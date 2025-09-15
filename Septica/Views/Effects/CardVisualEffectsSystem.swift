//
//  CardVisualEffectsSystem.swift
//  Septica
//
//  Advanced visual effects and animations for premium card interactions
//  Particle systems, lighting effects, and cinematic animations
//

import SwiftUI
import UIKit

// MARK: - Card Visual Effects Manager

/// Manages advanced visual effects for cards including particles, lighting, and special animations
@MainActor
class CardVisualEffectsManager: ObservableObject {
    @Published var activeEffects: [CardEffect] = []
    @Published var isParticleSystemEnabled = true
    @Published var isAdvancedLightingEnabled = true
    @Published var effectIntensity: EffectIntensity = .medium
    
    private var effectTimer: Timer?
    
    /// Trigger a visual effect for a specific card action
    func triggerEffect(_ effectType: CardEffectType, for card: Card, at position: CGPoint = .zero) {
        let effect = CardEffect(
            id: UUID(),
            type: effectType,
            card: card,
            position: position,
            startTime: Date(),
            duration: effectType.duration,
            intensity: effectIntensity
        )
        
        activeEffects.append(effect)
        
        // Auto-cleanup effect after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + effectType.duration) {
            self.removeEffect(effect.id)
        }
    }
    
    /// Remove a specific effect
    func removeEffect(_ id: UUID) {
        activeEffects.removeAll { $0.id == id }
    }
    
    /// Clear all active effects
    func clearAllEffects() {
        activeEffects.removeAll()
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

/// Represents an active visual effect on a card
struct CardEffect: Identifiable, Equatable {
    let id: UUID
    let type: CardEffectType
    let card: Card
    let position: CGPoint
    let startTime: Date
    let duration: TimeInterval
    let intensity: EffectIntensity
    
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

// MARK: - Advanced Lighting Effects

/// Advanced lighting system for cards
struct CardLightingEffects: View {
    let card: Card
    let isSelected: Bool
    let isSpecialCard: Bool
    let lightingIntensity: EffectIntensity
    
    @State private var lightingPhase: Double = 0
    
    var body: some View {
        ZStack {
            if isSpecialCard {
                specialCardLighting
            }
            
            if isSelected {
                selectionLighting
            }
            
            // Cultural lighting for Romanian cards
            if card.value == 7 {
                romanianSevenLighting
            }
            
            if card.isPointCard {
                pointCardLighting
            }
        }
        .onAppear {
            startLightingAnimation()
        }
    }
    
    private var specialCardLighting: some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(
                LinearGradient(
                    colors: [
                        RomanianColors.goldAccent.opacity(0.8),
                        RomanianColors.goldAccent.opacity(0.4),
                        Color.clear,
                        RomanianColors.goldAccent.opacity(0.4),
                        RomanianColors.goldAccent.opacity(0.8)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 2
            )
            .scaleEffect(1.02)
            .opacity(0.8 + sin(lightingPhase) * 0.2)
    }
    
    private var selectionLighting: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(
                RadialGradient(
                    colors: [
                        Color.blue.opacity(0.3),
                        Color.blue.opacity(0.1),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 10,
                    endRadius: 50
                )
            )
            .scaleEffect(1.05)
            .opacity(0.7 + sin(lightingPhase * 1.5) * 0.3)
    }
    
    private var romanianSevenLighting: some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(
                LinearGradient(
                    colors: [
                        Color.orange.opacity(0.6),
                        Color.yellow.opacity(0.4),
                        Color.orange.opacity(0.6)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 1.5
            )
            .scaleEffect(1.01)
            .opacity(0.6 + sin(lightingPhase * 2) * 0.4)
    }
    
    private var pointCardLighting: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(
                RadialGradient(
                    colors: [
                        Color.yellow.opacity(0.2),
                        Color.yellow.opacity(0.05),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 5,
                    endRadius: 30
                )
            )
            .scaleEffect(1.03)
            .opacity(0.5 + sin(lightingPhase * 0.8) * 0.25)
    }
    
    private func startLightingAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            withAnimation(.linear(duration: 0.016)) {
                lightingPhase += 0.1
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