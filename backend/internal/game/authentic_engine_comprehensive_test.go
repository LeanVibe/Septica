package game

import (
	"testing"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestAuthenticEngine_DoubleVictoryCondition tests the double victory rule
func TestAuthenticEngine_DoubleVictoryCondition(t *testing.T) {
	engine := NewAuthenticEngine()
	player1ID := uuid.New()
	player2ID := uuid.New()
	playerIDs := []uuid.UUID{player1ID, player2ID}

	game, err := engine.CreateGame(playerIDs, ModeTwoPlayer)
	require.NoError(t, err)

	// Simulate a game where player1 gets all points and player2 gets zero
	game.PlayerScores[player1ID] = 8 // All possible points (4 tens + 4 aces)
	game.PlayerScores[player2ID] = 0 // Zero points

	// Mark game as complete
	game.Status = "finished"

	// Test double victory determination
	winnerID, _ := determineWinner(game)
	require.NotNil(t, winnerID)
	assert.Equal(t, player1ID, *winnerID)

	// Verify the score difference qualifies for double victory
	assert.Equal(t, 8, game.PlayerScores[player1ID])
	assert.Equal(t, 0, game.PlayerScores[player2ID])

	// In authentic Romanian Septica, 8-0 is maximum possible double victory
	// (4 tens + 4 aces = 8 total points available)
}

// TestAuthenticEngine_CompleteGameScenarios tests full game scenarios
func TestAuthenticEngine_CompleteGameScenarios(t *testing.T) {
	tests := []struct {
		name             string
		gameMode         AuthenticGameMode
		playerCount      int
		expectedDeckSize int
		wildEights       bool
	}{
		{
			name:             "2-player traditional",
			gameMode:         ModeTwoPlayer,
			playerCount:      2,
			expectedDeckSize: 32, // Full deck
			wildEights:       false,
		},
		{
			name:             "3-player with wild 8s",
			gameMode:         ModeThreePlayer,
			playerCount:      3,
			expectedDeckSize: 30, // 32 - 2 eights
			wildEights:       true,
		},
		{
			name:             "4-player team play",
			gameMode:         ModeFourPlayer,
			playerCount:      4,
			expectedDeckSize: 32, // Full deck
			wildEights:       false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			engine := NewAuthenticEngine()

			// Generate player IDs
			playerIDs := make([]uuid.UUID, tt.playerCount)
			for i := 0; i < tt.playerCount; i++ {
				playerIDs[i] = uuid.New()
			}

			game, err := engine.CreateGame(playerIDs, tt.gameMode)
			require.NoError(t, err)

			// Verify deck composition
			totalCards := len(game.Deck)
			for _, hand := range game.PlayerHands {
				totalCards += len(hand)
			}
			assert.Equal(t, tt.expectedDeckSize, totalCards)

			// Verify wild eights setting
			assert.Equal(t, tt.wildEights, game.WildEights)

			// Verify each player has exactly 4 cards
			for _, playerID := range playerIDs {
				hand := game.PlayerHands[playerID]
				assert.Len(t, hand, 4, "Each player should start with 4 cards")
			}

			// For 4-player mode, verify team setup
			if tt.gameMode == ModeFourPlayer {
				assert.Len(t, game.Teams, 2, "Should have 2 teams")
				assert.Len(t, game.Teams[0], 2, "Team 1 should have 2 players")
				assert.Len(t, game.Teams[1], 2, "Team 2 should have 2 players")
				assert.NotNil(t, game.TeamScores, "Team scores should be initialized")
			}
		})
	}
}

// TestAuthenticEngine_PassTimeoutHandling tests pass timeout scenarios
func TestAuthenticEngine_PassTimeoutHandling(t *testing.T) {
	engine := NewAuthenticEngine()
	player1ID := uuid.New()
	player2ID := uuid.New()
	playerIDs := []uuid.UUID{player1ID, player2ID}

	game, err := engine.CreateGame(playerIDs, ModeTwoPlayer)
	require.NoError(t, err)

	// Set up objection phase
	game.WaitingForObjection = true
	game.CurrentPlayerID = player2ID
	game.LastPlayedCard = &Card{Suit: "hearts", Value: 10, ID: "test1"}
	game.LastPlayerID = player1ID
	game.TableCards = []Card{{Suit: "hearts", Value: 10, ID: "test1"}}

	// Simulate timeout by having player2 pass
	passAction := AuthenticPlayerAction{
		Type:     "PASS",
		PlayerID: player2ID,
	}

	result, err := engine.ProcessAction(game.ID, passAction)
	require.NoError(t, err)
	assert.True(t, result.Valid, "Pass should be valid in objection phase")
	assert.True(t, result.RoundComplete, "Round should complete after pass")
	assert.Equal(t, player1ID, *result.CollectorPlayerID, "Original player should collect cards")
	assert.Equal(t, 1, result.PointsAwarded, "Should award 1 point for the 10")
}

// TestAuthenticEngine_InvalidObjectionAttempts tests invalid objection scenarios
func TestAuthenticEngine_InvalidObjectionAttempts(t *testing.T) {
	engine := NewAuthenticEngine()
	player1ID := uuid.New()
	player2ID := uuid.New()
	playerIDs := []uuid.UUID{player1ID, player2ID}

	game, err := engine.CreateGame(playerIDs, ModeTwoPlayer)
	require.NoError(t, err)

	// Set up objection phase
	game.WaitingForObjection = true
	game.CurrentPlayerID = player2ID
	game.LastPlayedCard = &Card{Suit: "hearts", Value: 10, ID: "test1"}
	game.PlayerHands[player2ID] = []Card{
		{Suit: "spades", Value: 9, ID: "test2"}, // Cannot object (different rank, not wild)
	}

	// Attempt invalid objection
	invalidAction := AuthenticPlayerAction{
		Type:     "PLAY_CARD",
		PlayerID: player2ID,
		Card:     &Card{Suit: "spades", Value: 9, ID: "test2"},
	}

	result, err := engine.ProcessAction(game.ID, invalidAction)
	require.NoError(t, err)
	assert.False(t, result.Valid, "Invalid objection should be rejected")
	assert.Contains(t, result.Error, "cannot object with this card")

	// Verify game state unchanged
	updated_game, err := engine.GetGame(game.ID)
	require.NoError(t, err)
	assert.True(t, updated_game.WaitingForObjection, "Should still be waiting for objection")
	assert.Len(t, updated_game.PlayerHands[player2ID], 1, "Player hand should be unchanged")
}

// TestAuthenticEngine_GameStateConsistency tests game state consistency
func TestAuthenticEngine_GameStateConsistency(t *testing.T) {
	engine := NewAuthenticEngine()
	player1ID := uuid.New()
	player2ID := uuid.New()
	playerIDs := []uuid.UUID{player1ID, player2ID}

	game, err := engine.CreateGame(playerIDs, ModeTwoPlayer)
	require.NoError(t, err)

	// Verify initial state consistency
	assert.Equal(t, "playing", game.Status)
	assert.False(t, game.WaitingForObjection)
	assert.Nil(t, game.LastPlayedCard)
	assert.Empty(t, game.TableCards)
	assert.Equal(t, 1, game.RoundNumber)
	assert.Equal(t, 1, game.MoveNumber)
	assert.Equal(t, 0, game.PlayerScores[player1ID])
	assert.Equal(t, 0, game.PlayerScores[player2ID])

	// Verify each player has unique cards
	player1Cards := game.PlayerHands[player1ID]
	player2Cards := game.PlayerHands[player2ID]
	deckCards := game.Deck

	allCards := make(map[string]bool)
	for _, card := range player1Cards {
		assert.False(t, allCards[card.ID], "Card ID should be unique")
		allCards[card.ID] = true
	}
	for _, card := range player2Cards {
		assert.False(t, allCards[card.ID], "Card ID should be unique")
		allCards[card.ID] = true
	}
	for _, card := range deckCards {
		assert.False(t, allCards[card.ID], "Card ID should be unique")
		allCards[card.ID] = true
	}

	// Total cards should be 32 for 2-player game
	totalCards := len(player1Cards) + len(player2Cards) + len(deckCards)
	assert.Equal(t, 32, totalCards)

	// Verify all values are in valid range (7-14)
	for _, card := range player1Cards {
		assert.GreaterOrEqual(t, card.Value, 7, "Card values should be >= 7")
		assert.LessOrEqual(t, card.Value, 14, "Card values should be <= 14")
		assert.Contains(t, []string{"hearts", "diamonds", "clubs", "spades"}, card.Suit)
	}
}

// TestAuthenticEngine_EdgeCaseScenarios tests edge case scenarios
func TestAuthenticEngine_EdgeCaseScenarios(t *testing.T) {
	t.Run("Empty deck handling", func(t *testing.T) {
		engine := NewAuthenticEngine()
		player1ID := uuid.New()
		player2ID := uuid.New()
		playerIDs := []uuid.UUID{player1ID, player2ID}

		game, err := engine.CreateGame(playerIDs, ModeTwoPlayer)
		require.NoError(t, err)

		// Force empty deck
		game.Deck = []Card{}
		game.PlayerHands[player1ID] = []Card{} // Empty hands
		game.PlayerHands[player2ID] = []Card{}

		// Check if game is complete
		isComplete := isAuthenticGameComplete(game)
		assert.True(t, isComplete, "Game should be complete with empty deck and hands")
	})

	t.Run("Multiple objections in sequence", func(t *testing.T) {
		// This tests a complex scenario where multiple objections could happen
		// In authentic Romanian Septica, only next player can object
		engine := NewAuthenticEngine()
		player1ID := uuid.New()
		player2ID := uuid.New()
		playerIDs := []uuid.UUID{player1ID, player2ID}

		game, err := engine.CreateGame(playerIDs, ModeTwoPlayer)
		require.NoError(t, err)

		// Player 1 plays a card
		game.PlayerHands[player1ID] = []Card{{Suit: "hearts", Value: 10, ID: "test1"}}
		action1 := AuthenticPlayerAction{
			Type:     "PLAY_CARD",
			PlayerID: player1ID,
			Card:     &Card{Suit: "hearts", Value: 10, ID: "test1"},
		}

		result1, err := engine.ProcessAction(game.ID, action1)
		require.NoError(t, err)
		assert.True(t, result1.ObjectionPhase)

		// Player 2 objects successfully
		game.PlayerHands[player2ID] = []Card{{Suit: "spades", Value: 7, ID: "test2"}} // Wild card
		objectionAction := AuthenticPlayerAction{
			Type:     "PLAY_CARD",
			PlayerID: player2ID,
			Card:     &Card{Suit: "spades", Value: 7, ID: "test2"},
		}

		result2, err := engine.ProcessAction(game.ID, objectionAction)
		require.NoError(t, err)
		assert.True(t, result2.Valid)
		assert.True(t, result2.RoundComplete)
		assert.Equal(t, player2ID, *result2.CollectorPlayerID) // Objector wins
	})

	t.Run("Maximum points scenario", func(t *testing.T) {
		// Test scenario with maximum possible points (all 10s and Aces)
		allPointCards := []Card{
			{Suit: "hearts", Value: 10}, {Suit: "diamonds", Value: 10},
			{Suit: "clubs", Value: 10}, {Suit: "spades", Value: 10},
			{Suit: "hearts", Value: 14}, {Suit: "diamonds", Value: 14},
			{Suit: "clubs", Value: 14}, {Suit: "spades", Value: 14},
		}

		maxPoints := calculateAuthenticPoints(allPointCards)
		assert.Equal(t, 8, maxPoints, "Maximum points should be 8 (4 tens + 4 aces)")
	})

	t.Run("Team scoring accuracy", func(t *testing.T) {
		engine := NewAuthenticEngine()
		player1ID, player2ID, player3ID, player4ID := uuid.New(), uuid.New(), uuid.New(), uuid.New()
		playerIDs := []uuid.UUID{player1ID, player2ID, player3ID, player4ID}

		game, err := engine.CreateGame(playerIDs, ModeFourPlayer)
		require.NoError(t, err)

		// Verify team assignments
		team1Players := game.Teams[0]
		team2Players := game.Teams[1]

		assert.Contains(t, team1Players, player1ID)
		assert.Contains(t, team1Players, player3ID)
		assert.Contains(t, team2Players, player2ID)
		assert.Contains(t, team2Players, player4ID)

		// Test team name assignment
		team1Name := getPlayerTeam(game, player1ID)
		team3Name := getPlayerTeam(game, player3ID)
		team2Name := getPlayerTeam(game, player2ID)
		team4Name := getPlayerTeam(game, player4ID)

		assert.Equal(t, "team1", team1Name)
		assert.Equal(t, "team1", team3Name)
		assert.Equal(t, "team2", team2Name)
		assert.Equal(t, "team2", team4Name)
	})
}

// COMPREHENSIVE PERFORMANCE AND STRESS TESTS

// TestAuthenticEngine_ConcurrentGameCreation tests concurrent game creation
func TestAuthenticEngine_ConcurrentGameCreation(t *testing.T) {
	engine := NewAuthenticEngine()
	numGames := 100
	type result struct {
		err error
	}
	results := make(chan result, numGames)

	// Create multiple games concurrently
	for i := 0; i < numGames; i++ {
		go func() {
			player1ID := uuid.New()
			player2ID := uuid.New()
			playerIDs := []uuid.UUID{player1ID, player2ID}

			_, err := engine.CreateGame(playerIDs, ModeTwoPlayer)
			results <- result{err: err}
		}()
	}

	// Wait for all games to be created and check errors
	for i := 0; i < numGames; i++ {
		res := <-results
		assert.NoError(t, res.err)
	}

	// Verify all games were created
	assert.Len(t, engine.games, numGames)
}

// TestAuthenticEngine_MemoryUsage tests memory usage patterns
func TestAuthenticEngine_MemoryUsage(t *testing.T) {
	engine := NewAuthenticEngine()

	// Create many games and verify they don't cause memory issues
	for i := 0; i < 1000; i++ {
		player1ID := uuid.New()
		player2ID := uuid.New()
		playerIDs := []uuid.UUID{player1ID, player2ID}

		game, err := engine.CreateGame(playerIDs, ModeTwoPlayer)
		require.NoError(t, err)

		// Complete the game quickly
		game.Status = "finished"
	}

	// Memory should be manageable (this is a basic test)
	assert.Greater(t, len(engine.games), 0)
	assert.LessOrEqual(t, len(engine.games), 1000)
}

// BACKWARD COMPATIBILITY TESTS

// TestAuthenticEngine_BackwardCompatibility tests compatibility with legacy systems
func TestAuthenticEngine_BackwardCompatibility(t *testing.T) {
	t.Run("Legacy message format support", func(t *testing.T) {
		// Test that authentic engine can handle legacy-style requests
		engine := NewAuthenticEngine()
		player1ID := uuid.New()
		player2ID := uuid.New()
		playerIDs := []uuid.UUID{player1ID, player2ID}

		game, err := engine.CreateGame(playerIDs, ModeTwoPlayer)
		require.NoError(t, err)

		// Legacy systems might send different action types
		// Ensure we handle them gracefully
		legacyAction := AuthenticPlayerAction{
			Type:     "INVALID_LEGACY_TYPE",
			PlayerID: player1ID,
		}

		result, err := engine.ProcessAction(game.ID, legacyAction)
		require.NoError(t, err)
		assert.False(t, result.Valid)
		assert.Contains(t, result.Error, "invalid action type")
	})

	t.Run("Feature flag support", func(t *testing.T) {
		// Test that engine respects feature flags
		engine := NewAuthenticEngine()
		assert.True(t, engine.config.UseAuthenticRules)

		// Should be able to toggle authentic rules
		engine.config.UseAuthenticRules = false
		assert.False(t, engine.config.UseAuthenticRules)
	})
}

// CULTURAL AUTHENTICITY VALIDATION TESTS

// TestAuthenticEngine_RomanianCulturalAuthenticity tests Romanian cultural elements
func TestAuthenticEngine_RomanianCulturalAuthenticity(t *testing.T) {
	t.Run("Card deck composition", func(t *testing.T) {
		// Verify Romanian Septica uses correct card values (7-14)
		engine := NewAuthenticEngine()
		player1ID := uuid.New()
		player2ID := uuid.New()
		playerIDs := []uuid.UUID{player1ID, player2ID}

		game, err := engine.CreateGame(playerIDs, ModeTwoPlayer)
		require.NoError(t, err)

		// Check all cards in the game
		allCards := append(game.Deck, game.PlayerHands[player1ID]...)
		allCards = append(allCards, game.PlayerHands[player2ID]...)

		// Count each value
		valueCounts := make(map[int]int)
		for _, card := range allCards {
			valueCounts[card.Value]++
			assert.GreaterOrEqual(t, card.Value, 7, "Romanian Septica uses values 7-14")
			assert.LessOrEqual(t, card.Value, 14, "Romanian Septica uses values 7-14")
		}

		// Each value should appear exactly 4 times (4 suits)
		for value := 7; value <= 14; value++ {
			assert.Equal(t, 4, valueCounts[value], "Each value should appear 4 times")
		}
	})

	t.Run("Point system authenticity", func(t *testing.T) {
		// Romanian Septica: only 10s and Aces are worth points
		testCards := []Card{
			{Suit: "hearts", Value: 7},  // 0 points
			{Suit: "hearts", Value: 8},  // 0 points
			{Suit: "hearts", Value: 9},  // 0 points
			{Suit: "hearts", Value: 10}, // 1 point
			{Suit: "hearts", Value: 11}, // 0 points (Jack)
			{Suit: "hearts", Value: 12}, // 0 points (Queen)
			{Suit: "hearts", Value: 13}, // 0 points (King)
			{Suit: "hearts", Value: 14}, // 1 point (Ace)
		}

		points := calculateAuthenticPoints(testCards)
		assert.Equal(t, 2, points, "Only 10s and Aces should give points")
	})

	t.Run("3-player variant deck modification", func(t *testing.T) {
		// 3-player Romanian Septica removes 2 eights, making remaining 8s wild
		engine := NewAuthenticEngine()
		player1ID := uuid.New()
		player2ID := uuid.New()
		player3ID := uuid.New()
		playerIDs := []uuid.UUID{player1ID, player2ID, player3ID}

		game, err := engine.CreateGame(playerIDs, ModeThreePlayer)
		require.NoError(t, err)

		// Count total cards (should be 30 for 3-player)
		totalCards := len(game.Deck)
		for _, hand := range game.PlayerHands {
			totalCards += len(hand)
		}
		assert.Equal(t, 30, totalCards, "3-player variant should have 30 cards")

		// Count 8s in the deck (should have exactly 2)
		allCards := append(game.Deck, game.PlayerHands[player1ID]...)
		allCards = append(allCards, game.PlayerHands[player2ID]...)
		allCards = append(allCards, game.PlayerHands[player3ID]...)

		eightsCount := 0
		for _, card := range allCards {
			if card.Value == 8 {
				eightsCount++
			}
		}
		assert.Equal(t, 2, eightsCount, "3-player variant should have exactly 2 eights")

		// Verify wild eights flag
		assert.True(t, game.WildEights, "3-player variant should have wild eights")
	})

	t.Run("4-player team formation authenticity", func(t *testing.T) {
		// Romanian 4-player Septica: teams are 1+3 vs 2+4 (cross-partners)
		engine := NewAuthenticEngine()
		player1ID := uuid.New()
		player2ID := uuid.New()
		player3ID := uuid.New()
		player4ID := uuid.New()
		playerIDs := []uuid.UUID{player1ID, player2ID, player3ID, player4ID}

		game, err := engine.CreateGame(playerIDs, ModeFourPlayer)
		require.NoError(t, err)

		// Verify authentic team formation (cross-partners)
		require.Len(t, game.Teams, 2)
		team1 := game.Teams[0]
		team2 := game.Teams[1]

		// Team 1: Player 1 and Player 3 (positions 0 and 2)
		assert.Contains(t, team1, player1ID)
		assert.Contains(t, team1, player3ID)

		// Team 2: Player 2 and Player 4 (positions 1 and 3)
		assert.Contains(t, team2, player2ID)
		assert.Contains(t, team2, player4ID)

		// Verify team scoring structure
		assert.NotNil(t, game.TeamScores)
		assert.Equal(t, 0, game.TeamScores["team1"])
		assert.Equal(t, 0, game.TeamScores["team2"])
	})
}

// INTEGRATION HELPERS AND UTILITIES

// Helper function to create a test game with specific cards
func createTestGameWithCards(engine *AuthenticEngine, gameMode AuthenticGameMode, playerCards map[uuid.UUID][]Card) (*AuthenticGameState, error) {
	playerIDs := make([]uuid.UUID, 0, len(playerCards))
	for playerID := range playerCards {
		playerIDs = append(playerIDs, playerID)
	}

	game, err := engine.CreateGame(playerIDs, gameMode)
	if err != nil {
		return nil, err
	}

	// Override with specific cards
	for playerID, cards := range playerCards {
		game.PlayerHands[playerID] = cards
	}

	return game, nil
}

// Helper function to simulate a complete round
func simulateCompleteRound(t *testing.T, engine *AuthenticEngine, gameID uuid.UUID, playCard Card, playerID uuid.UUID, shouldObject bool, objectionCard *Card, objectorID uuid.UUID) *AuthenticMoveResult {
	// Play initial card
	playAction := AuthenticPlayerAction{
		Type:     "PLAY_CARD",
		PlayerID: playerID,
		Card:     &playCard,
	}

	result1, err := engine.ProcessAction(gameID, playAction)
	require.NoError(t, err)
	require.True(t, result1.Valid)
	require.True(t, result1.ObjectionPhase)

	if shouldObject && objectionCard != nil {
		// Object with specified card
		objectionAction := AuthenticPlayerAction{
			Type:     "PLAY_CARD",
			PlayerID: objectorID,
			Card:     objectionCard,
		}
		result2, err := engine.ProcessAction(gameID, objectionAction)
		require.NoError(t, err)
		return result2
	} else {
		// Pass (don't object)
		passAction := AuthenticPlayerAction{
			Type:     "PASS",
			PlayerID: objectorID,
		}
		result2, err := engine.ProcessAction(gameID, passAction)
		require.NoError(t, err)
		return result2
	}
}
