//
//  EmoteDataTests.swift
//  SepticaTests
//
//  Tests for EmoteData notification structure
//

import XCTest
@testable import Septica

final class EmoteDataTests: XCTestCase {

    // MARK: - EmoteData Structure Tests

    func testEmoteDataInitialization() {
        // Given
        let playerId = UUID()
        let emoteType = EmoteType.greeting

        // When
        let emoteData = EmoteData(playerId: playerId, emote: emoteType)

        // Then
        XCTAssertEqual(emoteData.playerId, playerId)
        XCTAssertEqual(emoteData.emote, emoteType)
    }

    func testEmoteDataWithAllEmoteTypes() {
        // Given
        let playerId = UUID()

        // When/Then: Test all emote types
        for emoteType in EmoteType.allCases {
            let emoteData = EmoteData(playerId: playerId, emote: emoteType)
            XCTAssertEqual(emoteData.emote, emoteType)
        }
    }

    func testEmoteDataWithDifferentPlayers() {
        // Given
        let player1 = UUID()
        let player2 = UUID()
        let player3 = UUID()
        let emoteType = EmoteType.victory

        // When
        let emote1 = EmoteData(playerId: player1, emote: emoteType)
        let emote2 = EmoteData(playerId: player2, emote: emoteType)
        let emote3 = EmoteData(playerId: player3, emote: emoteType)

        // Then
        XCTAssertNotEqual(emote1.playerId, emote2.playerId)
        XCTAssertNotEqual(emote2.playerId, emote3.playerId)
        XCTAssertNotEqual(emote1.playerId, emote3.playerId)
    }

    // MARK: - Notification Integration Tests

    func testPlayerDidEmoteNotificationName() {
        // Given/When
        let notificationName = Notification.Name.playerDidEmote

        // Then
        XCTAssertEqual(notificationName.rawValue, "playerDidEmote")
    }

    func testEmoteDataNotificationPosting() {
        // Given
        let expectation = XCTestExpectation(description: "Notification received")
        let playerId = UUID()
        let emoteType = EmoteType.taunt
        let emoteData = EmoteData(playerId: playerId, emote: emoteType)

        var receivedData: EmoteData?

        let observer = NotificationCenter.default.addObserver(
            forName: .playerDidEmote,
            object: nil,
            queue: .main
        ) { notification in
            receivedData = notification.object as? EmoteData
            expectation.fulfill()
        }

        // When
        NotificationCenter.default.post(name: .playerDidEmote, object: emoteData)

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(receivedData)
        XCTAssertEqual(receivedData?.playerId, playerId)
        XCTAssertEqual(receivedData?.emote, emoteType)

        NotificationCenter.default.removeObserver(observer)
    }

    func testMultipleEmoteNotifications() {
        // Given
        let expectation = XCTestExpectation(description: "Multiple notifications received")
        expectation.expectedFulfillmentCount = 3

        var receivedEmotes: [EmoteData] = []

        let observer = NotificationCenter.default.addObserver(
            forName: .playerDidEmote,
            object: nil,
            queue: .main
        ) { notification in
            if let emoteData = notification.object as? EmoteData {
                receivedEmotes.append(emoteData)
            }
            expectation.fulfill()
        }

        // When
        let player1 = UUID()
        let player2 = UUID()
        let player3 = UUID()

        NotificationCenter.default.post(
            name: .playerDidEmote,
            object: EmoteData(playerId: player1, emote: .greeting)
        )
        NotificationCenter.default.post(
            name: .playerDidEmote,
            object: EmoteData(playerId: player2, emote: .goodMove)
        )
        NotificationCenter.default.post(
            name: .playerDidEmote,
            object: EmoteData(playerId: player3, emote: .victory)
        )

        // Then
        wait(for: [expectation], timeout: 2.0)
        XCTAssertEqual(receivedEmotes.count, 3)
        XCTAssertEqual(receivedEmotes[0].emote, .greeting)
        XCTAssertEqual(receivedEmotes[1].emote, .goodMove)
        XCTAssertEqual(receivedEmotes[2].emote, .victory)

        NotificationCenter.default.removeObserver(observer)
    }

    func testNotificationWithInvalidObject() {
        // Given
        let expectation = XCTestExpectation(description: "Notification received but invalid")
        var receivedData: EmoteData?

        let observer = NotificationCenter.default.addObserver(
            forName: .playerDidEmote,
            object: nil,
            queue: .main
        ) { notification in
            receivedData = notification.object as? EmoteData
            expectation.fulfill()
        }

        // When: Post notification with wrong object type
        NotificationCenter.default.post(
            name: .playerDidEmote,
            object: "Invalid Object"
        )

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNil(receivedData, "Should not cast non-EmoteData object")

        NotificationCenter.default.removeObserver(observer)
    }

    // MARK: - Integration with EmoteType Tests

    func testEmoteDataWithCharacterSpecificEmotes() {
        // Given: Test cultural authenticity
        let scenarios: [(emote: EmoteType, description: String)] = [
            (.greeting, "Traditional Romanian greeting"),
            (.goodMove, "Appreciative gesture"),
            (.badMove, "Disapproving gesture"),
            (.thinking, "Contemplative pose"),
            (.taunt, "Playful taunting"),
            (.victory, "Celebration"),
            (.defeat, "Graceful loss")
        ]

        // When/Then
        for scenario in scenarios {
            let playerId = UUID()
            let emoteData = EmoteData(playerId: playerId, emote: scenario.emote)

            XCTAssertEqual(emoteData.emote, scenario.emote,
                          "EmoteData should preserve \(scenario.description)")
        }
    }

    func testEmoteDataInBatchOperations() {
        // Given: Simulate rapid emote sending
        let playerId = UUID()
        var emotes: [EmoteData] = []

        // When: Create multiple emote data objects
        for emoteType in EmoteType.allCases {
            let emoteData = EmoteData(playerId: playerId, emote: emoteType)
            emotes.append(emoteData)
        }

        // Then
        XCTAssertEqual(emotes.count, EmoteType.allCases.count)
        for (index, emoteType) in EmoteType.allCases.enumerated() {
            XCTAssertEqual(emotes[index].emote, emoteType)
            XCTAssertEqual(emotes[index].playerId, playerId)
        }
    }

    // MARK: - Performance Tests

    func testEmoteDataCreationPerformance() {
        // Measure performance of creating EmoteData
        measure {
            for _ in 0..<1000 {
                let playerId = UUID()
                let emoteType = EmoteType.allCases.randomElement()!
                _ = EmoteData(playerId: playerId, emote: emoteType)
            }
        }
    }

    func testNotificationPostingPerformance() {
        // Measure performance of posting notifications
        let playerId = UUID()
        let emoteData = EmoteData(playerId: playerId, emote: .greeting)

        measure {
            for _ in 0..<100 {
                NotificationCenter.default.post(name: .playerDidEmote, object: emoteData)
            }
        }
    }
}
