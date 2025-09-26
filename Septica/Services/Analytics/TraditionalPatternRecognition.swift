import Foundation

protocol TraditionalPatternRecognitionDelegate: AnyObject {
    func didDetectPattern(_ pattern: TraditionalPatternRecognition.TraditionalPattern)
}

/// Simplified pattern recognition engine that exposes the hooks expected by the analytics layer
/// without depending on heavy ML models or unavailable data sources.
final class TraditionalPatternRecognition {
    struct TraditionalPattern: Identifiable, Hashable {
        enum PatternType: CaseIterable {
            case perfectTraditionalOpening
            case masterLevelStrategy
            case heritagePreservation
            case regionalMastery
        }

        enum CulturalOrigin: Equatable, Hashable {
            case traditional
            case modern
            case regional(RomanianRegion)
        }

        let id = UUID()
        let name: String
        let type: PatternType
        let culturalOrigin: CulturalOrigin
        let confidence: Float
    }

    weak var delegate: TraditionalPatternRecognitionDelegate?
    private var observedGameState: GameState?

    func startAnalysis(gameState: GameState) {
        observedGameState = gameState
    }

    func analyzeMove(_ move: GameMove, gameState: GameState) -> [TraditionalPattern] {
        var patterns: [TraditionalPattern] = []

        if move.card.value == 7 {
            patterns.append(
                TraditionalPattern(
                    name: "Seven Cutter",
                    type: .perfectTraditionalOpening,
                    culturalOrigin: .traditional,
                    confidence: 0.8
                )
            )
        }

        if move.card.value == 8 && move.tableCardsCount % 3 == 0 {
            patterns.append(
                TraditionalPattern(
                    name: "Rhythm Breaker",
                    type: .masterLevelStrategy,
                    culturalOrigin: .traditional,
                    confidence: 0.7
                )
            )
        }

        if move.card.value >= 10 {
            patterns.append(
                TraditionalPattern(
                    name: "Point Hunter",
                    type: .heritagePreservation,
                    culturalOrigin: .modern,
                    confidence: 0.5
                )
            )
        }

        if let region = inferredRegion(for: move.playerId, gameState: gameState) {
            patterns.append(
                TraditionalPattern(
                    name: "Regional Flair",
                    type: .regionalMastery,
                    culturalOrigin: .regional(region),
                    confidence: 0.4
                )
            )
        }

        patterns.forEach { delegate?.didDetectPattern($0) }
        return patterns
    }

    private func inferredRegion(for playerId: UUID, gameState: GameState) -> RomanianRegion? {
        guard let index = gameState.players.firstIndex(where: { $0.id == playerId }) else {
            return nil
        }

        switch index % 3 {
        case 0: return .moldova
        case 1: return .wallachia
        default: return .transylvania
        }
    }
}
