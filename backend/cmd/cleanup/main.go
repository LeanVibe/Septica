package main

import (
	"flag"
	"time"

	"septica-backend/internal/database"
	"septica-backend/pkg/config"
	"septica-backend/pkg/logger"
)

func main() {
	// Command line flags
	dryRun := flag.Bool("dry-run", false, "Show what would be deleted without actually deleting")
	maxAge := flag.Duration("max-age", 24*time.Hour, "Maximum age for stale entries (default: 24h)")
	verbose := flag.Bool("verbose", false, "Show detailed information")
	flag.Parse()

	// Load configuration
	cfg := config.Load()
	log := logger.New(cfg.LogLevel)

	log.Info("Starting database cleanup utility", "dry_run", *dryRun, "max_age", *maxAge)

	// Connect to database
	db, err := database.Initialize(cfg.DatabaseURL, log)
	if err != nil {
		log.Fatal("Failed to connect to database", "error", err)
	}

	sqlDB, _ := db.DB()
	defer sqlDB.Close()

	// Calculate cutoff time
	cutoff := time.Now().Add(-*maxAge)
	log.Info("Cleaning up entries older than", "cutoff", cutoff)

	// 1. Clean up stale matchmaking queue entries
	var staleQueueCount int64
	result := db.Model(&database.MatchmakingQueue{}).
		Where("created_at < ?", cutoff).
		Or("is_active = ? AND created_at < ?", false, time.Now().Add(-1*time.Hour)).
		Count(&staleQueueCount)

	if result.Error != nil {
		log.Error("Failed to count stale queue entries", "error", result.Error)
	} else {
		log.Info("Found stale matchmaking queue entries", "count", staleQueueCount)

		if *verbose && staleQueueCount > 0 {
			var staleEntries []database.MatchmakingQueue
			db.Where("created_at < ?", cutoff).
				Or("is_active = ? AND created_at < ?", false, time.Now().Add(-1*time.Hour)).
				Find(&staleEntries)

			for _, entry := range staleEntries {
				log.Info("Stale entry details",
					"id", entry.ID,
					"player_id", entry.PlayerID,
					"queue_type", entry.QueueType,
					"created_at", entry.CreatedAt,
					"is_active", entry.IsActive,
				)
			}
		}

		if !*dryRun && staleQueueCount > 0 {
			result = db.Where("created_at < ?", cutoff).
				Or("is_active = ? AND created_at < ?", false, time.Now().Add(-1*time.Hour)).
				Delete(&database.MatchmakingQueue{})

			if result.Error != nil {
				log.Error("Failed to delete stale queue entries", "error", result.Error)
			} else {
				log.Info("Deleted stale matchmaking queue entries", "count", result.RowsAffected)
			}
		}
	}

	// 2. Clean up abandoned games (status=waiting for more than max_age)
	var abandonedGamesCount int64
	result = db.Model(&database.Game{}).
		Where("status = ? AND created_at < ?", "waiting", cutoff).
		Count(&abandonedGamesCount)

	if result.Error != nil {
		log.Error("Failed to count abandoned games", "error", result.Error)
	} else {
		log.Info("Found abandoned games", "count", abandonedGamesCount)

		if !*dryRun && abandonedGamesCount > 0 {
			// Update status instead of deleting to preserve data
			result = db.Model(&database.Game{}).
				Where("status = ? AND created_at < ?", "waiting", cutoff).
				Update("status", "abandoned")

			if result.Error != nil {
				log.Error("Failed to mark games as abandoned", "error", result.Error)
			} else {
				log.Info("Marked games as abandoned", "count", result.RowsAffected)
			}
		}
	}

	// 3. Report on overall data integrity
	if *verbose {
		var totalUsers, totalPlayers, totalGames, totalActiveQueue int64

		db.Model(&database.User{}).Count(&totalUsers)
		db.Model(&database.Player{}).Count(&totalPlayers)
		db.Model(&database.Game{}).Count(&totalGames)
		db.Model(&database.MatchmakingQueue{}).Where("is_active = ?", true).Count(&totalActiveQueue)

		log.Info("Database statistics",
			"total_users", totalUsers,
			"total_players", totalPlayers,
			"total_games", totalGames,
			"active_queue_entries", totalActiveQueue,
		)
	}

	// 4. Verify referential integrity
	var orphanedPlayers int64
	db.Model(&database.Player{}).
		Where("user_id NOT IN (?)", db.Table("users").Select("id")).
		Count(&orphanedPlayers)

	if orphanedPlayers > 0 {
		log.Warn("Found orphaned players (players without users)", "count", orphanedPlayers)
	}

	if *dryRun {
		log.Info("Dry run complete - no changes were made")
	} else {
		log.Info("Cleanup complete")
	}
}
