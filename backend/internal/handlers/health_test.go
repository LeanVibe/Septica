package handlers

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"septica-backend/internal/ai"
	"septica-backend/internal/database"
	"septica-backend/internal/game"
	"septica-backend/internal/matchmaking"
	"septica-backend/internal/websocket"
	"septica-backend/pkg/logger"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func setupTestHealthHandler(t *testing.T) (*HealthHandler, *gorm.DB) {
	// Create in-memory SQLite database
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	assert.NoError(t, err)

	// Run migrations
	err = database.Migrate(db)
	assert.NoError(t, err)

	// Create logger
	log := logger.New("debug")

	// Create game engines
	gameEngine := game.NewEngine()
	authenticEngine := game.NewAuthenticEngine()

	// Create WebSocket hub
	hub := websocket.NewHub(gameEngine, authenticEngine, db, log)

	// Create matchmaking service
	mmService := matchmaking.NewMatchmakingService(hub, gameEngine, authenticEngine, db, log, nil)

	// Create AI matchmaking manager
	aiManager := ai.NewAIMatchmakingManager(hub, db, log)

	// Create health handler
	handler := NewHealthHandler(db, hub, mmService, aiManager, log)

	return handler, db
}

func TestBasicHealthEndpoint(t *testing.T) {
	handler, _ := setupTestHealthHandler(t)

	// Setup Gin router
	gin.SetMode(gin.TestMode)
	router := gin.New()
	router.GET("/health", handler.Basic)

	// Create test request
	req, _ := http.NewRequest("GET", "/health", nil)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	// Verify response
	assert.Equal(t, http.StatusOK, w.Code)

	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)
	assert.Equal(t, "ok", response["status"])
	assert.Equal(t, "septica-backend", response["service"])
	assert.NotNil(t, response["timestamp"])
}

func TestReadinessEndpoint(t *testing.T) {
	handler, _ := setupTestHealthHandler(t)

	// Setup Gin router
	gin.SetMode(gin.TestMode)
	router := gin.New()
	router.GET("/health/ready", handler.Readiness)

	// Create test request
	req, _ := http.NewRequest("GET", "/health/ready", nil)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	// Verify response
	assert.Equal(t, http.StatusOK, w.Code)

	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)
	assert.Equal(t, "healthy", response["status"])
	assert.NotNil(t, response["components"])

	components := response["components"].(map[string]interface{})
	assert.NotNil(t, components["database"])
	assert.NotNil(t, components["matchmaking"])
	assert.NotNil(t, components["ai_matchmaking"])
	assert.NotNil(t, components["websocket"])
}

func TestDetailedHealthEndpoint(t *testing.T) {
	handler, _ := setupTestHealthHandler(t)

	// Setup Gin router
	gin.SetMode(gin.TestMode)
	router := gin.New()
	router.GET("/health/detailed", handler.Detailed)

	// Create test request
	req, _ := http.NewRequest("GET", "/health/detailed", nil)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	// Verify response
	assert.Equal(t, http.StatusOK, w.Code)

	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)
	assert.Equal(t, "healthy", response["status"])
	assert.Equal(t, "1.0.0", response["version"])
	assert.NotNil(t, response["uptime"])
	assert.NotNil(t, response["components"])

	components := response["components"].(map[string]interface{})

	// Check database component
	db := components["database"].(map[string]interface{})
	assert.Equal(t, "up", db["status"])
	assert.NotNil(t, db["latency_ms"])

	// Check AI matchmaking component
	aiMM := components["ai_matchmaking"].(map[string]interface{})
	assert.Equal(t, "up", aiMM["status"])
	assert.NotNil(t, aiMM["active_ai"])
	assert.NotNil(t, aiMM["max_concurrent"])

	// Check matchmaking component
	mm := components["matchmaking"].(map[string]interface{})
	assert.Equal(t, "up", mm["status"])

	// Check WebSocket component
	ws := components["websocket"].(map[string]interface{})
	assert.Equal(t, "up", ws["status"])
	assert.NotNil(t, ws["connections"])
	assert.NotNil(t, ws["games"])
}

func TestAIHealthEndpoint(t *testing.T) {
	handler, _ := setupTestHealthHandler(t)

	// Setup Gin router
	gin.SetMode(gin.TestMode)
	router := gin.New()
	router.GET("/health/ai", handler.AIHealth)

	// Create test request
	req, _ := http.NewRequest("GET", "/health/ai", nil)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	// Verify response
	assert.Equal(t, http.StatusOK, w.Code)

	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)
	assert.Equal(t, "healthy", response["status"])
	assert.NotNil(t, response["active_ai_count"])
	assert.NotNil(t, response["max_concurrent_ai"])
	assert.NotNil(t, response["enabled"])
	assert.NotNil(t, response["activation_timeout"])
	assert.NotNil(t, response["capacity_used"])
}

func TestMatchmakingHealthEndpoint(t *testing.T) {
	handler, _ := setupTestHealthHandler(t)

	// Setup Gin router
	gin.SetMode(gin.TestMode)
	router := gin.New()
	router.GET("/health/matchmaking", handler.MatchmakingHealth)

	// Create test request
	req, _ := http.NewRequest("GET", "/health/matchmaking", nil)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	// Verify response
	assert.Equal(t, http.StatusOK, w.Code)

	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)
	assert.Equal(t, "healthy", response["status"])
	assert.NotNil(t, response["queue_stats"])
	assert.NotNil(t, response["cleanup_stats"])
}

func TestWebSocketHealthEndpoint(t *testing.T) {
	handler, _ := setupTestHealthHandler(t)

	// Setup Gin router
	gin.SetMode(gin.TestMode)
	router := gin.New()
	router.GET("/health/websocket", handler.WebSocketHealth)

	// Create test request
	req, _ := http.NewRequest("GET", "/health/websocket", nil)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	// Verify response
	assert.Equal(t, http.StatusOK, w.Code)

	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)
	assert.Equal(t, "healthy", response["status"])
	assert.NotNil(t, response["connections"])
	assert.NotNil(t, response["active_games"])
}

func TestReadinessUnhealthy(t *testing.T) {
	// Create handler with nil database to simulate unhealthy state
	handler := &HealthHandler{
		db:                 nil,
		hub:                nil,
		matchmakingService: nil,
		aiManager:          nil,
		logger:             logger.New("debug"),
		serverStartTime:    time.Now(),
	}

	// Setup Gin router
	gin.SetMode(gin.TestMode)
	router := gin.New()
	router.GET("/health/ready", handler.Readiness)

	// Create test request
	req, _ := http.NewRequest("GET", "/health/ready", nil)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	// Verify response
	assert.Equal(t, http.StatusServiceUnavailable, w.Code)

	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)
	assert.Equal(t, "unhealthy", response["status"])
}
