//
//  AchievementCelebrationSystem.swift
//  Septica
//
//  Romanian Cultural Achievement Celebration and Notification System
//  Provides beautiful celebrations for cultural milestones with authentic Romanian themes
//

import Foundation
import SwiftUI
import AVFoundation
import UserNotifications
import Combine

/// Romanian Cultural Achievement Celebration System
/// Creates immersive celebrations for cultural achievements with authentic Romanian elements
@MainActor
class AchievementCelebrationSystem: ObservableObject {
    
    // MARK: - Dependencies
    
    private let hapticManager: HapticManager
    private let audioManager: AudioManager
    private let animationManager: AnimationManager
    private let culturalContentLibrary: RomanianCulturalContentLibrary
    
    // MARK: - Published Celebration State
    
    @Published var activeCelebrations: [ActiveCelebration] = []
    @Published var celebrationQueue: [CelebrationEvent] = []
    @Published var isCelebrationInProgress: Bool = false
    @Published var currentCelebrationTheme: CelebrationTheme?
    
    // MARK: - Configuration
    
    @Published var celebrationSettings: CelebrationSettings
    @Published var culturalDisplaySettings: CulturalDisplaySettings
    
    // MARK: - Audio and Haptic Resources
    
    private var audioPlayer: AVAudioPlayer?
    private var backgroundMusicPlayer: AVAudioPlayer?
    private var celebrationSounds: [CelebrationSoundType: AVAudioPlayer] = [:]
    
    // MARK: - Animation State
    
    @Published var particleEffects: [ParticleEffect] = []
    @Published var backgroundAnimations: [BackgroundAnimation] = []
    @Published var culturalSymbolAnimations: [CulturalSymbolAnimation] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        hapticManager: HapticManager,
        audioManager: AudioManager,
        animationManager: AnimationManager,
        culturalContentLibrary: RomanianCulturalContentLibrary
    ) {
        self.hapticManager = hapticManager
        self.audioManager = audioManager
        self.animationManager = animationManager
        self.culturalContentLibrary = culturalContentLibrary
        
        self.celebrationSettings = CelebrationSettings()
        self.culturalDisplaySettings = CulturalDisplaySettings()
        
        setupAudioResources()
        setupNotificationSubscriptions()
        loadCelebrationPreferences()
    }
    
    // MARK: - Celebration Event Processing
    
    func celebrateAchievement(_ achievement: RomanianAchievement) async {
        let celebrationEvent = CelebrationEvent(
            id: UUID(),
            type: .achievementUnlock,
            achievement: achievement,
            culturalContext: CulturalContext(achievement: achievement),
            timestamp: Date(),
            priority: calculateCelebrationPriority(achievement)
        )
        
        await queueCelebration(celebrationEvent)
    }
    
    func celebrateMilestone(_ milestone: TraditionalMilestone) async {
        let celebrationEvent = CelebrationEvent(
            id: UUID(),
            type: .milestone,
            milestone: milestone,
            culturalContext: CulturalContext(milestone: milestone),
            timestamp: Date(),
            priority: .normal
        )
        
        await queueCelebration(celebrationEvent)
    }
    
    func celebrateSeasonalEvent(_ celebration: RomanianCulturalCelebration) async {
        let celebrationEvent = CelebrationEvent(
            id: UUID(),
            type: .seasonal,
            seasonalCelebration: celebration,
            culturalContext: CulturalContext(seasonal: celebration),
            timestamp: Date(),
            priority: .high
        )
        
        await queueCelebration(celebrationEvent)
    }
    
    func celebrateCulturalLevelUp(newLevel: Int, culturalProgress: CulturalProgress) async {
        let celebrationEvent = CelebrationEvent(
            id: UUID(),
            type: .levelUp,
            culturalLevel: newLevel,
            culturalProgress: culturalProgress,
            culturalContext: CulturalContext(levelUp: newLevel),
            timestamp: Date(),
            priority: .high
        )
        
        await queueCelebration(celebrationEvent)
    }
    
    private func queueCelebration(_ event: CelebrationEvent) async {
        celebrationQueue.append(event)
        celebrationQueue.sort { $0.priority.rawValue > $1.priority.rawValue }
        
        if !isCelebrationInProgress {
            await processNextCelebration()
        }
    }
    
    private func processNextCelebration() async {
        guard let event = celebrationQueue.first else { return }
        celebrationQueue.removeFirst()
        
        isCelebrationInProgress = true
        currentCelebrationTheme = determineCelebrationTheme(for: event)
        
        await executeCelebration(event)
        
        // Process next celebration after delay
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        isCelebrationInProgress = false
        
        if !celebrationQueue.isEmpty {
            await processNextCelebration()
        }
    }
    
    // MARK: - Celebration Execution
    
    private func executeCelebration(_ event: CelebrationEvent) async {
        let celebration = createActiveCelebration(from: event)
        activeCelebrations.append(celebration)
        
        // Execute celebration sequence
        await performCelebrationSequence(celebration)
        
        // Remove from active celebrations
        activeCelebrations.removeAll { $0.id == celebration.id }
    }
    
    private func performCelebrationSequence(_ celebration: ActiveCelebration) async {
        let sequence = CelebrationSequence(celebration: celebration, settings: celebrationSettings)
        
        // Phase 1: Initial Impact (Haptics + Sound)
        await executeInitialImpact(sequence)
        
        // Phase 2: Visual Effects (Particles + Animations)
        await executeVisualEffects(sequence)
        
        // Phase 3: Cultural Content Display
        await executeCulturalContent(sequence)
        
        // Phase 4: Educational Component (if enabled)
        if culturalDisplaySettings.showEducationalContent {
            await executeEducationalContent(sequence)
        }
        
        // Phase 5: Final Flourish
        await executeFinalFlourish(sequence)
    }
    
    // MARK: - Celebration Phases
    
    private func executeInitialImpact(_ sequence: CelebrationSequence) async {
        // Haptic feedback
        await performHapticSequence(sequence.celebration)
        
        // Sound effect
        await playInitialSound(sequence.celebration)
        
        // Quick visual flash
        await triggerInitialFlash(sequence.celebration)
    }
    
    private func executeVisualEffects(_ sequence: CelebrationSequence) async {
        // Start particle effects
        await startParticleEffects(sequence.celebration)
        
        // Begin background animations
        await startBackgroundAnimations(sequence.celebration)
        
        // Show cultural symbols
        await animateCulturalSymbols(sequence.celebration)
    }
    
    private func executeCulturalContent(_ sequence: CelebrationSequence) async {
        let culturalContent = await culturalContentLibrary.getCelebrationContent(
            for: sequence.celebration.culturalContext
        )
        
        // Display Romanian cultural message
        await displayCulturalMessage(culturalContent)
        
        // Show traditional patterns or symbols
        await displayTraditionalElements(culturalContent)
        
        // Play traditional music (if enabled)
        if celebrationSettings.enableTraditionalMusic {
            await playTraditionalMusic(culturalContent)
        }
    }
    
    private func executeEducationalContent(_ sequence: CelebrationSequence) async {
        if let educationalContent = sequence.celebration.educationalContent {
            // Show cultural fact or historical context
            await displayEducationalTip(educationalContent)
            
            // Brief folklore reference
            await displayFolkloreReference(educationalContent)
        }
    }
    
    private func executeFinalFlourish(_ sequence: CelebrationSequence) async {
        // Crescendo effects
        await performFinalEffects(sequence.celebration)
        
        // Achievement showcase
        await showcaseUnlockedContent(sequence.celebration)
        
        // Gentle fade out
        await fadeOutCelebration(sequence.celebration)
    }
    
    // MARK: - Haptic Feedback
    
    private func performHapticSequence(_ celebration: ActiveCelebration) async {
        switch celebration.type {
        case .achievementUnlock:
            await performAchievementHaptics(celebration)
        case .milestone:
            await performMilestoneHaptics(celebration)
        case .seasonal:
            await performSeasonalHaptics(celebration)
        case .levelUp:
            await performLevelUpHaptics(celebration)
        }
    }
    
    private func performAchievementHaptics(_ celebration: ActiveCelebration) async {
        guard let achievement = celebration.achievement else { return }
        
        switch achievement.difficulty {
        case .bronze:
            await hapticManager.playCustomPattern(.achievementBronze)
        case .silver:
            await hapticManager.playCustomPattern(.achievementSilver)
        case .gold:
            await hapticManager.playCustomPattern(.achievementGold)
        case .legendary:
            await hapticManager.playCustomPattern(.achievementLegendary)
        }
    }
    
    private func performMilestoneHaptics(_ celebration: ActiveCelebration) async {
        await hapticManager.playCustomPattern(.traditionalMilestone)
    }
    
    private func performSeasonalHaptics(_ celebration: ActiveCelebration) async {
        await hapticManager.playCustomPattern(.seasonalCelebration)
    }
    
    private func performLevelUpHaptics(_ celebration: ActiveCelebration) async {
        await hapticManager.playCustomPattern(.culturalLevelUp)
    }
    
    // MARK: - Audio Effects
    
    private func playInitialSound(_ celebration: ActiveCelebration) async {
        let soundType = determineSoundType(celebration)
        
        if let audioPlayer = celebrationSounds[soundType] {
            audioPlayer.play()
        }
    }
    
    private func playTraditionalMusic(_ culturalContent: CulturalContent) async {
        guard let musicTrack = culturalContent.associatedMusic else { return }
        
        do {
            let musicURL = Bundle.main.url(forResource: musicTrack, withExtension: "mp3")
            guard let url = musicURL else { return }
            
            backgroundMusicPlayer = try AVAudioPlayer(contentsOf: url)
            backgroundMusicPlayer?.volume = celebrationSettings.musicVolume
            backgroundMusicPlayer?.play()
        } catch {
            print("Failed to play traditional music: \(error)")
        }
    }
    
    private func determineSoundType(_ celebration: ActiveCelebration) -> CelebrationSoundType {
        switch celebration.type {
        case .achievementUnlock:
            return .achievementUnlock
        case .milestone:
            return .milestoneReached
        case .seasonal:
            return .seasonalFanfare
        case .levelUp:
            return .levelUpChime
        }
    }
    
    // MARK: - Visual Effects
    
    private func startParticleEffects(_ celebration: ActiveCelebration) async {
        let particleConfig = ParticleConfiguration(celebration: celebration)
        let effect = ParticleEffect(
            id: UUID(),
            type: particleConfig.type,
            colors: particleConfig.colors,
            duration: particleConfig.duration,
            intensity: celebrationSettings.effectsIntensity
        )
        
        particleEffects.append(effect)
        
        // Auto-remove after duration
        Task {
            try await Task.sleep(nanoseconds: UInt64(effect.duration * 1_000_000_000))
            particleEffects.removeAll { $0.id == effect.id }
        }
    }
    
    private func startBackgroundAnimations(_ celebration: ActiveCelebration) async {
        let animation = BackgroundAnimation(
            id: UUID(),
            type: determineBackgroundAnimationType(celebration),
            culturalTheme: celebration.culturalContext.theme,
            duration: 3.0
        )
        
        backgroundAnimations.append(animation)
        
        // Auto-remove after duration
        Task {
            try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            backgroundAnimations.removeAll { $0.id == animation.id }
        }
    }
    
    private func animateCulturalSymbols(_ celebration: ActiveCelebration) async {
        let symbols = culturalContentLibrary.getSymbolsFor(celebration.culturalContext)
        
        for symbol in symbols {
            let animation = CulturalSymbolAnimation(
                id: UUID(),
                symbol: symbol,
                animationType: .floatAndGlow,
                duration: 2.5
            )
            
            culturalSymbolAnimations.append(animation)
        }
        
        // Auto-remove after duration
        Task {
            try await Task.sleep(nanoseconds: 2_500_000_000) // 2.5 seconds
            culturalSymbolAnimations.removeAll()
        }
    }
    
    private func triggerInitialFlash(_ celebration: ActiveCelebration) async {
        // Create brief screen flash effect
        let flashColor = determineCelebrationColor(celebration)
        
        // Trigger flash animation via animation manager
        await animationManager.triggerScreenFlash(color: flashColor, duration: 0.2)
    }
    
    // MARK: - Cultural Content Display
    
    private func displayCulturalMessage(_ content: CulturalContent) async {
        // Display Romanian cultural message with beautiful typography
        NotificationCenter.default.post(
            name: .displayCulturalMessage,
            object: CulturalMessageDisplay(
                title: content.title,
                message: content.message,
                culturalSignificance: content.culturalSignificance,
                displayDuration: 3.0
            )
        )
    }
    
    private func displayTraditionalElements(_ content: CulturalContent) async {
        // Show traditional patterns or regional symbols
        NotificationCenter.default.post(
            name: .displayTraditionalElements,
            object: TraditionalElementsDisplay(
                patterns: content.traditionalPatterns,
                symbols: content.culturalSymbols,
                region: content.associatedRegion
            )
        )
    }
    
    private func displayEducationalTip(_ educational: EducationalContent) async {
        NotificationCenter.default.post(
            name: .displayEducationalTip,
            object: EducationalTipDisplay(
                title: educational.titleKey,
                content: educational.contentKey,
                culturalContext: educational.culturalRegion?.displayName,
                mediaAssets: educational.mediaAssets
            )
        )
    }
    
    private func displayFolkloreReference(_ educational: EducationalContent) async {
        if educational.type == .folklore {
            NotificationCenter.default.post(
                name: .displayFolkloreReference,
                object: FolkloreReferenceDisplay(
                    folkloreTitle: educational.titleKey,
                    briefDescription: educational.contentKey,
                    fullStoryId: "story_\(educational.id)"
                )
            )
        }
    }
    
    // MARK: - Final Effects
    
    private func performFinalEffects(_ celebration: ActiveCelebration) async {
        // Intensify existing effects
        for i in 0..<particleEffects.count {
            particleEffects[i].intensity *= 1.5
        }
        
        // Add final burst of particles
        let finalBurst = ParticleEffect(
            id: UUID(),
            type: .burst,
            colors: determineCelebrationColors(celebration),
            duration: 1.0,
            intensity: 1.0
        )
        
        particleEffects.append(finalBurst)
    }
    
    private func showcaseUnlockedContent(_ celebration: ActiveCelebration) async {
        if let achievement = celebration.achievement {
            let showcase = UnlockedContentShowcase(
                achievement: achievement,
                unlockedContent: achievement.unlockableContent,
                displayDuration: 4.0
            )
            
            NotificationCenter.default.post(
                name: .showcaseUnlockedContent,
                object: showcase
            )
        }
    }
    
    private func fadeOutCelebration(_ celebration: ActiveCelebration) async {
        // Gradually fade out all effects
        await animationManager.fadeOutEffects(duration: 1.0)
        
        // Stop background music
        backgroundMusicPlayer?.stop()
        backgroundMusicPlayer = nil
    }
    
    // MARK: - Push Notifications
    
    func scheduleAchievementNotification(_ achievement: RomanianAchievement) async {
        guard celebrationSettings.enablePushNotifications else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🏆 Realizare Culturală Nouă!"
        content.body = "Ai debloca realizarea '\(achievement.titleKey)' - \(achievement.descriptionKey)"
        content.sound = .default
        
        // Add cultural context
        content.userInfo = [
            "achievementId": achievement.id.uuidString,
            "culturalRegion": achievement.culturalRegion?.rawValue ?? "general",
            "difficulty": achievement.difficulty.rawValue
        ]
        
        // Immediate notification
        let request = UNNotificationRequest(
            identifier: "achievement_\(achievement.id)",
            content: content,
            trigger: nil
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Configuration and Preferences
    
    func updateCelebrationSettings(_ settings: CelebrationSettings) {
        celebrationSettings = settings
        saveCelebrationPreferences()
    }
    
    func updateCulturalDisplaySettings(_ settings: CulturalDisplaySettings) {
        culturalDisplaySettings = settings
        saveCelebrationPreferences()
    }
    
    // MARK: - Helper Methods
    
    private func setupAudioResources() {
        let soundFiles: [CelebrationSoundType: String] = [
            .achievementUnlock: "achievement_unlock",
            .milestoneReached: "milestone_reached",
            .seasonalFanfare: "seasonal_fanfare",
            .levelUpChime: "level_up_chime"
        ]
        
        for (type, filename) in soundFiles {
            if let url = Bundle.main.url(forResource: filename, withExtension: "wav") {
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.prepareToPlay()
                    celebrationSounds[type] = player
                } catch {
                    print("Failed to load sound \(filename): \(error)")
                }
            }
        }
    }
    
    private func setupNotificationSubscriptions() {
        // Listen for achievement unlocks
        NotificationCenter.default.publisher(for: .achievementUnlocked)
            .compactMap { $0.object as? RomanianAchievement }
            .sink { [weak self] achievement in
                Task { @MainActor in
                    await self?.celebrateAchievement(achievement)
                }
            }
            .store(in: &cancellables)
        
        // Listen for traditional milestones
        NotificationCenter.default.publisher(for: .traditionalMilestoneAchieved)
            .compactMap { $0.object as? TraditionalMilestone }
            .sink { [weak self] milestone in
                Task { @MainActor in
                    await self?.celebrateMilestone(milestone)
                }
            }
            .store(in: &cancellables)
    }
    
    private func calculateCelebrationPriority(_ achievement: RomanianAchievement) -> CelebrationPriority {
        switch achievement.difficulty {
        case .bronze: return .normal
        case .silver: return .normal
        case .gold: return .high
        case .legendary: return .highest
        }
    }
    
    private func determineCelebrationTheme(for event: CelebrationEvent) -> CelebrationTheme {
        switch event.type {
        case .achievementUnlock:
            return CelebrationTheme(
                primaryColor: determinePrimaryColor(event),
                secondaryColor: determineSecondaryColor(event),
                culturalElements: event.culturalContext.elements,
                musicStyle: .traditional
            )
        case .seasonal:
            return CelebrationTheme(
                primaryColor: event.seasonalCelebration?.culturalDescription.color ?? .blue,
                secondaryColor: .gold,
                culturalElements: event.seasonalCelebration?.traditionalActivities ?? [],
                musicStyle: .festive
            )
        case .milestone:
            return CelebrationTheme(
                primaryColor: .green,
                secondaryColor: .white,
                culturalElements: ["traditional_patterns"],
                musicStyle: .ambient
            )
        case .levelUp:
            return CelebrationTheme(
                primaryColor: .purple,
                secondaryColor: .gold,
                culturalElements: ["cultural_ascension"],
                musicStyle: .triumphant
            )
        }
    }
    
    private func createActiveCelebration(from event: CelebrationEvent) -> ActiveCelebration {
        return ActiveCelebration(
            id: UUID(),
            type: event.type,
            achievement: event.achievement,
            milestone: event.milestone,
            seasonalCelebration: event.seasonalCelebration,
            culturalLevel: event.culturalLevel,
            culturalContext: event.culturalContext,
            educationalContent: event.achievement?.educationalContent,
            startTime: Date(),
            duration: calculateCelebrationDuration(event)
        )
    }
    
    private func calculateCelebrationDuration(_ event: CelebrationEvent) -> TimeInterval {
        switch event.type {
        case .achievementUnlock:
            return event.achievement?.difficulty == .legendary ? 8.0 : 5.0
        case .seasonal:
            return 6.0
        case .milestone:
            return 3.0
        case .levelUp:
            return 7.0
        }
    }
    
    private func determinePrimaryColor(_ event: CelebrationEvent) -> Color {
        if let achievement = event.achievement {
            switch achievement.difficulty {
            case .bronze: return .brown
            case .silver: return .gray
            case .gold: return .yellow
            case .legendary: return .purple
            }
        }
        return .blue
    }
    
    private func determineSecondaryColor(_ event: CelebrationEvent) -> Color {
        return .white
    }
    
    private func determineCelebrationColor(_ celebration: ActiveCelebration) -> Color {
        switch celebration.type {
        case .achievementUnlock:
            return celebration.achievement?.difficulty.color ?? .blue
        case .seasonal:
            return .red // Romanian flag color
        case .milestone:
            return .green
        case .levelUp:
            return .purple
        }
    }
    
    private func determineCelebrationColors(_ celebration: ActiveCelebration) -> [Color] {
        let primary = determineCelebrationColor(celebration)
        return [primary, .gold, .white]
    }
    
    private func determineBackgroundAnimationType(_ celebration: ActiveCelebration) -> BackgroundAnimationType {
        switch celebration.type {
        case .achievementUnlock:
            return .radialBurst
        case .seasonal:
            return .traditionalPattern
        case .milestone:
            return .gentleWave
        case .levelUp:
            return .ascending
        }
    }
    
    private func loadCelebrationPreferences() {
        // Load from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "celebration_settings"),
           let settings = try? JSONDecoder().decode(CelebrationSettings.self, from: data) {
            celebrationSettings = settings
        }
        
        if let data = UserDefaults.standard.data(forKey: "cultural_display_settings"),
           let settings = try? JSONDecoder().decode(CulturalDisplaySettings.self, from: data) {
            culturalDisplaySettings = settings
        }
    }
    
    private func saveCelebrationPreferences() {
        if let data = try? JSONEncoder().encode(celebrationSettings) {
            UserDefaults.standard.set(data, forKey: "celebration_settings")
        }
        
        if let data = try? JSONEncoder().encode(culturalDisplaySettings) {
            UserDefaults.standard.set(data, forKey: "cultural_display_settings")
        }
    }
}

// MARK: - Supporting Data Models

struct CelebrationEvent {
    let id: UUID
    let type: CelebrationType
    let achievement: RomanianAchievement?
    let milestone: TraditionalMilestone?
    let seasonalCelebration: RomanianCulturalCelebration?
    let culturalLevel: Int?
    let culturalProgress: CulturalProgress?
    let culturalContext: CulturalContext
    let timestamp: Date
    let priority: CelebrationPriority
}

enum CelebrationType {
    case achievementUnlock
    case milestone
    case seasonal
    case levelUp
}

enum CelebrationPriority: Int {
    case low = 1
    case normal = 2
    case high = 3
    case highest = 4
}

struct ActiveCelebration: Identifiable {
    let id: UUID
    let type: CelebrationType
    let achievement: RomanianAchievement?
    let milestone: TraditionalMilestone?
    let seasonalCelebration: RomanianCulturalCelebration?
    let culturalLevel: Int?
    let culturalContext: CulturalContext
    let educationalContent: EducationalContent?
    let startTime: Date
    let duration: TimeInterval
}

struct CulturalContext {
    let theme: String
    let region: RomanianRegion?
    let elements: [String]
    let significance: String
    
    init(achievement: RomanianAchievement) {
        self.theme = achievement.category.rawValue
        self.region = achievement.culturalRegion
        self.elements = ["achievement_celebration"]
        self.significance = achievement.culturalContextKey
    }
    
    init(milestone: TraditionalMilestone) {
        self.theme = milestone.type.rawValue
        self.region = nil
        self.elements = ["traditional_milestone"]
        self.significance = milestone.culturalSignificance
    }
    
    init(seasonal: RomanianCulturalCelebration) {
        self.theme = seasonal.rawValue
        self.region = .general
        self.elements = seasonal.traditionalActivities
        self.significance = seasonal.culturalDescription
    }
    
    init(levelUp: Int) {
        self.theme = "cultural_ascension"
        self.region = .general
        self.elements = ["level_progression", "cultural_growth"]
        self.significance = "Advancing in Romanian cultural knowledge and mastery"
    }
}

struct CelebrationTheme {
    let primaryColor: Color
    let secondaryColor: Color
    let culturalElements: [String]
    let musicStyle: MusicStyle
    
    enum MusicStyle {
        case traditional
        case festive
        case ambient
        case triumphant
    }
}

struct CelebrationSettings: Codable {
    var enableCelebrations: Bool = true
    var enableHapticFeedback: Bool = true
    var enableSoundEffects: Bool = true
    var enableTraditionalMusic: Bool = true
    var enablePushNotifications: Bool = true
    var effectsIntensity: Float = 0.8
    var musicVolume: Float = 0.6
    var celebrationDuration: TimeInterval = 5.0
}

struct CulturalDisplaySettings: Codable {
    var showEducationalContent: Bool = true
    var showCulturalSymbols: Bool = true
    var showTraditionalPatterns: Bool = true
    var enableFolkloreReferences: Bool = true
    var displayLanguage: String = "romanian"
    var culturalDepthLevel: CulturalDepthLevel = .intermediate
}

enum CulturalDepthLevel: String, Codable {
    case basic
    case intermediate
    case advanced
    case scholarly
}

struct CelebrationSequence {
    let celebration: ActiveCelebration
    let settings: CelebrationSettings
    
    var phases: [CelebrationPhase] {
        return [
            .initialImpact(duration: 0.5),
            .visualEffects(duration: 2.0),
            .culturalContent(duration: celebration.duration * 0.6),
            .educationalContent(duration: 1.0),
            .finalFlourish(duration: 1.0)
        ]
    }
}

enum CelebrationPhase {
    case initialImpact(duration: TimeInterval)
    case visualEffects(duration: TimeInterval)
    case culturalContent(duration: TimeInterval)
    case educationalContent(duration: TimeInterval)
    case finalFlourish(duration: TimeInterval)
}

enum CelebrationSoundType {
    case achievementUnlock
    case milestoneReached
    case seasonalFanfare
    case levelUpChime
}

struct ParticleEffect: Identifiable {
    let id: UUID
    let type: ParticleType
    let colors: [Color]
    let duration: TimeInterval
    var intensity: Float
    
    enum ParticleType {
        case sparkles
        case burst
        case falling
        case swirling
        case traditional
    }
}

struct ParticleConfiguration {
    let type: ParticleEffect.ParticleType
    let colors: [Color]
    let duration: TimeInterval
    
    init(celebration: ActiveCelebration) {
        switch celebration.type {
        case .achievementUnlock:
            self.type = .burst
            self.colors = [.gold, .yellow, .white]
            self.duration = 3.0
        case .seasonal:
            self.type = .traditional
            self.colors = [.red, .yellow, .blue] // Romanian flag colors
            self.duration = 4.0
        case .milestone:
            self.type = .sparkles
            self.colors = [.green, .white]
            self.duration = 2.0
        case .levelUp:
            self.type = .swirling
            self.colors = [.purple, .gold, .white]
            self.duration = 5.0
        }
    }
}

struct BackgroundAnimation: Identifiable {
    let id: UUID
    let type: BackgroundAnimationType
    let culturalTheme: String
    let duration: TimeInterval
}

enum BackgroundAnimationType {
    case radialBurst
    case traditionalPattern
    case gentleWave
    case ascending
}

struct CulturalSymbolAnimation: Identifiable {
    let id: UUID
    let symbol: CulturalSymbol
    let animationType: SymbolAnimationType
    let duration: TimeInterval
}

enum SymbolAnimationType {
    case floatAndGlow
    case spiralIn
    case traditional
}

struct CulturalSymbol {
    let name: String
    let imageName: String
    let culturalSignificance: String
    let region: RomanianRegion?
}

struct CulturalContent {
    let title: String
    let message: String
    let culturalSignificance: String
    let traditionalPatterns: [String]
    let culturalSymbols: [String]
    let associatedRegion: RomanianRegion?
    let associatedMusic: String?
}

struct CulturalProgress {
    let totalExperience: Int
    let culturalLevel: Int
    let authenticityScore: Float
    let regionalMasteries: [RomanianRegion: Float]
}

// MARK: - Display Models

struct CulturalMessageDisplay {
    let title: String
    let message: String
    let culturalSignificance: String
    let displayDuration: TimeInterval
}

struct TraditionalElementsDisplay {
    let patterns: [String]
    let symbols: [String]
    let region: RomanianRegion?
}

struct EducationalTipDisplay {
    let title: String
    let content: String
    let culturalContext: String?
    let mediaAssets: [MediaAsset]
}

struct FolkloreReferenceDisplay {
    let folkloreTitle: String
    let briefDescription: String
    let fullStoryId: String
}

struct UnlockedContentShowcase {
    let achievement: RomanianAchievement
    let unlockedContent: [UnlockableContent]
    let displayDuration: TimeInterval
}

// MARK: - Extensions

extension AchievementDifficulty {
    var color: Color {
        switch self {
        case .bronze: return .brown
        case .silver: return .gray
        case .gold: return .yellow
        case .legendary: return .purple
        }
    }
}

extension String {
    var color: Color {
        // Simple color mapping for cultural descriptions
        if contains("spring") || contains("green") { return .green }
        if contains("love") || contains("red") { return .red }
        if contains("national") || contains("blue") { return .blue }
        if contains("gold") || contains("yellow") { return .yellow }
        return .blue
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let displayCulturalMessage = Notification.Name("displayCulturalMessage")
    static let displayTraditionalElements = Notification.Name("displayTraditionalElements")
    static let displayEducationalTip = Notification.Name("displayEducationalTip")
    static let displayFolkloreReference = Notification.Name("displayFolkloreReference")
    static let showcaseUnlockedContent = Notification.Name("showcaseUnlockedContent")
}

// MARK: - Haptic Extensions

extension HapticManager {
    func playCustomPattern(_ pattern: CustomHapticPattern) async {
        // Implementation would depend on the HapticManager structure
        // This is a placeholder for custom haptic patterns
    }
}

enum CustomHapticPattern {
    case achievementBronze
    case achievementSilver
    case achievementGold
    case achievementLegendary
    case traditionalMilestone
    case seasonalCelebration
    case culturalLevelUp
}