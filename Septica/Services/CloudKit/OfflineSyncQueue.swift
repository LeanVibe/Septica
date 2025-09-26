import Foundation
import Combine

@MainActor
final class OfflineSyncQueue: ObservableObject {
    @Published private(set) var pendingOperations: Int = 0

    func enqueueSyncOperation(description: String) {
        pendingOperations += 1
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 20_000_000)
            await self?.completeOperation()
        }
    }

    private func completeOperation() {
        pendingOperations = max(0, pendingOperations - 1)
    }
}
