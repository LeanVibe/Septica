//
//  AnimationCoordinator.swift
//  Septica
//
//  Unified animation management system for smooth gameplay
//  Coordinates all game animations with proper state management
//

import SwiftUI

/// Unified animation management system that coordinates all game animations
@MainActor
class AnimationCoordinator: ObservableObject {

    // MARK: - Properties

    private let elasticEngine = ElasticAnimationEngine()
    private let trajectoryAnimator = CardTrajectoryAnimator()
    private var activeAnimations: [UUID: AnimationState] = [:]
    private let animationQueue = DispatchQueue(label: "com.septica.animations", qos: .userInteractive)

    // MARK: - Animation State

    private struct AnimationState {
        let id: UUID
        let startTime: Date
        let duration: TimeInterval
        let completion: (() -> Void)?
        var isCompleted: Bool = false
    }

    // MARK: - Public Interface

    /// Coordinate complete card play animation with trajectory and physics
    /// - Parameters:
    ///   - card: Card being played
    ///   - from: Starting position
    ///   - to: Target position
    ///   - characterType: Character playing the card
    ///   - completion: Completion callback
    func coordinateCardPlay(
        card: Card,
        from startPoint: CGPoint,
        to endPoint: CGPoint,
        characterType: RomanianCharacterType,
        completion: (() -> Void)? = nil
    ) {
        let animationId = UUID()

        // Calculate trajectory
        let trajectory = trajectoryAnimator.calculatePlayTrajectory(
            from: startPoint,
            to: endPoint,
            height: 120.0
        )

        // Calculate timing based on character and play style
        let timing = CulturalAnimationTiming.timingForCardPlay(
            characterType: characterType,
            playStyle: determinePlayStyle(for: card, characterType: characterType),
            isWinning: isWinningCard(card)
        )

        // Calculate animation
        let animation = elasticEngine.calculateCardPlayAnimation()

        // Store animation state
        activeAnimations[animationId] = AnimationState(
            id: animationId,
            startTime: Date(),
            duration: timing,
            completion: completion
        )

        // Schedule cleanup
        scheduleAnimationCleanup(id: animationId, after: timing)
    }

    /// Coordinate card selection animation with elastic feedback
    /// - Parameters:
    ///   - cardId: ID of selected card
    ///   - characterType: Character selecting the card
    ///   - completion: Completion callback
    func coordinateCardSelection(
        cardId: UUID,
        characterType: RomanianCharacterType,
        completion: (() -> Void)? = nil
    ) {
        let timing = CulturalAnimationTiming.timingForCardSelection(
            characterType: characterType,
            selectionSpeed: determineSelectionSpeed(characterType: characterType)
        )

        let animation = elasticEngine.calculateCardSelectionAnimation()

        let animationId = UUID()
        activeAnimations[animationId] = AnimationState(
            id: animationId,
            startTime: Date(),
            duration: timing,
            completion: completion
        )

        scheduleAnimationCleanup(id: animationId, after: timing)
    }

    /// Coordinate victory celebration animation with character-specific effects
    /// - Parameters:
    ///   - characterType: Winning character
    ///   - victoryType: Type of victory
    ///   - completion: Completion callback
    func coordinateVictoryCelebration(
        characterType: RomanianCharacterType,
        victoryType: VictoryType = .decisive,
        completion: (() -> Void)? = nil
    ) {
        let timing = CulturalAnimationTiming.timingForVictory(
            characterType: characterType,
            victoryType: victoryType
        )

        let animation = elasticEngine.calculateVictoryAnimation(characterType: characterType)

        let animationId = UUID()
        activeAnimations[animationId] = AnimationState(
            id: animationId,
            startTime: Date(),
            duration: timing,
            completion: completion
        )

        scheduleAnimationCleanup(id: animationId, after: timing)
    }

    /// Coordinate emote animation with character timing
    /// - Parameters:
    ///   - emoteType: Type of emote
    ///   - characterType: Character performing emote
    ///   - completion: Completion callback
    func coordinateEmoteAnimation(
        emoteType: EmoteType,
        characterType: RomanianCharacterType,
        completion: (() -> Void)? = nil
    ) {
        let timing = CulturalAnimationTiming.timingForEmote(
            emoteType: emoteType,
            characterType: characterType
        )

        let animation = elasticEngine.calculateEmoteAnimation(
            emoteType: emoteType,
            characterType: characterType
        )

        let animationId = UUID()
        activeAnimations[animationId] = AnimationState(
            id: animationId,
            startTime: Date(),
            duration: timing,
            completion: completion
        )

        scheduleAnimationCleanup(id: animationId, after: timing)
    }

    /// Coordinate card dealing animation
    /// - Parameters:
    ///   - playerCount: Number of players
    ///   - cardsPerPlayer: Cards per player
    ///   - dealingStyle: Style of dealing
    ///   - completion: Completion callback
    func coordinateCardDealing(
        playerCount: Int,
        cardsPerPlayer: Int,
        dealingStyle: DealingStyle = .smooth,
        completion: (() -> Void)? = nil
    ) {
        let timing = CulturalAnimationTiming.timingForDealing(
            playerCount: playerCount,
            cardsPerPlayer: cardsPerPlayer,
            dealingStyle: dealingStyle
        )

        let animationId = UUID()
        activeAnimations[animationId] = AnimationState(
            id: animationId,
            startTime: Date(),
            duration: timing,
            completion: completion
        )

        scheduleAnimationCleanup(id: animationId, after: timing)
    }

    /// Check if animation can start for specific card
    /// - Parameter cardId: Card ID to check
    /// - Returns: True if animation can start
    func canStartAnimation(for cardId: UUID) -> Bool {
        return activeAnimations[cardId] == nil
    }

    /// Set animation state for card
    /// - Parameters:
    ///   - cardId: Card ID
    ///   - inProgress: Animation state
    func setAnimationInProgress(for cardId: UUID, inProgress: Bool) {
        if inProgress {
            // Animation start is handled by coordinate methods
        } else {
            // Animation completion is handled by cleanup
            onAnimationComplete(cardId: cardId)
        }
    }

    /// Handle animation completion
    /// - Parameter cardId: Card ID that completed animation
    func onAnimationComplete(cardId: UUID) {
        if let animationState = activeAnimations[cardId] {
            animationState.completion?()
            activeAnimations.removeValue(forKey: cardId)
        }
    }

    /// Synchronize animation with sound effect
    /// - Parameters:
    ///   - animationId: Animation ID
    ///   - soundName: Sound file name
    func synchronizeAnimationWithSound(animationId: UUID, soundName: String) {
        // This would integrate with the sound system
        // For now, we'll just log the synchronization
        print("Synchronizing animation \(animationId) with sound: \(soundName)")
    }

    /// Get current animation state for card
    /// - Parameter cardId: Card ID
    /// - Returns: Animation state if active
    func getAnimationState(for cardId: UUID) -> AnimationState? {
        return activeAnimations[cardId]
    }

    /// Cancel all active animations
    func cancelAllAnimations() {
        for (_, animationState) in activeAnimations {
            animationState.completion?()
        }
        activeAnimations.removeAll()
    }

    /// Get active animations count
    var activeAnimationCount: Int {
        return activeAnimations.count
    }

    // MARK: - Private Helper Methods

    /// Determine play style based on card and character
    private func determinePlayStyle(for card: Card, characterType: RomanianCharacterType) -> CardPlayStyle {
        // Character-specific play styles
        switch characterType {
        case .pacala:
            return .quick      // Playful and fast
        case .iele:
            return .thoughtful // Graceful and considered
        case .strigoi:
            return .dramatic   // Intense and showy
        case .fatFrumos:
            return .strategic  // Heroic and planned
        case .babaCloantza:
            return .thoughtful // Wise and careful
        case .zmeu:
            return .dramatic   // Energetic and explosive
        }
    }

    /// Determine selection speed based on character
    private func determineSelectionSpeed(characterType: RomanianCharacterType) -> SelectionSpeed {
        switch characterType {
        case .pacala:
            return .quick      // Impulsive selection
        case .iele:
            return .considered // Flowing selection
        case .strigoi:
            return .instant    // Decisive selection
        case .fatFrumos:
            return .normal     // Confident selection
        case .babaCloantza:
            return .considered // Wise selection
        case .zmeu:
            return .quick      // Eager selection
        }
    }

    /// Check if card is a winning card
    private func isWinningCard(_ card: Card) -> Bool {
        // This would integrate with game logic to determine if card wins
        // For now, assume face cards are winning cards
        return card.value >= 11 // Jack, Queen, King, Ace
    }

    /// Schedule animation cleanup
    private func scheduleAnimationCleanup(id: UUID, after duration: TimeInterval) {
        animationQueue.asyncAfter(deadline: .now() + duration) { [weak self] in
            DispatchQueue.main.async {
                self?.onAnimationComplete(cardId: id)
            }
        }
    }
}

// MARK: - SwiftUI Integration

extension View {
    /// Apply coordinated animation to view
    func coordinatedAnimation(
        _ coordinator: AnimationCoordinator,
        animationId: UUID,
        animation: Animation
    ) -> some View {
        self.animation(animation, value: coordinator.getAnimationState(for: animationId)?.isCompleted)
    }
}