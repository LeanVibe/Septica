/**
 * Performance Benchmark Tests
 * Validates system performance meets production requirements
 */

import { test, expect } from '@playwright/test';

test.describe('Romanian Septica Performance Benchmarks', () => {
  
  test.beforeEach(async () => {
    test.setTimeout(60000);
  });

  test('WebSocket connection performance', async ({ page }) => {
    console.log('⚡ Testing WebSocket connection performance...');
    
    await page.goto('http://localhost:3000');
    
    // Measure WebSocket connection time
    const connectionBenchmark = await page.evaluate(async () => {
      const measurements = [];
      
      // Test multiple connection attempts
      for (let i = 0; i < 5; i++) {
        const startTime = performance.now();
        
        try {
          const ws = await new Promise((resolve, reject) => {
            const websocket = new WebSocket(`ws://localhost:8080/ws/connect?user_id=perf-test-${i}`);
            
            const timeout = setTimeout(() => {
              websocket.close();
              reject(new Error('Connection timeout'));
            }, 5000);
            
            websocket.onopen = () => {
              clearTimeout(timeout);
              resolve(websocket);
            };
            
            websocket.onerror = (error) => {
              clearTimeout(timeout);
              reject(error);
            };
          });
          
          const connectionTime = performance.now() - startTime;
          ws.close();
          
          measurements.push({
            attempt: i + 1,
            connectionTime: connectionTime,
            success: true
          });
          
          // Small delay between attempts
          await new Promise(resolve => setTimeout(resolve, 100));
          
        } catch (error) {
          measurements.push({
            attempt: i + 1,
            connectionTime: performance.now() - startTime,
            success: false,
            error: error.message
          });
        }
      }
      
      return measurements;
    });
    
    // Analyze results
    const successfulConnections = connectionBenchmark.filter(m => m.success);
    const avgConnectionTime = successfulConnections.reduce((sum, m) => sum + m.connectionTime, 0) / successfulConnections.length;
    const maxConnectionTime = Math.max(...successfulConnections.map(m => m.connectionTime));
    const minConnectionTime = Math.min(...successfulConnections.map(m => m.connectionTime));
    
    console.log(`📊 WebSocket Connection Performance:`);
    console.log(`  Successful connections: ${successfulConnections.length}/5`);
    console.log(`  Average time: ${avgConnectionTime.toFixed(1)}ms`);
    console.log(`  Min time: ${minConnectionTime.toFixed(1)}ms`);
    console.log(`  Max time: ${maxConnectionTime.toFixed(1)}ms`);
    
    // Performance assertions
    expect(successfulConnections.length).toBeGreaterThanOrEqual(4); // At least 80% success
    expect(avgConnectionTime).toBeLessThan(500); // Average < 500ms
    expect(maxConnectionTime).toBeLessThan(1000); // Max < 1s
    
    console.log('✅ WebSocket connection performance validated');
  });

  test('Matchmaking speed benchmarks', async ({ browser }) => {
    console.log('🎯 Testing matchmaking speed performance...');
    
    const matchmakingBenchmarks = [];
    
    // Run 3 matchmaking speed tests
    for (let iteration = 0; iteration < 3; iteration++) {
      const context1 = await browser.newContext();
      const context2 = await browser.newContext();
      const player1Page = await context1.newPage();
      const player2Page = await context2.newPage();
      
      try {
        console.log(`  Iteration ${iteration + 1}/3`);
        
        const totalStartTime = Date.now();
        
        // Load pages
        const loadStart = Date.now();
        await Promise.all([
          player1Page.goto('http://localhost:3000'),
          player2Page.goto('http://localhost:3000')
        ]);
        const pageLoadTime = Date.now() - loadStart;
        
        // Wait for connections
        const connectionStart = Date.now();
        await Promise.all([
          player1Page.waitForSelector('#connection-text:has-text("Connected")', { timeout: 10000 }),
          player2Page.waitForSelector('#connection-text:has-text("Connected")', { timeout: 10000 })
        ]);
        const connectionTime = Date.now() - connectionStart;
        
        // Start matchmaking
        const matchmakingStart = Date.now();
        await player1Page.click('#play-btn');
        await player2Page.click('#play-btn');
        
        // Wait for matchmaking completion
        await Promise.all([
          player1Page.waitForSelector('#matchmaking-overlay', { state: 'hidden', timeout: 20000 }),
          player2Page.waitForSelector('#matchmaking-overlay', { state: 'hidden', timeout: 20000 })
        ]);
        const matchmakingTime = Date.now() - matchmakingStart;
        
        const totalTime = Date.now() - totalStartTime;
        
        matchmakingBenchmarks.push({
          iteration: iteration + 1,
          pageLoadTime,
          connectionTime,
          matchmakingTime,
          totalTime
        });
        
        console.log(`    Load: ${pageLoadTime}ms, Connect: ${connectionTime}ms, Match: ${matchmakingTime}ms, Total: ${totalTime}ms`);
        
      } finally {
        await context1.close();
        await context2.close();
      }
    }
    
    // Calculate averages
    const avgPageLoad = matchmakingBenchmarks.reduce((sum, b) => sum + b.pageLoadTime, 0) / matchmakingBenchmarks.length;
    const avgConnection = matchmakingBenchmarks.reduce((sum, b) => sum + b.connectionTime, 0) / matchmakingBenchmarks.length;
    const avgMatchmaking = matchmakingBenchmarks.reduce((sum, b) => sum + b.matchmakingTime, 0) / matchmakingBenchmarks.length;
    const avgTotal = matchmakingBenchmarks.reduce((sum, b) => sum + b.totalTime, 0) / matchmakingBenchmarks.length;
    
    console.log(`📊 Matchmaking Performance Averages:`);
    console.log(`  Page load: ${avgPageLoad.toFixed(1)}ms`);
    console.log(`  Connection: ${avgConnection.toFixed(1)}ms`);
    console.log(`  Matchmaking: ${avgMatchmaking.toFixed(1)}ms`);
    console.log(`  Total: ${avgTotal.toFixed(1)}ms`);
    
    // Performance assertions based on requirements
    expect(avgPageLoad).toBeLessThan(5000); // Page load < 5s
    expect(avgConnection).toBeLessThan(3000); // Connection < 3s
    expect(avgMatchmaking).toBeLessThan(10000); // Matchmaking < 10s
    expect(avgTotal).toBeLessThan(15000); // Total flow < 15s
    
    console.log('✅ Matchmaking speed benchmarks validated');
  });

  test('Game state synchronization performance', async ({ browser }) => {
    console.log('⚡ Testing game state sync performance...');
    
    const context1 = await browser.newContext();
    const context2 = await browser.newContext();
    const player1Page = await context1.newPage();
    const player2Page = await context2.newPage();
    
    try {
      // Set up two players in a matched game
      await Promise.all([
        player1Page.goto('http://localhost:3000'),
        player2Page.goto('http://localhost:3000')
      ]);
      
      await Promise.all([
        player1Page.waitForSelector('#connection-text:has-text("Connected")'),
        player2Page.waitForSelector('#connection-text:has-text("Connected")')
      ]);
      
      // Quick matchmaking
      await player1Page.click('#play-btn');
      await player2Page.click('#play-btn');
      
      await Promise.all([
        player1Page.waitForSelector('#matchmaking-overlay', { state: 'hidden', timeout: 15000 }),
        player2Page.waitForSelector('#matchmaking-overlay', { state: 'hidden', timeout: 15000 })
      ]);
      
      console.log('Players matched, testing sync performance...');
      
      // Test game state updates
      const syncMeasurements = [];
      
      for (let i = 0; i < 5; i++) {
        const syncStart = Date.now();
        
        // Trigger a state change (click demo cards button)
        await player1Page.click('#new-game-btn');
        
        // Wait for state to appear on both pages
        await Promise.all([
          player1Page.waitForFunction(() => 
            document.querySelectorAll('#player-cards .card').length > 0,
            {}, { timeout: 2000 }
          ).catch(() => false),
          player2Page.waitForFunction(() => 
            document.getElementById('game-status').textContent.length > 10,
            {}, { timeout: 2000 }
          ).catch(() => false)
        ]);
        
        const syncTime = Date.now() - syncStart;
        syncMeasurements.push(syncTime);
        
        console.log(`    Sync test ${i + 1}: ${syncTime}ms`);
        
        // Small delay between tests
        await player1Page.waitForTimeout(500);
      }
      
      const avgSyncTime = syncMeasurements.reduce((sum, time) => sum + time, 0) / syncMeasurements.length;
      const maxSyncTime = Math.max(...syncMeasurements);
      const minSyncTime = Math.min(...syncMeasurements);
      
      console.log(`📊 Game State Sync Performance:`);
      console.log(`  Average sync time: ${avgSyncTime.toFixed(1)}ms`);
      console.log(`  Min sync time: ${minSyncTime}ms`);
      console.log(`  Max sync time: ${maxSyncTime}ms`);
      
      // Performance assertions
      expect(avgSyncTime).toBeLessThan(200); // Average sync < 200ms
      expect(maxSyncTime).toBeLessThan(500); // Max sync < 500ms
      
      console.log('✅ Game state synchronization performance validated');
      
    } finally {
      await context1.close();
      await context2.close();
    }
  });

  test('Card play response time', async ({ page }) => {
    console.log('🃏 Testing card play response time...');
    
    await page.goto('http://localhost:3000');
    await page.waitForSelector('#connection-text:has-text("Connected")');
    
    // Start demo game
    await page.click('#new-game-btn');
    await page.waitForTimeout(1000);
    
    // Find playable cards
    const playableCards = await page.locator('#player-cards .card.playable').count();
    
    if (playableCards > 0) {
      const cardResponseTimes = [];
      
      // Test card interaction response times
      for (let i = 0; i < Math.min(3, playableCards); i++) {
        const card = page.locator('#player-cards .card.playable').nth(i);
        
        // Measure hover response time
        const hoverStart = Date.now();
        await card.hover();
        
        // Wait for transform effect
        await page.waitForFunction((cardIndex) => {
          const cardElement = document.querySelectorAll('#player-cards .card.playable')[cardIndex];
          if (!cardElement) return false;
          const transform = window.getComputedStyle(cardElement).transform;
          return transform !== 'none';
        }, i, { timeout: 1000 }).catch(() => false);
        
        const hoverTime = Date.now() - hoverStart;
        
        // Measure click response time
        const clickStart = Date.now();
        await card.click();
        
        // Wait for selected state or card movement
        await page.waitForFunction((cardIndex) => {
          const cardElement = document.querySelectorAll('#player-cards .card')[cardIndex];
          if (!cardElement) return false;
          return cardElement.classList.contains('selected') || 
                 cardElement.parentElement.id !== 'player-cards';
        }, i, { timeout: 2000 }).catch(() => false);
        
        const clickTime = Date.now() - clickStart;
        
        cardResponseTimes.push({
          cardIndex: i,
          hoverTime,
          clickTime,
          totalTime: hoverTime + clickTime
        });
        
        console.log(`    Card ${i + 1}: Hover ${hoverTime}ms, Click ${clickTime}ms`);
        
        // Reset for next test if needed
        await page.waitForTimeout(200);
      }
      
      if (cardResponseTimes.length > 0) {
        const avgHoverTime = cardResponseTimes.reduce((sum, t) => sum + t.hoverTime, 0) / cardResponseTimes.length;
        const avgClickTime = cardResponseTimes.reduce((sum, t) => sum + t.clickTime, 0) / cardResponseTimes.length;
        const avgTotalTime = cardResponseTimes.reduce((sum, t) => sum + t.totalTime, 0) / cardResponseTimes.length;
        
        console.log(`📊 Card Interaction Performance:`);
        console.log(`  Average hover time: ${avgHoverTime.toFixed(1)}ms`);
        console.log(`  Average click time: ${avgClickTime.toFixed(1)}ms`);
        console.log(`  Average total time: ${avgTotalTime.toFixed(1)}ms`);
        
        // Performance assertions
        expect(avgHoverTime).toBeLessThan(100); // Hover response < 100ms
        expect(avgClickTime).toBeLessThan(200); // Click response < 200ms
        expect(avgTotalTime).toBeLessThan(250); // Total interaction < 250ms
        
        console.log('✅ Card play response time validated');
      } else {
        console.log('⚠️ No card interactions available for testing');
      }
    } else {
      console.log('⚠️ No playable cards found for response time testing');
    }
  });

  test('Memory usage during gameplay', async ({ page }) => {
    console.log('💾 Testing memory usage during gameplay...');
    
    await page.goto('http://localhost:3000');
    await page.waitForSelector('#connection-text:has-text("Connected")');
    
    // Get initial memory reading
    const initialMemory = await page.evaluate(() => {
      if (performance.memory) {
        return {
          usedJSHeapSize: performance.memory.usedJSHeapSize,
          totalJSHeapSize: performance.memory.totalJSHeapSize,
          jsHeapSizeLimit: performance.memory.jsHeapSizeLimit
        };
      }
      return null;
    });
    
    if (initialMemory) {
      console.log(`Initial memory usage: ${Math.round(initialMemory.usedJSHeapSize / 1024 / 1024)}MB`);
      
      // Simulate gameplay activities
      const activities = [
        () => page.click('#new-game-btn'),
        () => page.hover('#player-cards .card'),
        () => page.click('#player-cards .card'),
        () => page.waitForTimeout(1000),
        () => page.click('#new-game-btn'), // Reset game
      ];
      
      const memoryMeasurements = [initialMemory];
      
      for (let i = 0; i < activities.length; i++) {
        await activities[i]();
        await page.waitForTimeout(500); // Let memory stabilize
        
        const memory = await page.evaluate(() => {
          if (performance.memory) {
            return {
              usedJSHeapSize: performance.memory.usedJSHeapSize,
              totalJSHeapSize: performance.memory.totalJSHeapSize,
              jsHeapSizeLimit: performance.memory.jsHeapSizeLimit
            };
          }
          return null;
        });
        
        if (memory) {
          memoryMeasurements.push(memory);
          console.log(`  After activity ${i + 1}: ${Math.round(memory.usedJSHeapSize / 1024 / 1024)}MB`);
        }
      }
      
      // Analyze memory usage
      const maxMemoryUsed = Math.max(...memoryMeasurements.map(m => m.usedJSHeapSize));
      const memoryGrowth = memoryMeasurements[memoryMeasurements.length - 1].usedJSHeapSize - initialMemory.usedJSHeapSize;
      
      const maxMemoryMB = Math.round(maxMemoryUsed / 1024 / 1024);
      const memoryGrowthMB = Math.round(memoryGrowth / 1024 / 1024);
      
      console.log(`📊 Memory Usage Analysis:`);
      console.log(`  Max memory used: ${maxMemoryMB}MB`);
      console.log(`  Memory growth: ${memoryGrowthMB}MB`);
      console.log(`  Memory growth rate: ${((memoryGrowth / initialMemory.usedJSHeapSize) * 100).toFixed(1)}%`);
      
      // Memory usage assertions
      expect(maxMemoryMB).toBeLessThan(100); // Max usage < 100MB
      expect(memoryGrowthMB).toBeLessThan(20); // Growth < 20MB during gameplay
      
      console.log('✅ Memory usage during gameplay validated');
    } else {
      console.log('⚠️ Memory performance API not available in this browser');
    }
  });

  test('Network latency under load', async ({ page }) => {
    console.log('🌐 Testing network latency under load...');
    
    await page.goto('http://localhost:3000');
    await page.waitForSelector('#connection-text:has-text("Connected")');
    
    // Test WebSocket latency under concurrent requests
    const latencyTest = await page.evaluate(async () => {
      const measurements = [];
      const concurrent = 10; // Number of concurrent WebSocket operations
      
      // Create multiple WebSocket connections
      const connections = [];
      
      try {
        // Establish connections
        for (let i = 0; i < concurrent; i++) {
          const ws = new WebSocket(`ws://localhost:8080/ws/connect?user_id=latency-test-${i}`);
          
          await new Promise((resolve, reject) => {
            const timeout = setTimeout(() => reject(new Error('Connection timeout')), 5000);
            
            ws.onopen = () => {
              clearTimeout(timeout);
              resolve();
            };
            
            ws.onerror = () => {
              clearTimeout(timeout);
              reject(new Error('Connection failed'));
            };
          });
          
          connections.push(ws);
        }
        
        console.log(`Established ${connections.length} concurrent connections`);
        
        // Test message round-trip times
        for (let round = 0; round < 3; round++) {
          const roundLatencies = [];
          
          const promises = connections.map((ws, index) => {
            return new Promise((resolve) => {
              const startTime = performance.now();
              const messageId = `ping-${round}-${index}`;
              
              const timeout = setTimeout(() => {
                resolve({ index, latency: -1, success: false });
              }, 2000);
              
              const messageHandler = (event) => {
                try {
                  const message = JSON.parse(event.data);
                  if (message.type === 'pong' && message.payload?.ping_id === messageId) {
                    const latency = performance.now() - startTime;
                    ws.removeEventListener('message', messageHandler);
                    clearTimeout(timeout);
                    resolve({ index, latency, success: true });
                  }
                } catch (error) {
                  // Ignore parsing errors
                }
              };
              
              ws.addEventListener('message', messageHandler);
              
              // Send ping
              ws.send(JSON.stringify({
                type: 'ping',
                id: `msg_${Date.now()}_${index}`,
                timestamp: new Date().toISOString(),
                payload: { ping_id: messageId }
              }));
            });
          });
          
          const results = await Promise.all(promises);
          const successfulResults = results.filter(r => r.success);
          
          if (successfulResults.length > 0) {
            const avgLatency = successfulResults.reduce((sum, r) => sum + r.latency, 0) / successfulResults.length;
            roundLatencies.push(avgLatency);
            
            console.log(`Round ${round + 1}: ${successfulResults.length}/${concurrent} successful, avg ${avgLatency.toFixed(1)}ms`);
          }
          
          measurements.push(...successfulResults.map(r => r.latency));
          
          // Small delay between rounds
          await new Promise(resolve => setTimeout(resolve, 100));
        }
        
        return {
          totalConnections: connections.length,
          measurements: measurements.filter(m => m > 0),
          success: true
        };
        
      } finally {
        // Clean up connections
        connections.forEach(ws => {
          if (ws.readyState === WebSocket.OPEN) {
            ws.close();
          }
        });
      }
    });
    
    if (latencyTest.success && latencyTest.measurements.length > 0) {
      const avgLatency = latencyTest.measurements.reduce((sum, l) => sum + l, 0) / latencyTest.measurements.length;
      const maxLatency = Math.max(...latencyTest.measurements);
      const minLatency = Math.min(...latencyTest.measurements);
      
      console.log(`📊 Network Latency Under Load:`);
      console.log(`  Concurrent connections: ${latencyTest.totalConnections}`);
      console.log(`  Successful measurements: ${latencyTest.measurements.length}`);
      console.log(`  Average latency: ${avgLatency.toFixed(1)}ms`);
      console.log(`  Min latency: ${minLatency.toFixed(1)}ms`);
      console.log(`  Max latency: ${maxLatency.toFixed(1)}ms`);
      
      // Performance assertions
      expect(avgLatency).toBeLessThan(500); // Average latency < 500ms under load
      expect(maxLatency).toBeLessThan(1000); // Max latency < 1s under load
      
      console.log('✅ Network latency under load validated');
    } else {
      console.log('⚠️ Network latency test failed or no measurements available');
    }
  });

  test('Frontend rendering performance', async ({ page }) => {
    console.log('🎨 Testing frontend rendering performance...');
    
    await page.goto('http://localhost:3000');
    
    // Measure rendering performance
    const renderingMetrics = await page.evaluate(async () => {
      const metrics = {};
      
      // Measure initial page render
      if (performance.getEntriesByType) {
        const navigationEntries = performance.getEntriesByType('navigation');
        if (navigationEntries.length > 0) {
          const nav = navigationEntries[0];
          metrics.domContentLoaded = nav.domContentLoadedEventEnd - nav.domContentLoadedEventStart;
          metrics.loadComplete = nav.loadEventEnd - nav.loadEventStart;
          metrics.firstPaint = nav.responseEnd - nav.requestStart;
        }
      }
      
      // Measure DOM update performance
      const updateStart = performance.now();
      
      // Trigger UI updates
      const gameContainer = document.querySelector('.game-container');
      if (gameContainer) {
        // Add and remove elements to test DOM manipulation performance
        for (let i = 0; i < 100; i++) {
          const testElement = document.createElement('div');
          testElement.className = 'test-element';
          testElement.textContent = `Test ${i}`;
          gameContainer.appendChild(testElement);
        }
        
        // Remove test elements
        const testElements = gameContainer.querySelectorAll('.test-element');
        testElements.forEach(el => el.remove());
      }
      
      metrics.domManipulation = performance.now() - updateStart;
      
      // Measure CSS animation performance if possible
      const animationStart = performance.now();
      const cards = document.querySelectorAll('.card');
      cards.forEach(card => {
        card.style.transform = 'translateY(-10px) scale(1.05)';
      });
      
      // Reset transforms
      setTimeout(() => {
        cards.forEach(card => {
          card.style.transform = '';
        });
      }, 100);
      
      metrics.cssAnimation = performance.now() - animationStart;
      
      return metrics;
    });
    
    console.log(`📊 Frontend Rendering Performance:`);
    if (renderingMetrics.domContentLoaded !== undefined) {
      console.log(`  DOM Content Loaded: ${renderingMetrics.domContentLoaded.toFixed(1)}ms`);
    }
    if (renderingMetrics.loadComplete !== undefined) {
      console.log(`  Load Complete: ${renderingMetrics.loadComplete.toFixed(1)}ms`);
    }
    console.log(`  DOM Manipulation: ${renderingMetrics.domManipulation.toFixed(1)}ms`);
    console.log(`  CSS Animation: ${renderingMetrics.cssAnimation.toFixed(1)}ms`);
    
    // Performance assertions
    if (renderingMetrics.domContentLoaded !== undefined) {
      expect(renderingMetrics.domContentLoaded).toBeLessThan(1000); // DOM ready < 1s
    }
    expect(renderingMetrics.domManipulation).toBeLessThan(50); // DOM updates < 50ms
    expect(renderingMetrics.cssAnimation).toBeLessThan(20); // CSS animations < 20ms
    
    console.log('✅ Frontend rendering performance validated');
  });
});

test.describe('Performance Stress Tests', () => {
  
  test('Extended gameplay session performance', async ({ page }) => {
    console.log('🔥 Testing extended gameplay session performance...');
    
    await page.goto('http://localhost:3000');
    await page.waitForSelector('#connection-text:has-text("Connected")');
    
    const sessionMetrics = {
      startTime: Date.now(),
      memorySnapshots: [],
      actionTimes: [],
      errors: []
    };
    
    try {
      // Simulate 30 game actions over 2 minutes
      for (let action = 0; action < 30; action++) {
        const actionStart = Date.now();
        
        try {
          // Perform various game actions
          const actions = [
            () => page.click('#new-game-btn'),
            () => page.hover('#player-cards .card'),
            () => page.click('#play-btn').catch(() => {}), // May not always be available
            () => page.click('#new-game-btn'),
          ];
          
          const randomAction = actions[action % actions.length];
          await randomAction();
          await page.waitForTimeout(100);
          
          const actionTime = Date.now() - actionStart;
          sessionMetrics.actionTimes.push(actionTime);
          
          // Take memory snapshot every 10 actions
          if (action % 10 === 0) {
            const memory = await page.evaluate(() => {
              if (performance.memory) {
                return {
                  used: performance.memory.usedJSHeapSize,
                  total: performance.memory.totalJSHeapSize,
                  timestamp: Date.now()
                };
              }
              return null;
            });
            
            if (memory) {
              sessionMetrics.memorySnapshots.push(memory);
            }
          }
          
          console.log(`  Action ${action + 1}/30 completed in ${actionTime}ms`);
          
          // Small delay between actions
          await page.waitForTimeout(200);
          
        } catch (error) {
          sessionMetrics.errors.push({
            action: action + 1,
            error: error.message,
            timestamp: Date.now()
          });
        }
      }
      
      sessionMetrics.endTime = Date.now();
      sessionMetrics.totalDuration = sessionMetrics.endTime - sessionMetrics.startTime;
      
      // Analyze session performance
      const avgActionTime = sessionMetrics.actionTimes.reduce((sum, time) => sum + time, 0) / sessionMetrics.actionTimes.length;
      const maxActionTime = Math.max(...sessionMetrics.actionTimes);
      const minActionTime = Math.min(...sessionMetrics.actionTimes);
      
      console.log(`📊 Extended Session Performance:`);
      console.log(`  Total duration: ${Math.round(sessionMetrics.totalDuration / 1000)}s`);
      console.log(`  Actions completed: ${sessionMetrics.actionTimes.length}/30`);
      console.log(`  Average action time: ${avgActionTime.toFixed(1)}ms`);
      console.log(`  Min action time: ${minActionTime}ms`);
      console.log(`  Max action time: ${maxActionTime}ms`);
      console.log(`  Errors encountered: ${sessionMetrics.errors.length}`);
      
      if (sessionMetrics.memorySnapshots.length > 1) {
        const memoryGrowth = sessionMetrics.memorySnapshots[sessionMetrics.memorySnapshots.length - 1].used - sessionMetrics.memorySnapshots[0].used;
        const memoryGrowthMB = Math.round(memoryGrowth / 1024 / 1024);
        console.log(`  Memory growth: ${memoryGrowthMB}MB`);
        
        // Memory growth should be reasonable during extended session
        expect(Math.abs(memoryGrowthMB)).toBeLessThan(50); // Growth < 50MB
      }
      
      // Performance assertions for extended session
      expect(sessionMetrics.actionTimes.length).toBeGreaterThanOrEqual(25); // At least 25/30 actions completed
      expect(avgActionTime).toBeLessThan(1000); // Average action time < 1s
      expect(sessionMetrics.errors.length).toBeLessThan(5); // Less than 5 errors
      
      console.log('✅ Extended gameplay session performance validated');
      
    } catch (error) {
      console.error('Extended session test error:', error);
      throw error;
    }
  });
});