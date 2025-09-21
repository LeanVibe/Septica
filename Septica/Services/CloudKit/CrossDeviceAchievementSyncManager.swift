//
//  CrossDeviceAchievementSyncManager.swift
//  Septica
//
//  Cross-Device Achievement Synchronization with CloudKit
//  Handles seamless achievement progress sync across iPhone/iPad with conflict resolution
//

import Foundation
import CloudKit
import Combine
import Network

/// Cross-Device Achievement Synchronization Manager
/// Provides seamless CloudKit integration with intelligent conflict resolution for achievements
@MainActor
class CrossDeviceAchievementSyncManager: ObservableObject {
    
    // MARK: - Dependencies
    
    private let cloudKitManager: SepticaCloudKitManager
    private let achievementManager: RomanianCulturalAchievementManager
    private let profileManager: EnhancedPlayerProfileManager
    private let errorManager: ErrorManager?
    
    // MARK: - Published Sync State
    
    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncDate: Date?
    @Published var pendingUploads: [SyncItem] = []
    @Published var conflictedItems: [ConflictedAchievement] = []
    @Published var crossDeviceProgress: CrossDeviceProgress
    @Published var connectedDevices: [ConnectedDevice] = []
    
    // MARK: - Network and Connectivity
    
    @Published var isOnline: Bool = true
    @Published var isCloudKitAvailable: Bool = true
    private let networkMonitor = NWPathMonitor()
    
    // MARK: - Sync Configuration
    
    private let syncConfiguration: SyncConfiguration
    private var syncTimer: Timer?
    private var offlineQueue: OfflineOperationQueue
    
    // MARK: - Sync State Management
    
    private var lastSuccessfulSync: Date?
    private var currentSyncOperation: SyncOperation?
    private var pendingOperations: [PendingOperation] = []
    private var cancellables = Set<AnyCancellable>()
    
    enum SyncStatus {
        case idle
        case syncing
        case offline
        case error(String)
        case conflictDetected
        case uploadingProgress
        case downloadingUpdates
    }
    
    // MARK: - Initialization
    
    init(
        cloudKitManager: SepticaCloudKitManager,
        achievementManager: RomanianCulturalAchievementManager,
        profileManager: EnhancedPlayerProfileManager,
        errorManager: ErrorManager?
    ) {
        self.cloudKitManager = cloudKitManager
        self.achievementManager = achievementManager
        self.profileManager = profileManager
        self.errorManager = errorManager
        
        self.syncConfiguration = SyncConfiguration()
        self.offlineQueue = OfflineOperationQueue()
        self.crossDeviceProgress = CrossDeviceProgress()
        
        setupNetworkMonitoring()
        setupAchievementSubscriptions()
        
        Task {
            await initializeSync()
            await startPeriodicSync()
        }
    }
    
    // MARK: - Network Monitoring
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isOnline = path.status == .satisfied
                if path.status == .satisfied {
                    Task { @MainActor in
                        await self?.processPendingOperations()
                    }
                }
            }
        }
        
        let queue = DispatchQueue(label: "NetworkMonitor")
        networkMonitor.start(queue: queue)
    }
    
    private func setupAchievementSubscriptions() {
        // Listen for achievement progress updates
        achievementManager.$achievementProgress
            .dropFirst()
            .sink { [weak self] progress in
                Task { @MainActor in
                    await self?.queueAchievementProgressSync(progress)
                }
            }
            .store(in: &cancellables)
        
        // Listen for achievement unlocks
        NotificationCenter.default.publisher(for: .achievementUnlocked)
            .compactMap { $0.object as? RomanianAchievement }
            .sink { [weak self] achievement in
                Task { @MainActor in
                    await self?.queueAchievementUnlockSync(achievement)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Sync Initialization
    
    private func initializeSync() async {
        // Check CloudKit availability
        await checkCloudKitAvailability()
        
        if isCloudKitAvailable && isOnline {
            await performInitialSync()
        } else {
            syncStatus = .offline
            await loadOfflineData()
        }
    }
    
    private func checkCloudKitAvailability() async {
        do {
            let status = try await cloudKitManager.checkAccountStatus()
            isCloudKitAvailable = (status == .available)
        } catch {
            isCloudKitAvailable = false
            syncStatus = .error("CloudKit unavailable: \(error.localizedDescription)")
        }
    }
    
    private func performInitialSync() async {
        syncStatus = .syncing
        
        do {
            // Download latest achievement data from CloudKit
            await downloadServerAchievements()
            
            // Upload any local achievements that aren't on server
            await uploadLocalAchievements()
            
            // Resolve any conflicts
            await resolveAchievementConflicts()
            
            // Update connected devices list
            await updateConnectedDevices()
            
            syncStatus = .idle
            lastSyncDate = Date()
            lastSuccessfulSync = Date()
            
        } catch {
            syncStatus = .error("Initial sync failed: \(error.localizedDescription)")
            errorManager?.reportError(
                .networkError(message: "Achievement sync failed: \(error.localizedDescription)"),
                context: "CrossDeviceAchievementSyncManager.performInitialSync"
            )
        }
    }
    
    // MARK: - Achievement Progress Synchronization
    
    private func queueAchievementProgressSync(_ progress: [UUID: AchievementProgress]) async {
        for (achievementId, progressData) in progress {
            let syncItem = SyncItem(
                id: UUID(),
                type: .achievementProgress,
                achievementId: achievementId,
                data: progressData,
                timestamp: Date(),
                deviceId: getCurrentDeviceId(),
                priority: .normal
            )
            
            if isOnline && isCloudKitAvailable {
                await uploadSyncItem(syncItem)
            } else {
                pendingUploads.append(syncItem)
                await offlineQueue.addOperation(.upload(syncItem))
            }
        }
    }
    
    private func queueAchievementUnlockSync(_ achievement: RomanianAchievement) async {
        let syncItem = SyncItem(
            id: UUID(),
            type: .achievementUnlock,
            achievementId: achievement.id,
            data: AchievementUnlockData(
                achievementId: achievement.id,
                unlockedAt: Date(),
                deviceId: getCurrentDeviceId()
            ),
            timestamp: Date(),
            deviceId: getCurrentDeviceId(),
            priority: .high
        )
        
        if isOnline && isCloudKitAvailable {
            await uploadSyncItem(syncItem)
        } else {
            pendingUploads.append(syncItem)
            await offlineQueue.addOperation(.upload(syncItem))
        }
    }
    
    // MARK: - CloudKit Upload/Download Operations
    
    private func uploadSyncItem(_ item: SyncItem) async {
        do {
            syncStatus = .uploadingProgress
            
            let record = createCloudKitRecord(from: item)
            try await cloudKitManager.save(record: record)
            
            // Remove from pending uploads
            pendingUploads.removeAll { $0.id == item.id }
            
            // Update cross-device progress
            await updateCrossDeviceProgress(item)
            
        } catch {
            // Re-queue for later if upload fails
            if !pendingUploads.contains(where: { $0.id == item.id }) {
                pendingUploads.append(item)
            }
            
            errorManager?.reportError(
                .networkError(message: "Achievement upload failed: \(error.localizedDescription)"),
                context: "CrossDeviceAchievementSyncManager.uploadSyncItem"
            )
        }
    }
    
    private func downloadServerAchievements() async {
        do {
            syncStatus = .downloadingUpdates
            
            let playerID = await profileManager.currentProfile?.playerID ?? ""
            let serverRecords = try await cloudKitManager.fetchAchievementRecords(for: playerID)
            
            await processServerAchievements(serverRecords)
            
        } catch {
            syncStatus = .error("Download failed: \(error.localizedDescription)")
        }
    }
    
    private func processServerAchievements(_ records: [CKRecord]) async {
        for record in records {
            if let syncItem = createSyncItem(from: record) {
                await mergeSyncItem(syncItem)
            }
        }
    }
    
    // MARK: - Conflict Resolution
    
    private func resolveAchievementConflicts() async {
        guard !conflictedItems.isEmpty else { return }
        
        syncStatus = .conflictDetected
        
        for conflictedAchievement in conflictedItems {
            let resolution = await determineConflictResolution(conflictedAchievement)
            await applyConflictResolution(conflictedAchievement, resolution: resolution)
        }
        
        conflictedItems.removeAll()
        syncStatus = .idle
    }
    
    private func determineConflictResolution(_ conflict: ConflictedAchievement) async -> ConflictResolution {
        // Intelligent conflict resolution based on Romanian cultural achievement principles
        switch conflict.type {
        case .progressMismatch:
            // For progress conflicts, take the higher value (more cultural progress is better)
            return conflict.localProgress.currentValue >= conflict.serverProgress.currentValue 
                ? .useLocal : .useServer
                
        case .unlockTimestamp:
            // For unlock conflicts, take the earlier timestamp (first to achieve)
            return conflict.localProgress.completedAt ?? Date.distantFuture <= 
                   conflict.serverProgress.completedAt ?? Date.distantFuture 
                ? .useLocal : .useServer
                
        case .culturalData:
            // For cultural data conflicts, prefer the more authentic or complete version
            return await resolveCulturalDataConflict(conflict)
            
        case .deviceSpecific:
            // For device-specific conflicts, merge intelligently
            return .merge
        }
    }
    
    private func resolveCulturalDataConflict(_ conflict: ConflictedAchievement) async -> ConflictResolution {
        // Analyze cultural authenticity and completeness
        let localAuthenticity = calculateCulturalAuthenticity(conflict.localProgress)
        let serverAuthenticity = calculateCulturalAuthenticity(conflict.serverProgress)
        
        if localAuthenticity > serverAuthenticity {
            return .useLocal
        } else if serverAuthenticity > localAuthenticity {
            return .useServer
        } else {
            return .merge
        }
    }
    
    private func calculateCulturalAuthenticity(_ progress: AchievementProgress) -> Float {
        // Calculate authenticity based on milestone rewards claimed and cultural engagement
        var authenticity: Float = 0.0
        
        // Base authenticity from completion
        if progress.isCompleted {
            authenticity += 0.5
        }
        
        // Additional authenticity from milestone rewards
        authenticity += Float(progress.milestoneRewards.filter { $0.isClaimed }.count) * 0.1
        
        // Time-based authenticity (longer engagement = more authentic)
        let daysSinceStart = Date().timeIntervalSince(progress.lastUpdated) / (24 * 3600)
        authenticity += min(Float(daysSinceStart) * 0.01, 0.2)
        
        return min(authenticity, 1.0)
    }
    
    private func applyConflictResolution(_ conflict: ConflictedAchievement, resolution: ConflictResolution) async {
        switch resolution {
        case .useLocal:
            await uploadSyncItem(createSyncItem(from: conflict.localProgress, achievementId: conflict.achievementId))
            
        case .useServer:
            await achievementManager.updateProgress(conflict.achievementId, with: conflict.serverProgress)
            
        case .merge:
            let mergedProgress = mergeAchievementProgress(
                local: conflict.localProgress,
                server: conflict.serverProgress
            )
            await achievementManager.updateProgress(conflict.achievementId, with: mergedProgress)
            await uploadSyncItem(createSyncItem(from: mergedProgress, achievementId: conflict.achievementId))
        }
    }
    
    private func mergeAchievementProgress(local: AchievementProgress, server: AchievementProgress) -> AchievementProgress {
        var merged = local
        
        // Take maximum progress value
        merged.currentValue = max(local.currentValue, server.currentValue)
        
        // Take earlier start date and later update date
        merged.lastUpdated = max(local.lastUpdated, server.lastUpdated)
        
        // Merge milestone rewards (union of claimed rewards)
        let localClaimed = Set(local.milestoneRewards.filter { $0.isClaimed }.map { $0.percentage })
        let serverClaimed = Set(server.milestoneRewards.filter { $0.isClaimed }.map { $0.percentage })
        let allClaimed = localClaimed.union(serverClaimed)
        
        merged.milestoneRewards = local.milestoneRewards.map { reward in
            var updatedReward = reward
            if allClaimed.contains(reward.percentage) {
                updatedReward = MilestoneReward(
                    percentage: reward.percentage,
                    rewardType: reward.rewardType,
                    isClaimed: true,
                    claimedAt: reward.claimedAt ?? Date()
                )
            }
            return updatedReward
        }
        
        // Update completion status
        if let achievement = await achievementManager.getAchievement(id: merged.achievementId) {
            if merged.currentValue >= achievement.targetValue && !merged.isCompleted {
                merged.isCompleted = true
                merged.completedAt = Date()
            }
        }
        
        return merged
    }
    
    // MARK: - Offline Operations
    
    private func processPendingOperations() async {
        guard isOnline && isCloudKitAvailable else { return }
        
        let operations = await offlineQueue.getAllOperations()
        
        for operation in operations {
            switch operation {
            case .upload(let syncItem):
                await uploadSyncItem(syncItem)
                await offlineQueue.removeOperation(operation)
                
            case .download(let achievementId):
                await downloadSpecificAchievement(achievementId)
                await offlineQueue.removeOperation(operation)
                
            case .resolve(let conflict):
                await applyConflictResolution(conflict.achievement, resolution: conflict.resolution)
                await offlineQueue.removeOperation(operation)
            }
        }
    }
    
    private func downloadSpecificAchievement(_ achievementId: UUID) async {
        do {
            let playerID = await profileManager.currentProfile?.playerID ?? ""
            if let record = try await cloudKitManager.fetchAchievementRecord(
                achievementId: achievementId,
                playerID: playerID
            ) {
                if let syncItem = createSyncItem(from: record) {
                    await mergeSyncItem(syncItem)
                }
            }
        } catch {
            errorManager?.reportError(
                .networkError(message: "Achievement download failed: \(error.localizedDescription)"),
                context: "CrossDeviceAchievementSyncManager.downloadSpecificAchievement"
            )
        }
    }
    
    // MARK: - Periodic Sync
    
    private func startPeriodicSync() async {
        syncTimer = Timer.scheduledTimer(withTimeInterval: syncConfiguration.syncInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.performPeriodicSync()
            }
        }
    }
    
    private func performPeriodicSync() async {
        guard syncStatus == .idle, isOnline, isCloudKitAvailable else { return }
        
        // Check if enough time has passed since last sync
        if let lastSync = lastSuccessfulSync,
           Date().timeIntervalSince(lastSync) < syncConfiguration.minimumSyncInterval {
            return
        }
        
        await downloadServerAchievements()
        
        // Upload any pending items
        for item in pendingUploads {
            await uploadSyncItem(item)
        }
    }
    
    // MARK: - Device Management
    
    private func updateConnectedDevices() async {
        do {
            let playerID = await profileManager.currentProfile?.playerID ?? ""
            let deviceRecords = try await cloudKitManager.fetchDeviceRecords(for: playerID)
            
            connectedDevices = deviceRecords.compactMap { record in
                ConnectedDevice(from: record)
            }
            
        } catch {
            errorManager?.reportError(
                .networkError(message: "Device update failed: \(error.localizedDescription)"),
                context: "CrossDeviceAchievementSyncManager.updateConnectedDevices"
            )
        }
    }
    
    // MARK: - Manual Sync Operations
    
    func forceSyncAllAchievements() async {
        syncStatus = .syncing
        
        await downloadServerAchievements()
        await uploadLocalAchievements()
        await resolveAchievementConflicts()
        
        syncStatus = .idle
        lastSyncDate = Date()
    }
    
    func syncSpecificAchievement(_ achievementId: UUID) async {
        if isOnline && isCloudKitAvailable {
            await downloadSpecificAchievement(achievementId)
            
            // Upload local version if it exists
            if let localProgress = achievementManager.achievementProgress[achievementId] {
                let syncItem = createSyncItem(from: localProgress, achievementId: achievementId)
                await uploadSyncItem(syncItem)
            }
        }
    }
    
    func resolveConflictManually(_ conflict: ConflictedAchievement, resolution: ConflictResolution) async {
        await applyConflictResolution(conflict, resolution: resolution)
        conflictedItems.removeAll { $0.achievementId == conflict.achievementId }
    }
    
    // MARK: - Helper Methods
    
    private func uploadLocalAchievements() async {
        let localProgress = achievementManager.achievementProgress
        
        for (achievementId, progress) in localProgress {
            let syncItem = createSyncItem(from: progress, achievementId: achievementId)
            await uploadSyncItem(syncItem)
        }
    }
    
    private func mergeSyncItem(_ syncItem: SyncItem) async {
        let achievementId = syncItem.achievementId
        let localProgress = achievementManager.achievementProgress[achievementId]
        
        switch syncItem.type {
        case .achievementProgress:
            if let serverProgress = syncItem.data as? AchievementProgress {
                if let local = localProgress {
                    // Check for conflicts
                    if hasProgressConflict(local: local, server: serverProgress) {
                        let conflict = ConflictedAchievement(
                            achievementId: achievementId,
                            type: .progressMismatch,
                            localProgress: local,
                            serverProgress: serverProgress,
                            conflictReason: "Progress values differ between devices"
                        )
                        conflictedItems.append(conflict)
                    } else {
                        // No conflict, merge safely
                        let merged = mergeAchievementProgress(local: local, server: serverProgress)
                        await achievementManager.updateProgress(achievementId, with: merged)
                    }
                } else {
                    // No local progress, use server version
                    await achievementManager.updateProgress(achievementId, with: serverProgress)
                }
            }
            
        case .achievementUnlock:
            if let unlockData = syncItem.data as? AchievementUnlockData {
                await achievementManager.processAchievementUnlock(unlockData)
            }
        }
    }
    
    private func hasProgressConflict(local: AchievementProgress, server: AchievementProgress) -> Bool {
        // Check for significant differences that indicate a conflict
        let valueDifference = abs(local.currentValue - server.currentValue)
        let timeDifference = abs(local.lastUpdated.timeIntervalSince(server.lastUpdated))
        
        // Conflict if values differ by more than 1 and updates are close in time
        return valueDifference > 1 && timeDifference < 300 // 5 minutes
    }
    
    private func createCloudKitRecord(from syncItem: SyncItem) -> CKRecord {
        let recordID = CKRecord.ID(recordName: syncItem.id.uuidString)
        let record = CKRecord(recordType: "AchievementSync", recordID: recordID)
        
        record["achievementId"] = syncItem.achievementId.uuidString
        record["type"] = syncItem.type.rawValue
        record["timestamp"] = syncItem.timestamp
        record["deviceId"] = syncItem.deviceId
        record["priority"] = syncItem.priority.rawValue
        
        // Encode data
        if let data = try? JSONEncoder().encode(syncItem.data as? Codable) {
            record["data"] = data
        }
        
        return record
    }
    
    private func createSyncItem(from record: CKRecord) -> SyncItem? {
        guard let achievementIdString = record["achievementId"] as? String,
              let achievementId = UUID(uuidString: achievementIdString),
              let typeString = record["type"] as? String,
              let type = SyncItemType(rawValue: typeString),
              let timestamp = record["timestamp"] as? Date,
              let deviceId = record["deviceId"] as? String,
              let priorityString = record["priority"] as? String,
              let priority = SyncPriority(rawValue: priorityString),
              let data = record["data"] as? Data else {
            return nil
        }
        
        // Decode data based on type
        var decodedData: Any?
        switch type {
        case .achievementProgress:
            decodedData = try? JSONDecoder().decode(AchievementProgress.self, from: data)
        case .achievementUnlock:
            decodedData = try? JSONDecoder().decode(AchievementUnlockData.self, from: data)
        }
        
        guard let decodedData = decodedData else { return nil }
        
        return SyncItem(
            id: UUID(uuidString: record.recordID.recordName) ?? UUID(),
            type: type,
            achievementId: achievementId,
            data: decodedData,
            timestamp: timestamp,
            deviceId: deviceId,
            priority: priority
        )
    }
    
    private func createSyncItem(from progress: AchievementProgress, achievementId: UUID) -> SyncItem {
        return SyncItem(
            id: UUID(),
            type: .achievementProgress,
            achievementId: achievementId,
            data: progress,
            timestamp: Date(),
            deviceId: getCurrentDeviceId(),
            priority: .normal
        )
    }
    
    private func updateCrossDeviceProgress(_ syncItem: SyncItem) async {
        crossDeviceProgress.lastCrossDeviceSync = Date()
        
        switch syncItem.type {
        case .achievementProgress:
            // Update shared progress tracking
            if let progress = syncItem.data as? AchievementProgress {
                crossDeviceProgress.sharedCulturalProgress += Float(progress.currentValue) * 0.01
            }
            
        case .achievementUnlock:
            // Add to shared achievements
            if !crossDeviceProgress.sharedAchievements.contains(syncItem.achievementId) {
                crossDeviceProgress.sharedAchievements.append(syncItem.achievementId)
            }
        }
    }
    
    private func getCurrentDeviceId() -> String {
        return UIDevice.current.identifierForVendor?.uuidString ?? "unknown_device"
    }
    
    private func loadOfflineData() async {
        // Load locally cached achievement data when offline
        // This would restore from local storage
    }
    
    deinit {
        syncTimer?.invalidate()
        networkMonitor.cancel()
    }
}

// MARK: - Supporting Data Models

struct SyncConfiguration {
    let syncInterval: TimeInterval = 300 // 5 minutes
    let minimumSyncInterval: TimeInterval = 60 // 1 minute
    let maxRetryAttempts: Int = 3
    let conflictResolutionTimeout: TimeInterval = 30
    let batchSize: Int = 50
}

struct SyncItem: Identifiable, Codable {
    let id: UUID
    let type: SyncItemType
    let achievementId: UUID
    let data: Any // This will be encoded/decoded based on type
    let timestamp: Date
    let deviceId: String
    let priority: SyncPriority
    
    private enum CodingKeys: CodingKey {
        case id, type, achievementId, timestamp, deviceId, priority
    }
    
    init(
        id: UUID,
        type: SyncItemType,
        achievementId: UUID,
        data: Any,
        timestamp: Date,
        deviceId: String,
        priority: SyncPriority
    ) {
        self.id = id
        self.type = type
        self.achievementId = achievementId
        self.data = data
        self.timestamp = timestamp
        self.deviceId = deviceId
        self.priority = priority
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.type = try container.decode(SyncItemType.self, forKey: .type)
        self.achievementId = try container.decode(UUID.self, forKey: .achievementId)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        self.deviceId = try container.decode(String.self, forKey: .deviceId)
        self.priority = try container.decode(SyncPriority.self, forKey: .priority)
        self.data = "placeholder" // Will be handled separately
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(achievementId, forKey: .achievementId)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(deviceId, forKey: .deviceId)
        try container.encode(priority, forKey: .priority)
    }
}

enum SyncItemType: String, Codable {
    case achievementProgress = "achievement_progress"
    case achievementUnlock = "achievement_unlock"
}

enum SyncPriority: String, Codable {
    case low = "low"
    case normal = "normal"
    case high = "high"
}

struct ConflictedAchievement: Identifiable {
    let id = UUID()
    let achievementId: UUID
    let type: ConflictType
    let localProgress: AchievementProgress
    let serverProgress: AchievementProgress
    let conflictReason: String
    
    enum ConflictType {
        case progressMismatch
        case unlockTimestamp
        case culturalData
        case deviceSpecific
    }
}

enum ConflictResolution {
    case useLocal
    case useServer
    case merge
}

struct ConnectedDevice: Identifiable {
    let id: String
    let name: String
    let type: String
    let lastSeen: Date
    let isCurrentDevice: Bool
    
    init?(from record: CKRecord) {
        guard let deviceId = record["deviceId"] as? String,
              let deviceName = record["deviceName"] as? String,
              let deviceType = record["deviceType"] as? String,
              let lastSeen = record["lastSeen"] as? Date else {
            return nil
        }
        
        self.id = deviceId
        self.name = deviceName
        self.type = deviceType
        self.lastSeen = lastSeen
        self.isCurrentDevice = deviceId == UIDevice.current.identifierForVendor?.uuidString
    }
}

struct AchievementUnlockData: Codable {
    let achievementId: UUID
    let unlockedAt: Date
    let deviceId: String
}

class OfflineOperationQueue {
    private var operations: [OfflineOperation] = []
    
    func addOperation(_ operation: OfflineOperation) async {
        operations.append(operation)
        saveToStorage()
    }
    
    func removeOperation(_ operation: OfflineOperation) async {
        operations.removeAll { $0.id == operation.id }
        saveToStorage()
    }
    
    func getAllOperations() async -> [OfflineOperation] {
        return operations
    }
    
    private func saveToStorage() {
        // Save operations to local storage for persistence
    }
}

struct OfflineOperation: Identifiable {
    let id = UUID()
    let type: OperationType
    
    enum OperationType {
        case upload(SyncItem)
        case download(UUID)
        case resolve(ConflictResolution: (achievement: ConflictedAchievement, resolution: ConflictResolution))
    }
}

struct PendingOperation {
    let id: UUID
    let type: OperationType
    let retryCount: Int
    let lastAttempt: Date
    
    enum OperationType {
        case sync
        case upload
        case download
        case resolve
    }
}