import Foundation
import Combine

@MainActor
final class RomanianCulturalAchievementManager: ObservableObject {
    @Published private(set) var unlocked: Set<UUID> = []
    @Published private(set) var available: [RomanianAchievement]
    @Published private(set) var progress: [UUID: AchievementProgress] = [:]
    @Published private(set) var totalExperience: Int = 0
    @Published private(set) var totalCulturalPoints: Int = 0

    private let registry: AchievementRegistry
    private let playerId: UUID

    init(registry: AchievementRegistry = .shared, playerId: UUID = UUID()) {
        self.registry = registry
        self.playerId = playerId

        if registry.all().isEmpty {
            Self.bootstrapSampleAchievements(into: registry)
        }
        self.available = registry.all()
        for achievement in available {
            progress[achievement.id] = AchievementProgress(
                achievementId: achievement.id,
                playerId: playerId,
                targetValue: achievement.targetValue
            )
        }
    }

    func recordGameEvent(_ event: GameEventType) {
        switch event {
        case .gameStarted:
            updateProgress(for: .gamesPlayed, amount: 1)
        case .gameWon:
            updateProgress(for: .gamesWon, amount: 1)
        }
    }

    func recordCulturalEvent(_ event: AchievementCulturalEventType) {
        switch event {
        case .folkloreStoryRead:
            updateProgress(for: .folkloreStories, amount: 1)
        case .culturalQuizCompleted:
            updateProgress(for: .culturalQuizzes, amount: 1)
        }
    }

    func progress(for achievementId: UUID) -> AchievementProgress? {
        progress[achievementId]
    }

    private func updateProgress(for requirement: AchievementRequirementID, amount: Int) {
        for achievement in available where achievementRequires(achievement, requirement: requirement) {
            guard var tracker = progress[achievement.id] else { continue }
            tracker.addProgress(amount)
            progress[achievement.id] = tracker

            if tracker.isCompleted {
                unlock(achievement)
            }
        }
    }

    private func unlock(_ achievement: RomanianAchievement) {
        guard !unlocked.contains(achievement.id) else { return }
        unlocked.insert(achievement.id)
        totalExperience += achievement.experiencePoints
        totalCulturalPoints += achievement.culturalPoints
    }

    private func achievementRequires(_ achievement: RomanianAchievement, requirement: AchievementRequirementID) -> Bool {
        switch achievement.category {
        case .gameplay:
            return requirement == .gamesPlayed || requirement == .gamesWon
        case .cultural, .cardMastery, .folkloreLearning:
            return requirement == .folkloreStories
        case .educational:
            return requirement == .culturalQuizzes
        default:
            return false
        }
    }

    static func bootstrapSampleAchievements(into registry: AchievementRegistry) {
        registry.reset()

        let starter = RomanianAchievement(
            titleKey: "achievement.starter.title",
            descriptionKey: "achievement.starter.description",
            category: .gameplay,
            difficulty: .bronze,
            targetValue: 1,
            experiencePoints: 10,
            culturalPoints: 5,
            badge: AchievementBadge(iconName: "star.fill", tint: .bronze)
        )
        let winner = RomanianAchievement(
            titleKey: "achievement.winner.title",
            descriptionKey: "achievement.winner.description",
            category: .gameplay,
            difficulty: .silver,
            targetValue: 5,
            experiencePoints: 50,
            culturalPoints: 20,
            badge: AchievementBadge(iconName: "crown.fill", tint: .silver),
            rewards: [.title("Septica Champion")]
        )
        let folklore = RomanianAchievement(
            titleKey: "achievement.folklore.title",
            descriptionKey: "achievement.folklore.description",
            category: .cultural,
            difficulty: .bronze,
            targetValue: 3,
            experiencePoints: 25,
            culturalPoints: 40,
            badge: AchievementBadge(iconName: "book.fill", tint: .cultural)
        )

        [starter, winner, folklore].forEach { registry.register($0) }
    }
}
