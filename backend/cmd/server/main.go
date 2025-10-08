package main

import (
	"context"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"septica-backend/internal/ai"
	"septica-backend/internal/auth"
	"septica-backend/internal/database"
	"septica-backend/internal/game"
	"septica-backend/internal/handlers"
	"septica-backend/internal/matchmaking"
	"septica-backend/internal/middleware"
	"septica-backend/internal/websocket"
	"septica-backend/pkg/config"
	"septica-backend/pkg/logger"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/prometheus/client_golang/prometheus/promhttp"
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

	// Run database migrations (temporarily bypassed for testing)
	if os.Getenv("SKIP_MIGRATIONS") != "true" {
		if err := database.Migrate(db); err != nil {
			logger.Fatal("Failed to run database migrations", "error", err)
		}
		logger.Info("Database migrations completed")
	} else {
		logger.Info("Database migrations skipped (SKIP_MIGRATIONS=true)")
	}

	// Initialize authentication service
	authService := auth.NewService(cfg.JWTSecret, cfg.JWTExpiration, db)
	logger.Info("Authentication service initialized")

	// Initialize game engines
	gameEngine := game.NewEngine()
	authenticEngine := game.NewAuthenticEngine()
	logger.Info("Game engines initialized (legacy + authentic)")

	// Initialize WebSocket hub with both engines
	wsHub := websocket.NewHub(gameEngine, authenticEngine, db, logger)
	go wsHub.Run()
	logger.Info("WebSocket hub started")

	// Initialize matchmaking service with both engines
	matchmakingService := matchmaking.NewMatchmakingService(wsHub, gameEngine, authenticEngine, db, logger, nil)
	if err := matchmakingService.Start(); err != nil {
		logger.Fatal("Failed to start matchmaking service", "error", err)
	}
	logger.Info("Matchmaking service started")

	// Set matchmaking service reference in hub
	wsHub.SetMatchmakingService(matchmakingService)

	// Initialize AI matchmaking manager
	aiMatchmakingManager := ai.NewAIMatchmakingManager(wsHub, db, logger)
	if err := aiMatchmakingManager.Start(); err != nil {
		logger.Fatal("Failed to start AI matchmaking manager", "error", err)
	}
	logger.Info("AI matchmaking manager started")

	// Set up Gin router
	if cfg.Environment == "production" {
		gin.SetMode(gin.ReleaseMode)
	}

	router := gin.New()

	// Global middleware
	router.Use(gin.Recovery())
	router.Use(LoggerMiddleware(logger))
	router.Use(middleware.PrometheusMiddleware())
	router.Use(CORSMiddleware(cfg))

	// Register routes
	registerRoutes(router, wsHub, matchmakingService, authService, db, logger)

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

	// Stop AI matchmaking manager first
	aiMatchmakingManager.Stop()
	logger.Info("AI matchmaking manager stopped")

	// Stop matchmaking service
	matchmakingService.Stop()
	logger.Info("Matchmaking service stopped")

	// Give outstanding requests 30 seconds to complete
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := server.Shutdown(ctx); err != nil {
		logger.Fatal("Server forced to shutdown", "error", err)
	}

	logger.Info("Server exited")
}

// Track server start time for uptime calculation
var serverStartTime = time.Now()

// registerRoutes sets up all application routes
func registerRoutes(router *gin.Engine, wsHub *websocket.Hub, matchmakingService *matchmaking.MatchmakingService, authService *auth.Service, db *gorm.DB, logger *logger.Logger) {
	// Prometheus metrics endpoint (public, no authentication)
	router.GET("/metrics", gin.WrapH(promhttp.Handler()))

	// Enhanced health check endpoint (public)
	router.GET("/health", func(c *gin.Context) {
		// Check database connection
		dbStatus := "healthy"
		sqlDB, err := db.DB()
		if err != nil {
			dbStatus = "unhealthy"
		} else {
			if err := sqlDB.Ping(); err != nil {
				dbStatus = "unhealthy"
			}
		}

		// Check WebSocket hub
		wsStatus := "healthy"
		if wsHub == nil {
			wsStatus = "not_initialized"
		}

		// Check matchmaking service
		mmStatus := "healthy"
		if matchmakingService == nil {
			mmStatus = "not_initialized"
		}

		c.JSON(http.StatusOK, gin.H{
			"status":    "ok",
			"timestamp": time.Now().Unix(),
			"uptime_seconds": time.Since(serverStartTime).Seconds(),
			"components": gin.H{
				"database":    dbStatus,
				"websocket":   wsStatus,
				"matchmaking": mmStatus,
				"metrics":     "enabled",
			},
			"version": "1.0.0",
			"service": "septica-backend",
		})
	})

	// API version group
	v1 := router.Group("/api/v1")

	// Register authentication routes (public + protected)
	handlers.RegisterAuthRoutes(v1, authService, db, logger)

	// Register WebSocket routes (authentication via token query param)
	handlers.RegisterWebSocketRoutes(router, wsHub, authService, logger)

	// Protected routes - require authentication
	protected := v1.Group("/")
	protected.Use(middleware.AuthMiddleware(authService, logger))
	{
		// Tournament management
		protected.POST("/tournaments", func(c *gin.Context) {
			// Get handler and inject user context
			tournamentHandlers := handlers.NewTournamentHandlers(db, logger)
			tournamentHandlers.CreateTournament(c)
		})
		protected.GET("/tournaments", func(c *gin.Context) {
			tournamentHandlers := handlers.NewTournamentHandlers(db, logger)
			tournamentHandlers.ListTournaments(c)
		})
		protected.GET("/tournaments/:id", func(c *gin.Context) {
			tournamentHandlers := handlers.NewTournamentHandlers(db, logger)
			tournamentHandlers.GetTournament(c)
		})
		protected.POST("/tournaments/:id/join", func(c *gin.Context) {
			tournamentHandlers := handlers.NewTournamentHandlers(db, logger)
			tournamentHandlers.JoinTournament(c)
		})
		protected.POST("/tournaments/:id/start", func(c *gin.Context) {
			tournamentHandlers := handlers.NewTournamentHandlers(db, logger)
			tournamentHandlers.StartTournament(c)
		})
		protected.GET("/tournaments/:id/bracket", func(c *gin.Context) {
			tournamentHandlers := handlers.NewTournamentHandlers(db, logger)
			tournamentHandlers.GetTournamentBracket(c)
		})

		// Rating and leaderboards
		protected.GET("/leaderboard", func(c *gin.Context) {
			tournamentHandlers := handlers.NewTournamentHandlers(db, logger)
			tournamentHandlers.GetLeaderboard(c)
		})
		protected.GET("/players/:id/rating-history", func(c *gin.Context) {
			tournamentHandlers := handlers.NewTournamentHandlers(db, logger)
			tournamentHandlers.GetPlayerRatingHistory(c)
		})
		protected.GET("/rating-distribution", func(c *gin.Context) {
			tournamentHandlers := handlers.NewTournamentHandlers(db, logger)
			tournamentHandlers.GetRatingDistribution(c)
		})

		// Matchmaking endpoints
		protected.POST("/matchmaking/queue", func(c *gin.Context) {
			// Re-register matchmaking routes with auth
			handlers.RegisterMatchmakingRoutes(protected, matchmakingService, logger)
		})

		// Game management endpoints
		protected.GET("/games/:id", getGameHandler(logger))
		protected.POST("/games", createGameHandler(wsHub, logger))
		protected.POST("/games/:id/join", joinGameHandler(logger))
		protected.DELETE("/games/:id/leave", leaveGameHandler(logger))
	}

	// Public info endpoint (optional auth)
	v1.GET("/info", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"connections":  wsHub.GetConnectionCount(),
			"active_games": wsHub.GetGameCount(),
			"server_time":  time.Now(),
		})
	})

	logger.Info("Routes registered successfully with authentication")
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