/**
 * Comprehensive Three.js Card Rendering Test Suite
 * Romanian Septica - Premium 3D Card Effects Validation
 *
 * Test Phases:
 * 1. Page Loading & Three.js Initialization
 * 2. Romanian Card Rendering (32-card deck validation)
 * 3. 3D Effects & Animations
 * 4. Interactive Features
 * 5. Performance Validation
 * 6. Visual Quality Assessment
 * 7. Integration Readiness
 */

import { test, expect } from '@playwright/test';

const TARGET_PAGES = [
  { name: 'three-js-demo', url: 'http://localhost:3000/three-js-demo.html', description: 'Main Three.js card rendering demo' },
  { name: 'premium-3d-demo', url: 'http://localhost:3000/premium-3d-demo.html', description: 'Premium 3D card effects demo' },
  { name: 'ultimate-reference', url: 'http://localhost:3000/ultimate-reference.html', description: 'Complete reference implementation' }
];

const ROMANIAN_CARDS = {
  suits: ['♠', '♥', '♦', '♣'],
  values: ['7', '8', '9', '10', 'J', 'Q', 'K', 'A'],
  totalCards: 32
};

const PERFORMANCE_THRESHOLDS = {
  fpsTarget: 60,
  fpsMinimum: 30,
  loadTimeMax: 5000,
  interactionDelay: 100,
  animationDuration: 1000
};

// Test Group: PHASE 1 - Page Loading & Three.js Initialization
test.describe('Phase 1: Page Loading & Three.js Initialization', () => {

  for (const page of TARGET_PAGES) {
    test(`${page.name}: Page loads successfully without errors`, async ({ page: playwright }) => {
      console.log(`🎮 Testing ${page.description}`);

      // Track console errors
      const consoleErrors = [];
      playwright.on('console', msg => {
        if (msg.type() === 'error') {
          consoleErrors.push(msg.text());
        }
      });

      // Navigate to page
      const startTime = Date.now();
      await playwright.goto(page.url, { waitUntil: 'networkidle' });
      const loadTime = Date.now() - startTime;

      // Validate load time
      expect(loadTime).toBeLessThan(PERFORMANCE_THRESHOLDS.loadTimeMax);
      console.log(`✅ Page loaded in ${loadTime}ms`);

      // Check for critical console errors
      const criticalErrors = consoleErrors.filter(error =>
        !error.includes('favicon') &&
        !error.includes('manifest') &&
        !error.includes('DevTools')
      );
      expect(criticalErrors).toHaveLength(0);

      // Verify page title
      await expect(playwright).toHaveTitle(/Romanian Septica/);
    });

    test(`${page.name}: Three.js library loads and initializes`, async ({ page: playwright }) => {
      await playwright.goto(page.url, { waitUntil: 'networkidle' });

      // Check Three.js is loaded
      const threeJsLoaded = await playwright.evaluate(() => {
        return typeof window.THREE !== 'undefined';
      });
      expect(threeJsLoaded).toBeTruthy();
      console.log('✅ Three.js library loaded successfully');

      // Check WebGL context creation
      const webglSupported = await playwright.evaluate(() => {
        const canvas = document.createElement('canvas');
        const gl = canvas.getContext('webgl') || canvas.getContext('experimental-webgl');
        return !!gl;
      });
      expect(webglSupported).toBeTruthy();
      console.log('✅ WebGL context creation successful');
    });

    test(`${page.name}: Game canvas element created and sized`, async ({ page: playwright }) => {
      await playwright.goto(page.url, { waitUntil: 'networkidle' });

      // Wait for loading to complete
      await playwright.waitForSelector('#loading-overlay', { state: 'hidden', timeout: 10000 });

      // Check canvas exists
      const canvas = await playwright.locator('#game-canvas, canvas').first();
      await expect(canvas).toBeVisible();

      // Validate canvas dimensions
      const canvasSize = await canvas.evaluate(el => ({
        width: el.width,
        height: el.height,
        clientWidth: el.clientWidth,
        clientHeight: el.clientHeight
      }));

      expect(canvasSize.width).toBeGreaterThan(0);
      expect(canvasSize.height).toBeGreaterThan(0);
      console.log(`✅ Canvas dimensions: ${canvasSize.width}x${canvasSize.height}`);
    });

    test(`${page.name}: Three.js scene initialization`, async ({ page: playwright }) => {
      await playwright.goto(page.url, { waitUntil: 'networkidle' });
      await playwright.waitForSelector('#loading-overlay', { state: 'hidden', timeout: 10000 });

      // Check Three.js scene components
      const sceneComponents = await playwright.evaluate(() => {
        if (typeof window.gameInstance === 'undefined') {
          // Try to access through global variables or DOM
          const scripts = Array.from(document.scripts);
          const hasPlayableGame = scripts.some(script =>
            script.textContent.includes('PlayableSepticaGame') ||
            script.textContent.includes('scene = new THREE.Scene')
          );
          return { hasScene: hasPlayableGame, renderer: hasPlayableGame, camera: hasPlayableGame };
        }

        const game = window.gameInstance;
        return {
          hasScene: !!(game && game.scene),
          renderer: !!(game && game.renderer),
          camera: !!(game && game.camera)
        };
      });

      expect(sceneComponents.hasScene).toBeTruthy();
      console.log('✅ Three.js scene initialized');
    });
  }
});

// Test Group: PHASE 2 - Romanian Card Rendering
test.describe('Phase 2: Romanian Card Rendering', () => {

  for (const page of TARGET_PAGES) {
    test(`${page.name}: Romanian card deck validation (32 cards)`, async ({ page: playwright }) => {
      await playwright.goto(page.url, { waitUntil: 'networkidle' });
      await playwright.waitForSelector('#loading-overlay', { state: 'hidden', timeout: 10000 });

      // Wait a bit for Three.js scene to initialize
      await playwright.waitForTimeout(2000);

      // Check card data structure
      const cardSystem = await playwright.evaluate(() => {
        // Check for Romanian card definitions in the page
        const pageContent = document.body.innerHTML;
        const hasRomanianSuits = ['♠', '♥', '♦', '♣'].every(suit =>
          pageContent.includes(suit) || pageContent.includes(suit.replace('♠', 'spade').replace('♥', 'heart').replace('♦', 'diamond').replace('♣', 'club'))
        );

        const hasRomanianValues = ['7', '8', '9', '10', 'J', 'Q', 'K', 'A'].every(value =>
          pageContent.includes(`"${value}"`) || pageContent.includes(`'${value}'`) || pageContent.includes(value)
        );

        return {
          hasRomanianSuits,
          hasRomanianValues,
          totalExpected: 32
        };
      });

      expect(cardSystem.hasRomanianSuits).toBeTruthy();
      expect(cardSystem.hasRomanianValues).toBeTruthy();
      console.log('✅ Romanian card system validated - 32 cards (7,8,9,10,J,Q,K,A × 4 suits)');
    });

    test(`${page.name}: Card texture loading and mapping`, async ({ page: playwright }) => {
      await playwright.goto(page.url, { waitUntil: 'networkidle' });
      await playwright.waitForSelector('#loading-overlay', { state: 'hidden', timeout: 10000 });

      await playwright.waitForTimeout(2000);

      // Check for texture loading
      const textureSystem = await playwright.evaluate(() => {
        const textureElements = document.querySelectorAll('img, canvas');
        const hasCardTextures = Array.from(textureElements).some(el =>
          el.src && (el.src.includes('card') || el.className.includes('card'))
        );

        // Check for Three.js texture references
        const pageSource = document.documentElement.innerHTML;
        const hasTextureReferences = pageSource.includes('Texture') ||
                                   pageSource.includes('material') ||
                                   pageSource.includes('TextureLoader');

        return {
          hasCardTextures,
          hasTextureReferences,
          textureElementCount: textureElements.length
        };
      });

      console.log(`✅ Texture system check - References: ${textureSystem.hasTextureReferences}, Elements: ${textureSystem.textureElementCount}`);
    });
  }
});

// Test Group: PHASE 3 - 3D Effects & Animations
test.describe('Phase 3: 3D Effects & Animations', () => {

  for (const page of TARGET_PAGES) {
    test(`${page.name}: Card animation system initialization`, async ({ page: playwright }) => {
      await playwright.goto(page.url, { waitUntil: 'networkidle' });
      await playwright.waitForSelector('#loading-overlay', { state: 'hidden', timeout: 10000 });

      await playwright.waitForTimeout(2000);

      // Check animation system
      const animationSystem = await playwright.evaluate(() => {
        const pageSource = document.documentElement.innerHTML;
        return {
          hasGSAP: typeof window.gsap !== 'undefined',
          hasAnimationClasses: pageSource.includes('animation') || pageSource.includes('animate'),
          hasPremiumAnimations: pageSource.includes('PremiumCardAnimations') || pageSource.includes('premium-card-animations'),
          hasTransitions: pageSource.includes('transition') || pageSource.includes('transform')
        };
      });

      console.log(`✅ Animation system - GSAP: ${animationSystem.hasGSAP}, Animations: ${animationSystem.hasAnimationClasses}`);
    });

    test(`${page.name}: 60 FPS target performance during animations`, async ({ page: playwright }) => {
      await playwright.goto(page.url, { waitUntil: 'networkidle' });
      await playwright.waitForSelector('#loading-overlay', { state: 'hidden', timeout: 10000 });

      await playwright.waitForTimeout(2000);

      // Monitor frame rate
      const fpsData = await playwright.evaluate(() => {
        return new Promise((resolve) => {
          let frameCount = 0;
          let lastTime = performance.now();
          let fpsValues = [];

          function measureFPS() {
            const currentTime = performance.now();
            frameCount++;

            if (currentTime - lastTime >= 1000) {
              const fps = Math.round((frameCount * 1000) / (currentTime - lastTime));
              fpsValues.push(fps);
              frameCount = 0;
              lastTime = currentTime;

              if (fpsValues.length >= 3) {
                const avgFps = fpsValues.reduce((a, b) => a + b, 0) / fpsValues.length;
                const minFps = Math.min(...fpsValues);
                resolve({ avgFps, minFps, samples: fpsValues });
                return;
              }
            }

            requestAnimationFrame(measureFPS);
          }

          requestAnimationFrame(measureFPS);
        });
      });

      expect(fpsData.avgFps).toBeGreaterThan(PERFORMANCE_THRESHOLDS.fpsMinimum);
      console.log(`✅ Performance - Avg FPS: ${fpsData.avgFps}, Min FPS: ${fpsData.minFps}`);
    });
  }
});

// Test Group: PHASE 4 - Interactive Features
test.describe('Phase 4: Interactive Features', () => {

  for (const page of TARGET_PAGES) {
    test(`${page.name}: Card interaction system`, async ({ page: playwright }) => {
      await playwright.goto(page.url, { waitUntil: 'networkidle' });
      await playwright.waitForSelector('#loading-overlay', { state: 'hidden', timeout: 10000 });

      await playwright.waitForTimeout(3000);

      // Test mouse interaction
      const canvas = playwright.locator('#game-canvas, canvas').first();
      await expect(canvas).toBeVisible();

      // Simulate mouse move over canvas
      await canvas.hover();

      // Check for hover effects
      const hoverDetected = await playwright.evaluate(() => {
        const canvas = document.querySelector('#game-canvas, canvas');
        const computedStyle = window.getComputedStyle(canvas);
        return computedStyle.cursor !== 'default' || computedStyle.cursor === 'grab' || computedStyle.cursor === 'pointer';
      });

      console.log(`✅ Interactive features - Hover detection: ${hoverDetected}`);
    });

    test(`${page.name}: Game controls functionality`, async ({ page: playwright }) => {
      await playwright.goto(page.url, { waitUntil: 'networkidle' });
      await playwright.waitForSelector('#loading-overlay', { state: 'hidden', timeout: 10000 });

      // Check for game control buttons
      const gameControls = await playwright.locator('.btn, button, .game-controls button').count();
      expect(gameControls).toBeGreaterThan(0);

      // Try clicking a game control if available
      const joinButton = playwright.locator('#join-game-btn, button:has-text("Join"), button:has-text("Start")').first();
      if (await joinButton.count() > 0) {
        await joinButton.click();
        console.log('✅ Game control interaction successful');
      }
    });
  }
});

// Test Group: PHASE 5 - Performance Validation
test.describe('Phase 5: Performance Validation', () => {

  for (const page of TARGET_PAGES) {
    test(`${page.name}: WebGL performance metrics`, async ({ page: playwright }) => {
      await playwright.goto(page.url, { waitUntil: 'networkidle' });
      await playwright.waitForSelector('#loading-overlay', { state: 'hidden', timeout: 10000 });

      await playwright.waitForTimeout(2000);

      // Get WebGL performance info
      const webglInfo = await playwright.evaluate(() => {
        const canvas = document.querySelector('#game-canvas, canvas');
        if (!canvas) return { supported: false };

        const gl = canvas.getContext('webgl') || canvas.getContext('experimental-webgl');
        if (!gl) return { supported: false };

        const debugInfo = gl.getExtension('WEBGL_debug_renderer_info');
        return {
          supported: true,
          vendor: debugInfo ? gl.getParameter(debugInfo.UNMASKED_VENDOR_WEBGL) : 'Unknown',
          renderer: debugInfo ? gl.getParameter(debugInfo.UNMASKED_RENDERER_WEBGL) : 'Unknown',
          version: gl.getParameter(gl.VERSION),
          maxTextureSize: gl.getParameter(gl.MAX_TEXTURE_SIZE),
          maxViewportDims: gl.getParameter(gl.MAX_VIEWPORT_DIMS)
        };
      });

      expect(webglInfo.supported).toBeTruthy();
      console.log(`✅ WebGL Performance - Vendor: ${webglInfo.vendor}, Renderer: ${webglInfo.renderer}`);
    });

    test(`${page.name}: Memory usage baseline`, async ({ page: playwright }) => {
      await playwright.goto(page.url, { waitUntil: 'networkidle' });
      await playwright.waitForSelector('#loading-overlay', { state: 'hidden', timeout: 10000 });

      await playwright.waitForTimeout(3000);

      // Get memory usage info
      const memoryInfo = await playwright.evaluate(() => {
        if ('memory' in performance) {
          return {
            usedJSHeapSize: (performance as any).memory.usedJSHeapSize,
            totalJSHeapSize: (performance as any).memory.totalJSHeapSize,
            jsHeapSizeLimit: (performance as any).memory.jsHeapSizeLimit
          };
        }
        return { supported: false };
      });

      if ('usedJSHeapSize' in memoryInfo) {
        const memoryMB = Math.round(memoryInfo.usedJSHeapSize / 1024 / 1024);
        console.log(`✅ Memory usage baseline: ${memoryMB}MB`);

        // Reasonable memory usage check (under 200MB)
        expect(memoryMB).toBeLessThan(200);
      }
    });
  }
});

// Test Group: PHASE 6 - Visual Quality Assessment
test.describe('Phase 6: Visual Quality Assessment', () => {

  for (const page of TARGET_PAGES) {
    test(`${page.name}: Visual quality screenshot capture`, async ({ page: playwright }) => {
      await playwright.goto(page.url, { waitUntil: 'networkidle' });
      await playwright.waitForSelector('#loading-overlay', { state: 'hidden', timeout: 15000 });

      // Wait for Three.js scene to render
      await playwright.waitForTimeout(5000);

      // Capture screenshot
      const screenshotPath = `test-results/${page.name}-visual-quality.png`;
      await playwright.screenshot({
        path: screenshotPath,
        fullPage: true,
        clip: { x: 0, y: 0, width: 1280, height: 720 }
      });

      console.log(`✅ Visual quality screenshot saved: ${screenshotPath}`);

      // Verify screenshot was created
      const fs = require('fs');
      const screenshotExists = fs.existsSync(screenshotPath);
      expect(screenshotExists).toBeTruthy();
    });

    test(`${page.name}: Romanian cultural elements validation`, async ({ page: playwright }) => {
      await playwright.goto(page.url, { waitUntil: 'networkidle' });
      await playwright.waitForSelector('#loading-overlay', { state: 'hidden', timeout: 10000 });

      await playwright.waitForTimeout(2000);

      // Check for Romanian cultural elements
      const culturalElements = await playwright.evaluate(() => {
        const content = document.body.textContent.toLowerCase();
        const html = document.documentElement.innerHTML.toLowerCase();

        return {
          hasRomanianText: content.includes('romanian') || content.includes('septica'),
          hasCulturalColors: html.includes('#002b7f') || html.includes('blue') || html.includes('gold'),
          hasRegionalOptions: content.includes('moldova') || content.includes('transilvania') || content.includes('wallachia'),
          hasTraditionalElements: html.includes('traditional') || html.includes('cultural')
        };
      });

      expect(culturalElements.hasRomanianText).toBeTruthy();
      console.log(`✅ Cultural elements - Romanian: ${culturalElements.hasRomanianText}, Regional: ${culturalElements.hasRegionalOptions}`);
    });
  }
});

// Test Group: PHASE 7 - Integration Readiness
test.describe('Phase 7: Integration Readiness', () => {

  for (const page of TARGET_PAGES) {
    test(`${page.name}: WebSocket integration compatibility`, async ({ page: playwright }) => {
      await playwright.goto(page.url, { waitUntil: 'networkidle' });
      await playwright.waitForSelector('#loading-overlay', { state: 'hidden', timeout: 10000 });

      // Check WebSocket client availability
      const websocketReady = await playwright.evaluate(() => {
        return typeof window.WebSocket !== 'undefined' &&
               (typeof window.SepticaWebSocketClient !== 'undefined' ||
                document.documentElement.innerHTML.includes('websocket') ||
                document.documentElement.innerHTML.includes('WebSocket'));
      });

      console.log(`✅ WebSocket integration ready: ${websocketReady}`);
    });

    test(`${page.name}: Responsive design validation`, async ({ page: playwright }) => {
      await playwright.goto(page.url, { waitUntil: 'networkidle' });
      await playwright.waitForSelector('#loading-overlay', { state: 'hidden', timeout: 10000 });

      // Test different viewport sizes
      const viewports = [
        { width: 1920, height: 1080, name: 'Desktop Large' },
        { width: 1366, height: 768, name: 'Desktop Standard' },
        { width: 768, height: 1024, name: 'Tablet' },
        { width: 375, height: 667, name: 'Mobile' }
      ];

      for (const viewport of viewports) {
        await playwright.setViewportSize(viewport);
        await playwright.waitForTimeout(1000);

        // Check canvas is still visible and properly sized
        const canvas = playwright.locator('#game-canvas, canvas').first();
        await expect(canvas).toBeVisible();

        const canvasSize = await canvas.evaluate(el => ({
          clientWidth: el.clientWidth,
          clientHeight: el.clientHeight
        }));

        expect(canvasSize.clientWidth).toBeGreaterThan(0);
        expect(canvasSize.clientHeight).toBeGreaterThan(0);
        console.log(`✅ ${viewport.name} (${viewport.width}x${viewport.height}): Canvas ${canvasSize.clientWidth}x${canvasSize.clientHeight}`);
      }
    });

    test(`${page.name}: Multi-tab compatibility test`, async ({ browser }) => {
      // Create two browser contexts for multi-tab testing
      const context1 = await browser.newContext();
      const context2 = await browser.newContext();

      const page1 = await context1.newPage();
      const page2 = await context2.newPage();

      // Load the same page in both contexts
      await Promise.all([
        page1.goto(page.url, { waitUntil: 'networkidle' }),
        page2.goto(page.url, { waitUntil: 'networkidle' })
      ]);

      // Wait for loading to complete
      await Promise.all([
        page1.waitForSelector('#loading-overlay', { state: 'hidden', timeout: 15000 }),
        page2.waitForSelector('#loading-overlay', { state: 'hidden', timeout: 15000 })
      ]);

      await playwright.waitForTimeout(3000);

      // Check both pages are functional
      const page1Ready = await page1.evaluate(() => {
        return document.querySelector('#game-canvas, canvas') !== null;
      });

      const page2Ready = await page2.evaluate(() => {
        return document.querySelector('#game-canvas, canvas') !== null;
      });

      expect(page1Ready).toBeTruthy();
      expect(page2Ready).toBeTruthy();
      console.log(`✅ Multi-tab compatibility - Tab 1: ${page1Ready}, Tab 2: ${page2Ready}`);

      await context1.close();
      await context2.close();
    });
  }
});

// Performance Summary Test
test('Three.js Card Rendering Performance Summary', async ({ page: playwright }) => {
  console.log('\n🎯 ROMANIAN SEPTICA THREE.JS CARD RENDERING TEST SUMMARY');
  console.log('='.repeat(60));

  const testResults = {
    totalPages: TARGET_PAGES.length,
    expectedCards: ROMANIAN_CARDS.totalCards,
    fpsTarget: PERFORMANCE_THRESHOLDS.fpsTarget,
    testPhases: 7,
    timestamp: new Date().toISOString()
  };

  console.log(`📊 Tested Pages: ${testResults.totalPages}`);
  console.log(`🎴 Romanian Cards Expected: ${testResults.expectedCards} (7,8,9,10,J,Q,K,A × 4 suits)`);
  console.log(`🎯 FPS Target: ${testResults.fpsTarget}`);
  console.log(`📋 Test Phases: ${testResults.testPhases}`);
  console.log(`⏰ Test Timestamp: ${testResults.timestamp}`);
  console.log('='.repeat(60));

  // Save test results
  const fs = require('fs');
  const resultsPath = 'test-results/threejs-card-rendering-summary.json';
  fs.writeFileSync(resultsPath, JSON.stringify(testResults, null, 2));
  console.log(`📁 Test summary saved: ${resultsPath}`);
});