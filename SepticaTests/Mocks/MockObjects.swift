//
//  MockObjects.swift
//  SepticaTests
//
//  Mock objects and test utilities for comprehensive testing
//  Provides controlled test environments and predictable behaviors
//

import Foundation
import XCTest
import Combine
@testable import Septica

// MARK: - Mock Game State

class MockGameState: ObservableObject {
    @Published var phase: GamePhase = .playing
    @Published var players: [Player] = []
    @Published var currentPlayerIndex: Int = 0
    @Published var tableCards: [Card] = []
    @Published var trickHistory: [CompletedTrick] = []
    @Published var targetScore: Int = 11
    @Published var gameResult: GameResult?
    
    var currentPlayer: Player? {
        guard currentPlayerIndex < players.count else { return nil }
        return players[currentPlayerIndex]
    }
    
    var topTableCard: Card? {
        return tableCards.last
    }
    
    var isGameComplete: Bool = false
    var isTrickComplete: Bool = false
    
    init(players: [Player] = [], targetScore: Int = 11) {
        self.players = players
        self.targetScore = targetScore
    }
    
    func validMovesForCurrentPlayer() -> [Card] {
        guard let currentPlayer = currentPlayer else { return [] }
        return GameRules.validMoves(
            from: currentPlayer.hand,
            against: topTableCard,
            tableCardsCount: tableCards.count
        )
    }
    
    func playCard(_ card: Card, by playerId: UUID) -> PlayResult {
        guard let playerIndex = players.firstIndex(where: { $0.id == playerId }) else {
            return .failure(.playerNotFound)
        }
        
        let player = players[playerIndex]
        
        guard playerIndex == currentPlayerIndex else {
            return .failure(.notPlayerTurn)
        }
        
        guard player.hasCard(card) else {
            return .failure(.invalidMove(.cardNotInHand))
        }
        
        player.removeCard(card)
        tableCards.append(card)
        
        // Simple turn advancement
        currentPlayerIndex = (currentPlayerIndex + 1) % players.count
        
        return .success
    }
}

// MARK: - Mock AI Player

class MockAIPlayer: Player {
    let mockDifficulty: AIDifficulty
    var shouldThinkingDelay: Bool = true
    var forcedChoice: Card?
    var decisionHistory: [Card] = []
    
    override var isHuman: Bool { return false }
    
    init(name: String, difficulty: AIDifficulty, id: UUID = UUID()) {
        self.mockDifficulty = difficulty
        super.init(name: name, id: id)
    }
    
    required init(from decoder: Decoder) throws {
        self.mockDifficulty = .medium
        try super.init(from: decoder)
    }
    
    override func chooseCard(gameState: GameState, validMoves: [Card]) async -> Card? {
        // Record decision for testing
        defer {
            if let choice = forcedChoice ?? validMoves.first {
                decisionHistory.append(choice)
            }
        }
        
        // Simulate thinking time if enabled
        if shouldThinkingDelay {
            try? await Task.sleep(nanoseconds: UInt64(mockDifficulty.thinkingTime * 0.1 * 1_000_000_000)) // Reduced for testing
        }
        
        // Return forced choice or first valid move
        if let forced = forcedChoice, validMoves.contains(where: { $0.suit == forced.suit && $0.value == forced.value }) {
            return forced
        }
        
        return validMoves.first
    }
    
    func setForcedChoice(_ card: Card?) {
        forcedChoice = card
    }
    
    func clearDecisionHistory() {
        decisionHistory.removeAll()
    }
}

// MARK: - Mock Game Controller

class MockGameController {
    var currentGame: GameState?
    var startGameCalled = false
    var endGameCalled = false
    var pauseGameCalled = false
    var resumeGameCalled = false
    var playCardResults: [PlayResult] = []
    
    func startNewGame(players: [Player], targetScore: Int = 11) -> Bool {
        startGameCalled = true
        
        guard players.count >= 2 else { return false }
        
        currentGame = GameState(players: players)
        currentGame?.targetScore = targetScore
        return true
    }
    
    func endCurrentGame() {
        endGameCalled = true
        currentGame?.phase = .finished
    }
    
    func pauseGame() {
        pauseGameCalled = true
        currentGame?.phase = .paused
    }
    
    func resumeGame() {
        resumeGameCalled = true
        currentGame?.phase = .playing
    }
    
    func playCard(_ card: Card, by playerId: UUID) -> PlayResult {
        guard let gameState = currentGame else {
            let result = PlayResult.failure(.gameNotInProgress)
            playCardResults.append(result)
            return result
        }
        
        let result = gameState.playCard(card, by: playerId)
        playCardResults.append(result)
        return result
    }
    
    func reset() {
        currentGame = nil
        startGameCalled = false
        endGameCalled = false
        pauseGameCalled = false
        resumeGameCalled = false
        playCardResults.removeAll()
    }
}

// MARK: - Mock Navigation Manager

class MockNavigationManager: ObservableObject {
    @Published var currentScreen: NavigationScreen = .mainMenu
    var navigationHistory: [NavigationScreen] = []
    var canGoBack: Bool { return navigationHistory.count > 1 }
    
    func navigateToMainMenu() {
        recordNavigation(.mainMenu)
    }
    
    func navigateToGameSetup() {
        recordNavigation(.gameSetup)
    }
    
    func navigateToGame() {
        recordNavigation(.game)
    }
    
    func navigateToGameResults() {
        recordNavigation(.gameResults)
    }
    
    func navigateToSettings() {
        recordNavigation(.settings)
    }
    
    func navigateToRules() {
        recordNavigation(.rules)
    }
    
    func goBack() {
        guard canGoBack else { return }
        navigationHistory.removeLast()
        currentScreen = navigationHistory.last ?? .mainMenu
    }
    
    private func recordNavigation(_ screen: NavigationScreen) {
        currentScreen = screen
        navigationHistory.append(screen)
    }
    
    func reset() {
        currentScreen = .mainMenu
        navigationHistory = [.mainMenu]
    }
}

// MARK: - Mock Deck

class MockDeck {
    var cards: [Card]
    var shuffled = false
    var drawCount = 0
    
    var count: Int { return cards.count }
    var isEmpty: Bool { return cards.isEmpty }
    
    init(cards: [Card] = []) {
        if cards.isEmpty {
            // Create standard deck
            self.cards = []
            for suit in CardSuit.allCases {
                for value in 7...14 {
                    self.cards.append(Card(suit: suit, value: value))
                }
            }
        } else {
            self.cards = cards
        }
    }
    
    func shuffle() {
        shuffled = true
        // Deterministic shuffle for testing
        cards.reverse()
    }
    
    func drawCard() -> Card? {
        guard !cards.isEmpty else { return nil }
        drawCount += 1
        return cards.removeFirst()
    }
    
    func peek() -> Card? {
        return cards.first
    }
    
    func addCard(_ card: Card) {
        cards.append(card)
    }
    
    func reset() {
        drawCount = 0
        shuffled = false
    }
}

// MARK: - Test Data Factories

struct TestDataFactory {
    
    static func createTestPlayers() -> [Player] {
        return [
            Player(name: "Test Human"),
            MockAIPlayer(name: "Test AI", difficulty: .medium)
        ]
    }
    
    static func createTestHand() -> [Card] {
        return [
            Card(suit: .hearts, value: 7),
            Card(suit: .spades, value: 10),
            Card(suit: .clubs, value: 14),
            Card(suit: .diamonds, value: 11)
        ]
    }
    
    static func createPointCards() -> [Card] {
        return [
            Card(suit: .hearts, value: 10),   // 1 point
            Card(suit: .spades, value: 14),   // 1 point (Ace)
            Card(suit: .clubs, value: 10),    // 1 point
            Card(suit: .diamonds, value: 14)  // 1 point (Ace)
        ]
    }
    
    static func createNonPointCards() -> [Card] {
        return [
            Card(suit: .hearts, value: 7),
            Card(suit: .spades, value: 8),
            Card(suit: .clubs, value: 9),
            Card(suit: .diamonds, value: 11)
        ]
    }
    
    static func createTestTrick() -> [Card] {
        return [
            Card(suit: .hearts, value: 10),
            Card(suit: .spades, value: 7),  // Should win
            Card(suit: .clubs, value: 8)
        ]
    }
    
    static func createGameStateWithKnownOutcome() -> GameState {
        let player1 = Player(name: "Winner")
        let player2 = Player(name: "Loser")
        
        player1.hand = [Card(suit: .hearts, value: 7)]  // Winning card
        player2.hand = [Card(suit: .spades, value: 8)]  // Losing card
        
        let gameState = GameState(players: [player1, player2])
        gameState.targetScore = 5  // Low score for quick completion
        
        return gameState
    }
    
    static func createComplexGameScenario() -> GameState {
        let human = Player(name: "Human Player")
        let ai = MockAIPlayer(name: "AI Player", difficulty: .expert)
        
        // Set up interesting game state
        human.hand = [
            Card(suit: .hearts, value: 7),    // Trump card
            Card(suit: .spades, value: 10),   // Point card
            Card(suit: .clubs, value: 8),     // Conditional card
            Card(suit: .diamonds, value: 9)   // Regular card
        ]
        
        ai.hand = [
            Card(suit: .hearts, value: 14),   // Point card (Ace)
            Card(suit: .spades, value: 11),   // Regular card
            Card(suit: .clubs, value: 12),    // Regular card
            Card(suit: .diamonds, value: 13)  // Regular card
        ]
        
        let gameState = GameState(players: [human, ai])
        
        // Add some cards to table
        gameState.tableCards = [
            Card(suit: .hearts, value: 10)   // Point card on table
        ]
        
        return gameState
    }
}

// MARK: - Test Assertions Helper

struct TestAssertions {
    
    static func assertCardEqual(_ card1: Card?, _ card2: Card?, file: StaticString = #filePath, line: UInt = #line) {
        guard let c1 = card1, let c2 = card2 else {
            XCTAssertEqual(card1, card2, "Both cards should be nil or non-nil", file: file, line: line)
            return
        }
        
        XCTAssertEqual(c1.suit, c2.suit, "Card suits should match", file: file, line: line)
        XCTAssertEqual(c1.value, c2.value, "Card values should match", file: file, line: line)
    }
    
    static func assertCardsEqual(_ cards1: [Card], _ cards2: [Card], file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(cards1.count, cards2.count, "Card arrays should have same count", file: file, line: line)
        
        for (index, (card1, card2)) in zip(cards1, cards2).enumerated() {
            assertCardEqual(card1, card2, file: file, line: line)
        }
    }
    
    static func assertPlayResult(_ result: PlayResult, isSuccess: Bool, file: StaticString = #filePath, line: UInt = #line) {
        switch (result, isSuccess) {
        case (.success, true):
            XCTAssertTrue(true, file: file, line: line)
        case (.failure, false):
            XCTAssertTrue(true, file: file, line: line)
        case (.success, false):
            XCTFail("Expected failure but got success", file: file, line: line)
        case (.failure, true):
            XCTFail("Expected success but got failure: \(result)", file: file, line: line)
        }
    }
    
    static func assertGamePhase(_ gameState: GameState, expectedPhase: GamePhase, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(gameState.phase, expectedPhase, "Game should be in \(expectedPhase) phase", file: file, line: line)
    }
    
    static func assertPlayerScore(_ player: Player, expectedScore: Int, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(player.score, expectedScore, "Player \(player.name) should have score \(expectedScore)", file: file, line: line)
    }
    
    static func assertValidMove(_ card: Card, in validMoves: [Card], file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(validMoves.contains { $0.suit == card.suit && $0.value == card.value },
                     "Card \(card.displayName) should be in valid moves", file: file, line: line)
    }
}

// MARK: - Performance Helpers

class PerformanceHelper {
    
    static func measureExecutionTime<T>(operation: () throws -> T) rethrows -> (result: T, time: TimeInterval) {
        let startTime = Date()
        let result = try operation()
        let executionTime = Date().timeIntervalSince(startTime)
        return (result, executionTime)
    }
    
    static func measureAsyncExecutionTime<T>(operation: () async throws -> T) async rethrows -> (result: T, time: TimeInterval) {
        let startTime = Date()
        let result = try await operation()
        let executionTime = Date().timeIntervalSince(startTime)
        return (result, executionTime)
    }
    
    static func createMemorySnapshot() -> Int64? {
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

// MARK: - Random Data Generator

struct TestRandomizer {
    
    static func randomCard() -> Card {
        let suits = CardSuit.allCases
        let suit = suits.randomElement() ?? .hearts
        let value = Int.random(in: 7...14)
        return Card(suit: suit, value: value)
    }
    
    static func randomHand(size: Int = 4) -> [Card] {
        var hand: [Card] = []
        let availableCards = createFullDeck()
        
        for _ in 0..<min(size, availableCards.count) {
            if let randomCard = availableCards.randomElement() {
                hand.append(randomCard)
            }
        }
        
        return hand
    }
    
    static func createFullDeck() -> [Card] {
        var deck: [Card] = []
        for suit in CardSuit.allCases {
            for value in 7...14 {
                deck.append(Card(suit: suit, value: value))
            }
        }
        return deck
    }
    
    static func randomAIDifficulty() -> AIDifficulty {
        let difficulties: [AIDifficulty] = [.easy, .medium, .hard, .expert]
        return difficulties.randomElement() ?? .medium
    }
}

// MARK: - Mock Extension Types

extension NavigationScreen {
    static var allTestCases: [NavigationScreen] {
        return [.mainMenu, .gameSetup, .game, .gameResults, .settings, .rules]
    }
}

// Navigation Screen enum if not defined elsewhere
enum NavigationScreen: CaseIterable {
    case mainMenu
    case gameSetup
    case game
    case gameResults
    case settings
    case rules
}
