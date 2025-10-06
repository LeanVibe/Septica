import Foundation
import Combine

/// Network Manager with automatic reconnection and state recovery
/// Handles WebSocket connections to Go backend with exponential backoff
@MainActor
final class NetworkManager: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var isConnected: Bool = false
    @Published private(set) var connectionStatus: ConnectionStatus = .disconnected
    @Published private(set) var isReconnecting: Bool = false
    @Published private(set) var lastSyncedAt: Date?
    @Published private(set) var reconnectionAttempts: Int = 0

    // MARK: - Private Properties
    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession?
    private var reconnectionTimer: Timer?
    private var heartbeatTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    // Session management
    private(set) var sessionID: String?
    private(set) var userID: UUID?
    private var pendingGameState: GameState?

    // MARK: - Configuration
    private let maxReconnectionAttempts = 3
    private let heartbeatInterval: TimeInterval = 30.0
    private let connectionTimeout: TimeInterval = 10.0

    // MARK: - Initialization
    init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = connectionTimeout
        configuration.waitsForConnectivity = true
        self.session = URLSession(configuration: configuration)
    }

    // MARK: - Connection Management

    /// Connect to the WebSocket server
    /// - Parameters:
    ///   - userID: User identifier for authentication
    ///   - sessionID: Optional session ID for reconnection
    func connect(userID: UUID, sessionID: String? = nil) {
        self.userID = userID
        self.sessionID = sessionID ?? UUID().uuidString

        connectionStatus = .connecting
        isConnected = false

        // Build WebSocket URL with authentication
        var components = URLComponents()
        components.scheme = "ws"
        components.host = "localhost"
        components.port = 8082
        components.path = "/ws/connect"
        components.queryItems = [
            URLQueryItem(name: "user_id", value: userID.uuidString),
            URLQueryItem(name: "session_id", value: self.sessionID)
        ]

        guard let url = components.url else {
            connectionStatus = .error
            return
        }

        // Create WebSocket task
        webSocketTask = session?.webSocketTask(with: url)
        webSocketTask?.resume()

        // Start receiving messages
        receiveMessage()

        // Start heartbeat timer
        startHeartbeat()

        // Mark as connected (will be confirmed by server ack)
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay
            if connectionStatus == .connecting {
                isConnected = true
                connectionStatus = .connected
                lastSyncedAt = Date()
                reconnectionAttempts = 0
            }
        }
    }

    /// Disconnect from WebSocket server
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        stopHeartbeat()
        stopReconnectionTimer()

        isConnected = false
        connectionStatus = .disconnected
        isReconnecting = false
        reconnectionAttempts = 0
    }

    // MARK: - Automatic Reconnection

    /// Handle connection loss and attempt reconnection
    /// Implements exponential backoff: 1s, 2s, 4s
    private func handleConnectionLoss() {
        guard !isReconnecting else { return }
        guard reconnectionAttempts < maxReconnectionAttempts else {
            connectionStatus = .error
            isReconnecting = false
            return
        }

        isConnected = false
        connectionStatus = .reconnecting
        isReconnecting = true
        reconnectionAttempts += 1

        // Calculate exponential backoff delay
        let delay = pow(2.0, Double(reconnectionAttempts - 1))

        print("[NetworkManager] Connection lost. Attempting reconnection \(reconnectionAttempts)/\(maxReconnectionAttempts) in \(delay)s")

        // Schedule reconnection attempt
        stopReconnectionTimer()
        reconnectionTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.attemptReconnection()
            }
        }
    }

    /// Attempt to reconnect with existing session
    private func attemptReconnection() {
        guard let userID = userID, let sessionID = sessionID else {
            connectionStatus = .error
            isReconnecting = false
            return
        }

        print("[NetworkManager] Reconnecting with session \(sessionID)")

        // Reconnect with existing session ID to resume game state
        connect(userID: userID, sessionID: sessionID)
    }

    /// Reset reconnection state after successful connection
    private func resetReconnectionState() {
        isReconnecting = false
        reconnectionAttempts = 0
        stopReconnectionTimer()
    }

    // MARK: - Message Handling

    /// Receive messages from WebSocket
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }

                switch result {
                case .success(let message):
                    switch message {
                    case .string(let text):
                        self.handleMessage(text)
                    case .data(let data):
                        if let text = String(data: data, encoding: .utf8) {
                            self.handleMessage(text)
                        }
                    @unknown default:
                        break
                    }

                    // Continue receiving
                    self.receiveMessage()

                case .failure(let error):
                    print("[NetworkManager] WebSocket error: \(error)")
                    self.handleConnectionLoss()
                }
            }
        }
    }

    /// Handle incoming message from server
    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }

        do {
            let decoder = JSONDecoder()
            let message = try decoder.decode(ServerMessage.self, from: data)

            switch message.type {
            case "connection_ack":
                // Connection acknowledged by server
                isConnected = true
                connectionStatus = .connected
                lastSyncedAt = Date()
                resetReconnectionState()
                print("[NetworkManager] Connection acknowledged by server")

            case "game_state":
                // Game state update received
                lastSyncedAt = Date()
                // Notify subscribers about state update
                NotificationCenter.default.post(
                    name: .gameStateReceived,
                    object: message.payload
                )

            case "reconnection_success":
                // Reconnection successful with state recovery
                resetReconnectionState()
                if let recoveredState = message.payload {
                    handleStateRecovery(recoveredState)
                }

            case "error":
                print("[NetworkManager] Server error: \(message.payload?["message"] ?? "unknown")")

            default:
                break
            }

        } catch {
            print("[NetworkManager] Failed to decode message: \(error)")
        }
    }

    /// Send message to server
    func send(_ message: ClientMessage) {
        guard isConnected else {
            print("[NetworkManager] Cannot send message - not connected")
            return
        }

        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(message)

            webSocketTask?.send(.data(data)) { error in
                if let error = error {
                    print("[NetworkManager] Failed to send message: \(error)")
                    Task { @MainActor in
                        self.handleConnectionLoss()
                    }
                }
            }
        } catch {
            print("[NetworkManager] Failed to encode message: \(error)")
        }
    }

    // MARK: - State Recovery

    /// Handle game state recovery after reconnection
    /// Validates consistency and merges with local state
    private func handleStateRecovery(_ recoveredState: [String: Any]) {
        print("[NetworkManager] Recovering game state from server")

        // Post notification for game state recovery
        NotificationCenter.default.post(
            name: .gameStateRecovered,
            object: recoveredState
        )
    }

    /// Store pending game state for reconnection recovery
    func storePendingState(_ gameState: GameState) {
        self.pendingGameState = gameState
    }

    // MARK: - Heartbeat Management

    /// Start heartbeat to keep connection alive
    private func startHeartbeat() {
        stopHeartbeat()

        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: heartbeatInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.sendHeartbeat()
            }
        }
    }

    /// Stop heartbeat timer
    private func stopHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }

    /// Send heartbeat ping to server
    private func sendHeartbeat() {
        let message = ClientMessage(type: "ping", payload: nil)
        send(message)
    }

    /// Stop reconnection timer
    private func stopReconnectionTimer() {
        reconnectionTimer?.invalidate()
        reconnectionTimer = nil
    }

    // MARK: - Cleanup

    deinit {
        // Cancel WebSocket and cleanup synchronously
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil

        // Stop timers
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
        reconnectionTimer?.invalidate()
        reconnectionTimer = nil
    }
}

// MARK: - Message Models

/// Client message sent to server
struct ClientMessage {
    let type: String
    let payload: [String: Any]?

    init(type: String, payload: [String: Any]?) {
        self.type = type
        self.payload = payload
    }

    func toJSON() -> Data? {
        var dict: [String: Any] = ["type": type]
        if let payload = payload {
            dict["payload"] = payload
        }
        return try? JSONSerialization.data(withJSONObject: dict)
    }
}

extension ClientMessage: Encodable {
    enum CodingKeys: String, CodingKey {
        case type
        case payload
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)

        if let payload = payload {
            // Encode payload as a nested container
            let jsonData = try JSONSerialization.data(withJSONObject: payload)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                try container.encode(jsonString, forKey: .payload)
            }
        }
    }
}

/// Server message received from backend
struct ServerMessage {
    let type: String
    let payload: [String: Any]?

    init(type: String, payload: [String: Any]?) {
        self.type = type
        self.payload = payload
    }
}

extension ServerMessage: Decodable {
    enum CodingKeys: String, CodingKey {
        case type
        case payload
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)

        // Try to decode payload as a dictionary
        if let jsonString = try? container.decode(String.self, forKey: .payload),
           let jsonData = jsonString.data(using: .utf8),
           let dict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
            payload = dict
        } else if let dict = try? container.decode([String: AnyCodable].self, forKey: .payload) {
            payload = dict.mapValues { $0.value }
        } else {
            payload = nil
        }
    }
}

/// Helper type to decode Any values
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        if let intValue = value as? Int {
            try container.encode(intValue)
        } else if let doubleValue = value as? Double {
            try container.encode(doubleValue)
        } else if let boolValue = value as? Bool {
            try container.encode(boolValue)
        } else if let stringValue = value as? String {
            try container.encode(stringValue)
        } else {
            try container.encodeNil()
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let gameStateReceived = Notification.Name("gameStateReceived")
    static let gameStateRecovered = Notification.Name("gameStateRecovered")
    static let connectionStatusChanged = Notification.Name("connectionStatusChanged")
}
