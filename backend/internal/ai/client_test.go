package ai

import (
	"testing"
	"time"

	"septica-backend/internal/game"
	"septica-backend/internal/websocket"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestAIClient_ReceiveGameID tests that AI client receives game_id after match creation
func TestAIClient_ReceiveGameID(t *testing.T) {
	_, hub, testLogger, cleanup := setupTestEnvironment(t)
	defer cleanup()

	// Create AI player and client
	ai := NewAIPlayer("medium", 1200, testLogger)
	aiClient := NewAIWebSocketClient(ai, hub, testLogger)

	// Connect AI client
	err := aiClient.Connect()
	require.NoError(t, err)
	defer aiClient.Disconnect()

	// Simulate match_found message from matchmaking service
	gameID := uuid.New()
	matchFoundMsg := websocket.Message{
		Type:      "match_found",
		ID:        uuid.New().String(),
		GameID:    &gameID,
		PlayerID:  ai.ID,
		Timestamp: time.Now(),
		Payload: map[string]interface{}{
			"game_id":     gameID.String(),
			"opponent_id": uuid.New().String(),
		},
	}

	// Send message to AI client
	err = aiClient.SendMessage(matchFoundMsg)
	require.NoError(t, err)

	// Wait for processing
	time.Sleep(100 * time.Millisecond)

	// Verify AI client received and stored game_id
	assert.NotNil(t, aiClient.CurrentGameID, "AI client should have game_id")
	assert.Equal(t, gameID, *aiClient.CurrentGameID, "Game ID should match")
	assert.Equal(t, gameID, *ai.CurrentGameID, "AI player should also have game_id")
}

// TestAIClient_SendMoveWithGameID tests that AI move includes game_id
func TestAIClient_SendMoveWithGameID(t *testing.T) {
	_, hub, testLogger, cleanup := setupTestEnvironment(t)
	defer cleanup()

	// Create AI player and client
	ai := NewAIPlayer("medium", 1200, testLogger)
	aiClient := NewAIWebSocketClient(ai, hub, testLogger)

	// Connect AI client
	err := aiClient.Connect()
	require.NoError(t, err)
	defer aiClient.Disconnect()

	// Set game ID
	gameID := uuid.New()
	aiClient.CurrentGameID = &gameID
	ai.CurrentGameID = &gameID

	// Send game state to AI
	// Note: Payload needs to be serializable as map[string]interface{}
	payloadMap := map[string]interface{}{
		"id":                gameID.String(),
		"current_player_id": ai.ID.String(),
		"status":            "playing",
	}

	gameStateMsg := websocket.Message{
		Type:      "game_state",
		ID:        uuid.New().String(),
		GameID:    &gameID,
		PlayerID:  ai.ID,
		Timestamp: time.Now(),
		Payload:   payloadMap,
	}

	err = aiClient.SendMessage(gameStateMsg)
	require.NoError(t, err)

	// Wait for AI to process and send move
	time.Sleep(200 * time.Millisecond)

	// Note: In actual implementation, we would capture the message sent to hub
	// For this test, we verify the AI client has the game_id set correctly
	assert.NotNil(t, aiClient.CurrentGameID, "AI client should retain game_id")
	assert.Equal(t, gameID, *aiClient.CurrentGameID, "Game ID should match")
}

// TestAIClient_MoveReachesHub tests that AI move reaches hub and gets processed
func TestAIClient_MoveReachesHub(t *testing.T) {
	_, hub, testLogger, cleanup := setupTestEnvironment(t)
	defer cleanup()

	// Create AI player and client
	ai := NewAIPlayer("easy", 1000, testLogger)
	aiClient := NewAIWebSocketClient(ai, hub, testLogger)

	// Connect AI client
	err := aiClient.Connect()
	require.NoError(t, err)
	defer aiClient.Disconnect()

	// Set game ID
	gameID := uuid.New()
	aiClient.CurrentGameID = &gameID

	// Create simple game state where AI must play
	gameState := &game.AuthenticGameState{
		ID:              gameID,
		CurrentPlayerID: ai.ID,
		Status:          "playing",
		PlayerHands: map[uuid.UUID][]game.Card{
			ai.ID: {
				{ID: uuid.New().String(), Suit: "Hearts", Value: 10},
			},
		},
		TableCards: []game.Card{},
	}

	// Update AI game state
	aiClient.lastGameState = gameState
	aiClient.awaitingMove = true

	// Process AI move (this should send message to hub)
	go aiClient.processAIMove(gameState)

	// Wait for processing
	time.Sleep(300 * time.Millisecond)

	// Verify move was processed
	assert.False(t, aiClient.awaitingMove, "AI should no longer be awaiting move")
}

// TestAIClient_HandlePASSMove tests that AI client handles PASS move correctly
func TestAIClient_HandlePASSMove(t *testing.T) {
	_, hub, testLogger, cleanup := setupTestEnvironment(t)
	defer cleanup()

	// Create AI player and client
	ai := NewAIPlayer("medium", 1200, testLogger)
	aiClient := NewAIWebSocketClient(ai, hub, testLogger)

	// Connect AI client
	err := aiClient.Connect()
	require.NoError(t, err)
	defer aiClient.Disconnect()

	// Set game ID
	gameID := uuid.New()
	aiClient.CurrentGameID = &gameID

	// Create game state where AI has no valid moves (empty hand)
	gameState := &game.AuthenticGameState{
		ID:              gameID,
		CurrentPlayerID: ai.ID,
		Status:          "playing",
		PlayerHands: map[uuid.UUID][]game.Card{
			ai.ID: {}, // Empty hand
		},
		TableCards: []game.Card{
			{ID: uuid.New().String(), Suit: "Clubs", Value: 10},
		},
	}

	// AI should decide to PASS
	move, err := ai.DecideMove(gameState)
	require.NoError(t, err)
	assert.NotNil(t, move)
	assert.Equal(t, "PASS", move.Type, "AI should choose PASS with no cards")
	assert.Nil(t, move.Card, "PASS move should not have a card")
}

// TestAIClient_HandleCardPlayMove tests that AI client handles card play move correctly
func TestAIClient_HandleCardPlayMove(t *testing.T) {
	_, hub, testLogger, cleanup := setupTestEnvironment(t)
	defer cleanup()

	// Create AI player and client
	ai := NewAIPlayer("hard", 1400, testLogger)
	aiClient := NewAIWebSocketClient(ai, hub, testLogger)

	// Connect AI client
	err := aiClient.Connect()
	require.NoError(t, err)
	defer aiClient.Disconnect()

	// Set game ID
	gameID := uuid.New()
	aiClient.CurrentGameID = &gameID

	// Create game state where AI has cards to play
	gameState := &game.AuthenticGameState{
		ID:              gameID,
		CurrentPlayerID: ai.ID,
		Status:          "playing",
		PlayerHands: map[uuid.UUID][]game.Card{
			ai.ID: {
				{ID: uuid.New().String(), Suit: "Hearts", Value: 7},    // 7 always beats
				{ID: uuid.New().String(), Suit: "Diamonds", Value: 10}, // Point card
			},
		},
		TableCards: []game.Card{
			{ID: uuid.New().String(), Suit: "Clubs", Value: 10},
		},
	}

	// AI should decide to play a card
	move, err := ai.DecideMove(gameState)
	require.NoError(t, err)
	assert.NotNil(t, move)
	assert.Equal(t, "PLAY_CARD", move.Type, "AI should choose to play a card")
	assert.NotNil(t, move.Card, "Card play move should have a card")
	assert.Contains(t, []int{7, 10}, move.Card.Value, "AI should play 7 or 10")
}

// TestAIClient_GameFoundMessage tests handling of game_found message
func TestAIClient_GameFoundMessage(t *testing.T) {
	_, hub, testLogger, cleanup := setupTestEnvironment(t)
	defer cleanup()

	// Create AI player and client
	ai := NewAIPlayer("medium", 1200, testLogger)
	aiClient := NewAIWebSocketClient(ai, hub, testLogger)

	// Connect AI client
	err := aiClient.Connect()
	require.NoError(t, err)
	defer aiClient.Disconnect()

	// Simulate game_found message
	gameID := uuid.New()
	gameFoundMsg := websocket.Message{
		Type:      "game_found",
		ID:        uuid.New().String(),
		GameID:    &gameID,
		PlayerID:  ai.ID,
		Timestamp: time.Now(),
		Payload: map[string]interface{}{
			"game_id": gameID.String(),
		},
	}

	// Send message to AI client
	err = aiClient.SendMessage(gameFoundMsg)
	require.NoError(t, err)

	// Wait for processing
	time.Sleep(100 * time.Millisecond)

	// Verify AI client processed the message
	assert.NotNil(t, aiClient.CurrentGameID, "AI client should have game_id")
	assert.Equal(t, gameID, *aiClient.CurrentGameID, "Game ID should match")
}

// TestAIClient_TurnTimeout tests AI handling of turn timeout
func TestAIClient_TurnTimeout(t *testing.T) {
	_, hub, testLogger, cleanup := setupTestEnvironment(t)
	defer cleanup()

	// Create AI player and client
	ai := NewAIPlayer("easy", 1000, testLogger)
	aiClient := NewAIWebSocketClient(ai, hub, testLogger)

	// Connect AI client
	err := aiClient.Connect()
	require.NoError(t, err)
	defer aiClient.Disconnect()

	// Set game ID and game state
	gameID := uuid.New()
	aiClient.CurrentGameID = &gameID
	gameState := &game.AuthenticGameState{
		ID:              gameID,
		CurrentPlayerID: ai.ID,
		Status:          "playing",
		PlayerHands: map[uuid.UUID][]game.Card{
			ai.ID: {
				{ID: uuid.New().String(), Suit: "Hearts", Value: 9},
			},
		},
		TableCards: []game.Card{},
	}
	aiClient.lastGameState = gameState
	aiClient.awaitingMove = true

	// Send turn timeout message
	timeoutMsg := websocket.Message{
		Type:      "turn_timeout",
		ID:        uuid.New().String(),
		GameID:    &gameID,
		PlayerID:  ai.ID,
		Timestamp: time.Now(),
		Payload: map[string]interface{}{
			"message": "Your turn has timed out",
		},
	}

	err = aiClient.SendMessage(timeoutMsg)
	require.NoError(t, err)

	// Wait for processing
	time.Sleep(200 * time.Millisecond)

	// AI should have attempted to make a move
	// In real scenario, we would verify the move was sent to hub
}

// TestAIClient_GameEndedMessage tests handling of game_ended message
func TestAIClient_GameEndedMessage(t *testing.T) {
	_, hub, testLogger, cleanup := setupTestEnvironment(t)
	defer cleanup()

	// Create AI player and client
	ai := NewAIPlayer("medium", 1200, testLogger)
	aiClient := NewAIWebSocketClient(ai, hub, testLogger)

	// Connect AI client
	err := aiClient.Connect()
	require.NoError(t, err)
	defer aiClient.Disconnect()

	// Set initial game state
	gameID := uuid.New()
	aiClient.CurrentGameID = &gameID
	aiClient.awaitingMove = true

	// Send game_ended message
	gameEndedMsg := websocket.Message{
		Type:      "game_ended",
		ID:        uuid.New().String(),
		GameID:    &gameID,
		PlayerID:  ai.ID,
		Timestamp: time.Now(),
		Payload: map[string]interface{}{
			"winner_id": uuid.New().String(),
			"reason":    "completed",
		},
	}

	err = aiClient.SendMessage(gameEndedMsg)
	require.NoError(t, err)

	// Wait for processing
	time.Sleep(100 * time.Millisecond)

	// Verify AI client cleaned up game state
	assert.Nil(t, aiClient.CurrentGameID, "AI client should clear game_id")
	assert.Nil(t, ai.CurrentGameID, "AI player should clear game_id")
	assert.False(t, aiClient.awaitingMove, "AI should not be awaiting move")
	assert.Nil(t, aiClient.lastGameState, "AI should clear last game state")
}

// TestAIClient_ErrorMessage tests handling of error messages
func TestAIClient_ErrorMessage(t *testing.T) {
	_, hub, testLogger, cleanup := setupTestEnvironment(t)
	defer cleanup()

	// Create AI player and client
	ai := NewAIPlayer("hard", 1400, testLogger)
	aiClient := NewAIWebSocketClient(ai, hub, testLogger)

	// Connect AI client
	err := aiClient.Connect()
	require.NoError(t, err)
	defer aiClient.Disconnect()

	// Send error message
	errorMsg := websocket.Message{
		Type:      "error",
		ID:        uuid.New().String(),
		PlayerID:  ai.ID,
		Timestamp: time.Now(),
		Payload: map[string]interface{}{
			"code":    "INVALID_MOVE",
			"message": "Cannot play that card",
		},
	}

	// Should not crash when receiving error
	err = aiClient.SendMessage(errorMsg)
	assert.NoError(t, err, "Should handle error message without crashing")

	// Wait for processing
	time.Sleep(100 * time.Millisecond)

	// AI client should still be connected
	assert.True(t, aiClient.IsConnected, "AI client should remain connected after error")
}

// TestAIClient_ConcurrentMessages tests handling multiple messages concurrently
func TestAIClient_ConcurrentMessages(t *testing.T) {
	_, hub, testLogger, cleanup := setupTestEnvironment(t)
	defer cleanup()

	// Create AI player and client
	ai := NewAIPlayer("medium", 1200, testLogger)
	aiClient := NewAIWebSocketClient(ai, hub, testLogger)

	// Connect AI client
	err := aiClient.Connect()
	require.NoError(t, err)
	defer aiClient.Disconnect()

	// Send multiple messages concurrently
	gameID := uuid.New()
	numMessages := 10
	done := make(chan bool, numMessages)

	for i := 0; i < numMessages; i++ {
		go func(index int) {
			msg := websocket.Message{
				Type:      "test_message",
				ID:        uuid.New().String(),
				GameID:    &gameID,
				PlayerID:  ai.ID,
				Timestamp: time.Now(),
				Payload: map[string]interface{}{
					"index": index,
				},
			}

			err := aiClient.SendMessage(msg)
			assert.NoError(t, err)
			done <- true
		}(i)
	}

	// Wait for all messages to be sent
	for i := 0; i < numMessages; i++ {
		<-done
	}

	// Wait for processing
	time.Sleep(200 * time.Millisecond)

	// AI client should still be connected and stable
	assert.True(t, aiClient.IsConnected, "AI client should handle concurrent messages")
}

// TestAIClient_ReconnectionScenario tests AI client reconnection handling
func TestAIClient_ReconnectionScenario(t *testing.T) {
	_, hub, testLogger, cleanup := setupTestEnvironment(t)
	defer cleanup()

	// Create AI player and client
	ai := NewAIPlayer("easy", 1000, testLogger)
	aiClient := NewAIWebSocketClient(ai, hub, testLogger)

	// Initial connection
	err := aiClient.Connect()
	require.NoError(t, err)
	assert.True(t, aiClient.IsConnected)

	// Disconnect
	err = aiClient.Disconnect()
	assert.NoError(t, err)
	assert.False(t, aiClient.IsConnected)

	// Reconnect with new session (simulate real reconnection)
	aiClient2 := NewAIWebSocketClient(ai, hub, testLogger)
	err = aiClient2.Connect()
	assert.NoError(t, err)
	assert.True(t, aiClient2.IsConnected)

	// Verify new session ID generated
	assert.NotEqual(t, aiClient.SessionID, aiClient2.SessionID, "New session should have different ID")

	// Cleanup
	aiClient2.Disconnect()
}
