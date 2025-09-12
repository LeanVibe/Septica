//
//  Card.swift
//  Septica
//
//  Core card model for Romanian Septica card game
//  Represents individual playing cards with corrected point system
//

import Foundation

/// Represents the four suits in a Romanian card deck
enum Suit: String, CaseIterable, Codable {
    case hearts = "hearts"
    case diamonds = "diamonds"
    case clubs = "clubs"
    case spades = "spades"
    
    var symbol: String {
        switch self {
        case .hearts: return "♥️"
        case .diamonds: return "♦️"
        case .clubs: return "♣️"
        case .spades: return "♠️"
        }
    }
}

/// Represents a single playing card in the Septica game
struct Card: Identifiable, Codable, Equatable, Hashable {
    let id = UUID()
    let suit: Suit
    let value: Int // 7-14 (7,8,9,10,J=11,Q=12,K=13,A=14)
    
    // MARK: - Codable Implementation
    private enum CodingKeys: String, CodingKey {
        case suit, value
        // id is excluded from encoding/decoding
    }
    
    /// Initialize a card with suit and value
    /// - Parameters:
    ///   - suit: The card's suit
    ///   - value: The card's value (7-14, where J=11, Q=12, K=13, A=14)
    init(suit: Suit, value: Int) {
        precondition(value >= 7 && value <= 14, "Card value must be between 7 and 14")
        self.suit = suit
        self.value = value
    }
    
    /// Returns true if this card is worth a point in Septica
    /// Point cards are 10s and Aces (value 14)
    var isPointCard: Bool {
        return value == 10 || value == 14 // 10s and Aces
    }
    
    /// Returns the display name for the card value
    var displayValue: String {
        switch value {
        case 7...10: return "\(value)"
        case 11: return "J"
        case 12: return "Q"
        case 13: return "K"
        case 14: return "A"
        default: return "\(value)"
        }
    }
    
    /// Returns the full display name of the card
    var displayName: String {
        return "\(displayValue)\(suit.symbol)"
    }
    
    /// Returns true if this card can beat the given card according to Septica rules
    /// - Parameter otherCard: The card to potentially beat
    /// - Parameter tableCardsCount: Current number of cards on the table (for 8 special rule)
    /// - Returns: true if this card can beat the other card
    func canBeat(_ otherCard: Card, tableCardsCount: Int) -> Bool {
        // 7 always beats (wild card)
        if self.value == 7 {
            return true
        }
        
        // 8 beats when table cards count is divisible by 3
        if self.value == 8 && tableCardsCount % 3 == 0 {
            return true
        }
        
        // Same value beats
        if self.value == otherCard.value {
            return true
        }
        
        return false
    }
}

// MARK: - Card Extensions for Game Logic

extension Card {
    /// Creates a card from its string representation (e.g., "7H", "AS")
    /// - Parameter string: String representation of the card
    /// - Returns: Card instance or nil if invalid
    static func fromString(_ string: String) -> Card? {
        guard string.count >= 2 else { return nil }
        
        let valueString = String(string.dropLast())
        let suitString = String(string.suffix(1))
        
        // Parse value
        let value: Int
        switch valueString {
        case "7", "8", "9", "10":
            guard let intValue = Int(valueString) else { return nil }
            value = intValue
        case "J": value = 11
        case "Q": value = 12
        case "K": value = 13
        case "A": value = 14
        default: return nil
        }
        
        // Parse suit
        let suit: Suit
        switch suitString.uppercased() {
        case "H": suit = .hearts
        case "D": suit = .diamonds
        case "C": suit = .clubs
        case "S": suit = .spades
        default: return nil
        }
        
        return Card(suit: suit, value: value)
    }
    
    /// Returns the string representation of the card (e.g., "7H", "AS")
    var stringRepresentation: String {
        let valueString = displayValue
        let suitString = String(suit.rawValue.first!).uppercased()
        return "\(valueString)\(suitString)"
    }
}

// MARK: - Equatable and Comparable Conformance

extension Card {
    /// Custom Equatable implementation that ignores the id field
    /// Two cards are equal if they have the same suit and value
    static func == (lhs: Card, rhs: Card) -> Bool {
        return lhs.suit == rhs.suit && lhs.value == rhs.value
    }
    
    /// Custom Hashable implementation that matches our Equatable implementation
    func hash(into hasher: inout Hasher) {
        hasher.combine(suit)
        hasher.combine(value)
    }
}

extension Card: Comparable {
    static func < (lhs: Card, rhs: Card) -> Bool {
        return lhs.value < rhs.value
    }
}