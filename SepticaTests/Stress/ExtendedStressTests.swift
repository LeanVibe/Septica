//
//  ExtendedStressTests.swift
//  SepticaTests
//
//  Extended stress testing and reliability validation
//  Tests system behavior under extreme conditions and extended usage
//

import XCTest
@testable import Septica

final class ExtendedStressTests: XCTestCase {
    
    // MARK: - Long Running Session Tests
    
    func testExtendedGameplaySession() async throws {
        // Test 30-minute continuous gameplay session
        let sessionDuration: TimeInterval = 30 * 60 // 30 minutes
        let startTime = Date()
        
        var gamesCompleted = 0
        var totalMoves = 0
        var errors: [Error] = []
        
        while Date().timeIntervalSince(startTime) < sessionDuration {
            do {
                let players = [
                    Player(name: "Endurance Player"),
                    AIPlayer(name: "Endurance AI", difficulty: .medium)
                ]
                
                let gameState = GameState(players: players)
                var moves = 0
                
                while !gameState.isGameComplete && moves < 100 {
                    if let validCard = gameState.validMovesForCurrentPlayer().first {
                        let result = gameState.playCard(validCard, by: gameState.currentPlayer!.id)
                        
                        switch result {
                        case .success:
                            moves += 1
                            totalMoves += 1
                        case .failure(let error):
                            errors.append(error)
                        }
                    }
                    
                    // Brief pause to prevent overwhelming the system
                    try await Task.sleep(nanoseconds: 10_000_000) // 10ms
                }
                
                gamesCompleted += 1
                
                // Force cleanup every 100 games
                if gamesCompleted % 100 == 0 {
                    // Trigger garbage collection
                    autoreleasepool {
                        _ = gameState.getGameStatistics()
                    }
                }
                
            } catch {
                errors.append(error)
            }
        }
        
        // Validate session results
        XCTAssertGreaterThan(gamesCompleted, 50, "Should complete at least 50 games in 30 minutes")
        XCTAssertGreaterThan(totalMoves, 200, "Should make at least 200 moves total")
        XCTAssertLessThan(errors.count, gamesCompleted / 10, "Error rate should be less than 10%")
        
        print("Extended session completed: \(gamesCompleted) games, \(totalMoves) moves, \(errors.count) errors")
    }
    
    func testMemoryStabilityOverTime() {
        // Test memory stability over extended period
        let initialMemory = getMemoryUsage()
        var gameStates: [GameState] = []
        var peakMemoryUsage: Int64 = 0
        
        // Create and play many games
        for gameNumber in 0..<200 {
            autoreleasepool {
                let players = [
                    Player(name: "Memory Test \(gameNumber)"),
                    AIPlayer(name: "AI \(gameNumber)", difficulty: .easy)
                ]
                
                let gameState = GameState(players: players)
                gameStates.append(gameState)
                
                // Play some moves
                for _ in 0..<10 {
                    if gameState.isGameComplete { break }
                    
                    if let validCard = gameState.validMovesForCurrentPlayer().first {
                        _ = gameState.playCard(validCard, by: gameState.currentPlayer!.id)
                    }
                }
                
                // Check memory every 20 games
                if gameNumber % 20 == 0 {
                    if let currentMemory = getMemoryUsage() {
                        peakMemoryUsage = max(peakMemoryUsage, currentMemory)
                    }
                    
                    // Clean up some old games to prevent unbounded growth
                    if gameStates.count > 100 {
                        gameStates.removeFirst(50)
                    }
                }
            }
        }
        
        let finalMemory = getMemoryUsage()
        
        if let initial = initialMemory, let final = finalMemory {
            let memoryIncrease = final - initial
            // Should not use more than 100MB for 200 games
            XCTAssertLessThan(memoryIncrease, 100_000_000,
                             "Memory usage should not exceed 100MB after 200 games")
        }
        
        XCTAssertLessThan(peakMemoryUsage, 150_000_000,
                         "Peak memory usage should not exceed 150MB")
    }
    
    // MARK: - High Frequency Operation Tests
    
    func testRapidGameCreationDestruction() {
        // Test rapid creation and destruction of games
        let iterations = 1000
        let startTime = Date()
        
        var creationFailures = 0
        var playFailures = 0
        
        for i in 0..<iterations {
            autoreleasepool {
                do {
                    let players = [
                        Player(name: "Rapid \(i)"),
                        Player(name: "Test \(i)")
                    ]
                    
                    let gameState = GameState(players: players)
                    
                    // Quick validation
                    XCTAssertEqual(gameState.players.count, 2)
                    XCTAssertFalse(gameState.isGameComplete)
                    
                    // Make one move
                    if let validCard = gameState.validMovesForCurrentPlayer().first {
                        let result = gameState.playCard(validCard, by: gameState.currentPlayer!.id)
                        
                        switch result {
                        case .success:
                            break
                        case .failure:
                            playFailures += 1
                        }
                    }
                    
                } catch {
                    creationFailures += 1
                }
            }
        }
        
        let totalTime = Date().timeIntervalSince(startTime)
        
        XCTAssertLessThan(creationFailures, iterations / 100, "Less than 1% creation failures allowed")
        XCTAssertLessThan(playFailures, iterations / 50, "Less than 2% play failures allowed")
        XCTAssertLessThan(totalTime, 30.0, "\(iterations) games should complete within 30 seconds")
        
        let averageTimePerGame = totalTime / Double(iterations)
        XCTAssertLessThan(averageTimePerGame, 0.05, "Average time per game should be under 50ms")
    }
    
    func testConcurrentAIDecisions() async {
        // Test many AI players making decisions concurrently
        let aiCount = 20
        var aiPlayers: [AIPlayer] = []
        
        // Create AI players
        for i in 0..<aiCount {
            let ai = AIPlayer(name: "Concurrent AI \(i)", difficulty: .medium)
            ai.hand = [
                Card(suit: .hearts, value: 7),
                Card(suit: .spades, value: 10),
                Card(suit: .clubs, value: 14)
            ]
            aiPlayers.append(ai)
        }
        
        let gameState = GameState(players: [Player(name: "Human"), aiPlayers.first!])
        
        let startTime = Date()
        
        // Make concurrent decisions
        let decisions = await withTaskGroup(of: Card?.self) { group in
            for ai in aiPlayers {
                group.addTask {
                    return await ai.chooseCard(gameState: gameState, validMoves: ai.hand)
                }
            }
            
            var results: [Card?] = []
            for await decision in group {
                results.append(decision)
            }
            return results
        }
        
        let totalTime = Date().timeIntervalSince(startTime)
        
        // Validate results
        XCTAssertEqual(decisions.count, aiCount, "Should get decision from each AI")
        
        let successfulDecisions = decisions.compactMap { $0 }
        XCTAssertEqual(successfulDecisions.count, aiCount, "All AIs should make decisions")
        
        // Should complete within reasonable time even with many concurrent AIs
        XCTAssertLessThan(totalTime, 10.0, "\(aiCount) concurrent AI decisions should complete within 10 seconds")
    }
    
    // MARK: - Resource Exhaustion Tests
    
    func testLargeHandScenarios() {
        // Test with unusually large hands (edge case)
        let largeHandSize = 32 // Entire deck
        
        let player = Player(name: "Large Hand Player")
        
        // Give player entire deck
        let fullDeck = Deck()
        for card in fullDeck.cards {
            player.addCard(card)
        }
        
        XCTAssertEqual(player.hand.count, largeHandSize)
        
        let targetCard = Card(suit: .hearts, value: 10)
        
        // Test valid moves calculation with large hand
        let startTime = Date()
        let validMoves = GameRules.validMoves(
            from: player.hand,
            against: targetCard,
            tableCardsCount: 5
        )
        let calculationTime = Date().timeIntervalSince(startTime)
        
        XCTAssertLessThan(calculationTime, 0.1, "Valid moves calculation should complete quickly even with large hand")
        XCTAssertGreaterThan(validMoves.count, 0, "Should find valid moves in large hand")
        
        // Test card operations
        let cardToRemove = player.hand.first!
        player.removeCard(cardToRemove)
        XCTAssertEqual(player.hand.count, largeHandSize - 1)
        XCTAssertFalse(player.hasCard(cardToRemove))
    }
    
    func testManyTableCards() {
        // Test with many cards on table (unusual but possible scenario)
        let players = [Player(name: "P1"), Player(name: "P2")]
        let gameState = GameState(players: players)
        
        // Add many cards to table
        for suit in CardSuit.allCases {
            for value in 7...14 {
                gameState.tableCards.append(Card(suit: suit, value: value))
            }
        }
        
        XCTAssertEqual(gameState.tableCards.count, 32) // Full deck
        
        // Test game operations still work
        XCTAssertNotNil(gameState.topTableCard)
        
        let stats = gameState.getGameStatistics()
        XCTAssertNotNil(stats)
        XCTAssertEqual(stats.playerStats.count, 2)
        
        // Test trick completion with many cards
        let winnerIndex = GameRules.determineTrickWinner(tableCards: gameState.tableCards)
        XCTAssertGreaterThanOrEqual(winnerIndex, 0)
        XCTAssertLessThan(winnerIndex, gameState.tableCards.count)
    }
    
    // MARK: - Error Recovery Tests
    
    func testRecoveryFromCorruptedGameState() {
        // Test recovery from various corrupted states
        let players = [Player(name: "Recovery Test"), AIPlayer(name: "Recovery AI", difficulty: .medium)]
        let gameState = GameState(players: players)
        
        // Test 1: Invalid current player index
        gameState.currentPlayerIndex = -1
        
        // Should handle gracefully
        XCTAssertNil(gameState.currentPlayer)
        let validMoves = gameState.validMovesForCurrentPlayer()
        XCTAssertEqual(validMoves.count, 0)
        
        // Reset to valid state
        gameState.currentPlayerIndex = 0
        XCTAssertNotNil(gameState.currentPlayer)
        
        // Test 2: Out of bounds current player index
        gameState.currentPlayerIndex = 10
        XCTAssertNil(gameState.currentPlayer)
        
        // Reset to valid state
        gameState.currentPlayerIndex = 0
        
        // Test 3: Empty hands but game not complete
        players[0].hand.removeAll()
        players[1].hand.removeAll()
        
        // Game should recognize completion
        if gameState.deck.isEmpty {
            XCTAssertTrue(gameState.isGameComplete)
        }
    }
    
    func testNetworkSimulatedFailures() {
        // Test handling of simulated network failures (for future multiplayer)
        // This tests the robustness of the underlying systems
        
        let players = [Player(name: "Network Test 1"), Player(name: "Network Test 2")]
        let gameState = GameState(players: players)
        
        var successfulOperations = 0
        var failedOperations = 0
        
        // Simulate intermittent failures
        for i in 0..<100 {
            let shouldSimulateFailure = (i % 7 == 0) // Fail every 7th operation
            
            if shouldSimulateFailure {
                // Simulate operation failure - for now just skip
                failedOperations += 1
                continue
            }
            
            // Perform normal operation
            if !gameState.isGameComplete {
                if let validCard = gameState.validMovesForCurrentPlayer().first {
                    let result = gameState.playCard(validCard, by: gameState.currentPlayer!.id)
                    
                    switch result {
                    case .success:
                        successfulOperations += 1
                    case .failure:
                        failedOperations += 1
                    }
                }
            } else {
                // Start new game
                gameState.setupNewGame()
                successfulOperations += 1
            }
        }
        
        XCTAssertGreaterThan(successfulOperations, 70, "Should have many successful operations despite failures")
        XCTAssertGreaterThan(failedOperations, 10, "Should have simulated some failures")
    }
    
    // MARK: - Performance Degradation Tests
    
    func testPerformanceDegradationOverTime() {
        // Test that performance doesn't degrade over time
        var executionTimes: [TimeInterval] = []
        
        for gameNumber in 0..<50 {
            let startTime = Date()
            
            autoreleasepool {
                let players = [
                    Player(name: "Perf Test \(gameNumber)"),
                    AIPlayer(name: "AI \(gameNumber)", difficulty: .medium)
                ]
                
                let gameState = GameState(players: players)
                
                // Play a fixed number of moves
                for _ in 0..<20 {
                    if gameState.isGameComplete { break }
                    
                    if let validCard = gameState.validMovesForCurrentPlayer().first {
                        _ = gameState.playCard(validCard, by: gameState.currentPlayer!.id)
                    }
                }
            }
            
            let executionTime = Date().timeIntervalSince(startTime)
            executionTimes.append(executionTime)
        }
        
        // Analyze performance trend
        let firstTenAverage = Array(executionTimes[0..<10]).reduce(0, +) / 10.0
        let lastTenAverage = Array(executionTimes[40..<50]).reduce(0, +) / 10.0
        
        // Performance should not degrade significantly
        let degradationRatio = lastTenAverage / firstTenAverage
        XCTAssertLessThan(degradationRatio, 1.5, "Performance should not degrade by more than 50% over time")
        
        // No execution should take extremely long
        let maxExecutionTime = executionTimes.max() ?? 0
        XCTAssertLessThan(maxExecutionTime, 2.0, "No single game should take longer than 2 seconds")
    }
    
    func testCPUIntensiveOperations() {
        // Test CPU-intensive operations don't block the system
        let iterations = 1000
        let startTime = Date()
        
        var totalCalculations = 0
        
        for _ in 0..<iterations {
            autoreleasepool {
                let hand = Array(0..<4).flatMap { suit in
                    Array(7...14).map { value in
                        Card(suit: CardSuit(rawValue: suit) ?? .hearts, value: value)
                    }
                }
                
                let targetCard = Card(suit: .hearts, value: 10)
                
                // Perform intensive calculations
                for tableCount in 0..<20 {
                    let validMoves = GameRules.validMoves(
                        from: hand,
                        against: targetCard,
                        tableCardsCount: tableCount
                    )
                    
                    totalCalculations += validMoves.count
                    
                    // Calculate points for all moves
                    let points = GameRules.calculatePoints(from: validMoves)
                    totalCalculations += points
                    
                    // Check beating logic
                    for card in validMoves {
                        if GameRules.canBeat(attackingCard: card, targetCard: targetCard, tableCardsCount: tableCount) {
                            totalCalculations += 1
                        }
                    }
                }
            }
        }
        
        let totalTime = Date().timeIntervalSince(startTime)
        
        XCTAssertGreaterThan(totalCalculations, 0, "Should perform calculations")
        XCTAssertLessThan(totalTime, 10.0, "CPU-intensive operations should complete within 10 seconds")
        
        let calculationsPerSecond = Double(totalCalculations) / totalTime
        XCTAssertGreaterThan(calculationsPerSecond, 1000, "Should maintain good calculation throughput")
    }
    
    // MARK: - Memory Pressure Tests
    
    func testBehaviorUnderMemoryPressure() {
        // Simulate memory pressure conditions
        var largeObjects: [Data] = []
        let initialMemory = getMemoryUsage()
        
        // Create memory pressure
        for _ in 0..<100 {
            let largeData = Data(count: 1024 * 1024) // 1MB each
            largeObjects.append(largeData)
        }
        
        let pressureMemory = getMemoryUsage()
        
        // Try to perform game operations under memory pressure
        var successfulOperations = 0
        
        for _ in 0..<20 {
            autoreleasepool {
                let players = [Player(name: "Pressure Test"), AIPlayer(name: "AI", difficulty: .easy)]
                let gameState = GameState(players: players)
                
                // Perform basic operations
                if let validCard = gameState.validMovesForCurrentPlayer().first {
                    let result = gameState.playCard(validCard, by: gameState.currentPlayer!.id)
                    
                    switch result {
                    case .success:
                        successfulOperations += 1
                    case .failure:
                        break
                    }
                }
            }
        }
        
        // Clean up memory pressure
        largeObjects.removeAll()
        
        let finalMemory = getMemoryUsage()
        
        // Validate results
        XCTAssertGreaterThan(successfulOperations, 15, "Should maintain functionality under memory pressure")
        
        if let initial = initialMemory, let pressure = pressureMemory, let final = finalMemory {
            XCTAssertGreaterThan(pressure, initial, "Should have created memory pressure")
            XCTAssertLessThan(final, pressure, "Should have cleaned up memory pressure")
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
    
    // MARK: - Reliability Tests
    
    func testSystemRecoveryAfterCrash() {
        // Test system behavior after simulated crashes
        var recoveryTests = 0
        var successfulRecoveries = 0
        
        for testCase in 0..<10 {
            recoveryTests += 1
            
            do {
                // Simulate various crash scenarios
                let players = [Player(name: "Recovery \(testCase)"), AIPlayer(name: "AI", difficulty: .hard)]
                let gameState = GameState(players: players)
                
                // Simulate crash during game
                if testCase % 3 == 0 {
                    // Simulate crash during card play
                    gameState.currentPlayerIndex = -1  // Invalid state
                }
                
                // Attempt recovery
                if gameState.currentPlayerIndex < 0 || gameState.currentPlayerIndex >= gameState.players.count {
                    gameState.currentPlayerIndex = 0  // Reset to valid state
                }
                
                // Verify system is recoverable
                XCTAssertNotNil(gameState.currentPlayer)
                let validMoves = gameState.validMovesForCurrentPlayer()
                XCTAssertGreaterThanOrEqual(validMoves.count, 0)
                
                successfulRecoveries += 1
                
            } catch {
                // Recovery failed
                XCTFail("Recovery test \(testCase) failed: \(error)")
            }
        }
        
        XCTAssertEqual(recoveryTests, successfulRecoveries, "All recovery tests should succeed")
    }
}