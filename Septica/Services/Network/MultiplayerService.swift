//
//  MultiplayerService.swift
//  Septica
//
//  High-level service for multiplayer game operations
//  Coordinates between NetworkManager and GameState for seamless multiplayer experience
//

import Foundation
import Combine
import OSLog

/// High-level service managing multiplayer game operations
@MainActor
class MultiplayerService: ObservableObject {
    
    // MARK: - Properties
    
    /// Current multiplayer session state
    @Published private(set) var sessionState: MultiplayerSessionState = .disconnected
    
    /// Whether a game search is in progress
    @Published private(set) var isSearchingForGame: Bool = false
    
    /// Current game session information
    @Published private(set) var currentGameSession: GameSession?
    
    /// Latest game state received from server
    @Published private(set) var serverGameState: GameStatePayload?
    
    /// Connection quality indicator
    @Published private(set) var connectionQuality: ConnectionQuality = .unknown
    
    // MARK: - Dependencies
    
    private let networkManager: NetworkManager
    private let logger = Logger(subsystem: "com.septica.app", category: "MultiplayerService")
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private var gameState: GameState?
    private var localPlayerId: UUID?
    private var gameSessionId: String?
    private var lastServerSequenceNumber: Int = 0
    
    // Performance monitoring
    private var lastHeartbeatTime: Date = Date()
    private var roundTripTimes: [TimeInterval] = []
    private let maxRTTSamples = 10
    
    // MARK: - Publishers
    
    /// Publisher for game events
    private let gameEventSubject = PassthroughSubject<MultiplayerGameEvent, Never>()
    
    /// Publisher for session events
    private let sessionEventSubject = PassthroughSubject<MultiplayerSessionEvent, Never>()
    
    /// Publisher for errors
    private let errorSubject = PassthroughSubject<MultiplayerError, Never>()
    
    /// Public publisher for game events
    var gameEventPublisher: AnyPublisher<MultiplayerGameEvent, Never> {
        gameEventSubject.eraseToAnyPublisher()
    }
    
    /// Public publisher for session events
    var sessionEventPublisher: AnyPublisher<MultiplayerSessionEvent, Never> {
        sessionEventSubject.eraseToAnyPublisher()
    }
    
    /// Public publisher for errors
    var errorPublisher: AnyPublisher<MultiplayerError, Never> {
        errorSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
        setupNetworkObservers()
        logger.info("MultiplayerService initialized")
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    // MARK: - Public API
    
    /// Start multiplayer service with a game state
    /// - Parameter gameState: The game state to manage
    func startService(with gameState: GameState) {
        self.gameState = gameState
        self.localPlayerId = UUID() // Generate if not provided
        
        logger.info("Starting multiplayer service with game state: \(gameState.id)")
        
        // Connect to network if not already connected
        if networkManager.connectionStatus == .disconnected {
            networkManager.connect(playerId: localPlayerId)
        }
    }
    
    /// Stop multiplayer service
    func stopService() {
        logger.info("Stopping multiplayer service")
        
        // Leave current game if any
        if let gameSession = currentGameSession {
            leaveGame(gameSession.gameId)
        }
        
        // Disconnect from network
        networkManager.disconnect()
        
        // Reset state
        sessionState = .disconnected
        currentGameSession = nil
        serverGameState = nil
        gameState = nil
        localPlayerId = nil
    }
    
    /// Search for and join a multiplayer game
    /// - Parameter mode: Game mode to search for
    func findGame(mode: GameMode = .casual) {
        guard sessionState == .connected else {
            logger.warning("Cannot search for game while not connected")
            errorSubject.send(.notConnected)
            return
        }
        
        guard !isSearchingForGame else {
            logger.warning("Already searching for a game")
            return
        }
        
        logger.info("Searching for game with mode: \(mode.rawValue)")
        isSearchingForGame = true
        sessionState = .searchingForGame
        
        networkManager.send(.joinGame(mode: mode))
        sessionEventSubject.send(.searchingForGame)
    }
    
    /// Leave the current game
    /// - Parameter gameId: ID of the game to leave
    func leaveGame(_ gameId: UUID) {
        logger.info("Leaving game: \(gameId)")
        
        networkManager.send(.leaveGame(gameId: gameId))
        
        // Update local state
        currentGameSession = nil
        serverGameState = nil
        sessionState = .connected
        isSearchingForGame = false
        
        // Update game state
        gameState?.configureForMultiplayer(
            localPlayerId: localPlayerId ?? UUID(),
            gameSessionId: "",
            isOnline: false
        )
        gameState?.connectionStatus = .connected
        
        sessionEventSubject.send(.leftGame(gameId))
    }
    
    /// Play a card in the current game
    /// - Parameter card: The card to play
    func playCard(_ card: Card) {
        guard let gameSession = currentGameSession else {
            logger.error("Cannot play card: no active game session")
            errorSubject.send(.noActiveGame)
            return
        }
        
        guard sessionState == .inGame else {
            logger.error("Cannot play card: not in game")
            errorSubject.send(.notInGame)
            return
        }
        
        logger.info("Playing card: \(card.description)")
        networkManager.send(.playCard(card: card, gameId: gameSession.gameId))
        
        gameEventSubject.send(.cardPlayAttempted(card))
    }
    
    /// Get the current game state from server
    func requestGameState() {
        guard let gameSession = currentGameSession else {
            logger.warning("Cannot request game state: no active game session")
            return
        }
        
        networkManager.send(.getGameState(gameId: gameSession.gameId))
    }
    
    /// Send a chat message
    /// - Parameter message: The message text
    func sendChatMessage(_ message: String) {
        guard let gameSession = currentGameSession else {
            logger.warning("Cannot send chat message: no active game session")
            return
        }
        
        guard !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        networkManager.send(.chatMessage(text: message, gameId: gameSession.gameId))
    }
    
    // MARK: - Connection Quality Monitoring
    
    /// Get current connection statistics
    func getConnectionStats() -> ConnectionStats {
        let avgRTT = roundTripTimes.isEmpty ? 0 : roundTripTimes.reduce(0, +) / Double(roundTripTimes.count)
        
        return ConnectionStats(
            averageRoundTripTime: avgRTT,
            lastHeartbeatTime: lastHeartbeatTime,
            connectionQuality: connectionQuality,
            sequenceNumber: lastServerSequenceNumber
        )
    }
    
    // MARK: - Private Methods
    
    private func setupNetworkObservers() {
        // Observe connection events
        networkManager.connectionEventPublisher
            .sink { [weak self] event in
                self?.handleConnectionEvent(event)
            }
            .store(in: &cancellables)
        
        // Observe incoming messages
        networkManager.messagePublisher
            .sink { [weak self] message in
                self?.handleIncomingMessage(message)
            }
            .store(in: &cancellables)
        
        // Observe network errors
        networkManager.errorPublisher
            .sink { [weak self] error in
                self?.handleNetworkError(error)
            }
            .store(in: &cancellables)
        
        // Observe connection status changes
        networkManager.$connectionStatus
            .sink { [weak self] status in
                self?.handleConnectionStatusChange(status)
            }
            .store(in: &cancellables)
    }
    
    private func handleConnectionEvent(_ event: ConnectionEvent) {
        logger.info("Connection event: \(String(describing: event))")
        
        switch event {
        case .connected:
            sessionState = .connected
            connectionQuality = .good
            sessionEventSubject.send(.connected)
            
        case .disconnected:
            sessionState = .disconnected
            connectionQuality = .unknown
            isSearchingForGame = false
            currentGameSession = nil
            sessionEventSubject.send(.disconnected)
            
        case .reconnecting:
            sessionState = .reconnecting
            sessionEventSubject.send(.reconnecting)
            
        case .failed(let error):
            handleConnectionFailure(error)
            
        case .maxReconnectionAttemptsReached:
            sessionState = .disconnected
            connectionQuality = .poor
            errorSubject.send(.connectionFailed("Max reconnection attempts reached"))
        }
    }
    
    private func handleIncomingMessage(_ message: IncomingMessage) {
        guard let messageType = message.messageType else {
            logger.warning("Unknown message type: \(message.type)")
            return
        }
        
        logger.debug("Handling message: \(messageType.rawValue)")
        
        switch messageType {
        case .gameState:
            handleGameStateMessage(message)
        case .moveResult:
            handleMoveResultMessage(message)
        case .playerJoined:
            handlePlayerJoinedMessage(message)
        case .playerLeft:
            handlePlayerLeftMessage(message)
        case .gameEnd:
            handleGameEndMessage(message)
        case .gameStarted:
            handleGameStartedMessage(message)
        case .trickComplete:
            handleTrickCompleteMessage(message)
        case .playerTurn:
            handlePlayerTurnMessage(message)
        case .chatReceived:
            handleChatMessage(message)
        case .pong:
            handlePongMessage(message)
        default:
            // Other messages handled by NetworkManager
            break
        }
        
        updateConnectionQuality()
    }
    
    private func handleGameStateMessage(_ message: IncomingMessage) {
        do {
            let gameStatePayload = try message.parsePayload(as: GameStatePayload.self)
            serverGameState = gameStatePayload
            
            // Update sequence number
            lastServerSequenceNumber = gameStatePayload.sequenceNumber
            
            // Convert server game state to local game state
            updateLocalGameState(from: gameStatePayload)
            
            gameEventSubject.send(.gameStateUpdated(gameStatePayload))
            logger.debug("Game state updated: sequence \(gameStatePayload.sequenceNumber)")
            
        } catch {
            logger.error("Failed to parse game state message: \(error.localizedDescription)")
            errorSubject.send(.messageParsingFailed(error))
        }
    }
    
    private func handleMoveResultMessage(_ message: IncomingMessage) {
        do {
            let moveResult = try message.parsePayload(as: MoveResultPayload.self)
            gameEventSubject.send(.moveResult(moveResult))
            
            if !moveResult.valid {
                logger.warning("Move was invalid: \(moveResult.error ?? "Unknown error")")
            }
            
        } catch {
            logger.error("Failed to parse move result: \(error.localizedDescription)")
        }
    }
    
    private func handlePlayerJoinedMessage(_ message: IncomingMessage) {
        do {
            let playerJoined = try message.parsePayload(as: PlayerJoinedPayload.self)
            
            // If we're searching for a game and a player joined, we're now in a game
            if isSearchingForGame {
                let gameSession = GameSession(
                    gameId: message.gameId ?? UUID(),
                    localPlayerId: localPlayerId ?? UUID(),
                    remotePlayerId: playerJoined.playerId,
                    startTime: Date(),
                    gameMode: .casual
                )
                
                currentGameSession = gameSession
                sessionState = .inGame
                isSearchingForGame = false
                
                // Configure game state for multiplayer
                gameState?.configureForMultiplayer(
                    localPlayerId: gameSession.localPlayerId,
                    gameSessionId: gameSession.gameId.uuidString,
                    isOnline: true
                )
                
                sessionEventSubject.send(.gameStarted(gameSession))
            }
            
            gameEventSubject.send(.playerJoined(playerJoined))
            
        } catch {
            logger.error("Failed to parse player joined message: \(error.localizedDescription)")
        }
    }
    
    private func handlePlayerLeftMessage(_ message: IncomingMessage) {
        do {
            let playerLeft = try message.parsePayload(as: PlayerLeftPayload.self)
            gameEventSubject.send(.playerLeft(playerLeft))
            
            // If the other player left, end the game
            if let session = currentGameSession,
               playerLeft.playerId == session.remotePlayerId {
                endCurrentGame(reason: "Opponent disconnected")
            }
            
        } catch {
            logger.error("Failed to parse player left message: \(error.localizedDescription)")
        }
    }
    
    private func handleGameEndMessage(_ message: IncomingMessage) {
        do {
            let gameEnd = try message.parsePayload(as: GameEndPayload.self)
            gameEventSubject.send(.gameEnded(gameEnd))
            endCurrentGame(reason: gameEnd.reason)
            
        } catch {
            logger.error("Failed to parse game end message: \(error.localizedDescription)")
        }
    }
    
    private func handleGameStartedMessage(_ message: IncomingMessage) {
        sessionState = .inGame
        gameEventSubject.send(.gameReady)
        logger.info("Game started")
    }
    
    private func handleTrickCompleteMessage(_ message: IncomingMessage) {
        gameEventSubject.send(.trickCompleted)
        logger.debug("Trick completed")
    }
    
    private func handlePlayerTurnMessage(_ message: IncomingMessage) {
        if let playerId = message.playerId {
            let isLocalPlayerTurn = playerId == localPlayerId
            gameEventSubject.send(.turnChanged(playerId, isLocalPlayerTurn))
        }
    }
    
    private func handleChatMessage(_ message: IncomingMessage) {
        do {
            let chatPayload = try message.parsePayload(as: ChatMessagePayload.self)
            gameEventSubject.send(.chatMessageReceived(
                from: message.playerId ?? UUID(),
                message: chatPayload.message
            ))
        } catch {
            logger.error("Failed to parse chat message: \(error.localizedDescription)")
        }
    }
    
    private func handlePongMessage(_ message: IncomingMessage) {
        // Calculate round trip time
        let now = Date()
        let rtt = now.timeIntervalSince(lastHeartbeatTime)
        
        addRoundTripTime(rtt)
        lastHeartbeatTime = now
    }
    
    private func handleNetworkError(_ error: NetworkError) {
        logger.error("Network error: \(error.localizedDescription)")
        
        let multiplayerError: MultiplayerError
        switch error {
        case .connectionTimeout:
            multiplayerError = .connectionTimeout
        case .networkUnavailable:
            multiplayerError = .networkUnavailable
        case .serverError(let type, let message):
            multiplayerError = .serverError(type, message)
        default:
            multiplayerError = .networkError(error.localizedDescription)
        }
        
        errorSubject.send(multiplayerError)
    }
    
    private func handleConnectionStatusChange(_ status: ConnectionStatus) {
        // Update game state connection status
        gameState?.connectionStatus = status
        
        // Update local session state based on connection
        switch status {
        case .connected:
            if sessionState == .disconnected || sessionState == .reconnecting {
                sessionState = .connected
            }
        case .connecting, .reconnecting:
            sessionState = .reconnecting
        case .disconnected, .error:
            sessionState = .disconnected
            currentGameSession = nil
            isSearchingForGame = false
        }
    }
    
    private func handleConnectionFailure(_ error: NetworkError) {
        logger.error("Connection failed: \(error.localizedDescription)")
        
        sessionState = .disconnected
        connectionQuality = .poor
        
        let multiplayerError = MultiplayerError.connectionFailed(error.localizedDescription)
        errorSubject.send(multiplayerError)
        sessionEventSubject.send(.connectionFailed(multiplayerError))
    }
    
    private func updateLocalGameState(from serverState: GameStatePayload) {
        guard let gameState = gameState else { return }
        
        // Update server sequence number
        gameState.updateServerSequence(serverState.sequenceNumber)
        
        // Convert server cards to local cards
        let localCards = serverState.yourCards.compactMap { $0.toCard() }
        let tableCards = serverState.tableCards.compactMap { $0.toCard() }
        
        // Update local game state (be careful with @Published properties)
        gameState.beginBatchUpdates()
        
        // Update current player if this is our turn
        if serverState.yourTurn {
            gameState.isWaitingForPlayerInput = true
        }
        
        // Update table cards
        gameState.tableCards = tableCards
        
        // Update trick number
        gameState.trickNumber = serverState.trickNumber
        
        gameState.endBatchUpdates()
    }
    
    private func endCurrentGame(reason: String) {
        logger.info("Ending current game: \(reason)")
        
        currentGameSession = nil
        sessionState = .connected
        isSearchingForGame = false
        
        sessionEventSubject.send(.gameEnded(reason))
    }
    
    private func addRoundTripTime(_ rtt: TimeInterval) {
        roundTripTimes.append(rtt)
        if roundTripTimes.count > maxRTTSamples {
            roundTripTimes.removeFirst()
        }
    }
    
    private func updateConnectionQuality() {
        let avgRTT = roundTripTimes.isEmpty ? 0 : roundTripTimes.reduce(0, +) / Double(roundTripTimes.count)
        
        if avgRTT < 0.1 {
            connectionQuality = .excellent
        } else if avgRTT < 0.25 {
            connectionQuality = .good
        } else if avgRTT < 0.5 {
            connectionQuality = .fair
        } else {
            connectionQuality = .poor
        }
    }
}

// MARK: - Supporting Types

/// Represents a multiplayer session state
enum MultiplayerSessionState {
    case disconnected
    case connected
    case searchingForGame
    case inGame
    case reconnecting
}

/// Represents connection quality
enum ConnectionQuality {
    case unknown
    case excellent
    case good
    case fair
    case poor
    
    var description: String {
        switch self {
        case .unknown: return "Unknown"
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .fair: return "Fair"
        case .poor: return "Poor"
        }
    }
}

/// Represents a game session
struct GameSession {
    let gameId: UUID
    let localPlayerId: UUID
    let remotePlayerId: UUID
    let startTime: Date
    let gameMode: GameMode
}

/// Connection statistics
struct ConnectionStats {
    let averageRoundTripTime: TimeInterval
    let lastHeartbeatTime: Date
    let connectionQuality: ConnectionQuality
    let sequenceNumber: Int
}

/// Multiplayer game events
enum MultiplayerGameEvent {
    case gameStateUpdated(GameStatePayload)
    case moveResult(MoveResultPayload)
    case playerJoined(PlayerJoinedPayload)
    case playerLeft(PlayerLeftPayload)
    case gameEnded(GameEndPayload)
    case gameReady
    case trickCompleted
    case turnChanged(UUID, Bool) // playerId, isLocalPlayer
    case chatMessageReceived(from: UUID, message: String)
    case cardPlayAttempted(Card)
}

/// Multiplayer session events
enum MultiplayerSessionEvent {
    case connected
    case disconnected
    case reconnecting
    case searchingForGame
    case gameStarted(GameSession)
    case leftGame(UUID)
    case gameEnded(String)
    case connectionFailed(MultiplayerError)
}

/// Multiplayer-specific errors
enum MultiplayerError: Error, LocalizedError {
    case notConnected
    case noActiveGame
    case notInGame
    case connectionTimeout
    case networkUnavailable
    case connectionFailed(String)
    case serverError(String, String)
    case networkError(String)
    case messageParsingFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Not connected to server"
        case .noActiveGame:
            return "No active game session"
        case .notInGame:
            return "Not currently in a game"
        case .connectionTimeout:
            return "Connection timeout"
        case .networkUnavailable:
            return "Network unavailable"
        case .connectionFailed(let message):
            return "Connection failed: \(message)"
        case .serverError(_, let message):
            return "Server error: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .messageParsingFailed(let error):
            return "Failed to parse message: \(error.localizedDescription)"
        }
    }
}