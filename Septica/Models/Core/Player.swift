//
//  Player.swift
//  Septica
//
//  Base player model for Septica game
//  Represents both human and AI players with stats and game state
//

import Foundation

/// Base protocol for all player types in Septica
protocol SepticaPlayer: AnyObject {
    var id: UUID { get }
    var name: String { get }
    var hand: [Card] { get set }
    var score: Int { get set }
    var isHuman: Bool { get }
    
    /// Make a move in the game
    /// - Parameters:
    ///   - gameState: Current state of the game
    ///   - validMoves: Cards the player can legally play
    /// - Returns: The card chosen to play
    func chooseCard(gameState: GameState, validMoves: [Card]) async -> Card?
    
    /// React to a game event (card played, trick won, etc.)
    /// - Parameter event: The game event that occurred
    func handleGameEvent(_ event: GameEvent)
}

/// Represents a player in the Septica game
class Player: SepticaPlayer, ObservableObject {
    let id = UUID()
    @Published var name: String
    @Published var hand: [Card] = []
    @Published var score: Int = 0
    @Published var statistics: PlayerStatistics
    
    /// Whether this is a human player
    var isHuman: Bool { return true }
    
    init(name: String) {
        self.name = name
        self.statistics = PlayerStatistics()
    }
    
    /// Add a card to the player's hand
    /// - Parameter card: Card to add
    func addCard(_ card: Card) {
        hand.append(card)
    }
    
    /// Remove a card from the player's hand
    /// - Parameter card: Card to remove
    /// - Returns: true if card was found and removed
    @discardableResult
    func removeCard(_ card: Card) -> Bool {
        if let index = hand.firstIndex(where: { $0.suit == card.suit && $0.value == card.value }) {
            hand.remove(at: index)
            return true
        }
        return false
    }
    
    /// Check if player has a specific card
    /// - Parameter card: Card to check for
    /// - Returns: true if player has the card
    func hasCard(_ card: Card) -> Bool {
        return hand.contains { $0.suit == card.suit && $0.value == card.value }
    }
    
    /// Add points to the player's score
    /// - Parameter points: Points to add
    func addPoints(_ points: Int) {
        score += points
    }
    
    /// Reset player's hand and score for a new game
    func resetForNewGame() {
        hand.removeAll()
        score = 0
    }
    
    /// Human players choose cards via UI interaction
    /// This method will be overridden by AI players
    func chooseCard(gameState: GameState, validMoves: [Card]) async -> Card? {
        // For human players, this will be handled by the UI
        // The game controller will wait for user input
        return nil
    }
    
    /// Handle game events (for statistics and feedback)
    func handleGameEvent(_ event: GameEvent) {
        switch event {
        case .cardPlayed(let playerId, let card):
            if playerId == self.id {
                statistics.cardsPlayed += 1
                if card.isPointCard {
                    statistics.pointCardsPlayed += 1
                }
            }
        case .trickWon(let playerId, let points):
            if playerId == self.id {
                statistics.tricksWon += 1
                statistics.totalPointsScored += points
            }
        case .gameEnded(let winnerId, _):
            statistics.gamesPlayed += 1
            if winnerId == self.id {
                statistics.gamesWon += 1
            }
        }
    }
}

/// AI player that makes automated decisions
class AIPlayer: Player {
    let difficulty: AIDifficulty
    let strategy: AIStrategy
    
    override var isHuman: Bool { return false }
    
    init(name: String, difficulty: AIDifficulty = .medium) {
        self.difficulty = difficulty
        self.strategy = AIStrategy(difficulty: difficulty)
        super.init(name: name)
    }
    
    /// AI chooses the best card to play based on strategy
    override func chooseCard(gameState: GameState, validMoves: [Card]) async -> Card? {
        guard !validMoves.isEmpty else { return nil }
        
        // Add slight delay to make AI feel more natural
        let delay = difficulty.thinkingTime
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        
        return strategy.chooseOptimalCard(
            from: validMoves,
            gameState: gameState,
            playerHand: hand
        )
    }
}

// MARK: - Supporting Types

/// AI difficulty levels
enum AIDifficulty: String, CaseIterable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    case expert = "Expert"
    
    /// Thinking time in seconds
    var thinkingTime: Double {
        switch self {
        case .easy: return 1.0
        case .medium: return 1.5
        case .hard: return 2.0
        case .expert: return 2.5
        }
    }
    
    /// How likely the AI is to make optimal moves (0.0-1.0)
    var accuracy: Double {
        switch self {
        case .easy: return 0.6
        case .medium: return 0.8
        case .hard: return 0.9
        case .expert: return 0.95
        }
    }
    
    /// How far ahead the AI looks
    var lookAheadDepth: Int {
        switch self {
        case .easy: return 1
        case .medium: return 2
        case .hard: return 3
        case .expert: return 4
        }
    }
}

/// AI strategy for card selection
struct AIStrategy {
    let difficulty: AIDifficulty
    
    /// Choose the optimal card from available moves
    /// - Parameters:
    ///   - validMoves: Cards that can legally be played
    ///   - gameState: Current state of the game
    ///   - playerHand: AI player's full hand
    /// - Returns: Best card to play
    func chooseOptimalCard(from validMoves: [Card], gameState: GameState, playerHand: [Card]) -> Card {
        // TODO: Implement sophisticated AI logic
        // For now, use basic heuristics
        
        // Apply difficulty-based randomization
        if Double.random(in: 0...1) > difficulty.accuracy {
            return validMoves.randomElement() ?? validMoves.first!
        }
        
        // Basic strategy priorities:
        // 1. Play point cards when safe
        // 2. Use 7s strategically
        // 3. Save strong cards for later
        // 4. Consider opponent's likely responses
        
        let scoredMoves = validMoves.map { card in
            (card: card, score: evaluateMove(card: card, gameState: gameState, playerHand: playerHand))
        }
        
        // Return the highest scored move
        return scoredMoves.max { $0.score < $1.score }?.card ?? validMoves.first!
    }
    
    /// Evaluate the quality of a potential move
    private func evaluateMove(card: Card, gameState: GameState, playerHand: [Card]) -> Double {
        var score: Double = 0
        
        // Point card considerations
        if card.isPointCard {
            // Bonus for playing point cards when likely to win trick
            score += 10
            
            // Penalty if opponent likely has cards that can beat
            if gameState.tableCards.isEmpty {
                score -= 5 // Don't lead with point cards
            }
        }
        
        // Wild card (7) considerations
        if card.value == 7 {
            score += 15 // 7s are very valuable
            
            // Save 7s for critical moments if we have other options
            if validMoves(from: playerHand, excluding: card, gameState: gameState).count > 0 {
                score -= 5
            }
        }
        
        // Special 8 rule considerations
        if card.value == 8 && gameState.tableCards.count % 3 == 0 {
            score += 12 // 8 can beat when table count is divisible by 3
        }
        
        // Hand management - prefer playing lower value cards first
        score -= Double(card.value) * 0.5
        
        // Endgame considerations
        if playerHand.count <= 2 {
            // In endgame, be more aggressive with point cards
            if card.isPointCard {
                score += 5
            }
        }
        
        return score
    }
    
    /// Get valid moves excluding a specific card
    private func validMoves(from hand: [Card], excluding excludedCard: Card, gameState: GameState) -> [Card] {
        let filteredHand = hand.filter { !($0.suit == excludedCard.suit && $0.value == excludedCard.value) }
        let topCard = gameState.tableCards.last
        
        return GameRules.validMoves(
            from: filteredHand,
            against: topCard,
            tableCardsCount: gameState.tableCards.count
        )
    }
}

/// Statistics tracked for each player
struct PlayerStatistics: Codable {
    var gamesPlayed: Int = 0
    var gamesWon: Int = 0
    var tricksWon: Int = 0
    var cardsPlayed: Int = 0
    var pointCardsPlayed: Int = 0
    var totalPointsScored: Int = 0
    
    /// Win rate as a percentage
    var winRate: Double {
        guard gamesPlayed > 0 else { return 0.0 }
        return Double(gamesWon) / Double(gamesPlayed) * 100.0
    }
    
    /// Average points per game
    var averagePointsPerGame: Double {
        guard gamesPlayed > 0 else { return 0.0 }
        return Double(totalPointsScored) / Double(gamesPlayed)
    }
    
    /// Tricks won rate as a percentage
    var trickWinRate: Double {
        guard cardsPlayed > 0 else { return 0.0 }
        return Double(tricksWon) / Double(cardsPlayed) * 100.0
    }
}

/// Game events that players can react to
enum GameEvent {
    case cardPlayed(playerId: UUID, card: Card)
    case trickWon(playerId: UUID, points: Int)
    case gameEnded(winnerId: UUID?, finalScores: [UUID: Int])
}

// MARK: - Player Extensions

extension Player: Equatable {
    static func == (lhs: Player, rhs: Player) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Player: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// Note: Player is not Codable due to ObservableObject and class complexity
// Use PlayerStatistics and other simple structs for persistence