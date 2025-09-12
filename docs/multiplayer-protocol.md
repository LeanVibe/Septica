# Septica WebSocket Multiplayer Protocol

## 🔗 Connection Overview

The Septica multiplayer system uses WebSockets for real-time, bidirectional communication between the iOS client and Go backend. The protocol ensures low-latency gameplay, state synchronization, and connection resilience.

**WebSocket Endpoint:** `wss://ws.septica.game/game`  
**Protocol Version:** `1.0`  
**Heartbeat Interval:** 30 seconds  
**Reconnection Timeout:** 5 minutes  

## 🤝 Connection Lifecycle

### Connection Flow
```
1. Client connects to WebSocket endpoint
2. Server validates JWT token in connection headers
3. Client sends CONNECT message with player info
4. Server responds with CONNECTION_ACK
5. Game messages flow bidirectionally
6. Heartbeat messages maintain connection
7. Connection closes gracefully or reconnects on failure
```

### Connection Headers
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Sec-WebSocket-Protocol: septica-v1
User-Agent: SepticaiOS/1.0 (iOS 17.0; iPhone15,2)
```

## 📨 Message Structure

### Base Message Format
```json
{
  "type": "MESSAGE_TYPE",
  "id": "msg_550e8400-e29b-41d4-a716-446655440000",
  "player_id": "550e8400-e29b-41d4-a716-446655440000",
  "game_id": "game_12345",
  "timestamp": "2024-01-20T15:30:00.123Z",
  "payload": {
    // Message-specific data
  }
}
```

### Message Types
```typescript
enum MessageType {
  // Connection Management
  CONNECT = "connect",
  CONNECTION_ACK = "connection_ack",
  DISCONNECT = "disconnect",
  HEARTBEAT = "heartbeat",
  ERROR = "error",
  
  // Matchmaking
  MATCHMAKING_START = "matchmaking_start",
  MATCH_FOUND = "match_found",
  MATCH_CANCELLED = "match_cancelled",
  
  // Game Flow
  GAME_START = "game_start",
  GAME_STATE = "game_state",
  CARD_PLAYED = "card_played",
  TRICK_COMPLETE = "trick_complete",
  CONTINUE_TRICK = "continue_trick",
  PASS_TURN = "pass_turn",
  GAME_END = "game_end",
  
  // Player Actions
  PLAYER_JOINED = "player_joined",
  PLAYER_LEFT = "player_left",
  PLAYER_RECONNECTED = "player_reconnected",
  
  // Communication
  CHAT_MESSAGE = "chat_message",
  EMOTE = "emote",
  
  // System
  SYSTEM_MESSAGE = "system_message",
  FORCE_DISCONNECT = "force_disconnect"
}
```

## 🔌 Connection Management Messages

### Connect
**Client → Server**
```json
{
  "type": "connect",
  "id": "msg_001",
  "player_id": "550e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2024-01-20T15:30:00.123Z",
  "payload": {
    "protocol_version": "1.0",
    "client_version": "1.2.3",
    "device_info": {
      "model": "iPhone15,2",
      "os_version": "17.0",
      "app_version": "1.0.0"
    },
    "reconnection": false,
    "last_message_id": null
  }
}
```

### Connection Acknowledgment
**Server → Client**
```json
{
  "type": "connection_ack",
  "id": "msg_002",
  "player_id": "550e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2024-01-20T15:30:00.456Z",
  "payload": {
    "session_id": "session_550e8400-e29b-41d4-a716-446655440000",
    "server_time": "2024-01-20T15:30:00.456Z",
    "heartbeat_interval": 30000,
    "max_message_queue": 100,
    "player_status": {
      "rating": 1450,
      "in_game": false,
      "queue_status": null
    }
  }
}
```

### Heartbeat
**Bidirectional (every 30 seconds)**
```json
{
  "type": "heartbeat",
  "id": "msg_heartbeat_001",
  "timestamp": "2024-01-20T15:30:30.000Z",
  "payload": {
    "ping": 1642694430000  // Client includes ping timestamp
  }
}
```

**Response includes pong:**
```json
{
  "type": "heartbeat",
  "id": "msg_heartbeat_002",
  "timestamp": "2024-01-20T15:30:30.045Z",
  "payload": {
    "pong": 1642694430000,  // Echo of ping timestamp
    "latency": 45           // Calculated round-trip time (ms)
  }
}
```

## 🎮 Game Flow Messages

### Game Start
**Server → Both Players**
```json
{
  "type": "game_start",
  "id": "msg_game_start_001",
  "game_id": "game_550e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2024-01-20T15:35:00.000Z",
  "payload": {
    "players": [
      {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "username": "player123",
        "rating": 1450,
        "position": 1
      },
      {
        "id": "player_456",
        "username": "opponent789",
        "rating": 1425,
        "position": 2
      }
    ],
    "game_settings": {
      "mode": "ranked",
      "time_limit_per_move": 30000,
      "total_time_per_player": 600000
    },
    "initial_state": {
      "current_player": "550e8400-e29b-41d4-a716-446655440000",
      "your_cards": [
        {"suit": "hearts", "value": 7, "id": "card_1"},
        {"suit": "diamonds", "value": 10, "id": "card_2"},
        {"suit": "clubs", "value": 12, "id": "card_3"},
        {"suit": "spades", "value": 14, "id": "card_4"}
      ],
      "opponent_card_count": 4,
      "deck_remaining": 24,
      "scores": {
        "550e8400-e29b-41d4-a716-446655440000": 0,
        "player_456": 0
      },
      "table_cards": [],
      "trick_number": 1
    }
  }
}
```

### Card Played
**Client → Server**
```json
{
  "type": "card_played",
  "id": "msg_card_played_001",
  "player_id": "550e8400-e29b-41d4-a716-446655440000",
  "game_id": "game_550e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2024-01-20T15:35:15.123Z",
  "payload": {
    "card": {
      "suit": "hearts",
      "value": 7,
      "id": "card_1"
    },
    "move_sequence": 1,
    "client_state_hash": "abc123def456"  // Client state verification
  }
}
```

### Game State Update
**Server → Both Players** (after each move)
```json
{
  "type": "game_state",
  "id": "msg_game_state_001", 
  "game_id": "game_550e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2024-01-20T15:35:15.200Z",
  "payload": {
    "move_result": {
      "played_by": "550e8400-e29b-41d4-a716-446655440000",
      "card": {"suit": "hearts", "value": 7, "id": "card_1"},
      "valid": true,
      "beat_previous": true
    },
    "current_state": {
      "current_player": "player_456",
      "table_cards": [
        {
          "suit": "hearts", 
          "value": 7, 
          "played_by": "550e8400-e29b-41d4-a716-446655440000",
          "position": 0
        }
      ],
      "your_cards": [
        {"suit": "diamonds", "value": 10, "id": "card_2"},
        {"suit": "clubs", "value": 12, "id": "card_3"},
        {"suit": "spades", "value": 14, "id": "card_4"}
      ],
      "opponent_card_count": 4,
      "valid_moves": [
        {"suit": "diamonds", "value": 7},  // Same value
        {"suit": "clubs", "value": 7}     // Same value
      ],
      "scores": {
        "550e8400-e29b-41d4-a716-446655440000": 0,
        "player_456": 0
      },
      "trick_number": 1,
      "move_sequence": 2,
      "time_remaining": {
        "current_player": 28500,
        "total_time": {
          "550e8400-e29b-41d4-a716-446655440000": 582000,
          "player_456": 600000
        }
      }
    }
  }
}
```

### Continue Trick Decision
**Client → Server**
```json
{
  "type": "continue_trick",
  "id": "msg_continue_001",
  "player_id": "550e8400-e29b-41d4-a716-446655440000",
  "game_id": "game_550e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2024-01-20T15:35:45.000Z",
  "payload": {
    "action": "continue", // "continue" or "stop"
    "move_sequence": 5
  }
}
```

### Trick Complete
**Server → Both Players**
```json
{
  "type": "trick_complete",
  "id": "msg_trick_complete_001",
  "game_id": "game_550e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2024-01-20T15:36:00.000Z",
  "payload": {
    "trick_winner": "550e8400-e29b-41d4-a716-446655440000",
    "cards_won": [
      {"suit": "hearts", "value": 7},
      {"suit": "diamonds", "value": 10}, // Point card
      {"suit": "clubs", "value": 9}
    ],
    "points_awarded": 1, // 1 point for the 10 of diamonds
    "trick_summary": {
      "total_cards": 3,
      "point_cards": 1,
      "winning_card": {"suit": "hearts", "value": 7}
    },
    "new_scores": {
      "550e8400-e29b-41d4-a716-446655440000": 1,
      "player_456": 0
    },
    "next_starter": "550e8400-e29b-41d4-a716-446655440000"
  }
}
```

### Game End
**Server → Both Players**
```json
{
  "type": "game_end",
  "id": "msg_game_end_001",
  "game_id": "game_550e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2024-01-20T15:45:30.000Z",
  "payload": {
    "winner": "550e8400-e29b-41d4-a716-446655440000",
    "reason": "normal", // "normal", "forfeit", "timeout", "disconnect"
    "final_scores": {
      "550e8400-e29b-41d4-a716-446655440000": 5,
      "player_456": 3
    },
    "game_statistics": {
      "duration": 632, // seconds
      "total_tricks": 8,
      "cards_played": 32,
      "mars": false
    },
    "rating_changes": {
      "550e8400-e29b-41d4-a716-446655440000": +18,
      "player_456": -18
    },
    "rewards": {
      "winner": {
        "xp": 50,
        "coins": 25
      },
      "loser": {
        "xp": 15,
        "coins": 5
      }
    },
    "achievements": [
      {
        "player_id": "550e8400-e29b-41d4-a716-446655440000",
        "achievement": "win_streak_5",
        "unlocked": true
      }
    ]
  }
}
```

## 💬 Communication Messages

### Chat Message
**Client → Server**
```json
{
  "type": "chat_message",
  "id": "msg_chat_001",
  "player_id": "550e8400-e29b-41d4-a716-446655440000",
  "game_id": "game_550e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2024-01-20T15:36:15.000Z",
  "payload": {
    "message": "Good game!",
    "message_type": "text" // "text", "quick_chat"
  }
}
```

**Server → Opponent**
```json
{
  "type": "chat_message",
  "id": "msg_chat_002",
  "game_id": "game_550e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2024-01-20T15:36:15.050Z",
  "payload": {
    "from_player": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "username": "player123"
    },
    "message": "Good game!",
    "message_type": "text"
  }
}
```

### Emote
**Client → Server**
```json
{
  "type": "emote",
  "id": "msg_emote_001",
  "player_id": "550e8400-e29b-41d4-a716-446655440000",
  "game_id": "game_550e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2024-01-20T15:36:30.000Z",
  "payload": {
    "emote_id": "thumbs_up",
    "emote_name": "Thumbs Up"
  }
}
```

## ⚠️ Error Handling Messages

### Error Response
**Server → Client**
```json
{
  "type": "error",
  "id": "msg_error_001",
  "player_id": "550e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2024-01-20T15:30:15.000Z",
  "payload": {
    "error_code": "INVALID_MOVE",
    "message": "Card cannot beat the current table card",
    "details": {
      "attempted_card": {"suit": "diamonds", "value": 9},
      "table_card": {"suit": "hearts", "value": 10},
      "valid_moves": [
        {"suit": "hearts", "value": 10},
        {"suit": "clubs", "value": 7}
      ]
    },
    "original_message_id": "msg_card_played_001"
  }
}
```

### Common Error Codes
```
AUTHENTICATION_FAILED - Invalid or expired token
INVALID_MESSAGE_FORMAT - Malformed JSON or missing fields
GAME_NOT_FOUND - Game ID doesn't exist
NOT_YOUR_TURN - Player attempted move out of turn
INVALID_MOVE - Move violates game rules
CARD_NOT_IN_HAND - Player doesn't have the specified card
TIME_EXCEEDED - Move took too long
PLAYER_DISCONNECTED - Opponent lost connection
SERVER_ERROR - Internal server error
RATE_LIMIT_EXCEEDED - Too many messages sent
```

## 🔄 State Synchronization

### Client-Side Prediction
```swift
class GameStateSynchronizer {
    func handleLocalMove(_ card: Card) {
        // 1. Optimistically update local state
        localGameState.playCard(card)
        
        // 2. Send move to server
        sendCardPlayedMessage(card)
        
        // 3. Add to pending moves queue
        pendingMoves.append(GameMove(card: card, sequence: nextSequence()))
    }
    
    func handleServerStateUpdate(_ update: GameStateMessage) {
        // 1. Validate sequence number
        if update.moveSequence <= lastServerSequence {
            return // Ignore old updates
        }
        
        // 2. Reconcile with pending moves
        reconcilePendingMoves(serverState: update.currentState)
        
        // 3. Update authoritative state
        serverGameState = update.currentState
        lastServerSequence = update.moveSequence
    }
}
```

### Conflict Resolution
```
1. Server is always authoritative
2. Client predictions are rolled back if server disagrees
3. Pending moves are replayed after server correction
4. UI smoothly transitions to corrected state
5. Players are notified of significant corrections
```

## 🔌 Reconnection Protocol

### Automatic Reconnection
```swift
class WebSocketManager {
    func handleDisconnection() {
        // 1. Start exponential backoff reconnection
        let delays = [1, 2, 4, 8, 16, 30] // seconds
        
        for delay in delays {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            
            if try await attemptReconnection() {
                break
            }
        }
    }
    
    func attemptReconnection() async throws -> Bool {
        // 1. Establish WebSocket connection
        // 2. Send connect message with reconnection flag
        // 3. Receive missed messages from server
        // 4. Synchronize game state
        // 5. Resume normal operation
    }
}
```

### State Recovery
**Client → Server** (on reconnection)
```json
{
  "type": "connect",
  "payload": {
    "reconnection": true,
    "last_message_id": "msg_game_state_015",
    "last_sequence": 23,
    "game_id": "game_550e8400-e29b-41d4-a716-446655440000"
  }
}
```

**Server → Client** (state recovery response)
```json
{
  "type": "connection_ack",
  "payload": {
    "missed_messages": [
      // Array of messages sent since last_message_id
    ],
    "current_game_state": {
      // Current authoritative game state
    },
    "reconnection_successful": true
  }
}
```

## 📊 Performance & Monitoring

### Message Size Limits
- **Maximum message size:** 64KB
- **Maximum queue depth:** 100 messages
- **Heartbeat timeout:** 90 seconds
- **Move timeout:** 30 seconds per turn

### Latency Optimization
```go
// Server-side message batching
type MessageBatch struct {
    messages []Message
    maxSize  int
    maxDelay time.Duration
}

func (b *MessageBatch) shouldFlush() bool {
    return len(b.messages) >= b.maxSize || 
           time.Since(b.firstMessage) >= b.maxDelay
}
```

### Connection Monitoring
```json
{
  "type": "system_message",
  "payload": {
    "message_type": "connection_quality",
    "metrics": {
      "latency": 45,
      "packet_loss": 0.01,
      "jitter": 5,
      "quality": "excellent" // poor, fair, good, excellent
    }
  }
}
```

This WebSocket protocol ensures reliable, low-latency multiplayer gameplay with robust error handling and state synchronization for the Septica card game.