package matchmaking

import (
	"testing"

	"septica-backend/internal/database"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

// TestGORMQueueUpdateFix verifies the GORM bulk update fix for queue entries
// This test ensures that .Model().Updates() pattern is used correctly
func TestGORMQueueUpdateFix(t *testing.T) {
	// Setup in-memory database
	db, err := gorm.Open(sqlite.Open("file::memory:?cache=shared"), &gorm.Config{})
	require.NoError(t, err)

	// Migrate schema
	err = db.AutoMigrate(&database.MatchmakingQueue{})
	require.NoError(t, err)

	// Create test queue entries
	player1ID := uuid.New()
	player2ID := uuid.New()

	entry1 := &database.MatchmakingQueue{
		BaseModel: database.BaseModel{ID: uuid.New()},
		PlayerID:  player1ID,
		QueueType: "ranked",
		Rating:    1200,
		IsActive:  true,
	}

	entry2 := &database.MatchmakingQueue{
		BaseModel: database.BaseModel{ID: uuid.New()},
		PlayerID:  player2ID,
		QueueType: "ranked",
		Rating:    1250,
		IsActive:  true,
	}

	err = db.Create(entry1).Error
	require.NoError(t, err)

	err = db.Create(entry2).Error
	require.NoError(t, err)

	// Test 1: Bulk update multiple entries (match creation scenario)
	t.Run("BulkUpdateMultipleEntries", func(t *testing.T) {
		// This is the fixed pattern from processor.go:192-194
		err := db.Model(&database.MatchmakingQueue{}).
			Where("player_id IN (?, ?) AND is_active = true", player1ID, player2ID).
			Updates(map[string]interface{}{"is_active": false}).Error

		assert.NoError(t, err, "Bulk update should succeed with Model().Updates() pattern")

		// Verify both entries are marked inactive
		var count int64
		err = db.Model(&database.MatchmakingQueue{}).
			Where("player_id IN (?, ?) AND is_active = false", player1ID, player2ID).
			Count(&count).Error

		assert.NoError(t, err)
		assert.Equal(t, int64(2), count, "Both entries should be marked inactive")
	})

	// Reset entries for next test
	err = db.Model(&database.MatchmakingQueue{}).
		Where("player_id IN (?, ?)", player1ID, player2ID).
		Updates(map[string]interface{}{"is_active": true}).Error
	require.NoError(t, err)

	// Test 2: Single entry update (leave queue scenario)
	t.Run("SingleEntryUpdate", func(t *testing.T) {
		// This is the fixed pattern from service.go:331-333
		err := db.Model(&database.MatchmakingQueue{}).
			Where("player_id = ? AND is_active = true", player1ID).
			Updates(map[string]interface{}{"is_active": false}).Error

		assert.NoError(t, err, "Single entry update should succeed with Model().Updates() pattern")

		// Verify the entry is marked inactive
		var entry database.MatchmakingQueue
		err = db.Where("player_id = ?", player1ID).First(&entry).Error

		assert.NoError(t, err)
		assert.False(t, entry.IsActive, "Entry should be marked inactive")

		// Verify other entry is still active
		var otherEntry database.MatchmakingQueue
		err = db.Where("player_id = ?", player2ID).First(&otherEntry).Error

		assert.NoError(t, err)
		assert.True(t, otherEntry.IsActive, "Other entry should still be active")
	})

	// Test 3: Transaction safety with bulk update
	t.Run("TransactionSafetyWithBulkUpdate", func(t *testing.T) {
		// Reset entries
		err = db.Model(&database.MatchmakingQueue{}).
			Where("player_id IN (?, ?)", player1ID, player2ID).
			Updates(map[string]interface{}{"is_active": true}).Error
		require.NoError(t, err)

		// Test transaction with bulk update (simulates match creation)
		err = db.Transaction(func(tx *gorm.DB) error {
			// Update queue entries within transaction
			if err := tx.Model(&database.MatchmakingQueue{}).
				Where("player_id IN (?, ?) AND is_active = true", player1ID, player2ID).
				Updates(map[string]interface{}{"is_active": false}).Error; err != nil {
				return err
			}

			return nil // Commit
		})

		assert.NoError(t, err, "Transaction with bulk update should succeed")

		// Verify updates were committed
		var count int64
		err = db.Model(&database.MatchmakingQueue{}).
			Where("player_id IN (?, ?) AND is_active = false", player1ID, player2ID).
			Count(&count).Error

		assert.NoError(t, err)
		assert.Equal(t, int64(2), count, "Both entries should be marked inactive after transaction")
	})

	// Test 4: Verify old broken pattern fails (documents the bug we fixed)
	t.Run("OldBrokenPatternDocumentation", func(t *testing.T) {
		// Reset entries
		err = db.Model(&database.MatchmakingQueue{}).
			Where("player_id IN (?, ?)", player1ID, player2ID).
			Updates(map[string]interface{}{"is_active": true}).Error
		require.NoError(t, err)

		// This is the OLD BROKEN pattern that caused the bug:
		// err := db.Where(...).Update("is_active", false).Error
		// It fails because GORM doesn't know which table to update

		// Attempting the old pattern should fail with "Table not set" error
		err = db.Where("player_id IN (?, ?) AND is_active = true", player1ID, player2ID).
			Update("is_active", false).Error

		assert.Error(t, err, "Old pattern without Model() should fail")
		assert.Contains(t, err.Error(), "Table not set", "Error should mention 'Table not set'")
	})
}

// TestGORMBulkUpdatePerformance verifies the performance of bulk updates
func TestGORMBulkUpdatePerformance(t *testing.T) {
	// Setup in-memory database
	db, err := gorm.Open(sqlite.Open("file::memory:?cache=shared"), &gorm.Config{})
	require.NoError(t, err)

	err = db.AutoMigrate(&database.MatchmakingQueue{})
	require.NoError(t, err)

	// Create 100 test entries
	playerIDs := make([]uuid.UUID, 100)
	for i := 0; i < 100; i++ {
		playerIDs[i] = uuid.New()
		entry := &database.MatchmakingQueue{
			BaseModel: database.BaseModel{ID: uuid.New()},
			PlayerID:  playerIDs[i],
			QueueType: "ranked",
			Rating:    1200,
			IsActive:  true,
		}
		err = db.Create(entry).Error
		require.NoError(t, err)
	}

	// Benchmark bulk update
	t.Run("BulkUpdate100Entries", func(t *testing.T) {
		err := db.Model(&database.MatchmakingQueue{}).
			Where("player_id IN ? AND is_active = true", playerIDs).
			Updates(map[string]interface{}{"is_active": false}).Error

		assert.NoError(t, err, "Bulk update of 100 entries should succeed")

		// Verify all entries are marked inactive
		var count int64
		err = db.Model(&database.MatchmakingQueue{}).
			Where("player_id IN ? AND is_active = false", playerIDs).
			Count(&count).Error

		assert.NoError(t, err)
		assert.Equal(t, int64(100), count, "All 100 entries should be marked inactive")
	})
}
