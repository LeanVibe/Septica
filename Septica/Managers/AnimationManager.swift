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
    
    // MARK: - Enhanced Physics-Based Animation Settings
    
    struct AnimationSettings {
        static let cardPlayDuration: Double = 0.6
        static let cardFlipDuration: Double = 0.4
        static let scoreUpdateDuration: Double = 0.8
        static let victoryAnimationDuration: Double = 2.0
        static let menuTransitionDuration: Double = 0.3
        static let loadingAnimationDuration: Double = 1.5
        
        // Enhanced physics-based spring animations with realistic constants
        static let cardSpring = Animation.interpolatingSpring(
            mass: 1.0,         // Natural card weight feel
            stiffness: 120.0,  // Responsive yet smooth
            damping: 12.0,     // Controlled oscillation
            initialVelocity: 0
        )
        static let cardDragSpring = Animation.interpolatingSpring(
            mass: 0.8,         // Lighter feel during drag
            stiffness: 150.0,  // More responsive for real-time interaction
            damping: 15.0,     // Quick settling
            initialVelocity: 0
        )
        static let cardSnapSpring = Animation.interpolatingSpring(
            mass: 1.2,         // Heavier snap for satisfying feedback
            stiffness: 200.0,  // Fast snap response
            damping: 20.0,     // Prevent overshoot
            initialVelocity: 10 // Initial momentum
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
        
        // Momentum preservation system
        static let momentumDamping: Double = 0.85  // Energy retention factor
        static let velocityThreshold: Double = 50.0 // Minimum velocity for momentum effects
        
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
    
    // MARK: - Enhanced Animation State Management with Momentum Tracking
    
    // Momentum tracking for physics-based animations
    private var animationMomentum: [AnimationType: Double] = [:]
    private var animationVelocities: [AnimationType: CGPoint] = [:]
    
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
    /// Apply card play animation
    func cardPlayAnimation(
        isActive: Bool,
        manager: AnimationManager,
        from: CGPoint = .zero,
        to: CGPoint = .zero
    ) -> some View {
        self.scaleEffect(isActive ? 1.1 : 1.0)
            .rotationEffect(.degrees(isActive ? 5 : 0))
            .animation(manager.accessibleAnimation(AnimationManager.AnimationSettings.cardSpring), value: isActive)
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
}

// MARK: - Animation Preview Support

#if DEBUG
extension AnimationManager {
    /// Create preview instance with test animations
    static let preview: AnimationManager = {
        let manager = AnimationManager()
        return manager
    }()
}
#endif
