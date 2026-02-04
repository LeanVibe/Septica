import { create } from 'zustand';
import { devtools } from 'zustand/middleware';

export type ConnectionStatus = 'disconnected' | 'connecting' | 'connected' | 'reconnecting' | 'error';

export interface ConnectionState {
  status: ConnectionStatus;
  attempts: number;
  latencyMs: number | null;
  lastMessageAt: number | null;
  lastError: string | null;
}

export interface ConnectionStoreState {
  connection: ConnectionState;
  setConnectionStatus: (status: ConnectionStatus) => void;
  setConnectionAttempts: (attempts: number) => void;
  setLatency: (latencyMs: number | null) => void;
  setLastMessageAt: (timestamp: number | null) => void;
  setConnectionError: (message: string | null) => void;
}

const initialConnectionState: ConnectionState = {
  status: 'disconnected',
  attempts: 0,
  latencyMs: null,
  lastMessageAt: null,
  lastError: null,
};

export const useConnectionStore = create<ConnectionStoreState>()(
  devtools(
    (set) => ({
      connection: initialConnectionState,
      setConnectionStatus: (status) =>
        set(
          (state) => ({
            connection: { ...state.connection, status },
          }),
          false,
          'connection/setStatus'
        ),
      setConnectionAttempts: (attempts) =>
        set(
          (state) => ({
            connection: { ...state.connection, attempts },
          }),
          false,
          'connection/setAttempts'
        ),
      setLatency: (latencyMs) =>
        set(
          (state) => ({
            connection: { ...state.connection, latencyMs },
          }),
          false,
          'connection/setLatency'
        ),
      setLastMessageAt: (timestamp) =>
        set(
          (state) => ({
            connection: { ...state.connection, lastMessageAt: timestamp },
          }),
          false,
          'connection/setLastMessageAt'
        ),
      setConnectionError: (message) =>
        set(
          (state) => ({
            connection: { ...state.connection, lastError: message },
          }),
          false,
          'connection/setError'
        ),
    }),
    { name: 'septica-connection' }
  )
);
