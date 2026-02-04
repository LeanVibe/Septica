/**
 * Romanian Septica Rules Engine
 * Ported from backend/internal/game/authentic_engine.go
 *
 * Core Rules:
 * - 7s are always wild (can beat any card)
 * - 8s are wild only in 3-player mode
 * - Same value beats
 * - 10s = 1 point (10 of diamonds = 2 points)
 * - Aces = 1 point
 * - Total 11 points in deck
 */

import type { Card, GameMode } from '../types/game';

// ============================================================
// WILD CARD DETECTION
// ============================================================

/**
 * Check if a card is wild in the current game mode
 * @param card - The card to check
 * @param gameMode - Current game mode
 * @returns true if the card is wild
 */
export const isWildCard = (card: Card, gameMode: GameMode): boolean => {
  // 7s are always wild
  if (card.value === 7) return true;

  // 8s are wild only in 3-player mode
  if (card.value === 8 && gameMode === '3_player') return true;

  return false;
};

// ============================================================
// CARD BEATING LOGIC
// ============================================================

/**
 * Determine if a defending card can beat an attacking card
 * Based on authentic Romanian Septica rules
 *
 * @param attackCard - The card on the table (being defended against)
 * @param defendCard - The card being played to defend
 * @param gameMode - Current game mode (affects wild 8s)
 * @returns true if defendCard can beat attackCard
 */
export const canBeat = (
  attackCard: Card,
  defendCard: Card,
  gameMode: GameMode
): boolean => {
  // Wild cards always beat
  if (isWildCard(defendCard, gameMode)) {
    return true;
  }

  // Same value beats
  if (defendCard.value === attackCard.value) {
    return true;
  }

  return false;
};

/**
 * Alias for canBeat - used for objection phase
 */
export const canObjectToCard = (
  playedCard: Card,
  objectionCard: Card,
  gameMode: GameMode
): boolean => {
  return canBeat(playedCard, objectionCard, gameMode);
};

// ============================================================
// MOVE VALIDATION
// ============================================================

/**
 * Check if playing a card is a valid move
 *
 * In Romanian Septica (objection-based):
 * - If no cards on table, any card is valid (starting round)
 * - If cards on table, must be able to beat the last card (objection phase)
 *
 * @param card - The card to play
 * @param tableCards - Current cards on the table
 * @param gameMode - Current game mode
 * @returns true if the move is valid
 */
export const isValidMove = (
  card: Card,
  tableCards: Card[],
  gameMode: GameMode
): boolean => {
  // Starting a new round: any card is valid
  if (tableCards.length === 0) {
    return true;
  }

  // Objection phase: must be able to beat the last card
  const lastCard = tableCards[tableCards.length - 1];
  return canBeat(lastCard, card, gameMode);
};

// ============================================================
// POINT CALCULATION
// ============================================================

/**
 * Calculate the point value of a single card
 * - 10 of diamonds = 2 points
 * - Other 10s = 1 point
 * - Aces = 1 point
 * - All other cards = 0 points
 *
 * @param card - The card to evaluate
 * @returns Point value (0, 1, or 2)
 */
export const getCardPoints = (card: Card): number => {
  // 10 of diamonds is special: 2 points
  if (card.value === 10 && card.suit === 'diamonds') {
    return 2;
  }

  // Other 10s: 1 point
  if (card.value === 10) {
    return 1;
  }

  // Aces: 1 point
  if (card.value === 14) {
    return 1;
  }

  return 0;
};

/**
 * Calculate total points in a collection of cards
 * Used for trick scoring
 *
 * @param cards - Array of cards to score
 * @returns Total points
 */
export const calculateTrickPoints = (cards: Card[]): number => {
  return cards.reduce((sum, card) => sum + getCardPoints(card), 0);
};

/**
 * Get the total number of points available in a full deck
 * Romanian Septica: 11 points total
 * - 4 aces × 1 point = 4 points
 * - 4 tens × 1 point = 4 points
 * - 1 ten of diamonds extra point = 1 point
 * Total: 11 points
 */
export const getTotalDeckPoints = (): number => {
  return 11;
};

// ============================================================
// VALID MOVES CALCULATION
// ============================================================

/**
 * Get all valid moves from a player's hand
 *
 * @param hand - Player's current hand
 * @param tableCards - Current cards on the table
 * @param gameMode - Current game mode
 * @returns Array of cards that can be legally played
 */
export const getValidMoves = (
  hand: Card[],
  tableCards: Card[],
  gameMode: GameMode
): Card[] => {
  // If no cards on table, all cards are valid (starting round)
  if (tableCards.length === 0) {
    return [...hand];
  }

  // Objection phase: only cards that can beat the last card
  const lastCard = tableCards[tableCards.length - 1];
  return hand.filter((card) => canBeat(lastCard, card, gameMode));
};

// ============================================================
// HELPER FUNCTIONS
// ============================================================

/**
 * Check if a player has any valid moves
 * Used to determine if PASS is the only option
 *
 * @param hand - Player's current hand
 * @param tableCards - Current cards on the table
 * @param gameMode - Current game mode
 * @returns true if at least one valid move exists
 */
export const hasValidMoves = (
  hand: Card[],
  tableCards: Card[],
  gameMode: GameMode
): boolean => {
  return getValidMoves(hand, tableCards, gameMode).length > 0;
};

/**
 * Count the number of wild cards in a hand
 * Useful for AI strategy
 *
 * @param hand - Player's cards
 * @param gameMode - Current game mode
 * @returns Number of wild cards
 */
export const countWildCards = (hand: Card[], gameMode: GameMode): number => {
  return hand.filter((card) => isWildCard(card, gameMode)).length;
};

/**
 * Count the number of point cards in a hand
 * Useful for scoring preview
 *
 * @param hand - Player's cards
 * @returns Number of point-bearing cards
 */
export const countPointCards = (hand: Card[]): number => {
  return hand.filter((card) => getCardPoints(card) > 0).length;
};

/**
 * Get the total point value of a hand
 * Useful for AI strategy and hand evaluation
 *
 * @param hand - Player's cards
 * @returns Total points if all cards were captured
 */
export const getHandPoints = (hand: Card[]): number => {
  return calculateTrickPoints(hand);
};

// ============================================================
// EXPORT ALL
// ============================================================

export const RomanianRules = {
  // Core logic
  isWildCard,
  canBeat,
  canObjectToCard,
  isValidMove,

  // Scoring
  getCardPoints,
  calculateTrickPoints,
  getTotalDeckPoints,

  // Move generation
  getValidMoves,
  hasValidMoves,

  // Helper utilities
  countWildCards,
  countPointCards,
  getHandPoints,
};

export default RomanianRules;
