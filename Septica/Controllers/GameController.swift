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
        // TODO: Implement achievement system
        // Examples:
        // - First win
        // - Perfect game (all point cards)
        // - Quick victory
        // - Comeback victory
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
class GameAnalytics {
    func recordGameStart(session: GameSession) {
        // TODO: Implement analytics recording
        print("Game started: \(session.gameType.displayName)")
    }
    
    func recordGameEnd(record: CompletedGameRecord) {
        // TODO: Implement analytics recording
        print("Game ended after \(Int(record.duration)) seconds")
    }
    
    func recordMove(move: GameMove, in session: GameSession) {
        // TODO: Implement move analytics
        // Track card play patterns, timing, etc.
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