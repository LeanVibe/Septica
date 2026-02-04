import { MessageHandler, type SocketMessage } from './MessageHandler';
import { useConnectionStore } from '../stores/connectionStore';

export type ConnectionInfo = {
  isConnected: boolean;
  playerId: string | null;
  sessionId: string | null;
  gameId: string | null;
  heartbeatIntervalMs: number;
  connectionAttempts: number;
};

export type WebSocketClientOptions = {
  url?: string;
  maxReconnectAttempts?: number;
  reconnectDelayMs?: number;
  heartbeatIntervalMs?: number;
};

const DEFAULT_URL = 'ws://localhost:8082/ws/connect';

export const MESSAGE_TYPES = {
  PING: 'ping',
  PONG: 'pong',
  CONNECTION_ACK: 'connection_ack',
  HEARTBEAT: 'heartbeat',
  GAME_STATE: 'game_state',
  MOVE_RESULT: 'move_result',
  MATCHMAKING_JOINED: 'matchmaking_joined',
  MATCHMAKING_UPDATE: 'matchmaking_update',
  MATCH_FOUND: 'match_found',
  MATCHMAKING_LEFT: 'matchmaking_left',
  MATCHMAKING_ERROR: 'matchmaking_error',
  ERROR: 'error',
} as const;

export class WebSocketClient {
  private ws: WebSocket | null = null;
  private heartbeatTimer: number | null = null;
  private pingStartTimes = new Map<string, number>();
  private messageHandler = new MessageHandler();

  private isConnected = false;
  private connectionAttempts = 0;
  private maxReconnectAttempts: number;
  private reconnectDelayMs: number;
  private heartbeatIntervalMs: number;

  private playerId: string | null = null;
  private sessionId: string | null = null;
  private gameId: string | null = null;

  onConnectionChange: ((info: ConnectionInfo) => void) | null = null;
  onError: ((error: unknown) => void) | null = null;

  constructor(options: WebSocketClientOptions = {}) {
    this.maxReconnectAttempts = options.maxReconnectAttempts ?? 5;
    this.reconnectDelayMs = options.reconnectDelayMs ?? 1000;
    this.heartbeatIntervalMs = options.heartbeatIntervalMs ?? 30000;

    this.messageHandler.setHandler(MESSAGE_TYPES.CONNECTION_ACK, (message) => this.handleConnectionAck(message));
    this.messageHandler.setHandler(MESSAGE_TYPES.PONG, (message) => this.handlePong(message));
    this.messageHandler.setHandler(MESSAGE_TYPES.HEARTBEAT, (message) => this.handleHeartbeat(message));
    this.messageHandler.setHandler(MESSAGE_TYPES.ERROR, (message) => this.handleServerError(message));
    this.messageHandler.setOnAny(() => {
      useConnectionStore.getState().setLastMessageAt(Date.now());
    });
  }

  async connect(url: string = DEFAULT_URL) {
    if (this.ws && this.ws.readyState === WebSocket.OPEN) return;

    if (!this.playerId && typeof crypto !== 'undefined' && 'randomUUID' in crypto) {
      this.playerId = crypto.randomUUID();
    }

    const connectUrl = this.playerId ? `${url}?user_id=${this.playerId}` : url;

    useConnectionStore.getState().setConnectionStatus('connecting');

    this.ws = new WebSocket(connectUrl);
    this.ws.addEventListener('open', () => this.handleOpen());
    this.ws.addEventListener('message', (event) => this.handleMessage(event));
    this.ws.addEventListener('close', (event) => this.handleClose(event));
    this.ws.addEventListener('error', (event) => this.handleError(event));

    return new Promise<void>((resolve, reject) => {
      const timeout = window.setTimeout(() => {
        reject(new Error('Connection timeout'));
      }, 10000);

      this.ws?.addEventListener(
        'open',
        () => {
          window.clearTimeout(timeout);
          resolve();
        },
        { once: true }
      );

      this.ws?.addEventListener(
        'error',
        (error) => {
          window.clearTimeout(timeout);
          reject(error);
        },
        { once: true }
      );
    });
  }

  disconnect() {
    if (this.heartbeatTimer) {
      window.clearInterval(this.heartbeatTimer);
      this.heartbeatTimer = null;
    }

    if (this.ws) {
      if (this.ws.readyState === WebSocket.OPEN) {
        this.ws.close(1000, 'Client disconnect');
      }
      this.ws = null;
    }

    this.isConnected = false;
    this.connectionAttempts = 0;
    this.gameId = null;
    this.sessionId = null;

    useConnectionStore.getState().setConnectionStatus('disconnected');
    this.notifyConnectionChange();
  }

  sendMessage(type: string, payload?: Record<string, unknown>) {
    if (!this.ws || this.ws.readyState !== WebSocket.OPEN) return false;

    const message = {
      type,
      id: this.generateMessageId(),
      timestamp: new Date().toISOString(),
      payload,
    };

    this.ws.send(JSON.stringify(message));
    return true;
  }

  ping() {
    const pingId = this.generateMessageId();
    this.pingStartTimes.set(pingId, performance.now());
    this.sendMessage(MESSAGE_TYPES.PING, { ping_id: pingId });
  }

  getStatus(): ConnectionInfo {
    return {
      isConnected: this.isConnected,
      playerId: this.playerId,
      sessionId: this.sessionId,
      gameId: this.gameId,
      heartbeatIntervalMs: this.heartbeatIntervalMs,
      connectionAttempts: this.connectionAttempts,
    };
  }

  getMessageHandler() {
    return this.messageHandler;
  }

  private handleOpen() {
    this.isConnected = true;
    this.connectionAttempts = 0;
    useConnectionStore.getState().setConnectionStatus('connected');
    this.startHeartbeat();
    this.notifyConnectionChange();
  }

  private handleClose(event: CloseEvent) {
    this.isConnected = false;
    if (this.heartbeatTimer) {
      window.clearInterval(this.heartbeatTimer);
      this.heartbeatTimer = null;
    }

    if (event.code !== 1000 && this.connectionAttempts < this.maxReconnectAttempts) {
      useConnectionStore.getState().setConnectionStatus('reconnecting');
      this.attemptReconnect();
    } else {
      useConnectionStore.getState().setConnectionStatus('disconnected');
    }

    this.notifyConnectionChange();
  }

  private handleError(event: Event) {
    useConnectionStore.getState().setConnectionStatus('error');
    useConnectionStore.getState().setConnectionError('WebSocket error');
    if (this.onError) this.onError(event);
  }

  private handleMessage(event: MessageEvent) {
    const data = typeof event.data === 'string' ? event.data : event.data?.toString?.() ?? '';
    this.messageHandler.handleRawMessage(data);
  }

  private handleConnectionAck(message: SocketMessage) {
    const payload = (message.payload ?? {}) as Record<string, unknown>;
    this.playerId = (payload.player_id as string) ?? (message.player_id as string) ?? this.playerId;
    this.sessionId = (payload.session_id as string) ?? (message.session_id as string) ?? this.sessionId;
    const interval = payload.heartbeat_interval as number | undefined;
    if (typeof interval === 'number') {
      this.heartbeatIntervalMs = interval;
      this.startHeartbeat();
    }
    this.notifyConnectionChange();
  }

  private handlePong(message: SocketMessage) {
    const payload = (message.payload ?? {}) as Record<string, unknown>;
    const pingId = payload.ping_id as string | undefined;
    if (!pingId) return;

    const startTime = this.pingStartTimes.get(pingId);
    if (!startTime) return;

    const latency = performance.now() - startTime;
    this.pingStartTimes.delete(pingId);
    useConnectionStore.getState().setLatency(Math.round(latency));
  }

  private handleHeartbeat(message: SocketMessage) {
    const payload = (message.payload ?? {}) as Record<string, unknown>;
    const interval = payload.heartbeat_interval as number | undefined;
    if (typeof interval === 'number' && interval !== this.heartbeatIntervalMs) {
      this.heartbeatIntervalMs = interval;
      this.startHeartbeat();
    }
  }

  private handleServerError(message: SocketMessage) {
    const payload = (message.payload ?? {}) as Record<string, unknown>;
    const messageText = (payload.message as string) ?? 'Server error';
    useConnectionStore.getState().setConnectionError(messageText);
    if (this.onError) this.onError(payload);
  }

  private startHeartbeat() {
    if (this.heartbeatTimer) {
      window.clearInterval(this.heartbeatTimer);
    }
    this.heartbeatTimer = window.setInterval(() => this.ping(), this.heartbeatIntervalMs);
  }

  private attemptReconnect() {
    this.connectionAttempts += 1;
    useConnectionStore.getState().setConnectionAttempts(this.connectionAttempts);

    const delay = Math.min(this.reconnectDelayMs * 2 ** (this.connectionAttempts - 1), 30000);
    window.setTimeout(() => {
      this.connect().catch((error) => {
        if (this.connectionAttempts < this.maxReconnectAttempts) {
          this.attemptReconnect();
        } else {
          useConnectionStore.getState().setConnectionStatus('error');
          useConnectionStore.getState().setConnectionError((error as Error).message);
        }
      });
    }, delay);
  }

  private notifyConnectionChange() {
    if (this.onConnectionChange) {
      this.onConnectionChange(this.getStatus());
    }
  }

  private generateMessageId() {
    return `msg_${Date.now()}_${Math.random().toString(36).slice(2, 10)}`;
  }
}
