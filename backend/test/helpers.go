package test

import (
	"testing"

	"septica-backend/internal/database"

	"github.com/google/uuid"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

// setupTestDB creates an in-memory SQLite database for testing
func setupTestDB(t *testing.T) *gorm.DB {
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Silent),
	})
	if err != nil {
		t.Fatalf("Failed to create test database: %v", err)
	}

	// Run migrations
	err = db.AutoMigrate(
		&database.User{},
		&database.Player{},
		&database.Game{},
		&database.MatchmakingQueue{},
	)
	if err != nil {
		t.Fatalf("Failed to run migrations: %v", err)
	}

	return db
}

// teardownTestDB closes the test database
func teardownTestDB(t *testing.T, db *gorm.DB) {
	sqlDB, err := db.DB()
	if err != nil {
		t.Logf("Failed to get SQL DB: %v", err)
		return
	}
	sqlDB.Close()
}

// createTestUser creates a test user and player in the database
func createTestUser(db *gorm.DB, userID uuid.UUID, username string, rating int) error {
	// Create user with BaseModel
	user := &database.User{
		BaseModel: database.BaseModel{
			ID: userID,
		},
		Username:     username,
		Email:        username + "@test.com",
		PasswordHash: "test",
		IsActive:     true,
	}
	if err := db.Create(user).Error; err != nil {
		return err
	}

	// Create player
	player := &database.Player{
		UserID:   userID,
		Username: username,
		Rating:   rating,
	}
	if err := db.Create(player).Error; err != nil {
		return err
	}

	return nil
}
