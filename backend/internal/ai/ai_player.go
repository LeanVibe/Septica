package ai

import (
	"fmt"
	"math/rand"
	"sort"
	"time"

	"septica-backend/internal/database"
	"septica-backend/internal/game"
	"septica-backend/internal/metrics"
	"septica-backend/pkg/logger"

	"github.com/google/uuid"
)

// AIPlayerConfig holds configuration for AI behavior
type AIPlayerConfig struct {
	Difficulty        string        `json:"difficulty"`          // "easy", "medium", "hard"
	ReactionTimeMin   time.Duration `json:"reaction_time_min"`   // Minimum thinking time
	ReactionTimeMax   time.Duration `json:"reaction_time_max"`   // Maximum thinking time
	PointCardPriority float64       `json:"point_card_priority"` // 0.0-1.0 priority for collecting 10s/Aces
	SevenAggressiveness float64     `json:"seven_aggressiveness"` // 0.0-1.0 likelihood to play 7s early
	EightTiming       float64       `json:"eight_timing"`        // 0.0-1.0 strategic timing for 8s
}

// DefaultAIConfig returns default AI configuration based on difficulty
func DefaultAIConfig(difficulty string) *AIPlayerConfig {
	switch difficulty {
	case "easy":
		return &AIPlayerConfig{
			Difficulty:        "easy",
			ReactionTimeMin:   800 * time.Millisecond,
			ReactionTimeMax:   2500 * time.Millisecond,
			PointCardPriority: 0.3, // Less focused on points
			SevenAggressiveness: 0.7, // Plays 7s readily
			EightTiming:       0.2, // Poor 8 timing
		}
	case "medium":
		return &AIPlayerConfig{
			Difficulty:        "medium",
			ReactionTimeMin:   600 * time.Millisecond,
			ReactionTimeMax:   1800 * time.Millisecond,
			PointCardPriority: 0.6, // Moderate point focus
			SevenAggressiveness: 0.5, // Strategic 7 play
			EightTiming:       0.6, // Good 8 timing
		}
	case "hard":
		return &AIPlayerConfig{
			Difficulty:        "hard",
			ReactionTimeMin:   400 * time.Millisecond,
			ReactionTimeMax:   1200 * time.Millisecond,
			PointCardPriority: 0.8, // High point focus
			SevenAggressiveness: 0.3, // Saves 7s strategically
			EightTiming:       0.9, // Excellent 8 timing
		}
	default:
		return DefaultAIConfig("medium")
	}
}

// AIPlayer represents an AI opponent for Romanian Septica
type AIPlayer struct {
	ID          uuid.UUID        `json:"id"`
	Username    string           `json:"username"`
	Rating      int              `json:"rating"`
	Config      *AIPlayerConfig  `json:"config"`
	Logger      *logger.Logger   `json:"-"`

	// Game state awareness
	CurrentGameID *uuid.UUID       `json:"current_game_id,omitempty"`
	GameMode      game.AuthenticGameMode `json:"game_mode"` // Track current game mode for rule awareness
	Hand          []game.Card      `json:"-"` // Keep private
	GameState     *game.AuthenticGameState `json:"-"`
}

// NewAIPlayer creates a new AI player with specified difficulty
func NewAIPlayer(difficulty string, rating int, logger *logger.Logger) *AIPlayer {
	id := uuid.New()
	username := generateAIUsername(difficulty)

	ai := &AIPlayer{
		ID:       id,
		Username: username,
		Rating:   rating,
		Config:   DefaultAIConfig(difficulty),
		Logger:   logger,
	}

	logger.Info("Created AI player",
		"ai_id", id,
		"username", username,
		"difficulty", difficulty,
		"rating", rating)

	return ai
}

// generateAIUsername creates a Romanian-themed AI username
func generateAIUsername(difficulty string) string {
	// Romanian first names
	romanianNames := []string{
		"Alexandru", "Maria", "Ion", "Ana", "Gheorghe", "Elena",
		"Nicolae", "Ioana", "Constantin", "Mihaela", "Stefan", "Carmen",
		"Adrian", "Daniela", "Cristian", "Andreea", "Marius", "Alina",
		"Florin", "Diana", "Bogdan", "Raluca", "Razvan", "Simona",
	}

	// Difficulty-based suffixes
	var suffix string
	switch difficulty {
	case "easy":
		suffix = "Incepator" // Beginner
	case "medium":
		suffix = "Mediu"     // Medium
	case "hard":
		suffix = "Expert"    // Expert
	default:
		suffix = "AI"
	}

	name := romanianNames[rand.Intn(len(romanianNames))]
	return fmt.Sprintf("%s_%s", name, suffix)
}

// DecideMove analyzes the game state and decides the AI's next move
func (ai *AIPlayer) DecideMove(gameState *game.AuthenticGameState) (*game.AuthenticPlayerAction, error) {
	startTime := time.Now()
	ai.GameState = gameState
	ai.Hand = gameState.PlayerHands[ai.ID]

	// Simulate thinking time
	thinkingTime := ai.calculateThinkingTime()

	ai.Logger.Debug("AI player thinking",
		"ai_id", ai.ID,
		"thinking_time", thinkingTime,
		"hand_size", len(ai.Hand),
		"table_cards", len(gameState.TableCards))

	// Sleep to simulate human-like reaction time
	time.Sleep(thinkingTime)

	// Analyze possible moves
	validMoves := ai.getValidMoves(gameState)
	if len(validMoves) == 0 {
		// Must pass
		ai.Logger.Debug("AI player passing - no valid moves", "ai_id", ai.ID)

		// Record AI move duration metric
		duration := time.Since(startTime).Seconds()
		metrics.AIMoveDuration.WithLabelValues(ai.Config.Difficulty).Observe(duration)

		return &game.AuthenticPlayerAction{
			Type:     "PASS",
			PlayerID: ai.ID,
		}, nil
	}

	// Choose best move based on AI strategy
	bestMove := ai.chooseBestMove(validMoves, gameState)

	// Record AI move duration metric
	duration := time.Since(startTime).Seconds()
	metrics.AIMoveDuration.WithLabelValues(ai.Config.Difficulty).Observe(duration)

	ai.Logger.Info("AI player chose move",
		"ai_id", ai.ID,
		"move_type", bestMove.Type,
		"card", bestMove.Card,
		"thinking_time", thinkingTime)

	return bestMove, nil
}

// calculateThinkingTime determines how long AI should "think"
func (ai *AIPlayer) calculateThinkingTime() time.Duration {
	min := ai.Config.ReactionTimeMin
	max := ai.Config.ReactionTimeMax
	diff := max - min

	// Add some randomness to make AI seem more human-like
	randomFactor := rand.Float64()
	thinkingTime := min + time.Duration(float64(diff)*randomFactor)

	return thinkingTime
}

// getValidMoves returns all valid moves for current game state
func (ai *AIPlayer) getValidMoves(gameState *game.AuthenticGameState) []game.Card {
	validMoves := []game.Card{}

	for _, card := range ai.Hand {
		if ai.canPlayCard(card, gameState) {
			validMoves = append(validMoves, card)
		}
	}

	return validMoves
}

// canPlayCard checks if a card can be legally played (Romanian Septica rules)
func (ai *AIPlayer) canPlayCard(card game.Card, gameState *game.AuthenticGameState) bool {
	// In Romanian Septica, you can always play any card you have
	// The question is whether it will beat the table cards
	return true
}

// chooseBestMove selects the optimal move from valid options
func (ai *AIPlayer) chooseBestMove(validMoves []game.Card, gameState *game.AuthenticGameState) *game.AuthenticPlayerAction {
	if len(validMoves) == 0 {
		return &game.AuthenticPlayerAction{Type: "PASS", PlayerID: ai.ID}
	}

	// Score each possible move
	moveScores := make(map[game.Card]float64)
	for _, card := range validMoves {
		moveScores[card] = ai.scoreMove(card, gameState)
	}

	// Sort moves by score (descending)
	sort.Slice(validMoves, func(i, j int) bool {
		return moveScores[validMoves[i]] > moveScores[validMoves[j]]
	})

	// Add some randomness based on difficulty
	var chosenCard game.Card
	if ai.Config.Difficulty == "easy" {
		// Easy: 40% best move, 35% second best, 25% random
		roll := rand.Float64()
		if roll < 0.4 && len(validMoves) > 0 {
			chosenCard = validMoves[0]
		} else if roll < 0.75 && len(validMoves) > 1 {
			chosenCard = validMoves[1]
		} else {
			chosenCard = validMoves[rand.Intn(len(validMoves))]
		}
	} else if ai.Config.Difficulty == "medium" {
		// Medium: 60% best move, 30% second best, 10% random
		roll := rand.Float64()
		if roll < 0.6 && len(validMoves) > 0 {
			chosenCard = validMoves[0]
		} else if roll < 0.9 && len(validMoves) > 1 {
			chosenCard = validMoves[1]
		} else {
			chosenCard = validMoves[rand.Intn(len(validMoves))]
		}
	} else {
		// Hard: 80% best move, 15% second best, 5% tactical variation
		roll := rand.Float64()
		if roll < 0.8 && len(validMoves) > 0 {
			chosenCard = validMoves[0]
		} else if roll < 0.95 && len(validMoves) > 1 {
			chosenCard = validMoves[1]
		} else {
			chosenCard = validMoves[rand.Intn(len(validMoves))]
		}
	}

	return &game.AuthenticPlayerAction{
		Type:     "PLAY_CARD",
		PlayerID: ai.ID,
		Card:     &chosenCard,
	}
}

// scoreMove evaluates how good a move is (Romanian Septica strategy)
func (ai *AIPlayer) scoreMove(card game.Card, gameState *game.AuthenticGameState) float64 {
	score := 0.0
	tableCards := gameState.TableCards

	// Base scoring for Romanian Septica rules

	// 1. 7s always beat - very powerful
	if card.Value == 7 {
		score += 15.0
		// But maybe save 7s for when there are more cards to collect
		if len(tableCards) > 0 {
			score += float64(len(tableCards)) * 2.0
		}
		// Apply aggressiveness factor
		if rand.Float64() < ai.Config.SevenAggressiveness {
			score += 5.0
		} else {
			score -= 3.0 // Hold back strategically
		}
	}

	// 2. Same value beats (10 vs 10, Queen vs Queen, etc.)
	for _, tableCard := range tableCards {
		if card.Value == tableCard.Value {
			score += 10.0 + float64(len(tableCards)) // More cards = better
			break
		}
	}

	// 3. 8s are wild ONLY in 3-player variant (when 2 eights removed from deck)
	// In authentic Romanian Septica, 8s are NOT wild in 2 or 4 player games
	if card.Value == 8 {
		switch ai.GameMode {
		case game.ModeThreePlayer:
			// In 3-player mode, 8s ARE wild (along with 7s)
			score += 8.0  // Similar to 7s but slightly less valuable
			if len(tableCards) > 0 {
				score += 5.0  // Strong bonus for beating cards
			}
			// Apply timing strategy
			if rand.Float64() < ai.Config.EightTiming {
				score += 2.0
			}
		case game.ModeTwoPlayer, game.ModeFourPlayer:
			// In 2/4-player modes, 8s are NORMAL cards (not wild)
			// Check if 8 can beat table card via same-value rule
			canBeat := false
			for _, tableCard := range tableCards {
				if tableCard.Value == 8 {
					canBeat = true
					score += 5.0  // Good move - beats via same value
					break
				}
			}
			if !canBeat && len(tableCards) > 0 {
				score -= 3.0  // Penalty - 8 doesn't beat non-8 cards
			}
		default:
			// Unknown mode - conservative strategy
			score += 1.0
		}
	}

	// 4. Point card strategy (10s and Aces are worth 1 point each)
	pointCardsOnTable := 0
	for _, tableCard := range tableCards {
		if tableCard.Value == 10 || tableCard.Value == 14 { // 14 = Ace
			pointCardsOnTable++
		}
	}

	if pointCardsOnTable > 0 {
		// Try to collect point cards
		score += float64(pointCardsOnTable) * ai.Config.PointCardPriority * 8.0
	}

	// 5. Card counting strategy
	if len(ai.Hand) <= 2 {
		// Near end of hand, play more aggressively
		score += 3.0
	}

	// 6. Avoid playing point cards unless they beat something good
	if card.Value == 10 || card.Value == 14 {
		if len(tableCards) == 0 || pointCardsOnTable == 0 {
			score -= 4.0 // Don't throw away point cards for nothing
		}
	}

	// 7. Random factor for unpredictability
	randomFactor := (rand.Float64() - 0.5) * 2.0 // -1.0 to +1.0
	score += randomFactor

	return score
}

// GetPlayerInfo returns player information for database integration
func (ai *AIPlayer) GetPlayerInfo() *database.Player {
	return &database.Player{
		BaseModel: database.BaseModel{ID: ai.ID},
		UserID:    ai.ID, // AI players use same ID for user and player
		Username:  ai.Username,
		Level:     1,
		XP:        0,
		Rating:    ai.Rating,
		Arena:     1,
		Coins:     0, // AI players don't earn coins
		Gems:      0,
		SelectedCardBack:   "ai_default",
		SelectedTableTheme: "ai_default",
		SelectedAvatar:     "ai_robot",
	}
}

// IsAI returns true since this is an AI player
func (ai *AIPlayer) IsAI() bool {
	return true
}