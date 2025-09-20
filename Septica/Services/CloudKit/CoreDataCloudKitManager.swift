//
//  CoreDataCloudKitManager.swift
//  Septica
//
//  Core Data and CloudKit integration manager for offline-first architecture
//  Implements bidirectional sync between local Core Data and CloudKit
//

import Foundation
import CoreData
import CloudKit
import Combine
import OSLog

/// Manages Core Data persistence with CloudKit synchronization for offline-first architecture
@MainActor
class CoreDataCloudKitManager: ObservableObject {
    
    // MARK: - Published State
    
    @Published var isReady: Bool = false
    @Published var syncInProgress: Bool = false
    @Published var lastSyncDate: Date?
    @Published var pendingChanges: Int = 0
    @Published var conflictCount: Int = 0
    
    // MARK: - Core Data Stack
    
    private lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "SepticaDataModel")
        
        // Configure CloudKit integration
        let description = container.persistentStoreDescriptions.first
        description?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        // CloudKit configuration
        description?.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.dev.septica.romanian.game")
        
        container.loadPersistentStores { [weak self] _, error in
            if let error = error {
                self?.logger.error("❌ Core Data failed to load: \\(error.localizedDescription)")
            } else {
                self?.logger.info("✅ Core Data loaded with CloudKit integration")
                Task { @MainActor in
                    self?.isReady = true
                }
            }
        }
        
        // Automatically merge changes from parent context
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    private var backgroundContext: NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }
    
    // MARK: - Dependencies
    
    private let logger = Logger(subsystem: "Septica", category: "CoreDataCloudKit")
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        setupNotifications()
        logger.info("🏗️ CoreDataCloudKitManager initialized")
    }
    
    // MARK: - Setup Methods
    
    private func setupNotifications() {
        // Monitor remote changes from CloudKit
        NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.handleRemoteChanges()
                }
            }
            .store(in: &cancellables)
        
        // Monitor local context changes
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .sink { [weak self] notification in
                Task { @MainActor in
                    await self?.handleLocalChanges(notification)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Player Profile Management
    
    /// Save player profile to Core Data with CloudKit sync
    func savePlayerProfile(_ profile: CloudKitPlayerProfile) async throws {
        logger.info("💾 Saving player profile to Core Data: \\(profile.displayName)")
        
        try await withCheckedThrowingContinuation { continuation in
            backgroundContext.perform {
                do {
                    // Check if profile already exists
                    let request: NSFetchRequest<PlayerProfileEntity> = PlayerProfileEntity.fetchRequest()
                    request.predicate = NSPredicate(format: "playerID == %@", profile.playerID)
                    
                    let existingProfiles = try self.backgroundContext.fetch(request)
                    let entity = existingProfiles.first ?? PlayerProfileEntity(context: self.backgroundContext)
                    
                    // Update entity with profile data
                    self.updatePlayerProfileEntity(entity, with: profile)
                    
                    try self.backgroundContext.save()
                    continuation.resume()
                    
                    self.logger.info("✅ Player profile saved to Core Data")
                    
                } catch {
                    self.logger.error("❌ Failed to save player profile: \\(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }
        
        await updatePendingChanges()
    }
    
    /// Load player profile from Core Data
    func loadPlayerProfile(playerID: String) async throws -> CloudKitPlayerProfile? {
        logger.info("📱 Loading player profile from Core Data: \\(playerID)")
        
        return try await withCheckedThrowingContinuation { continuation in
            backgroundContext.perform {
                do {
                    let request: NSFetchRequest<PlayerProfileEntity> = PlayerProfileEntity.fetchRequest()
                    request.predicate = NSPredicate(format: "playerID == %@", playerID)
                    
                    let entities = try self.backgroundContext.fetch(request)
                    
                    if let entity = entities.first {
                        let profile = self.createPlayerProfile(from: entity)
                        continuation.resume(returning: profile)
                        self.logger.info("✅ Player profile loaded from Core Data")
                    } else {
                        continuation.resume(returning: nil)
                        self.logger.info("📭 No player profile found in Core Data")
                    }
                    
                } catch {
                    self.logger.error("❌ Failed to load player profile: \\(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Game Record Management
    
    /// Save game record to Core Data with CloudKit sync
    func saveGameRecord(_ gameRecord: CloudKitGameRecord) async throws {
        logger.info("💾 Saving game record to Core Data: \\(gameRecord.gameID)")
        
        try await withCheckedThrowingContinuation { continuation in
            backgroundContext.perform {
                do {
                    // Check if record already exists
                    let request: NSFetchRequest<GameRecordEntity> = GameRecordEntity.fetchRequest()
                    request.predicate = NSPredicate(format: "gameID == %@", gameRecord.gameID)
                    
                    let existingRecords = try self.backgroundContext.fetch(request)
                    let entity = existingRecords.first ?? GameRecordEntity(context: self.backgroundContext)
                    
                    // Update entity with game record data
                    self.updateGameRecordEntity(entity, with: gameRecord)
                    
                    try self.backgroundContext.save()
                    continuation.resume()
                    
                    self.logger.info("✅ Game record saved to Core Data")
                    
                } catch {
                    self.logger.error("❌ Failed to save game record: \\(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }
        
        await updatePendingChanges()
    }
    
    /// Load game records for a player from Core Data
    func loadGameRecords(for playerID: String, limit: Int = 50) async throws -> [CloudKitGameRecord] {
        logger.info("📱 Loading game records from Core Data for player: \\(playerID)")
        
        return try await withCheckedThrowingContinuation { continuation in
            backgroundContext.perform {
                do {
                    let request: NSFetchRequest<GameRecordEntity> = GameRecordEntity.fetchRequest()
                    request.predicate = NSPredicate(format: "playerID == %@", playerID)
                    request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
                    request.fetchLimit = limit
                    
                    let entities = try self.backgroundContext.fetch(request)
                    let gameRecords = entities.compactMap { self.createGameRecord(from: $0) }
                    
                    continuation.resume(returning: gameRecords)
                    self.logger.info("✅ Loaded \\(gameRecords.count) game records from Core Data")
                    
                } catch {
                    self.logger.error("❌ Failed to load game records: \\(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Cultural Progress Management
    
    /// Save cultural progress to Core Data
    func saveCulturalProgress(_ progress: CulturalEducationProgress, for playerID: String) async throws {
        logger.info("💾 Saving cultural progress to Core Data for player: \\(playerID)")
        
        try await withCheckedThrowingContinuation { continuation in
            backgroundContext.perform {
                do {
                    let request: NSFetchRequest<CulturalProgressEntity> = CulturalProgressEntity.fetchRequest()
                    request.predicate = NSPredicate(format: "playerID == %@", playerID)
                    
                    let existingEntities = try self.backgroundContext.fetch(request)
                    let entity = existingEntities.first ?? CulturalProgressEntity(context: self.backgroundContext)
                    
                    // Update entity with cultural progress data
                    self.updateCulturalProgressEntity(entity, with: progress, playerID: playerID)
                    
                    try self.backgroundContext.save()
                    continuation.resume()
                    
                    self.logger.info("✅ Cultural progress saved to Core Data")
                    
                } catch {
                    self.logger.error("❌ Failed to save cultural progress: \\(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }
        
        await updatePendingChanges()
    }
    
    /// Load cultural progress from Core Data
    func loadCulturalProgress(for playerID: String) async throws -> CulturalEducationProgress? {
        logger.info("📱 Loading cultural progress from Core Data for player: \\(playerID)")
        
        return try await withCheckedThrowingContinuation { continuation in
            backgroundContext.perform {
                do {
                    let request: NSFetchRequest<CulturalProgressEntity> = CulturalProgressEntity.fetchRequest()
                    request.predicate = NSPredicate(format: "playerID == %@", playerID)
                    
                    let entities = try self.backgroundContext.fetch(request)
                    
                    if let entity = entities.first {
                        let progress = self.createCulturalProgress(from: entity)
                        continuation.resume(returning: progress)
                        self.logger.info("✅ Cultural progress loaded from Core Data")
                    } else {
                        continuation.resume(returning: nil)
                        self.logger.info("📭 No cultural progress found in Core Data")
                    }
                    
                } catch {
                    self.logger.error("❌ Failed to load cultural progress: \\(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Sync Management
    
    /// Force sync with CloudKit
    func forceSyncWithCloudKit() async throws {
        guard isReady else {
            throw CoreDataCloudKitError.notReady
        }
        
        logger.info("🔄 Forcing sync with CloudKit")
        syncInProgress = true
        
        do {
            // Trigger CloudKit sync by saving context
            try await withCheckedThrowingContinuation { continuation in
                context.perform {
                    do {
                        try self.context.save()
                        continuation.resume()
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
            
            lastSyncDate = Date()
            logger.info("✅ CloudKit sync completed")
            
        } catch {
            logger.error("❌ CloudKit sync failed: \\(error.localizedDescription)")
            throw error
        }
        
        syncInProgress = false
    }
    
    // MARK: - Private Methods
    
    private func handleRemoteChanges() async {
        logger.info("📡 Handling remote changes from CloudKit")
        await updatePendingChanges()
    }
    
    private func handleLocalChanges(_ notification: Notification) async {
        logger.info("📱 Handling local Core Data changes")
        await updatePendingChanges()
    }
    
    private func updatePendingChanges() async {
        // Count unsync'd records
        let request: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "PlayerProfileEntity")
        request.resultType = .countResultType
        
        do {
            let count = try context.count(for: request)
            pendingChanges = count
        } catch {
            logger.error("Failed to count pending changes: \\(error.localizedDescription)")
        }
    }
    
    // MARK: - Entity Conversion Methods
    
    private func updatePlayerProfileEntity(_ entity: PlayerProfileEntity, with profile: CloudKitPlayerProfile) {
        entity.playerID = profile.playerID
        entity.displayName = profile.displayName
        entity.currentArena = Int32(profile.currentArena.rawValue)
        entity.trophies = Int32(profile.trophies)
        entity.totalGamesPlayed = Int32(profile.totalGamesPlayed)
        entity.totalWins = Int32(profile.totalWins)
        entity.currentStreak = Int32(profile.currentStreak)
        entity.longestStreak = Int32(profile.longestStreak)
        entity.favoriteAIDifficulty = profile.favoriteAIDifficulty
        entity.lastPlayedDate = profile.lastPlayedDate
        entity.createdDate = profile.createdDate
        entity.heritageEngagementLevel = profile.heritageEngagementLevel
        entity.selectedAvatar = profile.selectedAvatar
        entity.selectedAvatarFrame = profile.selectedAvatarFrame
        
        // Encode complex data as JSON
        let encoder = JSONEncoder()
        entity.folkMusicListenedData = try? encoder.encode(profile.folkMusicListened)
        entity.culturalStoriesReadData = try? encoder.encode(profile.culturalStoriesRead)
        entity.traditionalColorsUnlockedData = try? encoder.encode(profile.traditionalColorsUnlocked)
        entity.achievementsData = try? encoder.encode(profile.achievements.map { $0.rawValue })
        entity.cardMasteriesData = try? encoder.encode(profile.cardMasteries)
        entity.culturalEducationProgressData = try? encoder.encode(profile.culturalEducationProgress)
        entity.preferencesData = try? encoder.encode(profile.preferences)
        entity.seasonalProgressData = try? encoder.encode(profile.seasonalProgress)
        entity.unlockedAvatarsData = try? encoder.encode(profile.unlockedAvatars)
        entity.unlockedAvatarFramesData = try? encoder.encode(profile.unlockedAvatarFrames)
    }
    
    private func createPlayerProfile(from entity: PlayerProfileEntity) -> CloudKitPlayerProfile? {
        guard let playerID = entity.playerID,
              let displayName = entity.displayName else {
            return nil
        }
        
        let decoder = JSONDecoder()
        
        // Decode complex data with fallbacks
        let folkMusicListened = (entity.folkMusicListenedData.flatMap { try? decoder.decode([String].self, from: $0) }) ?? []
        let culturalStoriesRead = (entity.culturalStoriesReadData.flatMap { try? decoder.decode([String].self, from: $0) }) ?? []
        let traditionalColorsUnlocked = (entity.traditionalColorsUnlockedData.flatMap { try? decoder.decode([String].self, from: $0) }) ?? []
        let achievementStrings = (entity.achievementsData.flatMap { try? decoder.decode([String].self, from: $0) }) ?? []
        let achievements = achievementStrings.compactMap { CulturalAchievement(rawValue: $0) }
        let cardMasteries = (entity.cardMasteriesData.flatMap { try? decoder.decode([String: CardMastery].self, from: $0) }) ?? [:]
        let culturalEducationProgress = (entity.culturalEducationProgressData.flatMap { try? decoder.decode(CulturalEducationProgress.self, from: $0) }) ?? 
            CulturalEducationProgress(gameRulesLearned: [], folkTalesRead: 0, traditionalMusicKnowledge: 0, cardHistoryKnowledge: 0, quizScores: [:], culturalBadges: [])
        let preferences = (entity.preferencesData.flatMap { try? decoder.decode(GamePreferences.self, from: $0) }) ?? GamePreferences()
        let seasonalProgress = (entity.seasonalProgressData.flatMap { try? decoder.decode(SeasonalProgress.self, from: $0) }) ?? 
            SeasonalProgress(seasonID: "2025-winter", seasonTrophies: 0, seasonWins: 0, seasonChestsOpened: 0, seasonAchievements: [], celebrationParticipation: [:])
        let unlockedAvatars = (entity.unlockedAvatarsData.flatMap { try? decoder.decode([String].self, from: $0) }) ?? [RomanianCharacterAvatar.traditionalPlayer.rawValue]
        let unlockedAvatarFrames = (entity.unlockedAvatarFramesData.flatMap { try? decoder.decode([String].self, from: $0) }) ?? [AvatarFrame.woodenFrame.rawValue]
        
        return CloudKitPlayerProfile(
            playerID: playerID,
            displayName: displayName,
            currentArena: RomanianArena(rawValue: Int(entity.currentArena)) ?? .sateImarica,
            trophies: Int(entity.trophies),
            totalGamesPlayed: Int(entity.totalGamesPlayed),
            totalWins: Int(entity.totalWins),
            currentStreak: Int(entity.currentStreak),
            longestStreak: Int(entity.longestStreak),
            favoriteAIDifficulty: entity.favoriteAIDifficulty ?? "medium",
            cardMasteries: cardMasteries,
            achievements: achievements,
            seasonalProgress: seasonalProgress,
            preferences: preferences,
            culturalEducationProgress: culturalEducationProgress,
            lastPlayedDate: entity.lastPlayedDate ?? Date(),
            createdDate: entity.createdDate ?? Date(),
            heritageEngagementLevel: entity.heritageEngagementLevel,
            folkMusicListened: folkMusicListened,
            culturalStoriesRead: culturalStoriesRead,
            traditionalColorsUnlocked: traditionalColorsUnlocked,
            selectedAvatar: entity.selectedAvatar ?? RomanianCharacterAvatar.traditionalPlayer.rawValue,
            selectedAvatarFrame: entity.selectedAvatarFrame ?? AvatarFrame.woodenFrame.rawValue,
            unlockedAvatars: unlockedAvatars,
            unlockedAvatarFrames: unlockedAvatarFrames
        )
    }
    
    private func updateGameRecordEntity(_ entity: GameRecordEntity, with record: CloudKitGameRecord) {
        entity.gameID = record.gameID
        entity.playerID = record.playerID
        entity.opponentType = record.opponentType
        entity.aiDifficulty = record.aiDifficulty
        entity.gameResult = record.gameResult
        entity.gameDuration = record.gameDuration
        entity.timestamp = record.timestamp
        entity.arenaAtTimeOfPlay = Int32(record.arenaAtTimeOfPlay.rawValue)
        entity.sevenWildCardUses = Int32(record.sevenWildCardUses)
        entity.eightSpecialUses = Int32(record.eightSpecialUses)
        entity.tricksWon = Int32(record.tricksWon)
        entity.pointsScored = Int32(record.pointsScored)
        
        // Encode complex data
        let encoder = JSONEncoder()
        entity.finalScoreData = try? encoder.encode(record.finalScore)
        entity.cardsPlayedData = try? encoder.encode(record.cardsPlayed)
        entity.culturalMomentsTriggeredData = try? encoder.encode(record.culturalMomentsTriggered)
        entity.mistakesMadeData = try? encoder.encode(record.mistakesMade)
        entity.strategicMovesData = try? encoder.encode(record.strategicMoves)
    }
    
    private func createGameRecord(from entity: GameRecordEntity) -> CloudKitGameRecord? {
        guard let gameID = entity.gameID,
              let playerID = entity.playerID,
              let opponentType = entity.opponentType,
              let gameResult = entity.gameResult,
              let timestamp = entity.timestamp else {
            return nil
        }
        
        let decoder = JSONDecoder()
        
        let finalScore = (entity.finalScoreData.flatMap { try? decoder.decode(GameScore.self, from: $0) }) ?? 
            GameScore(playerScore: 0, opponentScore: 0, tricksWon: 0, tricksLost: 0)
        let cardsPlayed = (entity.cardsPlayedData.flatMap { try? decoder.decode([CardPlayRecord].self, from: $0) }) ?? []
        let culturalMomentsTriggered = (entity.culturalMomentsTriggeredData.flatMap { try? decoder.decode([String].self, from: $0) }) ?? []
        let mistakesMade = (entity.mistakesMadeData.flatMap { try? decoder.decode([String].self, from: $0) }) ?? []
        let strategicMoves = (entity.strategicMovesData.flatMap { try? decoder.decode([String].self, from: $0) }) ?? []
        
        return CloudKitGameRecord(
            gameID: gameID,
            playerID: playerID,
            opponentType: opponentType,
            aiDifficulty: entity.aiDifficulty,
            gameResult: gameResult,
            finalScore: finalScore,
            gameDuration: entity.gameDuration,
            cardsPlayed: cardsPlayed,
            culturalMomentsTriggered: culturalMomentsTriggered,
            timestamp: timestamp,
            arenaAtTimeOfPlay: RomanianArena(rawValue: Int(entity.arenaAtTimeOfPlay)) ?? .sateImarica,
            sevenWildCardUses: Int(entity.sevenWildCardUses),
            eightSpecialUses: Int(entity.eightSpecialUses),
            tricksWon: Int(entity.tricksWon),
            pointsScored: Int(entity.pointsScored),
            mistakesMade: mistakesMade,
            strategicMoves: strategicMoves
        )
    }
    
    private func updateCulturalProgressEntity(_ entity: CulturalProgressEntity, with progress: CulturalEducationProgress, playerID: String) {
        entity.playerID = playerID
        entity.folkTalesRead = Int32(progress.folkTalesRead)
        entity.traditionalMusicKnowledge = Int32(progress.traditionalMusicKnowledge)
        entity.cardHistoryKnowledge = Int32(progress.cardHistoryKnowledge)
        
        // Encode complex data
        let encoder = JSONEncoder()
        entity.gameRulesLearnedData = try? encoder.encode(progress.gameRulesLearned)
        entity.quizScoresData = try? encoder.encode(progress.quizScores)
        entity.culturalBadgesData = try? encoder.encode(progress.culturalBadges)
    }
    
    private func createCulturalProgress(from entity: CulturalProgressEntity) -> CulturalEducationProgress {
        let decoder = JSONDecoder()
        
        let gameRulesLearned = (entity.gameRulesLearnedData.flatMap { try? decoder.decode([String].self, from: $0) }) ?? []
        let quizScores = (entity.quizScoresData.flatMap { try? decoder.decode([String: Int].self, from: $0) }) ?? [:]
        let culturalBadges = (entity.culturalBadgesData.flatMap { try? decoder.decode([String].self, from: $0) }) ?? []
        
        return CulturalEducationProgress(
            gameRulesLearned: gameRulesLearned,
            folkTalesRead: Int(entity.folkTalesRead),
            traditionalMusicKnowledge: Int(entity.traditionalMusicKnowledge),
            cardHistoryKnowledge: Int(entity.cardHistoryKnowledge),
            quizScores: quizScores,
            culturalBadges: culturalBadges
        )
    }
}

// MARK: - Core Data Entities

// Note: These would typically be generated from a Core Data model file (.xcdatamodeld)
// For now, we'll define them as protocols to indicate the expected structure

protocol PlayerProfileEntity: AnyObject {
    var playerID: String? { get set }
    var displayName: String? { get set }
    var currentArena: Int32 { get set }
    var trophies: Int32 { get set }
    var totalGamesPlayed: Int32 { get set }
    var totalWins: Int32 { get set }
    var currentStreak: Int32 { get set }
    var longestStreak: Int32 { get set }
    var favoriteAIDifficulty: String? { get set }
    var lastPlayedDate: Date? { get set }
    var createdDate: Date? { get set }
    var heritageEngagementLevel: Float { get set }
    var selectedAvatar: String? { get set }
    var selectedAvatarFrame: String? { get set }
    
    // JSON-encoded data properties
    var folkMusicListenedData: Data? { get set }
    var culturalStoriesReadData: Data? { get set }
    var traditionalColorsUnlockedData: Data? { get set }
    var achievementsData: Data? { get set }
    var cardMasteriesData: Data? { get set }
    var culturalEducationProgressData: Data? { get set }
    var preferencesData: Data? { get set }
    var seasonalProgressData: Data? { get set }
    var unlockedAvatarsData: Data? { get set }
    var unlockedAvatarFramesData: Data? { get set }
}

protocol GameRecordEntity: AnyObject {
    var gameID: String? { get set }
    var playerID: String? { get set }
    var opponentType: String? { get set }
    var aiDifficulty: String? { get set }
    var gameResult: String? { get set }
    var gameDuration: TimeInterval { get set }
    var timestamp: Date? { get set }
    var arenaAtTimeOfPlay: Int32 { get set }
    var sevenWildCardUses: Int32 { get set }
    var eightSpecialUses: Int32 { get set }
    var tricksWon: Int32 { get set }
    var pointsScored: Int32 { get set }
    
    // JSON-encoded data properties
    var finalScoreData: Data? { get set }
    var cardsPlayedData: Data? { get set }
    var culturalMomentsTriggeredData: Data? { get set }
    var mistakesMadeData: Data? { get set }
    var strategicMovesData: Data? { get set }
}

protocol CulturalProgressEntity: AnyObject {
    var playerID: String? { get set }
    var folkTalesRead: Int32 { get set }
    var traditionalMusicKnowledge: Int32 { get set }
    var cardHistoryKnowledge: Int32 { get set }
    
    // JSON-encoded data properties
    var gameRulesLearnedData: Data? { get set }
    var quizScoresData: Data? { get set }
    var culturalBadgesData: Data? { get set }
}

// MARK: - Errors

enum CoreDataCloudKitError: LocalizedError {
    case notReady
    case saveFailed(Error)
    case fetchFailed(Error)
    case syncFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .notReady:
            return "Core Data CloudKit integration is not ready"
        case .saveFailed(let error):
            return "Failed to save to Core Data: \\(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch from Core Data: \\(error.localizedDescription)"
        case .syncFailed(let error):
            return "Failed to sync with CloudKit: \\(error.localizedDescription)"
        }
    }
}

// MARK: - NSManagedObject Extensions

// Extensions to make existing NSManagedObject conform to our protocols
extension NSManagedObject {
    static var fetchRequest: NSFetchRequest<Self> {
        return NSFetchRequest<Self>(entityName: String(describing: self))
    }
}