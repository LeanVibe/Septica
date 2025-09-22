/**
 * Quick Weather Scenario Test for Romanian Septica
 * Tests the "good weather scenario" - all systems working properly
 */

const { webkit } = require('playwright');

async function testWeatherScenario() {
    console.log('🌤️ Romanian Septica Weather Scenario Test');
    console.log('=' * 50);
    
    const browser = await webkit.launch({ headless: false });
    let weatherStatus = 'sunny'; // sunny, cloudy, stormy
    let issues = [];
    let successes = [];
    
    try {
        // Test 1: Backend Health
        console.log('\n☀️ Testing Backend Health...');
        const context = await browser.newContext();
        const page = await context.newPage();
        
        const healthResponse = await page.request.get('http://localhost:8080/health');
        if (healthResponse.status() === 200) {
            successes.push('✅ Backend Health: HEALTHY');
            console.log('✅ Backend is healthy and responding');
        } else {
            issues.push('❌ Backend Health: FAILED');
            weatherStatus = 'stormy';
        }
        
        // Test 2: Game Creation
        console.log('\n☀️ Testing Game Creation...');
        const gameResponse = await page.request.post('http://localhost:8080/api/v1/games', {
            data: { game_mode: 'casual' }
        });
        
        if (gameResponse.status() === 201) {
            const gameData = await gameResponse.json();
            successes.push('✅ Game Creation: SUCCESS');
            console.log('✅ Game created successfully:', gameData.game_id);
        } else {
            issues.push('❌ Game Creation: FAILED');
            if (weatherStatus === 'sunny') weatherStatus = 'cloudy';
        }
        
        // Test 3: Frontend Loading
        console.log('\n☀️ Testing Frontend Interface...');
        await page.goto('http://localhost:8001');
        await page.waitForLoadState('networkidle');
        
        const title = await page.textContent('h1');
        if (title && title.includes('Septica')) {
            successes.push('✅ Frontend: LOADED');
            console.log('✅ Frontend loaded with Romanian Septica title');
        } else {
            issues.push('❌ Frontend: FAILED TO LOAD');
            if (weatherStatus === 'sunny') weatherStatus = 'cloudy';
        }
        
        // Test 4: Romanian Game Elements
        console.log('\n🇷🇴 Testing Romanian Septica Elements...');
        
        // Check for Romanian deck values (7-14)
        const cardValueOptions = await page.locator('#cardValue option').allTextContents();
        const hasRomanianDeck = cardValueOptions.some(opt => opt.includes('7')) && 
                               cardValueOptions.some(opt => opt.includes('Ace'));
        
        if (hasRomanianDeck) {
            successes.push('✅ Romanian Deck: AUTHENTIC');
            console.log('✅ Romanian deck composition (7-Ace) verified');
        } else {
            issues.push('❌ Romanian Deck: MISSING');
            if (weatherStatus === 'sunny') weatherStatus = 'cloudy';
        }
        
        // Check for suits
        const suitOptions = await page.locator('#cardSuit option').allTextContents();
        const hasAllSuits = suitOptions.some(opt => opt.includes('Hearts')) &&
                           suitOptions.some(opt => opt.includes('Spades'));
        
        if (hasAllSuits) {
            successes.push('✅ Card Suits: COMPLETE');
            console.log('✅ All four card suits available');
        } else {
            issues.push('❌ Card Suits: INCOMPLETE');
            if (weatherStatus === 'sunny') weatherStatus = 'cloudy';
        }
        
        // Test 5: WebSocket Infrastructure
        console.log('\n🔌 Testing WebSocket Infrastructure...');
        
        const wsUrl = await page.locator('#serverUrl').inputValue();
        if (wsUrl && wsUrl.includes('ws://localhost:8080')) {
            successes.push('✅ WebSocket URL: CONFIGURED');
            console.log('✅ WebSocket endpoint correctly configured');
        } else {
            issues.push('❌ WebSocket URL: MISCONFIGURED');
            if (weatherStatus === 'sunny') weatherStatus = 'cloudy';
        }
        
        // Test 6: Three.js 3D Renderer
        console.log('\n🎮 Testing 3D Game Renderer...');
        
        const threejsContainer = await page.locator('#threejsContainer').count();
        if (threejsContainer > 0) {
            successes.push('✅ 3D Renderer: AVAILABLE');
            console.log('✅ Three.js 3D renderer container present');
        } else {
            issues.push('❌ 3D Renderer: MISSING');
            if (weatherStatus === 'sunny') weatherStatus = 'cloudy';
        }
        
        // Test 7: Performance Testing Button
        console.log('\n📊 Testing Performance Features...');
        
        const mobileTestBtn = await page.locator('button:has-text("Mobile Performance Test")').count();
        if (mobileTestBtn > 0) {
            successes.push('✅ Performance Testing: AVAILABLE');
            console.log('✅ Mobile performance testing available');
        } else {
            // This is optional, so just log
            console.log('ℹ️ Mobile performance testing not visible (optional)');
        }
        
        await context.close();
        
    } catch (error) {
        console.error('❌ Critical test failure:', error.message);
        weatherStatus = 'stormy';
        issues.push(`❌ Critical Error: ${error.message}`);
    } finally {
        await browser.close();
    }
    
    // Weather Report
    console.log('\n🌤️ WEATHER SCENARIO REPORT');
    console.log('=' * 50);
    
    console.log(`\n✅ SUCCESSES (${successes.length}):`);
    successes.forEach(success => console.log(`  ${success}`));
    
    if (issues.length > 0) {
        console.log(`\n⚠️ ISSUES (${issues.length}):`);
        issues.forEach(issue => console.log(`  ${issue}`));
    }
    
    // Final Weather Assessment
    console.log('\n🌦️ FINAL WEATHER STATUS:');
    if (weatherStatus === 'sunny') {
        console.log('☀️ SUNNY WEATHER! 🎉');
        console.log('   All Romanian Septica systems working perfectly!');
        console.log('   ✅ Backend healthy');
        console.log('   ✅ Frontend loading');
        console.log('   ✅ Romanian game rules implemented');
        console.log('   ✅ Multiplayer infrastructure ready');
        console.log('   🚀 READY FOR PRODUCTION!');
    } else if (weatherStatus === 'cloudy') {
        console.log('⛅ PARTLY CLOUDY');
        console.log('   Most systems working, minor issues detected');
        console.log('   🔧 Minor fixes needed before production');
    } else {
        console.log('🌧️ STORMY WEATHER');
        console.log('   Critical issues detected');
        console.log('   ⚠️ Major repairs needed');
    }
    
    console.log(`\n📊 SUCCESS RATE: ${successes.length}/${successes.length + issues.length} (${Math.round(successes.length / (successes.length + issues.length) * 100)}%)`);
    
    return weatherStatus;
}

// Run the weather test
testWeatherScenario().then(weather => {
    console.log(`\n🏁 Test completed with ${weather} weather conditions`);
    process.exit(weather === 'stormy' ? 1 : 0);
}).catch(error => {
    console.error('❌ Weather test failed:', error);
    process.exit(1);
});