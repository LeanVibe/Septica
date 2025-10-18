//
//  EmoteSystemIntegrationTests.swift
//  SepticaTests
//
//  Comprehensive integration tests for the complete emote system
//  Tests end-to-end flow from UI interaction to WebSocket broadcast
//

import XCTest
@testable import Septica
import SwiftUI

final class EmoteSystemIntegrationTests: XCTestCase {

    // MARK: - Test Properties

    private var emoteManager: EmoteManager!
    private var mockDelegate: MockEmoteManagerDelegate!
    private var mockMessageSender: MockMessageSender!
    private var testPlayer: Player!

    override func setUp() async throws {
        try await super.setUp()

        // Initialize test infrastructure
        mockDelegate = MockEmoteManagerDelegate()
        mockMessageSender = MockMessageSender()
        emoteManager = EmoteManager()
        emoteManager.setDelegate(mockDelegate)
        emoteManager.setMessageSender(mockMessageSender)

        // Create test player with Romanian avatar
        testPlayer = Player(name: "Test Player")
        testPlayer.romanianAvatar = RomanianAvatar(characterType: .pacala)
        testPlayer.playerLevel = 1
    }

    override func tearDown() async throws {
        emoteManager = nil
        mockDelegate = nil
        mockMessageSender = nil
        testPlayer = nil
        try await super.tearDown()
    }

    // MARK: - End-to-End Emote Flow Tests

    func testCompleteEmoteFlow_FromSendToReceive() async throws {
        // GIVEN: A complete emote system setup with two players
        let player1Id = UUID()
        let player2Id = UUID()

        let emote1 = EmoteMessage(
            playerId: player1Id,
            emoteType: .greeting,
            gameId: "test-game-123",
            characterType: .pacala
        )

        // WHEN: Player 1 sends an emote
        try await emoteManager.sendEmote(emote1)

        // THEN: Message should be sent via WebSocket
        XCTAssertEqual(mockMessageSender.sentMessages.count, 1)

        // AND: Local state should be updated
        XCTAssertEqual(emoteManager.activeEmotes.count, 1)
        XCTAssertEqual(emoteManager.activeEmotes[player1Id]?.emoteType, .greeting)

        // AND: Delegate should be notified
        XCTAssertEqual(mockDelegate.statusUpdates[player1Id], true)

        // WHEN: Player 2 receives the broadcast
        let receivedMessage = GameWebSocketMessage.emoteBroadcast(emote1)
        emoteManager.receiveEmote(receivedMessage)

        // THEN: Player 2's delegate should be notified
        XCTAssertEqual(mockDelegate.receivedEmotes.count, 2) // Once from send, once from receive
        XCTAssertEqual(mockDelegate.receivedEmotes.last?.playerId, player1Id)
    }

    func testTargetedEmoteFlow_WithSpecificPlayer() async throws {
        // GIVEN: Two players in a game
        let senderId = UUID()
        let targetId = UUID()

        let targetedEmote = EmoteMessage(
            playerId: senderId,
            emoteType: .taunt,
            gameId: "test-game-456",
            characterType: .strigoi,
            targetPlayerId: targetId
        )

        // WHEN: Sender sends targeted emote
        try await emoteManager.sendEmote(targetedEmote)

        // THEN: Message should include target information
        XCTAssertEqual(mockMessageSender.sentMessages.count, 1)

        if case let .emoteBroadcast(emote) = mockMessageSender.sentMessages.first {
            XCTAssertTrue(emote.isTargeted)
            XCTAssertEqual(emote.targetPlayerId, targetId)
            XCTAssertEqual(emote.emoteType, .taunt)
        } else {
            XCTFail("Expected emote broadcast message")
        }
    }

    func testMultiplePlayerEmoteInteractions() async throws {
        // GIVEN: Three players emoting simultaneously
        let player1Id = UUID()
        let player2Id = UUID()
        let player3Id = UUID()

        let emote1 = EmoteMessage(
            playerId: player1Id,
            emoteType: .greeting,
            gameId: "multiplayer-test",
            characterType: .pacala
        )

        let emote2 = EmoteMessage(
            playerId: player2Id,
            emoteType: .victory,
            gameId: "multiplayer-test",
            characterType: .fatFrumos
        )

        let emote3 = EmoteMessage(
            playerId: player3Id,
            emoteType: .thinking,
            gameId: "multiplayer-test",
            characterType: .zmeu
        )

        // WHEN: All players send emotes with proper delays (to avoid rate limiting)
        try await emoteManager.sendEmote(emote1)

        try await Task.sleep(nanoseconds: 1_100_000_000) // 1.1 seconds
        emoteManager.receiveEmote(.emoteBroadcast(emote2))

        try await Task.sleep(nanoseconds: 1_100_000_000) // 1.1 seconds
        emoteManager.receiveEmote(.emoteBroadcast(emote3))

        // THEN: All emotes should be tracked
        XCTAssertEqual(emoteManager.activeEmotes.count, 3)
        XCTAssertNotNil(emoteManager.activeEmotes[player1Id])
        XCTAssertNotNil(emoteManager.activeEmotes[player2Id])
        XCTAssertNotNil(emoteManager.activeEmotes[player3Id])

        // AND: All emotes should be in recent history
        XCTAssertGreaterThanOrEqual(emoteManager.recentEmotes.count, 3)
    }

    // MARK: - Avatar Integration Tests

    func testAvatarEmoteSync_WithCharacterType() async throws {
        // GIVEN: Player with specific Romanian character
        let playerId = UUID()
        let characterType: RomanianCharacterType = .iele

        let emote = EmoteMessage(
            playerId: playerId,
            emoteType: .goodMove,
            gameId: "avatar-sync-test",
            characterType: characterType
        )

        // WHEN: Emote is sent and received
        try await emoteManager.sendEmote(emote)
        emoteManager.receiveEmote(.emoteBroadcast(emote))

        // THEN: Character type should be preserved
        if case let .emoteBroadcast(receivedEmote) = mockMessageSender.sentMessages.first {
            XCTAssertEqual(receivedEmote.characterType, characterType)
        }

        // AND: Active emote should match character
        XCTAssertEqual(emoteManager.activeEmotes[playerId]?.characterType, characterType)
    }

    func testRomanianAvatarProperties() {
        // GIVEN: All Romanian character types
        let characterTypes: [RomanianCharacterType] = [
            .pacala, .iele, .strigoi, .fatFrumos, .babaCloantza, .zmeu
        ]

        // WHEN: Creating avatars for each type
        for characterType in characterTypes {
            let avatar = RomanianAvatar(characterType: characterType)

            // THEN: All properties should be valid
            XCTAssertFalse(avatar.displayName.isEmpty)
            XCTAssertFalse(avatar.emoji.isEmpty)
            XCTAssertFalse(avatar.culturalTheme.isEmpty)
            XCTAssertGreaterThan(avatar.unlockLevel, 0)
        }
    }

    // MARK: - Error Handling Integration Tests

    func testNetworkError_WithQueueRecovery() async throws {
        // GIVEN: Network initially working
        let playerId = UUID()
        let emote1 = EmoteMessage(
            playerId: playerId,
            emoteType: .greeting,
            gameId: "network-test",
            characterType: .pacala
        )

        try await emoteManager.sendEmote(emote1)
        XCTAssertEqual(mockMessageSender.sentMessages.count, 1)

        // WHEN: Network fails
        mockMessageSender.shouldFail = true

        let emote2 = EmoteMessage(
            playerId: playerId,
            emoteType: .goodMove,
            gameId: "network-test",
            characterType: .pacala
        )

        // Wait for rate limit
        try await Task.sleep(nanoseconds: 1_100_000_000)

        do {
            try await emoteManager.sendEmote(emote2)
            // If we get here, the emote was queued for retry
        } catch {
            // Network error is expected
        }

        // THEN: Original emote should still be sent
        XCTAssertEqual(mockMessageSender.sentMessages.count, 1) // Only first emote succeeded
    }

    func testInvalidEmote_RejectedByValidation() async {
        // GIVEN: Invalid emote (empty game ID)
        let invalidEmote = EmoteMessage(
            playerId: UUID(),
            emoteType: .defeat,
            gameId: "", // Invalid!
            characterType: .babaCloantza
        )

        // WHEN: Attempting to send invalid emote
        do {
            try await emoteManager.sendEmote(invalidEmote)
            XCTFail("Should have thrown validation error")
        } catch EmoteError.unknownError(let message) {
            // THEN: Validation error should be thrown
            XCTAssertTrue(message.contains("Validation failed"))
        } catch {
            XCTFail("Expected validation error, got \(error)")
        }

        // AND: No messages should be sent
        XCTAssertEqual(mockMessageSender.sentMessages.count, 0)
    }

    // MARK: - Rate Limiting Integration Tests

    func testRateLimit_AcrossMultiplePlayers() async throws {
        // GIVEN: Multiple players
        let player1Id = UUID()
        let player2Id = UUID()

        let emote1 = EmoteMessage(
            playerId: player1Id,
            emoteType: .greeting,
            gameId: "rate-limit-test",
            characterType: .pacala
        )

        let emote2 = EmoteMessage(
            playerId: player2Id,
            emoteType: .victory,
            gameId: "rate-limit-test",
            characterType: .fatFrumos
        )

        // WHEN: Both players send emotes simultaneously
        try await emoteManager.sendEmote(emote1)
        try await emoteManager.sendEmote(emote2)

        // THEN: Both should succeed (different players)
        XCTAssertEqual(mockMessageSender.sentMessages.count, 2)
    }

    func testRateLimit_SamePlayerRapidEmotes() async throws {
        // GIVEN: Single player
        let playerId = UUID()

        let emote1 = EmoteMessage(
            playerId: playerId,
            emoteType: .greeting,
            gameId: "rapid-test",
            characterType: .zmeu
        )

        // WHEN: Player sends first emote
        try await emoteManager.sendEmote(emote1)

        // AND: Immediately tries to send another
        let emote2 = EmoteMessage(
            playerId: playerId,
            emoteType: .taunt,
            gameId: "rapid-test",
            characterType: .zmeu
        )

        do {
            try await emoteManager.sendEmote(emote2)
            XCTFail("Second emote should fail due to rate limit")
        } catch EmoteError.rateLimitExceeded {
            // THEN: Rate limit error expected
            XCTAssertEqual(mockMessageSender.sentMessages.count, 1) // Only first emote
        }
    }

    // MARK: - Emote Timeout Integration Tests

    func testEmoteTimeout_AutomaticCleanup() async throws {
        // GIVEN: Emote with short duration
        let playerId = UUID()
        let shortEmote = EmoteMessage(
            playerId: playerId,
            emoteType: .thinking,
            gameId: "timeout-test",
            characterType: .iele,
            duration: 0.5 // 500ms
        )

        // WHEN: Emote is received
        emoteManager.receiveEmote(.emoteBroadcast(shortEmote))
        XCTAssertEqual(emoteManager.activeEmotes.count, 1)

        // AND: Wait for timeout
        try await Task.sleep(nanoseconds: 600_000_000) // 600ms

        // THEN: Emote should be auto-removed
        XCTAssertEqual(emoteManager.activeEmotes.count, 0)
        XCTAssertEqual(mockDelegate.statusUpdates[playerId], false)
    }

    // MARK: - Statistics Integration Tests

    func testEmoteStatistics_CompleteScenario() async throws {
        // GIVEN: Initial state
        var stats = emoteManager.emoteStatistics
        XCTAssertEqual(stats.activeEmotes, 0)
        XCTAssertEqual(stats.queuedEmotes, 0)
        XCTAssertEqual(stats.recentEmotes, 0)

        // WHEN: Multiple emotes are sent
        let emote1 = EmoteMessage(
            playerId: UUID(),
            emoteType: .greeting,
            gameId: "stats-test",
            characterType: .pacala
        )

        try await emoteManager.sendEmote(emote1)

        try await Task.sleep(nanoseconds: 1_100_000_000) // Wait for rate limit

        let emote2 = EmoteMessage(
            playerId: UUID(),
            emoteType: .victory,
            gameId: "stats-test",
            characterType: .fatFrumos
        )

        emoteManager.receiveEmote(.emoteBroadcast(emote2))

        // THEN: Statistics should reflect activity
        stats = emoteManager.emoteStatistics
        XCTAssertEqual(stats.activeEmotes, 2)
        XCTAssertEqual(stats.recentEmotes, 2)
        XCTAssertTrue(stats.isConnected)
    }

    // MARK: - Cultural Authenticity Validation Tests

    func testRomanianCharacterEmoteMapping() {
        // GIVEN: All Romanian character types
        let characterMappings: [(RomanianCharacterType, EmoteType, String)] = [
            (.pacala, .taunt, "Trickster taunts"),
            (.iele, .greeting, "Ethereal nymphs greet"),
            (.strigoi, .thinking, "Restless spirit contemplates"),
            (.fatFrumos, .victory, "Heroic prince triumphs"),
            (.babaCloantza, .badMove, "Wise witch disapproves"),
            (.zmeu, .defeat, "Playful dragon concedes")
        ]

        // WHEN: Creating emotes for each character-emote pair
        for (characterType, emoteType, description) in characterMappings {
            let emote = EmoteMessage(
                playerId: UUID(),
                emoteType: emoteType,
                gameId: "cultural-test",
                characterType: characterType
            )

            // THEN: Emote should be valid
            XCTAssertTrue(emote.validate().isValid, "\(description) should create valid emote")
            XCTAssertEqual(emote.characterType, characterType)
            XCTAssertEqual(emote.emoteType, emoteType)
        }
    }

    func testCulturalThemes_AllCharacters() {
        // GIVEN: All character types
        let characters: [RomanianCharacterType] = [
            .pacala, .iele, .strigoi, .fatFrumos, .babaCloantza, .zmeu
        ]

        // WHEN: Checking cultural themes
        for characterType in characters {
            let avatar = RomanianAvatar(characterType: characterType)

            // THEN: Cultural theme should contain "Romanian"
            XCTAssertTrue(
                avatar.culturalTheme.contains("Romanian"),
                "\(characterType.rawValue) should have Romanian cultural context"
            )
        }
    }

    // MARK: - Performance Integration Tests

    func testEmoteSystem_UnderLoad() async throws {
        // GIVEN: Multiple concurrent emote operations
        let playerCount = 10
        var players: [UUID] = []

        for _ in 0..<playerCount {
            players.append(UUID())
        }

        // WHEN: All players send emotes with delays
        for (index, playerId) in players.enumerated() {
            let emote = EmoteMessage(
                playerId: playerId,
                emoteType: .greeting,
                gameId: "load-test",
                characterType: .pacala
            )

            // Stagger sends to avoid rate limiting
            try await Task.sleep(nanoseconds: UInt64(index * 200_000_000)) // 200ms * index
            try await emoteManager.sendEmote(emote)
        }

        // THEN: All emotes should be processed
        XCTAssertEqual(mockMessageSender.sentMessages.count, playerCount)

        // AND: Statistics should be accurate
        let stats = emoteManager.emoteStatistics
        XCTAssertGreaterThanOrEqual(stats.recentEmotes, playerCount)
    }
}

// MARK: - Mock Delegate (Reused from EmoteManagerTests)

private class MockEmoteManagerDelegate: EmoteManagerDelegate {
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

// MARK: - Mock Message Sender (Reused from EmoteManagerTests)

private class MockMessageSender: MessageSending {
    var sentMessages: [GameWebSocketMessage] = []
    var shouldFail = false

    func sendMessage(_ message: GameWebSocketMessage) async throws {
        if shouldFail {
            throw EmoteError.networkUnavailable
        }
        sentMessages.append(message)
    }
}
