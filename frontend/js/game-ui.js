/**
 * Game UI Manager for Septica Testing App
 * Handles all UI interactions and game state display
 */

class GameUI {
    constructor() {
        this.wsClient = null;
        this.currentGameState = null;
        this.messageLog = [];
        this.maxLogEntries = 1000;
        
        // UI Elements
        this.elements = {};
        this.initializeElements();
        
        // Event handlers
        this.bindEvents();
        
        // Initialize PWA features
        this.initializePWA();
        
        // Card suits and symbols
        this.cardSuits = {
            'hearts': '♥',
            'diamonds': '♦',
            'clubs': '♣',
            'spades': '♠'
        };
        
        this.cardSuitColors = {
            'hearts': '#e74c3c',
            'diamonds': '#e74c3c',
            'clubs': '#2c3e50',
            'spades': '#2c3e50'
        };
        
        this.cardValueNames = {
            7: '7', 8: '8', 9: '9', 10: '10',
            11: 'J', 12: 'Q', 13: 'K', 14: 'A'
        };
        
        this.log('UI initialized');
    }
    
    /**
     * Initialize UI elements
     */
    initializeElements() {
        // Connection elements
        this.elements.connectionStatus = document.getElementById('connectionStatus');
        this.elements.statusIndicator = document.getElementById('statusIndicator');
        this.elements.statusText = document.getElementById('statusText');
        this.elements.serverUrl = document.getElementById('serverUrl');
        this.elements.connectBtn = document.getElementById('connectBtn');
        this.elements.disconnectBtn = document.getElementById('disconnectBtn');
        this.elements.pingBtn = document.getElementById('pingBtn');
        
        // Connection info
        this.elements.playerId = document.getElementById('playerId');
        this.elements.sessionId = document.getElementById('sessionId');
        this.elements.serverTime = document.getElementById('serverTime');
        this.elements.heartbeatInterval = document.getElementById('heartbeatInterval');
        
        // Game controls
        this.elements.gameMode = document.getElementById('gameMode');
        this.elements.joinGameBtn = document.getElementById('joinGameBtn');
        this.elements.leaveGameBtn = document.getElementById('leaveGameBtn');
        this.elements.getGameStateBtn = document.getElementById('getGameStateBtn');
        
        // Game info
        this.elements.gameId = document.getElementById('gameId');
        this.elements.yourTurn = document.getElementById('yourTurn');
        this.elements.currentPlayer = document.getElementById('currentPlayer');
        this.elements.gameStatus = document.getElementById('gameStatus');
        this.elements.trickNumber = document.getElementById('trickNumber');
        this.elements.moveNumber = document.getElementById('moveNumber');
        
        // Game board
        this.elements.tableCards = document.getElementById('tableCards');
        this.elements.playerHand = document.getElementById('playerHand');
        this.elements.validMoves = document.getElementById('validMoves');
        this.elements.scoresContainer = document.getElementById('scoresContainer');
        
        // Quick play
        this.elements.cardSuit = document.getElementById('cardSuit');
        this.elements.cardValue = document.getElementById('cardValue');
        this.elements.playCardBtn = document.getElementById('playCardBtn');
        
        // Message log
        this.elements.messageLog = document.getElementById('messageLog');
        this.elements.clearLogBtn = document.getElementById('clearLogBtn');
        this.elements.exportLogBtn = document.getElementById('exportLogBtn');
        this.elements.autoScrollLog = document.getElementById('autoScrollLog');
        
        // Error handling
        this.elements.errorOverlay = document.getElementById('errorOverlay');
        this.elements.errorMessage = document.getElementById('errorMessage');
        this.elements.closeErrorBtn = document.getElementById('closeErrorBtn');
        
        // Loading
        this.elements.loadingOverlay = document.getElementById('loadingOverlay');
        
        // PWA Install
        this.elements.installBanner = document.getElementById('installBanner');
        this.elements.installBtn = document.getElementById('installBtn');
        this.elements.dismissBannerBtn = document.getElementById('dismissBannerBtn');
    }
    
    /**
     * Bind event handlers
     */
    bindEvents() {
        // Connection events
        this.elements.connectBtn.addEventListener('click', () => this.handleConnect());
        this.elements.disconnectBtn.addEventListener('click', () => this.handleDisconnect());
        this.elements.pingBtn.addEventListener('click', () => this.handlePing());
        
        // Game events
        this.elements.joinGameBtn.addEventListener('click', () => this.handleJoinGame());
        this.elements.leaveGameBtn.addEventListener('click', () => this.handleLeaveGame());
        this.elements.getGameStateBtn.addEventListener('click', () => this.handleGetGameState());
        this.elements.playCardBtn.addEventListener('click', () => this.handlePlayCard());
        
        // Log events
        this.elements.clearLogBtn.addEventListener('click', () => this.clearLog());
        this.elements.exportLogBtn.addEventListener('click', () => this.exportLog());
        
        // Error handling
        this.elements.closeErrorBtn.addEventListener('click', () => this.hideError());
        
        // PWA events
        this.elements.installBtn.addEventListener('click', () => this.handleInstall());
        this.elements.dismissBannerBtn.addEventListener('click', () => this.dismissInstallBanner());
        
        // Keyboard shortcuts
        document.addEventListener('keydown', (e) => this.handleKeydown(e));
    }
    
    /**
     * Initialize PWA features
     */
    initializePWA() {
        // Register service worker
        if ('serviceWorker' in navigator) {
            navigator.serviceWorker.register('./sw.js')
                .then(registration => {
                    this.log('Service Worker registered successfully');
                    
                    // Check for updates
                    registration.addEventListener('updatefound', () => {
                        this.log('Service Worker update found');
                    });
                })
                .catch(error => {
                    this.logError('Service Worker registration failed', error);
                });
        }
        
        // PWA install prompt
        window.addEventListener('beforeinstallprompt', (e) => {
            e.preventDefault();
            this.deferredPrompt = e;
            this.showInstallBanner();
        });
        
        // PWA installed
        window.addEventListener('appinstalled', () => {
            this.log('PWA installed successfully');
            this.hideInstallBanner();
        });
    }
    
    /**
     * Set WebSocket client
     */
    setWebSocketClient(client) {
        this.wsClient = client;
        
        // Set up event handlers
        client.onConnectionChange = (status) => this.updateConnectionStatus(status);
        client.onGameStateUpdate = (gameState) => this.updateGameState(gameState);
        client.onMoveResult = (result) => this.handleMoveResult(result);
        client.onError = (error) => this.showError(error.message || 'Unknown error');
        client.onMessage = (message) => this.logMessage('RECEIVED', message.type, message);
    }
    
    /**
     * Handle connect button
     */
    async handleConnect() {
        if (!this.wsClient) {
            this.showError('WebSocket client not initialized');
            return;
        }
        
        const url = this.elements.serverUrl.value.trim();
        if (!url) {
            this.showError('Please enter a server URL');
            return;
        }
        
        try {
            this.showLoading('Connecting...');
            await this.wsClient.connect(url);
        } catch (error) {
            this.showError(`Connection failed: ${error.message}`);
        } finally {
            this.hideLoading();
        }
    }
    
    /**
     * Handle disconnect button
     */
    handleDisconnect() {
        if (this.wsClient) {
            this.wsClient.disconnect();
        }
    }
    
    /**
     * Handle ping button
     */
    handlePing() {
        if (this.wsClient && this.wsClient.isConnected) {
            this.wsClient.ping();
            this.logMessage('SENT', 'ping', null);
        } else {
            this.showError('Not connected');
        }
    }
    
    /**
     * Handle join game button
     */
    handleJoinGame() {
        if (!this.wsClient || !this.wsClient.isConnected) {
            this.showError('Not connected');
            return;
        }
        
        const gameMode = this.elements.gameMode.value;
        this.wsClient.joinGame(gameMode);
        this.logMessage('SENT', 'join_game', { game_mode: gameMode });
    }
    
    /**
     * Handle leave game button
     */
    handleLeaveGame() {
        if (!this.wsClient || !this.wsClient.isConnected) {
            this.showError('Not connected');
            return;
        }
        
        if (!this.wsClient.gameId) {
            this.showError('Not in a game');
            return;
        }
        
        this.wsClient.leaveGame();
        this.logMessage('SENT', 'leave_game', null);
    }
    
    /**
     * Handle get game state button
     */
    handleGetGameState() {
        if (!this.wsClient || !this.wsClient.isConnected) {
            this.showError('Not connected');
            return;
        }
        
        if (!this.wsClient.gameId) {
            this.showError('Not in a game');
            return;
        }
        
        this.wsClient.getGameState();
        this.logMessage('SENT', 'get_game_state', null);
    }
    
    /**
     * Handle play card button
     */
    handlePlayCard() {
        if (!this.wsClient || !this.wsClient.isConnected) {
            this.showError('Not connected');
            return;
        }
        
        if (!this.wsClient.gameId) {
            this.showError('Not in a game');
            return;
        }
        
        const suit = this.elements.cardSuit.value;
        const value = this.elements.cardValue.value;
        
        this.wsClient.playCard(suit, value);
        this.logMessage('SENT', 'play_card', { suit, value: parseInt(value) });
    }
    
    /**
     * Handle keyboard shortcuts
     */
    handleKeydown(e) {
        // Ctrl/Cmd + Enter to connect/disconnect
        if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') {
            e.preventDefault();
            if (this.wsClient && this.wsClient.isConnected) {
                this.handleDisconnect();
            } else {
                this.handleConnect();
            }
        }
        
        // Space to ping
        if (e.key === ' ' && e.target.tagName !== 'INPUT' && e.target.tagName !== 'SELECT') {
            e.preventDefault();
            this.handlePing();
        }
        
        // J to join game
        if (e.key === 'j' && e.target.tagName !== 'INPUT') {
            e.preventDefault();
            this.handleJoinGame();
        }
        
        // L to leave game
        if (e.key === 'l' && e.target.tagName !== 'INPUT') {
            e.preventDefault();
            this.handleLeaveGame();
        }
        
        // G to get game state
        if (e.key === 'g' && e.target.tagName !== 'INPUT') {
            e.preventDefault();
            this.handleGetGameState();
        }
    }
    
    /**
     * Update connection status
     */
    updateConnectionStatus(status) {
        // Update connection indicator
        if (status.isConnected) {
            this.elements.statusIndicator.className = 'status-indicator connected';
            this.elements.statusText.textContent = 'Connected';
        } else {
            this.elements.statusIndicator.className = 'status-indicator disconnected';
            this.elements.statusText.textContent = 'Disconnected';
        }
        
        // Update connection info
        this.elements.playerId.textContent = status.playerId || '-';
        this.elements.sessionId.textContent = status.sessionId || '-';
        this.elements.serverTime.textContent = status.serverTime ? 
            status.serverTime.toLocaleTimeString() : '-';
        this.elements.heartbeatInterval.textContent = status.heartbeatInterval ? 
            `${status.heartbeatInterval}ms` : '-';
        
        // Update button states
        this.elements.connectBtn.disabled = status.isConnected;
        this.elements.disconnectBtn.disabled = !status.isConnected;
        this.elements.pingBtn.disabled = !status.isConnected;
        this.elements.joinGameBtn.disabled = !status.isConnected;
        this.elements.leaveGameBtn.disabled = !status.isConnected || !status.gameId;
        this.elements.getGameStateBtn.disabled = !status.isConnected || !status.gameId;
        this.elements.playCardBtn.disabled = !status.isConnected || !status.gameId;
        
        this.log(`Connection status updated: ${status.isConnected ? 'Connected' : 'Disconnected'}`);
    }
    
    /**
     * Update game state
     */
    updateGameState(gameState) {
        this.currentGameState = gameState;
        
        // Update game info
        this.elements.gameId.textContent = gameState.game_id || '-';
        this.elements.yourTurn.textContent = gameState.your_turn ? 'Yes' : 'No';
        this.elements.currentPlayer.textContent = gameState.current_player_id || '-';
        this.elements.gameStatus.textContent = gameState.status || '-';
        this.elements.trickNumber.textContent = gameState.trick_number || '-';
        this.elements.moveNumber.textContent = gameState.move_number || '-';
        
        // Update cards
        this.displayCards('tableCards', gameState.table_cards || []);
        this.displayCards('playerHand', gameState.your_cards || [], true);
        this.displayCards('validMoves', gameState.valid_moves || []);
        
        // Update scores
        this.displayScores(gameState.scores || {});
        
        // Update button states
        const hasGameId = !!gameState.game_id;
        this.elements.leaveGameBtn.disabled = !hasGameId;
        this.elements.getGameStateBtn.disabled = !hasGameId;
        this.elements.playCardBtn.disabled = !hasGameId || !gameState.your_turn;
        
        this.log('Game state updated', gameState);
    }
    
    /**
     * Display cards in a container
     */
    displayCards(containerId, cards, clickable = false) {
        const container = this.elements[containerId];
        if (!container) return;
        
        container.innerHTML = '';
        
        if (!cards || cards.length === 0) {
            const emptyMsg = document.createElement('div');
            emptyMsg.className = 'empty-message';
            emptyMsg.textContent = 'No cards';
            container.appendChild(emptyMsg);
            return;
        }
        
        cards.forEach(card => {
            const cardElement = this.createCardElement(card, clickable);
            container.appendChild(cardElement);
        });
    }
    
    /**
     * Create a card element
     */
    createCardElement(card, clickable = false) {
        const cardEl = document.createElement('div');
        cardEl.className = `card ${clickable ? 'clickable' : ''}`;
        cardEl.setAttribute('data-suit', card.suit);
        cardEl.setAttribute('data-value', card.value);
        cardEl.setAttribute('data-id', card.id || '');
        
        const suitSymbol = this.cardSuits[card.suit] || card.suit;
        const valueName = this.cardValueNames[card.value] || card.value;
        const suitColor = this.cardSuitColors[card.suit] || '#000';
        
        cardEl.innerHTML = `
            <div class="card-content">
                <div class="card-value">${valueName}</div>
                <div class="card-suit" style="color: ${suitColor}">${suitSymbol}</div>
            </div>
        `;
        
        if (clickable) {
            cardEl.addEventListener('click', () => {
                this.handleCardClick(card);
            });
        }
        
        return cardEl;
    }
    
    /**
     * Handle card click
     */
    handleCardClick(card) {
        if (!this.wsClient || !this.wsClient.isConnected || !this.wsClient.gameId) {
            this.showError('Cannot play card - not in a game');
            return;
        }
        
        if (!this.currentGameState || !this.currentGameState.your_turn) {
            this.showError('Not your turn');
            return;
        }
        
        // Check if card is valid
        const validMoves = this.currentGameState.valid_moves || [];
        const isValid = validMoves.some(validCard => 
            validCard.suit === card.suit && validCard.value === card.value
        );
        
        if (!isValid) {
            this.showError('Invalid move');
            return;
        }
        
        this.wsClient.playCard(card.suit, card.value, card.id);
        this.logMessage('SENT', 'play_card', card);
    }
    
    /**
     * Display scores
     */
    displayScores(scores) {
        const container = this.elements.scoresContainer;
        container.innerHTML = '';
        
        if (!scores || Object.keys(scores).length === 0) {
            const emptyMsg = document.createElement('div');
            emptyMsg.className = 'empty-message';
            emptyMsg.textContent = 'No scores available';
            container.appendChild(emptyMsg);
            return;
        }
        
        Object.entries(scores).forEach(([playerId, score]) => {
            const scoreEl = document.createElement('div');
            scoreEl.className = 'score-item';
            scoreEl.innerHTML = `
                <span class="player-id">${playerId.substring(0, 8)}...</span>
                <span class="score">${score}</span>
            `;
            container.appendChild(scoreEl);
        });
    }
    
    /**
     * Handle move result
     */
    handleMoveResult(result) {
        this.log('Move result received', result);
        
        if (!result.valid && result.error) {
            this.showError(`Invalid move: ${result.error}`);
        }
        
        if (result.trick_complete) {
            this.log('Trick completed');
        }
        
        if (result.game_complete) {
            this.log('Game completed');
            if (result.winner_id) {
                this.log(`Winner: ${result.winner_id}`);
            }
        }
    }
    
    /**
     * Show error message
     */
    showError(message) {
        this.elements.errorMessage.textContent = message;
        this.elements.errorOverlay.style.display = 'flex';
        this.logError('UI Error', message);
    }
    
    /**
     * Hide error message
     */
    hideError() {
        this.elements.errorOverlay.style.display = 'none';
    }
    
    /**
     * Show loading overlay
     */
    showLoading(message = 'Loading...') {
        const loadingText = this.elements.loadingOverlay.querySelector('p');
        if (loadingText) {
            loadingText.textContent = message;
        }
        this.elements.loadingOverlay.style.display = 'flex';
    }
    
    /**
     * Hide loading overlay
     */
    hideLoading() {
        this.elements.loadingOverlay.style.display = 'none';
    }
    
    /**
     * Show install banner
     */
    showInstallBanner() {
        this.elements.installBanner.style.display = 'block';
    }
    
    /**
     * Hide install banner
     */
    hideInstallBanner() {
        this.elements.installBanner.style.display = 'none';
    }
    
    /**
     * Dismiss install banner
     */
    dismissInstallBanner() {
        this.hideInstallBanner();
        localStorage.setItem('installBannerDismissed', 'true');
    }
    
    /**
     * Handle PWA install
     */
    async handleInstall() {
        if (!this.deferredPrompt) {
            this.showError('Install not available');
            return;
        }
        
        this.deferredPrompt.prompt();
        const result = await this.deferredPrompt.userChoice;
        
        if (result.outcome === 'accepted') {
            this.log('PWA install accepted');
        } else {
            this.log('PWA install declined');
        }
        
        this.deferredPrompt = null;
        this.hideInstallBanner();
    }
    
    /**
     * Log message to UI
     */
    logMessage(direction, type, data = null) {
        const timestamp = new Date().toLocaleTimeString();
        const entry = {
            timestamp,
            direction,
            type,
            data
        };
        
        this.messageLog.push(entry);
        
        // Limit log size
        if (this.messageLog.length > this.maxLogEntries) {
            this.messageLog.shift();
        }
        
        // Add to UI
        this.addLogEntryToUI(entry);
        
        console.log(`[${timestamp}] ${direction}: ${type}`, data);
    }
    
    /**
     * Add log entry to UI
     */
    addLogEntryToUI(entry) {
        const logEl = document.createElement('div');
        logEl.className = `log-entry ${entry.direction.toLowerCase()}`;
        
        const dataStr = entry.data ? JSON.stringify(entry.data, null, 2) : '';
        const shortData = dataStr.length > 100 ? dataStr.substring(0, 100) + '...' : dataStr;
        
        logEl.innerHTML = `
            <span class="timestamp">[${entry.timestamp}]</span>
            <span class="direction">${entry.direction}</span>
            <span class="type">${entry.type}</span>
            ${shortData ? `<span class="data">${shortData}</span>` : ''}
        `;
        
        // Add click to expand
        if (entry.data) {
            logEl.addEventListener('click', () => {
                this.showLogDetail(entry);
            });
            logEl.style.cursor = 'pointer';
        }
        
        this.elements.messageLog.appendChild(logEl);
        
        // Auto-scroll
        if (this.elements.autoScrollLog.checked) {
            this.elements.messageLog.scrollTop = this.elements.messageLog.scrollHeight;
        }
    }
    
    /**
     * Show log entry detail
     */
    showLogDetail(entry) {
        const detail = JSON.stringify(entry, null, 2);
        this.showError(`Log Entry Detail:\n\n${detail}`);
    }
    
    /**
     * Clear message log
     */
    clearLog() {
        this.messageLog = [];
        this.elements.messageLog.innerHTML = '';
        this.log('Message log cleared');
    }
    
    /**
     * Export message log
     */
    exportLog() {
        const logData = JSON.stringify(this.messageLog, null, 2);
        const blob = new Blob([logData], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        
        const a = document.createElement('a');
        a.href = url;
        a.download = `septica-test-log-${new Date().toISOString().split('T')[0]}.json`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        
        URL.revokeObjectURL(url);
        this.log('Log exported');
    }
    
    /**
     * Log general message
     */
    log(message, data = null) {
        this.logMessage('SYSTEM', message, data);
    }
    
    /**
     * Log error message
     */
    logError(message, error = null) {
        this.logMessage('ERROR', message, error);
    }
}

// Export for global use
window.GameUI = GameUI;