/**
 * Development Authentication System for Romanian Septica PWA
 * Automatic silent sign-in for easy multiplayer testing
 */

class DevAuthManager {
    constructor() {
        this.isDevelopment = this.checkDevelopmentMode();
        this.playerId = null;
        this.playerNumber = null;
        this.playerTheme = null;
        
        if (this.isDevelopment) {
            this.initializeDevAuth();
        }
    }

    /**
     * Check if we're running in development mode
     */
    checkDevelopmentMode() {
        const hostname = window.location.hostname;
        const port = window.location.port;
        const isDev = hostname === 'localhost' || 
                     hostname === '127.0.0.1' || 
                     hostname.includes('dev') ||
                     port === '8001';
        
        console.log(`🔧 DEBUG: Development mode check - hostname: "${hostname}", port: "${port}"`);
        console.log(`🔧 DEBUG: Development mode: ${isDev ? 'ENABLED' : 'DISABLED'}`);
        return isDev;
    }

    /**
     * Initialize development authentication
     */
    initializeDevAuth() {
        // Get or create player ID for this tab
        this.playerId = this.getOrCreatePlayerId();
        this.playerNumber = this.determinePlayerNumber();
        this.playerTheme = this.playerNumber === 1 ? 'red' : 'blue';
        
        // Apply visual theme
        this.applyPlayerTheme();
        
        // Show dev info
        this.showDevInfo();
        
        console.log(`🎮 Dev Auth initialized: Player ${this.playerNumber} (${this.playerId})`);
    }

    /**
     * Get or create a unique player ID for this browser tab
     */
    getOrCreatePlayerId() {
        let playerId = sessionStorage.getItem('septica_dev_player_id');
        
        if (!playerId) {
            // Generate a memorable player ID
            const timestamp = Date.now();
            const randomSuffix = Math.random().toString(36).substr(2, 4);
            playerId = `player_${timestamp}_${randomSuffix}`;
            sessionStorage.setItem('septica_dev_player_id', playerId);
        }
        
        return playerId;
    }

    /**
     * Determine if this is Player 1 or Player 2 based on existing connections
     */
    determinePlayerNumber() {
        // Check if we've already determined this
        let playerNumber = sessionStorage.getItem('septica_dev_player_number');
        
        if (!playerNumber) {
            // Simple strategy: odd/even based on timestamp + tab opener
            const isFirstTab = !window.opener && !sessionStorage.getItem('septica_tab_opened');
            playerNumber = isFirstTab ? '1' : '2';
            
            sessionStorage.setItem('septica_dev_player_number', playerNumber);
            sessionStorage.setItem('septica_tab_opened', 'true');
        }
        
        return parseInt(playerNumber);
    }

    /**
     * Apply visual theme based on player number
     */
    applyPlayerTheme() {
        const root = document.documentElement;
        
        if (this.playerNumber === 1) {
            // Player 1: Romanian Red/Gold theme
            root.style.setProperty('--player-primary', '#CE1126');
            root.style.setProperty('--player-secondary', '#FCD116');
            root.style.setProperty('--player-accent', '#8B0000');
            root.classList.add('player-1-theme');
        } else {
            // Player 2: Romanian Blue/Silver theme  
            root.style.setProperty('--player-primary', '#002B7F');
            root.style.setProperty('--player-secondary', '#C0C0C0');
            root.style.setProperty('--player-accent', '#001B5F');
            root.classList.add('player-2-theme');
        }
        
        // Add dev mode class
        root.classList.add('dev-mode');
    }

    /**
     * Show development information in the UI
     */
    showDevInfo() {
        const devInfo = document.createElement('div');
        devInfo.id = 'dev-info';
        devInfo.className = 'dev-info';
        devInfo.innerHTML = `
            <div class="dev-badge">
                <span class="dev-label">DEV</span>
                <span class="player-info">Player ${this.playerNumber}</span>
                <span class="player-id">${this.playerId.substring(0, 12)}...</span>
            </div>
        `;
        
        document.body.appendChild(devInfo);
    }

    /**
     * Get WebSocket URL with player ID
     */
    getWebSocketUrl(baseUrl = 'ws://localhost:8080/ws/connect') {
        if (!this.isDevelopment) {
            return baseUrl;
        }
        
        // Convert player ID to UUID format for backend compatibility
        const uuid = this.convertToUUID(this.playerId);
        return `${baseUrl}?user_id=${uuid}`;
    }

    /**
     * Convert player ID to UUID format for backend
     */
    convertToUUID(playerId) {
        // Create a deterministic UUID from player ID
        const hash = this.simpleHash(playerId);
        const uuid = [
            hash.substr(0, 8),
            hash.substr(8, 4),
            '4' + hash.substr(12, 3), // Version 4 UUID
            ((parseInt(hash.substr(15, 1), 16) & 0x3) | 0x8).toString(16) + hash.substr(16, 3),
            hash.substr(19, 12)
        ].join('-');
        
        return uuid;
    }

    /**
     * Simple hash function for consistent UUID generation
     */
    simpleHash(str) {
        let hash = 0;
        for (let i = 0; i < str.length; i++) {
            const char = str.charCodeAt(i);
            hash = ((hash << 5) - hash) + char;
            hash = hash & hash; // Convert to 32-bit integer
        }
        
        // Convert to hex and pad to 32 characters
        const hex = Math.abs(hash).toString(16);
        return (hex + '0'.repeat(32)).substring(0, 32);
    }

    /**
     * Get player information for UI display
     */
    getPlayerInfo() {
        return {
            id: this.playerId,
            number: this.playerNumber,
            theme: this.playerTheme,
            uuid: this.convertToUUID(this.playerId),
            isDevelopment: this.isDevelopment
        };
    }

    /**
     * Auto-connect to WebSocket in development mode
     */
    async autoConnect(webSocketClient) {
        if (!this.isDevelopment || !webSocketClient) {
            console.log(`⚠️ DEBUG: Auto-connect skipped - isDev: ${this.isDevelopment}, hasClient: ${!!webSocketClient}`);
            return false;
        }
        
        const wsUrl = this.getWebSocketUrl();
        console.log(`🚀 DEBUG: Auto-connecting Player ${this.playerNumber} to ${wsUrl}`);
        console.log(`🔍 DEBUG: Development mode: ${this.isDevelopment}, Player ID: ${this.playerId}`);
        
        try {
            await webSocketClient.connect(wsUrl);
            console.log(`✅ DEBUG: WebSocket connect() completed successfully`);
            return true;
        } catch (error) {
            console.error('❌ DEBUG: Auto-connect failed:', error);
            return false;
        }
    }

    /**
     * Show connection info in UI
     */
    updateConnectionUI(status, sessionId = null) {
        const devInfo = document.getElementById('dev-info');
        if (!devInfo) return;
        
        const statusClass = status === 'connected' ? 'connected' : 'disconnected';
        devInfo.className = `dev-info ${statusClass}`;
        
        if (sessionId) {
            const sessionSpan = devInfo.querySelector('.session-id') || 
                              document.createElement('span');
            sessionSpan.className = 'session-id';
            sessionSpan.textContent = sessionId.substring(0, 8) + '...';
            devInfo.querySelector('.dev-badge').appendChild(sessionSpan);
        }
    }
}

// Export for use in other modules
window.DevAuthManager = DevAuthManager;