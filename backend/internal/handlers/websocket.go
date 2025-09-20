package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"septica-backend/internal/websocket"
	"septica-backend/pkg/logger"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// WebSocketHandler handles WebSocket-related HTTP endpoints
type WebSocketHandler struct {
	hub    *websocket.Hub
	logger *logger.Logger
}

// NewWebSocketHandler creates a new WebSocket handler
func NewWebSocketHandler(hub *websocket.Hub, logger *logger.Logger) *WebSocketHandler {
	return &WebSocketHandler{
		hub:    hub,
		logger: logger,
	}
}

// HandleWebSocketUpgrade handles WebSocket connection upgrade requests
func (h *WebSocketHandler) HandleWebSocketUpgrade(c *gin.Context) {
	// Extract user ID from query parameter or JWT token
	userIDStr := c.Query("user_id")
	if userIDStr == "" {
		// Try to get from JWT token if available
		if userIDFromToken := h.getUserIDFromToken(c); userIDFromToken != uuid.Nil {
			userIDStr = userIDFromToken.String()
		} else {
			c.JSON(http.StatusBadRequest, gin.H{
				"error": "user_id parameter or valid JWT token required",
			})
			return
		}
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "invalid user_id format",
		})
		return
	}

	sessionID := c.Query("session_id")
	if sessionID == "" {
		sessionID = uuid.New().String()
	}

	// Upgrade HTTP connection to WebSocket
	websocket.ServeWS(h.hub, c.Writer, c.Request)
	
	h.logger.Info("WebSocket connection upgrade", "user_id", userID, "session_id", sessionID)
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
		"user_id":     userID,
		"connected":   false, // Placeholder
		"session_id":  "",    // Placeholder
		"connected_at": nil,  // Placeholder
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

// Helper function to extract user ID from JWT token
func (h *WebSocketHandler) getUserIDFromToken(c *gin.Context) uuid.UUID {
	// Implementation would extract user ID from JWT token
	// For now, return nil UUID
	return uuid.Nil
}

// RegisterWebSocketRoutes registers all WebSocket-related routes
func RegisterWebSocketRoutes(router *gin.Engine, hub *websocket.Hub, logger *logger.Logger) {
	handler := NewWebSocketHandler(hub, logger)
	
	// Apply middleware
	wsGroup := router.Group("/ws")
	wsGroup.Use(WebSocketCORS())
	wsGroup.Use(RateLimitWebSocket())
	
	// WebSocket upgrade endpoint
	wsGroup.GET("/connect", handler.HandleWebSocketUpgrade)
	
	// WebSocket management endpoints
	wsGroup.GET("/stats", handler.GetConnectionStats)
	wsGroup.POST("/heartbeat", handler.SendHeartbeat)
	wsGroup.POST("/broadcast", handler.BroadcastMessage)
	wsGroup.POST("/broadcast/:game_id", handler.BroadcastToGame)
	
	// User management endpoints
	wsGroup.GET("/users/:user_id", handler.GetUserConnections)
	wsGroup.DELETE("/users/:user_id", handler.DisconnectUser)
}