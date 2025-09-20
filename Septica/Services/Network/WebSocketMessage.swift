//
//  WebSocketMessage.swift
//  Septica
//
//  WebSocket message types matching the Go backend protocol
//  Handles serialization/deserialization for client-server communication
//

import Foundation
import Combine

// MARK: - Base Message Types

/// Represents an outbound message sent to the server
struct OutgoingMessage: Codable {
    let type: String
    let id: String
    let gameId: UUID?
    let payload: AnyCodable?
    
    enum CodingKeys: String, CodingKey {
        case type, id
        case gameId = "game_id"
        case payload
    }
    
    init(type: MessageType, gameId: UUID? = nil, payload: Codable? = nil) {
        self.type = type.rawValue
        self.id = UUID().uuidString
        self.gameId = gameId
        self.payload = payload.map { AnyCodable($0) }
    }
}

/// Represents an incoming message received from the server
struct IncomingMessage: Codable {
    let type: String
    let id: String
    let playerId: UUID?
    let gameId: UUID?
    let timestamp: Date
    let payload: [String: AnyCodable]?
    
    enum CodingKeys: String, CodingKey {
        case type, id, timestamp
        case playerId = "player_id"
        case gameId = "game_id"
        case payload
    }
}

// MARK: - Message Types

/// All supported message types for client-server communication
enum MessageType: String, CaseIterable {
    // Client -> Server
    case ping = "ping"
    case joinGame = "join_game"
    case leaveGame = "leave_game"
    case playCard = "play_card"
    case getGameState = "get_game_state"
    case chatMessage = "chat_message"
    
    // Server -> Client
    case pong = "pong"
    case connectionAck = "connection_ack"
    case error = "error"
    case gameState = "game_state"
    case moveResult = "move_result"
    case playerJoined = "player_joined"
    case playerLeft = "player_left"
    case gameEnd = "game_end"
    case heartbeat = "heartbeat"
    case chatReceived = "chat_received"
    
    // Game state notifications
    case gameStarted = "game_started"
    case trickComplete = "trick_complete"
    case playerTurn = "player_turn"
    case gamePaused = "game_paused"
    case gameResumed = "game_resumed"
}

// MARK: - Error Types

/// Error types for consistent error handling
enum NetworkErrorType: String, CaseIterable {
    case invalidMessage = "invalid_message"
    case notAuthorized = "not_authorized"
    case gameNotFound = "game_not_found"
    case playerNotInGame = "player_not_in_game"
    case invalidMove = "invalid_move"
    case notPlayerTurn = "not_player_turn"
    case gameFull = "game_full"
    case connectionFailed = "connection_failed"
    case rateLimited = "rate_limited"
    case serverError = "server_error"
}

// MARK: - Payload Structures

/// Payload for join_game messages
struct JoinGamePayload: Codable {
    let gameMode: String?
    
    enum CodingKeys: String, CodingKey {
        case gameMode = "game_mode"
    }
    
    init(gameMode: GameMode = .casual) {
        self.gameMode = gameMode.rawValue
    }
}

/// Game modes supported by the server
enum GameMode: String, CaseIterable {
    case ranked = "ranked"
    case casual = "casual"
    case custom = "custom"
}

/// Payload for play_card messages
struct PlayCardPayload: Codable {
    let suit: String
    let value: Int
    let id: String?
    
    init(card: Card) {
        self.suit = card.suit.rawValue
        self.value = card.value.rawValue
        self.id = card.id.uuidString
    }
}

/// Payload for chat messages
struct ChatMessagePayload: Codable {
    let message: String
    let type: String?
    
    init(message: String, type: ChatType = .text) {
        self.message = message
        self.type = type.rawValue
    }
}

/// Chat message types
enum ChatType: String, CaseIterable {
    case text = "text"
    case emote = "emote"
}

/// Game state payload received from server
struct GameStatePayload: Codable {
    let gameId: UUID
    let currentPlayerId: UUID
    let yourTurn: Bool
    let yourCards: [NetworkCard]
    let opponentCardCount: Int
    let tableCards: [NetworkCard]
    let validMoves: [NetworkCard]
    let scores: [String: Int]
    let trickNumber: Int
    let moveNumber: Int
    let sequenceNumber: Int
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case gameId = "game_id"
        case currentPlayerId = "current_player_id"
        case yourTurn = "your_turn"
        case yourCards = "your_cards"
        case opponentCardCount = "opponent_card_count"
        case tableCards = "table_cards"
        case validMoves = "valid_moves"
        case scores
        case trickNumber = "trick_number"
        case moveNumber = "move_number"
        case sequenceNumber = "sequence_number"
        case status
    }
}

/// Network representation of a card
struct NetworkCard: Codable {
    let suit: String
    let value: Int
    let id: String
    
    /// Convert to domain Card model
    func toCard() -> Card? {
        guard let suitEnum = Card.Suit(rawValue: suit),
              let valueEnum = Card.Value(rawValue: value),
              let cardId = UUID(uuidString: id) else {
            return nil
        }
        return Card(suit: suitEnum, value: valueEnum, id: cardId)
    }
    
    /// Create from domain Card model
    init(from card: Card) {
        self.suit = card.suit.rawValue
        self.value = card.value.rawValue
        self.id = card.id.uuidString
    }
}

/// Move result payload
struct MoveResultPayload: Codable {
    let valid: Bool
    let error: String?
    let trickComplete: Bool
    let gameComplete: Bool
    let winnerId: UUID?
    let pointsAwarded: Int
    
    enum CodingKeys: String, CodingKey {
        case valid, error
        case trickComplete = "trick_complete"
        case gameComplete = "game_complete"
        case winnerId = "winner_id"
        case pointsAwarded = "points_awarded"
    }
}

/// Player joined notification payload
struct PlayerJoinedPayload: Codable {
    let playerId: UUID
    let username: String?
    
    enum CodingKeys: String, CodingKey {
        case playerId = "player_id"
        case username
    }
}

/// Player left notification payload
struct PlayerLeftPayload: Codable {
    let playerId: UUID
    let reason: String?
    
    enum CodingKeys: String, CodingKey {
        case playerId = "player_id"
        case reason
    }
}

/// Game end notification payload
struct GameEndPayload: Codable {
    let winnerId: UUID?
    let reason: String
    let finalScore: [String: Int]
    let gameStats: GameStats?
    
    enum CodingKeys: String, CodingKey {
        case winnerId = "winner_id"
        case reason
        case finalScore = "final_score"
        case gameStats = "game_stats"
    }
}

/// Game statistics
struct GameStats: Codable {
    let durationMs: Int64
    let totalMoves: Int
    let totalTricks: Int
    let sevensPlayed: Int
    let eightsPlayed: Int
    let pointCardsWon: [String: Int]
    
    enum CodingKeys: String, CodingKey {
        case durationMs = "duration_ms"
        case totalMoves = "total_moves"
        case totalTricks = "total_tricks"
        case sevensPlayed = "sevens_played"
        case eightsPlayed = "eights_played"
        case pointCardsWon = "point_cards_won"
    }
}

/// Connection acknowledgment payload
struct ConnectionAckPayload: Codable {
    let sessionId: String
    let serverTime: Date
    let heartbeatInterval: Int
    let maxMessageQueue: Int
    let serverVersion: String?
    
    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case serverTime = "server_time"
        case heartbeatInterval = "heartbeat_interval"
        case maxMessageQueue = "max_message_queue"
        case serverVersion = "server_version"
    }
}

/// Error payload
struct ErrorPayload: Codable {
    let errorType: String
    let message: String
    let code: Int?
    let details: [String: AnyCodable]?
    
    enum CodingKeys: String, CodingKey {
        case errorType = "error_type"
        case message, code, details
    }
}

/// Heartbeat payload
struct HeartbeatPayload: Codable {
    let serverTime: Date
    let clientCount: Int?
    let activeGames: Int?
    
    enum CodingKeys: String, CodingKey {
        case serverTime = "server_time"
        case clientCount = "client_count"
        case activeGames = "active_games"
    }
}

// MARK: - Type-Erased Codable

/// Type-erased wrapper for Codable values
struct AnyCodable: Codable {
    let value: Any
    
    init<T: Codable>(_ value: T) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let value = try? container.decode(Bool.self) {
            self.value = value
        } else if let value = try? container.decode(Int.self) {
            self.value = value
        } else if let value = try? container.decode(Double.self) {
            self.value = value
        } else if let value = try? container.decode(String.self) {
            self.value = value
        } else if let value = try? container.decode([String: AnyCodable].self) {
            self.value = value
        } else if let value = try? container.decode([AnyCodable].self) {
            self.value = value
        } else {
            throw DecodingError.typeMismatch(
                AnyCodable.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Unsupported type"
                )
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let value as Bool:
            try container.encode(value)
        case let value as Int:
            try container.encode(value)
        case let value as Double:
            try container.encode(value)
        case let value as String:
            try container.encode(value)
        case let value as [String: AnyCodable]:
            try container.encode(value)
        case let value as [AnyCodable]:
            try container.encode(value)
        default:
            let context = EncodingError.Context(
                codingPath: encoder.codingPath,
                debugDescription: "Unsupported type: \(type(of: value))"
            )
            throw EncodingError.invalidValue(value, context)
        }
    }
}

// MARK: - Message Factories

extension OutgoingMessage {
    
    /// Create a ping message
    static func ping() -> OutgoingMessage {
        return OutgoingMessage(type: .ping)
    }
    
    /// Create a join game message
    static func joinGame(mode: GameMode = .casual) -> OutgoingMessage {
        return OutgoingMessage(
            type: .joinGame,
            payload: JoinGamePayload(gameMode: mode)
        )
    }
    
    /// Create a leave game message
    static func leaveGame(gameId: UUID) -> OutgoingMessage {
        return OutgoingMessage(type: .leaveGame, gameId: gameId)
    }
    
    /// Create a play card message
    static func playCard(card: Card, gameId: UUID) -> OutgoingMessage {
        return OutgoingMessage(
            type: .playCard,
            gameId: gameId,
            payload: PlayCardPayload(card: card)
        )
    }
    
    /// Create a get game state message
    static func getGameState(gameId: UUID) -> OutgoingMessage {
        return OutgoingMessage(type: .getGameState, gameId: gameId)
    }
    
    /// Create a chat message
    static func chatMessage(text: String, gameId: UUID) -> OutgoingMessage {
        return OutgoingMessage(
            type: .chatMessage,
            gameId: gameId,
            payload: ChatMessagePayload(message: text)
        )
    }
}

// MARK: - Message Parsing Helpers

extension IncomingMessage {
    
    /// Parse a specific payload type from the message
    func parsePayload<T: Codable>(as type: T.Type) throws -> T {
        guard let payloadData = payload else {
            throw NetworkError.invalidMessageFormat("Missing payload")
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: payloadData)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(type, from: jsonData)
    }
    
    /// Get the message type enum
    var messageType: MessageType? {
        return MessageType(rawValue: type)
    }
}

// MARK: - Network Error

enum NetworkError: Error, LocalizedError {
    case invalidMessageFormat(String)
    case decodingError(Error)
    case encodingError(Error)
    case unsupportedMessageType(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidMessageFormat(let message):
            return "Invalid message format: \(message)"
        case .decodingError(let error):
            return "Message decoding error: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Message encoding error: \(error.localizedDescription)"
        case .unsupportedMessageType(let type):
            return "Unsupported message type: \(type)"
        }
    }
}