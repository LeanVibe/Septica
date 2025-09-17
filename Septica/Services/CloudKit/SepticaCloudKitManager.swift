//
//  SepticaCloudKitManager.swift
//  Septica
//
//  CloudKit integration for Romanian Septica with Shuffle Cats-inspired progression
//  Supports fluid card interactions, cultural achievements, and arena progression
//

import CloudKit
import Foundation
import Combine
import OSLog
import UIKit

/// Main CloudKit service manager for Septica
/// Integrates Romanian cultural progression with engaging gameplay mechanics
@MainActor
class SepticaCloudKitManager: ObservableObject {
    
    // MARK: - Shared Instance
    
    static let shared = SepticaCloudKitManager()
    
    // MARK: - CloudKit Configuration
    
    private let container = CKContainer(identifier: "iCloud.dev.septica.romanian.game")
    private let privateDatabase: CKDatabase
    private let publicDatabase: CKDatabase
    private let sharedDatabase: CKDatabase
    
    // MARK: - Published State
    
    @Published var isAvailable: Bool = false
    @Published var accountStatus: CKAccountStatus = .couldNotDetermine
    @Published var syncStatus: CloudKitSyncStatus = .idle
    @Published var lastSyncDate: Date?
    @Published var conflictsRequiringAttention: [CloudKitConflict] = []
    @Published var networkReachable = true
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(subsystem: "Septica", category: "CloudKit")
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    
    // Romanian Cultural Configuration
    private let culturalDataContainer: String = "SepticaRomanianCulture"
    private let achievementContainer: String = "SepticaAchievements"
    private let statisticsContainer: String = "SepticaStatistics"
    
    // Offline synchronization and network monitoring
    private var offlineSyncQueue = OfflineSyncQueue()
    private var reachabilityMonitor = NetworkReachabilityMonitor()
    
    // MARK: - Initialization
    
    init() {
        self.privateDatabase = container.privateCloudDatabase
        self.publicDatabase = container.publicCloudDatabase
        self.sharedDatabase = container.sharedCloudDatabase
        
        Task {
            await checkCloudKitAvailability()
            await setupCloudKitSubscriptions()
            await setupReachabilityMonitoring()
        }
        
        logger.info("🏗️ SepticaCloudKitManager initialized for Romanian cultural preservation")
    }
    
    // MARK: - CloudKit Availability & Setup
    
    func checkCloudKitAvailability() async {
        do {
            accountStatus = try await container.accountStatus()
            isAvailable = (accountStatus == .available)
            
            if isAvailable {
                await initializeUserRecord()
            }
        } catch {
            print("❌ CloudKit availability check failed: \(error)")
            isAvailable = false
        }
    }
    
    private func initializeUserRecord() async {
        do {
            let userRecordID = try await container.userRecordID()
            print("✅ CloudKit user record initialized: \(userRecordID)")
        } catch {
            print("❌ Failed to initialize user record: \(error)")
        }
    }
    
    private func setupCloudKitSubscriptions() async {
        // Set up database change notifications for real-time sync
        do {
            let subscription = CKDatabaseSubscription(subscriptionID: "septica-database-changes")
            
            let notificationInfo = CKSubscription.NotificationInfo()
            notificationInfo.shouldSendContentAvailable = true
            subscription.notificationInfo = notificationInfo
            
            try await privateDatabase.save(subscription)
            print("✅ CloudKit subscription established")
        } catch {
            print("❌ Failed to setup CloudKit subscription: \(error)")
        }
    }
    
    // MARK: - Network Monitoring
    
    private func setupReachabilityMonitoring() async {
        reachabilityMonitor.startMonitoring { [weak self] isReachable in
            Task { @MainActor in
                self?.networkReachable = isReachable
                if isReachable && !(self?.offlineSyncQueue.isEmpty() ?? true) {
                    await self?.processPendingOfflineUpdates()
                }
            }
        }
    }
    
    private func processPendingOfflineUpdates() async {
        guard isAvailable && networkReachable else { return }
        
        logger.info("🔄 Processing pending offline Romanian cultural updates...")
        
        do {
            try await offlineSyncQueue.processAll()
            logger.info("✅ All offline Romanian updates processed successfully")
            
        } catch {
            logger.error("❌ Failed to process offline updates: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Core CloudKit Operations
    
    
    /// Load player profile from CloudKit with Romanian cultural data
    func loadPlayerProfile(playerID: String) async throws -> CloudKitPlayerProfile? {
        guard isAvailable else {
            throw CloudKitError.notAvailable
        }
        
        logger.info("🔽 Loading Romanian player profile: \(playerID)")
        
        let recordID = CKRecord.ID(recordName: playerID)
        
        do {
            let record = try await privateDatabase.record(for: recordID)
            
            // Decode complex data fields
            let decoder = JSONDecoder()
            
            let folkMusicData = record["folkMusicListened"] as? Data ?? Data()
            let folkMusicListened = try decoder.decode([String].self, from: folkMusicData)
            
            let culturalStoriesData = record["culturalStoriesRead"] as? Data ?? Data()
            let culturalStoriesRead = try decoder.decode([String].self, from: culturalStoriesData)
            
            let traditionalColorsData = record["traditionalColorsUnlocked"] as? Data ?? Data()
            let traditionalColorsUnlocked = try decoder.decode([String].self, from: traditionalColorsData)
            
            let achievementsData = record["achievements"] as? Data ?? Data()
            let achievementStrings = try decoder.decode([String].self, from: achievementsData)
            let achievements = achievementStrings.compactMap { CulturalAchievement(rawValue: $0) }
            
            let cardMasteriesData = record["cardMasteries"] as? Data ?? Data()
            let cardMasteries = try decoder.decode([String: CardMastery].self, from: cardMasteriesData)
            
            let culturalProgressData = record["culturalEducationProgress"] as? Data ?? Data()
            let culturalEducationProgress = try decoder.decode(CulturalEducationProgress.self, from: culturalProgressData)
            
            let preferencesData = record["preferences"] as? Data ?? Data()
            let preferences = try decoder.decode(GamePreferences.self, from: preferencesData)
            
            // Create profile from CloudKit record
            let profile = CloudKitPlayerProfile(
                playerID: playerID,
                displayName: record["displayName"] as? String ?? "Unknown Player",
                currentArena: RomanianArena(rawValue: record["currentArena"] as? Int ?? 0) ?? .sateImarica,
                trophies: record["trophies"] as? Int ?? 0,
                totalGamesPlayed: record["totalGamesPlayed"] as? Int ?? 0,
                totalWins: record["totalWins"] as? Int ?? 0,
                currentStreak: record["currentStreak"] as? Int ?? 0,
                longestStreak: record["longestStreak"] as? Int ?? 0,
                favoriteAIDifficulty: record["favoriteAIDifficulty"] as? String ?? "medium",
                cardMasteries: cardMasteries,
                achievements: achievements,
                seasonalProgress: SeasonalProgress(seasonID: "2025-winter", seasonTrophies: 0, seasonWins: 0, seasonChestsOpened: 0, seasonAchievements: [], celebrationParticipation: [:]),
                preferences: preferences,
                culturalEducationProgress: culturalEducationProgress,
                lastPlayedDate: record["lastPlayedDate"] as? Date ?? Date(),
                createdDate: record["createdDate"] as? Date ?? Date(),
                heritageEngagementLevel: record["heritageEngagementLevel"] as? Float ?? 0.0,
                folkMusicListened: folkMusicListened,
                culturalStoriesRead: culturalStoriesRead,
                traditionalColorsUnlocked: traditionalColorsUnlocked,
                selectedAvatar: record["selectedAvatar"] as? String ?? RomanianCharacterAvatar.traditionalPlayer.rawValue,
                selectedAvatarFrame: record["selectedAvatarFrame"] as? String ?? AvatarFrame.woodenFrame.rawValue,
                unlockedAvatars: [RomanianCharacterAvatar.traditionalPlayer.rawValue],
                unlockedAvatarFrames: [AvatarFrame.woodenFrame.rawValue]
            )
            
            logger.info("✅ Romanian player profile loaded: \(profile.displayName) - Arena: \(profile.currentArena.displayName)")
            return profile
            
        } catch CKError.unknownItem {
            // Record doesn't exist yet - return nil to create new profile
            logger.info("📱 No CloudKit profile found for \(playerID) - will create new")
            return nil
        } catch {
            logger.error("❌ Failed to load Romanian player profile: \(error.localizedDescription)")
            throw CloudKitError.fetchFailed(error)
        }
    }
    
    /// Save game record with Romanian cultural analysis
    func saveGameRecord(_ record: CloudKitGameRecord) async throws {
        guard isAvailable && networkReachable else {
            await queueOfflineUpdate(.gameHistory([record]))
            return
        }
        
        logger.info("🔄 Saving Romanian game record: \(record.gameResult) in \(record.arenaAtTimeOfPlay.displayName)")
        
        do {
            let ckRecord = CKRecord(recordType: "GameRecord", recordID: CKRecord.ID(recordName: record.gameID))
            
            // Core game data
            ckRecord["playerID"] = record.playerID as CKRecordValue
            ckRecord["gameResult"] = record.gameResult as CKRecordValue
            ckRecord["timestamp"] = record.timestamp as CKRecordValue
            ckRecord["arena"] = record.arenaAtTimeOfPlay.rawValue as CKRecordValue
            ckRecord["opponentType"] = record.opponentType as CKRecordValue
            ckRecord["aiDifficulty"] = record.aiDifficulty as CKRecordValue?
            ckRecord["gameDuration"] = record.gameDuration as CKRecordValue
            
            // Romanian cultural metrics
            ckRecord["sevenWildCardUses"] = record.sevenWildCardUses as CKRecordValue
            ckRecord["eightSpecialUses"] = record.eightSpecialUses as CKRecordValue
            ckRecord["tricksWon"] = record.tricksWon as CKRecordValue
            ckRecord["pointsScored"] = record.pointsScored as CKRecordValue
            
            // Encode complex data
            let encoder = JSONEncoder()
            
            let finalScoreData = try encoder.encode(record.finalScore)
            ckRecord["finalScore"] = finalScoreData as CKRecordValue
            
            let cardsPlayedData = try encoder.encode(record.cardsPlayed)
            ckRecord["cardsPlayed"] = cardsPlayedData as CKRecordValue
            
            let culturalMomentsData = try encoder.encode(record.culturalMomentsTriggered)
            ckRecord["culturalMomentsTriggered"] = culturalMomentsData as CKRecordValue
            
            let mistakesData = try encoder.encode(record.mistakesMade)
            ckRecord["mistakesMade"] = mistakesData as CKRecordValue
            
            let strategicMovesData = try encoder.encode(record.strategicMoves)
            ckRecord["strategicMoves"] = strategicMovesData as CKRecordValue
            
            // Romanian cultural metadata
            ckRecord["culturalVersion"] = "1.0" as CKRecordValue
            ckRecord["arenaDisplayName"] = record.arenaAtTimeOfPlay.displayName as CKRecordValue
            ckRecord["syncTimestamp"] = Date() as CKRecordValue
            
            _ = try await privateDatabase.save(ckRecord)
            
            logger.info("✅ Romanian game record saved: \(record.gameResult) in \(record.arenaAtTimeOfPlay.displayName)")
            
        } catch {
            logger.error("❌ Failed to save Romanian game record: \(error.localizedDescription)")
            await queueOfflineUpdate(.gameHistory([record]))
            throw CloudKitError.syncFailed(error)
        }
    }
    
    /// Save cultural education progress with Romanian heritage data
    func saveCulturalProgress(_ progress: CulturalEducationProgress) async throws {
        guard isAvailable && networkReachable else {
            await queueOfflineUpdate(.culturalProgress(progress))
            return
        }
        
        logger.info("🔄 Saving Romanian cultural progress")
        
        do {
            let recordID = CKRecord.ID(recordName: "cultural_progress_\(UUID().uuidString)")
            let record = CKRecord(recordType: "CulturalProgress", recordID: recordID)
            
            // Encode cultural progress data
            let encoder = JSONEncoder()
            let progressData = try encoder.encode(progress)
            record["progressData"] = progressData as CKRecordValue
            
            // Romanian cultural metadata
            record["folkTalesRead"] = progress.folkTalesRead as CKRecordValue
            record["traditionalMusicKnowledge"] = progress.traditionalMusicKnowledge as CKRecordValue
            record["cardHistoryKnowledge"] = progress.cardHistoryKnowledge as CKRecordValue
            record["culturalBadgesCount"] = progress.culturalBadges.count as CKRecordValue
            record["syncTimestamp"] = Date() as CKRecordValue
            
            _ = try await privateDatabase.save(record)
            
            await updateLastSyncDate()
            logger.info("✅ Romanian cultural progress saved successfully")
            
        } catch {
            logger.error("❌ Failed to save Romanian cultural progress: \(error.localizedDescription)")
            await queueOfflineUpdate(.culturalProgress(progress))
            throw CloudKitError.syncFailed(error)
        }
    }
    
    /// Save cultural achievements with Romanian heritage preservation
    func saveAchievements(_ achievements: [CulturalAchievement]) async throws {
        guard isAvailable && networkReachable else {
            await queueOfflineUpdate(.achievements(achievements))
            return
        }
        
        logger.info("🔄 Saving Romanian achievements (\(achievements.count) items)")
        
        do {
            let recordID = CKRecord.ID(recordName: "achievements_\(UUID().uuidString)")
            let record = CKRecord(recordType: "Achievements", recordID: recordID)
            
            // Encode achievements data
            let encoder = JSONEncoder()
            let achievementStrings = achievements.map { $0.rawValue }
            let achievementsData = try encoder.encode(achievementStrings)
            record["achievementsData"] = achievementsData as CKRecordValue
            
            // Romanian cultural metadata
            record["achievementCount"] = achievements.count as CKRecordValue
            record["culturalVersion"] = "1.0" as CKRecordValue
            record["syncTimestamp"] = Date() as CKRecordValue
            
            _ = try await privateDatabase.save(record)
            
            await updateLastSyncDate()
            logger.info("✅ Romanian achievements saved successfully (\(achievements.count) items)")
            
        } catch {
            logger.error("❌ Failed to save Romanian achievements: \(error.localizedDescription)")
            await queueOfflineUpdate(.achievements(achievements))
            throw CloudKitError.syncFailed(error)
        }
    }
    
    // MARK: - Helper Methods
    
    private func queueOfflineUpdate(_ update: CloudKitUpdate) async {
        offlineSyncQueue.enqueue(update)
        logger.info("📱 Queued offline update: \(update.description)")
    }
    
    private func updateLastSyncDate() async {
        lastSyncDate = Date()
    }
    
    deinit {
        Task { @MainActor in await reachabilityMonitor.stopMonitoring() }
        NotificationCenter.default.removeObserver(self)
        logger.info("🏁 SepticaCloudKitManager deinitialized")
    }
}

// MARK: - Supporting Types

/// CloudKit synchronization status
enum CloudKitSyncStatus: Equatable {
    case idle
    case syncing(CloudKitDataType)
    case success
    case error(Error)
    
    static func == (lhs: CloudKitSyncStatus, rhs: CloudKitSyncStatus) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.success, .success):
            return true
        case (.syncing(let lhsType), .syncing(let rhsType)):
            return lhsType == rhsType
        case (.error, .error):
            return true
        default:
            return false
        }
    }
}

/// Types of data being synchronized
enum CloudKitDataType {
    case playerProfile
    case gameHistory
    case culturalData
    case achievements
    case statistics
}

/// CloudKit synchronization update types
enum CloudKitUpdate: Codable {
    case playerProfile(CloudKitPlayerProfile)
    case gameHistory([CloudKitGameRecord])
    case culturalProgress(CulturalEducationProgress)
    case achievements([CulturalAchievement])
    
    var description: String {
        switch self {
        case .playerProfile: return "Player Profile"
        case .gameHistory(let games): return "Game History (\(games.count) games)"
        case .culturalProgress: return "Romanian Cultural Progress"
        case .achievements(let achievements): return "Romanian Achievements (\(achievements.count))"
        }
    }
}

/// CloudKit-related errors
enum CloudKitError: LocalizedError {
    case accountUnavailable
    case networkUnavailable
    case syncFailed(Error)
    case recordFetchFailed(Error)
    case fetchFailed(Error)
    case conflictResolutionFailed(Error)
    case notAvailable
    
    var errorDescription: String? {
        switch self {
        case .accountUnavailable:
            return "iCloud account is not available for Romanian cultural sync"
        case .networkUnavailable:
            return "Network connection required for Romanian cultural sync"
        case .syncFailed(let error):
            return "Failed to sync Romanian cultural data: \(error.localizedDescription)"
        case .recordFetchFailed(let error):
            return "Failed to fetch Romanian record: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch Romanian cultural data: \(error.localizedDescription)"
        case .conflictResolutionFailed(let error):
            return "Failed to resolve Romanian cultural data conflict: \(error.localizedDescription)"
        case .notAvailable:
            return "CloudKit is not available"
        }
    }
}

// MARK: - Romanian Cultural Extensions

extension SepticaCloudKitManager {
    
    /// Update card mastery with Romanian cultural significance
    func updateCardMastery(cardKey: String, wasSuccessful: Bool, isSpecialPlay: Bool = false) async {
        // This will be integrated with the main profile update system
        // Track individual card usage for Shuffle Cats-style progression
        print("🃏 Card mastery updated: \(cardKey) - Success: \(wasSuccessful) - Special: \(isSpecialPlay)")
    }
    
    /// Progress through Romanian arenas based on trophies
    func checkArenaProgression(currentTrophies: Int) -> RomanianArena {
        return RomanianArena.allCases.last { arena in
            currentTrophies >= arena.requiredTrophies
        } ?? .sateImarica
    }
    
    /// Unlock cultural achievement
    func unlockCulturalAchievement(_ achievement: CulturalAchievement) async {
        print("🏆 Cultural achievement unlocked: \(achievement.title)")
        // This will trigger UI celebration and educational content
    }
}

// MARK: - CloudKit Sync Status

enum CloudKitSyncState: String, CaseIterable {
    case idle = "idle"
    case syncing = "syncing"
    case uploading = "uploading"
    case downloading = "downloading"
    case conflictResolution = "conflict_resolution"
    case error = "error"
    
    var displayName: String {
        switch self {
        case .idle: return "Ready"
        case .syncing: return "Synchronizing..."
        case .uploading: return "Uploading Romanian heritage data..."
        case .downloading: return "Downloading cultural progress..."
        case .conflictResolution: return "Resolving conflicts..."
        case .error: return "Sync error"
        }
    }
}

// MARK: - Compatibility stubs

extension SepticaCloudKitManager {
    /// Save CloudKit player profile with Romanian cultural data
    @MainActor
    func savePlayerProfile(_ profile: CloudKitPlayerProfile) async throws {
        guard isAvailable && networkReachable else {
            await queueOfflineUpdate(.playerProfile(profile))
            return
        }
        
        syncStatus = .syncing(.playerProfile)
        logger.info("🔄 Saving Romanian player profile: \(profile.displayName)")
        
        do {
            let recordID = CKRecord.ID(recordName: profile.playerID)
            let record = CKRecord(recordType: "PlayerProfile", recordID: recordID)
            
            // Core player data
            record["displayName"] = profile.displayName as CKRecordValue
            record["currentArena"] = profile.currentArena.rawValue as CKRecordValue
            record["trophies"] = profile.trophies as CKRecordValue
            record["totalGamesPlayed"] = profile.totalGamesPlayed as CKRecordValue
            record["totalWins"] = profile.totalWins as CKRecordValue
            record["currentStreak"] = profile.currentStreak as CKRecordValue
            record["longestStreak"] = profile.longestStreak as CKRecordValue
            
            // Romanian cultural data
            record["heritageEngagementLevel"] = profile.heritageEngagementLevel as CKRecordValue
            record["selectedAvatar"] = profile.selectedAvatar as CKRecordValue
            record["selectedAvatarFrame"] = profile.selectedAvatarFrame as CKRecordValue
            
            // Encode complex data as JSON
            let encoder = JSONEncoder()
            
            let folkMusicData = try encoder.encode(profile.folkMusicListened)
            record["folkMusicListened"] = folkMusicData as CKRecordValue
            
            let culturalStoriesData = try encoder.encode(profile.culturalStoriesRead)
            record["culturalStoriesRead"] = culturalStoriesData as CKRecordValue
            
            let traditionalColorsData = try encoder.encode(profile.traditionalColorsUnlocked)
            record["traditionalColorsUnlocked"] = traditionalColorsData as CKRecordValue
            
            let achievementsData = try encoder.encode(profile.achievements.map { $0.rawValue })
            record["achievements"] = achievementsData as CKRecordValue
            
            let cardMasteriesData = try encoder.encode(profile.cardMasteries)
            record["cardMasteries"] = cardMasteriesData as CKRecordValue
            
            let culturalProgressData = try encoder.encode(profile.culturalEducationProgress)
            record["culturalEducationProgress"] = culturalProgressData as CKRecordValue
            
            let preferencesData = try encoder.encode(profile.preferences)
            record["preferences"] = preferencesData as CKRecordValue
            
            // Romanian cultural metadata
            record["culturalVersion"] = "1.0" as CKRecordValue
            record["romanianAuthenticity"] = true as CKRecordValue
            record["lastPlayedDate"] = profile.lastPlayedDate as CKRecordValue
            record["createdDate"] = profile.createdDate as CKRecordValue
            record["syncTimestamp"] = Date() as CKRecordValue
            
            _ = try await privateDatabase.save(record)
            
            await updateLastSyncDate()
            syncStatus = .success
            
            logger.info("✅ Romanian player profile saved successfully: \(profile.displayName)")
            
        } catch {
            syncStatus = .error(error)
            logger.error("❌ Failed to save Romanian player profile: \(error.localizedDescription)")
            
            await queueOfflineUpdate(.playerProfile(profile))
            throw CloudKitError.syncFailed(error)
        }
    }
}

// MARK: - CloudKit Conflict Resolution

struct CloudKitConflict: Identifiable {
    let id = UUID()
    let recordType: String
    let recordID: CKRecord.ID
    let serverRecord: CKRecord?
    let clientRecord: CKRecord
    let conflictType: ConflictType
    let culturalImpact: CulturalImpact
    
    enum ConflictType {
        case dataModified
        case recordDeleted
        case culturalProgressMismatch
        case achievementDuplicate
    }
    
    enum CulturalImpact {
        case none
        case minor           // Preferences, non-critical data
        case moderate        // Game statistics, partial cultural progress
        case significant     // Major cultural achievements, heritage milestones
        case critical        // Cultural education progress, rare achievements
        
        var requiresUserIntervention: Bool {
            return self == .significant || self == .critical
        }
    }
}
