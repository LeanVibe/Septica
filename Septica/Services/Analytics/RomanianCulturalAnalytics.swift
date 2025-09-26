import Foundation
import Combine
import os.log

@MainActor
final class RomanianCulturalAnalytics: ObservableObject {
    @Published private(set) var culturalAuthenticityScore: Float = 0.5
    @Published private(set) var culturalMoments: [String] = []

    private let logger = Logger(subsystem: "dev.leanvibe.game.Septica", category: "RomanianCulturalAnalytics")

    func startGameAnalysis(gameState: GameState) {
        culturalAuthenticityScore = 0.5
        culturalMoments.removeAll()
        logger.info("Started cultural analytics for game \(gameState.id.uuidString, privacy: .public)")
    }

    func analyzeMove(_ move: GameMove, gameState: GameState) {
        if move.card.value == 7 {
            culturalMoments.append("Seven played")
            culturalAuthenticityScore = min(1.0, culturalAuthenticityScore + 0.05)
        }
    }

    func endGameAnalysis(gameResult: GameResult) {
        if gameResult.isTie {
            culturalAuthenticityScore *= 0.9
        }
    }
}
