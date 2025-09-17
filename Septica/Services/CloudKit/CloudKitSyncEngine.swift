//
//  CloudKitSyncEngine.swift
//  Septica
//
//  Real-time CloudKit synchronization engine for Romanian Septica
//  Implements Sprint 2 Week 6: Core Synchronization with conflict resolution
//

import Foundation
import CloudKit
import Combine
import os.log

/// Advanced CloudKit synchronization engine with Romanian cultural data preservation
@MainActor
class CloudKitSyncEngine: ObservableObject {
    
    // MARK: - Dependencies
    
    private let cloudKitManager: SepticaCloudKitManager
    private let logger = Logger(subsystem: "dev.leanvibe.game.Septica", category: "CloudKitSyncEngine")
    
    // MARK: - Published State
    
    @Published var syncStatus: CloudKitSyncState = .idle
    @Published var syncProgress: Double = 0.0
    @Published var lastSyncDate: Date?
    @Published var conflictsRequiringAttention: [CloudKitConflict] = []
    @Published var pendingUploads: Int = 0
    @Published var pendingDownloads: Int = 0
    @Published var networkReachable: Bool = true
    @Published var culturalDataIntegrity: Float = 1.0
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private let syncQueue = DispatchQueue(label: "CloudKitSyncEngine", qos: .utility)
    private let offlineQueue = OfflineSyncQueue()
    private var syncTimer: Timer?
    private let maxRetries = 3
    private let syncInterval: TimeInterval = 300 // 5 minutes
    
    // MARK: - Romanian Cultural Sync Metrics
    
    @Published var culturalProgressSyncStatus: CulturalSyncStatus = .synchronized
    @Published var heritageDataLastSynced: Date?
    @Published var culturalAchievementsSync: SyncState = .synced
    @Published var folkMusicCollectionSync: SyncState = .synced
    @Published var traditionalColorsSync: SyncState = .synced
    
    enum CulturalSyncStatus {
        case synchronized
        case culturalConflict
        case heritageDataMissing
        case folkContentOutdated
        case achievementDuplicate
        
        var priority: Int {
            switch self {
            case .synchronized: return 0
            case .folkContentOutdated: return 1
            case .culturalConflict: return 2
            case .achievementDuplicate: return 3
            case .heritageDataMissing: return 4
            }
        }
    }
    
    enum SyncState {
        case synced
        case pending
        case syncing
        case conflict
        case error
    }
    
    // MARK: - Initialization
    
    init(cloudKitManager: SepticaCloudKitManager) {
        self.cloudKitManager = cloudKitManager
        setupSyncMonitoring()
        startPeriodicSync()
    }
    
    // MARK: - Core Synchronization Methods
    
    /// Comprehensive sync of all Romanian cultural data
    func syncAllData() async throws {
        guard cloudKitManager.isAvailable else {
            throw CloudKitSyncError.cloudKitNotAvailable
        }
        
        syncStatus = .syncing
        syncProgress = 0.0
        
        do {
            // Phase 1: Player Profile (25% progress)
            try await syncPlayerProfile()
            syncProgress = 0.25
            
            // Phase 2: Game History (50% progress)  
            try await syncGameHistory()
            syncProgress = 0.50
            
            // Phase 3: Cultural Progress (75% progress)
            try await syncCulturalProgress()
            syncProgress = 0.75
            
            // Phase 4: Achievements & Heritage (100% progress)
            try await syncAchievements()
            syncProgress = 1.0
            
            syncStatus = .idle
            lastSyncDate = Date()
            culturalDataIntegrity = 1.0
            
            logger.info("Complete Romanian heritage sync successful")
            
        } catch {
            syncStatus = .error
            logger.error("Sync failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Pause all sync operations for memory optimization or performance reasons
    func pauseSyncOperations() {
        logger.info("⏸️ Pausing CloudKit sync operations for performance optimization")
        
        // Cancel any ongoing sync operations
        syncStatus = .idle
        syncProgress = 0.0
        
        // Clear pending operations to reduce memory usage
        pendingUploads = 0
        pendingDownloads = 0
        
        // Pause periodic sync timer
        syncTimer?.invalidate()
        syncTimer = nil
        
        // Queue any pending operations for later
        offlineQueue.pauseOperations()
        
        // Update cultural sync status
        if culturalProgressSyncStatus == .culturalConflict {
            culturalProgressSyncStatus = .synchronized
        }
        
        logger.info("✅ CloudKit sync operations paused successfully")
    }
    
    /// Resume sync operations after pause
    func resumeSyncOperations() {
        logger.info("▶️ Resuming CloudKit sync operations")
        
        // Restart periodic sync
        startPeriodicSync()
        
        // Resume offline queue processing
        offlineQueue.resumeOperations()
        
        // Trigger a gentle sync if needed
        Task {
            try? await syncAllData()
        }
    }
    
    /// Sync player profile with conflict resolution
    private func syncPlayerProfile() async throws {
        syncStatus = .downloading
        
        // Download latest from CloudKit
        let cloudProfile = try await downloadPlayerProfile()
        let localProfile = loadLocalPlayerProfile()
        
        if let cloud = cloudProfile, let local = localProfile {
            // Check for conflicts
            let conflicts = detectProfileConflicts(cloud: cloud, local: local)
            if !conflicts.isEmpty {
                let resolvedProfile = try await resolveProfileConflicts(conflicts: conflicts, cloud: cloud, local: local)
                try await uploadPlayerProfile(resolvedProfile)
                saveLocalPlayerProfile(resolvedProfile) // Save resolved version locally
            } else {
                // No conflicts - use cloud version as source of truth
                saveLocalPlayerProfile(cloud)
            }
        } else if let cloudProfile = cloudProfile {
            // Only cloud version exists - save locally
            saveLocalPlayerProfile(cloudProfile)
        } else if let localProfile = localProfile {
            // Only local version exists - upload to cloud
            try await uploadPlayerProfile(localProfile)
        }
    }
    
    /// Sync game history with Romanian cultural moments preservation
    private func syncGameHistory(limit: Int = 100) async throws {
        syncStatus = .syncing
        
        // Download recent game records
        let cloudRecords = try await downloadGameRecords(limit: limit)
        let localRecords = loadLocalGameRecords()
        
        // Merge records preserving cultural moments
        let mergedRecords = mergeGameRecords(cloud: cloudRecords, local: localRecords)
        
        // Save merged records locally first (offline-first approach)
        saveLocalGameRecords(mergedRecords)
        
        // Upload merged records to CloudKit
        for record in mergedRecords {
            try await uploadGameRecord(record)
        }
    }
    
    /// Sync Romanian cultural progress with heritage preservation priority
    private func syncCulturalProgress() async throws {
        culturalProgressSyncStatus = .culturalConflict
        
        let cloudCultural = try await downloadCulturalProgress()
        let localCultural = loadLocalCulturalProgress()
        
        if let cloud = cloudCultural, let local = localCultural {
            let resolvedCultural = resolveCulturalConflicts(cloud: cloud, local: local)
            saveLocalCulturalProgress(resolvedCultural) // Save locally first
            try await uploadCulturalProgress(resolvedCultural)
        } else if let cloudCultural = cloudCultural {
            // Only cloud version exists - save locally
            saveLocalCulturalProgress(cloudCultural)
        } else if let localCultural = localCultural {
            // Only local version exists - upload to cloud
            try await uploadCulturalProgress(localCultural)
        }
        
        culturalProgressSyncStatus = .synchronized
        heritageDataLastSynced = Date()
    }
    
    /// Sync achievements with duplicate detection
    private func syncAchievements() async throws {
        culturalAchievementsSync = .syncing
        
        let cloudAchievements = try await downloadAchievements()
        let localAchievements = loadLocalAchievements()
        
        // Merge achievements avoiding duplicates
        let mergedAchievements = mergeAchievements(cloud: cloudAchievements, local: localAchievements)
        
        // Save merged achievements locally first (offline-first approach)
        saveLocalAchievements(mergedAchievements)
        
        try await uploadAchievements(mergedAchievements)
        culturalAchievementsSync = .synced
    }
}

// MARK: - Conflict Resolution System

extension CloudKitSyncEngine {
    
    /// Detect conflicts between cloud and local player profiles
    private func detectProfileConflicts(cloud: CloudKitPlayerProfile, local: CloudKitPlayerProfile) -> [CloudKitConflict] {
        var conflicts: [CloudKitConflict] = []
        
        // Check cultural progress conflicts (high priority)
        if cloud.heritageEngagementLevel != local.heritageEngagementLevel {
            let culturalImpact: CloudKitConflict.CulturalImpact = abs(cloud.heritageEngagementLevel - local.heritageEngagementLevel) > 0.1 ? .significant : .minor
            
            conflicts.append(CloudKitConflict(
                recordType: "PlayerProfile",
                recordID: CKRecord.ID(recordName: cloud.playerID),
                serverRecord: nil, // Would contain actual CKRecord
                clientRecord: CKRecord(recordType: "PlayerProfile"), // Would contain local CKRecord
                conflictType: .culturalProgressMismatch,
                culturalImpact: culturalImpact
            ))
        }
        
        // Check achievement conflicts
        let cloudAchievementSet = Set(cloud.achievements.map { $0.rawValue })
        let localAchievementSet = Set(local.achievements.map { $0.rawValue })
        
        if cloudAchievementSet != localAchievementSet {
            conflicts.append(CloudKitConflict(
                recordType: "PlayerProfile",
                recordID: CKRecord.ID(recordName: cloud.playerID),
                serverRecord: nil,
                clientRecord: CKRecord(recordType: "PlayerProfile"),
                conflictType: .achievementDuplicate,
                culturalImpact: .moderate
            ))
        }
        
        // Check basic data conflicts
        if cloud.totalGamesPlayed != local.totalGamesPlayed || cloud.totalWins != local.totalWins {
            conflicts.append(CloudKitConflict(
                recordType: "PlayerProfile",
                recordID: CKRecord.ID(recordName: cloud.playerID),
                serverRecord: nil,
                clientRecord: CKRecord(recordType: "PlayerProfile"),
                conflictType: .dataModified,
                culturalImpact: .minor
            ))
        }
        
        return conflicts
    }
    
    /// Resolve profile conflicts using Romanian cultural priority system
    private func resolveProfileConflicts(conflicts: [CloudKitConflict], cloud: CloudKitPlayerProfile, local: CloudKitPlayerProfile) async throws -> CloudKitPlayerProfile {
        var resolved = cloud // Start with server version
        
        for conflict in conflicts {
            switch conflict.conflictType {
            case .culturalProgressMismatch:
                // Always preserve higher cultural engagement (heritage preservation priority)
                resolved.heritageEngagementLevel = max(cloud.heritageEngagementLevel, local.heritageEngagementLevel)
                resolved.culturalStoriesRead = Array(Set(cloud.culturalStoriesRead + local.culturalStoriesRead))
                resolved.folkMusicListened = Array(Set(cloud.folkMusicListened + local.folkMusicListened))
                
            case .achievementDuplicate:
                // Merge achievements preserving all unlocked
                let mergedAchievements = Array(Set(cloud.achievements + local.achievements))
                resolved.achievements = mergedAchievements
                
            case .dataModified:
                // Use additive strategy for statistics
                resolved.totalGamesPlayed = max(cloud.totalGamesPlayed, local.totalGamesPlayed)
                resolved.totalWins = max(cloud.totalWins, local.totalWins)
                resolved.longestStreak = max(cloud.longestStreak, local.longestStreak)
                
                // Use most recent date
                resolved.lastPlayedDate = max(cloud.lastPlayedDate, local.lastPlayedDate)
                
            case .recordDeleted:
                // Restore from local if deleted on server (conservative approach)
                resolved = local
            }
        }
        
        return resolved
    }
    
    /// Resolve cultural progress conflicts with heritage preservation priority
    private func resolveCulturalConflicts(cloud: CulturalEducationProgress, local: CulturalEducationProgress) -> CulturalEducationProgress {
        var resolved = cloud
        
        // Always preserve maximum cultural knowledge (heritage preservation)
        resolved.folkTalesRead = max(cloud.folkTalesRead, local.folkTalesRead)
        resolved.traditionalMusicKnowledge = max(cloud.traditionalMusicKnowledge, local.traditionalMusicKnowledge)
        resolved.cardHistoryKnowledge = max(cloud.cardHistoryKnowledge, local.cardHistoryKnowledge)
        
        // Merge learned content
        resolved.gameRulesLearned = Array(Set(cloud.gameRulesLearned + local.gameRulesLearned))
        resolved.culturalBadges = Array(Set(cloud.culturalBadges + local.culturalBadges))
        
        // Merge quiz scores taking best scores
        resolved.quizScores = cloud.quizScores.merging(local.quizScores) { cloudScore, localScore in
            max(cloudScore, localScore)
        }
        
        return resolved
    }
    
    /// Merge achievements avoiding duplicates
    private func mergeAchievements(cloud: [CulturalAchievement], local: [CulturalAchievement]) -> [CulturalAchievement] {
        let cloudSet = Set(cloud.map { $0.rawValue })
        let localSet = Set(local.map { $0.rawValue })
        let mergedSet = cloudSet.union(localSet)
        
        return mergedSet.compactMap { CulturalAchievement(rawValue: $0) }
    }
    
    /// Merge game records preserving cultural moments
    private func mergeGameRecords(cloud: [CloudKitGameRecord], local: [CloudKitGameRecord]) -> [CloudKitGameRecord] {
        let cloudIDs = Set(cloud.map { $0.gameID })
        let localIDs = Set(local.map { $0.gameID })
        
        var merged: [CloudKitGameRecord] = []
        
        // Add all cloud records
        merged.append(contentsOf: cloud)
        
        // Add local records not in cloud
        for record in local {
            if !cloudIDs.contains(record.gameID) {
                merged.append(record)
            }
        }
        
        return merged.sorted { $0.timestamp > $1.timestamp }
    }
}

// MARK: - Data Access Methods (Placeholder implementations)

extension CloudKitSyncEngine {
    
    private func downloadPlayerProfile() async throws -> CloudKitPlayerProfile? {
        // Implementation would fetch from CloudKit
        return nil
    }
    
    private func loadLocalPlayerProfile() -> CloudKitPlayerProfile? {
        guard let data = UserDefaults.standard.data(forKey: "septica_local_player_profile") else {
            logger.info("📱 No local player profile found")
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let profile = try decoder.decode(CloudKitPlayerProfile.self, from: data)
            logger.info("📱 Loaded local player profile: \(profile.displayName)")
            return profile
        } catch {
            logger.error("❌ Failed to decode local player profile: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func saveLocalPlayerProfile(_ profile: CloudKitPlayerProfile) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(profile)
            UserDefaults.standard.set(data, forKey: "septica_local_player_profile")
            logger.info("💾 Saved local player profile: \(profile.displayName)")
        } catch {
            logger.error("❌ Failed to save local player profile: \(error.localizedDescription)")
        }
    }
    
    private func uploadPlayerProfile(_ profile: CloudKitPlayerProfile) async throws {
        // Implementation would save to CloudKit
    }
    
    private func downloadGameRecords(limit: Int) async throws -> [CloudKitGameRecord] {
        // Implementation would fetch from CloudKit
        return []
    }
    
    private func loadLocalGameRecords() -> [CloudKitGameRecord] {
        guard let data = UserDefaults.standard.data(forKey: "septica_local_game_records") else {
            logger.info("📱 No local game records found")
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            let records = try decoder.decode([CloudKitGameRecord].self, from: data)
            logger.info("📱 Loaded \(records.count) local game records")
            return records
        } catch {
            logger.error("❌ Failed to decode local game records: \(error.localizedDescription)")
            return []
        }
    }
    
    private func saveLocalGameRecords(_ records: [CloudKitGameRecord]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(records)
            UserDefaults.standard.set(data, forKey: "septica_local_game_records")
            logger.info("💾 Saved \(records.count) local game records")
        } catch {
            logger.error("❌ Failed to save local game records: \(error.localizedDescription)")
        }
    }
    
    private func uploadGameRecord(_ record: CloudKitGameRecord) async throws {
        // Implementation would save to CloudKit
    }
    
    private func downloadCulturalProgress() async throws -> CulturalEducationProgress? {
        // Implementation would fetch from CloudKit
        return nil
    }
    
    private func loadLocalCulturalProgress() -> CulturalEducationProgress? {
        guard let data = UserDefaults.standard.data(forKey: "septica_local_cultural_progress") else {
            logger.info("📱 No local cultural progress found")
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let progress = try decoder.decode(CulturalEducationProgress.self, from: data)
            logger.info("📱 Loaded local cultural progress: \(progress.folkTalesRead) tales read, \(progress.culturalBadges.count) badges")
            return progress
        } catch {
            logger.error("❌ Failed to decode local cultural progress: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func saveLocalCulturalProgress(_ progress: CulturalEducationProgress) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(progress)
            UserDefaults.standard.set(data, forKey: "septica_local_cultural_progress")
            logger.info("💾 Saved local cultural progress: \(progress.folkTalesRead) tales read, \(progress.culturalBadges.count) badges")
        } catch {
            logger.error("❌ Failed to save local cultural progress: \(error.localizedDescription)")
        }
    }
    
    private func uploadCulturalProgress(_ progress: CulturalEducationProgress) async throws {
        // Implementation would save to CloudKit
    }
    
    private func downloadAchievements() async throws -> [CulturalAchievement] {
        // Implementation would fetch from CloudKit
        return []
    }
    
    private func loadLocalAchievements() -> [CulturalAchievement] {
        guard let data = UserDefaults.standard.data(forKey: "septica_local_achievements") else {
            logger.info("📱 No local achievements found")
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            let achievements = try decoder.decode([CulturalAchievement].self, from: data)
            logger.info("📱 Loaded \(achievements.count) local achievements")
            return achievements
        } catch {
            logger.error("❌ Failed to decode local achievements: \(error.localizedDescription)")
            return []
        }
    }
    
    private func saveLocalAchievements(_ achievements: [CulturalAchievement]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(achievements)
            UserDefaults.standard.set(data, forKey: "septica_local_achievements")
            logger.info("💾 Saved \(achievements.count) local achievements")
        } catch {
            logger.error("❌ Failed to save local achievements: \(error.localizedDescription)")
        }
    }
    
    private func uploadAchievements(_ achievements: [CulturalAchievement]) async throws {
        // Implementation would save to CloudKit
    }
}

// MARK: - Periodic Sync & Monitoring

extension CloudKitSyncEngine {
    
    private func setupSyncMonitoring() {
        // Monitor network reachability
        // Implementation would use Network framework
        
        // Setup CloudKit subscription notifications
        // Implementation would handle remote notifications
    }
    
    private func startPeriodicSync() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.performBackgroundSync()
            }
        }
    }
    
    private func performBackgroundSync() async {
        guard networkReachable && cloudKitManager.isAvailable else { return }
        
        do {
            try await syncAllData()
        } catch {
            logger.error("Background sync failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - Offline Sync Queue

// OfflineSyncQueue and CloudKitUpdate are defined in dedicated files

enum CloudKitSyncError: LocalizedError {
    case cloudKitNotAvailable
    case conflictResolutionFailed
    case culturalDataCorrupted
    case networkUnavailable
    
    var errorDescription: String? {
        switch self {
        case .cloudKitNotAvailable:
            return "CloudKit is not available"
        case .conflictResolutionFailed:
            return "Failed to resolve sync conflicts"
        case .culturalDataCorrupted:
            return "Romanian cultural data integrity compromised"
        case .networkUnavailable:
            return "Network connection unavailable"
        }
    }
}
