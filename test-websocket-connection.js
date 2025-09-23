#!/usr/bin/env node

/**
 * Simple WebSocket connection test to verify server is working
 */

const WebSocket = require('ws');
const { v4: uuidv4 } = require('uuid');

async function testConnection() {
    console.log('🔍 TESTING WEBSOCKET CONNECTION');
    console.log('================================');
    
    const playerId = uuidv4();
    const url = `ws://localhost:8080/ws/connect?user_id=${playerId}`;
    
    console.log(`🔌 Connecting to: ${url}`);
    console.log(`📧 Player ID: ${playerId}`);
    
    const ws = new WebSocket(url);
    let messageCount = 0;
    
    ws.on('open', () => {
        console.log('✅ WebSocket connected successfully');
        console.log('⏰ Waiting for messages...');
    });
    
    ws.on('message', (data) => {
        try {
            const message = JSON.parse(data.toString());
            messageCount++;
            console.log(`📨 Message ${messageCount}: ${message.type}`);
            
            if (message.type === 'connection_ack') {
                console.log('✅ Connection acknowledged by server');
                console.log('📋 Server payload:', message.payload);
                
                // Close after receiving ack
                setTimeout(() => {
                    console.log('🔴 Closing connection after successful test');
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
            console.log('❌ No messages received - connection issue');
            process.exit(1);
        } else {
            console.log('✅ WebSocket communication working');
            process.exit(0);
        }
    });
    
    ws.on('error', (error) => {
        console.error('❌ WebSocket error:', error.message);
        process.exit(1);
    });
    
    // Timeout after 10 seconds
    setTimeout(() => {
        console.log('⏰ Test timeout - closing connection');
        ws.close();
    }, 10000);
}

testConnection().catch(console.error);