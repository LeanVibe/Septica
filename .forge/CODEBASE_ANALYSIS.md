# Septica Codebase Analysis for Rewrite

**Date:** 2026-02-02  
**Project:** Septica (Romanian Card Game)  
**Purpose:** Analysis for Rewrite Preparation  

---

## Executive Summary

This analysis covers the Septica codebase architecture to inform a complete rewrite. The codebase consists of:
- **Frontend:** 2,436 line vanilla JS game UI with Three.js 3D rendering
- **Backend:** Two competing game engines (471 lines legacy + 746 lines authentic)
- **WebSocket Protocol:** Real-time multiplayer with matchmaking and objection-based gameplay

---

## 1. Frontend Analysis: game-ui.js (2,436 lines)

### File Structure
```
frontend/js/
├── game-ui.js              # Main UI class (2,436 lines) - TOO LARGE
├── websocket-client.js     # WebSocket connection management
├── card-renderer-3d.js     # Three.js 3D card rendering
├── particle-effects.js     # Visual effects
├── premium-card-*.js       # Material/animation systems
├── romanian-septica-*.js   # Romanian rule implementations
└── mobile-*.js             # Mobile-specific features
```

### Components to Extract from game-ui.js

The GameUI class (~2,436 lines) should be split into 8-10 focused modules:

| New Module | Lines (est.) | Responsibility |
|------------|--------------|----------------|
| **ConnectionManager** | ~150 | WebSocket connect/disconnect, heartbeat |
| **GameStateStore** | ~200 | State management, caching |
| **CardRenderer** | ~300 | 2D/3D card display, animations |
| **UIManager** | ~250 | DOM manipulation, element caching |
| **EventHandler** | ~200 | Click handlers, keyboard shortcuts |
| **RomanianRulesEngine** | ~150 | Move validation, objection logic |
| **MultiplayerDisplay** | ~200 | Player layouts, turn indicators |
| **ObjectionSystem** | ~200 | Objection UI, timer, pass/object buttons |
| **PWAHandler** | ~100 | Service worker, install prompt |
| **PerformanceMonitor** | ~150 | FPS, latency, stats |
| **Logger** | ~100 | Message logging, export |

### Key Methods in GameUI (56 total methods)

**Connection Management:**
- `handleConnect()` - WS connection with unique player ID
- `handleDisconnect()` - Clean disconnection
- `handlePing()` - Latency measurement
- `setWebSocketClient()` - Event handler binding

**Game Actions:**
- `handleCreateGame()` - Create new game
- `handleJoinGame()` - Join existing game
- `handleLeaveGame()` - Leave current game
- `handleGetGameState()` - Request state refresh
- `handlePlayCard()` - Play a card
- `handleObjection()` - Object to last card
- `handlePass()` - Pass without objecting

**UI Rendering:**
- `updateGameState()` - Main state update handler
- `displayCards()` - Render hand/table cards
- `createCardElement()` - Card DOM creation
- `updateMultiplayerDisplay()` - 2-4 player layouts
- `updateTurnIndicator()` - Turn status UI
- `initialize3DRenderer()` - Three.js setup

**Romanian Septica Specific:**
- `initializeRomanianSepticaFeatures()` - Setup objection UI
- `isValidRomanianSepticaMove()` - Client-side validation
- `showObjectionDecision()` - Display objection options
- `showRoundComplete()` - Round end display

---

## 2. Backend Engine Comparison

### Two Parallel Engines

| Aspect | Legacy Engine (engine.go) | Authentic Engine (authentic_engine.go) |
|--------|---------------------------|----------------------------------------|
| **Lines** | 471 | 746 |
| **GameState** | `GameState` (struct with Player1/Player2) | `AuthenticGameState` (flexible players array) |
| **Player Support** | 2 players only | 2, 3, or 4 players |
| **Teams** | Not supported | 2v2 team mode for 4 players |
| **Objection System** | Partial (WaitingForObjection bool) | Full objection workflow |
| **Database** | No persistence | GORM persistence |
| **Wild Cards** | 7s always wild | 7s + 8s (in 3-player) |
| **Scoring** | Individual only | Individual + Team scores |
| **Move Recording** | No | Full move history |

### GameState Structures

**Legacy GameState:**
```go
type GameState struct {
    ID              uuid.UUID
    Player1ID       uuid.UUID
    Player2ID       uuid.UUID
    CurrentPlayerID uuid.UUID
    Status          string
    GameMode        GameMode  // TwoPlayers, ThreePlayers, FourPlayers
    Player1Hand     []Card
    Player2Hand     []Card
    TableCards      []Card
    Deck            []Card
    WaitingForObjection bool
    ObjectionDeadline   *time.Time
    LastPlayedCard      *Card
    Player1Score    int
    Player2Score    int
    TrickNumber     int
    MoveNumber      int
    mu              sync.Mutex
}
```

**Authentic GameState:**
```go
type AuthenticGameState struct {
    ID              uuid.UUID
    Players         []uuid.UUID       // 2-4 players
    Teams           [][]uuid.UUID     // For 4-player
    CurrentPlayerID uuid.UUID
    Status          string            // waiting, playing, finished
    GameMode        AuthenticGameMode // ModeTwoPlayer, ModeThreePlayer, ModeFourPlayer
    
    // Objection state
    WaitingForObjection bool
    LastPlayedCard      *Card
    LastPlayerID        uuid.UUID
    TableCards          []Card
    
    // Player data (indexed by ID)
    PlayerHands  map[uuid.UUID][]Card
    PlayerScores map[uuid.UUID]int
    TeamScores   map[string]int  // "team1", "team2"
    
    // Deck
    Deck       []Card
    WildEights bool  // true for 3-player
    
    // Progression
    RoundNumber    int
    MoveNumber     int
    SequenceNumber int
}
```

### Key Differences in Game Flow

**Legacy Engine Flow:**
1. `PlayCard()` - Play a card
2. Check if opponent can beat
3. If not: trick complete, award points
4. Deal new cards
5. Switch turn

**Authentic Engine Flow:**
1. `ProcessAction()` - PLAY_CARD or PASS
2. If initial play: set WaitingForObjection, next player must object/pass
3. If objection: validate can beat, complete round
4. If pass: original player takes cards
5. Persist move to database
6. Award points, deal cards

### Rule Differences

| Rule | Legacy | Authentic |
|------|--------|-----------|
| 7s | Wild (beat everything) | Wild |
| 8s | Normal card | Wild in 3-player mode |
| Beating same value | Yes | Yes |
| Higher same suit | Yes | Yes |
| Objection mechanic | Basic | Full with timeout |
| Team play | No | 2v2 in 4-player |
| Database logging | No | Full game history |

---

## 3. Game State & Events

### Core Game State

```typescript
interface GameState {
  // Identity
  game_id: string;
  current_player_id: string;
  your_turn: boolean;
  
  // Cards
  your_cards: Card[];
  opponent_card_count: number;
  table_cards: Card[];
  valid_moves: Card[];
  
  // Scoring
  scores: Record<string, number>;
  trick_number: number;
  move_number: number;
  
  // Objection system (Authentic)
  waiting_for_objection: boolean;
  last_played_card: Card | null;
  last_player_id: string | null;
  can_pass: boolean;
  objection_timeout: number;
  
  // Multiplayer
  game_mode: "2_player" | "3_player" | "4_player";
  teams?: string[][];
  team_scores?: Record<string, number>;
  
  // Sync
  sequence_number: number;
  status: "waiting" | "in_progress" | "completed";
}

interface Card {
  suit: "hearts" | "diamonds" | "clubs" | "spades";
  value: 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14; // J=11, Q=12, K=13, A=14
  id: string;
}
```

### Game Events

**Client -> Server:**
| Event | Payload | Description |
|-------|---------|-------------|
| `ping` | - | Latency check |
| `join_game` | `{ game_mode? }` | Join/create game |
| `leave_game` | - | Leave current game |
| `play_card` | `{ suit, value, id }` | Play a card |
| `pass` | - | Pass without objecting |
| `object` | - | Object (sent via play_card with valid card) |
| `get_game_state` | - | Request state refresh |
| `join_matchmaking` | `{ queue_type, game_mode }` | Join queue |
| `leave_matchmaking` | - | Leave queue |
| `chat_message` | `{ message, type? }` | Send chat |

**Server -> Client:**
| Event | Payload | Description |
|-------|---------|-------------|
| `pong` | `{ server_time }` | Ping response |
| `connection_ack` | `{ session_id, heartbeat_interval }` | Connected |
| `game_state` | `GameStatePayload` | Full state update |
| `move_result` | `{ valid, error?, trick_complete, points_awarded }` | Move outcome |
| `objection_wait` | `{ waiting_player_id, last_played_card, valid_objections }` | Objection prompt |
| `round_complete` | `{ collector_player_id, points_awarded, cards_collected, was_objected }` | Round ended |
| `player_turn` | `{ player_id }` | Turn change |
| `player_joined` | `{ player_id, username }` | New player |
| `player_left` | `{ player_id, reason }` | Player left |
| `game_end` | `{ winner_id?, reason, final_score }` | Game over |
| `match_found` | `{ game_id, opponent_id, opponent_name }` | Matchmaking |
| `error` | `{ error_type, message }` | Error |

### State Machine

```
[waiting] --join_game--> [playing]
   |
   |--all players pass-->
   v
[round_complete] --deal cards--> [playing]
   |
   |--game complete-->
   v
[finished]
```

**Objection Sub-State:**
```
[playing] --play_card--> [waiting_for_objection]
   |
   |--play_valid_objection-->
   v
[round_complete - objector wins]
   |
   |--pass-->
   v
[round_complete - original player wins]
```

---

## 4. WebSocket Protocol

### Connection Flow

```
Client                                          Server
  |                                               |
  |-- WebSocket ws://host:8082/ws/connect?user_id=xxx -->
  |                                               |
  |<---------------- connection_ack ---------------|
  |  { session_id, heartbeat_interval: 30000 }   |
  |                                               |
  |-- join_game { game_mode: "2_player" } -------->|
  |                                               |
  |<---------------- game_state -------------------|
  |                                               |
  |<---------------- player_joined ----------------|
  |                                               |
  |=== [every 30s] ===                            |
  |-- ping --------------------------------------->|
  |<---------------- pong -------------------------|
```

### Message Format

**Request:**
```json
{
  "type": "play_card",
  "id": "msg-uuid",
  "game_id": "game-uuid",
  "payload": {
    "suit": "hearts",
    "value": 7,
    "id": "card-uuid"
  }
}
```

**Response:**
```json
{
  "type": "game_state",
  "id": "msg-uuid",
  "player_id": "player-uuid",
  "game_id": "game-uuid",
  "timestamp": "2024-01-15T10:30:00Z",
  "payload": {
    "game_id": "game-uuid",
    "current_player_id": "player-uuid",
    "your_turn": true,
    "your_cards": [...],
    "table_cards": [...],
    "waiting_for_objection": false
  }
}
```

### Error Handling

**Error Types:**
- `invalid_message` - Malformed message
- `not_authorized` - Authentication required
- `game_not_found` - Invalid game ID
- `player_not_in_game` - Player not in this game
- `invalid_move` - Illegal card play
- `not_player_turn` - Playing out of turn
- `game_full` - Cannot join, game full
- `rate_limited` - Too many requests
- `server_error` - Internal error

### Matchmaking Protocol

```
Client                                          Server
  |                                               |
  |-- join_matchmaking { queue_type: "ranked" } -->|
  |                                               |
  |<--------------- matchmaking_joined -----------|
  |                                               |
  |<--------------- matchmaking_update -----------|
  |  { queue_position, estimated_wait_time }     |
  |                                               |
  |<--------------- match_found ------------------|
  |  { game_id, opponent_id, opponent_name }     |
  |                                               |
  |-- leave_matchmaking ------------------------->|
  |                                               |
  |<--------------- matchmaking_left -------------|
```

---

## 5. Romanian Septica Rules

### Card Values
- **7** - Wild card (beats everything in all modes)
- **8** - Wild card (only in 3-player mode)
- **9-10** - Face value
- **J (11)** - Jack
- **Q (12)** - Queen
- **K (13)** - King
- **A (14)** - Ace (highest)

### Valid Moves
1. **Empty table:** Any card can be played
2. **7 (or 8 in 3-player):** Always beats everything
3. **Same value:** Beats regardless of suit
4. **Same suit, higher value:** Beats (e.g., 9♥ beats 7♥)
5. **Invalid:** Lower value, different suit

### Objection Mechanic (Authentic)
1. Player A plays a card
2. Player B (next player) can:
   - **Object** with a valid card (takes all cards)
   - **Pass** (Player A takes all cards)
3. If Player B objects, play continues to Player C (if exists)

### Scoring
- **10 of diamonds:** 2 points
- **All other 10s:** 1 point
- **Aces:** 1 point each
- **Total:** 11 points per deck

### Game Modes
- **2-player:** 32 cards (7-14), 7s wild, 8s normal
- **3-player:** 30 cards (remove 2 eights), 7s + remaining 8s wild
- **4-player:** 32 cards, team play (1+3 vs 2+4), 7s wild, 8s normal

---

## 6. Rewrite Recommendations

### Frontend Rewrite

**Technology Stack:**
- **Framework:** React 18+ with TypeScript
- **State:** Zustand or Redux Toolkit
- **3D:** Three.js via React Three Fiber
- **WebSocket:** Native WebSocket with reconnect logic
- **Styling:** Tailwind CSS + CSS Modules

**Component Structure:**
```
src/
├── components/
│   ├── Game/
│   │   ├── GameBoard.tsx       # Main game container
│   │   ├── CardHand.tsx        # Player's cards
│   │   ├── TableArea.tsx       # Cards on table
│   │   ├── PlayerBadge.tsx     # Player info display
│   │   ├── TurnIndicator.tsx   # Current turn UI
│   │   └── ObjectionPanel.tsx  # Object/pass buttons
│   ├── UI/
│   │   ├── ConnectionStatus.tsx
│   │   ├── ScoreBoard.tsx
│   │   ├── ChatPanel.tsx
│   │   └── ErrorBoundary.tsx
│   └── 3D/
│       ├── Card3D.tsx
│       ├── CardTable.tsx
│       └── ParticleEffects.tsx
├── hooks/
│   ├── useWebSocket.ts         # WebSocket connection
│   ├── useGameState.ts         # Game state management
│   ├── useRomanianRules.ts     # Move validation
│   └── useObjection.ts         # Objection state
├── services/
│   ├── gameEngine.ts           # Client-side rules
│   ├── romanianRules.ts        # Rule validation
│   └── cardRenderer.ts         # 2D/3D rendering
└── stores/
    ├── gameStore.ts
    └── connectionStore.ts
```

### Backend Rewrite

**Decision:** Use ONLY the Authentic Engine (delete legacy engine.go)

**Justification:**
1. Authentic engine is more complete (746 vs 471 lines)
2. Supports 2-4 players vs only 2
3. Full database persistence
4. Proper objection workflow
5. Team play support

**Refactored Structure:**
```
internal/
├── game/
│   ├── engine.go               # Main engine (authentic)
│   ├── state.go                # GameState types
│   ├── rules.go                # Rule validation
│   ├── objection.go            # Objection workflow
│   ├── scoring.go              # Point calculation
│   └── persistence.go          # Database operations
├── websocket/
│   ├── server.go               # WS server
│   ├── handler.go              # Message handlers
│   ├── hub.go                  # Client management
│   └── messages.go             # Message types
└── matchmaking/
    ├── queue.go                # Matchmaking queue
    └── rating.go               # ELO/rating system
```

### Database Schema

```sql
-- Games table
CREATE TABLE games (
    id UUID PRIMARY KEY,
    status VARCHAR(20), -- waiting, playing, finished
    game_mode VARCHAR(20), -- 2_player, 3_player, 4_player
    created_at TIMESTAMP,
    started_at TIMESTAMP,
    finished_at TIMESTAMP,
    winner_id UUID,
    team1_score INT DEFAULT 0,
    team2_score INT DEFAULT 0
);

-- Game players
CREATE TABLE game_players (
    game_id UUID,
    player_id UUID,
    player_position INT, -- 0, 1, 2, 3
    team INT, -- 1 or 2 (for 4-player)
    initial_hand JSONB,
    final_score INT DEFAULT 0,
    PRIMARY KEY (game_id, player_id)
);

-- Game moves (full history)
CREATE TABLE game_moves (
    id UUID PRIMARY KEY,
    game_id UUID,
    player_id UUID,
    move_number INT,
    trick_number INT,
    move_type VARCHAR(20), -- PLAY_CARD, PASS
    card_suit VARCHAR(10),
    card_value INT,
    is_objection BOOLEAN DEFAULT FALSE,
    objected_card_suit VARCHAR(10),
    objected_card_value INT,
    round_complete BOOLEAN,
    points_awarded INT,
    created_at TIMESTAMP
);

-- Cards table (for deck tracking)
CREATE TABLE game_cards (
    game_id UUID,
    card_id VARCHAR(50),
    suit VARCHAR(10),
    value INT,
    initial_owner UUID,
    current_owner UUID,
    location VARCHAR(20), -- hand, table, collected
    played_at TIMESTAMP,
    collected_by UUID,
    collected_at TIMESTAMP
);
```

---

## 7. Migration Path

### Phase 1: Backend Consolidation
1. Delete `engine.go` (legacy)
2. Rename `authentic_engine.go` -> `engine.go`
3. Update all imports
4. Ensure all tests pass

### Phase 2: Frontend Modularization
1. Extract WebSocket client to standalone module
2. Create game state store (Zustand)
3. Extract Romanian rules to pure functions
4. Split UI into React components
5. Migrate from vanilla JS to React gradually

### Phase 3: Feature Parity
1. 2-player mode (MVP)
2. Objection system
3. 3-player mode
4. 4-player team mode
5. Matchmaking
6. Database persistence

---

## 8. Key Files for Rewrite

### Must Preserve Logic From:
- `backend/internal/game/authentic_engine.go` - Core game logic
- `backend/internal/websocket/messages.go` - Protocol definitions
- `frontend/js/websocket-client.js` - Connection handling
- `frontend/js/romanian-septica-rules.js` - Rule validation

### Can Discard:
- `backend/internal/game/engine.go` - Legacy engine
- `frontend/js/game-ui.js` - Will be split into components
- All test files (rewrite tests for new stack)

---

## Summary

**The Septica codebase has two parallel game engines that need consolidation.** The Authentic Engine (746 lines) is superior and should be the foundation for the rewrite. The frontend game-ui.js (2,436 lines) is a monolithic class that should be split into ~10 focused modules in a React/TypeScript architecture.

**Key architectural decisions for rewrite:**
1. Use Authentic Engine only (delete legacy)
2. React + TypeScript frontend
3. WebSocket protocol remains unchanged
4. Database persistence required
5. Support 2-4 players with team mode

**Estimated rewrite effort:** 3-4 weeks for full feature parity.

---

**Analysis Status:** COMPLETE
