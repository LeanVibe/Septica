//
//  CloudKitDataModels.swift
//  Septica
//
//  Data models for CloudKit integration - isolated from @MainActor to avoid concurrency issues
//  Romanian-themed progression system with cultural significance
//

import Foundation
import CloudKit

// MARK: - Romanian Cultural Arena System

/// Romanian-themed arena progression from villages to cities
enum RomanianArena: Int, CaseIterable, Codable, Sendable {
    case sateImarica = 0        // Imarica Village (Starting)
    case satuMihai = 1          // Mihai's Village
    case orasulBrara = 2        // Brara Town
    case orasulBacau = 3        // Bacău City
    case orasulCluj = 4         // Cluj-Napoca
    case orasulConstanta = 5    // Constanța (Black Sea)
    case orasulIasi = 6         // Iași (Cultural Center)
    case orasulTimisoara = 7    // Timișoara (Historic)
    case orasulBrasov = 8       // Brașov (Transylvania)
    case orasulSibiu = 9        // Sibiu (European Capital)
    case marealeBucuresti = 10  // Great Bucharest (Final)
    
    var displayName: String {
        switch self {
        case .sateImarica: return "Sat Imarica"
        case .satuMihai: return "Satul lui Mihai"
        case .orasulBrara: return "Orașul Brara"
        case .orasulBacau: return "Bacău"
        case .orasulCluj: return "Cluj-Napoca"
        case .orasulConstanta: return "Constanța"
        case .orasulIasi: return "Iași"
        case .orasulTimisoara: return "Timișoara"
        case .orasulBrasov: return "Brașov"
        case .orasulSibiu: return "Sibiu"
        case .marealeBucuresti: return "Marele București"
        }
    }
    
    var culturalDescription: String {
        switch self {
        case .sateImarica: return "Traditional village where Septica began"
        case .satuMihai: return "Village known for master card players"
        case .orasulBrara: return "Town of folk festivals"
        case .orasulBacau: return "City of skilled artisans"
        case .orasulCluj: return "Cultural heart of Transylvania"
        case .orasulConstanta: return "Ancient port city"
        case .orasulIasi: return "Intellectual capital of Moldova"
        case .orasulTimisoara: return "Historic revolution city"
        case .orasulBrasov: return "Gateway to Transylvania"
        case .orasulSibiu: return "European cultural capital"
        case .marealeBucuresti: return "The great capital of Romania"
        }
    }
    
    var requiredTrophies: Int {
        return rawValue * 150 // Each arena requires 150 more trophies
    }
}

// MARK: - Card Mastery System

/// Track individual card mastery and unlock visual effects
struct CardMastery: Codable, Sendable {
    let cardKey: String // e.g., "7_hearts", "ace_spades"
    var timesPlayed: Int = 0
    var successfulPlays: Int = 0 // Winning tricks with this card
    var specialPlays: Int = 0 // Using 7 as wild card, etc.
    var masteryLevel: Int = 0 // 0-5 mastery levels
    var unlockedEffects: [String] = [] // Visual effect identifiers
    
    var masteryProgress: Float {
        let nextLevelRequirement = masteryRequirement(for: masteryLevel + 1)
        return Float(timesPlayed) / Float(nextLevelRequirement)
    }
    
    func masteryRequirement(for level: Int) -> Int {
        switch level {
        case 1: return 25    // Bronze mastery - subtle glow
        case 2: return 100   // Silver mastery - enhanced animation
        case 3: return 300   // Gold mastery - particle effects
        case 4: return 750   // Diamond mastery - special sound
        case 5: return 1500  // Master mastery - full Romanian cultural effect
        default: return 0
        }
    }
}

// MARK: - Cultural Achievement System

/// Romanian heritage achievements with educational value
enum CulturalAchievement: String, CaseIterable, Codable, Sendable {
    case septicaMaster = "septica_master"
    case sevenWild = "seven_wild_master"
    case eightSpecial = "eight_special_master"
    case folkMusicLover = "folk_music_lover"
    case traditionalColors = "traditional_colors_unlocked"
    case heritageStudent = "heritage_student"
    case culturalAmbassador = "cultural_ambassador"
    
    var title: String {
        switch self {
        case .septicaMaster: return "Maestru Septică"
        case .sevenWild: return "Stăpânul Septelor"
        case .eightSpecial: return "Maestru Opti"
        case .folkMusicLover: return "Iubitor de Folclor"
        case .traditionalColors: return "Culorile Patriei"
        case .heritageStudent: return "Student al Tradițiilor"
        case .culturalAmbassador: return "Ambasador Cultural"
        }
    }
    
    var description: String {
        switch self {
        case .septicaMaster: return "Win 100 Septica games"
        case .sevenWild: return "Use 7 as wild card 50 times"
        case .eightSpecial: return "Win tricks with 8 when count % 3 == 0"
        case .folkMusicLover: return "Play with all traditional music tracks"
        case .traditionalColors: return "Unlock all Romanian color themes"
        case .heritageStudent: return "Complete cultural education modules"
        case .culturalAmbassador: return "Teach 10 friends about Romanian culture"
        }
    }
}

// MARK: - Player Profile Data Models

/// Player profile with Romanian cultural progression
struct CloudKitPlayerProfile: Codable, Sendable {
    let playerID: String
    var displayName: String
    var currentArena: RomanianArena
    var trophies: Int
    var totalGamesPlayed: Int
    var totalWins: Int
    var currentStreak: Int
    var longestStreak: Int
    var favoriteAIDifficulty: String
    var cardMasteries: [String: CardMastery] // Card key -> Mastery
    var achievements: [CulturalAchievement]
    var seasonalProgress: SeasonalProgress
    var preferences: GamePreferences
    var culturalEducationProgress: CulturalEducationProgress
    var lastPlayedDate: Date
    var createdDate: Date
    
    // Romanian cultural engagement metrics
    var heritageEngagementLevel: Float // 0.0 - 1.0
    var folkMusicListened: [String]
    var culturalStoriesRead: [String]
    var traditionalColorsUnlocked: [String]
}

/// Seasonal progress with Romanian celebrations
struct SeasonalProgress: Codable, Sendable {
    let seasonID: String
    var seasonTrophies: Int
    var seasonWins: Int
    var seasonChestsOpened: Int
    var seasonAchievements: [CulturalAchievement]
    var celebrationParticipation: [String: Bool] // Romanian holidays
    
    // Romanian seasonal celebrations
    var martisorCelebration: Bool = false    // March 1st celebration
    var dragobeteCelebration: Bool = false   // Romanian Valentine's Day
    var ziuaRomaniei: Bool = false           // Romania's National Day
}

/// Cultural education progress tracking
struct CulturalEducationProgress: Codable, Sendable {
    var gameRulesLearned: [String]
    var folkTalesRead: Int
    var traditionalMusicKnowledge: Int
    var cardHistoryKnowledge: Int
    var quizScores: [String: Int]
    var culturalBadges: [String]
}

/// Game preferences with cultural customization
struct GamePreferences: Codable, Sendable {
    var musicEnabled: Bool = true
    var selectedMusicTrack: String = "hora_unirii"
    var hapticFeedbackEnabled: Bool = true
    var ageGroup: String = "ages9to12"
    var culturalEducationEnabled: Bool = true
    var traditionalColorScheme: String = "classic_romanian"
    var cardBackStyle: String = "folk_art_patterns"
    var tableTheme: String = "wooden_traditional"
    var languagePreference: String = "romanian_english"
}

/// Individual game record for statistics and learning
struct CloudKitGameRecord: Codable, Sendable {
    let gameID: String
    let playerID: String
    let opponentType: String // "AI" or "Human"
    let aiDifficulty: String?
    let gameResult: String // "win", "loss"
    let finalScore: GameScore
    let gameDuration: TimeInterval
    let cardsPlayed: [CardPlayRecord]
    let culturalMomentsTriggered: [String]
    let timestamp: Date
    let arenaAtTimeOfPlay: RomanianArena
    
    // Learning and strategy analysis
    var sevenWildCardUses: Int
    var eightSpecialUses: Int
    var tricksWon: Int
    var pointsScored: Int
    var mistakesMade: [String]
    var strategicMoves: [String]
}

struct GameScore: Codable, Sendable {
    let playerScore: Int
    let opponentScore: Int
    let tricksWon: Int
    let tricksLost: Int
}

struct CardPlayRecord: Codable, Sendable {
    let cardKey: String
    let playOrder: Int
    let wasSuccessful: Bool
    let trickWon: Bool
    let pointsEarned: Int
    let contextNotes: String // e.g., "Used 7 as wild", "8 beat due to count rule"
}

// MARK: - Reward System Data Models

/// Romanian-themed chest types with cultural significance
enum ChestType: String, CaseIterable, Codable, Sendable {
    case wooden = "wooden"           // Basic village chest
    case folk = "folk"               // Romanian folk art themed
    case cultural = "cultural"       // Special Romanian heritage chest
    case seasonal = "seasonal"       // Holiday-themed (Martisor, etc.)
    case legendary = "legendary"     // Great Romanian masters
    case daily = "daily"             // Daily folk blessing
    
    var displayName: String {
        switch self {
        case .wooden: return "Lada de Lemn"
        case .folk: return "Lada Populară"
        case .cultural: return "Lada Culturală"
        case .seasonal: return "Lada Sărbătorii"
        case .legendary: return "Lada Legendară"
        case .daily: return "Binecuvântarea Zilnică"
        }
    }
    
    var culturalDescription: String {
        switch self {
        case .wooden: return "Traditional wooden chest from Romanian villages"
        case .folk: return "Decorated with authentic Romanian folk art patterns"
        case .cultural: return "Contains treasures of Romanian heritage"
        case .seasonal: return "Special celebration chest with holiday themes"
        case .legendary: return "Honors great Romanian cultural figures"
        case .daily: return "Daily blessing with folk wisdom"
        }
    }
    
    var openDuration: TimeInterval {
        switch self {
        case .wooden: return 4 * 3600      // 4 hours
        case .folk: return 8 * 3600        // 8 hours
        case .cultural: return 12 * 3600   // 12 hours
        case .seasonal: return 24 * 3600   // 24 hours
        case .legendary: return 48 * 3600  // 48 hours
        case .daily: return 0               // Instant
        }
    }
    
    var gemCost: Int {
        switch self {
        case .wooden: return 25
        case .folk: return 50
        case .cultural: return 100
        case .seasonal: return 200
        case .legendary: return 500
        case .daily: return 0
        }
    }
    
    var rarity: ChestRarity {
        switch self {
        case .wooden, .daily: return .common
        case .folk: return .rare
        case .cultural: return .epic
        case .seasonal, .legendary: return .legendary
        }
    }
}

enum ChestRarity: String, Codable, Sendable {
    case common = "common"
    case rare = "rare"
    case epic = "epic"
    case legendary = "legendary"
    
    var glowColor: String {
        switch self {
        case .common: return "#8B4513"      // Wood brown
        case .rare: return "#4169E1"        // Romanian blue
        case .epic: return "#FFD700"        // Romanian gold
        case .legendary: return "#DC143C"   // Romanian red
        }
    }
}

/// Individual reward chest with Romanian cultural theming
struct RewardChest: Codable, Identifiable, Sendable {
    let id: String
    let type: ChestType
    let earnedDate: Date
    var isOpening: Bool = false
    var openStartTime: Date?
    var rewards: [ChestReward] = []
    
    // Romanian cultural metadata
    let culturalTheme: String       // e.g., "transylvania_folk", "moldovan_traditions"
    let folkPattern: String         // Visual pattern identifier
    let seasonalBonus: Bool         // Extra rewards for Romanian holidays
    
    var timeUntilOpen: TimeInterval? {
        guard let startTime = openStartTime else { return nil }
        let elapsed = Date().timeIntervalSince(startTime)
        let remaining = type.openDuration - elapsed
        return max(0, remaining)
    }
    
    var isReadyToOpen: Bool {
        timeUntilOpen == 0
    }
    
    var progressPercentage: Float {
        guard let startTime = openStartTime else { return 0 }
        let elapsed = Date().timeIntervalSince(startTime)
        return Float(elapsed / type.openDuration).clamped(to: 0...1)
    }
}

/// Romanian-themed rewards with cultural education value
enum RewardType: String, CaseIterable, Codable, Sendable {
    case trophies = "trophies"
    case cards = "cards"
    case cardBacks = "card_backs"
    case folkMusic = "folk_music"
    case colorThemes = "color_themes"
    case culturalStories = "cultural_stories"
    case traditionalPatterns = "traditional_patterns"
    case achievements = "achievements"
    case gems = "gems"
    
    var displayName: String {
        switch self {
        case .trophies: return "Trofee"
        case .cards: return "Cărți de Joc"
        case .cardBacks: return "Modele de Cărți"
        case .folkMusic: return "Muzică Populară"
        case .colorThemes: return "Teme Tradiționale"
        case .culturalStories: return "Povești Culturale"
        case .traditionalPatterns: return "Modele Populare"
        case .achievements: return "Realizări"
        case .gems: return "Pietre Prețioase"
        }
    }
}

struct ChestReward: Codable, Identifiable, Sendable {
    let id: String
    let type: RewardType
    let quantity: Int
    let itemKey: String         // Specific item identifier
    let displayName: String
    let culturalSignificance: String
    let rarity: ChestRarity
    
    // Educational content for cultural rewards
    let educationalContent: String?
    let folkTaleReference: String?
    let historicalContext: String?
}

/// Chest slot for queue management (4 slots like Clash Royale)
struct ChestSlot: Identifiable, Sendable {
    let id: Int
    var chest: RewardChest?
    var isUnlocked: Bool
    
    var isEmpty: Bool { chest == nil }
}

/// Supporting types for CloudKit game results
struct CloudKitGameResult: Sendable {
    let isWin: Bool
    let score: Int
    let opponentType: String
    let culturalEngagement: Float
}

// MARK: - CloudKit Error Types

enum CloudKitError: LocalizedError, Sendable {
    case notAvailable
    case accountNotAvailable
    case syncFailed(Error)
    case recordNotFound
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "CloudKit is not available. Please check your iCloud settings."
        case .accountNotAvailable:
            return "iCloud account is not available. Please sign in to iCloud."
        case .syncFailed(let error):
            return "Sync failed: \(error.localizedDescription)"
        case .recordNotFound:
            return "Player profile not found."
        case .invalidData:
            return "Invalid data format."
        }
    }
}

// MARK: - Extensions

extension Float {
    func clamped(to range: ClosedRange<Float>) -> Float {
        return Swift.max(range.lowerBound, Swift.min(range.upperBound, self))
    }
}