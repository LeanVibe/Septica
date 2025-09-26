import Foundation

@MainActor
final class AchievementCelebrationManager {
    private let celebrationSystem: AchievementCelebrationSystem

    init(celebrationSystem: AchievementCelebrationSystem? = nil) {
        self.celebrationSystem = celebrationSystem ?? AchievementCelebrationSystem()
    }

    func celebrate(_ achievement: RomanianAchievement) {
        celebrationSystem.queueCelebration(for: achievement)
    }
}
