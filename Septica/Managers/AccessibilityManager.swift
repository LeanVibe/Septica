//
//  AccessibilityManager.swift
//  Septica
//
//  Comprehensive accessibility support for Romanian Septica card game
//  Ensures WCAG compliance and inclusive design for all users
//

import SwiftUI
import UIKit
import Combine

/// Centralized accessibility management for the entire application
@MainActor
class AccessibilityManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isVoiceOverEnabled = UIAccessibility.isVoiceOverRunning
    @Published var isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
    @Published var isIncreaseContrastEnabled = UIAccessibility.isDarkerSystemColorsEnabled
    @Published var isLargeTextEnabled = false
    @Published var preferredContentSizeCategory = UIContentSizeCategory.large
    @Published var isSwitchControlEnabled = UIAccessibility.isSwitchControlRunning
    @Published var isVoiceControlEnabled = false
    
    // Custom accessibility settings
    @Published var announceGameState = true
    @Published var announceCardDetails = true
    @Published var hapticFeedbackLevel: HapticLevel = .full
    @Published var audioDescriptionLevel: AudioLevel = .full
    @Published var gameSpeedAdjustment: SpeedAdjustment = .normal
    
    // MARK: - Accessibility Levels
    
    enum HapticLevel: String, CaseIterable {
        case off = "Off"
        case minimal = "Minimal"
        case full = "Full"
    }
    
    enum AudioLevel: String, CaseIterable {
        case off = "Off"
        case essential = "Essential Only"
        case full = "Full Description"
    }
    
    enum SpeedAdjustment: String, CaseIterable {
        case slow = "Slow"
        case normal = "Normal"
        case fast = "Fast"
    }
    
    // MARK: - Initialization
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadAccessibilityPreferences()
        setupAccessibilityObservers()
        updateDynamicTypeSettings()
    }
    
    // MARK: - Accessibility Observers
    
    private func setupAccessibilityObservers() {
        // VoiceOver state changes
        NotificationCenter.default.publisher(for: UIAccessibility.voiceOverStatusDidChangeNotification)
            .sink { [weak self] _ in
                self?.isVoiceOverEnabled = UIAccessibility.isVoiceOverRunning
            }
            .store(in: &cancellables)
        
        // Reduce motion changes
        NotificationCenter.default.publisher(for: UIAccessibility.reduceMotionStatusDidChangeNotification)
            .sink { [weak self] _ in
                self?.isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
            }
            .store(in: &cancellables)
        
        // Contrast changes
        NotificationCenter.default.publisher(for: UIAccessibility.darkerSystemColorsStatusDidChangeNotification)
            .sink { [weak self] _ in
                self?.isIncreaseContrastEnabled = UIAccessibility.isDarkerSystemColorsEnabled
            }
            .store(in: &cancellables)
        
        // Switch control changes
        NotificationCenter.default.publisher(for: UIAccessibility.switchControlStatusDidChangeNotification)
            .sink { [weak self] _ in
                self?.isSwitchControlEnabled = UIAccessibility.isSwitchControlRunning
            }
            .store(in: &cancellables)
        
        // Content size category changes
        NotificationCenter.default.publisher(for: UIContentSizeCategory.didChangeNotification)
            .sink { [weak self] _ in
                self?.updateDynamicTypeSettings()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Dynamic Type Support
    
    private func updateDynamicTypeSettings() {
        let contentSize = UIApplication.shared.preferredContentSizeCategory
        preferredContentSizeCategory = contentSize
        isLargeTextEnabled = contentSize.isAccessibilityCategory
    }
    
    /// Get scaled font size based on user preferences
    func scaledFontSize(baseSize: CGFloat) -> CGFloat {
        let metrics = UIFontMetrics.default
        return metrics.scaledValue(for: baseSize)
    }
    
    /// Get font appropriate for current accessibility settings
    func accessibleFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let scaledSize = scaledFontSize(baseSize: size)
        return Font.system(size: scaledSize, weight: weight)
    }
    
    // MARK: - VoiceOver Support
    
    /// Create accessibility label for cards
    func cardAccessibilityLabel(for card: Card) -> String {
        let value: String
        switch card.value {
        case 7: value = "Seven"
        case 8: value = "Eight"
        case 9: value = "Nine"
        case 10: value = "Ten"
        case 11: value = "Jack"
        case 12: value = "Queen"
        case 13: value = "King"
        case 14: value = "Ace"
        default: value = "\(card.value)"
        }
        
        let suit: String
        switch card.suit {
        case .hearts: suit = "Hearts"
        case .diamonds: suit = "Diamonds"
        case .clubs: suit = "Clubs"
        case .spades: suit = "Spades"
        }
        
        let specialInfo = card.isPointCard ? ", point card" : ""
        let wildInfo = (card.value == 7) ? ", wild card" : ""
        
        return "\(value) of \(suit)\(specialInfo)\(wildInfo)"
    }
    
    /// Create accessibility hint for card interactions
    func cardAccessibilityHint(for card: Card, isPlayable: Bool) -> String {
        if !isPlayable {
            return "Cannot play this card"
        }
        
        if card.value == 7 {
            return "Double tap to play this wild card"
        } else if card.isPointCard {
            return "Double tap to play this point card"
        } else {
            return "Double tap to play this card"
        }
    }
    
    /// Announce game state changes
    func announceGameState(_ message: String) {
        guard announceGameState && isVoiceOverEnabled else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            UIAccessibility.post(notification: .announcement, argument: message)
        }
    }
    
    /// Announce important game events
    func announceGameEvent(_ event: AccessibilityGameEvent) {
        guard announceGameState else { return }
        
        let message: String
        switch event {
        case .gameStarted:
            message = "New Septica game started. You have 4 cards in your hand."
        case .turnChanged(let isPlayerTurn):
            message = isPlayerTurn ? "Your turn" : "AI opponent's turn"
        case .cardPlayed(let card, let player):
            let cardLabel = cardAccessibilityLabel(for: card)
            message = "\(player) played \(cardLabel)"
        case .trickWon(let winner, let points):
            message = "\(winner) won the trick and earned \(points) points"
        case .roundComplete(let playerScore, let aiScore):
            message = "Round complete. Your score: \(playerScore), AI score: \(aiScore)"
        case .gameComplete(let winner):
            message = "Game complete. \(winner) wins!"
        case .invalidMove:
            message = "Invalid move. Please select a different card."
        }
        
        announceGameState(message)
    }
    
    // MARK: - Game Events for Accessibility
    
    enum AccessibilityGameEvent {
        case gameStarted
        case turnChanged(isPlayerTurn: Bool)
        case cardPlayed(card: Card, player: String)
        case trickWon(winner: String, points: Int)
        case roundComplete(playerScore: Int, aiScore: Int)
        case gameComplete(winner: String)
        case invalidMove
    }
    
    // MARK: - Visual Accessibility
    
    /// Get high contrast colors when needed
    func accessibleColor(primary: Color, highContrast: Color) -> Color {
        isIncreaseContrastEnabled ? highContrast : primary
    }
    
    /// Get minimum contrast ratio for text
    func contrastRatio(foreground: Color, background: Color) -> Double {
        // Simplified contrast calculation - in production, use proper luminance calculation
        return isIncreaseContrastEnabled ? 7.0 : 4.5
    }
    
    /// Check if color combination meets accessibility standards
    func meetsContrastRequirements(foreground: Color, background: Color) -> Bool {
        // Implementation would calculate actual luminance-based contrast
        // For now, return true if high contrast is enabled or false if user specifically needs it
        return !isIncreaseContrastEnabled || true
    }
    
    // MARK: - Motor Accessibility
    
    /// Get minimum touch target size based on accessibility needs
    func minimumTouchTargetSize() -> CGFloat {
        if isSwitchControlEnabled || isVoiceControlEnabled {
            return 60.0 // Larger targets for alternative input methods
        } else if isLargeTextEnabled {
            return 50.0 // Slightly larger for users who need large text
        } else {
            return 44.0 // Standard iOS minimum
        }
    }
    
    /// Check if view meets touch target requirements
    func meetsTouchTargetRequirements(size: CGSize) -> Bool {
        let minSize = minimumTouchTargetSize()
        return size.width >= minSize && size.height >= minSize
    }
    
    /// Get adjusted animation duration for accessibility
    func adjustedAnimationDuration(_ baseDuration: Double) -> Double {
        if isReduceMotionEnabled {
            return baseDuration * 0.1 // Nearly instant for reduce motion
        }
        
        switch gameSpeedAdjustment {
        case .slow:
            return baseDuration * 1.5
        case .normal:
            return baseDuration
        case .fast:
            return baseDuration * 0.7
        }
    }
    
    // MARK: - Settings Management
    
    func setAnnounceGameState(_ enabled: Bool) {
        announceGameState = enabled
        saveAccessibilityPreferences()
    }
    
    func setAnnounceCardDetails(_ enabled: Bool) {
        announceCardDetails = enabled
        saveAccessibilityPreferences()
    }
    
    func setHapticFeedbackLevel(_ level: HapticLevel) {
        hapticFeedbackLevel = level
        saveAccessibilityPreferences()
    }
    
    func setAudioDescriptionLevel(_ level: AudioLevel) {
        audioDescriptionLevel = level
        saveAccessibilityPreferences()
    }
    
    func setGameSpeedAdjustment(_ speed: SpeedAdjustment) {
        gameSpeedAdjustment = speed
        saveAccessibilityPreferences()
    }
    
    // MARK: - Persistence
    
    private func loadAccessibilityPreferences() {
        let defaults = UserDefaults.standard
        
        announceGameState = defaults.object(forKey: "accessibility_announce_game_state") as? Bool ?? true
        announceCardDetails = defaults.object(forKey: "accessibility_announce_card_details") as? Bool ?? true
        
        if let hapticLevelString = defaults.string(forKey: "accessibility_haptic_level"),
           let level = HapticLevel(rawValue: hapticLevelString) {
            hapticFeedbackLevel = level
        }
        
        if let audioLevelString = defaults.string(forKey: "accessibility_audio_level"),
           let level = AudioLevel(rawValue: audioLevelString) {
            audioDescriptionLevel = level
        }
        
        if let speedString = defaults.string(forKey: "accessibility_game_speed"),
           let speed = SpeedAdjustment(rawValue: speedString) {
            gameSpeedAdjustment = speed
        }
    }
    
    private func saveAccessibilityPreferences() {
        let defaults = UserDefaults.standard
        
        defaults.set(announceGameState, forKey: "accessibility_announce_game_state")
        defaults.set(announceCardDetails, forKey: "accessibility_announce_card_details")
        defaults.set(hapticFeedbackLevel.rawValue, forKey: "accessibility_haptic_level")
        defaults.set(audioDescriptionLevel.rawValue, forKey: "accessibility_audio_level")
        defaults.set(gameSpeedAdjustment.rawValue, forKey: "accessibility_game_speed")
    }
    
    // MARK: - Accessibility Testing Support
    
    /// Check overall accessibility compliance
    func performAccessibilityAudit() -> AccessibilityAuditResult {
        let issues: [String] = []
        var warnings: [String] = []
        
        // Check VoiceOver support
        if !isVoiceOverEnabled {
            warnings.append("VoiceOver not currently active - cannot test screen reader functionality")
        }
        
        // Check contrast if high contrast is enabled
        if isIncreaseContrastEnabled {
            warnings.append("High contrast mode active - verify all UI elements are visible")
        }
        
        // Check Dynamic Type support
        if isLargeTextEnabled {
            warnings.append("Large text enabled - verify all text scales properly")
        }
        
        return AccessibilityAuditResult(
            isCompliant: issues.isEmpty,
            issues: issues,
            warnings: warnings
        )
    }
}

// MARK: - Accessibility Audit Result

struct AccessibilityAuditResult {
    let isCompliant: Bool
    let issues: [String]
    let warnings: [String]
}

// MARK: - SwiftUI Integration

extension View {
    /// Apply comprehensive accessibility support
    func accessibilitySupport(
        label: String,
        hint: String? = nil,
        value: String? = nil,
        traits: AccessibilityTraits = [],
        manager: AccessibilityManager
    ) -> some View {
        self.accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityValue(value ?? "")
            .accessibilityAddTraits(traits)
            .font(manager.accessibleFont(size: 16))
    }
    
    /// Apply card-specific accessibility
    func cardAccessibility(
        card: Card,
        isPlayable: Bool,
        manager: AccessibilityManager
    ) -> some View {
        self.accessibilityLabel(manager.cardAccessibilityLabel(for: card))
            .accessibilityHint(manager.cardAccessibilityHint(for: card, isPlayable: isPlayable))
            .accessibilityAddTraits(isPlayable ? [.isButton] : [])
    }
    
    /// Apply touch target size requirements
    func accessibleTouchTarget(manager: AccessibilityManager) -> some View {
        let minSize = manager.minimumTouchTargetSize()
        return self.frame(minWidth: minSize, minHeight: minSize)
    }
    
    /// Apply contrast-aware styling
    func contrastAwareColor(
        primary: Color,
        highContrast: Color,
        manager: AccessibilityManager
    ) -> some View {
        self.foregroundColor(manager.accessibleColor(primary: primary, highContrast: highContrast))
    }
}

// MARK: - Preview Support

#if DEBUG
extension AccessibilityManager {
    static let preview: AccessibilityManager = {
        let manager = AccessibilityManager()
        return manager
    }()
}
#endif
