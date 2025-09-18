//
//  CardVisualEffectsSystem.swift
//  Septica
//
//  Advanced visual effects and animations for premium card interactions
//  Particle systems, lighting effects, and cinematic animations
//

import SwiftUI
import UIKit
import Combine

// MARK: - Enhanced Card Visual Effects Manager with Coordinated Animation Sequences

/// Manages advanced visual effects for cards including particles, lighting, and coordinated multi-card animations
@MainActor
class CardVisualEffectsManager: ObservableObject {
    @Published var activeEffects: [CardEffect] = []
    @Published var isParticleSystemEnabled = true
    @Published var isAdvancedLightingEnabled = true
    @Published var effectIntensity: EffectIntensity = .medium
    
    // Coordinated animation sequences
    @Published var activeSequences: [CoordinatedSequence] = []
    @Published var sequenceCoordinator = SequenceCoordinator()
    
    private var effectTimer: Timer?
    private var sequenceUpdateTimer: Timer?
    
    init() {
        startSequenceCoordination()
    }
    
    deinit {
        effectTimer?.invalidate()
        sequenceUpdateTimer?.invalidate()
    }
    
    /// Trigger a visual effect for a specific card action with coordinated sequence support
    func triggerEffect(
        _ effectType: CardEffectType, 
        for card: Card, 
        at position: CGPoint = .zero,
        coordinatedWith sequence: CoordinatedSequenceType? = nil
    ) {
        let effect = CardEffect(
            id: UUID(),
            type: effectType,
            card: card,
            position: position,
            startTime: Date(),
            duration: effectType.duration,
            intensity: effectIntensity,
            sequenceId: sequence?.rawValue
        )
        
        activeEffects.append(effect)
        
        // Register with sequence coordinator if part of a coordinated sequence
        if let sequenceType = sequence {
            sequenceCoordinator.registerEffect(effect, for: sequenceType)
        }
        
        // Auto-cleanup effect after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + effectType.duration) {
            self.removeEffect(effect.id)
        }
    }
    
    /// Remove a specific effect
    func removeEffect(_ id: UUID) {
        activeEffects.removeAll { $0.id == id }
    }
    
    /// Clear all active effects and sequences
    func clearAllEffects() {
        activeEffects.removeAll()
        activeSequences.removeAll()
        sequenceCoordinator.clearAll()
    }
    
    /// Start a coordinated animation sequence for multiple cards
    func startCoordinatedSequence(
        _ sequenceType: CoordinatedSequenceType,
        cards: [Card],
        positions: [CGPoint] = [],
        completion: @escaping () -> Void = {}
    ) {
        let sequence = CoordinatedSequence(
            id: UUID(),
            type: sequenceType,
            cards: cards,
            positions: positions.isEmpty ? Array(repeating: .zero, count: cards.count) : positions,
            startTime: Date(),
            completion: completion
        )
        
        activeSequences.append(sequence)
        sequenceCoordinator.startSequence(sequence)
        
        // Execute the coordinated sequence based on type
        executeCoordinatedSequence(sequence)
    }
    
    /// Execute a specific coordinated sequence
    private func executeCoordinatedSequence(_ sequence: CoordinatedSequence) {
        switch sequence.type {
        case .romanianSevenPlay:
            executeRomanianSevenSequence(sequence)
        case .multiCardCapture:
            executeMultiCardCaptureSequence(sequence)
        case .gameEndingCelebration:
            executeGameEndingCelebrationSequence(sequence)
        case .trickCompletionAnimation:
            executeTrickCompletionSequence(sequence)
        }
    }
    
    /// Execute Romanian seven play sequence with cultural authenticity
    private func executeRomanianSevenSequence(_ sequence: CoordinatedSequence) {
        let staggerDelay = sequence.type.staggerDelay
        
        for (index, card) in sequence.cards.enumerated() {
            let delay = Double(index) * staggerDelay
            let position = sequence.positions[index]
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                // Golden ceremonial glow for the seven
                self.triggerEffect(.goldenGlow, for: card, at: position, coordinatedWith: .romanianSevenPlay)
                
                // Traditional Romanian flourish
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.triggerEffect(.romanianFlourish, for: card, at: position, coordinatedWith: .romanianSevenPlay)
                }
                
                // Sparkle cascade for dramatic effect
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.triggerEffect(.sparklePlay, for: card, at: position, coordinatedWith: .romanianSevenPlay)
                }
            }
        }
    }
    
    /// Execute multi-card capture sequence with momentum
    private func executeMultiCardCaptureSequence(_ sequence: CoordinatedSequence) {
        let staggerDelay = sequence.type.staggerDelay
        
        for (index, card) in sequence.cards.enumerated() {
            let delay = Double(index) * staggerDelay
            let position = sequence.positions[index]
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                // Magnetic attraction effect
                self.triggerEffect(.magneticAttraction, for: card, at: position, coordinatedWith: .multiCardCapture)
                
                // Quick shimmer for point cards
                if card.isPointCard {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.triggerEffect(.pointCardShimmer, for: card, at: position, coordinatedWith: .multiCardCapture)
                    }
                }
                
                // Trail effect as cards move
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    self.triggerEffect(.cardTrail, for: card, at: position, coordinatedWith: .multiCardCapture)
                }
            }
        }
    }
    
    /// Execute game ending celebration sequence with joy
    private func executeGameEndingCelebrationSequence(_ sequence: CoordinatedSequence) {
        let staggerDelay = sequence.type.staggerDelay
        
        for (index, card) in sequence.cards.enumerated() {
            let delay = Double(index) * staggerDelay
            let position = sequence.positions[index]
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                // Victory celebration with sparkles
                self.triggerEffect(.victoryCelebration, for: card, at: position, coordinatedWith: .gameEndingCelebration)
                
                // Layered celebration effects
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.triggerEffect(.sparklePlay, for: card, at: position, coordinatedWith: .gameEndingCelebration)
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.triggerEffect(.goldenGlow, for: card, at: position, coordinatedWith: .gameEndingCelebration)
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.triggerEffect(.romanianFlourish, for: card, at: position, coordinatedWith: .gameEndingCelebration)
                }
            }
        }
    }
    
    /// Execute trick completion sequence with smooth professional flow
    private func executeTrickCompletionSequence(_ sequence: CoordinatedSequence) {
        let staggerDelay = sequence.type.staggerDelay
        
        for (index, card) in sequence.cards.enumerated() {
            let delay = Double(index) * staggerDelay
            let position = sequence.positions[index]
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                // Smooth collection effect
                self.triggerEffect(.magneticAttraction, for: card, at: position, coordinatedWith: .trickCompletionAnimation)
                
                // Gentle trail as cards gather
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.triggerEffect(.cardTrail, for: card, at: position, coordinatedWith: .trickCompletionAnimation)
                }
                
                // Final settling sparkle
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    self.triggerEffect(.sparklePlay, for: card, at: position, coordinatedWith: .trickCompletionAnimation)
                }
            }
        }
    }
    
    /// Start sequence coordination timer
    private func startSequenceCoordination() {
        sequenceUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            self.updateActiveSequences()
        }
    }
    
    /// Update all active coordinated sequences
    private func updateActiveSequences() {
        let currentTime = Date()
        
        // Remove completed sequences
        activeSequences.removeAll { sequence in
            let elapsed = currentTime.timeIntervalSince(sequence.startTime)
            return elapsed > sequence.type.duration
        }
        
        // Update sequence coordinator
        sequenceCoordinator.update(deltaTime: 0.016)
    }
}

// MARK: - Card Effect Types

/// Types of visual effects that can be applied to cards
enum CardEffectType: CaseIterable {
    case sparklePlay        // Sparkle particles when card is played
    case goldenGlow        // Golden glow for special cards (7s)
    case pointCardShimmer  // Shimmer effect for point cards
    case invalidCardShake  // Shake effect for invalid moves
    case victoryCelebration // Celebration particles for winning
    case magneticAttraction // Magnetic pull effect during drag
    case romanianFlourish  // Cultural flourish effect
    case cardTrail         // Motion trail during movement
    
    var duration: TimeInterval {
        switch self {
        case .sparklePlay: return 1.5
        case .goldenGlow: return 2.0
        case .pointCardShimmer: return 3.0
        case .invalidCardShake: return 0.6
        case .victoryCelebration: return 3.0
        case .magneticAttraction: return 0.8
        case .romanianFlourish: return 2.5
        case .cardTrail: return 1.0
        }
    }
    
    var particleCount: Int {
        switch self {
        case .sparklePlay: return 12
        case .goldenGlow: return 8
        case .pointCardShimmer: return 15
        case .invalidCardShake: return 0
        case .victoryCelebration: return 25
        case .magneticAttraction: return 6
        case .romanianFlourish: return 20
        case .cardTrail: return 8
        }
    }
}

/// Effect intensity levels
enum EffectIntensity: CaseIterable {
    case subtle
    case medium
    case dramatic
    
    var particleMultiplier: Double {
        switch self {
        case .subtle: return 0.6
        case .medium: return 1.0
        case .dramatic: return 1.4
        }
    }
    
    var animationSpeed: Double {
        switch self {
        case .subtle: return 0.8
        case .medium: return 1.0
        case .dramatic: return 1.2
        }
    }
}

// MARK: - Card Effect Model

/// Represents an active visual effect on a card with sequence coordination
struct CardEffect: Identifiable, Equatable {
    let id: UUID
    let type: CardEffectType
    let card: Card
    let position: CGPoint
    let startTime: Date
    let duration: TimeInterval
    let intensity: EffectIntensity
    let sequenceId: String?
    
    var progress: Double {
        let elapsed = Date().timeIntervalSince(startTime)
        return min(elapsed / duration, 1.0)
    }
    
    var isActive: Bool {
        progress < 1.0
    }
}

// MARK: - Particle System

/// Advanced particle system for card effects
struct CardParticleSystem: View {
    let effect: CardEffect
    @State private var particles: [Particle] = []
    @State private var animationTimer: Timer?
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                ParticleView(particle: particle, effect: effect)
            }
        }
        .onAppear {
            generateParticles()
            startAnimation()
        }
        .onDisappear {
            stopAnimation()
        }
    }
    
    private func generateParticles() {
        particles = (0..<effect.type.particleCount).map { index in
            let angle = Double(index) * (2 * .pi / Double(effect.type.particleCount))
            let distance = Double.random(in: 20...60) * effect.intensity.particleMultiplier
            
            return Particle(
                id: UUID(),
                type: getParticleType(for: effect.type),
                position: CGPoint(
                    x: effect.position.x + cos(angle) * distance,
                    y: effect.position.y + sin(angle) * distance
                ),
                velocity: CGPoint(
                    x: cos(angle) * Double.random(in: 30...80),
                    y: sin(angle) * Double.random(in: 30...80)
                ),
                color: getParticleColor(for: effect),
                size: Double.random(in: 2...6) * effect.intensity.particleMultiplier,
                life: effect.duration,
                opacity: 1.0
            )
        }
    }
    
    private func startAnimation() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            updateParticles()
        }
    }
    
    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    private func updateParticles() {
        let deltaTime = 0.016 // ~60 FPS
        
        for i in 0..<particles.count {
            particles[i].update(deltaTime: deltaTime)
        }
        
        // Remove expired particles
        particles.removeAll { $0.opacity <= 0 }
    }
    
    private func getParticleType(for effectType: CardEffectType) -> ParticleType {
        switch effectType {
        case .sparklePlay: return .sparkle
        case .goldenGlow: return .glow
        case .pointCardShimmer: return .shimmer
        case .invalidCardShake: return .dust
        case .victoryCelebration: return .confetti
        case .magneticAttraction: return .energy
        case .romanianFlourish: return .culturalSymbol
        case .cardTrail: return .trail
        }
    }
    
    private func getParticleColor(for effect: CardEffect) -> Color {
        switch effect.type {
        case .sparklePlay:
            return Color.white
        case .goldenGlow:
            return RomanianColors.goldAccent
        case .pointCardShimmer:
            return Color.yellow
        case .invalidCardShake:
            return Color.red.opacity(0.7)
        case .victoryCelebration:
            return [RomanianColors.primaryBlue, RomanianColors.primaryRed, RomanianColors.goldAccent].randomElement() ?? Color.white
        case .magneticAttraction:
            return Color.blue.opacity(0.8)
        case .romanianFlourish:
            return RomanianColors.embroideryRed
        case .cardTrail:
            return effect.card.suit == .hearts || effect.card.suit == .diamonds ? 
                   RomanianColors.primaryRed.opacity(0.6) : 
                   RomanianColors.primaryBlue.opacity(0.6)
        }
    }
}

// MARK: - Particle Model and View

/// Individual particle in the particle system
struct Particle: Identifiable {
    let id: UUID
    let type: ParticleType
    var position: CGPoint
    var velocity: CGPoint
    let color: Color
    var size: Double
    var life: TimeInterval
    var opacity: Double
    
    private var age: TimeInterval = 0
    
    init(id: UUID, type: ParticleType, position: CGPoint, velocity: CGPoint, color: Color, size: Double, life: TimeInterval, opacity: Double) {
        self.id = id
        self.type = type
        self.position = position
        self.velocity = velocity
        self.color = color
        self.size = size
        self.life = life
        self.opacity = opacity
        self.age = 0
    }
    
    mutating func update(deltaTime: TimeInterval) {
        age += deltaTime
        
        // Update position
        position.x += velocity.x * deltaTime
        position.y += velocity.y * deltaTime
        
        // Apply gravity for some particle types
        if type == .confetti || type == .dust {
            velocity.y += 200 * deltaTime // Gravity
        }
        
        // Update opacity based on age
        opacity = max(0, 1.0 - age / life)
        
        // Update size for some effects
        switch type {
        case .sparkle, .glow:
            size = size * (1.0 + sin(age * 10) * 0.1) // Twinkling effect
        case .shimmer:
            size = size * (1.0 + sin(age * 8) * 0.2) // Shimmer pulsing
        default:
            break
        }
    }
}

/// Types of particles
enum ParticleType {
    case sparkle
    case glow
    case shimmer
    case dust
    case confetti
    case energy
    case culturalSymbol
    case trail
}

/// View for rendering individual particles
struct ParticleView: View {
    let particle: Particle
    let effect: CardEffect
    
    var body: some View {
        Group {
            switch particle.type {
            case .sparkle:
                sparkleView
            case .glow:
                glowView
            case .shimmer:
                shimmerView
            case .dust:
                dustView
            case .confetti:
                confettiView
            case .energy:
                energyView
            case .culturalSymbol:
                culturalSymbolView
            case .trail:
                trailView
            }
        }
        .position(particle.position)
        .opacity(particle.opacity)
        .animation(.linear(duration: 0.016), value: particle.position)
    }
    
    private var sparkleView: some View {
        ZStack {
            // Star shape with multiple layers for sparkle effect
            Image(systemName: "star.fill")
                .font(.system(size: particle.size))
                .foregroundColor(particle.color)
                .shadow(color: particle.color, radius: 2)
            
            Image(systemName: "star.fill")
                .font(.system(size: particle.size * 0.7))
                .foregroundColor(.white)
                .scaleEffect(1.0 + sin(Date().timeIntervalSinceReferenceDate * 10) * 0.2)
        }
    }
    
    private var glowView: some View {
        Circle()
            .fill(RadialGradient(
                colors: [particle.color, particle.color.opacity(0.3), Color.clear],
                center: .center,
                startRadius: 0,
                endRadius: particle.size
            ))
            .frame(width: particle.size * 2, height: particle.size * 2)
            .blur(radius: 1)
    }
    
    private var shimmerView: some View {
        Capsule()
            .fill(LinearGradient(
                colors: [Color.clear, particle.color, Color.clear],
                startPoint: .leading,
                endPoint: .trailing
            ))
            .frame(width: particle.size * 3, height: particle.size * 0.5)
            .rotationEffect(.degrees(Double.random(in: 0...360)))
    }
    
    private var dustView: some View {
        Circle()
            .fill(particle.color)
            .frame(width: particle.size, height: particle.size)
            .blur(radius: 0.5)
    }
    
    private var confettiView: some View {
        Rectangle()
            .fill(particle.color)
            .frame(width: particle.size, height: particle.size * 1.5)
            .rotationEffect(.degrees(particle.position.x * 0.5))
    }
    
    private var energyView: some View {
        Ellipse()
            .fill(LinearGradient(
                colors: [particle.color, Color.clear],
                startPoint: .center,
                endPoint: .trailing
            ))
            .frame(width: particle.size * 2, height: particle.size * 0.8)
            .blur(radius: 1)
    }
    
    private var culturalSymbolView: some View {
        // Romanian cultural symbol (simplified folk art element)
        ZStack {
            Image(systemName: "diamond.fill")
                .font(.system(size: particle.size))
                .foregroundColor(particle.color)
            
            Image(systemName: "plus")
                .font(.system(size: particle.size * 0.6))
                .foregroundColor(.white)
                .fontWeight(.bold)
        }
    }
    
    private var trailView: some View {
        Capsule()
            .fill(LinearGradient(
                colors: [particle.color, Color.clear],
                startPoint: .leading,
                endPoint: .trailing
            ))
            .frame(width: particle.size * 4, height: particle.size * 0.3)
            .blur(radius: 0.5)
    }
}

// MARK: - Global Illumination System

/// Advanced global illumination system for realistic light bouncing and color bleeding
struct GlobalIlluminationSystem {
    /// Global illumination configuration
    struct GIConfiguration {
        let bounceIntensity: Double
        let colorBleedingStrength: Double
        let ambientOcclusionStrength: Double
        let culturalColorInfluence: Double
        let lightBounceRadius: CGFloat
        let maxBounces: Int
        
        static let standard = GIConfiguration(
            bounceIntensity: 0.3,
            colorBleedingStrength: 0.4,
            ambientOcclusionStrength: 0.2,
            culturalColorInfluence: 0.5,
            lightBounceRadius: 50.0,
            maxBounces: 3
        )
        
        static let enhanced = GIConfiguration(
            bounceIntensity: 0.5,
            colorBleedingStrength: 0.6,
            ambientOcclusionStrength: 0.3,
            culturalColorInfluence: 0.7,
            lightBounceRadius: 75.0,
            maxBounces: 4
        )
        
        static let performance = GIConfiguration(
            bounceIntensity: 0.2,
            colorBleedingStrength: 0.3,
            ambientOcclusionStrength: 0.15,
            culturalColorInfluence: 0.4,
            lightBounceRadius: 40.0,
            maxBounces: 2
        )
    }
    
    /// Calculate global illumination contribution at a specific position
    static func calculateGIContribution(
        at position: CGPoint,
        configuration: GIConfiguration
    ) -> Color {
        // Simulate indirect lighting from nearby surfaces
        let ambientContribution = Color.white.opacity(0.05 * configuration.bounceIntensity)
        
        // Add subtle Romanian cultural ambient lighting
        let culturalAmbient = RomanianColors.goldAccent.opacity(
            0.03 * configuration.culturalColorInfluence
        )
        
        return blendGIColors(ambientContribution, culturalAmbient)
    }
    
    /// Blend colors for global illumination
    private static func blendGIColors(_ base: Color, _ overlay: Color) -> Color {
        // Simplified color blending for SwiftUI compatibility
        return Color.white.opacity(0.05) // Subtle global illumination effect
    }
}

// MARK: - Advanced Lighting Effects

/// Professional multi-light system with Romanian cultural tinting
struct ProfessionalLightingSystem {
    /// Light types for the multi-light setup
    enum LightType {
        case keyLight      // Primary directional light
        case fillLight     // Secondary softer light
        case rimLight      // Edge highlighting light
        case ambientLight  // General scene illumination
        case culturalAccent // Romanian cultural color accent
    }
    
    /// Light configuration with Romanian cultural elements
    struct LightConfiguration {
        let type: LightType
        let color: Color
        let intensity: Double
        let direction: CGPoint
        let falloff: Double
        let culturalTint: Color?
        
        static func keyLight(intensity: Double = 0.8, culturalTint: Color? = nil) -> LightConfiguration {
            LightConfiguration(
                type: .keyLight,
                color: .white,
                intensity: intensity,
                direction: CGPoint(x: 0.3, y: -0.7), // Top-left key light
                falloff: 0.6,
                culturalTint: culturalTint
            )
        }
        
        static func fillLight(intensity: Double = 0.4) -> LightConfiguration {
            LightConfiguration(
                type: .fillLight,
                color: Color.white.opacity(0.8),
                intensity: intensity,
                direction: CGPoint(x: -0.5, y: -0.3), // Opposite side fill
                falloff: 0.8,
                culturalTint: nil
            )
        }
        
        static func rimLight(intensity: Double = 0.6, culturalColor: Color) -> LightConfiguration {
            LightConfiguration(
                type: .rimLight,
                color: culturalColor,
                intensity: intensity,
                direction: CGPoint(x: 0, y: -1), // Top rim light
                falloff: 0.3,
                culturalTint: culturalColor
            )
        }
        
        static func ambientOcclusion(intensity: Double = 0.2) -> LightConfiguration {
            LightConfiguration(
                type: .ambientLight,
                color: Color.gray.opacity(0.5),
                intensity: intensity,
                direction: CGPoint(x: 0, y: 0), // Omnidirectional
                falloff: 1.0,
                culturalTint: nil
            )
        }
        
        static func romanianCulturalAccent(for card: Card, intensity: Double = 0.5) -> LightConfiguration {
            let culturalColor: Color
            switch card.suit {
            case .hearts, .diamonds:
                culturalColor = RomanianColors.embroideryRed
            case .clubs, .spades:
                culturalColor = RomanianColors.primaryBlue
            }
            
            return LightConfiguration(
                type: .culturalAccent,
                color: culturalColor,
                intensity: intensity,
                direction: CGPoint(x: 0.2, y: 0.8), // Cultural accent from bottom
                falloff: 0.7,
                culturalTint: culturalColor
            )
        }
    }
    
    /// Calculate lighting for a given position with global illumination
    static func calculateLighting(
        at position: CGPoint,
        normal: CGPoint,
        lights: [LightConfiguration],
        globalIllumination: GlobalIlluminationSystem.GIConfiguration
    ) -> Color {
        var finalColor = Color.clear
        var totalIntensity: Double = 0
        
        for light in lights {
            // Calculate light contribution
            let lightVector = CGPoint(
                x: light.direction.x - position.x,
                y: light.direction.y - position.y
            )
            
            let distance = sqrt(lightVector.x * lightVector.x + lightVector.y * lightVector.y)
            let normalizedLight = CGPoint(x: lightVector.x / distance, y: lightVector.y / distance)
            
            // Calculate dot product for light intensity
            let dotProduct = max(0, normalizedLight.x * normal.x + normalizedLight.y * normal.y)
            
            // Apply falloff
            let falloffIntensity = max(0, 1.0 - (distance * light.falloff))
            let lightIntensity = dotProduct * light.intensity * falloffIntensity
            
            // Add cultural tinting if present
            let lightColor = light.culturalTint ?? light.color
            
            // Accumulate color contribution
            finalColor = blendColors(finalColor, lightColor.opacity(lightIntensity))
            totalIntensity += lightIntensity
        }
        
        // Apply global illumination contribution
        let giContribution = GlobalIlluminationSystem.calculateGIContribution(
            at: position,
            configuration: globalIllumination
        )
        finalColor = blendColors(finalColor, giContribution)
        
        return finalColor
    }
    
    /// Blend two colors for lighting accumulation
    private static func blendColors(_ base: Color, _ overlay: Color) -> Color {
        // Simplified additive blending for lighting (SwiftUI compatible)
        return overlay.opacity(0.7) // Use overlay with reduced opacity for blending effect
    }
}

/// Advanced lighting system for cards with multi-light setup
struct CardLightingEffects: View {
    let card: Card
    let isSelected: Bool
    let isSpecialCard: Bool
    let lightingIntensity: EffectIntensity
    
    @State private var lightingPhase: Double = 0
    @State private var lightingConfiguration: [ProfessionalLightingSystem.LightConfiguration] = []
    
    var body: some View {
        ZStack {
            // Multi-layer professional lighting system
            multiLightSystemView
            
            // Enhanced special card lighting with cultural elements
            if isSpecialCard {
                enhancedSpecialCardLighting
            }
            
            if isSelected {
                enhancedSelectionLighting
            }
            
            // Romanian cultural lighting with authenticity
            if card.value == 7 {
                romanianSevenCulturalLighting
            }
            
            if card.isPointCard {
                enhancedPointCardLighting
            }
            
            // Global illumination overlay
            globalIlluminationOverlay
        }
        .onAppear {
            setupLightingConfiguration()
            startLightingAnimation()
        }
    }
    
    /// Professional multi-light system with Romanian cultural tinting
    private var multiLightSystemView: some View {
        ZStack {
            ForEach(Array(lightingConfiguration.enumerated()), id: \.offset) { index, light in
                lightLayerView(for: light, index: index)
            }
        }
    }
    
    /// Individual light layer with proper falloff and cultural tinting
    private func lightLayerView(for light: ProfessionalLightingSystem.LightConfiguration, index: Int) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(
                RadialGradient(
                    colors: [
                        light.color.opacity(light.intensity * lightingIntensity.particleMultiplier),
                        light.color.opacity(light.intensity * 0.6 * lightingIntensity.particleMultiplier),
                        light.color.opacity(light.intensity * 0.3 * lightingIntensity.particleMultiplier),
                        Color.clear
                    ],
                    center: UnitPoint(
                        x: 0.5 + light.direction.x * 0.3,
                        y: 0.5 + light.direction.y * 0.3
                    ),
                    startRadius: 5,
                    endRadius: 45 * (1.0 - light.falloff)
                )
            )
            .scaleEffect(1.0 + sin(lightingPhase + Double(index) * 0.5) * 0.05)
            .opacity(0.7 + sin(lightingPhase + Double(index) * 0.7) * 0.2)
            .blendMode(light.type == .ambientLight ? .multiply : .normal)
    }
    
    /// Enhanced special card lighting with professional depth
    private var enhancedSpecialCardLighting: some View {
        ZStack {
            // Key light with cultural tinting
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    RadialGradient(
                        colors: [
                            RomanianColors.goldAccent.opacity(0.6),
                            RomanianColors.goldAccent.opacity(0.3),
                            RomanianColors.primaryYellow.opacity(0.2),
                            Color.clear
                        ],
                        center: UnitPoint(x: 0.3, y: 0.2), // Key light position
                        startRadius: 8,
                        endRadius: 40
                    )
                )
                .scaleEffect(1.03)
                .opacity(0.8 + sin(lightingPhase) * 0.15)
            
            // Rim lighting for edges
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    LinearGradient(
                        colors: [
                            RomanianColors.goldAccent.opacity(0.9),
                            RomanianColors.goldAccent.opacity(0.6),
                            Color.clear,
                            RomanianColors.goldAccent.opacity(0.6),
                            RomanianColors.goldAccent.opacity(0.9)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2.5
                )
                .scaleEffect(1.02)
                .opacity(0.9 + sin(lightingPhase * 1.2) * 0.1)
            
            // Cultural accent lighting
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            romanianCulturalAccentColor.opacity(0.3),
                            romanianCulturalAccentColor.opacity(0.15)
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .scaleEffect(1.01)
                .opacity(0.6 + sin(lightingPhase * 0.8) * 0.2)
        }
    }
    
    /// Enhanced selection lighting with multi-light system
    private var enhancedSelectionLighting: some View {
        ZStack {
            // Primary selection glow with key lighting
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    RadialGradient(
                        colors: [
                            RomanianColors.primaryBlue.opacity(0.4),
                            RomanianColors.primaryBlue.opacity(0.2),
                            Color.blue.opacity(0.1),
                            Color.clear
                        ],
                        center: UnitPoint(x: 0.3, y: 0.2), // Key light position
                        startRadius: 12,
                        endRadius: 55
                    )
                )
                .scaleEffect(1.06)
                .opacity(0.8 + sin(lightingPhase * 1.2) * 0.2)
            
            // Fill light for balanced illumination
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    RadialGradient(
                        colors: [
                            Color.clear,
                            Color.blue.opacity(0.15),
                            Color.blue.opacity(0.08)
                        ],
                        center: UnitPoint(x: 0.7, y: 0.8), // Fill light position
                        startRadius: 15,
                        endRadius: 45
                    )
                )
                .scaleEffect(1.04)
                .opacity(0.6 + sin(lightingPhase * 0.8) * 0.25)
            
            // Rim lighting for selection emphasis
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    LinearGradient(
                        colors: [
                            RomanianColors.goldAccent.opacity(0.8),
                            Color.blue.opacity(0.6),
                            RomanianColors.goldAccent.opacity(0.8)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 3.0
                )
                .scaleEffect(1.03)
                .opacity(0.9 + sin(lightingPhase * 1.8) * 0.1)
        }
    }
    
    /// Romanian Seven lighting with authentic cultural elements
    private var romanianSevenCulturalLighting: some View {
        ZStack {
            // Traditional Romanian gold lighting
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    RadialGradient(
                        colors: [
                            RomanianColors.goldAccent.opacity(0.5),
                            Color.orange.opacity(0.3),
                            Color.yellow.opacity(0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 8,
                        endRadius: 35
                    )
                )
                .scaleEffect(1.02)
                .opacity(0.7 + sin(lightingPhase * 1.5) * 0.2)
            
            // Romanian folk pattern lighting accent
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    LinearGradient(
                        colors: [
                            RomanianColors.embroideryRed.opacity(0.4),
                            Color.orange.opacity(0.6),
                            Color.yellow.opacity(0.5),
                            Color.orange.opacity(0.6),
                            RomanianColors.embroideryRed.opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2.0
                )
                .scaleEffect(1.015)
                .opacity(0.8 + sin(lightingPhase * 2.2) * 0.2)
            
            // Cultural significance glow
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            RomanianColors.goldAccent.opacity(0.25),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .scaleEffect(1.005)
                .opacity(0.6 + sin(lightingPhase * 0.8) * 0.3)
        }
    }
    
    /// Enhanced point card lighting with strategic illumination
    private var enhancedPointCardLighting: some View {
        ZStack {
            // Key light for point card significance
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    RadialGradient(
                        colors: [
                            Color.yellow.opacity(0.35),
                            Color.yellow.opacity(0.2),
                            Color.orange.opacity(0.1),
                            Color.clear
                        ],
                        center: UnitPoint(x: 0.3, y: 0.2),
                        startRadius: 8,
                        endRadius: 38
                    )
                )
                .scaleEffect(1.04)
                .opacity(0.7 + sin(lightingPhase * 1.1) * 0.2)
            
            // Strategic value highlighting
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.yellow.opacity(0.6),
                            Color.orange.opacity(0.4),
                            Color.yellow.opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.8
                )
                .scaleEffect(1.02)
                .opacity(0.8 + sin(lightingPhase * 1.6) * 0.15)
            
            // Point value accent lighting
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            romanianCulturalAccentColor.opacity(0.2),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .scaleEffect(1.01)
                .opacity(0.6 + sin(lightingPhase * 0.9) * 0.25)
        }
    }
    
    /// Global illumination overlay for realistic lighting interaction
    private var globalIlluminationOverlay: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.05),
                        Color.clear,
                        romanianCulturalAccentColor.opacity(0.03)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .opacity(0.7 + sin(lightingPhase * 0.5) * 0.2)
    }
    
    /// Romanian cultural accent color based on card suit
    private var romanianCulturalAccentColor: Color {
        switch card.suit {
        case .hearts, .diamonds:
            return RomanianColors.embroideryRed
        case .clubs, .spades:
            return RomanianColors.primaryBlue
        }
    }
    
    /// Setup professional lighting configuration
    private func setupLightingConfiguration() {
        var lights: [ProfessionalLightingSystem.LightConfiguration] = []
        
        // Base lighting setup
        lights.append(.keyLight(intensity: 0.8, culturalTint: romanianCulturalAccentColor))
        lights.append(.fillLight(intensity: 0.4))
        lights.append(.ambientOcclusion(intensity: 0.2))
        
        // Enhanced lighting for special cards
        if isSpecialCard {
            lights.append(.rimLight(intensity: 0.7, culturalColor: RomanianColors.goldAccent))
        }
        
        // Selection state lighting
        if isSelected {
            lights.append(.rimLight(intensity: 0.8, culturalColor: RomanianColors.primaryBlue))
        }
        
        // Romanian cultural accent
        lights.append(.romanianCulturalAccent(for: card, intensity: 0.5))
        
        lightingConfiguration = lights
    }
    
    /// Start sophisticated lighting animation with phase management
    private func startLightingAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            withAnimation(.linear(duration: 0.016)) {
                lightingPhase += 0.08 * lightingIntensity.animationSpeed
            }
        }
    }
}

// MARK: - Card Motion Effects

/// Advanced motion effects for cards
struct CardMotionEffects: View {
    let card: Card
    let motionType: MotionEffectType
    let isActive: Bool
    
    @State private var motionPhase: Double = 0
    @State private var particles: [Particle] = []
    
    var body: some View {
        ZStack {
            if isActive {
                switch motionType {
                case .magneticPull:
                    magneticPullEffect
                case .playTrail:
                    playTrailEffect
                case .shuffleGlow:
                    shuffleGlowEffect
                case .victorySpark:
                    victorySparkEffect
                }
            }
        }
        .onAppear {
            if isActive {
                startMotionAnimation()
            }
        }
    }
    
    private var magneticPullEffect: some View {
        ForEach(0..<6, id: \.self) { index in
            Circle()
                .stroke(Color.blue.opacity(0.4), lineWidth: 1)
                .frame(width: 20 + CGFloat(index) * 8, height: 20 + CGFloat(index) * 8)
                .scaleEffect(1.0 + sin(motionPhase + Double(index) * 0.5) * 0.2)
                .opacity(0.8 - Double(index) * 0.1)
        }
    }
    
    private var playTrailEffect: some View {
        ForEach(0..<8, id: \.self) { index in
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.6),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 30 - CGFloat(index) * 2, height: 2)
                .offset(y: CGFloat(index) * -3)
                .opacity(0.8 - Double(index) * 0.1)
                .rotationEffect(.degrees(sin(motionPhase) * 10))
        }
    }
    
    private var shuffleGlowEffect: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(
                RadialGradient(
                    colors: [
                        Color.purple.opacity(0.3),
                        Color.blue.opacity(0.2),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 10,
                    endRadius: 40
                )
            )
            .scaleEffect(1.0 + sin(motionPhase) * 0.1)
            .opacity(0.7 + sin(motionPhase * 1.5) * 0.3)
    }
    
    private var victorySparkEffect: some View {
        ForEach(0..<12, id: \.self) { index in
            Image(systemName: "star.fill")
                .font(.system(size: 8))
                .foregroundColor(RomanianColors.goldAccent)
                .offset(
                    x: cos(Double(index) * .pi / 6) * (20 + sin(motionPhase) * 10),
                    y: sin(Double(index) * .pi / 6) * (20 + sin(motionPhase) * 10)
                )
                .opacity(0.8 + sin(motionPhase + Double(index)) * 0.2)
                .scaleEffect(0.8 + sin(motionPhase * 2 + Double(index)) * 0.4)
        }
    }
    
    private func startMotionAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            withAnimation(.linear(duration: 0.016)) {
                motionPhase += 0.1
            }
        }
    }
}

/// Types of motion effects
enum MotionEffectType {
    case magneticPull    // Magnetic attraction during drag
    case playTrail       // Trail when card is played
    case shuffleGlow     // Glow during shuffling
    case victorySpark    // Sparks for victory
}

// MARK: - SwiftUI Modifiers

/// Modifier to add enhanced visual effects to cards
struct CardVisualEffectsModifier: ViewModifier {
    let card: Card
    let isSelected: Bool
    let isPlayable: Bool
    let effectsManager: CardVisualEffectsManager
    
    func body(content: Content) -> some View {
        content
            .overlay(
                ZStack {
                    // Lighting effects
                    CardLightingEffects(
                        card: card,
                        isSelected: isSelected,
                        isSpecialCard: card.value == 7 || card.isPointCard,
                        lightingIntensity: effectsManager.effectIntensity
                    )
                    
                    // Particle effects
                    ForEach(effectsManager.activeEffects.filter { $0.card.id == card.id }) { effect in
                        CardParticleSystem(effect: effect)
                    }
                }
            )
    }
}

extension View {
    /// Apply enhanced visual effects to a card
    func cardVisualEffects(
        card: Card,
        isSelected: Bool,
        isPlayable: Bool,
        effectsManager: CardVisualEffectsManager
    ) -> some View {
        modifier(CardVisualEffectsModifier(
            card: card,
            isSelected: isSelected,
            isPlayable: isPlayable,
            effectsManager: effectsManager
        ))
    }
}

// MARK: - Premium Card Animation Sequences

/// Complex animation sequences for special card interactions
struct PremiumCardAnimationSequence: View {
    let card: Card
    let sequenceType: AnimationSequenceType
    @Binding var isActive: Bool
    
    @State private var animationPhase: AnimationPhase = .idle
    @State private var rotationAngle: Double = 0
    @State private var scaleEffect: CGFloat = 1.0
    @State private var glowIntensity: Double = 0
    
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.clear)
            .overlay(
                // Animation overlay effects
                animationOverlay
            )
            .rotationEffect(.degrees(rotationAngle))
            .scaleEffect(scaleEffect)
            .onChange(of: isActive) { newValue in
                if newValue {
                    startAnimationSequence()
                } else {
                    resetAnimation()
                }
            }
    }
    
    @ViewBuilder
    private var animationOverlay: some View {
        switch sequenceType {
        case .sevenPlaySpecial:
            sevenPlayAnimation
        case .pointCardCapture:
            pointCardAnimation
        case .gameWinning:
            gameWinAnimation
        case .culturalMoment:
            culturalAnimation
        }
    }
    
    private var sevenPlayAnimation: some View {
        ZStack {
            // Golden spiral effect
            ForEach(0..<8, id: \.self) { index in
                Path { path in
                    let center = CGPoint(x: 35, y: 50)
                    let radius = CGFloat(10 + index * 3)
                    let angle = Double(index) * .pi / 4 + rotationAngle * .pi / 180
                    
                    path.addArc(
                        center: center,
                        radius: radius,
                        startAngle: .radians(angle),
                        endAngle: .radians(angle + .pi),
                        clockwise: false
                    )
                }
                .stroke(RomanianColors.goldAccent.opacity(0.7 - Double(index) * 0.08), lineWidth: 2)
            }
        }
        .opacity(glowIntensity)
    }
    
    private var pointCardAnimation: some View {
        ZStack {
            // Shimmer wave effect
            ForEach(0..<5, id: \.self) { index in
                Ellipse()
                    .stroke(
                        LinearGradient(
                            colors: [Color.clear, Color.yellow.opacity(0.8), Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 70 + CGFloat(index) * 10, height: 20)
                    .offset(x: sin(rotationAngle * .pi / 180 + Double(index)) * 15)
            }
        }
        .opacity(glowIntensity)
    }
    
    private var gameWinAnimation: some View {
        ZStack {
            // Victory burst effect
            ForEach(0..<16, id: \.self) { index in
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [RomanianColors.goldAccent, Color.clear],
                            startPoint: .center,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 30, height: 3)
                    .offset(x: 15)
                    .rotationEffect(.degrees(Double(index) * 22.5 + rotationAngle))
            }
        }
        .scaleEffect(scaleEffect)
        .opacity(glowIntensity)
    }
    
    private var culturalAnimation: some View {
        ZStack {
            // Romanian folk pattern animation
            ForEach(0..<4, id: \.self) { index in
                Image(systemName: "diamond.fill")
                    .font(.system(size: 12))
                    .foregroundColor(RomanianColors.embroideryRed.opacity(0.8))
                    .offset(
                        x: cos(Double(index) * .pi / 2) * 20,
                        y: sin(Double(index) * .pi / 2) * 20
                    )
                    .scaleEffect(0.8 + sin(rotationAngle * .pi / 180 + Double(index)) * 0.3)
            }
        }
        .rotationEffect(.degrees(rotationAngle))
        .opacity(glowIntensity)
    }
    
    private func startAnimationSequence() {
        animationPhase = .starting
        
        // Phase 1: Initial burst
        withAnimation(.easeOut(duration: 0.3)) {
            scaleEffect = 1.2
            glowIntensity = 1.0
        }
        
        // Phase 2: Main animation
        withAnimation(.linear(duration: sequenceType.duration)) {
            rotationAngle = 360
        }
        
        // Phase 3: Fade out
        DispatchQueue.main.asyncAfter(deadline: .now() + sequenceType.duration * 0.7) {
            withAnimation(.easeIn(duration: 0.5)) {
                glowIntensity = 0
                scaleEffect = 1.0
            }
        }
        
        // Complete sequence
        DispatchQueue.main.asyncAfter(deadline: .now() + sequenceType.duration) {
            isActive = false
            animationPhase = .complete
        }
    }
    
    private func resetAnimation() {
        animationPhase = .idle
        rotationAngle = 0
        scaleEffect = 1.0
        glowIntensity = 0
    }
}

/// Types of premium animation sequences
enum AnimationSequenceType {
    case sevenPlaySpecial    // Special animation for playing a 7
    case pointCardCapture    // Animation for capturing point cards
    case gameWinning        // Victory celebration animation
    case culturalMoment     // Romanian cultural significance animation
    
    var duration: TimeInterval {
        switch self {
        case .sevenPlaySpecial: return 2.0
        case .pointCardCapture: return 1.5
        case .gameWinning: return 3.0
        case .culturalMoment: return 2.5
        }
    }
}

/// Animation phases
enum AnimationPhase {
    case idle
    case starting
    case running
    case complete
}

// MARK: - Environmental Effects System

/// Advanced environmental effects for atmospheric depth and immersion
struct EnvironmentalEffectsSystem {
    /// Environmental effect configuration
    struct EnvironmentConfiguration {
        let atmosphericPerspective: Double
        let fogIntensity: Double
        let depthCueing: Double
        let culturalAtmosphere: Double
        let depthOfFieldStrength: Double
        let hazeDistribution: Double
        
        static let subtle = EnvironmentConfiguration(
            atmosphericPerspective: 0.2,
            fogIntensity: 0.1,
            depthCueing: 0.3,
            culturalAtmosphere: 0.4,
            depthOfFieldStrength: 0.2,
            hazeDistribution: 0.15
        )
        
        static let standard = EnvironmentConfiguration(
            atmosphericPerspective: 0.4,
            fogIntensity: 0.2,
            depthCueing: 0.5,
            culturalAtmosphere: 0.6,
            depthOfFieldStrength: 0.3,
            hazeDistribution: 0.25
        )
        
        static let dramatic = EnvironmentConfiguration(
            atmosphericPerspective: 0.6,
            fogIntensity: 0.35,
            depthCueing: 0.7,
            culturalAtmosphere: 0.8,
            depthOfFieldStrength: 0.5,
            hazeDistribution: 0.4
        )
    }
    
    /// Calculate atmospheric perspective for distance-based effects
    static func calculateAtmosphericPerspective(
        at distance: CGFloat,
        configuration: EnvironmentConfiguration
    ) -> Color {
        let perspectiveFactor = min(1.0, distance / 200.0) // Normalize distance
        let atmosphericStrength = configuration.atmosphericPerspective * perspectiveFactor
        
        // Romanian cultural atmospheric tinting
        let culturalTint = RomanianColors.goldAccent.opacity(
            0.05 * configuration.culturalAtmosphere * perspectiveFactor
        )
        
        let atmosphericBlue = Color.blue.opacity(
            0.03 * atmosphericStrength
        )
        
        return blendAtmosphericColors(culturalTint, atmosphericBlue)
    }
    
    /// Calculate depth cueing for focus management
    static func calculateDepthCueing(
        for focusDistance: CGFloat,
        cardDistance: CGFloat,
        configuration: EnvironmentConfiguration
    ) -> Double {
        let distanceDifference = abs(cardDistance - focusDistance)
        let maxDistance: CGFloat = 150.0
        
        let depthFactor = min(1.0, distanceDifference / maxDistance)
        return 1.0 - (depthFactor * configuration.depthCueing)
    }
    
    /// Generate fog/haze effects for distant elements
    static func generateFogEffect(
        at distance: CGFloat,
        configuration: EnvironmentConfiguration
    ) -> Color {
        let fogStrength = min(1.0, distance / 180.0) * configuration.fogIntensity
        
        // Romanian cultural fog with warm undertones
        let culturalFog = RomanianColors.goldAccent.opacity(
            0.08 * fogStrength * configuration.culturalAtmosphere
        )
        
        let naturalFog = Color.gray.opacity(
            0.12 * fogStrength
        )
        
        return blendAtmosphericColors(culturalFog, naturalFog)
    }
    
    /// Blend atmospheric colors for environmental effects
    private static func blendAtmosphericColors(_ color1: Color, _ color2: Color) -> Color {
        // Simplified atmospheric blending for SwiftUI compatibility
        return color1.opacity(0.5) // Use first color with reduced opacity
    }
}

/// Environmental effects modifier for atmospheric immersion
struct EnvironmentalEffectsModifier: ViewModifier {
    let card: Card
    let cardDistance: CGFloat
    let focusDistance: CGFloat
    let configuration: EnvironmentalEffectsSystem.EnvironmentConfiguration
    @State private var environmentPhase: Double = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                ZStack {
                    // Atmospheric perspective overlay
                    atmosphericPerspectiveOverlay
                    
                    // Fog/haze effects
                    fogEffectsOverlay
                    
                    // Depth cueing overlay
                    depthCueingOverlay
                    
                    // Romanian cultural atmospheric elements
                    culturalAtmosphereOverlay
                }
            )
            .opacity(depthBasedOpacity)
            .blur(radius: depthOfFieldBlur)
            .onAppear {
                startEnvironmentalAnimation()
            }
    }
    
    private var atmosphericPerspectiveOverlay: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(
                EnvironmentalEffectsSystem.calculateAtmosphericPerspective(
                    at: cardDistance,
                    configuration: configuration
                )
            )
            .opacity(0.6 + sin(environmentPhase * 0.3) * 0.2)
    }
    
    private var fogEffectsOverlay: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(
                EnvironmentalEffectsSystem.generateFogEffect(
                    at: cardDistance,
                    configuration: configuration
                )
            )
            .blur(radius: 1.5)
            .opacity(0.7 + sin(environmentPhase * 0.4) * 0.25)
    }
    
    private var depthCueingOverlay: some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(
                Color.black.opacity(
                    0.1 * (1.0 - EnvironmentalEffectsSystem.calculateDepthCueing(
                        for: focusDistance,
                        cardDistance: cardDistance,
                        configuration: configuration
                    ))
                ),
                lineWidth: 1
            )
    }
    
    private var culturalAtmosphereOverlay: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(
                LinearGradient(
                    colors: [
                        Color.clear,
                        romanianAtmosphericColor.opacity(
                            0.04 * configuration.culturalAtmosphere
                        ),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .opacity(0.8 + sin(environmentPhase * 0.6) * 0.15)
    }
    
    private var romanianAtmosphericColor: Color {
        switch card.suit {
        case .hearts, .diamonds:
            return RomanianColors.embroideryRed
        case .clubs, .spades:
            return RomanianColors.primaryBlue
        }
    }
    
    private var depthBasedOpacity: Double {
        EnvironmentalEffectsSystem.calculateDepthCueing(
            for: focusDistance,
            cardDistance: cardDistance,
            configuration: configuration
        )
    }
    
    private var depthOfFieldBlur: CGFloat {
        let distanceDifference = abs(cardDistance - focusDistance)
        let maxBlur: CGFloat = 3.0
        let blurFactor = min(1.0, distanceDifference / 120.0)
        
        return blurFactor * maxBlur * CGFloat(configuration.depthOfFieldStrength)
    }
    
    private func startEnvironmentalAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            withAnimation(.linear(duration: 0.05)) {
                environmentPhase += 0.02
            }
        }
    }
}

extension View {
    /// Apply environmental effects for atmospheric depth and immersion
    func environmentalEffects(
        card: Card,
        cardDistance: CGFloat = 50.0,
        focusDistance: CGFloat = 50.0,
        configuration: EnvironmentalEffectsSystem.EnvironmentConfiguration = .standard
    ) -> some View {
        modifier(EnvironmentalEffectsModifier(
            card: card,
            cardDistance: cardDistance,
            focusDistance: focusDistance,
            configuration: configuration
        ))
    }
}

// MARK: - Coordinated Animation Sequences

/// Types of coordinated animation sequences for multi-card animations
enum CoordinatedSequenceType: String, CaseIterable {
    case romanianSevenPlay = "romanian_seven_play"
    case multiCardCapture = "multi_card_capture"
    case gameEndingCelebration = "game_ending_celebration"
    case trickCompletionAnimation = "trick_completion_animation"
    
    var duration: TimeInterval {
        switch self {
        case .romanianSevenPlay: return 2.5
        case .multiCardCapture: return 1.8
        case .gameEndingCelebration: return 4.0
        case .trickCompletionAnimation: return 1.5
        }
    }
    
    var staggerDelay: TimeInterval {
        switch self {
        case .romanianSevenPlay: return 0.3
        case .multiCardCapture: return 0.2
        case .gameEndingCelebration: return 0.15
        case .trickCompletionAnimation: return 0.1
        }
    }
}

/// Represents a coordinated sequence involving multiple cards
struct CoordinatedSequence: Identifiable {
    let id: UUID
    let type: CoordinatedSequenceType
    let cards: [Card]
    let positions: [CGPoint]
    let startTime: Date
    let completion: () -> Void
}

/// Coordinates multiple animation sequences with precise timing and momentum preservation
@MainActor
class SequenceCoordinator: ObservableObject {
    private var activeSequences: [CoordinatedSequenceType: CoordinatedSequence] = [:]
    private var sequenceEffects: [CoordinatedSequenceType: [CardEffect]] = [:]
    private var sequenceTimings: [CoordinatedSequenceType: [TimeInterval]] = [:]
    
    /// Register an effect as part of a coordinated sequence
    func registerEffect(_ effect: CardEffect, for sequence: CoordinatedSequenceType) {
        if sequenceEffects[sequence] == nil {
            sequenceEffects[sequence] = []
        }
        sequenceEffects[sequence]?.append(effect)
    }
    
    /// Start a coordinated sequence with precise timing
    func startSequence(_ sequence: CoordinatedSequence) {
        activeSequences[sequence.type] = sequence
        
        // Calculate precise timing for each card in the sequence
        let totalCards = sequence.cards.count
        let staggerDelay = sequence.type.staggerDelay
        var timings: [TimeInterval] = []
        
        for index in 0..<totalCards {
            let delay = Double(index) * staggerDelay
            timings.append(delay)
        }
        
        sequenceTimings[sequence.type] = timings
    }
    
    /// Update sequence coordination with momentum preservation
    func update(deltaTime: TimeInterval) {
        let currentTime = Date()
        
        // Update all active sequences
        for (sequenceType, sequence) in activeSequences {
            let elapsed = currentTime.timeIntervalSince(sequence.startTime)
            
            // Check if sequence is complete
            if elapsed > sequenceType.duration {
                completeSequence(sequenceType)
            } else {
                // Update sequence progress with momentum considerations
                updateSequenceProgress(sequenceType, progress: elapsed / sequenceType.duration)
            }
        }
    }
    
    /// Update progress of a specific sequence
    private func updateSequenceProgress(_ sequenceType: CoordinatedSequenceType, progress: Double) {
        guard let sequence = activeSequences[sequenceType],
              let timings = sequenceTimings[sequenceType] else { return }
        
        // Apply momentum-based timing adjustments
        for (index, timing) in timings.enumerated() {
            let cardProgress = max(0, min(1, (progress * sequenceType.duration - timing) / (sequenceType.duration - timing)))
            
            // Apply momentum curves based on sequence type
            let momentumAdjustedProgress = applyMomentumCurve(progress: cardProgress, for: sequenceType)
            
            // Update card animation state based on momentum-adjusted progress
            updateCardInSequence(
                card: sequence.cards[index], 
                progress: momentumAdjustedProgress, 
                sequenceType: sequenceType,
                cardIndex: index
            )
        }
    }
    
    /// Apply momentum-based easing curves for different sequence types
    private func applyMomentumCurve(progress: Double, for sequenceType: CoordinatedSequenceType) -> Double {
        guard progress > 0 && progress < 1 else { return progress }
        
        switch sequenceType {
        case .romanianSevenPlay:
            // Ceremonial, deliberate curve with cultural respect
            return easeInOutQuart(progress)
        case .multiCardCapture:
            // Quick, snappy curve with satisfying feedback
            return easeOutBack(progress)
        case .gameEndingCelebration:
            // Bouncy, celebratory curve with joy
            return easeOutElastic(progress)
        case .trickCompletionAnimation:
            // Smooth, professional curve
            return easeInOutCubic(progress)
        }
    }
    
    /// Update individual card animation within a sequence
    private func updateCardInSequence(
        card: Card, 
        progress: Double, 
        sequenceType: CoordinatedSequenceType,
        cardIndex: Int
    ) {
        // Implementation depends on the specific sequence type
        // This would integrate with the visual effects system
    }
    
    /// Complete a coordinated sequence
    private func completeSequence(_ sequenceType: CoordinatedSequenceType) {
        if let sequence = activeSequences[sequenceType] {
            sequence.completion()
        }
        
        activeSequences.removeValue(forKey: sequenceType)
        sequenceEffects.removeValue(forKey: sequenceType)
        sequenceTimings.removeValue(forKey: sequenceType)
    }
    
    /// Clear all active sequences
    func clearAll() {
        activeSequences.removeAll()
        sequenceEffects.removeAll()
        sequenceTimings.removeAll()
    }
    
    // MARK: - Easing Functions for Momentum Curves
    
    private func easeInOutQuart(_ x: Double) -> Double {
        return x < 0.5 ? 8 * x * x * x * x : 1 - pow(-2 * x + 2, 4) / 2
    }
    
    private func easeOutBack(_ x: Double) -> Double {
        let c1 = 1.70158
        let c3 = c1 + 1
        return 1 + c3 * pow(x - 1, 3) + c1 * pow(x - 1, 2)
    }
    
    private func easeOutElastic(_ x: Double) -> Double {
        let c4 = (2 * Double.pi) / 3
        return x == 0 ? 0 : x == 1 ? 1 : pow(2, -10 * x) * sin((x * 10 - 0.75) * c4) + 1
    }
    
    private func easeInOutCubic(_ x: Double) -> Double {
        return x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2
    }
}

// MARK: - Preview

struct CardVisualEffectsSystem_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Lighting effects preview
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .frame(width: 70, height: 100)
                .overlay(
                    CardLightingEffects(
                        card: Card(suit: .hearts, value: 7),
                        isSelected: true,
                        isSpecialCard: true,
                        lightingIntensity: .medium
                    )
                )
            
            // Motion effects preview
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .frame(width: 70, height: 100)
                .overlay(
                    CardMotionEffects(
                        card: Card(suit: .spades, value: 10),
                        motionType: .magneticPull,
                        isActive: true
                    )
                )
        }
        .padding()
        .background(Color.green.opacity(0.3))
    }
}