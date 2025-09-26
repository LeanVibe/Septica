import Foundation
import Combine

@MainActor
final class StatisticsCloudKitManager: ObservableObject {
    @Published private(set) var isSyncing: Bool = false

    func syncIfNeeded() async {
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }
        try? await Task.sleep(nanoseconds: 50_000_000)
    }
}
