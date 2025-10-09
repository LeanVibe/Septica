package handlers

import (
	"net/http"

	"septica-backend/internal/matchmaking"
	"septica-backend/pkg/logger"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// MatchmakingHandler handles matchmaking-related HTTP endpoints
type MatchmakingHandler struct {
	matchmakingService *matchmaking.MatchmakingService
	logger             *logger.Logger
}

// NewMatchmakingHandler creates a new matchmaking handler
func NewMatchmakingHandler(service *matchmaking.MatchmakingService, logger *logger.Logger) *MatchmakingHandler {
	return &MatchmakingHandler{
		matchmakingService: service,
		logger:             logger,
	}
}

// JoinMatchmaking handles POST /api/v1/matchmaking/join
func (h *MatchmakingHandler) JoinMatchmaking(c *gin.Context) {
	var request struct {
		PlayerID  string `json:"player_id" binding:"required"`
		QueueType string `json:"queue_type" binding:"required"`
		GameMode  string `json:"game_mode"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid_request",
			"message": "Invalid request format",
			"details": err.Error(),
		})
		return
	}

	playerID, err := uuid.Parse(request.PlayerID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid_player_id",
			"message": "Player ID must be a valid UUID",
		})
		return
	}

	if request.GameMode == "" {
		request.GameMode = "septica"
	}

	// Validate queue type
	validQueueTypes := map[string]bool{
		"ranked":     true,
		"casual":     true,
		"tournament": true,
	}
	if !validQueueTypes[request.QueueType] {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid_queue_type",
			"message": "Queue type must be 'ranked', 'casual', or 'tournament'",
		})
		return
	}

	// Join matchmaking queue
	if err := h.matchmakingService.JoinQueue(playerID, request.QueueType, request.GameMode); err != nil {
		status := http.StatusInternalServerError
		errorType := "join_failed"

		switch err {
		case matchmaking.ErrPlayerAlreadyInQueue:
			status = http.StatusConflict
			errorType = "already_in_queue"
		case matchmaking.ErrPlayerNotFound:
			status = http.StatusNotFound
			errorType = "player_not_found"
		case matchmaking.ErrInvalidQueueType:
			status = http.StatusBadRequest
			errorType = "invalid_queue_type"
		}

		c.JSON(status, gin.H{
			"error":   errorType,
			"message": err.Error(),
		})
		return
	}

	h.logger.Info("Player joined matchmaking via API",
		"player_id", playerID,
		"queue_type", request.QueueType,
		"game_mode", request.GameMode)

	c.JSON(http.StatusOK, gin.H{
		"success":    true,
		"message":    "Successfully joined matchmaking queue",
		"player_id":  playerID,
		"queue_type": request.QueueType,
		"game_mode":  request.GameMode,
	})
}

// LeaveMatchmaking handles DELETE /api/v1/matchmaking/leave
func (h *MatchmakingHandler) LeaveMatchmaking(c *gin.Context) {
	var request struct {
		PlayerID string `json:"player_id" binding:"required"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid_request",
			"message": "Invalid request format",
			"details": err.Error(),
		})
		return
	}

	playerID, err := uuid.Parse(request.PlayerID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid_player_id",
			"message": "Player ID must be a valid UUID",
		})
		return
	}

	// Leave matchmaking queue
	if err := h.matchmakingService.LeaveQueue(playerID); err != nil {
		status := http.StatusInternalServerError
		errorType := "leave_failed"

		switch err {
		case matchmaking.ErrPlayerNotInQueue:
			status = http.StatusNotFound
			errorType = "not_in_queue"
		}

		c.JSON(status, gin.H{
			"error":   errorType,
			"message": err.Error(),
		})
		return
	}

	h.logger.Info("Player left matchmaking via API", "player_id", playerID)

	c.JSON(http.StatusOK, gin.H{
		"success":   true,
		"message":   "Successfully left matchmaking queue",
		"player_id": playerID,
	})
}

// GetMatchmakingStatus handles GET /api/v1/matchmaking/status/:player_id
func (h *MatchmakingHandler) GetMatchmakingStatus(c *gin.Context) {
	playerIDStr := c.Param("player_id")
	playerID, err := uuid.Parse(playerIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid_player_id",
			"message": "Player ID must be a valid UUID",
		})
		return
	}

	// Get queue status
	status, err := h.matchmakingService.GetQueueStatus(playerID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "status_retrieval_failed",
			"message": err.Error(),
		})
		return
	}

	status["player_id"] = playerID
	c.JSON(http.StatusOK, status)
}

// GetMatchmakingStats handles GET /api/v1/matchmaking/stats
func (h *MatchmakingHandler) GetMatchmakingStats(c *gin.Context) {
	stats := h.matchmakingService.GetQueueStats()
	c.JSON(http.StatusOK, stats)
}

// RegisterMatchmakingRoutes registers all matchmaking-related routes
func RegisterMatchmakingRoutes(router *gin.RouterGroup, service *matchmaking.MatchmakingService, logger *logger.Logger) {
	handler := NewMatchmakingHandler(service, logger)

	// Matchmaking endpoints
	router.POST("/matchmaking/join", handler.JoinMatchmaking)
	router.DELETE("/matchmaking/leave", handler.LeaveMatchmaking)
	router.GET("/matchmaking/status/:player_id", handler.GetMatchmakingStatus)
	router.GET("/matchmaking/stats", handler.GetMatchmakingStats)
}
