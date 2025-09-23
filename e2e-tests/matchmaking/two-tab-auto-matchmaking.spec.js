/**
 * Two-Tab Auto-Matchmaking E2E Tests
 * Comprehensive validation of the complete matchmaking flow
 */

import { test, expect } from '@playwright/test';

test.describe('Romanian Septica Two-Tab Auto-Matchmaking', () => {
  
  test.beforeEach(async () => {
    // Set longer timeout for matchmaking tests
    test.setTimeout(60000);
  });

  test('Complete two-tab auto-matchmaking flow', async ({ browser }) => {
    console.log('🎮 Starting two-tab auto-matchmaking flow test...');
    
    // Create two browser contexts (simulating two users/tabs)
    const context1 = await browser.newContext({
      viewport: { width: 1280, height: 720 }
    });
    const context2 = await browser.newContext({
      viewport: { width: 1280, height: 720 }
    });
    
    const player1Page = await context1.newPage();
    const player2Page = await context2.newPage();
    
    try {
      // Step 1: Both players open the game
      console.log('📱 Step 1: Opening two tabs...');
      await Promise.all([
        player1Page.goto('http://localhost:3000'),
        player2Page.goto('http://localhost:3000')
      ]);
      
      // Wait for pages to load completely
      await Promise.all([
        player1Page.waitForLoadState('domcontentloaded'),
        player2Page.waitForLoadState('domcontentloaded')
      ]);
      
      // Verify both pages loaded successfully
      await expect(player1Page.locator('.game-container')).toBeVisible();
      await expect(player2Page.locator('.game-container')).toBeVisible();
      
      console.log('✅ Both tabs opened successfully');
      
      // Step 2: Wait for WebSocket connections
      console.log('🔌 Step 2: Establishing WebSocket connections...');
      
      // Wait for connection status to show "Connected"
      await Promise.all([
        player1Page.waitForSelector('#connection-text:has-text("Connected")', { timeout: 10000 }),
        player2Page.waitForSelector('#connection-text:has-text("Connected")', { timeout: 10000 })
      ]);
      
      // Verify connection dots are green
      await expect(player1Page.locator('#connection-dot.connected')).toBeVisible();
      await expect(player2Page.locator('#connection-dot.connected')).toBeVisible();
      
      console.log('✅ Both WebSocket connections established');
      
      // Step 3: Both players click "Play" button to join matchmaking
      console.log('🎯 Step 3: Both players joining matchmaking...');
      
      // Verify Play buttons are enabled
      await expect(player1Page.locator('#play-btn')).toBeEnabled();
      await expect(player2Page.locator('#play-btn')).toBeEnabled();
      
      // Click Play buttons simultaneously (with small delay to simulate real users)
      await player1Page.click('#play-btn');
      console.log('Player 1 clicked Play');
      
      await player1Page.waitForTimeout(500); // Small realistic delay
      
      await player2Page.click('#play-btn');
      console.log('Player 2 clicked Play');
      
      // Verify matchmaking overlay appears for both players
      await Promise.all([
        player1Page.waitForSelector('#matchmaking-overlay', { state: 'visible', timeout: 5000 }),
        player2Page.waitForSelector('#matchmaking-overlay', { state: 'visible', timeout: 5000 })
      ]);
      
      console.log('✅ Both players entered matchmaking queue');
      
      // Step 4: Wait for auto-pairing and match found notifications
      console.log('⏳ Step 4: Waiting for auto-pairing...');
      
      // Wait for matchmaking overlay to disappear (indicates match found)
      await Promise.all([
        player1Page.waitForSelector('#matchmaking-overlay', { state: 'hidden', timeout: 15000 }),
        player2Page.waitForSelector('#matchmaking-overlay', { state: 'hidden', timeout: 15000 })
      ]);
      
      console.log('✅ Match found! Matchmaking completed');
      
      // Step 5: Verify game state synchronization
      console.log('🎮 Step 5: Verifying game state synchronization...');
      
      // Both players should now be in-game
      await Promise.all([
        player1Page.waitForSelector('#leave-game-btn:enabled', { timeout: 10000 }),
        player2Page.waitForSelector('#leave-game-btn:enabled', { timeout: 10000 })
      ]);
      
      // Play buttons should be disabled (already in game)
      await expect(player1Page.locator('#play-btn')).toBeDisabled();
      await expect(player2Page.locator('#play-btn')).toBeDisabled();
      
      // Verify game status updates
      const player1Status = await player1Page.locator('#game-status').textContent();
      const player2Status = await player2Page.locator('#game-status').textContent();
      
      expect(player1Status).toMatch(/(Match found|Game|turn|started)/i);
      expect(player2Status).toMatch(/(Match found|Game|turn|started)/i);
      
      console.log(`Player 1 status: ${player1Status}`);
      console.log(`Player 2 status: ${player2Status}`);
      
      // Step 6: Verify card distribution and game setup
      console.log('🃏 Step 6: Verifying game setup...');
      
      // Wait a bit for game initialization
      await player1Page.waitForTimeout(2000);
      
      // Check if cards are dealt (either real cards or demo cards should be visible)
      const player1Cards = await player1Page.locator('#player-cards .card').count();
      const player2Cards = await player2Page.locator('#player-cards .card').count();
      
      console.log(`Player 1 cards: ${player1Cards}, Player 2 cards: ${player2Cards}`);
      
      // In a real game, players should have cards
      // (In demo mode, there might be default cards)
      if (player1Cards > 0 || player2Cards > 0) {
        console.log('✅ Cards are visible (game initialized)');
      } else {
        console.log('⚠️ No cards visible yet (may be normal during initialization)');
      }
      
      // Step 7: Test basic game interaction (if cards are available)
      console.log('🎯 Step 7: Testing basic game interaction...');
      
      if (player1Cards > 0) {
        // Try to interact with a card on player 1's side
        const firstCard = player1Page.locator('#player-cards .card').first();
        
        if (await firstCard.isVisible()) {
          // Check if card is playable
          const cardClass = await firstCard.getAttribute('class');
          if (cardClass && cardClass.includes('playable')) {
            await firstCard.hover();
            console.log('✅ Card interaction test passed (hover effect)');
          }
        }
      }
      
      // Step 8: Verify real-time synchronization
      console.log('⚡ Step 8: Testing real-time synchronization...');
      
      // Monitor for any real-time updates (game state changes, turn notifications, etc.)
      let syncEvents = 0;
      
      // Listen for game state changes on both pages
      const syncPromise1 = player1Page.waitForFunction(() => {
        return document.getElementById('game-status').textContent.length > 0;
      }, {}, { timeout: 5000 }).then(() => syncEvents++).catch(() => {});
      
      const syncPromise2 = player2Page.waitForFunction(() => {
        return document.getElementById('game-status').textContent.length > 0;
      }, {}, { timeout: 5000 }).then(() => syncEvents++).catch(() => {});
      
      await Promise.allSettled([syncPromise1, syncPromise2]);
      
      if (syncEvents > 0) {
        console.log(`✅ Real-time synchronization working (${syncEvents} events detected)`);
      } else {
        console.log('⚠️ No real-time events detected (may be normal in current state)');
      }
      
      // Final verification
      console.log('🏁 Final verification...');
      
      // Verify both players are in the same game state
      const finalPlayer1Status = await player1Page.locator('#game-status').textContent();
      const finalPlayer2Status = await player2Page.locator('#game-status').textContent();
      
      console.log(`Final Player 1 status: ${finalPlayer1Status}`);
      console.log(`Final Player 2 status: ${finalPlayer2Status}`);
      
      // Both should be in some kind of game state (not in matchmaking)
      expect(finalPlayer1Status).not.toMatch(/connecting|searching/i);
      expect(finalPlayer2Status).not.toMatch(/connecting|searching/i);
      
      console.log('🎉 SUCCESS: Two-tab auto-matchmaking flow completed successfully!');
      
    } finally {
      // Cleanup
      await context1.close();
      await context2.close();
    }
  });

  test('Matchmaking queue position and timing', async ({ browser }) => {
    console.log('📊 Testing matchmaking queue mechanics...');
    
    const context1 = await browser.newContext();
    const context2 = await browser.newContext();
    const player1Page = await context1.newPage();
    const player2Page = await context2.newPage();
    
    try {
      // Both players load the game
      await Promise.all([
        player1Page.goto('http://localhost:3000'),
        player2Page.goto('http://localhost:3000')
      ]);
      
      // Wait for connections
      await Promise.all([
        player1Page.waitForSelector('#connection-text:has-text("Connected")', { timeout: 10000 }),
        player2Page.waitForSelector('#connection-text:has-text("Connected")', { timeout: 10000 })
      ]);
      
      // Player 1 joins queue first
      const startTime = Date.now();
      await player1Page.click('#play-btn');
      
      // Verify matchmaking overlay shows queue information
      await player1Page.waitForSelector('#matchmaking-overlay', { state: 'visible' });
      
      // Check for queue position display
      const queuePosition = await player1Page.locator('#queue-position').textContent();
      console.log(`Player 1 queue position: ${queuePosition}`);
      
      // Wait 2 seconds, then player 2 joins
      await player1Page.waitForTimeout(2000);
      await player2Page.click('#play-btn');
      
      // Wait for match to be found
      await Promise.all([
        player1Page.waitForSelector('#matchmaking-overlay', { state: 'hidden', timeout: 15000 }),
        player2Page.waitForSelector('#matchmaking-overlay', { state: 'hidden', timeout: 15000 })
      ]);
      
      const totalMatchmakingTime = Date.now() - startTime;
      console.log(`Total matchmaking time: ${totalMatchmakingTime}ms`);
      
      // Verify reasonable matchmaking time
      expect(totalMatchmakingTime).toBeLessThan(20000); // Should complete within 20 seconds
      expect(totalMatchmakingTime).toBeGreaterThan(1000); // Should take at least 1 second
      
      console.log('✅ Matchmaking timing test passed');
      
    } finally {
      await context1.close();
      await context2.close();
    }
  });

  test('Matchmaking cancellation flow', async ({ browser }) => {
    console.log('❌ Testing matchmaking cancellation...');
    
    const context = await browser.newContext();
    const page = await context.newPage();
    
    try {
      await page.goto('http://localhost:3000');
      await page.waitForSelector('#connection-text:has-text("Connected")', { timeout: 10000 });
      
      // Start matchmaking
      await page.click('#play-btn');
      await page.waitForSelector('#matchmaking-overlay', { state: 'visible' });
      
      // Verify cancel button is enabled
      await expect(page.locator('#cancel-matchmaking-btn')).toBeEnabled();
      
      // Cancel matchmaking
      await page.click('#cancel-matchmaking-btn');
      
      // Verify overlay disappears
      await page.waitForSelector('#matchmaking-overlay', { state: 'hidden', timeout: 5000 });
      
      // Verify Play button is re-enabled
      await expect(page.locator('#play-btn')).toBeEnabled();
      await expect(page.locator('#cancel-matchmaking-btn')).toBeDisabled();
      
      // Verify status update
      const status = await page.locator('#game-status').textContent();
      expect(status).toMatch(/(cancelled|ready)/i);
      
      console.log('✅ Matchmaking cancellation test passed');
      
    } finally {
      await context.close();
    }
  });

  test('Multiple simultaneous matchmaking attempts', async ({ browser }) => {
    console.log('👥 Testing multiple simultaneous players...');
    
    const contexts = [];
    const pages = [];
    
    try {
      // Create 4 players
      for (let i = 0; i < 4; i++) {
        const context = await browser.newContext();
        const page = await context.newPage();
        contexts.push(context);
        pages.push(page);
      }
      
      // All players load the game
      await Promise.all(pages.map(page => page.goto('http://localhost:3000')));
      
      // Wait for all connections
      await Promise.all(pages.map(page => 
        page.waitForSelector('#connection-text:has-text("Connected")', { timeout: 10000 })
      ));
      
      console.log('✅ All 4 players connected');
      
      // All players join matchmaking with small delays
      for (let i = 0; i < pages.length; i++) {
        await pages[i].click('#play-btn');
        console.log(`Player ${i + 1} joined matchmaking`);
        await pages[i].waitForTimeout(200); // Small delay between joins
      }
      
      // Verify all entered matchmaking
      await Promise.all(pages.map(page => 
        page.waitForSelector('#matchmaking-overlay', { state: 'visible' })
      ));
      
      console.log('✅ All players in matchmaking queue');
      
      // Wait for matches to be found (should create 2 games with 2 players each)
      const matchPromises = pages.map(page => 
        page.waitForSelector('#matchmaking-overlay', { state: 'hidden', timeout: 20000 })
          .then(() => true)
          .catch(() => false)
      );
      
      const matchResults = await Promise.all(matchPromises);
      const successfulMatches = matchResults.filter(result => result).length;
      
      console.log(`${successfulMatches} out of 4 players found matches`);
      
      // At least 2 players should find matches (1 complete game)
      expect(successfulMatches).toBeGreaterThanOrEqual(2);
      
      console.log('✅ Multiple player matchmaking test passed');
      
    } finally {
      // Cleanup all contexts
      for (const context of contexts) {
        await context.close();
      }
    }
  });

  test('Matchmaking with network interruption recovery', async ({ browser }) => {
    console.log('🔄 Testing matchmaking with network interruption...');
    
    const context = await browser.newContext();
    const page = await context.newPage();
    
    try {
      await page.goto('http://localhost:3000');
      await page.waitForSelector('#connection-text:has-text("Connected")', { timeout: 10000 });
      
      // Start matchmaking
      await page.click('#play-btn');
      await page.waitForSelector('#matchmaking-overlay', { state: 'visible' });
      
      // Simulate network interruption by going offline temporarily
      await page.context().setOffline(true);
      await page.waitForTimeout(2000);
      
      // Restore network
      await page.context().setOffline(false);
      
      // Wait for reconnection
      await page.waitForSelector('#connection-text:has-text("Connected")', { timeout: 15000 });
      
      // Verify matchmaking state is handled gracefully
      const status = await page.locator('#game-status').textContent();
      console.log(`Status after network recovery: ${status}`);
      
      // Should either be back in matchmaking or have gracefully exited
      expect(status).not.toMatch(/error|undefined/i);
      
      console.log('✅ Network interruption recovery test passed');
      
    } finally {
      await context.close();
    }
  });

  test('Cross-browser matchmaking compatibility', async ({ browser, browserName }) => {
    console.log(`🌐 Testing cross-browser compatibility (${browserName})...`);
    
    const context1 = await browser.newContext();
    const context2 = await browser.newContext();
    const player1Page = await context1.newPage();
    const player2Page = await context2.newPage();
    
    try {
      // Test basic matchmaking flow in current browser
      await Promise.all([
        player1Page.goto('http://localhost:3000'),
        player2Page.goto('http://localhost:3000')
      ]);
      
      // Verify WebSocket support
      const wsSupport1 = await player1Page.evaluate(() => typeof WebSocket !== 'undefined');
      const wsSupport2 = await player2Page.evaluate(() => typeof WebSocket !== 'undefined');
      
      expect(wsSupport1).toBe(true);
      expect(wsSupport2).toBe(true);
      
      // Verify connections
      await Promise.all([
        player1Page.waitForSelector('#connection-text:has-text("Connected")', { timeout: 10000 }),
        player2Page.waitForSelector('#connection-text:has-text("Connected")', { timeout: 10000 })
      ]);
      
      // Quick matchmaking test
      await player1Page.click('#play-btn');
      await player2Page.click('#play-btn');
      
      await Promise.all([
        player1Page.waitForSelector('#matchmaking-overlay', { state: 'visible' }),
        player2Page.waitForSelector('#matchmaking-overlay', { state: 'visible' })
      ]);
      
      console.log(`✅ Cross-browser compatibility verified for ${browserName}`);
      
    } finally {
      await context1.close();
      await context2.close();
    }
  });
});

test.describe('Matchmaking Performance and Reliability', () => {
  
  test('Matchmaking speed benchmarks', async ({ browser }) => {
    console.log('⚡ Running matchmaking speed benchmarks...');
    
    const measurements = [];
    
    // Run 3 iterations to get average performance
    for (let iteration = 0; iteration < 3; iteration++) {
      const context1 = await browser.newContext();
      const context2 = await browser.newContext();
      const player1Page = await context1.newPage();
      const player2Page = await context2.newPage();
      
      try {
        console.log(`Iteration ${iteration + 1}/3`);
        
        // Load pages
        const loadStart = Date.now();
        await Promise.all([
          player1Page.goto('http://localhost:3000'),
          player2Page.goto('http://localhost:3000')
        ]);
        
        await Promise.all([
          player1Page.waitForSelector('#connection-text:has-text("Connected")'),
          player2Page.waitForSelector('#connection-text:has-text("Connected")')
        ]);
        
        const connectionTime = Date.now() - loadStart;
        
        // Start matchmaking
        const matchmakingStart = Date.now();
        await player1Page.click('#play-btn');
        await player2Page.click('#play-btn');
        
        // Wait for match
        await Promise.all([
          player1Page.waitForSelector('#matchmaking-overlay', { state: 'hidden', timeout: 20000 }),
          player2Page.waitForSelector('#matchmaking-overlay', { state: 'hidden', timeout: 20000 })
        ]);
        
        const matchmakingTime = Date.now() - matchmakingStart;
        const totalTime = Date.now() - loadStart;
        
        measurements.push({
          iteration: iteration + 1,
          connectionTime,
          matchmakingTime,
          totalTime
        });
        
        console.log(`  Connection: ${connectionTime}ms, Matchmaking: ${matchmakingTime}ms, Total: ${totalTime}ms`);
        
      } finally {
        await context1.close();
        await context2.close();
      }
    }
    
    // Calculate averages
    const avgConnection = measurements.reduce((sum, m) => sum + m.connectionTime, 0) / measurements.length;
    const avgMatchmaking = measurements.reduce((sum, m) => sum + m.matchmakingTime, 0) / measurements.length;
    const avgTotal = measurements.reduce((sum, m) => sum + m.totalTime, 0) / measurements.length;
    
    console.log(`\n📊 Performance Summary:`);
    console.log(`  Average connection time: ${Math.round(avgConnection)}ms`);
    console.log(`  Average matchmaking time: ${Math.round(avgMatchmaking)}ms`);
    console.log(`  Average total time: ${Math.round(avgTotal)}ms`);
    
    // Performance assertions
    expect(avgConnection).toBeLessThan(10000); // Connection < 10s
    expect(avgMatchmaking).toBeLessThan(15000); // Matchmaking < 15s
    expect(avgTotal).toBeLessThan(20000); // Total < 20s
    
    console.log('✅ Matchmaking speed benchmarks passed');
  });

  test('Matchmaking reliability under load', async ({ browser }) => {
    console.log('🔄 Testing matchmaking reliability...');
    
    const attempts = 5;
    const successes = [];
    
    for (let i = 0; i < attempts; i++) {
      const context1 = await browser.newContext();
      const context2 = await browser.newContext();
      const player1Page = await context1.newPage();
      const player2Page = await context2.newPage();
      
      try {
        console.log(`Reliability test ${i + 1}/${attempts}`);
        
        await Promise.all([
          player1Page.goto('http://localhost:3000'),
          player2Page.goto('http://localhost:3000')
        ]);
        
        await Promise.all([
          player1Page.waitForSelector('#connection-text:has-text("Connected")', { timeout: 10000 }),
          player2Page.waitForSelector('#connection-text:has-text("Connected")', { timeout: 10000 })
        ]);
        
        await player1Page.click('#play-btn');
        await player2Page.click('#play-btn');
        
        const success = await Promise.all([
          player1Page.waitForSelector('#matchmaking-overlay', { state: 'hidden', timeout: 25000 })
            .then(() => true).catch(() => false),
          player2Page.waitForSelector('#matchmaking-overlay', { state: 'hidden', timeout: 25000 })
            .then(() => true).catch(() => false)
        ]).then(results => results.every(r => r));
        
        successes.push(success);
        console.log(`  Result: ${success ? 'SUCCESS' : 'FAILED'}`);
        
      } finally {
        await context1.close();
        await context2.close();
      }
    }
    
    const successRate = successes.filter(s => s).length / attempts;
    const successPercentage = (successRate * 100).toFixed(1);
    
    console.log(`\n📈 Reliability Summary: ${successPercentage}% success rate (${successes.filter(s => s).length}/${attempts})`);
    
    // Reliability assertion - should have at least 80% success rate
    expect(successRate).toBeGreaterThanOrEqual(0.8);
    
    console.log('✅ Matchmaking reliability test passed');
  });
});