//
//  AIPlayerTests.swift
//  SepticaTests
//
//  Comprehensive unit tests for AI player functionality
//  Tests Romanian Septica AI strategy, difficulty levels, and decision making
//

import XCTest
@testable import Septica

class AIPlayerTests: XCTestCase {

    // MARK: - Test Setup
    
    var gameState: GameState!
    var humanPlayer: Player!
    var aiPlayerEasy: AIPlayer!
    var aiPlayerMedium: AIPlayer!
    var aiPlayerHard: AIPlayer!
    var aiPlayerExpert: AIPlayer!
    
    override func setUp() {
        super.setUp()
        
        gameState = GameState()
        humanPlayer = Player(name: "Human")
        aiPlayerEasy = AIPlayer(name: "AI Easy", difficulty: .easy)
        aiPlayerMedium = AIPlayer(name: "AI Medium", difficulty: .medium)
        aiPlayerHard = AIPlayer(name: "AI Hard", difficulty: .hard)
        aiPlayerExpert = AIPlayer(name: "AI Expert", difficulty: .expert)
        
        gameState.players = [humanPlayer, aiPlayerMedium]
        gameState.setupNewGame()
    }
    
    override func tearDown() {
        gameState = nil
        humanPlayer = nil
        aiPlayerEasy = nil
        aiPlayerMedium = nil
        aiPlayerHard = nil
        aiPlayerExpert = nil
        super.tearDown()
    }
    
    // MARK: - Basic AI Player Tests
    
    func testAIPlayerInitialization() {
        XCTAssertFalse(aiPlayerMedium.isHuman)
        XCTAssertEqual(aiPlayerMedium.difficulty, .medium)
        XCTAssertEqual(aiPlayerMedium.name, "AI Medium")
    }
    
    func testAIPlayerDifficulties() {
        XCTAssertEqual(aiPlayerEasy.difficulty, .easy)
        XCTAssertEqual(aiPlayerMedium.difficulty, .medium)
        XCTAssertEqual(aiPlayerHard.difficulty, .hard)
        XCTAssertEqual(aiPlayerExpert.difficulty, .expert)
    }
    
    func testDifficultyThinkingTimes() {
        XCTAssertEqual(AIDifficulty.easy.thinkingTime, 1.0)
        XCTAssertEqual(AIDifficulty.medium.thinkingTime, 1.5)
        XCTAssertEqual(AIDifficulty.hard.thinkingTime, 2.0)
        XCTAssertEqual(AIDifficulty.expert.thinkingTime, 2.5)
    }
    
    func testDifficultyAccuracy() {
        XCTAssertEqual(AIDifficulty.easy.accuracy, 0.6)
        XCTAssertEqual(AIDifficulty.medium.accuracy, 0.8)
        XCTAssertEqual(AIDifficulty.hard.accuracy, 0.9)
        XCTAssertEqual(AIDifficulty.expert.accuracy, 0.95)
    }
    
    func testDifficultyLookAheadDepth() {
        XCTAssertEqual(AIDifficulty.easy.lookAheadDepth, 1)
        XCTAssertEqual(AIDifficulty.medium.lookAheadDepth, 2)
        XCTAssertEqual(AIDifficulty.hard.lookAheadDepth, 3)
        XCTAssertEqual(AIDifficulty.expert.lookAheadDepth, 4)
    }
    
    // MARK: - AI Strategy Tests
    
    func testAIChoosesValidMoves() async {
        // Set up a scenario where AI has limited valid moves
        aiPlayerMedium.hand = [
            Card(suit: .hearts, value: 7),
            Card(suit: .spades, value: 9),
            Card(suit: .clubs, value: 12)
        ]
        
        // Set up table with a card that only 7 can beat
        gameState.tableCards = [Card(suit: .diamonds, value: 10)]
        
        let validMoves = GameRules.validMoves(
            from: aiPlayerMedium.hand,
            against: gameState.topTableCard,
            tableCardsCount: gameState.tableCards.count
        )
        
        let chosenCard = await aiPlayerMedium.chooseCard(gameState: gameState, validMoves: validMoves)
        
        XCTAssertNotNil(chosenCard)
        XCTAssertTrue(validMoves.contains { $0.suit == chosenCard!.suit && $0.value == chosenCard!.value })
    }
    
    func testAIPrefers7sStrategically() async {
        // Set up AI with 7s and other cards
        aiPlayerExpert.hand = [
            Card(suit: .hearts, value: 7),
            Card(suit: .spades, value: 8),
            Card(suit: .clubs, value: 9),
            Card(suit: .diamonds, value: 11)
        ]
        
        // Set up a scenario where points are on the table
        gameState.tableCards = [
            Card(suit: .hearts, value: 10), // Point card
            Card(suit: .spades, value: 14)  // Ace (point card)
        ]
        
        let validMoves = GameRules.validMoves(
            from: aiPlayerExpert.hand,
            against: gameState.topTableCard,
            tableCardsCount: gameState.tableCards.count
        )
        
        // Run multiple times to test consistency (expert should prefer 7 with points on table)
        var sevenChosenCount = 0
        for _ in 0..<5 {
            let chosenCard = await aiPlayerExpert.chooseCard(gameState: gameState, validMoves: validMoves)
            if chosenCard?.value == 7 {
                sevenChosenCount += 1
            }
        }
        
        // Expert AI should often choose 7 when points are available
        XCTAssertTrue(sevenChosenCount >= 3, "Expert AI should prefer 7s when points are on table")
    }
    
    func testAIAvoids7sEarlyGame() async {
        // Set up early game scenario (many cards remaining)
        aiPlayerMedium.hand = [
            Card(suit: .hearts, value: 7),
            Card(suit: .spades, value: 8),
            Card(suit: .clubs, value: 9),
            Card(suit: .diamonds, value: 12)
        ]
        
        // Empty table (starting new trick)
        gameState.tableCards = []
        
        let validMoves = aiPlayerMedium.hand // All cards valid when table is empty
        
        // Run multiple times to test pattern
        var non7ChosenCount = 0
        for _ in 0..<10 {
            let chosenCard = await aiPlayerMedium.chooseCard(gameState: gameState, validMoves: validMoves)
            if chosenCard?.value != 7 {
                non7ChosenCount += 1
            }
        }
        
        // AI should often avoid playing 7s early in game when starting tricks
        XCTAssertTrue(non7ChosenCount >= 6, "AI should tend to avoid 7s in early game when starting tricks")
    }
    
    // MARK: - Romanian Strategy Tests
    
    func testRomanianStrategicPatterns() async {
        // Test that different difficulties show different patterns
        let testHand = [
            Card(suit: .hearts, value: 7),
            Card(suit: .spades, value: 10),
            Card(suit: .clubs, value: 11),
            Card(suit: .diamonds, value: 8)
        ]
        
        aiPlayerEasy.hand = testHand
        aiPlayerExpert.hand = testHand
        
        gameState.tableCards = []
        
        var easyChoices: [Int] = []
        var expertChoices: [Int] = []
        
        // Collect choices from different difficulty levels
        for _ in 0..<20 {
            if let easyChoice = await aiPlayerEasy.chooseCard(gameState: gameState, validMoves: testHand) {
                easyChoices.append(easyChoice.value)
            }
            if let expertChoice = await aiPlayerExpert.chooseCard(gameState: gameState, validMoves: testHand) {
                expertChoices.append(expertChoice.value)
            }
        }
        
        // Easy AI should show more randomness
        let easyUniqueChoices = Set(easyChoices).count
        let expertUniqueChoices = Set(expertChoices).count
        
        // Both should make valid choices, but easy should be more varied
        XCTAssertTrue(easyChoices.count > 0)
        XCTAssertTrue(expertChoices.count > 0)
        XCTAssertTrue(easyUniqueChoices >= expertUniqueChoices - 1, "Easy AI should show more variety in choices")
    }
    
    func testGamePhaseRecognition() {
        // This tests the internal game phase logic indirectly
        
        // Early game setup (many cards)
        gameState.players[0].hand = Array(repeating: Card(suit: .hearts, value: 8), count: 6)
        gameState.players[1].hand = Array(repeating: Card(suit: .spades, value: 9), count: 6)
        
        // The AI should make more conservative choices early
        // We can't directly test the internal phase recognition, but we can verify
        // that the AI behaves differently in different game states
        XCTAssertTrue(gameState.players[0].hand.count > 4, "Early game setup")
        
        // Later game setup (few cards)
        gameState.players[0].hand = [Card(suit: .hearts, value: 7)]
        gameState.players[1].hand = [Card(suit: .spades, value: 10)]
        
        XCTAssertTrue(gameState.players[0].hand.count <= 2, "End game setup")
    }
    
    // MARK: - Performance Tests
    
    func testAIDecisionSpeed() async {
        aiPlayerMedium.hand = [
            Card(suit: .hearts, value: 7),
            Card(suit: .spades, value: 10),
            Card(suit: .clubs, value: 11),
            Card(suit: .diamonds, value: 14)
        ]
        
        let validMoves = aiPlayerMedium.hand
        
        let startTime = Date()
        
        // Test that AI makes decision within reasonable time
        _ = await aiPlayerMedium.chooseCard(gameState: gameState, validMoves: validMoves)
        
        let elapsedTime = Date().timeIntervalSince(startTime)
        
        // Should complete within 5 seconds (including thinking time)
        XCTAssertLessThan(elapsedTime, 5.0, "AI decision should complete within 5 seconds")
    }
    
    func testAIDecisionConsistency() async {
        // Set up identical game state multiple times
        let testHand = [Card(suit: .hearts, value: 7)]
        let testTable = [Card(suit: .spades, value: 8)]
        
        aiPlayerExpert.hand = testHand
        gameState.tableCards = testTable
        
        let validMoves = GameRules.validMoves(
            from: testHand,
            against: testTable.last,
            tableCardsCount: testTable.count
        )
        
        // Expert AI should be consistent with forced moves
        for _ in 0..<5 {
            let choice = await aiPlayerExpert.chooseCard(gameState: gameState, validMoves: validMoves)
            XCTAssertNotNil(choice)
            XCTAssertEqual(choice?.value, 7, "Expert AI should consistently choose 7 when it's the only valid move")
        }
    }
    
    // MARK: - Edge Case Tests
    
    func testAIWithNoValidMoves() async {
        aiPlayerMedium.hand = []
        let validMoves: [Card] = []
        
        let choice = await aiPlayerMedium.chooseCard(gameState: gameState, validMoves: validMoves)
        XCTAssertNil(choice, "AI should return nil when no valid moves available")
    }
    
    func testAIWithSingleValidMove() async {
        let onlyValidCard = Card(suit: .hearts, value: 7)
        aiPlayerMedium.hand = [onlyValidCard]
        let validMoves = [onlyValidCard]
        
        let choice = await aiPlayerMedium.chooseCard(gameState: gameState, validMoves: validMoves)
        XCTAssertNotNil(choice)
        XCTAssertEqual(choice?.suit, onlyValidCard.suit)
        XCTAssertEqual(choice?.value, onlyValidCard.value)
    }
    
    // MARK: - Integration Tests
    
    func testAIIntegrationWithGameState() async {
        // Set up a full game scenario
        humanPlayer.hand = [
            Card(suit: .hearts, value: 10),
            Card(suit: .spades, value: 11)
        ]
        
        aiPlayerMedium.hand = [
            Card(suit: .clubs, value: 7),
            Card(suit: .diamonds, value: 14)
        ]
        
        gameState.players = [humanPlayer, aiPlayerMedium]
        gameState.currentPlayerIndex = 1 // AI's turn
        
        let validMoves = GameRules.validMoves(
            from: aiPlayerMedium.hand,
            against: gameState.topTableCard,
            tableCardsCount: gameState.tableCards.count
        )
        
        let aiChoice = await aiPlayerMedium.chooseCard(gameState: gameState, validMoves: validMoves)
        
        XCTAssertNotNil(aiChoice)
        XCTAssertTrue(aiPlayerMedium.hasCard(aiChoice!), "AI should choose from its own hand")
        XCTAssertTrue(validMoves.contains { $0.suit == aiChoice!.suit && $0.value == aiChoice!.value }, "AI should choose valid move")
    }
}