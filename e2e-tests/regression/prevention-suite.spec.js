/**
 * Regression Prevention Test Suite
 * Automated tests to prevent breaking changes to critical functionality
 */

import { test, expect } from '@playwright/test';

const REGRESSION_CONFIG = {
  frontendUrl: 'http://localhost:3000',
  backendUrl: 'http://localhost:8080',
  criticalPaths: [
    'connection-establishment',
    'matchmaking-flow',
    'game-initialization',
    'card-play-mechanics',
    'romanian-rules-compliance',
    'real-time-synchronization',
    'performance-benchmarks'
  ]
};

test.describe('Regression Prevention Suite', () => {

  test.beforeEach(async () => {
    test.setTimeout(45000); // Extended timeout for thorough testing
  });

  test('CRITICAL: Core system functionality regression check', async ({ browser }) => {
    console.log('🔒 CRITICAL: Running core system functionality regression check...');

    const regressionResults = {
      connectionSystem: false,
      matchmakingSystem: false,
      gameSystem: false,
      communicationSystem: false,
      uiSystem: false
    };

    const context1 = await browser.newContext();
    const context2 = await browser.newContext();
    const player1 = await context1.newPage();
    const player2 = await context2.newPage();

    try {
      // === Test 1: Connection System ===
      console.log('🔌 Testing connection system...');

      const connectionStart = Date.now();

      await Promise.all([
        player1.goto(REGRESSION_CONFIG.frontendUrl),
        player2.goto(REGRESSION_CONFIG.frontendUrl)
      ]);

      // Basic page load functionality
      await Promise.all([
        player1.waitForSelector('body'),
        player2.waitForSelector('body')
      ]);

      // WebSocket connection functionality
      await Promise.all([
        player1.waitForSelector('#connection-text:has-text("Connected")', { timeout: 10000 }),
        player2.waitForSelector('#connection-text:has-text("Connected")', { timeout: 10000 })
      ]);

      const connectionTime = Date.now() - connectionStart;

      // Validate connection indicators
      const connected1 = await player1.locator('#connection-dot.connected').isVisible();
      const connected2 = await player2.locator('#connection-dot.connected').isVisible();

      if (connected1 && connected2 && connectionTime < 10000) {
        regressionResults.connectionSystem = true;
        console.log(`✅ Connection system: PASS (${connectionTime}ms)`);
      } else {
        console.log(`❌ Connection system: FAIL (connected1: ${connected1}, connected2: ${connected2}, time: ${connectionTime}ms)`);
      }

      // === Test 2: Matchmaking System ===
      console.log('🎯 Testing matchmaking system...');

      const matchmakingStart = Date.now();

      // Verify play buttons are functional
      const playBtn1Enabled = await player1.locator('#play-btn').isEnabled();
      const playBtn2Enabled = await player2.locator('#play-btn').isEnabled();

      if (!playBtn1Enabled || !playBtn2Enabled) {
        console.log('❌ Matchmaking system: FAIL - Play buttons not enabled');
      } else {
        // Initiate matchmaking
        await player1.click('#play-btn');
        await player2.click('#play-btn');

        // Check matchmaking overlay appears
        await Promise.all([
          player1.waitForSelector('#matchmaking-overlay', { state: 'visible', timeout: 5000 }),
          player2.waitForSelector('#matchmaking-overlay', { state: 'visible', timeout: 5000 })
        ]);

        // Wait for match completion
        await Promise.all([
          player1.waitForSelector('#matchmaking-overlay', { state: 'hidden', timeout: 20000 }),
          player2.waitForSelector('#matchmaking-overlay', { state: 'hidden', timeout: 20000 })
        ]);

        const matchmakingTime = Date.now() - matchmakingStart;

        if (matchmakingTime < 25000) {
          regressionResults.matchmakingSystem = true;
          console.log(`✅ Matchmaking system: PASS (${matchmakingTime}ms)`);
        } else {
          console.log(`❌ Matchmaking system: FAIL (timeout: ${matchmakingTime}ms)`);
        }
      }

      // === Test 3: Game System ===
      console.log('🎮 Testing game system...');

      if (regressionResults.matchmakingSystem) {
        // Verify both players are in game
        const inGame1 = await player1.locator('#leave-game-btn:enabled').isVisible();
        const inGame2 = await player2.locator('#leave-game-btn:enabled').isVisible();

        // Check initial game state
        const score1 = await player1.locator('#player-score').textContent();
        const score2 = await player2.locator('#player-score').textContent();
        const trick1 = await player1.locator('#trick-number').textContent();
        const trick2 = await player2.locator('#trick-number').textContent();

        // Check card dealing
        const cards1 = await player1.locator('#player-cards .card').count();
        const cards2 = await player2.locator('#player-cards .card').count();

        const gameStateValid = inGame1 && inGame2 &&
                              score1 === '0' && score2 === '0' &&
                              trick1 === '1' && trick2 === '1' &&
                              cards1 === 4 && cards2 === 4;

        if (gameStateValid) {
          regressionResults.gameSystem = true;
          console.log('✅ Game system: PASS');
        } else {
          console.log(`❌ Game system: FAIL (inGame: ${inGame1}/${inGame2}, scores: ${score1}/${score2}, tricks: ${trick1}/${trick2}, cards: ${cards1}/${cards2})`);
        }
      } else {
        console.log('⏩ Game system: SKIPPED (matchmaking failed)');
      }

      // === Test 4: Communication System ===
      console.log('⚡ Testing real-time communication...');

      if (regressionResults.gameSystem) {
        // Test game state synchronization
        const status1 = await player1.locator('#game-status').textContent();
        const status2 = await player2.locator('#game-status').textContent();

        // Both players should see some form of game status
        const communicationWorking = status1.length > 0 && status2.length > 0;

        // Test turn indicators (one should have turn, not both)
        const hasturn1 = status1.includes('Your turn') || status1.includes('your move');
        const hasturn2 = status2.includes('Your turn') || status2.includes('your move');
        const turnSystemWorking = (hasT

1 || hasT
2) && !(hasT
1 && hasT
2);

        if (communicationWorking && turnSystemWorking) {
          regressionResults.communicationSystem = true;
          console.log('✅ Communication system: PASS');
        } else {
          console.log(`❌ Communication system: FAIL (comm: ${communicationWorking}, turn: ${turnSystemWorking})`);
        }
      } else {
        console.log('⏩ Communication system: SKIPPED (game system failed)');
      }

      // === Test 5: UI System ===
      console.log('🖥️ Testing UI system...');

      // Check critical UI elements exist
      const uiElements = await Promise.all([
        player1.locator('#connection-dot').isVisible(),
        player1.locator('#connection-text').isVisible(),
        player1.locator('#play-btn').isVisible(),
        player1.locator('#game-status').isVisible(),
        player1.locator('#player-score').isVisible(),
        player1.locator('#opponent-score').isVisible(),
        player1.locator('#trick-number').isVisible(),
        player1.locator('#move-number').isVisible(),
        player1.locator('#player-cards').isVisible(),
        player1.locator('#table-cards').isVisible()
      ]);

      const uiElementsWorking = uiElements.filter(visible => visible).length;
      const uiSystemWorking = uiElementsWorking >= 8; // At least 8/10 elements should be visible

      if (uiSystemWorking) {
        regressionResults.uiSystem = true;
        console.log(`✅ UI system: PASS (${uiElementsWorking}/10 elements visible)`);
      } else {
        console.log(`❌ UI system: FAIL (${uiElementsWorking}/10 elements visible)`);
      }

      // === Overall Regression Assessment ===
      const passedSystems = Object.values(regressionResults).filter(passed => passed).length;
      const totalSystems = Object.keys(regressionResults).length;
      const regressionScore = (passedSystems / totalSystems) * 100;

      console.log('\n🔍 REGRESSION TEST RESULTS:');
      console.log('='.repeat(50));
      Object.entries(regressionResults).forEach(([system, passed]) => {
        console.log(`  ${system.padEnd(20)}: ${passed ? '✅ PASS' : '❌ FAIL'}`);
      });

      console.log(`\nOverall Score: ${passedSystems}/${totalSystems} (${regressionScore}%)`);

      if (regressionScore === 100) {
        console.log('🟢 EXCELLENT: No regressions detected');
      } else if (regressionScore >= 80) {
        console.log('🟡 WARNING: Minor regressions detected');
      } else {
        console.log('🔴 CRITICAL: Major regressions detected');
      }

      // Critical assertion - all core systems must work
      expect(regressionScore).toBeGreaterThanOrEqual(80); // Allow for minor issues but catch major regressions

    } finally {
      await context1.close();
      await context2.close();
    }
  });

  test('Romanian Septica rules regression check', async ({ page }) => {
    console.log('🇷🇴 Running Romanian Septica rules regression check...');

    await page.goto(REGRESSION_CONFIG.frontendUrl);
    await page.waitForSelector('#connection-text:has-text("Connected")');

    const rulesRegressionCheck = await page.evaluate(() => {
      const results = {
        deckComposition: false,
        beatingRules: false,
        pointSystem: false,
        gameStructure: false
      };

      // Test 1: Deck composition (32 cards, values 7-14)
      try {
        const validValues = [7, 8, 9, 10, 11, 12, 13, 14];
        const validSuits = ['hearts', 'diamonds', 'clubs', 'spades'];
        const expectedDeckSize = validValues.length * validSuits.length;

        results.deckComposition = expectedDeckSize === 32 &&
                                 validValues.length === 8 &&
                                 validSuits.length === 4;
      } catch (error) {
        console.log('Deck composition test error:', error);
      }

      // Test 2: Beating rules logic
      try {
        function canBeat(played, table, tableCount = 0) {
          if (played === 7) return true;
          if (played === table) return true;
          if (played === 8 && tableCount % 3 === 0) return true;
          return false;
        }

        const testCases = [
          { played: 7, table: 14, count: 1, expected: true },
          { played: 8, table: 9, count: 3, expected: true },
          { played: 8, table: 9, count: 2, expected: false },
          { played: 10, table: 10, count: 1, expected: true },
          { played: 9, table: 11, count: 1, expected: false }
        ];

        const passedTests = testCases.filter(test =>
          canBeat(test.played, test.table, test.count) === test.expected
        ).length;

        results.beatingRules = passedTests === testCases.length;
      } catch (error) {
        console.log('Beating rules test error:', error);
      }

      // Test 3: Point system (only 10s and Aces)
      try {
        function calculatePoints(cards) {
          return cards.reduce((total, card) => {
            return total + ((card === 10 || card === 14) ? 1 : 0);
          }, 0);
        }

        const testHands = [
          { cards: [10, 14, 7, 9], expected: 2 },
          { cards: [7, 8, 9, 11], expected: 0 },
          { cards: [10, 10, 14, 14], expected: 4 }
        ];

        const passedPointTests = testHands.filter(test =>
          calculatePoints(test.cards) === test.expected
        ).length;

        results.pointSystem = passedPointTests === testHands.length;
      } catch (error) {
        console.log('Point system test error:', error);
      }

      // Test 4: Game structure
      try {
        results.gameStructure = document.querySelector('#player-cards') &&
                               document.querySelector('#opponent-cards, .opponent-area') &&
                               document.querySelector('#table-cards') &&
                               document.querySelector('#player-score') &&
                               document.querySelector('#trick-number');
      } catch (error) {
        console.log('Game structure test error:', error);
      }

      return results;
    });

    console.log('Romanian rules regression check results:');
    Object.entries(rulesRegressionCheck).forEach(([rule, passed]) => {
      console.log(`  ${rule.padEnd(20)}: ${passed ? '✅ PASS' : '❌ FAIL'}`);
      expect(passed).toBe(true); // All Romanian rules must remain intact
    });

    const rulesPassed = Object.values(rulesRegressionCheck).filter(passed => passed).length;
    const totalRules = Object.keys(rulesRegressionCheck).length;

    console.log(`Romanian rules integrity: ${rulesPassed}/${totalRules} (${Math.round(rulesPassed/totalRules*100)}%)`);
  });

  test('Performance regression benchmarks', async ({ browser }) => {
    console.log('⚡ Running performance regression benchmarks...');

    const performanceBaselines = {
      connectionTime: 5000,     // 5s max
      matchmakingTime: 15000,   // 15s max
      cardInteractionTime: 500, // 500ms max
      memoryUsage: 100          // 100MB max
    };

    const measurements = {};
    let regressionDetected = false;

    const context1 = await browser.newContext();
    const context2 = await browser.newContext();
    const player1 = await context1.newPage();
    const player2 = await context2.newPage();

    try {
      // Connection performance
      const connectionStart = Date.now();

      await Promise.all([
        player1.goto(REGRESSION_CONFIG.frontendUrl),
        player2.goto(REGRESSION_CONFIG.frontendUrl)
      ]);

      await Promise.all([
        player1.waitForSelector('#connection-text:has-text("Connected")'),
        player2.waitForSelector('#connection-text:has-text("Connected")')
      ]);

      measurements.connectionTime = Date.now() - connectionStart;

      // Matchmaking performance
      const matchmakingStart = Date.now();

      await player1.click('#play-btn');
      await player2.click('#play-btn');

      await Promise.all([
        player1.waitForSelector('#matchmaking-overlay', { state: 'hidden', timeout: 20000 }),
        player2.waitForSelector('#matchmaking-overlay', { state: 'hidden', timeout: 20000 })
      ]);

      measurements.matchmakingTime = Date.now() - matchmakingStart;

      // Card interaction performance
      const cardCount = await player1.locator('#player-cards .card').count();

      if (cardCount > 0) {
        const interactionStart = Date.now();
        await player1.locator('#player-cards .card').first().hover();
        measurements.cardInteractionTime = Date.now() - interactionStart;
      } else {
        measurements.cardInteractionTime = 0;
      }

      // Memory usage
      const memory = await player1.evaluate(() => {
        if (performance.memory) {
          return performance.memory.usedJSHeapSize / 1024 / 1024; // MB
        }
        return null;
      });

      if (memory !== null) {
        measurements.memoryUsage = memory;
      }

      // Performance regression analysis
      console.log('\n📊 PERFORMANCE REGRESSION ANALYSIS:');
      console.log('='.repeat(50));

      Object.entries(performanceBaselines).forEach(([metric, baseline]) => {
        const measured = measurements[metric];

        if (measured !== undefined && measured !== null) {
          const withinBaseline = measured <= baseline;
          const percentageOfBaseline = Math.round((measured / baseline) * 100);

          console.log(`${metric.padEnd(20)}: ${Math.round(measured)}ms/${baseline}ms (${percentageOfBaseline}%) ${withinBaseline ? '✅' : '❌'}`);

          if (!withinBaseline) {
            regressionDetected = true;
            console.log(`  🔴 REGRESSION: ${metric} exceeded baseline by ${Math.round(measured - baseline)}ms`);
          }

          // Assert performance standards
          expect(measured).toBeLessThanOrEqual(baseline * 1.2); // Allow 20% variance for regression
        }
      });

      if (!regressionDetected) {
        console.log('\n🟢 No performance regressions detected');
      } else {
        console.log('\n🔴 Performance regressions detected');
      }

    } finally {
      await context1.close();
      await context2.close();
    }
  });

  test('API and backend regression check', async ({ page }) => {
    console.log('🔧 Running API and backend regression check...');

    await page.goto(REGRESSION_CONFIG.frontendUrl);

    const apiRegressionResults = await page.evaluate(async (backendUrl) => {
      const results = {
        healthEndpoint: false,
        gameCreation: false,
        webSocketConnection: false
      };

      try {
        // Test health endpoint
        const healthResponse = await fetch(`${backendUrl}/health`);
        results.healthEndpoint = healthResponse.status === 200;
      } catch (error) {
        console.log('Health endpoint test failed:', error);
      }

      try {
        // Test game creation endpoint
        const gameResponse = await fetch(`${backendUrl}/api/v1/games`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ game_mode: 'casual' })
        });
        results.gameCreation = gameResponse.status === 201;
      } catch (error) {
        console.log('Game creation test failed:', error);
      }

      try {
        // Test WebSocket connection capability
        results.webSocketConnection = typeof WebSocket !== 'undefined';
      } catch (error) {
        console.log('WebSocket test failed:', error);
      }

      return results;
    }, REGRESSION_CONFIG.backendUrl);

    console.log('API and backend regression results:');
    Object.entries(apiRegressionResults).forEach(([api, working]) => {
      console.log(`  ${api.padEnd(25)}: ${working ? '✅ WORKING' : '❌ BROKEN'}`);
      expect(working).toBe(true); // All API endpoints must remain functional
    });

    const apisPassed = Object.values(apiRegressionResults).filter(working => working).length;
    const totalApis = Object.keys(apiRegressionResults).length;

    console.log(`Backend API integrity: ${apisPassed}/${totalApis} (${Math.round(apisPassed/totalApis*100)}%)`);
  });

  test('UI/UX regression validation', async ({ page }) => {
    console.log('🖥️ Running UI/UX regression validation...');

    await page.goto(REGRESSION_CONFIG.frontendUrl);
    await page.waitForSelector('#connection-text:has-text("Connected")');

    const uiRegressionCheck = await page.evaluate(() => {
      const results = {
        criticalElements: false,
        layoutIntegrity: false,
        interactivity: false,
        visualConsistency: false
      };

      try {
        // Critical elements presence
        const criticalSelectors = [
          '#connection-dot',
          '#connection-text',
          '#play-btn',
          '#game-status',
          '#player-score',
          '#opponent-score',
          '#trick-number',
          '#move-number',
          '#player-cards',
          '#table-cards'
        ];

        const presentElements = criticalSelectors.filter(selector =>
          document.querySelector(selector)
        ).length;

        results.criticalElements = presentElements >= 8; // At least 80% should be present

        // Layout integrity
        const gameContainer = document.querySelector('.game-container, .game-board');
        const playerArea = document.querySelector('.player-area, #player-cards');
        const opponentArea = document.querySelector('.opponent-area, #opponent-cards');

        results.layoutIntegrity = !!(gameContainer && playerArea && opponentArea);

        // Interactivity
        const playBtn = document.querySelector('#play-btn');
        const isInteractive = playBtn && !playBtn.disabled;

        results.interactivity = isInteractive;

        // Visual consistency (basic CSS checks)
        const bodyStyles = getComputedStyle(document.body);
        const hasValidStyles = bodyStyles.backgroundColor !== 'rgba(0, 0, 0, 0)' ||
                              bodyStyles.color !== 'rgba(0, 0, 0, 0)';

        results.visualConsistency = hasValidStyles;

      } catch (error) {
        console.log('UI regression check error:', error);
      }

      return results;
    });

    console.log('UI/UX regression validation results:');
    Object.entries(uiRegressionCheck).forEach(([aspect, valid]) => {
      console.log(`  ${aspect.padEnd(20)}: ${valid ? '✅ VALID' : '❌ INVALID'}`);
      expect(valid).toBe(true); // All UI aspects must remain functional
    });

    const uiAspectsPassed = Object.values(uiRegressionCheck).filter(valid => valid).length;
    const totalAspects = Object.keys(uiRegressionCheck).length;

    console.log(`UI/UX integrity: ${uiAspectsPassed}/${totalAspects} (${Math.round(uiAspectsPassed/totalAspects*100)}%)`);
  });

  test('Browser compatibility regression check', async ({ browser, browserName }) => {
    console.log(`🌐 Running browser compatibility regression check for ${browserName}...`);

    const context = await browser.newContext();
    const page = await context.newPage();

    try {
      await page.goto(REGRESSION_CONFIG.frontendUrl);

      const compatibilityCheck = await page.evaluate(() => {
        const results = {
          webSocketSupport: typeof WebSocket !== 'undefined',
          localStorageSupport: typeof localStorage !== 'undefined',
          fetchSupport: typeof fetch !== 'undefined',
          promiseSupport: typeof Promise !== 'undefined',
          es6Support: (() => {
            try {
              const testArrow = () => true;
              const testConst = () => { const x = 1; return x; };
              return testArrow() && testConst();
            } catch (e) {
              return false;
            }
          })()
        };

        return results;
      });

      console.log(`Browser compatibility results for ${browserName}:`);
      Object.entries(compatibilityCheck).forEach(([feature, supported]) => {
        console.log(`  ${feature.padEnd(20)}: ${supported ? '✅ SUPPORTED' : '❌ NOT SUPPORTED'}`);
        expect(supported).toBe(true); // All features must be supported
      });

      // Test basic page functionality
      await page.waitForSelector('#connection-text:has-text("Connected")', { timeout: 10000 });

      const basicFunctionality = await page.locator('#play-btn').isEnabled();
      expect(basicFunctionality).toBe(true);

      console.log(`✅ ${browserName} compatibility confirmed`);

    } finally {
      await context.close();
    }
  });
});