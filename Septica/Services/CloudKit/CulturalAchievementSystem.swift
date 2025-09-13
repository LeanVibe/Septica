//
//  CulturalAchievementSystem.swift
//  Septica
//
//  Romanian Cultural Achievement & Heritage Education System
//  Combines engaging gameplay progression with authentic cultural learning
//

import Foundation
import Combine
import SwiftUI

/// Educational achievement system that celebrates Romanian heritage through gameplay
@MainActor
class CulturalAchievementSystem: ObservableObject {
    
    // MARK: - Dependencies
    
    private let playerProfileService: PlayerProfileService
    private let audioManager: AudioManager?
    private let hapticManager: HapticManager?
    
    // MARK: - Published State
    
    @Published var availableAchievements: [CulturalAchievement] = []
    @Published var unlockedAchievements: [CulturalAchievement] = []
    @Published var culturalEducationModules: [EducationModule] = []
    @Published var heritageCollection: [HeritageItem] = []
    @Published var currentCelebration: CulturalCelebration?
    @Published var folkTalesLibrary: [FolkTale] = []
    
    // MARK: - Romanian Cultural Achievement Categories
    
    /// Comprehensive achievement system celebrating Romanian culture
    struct CulturalAchievement {
        let id: String
        let category: AchievementCategory
        let title: String
        let romanianTitle: String
        let description: String
        let culturalSignificance: String
        let educationalContent: String
        let requirements: AchievementRequirements
        let rewards: AchievementRewards
        let rarity: AchievementRarity
        var progress: Float = 0.0
        var isUnlocked: Bool = false
        var unlockedDate: Date?
        
        enum AchievementCategory: String, CaseIterable {
            case gameplayMastery = "gameplay_mastery"
            case culturalKnowledge = "cultural_knowledge"
            case cardTradition = "card_tradition"
            case folkArt = "folk_art"
            case musicHeritage = "music_heritage"
            case languageLearning = "language_learning"
            case seasonalCelebrations = "seasonal_celebrations"
            case communityEngagement = "community_engagement"
            
            var displayName: String {
                switch self {
                case .gameplayMastery: return "Gameplay Mastery"
                case .culturalKnowledge: return "Cultural Knowledge"
                case .cardTradition: return "Card Traditions"
                case .folkArt: return "Folk Art"
                case .musicHeritage: return "Music Heritage"
                case .languageLearning: return "Language Learning"
                case .seasonalCelebrations: return "Seasonal Celebrations"
                case .communityEngagement: return "Community Engagement"
                }
            }
            
            var culturalIcon: String {
                switch self {
                case .gameplayMastery: return "🎮"
                case .culturalKnowledge: return "📚"
                case .cardTradition: return "🃏"
                case .folkArt: return "🎨"
                case .musicHeritage: return "🎵"
                case .languageLearning: return "🗣️"
                case .seasonalCelebrations: return "🎉"
                case .communityEngagement: return "🤝"
                }
            }
        }
        
        enum AchievementRarity: String, CaseIterable {
            case common = "common"
            case uncommon = "uncommon"
            case rare = "rare"
            case epic = "epic"
            case legendary = "legendary"
            case cultural = "cultural" // Special Romanian heritage tier
            
            var color: Color {
                switch self {
                case .common: return .gray
                case .uncommon: return .green
                case .rare: return .blue
                case .epic: return .purple
                case .legendary: return .orange
                case .cultural: return Color(red: 0.8, green: 0.1, blue: 0.1) // Romanian red
                }
            }
            
            var glow: Bool {
                return self == .legendary || self == .cultural
            }
        }
        
        struct AchievementRequirements {
            let gameWins: Int?
            let cardMasteryLevels: [String: Int]? // CardKey -> Level
            let culturalQuizzesCompleted: Int?
            let folkTalesRead: Int?
            let musicTracksListened: Int?
            let seasonalEventsParticipated: Int?
            let customConditions: [String]?
        }
        
        struct AchievementRewards {
            let experiencePoints: Int
            let culturalPoints: Int
            let coins: Int?
            let unlockedContent: [String] // IDs of unlocked items
            let cardVisualEffects: [String]?
            let musicTracks: [String]?
            let educationalBadges: [String]?
        }
    }
    
    /// Romanian cultural education modules with interactive content
    struct EducationModule {
        let id: String
        let title: String
        let romanianTitle: String
        let description: String
        let category: EducationCategory
        let difficulty: EducationDifficulty
        let content: EducationalContent
        let interactiveElements: [InteractiveElement]
        let completionRewards: CulturalAchievement.AchievementRewards
        var isCompleted: Bool = false
        var progress: Float = 0.0
        
        enum EducationCategory: String, CaseIterable {
            case gameHistory = "game_history"
            case folkTraditions = "folk_traditions"
            case musicAndDance = "music_and_dance"
            case romanianLanguage = "romanian_language"
            case historicalContext = "historical_context"
            case geography = "geography"
            case artAndCrafts = "art_and_crafts"
            
            var culturalIcon: String {
                switch self {
                case .gameHistory: return "📜"
                case .folkTraditions: return "🏛️"
                case .musicAndDance: return "💃"
                case .romanianLanguage: return "🇷🇴"
                case .historicalContext: return "⚔️"
                case .geography: return "🗺️"
                case .artAndCrafts: return "🎨"
                }
            }
        }
        
        enum EducationDifficulty: Int, CaseIterable {
            case beginner = 1
            case intermediate = 2
            case advanced = 3
            case expert = 4
            
            var ageAppropriate: String {
                switch self {
                case .beginner: return "Ages 6-8"
                case .intermediate: return "Ages 9-10"
                case .advanced: return "Ages 11-12"
                case .expert: return "Ages 12+"
                }
            }
        }
        
        struct EducationalContent {
            let text: String
            let imageAssets: [String]
            let audioNarration: String?
            let videoContent: String?
            let interactiveQuiz: Quiz?
            let folkTaleStory: FolkTale?
        }
        
        struct InteractiveElement {
            let type: InteractionType
            let title: String
            let content: String
            let correctAnswer: String?
            let options: [String]?
            
            enum InteractionType {
                case quiz
                case dragAndDrop
                case cardMatching
                case audioRecognition
                case visualIdentification
            }
        }
        
        struct Quiz {
            let questions: [QuizQuestion]
            let passingScore: Int
            
            struct QuizQuestion {
                let question: String
                let options: [String]
                let correctAnswerIndex: Int
                let explanation: String
                let culturalContext: String?
            }
        }
    }
    
    /// Romanian folk tales integrated into the game experience
    struct FolkTale {
        let id: String
        let title: String
        let romanianTitle: String
        let summary: String
        let fullStory: String
        let moralLesson: String
        let culturalSignificance: String
        let relatedGameElements: [String] // How it connects to card game
        let illustrationAssets: [String]
        let audioNarration: String?
        let ageRating: String
        let estimatedReadingTime: Int // minutes
        var hasBeenRead: Bool = false
        var favorited: Bool = false
        
        // Pre-defined Romanian folk tales
        static let traditionalTales: [FolkTale] = [
            FolkTale(
                id: "fat_frumos_si_ileana_cosanzeana",
                title: "Făt-Frumos and Ileana Cosânzeana",
                romanianTitle: "Făt-Frumos și Ileana Cosânzeana",
                summary: "The story of a brave prince who overcomes challenges to win the hand of the beautiful Ileana Cosânzeana.",
                fullStory: "Long ago, in a kingdom far away, there lived a brave young prince known as Făt-Frumos...", // Full story would be included
                moralLesson: "Courage, perseverance, and good character triumph over adversity.",
                culturalSignificance: "This tale represents the archetypal Romanian hero story, emphasizing the importance of bravery and moral character.",
                relatedGameElements: ["The 7 card represents the magical number that helps Făt-Frumos", "Kings and Queens in the deck represent noble characters"],
                illustrationAssets: ["fat_frumos_illustration", "ileana_cosanzeana_portrait"],
                audioNarration: "fat_frumos_narration.mp3",
                ageRating: "6+",
                estimatedReadingTime: 8,
                hasBeenRead: false,
                favorited: false
            ),
            FolkTale(
                id: "miorita",
                title: "Miorița - The Little Ewe",
                romanianTitle: "Miorița",
                summary: "The pastoral ballad of a shepherd and his prophetic ewe, one of Romania's most beloved folk poems.",
                fullStory: "High up in the mountains, where three regions meet, three shepherds tend their flocks...",
                moralLesson: "Loyalty, acceptance of fate, and the connection between humans and nature.",
                culturalSignificance: "Miorița is considered the most important piece of Romanian folk literature, expressing the Romanian soul and worldview.",
                relatedGameElements: ["The Ace card represents the highest value, like the shepherd's wisdom", "The pattern of three in the story connects to the rule where 8 beats when count % 3 == 0"],
                illustrationAssets: ["miorita_shepherd", "carpathian_mountains"],
                audioNarration: "miorita_narration.mp3",
                ageRating: "8+",
                estimatedReadingTime: 12,
                hasBeenRead: false,
                favorited: false
            )
        ]
    }
    
    /// Cultural celebrations that unlock special content
    struct CulturalCelebration {
        let id: String
        let name: String
        let romanianName: String
        let date: Date
        let duration: TimeInterval // in days
        let description: String
        let culturalTraditions: [String]
        let specialRewards: [String]
        let gameplayModifications: [String]
        let educationalContent: EducationModule
        let isActive: Bool
        
        static let romanianCelebrations: [CulturalCelebration] = [
            CulturalCelebration(
                id: "martisor",
                name: "Mărțișor",
                romanianName: "Mărțișor",
                date: Calendar.current.date(from: DateComponents(month: 3, day: 1)) ?? Date(),
                duration: 7, // One week celebration
                description: "Spring celebration symbolizing renewal and hope",
                culturalTraditions: ["Giving white and red amulets", "Spring cleaning", "Welcoming warmer weather"],
                specialRewards: ["martisor_card_back", "spring_flower_effects", "traditional_music_unlocks"],
                gameplayModifications: ["Special flower particle effects", "Gentle spring sound effects", "Green and white color themes"],
                educationalContent: EducationModule(
                    id: "martisor_education",
                    title: "The Magic of Mărțișor",
                    romanianTitle: "Magia Mărțișorului",
                    description: "Learn about Romania's beautiful spring tradition",
                    category: .folkTraditions,
                    difficulty: .beginner,
                    content: EducationModule.EducationalContent(
                        text: "Mărțișor is celebrated on March 1st to welcome spring...",
                        imageAssets: ["martisor_amulets", "spring_flowers"],
                        audioNarration: "martisor_story.mp3",
                        videoContent: nil,
                        interactiveQuiz: nil,
                        folkTaleStory: nil
                    ),
                    interactiveElements: [],
                    completionRewards: CulturalAchievement.AchievementRewards(
                        experiencePoints: 100,
                        culturalPoints: 50,
                        coins: 500,
                        unlockedContent: ["martisor_theme"],
                        cardVisualEffects: ["spring_glow"],
                        musicTracks: ["spring_dance"],
                        educationalBadges: ["spring_scholar"]
                    )
                ),
                isActive: false
            )
        ]
    }
    
    /// Heritage items that can be collected and displayed
    struct HeritageItem {
        let id: String
        let name: String
        let romanianName: String
        let category: HeritageCategory
        let description: String
        let culturalPeriod: String
        let region: String
        let significance: String
        let imageAsset: String
        let rarity: CulturalAchievement.AchievementRarity
        var isCollected: Bool = false
        var collectionDate: Date?
        
        enum HeritageCategory: String, CaseIterable {
            case traditionalClothing = "traditional_clothing"
            case folkInstruments = "folk_instruments"
            case craftwork = "craftwork"
            case architecture = "architecture"
            case cuisine = "cuisine"
            case dances = "dances"
            case symbols = "symbols"
            
            var displayName: String {
                switch self {
                case .traditionalClothing: return "Traditional Clothing"
                case .folkInstruments: return "Folk Instruments"
                case .craftwork: return "Craftwork"
                case .architecture: return "Architecture"
                case .cuisine: return "Cuisine"
                case .dances: return "Dances"
                case .symbols: return "Symbols"
                }
            }
        }
    }
    
    // MARK: - Initialization
    
    init(playerProfileService: PlayerProfileService, audioManager: AudioManager?, hapticManager: HapticManager?) {
        self.playerProfileService = playerProfileService
        self.audioManager = audioManager
        self.hapticManager = hapticManager
        
        Task {
            await initializeCulturalContent()
            await loadPlayerProgress()
        }
    }
    
    // MARK: - System Initialization
    
    private func initializeCulturalContent() async {
        availableAchievements = createCulturalAchievements()
        culturalEducationModules = createEducationModules()
        folkTalesLibrary = FolkTale.traditionalTales
        heritageCollection = createHeritageItems()
        
        // Check for active seasonal celebrations
        await checkForActiveCelebrations()
    }
    
    private func createCulturalAchievements() -> [CulturalAchievement] {
        return [
            // Gameplay Mastery Achievements
            CulturalAchievement(
                id: "septica_master",
                category: .gameplayMastery,
                title: "Septica Master",
                romanianTitle: "Maestru Septică",
                description: "Win 100 games of Septica",
                culturalSignificance: "Septica has been played in Romanian households for generations, bringing families together.",
                educationalContent: "The name 'Septica' comes from the Romanian word 'șapte' meaning seven, highlighting the importance of the 7 card.",
                requirements: CulturalAchievement.AchievementRequirements(
                    gameWins: 100,
                    cardMasteryLevels: nil,
                    culturalQuizzesCompleted: nil,
                    folkTalesRead: nil,
                    musicTracksListened: nil,
                    seasonalEventsParticipated: nil,
                    customConditions: nil
                ),
                rewards: CulturalAchievement.AchievementRewards(
                    experiencePoints: 500,
                    culturalPoints: 100,
                    coins: 1000,
                    unlockedContent: ["master_card_back"],
                    cardVisualEffects: ["golden_glow"],
                    musicTracks: ["victory_hora"],
                    educationalBadges: ["septica_historian"]
                ),
                rarity: .epic
            ),
            
            // Card Tradition Achievement
            CulturalAchievement(
                id: "seven_wild_master",
                category: .cardTradition,
                title: "Master of Sevens",
                romanianTitle: "Stăpânul Septelor",
                description: "Use the 7 card as a wild card 50 times successfully",
                culturalSignificance: "The number 7 is considered magical in Romanian folklore, appearing in many traditional stories.",
                educationalContent: "In Romanian culture, 7 represents perfection and completion, which is why it's the most powerful card in Septica.",
                requirements: CulturalAchievement.AchievementRequirements(
                    gameWins: nil,
                    cardMasteryLevels: ["7_hearts": 3, "7_diamonds": 3, "7_clubs": 3, "7_spades": 3],
                    culturalQuizzesCompleted: nil,
                    folkTalesRead: nil,
                    musicTracksListened: nil,
                    seasonalEventsParticipated: nil,
                    customConditions: ["seven_wild_uses:50"]
                ),
                rewards: CulturalAchievement.AchievementRewards(
                    experiencePoints: 300,
                    culturalPoints: 75,
                    coins: 750,
                    unlockedContent: ["seven_magic_effect"],
                    cardVisualEffects: ["seven_star_trail"],
                    musicTracks: nil,
                    educationalBadges: ["seven_sage"]
                ),
                rarity: .rare
            ),
            
            // Cultural Knowledge Achievement
            CulturalAchievement(
                id: "heritage_scholar",
                category: .culturalKnowledge,
                title: "Heritage Scholar",
                romanianTitle: "Cărturar al Tradiției",
                description: "Complete 10 cultural education modules",
                culturalSignificance: "Knowledge of Romanian heritage helps preserve traditions for future generations.",
                educationalContent: "Romanian culture is rich with traditions that have been passed down through centuries of storytelling and celebration.",
                requirements: CulturalAchievement.AchievementRequirements(
                    gameWins: nil,
                    cardMasteryLevels: nil,
                    culturalQuizzesCompleted: 10,
                    folkTalesRead: 5,
                    musicTracksListened: nil,
                    seasonalEventsParticipated: nil,
                    customConditions: nil
                ),
                rewards: CulturalAchievement.AchievementRewards(
                    experiencePoints: 400,
                    culturalPoints: 150,
                    coins: 500,
                    unlockedContent: ["scholar_robes", "ancient_card_style"],
                    cardVisualEffects: ["wisdom_aura"],
                    musicTracks: ["academic_hymn"],
                    educationalBadges: ["cultural_guardian"]
                ),
                rarity: .cultural
            ),
            
            // Folk Art Achievement
            CulturalAchievement(
                id: "folk_art_collector",
                category: .folkArt,
                title: "Folk Art Collector",
                romanianTitle: "Colecționar de Artă Populară",
                description: "Unlock 15 traditional Romanian visual themes",
                culturalSignificance: "Romanian folk art expresses the creativity and soul of the people through beautiful patterns and colors.",
                educationalContent: "Traditional Romanian patterns often feature geometric designs, flowers, and symbols that tell stories of rural life.",
                requirements: CulturalAchievement.AchievementRequirements(
                    gameWins: 25,
                    cardMasteryLevels: nil,
                    culturalQuizzesCompleted: 3,
                    folkTalesRead: nil,
                    musicTracksListened: nil,
                    seasonalEventsParticipated: nil,
                    customConditions: ["themes_unlocked:15"]
                ),
                rewards: CulturalAchievement.AchievementRewards(
                    experiencePoints: 200,
                    culturalPoints: 100,
                    coins: 800,
                    unlockedContent: ["master_artisan_tools"],
                    cardVisualEffects: ["folk_pattern_border"],
                    musicTracks: nil,
                    educationalBadges: ["folk_artist"]
                ),
                rarity: .uncommon
            )
        ]
    }
    
    private func createEducationModules() -> [EducationModule] {
        return [
            EducationModule(
                id: "septica_history",
                title: "The History of Septica",
                romanianTitle: "Istoria Septicii",
                description: "Learn about the origins and evolution of Romania's beloved card game",
                category: .gameHistory,
                difficulty: .beginner,
                content: EducationModule.EducationalContent(
                    text: """
                    Septica is a traditional Romanian card game that has been played for centuries. The game gets its name from the Romanian word 'șapte' meaning seven, which is the most powerful card in the game.
                    
                    The game reflects Romanian values of strategy, patience, and social connection. Families would gather around tables to play Septica, sharing stories and strengthening bonds.
                    """,
                    imageAssets: ["old_romanian_cards", "family_playing_cards"],
                    audioNarration: "septica_history_narration.mp3",
                    videoContent: nil,
                    interactiveQuiz: EducationModule.Quiz(
                        questions: [
                            EducationModule.Quiz.QuizQuestion(
                                question: "What does the word 'Septica' mean in Romanian?",
                                options: ["Seven", "Eight", "King", "Ace"],
                                correctAnswerIndex: 0,
                                explanation: "Septica comes from 'șapte', the Romanian word for seven.",
                                culturalContext: "The number seven is considered lucky in Romanian culture."
                            )
                        ],
                        passingScore: 80
                    ),
                    folkTaleStory: nil
                ),
                interactiveElements: [],
                completionRewards: CulturalAchievement.AchievementRewards(
                    experiencePoints: 50,
                    culturalPoints: 25,
                    coins: 100,
                    unlockedContent: ["historical_card_back"],
                    cardVisualEffects: nil,
                    musicTracks: nil,
                    educationalBadges: ["history_student"]
                )
            )
        ]
    }
    
    private func createHeritageItems() -> [HeritageItem] {
        return [
            HeritageItem(
                id: "ie_traditionala",
                name: "Traditional Romanian Blouse",
                romanianName: "Ie Tradițională",
                category: .traditionalClothing,
                description: "The beautiful traditional Romanian blouse worn during celebrations",
                culturalPeriod: "18th-20th Century",
                region: "Throughout Romania",
                significance: "Symbol of Romanian femininity and artistry",
                imageAsset: "ie_traditionala",
                rarity: .rare
            ),
            HeritageItem(
                id: "caval",
                name: "Shepherd's Flute",
                romanianName: "Caval",
                category: .folkInstruments,
                description: "Traditional wooden flute used by Romanian shepherds",
                culturalPeriod: "Ancient to Present",
                region: "Carpathian Mountains",
                significance: "Represents the pastoral life and connection to nature",
                imageAsset: "caval_flute",
                rarity: .uncommon
            )
        ]
    }
    
    // MARK: - Achievement Tracking
    
    func checkAchievementProgress(gameWon: Bool, cardsUsed: [String], culturalActions: [String]) async {
        for achievement in availableAchievements {
            if !achievement.isUnlocked {
                let newProgress = calculateAchievementProgress(achievement, gameWon: gameWon, cardsUsed: cardsUsed, culturalActions: culturalActions)
                
                if newProgress >= 1.0 {
                    await unlockAchievement(achievement)
                }
            }
        }
    }
    
    private func calculateAchievementProgress(_ achievement: CulturalAchievement, gameWon: Bool, cardsUsed: [String], culturalActions: [String]) -> Float {
        // Implementation would check various conditions and return progress 0.0-1.0
        return 0.0 // Placeholder
    }
    
    private func unlockAchievement(_ achievement: CulturalAchievement) async {
        var unlockedAchievement = achievement
        unlockedAchievement.isUnlocked = true
        unlockedAchievement.unlockedDate = Date()
        
        unlockedAchievements.append(unlockedAchievement)
        
        // Remove from available and add to unlocked
        if let index = availableAchievements.firstIndex(where: { $0.id == achievement.id }) {
            availableAchievements.remove(at: index)
        }
        
        // Trigger celebration
        await celebrateAchievementUnlock(unlockedAchievement)
        
        // Apply rewards
        await applyAchievementRewards(unlockedAchievement.rewards)
    }
    
    private func celebrateAchievementUnlock(_ achievement: CulturalAchievement) async {
        // Play celebration sound
        audioManager?.playSound(.gameVictory)
        
        // Trigger haptic feedback
        hapticManager?.trigger(.success)
        
        // Show educational content
        print("🏆 Achievement Unlocked: \(achievement.title)")
        print("📚 Cultural Education: \(achievement.educationalContent)")
        print("🇷🇴 Significance: \(achievement.culturalSignificance)")
    }
    
    private func applyAchievementRewards(_ rewards: CulturalAchievement.AchievementRewards) async {
        // This would integrate with the player profile to apply rewards
        print("💰 Rewards applied: \(rewards.coins ?? 0) coins, \(rewards.experiencePoints) XP, \(rewards.culturalPoints) cultural points")
    }
    
    // MARK: - Cultural Education
    
    func startEducationModule(_ module: EducationModule) async {
        print("📖 Starting education module: \(module.title)")
        print("🎯 Difficulty: \(module.difficulty.ageAppropriate)")
        print("📚 Content: \(module.content.text)")
        
        // This would trigger the UI to show the educational content
    }
    
    func completeEducationModule(_ moduleId: String) async {
        if let index = culturalEducationModules.firstIndex(where: { $0.id == moduleId }) {
            culturalEducationModules[index].isCompleted = true
            await applyAchievementRewards(culturalEducationModules[index].completionRewards)
        }
    }
    
    // MARK: - Seasonal Celebrations
    
    private func checkForActiveCelebrations() async {
        let today = Date()
        
        for celebration in CulturalCelebration.romanianCelebrations {
            let calendar = Calendar.current
            let celebrationComponents = calendar.dateComponents([.month, .day], from: celebration.date)
            let todayComponents = calendar.dateComponents([.month, .day], from: today)
            
            if celebrationComponents.month == todayComponents.month && 
               celebrationComponents.day == todayComponents.day {
                await activateCelebration(celebration)
            }
        }
    }
    
    private func activateCelebration(_ celebration: CulturalCelebration) async {
        currentCelebration = celebration
        
        print("🎉 Cultural Celebration Active: \(celebration.name)")
        print("🇷🇴 \(celebration.description)")
        print("🎁 Special rewards available!")
        
        // Trigger special visual effects and music
        audioManager?.startBackgroundMusic(.traditionalFolk)
    }
    
    // MARK: - Progress Tracking
    
    private func loadPlayerProgress() async {
        // Load player's achievement progress from PlayerProfileService
        // This would sync with CloudKit data
    }
    
    func saveProgress() async {
        // Save current progress to CloudKit via PlayerProfileService
    }
}