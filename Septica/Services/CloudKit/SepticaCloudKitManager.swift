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
    
    // CloudKit record management
    private lazy var recordManager = CloudKitRecordManager(container: container)
    
    // Operation queues for batched operations
    private var pendingOperations: [String: CKDatabaseOperation] = [:]
    private let operationQueue = OperationQueue()
    
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
        
        let recordID = CKRecord.ID(recordName: "player_\(playerID)")
        
        do {
            let record = try await privateDatabase.record(for: recordID)
            let profile = try recordManager.parsePlayerProfileRecord(record)
            
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
            let ckRecord = try recordManager.createGameRecord(record)
            _ = try await privateDatabase.save(ckRecord)
            
            logger.info("✅ Romanian game record saved: \(record.gameResult) in \(record.arenaAtTimeOfPlay.displayName)")
            
        } catch {
            logger.error("❌ Failed to save Romanian game record: \(error.localizedDescription)")
            await queueOfflineUpdate(.gameHistory([record]))
            throw CloudKitError.syncFailed(error)
        }
    }
    
    /// Save cultural education progress with Romanian heritage data
    func saveCulturalProgress(_ progress: CulturalEducationProgress, playerID: String) async throws {
        guard isAvailable && networkReachable else {
            await queueOfflineUpdate(.culturalProgress(progress))
            return
        }
        
        logger.info("🔄 Saving Romanian cultural progress for player: \(playerID)")
        
        do {
            let record = try recordManager.createCulturalProgressRecord(progress, playerID: playerID)
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
    func saveAchievements(_ achievements: [CulturalAchievement], playerID: String) async throws {
        guard isAvailable && networkReachable else {
            await queueOfflineUpdate(.achievements(achievements))
            return
        }
        
        logger.info("🔄 Saving Romanian achievements (\(achievements.count) items) for player: \(playerID)")
        
        do {
            // Create individual records for each achievement to enable better querying
            for achievement in achievements {
                let record = try recordManager.createAchievementRecord(achievement, playerID: playerID, unlockedDate: Date())
                _ = try await privateDatabase.save(record)
            }
            
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
    
    // MARK: - Additional Data Operations
    
    /// Fetch game records for a player with pagination
    func fetchGameRecords(for playerID: String, limit: Int = 50) async throws -> [CloudKitGameRecord] {
        guard isAvailable else {
            throw CloudKitError.notAvailable
        }
        
        logger.info("🔽 Fetching game records for player: \(playerID)")
        
        let predicate = NSPredicate(format: "playerID == %@", playerID)
        let query = CKQuery(recordType: CloudKitRecordManager.RecordTypes.gameRecord, predicate: predicate)
        
        // Sort by timestamp descending (newest first)
        query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        do {
            let (matchResults, _) = try await privateDatabase.records(matching: query, resultsLimit: limit)
            
            var gameRecords: [CloudKitGameRecord] = []
            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    let gameRecord = try recordManager.parseGameRecord(record)
                    gameRecords.append(gameRecord)
                case .failure(let error):
                    logger.error("Failed to fetch game record: \(error.localizedDescription)")
                }
            }
            
            logger.info("✅ Fetched \(gameRecords.count) game records for player: \(playerID)")
            return gameRecords
            
        } catch {
            logger.error("❌ Failed to fetch game records: \(error.localizedDescription)")
            throw CloudKitError.fetchFailed(error)
        }
    }
    
    /// Fetch cultural progress for a player
    func fetchCulturalProgress(for playerID: String) async throws -> CulturalEducationProgress? {
        guard isAvailable else {
            throw CloudKitError.notAvailable
        }
        
        logger.info("🔽 Fetching cultural progress for player: \(playerID)")
        
        let recordID = CKRecord.ID(recordName: "cultural_\(playerID)")
        
        do {
            let record = try await privateDatabase.record(for: recordID)
            let progress = try recordManager.parseCulturalProgressRecord(record)
            
            logger.info("✅ Cultural progress fetched for player: \(playerID)")
            return progress
            
        } catch CKError.unknownItem {
            logger.info("📱 No cultural progress found for player: \(playerID)")
            return nil
        } catch {
            logger.error("❌ Failed to fetch cultural progress: \(error.localizedDescription)")
            throw CloudKitError.fetchFailed(error)
        }
    }
    
    /// Fetch achievements for a player
    func fetchAchievements(for playerID: String) async throws -> [CulturalAchievement] {
        guard isAvailable else {
            throw CloudKitError.notAvailable
        }
        
        logger.info("🔽 Fetching achievements for player: \(playerID)")
        
        let predicate = NSPredicate(format: "playerID == %@", playerID)
        let query = CKQuery(recordType: CloudKitRecordManager.RecordTypes.achievement, predicate: predicate)
        
        do {
            let (matchResults, _) = try await privateDatabase.records(matching: query)
            
            var achievements: [CulturalAchievement] = []
            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    let (achievement, _, _) = try recordManager.parseAchievementRecord(record)
                    achievements.append(achievement)
                case .failure(let error):
                    logger.error("Failed to fetch achievement record: \(error.localizedDescription)")
                }
            }
            
            logger.info("✅ Fetched \(achievements.count) achievements for player: \(playerID)")
            return achievements
            
        } catch {
            logger.error("❌ Failed to fetch achievements: \(error.localizedDescription)")
            throw CloudKitError.fetchFailed(error)
        }
    }
    
    /// Batch save multiple records for efficiency
    func batchSaveRecords(_ records: [CKRecord]) async throws {
        guard isAvailable && networkReachable else {
            throw CloudKitError.networkUnavailable
        }
        
        logger.info("🔄 Batch saving \(records.count) CloudKit records")
        
        // CloudKit supports up to 400 records per batch operation
        let batchSize = 400
        let batches = records.chunked(into: batchSize)
        
        for (index, batch) in batches.enumerated() {
            do {
                let saveResults = try await privateDatabase.modifyRecords(saving: batch, deleting: [])
                
                var successCount = 0
                for (_, result) in saveResults.saveResults {
                    switch result {
                    case .success:
                        successCount += 1
                    case .failure(let error):
                        logger.error("Failed to save record in batch \(index): \(error.localizedDescription)")
                    }
                }
                
                logger.info("✅ Batch \(index + 1)/\(batches.count): \(successCount)/\(batch.count) records saved")
                
            } catch {
                logger.error("❌ Failed to save batch \(index): \(error.localizedDescription)")
                throw CloudKitError.syncFailed(error)
            }
        }
        
        await updateLastSyncDate()
        logger.info("✅ All batches completed successfully")
    }
    
    /// Delete records by IDs
    func deleteRecords(withIDs recordIDs: [CKRecord.ID]) async throws {
        guard isAvailable && networkReachable else {
            throw CloudKitError.networkUnavailable
        }
        
        logger.info("🗑️ Deleting \(recordIDs.count) CloudKit records")
        
        do {
            let deleteResults = try await privateDatabase.modifyRecords(saving: [], deleting: recordIDs)
            
            var successCount = 0
            for (_, result) in deleteResults.deleteResults {
                switch result {
                case .success:
                    successCount += 1
                case .failure(let error):
                    logger.error("Failed to delete record: \(error.localizedDescription)")
                }
            }
            
            logger.info("✅ Deleted \(successCount)/\(recordIDs.count) records")
            
        } catch {
            logger.error("❌ Failed to delete records: \(error.localizedDescription)")
            throw CloudKitError.syncFailed(error)
        }
    }
    
    /// Validate CloudKit schema and setup
    func validateAndSetupSchema() async throws {
        logger.info("🔍 Validating and setting up CloudKit schema")
        
        do {
            try await recordManager.validateCloudKitSchema()
            logger.info("✅ CloudKit schema validation successful")
        } catch {
            logger.error("❌ CloudKit schema validation failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    deinit {
        Task { @MainActor in await reachabilityMonitor.stopMonitoring() }
        NotificationCenter.default.removeObserver(self)
        logger.info("🏁 SepticaCloudKitManager deinitialized")
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

// MARK: - Array Extension for Batching

fileprivate extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
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
            let record = try recordManager.createPlayerProfileRecord(profile)
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
