import Foundation

struct CloudKitPlayerProfile: Codable, Identifiable {
    var id: UUID
    var playerID: String
    var displayName: String
    var currentArena: RomanianArena
    var trophies: Int
    var totalGamesPlayed: Int
    var heritageEngagementLevel: Float
    var tournamentRating: Int
    var culturalKnowledgeLevel: Int
    var tournamentsPlayed: Int
    var tournamentsWon: Int
    var folkMusicListened: [String]
    var achievements: [CulturalAchievement]


    init(
        id: UUID = UUID(),
        playerID: String = UUID().uuidString,
        displayName: String,
        currentArena: RomanianArena = .sateImarica,
        trophies: Int = 0,
        totalGamesPlayed: Int = 0,
        heritageEngagementLevel: Float = 0.0,
        tournamentRating: Int = 1000,
        culturalKnowledgeLevel: Int = 1,
        tournamentsPlayed: Int = 0,
        tournamentsWon: Int = 0,
        folkMusicListened: [String] = [],
        achievements: [CulturalAchievement] = []
    ) {
        self.id = id
        self.playerID = playerID
        self.displayName = displayName
        self.currentArena = currentArena
        self.trophies = trophies
        self.totalGamesPlayed = totalGamesPlayed
        self.heritageEngagementLevel = heritageEngagementLevel
        self.tournamentRating = tournamentRating
        self.culturalKnowledgeLevel = culturalKnowledgeLevel
        self.tournamentsPlayed = tournamentsPlayed
        self.tournamentsWon = tournamentsWon
        self.folkMusicListened = folkMusicListened
        self.achievements = achievements
    }
}

struct GameScore: Codable, Equatable {
    var playerScore: Int
    var opponentScore: Int
    var tricksWon: Int
    var tricksLost: Int
}

struct CardPlayRecord: Codable, Identifiable, Equatable {
    let id = UUID()
    var cardKey: String
    var playOrder: Int
    var wasSuccessful: Bool
    var trickWon: Bool
    var pointsEarned: Int
    var contextNotes: String?
}

struct CloudKitGameRecord: Codable, Identifiable {
    var id: UUID
    var gameID: String
    var playerID: String
    var opponentType: String
    var aiDifficulty: String
    var gameResult: String
    var finalScore: GameScore
    var gameDuration: TimeInterval
    var cardsPlayed: [CardPlayRecord]
    var culturalMomentsTriggered: [String]
    var timestamp: Date
    var arenaAtTimeOfPlay: RomanianArena
    var sevenWildCardUses: Int
    var eightSpecialUses: Int
    var tricksWon: Int
    var pointsScored: Int
    var mistakesMade: [String]
    var strategicMoves: [String]

    init(
        id: UUID = UUID(),
        gameID: String,
        playerID: String,
        opponentType: String = "AI",
        aiDifficulty: String = "medium",
        gameResult: String = "in_progress",
        finalScore: GameScore = GameScore(playerScore: 0, opponentScore: 0, tricksWon: 0, tricksLost: 0),
        gameDuration: TimeInterval = 0,
        cardsPlayed: [CardPlayRecord] = [],
        culturalMomentsTriggered: [String] = [],
        timestamp: Date = Date(),
        arenaAtTimeOfPlay: RomanianArena = .sateImarica,
        sevenWildCardUses: Int = 0,
        eightSpecialUses: Int = 0,
        tricksWon: Int = 0,
        pointsScored: Int = 0,
        mistakesMade: [String] = [],
        strategicMoves: [String] = []
    ) {
        self.id = id
        self.gameID = gameID
        self.playerID = playerID
        self.opponentType = opponentType
        self.aiDifficulty = aiDifficulty
        self.gameResult = gameResult
        self.finalScore = finalScore
        self.gameDuration = gameDuration
        self.cardsPlayed = cardsPlayed
        self.culturalMomentsTriggered = culturalMomentsTriggered
        self.timestamp = timestamp
        self.arenaAtTimeOfPlay = arenaAtTimeOfPlay
        self.sevenWildCardUses = sevenWildCardUses
        self.eightSpecialUses = eightSpecialUses
        self.tricksWon = tricksWon
        self.pointsScored = pointsScored
        self.mistakesMade = mistakesMade
        self.strategicMoves = strategicMoves
    }
}
