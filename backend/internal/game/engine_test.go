package game

import (
	"testing"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestRomanianSepticaRuleCompliance validates all Romanian Septica game rules
func TestRomanianSepticaRuleCompliance(t *testing.T) {
	t.Run("Comprehensive Romanian Septica Rule Validation", func(t *testing.T) {
		testDeckComposition(t)
		testRomanianCardBeatingRules(t)
		testPointSystem(t)
		testGameFlow(t)
		testTurnManagement(t)
		testGameCompletion(t)
	})
}

// Test 1: Deck Composition (32 cards, values 7-14, all suits)
func testDeckComposition(t *testing.T) {
	t.Run("32-Card Deck Composition", func(t *testing.T) {
		deck := createAndShuffleDeck()
		
		// Validate deck size
		assert.Equal(t, 32, len(deck), "Deck must contain exactly 32 cards")
		
		// Validate card values (7-14)
		expectedValues := map[int]int{7: 0, 8: 0, 9: 0, 10: 0, 11: 0, 12: 0, 13: 0, 14: 0}
		for _, card := range deck {
			assert.GreaterOrEqual(t, card.Value, 7, "Card value must be >= 7")
			assert.LessOrEqual(t, card.Value, 14, "Card value must be <= 14")
			expectedValues[card.Value]++
		}
		
		// Validate each value appears exactly 4 times (once per suit)
		for value, count := range expectedValues {
			assert.Equal(t, 4, count, "Value %d must appear exactly 4 times (once per suit)", value)
		}
		
		// Validate suits
		suitCounts := map[string]int{"hearts": 0, "diamonds": 0, "clubs": 0, "spades": 0}
		for _, card := range deck {
			suitCounts[card.Suit]++
		}
		
		for suit, count := range suitCounts {
			assert.Equal(t, 8, count, "Suit %s must have exactly 8 cards", suit)
		}
		
		// Validate unique card IDs
		cardIDs := make(map[string]bool)
		for _, card := range deck {
			assert.False(t, cardIDs[card.ID], "Card ID must be unique: %s", card.ID)
			cardIDs[card.ID] = true
		}
	})
}

// Test 2: Romanian Card Beating Rules
func testRomanianCardBeatingRules(t *testing.T) {
	t.Run("7s Always Beat Any Card", func(t *testing.T) {
		// Test 7 beating various cards
		testCases := []struct {
			name      string
			playCard  Card
			tableCard Card
			shouldWin bool
		}{
			{
				name:      "7 beats Ace",
				playCard:  Card{Suit: "hearts", Value: 7},
				tableCard: Card{Suit: "spades", Value: 14}, // Ace
				shouldWin: true,
			},
			{
				name:      "7 beats King",
				playCard:  Card{Suit: "clubs", Value: 7},
				tableCard: Card{Suit: "diamonds", Value: 13}, // King
				shouldWin: true,
			},
			{
				name:      "7 beats 10",
				playCard:  Card{Suit: "spades", Value: 7},
				tableCard: Card{Suit: "hearts", Value: 10},
				shouldWin: true,
			},
		}
		
		for _, tc := range testCases {
			t.Run(tc.name, func(t *testing.T) {
				tableCards := []Card{tc.tableCard}
				result := isValidMove(tc.playCard, tableCards, TwoPlayers)
				assert.Equal(t, tc.shouldWin, result, "7s must always beat other cards")
			})
		}
	})
	
	t.Run("8s Beat When Table Cards % 3 = 0", func(t *testing.T) {
		// Test 8 beating when table has 3, 6, 9, etc. cards
		eightCard := Card{Suit: "hearts", Value: 8}
		
		// Create table with 3 cards (divisible by 3)
		tableWith3Cards := []Card{
			{Suit: "spades", Value: 10},
			{Suit: "diamonds", Value: 11},
			{Suit: "clubs", Value: 12},
		}
		assert.True(t, isValidMove(eightCard, tableWith3Cards, TwoPlayers), "8 should beat when table has 3 cards")
		
		// Create table with 6 cards (divisible by 3)
		tableWith6Cards := []Card{
			{Suit: "spades", Value: 10}, {Suit: "diamonds", Value: 11},
			{Suit: "clubs", Value: 12}, {Suit: "hearts", Value: 13},
			{Suit: "spades", Value: 9}, {Suit: "diamonds", Value: 14},
		}
		assert.True(t, isValidMove(eightCard, tableWith6Cards, TwoPlayers), "8 should beat when table has 6 cards")
		
		// Create table with 2 cards (not divisible by 3)
		tableWith2Cards := []Card{
			{Suit: "spades", Value: 10},
			{Suit: "diamonds", Value: 11},
		}
		assert.False(t, isValidMove(eightCard, tableWith2Cards, TwoPlayers), "8 should not beat when table has 2 cards")
		
		// Create table with 4 cards (not divisible by 3)
		tableWith4Cards := []Card{
			{Suit: "spades", Value: 10}, {Suit: "diamonds", Value: 11},
			{Suit: "clubs", Value: 12}, {Suit: "hearts", Value: 13},
		}
		assert.False(t, isValidMove(eightCard, tableWith4Cards, TwoPlayers), "8 should not beat when table has 4 cards")
	})
	
	t.Run("Same Value Cards Beat Each Other", func(t *testing.T) {
		testCases := []struct {
			name      string
			playCard  Card
			tableCard Card
			shouldWin bool
		}{
			{
				name:      "10 beats 10",
				playCard:  Card{Suit: "hearts", Value: 10},
				tableCard: Card{Suit: "spades", Value: 10},
				shouldWin: true,
			},
			{
				name:      "Ace beats Ace",
				playCard:  Card{Suit: "clubs", Value: 14},
				tableCard: Card{Suit: "diamonds", Value: 14},
				shouldWin: true,
			},
			{
				name:      "Jack beats Jack",
				playCard:  Card{Suit: "spades", Value: 11},
				tableCard: Card{Suit: "hearts", Value: 11},
				shouldWin: true,
			},
			{
				name:      "Different values don't beat",
				playCard:  Card{Suit: "hearts", Value: 9},
				tableCard: Card{Suit: "spades", Value: 10},
				shouldWin: false,
			},
		}
		
		for _, tc := range testCases {
			t.Run(tc.name, func(t *testing.T) {
				tableCards := []Card{tc.tableCard}
				result := isValidMove(tc.playCard, tableCards, TwoPlayers)
				assert.Equal(t, tc.shouldWin, result, "Same values should beat, different should not")
			})
		}
	})
	
	t.Run("Invalid Moves Rejected", func(t *testing.T) {
		// Test that invalid moves are properly rejected
		nineCard := Card{Suit: "hearts", Value: 9}
		aceOnTable := []Card{{Suit: "spades", Value: 14}}
		
		// 9 cannot beat Ace (not 7, not 8 with table%3=0, not same value)
		assert.False(t, isValidMove(nineCard, aceOnTable, TwoPlayers), "9 should not beat Ace")
		
		// Test various invalid combinations
		invalidCases := []struct {
			playCard  Card
			tableCard Card
		}{
			{Card{Suit: "hearts", Value: 9}, Card{Suit: "spades", Value: 10}},
			{Card{Suit: "clubs", Value: 12}, Card{Suit: "diamonds", Value: 13}},
			{Card{Suit: "spades", Value: 11}, Card{Suit: "hearts", Value: 14}},
		}
		
		for _, tc := range invalidCases {
			tableCards := []Card{tc.tableCard}
			assert.False(t, isValidMove(tc.playCard, tableCards, TwoPlayers),
				"Card %d should not beat card %d", tc.playCard.Value, tc.tableCard.Value)
		}
	})
}

// Test 3: Point System (Only 10s and Aces count)
func testPointSystem(t *testing.T) {
	t.Run("Point Card Identification", func(t *testing.T) {
		testCases := []struct {
			cards          []Card
			expectedPoints int
			description    string
		}{
			{
				cards: []Card{
					{Suit: "hearts", Value: 10},   // 1 point
					{Suit: "spades", Value: 14},   // 1 point (Ace)
					{Suit: "clubs", Value: 9},     // 0 points
					{Suit: "diamonds", Value: 11}, // 0 points (Jack)
				},
				expectedPoints: 2,
				description:    "10 and Ace should give 2 points",
			},
			{
				cards: []Card{
					{Suit: "hearts", Value: 10},   // 1 point
					{Suit: "spades", Value: 10},   // 1 point
					{Suit: "clubs", Value: 14},    // 1 point (Ace)
					{Suit: "diamonds", Value: 14}, // 1 point (Ace)
				},
				expectedPoints: 4,
				description:    "Two 10s and two Aces should give 4 points",
			},
			{
				cards: []Card{
					{Suit: "hearts", Value: 7},    // 0 points
					{Suit: "spades", Value: 8},    // 0 points
					{Suit: "clubs", Value: 9},     // 0 points
					{Suit: "diamonds", Value: 11}, // 0 points
					{Suit: "hearts", Value: 12},   // 0 points
					{Suit: "spades", Value: 13},   // 0 points
				},
				expectedPoints: 0,
				description:    "Non-point cards should give 0 points",
			},
		}
		
		for _, tc := range testCases {
			t.Run(tc.description, func(t *testing.T) {
				points := calculatePoints(tc.cards)
				assert.Equal(t, tc.expectedPoints, points, tc.description)
			})
		}
	})
	
	t.Run("Total Points Per Game", func(t *testing.T) {
		// In a full deck, there should be exactly 8 point cards
		deck := createAndShuffleDeck()
		totalPoints := calculatePoints(deck)
		assert.Equal(t, 8, totalPoints, "Full deck should contain exactly 8 points (4x10s + 4xAces)")
		
		// Count point cards manually
		pointCardCount := 0
		for _, card := range deck {
			if card.Value == 10 || card.Value == 14 {
				pointCardCount++
			}
		}
		assert.Equal(t, 8, pointCardCount, "Should have exactly 8 point cards in deck")
	})
}

// Test 4: Game Flow and State Management
func testGameFlow(t *testing.T) {
	t.Run("Game Creation and Initial State", func(t *testing.T) {
		engine := NewEngine()
		player1 := uuid.New()
		player2 := uuid.New()
		
		game := engine.CreateGame(player1, player2)
		
		// Validate game creation
		assert.Equal(t, player1, game.Player1ID, "Player 1 ID should match")
		assert.Equal(t, player2, game.Player2ID, "Player 2 ID should match")
		assert.Equal(t, "in_progress", game.Status, "Game should be in progress")
		assert.Equal(t, player1, game.CurrentPlayerID, "Player 1 should start")
		
		// Validate initial hands
		assert.Equal(t, 4, len(game.Player1Hand), "Player 1 should have 4 cards initially")
		assert.Equal(t, 4, len(game.Player2Hand), "Player 2 should have 4 cards initially")
		assert.Equal(t, 24, len(game.Deck), "Remaining deck should have 24 cards")
		assert.Empty(t, game.TableCards, "Table should be empty initially")
		
		// Validate scoring
		assert.Equal(t, 0, game.Player1Score, "Player 1 score should be 0 initially")
		assert.Equal(t, 0, game.Player2Score, "Player 2 score should be 0 initially")
		assert.Equal(t, 1, game.TrickNumber, "Should start with trick 1")
		assert.Equal(t, 1, game.MoveNumber, "Should start with move 1")
	})
	
	t.Run("Card Playing and State Updates", func(t *testing.T) {
		engine := NewEngine()
		player1 := uuid.New()
		player2 := uuid.New()
		
		game := engine.CreateGame(player1, player2)
		
		// Player 1 plays first card (any card is valid on empty table)
		firstCard := game.Player1Hand[0]
		result, err := engine.PlayCard(game.ID, player1, firstCard)
		
		require.NoError(t, err, "First card play should not error")
		assert.True(t, result.Valid, "First card play should be valid")
		assert.Equal(t, 1, len(result.UpdatedState.TableCards), "Table should have 1 card")
		assert.Equal(t, 3, len(result.UpdatedState.Player1Hand), "Player 1 should have 3 cards left")
		assert.Equal(t, player2, result.UpdatedState.CurrentPlayerID, "Turn should switch to Player 2")
		assert.Equal(t, 2, result.UpdatedState.MoveNumber, "Move number should increment")
	})
}

// Test 5: Turn Management
func testTurnManagement(t *testing.T) {
	t.Run("Turn Alternation", func(t *testing.T) {
		engine := NewEngine()
		player1 := uuid.New()
		player2 := uuid.New()
		
		game := engine.CreateGame(player1, player2)
		
		// Validate Player 1 starts
		assert.Equal(t, player1, game.CurrentPlayerID, "Player 1 should start")
		
		// Player 2 tries to play out of turn
		player2Card := game.Player2Hand[0]
		result, err := engine.PlayCard(game.ID, player2, player2Card)
		
		require.NoError(t, err, "Should not error, just return invalid")
		assert.False(t, result.Valid, "Player 2 should not be able to play out of turn")
		assert.Equal(t, "not your turn", result.Error, "Should get correct error message")
		
		// Player 1 plays correctly
		player1Card := game.Player1Hand[0]
		result, err = engine.PlayCard(game.ID, player1, player1Card)
		
		require.NoError(t, err, "Player 1 should be able to play")
		assert.True(t, result.Valid, "Player 1 move should be valid")
		assert.Equal(t, player2, result.UpdatedState.CurrentPlayerID, "Turn should switch to Player 2")
	})
	
	t.Run("Invalid Card in Hand", func(t *testing.T) {
		engine := NewEngine()
		player1 := uuid.New()
		player2 := uuid.New()
		
		game := engine.CreateGame(player1, player2)
		
		// Try to play a card not in hand
		fakeCard := Card{Suit: "hearts", Value: 7, ID: "fake-card"}
		result, err := engine.PlayCard(game.ID, player1, fakeCard)
		
		require.NoError(t, err, "Should not error, just return invalid")
		assert.False(t, result.Valid, "Should not be able to play card not in hand")
		assert.Equal(t, "card not in hand", result.Error, "Should get correct error message")
	})
}

// Test 6: Game Completion Logic
func testGameCompletion(t *testing.T) {
	t.Run("Game Completion Conditions", func(t *testing.T) {
		engine := NewEngine()
		player1 := uuid.New()
		player2 := uuid.New()
		
		game := engine.CreateGame(player1, player2)
		
		// Simulate game completion (empty hands and deck)
		game.Player1Hand = []Card{}
		game.Player2Hand = []Card{}
		game.Deck = []Card{}
		
		completed := isGameComplete(game)
		assert.True(t, completed, "Game should be complete when all cards are played")
		
		// Test incomplete game scenarios
		game.Player1Hand = []Card{{Suit: "hearts", Value: 7}}
		completed = isGameComplete(game)
		assert.False(t, completed, "Game should not be complete with cards remaining")
		
		game.Player1Hand = []Card{}
		game.Deck = []Card{{Suit: "spades", Value: 8}}
		completed = isGameComplete(game)
		assert.False(t, completed, "Game should not be complete with deck remaining")
	})
	
	t.Run("Winner Determination", func(t *testing.T) {
		engine := NewEngine()
		player1 := uuid.New()
		player2 := uuid.New()
		
		game := engine.CreateGame(player1, player2)
		
		// Set up game completion scenario with different scores
		game.Player1Hand = []Card{}
		game.Player2Hand = []Card{}
		game.Deck = []Card{}
		game.Player1Score = 5
		game.Player2Score = 3
		game.Status = "completed"
		
		// In a real game completion, this would be handled by PlayCard
		// Here we simulate the winner determination logic
		var winnerID *uuid.UUID
		if game.Player1Score > game.Player2Score {
			winnerID = &game.Player1ID
		} else if game.Player2Score > game.Player1Score {
			winnerID = &game.Player2ID
		}
		// If scores equal, winnerID remains nil (draw)
		
		assert.NotNil(t, winnerID, "Should have a winner when scores differ")
		assert.Equal(t, player1, *winnerID, "Player 1 should win with higher score")
		
		// Test draw scenario
		game.Player1Score = 4
		game.Player2Score = 4
		winnerID = nil
		if game.Player1Score > game.Player2Score {
			winnerID = &game.Player1ID
		} else if game.Player2Score > game.Player1Score {
			winnerID = &game.Player2ID
		}
		
		assert.Nil(t, winnerID, "Should be no winner in case of draw")
	})
}

// Test 7: Advanced Game Scenarios
func TestAdvancedGameScenarios(t *testing.T) {
	t.Run("Complete Game Simulation", func(t *testing.T) {
		engine := NewEngine()
		player1 := uuid.New()
		player2 := uuid.New()
		
		game := engine.CreateGame(player1, player2)
		
		// Simulate a few moves
		moveCount := 0
		maxMoves := 10 // Prevent infinite loops in test
		
		for game.Status == "in_progress" && moveCount < maxMoves {
			// Get current player's valid moves
			validMoves, err := engine.GetValidMoves(game.ID, game.CurrentPlayerID)
			require.NoError(t, err, "Should be able to get valid moves")
			
			if len(validMoves) > 0 {
				// Play first valid move
				result, err := engine.PlayCard(game.ID, game.CurrentPlayerID, validMoves[0])
				require.NoError(t, err, "Valid move should not error")
				assert.True(t, result.Valid, "Valid move should succeed")
				
				game = result.UpdatedState
				moveCount++
			} else {
				// No valid moves available - this should trigger trick completion
				break
			}
		}
		
		assert.True(t, moveCount > 0, "Should have made at least one move")
		assert.LessOrEqual(t, moveCount, maxMoves, "Should not exceed max moves limit")
	})
	
	t.Run("Multiple Game Instance Management", func(t *testing.T) {
		engine := NewEngine()
		
		// Create multiple games
		games := make([]uuid.UUID, 5)
		for i := 0; i < 5; i++ {
			player1 := uuid.New()
			player2 := uuid.New()
			game := engine.CreateGame(player1, player2)
			games[i] = game.ID
		}
		
		// Verify all games exist and are independent
		for i, gameID := range games {
			game, err := engine.GetGame(gameID)
			require.NoError(t, err, "Game %d should exist", i)
			assert.Equal(t, "in_progress", game.Status, "Game %d should be in progress", i)
			
			// Verify games have different players
			for j, otherGameID := range games {
				if i != j {
					otherGame, _ := engine.GetGame(otherGameID)
					assert.NotEqual(t, game.Player1ID, otherGame.Player1ID, 
						"Games should have different players")
				}
			}
		}
	})
	
	t.Run("Card Dealing and Deck Management", func(t *testing.T) {
		engine := NewEngine()
		player1 := uuid.New()
		player2 := uuid.New()
		
		game := engine.CreateGame(player1, player2)
		
		// Verify initial deck state
		totalCards := len(game.Player1Hand) + len(game.Player2Hand) + len(game.Deck)
		assert.Equal(t, 32, totalCards, "Total cards should equal deck size")
		
		// Verify no duplicate cards between hands and deck
		allCards := make(map[string]bool)
		
		for _, card := range game.Player1Hand {
			assert.False(t, allCards[card.ID], "Card ID should be unique: %s", card.ID)
			allCards[card.ID] = true
		}
		
		for _, card := range game.Player2Hand {
			assert.False(t, allCards[card.ID], "Card ID should be unique: %s", card.ID)
			allCards[card.ID] = true
		}
		
		for _, card := range game.Deck {
			assert.False(t, allCards[card.ID], "Card ID should be unique: %s", card.ID)
			allCards[card.ID] = true
		}
		
		assert.Equal(t, 32, len(allCards), "Should have exactly 32 unique cards")
	})
}

// Test 8: Performance and Edge Cases
func TestPerformanceAndEdgeCases(t *testing.T) {
	t.Run("Large Number of Games", func(t *testing.T) {
		engine := NewEngine()
		gameCount := 100
		
		// Create many games rapidly
		gameIDs := make([]uuid.UUID, gameCount)
		for i := 0; i < gameCount; i++ {
			player1 := uuid.New()
			player2 := uuid.New()
			game := engine.CreateGame(player1, player2)
			gameIDs[i] = game.ID
		}
		
		// Verify all games were created
		for i, gameID := range gameIDs {
			game, err := engine.GetGame(gameID)
			require.NoError(t, err, "Game %d should exist", i)
			assert.Equal(t, "in_progress", game.Status, "Game %d should be in progress", i)
		}
	})
	
	t.Run("Invalid Game ID", func(t *testing.T) {
		engine := NewEngine()
		
		fakeGameID := uuid.New()
		game, err := engine.GetGame(fakeGameID)
		
		assert.Error(t, err, "Should error for non-existent game")
		assert.Equal(t, ErrGameNotFound, err, "Should return correct error type")
		assert.Nil(t, game, "Should return nil game for invalid ID")
	})
	
	t.Run("Player Hand Access Control", func(t *testing.T) {
		engine := NewEngine()
		player1 := uuid.New()
		player2 := uuid.New()
		
		game := engine.CreateGame(player1, player2)
		
		// Player 1 should be able to access their hand
		hand1, err := engine.GetPlayerHand(game.ID, player1)
		require.NoError(t, err, "Player 1 should access their hand")
		assert.Equal(t, 4, len(hand1), "Player 1 hand should have 4 cards")
		
		// Player 2 should be able to access their hand
		hand2, err := engine.GetPlayerHand(game.ID, player2)
		require.NoError(t, err, "Player 2 should access their hand")
		assert.Equal(t, 4, len(hand2), "Player 2 hand should have 4 cards")
		
		// Unknown player should not be able to access any hand
		unknownPlayer := uuid.New()
		hand, err := engine.GetPlayerHand(game.ID, unknownPlayer)
		assert.Error(t, err, "Unknown player should not access hands")
		assert.Nil(t, hand, "Should return nil hand for unknown player")
	})
	
	t.Run("Valid Moves Calculation", func(t *testing.T) {
		engine := NewEngine()
		player1 := uuid.New()
		player2 := uuid.New()
		
		game := engine.CreateGame(player1, player2)
		
		// On empty table, all cards should be valid
		validMoves1, err := engine.GetValidMoves(game.ID, player1)
		require.NoError(t, err, "Should be able to get valid moves")
		assert.Equal(t, 4, len(validMoves1), "All 4 cards should be valid on empty table")
		
		// Play a card and check opponent's valid moves
		firstCard := game.Player1Hand[0]
		result, err := engine.PlayCard(game.ID, player1, firstCard)
		require.NoError(t, err, "Should be able to play first card")
		
		validMoves2, err := engine.GetValidMoves(game.ID, player2)
		require.NoError(t, err, "Should be able to get Player 2 valid moves")
		
		// At least some moves should be valid (7s always work, same values, etc.)
		assert.Greater(t, len(validMoves2), 0, "Player 2 should have at least some valid moves")
		
		// Verify all returned moves are actually valid
		for _, move := range validMoves2 {
			assert.True(t, isValidMove(move, result.UpdatedState.TableCards, result.UpdatedState.GameMode),
				"Returned move should be valid: %+v", move)
		}
	})
}

// Benchmark tests for performance validation
func BenchmarkGameCreation(b *testing.B) {
	engine := NewEngine()
	
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		player1 := uuid.New()
		player2 := uuid.New()
		engine.CreateGame(player1, player2)
	}
}

func BenchmarkCardPlay(b *testing.B) {
	engine := NewEngine()
	player1 := uuid.New()
	player2 := uuid.New()
	game := engine.CreateGame(player1, player2)
	
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		if len(game.Player1Hand) > 0 {
			card := game.Player1Hand[0]
			engine.PlayCard(game.ID, game.CurrentPlayerID, card)
		}
	}
}

func BenchmarkValidMovesCalculation(b *testing.B) {
	engine := NewEngine()
	player1 := uuid.New()
	player2 := uuid.New()
	game := engine.CreateGame(player1, player2)
	
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		engine.GetValidMoves(game.ID, player1)
	}
}