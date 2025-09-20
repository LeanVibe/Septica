package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"septica-backend/internal/api"
	"septica-backend/internal/auth"
	"septica-backend/internal/database"
	"septica-backend/internal/game"
	"septica-backend/internal/matchmaking"
	"septica-backend/internal/websocket"
	"septica-backend/pkg/config"
	"septica-backend/pkg/logger"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

func main() {
	// Load environment variables
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, using system environment variables")
	}

	// Initialize configuration
	cfg := config.Load()

	// Initialize logger
	logger := logger.New(cfg.LogLevel)

	// Initialize database
	db, err := database.Initialize(cfg.DatabaseURL)
	if err != nil {
		logger.Fatal("Failed to initialize database", "error", err)
	}

	// Run database migrations
	if err := database.Migrate(db); err != nil {
		logger.Fatal("Failed to run database migrations", "error", err)
	}

	// Initialize services
	authService := auth.NewService(cfg.JWTSecret, cfg.JWTExpiration)
	gameEngine := game.NewEngine()
	matchmaker := matchmaking.NewService(db)

	// Initialize WebSocket hub
	wsHub := websocket.NewHub(gameEngine, logger)
	go wsHub.Run()

	// Initialize API router
	router := api.NewRouter(db, authService, matchmaker, wsHub, logger)

	// Set Gin mode
	if cfg.Environment == "production" {
		gin.SetMode(gin.ReleaseMode)
	}

	// Create HTTP server
	srv := &http.Server{
		Addr:         ":" + cfg.Port,
		Handler:      router,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// Start server in a goroutine
	go func() {
		logger.Info("Starting Septica backend server", "port", cfg.Port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Fatal("Failed to start server", "error", err)
		}
	}()

	// Wait for interrupt signal to gracefully shutdown the server
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	logger.Info("Shutting down server...")

	// Give outstanding requests a deadline for completion
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	// Shutdown server
	if err := srv.Shutdown(ctx); err != nil {
		logger.Fatal("Server forced to shutdown", "error", err)
	}

	logger.Info("Server exited")
}