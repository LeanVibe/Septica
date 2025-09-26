const DEFAULT_ENDPOINT = 'ws://localhost:8080/ws/connect';

export const MESSAGE_TYPES = Object.freeze({
  PING: 'ping',
  PONG: 'pong',
  CONNECTION_ACK: 'connection_ack',
  ERROR: 'error',
  MATCH_FOUND: 'match_found',
  MATCHMAKING_JOINED: 'matchmaking_joined',
  MATCHMAKING_LEFT: 'matchmaking_left',
  MATCHMAKING_UPDATE: 'matchmaking_update',
  MATCHMAKING_ERROR: 'matchmaking_error',
  GAME_STATE: 'game_state',
  MOVE_RESULT: 'move_result',
  OBJECTION_WAIT: 'objection_wait',
  ROUND_COMPLETE: 'round_complete',
  GAME_END: 'game_end'
});

export class SepticaSocket {
  constructor({ endpoint = DEFAULT_ENDPOINT, userId, onMessage } = {}) {
    this.endpoint = endpoint;
    this.userId = userId ?? crypto.randomUUID();
    this.onMessage = onMessage ?? (() => {});
    this.status = 'disconnected';
    this.latency = 0;
    this.session = null;
    this.__reconnectTimer = null;
    this.__heartbeatTimer = null;
  }

  connect() {
    const url = new URL(this.endpoint);
    url.searchParams.set('user_id', this.userId);
    this.status = 'connecting';
    this.socket = new WebSocket(url.toString());
    this.socket.addEventListener('open', () => this.__handleOpen());
    this.socket.addEventListener('message', (event) => this.__handleMessage(event));
    this.socket.addEventListener('close', () => this.__handleClose());
    this.socket.addEventListener('error', () => this.__scheduleReconnect());
  }

  disconnect() {
    clearTimeout(this.__reconnectTimer);
    clearInterval(this.__heartbeatTimer);
    this.socket?.close(1000, 'client disconnect');
    this.status = 'disconnected';
  }

  send(payload) {
    if (this.socket?.readyState === WebSocket.OPEN) {
      this.socket.send(JSON.stringify(payload));
    }
  }

  joinMatchmaking(queueType = 'casual') {
    this.send({ t: 'join_matchmaking', payload: { queue_type: queueType, game_mode: 'septica' } });
  }

  leaveMatchmaking() {
    this.send({ t: 'leave_matchmaking' });
  }

  playCard(card) {
    this.send({ t: 'play_card', payload: card });
  }

  pass() {
    this.send({ t: 'pass' });
  }

  requestGameState(gameId) {
    this.send({ t: 'get_game_state', game_id: gameId });
  }

  __handleOpen() {
    this.status = 'connected';
    this.__scheduleHeartbeat();
  }

  __handleMessage(event) {
    try {
      const message = JSON.parse(event.data);
      if (message.type === MESSAGE_TYPES.PONG) {
        const now = performance.now();
        this.latency = now - (this.__lastPingAt ?? now);
      }
      if (message.type === MESSAGE_TYPES.CONNECTION_ACK) {
        this.session = message.payload?.session_id ?? null;
      }
      this.onMessage(message);
    } catch (error) {
      console.error('Failed to parse server message', error, event.data);
    }
  }

  __handleClose() {
    this.status = 'disconnected';
    this.__scheduleReconnect();
  }

  __scheduleReconnect() {
    if (this.status === 'reconnecting') return;
    this.status = 'reconnecting';
    clearTimeout(this.__reconnectTimer);
    this.__reconnectTimer = setTimeout(() => {
      this.connect();
    }, 1500);
  }

  __scheduleHeartbeat() {
    clearInterval(this.__heartbeatTimer);
    this.__heartbeatTimer = setInterval(() => {
      if (this.socket?.readyState === WebSocket.OPEN) {
        this.__lastPingAt = performance.now();
        this.send({ type: MESSAGE_TYPES.PING, timestamp: Date.now() });
      }
    }, 25000);
  }
}
