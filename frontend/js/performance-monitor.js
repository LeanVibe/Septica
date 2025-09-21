/**
 * Performance Monitor for Romanian Septica PWA
 * Real-time performance tracking and adaptive quality management
 */

class PerformanceMonitor {
    constructor() {
        this.metrics = {
            fps: 0,
            frameTime: 0,
            memory: 0,
            triangles: 0,
            drawCalls: 0,
            renderTime: 0,
            networkLatency: 0,
            devicePixelRatio: window.devicePixelRatio || 1
        };
        
        this.history = {
            fps: [],
            frameTime: [],
            memory: [],
            networkLatency: []
        };
        
        this.maxHistoryLength = 60; // 1 second at 60fps
        this.thresholds = {
            lowFPS: 30,
            targetFPS: 60,
            highMemory: 100, // MB
            criticalMemory: 200, // MB
            slowFrameTime: 33, // ms (30fps)
            highLatency: 100 // ms
        };
        
        this.qualityLevel = 'high'; // high, medium, low
        this.adaptiveQuality = true;
        this.lastAdaptation = 0;
        this.adaptationCooldown = 2000; // 2 seconds
        
        this.callbacks = {
            onQualityChange: null,
            onPerformanceAlert: null,
            onMetricsUpdate: null
        };
        
        this.deviceCapabilities = this.detectDeviceCapabilities();
        this.isLowEndDevice = this.deviceCapabilities.tier === 'low';
        
        // FPS tracking
        this.lastTime = performance.now();
        this.frameCount = 0;
        this.fpsUpdateInterval = 1000; // Update FPS every second
        this.lastFPSUpdate = 0;
        
        this.startMonitoring();
    }
    
    /**
     * Detect device capabilities for performance adaptation
     */
    detectDeviceCapabilities() {
        const canvas = document.createElement('canvas');
        const gl = canvas.getContext('webgl') || canvas.getContext('experimental-webgl');
        
        const capabilities = {
            tier: 'high', // high, medium, low
            maxTextureSize: 1024,
            maxRenderBufferSize: 1024,
            hasFloatTextures: false,
            hasDepthTexture: false,
            maxVertexShaders: 16,
            maxFragmentShaders: 16,
            cores: navigator.hardwareConcurrency || 4,
            memory: navigator.deviceMemory || 4, // GB
            connection: this.getConnectionInfo()
        };
        
        if (gl) {
            try {
                capabilities.maxTextureSize = gl.getParameter(gl.MAX_TEXTURE_SIZE);
                capabilities.maxRenderBufferSize = gl.getParameter(gl.MAX_RENDERBUFFER_SIZE);
                capabilities.hasFloatTextures = !!gl.getExtension('OES_texture_float');
                capabilities.hasDepthTexture = !!gl.getExtension('WEBGL_depth_texture');
                capabilities.maxVertexShaders = gl.getParameter(gl.MAX_VERTEX_ATTRIBS);
                capabilities.maxFragmentShaders = gl.getParameter(gl.MAX_FRAGMENT_UNIFORM_VECTORS);
            } catch (e) {
                console.warn('Error detecting WebGL capabilities:', e);
            }
        }
        
        // Classify device tier
        const score = this.calculateDeviceScore(capabilities);
        if (score < 30) {
            capabilities.tier = 'low';
        } else if (score < 60) {
            capabilities.tier = 'medium';
        } else {
            capabilities.tier = 'high';
        }
        
        console.log('Device capabilities detected:', capabilities);
        return capabilities;
    }
    
    /**
     * Calculate device performance score
     */
    calculateDeviceScore(capabilities) {
        let score = 0;
        
        // WebGL capabilities (0-30 points)
        if (capabilities.maxTextureSize >= 2048) score += 10;
        else if (capabilities.maxTextureSize >= 1024) score += 5;
        
        if (capabilities.hasFloatTextures) score += 5;
        if (capabilities.hasDepthTexture) score += 5;
        if (capabilities.maxVertexShaders >= 16) score += 5;
        if (capabilities.maxFragmentShaders >= 16) score += 5;
        
        // Hardware specs (0-30 points)
        score += Math.min(capabilities.cores * 3, 15);
        score += Math.min(capabilities.memory * 2, 15);
        
        // Display capabilities (0-20 points)
        const pixelRatio = window.devicePixelRatio || 1;
        if (pixelRatio >= 2) score += 10;
        else if (pixelRatio >= 1.5) score += 5;
        
        const screenArea = window.screen.width * window.screen.height;
        if (screenArea >= 2073600) score += 10; // 1920x1080 or higher
        else if (screenArea >= 921600) score += 5; // 1280x720 or higher
        
        // Network capabilities (0-20 points)
        if (capabilities.connection.effectiveType === '4g') score += 20;
        else if (capabilities.connection.effectiveType === '3g') score += 10;
        else if (capabilities.connection.effectiveType === 'slow-2g') score += 0;
        else score += 5;
        
        return Math.min(score, 100);
    }
    
    /**
     * Get connection information
     */
    getConnectionInfo() {
        const connection = navigator.connection || navigator.mozConnection || navigator.webkitConnection;
        return {
            effectiveType: connection?.effectiveType || '4g',
            downlink: connection?.downlink || 10,
            rtt: connection?.rtt || 50,
            saveData: connection?.saveData || false
        };
    }
    
    /**
     * Start performance monitoring
     */
    startMonitoring() {
        this.monitoringActive = true;
        this.monitorFrame();
        
        // Monitor memory usage periodically
        if (performance.memory) {
            setInterval(() => {
                this.updateMemoryMetrics();
            }, 1000);
        }
        
        // Monitor network connection changes
        if (navigator.connection) {
            navigator.connection.addEventListener('change', () => {
                this.deviceCapabilities.connection = this.getConnectionInfo();
                this.adaptQualityIfNeeded();
            });
        }
        
        // Monitor device orientation changes
        window.addEventListener('orientationchange', () => {
            setTimeout(() => this.adaptQualityIfNeeded(), 500);
        });
    }
    
    /**
     * Monitor frame performance
     */
    monitorFrame() {
        if (!this.monitoringActive) return;
        
        const now = performance.now();
        const frameTime = now - this.lastTime;
        this.lastTime = now;
        this.frameCount++;
        
        // Update frame time metrics
        this.metrics.frameTime = frameTime;
        this.addToHistory('frameTime', frameTime);
        
        // Update FPS every second
        if (now - this.lastFPSUpdate >= this.fpsUpdateInterval) {
            this.metrics.fps = Math.round((this.frameCount * 1000) / (now - this.lastFPSUpdate));
            this.addToHistory('fps', this.metrics.fps);
            this.frameCount = 0;
            this.lastFPSUpdate = now;
            
            // Check if quality adaptation is needed
            this.adaptQualityIfNeeded();
            
            // Notify callbacks
            if (this.callbacks.onMetricsUpdate) {
                this.callbacks.onMetricsUpdate(this.metrics);
            }
        }
        
        requestAnimationFrame(() => this.monitorFrame());
    }
    
    /**
     * Update memory metrics
     */
    updateMemoryMetrics() {
        if (performance.memory) {
            const memoryMB = performance.memory.usedJSHeapSize / (1024 * 1024);
            this.metrics.memory = Math.round(memoryMB);
            this.addToHistory('memory', this.metrics.memory);
            
            // Check for memory warnings
            if (this.metrics.memory > this.thresholds.criticalMemory) {
                this.triggerPerformanceAlert('critical_memory', {
                    current: this.metrics.memory,
                    threshold: this.thresholds.criticalMemory
                });
            }
        }
    }
    
    /**
     * Update Three.js renderer metrics
     */
    updateRendererMetrics(renderer) {
        if (renderer && renderer.info) {
            this.metrics.triangles = renderer.info.render.triangles;
            this.metrics.drawCalls = renderer.info.render.calls;
        }
    }
    
    /**
     * Update network latency
     */
    updateNetworkLatency(latency) {
        this.metrics.networkLatency = latency;
        this.addToHistory('networkLatency', latency);
        
        if (latency > this.thresholds.highLatency) {
            this.triggerPerformanceAlert('high_latency', {
                current: latency,
                threshold: this.thresholds.highLatency
            });
        }
    }
    
    /**
     * Add value to history
     */
    addToHistory(metric, value) {
        if (!this.history[metric]) {
            this.history[metric] = [];
        }
        
        this.history[metric].push(value);
        if (this.history[metric].length > this.maxHistoryLength) {
            this.history[metric].shift();
        }
    }
    
    /**
     * Adapt quality based on performance
     */
    adaptQualityIfNeeded() {
        if (!this.adaptiveQuality || Date.now() - this.lastAdaptation < this.adaptationCooldown) {
            return;
        }
        
        const avgFPS = this.getAverageMetric('fps', 10);
        const avgFrameTime = this.getAverageMetric('frameTime', 10);
        const currentMemory = this.metrics.memory;
        
        let newQuality = this.qualityLevel;
        
        // Determine new quality level
        if (avgFPS < this.thresholds.lowFPS || 
            avgFrameTime > this.thresholds.slowFrameTime * 1.5 ||
            currentMemory > this.thresholds.criticalMemory) {
            newQuality = 'low';
        } else if (avgFPS < this.thresholds.targetFPS * 0.8 || 
                   avgFrameTime > this.thresholds.slowFrameTime ||
                   currentMemory > this.thresholds.highMemory) {
            newQuality = this.qualityLevel === 'high' ? 'medium' : 'low';
        } else if (avgFPS >= this.thresholds.targetFPS && 
                   avgFrameTime < this.thresholds.slowFrameTime * 0.8 &&
                   currentMemory < this.thresholds.highMemory * 0.8) {
            newQuality = this.qualityLevel === 'low' ? 'medium' : 'high';
        }
        
        // Apply quality change if different
        if (newQuality !== this.qualityLevel) {
            this.setQualityLevel(newQuality);
        }
    }
    
    /**
     * Set quality level
     */
    setQualityLevel(quality) {
        const oldQuality = this.qualityLevel;
        this.qualityLevel = quality;
        this.lastAdaptation = Date.now();
        
        console.log(`Quality adapted from ${oldQuality} to ${quality}`);
        
        if (this.callbacks.onQualityChange) {
            this.callbacks.onQualityChange(quality, oldQuality, this.getQualitySettings(quality));
        }
    }
    
    /**
     * Get quality settings for given level
     */
    getQualitySettings(quality) {
        const settings = {
            high: {
                pixelRatio: Math.min(window.devicePixelRatio, 2),
                shadowMapSize: 2048,
                enableShadows: true,
                enableAntialiasing: true,
                maxLights: 5,
                textureQuality: 'high',
                particleCount: 100,
                animationQuality: 'high'
            },
            medium: {
                pixelRatio: Math.min(window.devicePixelRatio, 1.5),
                shadowMapSize: 1024,
                enableShadows: true,
                enableAntialiasing: false,
                maxLights: 3,
                textureQuality: 'medium',
                particleCount: 50,
                animationQuality: 'medium'
            },
            low: {
                pixelRatio: 1,
                shadowMapSize: 512,
                enableShadows: false,
                enableAntialiasing: false,
                maxLights: 2,
                textureQuality: 'low',
                particleCount: 20,
                animationQuality: 'low'
            }
        };
        
        return settings[quality] || settings.medium;
    }
    
    /**
     * Get average metric value
     */
    getAverageMetric(metric, samples = 10) {
        const history = this.history[metric];
        if (!history || history.length === 0) return 0;
        
        const recent = history.slice(-samples);
        return recent.reduce((sum, val) => sum + val, 0) / recent.length;
    }
    
    /**
     * Trigger performance alert
     */
    triggerPerformanceAlert(type, data) {
        console.warn(`Performance alert: ${type}`, data);
        
        if (this.callbacks.onPerformanceAlert) {
            this.callbacks.onPerformanceAlert(type, data);
        }
    }
    
    /**
     * Get current metrics
     */
    getMetrics() {
        return {
            ...this.metrics,
            qualityLevel: this.qualityLevel,
            deviceTier: this.deviceCapabilities.tier,
            averages: {
                fps: this.getAverageMetric('fps', 10),
                frameTime: this.getAverageMetric('frameTime', 10),
                memory: this.getAverageMetric('memory', 10),
                networkLatency: this.getAverageMetric('networkLatency', 10)
            }
        };
    }
    
    /**
     * Get performance summary
     */
    getPerformanceSummary() {
        const metrics = this.getMetrics();
        
        return {
            overall: this.calculateOverallScore(metrics),
            graphics: this.calculateGraphicsScore(metrics),
            network: this.calculateNetworkScore(metrics),
            memory: this.calculateMemoryScore(metrics),
            recommendations: this.getRecommendations(metrics)
        };
    }
    
    /**
     * Calculate overall performance score (0-100)
     */
    calculateOverallScore(metrics) {
        const fpsScore = Math.min((metrics.averages.fps / this.thresholds.targetFPS) * 100, 100);
        const memoryScore = Math.max(100 - (metrics.averages.memory / this.thresholds.highMemory) * 100, 0);
        const networkScore = Math.max(100 - (metrics.averages.networkLatency / this.thresholds.highLatency) * 100, 0);
        
        return Math.round((fpsScore * 0.5 + memoryScore * 0.3 + networkScore * 0.2));
    }
    
    /**
     * Calculate graphics performance score
     */
    calculateGraphicsScore(metrics) {
        const fpsScore = Math.min((metrics.averages.fps / this.thresholds.targetFPS) * 100, 100);
        const frameTimeScore = Math.max(100 - (metrics.averages.frameTime / this.thresholds.slowFrameTime) * 100, 0);
        
        return Math.round((fpsScore + frameTimeScore) / 2);
    }
    
    /**
     * Calculate network performance score
     */
    calculateNetworkScore(metrics) {
        return Math.max(100 - (metrics.averages.networkLatency / this.thresholds.highLatency) * 100, 0);
    }
    
    /**
     * Calculate memory performance score
     */
    calculateMemoryScore(metrics) {
        return Math.max(100 - (metrics.averages.memory / this.thresholds.highMemory) * 100, 0);
    }
    
    /**
     * Get performance recommendations
     */
    getRecommendations(metrics) {
        const recommendations = [];
        
        if (metrics.averages.fps < this.thresholds.lowFPS) {
            recommendations.push('Consider reducing graphics quality or closing other apps');
        }
        
        if (metrics.averages.memory > this.thresholds.highMemory) {
            recommendations.push('High memory usage detected. Close other browser tabs or apps');
        }
        
        if (metrics.averages.networkLatency > this.thresholds.highLatency) {
            recommendations.push('Network latency is high. Check your internet connection');
        }
        
        if (this.qualityLevel === 'low') {
            recommendations.push('Graphics quality automatically reduced for better performance');
        }
        
        return recommendations;
    }
    
    /**
     * Stop monitoring
     */
    stopMonitoring() {
        this.monitoringActive = false;
    }
    
    /**
     * Set callback functions
     */
    setCallbacks(callbacks) {
        this.callbacks = { ...this.callbacks, ...callbacks };
    }
}

// Export for global use
window.PerformanceMonitor = PerformanceMonitor;