# Septica - Full-Stack Technical Architecture

## 🏗️ System Overview

Septica is built as a modern, scalable full-stack application with an iOS Metal-powered client and a high-performance Go backend. The architecture emphasizes real-time gameplay, competitive integrity, and exceptional user experience.

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   iOS Client    │◄───┤   Load Balancer  ├───►│   Go Backend    │
│  (Metal + UI)   │    │   (nginx/TLS)    │    │ (API + WebSocket)│
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                                               │
         │                                               │
    ┌─────────┐                                  ┌──────────────┐
    │ GameKit │                                  │ PostgreSQL   │
    │  Cache  │                                  │   + Redis    │
    └─────────┘                                  └──────────────┘
```

## 📱 iOS Client Architecture

### Core Framework Stack
```
┌─────────────────────────────────────────────────────┐
│                  SwiftUI Views                      │
├─────────────────────────────────────────────────────┤
│                   ViewModels                        │
├─────────────────────────────────────────────────────┤
│    Controllers    │    Services    │   Coordinators  │
├─────────────────────────────────────────────────────┤
│                Metal Rendering Engine               │
├─────────────────────────────────────────────────────┤
│     Models      │   Persistence  │    Networking    │
├─────────────────────────────────────────────────────┤
│                 Foundation/UIKit                    │
└─────────────────────────────────────────────────────┘
```

### MVVM-C Pattern Implementation

#### Models Layer (`/Models/`)
```swift
// Core game models
struct Card {
    let suit: Suit
    let value: Int // 7-14
    let id: UUID
    
    var isPointCard: Bool {
        return value == 10 || value == 14 // Aces
    }
}

struct GameState {
    var currentPlayer: Player
    var tableCards: [Card]
    var playerHands: [PlayerID: [Card]]
    var scores: [PlayerID: Int]
    var phase: GamePhase
}

// Network models
struct GameMessage: Codable {
    let type: MessageType
    let playerId: String
    let payload: MessagePayload
    let timestamp: Date
}
```

#### ViewModels (`/ViewModels/`)
```swift
@MainActor
class GameViewModel: ObservableObject {
    @Published var gameState: GameState
    @Published var validMoves: [Card] = []
    @Published var isMyTurn: Bool = false
    
    private let gameService: GameService
    private let networkService: NetworkService
    
    func playCard(_ card: Card) async {
        await gameService.playCard(card)
    }
}
```

#### Services Layer (`/Services/`)
```swift
protocol GameService {
    func playCard(_ card: Card) async throws
    func startGame() async throws
    func forfeit() async throws
}

protocol NetworkService {
    func connect() async throws
    func sendMessage(_ message: GameMessage) async throws
    var messageStream: AsyncStream<GameMessage> { get }
}
```

### Metal Rendering Pipeline

#### Rendering Architecture
```
┌─────────────────┐
│  GameRenderer   │ ← Main renderer coordinator
├─────────────────┤
│   CardRenderer  │ ← Specialized card rendering
├─────────────────┤
│  TableRenderer  │ ← Game table and environment
├─────────────────┤
│ ParticleSystem  │ ← Visual effects
├─────────────────┤
│   ShaderLib     │ ← Vertex/Fragment shaders
└─────────────────┘
```

#### Rendering Components
```swift
class CardRenderer {
    private var pipelineState: MTLRenderPipelineState
    private var vertexBuffer: MTLBuffer
    private var indexBuffer: MTLBuffer
    private var textureAtlas: MTLTexture
    
    func render(cards: [Card], 
                encoder: MTLRenderCommandEncoder,
                viewMatrix: matrix_float4x4)
}

// Metal shaders for cards
vertex VertexOut cardVertexShader(
    VertexIn in [[stage_in]],
    constant Uniforms& uniforms [[buffer(0)]],
    uint instanceId [[instance_id]]
) {
    // Transform card position and rotation
    // Apply camera view and projection matrices
}

fragment float4 cardFragmentShader(
    VertexOut in [[stage_in]],
    texture2d<float> cardTexture [[texture(0)]]
) {
    // Sample card texture
    // Apply lighting and effects
}
```

### Networking Layer

#### WebSocket Implementation
```swift
class GameWebSocketService: NSObject, NetworkService {
    private var webSocket: URLSessionWebSocketTask?
    private let session = URLSession(configuration: .default)
    
    func connect() async throws {
        let url = URL(string: "wss://api.septica.game/ws")!
        webSocket = session.webSocketTask(with: url)
        webSocket?.resume()
        
        startListening()
    }
    
    private func startListening() {
        webSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleMessage(message)
            case .failure(let error):
                self?.handleError(error)
            }
        }
    }
}
```

#### State Synchronization
```swift
class GameStateSynchronizer {
    private var localState: GameState
    private var serverState: GameState
    private let reconciliationQueue = DispatchQueue(label: "game.sync")
    
    func reconcileState(_ serverUpdate: GameStateUpdate) {
        reconciliationQueue.async {
            // Compare local predictions with server authority
            // Rollback and replay if mismatch detected
            // Update UI with corrected state
        }
    }
}
```

## 🖥️ Go Backend Architecture

### Service Architecture
```
┌─────────────────────────────────────────────────────────┐
│                    Load Balancer                        │
│                     (nginx)                             │
└─────────────────────┬───────────────────────────────────┘
                      │
    ┌─────────────────┼─────────────────┐
    │                 │                 │
┌───▼───┐        ┌────▼────┐       ┌────▼────┐
│ API   │        │WebSocket│       │ Match   │
│Server │        │ Server  │       │ Maker   │
└───────┘        └─────────┘       └─────────┘
    │                 │                 │
    └─────────────────┼─────────────────┘
                      │
            ┌─────────▼─────────┐
            │                   │
        ┌───▼───┐          ┌────▼────┐
        │ Redis │          │Postgres │
        │ Cache │          │Database │
        └───────┘          └─────────┘
```

### Core Services Structure
```go
// Main application structure
type App struct {
    router      *gin.Engine
    db          *gorm.DB
    redis       *redis.Client
    wsHub       *websocket.Hub
    gameManager *game.Manager
    matchmaker  *matchmaking.Service
}

// Game service interfaces
type GameService interface {
    CreateGame(player1, player2 *Player) (*Game, error)
    PlayCard(gameID string, playerID string, card Card) error
    GetGameState(gameID string) (*GameState, error)
    EndGame(gameID string, reason string) error
}

type MatchmakingService interface {
    JoinQueue(player *Player) error
    LeaveQueue(playerID string) error
    FindMatch(rating int) (*Match, error)
}
```

### WebSocket Hub Implementation
```go
type Hub struct {
    clients    map[string]*Client
    games      map[string]*GameRoom
    register   chan *Client
    unregister chan *Client
    mutex      sync.RWMutex
}

type GameRoom struct {
    id      string
    players map[string]*Client
    game    *Game
    state   *GameState
}

func (h *Hub) HandleMessage(client *Client, msg *Message) {
    switch msg.Type {
    case MessageTypePlayCard:
        h.handlePlayCard(client, msg)
    case MessageTypeContinueTrick:
        h.handleContinueTrick(client, msg)
    case MessageTypeChat:
        h.handleChat(client, msg)
    }
}
```

### Game Logic Engine
```go
type Game struct {
    ID          string    `json:"id"`
    Player1ID   string    `json:"player1_id"`
    Player2ID   string    `json:"player2_id"`
    State       GameState `json:"state"`
    CreatedAt   time.Time `json:"created_at"`
    UpdatedAt   time.Time `json:"updated_at"`
}

type GameEngine struct {
    rules *SepticaRules
}

func (e *GameEngine) ValidateMove(game *Game, playerID string, card Card) error {
    // Validate player turn
    if game.State.CurrentPlayer != playerID {
        return ErrNotPlayerTurn
    }
    
    // Validate card ownership
    if !game.State.PlayerHasCard(playerID, card) {
        return ErrInvalidCard
    }
    
    // Validate game rules
    if !e.rules.CanPlayCard(card, game.State.TableCards) {
        return ErrInvalidMove
    }
    
    return nil
}

func (e *GameEngine) ApplyMove(game *Game, playerID string, card Card) {
    // Update game state
    game.State.RemoveCardFromPlayer(playerID, card)
    game.State.AddCardToTable(card)
    game.State.LastMove = Move{PlayerID: playerID, Card: card}
    
    // Check for trick completion
    if e.rules.IsTrickComplete(game.State) {
        winner := e.rules.DetermineTrickWinner(game.State.TableCards)
        points := e.rules.CountPoints(game.State.TableCards)
        game.State.AwardPoints(winner, points)
        game.State.ClearTable()
    }
    
    // Check for game end
    if e.rules.IsGameComplete(game.State) {
        game.State.Status = GameStatusCompleted
        game.State.Winner = e.rules.DetermineGameWinner(game.State)
    }
}
```

### Authentication & Security
```go
type AuthService struct {
    jwtSecret []byte
    db        *gorm.DB
}

func (s *AuthService) ValidateToken(token string) (*User, error) {
    claims := &jwt.Claims{}
    _, err := jwt.ParseWithClaims(token, claims, func(token *jwt.Token) (interface{}, error) {
        return s.jwtSecret, nil
    })
    
    if err != nil {
        return nil, err
    }
    
    user := &User{}
    if err := s.db.First(user, claims.UserID).Error; err != nil {
        return nil, err
    }
    
    return user, nil
}

// Rate limiting middleware
func RateLimitMiddleware(requests int, duration time.Duration) gin.HandlerFunc {
    limiter := rate.NewLimiter(rate.Every(duration/time.Duration(requests)), requests)
    
    return func(c *gin.Context) {
        if !limiter.Allow() {
            c.JSON(http.StatusTooManyRequests, gin.H{"error": "Rate limit exceeded"})
            c.Abort()
            return
        }
        c.Next()
    }
}
```

## 🗄️ Database Design

### PostgreSQL Schema
```sql
-- Users and authentication
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Player profiles and stats
CREATE TABLE players (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    rating INTEGER DEFAULT 1200,
    level INTEGER DEFAULT 1,
    xp INTEGER DEFAULT 0,
    coins INTEGER DEFAULT 1000,
    gems INTEGER DEFAULT 50,
    games_played INTEGER DEFAULT 0,
    games_won INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Game records
CREATE TABLE games (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player1_id UUID NOT NULL,
    player2_id UUID NOT NULL,
    winner_id UUID,
    game_data JSONB NOT NULL,
    duration INTEGER, -- seconds
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT NOW(),
    ended_at TIMESTAMP,
    FOREIGN KEY (player1_id) REFERENCES players(id),
    FOREIGN KEY (player2_id) REFERENCES players(id),
    FOREIGN KEY (winner_id) REFERENCES players(id)
);

-- Match history for analysis
CREATE TABLE match_moves (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    game_id UUID NOT NULL,
    player_id UUID NOT NULL,
    move_number INTEGER NOT NULL,
    card_played JSONB NOT NULL,
    game_state_before JSONB NOT NULL,
    timestamp TIMESTAMP DEFAULT NOW(),
    FOREIGN KEY (game_id) REFERENCES games(id),
    FOREIGN KEY (player_id) REFERENCES players(id)
);

-- Leaderboards and rankings
CREATE TABLE rankings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_id UUID NOT NULL,
    season VARCHAR(50) NOT NULL,
    rating INTEGER NOT NULL,
    rank INTEGER NOT NULL,
    arena INTEGER NOT NULL,
    updated_at TIMESTAMP DEFAULT NOW(),
    FOREIGN KEY (player_id) REFERENCES players(id)
);
```

### Redis Caching Strategy
```go
type CacheService struct {
    client *redis.Client
}

// Cache game states for fast access
func (c *CacheService) SetGameState(gameID string, state *GameState) error {
    data, err := json.Marshal(state)
    if err != nil {
        return err
    }
    
    return c.client.Set(ctx, fmt.Sprintf("game:%s", gameID), data, time.Hour).Err()
}

// Cache player sessions
func (c *CacheService) SetPlayerSession(playerID string, sessionData *SessionData) error {
    key := fmt.Sprintf("session:%s", playerID)
    return c.client.HMSet(ctx, key, map[string]interface{}{
        "game_id": sessionData.GameID,
        "status":  sessionData.Status,
        "joined":  sessionData.JoinedAt.Unix(),
    }).Err()
}

// Cache matchmaking queues
func (c *CacheService) AddToQueue(rating int, playerID string) error {
    queue := fmt.Sprintf("queue:%d", rating/100*100) // Group by rating ranges
    return c.client.ZAdd(ctx, queue, &redis.Z{
        Score:  float64(time.Now().Unix()),
        Member: playerID,
    }).Err()
}
```

## 🔄 Real-time Communication

### WebSocket Protocol
```go
type Message struct {
    Type      string          `json:"type"`
    PlayerID  string          `json:"player_id"`
    GameID    string          `json:"game_id"`
    Payload   json.RawMessage `json:"payload"`
    Timestamp time.Time       `json:"timestamp"`
}

// Message types
const (
    MsgTypeConnect      = "connect"
    MsgTypePlayCard     = "play_card"
    MsgTypeContinue     = "continue_trick"
    MsgTypeGameState    = "game_state"
    MsgTypeGameEnd      = "game_end"
    MsgTypeChat         = "chat"
    MsgTypeEmote        = "emote"
)

// Payload structures
type PlayCardPayload struct {
    Card Card `json:"card"`
}

type GameStatePayload struct {
    State     GameState `json:"state"`
    YourTurn  bool      `json:"your_turn"`
    ValidMoves []Card   `json:"valid_moves"`
}
```

### State Synchronization Strategy
```swift
class GameStateSynchronizer {
    private var localState: GameState
    private var pendingMoves: [GameMove] = []
    private var lastServerUpdate: Date
    
    func processServerUpdate(_ update: GameStateUpdate) {
        // Server reconciliation algorithm
        if update.timestamp > lastServerUpdate {
            // Apply server state
            localState = update.state
            
            // Replay any moves made after server timestamp
            replayPendingMoves(after: update.timestamp)
        }
        
        // Client-side prediction for smooth UX
        predictNextState(from: localState)
    }
    
    func playCard(_ card: Card) {
        // Optimistic update
        let move = GameMove(card: card, timestamp: Date())
        pendingMoves.append(move)
        
        // Update local state immediately
        localState.applyMove(move)
        
        // Send to server
        networkService.sendMove(move)
    }
}
```

## 🚀 Performance Optimizations

### iOS Client Optimizations
```swift
// Metal rendering optimizations
class OptimizedCardRenderer {
    private var instanceBuffer: MTLBuffer
    private var cardInstances: [CardInstance] = []
    
    func renderCards(_ cards: [Card]) {
        // Batch render all cards in single draw call
        updateInstanceBuffer(with: cards)
        
        encoder.setVertexBuffer(instanceBuffer, offset: 0, index: 1)
        encoder.drawIndexedPrimitives(
            type: .triangle,
            indexCount: 6,
            indexType: .uint16,
            indexBuffer: indexBuffer,
            indexBufferOffset: 0,
            instanceCount: cards.count
        )
    }
}

// Memory management
class CardTextureManager {
    private let textureCache: NSCache<NSString, MTLTexture>
    private let maxCacheSize = 50 * 1024 * 1024 // 50MB
    
    func loadTexture(named name: String) -> MTLTexture? {
        if let cached = textureCache.object(forKey: name as NSString) {
            return cached
        }
        
        // Load and cache texture
        let texture = loadTextureFromBundle(name)
        textureCache.setObject(texture, forKey: name as NSString)
        return texture
    }
}
```

### Backend Optimizations
```go
// Connection pooling
type DatabaseService struct {
    db *gorm.DB
}

func NewDatabaseService(config *DatabaseConfig) *DatabaseService {
    db, err := gorm.Open(postgres.Open(config.DSN), &gorm.Config{
        Logger: logger.Default.LogMode(logger.Silent),
    })
    
    sqlDB, _ := db.DB()
    sqlDB.SetMaxIdleConns(10)
    sqlDB.SetMaxOpenConns(100)
    sqlDB.SetConnMaxLifetime(time.Hour)
    
    return &DatabaseService{db: db}
}

// Query optimization
func (s *DatabaseService) GetPlayerStats(playerID string) (*PlayerStats, error) {
    var stats PlayerStats
    
    // Single optimized query instead of multiple
    err := s.db.Table("players").
        Select(`
            players.*,
            COUNT(games.id) as total_games,
            SUM(CASE WHEN games.winner_id = players.id THEN 1 ELSE 0 END) as wins,
            AVG(games.duration) as avg_game_duration
        `).
        Joins("LEFT JOIN games ON players.id = games.player1_id OR players.id = games.player2_id").
        Where("players.id = ?", playerID).
        Group("players.id").
        Scan(&stats).Error
        
    return &stats, err
}

// Goroutine pool for handling concurrent games
type WorkerPool struct {
    jobs    chan Job
    workers int
}

func (p *WorkerPool) Start() {
    for i := 0; i < p.workers; i++ {
        go p.worker()
    }
}

func (p *WorkerPool) worker() {
    for job := range p.jobs {
        job.Execute()
    }
}
```

## 🛡️ Security Architecture

### Authentication Flow
```
1. User logs in → Backend validates credentials
2. Backend generates JWT token with expiry
3. Client stores token securely in Keychain
4. All API requests include Bearer token
5. WebSocket connection authenticated via token
6. Token refresh before expiry
```

### Anti-cheat Measures
```go
type AntiCheatService struct {
    gameStates map[string]*GameState
    moveTimes  map[string][]time.Time
}

func (s *AntiCheatService) ValidateMove(gameID, playerID string, move GameMove) error {
    // Check move timing (prevent instant moves)
    if move.Timestamp.Sub(lastMove) < time.Millisecond*100 {
        return ErrSuspiciouslyFastMove
    }
    
    // Validate game state consistency
    expectedState := s.gameStates[gameID]
    if !move.IsValidFor(expectedState) {
        return ErrInvalidGameState
    }
    
    // Pattern analysis (detect bots)
    if s.detectBotPattern(playerID) {
        return ErrBotDetected
    }
    
    return nil
}
```

## 📊 Monitoring & Analytics

### Performance Metrics
```go
// Prometheus metrics
var (
    gameStartsTotal = prometheus.NewCounter(prometheus.CounterOpts{
        Name: "septica_games_started_total",
        Help: "Total number of games started",
    })
    
    gameDuration = prometheus.NewHistogram(prometheus.HistogramOpts{
        Name:    "septica_game_duration_seconds",
        Help:    "Game duration in seconds",
        Buckets: []float64{60, 180, 300, 600, 1800},
    })
    
    activeConnections = prometheus.NewGauge(prometheus.GaugeOpts{
        Name: "septica_active_connections",
        Help: "Number of active WebSocket connections",
    })
)

// Health check endpoint
func healthCheck(c *gin.Context) {
    status := gin.H{
        "status":      "ok",
        "database":    checkDatabase(),
        "redis":       checkRedis(),
        "active_games": getActiveGameCount(),
    }
    
    c.JSON(200, status)
}
```

This architecture provides a solid foundation for a scalable, secure, and high-performance card game that can handle thousands of concurrent players while maintaining 60 FPS gameplay and sub-50ms network latency.