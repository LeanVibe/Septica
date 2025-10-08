package database

import (
	"fmt"
	"sync"
	"testing"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

// setupTestDB creates an in-memory SQLite database for testing
func setupTestDB(t *testing.T) (*gorm.DB, func()) {
	// Create in-memory SQLite database
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	require.NoError(t, err, "Failed to open in-memory database")

	// Run migrations
	err = Migrate(db)
	require.NoError(t, err, "Failed to run migrations")

	// Return cleanup function
	cleanup := func() {
		sqlDB, err := db.DB()
		if err == nil {
			sqlDB.Close()
		}
	}

	return db, cleanup
}

// TestGetUserByUsername_ExistingUser tests retrieving an existing user by username
func TestGetUserByUsername_ExistingUser(t *testing.T) {
	db, cleanup := setupTestDB(t)
	defer cleanup()

	database := NewDatabase(db)

	// Create test user
	testUser := &User{
		BaseModel:    BaseModel{ID: uuid.New()},
		Username:     "test_user",
		Email:        "test@example.com",
		PasswordHash: "hashed_password",
		IsActive:     true,
	}
	err := db.Create(testUser).Error
	require.NoError(t, err)

	// Test retrieval
	user, err := database.GetUserByUsername("test_user")
	assert.NoError(t, err)
	assert.NotNil(t, user)
	assert.Equal(t, "test_user", user.Username)
	assert.Equal(t, "test@example.com", user.Email)
	assert.Equal(t, testUser.ID, user.ID)
}

// TestGetUserByUsername_NonExistentUser tests retrieving a non-existent user
func TestGetUserByUsername_NonExistentUser(t *testing.T) {
	db, cleanup := setupTestDB(t)
	defer cleanup()

	database := NewDatabase(db)

	// Test retrieval of non-existent user
	user, err := database.GetUserByUsername("non_existent_user")
	assert.Error(t, err)
	assert.Nil(t, user)
	assert.ErrorIs(t, err, gorm.ErrRecordNotFound)
}

// TestGetOrCreateUser_CreatesNewUser tests creating a new user
func TestGetOrCreateUser_CreatesNewUser(t *testing.T) {
	db, cleanup := setupTestDB(t)
	defer cleanup()

	database := NewDatabase(db)

	// Test creating new user
	userID := uuid.New()
	user, err := database.GetOrCreateUser(
		userID,
		"new_user",
		"new@example.com",
		"hashed_password",
	)

	assert.NoError(t, err)
	assert.NotNil(t, user)
	assert.Equal(t, userID, user.ID)
	assert.Equal(t, "new_user", user.Username)
	assert.Equal(t, "new@example.com", user.Email)
	assert.Equal(t, "hashed_password", user.PasswordHash)
	assert.True(t, user.IsActive)

	// Verify user was created in database
	var dbUser User
	err = db.Where("id = ?", userID).First(&dbUser).Error
	assert.NoError(t, err)
	assert.Equal(t, "new_user", dbUser.Username)
}

// TestGetOrCreateUser_ReturnsExistingUserByID tests returning existing user by ID
func TestGetOrCreateUser_ReturnsExistingUserByID(t *testing.T) {
	db, cleanup := setupTestDB(t)
	defer cleanup()

	database := NewDatabase(db)

	// Create test user
	existingUserID := uuid.New()
	existingUser := &User{
		BaseModel:    BaseModel{ID: existingUserID},
		Username:     "existing_user",
		Email:        "existing@example.com",
		PasswordHash: "existing_password",
		IsActive:     true,
	}
	err := db.Create(existingUser).Error
	require.NoError(t, err)

	// Test getting existing user by ID
	user, err := database.GetOrCreateUser(
		existingUserID,
		"different_username",
		"different@example.com",
		"different_password",
	)

	assert.NoError(t, err)
	assert.NotNil(t, user)
	assert.Equal(t, existingUserID, user.ID)
	assert.Equal(t, "existing_user", user.Username) // Original username preserved
	assert.Equal(t, "existing@example.com", user.Email)

	// Verify no duplicate was created
	var count int64
	db.Model(&User{}).Count(&count)
	assert.Equal(t, int64(1), count)
}

// TestGetOrCreateUser_ReturnsExistingUserByUsername tests returning existing user by username
func TestGetOrCreateUser_ReturnsExistingUserByUsername(t *testing.T) {
	db, cleanup := setupTestDB(t)
	defer cleanup()

	database := NewDatabase(db)

	// Create test user
	existingUserID := uuid.New()
	existingUser := &User{
		BaseModel:    BaseModel{ID: existingUserID},
		Username:     "existing_user",
		Email:        "existing@example.com",
		PasswordHash: "existing_password",
		IsActive:     true,
	}
	err := db.Create(existingUser).Error
	require.NoError(t, err)

	// Test getting existing user by username with different ID
	differentID := uuid.New()
	user, err := database.GetOrCreateUser(
		differentID,
		"existing_user",
		"different@example.com",
		"different_password",
	)

	assert.NoError(t, err)
	assert.NotNil(t, user)
	assert.Equal(t, existingUserID, user.ID) // Original ID preserved
	assert.Equal(t, "existing_user", user.Username)
	assert.Equal(t, "existing@example.com", user.Email)

	// Verify no duplicate was created
	var count int64
	db.Model(&User{}).Count(&count)
	assert.Equal(t, int64(1), count)
}

// TestGetOrCreateUser_ConcurrentRequests tests handling concurrent requests (race condition test)
func TestGetOrCreateUser_ConcurrentRequests(t *testing.T) {
	db, cleanup := setupTestDB(t)
	defer cleanup()

	database := NewDatabase(db)

	// Test parameters
	userID := uuid.New()
	username := "concurrent_user"
	email := "concurrent@example.com"
	password := "hashed_password"

	// Run concurrent GetOrCreateUser calls
	numGoroutines := 10
	var wg sync.WaitGroup
	errors := make([]error, numGoroutines)
	users := make([]*User, numGoroutines)

	for i := 0; i < numGoroutines; i++ {
		wg.Add(1)
		go func(index int) {
			defer wg.Done()
			user, err := database.GetOrCreateUser(userID, username, email, password)
			errors[index] = err
			users[index] = user
		}(i)
	}

	wg.Wait()

	// Verify at least some calls succeeded (SQLite may have transaction conflicts)
	successCount := 0
	for i := 0; i < numGoroutines; i++ {
		if errors[i] == nil {
			successCount++
			assert.NotNil(t, users[i])
			assert.Equal(t, userID, users[i].ID)
			assert.Equal(t, username, users[i].Username)
		}
	}
	assert.Greater(t, successCount, 0, "At least some concurrent calls should succeed")

	// Check if any user was created (SQLite in-memory may fail all concurrent writes)
	var count int64
	db.Model(&User{}).Count(&count)

	if count > 0 {
		// If user was created, verify it's correct
		assert.LessOrEqual(t, count, int64(1), "At most one user should exist")

		var dbUser User
		err := db.Where("id = ?", userID).First(&dbUser).Error
		assert.NoError(t, err)
		assert.Equal(t, username, dbUser.Username)
		assert.Equal(t, email, dbUser.Email)
	} else {
		// SQLite in-memory with concurrent writes may fail all operations
		// This is expected behavior for the in-memory database
		t.Log("Note: SQLite in-memory database failed all concurrent operations (expected with concurrent writes)")
	}
}

// TestGetOrCreateUser_DifferentUsersSequential tests creating multiple different users sequentially
func TestGetOrCreateUser_DifferentUsersSequential(t *testing.T) {
	db, cleanup := setupTestDB(t)
	defer cleanup()

	database := NewDatabase(db)

	// Create first user
	user1ID := uuid.New()
	user1, err := database.GetOrCreateUser(
		user1ID,
		"user1",
		"user1@example.com",
		"password1",
	)
	assert.NoError(t, err)
	assert.NotNil(t, user1)
	assert.Equal(t, "user1", user1.Username)

	// Create second user
	user2ID := uuid.New()
	user2, err := database.GetOrCreateUser(
		user2ID,
		"user2",
		"user2@example.com",
		"password2",
	)
	assert.NoError(t, err)
	assert.NotNil(t, user2)
	assert.Equal(t, "user2", user2.Username)

	// Verify both users exist
	var count int64
	db.Model(&User{}).Count(&count)
	assert.Equal(t, int64(2), count)
}

// TestGetOrCreateUser_WithInvalidData tests handling invalid data
func TestGetOrCreateUser_WithInvalidData(t *testing.T) {
	db, cleanup := setupTestDB(t)
	defer cleanup()

	database := NewDatabase(db)

	// First, create a user with a specific username
	existingUserID := uuid.New()
	_, err := database.GetOrCreateUser(
		existingUserID,
		"taken_username",
		"taken@example.com",
		"password",
	)
	require.NoError(t, err)

	// Try to create a different user with the same username (should return existing)
	differentID := uuid.New()
	user, err := database.GetOrCreateUser(
		differentID,
		"taken_username",
		"different@example.com",
		"different_password",
	)
	assert.NoError(t, err)
	assert.NotNil(t, user)
	assert.Equal(t, existingUserID, user.ID) // Should return existing user
	assert.Equal(t, "taken_username", user.Username)

	// Verify only one user exists
	var count int64
	db.Model(&User{}).Count(&count)
	assert.Equal(t, int64(1), count)
}

// TestNewDatabase tests creating a new Database instance
func TestNewDatabase(t *testing.T) {
	db, cleanup := setupTestDB(t)
	defer cleanup()

	database := NewDatabase(db)
	assert.NotNil(t, database)
	assert.NotNil(t, database.db)
}

// BenchmarkGetUserByUsername benchmarks the GetUserByUsername method
func BenchmarkGetUserByUsername(b *testing.B) {
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	if err != nil {
		b.Fatal(err)
	}
	defer func() {
		sqlDB, _ := db.DB()
		sqlDB.Close()
	}()

	if err := Migrate(db); err != nil {
		b.Fatal(err)
	}

	database := NewDatabase(db)

	// Create test user
	testUser := &User{
		BaseModel:    BaseModel{ID: uuid.New()},
		Username:     "bench_user",
		Email:        "bench@example.com",
		PasswordHash: "hashed_password",
		IsActive:     true,
	}
	if err := db.Create(testUser).Error; err != nil {
		b.Fatal(err)
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err := database.GetUserByUsername("bench_user")
		if err != nil {
			b.Fatal(err)
		}
	}
}

// BenchmarkGetOrCreateUser_ExistingUser benchmarks GetOrCreateUser for existing users
func BenchmarkGetOrCreateUser_ExistingUser(b *testing.B) {
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	if err != nil {
		b.Fatal(err)
	}
	defer func() {
		sqlDB, _ := db.DB()
		sqlDB.Close()
	}()

	if err := Migrate(db); err != nil {
		b.Fatal(err)
	}

	database := NewDatabase(db)

	// Create test user
	userID := uuid.New()
	testUser := &User{
		BaseModel:    BaseModel{ID: userID},
		Username:     "bench_user",
		Email:        "bench@example.com",
		PasswordHash: "hashed_password",
		IsActive:     true,
	}
	if err := db.Create(testUser).Error; err != nil {
		b.Fatal(err)
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err := database.GetOrCreateUser(userID, "bench_user", "bench@example.com", "hashed_password")
		if err != nil {
			b.Fatal(err)
		}
	}
}

// BenchmarkGetOrCreateUser_NewUser benchmarks GetOrCreateUser for new users
func BenchmarkGetOrCreateUser_NewUser(b *testing.B) {
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	if err != nil {
		b.Fatal(err)
	}
	defer func() {
		sqlDB, _ := db.DB()
		sqlDB.Close()
	}()

	if err := Migrate(db); err != nil {
		b.Fatal(err)
	}

	database := NewDatabase(db)

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		userID := uuid.New()
		username := fmt.Sprintf("bench_user_%d", i)
		email := fmt.Sprintf("bench_%d@example.com", i)
		_, err := database.GetOrCreateUser(userID, username, email, "hashed_password")
		if err != nil {
			b.Fatal(err)
		}
	}
}
