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
    
    /// Regional Romanian folk music associated with each arena
    var traditionalMusic: [String] {
        switch self {
        case .sateImarica: return ["hora_satului", "joc_de_doi"]
        case .satuMihai: return ["brau_muntean", "de_la_mihai_voda"]
        case .orasulBrara: return ["sarba_din_brara", "hora_mare"]
        case .orasulBacau: return ["joc_moldovenesc", "hora_din_moldova"]
        case .orasulCluj: return ["hora_din_ardeal", "batuta_clujana"]
        case .orasulConstanta: return ["joc_dobrogean", "cantec_de_port"]
        case .orasulIasi: return ["hora_academiei", "joc_moldav"]
        case .orasulTimisoara: return ["sarba_banateana", "joc_de_nunta"]
        case .orasulBrasov: return ["joc_brasovean", "hora_din_tara_barsei"]
        case .orasulSibiu: return ["hora_sibiana", "joc_sasesc"]
        case .marealeBucuresti: return ["hora_bucurestiului", "joc_de_capitala"]
        }
    }
    
    /// Traditional folk tales and stories from each region
    var regionalFolkTales: [String] {
        switch self {
        case .sateImarica: return ["Legenda Primul Joc de Septica", "Povestea Satelor de Munte"]
        case .satuMihai: return ["Mihai Viteazul și Cărțile", "Legenda Regelui Cărților"]
        case .orasulBrara: return ["Festivalul Primăverii", "Dansul Celor Șapte Cărți"]
        case .orasulBacau: return ["Meșterii din Bacău", "Povestea Celor Trei Brazi"]
        case .orasulCluj: return ["Castelul din Ardeal", "Legenda Voievodului"]
        case .orasulConstanta: return ["Povestea Mării Negre", "Pescarul și Cărțile"]
        case .orasulIasi: return ["Universitatea și Înțelepciunea", "Cronicile Moldovei"]
        case .orasulTimisoara: return ["Revoluția Libertății", "Eroii Banatului"]
        case .orasulBrasov: return ["Poarta Transilvaniei", "Legenda Tampei"]
        case .orasulSibiu: return ["Kapitala Culturală", "Ochii Orașului"]
        case .marealeBucuresti: return ["Inima României", "Legenda Marele București"]
        }
    }
    
    /// Traditional cultural symbols and patterns for each region
    var culturalSymbols: [String] {
        switch self {
        case .sateImarica: return ["ie_traditionala", "casa_de_lemn", "gard_impletit"]
        case .satuMihai: return ["coif_dacic", "steag_voievodal", "scut_medieval"]
        case .orasulBrara: return ["fluier_pastoral", "coroana_florii", "dansul_rotund"]
        case .orasulBacau: return ["olarit_traditional", "tesatura_moldoveneasca", "sculptura_lemn"]
        case .orasulCluj: return ["castelul_corvinilor", "heraldica_ardeal", "stemele_nobiliare"]
        case .orasulConstanta: return ["ancora_dacica", "delfin_pontic", "mosaicul_roman"]
        case .orasulIasi: return ["universitatea_1860", "palatul_culturii", "trei_ierarhi"]
        case .orasulTimisoara: return ["trandafirul_revolutiei", "catedrala_mitropolitana", "piata_victoriei"]
        case .orasulBrasov: return ["poarta_schei", "vulturul_negru", "cetatea_rasnov"]
        case .orasulSibiu: return ["ochii_caselor", "turnul_sfatului", "podul_minciunilor"]
        case .marealeBucuresti: return ["arcul_triumf", "ateneul_roman", "coroana_regala"]
        }
    }
    
    /// Specific cultural achievement unlocks for reaching this arena
    var culturalUnlocks: [String] {
        switch self {
        case .sateImarica: return ["basic_romanian_greetings", "simple_card_terms"]
        case .satuMihai: return ["historical_rulers", "medieval_traditions"]
        case .orasulBrara: return ["festival_customs", "folk_dance_basics"]
        case .orasulBacau: return ["artisan_crafts", "moldovan_culture"]
        case .orasulCluj: return ["transylvanian_history", "university_traditions"]
        case .orasulConstanta: return ["maritime_heritage", "ancient_tomis"]
        case .orasulIasi: return ["cultural_institutions", "moldovan_chronicles"]
        case .orasulTimisoara: return ["revolution_history", "banat_traditions"]
        case .orasulBrasov: return ["saxon_heritage", "mountain_folklore"]
        case .orasulSibiu: return ["european_capital_culture", "saxon_architecture"]
        case .marealeBucuresti: return ["national_symbols", "royal_heritage", "complete_cultural_mastery"]
        }
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
    
    // Romanian Avatar System (Inspired by Shuffle Cats character design)
    var selectedAvatar: String = RomanianCharacterAvatar.traditionalPlayer.rawValue
    var selectedAvatarFrame: String = AvatarFrame.woodenFrame.rawValue
    var unlockedAvatars: [String] = [RomanianCharacterAvatar.traditionalPlayer.rawValue]
    var unlockedAvatarFrames: [String] = [AvatarFrame.woodenFrame.rawValue]
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

// MARK: - Romanian Cultural Celebrations System

/// Comprehensive Romanian cultural celebrations and festivals
enum RomanianCulturalCelebration: String, CaseIterable, Codable, Sendable {
    case martisor = "martisor"                    // March 1st - Spring celebration
    case dragobete = "dragobete"                  // February 24th - Romanian love day
    case pasteOrtodox = "paste_ortodox"           // Orthodox Easter
    case mucenici = "mucenici"                    // March 9th - Saints celebration
    case sambataLazarului = "sambata_lazarului"   // Saturday before Palm Sunday
    case ziuaRomaniei = "ziua_romaniei"           // December 1st - National Day
    case sfantuNicolae = "sfantu_nicolae"         // December 6th - St. Nicholas
    case craciun = "craciun"                      // December 25th - Christmas
    case anuNou = "anu_nou"                       // January 1st - New Year
    case boboteaza = "boboteaza"                  // January 6th - Epiphany
    case zileMoscilor = "zile_moscilor"           // Days of the ancestors
    case sanzienele = "sanzienele"                // June 24th - Midsummer night
    
    var displayName: String {
        switch self {
        case .martisor: return "Mărțișor"
        case .dragobete: return "Dragobete"
        case .pasteOrtodox: return "Paștele Ortodox"
        case .mucenici: return "Mucenicii"
        case .sambataLazarului: return "Sâmbăta Lazarului"
        case .ziuaRomaniei: return "Ziua României"
        case .sfantuNicolae: return "Sfântul Nicolae"
        case .craciun: return "Crăciunul"
        case .anuNou: return "Anul Nou"
        case .boboteaza: return "Boboteaza"
        case .zileMoscilor: return "Zilele Moșilor"
        case .sanzienele: return "Sânzienele"
        }
    }
    
    var culturalDescription: String {
        switch self {
        case .martisor: return "Celebration of spring with red and white trinkets, bringing luck and joy"
        case .dragobete: return "Romanian day of love, celebrating romance and traditional courtship"
        case .pasteOrtodox: return "Orthodox Easter with painted eggs, traditional foods, and family gatherings"
        case .mucenici: return "Honoring the saints with traditional pastries shaped like infinity"
        case .sambataLazarului: return "Young women's celebration with flowers and traditional songs"
        case .ziuaRomaniei: return "Romania's National Day celebrating unity and independence"
        case .sfantuNicolae: return "St. Nicholas bringing gifts to children, patron of sailors"
        case .craciun: return "Christmas celebration with carols, traditional foods, and family"
        case .anuNou: return "New Year with wishes for prosperity and good fortune"
        case .boboteaza: return "Epiphany with holy water blessing and diving for the cross"
        case .zileMoscilor: return "Honoring ancestors and visiting graves with flowers and food"
        case .sanzienele: return "Midsummer night with healing herbs and protection rituals"
        }
    }
    
    var traditionalActivities: [String] {
        switch self {
        case .martisor: return ["gifting_martisor", "spring_cleaning", "wearing_red_white"]
        case .dragobete: return ["courtship_games", "love_songs", "flower_picking"]
        case .pasteOrtodox: return ["egg_painting", "church_service", "family_feast"]
        case .mucenici: return ["baking_pastries", "saint_stories", "infinity_symbols"]
        case .sambataLazarului: return ["flower_crowns", "traditional_songs", "village_procession"]
        case .ziuaRomaniei: return ["flag_ceremonies", "national_anthem", "unity_celebrations"]
        case .sfantuNicolae: return ["gift_giving", "carol_singing", "shoe_traditions"]
        case .craciun: return ["christmas_carols", "traditional_feast", "midnight_service"]
        case .anuNou: return ["fireworks", "new_year_wishes", "prosperity_rituals"]
        case .boboteaza: return ["water_blessing", "cross_diving", "holy_water_sprinkling"]
        case .zileMoscilor: return ["grave_visiting", "ancestor_honoring", "memorial_foods"]
        case .sanzienele: return ["herb_gathering", "protective_wreaths", "night_rituals"]
        }
    }
    
    var specialCardEffects: [String] {
        switch self {
        case .martisor: return ["spring_bloom_effect", "red_white_sparkles"]
        case .dragobete: return ["heart_particle_effect", "love_glow"]
        case .pasteOrtodox: return ["painted_egg_patterns", "golden_church_bells"]
        case .mucenici: return ["infinity_symbol_trail", "saint_blessing_glow"]
        case .sambataLazarului: return ["flower_petal_shower", "meadow_breeze"]
        case .ziuaRomaniei: return ["tricolor_flag_wave", "national_anthem_notes"]
        case .sfantuNicolae: return ["gift_box_sparkles", "winter_snowflakes"]
        case .craciun: return ["christmas_star_trail", "warm_candle_glow"]
        case .anuNou: return ["firework_explosions", "golden_confetti"]
        case .boboteaza: return ["holy_water_droplets", "blessed_cross_shine"]
        case .zileMoscilor: return ["ancestral_wisdom_aura", "memorial_candle_flicker"]
        case .sanzienele: return ["healing_herb_swirl", "moonlight_mystique"]
        }
    }
    
    var celebrationRewards: [String] {
        switch self {
        case .martisor: return ["martisor_card_back", "spring_avatar_frame", "luck_bonus"]
        case .dragobete: return ["love_themed_cards", "romantic_music_track", "heart_symbols"]
        case .pasteOrtodox: return ["painted_egg_collection", "easter_table_theme", "resurrection_music"]
        case .mucenici: return ["saint_blessing_effect", "infinity_pattern_unlock", "spiritual_bonus"]
        case .sambataLazarului: return ["flower_crown_avatar", "meadow_table_theme", "youth_celebration"]
        case .ziuaRomaniei: return ["national_symbols_unlock", "patriotic_music", "unity_achievement"]
        case .sfantuNicolae: return ["winter_gift_collection", "santa_helper_avatar", "generosity_bonus"]
        case .craciun: return ["christmas_card_collection", "carol_music_unlock", "family_blessing"]
        case .anuNou: return ["firework_effects", "prosperity_symbols", "new_beginning_bonus"]
        case .boboteaza: return ["holy_water_blessing", "divine_protection_aura", "spiritual_cleansing"]
        case .zileMoscilor: return ["ancestral_wisdom_unlock", "memorial_candle_effect", "heritage_bonus"]
        case .sanzienele: return ["healing_herb_collection", "mystical_powers", "protection_charm"]
        }
    }
}

/// Cultural celebration tracking and rewards
struct CulturalCelebrationProgress: Codable, Sendable {
    var participatedCelebrations: [String] = [] // Store as raw values
    var celebrationStreaks: [String: Int] = [:] // celebration -> consecutive years
    var culturalEducationUnlocks: [String] = []
    var seasonalRewards: [String] = []
    var currentActiveCelebration: String? // Store as raw value
    var celebrationStartDate: Date?
    var celebrationEndDate: Date?
    
    /// Check if a celebration is currently active based on date
    func isActiveCelebration(_ celebrationRawValue: String, on date: Date = Date()) -> Bool {
        guard let celebration = RomanianCulturalCelebration(rawValue: celebrationRawValue) else { return false }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day], from: date)
        
        switch celebration {
        case .martisor: return components.month == 3 && components.day == 1
        case .dragobete: return components.month == 2 && components.day == 24
        case .mucenici: return components.month == 3 && components.day == 9
        case .ziuaRomaniei: return components.month == 12 && components.day == 1
        case .sfantuNicolae: return components.month == 12 && components.day == 6
        case .craciun: return components.month == 12 && (25...31).contains(components.day ?? 0)
        case .anuNou: return components.month == 1 && components.day == 1
        case .boboteaza: return components.month == 1 && components.day == 6
        case .sanzienele: return components.month == 6 && components.day == 24
        case .pasteOrtodox, .sambataLazarului, .zileMoscilor: 
            // These require complex Orthodox calendar calculations - for now, return false
            return false
        }
    }
    
    /// Helper to add a celebration by enum
    mutating func addCelebration(_ celebration: RomanianCulturalCelebration) {
        if !participatedCelebrations.contains(celebration.rawValue) {
            participatedCelebrations.append(celebration.rawValue)
        }
    }
    
    /// Helper to set current active celebration
    mutating func setActiveCelebration(_ celebration: RomanianCulturalCelebration?) {
        currentActiveCelebration = celebration?.rawValue
    }
    
    /// Helper to get current active celebration as enum
    func getCurrentActiveCelebration() -> RomanianCulturalCelebration? {
        guard let rawValue = currentActiveCelebration else { return nil }
        return RomanianCulturalCelebration(rawValue: rawValue)
    }
}

// MARK: - Romanian Avatar System (Inspired by Shuffle Cats)

/// Romanian character avatars representing different cultural archetypes
enum RomanianCharacterAvatar: String, CaseIterable, Codable, Sendable {
    case traditionalPlayer = "traditional_player"
    case folkMusician = "folk_musician"
    case villageElder = "village_elder"
    case transylvanianNoble = "transylvanian_noble"
    case moldovanScholar = "moldovan_scholar"
    case wallachianWarrior = "wallachian_warrior"
    case carpathianShepherd = "carpathian_shepherd"
    case danubianFisherman = "danubian_fisherman"
    case bucovinianArtisan = "bucovinian_artisan"
    case dobrudjanMerchant = "dobrudjan_merchant"
    
    var displayName: String {
        switch self {
        case .traditionalPlayer: return "Jucător Tradițional"
        case .folkMusician: return "Muzicant Popular"
        case .villageElder: return "Bătrânul Satului"
        case .transylvanianNoble: return "Nobil Ardelean"
        case .moldovanScholar: return "Cărturar Moldovean"
        case .wallachianWarrior: return "Vitez Muntenesc"
        case .carpathianShepherd: return "Cioban Carpatin"
        case .danubianFisherman: return "Pescar Dunărean"
        case .bucovinianArtisan: return "Meșter Bucovinian"
        case .dobrudjanMerchant: return "Negustor Dobrogean"
        }
    }
    
    var culturalDescription: String {
        switch self {
        case .traditionalPlayer: return "Classic Romanian card player from the countryside"
        case .folkMusician: return "Traditional musician keeping Romanian heritage alive"
        case .villageElder: return "Wise elder who taught generations Septica strategies"
        case .transylvanianNoble: return "Aristocrat from the castles of Transylvania"
        case .moldovanScholar: return "Intellectual from the monasteries of Moldova"
        case .wallachianWarrior: return "Brave defender from the plains of Wallachia"
        case .carpathianShepherd: return "Mountain shepherd with ancient wisdom"
        case .danubianFisherman: return "River dweller from the Danube Delta"
        case .bucovinianArtisan: return "Master craftsman from Bucovina region"
        case .dobrudjanMerchant: return "Trader from the Black Sea coast"
        }
    }
    
    var requiredArena: RomanianArena {
        switch self {
        case .traditionalPlayer: return .sateImarica // Always available
        case .folkMusician: return .satuMihai
        case .villageElder: return .orasulBrara
        case .transylvanianNoble: return .orasulBrasov
        case .moldovanScholar: return .orasulIasi
        case .wallachianWarrior: return .marealeBucuresti
        case .carpathianShepherd: return .orasulBacau
        case .danubianFisherman: return .orasulConstanta
        case .bucovinianArtisan: return .orasulSibiu
        case .dobrudjanMerchant: return .orasulTimisoara
        }
    }
    
    var unLockRequirements: AvatarUnlockRequirements {
        switch self {
        case .traditionalPlayer: return AvatarUnlockRequirements(gamesPlayed: 0, trophies: 0, culturalBadges: 0)
        case .folkMusician: return AvatarUnlockRequirements(gamesPlayed: 10, trophies: 150, culturalBadges: 1)
        case .villageElder: return AvatarUnlockRequirements(gamesPlayed: 25, trophies: 300, culturalBadges: 3)
        case .transylvanianNoble: return AvatarUnlockRequirements(gamesPlayed: 50, trophies: 1200, culturalBadges: 5)
        case .moldovanScholar: return AvatarUnlockRequirements(gamesPlayed: 75, trophies: 900, culturalBadges: 7)
        case .wallachianWarrior: return AvatarUnlockRequirements(gamesPlayed: 100, trophies: 1500, culturalBadges: 10)
        case .carpathianShepherd: return AvatarUnlockRequirements(gamesPlayed: 40, trophies: 600, culturalBadges: 4)
        case .danubianFisherman: return AvatarUnlockRequirements(gamesPlayed: 60, trophies: 750, culturalBadges: 6)
        case .bucovinianArtisan: return AvatarUnlockRequirements(gamesPlayed: 80, trophies: 1350, culturalBadges: 8)
        case .dobrudjanMerchant: return AvatarUnlockRequirements(gamesPlayed: 70, trophies: 1050, culturalBadges: 6)
        }
    }
}

/// Avatar frames that unlock with arena progression (Shuffle Cats frame style)
enum AvatarFrame: String, CaseIterable, Codable, Sendable {
    case woodenFrame = "wooden_frame"
    case folkFrame = "folk_art_frame"
    case silverFrame = "silver_ornate_frame"
    case goldenFrame = "golden_royal_frame"
    case traditionFrame = "traditional_carved_frame"
    case culturalFrame = "cultural_heritage_frame"
    case legendaryFrame = "legendary_romanian_frame"
    
    var displayName: String {
        switch self {
        case .woodenFrame: return "Ramă de Lemn"
        case .folkFrame: return "Ramă Populară"
        case .silverFrame: return "Ramă de Argint"
        case .goldenFrame: return "Ramă de Aur"
        case .traditionFrame: return "Ramă Tradițională"
        case .culturalFrame: return "Ramă Culturală"
        case .legendaryFrame: return "Ramă Legendară"
        }
    }
    
    var requiredArena: RomanianArena {
        switch self {
        case .woodenFrame: return .sateImarica
        case .folkFrame: return .orasulBrara
        case .silverFrame: return .orasulCluj
        case .goldenFrame: return .orasulBrasov
        case .traditionFrame: return .orasulTimisoara
        case .culturalFrame: return .orasulSibiu
        case .legendaryFrame: return .marealeBucuresti
        }
    }
    
    var frameColor: String {
        switch self {
        case .woodenFrame: return "#8B4513" // Saddle brown
        case .folkFrame: return "#DC143C" // Traditional red
        case .silverFrame: return "#C0C0C0" // Silver
        case .goldenFrame: return "#FFD700" // Gold
        case .traditionFrame: return "#4169E1" // Royal blue
        case .culturalFrame: return "#800080" // Purple
        case .legendaryFrame: return "#FF6347" // Romanian flag inspired
        }
    }
}

/// Avatar unlock requirements structure
struct AvatarUnlockRequirements: Codable, Sendable {
    let gamesPlayed: Int
    let trophies: Int
    let culturalBadges: Int
    
    /// Check if player meets unlock requirements
    func isUnlockedBy(profile: CloudKitPlayerProfile) -> Bool {
        return profile.totalGamesPlayed >= gamesPlayed &&
               profile.trophies >= trophies &&
               profile.culturalEducationProgress.culturalBadges.count >= culturalBadges
    }
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

// NOTE: CloudKitError is defined centrally in SepticaCloudKitManager.swift

// MARK: - Extensions

extension Float {
    func clamped(to range: ClosedRange<Float>) -> Float {
        return Swift.max(range.lowerBound, Swift.min(range.upperBound, self))
    }
}
