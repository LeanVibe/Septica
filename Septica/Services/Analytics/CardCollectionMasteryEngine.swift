import Foundation
import Combine


@MainActor
final class CardCollectionMasteryEngine: ObservableObject {
    @Published private(set) var masteryScore: Float = 0.0

    private let achievementManager: RomanianCulturalAchievementManager

    init(achievementManager: RomanianCulturalAchievementManager, strategyAnalyzer: RomanianStrategyAnalyzer) {
        self.achievementManager = achievementManager
    }

    func updateAfterGameWin() {
        masteryScore = min(1.0, masteryScore + 0.05)
        achievementManager.recordGameEvent(.gameWon)
    }
}
