//
//  GameController.swift
//  Septica
//
//  Main game controller for coordinating game flow and business logic
//  Manages game sessions, player coordination, and game lifecycle
//

import Foundation
import Combine

/// Main controller coordinating game flow and player interactions
class GameController: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentGameSession: GameSession?
    @Published var isGameActive = false
    @Published var gameHistory: [CompletedGameRecord] = []
    
    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()
    private let gameAnalytics = GameAnalytics()
    private let achievementService = AchievementTrackingService.shared
    
    // MARK: - Game Session Management
    
    /// Create a new single-player game session
    func startSinglePlayerGame(playerName: String, difficulty: AIDifficulty = .medium, targetScore: Int = 11) -> GameSession {
        let humanPlayer = Player(name: playerName)
        let aiPlayer = AIPlayer(name: "Computer", difficulty: difficulty)
        
        let gameState = GameState()
        gameState.players = [humanPlayer, aiPlayer]
        gameState.targetScore = targetScore
        gameState.setupNewGame()
        
        let session = GameSession(
            id: UUID(),
            gameState: gameState,
            gameType: .singlePlayer(difficulty: difficulty),
            startTime: Date()
        )
        
        currentGameSession = session
        isGameActive = true
        
        // Set up session monitoring
        setupSessionMonitoring(for: session)
        
        // Record game start
        gameAnalytics.recordGameStart(session: session)
        
        return session
    }
    
    /// Create a new two-player local game session
    func startTwoPlayerGame(player1Name: String, player2Name: String) -> GameSession {
        let player1 = Player(name: player1Name)
        let player2 = Player(name: player2Name)
        
        let gameState = GameState()
        gameState.players = [player1, player2]
        gameState.setupNewGame()
        
        let session = GameSession(
            id: UUID(),
            gameState: gameState,
            gameType: .localMultiplayer,
            startTime: Date()
        )
        
        currentGameSession = session
        isGameActive = true
        
        setupSessionMonitoring(for: session)
        gameAnalytics.recordGameStart(session: session)
        
        return session
    }
    
    /// End the current game session
    func endCurrentGame() {
        guard let session = currentGameSession else { return }
        
        session.endTime = Date()
        isGameActive = false
        
        // Record completed game
        let record = CompletedGameRecord(
            id: session.id,
            gameType: session.gameType,
            startTime: session.startTime,
            endTime: session.endTime!,
            finalResult: session.gameState.gameResult,
            playerStats: session.gameState.players.map { player in
                CompletedPlayerStats(
                    playerId: player.id,
                    name: player.name,
                    finalScore: player.score,
                    isHuman: player.isHuman,
                    statistics: player.statistics
                )
            }
        )
        
        gameHistory.append(record)
        gameAnalytics.recordGameEnd(record: record)
        
        currentGameSession = nil
    }
    
    /// Pause the current game session
    func pauseCurrentGame() {
        currentGameSession?.isPaused = true
        currentGameSession?.gameState.phase = .paused
    }
    
    /// Resume the current game session
    func resumeCurrentGame() {
        currentGameSession?.isPaused = false
        currentGameSession?.gameState.phase = .playing
    }
    
    /// Force forfeit the current game
    func forfeitCurrentGame(by playerId: UUID) {
        guard let session = currentGameSession else { return }
        
        // Set the other player as winner
        let otherPlayer = session.gameState.players.first { $0.id != playerId }
        session.gameState.phase = .finished
        
        if let winner = otherPlayer {
            let result = GameResult(
                winnerId: winner.id,
                finalScores: Dictionary(uniqueKeysWithValues: session.gameState.players.map { ($0.id, $0.score) }),
                totalTricks: session.gameState.trickHistory.count,
                gameDuration: Date().timeIntervalSince(session.startTime)
            )
            session.gameState.gameResult = result
        }
        
        endCurrentGame()
    }
    
    // MARK: - Session Monitoring
    
    /// Set up monitoring for a game session
    private func setupSessionMonitoring(for session: GameSession) {
        // Monitor game state changes
        session.gameState.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.handleGameStateChange(session: session)
            }
            .store(in: &cancellables)
    }
    
    /// Handle changes in game state
    private func handleGameStateChange(session: GameSession) {
        // Check if game ended
        if session.gameState.phase == .finished && session.endTime == nil {
            endCurrentGame()
        }
        
        // Record significant game events
        if let lastMove = session.gameState.lastMove {
            gameAnalytics.recordMove(move: lastMove, in: session)
        }
        
        // Check for achievements or milestones
        checkForAchievements(in: session)
    }
    
    /// Check for player achievements during the game
    private func checkForAchievements(in session: GameSession) {
        // Check if game is finished to trigger end-game achievements
        guard session.gameState.phase == .finished,
              let result = session.gameState.gameResult else {
            return
        }

        // Get human player stats
        guard let humanPlayer = session.gameState.players.first(where: { $0.isHuman }),
              let humanStats = session.gameState.players.first(where: { $0.id == humanPlayer.id }) else {
            return
        }

        // Create completed player stats for achievement tracking
        let completedStats = CompletedPlayerStats(
            playerId: humanPlayer.id,
            name: humanPlayer.name,
            finalScore: humanPlayer.score,
            isHuman: true,
            statistics: humanPlayer.statistics
        )

        // Create completed game record
        let record = CompletedGameRecord(
            id: session.id,
            gameType: session.gameType,
            startTime: session.startTime,
            endTime: session.endTime ?? Date(),
            finalResult: result,
            playerStats: session.gameState.players.map { player in
                CompletedPlayerStats(
                    playerId: player.id,
                    name: player.name,
                    finalScore: player.score,
                    isHuman: player.isHuman,
                    statistics: player.statistics
                )
            }
        )

        // Trigger achievement checking
        achievementService.checkAchievementsAfterGame(
            gameResult: result,
            playerStats: completedStats,
            gameSession: session
        )

        // Record regional win if applicable
        if result.winnerId == humanPlayer.id {
            let arena = humanPlayer.currentArena
            achievementService.recordRegionalWin(arena: arena)
        }
    }
    
    // MARK: - Game History and Statistics
    
    /// Get player statistics across all games
    func getPlayerStatistics(for playerName: String) -> PlayerHistoryStats {
        let playerGames = gameHistory.filter { record in
            record.playerStats.contains { $0.name == playerName }
        }
        
        let wins = playerGames.filter { record in
            guard let winnerId = record.finalResult?.winnerId else { return false }
            return record.playerStats.first { $0.playerId == winnerId }?.name == playerName
        }.count
        
        let totalPoints = playerGames.compactMap { record -> Int? in
            record.playerStats.first { $0.name == playerName }?.finalScore
        }.reduce(0, +)
        
        return PlayerHistoryStats(
            playerName: playerName,
            totalGames: playerGames.count,
            wins: wins,
            losses: playerGames.count - wins,
            totalPoints: totalPoints,
            averagePointsPerGame: playerGames.count > 0 ? Double(totalPoints) / Double(playerGames.count) : 0.0,
            winRate: playerGames.count > 0 ? Double(wins) / Double(playerGames.count) * 100.0 : 0.0,
            bestGame: playerGames.max { $0.playerStats.first { $0.name == playerName }?.finalScore ?? 0 < $1.playerStats.first { $0.name == playerName }?.finalScore ?? 0 }
        )
    }
    
    /// Get overall game statistics
    func getOverallStatistics() -> OverallGameStats {
        let totalGames = gameHistory.count
        let completedGames = gameHistory.filter { $0.finalResult != nil }
        
        let averageDuration = gameHistory.isEmpty ? 0.0 : 
            gameHistory.reduce(0.0) { $0 + $1.endTime.timeIntervalSince($1.startTime) } / Double(gameHistory.count)
        
        let gamesAgainstAI = gameHistory.filter { 
            $0.playerStats.contains { !$0.isHuman }
        }.count
        
        return OverallGameStats(
            totalGames: totalGames,
            completedGames: completedGames.count,
            averageGameDuration: averageDuration,
            gamesAgainstAI: gamesAgainstAI,
            gamesAgainstHumans: totalGames - gamesAgainstAI,
            mostPlayedDifficulty: getMostPlayedAIDifficulty()
        )
    }
    
    /// Find the most frequently played AI difficulty
    private func getMostPlayedAIDifficulty() -> AIDifficulty? {
        let difficultyGames = gameHistory.compactMap { record -> AIDifficulty? in
            switch record.gameType {
            case .singlePlayer(let difficulty):
                return difficulty
            default:
                return nil
            }
        }
        
        let difficultyCount = difficultyGames.reduce(into: [:]) { counts, difficulty in
            counts[difficulty, default: 0] += 1
        }
        
        return difficultyCount.max { $0.value < $1.value }?.key
    }
    
    // MARK: - Save/Load Game State
    
    /// Save current game session to disk
    func saveCurrentGame() throws {
        guard let session = currentGameSession else {
            throw GameControllerError.noActiveGame
        }
        
        let data = try JSONEncoder().encode(session)
        let url = getSaveGameURL()
        try data.write(to: url)
    }
    
    /// Load a saved game session
    func loadSavedGame() throws -> GameSession {
        let url = getSaveGameURL()
        let data = try Data(contentsOf: url)
        let session = try JSONDecoder().decode(GameSession.self, from: data)
        
        currentGameSession = session
        isGameActive = session.gameState.phase == .playing
        
        setupSessionMonitoring(for: session)
        
        return session
    }
    
    /// Check if a saved game exists
    func hasSavedGame() -> Bool {
        return FileManager.default.fileExists(atPath: getSaveGameURL().path)
    }
    
    /// Delete saved game
    func deleteSavedGame() throws {
        let url = getSaveGameURL()
        try FileManager.default.removeItem(at: url)
    }
    
    /// Get URL for save game file
    private func getSaveGameURL() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("septica_saved_game.json")
    }
}

// MARK: - Supporting Types

/// Represents a complete game session
class GameSession: ObservableObject, Codable {
    let id: UUID
    @Published var gameState: GameState
    let gameType: GameType
    let startTime: Date
    var endTime: Date?
    @Published var isPaused = false
    
    init(id: UUID, gameState: GameState, gameType: GameType, startTime: Date) {
        self.id = id
        self.gameState = gameState
        self.gameType = gameType
        self.startTime = startTime
    }
    
    // MARK: - Codable Implementation
    
    enum CodingKeys: String, CodingKey {
        case id, gameState, gameType, startTime, endTime, isPaused
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        gameState = try container.decode(GameState.self, forKey: .gameState)
        gameType = try container.decode(GameType.self, forKey: .gameType)
        startTime = try container.decode(Date.self, forKey: .startTime)
        endTime = try container.decodeIfPresent(Date.self, forKey: .endTime)
        isPaused = try container.decode(Bool.self, forKey: .isPaused)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(gameState, forKey: .gameState)
        try container.encode(gameType, forKey: .gameType)
        try container.encode(startTime, forKey: .startTime)
        try container.encodeIfPresent(endTime, forKey: .endTime)
        try container.encode(isPaused, forKey: .isPaused)
    }
}

/// Different types of games that can be played
enum GameType: Codable {
    case singlePlayer(difficulty: AIDifficulty)
    case localMultiplayer
    case onlineMultiplayer // For future implementation
    
    var displayName: String {
        switch self {
        case .singlePlayer(let difficulty):
            return "vs Computer (\(difficulty.rawValue))"
        case .localMultiplayer:
            return "Local Multiplayer"
        case .onlineMultiplayer:
            return "Online Multiplayer"
        }
    }
    
    // MARK: - Codable Implementation
    
    enum CodingKeys: String, CodingKey {
        case type, difficulty
    }
    
    enum TypeKey: String, Codable {
        case singlePlayer, localMultiplayer, onlineMultiplayer
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(TypeKey.self, forKey: .type)
        
        switch type {
        case .singlePlayer:
            let difficulty = try container.decode(AIDifficulty.self, forKey: .difficulty)
            self = .singlePlayer(difficulty: difficulty)
        case .localMultiplayer:
            self = .localMultiplayer
        case .onlineMultiplayer:
            self = .onlineMultiplayer
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .singlePlayer(let difficulty):
            try container.encode(TypeKey.singlePlayer, forKey: .type)
            try container.encode(difficulty, forKey: .difficulty)
        case .localMultiplayer:
            try container.encode(TypeKey.localMultiplayer, forKey: .type)
        case .onlineMultiplayer:
            try container.encode(TypeKey.onlineMultiplayer, forKey: .type)
        }
    }
}

/// Record of a completed game
struct CompletedGameRecord: Codable {
    let id: UUID
    let gameType: GameType
    let startTime: Date
    let endTime: Date
    let finalResult: GameResult?
    let playerStats: [CompletedPlayerStats]
    
    var duration: TimeInterval {
        return endTime.timeIntervalSince(startTime)
    }
}

/// Player statistics for a completed game
struct CompletedPlayerStats: Codable {
    let playerId: UUID
    let name: String
    let finalScore: Int
    let isHuman: Bool
    let statistics: PlayerStatistics
}

/// Historical statistics for a player
struct PlayerHistoryStats {
    let playerName: String
    let totalGames: Int
    let wins: Int
    let losses: Int
    let totalPoints: Int
    let averagePointsPerGame: Double
    let winRate: Double
    let bestGame: CompletedGameRecord?
}

/// Overall game statistics
struct OverallGameStats {
    let totalGames: Int
    let completedGames: Int
    let averageGameDuration: TimeInterval
    let gamesAgainstAI: Int
    let gamesAgainstHumans: Int
    let mostPlayedDifficulty: AIDifficulty?
}

/// Analytics tracking for games
/// Privacy-compliant analytics with local storage only
/// Integrates with GameAnalyticsStore and CulturalEngagementTracker
class GameAnalytics {

    // MARK: - Properties

    private let analyticsStore = GameAnalyticsStore()
    private let culturalTracker = CulturalEngagementTracker()

    // Track session start time for duration calculation
    private var sessionStartTimes: [UUID: Date] = [:]

    // MARK: - Game Session Recording

    /// Record game start with full context
    /// Tracks: game mode, difficulty, arena selection
    func recordGameStart(session: GameSession) {
        // Store session start time
        sessionStartTimes[session.id] = session.startTime

        // Extract game type details
        let gameTypeString: String
        var difficulty: String?

        switch session.gameType {
        case .singlePlayer(let diff):
            gameTypeString = "Single Player"
            difficulty = diff.rawValue
        case .localMultiplayer:
            gameTypeString = "Local Multiplayer"
        case .onlineMultiplayer:
            gameTypeString = "Online Multiplayer"
        }

        // Determine game mode (2/3/4 players)
        let gameMode = "\(session.gameState.players.count) Players"

        // Extract arena from first player (all players in same arena)
        let arenaEnum = session.gameState.players.first?.currentArena
        let arena = arenaEnum?.displayName

        // Record to analytics store
        analyticsStore.recordGameStart(
            gameType: gameTypeString,
            difficulty: difficulty,
            gameMode: gameMode,
            arena: arena
        )

        // Calculate cultural engagement score based on arena selection
        if let arenaEnum = arenaEnum {
            let culturalScore = calculateCulturalEngagement(arena: arenaEnum.displayName)
            culturalTracker.recordCulturalInteraction(score: culturalScore)
        }

        print("📊 Analytics: Game started - \(session.gameType.displayName) (\(gameMode))")
    }

    /// Record game end with comprehensive results
    /// Tracks: duration, win/loss, score, points collected
    func recordGameEnd(record: CompletedGameRecord) {
        // Calculate game duration
        let duration = record.duration

        // Determine if human player won
        let humanPlayer = record.playerStats.first { $0.isHuman }
        let didWin = humanPlayer?.playerId == record.finalResult?.winnerId

        // Get human player statistics
        let finalScore = humanPlayer?.finalScore ?? 0
        let pointsCollected = humanPlayer?.statistics.totalPointsScored ?? 0
        let tricksWon = humanPlayer?.statistics.tricksWon ?? 0

        // Record to analytics store
        analyticsStore.recordGameEnd(
            duration: duration,
            didWin: didWin,
            finalScore: finalScore,
            pointsCollected: pointsCollected,
            tricksWon: tricksWon
        )

        // Calculate cultural engagement based on game completion
        let culturalScore = calculateGameCompletionCulturalScore(
            duration: duration,
            didWin: didWin,
            pointsCollected: pointsCollected
        )
        culturalTracker.recordCulturalInteraction(score: culturalScore)

        // Clean up session tracking
        sessionStartTimes.removeValue(forKey: record.id)

        let winStatus = didWin ? "Won" : "Lost"
        print("📊 Analytics: Game ended - \(winStatus) in \(Int(duration))s, \(pointsCollected) points")
    }

    /// Record individual move analytics
    /// Tracks: card values played, sevens usage, point card collection
    func recordMove(move: GameMove, in session: GameSession) {
        // Extract card information
        let cardValue = move.card.value
        let isPointCard = move.card.isPointCard
        let isSeven = cardValue == 7

        // Record card play
        analyticsStore.recordCardPlayed(
            cardValue: cardValue,
            isPointCard: isPointCard,
            isSeven: isSeven
        )

        // Calculate cultural engagement for strategic plays
        if isSeven || isPointCard {
            let culturalScore = calculateStrategicPlayCulturalScore(
                cardValue: cardValue,
                isPointCard: isPointCard,
                isSeven: isSeven
            )
            culturalTracker.recordCulturalInteraction(score: culturalScore)
        }
    }

    /// Record objection decision (called separately from move recording)
    /// - Parameter didObject: true if player objected, false if passed
    func recordObjectionDecision(didObject: Bool) {
        analyticsStore.recordObjection(didObject: didObject)
        print("📊 Analytics: Objection \(didObject ? "USED" : "PASSED")")
    }

    // MARK: - Cultural Engagement Calculations

    /// Calculate cultural engagement score based on arena selection
    /// Romanian arenas = higher cultural engagement
    private func calculateCulturalEngagement(arena: String) -> Float {
        // Romanian arenas show cultural engagement
        let romanianArenas = ["sateImarica", "satuMihai", "village", "carpathian"]

        let lowerArena = arena.lowercased()
        for romanianArena in romanianArenas {
            if lowerArena.contains(romanianArena) {
                return 0.8 // High cultural engagement
            }
        }

        return 0.4 // Moderate engagement for other arenas
    }

    /// Calculate cultural score based on game completion quality
    private func calculateGameCompletionCulturalScore(
        duration: TimeInterval,
        didWin: Bool,
        pointsCollected: Int
    ) -> Float {
        var score: Float = 0.5 // Base score

        // Longer games show deeper engagement
        if duration > 180 { // 3+ minutes
            score += 0.2
        }

        // Collecting points shows understanding of game
        if pointsCollected >= 5 {
            score += 0.2
        }

        // Winning shows mastery
        if didWin {
            score += 0.1
        }

        return min(1.0, score)
    }

    /// Calculate cultural score for strategic plays
    private func calculateStrategicPlayCulturalScore(
        cardValue: Int,
        isPointCard: Bool,
        isSeven: Bool
    ) -> Float {
        var score: Float = 0.3 // Base score for any play

        // Strategic use of sevens (Romanian tradition)
        if isSeven {
            score += 0.4
        }

        // Point card collection (game understanding)
        if isPointCard {
            score += 0.3
        }

        return min(1.0, score)
    }

    // MARK: - Public Analytics Access

    /// Get analytics summary for display
    func getAnalyticsSummary() -> AnalyticsSummary {
        return analyticsStore.getAnalyticsSummary()
    }

    /// Get cultural engagement history
    func getCulturalEngagementHistory() -> [CulturalEngagementTracker.EngagementSnapshot] {
        return culturalTracker.history
    }

    /// Allow user to opt out of analytics (COPPA compliance)
    func setAnalyticsOptOut(_ optOut: Bool) {
        analyticsStore.isOptedOut = optOut
        print("📊 Analytics: User \(optOut ? "opted out" : "opted in")")
    }

    /// Check if user has opted out
    var isOptedOut: Bool {
        return analyticsStore.isOptedOut
    }

    /// Reset all analytics data (privacy compliance)
    func resetAllAnalytics() {
        analyticsStore.resetAllData()
        print("📊 Analytics: All data reset")
    }

    /// Record tutorial completion
    func recordTutorialCompletion() {
        analyticsStore.recordTutorialCompletion()
        culturalTracker.recordCulturalInteraction(score: 0.9) // High engagement
        print("📊 Analytics: Tutorial completed")
    }
}

/// Errors that can occur in the game controller
enum GameControllerError: Error, LocalizedError {
    case noActiveGame
    case saveGameFailed
    case loadGameFailed
    case invalidGameData
    
    var errorDescription: String? {
        switch self {
        case .noActiveGame:
            return "No active game to save"
        case .saveGameFailed:
            return "Failed to save game"
        case .loadGameFailed:
            return "Failed to load saved game"
        case .invalidGameData:
            return "Invalid game data"
        }
    }
}