import Foundation
import Combine

@MainActor
final class SepticaCloudKitManager: ObservableObject {
    static let shared = SepticaCloudKitManager()

    @Published private(set) var isAvailable: Bool = true

    init() {}

    func checkCloudKitAvailability() async {}
}
