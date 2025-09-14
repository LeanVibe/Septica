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
        // Metal rendering temporarily disabled - use SwiftUI fallback
        swiftUICardView
    }
    
    /// Check if Metal rendering should be used
    private func shouldUseMetalRendering() -> Bool {
        // Temporarily disabled until Metal toolchain is properly configured in Xcode Beta
        // TODO: Re-enable once Metal shaders compile successfully
        return false
        
        // Future implementation:
        // return MTLCreateSystemDefaultDevice() != nil && 
        //        !ProcessInfo.processInfo.arguments.contains("--disable-metal") &&
        //        shadersCompiledSuccessfully()
    }
    
    /// SwiftUI fallback implementation
    private var swiftUICardView: some View {
        ZStack {
            // Card background
            RoundedRectangle(cornerRadius: cardSize.cornerRadius)
                .fill(cardBackground)
                .stroke(cardBorder, lineWidth: cardSize.borderWidth)
                .frame(width: cardSize.width, height: cardSize.height)
            
            // Card content
            VStack(spacing: cardSize.contentSpacing) {
                // Top left value and suit
                HStack {
                    VStack(spacing: 2) {
                        Text(card.displayValue)
                            .font(cardSize.valueFont)
                            .fontWeight(.bold)
                        
                        Text(card.suit.symbol)
                            .font(cardSize.suitFont)
                    }
                    .foregroundColor(suitColor)
                    
                    Spacer()
                }
                
                Spacer()
                
                // Center suit symbol (large)
                Text(card.suit.symbol)
                    .font(cardSize.centerSuitFont)
                    .foregroundColor(suitColor.opacity(0.3))
                
                Spacer()
                
                // Bottom right value and suit (rotated)
                HStack {
                    Spacer()
                    
                    VStack(spacing: 2) {
                        Text(card.suit.symbol)
                            .font(cardSize.suitFont)
                        
                        Text(card.displayValue)
                            .font(cardSize.valueFont)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(suitColor)
                    .rotationEffect(.degrees(180))
                }
            }
            .padding(cardSize.contentPadding)
            
            // Point card indicator
            if card.isPointCard {
                VStack {
                    HStack {
                        Spacer()
                        Circle()
                            .fill(Color.yellow)
                            .frame(width: 8, height: 8)
                            .offset(x: -4, y: 4)
                    }
                    Spacer()
                }
            }
            
            // Special card indicators
            if card.value == 7 {
                // Wild card indicator
                VStack {
                    HStack {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 6, height: 6)
                            .offset(x: 4, y: 4)
                        Spacer()
                    }
                    Spacer()
                }
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
            baseColor = Color.gray.opacity(0.8)
        } else {
            baseColor = Color.white.opacity(0.95)
        }
        
        // Apply high contrast adjustments if needed
        if accessibilityManager.isIncreaseContrastEnabled {
            if isSelected {
                return Color.white
            } else if !isPlayable {
                return Color.gray.opacity(0.6)
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
            baseColor = Color.gray
        } else {
            baseColor = Color.black.opacity(0.2)
        }
        
        // Apply high contrast adjustments
        if accessibilityManager.isIncreaseContrastEnabled {
            if isSelected {
                return Color.blue
            } else if !isPlayable {
                return Color.red.opacity(0.7) // Make disabled state more obvious
            } else {
                return Color.black.opacity(0.5) // Stronger border
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
        case .small: return 40
        case .normal: return 60
        case .large: return 80
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
        case .small: return .caption2
        case .normal: return .caption
        case .large: return .body
        }
    }
    
    var suitFont: Font {
        switch self {
        case .small: return .caption2
        case .normal: return .caption
        case .large: return .body
        }
    }
    
    var centerSuitFont: Font {
        switch self {
        case .small: return .title3
        case .normal: return .title2
        case .large: return .title
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

// MARK: - Metal Card View (Disabled)
// TODO: Re-enable when Metal toolchain is properly configured
// MetalCardView implementation removed temporarily to avoid compilation issues