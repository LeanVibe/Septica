package websocket

import (
	"bytes"
	"encoding/json"
	"log"
	"net/http"
	"time"

	"septica-backend/internal/game"

	"github.com/google/uuid"
	"github.com/gorilla/websocket"
)

const (
	// Time allowed to write a message to the peer
	writeWait = 10 * time.Second

	// Time allowed to read the next pong message from the peer
	pongWait = 60 * time.Second

	// Send pings to peer with this period. Must be less than pongWait
	pingPeriod = (pongWait * 9) / 10

	// Maximum message size allowed from peer
	maxMessageSize = 512
)

var (
	newline = []byte{'\n'}
	space   = []byte{' '}
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		// Allow connections from any origin for now
		// In production, check allowed origins
		return true
	},
}

// Client represents a WebSocket client connection
type Client struct {
	// The websocket connection
	conn *websocket.Conn

	// Hub that manages this client
	hub *Hub

	// Buffered channel of outbound messages
	send chan Message

	// User identification
	userID    uuid.UUID
	sessionID string

	// Current game context
	currentGameID *uuid.UUID

	// Connection metadata
	remoteAddr   string
	userAgent    string
	connectedAt  time.Time
	lastPingAt   time.Time
	lastPongAt   time.Time
}

// NewClient creates a new WebSocket client
func NewClient(hub *Hub, conn *websocket.Conn, userID uuid.UUID, sessionID string, r *http.Request) *Client {
	return &Client{
		conn:        conn,
		hub:         hub,
		send:        make(chan Message, 256),
		userID:      userID,
		sessionID:   sessionID,
		remoteAddr:  r.RemoteAddr,
		userAgent:   r.UserAgent(),
		connectedAt: time.Now(),
		lastPingAt:  time.Now(),
		lastPongAt:  time.Now(),
	}
}

// readPump pumps messages from the websocket connection to the hub
//
// The application runs readPump in a per-connection goroutine. The application
// ensures that there is at most one reader on a connection by executing all
// reads from this goroutine.
func (c *Client) readPump() {
	defer func() {
		c.hub.unregister <- c
		c.conn.Close()
	}()

	c.conn.SetReadLimit(maxMessageSize)
	c.conn.SetReadDeadline(time.Now().Add(pongWait))
	c.conn.SetPongHandler(func(string) error {
		c.lastPongAt = time.Now()
		c.conn.SetReadDeadline(time.Now().Add(pongWait))
		return nil
	})

	for {
		_, message, err := c.conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				c.hub.logger.Error("Websocket error", "user_id", c.userID, "error", err)
			}
			break
		}

		message = bytes.TrimSpace(bytes.Replace(message, newline, space, -1))

		// Parse incoming message
		var msg IncomingMessage
		if err := json.Unmarshal(message, &msg); err != nil {
			c.hub.logger.Warn("Invalid message format", "user_id", c.userID, "error", err)
			c.sendError("invalid_message_format", "Message must be valid JSON")
			continue
		}

		// Handle the message based on type
		c.handleMessage(msg)
	}
}

// writePump pumps messages from the hub to the websocket connection
//
// A goroutine running writePump is started for each connection. The
// application ensures that there is at most one writer to a connection by
// executing all writes from this goroutine.
func (c *Client) writePump() {
	ticker := time.NewTicker(pingPeriod)
	defer func() {
		ticker.Stop()
		c.conn.Close()
	}()

	for {
		select {
		case message, ok := <-c.send:
			c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if !ok {
				// The hub closed the channel
				c.conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}

			// Marshal message to JSON
			data, err := json.Marshal(message)
			if err != nil {
				c.hub.logger.Error("Failed to marshal message", "user_id", c.userID, "error", err)
				continue
			}

			w, err := c.conn.NextWriter(websocket.TextMessage)
			if err != nil {
				return
			}
			w.Write(data)

			// Add queued messages to the current websocket message
			n := len(c.send)
			for i := 0; i < n; i++ {
				w.Write(newline)
				additionalMsg := <-c.send
				additionalData, err := json.Marshal(additionalMsg)
				if err == nil {
					w.Write(additionalData)
				}
			}

			if err := w.Close(); err != nil {
				return
			}

		case <-ticker.C:
			c.lastPingAt = time.Now()
			c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if err := c.conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}

// handleMessage processes incoming messages from the client
func (c *Client) handleMessage(msg IncomingMessage) {
	c.hub.logger.Debug("Received message", "user_id", c.userID, "type", msg.Type, "game_id", msg.GameID)

	switch msg.Type {
	case "ping":
		c.sendPong()

	case "join_game":
		if msg.GameID == nil {
			c.sendError("missing_game_id", "Game ID is required for join_game")
			return
		}
		if err := c.hub.JoinGame(c.userID, *msg.GameID); err != nil {
			c.sendError("join_game_failed", err.Error())
		}

	case "leave_game":
		if c.currentGameID == nil {
			c.sendError("not_in_game", "You are not currently in a game")
			return
		}
		if err := c.hub.LeaveGame(c.userID, *c.currentGameID); err != nil {
			c.sendError("leave_game_failed", err.Error())
		}

	case "play_card":
		if c.currentGameID == nil {
			c.sendError("not_in_game", "You must be in a game to play cards")
			return
		}
		if msg.Payload == nil {
			c.sendError("missing_payload", "Card data is required")
			return
		}

		// Extract card data from payload
		cardData, ok := msg.Payload.(map[string]interface{})
		if !ok {
			c.sendError("invalid_card_data", "Card data must be an object")
			return
		}

		suit, ok := cardData["suit"].(string)
		if !ok {
			c.sendError("invalid_card_suit", "Card suit must be a string")
			return
		}

		valueFloat, ok := cardData["value"].(float64)
		if !ok {
			c.sendError("invalid_card_value", "Card value must be a number")
			return
		}
		value := int(valueFloat)

		cardID, _ := cardData["id"].(string)
		if cardID == "" {
			cardID = uuid.New().String()
		}

		card := game.Card{
			Suit:  suit,
			Value: value,
			ID:    cardID,
		}

		if err := c.hub.HandleGameMove(c.userID, *c.currentGameID, card); err != nil {
			c.sendError("move_failed", err.Error())
		}

	case "get_game_state":
		if c.currentGameID == nil {
			c.sendError("not_in_game", "You are not currently in a game")
			return
		}

		gameState, err := c.hub.gameEngine.GetGame(*c.currentGameID)
		if err != nil {
			c.sendError("game_not_found", "Game not found")
			return
		}

		playerView := c.hub.createPlayerView(gameState, c.userID)
		c.send <- Message{
			Type:      "game_state",
			ID:        uuid.New().String(),
			PlayerID:  c.userID,
			GameID:    c.currentGameID,
			Timestamp: time.Now(),
			Payload:   playerView,
		}

	case "join_matchmaking":
		c.handleJoinMatchmaking(msg)

	case "leave_matchmaking":
		c.handleLeaveMatchmaking(msg)

	case "matchmaking_status":
		c.handleMatchmakingStatus(msg)

	case "pong":
		// Client responded to our heartbeat - just acknowledge, no response needed
		c.hub.logger.Debug("Received pong from client", "user_id", c.userID)

	default:
		c.sendError("unknown_message_type", "Unknown message type: "+msg.Type)
	}
}

// sendPong sends a pong response
func (c *Client) sendPong() {
	pong := Message{
		Type:      "pong",
		ID:        uuid.New().String(),
		PlayerID:  c.userID,
		Timestamp: time.Now(),
		Payload: map[string]interface{}{
			"server_time": time.Now(),
		},
	}
	c.send <- pong
}

// sendError sends an error message to the client
func (c *Client) sendError(errorType, message string) {
	errorMsg := Message{
		Type:      "error",
		ID:        uuid.New().String(),
		PlayerID:  c.userID,
		Timestamp: time.Now(),
		Payload: map[string]interface{}{
			"error_type": errorType,
			"message":    message,
		},
	}
	c.send <- errorMsg
}

// handleJoinMatchmaking handles join matchmaking requests
func (c *Client) handleJoinMatchmaking(msg IncomingMessage) {
	if msg.Payload == nil {
		c.sendError("missing_payload", "Queue type and game mode are required")
		return
	}

	payloadData, ok := msg.Payload.(map[string]interface{})
	if !ok {
		c.sendError("invalid_payload", "Payload must be an object")
		return
	}

	queueType, ok := payloadData["queue_type"].(string)
	if !ok || queueType == "" {
		c.sendError("invalid_queue_type", "Queue type must be a non-empty string")
		return
	}

	gameMode, ok := payloadData["game_mode"].(string)
	if !ok {
		gameMode = "septica" // Default game mode
	}

	// Check if player is already in a game
	if c.currentGameID != nil {
		c.sendError("already_in_game", "Cannot join matchmaking while in a game")
		return
	}

	// Check if matchmaking service is available
	if c.hub.matchmakingService == nil {
		c.sendError("service_unavailable", "Matchmaking service is not available")
		return
	}

	// Join matchmaking queue
	if err := c.hub.matchmakingService.JoinQueue(c.userID, queueType, gameMode); err != nil {
		c.sendError("matchmaking_join_failed", err.Error())
		return
	}

	c.hub.logger.Info("Player joined matchmaking", "user_id", c.userID, "queue_type", queueType, "game_mode", gameMode)
}

// handleLeaveMatchmaking handles leave matchmaking requests
func (c *Client) handleLeaveMatchmaking(msg IncomingMessage) {
	// Check if matchmaking service is available
	if c.hub.matchmakingService == nil {
		c.sendError("service_unavailable", "Matchmaking service is not available")
		return
	}

	// Leave matchmaking queue
	if err := c.hub.matchmakingService.LeaveQueue(c.userID); err != nil {
		c.sendError("matchmaking_leave_failed", err.Error())
		return
	}

	c.hub.logger.Info("Player left matchmaking", "user_id", c.userID)
}

// handleMatchmakingStatus handles matchmaking status requests
func (c *Client) handleMatchmakingStatus(msg IncomingMessage) {
	// Check if matchmaking service is available
	if c.hub.matchmakingService == nil {
		c.sendError("service_unavailable", "Matchmaking service is not available")
		return
	}

	// Get queue status
	status, err := c.hub.matchmakingService.GetQueueStatus(c.userID)
	if err != nil {
		c.sendError("status_retrieval_failed", err.Error())
		return
	}

	// Send status response
	statusMsg := Message{
		Type:      "matchmaking_status",
		ID:        uuid.New().String(),
		PlayerID:  c.userID,
		Timestamp: time.Now(),
		Payload:   status,
	}
	c.send <- statusMsg
}

// ServeWS handles websocket requests from the peer
func ServeWS(hub *Hub, w http.ResponseWriter, r *http.Request) {
	// Extract user ID from query params or JWT token
	userIDStr := r.URL.Query().Get("user_id")
	if userIDStr == "" {
		http.Error(w, "user_id parameter required", http.StatusBadRequest)
		return
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		http.Error(w, "invalid user_id format", http.StatusBadRequest)
		return
	}

	sessionID := r.URL.Query().Get("session_id")
	if sessionID == "" {
		sessionID = uuid.New().String()
	}

	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println(err)
		return
	}

	client := NewClient(hub, conn, userID, sessionID, r)
	client.hub.register <- client

	// Allow collection of memory referenced by the caller by doing all work in new goroutines
	go client.writePump()
	go client.readPump()
}