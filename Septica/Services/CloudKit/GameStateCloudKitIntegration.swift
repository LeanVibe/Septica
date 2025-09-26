import Foundation
import Combine

@MainActor
final class GameStateCloudKitIntegration: ObservableObject {
    @Published private(set) var isSyncing: Bool = false
    @Published private(set) var lastSyncDate: Date?

    func syncCurrentGame(_ gameState: GameState) async {
        guard !isSyncing else { return }
        isSyncing = true
        try? await Task.sleep(nanoseconds: 50_000_000)
        lastSyncDate = Date()
        isSyncing = false
    }
}
