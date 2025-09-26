import Foundation
import Combine
import os.log

@MainActor
final class PerformanceAnalyticsManager: ObservableObject {
    @Published private(set) var performanceScore: Float = 0.0

    private let logger = Logger(subsystem: "dev.leanvibe.game.Septica", category: "PerformanceAnalyticsManager")
    private let strategyAnalyzer: TraditionalStrategyAnalyzer

    init(strategyAnalyzer: TraditionalStrategyAnalyzer) {
        self.strategyAnalyzer = strategyAnalyzer
    }

    func recordGameFinished(_ result: GameResult) {
        if let winner = result.winnerId,
           strategyAnalyzer.currentAnalysis?.move.playerId == winner {
            performanceScore = min(1.0, performanceScore + 0.1)
        } else {
            performanceScore = max(0.0, performanceScore - 0.05)
        }
        logger.info("Updated performance score to \(self.performanceScore, privacy: .public)")
    }
}
