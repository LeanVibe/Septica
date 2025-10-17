//
//  EmoteManager.swift
//  Septica
//
//  Elegant real-time emote broadcasting and management system
//  Handles multiplayer emote communication with cultural authenticity
//

import Foundation
import Combine

// MARK: - Emote Manager Delegate Protocol

/// Delegate protocol for emote system events
protocol EmoteManagerDelegate: AnyObject {
    func emoteManager(_ manager: EmoteManager, didReceiveEmote emote: EmoteMessage)
    func emoteManager(_ manager: EmoteManager, didUpdatePlayerStatus playerId: UUID, isEmoting: Bool)
    func emoteManager(_ manager: EmoteManager, didEncounterError error: EmoteError)
}

// MARK: - Emote Error Types

enum EmoteError: Error, LocalizedError {
    case networkUnavailable
    case invalidPlayerId(UUID)
    case rateLimitExceeded(timeUntilNext: TimeInterval)
    case serializationFailed(Error)
    case deserializationFailed(Error)
    case connectionLost
    case unknownError(String)

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "Network connection unavailable"
        case .invalidPlayerId(let id):
            return "Invalid player ID: \(id.uuidString)"
        case .rateLimitExceeded(let time):
            return "Rate limit exceeded. Try again in \(Int(time)) seconds."
        case .serializationFailed(let error):
            return "Failed to serialize emote: \(error.localizedDescription)"
        case .deserializationFailed(let error):
            return "Failed to deserialize emote: \(error.localizedDescription)"
        case .connectionLost:
            return "Connection to game server lost"
        case .unknownError(let message):
            return "Unknown error: \(message)"
        }
    }
}

// MARK: - Emote Configuration

struct EmoteConfiguration {
    let rateLimitPerPlayer: TimeInterval
    let maxQueueSize: Int
    let emoteTimeout: TimeInterval
    let retryAttempts: Int
    let batchSize: Int

    static let `default` = EmoteConfiguration(
        rateLimitPerPlayer: 1.0, // 1 emote per second per player
        maxQueueSize: 100,
        emoteTimeout: 30.0,
        retryAttempts: 3,
        batchSize: 10
    )
}

// MARK: - Emote Queue Entry

private struct EmoteQueueEntry {
    let emote: EmoteMessage
    let timestamp: Date
    let retryCount: Int

    var isValid: Bool {
        return emote.isValid && Date().timeIntervalSince(timestamp) < 30.0
    }
}

// MARK: - Emote Manager

/// Main emote management system for real-time multiplayer communication
@MainActor
class EmoteManager: ObservableObject {

    // MARK: - Published Properties

    @Published var isConnected: Bool = false
    @Published var activeEmotes: [UUID: EmoteMessage] = [:] // playerId -> emote
    @Published var recentEmotes: [EmoteMessage] = [] // Limited history
    @Published var connectionStatus: ConnectionStatus = .disconnected

    // MARK: - Private Properties

    private weak var delegate: EmoteManagerDelegate?
    private let configuration: EmoteConfiguration
    private var messageSender: MessageSending?
    private var emoteQueue: [EmoteQueueEntry] = []
    private var rateLimitTracker: [UUID: Date] = [:]
    private var cancellables = Set<AnyCancellable>()

    // Queue processing timer
    private var queueTimer: Timer?

    // MARK: - Connection Status

    enum ConnectionStatus {
        case disconnected
        case connecting
        case connected
        case reconnecting
        case error(Error)
    }

    // MARK: - Initialization

    init(configuration: EmoteConfiguration = .default) {
        self.configuration = configuration
        setupQueueProcessor()
    }

    deinit {
        stopQueueProcessor()
    }

    // MARK: - Public Interface

    /// Set the delegate for emote events
    func setDelegate(_ delegate: EmoteManagerDelegate) {
        self.delegate = delegate
    }

    /// Configure message sender (WebSocket, etc.)
    func setMessageSender(_ sender: MessageSending) {
        self.messageSender = sender
        updateConnectionStatus(.connected)
    }

    /// Send an emote to other players
    func sendEmote(_ emote: EmoteMessage) async throws {
        // Validate emote
        let validation = emote.validate()
        guard validation.isValid else {
            throw EmoteError.unknownError("Validation failed: \(validation.errors.joined(separator: ", "))")
        }

        // Check rate limiting
        try checkRateLimit(for: emote.playerId)

        // Check connection
        guard isConnected else {
            throw EmoteError.networkUnavailable
        }

        // Serialize and send
        guard let sender = messageSender else {
            throw EmoteError.connectionLost
        }

        let message = GameWebSocketMessage.emoteBroadcast(emote)

        do {
            try await sender.sendMessage(message)

            // Add to recent emotes
            addToRecentEmotes(emote)

            // Update local state
            activeEmotes[emote.playerId] = emote

            // Notify delegate
            delegate?.emoteManager(self, didUpdatePlayerStatus: emote.playerId, isEmoting: true)

        } catch {
            // Queue for retry if it's a network error
            if shouldRetry(for: error) {
                queueEmote(emote, retryCount: 0)
            } else {
                throw EmoteError.serializationFailed(error)
            }
        }
    }

    /// Process received emote message
    func receiveEmote(_ message: GameWebSocketMessage) {
        guard case let .emoteBroadcast(emote) = message else {
            return
        }

        // Validate received emote
        let validation = emote.validate()
        guard validation.isValid else {
            delegate?.emoteManager(self, didEncounterError: .unknownError("Invalid emote received"))
            return
        }

        // Update active emotes
        activeEmotes[emote.playerId] = emote

        // Add to recent emotes
        addToRecentEmotes(emote)

        // Set up timeout for emote completion
        scheduleEmoteTimeout(for: emote)

        // Notify delegate
        delegate?.emoteManager(self, didReceiveEmote: emote)
        delegate?.emoteManager(self, didUpdatePlayerStatus: emote.playerId, isEmoting: true)
    }

    /// Cancel active emote for a player
    func cancelEmote(for playerId: UUID) {
        activeEmotes.removeValue(forKey: playerId)
        delegate?.emoteManager(self, didUpdatePlayerStatus: playerId, isEmoting: false)
    }

    /// Get current emote for a player
    func getActiveEmote(for playerId: UUID) -> EmoteMessage? {
        return activeEmotes[playerId]?.isValid == true ? activeEmotes[playerId] : nil
    }

    /// Clear all active emotes
    func clearAllEmotes() {
        let activePlayerIds = Array(activeEmotes.keys)
        activeEmotes.removeAll()

        for playerId in activePlayerIds {
            delegate?.emoteManager(self, didUpdatePlayerStatus: playerId, isEmoting: false)
        }
    }

    /// Clean up expired emotes
    func cleanupExpiredEmotes() {
        let now = Date()
        var expiredPlayerIds: [UUID] = []

        for (playerId, emote) in activeEmotes {
            if emote.timestamp.addingTimeInterval(emote.duration) <= now {
                expiredPlayerIds.append(playerId)
            }
        }

        for playerId in expiredPlayerIds {
            cancelEmote(for: playerId)
        }

        // Clean rate limit tracker
        let cutoffTime = now.addingTimeInterval(-configuration.rateLimitPerPlayer * 2)
        rateLimitTracker = rateLimitTracker.filter { $0.value > cutoffTime }
    }

    // MARK: - Private Methods

    private func updateConnectionStatus(_ status: ConnectionStatus) {
        connectionStatus = status
        isConnected = (status == .connected)

        if !isConnected {
            clearAllEmotes()
        }
    }

    private func checkRateLimit(for playerId: UUID) throws {
        let now = Date()
        let lastEmoteTime = rateLimitTracker[playerId]

        if let lastTime = lastEmoteTime {
            let timeSinceLastEmote = now.timeIntervalSince(lastTime)
            if timeSinceLastEmote < configuration.rateLimitPerPlayer {
                let waitTime = configuration.rateLimitPerPlayer - timeSinceLastEmote
                throw EmoteError.rateLimitExceeded(timeUntilNext: waitTime)
            }
        }

        rateLimitTracker[playerId] = now
    }

    private func addToRecentEmotes(_ emote: EmoteMessage) {
        recentEmotes.append(emote)

        // Keep only recent emotes (last 50)
        if recentEmotes.count > 50 {
            recentEmotes.removeFirst(recentEmotes.count - 50)
        }
    }

    private func scheduleEmoteTimeout(for emote: EmoteMessage) {
        DispatchQueue.main.asyncAfter(deadline: .now() + emote.duration) { [weak self] in
            self?.cancelEmote(for: emote.playerId)
        }
    }

    private func shouldRetry(for error: Error) -> Bool {
        // Define retryable errors
        if error is URLError {
            return true
        }

        if let emoteError = error as? EmoteError {
            switch emoteError {
            case .networkUnavailable, .connectionLost:
                return true
            default:
                return false
            }
        }

        return false
    }

    private func queueEmote(_ emote: EmoteMessage, retryCount: Int) {
        guard retryCount < configuration.retryAttempts else {
            delegate?.emoteManager(self, didEncounterError: .unknownError("Max retry attempts exceeded"))
            return
        }

        guard emoteQueue.count < configuration.maxQueueSize else {
            delegate?.emoteManager(self, didEncounterError: .unknownError("Emote queue full"))
            return
        }

        let entry = EmoteQueueEntry(emote: emote, timestamp: Date(), retryCount: retryCount)
        emoteQueue.append(entry)
    }

    private func setupQueueProcessor() {
        queueTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.processQueue()
        }
    }

    private func stopQueueProcessor() {
        queueTimer?.invalidate()
        queueTimer = nil
    }

    private func processQueue() {
        guard isConnected, let sender = messageSender else {
            return
        }

        let batchSize = min(configuration.batchSize, emoteQueue.count)
        guard batchSize > 0 else { return }

        let batch = Array(emoteQueue.prefix(batchSize))
        emoteQueue.removeFirst(batchSize)

        Task {
            for entry in batch {
                guard entry.isValid else { continue }

                let message = GameWebSocketMessage.emoteBroadcast(entry.emote)

                do {
                    try await sender.sendMessage(message)
                } catch {
                    if shouldRetry(for: error) && entry.retryCount < configuration.retryAttempts {
                        // Re-queue with incremented retry count
                        let retryEntry = EmoteQueueEntry(
                            emote: entry.emote,
                            timestamp: entry.timestamp,
                            retryCount: entry.retryCount + 1
                        )
                        emoteQueue.append(retryEntry)
                    } else {
                        await MainActor.run {
                            self.delegate?.emoteManager(self, didEncounterError: .serializationFailed(error))
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Message Sending Protocol

protocol MessageSending {
    func sendMessage(_ message: GameWebSocketMessage) async throws
}

// MARK: - WebSocket Message Sender Implementation

class WebSocketMessageSender: MessageSending {
    private let webSocket: URLSessionWebSocketTask

    init(webSocket: URLSessionWebSocketTask) {
        self.webSocket = webSocket
    }

    func sendMessage(_ message: GameWebSocketMessage) async throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(message)
        let string = String(data: data, encoding: .utf8) ?? ""

        let message = URLSessionWebSocketTask.Message.string(string)
        try await webSocket.send(message)
    }
}

// MARK: - Emote Manager Extensions

extension EmoteManager {
    /// Get emote statistics
    var emoteStatistics: EmoteStatistics {
        let activeCount = activeEmotes.count
        let queueCount = emoteQueue.count
        let recentCount = recentEmotes.count
        let rateLimitedPlayers = rateLimitTracker.count

        return EmoteStatistics(
            activeEmotes: activeCount,
            queuedEmotes: queueCount,
            recentEmotes: recentCount,
            rateLimitedPlayers: rateLimitedPlayers,
            isConnected: isConnected
        )
    }

    /// Force reconnection attempt
    func reconnect() {
        updateConnectionStatus(.reconnecting)
        // Connection logic would be handled by the WebSocket manager
    }
}

// MARK: - Emote Statistics

struct EmoteStatistics {
    let activeEmotes: Int
    let queuedEmotes: Int
    let recentEmotes: Int
    let rateLimitedPlayers: Int
    let isConnected: Bool
}

// MARK: - Mock Message Sender for Testing

class MockMessageSender: MessageSending {
    var shouldFail = false
    var delay: TimeInterval = 0
    var sentMessages: [GameWebSocketMessage] = []

    func sendMessage(_ message: GameWebSocketMessage) async throws {
        sentMessages.append(message)

        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }

        if shouldFail {
            throw URLError(.notConnectedToInternet)
        }
    }
}