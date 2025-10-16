//
//  AnimationCoordinatorTests.swift
//  SepticaTests
//
//  Comprehensive tests for unified animation management system
//  Validates animation coordination, state management, and integration
//

import XCTest
@testable import Septica

final class AnimationCoordinatorTests: XCTestCase {

    // MARK: - Test Properties

    private var animationCoordinator: AnimationCoordinator!

    override func setUp() {
        super.setUp()
        animationCoordinator = AnimationCoordinator()
    }

    override func tearDown() {
        animationCoordinator = nil
        super.tearDown()
    }

    // MARK: - Card Play Coordination Tests

    func testCoordinateCardPlayBasic() {
        // GIVEN
        let card = Card(value: 10, suit: .hearts)
        let startPoint = CGPoint(x: 100, y: 200)
        let endPoint = CGPoint(x: 300, y: 400)
        let characterType = RomanianCharacterType.pacala
        let expectation = XCTestExpectation(description: "Card play completion")
        var completionCalled = false

        // WHEN
        animationCoordinator.coordinateCardPlay(
            card: card,
            from: startPoint,
            to: endPoint,
            characterType: characterType
        ) {
            completionCalled = true
            expectation.fulfill()
        }

        // THEN
        XCTAssertEqual(animationCoordinator.activeAnimationCount, 1)
        XCTAssertFalse(completionCalled)

        // Wait for animation completion
        wait(for: [expectation], timeout: 5.0)
        XCTAssertTrue(completionCalled)
        XCTAssertEqual(animationCoordinator.activeAnimationCount, 0)
    }

    func testCoordinateCardPlayDifferentCharacters() {
        // GIVEN
        let card = Card(value: 11, suit: .spades)
        let startPoint = CGPoint(x: 50, y: 100)
        let endPoint = CGPoint(x: 250, y: 300)
        let characterTypes: [RomanianCharacterType] = [.pacala, .iele, .strigoi, .fatFrumos, .babaCloantza, .zmeu]

        for characterType in characterTypes {
            // WHEN
            animationCoordinator.coordinateCardPlay(
                card: card,
                from: startPoint,
                to: endPoint,
                characterType: characterType
            )

            // THEN
            XCTAssertEqual(animationCoordinator.activeAnimationCount, 1)

            // Clear for next iteration
            animationCoordinator.cancelAllAnimations()
        }
    }

    func testCoordinateCardPlayWinningCard() {
        // GIVEN
        let winningCard = Card(value: 14, suit: .diamonds) // Ace
        let startPoint = CGPoint(x: 0, y: 0)
        let endPoint = CGPoint(x: 100, y: 100)
        let characterType = RomanianCharacterType.fatFrumos

        // WHEN
        animationCoordinator.coordinateCardPlay(
            card: winningCard,
            from: startPoint,
            to: endPoint,
            characterType: characterType
        )

        // THEN
        XCTAssertEqual(animationCoordinator.activeAnimationCount, 1)
        // Animation should be longer for winning cards
    }

    func testCoordinateCardPlayWithoutCompletion() {
        // GIVEN
        let card = Card(value: 9, suit: .clubs)
        let startPoint = CGPoint(x: 200, y: 100)
        let endPoint = CGPoint(x: 400, y: 300)
        let characterType = RomanianCharacterType.zmeu

        // WHEN
        animationCoordinator.coordinateCardPlay(
            card: card,
            from: startPoint,
            to: endPoint,
            characterType: characterType
        )

        // THEN
        XCTAssertEqual(animationCoordinator.activeAnimationCount, 1)
    }

    // MARK: - Card Selection Coordination Tests

    func testCoordinateCardSelectionBasic() {
        // GIVEN
        let cardId = UUID()
        let characterType = RomanianCharacterType.iele
        let expectation = XCTestExpectation(description: "Card selection completion")
        var completionCalled = false

        // WHEN
        animationCoordinator.coordinateCardSelection(
            cardId: cardId,
            characterType: characterType
        ) {
            completionCalled = true
            expectation.fulfill()
        }

        // THEN
        XCTAssertEqual(animationCoordinator.activeAnimationCount, 1)

        // Wait for completion
        wait(for: [expectation], timeout: 3.0)
        XCTAssertTrue(completionCalled)
        XCTAssertEqual(animationCoordinator.activeAnimationCount, 0)
    }

    func testCoordinateCardSelectionAllCharacters() {
        // GIVEN
        let characterTypes: [RomanianCharacterType] = [.pacala, .iele, .strigoi, .fatFrumos, .babaCloantza, .zmeu]

        for characterType in characterTypes {
            // WHEN
            let cardId = UUID()
            animationCoordinator.coordinateCardSelection(
                cardId: cardId,
                characterType: characterType
            )

            // THEN
            XCTAssertEqual(animationCoordinator.activeAnimationCount, 1)

            // Clear for next iteration
            animationCoordinator.cancelAllAnimations()
        }
    }

    func testCoordinateCardSelectionSameCard() {
        // GIVEN
        let cardId = UUID()
        let characterType = RomanianCharacterType.strigoi

        // WHEN - Try to animate same card twice
        animationCoordinator.coordinateCardSelection(
            cardId: cardId,
            characterType: characterType
        )

        let canStartSecond = animationCoordinator.canStartAnimation(for: cardId)

        // THEN
        XCTAssertFalse(canStartSecond, "Should not be able to start animation for same card")
        XCTAssertEqual(animationCoordinator.activeAnimationCount, 1)
    }

    // MARK: - Victory Celebration Coordination Tests

    func testCoordinateVictoryCelebrationBasic() {
        // GIVEN
        let characterType = RomanianCharacterType.pacala
        let victoryType = VictoryType.decisive
        let expectation = XCTestExpectation(description: "Victory celebration completion")
        var completionCalled = false

        // WHEN
        animationCoordinator.coordinateVictoryCelebration(
            characterType: characterType,
            victoryType: victoryType
        ) {
            completionCalled = true
            expectation.fulfill()
        }

        // THEN
        XCTAssertEqual(animationCoordinator.activeAnimationCount, 1)

        // Wait for completion
        wait(for: [expectation], timeout: 5.0)
        XCTAssertTrue(completionCalled)
        XCTAssertEqual(animationCoordinator.activeAnimationCount, 0)
    }

    func testCoordinateVictoryCelebrationAllTypes() {
        // GIVEN
        let characterType = RomanianCharacterType.fatFrumos
        let victoryTypes: [VictoryType] = [.decisive, .dramatic, .upset, .perfect]

        for victoryType in victoryTypes {
            // WHEN
            animationCoordinator.coordinateVictoryCelebration(
                characterType: characterType,
                victoryType: victoryType
            )

            // THEN
            XCTAssertEqual(animationCoordinator.activeAnimationCount, 1)

            // Clear for next iteration
            animationCoordinator.cancelAllAnimations()
        }
    }

    func testCoordinateVictoryCelebrationAllCharacters() {
        // GIVEN
        let characterTypes: [RomanianCharacterType] = [.pacala, .iele, .strigoi, .fatFrumos, .babaCloantza, .zmeu]

        for characterType in characterTypes {
            // WHEN
            animationCoordinator.coordinateVictoryCelebration(
                characterType: characterType,
                victoryType: .dramatic
            )

            // THEN
            XCTAssertEqual(animationCoordinator.activeAnimationCount, 1)

            // Clear for next iteration
            animationCoordinator.cancelAllAnimations()
        }
    }

    // MARK: - Emote Animation Coordination Tests

    func testCoordinateEmoteAnimationBasic() {
        // GIVEN
        let emoteType = EmoteType.greeting
        let characterType = RomanianCharacterType.babaCloantza
        let expectation = XCTestExpectation(description: "Emote animation completion")
        var completionCalled = false

        // WHEN
        animationCoordinator.coordinateEmoteAnimation(
            emoteType: emoteType,
            characterType: characterType
        ) {
            completionCalled = true
            expectation.fulfill()
        }

        // THEN
        XCTAssertEqual(animationCoordinator.activeAnimationCount, 1)

        // Wait for completion
        wait(for: [expectation], timeout: 5.0)
        XCTAssertTrue(completionCalled)
        XCTAssertEqual(animationCoordinator.activeAnimationCount, 0)
    }

    func testCoordinateEmoteAnimationAllCombinations() {
        // GIVEN
        let characterTypes: [RomanianCharacterType] = [.pacala, .iele, .strigoi, .fatFrumos, .babaCloantza, .zmeu]
        let emoteTypes: [EmoteType] = [.greeting, .goodMove, .badMove, .thinking, .taunt, .victory, .defeat]

        for characterType in characterTypes {
            for emoteType in emoteTypes {
                // WHEN
                animationCoordinator.coordinateEmoteAnimation(
                    emoteType: emoteType,
                    characterType: characterType
                )

                // THEN
                XCTAssertEqual(animationCoordinator.activeAnimationCount, 1)

                // Clear for next iteration
                animationCoordinator.cancelAllAnimations()
            }
        }
    }

    // MARK: - Card Dealing Coordination Tests

    func testCoordinateCardDealingBasic() {
        // GIVEN
        let playerCount = 4
        let cardsPerPlayer = 5
        let dealingStyle = DealingStyle.smooth
        let expectation = XCTestExpectation(description: "Card dealing completion")
        var completionCalled = false

        // WHEN
        animationCoordinator.coordinateCardDealing(
            playerCount: playerCount,
            cardsPerPlayer: cardsPerPlayer,
            dealingStyle: dealingStyle
        ) {
            completionCalled = true
            expectation.fulfill()
        }

        // THEN
        XCTAssertEqual(animationCoordinator.activeAnimationCount, 1)

        // Wait for completion
        wait(for: [expectation], timeout: 5.0)
        XCTAssertTrue(completionCalled)
        XCTAssertEqual(animationCoordinator.activeAnimationCount, 0)
    }

    func testCoordinateCardDealingDifferentStyles() {
        // GIVEN
        let playerCount = 2
        let cardsPerPlayer = 7
        let dealingStyles: [DealingStyle] = [.smooth, .quick, .dramatic, .circular]

        for dealingStyle in dealingStyles {
            // WHEN
            animationCoordinator.coordinateCardDealing(
                playerCount: playerCount,
                cardsPerPlayer: cardsPerPlayer,
                dealingStyle: dealingStyle
            )

            // THEN
            XCTAssertEqual(animationCoordinator.activeAnimationCount, 1)

            // Clear for next iteration
            animationCoordinator.cancelAllAnimations()
        }
    }

    func testCoordinateCardDealingVariousGameSizes() {
        // GIVEN
        let gameConfigs = [
            (players: 2, cards: 10),
            (players: 3, cards: 7),
            (players: 4, cards: 5),
            (players: 6, cards: 4)
        ]

        for (players, cards) in gameConfigs {
            // WHEN
            animationCoordinator.coordinateCardDealing(
                playerCount: players,
                cardsPerPlayer: cards
            )

            // THEN
            XCTAssertEqual(animationCoordinator.activeAnimationCount, 1)

            // Clear for next iteration
            animationCoordinator.cancelAllAnimations()
        }
    }

    // MARK: - Animation State Management Tests

    func testCanStartAnimation() {
        // GIVEN
        let cardId = UUID()

        // WHEN - No animation running
        let canStartInitially = animationCoordinator.canStartAnimation(for: cardId)

        // THEN
        XCTAssertTrue(canStartInitially, "Should be able to start animation initially")

        // WHEN - Start animation
        animationCoordinator.coordinateCardSelection(
            cardId: cardId,
            characterType: .pacala
        )

        let canStartDuringAnimation = animationCoordinator.canStartAnimation(for: cardId)

        // THEN
        XCTAssertFalse(canStartDuringAnimation, "Should not be able to start animation during animation")

        // WHEN - Different card ID
        let differentCardId = UUID()
        let canStartDifferentCard = animationCoordinator.canStartAnimation(for: differentCardId)

        // THEN
        XCTAssertTrue(canStartDifferentCard, "Should be able to start animation for different card")
    }

    func testSetAnimationInProgress() {
        // GIVEN
        let cardId = UUID()

        // WHEN - Set animation in progress
        animationCoordinator.setAnimationInProgress(for: cardId, inProgress: true)

        // THEN - This doesn't directly create animations (handled by coordinate methods)
        XCTAssertEqual(animationCoordinator.activeAnimationCount, 0)

        // WHEN - Start actual animation
        animationCoordinator.coordinateCardSelection(
            cardId: cardId,
            characterType: .iele
        )

        XCTAssertEqual(animationCoordinator.activeAnimationCount, 1)

        // WHEN - Set animation not in progress
        animationCoordinator.setAnimationInProgress(for: cardId, inProgress: false)

        // THEN - Animation should be cleaned up
        XCTAssertEqual(animationCoordinator.activeAnimationCount, 0)
    }

    func testOnAnimationComplete() {
        // GIVEN
        let cardId = UUID()
        let expectation = XCTestExpectation(description: "Manual animation completion")
        var completionCalled = false

        // WHEN - Start animation
        animationCoordinator.coordinateCardSelection(
            cardId: cardId,
            characterType: .strigoi
        ) {
            completionCalled = true
            expectation.fulfill()
        }

        XCTAssertEqual(animationCoordinator.activeAnimationCount, 1)

        // WHEN - Manually complete animation
        animationCoordinator.onAnimationComplete(cardId: cardId)

        // THEN
        XCTAssertEqual(animationCoordinator.activeAnimationCount, 0)

        // Wait for completion callback
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(completionCalled)
    }

    func testGetAnimationState() {
        // GIVEN
        let cardId = UUID()

        // WHEN - No animation running
        let initialState = animationCoordinator.getAnimationState(for: cardId)
        XCTAssertNil(initialState, "Should have no animation state initially")

        // WHEN - Start animation
        animationCoordinator.coordinateCardPlay(
            card: Card(value: 10, suit: .hearts),
            from: CGPoint.zero,
            to: CGPoint(x: 100, y: 100),
            characterType: .fatFrumos
        )

        let activeState = animationCoordinator.getAnimationState(for: cardId)

        // THEN
        XCTAssertNotNil(activeState, "Should have animation state when animation is active")
        XCTAssertFalse(activeState?.isCompleted ?? true, "Animation should not be completed initially")
    }

    // MARK: - Sound Synchronization Tests

    func testSynchronizeAnimationWithSound() {
        // GIVEN
        let animationId = UUID()
        let soundName = "pacala_victory"

        // WHEN
        animationCoordinator.synchronizeAnimationWithSound(
            animationId: animationId,
            soundName: soundName
        )

        // THEN - Should not crash and should handle synchronization
        // This is mainly a smoke test to ensure the method works
    }

    // MARK: - Animation Cancellation Tests

    func testCancelAllAnimations() {
        // GIVEN - Start multiple animations
        let cardId1 = UUID()
        let cardId2 = UUID()
        let cardId3 = UUID()

        animationCoordinator.coordinateCardSelection(cardId: cardId1, characterType: .pacala)
        animationCoordinator.coordinateCardPlay(
            card: Card(value: 11, suit: .spades),
            from: CGPoint.zero,
            to: CGPoint(x: 50, y: 50),
            characterType: .iele
        )
        animationCoordinator.coordinateVictoryCelebration(characterType: .strigoi)

        XCTAssertEqual(animationCoordinator.activeAnimationCount, 3)

        // WHEN
        animationCoordinator.cancelAllAnimations()

        // THEN
        XCTAssertEqual(animationCoordinator.activeAnimationCount, 0)
    }

    func testCancelAllAnimationsWithCompletionCallbacks() {
        // GIVEN
        let expectation1 = XCTestExpectation(description: "Animation 1 completion")
        let expectation2 = XCTestExpectation(description: "Animation 2 completion")
        let expectation3 = XCTestExpectation(description: "Animation 3 completion")

        animationCoordinator.coordinateCardSelection(cardId: UUID(), characterType: .pacala) {
            expectation1.fulfill()
        }
        animationCoordinator.coordinateCardPlay(
            card: Card(value: 12, suit: .diamonds),
            from: CGPoint.zero,
            to: CGPoint(x: 100, y: 100),
            characterType: .zmeu
        ) {
            expectation2.fulfill()
        }
        animationCoordinator.coordinateEmoteAnimation(
            emoteType: .victory,
            characterType: .fatFrumos
        ) {
            expectation3.fulfill()
        }

        XCTAssertEqual(animationCoordinator.activeAnimationCount, 3)

        // WHEN
        animationCoordinator.cancelAllAnimations()

        // THEN
        XCTAssertEqual(animationCoordinator.activeAnimationCount, 0)

        // Wait for completion callbacks
        wait(for: [expectation1, expectation2, expectation3], timeout: 1.0)
    }

    // MARK: - Performance Tests

    func testAnimationCoordinationPerformance() {
        // GIVEN
        let card = Card(value: 13, suit: .clubs)

        // WHEN & THEN
        measure {
            for i in 0..<100 {
                animationCoordinator.coordinateCardPlay(
                    card: card,
                    from: CGPoint(x: i, y: i),
                    to: CGPoint(x: i + 100, y: i + 100),
                    characterType: .pacala
                )
            }
            animationCoordinator.cancelAllAnimations()
        }
    }

    func testConcurrentAnimationCoordination() {
        // GIVEN
        let expectation = XCTestExpectation(description: "Concurrent animations")
        expectation.expectedFulfillmentCount = 50

        // WHEN
        for i in 0..<50 {
            DispatchQueue.global(qos: .userInitiated).async {
                let cardId = UUID()
                self.animationCoordinator.coordinateCardSelection(
                    cardId: cardId,
                    characterType: .pacala
                ) {
                    expectation.fulfill()
                }
            }
        }

        // THEN
        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(animationCoordinator.activeAnimationCount, 0)
    }

    // MARK: - Integration Tests

    func testCompleteGameAnimationSequence() {
        // GIVEN - Simulate a complete game sequence
        let playerCardId = UUID()
        let opponentCardId = UUID()
        let playerCard = Card(value: 10, suit: .hearts)
        let opponentCard = Card(value: 9, suit: .spades)

        let expectation = XCTestExpectation(description: "Complete game sequence")
        expectation.expectedFulfillmentCount = 6

        // WHEN - Deal cards
        animationCoordinator.coordinateCardDealing(
            playerCount: 2,
            cardsPerPlayer: 5
        ) {
            expectation.fulfill()
        }

        // Player selects card
        animationCoordinator.coordinateCardSelection(
            cardId: playerCardId,
            characterType: .pacala
        ) {
            expectation.fulfill()
        }

        // Player plays card
        animationCoordinator.coordinateCardPlay(
            card: playerCard,
            from: CGPoint(x: 100, y: 300),
            to: CGPoint(x: 200, y: 200),
            characterType: .pacala
        ) {
            expectation.fulfill()
        }

        // Opponent plays card
        animationCoordinator.coordinateCardPlay(
            card: opponentCard,
            from: CGPoint(x: 300, y: 300),
            to: CGPoint(x: 200, y: 200),
            characterType: .strigoi
        ) {
            expectation.fulfill()
        }

        // Player celebrates victory
        animationCoordinator.coordinateVictoryCelebration(
            characterType: .pacala,
            victoryType: .decisive
        ) {
            expectation.fulfill()
        }

        // Player shows emote
        animationCoordinator.coordinateEmoteAnimation(
            emoteType: .victory,
            characterType: .pacala
        ) {
            expectation.fulfill()
        }

        // THEN
        wait(for: [expectation], timeout: 15.0)
        XCTAssertEqual(animationCoordinator.activeAnimationCount, 0)
    }
}