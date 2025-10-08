package game

import (
	"testing"
	"time"

	"septica-backend/internal/database"
	"septica-backend/pkg/logger"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

// setupTestDB creates an in-memory SQLite database for testing
func setupTestDB(t *testing.T) *gorm.DB {
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	require.NoError(t, err, "Failed to create test database")

	// Auto-migrate the schema
	err = db.AutoMigrate(
		&database.User{},
		&database.Player{},
		&database.Game{},
		&database.GameMove{},
	)
	require.NoError(t, err, "Failed to migrate test database schema")

	return db
}

// TestRecordMove_WithValidGameID tests that moves are persisted with game_id
func TestRecordMove_WithValidGameID(t *testing.T) {
	db := setupTestDB(t)
	testLogger := logger.New("debug")
	engine := NewAuthenticEngineWithDB(db, testLogger)

	gameID := uuid.New()
	playerID := uuid.New()

	// Create a game move record
	move := &database.GameMove{
		GameID:         gameID, // ✅ game_id explicitly set
		PlayerID:       playerID,
		MoveNumber:     1,
		MoveType:       "PLAY_CARD",
		CardSuit:       "hearts",
		CardValue:      7,
		TrickNumber:    1,
		TableCardCount: 0,
	}

	// Record the move
	err := engine.RecordMove(gameID, move)
	require.NoError(t, err, "RecordMove should not return error")

	// Query database to verify move was persisted
	var persistedMove database.GameMove
	err = db.Where("game_id = ? AND player_id = ?", gameID, playerID).First(&persistedMove).Error
	require.NoError(t, err, "Move should be found in database")

	// Verify all fields including game_id
	assert.Equal(t, gameID, persistedMove.GameID, "game_id should match")
	assert.Equal(t, playerID, persistedMove.PlayerID, "player_id should match")
	assert.Equal(t, 1, persistedMove.MoveNumber, "move_number should match")
	assert.Equal(t, "PLAY_CARD", persistedMove.MoveType, "move_type should match")
	assert.Equal(t, "hearts", persistedMove.CardSuit, "card_suit should match")
	assert.Equal(t, 7, persistedMove.CardValue, "card_value should match")
}

// TestRecordMove_WithoutGameID tests that moves without game_id are rejected
func TestRecordMove_WithoutGameID(t *testing.T) {
	db := setupTestDB(t)
	testLogger := logger.New("debug")
	engine := NewAuthenticEngineWithDB(db, testLogger)

	playerID := uuid.New()

	// Create a move without game_id
	move := &database.GameMove{
		GameID:     uuid.Nil, // ❌ Missing game_id
		PlayerID:   playerID,
		MoveNumber: 1,
		MoveType:   "PLAY_CARD",
	}

	// Attempt to record the move
	err := engine.RecordMove(uuid.Nil, move)
	require.Error(t, err, "RecordMove should return error for missing game_id")
	assert.Contains(t, err.Error(), "game_id is required", "Error message should mention game_id")

	// Verify move was NOT persisted
	var count int64
	db.Model(&database.GameMove{}).Where("player_id = ?", playerID).Count(&count)
	assert.Equal(t, int64(0), count, "Move should not be in database")
}

// TestRecordMove_WithoutPlayerID tests that moves without player_id are rejected
func TestRecordMove_WithoutPlayerID(t *testing.T) {
	db := setupTestDB(t)
	testLogger := logger.New("debug")
	engine := NewAuthenticEngineWithDB(db, testLogger)

	gameID := uuid.New()

	// Create a move without player_id
	move := &database.GameMove{
		GameID:     gameID,
		PlayerID:   uuid.Nil, // ❌ Missing player_id
		MoveNumber: 1,
		MoveType:   "PLAY_CARD",
	}

	// Attempt to record the move
	err := engine.RecordMove(gameID, move)
	require.Error(t, err, "RecordMove should return error for missing player_id")
	assert.Contains(t, err.Error(), "player_id is required", "Error message should mention player_id")

	// Verify move was NOT persisted
	var count int64
	db.Model(&database.GameMove{}).Where("game_id = ?", gameID).Count(&count)
	assert.Equal(t, int64(0), count, "Move should not be in database")
}

// TestProcessAction_PersistsMove tests that ProcessAction persists moves to database
func TestProcessAction_PersistsMove(t *testing.T) {
	db := setupTestDB(t)
	testLogger := logger.New("debug")
	engine := NewAuthenticEngineWithDB(db, testLogger)

	// Create a 2-player game
	player1ID := uuid.New()
	player2ID := uuid.New()

	game, err := engine.CreateGame([]uuid.UUID{player1ID, player2ID}, ModeTwoPlayer)
	require.NoError(t, err, "Failed to create game")

	// Get player 1's first card
	player1Hand := game.PlayerHands[player1ID]
	require.NotEmpty(t, player1Hand, "Player 1 should have cards")
	cardToPlay := player1Hand[0]

	// Player 1 plays a card
	action := AuthenticPlayerAction{
		Type:     "PLAY_CARD",
		PlayerID: player1ID,
		Card:     &cardToPlay,
	}

	result, err := engine.ProcessAction(game.ID, action)
	require.NoError(t, err, "ProcessAction should not return error")
	require.True(t, result.Valid, "Move should be valid")

	// Give database a moment to persist (async operations)
	time.Sleep(50 * time.Millisecond)

	// Query database to verify move was persisted
	var persistedMove database.GameMove
	err = db.Where("game_id = ? AND player_id = ?", game.ID, player1ID).First(&persistedMove).Error
	require.NoError(t, err, "Move should be found in database")

	// Verify move details including game_id
	assert.Equal(t, game.ID, persistedMove.GameID, "game_id should match")
	assert.Equal(t, player1ID, persistedMove.PlayerID, "player_id should match")
	assert.Equal(t, "PLAY_CARD", persistedMove.MoveType, "move_type should be PLAY_CARD")
	assert.Equal(t, cardToPlay.Suit, persistedMove.CardSuit, "card_suit should match")
	assert.Equal(t, cardToPlay.Value, persistedMove.CardValue, "card_value should match")
	assert.Equal(t, 1, persistedMove.MoveNumber, "move_number should be 1")
	assert.False(t, persistedMove.IsObjection, "first move should not be objection")
}

// TestProcessAction_PassMove_Persisted tests that PASS actions are also persisted
func TestProcessAction_PassMove_Persisted(t *testing.T) {
	db := setupTestDB(t)
	testLogger := logger.New("debug")
	engine := NewAuthenticEngineWithDB(db, testLogger)

	// Create a 2-player game
	player1ID := uuid.New()
	player2ID := uuid.New()

	game, err := engine.CreateGame([]uuid.UUID{player1ID, player2ID}, ModeTwoPlayer)
	require.NoError(t, err, "Failed to create game")

	// Player 1 plays a card (to set up objection phase)
	player1Hand := game.PlayerHands[player1ID]
	cardToPlay := player1Hand[0]

	action1 := AuthenticPlayerAction{
		Type:     "PLAY_CARD",
		PlayerID: player1ID,
		Card:     &cardToPlay,
	}

	result1, err := engine.ProcessAction(game.ID, action1)
	require.NoError(t, err)
	require.True(t, result1.Valid)

	// Player 2 passes (doesn't object)
	action2 := AuthenticPlayerAction{
		Type:     "PASS",
		PlayerID: player2ID,
	}

	result2, err := engine.ProcessAction(game.ID, action2)
	require.NoError(t, err)
	require.True(t, result2.Valid)

	time.Sleep(50 * time.Millisecond)

	// Query database to verify PASS move was persisted
	var passMove database.GameMove
	err = db.Where("game_id = ? AND player_id = ? AND move_type = ?", game.ID, player2ID, "PASS").First(&passMove).Error
	require.NoError(t, err, "PASS move should be found in database")

	// Verify PASS move details
	assert.Equal(t, game.ID, passMove.GameID, "game_id should match")
	assert.Equal(t, player2ID, passMove.PlayerID, "player_id should match")
	assert.Equal(t, "PASS", passMove.MoveType, "move_type should be PASS")
	assert.True(t, passMove.IsObjection, "pass during objection phase should be marked as objection")
}

// TestProcessAction_MultipleMoves_AllPersisted tests that multiple moves are all persisted
func TestProcessAction_MultipleMoves_AllPersisted(t *testing.T) {
	db := setupTestDB(t)
	testLogger := logger.New("debug")
	engine := NewAuthenticEngineWithDB(db, testLogger)

	// Create a 2-player game
	player1ID := uuid.New()
	player2ID := uuid.New()

	game, err := engine.CreateGame([]uuid.UUID{player1ID, player2ID}, ModeTwoPlayer)
	require.NoError(t, err)

	// Play 3 complete rounds (6 moves total)
	for i := 0; i < 3; i++ {
		// Player 1 plays
		player1Hand := engine.games[game.ID].PlayerHands[player1ID]
		if len(player1Hand) > 0 {
			action := AuthenticPlayerAction{
				Type:     "PLAY_CARD",
				PlayerID: player1ID,
				Card:     &player1Hand[0],
			}
			result, err := engine.ProcessAction(game.ID, action)
			require.NoError(t, err)
			require.True(t, result.Valid)
		}

		// Player 2 passes
		action := AuthenticPlayerAction{
			Type:     "PASS",
			PlayerID: player2ID,
		}
		result, err := engine.ProcessAction(game.ID, action)
		require.NoError(t, err)
		require.True(t, result.Valid)
	}

	time.Sleep(100 * time.Millisecond)

	// Verify all moves were persisted
	var moveCount int64
	db.Model(&database.GameMove{}).Where("game_id = ?", game.ID).Count(&moveCount)
	assert.Equal(t, int64(6), moveCount, "All 6 moves should be persisted")

	// Verify all moves have game_id set
	var movesWithoutGameID int64
	db.Model(&database.GameMove{}).Where("game_id = ? OR game_id IS NULL", uuid.Nil).Count(&movesWithoutGameID)
	assert.Equal(t, int64(0), movesWithoutGameID, "No moves should have missing game_id")
}

// TestRecordMove_WithoutDatabase tests graceful handling when database is not configured
func TestRecordMove_WithoutDatabase(t *testing.T) {
	// Create engine WITHOUT database
	engine := NewAuthenticEngine()

	gameID := uuid.New()
	playerID := uuid.New()

	move := &database.GameMove{
		GameID:     gameID,
		PlayerID:   playerID,
		MoveNumber: 1,
		MoveType:   "PLAY_CARD",
	}

	// Should not error when database is not configured
	err := engine.RecordMove(gameID, move)
	assert.NoError(t, err, "RecordMove should not error when database is nil")
}

// TestAIMove_IncludesGameID tests that AI-generated moves include game_id
func TestAIMove_IncludesGameID(t *testing.T) {
	db := setupTestDB(t)
	testLogger := logger.New("debug")
	engine := NewAuthenticEngineWithDB(db, testLogger)

	// Create a 2-player game with AI
	humanPlayerID := uuid.New()
	aiPlayerID := uuid.New()

	game, err := engine.CreateGame([]uuid.UUID{humanPlayerID, aiPlayerID}, ModeTwoPlayer)
	require.NoError(t, err)

	// Simulate human player's move
	humanHand := game.PlayerHands[humanPlayerID]
	humanAction := AuthenticPlayerAction{
		Type:     "PLAY_CARD",
		PlayerID: humanPlayerID,
		Card:     &humanHand[0],
	}

	result, err := engine.ProcessAction(game.ID, humanAction)
	require.NoError(t, err)
	require.True(t, result.Valid)

	// Simulate AI player's move (pass)
	aiAction := AuthenticPlayerAction{
		Type:     "PASS",
		PlayerID: aiPlayerID,
	}

	aiResult, err := engine.ProcessAction(game.ID, aiAction)
	require.NoError(t, err)
	require.True(t, aiResult.Valid)

	time.Sleep(50 * time.Millisecond)

	// Verify AI move was persisted with game_id
	var aiMove database.GameMove
	err = db.Where("game_id = ? AND player_id = ?", game.ID, aiPlayerID).First(&aiMove).Error
	require.NoError(t, err, "AI move should be found in database")

	// Critical assertion: game_id must be present
	assert.Equal(t, game.ID, aiMove.GameID, "AI move MUST have game_id set")
	assert.NotEqual(t, uuid.Nil, aiMove.GameID, "AI move game_id MUST NOT be nil")
	assert.Equal(t, aiPlayerID, aiMove.PlayerID, "player_id should match AI player")
}
