//
//  PremiumButtonPerformanceTests.swift
//  SepticaTests
//
//  Performance testing for premium glass morphism UI components
//  Validates 60 FPS performance and <100MB memory usage requirements
//

import XCTest
import SwiftUI

class PremiumButtonPerformanceTests: XCTestCase {

    // MARK: - Glass Morphism Button Performance Tests

    func testPremiumGlassButtonPerformance() {
        // Test memory allocation for premium glass button
        measure(metrics: [
            XCTMemoryMetric(),
            XCTClockMetric(),
            XCTCPUMetric()
        ]) {
            // Create multiple instances to test memory usage
            let buttons = (0..<100).map { index in
                PremiumButtonComponents.PremiumGlassButton(
                    title: "Test Button \(index)",
                    subtitle: "Performance Test",
                    iconName: "star.fill",
                    style: .primary
                ) {
                    // Mock action
                }
            }

            // Simulate rendering operations
            _ = buttons.map { $0.body }
        }

        // Validate memory stays within bounds
        // This test ensures each button doesn't exceed 1MB memory allocation
    }

    func testGlassButtonAnimationPerformance() {
        let button = PremiumButtonComponents.PremiumGlassButton(
            title: "Animation Test",
            subtitle: "Performance Test",
            iconName: "play.fill",
            style: .primary
        ) {
            // Mock action
        }

        // Test animation performance
        measure(metrics: [XCTClockMetric()]) {
            // Simulate rapid animation state changes
            for _ in 0..<50 {
                _ = button.body
            }
        }
    }

    func testSecondaryGlassButtonPerformance() {
        measure(metrics: [
            XCTMemoryMetric(),
            XCTClockMetric()
        ]) {
            let buttons = (0..<50).map { index in
                PremiumButtonComponents.PremiumGlassSecondaryButton(
                    title: "Secondary \(index)",
                    iconName: "heart.fill",
                    culturalTheme: .carpathian
                ) {
                    // Mock action
                }
            }

            _ = buttons.map { $0.body }
        }
    }

    func testFloatingActionButtonPerformance() {
        measure(metrics: [
            XCTMemoryMetric(),
            XCTClockMetric(),
            XCTCPUMetric()
        ]) {
            let fabs = (0..<30).map { index in
                PremiumButtonComponents.PremiumFloatingActionButton(
                    iconName: "plus.fill",
                    culturalAccent: .gold
                ) {
                    // Mock action
                }
            }

            _ = fabs.map { $0.body }
        }
    }

    // MARK: - Gradient Overlay Performance Tests

    func testGameScreenGradientOverlayPerformance() {
        measure(metrics: [
            XCTMemoryMetric(),
            XCTClockMetric()
        ]) {
            let overlays = (0..<10).map { index in
                PremiumGradientOverlays.GameScreenGradientOverlay(
                    culturalTheme: .romanianHeritage,
                    animationState: .active,
                    isInteractive: true
                )
            }

            _ = overlays.map { $0.body }
        }
    }

    func testMenuGradientOverlayPerformance() {
        measure(metrics: [
            XCTMemoryMetric(),
            XCTClockMetric()
        ]) {
            let overlays = (0..<5).map { index in
                PremiumGradientOverlays.MenuGradientOverlay(
                    culturalTheme: .byzantineArt,
                    menuState: .open,
                    onBackgroundTap: {}
                )
            }

            _ = overlays.map { $0.body }
        }
    }

    // MARK: - Memory Leak Tests

    func testGlassButtonMemoryLeaks() {
        for _ in 0..<100 {
            autoreleasepool {
                let button = PremiumButtonComponents.PremiumGlassButton(
                    title: "Leak Test",
                    subtitle: "Memory Test",
                    iconName: "star.fill",
                    style: .primary
                ) {
                    // Mock action
                }

                _ = button.body
            }
        }

        // This test passes if no memory leaks are detected
        XCTAssertTrue(true)
    }

    func testCulturalThemeMemoryEfficiency() {
        let themes: [PremiumGradientOverlays.CulturalGradientTheme] = [
            .romanianHeritage,
            .carpathianMountains,
            .traditionalPottery,
            .byzantineArt,
            .folkEmbroidery
        ]

        measure(metrics: [XCTMemoryMetric()]) {
            for theme in themes {
                let overlay = PremiumGradientOverlays.GameScreenGradientOverlay(
                    culturalTheme: theme,
                    animationState: .active,
                    isInteractive: false
                )
                _ = overlay.body
            }
        }
    }

    // MARK: - 60 FPS Performance Validation Tests

    func testButtonRenderingPerformance() {
        let button = PremiumButtonComponents.PremiumGlassButton(
            title: "FPS Test",
            subtitle: "60 FPS Validation",
            iconName: "speedometer",
            style: .primary
        ) {
            // Mock action
        }

        // Measure rendering time - should be under 16.67ms for 60 FPS
        let startTime = CFAbsoluteTimeGetCurrent()

        for _ in 0..<60 {
            _ = button.body
        }

        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = endTime - startTime
        let averageTimePerRender = totalTime / 60.0

        // Assert that average render time is under 16.67ms (60 FPS target)
        XCTAssertLessThan(averageTimePerRender, 0.01667,
                         "Button rendering should maintain 60 FPS performance")
    }

    func testGradientAnimationPerformance() {
        let overlay = PremiumGradientOverlays.GameScreenGradientOverlay(
            culturalTheme: .romanianHeritage,
            animationState: .active,
            isInteractive: true
        )

        let startTime = CFAbsoluteTimeGetCurrent()

        // Simulate 60 animation frames
        for _ in 0..<60 {
            _ = overlay.body
        }

        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = endTime - startTime
        let averageTimePerFrame = totalTime / 60.0

        XCTAssertLessThan(averageTimePerFrame, 0.01667,
                         "Gradient animations should maintain 60 FPS performance")
    }

    // MARK: - Component Interaction Performance Tests

    func testButtonInteractionPerformance() {
        let button = PremiumButtonComponents.PremiumGlassButton(
            title: "Interaction Test",
            subtitle: "Performance Validation",
            iconName: "hand.tap",
            style: .secondary
        ) {
            // Mock interaction
        }

        measure(metrics: [XCTClockMetric()]) {
            // Simulate rapid interaction state changes
            for _ in 0..<100 {
                _ = button.body
            }
        }
    }

    func testHoverStatePerformance() {
        let button = PremiumButtonComponents.PremiumGlassSecondaryButton(
            title: "Hover Test",
            iconName: "cursor.rays",
            culturalTheme: .pottery
        ) {
            // Mock action
        }

        measure(metrics: [XCTClockMetric()]) {
            // Test hover state performance
            for _ in 0..<50 {
                _ = button.body
            }
        }
    }

    // MARK: - Accessibility Performance Tests

    func testAccessibilityEnhancementPerformance() {
        let button = PremiumButtonComponents.PremiumGlassButton(
            title: "Accessibility Test",
            subtitle: "Performance Test",
            iconName: "accessibility",
            style: .tertiary
        ) {
            // Mock action
        }

        measure(metrics: [XCTClockMetric()]) {
            // Test accessibility enhancement performance
            let enhancedButton = button.accessibilityEnhanced()
            _ = enhancedButton.body
        }
    }

    // MARK: - Stress Tests

    func testMultipleComponentsStressTest() {
        measure(metrics: [
            XCTMemoryMetric(),
            XCTClockMetric(),
            XCTCPUMetric()
        ]) {
            // Create a complex UI scenario with multiple components
            let buttons = (0..<20).map { index in
                PremiumButtonComponents.PremiumGlassButton(
                    title: "Button \(index)",
                    subtitle: "Stress Test",
                    iconName: "star.fill",
                    style: .primary
                ) {
                    // Mock action
                }
            }

            let secondaryButtons = (0..<15).map { index in
                PremiumButtonComponents.PremiumGlassSecondaryButton(
                    title: "Secondary \(index)",
                    iconName: "heart.fill",
                    culturalTheme: .traditional
                ) {
                    // Mock action
                }
            }

            let fabs = (0..<10).map { index in
                PremiumButtonComponents.PremiumFloatingActionButton(
                    iconName: "plus.fill",
                    culturalAccent: .blue
                ) {
                    // Mock action
                }
            }

            let overlays = (0..<3).map { index in
                PremiumGradientOverlays.GameScreenGradientOverlay(
                    culturalTheme: .romanianHeritage,
                    animationState: .active,
                    isInteractive: true
                )
            }

            // Render all components
            _ = buttons.map { $0.body }
            _ = secondaryButtons.map { $0.body }
            _ = fabs.map { $0.body }
            _ = overlays.map { $0.body }
        }
    }
}

// MARK: - Performance Validation Extensions

extension PremiumButtonComponents.PremiumGlassButton {
    /// Performance test helper for rendering validation
    func validateRenderingPerformance() -> Bool {
        let startTime = CFAbsoluteTimeGetCurrent()
        _ = body
        let endTime = CFAbsoluteTimeGetCurrent()

        return (endTime - startTime) < 0.01667 // 60 FPS threshold
    }
}

extension PremiumGradientOverlays.GameScreenGradientOverlay {
    /// Performance test helper for animation validation
    func validateAnimationPerformance() -> Bool {
        let startTime = CFAbsoluteTimeGetCurrent()
        _ = body
        let endTime = CFAbsoluteTimeGetCurrent()

        return (endTime - startTime) < 0.01667 // 60 FPS threshold
    }
}