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
        
        // 3D Card Renderer
        this.cardRenderer3D = null;
        this.is3DEnabled = true;
        this.performanceStats = { fps: 0, triangles: 0 };
        
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
        
        // 3D Renderer Elements
        this.elements.threejsContainer = document.getElementById('threejsContainer');
        this.elements.tableStatus = document.getElementById('tableStatus');
        this.elements.cardCount = document.getElementById('cardCount');
        this.elements.toggleRendererBtn = document.getElementById('toggleRendererBtn');
        this.elements.resetCameraBtn = document.getElementById('resetCameraBtn');
        this.elements.rendererStatsBtn = document.getElementById('rendererStatsBtn');
        this.elements.fpsCounter = document.getElementById('fpsCounter');
        this.elements.renderStats = document.getElementById('renderStats');
        
        // Initialize 3D renderer if container exists
        if (this.elements.threejsContainer) {
            this.initialize3DRenderer();
        }
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
        
        // 3D Renderer events
        if (this.elements.toggleRendererBtn) {
            this.elements.toggleRendererBtn.addEventListener('click', () => this.toggle3DRenderer());
        }
        if (this.elements.resetCameraBtn) {
            this.elements.resetCameraBtn.addEventListener('click', () => this.resetCamera());
        }
        if (this.elements.rendererStatsBtn) {
            this.elements.rendererStatsBtn.addEventListener('click', () => this.showRendererStats());
        }
        
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
        
        // Get game ID from the UI or use the test game ID
        let gameId = this.elements.gameId.textContent;
        if (gameId === '-' || !gameId) {
            // Try to get game ID from global test variable
            gameId = window.testGameId;
        }
        
        if (!gameId || gameId === '-') {
            this.showError('No game ID available. Please create a game first.');
            return;
        }
        
        const gameMode = this.elements.gameMode.value;
        this.wsClient.joinGame(gameId, gameMode);
        this.logMessage('SENT', 'join_game', { game_id: gameId, game_mode: gameMode });
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
        
        // Update 3D renderer if enabled
        if (this.cardRenderer3D && this.is3DEnabled) {
            this.cardRenderer3D.updateGameState(gameState);
            this.update3DUI(gameState);
        }
        
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
    
    // ===== 3D RENDERER METHODS =====
    
    /**
     * Initialize 3D card renderer
     */
    initialize3DRenderer() {
        try {
            if (!window.Card3DRenderer) {
                console.warn('Card3DRenderer not available - 3D features disabled');
                this.is3DEnabled = false;
                return;
            }
            
            const canvasWrapper = this.elements.threejsContainer.querySelector('.threejs-canvas-wrapper');
            if (!canvasWrapper) {
                console.error('3D canvas wrapper not found');
                this.is3DEnabled = false;
                return;
            }
            
            const containerRect = this.elements.threejsContainer.getBoundingClientRect();
            this.cardRenderer3D = new Card3DRenderer(canvasWrapper, {
                width: containerRect.width || 800,
                height: containerRect.height || 500,
                enableShadows: true,
                enableAntialiasing: true
            });
            
            // Start performance monitoring
            this.startPerformanceMonitoring();
            
            this.log('3D card renderer initialized successfully');
            this.update3DStatus('3D Renderer Active');
            
        } catch (error) {
            console.error('Failed to initialize 3D renderer:', error);
            this.is3DEnabled = false;
            this.logError('3D renderer initialization failed', error);
            this.update3DStatus('3D Renderer Failed');
        }
    }
    
    /**
     * Update 3D UI elements
     */
    update3DUI(gameState) {
        if (!this.is3DEnabled) return;
        
        try {
            // Update table status
            let status = 'Ready to Play';
            if (gameState.status === 'playing') {
                status = `${gameState.your_turn ? 'Your Turn' : 'Opponent\'s Turn'}`;
            } else if (gameState.status === 'finished') {
                status = 'Game Finished';
            }
            this.update3DStatus(status);
            
            // Update card count
            const tableCardCount = (gameState.table_cards || []).length;
            this.updateCardCount(`${tableCardCount} cards on table`);
            
            // Update performance stats
            this.updatePerformanceStats();
            
        } catch (error) {
            console.error('Error updating 3D UI:', error);
            this.logError('3D UI update failed', error);
        }
    }
    
    /**
     * Update 3D status display
     */
    update3DStatus(status) {
        if (this.elements.tableStatus) {
            this.elements.tableStatus.textContent = status;
        }
    }
    
    /**
     * Update card count display
     */
    updateCardCount(count) {
        if (this.elements.cardCount) {
            this.elements.cardCount.textContent = count;
        }
    }
    
    /**
     * Toggle between 3D and 2D view
     */
    toggle3DRenderer() {
        if (!this.cardRenderer3D) {
            this.showError('3D renderer not available');
            return;
        }
        
        this.is3DEnabled = !this.is3DEnabled;
        
        if (this.is3DEnabled) {
            this.elements.threejsContainer.style.display = 'block';
            this.elements.toggleRendererBtn.textContent = 'Switch to 2D View';
            this.update3DStatus('3D View Active');
            this.log('Switched to 3D view');
            
            // Re-render current game state
            if (this.currentGameState) {
                this.cardRenderer3D.updateGameState(this.currentGameState);
            }
        } else {
            this.elements.threejsContainer.style.display = 'none';
            this.elements.toggleRendererBtn.textContent = 'Switch to 3D View';
            this.log('Switched to 2D view');
        }
    }
    
    /**
     * Reset camera to default position
     */
    resetCamera() {
        if (!this.cardRenderer3D || !this.is3DEnabled) {
            this.showError('3D renderer not available');
            return;
        }
        
        try {
            // Reset camera position
            this.cardRenderer3D.camera.position.set(0, 8, 12);
            this.cardRenderer3D.camera.lookAt(0, 0, 0);
            this.log('Camera position reset');
        } catch (error) {
            this.logError('Failed to reset camera', error);
        }
    }
    
    /**
     * Show renderer performance statistics
     */
    showRendererStats() {
        if (!this.cardRenderer3D) {
            this.showError('3D renderer not available');
            return;
        }
        
        try {
            const stats = this.cardRenderer3D.getStats();
            const perfInfo = `
3D Renderer Performance Statistics:

• Triangles: ${stats.triangles.toLocaleString()}
• Draw Calls: ${stats.calls.toLocaleString()}
• Points: ${stats.points.toLocaleString()}
• Lines: ${stats.lines.toLocaleString()}

• Current FPS: ${this.performanceStats.fps}
• Memory Usage: ${(performance.memory?.usedJSHeapSize / 1024 / 1024).toFixed(1) || 'N/A'} MB
• GPU Renderer: ${this.cardRenderer3D.renderer.info.render.triangles > 0 ? 'Active' : 'Idle'}

Performance Status: ${this.getPerformanceStatus()}
            `.trim();
            
            this.showError(perfInfo);
            this.log('Performance stats displayed');
        } catch (error) {
            this.logError('Failed to get renderer stats', error);
        }
    }
    
    /**
     * Start performance monitoring
     */
    startPerformanceMonitoring() {
        let lastTime = performance.now();
        let frames = 0;
        
        const measurePerformance = () => {
            frames++;
            const currentTime = performance.now();
            
            if (currentTime - lastTime >= 1000) {
                this.performanceStats.fps = Math.round((frames * 1000) / (currentTime - lastTime));
                
                if (this.cardRenderer3D) {
                    const stats = this.cardRenderer3D.getStats();
                    this.performanceStats.triangles = stats.triangles;
                }
                
                frames = 0;
                lastTime = currentTime;
            }
            
            if (this.is3DEnabled) {
                requestAnimationFrame(measurePerformance);
            }
        };
        
        requestAnimationFrame(measurePerformance);
    }
    
    /**
     * Update performance statistics display
     */
    updatePerformanceStats() {
        if (this.elements.fpsCounter) {
            const fpsClass = this.performanceStats.fps >= 45 ? 'performance-good' : 
                            this.performanceStats.fps >= 30 ? 'performance-warning' : 'performance-critical';
            this.elements.fpsCounter.textContent = `FPS: ${this.performanceStats.fps}`;
            this.elements.fpsCounter.className = `fps-counter ${fpsClass}`;
        }
        
        if (this.elements.renderStats) {
            this.elements.renderStats.textContent = `Triangles: ${this.performanceStats.triangles.toLocaleString()}`;
        }
    }
    
    /**
     * Get performance status
     */
    getPerformanceStatus() {
        const fps = this.performanceStats.fps;
        if (fps >= 45) return 'Excellent (60+ FPS target)';
        if (fps >= 30) return 'Good (30+ FPS stable)';
        if (fps >= 15) return 'Poor (consider 2D mode)';
        return 'Critical (switch to 2D mode)';
    }
    
    /**
     * Cleanup 3D renderer
     */
    destroy3DRenderer() {
        if (this.cardRenderer3D) {
            this.cardRenderer3D.destroy();
            this.cardRenderer3D = null;
            this.log('3D renderer destroyed');
        }
    }
}

// Export for global use
window.GameUI = GameUI;