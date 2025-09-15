//
//  AchievementCelebrationManager.swift
//  Septica
//
//  Romanian Cultural Achievement Celebration System - Sprint 2
//  Orchestrates beautiful heritage-inspired achievement celebrations
//

import Foundation
import SwiftUI
import Combine
import AVFoundation
import os.log

/// Manages Romanian cultural achievement celebrations with authentic heritage elements
@MainActor
class AchievementCelebrationManager: ObservableObject {
    
    // MARK: - Dependencies
    
    private let logger = Logger(subsystem: "dev.leanvibe.game.Septica", category: "AchievementCelebrationManager")
    private let audioManager: AudioManager?
    private let hapticManager: HapticManager?
    
    // MARK: - Published Celebration State
    
    @Published var currentCelebration: AchievementCelebration?
    @Published var celebrationQueue: [AchievementCelebration] = []
    @Published var isPerformingCelebration: Bool = false
    @Published var celebrationHistory: [CompletedCelebration] = []
    
    // MARK: - Romanian Cultural Celebration Configuration
    
    @Published var culturalCelebrationSettings: CulturalCelebrationSettings = CulturalCelebrationSettings()
    @Published var folkloreAnimationEnabled: Bool = true
    @Published var traditionalMusicEnabled: Bool = true
    @Published var hapticCulturalPatterns: Bool = true
    
    // MARK: - Celebration Performance Metrics
    
    @Published var celebrationMetrics: CelebrationMetrics = CelebrationMetrics()
    private var cancellables: Set<AnyCancellable> = []
    
    // MARK: - Initialization
    
    init(audioManager: AudioManager? = nil, hapticManager: HapticManager? = nil) {
        self.audioManager = audioManager
        self.hapticManager = hapticManager
        
        setupCelebrationObservers()
        setupCulturalSettings()
    }
    
    // MARK: - Achievement Celebration Orchestration
    
    /// Trigger a Romanian cultural achievement celebration
    func celebrateAchievement(_ achievement: RomanianAchievement, context: CelebrationContext = .immediate) {
        let celebration = AchievementCelebration(
            achievement: achievement,
            culturalIntensity: determineCulturalIntensity(for: achievement),
            celebrationType: determineCelebrationType(for: achievement),
            folkloreElements: generateFolkloreElements(for: achievement),
            timestamp: Date(),
            context: context
        )
        
        switch context {
        case .immediate:
            performCelebrationImmediately(celebration)
        case .queued:
            queueCelebration(celebration)
        case .silent:
            recordSilentCelebration(celebration)
        }
        
        logger.info("Romanian achievement celebration triggered: \(achievement.titleKey)")
    }
    
    private func performCelebrationImmediately(_ celebration: AchievementCelebration) {
        guard !isPerformingCelebration else {
            queueCelebration(celebration)
            return
        }
        
        isPerformingCelebration = true
        currentCelebration = celebration
        
        // Romanian cultural celebration sequence
        Task {
            await performCulturalCelebrationSequence(celebration)
        }
    }
    
    private func queueCelebration(_ celebration: AchievementCelebration) {
        celebrationQueue.append(celebration)
        
        // Auto-process queue if not currently celebrating
        if !isPerformingCelebration {
            processNextCelebration()
        }
    }
    
    private func processNextCelebration() {
        guard !celebrationQueue.isEmpty, !isPerformingCelebration else { return }
        
        let nextCelebration = celebrationQueue.removeFirst()
        performCelebrationImmediately(nextCelebration)
    }
    
    // MARK: - Romanian Cultural Celebration Sequence
    
    private func performCulturalCelebrationSequence(_ celebration: AchievementCelebration) async {
        let startTime = Date()
        
        // 1. Traditional Romanian folk music (if enabled)
        await playTraditionalMusic(for: celebration)
        
        // 2. Romanian haptic pattern (if enabled)
        await performCulturalHaptics(for: celebration)
        
        // 3. Visual celebration display
        await displayVisualCelebration(celebration)
        
        // 4. Cultural significance narration (for educational achievements)
        await narrateCulturalSignificance(celebration)
        
        // 5. Folklore animation effects
        await performFolkloreAnimations(celebration)
        
        // 6. Completion and metrics
        let duration = Date().timeIntervalSince(startTime)
        completeCelebration(celebration, duration: duration)
    }
    
    private func playTraditionalMusic(for celebration: AchievementCelebration) async {
        guard traditionalMusicEnabled,
              let audioManager = audioManager else { return }
        
        let musicTrack = selectTraditionalMusic(for: celebration)
        
        await withCheckedContinuation { continuation in
            audioManager.playTraditionalMusic(track: musicTrack) {
                continuation.resume()
            }
        }
        
        celebrationMetrics.musicPlaysCount += 1
    }
    
    private func performCulturalHaptics(for celebration: AchievementCelebration) async {
        guard hapticCulturalPatterns,
              let hapticManager = hapticManager else { return }
        
        let hapticPattern = selectCulturalHapticPattern(for: celebration)
        
        await withCheckedContinuation { continuation in
            hapticManager.performCulturalPattern(pattern: hapticPattern) {
                continuation.resume()
            }
        }
        
        celebrationMetrics.hapticPatternsPerformed += 1
    }
    
    private func displayVisualCelebration(_ celebration: AchievementCelebration) async {
        // This triggers the SwiftUI notification view
        NotificationCenter.default.post(
            name: .showAchievementCelebration,
            object: celebration
        )
        
        celebrationMetrics.visualCelebrationsShown += 1
        
        // Wait for notification display duration
        await withCheckedContinuation { continuation in
            DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
                continuation.resume()
            }
        }
    }
    
    private func narrateCulturalSignificance(_ celebration: AchievementCelebration) async {
        // For educational achievements, provide cultural context narration
        if celebration.achievement.type == .educational || 
           celebration.achievement.type == .cultural {
            
            let narration = generateCulturalNarration(for: celebration.achievement)
            
            // Post narration for UI to display
            NotificationCenter.default.post(
                name: .showCulturalNarration,
                object: narration
            )
            
            celebrationMetrics.culturalNarrationsShown += 1
        }
    }
    
    private func performFolkloreAnimations(_ celebration: AchievementCelebration) async {
        guard folkloreAnimationEnabled else { return }
        
        // Trigger Romanian folklore-inspired animation effects
        let animations = selectFolkloreAnimations(for: celebration)
        
        for animation in animations {
            NotificationCenter.default.post(
                name: .performFolkloreAnimation,
                object: animation
            )
            
            // Wait between animations for proper sequencing
            await withCheckedContinuation { continuation in
                DispatchQueue.main.asyncAfter(deadline: .now() + animation.duration) {
                    continuation.resume()
                }
            }
        }
        
        celebrationMetrics.folkloreAnimationsPerformed += animations.count
    }
    
    private func completeCelebration(_ celebration: AchievementCelebration, duration: TimeInterval) {
        // Record completed celebration
        let completed = CompletedCelebration(
            celebration: celebration,
            completedAt: Date(),
            duration: duration,
            wasSuccessful: true
        )
        
        celebrationHistory.append(completed)
        
        // Update metrics
        celebrationMetrics.totalCelebrationsPerformed += 1
        celebrationMetrics.averageCelebrationDuration = calculateAverageDuration()
        
        // Clear current celebration
        currentCelebration = nil
        isPerformingCelebration = false
        
        // Process next in queue
        processNextCelebration()
        
        logger.info("Romanian celebration completed in \(duration)s: \(celebration.achievement.titleKey)")
    }
    
    // MARK: - Cultural Selection Methods
    
    private func determineCulturalIntensity(for achievement: RomanianAchievement) -> CulturalIntensity {
        switch achievement.difficulty {
        case .bronze:
            return .gentle
        case .silver:
            return .moderate
        case .gold:
            return .vibrant
        case .legendary:
            return .spectacular
        }
    }
    
    private func determineCelebrationType(for achievement: RomanianAchievement) -> CelebrationType {
        switch achievement.type {
        case .gameplay:
            return .gameplayMastery
        case .cultural:
            return .culturalWisdom
        case .educational:
            return .knowledgeGained
        case .heritage:
            return .heritageConnection
        case .strategic:
            return .strategicExcellence
        default:
            return .generalAchievement
        }
    }
    
    private func generateFolkloreElements(for achievement: RomanianAchievement) -> [FolkloreElement] {
        var elements: [FolkloreElement] = []
        
        // Base folklore elements
        elements.append(.traditionalColors)
        elements.append(.folkPatterns)
        
        // Region-specific elements
        if let region = achievement.culturalRegion {
            elements.append(.regionalSymbol(region))
            elements.append(.regionalMusic(region))
        }
        
        // Achievement-specific elements
        switch achievement.category {
        case .cardMastery:
            elements.append(.cardMasterySymbols)
        case .folkloreLearning:
            elements.append(.folkloreStoryElements)
        case .traditionalMusic:
            elements.append(.musicalNotations)
        default:
            elements.append(.generalCultural)
        }
        
        return elements
    }
    
    private func selectTraditionalMusic(for celebration: AchievementCelebration) -> TraditionalMusicTrack {
        // Select appropriate Romanian traditional music based on achievement
        switch celebration.culturalIntensity {
        case .gentle:
            return .softFolkMelody
        case .moderate:
            return .traditionalDance
        case .vibrant:
            return .celebratoryHora
        case .spectacular:
            return .grandFestival
        }
    }
    
    private func selectCulturalHapticPattern(for celebration: AchievementCelebration) -> CulturalHapticPattern {
        switch celebration.celebrationType {
        case .gameplayMastery:
            return .victoryDrumbeat
        case .culturalWisdom:
            return .traditionalRhythm
        case .knowledgeGained:
            return .gentleEnlightenment
        case .heritageConnection:
            return .ancestralHeartbeat
        case .strategicExcellence:
            return .masterfulPrecision
        case .generalAchievement:
            return .celebratoryPulse
        }
    }
    
    private func selectFolkloreAnimations(for celebration: AchievementCelebration) -> [FolkloreAnimation] {
        var animations: [FolkloreAnimation] = []
        
        // Base celebration animation
        animations.append(FolkloreAnimation(
            type: .sparklingStars,
            duration: 1.5,
            intensity: celebration.culturalIntensity.rawValue
        ))
        
        // Cultural-specific animations
        if celebration.achievement.culturalRegion != nil {
            animations.append(FolkloreAnimation(
                type: .regionalPattern,
                duration: 2.0,
                intensity: celebration.culturalIntensity.rawValue
            ))
        }
        
        // Achievement category animations
        switch celebration.achievement.category {
        case .cardMastery:
            animations.append(FolkloreAnimation(
                type: .flyingCards,
                duration: 2.5,
                intensity: celebration.culturalIntensity.rawValue
            ))
        case .folkloreLearning:
            animations.append(FolkloreAnimation(
                type: .ancientWisdom,
                duration: 3.0,
                intensity: celebration.culturalIntensity.rawValue
            ))
        default:
            animations.append(FolkloreAnimation(
                type: .traditionalCelebration,
                duration: 2.0,
                intensity: celebration.culturalIntensity.rawValue
            ))
        }
        
        return animations
    }
    
    private func generateCulturalNarration(for achievement: RomanianAchievement) -> CulturalNarration {
        return CulturalNarration(
            achievement: achievement,
            narrationText: achievement.culturalContextKey,
            culturalFacts: generateCulturalFacts(for: achievement),
            historicalContext: generateHistoricalContext(for: achievement),
            displayDuration: 8.0
        )
    }
    
    private func generateCulturalFacts(for achievement: RomanianAchievement) -> [String] {
        // Generate relevant Romanian cultural facts based on achievement
        switch achievement.category {
        case .cardMastery:
            return [
                "Cărțile de joc au ajuns în România în secolul al XV-lea",
                "Jocul de Septica este o tradiție românească veche de secole"
            ]
        case .folkloreLearning:
            return [
                "România are peste 40.000 de povești populare documentate",
                "Tradițiile orale românești sunt patrimoniiul UNESCO"
            ]
        default:
            return [
                "Cultura română este un amestec unic de tradiții dacice, romane și balcanice"
            ]
        }
    }
    
    private func generateHistoricalContext(for achievement: RomanianAchievement) -> String {
        if let region = achievement.culturalRegion {
            return "Această realizare celebrează tradițiile din regiunea \(region.localizedNameKey)"
        } else {
            return "Această realizare celebrează patrimoniul cultural românesc"
        }
    }
    
    // MARK: - Setup Methods
    
    private func setupCelebrationObservers() {
        // Listen for achievement unlock notifications
        NotificationCenter.default.publisher(for: .achievementUnlocked)
            .compactMap { $0.object as? RomanianAchievement }
            .sink { [weak self] achievement in
                self?.celebrateAchievement(achievement, context: .immediate)
            }
            .store(in: &cancellables)
        
        // Listen for cultural symbol unlocks
        NotificationCenter.default.publisher(for: .culturalSymbolUnlocked)
            .sink { [weak self] notification in
                if let unlock = notification.object as? CulturalSymbolUnlock {
                    self?.celebrateCulturalSymbol(unlock)
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupCulturalSettings() {
        // Configure default Romanian cultural celebration settings
        culturalCelebrationSettings = CulturalCelebrationSettings(
            folkloreAnimationIntensity: 0.8,
            traditionalMusicVolume: 0.7,
            hapticCulturalStrength: 0.6,
            celebrationDuration: 6.0,
            autoQueueEnabled: true,
            culturalNarrationEnabled: true
        )
    }
    
    private func celebrateCulturalSymbol(_ unlock: CulturalSymbolUnlock) {
        // Special mini-celebration for cultural symbol unlocks
        let miniCelebration = CulturalSymbolCelebration(
            symbol: unlock.symbol,
            card: unlock.card,
            intensity: CulturalIntensity.gentle
        )
        
        NotificationCenter.default.post(
            name: .showCulturalSymbolCelebration,
            object: miniCelebration
        )
    }
    
    private func recordSilentCelebration(_ celebration: AchievementCelebration) {
        // Record achievement without visual celebration (for background achievements)
        let completed = CompletedCelebration(
            celebration: celebration,
            completedAt: Date(),
            duration: 0,
            wasSuccessful: true
        )
        
        celebrationHistory.append(completed)
        celebrationMetrics.silentCelebrationsRecorded += 1
    }
    
    // MARK: - Metrics Calculation
    
    private func calculateAverageDuration() -> TimeInterval {
        let visibleCelebrations = celebrationHistory.filter { $0.duration > 0 }
        guard !visibleCelebrations.isEmpty else { return 0 }
        
        let totalDuration = visibleCelebrations.reduce(0) { $0 + $1.duration }
        return totalDuration / Double(visibleCelebrations.count)
    }
}

// MARK: - Supporting Data Structures

struct AchievementCelebration {
    let achievement: RomanianAchievement
    let culturalIntensity: CulturalIntensity
    let celebrationType: CelebrationType
    let folkloreElements: [FolkloreElement]
    let timestamp: Date
    let context: CelebrationContext
}

enum CelebrationContext {
    case immediate
    case queued
    case silent
}

enum CulturalIntensity: Double, CaseIterable {
    case gentle = 0.3
    case moderate = 0.6
    case vibrant = 0.8
    case spectacular = 1.0
}

enum CelebrationType {
    case gameplayMastery
    case culturalWisdom
    case knowledgeGained
    case heritageConnection
    case strategicExcellence
    case generalAchievement
}

enum FolkloreElement {
    case traditionalColors
    case folkPatterns
    case regionalSymbol(RomanianRegion)
    case regionalMusic(RomanianRegion)
    case cardMasterySymbols
    case folkloreStoryElements
    case musicalNotations
    case generalCultural
}

enum TraditionalMusicTrack: String, CaseIterable {
    case softFolkMelody = "soft_folk_melody"
    case traditionalDance = "traditional_dance"
    case celebratoryHora = "celebratory_hora"
    case grandFestival = "grand_festival"
}

enum CulturalHapticPattern {
    case victoryDrumbeat
    case traditionalRhythm
    case gentleEnlightenment
    case ancestralHeartbeat
    case masterfulPrecision
    case celebratoryPulse
}

struct FolkloreAnimation {
    let type: FolkloreAnimationType
    let duration: TimeInterval
    let intensity: Double
    
    enum FolkloreAnimationType {
        case sparklingStars
        case regionalPattern
        case flyingCards
        case ancientWisdom
        case traditionalCelebration
    }
}

struct CulturalNarration {
    let achievement: RomanianAchievement
    let narrationText: String
    let culturalFacts: [String]
    let historicalContext: String
    let displayDuration: TimeInterval
}

struct CulturalSymbolCelebration {
    let symbol: RomanianCardSymbol
    let card: Card
    let intensity: CulturalIntensity
}

struct CompletedCelebration {
    let celebration: AchievementCelebration
    let completedAt: Date
    let duration: TimeInterval
    let wasSuccessful: Bool
}

struct CulturalCelebrationSettings {
    var folkloreAnimationIntensity: Double = 0.8
    var traditionalMusicVolume: Double = 0.7
    var hapticCulturalStrength: Double = 0.6
    var celebrationDuration: TimeInterval = 6.0
    var autoQueueEnabled: Bool = true
    var culturalNarrationEnabled: Bool = true
}

struct CelebrationMetrics {
    var totalCelebrationsPerformed: Int = 0
    var averageCelebrationDuration: TimeInterval = 0
    var musicPlaysCount: Int = 0
    var hapticPatternsPerformed: Int = 0
    var visualCelebrationsShown: Int = 0
    var culturalNarrationsShown: Int = 0
    var folkloreAnimationsPerformed: Int = 0
    var silentCelebrationsRecorded: Int = 0
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let showAchievementCelebration = Notification.Name("showAchievementCelebration")
    static let showCulturalNarration = Notification.Name("showCulturalNarration")
    static let performFolkloreAnimation = Notification.Name("performFolkloreAnimation")
    static let showCulturalSymbolCelebration = Notification.Name("showCulturalSymbolCelebration")
}

// MARK: - Audio and Haptic Manager Extensions

extension AudioManager {
    func playTraditionalMusic(track: TraditionalMusicTrack, completion: @escaping () -> Void) {
        // Implementation would play the specified traditional Romanian music track
        // For now, simulate with delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            completion()
        }
    }
}

extension HapticManager {
    func performCulturalPattern(pattern: CulturalHapticPattern, completion: @escaping () -> Void) {
        // Implementation would perform Romanian-inspired haptic patterns
        // For now, simulate with delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            completion()
        }
    }
}
