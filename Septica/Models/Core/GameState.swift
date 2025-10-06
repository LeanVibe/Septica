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
/// Optimized for 60 FPS performance and memory efficiency
class GameState: ObservableObject, Codable {
    
    // MARK: - Game Identification
    let id = UUID()
    let createdAt = Date()
    private var _updatedAt = Date()
    
    // Non-published for performance - only update when necessary
    var updatedAt: Date {
        get { _updatedAt }
        set { _updatedAt = newValue }
    }
    
    // MARK: - Game Phase
    @Published var phase: GamePhase = .setup
    @Published var targetScore: Int = 11
    
    @Published var roundNumber: Int = 1
    @Published var trickNumber: Int = 1
    
    // MARK: - Game Configuration
    // Romanian Septica configuration - games end when all cards are played, not by target score
    @Published var gameMode: GameMode = .twoPlayers

    // MARK: - Objection System (Authentic Romanian Septica)
    @Published var waitingForObjection: Bool = false
    @Published var objectionDeadline: Date?
    @Published var lastPlayedCard: Card?
    @Published var validObjectionCards: [Card] = []

    // MARK: - Players
    @Published var players: [Player] = []
    @Published var currentPlayerIndex: Int = 0
    private var _dealerIndex: Int = 0
    
    // Non-published - rarely changes
    var dealerIndex: Int {
        get { _dealerIndex }
        set { _dealerIndex = newValue }
    }
    
    // MARK: - Cards and Deck
    private var _deck = Deck()
    @Published var tableCards: [Card] = []
    private var _trickHistory: [CompletedTrick] = []
    
    // Optimized deck access - only publish when UI needs updates
    var deck: Deck {
        get { _deck }
        set { _deck = newValue }
    }
    
    // Non-published history for performance
    var trickHistory: [CompletedTrick] {
        get { _trickHistory }
        set { _trickHistory = newValue }
    }
    
    // MARK: - Game Flow
    @Published var lastMove: GameMove?
    @Published var gameResult: GameResult?
    @Published var isWaitingForPlayerInput: Bool = false
    
    // MARK: - Multiplayer Support
    @Published var isMultiplayer: Bool = false
    @Published var isOnlineGame: Bool = false
    @Published var localPlayerId: UUID?
    @Published var gameSessionId: String?
    @Published var serverSequenceNumber: Int = 0
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var isReconnecting: Bool = false
    @Published var lastSyncedAt: Date?

    // State recovery tracking
    private var lastKnownServerState: [String: Any]?
    private var pendingMoves: [GameMove] = []
    
    // Performance optimization: Batch state updates
    private var _batchingUpdates = false
    
    /// Begin batching updates to reduce SwiftUI notifications
    func beginBatchUpdates() {
        _batchingUpdates = true
    }
    
    /// End batching and send single update notification
    func endBatchUpdates() {
        _batchingUpdates = false
        objectWillChange.send()
    }
    
    
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
        // Traditional Romanian Septica: Game ends when all cards have been played
        // Not when a target score is reached
        let allCardsPlayed = GameRules.isGameComplete(
            allPlayerHands: players.map { $0.hand },
            deckEmpty: deck.isEmpty
        )
        
        return allCardsPlayed
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
        currentPlayerIndex = _dealerIndex

        // Reset all players
        players.forEach { $0.resetForNewGame() }

        // Create and shuffle deck (30 cards for 3-player mode, 32 for others)
        _deck = Deck(gameMode: gameMode)
        _deck.shuffle()

        // Deal initial hands
        dealInitialHands()

        // Clear game state - use batch updates for performance
        beginBatchUpdates()
        tableCards.removeAll()
        _trickHistory.removeAll()
        lastMove = nil
        gameResult = nil
        endBatchUpdates()

        // Start the game
        phase = .playing
        updateTimestamp()
    }
    
    /// Deal initial hands to all players based on game mode
    private func dealInitialHands() {
        // Ensure correct number of players for game mode
        assert(players.count == GameRules.maxPlayers(for: gameMode), "Romanian Septica requires correct number of players for game mode")

        let hands = GameRules.dealInitialHands(from: &_deck, gameMode: gameMode)
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
        
        // Execute the move with batch updates for performance
        beginBatchUpdates()
        player.removeCard(card)
        tableCards.append(card)
        
        // Record the move
        lastMove = GameMove(
            playerId: playerId,
            card: card,
            timestamp: Date(),
            tableCardsCount: tableCards.count
        )
        endBatchUpdates()
        
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
        let trickWinnerPlayerIndex = (_dealerIndex + winnerIndex) % players.count
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
        _trickHistory.append(completedTrick)
        
        // Notify players
        let event = GameEvent.trickWon(playerId: winner.id, points: points)
        players.forEach { $0.handleGameEvent(event) }
        
        // Clear table and prepare for next trick - batch updates
        beginBatchUpdates()
        tableCards.removeAll()
        currentPlayerIndex = trickWinnerPlayerIndex // Winner starts next trick
        trickNumber += 1
        endBatchUpdates()
        
        // Deal new cards if deck has cards and players need them
        dealNewCardsIfNeeded()
    }
    
    /// Deal new cards to players if needed and available
    /// Traditional Septica: After each trick, players draw cards to maintain hand size until deck is empty
    private func dealNewCardsIfNeeded() {
        // In traditional Septica, maintain hand size of 4 until deck is exhausted
        let targetHandSize = GameRules.initialHandSize
        
        for player in players {
            while player.hand.count < targetHandSize && !_deck.isEmpty {
                if let card = _deck.drawCard() {
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
        beginBatchUpdates()
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
        endBatchUpdates()
        
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
        _updatedAt = Date()
    }
    
    /// Get game statistics for analysis - optimized for performance
    func getGameStatistics() -> GameStatistics {
        return GameStatistics(
            totalTricks: _trickHistory.count,
            totalCardsPlayed: _trickHistory.reduce(0) { $0 + $1.cards.count },
            playerStats: players.map { player in
                PlayerGameStats(
                    playerId: player.id,
                    playerName: player.name,
                    finalScore: player.score,
                    cardsRemaining: player.hand.count,
                    tricksWon: _trickHistory.filter { $0.winnerPlayerId == player.id }.count
                )
            }
        )
    }
    
    // MARK: - Codable Implementation
    
    enum CodingKeys: String, CodingKey {
        case id, createdAt, updatedAt, phase, roundNumber, trickNumber
        case players, currentPlayerIndex, dealerIndex, deck, tableCards
        case trickHistory, lastMove, gameResult, isWaitingForPlayerInput
        case isMultiplayer, isOnlineGame, localPlayerId, gameSessionId, serverSequenceNumber, connectionStatus
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode properties
        let decodedId = try container.decode(UUID.self, forKey: .id)
        // createdAt is let, can't be decoded - use current date
        _updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        phase = try container.decode(GamePhase.self, forKey: .phase)
        roundNumber = try container.decode(Int.self, forKey: .roundNumber)
        trickNumber = try container.decode(Int.self, forKey: .trickNumber)
        currentPlayerIndex = try container.decode(Int.self, forKey: .currentPlayerIndex)
        _dealerIndex = try container.decode(Int.self, forKey: .dealerIndex)
        _deck = try container.decode(Deck.self, forKey: .deck)
        tableCards = try container.decode([Card].self, forKey: .tableCards)
        _trickHistory = try container.decode([CompletedTrick].self, forKey: .trickHistory)
        lastMove = try container.decodeIfPresent(GameMove.self, forKey: .lastMove)
        gameResult = try container.decodeIfPresent(GameResult.self, forKey: .gameResult)
        isWaitingForPlayerInput = try container.decode(Bool.self, forKey: .isWaitingForPlayerInput)
        
        // Decode multiplayer fields
        isMultiplayer = try container.decodeIfPresent(Bool.self, forKey: .isMultiplayer) ?? false
        isOnlineGame = try container.decodeIfPresent(Bool.self, forKey: .isOnlineGame) ?? false
        localPlayerId = try container.decodeIfPresent(UUID.self, forKey: .localPlayerId)
        gameSessionId = try container.decodeIfPresent(String.self, forKey: .gameSessionId)
        serverSequenceNumber = try container.decodeIfPresent(Int.self, forKey: .serverSequenceNumber) ?? 0
        connectionStatus = try container.decodeIfPresent(ConnectionStatus.self, forKey: .connectionStatus) ?? .disconnected
        
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
        try container.encode(currentPlayerIndex, forKey: .currentPlayerIndex)
        try container.encode(_dealerIndex, forKey: .dealerIndex)
        try container.encode(_deck, forKey: .deck)
        try container.encode(tableCards, forKey: .tableCards)
        try container.encode(_trickHistory, forKey: .trickHistory)
        try container.encodeIfPresent(lastMove, forKey: .lastMove)
        try container.encodeIfPresent(gameResult, forKey: .gameResult)
        try container.encode(isWaitingForPlayerInput, forKey: .isWaitingForPlayerInput)
        
        // Encode multiplayer fields
        try container.encode(isMultiplayer, forKey: .isMultiplayer)
        try container.encode(isOnlineGame, forKey: .isOnlineGame)
        try container.encodeIfPresent(localPlayerId, forKey: .localPlayerId)
        try container.encodeIfPresent(gameSessionId, forKey: .gameSessionId)
        try container.encode(serverSequenceNumber, forKey: .serverSequenceNumber)
        try container.encode(connectionStatus, forKey: .connectionStatus)
        
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

// MARK: - Multiplayer Types

/// Connection status for online multiplayer games
enum ConnectionStatus: String, CaseIterable, Codable {
    case disconnected = "disconnected"
    case connecting = "connecting"
    case connected = "connected"
    case reconnecting = "reconnecting"
    case error = "error"
}

// MARK: - GameState Extensions

extension GameState {
    
    /// Configure game for multiplayer mode
    /// - Parameters:
    ///   - localPlayerId: UUID of the local player
    ///   - gameSessionId: Server-assigned game session ID
    ///   - isOnline: Whether this is an online game (vs local multiplayer)
    func configureForMultiplayer(localPlayerId: UUID, gameSessionId: String, isOnline: Bool = true) {
        self.isMultiplayer = true
        self.isOnlineGame = isOnline
        self.localPlayerId = localPlayerId
        self.gameSessionId = gameSessionId
        self.serverSequenceNumber = 0
        self.connectionStatus = isOnline ? .connecting : .connected
    }
    
    /// Update server sequence number for synchronization
    /// - Parameter sequenceNumber: New sequence number from server
    func updateServerSequence(_ sequenceNumber: Int) {
        self.serverSequenceNumber = sequenceNumber
    }
    
    /// Check if it's the local player's turn
    var isLocalPlayerTurn: Bool {
        guard let localId = localPlayerId,
              let currentId = currentPlayer?.id else { return false }
        return currentId == localId
    }
    
    /// Get the remote player (opponent)
    var remotePlayer: Player? {
        guard let localId = localPlayerId else { return nil }
        return players.first { $0.id != localId }
    }

    // MARK: - Reconnection Handling

    /// Handle reconnection with state recovery
    /// Merges recovered server state with local state and validates consistency
    /// - Parameter recoveredState: Game state recovered from server
    func handleReconnection(recoveredState: [String: Any]) {
        print("[GameState] Handling reconnection with recovered state")

        isReconnecting = true
        beginBatchUpdates()

        // Validate server sequence number (prevent stale state)
        if let serverSeq = recoveredState["sequence_number"] as? Int,
           serverSeq > serverSequenceNumber {

            // Server state is newer - merge it
            mergeServerState(recoveredState)

            // Replay any pending moves that weren't synced
            replayPendingMoves()

            // Update sync timestamp
            lastSyncedAt = Date()
            lastKnownServerState = recoveredState

        } else {
            // Local state is same or newer - send local state to server
            print("[GameState] Local state is current, no merge needed")
        }

        isReconnecting = false
        connectionStatus = .connected
        endBatchUpdates()

        print("[GameState] Reconnection complete - game resumed")
    }

    /// Merge server state with local state
    /// Prioritizes server authoritative data while preserving local UI state
    private func mergeServerState(_ serverState: [String: Any]) {
        print("[GameState] Merging server state")

        // Update sequence number
        if let serverSeq = serverState["sequence_number"] as? Int {
            serverSequenceNumber = serverSeq
        }

        // Update round and trick numbers
        if let roundNum = serverState["round_number"] as? Int {
            roundNumber = roundNum
        }

        if let trickNum = serverState["trick_number"] as? Int {
            trickNumber = trickNum
        }

        // Update current player
        if let currentPlayerIdString = serverState["current_player_id"] as? String,
           let currentPlayerId = UUID(uuidString: currentPlayerIdString) {
            if let playerIdx = players.firstIndex(where: { $0.id == currentPlayerId }) {
                currentPlayerIndex = playerIdx
            }
        }

        // Update table cards
        if let tableCardsData = serverState["table_cards"] as? [[String: Any]] {
            tableCards = tableCardsData.compactMap { cardData in
                guard let suit = cardData["suit"] as? String,
                      let value = cardData["value"] as? Int else { return nil }
                return Card(suit: Suit(rawValue: suit) ?? .hearts, value: value)
            }
        }

        // Update player hands and scores
        if let playerHands = serverState["player_hands"] as? [String: [[String: Any]]] {
            for player in players {
                if let handData = playerHands[player.id.uuidString] {
                    let hand = handData.compactMap { cardData -> Card? in
                        guard let suit = cardData["suit"] as? String,
                              let value = cardData["value"] as? Int else { return nil }
                        return Card(suit: Suit(rawValue: suit) ?? .hearts, value: value)
                    }
                    player.hand = hand
                }
            }
        }

        if let scores = serverState["scores"] as? [String: Int] {
            for player in players {
                if let score = scores[player.id.uuidString] {
                    player.score = score
                }
            }
        }

        // Update game phase
        if let status = serverState["status"] as? String {
            switch status {
            case "playing":
                phase = .playing
            case "finished":
                phase = .finished
            case "paused":
                phase = .paused
            default:
                break
            }
        }

        print("[GameState] Server state merged successfully")
    }

    /// Replay pending moves that weren't synced before disconnect
    private func replayPendingMoves() {
        guard !pendingMoves.isEmpty else { return }

        print("[GameState] Replaying \(pendingMoves.count) pending moves")

        for move in pendingMoves {
            // Attempt to replay the move
            _ = playCard(move.card, by: move.playerId)
        }

        // Clear pending moves after replay
        pendingMoves.removeAll()
    }

    /// Store server state snapshot for recovery
    func storeServerStateSnapshot(_ state: [String: Any]) {
        lastKnownServerState = state
        lastSyncedAt = Date()
    }

    /// Add move to pending queue (for offline play during disconnect)
    func addPendingMove(_ move: GameMove) {
        pendingMoves.append(move)
    }

    /// Clear pending moves (after successful sync)
    func clearPendingMoves() {
        pendingMoves.removeAll()
    }

    /// Validate state consistency between client and server
    /// Returns true if states are consistent, false if conflict detected
    func validateStateConsistency(with serverState: [String: Any]) -> Bool {
        // Check sequence number
        guard let serverSeq = serverState["sequence_number"] as? Int else {
            return false
        }

        // Allow server to be ahead (we're catching up)
        // or equal (we're in sync)
        // but not behind (client state is invalid)
        if serverSeq < serverSequenceNumber {
            print("[GameState] State conflict: server behind client")
            return false
        }

        // Check current player consistency
        if let serverPlayerId = serverState["current_player_id"] as? String,
           let localPlayerId = currentPlayer?.id.uuidString,
           serverSeq == serverSequenceNumber {
            if serverPlayerId != localPlayerId {
                print("[GameState] State conflict: different current player")
                return false
            }
        }

        return true
    }

    /// Reset reconnection state
    func resetReconnectionState() {
        isReconnecting = false
        pendingMoves.removeAll()
    }

    // MARK: - Team Play Support (4-player mode)

    /// Team indices for 4-player mode (2v2)
    /// Team A: Players 0 and 2 (human + partner opposite)
    /// Team B: Players 1 and 3 (opponents on sides)
    var teamAIndices: [Int] {
        guard gameMode == .fourPlayers else { return [] }
        return [0, 2]
    }

    var teamBIndices: [Int] {
        guard gameMode == .fourPlayers else { return [] }
        return [1, 3]
    }

    /// Get combined team score for Team A (human + partner)
    var teamAScore: Int {
        guard gameMode == .fourPlayers else { return 0 }
        return teamAIndices.reduce(0) { total, index in
            guard index < players.count else { return total }
            return total + players[index].score
        }
    }

    /// Get combined team score for Team B (opponents)
    var teamBScore: Int {
        guard gameMode == .fourPlayers else { return 0 }
        return teamBIndices.reduce(0) { total, index in
            guard index < players.count else { return total }
            return total + players[index].score
        }
    }

    /// Check if a player is on Team A (human's team)
    func isTeamA(playerIndex: Int) -> Bool {
        guard gameMode == .fourPlayers else { return false }
        return teamAIndices.contains(playerIndex)
    }

    /// Check if a player is on Team B (opponent team)
    func isTeamB(playerIndex: Int) -> Bool {
        guard gameMode == .fourPlayers else { return false }
        return teamBIndices.contains(playerIndex)
    }

    /// Get partner index for a given player (4-player mode only)
    func getPartnerIndex(for playerIndex: Int) -> Int? {
        guard gameMode == .fourPlayers else { return nil }

        if teamAIndices.contains(playerIndex) {
            return teamAIndices.first { $0 != playerIndex }
        } else if teamBIndices.contains(playerIndex) {
            return teamBIndices.first { $0 != playerIndex }
        }
        return nil
    }
}

// MARK: - GameState Extensions
// Note: GameState is not Codable due to ObservableObject complexity
// Use GameSession for persistence instead
