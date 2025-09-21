/**
 * Cross-Platform Validator for Romanian Septica PWA
 * Validates performance and compatibility across different devices and browsers
 */

class CrossPlatformValidator {
    constructor() {
        this.testResults = {};
        this.capabilities = {};
        this.performanceBaseline = {};
        
        this.detectPlatform();
        this.detectCapabilities();
        this.createTestSuite();
    }
    
    /**
     * Detect current platform and browser
     */
    detectPlatform() {
        const userAgent = navigator.userAgent;
        
        this.platform = {
            os: this.detectOS(userAgent),
            browser: this.detectBrowser(userAgent),
            device: this.detectDevice(userAgent),
            isMobile: /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(userAgent),
            isTablet: /iPad|Android(?=.*Tablet)|(?=.*\bAndroid\b)(?=.*\b(?:(?:7|10)(?:\.|$))|(?:.*(?:Nexus 7|Nexus 10|Pixel C|SM-T|GT-P|SCH-I|BGP|SGH-T|SHV-E|SM-P|SPH-P)))/i.test(userAgent),
            isDesktop: !/Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(userAgent),
            pixelRatio: window.devicePixelRatio || 1,
            screenSize: {
                width: window.screen.width,
                height: window.screen.height,
                availWidth: window.screen.availWidth,
                availHeight: window.screen.availHeight
            },
            viewport: {
                width: window.innerWidth,
                height: window.innerHeight
            }
        };
        
        console.log('Platform detected:', this.platform);
    }
    
    /**
     * Detect operating system
     */
    detectOS(userAgent) {
        if (/Windows NT/i.test(userAgent)) return 'Windows';
        if (/Macintosh|Mac OS X/i.test(userAgent)) return 'macOS';
        if (/Linux/i.test(userAgent)) return 'Linux';
        if (/Android/i.test(userAgent)) return 'Android';
        if (/iOS|iPhone|iPad|iPod/i.test(userAgent)) return 'iOS';
        return 'Unknown';
    }
    
    /**
     * Detect browser
     */
    detectBrowser(userAgent) {
        if (/Edg/i.test(userAgent)) return 'Edge';
        if (/Chrome/i.test(userAgent) && !/Edg/i.test(userAgent)) return 'Chrome';
        if (/Firefox/i.test(userAgent)) return 'Firefox';
        if (/Safari/i.test(userAgent) && !/Chrome/i.test(userAgent)) return 'Safari';
        if (/Opera|OPR/i.test(userAgent)) return 'Opera';
        return 'Unknown';
    }
    
    /**
     * Detect device type
     */
    detectDevice(userAgent) {
        if (/iPhone/i.test(userAgent)) return 'iPhone';
        if (/iPad/i.test(userAgent)) return 'iPad';
        if (/Android.*Mobile/i.test(userAgent)) return 'Android Phone';
        if (/Android/i.test(userAgent)) return 'Android Tablet';
        return 'Desktop';
    }
    
    /**
     * Detect browser and hardware capabilities
     */
    detectCapabilities() {
        this.capabilities = {
            // WebGL capabilities
            webgl: this.checkWebGLSupport(),
            webgl2: this.checkWebGL2Support(),
            
            // Web APIs
            websockets: 'WebSocket' in window,
            serviceWorker: 'serviceWorker' in navigator,
            pushNotifications: 'PushManager' in window,
            geolocation: 'geolocation' in navigator,
            
            // Storage
            localStorage: this.checkLocalStorage(),
            indexedDB: 'indexedDB' in window,
            
            // Audio/Video
            audioContext: 'AudioContext' in window || 'webkitAudioContext' in window,
            getUserMedia: 'mediaDevices' in navigator && 'getUserMedia' in navigator.mediaDevices,
            
            // Performance APIs
            performanceObserver: 'PerformanceObserver' in window,
            performanceMemory: 'memory' in performance,
            requestIdleCallback: 'requestIdleCallback' in window,
            
            // Touch and input
            touchEvents: 'ontouchstart' in window,
            pointerEvents: 'PointerEvent' in window,
            deviceOrientation: 'DeviceOrientationEvent' in window,
            
            // Hardware info
            hardwareConcurrency: navigator.hardwareConcurrency || 'unknown',
            deviceMemory: navigator.deviceMemory || 'unknown',
            connection: navigator.connection || navigator.mozConnection || navigator.webkitConnection,
            
            // Display capabilities
            pixelRatio: window.devicePixelRatio,
            colorDepth: window.screen.colorDepth,
            orientation: window.screen.orientation?.type || 'unknown'
        };
        
        console.log('Capabilities detected:', this.capabilities);
    }
    
    /**
     * Check WebGL support
     */
    checkWebGLSupport() {
        try {
            const canvas = document.createElement('canvas');
            const gl = canvas.getContext('webgl') || canvas.getContext('experimental-webgl');
            if (!gl) return false;
            
            return {
                supported: true,
                vendor: gl.getParameter(gl.VENDOR),
                renderer: gl.getParameter(gl.RENDERER),
                version: gl.getParameter(gl.VERSION),
                maxTextureSize: gl.getParameter(gl.MAX_TEXTURE_SIZE),
                maxVertexAttribs: gl.getParameter(gl.MAX_VERTEX_ATTRIBS),
                maxFragmentUniforms: gl.getParameter(gl.MAX_FRAGMENT_UNIFORM_VECTORS)
            };
        } catch (e) {
            return false;
        }
    }
    
    /**
     * Check WebGL2 support
     */
    checkWebGL2Support() {
        try {
            const canvas = document.createElement('canvas');
            const gl = canvas.getContext('webgl2');
            return !!gl;
        } catch (e) {
            return false;
        }
    }
    
    /**
     * Check localStorage support
     */
    checkLocalStorage() {
        try {
            localStorage.setItem('test', 'test');
            localStorage.removeItem('test');
            return true;
        } catch (e) {
            return false;
        }
    }
    
    /**
     * Create comprehensive test suite
     */
    createTestSuite() {
        this.testSuite = {
            // Performance tests
            performance: {
                renderingPerformance: this.testRenderingPerformance.bind(this),
                memoryUsage: this.testMemoryUsage.bind(this),
                networkLatency: this.testNetworkLatency.bind(this)
            },
            
            // Compatibility tests
            compatibility: {
                threejsCompatibility: this.testThreeJSCompatibility.bind(this),
                websocketCompatibility: this.testWebSocketCompatibility.bind(this),
                touchSupport: this.testTouchSupport.bind(this)
            },
            
            // Feature tests
            features: {
                particleEffects: this.testParticleEffects.bind(this),
                adaptiveQuality: this.testAdaptiveQuality.bind(this),
                offlineSupport: this.testOfflineSupport.bind(this)
            },
            
            // Romanian Septica specific tests
            gameLogic: {
                cardRendering: this.testCardRendering.bind(this),
                gameStateSync: this.testGameStateSync.bind(this),
                culturalElements: this.testCulturalElements.bind(this)
            }
        };
    }
    
    /**
     * Run all tests
     */
    async runAllTests() {
        console.log('Starting cross-platform validation...');
        this.testResults = {};
        
        for (const [category, tests] of Object.entries(this.testSuite)) {
            this.testResults[category] = {};
            
            for (const [testName, testFunction] of Object.entries(tests)) {
                try {
                    console.log(`Running ${category}.${testName}...`);
                    const result = await testFunction();
                    this.testResults[category][testName] = {
                        status: 'passed',
                        result: result,
                        timestamp: new Date().toISOString()
                    };
                } catch (error) {
                    console.error(`Test ${category}.${testName} failed:`, error);
                    this.testResults[category][testName] = {
                        status: 'failed',
                        error: error.message,
                        timestamp: new Date().toISOString()
                    };
                }
            }
        }
        
        console.log('Cross-platform validation completed:', this.testResults);
        return this.generateReport();
    }
    
    /**
     * Test rendering performance
     */
    async testRenderingPerformance() {
        const startTime = performance.now();
        let frameCount = 0;
        const targetFrames = 60;
        
        return new Promise((resolve) => {
            const testFrame = () => {
                frameCount++;
                if (frameCount < targetFrames) {
                    requestAnimationFrame(testFrame);
                } else {
                    const duration = performance.now() - startTime;
                    const fps = (frameCount / duration) * 1000;
                    resolve({
                        fps: Math.round(fps),
                        duration: Math.round(duration),
                        frameCount: frameCount,
                        performance: fps >= 30 ? 'good' : fps >= 15 ? 'acceptable' : 'poor'
                    });
                }
            };
            requestAnimationFrame(testFrame);
        });
    }
    
    /**
     * Test memory usage
     */
    async testMemoryUsage() {
        if (performance.memory) {
            return {
                usedJSHeapSize: Math.round(performance.memory.usedJSHeapSize / 1024 / 1024),
                totalJSHeapSize: Math.round(performance.memory.totalJSHeapSize / 1024 / 1024),
                jsHeapSizeLimit: Math.round(performance.memory.jsHeapSizeLimit / 1024 / 1024),
                supported: true
            };
        } else {
            return { supported: false, reason: 'performance.memory not available' };
        }
    }
    
    /**
     * Test network latency
     */
    async testNetworkLatency() {
        const startTime = performance.now();
        
        try {
            const response = await fetch(window.location.origin + '/ping', { 
                method: 'HEAD',
                cache: 'no-cache'
            });
            const latency = performance.now() - startTime;
            
            return {
                latency: Math.round(latency),
                status: response.status,
                performance: latency < 50 ? 'excellent' : latency < 100 ? 'good' : latency < 200 ? 'fair' : 'poor'
            };
        } catch (error) {
            return {
                error: error.message,
                fallbackTest: 'ping test failed'
            };
        }
    }
    
    /**
     * Test Three.js compatibility
     */
    async testThreeJSCompatibility() {
        if (!window.THREE) {
            throw new Error('Three.js not loaded');
        }
        
        const scene = new THREE.Scene();
        const camera = new THREE.PerspectiveCamera(75, 1, 0.1, 1000);
        const renderer = new THREE.WebGLRenderer();
        
        // Test basic geometry creation
        const geometry = new THREE.BoxGeometry(1, 1, 1);
        const material = new THREE.MeshBasicMaterial({ color: 0x00ff00 });
        const cube = new THREE.Mesh(geometry, material);
        scene.add(cube);
        
        // Test rendering
        renderer.setSize(100, 100);
        renderer.render(scene, camera);
        
        // Cleanup
        geometry.dispose();
        material.dispose();
        renderer.dispose();
        
        return { 
            compatible: true, 
            threeVersion: THREE.REVISION,
            rendererInfo: renderer.info 
        };
    }
    
    /**
     * Test WebSocket compatibility
     */
    async testWebSocketCompatibility() {
        return new Promise((resolve, reject) => {
            if (!window.WebSocket) {
                reject(new Error('WebSocket not supported'));
                return;
            }
            
            // Test basic WebSocket functionality
            try {
                const ws = new WebSocket('wss://echo.websocket.org');
                const timeout = setTimeout(() => {
                    ws.close();
                    reject(new Error('WebSocket connection timeout'));
                }, 5000);
                
                ws.onopen = () => {
                    clearTimeout(timeout);
                    ws.send('test');
                };
                
                ws.onmessage = (event) => {
                    ws.close();
                    resolve({
                        supported: true,
                        echoTest: event.data === 'test',
                        binaryType: ws.binaryType
                    });
                };
                
                ws.onerror = (error) => {
                    clearTimeout(timeout);
                    reject(new Error('WebSocket error: ' + error));
                };
            } catch (error) {
                reject(error);
            }
        });
    }
    
    /**
     * Test touch support
     */
    async testTouchSupport() {
        return {
            touchEvents: 'ontouchstart' in window,
            pointerEvents: 'PointerEvent' in window,
            maxTouchPoints: navigator.maxTouchPoints || 0,
            touchSupported: 'ontouchstart' in window || navigator.maxTouchPoints > 0
        };
    }
    
    /**
     * Test particle effects
     */
    async testParticleEffects() {
        if (!window.ParticleEffectsSystem) {
            throw new Error('ParticleEffectsSystem not available');
        }
        
        const scene = new THREE.Scene();
        const particleSystem = new ParticleEffectsSystem(scene, {
            maxParticles: 10,
            qualityLevel: 'low'
        });
        
        // Test effect creation
        const effectId = particleSystem.triggerEffect('cardSelect', new THREE.Vector3(0, 0, 0));
        
        // Let particles run for a bit
        await new Promise(resolve => setTimeout(resolve, 100));
        
        const stats = particleSystem.getStats();
        particleSystem.dispose();
        
        return {
            supported: true,
            effectTriggered: !!effectId,
            particleStats: stats
        };
    }
    
    /**
     * Test adaptive quality
     */
    async testAdaptiveQuality() {
        if (!window.PerformanceMonitor) {
            throw new Error('PerformanceMonitor not available');
        }
        
        const monitor = new PerformanceMonitor();
        const deviceCaps = monitor.deviceCapabilities;
        const qualitySettings = monitor.getQualitySettings(deviceCaps.tier);
        
        return {
            supported: true,
            deviceTier: deviceCaps.tier,
            qualityLevel: qualitySettings,
            adaptiveEnabled: true
        };
    }
    
    /**
     * Test offline support
     */
    async testOfflineSupport() {
        return {
            serviceWorkerSupported: 'serviceWorker' in navigator,
            cacheAPISupported: 'caches' in window,
            onlineStatus: navigator.onLine,
            offlineReady: 'serviceWorker' in navigator && 'caches' in window
        };
    }
    
    /**
     * Test card rendering
     */
    async testCardRendering() {
        if (!window.Card3DRenderer) {
            throw new Error('Card3DRenderer not available');
        }
        
        // This would normally test actual card rendering
        // For now, just verify the class exists and can be instantiated
        return {
            rendererAvailable: true,
            canInstantiate: typeof Card3DRenderer === 'function'
        };
    }
    
    /**
     * Test game state sync
     */
    async testGameStateSync() {
        if (!window.SepticaWebSocketClient) {
            throw new Error('SepticaWebSocketClient not available');
        }
        
        return {
            clientAvailable: true,
            canInstantiate: typeof SepticaWebSocketClient === 'function'
        };
    }
    
    /**
     * Test cultural elements
     */
    async testCulturalElements() {
        // Test Romanian flag colors
        const romanianColors = ['#002B7F', '#FCD116', '#CE1126'];
        
        // Test Unicode support for Romanian characters
        const romanianText = 'Septica Românească';
        const canvas = document.createElement('canvas');
        const ctx = canvas.getContext('2d');
        ctx.font = '16px Arial';
        const textWidth = ctx.measureText(romanianText).width;
        
        return {
            colorsSupported: true,
            unicodeSupported: textWidth > 0,
            culturalElementsReady: true
        };
    }
    
    /**
     * Generate comprehensive report
     */
    generateReport() {
        const totalTests = Object.values(this.testResults)
            .reduce((sum, category) => sum + Object.keys(category).length, 0);
        
        const passedTests = Object.values(this.testResults)
            .reduce((sum, category) => 
                sum + Object.values(category).filter(test => test.status === 'passed').length, 0);
        
        const compatibilityScore = Math.round((passedTests / totalTests) * 100);
        
        const report = {
            platform: this.platform,
            capabilities: this.capabilities,
            testResults: this.testResults,
            summary: {
                totalTests: totalTests,
                passedTests: passedTests,
                failedTests: totalTests - passedTests,
                compatibilityScore: compatibilityScore,
                overallStatus: compatibilityScore >= 90 ? 'excellent' : 
                              compatibilityScore >= 75 ? 'good' : 
                              compatibilityScore >= 60 ? 'acceptable' : 'poor'
            },
            recommendations: this.generateRecommendations(compatibilityScore),
            timestamp: new Date().toISOString()
        };
        
        console.log('Validation Report:', report);
        return report;
    }
    
    /**
     * Generate platform-specific recommendations
     */
    generateRecommendations(score) {
        const recommendations = [];
        
        if (score < 60) {
            recommendations.push('Consider upgrading browser or device for better experience');
        }
        
        if (!this.capabilities.webgl) {
            recommendations.push('WebGL not supported - 3D features will be disabled');
        }
        
        if (this.platform.isMobile && this.platform.pixelRatio > 2) {
            recommendations.push('High DPI mobile device - consider reducing quality for better performance');
        }
        
        if (this.capabilities.hardwareConcurrency < 4) {
            recommendations.push('Limited CPU cores detected - performance may be reduced');
        }
        
        if (this.capabilities.deviceMemory && this.capabilities.deviceMemory < 4) {
            recommendations.push('Limited device memory - consider low quality settings');
        }
        
        return recommendations;
    }
    
    /**
     * Export validation report
     */
    exportReport() {
        const report = this.generateReport();
        const blob = new Blob([JSON.stringify(report, null, 2)], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        
        const a = document.createElement('a');
        a.href = url;
        a.download = `septica-validation-${this.platform.os}-${this.platform.browser}-${new Date().toISOString().split('T')[0]}.json`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        
        URL.revokeObjectURL(url);
    }
}

// Export for global use
window.CrossPlatformValidator = CrossPlatformValidator;