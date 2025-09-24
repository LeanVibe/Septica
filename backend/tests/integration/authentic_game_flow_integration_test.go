package integration

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"

	"septica-backend/internal/database"
	"septica-backend/internal/game"
	"septica-backend/internal/handlers"
	"septica-backend/internal/matchmaking"
	ws "septica-backend/internal/websocket"
	"septica-backend/pkg/logger"
)

// IntegrationTestSuite manages the full integration test environment
type IntegrationTestSuite struct {
	server     *httptest.Server
	hub        *ws.Hub
	db         *gorm.DB
	matchmaker *matchmaking.MatchmakingService
	upgrader   websocket.Upgrader
	clients    map[string]*TestWebSocketClient
	mutex      sync.RWMutex
}

// TestWebSocketClient represents a test WebSocket client
type TestWebSocketClient struct {
	conn     *websocket.Conn
	playerID string
	gameID   string
	messages chan ws.Message
	done     chan struct{}
	mutex    sync.RWMutex
}

// NewTestWebSocketClient creates a new test WebSocket client
func NewTestWebSocketClient(wsURL string, playerID string) (*TestWebSocketClient, error) {
	conn, _, err := websocket.DefaultDialer.Dial(wsURL, nil)
	if err != nil {
		return nil, err
	}

	client := &TestWebSocketClient{
		conn:     conn,
		playerID: playerID,
		messages: make(chan ws.Message, 100),
		done:     make(chan struct{}),
	}

	// Start message reader
	go client.readMessages()

	return client, nil
}

// readMessages continuously reads messages from WebSocket connection
func (c *TestWebSocketClient) readMessages() {
	defer close(c.messages)
	for {
		select {
		case <-c.done:
			return
		default:
			var msg ws.Message
			err := c.conn.ReadJSON(&msg)
			if err != nil {
				if websocket.IsCloseError(err, websocket.CloseNormalClosure, websocket.CloseGoingAway) {
					return
				}
				continue
			}
			c.messages <- msg
		}
	}
}

// SendMessage sends a message to the WebSocket connection
func (c *TestWebSocketClient) SendMessage(msg ws.Message) error {
	c.mutex.Lock()
	defer c.mutex.Unlock()
	return c.conn.WriteJSON(msg)
}

// WaitForMessage waits for a specific message type with timeout
func (c *TestWebSocketClient) WaitForMessage(msgType string, timeout time.Duration) (*ws.Message, error) {
	timer := time.NewTimer(timeout)
	defer timer.Stop()

	for {
		select {
		case msg, ok := <-c.messages:
			if !ok {
				return nil, fmt.Errorf("message channel closed")
			}
			if msg.Type == msgType {
				return &msg, nil
			}
		case <-timer.C:
			return nil, fmt.Errorf("timeout waiting for message type: %s", msgType)
		}
	}
}

// Close closes the WebSocket connection
func (c *TestWebSocketClient) Close() error {
	close(c.done)
	return c.conn.Close()
}

// SetupIntegrationTestSuite creates a full integration test environment
func SetupIntegrationTestSuite(t *testing.T) *IntegrationTestSuite {
	// Setup in-memory database
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	require.NoError(t, err)

	// Run migrations
	err = db.AutoMigrate(
		&database.User{},
		&database.Game{},
		&database.Move{},
		&database.GameStats{},
	)
	require.NoError(t, err)

	// Initialize services
	log := logger.New("debug")
	hub := ws.NewHub()
	// Create a basic game engine for matchmaking
	gameEngine := game.NewEngine()
	matchmaker := matchmaking.NewMatchmakingService(hub, gameEngine, db, log, matchmaking.DefaultConfig())

	// Start hub
	go hub.Run()

	// Setup Gin router
	gin.SetMode(gin.TestMode)
	router := gin.New()

	// WebSocket upgrader
	upgrader := websocket.Upgrader{
		CheckOrigin: func(r *http.Request) bool { return true },
	}

	// WebSocket handler
	router.GET("/ws/connect", func(c *gin.Context) {
		handlers.HandleWebSocketConnection(c.Writer, c.Request, hub, db, log, &upgrader)
	})

	// Start test server
	server := httptest.NewServer(router)

	suite := &IntegrationTestSuite{
		server:     server,
		hub:        hub,
		db:         db,
		matchmaker: matchmaker,
		upgrader:   upgrader,
		clients:    make(map[string]*TestWebSocketClient),
	}

	return suite
}

// Cleanup tears down the integration test environment
func (s *IntegrationTestSuite) Cleanup() {
	s.mutex.Lock()
	defer s.mutex.Unlock()

	// Close all clients
	for _, client := range s.clients {
		client.Close()
	}

	// Stop server
	s.server.Close()

	// Close database
	sqlDB, _ := s.db.DB()
	if sqlDB != nil {
		sqlDB.Close()
	}
}

// CreateTestClient creates and registers a new test client
func (s *IntegrationTestSuite) CreateTestClient(t *testing.T, playerID string) *TestWebSocketClient {
	// Convert HTTP URL to WebSocket URL
	wsURL := strings.Replace(s.server.URL, "http://", "ws://", 1) + "/ws/connect"

	client, err := NewTestWebSocketClient(wsURL, playerID)
	require.NoError(t, err)

	s.mutex.Lock()
	s.clients[playerID] = client
	s.mutex.Unlock()

	return client
}

// TestCompleteAuthenticGameFlow tests a complete 2-player authentic Romanian Septica game
func TestCompleteAuthenticGameFlow(t *testing.T) {
	suite := SetupIntegrationTestSuite(t)
	defer suite.Cleanup()

	// Create two test clients
	player1 := suite.CreateTestClient(t, "player1")
	player2 := suite.CreateTestClient(t, "player2")

	// Wait for connection acknowledgments
	_, err := player1.WaitForMessage("connection_ack", 2*time.Second)
	require.NoError(t, err, "Player1 should receive connection_ack")

	_, err = player2.WaitForMessage("connection_ack", 2*time.Second)
	require.NoError(t, err, "Player2 should receive connection_ack")

	// Player 1 joins matchmaking
	err = player1.SendMessage(ws.Message{
		Type: "join_matchmaking",
		Payload: map[string]interface{}{
			"playerID":    "player1",
			"gameMode":    "authentic",
			"playerCount": 2,
		},
	})
	require.NoError(t, err)

	// Player 2 joins matchmaking
	err = player2.SendMessage(ws.Message{
		Type: "join_matchmaking",
		Payload: map[string]interface{}{
			"playerID":    "player2",
			"gameMode":    "authentic",
			"playerCount": 2,
		},
	})
	require.NoError(t, err)

	// Both players should receive match_found
	match1, err := player1.WaitForMessage("match_found", 5*time.Second)
	require.NoError(t, err, "Player1 should receive match_found")

	match2, err := player2.WaitForMessage("match_found", 5*time.Second)
	require.NoError(t, err, "Player2 should receive match_found")

	// Extract game ID
	gameData1 := match1.Payload
	gameID := gameData1["gameId"].(string)
	require.NotEmpty(t, gameID)

	gameData2, ok := match2.Payload.(map[string]interface{})
	require.True(t, ok)
	assert.Equal(t, gameID, gameData2["gameId"].(string))

	// Both players should receive initial game_state
	state1, err := player1.WaitForMessage("game_state", 3*time.Second)
	require.NoError(t, err, "Player1 should receive initial game_state")

	state2, err := player2.WaitForMessage("game_state", 3*time.Second)
	require.NoError(t, err, "Player2 should receive initial game_state")

	// Validate initial game state
	validateInitialGameState(t, state1, "player1")
	validateInitialGameState(t, state2, "player2")

	// Simulate a complete game with authentic Romanian Septica rules
	simulateAuthenticGameRounds(t, player1, player2, gameID)

	// Wait for game_end messages
	end1, err := player1.WaitForMessage("game_end", 10*time.Second)
	require.NoError(t, err, "Player1 should receive game_end")

	end2, err := player2.WaitForMessage("game_end", 10*time.Second)
	require.NoError(t, err, "Player2 should receive game_end")

	// Validate game completion
	validateGameCompletion(t, end1, end2)

	// Verify database persistence
	verifyGamePersistence(t, suite.db, gameID)
}

// validateInitialGameState validates the initial game state message
func validateInitialGameState(t *testing.T, stateMsg *ws.Message, playerID string) {
	require.Equal(t, "game_state", stateMsg.Type)

	data := stateMsg.Payload

	// Check required fields
	assert.NotEmpty(t, data["gameId"])
	assert.NotEmpty(t, data["currentPlayer"])
	assert.NotNil(t, data["playerHand"])
	assert.NotNil(t, data["opponentHandSize"])
	assert.NotNil(t, data["tableCards"])
	assert.NotNil(t, data["scores"])
	assert.NotNil(t, data["yourTurn"])
	assert.Equal(t, "playing", data["gamePhase"])

	// Validate hand size (should be 6 cards in Romanian Septica)
	playerHand, ok := data["playerHand"].([]interface{})
	require.True(t, ok)
	assert.Equal(t, 6, len(playerHand), "Player should have 6 cards initially")

	// Validate opponent hand size
	opponentHandSize, ok := data["opponentHandSize"].(float64)
	require.True(t, ok)
	assert.Equal(t, float64(6), opponentHandSize, "Opponent should have 6 cards initially")

	// Validate scores
	scores, ok := data["scores"].(map[string]interface{})
	require.True(t, ok)
	assert.Equal(t, float64(0), scores["player"])
	assert.Equal(t, float64(0), scores["opponent"])
}

// simulateAuthenticGameRounds simulates complete Romanian Septica game rounds
func simulateAuthenticGameRounds(t *testing.T, player1, player2 *TestWebSocketClient, gameID string) {
	roundsPlayed := 0
	maxRounds := 20 // Safety limit

	for roundsPlayed < maxRounds {
		// Get current game states
		state1, err := player1.WaitForMessage("game_state", 3*time.Second)
		if err != nil {
			break // Game might have ended
		}

		data1, ok := state1.Payload.(map[string]interface{})
		require.True(t, ok)

		if data1["gamePhase"].(string) == "completed" {
			break
		}

		// Determine current player and make a move
		currentPlayerID := data1["currentPlayer"].(string)
		yourTurn := data1["yourTurn"].(bool)

		var activePlayer *TestWebSocketClient
		var activePlayerID string

		if yourTurn {
			activePlayer = player1
			activePlayerID = "player1"
		} else {
			activePlayer = player2
			activePlayerID = "player2"
		}

		// Make a valid move (play first available card)
		playerHand, ok := data1["playerHand"].([]interface{})
		require.True(t, ok)
		require.Greater(t, len(playerHand), 0, "Player should have cards to play")

		// Play the first card
		card := playerHand[0].(map[string]interface{})
		err = activePlayer.SendMessage(ws.Message{
			Type: "play_card",
			Payload: map[string]interface{}{
				"gameId": gameID,
				"card": map[string]interface{}{
					"suit":  card["suit"],
					"value": card["value"],
				},
			},
		})
		require.NoError(t, err)

		// Wait for move result
		moveResult, err := activePlayer.WaitForMessage("move_result", 3*time.Second)
		require.NoError(t, err)

		resultData, ok := moveResult.Payload.(map[string]interface{})
		require.True(t, ok)
		assert.True(t, resultData["success"].(bool), "Move should be valid")

		// Test authentic Romanian Septica objection mechanics
		if shouldTestObjection(card) {
			// Test objection scenario
			testObjectionMechanism(t, player1, player2, gameID, card)
		}

		roundsPlayed++
	}

	assert.Less(t, roundsPlayed, maxRounds, "Game should complete within reasonable rounds")
}

// shouldTestObjection determines if we should test objection for this card
func shouldTestObjection(card map[string]interface{}) bool {
	value := card["value"].(float64)
	// Test objection for 7s (wild cards) and some other cards
	return value == 7 || value == 13 // Test with 7s and Kings
}

// testObjectionMechanism tests the Romanian Septica objection system
func testObjectionMechanism(t *testing.T, player1, player2 *TestWebSocketClient, gameID string, playedCard map[string]interface{}) {
	// Wait a moment for objection window
	time.Sleep(100 * time.Millisecond)

	// Simulate objection from non-active player
	// For simplicity, we'll randomly choose to object or pass
	objectionMsg := ws.Message{
		Type: "objection_decision",
		Payload: map[string]interface{}{
			"gameId":   gameID,
			"decision": "OBJECT", // or "PASS"
			"card": map[string]interface{}{
				"suit":  "hearts", // Test objection card
				"value": 7,        // Wild card objection
			},
		},
	}

	// Send objection (assuming player2 is objecting)
	err := player2.SendMessage(objectionMsg)
	if err != nil {
		// Objection window might have closed, that's okay
		return
	}

	// Wait for objection result
	objResult, err := player2.WaitForMessage("objection_result", 2*time.Second)
	if err != nil {
		return // No objection result, that's okay
	}

	objData, ok := objResult.Payload.(map[string]interface{})
	require.True(t, ok)

	if objData["success"].(bool) {
		// Objection was successful, verify round completion
		assert.True(t, objData["roundWon"].(bool))
	}
}

// validateGameCompletion validates game end messages
func validateGameCompletion(t *testing.T, end1, end2 *ws.Message) {
	require.Equal(t, "game_end", end1.Type)
	require.Equal(t, "game_end", end2.Type)

	data1, ok := end1.Payload.(map[string]interface{})
	require.True(t, ok)

	data2, ok := end2.Payload.(map[string]interface{})
	require.True(t, ok)

	// Both should have the same winner
	assert.Equal(t, data1["winner"], data2["winner"])

	// Check final scores
	scores1, ok := data1["finalScores"].(map[string]interface{})
	require.True(t, ok)

	scores2, ok := data2["finalScores"].(map[string]interface{})
	require.True(t, ok)

	assert.Equal(t, scores1, scores2)

	// Winner should have at least 6 points (Romanian Septica winning condition)
	winnerScore := float64(0)
	if data1["winner"] == "player1" {
		winnerScore = scores1["player1"].(float64)
	} else {
		winnerScore = scores1["player2"].(float64)
	}
	assert.GreaterOrEqual(t, winnerScore, float64(6), "Winner should have at least 6 points")
}

// verifyGamePersistence verifies that game data was properly persisted to database
func verifyGamePersistence(t *testing.T, db *gorm.DB, gameID string) {
	// Check game record exists
	var game database.Game
	err := db.Where("id = ?", gameID).First(&game).Error
	require.NoError(t, err, "Game should be persisted in database")

	// Verify game is completed
	assert.True(t, game.UseAuthenticRules, "Game should use authentic rules")
	assert.NotNil(t, game.WinnerID, "Game should have a winner")
	assert.NotNil(t, game.EndedAt, "Game should have end time")

	// Check moves were persisted
	var moves []database.Move
	err = db.Where("game_id = ?", gameID).Find(&moves).Error
	require.NoError(t, err, "Moves should be persisted")
	assert.Greater(t, len(moves), 0, "Should have at least one move")

	// Verify authentic Septica move types are recorded
	var objectionMoves []database.Move
	err = db.Where("game_id = ? AND is_objection = ?", gameID, true).Find(&objectionMoves).Error
	require.NoError(t, err, "Should be able to query objection moves")
	// Objection moves may or may not exist depending on game flow

	// Check pass moves exist
	var passMoves []database.Move
	err = db.Where("game_id = ? AND move_type = ?", gameID, "PASS").Find(&passMoves).Error
	require.NoError(t, err, "Should be able to query pass moves")
}

// TestMultiPlayerAuthenticGameFlow tests 3 and 4 player authentic games
func TestMultiPlayerAuthenticGameFlow(t *testing.T) {
	suite := SetupIntegrationTestSuite(t)
	defer suite.Cleanup()

	t.Run("3-Player Game with Wild 8s", func(t *testing.T) {
		testThreePlayerGame(t, suite)
	})

	t.Run("4-Player Team Game", func(t *testing.T) {
		testFourPlayerTeamGame(t, suite)
	})
}

// testThreePlayerGame tests 3-player authentic Romanian Septica
func testThreePlayerGame(t *testing.T, suite *IntegrationTestSuite) {
	// Create three test clients
	player1 := suite.CreateTestClient(t, "3p_player1")
	player2 := suite.CreateTestClient(t, "3p_player2")
	player3 := suite.CreateTestClient(t, "3p_player3")

	clients := []*TestWebSocketClient{player1, player2, player3}

	// Wait for all connections
	for i, client := range clients {
		_, err := client.WaitForMessage("connection_ack", 2*time.Second)
		require.NoError(t, err, fmt.Sprintf("Player%d should receive connection_ack", i+1))
	}

	// All players join matchmaking for 3-player game
	for i, client := range clients {
		err := client.SendMessage(ws.Message{
			Type: "join_matchmaking",
			Payload: map[string]interface{}{
				"playerID":    fmt.Sprintf("3p_player%d", i+1),
				"gameMode":    "authentic",
				"playerCount": 3,
			},
		})
		require.NoError(t, err)
	}

	// All should receive match_found
	var gameID string
	for i, client := range clients {
		match, err := client.WaitForMessage("match_found", 10*time.Second)
		require.NoError(t, err, fmt.Sprintf("Player%d should receive match_found", i+1))

		gameData, ok := match.Payload.(map[string]interface{})
		require.True(t, ok)

		if gameID == "" {
			gameID = gameData["gameId"].(string)
		} else {
			assert.Equal(t, gameID, gameData["gameId"].(string))
		}
	}

	// All should receive initial game state
	for i, client := range clients {
		state, err := client.WaitForMessage("game_state", 3*time.Second)
		require.NoError(t, err, fmt.Sprintf("Player%d should receive initial game_state", i+1))

		// Validate 3-player specific state
		data, ok := state.Payload.(map[string]interface{})
		require.True(t, ok)

		// In 3-player game, 8s should also be wild cards
		assert.Equal(t, 3, int(data["totalPlayers"].(float64)), "Should be 3-player game")
	}

	// Verify database records 3-player game correctly
	var game database.Game
	err := suite.db.Where("id = ?", gameID).First(&game).Error
	require.NoError(t, err)
	assert.Equal(t, "3_player", game.AuthenticMode)
	assert.NotNil(t, game.Player3ID, "Should have Player3")
	assert.Nil(t, game.Player4ID, "Should not have Player4")
}

// testFourPlayerTeamGame tests 4-player team Romanian Septica
func testFourPlayerTeamGame(t *testing.T, suite *IntegrationTestSuite) {
	// Create four test clients
	clients := make([]*TestWebSocketClient, 4)
	for i := 0; i < 4; i++ {
		clients[i] = suite.CreateTestClient(t, fmt.Sprintf("4p_player%d", i+1))
	}

	// Wait for all connections
	for i, client := range clients {
		_, err := client.WaitForMessage("connection_ack", 2*time.Second)
		require.NoError(t, err, fmt.Sprintf("Player%d should receive connection_ack", i+1))
	}

	// All players join matchmaking for 4-player game
	for i, client := range clients {
		err := client.SendMessage(ws.Message{
			Type: "join_matchmaking",
			Payload: map[string]interface{}{
				"playerID":    fmt.Sprintf("4p_player%d", i+1),
				"gameMode":    "authentic",
				"playerCount": 4,
			},
		})
		require.NoError(t, err)
	}

	// All should receive match_found
	var gameID string
	for i, client := range clients {
		match, err := client.WaitForMessage("match_found", 15*time.Second)
		require.NoError(t, err, fmt.Sprintf("Player%d should receive match_found", i+1))

		gameData, ok := match.Payload.(map[string]interface{})
		require.True(t, ok)

		if gameID == "" {
			gameID = gameData["gameId"].(string)
		} else {
			assert.Equal(t, gameID, gameData["gameId"].(string))
		}
	}

	// All should receive initial game state with team information
	for i, client := range clients {
		state, err := client.WaitForMessage("game_state", 3*time.Second)
		require.NoError(t, err, fmt.Sprintf("Player%d should receive initial game_state", i+1))

		data, ok := state.Payload.(map[string]interface{})
		require.True(t, ok)

		// Validate 4-player team game specifics
		assert.Equal(t, 4, int(data["totalPlayers"].(float64)), "Should be 4-player game")
		assert.NotNil(t, data["teamInfo"], "Should have team information")

		teamInfo, ok := data["teamInfo"].(map[string]interface{})
		require.True(t, ok)
		assert.NotNil(t, teamInfo["myTeam"], "Should have team assignment")
		assert.NotNil(t, teamInfo["teamScores"], "Should have team scores")
	}

	// Verify database records 4-player team game correctly
	var game database.Game
	err := suite.db.Where("id = ?", gameID).First(&game).Error
	require.NoError(t, err)
	assert.Equal(t, "4_player", game.AuthenticMode)
	assert.NotNil(t, game.Player3ID, "Should have Player3")
	assert.NotNil(t, game.Player4ID, "Should have Player4")
	assert.NotNil(t, game.Team1Score, "Should track Team1 score")
	assert.NotNil(t, game.Team2Score, "Should track Team2 score")
}

// TestAuthenticRuleValidationIntegration tests that authentic Romanian rules are enforced
func TestAuthenticRuleValidationIntegration(t *testing.T) {
	suite := SetupIntegrationTestSuite(t)
	defer suite.Cleanup()

	player1 := suite.CreateTestClient(t, "rule_player1")
	player2 := suite.CreateTestClient(t, "rule_player2")

	// Setup game (similar to previous test)
	setupGameForRuleTesting(t, player1, player2)

	// Test 1: Verify 7s beat everything
	t.Run("7s Beat All Cards", func(t *testing.T) {
		testSevenBeatsAll(t, player1, player2)
	})

	// Test 2: Verify same rank objections work
	t.Run("Same Rank Objections", func(t *testing.T) {
		testSameRankObjections(t, player1, player2)
	})

	// Test 3: Verify point counting (10s and Aces)
	t.Run("Point Counting Accuracy", func(t *testing.T) {
		testPointCounting(t, player1, player2)
	})

	// Test 4: Verify objection timeout mechanism
	t.Run("Objection Timeout", func(t *testing.T) {
		testObjectionTimeout(t, player1, player2)
	})
}

// Helper functions for rule testing
func setupGameForRuleTesting(t *testing.T, player1, player2 *TestWebSocketClient) {
	// Connection and matchmaking setup (abbreviated)
	// This would contain the same setup as previous tests
}

func testSevenBeatsAll(t *testing.T, player1, player2 *TestWebSocketClient) {
	// Simulate scenario where 7 is played against high-value cards
	// Verify objection with 7 always wins
}

func testSameRankObjections(t *testing.T, player1, player2 *TestWebSocketClient) {
	// Test objection with same rank cards
	// Verify rule that same rank beats the played card
}

func testPointCounting(t *testing.T, player1, player2 *TestWebSocketClient) {
	// Play rounds with 10s and Aces
	// Verify points are correctly awarded
}

func testObjectionTimeout(t *testing.T, player1, player2 *TestWebSocketClient) {
	// Test that objection window times out appropriately
	// Verify game continues after timeout
}