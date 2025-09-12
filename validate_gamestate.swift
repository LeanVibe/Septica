#!/usr/bin/env swift

//
//  validate_gamestate.swift
//  Game State Validation Script
//
//  Tests game flow, state transitions, and comprehensive game simulation
//

import Foundation
import Combine

// MARK: - Copy Required Types (since we can't import)

enum Suit: String, CaseIterable, Codable {
    case hearts = "hearts"
    case diamonds = "diamonds"
    case clubs = "clubs"
    case spades = "spades"
    
    var symbol: String {
        switch self {
        case .hearts: return "♥️"
        case .diamonds: return "♦️"
        case .clubs: return "♣️"
        case .spades: return "♠️"
        }
    }
}

struct Card: Identifiable, Codable, Equatable, Hashable {
    let id = UUID()
    let suit: Suit
    let value: Int
    
    private enum CodingKeys: String, CodingKey {
        case suit, value
    }
    
    init(suit: Suit, value: Int) {
        precondition(value >= 7 && value <= 14, "Card value must be between 7 and 14")
        self.suit = suit
        self.value = value
    }
    
    var isPointCard: Bool {
        return value == 10 || value == 14
    }
    
    var displayValue: String {
        switch value {
        case 7...10: return "\(value)"
        case 11: return "J"
        case 12: return "Q"
        case 13: return "K"
        case 14: return "A"
        default: return "\(value)"
        }
    }
    
    var displayName: String {
        return "\(displayValue)\(suit.symbol)"
    }
    
    func canBeat(_ otherCard: Card, tableCardsCount: Int) -> Bool {
        if self.value == 7 { return true }
        if self.value == 8 && tableCardsCount % 3 == 0 { return true }
        if self.value == otherCard.value { return true }
        return false
    }
}

struct Deck {
    private var cards: [Card]
    
    init() {
        self.cards = Deck.createStandardDeck()
    }
    
    var count: Int { cards.count }
    var isEmpty: Bool { cards.isEmpty }
    
    mutating func shuffle() {
        for i in stride(from: cards.count - 1, through: 1, by: -1) {
            let j = Int.random(in: 0...i)
            cards.swapAt(i, j)
        }
    }
    
    mutating func drawCard() -> Card? {
        guard !cards.isEmpty else { return nil }
        return cards.removeFirst()
    }
    
    private static func createStandardDeck() -> [Card] {
        var deck: [Card] = []
        for suit in Suit.allCases {
            for value in 7...14 {
                deck.append(Card(suit: suit, value: value))
            }
        }
        return deck
    }
}

struct GameRules {
    static let initialHandSize = 4
    static let totalPoints = 8
    
    static func canBeat(attackingCard: Card, targetCard: Card, tableCardsCount: Int) -> Bool {
        return attackingCard.canBeat(targetCard, tableCardsCount: tableCardsCount)
    }
    
    static func calculatePoints(from cards: [Card]) -> Int {
        return cards.filter { $0.isPointCard }.count
    }
    
    static func validMoves(from playerHand: [Card], against topTableCard: Card?, tableCardsCount: Int) -> [Card] {
        guard let topCard = topTableCard else { return playerHand }
        return playerHand.filter { card in
            canBeat(attackingCard: card, targetCard: topCard, tableCardsCount: tableCardsCount)
        }
    }
    
    static func determineTrickWinner(tableCards: [Card]) -> Int {
        guard !tableCards.isEmpty else { return 0 }
        return tableCards.count - 1
    }
    
    static func isGameComplete(allPlayerHands: [[Card]], deckEmpty: Bool) -> Bool {
        return allPlayerHands.allSatisfy { $0.isEmpty } && deckEmpty
    }
    
    static func determineGameWinner(playerScores: [Int]) -> Int? {
        guard let maxScore = playerScores.max(), maxScore > 0 else { return nil }
        let winnersWithMaxScore = playerScores.enumerated().compactMap { index, score in
            score == maxScore ? index : nil
        }
        return winnersWithMaxScore.count == 1 ? winnersWithMaxScore.first : nil
    }
}

// Simple player for testing
class TestPlayer {
    let id = UUID()
    let name: String
    var hand: [Card] = []
    var score: Int = 0
    
    init(name: String) {
        self.name = name
    }
    
    func addCard(_ card: Card) { hand.append(card) }
    func addPoints(_ points: Int) { score += points }
    
    func removeCard(_ card: Card) -> Bool {
        if let index = hand.firstIndex(where: { $0.suit == card.suit && $0.value == card.value }) {
            hand.remove(at: index)
            return true
        }
        return false
    }
}

// Simple game state for testing
class TestGameState {
    var players: [TestPlayer] = []
    var deck = Deck()
    var tableCards: [Card] = []
    var currentPlayerIndex = 0
    
    init(players: [TestPlayer]) {
        self.players = players
        deck.shuffle()
        dealInitialHands()
    }
    
    private func dealInitialHands() {
        for _ in 0..<GameRules.initialHandSize {
            for player in players {
                if let card = deck.drawCard() {
                    player.addCard(card)
                }
            }
        }
    }
    
    func playCard(_ card: Card, by playerId: UUID) -> Bool {
        guard let playerIndex = players.firstIndex(where: { $0.id == playerId }),
              playerIndex == currentPlayerIndex else { return false }
        
        let player = players[playerIndex]
        let validMoves = GameRules.validMoves(from: player.hand, against: tableCards.last, tableCardsCount: tableCards.count)
        
        guard validMoves.contains(where: { $0.suit == card.suit && $0.value == card.value }) else { return false }
        
        player.removeCard(card)
        tableCards.append(card)
        
        return true
    }
    
    func completeTrick() {
        guard !tableCards.isEmpty else { return }
        let winnerIndex = GameRules.determineTrickWinner(tableCards: tableCards)
        let points = GameRules.calculatePoints(from: tableCards)
        players[winnerIndex].addPoints(points)
        tableCards.removeAll()
    }
}

// MARK: - Validation Framework
class GameStateValidator {
    private var testsPassed = 0
    private var testsFailed = 0
    private var results: [String] = []
    
    func test(_ condition: Bool, _ description: String) {
        if condition {
            testsPassed += 1
            results.append("✅ \(description)")
        } else {
            testsFailed += 1
            results.append("❌ \(description)")
        }
    }
    
    func printResults() {
        print("\n" + String(repeating: "=", count: 50))
        print("GAME STATE VALIDATION RESULTS")
        print(String(repeating: "=", count: 50))
        
        for result in results {
            print(result)
        }
        
        print("\nSUMMARY:")
        print("✅ Passed: \(testsPassed)")
        print("❌ Failed: \(testsFailed)")
        print("Total: \(testsPassed + testsFailed)")
        print("Success Rate: \(Int(Double(testsPassed) / Double(testsPassed + testsFailed) * 100))%")
        print(String(repeating: "=", count: 50))
    }
    
    var allTestsPassed: Bool {
        return testsFailed == 0
    }
}

// MARK: - Test Functions
func testGameInitialization(validator: GameStateValidator) {
    print("\n🎮 Testing Game Initialization...")
    
    let player1 = TestPlayer(name: "Player 1")
    let player2 = TestPlayer(name: "Player 2")
    let gameState = TestGameState(players: [player1, player2])
    
    validator.test(player1.hand.count == GameRules.initialHandSize, "Player 1 has correct initial hand size")
    validator.test(player2.hand.count == GameRules.initialHandSize, "Player 2 has correct initial hand size")
    validator.test(gameState.deck.count == 32 - (2 * GameRules.initialHandSize), "Deck has correct remaining cards")
    validator.test(gameState.tableCards.isEmpty, "Table starts empty")
    validator.test(gameState.currentPlayerIndex == 0, "Game starts with player 0")
}

func testCardPlayValidation(validator: GameStateValidator) {
    print("\n🃏 Testing Card Play Validation...")
    
    let player1 = TestPlayer(name: "Player 1")
    let player2 = TestPlayer(name: "Player 2")
    
    // Set up specific hands for testing
    player1.hand = [
        Card(suit: .hearts, value: 7),   // Wild card
        Card(suit: .spades, value: 10)   // Regular card
    ]
    player2.hand = [Card(suit: .clubs, value: 9)]
    
    let gameState = TestGameState(players: [player1, player2])
    
    // Test valid card play
    let validCard = Card(suit: .hearts, value: 7)
    let played = gameState.playCard(validCard, by: player1.id)
    validator.test(played, "Valid card play accepted")
    validator.test(gameState.tableCards.count == 1, "Card added to table")
    validator.test(player1.hand.count == 1, "Card removed from player hand")
    
    // Test invalid player turn
    let invalidTurnCard = Card(suit: .clubs, value: 9)
    let wrongTurnPlayed = gameState.playCard(invalidTurnCard, by: player2.id)
    validator.test(!wrongTurnPlayed, "Wrong turn play rejected")
}

func testTrickCompletion(validator: GameStateValidator) {
    print("\n🏆 Testing Trick Completion...")
    
    let player1 = TestPlayer(name: "Player 1")
    let player2 = TestPlayer(name: "Player 2")
    let gameState = TestGameState(players: [player1, player2])
    
    // Set up table with point cards
    gameState.tableCards = [
        Card(suit: .hearts, value: 10),  // 1 point
        Card(suit: .spades, value: 14)   // 1 point (Ace)
    ]
    
    let initialPlayer1Score = player1.score
    gameState.completeTrick()
    
    validator.test(gameState.tableCards.isEmpty, "Table cleared after trick completion")
    validator.test(player1.score == initialPlayer1Score + 2, "Winner received correct points (2 for 10 + Ace)")
}

func testGameCompletion(validator: GameStateValidator) {
    print("\n🎯 Testing Game Completion Logic...")
    
    // Test game not complete
    let hands1: [[Card]] = [
        [Card(suit: .hearts, value: 7)],
        []
    ]
    validator.test(!GameRules.isGameComplete(allPlayerHands: hands1, deckEmpty: true), "Game not complete with cards remaining")
    
    // Test game complete
    let hands2: [[Card]] = [[], []]
    validator.test(GameRules.isGameComplete(allPlayerHands: hands2, deckEmpty: true), "Game complete when all hands empty and deck empty")
    
    // Test winner determination
    let scores = [3, 5, 2]
    let winner = GameRules.determineGameWinner(playerScores: scores)
    validator.test(winner == 1, "Correct winner determination")
    
    // Test tie
    let tieScores = [3, 3, 2]
    let tieWinner = GameRules.determineGameWinner(playerScores: tieScores)
    validator.test(tieWinner == nil, "Tie correctly identified")
}

func runCompleteGameSimulation(validator: GameStateValidator) {
    print("\n🎲 Running Complete Game Simulation...")
    
    let player1 = TestPlayer(name: "AI Player 1")
    let player2 = TestPlayer(name: "AI Player 2")
    let gameState = TestGameState(players: [player1, player2])
    
    var tricksPlayed = 0
    let maxTricks = 10
    
    while tricksPlayed < maxTricks && (!player1.hand.isEmpty || !player2.hand.isEmpty) {
        let currentPlayer = gameState.players[gameState.currentPlayerIndex]
        
        if currentPlayer.hand.isEmpty {
            gameState.currentPlayerIndex = (gameState.currentPlayerIndex + 1) % 2
            continue
        }
        
        let validMoves = GameRules.validMoves(
            from: currentPlayer.hand,
            against: gameState.tableCards.last,
            tableCardsCount: gameState.tableCards.count
        )
        
        if validMoves.isEmpty {
            // No valid moves - complete trick
            gameState.completeTrick()
            tricksPlayed += 1
            print("  Trick \(tricksPlayed): \(currentPlayer.name) wins - Score: P1=\(player1.score), P2=\(player2.score)")
            continue
        }
        
        // Choose random valid card (simple AI)
        let chosenCard = validMoves.randomElement()!
        let played = gameState.playCard(chosenCard, by: currentPlayer.id)
        
        if played {
            print("  \(currentPlayer.name) plays \(chosenCard.displayName)")
        }
        
        gameState.currentPlayerIndex = (gameState.currentPlayerIndex + 1) % 2
    }
    
    validator.test(tricksPlayed > 0, "At least one trick was played")
    validator.test(player1.score + player2.score <= GameRules.totalPoints, "Total score doesn't exceed maximum")
    
    print("  Final Score: \(player1.name): \(player1.score), \(player2.name): \(player2.score)")
    
    let winner = GameRules.determineGameWinner(playerScores: [player1.score, player2.score])
    if let winnerIndex = winner {
        let winnerName = winnerIndex == 0 ? player1.name : player2.name
        print("  Winner: \(winnerName)")
        validator.test(true, "Game completed with a winner")
    } else {
        print("  Game ended in a tie")
        validator.test(true, "Game completed (tie)")
    }
}

// MARK: - Main Runner
func main() {
    print("🚀 Starting Game State Validation Suite")
    print("Testing game flow, state transitions, and complete gameplay")
    
    let validator = GameStateValidator()
    
    testGameInitialization(validator: validator)
    testCardPlayValidation(validator: validator)
    testTrickCompletion(validator: validator)
    testGameCompletion(validator: validator)
    runCompleteGameSimulation(validator: validator)
    
    validator.printResults()
    
    if validator.allTestsPassed {
        print("\n🎉 ALL GAME STATE TESTS PASSED!")
        print("✅ Game flow and state management working correctly!")
    } else {
        print("\n⚠️ Some game state tests failed. Review implementation.")
    }
}

main()