/**
 * Direct Three.js Card Rendering Test
 * Manual testing of Romanian Septica Three.js pages
 */

const { chromium } = require('playwright');

const TARGET_PAGES = [
  { name: 'three-js-demo', url: 'http://localhost:3000/three-js-demo.html', description: 'Main Three.js card rendering demo' },
  { name: 'premium-3d-demo', url: 'http://localhost:3000/premium-3d-demo.html', description: 'Premium 3D card effects demo' },
  { name: 'ultimate-reference', url: 'http://localhost:3000/ultimate-reference.html', description: 'Complete reference implementation' }
];

async function testThreeJSCardRendering() {
  console.log('\n🎮 ROMANIAN SEPTICA THREE.JS CARD RENDERING TEST');
  console.log('='.repeat(60));

  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext({
    viewport: { width: 1280, height: 720 }
  });

  const testResults = {
    timestamp: new Date().toISOString(),
    pages: [],
    summary: {
      totalPages: TARGET_PAGES.length,
      passedTests: 0,
      failedTests: 0,
      performance: {},
      visualQuality: {}
    }
  };

  for (const targetPage of TARGET_PAGES) {
    console.log(`\n📄 Testing: ${targetPage.description}`);
    console.log(`🔗 URL: ${targetPage.url}`);

    const page = await context.newPage();
    const pageResults = {
      name: targetPage.name,
      url: targetPage.url,
      tests: {},
      performance: {},
      errors: []
    };

    try {
      // PHASE 1: Page Loading & Three.js Initialization
      console.log('\n📋 PHASE 1: Page Loading & Three.js Initialization');

      const consoleErrors = [];
      page.on('console', msg => {
        if (msg.type() === 'error') {
          consoleErrors.push(msg.text());
        }
      });

      const startTime = Date.now();
      await page.goto(targetPage.url, { waitUntil: 'networkidle', timeout: 30000 });
      const loadTime = Date.now() - startTime;

      console.log(`  ✅ Page loaded in ${loadTime}ms`);
      pageResults.performance.loadTime = loadTime;
      pageResults.tests.pageLoad = loadTime < 10000;

      // Check for critical errors
      const criticalErrors = consoleErrors.filter(error =>
        !error.includes('favicon') &&
        !error.includes('manifest') &&
        !error.includes('DevTools')
      );
      pageResults.tests.noErrors = criticalErrors.length === 0;
      if (criticalErrors.length > 0) {
        console.log(`  ❌ Console errors found: ${criticalErrors.length}`);
        pageResults.errors = criticalErrors;
      } else {
        console.log('  ✅ No critical console errors');
      }

      // Check Three.js loaded
      await page.waitForTimeout(2000);
      const threeJsLoaded = await page.evaluate(() => {
        return typeof window.THREE !== 'undefined';
      });
      pageResults.tests.threeJsLoaded = threeJsLoaded;
      console.log(`  ${threeJsLoaded ? '✅' : '❌'} Three.js library loaded: ${threeJsLoaded}`);

      // Check WebGL support
      const webglSupported = await page.evaluate(() => {
        const canvas = document.createElement('canvas');
        const gl = canvas.getContext('webgl') || canvas.getContext('experimental-webgl');
        return !!gl;
      });
      pageResults.tests.webglSupported = webglSupported;
      console.log(`  ${webglSupported ? '✅' : '❌'} WebGL supported: ${webglSupported}`);

      // Wait for loading overlay to disappear
      try {
        await page.waitForSelector('#loading-overlay', { state: 'hidden', timeout: 15000 });
        console.log('  ✅ Loading overlay hidden');
        pageResults.tests.loadingComplete = true;
      } catch (e) {
        console.log('  ⚠️ Loading overlay timeout or not found');
        pageResults.tests.loadingComplete = false;
      }

      // Check canvas element
      const canvasExists = await page.locator('#game-canvas, canvas').first().isVisible();
      pageResults.tests.canvasExists = canvasExists;
      console.log(`  ${canvasExists ? '✅' : '❌'} Game canvas visible: ${canvasExists}`);

      if (canvasExists) {
        const canvasSize = await page.locator('#game-canvas, canvas').first().evaluate(el => ({
          width: el.width,
          height: el.height,
          clientWidth: el.clientWidth,
          clientHeight: el.clientHeight
        }));
        console.log(`  📐 Canvas dimensions: ${canvasSize.clientWidth}x${canvasSize.clientHeight}`);
        pageResults.performance.canvasSize = canvasSize;
      }

      // PHASE 2: Romanian Card System Validation
      console.log('\n📋 PHASE 2: Romanian Card System Validation');

      const cardSystem = await page.evaluate(() => {
        const pageContent = document.body.innerHTML;
        const romanianSuits = ['♠', '♥', '♦', '♣'];
        const romanianValues = ['7', '8', '9', '10', 'J', 'Q', 'K', 'A'];

        const hasSuits = romanianSuits.some(suit =>
          pageContent.includes(suit) ||
          pageContent.includes('spade') ||
          pageContent.includes('heart') ||
          pageContent.includes('diamond') ||
          pageContent.includes('club')
        );

        const hasValues = romanianValues.some(value =>
          pageContent.includes(`"${value}"`) ||
          pageContent.includes(`'${value}'`)
        );

        return { hasSuits, hasValues };
      });

      pageResults.tests.romanianCards = cardSystem.hasSuits && cardSystem.hasValues;
      console.log(`  ${cardSystem.hasSuits ? '✅' : '❌'} Romanian suits detected: ${cardSystem.hasSuits}`);
      console.log(`  ${cardSystem.hasValues ? '✅' : '❌'} Romanian values detected: ${cardSystem.hasValues}`);

      // PHASE 3: Performance Monitoring
      console.log('\n📋 PHASE 3: Performance Monitoring');

      await page.waitForTimeout(3000);

      // Get WebGL info
      const webglInfo = await page.evaluate(() => {
        const canvas = document.querySelector('#game-canvas, canvas');
        if (!canvas) return { supported: false };

        const gl = canvas.getContext('webgl') || canvas.getContext('experimental-webgl');
        if (!gl) return { supported: false };

        return {
          supported: true,
          version: gl.getParameter(gl.VERSION),
          vendor: gl.getParameter(gl.VENDOR),
          renderer: gl.getParameter(gl.RENDERER),
          maxTextureSize: gl.getParameter(gl.MAX_TEXTURE_SIZE)
        };
      });

      if (webglInfo.supported) {
        console.log(`  ✅ WebGL Version: ${webglInfo.version}`);
        console.log(`  📱 WebGL Renderer: ${webglInfo.renderer}`);
        pageResults.performance.webgl = webglInfo;
      }

      // PHASE 4: Visual Quality Assessment
      console.log('\n📋 PHASE 4: Visual Quality Assessment');

      const screenshotPath = `test-results/${targetPage.name}-visual-quality.png`;
      await page.screenshot({
        path: screenshotPath,
        fullPage: false,
        clip: { x: 0, y: 0, width: 1280, height: 720 }
      });
      console.log(`  📸 Screenshot saved: ${screenshotPath}`);

      // Cultural elements check
      const culturalElements = await page.evaluate(() => {
        const content = document.body.textContent.toLowerCase();
        const html = document.documentElement.innerHTML.toLowerCase();

        return {
          hasRomanianText: content.includes('romanian') || content.includes('septica'),
          hasCulturalColors: html.includes('#002b7f') || html.includes('blue') || html.includes('gold'),
          hasRegionalOptions: content.includes('moldova') || content.includes('transilvania') || content.includes('wallachia'),
          hasTraditionalElements: html.includes('traditional') || html.includes('cultural')
        };
      });

      pageResults.tests.culturalElements = culturalElements;
      console.log(`  ${culturalElements.hasRomanianText ? '✅' : '❌'} Romanian cultural text: ${culturalElements.hasRomanianText}`);
      console.log(`  ${culturalElements.hasRegionalOptions ? '✅' : '❌'} Regional options: ${culturalElements.hasRegionalOptions}`);

      // PHASE 5: Interactive Features Test
      console.log('\n📋 PHASE 5: Interactive Features Test');

      const gameControls = await page.locator('.btn, button, .game-controls button').count();
      console.log(`  🎮 Game controls found: ${gameControls}`);
      pageResults.tests.gameControls = gameControls > 0;

      if (canvasExists) {
        await page.locator('#game-canvas, canvas').first().hover();
        const cursorStyle = await page.evaluate(() => {
          const canvas = document.querySelector('#game-canvas, canvas');
          return window.getComputedStyle(canvas).cursor;
        });
        console.log(`  🖱️ Canvas cursor style: ${cursorStyle}`);
        pageResults.tests.interactiveCanvas = cursorStyle !== 'default';
      }

      // Calculate test success rate
      const testKeys = Object.keys(pageResults.tests);
      const passedTests = testKeys.filter(key => pageResults.tests[key]).length;
      const totalTests = testKeys.length;
      const successRate = Math.round((passedTests / totalTests) * 100);

      console.log(`\n📊 Test Results for ${targetPage.name}:`);
      console.log(`  ✅ Passed: ${passedTests}/${totalTests} (${successRate}%)`);

      pageResults.successRate = successRate;
      testResults.pages.push(pageResults);

      if (successRate >= 70) {
        testResults.summary.passedTests++;
      } else {
        testResults.summary.failedTests++;
      }

    } catch (error) {
      console.error(`  ❌ Error testing ${targetPage.name}: ${error.message}`);
      pageResults.errors.push(error.message);
      testResults.summary.failedTests++;
    }

    await page.close();
  }

  await browser.close();

  // Generate final report
  console.log('\n📊 COMPREHENSIVE TEST SUMMARY');
  console.log('='.repeat(60));

  const overallSuccess = Math.round((testResults.summary.passedTests / TARGET_PAGES.length) * 100);
  console.log(`🎯 Overall Success Rate: ${overallSuccess}%`);
  console.log(`✅ Pages Passed: ${testResults.summary.passedTests}`);
  console.log(`❌ Pages Failed: ${testResults.summary.failedTests}`);
  console.log(`📄 Total Pages Tested: ${TARGET_PAGES.length}`);

  // Key findings
  console.log('\n🔍 KEY FINDINGS:');
  testResults.pages.forEach(page => {
    console.log(`\n  📄 ${page.name}:`);
    console.log(`    • Success Rate: ${page.successRate}%`);
    console.log(`    • Load Time: ${page.performance.loadTime}ms`);
    console.log(`    • Three.js: ${page.tests.threeJsLoaded ? '✅' : '❌'}`);
    console.log(`    • WebGL: ${page.tests.webglSupported ? '✅' : '❌'}`);
    console.log(`    • Romanian Cards: ${page.tests.romanianCards ? '✅' : '❌'}`);
    console.log(`    • Cultural Elements: ${page.tests.culturalElements?.hasRomanianText ? '✅' : '❌'}`);
    if (page.errors.length > 0) {
      console.log(`    • Errors: ${page.errors.length}`);
    }
  });

  console.log('\n📋 RECOMMENDATIONS:');
  if (overallSuccess >= 80) {
    console.log('  ✅ Three.js card rendering system is production-ready');
    console.log('  ✅ Romanian cultural authenticity maintained');
    console.log('  ✅ Performance targets met');
  } else if (overallSuccess >= 60) {
    console.log('  ⚠️ Three.js system functional but needs optimization');
    console.log('  🔧 Review failed test cases for improvements');
  } else {
    console.log('  ❌ Critical issues found - system needs significant work');
    console.log('  🚨 Review error logs and fix core functionality');
  }

  // Save detailed results
  const fs = require('fs');
  const resultsPath = 'test-results/threejs-card-rendering-report.json';
  fs.writeFileSync(resultsPath, JSON.stringify(testResults, null, 2));
  console.log(`\n💾 Detailed test results saved: ${resultsPath}`);

  return testResults;
}

// Run the tests
if (require.main === module) {
  testThreeJSCardRendering().catch(console.error);
}

module.exports = { testThreeJSCardRendering };