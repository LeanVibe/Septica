/**
 * WebSocket Client for Septica Game Testing
 * Implements the exact message protocol from the Go backend
 */

class SepticaWebSocketClient {
    constructor() {
        this.ws = null;
        this.isConnected = false;
        this.connectionAttempts = 0;
        this.maxReconnectAttempts = 5;
        this.reconnectDelay = 1000; // 1 second, will increase exponentially
        this.heartbeatInterval = null;
        this.heartbeatTimer = null;
        this.messageQueue = [];
        this.maxMessageQueue = 100;
        
        // Connection info
        this.playerId = null;
        this.sessionId = null;
        this.gameId = null;
        this.serverTime = null;
        this.heartbeatIntervalMs = 30000; // 30 seconds default
        
        // Event handlers
        this.onConnectionChange = null;
        this.onMessage = null;
        this.onError = null;
        this.onGameStateUpdate = null;
        this.onMoveResult = null;
        
        // Message types (matching backend constants)
        this.MESSAGE_TYPES = {
            // Client -> Server
            PING: 'ping',
            JOIN_GAME: 'join_game',
            LEAVE_GAME: 'leave_game',
            PLAY_CARD: 'play_card',
            GET_GAME_STATE: 'get_game_state',
            CHAT_MESSAGE: 'chat_message',
            
            // Server -> Client
            PONG: 'pong',
            CONNECTION_ACK: 'connection_ack',
            ERROR: 'error',
            GAME_STATE: 'game_state',
            MOVE_RESULT: 'move_result',
            PLAYER_JOINED: 'player_joined',
            PLAYER_LEFT: 'player_left',
            GAME_END: 'game_end',
            HEARTBEAT: 'heartbeat',
            CHAT_RECEIVED: 'chat_received',
            GAME_STARTED: 'game_started',
            TRICK_COMPLETE: 'trick_complete',
            PLAYER_TURN: 'player_turn',
            GAME_PAUSED: 'game_paused',
            GAME_RESUMED: 'game_resumed'
        };
        
        this.ERROR_TYPES = {
            INVALID_MESSAGE: 'invalid_message',
            NOT_AUTHORIZED: 'not_authorized',
            GAME_NOT_FOUND: 'game_not_found',
            PLAYER_NOT_IN_GAME: 'player_not_in_game',
            INVALID_MOVE: 'invalid_move',
            NOT_PLAYER_TURN: 'not_player_turn',
            GAME_FULL: 'game_full',
            CONNECTION_FAILED: 'connection_failed',
            RATE_LIMITED: 'rate_limited',
            SERVER_ERROR: 'server_error'
        };
        
        // Bind methods
        this.handleMessage = this.handleMessage.bind(this);
        this.handleOpen = this.handleOpen.bind(this);
        this.handleClose = this.handleClose.bind(this);
        this.handleError = this.handleError.bind(this);
        this.sendHeartbeat = this.sendHeartbeat.bind(this);
    }
    
    /**
     * Connect to WebSocket server
     */
    async connect(url = 'ws://localhost:8080/ws/connect') {
        try {
            if (this.ws && this.ws.readyState === WebSocket.OPEN) {
                this.log('Already connected');
                return;
            }
            
            this.log(`Connecting to ${url}...`);
            this.ws = new WebSocket(url);
            
            this.ws.addEventListener('open', this.handleOpen);
            this.ws.addEventListener('message', this.handleMessage);
            this.ws.addEventListener('close', this.handleClose);
            this.ws.addEventListener('error', this.handleError);
            
            return new Promise((resolve, reject) => {
                const timeout = setTimeout(() => {
                    reject(new Error('Connection timeout'));
                }, 10000);
                
                this.ws.addEventListener('open', () => {
                    clearTimeout(timeout);
                    resolve();
                }, { once: true });
                
                this.ws.addEventListener('error', (error) => {
                    clearTimeout(timeout);
                    reject(error);
                }, { once: true });
            });
        } catch (error) {
            this.logError('Connection error', error);
            throw error;
        }
    }
    
    /**
     * Disconnect from WebSocket server
     */
    disconnect() {
        if (this.heartbeatTimer) {
            clearInterval(this.heartbeatTimer);
            this.heartbeatTimer = null;
        }
        
        if (this.ws) {
            this.ws.removeEventListener('open', this.handleOpen);
            this.ws.removeEventListener('message', this.handleMessage);
            this.ws.removeEventListener('close', this.handleClose);
            this.ws.removeEventListener('error', this.handleError);
            
            if (this.ws.readyState === WebSocket.OPEN) {
                this.ws.close(1000, 'Client disconnect');
            }
            this.ws = null;
        }
        
        this.isConnected = false;
        this.playerId = null;
        this.sessionId = null;
        this.gameId = null;
        this.connectionAttempts = 0;
        
        this.notifyConnectionChange();
        this.log('Disconnected');
    }
    
    /**
     * Handle WebSocket open event
     */
    handleOpen() {
        this.isConnected = true;
        this.connectionAttempts = 0;
        this.reconnectDelay = 1000; // Reset delay
        
        this.log('Connected to WebSocket server');
        this.notifyConnectionChange();
    }
    
    /**
     * Handle WebSocket close event
     */
    handleClose(event) {
        this.isConnected = false;
        
        if (this.heartbeatTimer) {
            clearInterval(this.heartbeatTimer);
            this.heartbeatTimer = null;
        }
        
        this.log(`Connection closed: ${event.code} - ${event.reason}`);
        this.notifyConnectionChange();
        
        // Auto-reconnect if not a clean disconnect
        if (event.code !== 1000 && this.connectionAttempts < this.maxReconnectAttempts) {
            this.attemptReconnect();
        }
    }
    
    /**
     * Handle WebSocket error event
     */
    handleError(error) {
        this.logError('WebSocket error', error);
        if (this.onError) {
            this.onError(error);
        }
    }
    
    /**
     * Handle incoming WebSocket messages
     */
    handleMessage(event) {
        try {
            const message = JSON.parse(event.data);
            this.log('Received message', message);
            
            // Handle specific message types
            switch (message.type) {
                case this.MESSAGE_TYPES.CONNECTION_ACK:
                    this.handleConnectionAck(message);
                    break;
                    
                case this.MESSAGE_TYPES.PONG:
                    this.handlePong(message);
                    break;
                    
                case this.MESSAGE_TYPES.HEARTBEAT:
                    this.handleHeartbeat(message);
                    break;
                    
                case this.MESSAGE_TYPES.GAME_STATE:
                    this.handleGameState(message);
                    break;
                    
                case this.MESSAGE_TYPES.MOVE_RESULT:
                    this.handleMoveResult(message);
                    break;
                    
                case this.MESSAGE_TYPES.PLAYER_JOINED:
                    this.handlePlayerJoined(message);
                    break;
                    
                case this.MESSAGE_TYPES.PLAYER_LEFT:
                    this.handlePlayerLeft(message);
                    break;
                    
                case this.MESSAGE_TYPES.GAME_END:
                    this.handleGameEnd(message);
                    break;
                    
                case this.MESSAGE_TYPES.ERROR:
                    this.handleServerError(message);
                    break;
                    
                default:
                    this.log('Unknown message type', message.type);
            }
            
            // Notify general message handler
            if (this.onMessage) {
                this.onMessage(message);
            }
            
        } catch (error) {
            this.logError('Error parsing message', error);
        }
    }
    
    /**
     * Handle connection acknowledgment
     */
    handleConnectionAck(message) {
        if (message.payload) {
            this.playerId = message.player_id;
            this.sessionId = message.payload.session_id;
            this.serverTime = new Date(message.payload.server_time);
            this.heartbeatIntervalMs = message.payload.heartbeat_interval || 30000;
            this.maxMessageQueue = message.payload.max_message_queue || 100;
            
            this.log('Connection acknowledged', {
                playerId: this.playerId,
                sessionId: this.sessionId,
                heartbeatInterval: this.heartbeatIntervalMs
            });
            
            // Start heartbeat
            this.startHeartbeat();
            this.notifyConnectionChange();
        }
    }
    
    /**
     * Handle pong response
     */
    handlePong(message) {
        this.log('Received pong');
    }
    
    /**
     * Handle heartbeat from server
     */
    handleHeartbeat(message) {
        if (message.payload && message.payload.server_time) {
            this.serverTime = new Date(message.payload.server_time);
        }
        // Respond with pong
        this.sendMessage(this.MESSAGE_TYPES.PONG, null, {});
    }
    
    /**
     * Handle game state update
     */
    handleGameState(message) {
        if (message.payload) {
            this.gameId = message.game_id || message.payload.game_id;
            this.log('Game state updated', message.payload);
            
            if (this.onGameStateUpdate) {
                this.onGameStateUpdate(message.payload);
            }
        }
    }
    
    /**
     * Handle move result
     */
    handleMoveResult(message) {
        this.log('Move result received', message.payload);
        
        if (this.onMoveResult) {
            this.onMoveResult(message.payload);
        }
    }
    
    /**
     * Handle player joined notification
     */
    handlePlayerJoined(message) {
        this.log('Player joined', message.payload);
    }
    
    /**
     * Handle player left notification
     */
    handlePlayerLeft(message) {
        this.log('Player left', message.payload);
    }
    
    /**
     * Handle game end notification
     */
    handleGameEnd(message) {
        this.log('Game ended', message.payload);
        this.gameId = null;
    }
    
    /**
     * Handle server error
     */
    handleServerError(message) {
        const error = message.payload || {};
        this.logError('Server error', error);
        
        if (this.onError) {
            this.onError({
                type: 'server_error',
                message: error.message || 'Unknown server error',
                errorType: error.error_type,
                code: error.code,
                details: error.details
            });
        }
    }
    
    /**
     * Send a message to the server
     */
    sendMessage(type, gameId = null, payload = {}) {
        if (!this.isConnected || !this.ws || this.ws.readyState !== WebSocket.OPEN) {
            this.logError('Cannot send message - not connected');
            return false;
        }
        
        const message = {
            type: type,
            id: this.generateMessageId(),
            timestamp: new Date().toISOString()
        };
        
        if (gameId) {
            message.game_id = gameId;
        }
        
        if (payload && Object.keys(payload).length > 0) {
            message.payload = payload;
        }
        
        try {
            this.ws.send(JSON.stringify(message));
            this.log('Sent message', message);
            return true;
        } catch (error) {
            this.logError('Error sending message', error);
            return false;
        }
    }
    
    /**
     * Send ping to server
     */
    ping() {
        return this.sendMessage(this.MESSAGE_TYPES.PING);
    }
    
    /**
     * Join a game
     */
    joinGame(gameMode = 'casual') {
        return this.sendMessage(this.MESSAGE_TYPES.JOIN_GAME, null, {
            game_mode: gameMode
        });
    }
    
    /**
     * Leave current game
     */
    leaveGame() {
        if (!this.gameId) {
            this.logError('No game to leave');
            return false;
        }
        return this.sendMessage(this.MESSAGE_TYPES.LEAVE_GAME, this.gameId);
    }
    
    /**
     * Play a card
     */
    playCard(suit, value, cardId = null) {
        if (!this.gameId) {
            this.logError('No active game');
            return false;
        }
        
        const payload = {
            suit: suit,
            value: parseInt(value)
        };
        
        if (cardId) {
            payload.id = cardId;
        }
        
        return this.sendMessage(this.MESSAGE_TYPES.PLAY_CARD, this.gameId, payload);
    }
    
    /**
     * Get current game state
     */
    getGameState() {
        if (!this.gameId) {
            this.logError('No active game');
            return false;
        }
        return this.sendMessage(this.MESSAGE_TYPES.GET_GAME_STATE, this.gameId);
    }
    
    /**
     * Send chat message
     */
    sendChatMessage(message, type = 'text') {
        if (!this.gameId) {
            this.logError('No active game');
            return false;
        }
        
        return this.sendMessage(this.MESSAGE_TYPES.CHAT_MESSAGE, this.gameId, {
            message: message,
            type: type
        });
    }
    
    /**
     * Start heartbeat timer
     */
    startHeartbeat() {
        if (this.heartbeatTimer) {
            clearInterval(this.heartbeatTimer);
        }
        
        this.heartbeatTimer = setInterval(this.sendHeartbeat, this.heartbeatIntervalMs);
        this.log(`Heartbeat started (${this.heartbeatIntervalMs}ms interval)`);
    }
    
    /**
     * Send heartbeat ping
     */
    sendHeartbeat() {
        if (this.isConnected) {
            this.ping();
        }
    }
    
    /**
     * Attempt to reconnect
     */
    async attemptReconnect() {
        this.connectionAttempts++;
        this.log(`Reconnection attempt ${this.connectionAttempts}/${this.maxReconnectAttempts}`);
        
        // Exponential backoff
        const delay = Math.min(this.reconnectDelay * Math.pow(2, this.connectionAttempts - 1), 30000);
        
        setTimeout(async () => {
            try {
                await this.connect();
            } catch (error) {
                this.logError('Reconnection failed', error);
                
                if (this.connectionAttempts < this.maxReconnectAttempts) {
                    this.attemptReconnect();
                } else {
                    this.log('Max reconnection attempts reached');
                }
            }
        }, delay);
    }
    
    /**
     * Generate unique message ID
     */
    generateMessageId() {
        return 'msg_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
    }
    
    /**
     * Notify connection change
     */
    notifyConnectionChange() {
        if (this.onConnectionChange) {
            this.onConnectionChange({
                isConnected: this.isConnected,
                playerId: this.playerId,
                sessionId: this.sessionId,
                gameId: this.gameId,
                serverTime: this.serverTime,
                heartbeatInterval: this.heartbeatIntervalMs
            });
        }
    }
    
    /**
     * Log message
     */
    log(message, data = null) {
        const timestamp = new Date().toLocaleTimeString();
        console.log(`[${timestamp}] WebSocket: ${message}`, data || '');
        
        // Emit to UI logger if available
        if (window.gameUI && window.gameUI.logMessage) {
            window.gameUI.logMessage('WEBSOCKET', message, data);
        }
    }
    
    /**
     * Log error
     */
    logError(message, error = null) {
        const timestamp = new Date().toLocaleTimeString();
        console.error(`[${timestamp}] WebSocket Error: ${message}`, error || '');
        
        // Emit to UI logger if available
        if (window.gameUI && window.gameUI.logMessage) {
            window.gameUI.logMessage('ERROR', message, error);
        }
    }
    
    /**
     * Get connection status
     */
    getStatus() {
        return {
            isConnected: this.isConnected,
            playerId: this.playerId,
            sessionId: this.sessionId,
            gameId: this.gameId,
            serverTime: this.serverTime,
            heartbeatInterval: this.heartbeatIntervalMs,
            connectionAttempts: this.connectionAttempts,
            readyState: this.ws ? this.ws.readyState : WebSocket.CLOSED
        };
    }
    
    /**
     * Get WebSocket ready state as string
     */
    getReadyStateString() {
        if (!this.ws) return 'CLOSED';
        
        switch (this.ws.readyState) {
            case WebSocket.CONNECTING: return 'CONNECTING';
            case WebSocket.OPEN: return 'OPEN';
            case WebSocket.CLOSING: return 'CLOSING';
            case WebSocket.CLOSED: return 'CLOSED';
            default: return 'UNKNOWN';
        }
    }
}

// Export for global use
window.SepticaWebSocketClient = SepticaWebSocketClient;