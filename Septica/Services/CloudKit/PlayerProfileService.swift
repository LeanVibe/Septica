//
//  PlayerProfileService.swift
//  Septica
//
//  Player profile management with Clash Royale-style progression
//  Implements Romanian arena system and Shuffle Cats card mastery
//

import Foundation
import Combine
import CloudKit

/// Service for managing player profiles with engaging progression systems
@MainActor
class PlayerProfileService: ObservableObject {
    
    // MARK: - Dependencies
    
    private let cloudKitManager: SepticaCloudKitManager
    private let errorManager: ErrorManager?
    
    // MARK: - Published State
    
    @Published var currentProfile: SepticaCloudKitManager.CloudKitPlayerProfile?
    @Published var isLoading: Bool = false
    @Published var syncStatus: SyncStatus = .idle
    @Published var cardMasteries: [String: SepticaCloudKitManager.CardMastery] = [:]
    @Published var currentArena: SepticaCloudKitManager.RomanianArena = .sateImarica
    @Published var trophyProgress: TrophyProgress?
    
    // MARK: - Progression State
    
    @Published var seasonalRewards: [SeasonalReward] = []
    @Published var availableChests: [RewardChest] = []
    @Published var dailyQuests: [DailyQuest] = []
    @Published var achievements: [SepticaCloudKitManager.CulturalAchievement] = []
    
    // MARK: - Romanian Cultural Features
    
    @Published var culturalEducationProgress: Float = 0.0
    @Published var folkMusicCollection: [String] = []
    @Published var heritageLevel: Int = 1
    @Published var traditionalUnlocks: [String] = []
    
    enum SyncStatus {
        case idle
        case syncing
        case offline
        case error(String)
    }
    
    // MARK: - Progression Models
    
    struct TrophyProgress {
        let currentTrophies: Int
        let currentArena: SepticaCloudKitManager.RomanianArena
        let nextArena: SepticaCloudKitManager.RomanianArena?
        let trophiesNeeded: Int
        let progressPercentage: Float
        
        var progressDescription: String {
            if let nextArena = nextArena {
                return "\(trophiesNeeded) trophies to reach \(nextArena.displayName)"
            } else {
                return "Maximum arena reached!"
            }
        }
    }
    
    /// Reward chest system inspired by Clash Royale
    struct RewardChest {
        let id: UUID
        let type: ChestType
        let unlockTime: TimeInterval // in seconds
        let rewards: [ChestReward]
        let isUnlocking: Bool
        let timeRemaining: TimeInterval
        
        enum ChestType: String, CaseIterable {
            case wooden = "wooden"
            case folk = "folk"           // Romanian folk art themed
            case silver = "silver"
            case golden = "golden"
            case cultural = "cultural"   // Special Romanian heritage chest
            case legendary = "legendary"
            
            var displayName: String {
                switch self {
                case .wooden: return "Wooden Chest"
                case .folk: return "Folk Art Chest"
                case .silver: return "Silver Chest"
                case .golden: return "Golden Chest"
                case .cultural: return "Cultural Heritage Chest"
                case .legendary: return "Legendary Romanian Chest"
                }
            }
            
            var unlockTimeMinutes: Int {
                switch self {
                case .wooden: return 0        // Instant
                case .folk: return 15        // 15 minutes
                case .silver: return 60      // 1 hour
                case .golden: return 240     // 4 hours
                case .cultural: return 480   // 8 hours
                case .legendary: return 1440 // 24 hours
                }
            }
            
            var romanianTheme: String {
                switch self {
                case .wooden: return "Traditional oak wood from Maramureș"
                case .folk: return "Handcrafted with traditional Romanian patterns"
                case .silver: return "Silver like the Carpathian mountains"
                case .golden: return "Golden like Romanian wheat fields"
                case .cultural: return "Contains Romanian heritage treasures"
                case .legendary: return "Legendary treasures of Romanian kings"
                }
            }
        }
        
        struct ChestReward {
            let type: RewardType
            let amount: Int
            let itemID: String?
            
            enum RewardType {
                case coins
                case gems
                case cardBack
                case musicTrack
                case culturalStory
                case visualEffect
                case achievement
            }
        }
    }
    
    /// Daily quests with Romanian cultural education
    struct DailyQuest {
        let id: String
        let title: String
        let description: String
        let progress: Int
        let target: Int
        let reward: QuestReward
        let culturalEducation: String? // Optional educational content
        let isCompleted: Bool
        
        struct QuestReward {
            let coins: Int
            let xp: Int
            let culturalPoints: Int
            let specialItem: String?
        }
        
        static let romanianCulturalQuests: [DailyQuest] = [
            DailyQuest(
                id: "septica_wins_3",
                title: "Master the Seven",
                description: "Win 3 games using the wild 7 card strategically",
                progress: 0,
                target: 3,
                reward: QuestReward(coins: 100, xp: 50, culturalPoints: 10, specialItem: "seven_glow_effect"),
                culturalEducation: "The number 7 is considered lucky in Romanian culture, often appearing in folk tales and traditions.",
                isCompleted: false
            ),
            DailyQuest(
                id: "folk_music_play",
                title: "Traditional Melodies",
                description: "Play 5 games with traditional Romanian folk music",
                progress: 0,
                target: 5,
                reward: QuestReward(coins: 75, xp: 30, culturalPoints: 15, specialItem: "music_note_effect"),
                culturalEducation: "Romanian folk music reflects the soul of the people, passed down through generations.",
                isCompleted: false
            ),
            DailyQuest(
                id: "heritage_learn",
                title: "Cultural Student",
                description: "Read 2 Romanian cultural stories in the Heritage section",
                progress: 0,
                target: 2,
                reward: QuestReward(coins: 50, xp: 75, culturalPoints: 25, specialItem: "heritage_badge"),
                culturalEducation: "Learning about Romanian heritage helps preserve cultural traditions for future generations.",
                isCompleted: false
            )
        ]
    }
    
    /// Seasonal rewards with Romanian celebrations
    struct SeasonalReward {
        let id: String
        let title: String
        let description: String
        let tier: Int
        let requiredSeasonTrophies: Int
        let reward: String
        let culturalSignificance: String
        let isUnlocked: Bool
        
        static let romanianSeasonalRewards: [SeasonalReward] = [
            SeasonalReward(
                id: "martisor_celebration",
                title: "Mărțișor Celebration",
                description: "Celebrate the arrival of spring with traditional Romanian customs",
                tier: 1,
                requiredSeasonTrophies: 100,
                reward: "martisor_card_back",
                culturalSignificance: "Mărțișor is celebrated on March 1st, symbolizing the arrival of spring and new beginnings.",
                isUnlocked: false
            ),
            SeasonalReward(
                id: "romania_national_day",
                title: "Romania's National Day",
                description: "Honor Romania's Great Union with special rewards",
                tier: 5,
                requiredSeasonTrophies: 500,
                reward: "tricolor_effect",
                culturalSignificance: "December 1st commemorates the unification of all Romanian provinces in 1918.",
                isUnlocked: false
            )
        ]
    }
    
    // MARK: - Initialization
    
    init(cloudKitManager: SepticaCloudKitManager, errorManager: ErrorManager?) {
        self.cloudKitManager = cloudKitManager
        self.errorManager = errorManager
        
        Task {
            await loadCurrentProfile()
            await initializeDailyQuests()
        }
    }
    
    // MARK: - Profile Management
    
    func loadCurrentProfile() async {
        isLoading = true
        syncStatus = .syncing
        
        do {
            // Try to load from CloudKit first
            if let cloudProfile = try await cloudKitManager.loadPlayerProfile(playerID: getCurrentPlayerID()) {
                currentProfile = cloudProfile
                updateLocalState(from: cloudProfile)
                syncStatus = .idle
            } else {
                // Create new profile for first-time player
                await createNewPlayerProfile()
            }
        } catch {
            syncStatus = .error(error.localizedDescription)
            errorManager?.reportError(.saveDataCorruption(message: "CloudKit sync failed: \(error.localizedDescription)"), context: "PlayerProfileService.loadCurrentProfile")
            
            // Fall back to local profile if available
            loadLocalProfile()
        }
        
        isLoading = false
    }
    
    private func createNewPlayerProfile() async {
        let newProfile = SepticaCloudKitManager.CloudKitPlayerProfile(
            playerID: getCurrentPlayerID(),
            displayName: "New Player",
            currentArena: .sateImarica,
            trophies: 0,
            totalGamesPlayed: 0,
            totalWins: 0,
            currentStreak: 0,
            longestStreak: 0,
            favoriteAIDifficulty: "medium",
            cardMasteries: initializeCardMasteries(),
            achievements: [],
            seasonalProgress: SepticaCloudKitManager.SeasonalProgress(
                seasonID: getCurrentSeasonID(),
                seasonTrophies: 0,
                seasonWins: 0,
                seasonChestsOpened: 0,
                seasonAchievements: [],
                celebrationParticipation: [:] // Empty dictionary for Romanian holidays
            ),
            preferences: SepticaCloudKitManager.GamePreferences(),
            culturalEducationProgress: SepticaCloudKitManager.CulturalEducationProgress(
                gameRulesLearned: [],
                folkTalesRead: 0,
                traditionalMusicKnowledge: 0,
                cardHistoryKnowledge: 0,
                quizScores: [:],
                culturalBadges: []
            ),
            lastPlayedDate: Date(),
            createdDate: Date(),
            heritageEngagementLevel: 0.0,
            folkMusicListened: [],
            culturalStoriesRead: [],
            traditionalColorsUnlocked: ["classic_romanian"] // Start with basic theme
        )
        
        currentProfile = newProfile
        updateLocalState(from: newProfile)
        
        // Save to CloudKit
        do {
            try await cloudKitManager.savePlayerProfile(newProfile)
            syncStatus = .idle
        } catch {
            syncStatus = .error("Failed to save new profile")
        }
    }
    
    private func updateLocalState(from profile: SepticaCloudKitManager.CloudKitPlayerProfile) {
        cardMasteries = profile.cardMasteries
        currentArena = profile.currentArena
        achievements = profile.achievements
        updateTrophyProgress(profile.trophies)
        culturalEducationProgress = profile.culturalEducationProgress.folkTalesRead > 0 ? 
            Float(profile.culturalEducationProgress.folkTalesRead) / 10.0 : 0.0
        folkMusicCollection = profile.folkMusicListened
        traditionalUnlocks = profile.traditionalColorsUnlocked
    }
    
    private func updateTrophyProgress(_ trophies: Int) {
        let current = cloudKitManager.checkArenaProgression(currentTrophies: trophies)
        let nextArenaIndex = current.rawValue + 1
        let nextArena = nextArenaIndex < SepticaCloudKitManager.RomanianArena.allCases.count ? 
            SepticaCloudKitManager.RomanianArena(rawValue: nextArenaIndex) : nil
        
        let trophiesNeeded = nextArena?.requiredTrophies ?? 0
        let progress = nextArena != nil ? Float(trophies - current.requiredTrophies) / Float(trophiesNeeded - current.requiredTrophies) : 1.0
        
        trophyProgress = TrophyProgress(
            currentTrophies: trophies,
            currentArena: current,
            nextArena: nextArena,
            trophiesNeeded: max(0, trophiesNeeded - trophies),
            progressPercentage: progress
        )
    }
    
    // MARK: - Game Events & Updates
    
    func recordGameResult(won: Bool, opponentType: String, aiDifficulty: String?, cardsPlayed: [String], culturalMoments: [String]) async {
        guard var profile = currentProfile else { return }
        
        // Update basic stats
        profile.totalGamesPlayed += 1
        profile.lastPlayedDate = Date()
        
        if won {
            profile.totalWins += 1
            profile.currentStreak += 1
            profile.longestStreak = max(profile.longestStreak, profile.currentStreak)
            
            // Award trophies based on arena and opponent
            let trophiesEarned = calculateTrophiesEarned(arena: profile.currentArena, opponentType: opponentType)
            profile.trophies += trophiesEarned
            profile.seasonalProgress.seasonTrophies += trophiesEarned
            profile.seasonalProgress.seasonWins += 1
            
            // Check for arena progression
            let newArena = cloudKitManager.checkArenaProgression(currentTrophies: profile.trophies)
            if newArena != profile.currentArena {
                profile.currentArena = newArena
                await celebrateArenaPromotion(newArena)
            }
        } else {
            profile.currentStreak = 0
            // Lose fewer trophies in lower arenas (child-friendly)
            let trophiesLost = calculateTrophiesLost(arena: profile.currentArena)
            profile.trophies = max(0, profile.trophies - trophiesLost)
        }
        
        // Update card masteries
        for cardKey in cardsPlayed {
            updateCardMastery(cardKey: cardKey, won: won, in: &profile)
        }
        
        // Update cultural engagement
        if !culturalMoments.isEmpty {
            profile.heritageEngagementLevel = min(1.0, profile.heritageEngagementLevel + 0.01)
        }
        
        currentProfile = profile
        updateLocalState(from: profile)
        
        // Save to CloudKit
        do {
            try await cloudKitManager.savePlayerProfile(profile)
        } catch {
            syncStatus = .error("Failed to save game result")
        }
    }
    
    private func updateCardMastery(cardKey: String, won: Bool, in profile: inout SepticaCloudKitManager.CloudKitPlayerProfile) {
        var mastery = profile.cardMasteries[cardKey] ?? SepticaCloudKitManager.CardMastery(cardKey: cardKey)
        
        mastery.timesPlayed += 1
        if won {
            mastery.successfulPlays += 1
        }
        
        // Check for mastery level up
        let newLevel = calculateMasteryLevel(timesPlayed: mastery.timesPlayed)
        if newLevel > mastery.masteryLevel {
            mastery.masteryLevel = newLevel
            mastery.unlockedEffects.append("level_\(newLevel)_effect")
            
            Task {
                await celebrateCardMastery(cardKey: cardKey, level: newLevel)
            }
        }
        
        profile.cardMasteries[cardKey] = mastery
    }
    
    private func calculateMasteryLevel(timesPlayed: Int) -> Int {
        switch timesPlayed {
        case 25...99: return 1
        case 100...299: return 2
        case 300...749: return 3
        case 750...1499: return 4
        case 1500...: return 5
        default: return 0
        }
    }
    
    private func calculateTrophiesEarned(arena: SepticaCloudKitManager.RomanianArena, opponentType: String) -> Int {
        let baseTrophies = 25
        let arenaMultiplier = Float(arena.rawValue + 1) * 0.1 + 1.0
        let opponentMultiplier = opponentType == "AI" ? 1.0 : 1.2
        
        return Int(Float(baseTrophies) * arenaMultiplier * Float(opponentMultiplier))
    }
    
    private func calculateTrophiesLost(arena: SepticaCloudKitManager.RomanianArena) -> Int {
        // Child-friendly: lose fewer trophies in lower arenas
        switch arena {
        case .sateImarica, .satuMihai: return 5  // Very forgiving for beginners
        case .orasulBrara, .orasulBacau: return 10
        case .orasulCluj, .orasulConstanta: return 15
        default: return 20
        }
    }
    
    // MARK: - Daily Quests System
    
    private func initializeDailyQuests() async {
        dailyQuests = DailyQuest.romanianCulturalQuests.map { quest in
            var mutableQuest = quest
            mutableQuest = DailyQuest(
                id: quest.id,
                title: quest.title,
                description: quest.description,
                progress: 0,
                target: quest.target,
                reward: quest.reward,
                culturalEducation: quest.culturalEducation,
                isCompleted: false
            )
            return mutableQuest
        }
    }
    
    func updateQuestProgress(questType: String, amount: Int = 1) async {
        for (index, quest) in dailyQuests.enumerated() {
            if quest.id.contains(questType) && !quest.isCompleted {
                var updatedQuest = quest
                updatedQuest = DailyQuest(
                    id: quest.id,
                    title: quest.title,
                    description: quest.description,
                    progress: min(quest.progress + amount, quest.target),
                    target: quest.target,
                    reward: quest.reward,
                    culturalEducation: quest.culturalEducation,
                    isCompleted: quest.progress + amount >= quest.target
                )
                
                dailyQuests[index] = updatedQuest
                
                if updatedQuest.isCompleted {
                    await rewardQuestCompletion(updatedQuest)
                }
            }
        }
    }
    
    private func rewardQuestCompletion(_ quest: DailyQuest) async {
        guard var profile = currentProfile else { return }
        
        // Add quest rewards to profile
        // This would integrate with a currency/rewards system
        print("🏆 Quest completed: \(quest.title) - Cultural Education: \(quest.culturalEducation ?? "None")")
        
        // Update cultural education progress
        profile.culturalEducationProgress.culturalBadges.append(quest.id)
        profile.heritageEngagementLevel = min(1.0, profile.heritageEngagementLevel + 0.05)
        
        currentProfile = profile
    }
    
    // MARK: - Celebration Events
    
    private func celebrateArenaPromotion(_ newArena: SepticaCloudKitManager.RomanianArena) async {
        print("🎉 Arena promotion! Welcome to \(newArena.displayName)")
        print("📚 Cultural Info: \(newArena.culturalDescription)")
        // This would trigger UI animations and educational content display
    }
    
    private func celebrateCardMastery(cardKey: String, level: Int) async {
        print("🃏 Card mastery achieved! \(cardKey) reached level \(level)")
        // This would trigger visual effects for the specific card
    }
    
    // MARK: - Utility Methods
    
    private func getCurrentPlayerID() -> String {
        // This would be generated based on device/iCloud account
        return "player_\(UUID().uuidString)"
    }
    
    private func getCurrentSeasonID() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy_MM"
        return "season_\(formatter.string(from: Date()))"
    }
    
    private func loadLocalProfile() {
        // Fallback to local storage when CloudKit is unavailable
        print("⚠️ Loading local profile fallback")
    }
    
    private func initializeCardMasteries() -> [String: SepticaCloudKitManager.CardMastery] {
        var masteries: [String: SepticaCloudKitManager.CardMastery] = [:]
        
        // Initialize all Romanian Septica cards (7, 8, 9, 10, J, Q, K, A for each suit)
        let suits = ["hearts", "diamonds", "clubs", "spades"]
        let values = ["7", "8", "9", "10", "jack", "queen", "king", "ace"]
        
        for suit in suits {
            for value in values {
                let cardKey = "\(value)_\(suit)"
                masteries[cardKey] = SepticaCloudKitManager.CardMastery(cardKey: cardKey)
            }
        }
        
        return masteries
    }
}