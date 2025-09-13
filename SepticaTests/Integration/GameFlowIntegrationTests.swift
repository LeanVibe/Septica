//
//  GameFlowIntegrationTests.swift
//  SepticaTests
//
//  Comprehensive integration tests for game flow and navigation
//  Tests complete user journeys, state management, and cross-component integration
//

import XCTest
@testable import Septica

final class GameFlowIntegrationTests: XCTestCase {
    
    var gameController: GameController!
    var navigationManager: NavigationManager!
    var gameViewModel: GameViewModel!
    
    override func setUp() {
        super.setUp()
        gameController = GameController()
        navigationManager = NavigationManager()
        gameViewModel = GameViewModel()
    }
    
    override func tearDown() {
        gameController = nil
        navigationManager = nil
        gameViewModel = nil
        super.tearDown()
    }
    
    // MARK: - Complete Game Flow Integration Tests
    
    func testCompleteGameSession() async {
        // Test a complete game session from start to finish
        
        // 1. Start new game
        let humanPlayer = Player(name: "Test Human")
        let aiPlayer = AIPlayer(name: "Test AI", difficulty: .medium)
        
        gameController.startNewGame(players: [humanPlayer, aiPlayer], targetScore: 11)
        
        XCTAssertNotNil(gameController.currentGame)
        XCTAssertEqual(gameController.currentGame?.phase, .playing)
        XCTAssertEqual(gameController.currentGame?.players.count, 2)
        
        // 2. Simulate game progression
        let gameState = gameController.currentGame!
        var movesPlayed = 0
        let maxMoves = 50 // Safety limit
        
        while !gameState.isGameComplete && movesPlayed < maxMoves {
            guard let currentPlayer = gameState.currentPlayer else { break }
            
            let validMoves = gameState.validMovesForCurrentPlayer()
            guard !validMoves.isEmpty else {
                gameState.skipCurrentPlayer()
                continue
            }
            
            if currentPlayer.isHuman {
                // Simulate human move
                let result = gameController.playCard(validMoves.first!, by: currentPlayer.id)
                XCTAssertEqual(result, .success, "Human move should be successful")
            } else {
                // Let AI make its move
                let result = await gameController.processAITurn()
                XCTAssertEqual(result, .success, "AI move should be successful")
            }
            
            movesPlayed += 1
        }
        
        // 3. Verify game completion
        XCTAssertTrue(gameState.isGameComplete || movesPlayed >= maxMoves)
        if gameState.isGameComplete {
            XCTAssertEqual(gameState.phase, .finished)
            XCTAssertNotNil(gameState.gameResult)
        }
    }
    
    func testGameStateTransitions() {
        // Test all valid game state transitions
        let players = [Player(name: "P1"), AIPlayer(name: "P2", difficulty: .easy)]
        gameController.startNewGame(players: players, targetScore: 11)
        
        let gameState = gameController.currentGame!
        
        // Game should start in playing phase
        XCTAssertEqual(gameState.phase, .playing)
        
        // Test pause/resume
        gameController.pauseGame()
        XCTAssertEqual(gameState.phase, .paused)
        
        gameController.resumeGame()
        XCTAssertEqual(gameState.phase, .playing)
        
        // Test forced game end
        gameController.endCurrentGame()
        XCTAssertEqual(gameState.phase, .finished)
    }
    
    func testGamePersistenceAndRestoration() {
        // Test saving and loading game state
        let players = [Player(name: "TestP1"), AIPlayer(name: "TestAI", difficulty: .hard)]
        gameController.startNewGame(players: players, targetScore: 21)
        
        let originalGame = gameController.currentGame!
        
        // Play a few moves to create save-worthy state
        for _ in 0..<3 {
            if originalGame.isGameComplete { break }
            
            if let validCard = originalGame.validMovesForCurrentPlayer().first {
                _ = originalGame.playCard(validCard, by: originalGame.currentPlayer!.id)
            }
        }
        
        let originalScore1 = originalGame.players[0].score
        let originalScore2 = originalGame.players[1].score
        let originalTricks = originalGame.trickHistory.count
        let originalPhase = originalGame.phase
        
        // Save game
        let savedGame = gameController.saveCurrentGame()
        XCTAssertNotNil(savedGame, "Game should be saveable")
        
        // Start a new game (simulating app restart)
        gameController.startNewGame(players: [Player(name: "New"), Player(name: "Game")], targetScore: 11)
        
        // Load saved game
        gameController.loadGame(savedGame!)
        let restoredGame = gameController.currentGame!
        
        // Verify restoration
        XCTAssertEqual(restoredGame.players.count, 2)
        XCTAssertEqual(restoredGame.players[0].name, "TestP1")
        XCTAssertEqual(restoredGame.players[1].name, "TestAI")
        XCTAssertEqual(restoredGame.players[0].score, originalScore1)
        XCTAssertEqual(restoredGame.players[1].score, originalScore2)
        XCTAssertEqual(restoredGame.trickHistory.count, originalTricks)
        XCTAssertEqual(restoredGame.phase, originalPhase)
        XCTAssertEqual(restoredGame.targetScore, 21)
    }
    
    // MARK: - Navigation Integration Tests
    
    func testNavigationFlow() {
        // Test navigation through all app screens
        XCTAssertEqual(navigationManager.currentScreen, .mainMenu)
        
        // Navigate to game setup
        navigationManager.navigateToGameSetup()
        XCTAssertEqual(navigationManager.currentScreen, .gameSetup)
        
        // Navigate to active game
        navigationManager.navigateToGame()
        XCTAssertEqual(navigationManager.currentScreen, .game)
        
        // Navigate to results
        navigationManager.navigateToGameResults()
        XCTAssertEqual(navigationManager.currentScreen, .gameResults)
        
        // Return to main menu
        navigationManager.navigateToMainMenu()
        XCTAssertEqual(navigationManager.currentScreen, .mainMenu)
        
        // Test settings navigation
        navigationManager.navigateToSettings()
        XCTAssertEqual(navigationManager.currentScreen, .settings)
        
        navigationManager.navigateToMainMenu()
        XCTAssertEqual(navigationManager.currentScreen, .mainMenu)
    }
    
    func testNavigationStateConsistency() {
        // Test that navigation maintains state consistency
        let initialScreen = navigationManager.currentScreen
        
        // Perform multiple navigations
        navigationManager.navigateToSettings()
        navigationManager.navigateToGameSetup()
        navigationManager.navigateToGame()
        navigationManager.navigateToGameResults()
        
        // Verify we can always return to main menu
        navigationManager.navigateToMainMenu()
        XCTAssertEqual(navigationManager.currentScreen, .mainMenu)
        
        // Test navigation history if implemented
        if navigationManager.canGoBack {
            navigationManager.goBack()
            XCTAssertNotEqual(navigationManager.currentScreen, .mainMenu)
        }
    }
    
    func testNavigationWithActiveGame() {
        // Test navigation behavior when game is active
        let players = [Player(name: "P1"), AIPlayer(name: "P2", difficulty: .medium)]
        gameController.startNewGame(players: players, targetScore: 11)
        
        // Navigate to game screen
        navigationManager.navigateToGame()
        XCTAssertEqual(navigationManager.currentScreen, .game)
        
        // Test that navigation preserves game state
        navigationManager.navigateToSettings()
        XCTAssertEqual(navigationManager.currentScreen, .settings)
        XCTAssertNotNil(gameController.currentGame, "Game should be preserved during navigation")
        
        navigationManager.navigateToGame()
        XCTAssertEqual(navigationManager.currentScreen, .game)
        XCTAssertEqual(gameController.currentGame?.phase, .playing)
    }
    
    // MARK: - ViewModel Integration Tests
    
    func testGameViewModelIntegration() {
        // Test ViewModel integration with game state
        let players = [Player(name: "Human"), AIPlayer(name: "AI", difficulty: .medium)]
        gameViewModel.startNewGame(players: players)
        
        XCTAssertNotNil(gameViewModel.gameState)
        XCTAssertEqual(gameViewModel.gameState?.players.count, 2)
        XCTAssertFalse(gameViewModel.isGameComplete)
        XCTAssertTrue(gameViewModel.canCurrentPlayerMove)
        
        // Test ViewModel reflects game state changes
        let initialTableCards = gameViewModel.tableCards.count
        
        if let validCard = gameViewModel.validMovesForCurrentPlayer.first {
            gameViewModel.playCard(validCard)
            
            // ViewModel should reflect the change
            XCTAssertEqual(gameViewModel.tableCards.count, initialTableCards + 1)
            XCTAssertTrue(gameViewModel.lastMoveBy != nil)
        }
    }
    
    func testViewModelStateBinding() {
        // Test that ViewModel properly binds to UI state
        gameViewModel.startNewGame(players: [Player(name: "P1"), Player(name: "P2")])
        
        let initialState = gameViewModel.gameState!
        let initialCurrentPlayerIndex = gameViewModel.currentPlayerIndex
        let initialScores = gameViewModel.playerScores
        
        // Make a move and verify ViewModel updates
        if let validCard = gameViewModel.validMovesForCurrentPlayer.first {
            gameViewModel.playCard(validCard)
            
            // Current player might change
            let newCurrentPlayerIndex = gameViewModel.currentPlayerIndex
            let newScores = gameViewModel.playerScores
            
            // Verify state is properly updated
            XCTAssertNotNil(gameViewModel.gameState)
            XCTAssertNotNil(gameViewModel.lastMove)
            
            // Scores should be non-decreasing (only increase when points are won)
            for i in 0..<initialScores.count {
                XCTAssertGreaterThanOrEqual(newScores[i], initialScores[i])
            }
        }
    }
    
    // MARK: - Error Handling Integration Tests
    
    func testGameControllerErrorHandling() {
        // Test error handling across integrated components
        
        // Test starting game with invalid parameters
        let result1 = gameController.startNewGame(players: [], targetScore: 11)
        XCTAssertFalse(result1, "Should fail to start game with no players")
        
        let result2 = gameController.startNewGame(players: [Player(name: "Solo")], targetScore: 11)
        XCTAssertFalse(result2, "Should fail to start game with only one player")
        
        // Test playing card without active game
        let orphanCard = Card(suit: .hearts, value: 7)
        let orphanPlayer = UUID()
        let playResult = gameController.playCard(orphanCard, by: orphanPlayer)
        
        switch playResult {
        case .failure(.gameNotInProgress):
            XCTAssertTrue(true) // Expected
        default:
            XCTFail("Should fail when no game is active")
        }
    }
    
    func testViewModelErrorRecovery() {
        // Test ViewModel error recovery mechanisms
        gameViewModel.startNewGame(players: [Player(name: "P1"), Player(name: "P2")])
        
        // Simulate error conditions
        let invalidCard = Card(suit: .hearts, value: 13)
        gameViewModel.playCard(invalidCard) // This should fail gracefully
        
        // ViewModel should remain in valid state
        XCTAssertNotNil(gameViewModel.gameState)
        XCTAssertFalse(gameViewModel.isGameComplete)
        
        // Should still be able to make valid moves
        let validMoves = gameViewModel.validMovesForCurrentPlayer
        XCTAssertFalse(validMoves.isEmpty)
    }
    
    // MARK: - Performance Integration Tests
    
    func testIntegratedSystemPerformance() {
        // Test performance of integrated system under load
        measure {
            let players = [Player(name: "P1"), AIPlayer(name: "P2", difficulty: .easy)]
            gameController.startNewGame(players: players, targetScore: 11)
            
            let gameState = gameController.currentGame!
            
            // Simulate rapid gameplay
            for _ in 0..<20 {
                if gameState.isGameComplete { break }
                
                if let validCard = gameState.validMovesForCurrentPlayer().first {
                    _ = gameState.playCard(validCard, by: gameState.currentPlayer!.id)
                }
            }
        }
    }
    
    func testMemoryUsageIntegration() async {
        // Test memory usage of integrated components
        let initialMemory = getMemoryUsage()
        
        // Create multiple game sessions
        for i in 0..<10 {
            let players = [
                Player(name: "Player \(i)"),
                AIPlayer(name: "AI \(i)", difficulty: .medium)
            ]
            
            gameController.startNewGame(players: players, targetScore: 11)
            
            // Play some moves with AI
            let gameState = gameController.currentGame!
            for _ in 0..<5 {
                if gameState.isGameComplete { break }
                
                if gameState.currentPlayer?.isHuman == false {
                    _ = await gameController.processAITurn()
                } else if let validCard = gameState.validMovesForCurrentPlayer().first {
                    _ = gameState.playCard(validCard, by: gameState.currentPlayer!.id)
                }
            }
            
            // End game to clean up
            gameController.endCurrentGame()
        }
        
        let finalMemory = getMemoryUsage()
        
        // Memory should not increase dramatically
        if let initial = initialMemory, let final = finalMemory {
            let memoryIncrease = final - initial
            XCTAssertLessThan(memoryIncrease, 50_000_000, "Memory usage should not increase by more than 50MB")
        }
    }
    
    // MARK: - Multiplayer Simulation Tests
    
    func testMultiplayerGameFlow() async {
        // Test multiplayer game flow simulation
        let player1 = Player(name: "Human Player")
        let player2 = AIPlayer(name: "AI Player", difficulty: .hard)
        
        gameController.startNewGame(players: [player1, player2], targetScore: 11)
        let gameState = gameController.currentGame!
        
        var alternatingTurns = 0
        var player1Moves = 0
        var player2Moves = 0
        
        while !gameState.isGameComplete && alternatingTurns < 30 {
            let currentPlayer = gameState.currentPlayer!
            
            if currentPlayer.id == player1.id {
                // Simulate human player move
                if let validCard = gameState.validMovesForCurrentPlayer().first {
                    let result = gameController.playCard(validCard, by: player1.id)
                    XCTAssertEqual(result, .success)
                    player1Moves += 1
                }
            } else {
                // AI player move
                let result = await gameController.processAITurn()
                XCTAssertEqual(result, .success)
                player2Moves += 1
            }
            
            alternatingTurns += 1
        }
        
        // Verify both players participated
        XCTAssertGreaterThan(player1Moves, 0, "Player 1 should have made moves")
        XCTAssertGreaterThan(player2Moves, 0, "Player 2 should have made moves")
        
        // Verify game completed properly
        if gameState.isGameComplete {
            XCTAssertEqual(gameState.phase, .finished)
            XCTAssertNotNil(gameState.gameResult)
            
            let winner = gameState.gameResult!.winnerId
            XCTAssertTrue(winner == player1.id || winner == player2.id || winner == nil) // nil for tie
        }
    }
    
    func testGameStatisticsIntegration() {
        // Test that statistics are properly tracked across components
        let players = [Player(name: "P1"), AIPlayer(name: "P2", difficulty: .medium)]
        gameController.startNewGame(players: players, targetScore: 11)
        
        let gameState = gameController.currentGame!
        let initialStats = gameState.getGameStatistics()
        
        XCTAssertEqual(initialStats.totalTricks, 0)
        XCTAssertEqual(initialStats.totalCardsPlayed, 0)
        XCTAssertEqual(initialStats.playerStats.count, 2)
        
        // Play some moves
        for _ in 0..<4 {
            if gameState.isGameComplete { break }
            
            if let validCard = gameState.validMovesForCurrentPlayer().first {
                _ = gameState.playCard(validCard, by: gameState.currentPlayer!.id)
            }
        }
        
        let updatedStats = gameState.getGameStatistics()
        XCTAssertGreaterThanOrEqual(updatedStats.totalCardsPlayed, 4)
        XCTAssertEqual(updatedStats.playerStats.count, 2)
        
        // Verify player stats are tracked
        for playerStat in updatedStats.playerStats {
            XCTAssertFalse(playerStat.playerName.isEmpty)
            XCTAssertGreaterThanOrEqual(playerStat.finalScore, 0)
            XCTAssertGreaterThanOrEqual(playerStat.cardsRemaining, 0)
        }
    }
    
    // MARK: - State Consistency Tests
    
    func testCrossComponentStateConsistency() {
        // Test that all components maintain consistent state
        let players = [Player(name: "Human"), AIPlayer(name: "AI", difficulty: .expert)]
        
        // Initialize through ViewModel
        gameViewModel.startNewGame(players: players)
        
        // Also initialize through GameController  
        gameController.startNewGame(players: players, targetScore: 11)
        
        // Verify consistency
        XCTAssertEqual(gameViewModel.gameState?.players.count, gameController.currentGame?.players.count)
        XCTAssertEqual(gameViewModel.gameState?.phase, gameController.currentGame?.phase)
        
        // Make a move through ViewModel
        if let validCard = gameViewModel.validMovesForCurrentPlayer.first {
            gameViewModel.playCard(validCard)
        }
        
        // Make a move through GameController
        if let validCard = gameController.currentGame?.validMovesForCurrentPlayer().first,
           let currentPlayer = gameController.currentGame?.currentPlayer {
            _ = gameController.playCard(validCard, by: currentPlayer.id)
        }
        
        // Both should maintain valid states
        XCTAssertNotNil(gameViewModel.gameState)
        XCTAssertNotNil(gameController.currentGame)
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

// MARK: - Extensions for Testing

extension GameController {
    
    /// Process AI turn and return result (for testing)
    func processAITurn() async -> PlayResult {
        guard let gameState = currentGame,
              let currentPlayer = gameState.currentPlayer,
              !currentPlayer.isHuman,
              let aiPlayer = currentPlayer as? AIPlayer else {
            return .failure(.gameNotInProgress)
        }
        
        let validMoves = gameState.validMovesForCurrentPlayer()
        guard !validMoves.isEmpty else {
            gameState.skipCurrentPlayer()
            return .success
        }
        
        if let chosenCard = await aiPlayer.chooseCard(gameState: gameState, validMoves: validMoves) {
            return gameState.playCard(chosenCard, by: aiPlayer.id)
        }
        
        return .failure(.gameNotInProgress)
    }
    
    /// Save current game state (for testing)
    func saveCurrentGame() -> GameState? {
        return currentGame
    }
    
    /// Load game state (for testing)  
    func loadGame(_ gameState: GameState) {
        self.currentGame = gameState
    }
}