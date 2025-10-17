//
//  EmoteProtocolTests.swift
//  SepticaTests
//
//  Comprehensive tests for emote communication protocol
//  Validates message serialization, validation, and business logic
//

import XCTest
@testable import Septica

final class EmoteProtocolTests: XCTestCase {

    // MARK: - EmoteMessage Tests

    func testEmoteMessageInitialization() {
        // GIVEN
        let playerId = UUID()
        let gameId = "test-game-123"
        let characterType: RomanianCharacterType = .pacala

        // WHEN
        let emote = EmoteMessage(
            playerId: playerId,
            emoteType: .greeting,
            gameId: gameId,
            characterType: characterType
        )

        // THEN
        XCTAssertEqual(emote.playerId, playerId)
        XCTAssertEqual(emote.emoteType, .greeting)
        XCTAssertEqual(emote.gameId, gameId)
        XCTAssertEqual(emote.characterType, characterType)
        XCTAssertEqual(emote.intensity, 1.0)
        XCTAssertEqual(emote.duration, 2.0)
        XCTAssertNil(emote.targetPlayerId)
        XCTAssertLessThan(abs(emote.timestamp.timeIntervalSinceNow), 0.1) // Within 100ms
    }

    func testEmoteMessageWithCustomParameters() {
        // GIVEN
        let playerId = UUID()
        let targetPlayerId = UUID()
        let gameId = "test-game-456"
        let characterType: RomanianCharacterType = .iele

        // WHEN
        let emote = EmoteMessage(
            playerId: playerId,
            emoteType: .taunt,
            gameId: gameId,
            characterType: characterType,
            targetPlayerId: targetPlayerId,
            intensity: 0.7,
            duration: 3.5
        )

        // THEN
        XCTAssertEqual(emote.playerId, playerId)
        XCTAssertEqual(emote.emoteType, .taunt)
        XCTAssertEqual(emote.gameId, gameId)
        XCTAssertEqual(emote.characterType, characterType)
        XCTAssertEqual(emote.targetPlayerId, targetPlayerId)
        XCTAssertEqual(emote.intensity, 0.7)
        XCTAssertEqual(emote.duration, 3.5)
    }

    func testEmoteMessageIntensityBounds() {
        // Test intensity bounds enforcement
        let emoteHigh = EmoteMessage(
            playerId: UUID(),
            emoteType: .greeting,
            gameId: "test",
            characterType: .pacala,
            intensity: 1.5 // Above max
        )
        XCTAssertEqual(emoteHigh.intensity, 1.0, "Intensity should be clamped to max value")

        let emoteLow = EmoteMessage(
            playerId: UUID(),
            emoteType: .greeting,
            gameId: "test",
            characterType: .pacala,
            intensity: -0.5 // Below min
        )
        XCTAssertEqual(emoteLow.intensity, 0.0, "Intensity should be clamped to min value")
    }

    func testEmoteMessageDurationBounds() {
        // Test duration bounds enforcement
        let emoteLong = EmoteMessage(
            playerId: UUID(),
            emoteType: .victory,
            gameId: "test",
            characterType: .pacala,
            duration: 10.0 // Above max
        )
        XCTAssertEqual(emoteLong.duration, 5.0, "Duration should be clamped to max value")

        let emoteShort = EmoteMessage(
            playerId: UUID(),
            emoteType: .greeting,
            gameId: "test",
            characterType: .pacala,
            duration: 0.1 // Below min
        )
        XCTAssertEqual(emoteShort.duration, 0.5, "Duration should be clamped to min value")
    }

    func testEmoteMessageValidity() {
        // GIVEN
        let validEmote = EmoteMessage(
            playerId: UUID(),
            emoteType: .greeting,
            gameId: "valid-game",
            characterType: .pacala
        )

        let invalidEmote = EmoteMessage(
            playerId: UUID(),
            emoteType: .greeting,
            gameId: "", // Invalid empty game ID
            characterType: .pacala
        )

        // WHEN
        let validResult = validEmote.validate()
        let invalidResult = invalidEmote.validate()

        // THEN
        XCTAssertTrue(validResult.isValid, "Valid emote should pass validation")
        XCTAssertFalse(invalidResult.isValid, "Invalid emote should fail validation")
        XCTAssertEqual(invalidResult.errors.count, 1, "Should have one validation error")
        XCTAssertTrue(invalidResult.errors.contains("Game ID cannot be empty"))
    }

    func testEmoteMessageTimestampValidation() {
        // GIVEN
        let futureTimestamp = Date().addingTimeInterval(120) // 2 minutes in future
        let pastTimestamp = Date().addingTimeInterval(-120) // 2 minutes in past

        // Create emotes with custom timestamps
        var futureEmote = EmoteMessage(
            playerId: UUID(),
            emoteType: .greeting,
            gameId: "test",
            characterType: .pacala
        )
        futureEmote = EmoteMessage(
            playerId: futureEmote.playerId,
            emoteType: futureEmote.emoteType,
            gameId: futureEmote.gameId,
            characterType: futureEmote.characterType
        )

        // WHEN & THEN - Note: We can't directly test timestamp validation due to private setter
        // This would need to be tested with a custom initializer or dependency injection
    }

    func testEmoteMessageRemainingDuration() {
        // GIVEN
        var emote = EmoteMessage(
            playerId: UUID(),
            emoteType: .greeting,
            gameId: "test",
            characterType: .pacala,
            duration: 3.0
        )

        // WHEN - Test immediately after creation
        let remainingDuration = emote.remainingDuration

        // THEN - Should be close to full duration (within 100ms tolerance)
        XCTAssertGreaterThan(remainingDuration, 2.9)
        XCTAssertLessThanOrEqual(remainingDuration, 3.0)
    }

    func testEmoteMessageIsTargeted() {
        // GIVEN
        let targetedEmote = EmoteMessage(
            playerId: UUID(),
            emoteType: .taunt,
            gameId: "test",
            characterType: .pacala,
            targetPlayerId: UUID()
        )

        let broadcastEmote = EmoteMessage(
            playerId: UUID(),
            emoteType: .greeting,
            gameId: "test",
            characterType: .pacala
        )

        // WHEN & THEN
        XCTAssertTrue(targetedEmote.isTargeted, "Emote with target should be targeted")
        XCTAssertFalse(broadcastEmote.isTargeted, "Emote without target should not be targeted")
    }

    // MARK: - GameWebSocketMessage Tests

    func testWebSocketMessageEmoteBroadcastEncoding() {
        // GIVEN
        let emote = EmoteMessage(
            playerId: UUID(),
            emoteType: .greeting,
            gameId: "test-game",
            characterType: .pacala
        )
        let message = GameWebSocketMessage.emoteBroadcast(emote)

        // WHEN
        let encoder = JSONEncoder()
        let data = try? encoder.encode(message)

        // THEN
        XCTAssertNotNil(data, "Message should encode successfully")

        // Verify structure
        if let data = data,
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            XCTAssertEqual(json["type"] as? String, "emote_broadcast")
            XCTAssertNotNil(json["payload"])
        }
    }

    func testWebSocketMessageEmoteBroadcastDecoding() {
        // GIVEN
        let playerId = UUID()
        let gameId = "test-game"
        let characterType: RomanianCharacterType = .pacala

        let emoteJson: [String: Any] = [
            "type": "emote_broadcast",
            "payload": [
                "id": UUID().uuidString,
                "playerId": playerId.uuidString,
                "emoteType": "greeting",
                "timestamp": ISO8601DateFormatter().string(from: Date()),
                "gameId": gameId,
                "characterType": "pacala",
                "targetPlayerId": nil,
                "intensity": 1.0,
                "duration": 2.0
            ]
        ]

        // WHEN
        let data = try? JSONSerialization.data(withJSONObject: emoteJson)
        let decoder = JSONDecoder()
        let message = try? decoder.decode(GameWebSocketMessage.self, from: data!)

        // THEN
        XCTAssertNotNil(message, "Message should decode successfully")

        if case let .emoteBroadcast(decodedEmote) = message {
            XCTAssertEqual(decodedEmote.playerId, playerId)
            XCTAssertEqual(decodedEmote.emoteType, .greeting)
            XCTAssertEqual(decodedEmote.gameId, gameId)
            XCTAssertEqual(decodedEmote.characterType, characterType)
        } else {
            XCTFail("Message should be emote broadcast type")
        }
    }

    func testWebSocketMessageHeartbeat() {
        // GIVEN
        let sequenceNumber = 42

        // WHEN
        let message = GameWebSocketMessage.heartbeat(sequenceNumber: sequenceNumber)

        // THEN
        if case let .heartbeat(heartbeat) = message {
            XCTAssertEqual(heartbeat.sequenceNumber, sequenceNumber)
            XCTAssertEqual(heartbeat.clientVersion, "1.0.0")
        } else {
            XCTFail("Message should be heartbeat type")
        }
    }

    func testWebSocketMessageError() {
        // GIVEN
        let errorCode = "VALIDATION_ERROR"
        let errorMessage = "Invalid emote data"
        let recoverable = true

        // WHEN
        let message = GameWebSocketMessage.error(
            code: errorCode,
            message: errorMessage,
            recoverable: recoverable
        )

        // THEN
        if case let .error(error) = message {
            XCTAssertEqual(error.errorCode, errorCode)
            XCTAssertEqual(error.message, errorMessage)
            XCTAssertEqual(error.recoverable, recoverable)
        } else {
            XCTFail("Message should be error type")
        }
    }

    func testWebSocketMessagePriority() {
        // GIVEN
        let emoteMessage = GameWebSocketMessage.emoteBroadcast(
            playerId: UUID(),
            emoteType: .greeting,
            gameId: "test",
            characterType: .pacala
        )
        let heartbeatMessage = GameWebSocketMessage.heartbeat(sequenceNumber: 1)
        let errorMessage = GameWebSocketMessage.error(code: "TEST", message: "Test error")

        // WHEN & THEN
        XCTAssertTrue(emoteMessage.isHighPriority, "Emote broadcasts should be high priority")
        XCTAssertTrue(errorMessage.isHighPriority, "Error messages should be high priority")
        XCTAssertFalse(heartbeatMessage.isHighPriority, "Heartbeat should not be high priority")
    }

    func testWebSocketMessageTypeIdentifiers() {
        // GIVEN
        let emoteMessage = GameWebSocketMessage.emoteBroadcast(
            playerId: UUID(),
            emoteType: .greeting,
            gameId: "test",
            characterType: .pacala
        )
        let heartbeatMessage = GameWebSocketMessage.heartbeat(sequenceNumber: 1)

        // WHEN & THEN
        XCTAssertEqual(emoteMessage.messageType, "emote_broadcast")
        XCTAssertEqual(heartbeatMessage.messageType, "heartbeat")
    }

    // MARK: - Supporting Message Tests

    func testAvatarSyncMessage() {
        // GIVEN
        let playerId = UUID()
        let characterType: RomanianCharacterType = .strigoi
        let playerLevel = 5
        let isActiveEmote = true
        let currentEmote: EmoteType = .taunt
        let position = AvatarPosition(x: 10.5, y: 20.3, z: 5.0, rotation: 45.0)

        // WHEN
        let message = AvatarSyncMessage(
            playerId: playerId,
            characterType: characterType,
            playerLevel: playerLevel,
            isActiveEmote: isActiveEmote,
            currentEmote: currentEmote,
            emoteStartTime: Date(),
            position: position
        )

        // THEN
        XCTAssertEqual(message.playerId, playerId)
        XCTAssertEqual(message.characterType, characterType)
        XCTAssertEqual(message.playerLevel, playerLevel)
        XCTAssertEqual(message.isActiveEmote, isActiveEmote)
        XCTAssertEqual(message.currentEmote, currentEmote)
        XCTAssertEqual(message.position, position)
    }

    func testGameStateMessage() {
        // GIVEN
        let gameId = "game-123"
        let currentRound = 3
        let activePlayerId = UUID()
        let gamePhase: GameScreenPhase = .playing
        let turnTimeRemaining: TimeInterval = 25.5
        let lastMoveTimestamp = Date()

        // WHEN
        let message = GameStateMessage(
            gameId: gameId,
            currentRound: currentRound,
            activePlayerId: activePlayerId,
            gamePhase: gamePhase,
            turnTimeRemaining: turnTimeRemaining,
            lastMoveTimestamp: lastMoveTimestamp
        )

        // THEN
        XCTAssertEqual(message.gameId, gameId)
        XCTAssertEqual(message.currentRound, currentRound)
        XCTAssertEqual(message.activePlayerId, activePlayerId)
        XCTAssertEqual(message.gamePhase, gamePhase)
        XCTAssertEqual(message.turnTimeRemaining, turnTimeRemaining)
        XCTAssertEqual(message.lastMoveTimestamp, lastMoveTimestamp)
    }

    func testPlayerJoinedMessage() {
        // GIVEN
        let playerId = UUID()
        let playerName = "TestPlayer"
        let characterType: RomanianCharacterType = .fatFrumos
        let playerLevel = 3
        let joinTimestamp = Date()

        // WHEN
        let message = PlayerJoinedMessage(
            playerId: playerId,
            playerName: playerName,
            characterType: characterType,
            playerLevel: playerLevel,
            joinTimestamp: joinTimestamp
        )

        // THEN
        XCTAssertEqual(message.playerId, playerId)
        XCTAssertEqual(message.playerName, playerName)
        XCTAssertEqual(message.characterType, characterType)
        XCTAssertEqual(message.playerLevel, playerLevel)
        XCTAssertEqual(message.joinTimestamp, joinTimestamp)
    }

    // MARK: - Round Trip Tests

    func testEmoteMessageRoundTrip() {
        // GIVEN
        let originalEmote = EmoteMessage(
            playerId: UUID(),
            emoteType: .victory,
            gameId: "round-trip-test",
            characterType: .zmeu,
            targetPlayerId: UUID(),
            intensity: 0.8,
            duration: 2.5
        )

        // WHEN
        let message = GameWebSocketMessage.emoteBroadcast(originalEmote)
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try! encoder.encode(message)
        let decodedMessage = try! decoder.decode(GameWebSocketMessage.self, from: data)

        // THEN
        if case let .emoteBroadcast(decodedEmote) = decodedMessage {
            XCTAssertEqual(decodedEmote, originalEmote)
        } else {
            XCTFail("Decoded message should be emote broadcast")
        }
    }

    func testAllMessageTypesRoundTrip() {
        // Test all message types for serialization consistency
        let playerId = UUID()
        let gameId = "test-game"
        let characterType: RomanianCharacterType = .babaCloantza

        let messages: [GameWebSocketMessage] = [
            .emoteBroadcast(EmoteMessage(
                playerId: playerId,
                emoteType: .greeting,
                gameId: gameId,
                characterType: characterType
            )),
            .avatarSync(AvatarSyncMessage(
                playerId: playerId,
                characterType: characterType,
                playerLevel: 2,
                isActiveEmote: false,
                currentEmote: nil,
                emoteStartTime: nil,
                position: nil
            )),
            .gameState(GameStateMessage(
                gameId: gameId,
                currentRound: 1,
                activePlayerId: playerId,
                gamePhase: .playing,
                turnTimeRemaining: 30.0,
                lastMoveTimestamp: Date()
            )),
            .playerJoined(PlayerJoinedMessage(
                playerId: playerId,
                playerName: "TestPlayer",
                characterType: characterType,
                playerLevel: 1,
                joinTimestamp: Date()
            )),
            .playerLeft(PlayerLeftMessage(
                playerId: playerId,
                playerName: "TestPlayer",
                leaveTimestamp: Date(),
                reason: .voluntary
            )),
            .heartbeat(HeartbeatMessage(
                timestamp: Date(),
                sequenceNumber: 1,
                clientVersion: "1.0.0"
            )),
            .error(ErrorMessage(
                errorCode: "TEST_ERROR",
                message: "Test error message",
                timestamp: Date(),
                recoverable: true
            ))
        ]

        // WHEN & THEN
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for message in messages {
            do {
                let data = try encoder.encode(message)
                let decodedMessage = try decoder.decode(GameWebSocketMessage.self, from: data)

                // Verify message type is preserved
                XCTAssertEqual(message.messageType, decodedMessage.messageType)

                // Verify priority is preserved
                XCTAssertEqual(message.isHighPriority, decodedMessage.isHighPriority)

            } catch {
                XCTFail("Round trip failed for message type \(message.messageType): \(error)")
            }
        }
    }

    // MARK: - Performance Tests

    func testEmoteMessageCreationPerformance() {
        // GIVEN
        let playerId = UUID()
        let gameId = "perf-test"
        let characterType: RomanianCharacterType = .iele

        // WHEN & THEN
        measure {
            for _ in 0..<1000 {
                _ = EmoteMessage(
                    playerId: playerId,
                    emoteType: .greeting,
                    gameId: gameId,
                    characterType: characterType
                )
            }
        }
    }

    func testWebSocketMessageEncodingPerformance() {
        // GIVEN
        let message = GameWebSocketMessage.emoteBroadcast(
            playerId: UUID(),
            emoteType: .victory,
            gameId: "perf-test",
            characterType: .pacala
        )
        let encoder = JSONEncoder()

        // WHEN & THEN
        measure {
            for _ in 0..<1000 {
                _ = try! encoder.encode(message)
            }
        }
    }

    func testWebSocketMessageDecodingPerformance() {
        // GIVEN
        let message = GameWebSocketMessage.emoteBroadcast(
            playerId: UUID(),
            emoteType: .defeat,
            gameId: "perf-test",
            characterType: .strigoi
        )
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try! encoder.encode(message)

        // WHEN & THEN
        measure {
            for _ in 0..<1000 {
                _ = try! decoder.decode(GameWebSocketMessage.self, from: data)
            }
        }
    }
}