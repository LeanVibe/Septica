#!/usr/bin/env node

/**
 * Simple WebSocket connection test to debug message flow
 */

const WebSocket = require('ws');
const { v4: uuidv4 } = require('uuid');

async function testSimpleWebSocket() {
    console.log('🔍 TESTING SIMPLE WEBSOCKET CONNECTION');
    console.log('=====================================');
    
    const playerId = uuidv4();
    const url = `ws://localhost:8080/ws/connect?user_id=${playerId}`;
    
    console.log(`🔌 Connecting to: ${url}`);
    
    const ws = new WebSocket(url);
    let messageCount = 0;
    
    ws.on('open', () => {
        console.log('✅ WebSocket connected successfully');
        
        // Send a simple ping
        setTimeout(() => {
            console.log('📤 Sending ping message...');
            ws.send(JSON.stringify({
                type: 'ping',
                id: uuidv4(),
                timestamp: new Date().toISOString()
            }));
        }, 1000);
    });
    
    ws.on('message', (data) => {
        try {
            const message = JSON.parse(data.toString());
            messageCount++;
            console.log(`📨 Message ${messageCount}:`, message.type, message.payload ? '(with payload)' : '(no payload)');
            
            if (message.type === 'pong') {
                console.log('✅ Ping-pong successful!');
                setTimeout(() => {
                    ws.close();
                }, 1000);
            }
        } catch (error) {
            console.error('❌ Failed to parse message:', data.toString());
        }
    });
    
    ws.on('close', () => {
        console.log('🔴 WebSocket connection closed');
        console.log(`📊 Total messages received: ${messageCount}`);
        
        if (messageCount === 0) {
            console.log('❌ No messages received - possible registration issue');
        } else {
            console.log('✅ WebSocket communication working');
        }
        
        process.exit(0);
    });
    
    ws.on('error', (error) => {
        console.error('❌ WebSocket error:', error.message);
        process.exit(1);
    });
    
    // Timeout after 5 seconds
    setTimeout(() => {
        console.log('⏰ Test timeout - closing connection');
        ws.close();
    }, 5000);
}

testSimpleWebSocket().catch(console.error);