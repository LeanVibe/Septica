package ai

import (
	"encoding/json"
	"fmt"
	"sync"
	"time"

	"septica-backend/internal/game"
	"septica-backend/internal/websocket"
	"septica-backend/pkg/logger"

	"github.com/google/uuid"
)

// AIWebSocketClient simulates a WebSocket client for AI players
type AIWebSocketClient struct {
	AI               *AIPlayer             `json:"ai_player"`
	Hub              *websocket.Hub        `json:"-"`
	Logger           *logger.Logger        `json:"-"`
	UserID           uuid.UUID             `json:"user_id"`
	SessionID        uuid.UUID             `json:"session_id"`
	IsConnected      bool                  `json:"is_connected"`
	CurrentGameID    *uuid.UUID            `json:"current_game_id,omitempty"`

	// Virtual connection management
	messageChan      chan websocket.Message `json:"-"`
	stopChan         chan bool              `json:"-"`
	mutex            sync.RWMutex           `json:"-"`

	// Game state tracking
	lastGameState    *game.AuthenticGameState `json:"-"`
	awaitingMove     bool                     `json:"awaiting_move"`
}

// NewAIWebSocketClient creates a new AI WebSocket client
func NewAIWebSocketClient(ai *AIPlayer, hub *websocket.Hub, logger *logger.Logger) *AIWebSocketClient {
	sessionID := uuid.New()

	client := &AIWebSocketClient{
		AI:           ai,
		Hub:          hub,
		Logger:       logger,
		UserID:       ai.ID,
		SessionID:    sessionID,
		messageChan:  make(chan websocket.Message, 100),
		stopChan:     make(chan bool),
	}

	logger.Info("Created AI WebSocket client",
		"ai_id", ai.ID,
		"session_id", sessionID,
		"username", ai.Username)

	return client
}

// Connect simulates connecting to the WebSocket hub
func (c *AIWebSocketClient) Connect() error {
	c.mutex.Lock()
	defer c.mutex.Unlock()

	if c.IsConnected {
		return fmt.Errorf("AI client already connected")
	}

	// Register with the hub as a virtual client
	err := c.Hub.RegisterAIClient(c.UserID, c.SessionID, c)
	if err != nil {
		return fmt.Errorf("failed to register AI client: %w", err)
	}

	c.IsConnected = true

	// Start message processing goroutine
	go c.processMessages()

	c.Logger.Info("AI client connected to WebSocket hub",
		"ai_id", c.AI.ID,
		"session_id", c.SessionID)

	return nil
}

// Disconnect simulates disconnecting from the WebSocket hub
func (c *AIWebSocketClient) Disconnect() error {
	c.mutex.Lock()
	defer c.mutex.Unlock()

	if !c.IsConnected {
		return nil
	}

	// Signal stop to message processor
	close(c.stopChan)

	// Unregister from hub
	c.Hub.UnregisterAIClient(c.UserID)

	c.IsConnected = false

	c.Logger.Info("AI client disconnected from WebSocket hub",
		"ai_id", c.AI.ID,
		"session_id", c.SessionID)

	return nil
}

// SendMessage simulates receiving a message from the server
func (c *AIWebSocketClient) SendMessage(message websocket.Message) error {
	c.mutex.RLock()
	defer c.mutex.RUnlock()

	if !c.IsConnected {
		return fmt.Errorf("AI client not connected")
	}

	select {
	case c.messageChan <- message:
		return nil
	case <-time.After(1 * time.Second):
		return fmt.Errorf("AI client message queue full")
	}
}

// processMessages handles incoming messages and generates AI responses
func (c *AIWebSocketClient) processMessages() {
	c.Logger.Debug("AI client started message processing", "ai_id", c.AI.ID)

	for {
		select {
		case message := <-c.messageChan:
			c.handleMessage(message)
		case <-c.stopChan:
			c.Logger.Debug("AI client stopped message processing", "ai_id", c.AI.ID)
			return
		}
	}
}

// handleMessage processes a specific message and generates appropriate response
func (c *AIWebSocketClient) handleMessage(message websocket.Message) {
	c.Logger.Debug("AI client handling message",
		"ai_id", c.AI.ID,
		"message_type", message.Type,
		"game_id", message.GameID)

	switch message.Type {
	case "match_found":
		c.handleMatchFound(message)
	case "game_found":
		c.handleGameFound(message)
	case "game_state":
		c.handleGameState(message)
	case "game_update":
		c.handleGameUpdate(message)
	case "turn_timeout":
		c.handleTurnTimeout(message)
	case "game_ended":
		c.handleGameEnded(message)
	case "error":
		c.handleError(message)
	default:
		c.Logger.Debug("AI client ignoring unknown message type",
			"ai_id", c.AI.ID,
			"message_type", message.Type)
	}
}

// handleMatchFound processes match_found notification (from matchmaking service)
func (c *AIWebSocketClient) handleMatchFound(message websocket.Message) {
	// Extract game_id from message payload or GameID field
	var gameID *uuid.UUID
	if message.GameID != nil {
		gameID = message.GameID
	} else if message.Payload != nil {
		if gameIDStr, ok := message.Payload["game_id"].(string); ok {
			if parsedID, err := uuid.Parse(gameIDStr); err == nil {
				gameID = &parsedID
			}
		}
	}

	if gameID == nil {
		c.Logger.Error("AI client received match_found without game_id", "ai_id", c.AI.ID)
		return
	}

	c.CurrentGameID = gameID
	c.AI.CurrentGameID = gameID

	// Extract game mode from message payload if available
	if gameModeStr, ok := message.Payload["game_mode"].(string); ok {
		c.AI.GameMode = game.AuthenticGameMode(gameModeStr)
		c.Logger.Debug("AI client received game mode in match_found",
			"ai_id", c.AI.ID,
			"game_id", *gameID,
			"game_mode", c.AI.GameMode,
		)
	}

	c.Logger.Info("AI client matched to game",
		"ai_id", c.AI.ID,
		"game_id", *gameID,
		"game_mode", c.AI.GameMode,
		"opponent_id", message.Payload["opponent_id"])

	// Send confirmation that AI is ready
	response := websocket.Message{
		Type:      "player_ready",
		ID:        uuid.New().String(),
		GameID:    gameID,
		PlayerID:  c.AI.ID,
		Timestamp: time.Now(),
		Payload:   map[string]interface{}{"status": "ready"},
	}

	c.sendResponseToHub(response)
}

// handleGameFound processes game found notification
func (c *AIWebSocketClient) handleGameFound(message websocket.Message) {
	gameID := message.GameID
	if gameID == nil {
		c.Logger.Error("AI client received game_found without game_id", "ai_id", c.AI.ID)
		return
	}

	c.CurrentGameID = gameID
	c.AI.CurrentGameID = gameID

	c.Logger.Info("AI client joined game",
		"ai_id", c.AI.ID,
		"game_id", *gameID)

	// Send confirmation that AI is ready
	response := websocket.Message{
		Type:      "player_ready",
		ID:        uuid.New().String(),
		GameID:    gameID,
		PlayerID:  c.AI.ID,
		Timestamp: time.Now(),
		Payload:   map[string]interface{}{"status": "ready"},
	}

	c.sendResponseToHub(response)
}

// handleGameState processes complete game state updates
func (c *AIWebSocketClient) handleGameState(message websocket.Message) {
	if message.GameID == nil {
		return
	}

	// Parse game state from message payload
	var gameState game.AuthenticGameState
	if message.Payload != nil {
		dataBytes, err := json.Marshal(message.Payload)
		if err != nil {
			c.Logger.Error("AI client failed to marshal game state", "error", err, "ai_id", c.AI.ID)
			return
		}

		err = json.Unmarshal(dataBytes, &gameState)
		if err != nil {
			c.Logger.Error("AI client failed to unmarshal game state", "error", err, "ai_id", c.AI.ID)
			return
		}
	}

	c.lastGameState = &gameState
	c.AI.GameState = &gameState

	// Update AI game mode from game state
	c.AI.GameMode = gameState.GameMode

	// Check if it's AI's turn
	if gameState.CurrentPlayerID == c.AI.ID && gameState.Status == "playing" {
		c.awaitingMove = true

		// Process AI move in a separate goroutine to avoid blocking
		go c.processAIMove(&gameState)
	}
}

// handleGameUpdate processes incremental game updates
func (c *AIWebSocketClient) handleGameUpdate(message websocket.Message) {
	// Similar to handleGameState but for incremental updates
	c.handleGameState(message) // Reuse logic for simplicity
}

// handleTurnTimeout processes turn timeout notifications
func (c *AIWebSocketClient) handleTurnTimeout(message websocket.Message) {
	if c.awaitingMove && c.lastGameState != nil {
		c.Logger.Warn("AI client received turn timeout, making emergency move", "ai_id", c.AI.ID)
		go c.processAIMove(c.lastGameState)
	}
}

// handleGameEnded processes game end notifications
func (c *AIWebSocketClient) handleGameEnded(message websocket.Message) {
	c.CurrentGameID = nil
	c.AI.CurrentGameID = nil
	c.awaitingMove = false
	c.lastGameState = nil

	c.Logger.Info("AI client game ended",
		"ai_id", c.AI.ID,
		"message", message.Payload)
}

// handleError processes error messages
func (c *AIWebSocketClient) handleError(message websocket.Message) {
	c.Logger.Error("AI client received error message",
		"ai_id", c.AI.ID,
		"error", message.Payload)
}

// processAIMove generates and sends AI's move decision
func (c *AIWebSocketClient) processAIMove(gameState *game.AuthenticGameState) {
	if !c.awaitingMove {
		return
	}

	c.awaitingMove = false

	// Generate AI move
	move, err := c.AI.DecideMove(gameState)
	if err != nil {
		c.Logger.Error("AI failed to decide move", "error", err, "ai_id", c.AI.ID)
		return
	}

	// Convert AI move to WebSocket message
	var moveData map[string]interface{}
	if move.Type == "PLAY_CARD" && move.Card != nil {
		moveData = map[string]interface{}{
			"type":      move.Type,
			"player_id": move.PlayerID,
			"card": map[string]interface{}{
				"suit":  move.Card.Suit,
				"value": move.Card.Value,
				"id":    move.Card.ID,
			},
		}
	} else {
		moveData = map[string]interface{}{
			"type":      move.Type,
			"player_id": move.PlayerID,
		}
	}

	// Send move to hub
	response := websocket.Message{
		Type:      "player_move",
		ID:        uuid.New().String(),
		GameID:    c.CurrentGameID,
		PlayerID:  c.AI.ID,
		Timestamp: time.Now(),
		Payload:   moveData,
	}

	c.sendResponseToHub(response)

	c.Logger.Info("AI client sent move",
		"ai_id", c.AI.ID,
		"move_type", move.Type,
		"card", move.Card)
}

// sendResponseToHub sends a message back to the WebSocket hub
func (c *AIWebSocketClient) sendResponseToHub(message websocket.Message) {
	// In a real implementation, this would send via WebSocket
	// Here we directly call the hub's message handler
	go func() {
		// Add small delay to simulate network latency
		time.Sleep(50 * time.Millisecond)

		err := c.Hub.HandleAIMessage(c.UserID, message)
		if err != nil {
			c.Logger.Error("Failed to send AI message to hub",
				"error", err,
				"ai_id", c.AI.ID,
				"message_type", message.Type)
		}
	}()
}

// JoinMatchmaking makes the AI join the matchmaking queue
func (c *AIWebSocketClient) JoinMatchmaking(queueType string) error {
	if !c.IsConnected {
		return fmt.Errorf("AI client not connected")
	}

	message := websocket.Message{
		Type:      "join_matchmaking",
		ID:        uuid.New().String(),
		PlayerID:  c.AI.ID,
		Timestamp: time.Now(),
		Payload: map[string]interface{}{
			"queue_type": queueType,
			"game_mode":  "septica",
		},
	}

	c.sendResponseToHub(message)
	return nil
}

// IsAlive returns whether the AI client connection is still active
func (c *AIWebSocketClient) IsAlive() bool {
	c.mutex.RLock()
	defer c.mutex.RUnlock()
	return c.IsConnected
}

// GetUserID returns the AI's user ID
func (c *AIWebSocketClient) GetUserID() uuid.UUID {
	return c.UserID
}

// GetSessionID returns the AI's session ID
func (c *AIWebSocketClient) GetSessionID() uuid.UUID {
	return c.SessionID
}