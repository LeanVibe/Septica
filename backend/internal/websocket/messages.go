package websocket

import (
	"time"

	"github.com/google/uuid"
)

// Message represents an outbound message sent to clients
type Message struct {
	Type      string                 `json:"type"`
	ID        string                 `json:"id"`
	PlayerID  uuid.UUID              `json:"player_id,omitempty"`
	GameID    *uuid.UUID             `json:"game_id,omitempty"`
	Timestamp time.Time              `json:"timestamp"`
	Payload   map[string]interface{} `json:"payload,omitempty"`
}

// IncomingMessage represents an inbound message received from clients
type IncomingMessage struct {
	Type    string      `json:"type"`
	ID      string      `json:"id,omitempty"`
	GameID  *uuid.UUID  `json:"game_id,omitempty"`
	Payload interface{} `json:"payload,omitempty"`
}

// Message types for client-server communication

// Connection management messages
const (
	// Client -> Server
	MessageTypePing             = "ping"
	MessageTypeJoinGame         = "join_game"
	MessageTypeLeaveGame        = "leave_game"
	MessageTypePlayCard         = "play_card"
	MessageTypeGetGameState     = "get_game_state"
	MessageTypeChatMessage      = "chat_message"
	MessageTypeJoinMatchmaking  = "join_matchmaking"
	MessageTypeLeaveMatchmaking = "leave_matchmaking"
	MessageTypeMatchmakingStatus = "matchmaking_status"

	// Server -> Client
	MessageTypePong                = "pong"
	MessageTypeConnectionAck       = "connection_ack"
	MessageTypeError               = "error"
	MessageTypeGameState           = "game_state"
	MessageTypeMoveResult          = "move_result"
	MessageTypePlayerJoined        = "player_joined"
	MessageTypePlayerLeft          = "player_left"
	MessageTypeGameEnd             = "game_end"
	MessageTypeHeartbeat           = "heartbeat"
	MessageTypeChatReceived        = "chat_received"
	MessageTypeMatchmakingJoined   = "matchmaking_joined"
	MessageTypeMatchmakingUpdate   = "matchmaking_update"
	MessageTypeMatchFound          = "match_found"
	MessageTypeMatchmakingLeft     = "matchmaking_left"
	MessageTypeMatchmakingError    = "matchmaking_error"

	// Game state notifications
	MessageTypeGameStarted    = "game_started"
	MessageTypeTrickComplete  = "trick_complete"
	MessageTypePlayerTurn     = "player_turn"
	MessageTypeGamePaused     = "game_paused"
	MessageTypeGameResumed    = "game_resumed"
)

// Error types for consistent error handling
const (
	ErrorTypeInvalidMessage     = "invalid_message"
	ErrorTypeNotAuthorized      = "not_authorized"
	ErrorTypeGameNotFound       = "game_not_found"
	ErrorTypePlayerNotInGame    = "player_not_in_game"
	ErrorTypeInvalidMove        = "invalid_move"
	ErrorTypeNotPlayerTurn      = "not_player_turn"
	ErrorTypeGameFull           = "game_full"
	ErrorTypeConnectionFailed   = "connection_failed"
	ErrorTypeRateLimited        = "rate_limited"
	ErrorTypeServerError        = "server_error"
)

// Payload structures for specific message types

// JoinGamePayload represents the payload for join_game messages
type JoinGamePayload struct {
	GameMode string `json:"game_mode,omitempty"` // "ranked", "casual", "custom"
}

// JoinMatchmakingPayload represents the payload for join_matchmaking messages
type JoinMatchmakingPayload struct {
	QueueType string `json:"queue_type"` // "ranked", "casual", "tournament"
	GameMode  string `json:"game_mode"`  // "septica"
}

// PlayCardPayload represents the payload for play_card messages
type PlayCardPayload struct {
	Suit  string `json:"suit"`
	Value int    `json:"value"`
	ID    string `json:"id,omitempty"`
}

// ChatMessagePayload represents the payload for chat messages
type ChatMessagePayload struct {
	Message string `json:"message"`
	Type    string `json:"type,omitempty"` // "text", "emote"
}

// GameStatePayload represents the game state sent to clients
type GameStatePayload struct {
	GameID             uuid.UUID `json:"game_id"`
	CurrentPlayerID    uuid.UUID `json:"current_player_id"`
	YourTurn           bool      `json:"your_turn"`
	YourCards          []Card    `json:"your_cards"`
	OpponentCardCount  int       `json:"opponent_card_count"`
	TableCards         []Card    `json:"table_cards"`
	ValidMoves         []Card    `json:"valid_moves"`
	Scores             map[string]int `json:"scores"`
	TrickNumber        int       `json:"trick_number"`
	MoveNumber         int       `json:"move_number"`
	SequenceNumber     int       `json:"sequence_number"`
	Status             string    `json:"status"`
}

// Card represents a playing card in message payloads
type Card struct {
	Suit  string `json:"suit"`
	Value int    `json:"value"`
	ID    string `json:"id"`
}

// MoveResultPayload represents the result of a move attempt
type MoveResultPayload struct {
	Valid          bool   `json:"valid"`
	Error          string `json:"error,omitempty"`
	TrickComplete  bool   `json:"trick_complete"`
	GameComplete   bool   `json:"game_complete"`
	WinnerID       *uuid.UUID `json:"winner_id,omitempty"`
	PointsAwarded  int    `json:"points_awarded"`
}

// PlayerJoinedPayload represents a player joining notification
type PlayerJoinedPayload struct {
	PlayerID uuid.UUID `json:"player_id"`
	Username string    `json:"username,omitempty"`
}

// PlayerLeftPayload represents a player leaving notification
type PlayerLeftPayload struct {
	PlayerID uuid.UUID `json:"player_id"`
	Reason   string    `json:"reason,omitempty"` // "disconnected", "quit", "timeout"
}

// GameEndPayload represents game completion notification
type GameEndPayload struct {
	WinnerID   *uuid.UUID `json:"winner_id,omitempty"`
	Reason     string     `json:"reason"`           // "normal", "disconnection", "timeout", "forfeit"
	FinalScore map[string]int `json:"final_score"`
	GameStats  GameStats  `json:"game_stats,omitempty"`
}

// GameStats provides summary statistics for a completed game
type GameStats struct {
	Duration        int64 `json:"duration_ms"`
	TotalMoves      int   `json:"total_moves"`
	TotalTricks     int   `json:"total_tricks"`
	SevensPlayed    int   `json:"sevens_played"`
	EightsPlayed    int   `json:"eights_played"`
	PointCardsWon   map[string]int `json:"point_cards_won"`
}

// ConnectionAckPayload represents connection acknowledgment data
type ConnectionAckPayload struct {
	SessionID         string    `json:"session_id"`
	ServerTime        time.Time `json:"server_time"`
	HeartbeatInterval int       `json:"heartbeat_interval"` // milliseconds
	MaxMessageQueue   int       `json:"max_message_queue"`
	ServerVersion     string    `json:"server_version,omitempty"`
}

// ErrorPayload represents error message data
type ErrorPayload struct {
	ErrorType string `json:"error_type"`
	Message   string `json:"message"`
	Code      int    `json:"code,omitempty"`
	Details   map[string]interface{} `json:"details,omitempty"`
}

// HeartbeatPayload represents heartbeat message data
type HeartbeatPayload struct {
	ServerTime   time.Time `json:"server_time"`
	ClientCount  int       `json:"client_count,omitempty"`
	ActiveGames  int       `json:"active_games,omitempty"`
}

// MatchFoundPayload represents a match found notification
type MatchFoundPayload struct {
	GameID         uuid.UUID `json:"game_id"`
	OpponentID     uuid.UUID `json:"opponent_id"`
	OpponentRating int       `json:"opponent_rating"`
	OpponentName   string    `json:"opponent_name"`
	WaitTimeMs     int64     `json:"wait_time_ms"`
}

// MatchmakingUpdatePayload represents matchmaking queue status updates
type MatchmakingUpdatePayload struct {
	QueuePosition     int `json:"queue_position"`
	EstimatedWaitTime int `json:"estimated_wait_time_seconds"`
	SearchRange       int `json:"search_range"`
	PlayersInQueue    int `json:"players_in_queue"`
	WaitTime          int `json:"wait_time_seconds"`
}

// MatchmakingJoinedPayload represents successful queue join
type MatchmakingJoinedPayload struct {
	QueueType string `json:"queue_type"`
	Message   string `json:"message"`
}

// MatchmakingLeftPayload represents successful queue leave
type MatchmakingLeftPayload struct {
	Message string `json:"message"`
}

// MatchmakingErrorPayload represents matchmaking errors
type MatchmakingErrorPayload struct {
	ErrorType string `json:"error_type"`
	Message   string `json:"message"`
}

// Helper functions for creating common messages

// NewConnectionAck creates a connection acknowledgment message
func NewConnectionAck(playerID uuid.UUID, sessionID string) Message {
	return Message{
		Type:      MessageTypeConnectionAck,
		ID:        uuid.New().String(),
		PlayerID:  playerID,
		Timestamp: time.Now(),
		Payload: map[string]interface{}{
			"session_id":         sessionID,
			"server_time":        time.Now(),
			"heartbeat_interval": 30000,
			"max_message_queue":  100,
			"server_version":     "1.0.0",
		},
	}
}

// NewError creates an error message
func NewError(playerID uuid.UUID, errorType, message string) Message {
	return Message{
		Type:      MessageTypeError,
		ID:        uuid.New().String(),
		PlayerID:  playerID,
		Timestamp: time.Now(),
		Payload: map[string]interface{}{
			"error_type": errorType,
			"message":    message,
		},
	}
}

// NewHeartbeat creates a heartbeat message
func NewHeartbeat() Message {
	return Message{
		Type:      MessageTypeHeartbeat,
		ID:        uuid.New().String(),
		Timestamp: time.Now(),
		Payload: map[string]interface{}{
			"server_time": time.Now(),
		},
	}
}

// NewGameState creates a game state message
func NewGameState(playerID uuid.UUID, gameID uuid.UUID, payload map[string]interface{}) Message {
	return Message{
		Type:      MessageTypeGameState,
		ID:        uuid.New().String(),
		PlayerID:  playerID,
		GameID:    &gameID,
		Timestamp: time.Now(),
		Payload:   payload,
	}
}

// NewMoveResult creates a move result message
func NewMoveResult(playerID uuid.UUID, gameID uuid.UUID, result MoveResultPayload) Message {
	return Message{
		Type:      MessageTypeMoveResult,
		ID:        uuid.New().String(),
		PlayerID:  playerID,
		GameID:    &gameID,
		Timestamp: time.Now(),
		Payload: map[string]interface{}{
			"valid":          result.Valid,
			"error":          result.Error,
			"trick_complete": result.TrickComplete,
			"game_complete":  result.GameComplete,
			"winner_id":      result.WinnerID,
			"points_awarded": result.PointsAwarded,
		},
	}
}