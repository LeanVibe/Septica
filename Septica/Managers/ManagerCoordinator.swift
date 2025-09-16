//
//  ManagerCoordinator.swift
//  Septica
//
//  Central coordination system for all managers in Romanian Septica card game
//  Provides unified interface and manager lifecycle management
//

import SwiftUI
import Combine
import CloudKit

/// Central coordinator for all application managers
/// Ensures proper initialization order and cross-manager communication
@MainActor
class ManagerCoordinator: ObservableObject {
    
    // MARK: - Manager Instances
    
    @Published private(set) var errorManager: ErrorManager
    @Published private(set) var performanceMonitor: PerformanceMonitor
    @Published private(set) var audioManager: AudioManager
    @Published private(set) var hapticManager: HapticManager
    @Published private(set) var animationManager: AnimationManager
    @Published private(set) var accessibilityManager: AccessibilityManager
    
    // MARK: - CloudKit Manager Instances
    
    @Published private(set) var cloudKitManager: SepticaCloudKitManager?
    @Published private(set) var cloudKitSyncEngine: CloudKitSyncEngine?
    @Published private(set) var culturalAchievementSystem: CulturalAchievementSystem?
    @Published private(set) var playerProfileService: PlayerProfileService?
    @Published private(set) var rewardChestService: RewardChestService?
    @Published private(set) var romanianStrategyAnalyzer: RomanianStrategyAnalyzer?
    
    // MARK: - Coordinator State
    
    @Published var isInitialized = false
    @Published var hasErrors = false
    @Published var systemStatus: SystemStatus = .initializing
    
    private var cancellables = Set<AnyCancellable>()
    
    enum SystemStatus: String, CaseIterable {
        case initializing = "Initializing"
        case ready = "Ready"
        case degraded = "Degraded"
        case error = "Error"
    }
    
    // MARK: - Initialization
    
    init() {
        // Initialize managers in proper dependency order
        
        // Phase 1: Core Infrastructure
        self.errorManager = ErrorManager()
        self.performanceMonitor = PerformanceMonitor()
        
        // Phase 2: Audio/Haptic/UI
        self.audioManager = AudioManager()
        self.hapticManager = HapticManager()
        self.animationManager = AnimationManager()
        self.accessibilityManager = AccessibilityManager()
        
        // Phase 3: CloudKit Services (initialized after basic setup)
        self.cloudKitManager = nil
        self.cloudKitSyncEngine = nil
        self.culturalAchievementSystem = nil
        self.playerProfileService = nil
        self.rewardChestService = nil
        self.romanianStrategyAnalyzer = nil
        
        Task {
            await initializeManagers()
        }
    }
    
    private func initializeManagers() async {
        systemStatus = .initializing
        
        do {
            // Initialize CloudKit services with proper dependencies
            await initializeCloudKitServices()
            
            // Setup cross-manager communication
            setupManagerIntegration()
            
            // Start performance monitoring
            performanceMonitor.startMonitoring()
            
            // Configure managers based on accessibility settings
            configureForAccessibility()
            
            // Configure managers based on device capabilities
            configureForDevice()
            
            // Validate all managers are working
            try await validateManagerHealth()
            
            systemStatus = .ready
            isInitialized = true
            
            // Manager system initialized successfully - no error to report
            
        } catch {
            systemStatus = .error
            hasErrors = true
            errorManager.reportError(.criticalSystemError(error: "Manager initialization failed: \(error)"), 
                                   context: "System startup")
        }
    }
    
    // MARK: - CloudKit Services Initialization
    
    private func initializeCloudKitServices() async {
        // Initialize CloudKit services with proper dependency injection
        
        // Phase 1: Core CloudKit Manager
        self.cloudKitManager = SepticaCloudKitManager()
        
        guard let cloudKitManager = self.cloudKitManager else { return }
        
        // Phase 2: CloudKit-dependent services
        self.playerProfileService = PlayerProfileService(
            cloudKitManager: cloudKitManager,
            errorManager: errorManager
        )
        
        guard let playerProfileService = self.playerProfileService else { return }
        
        // Phase 3: Services that depend on other CloudKit services
        self.culturalAchievementSystem = CulturalAchievementSystem(
            playerProfileService: playerProfileService,
            audioManager: audioManager,
            hapticManager: hapticManager
        )
        
        guard let culturalAchievementSystem = self.culturalAchievementSystem else { return }
        
        self.rewardChestService = RewardChestService(
            cloudKitManager: cloudKitManager,
            culturalSystem: culturalAchievementSystem
        )
        
        self.romanianStrategyAnalyzer = RomanianStrategyAnalyzer()
        
        self.cloudKitSyncEngine = CloudKitSyncEngine(cloudKitManager: cloudKitManager)
    }
    
    // MARK: - Manager Integration
    
    private func setupManagerIntegration() {
        // Error Manager Integration
        errorManager.objectWillChange
            .sink { [weak self] _ in
                self?.handleErrorManagerUpdate()
            }
            .store(in: &cancellables)
        
        // Performance Monitor Integration
        performanceMonitor.objectWillChange
            .sink { [weak self] _ in
                self?.handlePerformanceUpdate()
            }
            .store(in: &cancellables)
        
        // Accessibility Manager Integration
        accessibilityManager.objectWillChange
            .sink { [weak self] _ in
                self?.handleAccessibilityUpdate()
            }
            .store(in: &cancellables)
        
        // Animation Manager Integration
        animationManager.objectWillChange
            .sink { [weak self] _ in
                self?.handleAnimationUpdate()
            }
            .store(in: &cancellables)
        
        // Cross-manager notifications
        NotificationCenter.default.publisher(for: .reduceAnimations)
            .sink { [weak self] _ in
                self?.handleReduceAnimationsRequest()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .performanceMemoryWarning)
            .sink { [weak self] _ in
                self?.handleMemoryWarning()
            }
            .store(in: &cancellables)
            
        // MARK: - CloudKit Manager Integration (Optional Services)
        
        // CloudKit Manager Integration
        cloudKitManager?.objectWillChange
            .sink { [weak self] _ in
                self?.handleCloudKitManagerUpdate()
            }
            .store(in: &cancellables)
        
        // CloudKit Sync Engine Integration
        cloudKitSyncEngine?.objectWillChange
            .sink { [weak self] _ in
                self?.handleCloudKitSyncUpdate()
            }
            .store(in: &cancellables)
            
        // Cultural Achievement System Integration
        culturalAchievementSystem?.objectWillChange
            .sink { [weak self] _ in
                self?.handleCulturalAchievementUpdate()
            }
            .store(in: &cancellables)
            
        // Performance monitoring integration with CloudKit
        cloudKitManager?.$syncStatus
            .sink { [weak self] status in
                // Monitor CloudKit sync performance impact
                self?.performanceMonitor.reportCloudKitSyncStatus(status)
            }
            .store(in: &cancellables)
            
        // Error handling integration with CloudKit
        cloudKitManager?.$conflictsRequiringAttention
            .sink { [weak self] conflicts in
                if !conflicts.isEmpty {
                    self?.errorManager.reportError(
                        .gameStateCorruption(details: "CloudKit sync conflicts detected"),
                        context: "CloudKit synchronization"
                    )
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Manager Update Handlers
    
    private func handleErrorManagerUpdate() {
        hasErrors = errorManager.isShowingError
        
        // Provide haptic feedback for errors
        if let currentError = errorManager.currentError {
            switch errorManager.determineSeverity(for: currentError) {
            case .critical, .error:
                hapticManager.trigger(.error)
            case .warning:
                hapticManager.trigger(.warning)
            case .info:
                break // No haptic for info messages
            }
        }
    }
    
    private func handlePerformanceUpdate() {
        // Adjust system behavior based on performance
        if !performanceMonitor.isPerformanceAcceptable {
            systemStatus = .degraded
            
            // Automatically reduce animations if performance is poor
            animationManager.stopAllAnimations()
            
            // Inform accessibility manager about performance issues
            accessibilityManager.announceGameState("Performance optimization applied")
            
            // Report performance warning
            errorManager.reportError(.performanceWarning(metric: "System Performance", value: 0.0), 
                                   context: "Automatic optimization")
        } else if systemStatus == .degraded {
            systemStatus = .ready
        }
    }
    
    private func handleAccessibilityUpdate() {
        // Update animation manager for accessibility preferences
        if accessibilityManager.isReduceMotionEnabled {
            animationManager.stopAllAnimations()
        }
        
        // Update haptic manager for accessibility preferences
        switch accessibilityManager.hapticFeedbackLevel {
        case .off:
            hapticManager.setHapticsEnabled(false)
        case .minimal:
            hapticManager.setHapticsEnabled(true)
            // Could implement reduced haptic intensity
        case .full:
            hapticManager.setHapticsEnabled(true)
        }
        
        // Update audio manager for accessibility preferences
        switch accessibilityManager.audioDescriptionLevel {
        case .off:
            audioManager.setAccessibilityAudioEnabled(false)
        case .essential, .full:
            audioManager.setAccessibilityAudioEnabled(true)
        }
    }
    
    private func handleAnimationUpdate() {
        // Coordinate animations with haptics
        if animationManager.isAnimating {
            // Prepare haptic generators for potential feedback
            hapticManager.prepareForImmediateUse(.cardPlay)
        }
    }
    
    private func handleReduceAnimationsRequest() {
        animationManager.stopAllAnimations()
        accessibilityManager.announceGameState("Animations disabled for better performance")
    }
    
    private func handleMemoryWarning() {
        // Coordinate memory cleanup across all managers
        audioManager.pauseAllAudio()
        animationManager.stopAllAnimations()
        
        // CloudKit memory cleanup
        cloudKitSyncEngine?.pauseSyncOperations()
        
        // Report memory warning
        hapticManager.trigger(.warning)
        accessibilityManager.announceGameState("Memory optimization applied")
    }
    
    // MARK: - CloudKit Update Handlers
    
    private func handleCloudKitManagerUpdate() {
        guard let cloudKitManager = self.cloudKitManager else { return }
        
        // Update system status based on CloudKit availability
        if !cloudKitManager.isAvailable {
            systemStatus = .degraded
        } else if systemStatus == .degraded && cloudKitManager.isAvailable {
            systemStatus = .ready
        }
        
        // Provide haptic feedback for sync events
        switch cloudKitManager.syncStatus {
        case .syncing(_):
            hapticManager.trigger(.cardSelect)
        case .success:
            hapticManager.trigger(.success)
        default:
            break
        }
    }
    
    private func handleCloudKitSyncUpdate() {
        guard let cloudKitSyncEngine = self.cloudKitSyncEngine else { return }
        
        // Monitor sync performance impact
        let syncProgress = cloudKitSyncEngine.syncProgress
        performanceMonitor.reportCloudKitPerformanceImpact(syncProgress: syncProgress)
        
        // Report significant sync milestones
        if syncProgress >= 1.0 {
            accessibilityManager.announceGameState("Romanian cultural data synchronized")
        }
    }
    
    private func handleCulturalAchievementUpdate() {
        guard let culturalAchievementSystem = self.culturalAchievementSystem else { return }
        
        // Handle Romanian cultural achievement unlocks
        if let latestAchievement = culturalAchievementSystem.unlockedAchievements.last {
            audioManager.playSepticaGameAudio(for: .gameComplete(won: true))
            hapticManager.trigger(.success)
            accessibilityManager.announceGameState("Achievement unlocked: \(latestAchievement.title)")
        } else {
            // General cultural progress update
            hapticManager.trigger(.success)
            accessibilityManager.announceGameState("Romanian cultural progress updated")
        }
    }
    
    // MARK: - Configuration
    
    private func configureForAccessibility() {
        // Configure animation speed based on accessibility settings
        let _ = accessibilityManager.gameSpeedAdjustment == .slow ? 1.5 : 
                accessibilityManager.gameSpeedAdjustment == .fast ? 0.7 : 1.0
        
        // Apply speed adjustments (would be implemented in animation manager)
        // animationManager.setSpeedMultiplier(speedMultiplier)
        
        // Configure haptic intensity based on user needs
        if accessibilityManager.hapticFeedbackLevel == .off {
            hapticManager.setHapticsEnabled(false)
        }
        
        // Configure audio descriptions
        if accessibilityManager.audioDescriptionLevel == .off {
            audioManager.setAccessibilityAudioEnabled(false)
        }
    }
    
    private func configureForDevice() {
        // Configure haptics based on device capabilities
        if !hapticManager.supportsHaptics {
            hapticManager.setHapticsEnabled(false)
            accessibilityManager.announceGameState("Haptic feedback not available on this device")
        }
        
        // Configure audio based on device capabilities
        // Additional device-specific optimizations could be added here
    }
    
    // MARK: - Manager Health Validation
    
    private func validateManagerHealth() async throws {
        var issues: [String] = []
        
        // Validate Error Manager
        if errorManager.currentError != nil && errorManager.determineSeverity(for: errorManager.currentError!) == .critical {
            issues.append("Critical error in error manager")
        }
        
        // Validate Performance Monitor
        if performanceMonitor.currentFPS < 30 {
            issues.append("Performance monitor showing very low FPS")
        }
        
        // Validate Audio Manager
        if !audioManager.isSoundEnabled && !audioManager.isMusicEnabled {
            // This might be user preference, so just log it
            print("⚠️ All audio disabled")
        }
        
        if !issues.isEmpty {
            throw ManagerError.healthValidationFailed(issues: issues)
        }
    }
    
    // MARK: - Public Interface
    
    /// Start a new game with proper manager coordination
    func startNewGame() {
        guard isInitialized else {
            errorManager.reportError(.criticalSystemError(error: "Managers not initialized"), 
                                   context: "Game start")
            return
        }
        
        // Coordinate game start across all managers
        audioManager.playSepticaGameAudio(for: .newGame)
        hapticManager.septicaGameFeedback(for: .sevenPlayed)
        accessibilityManager.announceGameEvent(.gameStarted)
        animationManager.animateLoading(isLoading: false)
        
        // Record game start performance
        performanceMonitor.recordMetric(name: "GameStart", value: 1, unit: "events")
    }
    
    /// Handle card play with full manager coordination
    func handleCardPlay(card: Card, isValid: Bool) {
        // Audio feedback
        audioManager.playSepticaGameAudio(for: isValid ? .cardPlayValid(isSpecialCard: card.value == 7) : .cardPlayInvalid)
        
        // Haptic feedback
        hapticManager.cardInteractionFeedback(isValid: isValid, isSpecialCard: card.value == 7)
        
        // Accessibility announcement
        if isValid {
            accessibilityManager.announceGameEvent(.cardPlayed(card: card, player: "You"))
        } else {
            accessibilityManager.announceGameEvent(.invalidMove)
        }
        
        // Animation coordination
        if isValid {
            animationManager.animateCardPlay(from: .zero, to: .zero) {
                // Animation completion
            }
        }
        
        // Performance tracking
        performanceMonitor.recordMetric(name: "CardPlay", value: 1, unit: "actions")
    }
    
    /// Handle game completion with celebration coordination
    func handleGameComplete(playerWon: Bool) {
        // Audio celebration/commiseration
        audioManager.playSepticaGameAudio(for: .gameComplete(won: playerWon))
        
        // Haptic feedback sequence
        hapticManager.septicaGameFeedback(for: .gameComplete(won: playerWon))
        
        // Accessibility announcement
        accessibilityManager.announceGameEvent(.gameComplete(winner: playerWon ? "You" : "AI"))
        
        // Victory/defeat animation
        if playerWon {
            animationManager.animateVictory {
                // Victory animation complete
            }
        } else {
            animationManager.animateDefeat {
                // Defeat animation complete
            }
        }
        
        // Performance metrics
        performanceMonitor.recordMetric(name: "GameComplete", value: 1, unit: "games")
    }
    
    /// Get system health status
    func getSystemHealth() -> SystemHealth {
        return SystemHealth(
            status: systemStatus,
            errorCount: errorManager.errorHistory.count,
            performanceLevel: performanceMonitor.isPerformanceAcceptable ? "Good" : "Poor",
            memoryUsage: performanceMonitor.memoryUsage,
            isAccessibilityActive: accessibilityManager.isVoiceOverEnabled || accessibilityManager.isSwitchControlEnabled,
            managersActive: [
                "ErrorManager": true,
                "PerformanceMonitor": performanceMonitor.currentFPS > 0,
                "AudioManager": audioManager.isSoundEnabled || audioManager.isMusicEnabled,
                "HapticManager": hapticManager.isHapticsEnabled,
                "AnimationManager": !animationManager.isAnimating, // Inverted - no constant animation is good
                "AccessibilityManager": true
            ]
        )
    }
    
    /// Emergency shutdown for critical errors
    func emergencyShutdown(reason: String) {
        // Stop all activities
        audioManager.pauseAllAudio()
        animationManager.stopAllAnimations()
        hapticManager.trigger(.error)
        
        // Log critical error
        errorManager.reportError(.criticalSystemError(error: "Emergency shutdown: \(reason)"), 
                               context: "System emergency")
        
        // Accessibility notification
        accessibilityManager.announceGameState("System emergency - application will close")
        
        systemStatus = .error
        hasErrors = true
    }
}

// MARK: - Supporting Types

enum ManagerError: Error, LocalizedError {
    case healthValidationFailed(issues: [String])
    case initializationTimeout
    case managerNotResponding(String)
    
    var errorDescription: String? {
        switch self {
        case .healthValidationFailed(let issues):
            return "Manager health check failed: \(issues.joined(separator: ", "))"
        case .initializationTimeout:
            return "Manager initialization timed out"
        case .managerNotResponding(let manager):
            return "\(manager) is not responding"
        }
    }
}

struct SystemHealth {
    let status: ManagerCoordinator.SystemStatus
    let errorCount: Int
    let performanceLevel: String
    let memoryUsage: Int64
    let isAccessibilityActive: Bool
    let managersActive: [String: Bool]
}

// MARK: - SwiftUI Environment Integration

extension EnvironmentValues {
    private struct ManagerCoordinatorKey: EnvironmentKey {
        static let defaultValue = ManagerCoordinator()
    }
    
    var managerCoordinator: ManagerCoordinator {
        get { self[ManagerCoordinatorKey.self] }
        set { self[ManagerCoordinatorKey.self] = newValue }
    }
}

// MARK: - Extensions for Manager Access

extension ManagerCoordinator {
    /// Convenience accessor for error reporting
    func reportError(_ error: ErrorManager.GameError, context: String = "") {
        errorManager.reportError(error, context: context)
    }
    
    /// Convenience accessor for performance metrics
    func recordMetric(name: String, value: Double, unit: String) {
        performanceMonitor.recordMetric(name: name, value: value, unit: unit)
    }
    
    /// Convenience accessor for haptic feedback
    func triggerHaptic(_ feedback: HapticManager.HapticFeedback) {
        hapticManager.trigger(feedback)
    }
    
    /// Convenience accessor for audio
    func playAudio(_ sound: AudioManager.SoundEffect) {
        audioManager.playSound(sound)
    }
    
    /// Convenience accessor for accessibility announcements
    func announceToUser(_ message: String) {
        accessibilityManager.announceGameState(message)
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let managerCoordinatorReady = Notification.Name("manager_coordinator_ready")
    static let systemHealthChanged = Notification.Name("system_health_changed")
}

// MARK: - Preview Support

#if DEBUG
extension ManagerCoordinator {
    static let preview: ManagerCoordinator = {
        let coordinator = ManagerCoordinator()
        return coordinator
    }()
}
#endif