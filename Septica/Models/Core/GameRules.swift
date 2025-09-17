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
    
    /// Maximum number of players in a Romanian Septica game
    static let maxPlayers = 4
    
    /// Total number of point cards in the deck (8 cards: 4 tens + 4 aces)
    static let totalPointCards = 8
    
    /// Total points available in a game (each point card = 1 point)
    static let totalPoints = 8
    
    // MARK: - Romanian Septica Deck Rules
    
    /// Returns the appropriate deck for the number of players
    /// - Parameter playerCount: Number of players (2-4)
    /// - Returns: Array of cards for Romanian Septica
    static func createDeck(for playerCount: Int) -> [Card] {
        var deck: [Card] = []
        
        // Romanian Septica uses cards 7-A (32 cards total)
        let values = [7, 8, 9, 10, 11, 12, 13, 14] // J=11, Q=12, K=13, A=14
        let suits: [Suit] = [.hearts, .diamonds, .clubs, .spades]
        
        for suit in suits {
            for value in values {
                deck.append(Card(suit: suit, value: value))
            }
        }
        
        // Romanian Rule: For 3 players, remove two 8s (leaving 30 cards)
        if playerCount == 3 {
            let eightsToRemove = deck.filter { $0.value == 8 }.prefix(2)
            for card in eightsToRemove {
                if let index = deck.firstIndex(of: card) {
                    deck.remove(at: index)
                }
            }
        }
        
        return deck.shuffled()
    }
    
    /// Determines if a card is a "taietura" (cutting card) based on player count
    /// - Parameters:
    ///   - card: The card to check
    ///   - playerCount: Number of players in the game
    /// - Returns: true if the card can cut (beat any card)
    static func isCuttingCard(_ card: Card, playerCount: Int) -> Bool {
        // 7s are always cutting cards in Romanian Septica
        if card.value == 7 {
            return true
        }
        
        // In 3-player games, the remaining two 8s also become cutting cards
        if playerCount == 3 && card.value == 8 {
            return true
        }
        
        return false
    }
    
    /// Determines team partnerships for 4-player Romanian Septica
    /// - Parameter players: Array of 4 players
    /// - Returns: Array of team pairs [(team1_player1, team1_player2), (team2_player1, team2_player2)]
    static func createTeams(from players: [Player]) -> [(Player, Player)] {
        guard players.count == 4 else { return [] }
        
        // Romanian Septica team formation: Player 1 & 3 vs Player 2 & 4
        let team1 = (players[0], players[2])
        let team2 = (players[1], players[3])
        
        return [team1, team2]
    }
    
    // MARK: - Card Beating Logic
    
    /// Determines if a card can beat another card according to Romanian Septica rules
    /// - Parameters:
    ///   - attackingCard: The card attempting to beat
    ///   - targetCard: The card being beaten
    ///   - tableCardsCount: Current number of cards on the table
    ///   - playerCount: Number of players (affects cutting card rules)
    /// - Returns: true if attacking card can beat the target card
    static func canBeat(attackingCard: Card, targetCard: Card, tableCardsCount: Int, playerCount: Int = 2) -> Bool {
        // Rule 1: Taieturi (cutting cards) always beat - 7s always, 8s in 3-player games
        if isCuttingCard(attackingCard, playerCount: playerCount) {
            return true
        }
        
        // Rule 2: Same value beats (including figure cards)
        if attackingCard.value == targetCard.value {
            return true
        }
        
        // Rule 3: Classic 8 special rule - beats when table cards count is divisible by 3
        // (This applies even in 2/4 player games where 8s aren't cutting cards)
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
    
    /// Deal initial hands to players from a deck
    /// - Parameters:
    ///   - deck: Deck to deal from (will be modified)
    ///   - playerCount: Number of players
    /// - Returns: Array of player hands
    static func dealInitialHands(from deck: inout Deck, playerCount: Int) -> [[Card]] {
        var hands: [[Card]] = Array(repeating: [], count: playerCount)
        
        // Deal cards in round-robin fashion
        for _ in 0..<initialHandSize {
            for playerIndex in 0..<playerCount {
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