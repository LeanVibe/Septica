//
//  NetworkManager.swift
//  Septica
//
//  Core networking service with WebSocket communication
//  Handles connection lifecycle, message sending/receiving, and reconnection logic
//

import Foundation
import Combine
import OSLog

/// Core networking service for WebSocket communication with the Septica game server
@MainActor
class NetworkManager: ObservableObject {
    
    // MARK: - Properties
    
    /// Current connection status
    @Published private(set) var connectionStatus: ConnectionStatus = .disconnected
    
    /// Whether the network manager is actively attempting to connect
    @Published private(set) var isConnecting: Bool = false
    
    /// Latest server-provided information
    @Published private(set) var serverInfo: ConnectionAckPayload?
    
    /// Publisher for incoming messages
    private let messageSubject = PassthroughSubject<IncomingMessage, Never>()
    
    /// Publisher for connection events
    private let connectionEventSubject = PassthroughSubject<ConnectionEvent, Never>()
    
    /// Publisher for errors
    private let errorSubject = PassthroughSubject<NetworkError, Never>()
    
    // MARK: - Private Properties
    
    private var webSocketTask: URLSessionWebSocketTask?
    private let urlSession: URLSession
    private let logger = Logger(subsystem: "com.septica.app", category: "NetworkManager")
    
    // Connection configuration
    private let baseURL: URL
    private let connectionTimeoutInterval: TimeInterval = 10.0
    private let heartbeatTimeoutInterval: TimeInterval = 60.0
    
    // Reconnection logic
    private var reconnectionTimer: Timer?
    private var heartbeatTimer: Timer?
    private var reconnectionAttempts: Int = 0
    private let maxReconnectionAttempts: Int = 5
    private let reconnectionDelays: [TimeInterval] = [1.0, 2.0, 4.0, 8.0, 16.0]
    
    // Message handling
    private var pendingMessages: [OutgoingMessage] = []
    private var messageSequenceNumber: Int = 0
    
    // Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public Publishers
    
    /// Publisher for incoming messages
    var messagePublisher: AnyPublisher<IncomingMessage, Never> {
        messageSubject.eraseToAnyPublisher()
    }
    
    /// Publisher for connection events
    var connectionEventPublisher: AnyPublisher<ConnectionEvent, Never> {
        connectionEventSubject.eraseToAnyPublisher()
    }
    
    /// Publisher for network errors
    var errorPublisher: AnyPublisher<NetworkError, Never> {
        errorSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    init(baseURL: URL = URL(string: "ws://localhost:8080")!) {
        self.baseURL = baseURL
        
        // Configure URLSession for WebSocket connections
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = connectionTimeoutInterval
        configuration.timeoutIntervalForResource = heartbeatTimeoutInterval
        self.urlSession = URLSession(configuration: configuration)
        
        setupConnectionObservers()
        logger.info("NetworkManager initialized with base URL: \(baseURL.absoluteString)")
    }
    
    deinit {
        disconnect()
        cancellables.removeAll()
    }
    
    // MARK: - Connection Management
    
    /// Connect to the WebSocket server
    /// - Parameter playerId: Player ID for authentication (required by backend)
    func connect(playerId: UUID? = nil) {
        guard connectionStatus == .disconnected || connectionStatus == .error else {
            logger.warning("Attempted to connect while already connected or connecting")
            return
        }
        
        // Generate or validate player ID - backend requires user_id parameter
        let userID = playerId ?? UUID()
        
        logger.info("Starting connection to WebSocket server...")
        connectionStatus = .connecting
        isConnecting = true
        
        // Construct WebSocket URL
        var urlComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        urlComponents.scheme = urlComponents.scheme == "https" ? "wss" : "ws"
        urlComponents.path = "/ws/connect"
        
        // Backend requires user_id parameter (not player_id)
        urlComponents.queryItems = [
            URLQueryItem(name: "user_id", value: userID.uuidString)
        ]
        
        // Add optional session_id for tracking
        let sessionId = UUID().uuidString
        urlComponents.queryItems?.append(
            URLQueryItem(name: "session_id", value: sessionId)
        )
        
        guard let wsURL = urlComponents.url else {
            handleConnectionError(.invalidURL)
            return
        }
        
        // Create WebSocket task
        webSocketTask = urlSession.webSocketTask(with: wsURL)
        
        // Start connection
        webSocketTask?.resume()
        startReceivingMessages()
        
        // Set connection timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + connectionTimeoutInterval) { [weak self] in
            guard let self = self else { return }
            if self.connectionStatus == .connecting {
                self.handleConnectionError(.connectionTimeout)
            }
        }
    }
    
    /// Disconnect from the WebSocket server
    func disconnect() {
        logger.info("Disconnecting from WebSocket server...")
        
        stopReconnectionTimer()
        stopHeartbeat()
        
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        
        connectionStatus = .disconnected
        isConnecting = false
        serverInfo = nil
        
        connectionEventSubject.send(.disconnected)
    }
    
    /// Force reconnection attempt
    func reconnect() {
        logger.info("Manual reconnection requested")
        disconnect()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.connect()
        }
    }
    
    // MARK: - Message Sending
    
    /// Send a message to the server
    /// - Parameter message: The message to send
    func send(_ message: OutgoingMessage) {
        guard connectionStatus == .connected else {
            logger.warning("Attempted to send message while not connected. Queuing message.")
            pendingMessages.append(message)
            return
        }
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(message)
            
            webSocketTask?.send(.data(data)) { [weak self] error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.logger.error("Failed to send message: \(error.localizedDescription)")
                        self?.errorSubject.send(.sendingFailed(error))
                    } else {
                        self?.logger.debug("Message sent successfully: \(message.type)")
                    }
                }
            }
        } catch {
            logger.error("Failed to encode message: \(error.localizedDescription)")
            errorSubject.send(.encodingError(error))
        }
    }
    
    /// Send a ping message to test connection
    func ping() {
        send(.ping())
    }
    
    // MARK: - Private Methods
    
    private func setupConnectionObservers() {
        // Monitor app lifecycle
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.handleAppWillEnterForeground()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.handleAppDidEnterBackground()
            }
            .store(in: &cancellables)
    }
    
    private func startReceivingMessages() {
        guard let webSocketTask = webSocketTask else { return }
        
        webSocketTask.receive { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success(let message):
                    self.handleReceivedMessage(message)
                    // Continue receiving messages
                    self.startReceivingMessages()
                    
                case .failure(let error):
                    self.logger.error("WebSocket receive error: \(error.localizedDescription)")
                    self.handleConnectionError(.receiveError(error))
                }
            }
        }
    }
    
    private func handleReceivedMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .data(let data):
            parseIncomingMessage(from: data)
            
        case .string(let text):
            if let data = text.data(using: .utf8) {
                parseIncomingMessage(from: data)
            } else {
                logger.error("Failed to convert string message to data")
            }
            
        @unknown default:
            logger.error("Received unknown message type")
        }
    }
    
    private func parseIncomingMessage(from data: Data) {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let incomingMessage = try decoder.decode(IncomingMessage.self, from: data)
            
            logger.debug("Received message: \(incomingMessage.type)")
            
            // Handle system messages
            handleSystemMessage(incomingMessage)
            
            // Forward message to subscribers
            messageSubject.send(incomingMessage)
            
        } catch {
            logger.error("Failed to decode incoming message: \(error.localizedDescription)")
            errorSubject.send(.decodingError(error))
        }
    }
    
    private func handleSystemMessage(_ message: IncomingMessage) {
        guard let messageType = message.messageType else {
            logger.warning("Unknown message type: \(message.type)")
            return
        }
        
        switch messageType {
        case .connectionAck:
            handleConnectionAck(message)
        case .pong:
            handlePong(message)
        case .heartbeat:
            handleHeartbeat(message)
        case .error:
            handleErrorMessage(message)
        default:
            // Game-specific messages are handled by MultiplayerService
            break
        }
    }
    
    private func handleConnectionAck(_ message: IncomingMessage) {
        do {
            let ackPayload = try message.parsePayload(as: ConnectionAckPayload.self)
            serverInfo = ackPayload
            connectionStatus = .connected
            isConnecting = false
            reconnectionAttempts = 0
            
            // Start heartbeat
            startHeartbeat(interval: TimeInterval(ackPayload.heartbeatInterval) / 1000.0)
            
            // Send any pending messages
            sendPendingMessages()
            
            connectionEventSubject.send(.connected)
            logger.info("Connection acknowledged by server. Session ID: \(ackPayload.sessionId)")
            
        } catch {
            logger.error("Failed to parse connection ack: \(error.localizedDescription)")
            handleConnectionError(.invalidResponse)
        }
    }
    
    private func handlePong(_ message: IncomingMessage) {
        logger.debug("Received pong from server")
        // Pong received - connection is alive
    }
    
    private func handleHeartbeat(_ message: IncomingMessage) {
        logger.debug("Received heartbeat from server")
        // Respond with ping to show we're alive
        ping()
    }
    
    private func handleErrorMessage(_ message: IncomingMessage) {
        do {
            let errorPayload = try message.parsePayload(as: ErrorPayload.self)
            logger.error("Server error: \(errorPayload.message)")
            
            let networkError = NetworkError.serverError(
                errorPayload.errorType,
                errorPayload.message
            )
            errorSubject.send(networkError)
            
            // Some errors require disconnection
            if shouldDisconnectOnError(errorPayload.errorType) {
                disconnect()
            }
            
        } catch {
            logger.error("Failed to parse error message: \(error.localizedDescription)")
        }
    }
    
    private func shouldDisconnectOnError(_ errorType: String) -> Bool {
        switch errorType {
        case NetworkErrorType.notAuthorized.rawValue,
             NetworkErrorType.connectionFailed.rawValue:
            return true
        default:
            return false
        }
    }
    
    private func handleConnectionError(_ error: NetworkError) {
        logger.error("Connection error: \(error.localizedDescription)")
        
        connectionStatus = .error
        isConnecting = false
        errorSubject.send(error)
        connectionEventSubject.send(.failed(error))
        
        // Attempt reconnection if appropriate
        if shouldAttemptReconnection(for: error) {
            scheduleReconnection()
        }
    }
    
    private func shouldAttemptReconnection(for error: NetworkError) -> Bool {
        switch error {
        case .connectionTimeout, .receiveError, .networkUnavailable:
            return reconnectionAttempts < maxReconnectionAttempts
        case .serverError(let type, _):
            // Don't reconnect for authorization errors
            return type != NetworkErrorType.notAuthorized.rawValue
        default:
            return false
        }
    }
    
    private func scheduleReconnection() {
        guard reconnectionAttempts < maxReconnectionAttempts else {
            logger.error("Max reconnection attempts reached")
            connectionEventSubject.send(.maxReconnectionAttemptsReached)
            return
        }
        
        let delayIndex = min(reconnectionAttempts, reconnectionDelays.count - 1)
        let delay = reconnectionDelays[delayIndex]
        
        logger.info("Scheduling reconnection attempt \(reconnectionAttempts + 1) in \(delay) seconds")
        
        connectionStatus = .reconnecting
        connectionEventSubject.send(.reconnecting)
        
        reconnectionTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.reconnectionAttempts += 1
            self.connect()
        }
    }
    
    private func stopReconnectionTimer() {
        reconnectionTimer?.invalidate()
        reconnectionTimer = nil
    }
    
    private func startHeartbeat(interval: TimeInterval) {
        stopHeartbeat()
        
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.ping()
        }
    }
    
    private func stopHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }
    
    private func sendPendingMessages() {
        let messages = pendingMessages
        pendingMessages.removeAll()
        
        messages.forEach { send($0) }
        
        if !messages.isEmpty {
            logger.info("Sent \(messages.count) pending messages")
        }
    }
    
    // MARK: - App Lifecycle Handlers
    
    private func handleAppWillEnterForeground() {
        logger.info("App entering foreground")
        if connectionStatus == .disconnected || connectionStatus == .error {
            // Attempt to reconnect when app comes to foreground
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.connect()
            }
        }
    }
    
    private func handleAppDidEnterBackground() {
        logger.info("App entering background")
        // Keep connection alive but stop non-essential operations
        stopReconnectionTimer()
    }
}

// MARK: - Supporting Types

/// Connection status for tracking current state
enum ConnectionStatus {
    case disconnected
    case connecting
    case connected
    case reconnecting
    case error
}

/// Connection events that can occur
enum ConnectionEvent {
    case connected
    case disconnected
    case reconnecting
    case failed(NetworkError)
    case maxReconnectionAttemptsReached
}

/// Network errors that can occur
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case connectionTimeout
    case receiveError(Error)
    case sendingFailed(Error)
    case networkUnavailable
    case invalidResponse
    case encodingError(Error)
    case decodingError(Error)
    case serverError(String, String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid WebSocket URL"
        case .connectionTimeout:
            return "Connection timeout"
        case .receiveError(let error):
            return "Failed to receive message: \(error.localizedDescription)"
        case .sendingFailed(let error):
            return "Failed to send message: \(error.localizedDescription)"
        case .networkUnavailable:
            return "Network unavailable"
        case .invalidResponse:
            return "Invalid server response"
        case .encodingError(let error):
            return "Message encoding error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Message decoding error: \(error.localizedDescription)"
        case .serverError(_, let message):
            return "Server error: \(message)"
        }
    }
}