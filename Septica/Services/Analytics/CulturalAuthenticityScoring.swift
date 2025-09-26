import Foundation
import Combine

@MainActor
final class CulturalAuthenticityScoring: ObservableObject {
    @Published private(set) var latestScore: Float = 0.5

    func score(for gameState: GameState) -> Float {
        guard !gameState.players.isEmpty else { return latestScore }
        let traditionalWins = gameState.players.filter { $0.score >= 10 }.count
        latestScore = min(1.0, Float(traditionalWins) / max(1.0, Float(gameState.players.count)))
        return latestScore
    }
}
