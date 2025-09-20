//
//  CloudKitSubscriptionManager.swift
//  Septica
//
//  CloudKit subscription management for real-time updates
//  Handles push notifications and live data synchronization
//

import Foundation
import CloudKit
import UserNotifications
import OSLog
import Combine

/// Manages CloudKit subscriptions for real-time data updates
@MainActor
class CloudKitSubscriptionManager: ObservableObject {
    
    // MARK: - Published State
    
    @Published var subscriptionsActive: Bool = false
    @Published var notificationsEnabled: Bool = false
    @Published var lastNotificationReceived: Date?
    @Published var activeSubscriptions: [String] = []
    
    // MARK: - Dependencies
    
    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private let logger = Logger(subsystem: "Septica", category: "CloudKitSubscriptions")
    
    // MARK: - Subscription Identifiers
    
    private struct SubscriptionIDs {
        static let playerProfile = "septica-player-profile-subscription"
        static let gameRecords = "septica-game-records-subscription"
        static let culturalProgress = "septica-cultural-progress-subscription"
        static let achievements = "septica-achievements-subscription"
        static let database = "septica-database-subscription"
    }
    
    // MARK: - Initialization
    
    init(container: CKContainer) {
        self.container = container
        self.privateDatabase = container.privateCloudDatabase
    }
    
    // MARK: - Setup Methods
    
    /// Setup all CloudKit subscriptions for Romanian cultural data
    func setupAllSubscriptions() async {
        logger.info("🔔 Setting up CloudKit subscriptions for Romanian cultural data...")
        
        do {
            await requestNotificationPermissions()
            
            // Set up database subscription for all changes
            try await setupDatabaseSubscription()
            
            // Set up specific record type subscriptions
            try await setupPlayerProfileSubscription()
            try await setupGameRecordsSubscription()
            try await setupCulturalProgressSubscription()
            try await setupAchievementsSubscription()
            
            subscriptionsActive = true
            logger.info("✅ All CloudKit subscriptions set up successfully")
            
        } catch {
            logger.error("❌ Failed to setup CloudKit subscriptions: \\(error.localizedDescription)")
            subscriptionsActive = false
        }
    }
    
    /// Request notification permissions from user
    private func requestNotificationPermissions() async {
        do {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            
            if settings.authorizationStatus == .notDetermined {
                let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                    options: [.alert, .badge, .sound]
                )
                notificationsEnabled = granted
                logger.info("📱 Notification permissions granted: \\(granted)")
            } else {
                notificationsEnabled = settings.authorizationStatus == .authorized
                logger.info("📱 Notification permissions status: \\(settings.authorizationStatus.rawValue)")
            }
            
        } catch {
            logger.error("❌ Failed to request notification permissions: \\(error.localizedDescription)")
            notificationsEnabled = false
        }
    }
    
    // MARK: - Database Subscription
    
    /// Setup database subscription for general changes
    private func setupDatabaseSubscription() async throws {
        logger.info("🔔 Setting up database subscription...")
        
        let subscription = CKDatabaseSubscription(subscriptionID: SubscriptionIDs.database)
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        notificationInfo.shouldBadge = false
        notificationInfo.alertBody = "Romanian cultural data updated"
        notificationInfo.soundName = "default"
        
        subscription.notificationInfo = notificationInfo
        
        do {
            let savedSubscription = try await privateDatabase.save(subscription)
            activeSubscriptions.append(savedSubscription.subscriptionID)
            logger.info("✅ Database subscription created: \\(savedSubscription.subscriptionID)")
        } catch CKError.serverRejectedRequest {
            // Subscription might already exist - this is fine
            logger.info("⚠️ Database subscription already exists")
        }
    }
    
    // MARK: - Record Type Subscriptions
    
    /// Setup player profile subscription
    private func setupPlayerProfileSubscription() async throws {
        logger.info("🔔 Setting up player profile subscription...")
        
        let predicate = NSPredicate(value: true) // Subscribe to all player profile changes
        let subscription = CKQuerySubscription(
            recordType: CloudKitRecordManager.RecordTypes.playerProfile,
            predicate: predicate,
            subscriptionID: SubscriptionIDs.playerProfile,
            options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
        )
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        notificationInfo.shouldBadge = false
        notificationInfo.alertBody = "Romanian player profile updated"
        notificationInfo.desiredKeys = ["displayName", "currentArena", "trophies"]
        
        subscription.notificationInfo = notificationInfo
        
        do {
            let savedSubscription = try await privateDatabase.save(subscription)
            activeSubscriptions.append(savedSubscription.subscriptionID)
            logger.info("✅ Player profile subscription created: \\(savedSubscription.subscriptionID)")
        } catch CKError.serverRejectedRequest {
            logger.info("⚠️ Player profile subscription already exists")
        }
    }
    
    /// Setup game records subscription
    private func setupGameRecordsSubscription() async throws {
        logger.info("🔔 Setting up game records subscription...")
        
        let predicate = NSPredicate(value: true)
        let subscription = CKQuerySubscription(
            recordType: CloudKitRecordManager.RecordTypes.gameRecord,
            predicate: predicate,
            subscriptionID: SubscriptionIDs.gameRecords,
            options: [.firesOnRecordCreation]
        )
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        notificationInfo.shouldBadge = false
        notificationInfo.alertBody = "New Romanian game completed"
        notificationInfo.desiredKeys = ["gameResult", "arenaAtTimeOfPlay"]
        
        subscription.notificationInfo = notificationInfo
        
        do {
            let savedSubscription = try await privateDatabase.save(subscription)
            activeSubscriptions.append(savedSubscription.subscriptionID)
            logger.info("✅ Game records subscription created: \\(savedSubscription.subscriptionID)")
        } catch CKError.serverRejectedRequest {
            logger.info("⚠️ Game records subscription already exists")
        }
    }
    
    /// Setup cultural progress subscription
    private func setupCulturalProgressSubscription() async throws {
        logger.info("🔔 Setting up cultural progress subscription...")
        
        let predicate = NSPredicate(value: true)
        let subscription = CKQuerySubscription(
            recordType: CloudKitRecordManager.RecordTypes.culturalProgress,
            predicate: predicate,
            subscriptionID: SubscriptionIDs.culturalProgress,
            options: [.firesOnRecordCreation, .firesOnRecordUpdate]
        )
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        notificationInfo.shouldBadge = false
        notificationInfo.alertBody = "Romanian cultural knowledge updated"
        notificationInfo.desiredKeys = ["folkTalesRead", "traditionalMusicKnowledge"]
        
        subscription.notificationInfo = notificationInfo
        
        do {
            let savedSubscription = try await privateDatabase.save(subscription)
            activeSubscriptions.append(savedSubscription.subscriptionID)
            logger.info("✅ Cultural progress subscription created: \\(savedSubscription.subscriptionID)")
        } catch CKError.serverRejectedRequest {
            logger.info("⚠️ Cultural progress subscription already exists")
        }
    }
    
    /// Setup achievements subscription
    private func setupAchievementsSubscription() async throws {
        logger.info("🔔 Setting up achievements subscription...")
        
        let predicate = NSPredicate(value: true)
        let subscription = CKQuerySubscription(
            recordType: CloudKitRecordManager.RecordTypes.achievement,
            predicate: predicate,
            subscriptionID: SubscriptionIDs.achievements,
            options: [.firesOnRecordCreation]
        )
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        notificationInfo.shouldBadge = true
        notificationInfo.alertBody = "New Romanian cultural achievement unlocked!"
        notificationInfo.desiredKeys = ["achievementTitle", "achievementDescription"]
        
        subscription.notificationInfo = notificationInfo
        
        do {
            let savedSubscription = try await privateDatabase.save(subscription)
            activeSubscriptions.append(savedSubscription.subscriptionID)
            logger.info("✅ Achievements subscription created: \\(savedSubscription.subscriptionID)")
        } catch CKError.serverRejectedRequest {
            logger.info("⚠️ Achievements subscription already exists")
        }
    }
    
    // MARK: - Notification Handling
    
    /// Handle remote notification from CloudKit
    func handleRemoteNotification(_ userInfo: [AnyHashable: Any]) async {
        logger.info("📡 Handling CloudKit remote notification...")
        lastNotificationReceived = Date()
        
        guard let cloudKitNotification = CKNotification(fromRemoteNotificationDictionary: userInfo) else {
            logger.error("❌ Invalid CloudKit notification format")
            return
        }
        
        switch cloudKitNotification.notificationType {
        case .query:
            await handleQueryNotification(cloudKitNotification as? CKQueryNotification)
            
        case .database:
            await handleDatabaseNotification(cloudKitNotification as? CKDatabaseNotification)
            
        case .recordZone:
            await handleRecordZoneNotification(cloudKitNotification as? CKRecordZoneNotification)
            
        @unknown default:
            logger.info("🤷‍♂️ Unknown CloudKit notification type")
        }
    }
    
    /// Handle query-based notifications (specific record changes)
    private func handleQueryNotification(_ notification: CKQueryNotification?) async {
        guard let queryNotification = notification else { return }
        
        logger.info("🎯 Query notification received for subscription: \\(queryNotification.subscriptionID ?? \"unknown\")")
        
        switch queryNotification.subscriptionID {
        case SubscriptionIDs.playerProfile:
            await handlePlayerProfileNotification(queryNotification)
            
        case SubscriptionIDs.gameRecords:
            await handleGameRecordNotification(queryNotification)
            
        case SubscriptionIDs.culturalProgress:
            await handleCulturalProgressNotification(queryNotification)
            
        case SubscriptionIDs.achievements:
            await handleAchievementNotification(queryNotification)
            
        default:
            logger.info("🤷‍♂️ Unknown subscription ID: \\(queryNotification.subscriptionID ?? \"nil\")")
        }
    }
    
    /// Handle database-level notifications
    private func handleDatabaseNotification(_ notification: CKDatabaseNotification?) async {
        guard let databaseNotification = notification else { return }
        
        logger.info("🗃️ Database notification received")
        
        // Post notification for other parts of the app to handle
        NotificationCenter.default.post(
            name: .cloudKitDatabaseChanged,
            object: databaseNotification
        )
    }
    
    /// Handle record zone notifications
    private func handleRecordZoneNotification(_ notification: CKRecordZoneNotification?) async {
        guard let zoneNotification = notification else { return }
        
        logger.info("📁 Record zone notification received for zone: \\(zoneNotification.recordZoneID?.zoneName ?? \"unknown\")")
        
        // Post notification for sync engine to handle
        NotificationCenter.default.post(
            name: .cloudKitRecordZoneChanged,
            object: zoneNotification
        )
    }
    
    // MARK: - Specific Notification Handlers
    
    private func handlePlayerProfileNotification(_ notification: CKQueryNotification) async {
        logger.info("👤 Player profile change detected")
        
        // Post notification for profile sync
        NotificationCenter.default.post(
            name: .cloudKitPlayerProfileChanged,
            object: notification
        )
    }
    
    private func handleGameRecordNotification(_ notification: CKQueryNotification) async {
        logger.info("🎮 Game record change detected")
        
        // Post notification for game history sync
        NotificationCenter.default.post(
            name: .cloudKitGameRecordChanged,
            object: notification
        )
    }
    
    private func handleCulturalProgressNotification(_ notification: CKQueryNotification) async {
        logger.info("🏛️ Cultural progress change detected")
        
        // Post notification for cultural data sync
        NotificationCenter.default.post(
            name: .cloudKitCulturalProgressChanged,
            object: notification
        )
    }
    
    private func handleAchievementNotification(_ notification: CKQueryNotification) async {
        logger.info("🏆 Achievement change detected")
        
        // Show celebration UI for new achievements
        if notification.queryNotificationReason == .recordCreated {
            await showAchievementCelebration(notification)
        }
        
        // Post notification for achievements sync
        NotificationCenter.default.post(
            name: .cloudKitAchievementChanged,
            object: notification
        )
    }
    
    /// Show achievement celebration UI
    private func showAchievementCelebration(_ notification: CKQueryNotification) async {
        guard let achievementTitle = notification.recordFields?["achievementTitle"] as? String else {
            return
        }
        
        logger.info("🎉 Showing achievement celebration for: \\(achievementTitle)")
        
        // Post notification for UI to show celebration
        NotificationCenter.default.post(
            name: .cloudKitAchievementUnlocked,
            object: achievementTitle
        )
    }
    
    // MARK: - Subscription Management
    
    /// Check which subscriptions are currently active
    func checkActiveSubscriptions() async {
        logger.info("🔍 Checking active CloudKit subscriptions...")
        
        do {
            let subscriptions = try await privateDatabase.allSubscriptions()
            activeSubscriptions = subscriptions.map { $0.subscriptionID }
            
            logger.info("✅ Found \\(subscriptions.count) active subscriptions: \\(activeSubscriptions)")
            subscriptionsActive = !activeSubscriptions.isEmpty
            
        } catch {
            logger.error("❌ Failed to fetch active subscriptions: \\(error.localizedDescription)")
            subscriptionsActive = false
        }
    }
    
    /// Remove all subscriptions (for testing or reset)
    func removeAllSubscriptions() async {
        logger.info("🗑️ Removing all CloudKit subscriptions...")
        
        do {
            let subscriptions = try await privateDatabase.allSubscriptions()
            let subscriptionIDs = subscriptions.map { $0.subscriptionID }
            
            for subscriptionID in subscriptionIDs {
                do {
                    try await privateDatabase.deleteSubscription(withID: subscriptionID)
                    logger.info("✅ Deleted subscription: \\(subscriptionID)")
                } catch {
                    logger.error("❌ Failed to delete subscription \\(subscriptionID): \\(error.localizedDescription)")
                }
            }
            
            activeSubscriptions.removeAll()
            subscriptionsActive = false
            
            logger.info("✅ All subscriptions removed")
            
        } catch {
            logger.error("❌ Failed to remove subscriptions: \\(error.localizedDescription)")
        }
    }
    
    /// Refresh all subscriptions (remove and recreate)
    func refreshAllSubscriptions() async {
        logger.info("🔄 Refreshing all CloudKit subscriptions...")
        
        await removeAllSubscriptions()
        await setupAllSubscriptions()
        
        logger.info("✅ All subscriptions refreshed")
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let cloudKitDatabaseChanged = Notification.Name("CloudKitDatabaseChanged")
    static let cloudKitRecordZoneChanged = Notification.Name("CloudKitRecordZoneChanged")
    static let cloudKitPlayerProfileChanged = Notification.Name("CloudKitPlayerProfileChanged")
    static let cloudKitGameRecordChanged = Notification.Name("CloudKitGameRecordChanged")
    static let cloudKitCulturalProgressChanged = Notification.Name("CloudKitCulturalProgressChanged")
    static let cloudKitAchievementChanged = Notification.Name("CloudKitAchievementChanged")
    static let cloudKitAchievementUnlocked = Notification.Name("CloudKitAchievementUnlocked")
}