//
//  GameRulesComprehensiveTests.swift
//  SepticaTests
//
//  Comprehensive test suite for Romanian Septica game rules validation
//  Tests 2-player only rules, deck creation, card beating logic, and game flow
//

import XCTest
@testable import Septica

final class GameRulesComprehensiveTests: XCTestCase {
    
    // MARK: - Test Data Setup
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    // MARK: - 1. Deck Creation Tests (32-card Romanian Septica)
    
    func testCreateDeckHas32Cards() {
        let deck = GameRules.createDeck()
        XCTAssertEqual(deck.count, 32, "Romanian Septica deck should have exactly 32 cards")
    }
    
    func testCreateDeckHasCorrectValues() {
        let deck = GameRules.createDeck()
        let expectedValues = [7, 8, 9, 10, 11, 12, 13, 14] // 7-A in Romanian notation
        
        for suit in Suit.allCases {
            for value in expectedValues {
                let cardExists = deck.contains { $0.suit == suit && $0.value == value }
                XCTAssertTrue(cardExists, "Deck should contain \(value) of \(suit)")
            }
        }
    }
    
    func testCreateDeckHasCorrectSuits() {
        let deck = GameRules.createDeck()
        
        for suit in Suit.allCases {
            let cardsInSuit = deck.filter { $0.suit == suit }
            XCTAssertEqual(cardsInSuit.count, 8, "Each suit should have exactly 8 cards")
        }
    }
    
    func testCreateDeckHasCorrectPointCards() {
        let deck = GameRules.createDeck()
        let pointCards = deck.filter { $0.isPointCard }
        
        XCTAssertEqual(pointCards.count, GameRules.totalPointCards)
        XCTAssertEqual(pointCards.count, 8, "Should have 8 point cards (4 tens + 4 aces)")
        
        // Verify all point cards are 10s or Aces
        for card in pointCards {
            XCTAssertTrue(card.value == 10 || card.value == 14, "Point cards should only be 10s or Aces")
        }
    }
    
    func testCreateDeckExcludesLowCards() {
        let deck = GameRules.createDeck()
        let invalidValues = [1, 2, 3, 4, 5, 6] // These shouldn't exist in Romanian Septica
        
        for value in invalidValues {
            let hasInvalidCard = deck.contains { $0.value == value }
            XCTAssertFalse(hasInvalidCard, "Deck should not contain cards with value \(value)")
        }
    }
    
    func testCreateDeckIsShuffled() {
        let deck1 = GameRules.createDeck()
        let deck2 = GameRules.createDeck()
        
        // While technically possible for two shuffled decks to be identical,
        // it's extremely unlikely with 32! permutations
        let ordersMatch = deck1.enumerated().allSatisfy { index, card in
            index < deck2.count && deck2[index].suit == card.suit && deck2[index].value == card.value
        }
        
        XCTAssertFalse(ordersMatch, "Shuffled decks should have different orders (probability of match ~1/32!)")
    }
    
    // MARK: - 2. Card Beating Logic Tests (Romanian Septica Rules)
    
    func testSevenAlwaysBeats() {
        let seven = Card(suit: .hearts, value: 7)
        let testCards = [
            Card(suit: .spades, value: 8),
            Card(suit: .clubs, value: 10),
            Card(suit: .diamonds, value: 11), // Jack
            Card(suit: .hearts, value: 12),   // Queen
            Card(suit: .spades, value: 13),   // King
            Card(suit: .clubs, value: 14)     // Ace
        ]
        
        for card in testCards {
            for tableCount in [0, 1, 2, 3, 4, 5, 6, 9, 12] {
                XCTAssertTrue(
                    GameRules.canBeat(attackingCard: seven, targetCard: card, tableCardsCount: tableCount),
                    "7 should always beat \(card.displayName) with \(tableCount) cards on table"
                )
            }
        }
    }
    
    func testSevenVsSevenFirstWins() {
        let seven1 = Card(suit: .hearts, value: 7)
        let seven2 = Card(suit: .spades, value: 7)
        
        // First seven played should win (same value rule applies)
        XCTAssertTrue(
            GameRules.canBeat(attackingCard: seven2, targetCard: seven1, tableCardsCount: 1),
            "Second seven should beat first seven (same value rule)"
        )
    }
    
    func testEightBeatsWhenTableDivisibleByThree() {
        let eight = Card(suit: .hearts, value: 8)
        let target = Card(suit: .spades, value: 12) // Queen
        
        // Should beat when table count is divisible by 3
        let divisibleBy3 = [0, 3, 6, 9, 12, 15]
        for count in divisibleBy3 {
            XCTAssertTrue(
                GameRules.canBeat(attackingCard: eight, targetCard: target, tableCardsCount: count),
                "8 should beat when table has \(count) cards (divisible by 3)"
            )
        }
        
        // Should NOT beat when table count is NOT divisible by 3
        let notDivisibleBy3 = [1, 2, 4, 5, 7, 8, 10, 11, 13, 14]
        for count in notDivisibleBy3 {
            XCTAssertFalse(
                GameRules.canBeat(attackingCard: eight, targetCard: target, tableCardsCount: count),
                "8 should NOT beat when table has \(count) cards (not divisible by 3)"
            )
        }
    }
    
    func testSameValueAlwaysBeats() {
        let testPairs = [
            (Card(suit: .hearts, value: 8), Card(suit: .spades, value: 8)),
            (Card(suit: .clubs, value: 10), Card(suit: .diamonds, value: 10)),
            (Card(suit: .hearts, value: 11), Card(suit: .spades, value: 11)), // Jacks
            (Card(suit: .clubs, value: 12), Card(suit: .diamonds, value: 12)), // Queens
            (Card(suit: .hearts, value: 13), Card(suit: .spades, value: 13)), // Kings
            (Card(suit: .clubs, value: 14), Card(suit: .diamonds, value: 14))  // Aces
        ]
        
        for (attacking, target) in testPairs {
            for tableCount in [1, 2, 4, 5, 7, 8] { // Various non-special counts
                XCTAssertTrue(
                    GameRules.canBeat(attackingCard: attacking, targetCard: target, tableCardsCount: tableCount),
                    "\(attacking.displayName) should beat \(target.displayName) (same value)"
                )
            }
        }
    }
    
    func testRegularCardsCannotBeat() {
        let testCases = [
            (attacking: Card(suit: .hearts, value: 9), target: Card(suit: .spades, value: 10)),
            (attacking: Card(suit: .clubs, value: 10), target: Card(suit: .diamonds, value: 11)),
            (attacking: Card(suit: .hearts, value: 11), target: Card(suit: .spades, value: 12)),
            (attacking: Card(suit: .clubs, value: 12), target: Card(suit: .diamonds, value: 13)),
            (attacking: Card(suit: .hearts, value: 13), target: Card(suit: .spades, value: 14))
        ]
        
        for (attacking, target) in testCases {
            // Test with table counts that don't trigger 8 special rule
            for tableCount in [1, 2, 4, 5, 7, 8] {
                XCTAssertFalse(
                    GameRules.canBeat(attackingCard: attacking, targetCard: target, tableCardsCount: tableCount),
                    "\(attacking.displayName) should NOT beat \(target.displayName) with \(tableCount) cards"
                )
            }
        }
    }
    
    func testComplexScenarios() {
        // Test: 8 vs 7 when table count is divisible by 3
        let eight = Card(suit: .hearts, value: 8)
        let seven = Card(suit: .spades, value: 7)
        
        // 8 should beat when divisible by 3, but 7 always beats
        XCTAssertTrue(
            GameRules.canBeat(attackingCard: eight, targetCard: seven, tableCardsCount: 3),
            "8 should beat 7 when table count is divisible by 3"
        )
        
        // But 7 should also beat 8
        XCTAssertTrue(
            GameRules.canBeat(attackingCard: seven, targetCard: eight, tableCardsCount: 3),
            "7 should always beat 8 regardless of table count"
        )
    }
    
    // MARK: - 3. Game Flow Tests (2-Player Game Progression)
    
    func testTwoPlayerConstraint() {
        XCTAssertEqual(GameRules.maxPlayers, 2, "Romanian Septica should enforce exactly 2 players")
    }
    
    func testInitialHandSize() {
        XCTAssertEqual(GameRules.initialHandSize, 4, "Each player should start with 4 cards")
    }
    
    func testDealInitialHandsFor2Players() {
        var deck = Deck()
        deck.shuffle()
        let originalDeckSize = deck.count
        
        let hands = GameRules.dealInitialHands(from: &deck)
        
        // Should have exactly 2 hands
        XCTAssertEqual(hands.count, GameRules.maxPlayers)
        XCTAssertEqual(hands.count, 2)
        
        // Each hand should have correct size
        for (index, hand) in hands.enumerated() {
            XCTAssertEqual(hand.count, GameRules.initialHandSize, "Player \(index) should have \(GameRules.initialHandSize) cards")
        }
        
        // Deck should have fewer cards
        let expectedRemainingCards = originalDeckSize - (GameRules.maxPlayers * GameRules.initialHandSize)
        XCTAssertEqual(deck.count, expectedRemainingCards)
        
        // No duplicate cards between hands and remaining deck
        var allCards = hands.flatMap { $0 }
        allCards.append(contentsOf: deck.allCards)
        let uniqueCards = Set(allCards.map { "\($0.suit.rawValue)-\($0.value)" })
        XCTAssertEqual(allCards.count, uniqueCards.count, "No duplicate cards should exist")
    }
    
    func testTrickWinnerDetermination() {
        // Scenario: First player plays 10♥, second player plays 7♠ (beats)
        let tableCards = [
            Card(suit: .hearts, value: 10),  // First card
            Card(suit: .spades, value: 7)    // Beats previous (7 always wins)
        ]
        
        let winnerIndex = GameRules.determineTrickWinner(tableCards: tableCards)
        XCTAssertEqual(winnerIndex, 1, "Second player (index 1) should win with 7")
    }
    
    func testTrickWinnerWithMultipleBeats() {
        // Scenario: 10♥ -> 7♠ -> 7♣ (last 7 wins)
        let tableCards = [
            Card(suit: .hearts, value: 10),  // First card
            Card(suit: .spades, value: 7),   // Beats previous
            Card(suit: .clubs, value: 7)     // Beats previous (same value)
        ]
        
        let winnerIndex = GameRules.determineTrickWinner(tableCards: tableCards)
        XCTAssertEqual(winnerIndex, 2, "Last player (index 2) should win with last 7")
    }
    
    func testPointCalculation() {
        let testCards = [
            Card(suit: .hearts, value: 7),   // Not a point card
            Card(suit: .spades, value: 10),  // Point card
            Card(suit: .clubs, value: 11),   // Not a point card (Jack)
            Card(suit: .diamonds, value: 14) // Point card (Ace)
        ]
        
        let points = GameRules.calculatePoints(from: testCards)
        XCTAssertEqual(points, 2, "Should have 2 points (10 and Ace)")
    }
    
    func testGameCompletionLogic() {
        // Game is complete when all hands are empty AND deck is empty
        let emptyHands = [[], []] as [[Card]]
        
        XCTAssertTrue(
            GameRules.isGameComplete(allPlayerHands: emptyHands, deckEmpty: true),
            "Game should be complete when all hands and deck are empty"
        )
        
        XCTAssertFalse(
            GameRules.isGameComplete(allPlayerHands: emptyHands, deckEmpty: false),
            "Game should NOT be complete when deck still has cards"
        )
        
        let nonEmptyHands = [[Card(suit: .hearts, value: 7)], []] as [[Card]]
        XCTAssertFalse(
            GameRules.isGameComplete(allPlayerHands: nonEmptyHands, deckEmpty: true),
            "Game should NOT be complete when player still has cards"
        )
    }
    
    func testGameWinnerDetermination() {
        // Clear winner
        let scores1 = [3, 5] // Player 1 wins with 5 points
        XCTAssertEqual(GameRules.determineGameWinner(playerScores: scores1), 1)
        
        // Tie scenario
        let scores2 = [4, 4] // Tie
        XCTAssertNil(GameRules.determineGameWinner(playerScores: scores2))
        
        // All zeros (no winner)
        let scores3 = [0, 0]
        XCTAssertNil(GameRules.determineGameWinner(playerScores: scores3))
    }
    
    // MARK: - 4. Edge Case Tests
    
    func testEdgeCaseEmptyTable() {
        let player1Hand = [Card(suit: .hearts, value: 7), Card(suit: .spades, value: 10)]
        
        // All cards should be valid when table is empty
        let validMoves = GameRules.validMoves(from: player1Hand, against: nil, tableCardsCount: 0)
        XCTAssertEqual(validMoves.count, player1Hand.count, "All cards should be valid on empty table")
        
        XCTAssertTrue(
            GameRules.hasValidMove(playerHand: player1Hand, topTableCard: nil, tableCardsCount: 0),
            "Player should have valid moves on empty table"
        )
    }
    
    func testEdgeCaseNoValidMoves() {
        let playerHand = [
            Card(suit: .hearts, value: 9),
            Card(suit: .spades, value: 11)  // Jack
        ]
        let topCard = Card(suit: .clubs, value: 10)
        
        // Neither card can beat 10 (not 7, not 8 with correct table count, not same value)
        XCTAssertFalse(
            GameRules.hasValidMove(playerHand: playerHand, topTableCard: topCard, tableCardsCount: 1),
            "Player should have no valid moves"
        )
        
        let validMoves = GameRules.validMoves(from: playerHand, against: topCard, tableCardsCount: 1)
        XCTAssertTrue(validMoves.isEmpty, "No valid moves should be available")
    }
    
    func testEdgeCaseMultipleSpecialCards() {
        let playerHand = [
            Card(suit: .hearts, value: 7),   // Always beats
            Card(suit: .spades, value: 8),   // Beats if table % 3 == 0
            Card(suit: .clubs, value: 10)    // Beats if same value
        ]
        let topCard = Card(suit: .diamonds, value: 10)
        
        // Test with table count divisible by 3
        let validMoves = GameRules.validMoves(from: playerHand, against: topCard, tableCardsCount: 3)
        XCTAssertEqual(validMoves.count, 3, "All three cards should be valid: 7 (always), 8 (table%3==0), 10 (same value)")
        
        // Test with table count NOT divisible by 3
        let validMoves2 = GameRules.validMoves(from: playerHand, against: topCard, tableCardsCount: 1)
        XCTAssertEqual(validMoves2.count, 2, "Two cards should be valid: 7 (always), 10 (same value)")
    }
    
    func testEdgeCaseMaxTableCards() {
        // Test with many cards on table (simulate long trick)
        let eight = Card(suit: .hearts, value: 8)
        let target = Card(suit: .spades, value: 10)
        
        // Large numbers divisible by 3
        for count in [21, 24, 27, 30] {
            XCTAssertTrue(
                GameRules.canBeat(attackingCard: eight, targetCard: target, tableCardsCount: count),
                "8 should beat with \(count) cards on table"
            )
        }
        
        // Large numbers NOT divisible by 3
        for count in [22, 23, 25, 26, 28, 29, 31] {
            XCTAssertFalse(
                GameRules.canBeat(attackingCard: eight, targetCard: target, tableCardsCount: count),
                "8 should NOT beat with \(count) cards on table"
            )
        }
    }
    
    // MARK: - 5. Move Validation Tests
    
    func testMoveValidationSuccess() {
        let card = Card(suit: .hearts, value: 7)
        let playerHand = [card, Card(suit: .spades, value: 10)]
        let topCard = Card(suit: .clubs, value: 12)
        
        let result = GameRules.validateMove(
            card: card,
            from: playerHand,
            against: topCard,
            tableCardsCount: 1
        )
        
        switch result {
        case .valid:
            XCTAssertTrue(true, "Move should be valid")
        case .invalid:
            XCTFail("Move should be valid - 7 always beats")
        }
    }
    
    func testMoveValidationCardNotInHand() {
        let card = Card(suit: .hearts, value: 7)
        let playerHand = [Card(suit: .spades, value: 10)]  // Doesn't contain the 7
        let topCard = Card(suit: .clubs, value: 12)
        
        let result = GameRules.validateMove(
            card: card,
            from: playerHand,
            against: topCard,
            tableCardsCount: 1
        )
        
        switch result {
        case .valid:
            XCTFail("Move should be invalid - card not in hand")
        case .invalid(let error):
            XCTAssertEqual(error, .cardNotInHand)
        }
    }
    
    func testMoveValidationCannotBeat() {
        let card = Card(suit: .hearts, value: 9)
        let playerHand = [card, Card(suit: .spades, value: 10)]
        let topCard = Card(suit: .clubs, value: 12)
        
        let result = GameRules.validateMove(
            card: card,
            from: playerHand,
            against: topCard,
            tableCardsCount: 1
        )
        
        switch result {
        case .valid:
            XCTFail("Move should be invalid - 9 cannot beat 12")
        case .invalid(let error):
            XCTAssertEqual(error, .cannotBeatTopCard)
        }
    }
    
    func testMoveValidationEmptyTable() {
        let card = Card(suit: .hearts, value: 9)
        let playerHand = [card]
        
        let result = GameRules.validateMove(
            card: card,
            from: playerHand,
            against: nil,
            tableCardsCount: 0
        )
        
        switch result {
        case .valid:
            XCTAssertTrue(true, "Any card should be valid on empty table")
        case .invalid:
            XCTFail("Move should be valid on empty table")
        }
    }
    
    // MARK: - 6. Card Strength Analysis Tests
    
    func testCardStrengthAnalysis() {
        // 7 should always be very strong
        let seven = Card(suit: .hearts, value: 7)
        XCTAssertEqual(
            GameRules.analyzeCardStrength(card: seven, tableCardsCount: 1),
            .veryStrong,
            "7 should always be very strong"
        )
        
        // 8 should be strong when table % 3 == 0
        let eight = Card(suit: .spades, value: 8)
        XCTAssertEqual(
            GameRules.analyzeCardStrength(card: eight, tableCardsCount: 3),
            .strong,
            "8 should be strong when table count divisible by 3"
        )
        
        XCTAssertEqual(
            GameRules.analyzeCardStrength(card: eight, tableCardsCount: 1),
            .normal,
            "8 should be normal when table count not divisible by 3"
        )
        
        // Point cards should be valuable
        let ten = Card(suit: .clubs, value: 10)
        XCTAssertEqual(
            GameRules.analyzeCardStrength(card: ten, tableCardsCount: 1),
            .valuable,
            "10 should be valuable (point card)"
        )
        
        let ace = Card(suit: .diamonds, value: 14)
        XCTAssertEqual(
            GameRules.analyzeCardStrength(card: ace, tableCardsCount: 2),
            .valuable,
            "Ace should be valuable (point card)"
        )
        
        // Regular cards should be normal
        let jack = Card(suit: .hearts, value: 11)
        XCTAssertEqual(
            GameRules.analyzeCardStrength(card: jack, tableCardsCount: 4),
            .normal,
            "Jack should be normal"
        )
    }
    
    // MARK: - 7. Beat Explanation Tests
    
    func testBeatExplanations() {
        let seven = Card(suit: .hearts, value: 7)
        let eight = Card(suit: .spades, value: 8)
        let ten1 = Card(suit: .clubs, value: 10)
        let ten2 = Card(suit: .diamonds, value: 10)
        let nine = Card(suit: .hearts, value: 9)
        let jack = Card(suit: .spades, value: 11)
        
        // 7 always beats
        let explanation1 = GameRules.beatExplanation(attackingCard: seven, targetCard: jack, tableCardsCount: 1)
        XCTAssertEqual(explanation1, "7 always beats (wild card)")
        
        // 8 beats when divisible by 3
        let explanation2 = GameRules.beatExplanation(attackingCard: eight, targetCard: nine, tableCardsCount: 3)
        XCTAssertEqual(explanation2, "8 beats when table has 3 cards (divisible by 3)")
        
        // Same value beats
        let explanation3 = GameRules.beatExplanation(attackingCard: ten1, targetCard: ten2, tableCardsCount: 1)
        XCTAssertEqual(explanation3, "Same value beats (10 beats 10)")
        
        // Cannot beat
        let explanation4 = GameRules.beatExplanation(attackingCard: nine, targetCard: jack, tableCardsCount: 1)
        XCTAssertNil(explanation4, "Should return nil when card cannot beat")
    }
    
    // MARK: - 8. Constants Validation
    
    func testGameConstants() {
        XCTAssertEqual(GameRules.initialHandSize, 4, "Initial hand size should be 4")
        XCTAssertEqual(GameRules.maxPlayers, 2, "Max players should be 2 for Romanian Septica")
        XCTAssertEqual(GameRules.totalPointCards, 8, "Total point cards should be 8 (4 tens + 4 aces)")
        XCTAssertEqual(GameRules.totalPoints, 8, "Total points available should be 8")
    }
    
    func testCuttingCardIdentification() {
        // Only 7s should be cutting cards
        XCTAssertTrue(GameRules.isCuttingCard(Card(suit: .hearts, value: 7)))
        XCTAssertTrue(GameRules.isCuttingCard(Card(suit: .spades, value: 7)))
        XCTAssertTrue(GameRules.isCuttingCard(Card(suit: .clubs, value: 7)))
        XCTAssertTrue(GameRules.isCuttingCard(Card(suit: .diamonds, value: 7)))
        
        // No other cards should be cutting cards
        for value in [8, 9, 10, 11, 12, 13, 14] {
            XCTAssertFalse(GameRules.isCuttingCard(Card(suit: .hearts, value: value)),
                          "Card with value \(value) should not be a cutting card")
        }
    }
}