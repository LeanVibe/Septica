package websocket

import (
	"encoding/json"
	"errors"
	"sync"
	"time"

	"septica-backend/internal/database"
	"septica-backend/internal/game"
	"septica-backend/pkg/logger"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// Hub maintains active WebSocket connections and manages game sessions
type Hub struct {
	// Registered clients
	clients map[*Client]bool

	// Client connections by user ID for quick lookup
	userClients map[uuid.UUID]*Client

	// Game sessions - maps game ID to slice of clients
	gameClients map[uuid.UUID][]*Client

	// Inbound messages from clients
	broadcast chan []byte

	// Register requests from clients
	register chan *Client

	// Unregister requests from clients
	unregister chan *Client

	// Game engine for validating moves
	gameEngine *game.Engine

	// Matchmaking service reference
	matchmakingService MatchmakingServiceInterface

	// Database connection
	db *gorm.DB

	// Logger
	logger *logger.Logger

	// Mutex for thread-safe operations
	mutex sync.RWMutex
}

// MatchmakingServiceInterface defines the interface for matchmaking service
type MatchmakingServiceInterface interface {
	JoinQueue(playerID uuid.UUID, queueType, gameMode string) error
	LeaveQueue(playerID uuid.UUID) error
	GetQueueStatus(playerID uuid.UUID) (map[string]interface{}, error)
	IsPlayerInQueue(playerID uuid.UUID) bool
}

// NewHub creates a new WebSocket hub
func NewHub(gameEngine *game.Engine, db *gorm.DB, logger *logger.Logger) *Hub {
	return &Hub{
		clients:     make(map[*Client]bool),
		userClients: make(map[uuid.UUID]*Client),
		gameClients: make(map[uuid.UUID][]*Client),
		broadcast:   make(chan []byte),
		register:    make(chan *Client),
		unregister:  make(chan *Client),
		gameEngine:  gameEngine,
		db:          db,
		logger:      logger,
	}
}

// Run starts the hub and handles client management
func (h *Hub) Run() {
	for {
		select {
		case client := <-h.register:
			h.handleRegister(client)

		case client := <-h.unregister:
			h.handleUnregister(client)

		case message := <-h.broadcast:
			h.handleBroadcast(message)
		}
	}
}

// handleRegister processes new client registrations
func (h *Hub) handleRegister(client *Client) {
	// Ensure user and player exist in database (outside mutex to avoid blocking)
	h.ensurePlayerExists(client.userID)

	h.mutex.Lock()
	defer h.mutex.Unlock()

	h.clients[client] = true
	h.userClients[client.userID] = client

	h.logger.Info("Client registered", "user_id", client.userID, "total_clients", len(h.clients))

	// Send connection acknowledgment
	ackMsg := Message{
		Type:      "connection_ack",
		ID:        uuid.New().String(),
		PlayerID:  client.userID,
		Timestamp: time.Now(),
		Payload: map[string]interface{}{
			"session_id":        client.sessionID,
			"server_time":       time.Now(),
			"heartbeat_interval": 30000, // 30 seconds
			"max_message_queue": 100,
		},
	}

	client.send <- ackMsg
}

// ensurePlayerExists creates user and player records if they don't exist
func (h *Hub) ensurePlayerExists(userID uuid.UUID) {
	// Check if user exists
	var user database.User
	err := h.db.Where("id = ?", userID).First(&user).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			// Create new user
			user = database.User{
				Username: "guest_" + userID.String()[:8],
				Email:    userID.String() + "@septica.game", // Placeholder email
				PasswordHash: "guest_password_hash", // Placeholder hash
				IsActive: true,
			}
			user.ID = userID // Set the BaseModel ID
			if err := h.db.Create(&user).Error; err != nil {
				h.logger.Error("Failed to create user", "user_id", userID, "error", err)
				return
			}
			h.logger.Info("Created new user", "user_id", userID, "username", user.Username)
		} else {
			h.logger.Error("Database error checking user", "user_id", userID, "error", err)
			return
		}
	}

	// Check if player exists
	var player database.Player
	err = h.db.Where("user_id = ?", userID).First(&player).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			// Create new player
			player = database.Player{
				UserID:   userID,
				Username: user.Username,
				Level:    1,
				XP:       0,
				Rating:   1000, // Default rating
				Arena:    1, // Bronze tier
				Coins:    100,  // Starting coins
				Gems:     0,
			}
			if err := h.db.Create(&player).Error; err != nil {
				h.logger.Error("Failed to create player", "user_id", userID, "error", err)
				return
			}
			h.logger.Info("Created new player", "user_id", userID, "username", player.Username, "rating", player.Rating)
		} else {
			h.logger.Error("Database error checking player", "user_id", userID, "error", err)
			return
		}
	}
}

// handleUnregister processes client disconnections
func (h *Hub) handleUnregister(client *Client) {
	h.mutex.Lock()
	defer h.mutex.Unlock()

	if _, ok := h.clients[client]; ok {
		delete(h.clients, client)
		delete(h.userClients, client.userID)
		close(client.send)

		// Remove from game sessions
		for gameID, clients := range h.gameClients {
			for i, c := range clients {
				if c == client {
					h.gameClients[gameID] = append(clients[:i], clients[i+1:]...)
					break
				}
			}
			// Clean up empty game sessions
			if len(h.gameClients[gameID]) == 0 {
				delete(h.gameClients, gameID)
			}
		}

		h.logger.Info("Client unregistered", "user_id", client.userID, "total_clients", len(h.clients))
	}
}

// handleBroadcast sends messages to all connected clients
func (h *Hub) handleBroadcast(messageBytes []byte) {
	h.mutex.RLock()
	defer h.mutex.RUnlock()

	// Parse the raw bytes into a Message struct
	var message Message
	if err := json.Unmarshal(messageBytes, &message); err != nil {
		h.logger.Error("Failed to unmarshal broadcast message", "error", err)
		return
	}

	for client := range h.clients {
		select {
		case client.send <- message:
		default:
			close(client.send)
			delete(h.clients, client)
		}
	}
}

// JoinGame adds a client to a game session
func (h *Hub) JoinGame(userID uuid.UUID, gameID uuid.UUID) error {
	h.mutex.Lock()
	defer h.mutex.Unlock()

	client, exists := h.userClients[userID]
	if !exists {
		return ErrClientNotFound
	}

	// Add client to game session
	h.gameClients[gameID] = append(h.gameClients[gameID], client)
	client.currentGameID = &gameID

	h.logger.Info("Client joined game", "user_id", userID, "game_id", gameID)

	// Notify other clients in the game
	h.broadcastToGame(gameID, Message{
		Type:      "player_joined",
		ID:        uuid.New().String(),
		GameID:    &gameID,
		PlayerID:  userID,
		Timestamp: time.Now(),
		Payload: map[string]interface{}{
			"player_id": userID,
		},
	})

	return nil
}

// LeaveGame removes a client from a game session
func (h *Hub) LeaveGame(userID uuid.UUID, gameID uuid.UUID) error {
	h.mutex.Lock()
	defer h.mutex.Unlock()

	client, exists := h.userClients[userID]
	if !exists {
		return ErrClientNotFound
	}

	// Remove client from game session
	clients := h.gameClients[gameID]
	for i, c := range clients {
		if c == client {
			h.gameClients[gameID] = append(clients[:i], clients[i+1:]...)
			break
		}
	}

	client.currentGameID = nil

	h.logger.Info("Client left game", "user_id", userID, "game_id", gameID)

	// Notify other clients in the game
	h.broadcastToGame(gameID, Message{
		Type:      "player_left",
		ID:        uuid.New().String(),
		GameID:    &gameID,
		PlayerID:  userID,
		Timestamp: time.Now(),
		Payload: map[string]interface{}{
			"player_id": userID,
		},
	})

	return nil
}

// HandleGameMove processes a game move and broadcasts the result
func (h *Hub) HandleGameMove(userID uuid.UUID, gameID uuid.UUID, card game.Card) error {
	// Validate the move using the game engine
	result, err := h.gameEngine.PlayCard(gameID, userID, card)
	if err != nil {
		return err
	}

	// Send move result to the player
	client, exists := h.userClients[userID]
	if exists {
		moveResult := Message{
			Type:      "move_result",
			ID:        uuid.New().String(),
			PlayerID:  userID,
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
		client.send <- moveResult
	}

	// If move was valid, broadcast game state update to all players in the game
	if result.Valid && result.UpdatedState != nil {
		h.broadcastGameState(gameID, result.UpdatedState)
	}

	// If game is complete, handle game end
	if result.GameComplete {
		h.handleGameEnd(gameID, result.WinnerID)
	}

	return nil
}

// broadcastToGame sends a message to all clients in a specific game
func (h *Hub) broadcastToGame(gameID uuid.UUID, message Message) {
	clients, exists := h.gameClients[gameID]
	if !exists {
		return
	}

	for _, client := range clients {
		select {
		case client.send <- message:
		default:
			// Client's send channel is full, skip
			h.logger.Warn("Failed to send message to client", "user_id", client.userID)
		}
	}
}

// broadcastGameState sends updated game state to all players
func (h *Hub) broadcastGameState(gameID uuid.UUID, gameState *game.GameState) {
	clients, exists := h.gameClients[gameID]
	if !exists {
		return
	}

	for _, client := range clients {
		// Get player-specific view (hide opponent's cards)
		playerView := h.createPlayerView(gameState, client.userID)

		stateMessage := Message{
			Type:      "game_state",
			ID:        uuid.New().String(),
			PlayerID:  client.userID,
			GameID:    &gameID,
			Timestamp: time.Now(),
			Payload:   playerView,
		}

		select {
		case client.send <- stateMessage:
		default:
			h.logger.Warn("Failed to send game state to client", "user_id", client.userID)
		}
	}
}

// createPlayerView creates a game state view for a specific player
func (h *Hub) createPlayerView(gameState *game.GameState, playerID uuid.UUID) map[string]interface{} {
	var yourHand []game.Card
	var opponentCardCount int

	if playerID == gameState.Player1ID {
		yourHand = gameState.Player1Hand
		opponentCardCount = len(gameState.Player2Hand)
	} else {
		yourHand = gameState.Player2Hand
		opponentCardCount = len(gameState.Player1Hand)
	}

	// Get valid moves for this player
	validMoves, _ := h.gameEngine.GetValidMoves(gameState.ID, playerID)

	return map[string]interface{}{
		"game_id":            gameState.ID,
		"current_player_id":  gameState.CurrentPlayerID,
		"your_turn":          gameState.CurrentPlayerID == playerID,
		"your_cards":         yourHand,
		"opponent_card_count": opponentCardCount,
		"table_cards":        gameState.TableCards,
		"valid_moves":        validMoves,
		"scores": map[string]int{
			gameState.Player1ID.String(): gameState.Player1Score,
			gameState.Player2ID.String(): gameState.Player2Score,
		},
		"trick_number":    gameState.TrickNumber,
		"move_number":     gameState.MoveNumber,
		"sequence_number": gameState.SequenceNumber,
		"status":          gameState.Status,
	}
}

// handleGameEnd processes game completion
func (h *Hub) handleGameEnd(gameID uuid.UUID, winnerID *uuid.UUID) {
	endMessage := Message{
		Type:      "game_end",
		ID:        uuid.New().String(),
		GameID:    &gameID,
		Timestamp: time.Now(),
		Payload: map[string]interface{}{
			"winner_id": winnerID,
			"reason":    "normal",
		},
	}

	h.broadcastToGame(gameID, endMessage)

	// Clean up game session
	h.mutex.Lock()
	for _, client := range h.gameClients[gameID] {
		client.currentGameID = nil
	}
	delete(h.gameClients, gameID)
	h.mutex.Unlock()

	h.logger.Info("Game ended", "game_id", gameID, "winner_id", winnerID)
}

// SendHeartbeat sends heartbeat to all connected clients
func (h *Hub) SendHeartbeat() {
	h.mutex.RLock()
	defer h.mutex.RUnlock()

	heartbeat := Message{
		Type:      "heartbeat",
		ID:        uuid.New().String(),
		Timestamp: time.Now(),
		Payload: map[string]interface{}{
			"server_time": time.Now(),
		},
	}

	for client := range h.clients {
		select {
		case client.send <- heartbeat:
		default:
			// Client not responding, will be cleaned up by client goroutine
		}
	}
}

// Broadcast sends raw message bytes to all connected clients
func (h *Hub) Broadcast(messageBytes []byte) {
	h.broadcast <- messageBytes
}

// GetConnectionCount returns the number of active connections
func (h *Hub) GetConnectionCount() int {
	h.mutex.RLock()
	defer h.mutex.RUnlock()
	return len(h.clients)
}

// GetGameCount returns the number of active games
func (h *Hub) GetGameCount() int {
	h.mutex.RLock()
	defer h.mutex.RUnlock()
	return len(h.gameClients)
}

// GetGameEngine returns the game engine instance
func (h *Hub) GetGameEngine() *game.Engine {
	return h.gameEngine
}

// SetMatchmakingService sets the matchmaking service reference
func (h *Hub) SetMatchmakingService(service MatchmakingServiceInterface) {
	h.matchmakingService = service
}

// SendToPlayer sends a message to a specific player by user ID
func (h *Hub) SendToPlayer(playerID uuid.UUID, message Message) error {
	h.mutex.RLock()
	defer h.mutex.RUnlock()
	
	client, exists := h.userClients[playerID]
	if !exists {
		return ErrClientNotFound
	}
	
	select {
	case client.send <- message:
		return nil
	default:
		h.logger.Warn("Failed to send message to client - channel full", "user_id", playerID)
		return errors.New("client channel full")
	}
}