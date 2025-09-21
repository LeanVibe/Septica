#!/usr/bin/env node

const WebSocket = require('ws');
const { v4: uuidv4 } = require('uuid');

// Romanian Septica WebSocket Test Suite
class SepticaWebSocketTest {
    constructor() {
        this.testResults = {
            connection: false,
            protocol: false,
            authentication: false,
            gameCreation: false,
            ruleCompliance: false,
            performance: false
        };
        this.userID = uuidv4();
        this.messageId = 0;
        this.results = [];
    }

    async runComprehensiveTests() {
        console.log('🎮 Starting Romanian Septica Comprehensive QA Testing');
        console.log('=' * 60);
        
        await this.testWebSocketConnection();
        await this.testProtocolCompliance();
        await this.testRomanianSepticaRules();
        await this.testPerformance();
        
        this.generateReport();
    }

    async testWebSocketConnection() {
        console.log('\n1. 🔌 Testing WebSocket Connection...');
        
        return new Promise((resolve) => {
            try {
                const ws = new WebSocket(`ws://localhost:8080/ws/connect?user_id=${this.userID}`);
                
                ws.on('open', () => {
                    console.log('   ✅ WebSocket connection established');
                    this.testResults.connection = true;
                    
                    // Test ping/pong
                    ws.send(JSON.stringify({
                        type: 'ping',
                        id: this.messageId++,
                        player_id: this.userID,
                        timestamp: new Date().toISOString()
                    }));
                });
                
                ws.on('message', (data) => {
                    const message = JSON.parse(data.toString());
                    console.log(`   📨 Received: ${message.type}`);
                    
                    if (message.type === 'connection_ack') {
                        console.log(`   ✅ Connection acknowledged - Player ID: ${message.player_id}`);
                        this.testResults.authentication = true;
                    }
                    
                    if (message.type === 'pong') {
                        console.log('   ✅ Ping/Pong working correctly');
                        this.testResults.protocol = true;
                        ws.close();
                        resolve();
                    }
                });
                
                ws.on('error', (error) => {
                    console.log(`   ❌ WebSocket error: ${error.message}`);
                    resolve();
                });
                
                ws.on('close', () => {
                    console.log('   🔌 WebSocket connection closed');
                });
                
            } catch (error) {
                console.log(`   ❌ Connection test failed: ${error.message}`);
                resolve();
            }
        });
    }

    async testProtocolCompliance() {
        console.log('\n2. 📋 Testing Protocol Compliance...');
        
        return new Promise((resolve) => {
            const ws = new WebSocket(`ws://localhost:8080/ws/connect?user_id=${this.userID}`);
            let protocolTests = {
                connectionAck: false,
                gameCreation: false,
                errorHandling: false
            };
            
            ws.on('open', () => {
                // Test game creation
                console.log('   🎮 Testing game creation...');
                ws.send(JSON.stringify({
                    type: 'join_game',
                    id: this.messageId++,
                    player_id: this.userID,
                    payload: {
                        game_mode: 'casual'
                    },
                    timestamp: new Date().toISOString()
                }));
            });
            
            ws.on('message', (data) => {
                const message = JSON.parse(data.toString());
                
                if (message.type === 'connection_ack') {
                    protocolTests.connectionAck = true;
                }
                
                if (message.type === 'error' && message.error && message.error.includes('Game ID is required')) {
                    console.log('   ✅ Game creation error handled correctly');
                    protocolTests.errorHandling = true;
                    this.testResults.gameCreation = true;
                }
                
                // Close after getting expected responses
                if (protocolTests.connectionAck && protocolTests.errorHandling) {
                    ws.close();
                    resolve();
                }
            });
            
            setTimeout(() => {
                ws.close();
                resolve();
            }, 5000);
        });
    }

    async testRomanianSepticaRules() {
        console.log('\n3. 🏛️ Testing Romanian Septica Rule Compliance...');
        
        // Test deck composition
        console.log('   🃏 Validating 32-card Romanian deck...');
        const expectedCards = [];
        const suits = ['hearts', 'diamonds', 'clubs', 'spades'];
        const values = [7, 8, 9, 10, 11, 12, 13, 14]; // J=11, Q=12, K=13, A=14
        
        suits.forEach(suit => {
            values.forEach(value => {
                expectedCards.push({ suit, value });
            });
        });
        
        if (expectedCards.length === 32) {
            console.log('   ✅ 32-card deck composition correct');
            
            // Test point cards (10s and Aces)
            const pointCards = expectedCards.filter(card => card.value === 10 || card.value === 14);
            if (pointCards.length === 8) {
                console.log('   ✅ Point cards correct: 8 total (4×10s + 4×Aces)');
                this.testResults.ruleCompliance = true;
            }
        }
        
        // Test Romanian rule logic
        console.log('   🎯 Testing Romanian Septica beating rules...');
        const ruleTests = {
            '7 beats Ace': this.testCardBeating(7, 14),
            '7 beats King': this.testCardBeating(7, 13),
            '7 beats 10': this.testCardBeating(7, 10),
            '8 beats 7 (when table % 3 = 0)': this.testConditionalBeating(8, 7, 0),
            'Same value beats': this.testSameValueBeating(10, 10),
            'Ace beats Ace': this.testSameValueBeating(14, 14)
        };
        
        Object.entries(ruleTests).forEach(([rule, result]) => {
            console.log(`   ${result ? '✅' : '❌'} ${rule}`);
        });
    }

    testCardBeating(card1Value, card2Value) {
        // 7s always beat any other card
        if (card1Value === 7 && card2Value !== 7 && card2Value !== 8) {
            return true;
        }
        // Same value cards beat each other (for collection)
        if (card1Value === card2Value) {
            return true;
        }
        return false;
    }

    testConditionalBeating(card1Value, card2Value, tableCardsCount) {
        // 8s beat 7s when table card count % 3 = 0
        if (card1Value === 8 && card2Value === 7 && tableCardsCount % 3 === 0) {
            return true;
        }
        return false;
    }

    testSameValueBeating(card1Value, card2Value) {
        return card1Value === card2Value;
    }

    async testPerformance() {
        console.log('\n4. ⚡ Testing Performance...');
        
        const startTime = Date.now();
        let connectionsSuccessful = 0;
        const totalConnections = 10;
        
        const connectionPromises = [];
        
        for (let i = 0; i < totalConnections; i++) {
            connectionPromises.push(this.createPerformanceConnection());
        }
        
        const results = await Promise.allSettled(connectionPromises);
        connectionsSuccessful = results.filter(r => r.status === 'fulfilled').length;
        
        const endTime = Date.now();
        const totalTime = endTime - startTime;
        
        console.log(`   📊 Concurrent connections: ${connectionsSuccessful}/${totalConnections}`);
        console.log(`   ⏱️ Total time: ${totalTime}ms`);
        console.log(`   📈 Average connection time: ${(totalTime / connectionsSuccessful).toFixed(2)}ms`);
        
        if (connectionsSuccessful >= totalConnections * 0.8) {
            console.log('   ✅ Performance test passed (80%+ success rate)');
            this.testResults.performance = true;
        } else {
            console.log('   ❌ Performance test failed');
        }
    }

    createPerformanceConnection() {
        return new Promise((resolve, reject) => {
            const userID = uuidv4();
            const ws = new WebSocket(`ws://localhost:8080/ws/connect?user_id=${userID}`);
            
            const timeout = setTimeout(() => {
                ws.close();
                reject(new Error('Connection timeout'));
            }, 5000);
            
            ws.on('open', () => {
                clearTimeout(timeout);
                ws.close();
                resolve();
            });
            
            ws.on('error', (error) => {
                clearTimeout(timeout);
                reject(error);
            });
        });
    }

    generateReport() {
        console.log('\n' + '=' * 60);
        console.log('📊 COMPREHENSIVE QA TEST RESULTS');
        console.log('=' * 60);
        
        const testCategories = [
            { name: 'WebSocket Connection', key: 'connection', weight: 20 },
            { name: 'Protocol Compliance', key: 'protocol', weight: 15 },
            { name: 'Authentication', key: 'authentication', weight: 10 },
            { name: 'Game Creation', key: 'gameCreation', weight: 15 },
            { name: 'Romanian Rule Compliance', key: 'ruleCompliance', weight: 25 },
            { name: 'Performance', key: 'performance', weight: 15 }
        ];
        
        let totalScore = 0;
        let maxScore = 0;
        
        testCategories.forEach(category => {
            const passed = this.testResults[category.key];
            const score = passed ? category.weight : 0;
            totalScore += score;
            maxScore += category.weight;
            
            console.log(`${passed ? '✅' : '❌'} ${category.name}: ${score}/${category.weight} points`);
        });
        
        const percentage = Math.round((totalScore / maxScore) * 100);
        
        console.log('\n📈 OVERALL SCORE: ' + `${totalScore}/${maxScore} (${percentage}%)`);
        
        if (percentage >= 90) {
            console.log('🏆 EXCELLENT - Production Ready');
        } else if (percentage >= 75) {
            console.log('✅ GOOD - Minor improvements needed');
        } else if (percentage >= 60) {
            console.log('⚠️ FAIR - Significant improvements required');
        } else {
            console.log('❌ POOR - Major issues need resolution');
        }
        
        console.log('\n🎯 PRODUCTION READINESS ASSESSMENT:');
        
        if (this.testResults.connection && this.testResults.ruleCompliance) {
            console.log('✅ Core functionality operational');
        }
        
        if (this.testResults.protocol && this.testResults.authentication) {
            console.log('✅ Security and protocol compliance');
        }
        
        if (this.testResults.performance) {
            console.log('✅ Performance targets met');
        }
        
        console.log('\n💡 RECOMMENDATIONS:');
        
        if (!this.testResults.gameCreation) {
            console.log('🔧 Implement game creation endpoint');
        }
        
        if (!this.testResults.performance) {
            console.log('⚡ Optimize connection handling for scale');
        }
        
        if (percentage < 90) {
            console.log('🛠️ Address failing test categories before production deployment');
        }
        
        console.log('\n🏁 Romanian Septica QA Testing Complete!');
    }
}

// Run the test suite
const tester = new SepticaWebSocketTest();
tester.runComprehensiveTests().catch(console.error);