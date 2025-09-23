/**
 * Stress Testing and Performance Validation Suite
 * Comprehensive testing under load and edge conditions
 */

import { test, expect } from '@playwright/test';

const STRESS_CONFIG = {
  frontendUrl: 'http://localhost:3000',
  backendUrl: 'http://localhost:8080',
  maxConcurrentGames: 5,
  stressTestDuration: 30000, // 30 seconds
  performanceThresholds: {
    connectionTime: 5000,    // 5s max connection time
    matchmakingTime: 15000,  // 15s max matchmaking time
    cardPlayResponse: 1000,  // 1s max card play response
    memoryUsage: 100,        // 100MB max memory usage
    cpuUsage: 80            // 80% max CPU usage
  }
};

test.describe('Stress Testing and Performance Validation', () => {

  test.beforeEach(async () => {
    test.setTimeout(120000); // Extended timeout for stress tests
  });

  test('High-load concurrent games stress test', async ({ browser }) => {
    console.log('🔥 Running high-load concurrent games stress test...');

    const gameCount = STRESS_CONFIG.maxConcurrentGames;
    const playerCount = gameCount * 2;
    const contexts = [];
    const pages = [];
    const metrics = {
      connectionsSuccessful: 0,
      matchmakingSuccessful: 0,
      gamesStarted: 0,
      errors: [],
      performanceTimes: []
    };

    try {
      console.log(`Creating ${playerCount} concurrent players for ${gameCount} games...`);

      // Create all browser contexts and pages
      for (let i = 0; i < playerCount; i++) {
        const context = await browser.newContext({
          viewport: { width: 1280, height: 720 }
        });
        const page = await context.newPage();
        contexts.push(context);
        pages.push(page);
      }

      // === Phase 1: Concurrent Connection Testing ===
      console.log('📡 Phase 1: Testing concurrent connections...');

      const connectionStart = Date.now();

      // All players navigate to the site simultaneously
      const navigationPromises = pages.map((page, index) =>
        page.goto(STRESS_CONFIG.frontendUrl)
          .then(() => {
            console.log(`Player ${index + 1} page loaded`);
            return true;
          })
          .catch(error => {
            console.error(`Player ${index + 1} navigation failed:`, error.message);
            metrics.errors.push(`Player ${index + 1} navigation: ${error.message}`);
            return false;
          })
      );

      const navigationResults = await Promise.all(navigationPromises);
      const successfulNavigations = navigationResults.filter(result => result).length;

      console.log(`${successfulNavigations}/${playerCount} players loaded successfully`);

      // Wait for WebSocket connections
      const connectionPromises = pages.map((page, index) =>
        page.waitForSelector('#connection-text:has-text("Connected")', { timeout: 10000 })
          .then(() => {
            metrics.connectionsSuccessful++;
            console.log(`Player ${index + 1} connected`);
            return true;
          })
          .catch(error => {
            console.error(`Player ${index + 1} connection failed:`, error.message);
            metrics.errors.push(`Player ${index + 1} connection: ${error.message}`);
            return false;
          })
      );

      const connectionResults = await Promise.all(connectionPromises);
      const connectionTime = Date.now() - connectionStart;

      console.log(`${metrics.connectionsSuccessful}/${playerCount} players connected in ${connectionTime}ms`);

      // Validate connection performance
      expect(metrics.connectionsSuccessful).toBeGreaterThanOrEqual(playerCount * 0.8); // At least 80% success
      expect(connectionTime).toBeLessThan(STRESS_CONFIG.performanceThresholds.connectionTime * 2); // Allow 2x normal time under load

      // === Phase 2: Concurrent Matchmaking Testing ===
      console.log('🎯 Phase 2: Testing concurrent matchmaking...');

      const matchmakingStart = Date.now();

      // All connected players join matchmaking simultaneously
      const connectedPages = pages.filter((_, index) => connectionResults[index]);

      const matchmakingPromises = connectedPages.map((page, index) =>
        page.click('#play-btn')
          .then(() => page.waitForSelector('#matchmaking-overlay', { state: 'visible', timeout: 5000 }))
          .then(() => {
            console.log(`Player ${index + 1} entered matchmaking`);
            return true;
          })
          .catch(error => {
            console.error(`Player ${index + 1} matchmaking entry failed:`, error.message);
            metrics.errors.push(`Player ${index + 1} matchmaking entry: ${error.message}`);
            return false;
          })
      );

      await Promise.all(matchmakingPromises);

      console.log('⏳ Waiting for matches to be found...');

      // Wait for matches to be found
      const matchFoundPromises = connectedPages.map((page, index) =>
        page.waitForSelector('#matchmaking-overlay', { state: 'hidden', timeout: 25000 })
          .then(() => {
            metrics.matchmakingSuccessful++;
            console.log(`Player ${index + 1} match found`);
            return true;
          })
          .catch(error => {
            console.error(`Player ${index + 1} match finding failed:`, error.message);
            metrics.errors.push(`Player ${index + 1} match finding: ${error.message}`);
            return false;
          })
      );

      const matchResults = await Promise.all(matchFoundPromises);
      const matchmakingTime = Date.now() - matchmakingStart;

      console.log(`${metrics.matchmakingSuccessful}/${connectedPages.length} players found matches in ${matchmakingTime}ms`);

      // Validate matchmaking performance
      expect(metrics.matchmakingSuccessful).toBeGreaterThanOrEqual(connectedPages.length * 0.6); // At least 60% success under load

      // === Phase 3: Game State Validation ===
      console.log('🎮 Phase 3: Validating game states...');

      const matchedPages = connectedPages.filter((_, index) => matchResults[index]);

      for (const page of matchedPages) {
        try {
          // Verify player is in game
          await page.waitForSelector('#leave-game-btn:enabled', { timeout: 5000 });

          // Check game status
          const gameStatus = await page.locator('#game-status').textContent();
          if (gameStatus && !gameStatus.includes('error')) {
            metrics.gamesStarted++;
          }

          // Check for Romanian Septica specific elements
          const playerCards = await page.locator('#player-cards .card').count();
          if (playerCards === 4) {
            console.log('✅ Romanian Septica setup confirmed (4 cards)');
          }

        } catch (error) {
          console.error('Game state validation error:', error.message);
          metrics.errors.push(`Game state validation: ${error.message}`);
        }
      }

      console.log(`${metrics.gamesStarted} games started successfully`);

      // === Phase 4: Performance Under Load Testing ===
      console.log('⚡ Phase 4: Performance testing under load...');

      // Test card interaction performance under load
      const performanceTests = matchedPages.slice(0, 2).map(async (page, index) => {
        try {
          const testStart = Date.now();

          // Simulate rapid card interactions
          for (let i = 0; i < 5; i++) {
            const cards = await page.locator('#player-cards .card').count();
            if (cards > 0) {
              await page.locator('#player-cards .card').first().hover();
              await page.waitForTimeout(50);
            }
          }

          const testTime = Date.now() - testStart;
          metrics.performanceTimes.push({
            player: index + 1,
            operation: 'card_interactions',
            time: testTime
          });

          console.log(`Player ${index + 1} performance test: ${testTime}ms`);

        } catch (error) {
          console.error(`Performance test failed for player ${index + 1}:`, error.message);
        }
      });

      await Promise.all(performanceTests);

      // === Phase 5: Memory and Resource Testing ===
      console.log('💾 Phase 5: Memory and resource testing...');

      const resourceMetrics = [];

      for (let i = 0; i < Math.min(matchedPages.length, 3); i++) {
        const page = matchedPages[i];
        try {
          const memory = await page.evaluate(() => {
            if (performance.memory) {
              return {
                used: performance.memory.usedJSHeapSize / 1024 / 1024, // MB
                total: performance.memory.totalJSHeapSize / 1024 / 1024, // MB
                limit: performance.memory.jsHeapSizeLimit / 1024 / 1024 // MB
              };
            }
            return null;
          });

          if (memory) {
            resourceMetrics.push({
              player: i + 1,
              memoryUsed: memory.used,
              memoryTotal: memory.total
            });

            console.log(`Player ${i + 1} memory: ${memory.used.toFixed(2)}MB used`);

            // Validate memory usage
            expect(memory.used).toBeLessThan(STRESS_CONFIG.performanceThresholds.memoryUsage);
          }

        } catch (error) {
          console.error(`Memory testing failed for player ${i + 1}:`, error.message);
        }
      }

      // === Final Results ===
      console.log('\n📊 STRESS TEST RESULTS:');
      console.log('='.repeat(50));
      console.log(`🔌 Connections: ${metrics.connectionsSuccessful}/${playerCount} (${Math.round(metrics.connectionsSuccessful/playerCount*100)}%)`);
      console.log(`🎯 Matchmaking: ${metrics.matchmakingSuccessful}/${connectedPages.length} (${Math.round(metrics.matchmakingSuccessful/connectedPages.length*100)}%)`);
      console.log(`🎮 Games Started: ${metrics.gamesStarted}`);
      console.log(`⚡ Connection Time: ${connectionTime}ms`);
      console.log(`⚡ Matchmaking Time: ${matchmakingTime}ms`);

      if (resourceMetrics.length > 0) {
        const avgMemory = resourceMetrics.reduce((sum, m) => sum + m.memoryUsed, 0) / resourceMetrics.length;
        console.log(`💾 Average Memory: ${avgMemory.toFixed(2)}MB`);
      }

      if (metrics.errors.length > 0) {
        console.log(`❌ Errors: ${metrics.errors.length}`);
        metrics.errors.slice(0, 5).forEach(error => console.log(`   ${error}`));
      }

      // Success criteria
      const successRate = metrics.connectionsSuccessful / playerCount;
      const matchingRate = metrics.matchmakingSuccessful / Math.max(connectedPages.length, 1);

      console.log('\n🏆 OVERALL ASSESSMENT:');
      if (successRate >= 0.8 && matchingRate >= 0.6) {
        console.log('🟢 EXCELLENT: System handles high load very well');
      } else if (successRate >= 0.6 && matchingRate >= 0.4) {
        console.log('🟡 GOOD: System handles moderate load acceptably');
      } else {
        console.log('🔴 NEEDS IMPROVEMENT: System struggles under load');
      }

      // Final assertions
      expect(successRate).toBeGreaterThanOrEqual(0.6); // At least 60% overall success
      expect(metrics.errors.length).toBeLessThan(playerCount); // Fewer errors than players

    } finally {
      // Cleanup all contexts
      console.log('\n🧹 Cleaning up test resources...');
      for (const context of contexts) {
        await context.close();
      }
      console.log('✅ Cleanup complete');
    }
  });

  test('Network resilience under varying conditions', async ({ browser }) => {
    console.log('🌐 Testing network resilience under varying conditions...');

    const context1 = await browser.newContext();
    const context2 = await browser.newContext();
    const player1 = await context1.newPage();
    const player2 = await context2.newPage();

    try {
      // Initial setup
      await Promise.all([
        player1.goto(STRESS_CONFIG.frontendUrl),
        player2.goto(STRESS_CONFIG.frontendUrl)
      ]);

      await Promise.all([
        player1.waitForSelector('#connection-text:has-text("Connected")'),
        player2.waitForSelector('#connection-text:has-text("Connected")')
      ]);

      console.log('✅ Initial connections established');

      // === Test 1: Intermittent connectivity ===
      console.log('📡 Test 1: Intermittent connectivity simulation...');

      await player1.click('#play-btn');
      await player2.click('#play-btn');

      // Start matchmaking
      await Promise.all([
        player1.waitForSelector('#matchmaking-overlay', { state: 'visible' }),
        player2.waitForSelector('#matchmaking-overlay', { state: 'visible' })
      ]);

      // Simulate brief network interruption during matchmaking
      await player1.context().setOffline(true);
      await player1.waitForTimeout(1000);
      await player1.context().setOffline(false);

      // Should still complete matchmaking
      await Promise.all([
        player1.waitForSelector('#matchmaking-overlay', { state: 'hidden', timeout: 20000 }),
        player2.waitForSelector('#matchmaking-overlay', { state: 'hidden', timeout: 20000 })
      ]);

      console.log('✅ Matchmaking completed despite network interruption');

      // === Test 2: Slow network conditions ===
      console.log('🐌 Test 2: Slow network conditions simulation...');

      // Simulate slow network
      await Promise.all([
        player1.context().route('**/*', route => {
          setTimeout(() => route.continue(), 200); // Add 200ms delay
        }),
        player2.context().route('**/*', route => {
          setTimeout(() => route.continue(), 200);
        })
      ]);

      // Test card interaction under slow network
      const slowNetworkStart = Date.now();

      if (await player1.locator('#player-cards .card').count() > 0) {
        await player1.locator('#player-cards .card').first().hover();
        const slowNetworkTime = Date.now() - slowNetworkStart;

        console.log(`Card interaction time under slow network: ${slowNetworkTime}ms`);
        expect(slowNetworkTime).toBeLessThan(5000); // Should still respond within 5s
      }

      // Clear network throttling
      await player1.context().unroute('**/*');
      await player2.context().unroute('**/*');

      console.log('✅ System functional under slow network conditions');

      // === Test 3: Recovery after extended offline period ===
      console.log('🔄 Test 3: Recovery after extended offline period...');

      // Both players go offline
      await Promise.all([
        player1.context().setOffline(true),
        player2.context().setOffline(true)
      ]);

      console.log('📴 Both players offline for 5 seconds...');
      await player1.waitForTimeout(5000);

      // Restore connectivity
      await Promise.all([
        player1.context().setOffline(false),
        player2.context().setOffline(false)
      ]);

      // Wait for reconnection
      await Promise.all([
        player1.waitForSelector('#connection-text:has-text("Connected")', { timeout: 15000 }),
        player2.waitForSelector('#connection-text:has-text("Connected")', { timeout: 15000 })
      ]);

      console.log('✅ Recovery after extended offline period successful');

      // === Test 4: Partial connectivity (one player offline) ===
      console.log('⚡ Test 4: Partial connectivity testing...');

      // Only player 1 goes offline
      await player1.context().setOffline(true);
      await player1.waitForTimeout(2000);

      // Player 2 should remain functional
      const player2Status = await player2.locator('#connection-text').textContent();
      expect(player2Status).toMatch(/connected/i);

      // Restore player 1
      await player1.context().setOffline(false);
      await player1.waitForSelector('#connection-text:has-text("Connected")', { timeout: 10000 });

      console.log('✅ Partial connectivity handled correctly');

      console.log('🏆 Network resilience testing completed successfully');

    } finally {
      await context1.close();
      await context2.close();
    }
  });

  test('Performance benchmarking under normal load', async ({ browser }) => {
    console.log('⚡ Running performance benchmarks under normal load...');

    const measurements = {
      pageLoad: [],
      connection: [],
      matchmaking: [],
      cardInteraction: [],
      memoryUsage: []
    };

    const iterations = 3;

    for (let i = 0; i < iterations; i++) {
      console.log(`\n📊 Benchmark iteration ${i + 1}/${iterations}`);

      const context1 = await browser.newContext();
      const context2 = await browser.newContext();
      const player1 = await context1.newPage();
      const player2 = await context2.newPage();

      try {
        // === Measure page load performance ===
        const loadStart = Date.now();

        await Promise.all([
          player1.goto(STRESS_CONFIG.frontendUrl),
          player2.goto(STRESS_CONFIG.frontendUrl)
        ]);

        await Promise.all([
          player1.waitForLoadState('domcontentloaded'),
          player2.waitForLoadState('domcontentloaded')
        ]);

        const loadTime = Date.now() - loadStart;
        measurements.pageLoad.push(loadTime);

        console.log(`  Page load: ${loadTime}ms`);

        // === Measure connection performance ===
        const connectionStart = Date.now();

        await Promise.all([
          player1.waitForSelector('#connection-text:has-text("Connected")'),
          player2.waitForSelector('#connection-text:has-text("Connected")')
        ]);

        const connectionTime = Date.now() - connectionStart;
        measurements.connection.push(connectionTime);

        console.log(`  Connection: ${connectionTime}ms`);

        // === Measure matchmaking performance ===
        const matchmakingStart = Date.now();

        await player1.click('#play-btn');
        await player2.click('#play-btn');

        await Promise.all([
          player1.waitForSelector('#matchmaking-overlay', { state: 'hidden', timeout: 20000 }),
          player2.waitForSelector('#matchmaking-overlay', { state: 'hidden', timeout: 20000 })
        ]);

        const matchmakingTime = Date.now() - matchmakingStart;
        measurements.matchmaking.push(matchmakingTime);

        console.log(`  Matchmaking: ${matchmakingTime}ms`);

        // === Measure card interaction performance ===
        const cardCount = await player1.locator('#player-cards .card').count();

        if (cardCount > 0) {
          const interactionStart = Date.now();

          await player1.locator('#player-cards .card').first().hover();
          await player1.waitForTimeout(100);

          const interactionTime = Date.now() - interactionStart;
          measurements.cardInteraction.push(interactionTime);

          console.log(`  Card interaction: ${interactionTime}ms`);
        }

        // === Measure memory usage ===
        const memory = await player1.evaluate(() => {
          if (performance.memory) {
            return performance.memory.usedJSHeapSize / 1024 / 1024; // MB
          }
          return null;
        });

        if (memory !== null) {
          measurements.memoryUsage.push(memory);
          console.log(`  Memory usage: ${memory.toFixed(2)}MB`);
        }

      } finally {
        await context1.close();
        await context2.close();
      }
    }

    // === Calculate and validate averages ===
    console.log('\n📈 PERFORMANCE BENCHMARK RESULTS:');
    console.log('='.repeat(50));

    function calculateStats(values) {
      if (values.length === 0) return { avg: 0, min: 0, max: 0 };
      const avg = values.reduce((sum, val) => sum + val, 0) / values.length;
      const min = Math.min(...values);
      const max = Math.max(...values);
      return { avg, min, max };
    }

    const stats = {
      pageLoad: calculateStats(measurements.pageLoad),
      connection: calculateStats(measurements.connection),
      matchmaking: calculateStats(measurements.matchmaking),
      cardInteraction: calculateStats(measurements.cardInteraction),
      memoryUsage: calculateStats(measurements.memoryUsage)
    };

    Object.entries(stats).forEach(([metric, data]) => {
      if (data.avg > 0) {
        console.log(`${metric.padEnd(15)}: Avg=${Math.round(data.avg)}ms, Min=${Math.round(data.min)}ms, Max=${Math.round(data.max)}ms`);
      }
    });

    // === Performance assertions ===
    console.log('\n✅ PERFORMANCE VALIDATION:');

    if (stats.pageLoad.avg > 0) {
      expect(stats.pageLoad.avg).toBeLessThan(STRESS_CONFIG.performanceThresholds.connectionTime);
      console.log(`  Page load: ${stats.pageLoad.avg < 3000 ? '🟢 EXCELLENT' : stats.pageLoad.avg < 5000 ? '🟡 GOOD' : '🔴 SLOW'}`);
    }

    if (stats.connection.avg > 0) {
      expect(stats.connection.avg).toBeLessThan(STRESS_CONFIG.performanceThresholds.connectionTime);
      console.log(`  Connection: ${stats.connection.avg < 2000 ? '🟢 EXCELLENT' : stats.connection.avg < 5000 ? '🟡 GOOD' : '🔴 SLOW'}`);
    }

    if (stats.matchmaking.avg > 0) {
      expect(stats.matchmaking.avg).toBeLessThan(STRESS_CONFIG.performanceThresholds.matchmakingTime);
      console.log(`  Matchmaking: ${stats.matchmaking.avg < 5000 ? '🟢 EXCELLENT' : stats.matchmaking.avg < 15000 ? '🟡 GOOD' : '🔴 SLOW'}`);
    }

    if (stats.cardInteraction.avg > 0) {
      expect(stats.cardInteraction.avg).toBeLessThan(STRESS_CONFIG.performanceThresholds.cardPlayResponse);
      console.log(`  Card interaction: ${stats.cardInteraction.avg < 100 ? '🟢 EXCELLENT' : stats.cardInteraction.avg < 500 ? '🟡 GOOD' : '🔴 SLOW'}`);
    }

    if (stats.memoryUsage.avg > 0) {
      expect(stats.memoryUsage.avg).toBeLessThan(STRESS_CONFIG.performanceThresholds.memoryUsage);
      console.log(`  Memory usage: ${stats.memoryUsage.avg < 50 ? '🟢 EXCELLENT' : stats.memoryUsage.avg < 100 ? '🟡 GOOD' : '🔴 HIGH'}`);
    }

    console.log('\n🏆 Performance benchmarking completed successfully');
  });

  test('Long-duration stability testing', async ({ browser }) => {
    console.log('⏱️ Running long-duration stability test...');

    const testDuration = 60000; // 1 minute for demo (would be longer in real scenario)
    const checkInterval = 5000;  // Check every 5 seconds
    const startTime = Date.now();

    const context1 = await browser.newContext();
    const context2 = await browser.newContext();
    const player1 = await context1.newPage();
    const player2 = await context2.newPage();

    const stabilityMetrics = {
      checks: 0,
      successfulChecks: 0,
      errors: [],
      memorySnapshots: [],
      connectionDrops: 0
    };

    try {
      // Initial setup
      await Promise.all([
        player1.goto(STRESS_CONFIG.frontendUrl),
        player2.goto(STRESS_CONFIG.frontendUrl)
      ]);

      await Promise.all([
        player1.waitForSelector('#connection-text:has-text("Connected")'),
        player2.waitForSelector('#connection-text:has-text("Connected")')
      ]);

      // Start game
      await player1.click('#play-btn');
      await player2.click('#play-btn');

      await Promise.all([
        player1.waitForSelector('#matchmaking-overlay', { state: 'hidden', timeout: 20000 }),
        player2.waitForSelector('#matchmaking-overlay', { state: 'hidden', timeout: 20000 })
      ]);

      console.log('✅ Stability test setup complete, starting monitoring...');

      // Long-duration monitoring loop
      while (Date.now() - startTime < testDuration) {
        stabilityMetrics.checks++;

        try {
          // Check connection status
          const status1 = await player1.locator('#connection-text').textContent();
          const status2 = await player2.locator('#connection-text').textContent();

          const connected1 = status1.includes('Connected');
          const connected2 = status2.includes('Connected');

          if (!connected1 || !connected2) {
            stabilityMetrics.connectionDrops++;
            console.log(`⚠️ Connection drop detected at ${Date.now() - startTime}ms`);
          }

          // Check game state consistency
          const trick1 = await player1.locator('#trick-number').textContent();
          const trick2 = await player2.locator('#trick-number').textContent();

          if (trick1 !== trick2) {
            stabilityMetrics.errors.push(`State inconsistency at ${Date.now() - startTime}ms`);
          }

          // Check memory usage
          const memory = await player1.evaluate(() => {
            if (performance.memory) {
              return performance.memory.usedJSHeapSize / 1024 / 1024;
            }
            return null;
          });

          if (memory !== null) {
            stabilityMetrics.memorySnapshots.push({
              time: Date.now() - startTime,
              memory: memory
            });
          }

          // Simulate light user activity
          if (Math.random() < 0.3) { // 30% chance per check
            const cards = await player1.locator('#player-cards .card').count();
            if (cards > 0) {
              await player1.locator('#player-cards .card').first().hover();
            }
          }

          stabilityMetrics.successfulChecks++;

        } catch (error) {
          stabilityMetrics.errors.push(`Check error at ${Date.now() - startTime}ms: ${error.message}`);
        }

        // Wait before next check
        await player1.waitForTimeout(checkInterval);
      }

      // === Analyze stability results ===
      console.log('\n📊 STABILITY TEST RESULTS:');
      console.log('='.repeat(50));
      console.log(`Duration: ${testDuration / 1000}s`);
      console.log(`Checks performed: ${stabilityMetrics.checks}`);
      console.log(`Successful checks: ${stabilityMetrics.successfulChecks}/${stabilityMetrics.checks} (${Math.round(stabilityMetrics.successfulChecks/stabilityMetrics.checks*100)}%)`);
      console.log(`Connection drops: ${stabilityMetrics.connectionDrops}`);
      console.log(`Errors: ${stabilityMetrics.errors.length}`);

      if (stabilityMetrics.memorySnapshots.length > 0) {
        const initialMemory = stabilityMetrics.memorySnapshots[0].memory;
        const finalMemory = stabilityMetrics.memorySnapshots[stabilityMetrics.memorySnapshots.length - 1].memory;
        const memoryIncrease = finalMemory - initialMemory;

        console.log(`Memory: ${initialMemory.toFixed(2)}MB → ${finalMemory.toFixed(2)}MB (${memoryIncrease > 0 ? '+' : ''}${memoryIncrease.toFixed(2)}MB)`);

        // Check for memory leaks
        expect(memoryIncrease).toBeLessThan(20); // Memory increase should be less than 20MB
      }

      // Stability assertions
      const stabilityRate = stabilityMetrics.successfulChecks / stabilityMetrics.checks;
      expect(stabilityRate).toBeGreaterThanOrEqual(0.9); // At least 90% stability
      expect(stabilityMetrics.connectionDrops).toBeLessThan(3); // Fewer than 3 connection drops

      if (stabilityMetrics.errors.length > 0) {
        console.log('\nFirst few errors:');
        stabilityMetrics.errors.slice(0, 3).forEach(error => console.log(`  ${error}`));
      }

      console.log(`\n${stabilityRate >= 0.95 ? '🟢 EXCELLENT' : stabilityRate >= 0.9 ? '🟡 GOOD' : '🔴 UNSTABLE'} stability`);

    } finally {
      await context1.close();
      await context2.close();
    }
  });
});