//
//  GameRulesTests.swift
//  SepticaTests
//
//  Unit tests for Septica game rules engine
//  Tests game logic, validation, and scoring
//

import XCTest
@testable import Septica

final class GameRulesTests: XCTestCase {
    
    // MARK: - Card Beating Tests
    
    func testCanBeatWithSeven() {
        let seven = Card(suit: .hearts, value: 7)
        let king = Card(suit: .spades, value: 13)
        
        // 7 should always beat any card
        XCTAssertTrue(GameRules.canBeat(attackingCard: seven, targetCard: king, tableCardsCount: 0))
        XCTAssertTrue(GameRules.canBeat(attackingCard: seven, targetCard: king, tableCardsCount: 1))
        XCTAssertTrue(GameRules.canBeat(attackingCard: seven, targetCard: king, tableCardsCount: 3))
        XCTAssertTrue(GameRules.canBeat(attackingCard: seven, targetCard: king, tableCardsCount: 6))
    }
    
    func testCanBeatWithEight() {
        let eight = Card(suit: .hearts, value: 8)
        let queen = Card(suit: .spades, value: 12)
        
        // 8 should beat when table count is divisible by 3
        XCTAssertTrue(GameRules.canBeat(attackingCard: eight, targetCard: queen, tableCardsCount: 0))
        XCTAssertTrue(GameRules.canBeat(attackingCard: eight, targetCard: queen, tableCardsCount: 3))
        XCTAssertTrue(GameRules.canBeat(attackingCard: eight, targetCard: queen, tableCardsCount: 6))
        XCTAssertTrue(GameRules.canBeat(attackingCard: eight, targetCard: queen, tableCardsCount: 9))
        
        // 8 should not beat when table count is not divisible by 3
        XCTAssertFalse(GameRules.canBeat(attackingCard: eight, targetCard: queen, tableCardsCount: 1))
        XCTAssertFalse(GameRules.canBeat(attackingCard: eight, targetCard: queen, tableCardsCount: 2))
        XCTAssertFalse(GameRules.canBeat(attackingCard: eight, targetCard: queen, tableCardsCount: 4))
        XCTAssertFalse(GameRules.canBeat(attackingCard: eight, targetCard: queen, tableCardsCount: 5))
    }
    
    func testCanBeatWithSameValue() {
        let ten1 = Card(suit: .hearts, value: 10)
        let ten2 = Card(suit: .spades, value: 10)
        let ace1 = Card(suit: .clubs, value: 14)
        let ace2 = Card(suit: .diamonds, value: 14)
        
        // Same values should beat each other
        XCTAssertTrue(GameRules.canBeat(attackingCard: ten1, targetCard: ten2, tableCardsCount: 1))
        XCTAssertTrue(GameRules.canBeat(attackingCard: ace1, targetCard: ace2, tableCardsCount: 5))
    }
    
    func testCannotBeatWithRegularCards() {
        let nine = Card(suit: .hearts, value: 9)
        let jack = Card(suit: .spades, value: 11)
        let queen = Card(suit: .clubs, value: 12)
        
        // Different values should not beat each other (unless 7 or 8 with special rule)
        XCTAssertFalse(GameRules.canBeat(attackingCard: nine, targetCard: jack, tableCardsCount: 1))
        XCTAssertFalse(GameRules.canBeat(attackingCard: jack, targetCard: queen, tableCardsCount: 2))
        XCTAssertFalse(GameRules.canBeat(attackingCard: queen, targetCard: nine, tableCardsCount: 4))
    }
    
    // MARK: - Valid Moves Tests
    
    func testValidMovesWithNoTableCard() {
        let hand = [
            Card(suit: .hearts, value: 7),
            Card(suit: .spades, value: 10),
            Card(suit: .clubs, value: 14)
        ]
        
        // When no card is on table, all cards are valid
        let validMoves = GameRules.validMoves(from: hand, against: nil, tableCardsCount: 0)
        XCTAssertEqual(validMoves.count, 3)
        XCTAssertTrue(validMoves.contains { $0.value == 7 && $0.suit == .hearts })
        XCTAssertTrue(validMoves.contains { $0.value == 10 && $0.suit == .spades })
        XCTAssertTrue(validMoves.contains { $0.value == 14 && $0.suit == .clubs })
    }
    
    func testValidMovesWithTableCard() {
        let hand = [
            Card(suit: .hearts, value: 7),    // Can beat (wild)
            Card(suit: .spades, value: 8),    // Cannot beat (table count not divisible by 3)
            Card(suit: .clubs, value: 10),    // Can beat (same value)
            Card(suit: .diamonds, value: 11)  // Cannot beat
        ]
        let tableCard = Card(suit: .hearts, value: 10)
        
        let validMoves = GameRules.validMoves(from: hand, against: tableCard, tableCardsCount: 1)
        XCTAssertEqual(validMoves.count, 2)
        XCTAssertTrue(validMoves.contains { $0.value == 7 }) // Wild card
        XCTAssertTrue(validMoves.contains { $0.value == 10 }) // Same value
    }
    
    func testValidMovesWithEightWhenTableDivisibleByThree() {
        let hand = [
            Card(suit: .hearts, value: 7),    // Can beat (wild)
            Card(suit: .spades, value: 8),    // Can beat (table count divisible by 3)
            Card(suit: .clubs, value: 9),     // Cannot beat
            Card(suit: .diamonds, value: 12)  // Can beat (same value)
        ]
        let tableCard = Card(suit: .hearts, value: 12)
        
        let validMoves = GameRules.validMoves(from: hand, against: tableCard, tableCardsCount: 3)
        XCTAssertEqual(validMoves.count, 3)
        XCTAssertTrue(validMoves.contains { $0.value == 7 })  // Wild card
        XCTAssertTrue(validMoves.contains { $0.value == 8 })  // 8 beats when count % 3 == 0
        XCTAssertTrue(validMoves.contains { $0.value == 12 }) // Same value
    }
    
    // MARK: - Has Valid Move Tests
    
    func testHasValidMoveWithValidCards() {
        let hand = [
            Card(suit: .hearts, value: 9),
            Card(suit: .spades, value: 7)  // Wild card
        ]
        let tableCard = Card(suit: .clubs, value: 10)
        
        XCTAssertTrue(GameRules.hasValidMove(playerHand: hand, topTableCard: tableCard, tableCardsCount: 1))
    }
    
    func testHasValidMoveWithoutValidCards() {
        let hand = [
            Card(suit: .hearts, value: 9),
            Card(suit: .spades, value: 11)
        ]
        let tableCard = Card(suit: .clubs, value: 10)
        
        XCTAssertFalse(GameRules.hasValidMove(playerHand: hand, topTableCard: tableCard, tableCardsCount: 1))
    }
    
    func testHasValidMoveWithEmptyHand() {
        let hand: [Card] = []
        let tableCard = Card(suit: .clubs, value: 10)
        
        XCTAssertFalse(GameRules.hasValidMove(playerHand: hand, topTableCard: tableCard, tableCardsCount: 1))
    }
    
    // MARK: - Point Calculation Tests
    
    func testCalculatePointsFromCards() {
        let cards = [
            Card(suit: .hearts, value: 7),    // Not a point card
            Card(suit: .spades, value: 10),   // Point card (1 point)
            Card(suit: .clubs, value: 14),    // Point card (1 point)
            Card(suit: .diamonds, value: 11)  // Not a point card
        ]
        
        let points = GameRules.calculatePoints(from: cards)
        XCTAssertEqual(points, 2) // Only 10 and Ace count as points
    }
    
    func testCalculatePointsFromEmptyCards() {
        let cards: [Card] = []
        let points = GameRules.calculatePoints(from: cards)
        XCTAssertEqual(points, 0)
    }
    
    func testCalculatePointsFromNonPointCards() {
        let cards = [
            Card(suit: .hearts, value: 7),
            Card(suit: .spades, value: 8),
            Card(suit: .clubs, value: 9),
            Card(suit: .diamonds, value: 11)
        ]
        
        let points = GameRules.calculatePoints(from: cards)
        XCTAssertEqual(points, 0)
    }
    
    // MARK: - Trick Logic Tests
    
    func testDetermineTrickWinner() {
        let tableCards = [
            Card(suit: .hearts, value: 10),   // First card
            Card(suit: .spades, value: 7),    // Beats previous
            Card(suit: .clubs, value: 14)     // Beats previous (last card wins)
        ]
        
        let winnerIndex = GameRules.determineTrickWinner(tableCards: tableCards)
        XCTAssertEqual(winnerIndex, 2) // Last card played wins
    }
    
    func testDetermineTrickWinnerEmptyCards() {
        let tableCards: [Card] = []
        let winnerIndex = GameRules.determineTrickWinner(tableCards: tableCards)
        XCTAssertEqual(winnerIndex, 0)
    }
    
    // MARK: - Game Completion Tests
    
    func testIsGameCompleteWhenAllHandsEmpty() {
        let allPlayerHands: [[Card]] = [[], []]
        let deckEmpty = true
        
        XCTAssertTrue(GameRules.isGameComplete(allPlayerHands: allPlayerHands, deckEmpty: deckEmpty))
    }
    
    func testIsGameNotCompleteWhenHandsHaveCards() {
        let allPlayerHands = [
            [Card(suit: .hearts, value: 7)],
            []
        ]
        let deckEmpty = true
        
        XCTAssertFalse(GameRules.isGameComplete(allPlayerHands: allPlayerHands, deckEmpty: deckEmpty))
    }
    
    func testIsGameNotCompleteWhenDeckNotEmpty() {
        let allPlayerHands: [[Card]] = [[], []]
        let deckEmpty = false
        
        XCTAssertFalse(GameRules.isGameComplete(allPlayerHands: allPlayerHands, deckEmpty: deckEmpty))
    }
    
    // MARK: - Game Winner Tests
    
    func testDetermineGameWinnerClearWinner() {
        let playerScores = [3, 5, 2] // Player 1 wins with 5 points
        let winnerIndex = GameRules.determineGameWinner(playerScores: playerScores)
        XCTAssertEqual(winnerIndex, 1)
    }
    
    func testDetermineGameWinnerTie() {
        let playerScores = [3, 3, 2] // Tie between players 0 and 1
        let winnerIndex = GameRules.determineGameWinner(playerScores: playerScores)
        XCTAssertNil(winnerIndex) // No clear winner in tie
    }
    
    func testDetermineGameWinnerAllZeros() {
        let playerScores = [0, 0, 0]
        let winnerIndex = GameRules.determineGameWinner(playerScores: playerScores)
        XCTAssertNil(winnerIndex) // No winner when all scores are 0
    }
    
    // MARK: - Move Validation Tests
    
    func testValidateMoveSuccess() {
        let card = Card(suit: .hearts, value: 7)
        let playerHand = [card, Card(suit: .spades, value: 10)]
        let tableCard = Card(suit: .clubs, value: 12)
        
        let result = GameRules.validateMove(
            card: card,
            from: playerHand,
            against: tableCard,
            tableCardsCount: 1
        )
        
        switch result {
        case .valid:
            XCTAssertTrue(true) // Test passes
        case .invalid:
            XCTFail("Move should be valid")
        }
    }
    
    func testValidateMoveCardNotInHand() {
        let card = Card(suit: .hearts, value: 7)
        let playerHand = [Card(suit: .spades, value: 10)]
        let tableCard = Card(suit: .clubs, value: 12)
        
        let result = GameRules.validateMove(
            card: card,
            from: playerHand,
            against: tableCard,
            tableCardsCount: 1
        )
        
        switch result {
        case .valid:
            XCTFail("Move should be invalid - card not in hand")
        case .invalid(let error):
            XCTAssertEqual(error, .cardNotInHand)
        }
    }
    
    func testValidateMoveCannotBeat() {
        let card = Card(suit: .hearts, value: 9)
        let playerHand = [card, Card(suit: .spades, value: 10)]
        let tableCard = Card(suit: .clubs, value: 12)
        
        let result = GameRules.validateMove(
            card: card,
            from: playerHand,
            against: tableCard,
            tableCardsCount: 1
        )
        
        switch result {
        case .valid:
            XCTFail("Move should be invalid - cannot beat top card")
        case .invalid(let error):
            XCTAssertEqual(error, .cannotBeatTopCard)
        }
    }
    
    // MARK: - Constants Tests
    
    func testGameConstants() {
        XCTAssertEqual(GameRules.initialHandSize, 4)
        XCTAssertEqual(GameRules.maxPlayers, 2)
        XCTAssertEqual(GameRules.totalPointCards, 8) // 4 tens + 4 aces
        XCTAssertEqual(GameRules.totalPoints, 8)
    }
    
    // MARK: - Deal Initial Hands Tests
    
    func testDealInitialHands() {
        var deck = Deck()
        deck.shuffle()
        let playerCount = 2
        
        let hands = GameRules.dealInitialHands(from: &deck, playerCount: playerCount)
        
        // Should have hands for each player
        XCTAssertEqual(hands.count, playerCount)
        
        // Each hand should have the correct number of cards
        for hand in hands {
            XCTAssertEqual(hand.count, GameRules.initialHandSize)
        }
        
        // Deck should have fewer cards
        let expectedDeckCount = 32 - (playerCount * GameRules.initialHandSize)
        XCTAssertEqual(deck.count, expectedDeckCount)
    }
}