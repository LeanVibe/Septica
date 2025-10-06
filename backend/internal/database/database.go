package database

import (
	"fmt"
	"time"

	"septica-backend/pkg/logger"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	gormlogger "gorm.io/gorm/logger"
)

// Initialize creates a new database connection
func Initialize(databaseURL string, logger *logger.Logger) (*gorm.DB, error) {
	// Configure GORM
	config := &gorm.Config{
		Logger: gormlogger.Default.LogMode(gormlogger.Info),
		NowFunc: func() time.Time {
			return time.Now().UTC()
		},
	}

	// Connect to database
	db, err := gorm.Open(postgres.Open(databaseURL), config)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to database: %w", err)
	}

	// Configure connection pool
	sqlDB, err := db.DB()
	if err != nil {
		return nil, fmt.Errorf("failed to get underlying sql.DB: %w", err)
	}

	// Connection pool settings
	sqlDB.SetMaxIdleConns(10)
	sqlDB.SetMaxOpenConns(100)
	sqlDB.SetConnMaxLifetime(time.Hour)

	// Test the connection
	if err := sqlDB.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	return db, nil
}

// Migrate runs database migrations
func Migrate(db *gorm.DB) error {
	// Auto-migrate models in dependency order
	// Note: Models with foreign keys must come AFTER their dependencies
	models := []interface{}{
		// Base tables with no foreign keys
		&User{},
		&Player{},

		// Player-related tables (depend on Player)
		&PlayerStatistics{},
		&MatchmakingQueue{},
		&PlayerSeasonStats{},
		&Friendship{},

		// Tournament tables (depend on Player)
		&Tournament{},
		&TournamentParticipant{},
		&TournamentBracket{}, // Must come before Game (Game references it)

		// Game tables (depend on Player, Tournament, TournamentBracket)
		&Game{},
		&GameMove{},
		&ChatMessage{},

		// Rating history (depends on Player, Game, Tournament)
		&ELORatingHistory{},
	}

	for _, model := range models {
		if err := db.AutoMigrate(model); err != nil {
			return fmt.Errorf("failed to migrate %T: %w", model, err)
		}
	}

	return nil
}

// Health checks database connectivity
func Health(db *gorm.DB) error {
	sqlDB, err := db.DB()
	if err != nil {
		return err
	}
	return sqlDB.Ping()
}

// Close closes the database connection
func Close(db *gorm.DB) error {
	sqlDB, err := db.DB()
	if err != nil {
		return err
	}
	return sqlDB.Close()
}