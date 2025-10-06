package config

import (
	"os"
	"strconv"
	"time"
)

// Config holds all configuration values for the application
type Config struct {
	// Server configuration
	Port        string
	Environment string

	// Database configuration
	DatabaseURL string

	// JWT configuration
	JWTSecret     string
	JWTExpiration time.Duration

	// Redis configuration
	RedisURL string

	// WebSocket configuration
	WSReadBufferSize  int
	WSWriteBufferSize int
	WSMessageLimit    int64

	// Game configuration
	MaxConcurrentGames int
	GameTimeout        time.Duration
	MoveTimeout        time.Duration

	// Rate limiting
	RateLimitRequests int
	RateLimitWindow   time.Duration

	// Logging
	LogLevel string

	// CORS
	AllowedOrigins []string
}

// Load creates a new Config instance with values from environment variables
func Load() *Config {
	return &Config{
		// Server
		Port:        getEnv("PORT", "8080"),
		Environment: getEnv("ENVIRONMENT", "development"),

		// Database
		DatabaseURL: getEnv("DATABASE_URL", "postgres://septica:septica@localhost:5434/septica?sslmode=disable"),

		// JWT
		JWTSecret:     getEnv("JWT_SECRET", "septica-development-secret-key-change-in-production"),
		JWTExpiration: getDurationEnv("JWT_EXPIRATION", 24*time.Hour),

		// Redis
		RedisURL: getEnv("REDIS_URL", "redis://localhost:6379"),

		// WebSocket
		WSReadBufferSize:  getIntEnv("WS_READ_BUFFER_SIZE", 1024),
		WSWriteBufferSize: getIntEnv("WS_WRITE_BUFFER_SIZE", 1024),
		WSMessageLimit:    getInt64Env("WS_MESSAGE_LIMIT", 64*1024), // 64KB

		// Game
		MaxConcurrentGames: getIntEnv("MAX_CONCURRENT_GAMES", 10000),
		GameTimeout:        getDurationEnv("GAME_TIMEOUT", 30*time.Minute),
		MoveTimeout:        getDurationEnv("MOVE_TIMEOUT", 30*time.Second),

		// Rate limiting
		RateLimitRequests: getIntEnv("RATE_LIMIT_REQUESTS", 120),
		RateLimitWindow:   getDurationEnv("RATE_LIMIT_WINDOW", 1*time.Minute),

		// Logging
		LogLevel: getEnv("LOG_LEVEL", "info"),

		// CORS
		AllowedOrigins: []string{
			getEnv("FRONTEND_URL", "http://localhost:3000"),
			"http://localhost:8080", // For PWA testing
		},
	}
}

// Helper functions to get environment variables with defaults

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func getIntEnv(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		if intValue, err := strconv.Atoi(value); err == nil {
			return intValue
		}
	}
	return defaultValue
}

func getInt64Env(key string, defaultValue int64) int64 {
	if value := os.Getenv(key); value != "" {
		if intValue, err := strconv.ParseInt(value, 10, 64); err == nil {
			return intValue
		}
	}
	return defaultValue
}

func getDurationEnv(key string, defaultValue time.Duration) time.Duration {
	if value := os.Getenv(key); value != "" {
		if duration, err := time.ParseDuration(value); err == nil {
			return duration
		}
	}
	return defaultValue
}