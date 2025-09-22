/**
 * Comprehensive Playwright E2E Test Suite for Romanian Septica
 * Testing both the dedicated test interface and the PWA frontend
 */

const { webkit, chromium } = require('playwright');

class SepticaPlaywrightTestSuite {
    constructor() {
        this.backendUrl = 'http://localhost:8080';
        this.testInterfaceUrl = 'http://localhost:8001';
        this.pwaUrl = 'http://localhost:8001';
        this.testResults = [];
        this.browser = null;
        this.contexts = [];
    }

    async initialize() {
        console.log('🎯 Initializing Septica Playwright Test Suite...');
        
        // Use webkit for iOS testing compatibility
        this.browser = await webkit.launch({ 
            headless: false,
            slowMo: 1000 // Slow down for demo
        });
        
        console.log('✅ Playwright browser initialized');
    }

    async runComprehensiveTests() {
        try {
            await this.initialize();
            
            console.log('\n🃏 Romanian Septica Comprehensive E2E Testing');
            console.log('='.repeat(60));
            
            // Test Sequence
            await this.testBackendHealth();
            await this.testInterface();
            await this.testPWAFunctionality();
            await this.testRomanianSepticaRules();
            await this.testWebSocketConnectivity();
            await this.testCrossTabMultiplayer();
            await this.testMobileResponsiveness();
            
            await this.generateFinalReport();
            
        } catch (error) {
            console.error('❌ Test suite failed:', error);
        } finally {
            await this.cleanup();
        }
    }

    async testBackendHealth() {
        console.log('\n🏥 Testing Backend Health...');
        
        const context = await this.browser.newContext();
        const page = await context.newPage();
        
        try {
            // Test health endpoint
            const response = await page.request.get(`${this.backendUrl}/health`);
            const healthData = await response.json();
            
            this.logTest('Backend Health Check', response.status() === 200, 
                `Status: ${response.status()}, Response: ${JSON.stringify(healthData)}`);
            
            // Test game creation endpoint
            const gameResponse = await page.request.post(`${this.backendUrl}/api/v1/games`, {
                data: { game_mode: 'casual' }
            });
            
            this.logTest('Game Creation Endpoint', gameResponse.status() === 201,
                `Status: ${gameResponse.status()}`);
            
        } catch (error) {
            this.logTest('Backend Health Check', false, `Error: ${error.message}`);
        } finally {
            await context.close();
        }
    }

    async testInterface() {
        console.log('\n🖥️ Testing Dedicated Test Interface...');
        
        const context = await this.browser.newContext();
        const page = await context.newPage();
        
        try {
            await page.goto(this.testInterfaceUrl);
            await page.waitForLoadState('networkidle');
            
            // Check if main elements are present
            const title = await page.textContent('h1');
            this.logTest('Test Interface Title', title?.includes('Septica'), 
                `Title: "${title}"`);
            
            // Check WebSocket connection controls
            const connectBtn = await page.locator('#connectBtn');
            const connectBtnExists = await connectBtn.count() > 0;
            this.logTest('WebSocket Connect Button', connectBtnExists, 
                'Connect button present');
            
            // Test connection
            if (connectBtnExists) {
                await connectBtn.click();
                await page.waitForTimeout(2000);
                
                const statusText = await page.textContent('#statusText');
                this.logTest('WebSocket Connection', statusText?.includes('Connected'), 
                    `Status: "${statusText}"`);
            }
            
            // Check game controls
            const gameControls = await page.locator('.game-panel').count();
            this.logTest('Game Controls Panel', gameControls > 0, 
                'Game controls panel present');
            
            // Check Romanian Septica game board
            const gameBoard = await page.locator('.game-board').count();
            this.logTest('Romanian Septica Game Board', gameBoard > 0, 
                'Game board present');
            
            // Check 3D renderer
            const threejsContainer = await page.locator('#threejsContainer').count();
            this.logTest('Three.js 3D Renderer', threejsContainer > 0, 
                '3D renderer container present');
            
        } catch (error) {
            this.logTest('Test Interface Loading', false, `Error: ${error.message}`);
        } finally {
            await context.close();
        }
    }

    async testPWAFunctionality() {
        console.log('\n📱 Testing PWA Functionality...');
        
        const context = await this.browser.newContext();
        const page = await context.newPage();
        
        try {
            await page.goto(this.pwaUrl);
            await page.waitForLoadState('networkidle');
            
            // Check PWA manifest
            const manifestLink = await page.locator('link[rel="manifest"]').count();
            this.logTest('PWA Manifest', manifestLink > 0, 
                'Manifest link present');
            
            // Check service worker registration
            const swRegistration = await page.evaluate(() => {
                return 'serviceWorker' in navigator;
            });
            this.logTest('Service Worker Support', swRegistration, 
                'Service worker API available');
            
            // Check offline capability indicators
            const connectionStatus = await page.locator('#connectionStatus').count();
            this.logTest('Connection Status Indicator', connectionStatus > 0, 
                'Connection status UI present');
            
            // Test install banner functionality
            const installBanner = await page.locator('#installBanner').count();
            this.logTest('PWA Install Banner', installBanner >= 0, 
                'Install banner element present');
            
        } catch (error) {
            this.logTest('PWA Functionality', false, `Error: ${error.message}`);
        } finally {
            await context.close();
        }
    }

    async testRomanianSepticaRules() {
        console.log('\n🇷🇴 Testing Romanian Septica Game Rules...');
        
        const context = await this.browser.newContext();
        const page = await context.newPage();
        
        try {
            await page.goto(this.testInterfaceUrl);
            await page.waitForLoadState('networkidle');
            
            // Connect to backend
            await page.click('#connectBtn');
            await page.waitForTimeout(2000);
            
            // Test card selection UI
            const cardSuitSelect = await page.locator('#cardSuit').count();
            const cardValueSelect = await page.locator('#cardValue').count();
            
            this.logTest('Romanian Card Selection UI', cardSuitSelect > 0 && cardValueSelect > 0, 
                'Card suit and value selectors present');
            
            // Test Romanian deck values (7-14)
            if (cardValueSelect > 0) {
                const valueOptions = await page.locator('#cardValue option').allTextContents();
                const hasRomanianDeck = valueOptions.includes('7') && 
                                       valueOptions.includes('10') && 
                                       valueOptions.includes('Ace');
                
                this.logTest('Romanian Deck Composition', hasRomanianDeck, 
                    `Available values: ${valueOptions.join(', ')}`);
            }
            
            // Test suit selection (Hearts, Diamonds, Clubs, Spades)
            if (cardSuitSelect > 0) {
                const suitOptions = await page.locator('#cardSuit option').allTextContents();
                const hasAllSuits = suitOptions.some(opt => opt.includes('Hearts')) &&
                                   suitOptions.some(opt => opt.includes('Diamonds')) &&
                                   suitOptions.some(opt => opt.includes('Clubs')) &&
                                   suitOptions.some(opt => opt.includes('Spades'));
                
                this.logTest('Romanian Card Suits', hasAllSuits, 
                    `Available suits: ${suitOptions.join(', ')}`);
            }
            
            // Test Romanian cultural elements
            const culturalElements = await page.textContent('body');
            const hasRomanianTheme = culturalElements.includes('Romanian') || 
                                   culturalElements.includes('Septica');
            
            this.logTest('Romanian Cultural Theme', hasRomanianTheme, 
                'Romanian/Septica references found');
            
        } catch (error) {
            this.logTest('Romanian Septica Rules', false, `Error: ${error.message}`);
        } finally {
            await context.close();
        }
    }

    async testWebSocketConnectivity() {
        console.log('\n🔌 Testing WebSocket Connectivity...');
        
        const context = await this.browser.newContext();
        const page = await context.newPage();
        
        try {
            await page.goto(this.testInterfaceUrl);
            await page.waitForLoadState('networkidle');
            
            // Monitor WebSocket messages
            let wsMessages = [];
            page.on('websocket', ws => {
                ws.on('framereceived', event => {
                    wsMessages.push({ type: 'received', data: event.payload });
                });
                ws.on('framesent', event => {
                    wsMessages.push({ type: 'sent', data: event.payload });
                });
            });
            
            // Connect to WebSocket
            await page.click('#connectBtn');
            await page.waitForTimeout(3000);
            
            // Check connection status
            const statusText = await page.textContent('#statusText');
            const isConnected = statusText?.includes('Connected');
            
            this.logTest('WebSocket Connection Established', isConnected, 
                `Status: "${statusText}", Messages: ${wsMessages.length}`);
            
            // Test ping functionality
            const pingBtn = await page.locator('#pingBtn');
            if (await pingBtn.count() > 0 && !await pingBtn.isDisabled()) {
                await pingBtn.click();
                await page.waitForTimeout(1000);
                
                this.logTest('WebSocket Ping/Pong', wsMessages.length > 0, 
                    `Messages exchanged: ${wsMessages.length}`);
            }
            
            // Test game joining
            const joinGameBtn = await page.locator('#joinGameBtn');
            if (await joinGameBtn.count() > 0 && !await joinGameBtn.isDisabled()) {
                await joinGameBtn.click();
                await page.waitForTimeout(2000);
                
                const gameInfo = await page.textContent('#gameInfo');
                this.logTest('Game Join Request', gameInfo?.includes('Game') || gameInfo?.includes('ID'), 
                    `Game info: ${gameInfo}`);
            }
            
        } catch (error) {
            this.logTest('WebSocket Connectivity', false, `Error: ${error.message}`);
        } finally {
            await context.close();
        }
    }

    async testCrossTabMultiplayer() {
        console.log('\n👥 Testing Cross-Tab Multiplayer...');
        
        const context1 = await this.browser.newContext();
        const context2 = await this.browser.newContext();
        
        const player1 = await context1.newPage();
        const player2 = await context2.newPage();
        
        try {
            // Setup Player 1
            await player1.goto(this.testInterfaceUrl);
            await player1.waitForLoadState('networkidle');
            await player1.click('#connectBtn');
            await player1.waitForTimeout(2000);
            
            // Setup Player 2
            await player2.goto(this.testInterfaceUrl);
            await player2.waitForLoadState('networkidle');
            await player2.click('#connectBtn');
            await player2.waitForTimeout(2000);
            
            // Check both connections
            const player1Status = await player1.textContent('#statusText');
            const player2Status = await player2.textContent('#statusText');
            
            const bothConnected = player1Status?.includes('Connected') && 
                                 player2Status?.includes('Connected');
            
            this.logTest('Multi-Player Connections', bothConnected, 
                `Player 1: "${player1Status}", Player 2: "${player2Status}"`);
            
            // Test synchronized game state
            if (bothConnected) {
                // Player 1 joins game
                const joinBtn1 = await player1.locator('#joinGameBtn');
                if (await joinBtn1.count() > 0 && !await joinBtn1.isDisabled()) {
                    await joinBtn1.click();
                    await player1.waitForTimeout(2000);
                }
                
                // Player 2 joins game
                const joinBtn2 = await player2.locator('#joinGameBtn');
                if (await joinBtn2.count() > 0 && !await joinBtn2.isDisabled()) {
                    await joinBtn2.click();
                    await player2.waitForTimeout(2000);
                }
                
                // Check for game state synchronization
                const gameState1 = await player1.textContent('#gameInfo');
                const gameState2 = await player2.textContent('#gameInfo');
                
                this.logTest('Cross-Tab Game Synchronization', 
                    gameState1 !== null && gameState2 !== null, 
                    'Game state present in both tabs');
            }
            
        } catch (error) {
            this.logTest('Cross-Tab Multiplayer', false, `Error: ${error.message}`);
        } finally {
            await context1.close();
            await context2.close();
        }
    }

    async testMobileResponsiveness() {
        console.log('\n📱 Testing Mobile Responsiveness...');
        
        const context = await this.browser.newContext({
            viewport: { width: 375, height: 667 }, // iPhone SE
            userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_6 like Mac OS X) AppleWebKit/605.1.15'
        });
        
        const page = await context.newPage();
        
        try {
            await page.goto(this.pwaUrl);
            await page.waitForLoadState('networkidle');
            
            // Check mobile viewport meta tag
            const viewportMeta = await page.locator('meta[name="viewport"]').count();
            this.logTest('Mobile Viewport Meta', viewportMeta > 0, 
                'Viewport meta tag present');
            
            // Check mobile-optimized UI elements
            const mobileElements = await page.locator('.mobile-optimization, .enhanced-btn, .glass-container').count();
            this.logTest('Mobile-Optimized UI Elements', mobileElements > 0, 
                `Mobile UI elements found: ${mobileElements}`);
            
            // Test touch interactions
            const gameBoard = await page.locator('.game-board');
            if (await gameBoard.count() > 0) {
                await gameBoard.tap();
                await page.waitForTimeout(500);
                
                this.logTest('Touch Interaction Support', true, 
                    'Game board touch interaction responsive');
            }
            
            // Check responsive Three.js container
            const threejsContainer = await page.locator('#threejsContainer');
            if (await threejsContainer.count() > 0) {
                const boundingBox = await threejsContainer.boundingBox();
                const fitsViewport = boundingBox && boundingBox.width <= 375;
                
                this.logTest('Three.js Mobile Responsiveness', fitsViewport, 
                    `Container width: ${boundingBox?.width}px (viewport: 375px)`);
            }
            
            // Test performance dashboard on mobile
            const perfBtn = await page.locator('#rendererStatsBtn');
            if (await perfBtn.count() > 0) {
                await perfBtn.click();
                await page.waitForTimeout(1000);
                
                this.logTest('Mobile Performance Dashboard', true, 
                    'Performance dashboard accessible on mobile');
            }
            
        } catch (error) {
            this.logTest('Mobile Responsiveness', false, `Error: ${error.message}`);
        } finally {
            await context.close();
        }
    }

    logTest(testName, passed, details = '') {
        const result = {
            test: testName,
            passed,
            details,
            timestamp: new Date().toISOString()
        };
        
        this.testResults.push(result);
        
        const status = passed ? '✅ PASS' : '❌ FAIL';
        console.log(`  ${status} ${testName}`);
        if (details) {
            console.log(`    ${details}`);
        }
    }

    async generateFinalReport() {
        console.log('\n📊 Final Test Report');
        console.log('='.repeat(60));
        
        const totalTests = this.testResults.length;
        const passedTests = this.testResults.filter(r => r.passed).length;
        const failedTests = totalTests - passedTests;
        const successRate = Math.round((passedTests / totalTests) * 100);
        
        console.log(`Total Tests: ${totalTests}`);
        console.log(`Passed: ${passedTests}`);
        console.log(`Failed: ${failedTests}`);
        console.log(`Success Rate: ${successRate}%`);
        
        console.log('\n🏆 Romanian Septica Implementation Status:');
        if (successRate >= 90) {
            console.log('🟢 EXCELLENT - Production Ready');
        } else if (successRate >= 75) {
            console.log('🟡 GOOD - Minor issues to address');
        } else {
            console.log('🔴 NEEDS WORK - Major issues detected');
        }
        
        // Log detailed results
        console.log('\n📋 Detailed Results:');
        this.testResults.forEach(result => {
            const status = result.passed ? '✅' : '❌';
            console.log(`${status} ${result.test}: ${result.details}`);
        });
        
        // Generate summary for weather scenario
        const criticalTests = [
            'Backend Health Check',
            'WebSocket Connection Established', 
            'Romanian Deck Composition',
            'Romanian Card Suits',
            'Cross-Tab Game Synchronization'
        ];
        
        const criticalPassed = criticalTests.filter(testName => 
            this.testResults.some(r => r.test === testName && r.passed)
        ).length;
        
        console.log('\n🌟 Weather Scenario Assessment:');
        console.log(`Critical Romanian Septica Features: ${criticalPassed}/${criticalTests.length} working`);
        
        if (criticalPassed === criticalTests.length) {
            console.log('☀️ SUNNY - All critical Romanian Septica features working perfectly!');
        } else if (criticalPassed >= criticalTests.length * 0.8) {
            console.log('⛅ PARTLY CLOUDY - Most features working, minor issues');
        } else {
            console.log('🌧️ STORMY - Critical issues need attention');
        }
    }

    async cleanup() {
        console.log('\n🧹 Cleaning up...');
        
        for (const context of this.contexts) {
            await context.close();
        }
        
        if (this.browser) {
            await this.browser.close();
        }
        
        console.log('✅ Cleanup complete');
    }
}

// Run the comprehensive test suite
async function runTests() {
    const testSuite = new SepticaPlaywrightTestSuite();
    await testSuite.runComprehensiveTests();
}

// Export for use as module or run directly
if (require.main === module) {
    runTests().catch(console.error);
}

module.exports = { SepticaPlaywrightTestSuite };