//
//  RomanianCulturalAnalytics.swift
//  Septica
//
//  Romanian Cultural Analytics Engine - Core analytics system for preserving and analyzing Romanian cultural gameplay patterns
//  Integrates with CloudKit for cross-device analytics sync and cultural authenticity tracking
//

import Foundation
import Combine
import GameplayKit
import os.log

/// Core Romanian Cultural Analytics Engine
/// Tracks traditional gameplay patterns, cultural authenticity, and educational engagement
@MainActor
class RomanianCulturalAnalytics: ObservableObject {
    
    // MARK: - Dependencies
    
    private let logger = Logger(subsystem: "dev.leanvibe.game.Septica", category: "RomanianCulturalAnalytics")
    private let cloudKitService: EnhancedCloudKitIntegrationService
    private let culturalLibrary: RomanianCulturalContentLibrary
    
    // MARK: - Published Analytics State
    
    @Published var culturalAuthenticityScore: Float = 0.0
    @Published var traditionalStrategyUsage: Float = 0.0
    @Published var regionalStyleAdaptation: Float = 0.0
    @Published var heritagePreservationIndex: Float = 0.0
    @Published var culturalLearningProgress: Float = 0.0
    
    // MARK: - Real-time Pattern Recognition
    
    @Published var currentGameAnalytics: GameCulturalAnalytics?
    @Published var realtimePatternDetection: [TraditionalPattern] = []
    @Published var culturalMoments: [CulturalMoment] = []
    @Published var authenticityAlerts: [AuthenticityAlert] = []
    
    // MARK: - Cultural Strategy Tracking
    
    private var traditionastrategies: [TraditionalStrategy] = []
    private var modernStrategies: [ModernStrategy] = []
    private var hybridPatterns: [HybridPattern] = []
    private var culturalEducationEvents: [CulturalEducationEvent] = []
    
    // MARK: - Performance & Analytics Data
    
    private var analyticsData: CulturalAnalyticsData
    private var performanceMonitor: CulturalPerformanceMonitor
    private var patternRecognition: TraditionalPatternRecognition
    
    // MARK: - Initialization
    
    init(cloudKitService: EnhancedCloudKitIntegrationService, culturalLibrary: RomanianCulturalContentLibrary) {
        self.cloudKitService = cloudKitService
        self.culturalLibrary = culturalLibrary
        self.analyticsData = CulturalAnalyticsData()
        self.performanceMonitor = CulturalPerformanceMonitor()
        self.patternRecognition = TraditionalPatternRecognition()
        
        setupAnalyticsEngine()
        loadTraditionalStrategies()
    }
    
    // MARK: - Analytics Engine Setup
    
    private func setupAnalyticsEngine() {
        // Initialize cultural pattern recognition
        patternRecognition.delegate = self
        
        // Load stored analytics data
        Task {
            await loadStoredAnalyticsData()
        }
        
        logger.info("Romanian Cultural Analytics Engine initialized")
    }
    
    private func loadTraditionalStrategies() {
        // Load traditional Romanian Septica strategies from cultural library
        traditionastrategies = [
            TraditionalStrategy(
                id: "cutting_with_sevens",
                name: "Tăierea cu Septele",
                description: "Using 7s strategically to cut opponent's plays",
                culturalOrigin: .traditional,
                effectiveness: 0.85,
                culturalSignificance: "Ancient Romanian technique from card masters",
                recognitionPattern: .sevenWildUsage
            ),
            TraditionalStrategy(
                id: "strategic_eight_usage",
                name: "Strategia Optului",
                description: "Using 8s when card count favors victory",
                culturalOrigin: .regional(.moldovan),
                effectiveness: 0.78,
                culturalSignificance: "Moldovan regional variation emphasizing timing",
                recognitionPattern: .eightTimingRule
            ),
            TraditionalStrategy(
                id: "point_card_hunting",
                name: "Vânătoarea Punctelor",
                description: "Strategic focus on high-value cards",
                culturalOrigin: .traditional,
                effectiveness: 0.82,
                culturalSignificance: "Traditional Romanian point maximization",
                recognitionPattern: .pointCardFocus
            ),
            TraditionalStrategy(
                id: "defensive_card_holding",
                name: "Apărarea Cărților",
                description: "Holding key cards for optimal timing",
                culturalOrigin: .regional(.transylvanian),
                effectiveness: 0.75,
                culturalSignificance: "Transylvanian patience and strategic thinking",
                recognitionPattern: .defensivePattern
            ),
            TraditionalStrategy(
                id: "rhythm_disruption",
                name: "Ruperea Ritmului",
                description: "Breaking opponent's playing rhythm",
                culturalOrigin: .masterLevel,
                effectiveness: 0.88,
                culturalSignificance: "Advanced technique from Romanian masters",
                recognitionPattern: .rhythmDisruption
            )
        ]
        
        logger.info("Loaded \(traditionastrategies.count) traditional Romanian strategies")
    }
    
    // MARK: - Real-time Game Analytics
    
    func startGameAnalysis(gameState: GameState) {
        currentGameAnalytics = GameCulturalAnalytics(
            gameId: gameState.id,
            startTime: Date(),
            players: gameState.players.map { createPlayerAnalytics($0) }
        )
        
        // Begin real-time pattern recognition
        patternRecognition.startAnalysis(gameState: gameState)
        
        logger.info("Started cultural analysis for game \(gameState.id)")
    }
    
    func analyzeMove(_ move: GameMove, gameState: GameState) {
        guard let analytics = currentGameAnalytics else { return }
        
        // Analyze move for traditional patterns
        let detectedPatterns = patternRecognition.analyzeMove(move, gameState: gameState)
        realtimePatternDetection.append(contentsOf: detectedPatterns)
        
        // Check for cultural moments
        let culturalMoment = detectCulturalMoment(move: move, patterns: detectedPatterns)
        if let moment = culturalMoment {
            culturalMoments.append(moment)
            celebrateCulturalMoment(moment)
        }
        
        // Update cultural authenticity score
        updateCulturalAuthenticityScore(move: move, patterns: detectedPatterns)
        
        // Track educational opportunities
        trackEducationalOpportunities(move: move, gameState: gameState)
    }
    
    func endGameAnalysis(gameResult: GameResult) {
        guard var analytics = currentGameAnalytics else { return }
        
        // Finalize game analytics
        analytics.endTime = Date()
        analytics.finalResult = gameResult
        analytics.culturalMoments = culturalMoments
        analytics.detectedPatterns = realtimePatternDetection
        
        // Calculate final cultural scores
        analytics.finalCulturalScore = calculateFinalCulturalScore(analytics)
        analytics.traditionalAlignmentScore = calculateTraditionalAlignment(analytics)
        analytics.culturalEducationScore = calculateEducationScore(analytics)
        
        // Store analytics data
        analyticsData.addGameAnalytics(analytics)
        
        // Sync to CloudKit
        Task {
            await syncAnalyticsToCloudKit(analytics)
        }
        
        // Reset for next game
        resetAnalyticsState()
        
        logger.info("Completed cultural analysis for game with score: \(analytics.finalCulturalScore)")
    }
    
    // MARK: - Cultural Pattern Detection
    
    private func detectCulturalMoment(move: GameMove, patterns: [TraditionalPattern]) -> CulturalMoment? {
        // Perfect Traditional Opening
        if patterns.contains(where: { $0.type == .perfectTraditionalOpening }) {
            return CulturalMoment(
                type: .perfectTraditionalOpening,
                timestamp: Date(),
                move: move,
                culturalSignificance: "Executed perfect traditional Romanian opening sequence",
                educationalContent: "This opening follows the classical Romanian Septica tradition dating back centuries",
                rewardPoints: 150
            )
        }
        
        // Romanian Master Move
        if patterns.contains(where: { $0.type == .masterLevelStrategy }) {
            return CulturalMoment(
                type: .romanianMasterMove,
                timestamp: Date(),
                move: move,
                culturalSignificance: "Demonstrated mastery-level traditional technique",
                educationalContent: "This advanced strategy was used by Romanian card masters in village tournaments",
                rewardPoints: 200
            )
        }
        
        // Cultural Heritage Preservation
        if patterns.filter({ $0.culturalOrigin == .traditional }).count >= 3 {
            return CulturalMoment(
                type: .heritagePreservation,
                timestamp: Date(),
                move: move,
                culturalSignificance: "Consistently demonstrating traditional Romanian techniques",
                educationalContent: "Your gameplay preserves centuries-old Romanian card playing wisdom",
                rewardPoints: 100
            )
        }
        
        return nil
    }
    
    private func updateCulturalAuthenticityScore(move: GameMove, patterns: [TraditionalPattern]) {
        let authenticityBonus = patterns.reduce(0.0) { total, pattern in
            total + pattern.authenticityWeight
        }
        
        let currentGame = analyticsData.getCurrentGameCount()
        let weightedBonus = authenticityBonus * Float(1.0 / max(1.0, Double(currentGame)))
        
        culturalAuthenticityScore = min(1.0, culturalAuthenticityScore + weightedBonus)
        
        // Check for authenticity milestones
        checkAuthenticityMilestones()
    }
    
    private func checkAuthenticityMilestones() {
        let previousScore = analyticsData.previousCulturalScore
        
        // Traditional Master threshold
        if culturalAuthenticityScore >= 0.75 && previousScore < 0.75 {
            let alert = AuthenticityAlert(
                type: .traditionalMaster,
                title: "Maestru Tradițional",
                message: "You've achieved Traditional Master status in Romanian Septica!",
                culturalReward: "traditional_master_badge"
            )
            authenticityAlerts.append(alert)
        }
        
        // Cultural Ambassador threshold
        if culturalAuthenticityScore >= 0.90 && previousScore < 0.90 {
            let alert = AuthenticityAlert(
                type: .culturalAmbassador,
                title: "Ambasador Cultural",
                message: "You are now a Cultural Ambassador of Romanian Septica traditions!",
                culturalReward: "cultural_ambassador_title"
            )
            authenticityAlerts.append(alert)
        }
    }
    
    // MARK: - Educational Tracking
    
    private func trackEducationalOpportunities(move: GameMove, gameState: GameState) {
        // Missed traditional opportunities
        let availableTraditionalMoves = identifyTraditionalOpportunities(gameState: gameState)
        let playedCard = move.card
        
        if !availableTraditionalMoves.contains(playedCard) && !availableTraditionalMoves.isEmpty {
            let educationEvent = CulturalEducationEvent(
                type: .missedTraditionalOpportunity,
                timestamp: Date(),
                gameMove: move,
                educationalContent: generateEducationalContent(for: availableTraditionalMoves),
                culturalContext: "Traditional Romanian masters would have considered these alternatives"
            )
            culturalEducationEvents.append(educationEvent)
        }
        
        // Regional strategy suggestions
        let currentRegionalStyle = detectCurrentRegionalStyle(gameState: gameState)
        if let suggestion = generateRegionalSuggestion(for: currentRegionalStyle, gameState: gameState) {
            let educationEvent = CulturalEducationEvent(
                type: .regionalStrategySuggestion,
                timestamp: Date(),
                gameMove: move,
                educationalContent: suggestion.content,
                culturalContext: suggestion.regionalContext
            )
            culturalEducationEvents.append(educationEvent)
        }
    }
    
    // MARK: - Analytics Calculations
    
    private func calculateFinalCulturalScore(_ analytics: GameCulturalAnalytics) -> Float {
        let traditionalPatternScore = Float(analytics.detectedPatterns.filter { $0.culturalOrigin == .traditional }.count) * 0.2
        let culturalMomentScore = Float(analytics.culturalMoments.count) * 0.3
        let educationalEngagementScore = Float(culturalEducationEvents.count) * 0.1
        let authenticityScore = culturalAuthenticityScore * 0.4
        
        return min(1.0, traditionalPatternScore + culturalMomentScore + educationalEngagementScore + authenticityScore)
    }
    
    private func calculateTraditionalAlignment(_ analytics: GameCulturalAnalytics) -> Float {
        let totalMoves = analytics.detectedPatterns.count
        guard totalMoves > 0 else { return 0.0 }
        
        let traditionalMoves = analytics.detectedPatterns.filter { $0.culturalOrigin == .traditional }.count
        return Float(traditionalMoves) / Float(totalMoves)
    }
    
    private func calculateEducationScore(_ analytics: GameCulturalAnalytics) -> Float {
        let educationEvents = culturalEducationEvents.count
        let culturalMoments = analytics.culturalMoments.count
        
        return min(1.0, Float(educationEvents + culturalMoments) * 0.1)
    }
    
    // MARK: - CloudKit Integration
    
    private func syncAnalyticsToCloudKit(_ analytics: GameCulturalAnalytics) async {
        do {
            // Convert to CloudKit-compatible statistics
            let culturalStatistics = convertToCloudKitStatistics(analytics)
            
            // Sync to CloudKit
            try await cloudKitService.syncCulturalStatistics(culturalStatistics)
            
            logger.info("Successfully synced cultural analytics to CloudKit")
        } catch {
            logger.error("Failed to sync cultural analytics: \(error)")
        }
    }
    
    private func convertToCloudKitStatistics(_ analytics: GameCulturalAnalytics) -> [CulturalStatistic] {
        var statistics: [CulturalStatistic] = []
        
        // Cultural authenticity statistic
        statistics.append(CulturalStatistic(
            id: UUID(),
            playerId: analytics.players.first?.playerId ?? UUID(),
            type: .culturalEngagement,
            value: Double(analytics.finalCulturalScore),
            culturalContext: "Romanian traditional gameplay analysis",
            timestamp: Date(),
            deviceId: UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        ))
        
        // Traditional alignment statistic
        statistics.append(CulturalStatistic(
            id: UUID(),
            playerId: analytics.players.first?.playerId ?? UUID(),
            type: .traditionalAlignment,
            value: Double(analytics.traditionalAlignmentScore),
            culturalContext: "Traditional Romanian Septica alignment analysis",
            timestamp: Date(),
            deviceId: UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        ))
        
        return statistics
    }
    
    // MARK: - Cultural Heritage Methods
    
    private func celebrateCulturalMoment(_ moment: CulturalMoment) {
        // Trigger cultural celebration UI
        NotificationCenter.default.post(
            name: .culturalMomentDetected,
            object: moment
        )
        
        // Award cultural experience points
        awardCulturalExperience(moment.rewardPoints)
        
        logger.info("Celebrated cultural moment: \(moment.type)")
    }
    
    private func awardCulturalExperience(_ points: Int) {
        analyticsData.totalCulturalExperience += points
        
        // Check for cultural level progression
        let newLevel = calculateCulturalLevel(analyticsData.totalCulturalExperience)
        if newLevel > analyticsData.currentCulturalLevel {
            analyticsData.currentCulturalLevel = newLevel
            triggerCulturalLevelUp(newLevel)
        }
    }
    
    private func calculateCulturalLevel(_ experience: Int) -> Int {
        // Romanian cultural progression levels
        switch experience {
        case 0..<100: return 1      // Novice (Începător)
        case 100..<500: return 2    // Apprentice (Ucenic)
        case 500..<1500: return 3   // Skilled (Priceput)
        case 1500..<3500: return 4  // Expert (Expert)
        case 3500..<7500: return 5  // Master (Maestru)
        case 7500..<15000: return 6 // Grand Master (Mare Maestru)
        default: return 7           // Cultural Guardian (Păzitor Cultural)
        }
    }
    
    private func triggerCulturalLevelUp(_ level: Int) {
        let levelNames = [
            1: "Începător Cultural",
            2: "Ucenic în Tradiții",
            3: "Priceput în Septica",
            4: "Expert Cultural",
            5: "Maestru Tradițional",
            6: "Mare Maestru",
            7: "Păzitor Cultural"
        ]
        
        NotificationCenter.default.post(
            name: .culturalLevelUp,
            object: CulturalLevelUpEvent(
                newLevel: level,
                levelName: levelNames[level] ?? "Maestru Cultural",
                culturalRewards: getCulturalRewards(for: level)
            )
        )
    }
    
    // MARK: - Helper Methods
    
    private func createPlayerAnalytics(_ player: Player) -> PlayerCulturalAnalytics {
        return PlayerCulturalAnalytics(
            playerId: player.id,
            playerName: player.name,
            isAI: player is AIPlayer,
            traditionalMoves: [],
            modernMoves: [],
            culturalEngagementLevel: 0.0
        )
    }
    
    private func identifyTraditionalOpportunities(gameState: GameState) -> [Card] {
        // Analyze current game state for traditional move opportunities
        guard let currentPlayer = gameState.currentPlayer else { return [] }
        
        var opportunities: [Card] = []
        
        // Check for 7 wild card opportunities
        let sevens = currentPlayer.hand.filter { $0.value == 7 }
        if !sevens.isEmpty && canUseSevenStrategically(gameState: gameState) {
            opportunities.append(contentsOf: sevens)
        }
        
        // Check for 8 timing opportunities
        let eights = currentPlayer.hand.filter { $0.value == 8 }
        if !eights.isEmpty && isOptimalEightTiming(gameState: gameState) {
            opportunities.append(contentsOf: eights)
        }
        
        return opportunities
    }
    
    private func canUseSevenStrategically(gameState: GameState) -> Bool {
        // Traditional Romanian strategy: Use 7 when it can cut opponent's potential high-value play
        guard let topCard = gameState.topTableCard else { return true }
        return topCard.value > 7 // Cut high-value cards
    }
    
    private func isOptimalEightTiming(gameState: GameState) -> Bool {
        // Traditional Romanian strategy: Use 8 when card count favors victory
        let cardCount = gameState.tableCards.count
        return cardCount % 3 == 0 // Traditional timing rule
    }
    
    private func generateEducationalContent(for cards: [Card]) -> String {
        if cards.contains(where: { $0.value == 7 }) {
            return "În tradiția românească, carțile de 7 se folosesc strategic pentru a 'tăia' jocurile adversarului. Această tehnică veche permite controlul ritmului jocului."
        }
        
        if cards.contains(where: { $0.value == 8 }) {
            return "Maestrii români de Septica foloseau carțile de 8 la momentul potrivit, când numărul cărților de pe masă favorizează victoria."
        }
        
        return "Tehnicile tradiționale românești oferă alternative strategice pentru această situație."
    }
    
    private func detectCurrentRegionalStyle(gameState: GameState) -> RomanianRegion? {
        // Analyze gameplay patterns to detect regional Romanian style
        let recentPatterns = realtimePatternDetection.suffix(5)
        
        let moldovanPatterns = recentPatterns.filter { $0.culturalOrigin == .regional(.moldovan) }.count
        let transylvanianPatterns = recentPatterns.filter { $0.culturalOrigin == .regional(.transylvanian) }.count
        let wallachianPatterns = recentPatterns.filter { $0.culturalOrigin == .regional(.wallachian) }.count
        
        if moldovanPatterns > transylvanianPatterns && moldovanPatterns > wallachianPatterns {
            return .moldovan
        } else if transylvanianPatterns > wallachianPatterns {
            return .transylvanian
        } else if wallachianPatterns > 0 {
            return .wallachian
        }
        
        return nil
    }
    
    private func generateRegionalSuggestion(for region: RomanianRegion?, gameState: GameState) -> RegionalSuggestion? {
        guard let region = region else { return nil }
        
        switch region {
        case .moldovan:
            return RegionalSuggestion(
                content: "Stilul moldovenesc favorizează răbdarea și jocul defensiv. Consideră să păstrezi cărțile de valoare pentru momentul potrivit.",
                regionalContext: "Tradiția moldoveneascăsă de joc strategic și calculat"
            )
        case .transylvanian:
            return RegionalSuggestion(
                content: "Stilul ardelean preferă jocul direct și eficient. Folosește cărțile de punct pentru presiune imediată.",
                regionalContext: "Tradiția ardeleană de eficiență și directețe în joc"
            )
        case .wallachian:
            return RegionalSuggestion(
                content: "Stilul muntenesc combină agresivitatea cu tactică. Alternează între presiune și retreere strategică.",
                regionalContext: "Tradiția munteneascăă de joc dinamic și adapabil"
            )
        }
    }
    
    private func getCulturalRewards(for level: Int) -> [String] {
        switch level {
        case 1: return ["traditional_card_back", "romanian_greetings"]
        case 2: return ["folk_music_track", "village_table_theme"]
        case 3: return ["regional_avatar", "cultural_patterns"]
        case 4: return ["expert_card_effects", "advanced_analytics"]
        case 5: return ["master_title", "golden_frame", "traditional_wisdom"]
        case 6: return ["grand_master_avatar", "legendary_effects", "cultural_education_unlock"]
        case 7: return ["cultural_guardian_status", "all_cultural_content", "heritage_preservation_certificate"]
        default: return []
        }
    }
    
    private func resetAnalyticsState() {
        realtimePatternDetection.removeAll()
        culturalMoments.removeAll()
        culturalEducationEvents.removeAll()
        currentGameAnalytics = nil
    }
    
    private func loadStoredAnalyticsData() async {
        // Load previously stored analytics data
        // This would integrate with local storage and CloudKit
        logger.info("Loaded stored cultural analytics data")
    }
    
    // MARK: - Analytics Data Access
    
    func getCulturalInsights() -> CulturalInsights {
        return CulturalInsights(
            totalGamesAnalyzed: analyticsData.totalGamesAnalyzed,
            averageCulturalScore: analyticsData.averageCulturalScore,
            traditionalStrategyUsage: traditionalStrategyUsage,
            regionalStyleDistribution: analyticsData.regionalStyleDistribution,
            culturalLearningProgress: culturalLearningProgress,
            mostUsedTraditionalStrategies: getMostUsedTraditionalStrategies(),
            culturalMilestones: analyticsData.culturalMilestones
        )
    }
    
    private func getMostUsedTraditionalStrategies() -> [TraditionalStrategyUsage] {
        return analyticsData.strategyUsageStats.map { (strategy, count) in
            TraditionalStrategyUsage(
                strategy: strategy,
                usageCount: count,
                successRate: analyticsData.getSuccessRate(for: strategy),
                culturalAuthenticity: strategy.culturalSignificance
            )
        }.sorted { $0.usageCount > $1.usageCount }
    }
}

// MARK: - Pattern Recognition Delegate

extension RomanianCulturalAnalytics: TraditionalPatternRecognitionDelegate {
    func didDetectPattern(_ pattern: TraditionalPattern) {
        realtimePatternDetection.append(pattern)
        
        // Update real-time analytics
        updateRealtimeAnalytics(with: pattern)
    }
    
    private func updateRealtimeAnalytics(with pattern: TraditionalPattern) {
        // Update traditional strategy usage
        if pattern.culturalOrigin == .traditional {
            traditionalStrategyUsage = min(1.0, traditionalStrategyUsage + 0.1)
        }
        
        // Update regional adaptation
        if case .regional(let region) = pattern.culturalOrigin {
            updateRegionalAdaptation(for: region)
        }
        
        // Update heritage preservation index
        heritagePreservationIndex = calculateHeritagePreservationIndex()
    }
    
    private func updateRegionalAdaptation(for region: RomanianRegion) {
        analyticsData.addRegionalUsage(region)
        regionalStyleAdaptation = calculateRegionalAdaptation()
    }
    
    private func calculateRegionalAdaptation() -> Float {
        let uniqueRegions = Set(analyticsData.regionalStyleDistribution.keys).count
        return Float(uniqueRegions) / 3.0 // 3 main Romanian regions
    }
    
    private func calculateHeritagePreservationIndex() -> Float {
        let traditionalPatterns = realtimePatternDetection.filter { $0.culturalOrigin == .traditional }.count
        let totalPatterns = max(1, realtimePatternDetection.count)
        return Float(traditionalPatterns) / Float(totalPatterns)
    }
}

// MARK: - Supporting Data Structures

struct GameCulturalAnalytics {
    let gameId: UUID
    let startTime: Date
    var endTime: Date?
    let players: [PlayerCulturalAnalytics]
    var detectedPatterns: [TraditionalPattern] = []
    var culturalMoments: [CulturalMoment] = []
    var finalResult: GameResult?
    var finalCulturalScore: Float = 0.0
    var traditionalAlignmentScore: Float = 0.0
    var culturalEducationScore: Float = 0.0
}

struct PlayerCulturalAnalytics {
    let playerId: UUID
    let playerName: String
    let isAI: Bool
    var traditionalMoves: [GameMove] = []
    var modernMoves: [GameMove] = []
    var culturalEngagementLevel: Float = 0.0
}

struct CulturalMoment {
    let type: CulturalMomentType
    let timestamp: Date
    let move: GameMove
    let culturalSignificance: String
    let educationalContent: String
    let rewardPoints: Int
}

enum CulturalMomentType {
    case perfectTraditionalOpening
    case romanianMasterMove
    case heritagePreservation
    case regionalMastery
    case culturalEducationMoment
}

struct AuthenticityAlert {
    let type: AuthenticityAlertType
    let title: String
    let message: String
    let culturalReward: String
}

enum AuthenticityAlertType {
    case traditionalMaster
    case culturalAmbassador
    case heritageGuardian
    case regionalExpert
}

struct CulturalEducationEvent {
    let type: EducationEventType
    let timestamp: Date
    let gameMove: GameMove
    let educationalContent: String
    let culturalContext: String
}

enum EducationEventType {
    case missedTraditionalOpportunity
    case regionalStrategySuggestion
    case culturalHistoryMoment
    case traditionalWisdomShare
}

struct RegionalSuggestion {
    let content: String
    let regionalContext: String
}

struct CulturalLevelUpEvent {
    let newLevel: Int
    let levelName: String
    let culturalRewards: [String]
}

struct CulturalInsights {
    let totalGamesAnalyzed: Int
    let averageCulturalScore: Float
    let traditionalStrategyUsage: Float
    let regionalStyleDistribution: [RomanianRegion: Int]
    let culturalLearningProgress: Float
    let mostUsedTraditionalStrategies: [TraditionalStrategyUsage]
    let culturalMilestones: [CulturalMilestone]
}

struct TraditionalStrategyUsage {
    let strategy: TraditionalStrategy
    let usageCount: Int
    let successRate: Float
    let culturalAuthenticity: String
}

struct CulturalMilestone {
    let name: String
    let achievedDate: Date
    let culturalSignificance: String
    let rewardUnlocked: String
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let culturalMomentDetected = Notification.Name("culturalMomentDetected")
    static let culturalLevelUp = Notification.Name("culturalLevelUp")
    static let authenticityMilestone = Notification.Name("authenticityMilestone")
}