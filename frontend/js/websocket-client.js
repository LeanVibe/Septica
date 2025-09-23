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
        
        // Network performance monitoring
        this.latencyHistory = [];
        this.maxLatencyHistory = 20;
        this.pingStartTimes = new Map();
        this.currentLatency = 0;
        this.averageLatency = 0;
        this.connectionQuality = 'unknown'; // excellent, good, fair, poor
        this.lastLatencyUpdate = 0;
        
        // Connection info
        this.playerId = null;
        this.sessionId = null;
        this.gameId = null;
        this.serverTime = null;
        this.heartbeatIntervalMs = 30000; // 30 seconds default

        // Move tracking
        this.pendingMove = null;
        
        // Event handlers
        this.onConnectionChange = null;
        this.onMessage = null;
        this.onError = null;
        this.onGameStateUpdate = null;
        this.onMoveResult = null;
        this.onPlayerJoined = null;
        this.onPlayerLeft = null;
        this.onMatchmakingJoined = null;
        this.onMatchmakingUpdate = null;
        this.onMatchFound = null;
        this.onMatchmakingLeft = null;
        this.onMatchmakingError = null;
        
        // Message types (matching backend constants)
        this.MESSAGE_TYPES = {
            // Client -> Server
            PING: 'ping',
            JOIN_GAME: 'join_game',
            LEAVE_GAME: 'leave_game',
            PLAY_CARD: 'play_card',
            GET_GAME_STATE: 'get_game_state',
            CHAT_MESSAGE: 'chat_message',
            JOIN_MATCHMAKING: 'join_matchmaking',
            LEAVE_MATCHMAKING: 'leave_matchmaking',
            MATCHMAKING_STATUS: 'matchmaking_status',
            
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
            MATCHMAKING_JOINED: 'matchmaking_joined',
            MATCHMAKING_UPDATE: 'matchmaking_update',
            MATCH_FOUND: 'match_found',
            MATCHMAKING_LEFT: 'matchmaking_left',
            MATCHMAKING_ERROR: 'matchmaking_error',
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
            
            // Generate user_id if not already set, or get from localStorage for silent signin
            if (!this.playerId) {
                this.playerId = localStorage.getItem('septica_user_id') || crypto.randomUUID();
                localStorage.setItem('septica_user_id', this.playerId);
            }
            
            // Add user_id parameter to WebSocket URL
            const connectUrl = `${url}?user_id=${this.playerId}`;
            url = connectUrl;
            
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
        console.log('🟢 DEBUG: WebSocket connection opened successfully');
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
        console.log(`🔴 DEBUG: WebSocket closed - Code: ${event.code}, Reason: "${event.reason}", Clean: ${event.code === 1000}`);
        this.notifyConnectionChange();
        
        // Auto-reconnect if not a clean disconnect
        if (event.code !== 1000 && this.connectionAttempts < this.maxReconnectAttempts) {
            console.log(`🔄 DEBUG: Auto-reconnecting... (attempt ${this.connectionAttempts + 1}/${this.maxReconnectAttempts})`);
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
                    
                case this.MESSAGE_TYPES.MATCHMAKING_JOINED:
                    this.handleMatchmakingJoined(message);
                    break;
                    
                case this.MESSAGE_TYPES.MATCHMAKING_UPDATE:
                    this.handleMatchmakingUpdate(message);
                    break;
                    
                case this.MESSAGE_TYPES.MATCH_FOUND:
                    this.handleMatchFound(message);
                    break;
                    
                case this.MESSAGE_TYPES.MATCHMAKING_LEFT:
                    this.handleMatchmakingLeft(message);
                    break;
                    
                case this.MESSAGE_TYPES.MATCHMAKING_ERROR:
                    this.handleMatchmakingError(message);
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
        console.log('🔍 DEBUG: handleConnectionAck called with:', message);
        
        try {
            if (message.payload) {
                this.playerId = message.player_id;
                this.sessionId = message.payload.session_id;
                this.serverTime = new Date(message.payload.server_time);
                this.heartbeatIntervalMs = message.payload.heartbeat_interval || 30000;
                this.maxMessageQueue = message.payload.max_message_queue || 100;
                
                console.log('🎯 DEBUG: Connection ACK processed successfully', {
                    playerId: this.playerId,
                    sessionId: this.sessionId,
                    heartbeatInterval: this.heartbeatIntervalMs
                });
                
                this.log('Connection acknowledged', {
                    playerId: this.playerId,
                    sessionId: this.sessionId,
                    heartbeatInterval: this.heartbeatIntervalMs
                });
                
                // Start heartbeat
                console.log('❤️ DEBUG: Starting heartbeat...');
                this.startHeartbeat();
                console.log('📡 DEBUG: Notifying connection change...');
                this.notifyConnectionChange();
                console.log('✅ DEBUG: handleConnectionAck completed successfully');
            } else {
                console.log('⚠️ DEBUG: No payload in connection_ack message');
            }
        } catch (error) {
            console.error('💥 DEBUG: Error in handleConnectionAck:', error);
            throw error; // Re-throw to see the error in console
        }
    }
    
    /**
     * Handle pong response and calculate latency
     */
    handlePong(message) {
        let latency = 0;
        
        if (message.payload && message.payload.ping_id) {
            const pingId = message.payload.ping_id;
            const startTime = this.pingStartTimes.get(pingId);
            
            if (startTime) {
                latency = performance.now() - startTime;
                this.pingStartTimes.delete(pingId);
                this.updateLatencyMetrics(latency);
            }
        }
        
        this.log(`Received pong (latency: ${Math.round(latency)}ms)`);
    }
    
    /**
     * Handle heartbeat from server
     */
    handleHeartbeat(message) {
        if (message.payload && message.payload.server_time) {
            this.serverTime = new Date(message.payload.server_time);
        }
        // Note: No pong response needed for server heartbeats
        // The backend handles WebSocket-level ping/pong separately
        this.log('Received heartbeat from server');
    }
    
    /**
     * Handle game state update
     */
    handleGameState(message) {
        if (message.payload) {
            this.gameId = message.game_id || message.payload.game_id;

            // Process Romanian Septica specific game state
            const gameState = this.processRomanianSepticaGameState(message.payload);

            this.log('Romanian Septica game state updated', gameState);

            if (this.onGameStateUpdate) {
                this.onGameStateUpdate(gameState);
            }
        }
    }
    
    /**
     * Handle move result
     */
    handleMoveResult(message) {
        const result = this.processMoveResult(message.payload);
        this.log('Romanian Septica move result received', result);

        // Validate against pending move
        if (this.pendingMove) {
            const moveLatency = Date.now() - this.pendingMove.timestamp;
            this.log(`Move completed in ${moveLatency}ms`);

            // Clear pending move
            this.pendingMove = null;
        }

        // Enhanced move result processing
        if (result.valid) {
            this.log('✅ Move accepted by server');

            if (result.trick_complete) {
                this.log('🎯 Trick completed!', {
                    winner: result.trick_winner,
                    points: result.points_won || 0
                });
            }

            if (result.game_complete) {
                this.log('🏆 Game completed!', {
                    winner: result.winner_id
                });
            }
        } else {
            this.logError('❌ Move rejected by server', result.error || 'Unknown error');
        }

        if (this.onMoveResult) {
            this.onMoveResult(result);
        }
    }
    
    /**
     * Handle player joined notification
     */
    handlePlayerJoined(message) {
        this.log('Player joined', message.payload);
        
        if (this.onPlayerJoined) {
            this.onPlayerJoined(message.payload);
        }
    }
    
    /**
     * Handle player left notification
     */
    handlePlayerLeft(message) {
        this.log('Player left', message.payload);
        
        if (this.onPlayerLeft) {
            this.onPlayerLeft(message.payload);
        }
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
     * Handle matchmaking joined confirmation
     */
    handleMatchmakingJoined(message) {
        this.log('Matchmaking joined', message.payload);
        
        if (this.onMatchmakingJoined) {
            this.onMatchmakingJoined(message.payload);
        }
    }
    
    /**
     * Handle matchmaking queue update
     */
    handleMatchmakingUpdate(message) {
        this.log('Matchmaking update', message.payload);
        
        if (this.onMatchmakingUpdate) {
            this.onMatchmakingUpdate(message.payload);
        }
    }
    
    /**
     * Handle match found notification
     */
    handleMatchFound(message) {
        this.log('Match found!', message.payload);
        
        // Set the game ID from the match
        if (message.payload && message.payload.game_id) {
            this.gameId = message.payload.game_id;
        }
        
        if (this.onMatchFound) {
            this.onMatchFound(message.payload);
        }
    }
    
    /**
     * Handle matchmaking left confirmation
     */
    handleMatchmakingLeft(message) {
        this.log('Left matchmaking', message.payload);
        
        if (this.onMatchmakingLeft) {
            this.onMatchmakingLeft(message.payload);
        }
    }
    
    /**
     * Handle matchmaking error
     */
    handleMatchmakingError(message) {
        this.logError('Matchmaking error', message.payload);
        
        if (this.onMatchmakingError) {
            this.onMatchmakingError(message.payload);
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
            this.log('Sent Romanian Septica message', { type, gameId, payload });
            return true;
        } catch (error) {
            this.logError('Error sending message', error);
            return false;
        }
    }
    
    /**
     * Send ping to server with latency tracking
     */
    ping() {
        const messageId = this.generateMessageId();
        const startTime = performance.now();
        this.pingStartTimes.set(messageId, startTime);
        
        const success = this.sendMessage(this.MESSAGE_TYPES.PING, null, { ping_id: messageId });
        
        // Clean up old ping times (in case pong is never received)
        setTimeout(() => {
            this.pingStartTimes.delete(messageId);
        }, 10000);
        
        return success;
    }
    
    /**
     * Join a game
     */
    joinGame(gameId, gameMode = 'casual') {
        if (!gameId) {
            this.logError('Game ID is required to join a game');
            return false;
        }
        return this.sendMessage(this.MESSAGE_TYPES.JOIN_GAME, gameId, {
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
     * Play a card (Romanian Septica specific)
     */
    playCard(suit, value, cardId = null) {
        if (!this.gameId) {
            this.logError('No active game');
            return false;
        }

        // Validate inputs
        if (!suit || !value) {
            this.logError('Invalid card data: missing suit or value');
            return false;
        }

        const payload = {
            suit: suit,
            value: parseInt(value)
        };

        if (cardId) {
            payload.id = cardId;
        }

        // Add client-side validation timestamp
        payload.client_timestamp = new Date().toISOString();

        // Log the Romanian Septica card play
        this.log(`Playing Romanian Septica card: ${this.getCardDisplayName(suit, value)}`);

        // Store the pending move for validation
        this.pendingMove = {
            suit: suit,
            value: parseInt(value),
            id: cardId,
            timestamp: Date.now()
        };

        const success = this.sendMessage(this.MESSAGE_TYPES.PLAY_CARD, this.gameId, payload);

        if (!success) {
            this.pendingMove = null;
        }

        return success;
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
     * Join matchmaking queue
     */
    joinMatchmaking(queueType = 'casual', gameMode = 'septica') {
        this.log(`Joining matchmaking queue: ${queueType}`);
        return this.sendMessage(this.MESSAGE_TYPES.JOIN_MATCHMAKING, null, {
            queue_type: queueType,
            game_mode: gameMode
        });
    }
    
    /**
     * Leave matchmaking queue
     */
    leaveMatchmaking() {
        this.log('Leaving matchmaking queue');
        return this.sendMessage(this.MESSAGE_TYPES.LEAVE_MATCHMAKING);
    }
    
    /**
     * Get matchmaking status
     */
    getMatchmakingStatus() {
        return this.sendMessage(this.MESSAGE_TYPES.MATCHMAKING_STATUS);
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
    
    /**
     * Update latency metrics
     */
    updateLatencyMetrics(latency) {
        this.currentLatency = latency;
        this.latencyHistory.push(latency);
        
        // Keep history size manageable
        if (this.latencyHistory.length > this.maxLatencyHistory) {
            this.latencyHistory.shift();
        }
        
        // Calculate average latency
        this.averageLatency = this.latencyHistory.reduce((sum, l) => sum + l, 0) / this.latencyHistory.length;
        
        // Determine connection quality
        this.updateConnectionQuality();
        
        // Update performance monitor if available
        if (window.PerformanceMonitor && window.performanceMonitor) {
            window.performanceMonitor.updateNetworkLatency(latency);
        }
        
        // Update UI
        this.updateLatencyDisplay();
        
        this.lastLatencyUpdate = Date.now();
    }
    
    /**
     * Update connection quality based on latency
     */
    updateConnectionQuality() {
        const avg = this.averageLatency;
        
        if (avg < 50) {
            this.connectionQuality = 'excellent';
        } else if (avg < 100) {
            this.connectionQuality = 'good';
        } else if (avg < 200) {
            this.connectionQuality = 'fair';
        } else {
            this.connectionQuality = 'poor';
        }
    }
    
    /**
     * Update latency display in UI
     */
    updateLatencyDisplay() {
        // Update connection status if element exists
        const statusElement = document.getElementById('connectionStatus');
        if (statusElement) {
            let latencyElement = statusElement.querySelector('.latency-indicator');
            if (!latencyElement) {
                latencyElement = document.createElement('div');
                latencyElement.className = 'latency-indicator';
                latencyElement.innerHTML = `
                    <span class="latency-text">${Math.round(this.currentLatency)}ms</span>
                    <div class="latency-bars ${this.connectionQuality}">
                        <div class="latency-bar ${this.currentLatency < 50 ? 'active' : ''}"></div>
                        <div class="latency-bar ${this.currentLatency < 100 ? 'active' : ''}"></div>
                        <div class="latency-bar ${this.currentLatency < 150 ? 'active' : ''}"></div>
                        <div class="latency-bar ${this.currentLatency < 200 ? 'active' : ''}"></div>
                    </div>
                `;
                statusElement.appendChild(latencyElement);
            } else {
                latencyElement.querySelector('.latency-text').textContent = `${Math.round(this.currentLatency)}ms`;
                const bars = latencyElement.querySelector('.latency-bars');
                bars.className = `latency-bars ${this.connectionQuality}`;
                
                const barElements = bars.querySelectorAll('.latency-bar');
                barElements[0].className = `latency-bar ${this.currentLatency < 50 ? 'active' : ''}`;
                barElements[1].className = `latency-bar ${this.currentLatency < 100 ? 'active' : ''}`;
                barElements[2].className = `latency-bar ${this.currentLatency < 150 ? 'active' : ''}`;
                barElements[3].className = `latency-bar ${this.currentLatency < 200 ? 'active' : ''}`;
            }
        }
    }
    
    /**
     * Get network performance metrics
     */
    getNetworkMetrics() {
        return {
            currentLatency: this.currentLatency,
            averageLatency: Math.round(this.averageLatency),
            connectionQuality: this.connectionQuality,
            latencyHistory: [...this.latencyHistory],
            lastUpdate: this.lastLatencyUpdate
        };
    }

    // ===== ROMANIAN SEPTICA SPECIFIC METHODS =====

    /**
     * Process Romanian Septica game state from backend
     */
    processRomanianSepticaGameState(rawGameState) {
        // Normalize backend game state format
        const gameState = {
            game_id: rawGameState.game_id || rawGameState.gameId,
            your_turn: rawGameState.your_turn !== undefined ? rawGameState.your_turn : rawGameState.yourTurn,
            current_player_id: rawGameState.current_player_id || rawGameState.currentPlayerId,
            status: rawGameState.status || rawGameState.gameStatus || 'playing',
            trick_number: rawGameState.trick_number || rawGameState.trickNumber || 1,
            move_number: rawGameState.move_number || rawGameState.moveNumber || 1,
            table_cards: this.normalizeCards(rawGameState.table_cards || rawGameState.tableCards || []),
            your_cards: this.normalizeCards(rawGameState.your_cards || rawGameState.playerCards || rawGameState.hand || []),
            valid_moves: this.normalizeCards(rawGameState.valid_moves || rawGameState.validMoves || []),
            scores: this.normalizeScores(rawGameState.scores || rawGameState.playerScores || {}),
            players: rawGameState.players || [],
            winner_id: rawGameState.winner_id || rawGameState.winnerId
        };

        // Add Romanian Septica specific metadata
        if (gameState.table_cards.length > 0) {
            gameState.last_played_card = gameState.table_cards[gameState.table_cards.length - 1];
        }

        // Calculate Romanian Septica specific info
        gameState.total_points_on_table = this.calculatePointsOnTable(gameState.table_cards);
        gameState.sevens_played = this.countSevensPlayed(gameState.table_cards);

        return gameState;
    }

    /**
     * Process move result from backend
     */
    processMoveResult(rawResult) {
        return {
            valid: rawResult.valid !== undefined ? rawResult.valid : rawResult.success,
            error: rawResult.error || rawResult.message,
            trick_complete: rawResult.trick_complete || rawResult.trickComplete,
            game_complete: rawResult.game_complete || rawResult.gameComplete,
            winner_id: rawResult.winner_id || rawResult.winnerId,
            trick_winner: rawResult.trick_winner || rawResult.trickWinner,
            points_won: rawResult.points_won || rawResult.pointsWon || 0,
            new_game_state: rawResult.new_game_state || rawResult.gameState
        };
    }

    /**
     * Normalize card format from backend
     */
    normalizeCards(cards) {
        if (!Array.isArray(cards)) return [];

        return cards.map(card => ({
            suit: card.suit,
            value: parseInt(card.value),
            id: card.id || `${card.suit}_${card.value}`
        }));
    }

    /**
     * Normalize scores format from backend
     */
    normalizeScores(scores) {
        if (typeof scores !== 'object' || !scores) return {};

        // Convert to consistent format
        const normalized = {};
        Object.keys(scores).forEach(playerId => {
            normalized[playerId] = parseInt(scores[playerId]) || 0;
        });

        return normalized;
    }

    /**
     * Calculate points on table (only 10s and Aces count in Romanian Septica)
     */
    calculatePointsOnTable(tableCards) {
        return tableCards.reduce((total, card) => {
            if (card.value === 10 || card.value === 14) { // 10s and Aces
                return total + 1;
            }
            return total;
        }, 0);
    }

    /**
     * Count sevens played (important in Romanian Septica)
     */
    countSevensPlayed(tableCards) {
        return tableCards.filter(card => card.value === 7).length;
    }

    /**
     * Get display name for card (Romanian Septica context)
     */
    getCardDisplayName(suit, value) {
        const valueNames = {
            7: '7', 8: '8', 9: '9', 10: '10',
            11: 'J', 12: 'Q', 13: 'K', 14: 'A'
        };

        const valueName = valueNames[value] || value;
        const suitName = suit.charAt(0).toUpperCase() + suit.slice(1);

        if (value === 7) {
            return `${valueName} of ${suitName} (Septica!)`;
        } else if (value === 14 || value === 10) {
            return `${valueName} of ${suitName} (Point card)`;
        }

        return `${valueName} of ${suitName}`;
    }

    /**
     * Join Romanian Septica specific matchmaking
     */
    joinRomanianSepticaMatchmaking(skillLevel = 'beginner') {
        return this.joinMatchmaking('romanian_septica', {
            game_mode: 'septica',
            skill_level: skillLevel,
            preferred_language: 'romanian'
        });
    }
}

// Export for global use
window.SepticaWebSocketClient = SepticaWebSocketClient;