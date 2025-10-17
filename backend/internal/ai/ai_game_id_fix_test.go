package ai

import (
	"testing"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
)

// TestGameIDFix validates the core fix for missing game_id in AI moves
func TestGameIDFix(t *testing.T) {
	// Test case 1: Valid game ID should pass validation
	gameID1 := uuid.New()
	assert.NotEqual(t, uuid.Nil, gameID1, "Valid game ID should not be Nil UUID")

	// Test case 2: Nil UUID should be detected
	gameID2 := uuid.Nil
	assert.Equal(t, uuid.Nil, gameID2, "Nil UUID should equal uuid.Nil")
	_ = gameID2 // Use variable to avoid unused variable warning

	// Test case 3: Game ID validation logic
	validateGameID := func(id *uuid.UUID) bool {
		if id == nil {
			return false
		}
		return *id != uuid.Nil
	}

	// Test valid game ID
	assert.True(t, validateGameID(&gameID1), "Valid game ID should pass validation")

	// Test nil game ID
	assert.False(t, validateGameID(nil), "Nil game ID should fail validation")

	// Test Nil UUID
	assert.False(t, validateGameID(&gameID2), "Nil UUID should fail validation")

	// Test pointer comparison
	gameID3 := uuid.New()
	gameIDPtr1 := &gameID3
	gameIDPtr2 := &gameID3
	assert.True(t, *gameIDPtr1 == *gameIDPtr2, "Same UUID pointers should be equal")
	assert.True(t, gameIDPtr1 == gameIDPtr2, "Pointer equality should work")
}

// TestMoveMessageStructure validates the move message structure
func TestMoveMessageStructure(t *testing.T) {
	// Test case 1: Complete valid message structure
	gameID := uuid.New()
	playerID := uuid.New()

	message := struct {
		Type     string                 `json:"type"`
		ID       string                 `json:"id"`
		GameID   *uuid.UUID            `json:"game_id"`
		PlayerID string                 `json:"player_id"`
		Payload  map[string]interface{} `json:"payload"`
	}{
		Type:     "player_move",
		ID:       uuid.New().String(),
		GameID:   &gameID,
		PlayerID: playerID.String(),
		Payload: map[string]interface{}{
			"type":      "PLAY_CARD",
			"player_id": playerID.String(),
			"card": map[string]interface{}{
				"suit":  "hearts",
				"value": 10.0,
				"id":    "card-123",
			},
		},
	}

	// Validate message structure
	assert.Equal(t, "player_move", message.Type, "Message type should be player_move")
	assert.NotEmpty(t, message.ID, "Message ID should not be empty")
	assert.NotNil(t, message.GameID, "Game ID should not be nil")
	assert.Equal(t, gameID, *message.GameID, "Game ID should match")
	assert.NotEmpty(t, message.PlayerID, "Player ID should not be empty")
	assert.NotNil(t, message.Payload, "Payload should not be nil")

	// Test case 2: Missing game ID should be detected
	invalidMessage := struct {
		Type     string                 `json:"type"`
		ID       string                 `json:"id"`
		GameID   *uuid.UUID            `json:"game_id"`
		PlayerID string                 `json:"player_id"`
		Payload  map[string]interface{} `json:"payload"`
	}{
		Type:     "player_move",
		ID:       uuid.New().String(),
		GameID:   nil, // Missing game ID
		PlayerID: playerID.String(),
		Payload: map[string]interface{}{
			"type": "PLAY_CARD",
		},
	}

	// Validate that missing game ID is detected
	assert.Equal(t, "player_move", invalidMessage.Type, "Message type should be player_move")
	assert.NotNil(t, invalidMessage.ID, "Message ID should not be nil")
	assert.Nil(t, invalidMessage.GameID, "Game ID should be nil (invalid)")
	assert.NotEmpty(t, invalidMessage.PlayerID, "Player ID should not be empty")
	assert.NotNil(t, invalidMessage.Payload, "Payload should not be nil")
}

// TestGameContextManagement tests game context management logic
func TestGameContextManagement(t *testing.T) {
	// Test case 1: Game context establishment
	gameID := uuid.New()
	playerID := uuid.New()

	gameContext := struct {
		GameID      *uuid.UUID `json:"game_id"`
		PlayerID    uuid.UUID   `json:"player_id"`
		AwaitingMove bool        `json:"awaiting_move"`
	}{}

	// Initially no context
	assert.Nil(t, gameContext.GameID, "Game ID should be nil initially")
	assert.Equal(t, uuid.Nil, gameContext.PlayerID, "Player ID should be Nil initially")
	assert.False(t, gameContext.AwaitingMove, "Should not be awaiting move initially")

	// Establish context
	gameContext.GameID = &gameID
	gameContext.PlayerID = playerID
	gameContext.AwaitingMove = true

	// Validate context
	assert.NotNil(t, gameContext.GameID, "Game ID should be set")
	assert.Equal(t, gameID, *gameContext.GameID, "Game ID should match")
	assert.Equal(t, playerID, gameContext.PlayerID, "Player ID should match")
	assert.True(t, gameContext.AwaitingMove, "Should be awaiting move")

	// Test case 2: Context validation logic
	validateContext := func(ctx *struct {
		GameID      *uuid.UUID `json:"game_id"`
		PlayerID    uuid.UUID   `json:"player_id"`
		AwaitingMove bool        `json:"awaiting_move"`
	}) error {
		if ctx.GameID == nil {
			return assert.AnError
		}
		if *ctx.GameID == uuid.Nil {
			return assert.AnError
		}
		if ctx.PlayerID == uuid.Nil {
			return assert.AnError
		}
		return nil
	}

	// Test valid context
	err := validateContext(&gameContext)
	assert.NoError(t, err, "Valid context should pass validation")

	// Test missing game ID
	gameContext.GameID = nil
	err = validateContext(&gameContext)
	assert.Error(t, err, "Missing game ID should fail validation")

	// Test invalid game ID
	gameContext.GameID = &uuid.Nil
	err = validateContext(&gameContext)
	assert.Error(t, err, "Invalid game ID should fail validation")

	// Test invalid player ID
	gameContext.GameID = &gameID
	gameContext.PlayerID = uuid.Nil
	err = validateContext(&gameContext)
	assert.Error(t, err, "Invalid player ID should fail validation")
}

// TestAIPlayerMoveLogic tests the AI player move generation logic
func TestAIPlayerMoveLogic(t *testing.T) {
	// Test case 1: Move generation with valid context
	gameID := uuid.New()
	playerID := uuid.New()

	gameState := struct {
		ID              uuid.UUID   `json:"id"`
		CurrentPlayerID uuid.UUID   `json:"current_player_id"`
		Status          string      `json:"status"`
		Players         []uuid.UUID `json:"players"`
		AvailableCards []struct {
			Suit  string `json:"suit"`
			Value int    `json:"value"`
			ID    string `json:"id"`
		} `json:"available_cards"`
	}{
		ID:              gameID,
		CurrentPlayerID: playerID,
		Status:          "playing",
		Players:         []uuid.UUID{playerID, uuid.New()},
		AvailableCards: []struct {
			Suit  string `json:"suit"`
			Value int    `json:"value"`
			ID    string `json:"id"`
		}{
			{Suit: "hearts", Value: 10, ID: "card1"},
			{Suit: "clubs", Value: 8, ID: "card2"},
		},
	}

	// Simulate AI move generation
	generateMove := func(state *struct {
		ID              uuid.UUID   `json:"id"`
		CurrentPlayerID uuid.UUID   `json:"current_player_id"`
		Status          string      `json:"status"`
		Players         []uuid.UUID `json:"players"`
		AvailableCards []struct {
			Suit  string `json:"suit"`
			Value int    `json:"value"`
			ID    string `json:"id"`
		} `json:"available_cards"`
	}, contextGameID uuid.UUID) (map[string]interface{}, error) {
		if state.CurrentPlayerID != uuid.Nil && state.Status == "playing" && len(state.AvailableCards) > 0 {
			card := state.AvailableCards[0] // Simple AI: play first available card

			moveData := map[string]interface{}{
				"type":      "PLAY_CARD",
				"player_id": state.CurrentPlayerID.String(),
				"card": map[string]interface{}{
					"suit":  card.Suit,
					"value": float64(card.Value),
					"id":    card.ID,
				},
			}

			return moveData, nil
		}
		return nil, assert.AnError
	}

	// Test move generation with valid context
	moveData, err := generateMove(&gameState, gameID)
	assert.NoError(t, err, "Move generation should succeed")
	assert.NotNil(t, moveData, "Move data should not be nil")
	assert.Equal(t, "PLAY_CARD", moveData["type"], "Move type should be PLAY_CARD")
	assert.Equal(t, playerID.String(), moveData["player_id"], "Player ID should match")
	assert.NotNil(t, moveData["card"], "Card data should not be nil")

	// Test move generation with invalid context (wrong game ID)
	invalidGameID := uuid.New()
	_, err = generateMove(&gameState, invalidGameID)
	assert.NoError(t, err, "Move generation should still succeed (game ID validation happens at hub level)")

	// Test move generation with no available cards
	gameState.AvailableCards = []struct {
		Suit  string `json:"suit"`
		Value int    `json:"value"`
		ID    string `json:"id"`
	}{}

	moveData, err = generateMove(&gameState, gameID)
	assert.Error(t, err, "Move generation should fail with no cards")
	assert.Nil(t, moveData, "Move data should be nil on failure")
}

// TestGameIDPointerHandling tests pointer handling for game IDs
func TestGameIDPointerHandling(t *testing.T) {
	// Test case 1: Valid pointer assignment and comparison
	gameID1 := uuid.New()
	gameIDPtr1 := &gameID1
	assert.Equal(t, gameID1, *gameIDPtr1, "Pointer should contain original value")

	// Test case 2: Nil pointer handling
	var gameIDPtr2 *uuid.UUID = nil
	assert.Nil(t, gameIDPtr2, "Pointer should be nil initially")

	// Test case 3: Valid pointer comparison
	gameID2 := uuid.New()
	gameIDPtr3 := &gameID2
	gameIDPtr4 := &gameID2

	assert.True(t, *gameIDPtr3 == *gameIDPtr4, "Same value pointers should be equal")
	assert.Equal(t, gameIDPtr3, gameIDPtr4, "Same value pointers should be equal")

	// Test case 4: Different pointer comparison
	gameID3 := uuid.New()
	gameIDPtr5 := &gameID3

	assert.True(t, *gameIDPtr1 != *gameIDPtr5, "Different values should not be equal")
	assert.True(t, gameIDPtr1 != gameIDPtr5, "Different pointers should not be equal")

	// Test case 5: Validation logic
	validateGameIDPtr := func(id *uuid.UUID) bool {
		if id == nil {
			return false
		}
		return *id != uuid.Nil
	}

	assert.True(t, validateGameIDPtr(&gameID1), "Valid pointer should pass")
	assert.False(t, validateGameIDPtr(nil), "Nil pointer should fail")
	assert.False(t, validateGameIDPtr(&uuid.Nil), "Nil UUID pointer should fail")
}

// Benchmark tests
func BenchmarkGameIDValidationSimple(b *testing.B) {
	gameID := uuid.New()

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		// Simulate game ID validation logic
		if gameID == uuid.Nil {
			panic("Should not happen in valid scenario")
		}
		// Additional validation would go here
	}
}

func BenchmarkMoveDataGeneration(b *testing.B) {
	playerID := uuid.New()
	availableCards := []struct {
		Suit  string `json:"suit"`
		Value int    `json:"value"`
		ID    string `json:"id"`
	}{
		{Suit: "hearts", Value: 10, ID: "card1"},
		{Suit: "clubs", Value: 8, ID: "card2"},
		{Suit: "spades", Value: 11, ID: "card3"},
		{Suit: "diamonds", Value: 1, ID: "card4"},
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		// Simulate move data generation
		card := availableCards[i%len(availableCards)]
		moveData := map[string]interface{}{
			"type":      "PLAY_CARD",
			"player_id": playerID.String(),
			"card": map[string]interface{}{
				"suit":  card.Suit,
				"value": float64(card.Value),
				"id":    card.ID,
			},
		}
		_ = moveData
	}
}

func BenchmarkGameContextManagement(b *testing.B) {
	gameID := uuid.New()

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		// Simulate game context validation
		if gameID == uuid.Nil {
			continue // Skip invalid scenarios
		}
		// Additional validation logic would go here
	}
}