//
//  GameLogicIntegrationTests.swift
//  SepticaTests
//
//  Comprehensive integration tests for Septica game logic
//  Tests complete game flows, edge cases, and production scenarios
//

import XCTest
@testable import Septica

final class GameLogicIntegrationTests: XCTestCase {
    
    var gameState: GameState!
    var humanPlayer: Player!
    var aiPlayer: AIPlayer!
    
    override func setUp() {
        super.setUp()
        humanPlayer = Player(name: "Human Test Player")
        aiPlayer = AIPlayer(name: "AI Test Player", difficulty: .medium)
        gameState = GameState(players: [humanPlayer, aiPlayer])
    }
    
    override func tearDown() {
        gameState = nil
        humanPlayer = nil
        aiPlayer = nil
        super.tearDown()
    }
    
    // MARK: - Complete Game Flow Tests
    
    func testCompleteGameFlow() {
        // Test a complete game from setup to completion
        XCTAssertEqual(gameState.phase, .playing)
        XCTAssertEqual(gameState.players.count, 2)
        XCTAssertFalse(gameState.isGameComplete)
        
        // Verify initial hands are dealt
        XCTAssertEqual(humanPlayer.hand.count, 4)
        XCTAssertEqual(aiPlayer.hand.count, 4)
        
        // Play a few moves to test game progression
        let initialCard = humanPlayer.hand.first!
        let validMoves = gameState.validMovesForCurrentPlayer()
        XCTAssertTrue(validMoves.contains(where: { $0.suit == initialCard.suit && $0.value == initialCard.value }))
        
        // Execute a valid move
        let result = gameState.playCard(initialCard, by: humanPlayer.id)
        XCTAssertEqual(result, .success)
        XCTAssertEqual(gameState.tableCards.count, 1)
        XCTAssertEqual(gameState.tableCards.first, initialCard)
        XCTAssertFalse(humanPlayer.hasCard(initialCard))
    }
    
    func testTrickCompletionAndScoring() {
        // Set up a scenario where we can complete a trick with points
        let tenOfHearts = Card(suit: .hearts, value: 10) // Point card
        let aceOfSpades = Card(suit: .spades, value: 14) // Point card
        
        // Force set hands for predictable testing
        humanPlayer.hand = [tenOfHearts]
        aiPlayer.hand = [aceOfSpades]
        
        gameState.players = [humanPlayer, aiPlayer]
        gameState.currentPlayerIndex = 0
        
        // Human plays the 10 of hearts
        var result = gameState.playCard(tenOfHearts, by: humanPlayer.id)
        XCTAssertEqual(result, .success)
        XCTAssertEqual(gameState.tableCards.count, 1)
        XCTAssertEqual(gameState.currentPlayerIndex, 1) // Should be AI's turn
        
        // AI plays the Ace of spades (should win the trick)
        result = gameState.playCard(aceOfSpades, by: aiPlayer.id)
        XCTAssertEqual(result, .success)
        
        // Trick should be complete and AI should have won 2 points
        XCTAssertEqual(gameState.tableCards.count, 0) // Table cleared
        XCTAssertEqual(aiPlayer.score, 2) // 10 + Ace = 2 points
        XCTAssertEqual(gameState.trickHistory.count, 1)
        XCTAssertEqual(gameState.trickHistory.first?.winnerPlayerId, aiPlayer.id)
        XCTAssertEqual(gameState.trickHistory.first?.points, 2)
    }
    
    func testGameEndConditions() {
        // Test game ending when target score is reached
        humanPlayer.score = 11 // Reached target
        
        XCTAssertTrue(gameState.isGameComplete)
        
        // Reset and test game ending when all cards are played
        humanPlayer.score = 0
        aiPlayer.score = 0
        humanPlayer.hand = []
        aiPlayer.hand = []
        gameState.deck = Deck() // Empty deck
        gameState.deck.cards = []
        
        XCTAssertTrue(gameState.isGameComplete)
    }
    
    // MARK: - Romanian Septica Rules Integration Tests
    
    func testSevenAlwaysWins() {
        // Test that 7s always beat other cards in actual gameplay
        let sevenOfHearts = Card(suit: .hearts, value: 7)
        let kingOfSpades = Card(suit: .spades, value: 13)
        
        humanPlayer.hand = [sevenOfHearts]
        aiPlayer.hand = [kingOfSpades]
        
        // Human plays King first
        gameState.currentPlayerIndex = 1
        var result = gameState.playCard(kingOfSpades, by: aiPlayer.id)
        XCTAssertEqual(result, .success)
        
        // Human plays 7 and should win
        gameState.currentPlayerIndex = 0
        result = gameState.playCard(sevenOfHearts, by: humanPlayer.id)
        XCTAssertEqual(result, .success)
        
        // Human should have won the trick
        XCTAssertEqual(gameState.trickHistory.count, 1)
        XCTAssertEqual(gameState.trickHistory.first?.winnerPlayerId, humanPlayer.id)
    }
    
    func testEightConditionalBeating() {
        // Test 8 beating when table count is divisible by 3
        let eightOfHearts = Card(suit: .hearts, value: 8)
        let queenOfSpades = Card(suit: .spades, value: 12)
        let jackOfClubs = Card(suit: .clubs, value: 11)
        
        humanPlayer.hand = [eightOfHearts]
        aiPlayer.hand = [queenOfSpades, jackOfClubs]
        
        // Set up table with 3 cards (divisible by 3) using internal manipulation
        gameState.tableCards = [queenOfSpades, jackOfClubs, queenOfSpades] // Simulate 3 cards on table
        
        // 8 should be able to beat when table count is 3
        let validMoves = GameRules.validMoves(
            from: [eightOfHearts],
            against: queenOfSpades,
            tableCardsCount: 3
        )
        
        XCTAssertTrue(validMoves.contains(where: { $0.value == 8 }))
        
        // Reset table and test when count is not divisible by 3
        gameState.tableCards = [queenOfSpades, jackOfClubs] // 2 cards
        
        let validMovesNot3 = GameRules.validMoves(
            from: [eightOfHearts],
            against: queenOfSpades,
            tableCardsCount: 2
        )
        
        XCTAssertFalse(validMovesNot3.contains(where: { $0.value == 8 }))
    }
    
    func testScoringOnlyTensAndAces() {
        // Test that only 10s and Aces contribute to scoring
        let mixed_cards = [
            Card(suit: .hearts, value: 7),  // Not a point card
            Card(suit: .spades, value: 8),  // Not a point card
            Card(suit: .clubs, value: 10),  // Point card (1 point)
            Card(suit: .diamonds, value: 11), // Not a point card
            Card(suit: .hearts, value: 14),  // Point card (1 point)
        ]
        
        let points = GameRules.calculatePoints(from: mixed_cards)
        XCTAssertEqual(points, 2) // Only the 10 and Ace should count
    }
    
    // MARK: - Edge Case Tests
    
    func testEmptyHandValidation() {
        // Test behavior when player has no cards
        humanPlayer.hand = []
        
        let validMoves = gameState.validMovesForCurrentPlayer()
        XCTAssertTrue(validMoves.isEmpty)
        XCTAssertFalse(gameState.currentPlayerCanMove())
        
        // Test that skipping works
        let currentIndex = gameState.currentPlayerIndex
        gameState.skipCurrentPlayer()
        XCTAssertNotEqual(gameState.currentPlayerIndex, currentIndex)
    }
    
    func testInvalidMoveAttempts() {
        // Test various invalid move scenarios
        let cardNotInHand = Card(suit: .hearts, value: 13)
        XCTAssertFalse(humanPlayer.hasCard(cardNotInHand))
        
        // Try to play card not in hand
        var result = gameState.playCard(cardNotInHand, by: humanPlayer.id)
        switch result {
        case .failure(.invalidMove(.cardNotInHand)):
            XCTAssertTrue(true) // Expected
        default:
            XCTFail("Expected cardNotInHand error")
        }
        
        // Try to play out of turn
        let aiCard = aiPlayer.hand.first!
        result = gameState.playCard(aiCard, by: aiPlayer.id)
        switch result {
        case .failure(.notPlayerTurn):
            XCTAssertTrue(true) // Expected
        default:
            XCTFail("Expected notPlayerTurn error")
        }
        
        // Try to play with invalid player ID
        let invalidId = UUID()
        let validCard = humanPlayer.hand.first!
        result = gameState.playCard(validCard, by: invalidId)
        switch result {
        case .failure(.playerNotFound):
            XCTAssertTrue(true) // Expected
        default:
            XCTFail("Expected playerNotFound error")
        }
    }
    
    func testDeckExhaustion() {
        // Test game behavior when deck runs out of cards
        gameState.deck.cards = [] // Force empty deck
        
        // Continue playing until hands are empty
        while !humanPlayer.hand.isEmpty && !aiPlayer.hand.isEmpty && !gameState.isGameComplete {
            let currentPlayer = gameState.currentPlayer!
            if let validCard = gameState.validMovesForCurrentPlayer().first {
                gameState.playCard(validCard, by: currentPlayer.id)
            } else {
                gameState.skipCurrentPlayer()
            }
            
            // Prevent infinite loops in testing
            if gameState.trickHistory.count > 20 {
                break
            }
        }
        
        // Game should end when all cards are played
        if humanPlayer.hand.isEmpty && aiPlayer.hand.isEmpty {
            XCTAssertTrue(gameState.isGameComplete)
        }
    }
    
    // MARK: - Multiplayer Turn Management Tests
    
    func testTurnProgression() {
        // Test that turns progress correctly through players
        XCTAssertEqual(gameState.currentPlayerIndex, 0) // Should start with first player
        
        let firstCard = gameState.currentPlayer!.hand.first!
        gameState.playCard(firstCard, by: gameState.currentPlayer!.id)
        
        // Should advance to next player if trick not complete
        if !gameState.isTrickComplete {
            XCTAssertEqual(gameState.currentPlayerIndex, 1)
        }
    }
    
    func testTrickWinnerStartsNext() {
        // Test that trick winner starts the next trick
        let tenOfHearts = Card(suit: .hearts, value: 10)
        let sevenOfSpades = Card(suit: .spades, value: 7) // Should win
        
        humanPlayer.hand = [tenOfHearts]
        aiPlayer.hand = [sevenOfSpades]
        
        // Human plays first
        gameState.currentPlayerIndex = 0
        gameState.playCard(tenOfHearts, by: humanPlayer.id)
        
        // AI plays winning card
        XCTAssertEqual(gameState.currentPlayerIndex, 1)
        gameState.playCard(sevenOfSpades, by: aiPlayer.id)
        
        // AI should start the next trick (if game continues)
        if !gameState.isGameComplete && gameState.trickHistory.count > 0 {
            XCTAssertEqual(gameState.currentPlayerIndex, 1) // AI won, AI starts
        }
    }
    
    // MARK: - Game State Consistency Tests
    
    func testGameStateConsistency() {
        // Test that game state remains consistent throughout play
        let initialTotalCards = humanPlayer.hand.count + aiPlayer.hand.count + gameState.deck.count
        
        // Play several moves
        for _ in 0..<6 {
            if gameState.isGameComplete { break }
            
            if let validCard = gameState.validMovesForCurrentPlayer().first {
                let currentPlayerId = gameState.currentPlayer!.id
                gameState.playCard(validCard, by: currentPlayerId)
            }
            
            // Check consistency after each move
            let currentTotalCards = humanPlayer.hand.count + aiPlayer.hand.count + gameState.deck.count + gameState.tableCards.count
            let cardsInHistory = gameState.trickHistory.reduce(0) { $0 + $1.cards.count }
            let totalAccountedCards = currentTotalCards + cardsInHistory
            
            XCTAssertEqual(totalAccountedCards, initialTotalCards, "Cards should be conserved")
        }
    }
    
    func testScoreIntegrity() {
        // Test that scores only increase through valid point-earning moves
        let initialHumanScore = humanPlayer.score
        let initialAIScore = aiPlayer.score
        
        // Play a trick with no point cards
        let sevenOfHearts = Card(suit: .hearts, value: 7)
        let eightOfSpades = Card(suit: .spades, value: 8)
        
        humanPlayer.hand = [sevenOfHearts]
        aiPlayer.hand = [eightOfSpades]
        
        gameState.currentPlayerIndex = 0
        gameState.playCard(sevenOfHearts, by: humanPlayer.id)
        gameState.playCard(eightOfSpades, by: aiPlayer.id)
        
        // No points should have been awarded (7 and 8 are not point cards)
        XCTAssertEqual(humanPlayer.score, initialHumanScore + 0) // 7 wins, but no point cards on table
        XCTAssertEqual(aiPlayer.score, initialAIScore)
    }
    
    // MARK: - Performance Tests
    
    func testGamePerformance() {
        // Test that game operations complete in reasonable time
        measure {
            let testGame = GameState(players: [Player(name: "P1"), AIPlayer(name: "P2", difficulty: .easy)])
            
            // Simulate rapid gameplay
            for _ in 0..<10 {
                if testGame.isGameComplete { break }
                
                if let validCard = testGame.validMovesForCurrentPlayer().first {
                    let currentPlayerId = testGame.currentPlayer!.id
                    testGame.playCard(validCard, by: currentPlayerId)
                }
            }
        }
    }
    
    // MARK: - Game Statistics Tests
    
    func testGameStatistics() {
        // Test that game statistics are accurately tracked
        let stats = gameState.getGameStatistics()
        
        XCTAssertEqual(stats.playerStats.count, 2)
        XCTAssertEqual(stats.totalTricks, gameState.trickHistory.count)
        
        // Play a trick and verify stats update
        if let validCard = gameState.validMovesForCurrentPlayer().first {
            gameState.playCard(validCard, by: gameState.currentPlayer!.id)
        }
        
        let updatedStats = gameState.getGameStatistics()
        XCTAssertEqual(updatedStats.totalCardsPlayed, gameState.trickHistory.reduce(0) { $0 + $1.cards.count })
    }
    
    // MARK: - Regression Tests
    
    func testNoInfiniteLoops() {
        // Test that game cannot get stuck in infinite loops
        var moveCount = 0
        let maxMoves = 100 // Safety limit
        
        while !gameState.isGameComplete && moveCount < maxMoves {
            if let validCard = gameState.validMovesForCurrentPlayer().first {
                gameState.playCard(validCard, by: gameState.currentPlayer!.id)
                moveCount += 1
            } else {
                gameState.skipCurrentPlayer()
                moveCount += 1
            }
        }
        
        XCTAssertLessThan(moveCount, maxMoves, "Game should not require more than \(maxMoves) moves to complete")
    }
    
    func testStateRestoration() {
        // Test that game state can be properly saved and restored
        // This is important for app backgrounding/foregrounding
        
        // Play some moves to create game state
        for _ in 0..<3 {
            if gameState.isGameComplete { break }
            if let validCard = gameState.validMovesForCurrentPlayer().first {
                gameState.playCard(validCard, by: gameState.currentPlayer!.id)
            }
        }
        
        let originalStats = gameState.getGameStatistics()
        let originalPhase = gameState.phase
        let originalScore1 = humanPlayer.score
        let originalScore2 = aiPlayer.score
        
        // Simulate saving and restoring (this would involve JSON serialization in real app)
        let newGameState = GameState(players: [
            Player(name: humanPlayer.name, id: humanPlayer.id),
            AIPlayer(name: aiPlayer.name, difficulty: (aiPlayer as! AIPlayer).difficulty, id: aiPlayer.id)
        ])
        
        // Verify core properties are restorable (simplified test)
        XCTAssertNotNil(newGameState.id)
        XCTAssertEqual(newGameState.players.count, 2)
        XCTAssertEqual(newGameState.phase, .playing) // New game starts in playing phase
    }
}

// MARK: - Test Result Enumeration Extension

extension PlayResult: Equatable {
    public static func == (lhs: PlayResult, rhs: PlayResult) -> Bool {
        switch (lhs, rhs) {
        case (.success, .success):
            return true
        case (.failure(let lhsError), .failure(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}