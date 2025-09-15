//
//  AchievementDataModels.swift
//  Septica
//
//  Created by Claude Code on 15/09/2025.
//

import Foundation
import CloudKit

// MARK: - Achievement Core Types

/// Represents an individual achievement in the Romanian cultural system
struct RomanianAchievement: Identifiable, Codable, Hashable {
    public let id: UUID
    public let type: AchievementType
    public let category: AchievementCategory
    public let difficulty: AchievementDifficulty
    public let culturalRegion: RomanianRegion?
    
    // Localized content
    public let titleKey: String
    public let descriptionKey: String
    public let culturalContextKey: String
    
    // Requirements
    public let requirements: [AchievementRequirement]
    public let targetValue: Int
    public let isSecret: Bool
    public let prerequisiteAchievements: [UUID]
    
    // Rewards
    public let experiencePoints: Int
    public let culturalKnowledgePoints: Int
    public let unlockableContent: [UnlockableContent]
    public let badge: AchievementBadge
    
    // Metadata
    public let createdAt: Date
    public let educationalContent: EducationalContent?
    
    public init(
        id: UUID = UUID(),
        type: AchievementType,
        category: AchievementCategory,
        difficulty: AchievementDifficulty,
        culturalRegion: RomanianRegion? = nil,
        titleKey: String,
        descriptionKey: String,
        culturalContextKey: String,
        requirements: [AchievementRequirement],
        targetValue: Int,
        isSecret: Bool = false,
        prerequisiteAchievements: [UUID] = [],
        experiencePoints: Int,
        culturalKnowledgePoints: Int,
        unlockableContent: [UnlockableContent] = [],
        badge: AchievementBadge,
        createdAt: Date = Date(),
        educationalContent: EducationalContent? = nil
    ) {
        self.id = id
        self.type = type
        self.category = category
        self.difficulty = difficulty
        self.culturalRegion = culturalRegion
        self.titleKey = titleKey
        self.descriptionKey = descriptionKey
        self.culturalContextKey = culturalContextKey
        self.requirements = requirements
        self.targetValue = targetValue
        self.isSecret = isSecret
        self.prerequisiteAchievements = prerequisiteAchievements
        self.experiencePoints = experiencePoints
        self.culturalKnowledgePoints = culturalKnowledgePoints
        self.unlockableContent = unlockableContent
        self.badge = badge
        self.createdAt = createdAt
        self.educationalContent = educationalContent
    }
}

// MARK: - Achievement Enums

enum AchievementType: String, Codable, CaseIterable {
    case gameplay = "gameplay"
    case cultural = "cultural"
    case educational = "educational"
    case social = "social"
    case strategic = "strategic"
    case heritage = "heritage"
    case community = "community"
    case seasonal = "seasonal"
}

enum AchievementCategory: String, Codable, CaseIterable {
    // Gameplay Categories
    case cardMastery = "card_mastery"
    case gameWins = "game_wins"
    case strategicPlay = "strategic_play"
    case perfectGames = "perfect_games"
    
    // Cultural Categories
    case folkloreLearning = "folklore_learning"
    case traditionalMusic = "traditional_music"
    case regionalHistory = "regional_history"
    case culturalPride = "cultural_pride"
    
    // Educational Categories
    case mathematicalThinking = "mathematical_thinking"
    case criticalThinking = "critical_thinking"
    case patternRecognition = "pattern_recognition"
    case problemSolving = "problem_solving"
    
    // Social Categories
    case friendlyPlay = "friendly_play"
    case mentorship = "mentorship"
    case communityParticipation = "community_participation"
    case culturalSharing = "cultural_sharing"
}

enum AchievementDifficulty: String, Codable, CaseIterable {
    case bronze = "bronze"
    case silver = "silver"
    case gold = "gold"
    case legendary = "legendary"
    
    public var experienceMultiplier: Double {
        switch self {
        case .bronze: return 1.0
        case .silver: return 1.5
        case .gold: return 2.0
        case .legendary: return 3.0
        }
    }
}

enum RomanianRegion: String, Codable, CaseIterable {
    case transylvania = "transylvania"
    case moldova = "moldova"
    case wallachia = "wallachia"
    case dobrudja = "dobrudja"
    case banat = "banat"
    case oltenia = "oltenia"
    case muntenia = "muntenia"
    case bucovina = "bucovina"
    
    public var localizedNameKey: String {
        return "region_\(rawValue)"
    }
    
    public var culturalColorScheme: (primary: String, secondary: String) {
        switch self {
        case .transylvania: return ("#8B0000", "#FFD700") // Dark red, gold
        case .moldova: return ("#000080", "#FFFFFF") // Navy blue, white
        case .wallachia: return ("#228B22", "#FFD700") // Forest green, gold
        case .dobrudja: return ("#4169E1", "#F0E68C") // Royal blue, khaki
        case .banat: return ("#8B4513", "#FFA500") // Saddle brown, orange
        case .oltenia: return ("#2E8B57", "#F5F5DC") // Sea green, beige
        case .muntenia: return ("#B22222", "#F0F8FF") // Fire brick, alice blue
        case .bucovina: return ("#4B0082", "#E6E6FA") // Indigo, lavender
        }
    }
}

// MARK: - Achievement Requirements

enum AchievementRequirement: Codable, Hashable {
    case gamesPlayed(count: Int)
    case gamesWon(count: Int)
    case perfectGames(count: Int)
    case cardsPlayed(count: Int)
    case specificCard(suit: Suit, value: Int, timesPlayed: Int)
    case winStreak(count: Int)
    case tournamentParticipation(count: Int)
    case tournamentWins(count: Int)
    case culturalQuizAnswered(count: Int)
    case culturalQuizPerfect(count: Int)
    case folktaleLearned(count: Int)
    case traditionExplored(count: Int)
    case communityInteraction(count: Int)
    case mentorshipProvided(count: Int)
    case seasonalEventParticipation(count: Int)
    case dailyPlayStreak(days: Int)
    case strategicMovesCorrect(count: Int)
    case mathematicalPuzzleSolved(count: Int)
    
    public var targetValue: Int {
        switch self {
        case .gamesPlayed(let count): return count
        case .gamesWon(let count): return count
        case .perfectGames(let count): return count
        case .cardsPlayed(let count): return count
        case .specificCard(_, _, let timesPlayed): return timesPlayed
        case .winStreak(let count): return count
        case .tournamentParticipation(let count): return count
        case .tournamentWins(let count): return count
        case .culturalQuizAnswered(let count): return count
        case .culturalQuizPerfect(let count): return count
        case .folktaleLearned(let count): return count
        case .traditionExplored(let count): return count
        case .communityInteraction(let count): return count
        case .mentorshipProvided(let count): return count
        case .seasonalEventParticipation(let count): return count
        case .dailyPlayStreak(let days): return days
        case .strategicMovesCorrect(let count): return count
        case .mathematicalPuzzleSolved(let count): return count
        }
    }
    
    public var descriptionKey: String {
        switch self {
        case .gamesPlayed: return "requirement_games_played"
        case .gamesWon: return "requirement_games_won"
        case .perfectGames: return "requirement_perfect_games"
        case .cardsPlayed: return "requirement_cards_played"
        case .specificCard: return "requirement_specific_card"
        case .winStreak: return "requirement_win_streak"
        case .tournamentParticipation: return "requirement_tournament_participation"
        case .tournamentWins: return "requirement_tournament_wins"
        case .culturalQuizAnswered: return "requirement_cultural_quiz_answered"
        case .culturalQuizPerfect: return "requirement_cultural_quiz_perfect"
        case .folktaleLearned: return "requirement_folktale_learned"
        case .traditionExplored: return "requirement_tradition_explored"
        case .communityInteraction: return "requirement_community_interaction"
        case .mentorshipProvided: return "requirement_mentorship_provided"
        case .seasonalEventParticipation: return "requirement_seasonal_event"
        case .dailyPlayStreak: return "requirement_daily_play_streak"
        case .strategicMovesCorrect: return "requirement_strategic_moves"
        case .mathematicalPuzzleSolved: return "requirement_mathematical_puzzle"
        }
    }
}

// MARK: - Achievement Progress

public struct AchievementProgress: Identifiable, Codable {
    public let id: UUID
    public let achievementId: UUID
    public let playerId: UUID
    public var currentValue: Int
    public var isCompleted: Bool
    public var completedAt: Date?
    public var lastUpdated: Date
    public var milestoneRewards: [MilestoneReward]
    
    public init(
        id: UUID = UUID(),
        achievementId: UUID,
        playerId: UUID,
        currentValue: Int = 0,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        lastUpdated: Date = Date(),
        milestoneRewards: [MilestoneReward] = []
    ) {
        self.id = id
        self.achievementId = achievementId
        self.playerId = playerId
        self.currentValue = currentValue
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.lastUpdated = lastUpdated
        self.milestoneRewards = milestoneRewards
    }
    
    public var progressPercentage: Double {
        guard let achievement = AchievementRegistry.shared.getAchievement(id: achievementId) else {
            return 0.0
        }
        return min(Double(currentValue) / Double(achievement.targetValue), 1.0)
    }
    
    public mutating func updateProgress(_ newValue: Int) {
        currentValue = max(currentValue, newValue)
        lastUpdated = Date()
        
        if let achievement = AchievementRegistry.shared.getAchievement(id: achievementId),
           currentValue >= achievement.targetValue && !isCompleted {
            isCompleted = true
            completedAt = Date()
        }
    }
}

// MARK: - Achievement Rewards

public struct AchievementBadge: Codable, Hashable {
    public let iconName: String
    public let colorScheme: BadgeColorScheme
    public let animation: BadgeAnimation
    public let culturalSymbol: String?
    
    public init(
        iconName: String,
        colorScheme: BadgeColorScheme,
        animation: BadgeAnimation = .none,
        culturalSymbol: String? = nil
    ) {
        self.iconName = iconName
        self.colorScheme = colorScheme
        self.animation = animation
        self.culturalSymbol = culturalSymbol
    }
}

public enum BadgeColorScheme: String, Codable {
    case bronze = "bronze"
    case silver = "silver"
    case gold = "gold"
    case legendary = "legendary"
    case cultural = "cultural"
    case seasonal = "seasonal"
}

public enum BadgeAnimation: String, Codable {
    case none = "none"
    case glow = "glow"
    case sparkle = "sparkle"
    case pulse = "pulse"
    case rotate = "rotate"
    case float = "float"
}

public enum UnlockableContent: Codable, Hashable {
    case cardBack(name: String)
    case gameTheme(name: String)
    case folkStory(id: String)
    case musicTrack(id: String)
    case culturalFact(id: String)
    case avatar(id: String)
    case title(name: String)
    case decorator(id: String)
    
    public var contentType: String {
        switch self {
        case .cardBack: return "card_back"
        case .gameTheme: return "game_theme"
        case .folkStory: return "folk_story"
        case .musicTrack: return "music_track"
        case .culturalFact: return "cultural_fact"
        case .avatar: return "avatar"
        case .title: return "title"
        case .decorator: return "decorator"
        }
    }
    
    public var identifier: String {
        switch self {
        case .cardBack(let name): return name
        case .gameTheme(let name): return name
        case .folkStory(let id): return id
        case .musicTrack(let id): return id
        case .culturalFact(let id): return id
        case .avatar(let id): return id
        case .title(let name): return name
        case .decorator(let id): return id
        }
    }
}

public struct MilestoneReward: Codable, Hashable {
    public let percentage: Int // 25, 50, 75, 100
    public let rewardType: MilestoneRewardType
    public let isClaimed: Bool
    public let claimedAt: Date?
    
    public init(
        percentage: Int,
        rewardType: MilestoneRewardType,
        isClaimed: Bool = false,
        claimedAt: Date? = nil
    ) {
        self.percentage = percentage
        self.rewardType = rewardType
        self.isClaimed = isClaimed
        self.claimedAt = claimedAt
    }
}

public enum MilestoneRewardType: Codable, Hashable {
    case experienceBonus(points: Int)
    case culturalFact(id: String)
    case encouragementMessage(key: String)
    case progressCelebration(type: String)
}

// MARK: - Educational Content

struct EducationalContent: Codable, Hashable {
    let id: UUID
    let type: EducationalContentType
    let titleKey: String
    let contentKey: String
    let culturalRegion: RomanianRegion?
    let ageAppropriate: AgeGroup
    let mediaAssets: [MediaAsset]
    let interactiveElements: [InteractiveElement]
    
    init(
        id: UUID = UUID(),
        type: EducationalContentType,
        titleKey: String,
        contentKey: String,
        culturalRegion: RomanianRegion? = nil,
        ageAppropriate: AgeGroup,
        mediaAssets: [MediaAsset] = [],
        interactiveElements: [InteractiveElement] = []
    ) {
        self.id = id
        self.type = type
        self.titleKey = titleKey
        self.contentKey = contentKey
        self.culturalRegion = culturalRegion
        self.ageAppropriate = ageAppropriate
        self.mediaAssets = mediaAssets
        self.interactiveElements = interactiveElements
    }
}

enum EducationalContentType: String, Codable {
    case folklore = "folklore"
    case history = "history"
    case tradition = "tradition"
    case music = "music"
    case geography = "geography"
    case language = "language"
    case mathematics = "mathematics"
    case strategy = "strategy"
}

enum AgeGroup: String, Codable {
    case ages6to8 = "ages_6_to_8"
    case ages9to12 = "ages_9_to_12"
    case allAges = "all_ages"
}

struct MediaAsset: Codable, Hashable {
    let id: UUID
    let type: MediaAssetType
    let fileName: String
    let altTextKey: String?
    
    init(
        id: UUID = UUID(),
        type: MediaAssetType,
        fileName: String,
        altTextKey: String? = nil
    ) {
        self.id = id
        self.type = type
        self.fileName = fileName
        self.altTextKey = altTextKey
    }
}

enum MediaAssetType: String, Codable {
    case image = "image"
    case audio = "audio"
    case video = "video"
    case illustration = "illustration"
}

struct InteractiveElement: Codable, Hashable {
    let id: UUID
    let type: InteractiveElementType
    let data: [String: String]
    
    init(
        id: UUID = UUID(),
        type: InteractiveElementType,
        data: [String: String] = [:]
    ) {
        self.id = id
        self.type = type
        self.data = data
    }
}

enum InteractiveElementType: String, Codable {
    case quiz = "quiz"
    case memoryGame = "memory_game"
    case dragAndDrop = "drag_and_drop"
    case audioPlayer = "audio_player"
    case imageGallery = "image_gallery"
    case storytelling = "storytelling"
}

// MARK: - CloudKit Support

extension RomanianAchievement {
    public var cloudKitRecord: CKRecord {
        let record = CKRecord(recordType: "RomanianAchievement", recordID: CKRecord.ID(recordName: id.uuidString))
        
        record["type"] = type.rawValue
        record["category"] = category.rawValue
        record["difficulty"] = difficulty.rawValue
        record["culturalRegion"] = culturalRegion?.rawValue
        record["titleKey"] = titleKey
        record["descriptionKey"] = descriptionKey
        record["culturalContextKey"] = culturalContextKey
        record["targetValue"] = targetValue
        record["isSecret"] = isSecret
        record["experiencePoints"] = experiencePoints
        record["culturalKnowledgePoints"] = culturalKnowledgePoints
        record["createdAt"] = createdAt
        
        return record
    }
    
    public init?(from record: CKRecord) {
        guard let typeString = record["type"] as? String,
              let type = AchievementType(rawValue: typeString),
              let categoryString = record["category"] as? String,
              let category = AchievementCategory(rawValue: categoryString),
              let difficultyString = record["difficulty"] as? String,
              let difficulty = AchievementDifficulty(rawValue: difficultyString),
              let titleKey = record["titleKey"] as? String,
              let descriptionKey = record["descriptionKey"] as? String,
              let culturalContextKey = record["culturalContextKey"] as? String,
              let targetValue = record["targetValue"] as? Int,
              let isSecret = record["isSecret"] as? Bool,
              let experiencePoints = record["experiencePoints"] as? Int,
              let culturalKnowledgePoints = record["culturalKnowledgePoints"] as? Int,
              let createdAt = record["createdAt"] as? Date else {
            return nil
        }
        
        let culturalRegion = (record["culturalRegion"] as? String).flatMap(RomanianRegion.init(rawValue:))
        
        self.init(
            id: UUID(uuidString: record.recordID.recordName) ?? UUID(),
            type: type,
            category: category,
            difficulty: difficulty,
            culturalRegion: culturalRegion,
            titleKey: titleKey,
            descriptionKey: descriptionKey,
            culturalContextKey: culturalContextKey,
            requirements: [], // Will be loaded separately
            targetValue: targetValue,
            isSecret: isSecret,
            prerequisiteAchievements: [],
            experiencePoints: experiencePoints,
            culturalKnowledgePoints: culturalKnowledgePoints,
            unlockableContent: [],
            badge: AchievementBadge(iconName: "star", colorScheme: .bronze),
            createdAt: createdAt,
            educationalContent: nil
        )
    }
}

extension AchievementProgress {
    public var cloudKitRecord: CKRecord {
        let record = CKRecord(recordType: "AchievementProgress", recordID: CKRecord.ID(recordName: id.uuidString))
        
        record["achievementId"] = achievementId.uuidString
        record["playerId"] = playerId.uuidString
        record["currentValue"] = currentValue
        record["isCompleted"] = isCompleted
        record["completedAt"] = completedAt
        record["lastUpdated"] = lastUpdated
        
        return record
    }
    
    public init?(from record: CKRecord) {
        guard let achievementIdString = record["achievementId"] as? String,
              let achievementId = UUID(uuidString: achievementIdString),
              let playerIdString = record["playerId"] as? String,
              let playerId = UUID(uuidString: playerIdString),
              let currentValue = record["currentValue"] as? Int,
              let isCompleted = record["isCompleted"] as? Bool,
              let lastUpdated = record["lastUpdated"] as? Date else {
            return nil
        }
        
        let completedAt = record["completedAt"] as? Date
        
        self.init(
            id: UUID(uuidString: record.recordID.recordName) ?? UUID(),
            achievementId: achievementId,
            playerId: playerId,
            currentValue: currentValue,
            isCompleted: isCompleted,
            completedAt: completedAt,
            lastUpdated: lastUpdated
        )
    }
}

// MARK: - Achievement Registry

class AchievementRegistry {
    static let shared = AchievementRegistry()
    
    private var achievements: [UUID: RomanianAchievement] = [:]
    private var achievementsByCategory: [AchievementCategory: [RomanianAchievement]] = [:]
    private var achievementsByRegion: [RomanianRegion: [RomanianAchievement]] = [:]
    
    private init() {
        loadDefaultAchievements()
    }
    
    func getAchievement(id: UUID) -> RomanianAchievement? {
        return achievements[id]
    }
    
    func getAchievements(for category: AchievementCategory) -> [RomanianAchievement] {
        return achievementsByCategory[category] ?? []
    }
    
    func getAchievements(for region: RomanianRegion) -> [RomanianAchievement] {
        return achievementsByRegion[region] ?? []
    }
    
    func getAllAchievements() -> [RomanianAchievement] {
        return Array(achievements.values)
    }
    
    private func loadDefaultAchievements() {
        // Implementation will be loaded from data files or created programmatically
        // This is where the 50+ predefined achievements would be registered
    }
    
    func registerAchievement(_ achievement: RomanianAchievement) {
        achievements[achievement.id] = achievement
        
        if achievementsByCategory[achievement.category] == nil {
            achievementsByCategory[achievement.category] = []
        }
        achievementsByCategory[achievement.category]?.append(achievement)
        
        if let region = achievement.culturalRegion {
            if achievementsByRegion[region] == nil {
                achievementsByRegion[region] = []
            }
            achievementsByRegion[region]?.append(achievement)
        }
    }
}