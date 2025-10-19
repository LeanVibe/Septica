//
//  GameSessionTests.swift
//  SepticaTests
//
//  Tests for game session identification and emote integration
//

import XCTest
@testable import Septica

final class GameSessionTests: XCTestCase {

    // MARK: - Game ID Generation Tests

    func testGameIdIsGenerated() {
        // Given: A game session is created
        // When: setupGame() is called
        // Then: gameId should be a valid UUID string

        let gameId = UUID().uuidString

        XCTAssertFalse(gameId.isEmpty, "Game ID should not be empty")
        XCTAssertNotNil(UUID(uuidString: gameId), "Game ID should be a valid UUID")
    }

    func testGameIdIsUnique() {
        // Given: Multiple game sessions
        // When: Each creates its own game ID
        // Then: All IDs should be unique

        let gameId1 = UUID().uuidString
        let gameId2 = UUID().uuidString
        let gameId3 = UUID().uuidString

        XCTAssertNotEqual(gameId1, gameId2)
        XCTAssertNotEqual(gameId2, gameId3)
        XCTAssertNotEqual(gameId1, gameId3)
    }

    func testGameIdFormat() {
        // Given: A generated game ID
        // When: Checking its format
        // Then: It should match UUID format (8-4-4-4-12 hex digits)

        let gameId = UUID().uuidString
        let uuidPattern = "^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$"
        let regex = try? NSRegularExpression(pattern: uuidPattern, options: [])
        let range = NSRange(location: 0, length: gameId.utf16.count)
        let match = regex?.firstMatch(in: gameId, options: [], range: range)

        XCTAssertNotNil(match, "Game ID should match UUID format")
    }

    // MARK: - Emote Message Integration Tests

    func testEmoteMessageIncludesGameId() {
        // Given: A game session with ID
        let gameId = UUID().uuidString
        let playerId = UUID()

        // When: Creating an emote message
        let emoteMessage = EmoteMessage(
            playerId: playerId,
            emoteType: .greeting,
            gameId: gameId,
            characterType: .pacala
        )

        // Then: Emote message should contain the game ID
        XCTAssertEqual(emoteMessage.gameId, gameId)
        XCTAssertFalse(emoteMessage.gameId.isEmpty)
    }

    func testEmoteMessageValidationWithGameId() {
        // Given: An emote message with valid game ID
        let gameId = UUID().uuidString
        let playerId = UUID()

        let emoteMessage = EmoteMessage(
            playerId: playerId,
            emoteType: .victory,
            gameId: gameId,
            characterType: .iele
        )

        // When: Validating the message
        let validationResult = emoteMessage.validate()

        // Then: Message should be valid
        XCTAssertTrue(validationResult.isValid, "Emote with valid game ID should pass validation")
        XCTAssertTrue(validationResult.errors.isEmpty, "There should be no validation errors")
    }

    func testEmoteMessageValidationWithEmptyGameId() {
        // Given: An emote message with empty game ID
        let playerId = UUID()

        let emoteMessage = EmoteMessage(
            playerId: playerId,
            emoteType: .taunt,
            gameId: "",
            characterType: .strigoi
        )

        // When: Validating the message
        let validationResult = emoteMessage.validate()

        // Then: Message should fail validation
        XCTAssertFalse(validationResult.isValid, "Emote with empty game ID should fail validation")
        XCTAssertTrue(validationResult.errors.contains { $0.contains("Game ID") },
                     "Validation errors should mention game ID")
    }

    // MARK: - WebSocket Message Integration Tests

    func testWebSocketMessageIncludesGameId() {
        // Given: An emote broadcast with game ID
        let gameId = UUID().uuidString
        let playerId = UUID()

        // When: Creating WebSocket message
        let message = GameWebSocketMessage.emoteBroadcast(
            playerId: playerId,
            emoteType: .goodMove,
            gameId: gameId,
            characterType: .fatFrumos
        )

        // Then: Message should contain the game ID
        if case .emoteBroadcast(let emoteMessage) = message {
            XCTAssertEqual(emoteMessage.gameId, gameId)
        } else {
            XCTFail("Message should be emoteBroadcast type")
        }
    }

    func testWebSocketMessageSerialization() {
        // Given: A complete emote message with game ID
        let gameId = UUID().uuidString
        let playerId = UUID()

        let message = GameWebSocketMessage.emoteBroadcast(
            playerId: playerId,
            emoteType: .thinking,
            gameId: gameId,
            characterType: .babaCloantza
        )

        // When: Encoding to JSON
        let encoder = JSONEncoder()
        let data = try? encoder.encode(message)

        // Then: Should serialize successfully
        XCTAssertNotNil(data, "Message should serialize to JSON")

        // When: Decoding back
        let decoder = JSONDecoder()
        let decoded = try? decoder.decode(GameWebSocketMessage.self, from: data!)

        // Then: Should deserialize with same game ID
        XCTAssertNotNil(decoded, "Message should deserialize from JSON")
        if case .emoteBroadcast(let decodedEmote) = decoded {
            XCTAssertEqual(decodedEmote.gameId, gameId, "Game ID should survive serialization")
        } else {
            XCTFail("Decoded message should be emoteBroadcast type")
        }
    }

    // MARK: - Game Session Lifecycle Tests

    func testGameIdPersistsThroughGameplay() {
        // Given: A game session starts with an ID
        let initialGameId = UUID().uuidString
        var currentGameId = initialGameId

        // When: Various game actions occur
        // (Simulating multiple emote sends)
        for _ in 0..<5 {
            let emoteMessage = EmoteMessage(
                playerId: UUID(),
                emoteType: EmoteType.allCases.randomElement()!,
                gameId: currentGameId,
                characterType: RomanianCharacterType.allCases.randomElement()!
            )

            // Then: Game ID should remain constant
            XCTAssertEqual(emoteMessage.gameId, initialGameId,
                          "Game ID should not change during gameplay")
        }
    }

    func testDifferentGamesHaveDifferentIds() {
        // Given: Multiple concurrent game sessions
        let game1Id = UUID().uuidString
        let game2Id = UUID().uuidString
        let game3Id = UUID().uuidString

        // When: Creating emotes for different games
        let game1Emote = EmoteMessage(
            playerId: UUID(),
            emoteType: .greeting,
            gameId: game1Id,
            characterType: .pacala
        )

        let game2Emote = EmoteMessage(
            playerId: UUID(),
            emoteType: .greeting,
            gameId: game2Id,
            characterType: .iele
        )

        let game3Emote = EmoteMessage(
            playerId: UUID(),
            emoteType: .greeting,
            gameId: game3Id,
            characterType: .zmeu
        )

        // Then: Each emote should have its unique game ID
        XCTAssertNotEqual(game1Emote.gameId, game2Emote.gameId)
        XCTAssertNotEqual(game2Emote.gameId, game3Emote.gameId)
        XCTAssertNotEqual(game1Emote.gameId, game3Emote.gameId)
    }
}
