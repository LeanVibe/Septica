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
    var strategy: AIStrategy // Made mutable to support learning
    
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

// MARK: - Supporting Types for Enhanced AI

/// AI Game phases for strategic decision making
enum AIGamePhase {
    case earlyGame   // Conservative, information gathering
    case midGame     // Balanced, tactical
    case endGame     // Aggressive, point maximizing
}

/// Opponent modeling for predictive play
struct OpponentModel {
    private var cardPlayHistory: [Card] = []
    private var strategicPatterns: [String: Int] = [:]
    
    /// Predict opponent's next likely card based on learned patterns
    mutating func predictNextCard(gameState: GameState) -> Card? {
        // Analyze opponent's previous plays
        recordOpponentMoves(gameState: gameState)
        
        // Simple pattern recognition: opponent's tendency toward certain values
        let currentPlayer = gameState.currentPlayer
        let opponentPlayers = gameState.players.filter { $0.id != currentPlayer?.id }
        
        guard opponentPlayers.first != nil else { return nil }
        
        // Romanian Septica insight: Players often follow value preference patterns
        let valuePreferences = analyzeValuePreferences()
        
        // Return most likely card value (simplified prediction)
        if let preferredValue = valuePreferences.max(by: { $0.value < $1.value })?.key,
           let intValue = Int(preferredValue) {
            // Create a representative card for prediction
            return Card(suit: .hearts, value: intValue) // Suit doesn't matter for prediction
        }
        
        return nil
    }
    
    /// Record opponent moves for pattern learning
    private mutating func recordOpponentMoves(gameState: GameState) {
        // Track cards played in recent tricks
        for trick in gameState.trickHistory.suffix(3) { // Last 3 tricks
            cardPlayHistory.append(contentsOf: trick.cards)
        }
        
        // Keep history manageable
        if cardPlayHistory.count > 20 {
            cardPlayHistory = Array(cardPlayHistory.suffix(20))
        }
    }
    
    /// Analyze opponent's value preferences
    private func analyzeValuePreferences() -> [String: Int] {
        var preferences: [String: Int] = [:]
        
        for card in cardPlayHistory {
            let key = "\(card.value)"
            preferences[key, default: 0] += 1
        }
        
        return preferences
    }
}

/// Game memory for learning and adaptation
struct GameMemory {
    private var gameStates: [(GameState, [Card])] = []
    private var successfulMoves: [Card] = []
    
    /// Record current game state and hand for learning
    mutating func recordGameState(_ gameState: GameState, playerHand: [Card]) {
        gameStates.append((gameState, playerHand))
        
        // Keep memory manageable - store last 10 states
        if gameStates.count > 10 {
            gameStates = Array(gameStates.suffix(10))
        }
    }
    
    /// Record a successful move outcome
    mutating func recordSuccessfulMove(_ card: Card) {
        successfulMoves.append(card)
        
        // Keep successful moves history reasonable
        if successfulMoves.count > 15 {
            successfulMoves = Array(successfulMoves.suffix(15))
        }
    }
    
    /// Get insights about successful strategies
    func getStrategicInsights() -> [String: Int] {
        var insights: [String: Int] = [:]
        
        for card in successfulMoves {
            let key = card.value == 7 ? "seven" : (card.isPointCard ? "point" : "regular")
            insights[key, default: 0] += 1
        }
        
        return insights
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

/// Enhanced AI strategy for authentic Romanian Septica gameplay
/// Incorporates traditional Romanian card game tactics and cultural playing styles
struct AIStrategy {
    let difficulty: AIDifficulty
    private var opponentModel: OpponentModel
    private var gameMemory: GameMemory
    
    /// Initialize AI strategy with difficulty and learning capabilities
    init(difficulty: AIDifficulty) {
        self.difficulty = difficulty
        self.opponentModel = OpponentModel()
        self.gameMemory = GameMemory()
    }
    
    /// Choose the optimal card from available moves using Romanian Septica tactics
    /// - Parameters:
    ///   - validMoves: Cards that can legally be played
    ///   - gameState: Current state of the game
    ///   - playerHand: AI player's full hand
    /// - Returns: Best card to play
    mutating func chooseOptimalCard(from validMoves: [Card], gameState: GameState, playerHand: [Card]) -> Card {
        guard !validMoves.isEmpty else { fatalError("No valid moves provided") }
        
        // Record current game context for learning
        gameMemory.recordGameState(gameState, playerHand: playerHand)
        
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
    
    /// Choose optimal move when starting a new trick - Romanian Septica style
    /// Incorporates traditional aggressive-defensive balance and 7 hoarding tactics
    private mutating func chooseOptimalMove(from validMoves: [Card], gameState: GameState, playerHand: [Card]) -> Card {
        // Romanian Septica Strategy: Assess game phase and adapt
        let gamePhase = determineGamePhase(gameState: gameState, playerHand: playerHand)
        
        switch gamePhase {
        case .earlyGame:
            return chooseEarlyGameMove(from: validMoves, gameState: gameState, playerHand: playerHand)
        case .midGame:
            return chooseMidGameMove(from: validMoves, gameState: gameState, playerHand: playerHand)
        case .endGame:
            return chooseEndGameMove(from: validMoves, gameState: gameState, playerHand: playerHand)
        }
    }
    
    /// Early game strategy: Conservative play, build card frequency knowledge
    private func chooseEarlyGameMove(from validMoves: [Card], gameState: GameState, playerHand: [Card]) -> Card {
        // In early game, Romanian players traditionally:
        // 1. Avoid playing 7s unless necessary
        // 2. Test opponent's card strength with mid-range cards
        // 3. Collect information about opponent's hand
        
        // Prefer non-7, non-point cards to gather intelligence
        let safeCards = validMoves.filter { card in
            card.value != 7 && !card.isPointCard
        }
        
        if !safeCards.isEmpty {
            // Play a moderately valuable card to test opponent
            return safeCards.sorted { $0.value > $1.value }.first ?? safeCards.randomElement()!
        }
        
        // If only 7s or point cards available, play strategically
        return chooseFromLimitedOptions(validMoves, gameState: gameState, playerHand: playerHand)
    }
    
    /// Mid game strategy: Balanced aggression, capitalize on opponent patterns
    private mutating func chooseMidGameMove(from validMoves: [Card], gameState: GameState, playerHand: [Card]) -> Card {
        // Mid-game Romanian strategy:
        // 1. Use learned opponent patterns
        // 2. Strategic 7 usage for point capture
        // 3. Adaptive difficulty scaling
        
        _ = GameRules.calculatePoints(from: gameState.tableCards)
        let opponentPredictedMove = opponentModel.predictNextCard(gameState: gameState)
        
        // If opponent likely to play valuable card, prepare to beat it
        if let predictedCard = opponentPredictedMove, predictedCard.isPointCard {
            if let counter7 = validMoves.first(where: { $0.value == 7 }) {
                return counter7 // Use 7 to capture points
            }
        }
        
        // Traditional Romanian tactic: Strategic value assessment
        return chooseBestStrategicCard(from: validMoves, gameState: gameState, playerHand: playerHand)
    }
    
    /// End game strategy: Aggressive point capture, optimal 7 timing
    private func chooseEndGameMove(from validMoves: [Card], gameState: GameState, playerHand: [Card]) -> Card {
        // End-game Romanian tactics:
        // 1. Maximize points with remaining cards
        // 2. Use 7s aggressively
        // 3. Block opponent's final point collection
        
        let sevenCards = validMoves.filter { $0.value == 7 }
        
        // In endgame, 7s become highly valuable - use them strategically
        if !sevenCards.isEmpty && difficulty == .expert {
            return sevenCards.first! // Expert AI uses 7s optimally in endgame
        }
        
        // Otherwise play highest value non-7 card to pressure opponent
        let nonSevens = validMoves.filter { $0.value != 7 }
        if !nonSevens.isEmpty {
            return nonSevens.max { $0.value < $1.value } ?? validMoves.first!
        }
        
        return validMoves.first!
    }
    
    /// Legacy method adapted with Romanian strategy enhancements
    private func chooseBestStrategicCard(from validMoves: [Card], gameState: GameState, playerHand: [Card]) -> Card {
        let cardWeights = computeCardWeights(gameState: gameState, playerHand: playerHand)
        
        var maxWeight = 0
        var bestCard: Card?
        
        // Romanian Septica: Weight 7s differently based on context
        for card in validMoves {
            if card.value == 7 && shouldUse7Strategically(gameState: gameState, playerHand: playerHand) {
                bestCard = card
                break
            } else {
                let weight = cardWeights[card.value - 7]
                if weight >= maxWeight {
                    maxWeight = weight
                    bestCard = card
                }
            }
        }
        
        let finalCard = bestCard ?? validMoves.first!
        return applyRomanianDifficultyModification(bestCard: finalCard, validMoves: validMoves)
    }
    
    /// Port of Unity's ThrowCard strategy - for continuing tricks
    /// 1. Try to match the trick start card
    /// 2. Use 7 if there are points on the table
    /// 3. Otherwise play a cheap card
    private mutating func chooseThrowCard(from validMoves: [Card], gameState: GameState, playerHand: [Card]) -> Card {
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
    
    /// Romanian-style difficulty modification with cultural authenticity
    /// Incorporates traditional Romanian playing styles and regional variations
    private func applyRomanianDifficultyModification(bestCard: Card, validMoves: [Card]) -> Card {
        switch difficulty {
        case .easy:
            // Beginner Romanian player: Often plays emotionally, 40% suboptimal
            if Double.random(in: 0...1) < 0.4 {
                return validMoves.randomElement() ?? bestCard
            }
        case .medium:
            // Casual Romanian player: Good intuition, occasional mistakes (20%)
            if Double.random(in: 0...1) < 0.2 {
                // Traditional Romanian tactic: Sometimes hold back strong cards
                let conservativeMoves = validMoves.filter { $0.value != 7 && $0 != bestCard }
                return conservativeMoves.randomElement() ?? bestCard
            }
        case .hard:
            // Experienced Romanian player: Strategic with occasional brilliance
            if Double.random(in: 0...1) < 0.1 {
                // 10% chance for "inspired" play - aggressive moves
                let aggressiveMoves = validMoves.filter { $0.value == 7 || $0.isPointCard }
                return aggressiveMoves.randomElement() ?? bestCard
            }
        case .expert:
            // Master Romanian player: Near-perfect with cultural flair
            // Always plays optimally but with Romanian strategic preferences
            break
        }
        
        return bestCard
    }
    
    /// Enhanced legacy method with Romanian strategic considerations
    private func applyDifficultyModification(bestCard: Card, validMoves: [Card]) -> Card {
        return applyRomanianDifficultyModification(bestCard: bestCard, validMoves: validMoves)
    }
    
    /// Determine current game phase based on cards remaining and scoring
    private func determineGamePhase(gameState: GameState, playerHand: [Card]) -> AIGamePhase {
        let totalCardsRemaining = gameState.players.reduce(0) { $0 + $1.hand.count }
        _ = gameState.trickHistory.count
        let maxPossibleScore = GameRules.totalPoints
        
        // Early game: More than 50% cards remaining
        if totalCardsRemaining > 16 {
            return .earlyGame
        }
        
        // End game: Few cards left or someone close to winning
        if totalCardsRemaining <= 6 || 
           gameState.players.contains(where: { $0.score >= maxPossibleScore - 2 }) {
            return .endGame
        }
        
        // Mid game: Everything else
        return .midGame
    }
    
    /// Strategic 7 usage decision based on Romanian traditional tactics
    private func shouldUse7Strategically(gameState: GameState, playerHand: [Card]) -> Bool {
        let pointsOnTable = GameRules.calculatePoints(from: gameState.tableCards)
        let sevenCount = playerHand.filter { $0.value == 7 }.count
        let gamePhase = determineGamePhase(gameState: gameState, playerHand: playerHand)
        
        switch gamePhase {
        case .earlyGame:
            // Early game: Hoard 7s unless forced or big point opportunity
            return pointsOnTable >= 2
        case .midGame:
            // Mid game: Balanced usage, consider opponent behavior
            return pointsOnTable >= 1 || sevenCount >= 3
        case .endGame:
            // End game: Use 7s more aggressively
            return pointsOnTable >= 1 || difficulty == .expert
        }
    }
    
    /// Choose from limited options when only valuable cards available
    private func chooseFromLimitedOptions(_ validMoves: [Card], gameState: GameState, playerHand: [Card]) -> Card {
        let pointCards = validMoves.filter { $0.isPointCard }
        let sevenCards = validMoves.filter { $0.value == 7 }
        
        // Romanian strategy: In tough spots, prefer keeping 7s over point cards
        if !pointCards.isEmpty && pointCards.count < sevenCards.count {
            return pointCards.first!
        }
        
        // Otherwise play the "least valuable" card
        return validMoves.min { card1, card2 in
            let value1 = card1.value == 7 ? 15 : (card1.isPointCard ? card1.value + 5 : card1.value)
            let value2 = card2.value == 7 ? 15 : (card2.isPointCard ? card2.value + 5 : card2.value)
            return value1 < value2
        } ?? validMoves.first!
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
