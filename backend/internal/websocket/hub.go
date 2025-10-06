package websocket

import (
	"encoding/json"
	"errors"
	"math/rand"
	"sync"
	"time"

	"septica-backend/internal/database"
	"septica-backend/internal/game"
	"septica-backend/pkg/logger"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// AIClientInterface defines the interface for AI WebSocket clients
type AIClientInterface interface {
	SendMessage(message Message) error
	IsAlive() bool
	GetUserID() uuid.UUID
	GetSessionID() uuid.UUID
}

// Hub maintains active WebSocket connections and manages game sessions
type Hub struct {
	// Registered clients
	clients map[*Client]bool

	// Client connections by user ID for quick lookup
	userClients map[uuid.UUID]*Client

	// AI clients by user ID for AI player support
	aiClients map[uuid.UUID]AIClientInterface

	// Game sessions - maps game ID to slice of clients
	gameClients map[uuid.UUID][]*Client

	// Inbound messages from clients
	broadcast chan []byte

	// Register requests from clients
	register chan *Client

	// Unregister requests from clients
	unregister chan *Client

	// Game engines for validating moves
	gameEngine      *game.Engine
	authenticEngine *game.AuthenticEngine

	// Matchmaking service reference
	matchmakingService MatchmakingServiceInterface

	// Session store for reconnection support
	sessionStore *SessionStore

	// Database connection
	db *gorm.DB

	// Logger
	logger *logger.Logger

	// Random number generator for AI system
	randGen *rand.Rand

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
func NewHub(gameEngine *game.Engine, authenticEngine *game.AuthenticEngine, db *gorm.DB, logger *logger.Logger) *Hub {
	// Create session store with 30 minute timeout
	sessionStore := NewSessionStore(30 * time.Minute)

	return &Hub{
		clients:         make(map[*Client]bool),
		userClients:     make(map[uuid.UUID]*Client),
		aiClients:       make(map[uuid.UUID]AIClientInterface),
		gameClients:     make(map[uuid.UUID][]*Client),
		broadcast:       make(chan []byte),
		register:        make(chan *Client),
		unregister:      make(chan *Client),
		gameEngine:      gameEngine,
		authenticEngine: authenticEngine,
		sessionStore:    sessionStore,
		db:              db,
		logger:          logger,
		randGen:         rand.New(rand.NewSource(time.Now().UnixNano())),
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

	// Check if this is a reconnection (existing session)
	isReconnection := false
	var recoveredSession *GameSession

	if existingSession, exists := h.sessionStore.GetSession(client.sessionID); exists {
		// This is a reconnection attempt
		isReconnection = true
		recoveredSession = existingSession
		h.sessionStore.IncrementReconnectCount(client.sessionID)
		h.logger.Info("Client reconnecting", "user_id", client.userID, "session_id", client.sessionID, "reconnect_count", recoveredSession.ReconnectCount)
	}

	h.clients[client] = true
	h.userClients[client.userID] = client

	// Create or update session in session store
	session := &GameSession{
		SessionID:      client.sessionID,
		UserID:         client.userID,
		GameID:         client.currentGameID,
		CreatedAt:      time.Now(),
		LastActiveAt:   time.Now(),
		RemoteAddr:     client.remoteAddr,
		UserAgent:      client.userAgent,
		ReconnectCount: 0,
	}

	if isReconnection && recoveredSession != nil {
		session.CreatedAt = recoveredSession.CreatedAt
		session.ReconnectCount = recoveredSession.ReconnectCount
		session.GameID = recoveredSession.GameID
		session.GameState = recoveredSession.GameState

		// Restore game context
		client.currentGameID = recoveredSession.GameID
	}

	h.sessionStore.StoreSession(session)

	h.logger.Info("Client registered", "user_id", client.userID, "total_clients", len(h.clients), "is_reconnection", isReconnection)

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
			"is_reconnection":   isReconnection,
		},
	}

	client.send <- ackMsg

	// If reconnection, send recovered game state
	if isReconnection && recoveredSession != nil && recoveredSession.GameState != nil {
		h.handleReconnection(client, recoveredSession)
	}
}

// handleReconnection sends recovered game state to reconnecting client
func (h *Hub) handleReconnection(client *Client, session *GameSession) {
	h.logger.Info("Handling reconnection", "user_id", client.userID, "game_id", session.GameID)

	// Export session snapshot for client
	snapshot, err := h.sessionStore.ExportSessionSnapshot(session.SessionID)
	if err != nil {
		h.logger.Error("Failed to export session snapshot", "error", err)
		return
	}

	// Send reconnection success message with recovered state
	reconnectMsg := Message{
		Type:      "reconnection_success",
		ID:        uuid.New().String(),
		PlayerID:  client.userID,
		GameID:    session.GameID,
		Timestamp: time.Now(),
		Payload:   snapshot,
	}

	client.send <- reconnectMsg

	// If client was in a game, re-add them to game session
	if session.GameID != nil {
		// Re-add client to game clients map
		h.gameClients[*session.GameID] = append(h.gameClients[*session.GameID], client)

		// Notify other players in the game
		h.broadcastToGame(*session.GameID, Message{
			Type:      "player_reconnected",
			ID:        uuid.New().String(),
			GameID:    session.GameID,
			PlayerID:  client.userID,
			Timestamp: time.Now(),
			Payload: map[string]interface{}{
				"player_id": client.userID,
			},
		})
	}
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
	// First try authentic engine
	authenticGame, authenticErr := h.authenticEngine.GetGame(gameID)
	if authenticErr == nil {
		// Handle authentic Septica move
		return h.handleAuthenticMove(userID, gameID, card, authenticGame)
	}

	// Fallback to legacy engine
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

// handleAuthenticMove processes authentic Septica moves
func (h *Hub) handleAuthenticMove(userID uuid.UUID, gameID uuid.UUID, card game.Card, gameState *game.AuthenticGameState) error {
	// Create authentic card from websocket card
	authenticCard := game.Card{
		Suit:  card.Suit,
		Value: card.Value,
		ID:    card.ID,
	}

	// Process the move
	action := game.AuthenticPlayerAction{
		Type:     "PLAY_CARD",
		PlayerID: userID,
		Card:     &authenticCard,
	}

	result, err := h.authenticEngine.ProcessAction(gameID, action)
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
				"valid":                result.Valid,
				"error":                result.Error,
				"round_complete":       result.RoundComplete,
				"game_complete":        result.GameComplete,
				"winner_id":            result.WinnerID,
				"winning_team":         result.WinningTeam,
				"points_awarded":       result.PointsAwarded,
				"collector_player_id":  result.CollectorPlayerID,
				"objection_phase":      result.ObjectionPhase,
				"next_player_id":       result.NextPlayerID,
			},
		}
		client.send <- moveResult
	}

	// If move was valid, broadcast game state update to all players in the game
	if result.Valid && result.UpdatedState != nil {
		h.broadcastAuthenticGameState(gameID, result.UpdatedState)
	}

	// If game is complete, handle game end
	if result.GameComplete {
		h.handleGameEnd(gameID, result.WinnerID)
	}

	return nil
}

// broadcastAuthenticGameState sends updated authentic game state to all players
func (h *Hub) broadcastAuthenticGameState(gameID uuid.UUID, gameState *game.AuthenticGameState) {
	clients, exists := h.gameClients[gameID]
	if !exists {
		return
	}

	// Update session store with latest game state for all players in this game
	for _, client := range clients {
		h.sessionStore.UpdateSessionGameState(client.sessionID, gameState, gameState.SequenceNumber)
	}

	for _, client := range clients {
		// Get player-specific view for authentic Septica
		playerView := h.createAuthenticPlayerView(gameState, client.userID)

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
			// Update session activity on successful send
			h.sessionStore.UpdateSessionActivity(client.sessionID)
		default:
			h.logger.Warn("Failed to send authentic game state to client", "user_id", client.userID)
		}
	}
}

// createAuthenticPlayerView creates a game state view for authentic Septica
func (h *Hub) createAuthenticPlayerView(gameState *game.AuthenticGameState, playerID uuid.UUID) map[string]interface{} {
	// Get player's hand
	playerHand := gameState.PlayerHands[playerID]

	// Count other players' cards
	var opponentCardCounts []int
	for _, otherPlayerID := range gameState.Players {
		if otherPlayerID != playerID {
			opponentCardCounts = append(opponentCardCounts, len(gameState.PlayerHands[otherPlayerID]))
		}
	}

	// Get valid moves for this player
	validMoves, _ := h.authenticEngine.GetValidMoves(gameState.ID, playerID)

	// Create scores map
	scores := make(map[string]int)
	for _, pID := range gameState.Players {
		scores[pID.String()] = gameState.PlayerScores[pID]
	}

	return map[string]interface{}{
		"game_id":                gameState.ID,
		"current_player_id":      gameState.CurrentPlayerID,
		"your_turn":              gameState.CurrentPlayerID == playerID,
		"your_cards":             playerHand,
		"opponent_card_counts":   opponentCardCounts,
		"table_cards":            gameState.TableCards,
		"valid_moves":            validMoves,
		"scores":                 scores,
		"round_number":           gameState.RoundNumber,
		"move_number":            gameState.MoveNumber,
		"sequence_number":        gameState.SequenceNumber,
		"status":                 gameState.Status,
		"game_mode":              gameState.GameMode,
		"waiting_for_objection":  gameState.WaitingForObjection,
		"last_played_card":       gameState.LastPlayedCard,
		"last_player_id":         gameState.LastPlayerID,
		"teams":                  gameState.Teams,
		"team_scores":            gameState.TeamScores,
		"wild_eights":            gameState.WildEights,
		"can_pass":               gameState.WaitingForObjection && gameState.CurrentPlayerID == playerID,
	}
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

	// Try regular client first
	client, exists := h.userClients[playerID]
	if exists {
		select {
		case client.send <- message:
			return nil
		default:
			h.logger.Warn("Failed to send message to client - channel full", "user_id", playerID)
			return errors.New("client channel full")
		}
	}

	// Try AI client if regular client not found
	aiClient, aiExists := h.aiClients[playerID]
	if aiExists {
		return aiClient.SendMessage(message)
	}

	return ErrClientNotFound
}

// AI CLIENT MANAGEMENT METHODS

// RegisterAIClient registers an AI client with the hub
func (h *Hub) RegisterAIClient(userID uuid.UUID, sessionID uuid.UUID, aiClient AIClientInterface) error {
	h.mutex.Lock()
	defer h.mutex.Unlock()

	// Ensure AI player exists in database
	h.ensurePlayerExists(userID)

	h.aiClients[userID] = aiClient

	h.logger.Info("AI client registered", "user_id", userID, "session_id", sessionID)

	return nil
}

// UnregisterAIClient removes an AI client from the hub
func (h *Hub) UnregisterAIClient(userID uuid.UUID) {
	h.mutex.Lock()
	defer h.mutex.Unlock()

	if _, exists := h.aiClients[userID]; exists {
		delete(h.aiClients, userID)
		h.logger.Info("AI client unregistered", "user_id", userID)
	}
}

// HandleAIMessage processes messages from AI clients
func (h *Hub) HandleAIMessage(userID uuid.UUID, message Message) error {
	h.logger.Debug("Handling AI message", "user_id", userID, "message_type", message.Type)

	switch message.Type {
	case "join_matchmaking":
		return h.handleAIJoinMatchmaking(userID, message)
	case "player_move":
		return h.handleAIPlayerMove(userID, message)
	case "player_ready":
		return h.handleAIPlayerReady(userID, message)
	default:
		h.logger.Debug("Unknown AI message type", "type", message.Type, "user_id", userID)
		return nil
	}
}

// handleAIJoinMatchmaking processes AI matchmaking requests
func (h *Hub) handleAIJoinMatchmaking(userID uuid.UUID, message Message) error {
	if h.matchmakingService == nil {
		return errors.New("matchmaking service not available")
	}

	data := message.Payload
	if data == nil {
		return errors.New("missing message payload")
	}

	queueType, _ := data["queue_type"].(string)
	gameMode, _ := data["game_mode"].(string)

	if queueType == "" {
		queueType = "ranked"
	}
	if gameMode == "" {
		gameMode = "septica"
	}

	err := h.matchmakingService.JoinQueue(userID, queueType, gameMode)
	if err != nil {
		h.logger.Error("AI failed to join matchmaking queue", "error", err, "user_id", userID)
		return err
	}

	h.logger.Info("AI joined matchmaking queue", "user_id", userID, "queue_type", queueType, "game_mode", gameMode)
	return nil
}

// handleAIPlayerMove processes AI player moves
func (h *Hub) handleAIPlayerMove(userID uuid.UUID, message Message) error {
	if message.GameID == nil {
		return errors.New("missing game_id in AI move")
	}

	data := message.Payload
	if data == nil {
		return errors.New("missing move data")
	}

	moveType, _ := data["type"].(string)
	if moveType == "PLAY_CARD" {
		cardData, ok := data["card"].(map[string]interface{})
		if !ok {
			return errors.New("invalid card data")
		}

		suit, _ := cardData["suit"].(string)
		value, ok := cardData["value"].(float64)
		if !ok {
			// Try int conversion
			if intValue, intOk := cardData["value"].(int); intOk {
				value = float64(intValue)
			} else {
				return errors.New("invalid card value")
			}
		}

		card := game.Card{
			Suit:  suit,
			Value: int(value),
			ID:    uuid.New().String(),
		}

		return h.HandleGameMove(userID, *message.GameID, card)
	} else if moveType == "PASS" {
		// Handle pass action for authentic engine
		authenticGame, err := h.authenticEngine.GetGame(*message.GameID)
		if err == nil && authenticGame != nil {
			action := game.AuthenticPlayerAction{
				Type:     "PASS",
				PlayerID: userID,
			}

			result, err := h.authenticEngine.ProcessAction(*message.GameID, action)
			if err != nil {
				return err
			}

			// Broadcast result if valid
			if result.Valid && result.UpdatedState != nil {
				h.broadcastAuthenticGameState(*message.GameID, result.UpdatedState)
			}
		}
	}

	return nil
}

// handleAIPlayerReady processes AI ready notifications
func (h *Hub) handleAIPlayerReady(userID uuid.UUID, message Message) error {
	h.logger.Info("AI player ready", "user_id", userID, "game_id", message.GameID)

	// Broadcast to other players that AI is ready
	if message.GameID != nil {
		readyMessage := Message{
			Type:      "player_ready",
			ID:        uuid.New().String(),
			GameID:    message.GameID,
			PlayerID:  userID,
			Timestamp: time.Now(),
			Payload: map[string]interface{}{
				"player_id": userID,
				"status":    "ready",
				"is_ai":     true,
			},
		}

		h.broadcastToGame(*message.GameID, readyMessage)
	}

	return nil
}

// GetMatchmakingQueueStats returns statistics about matchmaking queues
func (h *Hub) GetMatchmakingQueueStats() map[string]interface{} {
	// This would be implemented by the matchmaking service
	// For now, return empty stats
	if h.matchmakingService == nil {
		return make(map[string]interface{})
	}

	// In a real implementation, we would get this data from the matchmaking service
	// For now, return empty stats - this will be enhanced when matchmaking service
	// provides queue statistics
	return make(map[string]interface{})
}

// GetRandomFloat64 returns a random float64 between 0 and 1
func (h *Hub) GetRandomFloat64() float64 {
	h.mutex.Lock()
	defer h.mutex.Unlock()
	return h.randGen.Float64()
}