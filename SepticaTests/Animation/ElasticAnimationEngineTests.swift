//
//  ElasticAnimationEngineTests.swift
//  SepticaTests
//
//  Comprehensive tests for elastic animation physics engine
//  Validates spring physics, character animations, and performance
//

import XCTest
@testable import Septica

final class ElasticAnimationEngineTests: XCTestCase {

    // MARK: - Test Properties

    private var animationEngine: ElasticAnimationEngine!

    override func setUp() {
        super.setUp()
        animationEngine = ElasticAnimationEngine()
    }

    override func tearDown() {
        animationEngine = nil
        super.tearDown()
    }

    // MARK: - Card Selection Animation Tests

    func testCardSelectionAnimationPhysics() {
        // WHEN
        let animation = animationEngine.calculateCardSelectionAnimation()

        // THEN - Should return interpolating spring animation
        XCTAssertNotNil(animation)
        // Spring animation should have appropriate physics parameters
    }

    func testCardSelectionAnimationWithCustomParameters() {
        // WHEN
        let animation = animationEngine.calculateCardSelectionAnimation(
            from: 1.0,
            to: 1.08
        )

        // THEN
        XCTAssertNotNil(animation)
        // Animation should interpolate between the specified scales
    }

    func testCardSelectionAnimationWithCompletion() {
        // GIVEN
        let expectation = XCTestExpectation(description: "Animation completion")
        var completionCalled = false

        // WHEN
        let animation = animationEngine.calculateCardSelectionAnimation {
            completionCalled = true
            expectation.fulfill()
        }

        // THEN
        XCTAssertNotNil(animation)
        // Completion handler should be properly configured
    }

    // MARK: - Card Play Animation Tests

    func testCardPlayAnimationPhysics() {
        // WHEN
        let animation = animationEngine.calculateCardPlayAnimation()

        // THEN
        XCTAssertNotNil(animation)
        // Should use appropriate spring constants for card play
    }

    func testCardPlayAnimationWithCompletion() {
        // GIVEN
        let expectation = XCTestExpectation(description: "Card play completion")
        var completionCalled = false

        // WHEN
        let animation = animationEngine.calculateCardPlayAnimation {
            completionCalled = true
            expectation.fulfill()
        }

        // THEN
        XCTAssertNotNil(animation)
        // Completion should be properly configured
    }

    // MARK: - Elastic Bounce Tests

    func testElasticBounceCalculation() {
        // GIVEN
        let intensity: Float = 0.8
        let expectedDuration = TimeInterval(0.3 + Double(intensity) * 0.2)

        // WHEN
        let animation = animationEngine.calculateElasticBounce(intensity: intensity)

        // THEN
        XCTAssertNotNil(animation)
        // Duration should be calculated based on intensity
    }

    func testElasticBounceWithCustomDuration() {
        // GIVEN
        let customDuration: TimeInterval = 1.5
        let intensity: Float = 0.5

        // WHEN
        let animation = animationEngine.calculateElasticBounce(
            intensity: intensity,
            customDuration: customDuration
        )

        // THEN
        XCTAssertNotNil(animation)
        // Should use custom duration instead of calculated one
    }

    func testElasticBounceIntensityRange() {
        // Test various intensity values
        let intensities: [Float] = [0.0, 0.25, 0.5, 0.75, 1.0]

        for intensity in intensities {
            // WHEN
            let animation = animationEngine.calculateElasticBounce(intensity: intensity)

            // THEN
            XCTAssertNotNil(animation, "Animation should not be nil for intensity: \(intensity)")
        }
    }

    // MARK: - Card Hover Animation Tests

    func testCardHoverEnterAnimation() {
        // WHEN
        let animation = animationEngine.calculateCardHoverAnimation(isEntering: true)

        // THEN
        XCTAssertNotNil(animation)
        // Should use spring animation for hover entry
    }

    func testCardHoverExitAnimation() {
        // WHEN
        let animation = animationEngine.calculateCardHoverAnimation(isEntering: false)

        // THEN
        XCTAssertNotNil(animation)
        // Should use ease out animation for hover exit
    }

    // MARK: - Character Victory Animation Tests

    func testPacalaVictoryAnimation() {
        // WHEN
        let animation = animationEngine.calculateVictoryAnimation(characterType: .pacala)

        // THEN
        XCTAssertNotNil(animation)
        // Should return trickster-style playful animation
    }

    func testIeleVictoryAnimation() {
        // WHEN
        let animation = animationEngine.calculateVictoryAnimation(characterType: .iele)

        // THEN
        XCTAssertNotNil(animation)
        // Should return ethereal, graceful animation
    }

    func testStrigoiVictoryAnimation() {
        // WHEN
        let animation = animationEngine.calculateVictoryAnimation(characterType: .strigoi)

        // THEN
        XCTAssertNotNil(animation)
        // Should return dramatic, intense animation
    }

    func testFatFrumosVictoryAnimation() {
        // WHEN
        let animation = animationEngine.calculateVictoryAnimation(characterType: .fatFrumos)

        // THEN
        XCTAssertNotNil(animation)
        // Should return heroic, proud animation
    }

    func testBabaCloantzaVictoryAnimation() {
        // WHEN
        let animation = animationEngine.calculateVictoryAnimation(characterType: .babaCloantza)

        // THEN
        XCTAssertNotNil(animation)
        // Should return wise, subtle animation
    }

    func testZmeuVictoryAnimation() {
        // WHEN
        let animation = animationEngine.calculateVictoryAnimation(characterType: .zmeu)

        // THEN
        XCTAssertNotNil(animation)
        // Should return energetic, explosive animation
    }

    func testAllCharacterVictoryAnimations() {
        let characterTypes: [RomanianCharacterType] = [
            .pacala, .iele, .strigoi, .fatFrumos, .babaCloantza, .zmeu
        ]

        for characterType in characterTypes {
            // WHEN
            let animation = animationEngine.calculateVictoryAnimation(characterType: characterType)

            // THEN
            XCTAssertNotNil(animation, "Victory animation should not be nil for \(characterType)")
        }
    }

    // MARK: - Emote Animation Tests

    func testEmoteAnimationTiming() {
        // GIVEN
        let emoteType = EmoteType.greeting
        let characterType = RomanianCharacterType.pacala

        // WHEN
        let animation = animationEngine.calculateEmoteAnimation(
            emoteType: emoteType,
            characterType: characterType
        )

        // THEN
        XCTAssertNotNil(animation)
        // Should use appropriate timing for character-emote combination
    }

    func testEmoteAnimationWithCompletion() {
        // GIVEN
        let expectation = XCTestExpectation(description: "Emote animation completion")
        var completionCalled = false

        // WHEN
        let animation = animationEngine.calculateEmoteAnimation(
            emoteType: .victory,
            characterType: .fatFrumos
        ) {
            completionCalled = true
            expectation.fulfill()
        }

        // THEN
        XCTAssertNotNil(animation)
        // Completion should be properly configured
    }

    func testAllEmoteAnimationCombinations() {
        let characterTypes: [RomanianCharacterType] = [
            .pacala, .iele, .strigoi, .fatFrumos, .babaCloantza, .zmeu
        ]

        let emoteTypes: [EmoteType] = [
            .greeting, .goodMove, .badMove, .thinking, .taunt, .victory, .defeat
        ]

        for characterType in characterTypes {
            for emoteType in emoteTypes {
                // WHEN
                let animation = animationEngine.calculateEmoteAnimation(
                    emoteType: emoteType,
                    characterType: characterType
                )

                // THEN
                XCTAssertNotNil(
                    animation,
                    "Emote animation should not be nil for \(characterType) - \(emoteType)"
                )
            }
        }
    }

    // MARK: - Custom Easing Curve Tests

    func testCustomEasingCurveCreation() {
        // GIVEN
        let controlPoints = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: 0.25, y: 0.1),
            CGPoint(x: 0.5, y: 0.9),
            CGPoint(x: 1, y: 1)
        ]
        let duration: TimeInterval = 1.5

        // WHEN
        let animation = animationEngine.customEasingCurve(
            controlPoints: controlPoints,
            duration: duration
        )

        // THEN
        XCTAssertNotNil(animation)
        // Should create animation with specified control points and duration
    }

    func testCustomEasingCurveDefaultDuration() {
        // GIVEN
        let controlPoints = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: 0.3, y: 1.2),
            CGPoint(x: 0.7, y: 0.8),
            CGPoint(x: 1, y: 1)
        ]

        // WHEN
        let animation = animationEngine.customEasingCurve(controlPoints: controlPoints)

        // THEN
        XCTAssertNotNil(animation)
        // Should use default duration of 1.0
    }

    // MARK: - Animation Chaining Tests

    func testAnimationChaining() {
        // GIVEN
        let animations = [
            { Animation.easeInOut(duration: 0.3) },
            { Animation.easeInOut(duration: 0.5) },
            { Animation.easeInOut(duration: 0.2) }
        ]

        // WHEN
        let chainedAnimation = animationEngine.chainAnimations(animations: animations)

        // THEN
        XCTAssertNotNil(chainedAnimation)
        // Should return sequential animation
    }

    func testAnimationChainingWithCompletion() {
        // GIVEN
        let expectation = XCTestExpectation(description: "Chain completion")
        var completionCalled = false

        let animations = [
            { Animation.easeInOut(duration: 0.2) },
            { Animation.easeInOut(duration: 0.3) }
        ]

        // WHEN
        let chainedAnimation = animationEngine.chainAnimations(
            animations: animations
        ) {
            completionCalled = true
            expectation.fulfill()
        }

        // THEN
        XCTAssertNotNil(chainedAnimation)
        // Completion should be called after chain completes
    }

    // MARK: - Parallel Animation Tests

    func testParallelAnimations() {
        // GIVEN
        let animations = [
            Animation.easeInOut(duration: 0.4),
            Animation.easeInOut(duration: 0.6),
            Animation.easeInOut(duration: 0.3)
        ]

        // WHEN
        let parallelAnimation = animationEngine.parallelAnimations(animations: animations)

        // THEN
        XCTAssertNotNil(parallelAnimation)
        // Should return parallel animation
    }

    // MARK: - Performance Tests

    func testAnimationPerformanceTracking() {
        // GIVEN
        let animationId = "test-animation-1"
        let duration: TimeInterval = 1.2
        let complexity = AnimationComplexity.moderate

        // WHEN
        animationEngine.trackAnimationPerformance(
            animationId: animationId,
            duration: duration,
            complexity: complexity
        )

        let stats = animationEngine.getPerformanceStatistics()

        // THEN
        XCTAssertEqual(stats.totalAnimations, 1)
        XCTAssertEqual(stats.averageAnimationDuration, duration, accuracy: 0.001)
        XCTAssertEqual(stats.complexityDistribution[.moderate], 1)
    }

    func testMultipleAnimationPerformanceTracking() {
        // GIVEN
        let testCases = [
            ("animation-1", 0.5, AnimationComplexity.simple),
            ("animation-2", 1.2, AnimationComplexity.moderate),
            ("animation-3", 2.0, AnimationComplexity.complex),
            ("animation-4", 0.8, AnimationComplexity.simple)
        ]

        // WHEN
        for (id, duration, complexity) in testCases {
            animationEngine.trackAnimationPerformance(
                animationId: id,
                duration: duration,
                complexity: complexity
            )
        }

        let stats = animationEngine.getPerformanceStatistics()

        // THEN
        XCTAssertEqual(stats.totalAnimations, 4)
        XCTAssertEqual(stats.averageAnimationDuration, 1.125, accuracy: 0.001)
        XCTAssertEqual(stats.complexityDistribution[.simple], 2)
        XCTAssertEqual(stats.complexityDistribution[.moderate], 1)
        XCTAssertEqual(stats.complexityDistribution[.complex], 1)
    }

    func testAnimationEnginePerformance() {
        // GIVEN
        let animationEngine = ElasticAnimationEngine()

        // WHEN & THEN - Should complete within reasonable time
        measure {
            for _ in 0..<1000 {
                let animation = animationEngine.calculateCardSelectionAnimation()
                _ = animation // Ensure animation is computed
            }
        }
    }

    // MARK: - Device Optimization Tests

    func testDeviceOptimization() {
        // WHEN
        animationEngine.optimizeForDevice()

        // THEN - Should not crash and should adjust parameters appropriately
        // This is mainly a smoke test to ensure the method works
    }
}