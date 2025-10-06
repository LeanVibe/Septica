package websocket

import (
	"encoding/json"
	"sync"
	"time"

	"septica-backend/internal/game"

	"github.com/google/uuid"
)

// SessionStore manages active game sessions for reconnection support
// Stores game state snapshots and player session data for recovery
type SessionStore struct {
	sessions map[string]*GameSession // sessionID -> GameSession
	mutex    sync.RWMutex

	// Configuration
	sessionTimeout time.Duration // How long to keep inactive sessions
}

// GameSession represents a stored session for reconnection
type GameSession struct {
	SessionID       string                  `json:"session_id"`
	UserID          uuid.UUID               `json:"user_id"`
	GameID          *uuid.UUID              `json:"game_id"`
	LastActiveAt    time.Time               `json:"last_active_at"`
	CreatedAt       time.Time               `json:"created_at"`

	// Game state snapshot for recovery
	GameState       *game.AuthenticGameState `json:"game_state"`
	SequenceNumber  int                      `json:"sequence_number"`

	// Connection metadata
	RemoteAddr      string                  `json:"remote_addr"`
	UserAgent       string                  `json:"user_agent"`
	ReconnectCount  int                     `json:"reconnect_count"`
}

// NewSessionStore creates a new session store
func NewSessionStore(sessionTimeout time.Duration) *SessionStore {
	store := &SessionStore{
		sessions:       make(map[string]*GameSession),
		sessionTimeout: sessionTimeout,
	}

	// Start cleanup goroutine for expired sessions
	go store.cleanupExpiredSessions()

	return store
}

// StoreSession saves or updates a session
func (s *SessionStore) StoreSession(session *GameSession) {
	s.mutex.Lock()
	defer s.mutex.Unlock()

	session.LastActiveAt = time.Now()
	s.sessions[session.SessionID] = session
}

// GetSession retrieves a session by ID
func (s *SessionStore) GetSession(sessionID string) (*GameSession, bool) {
	s.mutex.RLock()
	defer s.mutex.RUnlock()

	session, exists := s.sessions[sessionID]
	if !exists {
		return nil, false
	}

	// Check if session has expired
	if time.Since(session.LastActiveAt) > s.sessionTimeout {
		return nil, false
	}

	return session, true
}

// UpdateSessionActivity updates the last active timestamp
func (s *SessionStore) UpdateSessionActivity(sessionID string) {
	s.mutex.Lock()
	defer s.mutex.Unlock()

	if session, exists := s.sessions[sessionID]; exists {
		session.LastActiveAt = time.Now()
	}
}

// UpdateSessionGameState updates the game state snapshot for a session
func (s *SessionStore) UpdateSessionGameState(sessionID string, gameState *game.AuthenticGameState, sequenceNumber int) {
	s.mutex.Lock()
	defer s.mutex.Unlock()

	if session, exists := s.sessions[sessionID]; exists {
		session.GameState = gameState
		session.SequenceNumber = sequenceNumber
		session.LastActiveAt = time.Now()
	}
}

// IncrementReconnectCount increments the reconnection counter for a session
func (s *SessionStore) IncrementReconnectCount(sessionID string) {
	s.mutex.Lock()
	defer s.mutex.Unlock()

	if session, exists := s.sessions[sessionID]; exists {
		session.ReconnectCount++
		session.LastActiveAt = time.Now()
	}
}

// RemoveSession removes a session from the store
func (s *SessionStore) RemoveSession(sessionID string) {
	s.mutex.Lock()
	defer s.mutex.Unlock()

	delete(s.sessions, sessionID)
}

// GetSessionByUserID finds a session by user ID
func (s *SessionStore) GetSessionByUserID(userID uuid.UUID) (*GameSession, bool) {
	s.mutex.RLock()
	defer s.mutex.RUnlock()

	for _, session := range s.sessions {
		if session.UserID == userID {
			// Check if session is still valid
			if time.Since(session.LastActiveAt) <= s.sessionTimeout {
				return session, true
			}
		}
	}

	return nil, false
}

// cleanupExpiredSessions periodically removes expired sessions
func (s *SessionStore) cleanupExpiredSessions() {
	ticker := time.NewTicker(5 * time.Minute)
	defer ticker.Stop()

	for range ticker.C {
		s.mutex.Lock()

		now := time.Now()
		expiredSessions := []string{}

		for sessionID, session := range s.sessions {
			if now.Sub(session.LastActiveAt) > s.sessionTimeout {
				expiredSessions = append(expiredSessions, sessionID)
			}
		}

		for _, sessionID := range expiredSessions {
			delete(s.sessions, sessionID)
		}

		s.mutex.Unlock()

		if len(expiredSessions) > 0 {
			// Log cleanup
			// logger.Info("Cleaned up expired sessions", "count", len(expiredSessions))
		}
	}
}

// GetActiveSessionCount returns the number of active sessions
func (s *SessionStore) GetActiveSessionCount() int {
	s.mutex.RLock()
	defer s.mutex.RUnlock()

	return len(s.sessions)
}

// ExportSessionSnapshot creates a JSON snapshot of a session for client recovery
func (s *SessionStore) ExportSessionSnapshot(sessionID string) (map[string]interface{}, error) {
	s.mutex.RLock()
	defer s.mutex.RUnlock()

	session, exists := s.sessions[sessionID]
	if !exists {
		return nil, nil
	}

	// Convert game state to map for client
	snapshot := make(map[string]interface{})

	if session.GameState != nil {
		gameStateBytes, err := json.Marshal(session.GameState)
		if err != nil {
			return nil, err
		}

		var gameStateMap map[string]interface{}
		if err := json.Unmarshal(gameStateBytes, &gameStateMap); err != nil {
			return nil, err
		}

		snapshot["game_state"] = gameStateMap
	}

	snapshot["session_id"] = session.SessionID
	snapshot["game_id"] = session.GameID
	snapshot["sequence_number"] = session.SequenceNumber
	snapshot["last_active_at"] = session.LastActiveAt
	snapshot["reconnect_count"] = session.ReconnectCount

	return snapshot, nil
}
