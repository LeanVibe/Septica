//
//  OfflineSyncQueue.swift
//  Septica
//
//  Offline synchronization queue for Romanian Septica CloudKit integration
//  Handles queuing and processing of sync operations when offline
//

import Foundation
import CloudKit
import OSLog
import Combine

/// Manages offline synchronization queue for CloudKit operations
@MainActor
class OfflineSyncQueue: ObservableObject {
    
    // MARK: - Properties
    
    @Published var queuedUpdates: [QueuedSyncOperation] = []
    @Published var isProcessing = false
    
    private let logger = Logger(subsystem: "Septica", category: "OfflineSync")
    private let maxRetryAttempts = 3
    private let retryDelay: TimeInterval = 30 // seconds
    
    // MARK: - Public Methods
    
    /// Add a sync operation to the offline queue
    func enqueue(_ update: CloudKitUpdate) {
        let operation = QueuedSyncOperation(
            id: UUID(),
            update: update,
            timestamp: Date(),
            retryCount: 0
        )
        
        queuedUpdates.append(operation)
        logger.info("📱 Queued offline sync: \(update.description)")
        
        // Persist to UserDefaults for app restart recovery
        persistQueue()
    }
    
    /// Check if the queue is empty
    func isEmpty() -> Bool {
        return queuedUpdates.isEmpty
    }
    
    /// Process all queued operations
    func processAll() async throws {
        guard !self.queuedUpdates.isEmpty && !self.isProcessing else { return }
        
        self.isProcessing = true
        self.logger.info("🔄 Processing \(self.queuedUpdates.count) offline sync operations...")
        
        defer { 
            self.isProcessing = false
            self.persistQueue()
        }
        
        var processedCount = 0
        var failedOperations: [QueuedSyncOperation] = []
        
        for operation in self.queuedUpdates {
            do {
                try await processOperation(operation)
                processedCount += 1
                self.logger.info("✅ Processed offline sync: \(operation.update.description)")
                
            } catch {
                self.logger.error("❌ Failed to process offline sync: \(error.localizedDescription)")
                
                // Increment retry count and re-queue if under limit
                var updatedOperation = operation
                updatedOperation.retryCount += 1
                updatedOperation.lastRetryDate = Date()
                
                if updatedOperation.retryCount < self.maxRetryAttempts {
                    failedOperations.append(updatedOperation)
                } else {
                    self.logger.error("🚨 Abandoning sync operation after \(self.maxRetryAttempts) attempts: \(operation.update.description)")
                }
            }
        }
        
        // Update queue with failed operations only
        self.queuedUpdates = failedOperations
        
        self.logger.info("✅ Offline sync complete: \(processedCount) processed, \(failedOperations.count) remain")
    }
    
    /// Remove a specific operation from the queue
    func remove(_ operationID: UUID) {
        self.queuedUpdates.removeAll { $0.id == operationID }
        self.persistQueue()
    }
    
    /// Clear all queued operations
    func clear() {
        self.queuedUpdates.removeAll()
        self.persistQueue()
        self.logger.info("🗑️ Offline sync queue cleared")
    }
    
    // MARK: - Private Methods
    
    private func processOperation(_ operation: QueuedSyncOperation) async throws {
        // This would integrate with the main CloudKit manager
        // For now, we'll simulate the processing
        
        switch operation.update {
        case .playerProfile(let profile):
            logger.info("🔄 Processing player profile sync for \(profile.displayName)")
            // Would call CloudKitManager.syncPlayerProfile(profile)
            
        case .gameHistory(let games):
            logger.info("🔄 Processing game history sync for \(games.count) games")
            // Would call CloudKitManager.syncGameHistory(games)
            
        case .culturalProgress(let progress):
            logger.info("🔄 Processing cultural progress sync")
            // Would call CloudKitManager.syncCulturalProgress(progress)
            
        case .achievements(let achievements):
            logger.info("🔄 Processing achievements sync for \(achievements.count) items")
            // Would call CloudKitManager.syncAchievements(achievements)
        }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
    }
    
    private func persistQueue() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(self.queuedUpdates)
            UserDefaults.standard.set(data, forKey: "SepticaOfflineSyncQueue")
            
        } catch {
            self.logger.error("❌ Failed to persist offline sync queue: \(error.localizedDescription)")
        }
    }
    
    private func restoreQueue() {
        guard let data = UserDefaults.standard.data(forKey: "SepticaOfflineSyncQueue") else { return }
        
        do {
            let decoder = JSONDecoder()
            self.queuedUpdates = try decoder.decode([QueuedSyncOperation].self, from: data)
            self.logger.info("📱 Restored \(self.queuedUpdates.count) offline sync operations from storage")
            
        } catch {
            self.logger.error("❌ Failed to restore offline sync queue: \(error.localizedDescription)")
            self.queuedUpdates = []
        }
    }
    
    // MARK: - Initialization
    
    init() {
        self.restoreQueue()
        self.logger.info("🏗️ OfflineSyncQueue initialized with \(self.queuedUpdates.count) pending operations")
    }
}

// MARK: - Supporting Types

/// Represents a queued sync operation
struct QueuedSyncOperation: Codable, Identifiable {
    let id: UUID
    let update: CloudKitUpdate
    let timestamp: Date
    var retryCount: Int
    var lastRetryDate: Date?
    
    var shouldRetry: Bool {
        guard retryCount > 0, let lastRetry = lastRetryDate else { return true }
        return Date().timeIntervalSince(lastRetry) > 30 // 30 seconds between retries
    }
}

// MARK: - Network Reachability Monitor

/// Simple network reachability monitor for offline sync
class NetworkReachabilityMonitor: ObservableObject {
    @Published var isReachable = true
    
    private var completionHandler: ((Bool) -> Void)?
    private let logger = Logger(subsystem: "Septica", category: "Network")
    
    func startMonitoring(completion: @escaping (Bool) -> Void) {
        self.completionHandler = completion
        
        // Simple reachability check - in production this would use Network framework
        checkReachability()
        
        // Set up periodic checking
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkReachability()
        }
        
        logger.info("📡 Network monitoring started")
    }
    
    func stopMonitoring() {
        completionHandler = nil
        logger.info("📡 Network monitoring stopped")
    }
    
    private func checkReachability() {
        // In a real implementation, this would use Network framework
        // For now, we'll assume network is available
        let wasReachable = self.isReachable
        self.isReachable = true // Simplified for this implementation
        
        if wasReachable != self.isReachable {
            self.completionHandler?(self.isReachable)
            self.logger.info("📡 Network status changed: \(self.isReachable ? "Connected" : "Disconnected")")
        }
    }
}
