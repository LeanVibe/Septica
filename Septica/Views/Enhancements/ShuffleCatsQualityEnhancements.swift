//
//  ShuffleCatsQualityEnhancements.swift
//  Septica
//
//  ShuffleCats-quality visual enhancements while preserving Romanian cultural authenticity
//  Provides premium depth, lighting, motion, and interaction effects
//

import SwiftUI
import Combine

// MARK: - ShuffleCats Quality Enhancement Manager

/// Manager for ShuffleCats-style visual enhancements with Romanian cultural preservation
@MainActor
class ShuffleCatsQualityEnhancementManager: ObservableObject {
    
    // MARK: - Enhancement Settings
    
    @Published var enhancementLevel: EnhancementLevel = .high
    @Published var motionSensitivity: MotionSensitivity = .medium
    @Published var preserveCulturalAuthenticity: Bool = true
    @Published var enableParallaxEffects: Bool = true
    @Published var enableMicroInteractions: Bool = true
    
    // MARK: - Visual Quality Settings
    
    @Published var shadowQuality: ShadowQuality = .premium
    @Published var lightingModel: LightingModel = .physicallyBased
    @Published var enableDepthOfField: Bool = true
    @Published var enableMotionBlur: Bool = true
    
    // MARK: - Performance Monitoring
    
    @Published var renderingPerformance: RenderingPerformance = RenderingPerformance()
    @Published var adaptiveQuality: Bool = true
    
    // MARK: - Enhancement Interface
    
    /// Apply ShuffleCats-quality enhancements to a card view
    func enhanceCard<Content: View>(_ content: Content, card: Card, isSelected: Bool) -> some View {
        content
            .modifier(
                ShuffleCatsCardEnhancement(
                    card: card,
                    isSelected: isSelected,
                    enhancementLevel: enhancementLevel,
                    motionSensitivity: motionSensitivity,
                    preserveCultural: preserveCulturalAuthenticity,
                    shadowQuality: shadowQuality,
                    lightingModel: lightingModel
                )
            )
    }
    
    /// Apply premium motion effects
    func applyMotionEffects<Content: View>(_ content: Content, motionData: MotionData) -> some View {
        content
            .modifier(
                PremiumMotionEffects(
                    motionData: motionData,
                    sensitivity: motionSensitivity,
                    enableParallax: enableParallaxEffects
                )
            )
    }
    
    /// Apply micro-interactions for polish
    func applyMicroInteractions<Content: View>(_ content: Content, interactionState: InteractionState) -> some View {
        content
            .modifier(
                MicroInteractionEffects(
                    state: interactionState,
                    enhancementLevel: enhancementLevel,
                    enableMicroInteractions: enableMicroInteractions
                )
            )
    }
}

// MARK: - ShuffleCats Card Enhancement Modifier

/// Primary enhancement modifier that applies ShuffleCats-quality effects
struct ShuffleCatsCardEnhancement: ViewModifier {
    let card: Card
    let isSelected: Bool
    let enhancementLevel: EnhancementLevel
    let motionSensitivity: MotionSensitivity
    let preserveCultural: Bool
    let shadowQuality: ShadowQuality
    let lightingModel: LightingModel
    
    @State private var hoverAmount: CGFloat = 0
    @State private var pressAmount: CGFloat = 0
    @State private var glowIntensity: Double = 0
    @State private var shimmerOffset: CGFloat = -2
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(1 + hoverAmount * 0.02 + pressAmount * 0.03)
            .rotation3DEffect(
                .degrees(hoverAmount * 2),
                axis: (x: 0.1, y: 1, z: 0)
            )
            .overlay(premiumShadowLayers)
            .overlay(culturalGlowAccent)
            .overlay(premiumShimmerEffect)
            .overlay(selectionEnhancement)
            .contentShape(Rectangle())
            .onHover { hovering in
                withAnimation(.easeOut(duration: 0.2)) {
                    hoverAmount = hovering ? 1.0 : 0.0
                }
            }
            .scaleEffect(isSelected ? 1.08 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelected)
            .onAppear {
                startShimmerAnimation()
                if isSelected {
                    startSelectionGlow()
                }
            }
    }
    
    // MARK: - Premium Shadow Layers
    
    @ViewBuilder
    private var premiumShadowLayers: some View {
        if shadowQuality != .disabled {
            ZStack {
                // Base shadow
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.clear)
                    .shadow(
                        color: .black.opacity(0.15),
                        radius: shadowQuality.baseRadius,
                        x: 0,
                        y: shadowQuality.baseOffset
                    )
                
                // Mid-layer shadow for depth
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.clear)
                    .shadow(
                        color: .black.opacity(0.08),
                        radius: shadowQuality.midRadius,
                        x: 0,
                        y: shadowQuality.midOffset
                    )
                
                // Premium top shadow for ShuffleCats quality
                if shadowQuality == .premium {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.clear)
                        .shadow(
                            color: .black.opacity(0.05),
                            radius: shadowQuality.topRadius,
                            x: 0,
                            y: shadowQuality.topOffset
                        )
                }
                
                // Cultural shadow accent
                if preserveCultural && isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.clear)
                        .shadow(
                            color: RomanianColors.goldAccent.opacity(0.3),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                }
            }
        }
    }
    
    // MARK: - Cultural Glow Accent
    
    @ViewBuilder
    private var culturalGlowAccent: some View {
        if preserveCultural && (card.value == 7 || card.isPointCard) {
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        colors: [
                            RomanianColors.goldAccent.opacity(glowIntensity * 0.6),
                            RomanianColors.embroideryRed.opacity(glowIntensity * 0.4),
                            RomanianColors.goldAccent.opacity(glowIntensity * 0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .opacity(glowIntensity)
        }
    }
    
    // MARK: - Premium Shimmer Effect
    
    @ViewBuilder
    private var premiumShimmerEffect: some View {
        if enhancementLevel == .ultra {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.3),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .mask(
                    Rectangle()
                        .frame(width: 30)
                        .offset(x: shimmerOffset * 100)
                )
                .allowsHitTesting(false)
        }
    }
    
    // MARK: - Selection Enhancement
    
    @ViewBuilder
    private var selectionEnhancement: some View {
        if isSelected && enhancementLevel != .minimal {
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        colors: [
                            preserveCultural ? RomanianColors.goldAccent : Color.blue,
                            preserveCultural ? RomanianColors.primaryYellow : Color.cyan,
                            preserveCultural ? RomanianColors.goldAccent : Color.blue
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .scaleEffect(1.02)
                .opacity(0.8 + sin(Date().timeIntervalSince1970 * 3) * 0.2)
        }
    }
    
    // MARK: - Animation Methods
    
    private func startShimmerAnimation() {
        withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
            shimmerOffset = 2
        }
    }
    
    private func startSelectionGlow() {
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            glowIntensity = 1.0
        }
    }
}

// MARK: - Premium Motion Effects

/// Sophisticated motion effects matching ShuffleCats quality
struct PremiumMotionEffects: ViewModifier {
    let motionData: MotionData
    let sensitivity: MotionSensitivity
    let enableParallax: Bool
    
    @State private var parallaxOffset: CGSize = .zero
    @State private var rotationEffect: Double = 0
    
    func body(content: Content) -> some View {
        content
            .offset(parallaxOffset)
            .rotation3DEffect(
                .degrees(rotationEffect),
                axis: (x: motionData.gyroscope.y, y: motionData.gyroscope.x, z: 0)
            )
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: parallaxOffset)
            .animation(.spring(response: 0.8, dampingFraction: 0.7), value: rotationEffect)
            .onChange(of: motionData) { newData in
                updateMotionEffects(newData)
            }
    }
    
    private func updateMotionEffects(_ data: MotionData) {
        let multiplier = sensitivity.multiplier
        
        if enableParallax {
            parallaxOffset = CGSize(
                width: data.accelerometer.x * multiplier * 5,
                height: -data.accelerometer.y * multiplier * 5
            )
        }
        
        rotationEffect = data.gyroscope.z * multiplier * 2
    }
}

// MARK: - Micro-Interaction Effects

/// Subtle micro-interactions for premium feel
struct MicroInteractionEffects: ViewModifier {
    let state: InteractionState
    let enhancementLevel: EnhancementLevel
    let enableMicroInteractions: Bool
    
    @State private var rippleEffect: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var hapticTrigger: Bool = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(pulseScale)
            .overlay(rippleOverlay)
            .onChange(of: state) { newState in
                handleStateChange(newState)
            }
    }
    
    @ViewBuilder
    private var rippleOverlay: some View {
        if enableMicroInteractions && enhancementLevel != .minimal {
            Circle()
                .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                .scaleEffect(rippleEffect)
                .opacity(2.0 - rippleEffect)
                .allowsHitTesting(false)
        }
    }
    
    private func handleStateChange(_ newState: InteractionState) {
        guard enableMicroInteractions else { return }
        
        switch newState {
        case .idle:
            withAnimation(.easeOut(duration: 0.3)) {
                pulseScale = 1.0
                rippleEffect = 0
            }
            
        case .pressed:
            withAnimation(.easeIn(duration: 0.1)) {
                pulseScale = 0.95
            }
            triggerHapticFeedback(.light)
            
        case .released:
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                pulseScale = 1.02
            }
            
            withAnimation(.easeOut(duration: 0.6)) {
                rippleEffect = 2.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    pulseScale = 1.0
                }
            }
            
            triggerHapticFeedback(.medium)
            
        case .hovering:
            withAnimation(.easeOut(duration: 0.2)) {
                pulseScale = 1.05
            }
            
        case .dragging:
            withAnimation(.easeOut(duration: 0.2)) {
                pulseScale = 1.1
            }
            triggerHapticFeedback(.heavy)
        }
    }
    
    private func triggerHapticFeedback(_ intensity: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: intensity)
        generator.impactOccurred()
    }
}

// MARK: - Supporting Types

/// Enhancement quality levels
enum EnhancementLevel: String, CaseIterable {
    case minimal = "Minimal"
    case medium = "Medium" 
    case high = "High"
    case ultra = "Ultra"
    
    var description: String {
        switch self {
        case .minimal: return "Basic enhancements for performance"
        case .medium: return "Balanced quality and performance"
        case .high: return "High-quality ShuffleCats-style effects"
        case .ultra: return "Maximum quality with all effects"
        }
    }
}

/// Motion sensitivity levels
enum MotionSensitivity: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var multiplier: CGFloat {
        switch self {
        case .low: return 0.3
        case .medium: return 0.6
        case .high: return 1.0
        }
    }
}

/// Shadow quality settings
enum ShadowQuality: String, CaseIterable {
    case disabled = "Disabled"
    case basic = "Basic"
    case enhanced = "Enhanced"
    case premium = "Premium"
    
    var baseRadius: CGFloat {
        switch self {
        case .disabled: return 0
        case .basic: return 4
        case .enhanced: return 8
        case .premium: return 12
        }
    }
    
    var baseOffset: CGFloat {
        switch self {
        case .disabled: return 0
        case .basic: return 2
        case .enhanced: return 4
        case .premium: return 6
        }
    }
    
    var midRadius: CGFloat { baseRadius * 0.7 }
    var midOffset: CGFloat { baseOffset * 0.7 }
    var topRadius: CGFloat { baseRadius * 1.5 }
    var topOffset: CGFloat { baseOffset * 1.2 }
}

/// Lighting model options
enum LightingModel: String, CaseIterable {
    case basic = "Basic"
    case physicallyBased = "Physically Based"
    case cinematic = "Cinematic"
    
    var description: String {
        switch self {
        case .basic: return "Simple ambient lighting"
        case .physicallyBased: return "Realistic lighting simulation"
        case .cinematic: return "Dramatic cinematic lighting"
        }
    }
}

/// Motion data for parallax effects
struct MotionData {
    let accelerometer: (x: CGFloat, y: CGFloat, z: CGFloat)
    let gyroscope: (x: CGFloat, y: CGFloat, z: CGFloat)
    let timestamp: TimeInterval
    
    static let zero = MotionData(
        accelerometer: (0, 0, 0),
        gyroscope: (0, 0, 0),
        timestamp: 0
    )
}

/// Interaction states for micro-interactions
enum InteractionState {
    case idle
    case pressed
    case released
    case hovering
    case dragging
}

/// Performance monitoring data
struct RenderingPerformance {
    var frameRate: Double = 60.0
    var droppedFrames: Int = 0
    var renderTime: Double = 0.0
    var memoryUsage: Int = 0
    var lastUpdate: TimeInterval = 0
}

// MARK: - View Extensions

extension View {
    /// Apply ShuffleCats-quality enhancements
    func shuffleCatsQuality(
        card: Card,
        isSelected: Bool = false,
        enhancementLevel: EnhancementLevel = .high,
        preserveCultural: Bool = true
    ) -> some View {
        self.modifier(
            ShuffleCatsCardEnhancement(
                card: card,
                isSelected: isSelected,
                enhancementLevel: enhancementLevel,
                motionSensitivity: .medium,
                preserveCultural: preserveCultural,
                shadowQuality: .premium,
                lightingModel: .physicallyBased
            )
        )
    }
    
    /// Apply premium motion effects
    func premiumMotion(
        motionData: MotionData = .zero,
        sensitivity: MotionSensitivity = .medium,
        enableParallax: Bool = true
    ) -> some View {
        self.modifier(
            PremiumMotionEffects(
                motionData: motionData,
                sensitivity: sensitivity,
                enableParallax: enableParallax
            )
        )
    }
    
    /// Apply micro-interactions
    func microInteractions(
        state: InteractionState = .idle,
        enhancementLevel: EnhancementLevel = .high,
        enabled: Bool = true
    ) -> some View {
        self.modifier(
            MicroInteractionEffects(
                state: state,
                enhancementLevel: enhancementLevel,
                enableMicroInteractions: enabled
            )
        )
    }
}

// MARK: - Romanian Cultural Preservation Helpers

extension ShuffleCatsCardEnhancement {
    /// Ensure Romanian cultural elements are preserved in enhancements
    private var culturalPreservationMultiplier: Double {
        return preserveCultural ? 1.2 : 1.0
    }
    
    /// Get culturally appropriate colors for effects
    private var culturalAccentColor: Color {
        if preserveCultural {
            switch card.suit {
            case .hearts, .diamonds:
                return RomanianColors.embroideryRed
            case .clubs, .spades:
                return RomanianColors.primaryBlue
            }
        } else {
            return .blue
        }
    }
}

// MARK: - Preview

struct ShuffleCatsQualityEnhancements_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Enhanced card examples
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .frame(width: 100, height: 140)
                .shuffleCatsQuality(
                    card: Card(suit: .hearts, value: 7),
                    isSelected: true,
                    enhancementLevel: .ultra,
                    preserveCultural: true
                )
            
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .frame(width: 100, height: 140)
                .shuffleCatsQuality(
                    card: Card(suit: .clubs, value: 14),
                    isSelected: false,
                    enhancementLevel: .high,
                    preserveCultural: true
                )
                .microInteractions(
                    state: .idle,
                    enhancementLevel: .high,
                    enabled: true
                )
        }
        .padding()
        .background(Color.gray.opacity(0.2))
    }
}