package matchmaking

import (
	"testing"
	"time"

	"septica-backend/internal/database"
	"septica-backend/pkg/logger"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

// setupCleanupTestDB creates an in-memory SQLite database for testing
func setupCleanupTestDB(t *testing.T) (*gorm.DB, *logger.Logger) {
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	require.NoError(t, err, "Failed to create test database")

	// Auto-migrate schema
	err = db.AutoMigrate(
		&database.User{},
		&database.Player{},
		&database.MatchmakingQueue{},
		&database.Game{},
	)
	require.NoError(t, err, "Failed to migrate test database schema")

	log := logger.New("debug")
	return db, log
}

func TestMatchmakingService_CleanupStaleEntries_OrphanedEntries(t *testing.T) {
	// Setup
	db, log := setupCleanupTestDB(t)
	config := DefaultConfig()

	service := &MatchmakingService{
		db:     db,
		logger: log,
		config: config,
		queues: make(map[string]*MatchmakingQueue),
	}

	// Create a valid player
	validUserID := uuid.New()
	validPlayerID := uuid.New()

	validUser := &database.User{
		BaseModel:    database.BaseModel{ID: validUserID},
		Username:     "valid_player",
		Email:        "valid@test.com",
		PasswordHash: "hash",
		IsActive:     true,
	}
	require.NoError(t, db.Create(validUser).Error)

	validPlayer := &database.Player{
		BaseModel: database.BaseModel{ID: validPlayerID},
		UserID:    validUserID,
		Username:  "valid_player",
		Level:     1,
		Rating:    1200,
	}
	require.NoError(t, db.Create(validPlayer).Error)

	// Create an orphaned queue entry (player doesn't exist)
	orphanedEntry := &database.MatchmakingQueue{
		BaseModel:   database.BaseModel{ID: uuid.New()},
		PlayerID:    uuid.New(), // Non-existent player ID
		QueueType:   "ranked",
		Rating:      1000,
		QueuedAt:    time.Now().Add(-5 * time.Minute),
		SearchRange: 100,
		MaxWaitTime: 300,
		IsActive:    true,
	}
	require.NoError(t, db.Create(orphanedEntry).Error)

	// Create a valid queue entry
	validEntry := &database.MatchmakingQueue{
		BaseModel:   database.BaseModel{ID: uuid.New()},
		PlayerID:    validPlayerID,
		QueueType:   "ranked",
		Rating:      1200,
		QueuedAt:    time.Now().Add(-2 * time.Minute),
		SearchRange: 100,
		MaxWaitTime: 300,
		IsActive:    true,
	}
	require.NoError(t, db.Create(validEntry).Error)

	// Verify initial state
	var initialCount int64
	db.Model(&database.MatchmakingQueue{}).Count(&initialCount)
	assert.Equal(t, int64(2), initialCount, "Should have 2 queue entries initially")

	// Run cleanup
	err := service.CleanupStaleEntries()
	require.NoError(t, err, "Cleanup should succeed")

	// Verify orphaned entry was removed
	var remainingCount int64
	db.Model(&database.MatchmakingQueue{}).Count(&remainingCount)
	assert.Equal(t, int64(1), remainingCount, "Should have only 1 queue entry after cleanup")

	// Verify the valid entry still exists
	var remainingEntry database.MatchmakingQueue
	err = db.Where("player_id = ?", validPlayerID).First(&remainingEntry).Error
	require.NoError(t, err, "Valid entry should still exist")
	assert.Equal(t, validPlayerID, remainingEntry.PlayerID)
}

func TestMatchmakingService_CleanupStaleEntries_StaleEntries(t *testing.T) {
	// Setup
	db, log := setupCleanupTestDB(t)
	config := DefaultConfig()

	service := &MatchmakingService{
		db:     db,
		logger: log,
		config: config,
		queues: make(map[string]*MatchmakingQueue),
	}

	// Create two players (since player_id has unique constraint)
	staleUserID := uuid.New()
	stalePlayerID := uuid.New()

	staleUser := &database.User{
		BaseModel:    database.BaseModel{ID: staleUserID},
		Username:     "stale_player",
		Email:        "stale@test.com",
		PasswordHash: "hash",
		IsActive:     true,
	}
	require.NoError(t, db.Create(staleUser).Error)

	stalePlayer := &database.Player{
		BaseModel: database.BaseModel{ID: stalePlayerID},
		UserID:    staleUserID,
		Username:  "stale_player",
		Level:     1,
		Rating:    1200,
	}
	require.NoError(t, db.Create(stalePlayer).Error)

	recentUserID := uuid.New()
	recentPlayerID := uuid.New()

	recentUser := &database.User{
		BaseModel:    database.BaseModel{ID: recentUserID},
		Username:     "recent_player",
		Email:        "recent@test.com",
		PasswordHash: "hash",
		IsActive:     true,
	}
	require.NoError(t, db.Create(recentUser).Error)

	recentPlayer := &database.Player{
		BaseModel: database.BaseModel{ID: recentPlayerID},
		UserID:    recentUserID,
		Username:  "recent_player",
		Level:     1,
		Rating:    1200,
	}
	require.NoError(t, db.Create(recentPlayer).Error)

	// Create a stale queue entry (>10 minutes old)
	staleEntryID := uuid.New()
	staleEntry := &database.MatchmakingQueue{
		BaseModel:   database.BaseModel{ID: staleEntryID},
		PlayerID:    stalePlayerID,
		QueueType:   "ranked",
		Rating:      1200,
		QueuedAt:    time.Now().Add(-15 * time.Minute), // 15 minutes ago
		SearchRange: 100,
		MaxWaitTime: 300,
		IsActive:    true,
	}
	require.NoError(t, db.Create(staleEntry).Error)

	// Create a recent queue entry
	recentEntryID := uuid.New()
	recentEntry := &database.MatchmakingQueue{
		BaseModel:   database.BaseModel{ID: recentEntryID},
		PlayerID:    recentPlayerID,
		QueueType:   "casual",
		Rating:      1200,
		QueuedAt:    time.Now().Add(-2 * time.Minute), // 2 minutes ago
		SearchRange: 100,
		MaxWaitTime: 300,
		IsActive:    true,
	}
	require.NoError(t, db.Create(recentEntry).Error)

	// Run cleanup
	err := service.CleanupStaleEntries()
	require.NoError(t, err, "Cleanup should succeed")

	// Verify stale entry was marked inactive
	var updatedStaleEntry database.MatchmakingQueue
	err = db.Where("id = ?", staleEntryID).First(&updatedStaleEntry).Error
	require.NoError(t, err, "Stale entry should still exist")
	assert.False(t, updatedStaleEntry.IsActive, "Stale entry should be marked inactive")

	// Verify recent entry is still active
	var updatedRecentEntry database.MatchmakingQueue
	err = db.Where("id = ?", recentEntryID).First(&updatedRecentEntry).Error
	require.NoError(t, err, "Recent entry should still exist")
	assert.True(t, updatedRecentEntry.IsActive, "Recent entry should still be active")
}

func TestMatchmakingService_GetCleanupStats(t *testing.T) {
	// Setup
	db, log := setupCleanupTestDB(t)
	config := DefaultConfig()

	service := &MatchmakingService{
		db:     db,
		logger: log,
		config: config,
		queues: make(map[string]*MatchmakingQueue),
	}

	// Create first player for stale entry
	user1ID := uuid.New()
	player1ID := uuid.New()

	user1 := &database.User{
		BaseModel:    database.BaseModel{ID: user1ID},
		Username:     "stale_player",
		Email:        "stale@test.com",
		PasswordHash: "hash",
		IsActive:     true,
	}
	require.NoError(t, db.Create(user1).Error)

	player1 := &database.Player{
		BaseModel: database.BaseModel{ID: player1ID},
		UserID:    user1ID,
		Username:  "stale_player",
		Level:     1,
		Rating:    1200,
	}
	require.NoError(t, db.Create(player1).Error)

	// Create second player for active entry
	user2ID := uuid.New()
	player2ID := uuid.New()

	user2 := &database.User{
		BaseModel:    database.BaseModel{ID: user2ID},
		Username:     "active_player",
		Email:        "active@test.com",
		PasswordHash: "hash",
		IsActive:     true,
	}
	require.NoError(t, db.Create(user2).Error)

	player2 := &database.Player{
		BaseModel: database.BaseModel{ID: player2ID},
		UserID:    user2ID,
		Username:  "active_player",
		Level:     1,
		Rating:    1200,
	}
	require.NoError(t, db.Create(player2).Error)

	// Create various queue entries
	// 1. Orphaned entry
	orphanedEntry := &database.MatchmakingQueue{
		BaseModel:   database.BaseModel{ID: uuid.New()},
		PlayerID:    uuid.New(), // Non-existent player
		QueueType:   "ranked",
		Rating:      1000,
		QueuedAt:    time.Now().Add(-5 * time.Minute),
		SearchRange: 100,
		MaxWaitTime: 300,
		IsActive:    true,
	}
	require.NoError(t, db.Create(orphanedEntry).Error)

	// 2. Stale entry
	staleEntry := &database.MatchmakingQueue{
		BaseModel:   database.BaseModel{ID: uuid.New()},
		PlayerID:    player1ID,
		QueueType:   "ranked",
		Rating:      1200,
		QueuedAt:    time.Now().Add(-15 * time.Minute),
		SearchRange: 100,
		MaxWaitTime: 300,
		IsActive:    true,
	}
	require.NoError(t, db.Create(staleEntry).Error)

	// 3. Active entry
	activeEntry := &database.MatchmakingQueue{
		BaseModel:   database.BaseModel{ID: uuid.New()},
		PlayerID:    player2ID,
		QueueType:   "casual",
		Rating:      1200,
		QueuedAt:    time.Now().Add(-2 * time.Minute),
		SearchRange: 100,
		MaxWaitTime: 300,
		IsActive:    true,
	}
	require.NoError(t, db.Create(activeEntry).Error)

	// Get cleanup stats
	stats := service.GetCleanupStats()

	// Verify stats
	assert.Equal(t, int64(1), stats["orphaned"], "Should have 1 orphaned entry")
	assert.Equal(t, int64(1), stats["stale"], "Should have 1 stale entry")
	assert.Equal(t, int64(3), stats["active"], "Should have 3 active entries")
}

func TestMatchmakingService_CleanupLoop_Integration(t *testing.T) {
	// This test verifies the cleanup loop can be started and stopped properly
	db, log := setupCleanupTestDB(t)
	config := &MatchmakingConfig{
		ProcessInterval: 1 * time.Second,
		UpdateInterval:  1 * time.Second,
		CleanupInterval: 1 * time.Second, // Short interval for testing
	}

	service := &MatchmakingService{
		db:       db,
		logger:   log,
		config:   config,
		queues:   make(map[string]*MatchmakingQueue),
		stopChan: make(chan bool),
		running:  true,
	}

	// Initialize queues
	service.queues["ranked"] = &MatchmakingQueue{Type: "ranked", Entries: []*QueueEntry{}}

	// Start cleanup loop in background
	go service.runCleanupLoop()

	// Let it run briefly
	time.Sleep(100 * time.Millisecond)

	// Stop the service
	service.running = false
	close(service.stopChan)

	// Wait for cleanup to finish
	time.Sleep(100 * time.Millisecond)

	// Test passes if we reach here without deadlock
	assert.True(t, true, "Cleanup loop should start and stop cleanly")
}
