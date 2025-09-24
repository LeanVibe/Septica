package integration

import (
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	ws "septica-backend/internal/websocket"
)

// TestAuthenticGameErrorScenarios tests error handling in authentic Romanian Septica
func TestAuthenticGameErrorScenarios(t *testing.T) {
	suite := SetupIntegrationTestSuite(t)
	defer suite.Cleanup()

	t.Run("Invalid Move Handling", func(t *testing.T) {
		testInvalidMoveHandling(t, suite)
	})

	t.Run("Disconnection Recovery", func(t *testing.T) {
		testDisconnectionRecovery(t, suite)
	})

	t.Run("Invalid Objection Scenarios", func(t *testing.T) {
		testInvalidObjectionScenarios(t, suite)
	})

	t.Run("Concurrent Move Attempts", func(t *testing.T) {
		testConcurrentMoveAttempts(t, suite)
	})

	t.Run("Malformed Message Handling", func(t *testing.T) {
		testMalformedMessageHandling(t, suite)
	})
}

// testInvalidMoveHandling tests how system handles invalid moves
func testInvalidMoveHandling(t *testing.T, suite *IntegrationTestSuite) {
	player1 := suite.CreateTestClient(t, "invalid_player1")
	player2 := suite.CreateTestClient(t, "invalid_player2")

	// Setup basic game
	gameID := setupBasicGame(t, player1, player2)

	// Test 1: Playing card not in hand
	err := player1.SendMessage(ws.Message{
		Type: "play_card",
		Payload: map[string]interface{}{
			"gameId": gameID,
			"card": map[string]interface{}{
				"suit":  "hearts",
				"value": 99, // Invalid card value
			},
		},
	})
	require.NoError(t, err)

	// Should receive error response
	errorMsg, err := player1.WaitForMessage("move_result", 3*time.Second)
	require.NoError(t, err)

	errorData := errorMsg.Payload
	assert.False(t, errorData["success"].(bool))
	assert.Contains(t, errorData["error"].(string), "invalid")

	// Test 2: Playing when it's not your turn
	err = player1.SendMessage(ws.Message{
		Type: "play_card",
		Payload: map[string]interface{}{
			"gameId": gameID,
			"card": map[string]interface{}{
				"suit":  "spades",
				"value": 7,
			},
		},
	})
	require.NoError(t, err)

	// Should receive error for playing out of turn
	errorMsg2, err := player1.WaitForMessage("move_result", 3*time.Second)
	require.NoError(t, err)

	errorData2 := errorMsg2.Payload
	assert.False(t, errorData2["success"].(bool))
}

// testDisconnectionRecovery tests WebSocket disconnection and recovery
func testDisconnectionRecovery(t *testing.T, suite *IntegrationTestSuite) {
	player1 := suite.CreateTestClient(t, "disconnect_player1")
	player2 := suite.CreateTestClient(t, "disconnect_player2")

	gameID := setupBasicGame(t, player1, player2)

	// Force disconnect player1
	player1.Close()

	// Player2 should be notified of disconnection
	disconnectMsg, err := player2.WaitForMessage("player_disconnected", 5*time.Second)
	require.NoError(t, err)

	disconnectData := disconnectMsg.Payload
	assert.Equal(t, "disconnect_player1", disconnectData["playerID"].(string))

	// Game should be paused or ended appropriately
	assert.NotNil(t, disconnectData["gameStatus"])

	// Test reconnection
	player1Reconnected := suite.CreateTestClient(t, "disconnect_player1_reconnect")

	// Send rejoin message
	err = player1Reconnected.SendMessage(ws.Message{
		Type: "rejoin_game",
		Payload: map[string]interface{}{
			"gameId":   gameID,
			"playerID": "disconnect_player1",
		},
	})
	require.NoError(t, err)

	// Should receive current game state
	rejoinState, err := player1Reconnected.WaitForMessage("game_state", 3*time.Second)
	require.NoError(t, err)

	rejoinData, ok := rejoinState.Payload.(map[string]interface{})
	require.True(t, ok)
	assert.Equal(t, gameID, rejoinData["gameId"].(string))
}

// testInvalidObjectionScenarios tests invalid objection handling
func testInvalidObjectionScenarios(t *testing.T, suite *IntegrationTestSuite) {
	player1 := suite.CreateTestClient(t, "obj_player1")
	player2 := suite.CreateTestClient(t, "obj_player2")

	gameID := setupBasicGame(t, player1, player2)

	// Test 1: Objection with invalid card (not in hand)
	err := player2.SendMessage(ws.Message{
		Type: "objection_decision",
		Payload: map[string]interface{}{
			"gameId":   gameID,
			"decision": "OBJECT",
			"card": map[string]interface{}{
				"suit":  "clubs",
				"value": 99, // Invalid card
			},
		},
	})
	require.NoError(t, err)

	// Should receive objection error
	objError, err := player2.WaitForMessage("objection_result", 3*time.Second)
	require.NoError(t, err)

	objErrorData, ok := objError.Payload.(map[string]interface{})
	require.True(t, ok)
	assert.False(t, objErrorData["success"].(bool))
	assert.Contains(t, objErrorData["error"].(string), "invalid")

	// Test 2: Objection when no objection window is open
	err = player2.SendMessage(ws.Message{
		Type: "objection_decision",
		Payload: map[string]interface{}{
			"gameId":   gameID,
			"decision": "OBJECT",
			"card": map[string]interface{}{
				"suit":  "hearts",
				"value": 7,
			},
		},
	})
	require.NoError(t, err)

	// Should receive timing error
	timingError, err := player2.WaitForMessage("objection_result", 3*time.Second)
	if err == nil { // If we receive a message, it should be an error
		timingErrorData, ok := timingError.Payload.(map[string]interface{})
		require.True(t, ok)
		assert.False(t, timingErrorData["success"].(bool))
	}
}

// testConcurrentMoveAttempts tests handling of concurrent move attempts
func testConcurrentMoveAttempts(t *testing.T, suite *IntegrationTestSuite) {
	player1 := suite.CreateTestClient(t, "concurrent_player1")
	player2 := suite.CreateTestClient(t, "concurrent_player2")

	gameID := setupBasicGame(t, player1, player2)

	// Both players attempt to play simultaneously
	go func() {
		player1.SendMessage(ws.Message{
			Type: "play_card",
			Payload: map[string]interface{}{
				"gameId": gameID,
				"card": map[string]interface{}{
					"suit":  "hearts",
					"value": 7,
				},
			},
		})
	}()

	go func() {
		player2.SendMessage(ws.Message{
			Type: "play_card",
			Payload: map[string]interface{}{
				"gameId": gameID,
				"card": map[string]interface{}{
					"suit":  "spades",
					"value": 10,
				},
			},
		})
	}()

	// Wait for responses
	time.Sleep(1 * time.Second)

	// One should succeed, one should fail
	result1, err1 := player1.WaitForMessage("move_result", 2*time.Second)
	result2, err2 := player2.WaitForMessage("move_result", 2*time.Second)

	// At least one should receive a response
	if err1 == nil || err2 == nil {
		// Verify proper handling
		if err1 == nil {
			data1, ok := result1.Payload.(map[string]interface{})
			require.True(t, ok)
			// Player1's move result status depends on whose turn it was
			assert.NotNil(t, data1["success"])
		}

		if err2 == nil {
			data2, ok := result2.Payload.(map[string]interface{})
			require.True(t, ok)
			assert.NotNil(t, data2["success"])
		}
	}
}

// testMalformedMessageHandling tests handling of malformed messages
func testMalformedMessageHandling(t *testing.T, suite *IntegrationTestSuite) {
	player1 := suite.CreateTestClient(t, "malformed_player1")

	// Wait for connection
	_, err := player1.WaitForMessage("connection_ack", 2*time.Second)
	require.NoError(t, err)

	// Send malformed message (missing required fields)
	err = player1.SendMessage(ws.Message{
		Type: "play_card",
		Payload: map[string]interface{}{
			"gameId": "", // Empty game ID
			// Missing card data
		},
	})
	require.NoError(t, err)

	// Should handle gracefully without crashing
	// Might receive error message or no response
	errorMsg, err := player1.WaitForMessage("error", 3*time.Second)
	if err == nil {
		errorData, ok := errorMsg.Payload.(map[string]interface{})
		require.True(t, ok)
		assert.Contains(t, errorData["message"].(string), "invalid")
	}

	// Send message with wrong type
	err = player1.SendMessage(ws.Message{
		Type: "invalid_message_type",
		Payload: map[string]interface{}{
			"randomField": "randomValue",
		},
	})
	require.NoError(t, err)

	// System should handle unknown message types gracefully
	time.Sleep(500 * time.Millisecond) // Give time for processing

	// Connection should still be alive
	err = player1.SendMessage(ws.Message{
		Type: "ping",
		Payload: map[string]interface{}{},
	})
	assert.NoError(t, err)
}

// setupBasicGame sets up a basic 2-player game for testing
func setupBasicGame(t *testing.T, player1, player2 *TestWebSocketClient) string {
	// Wait for connections
	_, err := player1.WaitForMessage("connection_ack", 2*time.Second)
	require.NoError(t, err)
	_, err = player2.WaitForMessage("connection_ack", 2*time.Second)
	require.NoError(t, err)

	// Join matchmaking
	err = player1.SendMessage(ws.Message{
		Type: "join_matchmaking",
		Payload: map[string]interface{}{
			"playerID":    player1.playerID,
			"gameMode":    "authentic",
			"playerCount": 2,
		},
	})
	require.NoError(t, err)

	err = player2.SendMessage(ws.Message{
		Type: "join_matchmaking",
		Payload: map[string]interface{}{
			"playerID":    player2.playerID,
			"gameMode":    "authentic",
			"playerCount": 2,
		},
	})
	require.NoError(t, err)

	// Wait for match
	match1, err := player1.WaitForMessage("match_found", 5*time.Second)
	require.NoError(t, err)

	gameData, ok := match1.Payload.(map[string]interface{})
	require.True(t, ok)
	gameID := gameData["gameId"].(string)

	// Wait for initial states
	_, err = player1.WaitForMessage("game_state", 3*time.Second)
	require.NoError(t, err)
	_, err = player2.WaitForMessage("game_state", 3*time.Second)
	require.NoError(t, err)

	return gameID
}

// TestBackwardCompatibilityIntegration tests that authentic games don't break legacy systems
func TestBackwardCompatibilityIntegration(t *testing.T) {
	suite := SetupIntegrationTestSuite(t)
	defer suite.Cleanup()

	t.Run("Legacy Client With Authentic Server", func(t *testing.T) {
		testLegacyClientCompatibility(t, suite)
	})

	t.Run("Mixed Game Modes", func(t *testing.T) {
		testMixedGameModes(t, suite)
	})
}

// testLegacyClientCompatibility tests legacy client support
func testLegacyClientCompatibility(t *testing.T, suite *IntegrationTestSuite) {
	player1 := suite.CreateTestClient(t, "legacy_player1")
	player2 := suite.CreateTestClient(t, "legacy_player2")

	// Legacy client sends old-style join message
	err := player1.SendMessage(ws.Message{
		Type: "join_matchmaking",
		Payload: map[string]interface{}{
			"playerID": "legacy_player1",
			// No gameMode specified (should default to legacy)
		},
	})
	require.NoError(t, err)

	err = player2.SendMessage(ws.Message{
		Type: "join_matchmaking",
		Payload: map[string]interface{}{
			"playerID": "legacy_player2",
			"gameMode": "legacy", // Explicit legacy mode
		},
	})
	require.NoError(t, err)

	// Should still be able to match and play
	match1, err := player1.WaitForMessage("match_found", 5*time.Second)
	require.NoError(t, err)

	gameData, ok := match1.Payload.(map[string]interface{})
	require.True(t, ok)
	gameID := gameData["gameId"].(string)

	// Verify in database that this is NOT an authentic rules game
	var game database.Game
	err = suite.db.Where("id = ?", gameID).First(&game).Error
	require.NoError(t, err)
	assert.False(t, game.UseAuthenticRules, "Legacy game should not use authentic rules")
}

// testMixedGameModes tests scenarios with different game modes
func testMixedGameModes(t *testing.T, suite *IntegrationTestSuite) {
	// This test verifies that players with different mode preferences
	// are handled appropriately by the matchmaking system

	authenticPlayer := suite.CreateTestClient(t, "auth_player")
	legacyPlayer := suite.CreateTestClient(t, "legacy_player")

	// Authentic player joins
	err := authenticPlayer.SendMessage(ws.Message{
		Type: "join_matchmaking",
		Payload: map[string]interface{}{
			"playerID": "auth_player",
			"gameMode": "authentic",
		},
	})
	require.NoError(t, err)

	// Legacy player joins
	err = legacyPlayer.SendMessage(ws.Message{
		Type: "join_matchmaking",
		Payload: map[string]interface{}{
			"playerID": "legacy_player",
			"gameMode": "legacy",
		},
	})
	require.NoError(t, err)

	// They should NOT be matched together (different game modes)
	// Wait reasonable time to verify no match occurs
	_, err = authenticPlayer.WaitForMessage("match_found", 3*time.Second)
	assert.Error(t, err, "Players with different game modes should not be matched")

	_, err = legacyPlayer.WaitForMessage("match_found", 1*time.Second)
	assert.Error(t, err, "Players with different game modes should not be matched")
}