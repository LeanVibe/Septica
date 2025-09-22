#!/usr/bin/env node

// Test the frontend multiplayer API integration
console.log('🧪 Testing Frontend Multiplayer API Integration...\n');

async function testGameCreation() {
    try {
        console.log('📡 Testing game creation API...');
        
        const response = await fetch('http://localhost:8080/api/v1/games', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                game_mode: 'standard',
                player_id: '550e8400-e29b-41d4-a716-446655440000'
            })
        });

        if (response.ok) {
            const gameData = await response.json();
            console.log('✅ Game creation successful!');
            console.log('   Game ID:', gameData.game_id);
            console.log('   Player 1:', gameData.player1_id);
            console.log('   Player 2:', gameData.player2_id);
            console.log('   Status:', gameData.status);
            console.log('   Current Player:', gameData.current_player);
            return gameData;
        } else {
            const error = await response.text();
            console.log('❌ Game creation failed:', error);
            return null;
        }
    } catch (err) {
        console.log('💥 Error testing game creation:', err.message);
        return null;
    }
}

async function testFrontendAccess() {
    try {
        console.log('\n🌐 Testing frontend accessibility...');
        
        const response = await fetch('http://localhost:3000/');
        if (response.ok) {
            console.log('✅ Frontend accessible at http://localhost:3000/');
            return true;
        } else {
            console.log('❌ Frontend not accessible');
            return false;
        }
    } catch (err) {
        console.log('💥 Error accessing frontend:', err.message);
        return false;
    }
}

async function runTests() {
    console.log('🚀 Starting API and Frontend Tests...\n');
    
    // Test game creation
    const gameData = await testGameCreation();
    
    // Test frontend access
    const frontendOk = await testFrontendAccess();
    
    console.log('\n📊 Test Summary:');
    console.log('   Backend API:', gameData ? '✅ Working' : '❌ Failed');
    console.log('   Frontend:', frontendOk ? '✅ Accessible' : '❌ Not accessible');
    
    if (gameData && frontendOk) {
        console.log('\n🎉 All tests passed! The 1v1 multiplayer system is ready for testing.');
        console.log('\n📋 Testing Instructions:');
        console.log('   1. Open http://localhost:3000/ in two browser tabs');
        console.log('   2. In Tab 1: Click "Create Game" to start a new game');
        console.log('   3. Copy the Game ID from Tab 1');
        console.log('   4. In Tab 2: Paste the Game ID and click "Join Game"');
        console.log('   5. Both tabs should now show the same game with real-time sync');
        console.log('   6. Test card playing and turn management');
    } else {
        console.log('\n❌ Some tests failed. Please check the backend and frontend servers.');
    }
}

// Run the tests
runTests().catch(console.error);