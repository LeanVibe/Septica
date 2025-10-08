package game

import (
	"errors"
	"math/rand"
	"time"

	"septica-backend/internal/metrics"

	"github.com/google/uuid"
)

var (
	ErrInvalidMove      = errors.New("invalid move")
	ErrNotPlayerTurn    = errors.New("not player turn")
	ErrGameNotFound     = errors.New("game not found")
	ErrGameNotActive    = errors.New("game not active")
	ErrCardNotInHand    = errors.New("card not in hand")
	ErrCannotBeatCard   = errors.New("cannot beat card")
)

// GameMode represents different Romanian Septica game modes
type GameMode string

const (
	TwoPlayers   GameMode = "two_players"   // 32 cards, 7s wild, 8s normal
	ThreePlayers GameMode = "three_players" // 30 cards (remove 2 eights), 7s + remaining 8s wild
	FourPlayers  GameMode = "four_players"  // 32 cards, team play, 7s wild, 8s normal
)

// PlayerActionType represents the type of action a player can take
type PlayerActionType string

const (
	ActionPlayCard PlayerActionType = "PLAY_CARD"
	ActionPass     PlayerActionType = "PASS"
)

// PlayerAction represents a player's action in objection-based gameplay
type PlayerAction struct {
	Type     PlayerActionType `json:"type"`
	Card     *Card            `json:"card,omitempty"` // nil for PASS
	PlayerID uuid.UUID        `json:"player_id"`
}

// Card represents a playing card
type Card struct {
	Suit  string `json:"suit"`  // hearts, diamonds, clubs, spades
	Value int    `json:"value"` // 7-14 (7,8,9,10,J,Q,K,A)
	ID    string `json:"id"`    // unique identifier for the card instance
}

// GameState represents the complete state of a game
type GameState struct {
	ID                uuid.UUID `json:"id"`
	Player1ID         uuid.UUID `json:"player1_id"`
	Player2ID         uuid.UUID `json:"player2_id"`
	CurrentPlayerID   uuid.UUID `json:"current_player_id"`
	Status            string    `json:"status"` // waiting, in_progress, completed

	// Game configuration
	GameMode          GameMode  `json:"game_mode"`

	// Game state
	Player1Hand       []Card    `json:"player1_hand"`
	Player2Hand       []Card    `json:"player2_hand"`
	TableCards        []Card    `json:"table_cards"`
	Deck              []Card    `json:"deck"`

	// Objection system (Authentic Romanian Septica)
	WaitingForObjection bool      `json:"waiting_for_objection"`
	ObjectionDeadline   *time.Time `json:"objection_deadline,omitempty"`
	LastPlayedCard      *Card     `json:"last_played_card,omitempty"`

	// Score tracking
	Player1Score      int       `json:"player1_score"`
	Player2Score      int       `json:"player2_score"`
	TrickNumber       int       `json:"trick_number"`
	MoveNumber        int       `json:"move_number"`

	// Timing
	CreatedAt         time.Time `json:"created_at"`
	StartedAt         *time.Time `json:"started_at"`
	LastMoveAt        *time.Time `json:"last_move_at"`

	// Multiplayer sync
	SequenceNumber    int       `json:"sequence_number"`
}

// MoveResult represents the result of a move
type MoveResult struct {
	Valid          bool      `json:"valid"`
	Error          string    `json:"error,omitempty"`
	UpdatedState   *GameState `json:"updated_state,omitempty"`
	TrickComplete  bool      `json:"trick_complete"`
	GameComplete   bool      `json:"game_complete"`
	WinnerID       *uuid.UUID `json:"winner_id,omitempty"`
	PointsAwarded  int       `json:"points_awarded"`
}

// Engine manages game logic and state
type Engine struct {
	games map[uuid.UUID]*GameState
}

// NewEngine creates a new game engine
func NewEngine() *Engine {
	return &Engine{
		games: make(map[uuid.UUID]*GameState),
	}
}

// CreateGame creates a new game between two players
func (e *Engine) CreateGame(player1ID, player2ID uuid.UUID) *GameState {
	gameID := uuid.New()

	// Create and shuffle deck (32 cards: 7-14 in all suits)
	deck := createAndShuffleDeck()

	// Deal 4 cards to each player
	player1Hand := deck[:4]
	player2Hand := deck[4:8]
	remainingDeck := deck[8:]

	// Player 1 starts
	game := &GameState{
		ID:                  gameID,
		Player1ID:           player1ID,
		Player2ID:           player2ID,
		CurrentPlayerID:     player1ID,
		Status:              "in_progress",
		GameMode:            TwoPlayers, // Default to 2-player mode
		Player1Hand:         player1Hand,
		Player2Hand:         player2Hand,
		TableCards:          []Card{},
		Deck:                remainingDeck,
		WaitingForObjection: false,
		Player1Score:        0,
		Player2Score:        0,
		TrickNumber:         1,
		MoveNumber:          1,
		CreatedAt:           time.Now(),
		SequenceNumber:      0,
	}

	now := time.Now()
	game.StartedAt = &now

	e.games[gameID] = game

	// Update game metrics
	metrics.ConcurrentGames.Inc()
	metrics.TotalGames.WithLabelValues(string(TwoPlayers)).Inc()

	return game
}

// GetGame retrieves a game by ID
func (e *Engine) GetGame(gameID uuid.UUID) (*GameState, error) {
	game, exists := e.games[gameID]
	if !exists {
		return nil, ErrGameNotFound
	}
	return game, nil
}

// PlayCard attempts to play a card
func (e *Engine) PlayCard(gameID uuid.UUID, playerID uuid.UUID, card Card) (*MoveResult, error) {
	game, err := e.GetGame(gameID)
	if err != nil {
		return nil, err
	}
	
	// Validate game is active
	if game.Status != "in_progress" {
		metrics.GameErrors.WithLabelValues("game_not_active").Inc()
		return &MoveResult{Valid: false, Error: "game not active"}, nil
	}

	// Validate it's the player's turn
	if game.CurrentPlayerID != playerID {
		metrics.GameErrors.WithLabelValues("not_player_turn").Inc()
		return &MoveResult{Valid: false, Error: "not your turn"}, nil
	}

	// Get player's hand
	var playerHand *[]Card
	if playerID == game.Player1ID {
		playerHand = &game.Player1Hand
	} else {
		playerHand = &game.Player2Hand
	}

	// Validate card is in player's hand
	cardIndex := -1
	for i, handCard := range *playerHand {
		if handCard.Suit == card.Suit && handCard.Value == card.Value {
			cardIndex = i
			break
		}
	}

	if cardIndex == -1 {
		metrics.GameErrors.WithLabelValues("card_not_in_hand").Inc()
		return &MoveResult{Valid: false, Error: "card not in hand"}, nil
	}

	// Validate the move according to Septica rules
	if !isValidMove(card, game.TableCards, game.GameMode) {
		metrics.GameErrors.WithLabelValues("invalid_move").Inc()
		return &MoveResult{Valid: false, Error: "cannot beat current card"}, nil
	}
	
	// Execute the move
	// Remove card from player's hand
	*playerHand = append((*playerHand)[:cardIndex], (*playerHand)[cardIndex+1:]...)
	
	// Add card to table
	game.TableCards = append(game.TableCards, card)
	game.MoveNumber++
	game.SequenceNumber++
	now := time.Now()
	game.LastMoveAt = &now
	
	// Determine opponent
	opponentID := game.Player2ID
	var opponentHand []Card
	if playerID == game.Player2ID {
		opponentID = game.Player1ID
		opponentHand = game.Player1Hand
	} else {
		opponentHand = game.Player2Hand
	}

	// Always switch turn first
	game.CurrentPlayerID = opponentID

	// Then check if trick is complete (opponent cannot beat the current card)
	trickComplete := !hasValidMoves(opponentHand, game.TableCards, game.GameMode)
	pointsAwarded := 0

	if trickComplete {
		// Award points and start new trick
		pointsAwarded = calculatePoints(game.TableCards)
		if playerID == game.Player1ID {
			game.Player1Score += pointsAwarded
		} else {
			game.Player2Score += pointsAwarded
		}

		// Clear table and start new trick
		game.TableCards = []Card{}
		game.TrickNumber++

		// Winner of trick gets the next turn (switch back to the player who won)
		game.CurrentPlayerID = playerID

		// Deal new cards if deck not empty
		dealNewCards(game)
	}
	
	// Check if game is complete
	gameComplete := isGameComplete(game)
	var winnerID *uuid.UUID
	if gameComplete {
		game.Status = "completed"
		if game.Player1Score > game.Player2Score {
			winnerID = &game.Player1ID
		} else if game.Player2Score > game.Player1Score {
			winnerID = &game.Player2ID
		}
		// Draw case: winnerID remains nil

		// Update game metrics
		metrics.ConcurrentGames.Dec()
		if game.StartedAt != nil {
			duration := time.Since(*game.StartedAt).Seconds()
			metrics.GameDuration.WithLabelValues(string(game.GameMode)).Observe(duration)
		}
	}
	
	return &MoveResult{
		Valid:         true,
		UpdatedState:  game,
		TrickComplete: trickComplete,
		GameComplete:  gameComplete,
		WinnerID:      winnerID,
		PointsAwarded: pointsAwarded,
	}, nil
}

// Helper functions

func createAndShuffleDeck() []Card {
	suits := []string{"hearts", "diamonds", "clubs", "spades"}
	values := []int{7, 8, 9, 10, 11, 12, 13, 14} // J=11, Q=12, K=13, A=14
	
	var deck []Card
	for _, suit := range suits {
		for _, value := range values {
			card := Card{
				Suit:  suit,
				Value: value,
				ID:    uuid.New().String(),
			}
			deck = append(deck, card)
		}
	}
	
	// Shuffle deck
	rand.Seed(time.Now().UnixNano())
	for i := len(deck) - 1; i > 0; i-- {
		j := rand.Intn(i + 1)
		deck[i], deck[j] = deck[j], deck[i]
	}
	
	return deck
}

func isValidMove(card Card, tableCards []Card, gameMode GameMode) bool {
	// If table is empty, any card is valid
	if len(tableCards) == 0 {
		return true
	}

	topCard := tableCards[len(tableCards)-1]

	// Romanian Septica rules:
	// 1. 7s always beat everything (wild cards in all modes)
	if card.Value == 7 {
		return true
	}

	// 2. Same value beats
	if card.Value == topCard.Value {
		// If both are 7s, check suit priority (spades > hearts > diamonds > clubs)
		if card.Value == 7 {
			return getSuitPriority(card.Suit) > getSuitPriority(topCard.Suit)
		}
		return true
	}

	// 3. 8s are wild ONLY in 3-player mode (with 30-card deck)
	if gameMode == ThreePlayers && card.Value == 8 {
		return true
	}

	return false
}

// getSuitPriority returns the priority value for suits in Romanian Septica
// spades (4) > hearts (3) > diamonds (2) > clubs (1)
func getSuitPriority(suit string) int {
	switch suit {
	case "spades":
		return 4
	case "hearts":
		return 3
	case "diamonds":
		return 2
	case "clubs":
		return 1
	default:
		return 0
	}
}

func hasValidMoves(hand []Card, tableCards []Card, gameMode GameMode) bool {
	for _, card := range hand {
		if isValidMove(card, tableCards, gameMode) {
			return true
		}
	}
	return false
}

func calculatePoints(tableCards []Card) int {
	points := 0
	for _, card := range tableCards {
		// 10s and Aces are worth 1 point each
		if card.Value == 10 || card.Value == 14 {
			points++
		}
	}
	return points
}

func dealNewCards(game *GameState) {
	// Deal one card to each player if deck has cards
	cardsNeeded := 0
	if len(game.Player1Hand) < 4 && len(game.Deck) > 0 {
		cardsNeeded++
	}
	if len(game.Player2Hand) < 4 && len(game.Deck) > cardsNeeded {
		cardsNeeded++
	}
	
	if cardsNeeded > 0 && len(game.Deck) >= cardsNeeded {
		if len(game.Player1Hand) < 4 {
			game.Player1Hand = append(game.Player1Hand, game.Deck[0])
			game.Deck = game.Deck[1:]
		}
		if len(game.Player2Hand) < 4 && len(game.Deck) > 0 {
			game.Player2Hand = append(game.Player2Hand, game.Deck[0])
			game.Deck = game.Deck[1:]
		}
	}
}

func isGameComplete(game *GameState) bool {
	// Game is complete when both players have no cards and deck is empty
	return len(game.Player1Hand) == 0 && len(game.Player2Hand) == 0 && len(game.Deck) == 0
}

// GetPlayerHand returns the hand for a specific player (for authorized access)
func (e *Engine) GetPlayerHand(gameID uuid.UUID, playerID uuid.UUID) ([]Card, error) {
	game, err := e.GetGame(gameID)
	if err != nil {
		return nil, err
	}
	
	if playerID == game.Player1ID {
		return game.Player1Hand, nil
	} else if playerID == game.Player2ID {
		return game.Player2Hand, nil
	}
	
	return nil, errors.New("player not in game")
}

// GetValidMoves returns valid moves for a player
func (e *Engine) GetValidMoves(gameID uuid.UUID, playerID uuid.UUID) ([]Card, error) {
	game, err := e.GetGame(gameID)
	if err != nil {
		return nil, err
	}
	
	hand, err := e.GetPlayerHand(gameID, playerID)
	if err != nil {
		return nil, err
	}
	
	var validMoves []Card
	for _, card := range hand {
		if isValidMove(card, game.TableCards, game.GameMode) {
			validMoves = append(validMoves, card)
		}
	}
	
	return validMoves, nil
}