import Foundation
import Combine

@MainActor
final class AchievementCelebrationSystem: ObservableObject {
    struct CelebrationEvent: Identifiable {
        let id = UUID()
        let achievement: RomanianAchievement
    }

    @Published private(set) var recentCelebrations: [CelebrationEvent] = []

    func queueCelebration(for achievement: RomanianAchievement) {
        recentCelebrations.append(CelebrationEvent(achievement: achievement))
        if recentCelebrations.count > 3 {
            recentCelebrations.removeFirst(recentCelebrations.count - 3)
        }
    }
}
