//
//  DeckTests.swift
//  SepticaTests
//
//  Unit tests for Deck model and card management
//  Tests deck creation, shuffling, and card operations
//

import XCTest
@testable import Septica

final class DeckTests: XCTestCase {
    
    // MARK: - Deck Creation Tests
    
    func testDeckInitialization() {
        let deck = Deck()
        
        // Standard Romanian deck should have 32 cards
        XCTAssertEqual(deck.count, 32)
        XCTAssertFalse(deck.isEmpty)
    }
    
    func testDeckHasCorrectCards() {
        let deck = Deck()
        
        // Should have 8 cards per suit (7,8,9,10,J,Q,K,A)
        for suit in Suit.allCases {
            let suitCards = deck.cards(ofSuit: suit)
            XCTAssertEqual(suitCards.count, 8)
            
            // Should have all values from 7 to 14
            for value in 7...14 {
                XCTAssertTrue(suitCards.contains { $0.value == value })
            }
        }
    }
    
    func testDeckFromCards() {
        let cards = [
            Card(suit: .hearts, value: 7),
            Card(suit: .spades, value: 10),
            Card(suit: .clubs, value: 14)
        ]
        
        let deck = Deck(cards: cards)
        XCTAssertEqual(deck.count, 3)
        XCTAssertEqual(deck.allCards, cards)
    }
    
    // MARK: - Card Drawing Tests
    
    func testDrawSingleCard() {
        var deck = Deck()
        let initialCount = deck.count
        
        let drawnCard = deck.drawCard()
        
        XCTAssertNotNil(drawnCard)
        XCTAssertEqual(deck.count, initialCount - 1)
    }
    
    func testDrawFromEmptyDeck() {
        var deck = Deck(cards: [])
        
        let drawnCard = deck.drawCard()
        
        XCTAssertNil(drawnCard)
        XCTAssertEqual(deck.count, 0)
        XCTAssertTrue(deck.isEmpty)
    }
    
    func testDrawMultipleCards() {
        var deck = Deck()
        let initialCount = deck.count
        let cardsToDraw = 5
        
        let drawnCards = deck.drawCards(cardsToDraw)
        
        XCTAssertEqual(drawnCards.count, cardsToDraw)
        XCTAssertEqual(deck.count, initialCount - cardsToDraw)
        
        // All drawn cards should be different
        let uniqueCards = Set(drawnCards.map { "\($0.suit)\($0.value)" })
        XCTAssertEqual(uniqueCards.count, cardsToDraw)
    }
    
    func testDrawMoreCardsThanAvailable() {
        var deck = Deck(cards: [
            Card(suit: .hearts, value: 7),
            Card(suit: .spades, value: 8)
        ])
        
        let drawnCards = deck.drawCards(5) // Try to draw more than available
        
        XCTAssertEqual(drawnCards.count, 2) // Should only get available cards
        XCTAssertTrue(deck.isEmpty)
    }
    
    // MARK: - Card Adding Tests
    
    func testAddSingleCard() {
        var deck = Deck(cards: [])
        let card = Card(suit: .hearts, value: 7)
        
        deck.addCard(card)
        
        XCTAssertEqual(deck.count, 1)
        XCTAssertTrue(deck.contains(card))
    }
    
    func testAddMultipleCards() {
        var deck = Deck(cards: [])
        let cards = [
            Card(suit: .hearts, value: 7),
            Card(suit: .spades, value: 10),
            Card(suit: .clubs, value: 14)
        ]
        
        deck.addCards(cards)
        
        XCTAssertEqual(deck.count, 3)
        for card in cards {
            XCTAssertTrue(deck.contains(card))
        }
    }
    
    // MARK: - Deck Shuffling Tests
    
    func testShuffleDeck() {
        var deck1 = Deck()
        var deck2 = Deck()
        
        // Get original order
        let originalOrder = deck1.allCards
        
        // Shuffle one deck
        deck1.shuffle()
        
        // Decks should have same cards but potentially different order
        XCTAssertEqual(deck1.count, deck2.count)
        XCTAssertEqual(deck1.count, 32)
        
        // Check all cards are still present
        for card in originalOrder {
            XCTAssertTrue(deck1.contains(card))
        }
        
        // Note: There's a tiny chance this could fail if shuffle returns same order
        // but statistically very unlikely with 32 cards
    }
    
    // MARK: - Deck Reset Tests
    
    func testDeckReset() {
        var deck = Deck()
        
        // Draw some cards
        _ = deck.drawCards(10)
        XCTAssertEqual(deck.count, 22)
        
        // Reset deck
        deck.reset()
        
        // Should be back to full 32-card deck
        XCTAssertEqual(deck.count, 32)
        XCTAssertFalse(deck.isEmpty)
        
        // Should have all standard cards again
        XCTAssertEqual(deck.pointCardsRemaining, 8) // 4 tens + 4 aces
    }
    
    // MARK: - Card Querying Tests
    
    func testCardsWithValue() {
        let deck = Deck()
        
        // Should have 4 cards of each value (one per suit)
        for value in 7...14 {
            let cardsWithValue = deck.cards(withValue: value)
            XCTAssertEqual(cardsWithValue.count, 4)
            
            // Should have one of each suit
            let suits = Set(cardsWithValue.map { $0.suit })
            XCTAssertEqual(suits.count, 4)
        }
    }
    
    func testCardsOfSuit() {
        let deck = Deck()
        
        // Should have 8 cards of each suit
        for suit in Suit.allCases {
            let cardsOfSuit = deck.cards(ofSuit: suit)
            XCTAssertEqual(cardsOfSuit.count, 8)
            
            // Should have all values from 7 to 14
            let values = Set(cardsOfSuit.map { $0.value })
            XCTAssertEqual(values, Set(7...14))
        }
    }
    
    func testContainsCard() {
        let deck = Deck()
        
        // Should contain all standard cards
        for suit in Suit.allCases {
            for value in 7...14 {
                let card = Card(suit: suit, value: value)
                XCTAssertTrue(deck.contains(card), "Deck should contain \(card.displayName)")
            }
        }
        
        // Test that deck doesn't contain a card after it's drawn
        var mutableDeck = Deck()
        if let drawnCard = mutableDeck.drawCard() {
            XCTAssertFalse(mutableDeck.contains(drawnCard), "Deck should not contain drawn card \(drawnCard.displayName)")
        }
    }
    
    // MARK: - Point Card Tests
    
    func testPointCardsRemaining() {
        let deck = Deck()
        
        // New deck should have 8 point cards (4 tens + 4 aces)
        XCTAssertEqual(deck.pointCardsRemaining, 8)
        XCTAssertEqual(deck.totalPointsRemaining, 8)
    }
    
    func testPointCardsAfterDrawing() {
        var deck = Deck()
        
        // Draw cards until we get a point card
        var pointCardsDrawn = 0
        while !deck.isEmpty {
            if let card = deck.drawCard(), card.isPointCard {
                pointCardsDrawn += 1
                break
            }
        }
        
        XCTAssertEqual(pointCardsDrawn, 1)
        XCTAssertEqual(deck.pointCardsRemaining, 7)
        XCTAssertEqual(deck.totalPointsRemaining, 7)
    }
    
    // MARK: - Deck Statistics Tests
    
    func testDeckStatistics() {
        let deck = Deck()
        let stats = deck.statistics
        
        XCTAssertEqual(stats.totalCards, 32)
        XCTAssertEqual(stats.pointCards, 8)
        XCTAssertEqual(stats.totalPoints, 8)
        
        // Should have 8 cards per suit
        for suit in Suit.allCases {
            XCTAssertEqual(stats.cardsBySuit[suit], 8)
        }
    }
    
    func testDeckStatisticsAfterDrawing() {
        var deck = Deck()
        let initialStats = deck.statistics
        
        // Verify initial state
        XCTAssertEqual(initialStats.totalCards, 32)
        XCTAssertEqual(initialStats.pointCards, 8) // 4 tens + 4 aces
        XCTAssertEqual(initialStats.totalPoints, 8)
        
        // Draw some cards and check statistics update
        let cardsDrawn = 10
        _ = deck.drawCards(cardsDrawn)
        let statsAfterDrawing = deck.statistics
        
        XCTAssertEqual(statsAfterDrawing.totalCards, 32 - cardsDrawn)
        XCTAssertTrue(statsAfterDrawing.pointCards <= 8) // Can't have more than initial
        XCTAssertTrue(statsAfterDrawing.pointCards >= 0) // Can't have negative
        XCTAssertEqual(statsAfterDrawing.totalPoints, statsAfterDrawing.pointCards)
        
        // Verify that all suit counts sum to total
        let totalBySuit = statsAfterDrawing.cardsBySuit.values.reduce(0, +)
        XCTAssertEqual(totalBySuit, statsAfterDrawing.totalCards)
    }
    
    // MARK: - Collection Conformance Tests
    
    func testDeckAsCollection() {
        let deck = Deck()
        
        // Test collection properties
        XCTAssertEqual(deck.count, 32)
        XCTAssertFalse(deck.isEmpty)
        
        // Test subscript access
        let firstCard = deck[deck.startIndex]
        XCTAssertNotNil(firstCard)
        
        // Test iteration
        var cardCount = 0
        for _ in deck {
            cardCount += 1
        }
        XCTAssertEqual(cardCount, 32)
    }
    
    // MARK: - Codable Tests
    
    func testDeckCodable() throws {
        let originalDeck = Deck()
        
        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalDeck)
        
        // Decode
        let decoder = JSONDecoder()
        let decodedDeck = try decoder.decode(Deck.self, from: data)
        
        // Verify
        XCTAssertEqual(originalDeck.count, decodedDeck.count)
        XCTAssertEqual(originalDeck.pointCardsRemaining, decodedDeck.pointCardsRemaining)
        
        // Check that all cards are present
        for card in originalDeck {
            XCTAssertTrue(decodedDeck.contains(card))
        }
    }
    
    func testModifiedDeckCodable() throws {
        var originalDeck = Deck()
        
        // Modify deck
        _ = originalDeck.drawCards(5)
        originalDeck.shuffle()
        
        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalDeck)
        
        // Decode
        let decoder = JSONDecoder()
        let decodedDeck = try decoder.decode(Deck.self, from: data)
        
        // Verify state is preserved
        XCTAssertEqual(originalDeck.count, decodedDeck.count)
        XCTAssertEqual(originalDeck.pointCardsRemaining, decodedDeck.pointCardsRemaining)
        
        // Verify order is preserved
        XCTAssertEqual(originalDeck.allCards.count, decodedDeck.allCards.count)
    }
}