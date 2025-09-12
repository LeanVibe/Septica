//
//  Deck.swift
//  Septica
//
//  Romanian 32-card deck management for Septica game
//  Handles deck creation, shuffling, and card distribution
//

import Foundation

/// Manages a Romanian 32-card deck used in Septica
struct Deck: Codable {
    private var cards: [Card]
    
    /// Create a new standard 32-card Romanian deck
    init() {
        self.cards = Deck.createStandardDeck()
    }
    
    /// Create a deck from existing cards
    /// - Parameter cards: Array of cards to initialize the deck with
    init(cards: [Card]) {
        self.cards = cards
    }
    
    /// Returns the number of cards remaining in the deck
    var count: Int {
        return cards.count
    }
    
    /// Returns true if the deck is empty
    var isEmpty: Bool {
        return cards.isEmpty
    }
    
    /// Returns all cards in the deck (without removing them)
    var allCards: [Card] {
        return cards
    }
    
    /// Shuffle the deck using Fisher-Yates algorithm
    mutating func shuffle() {
        for i in stride(from: cards.count - 1, through: 1, by: -1) {
            let j = Int.random(in: 0...i)
            cards.swapAt(i, j)
        }
    }
    
    /// Draw the top card from the deck
    /// - Returns: The top card, or nil if deck is empty
    mutating func drawCard() -> Card? {
        guard !cards.isEmpty else { return nil }
        return cards.removeFirst()
    }
    
    /// Draw multiple cards from the top of the deck
    /// - Parameter count: Number of cards to draw
    /// - Returns: Array of cards drawn (may be fewer than requested if deck runs out)
    mutating func drawCards(_ count: Int) -> [Card] {
        let actualCount = Swift.min(count, cards.count)
        var drawnCards: [Card] = []
        
        for _ in 0..<actualCount {
            if let card = drawCard() {
                drawnCards.append(card)
            }
        }
        
        return drawnCards
    }
    
    /// Add a card to the bottom of the deck
    /// - Parameter card: Card to add
    mutating func addCard(_ card: Card) {
        cards.append(card)
    }
    
    /// Add multiple cards to the bottom of the deck
    /// - Parameter cards: Cards to add
    mutating func addCards(_ cards: [Card]) {
        self.cards.append(contentsOf: cards)
    }
    
    /// Reset the deck to a fresh, unshuffled 32-card Romanian deck
    mutating func reset() {
        self.cards = Deck.createStandardDeck()
    }
    
    /// Create a standard Romanian 32-card deck
    /// - Returns: Array of 32 cards (7,8,9,10,J,Q,K,A in each suit)
    private static func createStandardDeck() -> [Card] {
        var deck: [Card] = []
        
        // Create cards for each suit
        for suit in Suit.allCases {
            // Romanian deck uses values 7-14 (7,8,9,10,J,Q,K,A)
            for value in 7...14 {
                deck.append(Card(suit: suit, value: value))
            }
        }
        
        return deck
    }
}

// MARK: - Deck Statistics and Utilities

extension Deck {
    /// Count of point cards remaining in the deck (10s and Aces)
    var pointCardsRemaining: Int {
        return cards.filter { $0.isPointCard }.count
    }
    
    /// Total points remaining in the deck
    var totalPointsRemaining: Int {
        return pointCardsRemaining // Each point card is worth 1 point
    }
    
    /// Get cards of a specific value
    /// - Parameter value: The card value to filter for
    /// - Returns: Array of cards with the specified value
    func cards(withValue value: Int) -> [Card] {
        return cards.filter { $0.value == value }
    }
    
    /// Get cards of a specific suit
    /// - Parameter suit: The suit to filter for
    /// - Returns: Array of cards with the specified suit
    func cards(ofSuit suit: Suit) -> [Card] {
        return cards.filter { $0.suit == suit }
    }
    
    /// Check if the deck contains a specific card
    /// - Parameter card: Card to search for
    /// - Returns: true if the card is in the deck
    func contains(_ card: Card) -> Bool {
        return cards.contains { $0.suit == card.suit && $0.value == card.value }
    }
    
    /// Get deck statistics for debugging/analysis
    var statistics: DeckStatistics {
        return DeckStatistics(
            totalCards: count,
            cardsBySuit: Suit.allCases.map { suit in
                (suit, cards(ofSuit: suit).count)
            }.reduce(into: [:]) { result, pair in
                result[pair.0] = pair.1
            },
            pointCards: pointCardsRemaining,
            totalPoints: totalPointsRemaining
        )
    }
}

/// Statistics about the current state of a deck
struct DeckStatistics {
    let totalCards: Int
    let cardsBySuit: [Suit: Int]
    let pointCards: Int
    let totalPoints: Int
    
    var description: String {
        var desc = "Deck Statistics:\n"
        desc += "Total Cards: \(totalCards)\n"
        desc += "Point Cards: \(pointCards)\n"
        desc += "Total Points: \(totalPoints)\n"
        desc += "Cards by Suit:\n"
        for suit in Suit.allCases {
            desc += "  \(suit.rawValue.capitalized): \(cardsBySuit[suit, default: 0])\n"
        }
        return desc
    }
}

// MARK: - Codable Conformance

extension Deck: Codable {
    enum CodingKeys: String, CodingKey {
        case cards
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.cards = try container.decode([Card].self, forKey: .cards)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(cards, forKey: .cards)
    }
}

// MARK: - Collection Conformance

extension Deck: Collection {
    typealias Index = Array<Card>.Index
    
    var startIndex: Index { return cards.startIndex }
    var endIndex: Index { return cards.endIndex }
    
    subscript(index: Index) -> Card {
        return cards[index]
    }
    
    func index(after i: Index) -> Index {
        return cards.index(after: i)
    }
}