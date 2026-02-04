/**
 * WebSocket Message Types for Septica
 * Based on backend/internal/websocket/messages.go
 * 
 * Uses discriminated unions for type-safe message handling
 */

import type { Card, GameState, GameMode, MoveResult, RoundResult, MatchmakingStatus, MatchFound, GameEndPayload, QueueType } from './game';

// ============================================================
// BASE MESSAGE TYPES
// ============================================================

/** Base interface for all messages */
export interface BaseMessage {
  id: string;
  timestamp: string;
}

/** Base interface for client -> server messages */
export interface ClientMessage extends BaseMessage {
  gameId?: string;
}

/** Base interface for server -> client messages */
export interface ServerMessage extends BaseMessage {
  playerId?: string;
  gameId?: string;
}

// ============================================================
// CLIENT -> SERVER MESSAGE TYPES
// ============================================================

export type ClientMessageType =
  | 'ping'
  | 'join_game'
  | 'leave_game'
  | 'play_card'
  | 'pass'
  | 'get_game_state'
  | 'chat_message'
  | 'join_matchmaking'
  | 'leave_matchmaking'
  | 'matchmaking_status';

/** Ping - Keep connection alive and measure latency */
export interface PingMessage extends ClientMessage {
  type: 'ping';
}

/** JoinGame - Create or join a game */
export interface JoinGamePayload {
  gameMode?: GameMode;
  useAuthentic?: boolean;
  teamPlay?: boolean;
}

export interface JoinGameMessage extends ClientMessage {
  type: 'join_game';
  payload: JoinGamePayload;
}

/** LeaveGame - Leave current game */
export interface LeaveGameMessage extends ClientMessage {
  type: 'leave_game';
}

/** PlayCard - Play a card from hand */
export interface PlayCardPayload {
  suit: Card['suit'];
  value: Card['value'];
  id: string;
}

export interface PlayCardMessage extends ClientMessage {
  type: 'play_card';
  payload: PlayCardPayload;
}

/** Pass - Pass without objecting */
export interface PassMessage extends ClientMessage {
  type: 'pass';
}

/** GetGameState - Request current game state */
export interface GetGameStateMessage extends ClientMessage {
  type: 'get_game_state';
}

/** ChatMessage - Send chat message */
export interface ChatMessagePayload {
  message: string;
  type?: 'text' | 'emote';
}

export interface ChatMessage extends ClientMessage {
  type: 'chat_message';
  payload: ChatMessagePayload;
}

/** JoinMatchmaking - Join matchmaking queue */
export interface JoinMatchmakingPayload {
  queueType: QueueType;
  gameMode: 'septica';
}

export interface JoinMatchmakingMessage extends ClientMessage {
  type: 'join_matchmaking';
  payload: JoinMatchmakingPayload;
}

/** LeaveMatchmaking - Leave matchmaking queue */
export interface LeaveMatchmakingMessage extends ClientMessage {
  type: 'leave_matchmaking';
}

/** MatchmakingStatus - Request queue status */
export interface MatchmakingStatusMessage extends ClientMessage {
  type: 'matchmaking_status';
}

/** Union type for all client messages */
export type ClientMessageUnion =
  | PingMessage
  | JoinGameMessage
  | LeaveGameMessage
  | PlayCardMessage
  | PassMessage
  | GetGameStateMessage
  | ChatMessage
  | JoinMatchmakingMessage
  | LeaveMatchmakingMessage
  | MatchmakingStatusMessage;

// ============================================================
// SERVER -> CLIENT MESSAGE TYPES
// ============================================================

export type ServerMessageType =
  | 'pong'
  | 'connection_ack'
  | 'error'
  | 'game_state'
  | 'move_result'
  | 'objection_wait'
  | 'round_complete'
  | 'player_joined'
  | 'player_left'
  | 'game_end'
  | 'heartbeat'
  | 'chat_received'
  | 'matchmaking_joined'
  | 'matchmaking_update'
  | 'match_found'
  | 'matchmaking_left'
  | 'matchmaking_error'
  | 'game_started'
  | 'player_turn'
  | 'game_paused'
  | 'game_resumed';

/** Pong - Response to ping */
export interface PongPayload {
  serverTime: string;
}

export interface PongMessage extends ServerMessage {
  type: 'pong';
  payload: PongPayload;
}

/** ConnectionAck - Initial connection acknowledgment */
export interface ConnectionAckPayload {
  sessionId: string;
  serverTime: string;
  heartbeatInterval: number; // milliseconds
  maxMessageQueue: number;
  serverVersion?: string;
}

export interface ConnectionAckMessage extends ServerMessage {
  type: 'connection_ack';
  payload: ConnectionAckPayload;
}

/** Error - Error response */
export type ErrorType =
  | 'invalid_message'
  | 'not_authorized'
  | 'game_not_found'
  | 'player_not_in_game'
  | 'invalid_move'
  | 'not_player_turn'
  | 'game_full'
  | 'connection_failed'
  | 'rate_limited'
  | 'server_error';

export interface ErrorPayload {
  errorType: ErrorType;
  message: string;
  code?: number;
  details?: Record<string, unknown>;
}

export interface ErrorMessage extends ServerMessage {
  type: 'error';
  payload: ErrorPayload;
}

/** GameState - Full game state update */
export interface GameStatePayload extends GameState {}

export interface GameStateMessage extends ServerMessage {
  type: 'game_state';
  payload: GameStatePayload;
}

/** MoveResult - Result of a move attempt */
export interface MoveResultPayload extends MoveResult {}

export interface MoveResultMessage extends ServerMessage {
  type: 'move_result';
  payload: MoveResultPayload;
}

/** ObjectionWait - Waiting for objection decision */
export interface ObjectionWaitPayload {
  waitingPlayerId: string;
  lastPlayedCard: Card;
  lastPlayerId: string;
  validObjections: Card[];
  timeoutSeconds: number;
  canPass: boolean;
}

export interface ObjectionWaitMessage extends ServerMessage {
  type: 'objection_wait';
  payload: ObjectionWaitPayload;
}

/** RoundComplete - Round finished */
export interface RoundCompletePayload extends RoundResult {}

export interface RoundCompleteMessage extends ServerMessage {
  type: 'round_complete';
  payload: RoundCompletePayload;
}

/** PlayerJoined - New player joined */
export interface PlayerJoinedPayload {
  playerId: string;
  username: string;
}

export interface PlayerJoinedMessage extends ServerMessage {
  type: 'player_joined';
  payload: PlayerJoinedPayload;
}

/** PlayerLeft - Player left game */
export interface PlayerLeftPayload {
  playerId: string;
  reason: 'disconnected' | 'quit' | 'timeout';
}

export interface PlayerLeftMessage extends ServerMessage {
  type: 'player_left';
  payload: PlayerLeftPayload;
}

/** GameEnd - Game completed */
export interface GameEndPayloadMessage extends GameEndPayload {}

export interface GameEndMessage extends ServerMessage {
  type: 'game_end';
  payload: GameEndPayloadMessage;
}

/** Heartbeat - Server heartbeat */
export interface HeartbeatPayload {
  serverTime: string;
  clientCount?: number;
  activeGames?: number;
}

export interface HeartbeatMessage extends ServerMessage {
  type: 'heartbeat';
  payload: HeartbeatPayload;
}

/** ChatReceived - Chat message received */
export interface ChatReceivedPayload {
  playerId: string;
  username: string;
  message: string;
  type: 'text' | 'emote';
  timestamp: string;
}

export interface ChatReceivedMessage extends ServerMessage {
  type: 'chat_received';
  payload: ChatReceivedPayload;
}

/** MatchmakingJoined - Successfully joined queue */
export interface MatchmakingJoinedPayload {
  queueType: QueueType;
  message: string;
}

export interface MatchmakingJoinedMessage extends ServerMessage {
  type: 'matchmaking_joined';
  payload: MatchmakingJoinedPayload;
}

/** MatchmakingUpdate - Queue status update */
export interface MatchmakingUpdatePayload extends MatchmakingStatus {}

export interface MatchmakingUpdateMessage extends ServerMessage {
  type: 'matchmaking_update';
  payload: MatchmakingUpdatePayload;
}

/** MatchFound - Match found! */
export interface MatchFoundPayload extends MatchFound {}

export interface MatchFoundMessage extends ServerMessage {
  type: 'match_found';
  payload: MatchFoundPayload;
}

/** MatchmakingLeft - Left queue */
export interface MatchmakingLeftPayload {
  message: string;
}

export interface MatchmakingLeftMessage extends ServerMessage {
  type: 'matchmaking_left';
  payload: MatchmakingLeftPayload;
}

/** MatchmakingError - Queue error */
export interface MatchmakingErrorPayload {
  errorType: string;
  message: string;
}

export interface MatchmakingErrorMessage extends ServerMessage {
  type: 'matchmaking_error';
  payload: MatchmakingErrorPayload;
}

/** GameStarted - Game has begun */
export interface GameStartedPayload {
  gameId: string;
  gameMode: GameMode;
  players: Array<{
    id: string;
    username: string;
    position: number;
  }>;
  yourPosition: number;
}

export interface GameStartedMessage extends ServerMessage {
  type: 'game_started';
  payload: GameStartedPayload;
}

/** PlayerTurn - Turn changed */
export interface PlayerTurnPayload {
  playerId: string;
  username: string;
  yourTurn: boolean;
  timeoutSeconds?: number;
}

export interface PlayerTurnMessage extends ServerMessage {
  type: 'player_turn';
  payload: PlayerTurnPayload;
}

/** GamePaused - Game paused */
export interface GamePausedPayload {
  reason: string;
  pausedBy?: string;
}

export interface GamePausedMessage extends ServerMessage {
  type: 'game_paused';
  payload: GamePausedPayload;
}

/** GameResumed - Game resumed */
export interface GameResumedPayload {
  resumedBy?: string;
}

export interface GameResumedMessage extends ServerMessage {
  type: 'game_resumed';
  payload: GameResumedPayload;
}

/** Union type for all server messages */
export type ServerMessageUnion =
  | PongMessage
  | ConnectionAckMessage
  | ErrorMessage
  | GameStateMessage
  | MoveResultMessage
  | ObjectionWaitMessage
  | RoundCompleteMessage
  | PlayerJoinedMessage
  | PlayerLeftMessage
  | GameEndMessage
  | HeartbeatMessage
  | ChatReceivedMessage
  | MatchmakingJoinedMessage
  | MatchmakingUpdateMessage
  | MatchFoundMessage
  | MatchmakingLeftMessage
  | MatchmakingErrorMessage
  | GameStartedMessage
  | PlayerTurnMessage
  | GamePausedMessage
  | GameResumedMessage;

// ============================================================
// MESSAGE TYPE MAPS (for type-safe handlers)
// ============================================================

/** Map of message types to their payload types */
export interface ClientMessagePayloadMap {
  ping: undefined;
  join_game: JoinGamePayload;
  leave_game: undefined;
  play_card: PlayCardPayload;
  pass: undefined;
  get_game_state: undefined;
  chat_message: ChatMessagePayload;
  join_matchmaking: JoinMatchmakingPayload;
  leave_matchmaking: undefined;
  matchmaking_status: undefined;
}

/** Map of server message types to their payload types */
export interface ServerMessagePayloadMap {
  pong: PongPayload;
  connection_ack: ConnectionAckPayload;
  error: ErrorPayload;
  game_state: GameStatePayload;
  move_result: MoveResultPayload;
  objection_wait: ObjectionWaitPayload;
  round_complete: RoundCompletePayload;
  player_joined: PlayerJoinedPayload;
  player_left: PlayerLeftPayload;
  game_end: GameEndPayloadMessage;
  heartbeat: HeartbeatPayload;
  chat_received: ChatReceivedPayload;
  matchmaking_joined: MatchmakingJoinedPayload;
  matchmaking_update: MatchmakingUpdatePayload;
  match_found: MatchFoundPayload;
  matchmaking_left: MatchmakingLeftPayload;
  matchmaking_error: MatchmakingErrorPayload;
  game_started: GameStartedPayload;
  player_turn: PlayerTurnPayload;
  game_paused: GamePausedPayload;
  game_resumed: GameResumedPayload;
}

// ============================================================
// TYPE GUARDS
// ============================================================

export const isServerMessage = (obj: unknown): obj is ServerMessageUnion => {
  if (typeof obj !== 'object' || obj === null) return false;
  const msg = obj as Partial<ServerMessageUnion>;
  const validTypes: ServerMessageType[] = [
    'pong', 'connection_ack', 'error', 'game_state', 'move_result',
    'objection_wait', 'round_complete', 'player_joined', 'player_left',
    'game_end', 'heartbeat', 'chat_received', 'matchmaking_joined',
    'matchmaking_update', 'match_found', 'matchmaking_left',
    'matchmaking_error', 'game_started', 'player_turn', 'game_paused',
    'game_resumed'
  ];
  return typeof msg.type === 'string' && validTypes.includes(msg.type as ServerMessageType);
};

export const isClientMessage = (obj: unknown): obj is ClientMessageUnion => {
  if (typeof obj !== 'object' || obj === null) return false;
  const msg = obj as Partial<ClientMessageUnion>;
  const validTypes: ClientMessageType[] = [
    'ping', 'join_game', 'leave_game', 'play_card', 'pass',
    'get_game_state', 'chat_message', 'join_matchmaking',
    'leave_matchmaking', 'matchmaking_status'
  ];
  return typeof msg.type === 'string' && validTypes.includes(msg.type as ClientMessageType);
};

/** Type guard for specific message types */
export const isMessageOfType = <T extends ServerMessageType>(
  msg: ServerMessageUnion,
  type: T
): msg is Extract<ServerMessageUnion, { type: T }> => {
  return msg.type === type;
};

// ============================================================
// MESSAGE CREATORS (for client -> server)
// ============================================================

export const createPing = (): PingMessage => ({
  type: 'ping',
  id: crypto.randomUUID(),
  timestamp: new Date().toISOString(),
});

export const createJoinGame = (payload: JoinGamePayload): JoinGameMessage => ({
  type: 'join_game',
  id: crypto.randomUUID(),
  timestamp: new Date().toISOString(),
  payload,
});

export const createPlayCard = (payload: PlayCardPayload): PlayCardMessage => ({
  type: 'play_card',
  id: crypto.randomUUID(),
  timestamp: new Date().toISOString(),
  payload,
});

export const createPass = (): PassMessage => ({
  type: 'pass',
  id: crypto.randomUUID(),
  timestamp: new Date().toISOString(),
});

export const createLeaveGame = (): LeaveGameMessage => ({
  type: 'leave_game',
  id: crypto.randomUUID(),
  timestamp: new Date().toISOString(),
});

export const createGetGameState = (): GetGameStateMessage => ({
  type: 'get_game_state',
  id: crypto.randomUUID(),
  timestamp: new Date().toISOString(),
});

export const createChatMessage = (payload: ChatMessagePayload): ChatMessage => ({
  type: 'chat_message',
  id: crypto.randomUUID(),
  timestamp: new Date().toISOString(),
  payload,
});

export const createJoinMatchmaking = (payload: JoinMatchmakingPayload): JoinMatchmakingMessage => ({
  type: 'join_matchmaking',
  id: crypto.randomUUID(),
  timestamp: new Date().toISOString(),
  payload,
});

export const createLeaveMatchmaking = (): LeaveMatchmakingMessage => ({
  type: 'leave_matchmaking',
  id: crypto.randomUUID(),
  timestamp: new Date().toISOString(),
});
