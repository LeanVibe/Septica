# CLAUDE.md - Septica iOS Project Navigation Guide

This file provides guidance to Claude Code (claude.ai/code) when working with the Septica iOS Metal card game project.

## Project Overview
Septica is a Romanian card game implementation for iOS using Metal for high-performance rendering, with a Go backend for real-time multiplayer, matchmaking, and competitive ranking systems.

## iOS Project Structure

### Core Directories
```
/Septica/
├── Septica/                 # Main iOS app target
│   ├── Models/             # Data models and game logic
│   │   ├── Core/           # Game rules, Card, Deck, Player models
│   │   ├── Network/        # API and WebSocket models
│   │   └── Persistence/    # Core Data and local storage
│   ├── Views/              # UI Components
│   │   ├── Game/           # Game board and card views
│   │   ├── Menu/           # Menu screens (SwiftUI)
│   │   └── Components/     # Reusable UI components
│   ├── Controllers/        # View controllers and coordinators
│   │   ├── Game/           # Game flow controllers
│   │   ├── Network/        # Network communication
│   │   └── UI/             # UI coordination
│   ├── Rendering/          # Metal rendering system
│   │   ├── Metal/          # Metal setup and pipelines
│   │   ├── Shaders/        # .metal shader files
│   │   └── Textures/       # Texture management
│   ├── Services/           # Business logic services
│   │   ├── API/            # REST API communication
│   │   ├── WebSocket/      # Real-time game communication
│   │   └── Storage/        # Data persistence
│   └── Resources/          # Assets and configurations
│       ├── Assets.xcassets/ # Images and colors
│       ├── Sounds/         # Audio files
│       └── Localizations/  # String files
├── SepticaTests/           # Unit tests
├── SepticaUITests/         # UI automation tests
└── docs/                   # Project documentation
```

## Key Implementation Files

### Game Logic Core
- **Septica/Models/Core/Card.swift** - Card model (suit, value, point calculation)
- **Septica/Models/Core/Deck.swift** - 32-card Romanian deck management
- **Septica/Models/Core/GameRules.swift** - Core Septica game rules engine
- **Septica/Models/Core/Player.swift** - Base player class
- **Septica/Models/Core/AIPlayer.swift** - AI decision algorithms
- **Septica/Models/Core/GameState.swift** - Game state machine

### Metal Rendering
- **Septica/Rendering/Metal/Renderer.swift** - Main Metal renderer (extend existing)
- **Septica/Rendering/Metal/CardRenderer.swift** - Card-specific rendering
- **Septica/Rendering/Shaders/CardShaders.metal** - Card vertex/fragment shaders
- **Septica/GameViewController.swift** - Main game view controller (existing)

### Networking
- **Septica/Services/API/SepticaAPI.swift** - REST API service
- **Septica/Services/WebSocket/GameWebSocket.swift** - Real-time game communication
- **Septica/Models/Network/GameMessage.swift** - Network protocol models

### UI Components
- **Septica/Views/Game/GameBoardView.swift** - Main game board UI
- **Septica/Views/Game/CardView.swift** - Individual card view
- **Septica/Views/Menu/MainMenuView.swift** - Main menu (SwiftUI)

## Septica Game Rules (IMPORTANT)

### Card Values and Points
- **Deck:** 32 cards (7, 8, 9, 10, Jack, Queen, King, Ace) × 4 suits
- **Point Cards:** 10s and Aces (1 point each) - **Total: 8 points per game**
- **Card Hierarchy:** 7 < 8 < 9 < 10 < Jack < Queen < King < Ace

### Game Mechanics
- **Players:** 2 players, 4 cards each initially
- **Beating Rules:**
  - Same value beats the previous card
  - 7 always beats (wild card)
  - 8 beats when (table cards count % 3 == 0)
- **Trick System:** Players continue adding cards until no one can beat
- **Win Conditions:** Player with most points (10s and Aces) wins

### Key Rule Implementation
```swift
// Card beating logic
func canBeat(atu: Card, with card: Card) -> Bool {
    return card.value == atu.value || 
           card.value == 7 || 
           (card.value == 8 && tableCards.count % 3 == 0)
}

// Point calculation
func isPointCard(_ card: Card) -> Bool {
    return card.value == 10 || card.value == 14 // Ace
}
```

## Development Workflow

### Build Commands
```bash
# Build iOS project
xcodebuild -project Septica.xcodeproj -scheme Septica build

# Run tests
xcodebuild -project Septica.xcodeproj -scheme Septica test

# iOS Simulator
xcodebuild -project Septica.xcodeproj -scheme Septica -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build
```

### Key Files to Check When:
- **Game logic issues:** `/Models/Core/GameRules.swift`
- **Rendering problems:** `/Rendering/Metal/Renderer.swift`
- **Network issues:** `/Services/WebSocket/GameWebSocket.swift`
- **UI problems:** `/Views/Game/GameBoardView.swift`
- **Card behavior:** `/Models/Core/Card.swift`

## Architecture Patterns

### MVVM + Coordinators
- **Models:** Pure data structures and business logic
- **ViewModels:** Presentation logic and state management
- **Views:** SwiftUI/UIKit UI components
- **Coordinators:** Navigation and flow management

### Metal Rendering Pipeline
- **Vertex Stage:** Transform card positions and orientations
- **Fragment Stage:** Render card textures and effects
- **Compute Shaders:** Particle effects and animations

### Network Architecture
- **REST API:** Authentication, profiles, leaderboards
- **WebSocket:** Real-time game moves and state sync
- **Local Storage:** Core Data for offline capability

## Backend Integration

### API Endpoints (Go Backend)
```
BASE_URL: https://api.septica.game
Authentication: Bearer JWT tokens

POST /api/v1/auth/login
GET  /api/v1/profile
POST /api/v1/matchmaking/queue
```

### WebSocket Protocol
```
wss://ws.septica.game/game
Messages: JSON format
Events: connect, game_start, card_played, game_end
```

## Testing Strategy

### Unit Tests (`SepticaTests/`)
- Game rules validation
- Card logic verification  
- AI decision testing
- Network protocol tests

### UI Tests (`SepticaUITests/`)
- Card interaction flows
- Menu navigation
- Multiplayer scenarios
- Performance benchmarks

## Performance Targets

- **Rendering:** 60 FPS on iPhone 11+
- **Memory:** <100MB total usage
- **Network:** <50ms game move latency
- **Launch:** <2 seconds to main menu
- **App Size:** <150MB download

## Common Issues & Solutions

### Metal Rendering
- **Issue:** Card textures not loading
- **Check:** `/Resources/Assets.xcassets/` texture organization
- **Solution:** Verify MTKTextureLoader implementation

### Game Logic
- **Issue:** Incorrect card beating
- **Check:** `GameRules.swift` card comparison logic
- **Solution:** Verify Romanian Septica rules implementation

### Networking
- **Issue:** WebSocket disconnections
- **Check:** Network controller connection handling
- **Solution:** Implement reconnection logic with exponential backoff

## File Naming Conventions

- **Swift Files:** PascalCase (e.g., `CardRenderer.swift`)
- **Metal Shaders:** PascalCase + .metal (e.g., `CardShaders.metal`)
- **Assets:** kebab-case (e.g., `card-back-blue.png`)
- **Storyboards:** PascalCase (e.g., `Main.storyboard`)

## Git Workflow

- **Main Branch:** `main` - production ready code
- **Feature Branches:** `feature/DS-XXX-description`
- **Bug Fixes:** `fix/DS-XXX-description`
- **Always:** Run tests before committing

## Documentation References

For detailed specifications, see:
- `/docs/PLAN.md` - Complete implementation roadmap
- `/docs/game-rules.md` - Full Septica rules
- `/docs/architecture.md` - Technical architecture
- `/docs/backend-api.md` - API documentation
- `/docs/multiplayer-protocol.md` - WebSocket protocol

## Quality Gates

Before any commit:
1. ✅ All unit tests pass
2. ✅ Build succeeds without warnings
3. ✅ Metal shaders compile correctly
4. ✅ Performance targets maintained
5. ✅ No memory leaks detected

Remember: This is a competitive multiplayer card game. Focus on smooth 60 FPS gameplay, responsive touch controls, and rock-solid network synchronization.