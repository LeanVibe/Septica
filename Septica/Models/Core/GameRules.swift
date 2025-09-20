//
//  GameRules.swift
//  Septica
//
//  Core game rules engine for Romanian Septica
//  Implements official Septica rules including card beating logic and scoring
//

import Foundation

/// Core rules engine for the Septica card game
struct GameRules {
    
    // MARK: - Game Constants
    
    /// Total number of cards dealt to each player at game start
    static let initialHandSize = 4
    
    /// Maximum number of players in a Romanian Septica game (strict 2-player)
    static let maxPlayers = 2
    
    /// Total number of point cards in the deck (8 cards: 4 tens + 4 aces)
    static let totalPointCards = 8
    
    /// Total points available in a game (each point card = 1 point)
    static let totalPoints = 8
    
    // MARK: - Romanian Septica Deck Rules
    
    /// Returns the standard Romanian Septica deck (32 cards, 2 players only)
    /// - Returns: Array of cards for Romanian Septica
    static func createDeck() -> [Card] {
        var deck: [Card] = []
        
        // Romanian Septica uses cards 7-A (32 cards total)
        let values = [7, 8, 9, 10, 11, 12, 13, 14] // J=11, Q=12, K=13, A=14
        let suits: [Suit] = [.hearts, .diamonds, .clubs, .spades]
        
        for suit in suits {
            for value in values {
                deck.append(Card(suit: suit, value: value))
            }
        }
        
        return deck.shuffled()
    }
    
    /// Determines if a card is a "taietura" (cutting card) in 2-player Septica
    /// - Parameter card: The card to check
    /// - Returns: true if the card can cut (beat any card)
    static func isCuttingCard(_ card: Card) -> Bool {
        // Only 7s are cutting cards in 2-player Romanian Septica
        return card.value == 7
    }
    
    
    // MARK: - Card Beating Logic
    
    /// Determines if a card can beat another card according to 2-player Romanian Septica rules
    /// - Parameters:
    ///   - attackingCard: The card attempting to beat
    ///   - targetCard: The card being beaten
    ///   - tableCardsCount: Current number of cards on the table
    /// - Returns: true if attacking card can beat the target card
    static func canBeat(attackingCard: Card, targetCard: Card, tableCardsCount: Int) -> Bool {
        // Rule 1: 7s always beat (wild cards)
        if isCuttingCard(attackingCard) {
            return true
        }
        
        // Rule 2: Same value beats (including figure cards)
        if attackingCard.value == targetCard.value {
            return true
        }
        
        // Rule 3: 8s beat when table cards count is divisible by 3
        if attackingCard.value == 8 && tableCardsCount % 3 == 0 {
            return true
        }
        
        // No other cards can beat
        return false
    }
    
    /// Determines if a player can play any card from their hand
    /// - Parameters:
    ///   - playerHand: Cards in the player's hand
    ///   - topTableCard: The top card on the table (to beat)
    ///   - tableCardsCount: Current number of cards on the table
    /// - Returns: true if player has at least one valid move
    static func hasValidMove(playerHand: [Card], topTableCard: Card?, tableCardsCount: Int) -> Bool {
        // If no card on table, player can play any card
        guard let topCard = topTableCard else {
            return !playerHand.isEmpty
        }
        
        // Check if any card in hand can beat the top card
        return playerHand.contains { card in
            canBeat(attackingCard: card, targetCard: topCard, tableCardsCount: tableCardsCount)
        }
    }
    
    /// Get all valid cards a player can play
    /// - Parameters:
    ///   - playerHand: Cards in the player's hand
    ///   - topTableCard: The top card on the table (to beat)
    ///   - tableCardsCount: Current number of cards on the table
    /// - Returns: Array of cards that can be played
    static func validMoves(from playerHand: [Card], against topTableCard: Card?, tableCardsCount: Int) -> [Card] {
        // If no card on table, all cards are valid
        guard let topCard = topTableCard else {
            return playerHand
        }
        
        // Return cards that can beat the top card
        return playerHand.filter { card in
            canBeat(attackingCard: card, targetCard: topCard, tableCardsCount: tableCardsCount)
        }
    }
    
    // MARK: - Trick Logic
    
    /// Determines if a trick is complete (no more players can beat)
    /// - Parameters:
    ///   - tableCards: All cards currently on the table
    ///   - allPlayerHands: All players' hands
    ///   - currentPlayerIndex: Index of the current player
    /// - Returns: true if the trick is complete
    static func isTrickComplete(tableCards: [Card], allPlayerHands: [[Card]], currentPlayerIndex: Int) -> Bool {
        guard let topCard = tableCards.last else {
            return false // No cards on table yet
        }
        
        // Check all players after current player
        let remainingPlayerCount = allPlayerHands.count
        for i in 1..<remainingPlayerCount {
            let playerIndex = (currentPlayerIndex + i) % remainingPlayerCount
            let playerHand = allPlayerHands[playerIndex]
            
            if hasValidMove(playerHand: playerHand, topTableCard: topCard, tableCardsCount: tableCards.count) {
                return false // This player can still beat
            }
        }
        
        return true // No player can beat
    }
    
    /// Determines who wins the current trick
    /// - Parameter tableCards: All cards played in the current trick
    /// - Returns: Index of the winning card (0 = first card played)
    static func determineTrickWinner(tableCards: [Card]) -> Int {
        guard !tableCards.isEmpty else { return 0 }
        guard tableCards.count > 1 else { return 0 }
        
        var winningIndex = 0
        var currentWinningCard = tableCards[0]
        
        // Check each subsequent card to see if it beats the current winner
        for i in 1..<tableCards.count {
            let challengingCard = tableCards[i]
            // tableCardsCount should be the total cards when this card was played (i+1)
            if canBeat(attackingCard: challengingCard, targetCard: currentWinningCard, tableCardsCount: i + 1) {
                winningIndex = i
                currentWinningCard = challengingCard
            }
        }
        
        return winningIndex
    }
    
    /// Calculate points from a collection of cards
    /// - Parameter cards: Cards to count points from
    /// - Returns: Total points (10s and Aces = 1 point each)
    static func calculatePoints(from cards: [Card]) -> Int {
        return cards.filter { $0.isPointCard }.count
    }
    
    // MARK: - Game State Logic
    
    /// Determines if the game is complete
    /// - Parameters:
    ///   - allPlayerHands: All players' hands
    ///   - deckEmpty: Whether the deck is empty
    /// - Returns: true if game should end
    static func isGameComplete(allPlayerHands: [[Card]], deckEmpty: Bool) -> Bool {
        // Game ends when all players have no cards left
        return allPlayerHands.allSatisfy { $0.isEmpty } && deckEmpty
    }
    
    /// Determines the winner of the game based on points
    /// - Parameter playerScores: Points for each player
    /// - Returns: Index of winning player, or nil for tie
    static func determineGameWinner(playerScores: [Int]) -> Int? {
        guard let maxScore = playerScores.max(),
              maxScore > 0 else { return nil }
        
        let winnersWithMaxScore = playerScores.enumerated().compactMap { index, score in
            score == maxScore ? index : nil
        }
        
        // Return winner only if there's a single player with max score
        return winnersWithMaxScore.count == 1 ? winnersWithMaxScore.first : nil
    }
    
    // MARK: - Hand Dealing Logic
    
    /// Deal initial hands to both players from a deck (2-player Septica)
    /// - Parameter deck: Deck to deal from (will be modified)
    /// - Returns: Array of player hands [player1Hand, player2Hand]
    static func dealInitialHands(from deck: inout Deck) -> [[Card]] {
        var hands: [[Card]] = Array(repeating: [], count: maxPlayers)
        
        // Deal cards in round-robin fashion (4 cards each)
        for _ in 0..<initialHandSize {
            for playerIndex in 0..<maxPlayers {
                if let card = deck.drawCard() {
                    hands[playerIndex].append(card)
                }
            }
        }
        
        return hands
    }
    
    // MARK: - Validation Logic
    
    /// Validates a game move
    /// - Parameters:
    ///   - card: Card being played
    ///   - playerHand: Current player's hand
    ///   - topTableCard: Top card on table
    ///   - tableCardsCount: Number of cards on table
    /// - Returns: Validation result
    static func validateMove(card: Card, from playerHand: [Card], against topTableCard: Card?, tableCardsCount: Int) -> MoveValidationResult {
        // Check if player has the card
        guard playerHand.contains(where: { $0.suit == card.suit && $0.value == card.value }) else {
            return .invalid(.cardNotInHand)
        }
        
        // Check if move is legal according to rules
        if let topCard = topTableCard {
            guard canBeat(attackingCard: card, targetCard: topCard, tableCardsCount: tableCardsCount) else {
                return .invalid(.cannotBeatTopCard)
            }
        }
        
        return .valid
    }
}

// MARK: - Supporting Types

/// Result of move validation
enum MoveValidationResult {
    case valid
    case invalid(MoveError)
}

/// Errors that can occur during move validation
enum MoveError: Error, LocalizedError {
    case cardNotInHand
    case cannotBeatTopCard
    case gameNotInProgress
    case notPlayerTurn
    
    var errorDescription: String? {
        switch self {
        case .cardNotInHand:
            return "Card is not in player's hand"
        case .cannotBeatTopCard:
            return "Card cannot beat the top card on the table"
        case .gameNotInProgress:
            return "Game is not in progress"
        case .notPlayerTurn:
            return "It is not the player's turn"
        }
    }
}

// MARK: - Game Rules Extensions

extension GameRules {
    
    /// Get a human-readable explanation of why a card can beat another
    /// - Parameters:
    ///   - attackingCard: Card doing the beating
    ///   - targetCard: Card being beaten
    ///   - tableCardsCount: Number of cards on table
    /// - Returns: Explanation string, or nil if card cannot beat
    static func beatExplanation(attackingCard: Card, targetCard: Card, tableCardsCount: Int) -> String? {
        if attackingCard.value == 7 {
            return "7 always beats (wild card)"
        } else if attackingCard.value == 8 && tableCardsCount % 3 == 0 {
            return "8 beats when table has \(tableCardsCount) cards (divisible by 3)"
        } else if attackingCard.value == targetCard.value {
            return "Same value beats (\(attackingCard.displayValue) beats \(targetCard.displayValue))"
        }
        
        return nil
    }
    
    /// Analyze the strength of a card in the current game context
    /// - Parameters:
    ///   - card: Card to analyze
    ///   - tableCardsCount: Current cards on table
    /// - Returns: Card strength analysis
    static func analyzeCardStrength(card: Card, tableCardsCount: Int) -> CardStrength {
        var strength = CardStrength.normal
        
        // 7 is always strong (wild card)
        if card.value == 7 {
            strength = .veryStrong
        }
        // 8 is strong when table count is divisible by 3
        else if card.value == 8 && tableCardsCount % 3 == 0 {
            strength = .strong
        }
        // Point cards have strategic value
        else if card.isPointCard {
            strength = .valuable
        }
        
        return strength
    }
}

/// Represents the strategic strength of a card
enum CardStrength: String, CaseIterable {
    case veryStrong = "Very Strong"
    case strong = "Strong"
    case valuable = "Valuable"
    case normal = "Normal"
    case weak = "Weak"
}