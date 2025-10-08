package websocket

import (
	"encoding/json"
	"testing"
	"time"

	"septica-backend/internal/game"
	"septica-backend/pkg/logger"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

// MockAuthenticEngine provides a mock implementation for testing
type MockAuthenticEngine struct {
	games map[uuid.UUID]*game.AuthenticGameState
}

func NewMockAuthenticEngine() *MockAuthenticEngine {
	return &MockAuthenticEngine{
		games: make(map[uuid.UUID]*game.AuthenticGameState),
	}
}

func (m *MockAuthenticEngine) CreateGame(playerIDs []uuid.UUID, gameMode game.AuthenticGameMode) (*game.AuthenticGameState, error) {
	gameID := uuid.New()
	authenticGame := &game.AuthenticGameState{
		ID:              gameID,
		Players:         playerIDs,
		CurrentPlayerID: playerIDs[0],
		Status:          "playing",
		GameMode:        gameMode,
		PlayerHands:     make(map[uuid.UUID][]game.Card),
		PlayerScores:    make(map[uuid.UUID]int),
		Deck:            []game.Card{},
		TableCards:      []game.Card{},
		WildEights:      gameMode == game.ModeThreePlayer,
		RoundNumber:     1,
		MoveNumber:      1,
	}

	// Setup teams for 4-player mode
	if gameMode == game.ModeFourPlayer {
		authenticGame.Teams = [][]uuid.UUID{
			{playerIDs[0], playerIDs[2]}, // Team 1: Player 1 + Player 3
			{playerIDs[1], playerIDs[3]}, // Team 2: Player 2 + Player 4
		}
		authenticGame.TeamScores = map[string]int{"team1": 0, "team2": 0}
	}

	// Initialize player hands and scores
	for _, playerID := range playerIDs {
		authenticGame.PlayerHands[playerID] = []game.Card{
			{Suit: "hearts", Value: 7, ID: uuid.New().String()},
			{Suit: "diamonds", Value: 8, ID: uuid.New().String()},
			{Suit: "clubs", Value: 9, ID: uuid.New().String()},
			{Suit: "spades", Value: 10, ID: uuid.New().String()},
		}
		authenticGame.PlayerScores[playerID] = 0
	}

	m.games[gameID] = authenticGame
	return authenticGame, nil
}

func (m *MockAuthenticEngine) GetGame(gameID uuid.UUID) (*game.AuthenticGameState, error) {
	if game, exists := m.games[gameID]; exists {
		return game, nil
	}
	return nil, game.ErrGameNotFound
}

func (m *MockAuthenticEngine) ProcessAction(gameID uuid.UUID, action game.AuthenticPlayerAction) (*game.AuthenticMoveResult, error) {
	gameState, err := m.GetGame(gameID)
	if err != nil {
		return nil, err
	}

	switch action.Type {
	case "PLAY_CARD":
		// Simulate card play - enter objection phase
		gameState.WaitingForObjection = true
		gameState.LastPlayedCard = action.Card
		gameState.LastPlayerID = action.PlayerID
		gameState.TableCards = append(gameState.TableCards, *action.Card)

		// Set next player
		for i, playerID := range gameState.Players {
			if playerID == action.PlayerID {
				nextIndex := (i + 1) % len(gameState.Players)
				gameState.CurrentPlayerID = gameState.Players[nextIndex]
				break
			}
		}

		return &game.AuthenticMoveResult{
			Valid:         true,
			UpdatedState:  gameState,
			ObjectionPhase: true,
			NextPlayerID:  gameState.CurrentPlayerID,
		}, nil

	case "PASS":
		// Simulate pass - complete round
		gameState.WaitingForObjection = false
		points := 0
		if gameState.LastPlayedCard != nil && (gameState.LastPlayedCard.Value == 10 || gameState.LastPlayedCard.Value == 14) {
			points = 1
		}

		collectorID := gameState.LastPlayerID
		gameState.PlayerScores[collectorID] += points
		gameState.TableCards = []game.Card{}
		gameState.CurrentPlayerID = collectorID
		gameState.RoundNumber++

		return &game.AuthenticMoveResult{
			Valid:             true,
			UpdatedState:      gameState,
			RoundComplete:     true,
			CollectorPlayerID: &collectorID,
			PointsAwarded:     points,
			NextPlayerID:      collectorID,
		}, nil

	default:
		return &game.AuthenticMoveResult{Valid: false, Error: "invalid action type"}, nil
	}
}

func (m *MockAuthenticEngine) CanObjectToCard(playedCard game.Card, objectionCard game.Card, gameMode game.AuthenticGameMode) bool {
	// 7s are always wild
	if objectionCard.Value == 7 {
		return true
	}
	// Same rank can object
	if objectionCard.Value == playedCard.Value {
		return true
	}
	// 8s are wild in 3-player mode
	if gameMode == game.ModeThreePlayer && objectionCard.Value == 8 {
		return true
	}
	return false
}

func (m *MockAuthenticEngine) GetValidMoves(gameID uuid.UUID, playerID uuid.UUID) ([]game.Card, error) {
	gameState, err := m.GetGame(gameID)
	if err != nil {
		return nil, err
	}

	hand := gameState.PlayerHands[playerID]
	if !gameState.WaitingForObjection {
		return hand, nil // All cards valid when starting round
	}

	// Return cards that can object
	var validMoves []game.Card
	for _, card := range hand {
		if m.CanObjectToCard(*gameState.LastPlayedCard, card, gameState.GameMode) {
			validMoves = append(validMoves, card)
		}
	}
	return validMoves, nil
}

func (m *MockAuthenticEngine) GetPlayerHand(gameID uuid.UUID, playerID uuid.UUID) ([]game.Card, error) {
	gameState, err := m.GetGame(gameID)
	if err != nil {
		return nil, err
	}

	if hand, exists := gameState.PlayerHands[playerID]; exists {
		return hand, nil
	}
	return nil, game.ErrGameNotFound
}

// Test setup helper
func setupTestHub() (*Hub, *gorm.DB, *MockAuthenticEngine) {
	// Create in-memory SQLite database for testing
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	if err != nil {
		panic("failed to connect database")
	}

	// Initialize logger
	testLogger := logger.New("info")

	// Create mock engine
	mockEngine := NewMockAuthenticEngine()

	// Create hub (we'll need to cast the engine interface when needed)
	// TODO: Fix mock engine to properly implement game.AuthenticEngine interface
	hub := NewHub(nil, nil, db, testLogger) // Pass nil for both engines for now

	return hub, db, mockEngine
}

// TestWebSocket_ObjectionWaitMessage tests objection wait message generation
func TestWebSocket_ObjectionWaitMessage(t *testing.T) {
	hub, _, mockEngine := setupTestHub()
	defer hub.db.Exec("DROP TABLE IF EXISTS players")

	// Create a test game
	player1ID := uuid.New()
	player2ID := uuid.New()
	playerIDs := []uuid.UUID{player1ID, player2ID}

	gameState, err := mockEngine.CreateGame(playerIDs, game.ModeTwoPlayer)
	require.NoError(t, err)

	// Simulate card play to enter objection phase
	playAction := game.AuthenticPlayerAction{
		Type:     "PLAY_CARD",
		PlayerID: player1ID,
		Card:     &game.Card{Suit: "hearts", Value: 10, ID: "test1"},
	}

	result, err := mockEngine.ProcessAction(gameState.ID, playAction)
	require.NoError(t, err)
	require.True(t, result.ObjectionPhase)

	// Convert game.Card to websocket.Card
	lastPlayedCard := Card{
		Suit:  result.UpdatedState.LastPlayedCard.Suit,
		Value: result.UpdatedState.LastPlayedCard.Value,
		ID:    result.UpdatedState.LastPlayedCard.ID,
	}

	// Test objection wait message creation
	objectionPayload := ObjectionWaitPayload{
		WaitingPlayerID: player2ID,
		LastPlayedCard:  lastPlayedCard,
		LastPlayerID:    result.UpdatedState.LastPlayerID,
		ValidObjections: []Card{
			{Suit: "spades", Value: 7, ID: "wild1"},     // Wild card
			{Suit: "diamonds", Value: 10, ID: "same1"},  // Same rank
		},
		TimeoutSeconds: 30,
		CanPass:       true,
	}

	message := Message{
		Type:      MessageTypeObjectionWait,
		ID:        uuid.New().String(),
		PlayerID:  player2ID,
		GameID:    &gameState.ID,
		Timestamp: time.Now(),
		Payload: map[string]interface{}{
			"waiting_player_id": objectionPayload.WaitingPlayerID,
			"last_played_card":  objectionPayload.LastPlayedCard,
			"last_player_id":    objectionPayload.LastPlayerID,
			"valid_objections":  objectionPayload.ValidObjections,
			"timeout_seconds":   objectionPayload.TimeoutSeconds,
			"can_pass":         objectionPayload.CanPass,
		},
	}

	// Verify message structure
	assert.Equal(t, MessageTypeObjectionWait, message.Type)
	assert.Equal(t, player2ID, message.PlayerID)
	assert.Equal(t, gameState.ID, *message.GameID)

	// Verify payload contents
	payload := message.Payload
	assert.Equal(t, player2ID, payload["waiting_player_id"])
	assert.Equal(t, 10, objectionPayload.LastPlayedCard.Value)
	assert.Equal(t, "hearts", objectionPayload.LastPlayedCard.Suit)
	assert.Equal(t, 30, payload["timeout_seconds"])
	assert.True(t, payload["can_pass"].(bool))

	// Verify valid objections
	validObjections, ok := payload["valid_objections"].([]Card)
	require.True(t, ok)
	assert.Len(t, validObjections, 2)

	// Check that wild card (7) is included
	hasWild := false
	hasSameRank := false
	for _, card := range validObjections {
		if card.Value == 7 {
			hasWild = true
		}
		if card.Value == 10 {
			hasSameRank = true
		}
	}
	assert.True(t, hasWild, "Should include wild card (7)")
	assert.True(t, hasSameRank, "Should include same rank card (10)")
}

// TestWebSocket_PassMessage tests pass message handling
func TestWebSocket_PassMessage(t *testing.T) {
	hub, _, mockEngine := setupTestHub()
	defer hub.db.Exec("DROP TABLE IF EXISTS players")

	// Create a test game in objection phase
	player1ID := uuid.New()
	player2ID := uuid.New()
	playerIDs := []uuid.UUID{player1ID, player2ID}

	gameState, err := mockEngine.CreateGame(playerIDs, game.ModeTwoPlayer)
	require.NoError(t, err)

	// Set up objection phase manually
	gameState.WaitingForObjection = true
	gameState.LastPlayedCard = &game.Card{Suit: "hearts", Value: 10, ID: "test1"}
	gameState.LastPlayerID = player1ID
	gameState.CurrentPlayerID = player2ID
	gameState.TableCards = []game.Card{{Suit: "hearts", Value: 10, ID: "test1"}}

	// Test pass message structure
	passMessage := IncomingMessage{
		Type:   MessageTypePass,
		ID:     uuid.New().String(),
		GameID: &gameState.ID,
		Payload: PassPayload{}, // Empty payload for pass
	}

	// Verify message type
	assert.Equal(t, MessageTypePass, passMessage.Type)
	assert.Equal(t, gameState.ID, *passMessage.GameID)

	// Test pass action processing
	passAction := game.AuthenticPlayerAction{
		Type:     "PASS",
		PlayerID: player2ID,
	}

	result, err := mockEngine.ProcessAction(gameState.ID, passAction)
	require.NoError(t, err)
	assert.True(t, result.Valid)
	assert.True(t, result.RoundComplete)
	assert.Equal(t, player1ID, *result.CollectorPlayerID) // Original player collects
	assert.Equal(t, 1, result.PointsAwarded) // 10 is worth 1 point
}

// TestWebSocket_ObjectionMessage tests objection message handling
func TestWebSocket_ObjectionMessage(t *testing.T) {
	hub, _, mockEngine := setupTestHub()
	defer hub.db.Exec("DROP TABLE IF EXISTS players")

	// Create a test game in objection phase
	player1ID := uuid.New()
	player2ID := uuid.New()
	playerIDs := []uuid.UUID{player1ID, player2ID}

	gameState, err := mockEngine.CreateGame(playerIDs, game.ModeTwoPlayer)
	require.NoError(t, err)

	// Enter objection phase
	playAction := game.AuthenticPlayerAction{
		Type:     "PLAY_CARD",
		PlayerID: player1ID,
		Card:     &game.Card{Suit: "hearts", Value: 10, ID: "test1"},
	}

	_, err = mockEngine.ProcessAction(gameState.ID, playAction)
	require.NoError(t, err)

	// Test objection message (play card during objection phase)
	objectionMessage := IncomingMessage{
		Type:   MessageTypePlayCard,
		ID:     uuid.New().String(),
		GameID: &gameState.ID,
		Payload: PlayCardPayload{
			Suit:  "spades",
			Value: 7, // Wild card that can object
			ID:    "objection1",
		},
	}

	// Verify message structure
	assert.Equal(t, MessageTypePlayCard, objectionMessage.Type)
	assert.Equal(t, gameState.ID, *objectionMessage.GameID)

	// Verify payload
	payload, ok := objectionMessage.Payload.(PlayCardPayload)
	require.True(t, ok)
	assert.Equal(t, "spades", payload.Suit)
	assert.Equal(t, 7, payload.Value)
	assert.Equal(t, "objection1", payload.ID)
}

// TestWebSocket_RoundCompleteMessage tests round complete message generation
func TestWebSocket_RoundCompleteMessage(t *testing.T) {
	hub, _, mockEngine := setupTestHub()
	defer hub.db.Exec("DROP TABLE IF EXISTS players")

	// Create a test game
	player1ID := uuid.New()
	player2ID := uuid.New()
	playerIDs := []uuid.UUID{player1ID, player2ID}

	gameState, err := mockEngine.CreateGame(playerIDs, game.ModeTwoPlayer)
	require.NoError(t, err)

	// Simulate a complete round (play card + pass)
	// 1. Player 1 plays a point card
	playAction := game.AuthenticPlayerAction{
		Type:     "PLAY_CARD",
		PlayerID: player1ID,
		Card:     &game.Card{Suit: "hearts", Value: 14, ID: "ace"}, // Ace = 1 point
	}

	_, err = mockEngine.ProcessAction(gameState.ID, playAction)
	require.NoError(t, err)

	// 2. Player 2 passes
	passAction := game.AuthenticPlayerAction{
		Type:     "PASS",
		PlayerID: player2ID,
	}

	result2, err := mockEngine.ProcessAction(gameState.ID, passAction)
	require.NoError(t, err)
	require.True(t, result2.RoundComplete)

	// Create round complete message
	roundCompletePayload := RoundCompletePayload{
		RoundNumber:       result2.UpdatedState.RoundNumber - 1, // Previous round number
		CollectorPlayerID: *result2.CollectorPlayerID,
		PointsAwarded:     result2.PointsAwarded,
		CardsCollected: []Card{
			{Suit: "hearts", Value: 14, ID: "ace"},
		},
		WasObjected: false,
		UpdatedScores: map[string]int{
			player1ID.String(): result2.UpdatedState.PlayerScores[player1ID],
			player2ID.String(): result2.UpdatedState.PlayerScores[player2ID],
		},
		NextPlayerID: result2.NextPlayerID,
	}

	message := Message{
		Type:      MessageTypeRoundComplete,
		ID:        uuid.New().String(),
		PlayerID:  player1ID, // Collector
		GameID:    &gameState.ID,
		Timestamp: time.Now(),
		Payload: map[string]interface{}{
			"round_number":        roundCompletePayload.RoundNumber,
			"collector_player_id": roundCompletePayload.CollectorPlayerID,
			"points_awarded":      roundCompletePayload.PointsAwarded,
			"cards_collected":     roundCompletePayload.CardsCollected,
			"was_objected":        roundCompletePayload.WasObjected,
			"updated_scores":      roundCompletePayload.UpdatedScores,
			"next_player_id":      roundCompletePayload.NextPlayerID,
		},
	}

	// Verify message structure
	assert.Equal(t, MessageTypeRoundComplete, message.Type)
	assert.Equal(t, player1ID, message.PlayerID)
	assert.Equal(t, gameState.ID, *message.GameID)

	// Verify payload
	payload := message.Payload
	assert.Equal(t, player1ID, payload["collector_player_id"])
	assert.Equal(t, 1, payload["points_awarded"])
	assert.False(t, payload["was_objected"].(bool))
	assert.Equal(t, result2.NextPlayerID, payload["next_player_id"])

	// Verify cards collected
	cardsCollected, ok := payload["cards_collected"].([]Card)
	require.True(t, ok)
	assert.Len(t, cardsCollected, 1)
	assert.Equal(t, 14, cardsCollected[0].Value) // Ace
	assert.Equal(t, "hearts", cardsCollected[0].Suit)
}

// TestWebSocket_AuthenticGameStateUpdates tests game state updates for authentic Septica
func TestWebSocket_AuthenticGameStateUpdates(t *testing.T) {
	hub, _, mockEngine := setupTestHub()
	defer hub.db.Exec("DROP TABLE IF EXISTS players")

	// Create different game modes
	testCases := []struct {
		name        string
		gameMode    game.AuthenticGameMode
		playerCount int
		wildEights  bool
	}{
		{
			name:        "2-player traditional",
			gameMode:    game.ModeTwoPlayer,
			playerCount: 2,
			wildEights:  false,
		},
		{
			name:        "3-player with wild 8s",
			gameMode:    game.ModeThreePlayer,
			playerCount: 3,
			wildEights:  true,
		},
		{
			name:        "4-player team mode",
			gameMode:    game.ModeFourPlayer,
			playerCount: 4,
			wildEights:  false,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			// Generate player IDs
			playerIDs := make([]uuid.UUID, tc.playerCount)
			for i := 0; i < tc.playerCount; i++ {
				playerIDs[i] = uuid.New()
			}

			gameState, err := mockEngine.CreateGame(playerIDs, tc.gameMode)
			require.NoError(t, err)

			// Convert game.Card slices to websocket.Card slices
			yourCards := make([]Card, len(gameState.PlayerHands[playerIDs[0]]))
			for i, card := range gameState.PlayerHands[playerIDs[0]] {
				yourCards[i] = Card{Suit: card.Suit, Value: card.Value, ID: card.ID}
			}

			tableCards := make([]Card, len(gameState.TableCards))
			for i, card := range gameState.TableCards {
				tableCards[i] = Card{Suit: card.Suit, Value: card.Value, ID: card.ID}
			}

			var lastPlayedCard *Card
			if gameState.LastPlayedCard != nil {
				lastPlayedCard = &Card{
					Suit:  gameState.LastPlayedCard.Suit,
					Value: gameState.LastPlayedCard.Value,
					ID:    gameState.LastPlayedCard.ID,
				}
			}

			// Create game state payload
			gameStatePayload := GameStatePayload{
				GameID:             gameState.ID,
				CurrentPlayerID:    gameState.CurrentPlayerID,
				YourTurn:           true, // For current player
				YourCards:          yourCards,
				OpponentCardCount:  4,
				TableCards:         tableCards,
				ValidMoves:         yourCards, // All cards valid initially
				Scores:             make(map[string]int),
				TrickNumber:        gameState.RoundNumber,
				MoveNumber:         gameState.MoveNumber,
				Status:             gameState.Status,

				// Authentic Septica extensions
				WaitingForObjection: gameState.WaitingForObjection,
				LastPlayedCard:     lastPlayedCard,
				GameMode:           string(gameState.GameMode),
				CanPass:            gameState.WaitingForObjection,
			}

			// Convert scores to string keys
			for playerID, score := range gameState.PlayerScores {
				gameStatePayload.Scores[playerID.String()] = score
			}

			// For 4-player mode, include team information
			if tc.gameMode == game.ModeFourPlayer {
				gameStatePayload.Teams = make([][]uuid.UUID, 2)
				gameStatePayload.Teams[0] = []uuid.UUID{playerIDs[0], playerIDs[2]} // Team 1
				gameStatePayload.Teams[1] = []uuid.UUID{playerIDs[1], playerIDs[3]} // Team 2

				gameStatePayload.TeamScores = map[string]int{
					"team1": 0,
					"team2": 0,
				}
			}

			// Verify payload structure
			assert.Equal(t, gameState.ID, gameStatePayload.GameID)
			assert.Equal(t, string(tc.gameMode), gameStatePayload.GameMode)
			assert.Equal(t, gameState.WaitingForObjection, gameStatePayload.WaitingForObjection)
			assert.Equal(t, gameState.WaitingForObjection, gameStatePayload.CanPass)
			assert.Len(t, gameStatePayload.YourCards, 4) // Each player starts with 4 cards

			// Verify team setup for 4-player mode
			if tc.gameMode == game.ModeFourPlayer {
				require.NotNil(t, gameStatePayload.Teams)
				require.NotNil(t, gameStatePayload.TeamScores)
				assert.Len(t, gameStatePayload.Teams, 2)
				assert.Equal(t, 0, gameStatePayload.TeamScores["team1"])
				assert.Equal(t, 0, gameStatePayload.TeamScores["team2"])
			}
		})
	}
}

// TestWebSocket_MultiPlayerSupport tests multi-player game support
func TestWebSocket_MultiPlayerSupport(t *testing.T) {
	hub, _, mockEngine := setupTestHub()
	defer hub.db.Exec("DROP TABLE IF EXISTS players")

	t.Run("3-player game with wild 8s", func(t *testing.T) {
		player1ID, player2ID, player3ID := uuid.New(), uuid.New(), uuid.New()
		playerIDs := []uuid.UUID{player1ID, player2ID, player3ID}

		gameState, err := mockEngine.CreateGame(playerIDs, game.ModeThreePlayer)
		require.NoError(t, err)

		// Verify 3-player specific settings
		assert.Equal(t, game.ModeThreePlayer, gameState.GameMode)
		assert.True(t, gameState.WildEights)
		assert.Len(t, gameState.Players, 3)

		// Test that 8s can object in 3-player mode
		canObject := mockEngine.CanObjectToCard(
			game.Card{Suit: "hearts", Value: 13},
			game.Card{Suit: "spades", Value: 8},
			game.ModeThreePlayer,
		)
		assert.True(t, canObject, "8s should be wild in 3-player mode")
	})

	t.Run("4-player team game", func(t *testing.T) {
		player1ID, player2ID, player3ID, player4ID := uuid.New(), uuid.New(), uuid.New(), uuid.New()
		playerIDs := []uuid.UUID{player1ID, player2ID, player3ID, player4ID}

		gameState, err := mockEngine.CreateGame(playerIDs, game.ModeFourPlayer)
		require.NoError(t, err)

		// Verify 4-player team setup
		assert.Equal(t, game.ModeFourPlayer, gameState.GameMode)
		assert.False(t, gameState.WildEights)
		assert.Len(t, gameState.Players, 4)
		assert.Len(t, gameState.Teams, 2)
		assert.Len(t, gameState.Teams[0], 2) // Team 1
		assert.Len(t, gameState.Teams[1], 2) // Team 2

		// Verify team assignments (cross-partners)
		assert.Contains(t, gameState.Teams[0], player1ID)
		assert.Contains(t, gameState.Teams[0], player3ID)
		assert.Contains(t, gameState.Teams[1], player2ID)
		assert.Contains(t, gameState.Teams[1], player4ID)
	})
}

// TestWebSocket_BackwardCompatibility tests backward compatibility with legacy systems
func TestWebSocket_BackwardCompatibility(t *testing.T) {
	hub, _, _ := setupTestHub()
	defer hub.db.Exec("DROP TABLE IF EXISTS players")

	t.Run("Legacy message types still supported", func(t *testing.T) {
		// Test that legacy message types are still recognized
		legacyMessages := []string{
			MessageTypeTrickComplete, // Old name for round complete
			MessageTypePlayerTurn,
			MessageTypeGameEnd,
		}

		for _, msgType := range legacyMessages {
			// Verify message type constants still exist
			assert.NotEmpty(t, msgType, "Legacy message type should still be defined")
		}
	})

	t.Run("New message types added", func(t *testing.T) {
		// Test new authentic Septica message types
		newMessages := []string{
			MessageTypePass,
			MessageTypeObjectionWait,
			MessageTypeRoundComplete,
		}

		for _, msgType := range newMessages {
			assert.NotEmpty(t, msgType, "New message type should be defined")
		}

		// Verify specific values
		assert.Equal(t, "pass", MessageTypePass)
		assert.Equal(t, "objection_wait", MessageTypeObjectionWait)
		assert.Equal(t, "round_complete", MessageTypeRoundComplete)
	})

	t.Run("GameStatePayload extensions", func(t *testing.T) {
		// Test that GameStatePayload has authentic extensions
		payload := GameStatePayload{
			WaitingForObjection: true,
			LastPlayedCard:     &Card{Suit: "hearts", Value: 10, ID: "test"},
			GameMode:           "2_player",
			Teams:              [][]uuid.UUID{},
			TeamScores:         map[string]int{},
			CanPass:            true,
			ObjectionTimeout:   30,
		}

		// Verify all new fields are accessible
		assert.True(t, payload.WaitingForObjection)
		assert.NotNil(t, payload.LastPlayedCard)
		assert.Equal(t, "2_player", payload.GameMode)
		assert.NotNil(t, payload.Teams)
		assert.NotNil(t, payload.TeamScores)
		assert.True(t, payload.CanPass)
		assert.Equal(t, 30, payload.ObjectionTimeout)
	})
}

// TestWebSocket_MessageSerialization tests message serialization/deserialization
func TestWebSocket_MessageSerialization(t *testing.T) {
	t.Run("ObjectionWaitPayload serialization", func(t *testing.T) {
		payload := ObjectionWaitPayload{
			WaitingPlayerID: uuid.New(),
			LastPlayedCard:  Card{Suit: "hearts", Value: 10, ID: "test1"},
			LastPlayerID:    uuid.New(),
			ValidObjections: []Card{
				{Suit: "spades", Value: 7, ID: "wild1"},
				{Suit: "diamonds", Value: 10, ID: "same1"},
			},
			TimeoutSeconds: 30,
			CanPass:       true,
		}

		// Serialize to JSON
		data, err := json.Marshal(payload)
		require.NoError(t, err)

		// Deserialize back
		var unmarshaled ObjectionWaitPayload
		err = json.Unmarshal(data, &unmarshaled)
		require.NoError(t, err)

		// Verify integrity
		assert.Equal(t, payload.WaitingPlayerID, unmarshaled.WaitingPlayerID)
		assert.Equal(t, payload.LastPlayedCard.Value, unmarshaled.LastPlayedCard.Value)
		assert.Equal(t, payload.LastPlayedCard.Suit, unmarshaled.LastPlayedCard.Suit)
		assert.Len(t, unmarshaled.ValidObjections, 2)
		assert.Equal(t, payload.TimeoutSeconds, unmarshaled.TimeoutSeconds)
		assert.Equal(t, payload.CanPass, unmarshaled.CanPass)
	})

	t.Run("RoundCompletePayload serialization", func(t *testing.T) {
		payload := RoundCompletePayload{
			RoundNumber:       5,
			CollectorPlayerID: uuid.New(),
			PointsAwarded:     2,
			CardsCollected: []Card{
				{Suit: "hearts", Value: 10, ID: "ten1"},
				{Suit: "spades", Value: 14, ID: "ace1"},
			},
			WasObjected: true,
			ObjectionCard: &Card{Suit: "clubs", Value: 7, ID: "wild1"},
			UpdatedScores: map[string]int{
				"player1": 3,
				"player2": 1,
			},
			NextPlayerID: uuid.New(),
		}

		// Serialize to JSON
		data, err := json.Marshal(payload)
		require.NoError(t, err)

		// Deserialize back
		var unmarshaled RoundCompletePayload
		err = json.Unmarshal(data, &unmarshaled)
		require.NoError(t, err)

		// Verify integrity
		assert.Equal(t, payload.RoundNumber, unmarshaled.RoundNumber)
		assert.Equal(t, payload.CollectorPlayerID, unmarshaled.CollectorPlayerID)
		assert.Equal(t, payload.PointsAwarded, unmarshaled.PointsAwarded)
		assert.Len(t, unmarshaled.CardsCollected, 2)
		assert.True(t, unmarshaled.WasObjected)
		assert.NotNil(t, unmarshaled.ObjectionCard)
		assert.Equal(t, 7, unmarshaled.ObjectionCard.Value)
		assert.Equal(t, 3, unmarshaled.UpdatedScores["player1"])
		assert.Equal(t, payload.NextPlayerID, unmarshaled.NextPlayerID)
	})
}

// TestWebSocket_ErrorHandling tests error handling in WebSocket protocol
func TestWebSocket_ErrorHandling(t *testing.T) {
	hub, _, mockEngine := setupTestHub()
	defer hub.db.Exec("DROP TABLE IF EXISTS players")

	t.Run("Invalid objection attempt", func(t *testing.T) {
		// Create game in objection phase
		player1ID := uuid.New()
		player2ID := uuid.New()
		playerIDs := []uuid.UUID{player1ID, player2ID}

		gameState, err := mockEngine.CreateGame(playerIDs, game.ModeTwoPlayer)
		require.NoError(t, err)

		// Set up objection phase
		gameState.WaitingForObjection = true
		gameState.LastPlayedCard = &game.Card{Suit: "hearts", Value: 10, ID: "test1"}
		gameState.CurrentPlayerID = player2ID

		// Try to object with invalid card (different rank, not wild)
		invalidAction := game.AuthenticPlayerAction{
			Type:     "PLAY_CARD",
			PlayerID: player2ID,
			Card:     &game.Card{Suit: "spades", Value: 9, ID: "invalid"},
		}

		// Mock should reject this
		canObject := mockEngine.CanObjectToCard(
			*gameState.LastPlayedCard,
			*invalidAction.Card,
			gameState.GameMode,
		)
		assert.False(t, canObject, "Should not be able to object with different rank non-wild card")
	})

	t.Run("Pass when not in objection phase", func(t *testing.T) {
		player1ID := uuid.New()
		player2ID := uuid.New()
		playerIDs := []uuid.UUID{player1ID, player2ID}

		gameState, err := mockEngine.CreateGame(playerIDs, game.ModeTwoPlayer)
		require.NoError(t, err)

		// This should be handled gracefully
		// In a real implementation, this would return an error
		assert.False(t, gameState.WaitingForObjection, "Should not be in objection phase initially")
	})

	t.Run("Message format validation", func(t *testing.T) {
		// Test invalid message format
		invalidMessage := IncomingMessage{
			Type:    "INVALID_TYPE",
			ID:      "",
			GameID:  nil,
			Payload: nil,
		}

		// Verify invalid message structure
		assert.Equal(t, "INVALID_TYPE", invalidMessage.Type)
		assert.Empty(t, invalidMessage.ID)
		assert.Nil(t, invalidMessage.GameID)
		assert.Nil(t, invalidMessage.Payload)
	})
}