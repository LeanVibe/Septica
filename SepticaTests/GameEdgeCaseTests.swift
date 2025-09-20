//
//  GameEdgeCaseTests.swift
//  SepticaTests
//
//  Edge case and stress tests for Romanian Septica game logic
//  Tests unusual scenarios, boundary conditions, and error cases
//

import XCTest
@testable import Septica

final class GameEdgeCaseTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Setup for edge case testing
    }
    
    override func tearDownWithError() throws {
        // Cleanup after edge case testing
    }
    
    // MARK: - 1. Multiple 7s Scenarios
    
    func testMultipleSevensBattling() {
        let sevens = [
            Card(suit: .hearts, value: 7),
            Card(suit: .spades, value: 7),
            Card(suit: .clubs, value: 7),
            Card(suit: .diamonds, value: 7)
        ]
        
        // Test all 7s beating each other
        for i in 0..<sevens.count {
            for j in 0..<sevens.count {
                if i != j {
                    XCTAssertTrue(
                        GameRules.canBeat(
                            attackingCard: sevens[i],
                            targetCard: sevens[j],
                            tableCardsCount: 1
                        ),
                        "7 of \(sevens[i].suit) should beat 7 of \(sevens[j].suit) (same value rule)"
                    )
                }
            }
        }
    }
    
    func testTrickWithAllSevens() {
        let tableCards = [
            Card(suit: .hearts, value: 7),   // First 7
            Card(suit: .spades, value: 7),   // Beats first (same value)
            Card(suit: .clubs, value: 7),    // Beats second (same value)
            Card(suit: .diamonds, value: 7)  // Beats third (same value)
        ]
        
        // Last played card should win
        let winnerIndex = GameRules.determineTrickWinner(tableCards: tableCards)
        XCTAssertEqual(winnerIndex, 3, "Last 7 played should win the trick")
    }
    
    func testAllSevensInHand() {
        let allSevens = [
            Card(suit: .hearts, value: 7),
            Card(suit: .spades, value: 7),
            Card(suit: .clubs, value: 7),
            Card(suit: .diamonds, value: 7)
        ]
        let targetCard = Card(suit: .hearts, value: 10)
        
        let validMoves = GameRules.validMoves(
            from: allSevens,
            against: targetCard,
            tableCardsCount: 1
        )
        
        XCTAssertEqual(validMoves.count, 4, "All 7s should be valid moves")
        
        // All should be able to beat the target
        for seven in allSevens {
            XCTAssertTrue(
                GameRules.canBeat(attackingCard: seven, targetCard: targetCard, tableCardsCount: 1),
                "Every 7 should beat the 10"
            )
        }
    }
    
    // MARK: - 2. 8s with Various Table States
    
    func testEightsWithExtremeTableCounts() {
        let eight = Card(suit: .hearts, value: 8)
        let target = Card(suit: .spades, value: 10)
        
        // Test very large numbers divisible by 3
        let largeDivisibleBy3 = [99, 300, 999, 3000]
        for count in largeDivisibleBy3 {
            XCTAssertTrue(
                GameRules.canBeat(attackingCard: eight, targetCard: target, tableCardsCount: count),
                "8 should beat with \(count) cards on table (divisible by 3)"
            )
        }
        
        // Test very large numbers NOT divisible by 3
        let largeNotDivisibleBy3 = [100, 301, 1000, 3001]
        for count in largeNotDivisibleBy3 {
            XCTAssertFalse(
                GameRules.canBeat(attackingCard: eight, targetCard: target, tableCardsCount: count),
                "8 should NOT beat with \(count) cards on table (not divisible by 3)"
            )
        }
    }
    
    func testEightVsEightScenarios() {
        let eight1 = Card(suit: .hearts, value: 8)
        let eight2 = Card(suit: .spades, value: 8)
        
        // 8 vs 8 when table count divisible by 3
        XCTAssertTrue(
            GameRules.canBeat(attackingCard: eight2, targetCard: eight1, tableCardsCount: 3),
            "Second 8 should beat first 8 when table divisible by 3 (both special rule + same value)"
        )
        
        // 8 vs 8 when table count NOT divisible by 3 (only same value applies)
        XCTAssertTrue(
            GameRules.canBeat(attackingCard: eight2, targetCard: eight1, tableCardsCount: 1),
            "Second 8 should beat first 8 via same value rule"
        )
    }
    
    func testEightVsSeven() {
        let eight = Card(suit: .hearts, value: 8)
        let seven = Card(suit: .spades, value: 7)
        
        // 8 vs 7 when table divisible by 3
        XCTAssertTrue(
            GameRules.canBeat(attackingCard: eight, targetCard: seven, tableCardsCount: 3),
            "8 should beat 7 when table count divisible by 3"
        )
        
        // 7 vs 8 (7 always wins)
        XCTAssertTrue(
            GameRules.canBeat(attackingCard: seven, targetCard: eight, tableCardsCount: 3),
            "7 should always beat 8 regardless of table count"
        )
        
        // 8 vs 7 when table NOT divisible by 3
        XCTAssertFalse(
            GameRules.canBeat(attackingCard: eight, targetCard: seven, tableCardsCount: 1),
            "8 should NOT beat 7 when table count not divisible by 3"
        )
    }
    
    // MARK: - 3. Boundary Value Tests
    
    func testZeroTableCards() {
        let cards = [
            Card(suit: .hearts, value: 7),
            Card(suit: .spades, value: 8),
            Card(suit: .clubs, value: 10)
        ]
        let target = Card(suit: .diamonds, value: 12)
        
        for card in cards {
            // With 0 table cards, 8 should beat (0 % 3 == 0)
            let expected = card.value == 7 || card.value == 8 || card.value == target.value
            XCTAssertEqual(
                GameRules.canBeat(attackingCard: card, targetCard: target, tableCardsCount: 0),
                expected,
                "Card \(card.displayName) vs \(target.displayName) with 0 table cards"
            )
        }
    }
    
    func testSingleCardOnTable() {
        let hand = [Card(suit: .hearts, value: 9)]
        let target = Card(suit: .spades, value: 10)
        
        XCTAssertFalse(
            GameRules.hasValidMove(playerHand: hand, topTableCard: target, tableCardsCount: 1),
            "9 should not be able to beat 10 with 1 card on table"
        )
        
        let validMoves = GameRules.validMoves(from: hand, against: target, tableCardsCount: 1)
        XCTAssertTrue(validMoves.isEmpty, "No valid moves should be available")
    }
    
    func testMaxCardValue() {
        let ace = Card(suit: .hearts, value: 14) // Highest value
        let otherCards = [
            Card(suit: .spades, value: 7),   // Should beat
            Card(suit: .clubs, value: 8),    // Should not beat (1 % 3 != 0)
            Card(suit: .diamonds, value: 14) // Should beat (same value)
        ]
        
        XCTAssertTrue(GameRules.canBeat(attackingCard: otherCards[0], targetCard: ace, tableCardsCount: 1))
        XCTAssertFalse(GameRules.canBeat(attackingCard: otherCards[1], targetCard: ace, tableCardsCount: 1))
        XCTAssertTrue(GameRules.canBeat(attackingCard: otherCards[2], targetCard: ace, tableCardsCount: 1))
    }
    
    func testMinCardValue() {
        let seven = Card(suit: .hearts, value: 7) // Lowest value in Romanian Septica
        let otherCards = [
            Card(suit: .spades, value: 8),
            Card(suit: .clubs, value: 10),
            Card(suit: .diamonds, value: 14)
        ]
        
        // 7 should beat all other cards
        for card in otherCards {
            XCTAssertTrue(
                GameRules.canBeat(attackingCard: seven, targetCard: card, tableCardsCount: 1),
                "7 should beat \(card.displayName)"
            )
        }
    }
    
    // MARK: - 4. Empty and Full Hand Scenarios
    
    func testEmptyHandEdgeCases() {
        let emptyHand: [Card] = []
        let target = Card(suit: .hearts, value: 10)
        
        XCTAssertFalse(
            GameRules.hasValidMove(playerHand: emptyHand, topTableCard: target, tableCardsCount: 1),
            "Empty hand should have no valid moves"
        )
        
        let validMoves = GameRules.validMoves(from: emptyHand, against: target, tableCardsCount: 1)
        XCTAssertTrue(validMoves.isEmpty, "Empty hand should return empty valid moves")
        
        // Empty hand on empty table
        XCTAssertFalse(
            GameRules.hasValidMove(playerHand: emptyHand, topTableCard: nil, tableCardsCount: 0),
            "Empty hand should have no valid moves even on empty table"
        )
    }
    
    func testFullDeckAsHand() {
        let fullDeck = GameRules.createDeck()
        let target = Card(suit: .hearts, value: 10)
        
        // Should definitely have valid moves with full deck
        XCTAssertTrue(
            GameRules.hasValidMove(playerHand: fullDeck, topTableCard: target, tableCardsCount: 1),
            "Full deck should have valid moves"
        )
        
        let validMoves = GameRules.validMoves(from: fullDeck, against: target, tableCardsCount: 1)
        XCTAssertGreaterThan(validMoves.count, 0, "Full deck should have multiple valid moves")
        
        // Should include all 7s
        let sevensInValidMoves = validMoves.filter { $0.value == 7 }
        XCTAssertEqual(sevensInValidMoves.count, 4, "All four 7s should be valid")
    }
    
    // MARK: - 5. Game State Edge Cases
    
    func testGameWithNoPointCards() {
        // Create a scenario where no point cards are played
        let nonPointCards = [
            Card(suit: .hearts, value: 7),
            Card(suit: .spades, value: 8),
            Card(suit: .clubs, value: 9),
            Card(suit: .diamonds, value: 11)
        ]
        
        let points = GameRules.calculatePoints(from: nonPointCards)
        XCTAssertEqual(points, 0, "Should be 0 points when no 10s or Aces")
        
        // Game winner should be nil when all scores are 0
        let scores = [0, 0]
        XCTAssertNil(GameRules.determineGameWinner(playerScores: scores), "No winner when all scores are 0")
    }
    
    func testGameWithAllPointCards() {
        // Scenario where one player gets all point cards
        let allPointCards = [
            Card(suit: .hearts, value: 10),
            Card(suit: .spades, value: 10),
            Card(suit: .clubs, value: 10),
            Card(suit: .diamonds, value: 10),
            Card(suit: .hearts, value: 14),
            Card(suit: .spades, value: 14),
            Card(suit: .clubs, value: 14),
            Card(suit: .diamonds, value: 14)
        ]
        
        let points = GameRules.calculatePoints(from: allPointCards)
        XCTAssertEqual(points, 8, "Should be 8 points (all point cards)")
        
        let scores = [8, 0]
        XCTAssertEqual(GameRules.determineGameWinner(playerScores: scores), 0, "Player with all points should win")
    }
    
    func testGameStateWithEmptyDeckAndHands() {
        let player1 = Player(name: "Player 1")
        let player2 = Player(name: "Player 2")
        let gameState = GameState(players: [player1, player2])
        
        // Empty everything
        player1.hand.removeAll()
        player2.hand.removeAll()
        gameState.deck = Deck(cards: [])
        
        XCTAssertTrue(gameState.isGameComplete, "Game should be complete")
        XCTAssertFalse(gameState.currentPlayerCanMove(), "No player should be able to move")
        XCTAssertTrue(gameState.validMovesForCurrentPlayer().isEmpty, "No valid moves available")
    }
    
    // MARK: - 6. Trick Completion Edge Cases
    
    func testSingleCardTrick() {
        let tableCards = [Card(suit: .hearts, value: 10)]
        
        let winnerIndex = GameRules.determineTrickWinner(tableCards: tableCards)
        XCTAssertEqual(winnerIndex, 0, "Single card trick should be won by that card")
    }
    
    func testEmptyTableTrick() {
        let tableCards: [Card] = []
        
        let winnerIndex = GameRules.determineTrickWinner(tableCards: tableCards)
        XCTAssertEqual(winnerIndex, 0, "Empty table should return index 0")
    }
    
    func testLongTrickWithMultipleBeats() {
        // Simulate a very long trick (shouldn't happen in normal 2-player game)
        let tableCards = [
            Card(suit: .hearts, value: 10),   // Initial card
            Card(suit: .spades, value: 7),    // Beats (7 always wins)
            Card(suit: .clubs, value: 7),     // Beats previous 7
            Card(suit: .diamonds, value: 7),  // Beats previous 7
            Card(suit: .hearts, value: 7)     // Beats previous 7 (but impossible since only 4 sevens exist)
        ]
        
        // Last 7 should win
        let winnerIndex = GameRules.determineTrickWinner(tableCards: tableCards.prefix(4).map { $0 })
        XCTAssertEqual(winnerIndex, 3, "Last 7 should win")
    }
    
    // MARK: - 7. Card Validation Edge Cases
    
    func testValidationWithIdenticalCards() {
        // Create two identical cards (same suit and value, different objects)
        let card1 = Card(suit: .hearts, value: 7)
        let card2 = Card(suit: .hearts, value: 7)
        let playerHand = [card1]
        
        // Should succeed with the actual card in hand
        let result1 = GameRules.validateMove(
            card: card1,
            from: playerHand,
            against: nil,
            tableCardsCount: 0
        )
        
        switch result1 {
        case .valid:
            XCTAssertTrue(true, "Should succeed with card in hand")
        case .invalid:
            XCTFail("Should succeed with card in hand")
        }
        
        // Should also succeed with identical card (same suit/value)
        let result2 = GameRules.validateMove(
            card: card2,
            from: playerHand,
            against: nil,
            tableCardsCount: 0
        )
        
        switch result2 {
        case .valid:
            XCTAssertTrue(true, "Should succeed with identical card")
        case .invalid:
            XCTFail("Should succeed with identical card (same suit and value)")
        }
    }
    
    func testValidationWithComplexHand() {
        let complexHand = [
            Card(suit: .hearts, value: 7),
            Card(suit: .hearts, value: 8),
            Card(suit: .hearts, value: 10),
            Card(suit: .spades, value: 7),
            Card(suit: .spades, value: 8),
            Card(suit: .spades, value: 10)
        ]
        
        let target = Card(suit: .clubs, value: 10)
        
        // Test valid cards
        let validCards = [
            Card(suit: .hearts, value: 7),   // 7 always beats
            Card(suit: .spades, value: 7),   // 7 always beats
            Card(suit: .hearts, value: 10),  // Same value beats
            Card(suit: .spades, value: 10)   // Same value beats
        ]
        
        for card in validCards {
            let result = GameRules.validateMove(
                card: card,
                from: complexHand,
                against: target,
                tableCardsCount: 1
            )
            
            switch result {
            case .valid:
                XCTAssertTrue(true, "\(card.displayName) should be valid")
            case .invalid:
                XCTFail("\(card.displayName) should be valid")
            }
        }
        
        // Test invalid cards (8s when table count not divisible by 3)
        let invalidCards = [
            Card(suit: .hearts, value: 8),
            Card(suit: .spades, value: 8)
        ]
        
        for card in invalidCards {
            let result = GameRules.validateMove(
                card: card,
                from: complexHand,
                against: target,
                tableCardsCount: 1
            )
            
            switch result {
            case .valid:
                XCTFail("\(card.displayName) should be invalid with table count 1")
            case .invalid(let error):
                XCTAssertEqual(error, .cannotBeatTopCard, "Should be cannotBeatTopCard error")
            }
        }
    }
    
    // MARK: - 8. Stress Test Scenarios
    
    func testRapidGameStateChanges() {
        let player1 = Player(name: "Player 1")
        let player2 = Player(name: "Player 2")
        let gameState = GameState(players: [player1, player2])
        
        // Rapidly change game state many times
        for i in 0..<100 {
            gameState.beginBatchUpdates()
            
            gameState.trickNumber = i
            gameState.roundNumber = i / 10
            gameState.currentPlayerIndex = i % 2
            
            // Add and remove cards rapidly
            let testCard = Card(suit: .hearts, value: 7)
            gameState.tableCards.append(testCard)
            gameState.tableCards.removeAll()
            
            gameState.endBatchUpdates()
        }
        
        // Game state should still be consistent
        XCTAssertEqual(gameState.players.count, 2, "Should still have 2 players")
        XCTAssertTrue(gameState.tableCards.isEmpty, "Table should be empty after cleanup")
    }
    
    func testExtremelyLongGameSimulation() {
        let player1 = Player(name: "Player 1")
        let player2 = Player(name: "Player 2")
        let gameState = GameState(players: [player1, player2])
        
        // Simulate a game that goes on much longer than normal
        var moveCount = 0
        let maxMoves = 1000
        
        while moveCount < maxMoves && !gameState.isGameComplete {
            let currentPlayer = gameState.currentPlayer!
            let validMoves = gameState.validMovesForCurrentPlayer()
            
            if let cardToPlay = validMoves.first {
                _ = gameState.playCard(cardToPlay, by: currentPlayer.id)
                moveCount += 1
            } else {
                // If no valid moves, manually add a card to continue test
                currentPlayer.hand.append(Card(suit: .hearts, value: 7))
            }
            
            // Prevent infinite loops
            if moveCount % 100 == 0 {
                // Periodically check game state is still valid
                XCTAssertEqual(gameState.players.count, 2, "Should maintain 2 players")
                XCTAssertNotNil(gameState.currentPlayer, "Should have current player")
            }
        }
        
        XCTAssertLessThan(moveCount, maxMoves, "Game should not require excessive moves")
    }
    
    // MARK: - 9. Multiplayer Edge Cases
    
    func testMultiplayerConfigurationEdgeCases() {
        let player1 = Player(name: "Player 1")
        let player2 = Player(name: "Player 2")
        let gameState = GameState(players: [player1, player2])
        
        // Test configuration with same player as local and remote
        gameState.configureForMultiplayer(
            localPlayerId: player1.id,
            gameSessionId: "test-session",
            isOnline: true
        )
        
        XCTAssertTrue(gameState.isLocalPlayerTurn, "Should be local player's turn")
        XCTAssertEqual(gameState.remotePlayer?.id, player2.id, "Remote player should be player 2")
        
        // Test with invalid local player ID
        let fakeId = UUID()
        gameState.configureForMultiplayer(
            localPlayerId: fakeId,
            gameSessionId: "test-session",
            isOnline: true
        )
        
        XCTAssertFalse(gameState.isLocalPlayerTurn, "Should not be local player's turn with invalid ID")
        XCTAssertNil(gameState.remotePlayer, "Should not find remote player with invalid local ID")
    }
    
    // MARK: - 10. Error Recovery Tests
    
    func testRecoveryFromInvalidStates() {
        let player1 = Player(name: "Player 1")
        let player2 = Player(name: "Player 2")
        let gameState = GameState(players: [player1, player2])
        
        // Force invalid current player index
        gameState.currentPlayerIndex = 99
        
        XCTAssertNil(gameState.currentPlayer, "Should return nil for invalid player index")
        XCTAssertTrue(gameState.validMovesForCurrentPlayer().isEmpty, "Should return empty moves for invalid player")
        XCTAssertFalse(gameState.currentPlayerCanMove(), "Should return false for invalid player")
        
        // Reset to valid state
        gameState.currentPlayerIndex = 0
        XCTAssertNotNil(gameState.currentPlayer, "Should recover with valid player index")
    }
    
    func testGameStateConsistencyAfterErrors() {
        let player1 = Player(name: "Player 1")
        let player2 = Player(name: "Player 2")
        let gameState = GameState(players: [player1, player2])
        
        let originalTrickNumber = gameState.trickNumber
        let originalTableCardCount = gameState.tableCards.count
        
        // Try several invalid operations
        _ = gameState.playCard(Card(suit: .hearts, value: 7), by: UUID()) // Invalid player
        _ = gameState.playCard(Card(suit: .hearts, value: 7), by: player2.id) // Wrong turn
        
        // Game state should remain consistent
        XCTAssertEqual(gameState.trickNumber, originalTrickNumber, "Trick number should not change after failed operations")
        XCTAssertEqual(gameState.tableCards.count, originalTableCardCount, "Table cards should not change after failed operations")
        XCTAssertEqual(gameState.currentPlayerIndex, 0, "Current player should not change after failed operations")
    }
}