//
//  RomanianCulturalAchievementManager.swift
//  Septica
//
//  Romanian Cultural Achievement System - Sprint 3 Week 10
//  Comprehensive heritage achievement tracking with educational value
//

import Foundation
import Combine
import os.log

/// Romanian cultural achievement manager with educational heritage integration
@MainActor
class RomanianCulturalAchievementManager: ObservableObject {
    
    // MARK: - Dependencies
    
    private let logger = Logger(subsystem: "dev.leanvibe.game.Septica", category: "RomanianCulturalAchievementManager")
    
    // MARK: - Published Achievement State
    
    @Published var unlockedAchievements: [RomanianAchievement] = []
    @Published var progressAchievements: [AchievementProgress] = []
    @Published var availableAchievements: [RomanianAchievement] = []
    
    // MARK: - Player Progress Tracking
    
    @Published var currentPlayerId: UUID = UUID()
    @Published var totalExperiencePoints: Int = 0
    @Published var totalCulturalKnowledgePoints: Int = 0
    @Published var completedAchievementIds: Set<UUID> = []
    
    // MARK: - Achievement Registry
    
    private let achievementRegistry = AchievementRegistry.shared
    
    // MARK: - Initialization
    
    init() {
        setupDefaultAchievements()
        loadPlayerProgress()
    }
    
    // MARK: - Achievement Setup
    
    private func setupDefaultAchievements() {
        // Register some basic achievements for testing
        let firstSteps = RomanianAchievement(
            type: .gameplay,
            category: .gameWins,
            difficulty: .bronze,
            culturalRegion: nil,
            titleKey: "achievement_first_steps_title",
            descriptionKey: "achievement_first_steps_desc",
            culturalContextKey: "achievement_first_steps_context",
            requirements: [.gamesPlayed(count: 1)],
            targetValue: 1,
            experiencePoints: 10,
            culturalKnowledgePoints: 5,
            badge: AchievementBadge(iconName: "star.fill", colorScheme: .bronze)
        )
        
        let cardVirtuoso = RomanianAchievement(
            type: .gameplay,
            category: .cardMastery,
            difficulty: .gold,
            culturalRegion: .transylvania,
            titleKey: "achievement_card_virtuoso_title",
            descriptionKey: "achievement_card_virtuoso_desc",
            culturalContextKey: "achievement_card_virtuoso_context",
            requirements: [.gamesWon(count: 25)],
            targetValue: 25,
            experiencePoints: 100,
            culturalKnowledgePoints: 50,
            badge: AchievementBadge(iconName: "crown.fill", colorScheme: .gold)
        )
        
        let folkloreScholar = RomanianAchievement(
            type: .cultural,
            category: .folkloreLearning,
            difficulty: .silver,
            culturalRegion: nil,
            titleKey: "achievement_folklore_scholar_title",
            descriptionKey: "achievement_folklore_scholar_desc",
            culturalContextKey: "achievement_folklore_scholar_context",
            requirements: [.folktaleLearned(count: 15)],
            targetValue: 15,
            experiencePoints: 75,
            culturalKnowledgePoints: 100,
            badge: AchievementBadge(iconName: "book.fill", colorScheme: .cultural)
        )
        
        achievementRegistry.registerAchievement(firstSteps)
        achievementRegistry.registerAchievement(cardVirtuoso)
        achievementRegistry.registerAchievement(folkloreScholar)
        
        availableAchievements = achievementRegistry.getAllAchievements()
        
        logger.info("Registered \(self.availableAchievements.count) Romanian cultural achievements")
    }
    
    private func loadPlayerProgress() {
        // Initialize progress tracking for all achievements
        for achievement in availableAchievements {
            let progress = AchievementProgress(
                achievementId: achievement.id,
                playerId: currentPlayerId
            )
            progressAchievements.append(progress)
        }
        
        logger.info("Initialized progress tracking for \(self.progressAchievements.count) achievements")
    }
    
    // MARK: - Progress Tracking
    
    func trackGameEvent(type: GameEventType, value: Int = 1) {
        logger.info("Tracking game event: \(String(describing: type)) with value: \(value)")
        
        switch type {
        case .gameStarted:
            updateProgress(for: .gamesPlayed(count: value))
        case .gameWon:
            updateProgress(for: .gamesWon(count: value))
        case .perfectGame:
            updateProgress(for: .perfectGames(count: value))
        case .cardPlayed:
            updateProgress(for: .cardsPlayed(count: value))
        }
    }
    
    func trackCulturalEvent(type: AchievementCulturalEventType, value: Int = 1) {
        logger.info("Tracking cultural event: \(String(describing: type)) with value: \(value)")
        
        switch type {
        case .folkloreStoryRead:
            updateProgress(for: .folktaleLearned(count: value))
        case .traditionExplored:
            updateProgress(for: .traditionExplored(count: value))
        case .culturalQuizCompleted:
            updateProgress(for: .culturalQuizAnswered(count: value))
        }
    }
    
    private func updateProgress(for requirement: AchievementRequirement) {
        for i in 0..<progressAchievements.count {
            let progress = progressAchievements[i]
            
            if let achievement = achievementRegistry.getAchievement(id: progress.achievementId),
               achievement.requirements.contains(requirement) {
                
                let newValue = progress.currentValue + requirement.targetValue
                progressAchievements[i].updateProgress(newValue)
                
                // Check for completion
                if progressAchievements[i].isCompleted && !completedAchievementIds.contains(achievement.id) {
                    completeAchievement(achievement)
                }
            }
        }
    }
    
    private func completeAchievement(_ achievement: RomanianAchievement) {
        guard !completedAchievementIds.contains(achievement.id) else { return }
        
        unlockedAchievements.append(achievement)
        completedAchievementIds.insert(achievement.id)
        
        totalExperiencePoints += achievement.experiencePoints
        totalCulturalKnowledgePoints += achievement.culturalKnowledgePoints
        
        logger.info("Achievement completed: \(achievement.titleKey)")
        logger.info("Gained \(achievement.experiencePoints) XP and \(achievement.culturalKnowledgePoints) cultural knowledge points")
        
        // Trigger achievement celebration
        celebrateAchievement(achievement)
    }
    
    private func celebrateAchievement(_ achievement: RomanianAchievement) {
        // Simple celebration logic - could be expanded with animations, sounds, etc.
        logger.info("🎉 Celebrating achievement: \(achievement.titleKey)")
        
        // Post notification for UI to show celebration
        NotificationCenter.default.post(
            name: .achievementUnlocked,
            object: achievement
        )
    }
    
    // MARK: - Query Methods
    
    func getProgress(for achievementId: UUID) -> AchievementProgress? {
        return progressAchievements.first { $0.achievementId == achievementId }
    }
    
    func getAchievements(for category: AchievementCategory) -> [RomanianAchievement] {
        return achievementRegistry.getAchievements(for: category)
    }
    
    func getAchievements(for region: RomanianRegion) -> [RomanianAchievement] {
        return achievementRegistry.getAchievements(for: region)
    }
    
    func getCompletedAchievements() -> [RomanianAchievement] {
        return unlockedAchievements
    }
    
    func getProgressPercentage(for achievementId: UUID) -> Double {
        guard let progress = getProgress(for: achievementId),
              let achievement = achievementRegistry.getAchievement(id: achievementId) else {
            return 0.0
        }
        
        return min(Double(progress.currentValue) / Double(achievement.targetValue), 1.0)
    }
}

// MARK: - Event Types

enum GameEventType {
    case gameStarted
    case gameWon
    case perfectGame
    case cardPlayed
}

enum AchievementCulturalEventType {
    case folkloreStoryRead
    case traditionExplored
    case culturalQuizCompleted
}

// MARK: - Notification Names

extension Notification.Name {
    static let achievementUnlocked = Notification.Name("achievementUnlocked")
}