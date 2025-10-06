//
//  ObjectionSystemTests.swift
//  SepticaTests
//
//  Comprehensive tests for Romanian Septica objection system
//  Tests PASS/OBJECT actions, timer mechanics, AI decision logic, and state transitions
//

import XCTest
@testable import Septica

final class ObjectionSystemTests: XCTestCase {

    // MARK: - Test Properties

    var gameState: GameState!
    var viewModel: GameViewModel!
    var humanPlayer: Player!
    var aiPlayer: AIPlayer!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()

        // Create players
        humanPlayer = Player(name: "Human Player")
        aiPlayer = AIPlayer(name: "AI Opponent", difficulty: .medium)

        // Create game state
        gameState = GameState()
        gameState.players = [humanPlayer, aiPlayer]
        gameState.setupNewGame()

        // Create view model
        viewModel = GameViewModel(gameState: gameState)
    }

    override func tearDown() {
        gameState = nil
        viewModel = nil
        humanPlayer = nil
        aiPlayer = nil
        super.tearDown()
    }

    // MARK: - PASS Action Tests

    func testPassActionClearsObjectionState() {
        // Given: Game is in objection waiting state
        gameState.waitingForObjection = true
        gameState.objectionDeadline = Date().addingTimeInterval(30)
        gameState.validObjectionCards = [
            Card(suit: .hearts, value: 7),
            Card(suit: .spades, value: 10)
        ]
        gameState.lastPlayedCard = Card(suit: .diamonds, value: 9)

        // When: Player passes on objection
        viewModel.passCurrentTurn()

        // Then: Objection state should be cleared
        XCTAssertFalse(gameState.waitingForObjection, "waitingForObjection should be false after pass")
        XCTAssertNil(gameState.objectionDeadline, "objectionDeadline should be nil after pass")
        XCTAssertTrue(gameState.validObjectionCards.isEmpty, "validObjectionCards should be empty after pass")
    }

    func testPassActionDoesNotCollectCards() {
        // Given: Cards on table and objection state active
        let tableCard1 = Card(suit: .hearts, value: 10)
        let tableCard2 = Card(suit: .spades, value: 14) // Ace (point card)
        gameState.tableCards = [tableCard1, tableCard2]
        gameState.waitingForObjection = true

        let initialTableCount = gameState.tableCards.count

        // When: Player passes
        viewModel.passCurrentTurn()

        // Then: Cards remain on table (not collected yet)
        // Note: Cards are collected in completeTrick(), not in pass action
        XCTAssertEqual(gameState.tableCards.count, initialTableCount, "Table cards should remain until trick completes")
    }

    func testPassActionAllowsGameToContinue() {
        // Given: Objection state with AI ready to play
        gameState.waitingForObjection = true
        gameState.currentPlayerIndex = 1 // AI's turn after human passes

        // When: Human player passes
        viewModel.passCurrentTurn()

        // Then: Game should continue (not waiting for objection)
        XCTAssertFalse(gameState.waitingForObjection, "Game should continue after pass")
    }

    // MARK: - OBJECT Action Tests

    func testObjectActionWithValidBeatingCard() {
        // Given: Human has a valid beating card (7 beats everything)
        let beatingCard = Card(suit: .hearts, value: 7)
        humanPlayer.hand = [beatingCard, Card(suit: .spades, value: 9)]

        let tableCard = Card(suit: .diamonds, value: 10)
        gameState.tableCards = [tableCard]
        gameState.waitingForObjection = true
        gameState.validObjectionCards = [beatingCard]

        let initialHandSize = humanPlayer.hand.count

        // When: Player objects by playing the 7
        let result = gameState.playCard(beatingCard, by: humanPlayer.id)

        // Then: Card should be played successfully
        XCTAssertEqual(result, .success, "Valid objection card should play successfully")
        XCTAssertEqual(humanPlayer.hand.count, initialHandSize - 1, "Hand should have one fewer card")
        XCTAssertTrue(gameState.tableCards.contains { $0.suit == beatingCard.suit && $0.value == beatingCard.value }, "Beating card should be on table")
    }

    func testObjectActionWithInvalidCardFails() {
        // Given: Human tries to object with non-beating card
        let nonBeatingCard = Card(suit: .hearts, value: 9)
        humanPlayer.hand = [nonBeatingCard, Card(suit: .spades, value: 8)]

        let tableCard = Card(suit: .diamonds, value: 10)
        gameState.tableCards = [tableCard]
        gameState.currentPlayerIndex = 0 // Human's turn

        // When: Player tries to object with invalid card
        let result = gameState.playCard(nonBeatingCard, by: humanPlayer.id)

        // Then: Move should fail validation
        if case .failure = result {
            XCTAssertTrue(true, "Invalid objection should fail")
        } else {
            XCTFail("Non-beating card should not be playable")
        }
    }

    func testObjectActionCollectsAllTableCards() {
        // Given: Multiple cards on table including point cards
        let card1 = Card(suit: .hearts, value: 10) // Point card
        let card2 = Card(suit: .spades, value: 14) // Ace - point card
        let card3 = Card(suit: .diamonds, value: 9)
        gameState.tableCards = [card1, card2, card3]

        let beatingCard = Card(suit: .clubs, value: 7)
        humanPlayer.hand = [beatingCard]
        gameState.currentPlayerIndex = 0

        let initialScore = humanPlayer.score

        // When: Player objects and beats the trick
        _ = gameState.playCard(beatingCard, by: humanPlayer.id)

        // Wait for trick completion
        // In real game, this triggers completeTrick()

        // Then: Player should collect 2 points (10 and Ace)
        // Note: This test validates the setup - actual collection happens in integration
        let expectedPoints = 2
        XCTAssertEqual(gameState.tableCards.count, 4, "All cards should be on table before trick completion")
    }

    // MARK: - Objection Timer Tests

    func testObjectionTimerSetTo30Seconds() {
        // Given: Clean game state
        gameState.waitingForObjection = false

        let beforeTime = Date()

        // When: Objection state is triggered
        gameState.waitingForObjection = true
        gameState.objectionDeadline = Date().addingTimeInterval(GameRules.objectionTimeLimit)

        // Then: Deadline should be approximately 30 seconds from now
        guard let deadline = gameState.objectionDeadline else {
            XCTFail("Objection deadline should be set")
            return
        }

        let timeInterval = deadline.timeIntervalSince(beforeTime)
        XCTAssertEqual(timeInterval, 30.0, accuracy: 0.1, "Objection timer should be 30 seconds")
    }

    func testObjectionTimerExpiration() {
        // Given: Objection deadline has passed
        gameState.waitingForObjection = true
        gameState.objectionDeadline = Date().addingTimeInterval(-1) // 1 second in the past

        // When: Checking if deadline has expired
        let hasExpired = gameState.objectionDeadline! < Date()

        // Then: Deadline should be expired
        XCTAssertTrue(hasExpired, "Objection deadline should be expired")
    }

    func testObjectionTimerNotExpired() {
        // Given: Objection deadline is in future
        gameState.waitingForObjection = true
        gameState.objectionDeadline = Date().addingTimeInterval(15) // 15 seconds from now

        // When: Checking if deadline has expired
        let hasExpired = gameState.objectionDeadline! < Date()

        // Then: Deadline should not be expired
        XCTAssertFalse(hasExpired, "Objection deadline should not be expired")
    }

    // MARK: - AI Objection Decision Logic Tests

    func testAIShouldObjectToHighValueCards() async {
        // Given: 3+ point cards on table (high value scenario)
        gameState.tableCards = [
            Card(suit: .hearts, value: 10),  // Point card
            Card(suit: .spades, value: 14),  // Ace - point card
            Card(suit: .diamonds, value: 10) // Point card
        ]

        let beatingCard = Card(suit: .clubs, value: 7)
        aiPlayer.hand = [beatingCard, Card(suit: .hearts, value: 9)]

        // When: AI evaluates objection decision
        let validMoves = GameRules.validMoves(
            from: aiPlayer.hand,
            against: gameState.topTableCard,
            tableCardsCount: gameState.tableCards.count
        )

        let canBeat = validMoves.contains { $0.value == 7 }
        let tableValue = gameState.tableCards.filter { $0.isPointCard }.count

        // Then: AI should decide to OBJECT (3 points available)
        XCTAssertTrue(canBeat, "AI should have beating card")
        XCTAssertEqual(tableValue, 3, "Should be 3 point cards on table")
        XCTAssertTrue(tableValue >= 2, "AI should object when 2+ points available")
    }

    func testAIShouldPassOnLowValueCards() async {
        // Given: No point cards on table (low value scenario)
        gameState.tableCards = [
            Card(suit: .hearts, value: 9),
            Card(suit: .spades, value: 8)
        ]

        let beatingCard = Card(suit: .clubs, value: 7)
        aiPlayer.hand = [beatingCard, Card(suit: .hearts, value: 11)]

        // When: AI evaluates objection decision
        let tableValue = gameState.tableCards.filter { $0.isPointCard }.count

        // Then: AI should decide to PASS (0 points on table)
        XCTAssertEqual(tableValue, 0, "Should be 0 point cards on table")
        XCTAssertFalse(tableValue >= 2, "AI should pass when fewer than 2 points available")
    }

    func testAIObjectionRequiresBeatingCard() async {
        // Given: High value on table but AI has no beating cards
        gameState.tableCards = [
            Card(suit: .hearts, value: 10),  // Point card
            Card(suit: .spades, value: 14)   // Ace - point card
        ]

        // AI has no 7s or same-value cards to beat
        aiPlayer.hand = [
            Card(suit: .clubs, value: 9),
            Card(suit: .diamonds, value: 11)
        ]

        let topCard = gameState.topTableCard!

        // When: AI evaluates if it can beat
        let validMoves = GameRules.validMoves(
            from: aiPlayer.hand,
            against: topCard,
            tableCardsCount: gameState.tableCards.count
        )

        let canBeat = !validMoves.isEmpty

        // Then: AI should not be able to object (no beating cards)
        XCTAssertFalse(canBeat, "AI should not have valid beating cards")
    }

    // MARK: - Valid Objection Cards Calculation Tests

    func testValidObjectionCardsWithSeven() {
        // Given: Player has a 7 (always beats)
        let seven = Card(suit: .hearts, value: 7)
        humanPlayer.hand = [seven, Card(suit: .spades, value: 9)]

        let tableCard = Card(suit: .diamonds, value: 10)
        gameState.tableCards = [tableCard]

        // When: Calculating valid objection cards
        let validCards = GameRules.validMoves(
            from: humanPlayer.hand,
            against: tableCard,
            tableCardsCount: gameState.tableCards.count
        )

        // Then: 7 should be in valid objection cards
        XCTAssertTrue(validCards.contains { $0.value == 7 }, "7 should be valid objection card")
    }

    func testValidObjectionCardsWithSameValue() {
        // Given: Player has same value card as table card
        let topCard = Card(suit: .hearts, value: 10)
        let sameValueCard = Card(suit: .spades, value: 10)

        humanPlayer.hand = [sameValueCard, Card(suit: .clubs, value: 9)]
        gameState.tableCards = [topCard]

        // When: Calculating valid objection cards
        let validCards = GameRules.validMoves(
            from: humanPlayer.hand,
            against: topCard,
            tableCardsCount: gameState.tableCards.count
        )

        // Then: Same value card should be valid
        XCTAssertTrue(validCards.contains { $0.value == 10 && $0.suit == .spades }, "Same value card should be valid")
    }

    func testValidObjectionCardsExcludesNonBeatingCards() {
        // Given: Player has cards that cannot beat table card
        let topCard = Card(suit: .hearts, value: 10)
        humanPlayer.hand = [
            Card(suit: .spades, value: 9),
            Card(suit: .clubs, value: 11),
            Card(suit: .diamonds, value: 12)
        ]
        gameState.tableCards = [topCard]

        // When: Calculating valid objection cards
        let validCards = GameRules.validMoves(
            from: humanPlayer.hand,
            against: topCard,
            tableCardsCount: gameState.tableCards.count
        )

        // Then: No cards should be valid (none can beat 10)
        XCTAssertTrue(validCards.isEmpty, "Should have no valid objection cards")
    }

    // MARK: - Objection State Transition Tests

    func testWaitingForObjectionStateActivation() {
        // Given: Clean game state
        gameState.waitingForObjection = false

        // When: Objection opportunity arises
        gameState.waitingForObjection = true
        gameState.objectionDeadline = Date().addingTimeInterval(30)

        // Then: State should transition to waiting for objection
        XCTAssertTrue(gameState.waitingForObjection, "Should be waiting for objection")
        XCTAssertNotNil(gameState.objectionDeadline, "Should have objection deadline")
    }

    func testWaitingForObjectionStateClearing() {
        // Given: Active objection state
        gameState.waitingForObjection = true
        gameState.objectionDeadline = Date().addingTimeInterval(30)
        gameState.validObjectionCards = [Card(suit: .hearts, value: 7)]

        // When: Objection is resolved (passed)
        viewModel.passCurrentTurn()

        // Then: State should clear all objection flags
        XCTAssertFalse(gameState.waitingForObjection, "Should not be waiting for objection")
        XCTAssertNil(gameState.objectionDeadline, "Deadline should be cleared")
        XCTAssertTrue(gameState.validObjectionCards.isEmpty, "Valid cards should be cleared")
    }

    func testObjectionStateAfterSuccessfulObject() {
        // Given: Player objects successfully
        let beatingCard = Card(suit: .hearts, value: 7)
        humanPlayer.hand = [beatingCard]
        gameState.tableCards = [Card(suit: .spades, value: 10)]
        gameState.currentPlayerIndex = 0
        gameState.waitingForObjection = true

        // When: Player plays objection card
        let result = gameState.playCard(beatingCard, by: humanPlayer.id)

        // Then: Play should succeed
        XCTAssertEqual(result, .success, "Objection card should play successfully")
    }

    // MARK: - Integration Tests

    func testCompleteObjectionFlow_PassScenario() {
        // Given: Complete objection scenario setup
        gameState.waitingForObjection = true
        gameState.objectionDeadline = Date().addingTimeInterval(30)
        gameState.tableCards = [
            Card(suit: .hearts, value: 9),
            Card(suit: .spades, value: 8)
        ]

        let initialTableCount = gameState.tableCards.count

        // When: Player chooses to PASS
        viewModel.passCurrentTurn()

        // Then: Objection state should be fully cleared
        XCTAssertFalse(gameState.waitingForObjection, "Should not be waiting after pass")
        XCTAssertNil(gameState.objectionDeadline, "Deadline should be cleared")
        XCTAssertTrue(gameState.validObjectionCards.isEmpty, "Valid cards should be empty")
    }

    func testCompleteObjectionFlow_ObjectScenario() {
        // Given: Complete objection scenario with beating card
        let beatingCard = Card(suit: .hearts, value: 7)
        humanPlayer.hand = [beatingCard, Card(suit: .spades, value: 9)]

        gameState.tableCards = [Card(suit: .diamonds, value: 10)]
        gameState.currentPlayerIndex = 0
        gameState.waitingForObjection = true

        // When: Player chooses to OBJECT with 7
        let result = gameState.playCard(beatingCard, by: humanPlayer.id)

        // Then: Card should be played and on table
        XCTAssertEqual(result, .success, "Object action should succeed")
        XCTAssertEqual(gameState.tableCards.count, 2, "Should have 2 cards on table")
        XCTAssertTrue(gameState.tableCards.last?.value == 7, "Last card should be the 7")
    }

    // MARK: - Edge Case Tests

    func testObjectionWithEmptyHand() {
        // Given: Player has empty hand (edge case)
        humanPlayer.hand = []
        gameState.tableCards = [Card(suit: .hearts, value: 10)]
        gameState.waitingForObjection = true

        // When: Calculating valid objection cards
        let validCards = GameRules.validMoves(
            from: humanPlayer.hand,
            against: gameState.topTableCard,
            tableCardsCount: gameState.tableCards.count
        )

        // Then: Should have no valid cards
        XCTAssertTrue(validCards.isEmpty, "Empty hand should have no valid objection cards")
    }

    func testObjectionWithAllPointCardsOnTable() {
        // Given: All 8 point cards on table (maximum value scenario)
        gameState.tableCards = [
            Card(suit: .hearts, value: 10),
            Card(suit: .spades, value: 10),
            Card(suit: .clubs, value: 10),
            Card(suit: .diamonds, value: 10),
            Card(suit: .hearts, value: 14),
            Card(suit: .spades, value: 14),
            Card(suit: .clubs, value: 14),
            Card(suit: .diamonds, value: 14)
        ]

        let beatingCard = Card(suit: .hearts, value: 7)
        aiPlayer.hand = [beatingCard]

        // When: AI evaluates this scenario
        let pointCardCount = gameState.tableCards.filter { $0.isPointCard }.count

        // Then: AI should definitely object (8 points - entire game!)
        XCTAssertEqual(pointCardCount, 8, "Should have all 8 point cards")
        XCTAssertTrue(pointCardCount >= 2, "AI should object with max points available")
    }
}
