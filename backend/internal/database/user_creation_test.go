package database

import (
	"fmt"
	"testing"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func TestGetOrCreateUser(t *testing.T) {
	// Setup in-memory database with unique name for test isolation
	db, cleanup := setupTestDB(t)
	defer cleanup()

	// Auto-migrate User model
	err := db.AutoMigrate(&User{})
	require.NoError(t, err)

	// Create database service
	dbService := NewDatabase(db)

	// Test 1: Create new user
	testID := uuid.New()
	testUsername := "TestUser"
	testEmail := "test@example.com"
	testPassword := "test_password"

	user, err := dbService.GetOrCreateUser(testID, testUsername, testEmail, testPassword)
	assert.NoError(t, err)
	assert.NotNil(t, user)
	assert.Equal(t, testID, user.ID)
	assert.Equal(t, testUsername, user.Username)
	assert.Equal(t, testEmail, user.Email)
	assert.Equal(t, testPassword, user.PasswordHash)
	assert.True(t, user.IsActive)

	// Verify user exists in database
	var userFromDB User
	err = db.Where("id = ?", testID).First(&userFromDB).Error
	assert.NoError(t, err)
	assert.Equal(t, user.ID, userFromDB.ID)
	assert.Equal(t, user.Username, userFromDB.Username)

	// Test 2: Get existing user
	user2, err := dbService.GetOrCreateUser(testID, testUsername, testEmail, testPassword)
	assert.NoError(t, err)
	assert.Equal(t, user.ID, user2.ID)
	assert.Equal(t, user.Username, user2.Username)

	// Verify only one user exists
	var userCount int64
	db.Model(&User{}).Count(&userCount)
	assert.Equal(t, int64(1), userCount)

	// Test 3: Get existing user by different criteria (should find existing user)
	user3, err := dbService.GetOrCreateUser(testID, "DifferentUsername", "different@example.com", "different_password")
	assert.NoError(t, err)
	assert.Equal(t, user.ID, user3.ID) // Should return existing user

	// Verify still only one user exists
	db.Model(&User{}).Count(&userCount)
	assert.Equal(t, int64(1), userCount)
}

func TestGetOrCreateUser_Concurrency(t *testing.T) {
	// Setup in-memory database with unique name for test isolation
	db, cleanup := setupTestDB(t)
	defer cleanup()

	// Auto-migrate User model
	err := db.AutoMigrate(&User{})
	require.NoError(t, err)

	// Create database service
	dbService := NewDatabase(db)

	// Test concurrent user creation with same ID
	testID := uuid.New()
	testUsername := "ConcurrentUser"
	testEmail := "concurrent@example.com"
	testPassword := "test_password"

	concurrency := 10
	results := make(chan error, concurrency)

	// Launch multiple goroutines trying to create the same user
	for i := 0; i < concurrency; i++ {
		go func() {
			_, err := dbService.GetOrCreateUser(testID, testUsername, testEmail, testPassword)
			results <- err
		}()
	}

	// Wait for all goroutines to complete
	successCount := 0
	for i := 0; i < concurrency; i++ {
		err := <-results
		if err == nil {
			successCount++
		}
	}

	// All should succeed (GetOrCreateUser should handle race conditions)
	assert.Equal(t, concurrency, successCount)

	// Verify only one user was created
	var userCount int64
	db.Model(&User{}).Count(&userCount)
	assert.Equal(t, int64(1), userCount)

	// Verify the user exists and has correct data
	var user User
	err = db.Where("id = ?", testID).First(&user).Error
	assert.NoError(t, err)
	assert.Equal(t, testUsername, user.Username)
	assert.Equal(t, testEmail, user.Email)
}

func TestGetOrCreateUser_ErrorHandling(t *testing.T) {
	// Setup in-memory database with unique name for test isolation
	db, cleanup := setupTestDB(t)
	defer cleanup()

	// Auto-migrate User model
	err := db.AutoMigrate(&User{})
	require.NoError(t, err)

	// Create database service
	dbService := NewDatabase(db)

	// Test with nil ID (should generate new UUID)
	user, err := dbService.GetOrCreateUser(uuid.Nil, "NilIDUser", "nil@example.com", "test_password")
	assert.NoError(t, err)
	assert.NotNil(t, user)
	assert.NotEqual(t, uuid.Nil, user.ID)
	assert.Equal(t, "NilIDUser", user.Username)

	// Test with empty fields (should still work)
	user2, err := dbService.GetOrCreateUser(uuid.New(), "", "", "")
	assert.NoError(t, err)
	assert.NotNil(t, user2)
	assert.NotEqual(t, uuid.Nil, user2.ID)
}

func TestGetOrCreateUser_PlayerLinking(t *testing.T) {
	// Setup in-memory database with unique name for test isolation
	db, cleanup := setupTestDB(t)
	defer cleanup()

	// Auto-migrate User and Player models
	err := db.AutoMigrate(&User{}, &Player{})
	require.NoError(t, err)

	// Create database service
	dbService := NewDatabase(db)

	// Test 1: Create user first, then create linked player
	userID := uuid.New()
	user, err := dbService.GetOrCreateUser(userID, "LinkedUser", "linked@example.com", "test_password")
	require.NoError(t, err)

	// Create player record linked to the user
	player := &Player{
		BaseModel: BaseModel{ID: uuid.New()},
		UserID:    user.ID,
		Username:  "LinkedUser",
		Rating:    1200,
		Level:     1,
		XP:        0,
		Arena:     1,
		Coins:     1000,
		Gems:      0,
		SelectedCardBack:   "default",
		SelectedTableTheme: "default",
		SelectedAvatar:     "default",
	}

	err = db.Create(player).Error
	assert.NoError(t, err)

	// Verify the linking worked correctly
	var createdPlayer Player
	err = db.Preload("User").Where("id = ?", player.ID).First(&createdPlayer).Error
	assert.NoError(t, err)
	assert.Equal(t, user.ID, createdPlayer.UserID)
	assert.Equal(t, user.Username, createdPlayer.User.Username)
	assert.Equal(t, "LinkedUser", createdPlayer.Username)
	assert.Equal(t, 1200, createdPlayer.Rating)
}

// Benchmark test for GetOrCreateUser performance
func BenchmarkGetOrCreateUser(b *testing.B) {
	dbName := fmt.Sprintf("file:bench_%s?mode=memory&cache=shared", b.Name())
	db, err := gorm.Open(sqlite.Open(dbName), &gorm.Config{})
	if err != nil {
		b.Fatal(err)
	}

	err = db.AutoMigrate(&User{})
	if err != nil {
		b.Fatal(err)
	}

	dbService := NewDatabase(db)

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		testID := uuid.New()
		_, err := dbService.GetOrCreateUser(testID, "BenchUser", "bench@example.com", "test_password")
		if err != nil {
			b.Fatal(err)
		}
	}
}

// Benchmark test for concurrent GetOrCreateUser
func BenchmarkGetOrCreateUser_Concurrent(b *testing.B) {
	dbName := fmt.Sprintf("file:bench_%s?mode=memory&cache=shared", b.Name())
	db, err := gorm.Open(sqlite.Open(dbName), &gorm.Config{})
	if err != nil {
		b.Fatal(err)
	}

	err = db.AutoMigrate(&User{})
	if err != nil {
		b.Fatal(err)
	}

	dbService := NewDatabase(db)

	b.ResetTimer()
	b.RunParallel(func(pb *testing.PB) {
		for pb.Next() {
			testID := uuid.New()
			_, err := dbService.GetOrCreateUser(testID, "ConcurrentBenchUser", "concurrent@example.com", "test_password")
			if err != nil {
				b.Fatal(err)
			}
		}
	})
}

// Benchmark test for GetOrCreateUser with same ID (race condition scenario)
func BenchmarkGetOrCreateUser_SameID(b *testing.B) {
	dbName := fmt.Sprintf("file:bench_%s?mode=memory&cache=shared", b.Name())
	db, err := gorm.Open(sqlite.Open(dbName), &gorm.Config{})
	if err != nil {
		b.Fatal(err)
	}

	err = db.AutoMigrate(&User{})
	if err != nil {
		b.Fatal(err)
	}

	dbService := NewDatabase(db)
	testID := uuid.New()

	b.ResetTimer()
	b.RunParallel(func(pb *testing.PB) {
		for pb.Next() {
			_, err := dbService.GetOrCreateUser(testID, "SameIDBenchUser", "sameid@example.com", "test_password")
			if err != nil {
				b.Fatal(err)
			}
		}
	})
}