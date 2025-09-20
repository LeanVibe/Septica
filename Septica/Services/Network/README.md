# Septica iOS Network Layer

This directory contains the complete iOS network layer for Septica multiplayer functionality. The implementation provides seamless integration between the Go WebSocket backend and the existing iOS GameState system.

## Architecture Overview

The network layer follows a layered architecture with clear separation of concerns:

```
┌─────────────────────────────────────┐
│         SwiftUI Views               │
│   (MultiplayerIntegration.swift)   │
├─────────────────────────────────────┤
│      NetworkCoordinator             │
│   (High-level coordination)        │
├─────────────────────────────────────┤
│      MultiplayerService             │
│   (Game-specific operations)       │
├─────────────────────────────────────┤
│       NetworkManager               │
│   (WebSocket communication)        │
├─────────────────────────────────────┤
│      WebSocket Messages             │
│   (Protocol & serialization)       │
└─────────────────────────────────────┘
```

## Core Components

### 1. WebSocketMessage.swift
- **Purpose**: Defines message types and payload structures matching the Go backend
- **Key Features**:
  - Type-safe message definitions (`OutgoingMessage`, `IncomingMessage`)
  - All backend message types: `ping`, `pong`, `join_game`, `play_card`, `game_state`, etc.
  - Payload structures: `GameStatePayload`, `MoveResultPayload`, `PlayerJoinedPayload`, etc.
  - `AnyCodable` wrapper for flexible JSON handling
  - Message factory methods for easy message creation

### 2. NetworkManager.swift
- **Purpose**: Core WebSocket communication using `URLSessionWebSocketTask`
- **Key Features**:
  - Connection lifecycle management (connect, disconnect, reconnect)
  - Automatic reconnection with exponential backoff
  - Heartbeat/ping-pong for connection monitoring
  - App lifecycle integration (background/foreground handling)
  - Message queuing when disconnected
  - Comprehensive error handling and logging

### 3. MultiplayerService.swift
- **Purpose**: High-level game operations and server communication
- **Key Features**:
  - Game session management (finding games, joining, leaving)
  - Integration with existing `GameState` 
  - Real-time game state synchronization
  - Connection quality monitoring
  - Chat message handling
  - Game event publishing via Combine

### 4. NetworkCoordinator.swift
- **Purpose**: Coordinates networking services with the existing GameState
- **Key Features**:
  - Unified interface for multiplayer functionality
  - Seamless integration with existing single-player code
  - Reactive state synchronization
  - Multiplayer-aware game state updates
  - Error handling and user feedback

### 5. MultiplayerIntegration.swift
- **Purpose**: SwiftUI integration helpers and convenience components
- **Key Features**:
  - `MultiplayerGameViewModel` for easy view integration
  - Environment injection for `NetworkCoordinator`
  - Connection status and quality UI components
  - Convenience methods for multiplayer vs single-player handling

## Usage Examples

### Basic Integration

```swift
// Create network coordinator
let networkCoordinator = NetworkCoordinator()

// Enable multiplayer for a game state
networkCoordinator.enableMultiplayer(for: gameState)

// Find an opponent
networkCoordinator.findGame(mode: .casual)

// Play a card
networkCoordinator.playCard(selectedCard)
```

### SwiftUI Integration

```swift
struct GameView: View {
    @StateObject private var viewModel = MultiplayerGameViewModel(gameState: gameState)
    
    var body: some View {
        VStack {
            GameBoardView()
            
            MultiplayerControlsView(viewModel: viewModel)
        }
        .networkCoordinator(viewModel.networkCoordinator)
    }
}
```

### View Model Integration

```swift
class GameViewModel: ObservableObject {
    @Published var gameState: GameState
    private let networkCoordinator: NetworkCoordinator
    
    func playCard(_ card: Card) {
        if gameState.isMultiplayer {
            networkCoordinator.playCard(card)
        } else {
            gameState.playCard(card, by: currentPlayerId)
        }
    }
}
```

## Message Protocol

### Client → Server Messages

| Message Type | Purpose | Payload |
|-------------|---------|---------|
| `ping` | Connection test | None |
| `join_game` | Find/join game | `{game_mode: "casual"}` |
| `leave_game` | Leave current game | None |
| `play_card` | Play a card | `{suit: "hearts", value: 7}` |
| `get_game_state` | Request current state | None |
| `chat_message` | Send chat | `{message: "Good game!"}` |

### Server → Client Messages

| Message Type | Purpose | Payload |
|-------------|---------|---------|
| `connection_ack` | Connection confirmed | Session info |
| `game_state` | Full game state | Player hands, table, turn info |
| `move_result` | Card play result | Valid/invalid, trick status |
| `player_joined` | Opponent found | Player info |
| `player_left` | Opponent disconnected | Player info |
| `game_end` | Game finished | Winner, scores, stats |

## Connection States

The network layer manages several connection states:

- **`disconnected`**: No connection to server
- **`connecting`**: Attempting initial connection
- **`connected`**: Connected and ready for games
- **`reconnecting`**: Attempting to restore connection
- **`error`**: Connection failed

## Error Handling

Comprehensive error handling covers:

- **Network errors**: Connection timeouts, network unavailable
- **Server errors**: Invalid moves, game not found, authorization
- **Protocol errors**: Message parsing, encoding/decoding
- **Game errors**: Not player's turn, invalid game state

## Quality of Service

The implementation includes:

- **Connection monitoring**: Round-trip time tracking
- **Quality indicators**: Excellent/Good/Fair/Poor based on RTT
- **Automatic reconnection**: Exponential backoff with max attempts
- **Message queuing**: Pending messages sent on reconnection
- **App lifecycle handling**: Reconnect on foreground

## Integration with Existing Code

The network layer is designed to integrate seamlessly with the existing Septica codebase:

1. **GameState**: Uses existing multiplayer fields (`isMultiplayer`, `localPlayerId`, `connectionStatus`)
2. **Player**: Works with existing `Player` and `AIPlayer` classes
3. **Card**: Uses existing `Card` model with conversion to/from network format
4. **Game Rules**: Server validates moves using same rules as client

## Configuration

### Default Settings

- **Server URL**: `ws://localhost:8080/ws/connect` (development)
- **Heartbeat interval**: 30 seconds
- **Connection timeout**: 10 seconds
- **Max reconnection attempts**: 5
- **Reconnection delays**: [1, 2, 4, 8, 16] seconds

### Production Configuration

```swift
// Production server
let coordinator = NetworkCoordinator(
    baseURL: URL(string: "wss://septica-game.com/ws/connect")!
)
```

## Testing

All Swift files pass syntax validation:
- ✅ WebSocketMessage.swift
- ✅ NetworkManager.swift  
- ✅ MultiplayerService.swift
- ✅ NetworkCoordinator.swift
- ✅ MultiplayerIntegration.swift

## Future Enhancements

Potential improvements:
1. **Authentication**: JWT token integration
2. **Spectator mode**: Watch games in progress
3. **Tournaments**: Multi-round competitions
4. **Voice chat**: Real-time communication
5. **Replay system**: Game recording and playback
6. **Statistics**: Extended player stats and analytics

## Dependencies

- **Foundation**: Core networking and data handling
- **Combine**: Reactive programming for state management
- **SwiftUI**: User interface integration
- **OSLog**: Structured logging and debugging

The implementation follows Swift 6 concurrency patterns with proper `@MainActor` usage and provides a robust foundation for Septica's multiplayer experience.