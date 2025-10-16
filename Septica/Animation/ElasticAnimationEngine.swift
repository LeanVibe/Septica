//
//  ElasticAnimationEngine.swift
//  Septica
//
//  Core physics engine for elastic animations
//  Provides natural spring-based movement with Romanian cultural timing
//

import SwiftUI

/// Core physics engine for elastic animations with spring dynamics
class ElasticAnimationEngine: ObservableObject {

    // MARK: - Physics Constants

    /// Spring stiffness values for different interaction types
    struct SpringConstants {
        static let cardSelection: CGFloat = 300.0      // Stiff for immediate feedback
        static let cardPlay: CGFloat = 200.0          // Medium for smooth play
        static let cardHover: CGFloat = 150.0          // Soft for hover effects
        static let victory: CGFloat = 100.0            // Very soft for celebrations
        static let emote: CGFloat = 180.0              // Medium for emotes
    }

    /// Damping ratios for different effects
    struct DampingConstants {
        static let snappy: CGFloat = 0.8               // Quick settling
        static let smooth: CGFloat = 0.7               // Smooth movement
        static let bouncy: CGFloat = 0.5               // Extra bounce
        static let gentle: CGFloat = 0.9               // Very gentle
    }

    /// Mass values for different animated objects
    struct MassConstants {
        static let playingCard: CGFloat = 1.0
        static let gameToken: CGFloat = 0.8
        static let emoteBubble: CGFloat = 0.5
        static let victoryEffect: CGFloat = 0.3
    }

    // MARK: - Private Properties

    private var activeAnimations: [String: AnimationState] = [:]
    private var animationQueue: DispatchQueue
    private let performanceTracker = AnimationPerformanceTracker()

    // MARK: - Animation State

    private struct AnimationState {
        let id: String
        let startTime: Date
        let duration: TimeInterval
        let completion: (() -> Void)?
        var isCompleted: Bool = false
    }

    // MARK: - Initialization

    init() {
        self.animationQueue = DispatchQueue(label: "com.septica.animations", qos: .userInteractive)
    }

    // MARK: - Public Interface

    /// Calculate spring animation for card selection
    func calculateCardSelectionAnimation(
        from initialScale: CGFloat = 1.0,
        to targetScale: CGFloat = 1.08,
        completion: (() -> Void)? = nil
    ) -> Animation {
        return .interpolatingSpring(
            mass: MassConstants.playingCard,
            stiffness: SpringConstants.cardSelection,
            damping: DampingConstants.snappy
        )
    }

    /// Calculate elastic animation for card play
    func calculateCardPlayAnimation(
        completion: (() -> Void)? = nil
    ) -> Animation {
        return .interpolatingSpring(
            mass: MassConstants.playingCard,
            stiffness: SpringConstants.cardPlay,
            damping: DampingConstants.smooth
        )
    }

    /// Calculate bounce animation for card interactions
    func calculateElasticBounce(
        intensity: Float,
        customDuration: TimeInterval? = nil,
        completion: (() -> Void)? = nil
    ) -> Animation {
        let duration = customDuration ?? TimeInterval(0.3 + Double(intensity) * 0.2)

        return .timingCurve(
            TimingCurve(
                controlPoints: [
                    CGPoint(x: 0, y: 0),
                    CGPoint(x: 0.2, y: 1.0),
                    CGPoint(x: 0.4, y: 0.8),
                    CGPoint(x: 1.0, y: 1.0)
                ],
                duration: duration
            )
        )
    }

    /// Calculate smooth hover animation
    func calculateCardHoverAnimation(
        isEntering: Bool,
        completion: (() -> Void)? = nil
    ) -> Animation {
        if isEntering {
            return .interpolatingSpring(
                mass: MassConstants.playingCard,
                stiffness: SpringConstants.cardHover,
                damping: DampingConstants.smooth
            )
        } else {
            return .easeOut(duration: 0.2)
        }
    }

    /// Calculate victory celebration animation
    func calculateVictoryAnimation(
        characterType: RomanianCharacterType,
        completion: (() -> Void)? = nil
    ) -> Animation {
        // Different celebration styles based on character type
        switch characterType {
        case .pacala:
            return calculateTricksterVictoryAnimation()
        case .iele:
            return calculateEtherealVictoryAnimation()
        case .strigoi:
            return calculateDramaticVictoryAnimation()
        case .fatFrumos:
            return calculateHeroicVictoryAnimation()
        case .babaCloantza:
            return calculateWiseVictoryAnimation()
        case .zmeu:
            return calculateEnergeticVictoryAnimation()
        }
    }

    /// Calculate emote animation with character-specific timing
    func calculateEmoteAnimation(
        emoteType: EmoteType,
        characterType: RomanianCharacterType,
        completion: (() -> Void)? = nil
    ) -> Animation {
        let timing = CulturalAnimationTiming.timingForEmote(
            emoteType: emoteType,
            characterType: characterType
        )

        return .interpolatingSpring(
            mass: MassConstants.emoteBubble,
            stiffness: SpringConstants.emote,
            damping: DampingConstants.smooth
        )
    }

    /// Create custom easing curve from control points
    func customEasingCurve(
        controlPoints: [CGPoint],
        duration: TimeInterval = 1.0
    ) -> Animation {
        return .timingCurve(
            TimingCurve(controlPoints: controlPoints, duration: duration)
        )
    }

    /// Chain multiple animations sequentially
    func chainAnimations(
        animations: [() -> Animation],
        completion: (() -> Void)? = nil
    ) -> Animation {
        return .sequential(
            with: animations,
            completion: completion
        )
    }

    /// Create parallel animations for multiple properties
    func parallelAnimations(
        animations: [Animation]
    ) -> Animation {
        return .parallel(animations)
    }

    // MARK: - Character-Specific Victory Animations

    private func calculateTricksterVictoryAnimation() -> Animation {
        // Păcală's victory: playful, bouncy
        return .keyframes(
            with: [
                AnimationKeyframe(0.0, transform: .identity),
                AnimationKeyframe(0.3, transform: .scale(1.2).rotation(.degrees(10))),
                AnimationKeyframe(0.6, transform: .scale(0.9).rotation(.degrees(-5))),
                AnimationKeyframe(1.0, transform: .identity)
            ]
        )
    }

    private func calculateEtherealVictoryAnimation() -> Animation {
        // Iele's victory: graceful, flowing
        return .keyframes(
            with: [
                AnimationKeyframe(0.0, transform: .identity, opacity: 1.0),
                AnimationKeyframe(0.4, transform: .scale(1.1), opacity: 0.8),
                AnimationKeyframe(0.8, transform: .scale(1.15), opacity: 1.0),
                AnimationKeyframe(1.0, transform: .identity, opacity: 1.0)
            ]
        )
    }

    private func calculateDramaticVictoryAnimation() -> Animation {
        // Strigoi's victory: dramatic, intense
        return .keyframes(
            with: [
                AnimationKeyframe(0.0, transform: .identity),
                AnimationKeyframe(0.2, transform: .scale(0.8).rotation(.degrees(-15))),
                AnimationKeyframe(0.5, transform: .scale(1.3).rotation(.degrees(15))),
                AnimationKeyframe(1.0, transform: .identity)
            ]
        )
    }

    private func calculateHeroicVictoryAnimation() -> Animation {
        // Făt-Frumos's victory: proud, upright
        return .keyframes(
            with: [
                AnimationKeyframe(0.0, transform: .identity),
                AnimationKeyframe(0.3, transform: .scale(1.15)),
                AnimationKeyframe(0.6, transform: .scale(1.25).rotation(.degrees(5))),
                AnimationKeyframe(1.0, transform: .identity)
            ]
        )
    }

    private func calculateWiseVictoryAnimation() -> Animation {
        // Baba Cloanța's victory: subtle, knowing
        return .keyframes(
            with: [
                AnimationKeyframe(0.0, transform: .identity),
                AnimationKeyframe(0.5, transform: .scale(1.05)),
                AnimationKeyframe(1.0, transform: .identity)
            ]
        )
    }

    private func calculateEnergeticVictoryAnimation() -> Animation {
        // Zmeu's victory: explosive, energetic
        return .keyframes(
            with: [
                AnimationKeyframe(0.0, transform: .identity),
                AnimationKeyframe(0.15, transform: .scale(0.7)),
                AnimationKeyframe(0.4, transform: .scale(1.4).rotation(.degrees(20))),
                AnimationKeyframe(0.7, transform: .scale(1.2).rotation(.degrees(-10))),
                AnimationKeyframe(1.0, transform: .identity)
            ]
        )
    }

    // MARK: - Performance Optimization

    /// Track animation performance metrics
    func trackAnimationPerformance(
        animationId: String,
        duration: TimeInterval,
        complexity: AnimationComplexity
    ) {
        performanceTracker.recordAnimation(
            id: animationId,
            duration: duration,
            complexity: complexity
        )
    }

    /// Get performance statistics
    func getPerformanceStatistics() -> AnimationPerformanceStats {
        return performanceTracker.getStatistics()
    }

    /// Optimize animation parameters for current device
    func optimizeForDevice() {
        let deviceCapabilities = DeviceCapabilityDetector.detectCurrentDevice()

        // Adjust animation parameters based on device performance
        if deviceCapabilities.isHighEnd {
            // Use full quality animations
        } else if deviceCapabilities.isMidRange {
            // Reduce animation complexity slightly
        } else {
            // Use optimized animations for low-end devices
        }
    }
}

// MARK: - Supporting Types

/// Animation complexity levels for performance tracking
enum AnimationComplexity {
    case simple      // Basic transforms
    case moderate    // Keyframe animations
    case complex     // Multiple chained animations
    case heavy       // Physics simulations
}

/// Device capability detection for animation optimization
struct DeviceCapabilityDetector {
    static func detectCurrentDevice() -> DeviceCapabilities {
        // This would detect actual device capabilities
        // For now, return high-end as default
        return DeviceCapabilities(
            isHighEnd: true,
            isMidRange: false,
            isLowEnd: false,
            maxConcurrentAnimations: 20,
            preferredFrameRate: 60
        )
    }
}

struct DeviceCapabilities {
    let isHighEnd: Bool
    let isMidRange: Bool
    let isLowEnd: Bool
    let maxConcurrentAnimations: Int
    let preferredFrameRate: Int
}

/// Animation performance tracking
class AnimationPerformanceTracker {
    private var animationRecords: [AnimationRecord] = []

    func recordAnimation(id: String, duration: TimeInterval, complexity: AnimationComplexity) {
        let record = AnimationRecord(
            id: id,
            timestamp: Date(),
            duration: duration,
            complexity: complexity
        )
        animationRecords.append(record)

        // Keep only recent records
        if animationRecords.count > 1000 {
            animationRecords.removeFirst(500)
        }
    }

    func getStatistics() -> AnimationPerformanceStats {
        let recentRecords = animationRecords.suffix(100)

        let averageDuration = recentRecords.isEmpty ? 0 :
            recentRecords.reduce(0) { $0 + $1.duration } / Double(recentRecords.count)

        let complexityDistribution = Dictionary(grouping: recentRecords) { $0.complexity }
            .mapValues { $0.count }

        return AnimationPerformanceStats(
            averageAnimationDuration: averageDuration,
            totalAnimations: recentRecords.count,
            complexityDistribution: complexityDistribution
        )
    }
}

struct AnimationRecord {
    let id: String
    let timestamp: Date
    let duration: TimeInterval
    let complexity: AnimationComplexity
}

struct AnimationPerformanceStats {
    let averageAnimationDuration: TimeInterval
    let totalAnimations: Int
    let complexityDistribution: [AnimationComplexity: Int]
}

// MARK: - SwiftUI Extensions

extension Animation {
    /// Create sequential animation chain
    static func sequential(
        with animations: [() -> Animation],
        completion: (() -> Void)? = nil
    ) -> Animation {
        // This would implement animation sequencing
        // For now, return a combined animation
        return .parallel(animations.map { $0() })
    }
}

/// Custom timing curve for complex animations
struct TimingCurve {
    let controlPoints: [CGPoint]
    let duration: TimeInterval

    init(controlPoints: [CGPoint], duration: TimeInterval = 1.0) {
        self.controlPoints = controlPoints
        self.duration = duration
    }
}

/// Animation keyframe for complex animations
struct AnimationKeyframe {
    let time: Double
    let transform: Transform3DEffect
    let opacity: Double?
    let scale: Double?
    let rotation: Angle?

    init(
        _ time: Double,
        transform: Transform3DEffect = .identity,
        opacity: Double? = nil,
        scale: Double? = nil,
        rotation: Angle? = nil
    ) {
        self.time = time
        self.transform = transform
        self.opacity = opacity
        self.scale = scale
        self.rotation = rotation
    }
}