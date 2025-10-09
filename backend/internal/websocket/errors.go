package websocket

import "errors"

// WebSocket-specific errors
var (
	ErrClientNotFound      = errors.New("client not found")
	ErrClientAlreadyInGame = errors.New("client already in a game")
	ErrGameNotFound        = errors.New("game not found")
	ErrGameFull            = errors.New("game is full")
	ErrInvalidMessage      = errors.New("invalid message format")
	ErrNotAuthenticated    = errors.New("client not authenticated")
	ErrConnectionClosed    = errors.New("connection closed")
	ErrMessageQueueFull    = errors.New("message queue full")
	ErrRateLimitExceeded   = errors.New("rate limit exceeded")
	ErrInvalidGameState    = errors.New("invalid game state")
	ErrPlayerNotInGame     = errors.New("player not in game")
	ErrInvalidMove         = errors.New("invalid move")
	ErrNotPlayerTurn       = errors.New("not player's turn")
	ErrGameAlreadyStarted  = errors.New("game already started")
	ErrGameNotStarted      = errors.New("game not started")
	ErrInsufficientPlayers = errors.New("insufficient players to start game")
	ErrSessionExpired      = errors.New("session expired")
	ErrDuplicateConnection = errors.New("duplicate connection for user")
)

// Error codes for client communication
const (
	ErrorCodeClientNotFound      = 1001
	ErrorCodeClientAlreadyInGame = 1002
	ErrorCodeGameNotFound        = 1003
	ErrorCodeGameFull            = 1004
	ErrorCodeInvalidMessage      = 1005
	ErrorCodeNotAuthenticated    = 1006
	ErrorCodeConnectionClosed    = 1007
	ErrorCodeMessageQueueFull    = 1008
	ErrorCodeRateLimitExceeded   = 1009
	ErrorCodeInvalidGameState    = 1010
	ErrorCodePlayerNotInGame     = 1011
	ErrorCodeInvalidMove         = 1012
	ErrorCodeNotPlayerTurn       = 1013
	ErrorCodeGameAlreadyStarted  = 1014
	ErrorCodeGameNotStarted      = 1015
	ErrorCodeInsufficientPlayers = 1016
	ErrorCodeSessionExpired      = 1017
	ErrorCodeDuplicateConnection = 1018
)

// ErrorWithCode represents an error with an associated error code
type ErrorWithCode struct {
	Err  error
	Code int
}

// Error implements the error interface
func (e ErrorWithCode) Error() string {
	return e.Err.Error()
}

// NewErrorWithCode creates a new error with an associated code
func NewErrorWithCode(err error, code int) ErrorWithCode {
	return ErrorWithCode{
		Err:  err,
		Code: code,
	}
}

// GetErrorCode returns the error code for a given error
func GetErrorCode(err error) int {
	switch err {
	case ErrClientNotFound:
		return ErrorCodeClientNotFound
	case ErrClientAlreadyInGame:
		return ErrorCodeClientAlreadyInGame
	case ErrGameNotFound:
		return ErrorCodeGameNotFound
	case ErrGameFull:
		return ErrorCodeGameFull
	case ErrInvalidMessage:
		return ErrorCodeInvalidMessage
	case ErrNotAuthenticated:
		return ErrorCodeNotAuthenticated
	case ErrConnectionClosed:
		return ErrorCodeConnectionClosed
	case ErrMessageQueueFull:
		return ErrorCodeMessageQueueFull
	case ErrRateLimitExceeded:
		return ErrorCodeRateLimitExceeded
	case ErrInvalidGameState:
		return ErrorCodeInvalidGameState
	case ErrPlayerNotInGame:
		return ErrorCodePlayerNotInGame
	case ErrInvalidMove:
		return ErrorCodeInvalidMove
	case ErrNotPlayerTurn:
		return ErrorCodeNotPlayerTurn
	case ErrGameAlreadyStarted:
		return ErrorCodeGameAlreadyStarted
	case ErrGameNotStarted:
		return ErrorCodeGameNotStarted
	case ErrInsufficientPlayers:
		return ErrorCodeInsufficientPlayers
	case ErrSessionExpired:
		return ErrorCodeSessionExpired
	case ErrDuplicateConnection:
		return ErrorCodeDuplicateConnection
	default:
		return 0 // Unknown error
	}
}

// IsWebSocketError checks if an error is a WebSocket-specific error
func IsWebSocketError(err error) bool {
	return GetErrorCode(err) != 0
}
