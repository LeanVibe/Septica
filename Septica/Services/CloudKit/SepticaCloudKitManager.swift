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