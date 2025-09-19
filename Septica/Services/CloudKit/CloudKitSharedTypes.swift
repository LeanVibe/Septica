//
//  CloudKitSharedTypes.swift
//  Septica
//
//  Shared CloudKit data structures used across Septica services.
//  Breaking them out keeps the sync layer decoupled and avoids hidden type dependencies.
//

import Foundation
import CloudKit

/// CloudKit synchronization status used by UI and services.
enum CloudKitSyncStatus: Equatable {
    case idle
    case syncing(CloudKitDataType)
    case success
    case error(Error)
    
    static func == (lhs: CloudKitSyncStatus, rhs: CloudKitSyncStatus) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.success, .success):
            return true
        case (.syncing(let lhsType), .syncing(let rhsType)):
            return lhsType == rhsType
        case (.error, .error):
            return true
        default:
            return false
        }
    }
}

/// Types of data being synchronized through CloudKit.
enum CloudKitDataType {
    case playerProfile
    case gameHistory
    case culturalData
    case achievements
    case statistics
}

/// CloudKit synchronization payloads used by the offline queue.
enum CloudKitUpdate: Codable {
    case playerProfile(CloudKitPlayerProfile)
    case gameHistory([CloudKitGameRecord])
    case culturalProgress(CulturalEducationProgress)
    case achievements([CulturalAchievement])
    
    var description: String {
        switch self {
        case .playerProfile:
            return "Player Profile"
        case .gameHistory(let games):
            return "Game History (\(games.count) games)"
        case .culturalProgress:
            return "Romanian Cultural Progress"
        case .achievements(let achievements):
            return "Romanian Achievements (\(achievements.count))"
        }
    }
}

/// CloudKit-related errors that we surface across the sync stack.
enum CloudKitError: LocalizedError {
    case accountUnavailable
    case networkUnavailable
    case syncFailed(Error)
    case recordFetchFailed(Error)
    case fetchFailed(Error)
    case conflictResolutionFailed(Error)
    case notAvailable
    
    var errorDescription: String? {
        switch self {
        case .accountUnavailable:
            return "iCloud account is not available for Romanian cultural sync"
        case .networkUnavailable:
            return "Network connection required for Romanian cultural sync"
        case .syncFailed(let error):
            return "Failed to sync Romanian cultural data: \(error.localizedDescription)"
        case .recordFetchFailed(let error):
            return "Failed to fetch Romanian record: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch Romanian cultural data: \(error.localizedDescription)"
        case .conflictResolutionFailed(let error):
            return "Failed to resolve Romanian cultural data conflict: \(error.localizedDescription)"
        case .notAvailable:
            return "CloudKit is not available"
        }
    }
}

/// High-level sync state used by activity indicators and logging.
enum CloudKitSyncState: String, CaseIterable {
    case idle = "idle"
    case syncing = "syncing"
    case uploading = "uploading"
    case downloading = "downloading"
    case conflictResolution = "conflict_resolution"
    case error = "error"
    
    var displayName: String {
        switch self {
        case .idle: return "Ready"
        case .syncing: return "Synchronizing..."
        case .uploading: return "Uploading Romanian heritage data..."
        case .downloading: return "Downloading cultural progress..."
        case .conflictResolution: return "Resolving conflicts..."
        case .error: return "Sync error"
        }
    }
}

/// Represents a data conflict detected during CloudKit sync.
struct CloudKitConflict: Identifiable {
    let id = UUID()
    let recordType: String
    let recordID: CKRecord.ID
    let serverRecord: CKRecord?
    let clientRecord: CKRecord
    let conflictType: ConflictType
    let culturalImpact: CulturalImpact
    
    enum ConflictType {
        case dataModified
        case recordDeleted
        case culturalProgressMismatch
        case achievementDuplicate
    }
    
    enum CulturalImpact {
        case none
        case minor           // Preferences, non-critical data
        case moderate        // Game statistics, partial cultural progress
        case significant     // Major cultural achievements, heritage milestones
        case critical        // Cultural education progress, rare achievements
        
        var requiresUserIntervention: Bool {
            self == .significant || self == .critical
        }
    }
}
