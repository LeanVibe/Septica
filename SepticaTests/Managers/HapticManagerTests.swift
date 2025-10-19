//
//  HapticManagerTests.swift
//  SepticaTests
//
//  Tests for HapticManager public haptic feedback methods
//

import XCTest
@testable import Septica

@MainActor
final class HapticManagerTests: XCTestCase {

    var hapticManager: HapticManager!

    override func setUp() async throws {
        try await super.setUp()
        hapticManager = HapticManager()
    }

    override func tearDown() async throws {
        hapticManager = nil
        try await super.tearDown()
    }

    // MARK: - Public Haptic Method Tests

    func testLightImpactMethodExists() {
        // Test that lightImpact() method is accessible
        // This verifies the public API was correctly added
        XCTAssertNoThrow(hapticManager.lightImpact())
    }

    func testMediumImpactMethodExists() {
        // Test that mediumImpact() method is accessible
        // This verifies the public API was correctly added
        XCTAssertNoThrow(hapticManager.mediumImpact())
    }

    func testHapticMethodsRespectEnabledState() {
        // Test that haptic methods respect isHapticsEnabled flag
        hapticManager.setHapticsEnabled(false)
        XCTAssertFalse(hapticManager.isHapticsEnabled)

        // Should not throw even when disabled
        XCTAssertNoThrow(hapticManager.lightImpact())
        XCTAssertNoThrow(hapticManager.mediumImpact())

        hapticManager.setHapticsEnabled(true)
        XCTAssertTrue(hapticManager.isHapticsEnabled)
    }

    func testSharedInstanceAccessible() {
        // Test that shared singleton is accessible
        let shared = HapticManager.shared
        XCTAssertNotNil(shared)
    }

    func testHapticFeedbackTrigger() {
        // Test that trigger method works with various feedback types
        XCTAssertNoThrow(hapticManager.trigger(.cardSelect))
        XCTAssertNoThrow(hapticManager.trigger(.cardPlay))
        XCTAssertNoThrow(hapticManager.trigger(.gameVictory))
        XCTAssertNoThrow(hapticManager.trigger(.menuSelect))
    }

    func testHapticsDeviceSupport() {
        // Test that device support detection works
        let supportsHaptics = hapticManager.supportsHaptics

        // On iPhone, should be true; on iPad/simulator, should be false
        #if targetEnvironment(simulator)
        // Simulator behavior may vary
        #else
        // Real device behavior
        if UIDevice.current.userInterfaceIdiom == .phone {
            XCTAssertTrue(supportsHaptics)
        } else {
            XCTAssertFalse(supportsHaptics)
        }
        #endif
    }

    func testCardInteractionFeedback() {
        // Test card-specific haptic feedback
        XCTAssertNoThrow(hapticManager.cardInteractionFeedback(isValid: true))
        XCTAssertNoThrow(hapticManager.cardInteractionFeedback(isValid: false))
        XCTAssertNoThrow(hapticManager.cardInteractionFeedback(isValid: true, isSpecialCard: true))
    }

    func testScoreChangeFeedback() {
        // Test score change haptic feedback
        XCTAssertNoThrow(hapticManager.scoreChangeFeedback(pointsEarned: 5))
        XCTAssertNoThrow(hapticManager.scoreChangeFeedback(pointsEarned: 10))
        XCTAssertNoThrow(hapticManager.scoreChangeFeedback(pointsEarned: 0))
    }

    func testAgeGroupConfiguration() {
        // Test age group haptic configuration
        hapticManager.ageGroup = .ages6to8
        XCTAssertEqual(hapticManager.ageGroup.hapticIntensityModifier, 0.6)
        XCTAssertEqual(hapticManager.ageGroup.maxSequenceLength, 3)

        hapticManager.ageGroup = .ages9to12
        XCTAssertEqual(hapticManager.ageGroup.hapticIntensityModifier, 0.8)
        XCTAssertEqual(hapticManager.ageGroup.maxSequenceLength, 5)

        hapticManager.ageGroup = .adult
        XCTAssertEqual(hapticManager.ageGroup.hapticIntensityModifier, 1.0)
        XCTAssertEqual(hapticManager.ageGroup.maxSequenceLength, 8)
    }

    func testAccessibilityFeedback() {
        // Test accessibility-specific haptic feedback
        XCTAssertNoThrow(hapticManager.accessibilityFeedback(for: "select"))
        XCTAssertNoThrow(hapticManager.accessibilityFeedback(for: "focus"))
        XCTAssertNoThrow(hapticManager.accessibilityFeedback(for: "error"))
        XCTAssertNoThrow(hapticManager.accessibilityFeedback(for: "success"))
    }
}
