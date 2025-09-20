//
//  NetworkCoordinator.swift
//  Septica
//
//  Coordinates networking services with the existing GameState
//  Provides a unified interface for multiplayer functionality
//

import Foundation
import Combine
import OSLog

/// Coordinator that integrates networking services with the game state
@MainActor
class NetworkCoordinator: ObservableObject {
    
    // MARK: - Properties
    
    /// Whether multiplayer is currently enabled
    @Published private(set) var isMultiplayerEnabled: Bool = false
    
    /// Current connection status
    @Published var connectionStatus: ConnectionStatus = .disconnected
    
    /// Latest multiplayer session state
    @Published var sessionState: MultiplayerSessionState = .disconnected
    
    /// Connection quality indicator
    @Published var connectionQuality: ConnectionQuality = .unknown
    
    // MARK: - Dependencies
    
    private let networkManager: NetworkManager
    private let multiplayerService: MultiplayerService
    private let logger = Logger(subsystem: "com.septica.app", category: "NetworkCoordinator")
    
    // MARK: - Private Properties
    
    private var gameState: GameState?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(baseURL: URL = URL(string: "ws://localhost:8080")!) {
        self.networkManager = NetworkManager(baseURL: baseURL)
        self.multiplayerService = MultiplayerService(networkManager: networkManager)
        
        setupObservers()
        logger.info("NetworkCoordinator initialized")
    }
    
    convenience init() {
        // Default to localhost for development
        self.init(baseURL: URL(string: "ws://localhost:8080")!)
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    // MARK: - Public API
    
    /// Enable multiplayer for a game state
    /// - Parameter gameState: The game state to enable multiplayer for
    func enableMultiplayer(for gameState: GameState) {
        logger.info("Enabling multiplayer for game state: \(gameState.id)")
        
        self.gameState = gameState
        self.isMultiplayerEnabled = true
        
        // Configure game state for multiplayer
        let localPlayerId = UUID()
        gameState.configureForMultiplayer(
            localPlayerId: localPlayerId,
            gameSessionId: "",
            isOnline: true
        )
        
        // Start multiplayer service
        multiplayerService.startService(with: gameState)
        
        // Sync connection status
        syncConnectionStatus()
    }
    
    /// Disable multiplayer
    func disableMultiplayer() {
        logger.info("Disabling multiplayer")
        
        multiplayerService.stopService()
        
        // Reset game state multiplayer configuration
        gameState?.isMultiplayer = false
        gameState?.isOnlineGame = false
        gameState?.connectionStatus = .disconnected
        
        self.isMultiplayerEnabled = false
        self.gameState = nil
        
        syncConnectionStatus()
    }
    
    /// Find and join a multiplayer game
    /// - Parameter mode: Game mode to search for
    func findGame(mode: GameMode = .casual) {
        guard isMultiplayerEnabled else {
            logger.warning("Cannot find game: multiplayer not enabled")
            return
        }
        
        multiplayerService.findGame(mode: mode)
    }
    
    /// Leave the current game
    func leaveCurrentGame() {
        guard let gameState = gameState,
              let gameSessionId = gameState.gameSessionId,
              let gameId = UUID(uuidString: gameSessionId) else {
            logger.warning("Cannot leave game: no active game session")
            return
        }
        
        multiplayerService.leaveGame(gameId)
    }
    
    /// Play a card in multiplayer mode
    /// - Parameter card: The card to play
    /// - Returns: Whether the card play was successfully sent
    @discardableResult
    func playCard(_ card: Card) -> Bool {
        guard isMultiplayerEnabled else {
            logger.warning("Cannot play card: multiplayer not enabled")
            return false
        }
        
        guard let gameState = gameState,
              gameState.isLocalPlayerTurn else {
            logger.warning("Cannot play card: not local player's turn")
            return false
        }
        
        multiplayerService.playCard(card)
        return true
    }
    
    /// Send a chat message
    /// - Parameter message: The message to send
    func sendChatMessage(_ message: String) {
        guard isMultiplayerEnabled else { return }
        multiplayerService.sendChatMessage(message)
    }
    
    /// Get current connection statistics
    func getConnectionStats() -> ConnectionStats {
        return multiplayerService.getConnectionStats()
    }
    
    /// Force reconnection
    func reconnect() {
        networkManager.reconnect()
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        // Observe connection status changes
        networkManager.$connectionStatus
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.connectionStatus = status
                self?.syncConnectionStatus()
            }
            .store(in: &cancellables)
        
        // Observe session state changes
        multiplayerService.$sessionState
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.sessionState = state
            }
            .store(in: &cancellables)
        
        // Observe connection quality changes
        multiplayerService.$connectionQuality
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] quality in
                self?.connectionQuality = quality
            }
            .store(in: &cancellables)
        
        // Observe multiplayer game events
        multiplayerService.gameEventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handleGameEvent(event)
            }
            .store(in: &cancellables)
        
        // Observe multiplayer session events
        multiplayerService.sessionEventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handleSessionEvent(event)
            }
            .store(in: &cancellables)
        
        // Observe multiplayer errors
        multiplayerService.errorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.handleMultiplayerError(error)
            }
            .store(in: &cancellables)
    }
    
    private func syncConnectionStatus() {
        guard let gameState = gameState else { return }
        
        // Sync connection status to game state
        gameState.connectionStatus = connectionStatus
        
        logger.debug("Synced connection status to game state: \(connectionStatus)")
    }
    
    private func handleGameEvent(_ event: MultiplayerGameEvent) {
        logger.debug("Handling game event: \(String(describing: event))")
        
        guard let gameState = gameState else { return }
        
        switch event {
        case .gameStateUpdated(let serverState):
            updateGameStateFromServer(gameState, serverState: serverState)
            
        case .moveResult(let result):
            handleMoveResult(gameState, result: result)
            
        case .playerJoined(let playerJoined):
            handlePlayerJoined(gameState, playerJoined: playerJoined)
            
        case .playerLeft(let playerLeft):
            handlePlayerLeft(gameState, playerLeft: playerLeft)
            
        case .gameEnded(let gameEnd):
            handleGameEnded(gameState, gameEnd: gameEnd)
            
        case .gameReady:
            handleGameReady(gameState)
            
        case .trickCompleted:
            // Trick completion is handled by the server game state update
            break
            
        case .turnChanged(let playerId, let isLocalPlayer):
            handleTurnChanged(gameState, playerId: playerId, isLocalPlayer: isLocalPlayer)
            
        case .chatMessageReceived(from: let playerId, message: let message):
            handleChatMessage(from: playerId, message: message)
            
        case .cardPlayAttempted(let card):
            // Card play attempt logged, wait for move result
            logger.debug("Card play attempted: \(card.description)")
        }
    }
    
    private func handleSessionEvent(_ event: MultiplayerSessionEvent) {
        logger.info("Handling session event: \(String(describing: event))")
        
        guard let gameState = gameState else { return }
        
        switch event {
        case .connected:
            gameState.connectionStatus = .connected
            
        case .disconnected:
            gameState.connectionStatus = .disconnected
            gameState.gameSessionId = nil
            
        case .reconnecting:
            gameState.connectionStatus = .reconnecting
            
        case .searchingForGame:
            logger.info("Searching for multiplayer game...")
            
        case .gameStarted(let session):
            handleGameStarted(gameState, session: session)
            
        case .leftGame(let gameId):
            handleLeftGame(gameState, gameId: gameId)
            
        case .gameEnded(let reason):
            handleSessionGameEnded(gameState, reason: reason)
            
        case .connectionFailed(let error):
            handleConnectionFailed(gameState, error: error)
        }
    }
    
    private func handleMultiplayerError(_ error: MultiplayerError) {
        logger.error("Multiplayer error: \(error.localizedDescription)")
        
        // Convert multiplayer errors to game events if needed
        switch error {
        case .connectionTimeout, .networkUnavailable, .connectionFailed:
            gameState?.connectionStatus = .error
            
        default:
            break
        }
    }
    
    // MARK: - Game Event Handlers
    
    private func updateGameStateFromServer(_ gameState: GameState, serverState: GameStatePayload) {
        logger.debug("Updating game state from server data")
        
        // Update server sequence number
        gameState.updateServerSequence(serverState.sequenceNumber)
        
        // Convert server cards to local cards
        let yourCards = serverState.yourCards.compactMap { $0.toCard() }
        let tableCards = serverState.tableCards.compactMap { $0.toCard() }
        
        // Update game state with batch updates for performance
        gameState.beginBatchUpdates()
        
        // Update table cards
        gameState.tableCards = tableCards
        
        // Update trick number
        gameState.trickNumber = serverState.trickNumber
        
        // Update current player turn state
        gameState.isWaitingForPlayerInput = serverState.yourTurn
        
        // Update local player's hand if provided
        if let localPlayer = gameState.players.first(where: { $0.id == gameState.localPlayerId }) {
            localPlayer.hand = yourCards
        }
        
        gameState.endBatchUpdates()
    }
    
    private func handleMoveResult(_ gameState: GameState, result: MoveResultPayload) {
        if !result.valid {
            logger.warning("Move was rejected by server: \(result.error ?? "Unknown error")")
            // Could show error to user here
        } else {
            logger.debug("Move accepted by server")
        }
        
        // If trick is complete, the server will send updated game state
        if result.trickComplete {
            logger.debug("Trick completed")
        }
        
        // If game is complete, handle game end
        if result.gameComplete {
            logger.info("Game completed")
            if let winnerId = result.winnerId {
                logger.info("Winner: \(winnerId)")
            }
        }
    }
    
    private func handlePlayerJoined(_ gameState: GameState, playerJoined: PlayerJoinedPayload) {
        logger.info("Player joined: \(playerJoined.playerId)")
        
        // Create or update player in game state if needed
        if !gameState.players.contains(where: { $0.id == playerJoined.playerId }) {
            let newPlayer = Player(
                name: playerJoined.username ?? "Opponent",
                id: playerJoined.playerId
            )
            gameState.players.append(newPlayer)
        }
    }
    
    private func handlePlayerLeft(_ gameState: GameState, playerLeft: PlayerLeftPayload) {
        logger.info("Player left: \(playerLeft.playerId), reason: \(playerLeft.reason ?? "unknown")")
        
        // Remove player from game state if needed
        gameState.players.removeAll { $0.id == playerLeft.playerId }
    }
    
    private func handleGameEnded(_ gameState: GameState, gameEnd: GameEndPayload) {
        logger.info("Game ended: \(gameEnd.reason)")
        
        // Create game result
        let result = GameResult(
            winnerId: gameEnd.winnerId,
            finalScores: gameEnd.finalScore.compactMapValues { Int($0) }.reduce(into: [:]) { dict, pair in
                if let uuid = UUID(uuidString: pair.key) {
                    dict[uuid] = pair.value
                }
            },
            totalTricks: gameEnd.gameStats?.totalTricks ?? 0,
            gameDuration: TimeInterval((gameEnd.gameStats?.durationMs ?? 0) / 1000)
        )
        
        gameState.gameResult = result
        gameState.phase = .finished
    }
    
    private func handleGameReady(_ gameState: GameState) {
        logger.info("Game is ready to start")
        gameState.phase = .playing
    }
    
    private func handleTurnChanged(_ gameState: GameState, playerId: UUID, isLocalPlayer: Bool) {
        logger.debug("Turn changed to player: \(playerId), isLocal: \(isLocalPlayer)")
        
        // Update current player index if we can find the player
        if let playerIndex = gameState.players.firstIndex(where: { $0.id == playerId }) {
            gameState.currentPlayerIndex = playerIndex
        }
        
        gameState.isWaitingForPlayerInput = isLocalPlayer
    }
    
    private func handleChatMessage(from playerId: UUID, message: String) {
        logger.debug("Received chat message from \(playerId): \(message)")
        // Could forward to a chat system here
    }
    
    // MARK: - Session Event Handlers
    
    private func handleGameStarted(_ gameState: GameState, session: GameSession) {
        logger.info("Game session started: \(session.gameId)")
        
        gameState.gameSessionId = session.gameId.uuidString
        gameState.localPlayerId = session.localPlayerId
        gameState.phase = .playing
        
        // Ensure we have both players in the game state
        if gameState.players.count < 2 {
            // Add local player if not present
            if !gameState.players.contains(where: { $0.id == session.localPlayerId }) {
                let localPlayer = Player(name: "You", id: session.localPlayerId)
                gameState.players.append(localPlayer)
            }
            
            // Add remote player if not present
            if !gameState.players.contains(where: { $0.id == session.remotePlayerId }) {
                let remotePlayer = Player(name: "Opponent", id: session.remotePlayerId)
                gameState.players.append(remotePlayer)
            }
        }
        
        // Request initial game state from server
        multiplayerService.requestGameState()
    }
    
    private func handleLeftGame(_ gameState: GameState, gameId: UUID) {
        logger.info("Left game: \(gameId)")
        
        gameState.gameSessionId = nil
        gameState.phase = .setup
        
        // Reset multiplayer state but keep it enabled
        gameState.isMultiplayer = true
        gameState.isOnlineGame = true
    }
    
    private func handleSessionGameEnded(_ gameState: GameState, reason: String) {
        logger.info("Session game ended: \(reason)")
        
        if gameState.gameResult == nil {
            // Create a default game result if none was provided
            let result = GameResult(
                winnerId: nil,
                finalScores: [:],
                totalTricks: gameState.trickHistory.count,
                gameDuration: Date().timeIntervalSince(gameState.createdAt)
            )
            gameState.gameResult = result
        }
        
        gameState.phase = .finished
    }
    
    private func handleConnectionFailed(_ gameState: GameState, error: MultiplayerError) {
        logger.error("Connection failed: \(error.localizedDescription)")
        
        gameState.connectionStatus = .error
        
        // If we're in a game, pause it
        if gameState.phase == .playing {
            gameState.phase = .paused
        }
    }
}

// MARK: - Extensions

extension NetworkCoordinator {
    
    /// Convenience method to check if ready for multiplayer
    var isReadyForMultiplayer: Bool {
        return isMultiplayerEnabled && 
               connectionStatus == .connected && 
               sessionState == .connected
    }
    
    /// Convenience method to check if currently in a game
    var isInGame: Bool {
        return isMultiplayerEnabled && sessionState == .inGame
    }
    
    /// Convenience method to check if searching for a game
    var isSearchingForGame: Bool {
        return isMultiplayerEnabled && sessionState == .searchingForGame
    }
}