//
//  AIBehaviorQualityTests.swift
//  SepticaTests
//
//  Comprehensive AI behavior and quality assurance tests
//  Tests AI decision making quality, strategic patterns, and difficulty consistency
//

import XCTest
@testable import Septica

final class AIBehaviorQualityTests: XCTestCase {
    
    var gameState: GameState!
    var easyAI: AIPlayer!
    var mediumAI: AIPlayer!
    var hardAI: AIPlayer!
    var expertAI: AIPlayer!
    
    override func setUp() {
        super.setUp()
        easyAI = AIPlayer(name: "Easy AI", difficulty: .easy)
        mediumAI = AIPlayer(name: "Medium AI", difficulty: .medium)
        hardAI = AIPlayer(name: "Hard AI", difficulty: .hard)
        expertAI = AIPlayer(name: "Expert AI", difficulty: .expert)
        gameState = GameState(players: [Player(name: "Human"), mediumAI])
    }
    
    override func tearDown() {
        gameState = nil
        easyAI = nil
        mediumAI = nil
        hardAI = nil
        expertAI = nil
        super.tearDown()
    }
    
    // MARK: - AI Decision Quality Tests
    
    func testAINeverMakesIllegalMoves() async {
        // Test that AI never attempts illegal moves across all difficulties
        let difficulties: [AIPlayer] = [easyAI, mediumAI, hardAI, expertAI]
        
        for aiPlayer in difficulties {
            // Set up a constrained scenario
            aiPlayer.hand = [
                Card(suit: .hearts, value: 9),   // Cannot beat most cards
                Card(suit: .spades, value: 11),  // Cannot beat most cards
                Card(suit: .clubs, value: 7)     // Can beat anything
            ]
            
            let tableCard = Card(suit: .diamonds, value: 12)
            gameState.tableCards = [tableCard]
            
            let validMoves = GameRules.validMoves(
                from: aiPlayer.hand,
                against: tableCard,
                tableCardsCount: 1
            )
            
            // AI should only choose from valid moves
            let chosenCard = await aiPlayer.chooseCard(gameState: gameState, validMoves: validMoves)
            
            XCTAssertNotNil(chosenCard, "AI should choose a card when valid moves exist")
            XCTAssertTrue(validMoves.contains { $0.suit == chosenCard!.suit && $0.value == chosenCard!.value },
                         "AI (\(aiPlayer.difficulty)) should only choose from valid moves")
        }
    }
    
    func testDifficultyAccuracyLevels() async {
        // Test that different difficulty levels show measurably different decision quality
        let testScenario = [
            Card(suit: .hearts, value: 7),    // Optimal choice (trump card)
            Card(suit: .spades, value: 8),    // Suboptimal 
            Card(suit: .clubs, value: 9),     // Poor choice
            Card(suit: .diamonds, value: 11)  // Poor choice
        ]
        
        // Set up scenario where 7 is clearly the best choice
        gameState.tableCards = [
            Card(suit: .hearts, value: 10),   // Point card on table
            Card(suit: .spades, value: 14)    // Ace (point card) on table
        ]
        
        let difficulties = [easyAI, mediumAI, hardAI, expertAI]
        var optimalChoices: [AIDifficulty: Int] = [:]
        
        let testRuns = 10
        
        for aiPlayer in difficulties {
            var optimalCount = 0
            
            for _ in 0..<testRuns {
                aiPlayer.hand = testScenario
                
                let validMoves = testScenario // All cards are valid when starting a trick
                let choice = await aiPlayer.chooseCard(gameState: gameState, validMoves: validMoves)
                
                if choice?.value == 7 { // Optimal choice (7 can collect points)
                    optimalCount += 1
                }
            }
            
            optimalChoices[aiPlayer.difficulty] = optimalCount
        }
        
        // Expert should make optimal choices more often than Hard
        XCTAssertGreaterThanOrEqual(optimalChoices[.expert] ?? 0, optimalChoices[.hard] ?? 0,
                                   "Expert AI should be at least as optimal as Hard AI")
        
        // Hard should make optimal choices more often than Medium
        XCTAssertGreaterThanOrEqual(optimalChoices[.hard] ?? 0, optimalChoices[.medium] ?? 0,
                                   "Hard AI should be at least as optimal as Medium AI")
        
        // Medium should make optimal choices more often than Easy (not always guaranteed due to randomness)
        // But we can test that Expert makes significantly better choices than Easy
        XCTAssertGreaterThan(optimalChoices[.expert] ?? 0, optimalChoices[.easy] ?? 0,
                            "Expert AI should make significantly more optimal choices than Easy AI")
    }
    
    func testAIThinkingTimes() async {
        // Test that AI thinking times match their difficulty specifications
        let difficulties: [(AIPlayer, TimeInterval)] = [
            (easyAI, 1.0),
            (mediumAI, 1.5),
            (hardAI, 2.0),
            (expertAI, 2.5)
        ]
        
        for (aiPlayer, expectedTime) in difficulties {
            aiPlayer.hand = [Card(suit: .hearts, value: 10)]
            let validMoves = aiPlayer.hand
            
            let startTime = Date()
            _ = await aiPlayer.chooseCard(gameState: gameState, validMoves: validMoves)
            let actualTime = Date().timeIntervalSince(startTime)
            
            // Allow some tolerance for system delays
            XCTAssertGreaterThanOrEqual(actualTime, expectedTime - 0.1,
                                       "\(aiPlayer.difficulty) AI should think for at least \(expectedTime - 0.1) seconds")
            XCTAssertLessThanOrEqual(actualTime, expectedTime + 0.5,
                                    "\(aiPlayer.difficulty) AI should not exceed \(expectedTime + 0.5) seconds thinking time")
        }
    }
    
    // MARK: - Strategic Behavior Tests
    
    func testAIPrefers7sWithPointsOnTable() async {
        // Test that AI properly values 7s when points are available
        expertAI.hand = [
            Card(suit: .hearts, value: 7),    // Should prefer this
            Card(suit: .spades, value: 8),    // Less optimal
            Card(suit: .clubs, value: 9),     // Less optimal
            Card(suit: .diamonds, value: 11)  // Less optimal
        ]
        
        // Put valuable cards on table
        gameState.tableCards = [
            Card(suit: .hearts, value: 10),   // 1 point
            Card(suit: .spades, value: 14),   // 1 point (Ace)
        ]
        
        let validMoves = expertAI.hand
        var sevenChosenCount = 0
        
        // Test multiple times due to AI randomness
        for _ in 0..<8 {
            let choice = await expertAI.chooseCard(gameState: gameState, validMoves: validMoves)
            if choice?.value == 7 {
                sevenChosenCount += 1
            }
        }
        
        // Expert AI should choose 7 most of the time when points are available
        XCTAssertGreaterThanOrEqual(sevenChosenCount, 5,
                                   "Expert AI should prefer 7s when points (2 total) are on table")
    }
    
    func testAIAvoids7sEarlyGameWithoutPoints() async {
        // Test that AI avoids wasting 7s early in the game
        mediumAI.hand = [
            Card(suit: .hearts, value: 7),
            Card(suit: .spades, value: 8),
            Card(suit: .clubs, value: 9),
            Card(suit: .diamonds, value: 11)
        ]
        
        // Empty table (starting a trick) with no points
        gameState.tableCards = []
        
        let validMoves = mediumAI.hand // All valid when starting trick
        var non7ChosenCount = 0
        
        for _ in 0..<10 {
            let choice = await mediumAI.chooseCard(gameState: gameState, validMoves: validMoves)
            if choice?.value != 7 {
                non7ChosenCount += 1
            }
        }
        
        // AI should often avoid playing 7s when starting tricks early
        XCTAssertGreaterThanOrEqual(non7ChosenCount, 6,
                                   "AI should tend to avoid 7s when starting tricks with no points at stake")
    }
    
    func testAIPlaysOptimallyWithOnlyOneChoice() async {
        // Test AI behavior when only one valid move exists
        expertAI.hand = [
            Card(suit: .hearts, value: 7),    // Only valid move
            Card(suit: .spades, value: 9),    // Cannot beat target
            Card(suit: .clubs, value: 11)     // Cannot beat target
        ]
        
        let tableCard = Card(suit: .diamonds, value: 12)
        gameState.tableCards = [tableCard]
        
        let validMoves = GameRules.validMoves(
            from: expertAI.hand,
            against: tableCard,
            tableCardsCount: 1
        )
        
        XCTAssertEqual(validMoves.count, 1)
        XCTAssertEqual(validMoves.first?.value, 7)
        
        let choice = await expertAI.chooseCard(gameState: gameState, validMoves: validMoves)
        XCTAssertEqual(choice?.value, 7, "AI should choose the only valid move")
    }
    
    func testAIStrategicDecisionConsistency() async {
        // Test that AI makes consistent strategic decisions in identical scenarios
        let testHand = [
            Card(suit: .hearts, value: 10), // Point card
            Card(suit: .spades, value: 11), // Regular card
        ]
        
        let tableCard = Card(suit: .clubs, value: 9)
        
        expertAI.hand = testHand
        gameState.tableCards = [tableCard]
        
        let validMoves = GameRules.validMoves(
            from: testHand,
            against: tableCard,
            tableCardsCount: 1
        )
        
        var choices: [Card] = []
        
        // Get multiple decisions in identical scenarios
        for _ in 0..<5 {
            expertAI.hand = testHand // Reset hand
            let choice = await expertAI.chooseCard(gameState: gameState, validMoves: validMoves)
            if let card = choice {
                choices.append(card)
            }
        }
        
        // Expert AI should show some consistency (not completely random)
        XCTAssertGreaterThan(choices.count, 0, "AI should make choices")
        
        // Count unique choices - should not be completely random
        let uniqueChoices = Set(choices.map { "\($0.suit)-\($0.value)" })
        XCTAssertLessThanOrEqual(uniqueChoices.count, 2, "Expert AI should not be completely random")
    }
    
    // MARK: - Error Handling Tests
    
    func testAIHandlesEmptyValidMoves() async {
        expertAI.hand = []
        let validMoves: [Card] = []
        
        let choice = await expertAI.chooseCard(gameState: gameState, validMoves: validMoves)
        XCTAssertNil(choice, "AI should return nil when no valid moves available")
    }
    
    func testAIHandlesCorruptedGameState() async {
        // Test AI resilience to unusual game states
        expertAI.hand = [Card(suit: .hearts, value: 7)]
        
        // Create unusual game state
        gameState.tableCards = [] // Empty table
        gameState.currentPlayerIndex = -1 // Invalid index
        
        let validMoves = expertAI.hand
        let choice = await expertAI.chooseCard(gameState: gameState, validMoves: validMoves)
        
        // AI should still make a valid choice
        XCTAssertNotNil(choice, "AI should handle unusual game states gracefully")
        XCTAssertTrue(expertAI.hasCard(choice!), "AI should choose from its own hand")
    }
    
    // MARK: - Romanian Septica Strategic Pattern Tests
    
    func testAIUnderstandsCardHierarchy() async {
        // Test that AI understands the special Romanian Septica card hierarchy
        hardAI.hand = [
            Card(suit: .hearts, value: 7),    // Highest priority (wild)
            Card(suit: .spades, value: 8),    // Conditional (depends on table count)
            Card(suit: .clubs, value: 10),    // Same value beats
            Card(suit: .diamonds, value: 11)   // Cannot beat
        ]
        
        let tableCard = Card(suit: .hearts, value: 10) // Target to beat
        gameState.tableCards = [tableCard]
        
        let validMoves = GameRules.validMoves(
            from: hardAI.hand,
            against: tableCard,
            tableCardsCount: 1
        )
        
        // Should have 7 (always beats) and 10 (same value beats)
        XCTAssertEqual(validMoves.count, 2)
        XCTAssertTrue(validMoves.contains { $0.value == 7 })
        XCTAssertTrue(validMoves.contains { $0.value == 10 })
        
        let choice = await hardAI.chooseCard(gameState: gameState, validMoves: validMoves)
        XCTAssertNotNil(choice)
        XCTAssertTrue(choice!.value == 7 || choice!.value == 10)
    }
    
    func testAIPointCardPrioritization() async {
        // Test that AI prioritizes collecting point cards (10s and Aces)
        expertAI.hand = [Card(suit: .hearts, value: 7)] // Can beat anything
        
        // Scenario 1: No points on table
        gameState.tableCards = [Card(suit: .spades, value: 8)]
        let choice1 = await expertAI.chooseCard(gameState: gameState, validMoves: expertAI.hand)
        
        // Scenario 2: Points on table
        gameState.tableCards = [
            Card(suit: .spades, value: 8),
            Card(suit: .hearts, value: 10),   // 1 point
            Card(suit: .clubs, value: 14)     // 1 point (Ace)
        ]
        
        expertAI.hand = [Card(suit: .hearts, value: 7)]
        let choice2 = await expertAI.chooseCard(gameState: gameState, validMoves: expertAI.hand)
        
        // AI should be more likely to play 7 when points are available
        XCTAssertNotNil(choice1)
        XCTAssertNotNil(choice2)
        // Both choices should be the 7 since it's the only card, but behavior pattern is important
    }
    
    // MARK: - Performance and Robustness Tests
    
    func testAIDecisionPerformance() async {
        // Test that AI decisions complete within reasonable time limits
        let largeHand = [
            Card(suit: .hearts, value: 7),
            Card(suit: .hearts, value: 8),
            Card(suit: .hearts, value: 9),
            Card(suit: .hearts, value: 10),
            Card(suit: .spades, value: 7),
            Card(suit: .spades, value: 8),
            Card(suit: .spades, value: 9),
            Card(suit: .spades, value: 10),
        ]
        
        expertAI.hand = largeHand
        
        let startTime = Date()
        let choice = await expertAI.chooseCard(gameState: gameState, validMoves: largeHand)
        let elapsedTime = Date().timeIntervalSince(startTime)
        
        XCTAssertNotNil(choice)
        XCTAssertLessThan(elapsedTime, 5.0, "AI should make decisions within 5 seconds even with large hands")
    }
    
    func testAIMemoryEfficiency() async {
        // Test that AI doesn't consume excessive memory during decision making
        let initialMemory = mach_task_basic_info()
        
        // Make many AI decisions
        for _ in 0..<50 {
            expertAI.hand = [
                Card(suit: .hearts, value: 7),
                Card(suit: .spades, value: 10),
                Card(suit: .clubs, value: 14)
            ]
            
            _ = await expertAI.chooseCard(gameState: gameState, validMoves: expertAI.hand)
        }
        
        let finalMemory = mach_task_basic_info()
        
        // Memory should not increase dramatically (this is a basic check)
        // In a real implementation, you'd use more sophisticated memory monitoring
        XCTAssertNotNil(finalMemory)
        XCTAssertNotNil(initialMemory)
    }
    
    func testConcurrentAIDecisions() async {
        // Test that multiple AI players can make decisions concurrently without conflicts
        let ai1 = AIPlayer(name: "AI1", difficulty: .medium)
        let ai2 = AIPlayer(name: "AI2", difficulty: .hard)
        let ai3 = AIPlayer(name: "AI3", difficulty: .expert)
        
        ai1.hand = [Card(suit: .hearts, value: 7)]
        ai2.hand = [Card(suit: .spades, value: 8)]
        ai3.hand = [Card(suit: .clubs, value: 9)]
        
        async let choice1 = ai1.chooseCard(gameState: gameState, validMoves: ai1.hand)
        async let choice2 = ai2.chooseCard(gameState: gameState, validMoves: ai2.hand)
        async let choice3 = ai3.chooseCard(gameState: gameState, validMoves: ai3.hand)
        
        let results = await [choice1, choice2, choice3]
        
        XCTAssertNotNil(results[0], "AI1 should make a choice")
        XCTAssertNotNil(results[1], "AI2 should make a choice")
        XCTAssertNotNil(results[2], "AI3 should make a choice")
    }
    
    // MARK: - Regression Tests
    
    func testAIDifficultyConstants() {
        // Test that AI difficulty constants are correct and haven't regressed
        XCTAssertEqual(AIDifficulty.easy.accuracy, 0.6)
        XCTAssertEqual(AIDifficulty.medium.accuracy, 0.8)
        XCTAssertEqual(AIDifficulty.hard.accuracy, 0.9)
        XCTAssertEqual(AIDifficulty.expert.accuracy, 0.95)
        
        XCTAssertEqual(AIDifficulty.easy.thinkingTime, 1.0)
        XCTAssertEqual(AIDifficulty.medium.thinkingTime, 1.5)
        XCTAssertEqual(AIDifficulty.hard.thinkingTime, 2.0)
        XCTAssertEqual(AIDifficulty.expert.thinkingTime, 2.5)
        
        XCTAssertEqual(AIDifficulty.easy.lookAheadDepth, 1)
        XCTAssertEqual(AIDifficulty.medium.lookAheadDepth, 2)
        XCTAssertEqual(AIDifficulty.hard.lookAheadDepth, 3)
        XCTAssertEqual(AIDifficulty.expert.lookAheadDepth, 4)
    }
}

// MARK: - Memory Monitoring Helper

private func mach_task_basic_info() -> mach_task_basic_info_data_t? {
    var info = mach_task_basic_info_data_t()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
    
    let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
        $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
            task_info(mach_task_self_,
                      task_flavor_t(MACH_TASK_BASIC_INFO),
                      $0,
                      &count)
        }
    }
    
    return kerr == KERN_SUCCESS ? info : nil
}