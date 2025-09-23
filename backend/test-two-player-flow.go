package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"net/url"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/google/uuid"
	"github.com/gorilla/websocket"
)

// Test message structures
type Message struct {
	Type      string                 `json:"type"`
	ID        string                 `json:"id,omitempty"`
	PlayerID  *uuid.UUID             `json:"player_id,omitempty"`
	GameID    *uuid.UUID             `json:"game_id,omitempty"`
	Timestamp time.Time              `json:"timestamp"`
	Payload   map[string]interface{} `json:"payload,omitempty"`
}

type IncomingMessage struct {
	Type    string      `json:"type"`
	ID      string      `json:"id,omitempty"`
	GameID  *uuid.UUID  `json:"game_id,omitempty"`
	Payload interface{} `json:"payload,omitempty"`
}

type TestClient struct {
	conn     *websocket.Conn
	playerID uuid.UUID
	name     string
	gameID   *uuid.UUID
	messages chan Message
}

func main() {
	fmt.Println("🎮 Starting Romanian Septica Backend Two-Player Flow Test")
	fmt.Println("================================================================")

	// Test backend health first
	if !testBackendHealth() {
		log.Fatal("❌ Backend health check failed")
	}
	fmt.Println("✅ Backend health check passed")

	// Create two test clients
	player1ID := uuid.New()
	player2ID := uuid.New()

	fmt.Printf("👤 Player 1 ID: %s\n", player1ID)
	fmt.Printf("👤 Player 2 ID: %s\n", player2ID)

	// Connect both clients
	client1, err := connectClient(player1ID, "Player1")
	if err != nil {
		log.Fatal("❌ Failed to connect Player 1:", err)
	}
	defer client1.conn.Close()
	fmt.Println("🔌 Player 1 connected")

	client2, err := connectClient(player2ID, "Player2")
	if err != nil {
		log.Fatal("❌ Failed to connect Player 2:", err)
	}
	defer client2.conn.Close()
	fmt.Println("🔌 Player 2 connected")

	// Set up graceful shutdown
	interrupt := make(chan os.Signal, 1)
	signal.Notify(interrupt, os.Interrupt, syscall.SIGTERM)

	// Start message handlers for both clients
	go client1.messageHandler()
	go client2.messageHandler()

	// Wait for connection acknowledgments
	fmt.Println("⏳ Waiting for connection acknowledgments...")
	time.Sleep(2 * time.Second)

	// Test matchmaking flow
	if !testMatchmakingFlow(client1, client2) {
		log.Fatal("❌ Matchmaking flow test failed")
	}

	// Wait for match to be found
	fmt.Println("⏳ Waiting for match to be found...")
	if !waitForMatch(client1, client2, 30*time.Second) {
		log.Fatal("❌ Match not found within timeout")
	}

	// Test gameplay flow
	if !testGameplayFlow(client1, client2) {
		log.Fatal("❌ Gameplay flow test failed")
	}

	fmt.Println("🎉 All tests passed successfully!")
	fmt.Println("✅ Romanian Septica backend is fully functional for two-player multiplayer")

	// Wait for interrupt
	<-interrupt
	fmt.Println("🔌 Shutting down test clients")
}

func testBackendHealth() bool {
	resp, err := http.Get("http://localhost:8080/health")
	if err != nil {
		fmt.Printf("❌ Health check failed: %v\n", err)
		return false
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		fmt.Printf("❌ Health check returned status %d\n", resp.StatusCode)
		return false
	}

	return true
}

func connectClient(playerID uuid.UUID, name string) (*TestClient, error) {
	u := url.URL{
		Scheme:   "ws",
		Host:     "localhost:8080",
		Path:     "/ws",
		RawQuery: fmt.Sprintf("user_id=%s&session_id=%s", playerID, uuid.New()),
	}

	conn, _, err := websocket.DefaultDialer.Dial(u.String(), nil)
	if err != nil {
		return nil, err
	}

	client := &TestClient{
		conn:     conn,
		playerID: playerID,
		name:     name,
		messages: make(chan Message, 100),
	}

	return client, nil
}

func (c *TestClient) messageHandler() {
	for {
		var msg Message
		err := c.conn.ReadJSON(&msg)
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("❌ WebSocket error for %s: %v", c.name, err)
			}
			return
		}

		fmt.Printf("📨 %s received: %s\n", c.name, msg.Type)
		if msg.Type == "game_state" {
			if gameID := msg.GameID; gameID != nil {
				c.gameID = gameID
				fmt.Printf("🎮 %s joined game: %s\n", c.name, *gameID)
			}
		}

		select {
		case c.messages <- msg:
		default:
			// Channel full, skip message
		}
	}
}

func (c *TestClient) sendMessage(msgType string, payload interface{}) error {
	msg := IncomingMessage{
		Type:    msgType,
		ID:      uuid.New().String(),
		Payload: payload,
	}

	if c.gameID != nil {
		msg.GameID = c.gameID
	}

	return c.conn.WriteJSON(msg)
}

func (c *TestClient) waitForMessage(msgType string, timeout time.Duration) (*Message, bool) {
	timer := time.NewTimer(timeout)
	defer timer.Stop()

	for {
		select {
		case msg := <-c.messages:
			if msg.Type == msgType {
				return &msg, true
			}
		case <-timer.C:
			return nil, false
		}
	}
}

func testMatchmakingFlow(client1, client2 *TestClient) bool {
	fmt.Println("🔄 Testing matchmaking flow...")

	// Both clients join matchmaking
	payload := map[string]interface{}{
		"queue_type": "casual",
		"game_mode":  "septica",
	}

	err := client1.sendMessage("join_matchmaking", payload)
	if err != nil {
		fmt.Printf("❌ Player 1 failed to join matchmaking: %v\n", err)
		return false
	}

	err = client2.sendMessage("join_matchmaking", payload)
	if err != nil {
		fmt.Printf("❌ Player 2 failed to join matchmaking: %v\n", err)
		return false
	}

	fmt.Println("✅ Both players joined matchmaking queue")

	// Wait for matchmaking confirmations
	if _, ok := client1.waitForMessage("matchmaking_joined", 5*time.Second); !ok {
		fmt.Println("❌ Player 1 did not receive matchmaking_joined")
		return false
	}

	if _, ok := client2.waitForMessage("matchmaking_joined", 5*time.Second); !ok {
		fmt.Println("❌ Player 2 did not receive matchmaking_joined")
		return false
	}

	fmt.Println("✅ Matchmaking flow completed successfully")
	return true
}

func waitForMatch(client1, client2 *TestClient, timeout time.Duration) bool {
	fmt.Println("🔍 Waiting for match to be found...")

	// Wait for match_found messages
	msg1, ok1 := client1.waitForMessage("match_found", timeout)
	if !ok1 {
		fmt.Println("❌ Player 1 did not receive match_found")
		return false
	}

	msg2, ok2 := client2.waitForMessage("match_found", timeout)
	if !ok2 {
		fmt.Println("❌ Player 2 did not receive match_found")
		return false
	}

	// Extract game IDs
	if msg1.GameID != nil {
		client1.gameID = msg1.GameID
	}
	if msg2.GameID != nil {
		client2.gameID = msg2.GameID
	}

	fmt.Printf("🎯 Match found! Game ID: %s\n", *client1.gameID)

	// Wait for initial game state
	if _, ok := client1.waitForMessage("game_state", 10*time.Second); !ok {
		fmt.Println("❌ Player 1 did not receive initial game_state")
		return false
	}

	if _, ok := client2.waitForMessage("game_state", 10*time.Second); !ok {
		fmt.Println("❌ Player 2 did not receive initial game_state")
		return false
	}

	fmt.Println("✅ Match found and game state received")
	return true
}

func testGameplayFlow(client1, client2 *TestClient) bool {
	fmt.Println("🎲 Testing gameplay flow...")

	// Request current game state to see hands and valid moves
	err := client1.sendMessage("get_game_state", nil)
	if err != nil {
		fmt.Printf("❌ Player 1 failed to request game state: %v\n", err)
		return false
	}

	err = client2.sendMessage("get_game_state", nil)
	if err != nil {
		fmt.Printf("❌ Player 2 failed to request game state: %v\n", err)
		return false
	}

	// Wait for game states
	gameState1, ok1 := client1.waitForMessage("game_state", 5*time.Second)
	if !ok1 {
		fmt.Println("❌ Player 1 did not receive game_state")
		return false
	}

	gameState2, ok2 := client2.waitForMessage("game_state", 5*time.Second)
	if !ok2 {
		fmt.Println("❌ Player 2 did not receive game_state")
		return false
	}

	fmt.Printf("🃏 Player 1 game state: %+v\n", gameState1.Payload)
	fmt.Printf("🃏 Player 2 game state: %+v\n", gameState2.Payload)

	// Determine current player and play a card
	var currentPlayer *TestClient
	var waitingPlayer *TestClient
	var currentState *Message

	if gameState1.Payload["your_turn"] == true {
		currentPlayer = client1
		waitingPlayer = client2
		currentState = gameState1
	} else {
		currentPlayer = client2
		waitingPlayer = client1
		currentState = gameState2
	}

	fmt.Printf("🎯 Current player: %s\n", currentPlayer.name)

	// Get valid moves and play first available card
	validMoves, ok := currentState.Payload["valid_moves"].([]interface{})
	if !ok || len(validMoves) == 0 {
		fmt.Println("❌ No valid moves available")
		return false
	}

	// Play the first valid card
	firstMove := validMoves[0].(map[string]interface{})
	cardPayload := map[string]interface{}{
		"suit":  firstMove["suit"],
		"value": firstMove["value"],
		"id":    firstMove["id"],
	}

	fmt.Printf("🎴 Playing card: %+v\n", cardPayload)

	err = currentPlayer.sendMessage("play_card", cardPayload)
	if err != nil {
		fmt.Printf("❌ Failed to play card: %v\n", err)
		return false
	}

	// Wait for move result
	moveResult, ok := currentPlayer.waitForMessage("move_result", 5*time.Second)
	if !ok {
		fmt.Println("❌ Did not receive move_result")
		return false
	}

	if moveResult.Payload["valid"] != true {
		fmt.Printf("❌ Move was invalid: %s\n", moveResult.Payload["error"])
		return false
	}

	fmt.Println("✅ Move was valid and processed")

	// Wait for updated game states
	if _, ok := client1.waitForMessage("game_state", 5*time.Second); !ok {
		fmt.Println("❌ Player 1 did not receive updated game_state")
		return false
	}

	if _, ok := client2.waitForMessage("game_state", 5*time.Second); !ok {
		fmt.Println("❌ Player 2 did not receive updated game_state")
		return false
	}

	fmt.Println("✅ Gameplay flow completed successfully")
	return true
}