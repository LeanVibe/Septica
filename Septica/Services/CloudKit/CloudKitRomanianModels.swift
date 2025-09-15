//
//  CloudKitRomanianModels.swift
//  Septica
//
//  Essential Romanian cultural data models for CloudKit synchronization
//  Sprint 2 - Week 5 implementation focused on cultural preservation
//

import Foundation
import CloudKit

// MARK: - Essential CloudKit Protocol

/// Protocol for objects that can be synchronized with CloudKit
protocol CloudKitSyncable {
    var cloudKitIdentifier: String { get }
    
    func populateCloudKitRecord(_ record: CKRecord) async throws
    static func fromCloudKitRecord(_ record: CKRecord) async throws -> Self
}

// MARK: - Essential Data Models for Sprint 2

/// Simple player profile for CloudKit sync (Sprint 2 focus)
struct PlayerProfile: Codable, Identifiable {
    let id = UUID()
    let playerID: String
    var displayName: String
    var totalGamesPlayed: Int
    var totalWins: Int
    var currentStreak: Int
    var longestStreak: Int
    var romanianCulturalLevel: Int
    let createdDate: Date
    var lastPlayedDate: Date
    
    init(playerID: String, displayName: String) {
        self.playerID = playerID
        self.displayName = displayName
        self.totalGamesPlayed = 0
        self.totalWins = 0
        self.currentStreak = 0
        self.longestStreak = 0
        self.romanianCulturalLevel = 1
        self.createdDate = Date()
        self.lastPlayedDate = Date()
    }
}

extension PlayerProfile: CloudKitSyncable {
    var cloudKitIdentifier: String {
        return "PlayerProfile_\(playerID)"
    }
    
    func populateCloudKitRecord(_ record: CKRecord) async throws {
        record["playerID"] = playerID as CKRecordValue
        record["displayName"] = displayName as CKRecordValue
        record["totalGamesPlayed"] = totalGamesPlayed as CKRecordValue
        record["totalWins"] = totalWins as CKRecordValue
        record["currentStreak"] = currentStreak as CKRecordValue
        record["longestStreak"] = longestStreak as CKRecordValue
        record["romanianCulturalLevel"] = romanianCulturalLevel as CKRecordValue
        record["createdDate"] = createdDate as CKRecordValue
        record["lastPlayedDate"] = lastPlayedDate as CKRecordValue
    }
    
    static func fromCloudKitRecord(_ record: CKRecord) async throws -> PlayerProfile {
        guard let playerID = record["playerID"] as? String,
              let displayName = record["displayName"] as? String,
              let totalGamesPlayed = record["totalGamesPlayed"] as? Int,
              let totalWins = record["totalWins"] as? Int,
              let currentStreak = record["currentStreak"] as? Int,
              let longestStreak = record["longestStreak"] as? Int,
              let romanianCulturalLevel = record["romanianCulturalLevel"] as? Int,
              let createdDate = record["createdDate"] as? Date,
              let lastPlayedDate = record["lastPlayedDate"] as? Date else {
            throw CloudKitError.recordFetchFailed(NSError(domain: "Invalid PlayerProfile record", code: 0))
        }
        
        var profile = PlayerProfile(playerID: playerID, displayName: displayName)
        profile.totalGamesPlayed = totalGamesPlayed
        profile.totalWins = totalWins
        profile.currentStreak = currentStreak
        profile.longestStreak = longestStreak
        profile.romanianCulturalLevel = romanianCulturalLevel
        profile.lastPlayedDate = lastPlayedDate
        
        return profile
    }
}

/// Essential game record for CloudKit sync
struct GameRecord: Codable, Identifiable {
    let id = UUID()
    let gameID: UUID
    let playerID: String
    let opponentType: OpponentType
    let aiDifficulty: AIDifficulty?
    let gameResult: GameResultType
    let finalScore: Int
    let gameDuration: TimeInterval
    let culturalMomentsTriggered: [String]
    let timestamp: Date
    
    init(gameID: UUID = UUID(), playerID: String, opponentType: OpponentType, gameResult: GameResultType, finalScore: Int, gameDuration: TimeInterval) {
        self.gameID = gameID
        self.playerID = playerID
        self.opponentType = opponentType
        self.aiDifficulty = nil
        self.gameResult = gameResult
        self.finalScore = finalScore
        self.gameDuration = gameDuration
        self.culturalMomentsTriggered = []
        self.timestamp = Date()
    }
}

extension GameRecord: CloudKitSyncable {
    var cloudKitIdentifier: String {
        return "GameRecord_\(gameID.uuidString)"
    }
    
    func populateCloudKitRecord(_ record: CKRecord) async throws {
        record["gameID"] = gameID.uuidString as CKRecordValue
        record["playerID"] = playerID as CKRecordValue
        record["opponentType"] = opponentType.rawValue as CKRecordValue
        record["gameResult"] = gameResult.rawValue as CKRecordValue
        record["finalScore"] = finalScore as CKRecordValue
        record["gameDuration"] = gameDuration as CKRecordValue
        record["timestamp"] = timestamp as CKRecordValue
    }
    
    static func fromCloudKitRecord(_ record: CKRecord) async throws -> GameRecord {
        guard let gameIDString = record["gameID"] as? String,
              let gameID = UUID(uuidString: gameIDString),
              let playerID = record["playerID"] as? String,
              let opponentTypeRaw = record["opponentType"] as? String,
              let gameResultRaw = record["gameResult"] as? String,
              let finalScore = record["finalScore"] as? Int,
              let gameDuration = record["gameDuration"] as? TimeInterval,
              let timestamp = record["timestamp"] as? Date else {
            throw CloudKitError.recordFetchFailed(NSError(domain: "Invalid GameRecord", code: 0))
        }
        
        let opponentType = OpponentType(rawValue: opponentTypeRaw) ?? .ai
        let gameResult = GameResultType(rawValue: gameResultRaw) ?? .loss
        
        var gameRecord = GameRecord(
            gameID: gameID,
            playerID: playerID,
            opponentType: opponentType,
            gameResult: gameResult,
            finalScore: finalScore,
            gameDuration: gameDuration
        )
        
        return gameRecord
    }
}

/// Romanian cultural progress tracking
struct RomanianCulturalProgress: Codable, Identifiable {
    let id = UUID()
    let progressID: UUID
    let playerID: String
    var storiesRead: Int
    var folkMusicListened: [String]
    var gameRulesLearned: [String]
    var culturalQuizScore: Int
    var heritageEngagementLevel: Float
    var authenticityScore: Float
    var lastUpdated: Date
    
    init(playerID: String) {
        self.progressID = UUID()
        self.playerID = playerID
        self.storiesRead = 0
        self.folkMusicListened = []
        self.gameRulesLearned = []
        self.culturalQuizScore = 0
        self.heritageEngagementLevel = 0.0
        self.authenticityScore = 0.0
        self.lastUpdated = Date()
    }
}

extension RomanianCulturalProgress: CloudKitSyncable {
    var cloudKitIdentifier: String {
        return "CulturalProgress_\(playerID)"
    }
    
    func populateCloudKitRecord(_ record: CKRecord) async throws {
        let encoder = JSONEncoder()
        
        record["progressID"] = progressID.uuidString as CKRecordValue
        record["playerID"] = playerID as CKRecordValue
        record["storiesRead"] = storiesRead as CKRecordValue
        record["folkMusicData"] = try encoder.encode(folkMusicListened) as CKRecordValue
        record["gameRulesData"] = try encoder.encode(gameRulesLearned) as CKRecordValue
        record["culturalQuizScore"] = culturalQuizScore as CKRecordValue
        record["heritageEngagementLevel"] = heritageEngagementLevel as CKRecordValue
        record["authenticityScore"] = authenticityScore as CKRecordValue
        record["lastUpdated"] = lastUpdated as CKRecordValue
    }
    
    static func fromCloudKitRecord(_ record: CKRecord) async throws -> RomanianCulturalProgress {
        let decoder = JSONDecoder()
        
        guard let progressIDString = record["progressID"] as? String,
              let progressID = UUID(uuidString: progressIDString),
              let playerID = record["playerID"] as? String,
              let storiesRead = record["storiesRead"] as? Int,
              let folkMusicData = record["folkMusicData"] as? Data,
              let gameRulesData = record["gameRulesData"] as? Data,
              let culturalQuizScore = record["culturalQuizScore"] as? Int,
              let heritageEngagementLevel = record["heritageEngagementLevel"] as? Float,
              let authenticityScore = record["authenticityScore"] as? Float,
              let lastUpdated = record["lastUpdated"] as? Date else {
            throw CloudKitError.recordFetchFailed(NSError(domain: "Invalid CulturalProgress", code: 0))
        }
        
        let folkMusic = try decoder.decode([String].self, from: folkMusicData)
        let gameRules = try decoder.decode([String].self, from: gameRulesData)
        
        var progress = RomanianCulturalProgress(playerID: playerID)
        progress.progressID = progressID
        progress.storiesRead = storiesRead
        progress.folkMusicListened = folkMusic
        progress.gameRulesLearned = gameRules
        progress.culturalQuizScore = culturalQuizScore
        progress.heritageEngagementLevel = heritageEngagementLevel
        progress.authenticityScore = authenticityScore
        progress.lastUpdated = lastUpdated
        
        return progress
    }
}

// MARK: - Supporting Enums

enum OpponentType: String, Codable, CaseIterable {
    case ai = "ai"
    case human = "human"
}

enum GameResultType: String, Codable, CaseIterable {
    case win = "win"
    case loss = "loss"
    case draw = "draw"
}

