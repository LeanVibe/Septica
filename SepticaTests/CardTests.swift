//
//  CardTests.swift
//  SepticaTests
//
//  Unit tests for Card model and game rules
//  Tests card creation, validation, and beating logic
//

import XCTest
@testable import Septica

final class CardTests: XCTestCase {
    
    // MARK: - Card Creation Tests
    
    func testCardInitialization() {
        // Test valid card creation
        let card = Card(suit: .hearts, value: 10)
        XCTAssertEqual(card.suit, .hearts)
        XCTAssertEqual(card.value, 10)
        XCTAssertNotNil(card.id)
    }
    
    func testCardInitializationValidRange() {
        // Test all valid values (7-14)
        for value in 7...14 {
            let card = Card(suit: .spades, value: value)
            XCTAssertEqual(card.value, value)
        }
    }
    
    func testCardDisplayValues() {
        // Test display values for all cards
        XCTAssertEqual(Card(suit: .hearts, value: 7).displayValue, "7")
        XCTAssertEqual(Card(suit: .hearts, value: 10).displayValue, "10")
        XCTAssertEqual(Card(suit: .hearts, value: 11).displayValue, "J")
        XCTAssertEqual(Card(suit: .hearts, value: 12).displayValue, "Q")
        XCTAssertEqual(Card(suit: .hearts, value: 13).displayValue, "K")
        XCTAssertEqual(Card(suit: .hearts, value: 14).displayValue, "A")
    }
    
    // MARK: - Point Card Tests
    
    func testPointCardIdentification() {
        // 10s and Aces should be point cards
        XCTAssertTrue(Card(suit: .hearts, value: 10).isPointCard)
        XCTAssertTrue(Card(suit: .spades, value: 14).isPointCard) // Ace
        
        // Other cards should not be point cards
        XCTAssertFalse(Card(suit: .hearts, value: 7).isPointCard)
        XCTAssertFalse(Card(suit: .hearts, value: 8).isPointCard)
        XCTAssertFalse(Card(suit: .hearts, value: 9).isPointCard)
        XCTAssertFalse(Card(suit: .hearts, value: 11).isPointCard) // Jack
        XCTAssertFalse(Card(suit: .hearts, value: 12).isPointCard) // Queen
        XCTAssertFalse(Card(suit: .hearts, value: 13).isPointCard) // King
    }
    
    // MARK: - Card Beating Logic Tests
    
    func testSevenAlwaysBeats() {
        let seven = Card(suit: .hearts, value: 7)
        let ace = Card(suit: .spades, value: 14)
        let king = Card(suit: .clubs, value: 13)
        
        // 7 should beat any card regardless of table count
        XCTAssertTrue(seven.canBeat(ace, tableCardsCount: 0))
        XCTAssertTrue(seven.canBeat(king, tableCardsCount: 3))
        XCTAssertTrue(seven.canBeat(ace, tableCardsCount: 6))
    }
    
    func testEightBeatsWhenTableCountDivisibleByThree() {
        let eight = Card(suit: .hearts, value: 8)
        let ten = Card(suit: .spades, value: 10)
        
        // 8 should beat when table count is divisible by 3
        XCTAssertTrue(eight.canBeat(ten, tableCardsCount: 0))
        XCTAssertTrue(eight.canBeat(ten, tableCardsCount: 3))
        XCTAssertTrue(eight.canBeat(ten, tableCardsCount: 6))
        
        // 8 should not beat when table count is not divisible by 3
        XCTAssertFalse(eight.canBeat(ten, tableCardsCount: 1))
        XCTAssertFalse(eight.canBeat(ten, tableCardsCount: 2))
        XCTAssertFalse(eight.canBeat(ten, tableCardsCount: 4))
        XCTAssertFalse(eight.canBeat(ten, tableCardsCount: 5))
    }
    
    func testSameValueBeats() {
        let ten1 = Card(suit: .hearts, value: 10)
        let ten2 = Card(suit: .spades, value: 10)
        let ace1 = Card(suit: .clubs, value: 14)
        let ace2 = Card(suit: .diamonds, value: 14)
        
        // Same values should beat each other
        XCTAssertTrue(ten1.canBeat(ten2, tableCardsCount: 1))
        XCTAssertTrue(ten2.canBeat(ten1, tableCardsCount: 1))
        XCTAssertTrue(ace1.canBeat(ace2, tableCardsCount: 1))
        XCTAssertTrue(ace2.canBeat(ace1, tableCardsCount: 1))
    }
    
    func testRegularCardsCannotBeat() {
        let nine = Card(suit: .hearts, value: 9)
        let jack = Card(suit: .spades, value: 11)
        let queen = Card(suit: .clubs, value: 12)
        let king = Card(suit: .diamonds, value: 13)
        
        // Regular cards should not beat different values
        XCTAssertFalse(nine.canBeat(jack, tableCardsCount: 1))
        XCTAssertFalse(jack.canBeat(queen, tableCardsCount: 1))
        XCTAssertFalse(queen.canBeat(king, tableCardsCount: 1))
        XCTAssertFalse(king.canBeat(nine, tableCardsCount: 1))
    }
    
    // MARK: - String Representation Tests
    
    func testStringRepresentation() {
        XCTAssertEqual(Card(suit: .hearts, value: 7).stringRepresentation, "7H")
        XCTAssertEqual(Card(suit: .diamonds, value: 10).stringRepresentation, "10D")
        XCTAssertEqual(Card(suit: .clubs, value: 11).stringRepresentation, "JC")
        XCTAssertEqual(Card(suit: .spades, value: 14).stringRepresentation, "AS")
    }
    
    func testFromString() {
        // Test valid string parsing
        XCTAssertEqual(Card.fromString("7H"), Card(suit: .hearts, value: 7))
        XCTAssertEqual(Card.fromString("10D"), Card(suit: .diamonds, value: 10))
        XCTAssertEqual(Card.fromString("JC"), Card(suit: .clubs, value: 11))
        XCTAssertEqual(Card.fromString("AS"), Card(suit: .spades, value: 14))
        
        // Test invalid strings
        XCTAssertNil(Card.fromString("6H")) // Invalid value
        XCTAssertNil(Card.fromString("7X")) // Invalid suit
        XCTAssertNil(Card.fromString("")) // Empty string
        XCTAssertNil(Card.fromString("7")) // No suit
    }
    
    // MARK: - Equality and Comparison Tests
    
    func testCardEquality() {
        let card1 = Card(suit: .hearts, value: 10)
        let card2 = Card(suit: .hearts, value: 10)
        let card3 = Card(suit: .spades, value: 10)
        
        // Same suit and value should be equal (ignoring ID)
        XCTAssertTrue(card1.suit == card2.suit && card1.value == card2.value)
        XCTAssertFalse(card1.suit == card3.suit && card1.value == card3.value)
    }
    
    func testCardComparison() {
        let seven = Card(suit: .hearts, value: 7)
        let ten = Card(suit: .hearts, value: 10)
        let ace = Card(suit: .hearts, value: 14)
        
        // Test ordering by value
        XCTAssertTrue(seven < ten)
        XCTAssertTrue(ten < ace)
        XCTAssertTrue(seven < ace)
        
        XCTAssertFalse(ace < seven)
        XCTAssertFalse(ten < seven)
    }
    
    // MARK: - Display Name Tests
    
    func testDisplayName() {
        XCTAssertEqual(Card(suit: .hearts, value: 7).displayName, "7♥️")
        XCTAssertEqual(Card(suit: .diamonds, value: 11).displayName, "J♦️")
        XCTAssertEqual(Card(suit: .clubs, value: 12).displayName, "Q♣️")
        XCTAssertEqual(Card(suit: .spades, value: 14).displayName, "A♠️")
    }
    
    // MARK: - Codable Tests
    
    func testCardCodable() throws {
        let originalCard = Card(suit: .hearts, value: 10)
        
        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalCard)
        
        // Decode
        let decoder = JSONDecoder()
        let decodedCard = try decoder.decode(Card.self, from: data)
        
        // Verify
        XCTAssertEqual(originalCard.suit, decodedCard.suit)
        XCTAssertEqual(originalCard.value, decodedCard.value)
        XCTAssertEqual(originalCard.isPointCard, decodedCard.isPointCard)
    }
}