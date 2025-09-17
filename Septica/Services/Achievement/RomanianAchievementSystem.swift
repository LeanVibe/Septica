//
//  RomanianAchievementSystem.swift
//  Septica
//
//  Meta-game progression system with Romanian cultural achievements
//  Celebrates mastery of traditional Septica strategies and cultural knowledge
//

import SwiftUI
import Observation
import Foundation
import Combine

/// Romanian cultural achievement categories
enum RomanianAchievementCategory: String, CaseIterable {
    case cardMastery = "Măiestria Cărților"        // Card Mastery
    case traditionalPlay = "Jocul Tradițional"     // Traditional Play
    case culturalWisdom = "Înțelepciunea Culturală" // Cultural Wisdom
    case strategicThinking = "Gândirea Strategică"  // Strategic Thinking
    case communitySpirit = "Spiritul Comunității"  // Community Spirit
    case heritageKeeper = "Păstrător de Moștenire" // Heritage Keeper
    case gameExpertise = "Expertiza în Joc"        // Game Expertise
    case culturalAmbassador = "Ambasador Cultural" // Cultural Ambassador
    
    var icon: String {
        switch self {
        case .cardMastery: return "suit.spade.fill"
        case .traditionalPlay: return "figure.2.and.child.holdinghands"
        case .culturalWisdom: return "brain.head.profile"
        case .strategicThinking: return "lightbulb.fill"
        case .communitySpirit: return "heart.fill"
        case .heritageKeeper: return "building.columns.fill"
        case .gameExpertise: return "star.fill"
        case .culturalAmbassador: return "globe.europe.africa.fill"
        }
    }
    
    var culturalDescription: String {
        switch self {
        case .cardMastery:
            return "Stăpânește arta jocului de cărți cu îndemânarea unui meșter roman"
        case .traditionalPlay:
            return "Păstrează spiritul tradițional al jocului românesc"
        case .culturalWisdom:
            return "Dobândește înțelepciunea culturală transmisă din generație în generație"
        case .strategicThinking:
            return "Dezvoltă gândirea strategică specifică mentalității românești"
        case .communitySpirit:
            return "Cultivă spiritul de comunitate caracteristic satului românesc"
        case .heritageKeeper:
            return "Păstrează și transmite moștenirea culturală românească"
        case .gameExpertise:
            return "Atinge nivelul de expert în jocul de Septica"
        case .culturalAmbassador:
            return "Devine ambasador al culturii românești prin joc"
        }
    }
}

/// Achievement rarity levels with Romanian cultural significance
enum LegacyAchievementRarity: String, CaseIterable {
    case common = "Obișnuit"        // Common
    case uncommon = "Neobișnuit"    // Uncommon
    case rare = "Rar"               // Rare
    case epic = "Epic"              // Epic
    case legendary = "Legendar"     // Legendary
    case mythic = "Mitic"           // Mythic
    
    var color: Color {
        switch self {
        case .common: return .gray
        case .uncommon: return .green
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        case .mythic: return .yellow
        }
    }
    
    var culturalValue: Int {
        switch self {
        case .common: return 10
        case .uncommon: return 25
        case .rare: return 50
        case .epic: return 100
        case .legendary: return 250
        case .mythic: return 500
        }
    }
}

/// Romanian cultural achievement with heritage significance
struct LegacyRomanianAchievement: Identifiable {
    let id: UUID
    let category: RomanianAchievementCategory
    let rarity: LegacyAchievementRarity
    let titleRomanian: String
    let titleEnglish: String
    let descriptionRomanian: String
    let descriptionEnglish: String
    let culturalStory: String
    let historicalContext: String
    let requirement: LegacyAchievementRequirement
    let reward: LegacyAchievementReward
    let culturalPoints: Int
    let unlockLevel: Int
    let isHidden: Bool
    
    var isUnlocked: Bool {
        AchievementManager.shared.isAchievementUnlocked(id)
    }
    
    var progress: Float {
        AchievementManager.shared.getAchievementProgress(id)
    }
    
    init(
        category: RomanianAchievementCategory,
        rarity: LegacyAchievementRarity,
        titleRomanian: String,
        titleEnglish: String,
        descriptionRomanian: String,
        descriptionEnglish: String,
        culturalStory: String,
        historicalContext: String,
        requirement: LegacyAchievementRequirement,
        reward: LegacyAchievementReward,
        unlockLevel: Int = 1,
        isHidden: Bool = false
    ) {
        self.id = UUID()
        self.category = category
        self.rarity = rarity
        self.titleRomanian = titleRomanian
        self.titleEnglish = titleEnglish
        self.descriptionRomanian = descriptionRomanian
        self.descriptionEnglish = descriptionEnglish
        self.culturalStory = culturalStory
        self.historicalContext = historicalContext
        self.requirement = requirement
        self.reward = reward
        self.culturalPoints = rarity.culturalValue
        self.unlockLevel = unlockLevel
        self.isHidden = isHidden
    }
}

/// Achievement requirements with cultural context
enum LegacyAchievementRequirement: Codable {
    case playGames(count: Int)
    case winGames(count: Int)
    case playSevenCards(count: Int)
    case playEightAtRightTime(count: Int)
    case capturePointCards(count: Int)
    case winWithoutLosingTricks(count: Int)
    case playConsecutiveGames(count: Int)
    case achieveWinStreak(count: Int)
    case completeGamesInTime(count: Int, seconds: Int)
    case learnCulturalFacts(count: Int)
    case masterDifficulty(difficulty: AIDifficulty, games: Int)
    case exhibitSportsmanship(count: Int)
    case teachNewPlayers(count: Int)
    case preserveCulturalTraditions(count: Int)
    
    var progressDescription: String {
        switch self {
        case .playGames(let count):
            return "Joacă \(count) jocuri"
        case .winGames(let count):
            return "Câștigă \(count) jocuri"
        case .playSevenCards(let count):
            return "Joacă \(count) cărți de șapte"
        case .playEightAtRightTime(let count):
            return "Joacă \(count) cărți de opt la momentul potrivit"
        case .capturePointCards(let count):
            return "Capturează \(count) cărți cu puncte"
        case .winWithoutLosingTricks(let count):
            return "Câștigă \(count) jocuri fără să pierzi levate"
        case .playConsecutiveGames(let count):
            return "Joacă \(count) jocuri consecutive"
        case .achieveWinStreak(let count):
            return "Obține o serie de \(count) victorii"
        case .completeGamesInTime(let count, let seconds):
            return "Completează \(count) jocuri în sub \(seconds) secunde"
        case .learnCulturalFacts(let count):
            return "Învață \(count) fapte culturale"
        case .masterDifficulty(let difficulty, let games):
            return "Stăpânește dificultatea \(difficulty.rawValue) în \(games) jocuri"
        case .exhibitSportsmanship(let count):
            return "Demonstrează sportivitate în \(count) jocuri"
        case .teachNewPlayers(let count):
            return "Învață \(count) jucători noi"
        case .preserveCulturalTraditions(let count):
            return "Păstrează \(count) tradiții culturale"
        }
    }
}

/// Achievement rewards with Romanian cultural value
enum LegacyAchievementReward {
    case culturalPoints(Int)
    case cardBack(String)
    case characterUnlock(RomanianCharacterType)
    case musicUnlock(String)
    case storyUnlock(String)
    case titleUnlock(String)
    case specialAnimation(String)
    case culturalInsight(String)
    case heritageContent(String)
    
    var displayName: String {
        switch self {
        case .culturalPoints(let points):
            return "\(points) Puncte Culturale"
        case .cardBack(let name):
            return "Verso de carte: \(name)"
        case .characterUnlock(let character):
            return "Personaj: \(character.rawValue)"
        case .musicUnlock(let track):
            return "Muzică: \(track)"
        case .storyUnlock(let story):
            return "Poveste: \(story)"
        case .titleUnlock(let title):
            return "Titlu: \(title)"
        case .specialAnimation(let animation):
            return "Animație: \(animation)"
        case .culturalInsight(let insight):
            return "Perspective culturală: \(insight)"
        case .heritageContent(let content):
            return "Conținut patrimonial: \(content)"
        }
    }
}

// MARK: - Legacy Rarity Utilities for UI

extension LegacyAchievementRarity {
    var starCount: Int {
        switch self {
        case .common: return 1
        case .uncommon: return 2
        case .rare: return 3
        case .epic: return 4
        case .legendary: return 5
        case .mythic: return 6
        }
    }
    
    var displayName: String {
        switch self {
        case .common: return "Obișnuit"
        case .uncommon: return "Neobișnuit"
        case .rare: return "Rar"
        case .epic: return "Epic"
        case .legendary: return "Legendar"
        case .mythic: return "Mitic"
        }
    }
}

/// Main achievement manager with Romanian cultural focus
@MainActor
class AchievementManager: ObservableObject {
    static let shared = AchievementManager()
    
    var unlockedAchievements: Set<UUID> = []
    var achievementProgress: [UUID: Float] = [:]
    var totalCulturalPoints: Int = 0
    var totalCulturalKnowledgePoints: Int = 0
    var playerLevel: Int = 1
    var playerTitle: String = "Începător" // Beginner
    var recentlyUnlocked: [RomanianAchievement] = []
    
    private var gameStatistics: [String: Int] = [:]
    
    // MARK: - Cultural Achievements Database
    
    let allAchievements: [RomanianAchievement]
    var achievements: [RomanianAchievement] { allAchievements }
    
    private init() {
        self.allAchievements = AchievementRegistry.shared.getAllAchievements()
        loadProgress()
    }

    // MARK: - Public Query API

    func isAchievementUnlocked(_ achievementId: UUID) -> Bool {
        return unlockedAchievements.contains(achievementId)
    }

    func getAchievementProgress(_ achievementId: UUID) -> Float {
        return achievementProgress[achievementId] ?? 0.0
    }

    func getRecentlyUnlockedAchievements() -> [RomanianAchievement] {
        return recentlyUnlocked
    }
    
    /// Create comprehensive Romanian cultural achievements
    private static func createRomanianAchievements() -> [LegacyRomanianAchievement] {
    return []
}

    /// Unlock achievement and apply rewards
    private func unlockAchievement(_ achievement: RomanianAchievement) {
        unlockedAchievements.insert(achievement.id)
        totalCulturalPoints += achievement.experiencePoints
        totalCulturalKnowledgePoints += achievement.culturalKnowledgePoints
        recentlyUnlocked.append(achievement)

        // Apply unlockable content (placeholder routing)
        grantReward(achievement.unlockableContent)

        // Update player level and title
        updatePlayerStatus()

        // Trigger achievement notification
        NotificationCenter.default.post(
            name: .achievementUnlocked,
            object: achievement
        )
    }

    /// Grant achievement unlockable content (placeholder)
    private func grantReward(_ content: [UnlockableContent]) {
        for item in content {
            switch item {
            case .cardBack(let name):
                CardCollectionManager.shared.unlockCardBack(name)
            case .title(let title):
                PlayerTitleManager.shared.unlockTitle(title)
            case .musicTrack(_), .folkStory(_), .culturalFact(_), .gameTheme(_), .avatar(_), .decorator(_):
                // Future: route to appropriate systems
                break
            }
        }
    }
    
    /// Update player level and title based on cultural points
    private func updatePlayerStatus() {
        let newLevel = calculatePlayerLevel(totalCulturalPoints)
        if newLevel > playerLevel {
            playerLevel = newLevel
            playerTitle = getPlayerTitle(for: newLevel)
        }
    }
    
    /// Calculate player level from cultural points
    private func calculatePlayerLevel(_ points: Int) -> Int {
        switch points {
        case 0..<100: return 1
        case 100..<300: return 2
        case 300..<600: return 3
        case 600..<1000: return 4
        case 1000..<1500: return 5
        case 1500..<2500: return 6
        case 2500..<4000: return 7
        case 4000..<6000: return 8
        case 6000..<9000: return 9
        case 9000..<13000: return 10
        default: return min(10 + (points - 13000) / 2000, 50)
        }
    }
    
    /// Get Romanian cultural title for player level
    private func getPlayerTitle(for level: Int) -> String {
        switch level {
        case 1: return "Începător"           // Beginner
        case 2: return "Ucenic"              // Apprentice
        case 3: return "Jucător"             // Player
        case 4: return "Priceput"            // Skilled
        case 5: return "Experimentat"        // Experienced
        case 6: return "Meșter"              // Master
        case 7: return "Mare Meșter"         // Grand Master
        case 8: return "Expert"              // Expert
        case 9: return "Maestru"             // Maestro
        case 10: return "Legendă"            // Legend
        default: return "Păstrător Etern de Tradiții" // Eternal Keeper of Traditions
        }
    }
    
    // MARK: - Persistence
    
    private func saveProgress() {
        // Save to UserDefaults or Core Data
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(Array(unlockedAchievements)) {
            UserDefaults.standard.set(data, forKey: "unlockedAchievements")
        }
        if let data = try? encoder.encode(achievementProgress) {
            UserDefaults.standard.set(data, forKey: "achievementProgress")
        }
        UserDefaults.standard.set(totalCulturalPoints, forKey: "totalCulturalPoints")
        UserDefaults.standard.set(playerLevel, forKey: "playerLevel")
        UserDefaults.standard.set(playerTitle, forKey: "playerTitle")
    }
    
    private func loadProgress() {
        let decoder = JSONDecoder()
        
        if let data = UserDefaults.standard.data(forKey: "unlockedAchievements"),
           let achievements = try? decoder.decode([UUID].self, from: data) {
            unlockedAchievements = Set(achievements)
        }
        
        if let data = UserDefaults.standard.data(forKey: "achievementProgress"),
           let progress = try? decoder.decode([UUID: Float].self, from: data) {
            achievementProgress = progress
        }
        
        totalCulturalPoints = UserDefaults.standard.integer(forKey: "totalCulturalPoints")
        playerLevel = UserDefaults.standard.integer(forKey: "playerLevel")
        playerTitle = UserDefaults.standard.string(forKey: "playerTitle") ?? "Începător"
    }
    
    // MARK: - Event Tracking API
    
    /// Track game events for achievement progress
    func trackEvent(_ event: AchievementGameEvent) {
        // Simple implementation to satisfy compiler
        // This can be expanded later for actual achievement tracking
        switch event {
        case .gameCompleted:
            gameStatistics["gamesCompleted", default: 0] += 1
        case .gameWon:
            gameStatistics["gamesWon", default: 0] += 1
        case .gameStarted:
            gameStatistics["gamesStarted", default: 0] += 1
        case .sevenCardPlayed, .playedSevenCard:
            gameStatistics["sevenCardsPlayed", default: 0] += 1
        case .playedPointCard:
            gameStatistics["pointCardsPlayed", default: 0] += 1
        case .dominantVictory:
            gameStatistics["dominantVictories", default: 0] += 1
        case .eightPlayedAtRightTime:
            gameStatistics["eightCardsPlayedOptimally", default: 0] += 1
        case .pointCardCaptured:
            gameStatistics["pointCardsCaptured", default: 0] += 1
        case .playedCard:
            gameStatistics["totalCardsPlayed", default: 0] += 1
        case .culturalInteraction:
            gameStatistics["culturalInteractions", default: 0] += 1
        default:
            break
        }
        
        // Save progress after tracking
        saveProgress()
    }
}

/// Achievement-related game events
enum AchievementGameEvent {
    case gameCompleted
    case gameWon
    case gameStarted
    case sevenCardPlayed
    case playedSevenCard
    case playedPointCard
    case eightPlayedAtRightTime
    case pointCardCaptured
    case playedCard
    case culturalInteraction
    case dominantVictory
    case perfectTiming
    case winStreakUpdated
    case culturalFactLearned
    case sportsmanshipShown
    case traditionalStyleMaintained
    case expertLevelReached
}

// MARK: - Notification Extensions

// Note: Global achievementUnlocked notification is defined in RomanianCulturalAchievementManager

// MARK: - Supporting Managers (Stubs for Integration)

class CardCollectionManager {
    static let shared = CardCollectionManager()
    private init() {}
    
    func unlockCardBack(_ cardBack: String) {
        // Implementation for unlocking card backs
    }
}

class CharacterUnlockManager {
    static let shared = CharacterUnlockManager()
    private init() {}
    
    func unlockCharacter(_ character: RomanianCharacterType) {
        // Implementation for unlocking characters
    }
}

class MusicLibraryManager {
    static let shared = MusicLibraryManager()
    private init() {}
    
    func unlockTrack(_ track: String) {
        // Implementation for unlocking music tracks
    }
}

class PlayerTitleManager {
    static let shared = PlayerTitleManager()
    private init() {}
    
    func unlockTitle(_ title: String) {
        // Implementation for unlocking player titles
    }
}
