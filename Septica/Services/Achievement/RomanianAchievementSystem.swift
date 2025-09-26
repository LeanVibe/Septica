import Foundation
import Combine

/// Lightweight facade that previously exposed a very rich achievement catalogue.
/// The simplified build only exposes the minimal information needed by the UI layer.
@MainActor
final class RomanianAchievementSystem: ObservableObject {
    @Published private(set) var achievements: [RomanianAchievement]

    private let manager: RomanianCulturalAchievementManager

    init(manager: RomanianCulturalAchievementManager? = nil) {
        let resolvedManager = manager ?? RomanianCulturalAchievementManager()
        self.manager = resolvedManager
        self.achievements = resolvedManager.available
    }

    func progress(for achievement: RomanianAchievement) -> AchievementProgress? {
        manager.progress(for: achievement.id)
    }

    func registerGameWon() {
        manager.recordGameEvent(.gameWon)
    }

    func registerGameStarted() {
        manager.recordGameEvent(.gameStarted)
    }

    func registerCulturalQuiz() {
        manager.recordCulturalEvent(.culturalQuizCompleted)
    }
}
