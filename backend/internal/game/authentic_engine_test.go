package game

import (
	"testing"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestAuthenticEngine_CreateGame tests game creation for different modes
func TestAuthenticEngine_CreateGame(t *testing.T) {
	tests := []struct {
		name        string
		playerCount int
		gameMode    AuthenticGameMode
		expectError bool
		expectedErr string
	}{
		{
			name:        "Valid 2-player game",
			playerCount: 2,
			gameMode:    ModeTwoPlayer,
			expectError: false,
		},
		{
			name:        "Valid 3-player game",
			playerCount: 3,
			gameMode:    ModeThreePlayer,
			expectError: false,
		},
		{
			name:        "Valid 4-player game",
			playerCount: 4,
			gameMode:    ModeFourPlayer,
			expectError: false,
		},
		{
			name:        "Invalid player count - too few",
			playerCount: 1,
			gameMode:    ModeTwoPlayer,
			expectError: true,
			expectedErr: "invalid number of players",
		},
		{
			name:        "Invalid player count - too many",
			playerCount: 5,
			gameMode:    ModeFourPlayer,
			expectError: true,
			expectedErr: "invalid number of players",
		},
		{
			name:        "Mismatched mode and player count",
			playerCount: 3,
			gameMode:    ModeTwoPlayer,
			expectError: true,
			expectedErr: "2-player mode requires exactly 2 players",
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

			if tt.expectError {
				assert.Error(t, err)
				assert.Contains(t, err.Error(), tt.expectedErr)
				assert.Nil(t, game)
			} else {
				assert.NoError(t, err)
				require.NotNil(t, game)
				assert.Equal(t, len(playerIDs), len(game.Players))
				assert.Equal(t, "playing", game.Status)
				assert.Equal(t, tt.gameMode, game.GameMode)

				// Verify each player has 4 cards
				for _, playerID := range playerIDs {
					hand, exists := game.PlayerHands[playerID]
					assert.True(t, exists)
					assert.Len(t, hand, 4)
				}

				// Verify team setup for 4-player mode
				if tt.gameMode == ModeFourPlayer {
					assert.Len(t, game.Teams, 2)
					assert.Len(t, game.Teams[0], 2) // Team 1
					assert.Len(t, game.Teams[1], 2) // Team 2
					assert.NotNil(t, game.TeamScores)
					assert.Equal(t, 0, game.TeamScores["team1"])
					assert.Equal(t, 0, game.TeamScores["team2"])
				}

				// Verify wild 8s for 3-player mode
				if tt.gameMode == ModeThreePlayer {
					assert.True(t, game.WildEights)
					// Verify deck has 30 cards (32 - 2 eights removed)
					totalCards := len(game.Deck)
					for _, hand := range game.PlayerHands {
						totalCards += len(hand)
					}
					assert.Equal(t, 30, totalCards)
				} else {
					assert.False(t, game.WildEights)
					// Verify deck has 32 cards
					totalCards := len(game.Deck)
					for _, hand := range game.PlayerHands {
						totalCards += len(hand)
					}
					assert.Equal(t, 32, totalCards)
				}
			}
		})
	}
}

// TestAuthenticEngine_ObjectionRules tests the core objection mechanics
func TestAuthenticEngine_ObjectionRules(t *testing.T) {
	tests := []struct {
		name           string
		playedCard     Card
		objectionCard  Card
		gameMode       AuthenticGameMode
		canObject      bool
	}{
		{
			name:          "7 can always object (wild card)",
			playedCard:    Card{Suit: "hearts", Value: 10},
			objectionCard: Card{Suit: "spades", Value: 7},
			gameMode:      ModeTwoPlayer,
			canObject:     true,
		},
		{
			name:          "Same rank can object",
			playedCard:    Card{Suit: "hearts", Value: 10},
			objectionCard: Card{Suit: "diamonds", Value: 10},
			gameMode:      ModeTwoPlayer,
			canObject:     true,
		},
		{
			name:          "8 can object in 3-player mode (wild)",
			playedCard:    Card{Suit: "hearts", Value: 13},
			objectionCard: Card{Suit: "clubs", Value: 8},
			gameMode:      ModeThreePlayer,
			canObject:     true,
		},
		{
			name:          "8 cannot object in 2-player mode (not wild)",
			playedCard:    Card{Suit: "hearts", Value: 13},
			objectionCard: Card{Suit: "clubs", Value: 8},
			gameMode:      ModeTwoPlayer,
			canObject:     false,
		},
		{
			name:          "Different non-wild ranks cannot object",
			playedCard:    Card{Suit: "hearts", Value: 13},
			objectionCard: Card{Suit: "clubs", Value: 9},
			gameMode:      ModeTwoPlayer,
			canObject:     false,
		},
		{
			name:          "Ace can object to Ace",
			playedCard:    Card{Suit: "hearts", Value: 14},
			objectionCard: Card{Suit: "spades", Value: 14},
			gameMode:      ModeFourPlayer,
			canObject:     true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			engine := NewAuthenticEngine()
			result := engine.CanObjectToCard(tt.playedCard, tt.objectionCard, tt.gameMode)
			assert.Equal(t, tt.canObject, result)
		})
	}
}

// TestAuthenticEngine_GameFlow tests the complete game flow
func TestAuthenticEngine_GameFlow(t *testing.T) {
	engine := NewAuthenticEngine()

	// Create a 2-player game
	player1ID := uuid.New()
	player2ID := uuid.New()
	playerIDs := []uuid.UUID{player1ID, player2ID}

	game, err := engine.CreateGame(playerIDs, ModeTwoPlayer)
	require.NoError(t, err)
	require.NotNil(t, game)

	// Test initial state
	assert.Equal(t, "playing", game.Status)
	assert.Equal(t, player1ID, game.CurrentPlayerID)
	assert.False(t, game.WaitingForObjection)
	assert.Empty(t, game.TableCards)

	// Player 1 plays a card
	player1Hand := game.PlayerHands[player1ID]
	require.NotEmpty(t, player1Hand)
	cardToPlay := player1Hand[0]

	action := AuthenticPlayerAction{
		Type:     "PLAY_CARD",
		PlayerID: player1ID,
		Card:     &cardToPlay,
	}

	result, err := engine.ProcessAction(game.ID, action)
	require.NoError(t, err)
	assert.True(t, result.Valid)
	assert.False(t, result.RoundComplete)
	assert.True(t, result.ObjectionPhase)
	assert.Equal(t, player2ID, result.NextPlayerID)

	// Verify objection phase state
	updatedGame := result.UpdatedState
	assert.True(t, updatedGame.WaitingForObjection)
	assert.NotNil(t, updatedGame.LastPlayedCard)
	assert.Equal(t, cardToPlay.Suit, updatedGame.LastPlayedCard.Suit)
	assert.Equal(t, cardToPlay.Value, updatedGame.LastPlayedCard.Value)
	assert.Equal(t, player1ID, updatedGame.LastPlayerID)
	assert.Len(t, updatedGame.TableCards, 1)

	// Player 2 passes (doesn't object)
	passAction := AuthenticPlayerAction{
		Type:     "PASS",
		PlayerID: player2ID,
		Card:     nil,
	}

	result2, err := engine.ProcessAction(game.ID, passAction)
	require.NoError(t, err)
	assert.True(t, result2.Valid)
	assert.True(t, result2.RoundComplete)
	assert.False(t, result2.ObjectionPhase)
	assert.Equal(t, player1ID, result2.NextPlayerID) // Winner starts next round

	// Verify round completion
	finalGame := result2.UpdatedState
	assert.False(t, finalGame.WaitingForObjection)
	assert.Nil(t, finalGame.LastPlayedCard)
	assert.Empty(t, finalGame.TableCards) // Cards collected
	assert.Equal(t, player1ID, finalGame.CurrentPlayerID) // Winner's turn
}

// TestAuthenticEngine_ObjectionFlow tests objection scenarios
func TestAuthenticEngine_ObjectionFlow(t *testing.T) {
	engine := NewAuthenticEngine()

	// Create a 2-player game
	player1ID := uuid.New()
	player2ID := uuid.New()
	playerIDs := []uuid.UUID{player1ID, player2ID}

	game, err := engine.CreateGame(playerIDs, ModeTwoPlayer)
	require.NoError(t, err)

	// Force specific cards for testing
	game.PlayerHands[player1ID] = []Card{
		{Suit: "hearts", Value: 10, ID: "test1"},
		{Suit: "diamonds", Value: 9, ID: "test2"},
		{Suit: "clubs", Value: 8, ID: "test3"},
		{Suit: "spades", Value: 11, ID: "test4"},
	}
	game.PlayerHands[player2ID] = []Card{
		{Suit: "hearts", Value: 7, ID: "test5"}, // Wild card
		{Suit: "spades", Value: 10, ID: "test6"}, // Same rank
		{Suit: "clubs", Value: 9, ID: "test7"},
		{Suit: "diamonds", Value: 12, ID: "test8"},
	}

	// Player 1 plays 10 of hearts (point card)
	action := AuthenticPlayerAction{
		Type:     "PLAY_CARD",
		PlayerID: player1ID,
		Card:     &Card{Suit: "hearts", Value: 10, ID: "test1"},
	}

	result, err := engine.ProcessAction(game.ID, action)
	require.NoError(t, err)
	assert.True(t, result.ObjectionPhase)

	// Player 2 objects with 7 (wild card)
	objectionAction := AuthenticPlayerAction{
		Type:     "PLAY_CARD",
		PlayerID: player2ID,
		Card:     &Card{Suit: "hearts", Value: 7, ID: "test5"},
	}

	result2, err := engine.ProcessAction(game.ID, objectionAction)
	require.NoError(t, err)
	assert.True(t, result2.Valid)
	assert.True(t, result2.RoundComplete)
	assert.Equal(t, 1, result2.PointsAwarded) // 10 is worth 1 point
	assert.Equal(t, player2ID, *result2.CollectorPlayerID) // Objector wins

	// Verify player 2 got the point
	finalGame := result2.UpdatedState
	assert.Equal(t, 1, finalGame.PlayerScores[player2ID])
	assert.Equal(t, 0, finalGame.PlayerScores[player1ID])
	assert.Equal(t, player2ID, finalGame.CurrentPlayerID) // Winner starts next round
}

// TestAuthenticEngine_InvalidActions tests invalid action handling
func TestAuthenticEngine_InvalidActions(t *testing.T) {
	engine := NewAuthenticEngine()

	// Create a 2-player game
	player1ID := uuid.New()
	player2ID := uuid.New()
	playerIDs := []uuid.UUID{player1ID, player2ID}

	game, err := engine.CreateGame(playerIDs, ModeTwoPlayer)
	require.NoError(t, err)

	tests := []struct {
		name           string
		action         AuthenticPlayerAction
		expectedError  string
	}{
		{
			name: "Wrong player's turn",
			action: AuthenticPlayerAction{
				Type:     "PLAY_CARD",
				PlayerID: player2ID,
				Card:     &Card{Suit: "hearts", Value: 10},
			},
			expectedError: "not your turn",
		},
		{
			name: "Card not in hand",
			action: AuthenticPlayerAction{
				Type:     "PLAY_CARD",
				PlayerID: player1ID,
				Card:     &Card{Suit: "hearts", Value: 99}, // Invalid card
			},
			expectedError: "card not in hand",
		},
		{
			name: "Pass when not in objection phase",
			action: AuthenticPlayerAction{
				Type:     "PASS",
				PlayerID: player1ID,
			},
			expectedError: "not in objection phase",
		},
		{
			name: "Play card without card data",
			action: AuthenticPlayerAction{
				Type:     "PLAY_CARD",
				PlayerID: player1ID,
				Card:     nil,
			},
			expectedError: "card required for PLAY_CARD action",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result, err := engine.ProcessAction(game.ID, tt.action)
			require.NoError(t, err) // Process should not return error
			assert.False(t, result.Valid)
			assert.Contains(t, result.Error, tt.expectedError)
		})
	}
}

// TestAuthenticEngine_ThreePlayerWild8s tests 3-player wild 8s
func TestAuthenticEngine_ThreePlayerWild8s(t *testing.T) {
	engine := NewAuthenticEngine()

	// Create a 3-player game
	player1ID := uuid.New()
	player2ID := uuid.New()
	player3ID := uuid.New()
	playerIDs := []uuid.UUID{player1ID, player2ID, player3ID}

	game, err := engine.CreateGame(playerIDs, ModeThreePlayer)
	require.NoError(t, err)
	assert.True(t, game.WildEights)

	// Test that 8s can object in 3-player mode
	playedCard := Card{Suit: "hearts", Value: 13}
	objectionCard := Card{Suit: "clubs", Value: 8}

	canObject := engine.CanObjectToCard(playedCard, objectionCard, ModeThreePlayer)
	assert.True(t, canObject, "8 should be wild in 3-player mode")

	// Verify same card cannot object in 2-player mode
	canObjectTwoPlayer := engine.CanObjectToCard(playedCard, objectionCard, ModeTwoPlayer)
	assert.False(t, canObjectTwoPlayer, "8 should not be wild in 2-player mode")
}

// TestAuthenticEngine_FourPlayerTeams tests 4-player team mechanics
func TestAuthenticEngine_FourPlayerTeams(t *testing.T) {
	engine := NewAuthenticEngine()

	// Create a 4-player team game
	player1ID := uuid.New()
	player2ID := uuid.New()
	player3ID := uuid.New()
	player4ID := uuid.New()
	playerIDs := []uuid.UUID{player1ID, player2ID, player3ID, player4ID}

	game, err := engine.CreateGame(playerIDs, ModeFourPlayer)
	require.NoError(t, err)

	// Verify team setup
	require.Len(t, game.Teams, 2)
	assert.Contains(t, game.Teams[0], player1ID)
	assert.Contains(t, game.Teams[0], player3ID) // Team 1: Player 1 + 3
	assert.Contains(t, game.Teams[1], player2ID)
	assert.Contains(t, game.Teams[1], player4ID) // Team 2: Player 2 + 4

	assert.NotNil(t, game.TeamScores)
	assert.Equal(t, 0, game.TeamScores["team1"])
	assert.Equal(t, 0, game.TeamScores["team2"])

	// Test team score allocation
	// Force a point card for testing
	game.PlayerHands[player1ID][0] = Card{Suit: "hearts", Value: 14, ID: "ace"} // Ace = point

	// Player 1 plays ace
	action := AuthenticPlayerAction{
		Type:     "PLAY_CARD",
		PlayerID: player1ID,
		Card:     &Card{Suit: "hearts", Value: 14, ID: "ace"},
	}

	result, err := engine.ProcessAction(game.ID, action)
	require.NoError(t, err)
	assert.True(t, result.ObjectionPhase)

	// Player 2 passes - Player 1 gets the point for Team 1
	passAction := AuthenticPlayerAction{
		Type:     "PASS",
		PlayerID: player2ID,
	}

	result2, err := engine.ProcessAction(game.ID, passAction)
	require.NoError(t, err)
	assert.True(t, result2.RoundComplete)
	assert.Equal(t, 1, result2.PointsAwarded)

	// Verify team score updated
	finalGame := result2.UpdatedState
	assert.Equal(t, 1, finalGame.TeamScores["team1"]) // Player 1's team got the point
	assert.Equal(t, 0, finalGame.TeamScores["team2"])
}

// TestAuthenticEngine_PointCalculation tests point card calculation
func TestAuthenticEngine_PointCalculation(t *testing.T) {
	tableCards := []Card{
		{Suit: "hearts", Value: 10},  // 1 point
		{Suit: "diamonds", Value: 14}, // 1 point (Ace)
		{Suit: "clubs", Value: 9},    // 0 points
		{Suit: "spades", Value: 7},   // 0 points
	}

	points := calculateAuthenticPoints(tableCards)
	assert.Equal(t, 2, points)

	// Test edge case - no point cards
	nonPointCards := []Card{
		{Suit: "hearts", Value: 7},
		{Suit: "diamonds", Value: 8},
		{Suit: "clubs", Value: 9},
	}

	noPoints := calculateAuthenticPoints(nonPointCards)
	assert.Equal(t, 0, noPoints)

	// Test all point cards
	allPointCards := []Card{
		{Suit: "hearts", Value: 10},
		{Suit: "diamonds", Value: 10},
		{Suit: "clubs", Value: 10},
		{Suit: "spades", Value: 10},
		{Suit: "hearts", Value: 14},
		{Suit: "diamonds", Value: 14},
		{Suit: "clubs", Value: 14},
		{Suit: "spades", Value: 14},
	}

	maxPoints := calculateAuthenticPoints(allPointCards)
	assert.Equal(t, 8, maxPoints) // Maximum possible points in Romanian Septica
}

// TestAuthenticEngine_GetValidMoves tests valid move calculation
func TestAuthenticEngine_GetValidMoves(t *testing.T) {
	engine := NewAuthenticEngine()

	// Create a 2-player game
	player1ID := uuid.New()
	player2ID := uuid.New()
	playerIDs := []uuid.UUID{player1ID, player2ID}

	game, err := engine.CreateGame(playerIDs, ModeTwoPlayer)
	require.NoError(t, err)

	// Test initial state - player 1's turn, any card valid
	validMoves, err := engine.GetValidMoves(game.ID, player1ID)
	require.NoError(t, err)
	assert.Equal(t, len(game.PlayerHands[player1ID]), len(validMoves))

	// Test not your turn
	validMovesWrongPlayer, err := engine.GetValidMoves(game.ID, player2ID)
	require.NoError(t, err)
	assert.Empty(t, validMovesWrongPlayer)

	// Set up objection phase
	game.WaitingForObjection = true
	game.CurrentPlayerID = player2ID
	game.LastPlayedCard = &Card{Suit: "hearts", Value: 10}

	// Force specific hand for testing objection rules
	game.PlayerHands[player2ID] = []Card{
		{Suit: "spades", Value: 7},   // Can object (wild)
		{Suit: "diamonds", Value: 10}, // Can object (same rank)
		{Suit: "clubs", Value: 9},    // Cannot object
		{Suit: "hearts", Value: 8},   // Cannot object (not wild in 2-player)
	}

	validObjections, err := engine.GetValidMoves(game.ID, player2ID)
	require.NoError(t, err)
	assert.Len(t, validObjections, 2) // Only 7 and 10 can object

	// Verify correct cards can object
	canObjectWith7 := false
	canObjectWith10 := false
	for _, card := range validObjections {
		if card.Value == 7 {
			canObjectWith7 = true
		}
		if card.Value == 10 {
			canObjectWith10 = true
		}
	}
	assert.True(t, canObjectWith7)
	assert.True(t, canObjectWith10)
}