/**
 * Type Exports for Septica Frontend
 * Central export point for all TypeScript types
 */

// ============================================================
// GAME TYPES
// ============================================================

export type {
  // Card types
  CardSuit,
  CardValue,
  Card,
  
  // Player types
  Player,
  PlayerPublic,
  Team,
  
  // Game mode types
  GameMode,
  GameModeConfig,
  
  // Game phase types
  GamePhase,
  GameStatus,
  
  // Game state types
  GameState,
  GameSummary,
  
  // Move types
  PlayerActionType,
  PlayerAction,
  MoveResult,
  
  // Round types
  RoundResult,
  Trick,
  
  // Configuration
  GameConfig,
  
  // Stats & history
  GameStats,
  GameEndPayload,
  
  // Matchmaking
  QueueType,
  MatchmakingStatus,
  MatchFound,
  
  // Utility types
  CardLocation,
  ConnectionStatus,
  GameErrorCode,
  GameError,
} from './game';

// Export game constants and utilities
export {
  CardValueNames,
  CardSuitSymbols,
  CardSuitColors,
  CardPoints,
  GameModeConfigs,
  DefaultGameConfig,
  isSpecialTenOfDiamonds,
  isValidCard,
  isWildCard,
  calculateCardPoints,
  getTotalPointsInDeck,
} from './game';

// ============================================================
// WEBSOCKET TYPES
// ============================================================

export type {
  // Base types
  BaseMessage,
  ClientMessage,
  ServerMessage,
  
  // Client message types
  ClientMessageType,
  PingMessage,
  JoinGamePayload,
  JoinGameMessage,
  LeaveGameMessage,
  PlayCardPayload,
  PlayCardMessage,
  PassMessage,
  GetGameStateMessage,
  ChatMessagePayload,
  ChatMessage,
  JoinMatchmakingPayload,
  JoinMatchmakingMessage,
  LeaveMatchmakingMessage,
  MatchmakingStatusMessage,
  ClientMessageUnion,
  
  // Server message types
  ServerMessageType,
  PongPayload,
  PongMessage,
  ConnectionAckPayload,
  ConnectionAckMessage,
  ErrorType,
  ErrorPayload,
  ErrorMessage,
  GameStatePayload,
  GameStateMessage,
  MoveResultPayload,
  MoveResultMessage,
  ObjectionWaitPayload,
  ObjectionWaitMessage,
  RoundCompletePayload,
  RoundCompleteMessage,
  PlayerJoinedPayload,
  PlayerJoinedMessage,
  PlayerLeftPayload,
  PlayerLeftMessage,
  GameEndPayloadMessage,
  GameEndMessage,
  HeartbeatPayload,
  HeartbeatMessage,
  ChatReceivedPayload,
  ChatReceivedMessage,
  MatchmakingJoinedPayload,
  MatchmakingJoinedMessage,
  MatchmakingUpdatePayload,
  MatchmakingUpdateMessage,
  MatchFoundPayload,
  MatchFoundMessage,
  MatchmakingLeftPayload,
  MatchmakingLeftMessage,
  MatchmakingErrorPayload,
  MatchmakingErrorMessage,
  GameStartedPayload,
  GameStartedMessage,
  PlayerTurnPayload,
  PlayerTurnMessage,
  GamePausedPayload,
  GamePausedMessage,
  GameResumedPayload,
  GameResumedMessage,
  ServerMessageUnion,
  
  // Message maps
  ClientMessagePayloadMap,
  ServerMessagePayloadMap,
} from './websocket';

// Export message creators and type guards
export {
  isServerMessage,
  isClientMessage,
  isMessageOfType,
  createPing,
  createJoinGame,
  createPlayCard,
  createPass,
  createLeaveGame,
  createGetGameState,
  createChatMessage,
  createJoinMatchmaking,
  createLeaveMatchmaking,
} from './websocket';

// ============================================================
// UTILITY TYPE HELPERS
// ============================================================

/** Extract the payload type from a message type */
export type PayloadOf<T> = T extends { payload: infer P } ? P : never;

/** Extract the type field from any message */
export type MessageTypeOf<T> = T extends { type: infer Type } ? Type : never;

/** Make all properties required recursively */
export type DeepRequired<T> = {
  [P in keyof T]-?: T[P] extends object ? DeepRequired<T[P]> : T[P];
};

/** Make all properties optional recursively */
export type DeepPartial<T> = {
  [P in keyof T]?: T[P] extends object ? DeepPartial<T[P]> : T[P];
};

/** Type for event handlers with discriminated unions */
export type MessageHandler<T extends { type: string }> = (
  message: T
) => void | Promise<void>;

/** Map of message types to their handlers */
export type MessageHandlerMap<T extends { type: string }> = {
  [K in T['type']]?: MessageHandler<Extract<T, { type: K }>>;
};
