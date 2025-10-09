package rating

import (
	"context"
	"fmt"
	"time"

	"septica-backend/internal/database"
	"septica-backend/pkg/logger"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// Service provides rating-related operations
type Service struct {
	db         *gorm.DB
	calculator *ELOCalculator
	logger     *logger.Logger
}

// NewService creates a new rating service
func NewService(db *gorm.DB, config *ELOConfig, logger *logger.Logger) *Service {
	if config == nil {
		config = DefaultELOConfig()
	}

	return &Service{
		db:         db,
		calculator: NewELOCalculator(config),
		logger:     logger,
	}
}

// ProcessGameResult processes a completed game and updates player ratings
func (s *Service) ProcessGameResult(ctx context.Context, gameID uuid.UUID) error {
	// Start transaction
	tx := s.db.WithContext(ctx).Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	// Get game details
	var game database.Game
	if err := tx.Preload("Player1").Preload("Player2").Preload("Tournament").First(&game, gameID).Error; err != nil {
		tx.Rollback()
		return fmt.Errorf("failed to get game: %w", err)
	}

	// Skip rating update if game is not completed or not ranked
	if game.Status != "completed" || (game.GameMode != "ranked" && game.GameMode != "tournament") {
		tx.Rollback()
		s.logger.Debug("Skipping rating update for non-ranked game", "game_id", gameID, "mode", game.GameMode)
		return nil
	}

	// Get player rating info
	player1Info, err := s.getPlayerRatingInfo(tx, game.Player1ID)
	if err != nil {
		tx.Rollback()
		return fmt.Errorf("failed to get player1 rating info: %w", err)
	}

	player2Info, err := s.getPlayerRatingInfo(tx, game.Player2ID)
	if err != nil {
		tx.Rollback()
		return fmt.Errorf("failed to get player2 rating info: %w", err)
	}

	// Determine game result from player 1's perspective
	var result GameResult
	if game.WinnerID == nil {
		result = GameResultDraw
	} else if *game.WinnerID == game.Player1ID {
		result = GameResultWin
	} else {
		result = GameResultLoss
	}

	// Create game context
	gameContext := &GameContext{
		GameID:          &gameID,
		TournamentID:    game.TournamentID,
		GameMode:        game.GameMode,
		IsMars:          game.IsMars,
		ScoreDifference: abs(game.Player1Score - game.Player2Score),
		IsPlayoff:       game.IsPlayoffGame,
		TournamentRound: game.TournamentRound,
	}

	// Calculate rating changes
	player1Calc, player2Calc := s.calculator.CalculateBothPlayersRatingChange(
		player1Info, player2Info, result, gameContext,
	)

	// Update player ratings in database
	if err := s.updatePlayerRating(tx, player1Calc); err != nil {
		tx.Rollback()
		return fmt.Errorf("failed to update player1 rating: %w", err)
	}

	if err := s.updatePlayerRating(tx, player2Calc); err != nil {
		tx.Rollback()
		return fmt.Errorf("failed to update player2 rating: %w", err)
	}

	// Store rating history
	if err := s.storeRatingHistory(tx, player1Calc); err != nil {
		tx.Rollback()
		return fmt.Errorf("failed to store player1 rating history: %w", err)
	}

	if err := s.storeRatingHistory(tx, player2Calc); err != nil {
		tx.Rollback()
		return fmt.Errorf("failed to store player2 rating history: %w", err)
	}

	// Update game with rating changes
	game.Player1RatingBefore = player1Calc.PlayerRating
	game.Player2RatingBefore = player2Calc.PlayerRating
	game.Player1RatingAfter = &player1Calc.NewRating
	game.Player2RatingAfter = &player2Calc.NewRating
	game.Player1RatingChange = player1Calc.RatingChange
	game.Player2RatingChange = player2Calc.RatingChange

	if err := tx.Save(&game).Error; err != nil {
		tx.Rollback()
		return fmt.Errorf("failed to update game with rating changes: %w", err)
	}

	// Commit transaction
	if err := tx.Commit().Error; err != nil {
		return fmt.Errorf("failed to commit rating update transaction: %w", err)
	}

	s.logger.Info("Rating update completed",
		"game_id", gameID,
		"player1_change", player1Calc.RatingChange,
		"player2_change", player2Calc.RatingChange,
		"player1_new_rating", player1Calc.NewRating,
		"player2_new_rating", player2Calc.NewRating,
	)

	return nil
}

// GetLeaderboard returns the top players by rating
func (s *Service) GetLeaderboard(ctx context.Context, limit int, season string) ([]LeaderboardEntry, error) {
	var entries []LeaderboardEntry

	// Base query structure
	baseSelect := `
		players.id as player_id,
		players.username,
		players.rating,
		players.level,
		players.arena,
		players.updated_at as last_active
	`

	var query *gorm.DB

	if season != "" {
		// Season-specific leaderboard using PlayerSeasonStats
		query = s.db.WithContext(ctx).Table("players").
			Select(baseSelect+`,
				COALESCE(pss.ranked_games_played, 0) as games_played,
				COALESCE(pss.ranked_games_won, 0) as games_won,
				COALESCE(pss.ranked_games_played - pss.ranked_games_won, 0) as games_lost,
				COALESCE(pss.win_rate, 0) as win_rate,
				0 as win_streak
			`).
			Joins("INNER JOIN player_season_stats pss ON players.id = pss.player_id").
			Where("players.is_active = ?", true).
			Where("pss.season = ?", season).
			Order("players.rating DESC, players.updated_at DESC")
	} else {
		// All-time leaderboard using PlayerStatistics
		query = s.db.WithContext(ctx).Table("players").
			Select(baseSelect+`,
				COALESCE(stats.games_played, 0) as games_played,
				COALESCE(stats.games_won, 0) as games_won,
				COALESCE(stats.games_lost, 0) as games_lost,
				CASE
					WHEN COALESCE(stats.games_played, 0) > 0
					THEN ROUND(CAST(COALESCE(stats.games_won, 0) AS FLOAT) / COALESCE(stats.games_played, 0) * 100, 1)
					ELSE 0
				END as win_rate,
				COALESCE(stats.current_win_streak, 0) as win_streak
			`).
			Joins("LEFT JOIN player_statistics stats ON players.id = stats.player_id").
			Where("players.is_active = ?", true).
			Order("players.rating DESC, players.updated_at DESC")
	}

	if limit > 0 {
		query = query.Limit(limit)
	}

	if err := query.Scan(&entries).Error; err != nil {
		return nil, fmt.Errorf("failed to get leaderboard: %w", err)
	}

	// Add rank numbers
	for i := range entries {
		entries[i].Rank = i + 1
	}

	return entries, nil
}

// GetPlayerRatingHistory returns a player's rating history
func (s *Service) GetPlayerRatingHistory(ctx context.Context, playerID uuid.UUID, limit int) ([]database.ELORatingHistory, error) {
	var history []database.ELORatingHistory

	query := s.db.WithContext(ctx).
		Preload("Game").
		Preload("Tournament").
		Preload("Opponent").
		Where("player_id = ?", playerID).
		Order("created_at DESC")

	if limit > 0 {
		query = query.Limit(limit)
	}

	if err := query.Find(&history).Error; err != nil {
		return nil, fmt.Errorf("failed to get player rating history: %w", err)
	}

	return history, nil
}

// GetRatingDistribution returns rating distribution statistics
func (s *Service) GetRatingDistribution(ctx context.Context) (*RatingDistribution, error) {
	var dist RatingDistribution

	// Get rating statistics
	err := s.db.WithContext(ctx).Raw(`
		SELECT 
			MIN(rating) as min_rating,
			MAX(rating) as max_rating,
			AVG(rating) as avg_rating,
			PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY rating) as median_rating,
			COUNT(*) as total_players
		FROM players 
		WHERE is_active = true
	`).Scan(&dist).Error

	if err != nil {
		return nil, fmt.Errorf("failed to get rating distribution: %w", err)
	}

	// Get rating ranges
	err = s.db.WithContext(ctx).Raw(`
		SELECT 
			rating_range,
			COUNT(*) as player_count
		FROM (
			SELECT 
				CASE 
					WHEN rating < 800 THEN 'Below 800'
					WHEN rating < 1000 THEN '800-999'
					WHEN rating < 1200 THEN '1000-1199'
					WHEN rating < 1400 THEN '1200-1399'
					WHEN rating < 1600 THEN '1400-1599'
					WHEN rating < 1800 THEN '1600-1799'
					WHEN rating < 2000 THEN '1800-1999'
					WHEN rating < 2200 THEN '2000-2199'
					WHEN rating < 2400 THEN '2200-2399'
					ELSE '2400+'
				END as rating_range
			FROM players 
			WHERE is_active = true
		) ranges
		GROUP BY rating_range
		ORDER BY 
			CASE rating_range
				WHEN 'Below 800' THEN 1
				WHEN '800-999' THEN 2
				WHEN '1000-1199' THEN 3
				WHEN '1200-1399' THEN 4
				WHEN '1400-1599' THEN 5
				WHEN '1600-1799' THEN 6
				WHEN '1800-1999' THEN 7
				WHEN '2000-2199' THEN 8
				WHEN '2200-2399' THEN 9
				WHEN '2400+' THEN 10
			END
	`).Scan(&dist.RatingRanges).Error

	if err != nil {
		return nil, fmt.Errorf("failed to get rating ranges: %w", err)
	}

	return &dist, nil
}

// Helper methods

func (s *Service) getPlayerRatingInfo(tx *gorm.DB, playerID uuid.UUID) (*PlayerRatingInfo, error) {
	var player database.Player
	if err := tx.First(&player, playerID).Error; err != nil {
		return nil, fmt.Errorf("player not found: %w", err)
	}

	var stats database.PlayerStatistics
	if err := tx.Where("player_id = ?", playerID).First(&stats).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			// Create default stats
			stats = database.PlayerStatistics{
				PlayerID:    playerID,
				GamesPlayed: 0,
			}
		} else {
			return nil, fmt.Errorf("failed to get player statistics: %w", err)
		}
	}

	// Get last game date
	var lastGameDate *time.Time
	var lastGame database.Game
	err := tx.Where("(player1_id = ? OR player2_id = ?) AND status = 'completed'", playerID, playerID).
		Order("ended_at DESC").
		First(&lastGame).Error
	if err == nil && lastGame.EndedAt != nil {
		lastGameDate = lastGame.EndedAt
	}

	return &PlayerRatingInfo{
		PlayerID:      playerID,
		CurrentRating: player.Rating,
		GamesPlayed:   stats.GamesPlayed,
		IsProvisional: s.calculator.IsProvisionalPeriod(stats.GamesPlayed),
		LastGameDate:  lastGameDate,
		WinStreak:     stats.CurrentWinStreak,
		LossStreak:    0, // TODO: Calculate loss streak if needed
	}, nil
}

func (s *Service) updatePlayerRating(tx *gorm.DB, calc *RatingCalculation) error {
	// Update player rating
	if err := tx.Model(&database.Player{}).
		Where("id = ?", calc.PlayerID).
		Update("rating", calc.NewRating).Error; err != nil {
		return err
	}

	// Update player statistics
	var stats database.PlayerStatistics
	err := tx.Where("player_id = ?", calc.PlayerID).First(&stats).Error
	if err == gorm.ErrRecordNotFound {
		// Create new statistics record
		stats = database.PlayerStatistics{
			PlayerID:    calc.PlayerID,
			GamesPlayed: 1,
		}
		if calc.Result == GameResultWin {
			stats.GamesWon = 1
			stats.CurrentWinStreak = 1
		} else if calc.Result == GameResultLoss {
			stats.GamesLost = 1
			stats.CurrentWinStreak = 0
		} else {
			stats.GamesDrawn = 1
			stats.CurrentWinStreak = 0
		}
		return tx.Create(&stats).Error
	} else if err != nil {
		return err
	}

	// Update existing statistics
	stats.GamesPlayed++
	if calc.Result == GameResultWin {
		stats.GamesWon++
		stats.CurrentWinStreak++
		if stats.CurrentWinStreak > stats.BestWinStreak {
			stats.BestWinStreak = stats.CurrentWinStreak
		}
	} else if calc.Result == GameResultLoss {
		stats.GamesLost++
		stats.CurrentWinStreak = 0
	} else {
		stats.GamesDrawn++
		stats.CurrentWinStreak = 0
	}

	return tx.Save(&stats).Error
}

func (s *Service) storeRatingHistory(tx *gorm.DB, calc *RatingCalculation) error {
	history := database.ELORatingHistory{
		PlayerID:        calc.PlayerID,
		GameID:          calc.GameID,
		TournamentID:    calc.TournamentID,
		OldRating:       calc.PlayerRating,
		NewRating:       calc.NewRating,
		RatingChange:    calc.RatingChange,
		KFactor:         calc.KFactor,
		ChangeReason:    string(calc.Result),
		OpponentID:      &calc.OpponentID,
		OpponentRating:  &calc.OpponentRating,
		GameResult:      (*string)(&calc.Result),
		ScoreDifference: &calc.ScoreDifference,
	}

	return tx.Create(&history).Error
}

// Utility function
func abs(x int) int {
	if x < 0 {
		return -x
	}
	return x
}

// LeaderboardEntry represents a leaderboard entry
type LeaderboardEntry struct {
	Rank        int       `json:"rank"`
	PlayerID    uuid.UUID `json:"player_id"`
	Username    string    `json:"username"`
	Rating      int       `json:"rating"`
	Level       int       `json:"level"`
	Arena       int       `json:"arena"`
	GamesPlayed int       `json:"games_played"`
	GamesWon    int       `json:"games_won"`
	GamesLost   int       `json:"games_lost"`
	WinRate     float64   `json:"win_rate"`
	WinStreak   int       `json:"win_streak"`
	LastActive  time.Time `json:"last_active"`
}

// RatingDistribution represents rating distribution statistics
type RatingDistribution struct {
	MinRating    int                `json:"min_rating"`
	MaxRating    int                `json:"max_rating"`
	AvgRating    float64            `json:"avg_rating"`
	MedianRating float64            `json:"median_rating"`
	TotalPlayers int                `json:"total_players"`
	RatingRanges []RatingRangeCount `json:"rating_ranges"`
}

// RatingRangeCount represents count of players in a rating range
type RatingRangeCount struct {
	RatingRange string `json:"rating_range"`
	PlayerCount int    `json:"player_count"`
}
