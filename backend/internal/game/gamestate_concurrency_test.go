package game

import (
	"sync"
	"testing"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestGameState_ConcurrentPlayCard validates that the GameState mutex
// prevents race conditions when multiple goroutines attempt to play cards
func TestGameState_ConcurrentPlayCard(t *testing.T) {
	t.Run("Concurrent PlayCard Operations Are Thread-Safe", func(t *testing.T) {
		engine := NewEngine()
		player1 := uuid.New()
		player2 := uuid.New()

		game := engine.CreateGame(player1, player2)
		require.NotNil(t, game)

		// Attempt concurrent plays (only one should succeed per turn)
		numAttempts := 10
		var wg sync.WaitGroup

		type playResult struct {
			valid bool
			err   error
		}
		results := make(chan playResult, numAttempts)

		// Get valid cards from both players
		player1Card := game.Player1Hand[0]
		player2Card := game.Player2Hand[0]

		// Launch concurrent goroutines trying to play cards
		for i := 0; i < numAttempts; i++ {
			wg.Add(1)
			go func(idx int) {
				defer wg.Done()

				// Alternate between players
				var playerID uuid.UUID
				var card Card
				if idx%2 == 0 {
					playerID = player1
					card = player1Card
				} else {
					playerID = player2
					card = player2Card
				}

				result, err := engine.PlayCard(game.ID, playerID, card)
				results <- playResult{
					valid: result != nil && result.Valid,
					err:   err,
				}
			}(i)
		}

		wg.Wait()
		close(results)

		// Collect results
		validPlays := 0
		invalidPlays := 0
		errors := 0
		for res := range results {
			if res.err != nil {
				errors++
			} else if res.valid {
				validPlays++
			} else {
				invalidPlays++
			}
		}

		// Verify results
		assert.Equal(t, 0, errors, "Should have no errors")
		assert.GreaterOrEqual(t, validPlays, 1, "At least one play should succeed")
		assert.LessOrEqual(t, validPlays, 2, "At most two plays should succeed (one per player)")
		assert.Equal(t, numAttempts, validPlays+invalidPlays, "All plays should be accounted for")

		// Verify game state integrity
		finalGame, err := engine.GetGame(game.ID)
		require.NoError(t, err)

		// Verify total cards is consistent
		totalCards := len(finalGame.Player1Hand) + len(finalGame.Player2Hand) + len(finalGame.TableCards)
		assert.LessOrEqual(t, totalCards, 8, "Total cards in play should not exceed 8 (initial 4+4)")
		assert.GreaterOrEqual(t, totalCards, 6, "Total cards should be at least 6 (accounting for plays)")
	})

	t.Run("Concurrent Plays On Different Games Are Independent", func(t *testing.T) {
		engine := NewEngine()

		// Create multiple games
		numGames := 5
		games := make([]*GameState, numGames)
		for i := 0; i < numGames; i++ {
			player1 := uuid.New()
			player2 := uuid.New()
			games[i] = engine.CreateGame(player1, player2)
		}

		// Play cards concurrently on different games
		var wg sync.WaitGroup
		type gameResult struct {
			gameIdx int
			valid   bool
			err     error
		}
		results := make(chan gameResult, numGames)

		for i, game := range games {
			wg.Add(1)
			go func(idx int, g *GameState) {
				defer wg.Done()

				// Play first card from player1's hand
				card := g.Player1Hand[0]
				result, err := engine.PlayCard(g.ID, g.Player1ID, card)

				results <- gameResult{
					gameIdx: idx,
					valid:   result != nil && result.Valid,
					err:     err,
				}
			}(i, game)
		}

		wg.Wait()
		close(results)

		// All plays should succeed (each game is independent)
		successCount := 0
		for res := range results {
			assert.NoError(t, res.err, "Game %d should not error", res.gameIdx)
			if res.valid {
				successCount++
			}
		}
		assert.Equal(t, numGames, successCount, "All %d games should have successful plays", numGames)
	})

	t.Run("Mutex Prevents Race Condition In Game State Updates", func(t *testing.T) {
		engine := NewEngine()
		player1 := uuid.New()
		player2 := uuid.New()

		game := engine.CreateGame(player1, player2)
		require.NotNil(t, game)

		// Store initial cards in local variables (thread-safe copy)
		player1Card := game.Player1Hand[0]
		player2Card := game.Player2Hand[0]
		initialTotalCards := len(game.Player1Hand) + len(game.Player2Hand) + len(game.TableCards)

		// Attempt many concurrent reads and writes
		numOperations := 100
		var wg sync.WaitGroup

		for i := 0; i < numOperations; i++ {
			wg.Add(1)
			go func(idx int) {
				defer wg.Done()

				// Mix of read and write operations
				if idx%3 == 0 {
					// Read operation
					_, _ = engine.GetGame(game.ID)
				} else {
					// Write operation (most will fail due to turn or duplicate card)
					var playerID uuid.UUID
					var card Card
					if idx%2 == 0 {
						playerID = player1
						card = player1Card
					} else {
						playerID = player2
						card = player2Card
					}

					_, _ = engine.PlayCard(game.ID, playerID, card)
				}
			}(i)
		}

		wg.Wait()

		// Verify final state is consistent (no corruption)
		finalGame, err := engine.GetGame(game.ID)
		require.NoError(t, err)

		// Game state should be consistent
		assert.Equal(t, player1, finalGame.Player1ID, "Player1 ID should be unchanged")
		assert.Equal(t, player2, finalGame.Player2ID, "Player2 ID should be unchanged")

		// Card counts should be valid (sum should equal initial or less)
		finalTotalCards := len(finalGame.Player1Hand) + len(finalGame.Player2Hand) + len(finalGame.TableCards)
		assert.LessOrEqual(t, finalTotalCards, initialTotalCards, "Total cards should not increase")

		// Status should still be valid
		assert.Contains(t, []string{"in_progress", "completed"}, finalGame.Status, "Game status should be valid")
	})
}

// TestEngine_ConcurrentGameAccess validates that the Engine's RWMutex
// prevents race conditions when accessing multiple games concurrently
func TestEngine_ConcurrentGameAccess(t *testing.T) {
	t.Run("Concurrent Game Creation Is Thread-Safe", func(t *testing.T) {
		engine := NewEngine()

		numGames := 50
		var wg sync.WaitGroup

		type result struct {
			gameID uuid.UUID
			err    error
		}
		results := make(chan result, numGames)

		for i := 0; i < numGames; i++ {
			wg.Add(1)
			go func() {
				defer wg.Done()

				player1 := uuid.New()
				player2 := uuid.New()
				game := engine.CreateGame(player1, player2)

				if game == nil {
					results <- result{err: assert.AnError}
				} else {
					results <- result{gameID: game.ID}
				}
			}()
		}

		wg.Wait()
		close(results)

		// Verify all games were created successfully
		gameIDs := make(map[uuid.UUID]bool)
		for res := range results {
			assert.NoError(t, res.err, "Game creation should not error")
			assert.NotEqual(t, uuid.Nil, res.gameID, "Game ID should not be nil")
			gameIDs[res.gameID] = true
		}

		assert.Len(t, gameIDs, numGames, "Should have %d unique games", numGames)
	})

	t.Run("Concurrent Game Reads Are Thread-Safe", func(t *testing.T) {
		engine := NewEngine()
		player1 := uuid.New()
		player2 := uuid.New()

		game := engine.CreateGame(player1, player2)
		require.NotNil(t, game)

		// Perform many concurrent reads
		numReads := 100
		var wg sync.WaitGroup
		errors := make(chan error, numReads)

		for i := 0; i < numReads; i++ {
			wg.Add(1)
			go func() {
				defer wg.Done()

				g, err := engine.GetGame(game.ID)
				if err != nil {
					errors <- err
				} else if g == nil {
					errors <- assert.AnError
				}
			}()
		}

		wg.Wait()
		close(errors)

		// All reads should succeed
		errorCount := 0
		for range errors {
			errorCount++
		}
		assert.Equal(t, 0, errorCount, "All concurrent reads should succeed")
	})
}
