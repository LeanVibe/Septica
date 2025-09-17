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
    
    // MARK: - Animation Settings
    
    struct AnimationSettings {
        static let cardPlayDuration: Double = 0.6
        static let cardFlipDuration: Double = 0.4
        static let scoreUpdateDuration: Double = 0.8
        static let victoryAnimationDuration: Double = 2.0
        static let menuTransitionDuration: Double = 0.3
        static let loadingAnimationDuration: Double = 1.5
        
        // Spring animations
        static let cardSpring = Animation.spring(response: 0.6, dampingFraction: 0.8)
        static let scoreSpring = Animation.spring(response: 0.5, dampingFraction: 0.7)
        static let menuSpring = Animation.spring(response: 0.4, dampingFraction: 0.9)
        
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
    
    // MARK: - Card Animation Functions
    
    /// Animate card being played from hand to table
    func animateCardPlay(
        from startPosition: CGPoint,
        to endPosition: CGPoint,
        completion: @escaping () -> Void
    ) {
        startAnimation(.cardPlay)
        
        withAnimation(AnimationSettings.cardSpring) {
            // Animation handled by view state changes
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + AnimationSettings.cardPlayDuration) {
            self.endAnimation(.cardPlay)
            completion()
        }
    }
    
    /// Animate card flip for opponent cards or reveals
    func animateCardFlip(delay: Double = 0, completion: @escaping () -> Void = {}) {
        startAnimation(.cardFlip)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.easeInOut(duration: AnimationSettings.cardFlipDuration)) {
                // Flip animation handled by view state
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + AnimationSettings.cardFlipDuration) {
                self.endAnimation(.cardFlip)
                completion()
            }
        }
    }
    
    /// Animate card shuffle effect
    func animateCardShuffle(completion: @escaping () -> Void = {}) {
        startAnimation(.cardShuffle)
        
        withAnimation(.easeInOut(duration: 1.0).repeatCount(3, autoreverses: true)) {
            // Shuffle animation state changes
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.endAnimation(.cardShuffle)
            completion()
        }
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
    
    // MARK: - Animation State Management
    
    private func startAnimation(_ type: AnimationType) {
        activeAnimations.insert(type)
        isAnimating = !activeAnimations.isEmpty
    }
    
    private func endAnimation(_ type: AnimationType) {
        activeAnimations.remove(type)
        isAnimating = !activeAnimations.isEmpty
    }
    
    /// Check if specific animation is active
    func isAnimationActive(_ type: AnimationType) -> Bool {
        activeAnimations.contains(type)
    }
    
    /// Stop all animations immediately (for accessibility or performance)
    func stopAllAnimations() {
        activeAnimations.removeAll()
        isAnimating = false
    }
    
    // MARK: - Accessibility Support
    
    /// Check if reduced motion is preferred
    private var isReducedMotionEnabled: Bool {
        UIAccessibility.isReduceMotionEnabled
    }
    
    /// Get animation duration adjusted for accessibility preferences
    func adjustedDuration(_ baseDuration: Double) -> Double {
        isReducedMotionEnabled ? baseDuration * 0.3 : baseDuration
    }
    
    /// Get animation with accessibility considerations
    func accessibleAnimation(_ animation: Animation) -> Animation {
        if isReducedMotionEnabled {
            return .linear(duration: 0.1) // Minimal animation for reduced motion
        }
        return animation
    }
    
    // MARK: - Game End Celebration Animations
    
    /// Play confetti animation with specified intensity
    func playConfettiAnimation(intensity: Double) async {
        startAnimation(.victory)
        
        withAnimation(.easeOut(duration: adjustedDuration(2.0))) {
            // Confetti particle animation
        }
        
        try? await Task.sleep(nanoseconds: UInt64(adjustedDuration(2.0) * 1_000_000_000))
        endAnimation(.victory)
    }
    
    /// Animate statistics reveal with staggered appearance
    func animateStatisticsReveal(_ statistics: Any) async {
        startAnimation(.scoreUpdate)
        
        withAnimation(.easeInOut(duration: adjustedDuration(1.0))) {
            // Statistics reveal animation
        }
        
        try? await Task.sleep(nanoseconds: UInt64(adjustedDuration(1.0) * 1_000_000_000))
        endAnimation(.scoreUpdate)
    }
    
    /// Animate experience gain with counting effect
    func animateExperienceGain(_ experience: Any) async {
        startAnimation(.scoreUpdate)
        
        withAnimation(AnimationSettings.scoreSpring) {
            // Experience points animation
        }
        
        try? await Task.sleep(nanoseconds: UInt64(adjustedDuration(1.5) * 1_000_000_000))
        endAnimation(.scoreUpdate)
    }
    
    /// Animate achievement unlock with celebration
    func animateAchievementUnlock(_ achievement: Any) async {
        startAnimation(.victory)
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            // Achievement unlock animation with bounce
        }
        
        try? await Task.sleep(nanoseconds: UInt64(adjustedDuration(1.0) * 1_000_000_000))
        endAnimation(.victory)
    }
    
    /// Display cultural wisdom with elegant presentation
    func displayCulturalWisdom(_ wisdom: String) async {
        startAnimation(.menuTransition)
        
        withAnimation(.easeInOut(duration: adjustedDuration(1.5))) {
            // Cultural wisdom display animation
        }
        
        try? await Task.sleep(nanoseconds: UInt64(adjustedDuration(1.5) * 1_000_000_000))
        endAnimation(.menuTransition)
    }
    
    /// Fade out celebration effects
    func fadeOutCelebration() async {
        withAnimation(.easeOut(duration: adjustedDuration(1.0))) {
            // Fade out all celebration elements
        }
        
        try? await Task.sleep(nanoseconds: UInt64(adjustedDuration(1.0) * 1_000_000_000))
        stopAllAnimations()
    }
    
    /// Start particle effects for celebrations
    func startParticleEffects(_ particleType: Any) async {
        startAnimation(.victory)
        
        withAnimation(.easeOut(duration: adjustedDuration(3.0))) {
            // Particle system animation
        }
        
        try? await Task.sleep(nanoseconds: UInt64(adjustedDuration(3.0) * 1_000_000_000))
    }
    
    /// Play specific animation type
    func playAnimation(_ animationType: Any) async {
        startAnimation(.victory)
        
        withAnimation(.easeInOut(duration: adjustedDuration(1.0))) {
            // Generic animation playback
        }
        
        try? await Task.sleep(nanoseconds: UInt64(adjustedDuration(1.0) * 1_000_000_000))
        endAnimation(.victory)
    }
    
    /// Animate score count up with number progression
    func animateScoreCountUp(from startValue: Int, to endValue: Int) async {
        startAnimation(.scoreUpdate)
        
        let duration = adjustedDuration(2.0)
        let steps = min(abs(endValue - startValue), 20) // Limit animation steps
        let stepDuration = duration / Double(steps)
        
        for step in 1...steps {
            withAnimation(.easeOut(duration: stepDuration)) {
                // Score counting animation step
            }
            try? await Task.sleep(nanoseconds: UInt64(stepDuration * 1_000_000_000))
        }
        
        endAnimation(.scoreUpdate)
    }
    
    /// Animate statistic count up for multiple values
    func animateStatisticCountUp(_ statistics: Any) async {
        startAnimation(.scoreUpdate)
        
        withAnimation(.easeInOut(duration: adjustedDuration(1.5))) {
            // Multiple statistics animation
        }
        
        try? await Task.sleep(nanoseconds: UInt64(adjustedDuration(1.5) * 1_000_000_000))
        endAnimation(.scoreUpdate)
    }
    
    /// Fade out all effects completely
    func fadeOutAllEffects() async {
        withAnimation(.easeOut(duration: adjustedDuration(1.0))) {
            // Fade out all active effects
        }
        
        try? await Task.sleep(nanoseconds: UInt64(adjustedDuration(1.0) * 1_000_000_000))
        stopAllAnimations()
    }
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
                    .easeInOut(duration: manager.adjustedDuration(1.0))
                    .repeatForever(autoreverses: true)
                ),
                value: isActive
            )
    }
}

// MARK: - Custom Animation Curves

extension Animation {
    /// Romanian traditional card game inspired bounce
    static let romanianCardBounce = Animation.interpolatingSpring(
        mass: 0.8,
        stiffness: 100,
        damping: 10,
        initialVelocity: 0
    )
    
    /// Gentle celebration animation
    static let gentleCelebration = Animation.timingCurve(
        0.25, 0.1, 0.25, 1.0,
        duration: 0.8
    )
    
    /// Smooth card transition
    static let smoothCardTransition = Animation.timingCurve(
        0.4, 0.0, 0.2, 1.0,
        duration: 0.6
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