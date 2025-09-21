/**
 * Main Application Entry Point
 * Septica Game Tester PWA
 */

class SepticaApp {
    constructor() {
        this.wsClient = null;
        this.gameUI = null;
        this.devAuth = null;
        this.isInitialized = false;
        
        // Initialize when DOM is ready
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', () => this.initialize());
        } else {
            this.initialize();
        }
    }
    
    /**
     * Initialize the application
     */
    async initialize() {
        if (this.isInitialized) return;
        
        try {
            console.log('Initializing Septica Test App...');
            
            // Initialize development authentication
            this.devAuth = new DevAuthManager();
            window.devAuth = this.devAuth; // Make globally available
            
            // Initialize UI
            this.gameUI = new GameUI();
            window.gameUI = this.gameUI; // Make globally available
            
            // Initialize WebSocket client
            this.wsClient = new SepticaWebSocketClient();
            window.wsClient = this.wsClient; // Make globally available
            
            // Connect UI to WebSocket client
            this.gameUI.setWebSocketClient(this.wsClient);
            
            // Auto-connect in development mode
            if (this.devAuth.isDevelopment) {
                await this.handleDevelopmentAutoConnect();
            }
            
            // Initialize PWA features
            this.initializePWAFeatures();
            
            // Setup error handling
            this.setupErrorHandling();
            
            // Setup keyboard shortcuts help
            this.setupKeyboardShortcuts();
            
            // Check for saved server URL
            this.restoreUserSettings();
            
            // Show install banner if appropriate
            this.checkInstallPrompt();
            
            this.isInitialized = true;
            console.log('Septica Test App initialized successfully');
            
            // Log startup info
            this.logStartupInfo();
            
        } catch (error) {
            console.error('Failed to initialize application:', error);
            this.showCriticalError('Application failed to initialize', error);
        }
    }
    
    /**
     * Handle automatic connection in development mode
     */
    async handleDevelopmentAutoConnect() {
        console.log('🎮 Development mode detected - attempting auto-connect');
        
        // Update server URL with dev auth parameters
        const devUrl = this.devAuth.getWebSocketUrl();
        if (this.gameUI.elements.serverUrl) {
            this.gameUI.elements.serverUrl.value = devUrl;
        }
        
        // Update connection status UI
        this.devAuth.updateConnectionUI('connecting');
        
        try {
            // Auto-connect using dev auth
            const connected = await this.devAuth.autoConnect(this.wsClient);
            
            if (connected) {
                this.devAuth.updateConnectionUI('connected');
                this.gameUI.log(`🎮 Auto-connected as ${this.devAuth.getPlayerInfo().number === 1 ? 'Player 1' : 'Player 2'}`);
                
                // Update connection info display
                const playerInfo = this.devAuth.getPlayerInfo();
                if (this.gameUI.elements.playerId) {
                    this.gameUI.elements.playerId.textContent = playerInfo.id.substring(0, 16) + '...';
                }
            } else {
                this.devAuth.updateConnectionUI('disconnected');
                this.gameUI.log('❌ Development auto-connect failed');
            }
        } catch (error) {
            this.devAuth.updateConnectionUI('disconnected');
            this.gameUI.logError('Development auto-connect error', error);
        }
    }
    
    /**
     * Initialize PWA features
     */
    initializePWAFeatures() {
        // Check if running as PWA
        if (window.matchMedia('(display-mode: standalone)').matches) {
            console.log('Running as PWA');
            document.body.classList.add('pwa-mode');
        }
        
        // Handle PWA install prompt
        window.addEventListener('beforeinstallprompt', (e) => {
            e.preventDefault();
            this.gameUI.deferredPrompt = e;
            
            // Only show banner if not dismissed
            if (!localStorage.getItem('installBannerDismissed')) {
                this.gameUI.showInstallBanner();
            }
        });
        
        // Handle PWA installed
        window.addEventListener('appinstalled', () => {
            console.log('PWA installed');
            this.gameUI.hideInstallBanner();
            this.gameUI.log('PWA installed successfully');
        });
        
        // Handle service worker updates
        if ('serviceWorker' in navigator) {
            navigator.serviceWorker.addEventListener('message', (event) => {
                if (event.data && event.data.type === 'RECONNECT_WEBSOCKET') {
                    this.handleServiceWorkerReconnect();
                }
            });
        }
        
        // Handle online/offline status
        window.addEventListener('online', () => {
            this.gameUI.log('Connection restored');
            this.handleConnectivityChange(true);
        });
        
        window.addEventListener('offline', () => {
            this.gameUI.log('Connection lost');
            this.handleConnectivityChange(false);
        });
        
        // Handle visibility change (PWA lifecycle)
        document.addEventListener('visibilitychange', () => {
            if (document.hidden) {
                this.handleAppHidden();
            } else {
                this.handleAppVisible();
            }
        });
    }
    
    /**
     * Setup global error handling
     */
    setupErrorHandling() {
        // Unhandled JavaScript errors
        window.addEventListener('error', (event) => {
            console.error('Unhandled error:', event.error);
            this.gameUI.logError('Unhandled Error', {
                message: event.error?.message || 'Unknown error',
                filename: event.filename,
                lineno: event.lineno,
                colno: event.colno
            });
        });
        
        // Unhandled promise rejections
        window.addEventListener('unhandledrejection', (event) => {
            console.error('Unhandled promise rejection:', event.reason);
            this.gameUI.logError('Unhandled Promise Rejection', event.reason);
            event.preventDefault(); // Prevent console spam
        });
        
        // WebSocket specific error handling
        if (this.wsClient) {
            this.wsClient.onError = (error) => {
                this.handleWebSocketError(error);
            };
        }
    }
    
    /**
     * Setup keyboard shortcuts help
     */
    setupKeyboardShortcuts() {
        // Help modal toggle
        document.addEventListener('keydown', (e) => {
            // F1 or Ctrl+H for help
            if (e.key === 'F1' || (e.ctrlKey && e.key === 'h')) {
                e.preventDefault();
                this.showKeyboardShortcuts();
            }
            
            // Escape to close modals
            if (e.key === 'Escape') {
                this.gameUI.hideError();
                this.hideKeyboardShortcuts();
            }
        });
    }
    
    /**
     * Restore user settings from localStorage
     */
    restoreUserSettings() {
        // Restore server URL
        const savedUrl = localStorage.getItem('serverUrl');
        if (savedUrl && this.gameUI.elements.serverUrl) {
            this.gameUI.elements.serverUrl.value = savedUrl;
        }
        
        // Restore game mode preference
        const savedGameMode = localStorage.getItem('gameMode');
        if (savedGameMode && this.gameUI.elements.gameMode) {
            this.gameUI.elements.gameMode.value = savedGameMode;
        }
        
        // Restore auto-scroll preference
        const autoScroll = localStorage.getItem('autoScrollLog');
        if (autoScroll !== null && this.gameUI.elements.autoScrollLog) {
            this.gameUI.elements.autoScrollLog.checked = autoScroll === 'true';
        }
        
        // Save settings when changed
        if (this.gameUI.elements.serverUrl) {
            this.gameUI.elements.serverUrl.addEventListener('change', (e) => {
                localStorage.setItem('serverUrl', e.target.value);
            });
        }
        
        if (this.gameUI.elements.gameMode) {
            this.gameUI.elements.gameMode.addEventListener('change', (e) => {
                localStorage.setItem('gameMode', e.target.value);
            });
        }
        
        if (this.gameUI.elements.autoScrollLog) {
            this.gameUI.elements.autoScrollLog.addEventListener('change', (e) => {
                localStorage.setItem('autoScrollLog', e.target.checked);
            });
        }
    }
    
    /**
     * Check if install prompt should be shown
     */
    checkInstallPrompt() {
        // Don't show if already dismissed or running as PWA
        if (localStorage.getItem('installBannerDismissed') || 
            window.matchMedia('(display-mode: standalone)').matches) {
            return;
        }
        
        // Show after a delay if conditions are met
        setTimeout(() => {
            if (!this.gameUI.deferredPrompt) {
                // Create a custom install prompt for browsers that support PWA
                if ('serviceWorker' in navigator && 'BeforeInstallPromptEvent' in window) {
                    this.gameUI.showInstallBanner();
                }
            }
        }, 5000); // 5 second delay
    }
    
    /**
     * Handle service worker reconnect message
     */
    handleServiceWorkerReconnect() {
        if (this.wsClient && !this.wsClient.isConnected) {
            this.gameUI.log('Service Worker requested reconnection');
            const url = this.gameUI.elements.serverUrl.value;
            if (url) {
                this.wsClient.connect(url).catch(error => {
                    this.gameUI.logError('Auto-reconnect failed', error);
                });
            }
        }
    }
    
    /**
     * Handle connectivity change
     */
    handleConnectivityChange(isOnline) {
        if (isOnline) {
            // Try to reconnect if we were connected before
            if (this.wsClient && !this.wsClient.isConnected) {
                const url = this.gameUI.elements.serverUrl.value;
                if (url) {
                    setTimeout(() => {
                        this.wsClient.connect(url).catch(error => {
                            this.gameUI.logError('Reconnect on connectivity restore failed', error);
                        });
                    }, 1000);
                }
            }
        } else {
            // Handle offline mode
            if (this.wsClient && this.wsClient.isConnected) {
                this.gameUI.log('Forcing disconnect due to lost connectivity');
            }
        }
    }
    
    /**
     * Handle app becoming hidden (PWA lifecycle)
     */
    handleAppHidden() {
        this.gameUI.log('App hidden - reducing activity');
        
        // Reduce heartbeat frequency when hidden
        if (this.wsClient && this.wsClient.isConnected) {
            // Could implement reduced heartbeat here
        }
    }
    
    /**
     * Handle app becoming visible (PWA lifecycle)
     */
    handleAppVisible() {
        this.gameUI.log('App visible - resuming normal activity');
        
        // Resume normal heartbeat when visible
        if (this.wsClient && this.wsClient.isConnected) {
            // Could implement normal heartbeat here
            // Send a quick ping to check connection
            this.wsClient.ping();
        }
    }
    
    /**
     * Handle WebSocket errors
     */
    handleWebSocketError(error) {
        console.error('WebSocket error:', error);
        
        // Show user-friendly error message
        let message = 'WebSocket connection error';
        if (error.type === 'server_error') {
            message = `Server error: ${error.message}`;
        } else if (error.message) {
            message = error.message;
        }
        
        this.gameUI.showError(message);
    }
    
    /**
     * Show critical application error
     */
    showCriticalError(message, error) {
        const errorDetails = error ? 
            `\n\nError details:\n${error.message || error}` : '';
        
        if (this.gameUI) {
            this.gameUI.showError(message + errorDetails);
        } else {
            // Fallback if UI not available
            alert(message + errorDetails);
        }
    }
    
    /**
     * Log startup information
     */
    logStartupInfo() {
        const info = {
            userAgent: navigator.userAgent,
            language: navigator.language,
            platform: navigator.platform,
            cookieEnabled: navigator.cookieEnabled,
            onLine: navigator.onLine,
            serviceWorkerSupported: 'serviceWorker' in navigator,
            webSocketSupported: 'WebSocket' in window,
            isPWA: window.matchMedia('(display-mode: standalone)').matches,
            viewport: {
                width: window.innerWidth,
                height: window.innerHeight
            },
            timestamp: new Date().toISOString()
        };
        
        this.gameUI.log('Application started', info);
        console.log('Startup info:', info);
    }
    
    /**
     * Show keyboard shortcuts help
     */
    showKeyboardShortcuts() {
        const shortcuts = `
Keyboard Shortcuts:

Connection:
• Ctrl/Cmd + Enter: Connect/Disconnect
• Space: Send Ping

Game:
• J: Join Game
• L: Leave Game  
• G: Get Game State

General:
• F1 or Ctrl+H: Show this help
• Escape: Close modals

Note: Shortcuts work when not typing in input fields.
        `;
        
        this.gameUI.showError(shortcuts.trim());
    }
    
    /**
     * Hide keyboard shortcuts help
     */
    hideKeyboardShortcuts() {
        // Currently using the same modal as errors
        this.gameUI.hideError();
    }
    
    /**
     * Get application status for debugging
     */
    getAppStatus() {
        return {
            isInitialized: this.isInitialized,
            wsClient: this.wsClient ? this.wsClient.getStatus() : null,
            online: navigator.onLine,
            isPWA: window.matchMedia('(display-mode: standalone)').matches,
            serviceWorkerReady: navigator.serviceWorker?.ready !== undefined,
            timestamp: new Date().toISOString()
        };
    }
    
    /**
     * Export application logs for debugging
     */
    exportDebugInfo() {
        const debugInfo = {
            appStatus: this.getAppStatus(),
            logs: this.gameUI ? this.gameUI.messageLog : [],
            localStorage: { ...localStorage },
            userAgent: navigator.userAgent,
            timestamp: new Date().toISOString()
        };
        
        const blob = new Blob([JSON.stringify(debugInfo, null, 2)], { 
            type: 'application/json' 
        });
        const url = URL.createObjectURL(blob);
        
        const a = document.createElement('a');
        a.href = url;
        a.download = `septica-debug-${new Date().toISOString().split('T')[0]}.json`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        
        URL.revokeObjectURL(url);
        
        if (this.gameUI) {
            this.gameUI.log('Debug info exported');
        }
    }
}

// Initialize application
const app = new SepticaApp();

// Make app globally available for debugging
window.septicaApp = app;

// Export debug function to global scope
window.exportDebugInfo = () => app.exportDebugInfo();

// Add debug command to console
console.log(`
🎮 Septica Game Tester PWA
========================

Debug commands:
• window.septicaApp.getAppStatus() - Get app status
• window.exportDebugInfo() - Export debug information
• window.wsClient - WebSocket client instance
• window.gameUI - Game UI instance

Keyboard shortcuts:
• F1 or Ctrl+H - Show help
• Ctrl/Cmd+Enter - Connect/Disconnect
• Space - Ping (when not in input)
• J - Join game
• L - Leave game
• G - Get game state
`);