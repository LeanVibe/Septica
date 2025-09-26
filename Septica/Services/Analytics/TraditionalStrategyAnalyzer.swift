import Foundation
import Combine
import os.log

/// Lightweight stub that keeps existing analytics integrations responsive without reintroducing
/// the massive ML-driven implementation that previously caused cascading build failures.
@MainActor
final class TraditionalStrategyAnalyzer: ObservableObject {
    private let logger = Logger(subsystem: "dev.leanvibe.game.Septica", category: "TraditionalStrategyAnalyzer")
    private let patternRecognition: TraditionalPatternRecognition
    private let culturalLibrary: RomanianCulturalContentLibrary

    @Published var currentAnalysis: StrategyAnalysis?
    @Published var traditionalEffectiveness: Float = 0
    @Published var modernEffectiveness: Float = 0
    @Published var hybridOpportunities: [HybridStrategy] = []
    @Published var strategicRecommendations: [StrategyRecommendation] = []
    @Published var detectedStrategies: [DetectedStrategy] = []
    @Published var strategyConfidence: Float = 0
    @Published var culturalAuthenticity: Float = 0
    @Published var adaptationSuggestions: [AdaptationSuggestion] = []

    private var recentAnalyses: [StrategyAnalysis] = []
    private let maxStoredAnalyses = 10

    init(patternRecognition: TraditionalPatternRecognition, culturalLibrary: RomanianCulturalContentLibrary) {
        self.patternRecognition = patternRecognition
        self.culturalLibrary = culturalLibrary
    }

    /// Produces a lightweight analysis that mirrors the data dependencies used by the rest of the app.
    func analyzeGameMove(_ move: GameMove, gameState: GameState) async -> StrategyAnalysis {
        let startTime = Date()
        let patterns = patternRecognition.analyzeMove(move, gameState: gameState)
        let detected = patterns.map { DetectedStrategy(patternName: $0.name, confidence: 0.6) }

        let baseConfidence: Float = detected.isEmpty ? 0.25 : 0.65
        let traditionalScore = clamp(baseConfidence + Float(gameState.tableCards.count) * 0.02)
        let modernScore = clamp(1.0 - traditionalScore * 0.5)
        let culturalScore = clamp(baseConfidence + (culturalLibrary.randomFolkloreFact().isEmpty ? 0 : 0.05))

        let hybrid = detected.isEmpty ? [] : [HybridStrategy(name: "Balanced Traditional Play", confidence: baseConfidence)]
        let recommendations = buildRecommendations(from: detected, culturalScore: culturalScore)

        let analysis = StrategyAnalysis(
            move: move,
            detectedStrategies: detected,
            traditionalEffectiveness: traditionalScore,
            modernEffectiveness: modernScore,
            hybridOpportunities: hybrid,
            recommendations: recommendations,
            culturalAuthenticity: culturalScore,
            confidence: baseConfidence,
            analysisTime: Date().timeIntervalSince(startTime)
        )

        await updatePublishedState(with: analysis)
        logger.debug("Generated simplified strategy analysis with confidence \(analysis.confidence, privacy: .public)")
        return analysis
    }

    /// Adjusts running aggregates after a game completes.
    func updateLearningModels(with gameResult: GameResult, analysis: StrategyAnalysis) async {
        guard let winner = gameResult.winnerId else { return }
        if winner == analysis.move.playerId {
            strategyConfidence = clamp(strategyConfidence + 0.05)
            traditionalEffectiveness = clamp(traditionalEffectiveness + 0.05)
        } else {
            strategyConfidence = clamp(strategyConfidence - 0.03)
        }
    }

    /// Exposes a condensed report consumed by higher-level analytics managers.
    func getAnalysisReport() -> StrategyAnalysisReport {
        StrategyAnalysisReport(
            generatedAt: Date(),
            recentAnalyses: recentAnalyses,
            confidence: strategyConfidence,
            culturalAuthenticity: culturalAuthenticity,
            recommendations: strategicRecommendations
        )
    }

    private func updatePublishedState(with analysis: StrategyAnalysis) async {
        currentAnalysis = analysis
        detectedStrategies = analysis.detectedStrategies
        strategicRecommendations = analysis.recommendations
        hybridOpportunities = analysis.hybridOpportunities
        traditionalEffectiveness = analysis.traditionalEffectiveness
        modernEffectiveness = analysis.modernEffectiveness
        strategyConfidence = analysis.confidence
        culturalAuthenticity = analysis.culturalAuthenticity
        adaptationSuggestions = analysis.recommendations.map {
            AdaptationSuggestion(title: $0.title, rationale: $0.details)
        }

        recentAnalyses.append(analysis)
        if recentAnalyses.count > maxStoredAnalyses {
            recentAnalyses.removeFirst(recentAnalyses.count - maxStoredAnalyses)
        }
    }

    private func buildRecommendations(from detected: [DetectedStrategy], culturalScore: Float) -> [StrategyRecommendation] {
        guard let primary = detected.first else {
            return [
                StrategyRecommendation(
                    title: "Observe Table State",
                    details: "Gather more data before committing to a specific Romanian pattern."
                )
            ]
        }

        let authenticityDetail = culturalScore > 0.5
            ? "Continue leveraging \(primary.patternName) to reinforce traditional flow."
            : "Consider reinforcing cultural cues before relying on \(primary.patternName)."

        return [
            StrategyRecommendation(
                title: "Lean Into \(primary.patternName)",
                details: authenticityDetail
            )
        ]
    }

    private func clamp(_ value: Float) -> Float {
        min(max(value, 0), 1)
    }
}

// MARK: - Support Types

struct StrategyAnalysis {
    let move: GameMove
    let detectedStrategies: [DetectedStrategy]
    let traditionalEffectiveness: Float
    let modernEffectiveness: Float
    let hybridOpportunities: [HybridStrategy]
    let recommendations: [StrategyRecommendation]
    let culturalAuthenticity: Float
    let confidence: Float
    let analysisTime: TimeInterval
}

struct DetectedStrategy: Hashable {
    let patternName: String
    let confidence: Float
}

struct HybridStrategy: Hashable {
    let name: String
    let confidence: Float
}

struct StrategyRecommendation: Hashable {
    let title: String
    let details: String
}

struct AdaptationSuggestion: Hashable {
    let title: String
    let rationale: String
}

struct StrategyAnalysisReport {
    let generatedAt: Date
    let recentAnalyses: [StrategyAnalysis]
    let confidence: Float
    let culturalAuthenticity: Float
    let recommendations: [StrategyRecommendation]
}
