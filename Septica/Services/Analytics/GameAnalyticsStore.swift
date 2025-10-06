//
//  GameAnalyticsStore.swift
//  Septica
//
//  Privacy-compliant local analytics storage for Romanian Septica
//  NO network calls, NO user identification, anonymous metrics only
//  COPPA compliant - suitable for children's privacy requirements
//

import Foundation
import Combine

/// Local analytics storage manager - fully offline, privacy-first
/// Stores anonymous game metrics in UserDefaults for insights
@MainActor
final class GameAnalyticsStore: ObservableObject {

    // MARK: - UserDefaults Keys

    private enum StorageKey: String, CaseIterable {
        case totalGamesPlayed = "analytics.totalGamesPlayed"
        case totalGameDuration = "analytics.totalGameDuration"
        case gamesByMode = "analytics.gamesByMode"
        case gamesByDifficulty = "analytics.gamesByDifficulty"
        case totalWins = "analytics.totalWins"
        case totalLosses = "analytics.totalLosses"
        case totalPointsCollected = "analytics.totalPointsCollected"
        case cardsPlayedByValue = "analytics.cardsPlayedByValue"
        case sevensPlayed = "analytics.sevensPlayed"
        case pointCardsCollected = "analytics.pointCardsCollected"
        case arenaPreferences = "analytics.arenaPreferences"
        case averageGameDuration = "analytics.averageGameDuration"
        case longestGameDuration = "analytics.longestGameDuration"
        case shortestGameDuration = "analytics.shortestGameDuration"
        case tricksWon = "analytics.tricksWon"
        case tricksLost = "analytics.tricksLost"
        case objectionsUsed = "analytics.objectionsUsed"
        case objectionsPassed = "analytics.objectionsPassed"
        case tutorialCompleted = "analytics.tutorialCompleted"
        case analyticsOptOut = "analytics.optOut"
        case firstGameDate = "analytics.firstGameDate"
        case lastGameDate = "analytics.lastGameDate"
    }

    // MARK: - Properties

    private let defaults = UserDefaults.standard

    /// Check if user has opted out of analytics
    var isOptedOut: Bool {
        get { defaults.bool(forKey: StorageKey.analyticsOptOut.rawValue) }
        set { defaults.set(newValue, forKey: StorageKey.analyticsOptOut.rawValue) }
    }

    // MARK: - Initialization

    init() {
        // Initialize first game date if needed
        if defaults.object(forKey: StorageKey.firstGameDate.rawValue) == nil {
            defaults.set(Date(), forKey: StorageKey.firstGameDate.rawValue)
        }
    }

    // MARK: - Game Session Recording

    /// Record game start event
    /// - Parameters:
    ///   - gameType: Type of game (single/multiplayer)
    ///   - difficulty: AI difficulty (if applicable)
    ///   - gameMode: Number of players (2/3/4)
    ///   - arena: Selected Romanian arena
    func recordGameStart(
        gameType: String,
        difficulty: String?,
        gameMode: String,
        arena: String?
    ) {
        guard !isOptedOut else { return }

        // Increment total games
        incrementCounter(key: .totalGamesPlayed)

        // Track game mode distribution
        incrementDictionary(key: .gamesByMode, subKey: gameMode)

        // Track AI difficulty if single player
        if let difficulty = difficulty {
            incrementDictionary(key: .gamesByDifficulty, subKey: difficulty)
        }

        // Track arena preferences
        if let arena = arena {
            incrementDictionary(key: .arenaPreferences, subKey: arena)
        }

        // Update last game date
        defaults.set(Date(), forKey: StorageKey.lastGameDate.rawValue)
    }

    /// Record game end event with results
    /// - Parameters:
    ///   - duration: Game duration in seconds
    ///   - didWin: Whether player won
    ///   - finalScore: Player's final score
    ///   - pointsCollected: Points collected during game
    ///   - tricksWon: Number of tricks won
    func recordGameEnd(
        duration: TimeInterval,
        didWin: Bool,
        finalScore: Int,
        pointsCollected: Int,
        tricksWon: Int
    ) {
        guard !isOptedOut else { return }

        // Track game duration
        let currentTotalDuration = defaults.double(forKey: StorageKey.totalGameDuration.rawValue)
        defaults.set(currentTotalDuration + duration, forKey: StorageKey.totalGameDuration.rawValue)

        // Update duration statistics
        updateDurationStatistics(duration: duration)

        // Track win/loss
        if didWin {
            incrementCounter(key: .totalWins)
        } else {
            incrementCounter(key: .totalLosses)
        }

        // Track points
        let currentPoints = defaults.integer(forKey: StorageKey.totalPointsCollected.rawValue)
        defaults.set(currentPoints + pointsCollected, forKey: StorageKey.totalPointsCollected.rawValue)

        // Track tricks
        let currentTricksWon = defaults.integer(forKey: StorageKey.tricksWon.rawValue)
        defaults.set(currentTricksWon + tricksWon, forKey: StorageKey.tricksWon.rawValue)
    }

    /// Record a card play event
    /// - Parameters:
    ///   - cardValue: Value of card played (7-14)
    ///   - isPointCard: Whether card was point card (10 or Ace)
    ///   - isSeven: Whether card was a seven
    func recordCardPlayed(cardValue: Int, isPointCard: Bool, isSeven: Bool) {
        guard !isOptedOut else { return }

        // Track card value distribution
        let valueKey = "value_\(cardValue)"
        incrementDictionary(key: .cardsPlayedByValue, subKey: valueKey)

        // Track sevens played
        if isSeven {
            incrementCounter(key: .sevensPlayed)
        }

        // Track point cards collected
        if isPointCard {
            incrementCounter(key: .pointCardsCollected)
        }
    }

    /// Record objection system usage
    /// - Parameter didObject: Whether player objected (true) or passed (false)
    func recordObjection(didObject: Bool) {
        guard !isOptedOut else { return }

        if didObject {
            incrementCounter(key: .objectionsUsed)
        } else {
            incrementCounter(key: .objectionsPassed)
        }
    }

    /// Mark tutorial as completed
    func recordTutorialCompletion() {
        guard !isOptedOut else { return }
        defaults.set(true, forKey: StorageKey.tutorialCompleted.rawValue)
    }

    // MARK: - Analytics Retrieval

    /// Get comprehensive analytics summary
    func getAnalyticsSummary() -> AnalyticsSummary {
        let totalGames = defaults.integer(forKey: StorageKey.totalGamesPlayed.rawValue)
        let totalWins = defaults.integer(forKey: StorageKey.totalWins.rawValue)
        let totalLosses = defaults.integer(forKey: StorageKey.totalLosses.rawValue)
        let totalDuration = defaults.double(forKey: StorageKey.totalGameDuration.rawValue)

        return AnalyticsSummary(
            totalGamesPlayed: totalGames,
            totalWins: totalWins,
            totalLosses: totalLosses,
            winRate: totalGames > 0 ? Double(totalWins) / Double(totalGames) * 100.0 : 0.0,
            averageGameDuration: totalGames > 0 ? totalDuration / Double(totalGames) : 0.0,
            longestGameDuration: defaults.double(forKey: StorageKey.longestGameDuration.rawValue),
            shortestGameDuration: defaults.double(forKey: StorageKey.shortestGameDuration.rawValue),
            totalPointsCollected: defaults.integer(forKey: StorageKey.totalPointsCollected.rawValue),
            averagePointsPerGame: totalGames > 0 ? Double(defaults.integer(forKey: StorageKey.totalPointsCollected.rawValue)) / Double(totalGames) : 0.0,
            sevensPlayed: defaults.integer(forKey: StorageKey.sevensPlayed.rawValue),
            pointCardsCollected: defaults.integer(forKey: StorageKey.pointCardsCollected.rawValue),
            tricksWon: defaults.integer(forKey: StorageKey.tricksWon.rawValue),
            objectionsUsed: defaults.integer(forKey: StorageKey.objectionsUsed.rawValue),
            objectionsPassed: defaults.integer(forKey: StorageKey.objectionsPassed.rawValue),
            objectionRate: calculateObjectionRate(),
            gamesByMode: getDictionary(key: .gamesByMode),
            gamesByDifficulty: getDictionary(key: .gamesByDifficulty),
            arenaPreferences: getDictionary(key: .arenaPreferences),
            cardsPlayedByValue: getDictionary(key: .cardsPlayedByValue),
            tutorialCompleted: defaults.bool(forKey: StorageKey.tutorialCompleted.rawValue),
            firstGameDate: defaults.object(forKey: StorageKey.firstGameDate.rawValue) as? Date,
            lastGameDate: defaults.object(forKey: StorageKey.lastGameDate.rawValue) as? Date
        )
    }

    /// Reset all analytics data (for testing or privacy requests)
    func resetAllData() {
        for key in StorageKey.allCases {
            defaults.removeObject(forKey: key.rawValue)
        }

        // Re-initialize first game date
        defaults.set(Date(), forKey: StorageKey.firstGameDate.rawValue)
    }

    // MARK: - Private Helpers

    private func incrementCounter(key: StorageKey) {
        let current = defaults.integer(forKey: key.rawValue)
        defaults.set(current + 1, forKey: key.rawValue)
    }

    private func incrementDictionary(key: StorageKey, subKey: String) {
        var dict = defaults.dictionary(forKey: key.rawValue) as? [String: Int] ?? [:]
        dict[subKey, default: 0] += 1
        defaults.set(dict, forKey: key.rawValue)
    }

    private func getDictionary(key: StorageKey) -> [String: Int] {
        return defaults.dictionary(forKey: key.rawValue) as? [String: Int] ?? [:]
    }

    private func updateDurationStatistics(duration: TimeInterval) {
        // Update average duration
        let totalGames = defaults.integer(forKey: StorageKey.totalGamesPlayed.rawValue)
        let totalDuration = defaults.double(forKey: StorageKey.totalGameDuration.rawValue)
        let avgDuration = totalGames > 0 ? totalDuration / Double(totalGames) : duration
        defaults.set(avgDuration, forKey: StorageKey.averageGameDuration.rawValue)

        // Update longest duration
        let currentLongest = defaults.double(forKey: StorageKey.longestGameDuration.rawValue)
        if duration > currentLongest || currentLongest == 0 {
            defaults.set(duration, forKey: StorageKey.longestGameDuration.rawValue)
        }

        // Update shortest duration
        let currentShortest = defaults.double(forKey: StorageKey.shortestGameDuration.rawValue)
        if duration < currentShortest || currentShortest == 0 {
            defaults.set(duration, forKey: StorageKey.shortestGameDuration.rawValue)
        }
    }

    private func calculateObjectionRate() -> Double {
        let used = defaults.integer(forKey: StorageKey.objectionsUsed.rawValue)
        let passed = defaults.integer(forKey: StorageKey.objectionsPassed.rawValue)
        let total = used + passed

        return total > 0 ? Double(used) / Double(total) * 100.0 : 0.0
    }
}

// MARK: - Supporting Types

/// Comprehensive analytics summary structure
struct AnalyticsSummary {
    // Game Counts
    let totalGamesPlayed: Int
    let totalWins: Int
    let totalLosses: Int
    let winRate: Double

    // Duration Metrics
    let averageGameDuration: TimeInterval
    let longestGameDuration: TimeInterval
    let shortestGameDuration: TimeInterval

    // Score Metrics
    let totalPointsCollected: Int
    let averagePointsPerGame: Double

    // Card Metrics
    let sevensPlayed: Int
    let pointCardsCollected: Int
    let tricksWon: Int

    // Objection System Metrics
    let objectionsUsed: Int
    let objectionsPassed: Int
    let objectionRate: Double

    // Distribution Metrics
    let gamesByMode: [String: Int]
    let gamesByDifficulty: [String: Int]
    let arenaPreferences: [String: Int]
    let cardsPlayedByValue: [String: Int]

    // Tutorial and Dates
    let tutorialCompleted: Bool
    let firstGameDate: Date?
    let lastGameDate: Date?

    // MARK: - Computed Properties

    /// Most played game mode
    var mostPlayedMode: String? {
        return gamesByMode.max(by: { $0.value < $1.value })?.key
    }

    /// Most played AI difficulty
    var mostPlayedDifficulty: String? {
        return gamesByDifficulty.max(by: { $0.value < $1.value })?.key
    }

    /// Favorite arena
    var favoriteArena: String? {
        return arenaPreferences.max(by: { $0.value < $1.value })?.key
    }

    /// Most played card value
    var mostPlayedCardValue: Int? {
        guard let valueStr = cardsPlayedByValue.max(by: { $0.value < $1.value })?.key,
              let value = Int(valueStr.replacingOccurrences(of: "value_", with: "")) else {
            return nil
        }
        return value
    }

    /// Days since first game
    var daysSinceFirstGame: Int {
        guard let firstDate = firstGameDate else { return 0 }
        return Calendar.current.dateComponents([.day], from: firstDate, to: Date()).day ?? 0
    }

    /// Average games per day
    var averageGamesPerDay: Double {
        let days = max(daysSinceFirstGame, 1)
        return Double(totalGamesPlayed) / Double(days)
    }
}
