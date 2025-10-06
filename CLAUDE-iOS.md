# CLAUDE-iOS.md - Romanian Septica iOS Native App Development Guide

This file provides guidance to Claude Code for working with the **iOS Native App** implementation of Romanian Septica.

> **Note**: This is a HYBRID project. For PWA/backend development, see `docs/CLAUDE.md`

---

## 🎯 Project Overview

**Romanian Septica iOS** is the PRIMARY implementation - a native iPad/iPhone app built with Swift 6.0, SwiftUI, and Metal GPU rendering.

### Technology Stack
- **Language**: Swift 6.0
- **UI Framework**: SwiftUI
- **3D Rendering**: Metal (GPU-accelerated)
- **Platforms**: iPad (primary), iPhone (secondary)
- **Minimum iOS**: 18.0
- **Multiplayer**: CloudKit
- **Architecture**: MVVM with SwiftUI

---

## 📊 Current Status (October 5, 2025)

### Build Status
- ✅ **Compilation**: Clean build, zero errors
- ✅ **Warnings**: 1 minor (duplicate file in build phase)
- ✅ **Simulator**: Successfully launches and runs
- ✅ **Verified**: October 5, 2025

### Implementation Progress (98% Complete)
- ✅ **Game Engine**: Romanian Septica with authentic objection-based gameplay
- ✅ **Objection System**: PASS/OBJECT choice mechanism with 30-second timer
- ✅ **Multi-Player Modes**: 2/3/4 player support with dynamic layouts
- ✅ **3D Rendering**: Metal shaders for professional card rendering
- ✅ **UI**: Complete SwiftUI interface with Romanian cultural design
- ✅ **AI Opponent**: Strategic AI with objection decision logic
- ✅ **Achievement System**: 10 achievements with persistent tracking
- ✅ **Privacy Analytics**: COPPA-compliant analytics with opt-out
- ✅ **Multiplayer**: CloudKit integration (foundation)
- ⏳ **App Store**: Final testing and submission preparation

---

## 🏗️ Project Structure

```
Septica/
├── Septica.xcodeproj/           # Xcode project file
├── Septica/                     # Main app code (166 Swift files)
│   ├── Models/Core/
│   │   ├── Card.swift          # Card model (7-A, 4 suits)
│   │   ├── Deck.swift          # 32-card Romanian deck
│   │   ├── GameState.swift     # Game state management
│   │   ├── Player.swift        # Player model
│   │   └── GameRules.swift     # Romanian Septica rules
│   │
│   ├── Views/
│   │   ├── Game/               # Main game screens
│   │   ├── Menu/               # Navigation and setup
│   │   ├── Components/         # Reusable Romanian UI
│   │   ├── Cultural/           # Cultural pattern integration
│   │   └── Effects/            # Visual effects
│   │
│   ├── ViewModels/              # MVVM view models
│   ├── Controllers/             # Game controllers
│   │
│   ├── AI/
│   │   └── RomanianTraditionalAI.swift  # Traditional playing style
│   │
│   ├── Rendering/
│   │   ├── Professional/       # Advanced rendering system
│   │   │   ├── ProfessionalCardRenderer.swift
│   │   │   ├── AdvancedLightingSystem.swift
│   │   │   └── EnhancedMaterialSystem.swift
│   │   ├── Metal/
│   │   │   └── CardRenderer.swift
│   │   └── RendererExtensions.swift
│   │
│   ├── Managers/
│   │   ├── AccessibilityManager.swift
│   │   ├── AudioManager.swift
│   │   ├── HapticManager.swift
│   │   ├── AnimationManager.swift
│   │   └── NavigationManager.swift
│   │
│   ├── Services/
│   │   ├── CloudKit/           # Multiplayer sync
│   │   ├── Tournament/         # Tournament system
│   │   ├── Achievement/        # Achievement tracking
│   │   └── Analytics/          # Cultural engagement tracking
│   │
│   ├── Performance/
│   │   ├── PerformanceMonitor.swift
│   │   ├── BatteryOptimizationManager.swift
│   │   └── MetalPerformanceMonitor.swift
│   │
│   ├── Shaders.metal           # Metal GPU shaders
│   ├── ShaderTypes.h           # Shader type definitions
│   └── AppDelegate.swift       # App entry point
│
├── SepticaTests/                # Unit tests
└── SepticaUITests/              # UI tests
```

---

## 🎮 Romanian Septica Game Rules (Implementation)

### Deck Configuration
```swift
// 32 cards: 7, 8, 9, 10, Jack, Queen, King, Ace × 4 suits
enum CardValue: Int {
    case seven = 7, eight, nine, ten
    case jack = 11, queen, king, ace
}

enum Suit: String {
    case hearts, diamonds, clubs, spades
}
```

### Beating Rules (Core Logic)
1. **7 Always Beats** - Wild card (highest priority)
2. **Same Value Beats** - Matching values beat table card
3. **8 Special Rule** - Wild cards ONLY in 3-player mode (with 30-card deck)

### Point System
- **Point Cards**: 10s and Aces = 1 point each
- **Total Points per Game**: 8 points (4 tens + 4 aces)
- **Win Condition**: First to 11 points wins match

### Objection System (Authentic Romanian Rules)
- **PASS**: Player chooses not to beat, saves cards for later
- **OBJECT**: Player plays beating card and takes control
- **Timer**: 30-second decision window with visual countdown
- **Strategy**: AI evaluates point cards on table before deciding

### Game Modes
- **2-Player**: Standard 32-card deck, classic rules
- **3-Player**: 30-card deck (8s removed), triangular layout, 8s as wild cards
- **4-Player**: Team mode with partnerships, square layout, 32-card deck

Implementation: `Septica/Models/Core/GameRules.swift`, `Septica/Controllers/GameController.swift`

---

## 🔧 Development Workflow

### Building the App

```bash
# Open in Xcode (recommended)
open Septica.xcodeproj
# Press Cmd+R to build and run on simulator

# Command-line build
xcodebuild -project Septica.xcodeproj \
  -scheme Septica \
  -destination 'platform=iOS Simulator,name=iPad (A16)' \
  clean build

# Build for device (requires Apple Developer account)
xcodebuild -project Septica.xcodeproj \
  -scheme Septica \
  -destination generic/platform=iOS \
  archive
```

### Running Tests

```bash
# Run all tests
xcodebuild test -project Septica.xcodeproj \
  -scheme Septica \
  -destination 'platform=iOS Simulator,name=iPad (A16)'

# Run specific test
xcodebuild test -project Septica.xcodeproj \
  -scheme Septica \
  -only-testing:SepticaTests/GameRulesTests

# UI tests
xcodebuild test -project Septica.xcodeproj \
  -scheme Septica \
  -only-testing:SepticaUITests
```

### Launching on Simulator

```bash
# Install on booted simulator
xcrun simctl install booted \
  ~/Library/Developer/Xcode/DerivedData/Septica-*/Build/Products/Debug-iphonesimulator/Septica.app

# Launch app
xcrun simctl launch booted dev.leanvibe.game.Septica
```

---

## 🎨 Metal Rendering System

### Shader Files
- **Shaders.metal**: Main Metal shaders for card rendering
- **ShaderTypes.h**: Shared type definitions between Swift and Metal

### Rendering Architecture
```swift
// Professional card renderer with GPU acceleration
ProfessionalCardRenderer
├── AdvancedLightingSystem      // Dynamic lighting
├── EnhancedMaterialSystem      // PBR materials
├── GeometryCache               // Optimized geometry
└── TextureCache                // Texture management
```

### Performance Targets
- **60 FPS**: Maintained on iPad 8th gen+
- **Memory**: <500MB total app usage
- **Battery**: <5% drain per hour gameplay
- **Startup**: <1 second launch time

---

## 🇷🇴 Romanian Cultural Features

### Regional Variations
Implemented in game AI and visual design:
- **Moldova**: Traditional patterns, specific color palette
- **Transilvania**: Mountain-inspired aesthetics
- **Wallachia**: Plains cultural elements
- **Traditional**: Classic Romanian card game style

### Cultural UI Components
- `RomanianCharacterSystem.swift` - Character avatars
- `RomanianColors.swift` - Authentic color palette
- `RomanianGameZoneFrames.swift` - Ornate frame designs
- `RomanianCulturalPatternView.swift` - Traditional patterns

---

## 🧪 Testing Requirements

### Before Committing
```bash
# 1. Build check
xcodebuild build -project Septica.xcodeproj -scheme Septica

# 2. Run tests
swift test --enable-code-coverage

# 3. SwiftLint (if configured)
swiftlint lint --config .swiftlint.yml
```

### Quality Gates
- ✅ All tests passing
- ✅ Zero compilation errors
- ✅ SwiftLint clean (if enabled)
- ✅ Performance targets met
- ✅ Accessibility validation

---

## 🔄 Multiplayer Architecture

### CloudKit Integration
- **Container**: iCloud.dev.leanvibe.game.Septica
- **Database**: Private (user data) + Public (leaderboards)
- **Sync**: Real-time game state synchronization
- **Matchmaking**: Skill-based pairing

### Shared Backend (Optional)
- iOS app CAN connect to Go backend (`backend/`) for cross-platform play
- WebSocket endpoint: `ws://localhost:8082/ws/connect` (development)
- See `docs/CLAUDE.md` for backend setup

---

## 🎯 New Features (October 2025)

### Objection System Usage

The objection system allows players to strategically choose when to beat cards:

```swift
// In GameController.swift
func handleObjectionDecision(pass: Bool) {
    if pass {
        // Player passes - opponent takes cards
        gameState.currentPlayer.takeCards(gameState.tableCards)
        gameState.clearTable()
        gameState.nextTurn()
    } else {
        // Player objects - show playable cards
        gameState.waitingForObjection = false
        // Player must select a beating card
    }
}
```

**UI Implementation**:
- PASS button appears when player can beat current card
- 30-second countdown timer shows remaining decision time
- Strategic hint system suggests optimal decisions based on point cards

### Multi-Player Mode Selection

Players can choose between 2, 3, or 4 player modes:

```swift
// In GameSetupView.swift
@State private var playerCount = 2

Picker("Players", selection: $playerCount) {
    Text("2 Players").tag(2)
    Text("3 Players").tag(3)  // Triangular layout, 30-card deck
    Text("4 Players").tag(4)  // Team mode, partnerships
}
```

**Layout Implementations**:
- `ThreePlayerGameLayout.swift` - Triangular card arrangement
- `FourPlayerGameLayout.swift` - Square layout with team indicators

### Achievement System Integration

10 achievements track player progress:

```swift
// Achievements available:
- First Win: Win your first game
- Perfect Game: Win without opponent scoring
- Comeback Victory: Win after being behind 5+ points
- Wild Card Master: Win 5 games using 7s strategically
- Objection Expert: Successfully object 20 times
// ... and 5 more

// Track achievement in code:
AchievementTrackingService.shared.trackAchievement(.firstWin)
```

**Storage**: Achievements persist in UserDefaults with unlock timestamps

### Privacy-Compliant Analytics

22 game metrics tracked with user consent:

```swift
// Analytics opt-out in settings
GameAnalyticsStore.shared.isEnabled = false

// Metrics tracked (when enabled):
- Games played/won/lost
- Average game duration
- Objection success rate
- AI difficulty preference
- Feature usage patterns

// No personal data, no cloud sync, COPPA compliant
```

**User Control**:
- Opt-out available in settings
- All data stored locally only
- No network transmission
- Clear data deletion option

---

## 📋 Common Development Tasks

### Adding a New View
```swift
// 1. Create view in Septica/Views/
import SwiftUI

struct NewGameView: View {
    var body: some View {
        Text("New View")
    }
}

// 2. Add to navigation
// 3. Update ViewModels if needed
```

### Adding a New Game Rule
```swift
// Edit Septica/Models/Core/GameRules.swift
extension GameRules {
    static func newRule(_ card: Card, _ table: [Card]) -> Bool {
        // Implementation
    }
}
```

### Modifying Metal Shaders
```metal
// Edit Septica/Shaders.metal
// Remember to update ShaderTypes.h for shared types
```

---

## 🐛 Known Issues

### Current
- ⚠️ Minor: Duplicate file warning in build phase (non-blocking)

### Resolved
- ✅ Card stretching constraints fixed (commit d409f5b)
- ✅ Environment object crash fixed (commit 4004055)
- ✅ Romanian 8-beating rule bug fixed (commit 16e9879)

---

## 📚 Key Resources

### Apple Documentation
- [SwiftUI](https://developer.apple.com/documentation/swiftui)
- [Metal](https://developer.apple.com/documentation/metal)
- [CloudKit](https://developer.apple.com/documentation/cloudkit)

### Project Documentation
- **This File**: iOS native development
- **docs/CLAUDE.md**: PWA/backend development
- **docs/game-rules.md**: Complete Romanian Septica rules
- **docs/PROJECT_STATUS.md**: Overall project status

---

## ⚠️ Important Notes

### Hybrid Architecture
- This is **Platform 1** (PRIMARY) of a dual-platform project
- **Platform 2** (SECONDARY): PWA with Go backend + Three.js frontend
- Both platforms share the same Romanian Septica game rules
- iOS uses CloudKit; PWA uses WebSocket for multiplayer

### Development Focus
- **iOS First**: Focus on native iOS excellence
- **Cross-platform**: Optional backend integration for web players
- **Cultural Authenticity**: Preserve Romanian gaming heritage

---

**Romanian Septica iOS** - Premium native implementation preserving traditional Romanian card gaming with modern iOS technology and authentic cultural representation.
