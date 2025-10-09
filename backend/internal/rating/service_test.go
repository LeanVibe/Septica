package rating

import (
	"context"
	"testing"

	"septica-backend/internal/database"
	"septica-backend/pkg/logger"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func setupTestDB(t *testing.T) *gorm.DB {
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	require.NoError(t, err)

	// Auto-migrate test schema
	err = db.AutoMigrate(
		&database.User{},
		&database.Player{},
		&database.PlayerStatistics{},
		&database.PlayerSeasonStats{},
	)
	require.NoError(t, err)

	return db
}

func createTestPlayer(t *testing.T, db *gorm.DB, username string, rating int) *database.Player {
	// Create user first
	user := &database.User{
		BaseModel:    database.BaseModel{ID: uuid.New()},
		Username:     username,
		Email:        username + "@test.com",
		PasswordHash: "test_hash",
		IsActive:     true,
	}
	require.NoError(t, db.Create(user).Error)

	// Create player
	player := &database.Player{
		BaseModel: database.BaseModel{ID: uuid.New()},
		UserID:    user.ID,
		Username:  username,
		Rating:    rating,
		Level:     10,
		Arena:     5,
	}
	require.NoError(t, db.Create(player).Error)

	return player
}

func TestGetLeaderboard_WithoutSeason(t *testing.T) {
	db := setupTestDB(t)
	log := logger.New("debug")
	service := NewService(db, DefaultELOConfig(), log)

	// Create test players with statistics
	player1 := createTestPlayer(t, db, "player1", 1500)
	player2 := createTestPlayer(t, db, "player2", 1600)

	// Create player statistics
	stats1 := &database.PlayerStatistics{
		BaseModel:        database.BaseModel{ID: uuid.New()},
		PlayerID:         player1.ID,
		GamesPlayed:      100,
		GamesWon:         60,
		GamesLost:        40,
		CurrentWinStreak: 5,
	}
	stats2 := &database.PlayerStatistics{
		BaseModel:        database.BaseModel{ID: uuid.New()},
		PlayerID:         player2.ID,
		GamesPlayed:      150,
		GamesWon:         100,
		GamesLost:        50,
		CurrentWinStreak: 3,
	}

	require.NoError(t, db.Create(stats1).Error)
	require.NoError(t, db.Create(stats2).Error)

	// Test all-time leaderboard (no season parameter)
	ctx := context.Background()
	leaderboard, err := service.GetLeaderboard(ctx, 10, "")

	require.NoError(t, err)
	require.Len(t, leaderboard, 2)

	// Verify ordering by rating (player2 has higher rating)
	assert.Equal(t, player2.ID, leaderboard[0].PlayerID)
	assert.Equal(t, "player2", leaderboard[0].Username)
	assert.Equal(t, 1600, leaderboard[0].Rating)
	assert.Equal(t, 1, leaderboard[0].Rank)

	assert.Equal(t, player1.ID, leaderboard[1].PlayerID)
	assert.Equal(t, "player1", leaderboard[1].Username)
	assert.Equal(t, 1500, leaderboard[1].Rating)
	assert.Equal(t, 2, leaderboard[1].Rank)

	// Verify statistics
	assert.Equal(t, 150, leaderboard[0].GamesPlayed)
	assert.Equal(t, 100, leaderboard[0].GamesWon)
	assert.Equal(t, 50, leaderboard[0].GamesLost)
}

func TestGetLeaderboard_WithSeason(t *testing.T) {
	db := setupTestDB(t)
	log := logger.New("debug")
	service := NewService(db, DefaultELOConfig(), log)

	// Create test players
	player1 := createTestPlayer(t, db, "player1", 1500)
	player2 := createTestPlayer(t, db, "player2", 1600)

	// Create seasonal statistics for 2025-Q1
	seasonStats1 := &database.PlayerSeasonStats{
		BaseModel:         database.BaseModel{ID: uuid.New()},
		PlayerID:          player1.ID,
		Season:            "2025-Q1",
		RankedGamesPlayed: 50,
		RankedGamesWon:    35,
		WinRate:           70.0,
	}
	seasonStats2 := &database.PlayerSeasonStats{
		BaseModel:         database.BaseModel{ID: uuid.New()},
		PlayerID:          player2.ID,
		Season:            "2025-Q1",
		RankedGamesPlayed: 60,
		RankedGamesWon:    45,
		WinRate:           75.0,
	}

	require.NoError(t, db.Create(seasonStats1).Error)
	require.NoError(t, db.Create(seasonStats2).Error)

	// Test seasonal leaderboard
	ctx := context.Background()
	leaderboard, err := service.GetLeaderboard(ctx, 10, "2025-Q1")

	require.NoError(t, err)
	require.Len(t, leaderboard, 2)

	// Verify ordering by rating (player2 has higher rating)
	assert.Equal(t, player2.ID, leaderboard[0].PlayerID)
	assert.Equal(t, "player2", leaderboard[0].Username)
	assert.Equal(t, 1600, leaderboard[0].Rating)
	assert.Equal(t, 1, leaderboard[0].Rank)

	// Verify seasonal statistics are used
	assert.Equal(t, 60, leaderboard[0].GamesPlayed)
	assert.Equal(t, 45, leaderboard[0].GamesWon)
	assert.Equal(t, 15, leaderboard[0].GamesLost) // Calculated from played - won
	assert.Equal(t, 75.0, leaderboard[0].WinRate)

	assert.Equal(t, 50, leaderboard[1].GamesPlayed)
	assert.Equal(t, 35, leaderboard[1].GamesWon)
	assert.Equal(t, 70.0, leaderboard[1].WinRate)
}

func TestGetLeaderboard_SeasonFilter(t *testing.T) {
	db := setupTestDB(t)
	log := logger.New("debug")
	service := NewService(db, DefaultELOConfig(), log)

	// Create test player
	player1 := createTestPlayer(t, db, "player1", 1500)

	// Create seasonal statistics for different seasons
	seasonStats2025Q1 := &database.PlayerSeasonStats{
		BaseModel:         database.BaseModel{ID: uuid.New()},
		PlayerID:          player1.ID,
		Season:            "2025-Q1",
		RankedGamesPlayed: 50,
		RankedGamesWon:    35,
		WinRate:           70.0,
	}
	seasonStats2024Q4 := &database.PlayerSeasonStats{
		BaseModel:         database.BaseModel{ID: uuid.New()},
		PlayerID:          player1.ID,
		Season:            "2024-Q4",
		RankedGamesPlayed: 40,
		RankedGamesWon:    25,
		WinRate:           62.5,
	}

	require.NoError(t, db.Create(seasonStats2025Q1).Error)
	require.NoError(t, db.Create(seasonStats2024Q4).Error)

	// Test 2025-Q1 leaderboard
	ctx := context.Background()
	leaderboard2025, err := service.GetLeaderboard(ctx, 10, "2025-Q1")
	require.NoError(t, err)
	require.Len(t, leaderboard2025, 1)
	assert.Equal(t, 50, leaderboard2025[0].GamesPlayed)

	// Test 2024-Q4 leaderboard
	leaderboard2024, err := service.GetLeaderboard(ctx, 10, "2024-Q4")
	require.NoError(t, err)
	require.Len(t, leaderboard2024, 1)
	assert.Equal(t, 40, leaderboard2024[0].GamesPlayed)

	// Verify different seasons return different stats
	assert.NotEqual(t, leaderboard2025[0].GamesPlayed, leaderboard2024[0].GamesPlayed)
}

func TestGetLeaderboard_Limit(t *testing.T) {
	db := setupTestDB(t)
	log := logger.New("debug")
	service := NewService(db, DefaultELOConfig(), log)

	// Create 5 test players
	for i := 0; i < 5; i++ {
		username := "player_" + uuid.New().String()[:8]
		createTestPlayer(t, db, username, 1500+i*100)
	}

	// Test limit parameter
	ctx := context.Background()

	leaderboard, err := service.GetLeaderboard(ctx, 3, "")
	require.NoError(t, err)
	assert.Equal(t, 3, len(leaderboard))

	leaderboard, err = service.GetLeaderboard(ctx, 0, "")
	require.NoError(t, err)
	assert.Equal(t, 5, len(leaderboard))
}
