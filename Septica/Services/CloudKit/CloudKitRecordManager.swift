//
//  CloudKitRecordManager.swift
//  Septica
//
//  CloudKit record type definitions and schema management for Romanian Septica
//  Implements comprehensive record types with cultural data preservation
//

import Foundation
import CloudKit
import OSLog

/// Manages CloudKit record types and schema operations for Septica
@MainActor
class CloudKitRecordManager: ObservableObject {
    
    // MARK: - CloudKit Record Type Constants
    
    struct RecordTypes {
        static let playerProfile = "SepticaPlayerProfile"
        static let gameRecord = "SepticaGameRecord"
        static let culturalProgress = "SepticaCulturalProgress"
        static let achievement = "SepticaAchievement"
        static let statistics = "SepticaStatistics"
        static let culturalElement = "SepticaCulturalElement"
        static let gameSession = "SepticaGameSession"
        static let cardMastery = "SepticaCardMastery"
        static let rewardChest = "SepticaRewardChest"
        static let seasonalProgress = "SepticaSeasonalProgress"
    }
    
    // MARK: - Dependencies
    
    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private let publicDatabase: CKDatabase
    private let logger = Logger(subsystem: "Septica", category: "CloudKitRecordManager")
    
    // MARK: - Initialization
    
    init(container: CKContainer) {
        self.container = container
        self.privateDatabase = container.privateCloudDatabase
        self.publicDatabase = container.publicCloudDatabase
    }
    
    // MARK: - Player Profile Records
    
    /// Convert CloudKitPlayerProfile to CKRecord
    func createPlayerProfileRecord(_ profile: CloudKitPlayerProfile) throws -> CKRecord {
        let recordID = CKRecord.ID(recordName: "player_\(profile.playerID)")
        let record = CKRecord(recordType: RecordTypes.playerProfile, recordID: recordID)
        
        // Basic profile data
        record["playerID"] = profile.playerID as CKRecordValue
        record["displayName"] = profile.displayName as CKRecordValue
        record["currentArena"] = profile.currentArena.rawValue as CKRecordValue
        record["trophies"] = profile.trophies as CKRecordValue
        record["totalGamesPlayed"] = profile.totalGamesPlayed as CKRecordValue
        record["totalWins"] = profile.totalWins as CKRecordValue
        record["currentStreak"] = profile.currentStreak as CKRecordValue
        record["longestStreak"] = profile.longestStreak as CKRecordValue
        record["favoriteAIDifficulty"] = profile.favoriteAIDifficulty as CKRecordValue
        record["lastPlayedDate"] = profile.lastPlayedDate as CKRecordValue
        record["createdDate"] = profile.createdDate as CKRecordValue
        
        // Romanian cultural data
        record["heritageEngagementLevel"] = profile.heritageEngagementLevel as CKRecordValue
        record["selectedAvatar"] = profile.selectedAvatar as CKRecordValue
        record["selectedAvatarFrame"] = profile.selectedAvatarFrame as CKRecordValue
        
        // Encode complex data structures
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
        
        let seasonalProgressData = try encoder.encode(profile.seasonalProgress)
        record["seasonalProgress"] = seasonalProgressData as CKRecordValue
        
        let unlockedAvatarsData = try encoder.encode(profile.unlockedAvatars)
        record["unlockedAvatars"] = unlockedAvatarsData as CKRecordValue
        
        let unlockedAvatarFramesData = try encoder.encode(profile.unlockedAvatarFrames)
        record["unlockedAvatarFrames"] = unlockedAvatarFramesData as CKRecordValue
        
        // Metadata
        record["syncVersion"] = 1 as CKRecordValue
        record["culturalVersion"] = "1.0" as CKRecordValue
        record["lastSyncDate"] = Date() as CKRecordValue
        
        return record
    }
    
    /// Convert CKRecord to CloudKitPlayerProfile
    func parsePlayerProfileRecord(_ record: CKRecord) throws -> CloudKitPlayerProfile {
        guard let playerID = record["playerID"] as? String else {
            throw CloudKitRecordError.missingRequiredField("playerID")
        }
        
        let decoder = JSONDecoder()
        
        // Parse complex data structures with fallback defaults
        let folkMusicData = record["folkMusicListened"] as? Data ?? Data()
        let folkMusicListened = (try? decoder.decode([String].self, from: folkMusicData)) ?? []
        
        let culturalStoriesData = record["culturalStoriesRead"] as? Data ?? Data()
        let culturalStoriesRead = (try? decoder.decode([String].self, from: culturalStoriesData)) ?? []
        
        let traditionalColorsData = record["traditionalColorsUnlocked"] as? Data ?? Data()
        let traditionalColorsUnlocked = (try? decoder.decode([String].self, from: traditionalColorsData)) ?? []
        
        let achievementsData = record["achievements"] as? Data ?? Data()
        let achievementStrings = (try? decoder.decode([String].self, from: achievementsData)) ?? []
        let achievements = achievementStrings.compactMap { CulturalAchievement(rawValue: $0) }
        
        let cardMasteriesData = record["cardMasteries"] as? Data ?? Data()
        let cardMasteries = (try? decoder.decode([String: CardMastery].self, from: cardMasteriesData)) ?? [:]
        
        let culturalProgressData = record["culturalEducationProgress"] as? Data ?? Data()
        let culturalProgress = (try? decoder.decode(CulturalEducationProgress.self, from: culturalProgressData)) ?? 
            CulturalEducationProgress(gameRulesLearned: [], folkTalesRead: 0, traditionalMusicKnowledge: 0, cardHistoryKnowledge: 0, quizScores: [:], culturalBadges: [])
        
        let preferencesData = record["preferences"] as? Data ?? Data()
        let preferences = (try? decoder.decode(GamePreferences.self, from: preferencesData)) ?? GamePreferences()
        
        let seasonalProgressData = record["seasonalProgress"] as? Data ?? Data()
        let seasonalProgress = (try? decoder.decode(SeasonalProgress.self, from: seasonalProgressData)) ?? 
            SeasonalProgress(seasonID: "2025-winter", seasonTrophies: 0, seasonWins: 0, seasonChestsOpened: 0, seasonAchievements: [], celebrationParticipation: [:])
        
        let unlockedAvatarsData = record["unlockedAvatars"] as? Data ?? Data()
        let unlockedAvatars = (try? decoder.decode([String].self, from: unlockedAvatarsData)) ?? [RomanianCharacterAvatar.traditionalPlayer.rawValue]
        
        let unlockedAvatarFramesData = record["unlockedAvatarFrames"] as? Data ?? Data()
        let unlockedAvatarFrames = (try? decoder.decode([String].self, from: unlockedAvatarFramesData)) ?? [AvatarFrame.woodenFrame.rawValue]
        
        return CloudKitPlayerProfile(
            playerID: playerID,
            displayName: record["displayName"] as? String ?? "Romanian Player",
            currentArena: RomanianArena(rawValue: record["currentArena"] as? Int ?? 0) ?? .sateImarica,
            trophies: record["trophies"] as? Int ?? 0,
            totalGamesPlayed: record["totalGamesPlayed"] as? Int ?? 0,
            totalWins: record["totalWins"] as? Int ?? 0,
            currentStreak: record["currentStreak"] as? Int ?? 0,
            longestStreak: record["longestStreak"] as? Int ?? 0,
            favoriteAIDifficulty: record["favoriteAIDifficulty"] as? String ?? "medium",
            cardMasteries: cardMasteries,
            achievements: achievements,
            seasonalProgress: seasonalProgress,
            preferences: preferences,
            culturalEducationProgress: culturalProgress,
            lastPlayedDate: record["lastPlayedDate"] as? Date ?? Date(),
            createdDate: record["createdDate"] as? Date ?? Date(),
            heritageEngagementLevel: record["heritageEngagementLevel"] as? Float ?? 0.0,
            folkMusicListened: folkMusicListened,
            culturalStoriesRead: culturalStoriesRead,
            traditionalColorsUnlocked: traditionalColorsUnlocked,
            selectedAvatar: record["selectedAvatar"] as? String ?? RomanianCharacterAvatar.traditionalPlayer.rawValue,
            selectedAvatarFrame: record["selectedAvatarFrame"] as? String ?? AvatarFrame.woodenFrame.rawValue,
            unlockedAvatars: unlockedAvatars,
            unlockedAvatarFrames: unlockedAvatarFrames
        )
    }
    
    // MARK: - Game Record Management
    
    /// Convert CloudKitGameRecord to CKRecord
    func createGameRecord(_ gameRecord: CloudKitGameRecord) throws -> CKRecord {
        let recordID = CKRecord.ID(recordName: "game_\(gameRecord.gameID)")
        let record = CKRecord(recordType: RecordTypes.gameRecord, recordID: recordID)
        
        // Basic game data
        record["gameID"] = gameRecord.gameID as CKRecordValue
        record["playerID"] = gameRecord.playerID as CKRecordValue
        record["opponentType"] = gameRecord.opponentType as CKRecordValue
        record["aiDifficulty"] = gameRecord.aiDifficulty as CKRecordValue?
        record["gameResult"] = gameRecord.gameResult as CKRecordValue
        record["gameDuration"] = gameRecord.gameDuration as CKRecordValue
        record["timestamp"] = gameRecord.timestamp as CKRecordValue
        record["arenaAtTimeOfPlay"] = gameRecord.arenaAtTimeOfPlay.rawValue as CKRecordValue
        
        // Romanian cultural gameplay metrics
        record["sevenWildCardUses"] = gameRecord.sevenWildCardUses as CKRecordValue
        record["eightSpecialUses"] = gameRecord.eightSpecialUses as CKRecordValue
        record["tricksWon"] = gameRecord.tricksWon as CKRecordValue
        record["pointsScored"] = gameRecord.pointsScored as CKRecordValue
        
        // Encode complex data
        let encoder = JSONEncoder()
        
        let finalScoreData = try encoder.encode(gameRecord.finalScore)
        record["finalScore"] = finalScoreData as CKRecordValue
        
        let cardsPlayedData = try encoder.encode(gameRecord.cardsPlayed)
        record["cardsPlayed"] = cardsPlayedData as CKRecordValue
        
        let culturalMomentsData = try encoder.encode(gameRecord.culturalMomentsTriggered)
        record["culturalMomentsTriggered"] = culturalMomentsData as CKRecordValue
        
        let mistakesData = try encoder.encode(gameRecord.mistakesMade)
        record["mistakesMade"] = mistakesData as CKRecordValue
        
        let strategicMovesData = try encoder.encode(gameRecord.strategicMoves)
        record["strategicMoves"] = strategicMovesData as CKRecordValue
        
        // Metadata
        record["culturalVersion"] = "1.0" as CKRecordValue
        record["arenaDisplayName"] = gameRecord.arenaAtTimeOfPlay.displayName as CKRecordValue
        record["syncTimestamp"] = Date() as CKRecordValue
        
        return record
    }
    
    /// Convert CKRecord to CloudKitGameRecord
    func parseGameRecord(_ record: CKRecord) throws -> CloudKitGameRecord {
        guard let gameID = record["gameID"] as? String,
              let playerID = record["playerID"] as? String,
              let opponentType = record["opponentType"] as? String,
              let gameResult = record["gameResult"] as? String,
              let gameDuration = record["gameDuration"] as? TimeInterval,
              let timestamp = record["timestamp"] as? Date,
              let arenaRawValue = record["arenaAtTimeOfPlay"] as? Int else {
            throw CloudKitRecordError.missingRequiredField("game record fields")
        }
        
        let decoder = JSONDecoder()
        
        // Parse complex data with fallback defaults
        let finalScoreData = record["finalScore"] as? Data ?? Data()
        let finalScore = (try? decoder.decode(GameScore.self, from: finalScoreData)) ?? 
            GameScore(playerScore: 0, opponentScore: 0, tricksWon: 0, tricksLost: 0)
        
        let cardsPlayedData = record["cardsPlayed"] as? Data ?? Data()
        let cardsPlayed = (try? decoder.decode([CardPlayRecord].self, from: cardsPlayedData)) ?? []
        
        let culturalMomentsData = record["culturalMomentsTriggered"] as? Data ?? Data()
        let culturalMomentsTriggered = (try? decoder.decode([String].self, from: culturalMomentsData)) ?? []
        
        let mistakesData = record["mistakesMade"] as? Data ?? Data()
        let mistakesMade = (try? decoder.decode([String].self, from: mistakesData)) ?? []
        
        let strategicMovesData = record["strategicMoves"] as? Data ?? Data()
        let strategicMoves = (try? decoder.decode([String].self, from: strategicMovesData)) ?? []
        
        return CloudKitGameRecord(
            gameID: gameID,
            playerID: playerID,
            opponentType: opponentType,
            aiDifficulty: record["aiDifficulty"] as? String,
            gameResult: gameResult,
            finalScore: finalScore,
            gameDuration: gameDuration,
            cardsPlayed: cardsPlayed,
            culturalMomentsTriggered: culturalMomentsTriggered,
            timestamp: timestamp,
            arenaAtTimeOfPlay: RomanianArena(rawValue: arenaRawValue) ?? .sateImarica,
            sevenWildCardUses: record["sevenWildCardUses"] as? Int ?? 0,
            eightSpecialUses: record["eightSpecialUses"] as? Int ?? 0,
            tricksWon: record["tricksWon"] as? Int ?? 0,
            pointsScored: record["pointsScored"] as? Int ?? 0,
            mistakesMade: mistakesMade,
            strategicMoves: strategicMoves
        )
    }
    
    // MARK: - Cultural Progress Records
    
    /// Convert CulturalEducationProgress to CKRecord
    func createCulturalProgressRecord(_ progress: CulturalEducationProgress, playerID: String) throws -> CKRecord {
        let recordID = CKRecord.ID(recordName: "cultural_\(playerID)")
        let record = CKRecord(recordType: RecordTypes.culturalProgress, recordID: recordID)
        
        // Basic cultural data
        record["playerID"] = playerID as CKRecordValue
        record["folkTalesRead"] = progress.folkTalesRead as CKRecordValue
        record["traditionalMusicKnowledge"] = progress.traditionalMusicKnowledge as CKRecordValue
        record["cardHistoryKnowledge"] = progress.cardHistoryKnowledge as CKRecordValue
        record["culturalBadgesCount"] = progress.culturalBadges.count as CKRecordValue
        
        // Encode complex data
        let encoder = JSONEncoder()
        
        let gameRulesLearnedData = try encoder.encode(progress.gameRulesLearned)
        record["gameRulesLearned"] = gameRulesLearnedData as CKRecordValue
        
        let quizScoresData = try encoder.encode(progress.quizScores)
        record["quizScores"] = quizScoresData as CKRecordValue
        
        let culturalBadgesData = try encoder.encode(progress.culturalBadges)
        record["culturalBadges"] = culturalBadgesData as CKRecordValue
        
        // Metadata
        record["culturalVersion"] = "1.0" as CKRecordValue
        record["syncTimestamp"] = Date() as CKRecordValue
        
        return record
    }
    
    /// Convert CKRecord to CulturalEducationProgress
    func parseCulturalProgressRecord(_ record: CKRecord) throws -> CulturalEducationProgress {
        let decoder = JSONDecoder()
        
        let gameRulesLearnedData = record["gameRulesLearned"] as? Data ?? Data()
        let gameRulesLearned = (try? decoder.decode([String].self, from: gameRulesLearnedData)) ?? []
        
        let quizScoresData = record["quizScores"] as? Data ?? Data()
        let quizScores = (try? decoder.decode([String: Int].self, from: quizScoresData)) ?? [:]
        
        let culturalBadgesData = record["culturalBadges"] as? Data ?? Data()
        let culturalBadges = (try? decoder.decode([String].self, from: culturalBadgesData)) ?? []
        
        return CulturalEducationProgress(
            gameRulesLearned: gameRulesLearned,
            folkTalesRead: record["folkTalesRead"] as? Int ?? 0,
            traditionalMusicKnowledge: record["traditionalMusicKnowledge"] as? Int ?? 0,
            cardHistoryKnowledge: record["cardHistoryKnowledge"] as? Int ?? 0,
            quizScores: quizScores,
            culturalBadges: culturalBadges
        )
    }
    
    // MARK: - Achievements Records
    
    /// Create achievement record for a specific achievement
    func createAchievementRecord(_ achievement: CulturalAchievement, playerID: String, unlockedDate: Date) throws -> CKRecord {
        let recordID = CKRecord.ID(recordName: "achievement_\(playerID)_\(achievement.rawValue)")
        let record = CKRecord(recordType: RecordTypes.achievement, recordID: recordID)
        
        record["playerID"] = playerID as CKRecordValue
        record["achievementID"] = achievement.rawValue as CKRecordValue
        record["achievementTitle"] = achievement.title as CKRecordValue
        record["achievementDescription"] = achievement.description as CKRecordValue
        record["unlockedDate"] = unlockedDate as CKRecordValue
        
        // Romanian cultural metadata
        record["culturalVersion"] = "1.0" as CKRecordValue
        record["heritageCategory"] = "romanian_cultural" as CKRecordValue
        record["syncTimestamp"] = Date() as CKRecordValue
        
        return record
    }
    
    /// Parse achievement record from CloudKit
    func parseAchievementRecord(_ record: CKRecord) throws -> (achievement: CulturalAchievement, playerID: String, unlockedDate: Date) {
        guard let playerID = record["playerID"] as? String,
              let achievementID = record["achievementID"] as? String,
              let unlockedDate = record["unlockedDate"] as? Date,
              let achievement = CulturalAchievement(rawValue: achievementID) else {
            throw CloudKitRecordError.missingRequiredField("achievement record fields")
        }
        
        return (achievement: achievement, playerID: playerID, unlockedDate: unlockedDate)
    }
    
    // MARK: - Schema Validation and Setup
    
    /// Validate that all required CloudKit record types are properly configured
    func validateCloudKitSchema() async throws {
        logger.info("🔍 Validating CloudKit schema for Romanian Septica...")
        
        // Test creating each record type to ensure schema compatibility
        let testPlayerProfile = createTestPlayerProfile()
        let testGameRecord = createTestGameRecord()
        let testCulturalProgress = createTestCulturalProgress()
        
        do {
            _ = try createPlayerProfileRecord(testPlayerProfile)
            _ = try createGameRecord(testGameRecord)
            _ = try createCulturalProgressRecord(testCulturalProgress, playerID: "test")
            _ = try createAchievementRecord(.septicaMaster, playerID: "test", unlockedDate: Date())
            
            logger.info("✅ CloudKit schema validation successful for Romanian cultural data")
        } catch {
            logger.error("❌ CloudKit schema validation failed: \(error.localizedDescription)")
            throw CloudKitRecordError.schemaValidationFailed(error)
        }
    }
    
    // MARK: - Test Data Creation
    
    private func createTestPlayerProfile() -> CloudKitPlayerProfile {
        return CloudKitPlayerProfile(
            playerID: "test_player",
            displayName: "Test Romanian Player",
            currentArena: .sateImarica,
            trophies: 0,
            totalGamesPlayed: 0,
            totalWins: 0,
            currentStreak: 0,
            longestStreak: 0,
            favoriteAIDifficulty: "medium",
            cardMasteries: [:],
            achievements: [],
            seasonalProgress: SeasonalProgress(seasonID: "2025-test", seasonTrophies: 0, seasonWins: 0, seasonChestsOpened: 0, seasonAchievements: [], celebrationParticipation: [:]),
            preferences: GamePreferences(),
            culturalEducationProgress: CulturalEducationProgress(gameRulesLearned: [], folkTalesRead: 0, traditionalMusicKnowledge: 0, cardHistoryKnowledge: 0, quizScores: [:], culturalBadges: []),
            lastPlayedDate: Date(),
            createdDate: Date(),
            heritageEngagementLevel: 0.0,
            folkMusicListened: [],
            culturalStoriesRead: [],
            traditionalColorsUnlocked: [],
            selectedAvatar: RomanianCharacterAvatar.traditionalPlayer.rawValue,
            selectedAvatarFrame: AvatarFrame.woodenFrame.rawValue,
            unlockedAvatars: [RomanianCharacterAvatar.traditionalPlayer.rawValue],
            unlockedAvatarFrames: [AvatarFrame.woodenFrame.rawValue]
        )
    }
    
    private func createTestGameRecord() -> CloudKitGameRecord {
        return CloudKitGameRecord(
            gameID: "test_game",
            playerID: "test_player",
            opponentType: "AI",
            aiDifficulty: "medium",
            gameResult: "win",
            finalScore: GameScore(playerScore: 10, opponentScore: 5, tricksWon: 8, tricksLost: 2),
            gameDuration: 300.0,
            cardsPlayed: [],
            culturalMomentsTriggered: [],
            timestamp: Date(),
            arenaAtTimeOfPlay: .sateImarica,
            sevenWildCardUses: 0,
            eightSpecialUses: 0,
            tricksWon: 8,
            pointsScored: 10,
            mistakesMade: [],
            strategicMoves: []
        )
    }
    
    private func createTestCulturalProgress() -> CulturalEducationProgress {
        return CulturalEducationProgress(
            gameRulesLearned: [],
            folkTalesRead: 0,
            traditionalMusicKnowledge: 0,
            cardHistoryKnowledge: 0,
            quizScores: [:],
            culturalBadges: []
        )
    }
}

// MARK: - CloudKit Record Errors

enum CloudKitRecordError: LocalizedError {
    case missingRequiredField(String)
    case invalidRecordType(String)
    case encodingFailed(Error)
    case decodingFailed(Error)
    case schemaValidationFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .missingRequiredField(let field):
            return "Missing required field: \(field)"
        case .invalidRecordType(let type):
            return "Invalid record type: \(type)"
        case .encodingFailed(let error):
            return "Failed to encode data: \(error.localizedDescription)"
        case .decodingFailed(let error):
            return "Failed to decode data: \(error.localizedDescription)"
        case .schemaValidationFailed(let error):
            return "CloudKit schema validation failed: \(error.localizedDescription)"
        }
    }
}