//
//  TraditionalPatternRecognition.swift
//  Septica
//
//  Traditional Romanian Septica Pattern Recognition System
//  AI-powered analysis of traditional vs modern gameplay patterns with cultural significance
//

import Foundation
import GameplayKit
import os.log

/// Protocol for pattern recognition delegate
protocol TraditionalPatternRecognitionDelegate: AnyObject {
    func didDetectPattern(_ pattern: TraditionalPattern)
}

/// AI-powered traditional pattern recognition engine
class TraditionalPatternRecognition {
    
    // MARK: - Dependencies
    
    private let logger = Logger(subsystem: "dev.leanvibe.game.Septica", category: "TraditionalPatternRecognition")
    weak var delegate: TraditionalPatternRecognitionDelegate?
    
    // MARK: - Pattern Recognition State
    
    private var gameHistory: [GameMove] = []
    private var patternCache: [String: TraditionalPattern] = [:]
    private var culturalContext: CulturalContext?
    
    // MARK: - Romanian Traditional Patterns
    
    private let traditionalPatterns: [TraditionalPatternTemplate] = [
        // 1. Classic Seven Wild Usage
        TraditionalPatternTemplate(
            id: "seven_wild_cut",
            name: "Tăierea cu Septul",
            description: "Using 7 to cut opponent's high-value card",
            culturalOrigin: .traditional,
            recognitionRules: [
                .cardValueCondition(7),
                .opponentCardValueHigher,
                .contextualTiming(.defensive)
            ],
            authenticityWeight: 0.9,
            difficultyLevel: .intermediate
        ),
        
        // 2. Strategic Eight Timing
        TraditionalPatternTemplate(
            id: "eight_timing_rule",
            name: "Regula Optului",
            description: "Playing 8 when card count modulo 3 equals 0",
            culturalOrigin: .traditional,
            recognitionRules: [
                .cardValueCondition(8),
                .tableCardCountRule(.modulo3Zero),
                .contextualTiming(.offensive)
            ],
            authenticityWeight: 0.85,
            difficultyLevel: .advanced
        ),
        
        // 3. Point Card Hunting
        TraditionalPatternTemplate(
            id: "point_hunting",
            name: "Vânătoarea Punctelor",
            description: "Strategic focus on high-point cards",
            culturalOrigin: .traditional,
            recognitionRules: [
                .pointCardFocus,
                .sequentialHighValuePlays,
                .contextualTiming(.aggressive)
            ],
            authenticityWeight: 0.8,
            difficultyLevel: .intermediate
        ),
        
        // 4. Moldovan Patience Strategy
        TraditionalPatternTemplate(
            id: "moldovan_patience",
            name: "Răbdarea Moldovenească",
            description: "Patient, defensive play style from Moldova region",
            culturalOrigin: .regional(.moldovan),
            recognitionRules: [
                .defensiveCardHolding,
                .lowValueCardSequence,
                .contextualTiming(.patient)
            ],
            authenticityWeight: 0.75,
            difficultyLevel: .beginner
        ),
        
        // 5. Transylvanian Direct Approach
        TraditionalPatternTemplate(
            id: "transylvanian_direct",
            name: "Directețea Ardeleană",
            description: "Direct, efficient play style from Transylvania",
            culturalOrigin: .regional(.transylvanian),
            recognitionRules: [
                .directPlayPattern,
                .efficientCardUsage,
                .contextualTiming(.efficient)
            ],
            authenticityWeight: 0.8,
            difficultyLevel: .intermediate
        ),
        
        // 6. Wallachian Rhythm Disruption
        TraditionalPatternTemplate(
            id: "wallachian_rhythm",
            name: "Ruperea Ritmului Muntean",
            description: "Dynamic rhythm disruption from Wallachia",
            culturalOrigin: .regional(.wallachian),
            recognitionRules: [
                .rhythmDisruptionPattern,
                .dynamicPlayStyle,
                .contextualTiming(.disruptive)
            ],
            authenticityWeight: 0.9,
            difficultyLevel: .advanced
        ),
        
        // 7. Perfect Traditional Opening
        TraditionalPatternTemplate(
            id: "perfect_traditional_opening",
            name: "Deschiderea Tradițională Perfectă",
            description: "Classical Romanian opening sequence",
            culturalOrigin: .traditional,
            recognitionRules: [
                .openingSequenceTraditional,
                .properCardOrder,
                .contextualTiming(.opening)
            ],
            authenticityWeight: 1.0,
            difficultyLevel: .master
        ),
        
        // 8. Master Level Strategy
        TraditionalPatternTemplate(
            id: "master_level_strategy",
            name: "Strategia de Maestru",
            description: "Advanced techniques used by Romanian masters",
            culturalOrigin: .masterLevel,
            recognitionRules: [
                .complexCardSequencing,
                .multiTurnStrategy,
                .contextualTiming(.masterful)
            ],
            authenticityWeight: 1.0,
            difficultyLevel: .master
        )
    ]
    
    // MARK: - Pattern Analysis
    
    func startAnalysis(gameState: GameState) {
        gameHistory.removeAll()
        patternCache.removeAll()
        
        // Initialize cultural context
        culturalContext = CulturalContext(
            gameState: gameState,
            currentTurn: 0,
            playerProfiles: createPlayerProfiles(gameState.players)
        )
        
        logger.info("Started traditional pattern analysis")
    }
    
    func analyzeMove(_ move: GameMove, gameState: GameState) -> [TraditionalPattern] {
        gameHistory.append(move)
        
        var detectedPatterns: [TraditionalPattern] = []
        
        // Update cultural context
        updateCulturalContext(move: move, gameState: gameState)
        
        // Analyze current move against all pattern templates
        for template in traditionalPatterns {
            if let pattern = evaluatePattern(template: template, move: move, gameState: gameState) {
                detectedPatterns.append(pattern)
                
                // Cache the pattern
                patternCache[template.id] = pattern
                
                // Notify delegate
                delegate?.didDetectPattern(pattern)
                
                logger.info("Detected traditional pattern: \(template.name)")
            }
        }
        
        // Analyze complex multi-move patterns
        let multiMovePatterns = analyzeMultiMovePatterns(gameState: gameState)
        detectedPatterns.append(contentsOf: multiMovePatterns)
        
        return detectedPatterns
    }
    
    // MARK: - Pattern Evaluation
    
    private func evaluatePattern(template: TraditionalPatternTemplate, move: GameMove, gameState: GameState) -> TraditionalPattern? {
        guard let context = culturalContext else { return nil }
        
        var rulesSatisfied = 0
        let totalRules = template.recognitionRules.count
        
        for rule in template.recognitionRules {
            if evaluateRule(rule, move: move, gameState: gameState, context: context) {
                rulesSatisfied += 1
            }
        }
        
        // Pattern is detected if at least 80% of rules are satisfied
        let satisfactionRate = Float(rulesSatisfied) / Float(totalRules)
        if satisfactionRate >= 0.8 {
            return TraditionalPattern(
                type: mapTemplateToType(template),
                template: template,
                move: move,
                timestamp: Date(),
                culturalOrigin: template.culturalOrigin,
                authenticityWeight: template.authenticityWeight * satisfactionRate,
                confidence: satisfactionRate,
                culturalContext: generateCulturalContext(template, move: move)
            )
        }
        
        return nil
    }
    
    private func evaluateRule(_ rule: PatternRecognitionRule, move: GameMove, gameState: GameState, context: CulturalContext) -> Bool {
        switch rule {
        case .cardValueCondition(let value):
            return move.card.value == value
            
        case .opponentCardValueHigher:
            guard let topCard = gameState.topTableCard else { return false }
            return topCard.value > move.card.value
            
        case .contextualTiming(let timing):
            return evaluateContextualTiming(timing, move: move, gameState: gameState, context: context)
            
        case .tableCardCountRule(let rule):
            return evaluateTableCardCountRule(rule, gameState: gameState)
            
        case .pointCardFocus:
            return isPointCard(move.card)
            
        case .sequentialHighValuePlays:
            return isSequentialHighValuePlay(move: move)
            
        case .defensiveCardHolding:
            return isDefensiveCardHolding(move: move, gameState: gameState, context: context)
            
        case .lowValueCardSequence:
            return isLowValueCardSequence(move: move)
            
        case .directPlayPattern:
            return isDirectPlayPattern(move: move, gameState: gameState)
            
        case .efficientCardUsage:
            return isEfficientCardUsage(move: move, gameState: gameState)
            
        case .rhythmDisruptionPattern:
            return isRhythmDisruptionPattern(move: move, gameState: gameState, context: context)
            
        case .dynamicPlayStyle:
            return isDynamicPlayStyle(move: move, context: context)
            
        case .openingSequenceTraditional:
            return isTraditionalOpeningSequence(move: move, gameState: gameState)
            
        case .properCardOrder:
            return isProperCardOrder(move: move, gameState: gameState)
            
        case .complexCardSequencing:
            return isComplexCardSequencing(move: move, context: context)
            
        case .multiTurnStrategy:
            return isMultiTurnStrategy(move: move, context: context)
        }
    }
    
    // MARK: - Rule Evaluation Implementations
    
    private func evaluateContextualTiming(_ timing: ContextualTiming, move: GameMove, gameState: GameState, context: CulturalContext) -> Bool {
        switch timing {
        case .defensive:
            return context.currentThreatLevel > 0.6
        case .offensive:
            return context.currentThreatLevel < 0.4
        case .aggressive:
            return context.currentThreatLevel < 0.3 && isPointCard(move.card)
        case .patient:
            return gameState.trickNumber < 3 && move.card.value < 8
        case .efficient:
            return calculateMoveEfficiency(move: move, gameState: gameState) > 0.7
        case .disruptive:
            return context.opponentPlayPattern == .predictable
        case .opening:
            return gameState.trickNumber == 1
        case .masterful:
            return calculateMoveComplexity(move: move, gameState: gameState) > 0.8
        }
    }
    
    private func evaluateTableCardCountRule(_ rule: TableCardCountRule, gameState: GameState) -> Bool {
        let count = gameState.tableCards.count
        switch rule {
        case .modulo3Zero:
            return count % 3 == 0
        case .evenCount:
            return count % 2 == 0
        case .lessThan(let threshold):
            return count < threshold
        case .greaterThan(let threshold):
            return count > threshold
        }
    }
    
    private func isPointCard(_ card: Card) -> Bool {
        // High-value cards in Romanian Septica
        return card.value >= 10 || card.value == 1 // Ace, Jack, Queen, King
    }
    
    private func isSequentialHighValuePlay(move: GameMove) -> Bool {
        let recentMoves = gameHistory.suffix(3)
        let highValueMoves = recentMoves.filter { isPointCard($0.card) }
        return highValueMoves.count >= 2 && isPointCard(move.card)
    }
    
    private func isDefensiveCardHolding(move: GameMove, gameState: GameState, context: CulturalContext) -> Bool {
        // Playing low-value cards while holding high-value cards
        guard let currentPlayer = gameState.currentPlayer else { return false }
        
        let hasHighValueCards = currentPlayer.hand.contains { isPointCard($0) }
        let playingLowValue = move.card.value < 8
        
        return hasHighValueCards && playingLowValue && context.currentThreatLevel > 0.5
    }
    
    private func isLowValueCardSequence(move: GameMove) -> Bool {
        let recentMoves = gameHistory.suffix(3)
        let lowValueMoves = recentMoves.filter { $0.card.value < 7 }
        return lowValueMoves.count >= 2 && move.card.value < 7
    }
    
    private func isDirectPlayPattern(move: GameMove, gameState: GameState) -> Bool {
        // Direct, efficient play without complex strategy
        return calculateMoveEfficiency(move: move, gameState: gameState) > 0.8 &&
               calculateMoveComplexity(move: move, gameState: gameState) < 0.4
    }
    
    private func isEfficientCardUsage(move: GameMove, gameState: GameState) -> Bool {
        return calculateMoveEfficiency(move: move, gameState: gameState) > 0.75
    }
    
    private func isRhythmDisruptionPattern(move: GameMove, gameState: GameState, context: CulturalContext) -> Bool {
        // Playing unexpected cards that break opponent's rhythm
        return context.opponentPlayPattern == .predictable &&
               !isPredictableMove(move: move, gameState: gameState)
    }
    
    private func isDynamicPlayStyle(move: GameMove, context: CulturalContext) -> Bool {
        let recentMoves = gameHistory.suffix(5)
        let moveTypes = recentMoves.map { classifyMoveType($0) }
        let uniqueTypes = Set(moveTypes).count
        return uniqueTypes >= 3 // Variety in move types
    }
    
    private func isTraditionalOpeningSequence(move: GameMove, gameState: GameState) -> Bool {
        // Traditional Romanian opening: Start with medium-value cards
        return gameState.trickNumber == 1 && (5...8).contains(move.card.value)
    }
    
    private func isProperCardOrder(move: GameMove, gameState: GameState) -> Bool {
        // Traditional card ordering principles
        if gameState.trickNumber == 1 {
            return (5...8).contains(move.card.value)
        } else if gameState.trickNumber <= 3 {
            return move.card.value < 10
        }
        return true
    }
    
    private func isComplexCardSequencing(move: GameMove, context: CulturalContext) -> Bool {
        return calculateMoveComplexity(move: move, gameState: context.gameState) > 0.7
    }
    
    private func isMultiTurnStrategy(move: GameMove, context: CulturalContext) -> Bool {
        // Analyze if this move is part of a multi-turn strategy
        let recentMoves = gameHistory.suffix(6)
        return analyzeMultiTurnPattern(moves: Array(recentMoves), currentMove: move)
    }
    
    // MARK: - Complex Pattern Analysis
    
    private func analyzeMultiMovePatterns(gameState: GameState) -> [TraditionalPattern] {
        var patterns: [TraditionalPattern] = []
        
        // Analyze Romanian "Hora" pattern (circular strategy)
        if let horaPattern = detectHoraPattern() {
            patterns.append(horaPattern)
        }
        
        // Analyze "Brâu" pattern (linear aggressive strategy)
        if let brauPattern = detectBrauPattern() {
            patterns.append(brauPattern)
        }
        
        // Analyze regional combination patterns
        patterns.append(contentsOf: detectRegionalCombinationPatterns())
        
        return patterns
    }
    
    private func detectHoraPattern() -> TraditionalPattern? {
        // Romanian "Hora" dance pattern in card play - circular, rhythmic
        let recentMoves = gameHistory.suffix(8)
        if recentMoves.count >= 6 {
            let rhythm = analyzePlayRhythm(Array(recentMoves))
            if rhythm.isCircular && rhythm.consistency > 0.8 {
                return createPatternFromTemplate(
                    id: "hora_pattern",
                    name: "Modelul Horei",
                    authenticityWeight: 0.95
                )
            }
        }
        return nil
    }
    
    private func detectBrauPattern() -> TraditionalPattern? {
        // Romanian "Brâu" dance pattern - linear, aggressive progression
        let recentMoves = gameHistory.suffix(6)
        if recentMoves.count >= 4 {
            let progression = analyzeProgressivePattern(Array(recentMoves))
            if progression.isLinear && progression.intensity > 0.75 {
                return createPatternFromTemplate(
                    id: "brau_pattern",
                    name: "Modelul Brâului",
                    authenticityWeight: 0.9
                )
            }
        }
        return nil
    }
    
    private func detectRegionalCombinationPatterns() -> [TraditionalPattern] {
        var patterns: [TraditionalPattern] = []
        
        // Detect combinations of regional patterns
        let moldovanPatterns = patternCache.values.filter { 
            if case .regional(.moldovan) = $0.culturalOrigin { return true }
            return false
        }
        
        let transylvanianPatterns = patternCache.values.filter {
            if case .regional(.transylvanian) = $0.culturalOrigin { return true }
            return false
        }
        
        // Regional mastery pattern
        if moldovanPatterns.count >= 2 && transylvanianPatterns.count >= 2 {
            let regionalMastery = createPatternFromTemplate(
                id: "regional_mastery",
                name: "Măiestria Regională",
                authenticityWeight: 1.0
            )
            patterns.append(regionalMastery)
        }
        
        return patterns
    }
    
    // MARK: - Helper Methods
    
    private func createPlayerProfiles(_ players: [Player]) -> [UUID: PlayerProfile] {
        var profiles: [UUID: PlayerProfile] = [:]
        for player in players {
            profiles[player.id] = PlayerProfile(
                playerId: player.id,
                isAI: player is AIPlayer,
                playStyle: .unknown,
                culturalAlignment: 0.5
            )
        }
        return profiles
    }
    
    private func updateCulturalContext(move: GameMove, gameState: GameState) {
        guard var context = culturalContext else { return }
        
        context.currentTurn += 1
        context.gameState = gameState
        
        // Update threat level
        context.currentThreatLevel = calculateThreatLevel(gameState: gameState)
        
        // Update opponent play pattern
        context.opponentPlayPattern = analyzeOpponentPattern(gameState: gameState)
        
        culturalContext = context
    }
    
    private func calculateThreatLevel(gameState: GameState) -> Float {
        guard let currentPlayer = gameState.currentPlayer,
              let opponent = gameState.players.first(where: { $0.id != currentPlayer.id }) else {
            return 0.5
        }
        
        let scoreDifference = opponent.score - currentPlayer.score
        let handSizeDifference = opponent.hand.count - currentPlayer.hand.count
        
        return Float(scoreDifference + handSizeDifference * 2) / 20.0 + 0.5
    }
    
    private func analyzeOpponentPattern(gameState: GameState) -> OpponentPlayPattern {
        let recentMoves = gameHistory.suffix(6)
        let moveVariability = calculateMoveVariability(Array(recentMoves))
        
        if moveVariability < 0.3 {
            return .predictable
        } else if moveVariability > 0.7 {
            return .chaotic
        } else {
            return .adaptive
        }
    }
    
    private func calculateMoveEfficiency(move: GameMove, gameState: GameState) -> Float {
        // Calculate how efficient this move is in the current context
        let cardValue = Float(move.card.value)
        let contextualValue = calculateContextualValue(move: move, gameState: gameState)
        
        return (cardValue + contextualValue) / 20.0 // Normalize to 0-1
    }
    
    private func calculateMoveComplexity(move: GameMove, gameState: GameState) -> Float {
        // Calculate strategic complexity of the move
        var complexity: Float = 0.0
        
        // Wild card usage adds complexity
        if move.card.value == 7 {
            complexity += 0.3
        }
        
        // Special timing adds complexity
        if move.card.value == 8 && gameState.tableCards.count % 3 == 0 {
            complexity += 0.4
        }
        
        // Counter-play adds complexity
        if isCounterPlay(move: move, gameState: gameState) {
            complexity += 0.3
        }
        
        return min(1.0, complexity)
    }
    
    private func calculateContextualValue(move: GameMove, gameState: GameState) -> Float {
        var value: Float = 0.0
        
        // Value increases if it wins the trick
        if canWinTrick(move: move, gameState: gameState) {
            value += 5.0
        }
        
        // Value increases for strategic timing
        if isStrategicTiming(move: move, gameState: gameState) {
            value += 3.0
        }
        
        return value
    }
    
    private func isPredictableMove(move: GameMove, gameState: GameState) -> Bool {
        // Determine if this move follows predictable patterns
        guard let topCard = gameState.topTableCard else { return false }
        
        // Following suit is predictable
        if move.card.suit == topCard.suit {
            return true
        }
        
        // Playing highest card is predictable
        guard let currentPlayer = gameState.currentPlayer else { return false }
        let highestCard = currentPlayer.hand.max { $0.value < $1.value }
        
        return move.card == highestCard
    }
    
    private func classifyMoveType(_ move: GameMove) -> MoveType {
        if move.card.value == 7 {
            return .wildCard
        } else if move.card.value >= 10 {
            return .highValue
        } else if move.card.value <= 4 {
            return .lowValue
        } else {
            return .medium
        }
    }
    
    private func analyzeMultiTurnPattern(moves: [GameMove], currentMove: GameMove) -> Bool {
        // Analyze if moves form a coherent multi-turn strategy
        if moves.count < 3 { return false }
        
        let values = moves.map { $0.card.value }
        
        // Check for ascending pattern
        let isAscending = zip(values, values.dropFirst()).allSatisfy { $0 < $1 }
        
        // Check for alternating pattern
        let isAlternating = zip(values, values.dropFirst()).allSatisfy { abs($0 - $1) > 3 }
        
        return isAscending || isAlternating
    }
    
    private func analyzePlayRhythm(_ moves: [GameMove]) -> RhythmPattern {
        let timings = moves.map { $0.timestamp }
        let intervals = zip(timings, timings.dropFirst()).map { $1.timeIntervalSince($0) }
        
        let avgInterval = intervals.reduce(0, +) / Double(intervals.count)
        let variance = intervals.map { pow($0 - avgInterval, 2) }.reduce(0, +) / Double(intervals.count)
        
        let consistency = 1.0 - sqrt(variance) / avgInterval
        let isCircular = intervals.count >= 4 && 
                        abs(intervals.first! - intervals.last!) < avgInterval * 0.3
        
        return RhythmPattern(
            consistency: Float(consistency),
            isCircular: isCircular,
            averageInterval: avgInterval
        )
    }
    
    private func analyzeProgressivePattern(_ moves: [GameMove]) -> ProgressivePattern {
        let values = moves.map { Float($0.card.value) }
        
        let differences = zip(values, values.dropFirst()).map { $1 - $0 }
        let isLinear = differences.allSatisfy { $0 > 0 } || differences.allSatisfy { $0 < 0 }
        
        let intensity = differences.map { abs($0) }.reduce(0, +) / Float(differences.count)
        
        return ProgressivePattern(
            isLinear: isLinear,
            intensity: intensity / 13.0 // Normalize by max card value difference
        )
    }
    
    private func calculateMoveVariability(_ moves: [GameMove]) -> Float {
        guard moves.count > 1 else { return 0.5 }
        
        let values = moves.map { Float($0.card.value) }
        let mean = values.reduce(0, +) / Float(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Float(values.count)
        
        return sqrt(variance) / 13.0 // Normalize by max possible standard deviation
    }
    
    private func canWinTrick(move: GameMove, gameState: GameState) -> Bool {
        // Simplified trick winning logic
        guard let topCard = gameState.topTableCard else { return true }
        
        if move.card.value == 7 { return true } // 7 is wild
        if move.card.suit == topCard.suit && move.card.value > topCard.value { return true }
        
        return false
    }
    
    private func isStrategicTiming(move: GameMove, gameState: GameState) -> Bool {
        // Check if this move has strategic timing
        if move.card.value == 8 && gameState.tableCards.count % 3 == 0 { return true }
        if move.card.value == 7 && gameState.trickNumber > 3 { return true }
        
        return false
    }
    
    private func isCounterPlay(move: GameMove, gameState: GameState) -> Bool {
        // Check if this move counters opponent's strategy
        guard let topCard = gameState.topTableCard else { return false }
        
        return move.card.value == 7 && topCard.value >= 10 // Counter high-value with 7
    }
    
    private func mapTemplateToType(_ template: TraditionalPatternTemplate) -> TraditionalPatternType {
        switch template.id {
        case "seven_wild_cut": return .sevenWildUsage
        case "eight_timing_rule": return .eightTimingRule
        case "point_hunting": return .pointCardFocus
        case "perfect_traditional_opening": return .perfectTraditionalOpening
        case "master_level_strategy": return .masterLevelStrategy
        default: return .defensivePattern
        }
    }
    
    private func generateCulturalContext(_ template: TraditionalPatternTemplate, move: GameMove) -> String {
        return "\(template.description) - Card played: \(move.card.displayName)"
    }
    
    private func createPatternFromTemplate(id: String, name: String, authenticityWeight: Float) -> TraditionalPattern {
        return TraditionalPattern(
            type: .culturalCombination,
            template: nil,
            move: gameHistory.last!,
            timestamp: Date(),
            culturalOrigin: .traditional,
            authenticityWeight: authenticityWeight,
            confidence: 0.9,
            culturalContext: name
        )
    }
}

// MARK: - Supporting Data Structures

struct TraditionalPattern {
    let type: TraditionalPatternType
    let template: TraditionalPatternTemplate?
    let move: GameMove
    let timestamp: Date
    let culturalOrigin: CulturalOrigin
    let authenticityWeight: Float
    let confidence: Float
    let culturalContext: String
}

enum TraditionalPatternType {
    case sevenWildUsage
    case eightTimingRule
    case pointCardFocus
    case defensivePattern
    case rhythmDisruption
    case perfectTraditionalOpening
    case masterLevelStrategy
    case culturalCombination
}

struct TraditionalPatternTemplate {
    let id: String
    let name: String
    let description: String
    let culturalOrigin: CulturalOrigin
    let recognitionRules: [PatternRecognitionRule]
    let authenticityWeight: Float
    let difficultyLevel: PatternDifficulty
}

enum PatternRecognitionRule {
    case cardValueCondition(Int)
    case opponentCardValueHigher
    case contextualTiming(ContextualTiming)
    case tableCardCountRule(TableCardCountRule)
    case pointCardFocus
    case sequentialHighValuePlays
    case defensiveCardHolding
    case lowValueCardSequence
    case directPlayPattern
    case efficientCardUsage
    case rhythmDisruptionPattern
    case dynamicPlayStyle
    case openingSequenceTraditional
    case properCardOrder
    case complexCardSequencing
    case multiTurnStrategy
}

enum ContextualTiming {
    case defensive
    case offensive
    case aggressive
    case patient
    case efficient
    case disruptive
    case opening
    case masterful
}

enum TableCardCountRule {
    case modulo3Zero
    case evenCount
    case lessThan(Int)
    case greaterThan(Int)
}

enum PatternDifficulty {
    case beginner
    case intermediate
    case advanced
    case master
}

struct CulturalContext {
    var gameState: GameState
    var currentTurn: Int
    var playerProfiles: [UUID: PlayerProfile]
    var currentThreatLevel: Float = 0.5
    var opponentPlayPattern: OpponentPlayPattern = .unknown
}

struct PlayerProfile {
    let playerId: UUID
    let isAI: Bool
    var playStyle: PlayStyle
    var culturalAlignment: Float
}

enum PlayStyle {
    case aggressive
    case defensive
    case strategic
    case traditional
    case modern
    case unknown
}

enum OpponentPlayPattern {
    case predictable
    case adaptive
    case chaotic
    case unknown
}

enum MoveType {
    case wildCard
    case highValue
    case medium
    case lowValue
}

struct RhythmPattern {
    let consistency: Float
    let isCircular: Bool
    let averageInterval: TimeInterval
}

struct ProgressivePattern {
    let isLinear: Bool
    let intensity: Float
}

// Supporting enums from previous files
enum CulturalOrigin {
    case traditional
    case regional(RomanianRegion)
    case masterLevel
    case modern
}

enum RomanianRegion {
    case moldovan
    case transylvanian
    case wallachian
    case dobrudjan
    case banat
}

struct TraditionalStrategy {
    let id: String
    let name: String
    let description: String
    let culturalOrigin: CulturalOrigin
    let effectiveness: Float
    let culturalSignificance: String
    let recognitionPattern: TraditionalPatternType
}

struct ModernStrategy {
    let id: String
    let name: String
    let description: String
    let effectiveness: Float
    let modernizationLevel: Float
}

struct HybridPattern {
    let traditionalElement: TraditionalStrategy
    let modernElement: ModernStrategy
    let hybridEffectiveness: Float
    let culturalPreservation: Float
}

struct CulturalAnalyticsData {
    var totalGamesAnalyzed: Int = 0
    var averageCulturalScore: Float = 0.0
    var regionalStyleDistribution: [RomanianRegion: Int] = [:]
    var strategyUsageStats: [TraditionalStrategy: Int] = [:]
    var culturalMilestones: [CulturalMilestone] = []
    var totalCulturalExperience: Int = 0
    var currentCulturalLevel: Int = 1
    var previousCulturalScore: Float = 0.0
    
    mutating func addGameAnalytics(_ analytics: GameCulturalAnalytics) {
        totalGamesAnalyzed += 1
        
        // Update average cultural score
        let totalScore = averageCulturalScore * Float(totalGamesAnalyzed - 1) + analytics.finalCulturalScore
        averageCulturalScore = totalScore / Float(totalGamesAnalyzed)
        
        previousCulturalScore = analytics.finalCulturalScore
    }
    
    mutating func addRegionalUsage(_ region: RomanianRegion) {
        regionalStyleDistribution[region, default: 0] += 1
    }
    
    func getCurrentGameCount() -> Int {
        return totalGamesAnalyzed
    }
    
    func getSuccessRate(for strategy: TraditionalStrategy) -> Float {
        // Simplified success rate calculation
        let usage = strategyUsageStats[strategy] ?? 0
        return Float(usage) / Float(max(1, totalGamesAnalyzed)) * strategy.effectiveness
    }
}

class CulturalPerformanceMonitor {
    private var metrics: [String: Any] = [:]
    
    func recordMetric(_ key: String, value: Any) {
        metrics[key] = value
    }
    
    func getMetrics() -> [String: Any] {
        return metrics
    }
}