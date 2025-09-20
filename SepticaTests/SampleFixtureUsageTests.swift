//
//  SampleFixtureUsageTests.swift
//  SepticaTests
//
//  Example tests demonstrating usage of TestDataFixtures
//  Shows how to use predefined test data for consistent testing
//

import XCTest
@testable import Septica

final class SampleFixtureUsageTests: XCTestCase {
    
    // MARK: - Example Usage of Test Fixtures
    
    func testUsingCardFixtures() {
        let cards = TestDataFixtures.commonCards
        
        // Test all sevens can beat any card
        let targetCard = cards.tenHearts
        
        for seven in cards.allSevens {
            assertCanBeat(seven, targetCard, tableCardsCount: 1, expected: true)
        }
        
        // Test point card identification
        for pointCard in cards.allPointCards {
            XCTAssertTrue(pointCard.isPointCard, "\(pointCard.displayName) should be a point card")
        }
        
        for nonPointCard in cards.nonPointCards {
            XCTAssertFalse(nonPointCard.isPointCard, "\(nonPointCard.displayName) should not be a point card")
        }
    }
    
    func testUsingHandFixtures() {
        let hands = TestDataFixtures.testHands
        let targetCard = TestDataFixtures.commonCards.tenHearts
        
        // Test strong hand has many valid moves
        assertValidMovesCount(
            hand: hands.mixedStrong,
            against: targetCard,
            tableCardsCount: 1,
            expectedCount: 3 // 7, 10, and Ace can beat
        )
        
        // Test weak hand has fewer valid moves
        assertValidMovesCount(
            hand: hands.regularCards,
            against: targetCard,
            tableCardsCount: 1,
            expectedCount: 1 // Only same value (if any) can beat
        )
        
        // Test all sevens hand can beat anything
        assertValidMovesCount(
            hand: hands.allSevens,
            against: targetCard,
            tableCardsCount: 1,
            expectedCount: 4 // All four sevens
        )
    }
    
    func testUsingGameScenarios() {
        let scenarios = TestDataFixtures.gameScenarios
        
        // Test seven beats all scenario
        let sevenScenario = scenarios.SevenBeatsAll()
        
        for targetCard in sevenScenario.targetCards {
            for tableCount in sevenScenario.tableCounts {
                assertCanBeat(
                    sevenScenario.attackingCard,
                    targetCard,
                    tableCardsCount: tableCount,
                    expected: sevenScenario.shouldAllBeat()
                )
            }
        }
        
        // Test eight conditional beating scenario
        let eightScenario = scenarios.EightConditionalBeating()
        
        for count in eightScenario.divisibleBy3 {
            assertCanBeat(
                eightScenario.attackingCard,
                eightScenario.targetCard,
                tableCardsCount: count,
                expected: eightScenario.shouldBeatWhenDivisible()
            )
        }
        
        for count in eightScenario.notDivisibleBy3 {
            assertCanBeat(
                eightScenario.attackingCard,
                eightScenario.targetCard,
                tableCardsCount: count,
                expected: eightScenario.shouldNotBeatWhenNotDivisible()
            )
        }
        
        // Test trick sequences
        let trickSequences = scenarios.TrickSequences()
        
        assertTrickWinner(
            tableCards: trickSequences.simpleTrick,
            expectedWinnerIndex: trickSequences.simpleTrickWinner
        )
        
        assertTrickWinner(
            tableCards: trickSequences.complexTrick,
            expectedWinnerIndex: trickSequences.complexTrickWinner
        )
        
        assertTrickWinner(
            tableCards: trickSequences.allSevensTrick,
            expectedWinnerIndex: trickSequences.allSevensTrickWinner
        )
    }
    
    func testUsingValidationTestCases() {
        let validationCases = TestDataFixtures.validationTestCases
        
        // Test valid moves
        for testCase in validationCases.validMoves {
            let result = GameRules.validateMove(
                card: testCase.card,
                from: testCase.playerHand,
                against: testCase.targetCard,
                tableCardsCount: testCase.tableCardsCount
            )
            
            switch result {
            case .valid:
                XCTAssertTrue(testCase.expectedResult, "Test case should be valid: \(testCase.description)")
            case .invalid:
                XCTAssertFalse(testCase.expectedResult, "Test case should be invalid: \(testCase.description)")
            }
        }
        
        // Test invalid moves
        for testCase in validationCases.invalidMoves {
            let result = GameRules.validateMove(
                card: testCase.card,
                from: testCase.playerHand,
                against: testCase.targetCard,
                tableCardsCount: testCase.tableCardsCount
            )
            
            switch result {
            case .valid:
                XCTAssertTrue(testCase.expectedResult, "Test case should be valid: \(testCase.description)")
            case .invalid:
                XCTAssertFalse(testCase.expectedResult, "Test case should be invalid: \(testCase.description)")
            }
        }
    }
    
    func testUsingGameStateFixtures() {
        // Test fresh game state
        let gameState = TestDataFixtures.createTestGameState()
        assertGamePhase(gameState, expectedPhase: .playing)
        XCTAssertEqual(gameState.players.count, 2)
        
        // Test game state with specific hands
        let hand1 = TestDataFixtures.testHands.mixedStrong
        let hand2 = TestDataFixtures.testHands.regularCards
        let customGameState = TestDataFixtures.createTestGameState(withHands: hand1, hand2)
        
        XCTAssertEqual(customGameState.players[0].hand, hand1)
        XCTAssertEqual(customGameState.players[1].hand, hand2)
        
        // Test mid-game state
        let tableCards = [TestDataFixtures.commonCards.tenHearts]
        let midGameState = TestDataFixtures.createMidGameState(tableCards: tableCards, currentPlayerIndex: 1)
        
        XCTAssertEqual(midGameState.tableCards, tableCards)
        XCTAssertEqual(midGameState.currentPlayerIndex, 1)
    }
    
    func testUsingPointsCalculation() {
        let cards = TestDataFixtures.commonCards
        
        // Test all point cards
        assertPointsCalculation(
            cards: cards.allPointCards,
            expectedPoints: 8 // 4 tens + 4 aces
        )
        
        // Test non-point cards
        assertPointsCalculation(
            cards: cards.nonPointCards,
            expectedPoints: 0
        )
        
        // Test mixed cards
        let mixedCards = [cards.tenHearts, cards.sevenSpades, cards.aceClubs, cards.nineHearts]
        assertPointsCalculation(
            cards: mixedCards,
            expectedPoints: 2 // 1 ten + 1 ace
        )
    }
    
    func testUsingMockObjects() {
        let (mockPlayer1, mockPlayer2) = TestMocks.createMockPlayers()
        
        // Test mock player functionality
        XCTAssertEqual(mockPlayer1.name, "Mock Player 1")
        XCTAssertEqual(mockPlayer2.name, "Mock Player 2")
        
        // Test predefined cards
        XCTAssertEqual(mockPlayer1.hand.count, TestDataFixtures.testHands.mixedStrong.count)
        XCTAssertEqual(mockPlayer2.hand.count, TestDataFixtures.testHands.regularCards.count)
        
        // Test card retrieval
        let firstCard = mockPlayer1.getNextCard()
        XCTAssertNotNil(firstCard)
        XCTAssertEqual(firstCard, TestDataFixtures.testHands.mixedStrong.first)
        
        // Test reset functionality
        mockPlayer1.reset()
        let firstCardAgain = mockPlayer1.getNextCard()
        XCTAssertEqual(firstCard, firstCardAgain)
    }
    
    func testPerformanceHelpers() {
        // Test time measurement
        let (result, timeInterval) = PerformanceTestHelpers.measureTime {
            return GameRules.createDeck()
        }
        
        XCTAssertEqual(result.count, 32)
        XCTAssertGreaterThan(timeInterval, 0)
        
        // Test large hand generation
        let largeHand = PerformanceTestHelpers.generateLargeHand(size: 100)
        XCTAssertEqual(largeHand.count, 100)
        
        // Test stress test game state
        let stressGameState = PerformanceTestHelpers.createStressTestGameState(handSize: 16)
        XCTAssertEqual(stressGameState.players[0].hand.count, 16)
        XCTAssertEqual(stressGameState.players[1].hand.count, 16)
    }
}