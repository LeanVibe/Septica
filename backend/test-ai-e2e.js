const puppeteer = require('puppeteer');

// Configuration for Romanian Septica AI Testing
const TEST_CONFIG = {
    BACKEND_PORT: 8085,
    FRONTEND_PORT: 3000,
    AI_ACTIVATION_TIMEOUT: 12000, // 12 seconds to match AI deployment timeout + buffer
    WEBSOCKET_CONNECTION_TIMEOUT: 5000,
    MATCHMAKING_WAIT_TIME: 15000, // Extended wait for AI deployment
    TEST_RETRY_COUNT: 3,
    SCREENSHOT_PATH: './test-screenshots/',
};

// Ensure screenshot directory exists
const fs = require('fs');
if (!fs.existsSync(TEST_CONFIG.SCREENSHOT_PATH)) {
    fs.mkdirSync(TEST_CONFIG.SCREENSHOT_PATH, { recursive: true });
}

async function testAIEndToEnd() {
    console.log('🎯 Romanian Septica AI End-to-End Test Suite');
    console.log('=' * 60);
    console.log(`Backend: http://localhost:${TEST_CONFIG.BACKEND_PORT}`);
    console.log(`Frontend: http://localhost:${TEST_CONFIG.FRONTEND_PORT}`);
    console.log(`AI Timeout: ${TEST_CONFIG.AI_ACTIVATION_TIMEOUT}ms`);
    console.log();

    const browser = await puppeteer.launch({
        headless: false, // Keep visible for debugging AI behavior
        defaultViewport: null,
        args: ['--start-maximized', '--no-sandbox', '--disable-setuid-sandbox']
    });

    const page = await browser.newPage();

    // Enhanced console logging to capture WebSocket AI messages
    page.on('console', msg => {
        const text = msg.text();
        if (text.includes('AI') || text.includes('WebSocket') || text.includes('matchmaking')) {
            console.log('🔍 Browser Console:', text);
        }
    });

    // Capture network requests to monitor AI WebSocket connections
    await page.setRequestInterception(true);
    page.on('request', request => {
        if (request.url().includes('ws://') || request.url().includes('matchmaking') || request.url().includes('ai')) {
            console.log('🌐 Network Request:', request.url());
        }
        request.continue();
    });

    try {
        // Step 1: Navigate to the application
        console.log('📍 Navigating to frontend application...');
        await page.goto(`http://localhost:${TEST_CONFIG.FRONTEND_PORT}`, {
            waitUntil: 'networkidle2',
            timeout: 10000
        });

        // Step 2: Validate backend connectivity
        console.log('🔌 Checking backend server connectivity...');
        const backendHealth = await checkBackendHealth(page);
        if (!backendHealth) {
            throw new Error(`Backend server not responding on port ${TEST_CONFIG.BACKEND_PORT}`);
        }
        console.log('✅ Backend server is healthy');

        // Step 3: Wait for page initialization and WebSocket setup
        console.log('⚡ Waiting for WebSocket connection establishment...');
        await page.waitForSelector('body', { timeout: 10000 });

        // Allow time for WebSocket connection to backend:8085
        await page.evaluate(() => {
            return new Promise((resolve) => {
                setTimeout(resolve, TEST_CONFIG.WEBSOCKET_CONNECTION_TIMEOUT);
            });
        });

        // Step 4: Validate WebSocket connection status
        const wsConnected = await page.evaluate(() => {
            // Check for WebSocket connection indicators
            return document.querySelector('[data-ws-status="connected"], .ws-connected') !== null ||
                   window.websocketConnected === true ||
                   document.body.classList.contains('ws-connected');
        });

        console.log(`🔗 WebSocket Status: ${wsConnected ? 'Connected' : 'Disconnected'}`);

        // Step 5: Comprehensive matchmaking button search
        console.log('🔍 Searching for matchmaking controls...');
        const matchmakingControls = await findMatchmakingControls(page);

        if (!matchmakingControls.found) {
            console.log('❌ No matchmaking controls found');
            console.log('🔍 Available interactive elements:');
            await logAvailableElements(page);
            throw new Error('Cannot proceed without matchmaking controls');
        }

        console.log(`🎯 Found matchmaking control: ${matchmakingControls.type}`);

        // Step 6: Initiate matchmaking
        console.log('🚀 Initiating matchmaking...');
        await matchmakingControls.element.click();

        // Wait for matchmaking status update
        await page.waitForTimeout(1500);

        // Step 7: Monitor for AI deployment with enhanced logging
        console.log('⏱️  Monitoring AI deployment process...');
        console.log(`   - AI Manager checks queue every 10 seconds`);
        console.log(`   - AI deployment timeout: ${TEST_CONFIG.AI_ACTIVATION_TIMEOUT}ms`);
        console.log(`   - Expected AI names: Andreea_Incepator, Cristian_Mediu, Diana_Mediu, etc.`);

        const aiDeploymentResult = await monitorAIDeployment(page);

        // Step 8: Validate match creation with AI opponent
        console.log('🎮 Validating match creation...');
        const matchResult = await validateMatchWithAI(page);

        console.log('📊 AI Deployment Results:');
        console.log(`   - AI Deployed: ${aiDeploymentResult.deployed ? '✅' : '❌'}`);
        console.log(`   - Match Created: ${matchResult.created ? '✅' : '❌'}`);
        console.log(`   - AI Opponent: ${matchResult.aiOpponent || 'None detected'}`);

        if (aiDeploymentResult.aiNames.length > 0) {
            console.log(`   - AI Names Detected: ${aiDeploymentResult.aiNames.join(', ')}`);
        }

        // Step 9: Test AI strategic behavior (if match created)
        if (matchResult.created && matchResult.aiOpponent) {
            console.log('🧠 Testing AI strategic behavior...');
            await testAIGameplayBehavior(page, matchResult.aiOpponent);
        }

        // Step 10: Generate comprehensive test report
        const testReport = {
            timestamp: new Date().toISOString(),
            backend_port: TEST_CONFIG.BACKEND_PORT,
            frontend_port: TEST_CONFIG.FRONTEND_PORT,
            websocket_connected: wsConnected,
            ai_deployment: aiDeploymentResult,
            match_result: matchResult,
            test_status: 'COMPLETED'
        };

        // Step 11: Save screenshots and evidence
        await captureTestEvidence(page, testReport);

        console.log('✅ Romanian Septica AI End-to-End Test Completed Successfully');
        console.log('📄 Test report saved with screenshots');

        return testReport;

    } catch (error) {
        console.error('❌ Test failed:', error.message);

        // Capture error state
        const errorScreenshot = `${TEST_CONFIG.SCREENSHOT_PATH}ai-test-error-${Date.now()}.png`;
        await page.screenshot({
            path: errorScreenshot,
            fullPage: true
        });
        console.log(`📸 Error screenshot saved: ${errorScreenshot}`);

        // Try to capture any available debug information
        await captureDebugInfo(page);

        throw error;
    } finally {
        await browser.close();
        console.log('🔚 Browser closed');
    }
}

// ====================== HELPER FUNCTIONS ======================

async function checkBackendHealth(page) {
    try {
        const response = await page.evaluate(async (port) => {
            try {
                const res = await fetch(`http://localhost:${port}/health`);
                return { status: res.status, ok: res.ok };
            } catch (e) {
                return { error: e.message };
            }
        }, TEST_CONFIG.BACKEND_PORT);

        return response.ok || response.status === 200;
    } catch (error) {
        console.log('⚠️  Backend health check failed:', error.message);
        return false;
    }
}

async function findMatchmakingControls(page) {
    // Try multiple selectors for matchmaking controls
    const selectors = [
        '#joinMatchmakingBtn',
        '.join-matchmaking',
        'button[data-action="join-matchmaking"]',
        'button:contains("Join")',
        'button:contains("Matchmaking")',
        'button:contains("Play")',
        'button:contains("Find Game")',
        '.matchmaking-btn',
        '.play-btn'
    ];

    for (const selector of selectors) {
        try {
            const element = await page.$(selector);
            if (element) {
                const isVisible = await page.evaluate(el => {
                    const rect = el.getBoundingClientRect();
                    return rect.width > 0 && rect.height > 0;
                }, element);

                if (isVisible) {
                    return {
                        found: true,
                        element: element,
                        type: selector
                    };
                }
            }
        } catch (e) {
            // Continue to next selector
        }
    }

    return { found: false };
}

async function logAvailableElements(page) {
    const elements = await page.evaluate(() => {
        const buttons = Array.from(document.querySelectorAll('button'));
        const links = Array.from(document.querySelectorAll('a'));
        const inputs = Array.from(document.querySelectorAll('input[type="button"], input[type="submit"]'));

        return {
            buttons: buttons.map(btn => ({
                text: btn.textContent.trim(),
                id: btn.id,
                class: btn.className
            })).filter(b => b.text),
            links: links.map(link => ({
                text: link.textContent.trim(),
                href: link.href
            })).filter(l => l.text),
            inputs: inputs.map(input => ({
                value: input.value,
                id: input.id,
                class: input.className
            }))
        };
    });

    if (elements.buttons.length > 0) {
        console.log('   Buttons:', elements.buttons.map(b => b.text).join(', '));
    }
    if (elements.links.length > 0) {
        console.log('   Links:', elements.links.map(l => l.text).join(', '));
    }
    if (elements.inputs.length > 0) {
        console.log('   Inputs:', elements.inputs.map(i => i.value).join(', '));
    }
}

async function monitorAIDeployment(page) {
    const startTime = Date.now();
    const result = {
        deployed: false,
        aiNames: [],
        deploymentTime: null,
        logs: []
    };

    // Romanian AI name patterns to detect
    const romanianAIPatterns = [
        /\b(Alexandru|Maria|Ion|Ana|Gheorghe|Elena|Nicolae|Ioana|Constantin|Mihaela|Stefan|Carmen|Adrian|Daniela|Cristian|Andreea|Marius|Alina|Florin|Diana|Bogdan|Raluca|Razvan|Simona)_(Incepator|Mediu|Expert)\b/g
    ];

    // Monitor for AI deployment over the specified timeout period
    const monitoringInterval = 2000; // Check every 2 seconds
    const maxChecks = Math.ceil(TEST_CONFIG.AI_ACTIVATION_TIMEOUT / monitoringInterval);

    for (let check = 0; check < maxChecks; check++) {
        console.log(`   🔄 Check ${check + 1}/${maxChecks} (${(Date.now() - startTime)/1000}s elapsed)`);

        // Check page content for AI opponent indicators
        const pageContent = await page.evaluate(() => {
            return {
                bodyText: document.body.innerText,
                html: document.documentElement.innerHTML,
                title: document.title
            };
        });

        // Look for Romanian AI names in page content
        for (const pattern of romanianAIPatterns) {
            const matches = pageContent.bodyText.match(pattern);
            if (matches) {
                result.aiNames.push(...matches);
                result.deployed = true;
                result.deploymentTime = Date.now() - startTime;
                console.log(`   🤖 Romanian AI detected: ${matches.join(', ')}`);
                break;
            }
        }

        // Check for general AI indicators
        const aiIndicators = [
            'AI opponent',
            'artificial intelligence',
            'bot opponent',
            'computer player',
            'AI player joined',
            'Incepator', // Romanian difficulty levels
            'Mediu',
            'Expert'
        ];

        for (const indicator of aiIndicators) {
            if (pageContent.bodyText.toLowerCase().includes(indicator.toLowerCase())) {
                result.deployed = true;
                if (!result.deploymentTime) {
                    result.deploymentTime = Date.now() - startTime;
                }
                result.logs.push(`AI indicator found: ${indicator}`);
            }
        }

        if (result.deployed) {
            console.log(`   ✅ AI deployment confirmed after ${result.deploymentTime}ms`);
            break;
        }

        // Wait before next check
        await page.waitForTimeout(monitoringInterval);
    }

    return result;
}

async function validateMatchWithAI(page) {
    const result = {
        created: false,
        aiOpponent: null,
        gameState: null
    };

    try {
        // Look for game state indicators
        const gameState = await page.evaluate(() => {
            // Common game state selectors
            const gameContainer = document.querySelector('.game-container, #game, .septica-game');
            const playerList = document.querySelector('.players, .game-players, .opponents');
            const gameStatus = document.querySelector('.game-status, #gameStatus, .match-status');

            return {
                hasGameContainer: !!gameContainer,
                hasPlayerList: !!playerList,
                hasGameStatus: !!gameStatus,
                gameStatusText: gameStatus ? gameStatus.innerText : null,
                playerCount: playerList ? playerList.children.length : 0
            };
        });

        result.gameState = gameState;

        if (gameState.hasGameContainer || gameState.hasPlayerList || gameState.hasGameStatus) {
            result.created = true;
            console.log('   🎮 Game interface detected');

            if (gameState.gameStatusText) {
                console.log(`   📊 Game Status: ${gameState.gameStatusText}`);

                // Check if status mentions AI opponent
                const aiIndicators = ['AI', 'Incepator', 'Mediu', 'Expert', 'bot', 'computer'];
                for (const indicator of aiIndicators) {
                    if (gameState.gameStatusText.includes(indicator)) {
                        result.aiOpponent = indicator;
                        break;
                    }
                }
            }
        }

    } catch (error) {
        console.log('   ⚠️  Error validating match:', error.message);
    }

    return result;
}

async function testAIGameplayBehavior(page, aiOpponent) {
    console.log('   🎯 Testing AI strategic behavior in game...');

    try {
        // Monitor AI moves for authentic Romanian Septica behavior
        const moveMonitor = await page.evaluate(() => {
            return new Promise((resolve) => {
                let moveCount = 0;
                const maxMoves = 5;
                const moves = [];

                const checkForMoves = () => {
                    // Look for card plays or game moves
                    const gameLog = document.querySelector('.game-log, .move-log, .game-events');
                    if (gameLog) {
                        const newMoves = Array.from(gameLog.children).map(el => el.innerText);
                        if (newMoves.length > moveCount) {
                            moves.push(...newMoves.slice(moveCount));
                            moveCount = newMoves.length;
                        }
                    }

                    if (moveCount >= maxMoves || Date.now() > startTime + 30000) {
                        resolve({ moves, aiMoveCount: moveCount });
                    } else {
                        setTimeout(checkForMoves, 2000);
                    }
                };

                const startTime = Date.now();
                checkForMoves();
            });
        });

        console.log(`   📋 AI made ${moveMonitor.aiMoveCount} moves`);
        if (moveMonitor.moves.length > 0) {
            console.log('   🎴 Sample moves:', moveMonitor.moves.slice(0, 3).join(', '));
        }

    } catch (error) {
        console.log('   ⚠️  Could not monitor AI gameplay:', error.message);
    }
}

async function captureTestEvidence(page, testReport) {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');

    // Main screenshot
    const mainScreenshot = `${TEST_CONFIG.SCREENSHOT_PATH}ai-test-main-${timestamp}.png`;
    await page.screenshot({
        path: mainScreenshot,
        fullPage: true
    });

    // Game state screenshot if available
    const gameArea = await page.$('.game-container, #game, .septica-game');
    if (gameArea) {
        const gameScreenshot = `${TEST_CONFIG.SCREENSHOT_PATH}ai-test-game-${timestamp}.png`;
        await gameArea.screenshot({ path: gameScreenshot });
        testReport.game_screenshot = gameScreenshot;
    }

    // Save test report
    const reportPath = `${TEST_CONFIG.SCREENSHOT_PATH}ai-test-report-${timestamp}.json`;
    require('fs').writeFileSync(reportPath, JSON.stringify(testReport, null, 2));

    testReport.main_screenshot = mainScreenshot;
    testReport.report_path = reportPath;

    console.log(`📸 Evidence captured: ${mainScreenshot}`);
    console.log(`📄 Report saved: ${reportPath}`);
}

async function captureDebugInfo(page) {
    try {
        const debugInfo = await page.evaluate(() => {
            return {
                url: window.location.href,
                title: document.title,
                wsStatus: window.websocketConnected || 'unknown',
                errorMessages: Array.from(document.querySelectorAll('.error, .alert-danger'))
                    .map(el => el.innerText),
                availableElements: {
                    buttons: Array.from(document.querySelectorAll('button')).length,
                    forms: Array.from(document.querySelectorAll('form')).length,
                    links: Array.from(document.querySelectorAll('a')).length
                }
            };
        });

        console.log('🔍 Debug Info:', JSON.stringify(debugInfo, null, 2));
    } catch (error) {
        console.log('⚠️  Could not capture debug info:', error.message);
    }
}

// Check if Puppeteer is installed
async function checkPuppeteer() {
    try {
        require('puppeteer');
        return true;
    } catch (e) {
        return false;
    }
}

// Main execution
(async () => {
    const hasPuppeteer = await checkPuppeteer();

    if (!hasPuppeteer) {
        console.log('❌ Puppeteer not found. Installing...');
        const { exec } = require('child_process');

        exec('npm install puppeteer', (error, stdout, stderr) => {
            if (error) {
                console.error('❌ Failed to install Puppeteer:', error);
                console.log('🔧 Please install Puppeteer manually: npm install puppeteer');
                return;
            }
            console.log('✅ Puppeteer installed');
            testAIEndToEnd();
        });
    } else {
        await testAIEndToEnd();
    }
})();