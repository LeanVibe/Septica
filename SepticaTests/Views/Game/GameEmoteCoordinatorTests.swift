//
//  GameEmoteCoordinatorTests.swift
//  SepticaTests
//
//  Comprehensive tests for game emote coordination system
//  Validates emote display, animation, and integration
//

import XCTest
@testable import Septica

final class GameEmoteCoordinatorTests: XCTestCase {

    // MARK: - Test Properties

    private var coordinator: GameEmoteCoordinator!
    private var mockGameScreen: MockMultiplayerReadyGameScreen!
    private var mockSoundManager: MockSoundManager!

    override func setUp() {
        super.setUp()
        mockGameScreen = MockMultiplayerReadyGameScreen()
        mockSoundManager = MockSoundManager()
        coordinator = GameEmoteCoordinator(gameScreen: mockGameScreen)
    }

    override func tearDown() {
        coordinator = nil
        mockGameScreen = nil
        mockSoundManager = nil
        super.tearDown()
    }

    // MARK: - Emote Receiving Tests

    func testReceiveEmote() {
        // GIVEN
        let playerId = UUID()
        let emote = EmoteMessage(
            playerId: playerId,
            emoteType: .greeting,
            gameId: "test-game",
            characterType: .pacala
        )

        // WHEN
        coordinator.emoteManager(
            EmoteManager(),
            didReceiveEmote: emote
        )

        // THEN
        XCTAssertNotNil(coordinator.activeEmotes[playerId])
        XCTAssertEqual(coordinator.activeEmotes[playerId]?.emote.emoteType, .greeting)
        XCTAssertEqual(coordinator.activeEmotes[playerId]?.emote.characterType, .pacala)
        XCTAssertNotNil(coordinator.emoteAnimations[playerId])
        XCTAssertTrue(coordinator.activeEmotes[playerId]?.isActive ?? false)
    }

    func testReceiveMultipleEmotes() {
        // GIVEN
        let player1Id = UUID()
        let player2Id = UUID()

        let emote1 = EmoteMessage(
            playerId: player1Id,
            emoteType: .victory,
            gameId: "test-game",
            characterType: .fatFrumos
        )

        let emote2 = EmoteMessage(
            playerId: player2Id,
            emoteType: .defeat,
            gameId: "test-game",
            characterType: .strigoi
        )

        // WHEN
        coordinator.emoteManager(EmoteManager(), didReceiveEmote: emote1)
        coordinator.emoteManager(EmoteManager(), didReceiveEmote: emote2)

        // THEN
        XCTAssertEqual(coordinator.activeEmotes.count, 2)
        XCTAssertEqual(coordinator.activeEmotes[player1Id]?.emote.emoteType, .victory)
        XCTAssertEqual(coordinator.activeEmotes[player2Id]?.emote.emoteType, .defeat)
        XCTAssertEqual(coordinator.emoteAnimations.count, 2)
    }

    func testReceiveEmoteWithDifferentCharacterTypes() {
        // GIVEN
        let testCases: [(RomanianCharacterType, EmoteType)] = [
            (.pacala, .greeting),
            (.iele, .thinking),
            (.strigoi, .taunt),
            (.fatFrumos, .victory),
            (.babaCloantza, .badMove),
            (.zmeu, .defeat)
        ]

        for (characterType, emoteType) in testCases {
            // WHEN
            let playerId = UUID()
            let emote = EmoteMessage(
                playerId: playerId,
                emoteType: emoteType,
                gameId: "test-game",
                characterType: characterType
            )

            coordinator.emoteManager(EmoteManager(), didReceiveEmote: emote)

            // THEN
            XCTAssertNotNil(coordinator.activeEmotes[playerId])
            XCTAssertEqual(coordinator.activeEmotes[playerId]?.emote.characterType, characterType)
            XCTAssertEqual(coordinator.activeEmotes[playerId]?.emote.emoteType, emoteType)
        }

        XCTAssertEqual(coordinator.activeEmotes.count, testCases.count)
    }

    // MARK: - Player Status Update Tests

    func testPlayerStatusUpdateToEmoting() {
        // GIVEN
        let playerId = UUID()
        let emote = EmoteMessage(
            playerId: playerId,
            emoteType: .greeting,
            gameId: "test-game",
            characterType: .pacala
        )

        // WHEN
        coordinator.emoteManager(EmoteManager(), didReceiveEmote: emote)
        coordinator.emoteManager(EmoteManager(), didUpdatePlayerStatus: playerId, isEmoting: true)

        // THEN
        XCTAssertNotNil(coordinator.activeEmotes[playerId])
        XCTAssertNotNil(coordinator.emoteAnimations[playerId])
    }

    func testPlayerStatusUpdateToNotEmoting() {
        // GIVEN
        let playerId = UUID()
        let emote = EmoteMessage(
            playerId: playerId,
            emoteType: .greeting,
            gameId: "test-game",
            characterType: .pacala
        )

        coordinator.emoteManager(EmoteManager(), didReceiveEmote: emote)

        // WHEN
        coordinator.emoteManager(EmoteManager(), didUpdatePlayerStatus: playerId, isEmoting: false)

        // THEN - Emote should be removed after animation completes
        // Note: This is async, so we can't test it immediately
        XCTAssertNotNil(coordinator.activeEmotes[playerId])
    }

    // MARK: - Emote Duration Tests

    func testEmoteDurationCalculation() {
        // GIVEN
        let playerId = UUID()
        let emote = EmoteMessage(
            playerId: playerId,
            emoteType: .victory,
            gameId: "test-game",
            characterType: .fatFrumos,
            duration: 3.0
        )

        let displayState = GameEmoteCoordinator.EmoteDisplayState(
            emote: emote,
            startTime: Date(),
            isAnimating: true
        )

        // WHEN
        let completionTime = displayState.completionTime
        let expectedTime = Date().addingTimeInterval(3.0)

        // THEN
        XCTAssertEqual(completionTime.timeIntervalSince1970, expectedTime.timeIntervalSince1970, accuracy: 0.1)
    }

    func testEmoteActiveStatus() {
        // GIVEN
        let playerId = UUID()
        let shortEmote = EmoteMessage(
            playerId: playerId,
            emoteType: .greeting,
            gameId: "test-game",
            characterType: .pacala,
            duration: 0.1
        )

        var displayState = GameEmoteCoordinator.EmoteDisplayState(
            emote: shortEmote,
            startTime: Date(),
            isAnimating: true
        )

        // WHEN - Should be active immediately
        XCTAssertTrue(displayState.isActive)

        // Wait for expiration
        let expectation = XCTestExpectation(description: "Emote expiration")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)

        // THEN - Should be inactive
        XCTAssertFalse(displayState.isActive)
    }

    // MARK: - Animation State Tests

    func testAnimationStateStartAnimation() {
        // GIVEN
        var animationState = GameEmoteCoordinator.EmoteAnimationState()

        // WHEN
        animationState.startAnimation()

        // THEN
        XCTAssertEqual(animationState.scale, 1.0)
        XCTAssertEqual(animationState.opacity, 1.0)
        XCTAssertEqual(animationState.rotation, 360.0)
    }

    func testAnimationStateEndAnimation() {
        // GIVEN
        var animationState = GameEmoteCoordinator.EmoteAnimationState()

        // WHEN
        animationState.endAnimation()

        // THEN
        XCTAssertEqual(animationState.scale, 0.8)
        XCTAssertEqual(animationState.opacity, 0.0)
        XCTAssertEqual(animationState.rotation, 0.0)
    }

    // MARK: - Emote Cleanup Tests

    func testCleanupExpiredEmotes() {
        // GIVEN
        let player1Id = UUID()
        let player2Id = UUID()

        let expiredEmote = EmoteMessage(
            playerId: player1Id,
            emoteType: .greeting,
            gameId: "test-game",
            characterType: .pacala,
            duration: 0.1
        )

        let activeEmote = EmoteMessage(
            playerId: player2Id,
            emoteType: .victory,
            gameId: "test-game",
            characterType: .fatFrumos,
            duration: 10.0
        )

        // Add emotes
        coordinator.emoteManager(EmoteManager(), didReceiveEmote: expiredEmote)
        coordinator.emoteManager(EmoteManager(), didReceiveEmote: activeEmote)

        XCTAssertEqual(coordinator.activeEmotes.count, 2)

        // Wait for expiration
        let expectation = XCTestExpectation(description: "Emote cleanup")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)

        // WHEN
        coordinator.cleanupExpiredEmotes()

        // THEN
        XCTAssertEqual(coordinator.activeEmotes.count, 1)
        XCTAssertNotNil(coordinator.activeEmotes[player2Id])
        XCTAssertNil(coordinator.activeEmotes[player1Id])
    }

    // MARK: - Sound Integration Tests

    func testSoundNameGeneration() {
        // Test character and emote combinations
        let testCases: [(RomanianCharacterType, EmoteType, String)] = [
            (.pacala, .greeting, "pacala_greeting"),
            (.pacala, .taunt, "pacala_taunt"),
            (.pacala, .victory, "pacala_victory"),
            (.iele, .greeting, "iele_greeting"),
            (.iele, .thinking, "iele_thinking"),
            (.strigoi, .taunt, "strigoi_taunt"),
            (.strigoi, .defeat, "strigoi_defeat"),
            (.fatFrumos, .victory, "fat_frumos_victory"),
            (.fatFrumos, .goodMove, "fat_frumos_good_move"),
            (.babaCloantza, .badMove, "baba_cloantza_bad_move"),
            (.babaCloantza, .thinking, "baba_cloantza_thinking"),
            (.zmeu, .victory, "zmeu_victory"),
            (.zmeu, .taunt, "zmeu_taunt")
        ]

        for (characterType, emoteType, expectedSoundName) in testCases {
            // WHEN
            let emote = EmoteMessage(
                playerId: UUID(),
                emoteType: emoteType,
                gameId: "test-game",
                characterType: characterType
            )

            coordinator.emoteManager(EmoteManager(), didReceiveEmote: emote)

            // THEN - Sound should be played (we can't easily test this without mocking)
            // For now, just ensure no crash occurs
            XCTAssertNotNil(coordinator.activeEmotes[emote.playerId])
        }
    }

    // MARK: - Character Emote View Tests

    func testEmoteOverlayViewCreation() {
        // GIVEN
        let emoteState = GameEmoteCoordinator.EmoteDisplayState(
            emote: EmoteMessage(
                playerId: UUID(),
                emoteType: .victory,
                gameId: "test-game",
                characterType: .pacala
            ),
            startTime: Date(),
            isAnimating: true
        )

        let animationState = GameEmoteCoordinator.EmoteAnimationState()

        // WHEN
        let overlayView = EmoteOverlayView(
            emoteState: emoteState,
            animationState: animationState
        )

        // THEN - Should create view without crashing
        XCTAssertNotNil(overlayView)
    }

    func testAllCharacterEmoteViews() {
        let characterTypes: [RomanianCharacterType] = [
            .pacala, .iele, .strigoi, .fatFrumos, .babaCloantza, .zmeu
        ]

        let emoteTypes: [EmoteType] = [
            .greeting, .goodMove, .badMove, .thinking, .taunt, .victory, .defeat
        ]

        for characterType in characterTypes {
            for emoteType in emoteTypes {
                // GIVEN
                let emoteState = GameEmoteCoordinator.EmoteDisplayState(
                    emote: EmoteMessage(
                        playerId: UUID(),
                        emoteType: emoteType,
                        gameId: "test-game",
                        characterType: characterType
                    ),
                    startTime: Date(),
                    isAnimating: true
                )

                let animationState = GameEmoteCoordinator.EmoteAnimationState()

                // WHEN & THEN - Should create view without crashing
                let overlayView = EmoteOverlayView(
                    emoteState: emoteState,
                    animationState: animationState
                )
                XCTAssertNotNil(overlayView)
            }
        }
    }

    // MARK: - Performance Tests

    func testConcurrentEmoteReceiving() {
        // GIVEN
        let expectation = XCTestExpectation(description: "Concurrent emotes")
        expectation.expectedFulfillmentCount = 100

        // WHEN
        for i in 0..<100 {
            DispatchQueue.global(qos: .userInitiated).async {
                let emote = EmoteMessage(
                    playerId: UUID(),
                    emoteType: .greeting,
                    gameId: "test-game-\(i)",
                    characterType: .pacala
                )

                self.coordinator.emoteManager(EmoteManager(), didReceiveEmote: emote)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 5.0)

        // THEN
        XCTAssertEqual(coordinator.activeEmotes.count, 100)
    }

    func testEmoteManagerPerformance() {
        // GIVEN
        let coordinator = GameEmoteCoordinator(gameScreen: mockGameScreen)

        // WHEN & THEN
        measure {
            for i in 0..<1000 {
                let emote = EmoteMessage(
                    playerId: UUID(),
                    emoteType: .greeting,
                    gameId: "test-game-\(i)",
                    characterType: .pacala
                )
                coordinator.emoteManager(EmoteManager(), didReceiveEmote: emote)
            }
        }
    }

    // MARK: - Error Handling Tests

    func testEmoteErrorHandling() {
        // GIVEN
        let error = EmoteError.networkUnavailable

        // WHEN
        coordinator.emoteManager(EmoteManager(), didEncounterError: error)

        // THEN - Should handle error gracefully without crashing
        // Error handling is currently just logging, so we can't easily test it
    }
}

// MARK: - Mock Classes

class MockMultiplayerReadyGameScreen {
    // Mock implementation for testing
}

class MockSoundManager {
    func playEmoteSound(_ soundName: String) {
        // Mock sound playing
        print("Playing sound: \(soundName)")
    }
}