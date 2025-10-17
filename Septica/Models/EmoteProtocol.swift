//
//  EmoteProtocol.swift
//  Septica
//
//  Elegant multiplayer emote communication protocol
//  Real-time avatar emote broadcasting with cultural authenticity
//

import Foundation

// MARK: - Core Emote Message Protocol

/// Primary emote message for real-time multiplayer communication
struct EmoteMessage: Codable, Identifiable, Equatable {
    let id: UUID
    let playerId: UUID
    let emoteType: EmoteType
    let timestamp: Date
    let gameId: String
    let characterType: RomanianCharacterType

    // Optional contextual data
    let targetPlayerId: UUID?
    let intensity: Float // 0.0 to 1.0
    let duration: TimeInterval // Custom duration override

    init(
        playerId: UUID,
        emoteType: EmoteType,
        gameId: String,
        characterType: RomanianCharacterType,
        targetPlayerId: UUID? = nil,
        intensity: Float = 1.0,
        duration: TimeInterval = 2.0
    ) {
        self.id = UUID()
        self.playerId = playerId
        self.emoteType = emoteType
        self.timestamp = Date()
        self.gameId = gameId
        self.characterType = characterType
        self.targetPlayerId = targetPlayerId
        self.intensity = max(0.0, min(1.0, intensity))
        self.duration = max(0.5, min(5.0, duration))
    }
}

// MARK: - WebSocket Message Types

/// Unified WebSocket message protocol for all game communications
enum GameWebSocketMessage: Codable {
    case emoteBroadcast(EmoteMessage)
    case avatarSync(AvatarSyncMessage)
    case gameState(GameStateMessage)
    case playerJoined(PlayerJoinedMessage)
    case playerLeft(PlayerLeftMessage)
    case heartbeat(HeartbeatMessage)
    case error(ErrorMessage)

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case type, payload
    }

    // MARK: - Codable Implementation

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "emote_broadcast":
            self = .emoteBroadcast(try container.decode(EmoteMessage.self, forKey: .payload))
        case "avatar_sync":
            self = .avatarSync(try container.decode(AvatarSyncMessage.self, forKey: .payload))
        case "game_state":
            self = .gameState(try container.decode(GameStateMessage.self, forKey: .payload))
        case "player_joined":
            self = .playerJoined(try container.decode(PlayerJoinedMessage.self, forKey: .payload))
        case "player_left":
            self = .playerLeft(try container.decode(PlayerLeftMessage.self, forKey: .payload))
        case "heartbeat":
            self = .heartbeat(try container.decode(HeartbeatMessage.self, forKey: .payload))
        case "error":
            self = .error(try container.decode(ErrorMessage.self, forKey: .payload))
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unknown message type: \(type)")
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .emoteBroadcast(let message):
            try container.encode("emote_broadcast", forKey: .type)
            try container.encode(message, forKey: .payload)
        case .avatarSync(let message):
            try container.encode("avatar_sync", forKey: .type)
            try container.encode(message, forKey: .payload)
        case .gameState(let message):
            try container.encode("game_state", forKey: .type)
            try container.encode(message, forKey: .payload)
        case .playerJoined(let message):
            try container.encode("player_joined", forKey: .type)
            try container.encode(message, forKey: .payload)
        case .playerLeft(let message):
            try container.encode("player_left", forKey: .type)
            try container.encode(message, forKey: .payload)
        case .heartbeat(let message):
            try container.encode("heartbeat", forKey: .type)
            try container.encode(message, forKey: .payload)
        case .error(let message):
            try container.encode("error", forKey: .type)
            try container.encode(message, forKey: .payload)
        }
    }
}

// MARK: - Supporting Message Types

/// Avatar synchronization message for multiplayer state consistency
struct AvatarSyncMessage: Codable, Equatable {
    let playerId: UUID
    let characterType: RomanianCharacterType
    let playerLevel: Int
    let isActiveEmote: Bool
    let currentEmote: EmoteType?
    let emoteStartTime: Date?
    let position: AvatarPosition?
}

/// Game state synchronization message
struct GameStateMessage: Codable {
    let gameId: String
    let currentRound: Int
    let activePlayerId: UUID
    let gamePhase: GameScreenPhase
    let turnTimeRemaining: TimeInterval
    let lastMoveTimestamp: Date
}

/// Player joined notification
struct PlayerJoinedMessage: Codable {
    let playerId: UUID
    let playerName: String
    let characterType: RomanianCharacterType
    let playerLevel: Int
    let joinTimestamp: Date
}

/// Player left notification
struct PlayerLeftMessage: Codable {
    let playerId: UUID
    let playerName: String
    let leaveTimestamp: Date
    let reason: PlayerLeaveReason
}

/// Heartbeat for connection monitoring
struct HeartbeatMessage: Codable {
    let timestamp: Date
    let sequenceNumber: Int
    let clientVersion: String
}

/// Error message for protocol errors
struct ErrorMessage: Codable {
    let errorCode: String
    let message: String
    let timestamp: Date
    let recoverable: Bool
}

// MARK: - Supporting Types

/// Avatar position for spatial emotes
struct AvatarPosition: Codable, Equatable {
    let x: Float
    let y: Float
    let z: Float
    let rotation: Float
}

/// Reason for player leaving
enum PlayerLeaveReason: String, Codable, CaseIterable {
    case voluntary = "voluntary"
    case disconnected = "disconnected"
    case kicked = "kicked"
    case timeout = "timeout"
}

// MARK: - Emote Protocol Extensions

extension EmoteMessage {
    /// Check if emote is still valid based on timestamp and duration
    var isValid: Bool {
        let elapsed = Date().timeIntervalSince(timestamp)
        return elapsed < duration
    }

    /// Calculate remaining emote duration
    var remainingDuration: TimeInterval {
        let elapsed = Date().timeIntervalSince(timestamp)
        return max(0, duration - elapsed)
    }

    /// Check if emote targets a specific player
    var isTargeted: Bool {
        return targetPlayerId != nil
    }

    /// Get localized emote description for accessibility
    var localizedDescription: String {
        let playerName = "Player" // Would get from PlayerManager
        let emoteName = emoteType.rawValue

        if let targetId = targetPlayerId {
            let targetName = "Target Player" // Would get from PlayerManager
            return "\(playerName) \(emoteName) to \(targetName)"
        } else {
            return "\(playerName) \(emoteName)"
        }
    }
}

extension GameWebSocketMessage {
    /// Extract message timestamp for ordering
    var timestamp: Date {
        switch self {
        case .emoteBroadcast(let message):
            return message.timestamp
        case .avatarSync(let message):
            return Date() // Avatar sync is immediate
        case .gameState(let message):
            return message.lastMoveTimestamp
        case .playerJoined(let message):
            return message.joinTimestamp
        case .playerLeft(let message):
            return message.leaveTimestamp
        case .heartbeat(let message):
            return message.timestamp
        case .error(let message):
            return message.timestamp
        }
    }

    /// Check if message requires immediate processing
    var isHighPriority: Bool {
        switch self {
        case .emoteBroadcast, .error:
            return true
        case .avatarSync, .gameState, .playerJoined, .playerLeft:
            return false
        case .heartbeat:
            return false
        }
    }

    /// Get message type identifier for logging
    var messageType: String {
        switch self {
        case .emoteBroadcast: return "emote_broadcast"
        case .avatarSync: return "avatar_sync"
        case .gameState: return "game_state"
        case .playerJoined: return "player_joined"
        case .playerLeft: return "player_left"
        case .heartbeat: return "heartbeat"
        case .error: return "error"
        }
    }
}

// MARK: - Validation Extensions

extension EmoteMessage {
    /// Validate emote message integrity
    func validate() -> ValidationResult {
        var errors: [String] = []

        // Validate intensity range
        if intensity < 0.0 || intensity > 1.0 {
            errors.append("Intensity out of valid range: \(intensity)")
        }

        // Validate duration range
        if duration < 0.5 || duration > 5.0 {
            errors.append("Duration out of valid range: \(duration)")
        }

        // Validate gameId
        if gameId.isEmpty {
            errors.append("Game ID cannot be empty")
        }

        // Validate timestamp isn't too old or future
        let now = Date()
        let timeDiff = abs(now.timeIntervalSince(timestamp))
        if timeDiff > 60 { // 1 minute tolerance
            errors.append("Timestamp too far from current time: \(timestamp)")
        }

        return errors.isEmpty ? .valid : .invalid(errors)
    }
}

/// Validation result for message integrity
enum ValidationResult {
    case valid
    case invalid([String])

    var isValid: Bool {
        switch self {
        case .valid:
            return true
        case .invalid:
            return false
        }
    }

    var errors: [String] {
        switch self {
        case .valid:
            return []
        case .invalid(let errors):
            return errors
        }
    }
}

// MARK: - Factory Methods

extension GameWebSocketMessage {
    /// Create emote broadcast message
    static func emoteBroadcast(
        playerId: UUID,
        emoteType: EmoteType,
        gameId: String,
        characterType: RomanianCharacterType
    ) -> GameWebSocketMessage {
        let emoteMessage = EmoteMessage(
            playerId: playerId,
            emoteType: emoteType,
            gameId: gameId,
            characterType: characterType
        )
        return .emoteBroadcast(emoteMessage)
    }

    /// Create heartbeat message
    static func heartbeat(sequenceNumber: Int) -> GameWebSocketMessage {
        let heartbeat = HeartbeatMessage(
            timestamp: Date(),
            sequenceNumber: sequenceNumber,
            clientVersion: "1.0.0"
        )
        return .heartbeat(heartbeat)
    }

    /// Create error message
    static func error(
        code: String,
        message: String,
        recoverable: Bool = true
    ) -> GameWebSocketMessage {
        let errorMessage = ErrorMessage(
            errorCode: code,
            message: message,
            timestamp: Date(),
            recoverable: recoverable
        )
        return .error(errorMessage)
    }
}