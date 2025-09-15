//
//  GameViewModelAnalyticsIntegration.swift
//  Septica
//
//  GameViewModel Integration with Enhanced Analytics - Sprint 2
//  Connects Romanian cultural analytics with real-time gameplay
//

import Foundation
import Combine

/// Extension to GameViewModel that integrates advanced Romanian cultural analytics
extension GameViewModel {
    
    // MARK: - Enhanced Analytics Integration
    
    /// Initialize enhanced analytics systems for Romanian cultural tracking
    func initializeEnhancedAnalytics() {
        // Create analytics engines
        self.cardMasteryEngine = CardCollectionMasteryEngine(
            achievementManager: self.achievementManager,
            strategyAnalyzer: self.strategyAnalyzer
        )
        
        self.celebrationManager = AchievementCelebrationManager(
            audioManager: self.audioManager,
            hapticManager: self.hapticManager
        )
        
        // Setup analytics event monitoring
        setupAnalyticsEventMonitoring()
        
        // Setup real-time cultural tracking
        setupCulturalTrackingIntegration()
        
        logger.info("Enhanced Romanian cultural analytics initialized")
    }
    
    // MARK: - Real-Time Gameplay Analytics
    
    /// Analyze card play with full Romanian cultural context
    override func playCard(_ card: Card) {
        // Existing card play logic
        super.playCard(card)
        
        // Enhanced analytics tracking
        analyzeCardPlayWithCulturalContext(card)
        
        // Update cultural mastery
        updateCulturalMasteryProgress(card)
        
        // Check for achievement triggers
        checkAchievementTriggers(cardPlayed: card)
        
        // Romanian strategy analysis
        analyzeRomanianStrategyAlignment(card)
    }
    
    private func analyzeCardPlayWithCulturalContext(_ card: Card) {
        let context = generateCardPlayContext(for: card)
        
        // Track in card mastery engine
        cardMasteryEngine?.analyzeCardPlay(card, context: context)
        
        // Update strategy analyzer
        strategyAnalyzer?.analyzeCardInContext(card, context: context)
        
        // Track cultural moments
        if context.hadCulturalSignificance {
            recordCulturalMoment(card: card, context: context)
        }
    }
    
    private func generateCardPlayContext(for card: Card) -> CardPlayContext {
        let tableCount = tableCards.count
        let wasSuccessful = determinePlaySuccess(card)
        let culturalSignificance = determineCulturalSignificance(card)
        let strategicOptimal = determineStrategicOptimality(card)
        
        return CardPlayContext(
            situation: determinePlaySituation(card),
            tableCardsCount: tableCount,
            wasSuccessful: wasSuccessful,
            hadCulturalSignificance: culturalSignificance,
            alignsWithTraditionalStrategy: assessTraditionalAlignment(card),
            wasStrategicallyOptimal: strategicOptimal,
            maximizedPointValue: assessPointValueOptimization(card),
            demonstratedMastery: assessMasteryDemonstration(card),
            hadLuckyCulturalMoment: assessLuckyCulturalMoment(card),
            tableCountDivisibleByThree: tableCount % 3 == 0,
            culturalContext: generateCulturalContext(card)
        )
    }
    
    // MARK: - Achievement Integration
    
    private func checkAchievementTriggers(cardPlayed card: Card) {
        // Track gameplay events
        achievementManager?.trackGameEvent(type: .cardPlayed, value: 1)
        
        // Check for specific card achievements
        checkCardSpecificAchievements(card)
        
        // Check for strategic achievements
        checkStrategicAchievements(card)
        
        // Check for cultural achievements
        checkCulturalAchievements(card)
        
        // Check for mastery milestones
        checkMasteryMilestones(card)
    }
    
    private func checkCardSpecificAchievements(_ card: Card) {
        switch card.value {
        case 7: // Wild card mastery
            checkSevenMasteryAchievements(card)
        case 10, 14: // Point cards
            checkPointCardAchievements(card)
        case 8: // Conditional beat card
            checkEightSpecialAchievements(card)
        default:
            checkRegularCardAchievements(card)
        }
    }
    
    private func checkSevenMasteryAchievements(_ card: Card) {
        guard card.value == 7 else { return }
        
        let sevenPlaysCount = getCardPlayCount(card)
        let successRate = getCardSuccessRate(card)
        
        // Check for seven mastery milestones
        if sevenPlaysCount == 25 && successRate >= 0.8 {
            triggerAchievement("seven_apprentice_master")
        } else if sevenPlaysCount == 100 && successRate >= 0.9 {
            triggerAchievement("seven_grand_master")
        }
    }
    
    private func checkPointCardAchievements(_ card: Card) {
        guard card.isPointCard else { return }
        
        let pointsCollected = getTotalPointsCollected()
        
        if pointsCollected >= 50 {
            triggerAchievement("point_collector_bronze")
        } else if pointsCollected >= 200 {
            triggerAchievement("point_collector_gold")
        }
    }
    
    // MARK: - Cultural Moments Recording
    
    private func recordCulturalMoment(card: Card, context: CardPlayContext) {
        let moment = CulturalMoment(
            type: determineCulturalMomentType(context),
            card: card,
            context: context.culturalContext,
            timestamp: Date()
        )
        
        // Record in strategy analyzer
        strategyAnalyzer?.recordCulturalMoment(moment)
        
        // Track cultural achievement progress
        achievementManager?.trackCulturalEvent(type: .traditionExplored, value: 1)
        
        // Update cultural authenticity score
        updateCulturalAuthenticityScore(moment)
    }
    
    // MARK: - Romanian Strategy Analysis
    
    private func analyzeRomanianStrategyAlignment(_ card: Card) {
        let alignment = assessRomanianStrategyAlignment(card)
        
        if alignment.isTraditional {
            // Reward traditional Romanian play style
            updateTraditionalismLevel(+1)
            
            if alignment.significance == .high {
                triggerCulturalCelebration(type: .traditionalWisdom, card: card)
            }
        }
        
        // Update strategy analysis
        strategyAnalyzer?.updateStrategyAlignment(alignment)
    }
    
    // MARK: - Game State Monitoring
    
    override func onGameWon(winner: Player) {
        super.onGameWon(winner: winner)
        
        // Track game completion
        achievementManager?.trackGameEvent(type: .gameWon, value: 1)
        
        // Analyze game performance
        analyzeGamePerformance(winner: winner)
        
        // Check for game-level achievements
        checkGameCompletionAchievements(winner: winner)
        
        // Update long-term statistics
        updateLongTermStatistics(winner: winner)
    }
    
    override func onGameStarted() {
        super.onGameStarted()
        
        // Track game start
        achievementManager?.trackGameEvent(type: .gameStarted, value: 1)
        
        // Initialize game session analytics
        initializeGameSessionAnalytics()
        
        // Setup real-time monitoring
        setupGameSessionMonitoring()
    }
    
    // MARK: - Cultural Celebrations
    
    private func triggerCulturalCelebration(type: CulturalCelebrationType, card: Card) {
        // Create mini-celebration for cultural moments
        let celebration = createCulturalMiniCelebration(type: type, card: card)
        
        NotificationCenter.default.post(
            name: .culturalMomentCelebration,
            object: celebration
        )
    }
    
    // MARK: - Analytics Event Monitoring Setup
    
    private func setupAnalyticsEventMonitoring() {
        // Monitor achievement unlocks
        NotificationCenter.default.publisher(for: .achievementUnlocked)
            .sink { [weak self] notification in
                if let achievement = notification.object as? RomanianAchievement {
                    self?.onAchievementUnlocked(achievement)
                }
            }
            .store(in: &cancellables)
        
        // Monitor cultural symbol unlocks
        NotificationCenter.default.publisher(for: .culturalSymbolUnlocked)
            .sink { [weak self] notification in
                if let unlock = notification.object as? CulturalSymbolUnlock {
                    self?.onCulturalSymbolUnlocked(unlock)
                }
            }
            .store(in: &cancellables)
        
        // Monitor mastery milestones
        NotificationCenter.default.publisher(for: .masteryMilestoneReached)
            .sink { [weak self] notification in
                if let milestone = notification.object as? MasteryMilestone {
                    self?.onMasteryMilestoneReached(milestone)
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupCulturalTrackingIntegration() {
        // Integrate with existing performance monitoring
        performanceMonitor.onFrameRateChange = { [weak self] frameRate in
            self?.updatePerformanceMetrics(frameRate: frameRate)
        }
        
        // Setup cultural progress tracking
        strategyAnalyzer?.$culturalAuthenticityScore
            .sink { [weak self] score in
                self?.updateCulturalProgressUI(score: score)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Helper Methods
    
    private func determinePlaySituation(_ card: Card) -> CardPlayContext.PlaySituation {
        switch card.value {
        case 7:
            return .strategicWildCardUse
        case 10, 14:
            return .pointCardCapture
        case 8 where tableCards.count % 3 == 0:
            return .conditionalBeat
        default:
            return .tacticalPositioning
        }
    }
    
    private func determinePlaySuccess(_ card: Card) -> Bool {
        // Determine if the card play was successful based on game rules
        guard let lastCard = tableCards.last else { return true }
        return card.canBeat(lastCard, tableCardsCount: tableCards.count)
    }
    
    private func determineCulturalSignificance(_ card: Card) -> Bool {
        // Determine if this play has Romanian cultural significance
        switch card.value {
        case 7: return true // Seven is culturally significant (lucky number)
        case 14: return true // Ace represents mastery
        default: return false
        }
    }
    
    private func determineStrategicOptimality(_ card: Card) -> Bool {
        // Analyze if this was the optimal strategic choice
        // This would involve complex game tree analysis
        return evaluateOptimalMove(card)
    }
    
    private func assessTraditionalAlignment(_ card: Card) -> Bool {
        // Check if the play aligns with traditional Romanian Septica strategies
        return evaluateTraditionalStrategy(card)
    }
    
    private func evaluateTraditionalStrategy(_ card: Card) -> Bool {
        // Stub implementation for traditional strategy evaluation
        return true
    }
    
    private func determineCulturalMomentType(_ context: String) -> CulturalMomentType {
        // Stub implementation for cultural moment type determination
        return .strategicTradition
    }
    
    private func assessPointValueOptimization(_ card: Card) -> Bool {
        // Check if the play maximized point value capture
        return card.isPointCard && canCapturePoints()
    }
    
    private func assessMasteryDemonstration(_ card: Card) -> Bool {
        // Check if the play demonstrated advanced mastery
        return evaluateMasteryLevel(card) >= .expert
    }
    
    private func assessLuckyCulturalMoment(_ card: Card) -> Bool {
        // Check for culturally lucky moments (e.g., playing 7 of hearts)
        return card.value == 7 && card.suit == .hearts
    }
    
    private func generateCulturalContext(_ card: Card) -> String {
        // Generate Romanian cultural context for the card play
        switch (card.value, card.suit) {
        case (7, .hearts):
            return "Norocul inimii - traditional Romanian lucky card"
        case (14, .spades):
            return "As de pică - representing strength and courage"
        case (10, _):
            return "Cartea de valoare - traditional prosperity symbol"
        default:
            return "Traditional Romanian card play"
        }
    }
    
    private func triggerAchievement(_ achievementId: String) {
        // Trigger specific achievement by ID
        if let achievement = getAchievementById(achievementId) {
            celebrationManager?.celebrateAchievement(achievement, context: .immediate)
        }
    }
    
    // MARK: - Event Handlers
    
    private func onAchievementUnlocked(_ achievement: RomanianAchievement) {
        logger.info("Achievement unlocked: \(achievement.titleKey)")
        
        // Update UI state
        updateAchievementUI(achievement)
        
        // Update player progression
        updatePlayerProgression(achievement)
    }
    
    private func onCulturalSymbolUnlocked(_ unlock: CulturalSymbolUnlock) {
        logger.info("Cultural symbol unlocked: \(unlock.symbol)")
        
        // Update cultural collection
        updateCulturalCollection(unlock.symbol)
    }
    
    private func onMasteryMilestoneReached(_ milestone: MasteryMilestone) {
        logger.info("Mastery milestone reached: \(milestone.type)")
        
        // Update mastery progression UI
        updateMasteryProgressionUI(milestone)
    }
    
    // MARK: - Performance Integration
    
    private func updatePerformanceMetrics(frameRate: Double) {
        // Ensure analytics don't impact performance
        if frameRate < 50 {
            // Reduce analytics frequency if performance drops
            reduceAnalyticsFrequency()
        } else {
            // Restore full analytics if performance is good
            restoreFullAnalytics()
        }
    }
}

// MARK: - Analytics Properties Extension

extension GameViewModel {
    
    // Analytics engines
    private(set) var cardMasteryEngine: CardCollectionMasteryEngine?
    private(set) var celebrationManager: AchievementCelebrationManager?
    private(set) var achievementManager: RomanianCulturalAchievementManager?
    private(set) var strategyAnalyzer: RomanianStrategyAnalyzer?
    
    // Audio and haptic managers
    private(set) var audioManager: AudioManager?
    private(set) var hapticManager: HapticManager?
    
    // Analytics state
    @Published var culturalAuthenticityScore: Float = 0.0
    @Published var currentPlayingStyle: AnalyticsTraditionalStrategy = .wiseSage
    @Published var masteryLevel: CulturalMasteryLevel = .beginner
    @Published var unlockedSymbols: Set<RomanianCardSymbol> = []
    
    // Performance analytics
    @Published var analyticsPerformanceMetrics: AnalyticsPerformanceMetrics = AnalyticsPerformanceMetrics()
}

// MARK: - Supporting Data Structures

struct RomanianStrategyAlignment {
    let isTraditional: Bool
    let significance: CulturalSignificance
    let authenticityScore: Float
    
    enum CulturalSignificance {
        case low, medium, high
    }
}

enum CulturalCelebrationType {
    case traditionalWisdom
    case strategicExcellence
    case culturalAuthenticity
    case masteryDemonstration
}

struct CulturalMiniCelebration {
    let type: CulturalCelebrationType
    let card: Card
    let intensity: Float
    let duration: TimeInterval
}

struct AnalyticsPerformanceMetrics {
    var analyticsCallsPerSecond: Int = 0
    var averageAnalyticsProcessingTime: TimeInterval = 0
    var analyticsMemoryUsage: Int = 0
    var analyticsPerformanceImpact: Float = 0
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let culturalMomentCelebration = Notification.Name("culturalMomentCelebration")
}

// MARK: - Traditional Strategy Extension

enum AnalyticsTraditionalStrategy: String, CaseIterable {
    case wiseSage = "wise_sage"
    case boldWarrior = "bold_warrior"
    case patientScholar = "patient_scholar"
    case craftyCunning = "crafty_cunning"
    
    var displayName: String {
        switch self {
        case .wiseSage: return "Înțeleptul Satului"
        case .boldWarrior: return "Războinicul Curajos"
        case .patientScholar: return "Învățatul Răbdător"
        case .craftyCunning: return "Vicleanul Isteț"
        }
    }
}