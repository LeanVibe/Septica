/**
 * Performance and Load Testing Suite
 * Comprehensive performance validation and load testing for Romanian Septica
 */

import { test, expect } from '@playwright/test';

const PERFORMANCE_CONFIG = {
  servers: {
    frontend: 'http://localhost:3000',
    backend: 'http://localhost:8082'
  },
  targets: {
    pageLoad: 3000,      // Page load under 3 seconds
    wsConnection: 2000,  // WebSocket connection under 2 seconds
    matchmaking: 10000,  // Matchmaking under 10 seconds
    cardPlay: 200,       // Card play response under 200ms
    memoryLimit: 100,    // Memory usage under 100MB
    concurrentUsers: 8   // Support for 8 concurrent users
  },
  loadTest: {
    rampUpTime: 5000,    // 5 seconds to reach max load
    sustainTime: 10000,   // Sustain load for 10 seconds
    rampDownTime: 3000   // 3 seconds to ramp down
  }
};

test.describe('Performance Benchmarking and Optimization', () => {

  test('Page load performance and optimization', async ({ page }) => {
    console.log('⚡ Testing page load performance and optimization...');

    // Measure complete page load cycle
    const performanceMetrics = await page.evaluate(() => {
      return new Promise((resolve) => {
        const observer = new PerformanceObserver((list) => {
          const entries = list.getEntries();
          const navigationEntry = entries.find(entry => entry.entryType === 'navigation');

          if (navigationEntry) {
            const metrics = {
              dns: navigationEntry.domainLookupEnd - navigationEntry.domainLookupStart,
              tcp: navigationEntry.connectEnd - navigationEntry.connectStart,
              request: navigationEntry.responseStart - navigationEntry.requestStart,
              response: navigationEntry.responseEnd - navigationEntry.responseStart,
              domParsing: navigationEntry.domContentLoadedEventStart - navigationEntry.responseEnd,
              totalLoad: navigationEntry.loadEventEnd - navigationEntry.loadEventStart
            };
            resolve(metrics);
          }
        });

        observer.observe({ entryTypes: ['navigation'] });

        // Fallback timeout
        setTimeout(() => resolve(null), 5000);
      });
    });

    const startTime = Date.now();
    await page.goto(PERFORMANCE_CONFIG.servers.frontend);
    const totalLoadTime = Date.now() - startTime;

    // Validate load time
    expect(totalLoadTime).toBeLessThan(PERFORMANCE_CONFIG.targets.pageLoad);
    console.log(`✅ Page load time: ${totalLoadTime}ms (target: <${PERFORMANCE_CONFIG.targets.pageLoad}ms)`);

    if (performanceMetrics) {
      console.log(`  DNS lookup: ${performanceMetrics.dns}ms`);
      console.log(`  TCP connection: ${performanceMetrics.tcp}ms`);
      console.log(`  Request time: ${performanceMetrics.request}ms`);
      console.log(`  Response time: ${performanceMetrics.response}ms`);
      console.log(`  DOM parsing: ${performanceMetrics.domParsing}ms`);
    }

    // Test resource loading
    const resourceMetrics = await page.evaluate(() => {
      const resources = performance.getEntriesByType('resource');
      const analysis = {
        totalResources: resources.length,
        slowResources: resources.filter(r => r.duration > 1000).length,
        cachedResources: resources.filter(r => r.transferSize === 0).length,
        avgLoadTime: resources.reduce((sum, r) => sum + r.duration, 0) / resources.length
      };
      return analysis;
    });

    console.log(`✅ Resource analysis: ${resourceMetrics.totalResources} total, ${resourceMetrics.slowResources} slow, ${resourceMetrics.cachedResources} cached`);
    console.log(`  Average resource load time: ${resourceMetrics.avgLoadTime.toFixed(2)}ms`);

    // Test critical rendering path
    const renderingMetrics = await page.evaluate(() => {
      const paint = performance.getEntriesByType('paint');
      const firstPaint = paint.find(entry => entry.name === 'first-paint');
      const firstContentfulPaint = paint.find(entry => entry.name === 'first-contentful-paint');

      return {
        firstPaint: firstPaint ? firstPaint.startTime : 0,
        firstContentfulPaint: firstContentfulPaint ? firstContentfulPaint.startTime : 0,
        domInteractive: performance.timing ?
          performance.timing.domInteractive - performance.timing.navigationStart : 0
      };
    });

    if (renderingMetrics.firstContentfulPaint > 0) {
      expect(renderingMetrics.firstContentfulPaint).toBeLessThan(2000); // FCP under 2s
      console.log(`✅ First Contentful Paint: ${renderingMetrics.firstContentfulPaint.toFixed(2)}ms`);
    }
  });

  test('WebSocket connection performance and reliability', async ({ page }) => {
    console.log('🔌 Testing WebSocket connection performance...');

    await page.goto(PERFORMANCE_CONFIG.servers.frontend);

    // Measure WebSocket connection time
    const wsConnectionMetrics = await page.evaluate(async () => {
      return new Promise((resolve) => {
        const startTime = performance.now();
        const ws = new WebSocket('ws://localhost:8082/ws/connect?user_id=perf-test-ws');

        const timeout = setTimeout(() => {
          ws.close();
          resolve({
            success: false,
            connectionTime: performance.now() - startTime,
            error: 'timeout'
          });
        }, 10000);

        ws.onopen = () => {
          clearTimeout(timeout);
          const connectionTime = performance.now() - startTime;

          // Test message round-trip
          const messageStart = performance.now();
          ws.send(JSON.stringify({ type: 'ping', timestamp: Date.now() }));

          ws.onmessage = (event) => {
            const messageTime = performance.now() - messageStart;
            ws.close();
            resolve({
              success: true,
              connectionTime,
              messageRoundTrip: messageTime
            });
          };
        };

        ws.onerror = () => {
          clearTimeout(timeout);
          resolve({
            success: false,
            connectionTime: performance.now() - startTime,
            error: 'connection_failed'
          });
        };
      });
    });

    expect(wsConnectionMetrics.success).toBe(true);
    expect(wsConnectionMetrics.connectionTime).toBeLessThan(PERFORMANCE_CONFIG.targets.wsConnection);

    console.log(`✅ WebSocket connection time: ${wsConnectionMetrics.connectionTime.toFixed(2)}ms`);
    if (wsConnectionMetrics.messageRoundTrip) {
      console.log(`✅ Message round-trip time: ${wsConnectionMetrics.messageRoundTrip.toFixed(2)}ms`);
    }

    // Test connection stability under load
    const stabilityTest = await page.evaluate(async () => {
      const connections = [];
      const results = [];

      // Create multiple WebSocket connections
      for (let i = 0; i < 5; i++) {
        const ws = new WebSocket(`ws://localhost:8082/ws/connect?user_id=stability-test-${i}`);
        connections.push(ws);

        const connectionPromise = new Promise((resolve) => {
          const startTime = performance.now();

          ws.onopen = () => {
            resolve({
              id: i,
              success: true,
              time: performance.now() - startTime
            });
          };

          ws.onerror = () => {
            resolve({
              id: i,
              success: false,
              time: performance.now() - startTime
            });
          };

          setTimeout(() => resolve({
            id: i,
            success: false,
            time: performance.now() - startTime,
            error: 'timeout'
          }), 5000);
        });

        results.push(connectionPromise);
      }

      const connectionResults = await Promise.all(results);

      // Cleanup connections
      connections.forEach(ws => {
        if (ws.readyState === WebSocket.OPEN) {
          ws.close();
        }
      });

      return connectionResults;
    });

    const successfulConnections = stabilityTest.filter(result => result.success).length;
    const avgConnectionTime = stabilityTest.reduce((sum, result) => sum + result.time, 0) / stabilityTest.length;

    expect(successfulConnections).toBeGreaterThanOrEqual(4); // At least 80% success rate
    console.log(`✅ Connection stability: ${successfulConnections}/5 successful (avg: ${avgConnectionTime.toFixed(2)}ms)`);
  });

  test('Matchmaking performance under load', async ({ browser }) => {
    console.log('🎯 Testing matchmaking performance under load...');

    const contexts = [];
    const pages = [];

    try {
      // Create multiple player contexts
      for (let i = 0; i < 6; i++) {
        const context = await browser.newContext();
        const page = await context.newPage();
        contexts.push(context);
        pages.push(page);
      }

      // All players load the application
      const loadStartTime = Date.now();
      await Promise.all(pages.map(page => page.goto(PERFORMANCE_CONFIG.servers.frontend)));
      const loadTime = Date.now() - loadStartTime;

      console.log(`✅ ${pages.length} players loaded in ${loadTime}ms`);

      // All players establish connections
      await Promise.all(pages.map(page =>
        page.waitForSelector('#connection-text:has-text("Connected")', { timeout: 10000 })
      ));

      console.log(`✅ All ${pages.length} players connected`);

      // Staggered matchmaking entry (more realistic)
      const matchmakingResults = [];
      const matchmakingStartTime = Date.now();

      for (let i = 0; i < pages.length; i += 2) {
        // Launch pairs with slight delay
        const player1 = pages[i];
        const player2 = pages[i + 1];

        if (player2) {
          const pairStartTime = Date.now();

          await player1.click('#play-btn');
          await player1.waitForTimeout(200); // Realistic user delay
          await player2.click('#play-btn');

          // Wait for both to find match
          try {
            await Promise.all([
              player1.waitForSelector('#matchmaking-overlay', { state: 'hidden', timeout: 15000 }),
              player2.waitForSelector('#matchmaking-overlay', { state: 'hidden', timeout: 15000 })
            ]);

            const pairTime = Date.now() - pairStartTime;
            matchmakingResults.push({
              pair: Math.floor(i / 2) + 1,
              success: true,
              time: pairTime
            });

            console.log(`✅ Pair ${Math.floor(i / 2) + 1} matched in ${pairTime}ms`);

          } catch (error) {
            matchmakingResults.push({
              pair: Math.floor(i / 2) + 1,
              success: false,
              error: 'timeout'
            });
          }

          // Brief pause between pair launches
          await pages[0].waitForTimeout(500);
        }
      }

      const totalMatchmakingTime = Date.now() - matchmakingStartTime;
      const successfulMatches = matchmakingResults.filter(result => result.success).length;
      const avgMatchTime = matchmakingResults
        .filter(result => result.success)
        .reduce((sum, result) => sum + result.time, 0) / (successfulMatches || 1);

      expect(successfulMatches).toBeGreaterThanOrEqual(2); // At least 2 pairs should match
      console.log(`✅ Matchmaking load test: ${successfulMatches}/3 pairs matched`);
      console.log(`  Total time: ${totalMatchmakingTime}ms, Average pair time: ${avgMatchTime.toFixed(2)}ms`);

    } finally {
      // Cleanup all contexts
      for (const context of contexts) {
        await context.close();
      }
    }
  });

  test('Memory usage and resource management', async ({ page }) => {
    console.log('💾 Testing memory usage and resource management...');

    await page.goto(PERFORMANCE_CONFIG.servers.frontend);
    await page.waitForSelector('#connection-text:has-text("Connected")');

    // Baseline memory measurement
    const baselineMemory = await page.evaluate(() => {
      if (performance.memory) {
        return {
          used: performance.memory.usedJSHeapSize,
          total: performance.memory.totalJSHeapSize,
          limit: performance.memory.jsHeapSizeLimit
        };
      }
      return null;
    });

    if (!baselineMemory) {
      console.log('⚠️ Memory API not available, skipping memory tests');
      return;
    }

    console.log(`📊 Baseline memory: ${Math.round(baselineMemory.used / 1024 / 1024)}MB used`);

    // Intensive operations simulation
    await page.evaluate(() => {
      // Simulate game operations that might cause memory growth
      const operations = [];

      // Create mock game data
      for (let i = 0; i < 1000; i++) {
        operations.push({
          id: i,
          type: 'card_play',
          data: {
            card: { value: 7 + (i % 8), suit: ['hearts', 'diamonds', 'clubs', 'spades'][i % 4] },
            timestamp: Date.now() + i,
            player: `player_${i % 2}`,
            gameState: new Array(32).fill(null).map((_, idx) => ({
              value: 7 + (idx % 8),
              suit: ['hearts', 'diamonds', 'clubs', 'spades'][Math.floor(idx / 8)]
            }))
          }
        });
      }

      // Store in memory temporarily
      window.testOperations = operations;

      // Simulate DOM manipulations
      for (let i = 0; i < 100; i++) {
        const element = document.createElement('div');
        element.innerHTML = `<span>Test ${i}</span>`;
        element.className = 'performance-test-element';
        document.body.appendChild(element);
      }

      return operations.length;
    });

    // Memory after intensive operations
    const postOperationsMemory = await page.evaluate(() => {
      if (performance.memory) {
        return {
          used: performance.memory.usedJSHeapSize,
          total: performance.memory.totalJSHeapSize,
          limit: performance.memory.jsHeapSizeLimit
        };
      }
      return null;
    });

    const memoryIncrease = postOperationsMemory.used - baselineMemory.used;
    const memoryIncreaseMB = memoryIncrease / 1024 / 1024;

    console.log(`📊 Memory after operations: ${Math.round(postOperationsMemory.used / 1024 / 1024)}MB (+${memoryIncreaseMB.toFixed(2)}MB)`);

    // Cleanup operations
    await page.evaluate(() => {
      // Remove test data
      delete window.testOperations;

      // Remove test DOM elements
      const testElements = document.querySelectorAll('.performance-test-element');
      testElements.forEach(element => element.remove());

      // Force garbage collection if available
      if (window.gc) {
        window.gc();
      }
    });

    // Memory after cleanup
    await page.waitForTimeout(1000); // Allow GC time

    const postCleanupMemory = await page.evaluate(() => {
      if (performance.memory) {
        return {
          used: performance.memory.usedJSHeapSize,
          total: performance.memory.totalJSHeapSize,
          limit: performance.memory.jsHeapSizeLimit
        };
      }
      return null;
    });

    const finalMemoryMB = postCleanupMemory.used / 1024 / 1024;
    const memoryRecovered = (postOperationsMemory.used - postCleanupMemory.used) / 1024 / 1024;

    expect(finalMemoryMB).toBeLessThan(PERFORMANCE_CONFIG.targets.memoryLimit);
    console.log(`📊 Memory after cleanup: ${Math.round(finalMemoryMB)}MB (-${memoryRecovered.toFixed(2)}MB recovered)`);
    console.log(`✅ Memory management: Within ${PERFORMANCE_CONFIG.targets.memoryLimit}MB limit`);
  });

  test('Card play response time optimization', async ({ browser }) => {
    console.log('🃏 Testing card play response time optimization...');

    const context1 = await browser.newContext();
    const context2 = await browser.newContext();
    const player1 = await context1.newPage();
    const player2 = await context2.newPage();

    try {
      // Setup matched game
      await Promise.all([
        player1.goto(PERFORMANCE_CONFIG.servers.frontend),
        player2.goto(PERFORMANCE_CONFIG.servers.frontend)
      ]);

      await Promise.all([
        player1.waitForSelector('#connection-text:has-text("Connected")'),
        player2.waitForSelector('#connection-text:has-text("Connected")')
      ]);

      await player1.click('#play-btn');
      await player2.click('#play-btn');

      await Promise.all([
        player1.waitForSelector('#matchmaking-overlay', { state: 'hidden' }),
        player2.waitForSelector('#matchmaking-overlay', { state: 'hidden' })
      ]);

      console.log('✅ Game setup complete, testing card play performance...');

      // Test card interaction response times
      const interactionMetrics = await Promise.all([
        player1.evaluate(() => {
          const metrics = [];
          const cards = document.querySelectorAll('#player-cards .card');

          if (cards.length > 0) {
            // Test hover response
            for (let i = 0; i < Math.min(3, cards.length); i++) {
              const startTime = performance.now();
              cards[i].dispatchEvent(new MouseEvent('mouseenter', { bubbles: true }));
              const hoverTime = performance.now() - startTime;
              metrics.push({ action: 'hover', time: hoverTime, cardIndex: i });

              // Test click response
              const clickStart = performance.now();
              cards[i].dispatchEvent(new MouseEvent('click', { bubbles: true }));
              const clickTime = performance.now() - clickStart;
              metrics.push({ action: 'click', time: clickTime, cardIndex: i });
            }
          }

          return metrics;
        }),

        player2.evaluate(() => {
          const metrics = [];
          const cards = document.querySelectorAll('#player-cards .card');

          if (cards.length > 0) {
            // Test hover response
            for (let i = 0; i < Math.min(3, cards.length); i++) {
              const startTime = performance.now();
              cards[i].dispatchEvent(new MouseEvent('mouseenter', { bubbles: true }));
              const hoverTime = performance.now() - startTime;
              metrics.push({ action: 'hover', time: hoverTime, cardIndex: i });
            }
          }

          return metrics;
        })
      ]);

      const allMetrics = [...interactionMetrics[0], ...interactionMetrics[1]];

      if (allMetrics.length > 0) {
        const avgHoverTime = allMetrics
          .filter(m => m.action === 'hover')
          .reduce((sum, m) => sum + m.time, 0) / allMetrics.filter(m => m.action === 'hover').length;

        const avgClickTime = allMetrics
          .filter(m => m.action === 'click')
          .reduce((sum, m) => sum + m.time, 0) / allMetrics.filter(m => m.action === 'click').length;

        expect(avgHoverTime).toBeLessThan(50); // Hover should be instant
        expect(avgClickTime).toBeLessThan(PERFORMANCE_CONFIG.targets.cardPlay);

        console.log(`✅ Card interaction performance: Hover ${avgHoverTime.toFixed(2)}ms, Click ${avgClickTime.toFixed(2)}ms`);
      } else {
        console.log('⚠️ No cards available for interaction testing');
      }

      // Test move processing performance
      const currentPlayer = await player1.locator('#game-status').textContent().then(status =>
        status.includes('Your turn') ? player1 : player2
      );

      const playableCards = await currentPlayer.locator('#player-cards .card.playable').count();

      if (playableCards > 0) {
        const moveStartTime = Date.now();
        await currentPlayer.locator('#player-cards .card.playable').first().click();
        await currentPlayer.waitForTimeout(500); // Allow processing time

        const moveProcessingTime = Date.now() - moveStartTime;
        console.log(`✅ Move processing time: ${moveProcessingTime}ms`);

        // Should be responsive but allow for network latency
        expect(moveProcessingTime).toBeLessThan(3000); // 3 seconds max for move processing
      }

    } finally {
      await context1.close();
      await context2.close();
    }
  });

  test('Stress test with maximum concurrent users', async ({ browser }) => {
    console.log('🔥 Stress testing with maximum concurrent users...');

    const maxUsers = PERFORMANCE_CONFIG.targets.concurrentUsers;
    const contexts = [];
    const pages = [];
    const results = {
      connectionSuccess: 0,
      matchmakingSuccess: 0,
      totalTime: 0
    };

    try {
      const stressTestStart = Date.now();

      // Ramp up users gradually
      console.log(`🚀 Ramping up ${maxUsers} concurrent users...`);

      for (let i = 0; i < maxUsers; i++) {
        const context = await browser.newContext();
        const page = await context.newPage();
        contexts.push(context);
        pages.push(page);

        // Staggered launch to simulate realistic load
        await page.goto(PERFORMANCE_CONFIG.servers.frontend);

        // Small delay between user connections
        if (i < maxUsers - 1) {
          await page.waitForTimeout(100);
        }
      }

      console.log(`✅ ${pages.length} users created`);

      // Test concurrent connections
      const connectionPromises = pages.map((page, index) =>
        page.waitForSelector('#connection-text:has-text("Connected")', { timeout: 15000 })
          .then(() => ({ index, success: true }))
          .catch(() => ({ index, success: false }))
      );

      const connectionResults = await Promise.all(connectionPromises);
      results.connectionSuccess = connectionResults.filter(result => result.success).length;

      console.log(`✅ Connections: ${results.connectionSuccess}/${pages.length} successful`);

      // Test concurrent matchmaking (pair users)
      const matchmakingPromises = [];
      for (let i = 0; i < pages.length - 1; i += 2) {
        const player1 = pages[i];
        const player2 = pages[i + 1];

        const matchPromise = Promise.all([
          player1.click('#play-btn'),
          player2.click('#play-btn')
        ]).then(() =>
          Promise.all([
            player1.waitForSelector('#matchmaking-overlay', { state: 'hidden', timeout: 20000 }),
            player2.waitForSelector('#matchmaking-overlay', { state: 'hidden', timeout: 20000 })
          ])
        ).then(() => ({ pair: Math.floor(i / 2), success: true }))
          .catch(() => ({ pair: Math.floor(i / 2), success: false }));

        matchmakingPromises.push(matchPromise);
      }

      if (matchmakingPromises.length > 0) {
        const matchResults = await Promise.all(matchmakingPromises);
        results.matchmakingSuccess = matchResults.filter(result => result.success).length;
        console.log(`✅ Matchmaking: ${results.matchmakingSuccess}/${matchmakingPromises.length} pairs matched`);
      }

      results.totalTime = Date.now() - stressTestStart;

      // Performance validation
      expect(results.connectionSuccess / pages.length).toBeGreaterThanOrEqual(0.8); // 80% connection success
      expect(results.totalTime).toBeLessThan(30000); // Complete test under 30 seconds

      console.log('🎯 Stress test summary:');
      console.log(`  Total users: ${pages.length}`);
      console.log(`  Connection success rate: ${((results.connectionSuccess / pages.length) * 100).toFixed(1)}%`);
      console.log(`  Matchmaking success rate: ${matchmakingPromises.length > 0 ? ((results.matchmakingSuccess / matchmakingPromises.length) * 100).toFixed(1) : 'N/A'}%`);
      console.log(`  Total test time: ${results.totalTime}ms`);

    } finally {
      // Cleanup all contexts
      console.log('🧹 Cleaning up stress test contexts...');
      for (const context of contexts) {
        await context.close();
      }
    }
  });
});