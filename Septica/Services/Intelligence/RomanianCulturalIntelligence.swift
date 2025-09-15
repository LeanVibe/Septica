//
//  RomanianCulturalIntelligence.swift
//  Septica
//
//  Apple Intelligence Integration for Cultural Rule Explanations - Sprint 3 Week 10
//  Uses Apple's FoundationModels framework for natural language cultural education
//

import Foundation
import Combine
import FoundationModels
import os.log

/// Apple Intelligence-powered cultural explanation system for Romanian Septica rules
@MainActor
class RomanianCulturalIntelligence: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentExplanation: CulturalExplanation?
    @Published var folkloreNarration: FolkloreStory?
    @Published var culturalInsights: [CulturalInsight] = []
    @Published var isProcessingRequest: Bool = false
    @Published var educationalContent: [EducationalContent] = []
    
    // MARK: - Intelligence State
    
    @Published var modelAvailability: ModelAvailabilityStatus = .checking
    @Published var processingPerformance: IntelligencePerformanceMetrics = IntelligencePerformanceMetrics()
    @Published var educationalEngagement: EducationalEngagementMetrics = EducationalEngagementMetrics()
    
    // MARK: - Private Properties
    
    private let languageModel: SystemLanguageModel
    private var modelSession: LanguageModelSession?
    private let logger = Logger(subsystem: "dev.leanvibe.game.Septica", category: "RomanianCulturalIntelligence")
    private var cancellables = Set<AnyCancellable>()
    
    // Cultural knowledge database
    private let culturalKnowledgeBase: RomanianCulturalKnowledgeBase
    private let folkloreLibrary: RomanianFolkloreLibrary
    private let ruleExplanationTemplates: [GameRule: CulturalRuleTemplate]
    
    // Performance monitoring
    private let performanceMonitor: PerformanceMonitor
    
    // MARK: - Initialization
    
    init(performanceMonitor: PerformanceMonitor) {
        self.languageModel = SystemLanguageModel.default
        self.culturalKnowledgeBase = RomanianCulturalKnowledgeBase()
        self.folkloreLibrary = RomanianFolkloreLibrary()
        self.performanceMonitor = performanceMonitor
        self.ruleExplanationTemplates = Self.createRuleExplanationTemplates()
        
        Task {
            await initializeIntelligenceSystem()
        }
    }
    
    // MARK: - Intelligence System Initialization
    
    private func initializeIntelligenceSystem() async {
        do {
            modelAvailability = .checking
            
            // Check model availability
            let availability = await languageModel.availability
            
            switch availability {
            case .installed:
                modelAvailability = .available
                await initializeModelSession()
                
            case .supported:
                modelAvailability = .supported
                logger.info("Apple Intelligence supported but not installed")
                
            case .unsupported:
                modelAvailability = .unsupported
                logger.warning("Apple Intelligence not supported on this device")
                
            @unknown default:
                modelAvailability = .unknown
                logger.error("Unknown Apple Intelligence availability status")
            }
            
            logger.info("Romanian Cultural Intelligence initialized with status: \(modelAvailability)")
            
        } catch {
            logger.error("Failed to initialize Romanian Cultural Intelligence: \(error)")
            modelAvailability = .error
        }
    }
    
    private func initializeModelSession() async {
        do {
            let sessionConfiguration = LanguageModelSession.Configuration(
                systemPrompt: createSystemPrompt(),
                options: LanguageModelSession.Options()
            )
            
            modelSession = try await languageModel.session(configuration: sessionConfiguration)
            logger.info("Apple Intelligence model session initialized for Romanian cultural explanations")
            
        } catch {
            logger.error("Failed to create Apple Intelligence session: \(error)")
            modelAvailability = .error
        }
    }
    
    // MARK: - Cultural Rule Explanations
    
    /// Generate natural language explanation for a game rule with cultural context
    func explainRule(_ rule: GameRule, context: CulturalContext) async -> CulturalExplanation {
        let startTime = Date()
        isProcessingRequest = true
        
        defer {
            isProcessingRequest = false
            recordPerformanceMetrics(startTime: startTime, operation: .ruleExplanation)
        }
        
        // Check if model is available
        guard modelAvailability == .available,
              let session = modelSession else {
            return createFallbackExplanation(for: rule, context: context)
        }
        
        do {
            let prompt = createRuleExplanationPrompt(rule: rule, context: context)
            let response = try await session.generate(prompt: prompt)
            
            let explanation = parseRuleExplanationResponse(response, rule: rule, context: context)
            
            // Cache and track explanation
            currentExplanation = explanation
            trackEducationalEngagement(explanation)
            
            logger.info("Generated cultural rule explanation for \(rule.displayName)")
            return explanation
            
        } catch {
            logger.error("Failed to generate rule explanation: \(error)")
            return createFallbackExplanation(for: rule, context: context)
        }
    }
    
    /// Generate folklore narration triggered by gameplay moments
    func narrateFolklore(for moment: CulturalMoment) async -> FolkloreStory {
        let startTime = Date()
        
        defer {
            recordPerformanceMetrics(startTime: startTime, operation: .folkloreNarration)
        }
        
        // Check if model is available
        guard modelAvailability == .available,
              let session = modelSession else {
            return folkloreLibrary.getFallbackStory(for: moment)
        }
        
        do {
            let prompt = createFolklorePrompt(for: moment)
            let response = try await session.generate(prompt: prompt)
            
            let story = parseFolkloreResponse(response, moment: moment)
            
            folkloreNarration = story
            trackEducationalEngagement(story)
            
            logger.info("Generated folklore narration for cultural moment: \(moment.type)")
            return story
            
        } catch {
            logger.error("Failed to generate folklore narration: \(error)")
            return folkloreLibrary.getFallbackStory(for: moment)
        }
    }
    
    /// Generate cultural insight for a specific card move
    func generateCulturalInsight(for move: CardMove) async -> CulturalInsight {
        let startTime = Date()
        
        defer {
            recordPerformanceMetrics(startTime: startTime, operation: .culturalInsight)
        }
        
        // Check if model is available
        guard modelAvailability == .available,
              let session = modelSession else {
            return createFallbackInsight(for: move)
        }
        
        do {
            let prompt = createCulturalInsightPrompt(for: move)
            let response = try await session.generate(prompt: prompt)
            
            let insight = parseCulturalInsightResponse(response, move: move)
            
            culturalInsights.append(insight)
            trackEducationalEngagement(insight)
            
            logger.info("Generated cultural insight for card move")
            return insight
            
        } catch {
            logger.error("Failed to generate cultural insight: \(error)")
            return createFallbackInsight(for: move)
        }
    }
    
    // MARK: - Interactive Learning
    
    /// Handle natural language questions about Romanian culture and game rules
    func answerCulturalQuestion(_ question: String) async -> CulturalAnswer {
        let startTime = Date()
        isProcessingRequest = true
        
        defer {
            isProcessingRequest = false
            recordPerformanceMetrics(startTime: startTime, operation: .questionAnswering)
        }
        
        // Check if model is available
        guard modelAvailability == .available,
              let session = modelSession else {
            return createFallbackAnswer(for: question)
        }
        
        do {
            let prompt = createQuestionAnsweringPrompt(question: question)
            let response = try await session.generate(prompt: prompt)
            
            let answer = parseQuestionAnswerResponse(response, originalQuestion: question)
            
            trackEducationalEngagement(answer)
            
            logger.info("Answered cultural question about Romanian traditions")
            return answer
            
        } catch {
            logger.error("Failed to answer cultural question: \(error)")
            return createFallbackAnswer(for: question)
        }
    }
    
    /// Create child-friendly explanations for different age groups
    func createChildFriendlyExplanation(_ rule: GameRule, ageGroup: ChildAgeGroup) async -> ChildFriendlyExplanation {
        let startTime = Date()
        
        defer {
            recordPerformanceMetrics(startTime: startTime, operation: .childExplanation)
        }
        
        // Check if model is available
        guard modelAvailability == .available,
              let session = modelSession else {
            return createFallbackChildExplanation(for: rule, ageGroup: ageGroup)
        }
        
        do {
            let prompt = createChildFriendlyPrompt(rule: rule, ageGroup: ageGroup)
            let response = try await session.generate(prompt: prompt)
            
            let explanation = parseChildFriendlyResponse(response, rule: rule, ageGroup: ageGroup)
            
            trackEducationalEngagement(explanation)
            
            logger.info("Created child-friendly explanation for age group: \(ageGroup)")
            return explanation
            
        } catch {
            logger.error("Failed to create child-friendly explanation: \(error)")
            return createFallbackChildExplanation(for: rule, ageGroup: ageGroup)
        }
    }
    
    // MARK: - Prompt Creation
    
    private func createSystemPrompt() -> String {
        return """
        You are a Romanian cultural expert and educational assistant specializing in traditional card games, particularly Septica. Your role is to:

        1. Explain game rules with authentic Romanian cultural context
        2. Share relevant folklore and traditional stories
        3. Provide educational content about Romanian heritage
        4. Adapt explanations for different age groups (children 6-12, teens 13-17, adults 18+)
        5. Always maintain cultural authenticity and respect

        Cultural Guidelines:
        - Reference authentic Romanian traditions, regions, and folklore
        - Use appropriate Romanian terms when relevant (with translations)
        - Connect game strategies to Romanian values and wisdom
        - Include seasonal and regional cultural variations
        - Maintain educational value while being engaging

        Language Guidelines:
        - Use clear, accessible language appropriate for the intended age group
        - Include Romanian cultural terms with explanations
        - Be encouraging and positive
        - Focus on the educational and cultural value of the game

        Always respond in a warm, educational tone that celebrates Romanian heritage while being inclusive and welcoming to all players.
        """
    }
    
    private func createRuleExplanationPrompt(rule: GameRule, context: CulturalContext) -> String {
        let template = ruleExplanationTemplates[rule] ?? CulturalRuleTemplate.default
        
        return """
        Explain the Septica rule: "\(rule.displayName)" with Romanian cultural context.

        Rule Details: \(rule.description)
        Current Game Context: \(context.description)
        Cultural Theme: \(context.theme)
        Player's Experience Level: \(context.playerExperience)

        Please provide:
        1. A clear explanation of how this rule works
        2. The cultural or historical reasoning behind this rule in Romanian tradition
        3. A practical example from the current game situation
        4. Any relevant Romanian folklore or traditional wisdom
        5. Tips for remembering this rule using cultural mnemonics

        Keep the explanation engaging, educational, and culturally authentic. If appropriate, include Romanian terms with translations.
        """
    }
    
    private func createFolklorePrompt(for moment: CulturalMoment) -> String {
        return """
        Create a brief Romanian folklore story or cultural explanation for this moment in the game:

        Cultural Moment: \(moment.type.displayName)
        Card Involved: \(moment.card?.displayName ?? "N/A")
        Game Situation: \(moment.gameContext)
        Cultural Significance: \(moment.culturalSignificance)

        Please create:
        1. A short (2-3 sentence) traditional Romanian story or saying that relates to this moment
        2. The cultural lesson or wisdom this moment represents
        3. How this connects to broader Romanian values or traditions

        Make it authentic, engaging, and educational while being appropriate for all ages.
        """
    }
    
    private func createCulturalInsightPrompt(for move: CardMove) -> String {
        return """
        Provide a cultural insight for this Septica card move:

        Card Played: \(move.card.displayName)
        Strategic Context: \(move.strategicReasoning ?? "N/A")
        Game State: \(move.gameStateDescription)
        
        Please provide:
        1. The traditional Romanian strategic wisdom this move represents
        2. Any cultural significance of this specific card or play pattern
        3. How this move reflects Romanian values (patience, wisdom, boldness, etc.)
        4. A brief traditional saying or proverb that applies

        Keep it concise (1-2 sentences) and culturally authentic.
        """
    }
    
    private func createQuestionAnsweringPrompt(question: String) -> String {
        return """
        Answer this question about Romanian culture and Septica:

        Question: "\(question)"

        Please provide:
        1. A clear, accurate answer
        2. Cultural context from Romanian traditions
        3. Any relevant historical background
        4. Examples from traditional Romanian card playing culture
        5. Additional interesting cultural facts if relevant

        Ensure the answer is educational, culturally authentic, and engaging.
        """
    }
    
    private func createChildFriendlyPrompt(rule: GameRule, ageGroup: ChildAgeGroup) -> String {
        let vocabularyLevel = ageGroup == .elementary ? "simple" : "intermediate"
        let culturalDepth = ageGroup == .elementary ? "basic" : "moderate"
        
        return """
        Explain the Septica rule "\(rule.displayName)" for children aged \(ageGroup.ageRange):

        Rule: \(rule.description)
        Vocabulary Level: \(vocabularyLevel)
        Cultural Depth: \(culturalDepth)

        Please create:
        1. A simple, clear explanation using age-appropriate language
        2. A fun Romanian cultural story or example that helps remember the rule
        3. An easy way to remember when to use this rule
        4. A positive encouragement about learning Romanian culture

        Make it friendly, encouraging, and educational while celebrating Romanian heritage.
        """
    }
    
    // MARK: - Response Parsing
    
    private func parseRuleExplanationResponse(_ response: String, rule: GameRule, context: CulturalContext) -> CulturalExplanation {
        return CulturalExplanation(
            id: UUID(),
            rule: rule,
            context: context,
            explanation: response,
            culturalInsights: extractCulturalInsights(from: response),
            folkloreElements: extractFolkloreElements(from: response),
            learningTips: extractLearningTips(from: response),
            ageGroup: .general,
            confidenceScore: calculateConfidenceScore(for: response),
            createdAt: Date()
        )
    }
    
    private func parseFolkloreResponse(_ response: String, moment: CulturalMoment) -> FolkloreStory {
        return FolkloreStory(
            id: UUID(),
            title: generateStoryTitle(from: moment),
            content: response,
            culturalTheme: moment.culturalTheme,
            region: extractRegion(from: response),
            moralLesson: extractMoralLesson(from: response),
            ageAppropriate: true,
            culturalAuthenticity: calculateCulturalAuthenticity(for: response),
            createdAt: Date()
        )
    }
    
    private func parseCulturalInsightResponse(_ response: String, move: CardMove) -> CulturalInsight {
        return CulturalInsight(
            id: UUID(),
            move: move,
            insight: response,
            culturalWisdom: extractCulturalWisdom(from: response),
            traditionalSaying: extractTraditionalSaying(from: response),
            strategicValue: calculateStrategicValue(for: move),
            relevanceScore: calculateRelevanceScore(for: response),
            createdAt: Date()
        )
    }
    
    private func parseQuestionAnswerResponse(_ response: String, originalQuestion: String) -> CulturalAnswer {
        return CulturalAnswer(
            id: UUID(),
            question: originalQuestion,
            answer: response,
            culturalContext: extractCulturalContext(from: response),
            historicalBackground: extractHistoricalBackground(from: response),
            additionalResources: extractAdditionalResources(from: response),
            educationalValue: calculateEducationalValue(for: response),
            createdAt: Date()
        )
    }
    
    private func parseChildFriendlyResponse(_ response: String, rule: GameRule, ageGroup: ChildAgeGroup) -> ChildFriendlyExplanation {
        return ChildFriendlyExplanation(
            id: UUID(),
            rule: rule,
            ageGroup: ageGroup,
            explanation: response,
            culturalStory: extractCulturalStory(from: response),
            memoryTrick: extractMemoryTrick(from: response),
            encouragement: extractEncouragement(from: response),
            vocabularyLevel: calculateVocabularyLevel(for: response, ageGroup: ageGroup),
            engagement: calculateEngagementScore(for: response, ageGroup: ageGroup),
            createdAt: Date()
        )
    }
    
    // MARK: - Fallback Systems
    
    private func createFallbackExplanation(for rule: GameRule, context: CulturalContext) -> CulturalExplanation {
        let template = ruleExplanationTemplates[rule] ?? CulturalRuleTemplate.default
        
        return CulturalExplanation(
            id: UUID(),
            rule: rule,
            context: context,
            explanation: template.fallbackExplanation,
            culturalInsights: template.culturalInsights,
            folkloreElements: template.folkloreElements,
            learningTips: template.learningTips,
            ageGroup: .general,
            confidenceScore: 0.7, // Lower confidence for fallback
            createdAt: Date()
        )
    }
    
    private func createFallbackInsight(for move: CardMove) -> CulturalInsight {
        return CulturalInsight(
            id: UUID(),
            move: move,
            insight: culturalKnowledgeBase.getGenericInsight(for: move.card),
            culturalWisdom: "Traditional Romanian wisdom values thoughtful play",
            traditionalSaying: "Cine se gândește bine, câștigă frumos",
            strategicValue: 0.5,
            relevanceScore: 0.6,
            createdAt: Date()
        )
    }
    
    private func createFallbackAnswer(for question: String) -> CulturalAnswer {
        return CulturalAnswer(
            id: UUID(),
            question: question,
            answer: culturalKnowledgeBase.getGenericAnswer(for: question),
            culturalContext: "Romanian cultural traditions",
            historicalBackground: "Passed down through generations",
            additionalResources: [],
            educationalValue: 0.6,
            createdAt: Date()
        )
    }
    
    private func createFallbackChildExplanation(for rule: GameRule, ageGroup: ChildAgeGroup) -> ChildFriendlyExplanation {
        let template = ruleExplanationTemplates[rule] ?? CulturalRuleTemplate.default
        
        return ChildFriendlyExplanation(
            id: UUID(),
            rule: rule,
            ageGroup: ageGroup,
            explanation: template.childFriendlyExplanation,
            culturalStory: template.childStory,
            memoryTrick: template.memoryTrick,
            encouragement: "Great job learning about Romanian traditions!",
            vocabularyLevel: ageGroup == .elementary ? 0.7 : 0.8,
            engagement: 0.7,
            createdAt: Date()
        )
    }
    
    // MARK: - Performance Monitoring
    
    private func recordPerformanceMetrics(startTime: Date, operation: IntelligenceOperation) {
        let duration = Date().timeIntervalSince(startTime)
        
        processingPerformance.recordOperation(operation, duration: duration)
        
        // Alert if performance is degrading
        if duration > 2.0 {
            logger.warning("Apple Intelligence operation took \(duration) seconds - performance impact detected")
            performanceMonitor.recordAIDecision(duration: duration)
        }
    }
    
    private func trackEducationalEngagement(_ content: EducationalContentProtocol) {
        educationalEngagement.recordEngagement(with: content)
    }
    
    // MARK: - Helper Methods
    
    private static func createRuleExplanationTemplates() -> [GameRule: CulturalRuleTemplate] {
        return [
            .sevenWild: CulturalRuleTemplate(
                fallbackExplanation: "The 7 is a special wild card in Romanian Septica, representing luck and wisdom from our traditions.",
                culturalInsights: ["Seven is considered a lucky number in Romanian folklore"],
                folkloreElements: ["The wise shepherd counted seven hills before finding the perfect grazing ground"],
                learningTips: ["Remember: 7 brings luck, just like in Romanian traditions!"],
                childFriendlyExplanation: "The 7 is like a magic card that can beat almost anything!",
                childStory: "Once upon a time, a shepherd had seven lucky sheep...",
                memoryTrick: "Seven stars in the sky, seven can reach up high!"
            ),
            .eightConditional: CulturalRuleTemplate(
                fallbackExplanation: "The 8 can beat higher cards only when there are exactly 3 cards on the table, showing Romanian patience.",
                culturalInsights: ["This rule teaches the Romanian value of waiting for the right moment"],
                folkloreElements: ["Like waiting for the harvest moon, timing is everything"],
                learningTips: ["Count to 3 like counting sheep - that's when 8 gets strong!"],
                childFriendlyExplanation: "The 8 becomes super strong when there are exactly 3 cards waiting for it!",
                childStory: "The number 8 waited patiently until exactly 3 friends arrived...",
                memoryTrick: "Eight plus three equals great!"
            )
        ]
    }
    
    // Helper methods for parsing responses
    private func extractCulturalInsights(from response: String) -> [String] {
        // Implementation would parse cultural insights from AI response
        return []
    }
    
    private func extractFolkloreElements(from response: String) -> [String] {
        // Implementation would extract folklore elements
        return []
    }
    
    private func extractLearningTips(from response: String) -> [String] {
        // Implementation would extract learning tips
        return []
    }
    
    private func calculateConfidenceScore(for response: String) -> Double {
        // Implementation would analyze response quality
        return 0.85
    }
    
    private func generateStoryTitle(from moment: CulturalMoment) -> String {
        return "The \(moment.type.displayName) Story"
    }
    
    private func extractRegion(from response: String) -> RomanianRegion? {
        // Implementation would identify regional references
        return nil
    }
    
    private func extractMoralLesson(from response: String) -> String {
        // Implementation would extract moral lessons
        return "Traditional Romanian wisdom"
    }
    
    private func calculateCulturalAuthenticity(for response: String) -> Double {
        // Implementation would assess cultural authenticity
        return 0.9
    }
    
    private func extractCulturalWisdom(from response: String) -> String {
        return "Romanian traditional wisdom"
    }
    
    private func extractTraditionalSaying(from response: String) -> String? {
        return nil
    }
    
    private func calculateStrategicValue(for move: CardMove) -> Double {
        return 0.7
    }
    
    private func calculateRelevanceScore(for response: String) -> Double {
        return 0.8
    }
    
    private func extractCulturalContext(from response: String) -> String {
        return "Romanian cultural context"
    }
    
    private func extractHistoricalBackground(from response: String) -> String {
        return "Historical Romanian background"
    }
    
    private func extractAdditionalResources(from response: String) -> [String] {
        return []
    }
    
    private func calculateEducationalValue(for response: String) -> Double {
        return 0.85
    }
    
    private func extractCulturalStory(from response: String) -> String {
        return "Cultural story for children"
    }
    
    private func extractMemoryTrick(from response: String) -> String {
        return "Memory trick"
    }
    
    private func extractEncouragement(from response: String) -> String {
        return "Great job learning!"
    }
    
    private func calculateVocabularyLevel(for response: String, ageGroup: ChildAgeGroup) -> Double {
        return ageGroup == .elementary ? 0.7 : 0.8
    }
    
    private func calculateEngagementScore(for response: String, ageGroup: ChildAgeGroup) -> Double {
        return 0.8
    }
}

// MARK: - Supporting Data Structures

// MARK: - Model Availability

enum ModelAvailabilityStatus {
    case checking
    case available
    case supported
    case unsupported
    case error
    case unknown
}

// MARK: - Cultural Explanation Structures

struct CulturalExplanation: EducationalContentProtocol {
    let id: UUID
    let rule: GameRule
    let context: CulturalContext
    let explanation: String
    let culturalInsights: [String]
    let folkloreElements: [String]
    let learningTips: [String]
    let ageGroup: AgeGroup
    let confidenceScore: Double
    let createdAt: Date
}

struct FolkloreStory: EducationalContentProtocol {
    let id: UUID
    let title: String
    let content: String
    let culturalTheme: CulturalTheme?
    let region: RomanianRegion?
    let moralLesson: String
    let ageAppropriate: Bool
    let culturalAuthenticity: Double
    let createdAt: Date
}

struct CulturalInsight: EducationalContentProtocol {
    let id: UUID
    let move: CardMove
    let insight: String
    let culturalWisdom: String
    let traditionalSaying: String?
    let strategicValue: Double
    let relevanceScore: Double
    let createdAt: Date
}

struct CulturalAnswer: EducationalContentProtocol {
    let id: UUID
    let question: String
    let answer: String
    let culturalContext: String
    let historicalBackground: String
    let additionalResources: [String]
    let educationalValue: Double
    let createdAt: Date
}

struct ChildFriendlyExplanation: EducationalContentProtocol {
    let id: UUID
    let rule: GameRule
    let ageGroup: ChildAgeGroup
    let explanation: String
    let culturalStory: String
    let memoryTrick: String
    let encouragement: String
    let vocabularyLevel: Double
    let engagement: Double
    let createdAt: Date
}

// MARK: - Context and Game Structures

struct CulturalContext {
    let theme: String
    let playerExperience: PlayerExperienceLevel
    let gamePhase: GamePhase
    let description: String
}

struct CulturalMoment {
    let type: CulturalMomentType
    let card: Card?
    let gameContext: String
    let culturalSignificance: String
    let culturalTheme: CulturalTheme?
}

enum CulturalMomentType {
    case strategicWildCard
    case perfectTiming
    case culturalTradition
    case folkloreConnection
    case seasonalReference
    
    var displayName: String {
        switch self {
        case .strategicWildCard: return "Strategic Wild Card"
        case .perfectTiming: return "Perfect Timing"
        case .culturalTradition: return "Cultural Tradition"
        case .folkloreConnection: return "Folklore Connection"
        case .seasonalReference: return "Seasonal Reference"
        }
    }
}

struct CardMove {
    let card: Card
    let strategicReasoning: String?
    let gameStateDescription: String
}

// MARK: - Game Rules

enum GameRule {
    case sevenWild
    case eightConditional
    case aceHigh
    case pointCards
    case trickTaking
    
    var displayName: String {
        switch self {
        case .sevenWild: return "Seven Wild Card"
        case .eightConditional: return "Eight Conditional"
        case .aceHigh: return "Ace High"
        case .pointCards: return "Point Cards"
        case .trickTaking: return "Trick Taking"
        }
    }
    
    var description: String {
        switch self {
        case .sevenWild: return "Sevens can beat any card except other sevens"
        case .eightConditional: return "Eights can beat higher cards when exactly 3 cards are on the table"
        case .aceHigh: return "Aces are the highest non-wild cards"
        case .pointCards: return "Tens and Aces give points when captured"
        case .trickTaking: return "Highest card wins the trick and all cards on the table"
        }
    }
}

// MARK: - Age Groups

enum AgeGroup {
    case general
    case child
    case teenager
    case adult
}

enum ChildAgeGroup {
    case elementary // 6-10
    case middle     // 11-13
    
    var ageRange: String {
        switch self {
        case .elementary: return "6-10 years"
        case .middle: return "11-13 years"
        }
    }
}

// MARK: - Player Experience

enum PlayerExperienceLevel {
    case beginner
    case intermediate
    case advanced
    case expert
}

enum GamePhase {
    case early
    case middle
    case late
    case final
}

// MARK: - Performance Metrics

struct IntelligencePerformanceMetrics {
    var operationTimes: [IntelligenceOperation: [TimeInterval]] = [:]
    var averageResponseTime: TimeInterval = 0.0
    var totalOperations: Int = 0
    var errorCount: Int = 0
    var memoryUsage: Int = 0 // KB
    
    mutating func recordOperation(_ operation: IntelligenceOperation, duration: TimeInterval) {
        operationTimes[operation, default: []].append(duration)
        totalOperations += 1
        updateAverageResponseTime()
    }
    
    private mutating func updateAverageResponseTime() {
        let allTimes = operationTimes.values.flatMap { $0 }
        averageResponseTime = allTimes.isEmpty ? 0.0 : allTimes.reduce(0, +) / Double(allTimes.count)
    }
}

struct EducationalEngagementMetrics {
    var contentViewed: Int = 0
    var questionsAsked: Int = 0
    var culturalInsightsGenerated: Int = 0
    var folkloreStoriesShared: Int = 0
    var learningSessionDuration: TimeInterval = 0
    var culturalAuthenticityScore: Double = 0.0
    
    mutating func recordEngagement(with content: EducationalContentProtocol) {
        contentViewed += 1
        // Additional engagement tracking based on content type
    }
}

enum IntelligenceOperation {
    case ruleExplanation
    case folkloreNarration
    case culturalInsight
    case questionAnswering
    case childExplanation
}

// MARK: - Cultural Templates

struct CulturalRuleTemplate {
    let fallbackExplanation: String
    let culturalInsights: [String]
    let folkloreElements: [String]
    let learningTips: [String]
    let childFriendlyExplanation: String
    let childStory: String
    let memoryTrick: String
    
    static let `default` = CulturalRuleTemplate(
        fallbackExplanation: "This is a traditional rule from Romanian Septica.",
        culturalInsights: ["This rule reflects Romanian cultural values"],
        folkloreElements: ["Traditional Romanian wisdom guides this rule"],
        learningTips: ["Remember the cultural context to master this rule"],
        childFriendlyExplanation: "This is a special rule that makes the game fun!",
        childStory: "Once upon a time in Romania...",
        memoryTrick: "Use this trick to remember!"
    )
}

// MARK: - Knowledge Base and Folklore Library

class RomanianCulturalKnowledgeBase {
    func getGenericInsight(for card: Card) -> String {
        switch card.value {
        case 7: return "The seven brings luck and wisdom in Romanian tradition"
        case 8: return "Patience is a virtue - wait for the right moment like Romanian shepherds"
        case 14: return "The ace represents mastery and leadership in Romanian culture"
        case 10: return "Ten symbolizes completion and prosperity in Romanian folklore"
        default: return "Every card has its place in the Romanian tradition of Septica"
        }
    }
    
    func getGenericAnswer(for question: String) -> String {
        return "Romanian culture is rich with traditions that have been passed down through generations. Septica is one of these beautiful cultural treasures."
    }
}

class RomanianFolkloreLibrary {
    func getFallbackStory(for moment: CulturalMoment) -> FolkloreStory {
        return FolkloreStory(
            id: UUID(),
            title: "Traditional Romanian Wisdom",
            content: "In the villages of Romania, card games like Septica have been played for generations, teaching patience, strategy, and the value of community.",
            culturalTheme: moment.culturalTheme,
            region: nil,
            moralLesson: "Traditional games connect us to our heritage",
            ageAppropriate: true,
            culturalAuthenticity: 0.8,
            createdAt: Date()
        )
    }
}

// MARK: - Educational Content Protocol

protocol EducationalContentProtocol {
    var id: UUID { get }
    var createdAt: Date { get }
}

// MARK: - Cultural Theme Structure

struct CulturalTheme {
    let name: String
    let description: String
    let region: RomanianRegion?
    let elements: [String]
}

// MARK: - Educational Content Structure

struct EducationalContent {
    let id: UUID
    let title: String
    let content: String
    let culturalLevel: CulturalLevel
    let ageGroup: AgeGroup
    let interactiveElements: [String]
    let createdAt: Date
}

enum CulturalLevel {
    case basic
    case intermediate
    case advanced
    case expert
}