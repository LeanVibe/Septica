import Foundation

struct CloudKitErrorHandler {
    func handle(_ error: Error) {
        print("CloudKit error: \(error.localizedDescription)")
    }
}
