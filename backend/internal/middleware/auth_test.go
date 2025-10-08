package middleware

import (
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"septica-backend/internal/auth"
	"septica-backend/internal/database"
	"septica-backend/pkg/logger"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func setupTestAuthService(t *testing.T) (*auth.Service, *gorm.DB) {
	// Use in-memory SQLite for testing
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	assert.NoError(t, err)

	// Run migrations
	err = db.AutoMigrate(&database.User{}, &database.Player{})
	assert.NoError(t, err)

	authService := auth.NewService("test-secret-key", 24*time.Hour, db)
	return authService, db
}

func TestAuthMiddleware_ValidToken(t *testing.T) {
	gin.SetMode(gin.TestMode)
	authService, db := setupTestAuthService(t)
	defer func() {
		sqlDB, _ := db.DB()
		sqlDB.Close()
	}()

	log := logger.New("debug")

	// Create a test user
	user, err := authService.Register("testuser", "test@example.com", "password123")
	assert.NoError(t, err)

	// Generate token
	token, err := authService.GenerateToken(user.ID, user.Username)
	assert.NoError(t, err)

	// Create test router
	router := gin.New()
	router.Use(AuthMiddleware(authService, log))
	router.GET("/protected", func(c *gin.Context) {
		userID, exists := GetUserID(c)
		assert.True(t, exists)
		assert.Equal(t, user.ID, userID)
		c.JSON(http.StatusOK, gin.H{"message": "success"})
	})

	// Make request with valid token
	req := httptest.NewRequest("GET", "/protected", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
}

func TestAuthMiddleware_MissingToken(t *testing.T) {
	gin.SetMode(gin.TestMode)
	authService, db := setupTestAuthService(t)
	defer func() {
		sqlDB, _ := db.DB()
		sqlDB.Close()
	}()

	log := logger.New("debug")

	// Create test router
	router := gin.New()
	router.Use(AuthMiddleware(authService, log))
	router.GET("/protected", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"message": "success"})
	})

	// Make request without token
	req := httptest.NewRequest("GET", "/protected", nil)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusUnauthorized, w.Code)
	assert.Contains(t, w.Body.String(), "missing authorization header")
}

func TestAuthMiddleware_InvalidTokenFormat(t *testing.T) {
	gin.SetMode(gin.TestMode)
	authService, db := setupTestAuthService(t)
	defer func() {
		sqlDB, _ := db.DB()
		sqlDB.Close()
	}()

	log := logger.New("debug")

	// Create test router
	router := gin.New()
	router.Use(AuthMiddleware(authService, log))
	router.GET("/protected", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"message": "success"})
	})

	// Make request with invalid format (missing "Bearer " prefix)
	req := httptest.NewRequest("GET", "/protected", nil)
	req.Header.Set("Authorization", "invalid-token")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusUnauthorized, w.Code)
	assert.Contains(t, w.Body.String(), "invalid authorization format")
}

func TestAuthMiddleware_ExpiredToken(t *testing.T) {
	gin.SetMode(gin.TestMode)

	// Create auth service with very short expiry
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	assert.NoError(t, err)
	defer func() {
		sqlDB, _ := db.DB()
		sqlDB.Close()
	}()

	err = db.AutoMigrate(&database.User{}, &database.Player{})
	assert.NoError(t, err)

	authService := auth.NewService("test-secret-key", -1*time.Hour, db) // Already expired
	log := logger.New("debug")

	// Create a test user
	user, err := authService.Register("testuser", "test@example.com", "password123")
	assert.NoError(t, err)

	// Generate expired token
	token, err := authService.GenerateToken(user.ID, user.Username)
	assert.NoError(t, err)

	// Create test router
	router := gin.New()
	router.Use(AuthMiddleware(authService, log))
	router.GET("/protected", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"message": "success"})
	})

	// Make request with expired token
	req := httptest.NewRequest("GET", "/protected", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusUnauthorized, w.Code)
	assert.Contains(t, w.Body.String(), "invalid or expired token")
}

func TestOptionalAuthMiddleware_WithValidToken(t *testing.T) {
	gin.SetMode(gin.TestMode)
	authService, db := setupTestAuthService(t)
	defer func() {
		sqlDB, _ := db.DB()
		sqlDB.Close()
	}()

	log := logger.New("debug")

	// Create a test user
	user, err := authService.Register("testuser", "test@example.com", "password123")
	assert.NoError(t, err)

	// Generate token
	token, err := authService.GenerateToken(user.ID, user.Username)
	assert.NoError(t, err)

	// Create test router
	router := gin.New()
	router.Use(OptionalAuthMiddleware(authService, log))
	router.GET("/public", func(c *gin.Context) {
		userID, exists := GetUserID(c)
		if exists {
			assert.Equal(t, user.ID, userID)
			c.JSON(http.StatusOK, gin.H{"authenticated": true, "user_id": userID})
		} else {
			c.JSON(http.StatusOK, gin.H{"authenticated": false})
		}
	})

	// Make request with valid token
	req := httptest.NewRequest("GET", "/public", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
	assert.Contains(t, w.Body.String(), "\"authenticated\":true")
}

func TestOptionalAuthMiddleware_WithoutToken(t *testing.T) {
	gin.SetMode(gin.TestMode)
	authService, db := setupTestAuthService(t)
	defer func() {
		sqlDB, _ := db.DB()
		sqlDB.Close()
	}()

	log := logger.New("debug")

	// Create test router
	router := gin.New()
	router.Use(OptionalAuthMiddleware(authService, log))
	router.GET("/public", func(c *gin.Context) {
		_, exists := GetUserID(c)
		c.JSON(http.StatusOK, gin.H{"authenticated": exists})
	})

	// Make request without token - should still succeed
	req := httptest.NewRequest("GET", "/public", nil)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
	assert.Contains(t, w.Body.String(), "\"authenticated\":false")
}

func TestGetUserID(t *testing.T) {
	gin.SetMode(gin.TestMode)

	testUserID := uuid.New()

	// Create test context with user_id set
	c, _ := gin.CreateTestContext(httptest.NewRecorder())
	c.Set("user_id", testUserID)

	userID, exists := GetUserID(c)
	assert.True(t, exists)
	assert.Equal(t, testUserID, userID)

	// Test with missing user_id
	c2, _ := gin.CreateTestContext(httptest.NewRecorder())
	userID2, exists2 := GetUserID(c2)
	assert.False(t, exists2)
	assert.Equal(t, uuid.Nil, userID2)
}

func TestGetUsername(t *testing.T) {
	gin.SetMode(gin.TestMode)

	testUsername := "testuser"

	// Create test context with username set
	c, _ := gin.CreateTestContext(httptest.NewRecorder())
	c.Set("username", testUsername)

	username, exists := GetUsername(c)
	assert.True(t, exists)
	assert.Equal(t, testUsername, username)

	// Test with missing username
	c2, _ := gin.CreateTestContext(httptest.NewRecorder())
	username2, exists2 := GetUsername(c2)
	assert.False(t, exists2)
	assert.Equal(t, "", username2)
}

func TestRequireAuth(t *testing.T) {
	gin.SetMode(gin.TestMode)
	log := logger.New("debug")

	testUserID := uuid.New()

	// Test with authenticated user
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = httptest.NewRequest("GET", "/test", nil)
	c.Set("user_id", testUserID)
	result := RequireAuth(c, log)
	assert.True(t, result)
	assert.False(t, c.IsAborted()) // Should not abort

	// Test without authenticated user
	w2 := httptest.NewRecorder()
	c2, _ := gin.CreateTestContext(w2)
	c2.Request = httptest.NewRequest("GET", "/test", nil)
	result2 := RequireAuth(c2, log)
	assert.False(t, result2)
	assert.True(t, c2.IsAborted())
	assert.Contains(t, w2.Body.String(), "authentication required")
}
