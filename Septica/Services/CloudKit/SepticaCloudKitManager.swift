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
                if isReachable && !self?.offlineSyncQueue.isEmpty() {
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
    
    /// Save player profile to CloudKit with Romanian cultural elements
    func syncPlayerProfile(_ profile: PlayerProfile) async throws {
        guard isAvailable && networkReachable else {
            await queueOfflineUpdate(.playerProfile(profile))
            return
        }
        
        syncStatus = .syncing(.playerProfile)
        logger.info("🔄 Syncing Romanian player profile...")
        
        do {
            // Create CloudKit record from player profile
            let recordID = CKRecord.ID(recordName: profile.cloudKitIdentifier)
            let record = CKRecord(recordType: "PlayerProfile", recordID: recordID)
            
            // Populate Romanian cultural data
            try await profile.populateCloudKitRecord(record)
            
            // Add Romanian cultural metadata
            record["culturalVersion"] = "1.0" as CKRecordValue
            record["romanianAuthenticity"] = true as CKRecordValue
            record["syncTimestamp"] = Date() as CKRecordValue
            
            let savedRecord = try await privateDatabase.save(record)
            
            await updateLastSyncDate()
            syncStatus = .success
            
            logger.info("✅ Romanian player profile synced successfully")
            
        } catch {
            syncStatus = .error(error)
            logger.error("❌ Failed to sync Romanian player profile: \(error.localizedDescription)")
            
            await queueOfflineUpdate(.playerProfile(profile))
            throw CloudKitError.syncFailed(error)
        }
    }
    
    /// Load player profile from CloudKit
    func loadPlayerProfile(playerID: String) async throws -> CloudKitPlayerProfile? {
        guard isAvailable else {
            throw CloudKitError.notAvailable
        }
        
        let recordID = CKRecord.ID(recordName: playerID)
        
        do {
            let record = try await privateDatabase.record(for: recordID)
            
            guard let profileData = record["profileData"] as? Data else {
                return nil
            }
            
            let decoder = JSONDecoder()
            let profile = try decoder.decode(CloudKitPlayerProfile.self, from: profileData)
            
            print("✅ Player profile loaded from CloudKit: \(profile.displayName)")
            return profile
            
        } catch CKError.unknownItem {
            // Record doesn't exist yet - return nil to create new profile
            return nil
        } catch {
            throw error
        }
    }
    
    /// Save game record with cultural analysis
    func saveGameRecord(_ record: CloudKitGameRecord) async throws {
        guard isAvailable else { return }
        
        let ckRecord = CKRecord(recordType: "GameRecord")
        
        let encoder = JSONEncoder()
        let recordData = try encoder.encode(record)
        
        ckRecord["recordData"] = recordData
        ckRecord["playerID"] = record.playerID
        ckRecord["gameResult"] = record.gameResult
        ckRecord["timestamp"] = record.timestamp
        ckRecord["arena"] = record.arenaAtTimeOfPlay.rawValue
        
        try await privateDatabase.save(ckRecord)
        
        print("✅ Game record saved: \(record.gameResult) in \(record.arenaAtTimeOfPlay.displayName)")
    }
    
    // MARK: - Helper Methods
    
    private func queueOfflineUpdate(_ update: CloudKitUpdate) async {
        await offlineSyncQueue.enqueue(update)
        logger.info("📱 Queued offline update: \(update.description)")
    }
    
    private func updateLastSyncDate() async {
        lastSyncDate = Date()
    }
    
    deinit {
        reachabilityMonitor.stopMonitoring()
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
    case playerProfile(PlayerProfile)
    case gameHistory([GameRecord])
    case culturalProgress(RomanianCulturalProgress)
    case achievements([RomanianAchievement])
    
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

enum CloudKitSyncStatus: String, CaseIterable {
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