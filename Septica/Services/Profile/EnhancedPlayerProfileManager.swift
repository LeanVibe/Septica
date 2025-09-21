//
//  EnhancedPlayerProfileManager.swift
//  Septica
//
//  Comprehensive Player Profile Management with Cultural Achievement Integration
//  Manages Romanian cultural preferences, progress tracking, and cross-device synchronization
//

import Foundation
import Combine
import CloudKit
import SwiftUI

/// Enhanced Player Profile Manager with Romanian Cultural Integration
/// Manages player data, cultural preferences, achievement progress, and cross-device sync
@MainActor
class EnhancedPlayerProfileManager: ObservableObject {
    
    // MARK: - Dependencies
    
    private let cloudKitManager: SepticaCloudKitManager
    private let achievementManager: RomanianCulturalAchievementManager
    private let milestoneTracker: TraditionalGameplayMilestoneTracker
    private let errorManager: ErrorManager?
    
    // MARK: - Published Profile State
    
    @Published var currentProfile: EnhancedPlayerProfile?
    @Published var isLoading: Bool = false
    @Published var syncStatus: ProfileSyncStatus = .idle
    @Published var lastSyncDate: Date?
    
    // MARK: - Cultural Progress State
    
    @Published var culturalEducationProgress: CulturalEducationProgress
    @Published var culturalPreferences: CulturalPreferences
    @Published var regionalMasteries: [RomanianRegion: RegionalMastery] = [:]
    @Published var traditionalTechniqueMasteries: [String: TechniqueMastery] = [:]
    @Published var culturalEngagementMetrics: CulturalEngagementMetrics
    
    // MARK: - Achievement Integration
    
    @Published var achievementProgress: [UUID: AchievementProgress] = [:]
    @Published var unlockedContent: [UnlockableContent] = []
    @Published var culturalMilestones: [CulturalMilestone] = []
    @Published var seasonalCelebrations: [RomanianCulturalCelebration: CelebrationProgress] = [:]
    
    // MARK: - Cross-Device State
    
    @Published var deviceProfiles: [String: DeviceProfile] = [:]
    @Published var crossDeviceProgress: CrossDeviceProgress
    @Published var pendingSyncOperations: [SyncOperation] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Profile Sync Status
    
    enum ProfileSyncStatus {
        case idle
        case syncing
        case offline
        case error(String)
        case conflictDetected([ProfileConflict])
    }
    
    // MARK: - Initialization
    
    init(
        cloudKitManager: SepticaCloudKitManager,
        achievementManager: RomanianCulturalAchievementManager,
        milestoneTracker: TraditionalGameplayMilestoneTracker,
        errorManager: ErrorManager?
    ) {
        self.cloudKitManager = cloudKitManager
        self.achievementManager = achievementManager
        self.milestoneTracker = milestoneTracker
        self.errorManager = errorManager
        
        // Initialize default values
        self.culturalEducationProgress = CulturalEducationProgress()
        self.culturalPreferences = CulturalPreferences()
        self.culturalEngagementMetrics = CulturalEngagementMetrics()
        self.crossDeviceProgress = CrossDeviceProgress()
        
        setupSubscriptions()
        
        Task {
            await loadPlayerProfile()
            await initializeRegionalMasteries()
            await setupPeriodicSync()
        }
    }
    
    private func setupSubscriptions() {
        // Listen for achievement progress updates
        achievementManager.$achievementProgress
            .sink { [weak self] progress in
                self?.achievementProgress = progress
            }
            .store(in: &cancellables)
        
        // Listen for milestone achievements
        NotificationCenter.default.publisher(for: .traditionalMilestoneAchieved)
            .compactMap { $0.object as? TraditionalMilestone }
            .sink { [weak self] milestone in
                Task { @MainActor in
                    await self?.processMilestone(milestone)
                }
            }
            .store(in: &cancellables)
        
        // Listen for achievement unlocks
        NotificationCenter.default.publisher(for: .achievementUnlocked)
            .compactMap { $0.object as? RomanianAchievement }
            .sink { [weak self] achievement in
                Task { @MainActor in
                    await self?.processAchievementUnlock(achievement)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Profile Loading and Creation
    
    func loadPlayerProfile() async {
        isLoading = true
        syncStatus = .syncing
        
        do {
            let playerID = getCurrentPlayerID()
            
            // Try to load from CloudKit first
            if let cloudProfile = try await cloudKitManager.loadEnhancedPlayerProfile(playerID: playerID) {
                await processLoadedProfile(cloudProfile)
            } else {
                // Create new profile for first-time player
                await createNewPlayerProfile()
            }
            
            syncStatus = .idle
            lastSyncDate = Date()
        } catch {
            syncStatus = .error(error.localizedDescription)
            errorManager?.reportError(
                .saveDataCorruption(message: "Profile loading failed: \(error.localizedDescription)"),
                context: "EnhancedPlayerProfileManager.loadPlayerProfile"
            )
            
            // Fall back to local profile
            await loadLocalProfile()
        }
        
        isLoading = false
    }
    
    private func createNewPlayerProfile() async {
        let playerID = getCurrentPlayerID()
        let deviceID = getCurrentDeviceID()
        
        let newProfile = EnhancedPlayerProfile(
            playerID: playerID,
            displayName: "Romanian Player",
            email: nil,
            createdDate: Date(),
            lastActiveDate: Date(),
            
            // Game Progress
            currentArena: .sateImarica,
            trophies: 0,
            totalGamesPlayed: 0,
            totalWins: 0,
            currentWinStreak: 0,
            longestWinStreak: 0,
            preferredDifficulty: .medium,
            
            // Cultural Progress
            culturalLevel: 1,
            culturalExperiencePoints: 0,
            culturalKnowledgePoints: 0,
            heritageEngagementLevel: 0.0,
            authenticityScore: 0.0,
            
            // Achievements
            unlockedAchievements: [],
            achievementProgress: [:],
            culturalMilestones: [],
            
            // Cultural Preferences
            preferredLanguage: .romanian,
            culturalContentEnabled: true,
            selectedRegionalStyle: .general,
            musicPreferences: CulturalMusicPreferences(),
            visualPreferences: CulturalVisualPreferences(),
            educationalPreferences: EducationalPreferences(),
            
            // Seasonal Engagement
            seasonalCelebrations: initializeSeasonalCelebrations(),
            culturalCalendarParticipation: [:],
            
            // Cross-Device Data
            deviceProfiles: [deviceID: createCurrentDeviceProfile()],
            crossDeviceSettings: CrossDeviceSettings(),
            lastSyncTimestamp: Date(),
            syncVersion: 1
        )
        
        currentProfile = newProfile
        await updateLocalState(from: newProfile)
        await saveProfileToCloudKit(newProfile)
        
        // Initialize cultural masteries
        await initializeRegionalMasteries()
        await initializeTechniqueMasteries()
    }
    
    private func processLoadedProfile(_ profile: EnhancedPlayerProfile) async {
        currentProfile = profile
        await updateLocalState(from: profile)
        
        // Merge with any local changes
        await reconcileLocalChanges(profile)
        
        // Update device-specific data
        await updateDeviceProfile(profile)
    }
    
    // MARK: - Cultural Progress Management
    
    func updateCulturalPreferences(_ preferences: CulturalPreferences) async {
        culturalPreferences = preferences
        
        guard var profile = currentProfile else { return }
        profile.visualPreferences = preferences.visualPreferences
        profile.musicPreferences = preferences.musicPreferences
        profile.educationalPreferences = preferences.educationalPreferences
        profile.selectedRegionalStyle = preferences.selectedRegionalStyle
        
        currentProfile = profile
        await saveProfileChanges()
    }
    
    func updateRegionalMastery(_ region: RomanianRegion, mastery: RegionalMastery) async {
        regionalMasteries[region] = mastery
        
        guard var profile = currentProfile else { return }
        // Update regional progress in profile
        // This would integrate with existing regional progress tracking
        
        currentProfile = profile
        await saveProfileChanges()
        
        // Check for regional mastery achievements
        await checkRegionalMasteryAchievements(region: region, mastery: mastery)
    }
    
    func updateCulturalEngagement(_ engagement: CulturalEngagementMetrics) async {
        culturalEngagementMetrics = engagement
        
        guard var profile = currentProfile else { return }
        profile.heritageEngagementLevel = engagement.overallEngagement
        profile.authenticityScore = engagement.authenticityScore
        
        // Update cultural level based on engagement
        let newLevel = calculateCulturalLevel(
            experiencePoints: profile.culturalExperiencePoints,
            engagement: engagement.overallEngagement
        )
        
        if newLevel > profile.culturalLevel {
            profile.culturalLevel = newLevel
            await celebrateCulturalLevelUp(newLevel: newLevel)
        }
        
        currentProfile = profile
        await saveProfileChanges()
    }
    
    func participateInSeasonalCelebration(_ celebration: RomanianCulturalCelebration) async {
        guard var profile = currentProfile else { return }
        
        var celebrationProgress = seasonalCelebrations[celebration] ?? CelebrationProgress(celebration: celebration)
        celebrationProgress.hasParticipated = true
        celebrationProgress.participationDate = Date()
        celebrationProgress.participationCount += 1
        
        seasonalCelebrations[celebration] = celebrationProgress
        profile.seasonalCelebrations[celebration.rawValue] = celebrationProgress
        
        // Award celebration rewards
        await awardCelebrationRewards(celebration: celebration, progress: celebrationProgress)
        
        currentProfile = profile
        await saveProfileChanges()
    }
    
    // MARK: - Achievement Integration
    
    private func processMilestone(_ milestone: TraditionalMilestone) async {
        let culturalMilestone = CulturalMilestone(
            id: milestone.id,
            type: milestone.type.culturalType,
            name: milestone.name,
            description: milestone.description,
            culturalSignificance: milestone.culturalSignificance,
            timestamp: milestone.timestamp,
            experiencePoints: milestone.experiencePoints,
            culturalPoints: milestone.culturalPoints,
            region: extractRegion(from: milestone)
        )
        
        culturalMilestones.append(culturalMilestone)
        
        // Update profile
        guard var profile = currentProfile else { return }
        profile.culturalMilestones.append(culturalMilestone)
        profile.culturalExperiencePoints += milestone.experiencePoints
        profile.culturalKnowledgePoints += milestone.culturalPoints
        
        currentProfile = profile
        await saveProfileChanges()
        
        // Check for level up
        await checkCulturalLevelUp(profile: profile)
    }
    
    private func processAchievementUnlock(_ achievement: RomanianAchievement) async {
        guard var profile = currentProfile else { return }
        
        // Add to unlocked achievements
        if !profile.unlockedAchievements.contains(achievement.id) {
            profile.unlockedAchievements.append(achievement.id)
            profile.culturalExperiencePoints += achievement.experiencePoints
            profile.culturalKnowledgePoints += achievement.culturalKnowledgePoints
            
            // Unlock content
            unlockedContent.append(contentsOf: achievement.unlockableContent)
            
            currentProfile = profile
            await saveProfileChanges()
            
            // Award unlockable content
            await awardUnlockableContent(achievement.unlockableContent)
        }
    }
    
    // MARK: - Cross-Device Synchronization
    
    func syncWithCloudKit() async {
        guard let profile = currentProfile else { return }
        
        syncStatus = .syncing
        
        do {
            // Check for conflicts
            let serverProfile = try await cloudKitManager.loadEnhancedPlayerProfile(playerID: profile.playerID)
            
            if let serverProfile = serverProfile {
                let conflicts = detectProfileConflicts(local: profile, server: serverProfile)
                
                if !conflicts.isEmpty {
                    syncStatus = .conflictDetected(conflicts)
                    return
                }
            }
            
            // Update sync timestamp and device info
            var updatedProfile = profile
            updatedProfile.lastSyncTimestamp = Date()
            updatedProfile.deviceProfiles[getCurrentDeviceID()] = createCurrentDeviceProfile()
            updatedProfile.syncVersion += 1
            
            // Save to CloudKit
            try await cloudKitManager.saveEnhancedPlayerProfile(updatedProfile)
            
            currentProfile = updatedProfile
            syncStatus = .idle
            lastSyncDate = Date()
            
        } catch {
            syncStatus = .error(error.localizedDescription)
            errorManager?.reportError(
                .networkError(message: "CloudKit sync failed: \(error.localizedDescription)"),
                context: "EnhancedPlayerProfileManager.syncWithCloudKit"
            )
        }
    }
    
    func resolveProfileConflicts(_ conflicts: [ProfileConflict], resolution: ConflictResolution) async {
        guard let localProfile = currentProfile else { return }
        
        do {
            let serverProfile = try await cloudKitManager.loadEnhancedPlayerProfile(playerID: localProfile.playerID)
            guard let serverProfile = serverProfile else { return }
            
            let resolvedProfile = await resolveConflicts(
                local: localProfile,
                server: serverProfile,
                conflicts: conflicts,
                resolution: resolution
            )
            
            currentProfile = resolvedProfile
            await saveProfileToCloudKit(resolvedProfile)
            syncStatus = .idle
            
        } catch {
            syncStatus = .error("Conflict resolution failed: \(error.localizedDescription)")
        }
    }
    
    private func detectProfileConflicts(local: EnhancedPlayerProfile, server: EnhancedPlayerProfile) -> [ProfileConflict] {
        var conflicts: [ProfileConflict] = []
        
        // Check sync version
        if local.syncVersion != server.syncVersion {
            conflicts.append(.syncVersionMismatch(local: local.syncVersion, server: server.syncVersion))
        }
        
        // Check achievement progress conflicts
        for (achievementId, localProgress) in local.achievementProgress {
            if let serverProgress = server.achievementProgress[achievementId] {
                if localProgress.currentValue != serverProgress.currentValue {
                    conflicts.append(.achievementProgress(
                        achievementId: achievementId,
                        localValue: localProgress.currentValue,
                        serverValue: serverProgress.currentValue
                    ))
                }
            }
        }
        
        // Check cultural progress conflicts
        if local.culturalExperiencePoints != server.culturalExperiencePoints {
            conflicts.append(.culturalProgress(
                local: local.culturalExperiencePoints,
                server: server.culturalExperiencePoints
            ))
        }
        
        return conflicts
    }
    
    private func resolveConflicts(
        local: EnhancedPlayerProfile,
        server: EnhancedPlayerProfile,
        conflicts: [ProfileConflict],
        resolution: ConflictResolution
    ) async -> EnhancedPlayerProfile {
        var resolvedProfile = local
        
        switch resolution {
        case .useLocal:
            resolvedProfile = local
        case .useServer:
            resolvedProfile = server
        case .merge:
            resolvedProfile = await mergeProfiles(local: local, server: server)
        case .custom(let customResolution):
            resolvedProfile = await applyCustomResolution(
                local: local,
                server: server,
                customResolution: customResolution
            )
        }
        
        // Update sync metadata
        resolvedProfile.lastSyncTimestamp = Date()
        resolvedProfile.syncVersion = max(local.syncVersion, server.syncVersion) + 1
        
        return resolvedProfile
    }
    
    // MARK: - Utility Methods
    
    private func initializeRegionalMasteries() async {
        for region in RomanianRegion.allCases {
            if regionalMasteries[region] == nil {
                regionalMasteries[region] = RegionalMastery(region: region)
            }
        }
    }
    
    private func initializeTechniqueMasteries() async {
        let techniques = ["septe_wild_mastery", "opt_timing_mastery", "moldovan_patience", 
                         "transylvanian_efficiency", "wallachian_rhythm", "carpathian_wisdom"]
        
        for technique in techniques {
            if traditionalTechniqueMasteries[technique] == nil {
                traditionalTechniqueMasteries[technique] = TechniqueMastery(techniqueId: technique)
            }
        }
    }
    
    private func initializeSeasonalCelebrations() -> [String: CelebrationProgress] {
        var celebrations: [String: CelebrationProgress] = [:]
        
        for celebration in RomanianCulturalCelebration.allCases {
            celebrations[celebration.rawValue] = CelebrationProgress(celebration: celebration)
        }
        
        return celebrations
    }
    
    private func calculateCulturalLevel(experiencePoints: Int, engagement: Float) -> Int {
        let baseLevel = experiencePoints / 1000 // 1000 XP per level
        let engagementBonus = Int(engagement * 2) // Engagement can add up to 2 levels
        return max(1, baseLevel + engagementBonus)
    }
    
    private func getCurrentPlayerID() -> String {
        // Implementation would get unique player ID (iCloud, device-based, etc.)
        return UserDefaults.standard.string(forKey: "player_id") ?? UUID().uuidString
    }
    
    private func getCurrentDeviceID() -> String {
        return UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    }
    
    private func createCurrentDeviceProfile() -> DeviceProfile {
        return DeviceProfile(
            deviceId: getCurrentDeviceID(),
            deviceName: UIDevice.current.name,
            deviceType: UIDevice.current.model,
            systemVersion: UIDevice.current.systemVersion,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            lastActive: Date(),
            capabilities: DeviceCapabilities()
        )
    }
    
    private func updateLocalState(from profile: EnhancedPlayerProfile) async {
        culturalEducationProgress = CulturalEducationProgress(from: profile)
        culturalPreferences = CulturalPreferences(from: profile)
        
        // Update achievement progress
        achievementProgress = profile.achievementProgress
        
        // Update cultural milestones
        culturalMilestones = profile.culturalMilestones
        
        // Update seasonal celebrations
        for (key, progress) in profile.seasonalCelebrations {
            if let celebration = RomanianCulturalCelebration(rawValue: key) {
                seasonalCelebrations[celebration] = progress
            }
        }
    }
    
    private func saveProfileChanges() async {
        guard let profile = currentProfile else { return }
        
        // Save locally first
        saveLocalProfile(profile)
        
        // Queue for CloudKit sync
        let operation = SyncOperation(
            type: .profileUpdate,
            timestamp: Date(),
            data: profile
        )
        pendingSyncOperations.append(operation)
        
        // Perform immediate sync if online
        if syncStatus != .offline {
            await syncWithCloudKit()
        }
    }
    
    private func saveProfileToCloudKit(_ profile: EnhancedPlayerProfile) async {
        do {
            try await cloudKitManager.saveEnhancedPlayerProfile(profile)
        } catch {
            errorManager?.reportError(
                .networkError(message: "CloudKit save failed: \(error.localizedDescription)"),
                context: "EnhancedPlayerProfileManager.saveProfileToCloudKit"
            )
        }
    }
    
    private func saveLocalProfile(_ profile: EnhancedPlayerProfile) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(profile)
            UserDefaults.standard.set(data, forKey: "enhanced_player_profile")
        } catch {
            errorManager?.reportError(
                .saveDataCorruption(message: "Local profile save failed: \(error.localizedDescription)"),
                context: "EnhancedPlayerProfileManager.saveLocalProfile"
            )
        }
    }
    
    private func loadLocalProfile() async {
        guard let data = UserDefaults.standard.data(forKey: "enhanced_player_profile") else {
            await createNewPlayerProfile()
            return
        }
        
        do {
            let decoder = JSONDecoder()
            let profile = try decoder.decode(EnhancedPlayerProfile.self, from: data)
            currentProfile = profile
            await updateLocalState(from: profile)
            syncStatus = .offline
        } catch {
            await createNewPlayerProfile()
        }
    }
    
    private func setupPeriodicSync() async {
        // Setup periodic CloudKit sync every 5 minutes when app is active
        Timer.publish(every: 300, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor in
                    if self?.syncStatus == .idle {
                        await self?.syncWithCloudKit()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Achievement and Milestone Helpers
    
    private func checkCulturalLevelUp(profile: EnhancedPlayerProfile) async {
        let newLevel = calculateCulturalLevel(
            experiencePoints: profile.culturalExperiencePoints,
            engagement: profile.heritageEngagementLevel
        )
        
        if newLevel > profile.culturalLevel {
            await celebrateCulturalLevelUp(newLevel: newLevel)
        }
    }
    
    private func celebrateCulturalLevelUp(newLevel: Int) async {
        // Trigger level up celebration
        NotificationCenter.default.post(
            name: .culturalLevelUp,
            object: CulturalLevelUpEvent(newLevel: newLevel)
        )
    }
    
    private func checkRegionalMasteryAchievements(region: RomanianRegion, mastery: RegionalMastery) async {
        // Check if this mastery level unlocks any achievements
        await achievementManager.checkRegionalMasteryAchievements(region: region, mastery: mastery)
    }
    
    private func awardCelebrationRewards(celebration: RomanianCulturalCelebration, progress: CelebrationProgress) async {
        // Award seasonal celebration rewards
        let rewards = celebration.celebrationRewards
        for reward in rewards {
            await awardUnlockableContent([UnlockableContent.culturalFact(id: reward)])
        }
    }
    
    private func awardUnlockableContent(_ content: [UnlockableContent]) async {
        unlockedContent.append(contentsOf: content)
        
        // Notify content unlock systems
        for item in content {
            NotificationCenter.default.post(
                name: .contentUnlocked,
                object: item
            )
        }
    }
    
    private func extractRegion(from milestone: TraditionalMilestone) -> RomanianRegion? {
        // Extract region from milestone context if applicable
        return nil // Implementation would depend on milestone structure
    }
    
    private func reconcileLocalChanges(_ serverProfile: EnhancedPlayerProfile) async {
        // Reconcile any local changes with server data
        // This is a placeholder for conflict-free merging logic
    }
    
    private func updateDeviceProfile(_ profile: EnhancedPlayerProfile) async {
        guard var updatedProfile = currentProfile else { return }
        
        let deviceId = getCurrentDeviceID()
        updatedProfile.deviceProfiles[deviceId] = createCurrentDeviceProfile()
        
        currentProfile = updatedProfile
    }
    
    private func mergeProfiles(local: EnhancedPlayerProfile, server: EnhancedPlayerProfile) async -> EnhancedPlayerProfile {
        // Implement intelligent profile merging
        var merged = local
        
        // Take maximum values for cumulative stats
        merged.totalGamesPlayed = max(local.totalGamesPlayed, server.totalGamesPlayed)
        merged.totalWins = max(local.totalWins, server.totalWins)
        merged.culturalExperiencePoints = max(local.culturalExperiencePoints, server.culturalExperiencePoints)
        merged.culturalKnowledgePoints = max(local.culturalKnowledgePoints, server.culturalKnowledgePoints)
        
        // Merge unlocked achievements
        let allAchievements = Set(local.unlockedAchievements + server.unlockedAchievements)
        merged.unlockedAchievements = Array(allAchievements)
        
        // Merge device profiles
        merged.deviceProfiles = local.deviceProfiles.merging(server.deviceProfiles) { _, server in server }
        
        return merged
    }
    
    private func applyCustomResolution(
        local: EnhancedPlayerProfile,
        server: EnhancedPlayerProfile,
        customResolution: [String: Any]
    ) async -> EnhancedPlayerProfile {
        // Apply custom conflict resolution rules
        return local // Placeholder implementation
    }
}

// MARK: - Supporting Data Models

struct EnhancedPlayerProfile: Codable {
    let playerID: String
    var displayName: String
    var email: String?
    let createdDate: Date
    var lastActiveDate: Date
    
    // Game Progress
    var currentArena: RomanianArena
    var trophies: Int
    var totalGamesPlayed: Int
    var totalWins: Int
    var currentWinStreak: Int
    var longestWinStreak: Int
    var preferredDifficulty: AIDifficulty
    
    // Cultural Progress
    var culturalLevel: Int
    var culturalExperiencePoints: Int
    var culturalKnowledgePoints: Int
    var heritageEngagementLevel: Float
    var authenticityScore: Float
    
    // Achievements
    var unlockedAchievements: [UUID]
    var achievementProgress: [UUID: AchievementProgress]
    var culturalMilestones: [CulturalMilestone]
    
    // Cultural Preferences
    var preferredLanguage: PreferredLanguage
    var culturalContentEnabled: Bool
    var selectedRegionalStyle: RomanianRegion
    var musicPreferences: CulturalMusicPreferences
    var visualPreferences: CulturalVisualPreferences
    var educationalPreferences: EducationalPreferences
    
    // Seasonal Engagement
    var seasonalCelebrations: [String: CelebrationProgress]
    var culturalCalendarParticipation: [String: Date]
    
    // Cross-Device Data
    var deviceProfiles: [String: DeviceProfile]
    var crossDeviceSettings: CrossDeviceSettings
    var lastSyncTimestamp: Date
    var syncVersion: Int
}

enum AIDifficulty: String, Codable {
    case easy, medium, hard, expert
}

enum PreferredLanguage: String, Codable {
    case romanian, english, bilingual
}

struct CulturalPreferences {
    var visualPreferences: CulturalVisualPreferences
    var musicPreferences: CulturalMusicPreferences
    var educationalPreferences: EducationalPreferences
    var selectedRegionalStyle: RomanianRegion
    
    init() {
        self.visualPreferences = CulturalVisualPreferences()
        self.musicPreferences = CulturalMusicPreferences()
        self.educationalPreferences = EducationalPreferences()
        self.selectedRegionalStyle = .general
    }
    
    init(from profile: EnhancedPlayerProfile) {
        self.visualPreferences = profile.visualPreferences
        self.musicPreferences = profile.musicPreferences
        self.educationalPreferences = profile.educationalPreferences
        self.selectedRegionalStyle = profile.selectedRegionalStyle
    }
}

struct CulturalMusicPreferences: Codable {
    var enableTraditionalMusic: Bool = true
    var preferredRegionalStyle: RomanianRegion = .general
    var volumeLevel: Float = 0.7
    var autoPlayDuringCelebrations: Bool = true
    var favoriteTrackIds: [String] = []
}

struct CulturalVisualPreferences: Codable {
    var enableCulturalThemes: Bool = true
    var preferredColorScheme: String = "traditional_romanian"
    var enableSeasonalDecorations: Bool = true
    var animationIntensity: Float = 0.8
    var culturalSymbolsEnabled: Bool = true
}

struct EducationalPreferences: Codable {
    var enableCulturalEducation: Bool = true
    var preferredLearningStyle: LearningStyle = .interactive
    var difficultyLevel: EducationalDifficulty = .intermediate
    var enableQuizzes: Bool = true
    var enableFolkloreContent: Bool = true
}

enum LearningStyle: String, Codable {
    case visual, auditory, interactive, reading
}

enum EducationalDifficulty: String, Codable {
    case beginner, intermediate, advanced
}

struct RegionalMastery: Codable {
    let region: RomanianRegion
    var level: MasteryLevel = .novice
    var experiencePoints: Int = 0
    var gamesPlayed: Int = 0
    var gamesWon: Int = 0
    var authenticity: Float = 0.0
    var lastProgress: Date?
}

struct TechniqueMastery: Codable {
    let techniqueId: String
    var level: MasteryLevel = .novice
    var successfulUses: Int = 0
    var totalAttempts: Int = 0
    var lastUsed: Date?
    
    var successRate: Float {
        guard totalAttempts > 0 else { return 0 }
        return Float(successfulUses) / Float(totalAttempts)
    }
}

struct CulturalEngagementMetrics: Codable {
    var educationalContentViewed: Int = 0
    var quizzesCompleted: Int = 0
    var folkloreStoriesRead: Int = 0
    var culturalFactsLearned: Int = 0
    var authenticityScore: Float = 0.0
    var engagementScore: Float = 0.0
    var lastEngagement: Date?
    
    var overallEngagement: Float {
        let factors = [
            Float(educationalContentViewed) / 100.0,
            Float(quizzesCompleted) / 50.0,
            Float(folkloreStoriesRead) / 25.0,
            authenticityScore,
            engagementScore
        ]
        return factors.reduce(0, +) / Float(factors.count)
    }
}

struct CulturalMilestone: Codable, Identifiable {
    let id: UUID
    let type: CulturalMilestoneType
    let name: String
    let description: String
    let culturalSignificance: String
    let timestamp: Date
    let experiencePoints: Int
    let culturalPoints: Int
    let region: RomanianRegion?
}

enum CulturalMilestoneType: String, Codable {
    case strategicExcellence
    case culturalTradition
    case regionalMastery
    case heritageEngagement
    case educationalAchievement
    case seasonalParticipation
}

struct CelebrationProgress: Codable {
    let celebration: RomanianCulturalCelebration
    var hasParticipated: Bool = false
    var participationDate: Date?
    var participationCount: Int = 0
    var rewardsEarned: [String] = []
    var completionPercentage: Float = 0.0
}

struct DeviceProfile: Codable {
    let deviceId: String
    let deviceName: String
    let deviceType: String
    let systemVersion: String
    let appVersion: String
    var lastActive: Date
    let capabilities: DeviceCapabilities
}

struct DeviceCapabilities: Codable {
    var supportsCloudKit: Bool = true
    var supportsHaptics: Bool = true
    var supportsAdvancedGraphics: Bool = true
    var supportsCulturalContent: Bool = true
}

struct CrossDeviceProgress: Codable {
    var sharedAchievements: [UUID] = []
    var sharedCulturalProgress: Float = 0.0
    var lastCrossDeviceSync: Date?
    var pendingSync: Bool = false
}

struct CrossDeviceSettings: Codable {
    var syncAchievements: Bool = true
    var syncCulturalProgress: Bool = true
    var syncPreferences: Bool = true
    var autoSync: Bool = true
    var syncOnlyOnWiFi: Bool = false
}

enum ProfileConflict {
    case syncVersionMismatch(local: Int, server: Int)
    case achievementProgress(achievementId: UUID, localValue: Int, serverValue: Int)
    case culturalProgress(local: Int, server: Int)
    case preferenceConflict(key: String, localValue: Any, serverValue: Any)
}

enum ConflictResolution {
    case useLocal
    case useServer
    case merge
    case custom([String: Any])
}

struct SyncOperation {
    let type: SyncOperationType
    let timestamp: Date
    let data: Any
}

enum SyncOperationType {
    case profileUpdate
    case achievementProgress
    case culturalMilestone
    case preferenceChange
}

struct CulturalLevelUpEvent {
    let newLevel: Int
}

extension MilestoneType {
    var culturalType: CulturalMilestoneType {
        switch self {
        case .strategicExcellence: return .strategicExcellence
        case .culturalTradition: return .culturalTradition
        case .regionalMastery: return .regionalMastery
        case .heritageEngagement: return .heritageEngagement
        case .techniqueMastery: return .strategicExcellence
        case .authenticityAchievement: return .culturalTradition
        }
    }
}

extension CulturalEducationProgress {
    init() {
        self.gameRulesLearned = []
        self.folkTalesRead = 0
        self.traditionalMusicKnowledge = 0
        self.cardHistoryKnowledge = 0
        self.quizScores = [:]
        self.culturalBadges = []
    }
    
    init(from profile: EnhancedPlayerProfile) {
        self.gameRulesLearned = []
        self.folkTalesRead = 0
        self.traditionalMusicKnowledge = 0
        self.cardHistoryKnowledge = 0
        self.quizScores = [:]
        self.culturalBadges = []
        // Map from profile data if available
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let culturalLevelUp = Notification.Name("culturalLevelUp")
    static let contentUnlocked = Notification.Name("contentUnlocked")
}