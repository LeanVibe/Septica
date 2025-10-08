package game

import (
	"errors"
	"math/rand"
	"time"

	"septica-backend/internal/database"
	"septica-backend/pkg/logger"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

var (
	// Authentic Septica specific errors
	ErrWaitingForObjection = errors.New("waiting for objection decision")
	ErrNotObjectionPhase   = errors.New("not in objection phase")
	ErrInvalidTeamPlay     = errors.New("invalid team play configuration")
	ErrUnsupportedGameMode = errors.New("unsupported game mode")
)

// AuthenticGameMode represents different player configurations
type AuthenticGameMode string

const (
	ModeTwoPlayer    AuthenticGameMode = "2_player"    // Individual play
	ModeThreePlayer  AuthenticGameMode = "3_player"    // Individual with wild 8s
	ModeFourPlayer   AuthenticGameMode = "4_player"    // Team play (1+3 vs 2+4)
)

// AuthenticGameState represents the complete state of an authentic Romanian Septica game
type AuthenticGameState struct {
	ID              uuid.UUID         `json:"id"`
	Players         []uuid.UUID       `json:"players"`          // 2-4 players in turn order
	Teams           [][]uuid.UUID     `json:"teams,omitempty"`  // For 4-player team mode
	CurrentPlayerID uuid.UUID         `json:"current_player_id"`
	Status          string            `json:"status"`           // waiting, playing, finished
	GameMode        AuthenticGameMode `json:"game_mode"`

	// Objection-based game state
	WaitingForObjection bool          `json:"waiting_for_objection"`
	LastPlayedCard     *Card         `json:"last_played_card,omitempty"`
	LastPlayerID       uuid.UUID     `json:"last_player_id,omitempty"`
	TableCards         []Card        `json:"table_cards"`

	// Player hands and scores (indexed by player position)
	PlayerHands     map[uuid.UUID][]Card `json:"player_hands"`
	PlayerScores    map[uuid.UUID]int    `json:"player_scores"`
	TeamScores      map[string]int       `json:"team_scores,omitempty"` // "team1", "team2"

	// Deck management
	Deck            []Card        `json:"deck"`
	WildEights      bool          `json:"wild_eights"`  // true for 3-player variant

	// Game progression
	RoundNumber     int           `json:"round_number"`
	MoveNumber      int           `json:"move_number"`
	SequenceNumber  int           `json:"sequence_number"`

	// Timing
	CreatedAt       time.Time     `json:"created_at"`
	StartedAt       *time.Time    `json:"started_at"`
	LastMoveAt      *time.Time    `json:"last_move_at"`
}

// AuthenticPlayerAction represents a player's action in authentic Septica
type AuthenticPlayerAction struct {
	Type     string    `json:"type"`      // "PLAY_CARD" or "PASS"
	PlayerID uuid.UUID `json:"player_id"`
	Card     *Card     `json:"card,omitempty"` // nil for PASS
}

// AuthenticMoveResult represents the result of a move in authentic Septica
type AuthenticMoveResult struct {
	Valid              bool                `json:"valid"`
	Error              string              `json:"error,omitempty"`
	UpdatedState       *AuthenticGameState `json:"updated_state,omitempty"`
	RoundComplete      bool                `json:"round_complete"`
	GameComplete       bool                `json:"game_complete"`
	WinnerID           *uuid.UUID          `json:"winner_id,omitempty"`
	WinningTeam        *string             `json:"winning_team,omitempty"` // "team1", "team2"
	PointsAwarded      int                 `json:"points_awarded"`
	CollectorPlayerID  *uuid.UUID          `json:"collector_player_id,omitempty"`
	ObjectionPhase     bool                `json:"objection_phase"`
	NextPlayerID       uuid.UUID           `json:"next_player_id"`
}

// RoundResult represents the outcome of a completed round
type RoundResult struct {
	WinnerID       uuid.UUID `json:"winner_id"`
	PointsAwarded  int       `json:"points_awarded"`
	CardsCollected []Card    `json:"cards_collected"`
	WasObjected    bool      `json:"was_objected"`
}

// AuthenticEngineConfig holds configuration for the authentic engine
type AuthenticEngineConfig struct {
	UseAuthenticRules bool          `json:"use_authentic_rules"`
	DefaultGameMode   AuthenticGameMode `json:"default_game_mode"`
	MaxGameDuration   time.Duration `json:"max_game_duration"`
	ObjectionTimeout  time.Duration `json:"objection_timeout"`
}

// AuthenticEngine manages authentic Romanian Septica game logic
type AuthenticEngine struct {
	games  map[uuid.UUID]*AuthenticGameState
	config *AuthenticEngineConfig
	db     *gorm.DB
	logger *logger.Logger
}

// NewAuthenticEngine creates a new authentic game engine
func NewAuthenticEngine() *AuthenticEngine {
	return &AuthenticEngine{
		games: make(map[uuid.UUID]*AuthenticGameState),
		config: &AuthenticEngineConfig{
			UseAuthenticRules: true,
			DefaultGameMode:   ModeTwoPlayer,
			MaxGameDuration:   30 * time.Minute,
			ObjectionTimeout:  30 * time.Second,
		},
		db:     nil,
		logger: nil,
	}
}

// NewAuthenticEngineWithDB creates a new authentic game engine with database persistence
func NewAuthenticEngineWithDB(db *gorm.DB, logger *logger.Logger) *AuthenticEngine {
	return &AuthenticEngine{
		games: make(map[uuid.UUID]*AuthenticGameState),
		config: &AuthenticEngineConfig{
			UseAuthenticRules: true,
			DefaultGameMode:   ModeTwoPlayer,
			MaxGameDuration:   30 * time.Minute,
			ObjectionTimeout:  30 * time.Second,
		},
		db:     db,
		logger: logger,
	}
}

// CreateGame creates a new authentic Romanian Septica game
func (e *AuthenticEngine) CreateGame(playerIDs []uuid.UUID, gameMode AuthenticGameMode) (*AuthenticGameState, error) {
	if len(playerIDs) < 2 || len(playerIDs) > 4 {
		return nil, errors.New("invalid number of players: must be 2-4")
	}

	// Validate game mode matches player count
	if err := validateGameModeAndPlayers(gameMode, len(playerIDs)); err != nil {
		return nil, err
	}

	gameID := uuid.New()

	// Create authentic deck based on player count
	deck := createAuthenticDeck(gameMode)

	// Deal 4 cards to each player
	playerHands, remainingDeck := dealAuthenticCards(deck, playerIDs)

	// Initialize scores
	playerScores := make(map[uuid.UUID]int)
	for _, playerID := range playerIDs {
		playerScores[playerID] = 0
	}

	// Setup teams for 4-player mode
	var teams [][]uuid.UUID
	var teamScores map[string]int
	if gameMode == ModeFourPlayer {
		teams = [][]uuid.UUID{
			{playerIDs[0], playerIDs[2]}, // Team 1: Player 1 + Player 3
			{playerIDs[1], playerIDs[3]}, // Team 2: Player 2 + Player 4
		}
		teamScores = map[string]int{"team1": 0, "team2": 0}
	}

	// First player starts
	game := &AuthenticGameState{
		ID:              gameID,
		Players:         playerIDs,
		Teams:           teams,
		CurrentPlayerID: playerIDs[0],
		Status:          "playing",
		GameMode:        gameMode,

		// Objection state
		WaitingForObjection: false,
		LastPlayedCard:     nil,
		LastPlayerID:       uuid.Nil,
		TableCards:         []Card{},

		// Player data
		PlayerHands:     playerHands,
		PlayerScores:    playerScores,
		TeamScores:      teamScores,

		// Deck
		Deck:            remainingDeck,
		WildEights:      gameMode == ModeThreePlayer,

		// Progression
		RoundNumber:     1,
		MoveNumber:      1,
		SequenceNumber:  0,

		// Timing
		CreatedAt:       time.Now(),
	}

	now := time.Now()
	game.StartedAt = &now

	e.games[gameID] = game
	return game, nil
}

// GetGame retrieves an authentic game by ID
func (e *AuthenticEngine) GetGame(gameID uuid.UUID) (*AuthenticGameState, error) {
	game, exists := e.games[gameID]
	if !exists {
		return nil, ErrGameNotFound
	}
	return game, nil
}

// ProcessAction processes a player action (PLAY_CARD or PASS)
func (e *AuthenticEngine) ProcessAction(gameID uuid.UUID, action AuthenticPlayerAction) (*AuthenticMoveResult, error) {
	game, err := e.GetGame(gameID)
	if err != nil {
		return nil, err
	}

	// Validate game is active
	if game.Status != "playing" {
		return &AuthenticMoveResult{Valid: false, Error: "game not active"}, nil
	}

	// Validate it's the player's turn OR they're in objection phase
	if !game.WaitingForObjection && game.CurrentPlayerID != action.PlayerID {
		return &AuthenticMoveResult{Valid: false, Error: "not your turn"}, nil
	}

	if game.WaitingForObjection && !isNextPlayerForObjection(game, action.PlayerID) {
		return &AuthenticMoveResult{Valid: false, Error: "not your turn to object"}, nil
	}

	// Create move record for database persistence
	moveRecord := &database.GameMove{
		GameID:         gameID, // ✅ game_id explicitly set
		PlayerID:       action.PlayerID,
		MoveNumber:     game.MoveNumber,
		MoveType:       action.Type,
		TrickNumber:    game.RoundNumber,
		TableCardCount: len(game.TableCards),
		IsObjection:    game.WaitingForObjection,
	}

	// Add card details if this is a PLAY_CARD action
	if action.Type == "PLAY_CARD" && action.Card != nil {
		moveRecord.CardSuit = action.Card.Suit
		moveRecord.CardValue = action.Card.Value
	}

	// If this is an objection, record the card being objected to
	if game.WaitingForObjection && game.LastPlayedCard != nil {
		moveRecord.ObjectedCardSuit = &game.LastPlayedCard.Suit
		moveRecord.ObjectedCardValue = &game.LastPlayedCard.Value
	}

	// Process the action based on type
	var result *AuthenticMoveResult
	switch action.Type {
	case "PLAY_CARD":
		result, err = e.processPlayCard(game, action)
	case "PASS":
		result, err = e.processPass(game, action)
	default:
		return &AuthenticMoveResult{Valid: false, Error: "invalid action type"}, nil
	}

	// If move was valid, persist to database
	if result != nil && result.Valid {
		// Update move record with result data
		moveRecord.RoundComplete = result.RoundComplete
		moveRecord.PointsAwarded = result.PointsAwarded
		moveRecord.IsWinningMove = result.GameComplete

		// Persist move to database
		if persistErr := e.RecordMove(gameID, moveRecord); persistErr != nil {
			// Log error but don't fail the move - game state already updated
			if e.logger != nil {
				e.logger.Error("Failed to persist move (move already processed)",
					"error", persistErr,
					"game_id", gameID,
					"player_id", action.PlayerID)
			}
		}
	}

	return result, err
}

// processPlayCard handles playing a card
func (e *AuthenticEngine) processPlayCard(game *AuthenticGameState, action AuthenticPlayerAction) (*AuthenticMoveResult, error) {
	if action.Card == nil {
		return &AuthenticMoveResult{Valid: false, Error: "card required for PLAY_CARD action"}, nil
	}

	// Validate card is in player's hand
	playerHand := game.PlayerHands[action.PlayerID]
	cardIndex := -1
	for i, handCard := range playerHand {
		if handCard.Suit == action.Card.Suit && handCard.Value == action.Card.Value {
			cardIndex = i
			break
		}
	}

	if cardIndex == -1 {
		return &AuthenticMoveResult{Valid: false, Error: "card not in hand"}, nil
	}

	if game.WaitingForObjection {
		// This is an objection attempt
		return e.processObjection(game, action, cardIndex)
	} else {
		// This is the initial card play
		return e.processInitialPlay(game, action, cardIndex)
	}
}

// processInitialPlay handles the first player playing a card
func (e *AuthenticEngine) processInitialPlay(game *AuthenticGameState, action AuthenticPlayerAction, cardIndex int) (*AuthenticMoveResult, error) {
	// Remove card from player's hand
	playerHand := game.PlayerHands[action.PlayerID]
	game.PlayerHands[action.PlayerID] = append(playerHand[:cardIndex], playerHand[cardIndex+1:]...)

	// Add card to table
	game.TableCards = append(game.TableCards, *action.Card)

	// Set objection state
	game.LastPlayedCard = action.Card
	game.LastPlayerID = action.PlayerID
	game.WaitingForObjection = true

	// Determine next player (for objection)
	game.CurrentPlayerID = getNextPlayerID(game, action.PlayerID)

	// Update move tracking
	game.MoveNumber++
	game.SequenceNumber++
	now := time.Now()
	game.LastMoveAt = &now

	return &AuthenticMoveResult{
		Valid:         true,
		UpdatedState:  game,
		RoundComplete: false,
		GameComplete:  false,
		ObjectionPhase: true,
		NextPlayerID:  game.CurrentPlayerID,
	}, nil
}

// processObjection handles a player attempting to object with a card
func (e *AuthenticEngine) processObjection(game *AuthenticGameState, action AuthenticPlayerAction, cardIndex int) (*AuthenticMoveResult, error) {
	// Validate objection is legal
	if !e.canObjectToCard(*game.LastPlayedCard, *action.Card, game.GameMode) {
		return &AuthenticMoveResult{Valid: false, Error: "cannot object with this card"}, nil
	}

	// Execute objection: objecting player takes all cards
	return e.completeRound(game, action.PlayerID, cardIndex, true)
}

// processPass handles a player choosing not to object
func (e *AuthenticEngine) processPass(game *AuthenticGameState, action AuthenticPlayerAction) (*AuthenticMoveResult, error) {
	if !game.WaitingForObjection {
		return &AuthenticMoveResult{Valid: false, Error: "not in objection phase"}, nil
	}

	// Player passes: original player takes all cards
	return e.completeRound(game, game.LastPlayerID, -1, false)
}

// completeRound finishes a round and awards cards to the collector
func (e *AuthenticEngine) completeRound(game *AuthenticGameState, collectorID uuid.UUID, objectionCardIndex int, wasObjected bool) (*AuthenticMoveResult, error) {
	// If there was an objection, add the objection card to table
	if wasObjected && objectionCardIndex >= 0 {
		playerHand := game.PlayerHands[game.CurrentPlayerID]
		objectionCard := playerHand[objectionCardIndex]
		game.PlayerHands[game.CurrentPlayerID] = append(playerHand[:objectionCardIndex], playerHand[objectionCardIndex+1:]...)
		game.TableCards = append(game.TableCards, objectionCard)
	}

	// Calculate points in table cards
	pointsAwarded := calculateAuthenticPoints(game.TableCards)

	// Award points to collector (or their team in 4-player mode)
	if game.GameMode == ModeFourPlayer {
		teamName := getPlayerTeam(game, collectorID)
		game.TeamScores[teamName] += pointsAwarded
	}
	game.PlayerScores[collectorID] += pointsAwarded

	// Clear the table and objection state
	game.TableCards = []Card{}
	game.WaitingForObjection = false
	game.LastPlayedCard = nil
	game.LastPlayerID = uuid.Nil

	// Collector starts the next round
	game.CurrentPlayerID = collectorID
	game.RoundNumber++

	// Deal new cards if needed
	dealNewAuthenticCards(game)

	// Check if game is complete
	gameComplete := isAuthenticGameComplete(game)
	var winnerID *uuid.UUID
	var winningTeam *string

	if gameComplete {
		game.Status = "finished"
		winnerID, winningTeam = determineWinner(game)
	}

	return &AuthenticMoveResult{
		Valid:             true,
		UpdatedState:      game,
		RoundComplete:     true,
		GameComplete:      gameComplete,
		WinnerID:          winnerID,
		WinningTeam:       winningTeam,
		PointsAwarded:     pointsAwarded,
		CollectorPlayerID: &collectorID,
		ObjectionPhase:    false,
		NextPlayerID:      game.CurrentPlayerID,
	}, nil
}

// canObjectToCard determines if a card can be used to object to another card
func (e *AuthenticEngine) CanObjectToCard(playedCard Card, objectionCard Card, gameMode AuthenticGameMode) bool {
	return e.canObjectToCard(playedCard, objectionCard, gameMode)
}

func (e *AuthenticEngine) canObjectToCard(playedCard Card, objectionCard Card, gameMode AuthenticGameMode) bool {
	// 7s always can object (wild cards)
	if objectionCard.Value == 7 {
		return true
	}

	// Same rank can object
	if objectionCard.Value == playedCard.Value {
		return true
	}

	// For 3-player: remaining 8s are wild
	if gameMode == ModeThreePlayer && objectionCard.Value == 8 {
		return true
	}

	return false
}

// Helper functions

func validateGameModeAndPlayers(gameMode AuthenticGameMode, playerCount int) error {
	switch gameMode {
	case ModeTwoPlayer:
		if playerCount != 2 {
			return errors.New("2-player mode requires exactly 2 players")
		}
	case ModeThreePlayer:
		if playerCount != 3 {
			return errors.New("3-player mode requires exactly 3 players")
		}
	case ModeFourPlayer:
		if playerCount != 4 {
			return errors.New("4-player mode requires exactly 4 players")
		}
	default:
		return ErrUnsupportedGameMode
	}
	return nil
}

func createAuthenticDeck(gameMode AuthenticGameMode) []Card {
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

	// For 3-player mode: remove 2 specific eights (keep only 2)
	if gameMode == ModeThreePlayer {
		// Remove two 8s to get 30 cards (traditional Romanian Septica 3-player)
		filteredDeck := []Card{}
		eightsRemoved := 0
		for _, card := range deck {
			if card.Value == 8 && eightsRemoved < 2 {
				eightsRemoved++
				continue // Skip this 8
			}
			filteredDeck = append(filteredDeck, card)
		}
		deck = filteredDeck
	}

	// Shuffle deck
	rand.Seed(time.Now().UnixNano())
	for i := len(deck) - 1; i > 0; i-- {
		j := rand.Intn(i + 1)
		deck[i], deck[j] = deck[j], deck[i]
	}

	return deck
}

func dealAuthenticCards(deck []Card, playerIDs []uuid.UUID) (map[uuid.UUID][]Card, []Card) {
	playerHands := make(map[uuid.UUID][]Card)

	// Deal 4 cards to each player
	cardIndex := 0
	for _, playerID := range playerIDs {
		hand := make([]Card, 4)
		for i := 0; i < 4; i++ {
			hand[i] = deck[cardIndex]
			cardIndex++
		}
		playerHands[playerID] = hand
	}

	// Return remaining deck
	return playerHands, deck[cardIndex:]
}

func dealNewAuthenticCards(game *AuthenticGameState) {
	// Deal one card to each player if they need cards and deck has cards
	for _, playerID := range game.Players {
		if len(game.PlayerHands[playerID]) < 4 && len(game.Deck) > 0 {
			game.PlayerHands[playerID] = append(game.PlayerHands[playerID], game.Deck[0])
			game.Deck = game.Deck[1:]
		}
	}
}

func calculateAuthenticPoints(tableCards []Card) int {
	points := 0
	for _, card := range tableCards {
		// 10s and Aces are worth 1 point each
		if card.Value == 10 || card.Value == 14 {
			points++
		}
	}
	return points
}

func isAuthenticGameComplete(game *AuthenticGameState) bool {
	// Game is complete when all players have no cards and deck is empty
	for _, playerID := range game.Players {
		if len(game.PlayerHands[playerID]) > 0 {
			return false
		}
	}
	return len(game.Deck) == 0
}

func getNextPlayerID(game *AuthenticGameState, currentPlayerID uuid.UUID) uuid.UUID {
	for i, playerID := range game.Players {
		if playerID == currentPlayerID {
			nextIndex := (i + 1) % len(game.Players)
			return game.Players[nextIndex]
		}
	}
	// Fallback to first player if not found
	return game.Players[0]
}

func isNextPlayerForObjection(game *AuthenticGameState, playerID uuid.UUID) bool {
	return game.CurrentPlayerID == playerID
}

func getPlayerTeam(game *AuthenticGameState, playerID uuid.UUID) string {
	if len(game.Teams) < 2 {
		return ""
	}

	// Check team1
	for _, teamPlayerID := range game.Teams[0] {
		if teamPlayerID == playerID {
			return "team1"
		}
	}

	// Must be team2
	return "team2"
}

func determineWinner(game *AuthenticGameState) (*uuid.UUID, *string) {
	if game.GameMode == ModeFourPlayer {
		// Team play: determine winning team
		if game.TeamScores["team1"] > game.TeamScores["team2"] {
			winningTeam := "team1"
			return nil, &winningTeam
		} else if game.TeamScores["team2"] > game.TeamScores["team1"] {
			winningTeam := "team2"
			return nil, &winningTeam
		}
		// Draw case
		return nil, nil
	} else {
		// Individual play: find player with highest score
		var winnerID *uuid.UUID
		highestScore := -1

		for playerID, score := range game.PlayerScores {
			if score > highestScore {
				highestScore = score
				winnerID = &playerID
			} else if score == highestScore {
				// Draw case
				winnerID = nil
			}
		}

		return winnerID, nil
	}
}

// GetPlayerHand returns the hand for a specific player (for authorized access)
func (e *AuthenticEngine) GetPlayerHand(gameID uuid.UUID, playerID uuid.UUID) ([]Card, error) {
	game, err := e.GetGame(gameID)
	if err != nil {
		return nil, err
	}

	hand, exists := game.PlayerHands[playerID]
	if !exists {
		return nil, errors.New("player not in game")
	}

	return hand, nil
}

// RecordMove persists a game move to the database
func (e *AuthenticEngine) RecordMove(gameID uuid.UUID, move *database.GameMove) error {
	if e.db == nil {
		// Database not initialized, skip persistence (for tests or in-memory mode)
		return nil
	}

	// Validate game_id is set
	if move.GameID == uuid.Nil {
		if e.logger != nil {
			e.logger.Error("Attempted to record move without game_id", "player_id", move.PlayerID)
		}
		return errors.New("game_id is required for move recording")
	}

	// Validate player_id is set
	if move.PlayerID == uuid.Nil {
		if e.logger != nil {
			e.logger.Error("Attempted to record move without player_id", "game_id", move.GameID)
		}
		return errors.New("player_id is required for move recording")
	}

	// Persist to database
	if err := e.db.Create(move).Error; err != nil {
		if e.logger != nil {
			e.logger.Error("Failed to persist move to database",
				"error", err,
				"game_id", move.GameID,
				"player_id", move.PlayerID,
				"move_number", move.MoveNumber)
		}
		return err
	}

	if e.logger != nil {
		e.logger.Debug("Move persisted to database",
			"game_id", move.GameID,
			"player_id", move.PlayerID,
			"move_type", move.MoveType,
			"move_number", move.MoveNumber)
	}

	return nil
}

// GetValidMoves returns valid moves for a player in current game state
func (e *AuthenticEngine) GetValidMoves(gameID uuid.UUID, playerID uuid.UUID) ([]Card, error) {
	game, err := e.GetGame(gameID)
	if err != nil {
		return nil, err
	}

	hand, err := e.GetPlayerHand(gameID, playerID)
	if err != nil {
		return nil, err
	}

	// In authentic Septica, valid moves depend on game state:
	if !game.WaitingForObjection {
		// If it's your turn to start a round, any card is valid
		if game.CurrentPlayerID == playerID {
			return hand, nil
		}
		return []Card{}, nil
	} else {
		// If in objection phase, return cards that can object to last played card
		if game.CurrentPlayerID != playerID {
			return []Card{}, nil
		}

		var validMoves []Card
		for _, card := range hand {
			if e.canObjectToCard(*game.LastPlayedCard, card, game.GameMode) {
				validMoves = append(validMoves, card)
			}
		}
		return validMoves, nil
	}
}