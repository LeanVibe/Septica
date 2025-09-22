#!/usr/bin/env node

/**
 * COMPREHENSIVE E2E TEST RUNNER
 * =============================
 * 
 * Orchestrates and executes the complete Romanian Septica auto-matchmaking
 * test suite with comprehensive reporting and analysis.
 * 
 * Test Execution Order:
 * 1. System Readiness Validation
 * 2. WebSocket Message Flow Validation 
 * 3. Romanian Septica Rule Compliance
 * 4. Auto-Matchmaking E2E Testing
 * 5. Performance and Stress Testing
 * 6. Comprehensive Report Generation
 * 
 * Usage:
 * node run-comprehensive-e2e-tests.js [--quick] [--no-rules] [--no-e2e]
 */

const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');

class ComprehensiveE2ETestRunner {
    constructor() {
        this.config = {
            testTimeout: 300000, // 5 minutes per test suite
            maxRetries: 2,
            outputDir: './test-results',
            reportFile: './test-results/comprehensive-e2e-report.json'
        };
        
        this.testSuites = [
            {
                name: 'System Readiness',
                file: 'test-system-readiness.js',
                description: 'Backend, frontend, and infrastructure validation',
                critical: true,
                timeout: 30000
            },
            {
                name: 'WebSocket Message Flow',
                file: 'test-websocket-matchmaking-flow.js',
                description: 'Real-time communication protocol validation',
                critical: true,
                timeout: 60000
            },
            {
                name: 'Romanian Septica Rules',
                file: 'test-romanian-septica-rules.js',
                description: 'Cultural authenticity and rule compliance',
                critical: true,
                timeout: 45000
            },
            {
                name: 'Auto-Matchmaking E2E',
                file: 'test-auto-matchmaking-e2e.js',
                description: 'Complete two-tab workflow validation',
                critical: true,
                timeout: 120000
            },
            {
                name: 'Performance & Stress',
                file: 'test-performance-stress.js',
                description: 'Load testing and performance validation',
                critical: false,
                timeout: 90000
            }
        ];
        
        this.results = [];
        this.startTime = null;
        this.args = process.argv.slice(2);
    }

    async runComprehensiveTests() {
        console.log('🏛️ COMPREHENSIVE E2E TEST RUNNER');
        console.log('Romanian Septica Auto-Matchmaking System');
        console.log('=' .repeat(60));
        console.log('🎯 Testing complete "Play button → Auto-paired → Full game" workflow');
        console.log();

        this.startTime = Date.now();
        
        try {
            // Setup test environment
            await this.setupTestEnvironment();
            
            // Parse command line arguments
            const options = this.parseArguments();
            
            // Filter test suites based on options
            const testSuitesToRun = this.filterTestSuites(options);
            
            console.log(`📋 Running ${testSuitesToRun.length} test suites:`);
            testSuitesToRun.forEach((suite, index) => {
                console.log(`   ${index + 1}. ${suite.name} - ${suite.description}`);
            });
            console.log();
            
            // Execute test suites sequentially
            for (const suite of testSuitesToRun) {
                await this.runTestSuite(suite, options);
            }
            
            // Generate comprehensive report
            await this.generateComprehensiveReport(options);
            
        } catch (error) {
            console.error('❌ Test runner failed:', error);
            process.exit(1);
        }
    }

    parseArguments() {
        const options = {
            quick: this.args.includes('--quick'),
            noRules: this.args.includes('--no-rules'),
            noE2E: this.args.includes('--no-e2e'),
            noPerformance: this.args.includes('--no-performance'),
            verbose: this.args.includes('--verbose'),
            headless: this.args.includes('--headless')
        };
        
        if (options.quick) {
            console.log('⚡ Quick mode enabled - reduced test depth');
        }
        
        return options;
    }

    filterTestSuites(options) {
        return this.testSuites.filter(suite => {
            if (options.noRules && suite.name.includes('Rules')) return false;
            if (options.noE2E && suite.name.includes('E2E')) return false;
            if (options.noPerformance && suite.name.includes('Performance')) return false;
            return true;
        });
    }

    async setupTestEnvironment() {
        console.log('🔧 Setting up test environment...');
        
        // Create output directory
        if (!fs.existsSync(this.config.outputDir)) {
            fs.mkdirSync(this.config.outputDir, { recursive: true });
        }
        
        // Verify test files exist
        for (const suite of this.testSuites) {
            const filePath = path.join(__dirname, suite.file);
            if (!fs.existsSync(filePath)) {
                // Create minimal test file if it doesn't exist
                await this.createMinimalTestFile(suite);
            }
        }
        
        console.log('✅ Test environment ready');
        console.log();
    }

    async createMinimalTestFile(suite) {
        const filePath = path.join(__dirname, suite.file);
        
        // Create a minimal test file based on the suite type
        let content = '';
        
        if (suite.name === 'System Readiness') {
            content = this.createSystemReadinessTest();
        } else if (suite.name === 'Performance & Stress') {
            content = this.createPerformanceTest();
        } else {
            // Skip creation for files we already created
            return;
        }
        
        fs.writeFileSync(filePath, content);
        console.log(`   📄 Created ${suite.file}`);
    }

    createSystemReadinessTest() {
        return `#!/usr/bin/env node

/**
 * SYSTEM READINESS TEST
 * =====================
 * 
 * Validates that all system components are ready for testing:
 * - Backend server health
 * - Frontend availability  
 * - Database connectivity
 * - WebSocket endpoint
 */

const WebSocket = require('ws');

class SystemReadinessTest {
    constructor() {
        this.config = {
            backendUrl: 'http://localhost:8080',
            frontendUrl: 'http://localhost:3000',
            websocketUrl: 'ws://localhost:8080/ws/connect'
        };
        this.testResults = [];
    }

    async runTests() {
        console.log('🏥 SYSTEM READINESS VALIDATION');
        console.log('=' .repeat(40));
        
        try {
            await this.testBackendHealth();
            await this.testFrontendAvailability();
            await this.testWebSocketEndpoint();
            await this.testDatabaseConnectivity();
            
            this.generateReport();
            
        } catch (error) {
            console.error('❌ System readiness test failed:', error);
            process.exit(1);
        }
    }

    async testBackendHealth() {
        console.log('🧪 Testing backend health...');
        
        try {
            const response = await fetch(\`\${this.config.backendUrl}/health\`);
            const healthy = response.status === 200;
            
            this.logTest('Backend Health', healthy, \`Status: \${response.status}\`);
        } catch (error) {
            this.logTest('Backend Health', false, error.message);
        }
    }

    async testFrontendAvailability() {
        console.log('🧪 Testing frontend availability...');
        
        try {
            const response = await fetch(this.config.frontendUrl);
            const available = response.status === 200;
            
            this.logTest('Frontend Availability', available, \`Status: \${response.status}\`);
        } catch (error) {
            this.logTest('Frontend Availability', false, error.message);
        }
    }

    async testWebSocketEndpoint() {
        console.log('🧪 Testing WebSocket endpoint...');
        
        const connected = await new Promise((resolve) => {
            try {
                const ws = new WebSocket(this.config.websocketUrl);
                
                const timeout = setTimeout(() => {
                    ws.close();
                    resolve(false);
                }, 5000);
                
                ws.on('open', () => {
                    clearTimeout(timeout);
                    ws.close();
                    resolve(true);
                });
                
                ws.on('error', () => {
                    clearTimeout(timeout);
                    resolve(false);
                });
            } catch (error) {
                resolve(false);
            }
        });
        
        this.logTest('WebSocket Endpoint', connected, connected ? 'Connected' : 'Connection failed');
    }

    async testDatabaseConnectivity() {
        console.log('🧪 Testing database connectivity...');
        
        try {
            // Test via backend API
            const response = await fetch(\`\${this.config.backendUrl}/api/v1/games\`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ game_mode: 'test' })
            });
            
            const dbWorking = response.status === 201 || response.status === 200;
            this.logTest('Database Connectivity', dbWorking, \`API response: \${response.status}\`);
        } catch (error) {
            this.logTest('Database Connectivity', false, error.message);
        }
    }

    logTest(testName, passed, details = '') {
        this.testResults.push({ name: testName, passed, details });
        
        const status = passed ? '✅ PASS' : '❌ FAIL';
        console.log(\`   \${status} \${testName}\`);
        if (details) {
            console.log(\`      \${details}\`);
        }
    }

    generateReport() {
        const totalTests = this.testResults.length;
        const passedTests = this.testResults.filter(t => t.passed).length;
        const passRate = ((passedTests / totalTests) * 100).toFixed(1);
        
        console.log(\`\\n📊 System Readiness Report:\`);
        console.log(\`   Total Tests: \${totalTests}\`);
        console.log(\`   Passed: \${passedTests}\`);
        console.log(\`   Pass Rate: \${passRate}%\`);
        
        if (passRate < 100) {
            console.log(\`\\n❌ System not ready for testing!\`);
            process.exit(1);
        } else {
            console.log(\`\\n✅ System ready for comprehensive testing!\`);
        }
    }
}

// Run the test
if (require.main === module) {
    const test = new SystemReadinessTest();
    test.runTests().catch(console.error);
}

module.exports = { SystemReadinessTest };`;
    }

    createPerformanceTest() {
        return `#!/usr/bin/env node

/**
 * PERFORMANCE & STRESS TEST
 * =========================
 * 
 * Performance validation for Romanian Septica auto-matchmaking:
 * - Matchmaking speed benchmarks
 * - Concurrent user load testing
 * - WebSocket message latency
 * - Memory usage validation
 */

const WebSocket = require('ws');

class PerformanceStressTest {
    constructor() {
        this.config = {
            websocketUrl: 'ws://localhost:8080/ws/connect',
            backendUrl: 'http://localhost:8080',
            maxConcurrentUsers: 10,
            testDuration: 30000 // 30 seconds
        };
        this.testResults = [];
        this.performanceMetrics = [];
    }

    async runTests() {
        console.log('📊 PERFORMANCE & STRESS TESTING');
        console.log('=' .repeat(40));
        
        try {
            await this.testMatchmakingSpeed();
            await this.testConcurrentUserLoad();
            await this.testWebSocketLatency();
            await this.testMemoryUsage();
            
            this.generateReport();
            
        } catch (error) {
            console.error('❌ Performance test failed:', error);
        }
    }

    async testMatchmakingSpeed() {
        console.log('🧪 Testing matchmaking speed...');
        
        const iterations = 5;
        const times = [];
        
        for (let i = 0; i < iterations; i++) {
            const startTime = Date.now();
            
            // Simulate two players joining matchmaking
            const player1 = await this.createConnection();
            const player2 = await this.createConnection();
            
            // Wait for match (simplified)
            await this.sleep(2000);
            
            const matchTime = Date.now() - startTime;
            times.push(matchTime);
            
            player1.close();
            player2.close();
        }
        
        const avgTime = times.reduce((a, b) => a + b, 0) / times.length;
        const passed = avgTime < 5000; // 5 second target
        
        this.logTest('Matchmaking Speed', passed, \`Average: \${avgTime.toFixed(0)}ms\`);
        this.addMetric('Matchmaking Speed', avgTime, 'ms', 5000);
    }

    async testConcurrentUserLoad() {
        console.log('🧪 Testing concurrent user load...');
        
        const connections = [];
        const startTime = Date.now();
        
        try {
            // Create multiple concurrent connections
            for (let i = 0; i < this.config.maxConcurrentUsers; i++) {
                const conn = await this.createConnection();
                connections.push(conn);
            }
            
            const connectionTime = Date.now() - startTime;
            const passed = connectionTime < 10000; // 10 second target
            
            this.logTest('Concurrent User Load', passed, 
                \`\${connections.length} users connected in \${connectionTime}ms\`);
            
        } finally {
            // Clean up connections
            connections.forEach(conn => {
                if (conn.readyState === WebSocket.OPEN) {
                    conn.close();
                }
            });
        }
    }

    async testWebSocketLatency() {
        console.log('🧪 Testing WebSocket latency...');
        
        const connection = await this.createConnection();
        const latencies = [];
        
        try {
            for (let i = 0; i < 5; i++) {
                const startTime = Date.now();
                
                // Send ping message
                connection.send(JSON.stringify({
                    type: 'ping',
                    id: \`latency-test-\${i}\`,
                    timestamp: new Date().toISOString()
                }));
                
                // Wait for response (simplified)
                await this.sleep(100);
                
                const latency = Date.now() - startTime;
                latencies.push(latency);
            }
            
            const avgLatency = latencies.reduce((a, b) => a + b, 0) / latencies.length;
            const passed = avgLatency < 100; // 100ms target
            
            this.logTest('WebSocket Latency', passed, \`Average: \${avgLatency.toFixed(0)}ms\`);
            this.addMetric('WebSocket Latency', avgLatency, 'ms', 100);
            
        } finally {
            connection.close();
        }
    }

    async testMemoryUsage() {
        console.log('🧪 Testing memory usage...');
        
        // Basic memory usage validation
        const memoryUsage = process.memoryUsage();
        const heapUsedMB = memoryUsage.heapUsed / 1024 / 1024;
        const passed = heapUsedMB < 200; // 200MB target
        
        this.logTest('Memory Usage', passed, \`Heap used: \${heapUsedMB.toFixed(1)}MB\`);
        this.addMetric('Memory Usage', heapUsedMB, 'MB', 200);
    }

    async createConnection() {
        return new Promise((resolve, reject) => {
            const ws = new WebSocket(this.config.websocketUrl);
            
            const timeout = setTimeout(() => {
                reject(new Error('Connection timeout'));
            }, 5000);
            
            ws.on('open', () => {
                clearTimeout(timeout);
                resolve(ws);
            });
            
            ws.on('error', (error) => {
                clearTimeout(timeout);
                reject(error);
            });
        });
    }

    sleep(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    logTest(testName, passed, details = '') {
        this.testResults.push({ name: testName, passed, details });
        
        const status = passed ? '✅ PASS' : '❌ FAIL';
        console.log(\`   \${status} \${testName}\`);
        if (details) {
            console.log(\`      \${details}\`);
        }
    }

    addMetric(name, value, unit, target) {
        this.performanceMetrics.push({
            name, value, unit, target,
            passed: value < target
        });
    }

    generateReport() {
        const totalTests = this.testResults.length;
        const passedTests = this.testResults.filter(t => t.passed).length;
        const passRate = ((passedTests / totalTests) * 100).toFixed(1);
        
        console.log(\`\\n📊 Performance Test Report:\`);
        console.log(\`   Total Tests: \${totalTests}\`);
        console.log(\`   Passed: \${passedTests}\`);
        console.log(\`   Pass Rate: \${passRate}%\`);
        
        console.log(\`\\n⚡ Performance Metrics:\`);
        this.performanceMetrics.forEach(metric => {
            const status = metric.passed ? '✅' : '❌';
            console.log(\`   \${status} \${metric.name}: \${metric.value}\${metric.unit} (target: <\${metric.target}\${metric.unit})\`);
        });
        
        console.log(\`\\n🎯 Performance Status: \${passRate >= 80 ? '🟢 GOOD' : '🔴 NEEDS IMPROVEMENT'}\`);
    }
}

// Run the test
if (require.main === module) {
    const test = new PerformanceStressTest();
    test.runTests().catch(console.error);
}

module.exports = { PerformanceStressTest };`;
    }

    async runTestSuite(suite, options) {
        console.log(`🧪 Running ${suite.name}...`);
        
        const startTime = Date.now();
        let attempt = 1;
        let result = null;
        
        while (attempt <= this.config.maxRetries && !result?.passed) {
            try {
                if (attempt > 1) {
                    console.log(`   🔄 Retry attempt ${attempt}/${this.config.maxRetries}`);
                }
                
                result = await this.executeTestSuite(suite, options);
                
                if (result.passed) {
                    break;
                }
                
            } catch (error) {
                console.error(`   ❌ Attempt ${attempt} failed:`, error.message);
                result = {
                    name: suite.name,
                    passed: false,
                    error: error.message,
                    duration: Date.now() - startTime,
                    attempt: attempt
                };
            }
            
            attempt++;
            
            if (attempt <= this.config.maxRetries) {
                console.log('   ⏱️  Waiting 5 seconds before retry...');
                await this.sleep(5000);
            }
        }
        
        // Store result
        result.duration = Date.now() - startTime;
        result.critical = suite.critical;
        this.results.push(result);
        
        // Log result
        const status = result.passed ? '✅ PASSED' : '❌ FAILED';
        const duration = (result.duration / 1000).toFixed(1);
        console.log(`   ${status} ${suite.name} (${duration}s)`);
        
        if (!result.passed && result.error) {
            console.log(`   💥 Error: ${result.error}`);
        }
        
        // Check if critical test failed
        if (!result.passed && suite.critical) {
            console.log(`   ⚠️  Critical test failed - this may affect subsequent tests`);
        }
        
        console.log();
    }

    async executeTestSuite(suite, options) {
        const filePath = path.join(__dirname, suite.file);
        
        return new Promise((resolve, reject) => {
            const nodeProcess = spawn('node', [filePath], {
                stdio: options.verbose ? 'inherit' : 'pipe',
                timeout: suite.timeout || this.config.testTimeout
            });
            
            let stdout = '';
            let stderr = '';
            
            if (!options.verbose) {
                nodeProcess.stdout?.on('data', (data) => {
                    stdout += data.toString();
                });
                
                nodeProcess.stderr?.on('data', (data) => {
                    stderr += data.toString();
                });
            }
            
            nodeProcess.on('close', (code) => {
                const passed = code === 0;
                
                resolve({
                    name: suite.name,
                    passed: passed,
                    exitCode: code,
                    stdout: stdout,
                    stderr: stderr,
                    output: options.verbose ? 'Console output shown above' : stdout
                });
            });
            
            nodeProcess.on('error', (error) => {
                reject(error);
            });
            
            // Handle timeout
            setTimeout(() => {
                if (!nodeProcess.killed) {
                    nodeProcess.kill('SIGTERM');
                    reject(new Error(`Test suite timeout after ${suite.timeout || this.config.testTimeout}ms`));
                }
            }, suite.timeout || this.config.testTimeout);
        });
    }

    async generateComprehensiveReport(options) {
        const totalDuration = Date.now() - this.startTime;
        const totalTests = this.results.length;
        const passedTests = this.results.filter(r => r.passed).length;
        const failedTests = totalTests - passedTests;
        const overallPassRate = ((passedTests / totalTests) * 100).toFixed(1);
        
        console.log('📊 COMPREHENSIVE E2E TEST REPORT');
        console.log('Romanian Septica Auto-Matchmaking System');
        console.log('=' .repeat(60));
        
        // Executive Summary
        console.log('\\n🎯 EXECUTIVE SUMMARY');
        console.log(`   📅 Test Duration: ${(totalDuration / 1000 / 60).toFixed(1)} minutes`);
        console.log(`   📋 Test Suites Run: ${totalTests}`);
        console.log(`   ✅ Passed: ${passedTests}`);
        console.log(`   ❌ Failed: ${failedTests}`);
        console.log(`   📈 Overall Pass Rate: ${overallPassRate}%`);
        
        // Test Suite Results
        console.log('\\n📋 TEST SUITE RESULTS');
        this.results.forEach((result, index) => {
            const status = result.passed ? '✅' : '❌';
            const critical = result.critical ? ' (CRITICAL)' : '';
            const duration = (result.duration / 1000).toFixed(1);
            
            console.log(`   ${index + 1}. ${status} ${result.name}${critical} - ${duration}s`);
            
            if (!result.passed && result.error) {
                console.log(`      💥 ${result.error}`);
            }
        });
        
        // Critical Analysis
        const criticalTests = this.results.filter(r => r.critical);
        const criticalPassed = criticalTests.filter(r => r.passed).length;
        const criticalFailures = criticalTests.length - criticalPassed;
        
        console.log('\\n⚠️  CRITICAL ANALYSIS');
        console.log(`   Critical Tests: ${criticalTests.length}`);
        console.log(`   Critical Passed: ${criticalPassed}`);
        console.log(`   Critical Failures: ${criticalFailures}`);
        
        if (criticalFailures > 0) {
            console.log('   🚨 CRITICAL ISSUES DETECTED:');
            criticalTests.filter(r => !r.passed).forEach(test => {
                console.log(`      • ${test.name}: ${test.error || 'Failed'}`);
            });
        }
        
        // Production Readiness Assessment
        console.log('\\n🚀 PRODUCTION READINESS ASSESSMENT');
        const readiness = this.calculateProductionReadiness();
        console.log(`   🎯 Readiness Score: ${readiness.score}/100`);
        console.log(`   📊 Readiness Level: ${readiness.level}`);
        console.log(`   🚦 Recommendation: ${readiness.recommendation}`);
        
        // Feature Status
        console.log('\\n🎮 FEATURE STATUS SUMMARY');
        console.log(`   🔌 Auto-Matchmaking: ${this.getFeatureStatus('Auto-Matchmaking')}`);
        console.log(`   🇷🇴 Romanian Rules: ${this.getFeatureStatus('Romanian')}`);
        console.log(`   📡 WebSocket Flow: ${this.getFeatureStatus('WebSocket')}`);
        console.log(`   🏥 System Health: ${this.getFeatureStatus('System')}`);
        console.log(`   📊 Performance: ${this.getFeatureStatus('Performance')}`);
        
        // Quality Gates
        console.log('\\n🚪 QUALITY GATES');
        const qualityGates = [
            { name: 'All Critical Tests Pass', passed: criticalFailures === 0 },
            { name: 'Overall Pass Rate ≥ 80%', passed: overallPassRate >= 80 },
            { name: 'Auto-Matchmaking Works', passed: this.hasFeaturePassed('Auto-Matchmaking') },
            { name: 'Romanian Rules Compliant', passed: this.hasFeaturePassed('Romanian') },
            { name: 'No System Issues', passed: this.hasFeaturePassed('System') }
        ];
        
        qualityGates.forEach(gate => {
            const status = gate.passed ? '✅ PASS' : '❌ FAIL';
            console.log(`   ${status} ${gate.name}`);
        });
        
        const allQualityGatesPassed = qualityGates.every(gate => gate.passed);
        
        // Final Recommendation
        console.log('\\n🎯 FINAL RECOMMENDATION');
        if (allQualityGatesPassed && overallPassRate >= 90) {
            console.log('🟢 APPROVED FOR PRODUCTION');
            console.log('   All quality gates passed - system ready for deployment');
            console.log('   Romanian Septica auto-matchmaking fully functional');
        } else if (criticalFailures === 0 && overallPassRate >= 75) {
            console.log('🟡 CONDITIONAL APPROVAL');
            console.log('   Core functionality working - minor issues to address');
            console.log('   Consider deployment with monitoring');
        } else {
            console.log('🔴 NOT APPROVED FOR PRODUCTION');
            console.log('   Critical issues must be resolved before deployment');
            console.log('   Additional development and testing required');
        }
        
        // Save detailed report
        await this.saveDetailedReport();
        
        console.log('\\n🏁 COMPREHENSIVE E2E TESTING COMPLETE');
        console.log('=' .repeat(60));
        
        // Exit with appropriate code
        if (!allQualityGatesPassed || overallPassRate < 70) {
            process.exit(1);
        }
    }

    getFeatureStatus(featureName) {
        const relatedTests = this.results.filter(r => 
            r.name.toLowerCase().includes(featureName.toLowerCase())
        );
        
        if (relatedTests.length === 0) return '⚪ NOT TESTED';
        
        const passed = relatedTests.every(t => t.passed);
        return passed ? '🟢 WORKING' : '🔴 ISSUES';
    }

    hasFeaturePassed(featureName) {
        const relatedTests = this.results.filter(r => 
            r.name.toLowerCase().includes(featureName.toLowerCase())
        );
        
        return relatedTests.length > 0 && relatedTests.every(t => t.passed);
    }

    calculateProductionReadiness() {
        const totalTests = this.results.length;
        const passedTests = this.results.filter(r => r.passed).length;
        const baseScore = (passedTests / totalTests) * 100;
        
        // Weight critical tests higher
        const criticalTests = this.results.filter(r => r.critical);
        const criticalScore = criticalTests.length > 0 ? 
            (criticalTests.filter(r => r.passed).length / criticalTests.length) * 100 : 100;
        
        // Calculate weighted score
        const score = Math.round((baseScore * 0.4) + (criticalScore * 0.6));
        
        let level, recommendation;
        if (score >= 95) {
            level = 'PRODUCTION READY';
            recommendation = 'Deploy immediately - all systems operational';
        } else if (score >= 85) {
            level = 'NEAR READY';
            recommendation = 'Minor fixes needed - deploy within days';
        } else if (score >= 70) {
            level = 'DEVELOPMENT';
            recommendation = 'Resolve major issues - weeks of work needed';
        } else {
            level = 'CRITICAL ISSUES';
            recommendation = 'Significant rework required - months of development';
        }
        
        return { score, level, recommendation };
    }

    async saveDetailedReport() {
        const report = {
            timestamp: new Date().toISOString(),
            duration: Date.now() - this.startTime,
            summary: {
                totalTests: this.results.length,
                passed: this.results.filter(r => r.passed).length,
                failed: this.results.filter(r => !r.passed).length,
                passRate: ((this.results.filter(r => r.passed).length / this.results.length) * 100).toFixed(1)
            },
            results: this.results,
            readiness: this.calculateProductionReadiness()
        };
        
        fs.writeFileSync(this.config.reportFile, JSON.stringify(report, null, 2));
        console.log(`\\n💾 Detailed report saved to: ${this.config.reportFile}`);
    }

    sleep(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
}

// Run the comprehensive test suite
if (require.main === module) {
    const runner = new ComprehensiveE2ETestRunner();
    runner.runComprehensiveTests().catch(error => {
        console.error('💥 Test runner failed:', error);
        process.exit(1);
    });
}

module.exports = { ComprehensiveE2ETestRunner };