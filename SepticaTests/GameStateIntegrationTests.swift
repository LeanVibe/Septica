//
//  GameStateIntegrationTests.swift
//  SepticaTests
//
//  Integration tests for GameState with 2-player Romanian Septica rules
//  Tests game flow, multiplayer features, and state transitions
//

import XCTest
@testable import Septica

final class GameStateIntegrationTests: XCTestCase {
    
    var gameState: GameState!
    var player1: Player!
    var player2: Player!
    
    override func setUpWithError() throws {
        // Create test players
        player1 = Player(name: "Player 1")
        player2 = Player(name: "Player 2")
        
        // Create game state with players
        gameState = GameState(players: [player1, player2])
    }
    
    override func tearDownWithError() throws {
        gameState = nil
        player1 = nil
        player2 = nil
    }
    
    // MARK: - 1. Game Initialization Tests
    
    func testGameInitializationWith2Players() {
        XCTAssertEqual(gameState.players.count, 2, "Game should have exactly 2 players")
        XCTAssertEqual(gameState.phase, .playing, "Game should start in playing phase after setup")
        XCTAssertEqual(gameState.roundNumber, 1, "Should start at round 1")
        XCTAssertEqual(gameState.trickNumber, 1, "Should start at trick 1")
    }
    
    func testInitialHandDealing() {
        // Each player should have correct number of cards
        XCTAssertEqual(player1.hand.count, GameRules.initialHandSize)
        XCTAssertEqual(player2.hand.count, GameRules.initialHandSize)
        
        // Deck should have remaining cards
        let expectedRemainingCards = 32 - (2 * GameRules.initialHandSize)
        XCTAssertEqual(gameState.deck.count, expectedRemainingCards)
        
        // No duplicate cards between players and deck
        var allCards = player1.hand + player2.hand + gameState.deck.allCards
        let uniqueCards = Set(allCards.map { "\($0.suit.rawValue)-\($0.value)" })
        XCTAssertEqual(allCards.count, uniqueCards.count, "No duplicate cards should exist")
    }
    
    func testInitialGameState() {
        XCTAssertTrue(gameState.tableCards.isEmpty, "Table should start empty")
        XCTAssertNil(gameState.topTableCard, "No top card on empty table")
        XCTAssertEqual(gameState.currentPlayerIndex, 0, "Should start with first player")
        XCTAssertNil(gameState.gameResult, "No game result at start")
        XCTAssertFalse(gameState.isGameComplete, "Game should not be complete at start")
    }
    
    // MARK: - 2. Card Playing Flow Tests
    
    func testValidCardPlay() {
        // First player plays any card (table is empty)
        let cardToPlay = player1.hand.first!
        
        let result = gameState.playCard(cardToPlay, by: player1.id)
        
        switch result {
        case .success:
            XCTAssertEqual(gameState.tableCards.count, 1, "Table should have 1 card")
            XCTAssertEqual(gameState.tableCards.first!, cardToPlay, "Played card should be on table")
            XCTAssertEqual(gameState.currentPlayerIndex, 1, "Should advance to second player")
            XCTAssertFalse(player1.hand.contains(cardToPlay), "Card should be removed from player's hand")
        case .failure(let error):
            XCTFail("Valid card play failed: \(error)")
        }
    }
    
    func testInvalidCardPlayNotPlayerTurn() {
        // Try to play as second player when it's first player's turn
        let cardToPlay = player2.hand.first!
        
        let result = gameState.playCard(cardToPlay, by: player2.id)
        
        switch result {
        case .success:
            XCTFail("Should not allow play when not player's turn")
        case .failure(let error):
            if case .notPlayerTurn = error {
                XCTAssertTrue(true, "Correctly rejected play out of turn")
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }
    
    func testInvalidCardPlayCardNotInHand() {
        // Try to play a card not in player's hand
        let fakeCard = Card(suit: .hearts, value: 7)
        
        let result = gameState.playCard(fakeCard, by: player1.id)
        
        switch result {
        case .success:
            XCTFail("Should not allow play of card not in hand")
        case .failure(let error):
            if case .invalidMove(let moveError) = error,
               case .cardNotInHand = moveError {
                XCTAssertTrue(true, "Correctly rejected card not in hand")
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }
    
    func testInvalidCardPlayCannotBeat() {
        // First player plays a 10
        let ten = player1.hand.first { $0.value == 10 } ?? 
                  Card(suit: .hearts, value: 10) // Fallback for test
        
        // Force the card into player's hand for testing
        if !player1.hand.contains(ten) {
            player1.hand.append(ten)
        }
        
        _ = gameState.playCard(ten, by: player1.id)
        
        // Second player tries to play a 9 (cannot beat 10)
        let nine = Card(suit: .spades, value: 9)
        if !player2.hand.contains(nine) {
            player2.hand.append(nine)
        }
        
        let result = gameState.playCard(nine, by: player2.id)
        
        switch result {
        case .success:
            XCTFail("Should not allow card that cannot beat")
        case .failure(let error):
            if case .invalidMove(let moveError) = error,
               case .cannotBeatTopCard = moveError {
                XCTAssertTrue(true, "Correctly rejected card that cannot beat")
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }
    
    // MARK: - 3. Trick Completion Tests
    
    func testTrickCompletion() {
        // Player 1 plays 10
        let ten = Card(suit: .hearts, value: 10)
        player1.hand.append(ten)
        _ = gameState.playCard(ten, by: player1.id)
        
        // Player 2 plays 7 (beats the 10)
        let seven = Card(suit: .spades, value: 7)
        player2.hand.append(seven)
        _ = gameState.playCard(seven, by: player2.id)
        
        // Check if trick completed (should be since no more players can beat)
        XCTAssertTrue(gameState.tableCards.isEmpty, "Table should be cleared after trick completion")
        XCTAssertEqual(gameState.trickNumber, 2, "Should advance to next trick")
        XCTAssertEqual(gameState.currentPlayerIndex, 1, "Winner should start next trick")
        
        // Player 2 should have gained points if there were any point cards
        // (10 is a point card worth 1 point)
        XCTAssertGreaterThan(player2.score, 0, "Winner should have gained points from the 10")
    }
    
    func testTrickHistoryRecording() {
        let originalTrickCount = gameState.trickHistory.count
        
        // Play a complete trick
        let ten = Card(suit: .hearts, value: 10)
        player1.hand.append(ten)
        _ = gameState.playCard(ten, by: player1.id)
        
        let seven = Card(suit: .spades, value: 7)
        player2.hand.append(seven)
        _ = gameState.playCard(seven, by: player2.id)
        
        // Check trick history was recorded
        XCTAssertEqual(gameState.trickHistory.count, originalTrickCount + 1, "Trick should be recorded in history")
        
        let lastTrick = gameState.trickHistory.last!
        XCTAssertEqual(lastTrick.cards.count, 2, "Trick should contain both cards")
        XCTAssertEqual(lastTrick.winnerPlayerId, player2.id, "Player 2 should be recorded as winner")
        XCTAssertEqual(lastTrick.points, 1, "Trick should be worth 1 point (from the 10)")
    }
    
    // MARK: - 4. Game Completion Tests
    
    func testGameCompletionWhenAllCardsPlayed() {
        // Simulate game until completion by emptying all hands and deck
        player1.hand.removeAll()
        player2.hand.removeAll()
        gameState.deck = Deck(cards: []) // Empty deck
        
        XCTAssertTrue(gameState.isGameComplete, "Game should be complete when all cards are played")
    }
    
    func testGameNotCompleteWithCardsRemaining() {
        // Game should not be complete while players have cards
        XCTAssertFalse(gameState.isGameComplete, "Game should not be complete with cards remaining")
        
        // Even if deck is empty but players have cards
        gameState.deck = Deck(cards: [])
        XCTAssertFalse(gameState.isGameComplete, "Game should not be complete while players have cards")
    }
    
    func testGameEndProcessing() {
        // Set up end game scenario
        player1.score = 3
        player2.score = 5
        
        // Empty hands and deck to trigger game end
        player1.hand.removeAll()
        player2.hand.removeAll()
        gameState.deck = Deck(cards: [])
        
        // Manually trigger end game
        gameState.endGame()
        
        XCTAssertEqual(gameState.phase, .finished, "Game phase should be finished")
        XCTAssertNotNil(gameState.gameResult, "Game result should be set")
        XCTAssertEqual(gameState.gameResult?.winnerId, player2.id, "Player 2 should be winner with higher score")
        XCTAssertEqual(gameState.gameResult?.finalScores[player2.id], 5, "Final score should be recorded")
    }
    
    // MARK: - 5. Multiplayer Integration Tests
    
    func testMultiplayerConfiguration() {
        let localPlayerId = player1.id
        let sessionId = "test-session-123"
        
        gameState.configureForMultiplayer(localPlayerId: localPlayerId, gameSessionId: sessionId, isOnline: true)
        
        XCTAssertTrue(gameState.isMultiplayer, "Should be configured for multiplayer")
        XCTAssertTrue(gameState.isOnlineGame, "Should be configured as online game")
        XCTAssertEqual(gameState.localPlayerId, localPlayerId, "Local player ID should be set")
        XCTAssertEqual(gameState.gameSessionId, sessionId, "Session ID should be set")
        XCTAssertEqual(gameState.connectionStatus, .connecting, "Should start in connecting status")
    }
    
    func testLocalPlayerTurnDetection() {
        let localPlayerId = player1.id
        gameState.configureForMultiplayer(localPlayerId: localPlayerId, gameSessionId: "test", isOnline: true)
        
        // Should be local player's turn initially (player 1 starts)
        XCTAssertTrue(gameState.isLocalPlayerTurn, "Should be local player's turn")
        
        // Advance to next player
        gameState.currentPlayerIndex = 1
        XCTAssertFalse(gameState.isLocalPlayerTurn, "Should not be local player's turn")
    }
    
    func testRemotePlayerIdentification() {
        let localPlayerId = player1.id
        gameState.configureForMultiplayer(localPlayerId: localPlayerId, gameSessionId: "test", isOnline: true)
        
        let remotePlayer = gameState.remotePlayer
        XCTAssertNotNil(remotePlayer, "Should identify remote player")
        XCTAssertEqual(remotePlayer?.id, player2.id, "Remote player should be player 2")
    }
    
    func testServerSequenceUpdates() {
        gameState.configureForMultiplayer(localPlayerId: player1.id, gameSessionId: "test", isOnline: true)
        
        gameState.updateServerSequence(42)
        XCTAssertEqual(gameState.serverSequenceNumber, 42, "Server sequence should be updated")
    }
    
    // MARK: - 6. Valid Moves Tests
    
    func testValidMovesForCurrentPlayer() {
        // Initially, all cards should be valid (empty table)
        let validMoves = gameState.validMovesForCurrentPlayer()
        XCTAssertEqual(validMoves.count, player1.hand.count, "All cards should be valid on empty table")
        
        // Play a card to set up table
        let cardToPlay = player1.hand.first!
        _ = gameState.playCard(cardToPlay, by: player1.id)
        
        // Now check valid moves for player 2
        let validMoves2 = gameState.validMovesForCurrentPlayer()
        XCTAssertGreaterThan(validMoves2.count, 0, "Player 2 should have some valid moves")
        
        // All returned moves should actually be able to beat the top card
        for move in validMoves2 {
            XCTAssertTrue(
                GameRules.canBeat(
                    attackingCard: move,
                    targetCard: cardToPlay,
                    tableCardsCount: gameState.tableCards.count
                ),
                "Each valid move should actually be able to beat the top card"
            )
        }
    }
    
    func testCurrentPlayerCanMove() {
        XCTAssertTrue(gameState.currentPlayerCanMove(), "Current player should be able to move initially")
        
        // Create scenario where player cannot move
        let unbeatable = Card(suit: .hearts, value: 14) // Ace
        player1.hand = [unbeatable]
        _ = gameState.playCard(unbeatable, by: player1.id)
        
        // Give player 2 only cards that cannot beat Ace
        player2.hand = [
            Card(suit: .spades, value: 9),
            Card(suit: .clubs, value: 11)
        ]
        
        XCTAssertFalse(gameState.currentPlayerCanMove(), "Player should not be able to move")
    }
    
    // MARK: - 7. Performance and State Management Tests
    
    func testBatchUpdates() {
        // Test batch update mechanism
        var updateCount = 0
        let cancellable = gameState.objectWillChange.sink {
            updateCount += 1
        }
        
        gameState.beginBatchUpdates()
        
        // Make multiple changes
        gameState.tableCards.append(Card(suit: .hearts, value: 7))
        gameState.trickNumber += 1
        gameState.roundNumber += 1
        
        gameState.endBatchUpdates()
        
        // Should only have one update notification
        XCTAssertEqual(updateCount, 1, "Should have exactly one update notification from batch")
        
        cancellable.cancel()
    }
    
    func testGameStatistics() {
        // Play a few moves and check statistics
        let stats = gameState.getGameStatistics()
        
        XCTAssertEqual(stats.playerStats.count, 2, "Should have stats for both players")
        XCTAssertGreaterThanOrEqual(stats.totalCardsPlayed, 0, "Total cards played should be non-negative")
        
        for playerStat in stats.playerStats {
            XCTAssertTrue([player1.id, player2.id].contains(playerStat.playerId), "Player ID should match existing players")
        }
    }
    
    // MARK: - 8. Card Dealing and Deck Management Tests
    
    func testNewCardDealing() {
        let originalHandSize = player1.hand.count
        
        // Simulate playing cards until hand is below target size
        player1.hand.removeLast()
        player2.hand.removeLast()
        
        // Force deal new cards
        gameState.dealNewCardsIfNeeded()
        
        // Hands should be replenished if deck has cards
        if !gameState.deck.isEmpty {
            XCTAssertEqual(player1.hand.count, originalHandSize, "Hand should be replenished")
            XCTAssertEqual(player2.hand.count, originalHandSize, "Hand should be replenished")
        }
    }
    
    func testDeckExhaustion() {
        // Empty the deck
        gameState.deck = Deck(cards: [])
        
        let originalHandSize = player1.hand.count
        player1.hand.removeLast()
        
        // Try to deal new cards
        gameState.dealNewCardsIfNeeded()
        
        // Hand should remain smaller since deck is empty
        XCTAssertEqual(player1.hand.count, originalHandSize - 1, "Hand should not be replenished from empty deck")
    }
    
    // MARK: - 9. Error Handling Tests
    
    func testPlayerNotFoundError() {
        let fakePlayerId = UUID()
        let cardToPlay = Card(suit: .hearts, value: 7)
        
        let result = gameState.playCard(cardToPlay, by: fakePlayerId)
        
        switch result {
        case .success:
            XCTFail("Should not succeed with fake player ID")
        case .failure(let error):
            if case .playerNotFound = error {
                XCTAssertTrue(true, "Correctly identified player not found")
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }
    
    // MARK: - 10. Romanian Septica Specific Rules Tests
    
    func testStrictTwoPlayerEnforcement() {
        // Verify that game state enforces exactly 2 players
        XCTAssertEqual(gameState.players.count, GameRules.maxPlayers)
        XCTAssertEqual(gameState.players.count, 2)
        
        // This test implicitly verifies the assertion in dealInitialHands
        // which requires exactly 2 players
    }
    
    func testRomanianSepticaScoringRules() {
        // Only 10s and Aces should count as points
        let mixedCards = [
            Card(suit: .hearts, value: 7),   // 0 points
            Card(suit: .spades, value: 10),  // 1 point
            Card(suit: .clubs, value: 11),   // 0 points (Jack)
            Card(suit: .diamonds, value: 14) // 1 point (Ace)
        ]
        
        let points = GameRules.calculatePoints(from: mixedCards)
        XCTAssertEqual(points, 2, "Should have exactly 2 points from 10 and Ace")
    }
}