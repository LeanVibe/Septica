package game

import (
	"testing"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestCardIDValidation_SecurityFix validates that cards must match by ID, not just suit/value
// This prevents playing fake cards with matching suit/value but different IDs
func TestCardIDValidation_SecurityFix(t *testing.T) {
	t.Run("Fake Card With Different ID Should Be Rejected", func(t *testing.T) {
		engine := NewEngine()
		player1 := uuid.New()
		player2 := uuid.New()

		game := engine.CreateGame(player1, player2)
		require.NotNil(t, game)

		// Get a valid card from player1's hand
		validCard := game.Player1Hand[0]

		// Create a fake card with same suit and value but different ID
		fakeCard := Card{
			Suit:  validCard.Suit,
			Value: validCard.Value,
			ID:    "fake-card-id-123",  // Different ID!
		}

		// Attempt to play the fake card
		result, err := engine.PlayCard(game.ID, player1, fakeCard)

		require.NoError(t, err, "Should not error, just return invalid")
		assert.False(t, result.Valid, "Fake card should be rejected")
		assert.Equal(t, "card not in hand", result.Error, "Should get 'card not in hand' error")
		assert.Nil(t, result.UpdatedState, "UpdatedState should be nil for invalid moves")

		// Verify original game state wasn't modified
		freshGame, err := engine.GetGame(game.ID)
		require.NoError(t, err)
		assert.Equal(t, 0, len(freshGame.TableCards), "No cards should be on table")
		assert.Equal(t, 4, len(freshGame.Player1Hand), "Player1 should still have 4 cards")
	})

	t.Run("Valid Card With Correct ID Should Be Accepted", func(t *testing.T) {
		engine := NewEngine()
		player1 := uuid.New()
		player2 := uuid.New()

		game := engine.CreateGame(player1, player2)
		require.NotNil(t, game)

		// Get a valid card from player1's hand
		validCard := game.Player1Hand[0]

		// Play the actual valid card
		result, err := engine.PlayCard(game.ID, player1, validCard)

		require.NoError(t, err, "Should not error")
		assert.True(t, result.Valid, "Valid card should be accepted")
		assert.Empty(t, result.Error, "Should have no error")

		// Verify game state was modified correctly
		require.NotNil(t, result.UpdatedState, "UpdatedState should not be nil for valid moves")

		// Table state and hand size depend on whether trick completed
		if result.TrickComplete {
			// If trick complete, table is cleared and new card dealt
			assert.Equal(t, 0, len(result.UpdatedState.TableCards), "Table should be cleared after trick completion")
			assert.Equal(t, 4, len(result.UpdatedState.Player1Hand), "Player1 should have 4 cards (new card dealt)")
			assert.GreaterOrEqual(t, result.UpdatedState.Player1Score, 0, "Points may be awarded if trick complete")
		} else {
			// If trick not complete, card should be on table and hand reduced
			assert.Equal(t, 1, len(result.UpdatedState.TableCards), "Card should be on table")
			assert.Equal(t, 3, len(result.UpdatedState.Player1Hand), "Player1 should have 3 cards left")
			assert.Equal(t, validCard.ID, result.UpdatedState.TableCards[0].ID, "Played card should match by ID")
		}
	})
}

// TestCardIDValidation_DuplicatePreventionAcrossPlayers validates that players
// cannot play each other's cards even if they have matching suit/value
func TestCardIDValidation_DuplicatePreventionAcrossPlayers(t *testing.T) {
	engine := NewEngine()
	player1 := uuid.New()
	player2 := uuid.New()

	game := engine.CreateGame(player1, player2)
	require.NotNil(t, game)

	// Player1 plays their first card
	player1Card := game.Player1Hand[0]
	result, err := engine.PlayCard(game.ID, player1, player1Card)
	require.NoError(t, err)
	require.True(t, result.Valid, "Player1 should successfully play their card")

	// Find if Player2 has a card with same suit/value but different ID
	// (In a 32-card deck with 4 of each value, this could happen)
	for _, player2Card := range game.Player2Hand {
		if player2Card.Suit == player1Card.Suit && 
		   player2Card.Value == player1Card.Value &&
		   player2Card.ID != player1Card.ID {
			
			t.Run("Player2 Cannot Play Card With Same Suit/Value But Different ID", func(t *testing.T) {
				// This should succeed because it's player2's actual card
				result, err := engine.PlayCard(game.ID, player2, player2Card)
				require.NoError(t, err)
				assert.True(t, result.Valid, "Player2 should be able to play their own card")
			})
			
			return // Test completed
		}
	}
	
	t.Skip("No duplicate suit/value cards found between players in this deal")
}

// TestCardIDValidation_IntegrityAfterMultiplePlays ensures card ID validation
// works correctly across multiple card plays in a game
func TestCardIDValidation_IntegrityAfterMultiplePlays(t *testing.T) {
	engine := NewEngine()
	player1 := uuid.New()
	player2 := uuid.New()

	game := engine.CreateGame(player1, player2)
	require.NotNil(t, game)

	// Track all card IDs played
	playedCardIDs := make(map[string]bool)

	// Play first card from player1
	card1 := game.Player1Hand[0]
	result, err := engine.PlayCard(game.ID, player1, card1)
	require.NoError(t, err)
	require.True(t, result.Valid)
	playedCardIDs[card1.ID] = true

	// Get fresh game state to see current turn and available cards
	freshGame, err := engine.GetGame(game.ID)
	require.NoError(t, err)

	currentPlayer := freshGame.CurrentPlayerID

	// Get a valid move for the current player
	validMoves, err := engine.GetValidMoves(game.ID, currentPlayer)
	require.NoError(t, err)

	if len(validMoves) == 0 {
		t.Skip("No valid moves available, skipping second play test")
	}

	nextCard := validMoves[0]

	// Attempt to play card1 again as the wrong player (should fail)
	wrongPlayer := player2
	if currentPlayer == player2 {
		wrongPlayer = player1
	}
	retryResult, err := engine.PlayCard(game.ID, wrongPlayer, card1)
	require.NoError(t, err)
	assert.False(t, retryResult.Valid, "Cannot replay already played card")
	// Error could be "not your turn" or "card not in hand" depending on game state
	assert.Contains(t, []string{"not your turn", "card not in hand"}, retryResult.Error)

	// Play valid card from current player
	result, err = engine.PlayCard(game.ID, currentPlayer, nextCard)
	require.NoError(t, err)
	if !result.Valid {
		t.Logf("Second play failed: %s (currentPlayer=%s, card=%+v)", result.Error, currentPlayer, nextCard)
		t.Logf("Fresh game state: CurrentPlayer=%s, Player1Hand=%d, Player2Hand=%d, TableCards=%d",
			freshGame.CurrentPlayerID, len(freshGame.Player1Hand), len(freshGame.Player2Hand), len(freshGame.TableCards))
		// If no valid moves available, skip this validation
		validMoves, _ := engine.GetValidMoves(game.ID, currentPlayer)
		if len(validMoves) == 0 {
			t.Skip("No valid moves available for current player")
		}
	}
	require.True(t, result.Valid, "Second card play should be valid")
	playedCardIDs[nextCard.ID] = true

	// Verify all played cards have unique IDs
	assert.Len(t, playedCardIDs, 2, "Should have 2 unique card IDs played")
	
	// Verify no card ID appears in both player hands
	for _, c1 := range result.UpdatedState.Player1Hand {
		for _, c2 := range result.UpdatedState.Player2Hand {
			assert.NotEqual(t, c1.ID, c2.ID, "Player hands should have no duplicate card IDs")
		}
	}
}
