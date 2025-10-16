//
//  CardTrajectoryAnimatorTests.swift
//  SepticaTests
//
//  Comprehensive tests for card trajectory animation system
//  Validates arc calculations, path generation, and animation performance
//

import XCTest
@testable import Septica

final class CardTrajectoryAnimatorTests: XCTestCase {

    // MARK: - Test Properties

    private var trajectoryAnimator: CardTrajectoryAnimator!

    override func setUp() {
        super.setUp()
        trajectoryAnimator = CardTrajectoryAnimator()
    }

    override func tearDown() {
        trajectoryAnimator = nil
        super.tearDown()
    }

    // MARK: - Play Trajectory Tests

    func testPlayTrajectoryCalculation() {
        // GIVEN
        let startPoint = CGPoint(x: 100, y: 200)
        let endPoint = CGPoint(x: 300, y: 400)
        let expectedHeight: CGFloat = 100.0

        // WHEN
        let trajectory = trajectoryAnimator.calculatePlayTrajectory(
            from: startPoint,
            to: endPoint,
            height: expectedHeight
        )

        // THEN
        XCTAssertFalse(trajectory.isEmpty, "Trajectory should not be empty")
        XCTAssertEqual(trajectory.first, startPoint, "Trajectory should start at start point")
        XCTAssertEqual(trajectory.last, endPoint, "Trajectory should end at end point")

        // Check that trajectory creates an arc (middle point should be higher than start/end)
        let middleIndex = trajectory.count / 2
        let middlePoint = trajectory[middleIndex]
        XCTAssertGreaterThan(
            middlePoint.y,
            min(startPoint.y, endPoint.y),
            "Middle point should create an arc"
        )
    }

    func testPlayTrajectoryWithDifferentHeights() {
        // GIVEN
        let startPoint = CGPoint(x: 50, y: 100)
        let endPoint = CGPoint(x: 250, y: 150)
        let heights: [CGFloat] = [30.0, 100.0, 200.0]

        for height in heights {
            // WHEN
            let trajectory = trajectoryAnimator.calculatePlayTrajectory(
                from: startPoint,
                to: endPoint,
                height: height
            )

            // THEN
            XCTAssertFalse(trajectory.isEmpty, "Trajectory should not be empty for height: \(height)")
            XCTAssertEqual(trajectory.count, 21, "Should have 21 points for smoothness") // 0-20 inclusive
        }
    }

    func testPlayTrajectoryDownwardArc() {
        // GIVEN
        let startPoint = CGPoint(x: 100, y: 100) // Higher point
        let endPoint = CGPoint(x: 300, y: 300)   // Lower point

        // WHEN
        let trajectory = trajectoryAnimator.calculatePlayTrajectory(
            from: startPoint,
            to: endPoint
        )

        // THEN
        XCTAssertFalse(trajectory.isEmpty)

        // For downward movement, arc should go up first
        let middleIndex = trajectory.count / 2
        let middlePoint = trajectory[middleIndex]
        XCTAssertLessThan(middlePoint.y, startPoint.y, "Arc should go up for downward movement")
    }

    func testPlayTrajectoryUpwardArc() {
        // GIVEN
        let startPoint = CGPoint(x: 100, y: 300) // Lower point
        let endPoint = CGPoint(x: 300, y: 100)   // Higher point

        // WHEN
        let trajectory = trajectoryAnimator.calculatePlayTrajectory(
            from: startPoint,
            to: endPoint
        )

        // THEN
        XCTAssertFalse(trajectory.isEmpty)

        // For upward movement, arc should go down first
        let middleIndex = trajectory.count / 2
        let middlePoint = trajectory[middleIndex]
        XCTAssertGreaterThan(middlePoint.y, startPoint.y, "Arc should go down for upward movement")
    }

    // MARK: - Card Flip Animation Tests

    func testCardFlipAnimationDefaultParameters() {
        // GIVEN
        let startPosition = CGPoint(x: 100, y: 200)
        let endPosition = CGPoint(x: 200, y: 300)

        // WHEN
        let animation = trajectoryAnimator.calculateCardFlipAnimation(
            from: startPosition,
            to: endPosition
        )

        // THEN
        XCTAssertNotNil(animation, "Card flip animation should not be nil")
    }

    func testCardFlipAnimationWithXAxis() {
        // GIVEN
        let startPosition = CGPoint(x: 50, y: 150)
        let endPosition = CGPoint(x: 250, y: 350)

        // WHEN
        let animation = trajectoryAnimator.calculateCardFlipAnimation(
            from: startPosition,
            to: endPosition,
            flipAxis: "x",
            flipCount: 2
        )

        // THEN
        XCTAssertNotNil(animation, "X-axis flip animation should not be nil")
    }

    func testCardFlipAnimationWithYAxis() {
        // GIVEN
        let startPosition = CGPoint(x: 150, y: 100)
        let endPosition = CGPoint(x: 350, y: 200)

        // WHEN
        let animation = trajectoryAnimator.calculateCardFlipAnimation(
            from: startPosition,
            to: endPosition,
            flipAxis: "y",
            flipCount: 3
        )

        // THEN
        XCTAssertNotNil(animation, "Y-axis flip animation should not be nil")
    }

    func testCardFlipAnimationMultipleFlips() {
        // GIVEN
        let startPosition = CGPoint(x: 0, y: 0)
        let endPosition = CGPoint(x: 100, y: 100)
        let flipCounts = [1, 2, 3, 5]

        for flipCount in flipCounts {
            // WHEN
            let animation = trajectoryAnimator.calculateCardFlipAnimation(
                from: startPosition,
                to: endPosition,
                flipCount: flipCount
            )

            // THEN
            XCTAssertNotNil(animation, "Animation with \(flipCount) flips should not be nil")
        }
    }

    // MARK: - Path Animation Tests

    func testAnimateAlongPath() {
        // GIVEN
        let path = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: 50, y: 25),
            CGPoint(x: 100, y: 0),
            CGPoint(x: 150, y: 25),
            CGPoint(x: 200, y: 0)
        ]
        let duration: TimeInterval = 1.5
        var completionCalled = false

        // WHEN
        let animation = trajectoryAnimator.animateAlongPath(
            path: path,
            duration: duration
        ) {
            completionCalled = true
        }

        // THEN
        XCTAssertNotNil(animation, "Path animation should not be nil")
    }

    func testAnimateAlongEmptyPath() {
        // GIVEN
        let emptyPath: [CGPoint] = []
        let duration: TimeInterval = 1.0

        // WHEN
        let animation = trajectoryAnimator.animateAlongPath(
            path: emptyPath,
            duration: duration
        )

        // THEN
        XCTAssertNotNil(animation, "Empty path animation should fallback to easeInOut")
    }

    func testAnimateAlongSinglePointPath() {
        // GIVEN
        let singlePointPath = [CGPoint(x: 100, y: 100)]
        let duration: TimeInterval = 0.5

        // WHEN
        let animation = trajectoryAnimator.animateAlongPath(
            path: singlePointPath,
            duration: duration
        )

        // THEN
        XCTAssertNotNil(animation, "Single point path animation should not be nil")
    }

    // MARK: - Shuffle Trajectory Tests

    func testShuffleTrajectoryCalculation() {
        // GIVEN
        let centerPoint = CGPoint(x: 200, y: 200)
        let radius: CGFloat = 50
        let cardCount = 10
        let cardIndex = 3

        // WHEN
        let trajectory = trajectoryAnimator.calculateShuffleTrajectory(
            centerPoint: centerPoint,
            radius: radius,
            cardCount: cardCount,
            cardIndex: cardIndex
        )

        // THEN
        XCTAssertFalse(trajectory.isEmpty, "Shuffle trajectory should not be empty")

        // Verify points are roughly at the correct distance from center
        for point in trajectory {
            let distance = point.distance(to: centerPoint)
            XCTAssertEqual(
                distance,
                radius,
                accuracy: 5.0,
                "Point should be approximately radius distance from center"
            )
        }
    }

    func testShuffleTrajectoryDifferentCardCounts() {
        // GIVEN
        let centerPoint = CGPoint(x: 150, y: 150)
        let radius: CGFloat = 40
        let cardCounts = [5, 10, 20, 52]

        for cardCount in cardCounts {
            for cardIndex in 0..<cardCount {
                // WHEN
                let trajectory = trajectoryAnimator.calculateShuffleTrajectory(
                    centerPoint: centerPoint,
                    radius: radius,
                    cardCount: cardCount,
                    cardIndex: cardIndex
                )

                // THEN
                XCTAssertFalse(
                    trajectory.isEmpty,
                    "Trajectory should not be empty for \(cardCount) cards, index \(cardIndex)"
                )
            }
        }
    }

    func testShuffleTrajectoryEdgeCases() {
        // GIVEN
        let centerPoint = CGPoint(x: 100, y: 100)
        let radius: CGFloat = 30

        // WHEN - Single card
        let singleCardTrajectory = trajectoryAnimator.calculateShuffleTrajectory(
            centerPoint: centerPoint,
            radius: radius,
            cardCount: 1,
            cardIndex: 0
        )

        // THEN
        XCTAssertFalse(singleCardTrajectory.isEmpty)

        // WHEN - First and last card in large deck
        let firstCardTrajectory = trajectoryAnimator.calculateShuffleTrajectory(
            centerPoint: centerPoint,
            radius: radius,
            cardCount: 52,
            cardIndex: 0
        )

        let lastCardTrajectory = trajectoryAnimator.calculateShuffleTrajectory(
            centerPoint: centerPoint,
            radius: radius,
            cardCount: 52,
            cardIndex: 51
        )

        // THEN
        XCTAssertFalse(firstCardTrajectory.isEmpty)
        XCTAssertFalse(lastCardTrajectory.isEmpty)
    }

    // MARK: - Dealing Trajectory Tests

    func testDealingTrajectorySmoothStyle() {
        // GIVEN
        let deckPosition = CGPoint(x: 200, y: 100)
        let playerPosition = CGPoint(x: 100, y: 300)

        // WHEN
        let trajectory = trajectoryAnimator.calculateDealingTrajectory(
            from: deckPosition,
            to: playerPosition,
            dealingStyle: .smooth
        )

        // THEN
        XCTAssertFalse(trajectory.isEmpty, "Smooth dealing trajectory should not be empty")
        XCTAssertEqual(trajectory.first, deckPosition)
        XCTAssertEqual(trajectory.last, playerPosition)
    }

    func testDealingTrajectoryDirectStyle() {
        // GIVEN
        let deckPosition = CGPoint(x: 150, y: 50)
        let playerPosition = CGPoint(x: 250, y: 350)

        // WHEN
        let trajectory = trajectoryAnimator.calculateDealingTrajectory(
            from: deckPosition,
            to: playerPosition,
            dealingStyle: .direct
        )

        // THEN
        XCTAssertFalse(trajectory.isEmpty, "Direct dealing trajectory should not be empty")
        XCTAssertEqual(trajectory.count, 2, "Direct trajectory should have exactly 2 points")
        XCTAssertEqual(trajectory.first, deckPosition)
        XCTAssertEqual(trajectory.last, playerPosition)
    }

    func testDealingTrajectoryCircularStyle() {
        // GIVEN
        let deckPosition = CGPoint(x: 100, y: 100)
        let playerPosition = CGPoint(x: 300, y: 200)

        // WHEN
        let trajectory = trajectoryAnimator.calculateDealingTrajectory(
            from: deckPosition,
            to: playerPosition,
            dealingStyle: .circular
        )

        // THEN
        XCTAssertFalse(trajectory.isEmpty, "Circular dealing trajectory should not be empty")
        XCTAssertEqual(trajectory.first, deckPosition)
        XCTAssertEqual(trajectory.last, playerPosition)

        // Circular trajectory should have more points than direct
        XCTAssertGreaterThan(trajectory.count, 2, "Circular trajectory should have more than 2 points")
    }

    // MARK: - Victory Trajectory Tests

    func testVictoryTrajectoryBounce() {
        // GIVEN
        let cardPosition = CGPoint(x: 200, y: 200)

        // WHEN
        let trajectory = trajectoryAnimator.calculateVictoryTrajectory(
            from: cardPosition,
            celebrationType: .bounce
        )

        // THEN
        XCTAssertFalse(trajectory.isEmpty, "Bounce trajectory should not be empty")
        XCTAssertEqual(trajectory.first, cardPosition, "Bounce should start from card position")

        // Bounce should go up and come back down
        let maxY = trajectory.map { $0.y }.max() ?? 0
        XCTAssertLessThan(maxY, cardPosition.y, "Bounce should go up (negative y direction)")
    }

    func testVictoryTrajectorySpiral() {
        // GIVEN
        let cardPosition = CGPoint(x: 150, y: 250)

        // WHEN
        let trajectory = trajectoryAnimator.calculateVictoryTrajectory(
            from: cardPosition,
            celebrationType: .spiral
        )

        // THEN
        XCTAssertFalse(trajectory.isEmpty, "Spiral trajectory should not be empty")
        XCTAssertEqual(trajectory.first, cardPosition, "Spiral should start from card position")

        // Spiral should create a circular pattern
        // Check that points move away from and back to center
        let distances = trajectory.map { $0.distance(to: cardPosition) }
        let maxDistance = distances.max() ?? 0
        XCTAssertGreaterThan(maxDistance, 0, "Spiral should move away from center")
    }

    func testVictoryTrajectoryFloat() {
        // GIVEN
        let cardPosition = CGPoint(x: 300, y: 150)

        // WHEN
        let trajectory = trajectoryAnimator.calculateVictoryTrajectory(
            from: cardPosition,
            celebrationType: .float
        )

        // THEN
        XCTAssertFalse(trajectory.isEmpty, "Float trajectory should not be empty")
        XCTAssertEqual(trajectory.first, cardPosition, "Float should start from card position")

        // Float should move up and down with slight horizontal movement
        let yValues = trajectory.map { $0.y }
        let minY = yValues.min() ?? 0
        let maxY = yValues.max() ?? 0
        XCTAssertLessThan(minY, cardPosition.y, "Float should go up")
        XCTAssertGreaterThan(maxY, cardPosition.y, "Float should come back down")
    }

    func testVictoryTrajectorySpin() {
        // GIVEN
        let cardPosition = CGPoint(x: 100, y: 100)

        // WHEN
        let trajectory = trajectoryAnimator.calculateVictoryTrajectory(
            from: cardPosition,
            celebrationType: .spin
        )

        // THEN
        XCTAssertFalse(trajectory.isEmpty, "Spin trajectory should not be empty")
        XCTAssertEqual(trajectory.first, cardPosition, "Spin should start from card position")

        // Spin should create circular motion around the card position
        let distances = trajectory.map { $0.distance(to: cardPosition) }
        let maxDistance = distances.max() ?? 0
        XCTAssertGreaterThan(maxDistance, 0, "Spin should move away from center")

        // All points should be roughly the same distance from center (circular)
        let minDistance = distances.min() ?? 0
        XCTAssertEqual(
            maxDistance,
            minDistance,
            accuracy: 10.0,
            "Spin should create roughly circular motion"
        )
    }

    func testAllVictoryTrajectoryTypes() {
        // GIVEN
        let cardPosition = CGPoint(x: 200, y: 200)
        let celebrationTypes: [VictoryCelebrationType] = [.bounce, .spiral, .float, .spin]

        for celebrationType in celebrationTypes {
            // WHEN
            let trajectory = trajectoryAnimator.calculateVictoryTrajectory(
                from: cardPosition,
                celebrationType: celebrationType
            )

            // THEN
            XCTAssertFalse(
                trajectory.isEmpty,
                "\(celebrationType) trajectory should not be empty"
            )
            XCTAssertEqual(
                trajectory.first,
                cardPosition,
                "\(celebrationType) should start from card position"
            )
        }
    }

    // MARK: - Performance Tests

    func testTrajectoryCalculationPerformance() {
        // GIVEN
        let startPoint = CGPoint(x: 0, y: 0)
        let endPoint = CGPoint(x: 100, y: 100)

        // WHEN & THEN
        measure {
            for _ in 0..<1000 {
                let trajectory = trajectoryAnimator.calculatePlayTrajectory(
                    from: startPoint,
                    to: endPoint
                )
                _ = trajectory // Ensure trajectory is computed
            }
        }
    }

    func testShuffleTrajectoryPerformance() {
        // GIVEN
        let centerPoint = CGPoint(x: 200, y: 200)
        let radius: CGFloat = 50

        // WHEN & THEN
        measure {
            for cardIndex in 0..<52 {
                let trajectory = trajectoryAnimator.calculateShuffleTrajectory(
                    centerPoint: centerPoint,
                    radius: radius,
                    cardCount: 52,
                    cardIndex: cardIndex
                )
                _ = trajectory
            }
        }
    }

    func testMemoryUsageWithLargeTrajectories() {
        // GIVEN
        let startPoint = CGPoint(x: 0, y: 0)
        let endPoint = CGPoint(x: 1000, y: 1000)

        // WHEN - Generate many trajectories
        var trajectories: [[CGPoint]] = []
        for _ in 0..<100 {
            let trajectory = trajectoryAnimator.calculatePlayTrajectory(
                from: startPoint,
                to: endPoint
            )
            trajectories.append(trajectory)
        }

        // THEN - Should not cause memory issues
        XCTAssertEqual(trajectories.count, 100)
        XCTAssertFalse(trajectories.contains { $0.isEmpty })
    }
}