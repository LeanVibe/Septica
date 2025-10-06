//
//  AchievementTrackingService.swift
//  Septica
//
//  Persistent achievement tracking service with UserDefaults storage
//  Manages achievement unlocks, progress tracking, and statistics
//

import Foundation
import Combine

/// Service for tracking and persisting achievement progress
@MainActor
final class AchievementTrackingService: ObservableObject {
    static let shared = AchievementTrackingService()

    // MARK: - Published Properties

    @Published private(set) var unlockedAchievements: Set<UUID> = []
    @Published private(set) var recentlyUnlocked: [AchievementUnlock] = []

    // MARK: - Private Properties

    private let culturalManager: RomanianCulturalAchievementManager
    private let userDefaults = UserDefaults.standard

    // UserDefaults keys
    private enum Keys {
        static let unlockedAchievements = "septica.achievements.unlocked"
        static let achievementProgress = "septica.achievements.progress"
        static let totalExperience = "septica.achievements.experience"
        static let totalCulturalPoints = "septica.achievements.culturalPoints"
        static let winStreak = "septica.stats.winStreak"
        static let totalGamesPlayed = "septica.stats.totalGames"
        static let totalGamesWon = "septica.stats.totalWins"
        static let perfectGamesCount = "septica.stats.perfectGames"
        static let sevensUsedToWin = "septica.stats.sevensUsedToWin"
        static let regionalWins = "septica.stats.regionalWins"
    }

    // MARK: - Gameplay Statistics

    private(set) var currentWinStreak: Int = 0
    private(set) var totalGamesPlayed: Int = 0
    private(set) var totalGamesWon: Int = 0
    private(set) var perfectGamesCount: Int = 0
    private(set) var sevensUsedToWin: Int = 0
    private(set) var regionalWins: [Int: Int] = [:] // Key is RomanianArena.rawValue

    // MARK: - Initialization

    private init() {
        self.culturalManager = RomanianCulturalAchievementManager()
        loadPersistedData()
    }

    // MARK: - Achievement Checking

    /// Check for achievements after a game is completed
    /// - Parameters:
    ///   - gameResult: The completed game result
    ///   - playerStats: Statistics for the winning player
    ///   - gameSession: The completed game session
    func checkAchievementsAfterGame(
        gameResult: GameResult,
        playerStats: CompletedPlayerStats,
        gameSession: GameSession
    ) {
        guard let winnerId = gameResult.winnerId else { return }

        let isHumanWinner = playerStats.playerId == winnerId && playerStats.isHuman

        // Update game statistics
        updateGameStatistics(
            won: isHumanWinner,
            playerStats: playerStats,
            gameResult: gameResult,
            gameSession: gameSession
        )

        if isHumanWinner {
            checkWinBasedAchievements(playerStats: playerStats, gameResult: gameResult)
        }

        // Persist updated data
        savePersistedData()
    }

    /// Update tracked game statistics
    private func updateGameStatistics(
        won: Bool,
        playerStats: CompletedPlayerStats,
        gameResult: GameResult,
        gameSession: GameSession
    ) {
        totalGamesPlayed += 1

        if won {
            totalGamesWon += 1
            currentWinStreak += 1

            // Check for perfect game (8/8 points)
            if playerStats.finalScore == 8 {
                perfectGamesCount += 1
                unlockAchievement(type: .perfectGame)
            }

            // Track 7s usage
            if used7sToWin(playerStats: playerStats) {
                sevensUsedToWin += 1
                checkSevensMasterAchievement()
            }

            // Check win streak achievements
            checkWinStreakAchievements()

        } else {
            currentWinStreak = 0
        }
    }

    /// Check win-based achievements
    private func checkWinBasedAchievements(playerStats: CompletedPlayerStats, gameResult: GameResult) {
        // First Win achievement
        if totalGamesWon == 1 {
            unlockAchievement(type: .firstWin)
        }

        // Milestone wins
        if totalGamesWon == 10 {
            unlockAchievement(type: .veteran)
        }

        if totalGamesWon == 50 {
            unlockAchievement(type: .master)
        }

        if totalGamesWon == 100 {
            unlockAchievement(type: .legend)
        }
    }

    /// Check win streak achievements
    private func checkWinStreakAchievements() {
        if currentWinStreak == 3 {
            unlockAchievement(type: .winStreak3)
        } else if currentWinStreak == 5 {
            unlockAchievement(type: .winStreak5)
        } else if currentWinStreak == 10 {
            unlockAchievement(type: .winStreak10)
        }
    }

    /// Check if player used 7s to win tricks
    /// NOTE: This is a simplified heuristic - ideally we'd track specific 7 card plays
    private func used7sToWin(playerStats: CompletedPlayerStats) -> Bool {
        // Heuristic: If player won multiple tricks and has good win rate, likely used 7s effectively
        let wonMultipleTricks = playerStats.statistics.tricksWon >= 2
        let hasGoodWinRate = playerStats.statistics.trickWinRate > 40.0

        return wonMultipleTricks && hasGoodWinRate
    }

    /// Check 7s Master achievement
    private func checkSevensMasterAchievement() {
        if sevensUsedToWin >= 5 {
            unlockAchievement(type: .sevensMaster)
        }
    }

    /// Record regional arena victory
    func recordRegionalWin(arena: RomanianArena) {
        let arenaKey = arena.rawValue
        regionalWins[arenaKey, default: 0] += 1

        // Check for regional mastery achievements
        if regionalWins[arenaKey] ?? 0 >= 5 {
            unlockAchievement(type: .regionalChampion(arena))
        }
    }

    // MARK: - Achievement Unlocking

    /// Unlock an achievement if not already unlocked
    private func unlockAchievement(type: AchievementType) {
        let achievement = type.toRomanianAchievement()

        // Check if already unlocked
        guard !unlockedAchievements.contains(achievement.id) else { return }

        // Unlock achievement
        unlockedAchievements.insert(achievement.id)

        // Create unlock record
        let unlock = AchievementUnlock(
            achievement: achievement,
            unlockedAt: Date()
        )

        // Add to recently unlocked (for notifications)
        recentlyUnlocked.append(unlock)

        // Update cultural manager
        culturalManager.recordGameEvent(.gameWon)

        // Save to persistence
        savePersistedData()

        // Post notification for UI
        NotificationCenter.default.post(
            name: .achievementUnlocked,
            object: unlock
        )

        print("🏆 Achievement Unlocked: \(achievement.titleKey)")
    }

    /// Clear recently unlocked achievements (after showing notifications)
    func clearRecentlyUnlocked() {
        recentlyUnlocked.removeAll()
    }

    // MARK: - Achievement Queries

    /// Check if an achievement is unlocked
    func isUnlocked(_ achievementId: UUID) -> Bool {
        return unlockedAchievements.contains(achievementId)
    }

    /// Get progress for a specific achievement
    func getProgress(for achievement: RomanianAchievement) -> AchievementProgress? {
        return culturalManager.progress(for: achievement.id)
    }

    /// Get all available achievements
    func getAllAchievements() -> [RomanianAchievement] {
        return culturalManager.available
    }

    /// Get unlocked achievements
    func getUnlockedAchievements() -> [RomanianAchievement] {
        return culturalManager.available.filter { unlockedAchievements.contains($0.id) }
    }

    /// Get locked achievements
    func getLockedAchievements() -> [RomanianAchievement] {
        return culturalManager.available.filter { !unlockedAchievements.contains($0.id) }
    }

    // MARK: - Persistence

    /// Load persisted achievement data from UserDefaults
    private func loadPersistedData() {
        // Load unlocked achievements
        if let unlockedData = userDefaults.array(forKey: Keys.unlockedAchievements) as? [String] {
            unlockedAchievements = Set(unlockedData.compactMap { UUID(uuidString: $0) })
        }

        // Load statistics
        currentWinStreak = userDefaults.integer(forKey: Keys.winStreak)
        totalGamesPlayed = userDefaults.integer(forKey: Keys.totalGamesPlayed)
        totalGamesWon = userDefaults.integer(forKey: Keys.totalGamesWon)
        perfectGamesCount = userDefaults.integer(forKey: Keys.perfectGamesCount)
        sevensUsedToWin = userDefaults.integer(forKey: Keys.sevensUsedToWin)

        // Load regional wins
        if let regionalData = userDefaults.dictionary(forKey: Keys.regionalWins) as? [Int: Int] {
            regionalWins = regionalData
        }
    }

    /// Save achievement data to UserDefaults
    private func savePersistedData() {
        // Save unlocked achievements
        let unlockedArray = Array(unlockedAchievements).map { $0.uuidString }
        userDefaults.set(unlockedArray, forKey: Keys.unlockedAchievements)

        // Save statistics
        userDefaults.set(currentWinStreak, forKey: Keys.winStreak)
        userDefaults.set(totalGamesPlayed, forKey: Keys.totalGamesPlayed)
        userDefaults.set(totalGamesWon, forKey: Keys.totalGamesWon)
        userDefaults.set(perfectGamesCount, forKey: Keys.perfectGamesCount)
        userDefaults.set(sevensUsedToWin, forKey: Keys.sevensUsedToWin)
        userDefaults.set(regionalWins, forKey: Keys.regionalWins)
    }

    /// Reset all achievements (for testing)
    func resetAllAchievements() {
        unlockedAchievements.removeAll()
        recentlyUnlocked.removeAll()
        currentWinStreak = 0
        totalGamesPlayed = 0
        totalGamesWon = 0
        perfectGamesCount = 0
        sevensUsedToWin = 0
        regionalWins.removeAll()

        savePersistedData()
    }
}

// MARK: - Supporting Types

/// Achievement unlock record
struct AchievementUnlock: Identifiable, Equatable {
    let id = UUID()
    let achievement: RomanianAchievement
    let unlockedAt: Date

    static func == (lhs: AchievementUnlock, rhs: AchievementUnlock) -> Bool {
        lhs.id == rhs.id
    }
}

/// Achievement type definitions
enum AchievementType {
    case firstWin
    case winStreak3
    case winStreak5
    case winStreak10
    case perfectGame
    case sevensMaster
    case veteran
    case master
    case legend
    case regionalChampion(RomanianArena)

    func toRomanianAchievement() -> RomanianAchievement {
        switch self {
        case .firstWin:
            return RomanianAchievement(
                titleKey: "achievement.firstWin.title",
                descriptionKey: "achievement.firstWin.description",
                category: .gameplay,
                difficulty: .bronze,
                targetValue: 1,
                experiencePoints: 50,
                culturalPoints: 10,
                badge: AchievementBadge(iconName: "star.fill", tint: .bronze)
            )

        case .winStreak3:
            return RomanianAchievement(
                titleKey: "achievement.winStreak3.title",
                descriptionKey: "achievement.winStreak3.description",
                category: .gameplay,
                difficulty: .silver,
                targetValue: 3,
                experiencePoints: 100,
                culturalPoints: 20,
                badge: AchievementBadge(iconName: "flame.fill", tint: .silver)
            )

        case .winStreak5:
            return RomanianAchievement(
                titleKey: "achievement.winStreak5.title",
                descriptionKey: "achievement.winStreak5.description",
                category: .gameplay,
                difficulty: .gold,
                targetValue: 5,
                experiencePoints: 200,
                culturalPoints: 40,
                badge: AchievementBadge(iconName: "flame.fill", tint: .gold)
            )

        case .winStreak10:
            return RomanianAchievement(
                titleKey: "achievement.winStreak10.title",
                descriptionKey: "achievement.winStreak10.description",
                category: .gameplay,
                difficulty: .legendary,
                targetValue: 10,
                experiencePoints: 500,
                culturalPoints: 100,
                badge: AchievementBadge(iconName: "flame.fill", tint: .cultural)
            )

        case .perfectGame:
            return RomanianAchievement(
                titleKey: "achievement.perfectGame.title",
                descriptionKey: "achievement.perfectGame.description",
                category: .gameplay,
                difficulty: .gold,
                targetValue: 1,
                experiencePoints: 250,
                culturalPoints: 50,
                badge: AchievementBadge(iconName: "crown.fill", tint: .gold)
            )

        case .sevensMaster:
            return RomanianAchievement(
                titleKey: "achievement.sevensMaster.title",
                descriptionKey: "achievement.sevensMaster.description",
                category: .cardMastery,
                difficulty: .gold,
                targetValue: 5,
                experiencePoints: 300,
                culturalPoints: 60,
                badge: AchievementBadge(iconName: "7.circle.fill", tint: .gold)
            )

        case .veteran:
            return RomanianAchievement(
                titleKey: "achievement.veteran.title",
                descriptionKey: "achievement.veteran.description",
                category: .gameplay,
                difficulty: .silver,
                targetValue: 10,
                experiencePoints: 150,
                culturalPoints: 30,
                badge: AchievementBadge(iconName: "shield.fill", tint: .silver)
            )

        case .master:
            return RomanianAchievement(
                titleKey: "achievement.master.title",
                descriptionKey: "achievement.master.description",
                category: .gameplay,
                difficulty: .gold,
                targetValue: 50,
                experiencePoints: 500,
                culturalPoints: 100,
                badge: AchievementBadge(iconName: "shield.fill", tint: .gold)
            )

        case .legend:
            return RomanianAchievement(
                titleKey: "achievement.legend.title",
                descriptionKey: "achievement.legend.description",
                category: .gameplay,
                difficulty: .legendary,
                targetValue: 100,
                experiencePoints: 1000,
                culturalPoints: 200,
                badge: AchievementBadge(iconName: "shield.fill", tint: .cultural)
            )

        case .regionalChampion(let arena):
            return RomanianAchievement(
                titleKey: "achievement.regional.\(arena.rawValue).title",
                descriptionKey: "achievement.regional.\(arena.rawValue).description",
                category: .cultural,
                difficulty: .gold,
                targetValue: 5,
                experiencePoints: 200,
                culturalPoints: 80,
                badge: AchievementBadge(iconName: "map.fill", tint: .cultural)
            )
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let achievementUnlocked = Notification.Name("septica.achievement.unlocked")
}

// Note: RomanianArena enum is defined in CloudKitDataModels.swift
