# Septica iOS UI/UX Design Specifications

## 🎨 Design Philosophy

Septica combines the elegance of traditional Romanian card games with modern mobile gaming excellence. Our design language draws inspiration from Romanian folk art while delivering the smooth, intuitive interactions found in premium mobile games like Shuffle Cats and Hearthstone.

## 🎯 Design Principles

### 1. Cultural Authenticity
- **Traditional Patterns:** Incorporate Romanian folk art motifs and color schemes
- **Architectural Elements:** Reference Romanian castles, monasteries, and landscapes  
- **Typography:** Balance traditional serif elements with modern readability
- **Respectful Modernization:** Honor heritage while appealing to global audiences

### 2. Intuitive Interaction
- **Natural Gestures:** Drag-and-drop feels like handling real cards
- **Clear Feedback:** Every interaction provides immediate visual and haptic response
- **Contextual Guidance:** Show valid moves and game state clearly
- **Error Prevention:** Design prevents invalid actions rather than correcting them

### 3. Visual Excellence
- **60 FPS Smoothness:** All animations maintain consistent frame rate
- **Metal-Powered Effects:** Leverage hardware acceleration for premium feel
- **Glass Morphism:** Modern translucent interfaces with depth
- **Dynamic Lighting:** Realistic shadows and reflections enhance immersion

## 🖼️ Visual Identity

### Color Palette

#### Primary Colors
```swift
// Traditional Romanian-inspired colors
static let primaryRed = Color(red: 0.8, green: 0.2, blue: 0.2)      // Romanian flag red
static let primaryBlue = Color(red: 0.0, green: 0.3, blue: 0.6)     // Deep royal blue
static let primaryYellow = Color(red: 1.0, green: 0.8, blue: 0.0)   // Golden yellow

// Game-specific colors
static let cardBack = Color(red: 0.15, green: 0.25, blue: 0.4)      // Deep navy
static let tableGreen = Color(red: 0.1, green: 0.5, blue: 0.2)      // Forest green
static let goldAccent = Color(red: 1.0, green: 0.84, blue: 0.0)     // Metallic gold
```

#### Semantic Colors
```swift
// Game state colors
static let validMove = Color.green.opacity(0.3)
static let invalidMove = Color.red.opacity(0.3)
static let currentPlayer = Color.blue.opacity(0.6)
static let winningCard = Color.yellow.opacity(0.8)

// UI feedback colors
static let success = Color(red: 0.2, green: 0.7, blue: 0.3)
static let warning = Color(red: 1.0, green: 0.6, blue: 0.0)
static let error = Color(red: 0.8, green: 0.2, blue: 0.2)
static let info = Color(red: 0.3, green: 0.5, blue: 0.8)
```

#### Dark Mode Adaptations
```swift
// Automatically adjust for dark mode
static let backgroundColor = Color(UIColor.systemBackground)
static let surfaceColor = Color(UIColor.secondarySystemBackground)
static let textPrimary = Color(UIColor.label)
static let textSecondary = Color(UIColor.secondaryLabel)
```

### Typography

#### Font System
```swift
// Custom font hierarchy
static let displayFont = Font.custom("TrajanPro-Bold", size: 28)      // Headers
static let titleFont = Font.custom("TrajanPro-Regular", size: 22)     // Titles
static let bodyFont = Font.custom("SFPro-Regular", size: 16)          // Body text
static let captionFont = Font.custom("SFPro-Medium", size: 14)        // Captions
static let monoFont = Font.custom("SFMono-Regular", size: 16)          // Scores/numbers

// Dynamic Type support
extension Font {
    static func scaledTitle() -> Font {
        return Font.custom("TrajanPro-Regular", size: 22, relativeTo: .title)
    }
}
```

### Iconography

#### Custom Icon Set
- **Card Suits:** Custom-designed Romanian-style suits
- **Action Icons:** Minimalist line art with 2pt stroke width
- **Status Icons:** Clear, recognizable symbols for all game states
- **Navigation:** Consistent with iOS design guidelines

```swift
// Icon design specifications
struct IconStyle {
    static let strokeWidth: CGFloat = 2.0
    static let cornerRadius: CGFloat = 8.0
    static let shadowOffset = CGSize(width: 0, height: 2)
    static let shadowOpacity: Float = 0.3
}
```

## 📱 Screen Layouts

### Main Menu
```
┌─────────────────────────────────────┐
│  [Profile Avatar]    [Coins] [Gems] │
│                                     │
│        ╔═══════════════════╗        │
│        ║    SEPTICA        ║        │
│        ║  Traditional Card ║        │
│        ║      Game         ║        │
│        ╚═══════════════════╝        │
│                                     │
│    ┌─────────────────────────┐      │
│    │      QUICK PLAY         │      │
│    └─────────────────────────┘      │
│    ┌─────────────────────────┐      │
│    │      RANKED            │      │
│    └─────────────────────────┘      │
│    ┌─────────────────────────┐      │
│    │      TOURNAMENTS       │      │
│    └─────────────────────────┘      │
│                                     │
│  [Settings] [Achievements] [Shop]   │
└─────────────────────────────────────┘
```

### Game Board Layout
```
┌─────────────────────────────────────┐
│ AI: ●●●● [Score: 2] [Time: 0:45]    │
│                                     │
│           ┌─┐ ┌─┐ ┌─┐               │
│           │?│ │?│ │?│               │  ← AI Cards
│           └─┘ └─┘ └─┘               │
│                                     │
│         ┌─────┐ ┌─────┐             │
│         │  7♥ │ │ 10♦│             │  ← Table Cards
│         └─────┘ └─────┘             │
│                                     │
│         [Continue] [Pass]           │  ← Action Buttons
│                                     │
│           ┌─────┐ ┌─────┐           │
│           │  J♣ │ │  A♠│           │  ← Player Cards
│           └─────┘ └─────┘           │
│                                     │
│ You: ●● [Score: 1] [Time: 0:28]     │
│ [Menu] [Chat] [Emotes] [Forfeit]    │
└─────────────────────────────────────┘
```

## 🃏 Card Design System

### Card Dimensions
```swift
struct CardDimensions {
    static let cardRatio: CGFloat = 0.7 // width/height
    static let standardWidth: CGFloat = 80
    static let standardHeight: CGFloat = standardWidth / cardRatio
    static let cornerRadius: CGFloat = 8
    static let borderWidth: CGFloat = 1
}
```

### Card States & Animations

#### Visual States
```swift
enum CardState {
    case normal
    case highlighted      // Glowing border for valid moves
    case selected        // Lifted with shadow
    case disabled        // Grayed out, cannot play
    case hidden          // Face down (opponent cards)
    case played          // On table, slightly transparent
}

struct CardVisualState {
    var scale: CGFloat = 1.0
    var rotation: Angle = .zero
    var offset: CGSize = .zero
    var opacity: Double = 1.0
    var shadowRadius: CGFloat = 4.0
    var borderColor: Color = .clear
    var borderWidth: CGFloat = 0
}
```

#### Card Animations
```swift
// Smooth card interactions
extension Animation {
    static let cardMove = Animation.spring(
        response: 0.4,
        dampingFraction: 0.8,
        blendDuration: 0.1
    )
    
    static let cardFlip = Animation.easeInOut(duration: 0.3)
    static let cardDeal = Animation.easeOut(duration: 0.5)
}
```

### Card Face Design
```
┌─────────────┐
│ 7♥          │  ← Suit and value in corner
│             │
│             │
│      ♥      │  ← Large suit symbol
│             │
│             │
│          ♥7 │  ← Inverted corner
└─────────────┘
```

### Card Back Design
```
┌─────────────┐
│ ╔═════════╗ │
│ ║ Traditional ║ │  ← Romanian folk patterns
│ ║ patterns  ║ │
│ ║   here    ║ │
│ ╚═════════╝ │
└─────────────┘
```

## 🎮 Interactive Elements

### Touch Interactions

#### Card Handling
```swift
struct CardGesture {
    // Drag gesture for card play
    var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                // Update card position
                // Show ghost preview
                // Highlight valid drop zones
            }
            .onEnded { value in
                // Snap to valid position or return
                // Play haptic feedback
                // Execute game move
            }
    }
    
    // Tap gesture for quick play
    var tapGesture: some Gesture {
        TapGesture()
            .onEnded {
                // Auto-play card if only one valid move
                // Show move options if multiple
            }
    }
}
```

#### Haptic Feedback
```swift
extension UIImpactFeedbackGenerator.FeedbackStyle {
    static let cardPickup: UIImpactFeedbackGenerator.FeedbackStyle = .light
    static let cardPlay: UIImpactFeedbackGenerator.FeedbackStyle = .medium
    static let trickWin: UIImpactFeedbackGenerator.FeedbackStyle = .heavy
    static let gameWin: UIImpactFeedbackGenerator.FeedbackStyle = .heavy
}
```

### Button Design System

#### Primary Buttons
```swift
struct PrimaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.primaryBlue)
                    .shadow(radius: configuration.isPressed ? 2 : 4)
            )
            .foregroundColor(.white)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
```

#### Glass Morphism Buttons
```swift
struct GlassButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}
```

## 📊 Game UI Components

### Score Display
```swift
struct ScoreView: View {
    let playerScore: Int
    let opponentScore: Int
    let maxScore: Int = 8
    
    var body: some View {
        HStack {
            // Player score with dots
            HStack(spacing: 4) {
                ForEach(0..<maxScore/2, id: \.self) { index in
                    Circle()
                        .fill(index < playerScore ? .blue : .gray.opacity(0.3))
                        .frame(width: 12, height: 12)
                }
            }
            
            Text("VS")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Opponent score with dots
            HStack(spacing: 4) {
                ForEach(0..<maxScore/2, id: \.self) { index in
                    Circle()
                        .fill(index < opponentScore ? .red : .gray.opacity(0.3))
                        .frame(width: 12, height: 12)
                }
            }
        }
    }
}
```

### Timer Display
```swift
struct GameTimer: View {
    let timeRemaining: TimeInterval
    let totalTime: TimeInterval
    
    var progress: Double {
        timeRemaining / totalTime
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(.gray.opacity(0.3), lineWidth: 4)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    progress > 0.5 ? .green :
                    progress > 0.2 ? .orange : .red,
                    lineWidth: 4
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)
            
            Text("\(Int(timeRemaining))")
                .font(.title2)
                .fontWeight(.medium)
        }
        .frame(width: 50, height: 50)
    }
}
```

### Valid Move Indicators
```swift
struct ValidMoveOverlay: View {
    let isValidDrop: Bool
    
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(
                isValidDrop ? Color.green : Color.clear,
                lineWidth: 3
            )
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isValidDrop ? Color.green.opacity(0.2) : Color.clear)
            )
            .animation(.easeInOut(duration: 0.2), value: isValidDrop)
    }
}
```

## 🎨 Themed Environments

### Table Themes

#### Castle Courtyard
```swift
struct CastleCourtyardTheme: GameTheme {
    var backgroundImage: String = "castle_courtyard"
    var tableTexture: String = "stone_table"
    var cardShadowColor: Color = .black.opacity(0.4)
    var ambientSound: String = "castle_ambiance"
    
    var lighting: LightingConfig {
        LightingConfig(
            primaryLight: simd_float3(0.8, 0.8, 0.8),
            shadowOpacity: 0.3,
            ambientStrength: 0.4
        )
    }
}
```

#### Carpathian Mountains
```swift
struct CarpathianTheme: GameTheme {
    var backgroundImage: String = "mountain_landscape"
    var tableTexture: String = "wooden_table"
    var cardShadowColor: Color = .brown.opacity(0.3)
    var ambientSound: String = "mountain_wind"
    
    var lighting: LightingConfig {
        LightingConfig(
            primaryLight: simd_float3(1.0, 0.9, 0.7), // Warm sunlight
            shadowOpacity: 0.5,
            ambientStrength: 0.6
        )
    }
}
```

## 🔄 Animations & Transitions

### Screen Transitions
```swift
extension AnyTransition {
    static let slideFromRight = AnyTransition.asymmetric(
        insertion: .move(edge: .trailing),
        removal: .move(edge: .leading)
    ).combined(with: .opacity)
    
    static let cardFlip = AnyTransition.asymmetric(
        insertion: .scale(scale: 0, anchor: .center)
            .combined(with: .rotation3D(axis: (x: 0, y: 1, z: 0), angle: .degrees(90))),
        removal: .scale(scale: 0, anchor: .center)
            .combined(with: .rotation3D(axis: (x: 0, y: 1, z: 0), angle: .degrees(-90)))
    )
}
```

### Particle Effects
```swift
struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    
    var body: some View {
        ZStack {
            ForEach(particles, id: \.id) { particle in
                ParticleView(particle: particle)
            }
        }
        .onAppear {
            generateParticles()
        }
    }
    
    func generateParticles() {
        particles = (0..<50).map { _ in
            ConfettiParticle(
                position: CGPoint(x: CGFloat.random(in: 0...400), y: -50),
                velocity: CGPoint(x: CGFloat.random(in: -100...100), y: CGFloat.random(in: 100...300)),
                color: [.red, .blue, .yellow, .green].randomElement()!,
                size: CGFloat.random(in: 4...8)
            )
        }
    }
}
```

## ♿ Accessibility Features

### VoiceOver Support
```swift
extension CardView {
    var accessibilityDescription: String {
        switch card.value {
        case 7: return "Seven of \(card.suit.accessibilityName)"
        case 10: return "Ten of \(card.suit.accessibilityName) - Point card"
        case 14: return "Ace of \(card.suit.accessibilityName) - Point card"
        default: return "\(card.displayValue) of \(card.suit.accessibilityName)"
        }
    }
    
    var accessibilityHint: String {
        if isValidMove {
            return "Double tap to play this card"
        } else {
            return "Cannot play this card"
        }
    }
}
```

### Dynamic Type Support
```swift
struct ScaledFont: ViewModifier {
    @Environment(\.sizeCategory) var sizeCategory
    
    let size: CGFloat
    
    func body(content: Content) -> some View {
        content
            .font(.system(size: size * scaleFactor))
    }
    
    private var scaleFactor: CGFloat {
        switch sizeCategory {
        case .extraSmall: return 0.8
        case .small: return 0.9
        case .medium: return 1.0
        case .large: return 1.1
        case .extraLarge: return 1.2
        case .extraExtraLarge: return 1.3
        case .extraExtraExtraLarge: return 1.4
        default: return 1.0
        }
    }
}
```

### Color Contrast
```swift
struct AccessibleColors {
    static func contrastingColor(for background: Color) -> Color {
        // Calculate luminance and return appropriate text color
        return background.luminance > 0.5 ? .black : .white
    }
    
    static let minimumContrastRatio: Double = 4.5 // WCAG AA standard
}
```

## 🌐 Responsive Design

### Device Adaptations

#### iPhone Layout
```swift
struct iPhoneGameLayout: View {
    var body: some View {
        VStack(spacing: 16) {
            OpponentSection()
                .frame(height: 120)
            
            Spacer()
            
            TableSection()
                .frame(height: 200)
            
            Spacer()
            
            PlayerSection()
                .frame(height: 120)
            
            GameControls()
                .frame(height: 60)
        }
    }
}
```

#### iPad Layout
```swift
struct iPadGameLayout: View {
    var body: some View {
        HStack {
            VStack {
                OpponentSection()
                Spacer()
                PlayerSection()
            }
            .frame(width: 200)
            
            VStack {
                TableSection()
                GameControls()
            }
            
            VStack {
                ScoreSection()
                ChatSection()
                Spacer()
            }
            .frame(width: 200)
        }
    }
}
```

### Orientation Support
```swift
struct AdaptiveGameView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                iPhoneGameLayout()
            } else {
                iPadGameLayout()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: horizontalSizeClass)
    }
}
```

This comprehensive UI/UX design system ensures a premium, culturally authentic, and accessible gaming experience that leverages iOS platform strengths while maintaining 60 FPS performance through Metal rendering optimization.