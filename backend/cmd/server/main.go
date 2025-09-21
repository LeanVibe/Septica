package main

import (
	"context"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"septica-backend/internal/database"
	"septica-backend/internal/game"
	"septica-backend/internal/handlers"
	"septica-backend/internal/websocket"
	"septica-backend/pkg/config"
	"septica-backend/pkg/logger"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

func main() {
	// Load configuration
	cfg := config.Load()

	// Initialize logger
	logger := logger.New(cfg.LogLevel)
	logger.Info("Starting Septica backend server", "environment", cfg.Environment, "port", cfg.Port)

	// Initialize database
	db, err := database.Initialize(cfg.DatabaseURL, logger)
	if err != nil {
		logger.Fatal("Failed to initialize database", "error", err)
	}
	logger.Info("Database connected successfully")

	// Run database migrations
	if err := database.Migrate(db); err != nil {
		logger.Fatal("Failed to run database migrations", "error", err)
	}
	logger.Info("Database migrations completed")

	// Initialize game engine
	gameEngine := game.NewEngine()
	logger.Info("Game engine initialized")

	// Initialize WebSocket hub
	wsHub := websocket.NewHub(gameEngine, logger)
	go wsHub.Run()
	logger.Info("WebSocket hub started")

	// Set up Gin router
	if cfg.Environment == "production" {
		gin.SetMode(gin.ReleaseMode)
	}

	router := gin.New()

	// Global middleware
	router.Use(gin.Recovery())
	router.Use(LoggerMiddleware(logger))
	router.Use(CORSMiddleware(cfg))

	// Register routes
	registerRoutes(router, wsHub, db, logger)

	// Create HTTP server
	server := &http.Server{
		Addr:    ":" + cfg.Port,
		Handler: router,
	}

	// Start heartbeat ticker
	go startHeartbeatTicker(wsHub, logger)

	// Start server in a goroutine
	go func() {
		logger.Info("Server starting", "port", cfg.Port)
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Fatal("Server failed to start", "error", err)
		}
	}()

	// Wait for interrupt signal to gracefully shutdown the server
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	logger.Info("Server shutting down...")

	// Give outstanding requests 30 seconds to complete
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := server.Shutdown(ctx); err != nil {
		logger.Fatal("Server forced to shutdown", "error", err)
	}

	logger.Info("Server exited")
}

// registerRoutes sets up all application routes
func registerRoutes(router *gin.Engine, wsHub *websocket.Hub, db *gorm.DB, logger *logger.Logger) {
	// Health check endpoint
	router.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":    "healthy",
			"timestamp": time.Now(),
			"version":   "1.0.0",
			"service":   "septica-backend",
		})
	})

	// API version group
	v1 := router.Group("/api/v1")

	// Register WebSocket routes
	handlers.RegisterWebSocketRoutes(router, wsHub, logger)

	// Register tournament routes
	handlers.RegisterTournamentRoutes(v1, db, logger)

	// Game management endpoints
	v1.GET("/games/:id", getGameHandler(logger))
	v1.POST("/games", createGameHandler(wsHub, logger))
	v1.POST("/games/:id/join", joinGameHandler(logger))
	v1.DELETE("/games/:id/leave", leaveGameHandler(logger))

	// Server info endpoint
	v1.GET("/info", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"connections": wsHub.GetConnectionCount(),
			"active_games": wsHub.GetGameCount(),
			"server_time": time.Now(),
			"uptime":      time.Since(time.Now()), // This would be calculated from start time
		})
	})

	logger.Info("Routes registered successfully")
}

// LoggerMiddleware provides request logging
func LoggerMiddleware(logger *logger.Logger) gin.HandlerFunc {
	return gin.LoggerWithFormatter(func(param gin.LogFormatterParams) string {
		logger.Info("HTTP Request",
			"method", param.Method,
			"path", param.Path,
			"status", param.StatusCode,
			"latency", param.Latency,
			"ip", param.ClientIP,
			"user_agent", param.Request.UserAgent(),
		)
		return ""
	})
}

// CORSMiddleware handles CORS headers
func CORSMiddleware(cfg *config.Config) gin.HandlerFunc {
	return func(c *gin.Context) {
		origin := c.Request.Header.Get("Origin")

		// Check if origin is allowed
		for _, allowedOrigin := range cfg.AllowedOrigins {
			if origin == allowedOrigin {
				c.Header("Access-Control-Allow-Origin", origin)
				break
			}
		}

		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Requested-With")
		c.Header("Access-Control-Allow-Credentials", "true")
		c.Header("Access-Control-Max-Age", "86400")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}

		c.Next()
	}
}

// startHeartbeatTicker sends periodic heartbeats to all connected clients
func startHeartbeatTicker(hub *websocket.Hub, logger *logger.Logger) {
	ticker := time.NewTicker(30 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			hub.SendHeartbeat()
			logger.Debug("Heartbeat sent to all clients", "connections", hub.GetConnectionCount())
		}
	}
}

// Placeholder handlers for game management (to be implemented)

func getGameHandler(logger *logger.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		c.JSON(http.StatusNotImplemented, gin.H{
			"error": "Game management endpoints not implemented yet",
		})
	}
}

func createGameHandler(wsHub *websocket.Hub, logger *logger.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Parse request body
		var req struct {
			GameMode string `json:"game_mode,omitempty"`
			PlayerID string `json:"player_id,omitempty"`
		}
		
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{
				"error": "Invalid request format",
				"details": err.Error(),
			})
			return
		}
		
		// Parse player ID or generate one for testing
		var player1ID uuid.UUID
		var err error
		if req.PlayerID != "" {
			player1ID, err = uuid.Parse(req.PlayerID)
			if err != nil {
				c.JSON(http.StatusBadRequest, gin.H{
					"error": "Invalid player ID format",
				})
				return
			}
		} else {
			player1ID = uuid.New()
		}
		
		// For testing: Create a dummy second player
		// TODO: Replace with proper matchmaking system
		player2ID := uuid.New()
		
		// Create game using the game engine
		game := wsHub.GetGameEngine().CreateGame(player1ID, player2ID)
		
		logger.Info("Game created successfully", 
			"game_id", game.ID, 
			"player1_id", player1ID, 
			"player2_id", player2ID,
			"game_mode", req.GameMode)
		
		c.JSON(http.StatusCreated, gin.H{
			"game_id": game.ID,
			"player1_id": player1ID,
			"player2_id": player2ID,
			"status": game.Status,
			"current_player": game.CurrentPlayerID,
			"created_at": game.CreatedAt,
			"game_mode": req.GameMode,
		})
	}
}

func joinGameHandler(logger *logger.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		c.JSON(http.StatusNotImplemented, gin.H{
			"error": "Game join endpoint not implemented yet",
		})
	}
}

func leaveGameHandler(logger *logger.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		c.JSON(http.StatusNotImplemented, gin.H{
			"error": "Game leave endpoint not implemented yet",
		})
	}
}