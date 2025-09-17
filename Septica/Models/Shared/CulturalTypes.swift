//
//  CulturalTypes.swift
//  Septica
//
//  Shared cultural data types for Romanian Septica game
//  Provides common types used across cultural intelligence, analytics, and strategy modules
//

import Foundation

// MARK: - Cultural Moment Types

/// Cultural moment captured during gameplay
struct CulturalMoment {
    let type: CulturalMomentType
    let context: String
    let significance: Double
    let timestamp: Date
    
    init(type: CulturalMomentType, context: String, significance: Double = 0.5, timestamp: Date = Date()) {
        self.type = type
        self.context = context
        self.significance = significance
        self.timestamp = timestamp
    }
}

/// Types of cultural moments that can be captured
enum CulturalMomentType: String, CaseIterable {
    case traditionInvoked = "tradition_invoked"
    case wisdomShared = "wisdom_shared"
    case folkloreReference = "folklore_reference"
    case strategicTradition = "strategic_tradition"
    case culturalPattern = "cultural_pattern"
    case strategicExcellence = "strategic_excellence"
    case strategicWildCard = "strategic_wild_card"
    case perfectTiming = "perfect_timing"
    case culturalTradition = "cultural_tradition"
    case folkloreConnection = "folklore_connection"
    case seasonalReference = "seasonal_reference"
    
    var displayName: String {
        switch self {
        case .traditionInvoked: return "Tradition Invoked"
        case .wisdomShared: return "Wisdom Shared"
        case .folkloreReference: return "Folklore Reference"
        case .strategicTradition: return "Strategic Tradition"
        case .culturalPattern: return "Cultural Pattern"
        case .strategicExcellence: return "Strategic Excellence"
        case .strategicWildCard: return "Strategic Wild Card"
        case .perfectTiming: return "Perfect Timing"
        case .culturalTradition: return "Cultural Tradition"
        case .folkloreConnection: return "Folklore Connection"
        case .seasonalReference: return "Seasonal Reference"
        }
    }
}

// MARK: - Cultural Mastery Types

enum CulturalMasteryLevel: String, CaseIterable {
    case beginner = "beginner"
    case apprentice = "apprentice"
    case practitioner = "practitioner"
    case expert = "expert"
    case master = "master"
    case culturalMaster = "cultural_master"
    case traditionalist = "traditionalist"
    case culturalApprentice = "cultural_apprentice"
    
    var displayName: String {
        switch self {
        case .beginner: return "Începător"
        case .apprentice: return "Ucenic"
        case .practitioner: return "Practicant"
        case .expert: return "Expert"
        case .master: return "Maestru"
        case .culturalMaster: return "Maestru Cultural"
        case .traditionalist: return "Tradiționalist"
        case .culturalApprentice: return "Ucenic Cultural"
        }
    }
}

// MARK: - Cultural Theme Types

struct CulturalTheme {
    let name: String
    let description: String
    let region: RomanianRegion?
    let elements: [String]
}

enum RomanianRegion: String, Codable, CaseIterable {
    case transylvania = "transylvania"
    case moldova = "moldova"
    case wallachia = "wallachia"
    case dobrudja = "dobrudja"
    case banat = "banat"
    case oltenia = "oltenia"
    case muntenia = "muntenia"
    case bucovina = "bucovina"
    case general = "general"
    
    var displayName: String {
        switch self {
        case .transylvania: return "Transilvania"
        case .moldova: return "Moldova"
        case .wallachia: return "Țara Românească"
        case .dobrudja: return "Dobrogea"
        case .banat: return "Banat"
        case .oltenia: return "Oltenia"
        case .muntenia: return "Muntenia"
        case .bucovina: return "Bucovina"
        case .general: return "România"
        }
    }
    
    public var localizedNameKey: String {
        return "region_\(rawValue)"
    }
    
    public var culturalColorScheme: (primary: String, secondary: String) {
        switch self {
        case .transylvania: return ("#8B0000", "#FFD700") // Dark red, gold
        case .moldova: return ("#000080", "#FFFFFF") // Navy blue, white
        case .wallachia: return ("#228B22", "#FFD700") // Forest green, gold
        case .dobrudja: return ("#4169E1", "#F0E68C") // Royal blue, khaki
        case .banat: return ("#8B4513", "#FFA500") // Saddle brown, orange
        case .oltenia: return ("#2E8B57", "#F5F5DC") // Sea green, beige
        case .muntenia: return ("#B22222", "#F0F8FF") // Fire brick, alice blue
        case .bucovina: return ("#4B0082", "#E6E6FA") // Indigo, lavender
        case .general: return ("#FF0000", "#FFFF00") // Romanian flag colors: red, yellow
        }
    }
}

enum RomanianCardSymbol: String, CaseIterable {
    case luckyHeart = "lucky_heart"
    case mysticalSpade = "mystical_spade"
    case fortuneDiamond = "fortune_diamond"
    case protectiveClub = "protective_club"
    case aceOfHearts = "ace_of_hearts"
    case aceOfSpades = "ace_of_spades"
    case valueCard = "value_card"
    case traditionalCard = "traditional_card"
    
    var displayName: String {
        switch self {
        case .luckyHeart: return "Inima Norocoasă"
        case .mysticalSpade: return "Pica Mistică"
        case .fortuneDiamond: return "Diamantul Norocului"
        case .protectiveClub: return "Treflă Protectoare"
        case .aceOfHearts: return "As de Cupă"
        case .aceOfSpades: return "As de Pică"
        case .valueCard: return "Carte de Valoare"
        case .traditionalCard: return "Carte Tradițională"
        }
    }
}