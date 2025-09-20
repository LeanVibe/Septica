//
//  TestDataFixtures.swift
//  SepticaTests
//
//  Test data fixtures and helpers for reproducible Romanian Septica testing
//  Provides predefined game scenarios and utility functions for testing
//

import XCTest
@testable import Septica

/// Provides test data fixtures and helper methods for Romanian Septica testing
struct TestDataFixtures {
    
    // MARK: - Card Fixtures
    
    /// Common cards used in tests
    static let commonCards = CommonCards()
    
    struct CommonCards {
        let sevenHearts = Card(suit: .hearts, value: 7)
        let sevenSpades = Card(suit: .spades, value: 7)
        let sevenClubs = Card(suit: .clubs, value: 7)
        let sevenDiamonds = Card(suit: .diamonds, value: 7)
        
        let eightHearts = Card(suit: .hearts, value: 8)
        let eightSpades = Card(suit: .spades, value: 8)
        let eightClubs = Card(suit: .clubs, value: 8)
        let eightDiamonds = Card(suit: .diamonds, value: 8)
        
        let tenHearts = Card(suit: .hearts, value: 10)
        let tenSpades = Card(suit: .spades, value: 10)
        let tenClubs = Card(suit: .clubs, value: 10)
        let tenDiamonds = Card(suit: .diamonds, value: 10)
        
        let aceHearts = Card(suit: .hearts, value: 14)
        let aceSpades = Card(suit: .spades, value: 14)
        let aceClubs = Card(suit: .clubs, value: 14)
        let aceDiamonds = Card(suit: .diamonds, value: 14)
        
        let jackHearts = Card(suit: .hearts, value: 11)
        let queenSpades = Card(suit: .spades, value: 12)
        let kingClubs = Card(suit: .clubs, value: 13)
        
        let nineHearts = Card(suit: .hearts, value: 9)
        let nineSpades = Card(suit: .spades, value: 9)
        
        /// All four 7s (cutting cards)
        var allSevens: [Card] {
            return [sevenHearts, sevenSpades, sevenClubs, sevenDiamonds]
        }
        
        /// All four 8s (special beating cards)
        var allEights: [Card] {
            return [eightHearts, eightSpades, eightClubs, eightDiamonds]
        }
        
        /// All point cards (10s and Aces)
        var allPointCards: [Card] {
            return [tenHearts, tenSpades, tenClubs, tenDiamonds,
                   aceHearts, aceSpades, aceClubs, aceDiamonds]
        }
        
        /// Non-point cards for testing
        var nonPointCards: [Card] {
            return [sevenHearts, eightSpades, nineHearts, jackHearts, queenSpades, kingClubs]
        }
    }
    
    // MARK: - Hand Fixtures
    
    /// Predefined hands for testing various scenarios
    static let testHands = TestHands()
    
    struct TestHands {
        /// Hand with all 7s (very strong hand)
        let allSevens = [
            Card(suit: .hearts, value: 7),
            Card(suit: .spades, value: 7),
            Card(suit: .clubs, value: 7),
            Card(suit: .diamonds, value: 7)
        ]
        
        /// Hand with mixed strong cards
        let mixedStrong = [
            Card(suit: .hearts, value: 7),   // Cutting card
            Card(suit: .spades, value: 8),   // Special beating card
            Card(suit: .clubs, value: 10),   // Point card
            Card(suit: .diamonds, value: 14) // Point card (Ace)
        ]
        
        /// Hand with no special cards (weak hand)
        let regularCards = [
            Card(suit: .hearts, value: 9),
            Card(suit: .spades, value: 11), // Jack
            Card(suit: .clubs, value: 12),  // Queen
            Card(suit: .diamonds, value: 13) // King
        ]
        
        /// Hand with only point cards
        let allPointCards = [
            Card(suit: .hearts, value: 10),
            Card(suit: .spades, value: 10),
            Card(suit: .clubs, value: 14),  // Ace
            Card(suit: .diamonds, value: 14) // Ace
        ]
        
        /// Hand that can beat specific target cards
        let versatileHand = [
            Card(suit: .hearts, value: 7),   // Can beat anything
            Card(suit: .spades, value: 8),   // Can beat when table % 3 == 0
            Card(suit: .clubs, value: 10),   // Can beat other 10s
            Card(suit: .diamonds, value: 9)  // Regular card
        ]
        
        /// Empty hand for edge case testing
        let empty: [Card] = []
        
        /// Single card hand
        let singleCard = [Card(suit: .hearts, value: 7)]
    }
    
    // MARK: - Game Scenario Fixtures
    
    /// Predefined game scenarios for testing
    static let gameScenarios = GameScenarios()
    
    struct GameScenarios {
        
        /// Scenario: 7 always beats everything
        struct SevenBeatsAll {
            let attackingCard = Card(suit: .hearts, value: 7)
            let targetCards = [
                Card(suit: .spades, value: 8),
                Card(suit: .clubs, value: 10),
                Card(suit: .diamonds, value: 14)
            ]
            let tableCounts = [0, 1, 2, 3, 4, 5, 6, 9, 12]
            
            func shouldAllBeat() -> Bool { return true }
        }
        
        /// Scenario: 8 beats when table count divisible by 3
        struct EightConditionalBeating {
            let attackingCard = Card(suit: .hearts, value: 8)
            let targetCard = Card(suit: .spades, value: 10)
            let divisibleBy3 = [0, 3, 6, 9, 12, 15, 21]
            let notDivisibleBy3 = [1, 2, 4, 5, 7, 8, 10, 11, 13, 14, 16]
            
            func shouldBeatWhenDivisible() -> Bool { return true }
            func shouldNotBeatWhenNotDivisible() -> Bool { return false }
        }
        
        /// Scenario: Same value always beats
        struct SameValueBeats {
            let pairs = [
                (Card(suit: .hearts, value: 10), Card(suit: .spades, value: 10)),
                (Card(suit: .clubs, value: 11), Card(suit: .diamonds, value: 11)),
                (Card(suit: .hearts, value: 14), Card(suit: .spades, value: 14))
            ]
            let tableCounts = [1, 2, 4, 5, 7, 8] // Various counts
            
            func shouldAllBeat() -> Bool { return true }
        }
        
        /// Scenario: Complete trick sequences
        struct TrickSequences {
            
            /// Simple trick: 10 -> 7 (7 wins)
            let simpleTrick = [
                Card(suit: .hearts, value: 10),
                Card(suit: .spades, value: 7)
            ]
            let simpleTrickWinner = 1
            
            /// Complex trick: 10 -> 7 -> 7 -> 8 (last card wins)
            let complexTrick = [
                Card(suit: .hearts, value: 10),  // Index 0
                Card(suit: .spades, value: 7),   // Index 1 - beats 10
                Card(suit: .clubs, value: 7),    // Index 2 - beats previous 7
                Card(suit: .diamonds, value: 8)  // Index 3 - beats when table count = 4 (not divisible by 3, so doesn't beat)
            ]
            let complexTrickWinner = 2 // Last 7 wins
            
            /// All sevens trick
            let allSevensTrick = [
                Card(suit: .hearts, value: 7),
                Card(suit: .spades, value: 7),
                Card(suit: .clubs, value: 7),
                Card(suit: .diamonds, value: 7)
            ]
            let allSevensTrickWinner = 3 // Last 7 wins
        }
    }
    
    // MARK: - Player Fixtures
    
    /// Create test players with predefined configurations
    static func createTestPlayers() -> (Player, Player) {
        let player1 = Player(name: "Test Player 1")
        let player2 = Player(name: "Test Player 2")
        return (player1, player2)
    }
    
    /// Create test players with specific hands
    static func createTestPlayersWithHands(_ hand1: [Card], _ hand2: [Card]) -> (Player, Player) {
        let (player1, player2) = createTestPlayers()
        player1.hand = hand1
        player2.hand = hand2
        return (player1, player2)
    }
    
    // MARK: - Game State Fixtures
    
    /// Create a fresh game state for testing
    static func createTestGameState() -> GameState {
        let (player1, player2) = createTestPlayers()
        return GameState(players: [player1, player2])
    }
    
    /// Create a game state with specific configuration
    static func createTestGameState(withHands hand1: [Card], _ hand2: [Card]) -> GameState {
        let (player1, player2) = createTestPlayersWithHands(hand1, hand2)
        let gameState = GameState(players: [player1, player2])
        return gameState
    }
    
    /// Create a game state mid-game with cards on table
    static func createMidGameState(tableCards: [Card] = [], currentPlayerIndex: Int = 0) -> GameState {
        let gameState = createTestGameState()
        gameState.tableCards = tableCards
        gameState.currentPlayerIndex = currentPlayerIndex
        return gameState
    }
    
    // MARK: - Validation Test Cases
    
    /// Test cases for move validation
    static let validationTestCases = ValidationTestCases()
    
    struct ValidationTestCases {
        
        struct ValidMoveCase {
            let card: Card
            let playerHand: [Card]
            let targetCard: Card?
            let tableCardsCount: Int
            let expectedResult: Bool
            let description: String
        }
        
        let validMoves: [ValidMoveCase] = [
            ValidMoveCase(
                card: Card(suit: .hearts, value: 7),
                playerHand: [Card(suit: .hearts, value: 7)],
                targetCard: Card(suit: .spades, value: 10),
                tableCardsCount: 1,
                expectedResult: true,
                description: "7 should always beat"
            ),
            ValidMoveCase(
                card: Card(suit: .hearts, value: 8),
                playerHand: [Card(suit: .hearts, value: 8)],
                targetCard: Card(suit: .spades, value: 10),
                tableCardsCount: 3,
                expectedResult: true,
                description: "8 should beat when table count divisible by 3"
            ),
            ValidMoveCase(
                card: Card(suit: .hearts, value: 10),
                playerHand: [Card(suit: .hearts, value: 10)],
                targetCard: Card(suit: .spades, value: 10),
                tableCardsCount: 1,
                expectedResult: true,
                description: "Same value should beat"
            ),
            ValidMoveCase(
                card: Card(suit: .hearts, value: 9),
                playerHand: [Card(suit: .hearts, value: 9)],
                targetCard: nil,
                tableCardsCount: 0,
                expectedResult: true,
                description: "Any card should be valid on empty table"
            )
        ]
        
        let invalidMoves: [ValidMoveCase] = [
            ValidMoveCase(
                card: Card(suit: .hearts, value: 9),
                playerHand: [Card(suit: .spades, value: 10)], // Card not in hand
                targetCard: Card(suit: .clubs, value: 12),
                tableCardsCount: 1,
                expectedResult: false,
                description: "Card not in hand should be invalid"
            ),
            ValidMoveCase(
                card: Card(suit: .hearts, value: 9),
                playerHand: [Card(suit: .hearts, value: 9)],
                targetCard: Card(suit: .spades, value: 10),
                tableCardsCount: 1,
                expectedResult: false,
                description: "9 cannot beat 10"
            ),
            ValidMoveCase(
                card: Card(suit: .hearts, value: 8),
                playerHand: [Card(suit: .hearts, value: 8)],
                targetCard: Card(suit: .spades, value: 10),
                tableCardsCount: 1,
                expectedResult: false,
                description: "8 cannot beat when table count not divisible by 3"
            )
        ]
    }
}

// MARK: - Test Helper Extensions

extension XCTestCase {
    
    /// Assert that a card can beat another card under given conditions
    func assertCanBeat(
        _ attackingCard: Card,
        _ targetCard: Card,
        tableCardsCount: Int,
        expected: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let result = GameRules.canBeat(
            attackingCard: attackingCard,
            targetCard: targetCard,
            tableCardsCount: tableCardsCount
        )
        
        XCTAssertEqual(
            result,
            expected,
            "\(attackingCard.displayName) vs \(targetCard.displayName) with \(tableCardsCount) cards should \(expected ? "beat" : "not beat")",
            file: file,
            line: line
        )
    }
    
    /// Assert that a hand has expected number of valid moves
    func assertValidMovesCount(
        hand: [Card],
        against targetCard: Card?,
        tableCardsCount: Int,
        expectedCount: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let validMoves = GameRules.validMoves(
            from: hand,
            against: targetCard,
            tableCardsCount: tableCardsCount
        )
        
        XCTAssertEqual(
            validMoves.count,
            expectedCount,
            "Hand should have \(expectedCount) valid moves against \(targetCard?.displayName ?? "empty table")",
            file: file,
            line: line
        )
    }
    
    /// Assert trick winner is as expected
    func assertTrickWinner(
        tableCards: [Card],
        expectedWinnerIndex: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let winnerIndex = GameRules.determineTrickWinner(tableCards: tableCards)
        
        XCTAssertEqual(
            winnerIndex,
            expectedWinnerIndex,
            "Trick winner should be player at index \(expectedWinnerIndex)",
            file: file,
            line: line
        )
    }
    
    /// Assert that game state is in expected phase
    func assertGamePhase(
        _ gameState: GameState,
        expectedPhase: GamePhase,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(
            gameState.phase,
            expectedPhase,
            "Game should be in \(expectedPhase) phase",
            file: file,
            line: line
        )
    }
    
    /// Assert that points calculation is correct
    func assertPointsCalculation(
        cards: [Card],
        expectedPoints: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let points = GameRules.calculatePoints(from: cards)
        
        XCTAssertEqual(
            points,
            expectedPoints,
            "Cards should be worth \(expectedPoints) points",
            file: file,
            line: line
        )
    }
}

// MARK: - Performance Test Helpers

struct PerformanceTestHelpers {
    
    /// Measure time to execute a block of code
    static func measureTime<T>(operation: () throws -> T) rethrows -> (result: T, timeInterval: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try operation()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        return (result, timeElapsed)
    }
    
    /// Generate large number of cards for stress testing
    static func generateLargeHand(size: Int) -> [Card] {
        var hand: [Card] = []
        let deck = GameRules.createDeck()
        
        for i in 0..<size {
            let card = deck[i % deck.count]
            hand.append(card)
        }
        
        return hand
    }
    
    /// Create stress test scenario with many players (for testing scalability)
    static func createStressTestGameState(handSize: Int = 8) -> GameState {
        let player1 = Player(name: "Stress Test Player 1")
        let player2 = Player(name: "Stress Test Player 2")
        
        player1.hand = Array(generateLargeHand(size: handSize).prefix(handSize))
        player2.hand = Array(generateLargeHand(size: handSize).prefix(handSize))
        
        return GameState(players: [player1, player2])
    }
}

// MARK: - Mock Objects for Testing

/// Mock objects for isolated unit testing
struct TestMocks {
    
    /// Mock player that always returns specific cards
    class MockPlayer: Player {
        private let predefinedCards: [Card]
        private var cardIndex = 0
        
        init(name: String, cards: [Card]) {
            self.predefinedCards = cards
            super.init(name: name)
            self.hand = cards
        }
        
        required init(name: String, id: UUID = UUID()) {
            self.predefinedCards = []
            super.init(name: name, id: id)
        }
        
        func getNextCard() -> Card? {
            guard cardIndex < predefinedCards.count else { return nil }
            let card = predefinedCards[cardIndex]
            cardIndex += 1
            return card
        }
        
        func reset() {
            cardIndex = 0
            hand = predefinedCards
        }
    }
    
    /// Create mock players with predefined behavior
    static func createMockPlayers() -> (MockPlayer, MockPlayer) {
        let player1Cards = TestDataFixtures.testHands.mixedStrong
        let player2Cards = TestDataFixtures.testHands.regularCards
        
        let player1 = MockPlayer(name: "Mock Player 1", cards: player1Cards)
        let player2 = MockPlayer(name: "Mock Player 2", cards: player2Cards)
        
        return (player1, player2)
    }
}