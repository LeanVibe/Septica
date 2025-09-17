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
    let onDragChanged: ((DragGesture.Value) -> Void)?
    let onDragEnded: ((DragGesture.Value) -> Void)?
    
    // Accessibility and UX managers
    @EnvironmentObject private var accessibilityManager: AccessibilityManager
    @EnvironmentObject private var hapticManager: HapticManager
    @EnvironmentObject private var audioManager: AudioManager
    @EnvironmentObject private var animationManager: AnimationManager
    
    // Visual effects system
    @StateObject private var visualEffectsManager = CardVisualEffectsManager()
    
    @State private var isPressed = false
    @State private var rotationAngle: Double = 0
    @State private var isFocused = false
    @State private var playAnimationTrigger = false
    @State private var dragOffset = CGSize.zero
    @State private var isDragging = false
    
    // Enhanced visual effects state
    @State private var showPremiumAnimation = false
    @State private var currentAnimationSequence: AnimationSequenceType = .sevenPlaySpecial
    @State private var particleEffectActive = false
    
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
        onTap: (() -> Void)? = nil,
        onDragChanged: ((DragGesture.Value) -> Void)? = nil,
        onDragEnded: ((DragGesture.Value) -> Void)? = nil
    ) {
        self.card = card
        self.isSelected = isSelected
        self.isPlayable = isPlayable
        self.isAnimating = isAnimating
        self.cardSize = cardSize
        self.onTap = onTap
        self.onDragChanged = onDragChanged
        self.onDragEnded = onDragEnded
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
            .fill(
                // Enhanced premium card background with professional depth
                LinearGradient(
                    colors: [
                        cardBackground,
                        cardBackground.opacity(0.95),
                        cardBackground.opacity(0.85),
                        cardBackground
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                // Premium border with sophisticated depth effect
                RoundedRectangle(cornerRadius: cardSize.cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                cardBorder,
                                cardBorder.opacity(0.7),
                                cardBorder.opacity(0.9),
                                cardBorder
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ), 
                        lineWidth: cardSize.borderWidth
                    )
            )
            .frame(width: cardSize.width, height: cardSize.height)
            // Multi-layer shadow system for premium depth (Shuffle Cats style)
            .background(
                RoundedRectangle(cornerRadius: cardSize.cornerRadius)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.12), radius: 2, x: 0, y: 1)
                    .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
                    .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 6)
            )
    }
    
    private var cardContentView: some View {
        ZStack {
            // Premium glass morphism card surface (Shuffle Cats style)
            RoundedRectangle(cornerRadius: cardSize.cornerRadius * 0.85)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.98), 
                            Color.white.opacity(0.94), 
                            Color.white.opacity(0.96),
                            Color.white.opacity(0.92)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    // Sophisticated glass edge highlight
                    RoundedRectangle(cornerRadius: cardSize.cornerRadius * 0.85)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.6), 
                                    Color.clear,
                                    Color.clear,
                                    suitColor.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ), 
                            lineWidth: 1.0
                        )
                )
                .overlay(
                    // Inner Romanian cultural accent
                    RoundedRectangle(cornerRadius: cardSize.cornerRadius * 0.85)
                        .stroke(
                            suitColor.opacity(0.15), 
                            lineWidth: 0.8
                        )
                        .padding(1)
                )
                .background(
                    // Professional drop shadow for content area
                    RoundedRectangle(cornerRadius: cardSize.cornerRadius * 0.85)
                        .fill(Color.white)
                        .shadow(color: suitColor.opacity(0.08), radius: 2, x: 0, y: 1)
                        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
                )
            
            VStack(spacing: cardSize.contentSpacing) {
                // Top left value and suit - Enhanced for visibility
                HStack {
                    VStack(spacing: 1) {
                        Text(card.displayValue)
                            .font(cardSize.valueFont.weight(.heavy))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [suitColor, suitColor.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: Color.white, radius: 1, x: 0, y: 0)
                            .shadow(color: Color.white.opacity(0.9), radius: 2, x: 1, y: 1)
                            .shadow(color: suitColor.opacity(0.3), radius: 2, x: 1, y: 1)
                        
                        Text(card.suit.symbol)
                            .font(cardSize.suitFont.weight(.heavy))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [suitColor, suitColor.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: Color.white, radius: 1, x: 0, y: 0)
                            .shadow(color: Color.white.opacity(0.9), radius: 2, x: 1, y: 1)
                            .shadow(color: suitColor.opacity(0.3), radius: 2, x: 1, y: 1)
                    }
                    .background(
                        // White backing for better contrast
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.9))
                            .blur(radius: 2)
                    )
                    Spacer()
                }
                
                Spacer()
                
                // Center suit symbol with enhanced Romanian design and premium effects
                ZStack {
                    // Enhanced background circle with premium gradient
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    suitColor.opacity(0.25),
                                    suitColor.opacity(0.12),
                                    suitColor.opacity(0.05),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 5,
                                endRadius: cardSize.width * 0.35
                            )
                        )
                        .frame(width: cardSize.width * 0.65, height: cardSize.width * 0.65)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            suitColor.opacity(0.3),
                                            suitColor.opacity(0.15),
                                            suitColor.opacity(0.25)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .shadow(color: suitColor.opacity(0.2), radius: 3, x: 0, y: 2)
                    
                    Text(card.suit.symbol)
                        .font(cardSize.centerSuitFont.weight(.black))
                        .foregroundStyle(suitColor.opacity(0.9))
                        .shadow(color: Color.white, radius: 2, x: 0, y: 0)
                        .shadow(color: Color.white.opacity(0.6), radius: 4, x: 1, y: 1)
                        .shadow(color: suitColor.opacity(0.4), radius: 4, x: 3, y: 3)
                        .shadow(color: suitColor.opacity(0.2), radius: 6, x: 4, y: 4)
                        .scaleEffect(isSelected ? 1.15 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                }
                
                Spacer()
                
                // Bottom right value and suit (rotated) - Enhanced for visibility
                HStack {
                    Spacer()
                    VStack(spacing: 1) {
                        Text(card.suit.symbol)
                            .font(cardSize.suitFont.weight(.black))
                            .foregroundStyle(suitColor)
                            .shadow(color: Color.white, radius: 2, x: 0, y: 0)
                            .shadow(color: Color.white.opacity(0.8), radius: 3, x: 1, y: 1)
                            .shadow(color: suitColor.opacity(0.5), radius: 3, x: 2, y: 2)
                        
                        Text(card.displayValue)
                            .font(cardSize.valueFont.weight(.black))
                            .foregroundStyle(suitColor)
                            .shadow(color: Color.white, radius: 2, x: 0, y: 0)
                            .shadow(color: Color.white.opacity(0.8), radius: 3, x: 1, y: 1)
                            .shadow(color: suitColor.opacity(0.5), radius: 3, x: 2, y: 2)
                    }
                    .background(
                        // White backing for better contrast
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.9))
                            .blur(radius: 2)
                    )
                    .rotationEffect(.degrees(180))
                }
            }
            .padding(cardSize.contentPadding)
        }
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
        ZStack {
            // Premium selection glow with Shuffle Cats-style prominence
            RoundedRectangle(cornerRadius: cardSize.cornerRadius)
                .stroke(
                    LinearGradient(
                        colors: [
                            RomanianColors.goldAccent,
                            RomanianColors.primaryYellow,
                            RomanianColors.goldAccent
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3.5
                )
                .background(
                    RoundedRectangle(cornerRadius: cardSize.cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    RomanianColors.goldAccent.opacity(0.25),
                                    RomanianColors.primaryYellow.opacity(0.15),
                                    RomanianColors.goldAccent.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: RomanianColors.goldAccent.opacity(0.6), radius: 8, x: 0, y: 0)
                .shadow(color: RomanianColors.primaryYellow.opacity(0.4), radius: 16, x: 0, y: 0)
                .shadow(color: .yellow.opacity(0.6), radius: 10, x: 0, y: 4)
                .shadow(color: .orange.opacity(0.4), radius: 15, x: 0, y: 6)
            
            // Enhanced animated pulse effect with more visibility
            RoundedRectangle(cornerRadius: cardSize.cornerRadius)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.yellow.opacity(0.9), 
                            Color.orange.opacity(0.8), 
                            Color.yellow.opacity(0.7),
                            Color.orange.opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .scaleEffect(1.02)
                .opacity(0.9)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: UUID())
        }
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
            
            // Trigger enhanced visual effects
            triggerPlayVisualEffects()
            
            onTap?()
        } else {
            // Invalid move feedback
            hapticManager.trigger(.cardInvalid)
            audioManager.playSound(.cardInvalid)
            
            // Trigger invalid move visual effects
            visualEffectsManager.triggerEffect(.invalidCardShake, for: card)
        }
    }
    
    /// Trigger visual effects when card is played
    private func triggerPlayVisualEffects() {
        // Determine the type of play and trigger appropriate effects
        if card.value == 7 {
            // Special seven play effects
            visualEffectsManager.triggerEffect(.goldenGlow, for: card)
            currentAnimationSequence = .sevenPlaySpecial
            showPremiumAnimation = true
        } else if card.isPointCard {
            // Point card effects
            visualEffectsManager.triggerEffect(.pointCardShimmer, for: card)
            currentAnimationSequence = .pointCardCapture
            showPremiumAnimation = true
        } else {
            // Standard play effects
            visualEffectsManager.triggerEffect(.sparklePlay, for: card)
        }
        
        // Add Romanian cultural flourish for authentic cultural moments
        if card.suit == .hearts && card.value == 10 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.visualEffectsManager.triggerEffect(.romanianFlourish, for: self.card)
            }
        }
    }
    
    private var accessibilityLabel: String {
        return "\(card.displayValue) of \(card.suit.rawValue)\(isSelected ? ", selected" : "")\(isPlayable ? "" : ", not playable")"
    }
    
    /// Check if Metal rendering should be used
    private func shouldUseMetalRendering() -> Bool {
        // Temporarily disable Metal rendering to use enhanced SwiftUI cards
        // Metal rendering will be re-enabled after proper card face textures are implemented
        return false
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
            
            // Special effect for wild card (7) - Romanian Septica tradition
            if card.value == 7 {
                RoundedRectangle(cornerRadius: cardSize.cornerRadius)
                    .stroke(Color.orange.opacity(0.6), lineWidth: 1)
                    .scaleEffect(1.02)
                    .opacity(0.8)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: UUID())
            }
            
            // Premium animation overlay
            if showPremiumAnimation {
                PremiumCardAnimationSequence(
                    card: card,
                    sequenceType: currentAnimationSequence,
                    isActive: $showPremiumAnimation
                )
            }
        }
        .frame(width: cardSize.width, height: cardSize.height) // CRITICAL: Enforce proper card dimensions to prevent stretching
        .romanianPatternOverlay() // Subtle Romanian cultural pattern
        .premiumSelection(
            isSelected: isSelected,
            isPlayable: isPlayable,
            isSpecialCard: card.value == 7 || card.isPointCard // 7s and point cards get special treatment
        )
        .premiumDepth(isLifted: isSelected, isPressed: isPressed)
        .cardVisualEffects(
            card: card,
            isSelected: isSelected,
            isPlayable: isPlayable,
            effectsManager: visualEffectsManager
        )
        .scaleEffect(scaleEffect)
        .rotationEffect(.degrees(rotationAngle))
        .opacity(opacity)
        .offset(dragOffset)
        .animation(.spring(response: 0.35, dampingFraction: 0.75, blendDuration: 0.15), value: isSelected)
        .animation(.spring(response: 0.25, dampingFraction: 0.8, blendDuration: 0.1), value: isPressed)
        .animation(.spring(response: 0.4, dampingFraction: 0.85, blendDuration: 0.15), value: isDragging)
        .cardPlayAnimation(isActive: playAnimationTrigger, manager: animationManager)
        .gesture(
            // Enhanced Shuffle Cats-style drag gestures with magnetic snapping
            DragGesture(minimumDistance: 8, coordinateSpace: .global)
                .onChanged { value in
                    guard isPlayable else { 
                        // Enhanced invalid move feedback with shake
                        hapticManager.trigger(.cardInvalid)
                        withAnimation(.easeInOut(duration: 0.1).repeatCount(3, autoreverses: true)) {
                            dragOffset = CGSize(width: 8, height: 0)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                dragOffset = .zero
                            }
                        }
                        return
                    }
                    
                    // Start drag with enhanced visual feedback
                    if !isDragging {
                        isDragging = true
                        hapticManager.trigger(.cardSelect)
                        audioManager.playSound(.cardSelect)
                        
                        // Trigger magnetic attraction effect
                        visualEffectsManager.triggerEffect(.magneticAttraction, for: card)
                        
                        // Enhanced lift effect for drag start
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            rotationAngle = Double.random(in: -3...3) // Subtle rotation for natural feel
                        }
                    }
                    
                    // Smooth drag following with enhanced physics
                    let dampingFactor: CGFloat = 0.8
                    dragOffset = CGSize(
                        width: value.translation.width * dampingFactor,
                        height: value.translation.height * dampingFactor
                    )
                    
                    // Call external drag handler for Shuffle Cats-style drop zone feedback
                    onDragChanged?(value)
                }
                .onEnded { value in
                    guard isPlayable else { return }
                    
                    isDragging = false
                    
                    // Enhanced drag distance calculation with directional bias
                    let dragDistance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
                    let dragVelocity = sqrt(pow(value.velocity.width, 2) + pow(value.velocity.height, 2))
                    
                    // Shuffle Cats-style drop detection (distance + velocity + direction)
                    let isIntentionalDrop = dragDistance > 40 || dragVelocity > 500
                    let isUpwardDrag = value.translation.height < -25 // Dragging toward play area
                    
                    if isIntentionalDrop && isUpwardDrag {
                        // Successful drop - enhanced feedback
                        onDragEnded?(value)
                        
                        hapticManager.trigger(.cardPlay)
                        audioManager.playSound(.cardPlace)
                        playAnimationTrigger = true
                        
                        // Trigger card trail effect and play effects
                        visualEffectsManager.triggerEffect(.cardTrail, for: card)
                        triggerPlayVisualEffects()
                        
                        // Celebrate successful drag
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                            rotationAngle = 0
                            dragOffset = .zero
                        }
                    } else {
                        // Return to hand with natural animation
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            rotationAngle = 0
                            dragOffset = .zero
                        }
                        
                        // Short drag - treat as selection/tap
                        if dragDistance < 25 {
                            onTap?()
                            hapticManager.trigger(.cardSelect)
                            audioManager.playSound(.cardSelect)
                        }
                    }
                }
                .simultaneously(with: 
                    // Enhanced tap gesture for accessibility and quick play
                    TapGesture()
                        .onEnded {
                            guard isPlayable && !isDragging else {
                                if !isPlayable {
                                    hapticManager.trigger(.cardInvalid)
                                    audioManager.playSound(.cardInvalid)
                                    
                                    // Enhanced visual feedback for invalid tap
                                    withAnimation(.easeInOut(duration: 0.15).repeatCount(2, autoreverses: true)) {
                                        dragOffset = CGSize(width: 0, height: -5)
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        withAnimation(.spring()) {
                                            dragOffset = .zero
                                        }
                                    }
                                }
                                return
                            }
                            
                            // Enhanced tap feedback
                            hapticManager.trigger(.cardPlay)
                            audioManager.playSound(.cardPlace)
                            playAnimationTrigger = true
                            
                            // Trigger visual effects for tap
                            triggerPlayVisualEffects()
                            
                            // Quick tap animation
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                                rotationAngle = Double.random(in: -2...2)
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    rotationAngle = 0
                                }
                            }
                            
                            onTap?()
                        }
                )
        )
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
    
    /// Romanian cultural color for suit symbols with accessibility support
    private var suitColor: Color {
        // Romanian cultural colors maintaining traditional distinction
        let baseColor: Color
        switch card.suit {
        case .hearts, .diamonds:
            baseColor = RomanianColors.primaryRed // Romanian flag red
        case .clubs, .spades:
            baseColor = RomanianColors.primaryBlue // Romanian flag blue (darker than black for cultural authenticity)
        }
        
        // High contrast adjustments for accessibility
        if accessibilityManager.isIncreaseContrastEnabled {
            switch card.suit {
            case .hearts, .diamonds:
                return RomanianColors.embroideryRed // More vibrant red for high contrast
            case .clubs, .spades:
                return Color.black // Ensure maximum contrast for accessibility
            }
        }
        
        return baseColor
    }
    
    /// Scale effect based on state
    private var scaleEffect: CGFloat {
        if isPressed {
            return 0.92
        } else if isSelected {
            return 1.15  // Even more pronounced selection for better visibility
        } else if !isPlayable {
            return 0.85
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
            return 12  // More prominent shadow for selected cards
        } else {
            return 6   // Enhanced default shadow
        }
    }
    
    /// Shadow offset
    private var shadowOffset: CGFloat {
        if isSelected {
            return 6   // Deeper shadow offset for selected cards
        } else {
            return 3   // Enhanced default offset
        }
    }
}

// MARK: - Card Sizes

/// Different sizes for cards in various contexts
enum CardSize {
    case small      // For opponent hands, trick history
    case compact    // For organized columns like Shuffle Cats
    case normal     // Standard game cards
    case large      // For detailed view, tutorials
    
    var width: CGFloat {
        switch self {
        case .small: return 180    // Enhanced visibility - significantly wider
        case .compact: return 220  // Table cards - wider for better recognition
        case .normal: return 260   // Standard cards - doubled width for clear visibility
        case .large: return 400   // Large detailed view - doubled width
        }
    }
    
    var height: CGFloat {
        return width * 1.4 // Standard playing card ratio (2.5" × 3.5" = 1.4) - matches reference card proportions better
    }
    
    var cornerRadius: CGFloat {
        return width * 0.1
    }
    
    var borderWidth: CGFloat {
        switch self {
        case .small: return 1
        case .compact: return 1.2
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
        case .compact: return .caption   // Compact size for organized columns
        case .normal: return .body       // Increased from caption  
        case .large: return .title3      // Increased from body
        }
    }
    
    var suitFont: Font {
        switch self {
        case .small: return .caption     // Increased from caption2
        case .compact: return .caption   // Compact size for organized columns
        case .normal: return .body       // Increased from caption
        case .large: return .title3      // Increased from body
        }
    }
    
    var centerSuitFont: Font {
        switch self {
        case .small: return .title2      // Increased from title3
        case .compact: return .title3    // Compact size for organized columns
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
