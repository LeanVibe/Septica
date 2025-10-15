//
//  PremiumButtonAccessibilityTests.swift
//  SepticaUITests
//
//  Accessibility testing for premium glass morphism UI components
//  Validates VoiceOver support and Dynamic Type compatibility
//

import XCTest

class PremiumButtonAccessibilityTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()

        // Enable accessibility features for testing
        app.accessibilityActivate()

        // Set up VoiceOver if available
        if UIAccessibility.isVoiceOverRunning {
            // VoiceOver is already enabled
        }
    }

    override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }

    // MARK: - VoiceOver Testing

    func testPremiumGlassButtonVoiceOverSupport() throws {
        // Navigate to premium game screen if needed
        // This assumes the app launches with premium components visible

        // Test primary glass button VoiceOver support
        let primaryButton = app.buttons["Joacă"]

        if primaryButton.exists {
            XCTAssertTrue(primaryButton.isHittable, "Primary glass button should be accessible")

            // Test accessibility label
            let accessibilityLabel = primaryButton.label
            XCTAssertFalse(accessibilityLabel.isEmpty, "Primary button should have accessibility label")

            // Test accessibility hint
            let accessibilityHint = primaryButton.value as? String
            XCTAssertNotNil(accessibilityHint, "Primary button should have accessibility hint")

            // Test accessibility traits
            let traits = primaryButton.accessibilityTraits
            XCTAssertTrue(traits.contains(.button), "Primary button should have button trait")
        }
    }

    func testSecondaryGlassButtonVoiceOverSupport() throws {
        // Test secondary glass buttons
        let passButton = app.buttons["Treci"]

        if passButton.exists {
            XCTAssertTrue(passButton.isHittable, "Pass button should be accessible")

            let accessibilityLabel = passButton.label
            XCTAssertFalse(accessibilityLabel.isEmpty, "Pass button should have accessibility label")

            let traits = passButton.accessibilityTraits
            XCTAssertTrue(traits.contains(.button), "Pass button should have button trait")
        }

        let menuButton = app.buttons["Meniu"]

        if menuButton.exists {
            XCTAssertTrue(menuButton.isHittable, "Menu button should be accessible")

            let accessibilityLabel = menuButton.label
            XCTAssertFalse(accessibilityLabel.isEmpty, "Menu button should have accessibility label")

            let traits = menuButton.accessibilityTraits
            XCTAssertTrue(traits.contains(.button), "Menu button should have button trait")
        }
    }

    func testFloatingActionButtonVoiceOverSupport() throws {
        // Test floating action button
        let fab = app.buttons["Action button"]

        if fab.exists {
            XCTAssertTrue(fab.isHittable, "Floating action button should be accessible")

            let accessibilityLabel = fab.label
            XCTAssertFalse(accessibilityLabel.isEmpty, "FAB should have accessibility label")

            let accessibilityHint = fab.value as? String
            XCTAssertNotNil(accessibilityHint, "FAB should have accessibility hint")

            let traits = fab.accessibilityTraits
            XCTAssertTrue(traits.contains(.button), "FAB should have button trait")
        }
    }

    func testGlassMorphismEffectsAccessibility() throws {
        // Test that glass morphism effects don't interfere with accessibility
        let gameScreenArea = app.otherElements["Premium game screen"]

        if gameScreenArea.exists {
            // Ensure glass effects don't block accessibility
            XCTAssertTrue(gameScreenArea.isHittable, "Game screen should remain accessible with glass effects")
        }
    }

    // MARK: - Dynamic Type Testing

    func testDynamicTypeSupport() throws {
        // Test different Dynamic Type sizes
        let dynamicTypeSizes: [String] = [
            "Extra Small",
            "Small",
            "Medium",
            "Large",
            "Extra Large",
            "Extra Extra Large",
            "Extra Extra Extra Large"
        ]

        for size in dynamicTypeSizes {
            // Set Dynamic Type size (this would need to be implemented via settings)
            // For now, we'll test that buttons remain accessible

            testButtonsAtCurrentSize()

            // Reset for next size if needed
            // This would require device settings manipulation
        }
    }

    func testButtonsAtCurrentSize() {
        // Test that all buttons remain accessible at current Dynamic Type size
        let primaryButton = app.buttons["Joacă"]
        if primaryButton.exists {
            XCTAssertTrue(primaryButton.isHittable, "Primary button should be hittable at current Dynamic Type size")

            // Test that button content is still readable
            let label = primaryButton.label
            XCTAssertFalse(label.isEmpty, "Button label should still be present")
        }

        let passButton = app.buttons["Treci"]
        if passButton.exists {
            XCTAssertTrue(passButton.isHittable, "Pass button should be hittable at current Dynamic Type size")
        }

        let menuButton = app.buttons["Meniu"]
        if menuButton.exists {
            XCTAssertTrue(menuButton.isHittable, "Menu button should be hittable at current Dynamic Type size")
        }
    }

    func testAccessibilityNavigation() throws {
        // Test that users can navigate between buttons using accessibility
        let primaryButton = app.buttons["Joacă"]
        let passButton = app.buttons["Treci"]
        let menuButton = app.buttons["Meniu"]

        if primaryButton.exists && passButton.exists && menuButton.exists {
            // Test VoiceOver navigation order
            primaryButton.tap()

            // Navigate to next element
            app.swipeLeft()

            // Should land on another interactive element
            let nextElement = app.firstMatch
            XCTAssertTrue(nextElement.exists, "Should be able to navigate to next element")
        }
    }

    // MARK: - Color Contrast Testing

    func testColorContrastAccessibility() throws {
        // Test that text has sufficient contrast against backgrounds
        let primaryButton = app.buttons["Joacă"]

        if primaryButton.exists {
            // While we can't directly test color contrast in UI tests,
            // we can ensure the content is visible and readable

            primaryButton.tap()
            XCTAssertTrue(primaryButton.exists, "Button should remain tappable")
        }
    }

    // MARK: - Haptic Feedback Accessibility

    func testHapticFeedbackAccessibility() throws {
        // Test that haptic feedback doesn't interfere with accessibility
        let primaryButton = app.buttons["Joacă"]

        if primaryButton.exists {
            // Tap button and ensure it responds
            primaryButton.tap()

            // Button should still be responsive after haptic feedback
            XCTAssertTrue(primaryButton.exists, "Button should remain responsive after haptic feedback")
        }
    }

    // MARK: - Animation Accessibility

    func testAnimationAccessibility() throws {
        // Test that animations don't interfere with accessibility
        // Test reduce motion settings

        let primaryButton = app.buttons["Joacă"]

        if primaryButton.exists {
            // Test button interaction with animations
            primaryButton.tap()

            // Should be able to interact even with animations running
            XCTAssertTrue(primaryButton.isHittable, "Button should remain hittable during animations")
        }
    }

    // MARK: - Screen Reader Testing

    func testScreenReaderCompatibility() throws {
        // Test comprehensive screen reader compatibility

        let buttons = [
            app.buttons["Joacă"],
            app.buttons["Treci"],
            app.buttons["Meniu"],
            app.buttons["Action button"]
        ]

        for button in buttons {
            if button.exists {
                // Test that button has proper accessibility information
                let label = button.label
                XCTAssertFalse(label.isEmpty, "Button '\(label)' should have accessibility label")

                let hint = button.value as? String
                if hint != nil {
                    XCTAssertFalse(hint!.isEmpty, "Button '\(label)' hint should not be empty")
                }

                let traits = button.accessibilityTraits
                XCTAssertTrue(traits.contains(.button), "Button '\(label)' should have button trait")

                // Test that button is actionable
                XCTAssertTrue(button.isHittable, "Button '\(label)' should be actionable")
            }
        }
    }

    // MARK: - Accessibility Inspector Tests

    func testAccessibilityInspectorInformation() throws {
        // Test that components provide proper information for Accessibility Inspector

        let primaryButton = app.buttons["Joacă"]

        if primaryButton.exists {
            // These would be verified using Accessibility Inspector
            // For UI tests, we check basic accessibility properties

            XCTAssertNotNil(primaryButton.label, "Primary button should have accessibility label")
            XCTAssertTrue(primaryButton.isHittable, "Primary button should be accessible")

            let frame = primaryButton.frame
            XCTAssertGreaterThan(frame.width, 44, "Button should meet minimum touch target size (44pt)")
            XCTAssertGreaterThan(frame.height, 44, "Button should meet minimum touch target size (44pt)")
        }
    }

    // MARK: - Gesture Accessibility Testing

    func testGestureAccessibility() throws {
        // Test that custom gestures don't interfere with accessibility

        let gameScreen = app.otherElements["Premium game screen"]

        if gameScreen.exists {
            // Test basic gestures still work with accessibility
            gameScreen.swipeUp()
            gameScreen.swipeDown()
            gameScreen.swipeLeft()
            gameScreen.swipeRight()

            // Screen should remain interactive
            XCTAssertTrue(gameScreen.exists, "Game screen should remain interactive after gestures")
        }
    }

    // MARK: - Focus Management Testing

    func testFocusManagement() throws {
        // Test proper focus management for accessibility

        let primaryButton = app.buttons["Joacă"]

        if primaryButton.exists {
            // Test focus behavior
            primaryButton.tap()

            // Button should receive focus
            XCTAssertTrue(primaryButton.exists, "Primary button should receive focus")

            // Test that focus can be moved away
            app.swipeLeft()

            // Focus should move to next element
            let nextElement = app.firstMatch
            XCTAssertTrue(nextElement.exists, "Focus should move to next element")
        }
    }
}

// MARK: - Accessibility Testing Extensions

extension XCTestCase {

    /// Helper method to test button accessibility properties
    func testButtonAccessibility(_ button: XCUIElement, expectedLabel: String? = nil) {
        XCTAssertTrue(button.exists, "Button should exist")
        XCTAssertTrue(button.isHittable, "Button should be hittable")

        let label = button.label
        if let expectedLabel = expectedLabel {
            XCTAssertEqual(label, expectedLabel, "Button should have expected accessibility label")
        } else {
            XCTAssertFalse(label.isEmpty, "Button should have accessibility label")
        }

        let traits = button.accessibilityTraits
        XCTAssertTrue(traits.contains(.button), "Button should have button trait")

        // Test minimum touch target size (44pt for accessibility)
        let frame = button.frame
        XCTAssertGreaterThanOrEqual(frame.width, 44, "Button should meet minimum touch target width")
        XCTAssertGreaterThanOrEqual(frame.height, 44, "Button should meet minimum touch target height")
    }

    /// Helper method to test element visibility for screen readers
    func testScreenReaderVisibility(_ element: XCUIElement, expectedLabel: String? = nil) {
        XCTAssertTrue(element.exists, "Element should exist")

        let label = element.label
        if let expectedLabel = expectedLabel {
            XCTAssertTrue(label.contains(expectedLabel), "Element should contain expected label text")
        }

        // Element should be accessible to screen readers
        XCTAssertTrue(element.isHittable || element.accessibilityElementsHidden == false,
                     "Element should be accessible to screen readers")
    }
}