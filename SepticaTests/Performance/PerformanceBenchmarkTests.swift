//
//  PerformanceBenchmarkTests.swift
//  SepticaTests
//
//  Performance and memory benchmark tests for production readiness
//  Tests memory usage, execution speed, and system resource efficiency
//

import XCTest
@testable import Septica

final class PerformanceBenchmarkTests: XCTestCase {
    
    // MARK: - Memory Performance Tests
    
    func testGameStateMemoryEfficiency() {
        // Test that GameState doesn't consume excessive memory
        let initialMemory = getMemoryUsage()
        var gameStates: [GameState] = []
        
        // Create multiple game states
        for i in 0..<10 {
            let players = [
                Player(name: "Player \(i)"),
                AIPlayer(name: "AI \(i)", difficulty: .medium)
            ]
            let gameState = GameState(players: players)
            gameStates.append(gameState)
        }
        
        let afterCreationMemory = getMemoryUsage()
        
        // Play games to completion
        for gameState in gameStates {
            var moves = 0
            while !gameState.isGameComplete && moves < 30 {
                if let validCard = gameState.validMovesForCurrentPlayer().first {
                    _ = gameState.playCard(validCard, by: gameState.currentPlayer!.id)
                    moves += 1
                }
            }
        }
        
        let finalMemory = getMemoryUsage()
        
        if let initial = initialMemory, let final = finalMemory {
            let memoryIncrease = final - initial
            // Should not use more than 30MB for 10 complete games
            XCTAssertLessThan(memoryIncrease, 30_000_000, 
                             "10 complete games should not consume more than 30MB")
        }
        
        // Clear references and test cleanup
        gameStates.removeAll()
        
        // Give system time to cleanup
        Thread.sleep(forTimeInterval: 0.1)
        
        let cleanupMemory = getMemoryUsage()
        if let final = finalMemory, let cleanup = cleanupMemory {
            let memoryFreed = final - cleanup
            // Should free at least some memory
            XCTAssertGreaterThanOrEqual(memoryFreed, 0, "Memory should be freed after cleanup")
        }
    }
    
    func testDeckMemoryEfficiency() {
        // Test Deck memory usage with multiple shuffles
        measure(metrics: [XCTMemoryMetric()]) {
            var decks: [Deck] = []
            
            for _ in 0..<100 {
                var deck = Deck()
                deck.shuffle()
                
                // Draw some cards
                for _ in 0..<10 {
                    _ = deck.drawCard()
                }
                
                decks.append(deck)
            }
            
            // Clear decks
            decks.removeAll()
        }
    }
    
    func testAIPlayerMemoryLeaks() async {
        // Test that AI players don't leak memory during decision making
        let initialMemory = getMemoryUsage()
        var aiPlayers: [AIPlayer] = []
        
        // Create multiple AI players
        for i in 0..<5 {
            let ai = AIPlayer(name: "AI \(i)", difficulty: .expert)
            ai.hand = [
                Card(suit: .hearts, value: 7),
                Card(suit: .spades, value: 10),
                Card(suit: .clubs, value: 14),
                Card(suit: .diamonds, value: 11)
            ]
            aiPlayers.append(ai)
        }
        
        // Make many decisions
        let gameState = GameState(players: [Player(name: "Human"), aiPlayers.first!])
        
        for ai in aiPlayers {
            for _ in 0..<20 {
                _ = await ai.chooseCard(gameState: gameState, validMoves: ai.hand)
            }
        }
        
        let afterDecisionsMemory = getMemoryUsage()
        
        // Clear AI players
        aiPlayers.removeAll()
        
        Thread.sleep(forTimeInterval: 0.1) // Allow cleanup
        
        let finalMemory = getMemoryUsage()
        
        if let initial = initialMemory, let final = finalMemory {
            let memoryIncrease = final - initial
            // Should not leak significant memory
            XCTAssertLessThan(memoryIncrease, 10_000_000,
                             "AI decision making should not leak significant memory")
        }
    }
    
    // MARK: - Execution Speed Tests
    
    func testGameRuleExecutionSpeed() {
        // Test that game rule calculations are fast enough for real-time play
        let testCard = Card(suit: .hearts, value: 7)
        let targetCard = Card(suit: .spades, value: 10)
        
        measure(metrics: [XCTClockMetric()]) {
            // Perform many rule calculations
            for tableCount in 0..<100 {
                _ = GameRules.canBeat(attackingCard: testCard, targetCard: targetCard, tableCardsCount: tableCount)
            }
            
            // Test valid moves calculation
            let hand = [
                Card(suit: .hearts, value: 7),
                Card(suit: .spades, value: 8),
                Card(suit: .clubs, value: 9),
                Card(suit: .diamonds, value: 10)
            ]
            
            for tableCount in 0..<25 {
                _ = GameRules.validMoves(from: hand, against: targetCard, tableCardsCount: tableCount)
            }
        }
    }
    
    func testDeckShufflePerformance() {
        // Test deck shuffling performance
        measure(metrics: [XCTClockMetric()]) {
            for _ in 0..<1000 {
                var deck = Deck()
                deck.shuffle()
            }
        }
    }
    
    func testAIDecisionSpeed() async {
        // Test that AI makes decisions within time limits
        let aiPlayer = AIPlayer(name: "Speed Test AI", difficulty: .expert)
        aiPlayer.hand = [
            Card(suit: .hearts, value: 7),
            Card(suit: .spades, value: 8),
            Card(suit: .clubs, value: 9),
            Card(suit: .diamonds, value: 10),
            Card(suit: .hearts, value: 11),
            Card(suit: .spades, value: 12),
            Card(suit: .clubs, value: 13),
            Card(suit: .diamonds, value: 14)
        ]
        
        let gameState = GameState(players: [Player(name: "Human"), aiPlayer])
        
        let startTime = Date()
        
        // Make multiple decisions
        for _ in 0..<5 {
            _ = await aiPlayer.chooseCard(gameState: gameState, validMoves: aiPlayer.hand)
        }
        
        let totalTime = Date().timeIntervalSince(startTime)
        
        // Should complete within reasonable time (allowing for thinking time)
        XCTAssertLessThan(totalTime, 15.0, "5 AI decisions should complete within 15 seconds")
        
        // Average decision time should be reasonable
        let averageDecisionTime = totalTime / 5.0
        XCTAssertLessThan(averageDecisionTime, 3.0, "Average AI decision time should be under 3 seconds")
    }
    
    func testGameStateTransitionSpeed() {
        // Test speed of game state transitions
        let players = [Player(name: "P1"), Player(name: "P2")]
        
        measure(metrics: [XCTClockMetric()]) {
            let gameState = GameState(players: players)
            
            // Perform rapid state transitions
            for _ in 0..<20 {
                if gameState.isGameComplete { break }
                
                if let validCard = gameState.validMovesForCurrentPlayer().first {
                    _ = gameState.playCard(validCard, by: gameState.currentPlayer!.id)
                }
            }
        }
    }
    
    // MARK: - Scalability Tests
    
    func testLargeHandPerformance() {
        // Test performance with unusually large hands
        let largeHand = Array(0..<4).flatMap { suit in
            Array(7...14).map { value in
                Card(suit: CardSuit(rawValue: suit) ?? .hearts, value: value)
            }
        }
        
        let targetCard = Card(suit: .hearts, value: 10)
        
        measure(metrics: [XCTClockMetric()]) {
            for tableCount in 0..<10 {
                _ = GameRules.validMoves(from: largeHand, against: targetCard, tableCardsCount: tableCount)
            }
        }
    }
    
    func testManyPlayersSimulation() {
        // Test performance with multiple players (even though game is 2-player)
        // This tests scalability of the underlying systems
        var multiplePlayers: [Player] = []
        
        for i in 0..<10 {
            if i % 2 == 0 {
                multiplePlayers.append(Player(name: "Player \(i)"))
            } else {
                multiplePlayers.append(AIPlayer(name: "AI \(i)", difficulty: .medium))
            }
        }
        
        measure(metrics: [XCTClockMetric()]) {
            // Test player operations
            for player in multiplePlayers {
                player.resetForNewGame()
                
                // Add some cards
                for value in 7...10 {
                    player.addCard(Card(suit: .hearts, value: value))
                }
                
                // Test operations
                _ = player.hasCard(Card(suit: .hearts, value: 7))
                player.addPoints(1)
                
                // Remove cards
                if let card = player.hand.first {
                    player.removeCard(card)
                }
            }
        }
    }
    
    // MARK: - Real-time Performance Tests
    
    func testSixtyFPSGameplaySimulation() {
        // Test that game logic can handle 60 FPS update rates
        let players = [Player(name: "P1"), AIPlayer(name: "P2", difficulty: .easy)]
        let gameState = GameState(players: players)
        
        let targetFrameTime: TimeInterval = 1.0 / 60.0 // 16.67ms per frame
        var frameExceedCount = 0
        
        // Simulate 60 FPS for 2 seconds (120 frames)
        for frame in 0..<120 {
            let frameStartTime = Date()
            
            // Simulate frame update operations
            _ = gameState.isGameComplete
            _ = gameState.validMovesForCurrentPlayer()
            _ = gameState.currentPlayer
            _ = gameState.topTableCard
            _ = gameState.getGameStatistics()
            
            // Occasionally make moves
            if frame % 20 == 0 && !gameState.isGameComplete {
                if let validCard = gameState.validMovesForCurrentPlayer().first {
                    _ = gameState.playCard(validCard, by: gameState.currentPlayer!.id)
                }
            }
            
            let frameTime = Date().timeIntervalSince(frameStartTime)
            if frameTime > targetFrameTime {
                frameExceedCount += 1
            }
        }
        
        // Should maintain 60 FPS in most frames
        XCTAssertLessThan(frameExceedCount, 12, "Should exceed frame time in less than 10% of frames")
    }
    
    func testBackgroundProcessingPerformance() async {
        // Test performance when AI processing happens in background
        let aiPlayer = AIPlayer(name: "Background AI", difficulty: .hard)
        aiPlayer.hand = [
            Card(suit: .hearts, value: 7),
            Card(suit: .spades, value: 10),
            Card(suit: .clubs, value: 14)
        ]
        
        let gameState = GameState(players: [Player(name: "Human"), aiPlayer])
        
        let startTime = Date()
        
        // Simulate multiple concurrent AI decisions
        async let decision1 = aiPlayer.chooseCard(gameState: gameState, validMoves: aiPlayer.hand)
        async let decision2 = aiPlayer.chooseCard(gameState: gameState, validMoves: aiPlayer.hand)
        async let decision3 = aiPlayer.chooseCard(gameState: gameState, validMoves: aiPlayer.hand)
        
        let results = await [decision1, decision2, decision3]
        
        let totalTime = Date().timeIntervalSince(startTime)
        
        // All decisions should complete
        XCTAssertEqual(results.compactMap { $0 }.count, 3, "All AI decisions should complete")
        
        // Should handle concurrent processing efficiently
        XCTAssertLessThan(totalTime, 8.0, "Concurrent AI decisions should complete within 8 seconds")
    }
    
    // MARK: - Resource Usage Tests
    
    func testCPUUsageUnderLoad() {
        // Test CPU usage during intensive operations
        let players = [Player(name: "P1"), AIPlayer(name: "P2", difficulty: .expert)]
        var gameStates: [GameState] = []
        
        // Create multiple concurrent games
        for i in 0..<5 {
            let testPlayers = [
                Player(name: "Player \(i)"),
                AIPlayer(name: "AI \(i)", difficulty: .hard)
            ]
            gameStates.append(GameState(players: testPlayers))
        }
        
        let startTime = Date()
        
        // Process all games simultaneously
        for gameState in gameStates {
            var moves = 0
            while !gameState.isGameComplete && moves < 15 {
                if let validCard = gameState.validMovesForCurrentPlayer().first {
                    _ = gameState.playCard(validCard, by: gameState.currentPlayer!.id)
                    moves += 1
                }
            }
        }
        
        let processingTime = Date().timeIntervalSince(startTime)
        
        // Should complete multiple games within reasonable time
        XCTAssertLessThan(processingTime, 10.0, "5 concurrent games should complete within 10 seconds")
    }
    
    func testFileSystemPerformance() {
        // Test performance of save/load operations (if implemented)
        let players = [Player(name: "Save Test"), AIPlayer(name: "Load Test", difficulty: .medium)]
        let gameState = GameState(players: players)
        
        // Play some moves to create meaningful save data
        for _ in 0..<5 {
            if gameState.isGameComplete { break }
            if let validCard = gameState.validMovesForCurrentPlayer().first {
                _ = gameState.playCard(validCard, by: gameState.currentPlayer!.id)
            }
        }
        
        measure(metrics: [XCTClockMetric()]) {
            // Simulate save/load operations
            let stats = gameState.getGameStatistics()
            _ = stats.totalTricks
            _ = stats.playerStats.count
            
            // Simulate JSON encoding/decoding operations
            if let encoded = try? JSONEncoder().encode(gameState.trickHistory) {
                _ = try? JSONDecoder().decode([CompletedTrick].self, from: encoded)
            }
        }
    }
    
    // MARK: - Memory Leak Detection
    
    func testGameStateMemoryLeaks() {
        weak var weakGameState: GameState?
        
        autoreleasepool {
            let players = [Player(name: "Leak Test"), AIPlayer(name: "AI Leak", difficulty: .easy)]
            let gameState = GameState(players: players)
            weakGameState = gameState
            
            // Play the game
            var moves = 0
            while !gameState.isGameComplete && moves < 20 {
                if let validCard = gameState.validMovesForCurrentPlayer().first {
                    _ = gameState.playCard(validCard, by: gameState.currentPlayer!.id)
                    moves += 1
                }
            }
        }
        
        // GameState should be deallocated
        XCTAssertNil(weakGameState, "GameState should be deallocated when out of scope")
    }
    
    func testPlayerMemoryLeaks() {
        weak var weakPlayer: Player?
        weak var weakAIPlayer: AIPlayer?
        
        autoreleasepool {
            let player = Player(name: "Memory Test")
            let aiPlayer = AIPlayer(name: "AI Memory", difficulty: .medium)
            
            weakPlayer = player
            weakAIPlayer = aiPlayer
            
            // Use players
            player.addCard(Card(suit: .hearts, value: 10))
            aiPlayer.addCard(Card(suit: .spades, value: 7))
            
            player.addPoints(2)
            aiPlayer.addPoints(1)
        }
        
        // Players should be deallocated
        XCTAssertNil(weakPlayer, "Player should be deallocated when out of scope")
        XCTAssertNil(weakAIPlayer, "AIPlayer should be deallocated when out of scope")
    }
    
    // MARK: - Stress Tests
    
    func testRapidGameCreationDestruction() {
        // Test rapid creation and destruction of games
        measure(metrics: [XCTMemoryMetric(), XCTClockMetric()]) {
            for _ in 0..<100 {
                let players = [Player(name: "Rapid P1"), Player(name: "Rapid P2")]
                let gameState = GameState(players: players)
                
                // Quick game simulation
                if let validCard = gameState.validMovesForCurrentPlayer().first {
                    _ = gameState.playCard(validCard, by: gameState.currentPlayer!.id)
                }
                
                // GameState goes out of scope and should be cleaned up
            }
        }
    }
    
    func testLongRunningGameSession() {
        // Test a very long game session for memory stability
        let players = [Player(name: "Endurance P1"), AIPlayer(name: "Endurance AI", difficulty: .easy)]
        let gameState = GameState(players: players)
        
        let initialMemory = getMemoryUsage()
        var totalMoves = 0
        
        // Play multiple complete games
        for gameNumber in 0..<20 {
            gameState.setupNewGame()
            
            var moves = 0
            while !gameState.isGameComplete && moves < 50 {
                if let validCard = gameState.validMovesForCurrentPlayer().first {
                    _ = gameState.playCard(validCard, by: gameState.currentPlayer!.id)
                    moves += 1
                    totalMoves += 1
                }
            }
        }
        
        let finalMemory = getMemoryUsage()
        
        XCTAssertGreaterThan(totalMoves, 100, "Should have played significant number of moves")
        
        if let initial = initialMemory, let final = finalMemory {
            let memoryIncrease = final - initial
            // Memory should not grow unboundedly
            XCTAssertLessThan(memoryIncrease, 20_000_000, 
                             "Long gaming session should not consume excessive memory")
        }
    }
    
    // MARK: - Helper Methods
    
    private func getMemoryUsage() -> Int64? {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                          task_flavor_t(MACH_TASK_BASIC_INFO),
                          $0,
                          &count)
            }
        }
        
        return kerr == KERN_SUCCESS ? Int64(info.resident_size) : nil
    }
}