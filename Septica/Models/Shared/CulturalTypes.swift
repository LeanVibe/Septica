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
    
    var displayName: String {
        switch self {
        case .traditionInvoked: return "Tradition Invoked"
        case .wisdomShared: return "Wisdom Shared"
        case .folkloreReference: return "Folklore Reference"
        case .strategicTradition: return "Strategic Tradition"
        case .culturalPattern: return "Cultural Pattern"
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
    
    var displayName: String {
        switch self {
        case .beginner: return "Începător"
        case .apprentice: return "Ucenic"
        case .practitioner: return "Practicant"
        case .expert: return "Expert"
        case .master: return "Maestru"
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