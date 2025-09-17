//
//  CardCollectionMasteryEngine.swift
//  Septica
//
//  Enhanced Card Collection Analytics for Sprint 2
//  Detailed card-specific mastery tracking with Romanian cultural context
//

import Foundation
import Combine
import os.log

/// Advanced card collection analytics engine with Romanian cultural mastery tracking
@MainActor
class CardCollectionMasteryEngine: ObservableObject {
    
    // MARK: - Dependencies
    
    private let logger = Logger(subsystem: "dev.leanvibe.game.Septica", category: "CardCollectionMasteryEngine")
    private let achievementManager: RomanianCulturalAchievementManager
    private let strategyAnalyzer: RomanianStrategyAnalyzer
    
    // MARK: - Published Analytics State
    
    @Published var cardMasteryProfiles: [Card: CardMasteryProfile] = [:]
    @Published var suitPreferences: [Suit: SuitMasteryAnalysis] = [:]
    @Published var culturalCardSignificance: [Card: CulturalSignificance] = [:]
    @Published var masteryMilestones: [MasteryMilestone] = []
    @Published var dailyCardAnalytics: [Date: DailyCardAnalytics] = [:]
    
    // MARK: - Romanian Cultural Card Analytics
    
    @Published var sevenMasteryLevel: SevenMasteryLevel = .novice
    @Published var aceCollectionProgress: AceCollectionProgress = AceCollectionProgress()
    @Published var tenValueMastery: TenValueMastery = TenValueMastery()
    @Published var culturalSymbolismUnlocked: Set<RomanianCardSymbol> = []
    
    // MARK: - Advanced Analytics
    
    @Published var movePatternsAnalysis: MovePatternsAnalysis = MovePatternsAnalysis()
    @Published var cardSequenceInsights: [CardSequenceInsight] = []
    @Published var Romanian4GamePhaseAnalysis: GamePhaseAnalysis = GamePhaseAnalysis()
    @Published var cardEfficiencyMetrics: CardEfficiencyMetrics = CardEfficiencyMetrics()
    
    // MARK: - Initialization
    
    init(achievementManager: RomanianCulturalAchievementManager, strategyAnalyzer: RomanianStrategyAnalyzer) {
        self.achievementManager = achievementManager
        self.strategyAnalyzer = strategyAnalyzer
        
        setupCardCulturalSignificance()
        initializeMasteryProfiles()
        setupMasteryMilestones()
    }
    
    // MARK: - Card Play Analysis
    
    /// Analyze card play with detailed Romanian cultural context
    func analyzeCardPlay(_ card: Card, context: CardPlayContext) {
        let timestamp = Date()
        
        // Update mastery profile
        updateCardMasteryProfile(card, context: context, timestamp: timestamp)
        
        // Analyze Romanian cultural significance
        analyzeCulturalSignificance(card, context: context)
        
        // Check for mastery milestones
        checkMasteryMilestones(card: card, context: context)
        
        // Update daily analytics
        updateDailyAnalytics(card: card, context: context, timestamp: timestamp)
        
        // Romanian pattern analysis
        analyzeRomanianPattern(card: card, context: context)
        
        logger.info("Card play analyzed: \(card.displayName) in context: \(String(describing: context.situation))")
    }
    
    private func updateCardMasteryProfile(_ card: Card, context: CardPlayContext, timestamp: Date) {
        var profile = cardMasteryProfiles[card] ?? CardMasteryProfile(card: card)
        
        // Update play statistics
        profile.totalPlaysCount += 1
        profile.lastPlayedDate = timestamp
        profile.playContexts.append(context)
        
        // Analyze play success rate
        if context.wasSuccessful {
            profile.successfulPlaysCount += 1
            profile.avgSuccessRate = Float(profile.successfulPlaysCount) / Float(profile.totalPlaysCount)
        }
        
        // Romanian cultural context analysis
        if context.hadCulturalSignificance {
            profile.culturalPlaysCount += 1
            profile.culturalMasteryLevel = calculateCulturalMasteryLevel(profile)
        }
        
        // Card-specific analysis
        switch card.value {
        case 7:
            analyzeSevenPlay(card, context: context, profile: &profile)
        case 10:
            analyzeTenPlay(card, context: context, profile: &profile)
        case 14: // Ace
            analyzeAcePlay(card, context: context, profile: &profile)
        case 8:
            analyzeEightPlay(card, context: context, profile: &profile)
        default:
            analyzeRegularCardPlay(card, context: context, profile: &profile)
        }
        
        cardMasteryProfiles[card] = profile
    }
    
    // MARK: - Romanian Cultural Significance Analysis
    
    private func analyzeCulturalSignificance(_ card: Card, context: CardPlayContext) {
        guard var significance = culturalCardSignificance[card] else { return }
        
        // Check for cultural moments
        if context.wasStrategicallyOptimal {
            significance.culturalMoments.append(MasteryCulturalMoment(
                type: .strategicExcellence,
                card: card,
                context: context.culturalContext,
                timestamp: Date()
            ))
        }
        
        // Romanian traditional strategy alignment
        if context.alignsWithTraditionalStrategy {
            significance.traditionalAlignmentScore += 1
            unlockCulturalSymbolism(for: card)
        }
        
        // Update the dictionary with the modified significance
        culturalCardSignificance[card] = significance
    }
    
    private func unlockCulturalSymbolism(for card: Card) {
        let symbol = getRomanianCardSymbol(for: card)
        if !culturalSymbolismUnlocked.contains(symbol) {
            culturalSymbolismUnlocked.insert(symbol)
            
            // Trigger cultural achievement
            achievementManager.trackCulturalEvent(type: .traditionExplored, value: 1)
            
            // Create cultural celebration
            NotificationCenter.default.post(
                name: .culturalSymbolUnlocked,
                object: CulturalSymbolUnlock(symbol: symbol, card: card)
            )
        }
    }
    
    // MARK: - Mastery Level Calculations
    
    private func calculateCulturalMasteryLevel(_ profile: CardMasteryProfile) -> CulturalMasteryLevel {
        let culturalRatio = Float(profile.culturalPlaysCount) / Float(profile.totalPlaysCount)
        let successRate = profile.avgSuccessRate
        let playCount = profile.totalPlaysCount
        
        if culturalRatio >= 0.8 && successRate >= 0.9 && playCount >= 50 {
            return .culturalMaster
        } else if culturalRatio >= 0.6 && successRate >= 0.8 && playCount >= 25 {
            return .traditionalist
        } else if culturalRatio >= 0.4 && successRate >= 0.7 && playCount >= 10 {
            return .culturalApprentice
        } else {
            return .beginner
        }
    }
    
    // MARK: - Card-Specific Analysis Methods
    
    private func analyzeSevenPlay(_ card: Card, context: CardPlayContext, profile: inout CardMasteryProfile) {
        // Seven (wild card) specific analysis
        if context.situation == .strategicWildCardUse {
            profile.strategicPlaysCount += 1
            
            // Update seven mastery level
            let wildCardExpertise = Float(profile.strategicPlaysCount) / Float(profile.totalPlaysCount)
            sevenMasteryLevel = determineSevenMasteryLevel(expertise: wildCardExpertise, totalPlays: profile.totalPlaysCount)
        }
        
        // Romanian cultural context: 7 as the "lucky number"
        if context.hadLuckyCulturalMoment {
            profile.luckySevenMoments += 1
        }
    }
    
    private func analyzeTenPlay(_ card: Card, context: CardPlayContext, profile: inout CardMasteryProfile) {
        // Ten (point card) specific analysis
        if context.situation == .pointCardCapture {
            tenValueMastery.pointsCaptured += 1
            tenValueMastery.captureEfficiency = calculateCaptureEfficiency()
        }
        
        // Romanian cultural context: 10 as "value card"
        if context.maximizedPointValue {
            profile.pointOptimizationCount += 1
        }
    }
    
    private func analyzeAcePlay(_ card: Card, context: CardPlayContext, profile: inout CardMasteryProfile) {
        // Ace (highest value + point card) specific analysis
        aceCollectionProgress.acesPlayed += 1
        
        if context.situation == .dominanceAssertion {
            aceCollectionProgress.dominantAcePlays += 1
        }
        
        if context.situation == .pointCardCapture {
            aceCollectionProgress.acePointCaptures += 1
        }
        
        // Romanian cultural context: Ace as "master card"
        if context.demonstratedMastery {
            profile.masteryDemonstrations += 1
        }
    }
    
    private func analyzeEightPlay(_ card: Card, context: CardPlayContext, profile: inout CardMasteryProfile) {
        // Eight (conditional beat card) specific analysis
        if context.situation == .conditionalBeat && context.wasSuccessful {
            profile.conditionalBeatSuccesses += 1
            
            // Romanian pattern: understanding when "8 beats"
            if context.tableCountDivisibleByThree {
                profile.conditionalMasteryCount += 1
            }
        }
    }
    
    private func analyzeRegularCardPlay(_ card: Card, context: CardPlayContext, profile: inout CardMasteryProfile) {
        // Analysis for 9, Jack, Queen, King
        if context.situation == .tacticalPositioning {
            profile.tacticalPlaysCount += 1
        }
        
        if context.situation == .setupMove {
            profile.setupMovesCount += 1
        }
    }
    
    // MARK: - Mastery Milestones
    
    private func checkMasteryMilestones(card: Card, context: CardPlayContext) {
        let profile = cardMasteryProfiles[card] ?? CardMasteryProfile(card: card)
        
        // Check for various milestones
        checkPlayCountMilestones(card: card, profile: profile)
        checkSuccessRateMilestones(card: card, profile: profile)
        checkCulturalMilestones(card: card, profile: profile)
        checkSevenMasteryMilestones()
        checkAceCollectionMilestones()
    }
    
    private func checkPlayCountMilestones(card: Card, profile: CardMasteryProfile) {
        let milestoneThresholds = [10, 25, 50, 100, 250, 500]
        
        for threshold in milestoneThresholds {
            if profile.totalPlaysCount == threshold {
                let milestone = MasteryMilestone(
                    type: .cardPlayCount(card: card, count: threshold),
                    unlockedAt: Date(),
                    culturalSignificance: "Played \(card.displayName) \(threshold) times with Romanian authenticity"
                )
                masteryMilestones.append(milestone)
                
                // Trigger achievement
                achievementManager.trackGameEvent(type: .cardPlayed, value: threshold)
            }
        }
    }
    
    private func checkSuccessRateMilestones(card: Card, profile: CardMasteryProfile) {
        // Stub implementation - TODO: Implement success rate milestone checking
        let successThresholds: [Float] = [0.7, 0.8, 0.9, 0.95]
        let successRate = profile.totalPlaysCount > 0 ? Float(profile.successfulPlaysCount) / Float(profile.totalPlaysCount) : 0.0
        
        for threshold in successThresholds {
            if successRate >= threshold && profile.totalPlaysCount >= 10 {
                logger.info("🎯 Success rate milestone reached for \(card.displayName): \(threshold * 100)%")
            }
        }
    }
    
    private func checkCulturalMilestones(card: Card, profile: CardMasteryProfile) {
        // Stub implementation - TODO: Implement cultural milestone checking
        if let significance = culturalCardSignificance[card], significance.culturalMoments.count > 0 {
            logger.info("🏛️ Cultural milestone progress for \(card.displayName)")
        }
    }
    
    private func checkSevenMasteryMilestones() {
        // Stub implementation - TODO: Implement seven card mastery checking
        logger.info("🎭 Checking seven card mastery milestones")
    }
    
    private func checkAceCollectionMilestones() {
        // Stub implementation - TODO: Implement ace collection milestone checking
        logger.info("🏆 Checking ace collection milestones")
    }
    
    // MARK: - Setup Methods
    
    private func setupCardCulturalSignificance() {
        // Set up cultural significance for each card based on Romanian traditions
        for suit in Suit.allCases {
            for value in 7...14 {
                let card = Card(suit: suit, value: value)
                let significance = CulturalSignificance(
                    card: card,
                    romanianMeaning: getRomanianMeaning(for: card),
                    culturalStories: getRomanianStories(for: card),
                    traditionalUse: getTraditionalUse(for: card)
                )
                culturalCardSignificance[card] = significance
            }
        }
    }
    
    private func initializeMasteryProfiles() {
        // Initialize empty mastery profiles for all cards
        for suit in Suit.allCases {
            for value in 7...14 {
                let card = Card(suit: suit, value: value)
                cardMasteryProfiles[card] = CardMasteryProfile(card: card)
            }
        }
    }
    
    private func setupMasteryMilestones() {
        // Set up predefined mastery milestones for Romanian cultural learning
        // These will be checked as players progress
    }
    
    // MARK: - Helper Methods
    
    private func getRomanianCardSymbol(for card: Card) -> RomanianCardSymbol {
        switch (card.value, card.suit) {
        case (7, .hearts): return .luckyHeart
        case (7, .spades): return .mysticalSpade
        case (7, .diamonds): return .fortuneDiamond
        case (7, .clubs): return .protectiveClub
        case (14, .hearts): return .aceOfHearts // Ace of Hearts - love and family
        case (14, .spades): return .aceOfSpades // Ace of Spades - strength and courage
        case (10, _): return .valueCard // 10s represent prosperity
        default: return .traditionalCard
        }
    }
    
    private func getRomanianMeaning(for card: Card) -> String {
        // Romanian cultural meanings for cards
        switch card.value {
        case 7: return "Lucky number in Romanian folklore"
        case 8: return "Balance and harmony in traditional Romanian culture"
        case 9: return "Completion and fulfillment"
        case 10: return "Material prosperity and abundance"
        case 11: return "The loyal servant - Jack represents faithfulness"
        case 12: return "The wise woman - Queen represents wisdom"
        case 13: return "The noble leader - King represents strength"
        case 14: return "Excellence and mastery - Ace represents achievement"
        default: return "Traditional Romanian card"
        }
    }
    
    private func getRomanianStories(for card: Card) -> [String] {
        // Romanian folk tales and stories associated with cards
        switch card.value {
        case 7: return ["The Seven Stars of Ursa Major", "The Seven Wonders of Ancient Romania"]
        case 14: return ["The Ace of Victory", "The Master Card's Tale"]
        default: return []
        }
    }
    
    private func getTraditionalUse(for card: Card) -> String {
        // Traditional use in Romanian Septica
        switch card.value {
        case 7: return "Wild card - always beats other cards"
        case 8: return "Special beat when table count is divisible by 3"
        case 10, 14: return "Point card - worth 1 point when captured"
        default: return "Regular card - beats same value"
        }
    }
    
    private func determineSevenMasteryLevel(expertise: Float, totalPlays: Int) -> SevenMasteryLevel {
        if expertise >= 0.9 && totalPlays >= 100 {
            return .grandMaster
        } else if expertise >= 0.8 && totalPlays >= 50 {
            return .master
        } else if expertise >= 0.7 && totalPlays >= 25 {
            return .expert
        } else if expertise >= 0.6 && totalPlays >= 10 {
            return .skilled
        } else {
            return .novice
        }
    }
    
    private func calculateCaptureEfficiency() -> Float {
        // Calculate efficiency of point card captures
        let totalOpportunities = Float(tenValueMastery.captureOpportunities)
        let actualCaptures = Float(tenValueMastery.pointsCaptured)
        return totalOpportunities > 0 ? actualCaptures / totalOpportunities : 0.0
    }
    
    private func updateDailyAnalytics(card: Card, context: CardPlayContext, timestamp: Date) {
        let day = Calendar.current.startOfDay(for: timestamp)
        var analytics = dailyCardAnalytics[day] ?? DailyCardAnalytics(date: day)
        
        analytics.cardsPlayed.append(card)
        analytics.totalPlays += 1
        
        if context.wasSuccessful {
            analytics.successfulPlays += 1
        }
        
        if context.hadCulturalSignificance {
            analytics.culturalPlays += 1
        }
        
        dailyCardAnalytics[day] = analytics
    }
    
    private func analyzeRomanianPattern(card: Card, context: CardPlayContext) {
        // Advanced pattern analysis specific to Romanian Septica traditions
        // This feeds into the strategy analyzer for cultural authenticity scoring
        // TODO: Implement analyzeCardInContext method on RomanianStrategyAnalyzer
        logger.info("🎭 Romanian pattern analyzed for \(card.displayName)")
    }
}

// MARK: - Supporting Data Structures

struct CardMasteryProfile {
    let card: Card
    var totalPlaysCount: Int = 0
    var successfulPlaysCount: Int = 0
    var culturalPlaysCount: Int = 0
    var strategicPlaysCount: Int = 0
    var tacticalPlaysCount: Int = 0
    var setupMovesCount: Int = 0
    var pointOptimizationCount: Int = 0
    var masteryDemonstrations: Int = 0
    var conditionalBeatSuccesses: Int = 0
    var conditionalMasteryCount: Int = 0
    var luckySevenMoments: Int = 0
    
    var avgSuccessRate: Float = 0.0
    var culturalMasteryLevel: CulturalMasteryLevel = .beginner
    var lastPlayedDate: Date?
    var playContexts: [CardPlayContext] = []
    
    init(card: Card) {
        self.card = card
    }
}

// CulturalMasteryLevel is now defined in CulturalTypes.swift

enum SevenMasteryLevel: String, CaseIterable {
    case novice = "novice"
    case skilled = "skilled"
    case expert = "expert"
    case master = "master"
    case grandMaster = "grand_master"
    
    var displayName: String {
        switch self {
        case .novice: return "Novice în Șepte"
        case .skilled: return "Abil cu Șeptele"
        case .expert: return "Expert în Șepte"
        case .master: return "Maestru al Șeptelor"
        case .grandMaster: return "Mare Maestru al Șeptelor"
        }
    }
}

struct AceCollectionProgress {
    var acesPlayed: Int = 0
    var dominantAcePlays: Int = 0
    var acePointCaptures: Int = 0
    var aceStrategicUse: Int = 0
    
    var masteryLevel: CulturalMasteryLevel {
        let efficiency = Float(dominantAcePlays + acePointCaptures) / Float(max(acesPlayed, 1))
        if efficiency >= 0.9 && acesPlayed >= 20 {
            return .culturalMaster
        } else if efficiency >= 0.7 && acesPlayed >= 10 {
            return .traditionalist
        } else if efficiency >= 0.5 && acesPlayed >= 5 {
            return .culturalApprentice
        } else {
            return .beginner
        }
    }
}

struct TenValueMastery {
    var pointsCaptured: Int = 0
    var captureOpportunities: Int = 0
    var captureEfficiency: Float = 0.0
    var optimalTiming: Int = 0
}

struct CulturalSignificance {
    let card: Card
    let romanianMeaning: String
    let culturalStories: [String]
    let traditionalUse: String
    var culturalMoments: [MasteryCulturalMoment] = []
    var traditionalAlignmentScore: Int = 0
}

struct CardPlayContext {
    let situation: PlaySituation
    let tableCardsCount: Int
    let wasSuccessful: Bool
    let hadCulturalSignificance: Bool
    let alignsWithTraditionalStrategy: Bool
    let wasStrategicallyOptimal: Bool
    let maximizedPointValue: Bool
    let demonstratedMastery: Bool
    let hadLuckyCulturalMoment: Bool
    let tableCountDivisibleByThree: Bool
    let culturalContext: String
    
    enum PlaySituation: String, CaseIterable {
        case strategicWildCardUse = "strategic_wild_card"
        case pointCardCapture = "point_card_capture"
        case conditionalBeat = "conditional_beat"
        case tacticalPositioning = "tactical_positioning"
        case setupMove = "setup_move"
        case dominanceAssertion = "dominance_assertion"
        case culturalMoment = "cultural_moment"
    }
}

struct MasteryCulturalMoment {
    let type: CulturalMomentType
    let card: Card
    let context: String
    let timestamp: Date
    
}

// RomanianCardSymbol is now defined in CulturalTypes.swift

struct MasteryMilestone {
    let type: MilestoneType
    let unlockedAt: Date
    let culturalSignificance: String
    
    enum MilestoneType {
        case cardPlayCount(card: Card, count: Int)
        case successRate(card: Card, rate: Float)
        case culturalMastery(level: CulturalMasteryLevel)
        case sevenMastery(level: SevenMasteryLevel)
        case aceCollection(achievement: String)
    }
}

struct DailyCardAnalytics {
    let date: Date
    var cardsPlayed: [Card] = []
    var totalPlays: Int = 0
    var successfulPlays: Int = 0
    var culturalPlays: Int = 0
    
    var successRate: Float {
        return totalPlays > 0 ? Float(successfulPlays) / Float(totalPlays) : 0.0
    }
    
    var culturalEngagement: Float {
        return totalPlays > 0 ? Float(culturalPlays) / Float(totalPlays) : 0.0
    }
}

struct SuitMasteryAnalysis {
    let suit: Suit
    var totalPlays: Int = 0
    var preferenceScore: Float = 0.0
    var culturalConnection: String = ""
}

struct MovePatternsAnalysis {
    var sequentialPatterns: [String] = []
    var strategicSequences: [String] = []
    var culturalPatterns: [String] = []
}

struct CardSequenceInsight {
    let sequence: [Card]
    let culturalSignificance: String
    let strategicValue: Float
    let frequency: Int
}

struct GamePhaseAnalysis {
    var earlyGamePreferences: [Card: Int] = [:]
    var midGamePreferences: [Card: Int] = [:]
    var endGamePreferences: [Card: Int] = [:]
}

struct CardEfficiencyMetrics {
    var cardValueEfficiency: [Card: Float] = [:]
    var situationalEfficiency: [CardPlayContext.PlaySituation: Float] = [:]
    var culturalEfficiency: Float = 0.0
}

struct CulturalSymbolUnlock {
    let symbol: RomanianCardSymbol
    let card: Card
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let culturalSymbolUnlocked = Notification.Name("culturalSymbolUnlocked")
    static let masteryMilestoneReached = Notification.Name("masteryMilestoneReached")
    static let cardMasteryLevelUp = Notification.Name("cardMasteryLevelUp")
}