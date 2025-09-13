//
//  SepticaCloudKitManager.swift
//  Septica
//
//  CloudKit integration for Romanian Septica with Shuffle Cats-inspired progression
//  Supports fluid card interactions, cultural achievements, and arena progression
//

import CloudKit
import Foundation
import Combine

/// Main CloudKit service manager for Septica
/// Integrates Romanian cultural progression with engaging gameplay mechanics
@MainActor
class SepticaCloudKitManager: ObservableObject {
    
    // MARK: - CloudKit Configuration
    
    private let container = CKContainer(identifier: "iCloud.dev.leanvibe.game.Septica")
    private let privateDatabase: CKDatabase
    private let sharedDatabase: CKDatabase
    
    // MARK: - Published State
    
    @Published var isAvailable: Bool = false
    @Published var accountStatus: CKAccountStatus = .couldNotDetermine
    @Published var syncInProgress: Bool = false
    @Published var lastSyncDate: Date?
    @Published var pendingUploads: Int = 0
    
    // MARK: - Romanian Cultural Arena System (Clash Royale inspired)
    
    /// Romanian-themed arena progression from villages to cities
    enum RomanianArena: Int, CaseIterable, Codable {
        case sateImarica = 0        // Imarica Village (Starting)
        case satuMihai = 1          // Mihai's Village
        case orasulBrara = 2        // Brara Town
        case orasulBacau = 3        // Bacău City
        case orasulCluj = 4         // Cluj-Napoca
        case orasulConstanta = 5    // Constanța (Black Sea)
        case orasulIasi = 6         // Iași (Cultural Center)
        case orasulTimisoara = 7    // Timișoara (Historic)
        case orasulBrasov = 8       // Brașov (Transylvania)
        case orasulSibiu = 9        // Sibiu (European Capital)
        case marealeBucuresti = 10  // Great Bucharest (Final)
        
        var displayName: String {
            switch self {
            case .sateImarica: return "Sat Imarica"
            case .satuMihai: return "Satul lui Mihai"
            case .orasulBrara: return "Orașul Brara"
            case .orasulBacau: return "Bacău"
            case .orasulCluj: return "Cluj-Napoca"
            case .orasulConstanta: return "Constanța"
            case .orasulIasi: return "Iași"
            case .orasulTimisoara: return "Timișoara"
            case .orasulBrasov: return "Brașov"
            case .orasulSibiu: return "Sibiu"
            case .marealeBucuresti: return "Marele București"
            }
        }
        
        var culturalDescription: String {
            switch self {
            case .sateImarica: return "Traditional village where Septica began"
            case .satuMihai: return "Village known for master card players"
            case .orasulBrara: return "Town of folk festivals"
            case .orasulBacau: return "City of skilled artisans"
            case .orasulCluj: return "Cultural heart of Transylvania"
            case .orasulConstanta: return "Ancient port city"
            case .orasulIasi: return "Intellectual capital of Moldova"
            case .orasulTimisoara: return "Historic revolution city"
            case .orasulBrasov: return "Gateway to Transylvania"
            case .orasulSibiu: return "European cultural capital"
            case .marealeBucuresti: return "The great capital of Romania"
            }
        }
        
        var requiredTrophies: Int {
            return rawValue * 150 // Each arena requires 150 more trophies
        }
    }
    
    // MARK: - Card Mastery System (Shuffle Cats inspired)
    
    /// Track individual card mastery and unlock visual effects
    struct CardMastery: Codable, @unchecked Sendable {
        let cardKey: String // e.g., "7_hearts", "ace_spades"
        var timesPlayed: Int = 0
        var successfulPlays: Int = 0 // Winning tricks with this card
        var specialPlays: Int = 0 // Using 7 as wild card, etc.
        var masteryLevel: Int = 0 // 0-5 mastery levels
        var unlockedEffects: [String] = [] // Visual effect identifiers
        
        var masteryProgress: Float {
            let nextLevelRequirement = masteryRequirement(for: masteryLevel + 1)
            return Float(timesPlayed) / Float(nextLevelRequirement)
        }
        
        func masteryRequirement(for level: Int) -> Int {
            switch level {
            case 1: return 25    // Bronze mastery - subtle glow
            case 2: return 100   // Silver mastery - enhanced animation
            case 3: return 300   // Gold mastery - particle effects
            case 4: return 750   // Diamond mastery - special sound
            case 5: return 1500  // Master mastery - full Romanian cultural effect
            default: return 0
            }
        }
    }
    
    // MARK: - Cultural Achievement System
    
    /// Romanian heritage achievements with educational value
    enum CulturalAchievement: String, CaseIterable, Codable {
        case septicaMaster = "septica_master"
        case sevenWild = "seven_wild_master"
        case eightSpecial = "eight_special_master"
        case folkMusicLover = "folk_music_lover"
        case traditionalColors = "traditional_colors_unlocked"
        case heritageStudent = "heritage_student"
        case culturalAmbassador = "cultural_ambassador"
        
        var title: String {
            switch self {
            case .septicaMaster: return "Maestru Septică"
            case .sevenWild: return "Stăpânul Septelor"
            case .eightSpecial: return "Maestru Opti"
            case .folkMusicLover: return "Iubitor de Folclor"
            case .traditionalColors: return "Culorile Patriei"
            case .heritageStudent: return "Student al Tradițiilor"
            case .culturalAmbassador: return "Ambasador Cultural"
            }
        }
        
        var description: String {
            switch self {
            case .septicaMaster: return "Win 100 Septica games"
            case .sevenWild: return "Use 7 as wild card 50 times"
            case .eightSpecial: return "Win tricks with 8 when count % 3 == 0"
            case .folkMusicLover: return "Play with all traditional music tracks"
            case .traditionalColors: return "Unlock all Romanian color themes"
            case .heritageStudent: return "Complete cultural education modules"
            case .culturalAmbassador: return "Teach 10 friends about Romanian culture"
            }
        }
    }
    
    // MARK: - Initialization
    
    init() {
        self.privateDatabase = container.privateCloudDatabase
        self.sharedDatabase = container.sharedCloudDatabase
        
        Task {
            await checkCloudKitAvailability()
            await setupCloudKitSubscriptions()
        }
    }
    
    // MARK: - CloudKit Availability & Setup
    
    func checkCloudKitAvailability() async {
        do {
            accountStatus = try await container.accountStatus()
            isAvailable = (accountStatus == .available)
            
            if isAvailable {
                await initializeUserRecord()
            }
        } catch {
            print("❌ CloudKit availability check failed: \(error)")
            isAvailable = false
        }
    }
    
    private func initializeUserRecord() async {
        do {
            let userRecordID = try await container.userRecordID()
            print("✅ CloudKit user record initialized: \(userRecordID)")
        } catch {
            print("❌ Failed to initialize user record: \(error)")
        }
    }
    
    private func setupCloudKitSubscriptions() async {
        // Set up database change notifications for real-time sync
        do {
            let subscription = CKDatabaseSubscription(subscriptionID: "septica-database-changes")
            
            let notificationInfo = CKSubscription.NotificationInfo()
            notificationInfo.shouldSendContentAvailable = true
            subscription.notificationInfo = notificationInfo
            
            try await privateDatabase.save(subscription)
            print("✅ CloudKit subscription established")
        } catch {
            print("❌ Failed to setup CloudKit subscription: \(error)")
        }
    }
    
    // MARK: - Data Types for CloudKit Records
    
    /// Player profile with Romanian cultural progression
    struct CloudKitPlayerProfile: Codable, @unchecked Sendable {
        let playerID: String
        var displayName: String
        var currentArena: RomanianArena
        var trophies: Int
        var totalGamesPlayed: Int
        var totalWins: Int
        var currentStreak: Int
        var longestStreak: Int
        var favoriteAIDifficulty: String
        var cardMasteries: [String: CardMastery] // Card key -> Mastery
        var achievements: [CulturalAchievement]
        var seasonalProgress: SeasonalProgress
        var preferences: GamePreferences
        var culturalEducationProgress: CulturalEducationProgress
        var lastPlayedDate: Date
        var createdDate: Date
        
        // Romanian cultural engagement metrics
        var heritageEngagementLevel: Float // 0.0 - 1.0
        var folkMusicListened: [String]
        var culturalStoriesRead: [String]
        var traditionalColorsUnlocked: [String]
    }
    
    /// Seasonal progress with Romanian celebrations
    struct SeasonalProgress: Codable, @unchecked Sendable {
        let seasonID: String
        var seasonTrophies: Int
        var seasonWins: Int
        var seasonChestsOpened: Int
        var seasonAchievements: [CulturalAchievement]
        var celebrationParticipation: [String: Bool] // Romanian holidays
        
        // Romanian seasonal celebrations
        var martisorCelebration: Bool = false    // March 1st celebration
        var dragobeteCelebration: Bool = false   // Romanian Valentine's Day
        var ziuaRomaniei: Bool = false           // Romania's National Day
    }
    
    /// Cultural education progress tracking
    struct CulturalEducationProgress: Codable, @unchecked Sendable {
        var gameRulesLearned: [String]
        var folkTalesRead: Int
        var traditionalMusicKnowledge: Int
        var cardHistoryKnowledge: Int
        var quizScores: [String: Int]
        var culturalBadges: [String]
    }
    
    /// Game preferences with cultural customization
    struct GamePreferences: Codable, @unchecked Sendable {
        var musicEnabled: Bool = true
        var selectedMusicTrack: String = "hora_unirii"
        var hapticFeedbackEnabled: Bool = true
        var ageGroup: String = "ages9to12"
        var culturalEducationEnabled: Bool = true
        var traditionalColorScheme: String = "classic_romanian"
        var cardBackStyle: String = "folk_art_patterns"
        var tableTheme: String = "wooden_traditional"
        var languagePreference: String = "romanian_english"
    }
    
    /// Individual game record for statistics and learning
    struct CloudKitGameRecord: Codable, @unchecked Sendable {
        let gameID: String
        let playerID: String
        let opponentType: String // "AI" or "Human"
        let aiDifficulty: String?
        let gameResult: String // "win", "loss"
        let finalScore: GameScore
        let gameDuration: TimeInterval
        let cardsPlayed: [CardPlayRecord]
        let culturalMomentsTriggered: [String]
        let timestamp: Date
        let arenaAtTimeOfPlay: RomanianArena
        
        // Learning and strategy analysis
        var sevenWildCardUses: Int
        var eightSpecialUses: Int
        var tricksWon: Int
        var pointsScored: Int
        var mistakesMade: [String]
        var strategicMoves: [String]
    }
    
    struct GameScore: Codable, @unchecked Sendable {
        let playerScore: Int
        let opponentScore: Int
        let tricksWon: Int
        let tricksLost: Int
    }
    
    struct CardPlayRecord: Codable, @unchecked Sendable {
        let cardKey: String
        let playOrder: Int
        let wasSuccessful: Bool
        let trickWon: Bool
        let pointsEarned: Int
        let contextNotes: String // e.g., "Used 7 as wild", "8 beat due to count rule"
    }
    
    // MARK: - Core CloudKit Operations
    
    /// Save player profile to CloudKit
    func savePlayerProfile(_ profile: CloudKitPlayerProfile) async throws {
        guard isAvailable else {
            throw CloudKitError.notAvailable
        }
        
        syncInProgress = true
        defer { syncInProgress = false }
        
        let record = CKRecord(recordType: "PlayerProfile", recordID: CKRecord.ID(recordName: profile.playerID))
        
        // Encode profile data
        let encoder = JSONEncoder()
        let profileData = try encoder.encode(profile)
        
        record["profileData"] = profileData
        record["displayName"] = profile.displayName
        record["currentArena"] = profile.currentArena.rawValue
        record["trophies"] = profile.trophies
        record["totalWins"] = profile.totalWins
        record["lastPlayedDate"] = profile.lastPlayedDate
        record["heritageEngagement"] = profile.heritageEngagementLevel
        
        try await privateDatabase.save(record)
        lastSyncDate = Date()
        
        print("✅ Player profile saved to CloudKit: \(profile.displayName) - Arena: \(profile.currentArena.displayName)")
    }
    
    /// Load player profile from CloudKit
    func loadPlayerProfile(playerID: String) async throws -> CloudKitPlayerProfile? {
        guard isAvailable else {
            throw CloudKitError.notAvailable
        }
        
        let recordID = CKRecord.ID(recordName: playerID)
        
        do {
            let record = try await privateDatabase.record(for: recordID)
            
            guard let profileData = record["profileData"] as? Data else {
                return nil
            }
            
            let decoder = JSONDecoder()
            let profile = try decoder.decode(CloudKitPlayerProfile.self, from: profileData)
            
            print("✅ Player profile loaded from CloudKit: \(profile.displayName)")
            return profile
            
        } catch CKError.unknownItem {
            // Record doesn't exist yet - return nil to create new profile
            return nil
        } catch {
            throw error
        }
    }
    
    /// Save game record with cultural analysis
    func saveGameRecord(_ record: CloudKitGameRecord) async throws {
        guard isAvailable else { return }
        
        let ckRecord = CKRecord(recordType: "GameRecord")
        
        let encoder = JSONEncoder()
        let recordData = try encoder.encode(record)
        
        ckRecord["recordData"] = recordData
        ckRecord["playerID"] = record.playerID
        ckRecord["gameResult"] = record.gameResult
        ckRecord["timestamp"] = record.timestamp
        ckRecord["arena"] = record.arenaAtTimeOfPlay.rawValue
        
        try await privateDatabase.save(ckRecord)
        
        print("✅ Game record saved: \(record.gameResult) in \(record.arenaAtTimeOfPlay.displayName)")
    }
    
    // MARK: - Error Types
    
    @MainActor
    enum CloudKitError: LocalizedError {
        case notAvailable
        case accountNotAvailable
        case syncFailed(Error)
        case recordNotFound
        case invalidData
        
        var errorDescription: String? {
            switch self {
            case .notAvailable:
                return "CloudKit is not available. Please check your iCloud settings."
            case .accountNotAvailable:
                return "iCloud account is not available. Please sign in to iCloud."
            case .syncFailed(let error):
                return "Sync failed: \(error.localizedDescription)"
            case .recordNotFound:
                return "Player profile not found."
            case .invalidData:
                return "Invalid data format."
            }
        }
    }
}

// MARK: - Romanian Cultural Extensions

extension SepticaCloudKitManager {
    
    /// Update card mastery with Romanian cultural significance
    func updateCardMastery(cardKey: String, wasSuccessful: Bool, isSpecialPlay: Bool = false) async {
        // This will be integrated with the main profile update system
        // Track individual card usage for Shuffle Cats-style progression
        print("🃏 Card mastery updated: \(cardKey) - Success: \(wasSuccessful) - Special: \(isSpecialPlay)")
    }
    
    /// Progress through Romanian arenas based on trophies
    func checkArenaProgression(currentTrophies: Int) -> RomanianArena {
        return RomanianArena.allCases.last { arena in
            currentTrophies >= arena.requiredTrophies
        } ?? .sateImarica
    }
    
    /// Unlock cultural achievement
    func unlockCulturalAchievement(_ achievement: CulturalAchievement) async {
        print("🏆 Cultural achievement unlocked: \(achievement.title)")
        // This will trigger UI celebration and educational content
    }
}