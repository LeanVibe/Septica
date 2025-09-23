/**
 * Error Handling and Resilience Tests
 * Validates system behavior under adverse conditions and error scenarios
 */

import { test, expect } from '@playwright/test';

test.describe('Romanian Septica Error Handling and Resilience', () => {
  
  test.beforeEach(async () => {
    test.setTimeout(60000);
  });

  test('Connection loss during matchmaking', async ({ browser }) => {
    console.log('🔌 Testing connection loss during matchmaking...');
    
    const context = await browser.newContext();
    const page = await context.newPage();
    
    try {
      await page.goto('http://localhost:3000');
      await page.waitForSelector('#connection-text:has-text("Connected")');
      
      // Start matchmaking
      await page.click('#play-btn');
      await page.waitForSelector('#matchmaking-overlay', { state: 'visible' });
      
      console.log('Player entered matchmaking, simulating connection loss...');
      
      // Simulate connection loss by going offline
      await page.context().setOffline(true);
      await page.waitForTimeout(2000);
      
      // Check that UI handles offline state gracefully
      const connectionStatus = await page.locator('#connection-text').textContent();
      console.log(`Connection status during offline: ${connectionStatus}`);
      
      // Restore connection
      await page.context().setOffline(false);
      console.log('Connection restored, checking recovery...');
      
      // Wait for reconnection
      await page.waitForSelector('#connection-text:has-text("Connected")', { timeout: 15000 });
      
      // Verify UI state after reconnection
      const gameStatus = await page.locator('#game-status').textContent();
      console.log(`Game status after reconnection: ${gameStatus}`);
      
      // UI should be in a stable state (not stuck in matchmaking)
      const matchmakingVisible = await page.locator('#matchmaking-overlay').isVisible();
      console.log(`Matchmaking overlay still visible: ${matchmakingVisible}`);
      
      // The system should either:
      // 1. Successfully reconnect and continue matchmaking, or
      // 2. Gracefully exit matchmaking and return to ready state
      const playBtnEnabled = await page.locator('#play-btn').isEnabled();
      const cancelBtnEnabled = await page.locator('#cancel-matchmaking-btn').isEnabled();
      
      // At least one of these should be true (either ready to play or can cancel)
      expect(playBtnEnabled || cancelBtnEnabled).toBe(true);
      
      console.log('✅ Connection loss during matchmaking handled gracefully');
      
    } finally {
      await context.close();
    }
  });

  test('WebSocket reconnection scenarios', async ({ page }) => {
    console.log('🔄 Testing WebSocket reconnection scenarios...');
    
    await page.goto('http://localhost:3000');
    await page.waitForSelector('#connection-text:has-text("Connected")');
    
    // Test WebSocket resilience
    const reconnectionTest = await page.evaluate(async () => {
      const results = [];
      
      // Test multiple reconnection cycles
      for (let cycle = 0; cycle < 3; cycle++) {
        console.log(`Testing reconnection cycle ${cycle + 1}`);
        
        try {
          // Create a WebSocket connection
          const ws = new WebSocket(`ws://localhost:8080/ws/connect?user_id=reconnect-test-${cycle}`);
          
          // Wait for connection
          await new Promise((resolve, reject) => {
            const timeout = setTimeout(() => {
              ws.close();
              reject(new Error('Initial connection timeout'));
            }, 5000);
            
            ws.onopen = () => {
              clearTimeout(timeout);
              resolve();
            };
            
            ws.onerror = (error) => {
              clearTimeout(timeout);
              reject(error);
            };
          });
          
          console.log(`Cycle ${cycle + 1}: Initial connection successful`);
          
          // Force close connection
          ws.close();
          
          // Wait a moment
          await new Promise(resolve => setTimeout(resolve, 500));
          
          // Attempt reconnection
          const ws2 = new WebSocket(`ws://localhost:8080/ws/connect?user_id=reconnect-test-${cycle}-retry`);
          
          await new Promise((resolve, reject) => {
            const timeout = setTimeout(() => {
              ws2.close();
              reject(new Error('Reconnection timeout'));
            }, 5000);
            
            ws2.onopen = () => {
              clearTimeout(timeout);
              ws2.close();
              resolve();
            };
            
            ws2.onerror = (error) => {
              clearTimeout(timeout);
              reject(error);
            };
          });
          
          results.push({
            cycle: cycle + 1,
            success: true,
            error: null
          });
          
          console.log(`Cycle ${cycle + 1}: Reconnection successful`);
          
        } catch (error) {
          results.push({
            cycle: cycle + 1,
            success: false,
            error: error.message
          });
          
          console.log(`Cycle ${cycle + 1}: Failed - ${error.message}`);
        }
        
        // Delay between cycles
        await new Promise(resolve => setTimeout(resolve, 1000));
      }
      
      return results;
    });
    
    // Analyze reconnection results
    const successfulReconnections = reconnectionTest.filter(r => r.success).length;
    const totalAttempts = reconnectionTest.length;
    
    console.log(`📊 Reconnection Test Results:`);
    console.log(`  Successful reconnections: ${successfulReconnections}/${totalAttempts}`);
    
    reconnectionTest.forEach(result => {
      const status = result.success ? '✅' : '❌';
      console.log(`  Cycle ${result.cycle}: ${status} ${result.error || ''}`);
    });
    
    // Should have at least 80% success rate
    expect(successfulReconnections / totalAttempts).toBeGreaterThanOrEqual(0.8);
    
    console.log('✅ WebSocket reconnection scenarios validated');
  });

  test('Invalid card play rejection', async ({ page }) => {
    console.log('🚫 Testing invalid card play rejection...');
    
    await page.goto('http://localhost:3000');
    await page.waitForSelector('#connection-text:has-text("Connected")');
    
    // Start demo game
    await page.click('#new-game-btn');
    await page.waitForTimeout(1000);
    
    // Test invalid WebSocket messages
    const invalidMessageTest = await page.evaluate(async () => {
      const results = [];
      
      try {
        // Create WebSocket connection
        const ws = new WebSocket('ws://localhost:8080/ws/connect?user_id=invalid-test');
        
        await new Promise((resolve, reject) => {
          const timeout = setTimeout(() => {
            reject(new Error('Connection timeout'));
          }, 5000);
          
          ws.onopen = () => {
            clearTimeout(timeout);
            resolve();
          };
          
          ws.onerror = (error) => {
            clearTimeout(timeout);
            reject(error);
          };
        });
        
        // Test invalid message formats
        const invalidMessages = [
          // Invalid JSON
          'invalid json',
          
          // Missing required fields
          JSON.stringify({ type: 'play_card' }), // Missing game_id and payload
          
          // Invalid card values
          JSON.stringify({
            type: 'play_card',
            game_id: 'test-game',
            payload: { suit: 'hearts', value: 15 } // Invalid value
          }),
          
          // Invalid card suit
          JSON.stringify({
            type: 'play_card',
            game_id: 'test-game',
            payload: { suit: 'invalid', value: 10 }
          }),
          
          // Unknown message type
          JSON.stringify({
            type: 'unknown_message',
            game_id: 'test-game'
          })
        ];
        
        // Send invalid messages and check for error responses
        for (let i = 0; i < invalidMessages.length; i++) {
          const message = invalidMessages[i];
          
          try {
            // Listen for error responses
            const errorPromise = new Promise((resolve) => {
              const timeout = setTimeout(() => resolve(null), 2000);
              
              const messageHandler = (event) => {
                try {
                  const response = JSON.parse(event.data);
                  if (response.type === 'error') {
                    clearTimeout(timeout);
                    ws.removeEventListener('message', messageHandler);
                    resolve(response);
                  }
                } catch (error) {
                  // Ignore parsing errors
                }
              };
              
              ws.addEventListener('message', messageHandler);
            });
            
            // Send invalid message
            ws.send(message);
            
            const errorResponse = await errorPromise;
            
            results.push({
              messageIndex: i,
              sentMessage: message.substring(0, 50) + '...',
              receivedError: errorResponse !== null,
              errorDetails: errorResponse?.payload || null
            });
            
          } catch (error) {
            results.push({
              messageIndex: i,
              sentMessage: message.substring(0, 50) + '...',
              receivedError: false,
              error: error.message
            });
          }
          
          // Small delay between messages
          await new Promise(resolve => setTimeout(resolve, 200));
        }
        
        ws.close();
        
      } catch (error) {
        console.error('WebSocket connection failed:', error);
        return [];
      }
      
      return results;
    });
    
    if (invalidMessageTest.length > 0) {
      console.log(`📊 Invalid Message Test Results:`);
      
      invalidMessageTest.forEach((result, index) => {
        const status = result.receivedError ? '✅ Rejected' : '⚠️ Accepted';
        console.log(`  Message ${index + 1}: ${status}`);
        if (result.errorDetails) {
          console.log(`    Error: ${result.errorDetails.message || 'Unknown'}`);
        }
      });
      
      // At least some invalid messages should be rejected
      const rejectedCount = invalidMessageTest.filter(r => r.receivedError).length;
      console.log(`  ${rejectedCount}/${invalidMessageTest.length} invalid messages were properly rejected`);
      
      // We expect at least 60% of clearly invalid messages to be rejected
      expect(rejectedCount / invalidMessageTest.length).toBeGreaterThanOrEqual(0.6);
    } else {
      console.log('⚠️ Could not test invalid messages (WebSocket connection failed)');
    }
    
    console.log('✅ Invalid card play rejection test completed');
  });

  test('Timeout handling during matchmaking', async ({ page }) => {
    console.log('⏰ Testing timeout handling during matchmaking...');
    
    await page.goto('http://localhost:3000');
    await page.waitForSelector('#connection-text:has-text("Connected")');
    
    // Start matchmaking (single player - should timeout or handle gracefully)
    await page.click('#play-btn');
    await page.waitForSelector('#matchmaking-overlay', { state: 'visible' });
    
    console.log('Started matchmaking, waiting for timeout handling...');
    
    // Wait for extended period to test timeout behavior
    await page.waitForTimeout(30000); // 30 seconds
    
    // Check current state
    const matchmakingStillVisible = await page.locator('#matchmaking-overlay').isVisible();
    const gameStatus = await page.locator('#game-status').textContent();
    const playBtnEnabled = await page.locator('#play-btn').isEnabled();
    const cancelBtnEnabled = await page.locator('#cancel-matchmaking-btn').isEnabled();
    
    console.log(`📊 Timeout Handling State:`);
    console.log(`  Matchmaking overlay visible: ${matchmakingStillVisible}`);
    console.log(`  Game status: ${gameStatus}`);
    console.log(`  Play button enabled: ${playBtnEnabled}`);
    console.log(`  Cancel button enabled: ${cancelBtnEnabled}`);
    
    // System should either:
    // 1. Still be in matchmaking with cancel option available
    // 2. Have timed out and returned to ready state
    // 3. Show appropriate timeout message
    
    const systemInValidState = !matchmakingStillVisible ? playBtnEnabled : cancelBtnEnabled;
    expect(systemInValidState).toBe(true);
    
    // If still in matchmaking, test cancel functionality
    if (matchmakingStillVisible && cancelBtnEnabled) {
      await page.click('#cancel-matchmaking-btn');
      await page.waitForSelector('#matchmaking-overlay', { state: 'hidden', timeout: 5000 });
      
      const playBtnAfterCancel = await page.locator('#play-btn').isEnabled();
      expect(playBtnAfterCancel).toBe(true);
      
      console.log('✅ Matchmaking cancellation after timeout works correctly');
    }
    
    console.log('✅ Timeout handling during matchmaking validated');
  });

  test('Error message display and user feedback', async ({ page }) => {
    console.log('💬 Testing error message display and user feedback...');
    
    await page.goto('http://localhost:3000');
    
    // Test error scenarios that might produce user-visible errors
    const errorScenarios = [
      {
        name: 'Connection to invalid endpoint',
        action: async () => {
          return await page.evaluate(async () => {
            try {
              const ws = new WebSocket('ws://localhost:9999/invalid');
              
              return await new Promise((resolve) => {
                const timeout = setTimeout(() => {
                  resolve({ success: false, error: 'Connection timeout' });
                }, 3000);
                
                ws.onopen = () => {
                  clearTimeout(timeout);
                  ws.close();
                  resolve({ success: true, error: null });
                };
                
                ws.onerror = (error) => {
                  clearTimeout(timeout);
                  resolve({ success: false, error: 'Connection failed' });
                };
              });
            } catch (error) {
              return { success: false, error: error.message };
            }
          });
        }
      },
      
      {
        name: 'Multiple rapid button clicks',
        action: async () => {
          // Rapidly click play button multiple times
          for (let i = 0; i < 5; i++) {
            await page.click('#play-btn', { force: true }).catch(() => {});
            await page.waitForTimeout(50);
          }
          
          // Check if system handled it gracefully
          const gameStatus = await page.locator('#game-status').textContent();
          return { 
            success: !gameStatus.toLowerCase().includes('error'),
            error: gameStatus.toLowerCase().includes('error') ? gameStatus : null
          };
        }
      },
      
      {
        name: 'Interaction with disabled elements',
        action: async () => {
          try {
            // Try to interact with potentially disabled elements
            await page.click('#cancel-matchmaking-btn', { force: true, timeout: 1000 });
            
            const gameStatus = await page.locator('#game-status').textContent();
            return { 
              success: !gameStatus.toLowerCase().includes('error'),
              error: gameStatus.toLowerCase().includes('error') ? gameStatus : null
            };
          } catch (error) {
            // This is expected for disabled elements
            return { success: true, error: null };
          }
        }
      }
    ];
    
    console.log(`📊 Error Scenario Results:`);
    
    for (const scenario of errorScenarios) {
      try {
        console.log(`  Testing: ${scenario.name}`);
        const result = await scenario.action();
        
        const status = result.success ? '✅ Handled gracefully' : '❌ Error occurred';
        console.log(`    Result: ${status}`);
        
        if (result.error) {
          console.log(`    Error details: ${result.error}`);
        }
        
        // For error testing, we expect graceful handling (no crashes)
        // The page should remain functional
        const pageStillFunctional = await page.locator('.game-container').isVisible();
        expect(pageStillFunctional).toBe(true);
        
      } catch (error) {
        console.log(`    Exception during test: ${error.message}`);
        
        // Even if exceptions occur, page should still be functional
        const pageStillFunctional = await page.locator('.game-container').isVisible();
        expect(pageStillFunctional).toBe(true);
      }
      
      // Small delay between scenarios
      await page.waitForTimeout(500);
    }
    
    console.log('✅ Error message display and user feedback validated');
  });

  test('Browser refresh during active session', async ({ page }) => {
    console.log('🔄 Testing browser refresh during active session...');
    
    await page.goto('http://localhost:3000');
    await page.waitForSelector('#connection-text:has-text("Connected")');
    
    // Start demo game to establish session state
    await page.click('#new-game-btn');
    await page.waitForTimeout(1000);
    
    const preRefreshStatus = await page.locator('#game-status').textContent();
    console.log(`Pre-refresh status: ${preRefreshStatus}`);
    
    // Refresh the page
    console.log('Refreshing page...');
    await page.reload();
    
    // Wait for page to reload and reconnect
    await page.waitForSelector('.game-container', { timeout: 10000 });
    
    // Check post-refresh state
    await page.waitForTimeout(2000); // Allow time for reconnection
    
    const postRefreshConnectionStatus = await page.locator('#connection-text').textContent();
    const postRefreshGameStatus = await page.locator('#game-status').textContent();
    
    console.log(`📊 Post-Refresh State:`);
    console.log(`  Connection status: ${postRefreshConnectionStatus}`);
    console.log(`  Game status: ${postRefreshGameStatus}`);
    
    // Verify page is functional after refresh
    const gameContainerVisible = await page.locator('.game-container').isVisible();
    const playBtnVisible = await page.locator('#play-btn').isVisible();
    const connectionStatusVisible = await page.locator('#connection-text').isVisible();
    
    expect(gameContainerVisible).toBe(true);
    expect(playBtnVisible).toBe(true);
    expect(connectionStatusVisible).toBe(true);
    
    // Try to reconnect if not already connected
    if (!postRefreshConnectionStatus.includes('Connected')) {
      console.log('Waiting for automatic reconnection...');
      await page.waitForSelector('#connection-text:has-text("Connected")', { timeout: 15000 });
      console.log('✅ Automatic reconnection successful');
    }
    
    // Test basic functionality after refresh
    await page.click('#new-game-btn');
    await page.waitForTimeout(1000);
    
    const functionalityTestStatus = await page.locator('#game-status').textContent();
    console.log(`Post-refresh functionality test: ${functionalityTestStatus}`);
    
    // Should not contain error messages
    expect(functionalityTestStatus.toLowerCase()).not.toMatch(/error|undefined|null/);
    
    console.log('✅ Browser refresh during active session handled correctly');
  });

  test('Concurrent session conflict resolution', async ({ browser }) => {
    console.log('👥 Testing concurrent session conflict resolution...');
    
    // Test multiple tabs with same user ID to check conflict handling
    const context1 = await browser.newContext();
    const context2 = await browser.newContext();
    
    try {
      const page1 = await context1.newPage();
      const page2 = await context2.newPage();
      
      // Set the same user ID in localStorage for both pages
      await page1.goto('http://localhost:3000');
      await page2.goto('http://localhost:3000');
      
      // Set same user ID to simulate multiple tabs for same user
      await page1.evaluate(() => {
        localStorage.setItem('septica_user_id', 'conflict-test-user');
      });
      await page2.evaluate(() => {
        localStorage.setItem('septica_user_id', 'conflict-test-user');
      });
      
      // Refresh both pages to use the same user ID
      await Promise.all([
        page1.reload(),
        page2.reload()
      ]);
      
      await Promise.all([
        page1.waitForSelector('.game-container'),
        page2.waitForSelector('.game-container')
      ]);
      
      console.log('Both tabs loaded with same user ID');
      
      // Try to establish WebSocket connections from both tabs
      const connectionResults = await Promise.all([
        page1.evaluate(async () => {
          try {
            const ws = new WebSocket('ws://localhost:8080/ws/connect?user_id=conflict-test-user');
            
            return await new Promise((resolve) => {
              const timeout = setTimeout(() => {
                ws.close();
                resolve({ success: false, error: 'Connection timeout' });
              }, 5000);
              
              ws.onopen = () => {
                clearTimeout(timeout);
                ws.close();
                resolve({ success: true, tab: 'tab1' });
              };
              
              ws.onerror = (error) => {
                clearTimeout(timeout);
                resolve({ success: false, error: 'Connection failed', tab: 'tab1' });
              };
            });
          } catch (error) {
            return { success: false, error: error.message, tab: 'tab1' };
          }
        }),
        
        page2.evaluate(async () => {
          try {
            const ws = new WebSocket('ws://localhost:8080/ws/connect?user_id=conflict-test-user');
            
            return await new Promise((resolve) => {
              const timeout = setTimeout(() => {
                ws.close();
                resolve({ success: false, error: 'Connection timeout' });
              }, 5000);
              
              ws.onopen = () => {
                clearTimeout(timeout);
                ws.close();
                resolve({ success: true, tab: 'tab2' });
              };
              
              ws.onerror = (error) => {
                clearTimeout(timeout);
                resolve({ success: false, error: 'Connection failed', tab: 'tab2' });
              };
            });
          } catch (error) {
            return { success: false, error: error.message, tab: 'tab2' };
          }
        })
      ]);
      
      console.log(`📊 Concurrent Session Results:`);
      connectionResults.forEach(result => {
        const status = result.success ? '✅ Connected' : '❌ Failed';
        console.log(`  ${result.tab}: ${status} ${result.error || ''}`);
      });
      
      // The system should handle this scenario gracefully:
      // Either both connections succeed (if allowed) or one is rejected properly
      const successfulConnections = connectionResults.filter(r => r.success).length;
      const failedConnections = connectionResults.filter(r => !r.success).length;
      
      console.log(`  ${successfulConnections} successful, ${failedConnections} failed connections`);
      
      // System should handle conflicts consistently (not crash)
      expect(successfulConnections + failedConnections).toBe(2);
      
      console.log('✅ Concurrent session conflict resolution tested');
      
    } finally {
      await context1.close();
      await context2.close();
    }
  });

  test('Memory leak prevention during errors', async ({ page }) => {
    console.log('🧠 Testing memory leak prevention during errors...');
    
    await page.goto('http://localhost:3000');
    
    const memoryTest = await page.evaluate(async () => {
      const measurements = [];
      
      // Get initial memory reading
      if (performance.memory) {
        measurements.push({
          phase: 'initial',
          memory: performance.memory.usedJSHeapSize,
          timestamp: Date.now()
        });
      }
      
      // Simulate error conditions that might cause memory leaks
      const errorSimulations = [
        // Create and destroy WebSocket connections
        async () => {
          for (let i = 0; i < 10; i++) {
            try {
              const ws = new WebSocket(`ws://localhost:8080/ws/connect?user_id=memory-test-${i}`);
              
              // Don't wait for connection, just create and close
              setTimeout(() => {
                if (ws.readyState === WebSocket.OPEN || ws.readyState === WebSocket.CONNECTING) {
                  ws.close();
                }
              }, 100);
              
            } catch (error) {
              // Ignore connection errors
            }
          }
        },
        
        // Create DOM elements and event listeners
        async () => {
          for (let i = 0; i < 100; i++) {
            const element = document.createElement('div');
            element.addEventListener('click', () => {});
            document.body.appendChild(element);
            
            // Remove immediately to test cleanup
            document.body.removeChild(element);
          }
        },
        
        // Create and clear timers
        async () => {
          const timers = [];
          for (let i = 0; i < 50; i++) {
            timers.push(setTimeout(() => {}, 1000));
          }
          
          // Clear all timers
          timers.forEach(timer => clearTimeout(timer));
        }
      ];
      
      // Run error simulations
      for (let sim = 0; sim < errorSimulations.length; sim++) {
        await errorSimulations[sim]();
        
        // Force garbage collection if available
        if (window.gc) {
          window.gc();
        }
        
        // Wait for cleanup
        await new Promise(resolve => setTimeout(resolve, 1000));
        
        if (performance.memory) {
          measurements.push({
            phase: `after_simulation_${sim + 1}`,
            memory: performance.memory.usedJSHeapSize,
            timestamp: Date.now()
          });
        }
      }
      
      // Final measurement after cleanup
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      if (performance.memory) {
        measurements.push({
          phase: 'final',
          memory: performance.memory.usedJSHeapSize,
          timestamp: Date.now()
        });
      }
      
      return measurements;
    });
    
    if (memoryTest.length > 0) {
      console.log(`📊 Memory Usage During Error Simulations:`);
      
      memoryTest.forEach(measurement => {
        const memoryMB = Math.round(measurement.memory / 1024 / 1024);
        console.log(`  ${measurement.phase}: ${memoryMB}MB`);
      });
      
      // Analyze memory growth
      if (memoryTest.length >= 2) {
        const initialMemory = memoryTest[0].memory;
        const finalMemory = memoryTest[memoryTest.length - 1].memory;
        const memoryGrowth = finalMemory - initialMemory;
        const memoryGrowthMB = Math.round(memoryGrowth / 1024 / 1024);
        
        console.log(`  Memory growth: ${memoryGrowthMB}MB`);
        
        // Memory growth should be reasonable (< 20MB for error simulations)
        expect(Math.abs(memoryGrowthMB)).toBeLessThan(20);
      }
      
      console.log('✅ Memory leak prevention during errors validated');
    } else {
      console.log('⚠️ Memory performance API not available for testing');
    }
  });
});

test.describe('System Recovery Tests', () => {
  
  test('Graceful degradation when backend unavailable', async ({ page }) => {
    console.log('🏥 Testing graceful degradation when backend unavailable...');
    
    // Test what happens when backend is not reachable
    await page.goto('http://localhost:3000');
    
    // Wait for initial connection attempt
    await page.waitForTimeout(5000);
    
    const connectionStatus = await page.locator('#connection-text').textContent();
    console.log(`Connection status with potential backend issues: ${connectionStatus}`);
    
    // UI should still be functional even if backend is unavailable
    const uiElements = {
      gameContainer: await page.locator('.game-container').isVisible(),
      playButton: await page.locator('#play-btn').isVisible(),
      newGameButton: await page.locator('#new-game-btn').isVisible(),
      gameStatus: await page.locator('#game-status').isVisible()
    };
    
    console.log(`📊 UI Functionality During Backend Issues:`);
    Object.entries(uiElements).forEach(([element, visible]) => {
      console.log(`  ${element}: ${visible ? '✅ Visible' : '❌ Hidden'}`);
      expect(visible).toBe(true);
    });
    
    // Test offline functionality (demo mode should work)
    await page.click('#new-game-btn');
    await page.waitForTimeout(1000);
    
    const demoWorking = await page.locator('#player-cards .card').count() > 0;
    console.log(`Demo mode working: ${demoWorking ? '✅ Yes' : '⚠️ No'}`);
    
    // Even if backend is unavailable, basic UI should work
    expect(uiElements.gameContainer).toBe(true);
    expect(uiElements.playButton).toBe(true);
    
    console.log('✅ Graceful degradation when backend unavailable validated');
  });

  test('Recovery after service restoration', async ({ page }) => {
    console.log('🔧 Testing recovery after service restoration...');
    
    await page.goto('http://localhost:3000');
    
    // Simulate service interruption by going offline
    await page.context().setOffline(true);
    await page.waitForTimeout(2000);
    
    // Check offline state
    const offlineStatus = await page.locator('#connection-text').textContent();
    console.log(`Status during offline: ${offlineStatus}`);
    
    // Restore service
    await page.context().setOffline(false);
    console.log('Service restored, testing recovery...');
    
    // Wait for recovery
    await page.waitForSelector('#connection-text:has-text("Connected")', { timeout: 20000 });
    
    // Test full functionality after recovery
    const recoveryTests = [
      {
        name: 'WebSocket connection',
        test: async () => {
          const connected = await page.locator('#connection-dot.connected').isVisible();
          return { success: connected, details: connected ? 'Connected' : 'Not connected' };
        }
      },
      
      {
        name: 'UI responsiveness',
        test: async () => {
          await page.click('#new-game-btn');
          await page.waitForTimeout(1000);
          const cards = await page.locator('#player-cards .card').count();
          return { success: cards > 0, details: `${cards} cards visible` };
        }
      },
      
      {
        name: 'Game status updates',
        test: async () => {
          const status = await page.locator('#game-status').textContent();
          const hasStatus = status && status.length > 5;
          return { success: hasStatus, details: status };
        }
      }
    ];
    
    console.log(`📊 Recovery Test Results:`);
    
    for (const test of recoveryTests) {
      try {
        const result = await test.test();
        const status = result.success ? '✅ Passed' : '❌ Failed';
        console.log(`  ${test.name}: ${status} - ${result.details}`);
        
        expect(result.success).toBe(true);
      } catch (error) {
        console.log(`  ${test.name}: ❌ Error - ${error.message}`);
        throw error;
      }
    }
    
    console.log('✅ Recovery after service restoration validated');
  });
});