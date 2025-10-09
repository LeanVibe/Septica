package handlers

import (
	"net/http"
	"time"

	"septica-backend/internal/ai"
	"septica-backend/internal/matchmaking"
	"septica-backend/internal/websocket"
	"septica-backend/pkg/logger"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// HealthHandler handles health check endpoints for monitoring and observability
type HealthHandler struct {
	db                 *gorm.DB
	hub                *websocket.Hub
	matchmakingService *matchmaking.MatchmakingService
	aiManager          *ai.AIMatchmakingManager
	logger             *logger.Logger
	serverStartTime    time.Time
}

// NewHealthHandler creates a new health handler instance
func NewHealthHandler(
	db *gorm.DB,
	hub *websocket.Hub,
	matchmakingService *matchmaking.MatchmakingService,
	aiManager *ai.AIMatchmakingManager,
	logger *logger.Logger,
) *HealthHandler {
	return &HealthHandler{
		db:                 db,
		hub:                hub,
		matchmakingService: matchmakingService,
		aiManager:          aiManager,
		logger:             logger,
		serverStartTime:    time.Now(),
	}
}

// Basic handles the basic liveness probe endpoint
// GET /health
func (h *HealthHandler) Basic(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status":    "ok",
		"timestamp": time.Now().Unix(),
		"service":   "septica-backend",
	})
}

// Readiness handles the readiness probe endpoint
// GET /health/ready
// Returns 503 if any critical service is unavailable
func (h *HealthHandler) Readiness(c *gin.Context) {
	healthy := true
	components := make(map[string]interface{})

	// Check database connectivity
	dbStatus := "healthy"
	dbLatency := int64(0)
	if h.db == nil {
		dbStatus = "unhealthy"
		healthy = false
	} else {
		sqlDB, err := h.db.DB()
		if err != nil {
			dbStatus = "unhealthy"
			healthy = false
		} else {
			start := time.Now()
			if err := sqlDB.Ping(); err != nil {
				dbStatus = "unhealthy"
				healthy = false
			} else {
				dbLatency = time.Since(start).Milliseconds()
			}
		}
	}
	components["database"] = gin.H{
		"status":     dbStatus,
		"latency_ms": dbLatency,
	}

	// Check matchmaking service
	mmStatus := "healthy"
	if h.matchmakingService == nil {
		mmStatus = "not_initialized"
		healthy = false
	}
	components["matchmaking"] = gin.H{
		"status": mmStatus,
	}

	// Check AI matchmaking manager
	aiStatus := "healthy"
	if h.aiManager == nil {
		aiStatus = "not_initialized"
		healthy = false
	}
	components["ai_matchmaking"] = gin.H{
		"status": aiStatus,
	}

	// Check WebSocket hub
	wsStatus := "healthy"
	if h.hub == nil {
		wsStatus = "not_initialized"
		healthy = false
	}
	components["websocket"] = gin.H{
		"status": wsStatus,
	}

	statusCode := http.StatusOK
	overallStatus := "healthy"
	if !healthy {
		statusCode = http.StatusServiceUnavailable
		overallStatus = "unhealthy"
	}

	c.JSON(statusCode, gin.H{
		"status":     overallStatus,
		"timestamp":  time.Now().UTC().Format(time.RFC3339),
		"components": components,
	})
}

// Detailed handles the comprehensive system status endpoint
// GET /health/detailed
func (h *HealthHandler) Detailed(c *gin.Context) {
	components := make(map[string]interface{})

	// Database health
	dbStatus := "up"
	dbLatency := int64(0)
	if h.db == nil {
		dbStatus = "down"
	} else {
		sqlDB, err := h.db.DB()
		if err != nil {
			dbStatus = "down"
		} else {
			start := time.Now()
			if err := sqlDB.Ping(); err != nil {
				dbStatus = "down"
			} else {
				dbLatency = time.Since(start).Milliseconds()
			}
		}
	}
	components["database"] = gin.H{
		"status":     dbStatus,
		"latency_ms": dbLatency,
	}

	// AI matchmaking manager health
	activeAI := 0
	maxConcurrent := 0
	aiEnabled := false
	if h.aiManager != nil {
		activeAI = h.aiManager.GetActiveAICount()
		config := h.aiManager.GetConfig()
		if config != nil {
			maxConcurrent = config.MaxConcurrentAI
			aiEnabled = config.Enabled
		}
	}
	components["ai_matchmaking"] = gin.H{
		"status":         "up",
		"active_ai":      activeAI,
		"max_concurrent": maxConcurrent,
		"enabled":        aiEnabled,
	}

	// Matchmaking service health
	queueStats := make(map[string]interface{})
	totalPlayers := 0
	if h.matchmakingService != nil {
		stats := h.matchmakingService.GetQueueStats()
		if stats != nil {
			queueStats = stats
			if total, ok := stats["total_players"].(int); ok {
				totalPlayers = total
			}
		}
	}
	components["matchmaking"] = gin.H{
		"status":        "up",
		"total_players": totalPlayers,
		"queues":        queueStats,
	}

	// WebSocket hub health
	connections := 0
	activeGames := 0
	if h.hub != nil {
		connections = h.hub.GetConnectionCount()
		activeGames = h.hub.GetGameCount()
	}
	components["websocket"] = gin.H{
		"status":      "up",
		"connections": connections,
		"games":       activeGames,
	}

	c.JSON(http.StatusOK, gin.H{
		"status":     "healthy",
		"timestamp":  time.Now().UTC().Format(time.RFC3339),
		"version":    "1.0.0",
		"uptime":     time.Since(h.serverStartTime).Seconds(),
		"components": components,
	})
}

// AIHealth handles the AI matchmaking manager status endpoint
// GET /health/ai
func (h *HealthHandler) AIHealth(c *gin.Context) {
	if h.aiManager == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{
			"status":  "unavailable",
			"message": "AI matchmaking manager not initialized",
		})
		return
	}

	config := h.aiManager.GetConfig()
	activeAI := h.aiManager.GetActiveAICount()

	response := gin.H{
		"status":             "healthy",
		"timestamp":          time.Now().UTC().Format(time.RFC3339),
		"active_ai_count":    activeAI,
		"max_concurrent_ai":  config.MaxConcurrentAI,
		"enabled":            config.Enabled,
		"activation_timeout": config.ActivationTimeout.Seconds(),
		"capacity_used":      float64(activeAI) / float64(config.MaxConcurrentAI) * 100,
	}

	// Add difficulty distribution if available
	if config.DifficultyDistribution != nil {
		response["difficulty_distribution"] = config.DifficultyDistribution
	}

	c.JSON(http.StatusOK, response)
}

// MatchmakingHealth handles the matchmaking queue health endpoint
// GET /health/matchmaking
func (h *HealthHandler) MatchmakingHealth(c *gin.Context) {
	if h.matchmakingService == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{
			"status":  "unavailable",
			"message": "Matchmaking service not initialized",
		})
		return
	}

	// Get queue statistics
	stats := h.matchmakingService.GetQueueStats()

	// Get cleanup statistics
	cleanupStats := h.matchmakingService.GetCleanupStats()

	response := gin.H{
		"status":        "healthy",
		"timestamp":     time.Now().UTC().Format(time.RFC3339),
		"queue_stats":   stats,
		"cleanup_stats": cleanupStats,
	}

	c.JSON(http.StatusOK, response)
}

// WebSocketHealth handles the WebSocket hub health endpoint
// GET /health/websocket
func (h *HealthHandler) WebSocketHealth(c *gin.Context) {
	if h.hub == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{
			"status":  "unavailable",
			"message": "WebSocket hub not initialized",
		})
		return
	}

	connections := h.hub.GetConnectionCount()
	games := h.hub.GetGameCount()

	response := gin.H{
		"status":       "healthy",
		"timestamp":    time.Now().UTC().Format(time.RFC3339),
		"connections":  connections,
		"active_games": games,
	}

	c.JSON(http.StatusOK, response)
}
