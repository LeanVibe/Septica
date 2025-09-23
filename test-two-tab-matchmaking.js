#!/usr/bin/env node

/**
 * Test Two-Tab Auto-Matchmaking Flow
 * Simulates two browser tabs clicking "Play" and auto-pairing
 */

const WebSocket = require('ws');
const { v4: uuidv4 } = require('uuid');

class TestPlayer {
    constructor(name) {
        this.name = name;
        this.playerId = uuidv4();
        this.ws = null;
        this.isConnected = false;
        this.isInMatchmaking = false;
        this.gameId = null;
        this.messages = [];
    }

    async connect() {
        return new Promise((resolve, reject) => {
            const url = `ws://localhost:8080/ws/connect?user_id=${this.playerId}`;
            console.log(`🔌 ${this.name}: Connecting to ${url}`);
            
            this.ws = new WebSocket(url);
            
            this.ws.on('open', () => {
                this.isConnected = true;
                console.log(`✅ ${this.name}: Connected successfully`);
                resolve();
            });
            
            this.ws.on('message', (data) => {
                try {
                    const message = JSON.parse(data.toString());
                    this.handleMessage(message);
                } catch (error) {
                    console.error(`❌ ${this.name}: Invalid message:`, data.toString());
                }
            });
            
            this.ws.on('close', () => {
                this.isConnected = false;
                console.log(`🔴 ${this.name}: Connection closed`);
            });
            
            this.ws.on('error', (error) => {
                console.error(`❌ ${this.name}: WebSocket error:`, error.message);
                reject(error);
            });
            
            setTimeout(() => {
                if (!this.isConnected) {
                    reject(new Error('Connection timeout'));
                }
            }, 5000);
        });
    }

    handleMessage(message) {
        this.messages.push(message);
        console.log(`📨 ${this.name}: Received ${message.type}`, message.payload || '');
        
        switch (message.type) {
            case 'connection_ack':
                console.log(`🤝 ${this.name}: Connection acknowledged`);
                break;
                
            case 'matchmaking_joined':
                this.isInMatchmaking = true;
                console.log(`🎯 ${this.name}: Joined matchmaking queue`);
                break;
                
            case 'match_found':
                this.gameId = message.payload?.game_id;
                this.isInMatchmaking = false;
                console.log(`🎮 ${this.name}: Match found! Game ID: ${this.gameId}`);
                break;
                
            case 'game_started':
                console.log(`🚀 ${this.name}: Game started!`);
                break;
                
            case 'player_turn':
                console.log(`👉 ${this.name}: It's ${message.payload?.player_id === this.playerId ? 'your' : 'opponent'} turn`);
                break;
                
            case 'error':
                console.error(`❌ ${this.name}: Error:`, message.payload);
                break;
        }
    }

    joinMatchmaking() {
        if (!this.isConnected) {
            console.error(`❌ ${this.name}: Not connected`);
            return;
        }
        
        const message = {
            type: 'join_matchmaking',
            payload: {
                queue_type: 'casual',
                game_mode: 'septica'
            }
        };
        
        console.log(`📤 ${this.name}: Joining matchmaking...`);
        this.ws.send(JSON.stringify(message));
    }

    disconnect() {
        if (this.ws) {
            this.ws.close();
        }
    }
}

async function testTwoTabMatchmaking() {
    console.log('🎮 TESTING TWO-TAB AUTO-MATCHMAKING FLOW');
    console.log('==========================================');
    
    const player1 = new TestPlayer('Player1 (Tab1)');
    const player2 = new TestPlayer('Player2 (Tab2)');
    
    try {
        // Step 1: Both players connect (simulating opening two tabs)
        console.log('\n📱 Step 1: Opening two browser tabs...');
        await Promise.all([
            player1.connect(),
            player2.connect()
        ]);
        
        console.log('✅ Both tabs connected successfully');
        
        // Step 2: Both players click "Play" button (join matchmaking)
        console.log('\n🎯 Step 2: Both tabs click "Play" button...');
        player1.joinMatchmaking();
        await new Promise(resolve => setTimeout(resolve, 500)); // Small delay
        player2.joinMatchmaking();
        
        // Step 3: Wait for auto-pairing and game start
        console.log('\n⏳ Step 3: Waiting for auto-pairing...');
        
        await new Promise(resolve => setTimeout(resolve, 3000));
        
        // Step 4: Verify results
        console.log('\n📊 VERIFICATION RESULTS:');
        console.log('=======================');
        
        const player1InGame = player1.gameId !== null;
        const player2InGame = player2.gameId !== null;
        const sameGame = player1.gameId === player2.gameId;
        
        console.log(`Player1 in game: ${player1InGame ? '✅' : '❌'} (Game ID: ${player1.gameId})`);
        console.log(`Player2 in game: ${player2InGame ? '✅' : '❌'} (Game ID: ${player2.gameId})`);
        console.log(`Same game: ${sameGame ? '✅' : '❌'}`);
        
        if (player1InGame && player2InGame && sameGame) {
            console.log('\n🎉 SUCCESS: Two-tab auto-matchmaking working perfectly!');
            console.log('✅ Both players auto-paired into same Romanian Septica game');
        } else {
            console.log('\n❌ FAILURE: Auto-matchmaking not working correctly');
            
            console.log('\n📋 Debug Info:');
            console.log('Player1 messages:', player1.messages.length);
            console.log('Player2 messages:', player2.messages.length);
            
            if (player1.messages.length > 0) {
                console.log('Player1 last messages:', player1.messages.slice(-3));
            }
            if (player2.messages.length > 0) {
                console.log('Player2 last messages:', player2.messages.slice(-3));
            }
        }
        
    } catch (error) {
        console.error('❌ Test failed:', error.message);
    } finally {
        // Cleanup
        player1.disconnect();
        player2.disconnect();
        
        setTimeout(() => {
            process.exit(0);
        }, 1000);
    }
}

// Run the test
testTwoTabMatchmaking().catch(console.error);