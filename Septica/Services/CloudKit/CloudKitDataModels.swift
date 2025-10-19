import Foundation
import SwiftUI

/// Minimal data containers required by the simplified CloudKit services.
struct CulturalEducationProgress: Codable, Equatable {
    var gameRulesLearned: [String]
    var folkTalesRead: Int
    var traditionalMusicKnowledge: Int
    var cardHistoryKnowledge: Int
    var quizScores: [String: Int]
    var culturalBadges: [String]

    init(
        gameRulesLearned: [String] = [],
        folkTalesRead: Int = 0,
        traditionalMusicKnowledge: Int = 0,
        cardHistoryKnowledge: Int = 0,
        quizScores: [String: Int] = [:],
        culturalBadges: [String] = []
    ) {
        self.gameRulesLearned = gameRulesLearned
        self.folkTalesRead = folkTalesRead
        self.traditionalMusicKnowledge = traditionalMusicKnowledge
        self.cardHistoryKnowledge = cardHistoryKnowledge
        self.quizScores = quizScores
        self.culturalBadges = culturalBadges
    }
}

struct CloudKitSyncSnapshot: Codable, Equatable {
    var lastSyncDate: Date?
    var pendingRecords: Int = 0
}

// MARK: - Romanian Character Customisation Types

enum RomanianCharacterAvatar: String, CaseIterable, Codable {
    case traditionalPlayer
    case villageElder
    case folkMusician
    case carpathianShepherd
    case transylvanianNoble
    case moldovanScholar
    case wallachianWarrior
    case danubianFisherman
    case bucovinianArtisan
    case dobrudjanMerchant

    var displayName: String {
        switch self {
        case .traditionalPlayer: return "Jucător Tradițional"
        case .villageElder: return "Bătrânul Satului"
        case .folkMusician: return "Muzicant Popular"
        case .carpathianShepherd: return "Cioban Carpatin"
        case .transylvanianNoble: return "Nobil Transilvănean"
        case .moldovanScholar: return "Cărturar Moldovean"
        case .wallachianWarrior: return "Războinic Muntenesc"
        case .danubianFisherman: return "Pescar Dunărean"
        case .bucovinianArtisan: return "Meșter Bucovinean"
        case .dobrudjanMerchant: return "Negustor Dobrogean"
        }
    }

    /// Emoji representation for the avatar
    var emoji: String {
        switch self {
        case .traditionalPlayer: return "👤"
        case .villageElder: return "👴"
        case .folkMusician: return "🎵"
        case .carpathianShepherd: return "🐑"
        case .transylvanianNoble: return "👑"
        case .moldovanScholar: return "📚"
        case .wallachianWarrior: return "⚔️"
        case .danubianFisherman: return "🎣"
        case .bucovinianArtisan: return "🎨"
        case .dobrudjanMerchant: return "💰"
        }
    }

    /// Cultural theme associated with the avatar
    var culturalTheme: String {
        switch self {
        case .traditionalPlayer: return "Tradițional"
        case .villageElder: return "Sat Românesc"
        case .folkMusician: return "Muzică Populară"
        case .carpathianShepherd: return "Carpați"
        case .transylvanianNoble: return "Transilvania"
        case .moldovanScholar: return "Moldova"
        case .wallachianWarrior: return "Țara Românească"
        case .danubianFisherman: return "Dunăre"
        case .bucovinianArtisan: return "Bucovina"
        case .dobrudjanMerchant: return "Dobrogea"
        }
    }

    /// Maps avatar to character type for emote system integration
    var characterType: RomanianCharacterType {
        switch self {
        case .traditionalPlayer: return .pacala
        case .villageElder: return .babaCloantza
        case .folkMusician: return .pacala
        case .carpathianShepherd: return .fatFrumos
        case .transylvanianNoble: return .fatFrumos
        case .moldovanScholar: return .babaCloantza
        case .wallachianWarrior: return .strigoi
        case .danubianFisherman: return .zmeu
        case .bucovinianArtisan: return .iele
        case .dobrudjanMerchant: return .zmeu
        }
    }
}

enum AvatarFrame: String, CaseIterable, Codable {
    case woodenFrame
    case folkFrame
    case goldenFrame
    case legendaryFrame

    var displayName: String {
        switch self {
        case .woodenFrame: return "Ramă din Lemn"
        case .folkFrame: return "Ramă Folclorică"
        case .goldenFrame: return "Ramă Aurită"
        case .legendaryFrame: return "Ramă Legendară"
        }
    }

    /// Hex colour string used by SwiftUI helpers when rendering frames.
    var frameColor: String {
        switch self {
        case .woodenFrame: return "#8B4513"
        case .folkFrame: return "#C2185B"
        case .goldenFrame: return "#DAA520"
        case .legendaryFrame: return "#6A1B9A"
        }
    }
}

enum CulturalAchievement: String, CaseIterable, Codable {
    case septicaMaster
    case folkMusicLover
    case sevenWild
    case traditionalColors
    case culturalAmbassador
}

// MARK: - Romanian Arena Progression

enum RomanianArena: Int, CaseIterable, Codable {
    case sateImarica = 0
    case satuMihai
    case orasulBrara
    case orasulBacau
    case orasulCluj
    case orasulConstanta
    case orasulIasi
    case orasulTimisoara
    case orasulBrasov
    case orasulSibiu
    case marealeBucuresti

    var displayName: String {
        switch self {
        case .sateImarica: return "Satul Imarica"
        case .satuMihai: return "Satul Mihai"
        case .orasulBrara: return "Orașul Brăra"
        case .orasulBacau: return "Orașul Bacău"
        case .orasulCluj: return "Cluj Napoca"
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
        case .sateImarica: return "Sat tradițional din inima României."
        case .satuMihai: return "Pajiști verzi și tradiții autentice."
        case .orasulBrara: return "Târg plin de culoare și voie bună."
        case .orasulBacau: return "Oraș al meșteșugarilor și festivalurilor."
        case .orasulCluj: return "Capitală culturală și universitară."
        case .orasulConstanta: return "Port la Marea Neagră cu briză sărată."
        case .orasulIasi: return "Centru spiritual și artistic al Moldovei."
        case .orasulTimisoara: return "Oraș european cu arhitectură barocă."
        case .orasulBrasov: return "Cetate transilvăneană la poalele Carpaților."
        case .orasulSibiu: return "Meșteșuguri și cultură saxonă."
        case .marealeBucuresti: return "Grandețea capitalei regale."
        }
    }

    var description: String {
        switch self {
        case .sateImarica: return "Sat tradițional cu atmosferă autentică."
        case .satuMihai: return "Pajiști liniștite și dealuri românești."
        case .orasulBrara: return "Târg popular plin de culoare."
        case .orasulBacau: return "Meșteșugari și festivaluri de toamnă."
        case .orasulCluj: return "Capitală culturală și academică."
        case .orasulConstanta: return "Port la Marea Neagră cu briză marină."
        case .orasulIasi: return "Centru istoric și spiritual al Moldovei."
        case .orasulTimisoara: return "Arhitectură baroc și influențe europene."
        case .orasulBrasov: return "Cetate transilvăneană la poalele Carpaților."
        case .orasulSibiu: return "Capitală europeană a culturii."
        case .marealeBucuresti: return "Grandețea capitalei regale."
        }
    }

    /// Rough progression requirement used by tournament logic and UI gating.
    var requiredTrophies: Int {
        switch self {
        case .sateImarica: return 0
        case .satuMihai: return 50
        case .orasulBrara: return 120
        case .orasulBacau: return 200
        case .orasulCluj: return 320
        case .orasulConstanta: return 450
        case .orasulIasi: return 600
        case .orasulTimisoara: return 750
        case .orasulBrasov: return 900
        case .orasulSibiu: return 1050
        case .marealeBucuresti: return 1200
        }
    }
}
