//
//  TableCardTests.swift
//  SepticaTests
//
//  Tests for TableCard model
//

import XCTest
@testable import Septica

final class TableCardTests: XCTestCase {

    // MARK: - Initialization Tests

    func testTableCardInitialization() {
        // Given
        let card = Card(suit: .hearts, value: 10)
        let playOrder = 2
        let isWinning = true

        // When
        let tableCard = TableCard(
            card: card,
            playOrder: playOrder,
            isWinning: isWinning
        )

        // Then
        XCTAssertEqual(tableCard.card, card)
        XCTAssertEqual(tableCard.playOrder, playOrder)
        XCTAssertTrue(tableCard.isWinning)
    }

    func testTableCardHasUniqueId() {
        // Given
        let card = Card(suit: .hearts, value: 10)

        // When
        let tableCard1 = TableCard(card: card, playOrder: 1, isWinning: false)
        let tableCard2 = TableCard(card: card, playOrder: 1, isWinning: false)

        // Then
        XCTAssertNotEqual(tableCard1.id, tableCard2.id)
    }

    // MARK: - Equatable Tests

    func testTableCardsWithSamePropertiesAreEqual() {
        // Given
        let card1 = Card(suit: .hearts, value: 10)
        let card2 = Card(suit: .hearts, value: 10)

        // When
        let tableCard1 = TableCard(card: card1, playOrder: 1, isWinning: true)
        let tableCard2 = TableCard(card: card2, playOrder: 1, isWinning: true)

        // Then
        XCTAssertEqual(tableCard1, tableCard2)
    }

    func testTableCardsWithDifferentCardsAreNotEqual() {
        // Given
        let card1 = Card(suit: .hearts, value: 10)
        let card2 = Card(suit: .diamonds, value: 10)

        // When
        let tableCard1 = TableCard(card: card1, playOrder: 1, isWinning: false)
        let tableCard2 = TableCard(card: card2, playOrder: 1, isWinning: false)

        // Then
        XCTAssertNotEqual(tableCard1, tableCard2)
    }

    func testTableCardsWithDifferentPlayOrderAreNotEqual() {
        // Given
        let card = Card(suit: .hearts, value: 10)

        // When
        let tableCard1 = TableCard(card: card, playOrder: 1, isWinning: false)
        let tableCard2 = TableCard(card: card, playOrder: 2, isWinning: false)

        // Then
        XCTAssertNotEqual(tableCard1, tableCard2)
    }

    func testTableCardsWithDifferentWinningStatusAreNotEqual() {
        // Given
        let card = Card(suit: .hearts, value: 10)

        // When
        let tableCard1 = TableCard(card: card, playOrder: 1, isWinning: true)
        let tableCard2 = TableCard(card: card, playOrder: 1, isWinning: false)

        // Then
        XCTAssertNotEqual(tableCard1, tableCard2)
    }

    // MARK: - Usage Tests

    func testTableCardInArray() {
        // Given
        let cards = [
            TableCard(card: Card(suit: .hearts, value: 10), playOrder: 0, isWinning: false),
            TableCard(card: Card(suit: .diamonds, value: 14), playOrder: 1, isWinning: true),
            TableCard(card: Card(suit: .clubs, value: 7), playOrder: 2, isWinning: true)
        ]

        // Then
        XCTAssertEqual(cards.count, 3)
        XCTAssertEqual(cards[0].playOrder, 0)
        XCTAssertEqual(cards[1].playOrder, 1)
        XCTAssertEqual(cards[2].playOrder, 2)
        XCTAssertFalse(cards[0].isWinning)
        XCTAssertTrue(cards[1].isWinning)
        XCTAssertTrue(cards[2].isWinning)
    }

    func testTableCardFiltering() {
        // Given
        let cards = [
            TableCard(card: Card(suit: .hearts, value: 10), playOrder: 0, isWinning: false),
            TableCard(card: Card(suit: .diamonds, value: 14), playOrder: 1, isWinning: true),
            TableCard(card: Card(suit: .clubs, value: 7), playOrder: 2, isWinning: true),
            TableCard(card: Card(suit: .spades, value: 8), playOrder: 3, isWinning: false)
        ]

        // When
        let winningCards = cards.filter { $0.isWinning }

        // Then
        XCTAssertEqual(winningCards.count, 2)
        XCTAssertEqual(winningCards[0].card.value, 14)
        XCTAssertEqual(winningCards[1].card.value, 7)
    }

    func testTableCardSorting() {
        // Given
        let cards = [
            TableCard(card: Card(suit: .hearts, value: 10), playOrder: 2, isWinning: false),
            TableCard(card: Card(suit: .diamonds, value: 14), playOrder: 0, isWinning: true),
            TableCard(card: Card(suit: .clubs, value: 7), playOrder: 1, isWinning: true)
        ]

        // When
        let sortedCards = cards.sorted { $0.playOrder < $1.playOrder }

        // Then
        XCTAssertEqual(sortedCards[0].playOrder, 0)
        XCTAssertEqual(sortedCards[1].playOrder, 1)
        XCTAssertEqual(sortedCards[2].playOrder, 2)
    }

    // MARK: - Integration Tests

    func testTableCardWithPointCards() {
        // Given
        let tenOfHearts = Card(suit: .hearts, value: 10)
        let aceOfDiamonds = Card(suit: .diamonds, value: 14)
        let sevenOfClubs = Card(suit: .clubs, value: 7)

        // When
        let tableCards = [
            TableCard(card: tenOfHearts, playOrder: 0, isWinning: false),
            TableCard(card: aceOfDiamonds, playOrder: 1, isWinning: false),
            TableCard(card: sevenOfClubs, playOrder: 2, isWinning: true)
        ]

        // Then
        let pointCards = tableCards.filter { $0.card.isPointCard }
        XCTAssertEqual(pointCards.count, 2)
        XCTAssertTrue(tableCards[0].card.isPointCard)
        XCTAssertTrue(tableCards[1].card.isPointCard)
        XCTAssertFalse(tableCards[2].card.isPointCard)
    }
}
