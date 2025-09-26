import Foundation
import Combine

@MainActor
final class PlayerProfileService: ObservableObject {
    @Published private(set) var currentProfile: CloudKitPlayerProfile?

    func load() async {
        currentProfile = CloudKitPlayerProfile(displayName: "Player")
    }
}
