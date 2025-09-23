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

        // Initialize Romanian Septica specific features
        this.initializeRomanianSepticaFeatures();

        // Initialize Romanian rules engine
        if (typeof RomanianSepticaRules !== 'undefined') {
            this.romanianRules = new RomanianSepticaRules();
            console.log('🎯 Romanian Septica Rules Engine integrated');
        }

        // Initialize premium game integration
        this.premiumGameIntegration = null;
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
        this.elements.createGameBtn = document.getElementById('createGameBtn');
        this.elements.joinGameBtn = document.getElementById('joinGameBtn');
        this.elements.leaveGameBtn = document.getElementById('leaveGameBtn');
        this.elements.getGameStateBtn = document.getElementById('getGameStateBtn');
        
        // Game creation and joining elements
        this.elements.gameCreationResult = document.getElementById('gameCreationResult');
        this.elements.createdGameId = document.getElementById('createdGameId');
        this.elements.copyGameIdBtn = document.getElementById('copyGameIdBtn');
        this.elements.playersInGame = document.getElementById('playersInGame');
        this.elements.joinGameId = document.getElementById('joinGameId');
        
        // Multiplayer display elements
        this.elements.turnIndicator = document.getElementById('turnIndicator');
        this.elements.turnText = document.getElementById('turnText');
        this.elements.playersDisplay = document.getElementById('playersDisplay');
        this.elements.gameStatusBanner = document.getElementById('gameStatusBanner');
        this.elements.gameStatusText = document.getElementById('gameStatusText');
        this.elements.player1Info = document.getElementById('player1Info');
        this.elements.player1Name = document.getElementById('player1Name');
        this.elements.player1Cards = document.getElementById('player1Cards');
        this.elements.player1Score = document.getElementById('player1Score');
        this.elements.player2Info = document.getElementById('player2Info');
        this.elements.player2Name = document.getElementById('player2Name');
        this.elements.player2Cards = document.getElementById('player2Cards');
        this.elements.player2Score = document.getElementById('player2Score');
        
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
        this.elements.createGameBtn.addEventListener('click', () => this.handleCreateGame());
        this.elements.joinGameBtn.addEventListener('click', () => this.handleJoinGame());
        this.elements.leaveGameBtn.addEventListener('click', () => this.handleLeaveGame());
        this.elements.getGameStateBtn.addEventListener('click', () => this.handleGetGameState());
        this.elements.playCardBtn.addEventListener('click', () => this.handlePlayCard());
        this.elements.copyGameIdBtn.addEventListener('click', () => this.handleCopyGameId());
        this.elements.joinGameId.addEventListener('input', () => this.handleJoinGameIdInput());
        
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
     * Handle create game button
     */
    async handleCreateGame() {
        if (!this.wsClient || !this.wsClient.isConnected) {
            this.showError('Not connected to server');
            return;
        }
        
        try {
            const gameMode = this.elements.gameMode.value;
            const playerId = this.wsClient.playerId;
            
            this.log(`Creating game with mode: ${gameMode}, player: ${playerId}`);
            
            // Call backend API to create game
            const response = await fetch('http://localhost:8080/api/v1/games', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    game_mode: gameMode,
                    player_id: playerId
                })
            });
            
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            
            const gameData = await response.json();
            
            if (gameData.error) {
                throw new Error(gameData.error);
            }
            
            // Show game creation result
            this.elements.createdGameId.value = gameData.game_id;
            this.elements.gameCreationResult.style.display = 'block';
            this.elements.playersInGame.textContent = 'Players: 1/2';
            
            // Update game info
            this.elements.gameId.textContent = gameData.game_id;
            
            // Store game ID globally for easy access
            window.currentGameId = gameData.game_id;
            
            this.log('Game created successfully', gameData);
            this.logMessage('CREATED', 'game_created', gameData);
            
        } catch (error) {
            this.logError('Failed to create game', error);
            this.showError(`Failed to create game: ${error.message}`);
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
        
        // Get game ID from input field or use created game ID
        let gameId = this.elements.joinGameId.value.trim();
        if (!gameId && this.elements.createdGameId.value) {
            gameId = this.elements.createdGameId.value;
        }
        if (!gameId) {
            gameId = this.elements.gameId.textContent;
        }
        if (gameId === '-' || !gameId) {
            gameId = window.testGameId || window.currentGameId;
        }
        
        if (!gameId || gameId === '-') {
            this.showError('Please enter a game ID or create a new game first.');
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
        this.elements.createGameBtn.disabled = !status.isConnected;
        this.elements.joinGameBtn.disabled = !status.isConnected || (this.elements.joinGameId.value.trim() === '' && !status.gameId);
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

        // Handle backend game state format
        const gameId = gameState.game_id || gameState.gameId;
        const yourTurn = gameState.your_turn !== undefined ? gameState.your_turn : gameState.yourTurn;
        const currentPlayerId = gameState.current_player_id || gameState.currentPlayerId;
        const status = gameState.status || gameState.gameStatus;
        const trickNumber = gameState.trick_number || gameState.trickNumber || 1;
        const moveNumber = gameState.move_number || gameState.moveNumber || 1;

        // Update game info
        if (this.elements.gameId) this.elements.gameId.textContent = gameId || '-';
        if (this.elements.yourTurn) this.elements.yourTurn.textContent = yourTurn ? 'Yes' : 'No';
        if (this.elements.currentPlayer) this.elements.currentPlayer.textContent = currentPlayerId || '-';
        if (this.elements.gameStatus) this.elements.gameStatus.textContent = status || '-';
        if (this.elements.trickNumber) this.elements.trickNumber.textContent = trickNumber;
        if (this.elements.moveNumber) this.elements.moveNumber.textContent = moveNumber;

        // Update multiplayer display
        this.updateMultiplayerDisplay(gameState);

        // Handle backend card arrays
        const tableCards = gameState.table_cards || gameState.tableCards || [];
        const playerCards = gameState.your_cards || gameState.playerCards || gameState.hand || [];
        const validMoves = gameState.valid_moves || gameState.validMoves || [];

        // Update cards
        this.displayCards('tableCards', tableCards);
        this.displayCards('playerHand', playerCards, true);
        this.displayCards('validMoves', validMoves);

        // Update 3D renderer if enabled
        if (this.cardRenderer3D && this.is3DEnabled) {
            this.cardRenderer3D.updateGameState(gameState);
            this.update3DUI(gameState);
        }

        // Update premium game integration with animations
        if (window.premiumGame && window.premiumGame.handleGameStateUpdate) {
            window.premiumGame.handleGameStateUpdate(gameState);
        }

        // Re-enable card interaction when it's our turn
        if (yourTurn) {
            this.enableCardInteraction();
        } else {
            this.disableCardInteraction();
        }

        // Handle real-time animations based on game state changes
        this.handleRealTimeAnimations(gameState);

        // Update scores with backend format
        const scores = gameState.scores || gameState.playerScores || {};
        this.displayScores(scores);

        // Update button states
        const hasGameId = !!(gameId);
        if (this.elements.leaveGameBtn) this.elements.leaveGameBtn.disabled = !hasGameId;
        if (this.elements.getGameStateBtn) this.elements.getGameStateBtn.disabled = !hasGameId;
        if (this.elements.playCardBtn) this.elements.playCardBtn.disabled = !hasGameId || !yourTurn;

        this.log('Game state updated', gameState);

        // Notify Romanian Septica rule engine if available
        if (window.RomanianSepticaEngine && window.RomanianSepticaEngine.updateGameState) {
            window.RomanianSepticaEngine.updateGameState(gameState);
        }

        // Update any global game instance if available (for index.html compatibility)
        if (window.gameInstance && window.gameInstance.handleGameStateUpdate) {
            window.gameInstance.handleGameStateUpdate(gameState);
        }
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
        
        // Add multiplayer class for enhanced styling
        let cardClasses = `card ${clickable ? 'clickable multiplayer' : ''}`;
        
        // Check if this card is a valid move in multiplayer
        if (clickable && this.currentGameState) {
            const validMoves = this.currentGameState.valid_moves || [];
            const isValidMove = validMoves.some(validCard => 
                validCard.suit === card.suit && validCard.value === card.value
            );
            
            if (isValidMove) {
                cardClasses += ' valid-move';
            } else if (this.currentGameState.your_turn) {
                cardClasses += ' invalid-move';
            }
        }
        
        cardEl.className = cardClasses;
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
            
            // Add hover effects for multiplayer
            cardEl.addEventListener('mouseenter', () => {
                if (!cardEl.classList.contains('invalid-move')) {
                    cardEl.classList.add('hover');
                }
            });
            
            cardEl.addEventListener('mouseleave', () => {
                cardEl.classList.remove('hover');
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

        const yourTurn = this.currentGameState ?
            (this.currentGameState.your_turn !== undefined ? this.currentGameState.your_turn : this.currentGameState.yourTurn) :
            false;

        if (!this.currentGameState || !yourTurn) {
            this.showError('Not your turn');
            return;
        }

        // Check if card is valid using Romanian Septica rules
        const validMoves = this.currentGameState.valid_moves || this.currentGameState.validMoves || [];
        const isValid = this.isValidRomanianSepticaMove(card, validMoves);

        if (!isValid) {
            this.showError('Invalid move according to Romanian Septica rules');
            return;
        }

        // Add visual feedback for card play
        this.animateCardPlay(card);

        // Send to backend
        this.wsClient.playCard(card.suit, card.value, card.id);
        this.logMessage('SENT', 'play_card', card);

        // Disable further card plays until response
        this.disableCardInteraction();

        this.log(`Playing Romanian Septica card: ${this.getCardDisplayName(card)}`);
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

        // Handle backend move result format
        const isValid = result.valid !== undefined ? result.valid : result.success;
        const error = result.error || result.message;
        const trickComplete = result.trick_complete || result.trickComplete;
        const gameComplete = result.game_complete || result.gameComplete;
        const winnerId = result.winner_id || result.winnerId;

        if (!isValid && error) {
            this.showError(`Invalid move: ${error}`);
            return;
        }

        // Show move feedback
        if (isValid) {
            this.showMoveSuccess();
        }

        if (trickComplete) {
            this.log('Trick completed');
            this.showTrickComplete(result);
        }

        if (gameComplete) {
            this.log('Game completed');
            if (winnerId) {
                this.log(`Winner: ${winnerId}`);
                this.showGameComplete(winnerId);
            }
        }

        // Update game state if included in move result
        if (result.new_game_state || result.gameState) {
            this.updateGameState(result.new_game_state || result.gameState);
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
    
    /**
     * Handle copy game ID button
     */
    async handleCopyGameId() {
        const gameId = this.elements.createdGameId.value;
        if (!gameId) {
            this.showError('No game ID to copy');
            return;
        }
        
        try {
            await navigator.clipboard.writeText(gameId);
            
            // Visual feedback
            const button = this.elements.copyGameIdBtn;
            const originalText = button.textContent;
            button.textContent = '✓ Copied!';
            button.classList.add('copied');
            
            setTimeout(() => {
                button.textContent = originalText;
                button.classList.remove('copied');
            }, 2000);
            
            this.log(`Game ID copied to clipboard: ${gameId}`);
        } catch (error) {
            // Fallback for browsers that don't support clipboard API
            this.elements.createdGameId.select();
            document.execCommand('copy');
            this.log('Game ID copied to clipboard (fallback)');
        }
    }
    
    /**
     * Handle join game ID input changes
     */
    handleJoinGameIdInput() {
        const gameId = this.elements.joinGameId.value.trim();
        const isValidGameId = gameId.length > 0;
        
        // Enable/disable join button based on input
        if (this.wsClient && this.wsClient.isConnected) {
            this.elements.joinGameBtn.disabled = !isValidGameId;
        }
    }
    
    /**
     * Update multiplayer display with game state
     */
    updateMultiplayerDisplay(gameState) {
        if (!gameState) return;
        
        const hasGameId = !!gameState.game_id;
        const hasPlayers = gameState.players && gameState.players.length > 0;
        
        // Show/hide multiplayer elements
        if (hasGameId) {
            this.elements.turnIndicator.style.display = 'block';
            this.elements.gameStatusBanner.style.display = 'block';
            
            if (hasPlayers && gameState.players.length >= 2) {
                this.elements.playersDisplay.style.display = 'block';
            }
        }
        
        // Update turn indicator
        this.updateTurnIndicator(gameState);
        
        // Update game status banner
        this.updateGameStatusBanner(gameState);
        
        // Update players display
        if (hasPlayers) {
            this.updatePlayersDisplay(gameState);
        }
    }
    
    /**
     * Update turn indicator
     */
    updateTurnIndicator(gameState) {
        const turnIndicator = this.elements.turnIndicator;
        const turnText = this.elements.turnText;
        
        // Remove all turn classes
        turnIndicator.classList.remove('your-turn', 'opponent-turn', 'waiting');
        
        if (gameState.status === 'waiting_for_players') {
            turnIndicator.classList.add('waiting');
            turnText.innerHTML = '<span class="turn-icon">⏳</span> Waiting for players...';
        } else if (gameState.status === 'playing') {
            if (gameState.your_turn) {
                turnIndicator.classList.add('your-turn');
                turnText.innerHTML = '<span class="turn-icon">🎯</span> Your turn - Play a card!';
            } else {
                turnIndicator.classList.add('opponent-turn');
                turnText.innerHTML = '<span class="turn-icon">⏱️</span> Opponent\'s turn';
            }
        } else if (gameState.status === 'finished') {
            turnIndicator.classList.add('waiting');
            if (gameState.winner_id) {
                const isWinner = gameState.winner_id === this.wsClient.playerId;
                turnText.innerHTML = `<span class="turn-icon">${isWinner ? '🏆' : '😔'}</span> Game finished - ${isWinner ? 'You won!' : 'You lost'}`;
            } else {
                turnText.innerHTML = '<span class="turn-icon">🏁</span> Game finished';
            }
        }
    }
    
    /**
     * Update game status banner
     */
    updateGameStatusBanner(gameState) {
        const banner = this.elements.gameStatusBanner;
        const statusText = this.elements.gameStatusText;
        
        // Remove all status classes
        banner.classList.remove('waiting-for-players', 'game-active', 'game-finished');
        
        if (gameState.status === 'waiting_for_players') {
            banner.classList.add('waiting-for-players');
            const playerCount = gameState.players ? gameState.players.length : 1;
            statusText.textContent = `Waiting for players (${playerCount}/2)`;
        } else if (gameState.status === 'playing') {
            banner.classList.add('game-active');
            statusText.textContent = `Game in progress - Round ${gameState.trick_number || 1}`;
        } else if (gameState.status === 'finished') {
            banner.classList.add('game-finished');
            if (gameState.winner_id) {
                const isWinner = gameState.winner_id === this.wsClient.playerId;
                statusText.textContent = isWinner ? '🏆 You won the game!' : '😔 You lost the game';
            } else {
                statusText.textContent = 'Game finished';
            }
        }
    }
    
    /**
     * Update players display
     */
    updatePlayersDisplay(gameState) {
        if (!gameState.players || gameState.players.length === 0) return;
        
        const currentPlayerId = this.wsClient.playerId;
        let player1 = null;
        let player2 = null;
        
        // Organize players - current player first
        gameState.players.forEach(player => {
            if (player.id === currentPlayerId) {
                player1 = player;
            } else {
                player2 = player;
            }
        });
        
        // If no current player found, use order from array
        if (!player1 && gameState.players.length > 0) {
            player1 = gameState.players[0];
            player2 = gameState.players[1] || null;
        }
        
        // Update player 1 (current player)
        if (player1) {
            this.elements.player1Name.textContent = player1.id === currentPlayerId ? 'You' : `Player 1`;
            this.elements.player1Cards.textContent = `${player1.hand_size || 0} cards`;
            this.elements.player1Score.textContent = `${player1.score || 0} points`;
            
            // Highlight current player
            if (gameState.current_player_id === player1.id) {
                this.elements.player1Info.classList.add('current-player');
            } else {
                this.elements.player1Info.classList.remove('current-player');
            }
        }
        
        // Update player 2 (opponent)
        if (player2) {
            this.elements.player2Name.textContent = player2.id === currentPlayerId ? 'You' : 'Opponent';
            this.elements.player2Cards.textContent = `${player2.hand_size || 0} cards`;
            this.elements.player2Score.textContent = `${player2.score || 0} points`;
            
            // Highlight current player
            if (gameState.current_player_id === player2.id) {
                this.elements.player2Info.classList.add('current-player');
            } else {
                this.elements.player2Info.classList.remove('current-player');
            }
        } else {
            // No second player yet
            this.elements.player2Name.textContent = 'Waiting...';
            this.elements.player2Cards.textContent = '- cards';
            this.elements.player2Score.textContent = '- points';
            this.elements.player2Info.classList.remove('current-player');
        }
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

    // ===== ROMANIAN SEPTICA SPECIFIC METHODS =====

    /**
     * Initialize Romanian Septica specific features
     */
    initializeRomanianSepticaFeatures() {
        // Romanian Septica card values (7s are highest, then A, 10, K, Q, J, 9, 8)
        this.romanianCardHierarchy = {
            7: 15,   // 7s beat everything (including other 7s by suit priority)
            14: 14,  // Ace
            10: 13,  // 10
            13: 12,  // King
            12: 11,  // Queen
            11: 10,  // Jack
            9: 9,    // 9
            8: 8     // 8 (weakest, conditional beating)
        };

        // Suit priority for 7s: spades > hearts > diamonds > clubs
        this.suitPriority = {
            'spades': 4,
            'hearts': 3,
            'diamonds': 2,
            'clubs': 1
        };

        // Point values (only 10s and Aces count for points)
        this.pointValues = {
            10: 1,   // 10 = 1 point
            14: 1    // Ace = 1 point
        };

        this.log('Romanian Septica rules initialized');
    }

    /**
     * Check if a card is a valid Romanian Septica move
     */
    isValidRomanianSepticaMove(card, validMoves) {
        // First check if it's in the valid moves from backend
        const isInValidMoves = validMoves.some(validCard =>
            validCard.suit === card.suit && validCard.value === card.value
        );

        if (!isInValidMoves) {
            return false;
        }

        // Additional Romanian Septica rule validation could go here
        return true;
    }

    /**
     * Get display name for a card with Romanian context
     */
    getCardDisplayName(card) {
        const valueName = this.cardValueNames[card.value] || card.value;
        const suitName = card.suit.charAt(0).toUpperCase() + card.suit.slice(1);

        // Add Romanian context for special cards
        if (card.value === 7) {
            return `${valueName} of ${suitName} (Septica - strongest!)`;
        } else if (card.value === 14 || card.value === 10) {
            return `${valueName} of ${suitName} (Point card)`;
        }

        return `${valueName} of ${suitName}`;
    }

    /**
     * Animate card play with Romanian style
     */
    animateCardPlay(card) {
        // Add visual feedback for card selection
        const cardElements = document.querySelectorAll(`[data-suit="${card.suit}"][data-value="${card.value}"]`);
        cardElements.forEach(cardEl => {
            cardEl.classList.add('playing');
            cardEl.style.transform = 'scale(1.1) translateY(-10px)';
            cardEl.style.transition = 'all 0.3s ease';

            setTimeout(() => {
                cardEl.style.transform = '';
                cardEl.classList.remove('playing');
            }, 600);
        });
    }

    /**
     * Disable card interaction during move processing
     */
    disableCardInteraction() {
        const playerCards = document.querySelectorAll('#playerHand .card.clickable');
        playerCards.forEach(card => {
            card.style.pointerEvents = 'none';
            card.style.opacity = '0.7';
        });

        // Re-enable after 2 seconds (timeout)
        setTimeout(() => {
            this.enableCardInteraction();
        }, 2000);
    }

    /**
     * Enable card interaction
     */
    enableCardInteraction() {
        const playerCards = document.querySelectorAll('#playerHand .card');
        playerCards.forEach(card => {
            card.style.pointerEvents = '';
            card.style.opacity = '';
        });
    }

    /**
     * Show move success feedback
     */
    showMoveSuccess() {
        // Create success notification
        const notification = document.createElement('div');
        notification.className = 'move-success-notification';
        notification.innerHTML = '✅ Card played successfully!';
        notification.style.cssText = `
            position: fixed;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            background: rgba(16, 185, 129, 0.9);
            color: white;
            padding: 10px 20px;
            border-radius: 8px;
            z-index: 1000;
            font-weight: bold;
        `;

        document.body.appendChild(notification);

        setTimeout(() => {
            notification.remove();
        }, 2000);
    }

    /**
     * Show trick complete notification
     */
    showTrickComplete(result) {
        const trickWinner = result.trick_winner || result.trickWinner;
        const pointsWon = result.points_won || result.pointsWon || 0;

        const notification = document.createElement('div');
        notification.className = 'trick-complete-notification';
        notification.innerHTML = `
            <div style="font-size: 18px; margin-bottom: 5px;">🎯 Trick Complete!</div>
            <div>Winner: ${trickWinner === this.wsClient.playerId ? 'You' : 'Opponent'}</div>
            <div>Points: ${pointsWon}</div>
        `;
        notification.style.cssText = `
            position: fixed;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            background: rgba(59, 130, 246, 0.9);
            color: white;
            padding: 15px 25px;
            border-radius: 12px;
            z-index: 1000;
            text-align: center;
            font-weight: bold;
        `;

        document.body.appendChild(notification);

        setTimeout(() => {
            notification.remove();
        }, 3000);
    }

    /**
     * Show game complete notification
     */
    showGameComplete(winnerId) {
        const isWinner = winnerId === this.wsClient.playerId;

        const notification = document.createElement('div');
        notification.className = 'game-complete-notification';
        notification.innerHTML = `
            <div style="font-size: 24px; margin-bottom: 10px;">${isWinner ? '🏆' : '😔'}</div>
            <div style="font-size: 20px; margin-bottom: 5px;">
                ${isWinner ? 'Felicitări! You won!' : 'Game Over - You lost'}
            </div>
            <div style="font-size: 14px;">
                Romanian Septica match completed
            </div>
        `;
        notification.style.cssText = `
            position: fixed;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            background: ${isWinner ? 'rgba(16, 185, 129, 0.95)' : 'rgba(239, 68, 68, 0.95)'};
            color: white;
            padding: 20px 30px;
            border-radius: 15px;
            z-index: 1000;
            text-align: center;
            font-weight: bold;
            box-shadow: 0 10px 25px rgba(0,0,0,0.3);
        `;

        document.body.appendChild(notification);

        setTimeout(() => {
            notification.remove();
        }, 5000);
    }

    /**
     * Handle real-time animations based on game state changes
     */
    handleRealTimeAnimations(gameState) {
        if (!this.currentGameState) {
            this.currentGameState = gameState;
            return;
        }

        const previousState = this.currentGameState;

        // Detect card movements
        this.animateCardMovements(previousState, gameState);

        // Detect turn changes
        this.animateTurnChanges(previousState, gameState);

        // Detect trick completions
        this.animateTrickCompletions(previousState, gameState);

        // Update stored state
        this.currentGameState = gameState;
    }

    /**
     * Animate card movements when cards are played
     */
    animateCardMovements(previousState, currentState) {
        const prevTableCards = previousState.table_cards || [];
        const currTableCards = currentState.table_cards || [];

        // Check if new cards were added to the table
        if (currTableCards.length > prevTableCards.length) {
            const newCards = currTableCards.slice(prevTableCards.length);

            newCards.forEach(card => {
                this.animateNewCardOnTable(card);
            });
        }

        // Check if table was cleared (trick completed)
        if (currTableCards.length < prevTableCards.length) {
            this.animateTableClear();
        }
    }

    /**
     * Animate turn changes with visual feedback
     */
    animateTurnChanges(previousState, currentState) {
        const prevTurn = previousState.your_turn;
        const currTurn = currentState.your_turn;

        if (prevTurn !== currTurn) {
            if (currTurn) {
                this.animateYourTurnStart();
            } else {
                this.animateOpponentTurnStart();
            }
        }
    }

    /**
     * Animate trick completions
     */
    animateTrickCompletions(previousState, currentState) {
        const prevTrickNumber = previousState.trick_number || 1;
        const currTrickNumber = currentState.trick_number || 1;

        if (currTrickNumber > prevTrickNumber) {
            this.animateTrickComplete(currentState);
        }
    }

    /**
     * Animate new card appearing on table
     */
    animateNewCardOnTable(card) {
        // Create temporary visual for the animation
        const tableCardsContainer = this.elements.tableCards;
        if (!tableCardsContainer) return;

        const cardElement = this.createCardElement(card, false);
        cardElement.style.opacity = '0';
        cardElement.style.transform = 'scale(0.5) translateY(-50px)';
        cardElement.style.transition = 'all 0.5s ease-out';

        tableCardsContainer.appendChild(cardElement);

        // Trigger animation
        setTimeout(() => {
            cardElement.style.opacity = '1';
            cardElement.style.transform = 'scale(1) translateY(0)';
        }, 50);

        // Add card type specific effects
        if (card.value === 7) {
            this.addSepticaEffect(cardElement);
        } else if (card.value === 14 || card.value === 10) {
            this.addPointCardEffect(cardElement);
        }

        console.log(`🎴 Card animated onto table: ${this.getCardDisplayName(card)}`);
    }

    /**
     * Animate table clearing after trick completion
     */
    animateTableClear() {
        const tableCardsContainer = this.elements.tableCards;
        if (!tableCardsContainer) return;

        const cards = tableCardsContainer.querySelectorAll('.card');

        cards.forEach((card, index) => {
            setTimeout(() => {
                card.style.transition = 'all 0.6s ease-in';
                card.style.opacity = '0';
                card.style.transform = 'scale(0.8) rotate(10deg)';

                setTimeout(() => {
                    if (card.parentNode) {
                        card.parentNode.removeChild(card);
                    }
                }, 600);
            }, index * 100);
        });

        console.log('🧹 Table cleared with animation');
    }

    /**
     * Animate start of your turn
     */
    animateYourTurnStart() {
        const turnIndicator = this.elements.turnIndicator;
        if (!turnIndicator) return;

        // Flash effect
        turnIndicator.style.animation = 'none';
        setTimeout(() => {
            turnIndicator.style.animation = 'pulse 1s ease-in-out';
        }, 10);

        // Show your turn message
        this.showTemporaryMessage('Rândul tău! Your turn!', 'success');

        // Highlight player hand if available
        this.highlightPlayerHand(true);

        console.log('👤 Your turn animation triggered');
    }

    /**
     * Animate start of opponent turn
     */
    animateOpponentTurnStart() {
        const turnIndicator = this.elements.turnIndicator;
        if (!turnIndicator) return;

        // Different animation for opponent turn
        turnIndicator.style.animation = 'none';
        setTimeout(() => {
            turnIndicator.style.animation = 'fadeInOut 1.5s ease-in-out';
        }, 10);

        // Remove player hand highlight
        this.highlightPlayerHand(false);

        console.log('🤖 Opponent turn animation triggered');
    }

    /**
     * Animate trick completion
     */
    animateTrickComplete(gameState) {
        // Create trick completion celebration
        const celebration = document.createElement('div');
        celebration.className = 'trick-completion-celebration';
        celebration.innerHTML = `
            <div class="celebration-content">
                <h3>🎯 Runda Completă!</h3>
                <p>Trick ${gameState.trick_number} finished</p>
            </div>
        `;

        celebration.style.cssText = `
            position: fixed;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            background: rgba(59, 130, 246, 0.95);
            color: white;
            padding: 20px 30px;
            border-radius: 15px;
            z-index: 1000;
            text-align: center;
            font-weight: bold;
            animation: celebrationPop 2s ease-in-out;
        `;

        document.body.appendChild(celebration);

        setTimeout(() => {
            celebration.remove();
        }, 2000);

        console.log(`🎯 Trick ${gameState.trick_number} completion animated`);
    }

    /**
     * Add Septica (seven) special effect
     */
    addSepticaEffect(cardElement) {
        cardElement.classList.add('septica-effect');

        // Add golden glow
        cardElement.style.boxShadow = '0 0 20px #ffd700, 0 0 40px #ffd700';
        cardElement.style.border = '2px solid #ffd700';

        // Remove effect after animation
        setTimeout(() => {
            cardElement.style.boxShadow = '';
            cardElement.style.border = '';
            cardElement.classList.remove('septica-effect');
        }, 2000);

        console.log('✨ Septica effect added');
    }

    /**
     * Add point card effect
     */
    addPointCardEffect(cardElement) {
        cardElement.classList.add('point-card-effect');

        // Add blue glow for point cards
        cardElement.style.boxShadow = '0 0 15px #3b82f6';

        setTimeout(() => {
            cardElement.style.boxShadow = '';
            cardElement.classList.remove('point-card-effect');
        }, 1500);

        console.log('💎 Point card effect added');
    }

    /**
     * Highlight player hand for interaction
     */
    highlightPlayerHand(enable) {
        const playerHandContainer = this.elements.playerHand;
        if (!playerHandContainer) return;

        if (enable) {
            playerHandContainer.classList.add('interactive-highlight');
        } else {
            playerHandContainer.classList.remove('interactive-highlight');
        }
    }

    /**
     * Show temporary message
     */
    showTemporaryMessage(message, type = 'info') {
        const notification = document.createElement('div');
        notification.className = `temporary-message ${type}`;
        notification.textContent = message;

        const colors = {
            success: '#10b981',
            error: '#ef4444',
            info: '#3b82f6',
            warning: '#f59e0b'
        };

        notification.style.cssText = `
            position: fixed;
            top: 25%;
            left: 50%;
            transform: translateX(-50%);
            background: ${colors[type] || colors.info};
            color: white;
            padding: 12px 24px;
            border-radius: 8px;
            font-weight: bold;
            z-index: 1000;
            animation: messageSlideIn 0.5s ease-out;
        `;

        document.body.appendChild(notification);

        setTimeout(() => {
            notification.style.animation = 'messageSlideOut 0.5s ease-in';
            setTimeout(() => notification.remove(), 500);
        }, 2000);
    }

    /**
     * Initialize premium game integration
     */
    initializePremiumGameIntegration() {
        // Connect to premium game if available
        if (window.PremiumSepticaGame && window.premiumGame) {
            this.premiumGameIntegration = {
                game: window.premiumGame,
                connected: true
            };

            // Set up bidirectional communication
            window.premiumGame.gameUI = this;

            console.log('🎮 Premium game integration established');
        }
    }

    /**
     * Add CSS animations if not already present
     */
    addAnimationStyles() {
        if (document.querySelector('#gameAnimationStyles')) return;

        const style = document.createElement('style');
        style.id = 'gameAnimationStyles';
        style.textContent = `
            @keyframes pulse {
                0% { transform: scale(1); }
                50% { transform: scale(1.05); }
                100% { transform: scale(1); }
            }

            @keyframes fadeInOut {
                0% { opacity: 0.5; }
                50% { opacity: 1; }
                100% { opacity: 0.5; }
            }

            @keyframes celebrationPop {
                0% { transform: translate(-50%, -50%) scale(0.5); opacity: 0; }
                20% { transform: translate(-50%, -50%) scale(1.1); opacity: 1; }
                80% { transform: translate(-50%, -50%) scale(1); opacity: 1; }
                100% { transform: translate(-50%, -50%) scale(0.9); opacity: 0; }
            }

            @keyframes messageSlideIn {
                0% { transform: translateX(-50%) translateY(-20px); opacity: 0; }
                100% { transform: translateX(-50%) translateY(0); opacity: 1; }
            }

            @keyframes messageSlideOut {
                0% { transform: translateX(-50%) translateY(0); opacity: 1; }
                100% { transform: translateX(-50%) translateY(-20px); opacity: 0; }
            }

            .interactive-highlight {
                box-shadow: 0 0 10px rgba(59, 130, 246, 0.5);
                border-radius: 8px;
                transition: box-shadow 0.3s ease;
            }

            .septica-effect {
                animation: pulse 0.8s ease-in-out infinite;
            }

            .point-card-effect {
                animation: pulse 0.6s ease-in-out 2;
            }
        `;

        document.head.appendChild(style);
    }
}

// Initialize animation styles when GameUI is loaded
if (typeof document !== 'undefined') {
    document.addEventListener('DOMContentLoaded', () => {
        if (window.GameUI && window.gameUI) {
            window.gameUI.addAnimationStyles();
        }
    });
}

// Export for global use
window.GameUI = GameUI;