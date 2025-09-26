import Foundation
import Combine

@MainActor
final class NetworkManager: ObservableObject {
    @Published private(set) var isConnected: Bool = false

    func connect() {
        isConnected = true
    }

    func disconnect() {
        isConnected = false
    }
}
