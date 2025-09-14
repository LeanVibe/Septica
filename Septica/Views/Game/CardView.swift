//
//  CardView.swift
//  Septica
//
//  Individual card view component for displaying playing cards
//  Supports animations, selection states, and Romanian card styling
//

import SwiftUI
import MetalKit
import UIKit

/// SwiftUI view for displaying a single playing card with full accessibility support
struct CardView: View {
    let card: Card
    let isSelected: Bool
    let isPlayable: Bool
    let isAnimating: Bool
    let cardSize: CardSize
    let onTap: (() -> Void)?
    
    // Accessibility and UX managers
    @EnvironmentObject private var accessibilityManager: AccessibilityManager
    @EnvironmentObject private var hapticManager: HapticManager
    @EnvironmentObject private var audioManager: AudioManager
    @EnvironmentObject private var animationManager: AnimationManager
    
    @State private var isPressed = false
    @State private var rotationAngle: Double = 0
    @State private var isFocused = false
    @State private var playAnimationTrigger = false
    
    // Metal rendering computed properties
    private var rotationAxis: (x: CGFloat, y: CGFloat, z: CGFloat) {
        return (x: 0, y: 1, z: 0)
    }
    
    init(
        card: Card,
        isSelected: Bool = false,
        isPlayable: Bool = true,
        isAnimating: Bool = false,
        cardSize: CardSize = .normal,
        onTap: (() -> Void)? = nil
    ) {
        self.card = card
        self.isSelected = isSelected
        self.isPlayable = isPlayable
        self.isAnimating = isAnimating
        self.cardSize = cardSize
        self.onTap = onTap
    }
    
    var body: some View {
        // Use Metal rendering if available, otherwise fallback to SwiftUI
        if shouldUseMetalRendering() {
            MetalCardView(card: card, isSelected: isSelected, isPlayable: isPlayable, isAnimating: isAnimating)
                .frame(width: cardSize.width, height: cardSize.height)
                .scaleEffect(scaleEffect)
                .rotation3DEffect(.degrees(rotationAngle), axis: rotationAxis)
                .shadow(color: shadowColor, radius: shadowRadius, x: shadowOffset, y: shadowOffset)
                .animation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.3), value: isSelected)
                .animation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0.2), value: isAnimating)
                .onTapGesture {
                    handleCardTap()
                }
                .accessibilityElement()
                .accessibilityLabel(accessibilityLabel)
                .accessibilityAddTraits(isPlayable ? .isButton : [])
                .accessibilityHint(isPlayable ? "Double tap to play this card" : "")
        } else {
            swiftUICardView
        }
    }
    
    // MARK: - Card View Components
    
    private var cardBackgroundView: some View {
        RoundedRectangle(cornerRadius: cardSize.cornerRadius)
            .fill(cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: cardSize.cornerRadius)
                    .stroke(cardBorder, lineWidth: cardSize.borderWidth)
            )
            .frame(width: cardSize.width, height: cardSize.height)
    }
    
    private var cardContentView: some View {
        VStack(spacing: cardSize.contentSpacing) {
            // Top left value and suit
            HStack {
                VStack(spacing: 1) {
                    Text(card.displayValue)
                        .font(cardSize.valueFont.weight(.bold))
                        .foregroundStyle(suitColor)
                    
                    Text(card.suit.symbol)
                        .font(cardSize.suitFont)
                        .foregroundStyle(suitColor)
                }
                Spacer()
            }
            
            Spacer()
            
            // Center suit symbol
            Text(card.suit.symbol)
                .font(cardSize.centerSuitFont)
                .foregroundStyle(suitColor.opacity(0.4))
            
            Spacer()
            
            // Bottom right value and suit (rotated)
            HStack {
                Spacer()
                VStack(spacing: 1) {
                    Text(card.suit.symbol)
                        .font(cardSize.suitFont)
                        .foregroundStyle(suitColor)
                    
                    Text(card.displayValue)
                        .font(cardSize.valueFont.weight(.bold))
                        .foregroundStyle(suitColor)
                }
                .rotationEffect(.degrees(180))
            }
        }
        .padding(cardSize.contentPadding)
    }
    
    private var cardIndicatorsView: some View {
        ZStack {
            // Point card indicator
            if card.isPointCard {
                VStack {
                    HStack {
                        Spacer()
                        Circle()
                            .fill(Color.yellow.gradient)
                            .frame(width: 10, height: 10)
                            .overlay(
                                Text("P")
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundColor(.black)
                            )
                            .offset(x: -8, y: 8)
                    }
                    Spacer()
                }
            }
            
            // Wild card indicator
            if card.value == 7 {
                VStack {
                    HStack {
                        Circle()
                            .fill(Color.orange.gradient)
                            .frame(width: 8, height: 8)
                            .overlay(
                                Image(systemName: "star.fill")
                                    .font(.system(size: 4))
                                    .foregroundColor(.white)
                            )
                            .offset(x: 8, y: 8)
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
    }
    
    private var selectionOverlayView: some View {
        RoundedRectangle(cornerRadius: cardSize.cornerRadius)
            .stroke(Color.blue, lineWidth: 3)
            .background(
                RoundedRectangle(cornerRadius: cardSize.cornerRadius)
                    .fill(.blue.opacity(0.1))
            )
    }
    
    // MARK: - Event Handlers
    
    private func handleCardTap() {
        if isPlayable {
            // Trigger haptic feedback
            hapticManager.trigger(.cardPlay)
            
            // Play audio feedback
            audioManager.playSound(.cardPlace)
            
            // Trigger play animation
            playAnimationTrigger = true
            
            onTap?()
        } else {
            // Invalid move feedback
            hapticManager.trigger(.cardInvalid)
            audioManager.playSound(.cardInvalid)
        }
    }
    
    private var accessibilityLabel: String {
        return "\(card.displayValue) of \(card.suit.rawValue)\(isSelected ? ", selected" : "")\(isPlayable ? "" : ", not playable")"
    }
    
    /// Check if Metal rendering should be used
    private func shouldUseMetalRendering() -> Bool {
        // Re-enable Metal rendering with crash fixes
        return MTLCreateSystemDefaultDevice() != nil && 
               !ProcessInfo.processInfo.arguments.contains("--disable-metal")
    }
    
    /// Enhanced SwiftUI card implementation with premium design
    private var swiftUICardView: some View {
        ZStack {
            cardBackgroundView
            cardContentView
            cardIndicatorsView
            if isSelected {
                selectionOverlayView
            }
        }
        .scaleEffect(scaleEffect)
        .rotationEffect(.degrees(rotationAngle))
        .opacity(opacity)
        .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowOffset)
        .animation(animationManager.accessibleAnimation(.easeInOut(duration: 0.2)), value: isSelected)
        .animation(animationManager.accessibleAnimation(.easeInOut(duration: 0.2)), value: isPressed)
        .cardPlayAnimation(isActive: playAnimationTrigger, manager: animationManager)
        .onTapGesture {
            if isPlayable {
                // Trigger haptic feedback
                hapticManager.trigger(.cardPlay)
                
                // Play audio feedback
                audioManager.playSound(.cardPlace)
                
                // Trigger play animation
                playAnimationTrigger = true
                
                onTap?()
            } else {
                // Invalid move feedback
                hapticManager.trigger(.cardInvalid)
                audioManager.playSound(.cardInvalid)
            }
        }
        .onLongPressGesture(minimumDuration: 0) { pressing in
            isPressed = pressing
            if pressing {
                // Light haptic for press start
                hapticManager.trigger(.cardSelect)
            }
        } perform: {
            // Long press completed - could show card details
        }
        .onAppear {
            if isAnimating {
                withAnimation(animationManager.accessibleAnimation(.easeInOut(duration: 0.5))) {
                    rotationAngle = 360
                }
            }
        }
        // Comprehensive accessibility support
        .cardAccessibility(card: card, isPlayable: isPlayable, manager: accessibilityManager)
        .accessibleTouchTarget(manager: accessibilityManager)
        // Alternative focus management for iOS accessibility
        .onReceive(NotificationCenter.default.publisher(for: UIAccessibility.elementFocusedNotification)) { _ in
            // Handle accessibility focus changes
            hapticManager.trigger(.focusChange)
            audioManager.playAccessibilitySound(.focusChanged)
        }
        // High contrast support
        .overlay(
            RoundedRectangle(cornerRadius: cardSize.cornerRadius)
                .stroke(
                    accessibilityManager.isIncreaseContrastEnabled ? Color.primary : Color.clear,
                    lineWidth: isFocused ? 3 : 0
                )
        )
        .scaleEffect(accessibilityManager.isLargeTextEnabled ? 1.1 : 1.0)
        .onReceive(NotificationCenter.default.publisher(for: UIAccessibility.voiceOverStatusDidChangeNotification)) { _ in
            // Respond to VoiceOver state changes
        }
    }
    
    // MARK: - Computed Properties
    
    /// Background color based on card state with accessibility support
    private var cardBackground: Color {
        let baseColor: Color
        
        if isSelected {
            baseColor = Color.white
        } else if !isPlayable {
            baseColor = Color.gray.opacity(0.6)  // More contrast for disabled state
        } else {
            baseColor = Color.white
        }
        
        // Apply high contrast adjustments if needed
        if accessibilityManager.isIncreaseContrastEnabled {
            if isSelected {
                return Color.white
            } else if !isPlayable {
                return Color.gray.opacity(0.4)  // Even more contrast
            } else {
                return Color.white
            }
        }
        
        return baseColor
    }
    
    /// Border color based on card state with accessibility support
    private var cardBorder: Color {
        let baseColor: Color
        
        if isSelected {
            baseColor = Color.blue
        } else if !isPlayable {
            baseColor = Color.red.opacity(0.8)  // Clear visual feedback for non-playable cards
        } else {
            baseColor = Color.black.opacity(0.3)  // Stronger default border
        }
        
        // Apply high contrast adjustments
        if accessibilityManager.isIncreaseContrastEnabled {
            if isSelected {
                return Color.blue
            } else if !isPlayable {
                return Color.red  // Maximum contrast for disabled state
            } else {
                return Color.black.opacity(0.6) // Very strong border
            }
        }
        
        return baseColor
    }
    
    /// Color for suit symbols with color-blind accessibility support
    private var suitColor: Color {
        // Base colors
        let baseColor: Color
        switch card.suit {
        case .hearts, .diamonds:
            baseColor = Color.red
        case .clubs, .spades:
            baseColor = Color.black
        }
        
        // High contrast adjustments
        if accessibilityManager.isIncreaseContrastEnabled {
            switch card.suit {
            case .hearts, .diamonds:
                return Color.red
            case .clubs, .spades:
                return Color.black
            }
        }
        
        return baseColor
    }
    
    /// Scale effect based on state
    private var scaleEffect: CGFloat {
        if isPressed {
            return 0.95
        } else if isSelected {
            return 1.05
        } else if !isPlayable {
            return 0.9
        } else {
            return 1.0
        }
    }
    
    /// Opacity based on state
    private var opacity: Double {
        if !isPlayable {
            return 0.6
        } else {
            return 1.0
        }
    }
    
    /// Shadow color
    private var shadowColor: Color {
        if isSelected {
            return Color.blue.opacity(0.5)
        } else {
            return Color.black.opacity(0.3)
        }
    }
    
    /// Shadow radius
    private var shadowRadius: CGFloat {
        if isSelected {
            return 8
        } else {
            return 4
        }
    }
    
    /// Shadow offset
    private var shadowOffset: CGFloat {
        if isSelected {
            return 4
        } else {
            return 2
        }
    }
}

// MARK: - Card Sizes

/// Different sizes for cards in various contexts
enum CardSize {
    case small      // For opponent hands, trick history
    case normal     // Standard game cards
    case large      // For detailed view, tutorials
    
    var width: CGFloat {
        switch self {
        case .small: return 60    // Increased from 40 - minimum touch target
        case .normal: return 90   // Increased from 60 - main game cards
        case .large: return 120   // Increased from 80 - detailed views
        }
    }
    
    var height: CGFloat {
        return width * 1.4 // Standard card ratio
    }
    
    var cornerRadius: CGFloat {
        return width * 0.1
    }
    
    var borderWidth: CGFloat {
        switch self {
        case .small: return 1
        case .normal: return 1.5
        case .large: return 2
        }
    }
    
    var contentPadding: CGFloat {
        return width * 0.08
    }
    
    var contentSpacing: CGFloat {
        return height * 0.05
    }
    
    var valueFont: Font {
        switch self {
        case .small: return .caption     // Increased from caption2
        case .normal: return .body       // Increased from caption  
        case .large: return .title3      // Increased from body
        }
    }
    
    var suitFont: Font {
        switch self {
        case .small: return .caption     // Increased from caption2
        case .normal: return .body       // Increased from caption
        case .large: return .title3      // Increased from body
        }
    }
    
    var centerSuitFont: Font {
        switch self {
        case .small: return .title2      // Increased from title3
        case .normal: return .largeTitle // Increased from title2  
        case .large: return .largeTitle  // Increased from title
        }
    }
}

// MARK: - Card Back View
// Note: CardBackView is defined in OpponentHandView.swift

// MARK: - Preview

struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Normal cards
            HStack(spacing: 20) {
                CardView(card: Card(suit: .hearts, value: 10), isSelected: false, isPlayable: true)
                CardView(card: Card(suit: .spades, value: 7), isSelected: true, isPlayable: true)
                CardView(card: Card(suit: .diamonds, value: 14), isSelected: false, isPlayable: false)
            }
            
            // Different sizes
            HStack(spacing: 20) {
                CardView(card: Card(suit: .clubs, value: 11), cardSize: .small)
                CardView(card: Card(suit: .hearts, value: 12), cardSize: .normal)
                CardView(card: Card(suit: .spades, value: 13), cardSize: .large)
            }
            
            // Card back
            CardBackView()
                .frame(width: CardSize.normal.width, height: CardSize.normal.height)
        }
        .padding()
        .background(Color.green.opacity(0.3))
        .previewLayout(.sizeThatFits)
    }
}

// MARK: - Metal Card View

/// Metal-powered card view with advanced rendering and interactions
struct MetalCardView: UIViewRepresentable {
    let card: Card
    let isSelected: Bool
    let isPlayable: Bool  
    let isAnimating: Bool
    
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.delegate = context.coordinator
        mtkView.preferredFramesPerSecond = 60
        mtkView.enableSetNeedsDisplay = true
        mtkView.isPaused = false
        mtkView.backgroundColor = UIColor.clear
        
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.updateCard(card: card, isSelected: isSelected, isPlayable: isPlayable, isAnimating: isAnimating)
    }
    
    func makeCoordinator() -> MetalCardCoordinator {
        MetalCardCoordinator(card: card)
    }
}

/// Coordinator for Metal card rendering  
class MetalCardCoordinator: NSObject, MTKViewDelegate {
    private var renderer: Renderer?
    private var cardRenderer: CardRenderer?
    private var card: Card
    private var isSelected = false
    private var isPlayable = true
    private var isAnimating = false
    
    init(card: Card) {
        self.card = card
        super.init()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Handle view size changes - Metal views handle this internally
    }
    
    func draw(in view: MTKView) {
        guard let device = view.device,
              let drawable = view.currentDrawable else { return }
        
        // Initialize renderers if needed with proper error handling
        if cardRenderer == nil {
            do {
                guard let commandQueue = device.makeCommandQueue() else { 
                    print("Failed to create Metal command queue")
                    return 
                }
                cardRenderer = CardRenderer(device: device, commandQueue: commandQueue)
            } catch {
                print("Failed to initialize CardRenderer: \(error)")
                return
            }
        }
        
        // Safely render the card with Metal
        do {
            cardRenderer?.renderCard(
                card: card,
                isSelected: isSelected,
                isPlayable: isPlayable,
                isAnimating: isAnimating,
                to: drawable,
                view: view
            )
            
            // Don't call drawable.present() here - it's handled in CardRenderer.renderCard()
        } catch {
            print("Metal rendering error: \(error)")
        }
    }
    
    func updateCard(card: Card, isSelected: Bool, isPlayable: Bool, isAnimating: Bool) {
        self.card = card
        self.isSelected = isSelected
        self.isPlayable = isPlayable
        self.isAnimating = isAnimating
    }
}