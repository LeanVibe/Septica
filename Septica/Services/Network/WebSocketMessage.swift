import Foundation

struct WebSocketMessage: Codable {
    let type: String
    let payload: Data?

    init(type: String, payload: Data? = nil) {
        self.type = type
        self.payload = payload
    }
}
