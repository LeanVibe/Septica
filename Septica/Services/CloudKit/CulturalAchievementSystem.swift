import Foundation
import Combine

@MainActor
final class CulturalAchievementSystem: ObservableObject {
    struct CulturalAchievement: Identifiable {
        let id = UUID()
        let title: String
        let description: String
        var progress: Float
    }

    @Published private(set) var availableAchievements: [CulturalAchievement] = [
        CulturalAchievement(title: "Heritage Explorer", description: "Learn three folklore facts", progress: 0.0),
        CulturalAchievement(title: "Septica Scholar", description: "Win five educational matches", progress: 0.0)
    ]

    @Published private(set) var unlockedAchievements: [CulturalAchievement] = []

    func markProgress(for achievementId: UUID, value: Float) {
        guard let index = availableAchievements.firstIndex(where: { $0.id == achievementId }) else { return }
        var updated = availableAchievements[index]
        updated.progress = min(1.0, max(0.0, value))
        availableAchievements[index] = updated

        if updated.progress >= 1.0 && !unlockedAchievements.contains(where: { $0.id == updated.id }) {
            unlockedAchievements.append(updated)
        }
    }
}
