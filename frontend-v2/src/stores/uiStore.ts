/**
 * UI State Store for Septica
 * Manages transient UI state: modals, toasts, card selection, hover states
 */

import { create } from 'zustand';
import { devtools } from 'zustand/middleware';
import type { Card } from '../types/game';

// ============================================================
// TYPES
// ============================================================

export type ToastType = 'info' | 'success' | 'warning' | 'error';

export interface Toast {
  id: string;
  message: string;
  type: ToastType;
  duration: number; // milliseconds
}

export interface ModalState {
  showSettings: boolean;
  showLeaveConfirm: boolean;
  showHelp: boolean;
}

export interface UIState {
  // Modal states
  modals: ModalState;

  // Toast notifications
  toasts: Toast[];

  // Card interaction states
  selectedCard: Card | null;
  hoveredCard: Card | null;

  // Actions
  showToast: (message: string, type: ToastType, duration?: number) => void;
  dismissToast: (id: string) => void;
  selectCard: (card: Card | null) => void;
  hoverCard: (card: Card | null) => void;
  setModal: (modal: keyof ModalState, open: boolean) => void;
  resetUI: () => void;
}

// ============================================================
// INITIAL STATE
// ============================================================

const initialModalState: ModalState = {
  showSettings: false,
  showLeaveConfirm: false,
  showHelp: false,
};

// ============================================================
// STORE
// ============================================================

export const useUIStore = create<UIState>()(
  devtools(
    (set, get) => ({
      // Initial state
      modals: initialModalState,
      toasts: [],
      selectedCard: null,
      hoveredCard: null,

      // Show a toast notification
      showToast: (message: string, type: ToastType, duration = 5000) => {
        const id = `toast-${Date.now()}-${Math.random().toString(36).substring(2, 9)}`;
        const toast: Toast = { id, message, type, duration };

        set((state) => ({
          toasts: [...state.toasts, toast],
        }));

        // Auto-dismiss after duration
        if (duration > 0) {
          setTimeout(() => {
            get().dismissToast(id);
          }, duration);
        }
      },

      // Dismiss a toast notification
      dismissToast: (id: string) => {
        set((state) => ({
          toasts: state.toasts.filter((toast) => toast.id !== id),
        }));
      },

      // Select a card (for playing)
      selectCard: (card: Card | null) => {
        set({ selectedCard: card });
      },

      // Hover over a card (for highlighting)
      hoverCard: (card: Card | null) => {
        set({ hoveredCard: card });
      },

      // Toggle modal visibility
      setModal: (modal: keyof ModalState, open: boolean) => {
        set((state) => ({
          modals: {
            ...state.modals,
            [modal]: open,
          },
        }));
      },

      // Reset all UI state
      resetUI: () => {
        set({
          modals: initialModalState,
          toasts: [],
          selectedCard: null,
          hoveredCard: null,
        });
      },
    }),
    {
      name: 'septica-ui-store',
    }
  )
);

// ============================================================
// SELECTORS (for optimized re-renders)
// ============================================================

export const selectModals = (state: UIState) => state.modals;
export const selectToasts = (state: UIState) => state.toasts;
export const selectSelectedCard = (state: UIState) => state.selectedCard;
export const selectHoveredCard = (state: UIState) => state.hoveredCard;
