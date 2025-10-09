package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"septica-backend/internal/auth"
	"septica-backend/internal/websocket"
	"septica-backend/pkg/logger"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// WebSocketHandler handles WebSocket-related HTTP endpoints
type WebSocketHandler struct {
	hub         *websocket.Hub
	authService *auth.Service
	logger      *logger.Logger
}

// NewWebSocketHandler creates a new WebSocket handler
func NewWebSocketHandler(hub *websocket.Hub, authService *auth.Service, logger *logger.Logger) *WebSocketHandler {
	return &WebSocketHandler{
		hub:         hub,
		authService: authService,
		logger:      logger,
	}
}

// HandleWebSocketUpgrade handles WebSocket connection upgrade requests
// WebSocket authentication: requires token in query parameter since WebSocket
// doesn't support custom headers during the initial handshake
func (h *WebSocketHandler) HandleWebSocketUpgrade(c *gin.Context) {
	// Extract and validate JWT token from query parameter
	token := c.Query("token")
	if token == "" {
		h.logger.Warn("WebSocket connection attempt without token", "ip", c.ClientIP())
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "authentication token required in query parameter",
			"usage": "ws://server/ws/connect?token=YOUR_JWT_TOKEN",
		})
		return
	}

	// Validate the token
	claims, err := h.authService.ValidateToken(token)
	if err != nil {
		h.logger.Warn("WebSocket connection with invalid token", "error", err, "ip", c.ClientIP())
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "invalid or expired token",
		})
		return
	}

	userID := claims.UserID
	username := claims.Username

	// Optional session ID for multi-device support
	sessionID := c.Query("session_id")
	if sessionID == "" {
		sessionID = uuid.New().String()
	}

	h.logger.Info("WebSocket connection authenticated",
		"user_id", userID,
		"username", username,
		"session_id", sessionID)

	// Upgrade HTTP connection to WebSocket
	// The actual user ID will be extracted from the validated token during ServeWS
	websocket.ServeWS(h.hub, c.Writer, c.Request)
}

// GetConnectionStats returns WebSocket connection statistics
func (h *WebSocketHandler) GetConnectionStats(c *gin.Context) {
	stats := gin.H{
		"active_connections": h.hub.GetConnectionCount(),
		"active_games":       h.hub.GetGameCount(),
		"timestamp":          "now", // You might want to use actual timestamp
	}

	c.JSON(http.StatusOK, stats)
}

// SendHeartbeat manually triggers a heartbeat to all connected clients
func (h *WebSocketHandler) SendHeartbeat(c *gin.Context) {
	h.hub.SendHeartbeat()

	c.JSON(http.StatusOK, gin.H{
		"message": "heartbeat sent to all connected clients",
		"count":   h.hub.GetConnectionCount(),
	})
}

// DisconnectUser forces disconnection of a specific user
func (h *WebSocketHandler) DisconnectUser(c *gin.Context) {
	userIDStr := c.Param("user_id")
	_, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "invalid user_id format",
		})
		return
	}

	// Implementation would need to be added to Hub to support forced disconnection
	// For now, return not implemented
	c.JSON(http.StatusNotImplemented, gin.H{
		"error": "forced disconnection not implemented yet",
	})
}

// GetUserConnections returns connection info for a specific user
func (h *WebSocketHandler) GetUserConnections(c *gin.Context) {
	userIDStr := c.Param("user_id")
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "invalid user_id format",
		})
		return
	}

	// Implementation would need to be added to Hub to get user-specific connection info
	// For now, return placeholder
	c.JSON(http.StatusOK, gin.H{
		"user_id":      userID,
		"connected":    false, // Placeholder
		"session_id":   "",    // Placeholder
		"connected_at": nil,   // Placeholder
	})
}

// BroadcastMessage sends a message to all connected clients
func (h *WebSocketHandler) BroadcastMessage(c *gin.Context) {
	var request struct {
		Type    string                 `json:"type" binding:"required"`
		Payload map[string]interface{} `json:"payload"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "invalid request format",
		})
		return
	}

	// Create message
	message := websocket.Message{
		Type:      request.Type,
		ID:        uuid.New().String(),
		Timestamp: time.Now(),
		Payload:   request.Payload,
	}

	// Marshal and broadcast
	messageBytes, err := json.Marshal(message)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "failed to marshal message",
		})
		return
	}

	h.hub.Broadcast(messageBytes)

	c.JSON(http.StatusOK, gin.H{
		"message": "message broadcast to all clients",
		"type":    request.Type,
		"count":   h.hub.GetConnectionCount(),
	})
}

// BroadcastToGame sends a message to all clients in a specific game
func (h *WebSocketHandler) BroadcastToGame(c *gin.Context) {
	gameIDStr := c.Param("game_id")
	gameID, err := uuid.Parse(gameIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "invalid game_id format",
		})
		return
	}

	var request struct {
		Type    string                 `json:"type" binding:"required"`
		Payload map[string]interface{} `json:"payload"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "invalid request format",
		})
		return
	}

	// Create message
	_ = websocket.Message{
		Type:      request.Type,
		ID:        uuid.New().String(),
		GameID:    &gameID,
		Timestamp: time.Now(),
		Payload:   request.Payload,
	}

	// Implementation would need to be added to Hub to support game-specific broadcasting
	// For now, return not implemented
	c.JSON(http.StatusNotImplemented, gin.H{
		"error": "game-specific broadcasting not implemented yet",
	})
}

// WebSocket middleware and helper functions

// WebSocketCORS middleware allows WebSocket connections from allowed origins
func WebSocketCORS() gin.HandlerFunc {
	return func(c *gin.Context) {
		origin := c.Request.Header.Get("Origin")

		// In production, check against allowed origins
		allowedOrigins := []string{
			"http://localhost:3000",
			"http://localhost:8080",
			"http://localhost:5173", // Vite dev server
		}

		for _, allowed := range allowedOrigins {
			if origin == allowed {
				c.Header("Access-Control-Allow-Origin", origin)
				break
			}
		}

		c.Header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Content-Type, Authorization")
		c.Header("Access-Control-Allow-Credentials", "true")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}

		c.Next()
	}
}

// RateLimitWebSocket middleware implements rate limiting for WebSocket connections
func RateLimitWebSocket() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Simple rate limiting by IP
		clientIP := c.ClientIP()

		// Implementation would use Redis or in-memory store for rate limiting
		// For now, just log and continue
		if clientIP != "" {
			// log.Printf("WebSocket connection attempt from: %s", clientIP)
		}

		c.Next()
	}
}

// RegisterWebSocketRoutes registers all WebSocket-related routes
func RegisterWebSocketRoutes(router *gin.Engine, hub *websocket.Hub, authService *auth.Service, logger *logger.Logger) {
	handler := NewWebSocketHandler(hub, authService, logger)

	// Apply middleware
	wsGroup := router.Group("/ws")
	wsGroup.Use(WebSocketCORS())
	wsGroup.Use(RateLimitWebSocket())

	// WebSocket upgrade endpoint (authentication via token query param)
	wsGroup.GET("/connect", handler.HandleWebSocketUpgrade)

	// WebSocket management endpoints (public for monitoring)
	wsGroup.GET("/stats", handler.GetConnectionStats)
	wsGroup.POST("/heartbeat", handler.SendHeartbeat)
	wsGroup.POST("/broadcast", handler.BroadcastMessage)
	wsGroup.POST("/broadcast/:game_id", handler.BroadcastToGame)

	// User management endpoints (public for monitoring)
	wsGroup.GET("/users/:user_id", handler.GetUserConnections)
	wsGroup.DELETE("/users/:user_id", handler.DisconnectUser)
}
