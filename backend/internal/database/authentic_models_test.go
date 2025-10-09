package database

import (
	"strconv"
	"testing"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

// TestDatabase helper to create in-memory SQLite database for testing
func setupTestDatabase(t *testing.T) *gorm.DB {
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	require.NoError(t, err, "Failed to connect to test database")

	// Create simplified models for SQLite testing (UUID generation handled by GORM)
	type TestUser struct {
		ID           uuid.UUID `gorm:"type:text;primary_key" json:"id"`
		Username     string    `gorm:"uniqueIndex;not null" json:"username"`
		Email        string    `gorm:"uniqueIndex;not null" json:"email"`
		PasswordHash string    `gorm:"not null" json:"-"`
		IsActive     bool      `gorm:"default:true" json:"is_active"`
	}

	type TestPlayer struct {
		ID       uuid.UUID `gorm:"type:text;primary_key" json:"id"`
		UserID   uuid.UUID `gorm:"type:text;uniqueIndex" json:"user_id"`
		Username string    `gorm:"not null" json:"username"`
		Level    int       `gorm:"default:1" json:"level"`
		Rating   int       `gorm:"default:1200" json:"rating"`
		Coins    int       `gorm:"default:1000" json:"coins"`
	}

	type TestGame struct {
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

	type TestGameMove struct {
		ID                uuid.UUID `gorm:"type:text;primary_key" json:"id"`
		GameID            uuid.UUID `gorm:"type:text;not null" json:"game_id"`
		PlayerID          uuid.UUID `gorm:"type:text;not null" json:"player_id"`
		MoveNumber        int       `gorm:"not null" json:"move_number"`
		CardSuit          string    `json:"card_suit,omitempty"`
		CardValue         int       `json:"card_value,omitempty"`
		TableCardCount    int       `gorm:"not null" json:"table_card_count"`
		TrickNumber       int       `gorm:"not null" json:"trick_number"`
		MoveType          string    `gorm:"default:'PLAY_CARD'" json:"move_type"`
		IsObjection       bool      `gorm:"default:false" json:"is_objection"`
		ObjectedCardSuit  *string   `json:"objected_card_suit,omitempty"`
		ObjectedCardValue *int      `json:"objected_card_value,omitempty"`
		RoundComplete     bool      `gorm:"default:false" json:"round_complete"`
		PointsAwarded     int       `gorm:"default:0" json:"points_awarded"`
		TimeTakenMs       int64     `gorm:"default:0" json:"time_taken_ms"`
	}

	type TestPlayerStatistics struct {
		ID                   uuid.UUID `gorm:"type:text;primary_key" json:"id"`
		PlayerID             uuid.UUID `gorm:"type:text;uniqueIndex" json:"player_id"`
		GamesPlayed          int       `gorm:"default:0" json:"games_played"`
		GamesWon             int       `gorm:"default:0" json:"games_won"`
		GamesLost            int       `gorm:"default:0" json:"games_lost"`
		TotalPointsCollected int       `gorm:"default:0" json:"total_points_collected"`
		SevensPlayed         int       `gorm:"default:0" json:"sevens_played"`
		EightsPlayed         int       `gorm:"default:0" json:"eights_played"`
		PointCardsWon        int       `gorm:"default:0" json:"point_cards_won"`
		TricksWon            int       `gorm:"default:0" json:"tricks_won"`
	}

	// Auto-migrate simplified models
	err = db.AutoMigrate(
		&TestUser{},
		&TestPlayer{},
		&TestPlayerStatistics{},
		&TestGame{},
		&TestGameMove{},
	)
	require.NoError(t, err, "Failed to migrate database schema")

	return db
}

// Helper function to create test players
func createTestPlayers(t *testing.T, db *gorm.DB, count int) []Player {
	players := make([]Player, count)
	for i := 0; i < count; i++ {
		user := User{
			Username:     "test_user_" + strconv.Itoa(i),
			Email:        "test" + strconv.Itoa(i) + "@example.com",
			PasswordHash: "test_hash",
			IsActive:     true,
		}
		result := db.Create(&user)
		require.NoError(t, result.Error)

		player := Player{
			UserID:   user.ID,
			Username: "test_player_" + strconv.Itoa(i),
			Level:    1,
			Rating:   1200,
			Coins:    1000,
		}
		result = db.Create(&player)
		require.NoError(t, result.Error)

		players[i] = player
	}
	return players
}

// TestGame_MultiPlayerGameCreation tests multi-player game creation
func TestGame_MultiPlayerGameCreation(t *testing.T) {
	db := setupTestDatabase(t)

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
			// Create test players
			players := createTestPlayers(t, db, tt.playerCount)

			// Create game
			game := Game{
				Player1ID:         players[0].ID,
				Player2ID:         players[1].ID,
				GameMode:          tt.gameMode,
				AuthenticMode:     tt.authenticMode,
				UseAuthenticRules: true,
				Status:            "waiting",
			}

			// Set additional players for multi-player games
			if tt.playerCount >= 3 {
				game.Player3ID = &players[2].ID
				player3Score := 0
				game.Player3Score = &player3Score
				player3Rating := 1200
				game.Player3RatingBefore = &player3Rating
			}

			if tt.playerCount >= 4 {
				game.Player4ID = &players[3].ID
				player4Score := 0
				game.Player4Score = &player4Score
				player4Rating := 1200
				game.Player4RatingBefore = &player4Rating

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
			var savedGame Game
			err := db.Preload("Player1").Preload("Player2").Preload("Player3").Preload("Player4").
				First(&savedGame, game.ID).Error
			require.NoError(t, err)

			// Assertions
			assert.Equal(t, players[0].ID, savedGame.Player1ID)
			assert.Equal(t, players[1].ID, savedGame.Player2ID)
			assert.Equal(t, tt.gameMode, savedGame.GameMode)
			assert.Equal(t, tt.authenticMode, savedGame.AuthenticMode)
			assert.True(t, savedGame.UseAuthenticRules)

			// Verify multi-player fields
			if tt.playerCount >= 3 {
				require.NotNil(t, savedGame.Player3ID)
				assert.Equal(t, players[2].ID, *savedGame.Player3ID)
				assert.NotNil(t, savedGame.Player3Score)
				assert.Equal(t, 0, *savedGame.Player3Score)
			} else {
				assert.Nil(t, savedGame.Player3ID)
				assert.Nil(t, savedGame.Player3Score)
			}

			if tt.playerCount >= 4 {
				require.NotNil(t, savedGame.Player4ID)
				assert.Equal(t, players[3].ID, *savedGame.Player4ID)
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

// TestGameMove_AuthenticSepticaMoveStorage tests authentic game move storage
func TestGameMove_AuthenticSepticaMoveStorage(t *testing.T) {
	db := setupTestDatabase(t)

	// Create test players and game
	players := createTestPlayers(t, db, 2)
	game := Game{
		Player1ID:         players[0].ID,
		Player2ID:         players[1].ID,
		GameMode:          "ranked",
		AuthenticMode:     "2_player",
		UseAuthenticRules: true,
		Status:            "in_progress",
	}
	db.Create(&game)

	tests := []struct {
		name               string
		moveType           string
		isObjection        bool
		cardSuit           *string
		cardValue          *int
		objectedCardSuit   *string
		objectedCardValue  *int
		roundComplete      bool
		pointsAwarded      int
		expectValidStorage bool
	}{
		{
			name:               "Regular card play",
			moveType:           "PLAY_CARD",
			isObjection:        false,
			cardSuit:           stringPtr("hearts"),
			cardValue:          intPtr(10),
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
			cardSuit:           stringPtr("spades"),
			cardValue:          intPtr(7),
			objectedCardSuit:   stringPtr("hearts"),
			objectedCardValue:  intPtr(10),
			roundComplete:      true,
			pointsAwarded:      1,
			expectValidStorage: true,
		},
		{
			name:               "Objection with same rank",
			moveType:           "PLAY_CARD",
			isObjection:        true,
			cardSuit:           stringPtr("diamonds"),
			cardValue:          intPtr(13),
			objectedCardSuit:   stringPtr("clubs"),
			objectedCardValue:  intPtr(13),
			roundComplete:      true,
			pointsAwarded:      0,
			expectValidStorage: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			move := GameMove{
				GameID:            game.ID,
				PlayerID:          players[0].ID,
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
				var savedMove GameMove
				err := db.First(&savedMove, move.ID).Error
				require.NoError(t, err)

				// Assertions
				assert.Equal(t, game.ID, savedMove.GameID)
				assert.Equal(t, players[0].ID, savedMove.PlayerID)
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

// TestGame_TeamScoreTracking tests team score tracking for 4-player games
func TestGame_TeamScoreTracking(t *testing.T) {
	db := setupTestDatabase(t)

	// Create 4 test players
	players := createTestPlayers(t, db, 4)

	// Create 4-player team game
	team1Score := 0
	team2Score := 0
	game := Game{
		Player1ID:         players[0].ID,  // Team 1
		Player2ID:         players[1].ID,  // Team 2
		Player3ID:         &players[2].ID, // Team 1
		Player4ID:         &players[3].ID, // Team 2
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
	game.Player1Score = 2         // Player 1 individual score
	game.Player3Score = intPtr(1) // Player 3 individual score
	game.Player2Score = 1         // Player 2 individual score
	game.Player4Score = intPtr(1) // Player 4 individual score
	game.Team1Score = intPtr(3)   // Team 1 total
	game.Team2Score = intPtr(2)   // Team 2 total
	game.Status = "completed"
	game.WinningTeam = stringPtr("team1")

	result = db.Save(&game)
	require.NoError(t, result.Error)

	// Verify team score tracking
	var savedGame Game
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

// TestGame_BackwardCompatibility tests backward compatibility with legacy 2-player games
func TestGame_BackwardCompatibility(t *testing.T) {
	db := setupTestDatabase(t)

	// Create test players
	players := createTestPlayers(t, db, 2)

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
			game := Game{
				Player1ID:         players[0].ID,
				Player2ID:         players[1].ID,
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
				var savedGame Game
				err := db.First(&savedGame, game.ID).Error
				require.NoError(t, err)

				assert.Equal(t, tt.useAuthenticRules, savedGame.UseAuthenticRules)
				if tt.authenticMode != "" {
					assert.Equal(t, tt.authenticMode, savedGame.AuthenticMode)
				}

				// Legacy games should still work
				assert.Equal(t, players[0].ID, savedGame.Player1ID)
				assert.Equal(t, players[1].ID, savedGame.Player2ID)
			} else {
				assert.Error(t, result.Error)
			}
		})
	}
}

// TestGameMove_PassMoveHandling tests pass move handling in the database
func TestGameMove_PassMoveHandling(t *testing.T) {
	db := setupTestDatabase(t)

	// Create test players and game
	players := createTestPlayers(t, db, 2)
	game := Game{
		Player1ID:         players[0].ID,
		Player2ID:         players[1].ID,
		UseAuthenticRules: true,
		AuthenticMode:     "2_player",
		Status:            "in_progress",
	}
	db.Create(&game)

	// Test pass move with no card information
	passMove := GameMove{
		GameID:         game.ID,
		PlayerID:       players[1].ID,
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
	var savedMove GameMove
	err := db.First(&savedMove, passMove.ID).Error
	require.NoError(t, err)

	assert.Equal(t, "PASS", savedMove.MoveType)
	assert.Empty(t, savedMove.CardSuit)     // No card played
	assert.Equal(t, 0, savedMove.CardValue) // No card played
	assert.False(t, savedMove.IsObjection)
	assert.True(t, savedMove.RoundComplete)
	assert.Equal(t, 1, savedMove.PointsAwarded)
	assert.Nil(t, savedMove.ObjectedCardSuit)
	assert.Nil(t, savedMove.ObjectedCardValue)
}

// TestDatabase_SchemaConsistency tests database schema consistency
func TestDatabase_SchemaConsistency(t *testing.T) {
	db := setupTestDatabase(t)

	// Test foreign key relationships
	t.Run("Foreign key relationships", func(t *testing.T) {
		players := createTestPlayers(t, db, 4)

		// Create game with all foreign keys
		game := Game{
			Player1ID:         players[0].ID,
			Player2ID:         players[1].ID,
			Player3ID:         &players[2].ID,
			Player4ID:         &players[3].ID,
			UseAuthenticRules: true,
			AuthenticMode:     "4_player",
		}
		db.Create(&game)

		// Verify relationships can be loaded
		var loadedGame Game
		err := db.Preload("Player1").Preload("Player2").Preload("Player3").Preload("Player4").
			First(&loadedGame, game.ID).Error
		require.NoError(t, err)

		assert.Equal(t, players[0].Username, loadedGame.Player1.Username)
		assert.Equal(t, players[1].Username, loadedGame.Player2.Username)
		require.NotNil(t, loadedGame.Player3)
		assert.Equal(t, players[2].Username, loadedGame.Player3.Username)
		require.NotNil(t, loadedGame.Player4)
		assert.Equal(t, players[3].Username, loadedGame.Player4.Username)
	})

	// Test nullable fields
	t.Run("Nullable fields handling", func(t *testing.T) {
		players := createTestPlayers(t, db, 2)

		// Create minimal 2-player game
		game := Game{
			Player1ID: players[0].ID,
			Player2ID: players[1].ID,
		}
		result := db.Create(&game)
		require.NoError(t, result.Error)

		// Verify nullable fields are properly handled
		var savedGame Game
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
	t.Run("UUID generation", func(t *testing.T) {
		players := createTestPlayers(t, db, 2)

		game := Game{
			Player1ID: players[0].ID,
			Player2ID: players[1].ID,
		}
		result := db.Create(&game)
		require.NoError(t, result.Error)

		// Verify UUID was generated
		assert.NotEqual(t, uuid.Nil, game.ID)
		assert.NotEmpty(t, game.ID.String())
	})
}

// TestPlayerStatistics_MultiPlayerSupport tests player statistics for multi-player games
func TestPlayerStatistics_MultiPlayerSupport(t *testing.T) {
	db := setupTestDatabase(t)

	// Create test players
	players := createTestPlayers(t, db, 4)

	// Create statistics for each player
	for i, player := range players {
		stats := PlayerStatistics{
			PlayerID:             player.ID,
			GamesPlayed:          10 + i,
			GamesWon:             5 + i,
			GamesLost:            3 + i,
			TotalPointsCollected: 50 + i*10,
			SevensPlayed:         15 + i*2,
			EightsPlayed:         8 + i,
			PointCardsWon:        25 + i*3,
			TricksWon:            35 + i*4,
		}
		result := db.Create(&stats)
		require.NoError(t, result.Error)
	}

	// Verify statistics storage
	for i, player := range players {
		var stats PlayerStatistics
		err := db.Where("player_id = ?", player.ID).First(&stats).Error
		require.NoError(t, err)

		assert.Equal(t, 10+i, stats.GamesPlayed)
		assert.Equal(t, 5+i, stats.GamesWon)
		assert.Equal(t, 15+i*2, stats.SevensPlayed)
		assert.Equal(t, 8+i, stats.EightsPlayed)
	}
}

// Helper functions
func stringPtr(s string) *string {
	return &s
}

func intPtr(i int) *int {
	return &i
}
