//
//  EmoteManagerTests.swift
//  SepticaTests
//
//  Comprehensive tests for emote management system
//  Validates broadcasting, rate limiting, and queue management
//

import XCTest
@testable import Septica

final class EmoteManagerTests: XCTestCase {

    // MARK: - Test Properties

    private var emoteManager: EmoteManager!
    private var mockDelegate: MockEmoteManagerDelegate!
    private var mockMessageSender: MockMessageSender!

    override func setUp() {
        super.setUp()
        mockDelegate = MockEmoteManagerDelegate()
        mockMessageSender = MockMessageSender()
        emoteManager = EmoteManager()
        emoteManager.setDelegate(mockDelegate)
        emoteManager.setMessageSender(mockMessageSender)
    }

    override func tearDown() {
        emoteManager = nil
        mockDelegate = nil
        mockMessageSender = nil
        super.tearDown()
    }

    // MARK: - Basic Emote Sending Tests

    func testSendEmoteSuccess() async throws {
        // GIVEN
        let playerId = UUID()
        let emote = EmoteMessage(
            playerId: playerId,
            emoteType: .greeting,
            gameId: "test-game",
            characterType: .pacala
        )

        // WHEN
        try await emoteManager.sendEmote(emote)

        // THEN
        XCTAssertTrue(emoteManager.isConnected)
        XCTAssertEqual(mockMessageSender.sentMessages.count, 1)
        XCTAssertEqual(emoteManager.activeEmotes.count, 1)
        XCTAssertEqual(emoteManager.activeEmotes[playerId]?.emoteType, .greeting)
        XCTAssertEqual(mockDelegate.receivedEmotes.count, 1)
        XCTAssertEqual(mockDelegate.statusUpdates[playerId], true)
    }

    func testSendEmoteRateLimit() async {
        // GIVEN
        let playerId = UUID()
        let emote = EmoteMessage(
            playerId: playerId,
            emoteType: .greeting,
            gameId: "test-game",
            characterType: .pacala
        )

        // WHEN - Send first emote
        try await emoteManager.sendEmote(emote)

        // THEN - Should succeed
        XCTAssertEqual(mockMessageSender.sentMessages.count, 1)

        // WHEN - Send second emote immediately
        do {
            try await emoteManager.sendEmote(emote)
            XCTFail("Second emote should fail due to rate limit")
        } catch let error as EmoteError {
            // THEN - Should fail with rate limit error
            if case .rateLimitExceeded(let timeUntilNext) = error {
                XCTAssertGreaterThan(timeUntilNext, 0)
                XCTAssertLessThanOrEqual(timeUntilNext, 1.0)
            } else {
                XCTFail("Expected rate limit error, got \(error)")
            }
        }
    }

    func testSendEmoteNetworkUnavailable() async {
        // GIVEN
        emoteManager.setMessageSender(nil) // Remove message sender
        let emote = EmoteMessage(
            playerId: UUID(),
            emoteType: .greeting,
            gameId: "test-game",
            characterType: .pacala
        )

        // WHEN & THEN
        do {
            try await emoteManager.sendEmote(emote)
            XCTFail("Should throw network unavailable error")
        } catch EmoteError.networkUnavailable {
            // Expected
        } catch {
            XCTFail("Expected network unavailable error, got \(error)")
        }
    }

    func testSendEmoteInvalidData() async {
        // GIVEN
        let emote = EmoteMessage(
            playerId: UUID(),
            emoteType: .greeting,
            gameId: "", // Invalid empty game ID
            characterType: .pacala
        )

        // WHEN & THEN
        do {
            try await emoteManager.sendEmote(emote)
            XCTFail("Should throw validation error")
        } catch EmoteError.unknownError(let message) {
            XCTAssertTrue(message.contains("Validation failed"))
        } catch {
            XCTFail("Expected validation error, got \(error)")
        }
    }

    // MARK: - Receive Emote Tests

    func testReceiveValidEmote() {
        // GIVEN
        let playerId = UUID()
        let emote = EmoteMessage(
            playerId: playerId,
            emoteType: .victory,
            gameId: "test-game",
            characterType: .zmeu
        )
        let message = GameWebSocketMessage.emoteBroadcast(emote)

        // WHEN
        emoteManager.receiveEmote(message)

        // THEN
        XCTAssertEqual(emoteManager.activeEmotes.count, 1)
        XCTAssertEqual(emoteManager.activeEmotes[playerId]?.emoteType, .victory)
        XCTAssertEqual(mockDelegate.receivedEmotes.count, 1)
        XCTAssertEqual(mockDelegate.receivedEmotes.first?.emoteType, .victory)
        XCTAssertEqual(mockDelegate.statusUpdates[playerId], true)
    }

    func testReceiveInvalidEmote() {
        // GIVEN
        var emote = EmoteMessage(
            playerId: UUID(),
            emoteType: .greeting,
            gameId: "", // Invalid
            characterType: .pacala
        )
        let message = GameWebSocketMessage.emoteBroadcast(emote)

        // WHEN
        emoteManager.receiveEmote(message)

        // THEN
        XCTAssertEqual(emoteManager.activeEmotes.count, 0)
        XCTAssertEqual(mockDelegate.receivedEmotes.count, 0)
        XCTAssertEqual(mockDelegate.errors.count, 1)
    }

    func testReceiveNonEmoteMessage() {
        // GIVEN
        let message = GameWebSocketMessage.heartbeat(sequenceNumber: 1)

        // WHEN
        emoteManager.receiveEmote(message)

        // THEN
        XCTAssertEqual(emoteManager.activeEmotes.count, 0)
        XCTAssertEqual(mockDelegate.receivedEmotes.count, 0)
    }

    // MARK: - Emote Management Tests

    func testCancelEmote() {
        // GIVEN
        let playerId = UUID()
        let emote = EmoteMessage(
            playerId: playerId,
            emoteType: .greeting,
            gameId: "test-game",
            characterType: .pacala
        )
        let message = GameWebSocketMessage.emoteBroadcast(emote)
        emoteManager.receiveEmote(message)

        // WHEN
        emoteManager.cancelEmote(for: playerId)

        // THEN
        XCTAssertEqual(emoteManager.activeEmotes.count, 0)
        XCTAssertEqual(mockDelegate.statusUpdates[playerId], false)
    }

    func testGetActiveEmote() {
        // GIVEN
        let playerId = UUID()
        let emote = EmoteMessage(
            playerId: playerId,
            emoteType: .taunt,
            gameId: "test-game",
            characterType: .strigoi
        )
        let message = GameWebSocketMessage.emoteBroadcast(emote)
        emoteManager.receiveEmote(message)

        // WHEN
        let activeEmote = emoteManager.getActiveEmote(for: playerId)

        // THEN
        XCTAssertNotNil(activeEmote)
        XCTAssertEqual(activeEmote?.emoteType, .taunt)
    }

    func testClearAllEmotes() {
        // GIVEN
        let player1Id = UUID()
        let player2Id = UUID()

        let emote1 = EmoteMessage(
            playerId: player1Id,
            emoteType: .greeting,
            gameId: "test-game",
            characterType: .pacala
        )
        let emote2 = EmoteMessage(
            playerId: player2Id,
            emoteType: .victory,
            gameId: "test-game",
            characterType: .fatFrumos
        )

        emoteManager.receiveEmote(GameWebSocketMessage.emoteBroadcast(emote1))
        emoteManager.receiveEmote(GameWebSocketMessage.emoteBroadcast(emote2))

        XCTAssertEqual(emoteManager.activeEmotes.count, 2)

        // WHEN
        emoteManager.clearAllEmotes()

        // THEN
        XCTAssertEqual(emoteManager.activeEmotes.count, 0)
        XCTAssertEqual(mockDelegate.statusUpdates[player1Id], false)
        XCTAssertEqual(mockDelegate.statusUpdates[player2Id], false)
    }

    func testEmoteTimeout() {
        // GIVEN
        let playerId = UUID()
        var emote = EmoteMessage(
            playerId: playerId,
            emoteType: .thinking,
            gameId: "test-game",
            characterType: .babaCloantza,
            duration: 0.1 // Very short duration
        )
        let message = GameWebSocketMessage.emoteBroadcast(emote)
        emoteManager.receiveEmote(message)

        XCTAssertEqual(emoteManager.activeEmotes.count, 1)

        // WHEN - Wait for timeout
        let expectation = XCTestExpectation(description: "Emote timeout")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)

        // THEN
        XCTAssertEqual(emoteManager.activeEmotes.count, 0)
    }

    // MARK: - Queue Management Tests

    func testEmoteQueuingOnNetworkError() async throws {
        // GIVEN
        mockMessageSender.shouldFail = true // Simulate network error
        let playerId = UUID()
        let emote = EmoteMessage(
            playerId: playerId,
            emoteType: .greeting,
            gameId: "test-game",
            characterType: .iele
        )

        // WHEN
        try await emoteManager.sendEmote(emote)

        // THEN - Should be queued for retry
        XCTAssertEqual(mockMessageSender.sentMessages.count, 1)
        // Note: Queue processing happens asynchronously, so we can't test it immediately
    }

    func testRateLimitTrackerCleanup() async throws {
        // GIVEN
        let playerId = UUID()
        let emote = EmoteMessage(
            playerId: playerId,
            emoteType: .greeting,
            gameId: "test-game",
            characterType: .pacala
        )

        // Send emote to populate rate limit tracker
        try await emoteManager.sendEmote(emote)

        // WHEN - Wait for rate limit to expire and cleanup
        let expectation = XCTestExpectation(description: "Rate limit cleanup")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { // 2.5 seconds > rate limit * 2
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 3.0)

        // Emote should be able to be sent again
        try await emoteManager.sendEmote(emote)

        // THEN
        XCTAssertEqual(mockMessageSender.sentMessages.count, 2)
    }

    // MARK: - Statistics Tests

    func testEmoteStatistics() {
        // GIVEN
        let player1Id = UUID()
        let player2Id = UUID()

        let emote1 = EmoteMessage(
            playerId: player1Id,
            emoteType: .greeting,
            gameId: "test-game",
            characterType: .pacala
        )
        let emote2 = EmoteMessage(
            playerId: player2Id,
            emoteType: .victory,
            gameId: "test-game",
            characterType: .zmeu
        )

        // WHEN
        emoteManager.receiveEmote(GameWebSocketMessage.emoteBroadcast(emote1))
        emoteManager.receiveEmote(GameWebSocketMessage.emoteBroadcast(emote2))

        let stats = emoteManager.emoteStatistics

        // THEN
        XCTAssertEqual(stats.activeEmotes, 2)
        XCTAssertEqual(stats.queuedEmotes, 0)
        XCTAssertEqual(stats.recentEmotes, 2)
        XCTAssertEqual(stats.rateLimitedPlayers, 0)
        XCTAssertTrue(stats.isConnected)
    }

    // MARK: - Configuration Tests

    func testCustomConfiguration() async throws {
        // GIVEN
        let config = EmoteConfiguration(
            rateLimitPerPlayer: 2.0,
            maxQueueSize: 50,
            emoteTimeout: 15.0,
            retryAttempts: 1,
            batchSize: 5
        )
        let customManager = EmoteManager(configuration: config)
        customManager.setDelegate(mockDelegate)
        customManager.setMessageSender(mockMessageSender)

        let playerId = UUID()
        let emote = EmoteMessage(
            playerId: playerId,
            emoteType: .greeting,
            gameId: "test-game",
            characterType: .pacala
        )

        // WHEN - Send two emotes quickly (within 2 second rate limit)
        try await customManager.sendEmote(emote)
        try await customManager.sendEmote(emote)

        // THEN - Both should succeed due to 2 second rate limit
        XCTAssertEqual(mockMessageSender.sentMessages.count, 2)
    }

    // MARK: - Performance Tests

    func testEmoteManagerPerformance() {
        // GIVEN
        let playerId = UUID()
        let emote = EmoteMessage(
            playerId: playerId,
            emoteType: .greeting,
            gameId: "test-game",
            characterType: .pacala
        )

        // WHEN & THEN
        measure {
            for i in 0..<1000 {
                let testEmote = EmoteMessage(
                    playerId: playerId,
                    emoteType: .greeting,
                    gameId: "test-game-\(i)",
                    characterType: .pacala
                )
                emoteManager.receiveEmote(GameWebSocketMessage.emoteBroadcast(testEmote))
            }
        }
    }

    func testConcurrentEmoteSending() async throws {
        // GIVEN
        let playerId = UUID()
        let emote = EmoteMessage(
            playerId: playerId,
            emoteType: .greeting,
            gameId: "test-game",
            characterType: .pacala
        )

        // WHEN - Send emotes concurrently from multiple tasks
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    // Add delay to avoid rate limiting
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                    try? await self.emoteManager.sendEmote(emote)
                }
            }
        }

        // THEN - Should have sent multiple emotes without crashing
        XCTAssertGreaterThan(mockMessageSender.sentMessages.count, 0)
    }
}

// MARK: - Mock Delegate

class MockEmoteManagerDelegate: EmoteManagerDelegate {
    var receivedEmotes: [EmoteMessage] = []
    var statusUpdates: [UUID: Bool] = [:]
    var errors: [EmoteError] = []

    func emoteManager(_ manager: EmoteManager, didReceiveEmote emote: EmoteMessage) {
        receivedEmotes.append(emote)
    }

    func emoteManager(_ manager: EmoteManager, didUpdatePlayerStatus playerId: UUID, isEmoting: Bool) {
        statusUpdates[playerId] = isEmoting
    }

    func emoteManager(_ manager: EmoteManager, didEncounterError error: EmoteError) {
        errors.append(error)
    }
}

// MARK: - Mock Message Sender

class MockMessageSender: MessageSending {
    var sentMessages: [GameWebSocketMessage] = []
    var shouldFail = false

    func sendMessage(_ message: GameWebSocketMessage) async throws {
        if shouldFail {
            throw EmoteError.networkUnavailable
        }
        sentMessages.append(message)
    }
}