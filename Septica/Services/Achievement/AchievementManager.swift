import Foundation
import Combine

@MainActor
final class AchievementManager: ObservableObject {
    static let shared = AchievementManager()

    @Published private(set) var achievements: [RomanianAchievement] = [
        RomanianAchievement(
            titleKey: "First Victory",
            descriptionKey: "Win your first game",
            category: .gameplay,
            difficulty: .bronze,
            targetValue: 1,
            experiencePoints: 50,
            culturalPoints: 10,
            badge: AchievementBadge(iconName: "star.fill", tint: .bronze)
        )
    ]

    private init() {}

    func isAchievementUnlocked(_ id: UUID) -> Bool { false }

    func getAchievementProgress(_ id: UUID) -> Float { 0 }

    func recordGameEvent(_ event: GameEventType) {}
}
