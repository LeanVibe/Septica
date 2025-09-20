//
//  CloudKitIntegrationTests.swift
//  SepticaTests
//
//  Comprehensive test suite for CloudKit integration
//  Tests record management, sync operations, and error handling
//

import XCTest
import CloudKit
import Combine
@testable import Septica

@MainActor
class CloudKitIntegrationTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var cloudKitManager: SepticaCloudKitManager!
    var recordManager: CloudKitRecordManager!
    var syncEngine: CloudKitSyncEngine!
    var errorHandler: CloudKitErrorHandler!
    var cancellables: Set<AnyCancellable>!
    
    // Test data
    var testPlayerProfile: CloudKitPlayerProfile!
    var testGameRecord: CloudKitGameRecord!
    var testCulturalProgress: CulturalEducationProgress!
    
    // MARK: - Setup and Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Initialize CloudKit components
        let container = CKContainer(identifier: "iCloud.dev.septica.romanian.game.test")
        cloudKitManager = SepticaCloudKitManager()
        recordManager = CloudKitRecordManager(container: container)
        syncEngine = CloudKitSyncEngine(cloudKitManager: cloudKitManager)
        errorHandler = CloudKitErrorHandler()
        cancellables = Set<AnyCancellable>()
        
        // Create test data
        createTestData()
        
        // Wait for CloudKit availability
        try await waitForCloudKitAvailability()
    }
    
    override func tearDown() async throws {
        // Cleanup
        cancellables?.removeAll()
        cloudKitManager = nil
        recordManager = nil
        syncEngine = nil
        errorHandler = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func createTestData() {
        // Create test player profile
        testPlayerProfile = CloudKitPlayerProfile(
            playerID: "test_player_\\(UUID().uuidString)",
            displayName: "Test Romanian Player",
            currentArena: .sateImarica,
            trophies: 150,
            totalGamesPlayed: 10,
            totalWins: 7,
            currentStreak: 3,
            longestStreak: 5,
            favoriteAIDifficulty: "medium",
            cardMasteries: ["7_hearts": CardMastery(cardKey: "7_hearts", timesPlayed: 25, successfulPlays: 20, specialPlays: 5, masteryLevel: 1, unlockedEffects: ["glow"])],
            achievements: [.septicaMaster, .folkMusicLover],
            seasonalProgress: SeasonalProgress(seasonID: "2025-test", seasonTrophies: 150, seasonWins: 7, seasonChestsOpened: 2, seasonAchievements: [.septicaMaster], celebrationParticipation: [:]),
            preferences: GamePreferences(),
            culturalEducationProgress: CulturalEducationProgress(gameRulesLearned: ["basic_rules"], folkTalesRead: 3, traditionalMusicKnowledge: 2, cardHistoryKnowledge: 1, quizScores: ["folklore": 85], culturalBadges: ["heritage_student"]),
            lastPlayedDate: Date(),
            createdDate: Date().addingTimeInterval(-86400), // 1 day ago
            heritageEngagementLevel: 0.75,
            folkMusicListened: ["hora_unirii", "sarba_din_ardeal"],
            culturalStoriesRead: ["legenda_primul_joc", "mihai_viteazul"],
            traditionalColorsUnlocked: ["blue_yellow_red", "folk_red"],
            selectedAvatar: RomanianCharacterAvatar.folkMusician.rawValue,
            selectedAvatarFrame: AvatarFrame.folkFrame.rawValue,
            unlockedAvatars: [RomanianCharacterAvatar.traditionalPlayer.rawValue, RomanianCharacterAvatar.folkMusician.rawValue],
            unlockedAvatarFrames: [AvatarFrame.woodenFrame.rawValue, AvatarFrame.folkFrame.rawValue]
        )
        
        // Create test game record
        testGameRecord = CloudKitGameRecord(
            gameID: "test_game_\\(UUID().uuidString)",
            playerID: testPlayerProfile.playerID,
            opponentType: "AI",
            aiDifficulty: "medium",
            gameResult: "win",
            finalScore: GameScore(playerScore: 15, opponentScore: 10, tricksWon: 8, tricksLost: 2),
            gameDuration: 450.0,
            cardsPlayed: [
                CardPlayRecord(cardKey: "7_hearts", playOrder: 1, wasSuccessful: true, trickWon: true, pointsEarned: 3, contextNotes: "Used 7 as wild card"),
                CardPlayRecord(cardKey: "ace_spades", playOrder: 2, wasSuccessful: true, trickWon: true, pointsEarned: 4, contextNotes: "Won with ace")
            ],
            culturalMomentsTriggered: ["seven_wild_mastery", "folk_music_moment"],
            timestamp: Date(),
            arenaAtTimeOfPlay: .sateImarica,
            sevenWildCardUses: 2,
            eightSpecialUses: 1,
            tricksWon: 8,
            pointsScored: 15,
            mistakesMade: ["missed_optimal_play"],
            strategicMoves: ["blocked_opponent_seven", "saved_ace_for_finish"]
        )
        
        // Create test cultural progress
        testCulturalProgress = CulturalEducationProgress(
            gameRulesLearned: ["basic_rules", "seven_wild_rule", "eight_special_rule"],
            folkTalesRead: 5,
            traditionalMusicKnowledge: 3,
            cardHistoryKnowledge: 2,
            quizScores: ["folklore": 85, "history": 92, "music": 78],
            culturalBadges: ["heritage_student", "folk_enthusiast", "tradition_keeper"]
        )
    }
    
    private func waitForCloudKitAvailability() async throws {
        let timeout: TimeInterval = 10.0
        let startTime = Date()
        
        while !cloudKitManager.isAvailable && Date().timeIntervalSince(startTime) < timeout {
            try await Task.sleep(for: .milliseconds(100))
        }
        
        if !cloudKitManager.isAvailable {
            throw XCTSkip("CloudKit not available for testing")
        }
    }
    
    // MARK: - Record Manager Tests
    
    func testCreatePlayerProfileRecord() throws {
        // Given
        let playerProfile = testPlayerProfile!
        
        // When
        let record = try recordManager.createPlayerProfileRecord(playerProfile)
        
        // Then
        XCTAssertEqual(record.recordType, "SepticaPlayerProfile")
        XCTAssertEqual(record["playerID"] as? String, playerProfile.playerID)
        XCTAssertEqual(record["displayName"] as? String, playerProfile.displayName)
        XCTAssertEqual(record["currentArena"] as? Int, playerProfile.currentArena.rawValue)
        XCTAssertEqual(record["trophies"] as? Int, playerProfile.trophies)
        XCTAssertEqual(record["heritageEngagementLevel"] as? Float, playerProfile.heritageEngagementLevel)
        
        // Verify encoded data exists
        XCTAssertNotNil(record["folkMusicListened"])
        XCTAssertNotNil(record["achievements"])
        XCTAssertNotNil(record["culturalEducationProgress"])
    }
    
    func testParsePlayerProfileRecord() throws {
        // Given
        let originalProfile = testPlayerProfile!
        let record = try recordManager.createPlayerProfileRecord(originalProfile)
        
        // When
        let parsedProfile = try recordManager.parsePlayerProfileRecord(record)
        
        // Then
        XCTAssertEqual(parsedProfile.playerID, originalProfile.playerID)
        XCTAssertEqual(parsedProfile.displayName, originalProfile.displayName)
        XCTAssertEqual(parsedProfile.currentArena, originalProfile.currentArena)
        XCTAssertEqual(parsedProfile.trophies, originalProfile.trophies)
        XCTAssertEqual(parsedProfile.heritageEngagementLevel, originalProfile.heritageEngagementLevel, accuracy: 0.001)
        XCTAssertEqual(parsedProfile.folkMusicListened, originalProfile.folkMusicListened)
        XCTAssertEqual(parsedProfile.achievements.count, originalProfile.achievements.count)
    }
    
    func testCreateGameRecord() throws {
        // Given
        let gameRecord = testGameRecord!
        
        // When
        let record = try recordManager.createGameRecord(gameRecord)
        
        // Then
        XCTAssertEqual(record.recordType, "SepticaGameRecord")
        XCTAssertEqual(record["gameID"] as? String, gameRecord.gameID)
        XCTAssertEqual(record["playerID"] as? String, gameRecord.playerID)
        XCTAssertEqual(record["gameResult"] as? String, gameRecord.gameResult)
        XCTAssertEqual(record["sevenWildCardUses"] as? Int, gameRecord.sevenWildCardUses)
        XCTAssertEqual(record["eightSpecialUses"] as? Int, gameRecord.eightSpecialUses)
        
        // Verify encoded data
        XCTAssertNotNil(record["finalScore"])
        XCTAssertNotNil(record["cardsPlayed"])
        XCTAssertNotNil(record["culturalMomentsTriggered"])
    }
    
    func testParseGameRecord() throws {
        // Given
        let originalRecord = testGameRecord!
        let ckRecord = try recordManager.createGameRecord(originalRecord)
        
        // When
        let parsedRecord = try recordManager.parseGameRecord(ckRecord)
        
        // Then
        XCTAssertEqual(parsedRecord.gameID, originalRecord.gameID)
        XCTAssertEqual(parsedRecord.playerID, originalRecord.playerID)
        XCTAssertEqual(parsedRecord.gameResult, originalRecord.gameResult)
        XCTAssertEqual(parsedRecord.sevenWildCardUses, originalRecord.sevenWildCardUses)
        XCTAssertEqual(parsedRecord.eightSpecialUses, originalRecord.eightSpecialUses)
        XCTAssertEqual(parsedRecord.cardsPlayed.count, originalRecord.cardsPlayed.count)
        XCTAssertEqual(parsedRecord.culturalMomentsTriggered, originalRecord.culturalMomentsTriggered)
    }
    
    func testCreateCulturalProgressRecord() throws {
        // Given
        let progress = testCulturalProgress!
        let playerID = "test_player"
        
        // When
        let record = try recordManager.createCulturalProgressRecord(progress, playerID: playerID)
        
        // Then
        XCTAssertEqual(record.recordType, "SepticaCulturalProgress")
        XCTAssertEqual(record["playerID"] as? String, playerID)
        XCTAssertEqual(record["folkTalesRead"] as? Int, progress.folkTalesRead)
        XCTAssertEqual(record["traditionalMusicKnowledge"] as? Int, progress.traditionalMusicKnowledge)
        XCTAssertEqual(record["cardHistoryKnowledge"] as? Int, progress.cardHistoryKnowledge)
        
        // Verify encoded data
        XCTAssertNotNil(record["gameRulesLearned"])
        XCTAssertNotNil(record["quizScores"])
        XCTAssertNotNil(record["culturalBadges"])
    }
    
    func testParseCulturalProgressRecord() throws {
        // Given
        let originalProgress = testCulturalProgress!
        let playerID = "test_player"
        let record = try recordManager.createCulturalProgressRecord(originalProgress, playerID: playerID)
        
        // When
        let parsedProgress = try recordManager.parseCulturalProgressRecord(record)
        
        // Then
        XCTAssertEqual(parsedProgress.folkTalesRead, originalProgress.folkTalesRead)
        XCTAssertEqual(parsedProgress.traditionalMusicKnowledge, originalProgress.traditionalMusicKnowledge)
        XCTAssertEqual(parsedProgress.cardHistoryKnowledge, originalProgress.cardHistoryKnowledge)
        XCTAssertEqual(parsedProgress.gameRulesLearned, originalProgress.gameRulesLearned)
        XCTAssertEqual(parsedProgress.quizScores, originalProgress.quizScores)
        XCTAssertEqual(parsedProgress.culturalBadges, originalProgress.culturalBadges)
    }
    
    func testCreateAchievementRecord() throws {
        // Given
        let achievement = CulturalAchievement.septicaMaster
        let playerID = "test_player"
        let unlockedDate = Date()
        
        // When
        let record = try recordManager.createAchievementRecord(achievement, playerID: playerID, unlockedDate: unlockedDate)
        
        // Then
        XCTAssertEqual(record.recordType, "SepticaAchievement")
        XCTAssertEqual(record["playerID"] as? String, playerID)
        XCTAssertEqual(record["achievementID"] as? String, achievement.rawValue)
        XCTAssertEqual(record["achievementTitle"] as? String, achievement.title)
        XCTAssertEqual(record["achievementDescription"] as? String, achievement.description)
        XCTAssertEqual(record["unlockedDate"] as? Date, unlockedDate)
    }
    
    func testParseAchievementRecord() throws {
        // Given
        let originalAchievement = CulturalAchievement.folkMusicLover
        let playerID = "test_player"
        let unlockedDate = Date()
        let record = try recordManager.createAchievementRecord(originalAchievement, playerID: playerID, unlockedDate: unlockedDate)
        
        // When
        let (parsedAchievement, parsedPlayerID, parsedDate) = try recordManager.parseAchievementRecord(record)
        
        // Then
        XCTAssertEqual(parsedAchievement, originalAchievement)
        XCTAssertEqual(parsedPlayerID, playerID)
        XCTAssertEqual(parsedDate.timeIntervalSince1970, unlockedDate.timeIntervalSince1970, accuracy: 1.0)
    }
    
    // MARK: - CloudKit Manager Tests
    
    func testSaveAndLoadPlayerProfile() async throws {
        // Skip if CloudKit not available
        try XCTSkipUnless(cloudKitManager.isAvailable, "CloudKit not available")
        
        // Given
        let profile = testPlayerProfile!
        
        // When - Save profile
        try await cloudKitManager.savePlayerProfile(profile)
        
        // Then - Load profile
        let loadedProfile = try await cloudKitManager.loadPlayerProfile(playerID: profile.playerID)
        
        XCTAssertNotNil(loadedProfile)
        XCTAssertEqual(loadedProfile?.playerID, profile.playerID)
        XCTAssertEqual(loadedProfile?.displayName, profile.displayName)
        XCTAssertEqual(loadedProfile?.currentArena, profile.currentArena)
        XCTAssertEqual(loadedProfile?.trophies, profile.trophies)
    }
    
    func testSaveGameRecord() async throws {
        // Skip if CloudKit not available
        try XCTSkipUnless(cloudKitManager.isAvailable, "CloudKit not available")
        
        // Given
        let gameRecord = testGameRecord!
        
        // When/Then - Should not throw
        try await cloudKitManager.saveGameRecord(gameRecord)
    }
    
    func testSaveCulturalProgress() async throws {
        // Skip if CloudKit not available
        try XCTSkipUnless(cloudKitManager.isAvailable, "CloudKit not available")
        
        // Given
        let progress = testCulturalProgress!
        let playerID = "test_player"
        
        // When/Then - Should not throw
        try await cloudKitManager.saveCulturalProgress(progress, playerID: playerID)
    }
    
    func testSaveAchievements() async throws {
        // Skip if CloudKit not available
        try XCTSkipUnless(cloudKitManager.isAvailable, "CloudKit not available")
        
        // Given
        let achievements = [CulturalAchievement.septicaMaster, CulturalAchievement.folkMusicLover]
        let playerID = "test_player"
        
        // When/Then - Should not throw
        try await cloudKitManager.saveAchievements(achievements, playerID: playerID)
    }
    
    func testBatchSaveRecords() async throws {
        // Skip if CloudKit not available
        try XCTSkipUnless(cloudKitManager.isAvailable, "CloudKit not available")
        
        // Given
        let profile1 = testPlayerProfile!
        let profile2 = CloudKitPlayerProfile(
            playerID: "test_player_2",
            displayName: "Test Player 2",
            currentArena: .satuMihai,
            trophies: 300,
            totalGamesPlayed: 20,
            totalWins: 15,
            currentStreak: 2,
            longestStreak: 8,
            favoriteAIDifficulty: "hard",
            cardMasteries: [:],
            achievements: [.traditionalColors],
            seasonalProgress: SeasonalProgress(seasonID: "2025-test", seasonTrophies: 300, seasonWins: 15, seasonChestsOpened: 5, seasonAchievements: [], celebrationParticipation: [:]),
            preferences: GamePreferences(),
            culturalEducationProgress: CulturalEducationProgress(gameRulesLearned: [], folkTalesRead: 0, traditionalMusicKnowledge: 0, cardHistoryKnowledge: 0, quizScores: [:], culturalBadges: []),
            lastPlayedDate: Date(),
            createdDate: Date(),
            heritageEngagementLevel: 0.5,
            folkMusicListened: [],
            culturalStoriesRead: [],
            traditionalColorsUnlocked: [],
            selectedAvatar: RomanianCharacterAvatar.traditionalPlayer.rawValue,
            selectedAvatarFrame: AvatarFrame.woodenFrame.rawValue,
            unlockedAvatars: [RomanianCharacterAvatar.traditionalPlayer.rawValue],
            unlockedAvatarFrames: [AvatarFrame.woodenFrame.rawValue]
        )
        
        let record1 = try recordManager.createPlayerProfileRecord(profile1)
        let record2 = try recordManager.createPlayerProfileRecord(profile2)
        let records = [record1, record2]
        
        // When/Then - Should not throw
        try await cloudKitManager.batchSaveRecords(records)
    }
    
    // MARK: - Sync Engine Tests
    
    func testSyncEngineInitialization() {
        // Given/When
        let syncEngine = CloudKitSyncEngine(cloudKitManager: cloudKitManager)
        
        // Then
        XCTAssertEqual(syncEngine.syncStatus, .idle)
        XCTAssertEqual(syncEngine.syncProgress, 0.0)
        XCTAssertNil(syncEngine.lastSyncDate)
    }
    
    func testPauseSyncOperations() {
        // When
        syncEngine.pauseSyncOperations()
        
        // Then
        XCTAssertEqual(syncEngine.syncStatus, .idle)
        XCTAssertEqual(syncEngine.syncProgress, 0.0)
        XCTAssertEqual(syncEngine.pendingUploads, 0)
        XCTAssertEqual(syncEngine.pendingDownloads, 0)
    }
    
    func testResumeSyncOperations() {
        // Given
        syncEngine.pauseSyncOperations()
        
        // When
        syncEngine.resumeSyncOperations()
        
        // Then
        // Should schedule sync operation without throwing
    }
    
    // MARK: - Error Handler Tests
    
    func testHandleNetworkError() async {
        // Given
        let networkError = CKError(.networkUnavailable)
        
        // When
        let action = await errorHandler.handleCloudKitError(networkError, operation: "test_operation")
        
        // Then
        switch action {
        case .retryWithDelay(let delay):
            XCTAssertGreaterThan(delay, 0)
        case .showError(let message):
            XCTAssertTrue(message.contains("connection"))
        default:
            XCTFail("Unexpected action for network error")
        }
    }
    
    func testHandleQuotaExceededError() async {
        // Given
        let quotaError = CKError(.quotaExceeded)
        
        // When
        let action = await errorHandler.handleCloudKitError(quotaError, operation: "test_operation")
        
        // Then
        switch action {
        case .showError(let message):
            XCTAssertTrue(message.contains("storage") || message.contains("quota"))
        default:
            XCTFail("Unexpected action for quota exceeded error")
        }
    }
    
    func testHandleAuthenticationError() async {
        // Given
        let authError = CKError(.notAuthenticated)
        
        // When
        let action = await errorHandler.handleCloudKitError(authError, operation: "test_operation")
        
        // Then
        switch action {
        case .showError(let message):
            XCTAssertTrue(message.contains("iCloud") || message.contains("sign in"))
        default:
            XCTFail("Unexpected action for authentication error")
        }
    }
    
    func testConflictResolution() async {
        // Given
        let serverRecord = CKRecord(recordType: "TestRecord", recordID: CKRecord.ID(recordName: "test"))
        let clientRecord = CKRecord(recordType: "TestRecord", recordID: CKRecord.ID(recordName: "test"))
        
        serverRecord["testField"] = "server_value" as CKRecordValue
        clientRecord["testField"] = "client_value" as CKRecordValue
        
        let conflictError = CKError(.serverRecordChanged, userInfo: [
            CKRecordChangedErrorServerRecordKey: serverRecord,
            CKRecordChangedErrorClientRecordKey: clientRecord
        ])
        
        // When
        let action = await errorHandler.handleCloudKitError(conflictError, operation: "test_operation")
        
        // Then
        switch action {
        case .requiresUserIntervention(let conflictInfo):
            XCTAssertEqual(conflictInfo.recordType, "TestRecord")
            XCTAssertEqual(conflictInfo.serverRecord.recordType, "TestRecord")
            XCTAssertEqual(conflictInfo.clientRecord.recordType, "TestRecord")
        case .conflictResolved(let resolvedRecord):
            XCTAssertEqual(resolvedRecord.recordType, "TestRecord")
        default:
            XCTFail("Unexpected action for conflict error")
        }
    }
    
    func testRetryCalculation() {
        // Given
        let handler = CloudKitErrorHandler()
        
        // When
        let delay1 = handler.calculateRetryDelay(attemptCount: 0)
        let delay2 = handler.calculateRetryDelay(attemptCount: 1)
        let delay3 = handler.calculateRetryDelay(attemptCount: 2)
        
        // Then
        XCTAssertGreaterThan(delay1, 0)
        XCTAssertGreaterThan(delay2, delay1)
        XCTAssertGreaterThan(delay3, delay2)
        XCTAssertLessThanOrEqual(delay3, 60.0) // Max retry delay
    }
    
    // MARK: - Performance Tests
    
    func testRecordCreationPerformance() throws {
        // This test measures the performance of creating CloudKit records
        measure {
            for _ in 0..<100 {
                _ = try? recordManager.createPlayerProfileRecord(testPlayerProfile)
            }
        }
    }
    
    func testRecordParsingPerformance() throws {
        // Given
        let record = try recordManager.createPlayerProfileRecord(testPlayerProfile)
        
        // This test measures the performance of parsing CloudKit records
        measure {
            for _ in 0..<100 {
                _ = try? recordManager.parsePlayerProfileRecord(record)
            }
        }
    }
    
    // MARK: - Edge Case Tests
    
    func testEmptyPlayerProfile() throws {
        // Given
        let emptyProfile = CloudKitPlayerProfile(
            playerID: "empty_player",
            displayName: "",
            currentArena: .sateImarica,
            trophies: 0,
            totalGamesPlayed: 0,
            totalWins: 0,
            currentStreak: 0,
            longestStreak: 0,
            favoriteAIDifficulty: "easy",
            cardMasteries: [:],
            achievements: [],
            seasonalProgress: SeasonalProgress(seasonID: "empty", seasonTrophies: 0, seasonWins: 0, seasonChestsOpened: 0, seasonAchievements: [], celebrationParticipation: [:]),
            preferences: GamePreferences(),
            culturalEducationProgress: CulturalEducationProgress(gameRulesLearned: [], folkTalesRead: 0, traditionalMusicKnowledge: 0, cardHistoryKnowledge: 0, quizScores: [:], culturalBadges: []),
            lastPlayedDate: Date(),
            createdDate: Date(),
            heritageEngagementLevel: 0.0,
            folkMusicListened: [],
            culturalStoriesRead: [],
            traditionalColorsUnlocked: [],
            selectedAvatar: RomanianCharacterAvatar.traditionalPlayer.rawValue,
            selectedAvatarFrame: AvatarFrame.woodenFrame.rawValue,
            unlockedAvatars: [],
            unlockedAvatarFrames: []
        )
        
        // When/Then - Should not throw
        let record = try recordManager.createPlayerProfileRecord(emptyProfile)
        let parsedProfile = try recordManager.parsePlayerProfileRecord(record)
        
        XCTAssertEqual(parsedProfile.playerID, emptyProfile.playerID)
        XCTAssertEqual(parsedProfile.achievements.count, 0)
        XCTAssertEqual(parsedProfile.cardMasteries.count, 0)
    }
    
    func testLargeDataSets() throws {
        // Given - Profile with large datasets
        let largeProfile = testPlayerProfile!
        
        // Add many achievements
        largeProfile.achievements = CulturalAchievement.allCases
        
        // Add many card masteries
        let suits = ["hearts", "diamonds", "clubs", "spades"]
        let ranks = ["7", "8", "9", "10", "jack", "queen", "king", "ace"]
        for suit in suits {
            for rank in ranks {
                let cardKey = "\\(rank)_\\(suit)"
                largeProfile.cardMasteries[cardKey] = CardMastery(
                    cardKey: cardKey,
                    timesPlayed: 100,
                    successfulPlays: 75,
                    specialPlays: 10,
                    masteryLevel: 3,
                    unlockedEffects: ["glow", "particle", "sound"]
                )
            }
        }
        
        // Add many cultural stories and music
        largeProfile.folkMusicListened = Array(0..<50).map { "song_\\($0)" }
        largeProfile.culturalStoriesRead = Array(0..<30).map { "story_\\($0)" }
        
        // When/Then - Should handle large datasets
        let record = try recordManager.createPlayerProfileRecord(largeProfile)
        let parsedProfile = try recordManager.parsePlayerProfileRecord(record)
        
        XCTAssertEqual(parsedProfile.achievements.count, CulturalAchievement.allCases.count)
        XCTAssertEqual(parsedProfile.cardMasteries.count, 32) // 4 suits × 8 ranks
        XCTAssertEqual(parsedProfile.folkMusicListened.count, 50)
        XCTAssertEqual(parsedProfile.culturalStoriesRead.count, 30)
    }
    
    func testInvalidData() {
        // Test handling of invalid/corrupted data
        let record = CKRecord(recordType: "SepticaPlayerProfile", recordID: CKRecord.ID(recordName: "test"))
        
        // Missing required fields
        XCTAssertThrowsError(try recordManager.parsePlayerProfileRecord(record))
        
        // Add minimal required fields
        record["playerID"] = "test" as CKRecordValue
        record["displayName"] = "Test" as CKRecordValue
        
        // Should not throw with minimal data (should use defaults)
        XCTAssertNoThrow(try recordManager.parsePlayerProfileRecord(record))
    }
}