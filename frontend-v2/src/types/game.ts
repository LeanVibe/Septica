/**
 * Core Game Types for Septica
 * Based on backend/internal/game/authentic_engine.go
 */

// ============================================================
// CARD TYPES
// ============================================================

export type CardSuit = 'hearts' | 'diamonds' | 'clubs' | 'spades';

export type CardValue = 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14;

export interface Card {
  suit: CardSuit;
  value: CardValue;
  id: string;
}

/** Human-readable card value names */
export const CardValueNames: Record<CardValue, string> = {
  7: '7',
  8: '8',
  9: '9',
  10: '10',
  11: 'J',
  12: 'Q',
  13: 'K',
  14: 'A',
};

/** Card suit symbols for display */
export const CardSuitSymbols: Record<CardSuit, string> = {
  hearts: '♥',
  diamonds: '♦',
  clubs: '♣',
  spades: '♠',
};

/** Card suit colors for styling */
export const CardSuitColors: Record<CardSuit, string> = {
  hearts: '#e74c3c',
  diamonds: '#e74c3c',
  clubs: '#2c3e50',
  spades: '#2c3e50',
};

/** Point values for scoring */
export const CardPoints: Partial<Record<CardValue, number>> = {
  10: 1, // All 10s are worth 1 point
  14: 1, // Aces are worth 1 point
};

/** Special point card: 10 of diamonds is worth 2 points */
export const isSpecialTenOfDiamonds = (card: Card): boolean =>
  card.suit === 'diamonds' && card.value === 10;

// ============================================================
// PLAYER TYPES
// ============================================================

export interface Player {
  id: string;
  username: string;
  hand: Card[];
  score: number;
  isConnected: boolean;
  isAI?: boolean;
}

export interface PlayerPublic {
  id: string;
  username: string;
  cardCount: number;
  score: number;
  isConnected: boolean;
  isAI?: boolean;
}

/** Team configuration for 4-player mode */
export interface Team {
  id: 'team1' | 'team2';
  playerIds: string[];
  score: number;
}

// ============================================================
// GAME MODE TYPES
// ============================================================

export type GameMode = '2_player' | '3_player' | '4_player';

export interface GameModeConfig {
  mode: GameMode;
  maxPlayers: number;
  useTeams: boolean;
  wildEights: boolean;
  description: string;
}

export const GameModeConfigs: Record<GameMode, GameModeConfig> = {
  '2_player': {
    mode: '2_player',
    maxPlayers: 2,
    useTeams: false,
    wildEights: false,
    description: 'Classic 1v1 Septica',
  },
  '3_player': {
    mode: '3_player',
    maxPlayers: 3,
    useTeams: false,
    wildEights: true,
    description: '3-player with wild 8s',
  },
  '4_player': {
    mode: '4_player',
    maxPlayers: 4,
    useTeams: true,
    wildEights: false,
    description: '2v2 Team play',
  },
};

// ============================================================
// GAME PHASE TYPES
// ============================================================

export type GamePhase =
  | 'waiting'      // Waiting for players to join
  | 'playing'      // Active gameplay
  | 'objection'    // Waiting for objection decision
  | 'round_end'    // Round just completed
  | 'finished';    // Game over

export type GameStatus = 'waiting' | 'playing' | 'finished';

// ============================================================
// GAME STATE TYPES
// ============================================================

/** Complete game state (server -> client) */
export interface GameState {
  // Identity
  gameId: string;
  currentPlayerId: string;
  
  // Player perspective
  yourTurn: boolean;
  yourPlayerId: string;
  
  // Cards
  yourCards: Card[];
  yourCardCount: number;
  opponentCardCounts: Record<string, number>;
  tableCards: Card[];
  validMoves: Card[];
  
  // Scoring
  scores: Record<string, number>;
  teamScores?: Record<string, number>;
  trickNumber: number;
  moveNumber: number;
  
  // Objection system
  waitingForObjection: boolean;
  lastPlayedCard: Card | null;
  lastPlayerId: string | null;
  canPass: boolean;
  objectionTimeout: number; // seconds remaining
  validObjections: Card[];
  
  // Multiplayer
  gameMode: GameMode;
  players: PlayerPublic[];
  teams?: Team[];
  yourTeamId?: string;
  
  // Sync
  sequenceNumber: number;
  status: GameStatus;
  
  // Timing
  createdAt: string;
  startedAt?: string;
  lastMoveAt?: string;
}

/** Minimal game state for lists/lobby */
export interface GameSummary {
  gameId: string;
  status: GameStatus;
  gameMode: GameMode;
  playerCount: number;
  maxPlayers: number;
  createdAt: string;
}

// ============================================================
// MOVE & ACTION TYPES
// ============================================================

export type PlayerActionType = 'PLAY_CARD' | 'PASS';

export interface PlayerAction {
  type: PlayerActionType;
  playerId: string;
  card?: Card; // undefined for PASS
}

export interface MoveResult {
  valid: boolean;
  error?: string;
  trickComplete: boolean;
  gameComplete: boolean;
  winnerId?: string;
  pointsAwarded: number;
  roundComplete: boolean;
  objectionPhase: boolean;
  nextPlayerId: string;
}

// ============================================================
// ROUND & TRICK TYPES
// ============================================================

export interface RoundResult {
  roundNumber: number;
  collectorPlayerId: string;
  collectorTeamId?: string;
  pointsAwarded: number;
  cardsCollected: Card[];
  wasObjected: boolean;
  objectionCard?: Card;
  updatedScores: Record<string, number>;
  updatedTeamScores?: Record<string, number>;
  nextPlayerId: string;
}

export interface Trick {
  cards: Card[];
  playedBy: string[]; // player IDs in order
  winnerId: string;
  points: number;
}

// ============================================================
// GAME CONFIGURATION
// ============================================================

export interface GameConfig {
  gameMode: GameMode;
  useAuthenticRules: boolean;
  maxDuration?: number; // minutes
  objectionTimeout: number; // seconds
  enableChat: boolean;
  enableSpectators: boolean;
}

export const DefaultGameConfig: GameConfig = {
  gameMode: '2_player',
  useAuthenticRules: true,
  maxDuration: 30,
  objectionTimeout: 30,
  enableChat: true,
  enableSpectators: false,
};

// ============================================================
// GAME STATS & HISTORY
// ============================================================

export interface GameStats {
  duration: number; // milliseconds
  totalMoves: number;
  totalTricks: number;
  sevensPlayed: number;
  eightsPlayed: number;
  pointCardsWon: Record<string, number>;
}

export interface GameEndPayload {
  winnerId?: string;
  winningTeamId?: string;
  reason: 'normal' | 'disconnection' | 'timeout' | 'forfeit';
  finalScore: Record<string, number>;
  finalTeamScore?: Record<string, number>;
  gameStats: GameStats;
}

// ============================================================
// MATCHMAKING TYPES
// ============================================================

export type QueueType = 'ranked' | 'casual' | 'tournament';

export interface MatchmakingStatus {
  inQueue: boolean;
  queueType?: QueueType;
  queuePosition?: number;
  estimatedWaitTime?: number; // seconds
  playersInQueue?: number;
  waitTime?: number; // seconds elapsed
}

export interface MatchFound {
  gameId: string;
  opponentId: string;
  opponentName: string;
  opponentRating?: number;
  waitTimeMs: number;
}

// ============================================================
// UTILITY TYPES
// ============================================================

/** Card location in the game */
export type CardLocation = 'deck' | 'hand' | 'table' | 'collected';

/** Player connection status */
export type ConnectionStatus = 'connected' | 'disconnected' | 'reconnecting';

/** Game error codes */
export type GameErrorCode =
  | 'INVALID_MOVE'
  | 'NOT_PLAYER_TURN'
  | 'CARD_NOT_IN_HAND'
  | 'CANNOT_BEAT_CARD'
  | 'GAME_NOT_FOUND'
  | 'GAME_NOT_ACTIVE'
  | 'PLAYER_NOT_IN_GAME'
  | 'WAITING_FOR_OBJECTION'
  | 'NOT_OBJECTION_PHASE';

export interface GameError {
  code: GameErrorCode;
  message: string;
  details?: Record<string, unknown>;
}

// ============================================================
// TYPE GUARDS
// ============================================================

export const isValidCard = (obj: unknown): obj is Card => {
  if (typeof obj !== 'object' || obj === null) return false;
  const card = obj as Partial<Card>;
  return (
    typeof card.id === 'string' &&
    typeof card.value === 'number' &&
    typeof card.suit === 'string' &&
    ['hearts', 'diamonds', 'clubs', 'spades'].includes(card.suit)
  );
};

export const isWildCard = (card: Card, gameMode: GameMode): boolean => {
  if (card.value === 7) return true; // 7s are always wild
  if (card.value === 8 && gameMode === '3_player') return true; // 8s wild in 3-player
  return false;
};

export const calculateCardPoints = (card: Card): number => {
  if (card.value !== 10 && card.value !== 14) return 0;
  if (card.value === 10 && card.suit === 'diamonds') return 2;
  if (card.value === 10) return 1;
  if (card.value === 14) return 1;
  return 0;
};

export const getTotalPointsInDeck = (): number => {
  // 4 aces × 1 point + 4 tens × 1 point + 1 ten of diamonds extra point = 11
  return 11;
};
