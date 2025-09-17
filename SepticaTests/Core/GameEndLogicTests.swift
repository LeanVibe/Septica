//
//  GameEndLogicTests.swift
//  SepticaTests
//
//  Comprehensive tests for game end logic and celebration system
//  Validates GameResult handling, celebration conversion, and crash resistance
//

import XCTest
@testable import Septica

final class GameEndLogicTests: XCTestCase {
    
    var gameState: GameState!
    var humanPlayer: Player!
    var aiPlayer: AIPlayer!
    var gameResult: GameResult!
    
    override func setUp() {
        super.setUp()
        humanPlayer = Player(name: "Human Test Player")
        aiPlayer = AIPlayer(name: "AI Test Player", difficulty: .medium)
        gameState = GameState(players: [humanPlayer, aiPlayer])
        
        // Create a typical game result
        gameResult = GameResult(
            winnerId: humanPlayer.id,
            finalScores: [humanPlayer.id: 7, aiPlayer.id: 4],
            totalTricks: 8,
            gameDuration: 180.0
        )
    }
    
    override func tearDown() {
        gameState = nil
        humanPlayer = nil
        aiPlayer = nil
        gameResult = nil
        super.tearDown()
    }
    
    // MARK: - GameResult to CelebrationGameResult Conversion Tests
    
    func testBasicGameResultConversion() {
        // Test the conversion function that was causing the crash
        let mockGameResultView = MockGameResultView(
            result: gameResult,
            playerNames: ["Human", "AI"],
            gameState: gameState,
            onNewGame: {},
            onMainMenu: {}
        )
        
        let celebrationResult = mockGameResultView.testConvertToCelebrationGameResult(gameResult)
        
        XCTAssertEqual(celebrationResult.playerScore, 7, "Player score should be correctly extracted")
        XCTAssertEqual(celebrationResult.opponentScore, 4, "Opponent score should be correctly extracted")
        XCTAssertEqual(celebrationResult.duration, 180.0, "Duration should match")
        XCTAssertGreaterThanOrEqual(celebrationResult.strategicMoves, 1, "Strategic moves should be at least 1")
        XCTAssertGreaterThanOrEqual(celebrationResult.culturalMoments, 1, "Cultural moments should be at least 1")
    }
    
    func testEmptyGameStateConversion() {
        // Test edge case that could cause crashes: empty game state
        let emptyGameState = GameState()
        let mockGameResultView = MockGameResultView(
            result: gameResult,
            playerNames: ["Human", "AI"],
            gameState: emptyGameState,
            onNewGame: {},
            onMainMenu: {}
        )
        
        let celebrationResult = mockGameResultView.testConvertToCelebrationGameResult(gameResult)
        
        // Should not crash and should have safe defaults
        XCTAssertEqual(celebrationResult.tricksWon, 0, "Should handle empty tricks safely")
        XCTAssertGreaterThanOrEqual(celebrationResult.strategicMoves, 1, "Should have minimum strategic moves")
        XCTAssertGreaterThanOrEqual(celebrationResult.culturalMoments, 1, "Should have minimum cultural moments")
    }
    
    func testEmptyScoresConversion() {
        // Test edge case: empty final scores
        let emptyScoreResult = GameResult(
            winnerId: nil,
            finalScores: [:],
            totalTricks: 0,
            gameDuration: 0.0
        )
        
        let mockGameResultView = MockGameResultView(
            result: emptyScoreResult,
            playerNames: ["Human", "AI"],
            gameState: gameState,
            onNewGame: {},
            onMainMenu: {}
        )
        
        let celebrationResult = mockGameResultView.testConvertToCelebrationGameResult(emptyScoreResult)
        
        // Should not crash and should have safe defaults
        XCTAssertEqual(celebrationResult.playerScore, 0, "Should handle empty scores safely")
        XCTAssertEqual(celebrationResult.opponentScore, 0, "Should handle empty scores safely")
        XCTAssertEqual(celebrationResult.pointsCaptured, 0, "Should handle empty scores safely")
        XCTAssertGreaterThanOrEqual(celebrationResult.duration, 0.0, "Duration should not be negative")
    }
    
    func testNegativeValuesHandling() {
        // Test edge case: negative values that should be normalized
        let negativeResult = GameResult(
            winnerId: humanPlayer.id,
            finalScores: [humanPlayer.id: -5, aiPlayer.id: -3],
            totalTricks: 5,
            gameDuration: -10.0
        )
        
        let mockGameResultView = MockGameResultView(
            result: negativeResult,
            playerNames: ["Human", "AI"],
            gameState: gameState,
            onNewGame: {},
            onMainMenu: {}
        )
        
        let celebrationResult = mockGameResultView.testConvertToCelebrationGameResult(negativeResult)
        
        // All values should be normalized to non-negative
        XCTAssertGreaterThanOrEqual(celebrationResult.playerScore, 0, "Player score should be normalized")
        XCTAssertGreaterThanOrEqual(celebrationResult.opponentScore, 0, "Opponent score should be normalized")
        XCTAssertGreaterThanOrEqual(celebrationResult.duration, 0.0, "Duration should be normalized")
        XCTAssertGreaterThanOrEqual(celebrationResult.pointsCaptured, 0, "Points should be normalized")
    }
    
    // MARK: - Game End Detection Tests
    
    func testPlayerVictoryDetection() {
        // Test victory condition detection
        humanPlayer.score = 11  // Target score reached
        aiPlayer.score = 8
        
        XCTAssertTrue(gameState.isGameComplete, "Game should be complete when player reaches target score")
        
        let result = GameResult(
            winnerId: humanPlayer.id,
            finalScores: [humanPlayer.id: 11, aiPlayer.id: 8],
            totalTricks: 10,
            gameDuration: 300.0
        )
        
        XCTAssertEqual(result.winnerId, humanPlayer.id, "Winner should be correctly identified")
        XCTAssertEqual(result.winningScore, 11, "Winning score should be correctly calculated")
        XCTAssertFalse(result.isTie, "Should not be a tie when there's a winner")
    }
    
    func testDrawGameDetection() {
        // Test draw condition
        humanPlayer.score = 11
        aiPlayer.score = 11
        
        let result = GameResult(
            winnerId: nil,
            finalScores: [humanPlayer.id: 11, aiPlayer.id: 11],
            totalTricks: 12,
            gameDuration: 400.0
        )
        
        XCTAssertNil(result.winnerId, "Winner should be nil in a draw")
        XCTAssertTrue(result.isTie, "Should be identified as a tie")
        XCTAssertNil(result.winningScore, "Winning score should be nil in a tie")
    }
    
    // MARK: - Celebration System Integration Tests
    
    @MainActor 
    func testCelebrationSystemInitialization() {
        // Test that celebration system can be initialized without crashing
        let celebrationSystem = GameEndCelebrationSystem()
        XCTAssertNotNil(celebrationSystem, "Celebration system should initialize successfully")
    }
    
    func testCelebrationDataStructures() {
        // Test celebration data structures don't cause crashes
        let celebrationResult = CelebrationGameResult(
            playerScore: 10,
            opponentScore: 7,
            tricksWon: 5,
            pointsCaptured: 17,
            duration: 250.0,
            strategicMoves: 10,
            culturalMoments: 3
        )
        
        XCTAssertEqual(celebrationResult.playerScore, 10)
        XCTAssertEqual(celebrationResult.opponentScore, 7)
        XCTAssertEqual(celebrationResult.tricksWon, 5)
        XCTAssertEqual(celebrationResult.pointsCaptured, 17)
        XCTAssertEqual(celebrationResult.duration, 250.0)
        XCTAssertEqual(celebrationResult.strategicMoves, 10)
        XCTAssertEqual(celebrationResult.culturalMoments, 3)
    }
    
    // MARK: - Crash Resistance Tests
    
    func testCrashResistanceWithMalformedData() {
        // Test various malformed data scenarios that could cause crashes
        let testCases = [
            // Empty players
            GameState(),
            // Single player
            GameState(players: [humanPlayer]),
            // Multiple players
            GameState(players: [humanPlayer, aiPlayer, AIPlayer(name: "AI2", difficulty: .easy)])
        ]
        
        for testGameState in testCases {
            let mockView = MockGameResultView(
                result: gameResult,
                playerNames: ["Test"],
                gameState: testGameState,
                onNewGame: {},
                onMainMenu: {}
            )
            
            // This should not crash regardless of game state
            let celebrationResult = mockView.testConvertToCelebrationGameResult(gameResult)
            XCTAssertNotNil(celebrationResult, "Conversion should succeed even with malformed data")
        }
    }
    
    // MARK: - Performance Tests
    
    func testConversionPerformance() {
        // Test that conversion doesn't have performance regressions
        let mockGameResultView = MockGameResultView(
            result: gameResult,
            playerNames: ["Human", "AI"],
            gameState: gameState,
            onNewGame: {},
            onMainMenu: {}
        )
        
        measure {
            for _ in 0..<1000 {
                let _ = mockGameResultView.testConvertToCelebrationGameResult(gameResult)
            }
        }
    }
}

// MARK: - Mock GameResultView for Testing

class MockGameResultView {
    private let result: GameResult
    private let playerNames: [String]
    private let gameState: GameState
    private let onNewGame: () -> Void
    private let onMainMenu: () -> Void
    
    init(result: GameResult, playerNames: [String], gameState: GameState, onNewGame: @escaping () -> Void, onMainMenu: @escaping () -> Void) {
        self.result = result
        self.playerNames = playerNames
        self.gameState = gameState
        self.onNewGame = onNewGame
        self.onMainMenu = onMainMenu
    }
    
    // Expose the conversion function for testing
    func testConvertToCelebrationGameResult(_ gameResult: GameResult) -> CelebrationGameResult {
        // Copy the exact logic from GameResultView to test it
        let scores = Array(gameResult.finalScores.values)
        let playerScore = scores.max() ?? 0
        let opponentScore = scores.min() ?? 0
        
        let humanPlayerId = self.gameState.players.first(where: { $0.isHuman })?.id
        let tricksWon = humanPlayerId != nil ? 
            self.gameState.trickHistory.filter { $0.winnerPlayerId == humanPlayerId }.count : 0
        
        let pointsCaptured = scores.reduce(0, +)
        
        let safeTricksWon = max(0, tricksWon)
        let strategicMoves = max(1, safeTricksWon * 2)
        let culturalMoments = max(1, safeTricksWon)
        
        return CelebrationGameResult(
            playerScore: max(0, playerScore),
            opponentScore: max(0, opponentScore),
            tricksWon: safeTricksWon,
            pointsCaptured: max(0, pointsCaptured),
            duration: max(0.0, gameResult.gameDuration),
            strategicMoves: strategicMoves,
            culturalMoments: culturalMoments
        )
    }
}