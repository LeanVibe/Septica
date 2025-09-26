import Foundation
import Combine
import os.log

@MainActor
final class GameStateAnalyticsIntegration: ObservableObject {
    private let logger = Logger(subsystem: "dev.leanvibe.game.Septica", category: "GameStateAnalyticsIntegration")
    private let performanceAnalytics: PerformanceAnalyticsManager

    init(performanceAnalytics: PerformanceAnalyticsManager) {
        self.performanceAnalytics = performanceAnalytics
    }

    func startSession(for gameState: GameState) {
        logger.info("Analytics session started for game \(gameState.id.uuidString, privacy: .public)")
    }

    func recordMove(_ move: GameMove, gameState: GameState) {
        logger.debug("Recorded move from player \(move.playerId.uuidString, privacy: .public)")
    }

    func endSession(with result: GameResult) {
        performanceAnalytics.recordGameFinished(result)
    }
}
