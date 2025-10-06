//
//  MultiPlayerModeTests.swift
//  SepticaTests
//
//  Comprehensive tests for Romanian Septica multi-player game modes
//  Tests 2/3/4-player modes, deck composition, team scoring, and 8s as wild cards
//

import XCTest
@testable import Septica

final class MultiPlayerModeTests: XCTestCase {

    // MARK: - Test Properties

    var gameState: GameState!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        gameState = GameState()
    }

    override func tearDown() {
        gameState = nil
        super.tearDown()
    }

    // MARK: - 2-Player Mode Tests

    func testTwoPlayerModeUsesStandardDeck() {
        // Given: 2-player game mode
        gameState.gameMode = .twoPlayers

        // When: Creating deck for 2-player mode
        let deck = Deck(gameMode: .twoPlayers)

        // Then: Should have exactly 32 cards
        XCTAssertEqual(deck.count, 32, "2-player mode should use 32-card deck")
    }

    func testTwoPlayerModeHasAllEights() {
        // Given: 2-player deck
        let deck = Deck(gameMode: .twoPlayers)

        // When: Counting eights in deck
        let eightCount = deck.allCards.filter { $0.value == 8 }.count

        // Then: Should have all 4 eights
        XCTAssertEqual(eightCount, 4, "2-player deck should have all 4 eights")
    }

    func testTwoPlayerModeEightsNotWildCards() {
        // Given: 2-player mode
        let eight = Card(suit: .hearts, value: 8)
        let targetCard = Card(suit: .spades, value: 10)

        // When: Testing if 8 can beat when not divisible by 3
        let canBeatNormally = GameRules.canBeat(
            attackingCard: eight,
            targetCard: targetCard,
            gameMode: .twoPlayers,
            tableCardsCount: 1
        )

        // Then: 8 should NOT be a wild card (only beats when divisible by 3)
        XCTAssertFalse(canBeatNormally, "8s should not be wild in 2-player mode")
    }

    func testTwoPlayerModeMaxPlayers() {
        // Given/When: Querying max players for 2-player mode
        let maxPlayers = GameRules.maxPlayers(for: .twoPlayers)

        // Then: Should be exactly 2
        XCTAssertEqual(maxPlayers, 2, "2-player mode should have max 2 players")
    }

    // MARK: - 3-Player Mode Tests

    func testThreePlayerModeDeckHas30Cards() {
        // Given: 3-player game mode
        gameState.gameMode = .threePlayers

        // When: Creating deck for 3-player mode
        let deck = Deck(gameMode: .threePlayers)

        // Then: Should have exactly 30 cards (2 eights removed)
        XCTAssertEqual(deck.count, 30, "3-player mode should use 30-card deck")
    }

    func testThreePlayerModeHasOnly2Eights() {
        // Given: 3-player deck
        let deck = Deck(gameMode: .threePlayers)

        // When: Counting eights in deck
        let eightCount = deck.allCards.filter { $0.value == 8 }.count

        // Then: Should have exactly 2 eights (2 removed)
        XCTAssertEqual(eightCount, 2, "3-player deck should have only 2 eights")
    }

    func testThreePlayerModeRemovedEightsAreSpecific() {
        // Given: 3-player deck
        let deck = Deck(gameMode: .threePlayers)

        // When: Checking which eights remain
        let remainingEights = deck.allCards.filter { $0.value == 8 }

        // Then: Should have Hearts and Diamonds eights
        let hasHearts = remainingEights.contains { $0.suit == .hearts }
        let hasDiamonds = remainingEights.contains { $0.suit == .diamonds }

        XCTAssertTrue(hasHearts || hasDiamonds, "Should have at least one red eight")
        XCTAssertEqual(remainingEights.count, 2, "Should have exactly 2 eights")
    }

    func testThreePlayerModeEightsAsWildCards() {
        // Given: 3-player mode with an 8
        let eight = Card(suit: .hearts, value: 8)
        let targetCard = Card(suit: .spades, value: 10)

        // When: Testing if 8 acts as wild card in 3-player mode
        let canBeatAsWild = GameRules.canBeat(
            attackingCard: eight,
            targetCard: targetCard,
            gameMode: .threePlayers,
            tableCardsCount: 0
        )

        // Then: 8 should act as wild card in 3-player mode
        XCTAssertTrue(canBeatAsWild, "8s should be wild cards in 3-player mode")
    }

    func testThreePlayerModeMaxPlayers() {
        // Given/When: Querying max players for 3-player mode
        let maxPlayers = GameRules.maxPlayers(for: .threePlayers)

        // Then: Should be exactly 3
        XCTAssertEqual(maxPlayers, 3, "3-player mode should have max 3 players")
    }

    func testThreePlayerModeHasAllOtherCards() {
        // Given: 3-player deck
        let deck = Deck(gameMode: .threePlayers)

        // When: Counting non-eight cards
        let sevenCount = deck.allCards.filter { $0.value == 7 }.count
        let nineCount = deck.allCards.filter { $0.value == 9 }.count
        let tenCount = deck.allCards.filter { $0.value == 10 }.count
        let aceCount = deck.allCards.filter { $0.value == 14 }.count

        // Then: Should have all 4 of each other value
        XCTAssertEqual(sevenCount, 4, "Should have all 4 sevens")
        XCTAssertEqual(nineCount, 4, "Should have all 4 nines")
        XCTAssertEqual(tenCount, 4, "Should have all 4 tens")
        XCTAssertEqual(aceCount, 4, "Should have all 4 aces")
    }

    // MARK: - 4-Player Mode Tests

    func testFourPlayerModeUsesStandardDeck() {
        // Given: 4-player game mode
        gameState.gameMode = .fourPlayers

        // When: Creating deck for 4-player mode
        let deck = Deck(gameMode: .fourPlayers)

        // Then: Should have exactly 32 cards
        XCTAssertEqual(deck.count, 32, "4-player mode should use 32-card deck")
    }

    func testFourPlayerModeHasAllEights() {
        // Given: 4-player deck
        let deck = Deck(gameMode: .fourPlayers)

        // When: Counting eights in deck
        let eightCount = deck.allCards.filter { $0.value == 8 }.count

        // Then: Should have all 4 eights
        XCTAssertEqual(eightCount, 4, "4-player deck should have all 4 eights")
    }

    func testFourPlayerModeMaxPlayers() {
        // Given/When: Querying max players for 4-player mode
        let maxPlayers = GameRules.maxPlayers(for: .fourPlayers)

        // Then: Should be exactly 4
        XCTAssertEqual(maxPlayers, 4, "4-player mode should have max 4 players")
    }

    func testFourPlayerModeTeamComposition() {
        // Given: 4-player game with players
        gameState.gameMode = .fourPlayers
        gameState.players = [
            Player(name: "Player 1"), // Team A
            Player(name: "Player 2"), // Team B
            Player(name: "Player 3"), // Team A (partner of Player 1)
            Player(name: "Player 4")  // Team B (partner of Player 2)
        ]

        // When: Getting team indices
        let teamAIndices = gameState.teamAIndices
        let teamBIndices = gameState.teamBIndices

        // Then: Teams should be [0,2] and [1,3]
        XCTAssertEqual(teamAIndices, [0, 2], "Team A should be players 0 and 2")
        XCTAssertEqual(teamBIndices, [1, 3], "Team B should be players 1 and 3")
    }

    func testFourPlayerModeTeamScoring() {
        // Given: 4-player game with scores
        gameState.gameMode = .fourPlayers
        let player1 = Player(name: "Player 1")
        let player2 = Player(name: "Player 2")
        let player3 = Player(name: "Player 3")
        let player4 = Player(name: "Player 4")

        player1.score = 3  // Team A
        player2.score = 2  // Team B
        player3.score = 2  // Team A (partner of player1)
        player4.score = 1  // Team B (partner of player2)

        gameState.players = [player1, player2, player3, player4]

        // When: Calculating team scores
        let teamAScore = gameState.teamAScore
        let teamBScore = gameState.teamBScore

        // Then: Team scores should be combined
        XCTAssertEqual(teamAScore, 5, "Team A should have 5 points (3+2)")
        XCTAssertEqual(teamBScore, 3, "Team B should have 3 points (2+1)")
    }

    func testFourPlayerModePartnerIdentification() {
        // Given: 4-player game
        gameState.gameMode = .fourPlayers
        gameState.players = [
            Player(name: "Player 1"),
            Player(name: "Player 2"),
            Player(name: "Player 3"),
            Player(name: "Player 4")
        ]

        // When: Finding partners
        let player0Partner = gameState.getPartnerIndex(for: 0)
        let player1Partner = gameState.getPartnerIndex(for: 1)
        let player2Partner = gameState.getPartnerIndex(for: 2)
        let player3Partner = gameState.getPartnerIndex(for: 3)

        // Then: Partners should be correctly identified
        XCTAssertEqual(player0Partner, 2, "Player 0's partner should be Player 2")
        XCTAssertEqual(player1Partner, 3, "Player 1's partner should be Player 3")
        XCTAssertEqual(player2Partner, 0, "Player 2's partner should be Player 0")
        XCTAssertEqual(player3Partner, 1, "Player 3's partner should be Player 1")
    }

    func testFourPlayerModeTeamMembership() {
        // Given: 4-player game
        gameState.gameMode = .fourPlayers

        // When: Checking team membership
        let player0InTeamA = gameState.isTeamA(playerIndex: 0)
        let player1InTeamA = gameState.isTeamA(playerIndex: 1)
        let player2InTeamA = gameState.isTeamA(playerIndex: 2)
        let player3InTeamA = gameState.isTeamA(playerIndex: 3)

        // Then: Team membership should be correct
        XCTAssertTrue(player0InTeamA, "Player 0 should be in Team A")
        XCTAssertFalse(player1InTeamA, "Player 1 should NOT be in Team A")
        XCTAssertTrue(player2InTeamA, "Player 2 should be in Team A")
        XCTAssertFalse(player3InTeamA, "Player 3 should NOT be in Team A")

        // Check Team B membership
        let player0InTeamB = gameState.isTeamB(playerIndex: 0)
        let player1InTeamB = gameState.isTeamB(playerIndex: 1)

        XCTAssertFalse(player0InTeamB, "Player 0 should NOT be in Team B")
        XCTAssertTrue(player1InTeamB, "Player 1 should be in Team B")
    }

    // MARK: - Game Mode Switching Tests

    func testGameModeEnumSwitching() {
        // Given: Game with 2-player mode
        gameState.gameMode = .twoPlayers

        // When: Switching to 3-player mode
        gameState.gameMode = .threePlayers

        // Then: Mode should update
        XCTAssertEqual(gameState.gameMode, .threePlayers, "Mode should switch to 3-player")

        // When: Switching to 4-player mode
        gameState.gameMode = .fourPlayers

        // Then: Mode should update
        XCTAssertEqual(gameState.gameMode, .fourPlayers, "Mode should switch to 4-player")
    }

    func testDeckCreationMatchesGameMode() {
        // Test 2-player deck
        let deck2P = Deck(gameMode: .twoPlayers)
        XCTAssertEqual(deck2P.count, 32, "2-player deck should have 32 cards")

        // Test 3-player deck
        let deck3P = Deck(gameMode: .threePlayers)
        XCTAssertEqual(deck3P.count, 30, "3-player deck should have 30 cards")

        // Test 4-player deck
        let deck4P = Deck(gameMode: .fourPlayers)
        XCTAssertEqual(deck4P.count, 32, "4-player deck should have 32 cards")
    }

    // MARK: - 8s as Wild Cards Tests (3-Player Mode)

    func testEightsAreWildIn3PlayerMode() {
        // Given: 3-player mode
        let eight = Card(suit: .hearts, value: 8)

        // Test against various cards
        let ten = Card(suit: .spades, value: 10)
        let ace = Card(suit: .diamonds, value: 14)
        let king = Card(suit: .clubs, value: 13)

        // When: Testing if 8 beats these cards
        let beatsTen = GameRules.canBeat(attackingCard: eight, targetCard: ten, gameMode: .threePlayers, tableCardsCount: 0)
        let beatsAce = GameRules.canBeat(attackingCard: eight, targetCard: ace, gameMode: .threePlayers, tableCardsCount: 0)
        let beatsKing = GameRules.canBeat(attackingCard: eight, targetCard: king, gameMode: .threePlayers, tableCardsCount: 0)

        // Then: 8 should beat all cards in 3-player mode
        XCTAssertTrue(beatsTen, "8 should beat 10 in 3-player mode")
        XCTAssertTrue(beatsAce, "8 should beat Ace in 3-player mode")
        XCTAssertTrue(beatsKing, "8 should beat King in 3-player mode")
    }

    func testEightsNotWildIn2PlayerMode() {
        // Given: 2-player mode
        let eight = Card(suit: .hearts, value: 8)
        let ten = Card(suit: .spades, value: 10)

        // When: Testing if 8 beats when NOT divisible by 3
        let canBeat = GameRules.canBeat(
            attackingCard: eight,
            targetCard: ten,
            gameMode: .twoPlayers,
            tableCardsCount: 1  // Not divisible by 3
        )

        // Then: 8 should NOT beat (not wild in 2-player)
        XCTAssertFalse(canBeat, "8 should NOT be wild in 2-player mode")
    }

    func testEightsBeatWhenDivisibleBy3In2PlayerMode() {
        // Given: 2-player mode
        let eight = Card(suit: .hearts, value: 8)
        let ten = Card(suit: .spades, value: 10)

        // When: Testing if 8 beats when divisible by 3
        let beatsAt0 = GameRules.canBeat(attackingCard: eight, targetCard: ten, gameMode: .twoPlayers, tableCardsCount: 0)
        let beatsAt3 = GameRules.canBeat(attackingCard: eight, targetCard: ten, gameMode: .twoPlayers, tableCardsCount: 3)
        let beatsAt6 = GameRules.canBeat(attackingCard: eight, targetCard: ten, gameMode: .twoPlayers, tableCardsCount: 6)

        // Then: 8 should beat when count divisible by 3
        XCTAssertTrue(beatsAt0, "8 should beat when count is 0 (divisible by 3)")
        XCTAssertTrue(beatsAt3, "8 should beat when count is 3 (divisible by 3)")
        XCTAssertTrue(beatsAt6, "8 should beat when count is 6 (divisible by 3)")
    }

    func testSevensAlwaysWildInAllModes() {
        // Given: 7 card
        let seven = Card(suit: .hearts, value: 7)
        let ten = Card(suit: .spades, value: 10)

        // When: Testing in all game modes
        let beats2P = GameRules.canBeat(attackingCard: seven, targetCard: ten, gameMode: .twoPlayers, tableCardsCount: 0)
        let beats3P = GameRules.canBeat(attackingCard: seven, targetCard: ten, gameMode: .threePlayers, tableCardsCount: 0)
        let beats4P = GameRules.canBeat(attackingCard: seven, targetCard: ten, gameMode: .fourPlayers, tableCardsCount: 0)

        // Then: 7 should beat in all modes
        XCTAssertTrue(beats2P, "7 should be wild in 2-player mode")
        XCTAssertTrue(beats3P, "7 should be wild in 3-player mode")
        XCTAssertTrue(beats4P, "7 should be wild in 4-player mode")
    }

    // MARK: - Edge Case Tests

    func testThreePlayerModeNoBlackEights() {
        // Given: 3-player deck that removes black eights
        let deck = Deck(gameMode: .threePlayers)

        // When: Checking for black eights
        let hasSpadeEight = deck.allCards.contains { $0.suit == .spades && $0.value == 8 }
        let hasClubEight = deck.allCards.contains { $0.suit == .clubs && $0.value == 8 }

        // Then: Should not have both black eights
        let blackEightCount = (hasSpadeEight ? 1 : 0) + (hasClubEight ? 1 : 0)
        XCTAssertLessThanOrEqual(blackEightCount, 0, "Should have removed both black eights")
    }

    func testFourPlayerEmptyTeamScores() {
        // Given: 4-player game with no scores
        gameState.gameMode = .fourPlayers
        gameState.players = [
            Player(name: "Player 1"),
            Player(name: "Player 2"),
            Player(name: "Player 3"),
            Player(name: "Player 4")
        ]

        // When: Calculating team scores
        let teamAScore = gameState.teamAScore
        let teamBScore = gameState.teamBScore

        // Then: Both teams should have 0
        XCTAssertEqual(teamAScore, 0, "Team A should start with 0 points")
        XCTAssertEqual(teamBScore, 0, "Team B should start with 0 points")
    }

    func testTeamFunctionsReturnEmptyFor2PlayerMode() {
        // Given: 2-player mode
        gameState.gameMode = .twoPlayers

        // When: Querying team functions
        let teamAIndices = gameState.teamAIndices
        let teamBIndices = gameState.teamBIndices

        // Then: Should return empty arrays
        XCTAssertTrue(teamAIndices.isEmpty, "2-player mode should have empty Team A")
        XCTAssertTrue(teamBIndices.isEmpty, "2-player mode should have empty Team B")
    }

    func testPartnerIndexReturnsNilForNon4PlayerMode() {
        // Given: 2-player mode
        gameState.gameMode = .twoPlayers

        // When: Requesting partner
        let partner = gameState.getPartnerIndex(for: 0)

        // Then: Should return nil
        XCTAssertNil(partner, "2-player mode should have no partners")
    }

    // MARK: - Integration Tests

    func testCompleteGameSetupFor3Players() {
        // Given: 3-player game setup
        gameState.gameMode = .threePlayers
        gameState.players = [
            Player(name: "Player 1"),
            Player(name: "Player 2"),
            Player(name: "Player 3")
        ]

        // When: Setting up new game
        gameState.setupNewGame()

        // Then: All players should have correct hand size
        XCTAssertEqual(gameState.players[0].hand.count, GameRules.initialHandSize, "Player 1 should have 4 cards")
        XCTAssertEqual(gameState.players[1].hand.count, GameRules.initialHandSize, "Player 2 should have 4 cards")
        XCTAssertEqual(gameState.players[2].hand.count, GameRules.initialHandSize, "Player 3 should have 4 cards")

        // Deck should have remaining cards
        let totalDealt = 3 * GameRules.initialHandSize
        let expectedRemaining = 30 - totalDealt
        XCTAssertEqual(gameState.deck.count, expectedRemaining, "Deck should have \(expectedRemaining) cards remaining")
    }

    func testCompleteGameSetupFor4Players() {
        // Given: 4-player game setup
        gameState.gameMode = .fourPlayers
        gameState.players = [
            Player(name: "Player 1"),
            Player(name: "Player 2"),
            Player(name: "Player 3"),
            Player(name: "Player 4")
        ]

        // When: Setting up new game
        gameState.setupNewGame()

        // Then: All players should have correct hand size
        for (index, player) in gameState.players.enumerated() {
            XCTAssertEqual(player.hand.count, GameRules.initialHandSize, "Player \(index + 1) should have 4 cards")
        }

        // Deck should have remaining cards
        let totalDealt = 4 * GameRules.initialHandSize
        let expectedRemaining = 32 - totalDealt
        XCTAssertEqual(gameState.deck.count, expectedRemaining, "Deck should have \(expectedRemaining) cards remaining")
    }
}
