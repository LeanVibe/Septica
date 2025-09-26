import Foundation

/// High level achievement descriptor used by the simplified achievement pipeline.
struct RomanianAchievement: Identifiable, Hashable, Codable {
    let id: UUID
    let titleKey: String
    let descriptionKey: String
    let category: AchievementCategory
    let difficulty: AchievementDifficulty
    let targetValue: Int
    let experiencePoints: Int
    let culturalPoints: Int
    let badge: AchievementBadge
    let rewards: [UnlockableContent]

    init(
        id: UUID = UUID(),
        titleKey: String,
        descriptionKey: String,
        category: AchievementCategory,
        difficulty: AchievementDifficulty,
        targetValue: Int,
        experiencePoints: Int,
        culturalPoints: Int,
        badge: AchievementBadge,
        rewards: [UnlockableContent] = []
    ) {
        self.id = id
        self.titleKey = titleKey
        self.descriptionKey = descriptionKey
        self.category = category
        self.difficulty = difficulty
        self.targetValue = targetValue
        self.experiencePoints = experiencePoints
        self.culturalPoints = culturalPoints
        self.badge = badge
        self.rewards = rewards
    }
}

enum AchievementCategory: String, CaseIterable, Codable {
    case gameplay
    case cultural
    case educational
    case cardMastery
    case folkloreLearning
}

enum AchievementDifficulty: String, CaseIterable, Codable {
    case bronze
    case silver
    case gold
    case legendary
}

struct AchievementRequirement: Hashable, Codable {
    let identifier: AchievementRequirementID
    let amount: Int

    init(_ identifier: AchievementRequirementID, amount: Int) {
        self.identifier = identifier
        self.amount = amount
    }
}

enum AchievementRequirementID: String, Codable, CaseIterable {
    case gamesPlayed
    case gamesWon
    case culturalQuizzes
    case folkloreStories
}

struct AchievementBadge: Hashable, Codable {
    let iconName: String
    let tint: AchievementBadgeTint

    init(iconName: String, tint: AchievementBadgeTint) {
        self.iconName = iconName
        self.tint = tint
    }
}

enum AchievementBadgeTint: String, Codable {
    case bronze
    case silver
    case gold
    case cultural
}

enum UnlockableContent: Hashable, Codable {
    case title(String)
    case avatar(String)
    case cardBack(String)
}

struct AchievementProgress: Identifiable, Codable {
    let id: UUID
    let achievementId: UUID
    let playerId: UUID
    private(set) var currentValue: Int
    let targetValue: Int

    var isCompleted: Bool {
        currentValue >= targetValue
    }

    init(achievementId: UUID, playerId: UUID, targetValue: Int) {
        self.id = UUID()
        self.achievementId = achievementId
        self.playerId = playerId
        self.currentValue = 0
        self.targetValue = targetValue
    }

    mutating func addProgress(_ value: Int) {
        currentValue = min(targetValue, currentValue + max(0, value))
    }
}

/// Lightweight registry used by the manager and tests.
final class AchievementRegistry {
    static let shared = AchievementRegistry()

    private var achievements: [RomanianAchievement] = []
    private var achievementsByCategory: [AchievementCategory: [RomanianAchievement]] = [:]

    private init() {}

    func register(_ achievement: RomanianAchievement) {
        achievements.append(achievement)
        achievementsByCategory[achievement.category, default: []].append(achievement)
    }

    func all() -> [RomanianAchievement] {
        achievements
    }

    func achievements(for category: AchievementCategory) -> [RomanianAchievement] {
        achievementsByCategory[category] ?? []
    }

    func achievement(id: UUID) -> RomanianAchievement? {
        achievements.first { $0.id == id }
    }

    func reset() {
        achievements.removeAll()
        achievementsByCategory.removeAll()
    }
}

/// Simple event types consumed by the simplified manager.
enum GameEventType {
    case gameStarted
    case gameWon
}

enum AchievementCulturalEventType {
    case folkloreStoryRead
    case culturalQuizCompleted
}
