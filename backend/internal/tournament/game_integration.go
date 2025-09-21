package tournament

import (
	"context"
	"fmt"
	"time"

	"septica-backend/internal/database"
	"septica-backend/internal/game"
	"septica-backend/internal/rating"
	"septica-backend/pkg/logger"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// GameIntegration handles tournament-game integration
type GameIntegration struct {
	db            *gorm.DB
	gameEngine    *game.Engine
	ratingService *rating.Service
	logger        *logger.Logger
}

// NewGameIntegration creates a new tournament-game integration service
func NewGameIntegration(db *gorm.DB, gameEngine *game.Engine, ratingService *rating.Service, logger *logger.Logger) *GameIntegration {
	return &GameIntegration{
		db:            db,
		gameEngine:    gameEngine,
		ratingService: ratingService,
		logger:        logger,
	}
}

// CreateTournamentGame creates a game for a tournament bracket
func (gi *GameIntegration) CreateTournamentGame(ctx context.Context, tournamentID, bracketID uuid.UUID, player1ID, player2ID uuid.UUID) (*game.GameState, error) {
	// Start database transaction
	tx := gi.db.WithContext(ctx).Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	// Get tournament info
	var tournament database.Tournament
	if err := tx.First(&tournament, tournamentID).Error; err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("failed to get tournament: %w", err)
	}

	// Get bracket info
	var bracket database.TournamentBracket
	if err := tx.First(&bracket, bracketID).Error; err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("failed to get bracket: %w", err)
	}

	// Get player ratings for context
	var player1, player2 database.Player
	if err := tx.First(&player1, player1ID).Error; err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("failed to get player1: %w", err)
	}
	if err := tx.First(&player2, player2ID).Error; err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("failed to get player2: %w", err)
	}

	// Create game using game engine
	gameState := gi.gameEngine.CreateGame(player1ID, player2ID)

	// Create database game record with tournament context
	dbGame := database.Game{
		BaseModel: database.BaseModel{
			ID: gameState.ID,
		},
		Player1ID:           player1ID,
		Player2ID:           player2ID,
		TournamentID:        &tournamentID,
		TournamentBracketID: &bracketID,
		TournamentRound:     &bracket.Round,
		IsPlayoffGame:       gi.isPlayoffRound(tournament.Type, bracket.Round),
		Status:              "waiting",
		GameMode:            gi.getGameModeForTournament(&tournament),
		Player1RatingBefore: player1.Rating,
		Player2RatingBefore: player2.Rating,
	}

	if err := tx.Create(&dbGame).Error; err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("failed to create game record: %w", err)
	}

	// Update bracket with game ID
	bracket.GameID = &gameState.ID
	if err := tx.Save(&bracket).Error; err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("failed to update bracket: %w", err)
	}

	if err := tx.Commit().Error; err != nil {
		return nil, fmt.Errorf("failed to commit transaction: %w", err)
	}

	gi.logger.Info("Tournament game created",
		"game_id", gameState.ID,
		"tournament_id", tournamentID,
		"bracket_id", bracketID,
		"round", bracket.Round,
		"player1", player1ID,
		"player2", player2ID,
	)

	return gameState, nil
}

// OnGameComplete handles tournament game completion
func (gi *GameIntegration) OnGameComplete(ctx context.Context, gameID uuid.UUID, result *game.MoveResult) error {
	if !result.GameComplete {
		return nil // Game not complete, nothing to do
	}

	// Start transaction
	tx := gi.db.WithContext(ctx).Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	// Get game with tournament context
	var dbGame database.Game
	if err := tx.Preload("Tournament").Preload("TournamentBracket").First(&dbGame, gameID).Error; err != nil {
		tx.Rollback()
		return fmt.Errorf("failed to get game: %w", err)
	}

	// Skip if not a tournament game
	if dbGame.TournamentID == nil {
		gi.logger.Debug("Non-tournament game completed", "game_id", gameID)
		return nil
	}

	// Update game completion
	now := time.Now()
	dbGame.Status = "completed"
	dbGame.EndedAt = &now
	dbGame.DurationMs = now.Sub(dbGame.CreatedAt).Milliseconds()
	dbGame.WinnerID = result.WinnerID

	if err := tx.Save(&dbGame).Error; err != nil {
		tx.Rollback()
		return fmt.Errorf("failed to update game: %w", err)
	}

	// Process rating changes for tournament games
	if dbGame.Tournament.IsRankedTournament {
		if err := gi.ratingService.ProcessGameResult(ctx, gameID); err != nil {
			gi.logger.Error("Failed to process rating changes", "error", err, "game_id", gameID)
			// Don't fail the whole operation for rating issues
		}
	}

	// Update tournament bracket
	if err := gi.updateBracketResult(tx, &dbGame, result); err != nil {
		tx.Rollback()
		return fmt.Errorf("failed to update bracket: %w", err)
	}

	// Update participant statistics
	if err := gi.updateParticipantStats(tx, &dbGame, result); err != nil {
		tx.Rollback()
		return fmt.Errorf("failed to update participant stats: %w", err)
	}

	// Check if tournament progression is needed
	if err := gi.checkTournamentProgression(tx, &dbGame); err != nil {
		tx.Rollback()
		return fmt.Errorf("failed to check tournament progression: %w", err)
	}

	if err := tx.Commit().Error; err != nil {
		return fmt.Errorf("failed to commit tournament game completion: %w", err)
	}

	gi.logger.Info("Tournament game completed",
		"game_id", gameID,
		"tournament_id", dbGame.TournamentID,
		"winner", result.WinnerID,
		"round", dbGame.TournamentRound,
	)

	return nil
}

// Helper methods

func (gi *GameIntegration) getGameModeForTournament(tournament *database.Tournament) string {
	if tournament.Type == "swiss_system" {
		return "swiss"
	}
	return "tournament"
}

func (gi *GameIntegration) isPlayoffRound(tournamentType string, round int) bool {
	switch tournamentType {
	case "single_elimination":
		return round >= 1 // All rounds are playoff in single elimination
	case "double_elimination":
		return round >= 1 // All rounds are playoff in double elimination
	case "swiss_system":
		return false // No playoff rounds in Swiss system
	case "round_robin":
		return false // No playoff rounds in round robin
	default:
		return false
	}
}

func (gi *GameIntegration) updateBracketResult(tx *gorm.DB, game *database.Game, result *game.MoveResult) error {
	if game.TournamentBracket == nil {
		return fmt.Errorf("tournament bracket not found")
	}

	bracket := game.TournamentBracket
	bracket.WinnerID = result.WinnerID
	bracket.IsComplete = true

	if err := tx.Save(bracket).Error; err != nil {
		return fmt.Errorf("failed to save bracket: %w", err)
	}

	// For elimination tournaments, advance winner to next round
	if game.Tournament.Type == "single_elimination" || game.Tournament.Type == "double_elimination" {
		if err := gi.advanceWinnerToNextRound(tx, game, result.WinnerID); err != nil {
			return fmt.Errorf("failed to advance winner: %w", err)
		}

		// For double elimination, handle loser advancement
		if game.Tournament.Type == "double_elimination" {
			if err := gi.advanceLoserToLosersBracket(tx, game, result.WinnerID); err != nil {
				return fmt.Errorf("failed to advance loser: %w", err)
			}
		}
	}

	return nil
}

func (gi *GameIntegration) updateParticipantStats(tx *gorm.DB, game *database.Game, result *game.MoveResult) error {
	// Update participant statistics
	gameState, err := gi.gameEngine.GetGame(game.ID)
	if err != nil {
		return fmt.Errorf("game state not found in engine: %w", err)
	}

	// Get participants
	var participant1, participant2 database.TournamentParticipant
	if err := tx.Where("tournament_id = ? AND player_id = ?", game.TournamentID, game.Player1ID).First(&participant1).Error; err != nil {
		return fmt.Errorf("failed to get participant1: %w", err)
	}
	if err := tx.Where("tournament_id = ? AND player_id = ?", game.TournamentID, game.Player2ID).First(&participant2).Error; err != nil {
		return fmt.Errorf("failed to get participant2: %w", err)
	}

	// Update game counts and scores
	participant1.GamesWon++
	participant1.TotalPointsScored += gameState.Player1Score
	participant2.GamesWon++
	participant2.TotalPointsScored += gameState.Player2Score

	// Update win/loss records
	if result.WinnerID != nil {
		if *result.WinnerID == game.Player1ID {
			participant1.GamesWon++
			participant2.GamesLost++
		} else {
			participant1.GamesLost++
			participant2.GamesWon++
		}
	}

	// Update Swiss system specific stats
	if game.Tournament.Type == "swiss_system" {
		if result.WinnerID != nil {
			if *result.WinnerID == game.Player1ID {
				participant1.SwissPoints++
				participant1.SwissWins++
				participant2.SwissLosses++
			} else {
				participant2.SwissPoints++
				participant2.SwissWins++
				participant1.SwissLosses++
			}
		} else {
			// Draw
			participant1.SwissDraws++
			participant2.SwissDraws++
		}
	}

	// Save participants
	if err := tx.Save(&participant1).Error; err != nil {
		return fmt.Errorf("failed to save participant1: %w", err)
	}
	if err := tx.Save(&participant2).Error; err != nil {
		return fmt.Errorf("failed to save participant2: %w", err)
	}

	return nil
}

func (gi *GameIntegration) advanceWinnerToNextRound(tx *gorm.DB, game *database.Game, winnerID *uuid.UUID) error {
	if winnerID == nil {
		return nil // No winner to advance (draw)
	}

	// Find next round bracket position
	nextRound := *game.TournamentRound + 1
	nextPosition := (game.TournamentBracket.Position + 1) / 2

	// Find the bracket for next round
	var nextBracket database.TournamentBracket
	err := tx.Where("tournament_id = ? AND bracket_type = ? AND round = ? AND position = ?",
		game.TournamentID, game.TournamentBracket.BracketType, nextRound, nextPosition).First(&nextBracket).Error

	if err == gorm.ErrRecordNotFound {
		// This was the final round
		if err := gi.completeTournament(tx, game.Tournament, winnerID); err != nil {
			return fmt.Errorf("failed to complete tournament: %w", err)
		}
		return nil
	} else if err != nil {
		return fmt.Errorf("failed to find next bracket: %w", err)
	}

	// Determine which slot to fill (player1 or player2)
	if game.TournamentBracket.Position%2 == 1 {
		// Odd position advances to player1 slot
		nextBracket.Player1ID = winnerID
	} else {
		// Even position advances to player2 slot
		nextBracket.Player2ID = winnerID
	}

	if err := tx.Save(&nextBracket).Error; err != nil {
		return fmt.Errorf("failed to save next bracket: %w", err)
	}

	// If both slots are filled, create the next game
	if nextBracket.Player1ID != nil && nextBracket.Player2ID != nil {
		_, err := gi.CreateTournamentGame(context.Background(), *game.TournamentID, nextBracket.ID, *nextBracket.Player1ID, *nextBracket.Player2ID)
		if err != nil {
			return fmt.Errorf("failed to create next game: %w", err)
		}
	}

	return nil
}

func (gi *GameIntegration) advanceLoserToLosersBracket(tx *gorm.DB, game *database.Game, winnerID *uuid.UUID) error {
	if winnerID == nil {
		return nil // No loser to advance in case of draw
	}

	// Determine loser
	var loserID uuid.UUID
	if *winnerID == game.Player1ID {
		loserID = game.Player2ID
	} else {
		loserID = game.Player1ID
	}

	// Find appropriate losers bracket position
	// This is a simplified implementation - real double elimination would be more complex
	losersRound := *game.TournamentRound
	losersPosition := game.TournamentBracket.Position

	var losersBracket database.TournamentBracket
	err := tx.Where("tournament_id = ? AND bracket_type = ? AND round = ? AND position = ?",
		game.TournamentID, "losers", losersRound, losersPosition).First(&losersBracket).Error

	if err == gorm.ErrRecordNotFound {
		// Create losers bracket entry if it doesn't exist
		losersBracket = database.TournamentBracket{
			TournamentID: *game.TournamentID,
			BracketType:  "losers",
			Round:        losersRound,
			Position:     losersPosition,
			Player1ID:    &loserID,
		}
		if err := tx.Create(&losersBracket).Error; err != nil {
			return fmt.Errorf("failed to create losers bracket: %w", err)
		}
	} else if err != nil {
		return fmt.Errorf("failed to find losers bracket: %w", err)
	} else {
		// Add loser to existing bracket
		if losersBracket.Player1ID == nil {
			losersBracket.Player1ID = &loserID
		} else if losersBracket.Player2ID == nil {
			losersBracket.Player2ID = &loserID
		}
		if err := tx.Save(&losersBracket).Error; err != nil {
			return fmt.Errorf("failed to save losers bracket: %w", err)
		}
	}

	return nil
}

func (gi *GameIntegration) checkTournamentProgression(tx *gorm.DB, game *database.Game) error {
	// Check if we need to generate next Swiss round
	if game.Tournament.Type == "swiss_system" {
		return gi.checkSwissProgression(tx, game.Tournament)
	}

	return nil
}

func (gi *GameIntegration) checkSwissProgression(tx *gorm.DB, tournament *database.Tournament) error {
	// Check if current round is complete
	currentRound := tournament.CurrentSwissRound
	if currentRound == 0 {
		currentRound = 1
	}

	var incompleteGames int64
	err := tx.Model(&database.Game{}).
		Where("tournament_id = ? AND tournament_round = ? AND status != ?", tournament.ID, currentRound, "completed").
		Count(&incompleteGames).Error
	if err != nil {
		return fmt.Errorf("failed to count incomplete games: %w", err)
	}

	if incompleteGames > 0 {
		return nil // Round not complete yet
	}

	// Round is complete, check if we need another round
	if currentRound >= tournament.SwissRounds {
		// Tournament is complete
		return gi.completeSwissTournament(tx, tournament)
	}

	// Generate next round
	nextRound := currentRound + 1
	tournament.CurrentSwissRound = nextRound

	service := &Service{db: tx, logger: gi.logger}
	if err := service.generateSwissSystemPairings(tx, tournament, nextRound); err != nil {
		return fmt.Errorf("failed to generate next Swiss round: %w", err)
	}

	if err := tx.Save(tournament).Error; err != nil {
		return fmt.Errorf("failed to update tournament round: %w", err)
	}

	gi.logger.Info("Generated next Swiss round", 
		"tournament_id", tournament.ID, 
		"round", nextRound)

	return nil
}

func (gi *GameIntegration) completeTournament(tx *gorm.DB, tournament *database.Tournament, winnerID *uuid.UUID) error {
	tournament.Status = "completed"
	now := time.Now()
	tournament.TournamentEnd = &now

	if err := tx.Save(tournament).Error; err != nil {
		return fmt.Errorf("failed to update tournament status: %w", err)
	}

	// Award final ranking and prizes
	if err := gi.awardFinalPrizes(tx, tournament, winnerID); err != nil {
		return fmt.Errorf("failed to award prizes: %w", err)
	}

	gi.logger.Info("Tournament completed", 
		"tournament_id", tournament.ID, 
		"winner", winnerID)

	return nil
}

func (gi *GameIntegration) completeSwissTournament(tx *gorm.DB, tournament *database.Tournament) error {
	// Determine final rankings based on Swiss points
	var participants []database.TournamentParticipant
	err := tx.Where("tournament_id = ?", tournament.ID).
		Order("swiss_points DESC, swiss_buchholz_score DESC").
		Find(&participants).Error
	if err != nil {
		return fmt.Errorf("failed to get final standings: %w", err)
	}

	// Award final rankings
	for i, participant := range participants {
		rank := i + 1
		participant.FinalRank = &rank
		if err := tx.Save(&participant).Error; err != nil {
			return fmt.Errorf("failed to save final rank: %w", err)
		}
	}

	var winnerID *uuid.UUID
	if len(participants) > 0 {
		winnerID = &participants[0].PlayerID
	}

	return gi.completeTournament(tx, tournament, winnerID)
}

func (gi *GameIntegration) awardFinalPrizes(tx *gorm.DB, tournament *database.Tournament, winnerID *uuid.UUID) error {
	// Get final rankings
	var participants []database.TournamentParticipant
	err := tx.Where("tournament_id = ? AND final_rank IS NOT NULL", tournament.ID).
		Order("final_rank ASC").
		Find(&participants).Error
	if err != nil {
		return fmt.Errorf("failed to get ranked participants: %w", err)
	}

	// Calculate and award prizes based on ranking
	totalCoins := tournament.PrizePoolCoins
	totalGems := tournament.PrizePoolGems

	for _, participant := range participants {
		var prizeCoins, prizeGems int

		switch tournament.PrizeDistributionType {
		case "percentage":
			if *participant.FinalRank == 1 {
				prizeCoins = (totalCoins * tournament.FirstPlacePrizePercent) / 100
				prizeGems = (totalGems * tournament.FirstPlacePrizePercent) / 100
			} else if *participant.FinalRank == 2 {
				prizeCoins = (totalCoins * tournament.SecondPlacePrizePercent) / 100
				prizeGems = (totalGems * tournament.SecondPlacePrizePercent) / 100
			} else if *participant.FinalRank == 3 {
				prizeCoins = (totalCoins * tournament.ThirdPlacePrizePercent) / 100
				prizeGems = (totalGems * tournament.ThirdPlacePrizePercent) / 100
			}

		case "winner_takes_all":
			if *participant.FinalRank == 1 {
				prizeCoins = totalCoins
				prizeGems = totalGems
			}

		case "fixed":
			// Fixed prize amounts would need to be configured per tournament
			// This is a simplified implementation
			if *participant.FinalRank == 1 {
				prizeCoins = totalCoins / 2
				prizeGems = totalGems / 2
			} else if *participant.FinalRank == 2 {
				prizeCoins = totalCoins / 3
				prizeGems = totalGems / 3
			}
		}

		// Award prizes
		if prizeCoins > 0 || prizeGems > 0 {
			participant.PrizeCoins = prizeCoins
			participant.PrizeGems = prizeGems

			// Update player balance
			var player database.Player
			if err := tx.First(&player, participant.PlayerID).Error; err != nil {
				gi.logger.Error("Failed to get player for prize award", "error", err, "player_id", participant.PlayerID)
				continue
			}

			player.Coins += prizeCoins
			player.Gems += prizeGems

			if err := tx.Save(&player).Error; err != nil {
				gi.logger.Error("Failed to award prizes to player", "error", err, "player_id", participant.PlayerID)
				continue
			}

			if err := tx.Save(&participant).Error; err != nil {
				gi.logger.Error("Failed to save participant prizes", "error", err, "participant_id", participant.ID)
				continue
			}

			gi.logger.Info("Prizes awarded", 
				"player_id", participant.PlayerID, 
				"rank", *participant.FinalRank,
				"coins", prizeCoins, 
				"gems", prizeGems)
		}
	}

	return nil
}