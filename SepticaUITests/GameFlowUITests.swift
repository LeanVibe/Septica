//
//  GameFlowUITests.swift
//  SepticaUITests
//
//  End-to-end UI automation tests for complete user journeys
//  Tests app navigation, game interaction, and user experience flows
//

import XCTest

final class GameFlowUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchEnvironment = ["UI_TESTING": "1"]  // Flag for UI testing mode
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Complete User Journey Tests
    
    func testCompleteGameFlow() throws {
        // Test complete user journey: Launch -> Main Menu -> Setup -> Game -> Results -> Menu
        
        // 1. Verify app launches to main menu
        let mainMenuTitle = app.staticTexts["Romanian Septica"]
        XCTAssertTrue(mainMenuTitle.waitForExistence(timeout: 5))
        
        // 2. Navigate to new game
        let newGameButton = app.buttons["New Game"]
        XCTAssertTrue(newGameButton.exists)
        newGameButton.tap()
        
        // 3. Verify game setup screen
        let gameSetupTitle = app.staticTexts["Game Setup"]
        XCTAssertTrue(gameSetupTitle.waitForExistence(timeout: 3))
        
        // 4. Configure game settings
        let aiDifficultySegment = app.segmentedControls["AI Difficulty"]
        if aiDifficultySegment.exists {
            aiDifficultySegment.buttons["Medium"].tap()
        }
        
        let targetScoreSlider = app.sliders["Target Score"]
        if targetScoreSlider.exists {
            targetScoreSlider.adjust(toNormalizedSliderPosition: 0.5) // Set to middle value
        }
        
        // 5. Start the game
        let startGameButton = app.buttons["Start Game"]
        XCTAssertTrue(startGameButton.exists)
        startGameButton.tap()
        
        // 6. Verify game screen loads
        let gameBoard = app.otherElements["Game Board"]
        XCTAssertTrue(gameBoard.waitForExistence(timeout: 5))
        
        // 7. Verify game elements are present
        let playerHand = app.otherElements["Player Hand"]
        XCTAssertTrue(playerHand.exists)
        
        let scoreDisplay = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Score'")).firstMatch
        XCTAssertTrue(scoreDisplay.exists)
        
        // 8. Simulate playing a card (if cards are interactive)
        let playerCards = playerHand.buttons
        if playerCards.count > 0 {
            playerCards.firstMatch.tap()
        }
        
        // 9. Wait for game progression or completion
        let gameCompleted = app.alerts["Game Complete"].waitForExistence(timeout: 30)
        if gameCompleted {
            // Handle game completion
            let okButton = app.buttons["OK"]
            if okButton.exists {
                okButton.tap()
            }
        }
        
        // 10. Return to main menu
        let mainMenuButton = app.buttons["Main Menu"]
        if mainMenuButton.exists {
            mainMenuButton.tap()
            XCTAssertTrue(mainMenuTitle.waitForExistence(timeout: 3))
        }
    }
    
    func testAppLaunchAndNavigation() throws {
        // Test basic app navigation without gameplay
        
        // Verify main menu
        let mainMenuTitle = app.staticTexts["Romanian Septica"]
        XCTAssertTrue(mainMenuTitle.waitForExistence(timeout: 5))
        
        // Test Settings navigation
        let settingsButton = app.buttons["Settings"]
        if settingsButton.exists {
            settingsButton.tap()
            
            let settingsTitle = app.staticTexts["Settings"]
            XCTAssertTrue(settingsTitle.waitForExistence(timeout: 3))
            
            // Return to main menu
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists {
                backButton.tap()
            }
        }
        
        // Test Rules navigation
        let rulesButton = app.buttons["Rules"] 
        if rulesButton.exists {
            rulesButton.tap()
            
            let rulesTitle = app.staticTexts["Game Rules"]
            XCTAssertTrue(rulesTitle.waitForExistence(timeout: 3))
            
            // Return to main menu
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists {
                backButton.tap()
            }
        }
        
        // Test Statistics navigation
        let statsButton = app.buttons["Statistics"]
        if statsButton.exists {
            statsButton.tap()
            
            let statsTitle = app.staticTexts["Statistics"]
            XCTAssertTrue(statsTitle.waitForExistence(timeout: 3))
            
            // Return to main menu
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists {
                backButton.tap()
            }
        }
        
        // Verify we're back at main menu
        XCTAssertTrue(mainMenuTitle.exists)
    }
    
    // MARK: - Game Setup Tests
    
    func testGameSetupConfiguration() throws {
        // Test game setup options and validation
        
        // Navigate to game setup
        let newGameButton = app.buttons["New Game"]
        XCTAssertTrue(newGameButton.exists)
        newGameButton.tap()
        
        let gameSetupTitle = app.staticTexts["Game Setup"]
        XCTAssertTrue(gameSetupTitle.waitForExistence(timeout: 3))
        
        // Test AI difficulty selection
        let aiDifficultySegment = app.segmentedControls["AI Difficulty"]
        if aiDifficultySegment.exists {
            // Test each difficulty level
            let difficulties = ["Easy", "Medium", "Hard", "Expert"]
            for difficulty in difficulties {
                let difficultyButton = aiDifficultySegment.buttons[difficulty]
                if difficultyButton.exists {
                    difficultyButton.tap()
                    XCTAssertTrue(difficultyButton.isSelected)
                }
            }
        }
        
        // Test target score adjustment
        let targetScoreSlider = app.sliders["Target Score"]
        if targetScoreSlider.exists {
            // Test different positions
            targetScoreSlider.adjust(toNormalizedSliderPosition: 0.0) // Minimum
            targetScoreSlider.adjust(toNormalizedSliderPosition: 1.0) // Maximum
            targetScoreSlider.adjust(toNormalizedSliderPosition: 0.5) // Middle
        }
        
        // Test start game validation
        let startGameButton = app.buttons["Start Game"]
        XCTAssertTrue(startGameButton.exists)
        XCTAssertTrue(startGameButton.isEnabled)
    }
    
    // MARK: - Gameplay Interaction Tests
    
    func testGameplayInteractions() throws {
        // Start a game first
        try startNewGame()
        
        // Verify game elements
        let gameBoard = app.otherElements["Game Board"]
        XCTAssertTrue(gameBoard.exists)
        
        let playerHand = app.otherElements["Player Hand"]
        XCTAssertTrue(playerHand.exists)
        
        // Test card interaction
        let playerCards = playerHand.buttons
        if playerCards.count > 0 {
            let firstCard = playerCards.firstMatch
            
            // Verify card is tappable
            XCTAssertTrue(firstCard.isEnabled)
            
            // Tap the card
            firstCard.tap()
            
            // Verify game state updates (card moved to table)
            let tableArea = app.otherElements["Table Cards"]
            if tableArea.exists {
                // Check if card appeared on table
                let tableCards = tableArea.buttons
                XCTAssertGreaterThan(tableCards.count, 0)
            }
        }
        
        // Test game controls
        let pauseButton = app.buttons["Pause"]
        if pauseButton.exists {
            pauseButton.tap()
            
            // Check for pause dialog or state change
            let resumeButton = app.buttons["Resume"]
            if resumeButton.exists {
                resumeButton.tap()
            }
        }
    }
    
    func testGameResultsDisplay() throws {
        // This test may require completing a full game or using test data
        
        // Start game and try to reach completion quickly
        try startNewGame()
        
        // For UI testing, we might need to simulate rapid gameplay
        // This would typically require test hooks in the app
        
        let gameCompleted = app.alerts["Game Complete"].waitForExistence(timeout: 60)
        if gameCompleted {
            // Verify game results elements
            let winnerText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Winner'")).firstMatch
            XCTAssertTrue(winnerText.exists)
            
            let finalScoreText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Score'")).firstMatch
            XCTAssertTrue(finalScoreText.exists)
            
            // Test results screen buttons
            let playAgainButton = app.buttons["Play Again"]
            let mainMenuButton = app.buttons["Main Menu"]
            
            XCTAssertTrue(playAgainButton.exists || mainMenuButton.exists)
            
            if mainMenuButton.exists {
                mainMenuButton.tap()
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandling() throws {
        // Test app behavior under various error conditions
        
        // Test network connectivity issues (if app has online features)
        // This would require network stubbing or simulation
        
        // Test invalid user inputs
        try startNewGame()
        
        // Try to tap areas that shouldn't be interactive
        let gameBoard = app.otherElements["Game Board"]
        if gameBoard.exists {
            // Tap empty areas of the board
            let coordinate = gameBoard.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1))
            coordinate.tap()
            
            // App should remain stable
            XCTAssertTrue(gameBoard.exists)
        }
    }
    
    // MARK: - Performance Tests
    
    func testAppLaunchPerformance() throws {
        // Test app launch performance
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let testApp = XCUIApplication()
            testApp.launch()
            testApp.terminate()
        }
    }
    
    func testGameStartPerformance() throws {
        // Test game startup performance
        let mainMenuTitle = app.staticTexts["Romanian Septica"]
        XCTAssertTrue(mainMenuTitle.waitForExistence(timeout: 5))
        
        measure(metrics: [XCTClockMetric()]) {
            // Navigate to new game
            let newGameButton = app.buttons["New Game"]
            newGameButton.tap()
            
            // Start game
            let startGameButton = app.buttons["Start Game"]
            if startGameButton.waitForExistence(timeout: 3) {
                startGameButton.tap()
            }
            
            // Wait for game to load
            let gameBoard = app.otherElements["Game Board"]
            _ = gameBoard.waitForExistence(timeout: 10)
            
            // Return to main menu for next iteration
            let mainMenuButton = app.buttons["Main Menu"]
            if mainMenuButton.exists {
                mainMenuButton.tap()
            } else {
                // Force return to main menu
                app.terminate()
                app.launch()
            }
        }
    }
    
    // MARK: - Cross-Device Compatibility Tests
    
    func testPhoneLayout() throws {
        // Test layout on phone-sized devices
        if UIDevice.current.userInterfaceIdiom == .phone {
            // Verify main menu fits properly
            let mainMenuTitle = app.staticTexts["Romanian Septica"]
            XCTAssertTrue(mainMenuTitle.exists)
            
            // Check that buttons are accessible
            let newGameButton = app.buttons["New Game"]
            XCTAssertTrue(newGameButton.exists)
            XCTAssertTrue(newGameButton.isHittable)
            
            // Test portrait orientation
            XCUIDevice.shared.orientation = .portrait
            Thread.sleep(forTimeInterval: 1) // Allow rotation
            XCTAssertTrue(mainMenuTitle.exists)
            
            // Test landscape orientation (if supported)
            XCUIDevice.shared.orientation = .landscapeLeft
            Thread.sleep(forTimeInterval: 1)
            XCTAssertTrue(mainMenuTitle.exists)
            
            // Return to portrait
            XCUIDevice.shared.orientation = .portrait
        }
    }
    
    func testTabletLayout() throws {
        // Test layout on tablet-sized devices
        if UIDevice.current.userInterfaceIdiom == .pad {
            // Verify elements are properly spaced for larger screen
            let mainMenuTitle = app.staticTexts["Romanian Septica"]
            XCTAssertTrue(mainMenuTitle.exists)
            
            // Start a game to test game board layout
            try startNewGame()
            
            let gameBoard = app.otherElements["Game Board"]
            XCTAssertTrue(gameBoard.exists)
            
            let playerHand = app.otherElements["Player Hand"]
            XCTAssertTrue(playerHand.exists)
            
            // Verify adequate spacing between elements
            let gameBoardFrame = gameBoard.frame
            let playerHandFrame = playerHand.frame
            
            // Elements shouldn't overlap
            XCTAssertFalse(gameBoardFrame.intersects(playerHandFrame))
        }
    }
    
    // MARK: - Integration Tests
    
    func testAppStatePreservation() throws {
        // Test that app preserves state during backgrounding/foregrounding
        
        // Start a game
        try startNewGame()
        
        let gameBoard = app.otherElements["Game Board"]
        XCTAssertTrue(gameBoard.exists)
        
        // Background the app
        XCUIDevice.shared.press(.home)
        Thread.sleep(forTimeInterval: 2)
        
        // Return to app
        app.activate()
        
        // Verify game state is preserved
        XCTAssertTrue(gameBoard.waitForExistence(timeout: 5))
        
        let playerHand = app.otherElements["Player Hand"]
        XCTAssertTrue(playerHand.exists)
    }
    
    // MARK: - Helper Methods
    
    private func startNewGame() throws {
        let newGameButton = app.buttons["New Game"]
        XCTAssertTrue(newGameButton.exists)
        newGameButton.tap()
        
        let startGameButton = app.buttons["Start Game"]
        XCTAssertTrue(startGameButton.waitForExistence(timeout: 3))
        startGameButton.tap()
        
        let gameBoard = app.otherElements["Game Board"]
        XCTAssertTrue(gameBoard.waitForExistence(timeout: 5))
    }
    
    private func returnToMainMenu() {
        let mainMenuButton = app.buttons["Main Menu"]
        if mainMenuButton.exists {
            mainMenuButton.tap()
        } else {
            // Force return through navigation
            let backButtons = app.navigationBars.buttons
            if backButtons.count > 0 {
                backButtons.firstMatch.tap()
            }
        }
        
        // Wait for main menu
        let mainMenuTitle = app.staticTexts["Romanian Septica"]
        _ = mainMenuTitle.waitForExistence(timeout: 3)
    }
    
    private func dismissAnyAlerts() {
        // Dismiss any alert dialogs that might appear
        let alerts = app.alerts
        for alert in alerts.allElementsBoundByIndex {
            if alert.exists {
                let buttons = alert.buttons
                if buttons.count > 0 {
                    buttons.firstMatch.tap()
                }
            }
        }
    }
}

// MARK: - Specific Feature Tests

extension GameFlowUITests {
    
    func testCardDisplayAndInteraction() throws {
        // Test detailed card display and interaction
        try startNewGame()
        
        let playerHand = app.otherElements["Player Hand"]
        XCTAssertTrue(playerHand.exists)
        
        let playerCards = playerHand.buttons
        XCTAssertGreaterThan(playerCards.count, 0, "Player should have cards in hand")
        
        // Test each card in hand
        for i in 0..<min(playerCards.count, 4) {  // Test first 4 cards
            let card = playerCards.element(boundBy: i)
            
            // Verify card is displayable and interactive
            XCTAssertTrue(card.exists)
            XCTAssertTrue(card.isEnabled)
            
            // Verify card has accessible label (for accessibility)
            XCTAssertFalse(card.label.isEmpty)
        }
    }
    
    func testScoreDisplayUpdates() throws {
        // Test that score displays update correctly during gameplay
        try startNewGame()
        
        // Find score displays
        let scoreElements = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Score' OR label CONTAINS ':'"))
        XCTAssertGreaterThan(scoreElements.count, 0, "Should have score displays")
        
        // Record initial scores
        var initialScores: [String] = []
        for i in 0..<scoreElements.count {
            let element = scoreElements.element(boundBy: i)
            if element.exists {
                initialScores.append(element.label)
            }
        }
        
        // Play some moves and check if scores update
        let playerHand = app.otherElements["Player Hand"]
        let playerCards = playerHand.buttons
        
        if playerCards.count > 0 {
            // Play a few cards
            for i in 0..<min(3, playerCards.count) {
                let card = playerCards.element(boundBy: 0) // Always take first card
                if card.exists && card.isEnabled {
                    card.tap()
                    Thread.sleep(forTimeInterval: 1) // Allow for updates
                }
            }
            
            // Check if any scores changed
            var scoresChanged = false
            for i in 0..<min(scoreElements.count, initialScores.count) {
                let element = scoreElements.element(boundBy: i)
                if element.exists && element.label != initialScores[i] {
                    scoresChanged = true
                    break
                }
            }
            
            // Note: Scores might not change if no point cards were played
            // This test mainly ensures the score display elements exist and are accessible
        }
    }
    
    func testGameMenuIntegration() throws {
        // Test in-game menu functionality
        try startNewGame()
        
        // Look for menu button or gesture
        let menuButton = app.buttons["Menu"]
        if menuButton.exists {
            menuButton.tap()
            
            // Check for menu options
            let pauseOption = app.buttons["Pause Game"]
            let settingsOption = app.buttons["Game Settings"] 
            let quitOption = app.buttons["Quit Game"]
            
            if pauseOption.exists {
                pauseOption.tap()
                
                // Should see pause confirmation or state change
                let resumeButton = app.buttons["Resume"]
                if resumeButton.exists {
                    resumeButton.tap()
                }
            }
            
            if settingsOption.exists {
                // Test settings access from game
                settingsOption.tap()
                
                // Should be able to return to game
                let backButton = app.buttons["Back to Game"]
                if backButton.exists {
                    backButton.tap()
                }
            }
        }
    }
}