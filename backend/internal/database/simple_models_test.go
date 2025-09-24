package database

import (
	"testing"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

// Simplified test models for SQLite compatibility
type SimpleGame struct {
	ID                uuid.UUID  `gorm:"type:text;primary_key" json:"id"`
	Player1ID         uuid.UUID  `gorm:"type:text;not null" json:"player1_id"`
	Player2ID         uuid.UUID  `gorm:"type:text;not null" json:"player2_id"`
	Player3ID         *uuid.UUID `gorm:"type:text" json:"player3_id,omitempty"`
	Player4ID         *uuid.UUID `gorm:"type:text" json:"player4_id,omitempty"`
	Status            string     `gorm:"default:'waiting'" json:"status"`
	WinnerID          *uuid.UUID `gorm:"type:text" json:"winner_id"`
	WinningTeam       *string    `json:"winning_team,omitempty"`
	Player1Score      int        `gorm:"default:0" json:"player1_score"`
	Player2Score      int        `gorm:"default:0" json:"player2_score"`
	Player3Score      *int       `json:"player3_score,omitempty"`
	Player4Score      *int       `json:"player4_score,omitempty"`
	Team1Score        *int       `json:"team1_score,omitempty"`
	Team2Score        *int       `json:"team2_score,omitempty"`
	GameMode          string     `gorm:"default:'ranked'" json:"game_mode"`
	AuthenticMode     string     `json:"authentic_mode,omitempty"`
	UseAuthenticRules bool       `gorm:"default:false" json:"use_authentic_rules"`
}

type SimpleGameMove struct {
	ID                uuid.UUID  `gorm:"type:text;primary_key" json:"id"`
	GameID            uuid.UUID  `gorm:"type:text;not null" json:"game_id"`
	PlayerID          uuid.UUID  `gorm:"type:text;not null" json:"player_id"`
	MoveNumber        int        `gorm:"not null" json:"move_number"`
	CardSuit          string     `json:"card_suit,omitempty"`
	CardValue         int        `json:"card_value,omitempty"`
	TableCardCount    int        `gorm:"not null" json:"table_card_count"`
	TrickNumber       int        `gorm:"not null" json:"trick_number"`
	MoveType          string     `gorm:"default:'PLAY_CARD'" json:"move_type"`
	IsObjection       bool       `gorm:"default:false" json:"is_objection"`
	ObjectedCardSuit  *string    `json:"objected_card_suit,omitempty"`
	ObjectedCardValue *int       `json:"objected_card_value,omitempty"`
	RoundComplete     bool       `gorm:"default:false" json:"round_complete"`
	PointsAwarded     int        `gorm:"default:0" json:"points_awarded"`
	TimeTakenMs       int64      `gorm:"default:0" json:"time_taken_ms"`
}

func setupSimpleTestDatabase(t *testing.T) *gorm.DB {
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	require.NoError(t, err)

	err = db.AutoMigrate(&SimpleGame{}, &SimpleGameMove{})
	require.NoError(t, err)

	return db
}

// TestDatabase_MultiPlayerGameCreation tests multi-player game creation
func TestDatabase_MultiPlayerGameCreation(t *testing.T) {
	db := setupSimpleTestDatabase(t)

	tests := []struct {
		name           string
		playerCount    int
		gameMode       string
		authenticMode  string
		expectTeamMode bool
	}{
		{
			name:           "2-player traditional",
			playerCount:    2,
			gameMode:       "ranked",
			authenticMode:  "2_player",
			expectTeamMode: false,
		},
		{
			name:           "3-player with wild 8s",
			playerCount:    3,
			gameMode:       "casual",
			authenticMode:  "3_player",
			expectTeamMode: false,
		},
		{
			name:           "4-player team mode",
			playerCount:    4,
			gameMode:       "ranked",
			authenticMode:  "4_player",
			expectTeamMode: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Generate player IDs
			playerIDs := make([]uuid.UUID, tt.playerCount)
			for i := 0; i < tt.playerCount; i++ {
				playerIDs[i] = uuid.New()
			}

			// Create game
			game := SimpleGame{
				ID:                uuid.New(),
				Player1ID:         playerIDs[0],
				Player2ID:         playerIDs[1],
				GameMode:          tt.gameMode,
				AuthenticMode:     tt.authenticMode,
				UseAuthenticRules: true,
				Status:            "waiting",
			}

			// Set additional players for multi-player games
			if tt.playerCount >= 3 {
				game.Player3ID = &playerIDs[2]
				player3Score := 0
				game.Player3Score = &player3Score
			}

			if tt.playerCount >= 4 {
				game.Player4ID = &playerIDs[3]
				player4Score := 0
				game.Player4Score = &player4Score

				// For 4-player mode, initialize team scores
				if tt.expectTeamMode {
					team1Score := 0
					team2Score := 0
					game.Team1Score = &team1Score
					game.Team2Score = &team2Score
				}
			}

			// Save to database
			result := db.Create(&game)
			require.NoError(t, result.Error)

			// Verify game creation
			var savedGame SimpleGame
			err := db.First(&savedGame, game.ID).Error
			require.NoError(t, err)

			// Assertions
			assert.Equal(t, playerIDs[0], savedGame.Player1ID)
			assert.Equal(t, playerIDs[1], savedGame.Player2ID)
			assert.Equal(t, tt.gameMode, savedGame.GameMode)
			assert.Equal(t, tt.authenticMode, savedGame.AuthenticMode)
			assert.True(t, savedGame.UseAuthenticRules)

			// Verify multi-player fields
			if tt.playerCount >= 3 {
				require.NotNil(t, savedGame.Player3ID)
				assert.Equal(t, playerIDs[2], *savedGame.Player3ID)
				assert.NotNil(t, savedGame.Player3Score)
				assert.Equal(t, 0, *savedGame.Player3Score)
			} else {
				assert.Nil(t, savedGame.Player3ID)
				assert.Nil(t, savedGame.Player3Score)
			}

			if tt.playerCount >= 4 {
				require.NotNil(t, savedGame.Player4ID)
				assert.Equal(t, playerIDs[3], *savedGame.Player4ID)
				assert.NotNil(t, savedGame.Player4Score)
				assert.Equal(t, 0, *savedGame.Player4Score)

				if tt.expectTeamMode {
					require.NotNil(t, savedGame.Team1Score)
					require.NotNil(t, savedGame.Team2Score)
					assert.Equal(t, 0, *savedGame.Team1Score)
					assert.Equal(t, 0, *savedGame.Team2Score)
				}
			} else {
				assert.Nil(t, savedGame.Player4ID)
				assert.Nil(t, savedGame.Player4Score)
				assert.Nil(t, savedGame.Team1Score)
				assert.Nil(t, savedGame.Team2Score)
			}
		})
	}
}

// TestDatabase_AuthenticSepticaMoveStorage tests authentic game move storage
func TestDatabase_AuthenticSepticaMoveStorage(t *testing.T) {
	db := setupSimpleTestDatabase(t)

	// Create test game
	gameID := uuid.New()
	playerID := uuid.New()
	game := SimpleGame{
		ID:                gameID,
		Player1ID:         playerID,
		Player2ID:         uuid.New(),
		GameMode:          "ranked",
		AuthenticMode:     "2_player",
		UseAuthenticRules: true,
		Status:            "in_progress",
	}
	db.Create(&game)

	tests := []struct {
		name                string
		moveType            string
		isObjection         bool
		cardSuit            *string
		cardValue           *int
		objectedCardSuit    *string
		objectedCardValue   *int
		roundComplete       bool
		pointsAwarded       int
		expectValidStorage  bool
	}{
		{
			name:               "Regular card play",
			moveType:           "PLAY_CARD",
			isObjection:        false,
			cardSuit:           simpleStringPtr("hearts"),
			cardValue:          simpleIntPtr(10),
			objectedCardSuit:   nil,
			objectedCardValue:  nil,
			roundComplete:      false,
			pointsAwarded:      0,
			expectValidStorage: true,
		},
		{
			name:               "Pass move",
			moveType:           "PASS",
			isObjection:        false,
			cardSuit:           nil,
			cardValue:          nil,
			objectedCardSuit:   nil,
			objectedCardValue:  nil,
			roundComplete:      true,
			pointsAwarded:      1,
			expectValidStorage: true,
		},
		{
			name:               "Objection with 7 (wild card)",
			moveType:           "PLAY_CARD",
			isObjection:        true,
			cardSuit:           simpleStringPtr("spades"),
			cardValue:          simpleIntPtr(7),
			objectedCardSuit:   simpleStringPtr("hearts"),
			objectedCardValue:  simpleIntPtr(10),
			roundComplete:      true,
			pointsAwarded:      1,
			expectValidStorage: true,
		},
		{
			name:               "Objection with same rank",
			moveType:           "PLAY_CARD",
			isObjection:        true,
			cardSuit:           simpleStringPtr("diamonds"),
			cardValue:          simpleIntPtr(13),
			objectedCardSuit:   simpleStringPtr("clubs"),
			objectedCardValue:  simpleIntPtr(13),
			roundComplete:      true,
			pointsAwarded:      0,
			expectValidStorage: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			move := SimpleGameMove{
				ID:                uuid.New(),
				GameID:            gameID,
				PlayerID:          playerID,
				MoveNumber:        1,
				TrickNumber:       1,
				TableCardCount:    1,
				MoveType:          tt.moveType,
				IsObjection:       tt.isObjection,
				ObjectedCardSuit:  tt.objectedCardSuit,
				ObjectedCardValue: tt.objectedCardValue,
				RoundComplete:     tt.roundComplete,
				PointsAwarded:     tt.pointsAwarded,
				TimeTakenMs:       2500,
			}

			// Set card information if provided
			if tt.cardSuit != nil {
				move.CardSuit = *tt.cardSuit
			}
			if tt.cardValue != nil {
				move.CardValue = *tt.cardValue
			}

			// Save move to database
			result := db.Create(&move)

			if tt.expectValidStorage {
				require.NoError(t, result.Error)

				// Verify move storage
				var savedMove SimpleGameMove
				err := db.First(&savedMove, move.ID).Error
				require.NoError(t, err)

				// Assertions
				assert.Equal(t, gameID, savedMove.GameID)
				assert.Equal(t, playerID, savedMove.PlayerID)
				assert.Equal(t, tt.moveType, savedMove.MoveType)
				assert.Equal(t, tt.isObjection, savedMove.IsObjection)
				assert.Equal(t, tt.roundComplete, savedMove.RoundComplete)
				assert.Equal(t, tt.pointsAwarded, savedMove.PointsAwarded)

				// Verify objection details
				if tt.objectedCardSuit != nil {
					require.NotNil(t, savedMove.ObjectedCardSuit)
					assert.Equal(t, *tt.objectedCardSuit, *savedMove.ObjectedCardSuit)
				}
				if tt.objectedCardValue != nil {
					require.NotNil(t, savedMove.ObjectedCardValue)
					assert.Equal(t, *tt.objectedCardValue, *savedMove.ObjectedCardValue)
				}

				// Verify card details
				if tt.cardSuit != nil {
					assert.Equal(t, *tt.cardSuit, savedMove.CardSuit)
				}
				if tt.cardValue != nil {
					assert.Equal(t, *tt.cardValue, savedMove.CardValue)
				}

				assert.Equal(t, int64(2500), savedMove.TimeTakenMs)
			} else {
				assert.Error(t, result.Error)
			}
		})
	}
}

// TestDatabase_TeamScoreTracking tests team score tracking for 4-player games
func TestDatabase_TeamScoreTracking(t *testing.T) {
	db := setupSimpleTestDatabase(t)

	// Create 4 player UUIDs
	player1ID := uuid.New()
	player2ID := uuid.New()
	player3ID := uuid.New()
	player4ID := uuid.New()

	// Create 4-player team game
	team1Score := 0
	team2Score := 0
	game := SimpleGame{
		ID:                uuid.New(),
		Player1ID:         player1ID, // Team 1
		Player2ID:         player2ID, // Team 2
		Player3ID:         &player3ID, // Team 1
		Player4ID:         &player4ID, // Team 2
		GameMode:          "ranked",
		AuthenticMode:     "4_player",
		UseAuthenticRules: true,
		Status:            "in_progress",
		Team1Score:        &team1Score,
		Team2Score:        &team2Score,
	}

	result := db.Create(&game)
	require.NoError(t, result.Error)

	// Simulate team scoring
	// Team 1 (Player 1 + Player 3) scores 3 points
	// Team 2 (Player 2 + Player 4) scores 2 points
	game.Player1Score = 2  // Player 1 individual score
	player3Score := 1
	game.Player3Score = &player3Score // Player 3 individual score
	game.Player2Score = 1  // Player 2 individual score
	player4Score := 1
	game.Player4Score = &player4Score // Player 4 individual score
	team1Final := 3
	game.Team1Score = &team1Final // Team 1 total
	team2Final := 2
	game.Team2Score = &team2Final // Team 2 total
	game.Status = "completed"
	winningTeam := "team1"
	game.WinningTeam = &winningTeam

	result = db.Save(&game)
	require.NoError(t, result.Error)

	// Verify team score tracking
	var savedGame SimpleGame
	err := db.First(&savedGame, game.ID).Error
	require.NoError(t, err)

	assert.Equal(t, 2, savedGame.Player1Score)
	assert.Equal(t, 1, savedGame.Player2Score)
	require.NotNil(t, savedGame.Player3Score)
	assert.Equal(t, 1, *savedGame.Player3Score)
	require.NotNil(t, savedGame.Player4Score)
	assert.Equal(t, 1, *savedGame.Player4Score)

	require.NotNil(t, savedGame.Team1Score)
	require.NotNil(t, savedGame.Team2Score)
	assert.Equal(t, 3, *savedGame.Team1Score)
	assert.Equal(t, 2, *savedGame.Team2Score)

	require.NotNil(t, savedGame.WinningTeam)
	assert.Equal(t, "team1", *savedGame.WinningTeam)
}

// TestDatabase_BackwardCompatibility tests backward compatibility with legacy 2-player games
func TestDatabase_BackwardCompatibility(t *testing.T) {
	db := setupSimpleTestDatabase(t)

	tests := []struct {
		name              string
		useAuthenticRules bool
		authenticMode     string
		expectCompatible  bool
	}{
		{
			name:              "Legacy 2-player game",
			useAuthenticRules: false,
			authenticMode:     "",
			expectCompatible:  true,
		},
		{
			name:              "Modern authentic 2-player game",
			useAuthenticRules: true,
			authenticMode:     "2_player",
			expectCompatible:  true,
		},
		{
			name:              "Mixed mode - authentic rules without mode",
			useAuthenticRules: true,
			authenticMode:     "",
			expectCompatible:  true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			game := SimpleGame{
				ID:                uuid.New(),
				Player1ID:         uuid.New(),
				Player2ID:         uuid.New(),
				GameMode:          "casual",
				UseAuthenticRules: tt.useAuthenticRules,
				Status:            "waiting",
			}

			if tt.authenticMode != "" {
				game.AuthenticMode = tt.authenticMode
			}

			result := db.Create(&game)

			if tt.expectCompatible {
				require.NoError(t, result.Error)

				// Verify game was created successfully
				var savedGame SimpleGame
				err := db.First(&savedGame, game.ID).Error
				require.NoError(t, err)

				assert.Equal(t, tt.useAuthenticRules, savedGame.UseAuthenticRules)
				if tt.authenticMode != "" {
					assert.Equal(t, tt.authenticMode, savedGame.AuthenticMode)
				}

				// Legacy games should still work
				assert.Equal(t, game.Player1ID, savedGame.Player1ID)
				assert.Equal(t, game.Player2ID, savedGame.Player2ID)
			} else {
				assert.Error(t, result.Error)
			}
		})
	}
}

// TestDatabase_PassMoveHandling tests pass move handling in the database
func TestDatabase_PassMoveHandling(t *testing.T) {
	db := setupSimpleTestDatabase(t)

	// Create test game
	gameID := uuid.New()
	playerID := uuid.New()
	game := SimpleGame{
		ID:                gameID,
		Player1ID:         playerID,
		Player2ID:         uuid.New(),
		UseAuthenticRules: true,
		AuthenticMode:     "2_player",
		Status:            "in_progress",
	}
	db.Create(&game)

	// Test pass move with no card information
	passMove := SimpleGameMove{
		ID:             uuid.New(),
		GameID:         gameID,
		PlayerID:       playerID,
		MoveNumber:     2,
		TrickNumber:    1,
		TableCardCount: 1,
		MoveType:       "PASS",
		IsObjection:    false,
		RoundComplete:  true,
		PointsAwarded:  1, // Points go to original player
		TimeTakenMs:    1500,
	}

	result := db.Create(&passMove)
	require.NoError(t, result.Error)

	// Verify pass move storage
	var savedMove SimpleGameMove
	err := db.First(&savedMove, passMove.ID).Error
	require.NoError(t, err)

	assert.Equal(t, "PASS", savedMove.MoveType)
	assert.Empty(t, savedMove.CardSuit) // No card played
	assert.Equal(t, 0, savedMove.CardValue) // No card played
	assert.False(t, savedMove.IsObjection)
	assert.True(t, savedMove.RoundComplete)
	assert.Equal(t, 1, savedMove.PointsAwarded)
	assert.Nil(t, savedMove.ObjectedCardSuit)
	assert.Nil(t, savedMove.ObjectedCardValue)
}

// TestSimpleDatabase_SchemaConsistency tests database schema consistency with simplified models
func TestSimpleDatabase_SchemaConsistency(t *testing.T) {
	db := setupSimpleTestDatabase(t)

	// Test nullable fields
	t.Run("Nullable fields handling", func(t *testing.T) {
		// Create minimal 2-player game
		game := SimpleGame{
			ID:        uuid.New(),
			Player1ID: uuid.New(),
			Player2ID: uuid.New(),
		}
		result := db.Create(&game)
		require.NoError(t, result.Error)

		// Verify nullable fields are properly handled
		var savedGame SimpleGame
		err := db.First(&savedGame, game.ID).Error
		require.NoError(t, err)

		assert.Nil(t, savedGame.Player3ID)
		assert.Nil(t, savedGame.Player4ID)
		assert.Nil(t, savedGame.Player3Score)
		assert.Nil(t, savedGame.Player4Score)
		assert.Nil(t, savedGame.Team1Score)
		assert.Nil(t, savedGame.Team2Score)
		assert.Nil(t, savedGame.WinningTeam)
	})

	// Test UUID generation
	t.Run("UUID handling", func(t *testing.T) {
		gameID := uuid.New()
		game := SimpleGame{
			ID:        gameID,
			Player1ID: uuid.New(),
			Player2ID: uuid.New(),
		}
		result := db.Create(&game)
		require.NoError(t, result.Error)

		// Verify UUID was stored correctly
		assert.NotEqual(t, uuid.Nil, game.ID)
		assert.NotEmpty(t, game.ID.String())
		assert.Equal(t, gameID, game.ID)
	})
}

// Helper functions for simple models
func simpleStringPtr(s string) *string {
	return &s
}

func simpleIntPtr(i int) *int {
	return &i
}