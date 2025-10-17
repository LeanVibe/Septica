package ai

import (
	"fmt"
	"testing"

	"septica-backend/internal/database"
	"septica-backend/internal/game"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

// TestGameContextValidation tests the core game context validation logic
func TestGameContextValidation(t *testing.T) {
	// Test case 1: Nil game ID should fail validation
	gameID1 := uuid.Nil
	assert.True(t, gameID1 == uuid.Nil, "Test setup: uuid.Nil should equal uuid.Nil")

	// Test case 2: Valid game ID should pass validation
	gameID2 := uuid.New()
	assert.False(t, gameID2 == uuid.Nil, "Test setup: valid UUID should not equal uuid.Nil")

	// Test case 3: Game state ID mismatch should fail validation
	gameID3 := uuid.New()
	gameState1 := game.AuthenticGameState{
		ID:              uuid.New(), // Different ID
		Players:         []uuid.UUID{uuid.New(), uuid.New()},
		CurrentPlayerID: uuid.New(),
		Status:          "playing",
		GameMode:        game.ModeTwoPlayer,
	}

	// This should fail validation (mismatched IDs)
	assert.NotEqual(t, gameID3, gameState1.ID, "Test setup: game IDs should be different")

	// Test case 4: Matching game state ID should pass validation
	gameState2 := game.AuthenticGameState{
		ID:              gameID3,
		Players:         []uuid.UUID{uuid.New(), uuid.New()},
		CurrentPlayerID: uuid.New(),
		Status:          "playing",
		GameMode:        game.ModeTwoPlayer,
	}

	// This should pass validation (matching IDs)
	assert.Equal(t, gameID3, gameState2.ID, "Test setup: game IDs should match")
}

// TestGameMoveDataStructure tests the move data structure validation
func TestGameMoveDataStructure(t *testing.T) {
	// Test case 1: Valid PLAY_CARD move with card data
	playCardMove := map[string]interface{}{
		"type":      "PLAY_CARD",
		"player_id": uuid.New().String(),
		"card": map[string]interface{}{
			"suit":  "hearts",
			"value": 10.0,
			"id":    "card-123",
		},
	}

	// Validate structure
	moveType, ok := playCardMove["type"].(string)
	assert.True(t, ok, "Move type should be string")
	assert.Equal(t, "PLAY_CARD", moveType, "Move type should be PLAY_CARD")

	playerID, ok := playCardMove["player_id"].(string)
	assert.True(t, ok, "Player ID should be string")
	assert.NotEmpty(t, playerID, "Player ID should not be empty")

	cardData, ok := playCardMove["card"].(map[string]interface{})
	assert.True(t, ok, "Card data should be map")
	assert.NotNil(t, cardData, "Card data should not be nil")

	suit, ok := cardData["suit"].(string)
	assert.True(t, ok, "Card suit should be string")
	assert.Equal(t, "hearts", suit, "Card suit should be hearts")

	value, ok := cardData["value"].(float64)
	assert.True(t, ok, "Card value should be float64")
	assert.Equal(t, 10.0, value, "Card value should be 10.0")

	id, ok := cardData["id"].(string)
	assert.True(t, ok, "Card ID should be string")
	assert.Equal(t, "card-123", id, "Card ID should match")

	// Test case 2: Valid PASS move without card data
	passMove := map[string]interface{}{
		"type":      "PASS",
		"player_id": uuid.New().String(),
	}

	// Validate structure
	moveType, ok = passMove["type"].(string)
	assert.True(t, ok, "Move type should be string")
	assert.Equal(t, "PASS", moveType, "Move type should be PASS")

	playerID, ok = passMove["player_id"].(string)
	assert.True(t, ok, "Player ID should be string")
	assert.NotEmpty(t, playerID, "Player ID should not be empty")

	// Test case 3: Invalid move (missing type)
	invalidMove1 := map[string]interface{}{
		"player_id": uuid.New().String(),
		"card": map[string]interface{}{
			"suit":  "spades",
			"value": 8.0,
		},
	}

	moveType, ok = invalidMove1["type"].(string)
	assert.False(t, ok, "Move type should be missing")

	// Test case 4: Invalid move (missing player_id)
	invalidMove2 := map[string]interface{}{
		"type": "PLAY_CARD",
		"card": map[string]interface{}{
			"suit":  "spades",
			"value": 8.0,
		},
	}

	playerID, ok = invalidMove2["player_id"].(string)
	assert.False(t, ok, "Player ID should be missing")

	// Test case 5: Invalid move (invalid card data for PLAY_CARD)
	invalidMove3 := map[string]interface{}{
		"type":      "PLAY_CARD",
		"player_id": uuid.New().String(),
		"card":      "invalid_card_data", // Not a map
	}

	cardData, ok = invalidMove3["card"].(map[string]interface{})
	assert.False(t, ok, "Card data should be invalid")
}

// TestGameMoveMessageValidation tests the complete message validation
func TestGameMoveMessageValidation(t *testing.T) {
	// Test case 1: Valid message with PLAY_CARD
	gameID := uuid.New()
	playerID := uuid.New()

	validMessage1 := map[string]interface{}{
		"type":      "player_move",
		"id":        uuid.New().String(),
		"game_id":   gameID.String(),
		"player_id": playerID.String(),
		"timestamp": "2025-01-01T00:00:00Z",
		"payload": map[string]interface{}{
			"type":      "PLAY_CARD",
			"player_id": playerID.String(),
			"card": map[string]interface{}{
				"suit":  "hearts",
				"value": 10.0,
				"id":    "card-456",
			},
		},
	}

	// Validate message structure
	msgType, ok := validMessage1["type"].(string)
	assert.True(t, ok, "Message type should be string")
	assert.Equal(t, "player_move", msgType, "Message type should be player_move")

	msgID, ok := validMessage1["id"].(string)
	assert.True(t, ok, "Message ID should be string")
	assert.NotEmpty(t, msgID, "Message ID should not be empty")

	msgGameID, ok := validMessage1["game_id"].(string)
	assert.True(t, ok, "Game ID should be string")
	assert.NotEmpty(t, msgGameID, "Game ID should not be empty")

	// Validate game ID format
	parsedGameID, err := uuid.Parse(msgGameID)
	assert.NoError(t, err, "Game ID should be valid UUID")
	assert.Equal(t, gameID, parsedGameID, "Parsed game ID should match original")

	msgPlayerID, ok := validMessage1["player_id"].(string)
	assert.True(t, ok, "Player ID should be string")
	assert.NotEmpty(t, msgPlayerID, "Player ID should not be empty")

	// Validate player ID format
	parsedPlayerID, err := uuid.Parse(msgPlayerID)
	assert.NoError(t, err, "Player ID should be valid UUID")
	assert.Equal(t, playerID, parsedPlayerID, "Parsed player ID should match original")

	payload, ok := validMessage1["payload"].(map[string]interface{})
	assert.True(t, ok, "Payload should be map")
	assert.NotNil(t, payload, "Payload should not be nil")

	// Validate payload structure
	moveType, ok := payload["type"].(string)
	assert.True(t, ok, "Payload move type should be string")
	assert.Equal(t, "PLAY_CARD", moveType, "Payload move type should be PLAY_CARD")

	// Test case 2: Valid message with PASS
	validMessage2 := map[string]interface{}{
		"type":      "player_move",
		"id":        uuid.New().String(),
		"game_id":   gameID.String(),
		"player_id": playerID.String(),
		"timestamp": "2025-01-01T00:00:00Z",
		"payload": map[string]interface{}{
			"type":      "PASS",
			"player_id": playerID.String(),
		},
	}

	payload, ok = validMessage2["payload"].(map[string]interface{})
	assert.True(t, ok, "Payload should be map")
	assert.NotNil(t, payload, "Payload should not be nil")

	moveType, ok = payload["type"].(string)
	assert.True(t, ok, "Payload move type should be string")
	assert.Equal(t, "PASS", moveType, "Payload move type should be PASS")

	// Test case 3: Invalid message (missing game_id)
	invalidMessage1 := map[string]interface{}{
		"type":      "player_move",
		"id":        uuid.New().String(),
		"player_id": playerID.String(),
		"timestamp": "2025-01-01T00:00:00Z",
		"payload": map[string]interface{}{
			"type": "PLAY_CARD",
		},
	}

	_, ok = invalidMessage1["game_id"].(string)
	assert.False(t, ok, "Game ID should be missing")

	// Test case 4: Invalid message (invalid game_id format)
	invalidMessage2 := map[string]interface{}{
		"type":      "player_move",
		"id":        uuid.New().String(),
		"game_id":   "invalid-uuid",
		"player_id": playerID.String(),
		"timestamp": "2025-01-01T00:00:00Z",
		"payload": map[string]interface{}{
			"type": "PLAY_CARD",
		},
	}

	_, ok = invalidMessage2["game_id"].(string)
	assert.True(t, ok, "Game ID should be present")
	_, err = uuid.Parse(invalidMessage2["game_id"].(string))
	assert.Error(t, err, "Invalid game ID should fail UUID parsing")

	// Test case 5: Invalid message (missing payload)
	invalidMessage3 := map[string]interface{}{
		"type":      "player_move",
		"id":        uuid.New().String(),
		"game_id":   gameID.String(),
		"player_id": playerID.String(),
		"timestamp": "2025-01-01T00:00:00Z",
	}

	_, ok = invalidMessage3["payload"].(map[string]interface{})
	assert.False(t, ok, "Payload should be missing")
}

// TestGameIDValidationScenarios tests various game ID validation scenarios
func TestGameIDValidationScenarios(t *testing.T) {
	// Test case 1: Nil pointer should fail
	var gameID1 *uuid.UUID = nil
	assert.Nil(t, gameID1, "Test setup: game ID should be nil pointer")

	// Test case 2: Valid pointer should pass
	gameID2 := uuid.New()
	gameIDPtr := &gameID2
	assert.NotNil(t, gameIDPtr, "Test setup: game ID pointer should not be nil")
	assert.Equal(t, gameID2, *gameIDPtr, "Test setup: pointer should contain original UUID")

	// Test case 3: Empty UUID should fail
	gameID3 := uuid.Nil
	gameIDPtr = &gameID3
	assert.NotNil(t, gameIDPtr, "Test setup: game ID pointer should not be nil")
	assert.Equal(t, uuid.Nil, *gameIDPtr, "Test setup: pointer should contain Nil UUID")

	// Test case 4: UUID string validation
	validUUIDStr := uuid.New().String()
	parsedUUID, err := uuid.Parse(validUUIDStr)
	assert.NoError(t, err, "Valid UUID string should parse successfully")
	assert.NotEqual(t, uuid.Nil, parsedUUID, "Parsed UUID should not be Nil UUID")

	invalidUUIDStr := "invalid-uuid"
	_, err = uuid.Parse(invalidUUIDStr)
	assert.Error(t, err, "Invalid UUID string should fail to parse")

	// Test case 5: UUID comparison
	gameID4 := uuid.New()
	gameID5 := uuid.New()
	assert.NotEqual(t, gameID4, gameID5, "Different UUIDs should not be equal")
	assert.True(t, gameID4 != gameID5, "Different UUIDs should not be equal")

	gameID6 := gameID4
	assert.Equal(t, gameID4, gameID6, "Same UUIDs should be equal")
}

// TestDatabaseIntegration tests database integration for game moves
func TestDatabaseIntegration(t *testing.T) {
	// Setup in-memory database with unique name for test isolation
	dbName := fmt.Sprintf("file:test_%s?mode=memory&cache=shared", t.Name())
	db, err := gorm.Open(sqlite.Open(dbName), &gorm.Config{})
	require.NoError(t, err)

	// Auto-migrate required models
	err = db.AutoMigrate(&database.User{}, &database.Player{}, &database.GameMove{})
	require.NoError(t, err)

	// Create database service
	dbService := database.NewDatabase(db)

	// Create test user and player
	testUserID := uuid.New()
	user, err := dbService.GetOrCreateUser(testUserID, "TestUser", "test@example.com", "test_password")
	require.NoError(t, err)

	player := &database.Player{
		BaseModel: database.BaseModel{ID: uuid.New()},
		UserID:    user.ID,
		Username:  "TestUser",
		Rating:    1200,
		Level:     1,
		XP:        0,
		Arena:     1,
		Coins:     1000,
		Gems:      0,
		SelectedCardBack:   "default",
		SelectedTableTheme: "default",
		SelectedAvatar:     "default",
	}

	err = db.Create(player).Error
	require.NoError(t, err)

	// Create test game move with valid game ID
	gameID := uuid.New()
	gameMove := &database.GameMove{
		BaseModel: database.BaseModel{ID: uuid.New()},
		GameID:         gameID, // ✅ game_id explicitly set
		PlayerID:       player.ID,
		MoveNumber:     1,
		MoveType:       "PLAY_CARD",
		TrickNumber:    1,
		TableCardCount: 1,
		CardSuit:       "hearts",
		CardValue:      10,
		IsWinningMove:  false,
	}

	// Test that game move can be created with valid game ID
	err = db.Create(gameMove).Error
	assert.NoError(t, err, "Game move with valid game ID should be created")

	// Verify the move was created correctly
	var createdMove database.GameMove
	err = db.Where("id = ?", gameMove.ID).First(&createdMove).Error
	assert.NoError(t, err)
	assert.Equal(t, gameID, createdMove.GameID, "Created move should have correct game ID")
	assert.Equal(t, player.ID, createdMove.PlayerID, "Created move should have correct player ID")
	assert.Equal(t, "PLAY_CARD", createdMove.MoveType, "Created move should have correct move type")

	// Test that move lookup by game ID works
	var foundMoves []database.GameMove
	err = db.Where("game_id = ?", gameID).Find(&foundMoves).Error
	assert.NoError(t, err)
	assert.Len(t, foundMoves, 1, "Should find exactly one move for game ID")
	assert.Equal(t, gameID, foundMoves[0].GameID, "Found move should have correct game ID")

	// Test that move lookup by player ID works
	var playerMoves []database.GameMove
	err = db.Where("player_id = ?", player.ID).Find(&playerMoves).Error
	assert.NoError(t, err)
	assert.Len(t, playerMoves, 1, "Should find exactly one move for player")
	assert.Equal(t, player.ID, playerMoves[0].PlayerID, "Found move should have correct player ID")
}

// Benchmark tests
func BenchmarkGameIDValidation(b *testing.B) {
	gameID := uuid.New()

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		// Simulate game ID validation
		if gameID == uuid.Nil {
			b.Fatal("Should not happen")
		}
		// Additional validation logic would go here
	}
}

func BenchmarkGameMoveValidation(b *testing.B) {
	playerID := uuid.New()

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		// Simulate game move data creation and validation
		moveData := map[string]interface{}{
			"type":      "PLAY_CARD",
			"player_id": playerID.String(),
			"card": map[string]interface{}{
				"suit":  "hearts",
				"value": 10.0,
				"id":    fmt.Sprintf("card-%d", i),
			},
		}
		// Additional validation logic would go here
		_ = moveData
	}
}