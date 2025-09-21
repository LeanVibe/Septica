//
//  TraditionalGameplayMilestoneTracker.swift
//  Septica
//
//  Traditional Romanian Septica gameplay milestone detection and tracking
//  Recognizes authentic Romanian playing techniques and cultural patterns
//

import Foundation
import Combine
import SwiftUI

/// Tracks traditional Romanian Septica gameplay patterns and milestones
/// Monitors usage of authentic techniques and cultural engagement
@MainActor
class TraditionalGameplayMilestoneTracker: ObservableObject {
    
    // MARK: - Dependencies
    
    private let achievementManager: RomanianCulturalAchievementManager
    private let culturalAnalyzer: RomanianCulturalAnalyzer
    
    // MARK: - Published State
    
    @Published var currentMilestones: [TraditionalMilestone] = []
    @Published var recentMilestones: [TraditionalMilestone] = []
    @Published var traditionalTechniqueUsage: [String: TechniqueUsageStats] = [:]
    @Published var culturalAuthenticity: CulturalAuthenticityMetrics
    @Published var regionalStyleProgress: [RomanianRegion: RegionalStyleProgress] = [:]
    
    // MARK: - Tracking State
    
    private var gameSessionMilestones: [TraditionalMilestone] = []
    private var techniqueDetectionBuffer: [GameAction] = []
    private var currentGameContext: GameContext?
    
    // MARK: - Cultural Technique Detection
    
    private let traditionalTechniques: [TraditionalTechnique] = [
        TraditionalTechnique(
            id: "septe_wild_mastery",
            name: "Măiestria Septelor Sălbatice",
            description: "Strategic use of 7 cards as wild cards",
            culturalSignificance: "Traditional Romanian technique where 7 cards can capture any trick",
            detectionCriteria: [
                .cardPlayedAsWild(value: 7),
                .strategicTiming,
                .highSuccessRate(threshold: 0.75)
            ],
            difficulty: .intermediate,
            region: .general
        ),
        TraditionalTechnique(
            id: "opt_timing_mastery",
            name: "Temporizarea Opturilor",
            description: "Perfect timing of 8 card plays when count modulo 3 equals 0",
            culturalSignificance: "Mathematical precision valued in Romanian card games",
            detectionCriteria: [
                .cardPlayed(value: 8),
                .mathematicalCondition(.countModuloThree),
                .consistentApplication
            ],
            difficulty: .advanced,
            region: .general
        ),
        TraditionalTechnique(
            id: "moldovan_patience",
            name: "Răbdarea Moldovenească",
            description: "Patient, analytical approach characteristic of Moldovan players",
            culturalSignificance: "Reflects the scholarly and contemplative nature of Moldovan culture",
            detectionCriteria: [
                .thoughtfulPacing,
                .lowRiskPlays,
                .consistentPerformance
            ],
            difficulty: .intermediate,
            region: .moldova
        ),
        TraditionalTechnique(
            id: "transylvanian_efficiency",
            name: "Eficiența Ardelenească",
            description: "Quick, decisive gameplay with minimal moves",
            culturalSignificance: "Represents the practical and efficient Transylvanian mindset",
            detectionCriteria: [
                .fastDecisionMaking,
                .highEfficiency,
                .minimalMistakes
            ],
            difficulty: .advanced,
            region: .transylvania
        ),
        TraditionalTechnique(
            id: "wallachian_rhythm",
            name: "Ritmul Muntenesc",
            description: "Dynamic, rhythmic card play with strategic variations",
            culturalSignificance: "Embodies the vibrant and adaptable spirit of Wallachia",
            detectionCriteria: [
                .rhythmicPlay,
                .strategicVariation,
                .adaptability
            ],
            difficulty: .expert,
            region: .wallachia
        ),
        TraditionalTechnique(
            id: "carpathian_wisdom",
            name: "Înțelepciunea Carpatină",
            description: "Deep strategic thinking with cultural pattern recognition",
            culturalSignificance: "Ancient wisdom of the Carpathian mountains applied to card strategy",
            detectionCriteria: [
                .deepStrategy,
                .patternRecognition,
                .culturalAwareness
            ],
            difficulty: .master,
            region: .general
        )
    ]
    
    // MARK: - Initialization
    
    init(achievementManager: RomanianCulturalAchievementManager, culturalAnalyzer: RomanianCulturalAnalyzer) {
        self.achievementManager = achievementManager
        self.culturalAnalyzer = culturalAnalyzer
        self.culturalAuthenticity = CulturalAuthenticityMetrics()
        
        initializeRegionalProgress()
        loadStoredProgress()
    }
    
    private func initializeRegionalProgress() {
        for region in RomanianRegion.allCases {
            regionalStyleProgress[region] = RegionalStyleProgress(region: region)
        }
    }
    
    // MARK: - Game Action Tracking
    
    func trackGameAction(_ action: GameAction, context: GameContext) {
        currentGameContext = context
        techniqueDetectionBuffer.append(action)
        
        // Keep buffer size manageable
        if techniqueDetectionBuffer.count > 50 {
            techniqueDetectionBuffer.removeFirst(10)
        }
        
        // Analyze for traditional techniques
        Task {
            await analyzeForTraditionalTechniques(action: action, context: context)
            await detectCulturalMilestones(action: action, context: context)
        }
    }
    
    func startGameSession(context: GameContext) {
        currentGameContext = context
        gameSessionMilestones.removeAll()
        techniqueDetectionBuffer.removeAll()
    }
    
    func endGameSession(result: GameResult) {
        guard let context = currentGameContext else { return }
        
        Task {
            await processGameSessionMilestones(result: result, context: context)
            await updateCulturalAuthenticity(result: result)
            await updateRegionalStyleProgress(result: result, context: context)
            
            // Save progress
            saveProgress()
        }
        
        currentGameContext = nil
    }
    
    // MARK: - Traditional Technique Analysis
    
    private func analyzeForTraditionalTechniques(action: GameAction, context: GameContext) async {
        for technique in traditionalTechniques {
            if await detectTechniqueUsage(technique: technique, action: action, context: context) {
                await recordTechniqueUsage(technique: technique, action: action, context: context)
            }
        }
    }
    
    private func detectTechniqueUsage(technique: TraditionalTechnique, action: GameAction, context: GameContext) async -> Bool {
        switch technique.id {
        case "septe_wild_mastery":
            return detectSevenWildMastery(action: action, context: context)
        case "opt_timing_mastery":
            return detectEightTimingMastery(action: action, context: context)
        case "moldovan_patience":
            return detectMoldovanPatience(action: action, context: context)
        case "transylvanian_efficiency":
            return detectTransylvanianEfficiency(action: action, context: context)
        case "wallachian_rhythm":
            return detectWallachianRhythm(action: action, context: context)
        case "carpathian_wisdom":
            return detectCarpathianWisdom(action: action, context: context)
        default:
            return false
        }
    }
    
    private func detectSevenWildMastery(action: GameAction, context: GameContext) -> Bool {
        guard case .cardPlayed(let card) = action,
              card.value == 7 else { return false }
        
        // Check if used strategically as wild card
        let isStrategic = context.tricksInRound > 0 && 
                         context.playerPosition == .advantageous &&
                         context.remainingCards.count > 5
        
        return isStrategic
    }
    
    private func detectEightTimingMastery(action: GameAction, context: GameContext) -> Bool {
        guard case .cardPlayed(let card) = action,
              card.value == 8 else { return false }
        
        // Check mathematical condition: total cards played % 3 == 0
        let totalCardsPlayed = context.totalCardsPlayed
        return totalCardsPlayed % 3 == 0
    }
    
    private func detectMoldovanPatience(action: GameAction, context: GameContext) -> Bool {
        // Analyze decision time and risk assessment
        let thoughtfulTiming = context.decisionTime > 3.0 && context.decisionTime < 15.0
        let lowRisk = context.riskLevel < 0.4
        let goodTiming = context.turnAdvantage > 0.6
        
        return thoughtfulTiming && lowRisk && goodTiming
    }
    
    private func detectTransylvanianEfficiency(action: GameAction, context: GameContext) -> Bool {
        // Quick decisions with high success rate
        let fastDecision = context.decisionTime < 2.0
        let highEfficiency = context.moveEfficiency > 0.8
        let fewMistakes = context.sessionMistakes < 2
        
        return fastDecision && highEfficiency && fewMistakes
    }
    
    private func detectWallachianRhythm(action: GameAction, context: GameContext) -> Bool {
        // Analyze for rhythmic, dynamic play patterns
        let consistentTiming = abs(context.averageDecisionTime - context.decisionTime) < 1.0
        let strategicVariation = context.strategyVariation > 0.6
        let adaptivePlay = context.adaptabilityScore > 0.7
        
        return consistentTiming && strategicVariation && adaptivePlay
    }
    
    private func detectCarpathianWisdom(action: GameAction, context: GameContext) -> Bool {
        // Deep strategic thinking with cultural awareness
        let deepStrategy = context.strategyDepth > 0.8
        let culturalPattern = context.culturalPatternRecognition > 0.7
        let wisdomApplication = context.traditionalKnowledgeUsage > 0.6
        
        return deepStrategy && culturalPattern && wisdomApplication
    }
    
    // MARK: - Cultural Milestone Detection
    
    private func detectCulturalMilestones(action: GameAction, context: GameContext) async {
        let milestones = await identifyMilestones(action: action, context: context)
        
        for milestone in milestones {
            if !gameSessionMilestones.contains(where: { $0.id == milestone.id }) {
                gameSessionMilestones.append(milestone)
                await celebrateMilestone(milestone)
            }
        }
    }
    
    private func identifyMilestones(action: GameAction, context: GameContext) async -> [TraditionalMilestone] {
        var milestones: [TraditionalMilestone] = []
        
        // Check for various milestone types
        if let milestone = checkStrategicExcellenceMilestone(action: action, context: context) {
            milestones.append(milestone)
        }
        
        if let milestone = checkCulturalTraditionMilestone(action: action, context: context) {
            milestones.append(milestone)
        }
        
        if let milestone = checkRegionalMasteryMilestone(action: action, context: context) {
            milestones.append(milestone)
        }
        
        if let milestone = checkHeritageEngagementMilestone(action: action, context: context) {
            milestones.append(milestone)
        }
        
        return milestones
    }
    
    private func checkStrategicExcellenceMilestone(action: GameAction, context: GameContext) -> TraditionalMilestone? {
        // Perfect sequence of strategic moves
        let recentActions = techniqueDetectionBuffer.suffix(5)
        let strategicMoves = recentActions.filter { isStrategicMove($0, context: context) }
        
        if strategicMoves.count >= 4 {
            return TraditionalMilestone(
                id: UUID(),
                type: .strategicExcellence,
                name: "Excelență Strategică",
                description: "Sequință perfectă de mișcări strategice",
                culturalSignificance: "Demonstrează măiestria în gândirea tradițională românească",
                timestamp: Date(),
                context: context,
                experiencePoints: 50,
                culturalPoints: 10,
                celebrationType: .visual(.sparkleEffect)
            )
        }
        
        return nil
    }
    
    private func checkCulturalTraditionMilestone(action: GameAction, context: GameContext) -> TraditionalMilestone? {
        // Using traditional Romanian playing patterns
        if context.traditionalPatternUsage > 0.8 && context.culturalAuthenticity > 0.7 {
            return TraditionalMilestone(
                id: UUID(),
                type: .culturalTradition,
                name: "Tradiție Culturală",
                description: "Folosirea modelelor tradiționale românești",
                culturalSignificance: "Păstrează și respectă tradițiile jocului românesc",
                timestamp: Date(),
                context: context,
                experiencePoints: 30,
                culturalPoints: 20,
                celebrationType: .audioVisual(.folkMusic, .traditionalGlow)
            )
        }
        
        return nil
    }
    
    private func checkRegionalMasteryMilestone(action: GameAction, context: GameContext) -> TraditionalMilestone? {
        // Mastery of specific regional style
        if let region = detectRegionalStyleMastery(context: context) {
            return TraditionalMilestone(
                id: UUID(),
                type: .regionalMastery,
                name: "Măiestrie Regională",
                description: "Stăpânirea stilului regional \(region.displayName)",
                culturalSignificance: "Păstrează și dezvoltă tradițiile regionale românești",
                timestamp: Date(),
                context: context,
                experiencePoints: 75,
                culturalPoints: 25,
                celebrationType: .regional(region, .crestDisplay)
            )
        }
        
        return nil
    }
    
    private func checkHeritageEngagementMilestone(action: GameAction, context: GameContext) -> TraditionalMilestone? {
        // Active engagement with cultural content
        if context.heritageEngagement > 0.9 && context.educationalInteraction > 0.7 {
            return TraditionalMilestone(
                id: UUID(),
                type: .heritageEngagement,
                name: "Angajament Cultural",
                description: "Implicare activă în învățarea patrimoniului cultural",
                culturalSignificance: "Contribuie la păstrarea și transmiterea cunoștințelor culturale",
                timestamp: Date(),
                context: context,
                experiencePoints: 40,
                culturalPoints: 30,
                celebrationType: .educational(.heritageBook, .wisdomGlow)
            )
        }
        
        return nil
    }
    
    // MARK: - Progress Recording and Updates
    
    private func recordTechniqueUsage(technique: TraditionalTechnique, action: GameAction, context: GameContext) async {
        let key = technique.id
        var stats = traditionalTechniqueUsage[key] ?? TechniqueUsageStats(techniqueId: key)
        
        stats.totalUses += 1
        stats.lastUsed = Date()
        
        // Track success rate
        if context.moveSuccessful {
            stats.successfulUses += 1
        }
        
        // Update mastery level
        stats.masteryLevel = calculateMasteryLevel(stats: stats, technique: technique)
        
        traditionalTechniqueUsage[key] = stats
        
        // Check for achievement progress
        await checkTechniqueAchievements(technique: technique, stats: stats)
    }
    
    private func calculateMasteryLevel(stats: TechniqueUsageStats, technique: TraditionalTechnique) -> MasteryLevel {
        let successRate = stats.successRate
        let totalUses = stats.totalUses
        
        switch technique.difficulty {
        case .beginner:
            if totalUses >= 10 && successRate >= 0.6 { return .competent }
        case .intermediate:
            if totalUses >= 25 && successRate >= 0.7 { return .proficient }
        case .advanced:
            if totalUses >= 50 && successRate >= 0.8 { return .expert }
        case .expert:
            if totalUses >= 100 && successRate >= 0.85 { return .master }
        case .master:
            if totalUses >= 200 && successRate >= 0.9 { return .grandmaster }
        }
        
        return stats.masteryLevel
    }
    
    private func processGameSessionMilestones(result: GameResult, context: GameContext) async {
        // Add session milestones to recent milestones
        recentMilestones.append(contentsOf: gameSessionMilestones)
        
        // Keep only recent milestones (last 20)
        if recentMilestones.count > 20 {
            recentMilestones = Array(recentMilestones.suffix(20))
        }
        
        // Check for achievement unlocks
        for milestone in gameSessionMilestones {
            await achievementManager.processMilestone(milestone)
        }
    }
    
    private func updateCulturalAuthenticity(result: GameResult) async {
        guard let context = currentGameContext else { return }
        
        culturalAuthenticity.gamesAnalyzed += 1
        culturalAuthenticity.traditionalTechniqueUsage += context.traditionalPatternUsage
        culturalAuthenticity.culturalEngagement += context.heritageEngagement
        culturalAuthenticity.authenticityScore = culturalAuthenticity.overallAuthenticity
        
        culturalAuthenticity.lastUpdated = Date()
    }
    
    private func updateRegionalStyleProgress(result: GameResult, context: GameContext) async {
        // Update progress for detected regional styles
        for (region, progress) in regionalStyleProgress {
            var updatedProgress = progress
            
            if let styleUsage = detectRegionalStyleUsage(region: region, context: context) {
                updatedProgress.gamesPlayed += 1
                if result.playerWon {
                    updatedProgress.gamesWon += 1
                }
                updatedProgress.styleAuthenticityScore += styleUsage
                updatedProgress.lastPlayed = Date()
                
                regionalStyleProgress[region] = updatedProgress
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func isStrategicMove(_ action: GameAction, context: GameContext) -> Bool {
        switch action {
        case .cardPlayed(let card):
            return card.value == 7 || (card.value == 8 && context.totalCardsPlayed % 3 == 0)
        case .tricksWon:
            return context.tricksWon > context.tricksExpected
        default:
            return false
        }
    }
    
    private func detectRegionalStyleMastery(context: GameContext) -> RomanianRegion? {
        for (region, progress) in regionalStyleProgress {
            if progress.masteryLevel >= .proficient && 
               context.regionalStyleMatch[region] ?? 0 > 0.8 {
                return region
            }
        }
        return nil
    }
    
    private func detectRegionalStyleUsage(region: RomanianRegion, context: GameContext) -> Float? {
        return context.regionalStyleMatch[region]
    }
    
    private func celebrateMilestone(_ milestone: TraditionalMilestone) async {
        // Trigger celebration animation/sound
        NotificationCenter.default.post(
            name: .traditionalMilestoneAchieved,
            object: milestone
        )
    }
    
    private func checkTechniqueAchievements(technique: TraditionalTechnique, stats: TechniqueUsageStats) async {
        // Check if this technique usage unlocks any achievements
        await achievementManager.checkTechniqueAchievements(technique: technique, stats: stats)
    }
    
    // MARK: - Persistence
    
    private func saveProgress() {
        let encoder = JSONEncoder()
        
        // Save technique usage stats
        if let data = try? encoder.encode(traditionalTechniqueUsage) {
            UserDefaults.standard.set(data, forKey: "traditional_technique_usage")
        }
        
        // Save cultural authenticity
        if let data = try? encoder.encode(culturalAuthenticity) {
            UserDefaults.standard.set(data, forKey: "cultural_authenticity_metrics")
        }
        
        // Save regional progress
        if let data = try? encoder.encode(regionalStyleProgress) {
            UserDefaults.standard.set(data, forKey: "regional_style_progress")
        }
    }
    
    private func loadStoredProgress() {
        let decoder = JSONDecoder()
        
        // Load technique usage stats
        if let data = UserDefaults.standard.data(forKey: "traditional_technique_usage"),
           let stats = try? decoder.decode([String: TechniqueUsageStats].self, from: data) {
            traditionalTechniqueUsage = stats
        }
        
        // Load cultural authenticity
        if let data = UserDefaults.standard.data(forKey: "cultural_authenticity_metrics"),
           let metrics = try? decoder.decode(CulturalAuthenticityMetrics.self, from: data) {
            culturalAuthenticity = metrics
        }
        
        // Load regional progress
        if let data = UserDefaults.standard.data(forKey: "regional_style_progress"),
           let progress = try? decoder.decode([RomanianRegion: RegionalStyleProgress].self, from: data) {
            regionalStyleProgress = progress
        }
    }
}

// MARK: - Supporting Data Models

struct TraditionalTechnique {
    let id: String
    let name: String
    let description: String
    let culturalSignificance: String
    let detectionCriteria: [DetectionCriterion]
    let difficulty: TechniqueDifficulty
    let region: RomanianRegion
}

enum TechniqueDifficulty: String, Codable {
    case beginner, intermediate, advanced, expert, master
}

enum DetectionCriterion {
    case cardPlayedAsWild(value: Int)
    case cardPlayed(value: Int)
    case strategicTiming
    case mathematicalCondition(MathCondition)
    case highSuccessRate(threshold: Float)
    case consistentApplication
    case thoughtfulPacing
    case lowRiskPlays
    case consistentPerformance
    case fastDecisionMaking
    case highEfficiency
    case minimalMistakes
    case rhythmicPlay
    case strategicVariation
    case adaptability
    case deepStrategy
    case patternRecognition
    case culturalAwareness
}

enum MathCondition {
    case countModuloThree
}

struct TechniqueUsageStats: Codable {
    let techniqueId: String
    var totalUses: Int = 0
    var successfulUses: Int = 0
    var lastUsed: Date?
    var masteryLevel: MasteryLevel = .novice
    
    var successRate: Float {
        guard totalUses > 0 else { return 0 }
        return Float(successfulUses) / Float(totalUses)
    }
}

enum MasteryLevel: String, Codable, Comparable {
    case novice = "novice"
    case competent = "competent"
    case proficient = "proficient"
    case expert = "expert"
    case master = "master"
    case grandmaster = "grandmaster"
    
    static func < (lhs: MasteryLevel, rhs: MasteryLevel) -> Bool {
        let order: [MasteryLevel] = [.novice, .competent, .proficient, .expert, .master, .grandmaster]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else { return false }
        return lhsIndex < rhsIndex
    }
}

struct CulturalAuthenticityMetrics: Codable {
    var gamesAnalyzed: Int = 0
    var traditionalTechniqueUsage: Float = 0.0
    var culturalEngagement: Float = 0.0
    var authenticityScore: Float = 0.0
    var lastUpdated: Date = Date()
    
    var overallAuthenticity: Float {
        guard gamesAnalyzed > 0 else { return 0 }
        let techniqueAvg = traditionalTechniqueUsage / Float(gamesAnalyzed)
        let engagementAvg = culturalEngagement / Float(gamesAnalyzed)
        return (techniqueAvg + engagementAvg) / 2.0
    }
}

struct RegionalStyleProgress: Codable {
    let region: RomanianRegion
    var gamesPlayed: Int = 0
    var gamesWon: Int = 0
    var styleAuthenticityScore: Float = 0.0
    var masteryLevel: MasteryLevel = .novice
    var lastPlayed: Date?
    
    var winRate: Float {
        guard gamesPlayed > 0 else { return 0 }
        return Float(gamesWon) / Float(gamesPlayed)
    }
    
    var averageAuthenticity: Float {
        guard gamesPlayed > 0 else { return 0 }
        return styleAuthenticityScore / Float(gamesPlayed)
    }
}

struct TraditionalMilestone: Identifiable {
    let id: UUID
    let type: MilestoneType
    let name: String
    let description: String
    let culturalSignificance: String
    let timestamp: Date
    let context: GameContext
    let experiencePoints: Int
    let culturalPoints: Int
    let celebrationType: CelebrationType
}

enum MilestoneType {
    case strategicExcellence
    case culturalTradition
    case regionalMastery
    case heritageEngagement
    case techniqueMastery
    case authenticityAchievement
}

enum CelebrationType {
    case visual(VisualEffect)
    case audioVisual(AudioEffect, VisualEffect)
    case regional(RomanianRegion, RegionalEffect)
    case educational(EducationalElement, VisualEffect)
}

enum VisualEffect {
    case sparkleEffect
    case traditionalGlow
    case crestDisplay
    case wisdomGlow
}

enum AudioEffect {
    case folkMusic
    case traditionalCheer
    case heritageHymn
}

enum RegionalEffect {
    case crestDisplay
    case flagWave
    case folkPattern
}

enum EducationalElement {
    case heritageBook
    case culturalSymbol
    case traditionalPattern
}

enum GameAction {
    case cardPlayed(PlayedCard)
    case tricksWon(Int)
    case gameCompleted(GameResult)
    case culturalInteraction(String)
}

struct PlayedCard {
    let value: Int
    let suit: String
    let isWild: Bool
}

struct GameContext {
    let gameId: String
    let tricksInRound: Int
    let playerPosition: PlayerPosition
    let remainingCards: [PlayedCard]
    let totalCardsPlayed: Int
    let decisionTime: TimeInterval
    let riskLevel: Float
    let turnAdvantage: Float
    let moveEfficiency: Float
    let sessionMistakes: Int
    let averageDecisionTime: TimeInterval
    let strategyVariation: Float
    let adaptabilityScore: Float
    let strategyDepth: Float
    let culturalPatternRecognition: Float
    let traditionalKnowledgeUsage: Float
    let traditionalPatternUsage: Float
    let culturalAuthenticity: Float
    let heritageEngagement: Float
    let educationalInteraction: Float
    let moveSuccessful: Bool
    let tricksWon: Int
    let tricksExpected: Int
    let regionalStyleMatch: [RomanianRegion: Float]
}

enum PlayerPosition {
    case advantageous
    case neutral
    case disadvantageous
}

struct GameResult {
    let playerWon: Bool
    let finalScore: Int
    let tricksWon: Int
    let culturalEngagement: Float
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let traditionalMilestoneAchieved = Notification.Name("traditionalMilestoneAchieved")
}