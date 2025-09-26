import Foundation
import Combine

@MainActor
final class MultiplayerService: ObservableObject {
    @Published private(set) var isMatchmaking = false

    func startMatchmaking() async {
        isMatchmaking = true
        try? await Task.sleep(nanoseconds: 50_000_000)
        isMatchmaking = false
    }
}
