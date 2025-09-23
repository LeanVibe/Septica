/**
 * Romanian Septica Complete Integration
 * Connects all systems for seamless 3D card playing experience
 */

class RomanianSepticaIntegration {
    constructor() {
        this.initialized = false;
        this.premiumGame = null;
        this.gameUI = null;
        this.wsClient = null;
        this.rulesEngine = null;
        this.playableInterface = null;

        console.log('🎯 Romanian Septica Integration starting...');
        this.initialize();
    }

    /**
     * Initialize complete integration
     */
    async initialize() {
        try {
            // Wait for DOM to be ready
            if (document.readyState === 'loading') {
                await new Promise(resolve => {
                    document.addEventListener('DOMContentLoaded', resolve);
                });
            }

            // Initialize core systems
            await this.initializeCoreSystems();

            // Connect all systems
            this.connectSystems();

            // Setup global event handlers
            this.setupGlobalHandlers();

            // Initialize 3D premium game if container exists
            await this.initializePremiumGame();

            this.initialized = true;
            console.log('🎮 Romanian Septica Integration completed successfully');

        } catch (error) {
            console.error('❌ Romanian Septica Integration failed:', error);
            this.showFallbackMode();
        }
    }

    /**
     * Initialize core systems
     */
    async initializeCoreSystems() {
        // Initialize Romanian Rules Engine
        if (typeof RomanianSepticaRules !== 'undefined') {
            this.rulesEngine = new RomanianSepticaRules();
            console.log('✅ Romanian Rules Engine initialized');
        }

        // Connect to existing GameUI
        if (window.gameUI) {
            this.gameUI = window.gameUI;
            console.log('✅ GameUI connected');
        }

        // Connect to WebSocket client
        if (window.wsClient) {
            this.wsClient = window.wsClient;
            console.log('✅ WebSocket client connected');
        }
    }

    /**
     * Initialize premium 3D game
     */
    async initializePremiumGame() {
        const container = document.getElementById('threejsContainer') ||
                         document.getElementById('gameContainer') ||
                         document.getElementById('premium-game-container');

        if (!container) {
            console.log('⚠️ No 3D container found, using 2D mode only');
            return;
        }

        try {
            // Create premium game instance
            if (typeof PremiumSepticaGame !== 'undefined') {
                this.premiumGame = new PremiumSepticaGame(container.id);
                window.premiumGame = this.premiumGame;

                // Initialize playable interface
                if (typeof PlayableCardInterface !== 'undefined') {
                    this.playableInterface = new PlayableCardInterface(this.premiumGame);
                    this.premiumGame.playableInterface = this.playableInterface;
                }

                console.log('✅ Premium 3D Game initialized');
            }
        } catch (error) {
            console.error('❌ Premium game initialization failed:', error);
        }
    }

    /**
     * Connect all systems for seamless communication
     */
    connectSystems() {
        // Connect WebSocket to all systems
        if (this.wsClient) {
            this.setupWebSocketIntegration();
        }

        // Connect GameUI to premium systems
        if (this.gameUI && this.premiumGame) {
            this.setupGameUIIntegration();
        }

        // Connect rules engine to all systems
        if (this.rulesEngine) {
            this.setupRulesIntegration();
        }
    }

    /**
     * Setup WebSocket integration with all systems
     */
    setupWebSocketIntegration() {
        // Override game state handler to distribute to all systems
        const originalOnGameStateUpdate = this.wsClient.onGameStateUpdate;
        this.wsClient.onGameStateUpdate = (gameState) => {
            // Call original handler
            if (originalOnGameStateUpdate) {
                originalOnGameStateUpdate.call(this.wsClient, gameState);
            }

            // Distribute to premium game
            if (this.premiumGame) {
                this.premiumGame.handleGameStateUpdate(gameState);
            }

            // Update playable interface
            if (this.playableInterface) {
                this.playableInterface.onGameStateUpdate(gameState);
            }

            // Validate with rules engine
            if (this.rulesEngine) {
                this.validateGameState(gameState);
            }
        };

        // Override move result handler
        const originalOnMoveResult = this.wsClient.onMoveResult;
        this.wsClient.onMoveResult = (result) => {
            // Call original handler
            if (originalOnMoveResult) {
                originalOnMoveResult.call(this.wsClient, result);
            }

            // Handle in premium game
            if (this.premiumGame) {
                this.premiumGame.handleMoveResult(result);
            }

            // Process move result
            this.processMoveResult(result);
        };

        console.log('🔗 WebSocket integration completed');
    }

    /**
     * Setup GameUI integration with premium systems
     */
    setupGameUIIntegration() {
        // Connect premium game to GameUI
        this.gameUI.premiumGameIntegration = {
            game: this.premiumGame,
            connected: true
        };
        this.premiumGame.gameUI = this.gameUI;

        // Override card click handler to use 3D system
        if (this.gameUI.handleCardClick) {
            const originalHandleCardClick = this.gameUI.handleCardClick.bind(this.gameUI);
            this.gameUI.handleCardClick = (card) => {
                // Try 3D system first
                if (this.premiumGame && this.premiumGame.isInitialized) {
                    return; // 3D system handles it
                }

                // Fallback to 2D system
                return originalHandleCardClick(card);
            };
        }

        console.log('🔗 GameUI integration completed');
    }

    /**
     * Setup rules engine integration
     */
    setupRulesIntegration() {
        // Add rule validation to all card play attempts
        window.validateRomanianSepticaMove = (card, gameState) => {
            return this.rulesEngine.validateMove(
                card,
                gameState.table_cards || [],
                gameState.your_cards || [],
                gameState
            );
        };

        // Add helper functions
        window.getRomanianValidMoves = (gameState) => {
            return this.rulesEngine.getValidMoves(
                gameState.your_cards || [],
                gameState.table_cards || [],
                gameState
            );
        };

        console.log('🔗 Rules engine integration completed');
    }

    /**
     * Setup global event handlers
     */
    setupGlobalHandlers() {
        // Handle page visibility changes
        document.addEventListener('visibilitychange', () => {
            if (document.hidden) {
                this.handlePageHidden();
            } else {
                this.handlePageVisible();
            }
        });

        // Handle window resize
        window.addEventListener('resize', () => {
            this.handleResize();
        });

        // Handle fullscreen changes
        document.addEventListener('fullscreenchange', () => {
            this.handleFullscreenChange();
        });

        // Global error handler for Romanian Septica
        window.addEventListener('error', (event) => {
            if (event.error && event.error.message.includes('Septica')) {
                this.handleSepticaError(event.error);
            }
        });

        console.log('🔗 Global handlers setup completed');
    }

    /**
     * Validate game state with rules engine
     */
    validateGameState(gameState) {
        if (!this.rulesEngine) return;

        const validation = this.rulesEngine.validateGameState(gameState);
        if (!validation.valid) {
            console.warn('⚠️ Game state validation failed:', validation.errors);
        }

        // Update valid moves
        const validMoves = this.rulesEngine.getValidMoves(
            gameState.your_cards || [],
            gameState.table_cards || [],
            gameState
        );

        // Update all systems with valid moves
        if (this.premiumGame) {
            this.premiumGame.validMoves = validMoves;
            this.premiumGame.updateValidMoveIndicators();
        }

        if (this.playableInterface) {
            this.playableInterface.validMoves = validMoves;
            this.playableInterface.updateCardInteractivity();
        }
    }

    /**
     * Process move result from server
     */
    processMoveResult(result) {
        if (result.valid) {
            console.log('✅ Move accepted by Romanian Septica backend');

            if (result.trick_complete) {
                this.handleTrickComplete(result);
            }

            if (result.game_complete) {
                this.handleGameComplete(result);
            }
        } else {
            console.log('❌ Move rejected:', result.error);
            this.handleInvalidMove(result);
        }
    }

    /**
     * Handle trick completion
     */
    handleTrickComplete(result) {
        console.log('🎯 Trick completed with Romanian Septica rules');

        // Trigger animations
        if (this.premiumGame) {
            this.premiumGame.triggerTrickCompleteAnimation(result);
        }

        if (this.gameUI) {
            this.gameUI.showTrickComplete(result);
        }
    }

    /**
     * Handle game completion
     */
    handleGameComplete(result) {
        console.log('🏆 Romanian Septica game completed');

        const isWinner = result.winner_id === this.wsClient?.playerId;

        // Show completion in all systems
        if (this.premiumGame) {
            this.premiumGame.triggerGameCompleteAnimation(isWinner);
        }

        if (this.gameUI) {
            this.gameUI.showGameComplete(result.winner_id);
        }
    }

    /**
     * Handle invalid move
     */
    handleInvalidMove(result) {
        // Show error in all systems
        if (this.premiumGame) {
            this.premiumGame.showPlayCardError(result.error);
        }

        if (this.gameUI) {
            this.gameUI.showError(`Invalid move: ${result.error}`);
        }
    }

    /**
     * Handle page hidden
     */
    handlePageHidden() {
        // Reduce performance in 3D system
        if (this.premiumGame) {
            this.premiumGame.handleAppHidden();
        }
    }

    /**
     * Handle page visible
     */
    handlePageVisible() {
        // Resume performance in 3D system
        if (this.premiumGame) {
            this.premiumGame.handleAppVisible();
        }
    }

    /**
     * Handle window resize
     */
    handleResize() {
        if (this.premiumGame) {
            this.premiumGame.handleResize();
        }

        if (this.gameUI) {
            this.gameUI.handleResize?.();
        }
    }

    /**
     * Handle fullscreen changes
     */
    handleFullscreenChange() {
        const isFullscreen = !!document.fullscreenElement;
        console.log(`Fullscreen: ${isFullscreen ? 'enabled' : 'disabled'}`);

        if (this.premiumGame) {
            this.premiumGame.setFullscreen?.(isFullscreen);
        }
    }

    /**
     * Handle Romanian Septica specific errors
     */
    handleSepticaError(error) {
        console.error('🎯 Romanian Septica Error:', error);

        // Try to recover
        this.attemptRecovery();
    }

    /**
     * Attempt to recover from errors
     */
    attemptRecovery() {
        console.log('🔄 Attempting Romanian Septica recovery...');

        // Reconnect WebSocket if needed
        if (this.wsClient && !this.wsClient.isConnected) {
            this.wsClient.connect().catch(console.error);
        }

        // Re-initialize 3D system if needed
        if (this.premiumGame && !this.premiumGame.isInitialized) {
            this.initializePremiumGame().catch(console.error);
        }
    }

    /**
     * Show fallback mode if integration fails
     */
    showFallbackMode() {
        console.log('⚠️ Using Romanian Septica fallback mode');

        // Show message to user
        if (this.gameUI) {
            this.gameUI.showError('3D mode unavailable, using 2D fallback');
        }
    }

    /**
     * Get current system status
     */
    getStatus() {
        return {
            initialized: this.initialized,
            premiumGame: !!this.premiumGame?.isInitialized,
            gameUI: !!this.gameUI,
            wsClient: !!this.wsClient?.isConnected,
            rulesEngine: !!this.rulesEngine,
            playableInterface: !!this.playableInterface
        };
    }

    /**
     * Dispose of all systems
     */
    dispose() {
        if (this.premiumGame) {
            this.premiumGame.dispose();
        }

        if (this.playableInterface) {
            this.playableInterface.dispose();
        }

        console.log('🗑️ Romanian Septica Integration disposed');
    }
}

// Auto-initialize when loaded
let septicaIntegration = null;

if (typeof window !== 'undefined') {
    // Initialize after a short delay to ensure all dependencies are loaded
    setTimeout(() => {
        septicaIntegration = new RomanianSepticaIntegration();
        window.septicaIntegration = septicaIntegration;
    }, 100);
}

// Export for use in other modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = RomanianSepticaIntegration;
} else if (typeof window !== 'undefined') {
    window.RomanianSepticaIntegration = RomanianSepticaIntegration;
}