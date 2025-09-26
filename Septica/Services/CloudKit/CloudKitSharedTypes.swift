import Foundation

enum CloudKitSyncStatus: Equatable {
    case idle
    case syncing
    case success
    case error
}

struct CloudKitConflict: Identifiable {
    let id = UUID()
    let description: String
}
