/**
 * Mobile Performance Test Suite for Romanian Septica PWA
 * Comprehensive testing for 60fps performance on iOS and mobile browsers
 */

class MobilePerformanceTest {
    constructor() {
        this.testResults = [];
        this.benchmarks = {
            targetFPS: 60,
            minimumFPS: 30,
            maxMemoryMB: 50,
            maxLoadTimeMS: 2000,
            maxRenderTimeMS: 16.67 // 60fps = 16.67ms per frame
        };
        
        this.device = this.detectDevice();
        this.isRunning = false;
        this.startTime = 0;
        
        console.log('Mobile Performance Test initialized for:', this.device);
    }
    
    /**
     * Detect current device
     */
    detectDevice() {
        const userAgent = navigator.userAgent;
        const isIOS = /iPad|iPhone|iPod/.test(userAgent);
        const isAndroid = /Android/.test(userAgent);
        const isSafari = /Safari/.test(userAgent) && !/Chrome/.test(userAgent);
        
        return {
            platform: isIOS ? 'iOS' : isAndroid ? 'Android' : 'Desktop',
            browser: isSafari ? 'Safari' : /Chrome/.test(userAgent) ? 'Chrome' : 'Other',
            isIOSSafari: isIOS && isSafari,
            isMobile: isIOS || isAndroid,
            userAgent: userAgent,
            viewport: {
                width: window.innerWidth,
                height: window.innerHeight
            },
            pixelRatio: window.devicePixelRatio || 1,
            memory: navigator.deviceMemory || 'unknown',
            cores: navigator.hardwareConcurrency || 'unknown'
        };
    }
    
    /**
     * Run comprehensive performance test suite
     */
    async runPerformanceTests() {
        if (this.isRunning) {
            console.warn('Performance tests already running');
            return;
        }
        
        this.isRunning = true;
        this.startTime = performance.now();
        this.testResults = [];
        
        console.log('🚀 Starting Mobile Performance Test Suite...');
        
        try {
            // Test 1: WebGL Performance
            await this.testWebGLPerformance();
            
            // Test 2: Three.js Rendering Performance
            await this.testThreeJSPerformance();
            
            // Test 3: Touch Response Time
            await this.testTouchResponseTime();
            
            // Test 4: Memory Usage
            await this.testMemoryUsage();
            
            // Test 5: LOD System Performance
            await this.testLODSystem();
            
            // Test 6: Network Latency
            await this.testNetworkLatency();
            
            // Test 7: Battery Usage (if available)
            await this.testBatteryUsage();
            
            // Test 8: Frame Consistency
            await this.testFrameConsistency();
            
            // Generate report
            const report = this.generatePerformanceReport();
            console.log('✅ Performance tests completed:', report);
            
            return report;
            
        } catch (error) {
            console.error('❌ Performance test failed:', error);
            throw error;
        } finally {
            this.isRunning = false;
        }
    }
    
    /**
     * Test WebGL performance
     */
    async testWebGLPerformance() {
        const startTime = performance.now();
        
        const canvas = document.createElement('canvas');
        canvas.width = 512;
        canvas.height = 512;
        
        const gl = canvas.getContext('webgl2') || canvas.getContext('webgl');
        if (!gl) {
            this.addTestResult('WebGL Performance', false, 'WebGL not supported', 0);
            return;
        }
        
        // Simple WebGL performance test
        const vertexShader = this.createShader(gl, gl.VERTEX_SHADER, `
            attribute vec4 a_position;
            void main() {
                gl_Position = a_position;
            }
        `);
        
        const fragmentShader = this.createShader(gl, gl.FRAGMENT_SHADER, `
            precision mediump float;
            void main() {
                gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
            }
        `);
        
        const program = this.createProgram(gl, vertexShader, fragmentShader);
        const positionAttributeLocation = gl.getAttribLocation(program, 'a_position');
        
        // Create buffer
        const positionBuffer = gl.createBuffer();
        gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer);
        
        const positions = [
            -1, -1,
             1, -1,
            -1,  1,
             1,  1,
        ];
        gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(positions), gl.STATIC_DRAW);
        
        // Measure draw performance
        const drawStartTime = performance.now();
        const drawIterations = 1000;
        
        for (let i = 0; i < drawIterations; i++) {
            gl.viewport(0, 0, 512, 512);
            gl.clear(gl.COLOR_BUFFER_BIT);
            gl.useProgram(program);
            gl.enableVertexAttribArray(positionAttributeLocation);
            gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer);
            gl.vertexAttribPointer(positionAttributeLocation, 2, gl.FLOAT, false, 0, 0);
            gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
        }
        
        const drawTime = performance.now() - drawStartTime;
        const avgDrawTime = drawTime / drawIterations;
        
        const testTime = performance.now() - startTime;
        const passed = avgDrawTime < 1.0; // Less than 1ms per draw call
        
        this.addTestResult('WebGL Performance', passed, `Avg draw time: ${avgDrawTime.toFixed(3)}ms`, testTime);
        
        // Cleanup
        gl.deleteProgram(program);
        gl.deleteShader(vertexShader);
        gl.deleteShader(fragmentShader);
        gl.deleteBuffer(positionBuffer);
    }
    
    /**
     * Test Three.js rendering performance
     */
    async testThreeJSPerformance() {
        if (typeof THREE === 'undefined') {
            this.addTestResult('Three.js Performance', false, 'Three.js not available', 0);
            return;
        }
        
        const startTime = performance.now();
        
        // Create test scene
        const scene = new THREE.Scene();
        const camera = new THREE.PerspectiveCamera(75, 1, 0.1, 1000);
        const renderer = new THREE.WebGLRenderer({ antialias: false });
        
        renderer.setSize(512, 512);
        renderer.setPixelRatio(1); // Force low DPI for consistent testing
        
        // Add test objects
        const geometry = new THREE.BoxGeometry();
        const material = new THREE.MeshBasicMaterial({ color: 0x00ff00 });
        
        const cubes = [];
        for (let i = 0; i < 100; i++) {
            const cube = new THREE.Mesh(geometry, material);
            cube.position.x = (Math.random() - 0.5) * 10;
            cube.position.y = (Math.random() - 0.5) * 10;
            cube.position.z = (Math.random() - 0.5) * 10;
            scene.add(cube);
            cubes.push(cube);
        }
        
        camera.position.z = 5;
        
        // Measure render performance
        const frameCount = 60;
        const frameTimes = [];
        
        for (let frame = 0; frame < frameCount; frame++) {
            const frameStart = performance.now();
            
            // Animate cubes
            cubes.forEach(cube => {
                cube.rotation.x += 0.01;
                cube.rotation.y += 0.01;
            });
            
            renderer.render(scene, camera);
            
            const frameTime = performance.now() - frameStart;
            frameTimes.push(frameTime);
        }
        
        const avgFrameTime = frameTimes.reduce((a, b) => a + b, 0) / frameTimes.length;
        const maxFrameTime = Math.max(...frameTimes);
        const fps = 1000 / avgFrameTime;
        
        const testTime = performance.now() - startTime;
        const passed = fps >= this.benchmarks.minimumFPS && maxFrameTime < this.benchmarks.maxRenderTimeMS;
        
        this.addTestResult('Three.js Performance', passed, 
            `FPS: ${fps.toFixed(1)}, Avg: ${avgFrameTime.toFixed(2)}ms, Max: ${maxFrameTime.toFixed(2)}ms`, testTime);
        
        // Cleanup
        renderer.dispose();
        geometry.dispose();
        material.dispose();
    }
    
    /**
     * Test touch response time
     */
    async testTouchResponseTime() {
        if (!('ontouchstart' in window)) {
            this.addTestResult('Touch Response', false, 'Touch not supported', 0);
            return;
        }
        
        const startTime = performance.now();
        
        return new Promise((resolve) => {
            const testElement = document.createElement('div');
            testElement.style.position = 'fixed';
            testElement.style.top = '0';
            testElement.style.left = '0';
            testElement.style.width = '100px';
            testElement.style.height = '100px';
            testElement.style.background = 'red';
            testElement.style.zIndex = '10000';
            testElement.style.opacity = '0';
            
            document.body.appendChild(testElement);
            
            const touchStartTimes = [];
            const touchResponseTimes = [];
            
            let touchCount = 0;
            const maxTouches = 5;
            
            const handleTouchStart = (e) => {
                touchStartTimes[touchCount] = performance.now();
            };
            
            const handleTouchEnd = (e) => {
                const responseTime = performance.now() - touchStartTimes[touchCount];
                touchResponseTimes.push(responseTime);
                touchCount++;
                
                if (touchCount >= maxTouches) {
                    testElement.removeEventListener('touchstart', handleTouchStart);
                    testElement.removeEventListener('touchend', handleTouchEnd);
                    document.body.removeChild(testElement);
                    
                    const avgResponseTime = touchResponseTimes.reduce((a, b) => a + b, 0) / touchResponseTimes.length;
                    const maxResponseTime = Math.max(...touchResponseTimes);
                    
                    const testTime = performance.now() - startTime;
                    const passed = avgResponseTime < 50; // Less than 50ms response time
                    
                    this.addTestResult('Touch Response', passed, 
                        `Avg: ${avgResponseTime.toFixed(2)}ms, Max: ${maxResponseTime.toFixed(2)}ms`, testTime);
                    
                    resolve();
                } else {
                    // Simulate next touch after short delay
                    setTimeout(() => {
                        const touchEvent = new TouchEvent('touchstart', {
                            touches: [new Touch({
                                identifier: Date.now(),
                                target: testElement,
                                clientX: 50,
                                clientY: 50
                            })]
                        });
                        testElement.dispatchEvent(touchEvent);
                    }, 100);
                }
            };
            
            testElement.addEventListener('touchstart', handleTouchStart);
            testElement.addEventListener('touchend', handleTouchEnd);
            
            // Start first touch
            setTimeout(() => {
                const touchEvent = new TouchEvent('touchstart', {
                    touches: [new Touch({
                        identifier: Date.now(),
                        target: testElement,
                        clientX: 50,
                        clientY: 50
                    })]
                });
                testElement.dispatchEvent(touchEvent);
            }, 100);
        });
    }
    
    /**
     * Test memory usage
     */
    async testMemoryUsage() {
        const startTime = performance.now();
        
        if ('memory' in performance) {
            const memory = performance.memory;
            const usedMemoryMB = memory.usedJSHeapSize / 1024 / 1024;
            const totalMemoryMB = memory.totalJSHeapSize / 1024 / 1024;
            const limitMemoryMB = memory.jsHeapSizeLimit / 1024 / 1024;
            
            const passed = usedMemoryMB < this.benchmarks.maxMemoryMB;
            
            this.addTestResult('Memory Usage', passed,
                `Used: ${usedMemoryMB.toFixed(1)}MB, Total: ${totalMemoryMB.toFixed(1)}MB, Limit: ${limitMemoryMB.toFixed(1)}MB`,
                performance.now() - startTime);
        } else {
            this.addTestResult('Memory Usage', false, 'Memory API not available', 0);
        }
    }
    
    /**
     * Test LOD system performance
     */
    async testLODSystem() {
        const startTime = performance.now();
        
        if (typeof MobileLODSystem === 'undefined') {
            this.addTestResult('LOD System', false, 'MobileLODSystem not available', 0);
            return;
        }
        
        const lodSystem = new MobileLODSystem(null, null);
        
        // Test different FPS scenarios
        const fpsScenarios = [60, 45, 30, 15];
        const lodChanges = [];
        
        fpsScenarios.forEach(fps => {
            const initialLOD = lodSystem.currentLOD;
            lodSystem.updateLOD(fps);
            const newLOD = lodSystem.currentLOD;
            
            if (initialLOD !== newLOD) {
                lodChanges.push(`${fps}fps: ${initialLOD} → ${newLOD}`);
            }
        });
        
        const testTime = performance.now() - startTime;
        const passed = lodChanges.length > 0; // LOD should adapt
        
        this.addTestResult('LOD System', passed, 
            `Adaptations: ${lodChanges.join(', ')}`, testTime);
        
        lodSystem.destroy();
    }
    
    /**
     * Test network latency
     */
    async testNetworkLatency() {
        const startTime = performance.now();
        
        try {
            const latencyTests = [];
            const testCount = 3;
            
            for (let i = 0; i < testCount; i++) {
                const pingStart = performance.now();
                
                // Use a lightweight endpoint or fallback to same-origin
                const response = await fetch('/', { method: 'HEAD' });
                const latency = performance.now() - pingStart;
                
                latencyTests.push(latency);
            }
            
            const avgLatency = latencyTests.reduce((a, b) => a + b, 0) / latencyTests.length;
            const maxLatency = Math.max(...latencyTests);
            
            const testTime = performance.now() - startTime;
            const passed = avgLatency < 100; // Less than 100ms average
            
            this.addTestResult('Network Latency', passed,
                `Avg: ${avgLatency.toFixed(2)}ms, Max: ${maxLatency.toFixed(2)}ms`, testTime);
                
        } catch (error) {
            this.addTestResult('Network Latency', false, `Error: ${error.message}`, performance.now() - startTime);
        }
    }
    
    /**
     * Test battery usage (if available)
     */
    async testBatteryUsage() {
        const startTime = performance.now();
        
        if ('getBattery' in navigator) {
            try {
                const battery = await navigator.getBattery();
                const batteryLevel = (battery.level * 100).toFixed(0);
                const charging = battery.charging;
                
                this.addTestResult('Battery Status', true,
                    `Level: ${batteryLevel}%, Charging: ${charging}`, performance.now() - startTime);
            } catch (error) {
                this.addTestResult('Battery Status', false, 'Battery API error', performance.now() - startTime);
            }
        } else {
            this.addTestResult('Battery Status', false, 'Battery API not available', 0);
        }
    }
    
    /**
     * Test frame consistency
     */
    async testFrameConsistency() {
        const startTime = performance.now();
        
        return new Promise((resolve) => {
            const frameTimes = [];
            const frameCount = 60; // Test for 1 second at 60fps
            let currentFrame = 0;
            let lastFrameTime = performance.now();
            
            const testFrame = (timestamp) => {
                const frameTime = timestamp - lastFrameTime;
                frameTimes.push(frameTime);
                lastFrameTime = timestamp;
                currentFrame++;
                
                if (currentFrame < frameCount) {
                    requestAnimationFrame(testFrame);
                } else {
                    // Calculate frame consistency metrics
                    const avgFrameTime = frameTimes.reduce((a, b) => a + b, 0) / frameTimes.length;
                    const frameTimeVariance = frameTimes.reduce((acc, time) => acc + Math.pow(time - avgFrameTime, 2), 0) / frameTimes.length;
                    const frameTimeStdDev = Math.sqrt(frameTimeVariance);
                    
                    const testTime = performance.now() - startTime;
                    const passed = frameTimeStdDev < 5; // Low variance = consistent frames
                    
                    this.addTestResult('Frame Consistency', passed,
                        `Avg: ${avgFrameTime.toFixed(2)}ms, StdDev: ${frameTimeStdDev.toFixed(2)}ms`, testTime);
                    
                    resolve();
                }
            };
            
            requestAnimationFrame(testFrame);
        });
    }
    
    /**
     * Helper methods for WebGL testing
     */
    createShader(gl, type, source) {
        const shader = gl.createShader(type);
        gl.shaderSource(shader, source);
        gl.compileShader(shader);
        
        if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
            console.error('Shader compilation error:', gl.getShaderInfoLog(shader));
            gl.deleteShader(shader);
            return null;
        }
        
        return shader;
    }
    
    createProgram(gl, vertexShader, fragmentShader) {
        const program = gl.createProgram();
        gl.attachShader(program, vertexShader);
        gl.attachShader(program, fragmentShader);
        gl.linkProgram(program);
        
        if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
            console.error('Program linking error:', gl.getProgramInfoLog(program));
            gl.deleteProgram(program);
            return null;
        }
        
        return program;
    }
    
    /**
     * Add test result
     */
    addTestResult(testName, passed, details, executionTime) {
        const result = {
            testName,
            passed,
            details,
            executionTime: Math.round(executionTime),
            timestamp: new Date().toISOString()
        };
        
        this.testResults.push(result);
        console.log(`${passed ? '✅' : '❌'} ${testName}: ${details} (${executionTime.toFixed(2)}ms)`);
    }
    
    /**
     * Generate comprehensive performance report
     */
    generatePerformanceReport() {
        const totalTests = this.testResults.length;
        const passedTests = this.testResults.filter(t => t.passed).length;
        const totalExecutionTime = performance.now() - this.startTime;
        
        const performance_score = Math.round((passedTests / totalTests) * 100);
        
        const recommendations = this.generateRecommendations();
        
        return {
            summary: {
                device: this.device,
                totalTests,
                passedTests,
                failedTests: totalTests - passedTests,
                performanceScore: performance_score,
                totalExecutionTime: Math.round(totalExecutionTime),
                timestamp: new Date().toISOString()
            },
            testResults: this.testResults,
            recommendations,
            benchmarks: this.benchmarks,
            ready_for_production: performance_score >= 80 && this.device.isMobile
        };
    }
    
    /**
     * Generate performance recommendations
     */
    generateRecommendations() {
        const recommendations = [];
        
        // Check WebGL performance
        const webglTest = this.testResults.find(t => t.testName === 'WebGL Performance');
        if (webglTest && !webglTest.passed) {
            recommendations.push('Consider disabling advanced WebGL features for this device');
        }
        
        // Check Three.js performance
        const threejsTest = this.testResults.find(t => t.testName === 'Three.js Performance');
        if (threejsTest && !threejsTest.passed) {
            recommendations.push('Enable LOD system and reduce geometry complexity');
        }
        
        // Check memory usage
        const memoryTest = this.testResults.find(t => t.testName === 'Memory Usage');
        if (memoryTest && !memoryTest.passed) {
            recommendations.push('Reduce texture sizes and implement aggressive cleanup');
        }
        
        // iOS Safari specific
        if (this.device.isIOSSafari) {
            recommendations.push('iOS Safari detected: Use optimized shaders and disable antialiasing');
        }
        
        // Low-end device detection
        if (this.device.cores && this.device.cores < 4) {
            recommendations.push('Low-end device: Use critical LOD mode and disable particles');
        }
        
        if (recommendations.length === 0) {
            recommendations.push('Performance is optimal for this device');
        }
        
        return recommendations;
    }
}

// Export for use in other modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = MobilePerformanceTest;
} else if (typeof window !== 'undefined') {
    window.MobilePerformanceTest = MobilePerformanceTest;
}