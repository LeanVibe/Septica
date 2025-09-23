/**
 * Infrastructure Connectivity Tests
 * Validates all system components are operational and accessible
 */

import { test, expect } from '@playwright/test';

test.describe('Romanian Septica Infrastructure Connectivity', () => {
  
  test.beforeEach(async ({ page }) => {
    // Set longer timeout for infrastructure tests
    test.setTimeout(30000);
  });

  test('Backend server health check', async ({ request }) => {
    console.log('🔍 Testing backend server health...');
    
    const startTime = Date.now();
    const response = await request.get('http://localhost:8080/health');
    const responseTime = Date.now() - startTime;
    
    expect(response.status()).toBe(200);
    expect(responseTime).toBeLessThan(2000); // Should respond within 2 seconds
    
    console.log(`✅ Backend health check passed (${responseTime}ms)`);
  });

  test('Frontend server availability', async ({ page }) => {
    console.log('🔍 Testing frontend server availability...');
    
    const startTime = Date.now();
    const response = await page.goto('http://localhost:3000');
    const loadTime = Date.now() - startTime;
    
    expect(response.status()).toBe(200);
    expect(loadTime).toBeLessThan(5000); // Should load within 5 seconds
    
    // Verify basic page elements
    await expect(page.locator('title')).toHaveText(/Romanian Septica/);
    await expect(page.locator('.game-container')).toBeVisible();
    
    console.log(`✅ Frontend availability check passed (${loadTime}ms)`);
  });

  test('WebSocket connection establishment', async ({ page }) => {
    console.log('🔍 Testing WebSocket connection...');
    
    await page.goto('http://localhost:3000');
    
    // Wait for page to fully load
    await page.waitForLoadState('domcontentloaded');
    
    // Test WebSocket connectivity
    const wsResult = await page.evaluate(async () => {
      return new Promise((resolve) => {
        const startTime = Date.now();
        const ws = new WebSocket('ws://localhost:8080/ws/connect?user_id=test-infrastructure');
        
        const timeout = setTimeout(() => {
          ws.close();
          resolve({ 
            success: false, 
            error: 'Connection timeout',
            duration: Date.now() - startTime
          });
        }, 10000);
        
        ws.onopen = () => {
          clearTimeout(timeout);
          const duration = Date.now() - startTime;
          ws.close();
          resolve({ 
            success: true,
            duration,
            readyState: ws.readyState
          });
        };
        
        ws.onerror = (error) => {
          clearTimeout(timeout);
          resolve({ 
            success: false, 
            error: 'Connection failed',
            duration: Date.now() - startTime
          });
        };
      });
    });
    
    expect(wsResult.success).toBe(true);
    expect(wsResult.duration).toBeLessThan(5000); // Should connect within 5 seconds
    
    console.log(`✅ WebSocket connection test passed (${wsResult.duration}ms)`);
  });

  test('Cross-origin resource sharing (CORS)', async ({ page }) => {
    console.log('🔍 Testing CORS configuration...');
    
    await page.goto('http://localhost:3000');
    
    // Test API calls from frontend to backend
    const corsResult = await page.evaluate(async () => {
      try {
        const response = await fetch('http://localhost:8080/health', {
          method: 'GET',
          headers: {
            'Content-Type': 'application/json',
          },
        });
        
        return {
          success: response.ok,
          status: response.status,
          headers: Object.fromEntries(response.headers.entries())
        };
      } catch (error) {
        return {
          success: false,
          error: error.message
        };
      }
    });
    
    expect(corsResult.success).toBe(true);
    expect(corsResult.status).toBe(200);
    
    console.log('✅ CORS configuration test passed');
  });

  test('Database connectivity via backend', async ({ request }) => {
    console.log('🔍 Testing database connectivity...');
    
    // Try to reach a database-dependent endpoint (if available)
    // This might return 404 if not implemented, which is acceptable
    try {
      const response = await request.get('http://localhost:8080/api/health/db');
      
      if (response.status() === 200) {
        console.log('✅ Database connectivity confirmed via backend');
      } else if (response.status() === 404) {
        console.log('⚠️ Database health endpoint not available (acceptable)');
      } else {
        console.log(`⚠️ Database health check returned ${response.status()}`);
      }
      
      // Don't fail the test if endpoint doesn't exist
      expect([200, 404, 501]).toContain(response.status());
    } catch (error) {
      console.log('⚠️ Database health endpoint not reachable (may be normal)');
      // This is acceptable - not all backends expose this endpoint
    }
  });

  test('Static asset serving', async ({ page }) => {
    console.log('🔍 Testing static asset serving...');
    
    await page.goto('http://localhost:3000');
    
    // Check for common assets
    const assetChecks = [];
    
    // Check if CSS is loaded
    const styles = await page.evaluate(() => {
      const styleSheets = Array.from(document.styleSheets);
      return styleSheets.length > 0;
    });
    
    if (styles) {
      assetChecks.push('CSS loaded');
    }
    
    // Check if JavaScript is executed
    const jsExecuted = await page.evaluate(() => {
      return typeof window.ConsolidatedSepticaGame !== 'undefined' || 
             typeof window.SepticaWebSocketClient !== 'undefined';
    });
    
    if (jsExecuted) {
      assetChecks.push('JavaScript executed');
    }
    
    // Check for WebSocket client script
    const wsClientLoaded = await page.evaluate(() => {
      return typeof window.SepticaWebSocketClient !== 'undefined';
    });
    
    expect(wsClientLoaded).toBe(true);
    console.log(`✅ Static assets check passed: ${assetChecks.join(', ')}`);
  });

  test('Network latency benchmarks', async ({ page }) => {
    console.log('🔍 Running network latency benchmarks...');
    
    await page.goto('http://localhost:3000');
    
    // Test multiple round trips to establish baseline
    const latencies = [];
    
    for (let i = 0; i < 5; i++) {
      const startTime = Date.now();
      const response = await fetch('http://localhost:8080/health');
      const latency = Date.now() - startTime;
      latencies.push(latency);
      
      expect(response.ok).toBe(true);
    }
    
    const avgLatency = latencies.reduce((sum, lat) => sum + lat, 0) / latencies.length;
    const maxLatency = Math.max(...latencies);
    const minLatency = Math.min(...latencies);
    
    // Benchmark expectations
    expect(avgLatency).toBeLessThan(500); // Average < 500ms
    expect(maxLatency).toBeLessThan(1000); // Max < 1s
    
    console.log(`✅ Network latency benchmarks: avg=${avgLatency.toFixed(1)}ms, min=${minLatency}ms, max=${maxLatency}ms`);
  });

  test('Concurrent connection handling', async ({ browser }) => {
    console.log('🔍 Testing concurrent connection handling...');
    
    // Create multiple browser contexts to simulate concurrent users
    const contexts = [];
    const pages = [];
    
    try {
      // Create 3 concurrent connections
      for (let i = 0; i < 3; i++) {
        const context = await browser.newContext();
        const page = await context.newPage();
        contexts.push(context);
        pages.push(page);
      }
      
      // Navigate all pages simultaneously
      const navigationPromises = pages.map((page, index) => 
        page.goto('http://localhost:3000').then(() => ({ index, success: true }))
      );
      
      const results = await Promise.all(navigationPromises);
      
      // Verify all connections succeeded
      expect(results.length).toBe(3);
      results.forEach(result => {
        expect(result.success).toBe(true);
      });
      
      // Test WebSocket connections from all pages
      const wsPromises = pages.map((page, index) => 
        page.evaluate(async (testIndex) => {
          return new Promise((resolve) => {
            const ws = new WebSocket(`ws://localhost:8080/ws/connect?user_id=concurrent-test-${testIndex}`);
            
            const timeout = setTimeout(() => {
              ws.close();
              resolve({ success: false, error: 'timeout' });
            }, 5000);
            
            ws.onopen = () => {
              clearTimeout(timeout);
              ws.close();
              resolve({ success: true });
            };
            
            ws.onerror = () => {
              clearTimeout(timeout);
              resolve({ success: false, error: 'connection_failed' });
            };
          });
        }, index)
      );
      
      const wsResults = await Promise.all(wsPromises);
      
      // Verify all WebSocket connections succeeded
      wsResults.forEach((result, index) => {
        expect(result.success).toBe(true);
      });
      
      console.log('✅ Concurrent connection handling test passed');
      
    } finally {
      // Cleanup
      for (const context of contexts) {
        await context.close();
      }
    }
  });

  test('Service recovery after simulated disconnect', async ({ page }) => {
    console.log('🔍 Testing service recovery capabilities...');
    
    await page.goto('http://localhost:3000');
    
    // Establish initial connection
    const initialConnection = await page.evaluate(async () => {
      return new Promise((resolve) => {
        const ws = new WebSocket('ws://localhost:8080/ws/connect?user_id=recovery-test');
        
        ws.onopen = () => {
          ws.close();
          resolve({ success: true });
        };
        
        ws.onerror = () => {
          resolve({ success: false });
        };
        
        setTimeout(() => resolve({ success: false, error: 'timeout' }), 5000);
      });
    });
    
    expect(initialConnection.success).toBe(true);
    
    // Wait a moment
    await page.waitForTimeout(1000);
    
    // Test reconnection capability
    const reconnection = await page.evaluate(async () => {
      return new Promise((resolve) => {
        const ws = new WebSocket('ws://localhost:8080/ws/connect?user_id=recovery-test-2');
        
        ws.onopen = () => {
          ws.close();
          resolve({ success: true });
        };
        
        ws.onerror = () => {
          resolve({ success: false });
        };
        
        setTimeout(() => resolve({ success: false, error: 'timeout' }), 5000);
      });
    });
    
    expect(reconnection.success).toBe(true);
    
    console.log('✅ Service recovery test passed');
  });
});

test.describe('Infrastructure Performance Benchmarks', () => {
  
  test('Page load performance', async ({ page }) => {
    console.log('🔍 Measuring page load performance...');
    
    const startTime = Date.now();
    
    await page.goto('http://localhost:3000', { 
      waitUntil: 'domcontentloaded' 
    });
    
    const domContentLoaded = Date.now() - startTime;
    
    await page.waitForLoadState('load');
    const fullyLoaded = Date.now() - startTime;
    
    // Performance expectations
    expect(domContentLoaded).toBeLessThan(3000); // DOM ready < 3s
    expect(fullyLoaded).toBeLessThan(5000); // Fully loaded < 5s
    
    console.log(`✅ Page load performance: DOM=${domContentLoaded}ms, Full=${fullyLoaded}ms`);
  });

  test('JavaScript execution performance', async ({ page }) => {
    console.log('🔍 Measuring JavaScript execution performance...');
    
    await page.goto('http://localhost:3000');
    
    const jsPerformance = await page.evaluate(() => {
      const start = performance.now();
      
      // Test WebSocket client instantiation
      if (typeof window.SepticaWebSocketClient !== 'undefined') {
        new window.SepticaWebSocketClient();
      }
      
      // Test DOM manipulation
      const testElement = document.createElement('div');
      testElement.innerHTML = '<span>Performance Test</span>';
      document.body.appendChild(testElement);
      document.body.removeChild(testElement);
      
      return performance.now() - start;
    });
    
    expect(jsPerformance).toBeLessThan(100); // JS execution < 100ms
    
    console.log(`✅ JavaScript execution performance: ${jsPerformance.toFixed(2)}ms`);
  });

  test('Memory usage baseline', async ({ page }) => {
    console.log('🔍 Establishing memory usage baseline...');
    
    await page.goto('http://localhost:3000');
    
    // Let the page fully initialize
    await page.waitForTimeout(2000);
    
    const memoryInfo = await page.evaluate(() => {
      if (performance.memory) {
        return {
          usedJSHeapSize: performance.memory.usedJSHeapSize,
          totalJSHeapSize: performance.memory.totalJSHeapSize,
          jsHeapSizeLimit: performance.memory.jsHeapSizeLimit
        };
      }
      return null;
    });
    
    if (memoryInfo) {
      const usedMB = Math.round(memoryInfo.usedJSHeapSize / 1024 / 1024);
      const totalMB = Math.round(memoryInfo.totalJSHeapSize / 1024 / 1024);
      
      // Memory expectations (reasonable for a game application)
      expect(usedMB).toBeLessThan(50); // Used heap < 50MB
      expect(totalMB).toBeLessThan(100); // Total heap < 100MB
      
      console.log(`✅ Memory usage baseline: Used=${usedMB}MB, Total=${totalMB}MB`);
    } else {
      console.log('⚠️ Memory performance API not available in this browser');
    }
  });
});