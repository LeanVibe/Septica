import Foundation
import Combine

@MainActor
final class NetworkCoordinator: ObservableObject {
    @Published private(set) var isRunning = false

    func start() {
        isRunning = true
    }
}
