//
//  GameState.swift
//  Septica
//
//  Core game state management for Septica
//  Implements finite state machine for game flow and state transitions
//

import Foundation
import Combine

/// Represents the complete state of a Septica game
class GameState: ObservableObject, Codable {
    
    // MARK: - Game Identification
    let id = UUID()
    @Published var createdAt = Date()
    @Published var updatedAt = Date()
    
    // MARK: - Game Phase
    @Published var phase: GamePhase = .setup
    @Published var roundNumber: Int = 1
    @Published var trickNumber: Int = 1
    
    // MARK: - Game Configuration
    @Published var targetScore: Int = 11  // Romanian Septica traditional target
    
    // MARK: - Players
    @Published var players: [Player] = []
    @Published var currentPlayerIndex: Int = 0
    @Published var dealerIndex: Int = 0
    
    // MARK: - Cards and Deck
    @Published var deck = Deck()
    @Published var tableCards: [Card] = []
    @Published var trickHistory: [CompletedTrick] = []
    
    // MARK: - Game Flow
    @Published var lastMove: GameMove?
    @Published var gameResult: GameResult?
    @Published var isWaitingForPlayerInput: Bool = false
    
    /// Current player whose turn it is
    var currentPlayer: Player? {
        guard currentPlayerIndex < players.count else { return nil }
        return players[currentPlayerIndex]
    }
    
    /// Top card on the table (last played)
    var topTableCard: Card? {
        return tableCards.last
    }
    
    /// Whether the current trick is complete
    var isTrickComplete: Bool {
        return GameRules.isTrickComplete(
            tableCards: tableCards,
            allPlayerHands: players.map { $0.hand },
            currentPlayerIndex: currentPlayerIndex
        )
    }
    
    /// Whether the game is complete
    var isGameComplete: Bool {
        // Check if any player has reached the target score
        let hasWinner = players.contains { $0.score >= targetScore }
        
        // Also check if all cards have been played (traditional end condition)
        let allCardsPlayed = GameRules.isGameComplete(
            allPlayerHands: players.map { $0.hand },
            deckEmpty: deck.isEmpty
        )
        
        return hasWinner || allCardsPlayed
    }
    
    // MARK: - Initialization
    
    init() {
        setupNewGame()
    }
    
    init(players: [Player]) {
        self.players = players
        setupNewGame()
    }
    
    /// Set up a new game with fresh deck and dealt cards
    func setupNewGame() {
        phase = .setup
        roundNumber = 1
        trickNumber = 1
        currentPlayerIndex = dealerIndex
        
        // Reset all players
        players.forEach { $0.resetForNewGame() }
        
        // Create and shuffle deck
        deck = Deck()
        deck.shuffle()
        
        // Deal initial hands
        dealInitialHands()
        
        // Clear game state
        tableCards.removeAll()
        trickHistory.removeAll()
        lastMove = nil
        gameResult = nil
        
        // Start the game
        phase = .playing
        updateTimestamp()
    }
    
    /// Deal initial hands to all players
    private func dealInitialHands() {
        let hands = GameRules.dealInitialHands(from: &deck, playerCount: players.count)
        for (index, hand) in hands.enumerated() {
            players[index].hand = hand
        }
    }
    
    // MARK: - Game Actions
    
    /// Attempt to play a card
    /// - Parameters:
    ///   - card: Card to play
    ///   - playerId: ID of the player playing the card
    /// - Returns: Result of the play attempt
    @discardableResult
    func playCard(_ card: Card, by playerId: UUID) -> PlayResult {
        guard let playerIndex = players.firstIndex(where: { $0.id == playerId }) else {
            return .failure(.playerNotFound)
        }
        
        let player = players[playerIndex]
        
        // Validate it's the player's turn
        guard playerIndex == currentPlayerIndex else {
            return .failure(.notPlayerTurn)
        }
        
        // Validate the move
        let validationResult = GameRules.validateMove(
            card: card,
            from: player.hand,
            against: topTableCard,
            tableCardsCount: tableCards.count
        )
        
        switch validationResult {
        case .valid:
            break
        case .invalid(let error):
            return .failure(.invalidMove(error))
        }
        
        // Execute the move
        player.removeCard(card)
        tableCards.append(card)
        
        // Record the move
        lastMove = GameMove(
            playerId: playerId,
            card: card,
            timestamp: Date(),
            tableCardsCount: tableCards.count
        )
        
        // Notify players of the event
        let event = GameEvent.cardPlayed(playerId: playerId, card: card)
        players.forEach { $0.handleGameEvent(event) }
        
        // Check if trick is complete
        if isTrickComplete {
            completeTrick()
        } else {
            // Move to next player
            advanceToNextPlayer()
        }
        
        // Check if game is complete
        if isGameComplete {
            endGame()
        }
        
        updateTimestamp()
        return .success
    }
    
    /// Complete the current trick and award points
    private func completeTrick() {
        guard !tableCards.isEmpty else { return }
        
        // Determine trick winner
        let winnerIndex = GameRules.determineTrickWinner(tableCards: tableCards)
        let trickWinnerPlayerIndex = (dealerIndex + winnerIndex) % players.count
        let winner = players[trickWinnerPlayerIndex]
        
        // Calculate points
        let points = GameRules.calculatePoints(from: tableCards)
        winner.addPoints(points)
        
        // Record completed trick
        let completedTrick = CompletedTrick(
            trickNumber: trickNumber,
            cards: tableCards,
            winnerPlayerId: winner.id,
            points: points
        )
        trickHistory.append(completedTrick)
        
        // Notify players
        let event = GameEvent.trickWon(playerId: winner.id, points: points)
        players.forEach { $0.handleGameEvent(event) }
        
        // Clear table and prepare for next trick
        tableCards.removeAll()
        currentPlayerIndex = trickWinnerPlayerIndex // Winner starts next trick
        trickNumber += 1
        
        // Deal new cards if deck has cards and players need them
        dealNewCardsIfNeeded()
    }
    
    /// Deal new cards to players if needed and available
    private func dealNewCardsIfNeeded() {
        let minHandSize = Swift.min(GameRules.initialHandSize, deck.count / players.count)
        
        for player in players {
            while player.hand.count < minHandSize && !deck.isEmpty {
                if let card = deck.drawCard() {
                    player.addCard(card)
                }
            }
        }
    }
    
    /// Advance to the next player's turn
    private func advanceToNextPlayer() {
        currentPlayerIndex = (currentPlayerIndex + 1) % players.count
    }
    
    /// End the current game
    private func endGame() {
        phase = .finished
        
        // Determine winner
        let scores = players.map { $0.score }
        let winnerIndex = GameRules.determineGameWinner(playerScores: scores)
        
        let result = GameResult(
            winnerId: winnerIndex != nil ? players[winnerIndex!].id : nil,
            finalScores: Dictionary(
                uniqueKeysWithValues: players.map { ($0.id, $0.score) }
            ),
            totalTricks: trickHistory.count,
            gameDuration: Date().timeIntervalSince(createdAt)
        )
        
        gameResult = result
        
        // Notify players
        let event = GameEvent.gameEnded(winnerId: result.winnerId, finalScores: result.finalScores)
        players.forEach { $0.handleGameEvent(event) }
        
        updateTimestamp()
    }
    
    /// Get valid moves for the current player
    func validMovesForCurrentPlayer() -> [Card] {
        guard let currentPlayer = currentPlayer else { return [] }
        
        return GameRules.validMoves(
            from: currentPlayer.hand,
            against: topTableCard,
            tableCardsCount: tableCards.count
        )
    }
    
    /// Check if current player can make any valid moves
    func currentPlayerCanMove() -> Bool {
        return !validMovesForCurrentPlayer().isEmpty
    }
    
    /// Force skip current player's turn (if they cannot move)
    func skipCurrentPlayer() {
        guard !currentPlayerCanMove() else { return }
        advanceToNextPlayer()
    }
    
    // MARK: - Utility Methods
    
    private func updateTimestamp() {
        updatedAt = Date()
    }
    
    /// Get game statistics for analysis
    func getGameStatistics() -> GameStatistics {
        return GameStatistics(
            totalTricks: trickHistory.count,
            totalCardsPlayed: trickHistory.reduce(0) { $0 + $1.cards.count },
            playerStats: players.map { player in
                PlayerGameStats(
                    playerId: player.id,
                    playerName: player.name,
                    finalScore: player.score,
                    cardsRemaining: player.hand.count,
                    tricksWon: trickHistory.filter { $0.winnerPlayerId == player.id }.count
                )
            }
        )
    }
    
    // MARK: - Codable Implementation
    
    enum CodingKeys: String, CodingKey {
        case id, createdAt, updatedAt, phase, roundNumber, trickNumber, targetScore
        case players, currentPlayerIndex, dealerIndex, deck, tableCards
        case trickHistory, lastMove, gameResult, isWaitingForPlayerInput
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode properties
        let decodedId = try container.decode(UUID.self, forKey: .id)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        phase = try container.decode(GamePhase.self, forKey: .phase)
        roundNumber = try container.decode(Int.self, forKey: .roundNumber)
        trickNumber = try container.decode(Int.self, forKey: .trickNumber)
        targetScore = try container.decodeIfPresent(Int.self, forKey: .targetScore) ?? 11
        currentPlayerIndex = try container.decode(Int.self, forKey: .currentPlayerIndex)
        dealerIndex = try container.decode(Int.self, forKey: .dealerIndex)
        deck = try container.decode(Deck.self, forKey: .deck)
        tableCards = try container.decode([Card].self, forKey: .tableCards)
        trickHistory = try container.decode([CompletedTrick].self, forKey: .trickHistory)
        lastMove = try container.decodeIfPresent(GameMove.self, forKey: .lastMove)
        gameResult = try container.decodeIfPresent(GameResult.self, forKey: .gameResult)
        isWaitingForPlayerInput = try container.decode(Bool.self, forKey: .isWaitingForPlayerInput)
        
        // Handle players separately as they need special treatment
        let playersData = try container.decode([PlayerData].self, forKey: .players)
        players = playersData.map { $0.toPlayer() }
        
        // Set the id (it's a let constant)
        _ = decodedId // We can't change the id after init, so we'll use the auto-generated one
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(phase, forKey: .phase)
        try container.encode(roundNumber, forKey: .roundNumber)
        try container.encode(trickNumber, forKey: .trickNumber)
        try container.encode(targetScore, forKey: .targetScore)
        try container.encode(currentPlayerIndex, forKey: .currentPlayerIndex)
        try container.encode(dealerIndex, forKey: .dealerIndex)
        try container.encode(deck, forKey: .deck)
        try container.encode(tableCards, forKey: .tableCards)
        try container.encode(trickHistory, forKey: .trickHistory)
        try container.encodeIfPresent(lastMove, forKey: .lastMove)
        try container.encodeIfPresent(gameResult, forKey: .gameResult)
        try container.encode(isWaitingForPlayerInput, forKey: .isWaitingForPlayerInput)
        
        // Convert players to codable data
        let playersData = players.map { PlayerData.from($0) }
        try container.encode(playersData, forKey: .players)
    }
}

// MARK: - Supporting Types

/// Codable representation of Player for GameState serialization
struct PlayerData: Codable {
    let id: UUID
    let name: String
    let hand: [Card]
    let score: Int
    let statistics: PlayerStatistics
    let isAI: Bool
    let aiDifficulty: AIDifficulty?
    
    static func from(_ player: Player) -> PlayerData {
        if let aiPlayer = player as? AIPlayer {
            return PlayerData(
                id: player.id,
                name: player.name,
                hand: player.hand,
                score: player.score,
                statistics: player.statistics,
                isAI: true,
                aiDifficulty: aiPlayer.difficulty
            )
        } else {
            return PlayerData(
                id: player.id,
                name: player.name,
                hand: player.hand,
                score: player.score,
                statistics: player.statistics,
                isAI: false,
                aiDifficulty: nil
            )
        }
    }
    
    func toPlayer() -> Player {
        if isAI, let difficulty = aiDifficulty {
            let aiPlayer = AIPlayer(name: name, difficulty: difficulty, id: id)
            aiPlayer.hand = hand
            aiPlayer.score = score
            aiPlayer.statistics = statistics
            return aiPlayer
        } else {
            let humanPlayer = Player(name: name, id: id)
            humanPlayer.hand = hand
            humanPlayer.score = score
            humanPlayer.statistics = statistics
            return humanPlayer
        }
    }
}

/// Different phases of the game
enum GamePhase: String, CaseIterable, Codable {
    case setup = "setup"           // Setting up players and deck
    case playing = "playing"       // Game in progress
    case finished = "finished"     // Game completed
    case paused = "paused"         // Game temporarily paused
}

/// Represents a single move in the game
struct GameMove: Codable {
    let playerId: UUID
    let card: Card
    let timestamp: Date
    let tableCardsCount: Int
}

/// Represents a completed trick
struct CompletedTrick: Codable {
    let trickNumber: Int
    let cards: [Card]
    let winnerPlayerId: UUID
    let points: Int
}

/// Final result of a completed game
struct GameResult: Codable {
    let winnerId: UUID?
    let finalScores: [UUID: Int]
    let totalTricks: Int
    let gameDuration: TimeInterval
    
    /// Whether the game ended in a tie
    var isTie: Bool {
        return winnerId == nil
    }
    
    /// Get the winning score
    var winningScore: Int? {
        guard let winnerId = winnerId else { return nil }
        return finalScores[winnerId]
    }
}

/// Result of attempting to play a card
enum PlayResult {
    case success
    case failure(PlayError)
}

/// Errors that can occur when playing a card
enum PlayError: Error, LocalizedError {
    case playerNotFound
    case notPlayerTurn
    case invalidMove(MoveError)
    case gameNotInProgress
    
    var errorDescription: String? {
        switch self {
        case .playerNotFound:
            return "Player not found in game"
        case .notPlayerTurn:
            return "It is not the player's turn"
        case .invalidMove(let moveError):
            return moveError.localizedDescription
        case .gameNotInProgress:
            return "Game is not currently in progress"
        }
    }
}

/// Statistics about the current game
struct GameStatistics {
    let totalTricks: Int
    let totalCardsPlayed: Int
    let playerStats: [PlayerGameStats]
}

/// Statistics for a single player in the current game
struct PlayerGameStats {
    let playerId: UUID
    let playerName: String
    let finalScore: Int
    let cardsRemaining: Int
    let tricksWon: Int
}

// MARK: - GameState Extensions
// Note: GameState is not Codable due to ObservableObject complexity
// Use GameSession for persistence instead
