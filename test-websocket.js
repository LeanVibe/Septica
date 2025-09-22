#!/usr/bin/env node

// Simple WebSocket client test to debug the connection issue
const WebSocket = require('ws');

const testUrl = 'ws://localhost:8080/ws/connect?user_id=550e8400-e29b-41d4-a716-446655440000';

console.log(`🔍 Testing WebSocket connection to: ${testUrl}`);

const ws = new WebSocket(testUrl);

ws.on('open', () => {
    console.log('✅ WebSocket connected successfully');
});

ws.on('message', (data) => {
    console.log('📩 Received message:');
    try {
        const parsed = JSON.parse(data);
        console.log('   Type:', parsed.type);
        console.log('   Player ID:', parsed.player_id);
        console.log('   Full message:', JSON.stringify(parsed, null, 2));
    } catch (e) {
        console.log('   Raw data:', data.toString());
    }
});

ws.on('close', (code, reason) => {
    console.log(`❌ WebSocket closed - Code: ${code}, Reason: "${reason}"`);
    process.exit(0);
});

ws.on('error', (error) => {
    console.log('💥 WebSocket error:', error.message);
    process.exit(1);
});

// Auto-exit after 10 seconds
setTimeout(() => {
    console.log('⏰ Test timeout - closing connection');
    ws.close();
    process.exit(0);
}, 10000);
