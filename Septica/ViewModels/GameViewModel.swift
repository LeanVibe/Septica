//
//  GameViewModel.swift
//  Septica
//
//  Main view model for game state management and UI coordination
//  Manages game flow, player interactions, and state updates
//

import Foundation
import Combine
import OSLog

/// Main view model for the Septica game interface
@MainActor
class GameViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var gameState: GameState
    @Published var statusMessage: String?
    @Published var isProcessingMove = false
    @Published var showingError = false
    @Published var errorMessage = ""
    
    // MARK: - Private Properties
    
    var cancellables = Set<AnyCancellable>()
    private let aiMoveDelay: TimeInterval = 1.5
    private let logger = Logger(subsystem: "com.septica.app", category: "GameViewModel")
    
    // MARK: - Multiplayer Properties
    
    /// Network manager for WebSocket connections
    private let networkManager: NetworkManager
    
    /// Multiplayer service for coordinating online games
    private let multiplayerService: MultiplayerService
    
    /// Whether this is an online multiplayer game
    @Published var isOnlineGame: Bool = false
    
    /// Current multiplayer session state
    @Published var multiplayerSessionState: MultiplayerSessionState = .disconnected
    
    /// Connection quality indicator
    @Published var connectionQuality: ConnectionQuality = .unknown
    
    // Performance monitoring for 60 FPS targets
    @Published var performanceMonitor = PerformanceMonitor()
    
    // Achievement system integration
    let achievementManager = AchievementManager.shared
    @Published var showingAchievementUnlock = false
    @Published var unlockedAchievement: RomanianAchievement?
    
    // Romanian Arena System Integration
    @Published var currentArena: RomanianArena? = .sateImarica
    @Published var gamePhase: GamePhase = .setup
    
    // Romanian Character System Integration
    @Published var currentOpponentAvatar: RomanianCharacterAvatar = .villageElder
    @Published var currentPlayerAvatar: RomanianCharacterAvatar = .traditionalPlayer
    
    enum GamePhase {
        case setup, playing, gameOver
    }
    
    // MARK: - Computed Properties
    
    /// Current players in the game
    var players: [Player] {
        return gameState.players
    }
    
    /// Current player whose turn it is
    var currentPlayer: Player? {
        return gameState.currentPlayer
    }
    
    /// Index of the current player
    var currentPlayerIndex: Int {
        return gameState.currentPlayerIndex
    }
    
    /// Cards currently on the table
    var tableCards: [Card] {
        return gameState.tableCards
    }
    
    /// Valid moves for the current player
    var validMoves: [Card] {
        return gameState.validMovesForCurrentPlayer()
    }
    
    /// Whether it's the human player's turn
    var isHumanPlayerTurn: Bool {
        return currentPlayer?.isHuman == true
    }
    
    /// Whether the human player can make a move
    var canHumanPlayerMove: Bool {
        return isHumanPlayerTurn && !validMoves.isEmpty && !isProcessingMove
    }
    
    /// Get the human player (first human found)
    var humanPlayer: Player? {
        return players.first { $0.isHuman }
    }
    
    /// Get player scores as a dictionary
    var playerScores: [String: Int] {
        return Dictionary(uniqueKeysWithValues: players.map { ($0.name, $0.score) })
    }
    
    // MARK: - Initialization
    
    init(gameState: GameState, networkManager: NetworkManager? = nil, isOnline: Bool = false) {
        self.gameState = gameState
        self.isOnlineGame = isOnline
        
        // Initialize networking components
        self.networkManager = networkManager ?? NetworkManager()
        self.multiplayerService = MultiplayerService(networkManager: self.networkManager)
        
        setupBindings()
        setupPerformanceMonitoring()
        
        if isOnline {
            setupMultiplayerBindings()
        }
        
        logger.info("GameViewModel initialized (online: \(isOnline))")
    }
    
    convenience init() {
        let gameState = GameState()
        self.init(gameState: gameState, isOnline: false)
    }
    
    convenience init(onlineGame gameState: GameState) {
        self.init(gameState: gameState, isOnline: true)
    }
    
    deinit {
        Task { @MainActor in
            await self.performanceMonitor.stopMonitoring()
        }
        
        // Clean up multiplayer service
        if isOnlineGame {
            multiplayerService.stopService()
        }
    }
    
    /// Set up reactive bindings and observers
    private func setupBindings() {
        // Observe game state changes with safety checks
        gameState.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self = self else { return }
                
                // Record frame with safety check
                do {
                    self.performanceMonitor.recordFrame()
                } catch {
                    print("Performance monitor frame recording failed: \(error)")
                }
                
                self.objectWillChange.send()
                self.handleGameStateChange()
            }
            .store(in: &cancellables)
    }
    
    /// Set up performance monitoring for 60 FPS targets
    private func setupPerformanceMonitoring() {
        // Add safety check to prevent crashes
        do {
            performanceMonitor.startMonitoring()
            
            // Monitor for memory warnings and performance issues
            NotificationCenter.default.publisher(for: .performanceMemoryWarning)
                .sink { [weak self] _ in
                    self?.handlePerformanceMemoryWarning()
                }
                .store(in: &cancellables)
        } catch {
            print("Performance monitoring failed to start: \(error)")
            // Continue without performance monitoring to prevent crashes
        }
    }
    
    /// Set up reactive bindings for multiplayer events
    private func setupMultiplayerBindings() {
        logger.info("Setting up multiplayer bindings")
        
        // Start multiplayer service with game state
        multiplayerService.startService(with: gameState)
        
        // Observe multiplayer session state changes
        multiplayerService.$sessionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.multiplayerSessionState = state
                self?.handleMultiplayerSessionStateChange(state)
            }
            .store(in: &cancellables)
        
        // Observe connection quality changes
        multiplayerService.$connectionQuality
            .receive(on: DispatchQueue.main)
            .sink { [weak self] quality in
                self?.connectionQuality = quality
            }
            .store(in: &cancellables)
        
        // Observe game events from multiplayer service
        multiplayerService.gameEventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handleMultiplayerGameEvent(event)
            }
            .store(in: &cancellables)
        
        // Observe session events from multiplayer service
        multiplayerService.sessionEventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handleMultiplayerSessionEvent(event)
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
    
    // MARK: - Game Management
    
    /// Start a new game
    func startNewGame() {
        gameState.setupNewGame()
        statusMessage = "New game started!"
        
        // Clear any error states
        showingError = false
        errorMessage = ""
        
        // If AI goes first, make their move
        checkForAIMove()
        
        // Clear status message after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if self.statusMessage == "New game started!" {
                self.statusMessage = nil
            }
        }
    }
    
    /// Start the current game (if not already started)
    func startGame() {
        if gameState.phase == .setup {
            gameState.phase = .playing
        }
        checkForAIMove()
    }
    
    /// Play a card for the human player
    func playCard(_ card: Card) {
        guard let humanPlayer = humanPlayer else { return }
        guard canPlayCard(card) else { return }
        
        isProcessingMove = true
        statusMessage = "Playing \(card.displayName)..."
        
        // Handle online vs offline gameplay
        if isOnlineGame {
            // Send move to server via multiplayer service
            multiplayerService.playCard(card)
            
            // Track achievements for the played card
            trackCardPlayAchievements(card: card, player: humanPlayer)
            
        } else {
            // Local offline gameplay
            let result = gameState.playCard(card, by: humanPlayer.id)
            
            switch result {
            case .success:
                statusMessage = "\(humanPlayer.name) played \(card.displayName)"
                
                // Track achievements for the played card
                trackCardPlayAchievements(card: card, player: humanPlayer)
                
                // Check for AI move after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.checkForAIMove()
                }
                
            case .failure(let error):
                handlePlayError(error)
                isProcessingMove = false
                return
            }
        }
        
        // Clear status after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if self.statusMessage?.contains("played") == true {
                self.statusMessage = nil
                self.isProcessingMove = false
            }
        }
    }
    
    /// Check if a card can be played
    func canPlayCard(_ card: Card) -> Bool {
        guard !isProcessingMove else { return false }
        guard isHumanPlayerTurn else { return false }
        
        return validMoves.contains { validCard in
            validCard.suit == card.suit && validCard.value == card.value
        }
    }
    
    // MARK: - AI Management
    
    /// Check if it's an AI player's turn and make their move
    private func checkForAIMove() {
        // Skip AI moves in online games - server handles this
        guard !isOnlineGame else { return }
        
        guard let currentPlayer = currentPlayer,
              !currentPlayer.isHuman,
              gameState.phase == .playing else { return }
        
        guard !validMoves.isEmpty else {
            // AI has no valid moves, skip turn
            gameState.skipCurrentPlayer()
            checkForAIMove()
            return
        }
        
        statusMessage = "\(currentPlayer.name) is thinking..."
        
        Task {
            // Add delay for realistic AI behavior
            try? await Task.sleep(nanoseconds: UInt64(aiMoveDelay * 1_000_000_000))
            
            // Track AI decision performance
            let aiDecisionStartTime = Date()
            
            if let cardToPlay = await currentPlayer.chooseCard(gameState: gameState, validMoves: validMoves) {
                // Record AI decision time for performance monitoring
                let aiDecisionTime = Date().timeIntervalSince(aiDecisionStartTime)
                await MainActor.run {
                    self.performanceMonitor.recordAIDecision(duration: aiDecisionTime)
                }
                await MainActor.run {
                    let result = gameState.playCard(cardToPlay, by: currentPlayer.id)
                    
                    switch result {
                    case .success:
                        statusMessage = "\(currentPlayer.name) played \(cardToPlay.displayName)"
                        
                        // Continue with next player after delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.checkForAIMove()
                        }
                        
                    case .failure(let error):
                        handlePlayError(error)
                    }
                }
            }
            
            // Clear status after delay
            await MainActor.run {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    if self.statusMessage?.contains("played") == true || 
                       self.statusMessage?.contains("thinking") == true {
                        self.statusMessage = nil
                    }
                }
            }
        }
    }
    
    // MARK: - Game State Management
    
    /// Handle changes to the game state
    private func handleGameStateChange() {
        // Check for game end
        if gameState.phase == .finished {
            handleGameEnd()
        }
        
        // Update status based on current state
        updateStatusMessage()
    }
    
    /// Handle game completion
    private func handleGameEnd() {
        guard let result = gameState.gameResult else { return }
        
        if let winnerId = result.winnerId,
           let winner = players.first(where: { $0.id == winnerId }) {
            statusMessage = "🎉 \(winner.name) wins with \(result.winningScore ?? 0) points!"
        } else {
            statusMessage = "🤝 It's a tie!"
        }
        
        // Track game completion achievements
        trackGameCompletionAchievements()
    }
    
    /// Update status message based on current game state
    private func updateStatusMessage() {
        // Don't override specific messages
        guard statusMessage?.contains("played") != true &&
              statusMessage?.contains("thinking") != true &&
              statusMessage?.contains("wins") != true else { return }
        
        if gameState.phase == .finished {
            return // Keep game end message
        }
        
        if let currentPlayer = currentPlayer {
            if currentPlayer.isHuman {
                if validMoves.isEmpty {
                    statusMessage = "You have no valid moves"
                } else {
                    statusMessage = "Your turn - select a card to play"
                }
            } else {
                statusMessage = "\(currentPlayer.name)'s turn"
            }
        }
    }
    
    // MARK: - Error Handling
    
    /// Handle play errors
    private func handlePlayError(_ error: PlayError) {
        errorMessage = error.localizedDescription
        showingError = true
        statusMessage = "Invalid move"
        
        // Clear error after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.showingError = false
            self.statusMessage = nil
        }
    }
    
    /// Dismiss current error
    func dismissError() {
        showingError = false
        errorMessage = ""
    }
    
    // MARK: - Performance Management
    
    /// Handle performance memory warnings
    private func handlePerformanceMemoryWarning() {
        // Clear any non-essential caches
        statusMessage = "⚠️ Low memory - optimizing performance..."
        
        // Reduce AI thinking time temporarily
        let originalDelay = aiMoveDelay
        // Restore after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            if self.statusMessage?.contains("Low memory") == true {
                self.statusMessage = nil
            }
        }
    }
    
    /// Get current performance status
    func getPerformanceStatus() -> DevicePerformanceStatus {
        return performanceMonitor.getDevicePerformanceStatus()
    }
    
    /// Get detailed performance report
    func getPerformanceReport() -> PerformanceReport {
        return performanceMonitor.getPerformanceReport()
    }
    
    // MARK: - Achievement System Integration
    
    /// Track achievements related to card play
    private func trackCardPlayAchievements(card: Card, player: Player) {
        guard player.isHuman else { return }
        
        Task { @MainActor in
            // Track seven plays
            if card.value == 7 {
                achievementManager.trackEvent(.playedSevenCard)
            }
            
            // Track strategic plays (high-value cards)
            if card.isPointCard {
                achievementManager.trackEvent(.playedPointCard)
            }
            
            // Track specific card types
            if card.value == 8 && tableCards.count % 3 == 0 {
                achievementManager.trackEvent(.perfectTiming)
            }
            
            // Track consecutive games
            achievementManager.trackEvent(.gameStarted)
            
            // Check for newly unlocked achievements
            checkForUnlockedAchievements()
        }
    }
    
    /// Track achievements related to game completion
    func trackGameCompletionAchievements() {
        guard let result = gameState.gameResult,
              let humanPlayer = humanPlayer else { return }
        
        Task { @MainActor in
            // Track game completion
            achievementManager.trackEvent(.gameCompleted)
            
            // Track wins
            if result.winnerId == humanPlayer.id {
                achievementManager.trackEvent(.gameWon)
                
                // Track specific win conditions
                if let score = result.winningScore {
                    if score >= 50 {
                        achievementManager.trackEvent(.dominantVictory)
                    }
                }
            }
            
            // Track cultural learning moments (based on character interactions)
            achievementManager.trackEvent(.culturalInteraction)
            
            // Check for newly unlocked achievements
            checkForUnlockedAchievements()
        }
    }
    
    /// Check for any newly unlocked achievements and display them
    private func checkForUnlockedAchievements() {
        if let newlyUnlocked = achievementManager.getRecentlyUnlockedAchievements().first {
            unlockedAchievement = newlyUnlocked
            showingAchievementUnlock = true
        }
    }
    
    
    /// Dismiss achievement unlock overlay
    func dismissAchievementUnlock() {
        showingAchievementUnlock = false
        unlockedAchievement = nil
    }
    
    // MARK: - Multiplayer Methods
    
    /// Start searching for an online game
    func findOnlineGame(mode: GameMode = .casual) {
        guard isOnlineGame else {
            logger.warning("Cannot find online game - not in online mode")
            return
        }
        
        logger.info("Starting search for online game")
        statusMessage = "Searching for opponent..."
        multiplayerService.findGame(mode: mode)
    }
    
    /// Leave the current online game
    func leaveOnlineGame() {
        guard isOnlineGame,
              let currentSession = multiplayerService.currentGameSession else {
            logger.warning("Cannot leave game - no active session")
            return
        }
        
        logger.info("Leaving online game")
        statusMessage = "Leaving game..."
        multiplayerService.leaveGame(currentSession.gameId)
    }
    
    /// Get connection statistics for display
    func getConnectionStats() -> ConnectionStats? {
        guard isOnlineGame else { return nil }
        return multiplayerService.getConnectionStats()
    }
    
    // MARK: - Multiplayer Event Handlers
    
    private func handleMultiplayerSessionStateChange(_ state: MultiplayerSessionState) {
        logger.info("Multiplayer session state changed: \(state)")
        
        switch state {
        case .disconnected:
            statusMessage = "Disconnected from server"
        case .connected:
            statusMessage = "Connected to server"
        case .searchingForGame:
            statusMessage = "Searching for opponent..."
        case .inGame:
            statusMessage = "Game in progress"
        case .reconnecting:
            statusMessage = "Reconnecting..."
        }
    }
    
    private func handleMultiplayerGameEvent(_ event: MultiplayerGameEvent) {
        logger.debug("Handling multiplayer game event: \(String(describing: event))")
        
        switch event {
        case .gameStateUpdated(let serverGameState):
            handleServerGameStateUpdate(serverGameState)
            
        case .moveResult(let moveResult):
            handleServerMoveResult(moveResult)
            
        case .playerJoined(let playerJoined):
            statusMessage = "Player \(playerJoined.username ?? "Unknown") joined"
            
        case .playerLeft(let playerLeft):
            statusMessage = "Player left the game"
            
        case .gameEnded(let gameEnd):
            handleGameEnd(gameEnd)
            
        case .gameReady:
            statusMessage = "Game is ready!"
            
        case .trickCompleted:
            statusMessage = "Trick completed"
            
        case .turnChanged(let playerId, let isLocalPlayer):
            if isLocalPlayer {
                statusMessage = "Your turn"
                isWaitingForPlayerInput = true
            } else {
                statusMessage = "Opponent's turn"
                isWaitingForPlayerInput = false
            }
            
        case .chatMessageReceived(let from, let message):
            // Handle chat message (could show in UI)
            logger.info("Chat message from \(from): \(message)")
            
        case .cardPlayAttempted(let card):
            logger.debug("Card play attempted: \(card.displayName)")
        }
    }
    
    private func handleMultiplayerSessionEvent(_ event: MultiplayerSessionEvent) {
        logger.info("Handling multiplayer session event: \(String(describing: event))")
        
        switch event {
        case .connected:
            statusMessage = "Connected to server"
            
        case .disconnected:
            statusMessage = "Disconnected from server"
            
        case .reconnecting:
            statusMessage = "Reconnecting..."
            
        case .searchingForGame:
            statusMessage = "Searching for opponent..."
            
        case .gameStarted(let session):
            statusMessage = "Game started!"
            logger.info("Game started with session: \(session.gameId)")
            
        case .leftGame(let gameId):
            statusMessage = "Left the game"
            logger.info("Left game: \(gameId)")
            
        case .gameEnded(let reason):
            statusMessage = "Game ended: \(reason)"
            
        case .connectionFailed(let error):
            statusMessage = "Connection failed"
            handleMultiplayerError(error)
        }
    }
    
    private func handleMultiplayerError(_ error: MultiplayerError) {
        logger.error("Multiplayer error: \(error.localizedDescription)")
        
        errorMessage = error.localizedDescription
        showingError = true
        
        // Clear error after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.showingError = false
            self.errorMessage = ""
        }
    }
    
    private func handleServerGameStateUpdate(_ serverState: GameStatePayload) {
        logger.debug("Updating local game state from server")
        
        // The MultiplayerService already updates the local game state
        // We just need to update UI-specific properties
        
        statusMessage = serverState.yourTurn ? "Your turn" : "Opponent's turn"
        isWaitingForPlayerInput = serverState.yourTurn
        
        // Update processing state
        if !serverState.yourTurn {
            isProcessingMove = false
        }
    }
    
    private func handleServerMoveResult(_ moveResult: MoveResultPayload) {
        isProcessingMove = false
        
        if moveResult.valid {
            statusMessage = "Move accepted"
            
            if moveResult.trickComplete {
                statusMessage = "Trick completed"
            }
            
            if moveResult.gameComplete {
                statusMessage = "Game completed"
                if let winnerId = moveResult.winnerId {
                    // Determine if local player won
                    let localPlayerId = gameState.localPlayerId
                    if winnerId == localPlayerId {
                        statusMessage = "🎉 You won!"
                    } else {
                        statusMessage = "Game over - Opponent won"
                    }
                }
            }
        } else {
            statusMessage = "Invalid move: \(moveResult.error ?? "Unknown error")"
            errorMessage = moveResult.error ?? "Invalid move"
            showingError = true
        }
        
        // Clear status after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if self.statusMessage?.contains("Move") == true ||
               self.statusMessage?.contains("Invalid") == true {
                self.statusMessage = nil
            }
            self.showingError = false
        }
    }
    
    private func handleGameEnd(_ gameEnd: GameEndPayload) {
        logger.info("Game ended: \(gameEnd.reason)")
        
        gameState.phase = .finished
        
        // Determine winner message
        if let winnerId = gameEnd.winnerId {
            let localPlayerId = gameState.localPlayerId
            if winnerId == localPlayerId {
                statusMessage = "🎉 You won the game!"
            } else {
                statusMessage = "Game over - Opponent won"
            }
        } else {
            statusMessage = "Game ended in a tie"
        }
        
        // Track achievements for game completion
        trackGameCompletionAchievements()
    }
}

// MARK: - Game Setup Extensions

extension GameViewModel {
    
    /// Set up a game with specific players
    func setupGame(with players: [Player]) {
        gameState.players = players
        gameState.setupNewGame()
    }
    
    /// Add a player to the current game
    func addPlayer(_ player: Player) {
        guard gameState.players.count < GameRules.maxPlayers else { return }
        gameState.players.append(player)
    }
    
    /// Create a standard single-player game against AI
    func setupSinglePlayerGame(playerName: String, aiDifficulty: AIDifficulty = .medium) {
        let humanPlayer = Player(name: playerName)
        let aiPlayer = AIPlayer(name: "Computer", difficulty: aiDifficulty)
        
        setupGame(with: [humanPlayer, aiPlayer])
    }
    
    /// Create a two-player human game
    func setupTwoPlayerGame(player1Name: String, player2Name: String) {
        let player1 = Player(name: player1Name)
        let player2 = Player(name: player2Name)
        
        setupGame(with: [player1, player2])
    }
    
    /// Setup an online multiplayer game
    func setupOnlineMultiplayerGame(playerName: String) {
        guard isOnlineGame else {
            logger.error("Cannot setup online game - not in online mode")
            return
        }
        
        let localPlayer = Player(name: playerName)
        
        // Configure game state for multiplayer
        gameState.configureForMultiplayer(
            localPlayerId: localPlayer.id,
            gameSessionId: "", // Will be set when game starts
            isOnline: true
        )
        
        // Add local player to game state
        gameState.players = [localPlayer]
        
        logger.info("Online multiplayer game setup for player: \(playerName)")
    }
}

// MARK: - Analytics and Statistics

extension GameViewModel {
    
    /// Get current game statistics
    func getCurrentGameStatistics() -> GameStatistics {
        return gameState.getGameStatistics()
    }
    
    /// Get detailed game analysis
    func getGameAnalysis() -> GameAnalysis {
        let stats = getCurrentGameStatistics()
        
        return GameAnalysis(
            gameId: gameState.id,
            duration: Date().timeIntervalSince(gameState.createdAt),
            totalMoves: gameState.trickHistory.reduce(0) { $0 + $1.cards.count },
            averageMovesPerTrick: Double(gameState.trickHistory.reduce(0) { $0 + $1.cards.count }) / Double(max(gameState.trickHistory.count, 1)),
            pointCardDistribution: calculatePointCardDistribution(),
            playerPerformance: stats.playerStats.map { playerStat in
                PlayerPerformance(
                    playerId: playerStat.playerId,
                    name: playerStat.playerName,
                    score: playerStat.finalScore,
                    tricksWon: playerStat.tricksWon,
                    efficiency: Double(playerStat.tricksWon) / Double(max(gameState.trickHistory.count, 1))
                )
            }
        )
    }
    
    /// Calculate how point cards were distributed across players
    private func calculatePointCardDistribution() -> [UUID: Int] {
        var distribution: [UUID: Int] = [:]
        
        for trick in gameState.trickHistory {
            let points = GameRules.calculatePoints(from: trick.cards)
            if points > 0 {
                distribution[trick.winnerPlayerId, default: 0] += points
            }
        }
        
        return distribution
    }
}

// MARK: - Supporting Types

/// Detailed analysis of a game session
struct GameAnalysis {
    let gameId: UUID
    let duration: TimeInterval
    let totalMoves: Int
    let averageMovesPerTrick: Double
    let pointCardDistribution: [UUID: Int]
    let playerPerformance: [PlayerPerformance]
}

/// Performance metrics for a single player
struct PlayerPerformance {
    let playerId: UUID
    let name: String
    let score: Int
    let tricksWon: Int
    let efficiency: Double // Percentage of tricks won
}