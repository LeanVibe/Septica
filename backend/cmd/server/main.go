package main

import (
	"context"
	"errors"
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
		protected.GET("/games/:id", getGameHandler(db, logger))
		protected.POST("/games", createGameHandler(db, wsHub, logger))
		protected.POST("/games/:id/join", joinGameHandler(db, logger))
		protected.DELETE("/games/:id/leave", leaveGameHandler(db, logger))
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

// Game management handlers

func getGameHandler(db *gorm.DB, logger *logger.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		gameID, err := uuid.Parse(c.Param("id"))
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid game ID"})
			return
		}

		// Get authenticated user ID from context (set by auth middleware)
		userID, exists := c.Get("user_id")
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "user not authenticated"})
			return
		}

		// Query database for game
		var dbGame database.Game
		if err := db.Preload("Player1").Preload("Player2").Preload("Player3").Preload("Player4").First(&dbGame, "id = ?", gameID).Error; err != nil {
			if errors.Is(err, gorm.ErrRecordNotFound) {
				c.JSON(http.StatusNotFound, gin.H{"error": "game not found"})
			} else {
				logger.Error("Failed to fetch game from database", "error", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to retrieve game"})
			}
			return
		}

		// Verify user is participant in this game
		userUUID := userID.(uuid.UUID)
		isPlayer := dbGame.Player1ID == userUUID || dbGame.Player2ID == userUUID
		if dbGame.Player3ID != nil && *dbGame.Player3ID == userUUID {
			isPlayer = true
		}
		if dbGame.Player4ID != nil && *dbGame.Player4ID == userUUID {
			isPlayer = true
		}

		if !isPlayer {
			c.JSON(http.StatusForbidden, gin.H{"error": "not a participant in this game"})
			return
		}

		c.JSON(http.StatusOK, dbGame)
	}
}

func createGameHandler(db *gorm.DB, wsHub *websocket.Hub, logger *logger.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Parse request body
		var req struct {
			Mode       string `json:"mode" binding:"required,oneof=two_players three_players four_players"`
			IsPrivate  bool   `json:"is_private"`
			MaxPlayers int    `json:"max_players" binding:"required,min=2,max=4"`
		}

		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		// Get authenticated user ID
		userID, exists := c.Get("user_id")
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "user not authenticated"})
			return
		}

		userUUID := userID.(uuid.UUID)
		gameID := uuid.New()

		// Determine authentic mode based on max players
		authenticMode := ""
		if req.MaxPlayers == 2 {
			authenticMode = "2_player"
		} else if req.MaxPlayers == 3 {
			authenticMode = "3_player"
		} else if req.MaxPlayers == 4 {
			authenticMode = "4_player"
		}

		// Create game in database
		dbGame := &database.Game{
			Player1ID:          userUUID,
			Player2ID:          uuid.Nil, // Will be filled when player joins
			Status:             "waiting",
			GameMode:           req.Mode,
			AuthenticMode:      authenticMode,
			UseAuthenticRules:  true,
		}
		dbGame.ID = gameID

		if err := db.Create(dbGame).Error; err != nil {
			logger.Error("Failed to create game in database", "error", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create game"})
			return
		}

		logger.Info("Game created via REST API",
			"user_id", userUUID,
			"game_id", gameID,
			"mode", req.Mode,
			"max_players", req.MaxPlayers)

		c.JSON(http.StatusCreated, gin.H{
			"message":   "game created successfully",
			"game_id":   gameID,
			"game":      dbGame,
		})
	}
}

func joinGameHandler(db *gorm.DB, logger *logger.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		gameID, err := uuid.Parse(c.Param("id"))
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid game ID"})
			return
		}

		// Get authenticated user ID
		userID, exists := c.Get("user_id")
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "user not authenticated"})
			return
		}

		userUUID := userID.(uuid.UUID)

		// Fetch game from database
		var dbGame database.Game
		if err := db.First(&dbGame, "id = ?", gameID).Error; err != nil {
			if errors.Is(err, gorm.ErrRecordNotFound) {
				c.JSON(http.StatusNotFound, gin.H{"error": "game not found"})
			} else {
				logger.Error("Failed to fetch game", "error", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to retrieve game"})
			}
			return
		}

		// Determine max players from authentic mode
		maxPlayers := 2
		if dbGame.AuthenticMode == "3_player" {
			maxPlayers = 3
		} else if dbGame.AuthenticMode == "4_player" {
			maxPlayers = 4
		}

		// Check if game is full
		currentPlayers := 1 // Player1 always exists
		if dbGame.Player2ID != uuid.Nil {
			currentPlayers++
		}
		if dbGame.Player3ID != nil && *dbGame.Player3ID != uuid.Nil {
			currentPlayers++
		}
		if dbGame.Player4ID != nil && *dbGame.Player4ID != uuid.Nil {
			currentPlayers++
		}

		if currentPlayers >= maxPlayers {
			c.JSON(http.StatusConflict, gin.H{"error": "game is full"})
			return
		}

		// Check if already in game
		if dbGame.Player1ID == userUUID || dbGame.Player2ID == userUUID {
			c.JSON(http.StatusConflict, gin.H{"error": "already in game"})
			return
		}
		if dbGame.Player3ID != nil && *dbGame.Player3ID == userUUID {
			c.JSON(http.StatusConflict, gin.H{"error": "already in game"})
			return
		}
		if dbGame.Player4ID != nil && *dbGame.Player4ID == userUUID {
			c.JSON(http.StatusConflict, gin.H{"error": "already in game"})
			return
		}

		// Check if game already started
		if dbGame.Status != "waiting" {
			c.JSON(http.StatusConflict, gin.H{"error": "game already started"})
			return
		}

		// Add player to game
		if dbGame.Player2ID == uuid.Nil {
			dbGame.Player2ID = userUUID
		} else if dbGame.Player3ID == nil || *dbGame.Player3ID == uuid.Nil {
			dbGame.Player3ID = &userUUID
		} else if dbGame.Player4ID == nil || *dbGame.Player4ID == uuid.Nil {
			dbGame.Player4ID = &userUUID
		}

		// Save updated game
		if err := db.Save(&dbGame).Error; err != nil {
			logger.Error("Failed to update game", "error", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to join game"})
			return
		}

		logger.Info("Player joined game via REST API",
			"user_id", userUUID,
			"game_id", gameID)

		c.JSON(http.StatusOK, gin.H{
			"message": "successfully joined game",
			"game_id": gameID,
			"game":    dbGame,
		})
	}
}

func leaveGameHandler(db *gorm.DB, logger *logger.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		gameID, err := uuid.Parse(c.Param("id"))
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid game ID"})
			return
		}

		// Get authenticated user ID
		userID, exists := c.Get("user_id")
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "user not authenticated"})
			return
		}

		userUUID := userID.(uuid.UUID)

		// Fetch game from database
		var dbGame database.Game
		if err := db.First(&dbGame, "id = ?", gameID).Error; err != nil {
			if errors.Is(err, gorm.ErrRecordNotFound) {
				c.JSON(http.StatusNotFound, gin.H{"error": "game not found or not a participant"})
			} else {
				logger.Error("Failed to fetch game", "error", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to retrieve game"})
			}
			return
		}

		// Check if user is in the game and remove them
		wasInGame := false
		if dbGame.Player1ID == userUUID {
			// If player1 leaves, abandon the game or reassign
			dbGame.Status = "abandoned"
			wasInGame = true
		} else if dbGame.Player2ID == userUUID {
			dbGame.Player2ID = uuid.Nil
			wasInGame = true
		} else if dbGame.Player3ID != nil && *dbGame.Player3ID == userUUID {
			dbGame.Player3ID = nil
			wasInGame = true
		} else if dbGame.Player4ID != nil && *dbGame.Player4ID == userUUID {
			dbGame.Player4ID = nil
			wasInGame = true
		}

		if !wasInGame {
			c.JSON(http.StatusNotFound, gin.H{"error": "not a participant in this game"})
			return
		}

		// Save updated game
		if err := db.Save(&dbGame).Error; err != nil {
			logger.Error("Failed to update game", "error", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to leave game"})
			return
		}

		logger.Info("Player left game via REST API",
			"user_id", userUUID,
			"game_id", gameID)

		c.JSON(http.StatusOK, gin.H{
			"message": "successfully left game",
			"game_id": gameID,
		})
	}
}