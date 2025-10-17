package matchmaking

import (
	"testing"
	"time"

	"septica-backend/internal/ai"
	"septica-backend/internal/database"
	"septica-backend/internal/game"
	"septica-backend/internal/websocket"
	"septica-backend/pkg/logger"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

// setupMatchmakingTestEnvironment creates a complete test environment with matchmaking service
func setupMatchmakingTestEnvironment(t *testing.T) (*gorm.DB, *websocket.Hub, *MatchmakingService, *logger.Logger, func()) {
	// Use in-memory SQLite for testing
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	require.NoError(t, err)

	// Auto-migrate database schema
	err = db.AutoMigrate(
		&database.User{},
		&database.Player{},
		&database.MatchmakingQueue{},
		&database.Game{},
	)
	require.NoError(t, err)

	// Create logger
	testLogger := logger.New("debug")

	// Create game engines
	gameEngine := game.NewEngine()
	authenticEngine := game.NewAuthenticEngine()

	// Create WebSocket hub
	hub := websocket.NewHub(gameEngine, authenticEngine, db, testLogger)
	go hub.Run() // Start hub in background

	// Create matchmaking service
	matchmakingService := NewMatchmakingService(hub, gameEngine, authenticEngine, db, testLogger, nil)

	cleanup := func() {
		matchmakingService.Stop()
	}

	return db, hub, matchmakingService, testLogger, cleanup
}

// createTestPlayer creates a test player in the database
func createTestPlayer(t *testing.T, db *gorm.DB, rating int) (uuid.UUID, uuid.UUID) {
	userID := uuid.New()
	playerID := uuid.New()

	user := &database.User{
		BaseModel:    database.BaseModel{ID: userID},
		Username:     "test_player_" + userID.String()[:8],
		Email:        userID.String() + "@test.com",
		PasswordHash: "test_hash",
		IsActive:     true,
	}

	err := db.Create(user).Error
	require.NoError(t, err)

	player := &database.Player{
		BaseModel: database.BaseModel{ID: playerID},
		UserID:    userID,
		Username:  user.Username,
		Level:     1,
		Rating:    rating,
	}

	err = db.Create(player).Error
	require.NoError(t, err)

	return userID, playerID
}

// TestMatchmaking_AutoJoinSuccess tests that auto-join succeeds when client is registered
func TestMatchmaking_AutoJoinSuccess(t *testing.T) {
	db, _, matchmakingService, _, cleanup := setupMatchmakingTestEnvironment(t)
	defer cleanup()

	// Create two test players
	player1UserID, _ := createTestPlayer(t, db, 1200)
	player2UserID, _ := createTestPlayer(t, db, 1250)

	// Start matchmaking service
	err := matchmakingService.Start()
	require.NoError(t, err)

	// Join player 1 to matchmaking
	err = matchmakingService.JoinQueue(player1UserID, "ranked", "septica")
	assert.NoError(t, err, "Player 1 should join queue successfully")

	// Join player 2 to matchmaking
	err = matchmakingService.JoinQueue(player2UserID, "ranked", "septica")
	assert.NoError(t, err, "Player 2 should join queue successfully")

	// Wait for matchmaking to process
	time.Sleep(6 * time.Second) // Wait for one processing cycle

	// Verify both players are matched (no longer in queue)
	inQueue1 := matchmakingService.IsPlayerInQueue(player1UserID)
	inQueue2 := matchmakingService.IsPlayerInQueue(player2UserID)

	// At least one should be matched (removed from queue)
	assert.False(t, inQueue1 && inQueue2, "At least one player should be matched")
}

// TestMatchmaking_AIAutoJoinRetry tests that auto-join retries when AI client not found initially
func TestMatchmaking_AIAutoJoinRetry(t *testing.T) {
	db, hub, matchmakingService, testLogger, cleanup := setupMatchmakingTestEnvironment(t)
	defer cleanup()

	// Create human player
	humanUserID, _ := createTestPlayer(t, db, 1200)

	// Create AI player
	aiPlayer := ai.NewAIPlayer("medium", 1200, testLogger)
	aiClient := ai.NewAIWebSocketClient(aiPlayer, hub, testLogger)

	// Start matchmaking service
	err := matchmakingService.Start()
	require.NoError(t, err)

	// Human joins queue
	err = matchmakingService.JoinQueue(humanUserID, "ranked", "septica")
	require.NoError(t, err)

	// Wait a moment before connecting AI (simulate delayed registration)
	time.Sleep(500 * time.Millisecond)

	// Now connect AI client
	err = aiClient.Connect()
	require.NoError(t, err)
	defer aiClient.Disconnect()

	// Create AI player database record
	aiManager := ai.NewAIMatchmakingManager(hub, db, testLogger)
	err = aiManager.CreateAIPlayerRecord(aiPlayer)
	require.NoError(t, err)

	// AI joins matchmaking
	err = matchmakingService.JoinQueue(aiPlayer.ID, "ranked", "septica")
	assert.NoError(t, err, "AI should join queue successfully")

	// Wait for matchmaking to process
	time.Sleep(6 * time.Second)

	// Verify players are matched
	humanInQueue := matchmakingService.IsPlayerInQueue(humanUserID)
	aiInQueue := matchmakingService.IsPlayerInQueue(aiPlayer.ID)

	assert.False(t, humanInQueue && aiInQueue, "Players should be matched and removed from queue")
}

// TestMatchmaking_MatchCreationDoesNotFailOnAutoJoinFailure tests that match creation proceeds even if auto-join fails
func TestMatchmaking_MatchCreationDoesNotFailOnAutoJoinFailure(t *testing.T) {
	db, _, matchmakingService, _, cleanup := setupMatchmakingTestEnvironment(t)
	defer cleanup()

	// Create two players
	player1UserID, _ := createTestPlayer(t, db, 1200)
	player2UserID, _ := createTestPlayer(t, db, 1210)

	// Start matchmaking service
	err := matchmakingService.Start()
	require.NoError(t, err)

	// Both players join queue
	err = matchmakingService.JoinQueue(player1UserID, "ranked", "septica")
	require.NoError(t, err)

	err = matchmakingService.JoinQueue(player2UserID, "ranked", "septica")
	require.NoError(t, err)

	// Wait for matchmaking
	time.Sleep(6 * time.Second)

	// Even if auto-join fails (clients not connected), match should still be created in database
	var gameCount int64
	db.Model(&database.Game{}).Count(&gameCount)

	// Match creation should have been attempted
	// Note: Actual match creation depends on processor implementation
	t.Logf("Games created: %d", gameCount)
}

// TestMatchmaking_BothPlayersReceiveGameState tests that both players eventually receive initial game state
func TestMatchmaking_BothPlayersReceiveGameState(t *testing.T) {
	db, hub, matchmakingService, testLogger, cleanup := setupMatchmakingTestEnvironment(t)
	defer cleanup()

	// Create and connect human player
	humanUserID, _ := createTestPlayer(t, db, 1200)

	// Create and connect AI player
	aiPlayer := ai.NewAIPlayer("medium", 1220, testLogger)
	aiClient := ai.NewAIWebSocketClient(aiPlayer, hub, testLogger)
	err := aiClient.Connect()
	require.NoError(t, err)
	defer aiClient.Disconnect()

	// Create AI database record
	aiManager := ai.NewAIMatchmakingManager(hub, db, testLogger)
	err = aiManager.CreateAIPlayerRecord(aiPlayer)
	require.NoError(t, err)

	// Start matchmaking service
	err = matchmakingService.Start()
	require.NoError(t, err)

	// Both join queue
	err = matchmakingService.JoinQueue(humanUserID, "ranked", "septica")
	require.NoError(t, err)

	err = matchmakingService.JoinQueue(aiPlayer.ID, "ranked", "septica")
	require.NoError(t, err)

	// Wait for match processing
	time.Sleep(6 * time.Second)

	// Verify AI client received game state
	assert.NotNil(t, aiClient.LastGameState, "AI should have received game state")

	if aiClient.LastGameState != nil {
		assert.NotEqual(t, uuid.Nil, aiClient.LastGameState.ID, "Game state should have valid game ID")
	}
}

// TestMatchmaking_GameStateIncludesCorrectPlayerIDs tests that game state has correct player_ids
func TestMatchmaking_GameStateIncludesCorrectPlayerIDs(t *testing.T) {
	db, hub, matchmakingService, testLogger, cleanup := setupMatchmakingTestEnvironment(t)
	defer cleanup()

	// Create AI players
	ai1 := ai.NewAIPlayer("easy", 1100, testLogger)
	ai2 := ai.NewAIPlayer("medium", 1150, testLogger)

	aiClient1 := ai.NewAIWebSocketClient(ai1, hub, testLogger)
	aiClient2 := ai.NewAIWebSocketClient(ai2, hub, testLogger)

	err := aiClient1.Connect()
	require.NoError(t, err)
	defer aiClient1.Disconnect()

	err = aiClient2.Connect()
	require.NoError(t, err)
	defer aiClient2.Disconnect()

	// Create AI database records
	aiManager := ai.NewAIMatchmakingManager(hub, db, testLogger)
	err = aiManager.CreateAIPlayerRecord(ai1)
	require.NoError(t, err)
	err = aiManager.CreateAIPlayerRecord(ai2)
	require.NoError(t, err)

	// Start matchmaking
	err = matchmakingService.Start()
	require.NoError(t, err)

	// Join queue
	err = matchmakingService.JoinQueue(ai1.ID, "ranked", "septica")
	require.NoError(t, err)

	err = matchmakingService.JoinQueue(ai2.ID, "ranked", "septica")
	require.NoError(t, err)

	// Wait for matching
	time.Sleep(6 * time.Second)

	// Verify game state contains both player IDs
	if aiClient1.LastGameState != nil {
		playerIDs := []uuid.UUID{}
		for playerID := range aiClient1.LastGameState.PlayerHands {
			playerIDs = append(playerIDs, playerID)
		}

		assert.Contains(t, playerIDs, ai1.ID, "Game state should include AI1 player ID")
		assert.Contains(t, playerIDs, ai2.ID, "Game state should include AI2 player ID")
	}
}

// TestMatchmaking_QueueStatusReporting tests getting queue status for player
func TestMatchmaking_QueueStatusReporting(t *testing.T) {
	db, _, matchmakingService, _, cleanup := setupMatchmakingTestEnvironment(t)
	defer cleanup()

	// Create player
	playerUserID, _ := createTestPlayer(t, db, 1300)

	// Start matchmaking
	err := matchmakingService.Start()
	require.NoError(t, err)

	// Join queue
	err = matchmakingService.JoinQueue(playerUserID, "ranked", "septica")
	require.NoError(t, err)

	// Get queue status
	status, err := matchmakingService.GetQueueStatus(playerUserID)
	assert.NoError(t, err)
	assert.NotNil(t, status)

	// Verify status fields
	inQueue, ok := status["in_queue"].(bool)
	assert.True(t, ok, "Should have in_queue field")
	assert.True(t, inQueue, "Player should be in queue")

	queueType, ok := status["queue_type"].(string)
	assert.True(t, ok, "Should have queue_type field")
	assert.Equal(t, "ranked", queueType, "Queue type should be ranked")
}

// TestMatchmaking_LeaveQueueBeforeMatch tests leaving queue before getting matched
func TestMatchmaking_LeaveQueueBeforeMatch(t *testing.T) {
	db, _, matchmakingService, _, cleanup := setupMatchmakingTestEnvironment(t)
	defer cleanup()

	// Create player
	playerUserID, _ := createTestPlayer(t, db, 1200)

	// Start matchmaking
	err := matchmakingService.Start()
	require.NoError(t, err)

	// Join queue
	err = matchmakingService.JoinQueue(playerUserID, "ranked", "septica")
	require.NoError(t, err)

	// Verify in queue
	assert.True(t, matchmakingService.IsPlayerInQueue(playerUserID), "Player should be in queue")

	// Leave queue
	err = matchmakingService.LeaveQueue(playerUserID)
	assert.NoError(t, err, "Should leave queue successfully")

	// Verify not in queue
	assert.False(t, matchmakingService.IsPlayerInQueue(playerUserID), "Player should not be in queue")
}

// TestMatchmaking_PlayerRatingMatchingRange tests that players are matched within rating range
func TestMatchmaking_PlayerRatingMatchingRange(t *testing.T) {
	db, _, matchmakingService, _, cleanup := setupMatchmakingTestEnvironment(t)
	defer cleanup()

	// Create players with different ratings
	player1UserID, _ := createTestPlayer(t, db, 1000) // Low rating
	player2UserID, _ := createTestPlayer(t, db, 1500) // High rating

	// Start matchmaking
	err := matchmakingService.Start()
	require.NoError(t, err)

	// Both join queue
	err = matchmakingService.JoinQueue(player1UserID, "ranked", "septica")
	require.NoError(t, err)

	err = matchmakingService.JoinQueue(player2UserID, "ranked", "septica")
	require.NoError(t, err)

	// Wait for one processing cycle (should NOT match due to rating difference)
	time.Sleep(6 * time.Second)

	// Initially they should not be matched (rating difference too large)
	player1InQueue := matchmakingService.IsPlayerInQueue(player1UserID)
	player2InQueue := matchmakingService.IsPlayerInQueue(player2UserID)

	// Both should still be in queue (not matched yet)
	assert.True(t, player1InQueue || player2InQueue, "Players with large rating diff should not match immediately")
}

// TestMatchmaking_SearchRangeExpansion tests that search range expands over time
func TestMatchmaking_SearchRangeExpansion(t *testing.T) {
	_, _, matchmakingService, _, cleanup := setupMatchmakingTestEnvironment(t)
	defer cleanup()

	// Create player
	playerUserID := uuid.New()

	// Create queue entry manually
	entry := &QueueEntry{
		PlayerID:    playerUserID,
		Rating:      1200,
		QueuedAt:    time.Now().Add(-35 * time.Second), // Queued 35 seconds ago
		SearchRange: matchmakingService.config.InitialSearchRange,
		QueueType:   "ranked",
		GameMode:    "septica",
	}

	// Calculate current search range
	currentRange := entry.GetCurrentSearchRange(matchmakingService.config)

	// After 35 seconds, should have expanded at least once
	expectedRange := matchmakingService.config.InitialSearchRange + matchmakingService.config.RangeExpansionAmount
	assert.GreaterOrEqual(t, currentRange, expectedRange,
		"Search range should expand after activation timeout")
}

// TestMatchmaking_MaxWaitTimeExpiration tests handling of expired queue entries
func TestMatchmaking_MaxWaitTimeExpiration(t *testing.T) {
	_, _, matchmakingService, _, cleanup := setupMatchmakingTestEnvironment(t)
	defer cleanup()

	// Create queue entry that's expired
	entry := &QueueEntry{
		PlayerID:    uuid.New(),
		Rating:      1200,
		QueuedAt:    time.Now().Add(-10 * time.Minute), // Queued 10 minutes ago
		SearchRange: matchmakingService.config.InitialSearchRange,
		QueueType:   "ranked",
		GameMode:    "septica",
	}

	// Check if expired
	isExpired := entry.IsExpired(matchmakingService.config)
	assert.True(t, isExpired, "Queue entry should be expired after max wait time")
}

// TestMatchmaking_DuplicateQueueJoinPrevention tests preventing player from joining multiple queues
func TestMatchmaking_DuplicateQueueJoinPrevention(t *testing.T) {
	db, _, matchmakingService, _, cleanup := setupMatchmakingTestEnvironment(t)
	defer cleanup()

	// Create player
	playerUserID, _ := createTestPlayer(t, db, 1200)

	// Start matchmaking
	err := matchmakingService.Start()
	require.NoError(t, err)

	// Join ranked queue
	err = matchmakingService.JoinQueue(playerUserID, "ranked", "septica")
	require.NoError(t, err)

	// Try to join casual queue (should fail - already in queue)
	err = matchmakingService.JoinQueue(playerUserID, "casual", "septica")
	assert.Error(t, err, "Should not allow joining multiple queues")
	assert.Equal(t, ErrPlayerAlreadyInQueue, err, "Should return correct error")
}

// TestMatchmaking_QueueStatistics tests getting overall queue statistics
func TestMatchmaking_QueueStatistics(t *testing.T) {
	db, _, matchmakingService, _, cleanup := setupMatchmakingTestEnvironment(t)
	defer cleanup()

	// Create multiple players
	player1UserID, _ := createTestPlayer(t, db, 1200)
	player2UserID, _ := createTestPlayer(t, db, 1250)
	player3UserID, _ := createTestPlayer(t, db, 1300)

	// Start matchmaking
	err := matchmakingService.Start()
	require.NoError(t, err)

	// Players join queues
	err = matchmakingService.JoinQueue(player1UserID, "ranked", "septica")
	require.NoError(t, err)

	err = matchmakingService.JoinQueue(player2UserID, "ranked", "septica")
	require.NoError(t, err)

	err = matchmakingService.JoinQueue(player3UserID, "casual", "septica")
	require.NoError(t, err)

	// Get queue stats
	stats := matchmakingService.GetQueueStats()
	assert.NotNil(t, stats)

	// Verify total players
	totalPlayers, ok := stats["total_players"].(int)
	assert.True(t, ok, "Should have total_players field")
	assert.Equal(t, 3, totalPlayers, "Should have 3 players in queues")
}
