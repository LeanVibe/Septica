//
//  Player.swift
//  Septica
//
//  Base player model for Septica game
//  Represents both human and AI players with stats and game state
//

import Foundation
import Combine

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
    let id: UUID
    @Published var name: String
    @Published var hand: [Card] = []
    @Published var score: Int = 0
    @Published var statistics: PlayerStatistics
    
    /// Whether this is a human player
    var isHuman: Bool { return true }
    
    init(name: String, id: UUID = UUID()) {
        self.id = id
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
    
    init(name: String, difficulty: AIDifficulty = .medium, id: UUID = UUID()) {
        self.difficulty = difficulty
        self.strategy = AIStrategy(difficulty: difficulty)
        super.init(name: name, id: id)
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
enum AIDifficulty: String, CaseIterable, Codable {
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

/// AI strategy for card selection - Enhanced with Unity AI patterns
struct AIStrategy {
    let difficulty: AIDifficulty
    
    /// Choose the optimal card from available moves
    /// - Parameters:
    ///   - validMoves: Cards that can legally be played
    ///   - gameState: Current state of the game
    ///   - playerHand: AI player's full hand
    /// - Returns: Best card to play
    func chooseOptimalCard(from validMoves: [Card], gameState: GameState, playerHand: [Card]) -> Card {
        guard !validMoves.isEmpty else { fatalError("No valid moves provided") }
        
        // Apply difficulty-based randomization for sub-optimal play
        if Double.random(in: 0...1) > difficulty.accuracy {
            return validMoves.randomElement() ?? validMoves.first!
        }
        
        // Determine game context for strategy selection
        if gameState.tableCards.isEmpty {
            // Starting a new trick - use optimal move strategy
            return chooseOptimalMove(from: validMoves, gameState: gameState, playerHand: playerHand)
        } else {
            // Continuing a trick - use throw card strategy
            return chooseThrowCard(from: validMoves, gameState: gameState, playerHand: playerHand)
        }
    }
    
    /// Port of Unity's chooseOptimalMove - for starting tricks
    /// Prioritizes cards based on weight system and prefers 7s
    private func chooseOptimalMove(from validMoves: [Card], gameState: GameState, playerHand: [Card]) -> Card {
        let cardWeights = computeCardWeights(gameState: gameState, playerHand: playerHand)
        
        var maxWeight = 0
        var bestCard: Card?
        
        // Find the highest weight card, considering difficulty-based 7 preference
        for card in validMoves {
            if card.value == 7 && shouldPrefer7sInDifficulty(difficulty) {
                // 7s are prioritized based on difficulty level
                bestCard = card
                break
            } else {
                let weight = cardWeights[card.value - 7] // Adjust for 0-based array (values 7-14)
                if weight >= maxWeight {
                    maxWeight = weight
                    bestCard = card
                }
            }
        }
        
        let finalCard = bestCard ?? validMoves.first!
        return applyDifficultyModification(bestCard: finalCard, validMoves: validMoves)
    }
    
    /// Port of Unity's ThrowCard strategy - for continuing tricks
    /// 1. Try to match the trick start card
    /// 2. Use 7 if there are points on the table
    /// 3. Otherwise play a cheap card
    private func chooseThrowCard(from validMoves: [Card], gameState: GameState, playerHand: [Card]) -> Card {
        guard let trickStartCard = gameState.tableCards.first else {
            return chooseOptimalMove(from: validMoves, gameState: gameState, playerHand: playerHand)
        }
        
        // 1. Try to find a matching card (same value)
        for card in validMoves {
            if card.value == trickStartCard.value {
                return card
            }
        }
        
        // 2. If there are points on the table, consider using 7
        let pointsOnTable = GameRules.calculatePoints(from: gameState.tableCards)
        if pointsOnTable > 0 {
            for card in validMoves {
                if card.value == 7 {
                    return card
                }
            }
        }
        
        // 3. Choose a cheap card (non-valuable)
        let cheapCard = chooseACheapCard(from: validMoves)
        return applyDifficultyModification(bestCard: cheapCard, validMoves: validMoves)
    }
    
    /// Port of Unity's chooseACheapCard - plays non-valuable cards
    /// Avoids 7s, 10s, and Aces when possible
    private func chooseACheapCard(from validMoves: [Card]) -> Card {
        // Look for cards that are not 7, 10, or 11 (Ace)
        for card in validMoves {
            let value = card.value
            if value != 7 && value != 10 && value != 11 {
                return card
            }
        }
        
        // If all cards are valuable, return the first one
        return validMoves.first!
    }
    
    /// Port of Unity's computeCardWeights method
    /// Tracks frequency of each card value that has been played
    private func computeCardWeights(gameState: GameState, playerHand: [Card]) -> [Int] {
        // Array for card values 7-14 (8 positions, 0-based indexing)
        var weights = Array(repeating: 0, count: 8)
        
        // Count cards from the current trick
        for card in gameState.tableCards {
            let index = card.value - 7 // Convert to 0-based index
            if index >= 0 && index < 8 {
                weights[index] += 1
            }
        }
        
        // Count cards from completed tricks (won cards from all players)
        for trick in gameState.trickHistory {
            for card in trick.cards {
                let index = card.value - 7
                if index >= 0 && index < 8 {
                    weights[index] += 1
                }
            }
        }
        
        // Count cards in current player's hand
        for card in playerHand {
            let index = card.value - 7
            if index >= 0 && index < 8 {
                weights[index] += 1
            }
        }
        
        return weights
    }
    
    /// Enhanced version of shouldContinueTrick based on Unity's ContinueTrick logic
    /// - Parameters:
    ///   - gameState: Current game state
    ///   - playerHand: AI player's hand
    /// - Returns: true if AI should continue the trick
    func shouldContinueTrick(gameState: GameState, playerHand: [Card]) -> Bool {
        guard let trickStartCard = gameState.tableCards.first else {
            return false // No trick to continue
        }
        
        let validMoves = GameRules.validMoves(
            from: playerHand, 
            against: gameState.topTableCard, 
            tableCardsCount: gameState.tableCards.count
        )
        
        var hasSevenCard = false
        
        // Check if we have a matching card or a 7
        for card in validMoves {
            if card.value == trickStartCard.value {
                return true // Can match, should continue
            } else if card.value == 7 {
                hasSevenCard = true
            }
        }
        
        // If we have a 7 and there are points on the table, continue
        let pointsOnTable = GameRules.calculatePoints(from: gameState.tableCards)
        return hasSevenCard && pointsOnTable > 0
    }
    
    /// Apply difficulty-based modifications to the chosen card
    /// This allows easier difficulties to make occasional suboptimal plays
    private func applyDifficultyModification(bestCard: Card, validMoves: [Card]) -> Card {
        switch difficulty {
        case .easy:
            // 40% chance to make a random move instead of optimal
            if Double.random(in: 0...1) < 0.4 {
                return validMoves.randomElement() ?? bestCard
            }
        case .medium:
            // 20% chance to make a slightly suboptimal move
            if Double.random(in: 0...1) < 0.2 {
                // Prefer non-optimal but reasonable moves
                let nonOptimalMoves = validMoves.filter { $0 != bestCard }
                return nonOptimalMoves.randomElement() ?? bestCard
            }
        case .hard, .expert:
            // Always play optimally
            break
        }
        
        return bestCard
    }
    
    /// Enhanced strategic considerations based on difficulty level
    private func shouldPrefer7sInDifficulty(_ difficulty: AIDifficulty) -> Bool {
        switch difficulty {
        case .easy:
            return false // Don't always prioritize 7s
        case .medium:
            return true // Sometimes prioritize 7s
        case .hard, .expert:
            return true // Always prioritize 7s optimally
        }
    }
    
    /// Determine if AI should be aggressive with point cards based on difficulty
    private func shouldBeAggressiveWithPoints(_ difficulty: AIDifficulty, gameState: GameState) -> Bool {
        let handSize = gameState.currentPlayer?.hand.count ?? 4
        
        switch difficulty {
        case .easy:
            return handSize <= 1 // Only aggressive in endgame
        case .medium:
            return handSize <= 2 // Moderately aggressive
        case .hard:
            return handSize <= 3 // More strategic aggression
        case .expert:
            return true // Always consider strategic aggression
        }
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
