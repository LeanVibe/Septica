/**
 * Mobile Level of Detail (LOD) System for Romanian Septica PWA
 * Adaptive performance optimization for 60fps on iOS and mobile browsers
 */

class MobileLODSystem {
    constructor(renderer, performanceMonitor) {
        this.renderer = renderer;
        this.performanceMonitor = performanceMonitor;
        
        // LOD thresholds for mobile devices
        this.fpsThresholds = {
            high: 55,     // 55+ fps: Full quality
            medium: 40,   // 40-55 fps: Reduced quality
            low: 25,      // 25-40 fps: Minimal quality
            critical: 15  // <25 fps: Emergency mode
        };
        
        // Device-specific optimizations (must be initialized first)
        this.deviceOptimizations = this.detectDeviceOptimizations();
        
        // Current LOD state
        this.currentLOD = 'high';
        this.lodSettings = this.getLODSettings();
        
        // Performance tracking
        this.frameTimeHistory = [];
        this.lastLODUpdate = 0;
        this.lodUpdateInterval = 2000; // Update LOD every 2 seconds
        
        console.log('Mobile LOD System initialized:', {
            currentLOD: this.currentLOD,
            deviceOptimizations: this.deviceOptimizations
        });
    }
    
    /**
     * Detect device-specific optimizations
     */
    detectDeviceOptimizations() {
        const userAgent = navigator.userAgent;
        const isIOS = /iPad|iPhone|iPod/.test(userAgent);
        const isIOSSafari = isIOS && /Safari/.test(userAgent) && !/CriOS|FxiOS/.test(userAgent);
        const isLowMemory = navigator.deviceMemory && navigator.deviceMemory <= 2;
        const isOldDevice = this.detectOldDevice();
        
        const deviceOpts = {
            isIOS,
            isIOSSafari,
            isLowMemory,
            isOldDevice,
            shouldUseWebGL1: isOldDevice || isLowMemory,
            shouldDisableAntialiasing: isIOS || isLowMemory,
            shouldReduceTextures: isLowMemory || isOldDevice,
            shouldUseLowPrecision: isIOS || isOldDevice
        };
        
        // Add computed values that depend on the above
        deviceOpts.maxTextureSize = this.getMaxTextureSize(deviceOpts);
        deviceOpts.preferredPixelRatio = this.getPreferredPixelRatio(deviceOpts);
        
        return deviceOpts;
    }
    
    /**
     * Detect old/low-end devices
     */
    detectOldDevice() {
        const userAgent = navigator.userAgent;
        
        // Check for old iOS devices
        if (/iPhone/.test(userAgent)) {
            const match = userAgent.match(/iPhone OS (\d+)_/);
            if (match && parseInt(match[1]) < 13) return true;
        }
        
        // Check for old Android devices
        if (/Android/.test(userAgent)) {
            const match = userAgent.match(/Android (\d+\.\d+)/);
            if (match && parseFloat(match[1]) < 8.0) return true;
        }
        
        // Check hardware concurrency
        if (navigator.hardwareConcurrency && navigator.hardwareConcurrency < 4) return true;
        
        return false;
    }
    
    /**
     * Get optimal texture size for device
     */
    getMaxTextureSize(deviceOpts = null) {
        const opts = deviceOpts || this.deviceOptimizations;
        if (!opts) return 2048; // Fallback
        
        if (opts.isLowMemory) return 512;
        if (opts.isOldDevice) return 1024;
        if (opts.isIOS) return 2048;
        return 4096;
    }
    
    /**
     * Get preferred pixel ratio for device
     */
    getPreferredPixelRatio(deviceOpts = null) {
        const devicePixelRatio = window.devicePixelRatio || 1;
        const opts = deviceOpts || this.deviceOptimizations;
        
        if (!opts) return Math.min(devicePixelRatio, 2); // Fallback
        
        if (opts.isLowMemory) return Math.min(devicePixelRatio, 1);
        if (opts.isOldDevice) return Math.min(devicePixelRatio, 1.5);
        if (opts.isIOS) return Math.min(devicePixelRatio, 2);
        
        return Math.min(devicePixelRatio, 2);
    }
    
    /**
     * Get LOD settings for current level
     */
    getLODSettings() {
        const baseSettings = {
            high: {
                pixelRatio: this.deviceOptimizations.preferredPixelRatio,
                shadowMapSize: this.deviceOptimizations.isIOS ? 1024 : 2048,
                enableShadows: !this.deviceOptimizations.isLowMemory,
                enableAntialiasing: !this.deviceOptimizations.shouldDisableAntialiasing,
                cardGeometrySegments: 32,
                cardTextureSize: this.deviceOptimizations.maxTextureSize,
                particleCount: 100,
                enableReflections: !this.deviceOptimizations.isOldDevice,
                enableBloom: false, // Expensive on mobile
                renderDistance: 50,
                cullDistance: 100
            },
            medium: {
                pixelRatio: Math.min(this.deviceOptimizations.preferredPixelRatio, 1.5),
                shadowMapSize: 512,
                enableShadows: !this.deviceOptimizations.isLowMemory,
                enableAntialiasing: false,
                cardGeometrySegments: 16,
                cardTextureSize: Math.min(this.deviceOptimizations.maxTextureSize, 1024),
                particleCount: 50,
                enableReflections: false,
                enableBloom: false,
                renderDistance: 30,
                cullDistance: 60
            },
            low: {
                pixelRatio: 1,
                shadowMapSize: 256,
                enableShadows: false,
                enableAntialiasing: false,
                cardGeometrySegments: 8,
                cardTextureSize: 512,
                particleCount: 25,
                enableReflections: false,
                enableBloom: false,
                renderDistance: 20,
                cullDistance: 40
            },
            critical: {
                pixelRatio: 1,
                shadowMapSize: 128,
                enableShadows: false,
                enableAntialiasing: false,
                cardGeometrySegments: 4,
                cardTextureSize: 256,
                particleCount: 10,
                enableReflections: false,
                enableBloom: false,
                renderDistance: 10,
                cullDistance: 20
            }
        };
        
        return baseSettings[this.currentLOD];
    }
    
    /**
     * Update LOD based on current performance
     */
    updateLOD(currentFPS) {
        const now = performance.now();
        if (now - this.lastLODUpdate < this.lodUpdateInterval) return;
        
        this.lastLODUpdate = now;
        
        let newLOD = this.currentLOD;
        
        // Determine new LOD level based on FPS
        if (currentFPS >= this.fpsThresholds.high) {
            newLOD = 'high';
        } else if (currentFPS >= this.fpsThresholds.medium) {
            newLOD = 'medium';
        } else if (currentFPS >= this.fpsThresholds.low) {
            newLOD = 'low';
        } else {
            newLOD = 'critical';
        }
        
        // Apply hysteresis to prevent LOD thrashing
        if (newLOD !== this.currentLOD) {
            const shouldUpdate = this.shouldUpdateLOD(newLOD, currentFPS);
            if (shouldUpdate) {
                this.setLOD(newLOD);
            }
        }
    }
    
    /**
     * Determine if LOD should be updated (hysteresis)
     */
    shouldUpdateLOD(newLOD, currentFPS) {
        const lodLevels = ['critical', 'low', 'medium', 'high'];
        const currentIndex = lodLevels.indexOf(this.currentLOD);
        const newIndex = lodLevels.indexOf(newLOD);
        
        // Allow immediate downgrade for poor performance
        if (newIndex < currentIndex) return true;
        
        // Require stable performance for upgrade
        if (newIndex > currentIndex) {
            // Check if FPS has been stable above threshold
            return this.isPerformanceStable(newLOD, currentFPS);
        }
        
        return false;
    }
    
    /**
     * Check if performance is stable for LOD upgrade
     */
    isPerformanceStable(targetLOD, currentFPS) {
        const threshold = this.fpsThresholds[targetLOD];
        const requiredStabilityFrames = 60; // 1 second at 60fps
        
        // Add current FPS to history
        this.frameTimeHistory.push(currentFPS);
        if (this.frameTimeHistory.length > requiredStabilityFrames) {
            this.frameTimeHistory.shift();
        }
        
        // Check if we have enough history
        if (this.frameTimeHistory.length < requiredStabilityFrames) return false;
        
        // Check if all recent frames are above threshold
        return this.frameTimeHistory.every(fps => fps >= threshold);
    }
    
    /**
     * Set new LOD level
     */
    setLOD(newLOD) {
        if (newLOD === this.currentLOD) return;
        
        console.log(`LOD System: Switching from ${this.currentLOD} to ${newLOD}`);
        
        this.currentLOD = newLOD;
        this.lodSettings = this.getLODSettings();
        
        // Apply new settings to renderer
        this.applyLODSettings();
        
        // Clear frame history to prevent immediate changes
        this.frameTimeHistory = [];
        
        // Dispatch event for other systems
        const event = new CustomEvent('lodChanged', {
            detail: {
                oldLOD: this.currentLOD,
                newLOD: newLOD,
                settings: this.lodSettings
            }
        });
        window.dispatchEvent(event);
    }
    
    /**
     * Apply current LOD settings to renderer
     */
    applyLODSettings() {
        if (!this.renderer) return;
        
        const settings = this.lodSettings;
        
        // Update renderer pixel ratio
        this.renderer.setPixelRatio(settings.pixelRatio);
        
        // Update shadow settings
        this.renderer.shadowMap.enabled = settings.enableShadows;
        if (settings.enableShadows) {
            this.renderer.shadowMap.type = THREE.PCFShadowMap;
        }
        
        // Memory cleanup for texture changes
        if (settings.cardTextureSize !== this.previousTextureSize) {
            this.cleanupTextures();
            this.previousTextureSize = settings.cardTextureSize;
        }
    }
    
    /**
     * Clean up textures for memory management
     */
    cleanupTextures() {
        if (this.renderer && this.renderer.info) {
            // Force garbage collection of GPU resources
            this.renderer.dispose();
            
            // Clear texture cache if available
            if (THREE.Cache) {
                THREE.Cache.clear();
            }
        }
    }
    
    /**
     * Get current LOD information
     */
    getLODInfo() {
        return {
            currentLOD: this.currentLOD,
            settings: this.lodSettings,
            deviceOptimizations: this.deviceOptimizations,
            fpsThresholds: this.fpsThresholds
        };
    }
    
    /**
     * Force LOD level (for testing)
     */
    forceLOD(level) {
        if (['high', 'medium', 'low', 'critical'].includes(level)) {
            this.setLOD(level);
            return true;
        }
        return false;
    }
    
    /**
     * Get performance recommendations
     */
    getPerformanceRecommendations() {
        const recommendations = [];
        
        if (this.deviceOptimizations.isIOSSafari) {
            recommendations.push('iOS Safari detected: Using optimized shaders and reduced antialiasing');
        }
        
        if (this.deviceOptimizations.isLowMemory) {
            recommendations.push('Low memory device: Reduced texture sizes and disabled shadows');
        }
        
        if (this.deviceOptimizations.isOldDevice) {
            recommendations.push('Older device detected: Using simplified geometry and effects');
        }
        
        if (this.currentLOD === 'critical') {
            recommendations.push('Critical performance mode: Consider switching to 2D mode');
        }
        
        return recommendations;
    }
    
    /**
     * Destroy LOD system
     */
    destroy() {
        this.frameTimeHistory = [];
        this.cleanupTextures();
    }
}

// Export for use in other modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = MobileLODSystem;
} else if (typeof window !== 'undefined') {
    window.MobileLODSystem = MobileLODSystem;
}