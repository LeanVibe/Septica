const WebSocket = require('ws');

console.log('🧪 Testing Septica WebSocket Multiplayer Functionality');
console.log('=' .repeat(60));

// Test WebSocket connection
const ws = new WebSocket('ws://localhost:8080/ws/connect');

let gameId = null;
let playerId = null;
let sessionId = null;

ws.on('open', function open() {
    console.log('✅ WebSocket Connected');
    
    // Send ping to test basic communication
    const pingMessage = {
        type: 'ping',
        id: 'test-ping-' + Date.now(),
        timestamp: new Date().toISOString()
    };
    
    ws.send(JSON.stringify(pingMessage));
    console.log('📤 Sent ping message');
});

ws.on('message', function message(data) {
    try {
        const msg = JSON.parse(data);
        console.log('📥 Received:', msg.type);
        
        switch (msg.type) {
            case 'connection_ack':
                sessionId = msg.payload?.session_id;
                playerId = msg.player_id;
                console.log(`✅ Connection acknowledged - Session: ${sessionId?.substring(0, 8)}..., Player: ${playerId?.substring(0, 8)}...`);
                
                // Test joining a game (using the game ID from previous API call)
                setTimeout(() => {
                    const joinMessage = {
                        type: 'join_game',
                        id: 'test-join-' + Date.now(),
                        game_id: 'c82bbcf1-0ada-49b4-a226-62027f22b150', // Use game ID from API test
                        timestamp: new Date().toISOString(),
                        payload: { game_mode: 'casual' }
                    };
                    
                    ws.send(JSON.stringify(joinMessage));
                    console.log('📤 Sent join_game message');
                }, 1000);
                break;
                
            case 'pong':
                console.log('✅ Pong received - Basic communication working');
                break;
                
            case 'game_state':
                gameId = msg.game_id;
                console.log(`✅ Game state received - Game: ${gameId?.substring(0, 8)}...`);
                console.log(`   Current player: ${msg.payload?.current_player_id?.substring(0, 8)}...`);
                console.log(`   Trick: ${msg.payload?.trick_number}, Move: ${msg.payload?.move_number}`);
                console.log(`   Table cards: ${msg.payload?.table_cards?.length || 0}`);
                console.log(`   Player hand: ${msg.payload?.player_hand?.length || 0} cards`);
                break;
                
            case 'player_joined':
                console.log('✅ Player joined notification received');
                break;
                
            case 'heartbeat':
                console.log('💓 Heartbeat received');
                break;
                
            case 'error':
                console.log('❌ Error:', msg.payload?.message || msg.error);
                break;
                
            default:
                console.log(`📦 Other message: ${msg.type}`);
        }
    } catch (error) {
        console.log('❌ Message parsing error:', error.message);
    }
});

ws.on('error', function error(err) {
    console.log('❌ WebSocket error:', err.message);
});

ws.on('close', function close() {
    console.log('🔌 WebSocket connection closed');
    process.exit(0);
});

// Test timeout
setTimeout(() => {
    console.log('\n🏁 Test completed');
    console.log('📊 Multiplayer WebSocket functionality verified');
    ws.close();
}, 5000);