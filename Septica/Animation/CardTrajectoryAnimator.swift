//
//  CardTrajectoryAnimator.swift
//  Septica
//
//  Smooth arc trajectory animations for card movements
//  Calculates parabolic paths for realistic card play animations
//

import SwiftUI

/// Calculates smooth arc trajectories for card movements with natural physics
class CardTrajectoryAnimator: ObservableObject {

    // MARK: - Trajectory Constants

    struct TrajectoryConstants {
        static let defaultHeight: CGFloat = 100.0         // Default arc height
        static let minHeight: CGFloat = 30.0              // Minimum arc height
        static let maxHeight: CGFloat = 200.0             // Maximum arc height
        static let controlPointBias: CGFloat = 0.5        // Control point positioning
        static let smoothness: Int = 20                   // Number of points in smooth path
    }

    // MARK: - Public Interface

    /// Calculate parabolic arc trajectory for card play
    /// - Parameters:
    ///   - startPoint: Starting position of the card
    ///   - endPoint: Destination position of the card
    ///   - height: Maximum height of the arc (optional)
    /// - Returns: Array of points forming the smooth trajectory
    func calculatePlayTrajectory(
        from startPoint: CGPoint,
        to endPoint: CGPoint,
        height: CGFloat = TrajectoryConstants.defaultHeight
    ) -> [CGPoint] {
        // Calculate control points for quadratic Bezier curve
        let midPoint = CGPoint(
            x: (startPoint.x + endPoint.x) / 2,
            y: (startPoint.y + endPoint.y) / 2
        )

        // Determine arc direction (upward or downward)
        let arcDirection: CGFloat = startPoint.y > endPoint.y ? -1 : 1

        // Calculate control point for natural arc
        let controlPoint = CGPoint(
            x: midPoint.x,
            y: midPoint.y + (height * arcDirection)
        )

        // Generate smooth path points
        return generateBezierCurvePoints(
            start: startPoint,
            control: controlPoint,
            end: endPoint,
            smoothness: TrajectoryConstants.smoothness
        )
    }

    /// Calculate card flip animation path
    /// - Parameters:
    ///   - startPosition: Starting position
    ///   - endPosition: Final position
    ///   - flipAxis: Axis of rotation ("x" or "y")
    ///   - flipCount: Number of complete rotations
    /// - Returns: Animation combining position and rotation
    func calculateCardFlipAnimation(
        from startPosition: CGPoint,
        to endPosition: CGPoint,
        flipAxis: String = "y",
        flipCount: Int = 1
    ) -> Animation {
        return .keyframes(
            with: generateFlipKeyframes(
                from: startPosition,
                to: endPosition,
                flipAxis: flipAxis,
                flipCount: flipCount
            )
        )
    }

    /// Create smooth animation along calculated path
    /// - Parameters:
    ///   - path: Array of points forming the trajectory
    ///   - duration: Total animation duration
    ///   - completion: Callback when animation completes
    /// - Returns: Animation that follows the path
    func animateAlongPath(
        path: [CGPoint],
        duration: TimeInterval,
        completion: (() -> Void)? = nil
    ) -> Animation {
        guard !path.isEmpty else {
            return .easeInOut(duration: duration)
        }

        // Generate keyframes for smooth path following
        let keyframes = generatePathKeyframes(path: path, duration: duration)

        return .keyframes(with: keyframes)
    }

    /// Calculate card shuffle trajectory for deck animations
    /// - Parameters:
    ///   - centerPoint: Center of shuffle area
    ///   - radius: Radius of shuffle circle
    ///   - cardCount: Number of cards being shuffled
    ///   - cardIndex: Index of current card
    /// - Returns: Array of points for shuffle path
    func calculateShuffleTrajectory(
        centerPoint: CGPoint,
        radius: CGFloat,
        cardCount: Int,
        cardIndex: Int
    ) -> [CGPoint] {
        let angleStep = (2 * .pi) / CGFloat(cardCount)
        let startAngle = angleStep * CGFloat(cardIndex)
        let endAngle = startAngle + angleStep * 2 // Full circle

        return generateArcPoints(
            center: centerPoint,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle
        )
    }

    /// Calculate dealing trajectory for card distribution
    /// - Parameters:
    ///   - deckPosition: Position in deck
    ///   - playerPosition: Target player position
    ///   - dealingStyle: Style of dealing motion
    /// - Returns: Array of points for dealing path
    func calculateDealingTrajectory(
        from deckPosition: CGPoint,
        to playerPosition: CGPoint,
        dealingStyle: CardDealingTrajectory = .smooth
    ) -> [CGPoint] {
        switch dealingStyle {
        case .smooth:
            return calculatePlayTrajectory(
                from: deckPosition,
                to: playerPosition,
                height: TrajectoryConstants.defaultHeight * 0.6
            )
        case .direct:
            return [deckPosition, playerPosition]
        case .circular:
            return calculateCircularDealingTrajectory(
                from: deckPosition,
                to: playerPosition
            )
        }
    }

    /// Calculate victory celebration trajectory
    /// - Parameters:
    ///   - cardPosition: Position of winning card
    ///   - celebrationType: Type of victory celebration
    /// - Returns: Array of points for celebration path
    func calculateVictoryTrajectory(
        from cardPosition: CGPoint,
        celebrationType: VictoryCelebrationType
    ) -> [CGPoint] {
        switch celebrationType {
        case .bounce:
            return calculateBounceTrajectory(from: cardPosition)
        case .spiral:
            return calculateSpiralTrajectory(from: cardPosition)
        case .float:
            return calculateFloatTrajectory(from: cardPosition)
        case .spin:
            return calculateSpinTrajectory(from: cardPosition)
        }
    }

    // MARK: - Private Helper Methods

    /// Generate smooth Bezier curve points
    private func generateBezierCurvePoints(
        start: CGPoint,
        control: CGPoint,
        end: CGPoint,
        smoothness: Int
    ) -> [CGPoint] {
        var points: [CGPoint] = []

        for i in 0...smoothness {
            let t = CGFloat(i) / CGFloat(smoothness)
            let point = calculateBezierPoint(t: t, start: start, control: control, end: end)
            points.append(point)
        }

        return points
    }

    /// Calculate single point on quadratic Bezier curve
    private func calculateBezierPoint(
        t: CGFloat,
        start: CGPoint,
        control: CGPoint,
        end: CGPoint
    ) -> CGPoint {
        let oneMinusT = 1.0 - t
        let oneMinusTSquared = oneMinusT * oneMinusT

        let x = oneMinusTSquared * start.x +
                  2 * oneMinusT * t * control.x +
                  t * t * end.x

        let y = oneMinusTSquared * start.y +
                  2 * oneMinusT * t * control.y +
                  t * t * end.y

        return CGPoint(x: x, y: y)
    }

    /// Generate keyframes for path animation
    private func generatePathKeyframes(
        path: [CGPoint],
        duration: TimeInterval
    ) -> [AnimationKeyframe] {
        var keyframes: [AnimationKeyframe] = []

        let timeStep = duration / Double(path.count)

        for (index, point) in path.enumerated() {
            let time = Double(index) * timeStep / duration
            let transform = Transform3DEffect(
                translation: CGPoint(x: point.x, y: point.y)
            )

            keyframes.append(AnimationKeyframe(time, transform: transform))
        }

        return keyframes
    }

    /// Generate flip animation keyframes
    private func generateFlipKeyframes(
        from startPoint: CGPoint,
        to endPosition: CGPoint,
        flipAxis: Character,
        flipCount: Int
    ) -> [AnimationKeyframe] {
        var keyframes: [AnimationKeyframe] = []

        // Start position
        keyframes.append(AnimationKeyframe(0.0, transform: Transform3DEffect(translation: startPoint)))

        // Half flip
        let midPoint = CGPoint(
            x: (startPoint.x + endPosition.x) / 2,
            y: (startPoint.y + endPosition.y) / 2 - 20 // Lift up during flip
        )

        let rotationAngle = Angle.degrees(180 * flipCount)
        let flipTransform = flipAxis == "y" ?
            Transform3DEffect.identity.rotation3DEffect(
                by: .degrees(180 * flipCount),
                axis: (x: 0, y: 1, z: 0)
            ) :
            Transform3DEffect.identity.rotation3DEffect(
                by: .degrees(180 * flipCount),
                axis: (x: 1, y: 0, z: 0)
            )

        keyframes.append(AnimationKeyframe(0.5, transform: flipTransform.translation(midPoint)))

        // End position
        keyframes.append(AnimationKeyframe(1.0, transform: Transform3DEffect(translation: endPosition)))

        return keyframes
    }

    /// Generate arc points for circular motion
    private func generateArcPoints(
        center: CGPoint,
        radius: CGFloat,
        startAngle: Double,
        endAngle: Double
    ) -> [CGPoint] {
        var points: [CGPoint] = []
        let angleRange = endAngle - startAngle
        let step = angleRange / Double(TrajectoryConstants.smoothness)

        for i in 0...TrajectoryConstants.smoothness {
            let angle = startAngle + step * Double(i)
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)
            points.append(CGPoint(x: x, y: y))
        }

        return points
    }

    /// Generate circular dealing trajectory
    private func calculateCircularDealingTrajectory(
        from deckPosition: CGPoint,
        to playerPosition: CGPoint
    ) -> [CGPoint] {
        let center = CGPoint(
            x: (deckPosition.x + playerPosition.x) / 2,
            y: (deckPosition.y + playerPosition.y) / 2
        )
        let radius = deckPosition.distance(to: playerPosition) / 2

        return generateArcPoints(
            center: center,
            radius: radius,
            startAngle: .pi,
            endAngle: 0
        )
    }

    /// Generate bounce trajectory
    private func calculateBounceTrajectory(from position: CGPoint) -> [CGPoint] {
        var points: [CGPoint] = [position]

        // Create bounce arc
        let height: CGFloat = 50
        let bounceSteps = 15

        for i in 1...bounceSteps {
            let progress = CGFloat(i) / CGFloat(bounceSteps)
            let bounceHeight = height * sin(progress * .pi) * (1 - progress * 0.3)
            let y = position.y - bounceHeight
            points.append(CGPoint(x: position.x, y: y))
        }

        return points
    }

    /// Generate spiral trajectory
    private func calculateSpiralTrajectory(from position: CGPoint) -> [CGPoint] {
        var points: [CGPoint] = []
        let spiralTurns = 2.0
        let maxRadius: CGFloat = 40
        let steps = 30

        for i in 0...steps {
            let progress = CGFloat(i) / CGFloat(steps)
            let angle = progress * .pi * 2 * spiralTurns
            let radius = maxRadius * progress * (1 - progress * 0.5)

            let x = position.x + radius * cos(angle)
            let y = position.y + radius * sin(angle)
            points.append(CGPoint(x: x, y: y))
        }

        return points
    }

    /// Generate float trajectory
    private func calculateFloatTrajectory(from position: CGPoint) -> [CGPoint] {
        var points: [CGPoint] = [position]

        let floatHeight: CGFloat = 30
        let floatSteps = 20

        for i in 1...floatSteps {
            let progress = CGFloat(i) / CGFloat(floatSteps)
            let float = floatHeight * sin(progress * .pi * 2)
            let wobble = cos(progress * .pi * 4) * 5 // Small wobble
            let y = position.y - float
            let x = position.x + wobble
            points.append(CGPoint(x: x, y: y))
        }

        return points
    }

    /// Generate spin trajectory
    private func calculateSpinTrajectory(from position: CGPoint) -> [CGPoint] {
        var points: [CGPoint] = [position]

        let spinRadius: CGFloat = 20
        let spinTurns = 1.5
        let steps = 24

        for i in 1...steps {
            let progress = CGFloat(i) / CGFloat(steps)
            let angle = progress * .pi * 2 * spinTurns
            let shrink = 1 - progress * 0.3

            let x = position.x + spinRadius * cos(angle) * shrink
            let y = position.y + spinRadius * sin(angle) * shrink
            points.append(CGPoint(x: x, y: y))
        }

        return points
    }
}

// MARK: - Supporting Types

/// Card dealing trajectory physics style
enum CardDealingTrajectory {
    case smooth     // Smooth arc trajectory
    case direct     // Straight line movement
    case circular   // Circular dealing path
}

/// Type of victory celebration
enum VictoryCelebrationType {
    case bounce    // Bouncing animation
    case spiral    // Spiral motion
    case float     // Floating effect
    case spin      // Spinning motion
}

// MARK: - Extensions

extension CGPoint {
    /// Calculate distance to another point
    func distance(to other: CGPoint) -> CGFloat {
        let dx = x - other.x
        let dy = y - other.y
        return sqrt(dx * dx + dy * dy)
    }
}