import { create } from 'zustand';
import { devtools } from 'zustand/middleware';
import type { Card, GameState } from '../types';

export interface GameStoreState {
  game: GameState | null;
  setGame: (game: GameState | null) => void;
  playCard: (card: Card) => void;
  pass: () => void;
  objectToTrick: (card: Card) => void;
  updateFromServer: (state: GameState) => void;
}

export const useGameStore = create<GameStoreState>()(
  devtools(
    (set, get) => ({
      game: null,
      setGame: (game) =>
        set(
          () => ({
            game,
          }),
          false,
          'game/setGame'
        ),
      playCard: (card) => {
        const current = get().game;
        if (!current) return;
        set(
          () => ({
            game: {
              ...current,
              yourCards: current.yourCards.filter((c) => c.id !== card.id),
              tableCards: [...current.tableCards, card],
              yourTurn: false,
            },
          }),
          false,
          'game/playCard'
        );
      },
      pass: () => {
        const current = get().game;
        if (!current) return;
        set(
          () => ({
            game: {
              ...current,
              canPass: false,
              waitingForObjection: false,
              yourTurn: false,
            },
          }),
          false,
          'game/pass'
        );
      },
      objectToTrick: (card) => {
        const current = get().game;
        if (!current) return;
        set(
          () => ({
            game: {
              ...current,
              yourCards: current.yourCards.filter((c) => c.id !== card.id),
              tableCards: [...current.tableCards, card],
              waitingForObjection: false,
              yourTurn: false,
            },
          }),
          false,
          'game/objectToTrick'
        );
      },
      updateFromServer: (state) =>
        set(
          () => ({
            game: state,
          }),
          false,
          'game/updateFromServer'
        ),
    }),
    { name: 'septica-game' }
  )
);

export const selectValidMoves = (state: GameStoreState): Card[] =>
  state.game?.validMoves ?? [];

export const selectCanPass = (state: GameStoreState): boolean =>
  state.game?.canPass ?? false;

export const selectIsMyTurn = (state: GameStoreState): boolean =>
  state.game?.yourTurn ?? false;
