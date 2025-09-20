//
//  CloudKitErrorHandler.swift
//  Septica
//
//  Comprehensive error handling and conflict resolution for CloudKit operations
//  Implements intelligent retry logic and user-friendly error messages
//

import Foundation
import CloudKit
import OSLog
import Combine

/// Comprehensive error handling and recovery system for CloudKit operations
@MainActor
class CloudKitErrorHandler: ObservableObject {
    
    // MARK: - Published State
    
    @Published var currentErrors: [CloudKitErrorInfo] = []
    @Published var retryOperations: [String: CloudKitRetryOperation] = [:]
    @Published var isRecovering: Bool = false
    @Published var lastRecoveryAttempt: Date?
    @Published var conflictsAwaitingResolution: [CloudKitConflictInfo] = []
    
    // MARK: - Dependencies
    
    private let logger = Logger(subsystem: "Septica", category: "CloudKitErrorHandler")
    private var retryTimers: [String: Timer] = [:]
    
    // MARK: - Error Recovery Configuration
    
    private struct RetryConfiguration {
        static let maxRetries = 3
        static let baseRetryDelay: TimeInterval = 2.0 // 2 seconds
        static let maxRetryDelay: TimeInterval = 60.0 // 1 minute
        static let exponentialBackoffMultiplier = 2.0
        static let jitterRange: ClosedRange<Double> = 0.8...1.2
    }
    
    // MARK: - Error Analysis and Handling
    
    /// Analyze and handle CloudKit errors with intelligent recovery strategies
    func handleCloudKitError(_ error: Error, operation: String) async -> CloudKitErrorRecoveryAction {
        logger.error("🚨 CloudKit error in operation '\(operation)': \(error.localizedDescription)")
        
        let errorInfo = CloudKitErrorInfo(
            id: UUID().uuidString,
            operation: operation,
            error: error,
            timestamp: Date(),
            attemptCount: 0
        )
        
        currentErrors.append(errorInfo)
        
        // Analyze specific CloudKit errors
        if let ckError = error as? CKError {
            return await handleCKError(ckError, errorInfo: errorInfo)
        } else {
            return await handleGenericError(error, errorInfo: errorInfo)
        }
    }
    
    /// Handle specific CKError types with targeted recovery strategies
    private func handleCKError(_ ckError: CKError, errorInfo: CloudKitErrorInfo) async -> CloudKitErrorRecoveryAction {
        switch ckError.code {
        case .networkUnavailable, .networkFailure:
            return await handleNetworkError(ckError, errorInfo: errorInfo)
            
        case .quotaExceeded:
            return await handleQuotaExceededError(ckError, errorInfo: errorInfo)
            
        case .zoneBusy, .serviceUnavailable:
            return await handleServiceUnavailableError(ckError, errorInfo: errorInfo)
            
        case .requestRateLimited:
            return await handleRateLimitError(ckError, errorInfo: errorInfo)
            
        case .partialFailure:
            return await handlePartialFailureError(ckError, errorInfo: errorInfo)
            
        case .serverRecordChanged:
            return await handleConflictError(ckError, errorInfo: errorInfo)
            
        case .unknownItem:
            return await handleUnknownItemError(ckError, errorInfo: errorInfo)
            
        case .notAuthenticated:
            return await handleAuthenticationError(ckError, errorInfo: errorInfo)
            
        case .permissionFailure:
            return await handlePermissionError(ckError, errorInfo: errorInfo)
            
        case .invalidArguments:
            return await handleInvalidArgumentsError(ckError, errorInfo: errorInfo)
            
        case .incompatibleVersion:
            return await handleVersionError(ckError, errorInfo: errorInfo)
            
        case .badContainer, .badDatabase:
            return await handleContainerError(ckError, errorInfo: errorInfo)
            
        case .constraintViolation:
            return await handleConstraintViolationError(ckError, errorInfo: errorInfo)
            
        default:
            logger.warning("⚠️ Unhandled CKError code: \(ckError.code.rawValue)")
            return .showError(createUserFriendlyMessage(for: ckError))
        }
    }
    
    // MARK: - Specific Error Handlers
    
    private func handleNetworkError(_ error: CKError, errorInfo: CloudKitErrorInfo) async -> CloudKitErrorRecoveryAction {
        logger.info("🌐 Network error detected - scheduling retry with exponential backoff")
        
        if errorInfo.attemptCount < RetryConfiguration.maxRetries {
            let delay = calculateRetryDelay(attemptCount: errorInfo.attemptCount)
            await scheduleRetry(for: errorInfo, delay: delay)
            return .retryWithDelay(delay)
        } else {
            return .showError("Network connection unavailable. Romanian cultural data will sync when connection is restored.")
        }
    }
    
    private func handleQuotaExceededError(_ error: CKError, errorInfo: CloudKitErrorInfo) async -> CloudKitErrorRecoveryAction {
        logger.warning("💾 CloudKit quota exceeded")
        
        // Suggest data cleanup or upgrade to paid iCloud plan
        return .showError("iCloud storage is full. Please free up space or upgrade your iCloud plan to continue syncing Romanian cultural progress.")
    }
    
    private func handleServiceUnavailableError(_ error: CKError, errorInfo: CloudKitErrorInfo) async -> CloudKitErrorRecoveryAction {
        logger.info("⏰ CloudKit service temporarily unavailable")
        
        let retryAfter = error.retryAfterSeconds ?? 30.0
        
        if errorInfo.attemptCount < RetryConfiguration.maxRetries {
            await scheduleRetry(for: errorInfo, delay: retryAfter)
            return .retryWithDelay(retryAfter)
        } else {
            return .showError("CloudKit service is temporarily unavailable. Romanian cultural data will sync automatically when service resumes.")
        }
    }
    
    private func handleRateLimitError(_ error: CKError, errorInfo: CloudKitErrorInfo) async -> CloudKitErrorRecoveryAction {
        logger.info("🚦 Rate limit exceeded - backing off")
        
        let retryAfter = error.retryAfterSeconds ?? 60.0
        
        if errorInfo.attemptCount < RetryConfiguration.maxRetries {
            await scheduleRetry(for: errorInfo, delay: retryAfter)
            return .retryWithDelay(retryAfter)
        } else {
            return .showError("Too many requests to CloudKit. Romanian cultural data sync will resume shortly.")
        }
    }
    
    private func handlePartialFailureError(_ error: CKError, errorInfo: CloudKitErrorInfo) async -> CloudKitErrorRecoveryAction {
        logger.info("⚠️ Partial failure in CloudKit operation")
        
        // Extract individual errors from partial failure
        if let partialErrors = error.partialErrorsByItemID {
            var successfulItems: [String] = []
            var failedItems: [String: Error] = [:]
            
            for (itemID, itemError) in partialErrors {
                let itemIDString = itemID.recordName
                failedItems[itemIDString] = itemError
                
                // Handle individual item errors
                _ = await handleCloudKitError(itemError, operation: "\(errorInfo.operation)_item_\(itemIDString)")
            }
            
            logger.info("📊 Partial failure: \(failedItems.count) items failed")
            return .partialSuccess(successfulItems, failedItems)
        }
        
        return .showError("Some Romanian cultural data failed to sync. Retrying failed items...")
    }
    
    private func handleConflictError(_ error: CKError, errorInfo: CloudKitErrorInfo) async -> CloudKitErrorRecoveryAction {
        logger.info("⚔️ Record conflict detected - initiating conflict resolution")
        
        guard let serverRecord = error.serverRecord,
              let clientRecord = error.clientRecord else {
            return .showError("Data conflict detected but unable to resolve automatically.")
        }
        
        let conflictInfo = CloudKitConflictInfo(
            id: UUID().uuidString,
            recordType: serverRecord.recordType,
            recordID: serverRecord.recordID,
            serverRecord: serverRecord,
            clientRecord: clientRecord,
            conflictType: determineConflictType(serverRecord: serverRecord, clientRecord: clientRecord),
            culturalImpact: assessCulturalImpact(serverRecord: serverRecord, clientRecord: clientRecord),
            timestamp: Date()
        )
        
        conflictsAwaitingResolution.append(conflictInfo)
        
        // Attempt automatic resolution for low-impact conflicts
        if conflictInfo.culturalImpact.canAutoResolve {
            let resolvedRecord = await attemptAutomaticConflictResolution(conflictInfo)
            if resolvedRecord != nil {
                return .conflictResolved(resolvedRecord!)
            }
        }
        
        return .requiresUserIntervention(conflictInfo)
    }
    
    private func handleUnknownItemError(_ error: CKError, errorInfo: CloudKitErrorInfo) async -> CloudKitErrorRecoveryAction {
        logger.info("🤷‍♂️ Unknown item error - record may have been deleted")
        
        // This is often expected (e.g., first-time user, deleted records)
        return .ignore // Handle gracefully without user intervention
    }
    
    private func handleAuthenticationError(_ error: CKError, errorInfo: CloudKitErrorInfo) async -> CloudKitErrorRecoveryAction {
        logger.warning("🔐 Authentication error - user may need to sign in to iCloud")
        
        return .showError("Please sign in to iCloud in Settings to sync your Romanian cultural progress across devices.")
    }
    
    private func handlePermissionError(_ error: CKError, errorInfo: CloudKitErrorInfo) async -> CloudKitErrorRecoveryAction {
        logger.warning("🚫 Permission error - user may have disabled CloudKit")
        
        return .showError("CloudKit access is disabled. Please enable iCloud for this app in Settings to sync Romanian cultural data.")
    }
    
    private func handleInvalidArgumentsError(_ error: CKError, errorInfo: CloudKitErrorInfo) async -> CloudKitErrorRecoveryAction {
        logger.error("⚠️ Invalid arguments error - programming error")
        
        // This indicates a bug in our code
        return .showError("Internal error occurred. Romanian cultural data sync will resume after app restart.")
    }
    
    private func handleVersionError(_ error: CKError, errorInfo: CloudKitErrorInfo) async -> CloudKitErrorRecoveryAction {
        logger.warning("📱 Version incompatibility error")
        
        return .showError("App needs to be updated to continue syncing Romanian cultural data. Please update from the App Store.")
    }
    
    private func handleContainerError(_ error: CKError, errorInfo: CloudKitErrorInfo) async -> CloudKitErrorRecoveryAction {
        logger.error("📦 Container configuration error")
        
        return .showError("CloudKit configuration error. Please contact support if this problem persists.")
    }
    
    private func handleConstraintViolationError(_ error: CKError, errorInfo: CloudKitErrorInfo) async -> CloudKitErrorRecoveryAction {
        logger.warning("🚧 Constraint violation in CloudKit record")
        
        return .showError("Data validation error. Romanian cultural progress may need to be reset.")
    }
    
    private func handleGenericError(_ error: Error, errorInfo: CloudKitErrorInfo) async -> CloudKitErrorRecoveryAction {
        logger.error("❓ Generic error: \(error.localizedDescription)")
        
        if errorInfo.attemptCount < RetryConfiguration.maxRetries {
            let delay = calculateRetryDelay(attemptCount: errorInfo.attemptCount)
            await scheduleRetry(for: errorInfo, delay: delay)
            return .retryWithDelay(delay)
        } else {
            return .showError("Unexpected error occurred. Romanian cultural data sync will resume automatically.")
        }
    }
    
    // MARK: - Conflict Resolution
    
    private func determineConflictType(serverRecord: CKRecord, clientRecord: CKRecord) -> CloudKitConflictType {
        // Compare modification dates
        let serverModified = serverRecord.modificationDate ?? Date.distantPast
        let clientModified = clientRecord.modificationDate ?? Date.distantPast
        
        if abs(serverModified.timeIntervalSince(clientModified)) < 1.0 {
            return .simultaneousEdit
        } else if serverModified > clientModified {
            return .serverNewer
        } else {
            return .clientNewer
        }
    }
    
    private func assessCulturalImpact(serverRecord: CKRecord, clientRecord: CKRecord) -> CloudKitCulturalImpact {
        // Assess impact based on record type and fields
        switch serverRecord.recordType {
        case "SepticaPlayerProfile":
            return assessPlayerProfileImpact(serverRecord: serverRecord, clientRecord: clientRecord)
        case "SepticaCulturalProgress":
            return .high // Cultural progress is always high impact
        case "SepticaAchievement":
            return .high // Achievements are always high impact
        case "SepticaGameRecord":
            return .low // Individual game records are low impact
        default:
            return .medium
        }
    }
    
    private func assessPlayerProfileImpact(serverRecord: CKRecord, clientRecord: CKRecord) -> CloudKitCulturalImpact {
        // Check if cultural fields are affected
        let culturalFields = ["heritageEngagementLevel", "folkMusicListened", "culturalStoriesRead", "achievements"]
        
        for field in culturalFields {
            if !areFieldsEqual(serverRecord[field], clientRecord[field]) {
                return .high
            }
        }
        
        // Check if important game progress fields are affected
        let gameProgressFields = ["trophies", "totalWins", "currentArena"]
        
        for field in gameProgressFields {
            if !areFieldsEqual(serverRecord[field], clientRecord[field]) {
                return .medium
            }
        }
        
        return .low
    }
    
    private func areFieldsEqual(_ field1: CKRecordValue?, _ field2: CKRecordValue?) -> Bool {
        switch (field1, field2) {
        case (nil, nil):
            return true
        case (let val1?, let val2?):
            return String(describing: val1) == String(describing: val2)
        default:
            return false
        }
    }
    
    private func attemptAutomaticConflictResolution(_ conflict: CloudKitConflictInfo) async -> CKRecord? {
        logger.info("🔧 Attempting automatic conflict resolution...")
        
        switch conflict.culturalImpact {
        case .low:
            // Use last-writer-wins for low impact
            if conflict.conflictType == .serverNewer {
                return conflict.serverRecord
            } else {
                return conflict.clientRecord
            }
            
        case .medium:
            // Try to merge non-conflicting fields
            return attemptFieldMerge(conflict)
            
        case .high:
            // High impact conflicts require user intervention
            return nil
        }
    }
    
    private func attemptFieldMerge(_ conflict: CloudKitConflictInfo) -> CKRecord? {
        let mergedRecord = conflict.serverRecord.copy() as! CKRecord
        
        // Merge strategy: Take maximum values for numeric fields, union for arrays
        let clientRecord = conflict.clientRecord
        
        for key in clientRecord.allKeys() {
            let serverValue = mergedRecord[key]
            let clientValue = clientRecord[key]
            
            if let serverInt = serverValue as? Int, let clientInt = clientValue as? Int {
                mergedRecord[key] = max(serverInt, clientInt) as CKRecordValue
            } else if let serverFloat = serverValue as? Float, let clientFloat = clientValue as? Float {
                mergedRecord[key] = max(serverFloat, clientFloat) as CKRecordValue
            } else if let serverDate = serverValue as? Date, let clientDate = clientValue as? Date {
                mergedRecord[key] = max(serverDate, clientDate) as CKRecordValue
            }
            // For other types, keep server value
        }
        
        return mergedRecord
    }
    
    // MARK: - Retry Logic
    
    private func calculateRetryDelay(attemptCount: Int) -> TimeInterval {
        let baseDelay = RetryConfiguration.baseRetryDelay
        let exponentialDelay = baseDelay * pow(RetryConfiguration.exponentialBackoffMultiplier, Double(attemptCount))
        let cappedDelay = min(exponentialDelay, RetryConfiguration.maxRetryDelay)
        
        // Add jitter to prevent thundering herd
        let jitter = Double.random(in: RetryConfiguration.jitterRange)
        return cappedDelay * jitter
    }
    
    private func scheduleRetry(for errorInfo: CloudKitErrorInfo, delay: TimeInterval) async {
        let retryOperation = CloudKitRetryOperation(
            id: errorInfo.id,
            operation: errorInfo.operation,
            nextRetryTime: Date().addingTimeInterval(delay),
            attemptCount: errorInfo.attemptCount + 1
        )
        
        retryOperations[errorInfo.id] = retryOperation
        
        // Schedule timer for retry
        let timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                await self?.executeRetry(for: errorInfo.id)
            }
        }
        
        retryTimers[errorInfo.id] = timer
        
        logger.info("⏰ Scheduled retry for operation '\(errorInfo.operation)' in \(delay) seconds")
    }
    
    private func executeRetry(for errorID: String) async {
        guard let retryOperation = retryOperations[errorID] else { return }
        
        logger.info("🔄 Executing retry for operation: \(retryOperation.operation)")
        
        // Clean up
        retryOperations.removeValue(forKey: errorID)
        retryTimers[errorID]?.invalidate()
        retryTimers.removeValue(forKey: errorID)
        
        // Post notification for retry
        NotificationCenter.default.post(
            name: .cloudKitRetryRequested,
            object: retryOperation
        )
    }
    
    // MARK: - User-Friendly Messages
    
    private func createUserFriendlyMessage(for error: CKError) -> String {
        switch error.code {
        case .networkUnavailable, .networkFailure:
            return "No internet connection. Romanian cultural progress will sync when connection is restored."
            
        case .quotaExceeded:
            return "iCloud storage is full. Please free up space to continue syncing Romanian cultural data."
            
        case .notAuthenticated:
            return "Please sign in to iCloud to sync your Romanian cultural progress across devices."
            
        case .permissionFailure:
            return "CloudKit access is disabled. Please enable iCloud for Septica in Settings."
            
        case .zoneBusy, .serviceUnavailable:
            return "CloudKit service is temporarily busy. Sync will resume automatically."
            
        case .requestRateLimited:
            return "Sync rate limited. Romanian cultural data will sync shortly."
            
        default:
            return "Unable to sync Romanian cultural data. Please try again later."
        }
    }
    
    // MARK: - Cleanup
    
    func clearResolvedErrors() {
        currentErrors.removeAll { $0.isResolved }
        conflictsAwaitingResolution.removeAll { $0.isResolved }
    }
    
    func cancelAllRetries() {
        for timer in retryTimers.values {
            timer.invalidate()
        }
        retryTimers.removeAll()
        retryOperations.removeAll()
    }
}

// MARK: - Supporting Types

struct CloudKitErrorInfo: Identifiable {
    let id: String
    let operation: String
    let error: Error
    let timestamp: Date
    var attemptCount: Int
    var isResolved: Bool = false
    
    var userFriendlyMessage: String {
        if let ckError = error as? CKError {
            return CloudKitErrorHandler().createUserFriendlyMessage(for: ckError)
        } else {
            return error.localizedDescription
        }
    }
}

struct CloudKitConflictInfo: Identifiable {
    let id: String
    let recordType: String
    let recordID: CKRecord.ID
    let serverRecord: CKRecord
    let clientRecord: CKRecord
    let conflictType: CloudKitConflictType
    let culturalImpact: CloudKitCulturalImpact
    let timestamp: Date
    var isResolved: Bool = false
}

struct CloudKitRetryOperation: Identifiable {
    let id: String
    let operation: String
    let nextRetryTime: Date
    let attemptCount: Int
}

enum CloudKitErrorRecoveryAction {
    case ignore
    case retryWithDelay(TimeInterval)
    case showError(String)
    case requiresUserIntervention(CloudKitConflictInfo)
    case conflictResolved(CKRecord)
    case partialSuccess([String], [String: Error])
}

enum CloudKitConflictType {
    case simultaneousEdit
    case serverNewer
    case clientNewer
    case deletedOnServer
    case deletedOnClient
}

enum CloudKitCulturalImpact {
    case low
    case medium
    case high
    
    var canAutoResolve: Bool {
        switch self {
        case .low, .medium:
            return true
        case .high:
            return false
        }
    }
}

// MARK: - Extensions

extension CKError {
    var retryAfterSeconds: TimeInterval? {
        return (userInfo[CKErrorRetryAfterKey] as? NSNumber)?.doubleValue
    }
    
    var serverRecord: CKRecord? {
        return userInfo[CKRecordChangedErrorServerRecordKey] as? CKRecord
    }
    
    var clientRecord: CKRecord? {
        return userInfo[CKRecordChangedErrorClientRecordKey] as? CKRecord
    }
    
    var partialErrorsByItemID: [CKRecord.ID: Error]? {
        return userInfo[CKPartialErrorsByItemIDKey] as? [CKRecord.ID: Error]
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let cloudKitRetryRequested = Notification.Name("CloudKitRetryRequested")
    static let cloudKitConflictRequiresResolution = Notification.Name("CloudKitConflictRequiresResolution")
    static let cloudKitErrorRequiresAttention = Notification.Name("CloudKitErrorRequiresAttention")
}