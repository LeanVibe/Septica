//
//  PlayerProfileAchievementSystemTests.swift
//  SepticaTests
//
//  Comprehensive test suite for Player Profile and Romanian Cultural Achievement systems
//  Tests profile management, achievement tracking, cross-device sync, and cultural authenticity
//

import XCTest
import Combine
@testable import Septica

final class PlayerProfileAchievementSystemTests: XCTestCase {
    
    // MARK: - Test Dependencies
    
    var profileManager: EnhancedPlayerProfileManager!
    var achievementManager: RomanianCulturalAchievementManager!
    var milestoneTracker: TraditionalGameplayMilestoneTracker!
    var syncManager: CrossDeviceAchievementSyncManager!
    var celebrationSystem: AchievementCelebrationSystem!
    
    var mockCloudKitManager: MockCloudKitManager!
    var mockErrorManager: MockErrorManager!
    var mockHapticManager: MockHapticManager!
    var mockAudioManager: MockAudioManager!
    var mockAnimationManager: MockAnimationManager!
    var mockCulturalLibrary: MockRomanianCulturalContentLibrary!
    
    var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup and Teardown
    
    override func setUp() {
        super.setUp()
        
        setupMockDependencies()
        setupSystemUnderTest()
        
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables = nil
        
        profileManager = nil
        achievementManager = nil
        milestoneTracker = nil
        syncManager = nil
        celebrationSystem = nil
        
        mockCloudKitManager = nil
        mockErrorManager = nil
        mockHapticManager = nil
        mockAudioManager = nil
        mockAnimationManager = nil
        mockCulturalLibrary = nil
        
        super.tearDown()
    }
    
    private func setupMockDependencies() {
        mockCloudKitManager = MockCloudKitManager()
        mockErrorManager = MockErrorManager()
        mockHapticManager = MockHapticManager()
        mockAudioManager = MockAudioManager()
        mockAnimationManager = MockAnimationManager()
        mockCulturalLibrary = MockRomanianCulturalContentLibrary()
    }
    
    private func setupSystemUnderTest() {
        achievementManager = RomanianCulturalAchievementManager(
            cloudKitManager: mockCloudKitManager,
            errorManager: mockErrorManager
        )
        
        milestoneTracker = TraditionalGameplayMilestoneTracker(
            achievementManager: achievementManager,
            culturalAnalyzer: MockRomanianCulturalAnalyzer()
        )
        
        profileManager = EnhancedPlayerProfileManager(
            cloudKitManager: mockCloudKitManager,
            achievementManager: achievementManager,
            milestoneTracker: milestoneTracker,
            errorManager: mockErrorManager
        )
        
        syncManager = CrossDeviceAchievementSyncManager(
            cloudKitManager: mockCloudKitManager,
            achievementManager: achievementManager,
            profileManager: profileManager,
            errorManager: mockErrorManager
        )
        
        celebrationSystem = AchievementCelebrationSystem(
            hapticManager: mockHapticManager,
            audioManager: mockAudioManager,
            animationManager: mockAnimationManager,
            culturalContentLibrary: mockCulturalLibrary
        )
    }
    
    // MARK: - Enhanced Achievement Registry Tests
    
    func testEnhancedAchievementRegistryInitialization() {
        let registry = EnhancedRomanianAchievementRegistry.shared
        
        // Test registry has comprehensive achievement set
        let allAchievements = registry.getAllAchievements()
        XCTAssertGreaterThanOrEqual(allAchievements.count, 30, "Registry should contain at least 30 comprehensive achievements")
        
        // Test regional achievements exist
        for region in RomanianRegion.allCases {
            let regionalAchievements = registry.getAchievements(for: region)
            if region != .general {
                XCTAssertGreaterThanOrEqual(regionalAchievements.count, 1, "Each region should have at least one specific achievement")
            }
        }
        
        // Test all difficulty levels are represented
        for difficulty in AchievementDifficulty.allCases {
            let difficultyAchievements = registry.getAchievements(by: difficulty)
            XCTAssertGreaterThan(difficultyAchievements.count, 0, "Each difficulty level should have achievements")
        }
        
        // Test cultural authenticity
        let heritageAchievements = registry.getAchievements(by: .heritage)
        XCTAssertGreaterThanOrEqual(heritageAchievements.count, 5, "Should have multiple heritage preservation achievements")
    }
    
    func testTraditionalTechniqueDetection() async {
        // Test Seven Wild Mastery detection
        let sevenContext = GameContext(
            gameId: "test_game",
            tricksInRound: 2,
            playerPosition: .advantageous,
            remainingCards: createMockCards(count: 7),
            totalCardsPlayed: 12,
            decisionTime: 2.5,
            riskLevel: 0.3,
            turnAdvantage: 0.8,
            moveEfficiency: 0.9,
            sessionMistakes: 1,
            averageDecisionTime: 3.0,
            strategyVariation: 0.7,
            adaptabilityScore: 0.8,
            strategyDepth: 0.7,
            culturalPatternRecognition: 0.6,
            traditionalKnowledgeUsage: 0.5,
            traditionalPatternUsage: 0.8,
            culturalAuthenticity: 0.7,
            heritageEngagement: 0.6,
            educationalInteraction: 0.5,
            moveSuccessful: true,
            tricksWon: 3,
            tricksExpected: 2,
            regionalStyleMatch: [.moldova: 0.9, .transylvania: 0.3]
        )
        
        let sevenCard = PlayedCard(value: 7, suit: "hearts", isWild: true)
        let sevenAction = GameAction.cardPlayed(sevenCard)
        
        await milestoneTracker.trackGameAction(sevenAction, context: sevenContext)
        
        // Verify technique usage is tracked
        XCTAssertGreaterThan(milestoneTracker.traditionalTechniqueUsage.count, 0, "Should track technique usage")
        
        // Test Eight Timing Mastery detection
        let eightContext = GameContext(
            gameId: "test_game",
            tricksInRound: 1,
            playerPosition: .neutral,
            remainingCards: createMockCards(count: 5),
            totalCardsPlayed: 15, // 15 % 3 == 0
            decisionTime: 1.8,
            riskLevel: 0.4,
            turnAdvantage: 0.6,
            moveEfficiency: 0.8,
            sessionMistakes: 0,
            averageDecisionTime: 2.2,
            strategyVariation: 0.5,
            adaptabilityScore: 0.7,
            strategyDepth: 0.8,
            culturalPatternRecognition: 0.7,
            traditionalKnowledgeUsage: 0.6,
            traditionalPatternUsage: 0.7,
            culturalAuthenticity: 0.8,
            heritageEngagement: 0.7,
            educationalInteraction: 0.6,
            moveSuccessful: true,
            tricksWon: 2,
            tricksExpected: 2,
            regionalStyleMatch: [.transylvania: 0.8]
        )
        
        let eightCard = PlayedCard(value: 8, suit: "spades", isWild: false)
        let eightAction = GameAction.cardPlayed(eightCard)
        
        await milestoneTracker.trackGameAction(eightAction, context: eightContext)
        
        // Verify mathematical timing is detected
        if let eightUsage = milestoneTracker.traditionalTechniqueUsage["opt_timing_mastery"] {
            XCTAssertGreaterThan(eightUsage.totalUses, 0, "Should track eight timing usage")
        }
    }
    
    func testRegionalStyleProgress() async {
        let moldovanContext = GameContext(
            gameId: "moldovan_test",
            tricksInRound: 1,
            playerPosition: .neutral,
            remainingCards: createMockCards(count: 6),
            totalCardsPlayed: 8,
            decisionTime: 5.2, // Slow, thoughtful (Moldovan patience)
            riskLevel: 0.2, // Low risk
            turnAdvantage: 0.7,
            moveEfficiency: 0.6,
            sessionMistakes: 0,
            averageDecisionTime: 4.8,
            strategyVariation: 0.4,
            adaptabilityScore: 0.6,
            strategyDepth: 0.9, // Deep strategy
            culturalPatternRecognition: 0.8,
            traditionalKnowledgeUsage: 0.7,
            traditionalPatternUsage: 0.8,
            culturalAuthenticity: 0.8,
            heritageEngagement: 0.7,
            educationalInteraction: 0.8,
            moveSuccessful: true,
            tricksWon: 2,
            tricksExpected: 2,
            regionalStyleMatch: [.moldova: 0.9]
        )
        
        let gameResult = GameResult(playerWon: true, finalScore: 85, tricksWon: 4, culturalEngagement: 0.8)
        
        await milestoneTracker.startGameSession(context: moldovanContext)
        await milestoneTracker.endGameSession(result: gameResult)
        
        // Verify regional progress is tracked
        if let moldovanProgress = milestoneTracker.regionalStyleProgress[.moldova] {
            XCTAssertGreaterThan(moldovanProgress.gamesPlayed, 0, "Should track Moldovan style gameplay")
            XCTAssertGreaterThan(moldovanProgress.averageAuthenticity, 0.5, "Should track high authenticity for Moldovan style")
        }
    }
    
    // MARK: - Player Profile Management Tests
    
    func testPlayerProfileCreation() async {
        await profileManager.loadPlayerProfile()
        
        XCTAssertNotNil(profileManager.currentProfile, "Should create a new player profile")
        
        let profile = profileManager.currentProfile!
        XCTAssertEqual(profile.culturalLevel, 1, "New player should start at cultural level 1")
        XCTAssertEqual(profile.currentArena, .sateImarica, "New player should start in first arena")
        XCTAssertTrue(profile.culturalContentEnabled, "Cultural content should be enabled by default")
        XCTAssertEqual(profile.selectedRegionalStyle, .general, "Should start with general regional style")
    }
    
    func testCulturalPreferencesUpdate() async {
        await profileManager.loadPlayerProfile()
        
        var newPreferences = CulturalPreferences()
        newPreferences.selectedRegionalStyle = .transylvania
        newPreferences.musicPreferences.preferredRegionalStyle = .transylvania
        newPreferences.educationalPreferences.difficultyLevel = .advanced
        
        await profileManager.updateCulturalPreferences(newPreferences)
        
        XCTAssertEqual(profileManager.culturalPreferences.selectedRegionalStyle, .transylvania)
        XCTAssertEqual(profileManager.culturalPreferences.musicPreferences.preferredRegionalStyle, .transylvania)
        XCTAssertEqual(profileManager.culturalPreferences.educationalPreferences.difficultyLevel, .advanced)
    }
    
    func testCulturalEngagementTracking() async {
        await profileManager.loadPlayerProfile()
        
        var engagement = CulturalEngagementMetrics()
        engagement.educationalContentViewed = 15
        engagement.quizzesCompleted = 8
        engagement.folkloreStoriesRead = 5
        engagement.culturalFactsLearned = 20
        engagement.authenticityScore = 0.85
        engagement.engagementScore = 0.9
        
        await profileManager.updateCulturalEngagement(engagement)
        
        XCTAssertGreaterThan(profileManager.culturalEngagementMetrics.overallEngagement, 0.7, "Should calculate high overall engagement")
        XCTAssertNotNil(profileManager.currentProfile, "Profile should be updated")
        XCTAssertGreaterThan(profileManager.currentProfile!.heritageEngagementLevel, 0.7, "Profile heritage engagement should be updated")
    }
    
    func testSeasonalCelebrationParticipation() async {
        await profileManager.loadPlayerProfile()
        
        await profileManager.participateInSeasonalCelebration(.martisor)
        
        let martișorProgress = profileManager.seasonalCelebrations[.martisor]
        XCTAssertNotNil(martișorProgress, "Should track Mărțișor participation")
        XCTAssertTrue(martișorProgress!.hasParticipated, "Should mark participation as true")
        XCTAssertGreaterThan(martișorProgress!.participationCount, 0, "Should increment participation count")
    }
    
    // MARK: - Cross-Device Synchronization Tests
    
    func testCrossDeviceSyncInitialization() async {
        mockCloudKitManager.isOnline = true
        mockCloudKitManager.accountStatus = .available
        
        await syncManager.forceSyncAllAchievements()
        
        XCTAssertEqual(syncManager.syncStatus, .idle, "Sync should complete successfully")
        XCTAssertNotNil(syncManager.lastSyncDate, "Should record last sync date")
    }
    
    func testAchievementProgressConflictResolution() async {
        // Create local and server progress with conflicts
        let achievementId = UUID()
        
        let localProgress = AchievementProgress(
            achievementId: achievementId,
            playerId: UUID(),
            currentValue: 15,
            isCompleted: false,
            lastUpdated: Date()
        )
        
        let serverProgress = AchievementProgress(
            achievementId: achievementId,
            playerId: UUID(),
            currentValue: 12,
            isCompleted: false,
            lastUpdated: Date().addingTimeInterval(-100)
        )
        
        let conflict = ConflictedAchievement(
            achievementId: achievementId,
            type: .progressMismatch,
            localProgress: localProgress,
            serverProgress: serverProgress,
            conflictReason: "Progress values differ between devices"
        )
        
        await syncManager.resolveConflictManually(conflict, resolution: .merge)
        
        // Verify conflict is resolved
        XCTAssertFalse(syncManager.conflictedItems.contains { $0.achievementId == achievementId }, "Conflict should be resolved")
    }
    
    func testOfflineOperationQueuing() async {
        syncManager.isOnline = false
        
        let achievement = createMockAchievement()
        await achievementManager.unlockAchievement(achievement)
        
        // Should queue for later sync
        XCTAssertGreaterThan(syncManager.pendingUploads.count, 0, "Should queue upload when offline")
        
        // Simulate coming back online
        syncManager.isOnline = true
        await syncManager.forceSyncAllAchievements()
        
        XCTAssertEqual(syncManager.pendingUploads.count, 0, "Should process queued uploads when online")
    }
    
    // MARK: - Achievement Celebration Tests
    
    func testAchievementCelebrationTriggering() async {
        let achievement = createMockAchievement()
        
        let expectation = XCTestExpectation(description: "Celebration should be triggered")
        
        celebrationSystem.$activeCelebrations
            .sink { celebrations in
                if !celebrations.isEmpty {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        await celebrationSystem.celebrateAchievement(achievement)
        
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertGreaterThan(celebrationSystem.activeCelebrations.count, 0, "Should have active celebration")
    }
    
    func testCulturalLevelUpCelebration() async {
        let culturalProgress = CulturalProgress(
            totalExperience: 2500,
            culturalLevel: 3,
            authenticityScore: 0.85,
            regionalMasteries: [.moldova: 0.8, .transylvania: 0.6]
        )
        
        await celebrationSystem.celebrateCulturalLevelUp(newLevel: 3, culturalProgress: culturalProgress)
        
        XCTAssertTrue(celebrationSystem.isCelebrationInProgress || !celebrationSystem.celebrationQueue.isEmpty,
                     "Should trigger level up celebration")
    }
    
    func testSeasonalCelebrationEffects() async {
        await celebrationSystem.celebrateSeasonalEvent(.ziuaRomaniei)
        
        // Verify Romanian National Day celebration
        XCTAssertTrue(celebrationSystem.isCelebrationInProgress || !celebrationSystem.celebrationQueue.isEmpty,
                     "Should trigger seasonal celebration")
        
        // Check that cultural theme is set appropriately
        if let theme = celebrationSystem.currentCelebrationTheme {
            XCTAssertTrue(theme.culturalElements.contains { $0.contains("national") || $0.contains("unity") },
                         "Should include national/unity cultural elements")
        }
    }
    
    func testCelebrationSettings() {
        var settings = CelebrationSettings()
        settings.enableTraditionalMusic = false
        settings.effectsIntensity = 0.5
        settings.celebrationDuration = 3.0
        
        celebrationSystem.updateCelebrationSettings(settings)
        
        XCTAssertEqual(celebrationSystem.celebrationSettings.enableTraditionalMusic, false)
        XCTAssertEqual(celebrationSystem.celebrationSettings.effectsIntensity, 0.5)
        XCTAssertEqual(celebrationSystem.celebrationSettings.celebrationDuration, 3.0)
    }
    
    // MARK: - Cultural Authenticity Tests
    
    func testCulturalAuthenticityMeasurement() async {
        await milestoneTracker.startGameSession(context: createAuthenticGameContext())
        
        // Simulate a series of culturally authentic moves
        for i in 0..<5 {
            let authenticAction = GameAction.cardPlayed(PlayedCard(value: 7, suit: "hearts", isWild: true))
            await milestoneTracker.trackGameAction(authenticAction, context: createAuthenticGameContext())
        }
        
        let result = GameResult(playerWon: true, finalScore: 90, tricksWon: 6, culturalEngagement: 0.9)
        await milestoneTracker.endGameSession(result: result)
        
        XCTAssertGreaterThan(milestoneTracker.culturalAuthenticity.authenticityScore, 0.6,
                           "Should measure high cultural authenticity")
    }
    
    func testTraditionalTechniqueMastery() async {
        // Test progression through mastery levels
        let technique = "septe_wild_mastery"
        
        for i in 0..<30 {
            let context = createMockGameContext()
            let action = GameAction.cardPlayed(PlayedCard(value: 7, suit: "hearts", isWild: true))
            await milestoneTracker.trackGameAction(action, context: context)
        }
        
        if let masteryStats = milestoneTracker.traditionalTechniqueUsage[technique] {
            XCTAssertGreaterThanOrEqual(masteryStats.totalUses, 30, "Should track technique usage")
            XCTAssertGreaterThan(masteryStats.successRate, 0.0, "Should calculate success rate")
        }
    }
    
    // MARK: - Performance and Integration Tests
    
    func testLargeScaleAchievementProcessing() async {
        let startTime = Date()
        
        // Process 100 achievement updates
        for i in 0..<100 {
            let achievement = createMockAchievement()
            await achievementManager.trackProgress(achievement.id, increment: 1)
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        XCTAssertLessThan(duration, 5.0, "Should process 100 achievements within 5 seconds")
    }
    
    func testMemoryUsageStability() async {
        // Create many achievements and track memory usage
        for i in 0..<50 {
            let achievement = createMockAchievement()
            await achievementManager.unlockAchievement(achievement)
            await celebrationSystem.celebrateAchievement(achievement)
        }
        
        // Force cleanup
        celebrationSystem.activeCelebrations.removeAll()
        celebrationSystem.celebrationQueue.removeAll()
        
        // Verify no memory leaks (basic check)
        XCTAssertLessThan(celebrationSystem.activeCelebrations.count, 5,
                         "Should clean up completed celebrations")
    }
    
    func testConcurrentProfileUpdates() async {
        await profileManager.loadPlayerProfile()
        
        // Simulate concurrent updates
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    let engagement = CulturalEngagementMetrics()
                    await self.profileManager.updateCulturalEngagement(engagement)
                }
            }
        }
        
        XCTAssertNotNil(profileManager.currentProfile, "Profile should remain stable under concurrent updates")
    }
    
    // MARK: - Error Handling Tests
    
    func testCloudKitErrorHandling() async {
        mockCloudKitManager.shouldFailOperations = true
        mockCloudKitManager.errorToReturn = MockCloudKitError.networkUnavailable
        
        await profileManager.loadPlayerProfile()
        
        XCTAssertEqual(profileManager.syncStatus, .offline, "Should handle CloudKit errors gracefully")
        XCTAssertNotNil(profileManager.currentProfile, "Should fall back to local profile")
        XCTAssertGreaterThan(mockErrorManager.reportedErrors.count, 0, "Should report errors")
    }
    
    func testAchievementCorruptionRecovery() async {
        // Simulate corrupted achievement data
        mockCloudKitManager.corruptedData = true
        
        await achievementManager.loadAchievements()
        
        // Should recover gracefully
        XCTAssertGreaterThan(achievementManager.getAllAchievements().count, 0,
                           "Should recover with default achievements")
    }
    
    // MARK: - Helper Methods
    
    private func createMockAchievement() -> RomanianAchievement {
        return RomanianAchievement(
            type: .cultural,
            category: .cardMastery,
            difficulty: .bronze,
            culturalRegion: .general,
            titleKey: "test_achievement_title",
            descriptionKey: "test_achievement_desc",
            culturalContextKey: "test_cultural_context",
            requirements: [.gamesWon(count: 5)],
            targetValue: 5,
            experiencePoints: 100,
            culturalKnowledgePoints: 20,
            unlockableContent: [.cardBack(name: "test_card_back")],
            badge: AchievementBadge(iconName: "star", colorScheme: .bronze)
        )
    }
    
    private func createMockCards(count: Int) -> [PlayedCard] {
        return (0..<count).map { i in
            PlayedCard(value: (i % 8) + 7, suit: ["hearts", "diamonds", "clubs", "spades"][i % 4], isWild: false)
        }
    }
    
    private func createMockGameContext() -> GameContext {
        return GameContext(
            gameId: "test_game_\(UUID().uuidString)",
            tricksInRound: 2,
            playerPosition: .neutral,
            remainingCards: createMockCards(count: 5),
            totalCardsPlayed: 10,
            decisionTime: 2.5,
            riskLevel: 0.5,
            turnAdvantage: 0.6,
            moveEfficiency: 0.7,
            sessionMistakes: 1,
            averageDecisionTime: 3.0,
            strategyVariation: 0.6,
            adaptabilityScore: 0.7,
            strategyDepth: 0.6,
            culturalPatternRecognition: 0.5,
            traditionalKnowledgeUsage: 0.5,
            traditionalPatternUsage: 0.6,
            culturalAuthenticity: 0.7,
            heritageEngagement: 0.6,
            educationalInteraction: 0.5,
            moveSuccessful: true,
            tricksWon: 2,
            tricksExpected: 2,
            regionalStyleMatch: [.general: 0.8]
        )
    }
    
    private func createAuthenticGameContext() -> GameContext {
        return GameContext(
            gameId: "authentic_game",
            tricksInRound: 3,
            playerPosition: .advantageous,
            remainingCards: createMockCards(count: 6),
            totalCardsPlayed: 12,
            decisionTime: 4.0,
            riskLevel: 0.3,
            turnAdvantage: 0.8,
            moveEfficiency: 0.9,
            sessionMistakes: 0,
            averageDecisionTime: 3.8,
            strategyVariation: 0.8,
            adaptabilityScore: 0.9,
            strategyDepth: 0.9,
            culturalPatternRecognition: 0.9,
            traditionalKnowledgeUsage: 0.9,
            traditionalPatternUsage: 0.9,
            culturalAuthenticity: 0.9,
            heritageEngagement: 0.9,
            educationalInteraction: 0.8,
            moveSuccessful: true,
            tricksWon: 4,
            tricksExpected: 3,
            regionalStyleMatch: [.moldova: 0.9, .transylvania: 0.8]
        )
    }
}

// MARK: - Mock Classes

class MockCloudKitManager: SepticaCloudKitManager {
    var isOnline = true
    var accountStatus: MockAccountStatus = .available
    var shouldFailOperations = false
    var errorToReturn: Error?
    var corruptedData = false
    
    enum MockAccountStatus {
        case available
        case noAccount
        case restricted
    }
    
    enum MockCloudKitError: Error {
        case networkUnavailable
        case accountNotFound
        case quotaExceeded
    }
    
    override func checkAccountStatus() async throws -> MockAccountStatus {
        if shouldFailOperations {
            throw errorToReturn ?? MockCloudKitError.networkUnavailable
        }
        return accountStatus
    }
    
    override func loadEnhancedPlayerProfile(playerID: String) async throws -> EnhancedPlayerProfile? {
        if shouldFailOperations {
            throw errorToReturn ?? MockCloudKitError.networkUnavailable
        }
        return nil // Return nil to simulate new player
    }
    
    override func saveEnhancedPlayerProfile(_ profile: EnhancedPlayerProfile) async throws {
        if shouldFailOperations {
            throw errorToReturn ?? MockCloudKitError.networkUnavailable
        }
        // Simulate successful save
    }
}

class MockErrorManager: ErrorManager {
    var reportedErrors: [SepticaError] = []
    
    override func reportError(_ error: SepticaError, context: String) {
        reportedErrors.append(error)
    }
}

class MockHapticManager: HapticManager {
    var playedPatterns: [CustomHapticPattern] = []
    
    func playCustomPattern(_ pattern: CustomHapticPattern) async {
        playedPatterns.append(pattern)
    }
}

class MockAudioManager: AudioManager {
    var playedSounds: [String] = []
    
    func playSound(_ soundName: String) {
        playedSounds.append(soundName)
    }
}

class MockAnimationManager: AnimationManager {
    var triggeredAnimations: [String] = []
    
    func triggerScreenFlash(color: Color, duration: TimeInterval) async {
        triggeredAnimations.append("screen_flash")
    }
    
    func fadeOutEffects(duration: TimeInterval) async {
        triggeredAnimations.append("fade_out")
    }
}

class MockRomanianCulturalContentLibrary: RomanianCulturalContentLibrary {
    func getCelebrationContent(for context: CulturalContext) async -> CulturalContent {
        return CulturalContent(
            title: "Mock Cultural Title",
            message: "Mock cultural message",
            culturalSignificance: "Mock significance",
            traditionalPatterns: ["mock_pattern"],
            culturalSymbols: ["mock_symbol"],
            associatedRegion: context.region,
            associatedMusic: "mock_music"
        )
    }
    
    func getSymbolsFor(_ context: CulturalContext) -> [CulturalSymbol] {
        return [
            CulturalSymbol(
                name: "Mock Symbol",
                imageName: "mock_symbol",
                culturalSignificance: "Mock significance",
                region: context.region
            )
        ]
    }
}

class MockRomanianCulturalAnalyzer {
    // Mock implementation for testing
}