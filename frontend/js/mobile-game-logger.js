// Mobile Game Development Logger for Romanian Septica
// Optimized for real-time debugging and performance monitoring

class MobileGameLogger {
    constructor() {
        this.startTime = performance.now();
        this.frameCount = 0;
        this.lastFpsTime = this.startTime;
        this.memoryBaseline = this.getMemoryUsage();
        this.touchEvents = [];
        this.gameEvents = [];

        // Performance monitoring
        this.performanceMetrics = {
            fps: 0,
            memory: 0,
            touchLatency: 0,
            wsLatency: 0,
            cardPlayTime: 0,
            renderTime: 0
        };

        // Start performance monitoring
        this.startPerformanceMonitoring();

        console.log('%c🎮 MOBILE GAME LOGGER INITIALIZED',
            'color: #4CAF50; font-weight: bold; font-size: 14px;');
    }

    // ===== PERFORMANCE MONITORING =====

    startPerformanceMonitoring() {
        // FPS Monitoring
        const fpsCounter = () => {
            this.frameCount++;
            const now = performance.now();
            const delta = now - this.lastFpsTime;

            if (delta >= 1000) {
                this.performanceMetrics.fps = Math.round((this.frameCount * 1000) / delta);
                this.frameCount = 0;
                this.lastFpsTime = now;

                // Log FPS if below mobile game targets
                if (this.performanceMetrics.fps < 30) {
                    this.warn('PERFORMANCE', `Low FPS: ${this.performanceMetrics.fps} (Target: 60)`, {
                        fps: this.performanceMetrics.fps,
                        memory: this.getMemoryUsage(),
                        timestamp: this.getTimestamp()
                    });
                }
            }

            requestAnimationFrame(fpsCounter);
        };
        requestAnimationFrame(fpsCounter);

        // Memory monitoring every 5 seconds
        setInterval(() => {
            const currentMemory = this.getMemoryUsage();
            this.performanceMetrics.memory = currentMemory;

            if (currentMemory > this.memoryBaseline * 2) {
                this.error('MEMORY', `Memory leak detected: ${currentMemory}MB (baseline: ${this.memoryBaseline}MB)`, {
                    current: currentMemory,
                    baseline: this.memoryBaseline,
                    ratio: (currentMemory / this.memoryBaseline).toFixed(2)
                });
            }
        }, 5000);
    }

    getMemoryUsage() {
        if (performance.memory) {
            return Math.round(performance.memory.usedJSHeapSize / 1024 / 1024);
        }
        return 0;
    }

    // ===== ROMANIAN SEPTICA GAME LOGGING =====

    logCardPlay(playerName, card, tableState, isValidPlay, points = 0) {
        const timestamp = this.getTimestamp();
        const logData = {
            player: playerName,
            card: `${card.value}${card.suit}`,
            tableState: tableState.map(c => `${c.value}${c.suit}`),
            valid: isValidPlay,
            points: points,
            timestamp: timestamp,
            gameTime: this.getGameTime()
        };

        if (isValidPlay) {
            this.info('GAME_PLAY', `${playerName} played ${card.value}${card.suit} → ${points} points`, logData);
        } else {
            this.warn('GAME_RULE', `Invalid play: ${playerName} tried ${card.value}${card.suit}`, logData);
        }

        // Check Romanian Septica rules
        this.validateRomanianRules(card, tableState, isValidPlay);
    }

    validateRomanianRules(playedCard, tableState, wasValid) {
        const rules = {
            '7_beats_all': playedCard.value === 7,
            'same_value_beats': tableState.some(c => c.value === playedCard.value),
            '8_conditional': playedCard.value === 8 && (tableState.length % 3 === 0),
            'point_card': playedCard.value === 10 || playedCard.value === 14 // Ace = 14
        };

        // Log rule violations
        if (!wasValid && rules['7_beats_all']) {
            this.error('RULE_VIOLATION', '7 should always beat but was rejected!', {
                card: `${playedCard.value}${playedCard.suit}`,
                rule: '7_beats_all',
                tableState: tableState.map(c => `${c.value}${c.suit}`)
            });
        }

        if (rules.point_card) {
            this.info('POINTS', `Point card played: ${playedCard.value}${playedCard.suit}`, {
                value: playedCard.value === 10 ? '10 (1pt)' : 'Ace (1pt)',
                totalPossible: 8
            });
        }
    }

    logMatchmaking(status, playerId, waitTime = 0) {
        const logData = {
            playerId: playerId,
            status: status,
            waitTime: waitTime,
            timestamp: this.getTimestamp()
        };

        switch (status) {
            case 'queued':
                this.info('MATCHMAKING', `Player ${playerId} joined queue`, logData);
                break;
            case 'matched':
                this.success('MATCHMAKING', `Match found in ${waitTime}ms`, logData);
                break;
            case 'timeout':
                this.warn('MATCHMAKING', `Queue timeout after ${waitTime}ms`, logData);
                break;
            default:
                this.info('MATCHMAKING', `Status: ${status}`, logData);
        }
    }

    // ===== WEBSOCKET/NETWORK LOGGING =====

    logWebSocketEvent(eventType, data = null, latency = 0) {
        const timestamp = this.getTimestamp();
        const logData = {
            event: eventType,
            latency: latency,
            timestamp: timestamp,
            data: data
        };

        switch (eventType) {
            case 'connect':
                this.success('WEBSOCKET', 'Connected to game server', logData);
                break;
            case 'disconnect':
                this.error('WEBSOCKET', 'Disconnected from server', logData);
                break;
            case 'reconnect':
                this.info('WEBSOCKET', `Reconnected (${latency}ms)`, logData);
                break;
            case 'message':
                if (latency > 500) {
                    this.warn('WEBSOCKET', `High latency: ${latency}ms`, logData);
                } else {
                    this.debug('WEBSOCKET', `Message received (${latency}ms)`, logData);
                }
                break;
            case 'error':
                this.error('WEBSOCKET', 'Connection error', logData);
                break;
        }

        this.performanceMetrics.wsLatency = latency;
    }

    // ===== TOUCH/INPUT LOGGING =====

    logTouchEvent(eventType, touchData, responseTime = 0) {
        const timestamp = this.getTimestamp();
        const logData = {
            type: eventType,
            x: touchData.x,
            y: touchData.y,
            responseTime: responseTime,
            timestamp: timestamp
        };

        this.touchEvents.push(logData);

        // Keep only last 10 touch events
        if (this.touchEvents.length > 10) {
            this.touchEvents.shift();
        }

        if (responseTime > 100) {
            this.warn('INPUT_LAG', `Slow touch response: ${responseTime}ms`, logData);
        } else {
            this.debug('TOUCH', `${eventType} (${responseTime}ms)`, logData);
        }

        this.performanceMetrics.touchLatency = responseTime;
    }

    // ===== MOBILE DEVICE SPECIFIC =====

    logDeviceInfo() {
        const deviceInfo = {
            userAgent: navigator.userAgent,
            devicePixelRatio: window.devicePixelRatio,
            screenSize: `${screen.width}x${screen.height}`,
            viewportSize: `${window.innerWidth}x${window.innerHeight}`,
            connection: navigator.connection ? navigator.connection.effectiveType : 'unknown',
            memory: navigator.deviceMemory || 'unknown',
            cores: navigator.hardwareConcurrency || 'unknown',
            online: navigator.onLine,
            webgl: this.checkWebGLSupport()
        };

        this.info('DEVICE', 'Mobile device capabilities detected', deviceInfo);
        return deviceInfo;
    }

    checkWebGLSupport() {
        const canvas = document.createElement('canvas');
        const gl = canvas.getContext('webgl2') || canvas.getContext('webgl');
        return gl ? 'WebGL2/WebGL' : 'No WebGL';
    }

    // ===== ERROR HANDLING =====

    logError(error, context = {}) {
        const errorData = {
            message: error.message,
            stack: error.stack,
            context: context,
            timestamp: this.getTimestamp(),
            gameTime: this.getGameTime(),
            performance: this.performanceMetrics
        };

        this.error('GAME_ERROR', error.message, errorData);

        // Auto-report critical errors
        if (error.name === 'TypeError' || error.name === 'ReferenceError') {
            this.error('CRITICAL', 'Game-breaking error detected', errorData);
        }
    }

    // ===== LOG FORMATTING =====

    info(category, message, data = null) {
        this.log('INFO', category, message, data, 'color: #2196F3');
    }

    success(category, message, data = null) {
        this.log('SUCCESS', category, message, data, 'color: #4CAF50; font-weight: bold');
    }

    warn(category, message, data = null) {
        this.log('WARN', category, message, data, 'color: #FF9800; font-weight: bold');
    }

    error(category, message, data = null) {
        this.log('ERROR', category, message, data, 'color: #F44336; font-weight: bold');
    }

    debug(category, message, data = null) {
        if (this.debugMode) {
            this.log('DEBUG', category, message, data, 'color: #9E9E9E');
        }
    }

    log(level, category, message, data = null, style = '') {
        const timestamp = this.getTimestamp();
        const prefix = `[${timestamp}] [${level}] [${category}]`;

        if (data) {
            console.log(`%c${prefix} ${message}`, style, data);
        } else {
            console.log(`%c${prefix} ${message}`, style);
        }
    }

    // ===== UTILITY METHODS =====

    getTimestamp() {
        return new Date().toLocaleTimeString('en-US', {
            hour12: false,
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit',
            fractionalSecondDigits: 3
        });
    }

    getGameTime() {
        return Math.round(performance.now() - this.startTime);
    }

    // ===== PERFORMANCE DASHBOARD =====

    showPerformanceStats() {
        const stats = {
            ...this.performanceMetrics,
            gameTime: this.getGameTime(),
            memory: this.getMemoryUsage(),
            touchEvents: this.touchEvents.length
        };

        console.table(stats);
        return stats;
    }

    // ===== MOBILE GAME SPECIFIC ALERTS =====

    checkMobileGameHealth() {
        const issues = [];

        if (this.performanceMetrics.fps < 30) {
            issues.push(`Low FPS: ${this.performanceMetrics.fps}`);
        }

        if (this.performanceMetrics.memory > 100) {
            issues.push(`High memory: ${this.performanceMetrics.memory}MB`);
        }

        if (this.performanceMetrics.touchLatency > 100) {
            issues.push(`Input lag: ${this.performanceMetrics.touchLatency}ms`);
        }

        if (this.performanceMetrics.wsLatency > 300) {
            issues.push(`Network lag: ${this.performanceMetrics.wsLatency}ms`);
        }

        if (issues.length > 0) {
            this.warn('HEALTH_CHECK', 'Mobile game performance issues detected', {
                issues: issues,
                recommendations: this.getPerformanceRecommendations()
            });
        } else {
            this.success('HEALTH_CHECK', 'Mobile game performance is optimal', this.performanceMetrics);
        }

        return issues;
    }

    getPerformanceRecommendations() {
        const recommendations = [];

        if (this.performanceMetrics.fps < 30) {
            recommendations.push('Reduce Three.js quality settings');
            recommendations.push('Enable mobile LOD system');
        }

        if (this.performanceMetrics.memory > 100) {
            recommendations.push('Check for memory leaks in card animations');
            recommendations.push('Dispose unused Three.js objects');
        }

        return recommendations;
    }
}

// Global mobile game logger instance
window.MobileGameLogger = new MobileGameLogger();

// Auto-detect mobile device capabilities on load
window.addEventListener('load', () => {
    window.MobileGameLogger.logDeviceInfo();

    // Set up error tracking
    window.addEventListener('error', (event) => {
        window.MobileGameLogger.logError(event.error, {
            filename: event.filename,
            lineno: event.lineno,
            colno: event.colno
        });
    });

    // Monitor for mobile-specific events
    if ('ontouchstart' in window) {
        document.addEventListener('touchstart', (e) => {
            const startTime = performance.now();
            requestAnimationFrame(() => {
                const responseTime = performance.now() - startTime;
                window.MobileGameLogger.logTouchEvent('touchstart', {
                    x: e.touches[0].clientX,
                    y: e.touches[0].clientY
                }, responseTime);
            });
        });
    }

    // Health check every 30 seconds
    setInterval(() => {
        window.MobileGameLogger.checkMobileGameHealth();
    }, 30000);
});

export default MobileGameLogger;