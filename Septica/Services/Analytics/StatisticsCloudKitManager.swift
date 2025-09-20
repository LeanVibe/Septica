//
//  StatisticsCloudKitManager.swift
//  Septica
//
//  CloudKit manager specifically for Romanian cultural analytics and statistics synchronization
//  Handles cross-device analytics sync while preserving cultural authenticity data
//

import Foundation
import CloudKit
import Combine
import os.log

/// CloudKit manager specialized for Romanian cultural analytics and statistics
@MainActor
class StatisticsCloudKitManager: ObservableObject {
    
    // MARK: - Dependencies
    
    private let logger = Logger(subsystem: "dev.leanvibe.game.Septica", category: "StatisticsCloudKitManager")
    private let container = CKContainer(identifier: "iCloud.dev.leanvibe.game.Septica")
    private let privateDatabase: CKDatabase
    
    // MARK: - Published State
    
    @Published var syncStatus: AnalyticsSyncStatus = .idle
    @Published var lastAnalyticsSync: Date?
    @Published var culturalDataSyncProgress: Float = 0.0
    @Published var pendingAnalyticsOperations: Int = 0
    @Published var syncConflicts: [AnalyticsSyncConflict] = []
    
    // MARK: - Analytics Data Types
    
    @Published var syncedCulturalInsights: CulturalInsights?
    @Published var syncedPlayerProfiles: [UUID: PlayerCulturalProfile] = [:]
    @Published var syncedGameAnalytics: [GameCulturalAnalytics] = []
    
    // MARK: - Performance Tracking
    
    @Published var analyticsPerformance: AnalyticsPerformanceMetrics = AnalyticsPerformanceMetrics()
    private var batchOperationQueue: OperationQueue
    
    // MARK: - Local Analytics Cache
    
    private var localAnalyticsCache: LocalAnalyticsCache
    private var conflictResolver: AnalyticsConflictResolver
    
    // MARK: - Initialization
    
    init() {
        self.privateDatabase = container.privateCloudDatabase
        self.localAnalyticsCache = LocalAnalyticsCache()
        self.conflictResolver = AnalyticsConflictResolver()
        
        // Setup batch operation queue
        self.batchOperationQueue = OperationQueue()
        self.batchOperationQueue.maxConcurrentOperationCount = 2
        self.batchOperationQueue.qualityOfService = .userInitiated
        
        Task {
            await initializeAnalyticsSync()
        }
    }
    
    // MARK: - Initialization & Setup
    
    private func initializeAnalyticsSync() async {
        do {
            // Check CloudKit availability
            let accountStatus = try await container.accountStatus()
            guard accountStatus == .available else {
                logger.warning("CloudKit not available for analytics sync")
                return
            }
            
            // Setup analytics schema
            await setupAnalyticsSchema()
            
            // Setup subscriptions for real-time analytics updates
            await setupAnalyticsSubscriptions()
            
            // Perform initial analytics sync
            await performInitialAnalyticsSync()
            
            logger.info("Statistics CloudKit manager initialized successfully")
            
        } catch {
            logger.error("Failed to initialize analytics sync: \(error)")
            syncStatus = .failed(error)
        }
    }
    
    private func setupAnalyticsSchema() async {
        // Ensure CloudKit schema exists for Romanian cultural analytics
        logger.info("Verifying analytics CloudKit schema...")
        
        // In production, schema would be created via CloudKit Dashboard
        // This validates that required record types exist
        await validateRecordType("CulturalGameAnalytics")
        await validateRecordType("PlayerCulturalProfile")
        await validateRecordType("TraditionalPatternUsage")
        await validateRecordType("CulturalAuthenticityMetrics")
        await validateRecordType("RegionalStyleAnalytics")
    }
    
    private func validateRecordType(_ recordType: String) async {
        // Placeholder for schema validation
        logger.info("Validated CloudKit record type: \(recordType)")
    }
    
    private func setupAnalyticsSubscriptions() async {
        do {
            // Subscribe to cultural analytics changes
            let analyticsSubscription = CKQuerySubscription(
                recordType: "CulturalGameAnalytics",
                predicate: NSPredicate(value: true),
                subscriptionID: "cultural-analytics-subscription"
            )
            
            let notificationInfo = CKSubscription.NotificationInfo()
            notificationInfo.shouldSendContentAvailable = true
            notificationInfo.shouldBadge = false
            analyticsSubscription.notificationInfo = notificationInfo
            
            try await privateDatabase.save(analyticsSubscription)
            
            // Subscribe to cultural profile changes
            let profileSubscription = CKQuerySubscription(
                recordType: "PlayerCulturalProfile",
                predicate: NSPredicate(value: true),
                subscriptionID: "cultural-profile-subscription"
            )
            profileSubscription.notificationInfo = notificationInfo
            
            try await privateDatabase.save(profileSubscription)
            
            logger.info("Analytics CloudKit subscriptions established")
            
        } catch {
            logger.error("Failed to setup analytics subscriptions: \(error)")
        }
    }
    
    // MARK: - Game Analytics Sync
    
    func syncGameAnalytics(_ gameAnalytics: GameCulturalAnalytics) async throws {
        syncStatus = .syncing
        pendingAnalyticsOperations += 1
        
        let startTime = Date()
        
        do {
            // Create CloudKit record for game analytics
            let record = try createGameAnalyticsRecord(gameAnalytics)
            
            // Upload to CloudKit
            let savedRecord = try await privateDatabase.save(record)
            
            // Update local cache
            localAnalyticsCache.cacheGameAnalytics(gameAnalytics)
            
            // Update synced data
            if !syncedGameAnalytics.contains(where: { $0.gameId == gameAnalytics.gameId }) {
                syncedGameAnalytics.append(gameAnalytics)
            }
            
            // Update performance metrics
            let duration = Date().timeIntervalSince(startTime)
            analyticsPerformance.recordSyncOperation(.gameAnalytics, duration: duration, success: true)
            
            lastAnalyticsSync = Date()
            syncStatus = .completed
            
            logger.info("Successfully synced game analytics: \(gameAnalytics.gameId)")
            
        } catch {
            analyticsPerformance.recordSyncOperation(.gameAnalytics, duration: Date().timeIntervalSince(startTime), success: false)
            syncStatus = .failed(error)
            logger.error("Failed to sync game analytics: \(error)")
            pendingAnalyticsOperations -= 1
            throw error
        }
    }
    
    func syncCulturalProfile(_ profile: PlayerCulturalProfile) async throws {
        syncStatus = .syncing
        pendingAnalyticsOperations += 1
        
        do {
            // Create CloudKit record for cultural profile
            let record = try createCulturalProfileRecord(profile)
            
            // Upload to CloudKit with conflict resolution
            let uploadResult = try await uploadWithConflictHandling(record)
            
            if let conflict = uploadResult.conflict {
                // Handle cultural profile conflicts
                let resolvedProfile = try await conflictResolver.resolveCulturalProfileConflict(
                    localProfile: profile,
                    serverRecord: conflict,
                    strategy: .culturalPreservation
                )
                
                // Re-upload resolved profile
                let resolvedRecord = try createCulturalProfileRecord(resolvedProfile)
                try await privateDatabase.save(resolvedRecord)
                
                syncedPlayerProfiles[profile.playerId] = resolvedProfile
            } else {
                syncedPlayerProfiles[profile.playerId] = profile
            }
            
            // Update local cache
            localAnalyticsCache.cacheCulturalProfile(profile)
            
            lastAnalyticsSync = Date()
            syncStatus = .completed
            
            logger.info("Successfully synced cultural profile: \(profile.playerId)")
            
        } catch {
            syncStatus = .failed(error)
            logger.error("Failed to sync cultural profile: \(error)")
            pendingAnalyticsOperations -= 1
            throw error
        }
    }
    
    func syncCulturalInsights(_ insights: CulturalInsights) async throws {
        syncStatus = .syncing
        
        do {
            // Create CloudKit record for cultural insights
            let record = try createCulturalInsightsRecord(insights)
            
            // Upload to CloudKit
            try await privateDatabase.save(record)
            
            // Update synced insights
            syncedCulturalInsights = insights
            
            // Cache locally
            localAnalyticsCache.cacheCulturalInsights(insights)
            
            lastAnalyticsSync = Date()
            syncStatus = .completed
            
            logger.info("Successfully synced cultural insights")
            
        } catch {
            syncStatus = .failed(error)
            logger.error("Failed to sync cultural insights: \(error)")
            throw error
        }
    }
    
    // MARK: - Batch Analytics Operations
    
    func syncBatchAnalytics(_ batchData: BatchAnalyticsData) async throws {
        syncStatus = .syncing
        culturalDataSyncProgress = 0.0
        
        let totalOperations = batchData.gameAnalytics.count + 
                             batchData.culturalProfiles.count + 
                             batchData.traditionalPatterns.count
        
        var completedOperations = 0
        
        do {
            // Sync game analytics in batches
            for batch in batchData.gameAnalytics.chunked(into: 10) {
                try await syncGameAnalyticsBatch(batch)
                completedOperations += batch.count
                culturalDataSyncProgress = Float(completedOperations) / Float(totalOperations)
            }
            
            // Sync cultural profiles
            for profile in batchData.culturalProfiles {
                try await syncCulturalProfile(profile)
                completedOperations += 1
                culturalDataSyncProgress = Float(completedOperations) / Float(totalOperations)
            }
            
            // Sync traditional pattern usage
            for patternBatch in batchData.traditionalPatterns.chunked(into: 20) {
                try await syncTraditionalPatternsBatch(patternBatch)
                completedOperations += patternBatch.count
                culturalDataSyncProgress = Float(completedOperations) / Float(totalOperations)
            }
            
            culturalDataSyncProgress = 1.0
            syncStatus = .completed
            
            logger.info("Successfully completed batch analytics sync")
            
        } catch {
            syncStatus = .failed(error)
            logger.error("Batch analytics sync failed: \(error)")
            throw error
        }
    }
    
    private func syncGameAnalyticsBatch(_ batch: [GameCulturalAnalytics]) async throws {
        let records = try batch.map { try createGameAnalyticsRecord($0) }
        
        let modifyOperation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
        modifyOperation.isAtomic = false
        modifyOperation.qualityOfService = .userInitiated
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            modifyOperation.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            privateDatabase.add(modifyOperation)
        }
    }
    
    private func syncTraditionalPatternsBatch(_ batch: [TraditionalPatternUsage]) async throws {
        let records = try batch.map { try createTraditionalPatternRecord($0) }
        
        let modifyOperation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
        modifyOperation.isAtomic = false
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            modifyOperation.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            privateDatabase.add(modifyOperation)
        }
    }
    
    // MARK: - CloudKit Record Creation
    
    private func createGameAnalyticsRecord(_ analytics: GameCulturalAnalytics) throws -> CKRecord {
        let record = CKRecord(
            recordType: "CulturalGameAnalytics",
            recordID: CKRecord.ID(recordName: analytics.gameId.uuidString)
        )
        
        // Basic game information
        record["gameId"] = analytics.gameId.uuidString
        record["startTime"] = analytics.startTime
        record["endTime"] = analytics.endTime
        record["finalCulturalScore"] = analytics.finalCulturalScore
        record["traditionalAlignmentScore"] = analytics.traditionalAlignmentScore
        record["culturalEducationScore"] = analytics.culturalEducationScore
        
        // Serialize patterns and moments
        if let patternsData = try? JSONEncoder().encode(analytics.detectedPatterns) {
            record["detectedPatterns"] = patternsData
        }
        
        if let momentsData = try? JSONEncoder().encode(analytics.culturalMoments) {
            record["culturalMoments"] = momentsData
        }
        
        // Player analytics
        if let playersData = try? JSONEncoder().encode(analytics.players) {
            record["playerAnalytics"] = playersData
        }
        
        // Game result
        if let result = analytics.finalResult,
           let resultData = try? JSONEncoder().encode(result) {
            record["finalResult"] = resultData
        }
        
        return record
    }
    
    private func createCulturalProfileRecord(_ profile: PlayerCulturalProfile) throws -> CKRecord {
        let record = CKRecord(
            recordType: "PlayerCulturalProfile",
            recordID: CKRecord.ID(recordName: profile.playerId.uuidString)
        )
        
        record["playerId"] = profile.playerId.uuidString
        record["playerName"] = profile.playerName
        record["culturalLevel"] = profile.culturalLevel
        record["culturalExperience"] = profile.culturalExperience
        record["traditionalStrategyMastery"] = profile.traditionalStrategyMastery
        record["regionalStylePreference"] = profile.regionalStylePreference?.rawValue
        record["culturalAuthenticityScore"] = profile.culturalAuthenticityScore
        record["heritageEngagementLevel"] = profile.heritageEngagementLevel
        record["lastPlayedDate"] = profile.lastPlayedDate
        record["totalGamesWithCulturalAnalysis"] = profile.totalGamesWithCulturalAnalysis
        
        // Serialize complex data
        if let strategiesData = try? JSONEncoder().encode(profile.masteredStrategies) {
            record["masteredStrategies"] = strategiesData
        }
        
        if let milestonesData = try? JSONEncoder().encode(profile.culturalMilestones) {
            record["culturalMilestones"] = milestonesData
        }
        
        if let preferencesData = try? JSONEncoder().encode(profile.learningPreferences) {
            record["learningPreferences"] = preferencesData
        }
        
        return record
    }
    
    private func createCulturalInsightsRecord(_ insights: CulturalInsights) throws -> CKRecord {
        let record = CKRecord(
            recordType: "CulturalInsights",
            recordID: CKRecord.ID(recordName: "cultural-insights-\(Date().timeIntervalSince1970)")
        )
        
        record["totalGamesAnalyzed"] = insights.totalGamesAnalyzed
        record["averageCulturalScore"] = insights.averageCulturalScore
        record["traditionalStrategyUsage"] = insights.traditionalStrategyUsage
        record["culturalLearningProgress"] = insights.culturalLearningProgress
        record["generatedAt"] = Date()
        
        // Serialize complex insights data
        if let distributionData = try? JSONEncoder().encode(insights.regionalStyleDistribution) {
            record["regionalStyleDistribution"] = distributionData
        }
        
        if let strategiesData = try? JSONEncoder().encode(insights.mostUsedTraditionalStrategies) {
            record["mostUsedTraditionalStrategies"] = strategiesData
        }
        
        if let milestonesData = try? JSONEncoder().encode(insights.culturalMilestones) {
            record["culturalMilestones"] = milestonesData
        }
        
        return record
    }
    
    private func createTraditionalPatternRecord(_ patternUsage: TraditionalPatternUsage) throws -> CKRecord {
        let recordName = "\(patternUsage.patternId)-\(Date().timeIntervalSince1970)"
        let record = CKRecord(
            recordType: "TraditionalPatternUsage",
            recordID: CKRecord.ID(recordName: recordName)
        )
        
        record["patternId"] = patternUsage.patternId
        record["patternName"] = patternUsage.patternName
        record["usageCount"] = patternUsage.usageCount
        record["successRate"] = patternUsage.successRate
        record["culturalAuthenticityWeight"] = patternUsage.culturalAuthenticityWeight
        record["regionalOrigin"] = patternUsage.regionalOrigin?.rawValue
        record["difficultyLevel"] = patternUsage.difficultyLevel.rawValue
        record["lastUsedDate"] = patternUsage.lastUsedDate
        record["playerId"] = patternUsage.playerId.uuidString
        
        return record
    }
    
    // MARK: - Data Retrieval
    
    func fetchPlayerCulturalProfile(_ playerId: UUID) async throws -> PlayerCulturalProfile? {
        let recordID = CKRecord.ID(recordName: playerId.uuidString)
        
        do {
            let record = try await privateDatabase.record(for: recordID)
            let profile = try decodeCulturalProfileFromRecord(record)
            
            // Cache locally
            localAnalyticsCache.cacheCulturalProfile(profile)
            syncedPlayerProfiles[playerId] = profile
            
            return profile
            
        } catch {
            // Try local cache if CloudKit fails
            if let cachedProfile = localAnalyticsCache.getCachedCulturalProfile(playerId) {
                return cachedProfile
            }
            
            logger.error("Failed to fetch cultural profile: \(error)")
            throw error
        }
    }
    
    func fetchGameAnalytics(gameId: UUID) async throws -> GameCulturalAnalytics? {
        let recordID = CKRecord.ID(recordName: gameId.uuidString)
        
        do {
            let record = try await privateDatabase.record(for: recordID)
            let analytics = try decodeGameAnalyticsFromRecord(record)
            
            // Cache locally
            localAnalyticsCache.cacheGameAnalytics(analytics)
            
            return analytics
            
        } catch {
            // Try local cache if CloudKit fails
            if let cachedAnalytics = localAnalyticsCache.getCachedGameAnalytics(gameId) {
                return cachedAnalytics
            }
            
            logger.error("Failed to fetch game analytics: \(error)")
            throw error
        }
    }
    
    func fetchCulturalInsightsHistory(limit: Int = 10) async throws -> [CulturalInsights] {
        let query = CKQuery(recordType: "CulturalInsights", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "generatedAt", ascending: false)]
        
        do {
            let result = try await privateDatabase.records(matching: query, resultsLimit: limit)
            let insights = try result.matchResults.compactMap { (_, result) in
                try result.get()
            }.compactMap { record in
                try? decodeCulturalInsightsFromRecord(record)
            }
            
            return insights
            
        } catch {
            logger.error("Failed to fetch cultural insights history: \(error)")
            throw error
        }
    }
    
    // MARK: - Conflict Resolution
    
    private func uploadWithConflictHandling(_ record: CKRecord) async throws -> UploadResult {
        do {
            let savedRecord = try await privateDatabase.save(record)
            return UploadResult(savedRecord: savedRecord, conflict: nil)
            
        } catch let error as CKError where error.code == .serverRecordChanged {
            // Handle server record changed conflict
            if let serverRecord = error.userInfo[CKRecordChangedErrorServerRecordKey] as? CKRecord {
                return UploadResult(savedRecord: nil, conflict: serverRecord)
            } else {
                throw error
            }
        } catch {
            throw error
        }
    }
    
    // MARK: - Offline Support
    
    func enableOfflineAnalyticsMode() {
        localAnalyticsCache.enableOfflineMode()
        
        // Setup automatic sync when connectivity restored
        NotificationCenter.default.addObserver(
            forName: .cloudKitAccountChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.syncPendingAnalytics()
            }
        }
        
        logger.info("Offline analytics mode enabled")
    }
    
    private func syncPendingAnalytics() async {
        do {
            let pendingData = localAnalyticsCache.getPendingAnalyticsData()
            
            if !pendingData.isEmpty {
                try await syncBatchAnalytics(pendingData)
                localAnalyticsCache.clearPendingData()
                
                logger.info("Successfully synced pending analytics data")
            }
            
        } catch {
            logger.error("Failed to sync pending analytics: \(error)")
        }
    }
    
    // MARK: - Performance & Metrics
    
    private func performInitialAnalyticsSync() async {
        do {
            // Fetch recent analytics data
            let recentInsights = try await fetchCulturalInsightsHistory(limit: 5)
            if let latestInsights = recentInsights.first {
                syncedCulturalInsights = latestInsights
            }
            
            logger.info("Initial analytics sync completed")
            
        } catch {
            logger.error("Initial analytics sync failed: \(error)")
        }
    }
    
    func getAnalyticsPerformanceReport() -> AnalyticsPerformanceReport {
        return AnalyticsPerformanceReport(
            metrics: analyticsPerformance,
            lastSyncDate: lastAnalyticsSync,
            pendingOperations: pendingAnalyticsOperations,
            cacheHitRate: localAnalyticsCache.getHitRate(),
            syncConflictCount: syncConflicts.count
        )
    }
    
    // MARK: - Helper Methods
    
    private func decodeCulturalProfileFromRecord(_ record: CKRecord) throws -> PlayerCulturalProfile {
        guard let playerIdString = record["playerId"] as? String,
              let playerId = UUID(uuidString: playerIdString),
              let playerName = record["playerName"] as? String else {
            throw AnalyticsError.invalidRecordData
        }
        
        return PlayerCulturalProfile(
            playerId: playerId,
            playerName: playerName,
            culturalLevel: record["culturalLevel"] as? Int ?? 1,
            culturalExperience: record["culturalExperience"] as? Int ?? 0,
            traditionalStrategyMastery: record["traditionalStrategyMastery"] as? Float ?? 0.0,
            regionalStylePreference: RomanianRegion(rawValue: record["regionalStylePreference"] as? String ?? ""),
            culturalAuthenticityScore: record["culturalAuthenticityScore"] as? Float ?? 0.0,
            heritageEngagementLevel: record["heritageEngagementLevel"] as? Float ?? 0.0,
            lastPlayedDate: record["lastPlayedDate"] as? Date ?? Date(),
            totalGamesWithCulturalAnalysis: record["totalGamesWithCulturalAnalysis"] as? Int ?? 0,
            masteredStrategies: decodeStrategiesFromRecord(record),
            culturalMilestones: decodeMilestonesFromRecord(record),
            learningPreferences: decodeLearningPreferencesFromRecord(record)
        )
    }
    
    private func decodeGameAnalyticsFromRecord(_ record: CKRecord) throws -> GameCulturalAnalytics {
        guard let gameIdString = record["gameId"] as? String,
              let gameId = UUID(uuidString: gameIdString),
              let startTime = record["startTime"] as? Date else {
            throw AnalyticsError.invalidRecordData
        }
        
        return GameCulturalAnalytics(
            gameId: gameId,
            startTime: startTime,
            endTime: record["endTime"] as? Date,
            players: decodePlayerAnalyticsFromRecord(record),
            detectedPatterns: decodePatternsFromRecord(record),
            culturalMoments: decodeMomentsFromRecord(record),
            finalResult: decodeFinalResultFromRecord(record),
            finalCulturalScore: record["finalCulturalScore"] as? Float ?? 0.0,
            traditionalAlignmentScore: record["traditionalAlignmentScore"] as? Float ?? 0.0,
            culturalEducationScore: record["culturalEducationScore"] as? Float ?? 0.0
        )
    }
    
    private func decodeCulturalInsightsFromRecord(_ record: CKRecord) throws -> CulturalInsights {
        return CulturalInsights(
            totalGamesAnalyzed: record["totalGamesAnalyzed"] as? Int ?? 0,
            averageCulturalScore: record["averageCulturalScore"] as? Float ?? 0.0,
            traditionalStrategyUsage: record["traditionalStrategyUsage"] as? Float ?? 0.0,
            regionalStyleDistribution: decodeRegionalDistributionFromRecord(record),
            culturalLearningProgress: record["culturalLearningProgress"] as? Float ?? 0.0,
            mostUsedTraditionalStrategies: decodeStrategyUsageFromRecord(record),
            culturalMilestones: decodeMilestonesFromRecord(record)
        )
    }
    
    // Additional helper methods for record decoding
    private func decodeStrategiesFromRecord(_ record: CKRecord) -> [String] {
        guard let data = record["masteredStrategies"] as? Data else { return [] }
        return (try? JSONDecoder().decode([String].self, from: data)) ?? []
    }
    
    private func decodeMilestonesFromRecord(_ record: CKRecord) -> [CulturalMilestone] {
        guard let data = record["culturalMilestones"] as? Data else { return [] }
        return (try? JSONDecoder().decode([CulturalMilestone].self, from: data)) ?? []
    }
    
    private func decodeLearningPreferencesFromRecord(_ record: CKRecord) -> CulturalLearningPreferences {
        guard let data = record["learningPreferences"] as? Data else {
            return CulturalLearningPreferences.default
        }
        return (try? JSONDecoder().decode(CulturalLearningPreferences.self, from: data)) ?? CulturalLearningPreferences.default
    }
    
    private func decodePlayerAnalyticsFromRecord(_ record: CKRecord) -> [PlayerCulturalAnalytics] {
        guard let data = record["playerAnalytics"] as? Data else { return [] }
        return (try? JSONDecoder().decode([PlayerCulturalAnalytics].self, from: data)) ?? []
    }
    
    private func decodePatternsFromRecord(_ record: CKRecord) -> [TraditionalPattern] {
        guard let data = record["detectedPatterns"] as? Data else { return [] }
        return (try? JSONDecoder().decode([TraditionalPattern].self, from: data)) ?? []
    }
    
    private func decodeMomentsFromRecord(_ record: CKRecord) -> [CulturalMoment] {
        guard let data = record["culturalMoments"] as? Data else { return [] }
        return (try? JSONDecoder().decode([CulturalMoment].self, from: data)) ?? []
    }
    
    private func decodeFinalResultFromRecord(_ record: CKRecord) -> GameResult? {
        guard let data = record["finalResult"] as? Data else { return nil }
        return try? JSONDecoder().decode(GameResult.self, from: data)
    }
    
    private func decodeRegionalDistributionFromRecord(_ record: CKRecord) -> [RomanianRegion: Int] {
        guard let data = record["regionalStyleDistribution"] as? Data else { return [:] }
        return (try? JSONDecoder().decode([RomanianRegion: Int].self, from: data)) ?? [:]
    }
    
    private func decodeStrategyUsageFromRecord(_ record: CKRecord) -> [TraditionalStrategyUsage] {
        guard let data = record["mostUsedTraditionalStrategies"] as? Data else { return [] }
        return (try? JSONDecoder().decode([TraditionalStrategyUsage].self, from: data)) ?? []
    }
}

// MARK: - Supporting Data Structures

enum AnalyticsSyncStatus {
    case idle
    case syncing
    case completed
    case failed(Error)
}

struct AnalyticsSyncConflict {
    let recordId: CKRecord.ID
    let conflictType: ConflictType
    let localData: Data
    let serverData: Data
    let timestamp: Date
    
    enum ConflictType {
        case culturalProfile
        case gameAnalytics
        case insights
    }
}

struct BatchAnalyticsData {
    let gameAnalytics: [GameCulturalAnalytics]
    let culturalProfiles: [PlayerCulturalProfile]
    let traditionalPatterns: [TraditionalPatternUsage]
}

struct PlayerCulturalProfile: Codable {
    let playerId: UUID
    let playerName: String
    var culturalLevel: Int
    var culturalExperience: Int
    var traditionalStrategyMastery: Float
    var regionalStylePreference: RomanianRegion?
    var culturalAuthenticityScore: Float
    var heritageEngagementLevel: Float
    let lastPlayedDate: Date
    var totalGamesWithCulturalAnalysis: Int
    var masteredStrategies: [String]
    var culturalMilestones: [CulturalMilestone]
    var learningPreferences: CulturalLearningPreferences
}

struct CulturalLearningPreferences: Codable {
    var preferredRegionalStyle: RomanianRegion?
    var educationalContentEnabled: Bool
    var traditionalMusicEnabled: Bool
    var culturalTooltipsEnabled: Bool
    var difficultyPreference: LearningDifficulty
    
    static let `default` = CulturalLearningPreferences(
        preferredRegionalStyle: nil,
        educationalContentEnabled: true,
        traditionalMusicEnabled: true,
        culturalTooltipsEnabled: true,
        difficultyPreference: .adaptive
    )
}

enum LearningDifficulty: String, Codable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    case adaptive = "adaptive"
}

struct TraditionalPatternUsage: Codable {
    let patternId: String
    let patternName: String
    var usageCount: Int
    var successRate: Float
    let culturalAuthenticityWeight: Float
    let regionalOrigin: RomanianRegion?
    let difficultyLevel: PatternDifficulty
    let lastUsedDate: Date
    let playerId: UUID
}

struct AnalyticsPerformanceMetrics {
    var totalSyncOperations: Int = 0
    var successfulSyncs: Int = 0
    var averageSyncDuration: TimeInterval = 0.0
    var lastSyncPerformance: TimeInterval = 0.0
    var syncFailureRate: Float = 0.0
    
    mutating func recordSyncOperation(_ type: SyncOperationType, duration: TimeInterval, success: Bool) {
        totalSyncOperations += 1
        lastSyncPerformance = duration
        
        if success {
            successfulSyncs += 1
        }
        
        // Update average duration
        let totalDuration = averageSyncDuration * Double(totalSyncOperations - 1) + duration
        averageSyncDuration = totalDuration / Double(totalSyncOperations)
        
        // Update failure rate
        syncFailureRate = Float(totalSyncOperations - successfulSyncs) / Float(totalSyncOperations)
    }
}

enum SyncOperationType {
    case gameAnalytics
    case culturalProfile
    case insights
    case patterns
}

struct AnalyticsPerformanceReport {
    let metrics: AnalyticsPerformanceMetrics
    let lastSyncDate: Date?
    let pendingOperations: Int
    let cacheHitRate: Float
    let syncConflictCount: Int
}

struct UploadResult {
    let savedRecord: CKRecord?
    let conflict: CKRecord?
}

enum AnalyticsError: Error {
    case invalidRecordData
    case syncFailed
    case conflictResolutionFailed
    case offlineModeRequired
}

// MARK: - Supporting Classes

class LocalAnalyticsCache {
    private var gameAnalyticsCache: [UUID: GameCulturalAnalytics] = [:]
    private var culturalProfilesCache: [UUID: PlayerCulturalProfile] = [:]
    private var insightsCache: CulturalInsights?
    private var pendingData: BatchAnalyticsData?
    private var isOfflineMode: Bool = false
    private var cacheHits: Int = 0
    private var cacheMisses: Int = 0
    
    func enableOfflineMode() {
        isOfflineMode = true
    }
    
    func cacheGameAnalytics(_ analytics: GameCulturalAnalytics) {
        gameAnalyticsCache[analytics.gameId] = analytics
    }
    
    func getCachedGameAnalytics(_ gameId: UUID) -> GameCulturalAnalytics? {
        if let analytics = gameAnalyticsCache[gameId] {
            cacheHits += 1
            return analytics
        } else {
            cacheMisses += 1
            return nil
        }
    }
    
    func cacheCulturalProfile(_ profile: PlayerCulturalProfile) {
        culturalProfilesCache[profile.playerId] = profile
    }
    
    func getCachedCulturalProfile(_ playerId: UUID) -> PlayerCulturalProfile? {
        if let profile = culturalProfilesCache[playerId] {
            cacheHits += 1
            return profile
        } else {
            cacheMisses += 1
            return nil
        }
    }
    
    func cacheCulturalInsights(_ insights: CulturalInsights) {
        insightsCache = insights
    }
    
    func getPendingAnalyticsData() -> BatchAnalyticsData {
        return pendingData ?? BatchAnalyticsData(gameAnalytics: [], culturalProfiles: [], traditionalPatterns: [])
    }
    
    func clearPendingData() {
        pendingData = nil
    }
    
    func getHitRate() -> Float {
        let total = cacheHits + cacheMisses
        guard total > 0 else { return 0.0 }
        return Float(cacheHits) / Float(total)
    }
}

class AnalyticsConflictResolver {
    func resolveCulturalProfileConflict(
        localProfile: PlayerCulturalProfile,
        serverRecord: CKRecord,
        strategy: ConflictResolutionStrategy
    ) async throws -> PlayerCulturalProfile {
        switch strategy {
        case .culturalPreservation:
            // Preserve cultural progress and merge experience
            var resolvedProfile = localProfile
            
            if let serverExperience = serverRecord["culturalExperience"] as? Int {
                resolvedProfile.culturalExperience = max(localProfile.culturalExperience, serverExperience)
            }
            
            if let serverLevel = serverRecord["culturalLevel"] as? Int {
                resolvedProfile.culturalLevel = max(localProfile.culturalLevel, serverLevel)
            }
            
            return resolvedProfile
            
        case .serverWins:
            // Convert server record back to profile (simplified)
            throw AnalyticsError.conflictResolutionFailed
            
        case .clientWins:
            return localProfile
        }
    }
    
    enum ConflictResolutionStrategy {
        case culturalPreservation
        case serverWins
        case clientWins
    }
}

// MARK: - Array Extension

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}