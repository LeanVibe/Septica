//
//  GamePerformanceTests.swift
//  SepticaTests
//
//  Performance benchmarks and stress tests for Romanian Septica game logic
//  Ensures game runs efficiently even under heavy load
//

import XCTest
@testable import Septica

final class GamePerformanceTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Performance tests should run with optimized builds
        // This is typically configured in the test scheme
    }
    
    override func tearDownWithError() throws {
        // Clean up after performance tests
    }
    
    // MARK: - 1. Deck Operations Performance
    
    func testDeckCreationPerformance() {
        measure {
            for _ in 0..<1000 {
                let deck = GameRules.createDeck()
                XCTAssertEqual(deck.count, 32)
            }
        }
    }
    
    func testDeckShufflingPerformance() {
        measure {
            for _ in 0..<1000 {
                var deck = Deck()
                deck.shuffle()
            }
        }
    }
    
    func testCardDrawingPerformance() {
        measure {
            for _ in 0..<100 {
                var deck = Deck()
                while !deck.isEmpty {
                    _ = deck.drawCard()
                }
            }
        }
    }
    
    // MARK: - 2. Card Beating Logic Performance
    
    func testCardBeatingPerformance() {
        let cards = GameRules.createDeck()
        let targetCard = Card(suit: .hearts, value: 10)
        
        measure {
            for _ in 0..<10000 {
                for card in cards {
                    for tableCount in [0, 1, 2, 3, 4, 5, 6, 9, 12] {
                        _ = GameRules.canBeat(
                            attackingCard: card,
                            targetCard: targetCard,
                            tableCardsCount: tableCount
                        )
                    }
                }
            }
        }
    }
    
    func testValidMovesCalculationPerformance() {
        let fullHand = Array(GameRules.createDeck().prefix(8)) // Larger hand for stress test
        let targetCard = Card(suit: .hearts, value: 10)
        
        measure {
            for _ in 0..<5000 {
                for tableCount in [0, 1, 2, 3, 4, 5, 6, 9, 12] {
                    _ = GameRules.validMoves(
                        from: fullHand,
                        against: targetCard,
                        tableCardsCount: tableCount
                    )
                }
            }
        }
    }
    
    func testHasValidMovePerformance() {
        let fullHand = Array(GameRules.createDeck().prefix(8))
        let targetCard = Card(suit: .hearts, value: 10)
        
        measure {
            for _ in 0..<10000 {
                for tableCount in [0, 1, 2, 3, 4, 5, 6, 9, 12] {
                    _ = GameRules.hasValidMove(
                        playerHand: fullHand,
                        topTableCard: targetCard,
                        tableCardsCount: tableCount
                    )
                }
            }
        }
    }
    
    // MARK: - 3. Game State Performance
    
    func testGameStateInitializationPerformance() {
        measure {
            for _ in 0..<1000 {
                let player1 = Player(name: "Player 1")
                let player2 = Player(name: "Player 2")
                let gameState = GameState(players: [player1, player2])
                XCTAssertEqual(gameState.players.count, 2)
            }
        }
    }
    
    func testCardPlayPerformance() {
        let player1 = Player(name: "Player 1")
        let player2 = Player(name: "Player 2")
        let gameState = GameState(players: [player1, player2])
        
        measure {
            for _ in 0..<1000 {
                // Ensure player has a card to play
                if player1.hand.isEmpty {
                    player1.hand.append(Card(suit: .hearts, value: 7))
                }
                
                let cardToPlay = player1.hand.first!
                _ = gameState.playCard(cardToPlay, by: player1.id)
                
                // Reset for next iteration
                gameState.tableCards.removeAll()
                gameState.currentPlayerIndex = 0
                if !player1.hand.contains(cardToPlay) {
                    player1.hand.append(cardToPlay)
                }
            }
        }
    }
    
    func testTrickWinnerCalculationPerformance() {
        let tableCards = [
            Card(suit: .hearts, value: 10),
            Card(suit: .spades, value: 7),
            Card(suit: .clubs, value: 8),
            Card(suit: .diamonds, value: 14)
        ]
        
        measure {
            for _ in 0..<10000 {
                _ = GameRules.determineTrickWinner(tableCards: tableCards)
            }
        }
    }
    
    func testPointCalculationPerformance() {
        let cards = GameRules.createDeck()
        
        measure {
            for _ in 0..<10000 {
                _ = GameRules.calculatePoints(from: cards)
            }
        }
    }
    
    // MARK: - 4. Move Validation Performance
    
    func testMoveValidationPerformance() {
        let card = Card(suit: .hearts, value: 7)
        let playerHand = Array(GameRules.createDeck().prefix(8))
        let targetCard = Card(suit: .spades, value: 10)
        
        measure {
            for _ in 0..<10000 {
                _ = GameRules.validateMove(
                    card: card,
                    from: playerHand,
                    against: targetCard,
                    tableCardsCount: 3
                )
            }
        }
    }
    
    // MARK: - 5. Memory Performance Tests
    
    func testMemoryUsageDuringGameplay() {
        // This test ensures that game objects don't accumulate excessive memory
        weak var weakGameState: GameState?
        
        autoreleasepool {
            let player1 = Player(name: "Player 1")
            let player2 = Player(name: "Player 2")
            let gameState = GameState(players: [player1, player2])
            weakGameState = gameState
            
            // Simulate a full game
            for _ in 0..<20 { // Play multiple tricks
                if let cardToPlay = player1.hand.first {
                    _ = gameState.playCard(cardToPlay, by: player1.id)
                }
                
                if let cardToPlay = player2.hand.first {
                    _ = gameState.playCard(cardToPlay, by: player2.id)
                }
            }
        }
        
        // GameState should be deallocated after leaving the autoreleasepool
        XCTAssertNil(weakGameState, "GameState should be deallocated when no longer referenced")
    }
    
    func testLargeNumberOfGamesMemoryStability() {
        measure {
            for _ in 0..<100 {
                autoreleasepool {
                    let player1 = Player(name: "Player 1")
                    let player2 = Player(name: "Player 2")
                    let gameState = GameState(players: [player1, player2])
                    
                    // Play a few moves
                    for _ in 0..<4 {
                        if let card = player1.hand.first {
                            _ = gameState.playCard(card, by: player1.id)
                        }
                        if let card = player2.hand.first {
                            _ = gameState.playCard(card, by: player2.id)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 6. Batch Operations Performance
    
    func testBatchUpdatesPerformance() {
        let player1 = Player(name: "Player 1")
        let player2 = Player(name: "Player 2")
        let gameState = GameState(players: [player1, player2])
        
        measure {
            for _ in 0..<1000 {
                gameState.beginBatchUpdates()
                
                // Simulate multiple state changes
                gameState.tableCards.append(Card(suit: .hearts, value: 7))
                gameState.trickNumber += 1
                gameState.roundNumber += 1
                gameState.tableCards.removeAll()
                
                gameState.endBatchUpdates()
            }
        }
    }
    
    // MARK: - 7. Complex Scenario Performance
    
    func testFullGameSimulationPerformance() {
        measure {
            for _ in 0..<50 { // Run 50 full games
                let player1 = Player(name: "Player 1")
                let player2 = Player(name: "Player 2")
                let gameState = GameState(players: [player1, player2])
                
                // Simulate a full game until completion
                var movesPlayed = 0
                let maxMoves = 100 // Safety limit
                
                while !gameState.isGameComplete && movesPlayed < maxMoves {
                    let currentPlayer = gameState.currentPlayer!
                    let validMoves = gameState.validMovesForCurrentPlayer()
                    
                    if let cardToPlay = validMoves.first {
                        _ = gameState.playCard(cardToPlay, by: currentPlayer.id)
                        movesPlayed += 1
                    } else {
                        // If no valid moves, skip turn
                        gameState.skipCurrentPlayer()
                    }
                }
            }
        }
    }
    
    // MARK: - 8. Algorithmic Complexity Tests
    
    func testScalabilityWithTableSize() {
        let card = Card(suit: .hearts, value: 8)
        let target = Card(suit: .spades, value: 10)
        
        // Test that algorithm performance doesn't degrade with larger table counts
        measure {
            for tableSize in stride(from: 0, through: 1000, by: 10) {
                _ = GameRules.canBeat(
                    attackingCard: card,
                    targetCard: target,
                    tableCardsCount: tableSize
                )
            }
        }
    }
    
    func testScalabilityWithHandSize() {
        // Test valid moves calculation with increasingly large hands
        let targetCard = Card(suit: .hearts, value: 10)
        
        measure {
            for handSize in stride(from: 1, through: 32, by: 1) {
                let hand = Array(GameRules.createDeck().prefix(handSize))
                _ = GameRules.validMoves(
                    from: hand,
                    against: targetCard,
                    tableCardsCount: 3
                )
            }
        }
    }
    
    // MARK: - 9. Concurrent Access Performance
    
    func testConcurrentCardBeatingCalculations() {
        let cards = GameRules.createDeck()
        let targetCard = Card(suit: .hearts, value: 10)
        
        measure {
            DispatchQueue.concurrentPerform(iterations: 100) { _ in
                for card in cards {
                    for tableCount in [0, 1, 2, 3, 4, 5, 6, 9, 12] {
                        _ = GameRules.canBeat(
                            attackingCard: card,
                            targetCard: targetCard,
                            tableCardsCount: tableCount
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - 10. Real-World Usage Patterns
    
    func testTypicalGameplayPattern() {
        // Simulate typical user interaction patterns
        measure {
            let player1 = Player(name: "Player 1")
            let player2 = Player(name: "Player 2")
            let gameState = GameState(players: [player1, player2])
            
            for _ in 0..<20 { // 20 typical game actions
                // Check valid moves (user thinking)
                _ = gameState.validMovesForCurrentPlayer()
                
                // Check if can move (game logic)
                _ = gameState.currentPlayerCanMove()
                
                // Get game statistics (UI updates)
                _ = gameState.getGameStatistics()
                
                // Play a card if possible
                let validMoves = gameState.validMovesForCurrentPlayer()
                if let cardToPlay = validMoves.first {
                    _ = gameState.playCard(cardToPlay, by: gameState.currentPlayer!.id)
                }
            }
        }
    }
    
    // MARK: - 11. Edge Case Performance
    
    func testWorstCaseScenarios() {
        // Test performance with worst-case inputs
        let allSevens = [
            Card(suit: .hearts, value: 7),
            Card(suit: .spades, value: 7),
            Card(suit: .clubs, value: 7),
            Card(suit: .diamonds, value: 7)
        ]
        
        measure {
            for _ in 0..<5000 {
                // All cards can beat each other (worst case for validation)
                for attacking in allSevens {
                    for target in allSevens {
                        _ = GameRules.canBeat(
                            attackingCard: attacking,
                            targetCard: target,
                            tableCardsCount: 0
                        )
                    }
                }
            }
        }
    }
    
    func testEmptyHandScenarios() {
        let emptyHand: [Card] = []
        let targetCard = Card(suit: .hearts, value: 10)
        
        measure {
            for _ in 0..<10000 {
                _ = GameRules.hasValidMove(
                    playerHand: emptyHand,
                    topTableCard: targetCard,
                    tableCardsCount: 1
                )
                
                _ = GameRules.validMoves(
                    from: emptyHand,
                    against: targetCard,
                    tableCardsCount: 1
                )
            }
        }
    }
}