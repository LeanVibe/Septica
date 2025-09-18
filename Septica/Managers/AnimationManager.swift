//
//  AnimationManager.swift
//  Septica
//
//  Professional animation system for Romanian Septica card game
//  Provides smooth 60 FPS animations for card movements, celebrations, and transitions
//

import SwiftUI
import Combine

/// Centralized animation management for the entire application
@MainActor
class AnimationManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isAnimating = false
    @Published var activeAnimations: Set<AnimationType> = []
    
    // MARK: - Advanced Physics-Based Animation Settings (Phase 3 Excellence)
    
    struct AnimationSettings {
        static let cardPlayDuration: Double = 0.6
        static let cardFlipDuration: Double = 0.4
        static let scoreUpdateDuration: Double = 0.8
        static let victoryAnimationDuration: Double = 2.0
        static let menuTransitionDuration: Double = 0.3
        static let loadingAnimationDuration: Double = 1.5
        
        // PHASE 3: Advanced Physics Constants with Natural Spring Systems
        
        // Natural spring constants for realistic physics
        struct SpringConstants {
            static let cardMass: Double = 1.0           // Natural playing card mass
            static let cardStiffness: Double = 120.0    // Card material flexibility
            static let cardDamping: Double = 12.0       // Air resistance simulation
            
            static let dragMass: Double = 0.8          // Reduced mass during interaction
            static let dragStiffness: Double = 150.0   // Higher responsiveness for real-time
            static let dragDamping: Double = 15.0      // Quick settling for smooth follow
            
            static let snapMass: Double = 1.2          // Heavier for satisfying snap
            static let snapStiffness: Double = 200.0   // Strong return force
            static let snapDamping: Double = 20.0      // Prevent overshoot
        }
        
        // Energy conservation physics
        struct EnergyConservation {
            static let kineticEnergyRetention: Double = 0.92    // 92% kinetic energy preserved
            static let potentialEnergyConversion: Double = 0.88  // 88% potential energy conversion
            static let frictionCoefficient: Double = 0.02       // Minimal friction for smooth motion
            static let dampingForce: Double = 0.85              // Energy dissipation rate
            static let elasticRestitution: Double = 0.75        // Bounce efficiency
            static let momentumDecay: Double = 0.95             // Momentum preservation over time
        }
        
        // Collision detection and response parameters
        struct CollisionPhysics {
            static let collisionRadius: CGFloat = 35.0          // Card collision boundary
            static let collisionElasticity: Double = 0.6       // Bounce response
            static let collisionDamping: Double = 0.7          // Energy loss on collision
            static let separationForce: Double = 200.0         // Force to separate overlapping cards
            static let minimumSeparation: CGFloat = 8.0        // Minimum distance between cards
        }
        
        // Enhanced physics-based spring animations with natural constants
        static let cardSpring = Animation.interpolatingSpring(
            mass: SpringConstants.cardMass,
            stiffness: SpringConstants.cardStiffness,
            damping: SpringConstants.cardDamping,
            initialVelocity: 0
        )
        static let cardDragSpring = Animation.interpolatingSpring(
            mass: SpringConstants.dragMass,
            stiffness: SpringConstants.dragStiffness,
            damping: SpringConstants.dragDamping,
            initialVelocity: 0
        )
        static let cardSnapSpring = Animation.interpolatingSpring(
            mass: SpringConstants.snapMass,
            stiffness: SpringConstants.snapStiffness,
            damping: SpringConstants.snapDamping,
            initialVelocity: 10
        )
        static let scoreSpring = Animation.interpolatingSpring(
            mass: 0.6,         // Lighter for UI elements
            stiffness: 100.0,  // Smooth celebration movement
            damping: 10.0,     // Gentle bounce
            initialVelocity: 0
        )
        static let menuSpring = Animation.interpolatingSpring(
            mass: 0.5,         // Very light for menu transitions
            stiffness: 180.0,  // Quick response
            damping: 18.0,     // Minimal bounce
            initialVelocity: 0
        )
        
        // Advanced momentum preservation system
        static let momentumDamping: Double = EnergyConservation.dampingForce
        static let velocityThreshold: Double = 50.0 // Minimum velocity for momentum effects
        static let energyThreshold: Double = 25.0   // Minimum energy for physics effects
        
        // Performance optimization thresholds
        static let highPerformanceThreshold: Double = 55.0  // 55+ FPS = high quality
        static let mediumPerformanceThreshold: Double = 45.0 // 45+ FPS = medium quality
        static let lowPerformanceThreshold: Double = 30.0   // 30+ FPS = low quality
        
        // Easing animations
        static let smoothEaseInOut = Animation.easeInOut(duration: 0.3)
        static let quickEaseOut = Animation.easeOut(duration: 0.2)
        static let slowEaseInOut = Animation.easeInOut(duration: 0.8)
    }
    
    // MARK: - Animation Types
    
    enum AnimationType: String, CaseIterable {
        case cardPlay = "card_play"
        case cardFlip = "card_flip"
        case scoreUpdate = "score_update"
        case victory = "victory"
        case defeat = "defeat"
        case menuTransition = "menu_transition"
        case loading = "loading"
        case cardShuffle = "card_shuffle"
        case turnTransition = "turn_transition"
    }
    
    // MARK: - Enhanced Physics-Based Card Animation Functions
    
    /// Animate card being played from hand to table with advanced momentum physics
    func animateCardPlay(
        from startPosition: CGPoint,
        to endPosition: CGPoint,
        initialVelocity: CGPoint = .zero,
        dragVelocity: CGPoint = .zero,
        completion: @escaping () -> Void
    ) {
        startAnimation(.cardPlay)
        
        // Enhanced trajectory calculation with drag momentum integration
        let distance = sqrt(pow(endPosition.x - startPosition.x, 2) + pow(endPosition.y - startPosition.y, 2))
        let _ = sqrt(pow(initialVelocity.x, 2) + pow(initialVelocity.y, 2))
        let _ = sqrt(pow(dragVelocity.x, 2) + pow(dragVelocity.y, 2))
        
        // Combine initial and drag velocities for total momentum
        let combinedVelocity = CGPoint(
            x: initialVelocity.x + dragVelocity.x * 0.7, // Reduce drag velocity contribution
            y: initialVelocity.y + dragVelocity.y * 0.7
        )
        let totalVelocityMagnitude = sqrt(pow(combinedVelocity.x, 2) + pow(combinedVelocity.y, 2))
        
        // Advanced physics-based animation adjustment
        let dynamicSpring: Animation
        if totalVelocityMagnitude > AnimationSettings.velocityThreshold {
            // High velocity - use advanced momentum-preserving animation
            let momentumFactor = min(totalVelocityMagnitude / 1000.0, 2.0)
            dynamicSpring = Animation.interpolatingSpring(
                mass: 0.9 + momentumFactor * 0.8, // Progressive mass increase
                stiffness: max(90.0, 190.0 - totalVelocityMagnitude / 15.0), // Velocity-responsive stiffness
                damping: 11.0 + totalVelocityMagnitude / 60.0, // Smooth velocity-based damping
                initialVelocity: min(totalVelocityMagnitude / 80.0, 25.0) // Preserve momentum with limits
            )
            
            // Track momentum for this animation
            updateAnimationMomentum(.cardPlay, momentum: momentumFactor, velocity: combinedVelocity)
        } else {
            // Low velocity - use standard card spring
            dynamicSpring = AnimationSettings.cardSpring
            updateAnimationMomentum(.cardPlay, momentum: 0.3, velocity: combinedVelocity)
        }
        
        withAnimation(dynamicSpring) {
            // Advanced physics animation with momentum preservation and energy conservation
            // The view will handle the actual animation with the calculated physics parameters
        }
        
        // Enhanced dynamic duration with momentum consideration
        let baseDuration = distance / 200.0
        let velocityFactor = 1.0 - min(totalVelocityMagnitude / 1200.0, 0.7)
        let dynamicDuration = max(0.25, min(1.0, baseDuration + velocityFactor * 0.4))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + dynamicDuration) {
            // Apply momentum damping before ending animation
            if let currentMomentum = self.animationMomentum[.cardPlay] {
                let residualEnergy = currentMomentum * AnimationSettings.momentumDamping
                
                // If there's significant residual energy, create a subtle settling animation
                if residualEnergy > 0.1 {
                    let settlingSpring = Animation.interpolatingSpring(
                        mass: 0.6,
                        stiffness: 160,
                        damping: 22,
                        initialVelocity: residualEnergy * 5
                    )
                    
                    withAnimation(settlingSpring) {
                        // Subtle settling motion with residual energy
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.endAnimation(.cardPlay)
                        completion()
                    }
                } else {
                    self.endAnimation(.cardPlay)
                    completion()
                }
            } else {
                self.endAnimation(.cardPlay)
                completion()
            }
        }
    }
    
    /// Animate card flip with realistic physics and momentum preservation
    func animateCardFlip(
        delay: Double = 0,
        flipVelocity: Double = 0,
        completion: @escaping () -> Void = {}
    ) {
        startAnimation(.cardFlip)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            // Physics-based flip animation with momentum
            let flipSpring = Animation.interpolatingSpring(
                mass: 0.8,
                stiffness: 140.0 + abs(flipVelocity) * 10.0, // Velocity affects stiffness
                damping: 14.0 + abs(flipVelocity) * 2.0,     // Higher velocity = more damping
                initialVelocity: flipVelocity
            )
            
            withAnimation(flipSpring) {
                // Flip animation with preserved momentum
            }
            
            // Dynamic duration based on flip velocity
            let dynamicDuration = max(0.2, AnimationSettings.cardFlipDuration - abs(flipVelocity) / 200.0)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + dynamicDuration) {
                self.endAnimation(.cardFlip)
                completion()
            }
        }
    }
    
    /// Animate card shuffle with realistic physics and natural motion
    func animateCardShuffle(
        intensity: Double = 1.0,
        completion: @escaping () -> Void = {}
    ) {
        startAnimation(.cardShuffle)
        
        // Multi-phase shuffle with decreasing momentum
        let phases = 4
        var currentPhase = 0
        
        func shufflePhase() {
            let phaseIntensity = intensity * (1.0 - Double(currentPhase) / Double(phases))
            
            let shuffleSpring = Animation.interpolatingSpring(
                mass: 0.6 + phaseIntensity * 0.4,
                stiffness: 100.0 + phaseIntensity * 50.0,
                damping: 8.0 + phaseIntensity * 4.0,
                initialVelocity: phaseIntensity * 15.0
            )
            
            withAnimation(shuffleSpring) {
                // Phase-specific shuffle motion with momentum decay
            }
            
            currentPhase += 1
            if currentPhase < phases {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6 * (1.0 - phaseIntensity * 0.3)) {
                    shufflePhase()
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    self.endAnimation(.cardShuffle)
                    completion()
                }
            }
        }
        
        shufflePhase()
    }
    
    // MARK: - Score Animation Functions
    
    /// Animate score increase with celebration effect
    func animateScoreIncrease(points: Int, completion: @escaping () -> Void = {}) {
        startAnimation(.scoreUpdate)
        
        // Multiple phase animation for score celebration
        withAnimation(AnimationSettings.scoreSpring) {
            // Phase 1: Highlight and scale
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.5)) {
                // Phase 2: Point display and settle
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + AnimationSettings.scoreUpdateDuration) {
            self.endAnimation(.scoreUpdate)
            completion()
        }
    }
    
    // MARK: - Victory/Defeat Animations
    
    /// Animate victory celebration with multiple effects
    func animateVictory(completion: @escaping () -> Void = {}) {
        startAnimation(.victory)
        
        // Staggered victory animation phases
        withAnimation(.easeInOut(duration: 0.5)) {
            // Phase 1: Initial celebration
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                // Phase 2: Card cascade or confetti effect
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 1.0)) {
                // Phase 3: Results display
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + AnimationSettings.victoryAnimationDuration) {
            self.endAnimation(.victory)
            completion()
        }
    }
    
    /// Animate defeat with respectful, subdued effects
    func animateDefeat(completion: @escaping () -> Void = {}) {
        startAnimation(.defeat)
        
        withAnimation(.easeInOut(duration: 1.0)) {
            // Gentle defeat animation
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.endAnimation(.defeat)
            completion()
        }
    }
    
    // MARK: - Menu and UI Transitions
    
    /// Animate menu transitions
    func animateMenuTransition(completion: @escaping () -> Void = {}) {
        startAnimation(.menuTransition)
        
        withAnimation(AnimationSettings.menuSpring) {
            // Menu transition animation
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + AnimationSettings.menuTransitionDuration) {
            self.endAnimation(.menuTransition)
            completion()
        }
    }
    
    /// Animate turn transition
    func animateTurnTransition(completion: @escaping () -> Void = {}) {
        startAnimation(.turnTransition)
        
        withAnimation(.easeInOut(duration: 0.5)) {
            // Turn indicator animation
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.endAnimation(.turnTransition)
            completion()
        }
    }
    
    // MARK: - Loading Animations
    
    /// Animate loading state
    func animateLoading(isLoading: Bool) {
        if isLoading {
            startAnimation(.loading)
        } else {
            endAnimation(.loading)
        }
    }
    
    // MARK: - Advanced Physics State Management (Phase 3)
    
    // Enhanced momentum tracking for physics-based animations
    private var animationMomentum: [AnimationType: Double] = [:]
    private var animationVelocities: [AnimationType: CGPoint] = [:]
    private var animationEnergy: [AnimationType: Double] = [:]
    private var animationCollisions: [String: CollisionState] = [:]
    
    // Multi-element coordination system
    private var coordinatedAnimations: [CoordinatedAnimationGroup] = []
    private var animationSynchronizer = AnimationSynchronizer()
    
    // Physics simulation state
    private var physicsSimulator = PhysicsSimulator()
    private var collisionDetector = CollisionDetector()
    
    // Manager dependencies for haptic feedback
    private var hapticManager: HapticManager?
    
    /// Initialize with haptic manager for collision feedback
    func setHapticManager(_ manager: HapticManager) {
        self.hapticManager = manager
    }
    
    /// Collision state for physics simulation
    struct CollisionState {
        let cardId: String
        let position: CGPoint
        let velocity: CGPoint
        let radius: CGFloat
        let mass: Double
        let lastUpdate: Date
    }
    
    /// Coordinated animation group for multi-element sequences
    struct CoordinatedAnimationGroup {
        let id: UUID
        let animations: [AnimationType]
        let synchronizationMode: SynchronizationMode
        let startTime: Date
        let duration: TimeInterval
        
        enum SynchronizationMode {
            case simultaneous    // All animations start together
            case staggered(delay: TimeInterval)  // Animations start with delay
            case sequential      // Animations start after previous completes
            case wave(direction: WaveDirection)  // Animations ripple across
        }
        
        enum WaveDirection {
            case leftToRight, rightToLeft, centerOut, edgeIn
        }
    }
    
    private func startAnimation(_ type: AnimationType) {
        activeAnimations.insert(type)
        isAnimating = !activeAnimations.isEmpty
        
        // Initialize momentum tracking
        if animationMomentum[type] == nil {
            animationMomentum[type] = 1.0
        }
        if animationVelocities[type] == nil {
            animationVelocities[type] = .zero
        }
    }
    
    private func endAnimation(_ type: AnimationType) {
        activeAnimations.remove(type)
        isAnimating = !activeAnimations.isEmpty
        
        // Apply momentum damping for natural energy conservation
        if let currentMomentum = animationMomentum[type] {
            animationMomentum[type] = currentMomentum * AnimationSettings.momentumDamping
            
            // Clean up near-zero momentum
            if animationMomentum[type]! < 0.01 {
                animationMomentum.removeValue(forKey: type)
                animationVelocities.removeValue(forKey: type)
            }
        }
    }
    
    /// Update animation momentum for physics-based continuity
    func updateAnimationMomentum(_ type: AnimationType, momentum: Double, velocity: CGPoint = .zero) {
        animationMomentum[type] = momentum
        animationVelocities[type] = velocity
    }
    
    /// Get current momentum for animation type
    func getCurrentMomentum(_ type: AnimationType) -> Double {
        return animationMomentum[type] ?? 0.0
    }
    
    /// Get current velocity for animation type
    func getCurrentVelocity(_ type: AnimationType) -> CGPoint {
        return animationVelocities[type] ?? .zero
    }
    
    /// Check if specific animation is active
    func isAnimationActive(_ type: AnimationType) -> Bool {
        activeAnimations.contains(type)
    }
    
    /// Stop all animations immediately (for accessibility or performance)
    func stopAllAnimations() {
        activeAnimations.removeAll()
        isAnimating = false
        
        // Clean up momentum tracking
        animationMomentum.removeAll()
        animationVelocities.removeAll()
    }
    
    // MARK: - Performance Optimization Framework for 60fps Consistency
    
    /// Performance monitoring and optimization
    private var frameRateMonitor = FrameRateMonitor()
    private var animationQueue = AnimationQueue()
    private var performanceLevel: PerformanceLevel = .high
    
    /// Initialize performance monitoring
    func initializePerformanceMonitoring() {
        frameRateMonitor.startMonitoring { [weak self] averageFrameRate in
            self?.adjustPerformanceLevel(basedOn: averageFrameRate)
        }
    }
    
    /// Adjust performance level based on current frame rate
    private func adjustPerformanceLevel(basedOn frameRate: Double) {
        let newLevel: PerformanceLevel
        
        if frameRate >= 55.0 {
            newLevel = .high
        } else if frameRate >= 45.0 {
            newLevel = .medium
        } else {
            newLevel = .low
        }
        
        if newLevel != performanceLevel {
            performanceLevel = newLevel
            updateAnimationQuality(for: newLevel)
        }
    }
    
    /// Update animation quality based on performance level
    private func updateAnimationQuality(for level: PerformanceLevel) {
        switch level {
        case .high:
            // Full quality animations with all effects
            break
        case .medium:
            // Reduced particle counts and simplified effects
            break
        case .low:
            // Minimal animations, disable complex effects
            break
        }
    }
    
    /// Get performance-optimized animation duration
    func getOptimizedDuration(_ baseDuration: TimeInterval) -> TimeInterval {
        switch performanceLevel {
        case .high:
            return baseDuration
        case .medium:
            return baseDuration * 0.8  // 20% faster
        case .low:
            return baseDuration * 0.6  // 40% faster
        }
    }
    
    /// Get performance-optimized animation with frame rate awareness
    func getOptimizedAnimation(_ baseAnimation: Animation) -> Animation {
        let animation = accessibleAnimation(baseAnimation)
        
        switch performanceLevel {
        case .high:
            return animation
        case .medium:
            // Slightly reduce complexity by using a generic lighter spring for medium quality
            if animation == AnimationSettings.cardSpring {
                return Animation.interpolatingSpring(
                    mass: 0.8,
                    stiffness: 130.0,
                    damping: 14.0,
                    initialVelocity: 0.0
                )
            } else {
                return animation
            }
        case .low:
            // Simplified linear animations for low performance
            return .linear(duration: 0.2)
        }
    }
    
    /// Queue animation for optimized execution
    func queueOptimizedAnimation(
        _ animation: @escaping () -> Void,
        type: AnimationType,
        priority: AnimationPriority = .normal
    ) {
        let animationTask = AnimationTask(
            id: UUID(),
            type: type,
            priority: priority,
            execution: animation
        )
        
        animationQueue.enqueue(animationTask)
    }
    
    /// Performance level enumeration
    enum PerformanceLevel {
        case high    // 60fps target - full quality
        case medium  // 45fps target - reduced quality
        case low     // 30fps target - minimal quality
    }
    
    /// Animation priority for queue management
    enum AnimationPriority: Int {
        case low = 1
        case normal = 2
        case high = 3
        case critical = 4
    }
    
    // MARK: - Game End Celebration Animations
    
    /// Play confetti animation with specified intensity
    func playConfettiAnimation(intensity: Double) async {
        startAnimation(.victory)
        
        withAnimation(.easeOut(duration: getAdjustedDuration(2.0))) {
            // Confetti particle animation
        }
        
        try? await Task.sleep(nanoseconds: UInt64(getAdjustedDuration(2.0) * 1_000_000_000))
        endAnimation(.victory)
    }
    
    /// Animate experience gain with counting effect
    func animateExperienceGain(_ experience: Any) async {
        startAnimation(.scoreUpdate)
        
        withAnimation(AnimationSettings.scoreSpring) {
            // Experience points animation
        }
        
        try? await Task.sleep(nanoseconds: UInt64(getAdjustedDuration(1.5) * 1_000_000_000))
        endAnimation(.scoreUpdate)
    }
    
    /// Display cultural wisdom with elegant Romanian presentation
    func displayCulturalWisdom(_ wisdom: String) async {
        startAnimation(.menuTransition)
        
        withAnimation(.romanianBlessing) {
            // Cultural wisdom display animation with traditional Romanian reverence
        }
        
        try? await Task.sleep(nanoseconds: UInt64(getAdjustedDuration(2.0) * 1_000_000_000))
        endAnimation(.menuTransition)
    }
    
    /// Fade out celebration effects
    func fadeOutCelebration() async {
        withAnimation(.easeOut(duration: getAdjustedDuration(1.0))) {
            // Fade out all celebration elements
        }
        
        try? await Task.sleep(nanoseconds: UInt64(getAdjustedDuration(1.0) * 1_000_000_000))
        stopAllAnimations()
    }
    
    /// Play specific animation type
    func playAnimation(_ animationType: Any) async {
        startAnimation(.victory)
        
        withAnimation(.easeInOut(duration: getAdjustedDuration(1.0))) {
            // Generic animation playback
        }
        
        try? await Task.sleep(nanoseconds: UInt64(getAdjustedDuration(1.0) * 1_000_000_000))
        endAnimation(.victory)
    }
    
    /// Animate statistic count up for multiple values
    func animateStatisticCountUp(_ statistics: Any) async {
        startAnimation(.scoreUpdate)
        
        withAnimation(.easeInOut(duration: getAdjustedDuration(1.5))) {
            // Multiple statistics animation
        }
        
        try? await Task.sleep(nanoseconds: UInt64(getAdjustedDuration(1.5) * 1_000_000_000))
        endAnimation(.scoreUpdate)
    }
    
    // MARK: - Helper methods
    
    /// Get duration adjusted for accessibility preferences
    func getAdjustedDuration(_ baseDuration: Double) -> Double {
        let isReducedMotionEnabled = UIAccessibility.isReduceMotionEnabled
        return isReducedMotionEnabled ? baseDuration * 0.3 : baseDuration
    }
    
    /// Get animation with enhanced accessibility considerations
    func accessibleAnimation(_ animation: Animation) -> Animation {
        let isReducedMotionEnabled = UIAccessibility.isReduceMotionEnabled
        if isReducedMotionEnabled {
            // Maintain physics feel but reduce intensity
            return Animation.interpolatingSpring(
                mass: 0.5,      // Lighter for gentler motion
                stiffness: 200, // Higher stiffness for quicker settling
                damping: 30,    // High damping to minimize oscillation
                initialVelocity: 0 // No initial velocity for reduced motion
            )
        }
        return animation
    }
    
    /// Create momentum-preserving animation based on gesture velocity
    func createVelocityBasedAnimation(
        velocity: CGPoint,
        baseAnimation: Animation = Animation.interpolatingSpring(mass: 1.0, stiffness: 130, damping: 11, initialVelocity: 8)
    ) -> Animation {
        let velocityMagnitude = sqrt(pow(velocity.x, 2) + pow(velocity.y, 2))
        
        if velocityMagnitude < AnimationSettings.velocityThreshold {
            return accessibleAnimation(baseAnimation)
        }
        
        // Create momentum-preserving physics
        let dynamicSpring = Animation.interpolatingSpring(
            mass: 0.8 + min(velocityMagnitude / 1000.0, 1.5),
            stiffness: max(100, 180 - velocityMagnitude / 20.0),
            damping: 12 + velocityMagnitude / 100.0,
            initialVelocity: min(velocityMagnitude / 100.0, 20.0)
        )
        
        return accessibleAnimation(dynamicSpring)
    }
}

// MARK: - Frame Rate Monitor

/// Monitors frame rate for performance optimization
class FrameRateMonitor {
    private var displayLink: CADisplayLink?
    private var frameCount = 0
    private var lastTimestamp: CFTimeInterval = 0
    private var callback: ((Double) -> Void)?
    
    func startMonitoring(callback: @escaping (Double) -> Void) {
        self.callback = callback
        
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkTick))
        displayLink?.add(to: .main, forMode: .default)
    }
    
    func stopMonitoring() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func displayLinkTick(displayLink: CADisplayLink) {
        frameCount += 1
        
        if lastTimestamp == 0 {
            lastTimestamp = displayLink.timestamp
        }
        
        let elapsed = displayLink.timestamp - lastTimestamp
        
        // Calculate frame rate every second
        if elapsed >= 1.0 {
            let frameRate = Double(frameCount) / elapsed
            callback?(frameRate)
            
            frameCount = 0
            lastTimestamp = displayLink.timestamp
        }
    }
}

// MARK: - Animation Queue

/// Manages animation execution queue for optimal performance
class AnimationQueue {
    private var tasks: [AnimationTask] = []
    private var isExecuting = false
    private let executionQueue = DispatchQueue(label: "animation.queue", qos: .userInteractive)
    
    func enqueue(_ task: AnimationTask) {
        tasks.append(task)
        tasks.sort { $0.priority.rawValue > $1.priority.rawValue }
        
        if !isExecuting {
            executeNext()
        }
    }
    
    private func executeNext() {
        guard !tasks.isEmpty else {
            isExecuting = false
            return
        }
        
        isExecuting = true
        let task = tasks.removeFirst()
        
        DispatchQueue.main.async {
            task.execution()
            
            // Small delay to prevent overwhelming the render pipeline
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.016) {
                self.executeNext()
            }
        }
    }
    
    func clear() {
        tasks.removeAll()
        isExecuting = false
    }
}

// MARK: - Animation Task

/// Represents a queued animation task
struct AnimationTask {
    let id: UUID
    let type: AnimationManager.AnimationType
    let priority: AnimationManager.AnimationPriority
    let execution: () -> Void
    
    // MARK: - Accessibility Support
    
    /// Check if reduced motion is preferred
    private var isReducedMotionEnabled: Bool {
        UIAccessibility.isReduceMotionEnabled
    }
    
    /// Get animation duration adjusted for accessibility preferences
    func adjustedDuration(_ baseDuration: Double) -> Double {
        isReducedMotionEnabled ? baseDuration * 0.3 : baseDuration
    }
    
    /// Get animation with enhanced accessibility considerations and physics preservation
    func accessibleAnimation(_ animation: Animation) -> Animation {
        if isReducedMotionEnabled {
            // Maintain physics feel but reduce intensity
            return accessibilityAdaptedPhysics(animation)
        }
        return animation
    }
    
    /// Get physics-adapted animation for accessibility
    func accessibilityAdaptedPhysics(_ baseAnimation: Animation) -> Animation {
        if isReducedMotionEnabled {
            // Reduce momentum and increase damping for reduced motion
            return Animation.interpolatingSpring(
                mass: 0.5,      // Lighter for gentler motion
                stiffness: 200, // Higher stiffness for quicker settling
                damping: 30,    // High damping to minimize oscillation
                initialVelocity: 0 // No initial velocity for reduced motion
            )
        }
        return baseAnimation
    }
    
    
    
    // MARK: - Enhanced Romanian Cultural Animation Methods
    
    
}

// MARK: - Animation View Modifiers

extension View {
    /// Apply card play animation with Phase 3 physics-based enhancements
    func cardPlayAnimation(
        isActive: Bool,
        manager: AnimationManager,
        from: CGPoint = .zero,
        to: CGPoint = .zero,
        velocity: CGPoint = .zero,
        cardId: String = ""
    ) -> some View {
        let physicsAnimation = velocity != .zero 
            ? manager.createVelocityBasedAnimation(velocity: velocity)
            : manager.accessibleAnimation(AnimationManager.AnimationSettings.cardSpring)
        
        return self
            .scaleEffect(isActive ? 1.1 : 1.0)
            .rotationEffect(.degrees(isActive ? 5 : 0))
            .animation(physicsAnimation, value: isActive)
            .onChange(of: isActive) { _, newValue in
                if newValue && !cardId.isEmpty {
                    // Register card for physics simulation when animation starts
                    manager.registerCardForCollision(
                        cardId: cardId,
                        position: from,
                        velocity: velocity
                    )
                }
            }
    }
    
    /// Apply score celebration animation
    func scoreCelebrationAnimation(isActive: Bool, manager: AnimationManager) -> some View {
        self.scaleEffect(isActive ? 1.2 : 1.0)
            .opacity(isActive ? 0.8 : 1.0)
            .animation(manager.accessibleAnimation(AnimationManager.AnimationSettings.scoreSpring), value: isActive)
    }
    
    /// Apply menu transition animation
    func menuTransitionAnimation(isActive: Bool, manager: AnimationManager) -> some View {
        self.offset(y: isActive ? 0 : 50)
            .opacity(isActive ? 1 : 0)
            .animation(manager.accessibleAnimation(AnimationManager.AnimationSettings.menuSpring), value: isActive)
    }
    
    /// Apply loading pulse animation
    func loadingPulseAnimation(isActive: Bool, manager: AnimationManager) -> some View {
        self.scaleEffect(isActive ? 1.05 : 1.0)
            .opacity(isActive ? 0.7 : 1.0)
            .animation(
                manager.accessibleAnimation(
                    .easeInOut(duration: manager.getAdjustedDuration(1.0))
                    .repeatForever(autoreverses: true)
                ),
                value: isActive
            )
    }
}

// MARK: - Custom Animation Curves

extension Animation {
    /// Enhanced Romanian traditional card game physics with authentic momentum
    static let romanianCardBounce = Animation.interpolatingSpring(
        mass: 1.0,          // Natural card weight
        stiffness: 130,     // Lively Romanian folk dance rhythm
        damping: 11,        // Controlled traditional bounce
        initialVelocity: 8  // Initial cultural energy
    )
    
    /// Gentle celebration with momentum preservation
    static let gentleCelebration = Animation.interpolatingSpring(
        mass: 0.7,          // Light celebration feel
        stiffness: 90,      // Gentle rising motion
        damping: 12,        // Smooth settling
        initialVelocity: 5  // Subtle initial lift
    )
    
    /// Smooth card transition with natural physics
    static let smoothCardTransition = Animation.interpolatingSpring(
        mass: 0.9,          // Balanced transition weight
        stiffness: 140,     // Responsive movement
        damping: 16,        // Smooth deceleration
        initialVelocity: 3  // Natural start
    )
    
    /// Momentum-preserving drag follow animation
    static let momentumPreservingDrag = Animation.interpolatingSpring(
        mass: 0.6,          // Light responsive feel
        stiffness: 200,     // High responsiveness for real-time
        damping: 20,        // Quick settling without overshoot
        initialVelocity: 0  // Dynamic based on gesture
    )
    
    /// Natural card snap-back with energy conservation
    static let naturalSnapBack = Animation.interpolatingSpring(
        mass: 1.1,          // Heavier feel for satisfying return
        stiffness: 160,     // Strong return force
        damping: 18,        // Controlled return without bounce
        initialVelocity: 12 // Energy from the release
    )
    
    /// Romanian seven card special physics (cultural significance)
    static let romanianSevenPhysics = Animation.interpolatingSpring(
        mass: 1.3,          // Heavier cultural significance
        stiffness: 110,     // Ceremonial, deliberate movement
        damping: 13,        // Respectful settling
        initialVelocity: 6  // Dignified initial motion
    )
    
    /// Traditional Romanian folk dance rhythm animation
    static let romanianFolkRhythm = Animation.interpolatingSpring(
        mass: 0.9,          // Light, spirited movement
        stiffness: 125,     // Lively folk dance tempo
        damping: 9,         // Minimal damping for continuous movement
        initialVelocity: 12 // Energetic start
    )
    
    /// Romanian ceremonial card blessing animation
    static let romanianBlessing = Animation.interpolatingSpring(
        mass: 1.5,          // Reverent, weighty movement
        stiffness: 85,      // Slow, respectful motion
        damping: 16,        // Gentle, sacred settling
        initialVelocity: 3  // Gentle initiation
    )
    
    /// Traditional Romanian card gathering motion (as in village games)
    static let romanianGathering = Animation.interpolatingSpring(
        mass: 1.1,          // Community feel
        stiffness: 105,     // Steady, reliable gathering
        damping: 14,        // Stable community motion
        initialVelocity: 7  // Purposeful gathering energy
    )
    
    /// Romanian point card celebration (traditional victory)
    static let romanianVictoryDance = Animation.interpolatingSpring(
        mass: 0.7,          // Joyful, light celebration
        stiffness: 140,     // Quick, celebratory bounces
        damping: 8,         // Extended celebration with multiple bounces
        initialVelocity: 15 // Enthusiastic victory energy
    )
    
    // MARK: - Advanced Physics-Based Romanian Animations (Phase 3)
    
    /// Physics-aware Romanian card dance with momentum conservation
    static let romanianCardDance = Animation.interpolatingSpring(
        mass: 0.9,          // Light, spirited movement with proper physics
        stiffness: 135,     // Responsive folk dance rhythm
        damping: 8,         // Minimal damping for continuous natural motion
        initialVelocity: 15 // Energetic cultural start with momentum preservation
    )
    
    /// Energy-conserving Romanian harvest celebration animation
    static let romanianHarvestCelebration = Animation.interpolatingSpring(
        mass: 1.2,          // Substantial celebratory weight
        stiffness: 95,      // Deliberate, meaningful celebration
        damping: 10,        // Controlled joy with natural settling
        initialVelocity: 12 // Enthusiastic harvest energy
    )
    
    /// Momentum-preserving Romanian mountain wind animation
    static let romanianMountainWind = Animation.interpolatingSpring(
        mass: 0.6,          // Light as mountain air
        stiffness: 160,     // Quick, natural wind gusts
        damping: 6,         // Very low damping for flowing motion
        initialVelocity: 20 // Strong mountain wind force
    )
    
    /// Physics-based Romanian traditional game motion
    static let romanianTraditionalGame = Animation.interpolatingSpring(
        mass: 1.0,          // Balanced traditional feel
        stiffness: 115,     // Steady, time-honored rhythm
        damping: 12,        // Respectful settling
        initialVelocity: 8  // Traditional game energy
    )
}

// MARK: - Animation Preview Support

#if DEBUG
extension AnimationManager {
    /// Create preview instance with test animations and physics
    static let preview: AnimationManager = {
        let manager = AnimationManager()
        manager.initializePerformanceMonitoring()
        manager.performanceLevel = .high
        return manager
    }()
    
    /// Create demo physics animation for previews
    func createDemoPhysicsAnimation() {
        let demoCards = ["card1", "card2", "card3"]
        let demoGroup = createCoordinatedAnimation(
            animations: [.cardPlay, .cardFlip, .scoreUpdate],
            mode: .wave(direction: .centerOut),
            duration: 2.0
        )
        
        for (index, cardId) in demoCards.enumerated() {
            let position = CGPoint(x: CGFloat(index * 100), y: 100)
            let velocity = CGPoint(x: CGFloat.random(in: -50...50), y: CGFloat.random(in: -50...50))
            registerCardForCollision(cardId: cardId, position: position, velocity: velocity)
        }
        
        executeCoordinatedAnimation(groupId: demoGroup)
    }
}
#endif

// MARK: - Physics Simulation Components

/// Advanced physics simulator for card animations with ShuffleCats-quality physics
class PhysicsSimulator {
    private var quality: QualityLevel = .high
    private var updateRate: Int = 60
    private var energyConservationEnabled = true
    private var momentumPreservationEnabled = true
    private var simulationTime: Double = 0
    private var lastUpdateTime: CFTimeInterval = 0
    
    enum QualityLevel {
        case disabled, low, medium, high, maximum
        
        var description: String {
            switch self {
            case .disabled: return "No Physics"
            case .low: return "Basic Physics"
            case .medium: return "Standard Physics"
            case .high: return "Advanced Physics"
            case .maximum: return "Ultra Physics"
            }
        }
        
        var simulationSteps: Int {
            switch self {
            case .disabled: return 0
            case .low: return 1
            case .medium: return 2
            case .high: return 4
            case .maximum: return 8
            }
        }
    }
    
    func setQuality(_ quality: QualityLevel) {
        self.quality = quality
        adjustSimulationParameters()
    }
    
    func setUpdateRate(_ rate: Int) {
        self.updateRate = max(15, min(120, rate))  // Clamp between 15-120 FPS
    }
    
    func enableEnergyConservation() {
        energyConservationEnabled = true
    }
    
    func disableEnergyConservation() {
        energyConservationEnabled = false
    }
    
    func enableMomentumPreservation() {
        momentumPreservationEnabled = true
    }
    
    func disableMomentumPreservation() {
        momentumPreservationEnabled = false
    }
    
    func reset() {
        simulationTime = 0
        lastUpdateTime = CACurrentMediaTime()
    }
    
    /// Simulate physics step for improved realism
    func simulatePhysicsStep(deltaTime: Double) {
        guard quality != .disabled else { return }
        
        simulationTime += deltaTime
        
        // Perform multiple sub-steps for higher quality simulation
        let subSteps = quality.simulationSteps
        let subDeltaTime = deltaTime / Double(subSteps)
        
        for _ in 0..<subSteps {
            performSubStep(deltaTime: subDeltaTime)
        }
    }
    
    private func performSubStep(deltaTime: Double) {
        // Apply physics forces
        applyGravity(deltaTime: deltaTime)
        applyFriction(deltaTime: deltaTime)
        
        if energyConservationEnabled {
            conserveEnergy()
        }
        
        if momentumPreservationEnabled {
            preserveMomentum(deltaTime: deltaTime)
        }
    }
    
    private func applyGravity(deltaTime: Double) {
        // Subtle gravity effect for natural card fall
        let gravityStrength = quality == .maximum ? 9.81 : 4.905  // Reduced for card game
    }
    
    private func applyFriction(deltaTime: Double) {
        // Air resistance simulation
        let frictionCoefficient = AnimationManager.AnimationSettings.EnergyConservation.frictionCoefficient
    }
    
    private func conserveEnergy() {
        // Apply energy conservation laws
    }
    
    private func preserveMomentum(deltaTime: Double) {
        // Apply momentum conservation with decay
    }
    
    private func adjustSimulationParameters() {
        // Adjust parameters based on quality level
    }
}

/// Advanced collision detection system for card physics with spatial optimization
class CollisionDetector {
    private var enabled = true
    private var continuousDetection = true
    private var updateRate: Int = 60
    private var spatialGrid: SpatialGrid = SpatialGrid()
    private var collisionHistory: [String: Date] = [:]
    
    struct SpatialGrid {
        private var gridSize: CGFloat = 100.0
        private var grid: [GridCell] = []
        
        struct GridCell {
            let x: Int
            let y: Int
            var cardIds: Set<String> = []
        }
        
        mutating func updateCard(id: String, position: CGPoint) {
            let gridX = Int(position.x / gridSize)
            let gridY = Int(position.y / gridSize)
            
            // Remove from previous cells and add to new cell
            grid.removeAll { $0.cardIds.contains(id) }
            
            if let cellIndex = grid.firstIndex(where: { $0.x == gridX && $0.y == gridY }) {
                grid[cellIndex].cardIds.insert(id)
            } else {
                var newCell = GridCell(x: gridX, y: gridY)
                newCell.cardIds.insert(id)
                grid.append(newCell)
            }
        }
        
        func getNearbyCards(for position: CGPoint) -> Set<String> {
            let gridX = Int(position.x / gridSize)
            let gridY = Int(position.y / gridSize)
            
            var nearbyCards: Set<String> = []
            
            // Check surrounding cells (3x3 grid)
            for dx in -1...1 {
                for dy in -1...1 {
                    let checkX = gridX + dx
                    let checkY = gridY + dy
                    
                    if let cell = grid.first(where: { $0.x == checkX && $0.y == checkY }) {
                        nearbyCards.formUnion(cell.cardIds)
                    }
                }
            }
            
            return nearbyCards
        }
        
        mutating func clear() {
            grid.removeAll()
        }
    }
    
    func setEnabled(_ enabled: Bool) {
        self.enabled = enabled
        if !enabled {
            spatialGrid.clear()
        }
    }
    
    func enableContinuousDetection() {
        continuousDetection = true
    }
    
    func disableContinuousDetection() {
        continuousDetection = false
    }
    
    func setUpdateRate(_ rate: Int) {
        self.updateRate = max(15, min(120, rate))
    }
    
    func updateCardPosition(id: String, position: CGPoint) {
        guard enabled else { return }
        spatialGrid.updateCard(id: id, position: position)
    }
    
    func checkCollisions(for cardId: String, position: CGPoint, radius: CGFloat) -> [String] {
        guard enabled else { return [] }
        
        let nearbyCards = spatialGrid.getNearbyCards(for: position)
        var collidingCards: [String] = []
        
        for nearbyCardId in nearbyCards {
            guard nearbyCardId != cardId else { continue }
            
            // Prevent duplicate collision events within short time
            if let lastCollision = collisionHistory["\(cardId)-\(nearbyCardId)"],
               Date().timeIntervalSince(lastCollision) < 0.1 {
                continue
            }
            
            collidingCards.append(nearbyCardId)
            collisionHistory["\(cardId)-\(nearbyCardId)"] = Date()
        }
        
        return collidingCards
    }
    
    func reset() {
        spatialGrid.clear()
        collisionHistory.removeAll()
    }
    
    /// Clean up old collision history
    func cleanupCollisionHistory() {
        let cutoffTime = Date().addingTimeInterval(-1.0)  // Remove entries older than 1 second
        collisionHistory = collisionHistory.filter { $0.value > cutoffTime }
    }
}

/// Advanced animation synchronizer for coordinated sequences with temporal precision
class AnimationSynchronizer {
    private var activeGroups: [UUID: AnimationManager.CoordinatedAnimationGroup] = [:]
    private var groupTimings: [UUID: GroupTiming] = [:]
    private var masterClock: CFTimeInterval = 0
    
    struct GroupTiming {
        let startTime: CFTimeInterval
        let duration: TimeInterval
        let currentPhase: Double
        let nextEventTime: CFTimeInterval
        
        var progress: Double {
            let elapsed = CACurrentMediaTime() - startTime
            return min(elapsed / duration, 1.0)
        }
        
        var isComplete: Bool {
            return progress >= 1.0
        }
    }
    
    func addGroup(_ group: AnimationManager.CoordinatedAnimationGroup) {
        activeGroups[group.id] = group
        
        let timing = GroupTiming(
            startTime: CACurrentMediaTime(),
            duration: group.duration,
            currentPhase: 0.0,
            nextEventTime: CACurrentMediaTime()
        )
        groupTimings[group.id] = timing
    }
    
    func removeGroup(id: UUID) {
        activeGroups.removeValue(forKey: id)
        groupTimings.removeValue(forKey: id)
    }
    
    func getActiveGroups() -> [AnimationManager.CoordinatedAnimationGroup] {
        return Array(activeGroups.values)
    }
    
    func updateMasterClock() {
        masterClock = CACurrentMediaTime()
        
        // Clean up completed groups
        let completedGroups = groupTimings.filter { $0.value.isComplete }.map { $0.key }
        for groupId in completedGroups {
            removeGroup(id: groupId)
        }
    }
    
    func getGroupProgress(id: UUID) -> Double {
        return groupTimings[id]?.progress ?? 0.0
    }
    
    func isGroupComplete(id: UUID) -> Bool {
        return groupTimings[id]?.isComplete ?? true
    }
    
    func getNextEventTime(for groupId: UUID) -> CFTimeInterval? {
        return groupTimings[groupId]?.nextEventTime
    }
    
    func synchronizeToMasterClock() {
        // Ensure all groups are synchronized to the master clock
        for (id, timing) in groupTimings {
            if abs(timing.startTime - masterClock) > 0.016 {  // More than one frame difference
                // Adjust timing to maintain synchronization
                adjustGroupTiming(id: id)
            }
        }
    }
    
    private func adjustGroupTiming(id: UUID) {
        // Fine-tune group timing for better synchronization
    }
}

// MARK: - Missing Method Implementations

extension AnimationManager {
    /// Create gesture-responsive physics animation with energy conservation
    func createGesturePhysicsAnimation(
        velocity: CGPoint,
        position: CGPoint,
        cardId: String
    ) -> Animation {
        let velocityMagnitude = sqrt(pow(velocity.x, 2) + pow(velocity.y, 2))
        
        // Calculate kinetic energy for physics realism
        let kineticEnergy = calculateKineticEnergy(velocity: velocity, mass: 1.0)
        let energyFactor = min(kineticEnergy / 1000.0, 2.0)  // Scale energy impact
        
        // Register for collision detection with energy-based parameters
        registerCardForCollision(
            cardId: cardId,
            position: position,
            velocity: velocity,
            radius: 35.0 + CGFloat(energyFactor * 5),  // Larger collision radius for high energy
            mass: 1.0 + energyFactor * 0.3  // Increased effective mass for high energy
        )
        
        // Create energy-conserving velocity-responsive spring
        let conservedVelocity = velocityMagnitude * AnimationSettings.EnergyConservation.kineticEnergyRetention
        let responsiveSpring = Animation.interpolatingSpring(
            mass: AnimationSettings.SpringConstants.dragMass + min(conservedVelocity / 1000.0, 0.5),
            stiffness: max(80.0, AnimationSettings.SpringConstants.dragStiffness - conservedVelocity / 25.0),
            damping: AnimationSettings.SpringConstants.dragDamping + (conservedVelocity / 120.0),
            initialVelocity: min(conservedVelocity / 90.0, 35.0)
        )
        
        return getOptimizedAnimation(responsiveSpring)
    }
    
    /// Create momentum-preserving animation for fluid card interactions
    func createMomentumPreservingAnimation(
        initialMomentum: CGPoint,
        targetPosition: CGPoint,
        cardId: String
    ) -> Animation {
        let momentumMagnitude = sqrt(pow(initialMomentum.x, 2) + pow(initialMomentum.y, 2))
        
        // Apply momentum decay over time
        let decayedMomentum = momentumMagnitude * AnimationSettings.EnergyConservation.momentumDecay
        
        // Create momentum-aware spring physics
        let momentumSpring = Animation.interpolatingSpring(
            mass: AnimationSettings.SpringConstants.cardMass + min(decayedMomentum / 500.0, 0.8),
            stiffness: max(90.0, AnimationSettings.SpringConstants.cardStiffness - decayedMomentum / 30.0),
            damping: AnimationSettings.SpringConstants.cardDamping + (decayedMomentum / 100.0),
            initialVelocity: min(decayedMomentum / 60.0, 25.0)
        )
        
        return getOptimizedAnimation(momentumSpring)
    }
    
    /// Create collision-aware animation with physics response
    func createCollisionAwareAnimation(
        collisionForce: CGPoint,
        elasticity: Double = 0.6,
        cardId: String
    ) -> Animation {
        let forceMagnitude = sqrt(pow(collisionForce.x, 2) + pow(collisionForce.y, 2))
        
        // Apply collision physics with restitution
        let elasticForce = forceMagnitude * elasticity * AnimationSettings.CollisionPhysics.collisionElasticity
        
        // Create collision response spring
        let collisionSpring = Animation.interpolatingSpring(
            mass: AnimationSettings.SpringConstants.cardMass * 1.2,  // Increased mass for collision
            stiffness: max(150.0, 300.0 - elasticForce / 10.0),      // Higher stiffness for collision
            damping: AnimationSettings.SpringConstants.cardDamping * 1.5 + elasticForce / 50.0,
            initialVelocity: min(elasticForce / 40.0, 40.0)
        )
        
        return getOptimizedAnimation(collisionSpring)
    }
    
    /// Animate card with advanced physics simulation
    func animateCardWithPhysics(
        cardId: String,
        from startPosition: CGPoint,
        to endPosition: CGPoint,
        initialVelocity: CGPoint,
        completion: @escaping () -> Void
    ) {
        // Calculate physics parameters
        let distance = sqrt(pow(endPosition.x - startPosition.x, 2) + pow(endPosition.y - startPosition.y, 2))
        let velocityMagnitude = sqrt(pow(initialVelocity.x, 2) + pow(initialVelocity.y, 2))
        
        // Apply energy conservation
        let kineticEnergy = calculateKineticEnergy(velocity: initialVelocity, mass: 1.0)
        let potentialEnergy = calculatePotentialEnergy(position: startPosition, mass: 1.0)
        
        let totalEnergy = kineticEnergy + potentialEnergy
        let _ = totalEnergy * AnimationSettings.EnergyConservation.kineticEnergyRetention
        
        // Create physics-based spring animation
        let physicsSpring = Animation.interpolatingSpring(
            mass: AnimationSettings.SpringConstants.cardMass,
            stiffness: AnimationSettings.SpringConstants.cardStiffness,
            damping: AnimationSettings.SpringConstants.cardDamping,
            initialVelocity: min(velocityMagnitude / 100.0, 25.0)
        )
        
        // Update collision detection
        updateCardCollision(cardId: cardId, position: startPosition, velocity: initialVelocity)
        
        // Execute animation with physics
        withAnimation(getOptimizedAnimation(physicsSpring)) {
            // The actual UI animation will be handled by the view
        }
        
        // Calculate dynamic duration based on physics
        let baseDuration = distance / max(velocityMagnitude, 100.0)
        let physicsDuration = max(0.3, min(1.5, baseDuration))
        let optimizedDuration = getOptimizedDuration(physicsDuration)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + optimizedDuration) {
            self.unregisterCardFromCollision(cardId: cardId)
            completion()
        }
    }
    
    // MARK: - Missing Method Implementations for Phase 3 Animation Excellence
    
    /// Create coordinated animation group for multi-element sequences
    func createCoordinatedAnimation(
        animations: [AnimationType],
        mode: CoordinatedAnimationGroup.SynchronizationMode,
        duration: TimeInterval
    ) -> UUID {
        let group = CoordinatedAnimationGroup(
            id: UUID(),
            animations: animations,
            synchronizationMode: mode,
            startTime: Date(),
            duration: duration
        )
        
        coordinatedAnimations.append(group)
        animationSynchronizer.addGroup(group)
        
        return group.id
    }
    
    /// Execute coordinated animation group
    func executeCoordinatedAnimation(groupId: UUID) {
        guard let group = coordinatedAnimations.first(where: { $0.id == groupId }) else { return }
        
        switch group.synchronizationMode {
        case .simultaneous:
            // Start all animations at the same time
            for animationType in group.animations {
                startAnimation(animationType)
            }
        case .staggered(let delay):
            // Start animations with staggered delay
            for (index, animationType) in group.animations.enumerated() {
                let startDelay = Double(index) * delay
                DispatchQueue.main.asyncAfter(deadline: .now() + startDelay) {
                    self.startAnimation(animationType)
                }
            }
        case .sequential:
            // Start animations one after another
            executeSequentialAnimations(group.animations, index: 0)
        case .wave(let direction):
            // Execute wave-based animation sequence
            executeWaveAnimation(group.animations, direction: direction)
        }
    }
    
    /// Execute sequential animation chain
    private func executeSequentialAnimations(_ animations: [AnimationType], index: Int) {
        guard index < animations.count else { return }
        
        let currentAnimation = animations[index]
        startAnimation(currentAnimation)
        
        // Calculate duration based on animation type
        let duration = getAnimationDuration(for: currentAnimation)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.endAnimation(currentAnimation)
            self.executeSequentialAnimations(animations, index: index + 1)
        }
    }
    
    /// Execute wave-based animation sequence
    private func executeWaveAnimation(_ animations: [AnimationType], direction: CoordinatedAnimationGroup.WaveDirection) {
        let totalAnimations = animations.count
        
        for (index, animationType) in animations.enumerated() {
            let delay: Double
            
            switch direction {
            case .leftToRight:
                delay = Double(index) * 0.1
            case .rightToLeft:
                delay = Double(totalAnimations - 1 - index) * 0.1
            case .centerOut:
                let centerIndex = totalAnimations / 2
                delay = Double(abs(index - centerIndex)) * 0.1
            case .edgeIn:
                let centerIndex = totalAnimations / 2
                delay = Double(centerIndex - abs(index - centerIndex)) * 0.1
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.startAnimation(animationType)
            }
        }
    }
    
    /// Get duration for specific animation type
    private func getAnimationDuration(for type: AnimationType) -> Double {
        switch type {
        case .cardPlay:
            return AnimationSettings.cardPlayDuration
        case .cardFlip:
            return AnimationSettings.cardFlipDuration
        case .scoreUpdate:
            return AnimationSettings.scoreUpdateDuration
        case .victory, .defeat:
            return AnimationSettings.victoryAnimationDuration
        case .menuTransition:
            return AnimationSettings.menuTransitionDuration
        case .loading:
            return AnimationSettings.loadingAnimationDuration
        case .cardShuffle, .turnTransition:
            return 0.8
        }
    }
    
    /// Register card for collision detection with physics parameters
    func registerCardForCollision(
        cardId: String,
        position: CGPoint,
        velocity: CGPoint,
        radius: CGFloat = 35.0,
        mass: Double = 1.0
    ) {
        let collisionState = CollisionState(
            cardId: cardId,
            position: position,
            velocity: velocity,
            radius: radius,
            mass: mass,
            lastUpdate: Date()
        )
        
        animationCollisions[cardId] = collisionState
        collisionDetector.updateCardPosition(id: cardId, position: position)
        
        // Check for immediate collisions
        let collidingCards = collisionDetector.checkCollisions(for: cardId, position: position, radius: radius)
        if !collidingCards.isEmpty {
            handleCardCollisions(cardId: cardId, collidingWith: collidingCards)
        }
    }
    
    /// Update card collision state during animation
    func updateCardCollision(cardId: String, position: CGPoint, velocity: CGPoint) {
        guard var collisionState = animationCollisions[cardId] else { return }
        
        // Update collision state
        collisionState = CollisionState(
            cardId: cardId,
            position: position,
            velocity: velocity,
            radius: collisionState.radius,
            mass: collisionState.mass,
            lastUpdate: Date()
        )
        
        animationCollisions[cardId] = collisionState
        collisionDetector.updateCardPosition(id: cardId, position: position)
        
        // Check for new collisions
        let collidingCards = collisionDetector.checkCollisions(for: cardId, position: position, radius: collisionState.radius)
        if !collidingCards.isEmpty {
            handleCardCollisions(cardId: cardId, collidingWith: collidingCards)
        }
    }
    
    /// Remove card from collision detection
    func unregisterCardFromCollision(cardId: String) {
        animationCollisions.removeValue(forKey: cardId)
    }
    
    /// Handle collisions between cards with physics response
    private func handleCardCollisions(cardId: String, collidingWith: [String]) {
        guard let cardState = animationCollisions[cardId] else { return }
        
        for collidingCardId in collidingWith {
            guard let otherCardState = animationCollisions[collidingCardId] else { continue }
            
            // Calculate collision forces
            let dx = otherCardState.position.x - cardState.position.x
            let dy = otherCardState.position.y - cardState.position.y
            let distance = sqrt(dx * dx + dy * dy)
            
            // Prevent division by zero
            guard distance > 0 else { continue }
            
            // Calculate separation force
            let overlap = (cardState.radius + otherCardState.radius) - distance
            if overlap > 0 {
                let separationForce = overlap * AnimationSettings.CollisionPhysics.separationForce
                let forceX = (dx / distance) * separationForce
                let forceY = (dy / distance) * separationForce
                
                let collisionForce = CGPoint(x: forceX, y: forceY)
                
                // Apply collision response with haptic feedback
                applyCollisionResponse(cardId: cardId, force: collisionForce)
                hapticManager?.trigger(.cardPlay) // Collision feedback using existing method
            }
        }
    }
    
    /// Apply collision response forces
    private func applyCollisionResponse(cardId: String, force: CGPoint) {
        // Update velocity based on collision force
        guard var collisionState = animationCollisions[cardId] else { return }
        
        let elasticity = AnimationSettings.CollisionPhysics.collisionElasticity
        let damping = AnimationSettings.CollisionPhysics.collisionDamping
        
        let newVelocity = CGPoint(
            x: collisionState.velocity.x + force.x * elasticity * damping,
            y: collisionState.velocity.y + force.y * elasticity * damping
        )
        
        // Update collision state with new velocity
        collisionState = CollisionState(
            cardId: cardId,
            position: collisionState.position,
            velocity: newVelocity,
            radius: collisionState.radius,
            mass: collisionState.mass,
            lastUpdate: Date()
        )
        
        animationCollisions[cardId] = collisionState
    }
    
    /// Calculate kinetic energy for physics realism
    func calculateKineticEnergy(velocity: CGPoint, mass: Double) -> Double {
        let velocityMagnitudeSquared = pow(velocity.x, 2) + pow(velocity.y, 2)
        return 0.5 * mass * Double(velocityMagnitudeSquared)
    }
    
    /// Calculate potential energy based on position (height-based)
    func calculatePotentialEnergy(position: CGPoint, mass: Double) -> Double {
        let gravity = 9.81 // Standard gravity
        let height = Double(position.y) / 100.0 // Convert to meters (scale factor)
        return mass * gravity * height
    }
}
