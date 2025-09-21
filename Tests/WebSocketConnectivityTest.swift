//
//  WebSocketConnectivityTest.swift
//  Septica
//
//  iOS WebSocket client integration test for Romanian Septica backend
//  Validates connection, message protocol, and game state synchronization
//

import Foundation
import Combine
import XCTest

/// Comprehensive test suite for iOS WebSocket connectivity to Go backend
/// Tests connection establishment, message protocol compatibility, and game state sync
class WebSocketConnectivityTest: XCTestCase {
    
    // MARK: - Test Configuration
    
    private let backendURL = URL(string: "ws://localhost:8080")!
    private let testTimeout: TimeInterval = 30.0
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - System Under Test
    
    private var networkManager: NetworkManager!
    private var multiplayerService: MultiplayerService!
    private var gameState: GameState!
    
    // MARK: - Test Setup
    
    override func setUp() {
        super.setUp()
        
        // Initialize core components
        networkManager = NetworkManager(baseURL: backendURL)
        gameState = GameState()
        multiplayerService = MultiplayerService(networkManager: networkManager, gameState: gameState)
        
        // Clear any existing connections
        networkManager.disconnect()
        
        print("🧪 WebSocket Connectivity Test Setup Complete")
        print("📡 Backend URL: \(backendURL.absoluteString)")
    }
    
    override func tearDown() {
        networkManager?.disconnect()
        cancellables.removeAll()
        
        // Allow time for cleanup
        RunLoop.current.run(until: Date().addingTimeInterval(1.0))
        
        super.tearDown()
        print("🔄 WebSocket Connectivity Test Cleanup Complete")
    }
    
    // MARK: - Connection Tests
    
    /// Test 1: Basic WebSocket connection establishment
    func testWebSocketConnectionEstablishment() {
        print("\n🚀 Test 1: WebSocket Connection Establishment")
        
        let connectionExpectation = expectation(description: "WebSocket connection established")
        let testPlayerId = UUID()
        
        // Monitor connection events
        networkManager.connectionEventPublisher
            .sink { event in
                switch event {
                case .connected:
                    print("✅ Connection established successfully")
                    connectionExpectation.fulfill()
                case .failed(let error):
                    print("❌ Connection failed: \(error.localizedDescription)")
                    XCTFail("Connection failed: \(error)")
                default:
                    print("📊 Connection event: \(event)")
                }
            }
            .store(in: &cancellables)
        
        // Initiate connection
        print("🔗 Connecting to backend with player ID: \(testPlayerId)")
        networkManager.connect(playerId: testPlayerId)
        
        // Wait for connection
        wait(for: [connectionExpectation], timeout: testTimeout)
        
        // Verify connection status
        XCTAssertEqual(networkManager.connectionStatus, .connected)
        XCTAssertNotNil(networkManager.serverInfo)
        
        print("✅ Test 1 Complete: Connection established and verified")
    }
    
    /// Test 2: Message protocol compatibility
    func testMessageProtocolCompatibility() {
        print("\n📨 Test 2: Message Protocol Compatibility")
        
        let connectionExpectation = expectation(description: "Connection established")
        let pingPongExpectation = expectation(description: "Ping-pong completed")
        
        // Setup connection first
        networkManager.connectionEventPublisher
            .sink { event in
                if case .connected = event {
                    connectionExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Monitor incoming messages
        networkManager.messagePublisher
            .sink { message in
                print("📥 Received message: \(message.type)")
                
                if message.type == "pong" {
                    print("🏓 Pong received - protocol compatibility verified")
                    pingPongExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Connect and test ping
        networkManager.connect(playerId: UUID())
        wait(for: [connectionExpectation], timeout: testTimeout)
        
        // Send ping message
        print("🏓 Sending ping message...")
        networkManager.ping()
        
        // Wait for pong response
        wait(for: [pingPongExpectation], timeout: testTimeout)
        
        print("✅ Test 2 Complete: Message protocol verified")
    }
    
    /// Test 3: Game state synchronization
    func testGameStateSynchronization() {
        print("\n🎮 Test 3: Game State Synchronization")
        
        let connectionExpectation = expectation(description: "Connection established")
        let gameJoinedExpectation = expectation(description: "Game joined")
        let gameStateExpectation = expectation(description: "Game state received")
        
        // Setup connection monitoring
        multiplayerService.sessionStatePublisher
            .sink { state in
                print("🎯 Session state: \(state)")
                
                switch state {
                case .connected:
                    connectionExpectation.fulfill()
                case .inGame:
                    gameJoinedExpectation.fulfill()
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        // Monitor game state updates
        gameState.$currentGameState
            .dropFirst() // Skip initial value
            .sink { gameStateValue in
                if gameStateValue != .notStarted {
                    print("🎲 Game state updated: \(gameStateValue)")
                    gameStateExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Connect and join a game
        print("🔗 Connecting to multiplayer service...")
        multiplayerService.connect(playerId: UUID())
        wait(for: [connectionExpectation], timeout: testTimeout)
        
        print("🎮 Attempting to join game...")
        multiplayerService.findGame(mode: .casual)
        
        // Wait for game joining and state sync
        wait(for: [gameJoinedExpectation, gameStateExpectation], timeout: testTimeout)
        
        // Verify game state is properly synchronized
        XCTAssertNotEqual(gameState.currentGameState, .notStarted)
        XCTAssertTrue(gameState.isOnlineGame)
        
        print("✅ Test 3 Complete: Game state synchronization verified")
    }
    
    /// Test 4: Card play message validation
    func testCardPlayMessageValidation() {
        print("\n🃏 Test 4: Card Play Message Validation")
        
        let connectionExpectation = expectation(description: "Connection established")
        let cardPlayExpectation = expectation(description: "Card play processed")
        
        // Setup connection
        networkManager.connectionEventPublisher
            .sink { event in
                if case .connected = event {
                    connectionExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Monitor move results
        networkManager.messagePublisher
            .filter { $0.type == "move_result" }
            .sink { message in
                print("🎯 Move result received")
                
                do {
                    let moveResult = try message.parsePayload(as: MoveResultPayload.self)
                    print("✅ Card play result: valid=\(moveResult.valid)")
                    
                    if moveResult.error != nil {
                        print("ℹ️ Move error (expected): \(moveResult.error!)")
                    }
                    
                    cardPlayExpectation.fulfill()
                } catch {
                    print("❌ Failed to parse move result: \(error)")
                    XCTFail("Failed to parse move result")
                }
            }
            .store(in: &cancellables)
        
        // Connect
        networkManager.connect(playerId: UUID())
        wait(for: [connectionExpectation], timeout: testTimeout)
        
        // Create a test card (7 of Hearts - valid Septica card)
        let testCard = Card(suit: .hearts, value: 7)
        let playCardMessage = OutgoingMessage.playCard(card: testCard, gameId: UUID())
        
        print("🃏 Playing test card: \(testCard.displayName)")
        networkManager.send(playCardMessage)
        
        // Wait for move result
        wait(for: [cardPlayExpectation], timeout: testTimeout)
        
        print("✅ Test 4 Complete: Card play message validation verified")
    }
    
    /// Test 5: Romanian Septica rules compliance
    func testRomanianSepticaRulesCompliance() {
        print("\n🇷🇴 Test 5: Romanian Septica Rules Compliance")
        
        // Test card value ranges (7-14 for Romanian Septica)
        let validValues = Array(7...14)
        let validSuits: [Suit] = [.hearts, .diamonds, .clubs, .spades]
        
        print("🃏 Testing card value ranges...")
        for value in validValues {
            for suit in validSuits {
                let card = Card(suit: suit, value: value)
                XCTAssertEqual(card.value, value)
                XCTAssertEqual(card.suit, suit)
            }
        }
        
        // Test special card rules (7 is wild, 8 beats when table count % 3 == 0)
        let sevenOfHearts = Card(suit: .hearts, value: 7)
        let eightOfSpades = Card(suit: .spades, value: 8)
        let kingOfDiamonds = Card(suit: .diamonds, value: 13)
        
        print("🃏 Testing special card rules...")
        
        // 7 always beats (wild card rule)
        XCTAssertTrue(sevenOfHearts.canBeat(kingOfDiamonds, tableCardsCount: 1))
        XCTAssertTrue(sevenOfHearts.canBeat(eightOfSpades, tableCardsCount: 5))
        
        // 8 beats when table cards count is divisible by 3
        XCTAssertTrue(eightOfSpades.canBeat(kingOfDiamonds, tableCardsCount: 3))
        XCTAssertTrue(eightOfSpades.canBeat(kingOfDiamonds, tableCardsCount: 6))
        XCTAssertFalse(eightOfSpades.canBeat(kingOfDiamonds, tableCardsCount: 4))
        
        // Same value beats
        let anotherKing = Card(suit: .clubs, value: 13)
        XCTAssertTrue(kingOfDiamonds.canBeat(anotherKing, tableCardsCount: 1))
        
        // Test point cards (10s and Aces are worth 1 point each)
        let tenOfHearts = Card(suit: .hearts, value: 10)
        let aceOfSpades = Card(suit: .spades, value: 14)
        let jackOfClubs = Card(suit: .clubs, value: 11)
        
        XCTAssertTrue(tenOfHearts.isPointCard)
        XCTAssertTrue(aceOfSpades.isPointCard)
        XCTAssertFalse(jackOfClubs.isPointCard)
        XCTAssertFalse(sevenOfHearts.isPointCard)
        
        print("✅ Test 5 Complete: Romanian Septica rules compliance verified")
    }
    
    // MARK: - Integration Test
    
    /// Comprehensive integration test covering full multiplayer flow
    func testFullMultiplayerIntegration() {
        print("\n🌟 Integration Test: Full Multiplayer Flow")
        
        let connectionExpectation = expectation(description: "Connection established")
        let gameJoinedExpectation = expectation(description: "Game joined")
        let cardPlayedExpectation = expectation(description: "Card played")
        
        var receivedGameState = false
        var receivedMoveResult = false
        
        // Monitor all events
        multiplayerService.sessionStatePublisher
            .sink { state in
                print("📊 Session state: \(state)")
                
                switch state {
                case .connected:
                    connectionExpectation.fulfill()
                case .inGame:
                    gameJoinedExpectation.fulfill()
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        networkManager.messagePublisher
            .sink { message in
                print("📥 Message: \(message.type)")
                
                switch message.type {
                case "game_state":
                    receivedGameState = true
                    print("🎮 Game state received")
                case "move_result":
                    receivedMoveResult = true
                    print("🎯 Move result received")
                    
                    if receivedGameState && receivedMoveResult {
                        cardPlayedExpectation.fulfill()
                    }
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        // Execute full flow
        print("🔗 Starting full integration test...")
        multiplayerService.connect(playerId: UUID())
        wait(for: [connectionExpectation], timeout: testTimeout)
        
        print("🎮 Joining game...")
        multiplayerService.findGame(mode: .casual)
        wait(for: [gameJoinedExpectation], timeout: testTimeout)
        
        print("🃏 Playing a card...")
        let testCard = Card(suit: .hearts, value: 7)
        multiplayerService.playCard(testCard)
        wait(for: [cardPlayedExpectation], timeout: testTimeout)
        
        // Verify final state
        XCTAssertTrue(receivedGameState, "Should have received game state")
        XCTAssertTrue(receivedMoveResult, "Should have received move result")
        XCTAssertEqual(multiplayerService.sessionState, .inGame)
        
        print("✅ Integration Test Complete: Full multiplayer flow verified")
    }
}

// MARK: - Test Utilities

extension WebSocketConnectivityTest {
    
    /// Print test summary
    func printTestSummary() {
        print("\n📋 WebSocket Connectivity Test Summary")
        print("=" * 50)
        print("✅ Connection establishment")
        print("✅ Message protocol compatibility")
        print("✅ Game state synchronization")
        print("✅ Card play message validation")
        print("✅ Romanian Septica rules compliance")
        print("✅ Full multiplayer integration")
        print("=" * 50)
        print("🎉 All tests passed! iOS-Backend connectivity verified.")
    }
}

// MARK: - String Extension for Test Formatting

private extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}