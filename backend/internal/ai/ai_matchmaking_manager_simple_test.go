package ai

import (
	"testing"

	"septica-backend/internal/database"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func TestAIMatchmakingManagerFixed_Simple(t *testing.T) {
	// Setup in-memory database
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	require.NoError(t, err)

	// Auto-migrate required models
	err = db.AutoMigrate(&database.User{}, &database.Player{})
	require.NoError(t, err)

	// Create database service
	dbService := database.NewDatabase(db)

	// Test AI user creation
	testAIID := uuid.New()
	testUsername := "TestAI"
	testEmail := "test@ai.septica.game"
	testPassword := "test_password"

	// Create user using GetOrCreateUser
	user, err := dbService.GetOrCreateUser(testAIID, testUsername, testEmail, testPassword)
	assert.NoError(t, err)
	assert.NotNil(t, user)
	assert.Equal(t, testUsername, user.Username)
	assert.Equal(t, testEmail, user.Email)

	// Try to create same user again (should return existing user)
	user2, err := dbService.GetOrCreateUser(testAIID, testUsername, testEmail, testPassword)
	assert.NoError(t, err)
	assert.Equal(t, user.ID, user2.ID)
	assert.Equal(t, user.Username, user2.Username)

	// Test player creation
	var existingPlayer database.Player
	err = db.Where("user_id = ?", user.ID).First(&existingPlayer).Error
	assert.Equal(t, gorm.ErrRecordNotFound, err) // Should not exist yet

	// Create player record
	player := &database.Player{
		BaseModel: database.BaseModel{ID: uuid.New()},
		UserID:    user.ID,
		Username:  testUsername,
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
	assert.NotEqual(t, uuid.Nil, player.ID)

	// Verify player was created and linked correctly
	var createdPlayer database.Player
	err = db.Where("user_id = ?", user.ID).First(&createdPlayer).Error
	assert.NoError(t, err)
	assert.Equal(t, player.ID, createdPlayer.ID)
	assert.Equal(t, user.ID, createdPlayer.UserID)
	assert.Equal(t, testUsername, createdPlayer.Username)
	assert.Equal(t, 1200, createdPlayer.Rating)
}

func TestAIMatchmakingManagerFixed_Concurrency(t *testing.T) {
	// Setup in-memory database
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	require.NoError(t, err)

	// Auto-migrate required models
	err = db.AutoMigrate(&database.User{}, &database.Player{})
	require.NoError(t, err)

	// Create database service
	dbService := database.NewDatabase(db)

	// Test concurrent AI user creation
	testAIID := uuid.New()
	testUsername := "ConcurrentAI"
	testEmail := "concurrent@ai.septica.game"
	testPassword := "test_password"

	// Create multiple users concurrently
	concurrency := 10
	results := make(chan error, concurrency)

	for i := 0; i < concurrency; i++ {
		go func() {
			_, err := dbService.GetOrCreateUser(testAIID, testUsername, testEmail, testPassword)
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
	db.Model(&database.User{}).Count(&userCount)
	assert.Equal(t, int64(1), userCount)

	// Verify the user exists and has correct data
	var user database.User
	err = db.Where("id = ?", testAIID).First(&user).Error
	assert.NoError(t, err)
	assert.Equal(t, testUsername, user.Username)
	assert.Equal(t, testEmail, user.Email)
}

func TestAIMatchmakingManagerFixed_ErrorHandling(t *testing.T) {
	// Setup in-memory database
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	require.NoError(t, err)

	// Auto-migrate required models
	err = db.AutoMigrate(&database.User{}, &database.Player{})
	require.NoError(t, err)

	// Create database service
	dbService := database.NewDatabase(db)

	// Test with invalid email (should still work)
	testAIID := uuid.New()
	testUsername := "ErrorAI"
	testEmail := "" // Empty email should be allowed for AI
	testPassword := "test_password"

	user, err := dbService.GetOrCreateUser(testAIID, testUsername, testEmail, testPassword)
	assert.NoError(t, err)
	assert.NotNil(t, user)

	// Test with nil ID (should generate new UUID)
	user, err = dbService.GetOrCreateUser(uuid.Nil, "NilIDAI", "nil@ai.septica.game", "test_password")
	assert.NoError(t, err)
	assert.NotNil(t, user)
	assert.NotEqual(t, uuid.Nil, user.ID)
}

func TestAIMatchmakingManagerFixed_PlayerLinking(t *testing.T) {
	// Setup in-memory database
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	require.NoError(t, err)

	// Auto-migrate required models
	err = db.AutoMigrate(&database.User{}, &database.Player{})
	require.NoError(t, err)

	// Create database service
	dbService := database.NewDatabase(db)

	// Create AI user first
	testAIID := uuid.New()
	user, err := dbService.GetOrCreateUser(testAIID, "LinkAI", "link@ai.septica.game", "test_password")
	require.NoError(t, err)

	// Create player record linked to the user
	player := &database.Player{
		BaseModel: database.BaseModel{ID: uuid.New()},
		UserID:    user.ID, // Link to the user we just created
		Username:  "LinkAI",
		Rating:    1350,
		Level:     2,
		XP:        250,
		Coins:     1500,
		Gems:      5,
		SelectedCardBack:   "premium",
		SelectedTableTheme: "wood",
		SelectedAvatar:     "warrior",
	}

	err = db.Create(player).Error
	assert.NoError(t, err)

	// Verify the linking worked correctly
	var createdPlayer database.Player
	err = db.Preload("User").Where("id = ?", player.ID).First(&createdPlayer).Error
	assert.NoError(t, err)
	assert.Equal(t, user.ID, createdPlayer.UserID)
	assert.Equal(t, user.Username, createdPlayer.User.Username)
	assert.Equal(t, "LinkAI", createdPlayer.Username)
	assert.Equal(t, 1350, createdPlayer.Rating)
	assert.Equal(t, 2, createdPlayer.Level)
	assert.Equal(t, 250, createdPlayer.XP)
}

// Benchmark test for GetOrCreateUser performance
func BenchmarkGetOrCreateUser(b *testing.B) {
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	if err != nil {
		b.Fatal(err)
	}

	err = db.AutoMigrate(&database.User{}, &database.Player{})
	if err != nil {
		b.Fatal(err)
	}

	dbService := database.NewDatabase(db)

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		testID := uuid.New()
		_, err := dbService.GetOrCreateUser(testID, "BenchAI", "bench@ai.septica.game", "test_password")
		if err != nil {
			b.Fatal(err)
		}
	}
}

// Benchmark test for concurrent GetOrCreateUser
func BenchmarkGetOrCreateUser_Concurrent(b *testing.B) {
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	if err != nil {
		b.Fatal(err)
	}

	err = db.AutoMigrate(&database.User{}, &database.Player{})
	if err != nil {
		b.Fatal(err)
	}

	dbService := database.NewDatabase(db)

	b.ResetTimer()
	b.RunParallel(func(pb *testing.PB) {
		for pb.Next() {
			testID := uuid.New()
			_, err := dbService.GetOrCreateUser(testID, "ConcurrentBenchAI", "concurrent@ai.septica.game", "test_password")
			if err != nil {
				b.Fatal(err)
			}
		}
	})
}