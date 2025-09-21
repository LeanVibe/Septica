package rating

import (
	"math"
	"time"

	"github.com/google/uuid"
)

// ELOConfig holds configuration for ELO rating calculations
type ELOConfig struct {
	// Base K-factor for rating changes
	BaseKFactor int

	// K-factor adjustments based on player characteristics
	ProvisionalKFactor   int // For players with < 30 games
	HighRatedKFactor     int // For players with rating > 2400
	TournamentMultiplier float64 // Multiplier for tournament games

	// Rating boundaries
	MinRating int
	MaxRating int
	StartingRating int

	// Provisional period
	ProvisionalGameCount int
}

// DefaultELOConfig returns a default ELO configuration optimized for Romanian Septica
func DefaultELOConfig() *ELOConfig {
	return &ELOConfig{
		BaseKFactor:          32,
		ProvisionalKFactor:   40,
		HighRatedKFactor:     16,
		TournamentMultiplier: 1.5,
		MinRating:           600,
		MaxRating:           3000,
		StartingRating:      1200,
		ProvisionalGameCount: 30,
	}
}

// GameResult represents the outcome of a game
type GameResult string

const (
	GameResultWin  GameResult = "win"
	GameResultLoss GameResult = "loss"
	GameResultDraw GameResult = "draw"
)

// RatingCalculation represents a single rating calculation
type RatingCalculation struct {
	PlayerID       uuid.UUID
	OpponentID     uuid.UUID
	PlayerRating   int
	OpponentRating int
	Result         GameResult
	KFactor        int
	ExpectedScore  float64
	ActualScore    float64
	RatingChange   int
	NewRating      int
	
	// Context information
	GameID       *uuid.UUID
	TournamentID *uuid.UUID
	GameMode     string
	IsMars       bool
	ScoreDifference int
}

// PlayerRatingInfo holds information about a player's current rating state
type PlayerRatingInfo struct {
	PlayerID        uuid.UUID
	CurrentRating   int
	GamesPlayed     int
	IsProvisional   bool
	LastGameDate    *time.Time
	WinStreak       int
	LossStreak      int
}

// ELOCalculator handles ELO rating calculations
type ELOCalculator struct {
	config *ELOConfig
}

// NewELOCalculator creates a new ELO calculator with the given configuration
func NewELOCalculator(config *ELOConfig) *ELOCalculator {
	if config == nil {
		config = DefaultELOConfig()
	}
	return &ELOCalculator{
		config: config,
	}
}

// CalculateRatingChange calculates the rating change for a single player
func (calc *ELOCalculator) CalculateRatingChange(
	playerInfo *PlayerRatingInfo,
	opponentRating int,
	result GameResult,
	gameContext *GameContext,
) *RatingCalculation {
	
	// Determine K-factor
	kFactor := calc.determineKFactor(playerInfo, gameContext)
	
	// Calculate expected score using ELO formula
	expectedScore := calc.calculateExpectedScore(playerInfo.CurrentRating, opponentRating)
	
	// Convert game result to actual score
	actualScore := calc.gameResultToScore(result)
	
	// Apply performance modifiers
	performanceMultiplier := calc.calculatePerformanceMultiplier(result, gameContext)
	
	// Calculate raw rating change
	rawChange := float64(kFactor) * (actualScore - expectedScore) * performanceMultiplier
	
	// Round and apply bounds
	ratingChange := int(math.Round(rawChange))
	newRating := calc.applyRatingBounds(playerInfo.CurrentRating + ratingChange)
	
	// Adjust change based on actual new rating (in case bounds were applied)
	ratingChange = newRating - playerInfo.CurrentRating
	
	return &RatingCalculation{
		PlayerID:       playerInfo.PlayerID,
		PlayerRating:   playerInfo.CurrentRating,
		OpponentRating: opponentRating,
		Result:         result,
		KFactor:        kFactor,
		ExpectedScore:  expectedScore,
		ActualScore:    actualScore,
		RatingChange:   ratingChange,
		NewRating:      newRating,
		GameID:         gameContext.GameID,
		TournamentID:   gameContext.TournamentID,
		GameMode:       gameContext.GameMode,
		IsMars:         gameContext.IsMars,
		ScoreDifference: gameContext.ScoreDifference,
	}
}

// CalculateBothPlayersRatingChange calculates rating changes for both players in a game
func (calc *ELOCalculator) CalculateBothPlayersRatingChange(
	player1Info *PlayerRatingInfo,
	player2Info *PlayerRatingInfo,
	winner GameResult, // From player 1's perspective
	gameContext *GameContext,
) (*RatingCalculation, *RatingCalculation) {
	
	// Player 1's perspective
	player1Result := winner
	
	// Player 2's perspective (opposite result)
	var player2Result GameResult
	switch winner {
	case GameResultWin:
		player2Result = GameResultLoss
	case GameResultLoss:
		player2Result = GameResultWin
	case GameResultDraw:
		player2Result = GameResultDraw
	}
	
	// Calculate for both players
	player1Calc := calc.CalculateRatingChange(player1Info, player2Info.CurrentRating, player1Result, gameContext)
	player2Calc := calc.CalculateRatingChange(player2Info, player1Info.CurrentRating, player2Result, gameContext)
	
	// Set opponent IDs
	player1Calc.OpponentID = player2Info.PlayerID
	player2Calc.OpponentID = player1Info.PlayerID
	
	return player1Calc, player2Calc
}

// GameContext provides additional context for rating calculations
type GameContext struct {
	GameID          *uuid.UUID
	TournamentID    *uuid.UUID
	GameMode        string
	IsMars          bool
	ScoreDifference int
	GameDuration    time.Duration
	IsPlayoff       bool
	TournamentRound *int
}

// determineKFactor calculates the appropriate K-factor for a player
func (calc *ELOCalculator) determineKFactor(playerInfo *PlayerRatingInfo, gameContext *GameContext) int {
	baseK := calc.config.BaseKFactor
	
	// Provisional period (higher K-factor for new players)
	if playerInfo.IsProvisional || playerInfo.GamesPlayed < calc.config.ProvisionalGameCount {
		baseK = calc.config.ProvisionalKFactor
	}
	
	// Lower K-factor for highly rated players
	if playerInfo.CurrentRating >= 2400 {
		baseK = calc.config.HighRatedKFactor
	}
	
	// Tournament games have higher impact
	if gameContext.TournamentID != nil {
		baseK = int(float64(baseK) * calc.config.TournamentMultiplier)
	}
	
	// Playoff games have even higher impact
	if gameContext.IsPlayoff {
		baseK = int(float64(baseK) * 1.2)
	}
	
	return baseK
}

// calculateExpectedScore calculates expected score using standard ELO formula
func (calc *ELOCalculator) calculateExpectedScore(playerRating, opponentRating int) float64 {
	return 1.0 / (1.0 + math.Pow(10, float64(opponentRating-playerRating)/400.0))
}

// gameResultToScore converts game result to numerical score
func (calc *ELOCalculator) gameResultToScore(result GameResult) float64 {
	switch result {
	case GameResultWin:
		return 1.0
	case GameResultLoss:
		return 0.0
	case GameResultDraw:
		return 0.5
	default:
		return 0.0
	}
}

// calculatePerformanceMultiplier applies modifiers based on game performance
func (calc *ELOCalculator) calculatePerformanceMultiplier(result GameResult, gameContext *GameContext) float64 {
	multiplier := 1.0
	
	// Mars wins/losses have higher impact
	if gameContext.IsMars {
		if result == GameResultWin {
			multiplier *= 1.3 // Mars win bonus
		} else if result == GameResultLoss {
			multiplier *= 1.2 // Mars loss penalty
		}
	}
	
	// Score difference modifier (subtle)
	if gameContext.ScoreDifference > 0 {
		if result == GameResultWin {
			// Larger wins slightly increase rating gain
			scoreFactor := 1.0 + (float64(gameContext.ScoreDifference) * 0.02)
			if scoreFactor > 1.15 {
				scoreFactor = 1.15 // Cap at 15% bonus
			}
			multiplier *= scoreFactor
		}
	}
	
	return multiplier
}

// applyRatingBounds ensures rating stays within configured limits
func (calc *ELOCalculator) applyRatingBounds(rating int) int {
	if rating < calc.config.MinRating {
		return calc.config.MinRating
	}
	if rating > calc.config.MaxRating {
		return calc.config.MaxRating
	}
	return rating
}

// GetStartingRating returns the starting rating for new players
func (calc *ELOCalculator) GetStartingRating() int {
	return calc.config.StartingRating
}

// IsProvisionalPeriod checks if a player is still in provisional period
func (calc *ELOCalculator) IsProvisionalPeriod(gamesPlayed int) bool {
	return gamesPlayed < calc.config.ProvisionalGameCount
}

// CalculateExpectedWinProbability calculates win probability between two players
func (calc *ELOCalculator) CalculateExpectedWinProbability(playerRating, opponentRating int) float64 {
	return calc.calculateExpectedScore(playerRating, opponentRating)
}

// CalculateRatingRequirement calculates rating needed to achieve target win rate
func (calc *ELOCalculator) CalculateRatingRequirement(opponentRating int, targetWinRate float64) int {
	// Inverse ELO formula: Ra = Rb + 400 * log10((1/E) - 1)
	if targetWinRate >= 1.0 {
		return calc.config.MaxRating
	}
	if targetWinRate <= 0.0 {
		return calc.config.MinRating
	}
	
	logValue := math.Log10((1.0/targetWinRate) - 1.0)
	requiredRating := float64(opponentRating) + (400.0 * logValue)
	
	return calc.applyRatingBounds(int(math.Round(requiredRating)))
}