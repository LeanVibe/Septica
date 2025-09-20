//
//  CulturalEngagementTracker.swift
//  Septica
//
//  Cultural Engagement Tracker for Romanian Heritage Interactions
//  Tracks and analyzes player engagement with Romanian cultural content, educational materials, and heritage preservation
//

import Foundation
import Combine
import os.log

/// Tracks and analyzes Romanian cultural engagement throughout the app experience
@MainActor
class CulturalEngagementTracker: ObservableObject {
    
    // MARK: - Dependencies
    
    private let logger = Logger(subsystem: "dev.leanvibe.game.Septica", category: "CulturalEngagementTracker")
    private let culturalLibrary: RomanianCulturalContentLibrary
    private let statisticsManager: StatisticsCloudKitManager
    
    // MARK: - Published Engagement State
    
    @Published var currentEngagementLevel: CulturalEngagementLevel = .novice
    @Published var totalEngagementScore: Float = 0.0
    @Published var dailyEngagementProgress: Float = 0.0
    @Published var weeklyEducationalGoal: Float = 0.0
    @Published var culturalStreakDays: Int = 0
    
    // MARK: - Content Interaction Tracking
    
    @Published var folkMusicListeningTime: TimeInterval = 0.0
    @Published var culturalStoriesRead: [String] = []
    @Published var educationalContentViewed: [EducationalContent] = []
    @Published var traditionalPatternsLearned: [String] = []
    @Published var culturalQuizzesTaken: [CulturalQuiz] = []
    
    // MARK: - Regional Cultural Exploration
    
    @Published var exploredRegions: Set<RomanianRegion> = []
    @Published var regionalExpertise: [RomanianRegion: Float] = [:]
    @Published var preferredCulturalThemes: [CulturalTheme] = []
    @Published var culturalCuriosityScore: Float = 0.0
    
    // MARK: - Heritage Preservation Metrics
    
    @Published var heritagePreservationContributions: [HeritageContribution] = []
    @Published var culturalKnowledgeSharing: [KnowledgeShare] = []
    @Published var traditionalMusicPreference: Float = 0.0
    @Published var folkArtInteraction: Float = 0.0
    
    // MARK: - Learning Progress Tracking
    
    private var learningSessionData: LearningSessionData
    private var engagementHistory: [EngagementSession] = []
    private var culturalMilestones: [CulturalMilestone] = []
    
    // MARK: - Real-time Analytics
    
    private var currentSession: EngagementSession?
    private var sessionStartTime: Date?
    private var dailyEngagementTimer: Timer?
    
    // MARK: - Initialization
    
    init(culturalLibrary: RomanianCulturalContentLibrary, statisticsManager: StatisticsCloudKitManager) {
        self.culturalLibrary = culturalLibrary
        self.statisticsManager = statisticsManager
        self.learningSessionData = LearningSessionData()
        
        setupEngagementTracking()
        loadStoredEngagementData()
        startDailyEngagementTracking()
    }
    
    // MARK: - Setup & Configuration
    
    private func setupEngagementTracking() {
        // Setup observers for cultural interactions
        NotificationCenter.default.addObserver(
            forName: .culturalContentInteraction,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleCulturalInteraction(notification)
        }
        
        NotificationCenter.default.addObserver(
            forName: .educationalContentViewed,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleEducationalContent(notification)
        }
        
        NotificationCenter.default.addObserver(
            forName: .folkMusicPlayed,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleFolkMusicListening(notification)
        }
        
        logger.info("Cultural engagement tracking initialized")
    }
    
    private func loadStoredEngagementData() {
        Task {
            await loadPreviousEngagementHistory()
            await calculateCurrentEngagementLevel()
            await updateCulturalStreak()
        }
    }
    
    private func startDailyEngagementTracking() {
        // Reset daily progress at midnight
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        let midnight = calendar.startOfDay(for: tomorrow)
        
        dailyEngagementTimer = Timer(fireAt: midnight, interval: 24 * 60 * 60, target: self, selector: #selector(resetDailyProgress), userInfo: nil, repeats: true)
        
        if let timer = dailyEngagementTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    @objc private func resetDailyProgress() {
        dailyEngagementProgress = 0.0
        updateCulturalStreak()
    }
    
    // MARK: - Session Management
    
    func startEngagementSession() {
        let session = EngagementSession(
            sessionId: UUID(),
            startTime: Date(),
            sessionType: .general,
            initialEngagementLevel: currentEngagementLevel
        )
        
        currentSession = session
        sessionStartTime = Date()
        
        logger.info("Started cultural engagement session")
    }
    
    func endEngagementSession() {
        guard var session = currentSession else { return }
        
        session.endTime = Date()
        session.finalEngagementLevel = currentEngagementLevel
        session.totalEngagementGained = calculateSessionEngagement(session)
        session.culturalActivitiesCompleted = getCurrentSessionActivities()
        
        // Store session data
        engagementHistory.append(session)
        learningSessionData.addSession(session)
        
        // Sync to CloudKit
        Task {
            await syncEngagementSession(session)
        }
        
        currentSession = nil
        sessionStartTime = nil
        
        logger.info("Ended cultural engagement session with \(session.totalEngagementGained) engagement points")
    }
    
    // MARK: - Content Interaction Handlers
    
    private func handleCulturalInteraction(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let interactionType = userInfo["type"] as? String,
              let content = userInfo["content"] as? String else { return }
        
        let interaction = CulturalInteraction(
            type: CulturalInteractionType(rawValue: interactionType) ?? .unknown,
            content: content,
            timestamp: Date(),
            duration: userInfo["duration"] as? TimeInterval ?? 0,
            engagement_level: calculateInteractionEngagement(interactionType, content)
        )
        
        processCulturalInteraction(interaction)
    }
    
    private func handleEducationalContent(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let contentId = userInfo["contentId"] as? String,
              let contentType = userInfo["type"] as? String else { return }
        
        let content = EducationalContent(
            id: contentId,
            type: EducationalContentType(rawValue: contentType) ?? .generalKnowledge,
            title: userInfo["title"] as? String ?? "",
            culturalRegion: RomanianRegion(rawValue: userInfo["region"] as? String ?? ""),
            difficultyLevel: LearningDifficulty(rawValue: userInfo["difficulty"] as? String ?? "") ?? .beginner,
            completionTime: userInfo["duration"] as? TimeInterval ?? 0,
            comprehensionScore: userInfo["score"] as? Float ?? 0.0,
            viewedAt: Date()
        )
        
        processEducationalContent(content)
    }
    
    private func handleFolkMusicListening(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let trackName = userInfo["track"] as? String,
              let duration = userInfo["duration"] as? TimeInterval else { return }
        
        let musicInteraction = FolkMusicInteraction(
            trackName: trackName,
            region: extractRegionFromTrack(trackName),
            listeningDuration: duration,
            userRating: userInfo["rating"] as? Float,
            timestamp: Date()
        )
        
        processFolkMusicInteraction(musicInteraction)
    }
    
    // MARK: - Interaction Processing
    
    private func processCulturalInteraction(_ interaction: CulturalInteraction) {
        // Update engagement scores
        totalEngagementScore += interaction.engagement_level
        dailyEngagementProgress += interaction.engagement_level * 0.1
        
        // Track specific interaction types
        switch interaction.type {
        case .traditionalPattern:
            if !traditionalPatternsLearned.contains(interaction.content) {
                traditionalPatternsLearned.append(interaction.content)
                awardCulturalMilestone(.traditionaPatternMastery, content: interaction.content)
            }
            
        case .culturalStory:
            if !culturalStoriesRead.contains(interaction.content) {
                culturalStoriesRead.append(interaction.content)
                awardCulturalMilestone(.culturalStoryCompletion, content: interaction.content)
            }
            
        case .regionalExploration:
            if let region = RomanianRegion(rawValue: interaction.content) {
                exploreRegion(region, engagementLevel: interaction.engagement_level)
            }
            
        case .folkArtInteraction:
            folkArtInteraction += interaction.engagement_level * 0.2
            
        case .culturalQuiz:
            if let quiz = createQuizFromInteraction(interaction) {
                culturalQuizzesTaken.append(quiz)
            }
            
        case .heritageContribution:
            addHeritageContribution(interaction)
            
        case .unknown:
            break
        }
        
        // Update cultural curiosity
        updateCulturalCuriosity(for: interaction)
        
        // Check for engagement level progression
        checkEngagementLevelProgression()
    }
    
    private func processEducationalContent(_ content: EducationalContent) {
        educationalContentViewed.append(content)
        
        // Award engagement points based on content type and comprehension
        let basePoints = getBasePointsForContent(content.type)
        let comprehensionMultiplier = content.comprehensionScore
        let engagementPoints = basePoints * comprehensionMultiplier
        
        totalEngagementScore += engagementPoints
        dailyEngagementProgress += engagementPoints * 0.15
        
        // Update regional expertise if applicable
        if let region = content.culturalRegion {
            updateRegionalExpertise(region, points: engagementPoints)
        }
        
        // Update weekly educational goal
        weeklyEducationalGoal = min(1.0, weeklyEducationalGoal + 0.1)
        
        // Check for educational milestones
        checkEducationalMilestones(content)
        
        logger.info("Processed educational content: \(content.title) (\(engagementPoints) points)")
    }
    
    private func processFolkMusicInteraction(_ interaction: FolkMusicInteraction) {
        folkMusicListeningTime += interaction.listeningDuration
        
        // Calculate engagement based on listening duration and user rating
        let durationScore = min(1.0, Float(interaction.listeningDuration) / 180.0) // Max 3 minutes
        let ratingScore = interaction.userRating ?? 0.5
        let engagementPoints = (durationScore + ratingScore) * 5.0
        
        totalEngagementScore += engagementPoints
        traditionalMusicPreference += engagementPoints * 0.1
        
        // Update regional expertise based on music origin
        if let region = interaction.region {
            updateRegionalExpertise(region, points: engagementPoints * 0.5)
        }
        
        // Check for music appreciation milestones
        checkMusicAppreciationMilestones(interaction)
    }
    
    // MARK: - Regional Exploration
    
    private func exploreRegion(_ region: RomanianRegion, engagementLevel: Float) {
        exploredRegions.insert(region)
        updateRegionalExpertise(region, points: engagementLevel)
        
        // Check if this unlocks new cultural content
        checkRegionalUnlocks(region)
        
        // Award exploration milestone
        if exploredRegions.count == RomanianRegion.allCases.count {
            awardCulturalMilestone(.regionalExplorer, content: "All Romanian regions explored")
        }
    }
    
    private func updateRegionalExpertise(_ region: RomanianRegion, points: Float) {
        let currentExpertise = regionalExpertise[region] ?? 0.0
        regionalExpertise[region] = min(1.0, currentExpertise + points * 0.02)
        
        // Check for regional mastery
        if regionalExpertise[region]! >= 0.8 {
            awardCulturalMilestone(.regionalMastery, content: "Mastered \(region.displayName) culture")
        }
    }
    
    private func checkRegionalUnlocks(_ region: RomanianRegion) {
        // Unlock region-specific content based on exploration
        let expertise = regionalExpertise[region] ?? 0.0
        
        if expertise >= 0.3 {
            unlockRegionalContent(region, tier: .intermediate)
        }
        
        if expertise >= 0.6 {
            unlockRegionalContent(region, tier: .advanced)
        }
        
        if expertise >= 0.9 {
            unlockRegionalContent(region, tier: .master)
        }
    }
    
    private func unlockRegionalContent(_ region: RomanianRegion, tier: ContentTier) {
        let unlockEvent = ContentUnlockEvent(
            region: region,
            tier: tier,
            unlockedAt: Date(),
            triggerType: .expertiseLevel
        )
        
        NotificationCenter.default.post(
            name: .regionalContentUnlocked,
            object: unlockEvent
        )
        
        logger.info("Unlocked \(tier) content for \(region.displayName)")
    }
    
    // MARK: - Cultural Milestones & Achievements
    
    private func awardCulturalMilestone(_ type: CulturalMilestoneType, content: String) {
        let milestone = CulturalMilestone(
            name: type.displayName,
            achievedDate: Date(),
            culturalSignificance: type.culturalSignificance,
            rewardUnlocked: type.reward
        )
        
        culturalMilestones.append(milestone)
        
        // Award bonus engagement points
        totalEngagementScore += type.bonusPoints
        
        // Notify UI for celebration
        NotificationCenter.default.post(
            name: .culturalMilestoneAchieved,
            object: milestone
        )
        
        logger.info("Cultural milestone achieved: \(type.displayName)")
    }
    
    private func checkEngagementLevelProgression() {
        let newLevel = calculateEngagementLevel(totalEngagementScore)
        
        if newLevel != currentEngagementLevel {
            let previousLevel = currentEngagementLevel
            currentEngagementLevel = newLevel
            
            // Award level progression milestone
            awardCulturalMilestone(.engagementLevelUp, content: "Advanced to \(newLevel.displayName)")
            
            // Unlock level-specific content
            unlockLevelContent(newLevel)
            
            NotificationCenter.default.post(
                name: .culturalEngagementLevelUp,
                object: EngagementLevelUpEvent(
                    previousLevel: previousLevel,
                    newLevel: newLevel,
                    totalScore: totalEngagementScore
                )
            )
        }
    }
    
    private func checkEducationalMilestones(_ content: EducationalContent) {
        // Check for various educational achievements
        let totalEducationalTime = educationalContentViewed.reduce(0) { $0 + $1.completionTime }
        
        if totalEducationalTime >= 3600 { // 1 hour
            awardCulturalMilestone(.educationalDedication, content: "1 hour of educational content")
        }
        
        if educationalContentViewed.count >= 50 {
            awardCulturalMilestone(.knowledgeSeeker, content: "50 educational pieces completed")
        }
        
        // Check for high comprehension scores
        let highScoreContent = educationalContentViewed.filter { $0.comprehensionScore >= 0.9 }
        if highScoreContent.count >= 10 {
            awardCulturalMilestone(.culturalScholar, content: "10 perfect comprehension scores")
        }
    }
    
    private func checkMusicAppreciationMilestones(_ interaction: FolkMusicInteraction) {
        // Check music listening milestones
        if folkMusicListeningTime >= 7200 { // 2 hours
            awardCulturalMilestone(.musicAppreciator, content: "2 hours of folk music")
        }
        
        // Check for regional music diversity
        let uniqueRegions = Set(engagementHistory.compactMap { $0.musicInteractions.compactMap { $0.region } })
        if uniqueRegions.count >= 3 {
            awardCulturalMilestone(.musicalExplorer, content: "Music from 3+ regions")
        }
    }
    
    // MARK: - Heritage Preservation
    
    private func addHeritageContribution(_ interaction: CulturalInteraction) {
        let contribution = HeritageContribution(
            type: .knowledgeSharing,
            content: interaction.content,
            culturalValue: interaction.engagement_level,
            timestamp: Date(),
            verificationStatus: .pending
        )
        
        heritagePreservationContributions.append(contribution)
        
        // Award extra engagement for heritage preservation
        totalEngagementScore += interaction.engagement_level * 1.5
        
        // Check for heritage preservation milestones
        if heritagePreservationContributions.count >= 5 {
            awardCulturalMilestone(.heritagePreserver, content: "5 heritage contributions")
        }
    }
    
    func shareKnowledge(_ knowledge: CulturalKnowledge, with recipient: String) {
        let share = KnowledgeShare(
            knowledge: knowledge,
            recipient: recipient,
            sharedAt: Date(),
            culturalImpact: calculateKnowledgeImpact(knowledge)
        )
        
        culturalKnowledgeSharing.append(share)
        
        // Award significant engagement for knowledge sharing
        totalEngagementScore += share.culturalImpact * 10.0
        
        // Update cultural curiosity
        culturalCuriosityScore += 0.1
        
        awardCulturalMilestone(.culturalAmbassador, content: "Shared knowledge with \(recipient)")
        
        logger.info("Knowledge shared: \(knowledge.title)")
    }
    
    // MARK: - Analytics & Insights
    
    func getCulturalEngagementReport() -> CulturalEngagementReport {
        return CulturalEngagementReport(
            currentLevel: currentEngagementLevel,
            totalScore: totalEngagementScore,
            dailyProgress: dailyEngagementProgress,
            weeklyGoalProgress: weeklyEducationalGoal,
            streakDays: culturalStreakDays,
            exploredRegions: Array(exploredRegions),
            regionalExpertise: regionalExpertise,
            contentInteractionSummary: getContentInteractionSummary(),
            milestones: culturalMilestones,
            recommendations: generatePersonalizedRecommendations()
        )
    }
    
    private func getContentInteractionSummary() -> ContentInteractionSummary {
        return ContentInteractionSummary(
            storiesRead: culturalStoriesRead.count,
            educationalContentViewed: educationalContentViewed.count,
            folkMusicListeningTime: folkMusicListeningTime,
            quizzesTaken: culturalQuizzesTaken.count,
            traditionalPatternsLearned: traditionalPatternsLearned.count,
            averageComprehensionScore: calculateAverageComprehension()
        )
    }
    
    private func generatePersonalizedRecommendations() -> [CulturalRecommendation] {
        var recommendations: [CulturalRecommendation] = []
        
        // Recommend unexplored regions
        let unexploredRegions = Set(RomanianRegion.allCases).subtracting(exploredRegions)
        for region in unexploredRegions.prefix(2) {
            recommendations.append(CulturalRecommendation(
                type: .regionalExploration,
                title: "Explore \(region.displayName)",
                description: "Discover the unique cultural heritage of \(region.displayName)",
                estimatedEngagement: 15.0,
                culturalValue: .high
            ))
        }
        
        // Recommend improving weak areas
        if traditionalMusicPreference < 0.5 {
            recommendations.append(CulturalRecommendation(
                type: .musicAppreciation,
                title: "Discover Romanian Folk Music",
                description: "Explore traditional music from different Romanian regions",
                estimatedEngagement: 10.0,
                culturalValue: .medium
            ))
        }
        
        // Recommend advanced content for high performers
        if currentEngagementLevel.rawValue >= 3 {
            recommendations.append(CulturalRecommendation(
                type: .advancedLearning,
                title: "Master Traditional Strategies",
                description: "Learn advanced Romanian Septica techniques",
                estimatedEngagement: 25.0,
                culturalValue: .high
            ))
        }
        
        return recommendations
    }
    
    // MARK: - Data Persistence & Sync
    
    private func syncEngagementSession(_ session: EngagementSession) async {
        do {
            // Convert session to cultural statistics
            let statistics = convertSessionToStatistics(session)
            
            // Sync to CloudKit
            try await statisticsManager.syncCulturalStatistics(statistics)
            
            logger.info("Successfully synced engagement session to CloudKit")
            
        } catch {
            logger.error("Failed to sync engagement session: \(error)")
        }
    }
    
    private func convertSessionToStatistics(_ session: EngagementSession) -> [CulturalStatistic] {
        var statistics: [CulturalStatistic] = []
        
        // Session engagement statistic
        statistics.append(CulturalStatistic(
            id: UUID(),
            playerId: session.sessionId, // Using session ID as player ID for now
            type: .culturalEngagement,
            value: Double(session.totalEngagementGained),
            culturalContext: "Engagement session (\(session.sessionType.rawValue))",
            timestamp: session.startTime,
            deviceId: UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        ))
        
        return statistics
    }
    
    private func loadPreviousEngagementHistory() async {
        // Load from local storage or CloudKit
        // This would integrate with the app's data persistence layer
        logger.info("Loaded previous engagement history")
    }
    
    private func calculateCurrentEngagementLevel() async {
        currentEngagementLevel = calculateEngagementLevel(totalEngagementScore)
    }
    
    private func updateCulturalStreak() async {
        // Check if user engaged with cultural content today
        let today = Calendar.current.startOfDay(for: Date())
        let hasEngagementToday = engagementHistory.contains { session in
            Calendar.current.isDate(session.startTime, inSameDayAs: today)
        }
        
        if hasEngagementToday {
            culturalStreakDays += 1
        } else {
            culturalStreakDays = 0
        }
    }
    
    // MARK: - Helper Methods
    
    private func calculateEngagementLevel(_ score: Float) -> CulturalEngagementLevel {
        switch score {
        case 0..<25: return .novice
        case 25..<75: return .apprentice
        case 75..<150: return .practitioner
        case 150..<300: return .enthusiast
        case 300..<500: return .expert
        case 500..<750: return .scholar
        case 750..<1000: return .master
        default: return .guardian
        }
    }
    
    private func calculateInteractionEngagement(_ type: String, _ content: String) -> Float {
        switch type {
        case "traditionalPattern": return 8.0
        case "culturalStory": return 12.0
        case "regionalExploration": return 15.0
        case "folkArtInteraction": return 6.0
        case "culturalQuiz": return 10.0
        case "heritageContribution": return 20.0
        default: return 3.0
        }
    }
    
    private func getBasePointsForContent(_ type: EducationalContentType) -> Float {
        switch type {
        case .generalKnowledge: return 5.0
        case .traditionalStrategies: return 12.0
        case .regionalHistory: return 8.0
        case .folkTales: return 10.0
        case .musicTheory: return 7.0
        case .culturalContext: return 15.0
        }
    }
    
    private func extractRegionFromTrack(_ trackName: String) -> RomanianRegion? {
        // Simple region extraction based on track naming conventions
        if trackName.contains("moldovenesc") || trackName.contains("moldova") {
            return .moldovan
        } else if trackName.contains("ardelean") || trackName.contains("ardeal") {
            return .transylvanian
        } else if trackName.contains("muntean") || trackName.contains("wallachia") {
            return .wallachian
        }
        return nil
    }
    
    private func createQuizFromInteraction(_ interaction: CulturalInteraction) -> CulturalQuiz? {
        // Create quiz object from interaction data
        return CulturalQuiz(
            id: UUID().uuidString,
            topic: interaction.content,
            difficulty: .intermediate,
            score: interaction.engagement_level / 10.0,
            completedAt: interaction.timestamp
        )
    }
    
    private func updateCulturalCuriosity(for interaction: CulturalInteraction) {
        // Increase curiosity based on interaction diversity
        let diversityBonus = calculateDiversityBonus(interaction)
        culturalCuriosityScore = min(1.0, culturalCuriosityScore + diversityBonus)
    }
    
    private func calculateDiversityBonus(_ interaction: CulturalInteraction) -> Float {
        // Calculate bonus based on trying new types of cultural content
        let recentInteractionTypes = engagementHistory.suffix(10).flatMap { $0.culturalActivitiesCompleted.map { $0.type } }
        let uniqueTypes = Set(recentInteractionTypes + [interaction.type])
        
        return Float(uniqueTypes.count) * 0.02
    }
    
    private func calculateSessionEngagement(_ session: EngagementSession) -> Float {
        // Calculate total engagement gained during the session
        let duration = session.endTime?.timeIntervalSince(session.startTime) ?? 0
        let baseEngagement = Float(duration) / 60.0 // 1 point per minute
        
        // Add bonus for cultural activities
        let activityBonus = session.culturalActivitiesCompleted.reduce(0) { $0 + $1.engagement_level }
        
        return baseEngagement + activityBonus
    }
    
    private func getCurrentSessionActivities() -> [CulturalInteraction] {
        // Return activities completed in current session
        guard let startTime = sessionStartTime else { return [] }
        
        // This would track activities during the current session
        // For now, return empty array
        return []
    }
    
    private func calculateKnowledgeImpact(_ knowledge: CulturalKnowledge) -> Float {
        // Calculate cultural impact of shared knowledge
        let baseImpact: Float = 1.0
        let rarityMultiplier = knowledge.rarity.multiplier
        let accuracyMultiplier = knowledge.accuracy
        
        return baseImpact * rarityMultiplier * accuracyMultiplier
    }
    
    private func unlockLevelContent(_ level: CulturalEngagementLevel) {
        // Unlock content based on engagement level
        let unlockEvent = LevelContentUnlockEvent(
            level: level,
            unlockedContent: level.unlockedContent,
            unlockedAt: Date()
        )
        
        NotificationCenter.default.post(
            name: .engagementLevelContentUnlocked,
            object: unlockEvent
        )
    }
    
    private func calculateAverageComprehension() -> Float {
        guard !educationalContentViewed.isEmpty else { return 0.0 }
        
        let totalScore = educationalContentViewed.reduce(0) { $0 + $1.comprehensionScore }
        return totalScore / Float(educationalContentViewed.count)
    }
}

// MARK: - Supporting Data Structures

enum CulturalEngagementLevel: Int, CaseIterable {
    case novice = 0
    case apprentice = 1
    case practitioner = 2
    case enthusiast = 3
    case expert = 4
    case scholar = 5
    case master = 6
    case guardian = 7
    
    var displayName: String {
        switch self {
        case .novice: return "Novice Cultural Explorer"
        case .apprentice: return "Cultural Apprentice"
        case .practitioner: return "Cultural Practitioner"
        case .enthusiast: return "Heritage Enthusiast"
        case .expert: return "Cultural Expert"
        case .scholar: return "Cultural Scholar"
        case .master: return "Heritage Master"
        case .guardian: return "Cultural Guardian"
        }
    }
    
    var unlockedContent: [String] {
        switch self {
        case .novice: return ["basic_folk_music", "simple_stories"]
        case .apprentice: return ["regional_music", "traditional_patterns"]
        case .practitioner: return ["advanced_stories", "cultural_quizzes"]
        case .enthusiast: return ["expert_strategies", "regional_specialties"]
        case .expert: return ["master_techniques", "cultural_mentoring"]
        case .scholar: return ["research_access", "scholarly_content"]
        case .master: return ["exclusive_archives", "master_classes"]
        case .guardian: return ["all_content", "curator_privileges"]
        }
    }
}

struct CulturalInteraction {
    let type: CulturalInteractionType
    let content: String
    let timestamp: Date
    let duration: TimeInterval
    let engagement_level: Float
}

enum CulturalInteractionType: String {
    case traditionalPattern = "traditional_pattern"
    case culturalStory = "cultural_story"
    case regionalExploration = "regional_exploration"
    case folkArtInteraction = "folk_art_interaction"
    case culturalQuiz = "cultural_quiz"
    case heritageContribution = "heritage_contribution"
    case unknown = "unknown"
}

struct EducationalContent {
    let id: String
    let type: EducationalContentType
    let title: String
    let culturalRegion: RomanianRegion?
    let difficultyLevel: LearningDifficulty
    let completionTime: TimeInterval
    let comprehensionScore: Float
    let viewedAt: Date
}

enum EducationalContentType: String {
    case generalKnowledge = "general_knowledge"
    case traditionalStrategies = "traditional_strategies"
    case regionalHistory = "regional_history"
    case folkTales = "folk_tales"
    case musicTheory = "music_theory"
    case culturalContext = "cultural_context"
}

struct FolkMusicInteraction {
    let trackName: String
    let region: RomanianRegion?
    let listeningDuration: TimeInterval
    let userRating: Float?
    let timestamp: Date
}

struct CulturalQuiz {
    let id: String
    let topic: String
    let difficulty: LearningDifficulty
    let score: Float
    let completedAt: Date
}

struct HeritageContribution {
    let type: ContributionType
    let content: String
    let culturalValue: Float
    let timestamp: Date
    var verificationStatus: VerificationStatus
    
    enum ContributionType {
        case knowledgeSharing
        case traditionalTechnique
        case culturalTranslation
        case historicalCorrection
    }
    
    enum VerificationStatus {
        case pending
        case verified
        case rejected
    }
}

struct KnowledgeShare {
    let knowledge: CulturalKnowledge
    let recipient: String
    let sharedAt: Date
    let culturalImpact: Float
}

struct CulturalKnowledge {
    let title: String
    let content: String
    let rarity: KnowledgeRarity
    let accuracy: Float
    let culturalRegion: RomanianRegion?
    
    enum KnowledgeRarity {
        case common
        case uncommon
        case rare
        case legendary
        
        var multiplier: Float {
            switch self {
            case .common: return 1.0
            case .uncommon: return 1.5
            case .rare: return 2.0
            case .legendary: return 3.0
            }
        }
    }
}

struct LearningSessionData {
    private var sessions: [EngagementSession] = []
    
    mutating func addSession(_ session: EngagementSession) {
        sessions.append(session)
    }
    
    func getAverageSessionDuration() -> TimeInterval {
        guard !sessions.isEmpty else { return 0 }
        
        let totalDuration = sessions.compactMap { session in
            session.endTime?.timeIntervalSince(session.startTime)
        }.reduce(0, +)
        
        return totalDuration / Double(sessions.count)
    }
    
    func getTotalLearningTime() -> TimeInterval {
        return sessions.compactMap { session in
            session.endTime?.timeIntervalSince(session.startTime)
        }.reduce(0, +)
    }
}

struct EngagementSession {
    let sessionId: UUID
    let startTime: Date
    var endTime: Date?
    let sessionType: SessionType
    let initialEngagementLevel: CulturalEngagementLevel
    var finalEngagementLevel: CulturalEngagementLevel?
    var totalEngagementGained: Float = 0.0
    var culturalActivitiesCompleted: [CulturalInteraction] = []
    var educationalContentViewed: [EducationalContent] = []
    var musicInteractions: [FolkMusicInteraction] = []
    
    enum SessionType: String {
        case general = "general"
        case focused_learning = "focused_learning"
        case cultural_exploration = "cultural_exploration"
        case music_appreciation = "music_appreciation"
        case heritage_contribution = "heritage_contribution"
    }
}

enum CulturalMilestoneType {
    case traditionaPatternMastery
    case culturalStoryCompletion
    case regionalExplorer
    case regionalMastery
    case engagementLevelUp
    case educationalDedication
    case knowledgeSeeker
    case culturalScholar
    case musicAppreciator
    case musicalExplorer
    case heritagePreserver
    case culturalAmbassador
    
    var displayName: String {
        switch self {
        case .traditionaPatternMastery: return "Traditional Pattern Master"
        case .culturalStoryCompletion: return "Story Enthusiast"
        case .regionalExplorer: return "Regional Explorer"
        case .regionalMastery: return "Regional Master"
        case .engagementLevelUp: return "Cultural Advancement"
        case .educationalDedication: return "Dedicated Learner"
        case .knowledgeSeeker: return "Knowledge Seeker"
        case .culturalScholar: return "Cultural Scholar"
        case .musicAppreciator: return "Music Appreciator"
        case .musicalExplorer: return "Musical Explorer"
        case .heritagePreserver: return "Heritage Preservationist"
        case .culturalAmbassador: return "Cultural Ambassador"
        }
    }
    
    var culturalSignificance: String {
        switch self {
        case .traditionaPatternMastery: return "Mastered traditional Romanian Septica patterns"
        case .culturalStoryCompletion: return "Engaged deeply with Romanian folk tales"
        case .regionalExplorer: return "Explored all Romanian cultural regions"
        case .regionalMastery: return "Achieved mastery in a specific Romanian region"
        case .engagementLevelUp: return "Advanced in cultural understanding"
        case .educationalDedication: return "Demonstrated commitment to cultural learning"
        case .knowledgeSeeker: return "Actively pursued cultural knowledge"
        case .culturalScholar: return "Achieved scholarly understanding of Romanian culture"
        case .musicAppreciator: return "Developed appreciation for Romanian folk music"
        case .musicalExplorer: return "Explored diverse Romanian musical traditions"
        case .heritagePreserver: return "Contributed to preserving Romanian heritage"
        case .culturalAmbassador: return "Shared Romanian culture with others"
        }
    }
    
    var reward: String {
        switch self {
        case .traditionaPatternMastery: return "Traditional Pattern Badge"
        case .culturalStoryCompletion: return "Storyteller Badge"
        case .regionalExplorer: return "Explorer Badge"
        case .regionalMastery: return "Regional Master Badge"
        case .engagementLevelUp: return "Level Badge"
        case .educationalDedication: return "Dedication Badge"
        case .knowledgeSeeker: return "Seeker Badge"
        case .culturalScholar: return "Scholar Badge"
        case .musicAppreciator: return "Music Badge"
        case .musicalExplorer: return "Musical Explorer Badge"
        case .heritagePreserver: return "Preservationist Badge"
        case .culturalAmbassador: return "Ambassador Badge"
        }
    }
    
    var bonusPoints: Float {
        switch self {
        case .traditionaPatternMastery: return 15.0
        case .culturalStoryCompletion: return 10.0
        case .regionalExplorer: return 25.0
        case .regionalMastery: return 20.0
        case .engagementLevelUp: return 30.0
        case .educationalDedication: return 15.0
        case .knowledgeSeeker: return 20.0
        case .culturalScholar: return 25.0
        case .musicAppreciator: return 12.0
        case .musicalExplorer: return 18.0
        case .heritagePreserver: return 30.0
        case .culturalAmbassador: return 35.0
        }
    }
}

enum CulturalTheme {
    case folkMusic
    case traditionalCrafts
    case regionalCuisine
    case historicalEvents
    case folklore
    case architecture
    case festivals
    case language
}

enum ContentTier {
    case beginner
    case intermediate
    case advanced
    case master
}

struct ContentUnlockEvent {
    let region: RomanianRegion
    let tier: ContentTier
    let unlockedAt: Date
    let triggerType: UnlockTriggerType
    
    enum UnlockTriggerType {
        case expertiseLevel
        case milestone
        case special_event
    }
}

struct EngagementLevelUpEvent {
    let previousLevel: CulturalEngagementLevel
    let newLevel: CulturalEngagementLevel
    let totalScore: Float
}

struct LevelContentUnlockEvent {
    let level: CulturalEngagementLevel
    let unlockedContent: [String]
    let unlockedAt: Date
}

struct CulturalEngagementReport {
    let currentLevel: CulturalEngagementLevel
    let totalScore: Float
    let dailyProgress: Float
    let weeklyGoalProgress: Float
    let streakDays: Int
    let exploredRegions: [RomanianRegion]
    let regionalExpertise: [RomanianRegion: Float]
    let contentInteractionSummary: ContentInteractionSummary
    let milestones: [CulturalMilestone]
    let recommendations: [CulturalRecommendation]
}

struct ContentInteractionSummary {
    let storiesRead: Int
    let educationalContentViewed: Int
    let folkMusicListeningTime: TimeInterval
    let quizzesTaken: Int
    let traditionalPatternsLearned: Int
    let averageComprehensionScore: Float
}

struct CulturalRecommendation {
    let type: RecommendationType
    let title: String
    let description: String
    let estimatedEngagement: Float
    let culturalValue: CulturalValue
    
    enum RecommendationType {
        case regionalExploration
        case musicAppreciation
        case advancedLearning
        case heritageContribution
        case socialSharing
    }
    
    enum CulturalValue {
        case low
        case medium
        case high
        case exceptional
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let culturalContentInteraction = Notification.Name("culturalContentInteraction")
    static let educationalContentViewed = Notification.Name("educationalContentViewed")
    static let folkMusicPlayed = Notification.Name("folkMusicPlayed")
    static let regionalContentUnlocked = Notification.Name("regionalContentUnlocked")
    static let culturalMilestoneAchieved = Notification.Name("culturalMilestoneAchieved")
    static let culturalEngagementLevelUp = Notification.Name("culturalEngagementLevelUp")
    static let engagementLevelContentUnlocked = Notification.Name("engagementLevelContentUnlocked")
}

// MARK: - Extensions

extension RomanianRegion {
    var displayName: String {
        switch self {
        case .moldovan: return "Moldova"
        case .transylvanian: return "Transilvania"
        case .wallachian: return "Muntenia"
        case .dobrudjan: return "Dobrogea"
        case .banat: return "Banat"
        }
    }
    
    static var allCases: [RomanianRegion] {
        return [.moldovan, .transylvanian, .wallachian, .dobrudjan, .banat]
    }
}