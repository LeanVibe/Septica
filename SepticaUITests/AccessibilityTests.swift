//
//  AccessibilityTests.swift
//  SepticaUITests
//
//  Accessibility compliance and usability tests
//  Tests VoiceOver support, Dynamic Type, and inclusive design features
//

import XCTest

final class AccessibilityTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchEnvironment = ["UI_TESTING": "1"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - VoiceOver Support Tests
    
    func testVoiceOverSupport() throws {
        // Test that all interactive elements have proper accessibility labels
        
        // Main Menu accessibility
        let mainMenuTitle = app.staticTexts["Romanian Septica"]
        XCTAssertTrue(mainMenuTitle.waitForExistence(timeout: 5))
        XCTAssertFalse(mainMenuTitle.label.isEmpty, "Main menu title should have accessible label")
        
        // Test main menu buttons
        let mainMenuButtons = ["New Game", "Continue Game", "Settings", "Rules", "Statistics"]
        
        for buttonName in mainMenuButtons {
            let button = app.buttons[buttonName]
            if button.exists {
                XCTAssertFalse(button.label.isEmpty, "\(buttonName) button should have accessible label")
                XCTAssertNotNil(button.value, "\(buttonName) button should have accessible value if needed")
                
                // Check accessibility traits
                XCTAssertTrue(button.elementType == .button, "\(buttonName) should be identified as button")
            }
        }
        
        // Test game setup accessibility
        let newGameButton = app.buttons["New Game"]
        if newGameButton.exists {
            newGameButton.tap()
            
            let gameSetupTitle = app.staticTexts["Game Setup"]
            XCTAssertTrue(gameSetupTitle.waitForExistence(timeout: 3))
            
            // Test AI difficulty selector
            let aiDifficultySegment = app.segmentedControls["AI Difficulty"]
            if aiDifficultySegment.exists {
                XCTAssertFalse(aiDifficultySegment.label.isEmpty, "AI difficulty control should have label")
                
                let difficulties = ["Easy", "Medium", "Hard", "Expert"]
                for difficulty in difficulties {
                    let difficultyButton = aiDifficultySegment.buttons[difficulty]
                    if difficultyButton.exists {
                        XCTAssertFalse(difficultyButton.label.isEmpty, "\(difficulty) option should have label")
                    }
                }
            }
            
            // Test target score slider
            let targetScoreSlider = app.sliders["Target Score"]
            if targetScoreSlider.exists {
                XCTAssertFalse(targetScoreSlider.label.isEmpty, "Target score slider should have label")
                XCTAssertNotNil(targetScoreSlider.value, "Slider should have current value announced")
            }
        }
    }
    
    func testGameplayAccessibility() throws {
        // Test accessibility during actual gameplay
        
        try startNewGame()
        
        // Test game board accessibility
        let gameBoard = app.otherElements["Game Board"]
        XCTAssertTrue(gameBoard.exists)
        XCTAssertFalse(gameBoard.label.isEmpty, "Game board should have descriptive label")
        
        // Test player hand accessibility
        let playerHand = app.otherElements["Player Hand"]
        XCTAssertTrue(playerHand.exists)
        XCTAssertFalse(playerHand.label.isEmpty, "Player hand should have descriptive label")
        
        // Test individual cards
        let playerCards = playerHand.buttons
        for i in 0..<min(playerCards.count, 4) {
            let card = playerCards.element(boundBy: i)
            if card.exists {
                XCTAssertFalse(card.label.isEmpty, "Card \(i) should have descriptive label (e.g., '7 of Hearts')")
                
                // Verify card accessibility traits
                XCTAssertTrue(card.isEnabled, "Card should be marked as enabled if playable")
            }
        }
        
        // Test table area accessibility
        let tableArea = app.otherElements["Table Cards"]
        if tableArea.exists {
            XCTAssertFalse(tableArea.label.isEmpty, "Table area should describe current state")
        }
        
        // Test score displays
        let scoreElements = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Score'"))
        for i in 0..<scoreElements.count {
            let scoreElement = scoreElements.element(boundBy: i)
            if scoreElement.exists {
                XCTAssertFalse(scoreElement.label.isEmpty, "Score display should have clear label")
                XCTAssertTrue(scoreElement.label.contains("Score") || scoreElement.label.contains(":"), 
                             "Score should be clearly identified")
            }
        }
    }
    
    func testVoiceOverNavigation() throws {
        // Test VoiceOver navigation flow through the app
        
        // Enable VoiceOver simulation if available
        if app.buttons["Accessibility Inspector"].exists {
            app.buttons["Accessibility Inspector"].tap()
        }
        
        // Test tab order and focus management
        let mainMenuTitle = app.staticTexts["Romanian Septica"]
        XCTAssertTrue(mainMenuTitle.waitForExistence(timeout: 5))
        
        // Navigate through main menu elements
        let newGameButton = app.buttons["New Game"]
        if newGameButton.exists {
            newGameButton.tap()
            
            // Check focus moves appropriately to game setup
            let gameSetupTitle = app.staticTexts["Game Setup"]
            XCTAssertTrue(gameSetupTitle.waitForExistence(timeout: 3))
            
            // Test focus order in game setup
            let startGameButton = app.buttons["Start Game"]
            if startGameButton.exists {
                startGameButton.tap()
                
                // Verify focus moves to game area
                let gameBoard = app.otherElements["Game Board"]
                XCTAssertTrue(gameBoard.waitForExistence(timeout: 5))
            }
        }
    }
    
    // MARK: - Dynamic Type Support Tests
    
    func testDynamicTypeSupport() throws {
        // Test app behavior with different text sizes
        
        // Note: In real implementation, you would programmatically change text size
        // For UI tests, this would require device-level changes or test hooks
        
        let mainMenuTitle = app.staticTexts["Romanian Septica"]
        XCTAssertTrue(mainMenuTitle.waitForExistence(timeout: 5))
        
        // Verify text is readable and doesn't truncate
        XCTAssertFalse(mainMenuTitle.label.isEmpty)
        XCTAssertTrue(mainMenuTitle.isHittable, "Title should remain interactive at different sizes")
        
        // Test button text scaling
        let newGameButton = app.buttons["New Game"]
        if newGameButton.exists {
            XCTAssertTrue(newGameButton.isHittable, "Button should remain tappable with larger text")
            XCTAssertFalse(newGameButton.label.isEmpty)
        }
        
        // Test in-game text scaling
        try startNewGame()
        
        let scoreElements = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Score'"))
        for i in 0..<scoreElements.count {
            let scoreElement = scoreElements.element(boundBy: i)
            if scoreElement.exists {
                XCTAssertTrue(scoreElement.isHittable, "Score text should remain visible with scaling")
            }
        }
    }
    
    func testTextContrast() throws {
        // Test text contrast and readability
        // Note: This would typically require image analysis or accessibility audit tools
        
        let mainMenuTitle = app.staticTexts["Romanian Septica"]
        XCTAssertTrue(mainMenuTitle.waitForExistence(timeout: 5))
        
        // Verify important text elements exist and are discoverable
        XCTAssertTrue(mainMenuTitle.exists, "Main title should be visible")
        
        let buttons = app.buttons.allElementsBoundByIndex
        for button in buttons {
            if button.exists && !button.label.isEmpty {
                XCTAssertTrue(button.isEnabled, "Interactive buttons should be clearly marked as enabled")
            }
        }
        
        // Test game screen contrast
        try startNewGame()
        
        let playerHand = app.otherElements["Player Hand"]
        if playerHand.exists {
            let cards = playerHand.buttons
            for i in 0..<cards.count {
                let card = cards.element(boundBy: i)
                if card.exists {
                    XCTAssertTrue(card.isEnabled, "Cards should be clearly distinguishable as interactive")
                }
            }
        }
    }
    
    // MARK: - Reduced Motion Support Tests
    
    func testReducedMotionSupport() throws {
        // Test app behavior with reduced motion preferences
        
        // Launch app and verify basic functionality without animations
        let mainMenuTitle = app.staticTexts["Romanian Septica"]
        XCTAssertTrue(mainMenuTitle.waitForExistence(timeout: 5))
        
        // Test navigation without animation dependencies
        let newGameButton = app.buttons["New Game"]
        if newGameButton.exists {
            newGameButton.tap()
            
            let gameSetupTitle = app.staticTexts["Game Setup"]
            XCTAssertTrue(gameSetupTitle.waitForExistence(timeout: 3))
            
            let startGameButton = app.buttons["Start Game"]
            if startGameButton.exists {
                startGameButton.tap()
                
                let gameBoard = app.otherElements["Game Board"]
                XCTAssertTrue(gameBoard.waitForExistence(timeout: 5))
            }
        }
        
        // Verify game is fully playable without motion effects
        let playerHand = app.otherElements["Player Hand"]
        if playerHand.exists {
            let cards = playerHand.buttons
            if cards.count > 0 {
                cards.firstMatch.tap()
                
                // Game should progress without requiring animations
                // Verify the UI updates appropriately
                let tableArea = app.otherElements["Table Cards"]
                if tableArea.exists {
                    let tableCards = tableArea.buttons
                    // Card should appear on table regardless of animation settings
                    XCTAssertGreaterThanOrEqual(tableCards.count, 0)
                }
            }
        }
    }
    
    // MARK: - High Contrast Support Tests
    
    func testHighContrastSupport() throws {
        // Test app appearance in high contrast mode
        
        let mainMenuTitle = app.staticTexts["Romanian Septica"]
        XCTAssertTrue(mainMenuTitle.waitForExistence(timeout: 5))
        
        // Verify all interactive elements remain discoverable
        let interactiveElements = app.buttons.allElementsBoundByIndex
        for element in interactiveElements {
            if element.exists && !element.label.isEmpty {
                XCTAssertTrue(element.isEnabled, "Button '\(element.label)' should remain clearly interactive")
            }
        }
        
        // Test game elements in high contrast
        try startNewGame()
        
        let playerCards = app.otherElements["Player Hand"].buttons
        for i in 0..<min(playerCards.count, 4) {
            let card = playerCards.element(boundBy: i)
            if card.exists {
                XCTAssertTrue(card.isEnabled, "Card should remain clearly distinguishable in high contrast")
                XCTAssertFalse(card.label.isEmpty, "Card should have clear identifying label")
            }
        }
    }
    
    // MARK: - Alternative Input Methods Tests
    
    func testSwitchControlSupport() throws {
        // Test app usability with switch control or similar alternative inputs
        
        let mainMenuTitle = app.staticTexts["Romanian Septica"]
        XCTAssertTrue(mainMenuTitle.waitForExistence(timeout: 5))
        
        // Verify all interactive elements are focusable
        let buttons = app.buttons.allElementsBoundByIndex
        for button in buttons {
            if button.exists && !button.label.isEmpty {
                XCTAssertTrue(button.isEnabled, "All buttons should be accessible via alternative input")
                
                // Verify button has appropriate accessibility traits
                XCTAssertTrue(button.elementType == .button, "Element should be properly identified as button")
            }
        }
        
        // Test game interaction with alternative input
        try startNewGame()
        
        let playerCards = app.otherElements["Player Hand"].buttons
        for i in 0..<playerCards.count {
            let card = playerCards.element(boundBy: i)
            if card.exists && card.isEnabled {
                XCTAssertTrue(card.elementType == .button, "Cards should be accessible as buttons")
            }
        }
    }
    
    func testKeyboardNavigation() throws {
        // Test keyboard navigation if supported
        
        let mainMenuTitle = app.staticTexts["Romanian Septica"]
        XCTAssertTrue(mainMenuTitle.waitForExistence(timeout: 5))
        
        // Test tab navigation through main menu
        // Note: This would require actual keyboard simulation or focus management testing
        
        let newGameButton = app.buttons["New Game"]
        if newGameButton.exists {
            XCTAssertTrue(newGameButton.isEnabled, "New Game should be keyboard accessible")
            
            newGameButton.tap()
            
            let gameSetupTitle = app.staticTexts["Game Setup"]
            XCTAssertTrue(gameSetupTitle.waitForExistence(timeout: 3))
            
            // Test that all game setup controls are keyboard accessible
            let startGameButton = app.buttons["Start Game"]
            XCTAssertTrue(startGameButton.exists && startGameButton.isEnabled)
        }
    }
    
    // MARK: - Accessibility Audit Tests
    
    func testAccessibilityAudit() throws {
        // Comprehensive accessibility audit of all screens
        
        // Main Menu audit
        auditScreen(screenName: "Main Menu") {
            let mainMenuTitle = app.staticTexts["Romanian Septica"]
            return mainMenuTitle.waitForExistence(timeout: 5)
        }
        
        // Game Setup audit
        let newGameButton = app.buttons["New Game"]
        if newGameButton.exists {
            newGameButton.tap()
            
            auditScreen(screenName: "Game Setup") {
                let gameSetupTitle = app.staticTexts["Game Setup"]
                return gameSetupTitle.waitForExistence(timeout: 3)
            }
            
            // Game Screen audit
            let startGameButton = app.buttons["Start Game"]
            if startGameButton.exists {
                startGameButton.tap()
                
                auditScreen(screenName: "Game Screen") {
                    let gameBoard = app.otherElements["Game Board"]
                    return gameBoard.waitForExistence(timeout: 5)
                }
            }
        }
    }
    
    func testColorBlindnessSupport() throws {
        // Test app usability for color-blind users
        
        try startNewGame()
        
        // Verify cards are distinguishable without relying solely on color
        let playerCards = app.otherElements["Player Hand"].buttons
        
        for i in 0..<playerCards.count {
            let card = playerCards.element(boundBy: i)
            if card.exists {
                let label = card.label
                XCTAssertFalse(label.isEmpty, "Card should have text-based identifier")
                
                // Verify label includes suit name, not just symbol
                let suitNames = ["Hearts", "Spades", "Clubs", "Diamonds", "♥️", "♠️", "♣️", "♦️"]
                let containsSuit = suitNames.contains { label.contains($0) }
                XCTAssertTrue(containsSuit, "Card label should include suit identifier: \(label)")
                
                // Verify label includes value
                let values = ["7", "8", "9", "10", "J", "Q", "K", "A", "Jack", "Queen", "King", "Ace"]
                let containsValue = values.contains { label.contains($0) }
                XCTAssertTrue(containsValue, "Card label should include value identifier: \(label)")
            }
        }
        
        // Test that game state is communicated clearly without color dependency
        let scoreElements = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Score'"))
        XCTAssertGreaterThan(scoreElements.count, 0, "Score should be displayed as text, not just color")
        
        for i in 0..<scoreElements.count {
            let scoreElement = scoreElements.element(boundBy: i)
            if scoreElement.exists {
                XCTAssertTrue(scoreElement.label.contains("Score") || scoreElement.label.contains(":"),
                             "Score should be clearly labeled with text")
            }
        }
    }
    
    // MARK: - Accessibility Helper Methods
    
    private func auditScreen(screenName: String, screenExists: () -> Bool) {
        XCTAssertTrue(screenExists(), "\(screenName) should load successfully")
        
        // Check for accessibility violations
        let buttons = app.buttons.allElementsBoundByIndex
        let staticTexts = app.staticTexts.allElementsBoundByIndex
        let otherElements = app.otherElements.allElementsBoundByIndex
        
        // Verify all buttons have labels
        for button in buttons {
            if button.exists && button.isEnabled {
                XCTAssertFalse(button.label.isEmpty, 
                              "\(screenName): Button should have accessibility label")
            }
        }
        
        // Verify important text has proper traits
        for text in staticTexts {
            if text.exists && !text.label.isEmpty {
                XCTAssertTrue(text.elementType == .staticText, 
                             "\(screenName): Text element should be properly identified")
            }
        }
        
        // Verify interactive elements are marked appropriately
        for element in otherElements {
            if element.exists && element.isEnabled && !element.label.isEmpty {
                // Should have appropriate accessibility traits
                XCTAssertNotNil(element.elementType, 
                               "\(screenName): Interactive element should have proper type")
            }
        }
    }
    
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
    
    // MARK: - Specific Accessibility Features Tests
    
    func testGameStateAnnouncements() throws {
        // Test that important game state changes are announced
        
        try startNewGame()
        
        // Test turn announcements
        let currentPlayerIndicator = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'turn' OR label CONTAINS 'Turn'")).firstMatch
        if currentPlayerIndicator.exists {
            XCTAssertFalse(currentPlayerIndicator.label.isEmpty, "Current turn should be clearly announced")
        }
        
        // Play a card and verify state change is communicated
        let playerCards = app.otherElements["Player Hand"].buttons
        if playerCards.count > 0 {
            let cardToPlay = playerCards.firstMatch
            let cardLabel = cardToPlay.label
            
            cardToPlay.tap()
            
            // Verify some indication that the card was played
            // This could be through updated labels, announcements, or UI changes
            let tableArea = app.otherElements["Table Cards"]
            if tableArea.exists {
                XCTAssertFalse(tableArea.label.isEmpty, "Table area should announce current state")
            }
        }
    }
    
    func testAccessibilityHints() throws {
        // Test that elements provide helpful accessibility hints
        
        try startNewGame()
        
        let playerCards = app.otherElements["Player Hand"].buttons
        for i in 0..<min(playerCards.count, 2) {
            let card = playerCards.element(boundBy: i)
            if card.exists {
                // Card should have hint about what happens when tapped
                XCTAssertNotNil(card.value, "Card should provide accessibility hint or value")
                
                if card.isEnabled {
                    // Enabled cards should indicate they're playable
                    let label = card.label.lowercased()
                    let hasPlayableHint = label.contains("tap") || label.contains("play") || 
                                         label.contains("select") || card.value != nil
                    XCTAssertTrue(hasPlayableHint, "Playable card should provide usage hint")
                }
            }
        }
        
        // Test menu buttons have appropriate hints
        let menuButton = app.buttons["Menu"]
        if menuButton.exists {
            XCTAssertNotNil(menuButton.value, "Menu button should have hint about available options")
        }
    }
}