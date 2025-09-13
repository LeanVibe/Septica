//
//  HapticManager.swift
//  Septica
//
//  Comprehensive haptic feedback system for Romanian Septica card game
//  Provides contextual tactile feedback for enhanced user experience
//

import UIKit
import AudioToolbox
import SwiftUI
import Combine

/// Centralized haptic feedback management for the entire application
@MainActor
class HapticManager: ObservableObject {
    
    // MARK: - Properties
    
    private let lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()
    
    @Published var isHapticsEnabled = true
    @Published var ageGroup: AgeGroup = .ages6to8 // Septica target demographic
    
    // MARK: - Age-Appropriate Haptic Configuration
    
    enum AgeGroup {
        case ages6to8   // Gentle, encouraging feedback
        case ages9to12  // More sophisticated patterns
        case adult      // Full intensity haptics
        
        var hapticIntensityModifier: Float {
            switch self {
            case .ages6to8: return 0.6   // Gentler haptics for younger children
            case .ages9to12: return 0.8  // Moderate haptics
            case .adult: return 1.0      // Full intensity
            }
        }
        
        var maxSequenceLength: Int {
            switch self {
            case .ages6to8: return 3     // Shorter sequences to avoid overwhelming
            case .ages9to12: return 5    // Moderate complexity
            case .adult: return 8        // Full complexity allowed
            }
        }
    }
    
    // MARK: - Initialization
    
    init() {
        loadHapticPreferences()
        prepareGenerators()
    }
    
    // MARK: - Haptic Feedback Types
    
    enum HapticFeedback {
        // Card Interactions
        case cardSelect
        case cardPlay
        case cardInvalid
        case cardShuffle
        case cardFlip
        
        // Game Events
        case scoreIncrease
        case trickWon
        case trickLost
        case gameVictory
        case gameDefeat
        case turnChange
        
        // Menu Navigation
        case menuSelect
        case menuConfirm
        case menuCancel
        case menuTransition
        
        // System Events
        case notification
        case warning
        case error
        case success
        
        // Accessibility
        case focusChange
        case boundaryReached
        case elementActivated
    }
    
    // MARK: - Public Interface
    
    /// Trigger haptic feedback for specific game events
    func trigger(_ feedback: HapticFeedback) {
        guard isHapticsEnabled && UIDevice.current.userInterfaceIdiom == .phone else {
            return // Haptics only available on iPhone
        }
        
        switch feedback {
        // Card Interactions
        case .cardSelect:
            triggerLightImpact()
        case .cardPlay:
            triggerMediumImpact()
        case .cardInvalid:
            triggerError()
        case .cardShuffle:
            triggerCardShuffleSequence()
        case .cardFlip:
            triggerSelectionFeedback()
            
        // Game Events
        case .scoreIncrease:
            triggerSuccessNotification()
        case .trickWon:
            triggerTrickWonSequence()
        case .trickLost:
            triggerLightImpact()
        case .gameVictory:
            triggerVictorySequence()
        case .gameDefeat:
            triggerDefeatSequence()
        case .turnChange:
            triggerSelectionFeedback()
            
        // Menu Navigation
        case .menuSelect:
            triggerLightImpact()
        case .menuConfirm:
            triggerMediumImpact()
        case .menuCancel:
            triggerLightImpact()
        case .menuTransition:
            triggerSelectionFeedback()
            
        // System Events
        case .notification:
            triggerNotificationFeedback()
        case .warning:
            triggerWarningNotification()
        case .error:
            triggerError()
        case .success:
            triggerSuccessNotification()
            
        // Accessibility
        case .focusChange:
            triggerVeryLightImpact()
        case .boundaryReached:
            triggerMediumImpact()
        case .elementActivated:
            triggerSelectionFeedback()
        }
    }
    
    // MARK: - Basic Haptic Generators
    
    private func triggerLightImpact() {
        lightImpactGenerator.impactOccurred()
    }
    
    private func triggerMediumImpact() {
        mediumImpactGenerator.impactOccurred()
    }
    
    private func triggerHeavyImpact() {
        heavyImpactGenerator.impactOccurred()
    }
    
    private func triggerSelectionFeedback() {
        selectionGenerator.selectionChanged()
    }
    
    private func triggerSuccessNotification() {
        notificationGenerator.notificationOccurred(.success)
    }
    
    private func triggerWarningNotification() {
        notificationGenerator.notificationOccurred(.warning)
    }
    
    private func triggerError() {
        notificationGenerator.notificationOccurred(.error)
    }
    
    private func triggerNotificationFeedback() {
        notificationGenerator.notificationOccurred(.warning)
    }
    
    // MARK: - Complex Haptic Sequences
    
    /// Very light haptic for accessibility navigation
    private func triggerVeryLightImpact() {
        // Use system sound as very light haptic alternative
        AudioServicesPlaySystemSound(1519) // Weak haptic
    }
    
    /// Card shuffle haptic sequence
    private func triggerCardShuffleSequence() {
        let sequence: [(TimeInterval, () -> Void)] = [
            (0.0, { [weak self] in self?.triggerLightImpact() }),
            (0.1, { [weak self] in self?.triggerLightImpact() }),
            (0.15, { [weak self] in self?.triggerLightImpact() }),
            (0.25, { [weak self] in self?.triggerMediumImpact() })
        ]
        
        executeHapticSequence(sequence)
    }
    
    /// Trick won celebration sequence
    private func triggerTrickWonSequence() {
        let sequence: [(TimeInterval, () -> Void)] = [
            (0.0, { [weak self] in self?.triggerMediumImpact() }),
            (0.2, { [weak self] in self?.triggerLightImpact() }),
            (0.3, { [weak self] in self?.triggerLightImpact() })
        ]
        
        executeHapticSequence(sequence)
    }
    
    /// Victory celebration haptic sequence
    private func triggerVictorySequence() {
        let sequence: [(TimeInterval, () -> Void)] = [
            (0.0, { [weak self] in self?.triggerHeavyImpact() }),
            (0.2, { [weak self] in self?.triggerMediumImpact() }),
            (0.3, { [weak self] in self?.triggerMediumImpact() }),
            (0.5, { [weak self] in self?.triggerLightImpact() }),
            (0.6, { [weak self] in self?.triggerLightImpact() }),
            (0.8, { [weak self] in self?.triggerSuccessNotification() })
        ]
        
        executeHapticSequence(sequence)
    }
    
    /// Defeat acknowledgment sequence
    private func triggerDefeatSequence() {
        let sequence: [(TimeInterval, () -> Void)] = [
            (0.0, { [weak self] in self?.triggerMediumImpact() }),
            (0.3, { [weak self] in self?.triggerLightImpact() })
        ]
        
        executeHapticSequence(sequence)
    }
    
    // MARK: - Haptic Sequence Execution
    
    private func executeHapticSequence(_ sequence: [(TimeInterval, () -> Void)]) {
        for (delay, action) in sequence {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                action()
            }
        }
    }
    
    // MARK: - Generator Management
    
    private func prepareGenerators() {
        lightImpactGenerator.prepare()
        mediumImpactGenerator.prepare()
        heavyImpactGenerator.prepare()
        selectionGenerator.prepare()
        notificationGenerator.prepare()
    }
    
    /// Prepare specific generator for immediate use
    func prepareForImmediateUse(_ feedback: HapticFeedback) {
        switch feedback {
        case .cardSelect, .cardFlip, .trickLost, .menuSelect, .menuCancel, .focusChange:
            lightImpactGenerator.prepare()
        case .cardPlay, .gameDefeat, .menuConfirm, .boundaryReached:
            mediumImpactGenerator.prepare()
        case .gameVictory:
            heavyImpactGenerator.prepare()
        case .turnChange, .menuTransition, .elementActivated:
            selectionGenerator.prepare()
        case .scoreIncrease, .success, .trickWon, .notification, .warning, .error, .cardInvalid:
            notificationGenerator.prepare()
        case .cardShuffle:
            // Prepare multiple generators for sequence
            lightImpactGenerator.prepare()
            mediumImpactGenerator.prepare()
        }
    }
    
    // MARK: - Settings Management
    
    /// Enable or disable haptic feedback
    func setHapticsEnabled(_ enabled: Bool) {
        isHapticsEnabled = enabled
        saveHapticPreferences()
        
        if enabled {
            prepareGenerators()
        }
    }
    
    /// Check if device supports haptics
    var supportsHaptics: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
    
    // MARK: - Persistence
    
    private func loadHapticPreferences() {
        isHapticsEnabled = UserDefaults.standard.object(forKey: "haptics_enabled") as? Bool ?? true
    }
    
    private func saveHapticPreferences() {
        UserDefaults.standard.set(isHapticsEnabled, forKey: "haptics_enabled")
    }
    
    // MARK: - Accessibility Integration
    
    /// Provide haptic feedback for accessibility interactions
    func accessibilityFeedback(for action: String) {
        switch action.lowercased() {
        case "select", "tap":
            trigger(.elementActivated)
        case "focus":
            trigger(.focusChange)
        case "boundary":
            trigger(.boundaryReached)
        case "error", "invalid":
            trigger(.error)
        case "success", "completed":
            trigger(.success)
        default:
            trigger(.focusChange)
        }
    }
    
    // MARK: - Game-Specific Haptic Helpers
    
    /// Provide contextual haptic for card interactions
    func cardInteractionFeedback(isValid: Bool, isSpecialCard: Bool = false) {
        if isValid {
            trigger(isSpecialCard ? .trickWon : .cardPlay)
        } else {
            trigger(.cardInvalid)
        }
    }
    
    /// Provide haptic feedback for score changes
    func scoreChangeFeedback(pointsEarned: Int) {
        if pointsEarned > 0 {
            trigger(pointsEarned >= 10 ? .trickWon : .scoreIncrease)
        }
    }
    
    /// Provide haptic feedback for Romanian Septica specific events
    func septicaGameFeedback(for event: SepticaGameEvent) {
        switch event {
        case .sevenPlayed:
            triggerTrickWonSequence() // Special feedback for the key card
        case .lastCardOfRound:
            trigger(.turnChange)
        case .roundComplete:
            trigger(.scoreIncrease)
        case .gameComplete(won: let won):
            trigger(won ? .gameVictory : .gameDefeat)
        }
    }
}

// MARK: - Septica Game Events

enum SepticaGameEvent {
    case sevenPlayed
    case lastCardOfRound
    case roundComplete
    case gameComplete(won: Bool)
}

// MARK: - SwiftUI Integration

extension View {
    /// Add haptic feedback to any view tap
    func hapticFeedback(_ feedback: HapticManager.HapticFeedback, manager: HapticManager) -> some View {
        self.onTapGesture {
            manager.trigger(feedback)
        }
    }
    
    /// Add contextual haptic feedback based on interaction state
    func contextualHaptic(
        isEnabled: Bool,
        success: HapticManager.HapticFeedback,
        failure: HapticManager.HapticFeedback,
        manager: HapticManager
    ) -> some View {
        self.onTapGesture {
            manager.trigger(isEnabled ? success : failure)
        }
    }
}

// MARK: - Preview Support

#if DEBUG
extension HapticManager {
    /// Create preview instance that doesn't trigger actual haptics
    static let preview: HapticManager = {
        let manager = HapticManager()
        manager.isHapticsEnabled = false // Disable for previews
        return manager
    }()
    
    /// Test all haptic types
    func testAllHaptics() {
        let testSequence: [HapticFeedback] = [
            .cardSelect, .cardPlay, .scoreIncrease, .gameVictory,
            .menuSelect, .success, .focusChange
        ]
        
        for (index, feedback) in testSequence.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.5) {
                self.trigger(feedback)
            }
        }
    }
}
#endif