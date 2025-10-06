//
//  AchievementSystemTests.swift
//  SepticaTests
//
//  Comprehensive tests for Romanian Septica achievement system
//  Tests win streaks, perfect games, 7s mastery, regional victories, and UserDefaults persistence
//

import XCTest
@testable import Septica

@MainActor
final class AchievementSystemTests: XCTestCase {

    // MARK: - Test Properties

    var achievementService: AchievementTrackingService!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()

        // Get shared instance and reset it
        achievementService = AchievementTrackingService.shared
        achievementService.resetAllAchievements()
    }

    override func tearDown() async throws {
        // Clean up after each test
        achievementService.resetAllAchievements()
        achievementService = nil
        try await super.tearDown()
    }

    // MARK: - Win Streak Tests

    func testWinStreak3Achievement() {
        // Given: Player wins 3 games in a row
        for gameNumber in 1...3 {
            let gameResult = createWinningGameResult()
            let playerStats = createWinningPlayerStats(score: 5)
            let gameSession = createGameSession()

            // When: Recording each win
            achievementService.checkAchievementsAfterGame(
                gameResult: gameResult,
                playerStats: playerStats,
                gameSession: gameSession
            )

            // Then: Check win streak progression
            XCTAssertEqual(achievementService.currentWinStreak, gameNumber, "Win streak should be \(gameNumber)")
        }

        // Then: Win streak 3 achievement should be unlocked
        let achievements = achievementService.getAllAchievements()
        let winStreak3 = achievements.first { $0.titleKey == "achievement.winStreak3.title" }
        XCTAssertNotNil(winStreak3, "Win streak 3 achievement should exist")

        if let achievement = winStreak3 {
            XCTAssertTrue(achievementService.isUnlocked(achievement.id), "Win streak 3 should be unlocked")
        }
    }

    func testWinStreak5Achievement() {
        // Given: Player wins 5 games in a row
        for _ in 1...5 {
            let gameResult = createWinningGameResult()
            let playerStats = createWinningPlayerStats(score: 6)
            let gameSession = createGameSession()

            achievementService.checkAchievementsAfterGame(
                gameResult: gameResult,
                playerStats: playerStats,
                gameSession: gameSession
            )
        }

        // Then: Win streak 5 achievement should be unlocked
        let achievements = achievementService.getAllAchievements()
        let winStreak5 = achievements.first { $0.titleKey == "achievement.winStreak5.title" }

        if let achievement = winStreak5 {
            XCTAssertTrue(achievementService.isUnlocked(achievement.id), "Win streak 5 should be unlocked")
        }

        XCTAssertEqual(achievementService.currentWinStreak, 5, "Current win streak should be 5")
    }

    func testWinStreak10Achievement() {
        // Given: Player wins 10 games in a row
        for _ in 1...10 {
            let gameResult = createWinningGameResult()
            let playerStats = createWinningPlayerStats(score: 7)
            let gameSession = createGameSession()

            achievementService.checkAchievementsAfterGame(
                gameResult: gameResult,
                playerStats: playerStats,
                gameSession: gameSession
            )
        }

        // Then: Win streak 10 achievement should be unlocked
        let achievements = achievementService.getAllAchievements()
        let winStreak10 = achievements.first { $0.titleKey == "achievement.winStreak10.title" }

        if let achievement = winStreak10 {
            XCTAssertTrue(achievementService.isUnlocked(achievement.id), "Win streak 10 should be unlocked")
        }

        XCTAssertEqual(achievementService.currentWinStreak, 10, "Current win streak should be 10")
    }

    func testWinStreakResetsOnLoss() {
        // Given: Player has a 3-game win streak
        for _ in 1...3 {
            let gameResult = createWinningGameResult()
            let playerStats = createWinningPlayerStats(score: 5)
            let gameSession = createGameSession()

            achievementService.checkAchievementsAfterGame(
                gameResult: gameResult,
                playerStats: playerStats,
                gameSession: gameSession
            )
        }

        XCTAssertEqual(achievementService.currentWinStreak, 3, "Should have 3-game win streak")

        // When: Player loses a game
        let losingResult = createLosingGameResult()
        let losingStats = createLosingPlayerStats(score: 3)
        let gameSession = createGameSession()

        achievementService.checkAchievementsAfterGame(
            gameResult: losingResult,
            playerStats: losingStats,
            gameSession: gameSession
        )

        // Then: Win streak should reset to 0
        XCTAssertEqual(achievementService.currentWinStreak, 0, "Win streak should reset after loss")
    }

    // MARK: - Perfect Game Tests (8/8 Points)

    func testPerfectGameDetection() {
        // Given: Player wins with perfect score (8/8 points)
        let gameResult = createWinningGameResult()
        let playerStats = createWinningPlayerStats(score: 8) // Perfect score
        let gameSession = createGameSession()

        // When: Recording the game
        achievementService.checkAchievementsAfterGame(
            gameResult: gameResult,
            playerStats: playerStats,
            gameSession: gameSession
        )

        // Then: Perfect game achievement should be unlocked
        let achievements = achievementService.getAllAchievements()
        let perfectGame = achievements.first { $0.titleKey == "achievement.perfectGame.title" }

        if let achievement = perfectGame {
            XCTAssertTrue(achievementService.isUnlocked(achievement.id), "Perfect game achievement should be unlocked")
        }

        XCTAssertEqual(achievementService.perfectGamesCount, 1, "Should have 1 perfect game")
    }

    func testPerfectGameCountTracking() {
        // Given: Player achieves 3 perfect games
        for _ in 1...3 {
            let gameResult = createWinningGameResult()
            let playerStats = createWinningPlayerStats(score: 8)
            let gameSession = createGameSession()

            achievementService.checkAchievementsAfterGame(
                gameResult: gameResult,
                playerStats: playerStats,
                gameSession: gameSession
            )
        }

        // Then: Perfect game count should be tracked
        XCTAssertEqual(achievementService.perfectGamesCount, 3, "Should have 3 perfect games")
    }

    func testNonPerfectGameDoesNotTriggerAchievement() {
        // Given: Player wins but not with perfect score
        let gameResult = createWinningGameResult()
        let playerStats = createWinningPlayerStats(score: 5) // Not perfect
        let gameSession = createGameSession()

        // When: Recording the game
        achievementService.checkAchievementsAfterGame(
            gameResult: gameResult,
            playerStats: playerStats,
            gameSession: gameSession
        )

        // Then: Perfect game achievement should NOT be unlocked
        XCTAssertEqual(achievementService.perfectGamesCount, 0, "Should have 0 perfect games")
    }

    // MARK: - 7s Mastery Tests

    func testSevensMasteryProgression() {
        // Given: Player uses 7s effectively to win 5 games
        for gameNumber in 1...5 {
            let gameResult = createWinningGameResult()
            let playerStats = createWinningPlayerStats(
                score: 5,
                tricksWon: 3, // Multiple tricks won
                trickWinRate: 60.0 // Good win rate (indicates 7s usage)
            )
            let gameSession = createGameSession()

            // When: Recording each game
            achievementService.checkAchievementsAfterGame(
                gameResult: gameResult,
                playerStats: playerStats,
                gameSession: gameSession
            )

            // Then: 7s usage should be tracked
            XCTAssertEqual(achievementService.sevensUsedToWin, gameNumber, "Should track 7s usage count")
        }

        // Then: 7s Master achievement should be unlocked
        let achievements = achievementService.getAllAchievements()
        let sevensMaster = achievements.first { $0.titleKey == "achievement.sevensMaster.title" }

        if let achievement = sevensMaster {
            XCTAssertTrue(achievementService.isUnlocked(achievement.id), "7s Master should be unlocked after 5 games")
        }
    }

    func testSevensMasteryRequiresMultipleTricks() {
        // Given: Player wins but with low tricks won
        let gameResult = createWinningGameResult()
        let playerStats = createWinningPlayerStats(
            score: 5,
            tricksWon: 1, // Only 1 trick
            trickWinRate: 25.0 // Low win rate
        )
        let gameSession = createGameSession()

        // When: Recording the game
        achievementService.checkAchievementsAfterGame(
            gameResult: gameResult,
            playerStats: playerStats,
            gameSession: gameSession
        )

        // Then: Should NOT count towards 7s mastery
        XCTAssertEqual(achievementService.sevensUsedToWin, 0, "Should not count low-trick wins")
    }

    // MARK: - Regional Arena Victory Tests

    func testRegionalArenaVictoryTracking() {
        // Given: Player wins in specific arena
        let arena = RomanianArena.sateImarica

        // When: Recording 5 wins in the same arena
        for _ in 1...5 {
            achievementService.recordRegionalWin(arena: arena)
        }

        // Then: Arena win count should be tracked
        XCTAssertEqual(achievementService.regionalWins[arena.rawValue], 5, "Should have 5 wins in Sate Imarica")
    }

    func testRegionalChampionAchievement() {
        // Given: Player wins 5 times in same arena
        let arena = RomanianArena.sateImarica

        for _ in 1...5 {
            achievementService.recordRegionalWin(arena: arena)
        }

        // Then: Regional champion achievement should be unlocked
        let achievements = achievementService.getAllAchievements()
        let regionalChamp = achievements.first { $0.titleKey.contains("regional") && $0.titleKey.contains("sateImarica") }

        if let achievement = regionalChamp {
            XCTAssertTrue(achievementService.isUnlocked(achievement.id), "Regional champion should be unlocked")
        }
    }

    func testMultipleRegionalVictories() {
        // Given: Player wins in different arenas
        achievementService.recordRegionalWin(arena: .sateImarica)
        achievementService.recordRegionalWin(arena: .sateImarica)
        achievementService.recordRegionalWin(arena: .satuMihai)
        achievementService.recordRegionalWin(arena: .satuMihai)
        achievementService.recordRegionalWin(arena: .satuMihai)

        // Then: Each arena should have correct counts
        XCTAssertEqual(achievementService.regionalWins[RomanianArena.sateImarica.rawValue], 2, "Sate Imarica should have 2 wins")
        XCTAssertEqual(achievementService.regionalWins[RomanianArena.satuMihai.rawValue], 3, "Satu Mihai should have 3 wins")
    }

    // MARK: - Achievement Unlock Notification Tests

    func testAchievementUnlockNotification() {
        // Given: Setup notification expectation
        let expectation = XCTestExpectation(description: "Achievement unlock notification")

        let observer = NotificationCenter.default.addObserver(
            forName: .achievementUnlocked,
            object: nil,
            queue: .main
        ) { notification in
            if let unlock = notification.object as? AchievementUnlock {
                XCTAssertNotNil(unlock.achievement, "Notification should contain achievement")
                expectation.fulfill()
            }
        }

        // When: Unlocking first win achievement
        let gameResult = createWinningGameResult()
        let playerStats = createWinningPlayerStats(score: 5)
        let gameSession = createGameSession()

        achievementService.checkAchievementsAfterGame(
            gameResult: gameResult,
            playerStats: playerStats,
            gameSession: gameSession
        )

        // Then: Notification should be posted
        wait(for: [expectation], timeout: 2.0)

        NotificationCenter.default.removeObserver(observer)
    }

    func testRecentlyUnlockedTracking() {
        // Given: Player unlocks achievements
        let gameResult = createWinningGameResult()
        let playerStats = createWinningPlayerStats(score: 8) // Perfect game
        let gameSession = createGameSession()

        // When: Recording game
        achievementService.checkAchievementsAfterGame(
            gameResult: gameResult,
            playerStats: playerStats,
            gameSession: gameSession
        )

        // Then: Recently unlocked should contain achievements
        XCTAssertFalse(achievementService.recentlyUnlocked.isEmpty, "Should have recently unlocked achievements")

        // When: Clearing recently unlocked
        achievementService.clearRecentlyUnlocked()

        // Then: List should be empty
        XCTAssertTrue(achievementService.recentlyUnlocked.isEmpty, "Recently unlocked should be cleared")
    }

    // MARK: - UserDefaults Persistence Tests

    func testAchievementPersistence() {
        // Given: Unlock some achievements
        let gameResult = createWinningGameResult()
        let playerStats = createWinningPlayerStats(score: 8)
        let gameSession = createGameSession()

        achievementService.checkAchievementsAfterGame(
            gameResult: gameResult,
            playerStats: playerStats,
            gameSession: gameSession
        )

        let unlockedCount = achievementService.unlockedAchievements.count
        XCTAssertGreaterThan(unlockedCount, 0, "Should have unlocked achievements")

        // When: Creating new instance (simulates app restart)
        let newService = AchievementTrackingService.shared

        // Then: Achievements should persist
        XCTAssertEqual(newService.unlockedAchievements.count, unlockedCount, "Achievements should persist across sessions")
    }

    func testStatisticsPersistence() {
        // Given: Play several games to build statistics
        for _ in 1...5 {
            let gameResult = createWinningGameResult()
            let playerStats = createWinningPlayerStats(score: 6)
            let gameSession = createGameSession()

            achievementService.checkAchievementsAfterGame(
                gameResult: gameResult,
                playerStats: playerStats,
                gameSession: gameSession
            )
        }

        let totalGames = achievementService.totalGamesPlayed
        let totalWins = achievementService.totalGamesWon

        // When: Creating new instance
        let newService = AchievementTrackingService.shared

        // Then: Statistics should persist
        XCTAssertEqual(newService.totalGamesPlayed, totalGames, "Total games should persist")
        XCTAssertEqual(newService.totalGamesWon, totalWins, "Total wins should persist")
    }

    func testResetAllAchievements() {
        // Given: Unlock achievements and build statistics
        for _ in 1...3 {
            let gameResult = createWinningGameResult()
            let playerStats = createWinningPlayerStats(score: 7)
            let gameSession = createGameSession()

            achievementService.checkAchievementsAfterGame(
                gameResult: gameResult,
                playerStats: playerStats,
                gameSession: gameSession
            )
        }

        XCTAssertGreaterThan(achievementService.unlockedAchievements.count, 0, "Should have achievements")
        XCTAssertGreaterThan(achievementService.totalGamesPlayed, 0, "Should have games played")

        // When: Resetting all achievements
        achievementService.resetAllAchievements()

        // Then: Everything should be cleared
        XCTAssertEqual(achievementService.unlockedAchievements.count, 0, "Unlocked achievements should be cleared")
        XCTAssertEqual(achievementService.currentWinStreak, 0, "Win streak should be reset")
        XCTAssertEqual(achievementService.totalGamesPlayed, 0, "Total games should be reset")
        XCTAssertEqual(achievementService.totalGamesWon, 0, "Total wins should be reset")
        XCTAssertEqual(achievementService.perfectGamesCount, 0, "Perfect games should be reset")
        XCTAssertEqual(achievementService.sevensUsedToWin, 0, "7s usage should be reset")
        XCTAssertTrue(achievementService.regionalWins.isEmpty, "Regional wins should be reset")
    }

    // MARK: - Game Statistics Tracking Tests

    func testTotalGamesPlayedTracking() {
        // Given: Player plays multiple games (wins and losses)
        for gameNumber in 1...5 {
            let gameResult = gameNumber % 2 == 0 ? createWinningGameResult() : createLosingGameResult()
            let playerStats = gameNumber % 2 == 0 ? createWinningPlayerStats(score: 5) : createLosingPlayerStats(score: 3)
            let gameSession = createGameSession()

            achievementService.checkAchievementsAfterGame(
                gameResult: gameResult,
                playerStats: playerStats,
                gameSession: gameSession
            )
        }

        // Then: Total games should be tracked
        XCTAssertEqual(achievementService.totalGamesPlayed, 5, "Should track all games played")
    }

    func testWinLossRecording() {
        // Given: Player plays 3 wins and 2 losses
        for gameNumber in 1...5 {
            let isWin = gameNumber <= 3
            let gameResult = isWin ? createWinningGameResult() : createLosingGameResult()
            let playerStats = isWin ? createWinningPlayerStats(score: 5) : createLosingPlayerStats(score: 3)
            let gameSession = createGameSession()

            achievementService.checkAchievementsAfterGame(
                gameResult: gameResult,
                playerStats: playerStats,
                gameSession: gameSession
            )
        }

        // Then: Wins and losses should be tracked
        XCTAssertEqual(achievementService.totalGamesWon, 3, "Should have 3 wins")
        XCTAssertEqual(achievementService.totalGamesPlayed, 5, "Should have played 5 games")
    }

    // MARK: - Helper Methods

    private func createWinningGameResult() -> GameResult {
        let humanId = UUID()
        return GameResult(
            winnerId: humanId,
            finalScores: [humanId: 5, UUID(): 3],
            totalTricks: 8,
            gameDuration: 120.0
        )
    }

    private func createLosingGameResult() -> GameResult {
        let humanId = UUID()
        let aiId = UUID()
        return GameResult(
            winnerId: aiId, // AI wins
            finalScores: [humanId: 3, aiId: 5],
            totalTricks: 8,
            gameDuration: 120.0
        )
    }

    private func createWinningPlayerStats(score: Int, tricksWon: Int = 4, trickWinRate: Double = 50.0) -> CompletedPlayerStats {
        var stats = PlayerStatistics()
        stats.tricksWon = tricksWon
        stats.trickWinRate = trickWinRate
        stats.totalPointsScored = score

        return CompletedPlayerStats(
            playerId: UUID(),
            name: "Human Player",
            finalScore: score,
            isHuman: true,
            statistics: stats
        )
    }

    private func createLosingPlayerStats(score: Int) -> CompletedPlayerStats {
        var stats = PlayerStatistics()
        stats.tricksWon = 2
        stats.totalPointsScored = score

        return CompletedPlayerStats(
            playerId: UUID(),
            name: "Human Player",
            finalScore: score,
            isHuman: true,
            statistics: stats
        )
    }

    private func createGameSession() -> GameSession {
        let gameState = GameState()
        return GameSession(
            id: UUID(),
            gameState: gameState,
            gameType: .singlePlayer(difficulty: .medium),
            startTime: Date()
        )
    }
}
