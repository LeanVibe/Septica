//
//  TournamentDataModels.swift
//  Septica
//
//  Tournament data models for Romanian Septica tournaments
//  Supports cultural themes and educational Romanian heritage content
//

import Foundation
import CloudKit

// MARK: - Core Tournament Models

/// Romanian cultural tournament with educational and heritage features
struct RomanianTournament: Identifiable, Codable {
    let id: String
    let type: TournamentType
    let culturalTheme: CulturalTheme
    let arenaLocation: RomanianArena
    let createdBy: String
    let maxParticipants: Int
    var participants: [TournamentParticipant] = []
    let entryRequirements: TournamentEntryRequirements
    let culturalRewards: [CulturalReward]
    let folkMusicPlaylist: [FolkMusicTrack]
    let educationalContent: [EducationalContentItem]
    
    // Tournament timing
    let createdAt: Date = Date()
    let startTime: Date
    var actualStartTime: Date?
    let estimatedDuration: TimeInterval
    
    // Tournament state
    var status: TournamentStatus = .waitingForPlayers
    var bracket: TournamentBracket?
    var currentRound: Int = 1
    var totalCulturalMoments: Int = 0
    var educationalEngagementScore: Float = 0.0
    
    // Romanian cultural features
    var heritageStoriesTold: [String] = []
    var folkloreReferencesGenerated: [String] = []
    var traditionalMusicPlayTime: TimeInterval = 0
    var culturalEducationInteractions: Int = 0
    
    var canStart: Bool {
        return participants.count >= type.minimumParticipants && 
               participants.allSatisfy { $0.isReady } &&
               Date() >= startTime
    }
    
    var isComplete: Bool {
        return bracket?.isComplete == true
    }
    
    mutating func updateBracketWithResult(_ result: TournamentMatchResult) throws {
        guard var currentBracket = bracket else {
            throw TournamentError.noBracketFound
        }
        
        try currentBracket.updateWithMatchResult(result)
        bracket = currentBracket
        
        // Increment cultural moments if this was a culturally significant match
        if result.culturalMomentsGenerated > 0 {
            totalCulturalMoments += result.culturalMomentsGenerated
        }
        
        // Update educational engagement
        educationalEngagementScore += result.educationalEngagementScore
    }
}

/// Types of Romanian cultural tournaments
enum TournamentType: String, CaseIterable, Codable {
    case quickMatch = "quick_match"
    case romanianVillageChampionship = "village_championship"
    case folkFestivalTournament = "folk_festival"
    case culturalHeritageChampionship = "heritage_championship"
    case grandRomanianMasters = "grand_masters"
    case arenaSpecific = "arena_specific"
    case seasonalCelebration = "seasonal_celebration"
    
    var displayName: String {
        switch self {
        case .quickMatch: return "Quick Match"
        case .romanianVillageChampionship: return "Campionatul Satului"
        case .folkFestivalTournament: return "Turneu Festival Popular"
        case .culturalHeritageChampionship: return "Campionatul Moștenirii Culturale"
        case .grandRomanianMasters: return "Marii Maeștri Români"
        case .arenaSpecific: return "Campionatul Arenei"
        case .seasonalCelebration: return "Sărbătoare Sezonieră"
        }
    }
    
    var romanianDescription: String {
        switch self {
        case .quickMatch:
            return "Meci rapid pentru a testa abilitățile tale în Septică tradițională."
        case .romanianVillageChampionship:
            return "Campionatul satelor românești - demonstrează măiestria în tradițiile locale."
        case .folkFestivalTournament:
            return "Turneu inspirat de festivalurile populare românești cu muzică și povești tradiționale."
        case .culturalHeritageChampionship:
            return "Competiție dedicată păstrării și celebrării moștenirii culturale românești."
        case .grandRomanianMasters:
            return "Turneul de elită pentru maeștrii supremi ai Septicii românești."
        case .arenaSpecific:
            return "Campionat dedicat unei anumite arene românești și tradițiilor locale."
        case .seasonalCelebration:
            return "Turneu special pentru sărbătorile românești tradiționale."
        }
    }
    
    var minimumParticipants: Int {
        switch self {
        case .quickMatch: return 2
        case .romanianVillageChampionship: return 4
        case .folkFestivalTournament: return 8
        case .culturalHeritageChampionship: return 8
        case .grandRomanianMasters: return 16
        case .arenaSpecific: return 8
        case .seasonalCelebration: return 4
        }
    }
    
    var maxParticipants: Int {
        switch self {
        case .quickMatch: return 2
        case .romanianVillageChampionship: return 8
        case .folkFestivalTournament: return 16
        case .culturalHeritageChampionship: return 16
        case .grandRomanianMasters: return 32
        case .arenaSpecific: return 16
        case .seasonalCelebration: return 8
        }
    }
    
    var waitingPeriod: TimeInterval {
        switch self {
        case .quickMatch: return 60 // 1 minute
        case .romanianVillageChampionship: return 300 // 5 minutes
        case .folkFestivalTournament: return 600 // 10 minutes
        case .culturalHeritageChampionship: return 900 // 15 minutes
        case .grandRomanianMasters: return 1800 // 30 minutes
        case .arenaSpecific: return 600 // 10 minutes
        case .seasonalCelebration: return 300 // 5 minutes
        }
    }
    
    var estimatedDuration: TimeInterval {
        switch self {
        case .quickMatch: return 600 // 10 minutes
        case .romanianVillageChampionship: return 1800 // 30 minutes
        case .folkFestivalTournament: return 3600 // 1 hour
        case .culturalHeritageChampionship: return 3600 // 1 hour
        case .grandRomanianMasters: return 7200 // 2 hours
        case .arenaSpecific: return 2400 // 40 minutes
        case .seasonalCelebration: return 1800 // 30 minutes
        }
    }
    
    var entryRequirements: TournamentEntryRequirements {
        switch self {
        case .quickMatch:
            return TournamentEntryRequirements(minimumArena: .sateImarica, minimumCulturalLevel: 1, entryFee: 0)
        case .romanianVillageChampionship:
            return TournamentEntryRequirements(minimumArena: .satuMihai, minimumCulturalLevel: 2, entryFee: 50)
        case .folkFestivalTournament:
            return TournamentEntryRequirements(minimumArena: .orasulBrara, minimumCulturalLevel: 3, entryFee: 100)
        case .culturalHeritageChampionship:
            return TournamentEntryRequirements(minimumArena: .orasulCluj, minimumCulturalLevel: 5, entryFee: 200)
        case .grandRomanianMasters:
            return TournamentEntryRequirements(minimumArena: .orasulBrasov, minimumCulturalLevel: 8, entryFee: 500)
        case .arenaSpecific:
            return TournamentEntryRequirements(minimumArena: .sateImarica, minimumCulturalLevel: 1, entryFee: 100)
        case .seasonalCelebration:
            return TournamentEntryRequirements(minimumArena: .sateImarica, minimumCulturalLevel: 1, entryFee: 0)
        }
    }
}

/// Romanian cultural themes for tournaments
enum CulturalTheme: String, CaseIterable, Codable {
    case transylvanianTraditions = "transylvanian_traditions"
    case moldavianHeritage = "moldavian_heritage"
    case wallachianWisdom = "wallachian_wisdom"
    case dobrudjanSea = "dobrudjan_sea"
    
    var romanianName: String {
        switch self {
        case .transylvanianTraditions: return "Tradițiile Transilvaniei"
        case .moldavianHeritage: return "Moștenirea Moldovei"
        case .wallachianWisdom: return "Înțelepciunea Țării Românești"
        case .dobrudjanSea: return "Marea Dobrogei"
        }
    }
    
    var culturalDescription: String {
        switch self {
        case .transylvanianTraditions:
            return "Explorează tradițiile montane ale Transilvaniei, unde Septică se joacă în umbra Carpaților cu respectul pentru înțelepciunea străveche."
        case .moldavianHeritage:
            return "Descoperă moștenirea bogată a Moldovei, unde cântecele populare și jocurile de cărți se împletesc în sărbătorile tradiționale."
        case .wallachianWisdom:
            return "Învață înțelepciunea Țării Românești, unde strategia Septicii reflectă gândirea profundă a oamenilor din câmpiile fertile."
        case .dobrudjanSea:
            return "Simte briza Mării Negre în tradițiile Dobrogei, unde pescarii și marinarii au adaptat Septică pentru viața de pe coastă."
        }
    }
    
    var folkColorPalette: [String] {
        switch self {
        case .transylvanianTraditions:
            return ["#8B4513", "#228B22", "#CD853F", "#D2691E"] // Mountain browns and greens
        case .moldavianHeritage:
            return ["#DC143C", "#FFD700", "#006400", "#4169E1"] // Rich reds, golds, and blues
        case .wallachianWisdom:
            return ["#DAA520", "#B8860B", "#8B4513", "#2F4F4F"] // Golden fields and earth tones
        case .dobrudjanSea:
            return ["#4682B4", "#20B2AA", "#F0E68C", "#708090"] // Sea blues and sandy tones
        }
    }
    
    var representativeSymbols: [String] {
        switch self {
        case .transylvanianTraditions:
            return ["🏔️", "🌲", "🏰", "🎼"] // Mountains, forests, castles, music
        case .moldavianHeritage:
            return ["🌾", "🎵", "🏛️", "📚"] // Wheat, music, culture, wisdom
        case .wallachianWisdom:
            return ["⚖️", "📜", "🌅", "🌾"] // Justice, scrolls, sunrise, fields
        case .dobrudjanSea:
            return ["🌊", "⚓", "🐟", "🚢"] // Waves, anchor, fish, ships
        }
    }
}

/// Tournament status tracking
enum TournamentStatus: String, CaseIterable, Codable {
    case waitingForPlayers = "waiting"
    case readyToStart = "ready"
    case inProgress = "in_progress"
    case completed = "completed"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .waitingForPlayers: return "În așteptarea jucătorilor"
        case .readyToStart: return "Gata de start"
        case .inProgress: return "În desfășurare"
        case .completed: return "Finalizat"
        case .cancelled: return "Anulat"
        }
    }
}

// MARK: - Tournament Participant Models

/// Player participating in a Romanian tournament
struct TournamentParticipant: Identifiable, Codable {
    let id = UUID()
    let playerID: String
    let displayName: String
    let currentArena: RomanianArena
    let tournamentRating: Int
    let culturalLevel: Int
    let joinedAt: Date
    var isReady: Bool
    var currentSeed: Int = 0
    var matchesPlayed: Int = 0
    var matchesWon: Int = 0
    var culturalMomentsGenerated: Int = 0
}

/// Tournament entry requirements based on Romanian cultural progression
struct TournamentEntryRequirements: Codable {
    let minimumArena: RomanianArena
    let minimumCulturalLevel: Int
    let entryFee: Int // In-game currency
    let additionalRequirements: [String] = []
}

/// Player's tournament profile with Romanian cultural elements
struct TournamentPlayerProfile: Codable {
    let playerID: String
    var displayName: String
    var currentArena: RomanianArena
    var tournamentRating: Int
    var tournamentsPlayed: Int
    var tournamentsWon: Int
    var culturalKnowledgeLevel: Int
    var preferredTournamentTypes: [TournamentType]
    var seasonalAchievements: [SeasonalAchievement]
    var folkMusicPreferences: [String]
    var culturalMilestones: [String]
    
    var winRate: Float {
        guard tournamentsPlayed > 0 else { return 0.0 }
        return Float(tournamentsWon) / Float(tournamentsPlayed)
    }
    
    var culturalLevel: String {
        switch culturalKnowledgeLevel {
        case 1...2: return "Începător în Tradițiile Românești"
        case 3...4: return "Student al Culturii Populare"
        case 5...6: return "Cunoscător al Folclorului"
        case 7...8: return "Păstrător al Tradițiilor"
        case 9...10: return "Maestru al Moștenirii Culturale"
        default: return "Explorător Cultural"
        }
    }
}

// MARK: - Tournament Bracket System

/// Tournament bracket with Romanian cultural seeding
struct TournamentBracket: Codable {
    let participants: [TournamentParticipant]
    var matches: [TournamentMatch] = []
    var rounds: [TournamentRound] = []
    var currentRound: Int = 1
    var culturalSeed: Double
    var isComplete: Bool = false
    var finalStandings: [TournamentStanding] = []
    
    init(participants: [TournamentParticipant], culturalSeed: Double) {
        self.participants = participants
        self.culturalSeed = culturalSeed
        generateBracket()
    }
    
    mutating private func generateBracket() {
        // Seed participants based on tournament rating and cultural level
        let seededParticipants = participants.sorted { participant1, participant2 in
            let rating1 = participant1.tournamentRating + (participant1.culturalLevel * 10)
            let rating2 = participant2.tournamentRating + (participant2.culturalLevel * 10)
            return rating1 > rating2
        }
        
        // Create initial round matches
        var initialMatches: [TournamentMatch] = []
        for i in stride(from: 0, to: seededParticipants.count, by: 2) {
            if i + 1 < seededParticipants.count {
                let match = TournamentMatch(
                    id: "round1_match\(i/2 + 1)",
                    roundNumber: 1,
                    player1ID: seededParticipants[i].playerID,
                    player2ID: seededParticipants[i + 1].playerID,
                    culturalThemeBonus: calculateCulturalBonus(seededParticipants[i], seededParticipants[i + 1])
                )
                initialMatches.append(match)
            }
        }
        
        matches = initialMatches
        rounds = [TournamentRound(roundNumber: 1, matches: initialMatches)]
    }
    
    mutating func updateWithMatchResult(_ result: TournamentMatchResult) throws {
        guard let matchIndex = matches.firstIndex(where: { $0.id == result.matchID }) else {
            throw TournamentError.matchNotFound
        }
        
        matches[matchIndex].result = result
        matches[matchIndex].status = .completed
        
        // Check if round is complete
        let currentRoundMatches = matches.filter { $0.roundNumber == currentRound }
        let completedMatches = currentRoundMatches.filter { $0.status == .completed }
        
        if completedMatches.count == currentRoundMatches.count {
            // Round complete - advance to next round or complete tournament
            if currentRoundMatches.count == 1 {
                // Tournament complete
                isComplete = true
                generateFinalStandings()
            } else {
                // Advance to next round
                advanceToNextRound()
            }
        }
    }
    
    private mutating func advanceToNextRound() {
        let currentRoundMatches = matches.filter { $0.roundNumber == currentRound }
        let winners = currentRoundMatches.compactMap { $0.result?.winnerID }
        
        var nextRoundMatches: [TournamentMatch] = []
        for i in stride(from: 0, to: winners.count, by: 2) {
            if i + 1 < winners.count {
                let match = TournamentMatch(
                    id: "round\(currentRound + 1)_match\(i/2 + 1)",
                    roundNumber: currentRound + 1,
                    player1ID: winners[i],
                    player2ID: winners[i + 1],
                    culturalThemeBonus: 0.1 // Progressive cultural bonus
                )
                nextRoundMatches.append(match)
            }
        }
        
        matches.append(contentsOf: nextRoundMatches)
        currentRound += 1
        rounds.append(TournamentRound(roundNumber: currentRound, matches: nextRoundMatches))
    }
    
    private mutating func generateFinalStandings() {
        // Generate final standings based on tournament progression
        finalStandings = participants.enumerated().map { index, participant in
            TournamentStanding(
                position: index + 1,
                participant: participant,
                finalRating: participant.tournamentRating,
                culturalMomentsGenerated: participant.culturalMomentsGenerated,
                prizesWon: []
            )
        }.sorted { $0.finalRating > $1.finalRating }
    }
    
    private func calculateCulturalBonus(_ player1: TournamentParticipant, _ player2: TournamentParticipant) -> Float {
        let culturalDifference = abs(player1.culturalLevel - player2.culturalLevel)
        return Float(culturalDifference) * 0.05 // Small bonus for cultural diversity
    }
}

/// Individual tournament match
struct TournamentMatch: Identifiable, Codable {
    let id: String
    let roundNumber: Int
    let player1ID: String
    let player2ID: String
    let culturalThemeBonus: Float
    var status: TournamentMatchStatus = .pending
    var result: TournamentMatchResult?
    var scheduledTime: Date?
    var startedAt: Date?
    var completedAt: Date?
}

/// Tournament match status
enum TournamentMatchStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case inProgress = "in_progress"
    case completed = "completed"
    case forfeited = "forfeited"
}

/// Result of a tournament match with Romanian cultural elements
struct TournamentMatchResult: Codable {
    let matchID: String
    let winnerID: String
    let loserID: String
    let winnerScore: Int
    let loserScore: Int
    let matchDuration: TimeInterval
    let culturalMomentsGenerated: Int
    let educationalEngagementScore: Float
    let folkloreReferencesTriggered: [String]
    let completedAt: Date = Date()
}

/// Tournament round organization
struct TournamentRound: Codable {
    let roundNumber: Int
    let matches: [TournamentMatch]
    var startTime: Date?
    var endTime: Date?
    var culturalTheme: String?
}

/// Final tournament standings
struct TournamentStanding: Codable {
    let position: Int
    let participant: TournamentParticipant
    let finalRating: Int
    let culturalMomentsGenerated: Int
    let prizesWon: [CulturalReward]
}

// MARK: - Cultural Tournament Features

/// Romanian cultural rewards for tournament achievements
struct CulturalReward: Identifiable, Codable {
    let id: String
    let type: CulturalRewardType
    let title: String
    let romanianTitle: String
    let description: String
    let culturalSignificance: String
    let rarity: RewardRarity
    let visualEffects: [String]
    let educationalContent: String?
}

enum CulturalRewardType: String, CaseIterable, Codable {
    case cardBack = "card_back"
    case folkMusic = "folk_music"
    case culturalStory = "cultural_story"
    case traditionalPattern = "traditional_pattern"
    case historicalAchievement = "historical_achievement"
    case colorTheme = "color_theme"
    case specialEffect = "special_effect"
    case culturalBadge = "cultural_badge"
}

enum RewardRarity: String, CaseIterable, Codable {
    case common = "common"
    case rare = "rare"
    case epic = "epic"
    case legendary = "legendary"
    case mythical = "mythical" // Reserved for grand cultural achievements
}

/// Folk music tracks for tournament atmosphere
struct FolkMusicTrack: Identifiable, Codable {
    let id: String
    let title: String
    let region: String
    let culturalContext: String
    let duration: TimeInterval = 180 // 3 minutes default
    let tempo: MusicTempo = .moderate
    let mood: MusicMood = .celebratory
}

enum MusicTempo: String, CaseIterable, Codable {
    case slow = "slow"
    case moderate = "moderate"
    case fast = "fast"
    case variable = "variable"
}

enum MusicMood: String, CaseIterable, Codable {
    case celebratory = "celebratory"
    case contemplative = "contemplative"
    case energetic = "energetic"
    case traditional = "traditional"
    case ceremonial = "ceremonial"
}

/// Educational content items for cultural learning
struct EducationalContentItem: Identifiable, Codable {
    let id: String
    let title: String
    let content: String
    let culturalSignificance: String
    let interactiveElements: [String]
    let estimatedReadingTime: TimeInterval = 120 // 2 minutes
    let ageAppropriate: Bool = true
    let requiresParentalGuidance: Bool = false
}

// MARK: - Seasonal and Special Tournaments

/// Completed tournament record for history
struct CompletedTournament: Identifiable, Codable {
    let id = UUID()
    let originalTournament: RomanianTournament
    let finalStandings: [TournamentStanding]
    let culturalMomentsGenerated: Int
    let educationalContentEngagement: Float
    let completedAt: Date
    var totalParticipants: Int { originalTournament.participants.count }
    var duration: TimeInterval { completedAt.timeIntervalSince(originalTournament.actualStartTime ?? originalTournament.startTime) }
}

/// Special seasonal achievements
struct SeasonalAchievement: Identifiable, Codable {
    let id: String
    let season: RomanianSeason
    let title: String
    let description: String
    let unlockedAt: Date
    let culturalValue: Int
}

enum RomanianSeason: String, CaseIterable, Codable {
    case spring = "spring" // Mărțișor season
    case summer = "summer" // Folk festival season
    case autumn = "autumn" // Harvest season
    case winter = "winter" // Winter holidays season
    
    var romanianName: String {
        switch self {
        case .spring: return "Primăvara"
        case .summer: return "Vara"
        case .autumn: return "Toamna"
        case .winter: return "Iarna"
        }
    }
}

/// Romanian celebration tournaments
struct CelebrationTournament: Identifiable, Codable {
    let id: String
    let celebrationType: TournamentCelebration
    let title: String
    let description: String
    let culturalEducation: String
    let specialRewards: [String]
    let startDate: Date
    let endDate: Date
    var isActive: Bool
}

enum TournamentCelebration: String, CaseIterable, Codable {
    case martisor = "martisor"
    case nationalDay = "national_day"
    case folkFestival = "folk_festival"
    case harvest = "harvest"
    case winterSolstice = "winter_solstice"
    
    var romanianName: String {
        switch self {
        case .martisor: return "Mărțișor"
        case .nationalDay: return "Ziua României"
        case .folkFestival: return "Festival Popular"
        case .harvest: return "Sărbătoarea Recoltei"
        case .winterSolstice: return "Solstițiul de Iarnă"
        }
    }
}

// MARK: - Arena Championship System

/// Arena-specific championship tournaments
struct ArenaChampionship: Identifiable, Codable {
    let id: String
    let arena: RomanianArena
    let title: String
    let description: String
    let minParticipants: Int
    let maxParticipants: Int
    let entryFee: Int
    let prizePool: Int
    let culturalPrizes: [CulturalReward]
    let registrationStart: Date
    let registrationEnd: Date
    let championshipStart: Date
    var status: ChampionshipStatus = .registration
    var participants: [TournamentParticipant] = []
    var champion: TournamentParticipant?
}

enum ChampionshipStatus: String, CaseIterable, Codable {
    case registration = "registration"
    case ready = "ready"
    case inProgress = "in_progress"
    case completed = "completed"
}

// MARK: - Additional Tournament Features

/// Cultural seasonal progress tracking
struct CulturalSeasonProgress: Codable {
    var currentSeason: RomanianSeason = .spring
    var seasonStartDate: Date = Date()
    var culturalEventsParticipated: [String] = []
    var folkloreStoriesUnlocked: [String] = []
    var traditionalMusicCollected: [String] = []
    var heritageAchievementsEarned: [String] = []
    var seasonalRating: Int = 1000
    
    var progressPercentage: Float {
        let totalPossibleEvents = 20 // Example: 20 possible cultural events per season
        return Float(culturalEventsParticipated.count) / Float(totalPossibleEvents)
    }
}

/// Folk festival events for community engagement
struct FolkFestivalEvent: Identifiable, Codable {
    let id: String
    let festivalName: String
    let region: String
    let description: String
    let culturalActivities: [String]
    let musicPerformances: [FolkMusicTrack]
    let educationalWorkshops: [EducationalContentItem]
    let startDate: Date
    let endDate: Date
    var participantCount: Int = 0
}

/// Cultural events for special tournaments
struct CulturalEvent: Identifiable, Codable {
    let id: String
    let eventType: CulturalEventType
    let title: String
    let description: String
    let educationalValue: String
    let startDate: Date
    let endDate: Date
    let specialTournaments: [String] // Tournament IDs
    let culturalRewards: [CulturalReward]
}

enum CulturalEventType: String, CaseIterable, Codable {
    case folklore = "folklore"
    case music = "music"
    case history = "history"
    case traditions = "traditions"
    case crafts = "crafts"
    case literature = "literature"
}

/// Tournament sync status for CloudKit integration
enum TournamentSyncStatus: String, CaseIterable, Codable {
    case idle = "idle"
    case syncing = "syncing"
    case error = "error"
    
    var displayName: String {
        switch self {
        case .idle: return "Sincronizat"
        case .syncing: return "Se sincronizează..."
        case .error: return "Eroare de sincronizare"
        }
    }
}

/// Leaderboard entry for tournament rankings
struct LeaderboardEntry: Identifiable, Codable {
    let id: String
    let playerID: String
    let displayName: String
    let currentArena: RomanianArena
    let tournamentRating: Int
    let tournamentsWon: Int
    let culturalLevel: Int
    let currentRank: Int
    let seasonalTrophies: Int
}

// MARK: - Tournament Error Types

enum TournamentError: LocalizedError, Sendable {
    case playerProfileNotFound
    case tournamentFull
    case arenaRequirementNotMet
    case culturalLevelRequirementNotMet
    case insufficientParticipants
    case noActiveTournament
    case noBracketFound
    case matchNotFound
    case invalidTournamentType
    case syncFailed
    
    var errorDescription: String? {
        switch self {
        case .playerProfileNotFound:
            return "Profilul jucătorului nu a fost găsit."
        case .tournamentFull:
            return "Turneul este complet."
        case .arenaRequirementNotMet:
            return "Nu îndeplinești cerințele de arenă pentru acest turneu."
        case .culturalLevelRequirementNotMet:
            return "Nivelul tău cultural nu este suficient pentru acest turneu."
        case .insufficientParticipants:
            return "Nu sunt suficienți participanți pentru a începe turneul."
        case .noActiveTournament:
            return "Nu există un turneu activ."
        case .noBracketFound:
            return "Nu s-a găsit sistemul de eliminare pentru turneu."
        case .matchNotFound:
            return "Meciul nu a fost găsit."
        case .invalidTournamentType:
            return "Tipul de turneu nu este valid."
        case .syncFailed:
            return "Sincronizarea turneului a eșuat."
        }
    }
}

// MARK: - Extensions for Romanian Arena Championships

extension RomanianArena {
    var championshipMinParticipants: Int {
        switch self {
        case .sateImarica, .satuMihai: return 4
        case .orasulBrara, .orasulBacau: return 8
        case .orasulCluj, .orasulConstanta, .orasulIasi: return 12
        case .orasulTimisoara, .orasulBrasov, .orasulSibiu: return 16
        case .marealeBucuresti: return 32
        }
    }
    
    var championshipMaxParticipants: Int {
        return championshipMinParticipants * 2
    }
    
    var championshipEntryFee: Int {
        return requiredTrophies / 10
    }
    
    var championshipPrizePool: Int {
        return championshipEntryFee * championshipMaxParticipants
    }
    
    var championshipRegistrationPeriod: TimeInterval {
        switch self {
        case .sateImarica, .satuMihai: return 3600 // 1 hour
        case .orasulBrara, .orasulBacau: return 7200 // 2 hours
        case .orasulCluj, .orasulConstanta, .orasulIasi: return 14400 // 4 hours
        case .orasulTimisoara, .orasulBrasov, .orasulSibiu: return 28800 // 8 hours
        case .marealeBucuresti: return 86400 // 24 hours
        }
    }
    
    var championshipCulturalPrizes: [CulturalReward] {
        // Implementation would return arena-specific cultural rewards
        return []
    }
}