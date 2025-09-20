//
//  GameStateCloudKitIntegration.swift
//  Septica
//
//  CloudKit integration for GameState multiplayer fields
//  Enables cross-device game continuation and real-time multiplayer sync
//

import Foundation
import CloudKit
import Combine
import OSLog

/// Integrates GameState with CloudKit for multiplayer and cross-device functionality
@MainActor
class GameStateCloudKitIntegration: ObservableObject {
    
    // MARK: - Published State
    
    @Published var isEnabled: Bool = false
    @Published var syncStatus: GameStateSyncStatus = .idle
    @Published var lastSyncDate: Date?
    @Published var multiplayerSessionActive: Bool = false
    @Published var crossDeviceGameAvailable: Bool = false
    
    // MARK: - Dependencies
    
    private let cloudKitManager: SepticaCloudKitManager
    private let recordManager: CloudKitRecordManager
    private let logger = Logger(subsystem: "Septica", category: "GameStateCloudKit")
    
    // MARK: - Game State Tracking
    
    private var currentGameState: GameState?
    private var cancellables = Set<AnyCancellable>()
    private var gameStateSubscription: AnyCancellable?
    
    // MARK: - CloudKit Record Types
    
    private struct GameStateRecordTypes {
        static let gameSession = "SepticaGameSession"
        static let gameMove = "SepticaGameMove"
        static let multiplayerInvite = "SepticaMultiplayerInvite"
    }
    
    // MARK: - Initialization
    
    init(cloudKitManager: SepticaCloudKitManager) {
        self.cloudKitManager = cloudKitManager
        self.recordManager = CloudKitRecordManager(container: cloudKitManager.container)
        
        setupCloudKitIntegration()
    }
    
    // MARK: - Setup Methods
    
    private func setupCloudKitIntegration() {
        // Monitor CloudKit availability
        cloudKitManager.$isAvailable
            .sink { [weak self] isAvailable in
                self?.isEnabled = isAvailable
                if isAvailable {
                    Task {
                        await self?.checkForCrossDeviceGames()
                    }
                }
            }
            .store(in: &cancellables)
        
        logger.info("🎮 GameState CloudKit integration initialized")
    }
    
    // MARK: - Game State Synchronization
    
    /// Start tracking a GameState for CloudKit synchronization
    func startTracking(_ gameState: GameState) {
        logger.info("▶️ Starting CloudKit tracking for game: \\(gameState.id)")
        
        currentGameState = gameState
        
        // Subscribe to GameState changes
        gameStateSubscription = gameState.objectWillChange
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] in
                Task {
                    await self?.syncGameStateToCloudKit()
                }
            }
        
        // Save initial game state
        Task {
            await syncGameStateToCloudKit()
        }
    }
    
    /// Stop tracking the current GameState
    func stopTracking() {
        logger.info("⏹️ Stopping CloudKit tracking")
        
        gameStateSubscription?.cancel()
        gameStateSubscription = nil
        currentGameState = nil
    }
    
    /// Sync current GameState to CloudKit
    private func syncGameStateToCloudKit() async {
        guard let gameState = currentGameState,
              cloudKitManager.isAvailable,
              gameState.isMultiplayer else {
            return
        }
        
        syncStatus = .syncing
        logger.info("🔄 Syncing GameState to CloudKit...")
        
        do {
            let record = try createGameSessionRecord(from: gameState)
            try await saveGameSessionRecord(record)
            
            syncStatus = .synced
            lastSyncDate = Date()
            logger.info("✅ GameState synced to CloudKit successfully")
            
        } catch {
            syncStatus = .error
            logger.error("❌ Failed to sync GameState to CloudKit: \\(error.localizedDescription)")
        }
    }
    
    /// Load GameState from CloudKit for cross-device continuation
    func loadGameStateFromCloudKit(gameSessionId: String) async throws -> GameState? {
        guard cloudKitManager.isAvailable else {
            throw CloudKitError.notAvailable
        }
        
        logger.info("🔽 Loading GameState from CloudKit: \\(gameSessionId)")
        
        let recordID = CKRecord.ID(recordName: "game_session_\\(gameSessionId)")
        
        do {
            let record = try await cloudKitManager.privateDatabase.record(for: recordID)
            let gameState = try parseGameSessionRecord(record)
            
            logger.info("✅ GameState loaded from CloudKit successfully")
            return gameState
            
        } catch CKError.unknownItem {
            logger.info("📭 No GameState found in CloudKit for session: \\(gameSessionId)")
            return nil
        } catch {
            logger.error("❌ Failed to load GameState from CloudKit: \\(error.localizedDescription)")
            throw CloudKitError.fetchFailed(error)
        }
    }
    
    // MARK: - Cross-Device Game Management
    
    /// Check for available cross-device games
    func checkForCrossDeviceGames() async {
        guard cloudKitManager.isAvailable else {
            crossDeviceGameAvailable = false
            return
        }
        
        logger.info("🔍 Checking for cross-device games...")
        
        do {
            let games = try await fetchActiveGameSessions()
            crossDeviceGameAvailable = !games.isEmpty
            
            if crossDeviceGameAvailable {
                logger.info("✅ Found \\(games.count) cross-device games available")
            } else {
                logger.info("📭 No cross-device games found")
            }
            
        } catch {
            logger.error("❌ Failed to check for cross-device games: \\(error.localizedDescription)")
            crossDeviceGameAvailable = false
        }
    }
    
    /// Fetch active game sessions from CloudKit
    func fetchActiveGameSessions() async throws -> [GameSessionSummary] {
        guard cloudKitManager.isAvailable else {
            throw CloudKitError.notAvailable
        }
        
        // Query for active game sessions for current player
        let currentPlayerID = "current_player" // Should come from authentication
        let predicate = NSPredicate(format: "localPlayerId == %@ AND phase != %@", currentPlayerID, "finished")
        let query = CKQuery(recordType: GameStateRecordTypes.gameSession, predicate: predicate)
        
        query.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
        
        do {
            let (matchResults, _) = try await cloudKitManager.privateDatabase.records(matching: query, resultsLimit: 10)
            
            var sessions: [GameSessionSummary] = []
            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    if let summary = try? parseGameSessionSummary(record) {
                        sessions.append(summary)
                    }
                case .failure(let error):
                    logger.error("Failed to fetch game session: \\(error.localizedDescription)")
                }
            }
            
            return sessions
            
        } catch {
            logger.error("❌ Failed to fetch active game sessions: \\(error.localizedDescription)")
            throw CloudKitError.fetchFailed(error)
        }
    }
    
    // MARK: - Multiplayer Move Synchronization
    
    /// Save a game move to CloudKit for real-time multiplayer
    func saveGameMove(_ move: GameMove, in gameState: GameState) async throws {
        guard cloudKitManager.isAvailable,
              gameState.isOnlineGame else {
            return
        }
        
        logger.info("💾 Saving game move to CloudKit...")
        
        do {
            let record = try createGameMoveRecord(move, gameSessionId: gameState.gameSessionId ?? "")
            try await saveGameMoveRecord(record)
            
            logger.info("✅ Game move saved to CloudKit")
            
        } catch {
            logger.error("❌ Failed to save game move: \\(error.localizedDescription)")
            throw CloudKitError.syncFailed(error)
        }
    }
    
    /// Fetch recent game moves for multiplayer synchronization
    func fetchRecentGameMoves(for gameSessionId: String, since sequence: Int) async throws -> [GameMove] {
        guard cloudKitManager.isAvailable else {
            throw CloudKitError.notAvailable
        }
        
        logger.info("🔽 Fetching game moves since sequence: \\(sequence)")
        
        let predicate = NSPredicate(format: "gameSessionId == %@ AND sequenceNumber > %d", gameSessionId, sequence)
        let query = CKQuery(recordType: GameStateRecordTypes.gameMove, predicate: predicate)
        
        query.sortDescriptors = [NSSortDescriptor(key: "sequenceNumber", ascending: true)]
        
        do {
            let (matchResults, _) = try await cloudKitManager.privateDatabase.records(matching: query, resultsLimit: 50)
            
            var moves: [GameMove] = []
            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    if let move = try? parseGameMoveRecord(record) {
                        moves.append(move)
                    }
                case .failure(let error):
                    logger.error("Failed to fetch game move: \\(error.localizedDescription)")
                }
            }
            
            logger.info("✅ Fetched \\(moves.count) game moves")
            return moves
            
        } catch {
            logger.error("❌ Failed to fetch game moves: \\(error.localizedDescription)")
            throw CloudKitError.fetchFailed(error)
        }
    }
    
    // MARK: - Record Creation and Parsing
    
    /// Create CloudKit record from GameState
    private func createGameSessionRecord(from gameState: GameState) throws -> CKRecord {
        let recordID = CKRecord.ID(recordName: "game_session_\\(gameState.gameSessionId ?? gameState.id.uuidString)")
        let record = CKRecord(recordType: GameStateRecordTypes.gameSession, recordID: recordID)
        
        // Basic game information
        record["gameId"] = gameState.id.uuidString as CKRecordValue
        record["gameSessionId"] = gameState.gameSessionId as CKRecordValue?
        record["localPlayerId"] = gameState.localPlayerId?.uuidString as CKRecordValue?
        record["phase"] = gameState.phase.rawValue as CKRecordValue
        record["roundNumber"] = gameState.roundNumber as CKRecordValue
        record["trickNumber"] = gameState.trickNumber as CKRecordValue
        record["currentPlayerIndex"] = gameState.currentPlayerIndex as CKRecordValue
        record["dealerIndex"] = gameState.dealerIndex as CKRecordValue
        record["serverSequenceNumber"] = gameState.serverSequenceNumber as CKRecordValue
        record["connectionStatus"] = gameState.connectionStatus.rawValue as CKRecordValue
        record["isOnlineGame"] = gameState.isOnlineGame as CKRecordValue
        record["createdAt"] = gameState.createdAt as CKRecordValue
        record["updatedAt"] = gameState.updatedAt as CKRecordValue
        
        // Encode complex data
        let encoder = JSONEncoder()
        
        // Players data
        let playersData = try encoder.encode(gameState.players.map { PlayerData.from($0) })
        record["playersData"] = playersData as CKRecordValue
        
        // Table cards
        let tableCardsData = try encoder.encode(gameState.tableCards)
        record["tableCardsData"] = tableCardsData as CKRecordValue
        
        // Deck state
        let deckData = try encoder.encode(gameState.deck)
        record["deckData"] = deckData as CKRecordValue
        
        // Trick history
        let trickHistoryData = try encoder.encode(gameState.trickHistory)
        record["trickHistoryData"] = trickHistoryData as CKRecordValue
        
        // Last move
        if let lastMove = gameState.lastMove {
            let lastMoveData = try encoder.encode(lastMove)
            record["lastMoveData"] = lastMoveData as CKRecordValue
        }
        
        // Game result
        if let gameResult = gameState.gameResult {
            let gameResultData = try encoder.encode(gameResult)
            record["gameResultData"] = gameResultData as CKRecordValue
        }
        
        // Multiplayer metadata
        record["syncVersion"] = 1 as CKRecordValue
        record["deviceId"] = UIDevice.current.identifierForVendor?.uuidString as CKRecordValue?
        record["lastSyncDate"] = Date() as CKRecordValue
        
        return record
    }
    
    /// Parse GameState from CloudKit record
    private func parseGameSessionRecord(_ record: CKRecord) throws -> GameState {
        let decoder = JSONDecoder()
        
        // Parse players
        let playersData = record["playersData"] as? Data ?? Data()
        let playerDataArray = try decoder.decode([PlayerData].self, from: playersData)
        let players = playerDataArray.map { $0.toPlayer() }
        
        // Create GameState with players
        let gameState = GameState(players: players)
        
        // Set basic properties
        if let phaseString = record["phase"] as? String,
           let phase = GamePhase(rawValue: phaseString) {
            gameState.phase = phase
        }
        
        gameState.roundNumber = record["roundNumber"] as? Int ?? 1
        gameState.trickNumber = record["trickNumber"] as? Int ?? 1
        gameState.currentPlayerIndex = record["currentPlayerIndex"] as? Int ?? 0
        gameState.dealerIndex = record["dealerIndex"] as? Int ?? 0
        gameState.serverSequenceNumber = record["serverSequenceNumber"] as? Int ?? 0
        
        if let connectionStatusString = record["connectionStatus"] as? String,
           let connectionStatus = ConnectionStatus(rawValue: connectionStatusString) {
            gameState.connectionStatus = connectionStatus
        }
        
        gameState.isOnlineGame = record["isOnlineGame"] as? Bool ?? false
        
        // Set multiplayer properties
        if let gameSessionId = record["gameSessionId"] as? String {
            gameState.gameSessionId = gameSessionId
        }
        
        if let localPlayerIdString = record["localPlayerId"] as? String,
           let localPlayerId = UUID(uuidString: localPlayerIdString) {
            gameState.localPlayerId = localPlayerId
        }
        
        // Parse complex data
        if let tableCardsData = record["tableCardsData"] as? Data {
            gameState.tableCards = (try? decoder.decode([Card].self, from: tableCardsData)) ?? []
        }
        
        if let deckData = record["deckData"] as? Data {
            gameState.deck = (try? decoder.decode(Deck.self, from: deckData)) ?? Deck()
        }
        
        if let trickHistoryData = record["trickHistoryData"] as? Data {
            gameState.trickHistory = (try? decoder.decode([CompletedTrick].self, from: trickHistoryData)) ?? []
        }
        
        if let lastMoveData = record["lastMoveData"] as? Data {
            gameState.lastMove = try? decoder.decode(GameMove.self, from: lastMoveData)
        }
        
        if let gameResultData = record["gameResultData"] as? Data {
            gameState.gameResult = try? decoder.decode(GameResult.self, from: gameResultData)
        }
        
        return gameState
    }
    
    /// Create CloudKit record from GameMove
    private func createGameMoveRecord(_ move: GameMove, gameSessionId: String) throws -> CKRecord {
        let recordID = CKRecord.ID(recordName: "game_move_\\(gameSessionId)_\\(move.tableCardsCount)")
        let record = CKRecord(recordType: GameStateRecordTypes.gameMove, recordID: recordID)
        
        record["gameSessionId"] = gameSessionId as CKRecordValue
        record["playerId"] = move.playerId.uuidString as CKRecordValue
        record["timestamp"] = move.timestamp as CKRecordValue
        record["tableCardsCount"] = move.tableCardsCount as CKRecordValue
        record["sequenceNumber"] = move.tableCardsCount as CKRecordValue // Use as sequence
        
        // Encode card
        let encoder = JSONEncoder()
        let cardData = try encoder.encode(move.card)
        record["cardData"] = cardData as CKRecordValue
        
        return record
    }
    
    /// Parse GameMove from CloudKit record
    private func parseGameMoveRecord(_ record: CKRecord) throws -> GameMove {
        guard let playerIdString = record["playerId"] as? String,
              let playerId = UUID(uuidString: playerIdString),
              let timestamp = record["timestamp"] as? Date,
              let tableCardsCount = record["tableCardsCount"] as? Int,
              let cardData = record["cardData"] as? Data else {
            throw CloudKitError.recordFetchFailed(NSError(domain: "GameMove", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing required fields"]))
        }
        
        let decoder = JSONDecoder()
        let card = try decoder.decode(Card.self, from: cardData)
        
        return GameMove(
            playerId: playerId,
            card: card,
            timestamp: timestamp,
            tableCardsCount: tableCardsCount
        )
    }
    
    /// Parse game session summary for cross-device games
    private func parseGameSessionSummary(_ record: CKRecord) throws -> GameSessionSummary {
        guard let gameId = record["gameId"] as? String,
              let phaseString = record["phase"] as? String,
              let phase = GamePhase(rawValue: phaseString),
              let updatedAt = record["updatedAt"] as? Date else {
            throw CloudKitError.recordFetchFailed(NSError(domain: "GameSessionSummary", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing required fields"]))
        }
        
        return GameSessionSummary(
            gameId: gameId,
            gameSessionId: record["gameSessionId"] as? String,
            phase: phase,
            roundNumber: record["roundNumber"] as? Int ?? 1,
            updatedAt: updatedAt,
            playerCount: 2 // Romanian Septica is always 2 players
        )
    }
    
    // MARK: - CloudKit Operations
    
    private func saveGameSessionRecord(_ record: CKRecord) async throws {
        _ = try await cloudKitManager.privateDatabase.save(record)
    }
    
    private func saveGameMoveRecord(_ record: CKRecord) async throws {
        _ = try await cloudKitManager.privateDatabase.save(record)
    }
}

// MARK: - Supporting Types

enum GameStateSyncStatus {
    case idle
    case syncing
    case synced
    case error
    
    var displayName: String {
        switch self {
        case .idle: return "Ready"
        case .syncing: return "Syncing..."
        case .synced: return "Synced"
        case .error: return "Error"
        }
    }
}

struct GameSessionSummary: Identifiable {
    let id = UUID()
    let gameId: String
    let gameSessionId: String?
    let phase: GamePhase
    let roundNumber: Int
    let updatedAt: Date
    let playerCount: Int
    
    var displayTitle: String {
        return "Romanian Septica - Round \\(roundNumber)"
    }
    
    var displaySubtitle: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return "Updated \\(formatter.localizedString(for: updatedAt, relativeTo: Date()))"
    }
}