//
//  Advanced3DTransform.swift
//  Septica
//
//  Sophisticated 3D transformation system for ShuffleCats-quality card effects
//  Provides professional geometry effects, physics-based motion, and Romanian cultural animations
//

import SwiftUI
import simd
import Combine

// MARK: - Advanced 3D Transform System

/// Advanced 3D transformation system providing sophisticated geometry effects
/// and physics-based transformations for professional card rendering
@MainActor
class Advanced3DTransform: ObservableObject {
    
    // MARK: - Core Transform Properties
    
    @Published var position: simd_float3 = simd_float3(0, 0, 0)
    @Published var rotation: simd_float3 = simd_float3(0, 0, 0) // Euler angles in radians
    @Published var scale: simd_float3 = simd_float3(1, 1, 1)
    @Published var pivot: simd_float3 = simd_float3(0, 0, 0)
    
    // MARK: - Advanced Properties
    
    @Published var quaternionRotation: simd_quatf = simd_quatf(ix: 0, iy: 0, iz: 0, r: 1)
    @Published var velocity: simd_float3 = simd_float3(0, 0, 0)
    @Published var angularVelocity: simd_float3 = simd_float3(0, 0, 0)
    @Published var acceleration: simd_float3 = simd_float3(0, 0, 0)
    
    // MARK: - Material Physics Properties
    
    @Published var mass: Float = 1.0
    @Published var friction: Float = 0.8
    @Published var restitution: Float = 0.6 // Bounce factor
    @Published var airResistance: Float = 0.02
    
    // MARK: - Animation State
    
    @Published var isAnimating: Bool = false
    @Published var animationTime: Float = 0.0
    @Published var currentAnimation: TransformAnimation?
    
    // MARK: - Romanian Cultural Effects
    
    @Published var culturalIntensity: Float = 1.0
    @Published var folkDanceMode: Bool = false
    @Published var traditionalCardFlip: Bool = false
    
    // MARK: - Computed Properties
    
    /// Combined transformation matrix
    var modelMatrix: matrix_float4x4 {
        let translationMatrix = matrix4x4_translation(position)
        let rotationMatrix = matrix4x4_rotation(from: quaternionRotation)
        let scaleMatrix = matrix4x4_scale(scale)
        let pivotTranslation = matrix4x4_translation(-pivot)
        let pivotTranslationBack = matrix4x4_translation(pivot)
        
        return simd_mul(simd_mul(simd_mul(simd_mul(translationMatrix, pivotTranslationBack), rotationMatrix), scaleMatrix), pivotTranslation)
    }
    
    /// Normal matrix for lighting calculations
    var normalMatrix: matrix_float3x3 {
        let rotationMatrix3x3 = matrix3x3_from_quaternion(quaternionRotation)
        let scaleMatrix3x3 = matrix3x3_scale(scale)
        return simd_mul(rotationMatrix3x3, scaleMatrix3x3).inverse.transpose
    }
    
    /// Current forward direction
    var forwardDirection: simd_float3 {
        let forward = simd_float3(0, 0, -1)
        return simd_act(quaternionRotation, forward)
    }
    
    /// Current up direction
    var upDirection: simd_float3 {
        let up = simd_float3(0, 1, 0)
        return simd_act(quaternionRotation, up)
    }
    
    /// Current right direction
    var rightDirection: simd_float3 {
        let right = simd_float3(1, 0, 0)
        return simd_act(quaternionRotation, right)
    }
    
    // MARK: - Physics Integration
    
    private var lastUpdateTime: CFTimeInterval = 0
    private var physicsEnabled: Bool = false
    private var forces: [simd_float3] = []
    private var torques: [simd_float3] = []
    
    // MARK: - Animation System
    
    private var animationTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        setupPhysicsIntegration()
    }
    
    // MARK: - Transform Operations
    
    /// Set position with optional animation
    func setPosition(_ newPosition: simd_float3, animated: Bool = true, duration: TimeInterval = 0.3) {
        if animated {
            animateProperty(\.position, to: newPosition, duration: duration)
        } else {
            position = newPosition
        }
    }
    
    /// Set rotation using Euler angles
    func setRotation(_ eulerAngles: simd_float3, animated: Bool = true, duration: TimeInterval = 0.3) {
        let newQuaternion = simd_quatf(angle: simd_length(eulerAngles), axis: simd_normalize(eulerAngles))
        setQuaternionRotation(newQuaternion, animated: animated, duration: duration)
        rotation = eulerAngles
    }
    
    /// Set rotation using quaternion (preferred for smooth interpolation)
    func setQuaternionRotation(_ quaternion: simd_quatf, animated: Bool = true, duration: TimeInterval = 0.3) {
        if animated {
            animateProperty(\.quaternionRotation, to: quaternion, duration: duration)
        } else {
            quaternionRotation = quaternion
        }
    }
    
    /// Set scale with optional animation
    func setScale(_ newScale: simd_float3, animated: Bool = true, duration: TimeInterval = 0.3) {
        if animated {
            animateProperty(\.scale, to: newScale, duration: duration)
        } else {
            scale = newScale
        }
    }
    
    /// Set uniform scale
    func setUniformScale(_ factor: Float, animated: Bool = true, duration: TimeInterval = 0.3) {
        setScale(simd_float3(factor, factor, factor), animated: animated, duration: duration)
    }
    
    // MARK: - Advanced Transform Operations
    
    /// Rotate around arbitrary axis
    func rotateAroundAxis(_ axis: simd_float3, angle: Float, animated: Bool = true, duration: TimeInterval = 0.3) {
        let normalizedAxis = simd_normalize(axis)
        let deltaRotation = simd_quatf(angle: angle, axis: normalizedAxis)
        let newRotation = simd_mul(quaternionRotation, deltaRotation)
        setQuaternionRotation(newRotation, animated: animated, duration: duration)
    }
    
    /// Look at target position
    func lookAt(_ target: simd_float3, worldUp: simd_float3 = simd_float3(0, 1, 0), animated: Bool = true, duration: TimeInterval = 0.3) {
        let forward = simd_normalize(target - position)
        let right = simd_normalize(simd_cross(forward, worldUp))
        let up = simd_cross(right, forward)
        
        let rotationMatrix = matrix_float3x3([right, up, -forward])
        let lookAtQuaternion = simd_quatf(rotationMatrix)
        
        setQuaternionRotation(lookAtQuaternion, animated: animated, duration: duration)
    }
    
    /// Apply transform relative to current state
    func applyRelativeTransform(_ deltaPosition: simd_float3, _ deltaRotation: simd_float3, _ deltaScale: simd_float3) {
        position += deltaPosition
        let deltaQuat = simd_quatf(angle: simd_length(deltaRotation), axis: simd_normalize(deltaRotation))
        quaternionRotation = simd_mul(quaternionRotation, deltaQuat)
        scale *= deltaScale
    }
    
    // MARK: - Physics System
    
    /// Enable physics simulation
    func enablePhysics() {
        physicsEnabled = true
        lastUpdateTime = CACurrentMediaTime()
        startPhysicsUpdate()
    }
    
    /// Disable physics simulation
    func disablePhysics() {
        physicsEnabled = false
        stopPhysicsUpdate()
        velocity = simd_float3(0, 0, 0)
        angularVelocity = simd_float3(0, 0, 0)
        forces.removeAll()
        torques.removeAll()
    }
    
    /// Apply force at center of mass
    func applyForce(_ force: simd_float3) {
        forces.append(force)
    }
    
    /// Apply force at specific point (creates torque)
    func applyForceAtPoint(_ force: simd_float3, at point: simd_float3) {
        forces.append(force)
        let lever = point - position
        let torque = simd_cross(lever, force)
        torques.append(torque)
    }
    
    /// Apply torque directly
    func applyTorque(_ torque: simd_float3) {
        torques.append(torque)
    }
    
    /// Add impulse (instantaneous velocity change)
    func addImpulse(_ impulse: simd_float3) {
        velocity += impulse / mass
    }
    
    // MARK: - Romanian Cultural Animations
    
    /// Traditional Romanian card flip animation
    func performTraditionalFlip(completion: @escaping () -> Void = {}) {
        traditionalCardFlip = true
        
        let flipAnimation = TransformAnimation(
            type: .traditionalFlip,
            duration: 0.8,
            easing: .easeInOut
        )
        
        startAnimation(flipAnimation) {
            self.traditionalCardFlip = false
            completion()
        }
    }
    
    /// Romanian folk dance motion
    func performFolkDanceMotion(intensity: Float = 1.0, completion: @escaping () -> Void = {}) {
        folkDanceMode = true
        culturalIntensity = intensity
        
        let danceAnimation = TransformAnimation(
            type: .folkDance,
            duration: 2.0,
            easing: .easeInOut,
            culturalIntensity: intensity
        )
        
        startAnimation(danceAnimation) {
            self.folkDanceMode = false
            self.culturalIntensity = 1.0
            completion()
        }
    }
    
    /// Seven card special effect (Romanian Septica tradition)
    func performSevenCardEffect(completion: @escaping () -> Void = {}) {
        let sevenAnimation = TransformAnimation(
            type: .sevenSpecial,
            duration: 1.5,
            easing: .easeInOut,
            culturalIntensity: culturalIntensity
        )
        
        startAnimation(sevenAnimation, completion: completion)
    }
    
    /// Victory celebration animation
    func performVictoryCelebration(completion: @escaping () -> Void = {}) {
        let victoryAnimation = TransformAnimation(
            type: .victory,
            duration: 2.5,
            easing: .easeInOut,
            culturalIntensity: culturalIntensity
        )
        
        startAnimation(victoryAnimation, completion: completion)
    }
    
    // MARK: - ShuffleCats-Style Effects
    
    /// Smooth card lift effect
    func performLiftEffect(height: Float = 0.5, completion: @escaping () -> Void = {}) {
        let originalPosition = position
        let liftedPosition = originalPosition + simd_float3(0, height, 0)
        
        setPosition(liftedPosition, animated: true, duration: 0.3)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            completion()
        }
    }
    
    /// Magnetic attraction effect
    func performMagneticAttraction(to target: simd_float3, strength: Float = 1.0, completion: @escaping () -> Void = {}) {
        let attractionAnimation = TransformAnimation(
            type: .magneticAttraction,
            duration: 0.8,
            easing: .easeOut,
            targetPosition: target,
            strength: strength
        )
        
        startAnimation(attractionAnimation, completion: completion)
    }
    
    /// Smooth card snap to position
    func snapToPosition(_ target: simd_float3, rotation targetRotation: simd_float3? = nil, completion: @escaping () -> Void = {}) {
        let snapAnimation = TransformAnimation(
            type: .snapToPosition,
            duration: 0.4,
            easing: .easeInOut,
            targetPosition: target,
            targetRotation: targetRotation.map { simd_quatf(angle: simd_length($0), axis: simd_normalize($0)) }
        )
        
        startAnimation(snapAnimation, completion: completion)
    }
    
    /// Professional card flip with physics
    func performProfessionalFlip(axis: simd_float3 = simd_float3(0, 1, 0), completion: @escaping () -> Void = {}) {
        let flipAnimation = TransformAnimation(
            type: .professionalFlip,
            duration: 0.6,
            easing: .easeInOut,
            rotationAxis: axis
        )
        
        startAnimation(flipAnimation, completion: completion)
    }
    
    // MARK: - Animation System Implementation
    
    private func startAnimation(_ animation: TransformAnimation, completion: @escaping () -> Void = {}) {
        currentAnimation = animation
        isAnimating = true
        animationTime = 0.0
        
        let startTime = CACurrentMediaTime()
        let startPosition = position
        let startRotation = quaternionRotation
        let startScale = scale
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1/120, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self = self else {
                    timer.invalidate()
                    return
                }
                
                let elapsed = Float(CACurrentMediaTime() - startTime)
                let progress = min(elapsed / Float(animation.duration), 1.0)
                let easedProgress = animation.easing.apply(progress)
                
                self.animationTime = elapsed
                self.updateAnimationFrame(
                    animation: animation,
                    progress: easedProgress,
                    startPosition: startPosition,
                    startRotation: startRotation,
                    startScale: startScale
                )
                
                if progress >= 1.0 {
                    timer.invalidate()
                    self.currentAnimation = nil
                    self.isAnimating = false
                    self.animationTime = 0.0
                    completion()
                }
            }
        }
    }
    
    private func updateAnimationFrame(
        animation: TransformAnimation,
        progress: Float,
        startPosition: simd_float3,
        startRotation: simd_quatf,
        startScale: simd_float3
    ) {
        switch animation.type {
        case .traditionalFlip:
            updateTraditionalFlipFrame(progress: progress, startRotation: startRotation)
            
        case .folkDance:
            updateFolkDanceFrame(progress: progress, startPosition: startPosition, startRotation: startRotation, intensity: animation.culturalIntensity)
            
        case .sevenSpecial:
            updateSevenSpecialFrame(progress: progress, startPosition: startPosition, startRotation: startRotation, startScale: startScale)
            
        case .victory:
            updateVictoryFrame(progress: progress, startPosition: startPosition, startRotation: startRotation, startScale: startScale)
            
        case .magneticAttraction:
            updateMagneticAttractionFrame(progress: progress, startPosition: startPosition, target: animation.targetPosition, strength: animation.strength)
            
        case .snapToPosition:
            updateSnapToPositionFrame(progress: progress, startPosition: startPosition, startRotation: startRotation, target: animation.targetPosition, targetRotation: animation.targetRotation)
            
        case .professionalFlip:
            updateProfessionalFlipFrame(progress: progress, startRotation: startRotation, axis: animation.rotationAxis)
        }
    }
    
    // MARK: - Animation Frame Updates
    
    private func updateTraditionalFlipFrame(progress: Float, startRotation: simd_quatf) {
        // Traditional Romanian card flip: slow start, fast middle, gentle end
        let flipAngle = progress * .pi
        let flipQuat = simd_quatf(angle: flipAngle, axis: simd_float3(0, 1, 0))
        quaternionRotation = simd_mul(startRotation, flipQuat)
        
        // Add slight vertical movement for natural flip
        let verticalOffset = sin(progress * .pi) * 0.2
        position.y += verticalOffset
    }
    
    private func updateFolkDanceFrame(progress: Float, startPosition: simd_float3, startRotation: simd_quatf, intensity: Float) {
        // Romanian folk dance movement patterns
        let dancePhase = progress * 4 * .pi
        let horizontalSway = sin(dancePhase) * 0.3 * intensity
        let verticalBob = abs(sin(dancePhase * 2)) * 0.2 * intensity
        let rotationalSway = sin(dancePhase * 1.5) * 0.1 * intensity
        
        position = startPosition + simd_float3(horizontalSway, verticalBob, 0)
        
        let swayRotation = simd_quatf(angle: rotationalSway, axis: simd_float3(0, 0, 1))
        quaternionRotation = simd_mul(startRotation, swayRotation)
    }
    
    private func updateSevenSpecialFrame(progress: Float, startPosition: simd_float3, startRotation: simd_quatf, startScale: simd_float3) {
        // Special seven card effect with golden spiral
        let spiralAngle = progress * 2 * .pi
        let spiralRadius = progress * 0.5
        let spiralHeight = sin(progress * .pi) * 0.3
        
        let spiralOffset = simd_float3(
            cos(spiralAngle) * spiralRadius,
            spiralHeight,
            sin(spiralAngle) * spiralRadius
        )
        
        position = startPosition + spiralOffset
        
        let spiralRotation = simd_quatf(angle: spiralAngle, axis: simd_float3(0, 1, 0))
        quaternionRotation = simd_mul(startRotation, spiralRotation)
        
        // Pulsing scale effect
        let pulseScale = 1.0 + sin(progress * 4 * .pi) * 0.1
        scale = startScale * pulseScale
    }
    
    private func updateVictoryFrame(progress: Float, startPosition: simd_float3, startRotation: simd_quatf, startScale: simd_float3) {
        // Victory celebration with dramatic movements
        let celebrationPhase = progress * 6 * .pi
        let victoryHeight = sin(progress * .pi) * 0.8
        let victoryRotation = progress * 4 * .pi
        let scaleBoost = 1.0 + sin(progress * 2 * .pi) * 0.3
        
        position = startPosition + simd_float3(0, victoryHeight, 0)
        
        let celebrationQuat = simd_quatf(angle: victoryRotation, axis: simd_float3(0, 1, 0))
        quaternionRotation = simd_mul(startRotation, celebrationQuat)
        
        scale = startScale * scaleBoost
    }
    
    private func updateMagneticAttractionFrame(progress: Float, startPosition: simd_float3, target: simd_float3?, strength: Float) {
        guard let target = target else { return }
        
        // Magnetic attraction with easing
        let attractionForce = (target - startPosition) * strength
        let currentPosition = simd_mix(startPosition, target, simd_float3(repeating: progress))
        
        // Add some oscillation for realistic magnetic effect
        let oscillation = sin(progress * 8 * .pi) * (1.0 - progress) * 0.1
        let oscillationVector = simd_normalize(simd_cross(attractionForce, simd_float3(0, 1, 0))) * oscillation
        
        position = currentPosition + oscillationVector
    }
    
    private func updateSnapToPositionFrame(progress: Float, startPosition: simd_float3, startRotation: simd_quatf, target: simd_float3?, targetRotation: simd_quatf?) {
        if let target = target {
            position = simd_mix(startPosition, target, simd_float3(repeating: progress))
        }
        
        if let targetRotation = targetRotation {
            quaternionRotation = simd_slerp(startRotation, targetRotation, progress)
        }
    }
    
    private func updateProfessionalFlipFrame(progress: Float, startRotation: simd_quatf, axis: simd_float3?) {
        let rotationAxis = axis ?? simd_float3(0, 1, 0)
        let flipAngle = progress * .pi
        
        // Add slight arc motion for natural flip
        let arcHeight = sin(progress * .pi) * 0.25
        position.y += arcHeight
        
        let flipQuat = simd_quatf(angle: flipAngle, axis: rotationAxis)
        quaternionRotation = simd_mul(startRotation, flipQuat)
    }
    
    // MARK: - Physics Update
    
    private func setupPhysicsIntegration() {
        // Physics will be updated when enabled
    }
    
    private func startPhysicsUpdate() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1/120, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updatePhysics()
            }
        }
    }
    
    private func stopPhysicsUpdate() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    private func updatePhysics() {
        guard physicsEnabled else { return }
        
        let currentTime = CACurrentMediaTime()
        let deltaTime = Float(currentTime - lastUpdateTime)
        lastUpdateTime = currentTime
        
        // Calculate net force
        var netForce = simd_float3(0, 0, 0)
        for force in forces {
            netForce += force
        }
        
        // Apply air resistance
        netForce -= velocity * airResistance
        
        // Calculate acceleration (F = ma)
        acceleration = netForce / mass
        
        // Update velocity
        velocity += acceleration * deltaTime
        
        // Apply friction
        velocity *= (1.0 - friction * deltaTime)
        
        // Update position
        position += velocity * deltaTime
        
        // Calculate net torque
        var netTorque = simd_float3(0, 0, 0)
        for torque in torques {
            netTorque += torque
        }
        
        // Update angular velocity (simplified)
        angularVelocity += netTorque * deltaTime
        angularVelocity *= (1.0 - friction * deltaTime)
        
        // Update rotation
        if simd_length(angularVelocity) > 0.001 {
            let angularSpeed = simd_length(angularVelocity)
            let axis = simd_normalize(angularVelocity)
            let deltaRotation = simd_quatf(angle: angularSpeed * deltaTime, axis: axis)
            quaternionRotation = simd_mul(quaternionRotation, deltaRotation)
        }
        
        // Clear forces and torques
        forces.removeAll()
        torques.removeAll()
    }
    
    // MARK: - Animation Property Helper
    
    private func animateProperty<T>(_ keyPath: ReferenceWritableKeyPath<Advanced3DTransform, T>, to targetValue: T, duration: TimeInterval) where T: Interpolatable {
        let startValue = self[keyPath: keyPath]
        let startTime = CACurrentMediaTime()
        
        Timer.scheduledTimer(withTimeInterval: 1/120, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            let elapsed = CACurrentMediaTime() - startTime
            let progress = min(elapsed / duration, 1.0)
            let easedProgress = EasingFunction.easeInOut.apply(Float(progress))
            
            self[keyPath: keyPath] = startValue.interpolate(to: targetValue, progress: easedProgress)
            
            if progress >= 1.0 {
                timer.invalidate()
            }
        }
    }
}

// MARK: - Supporting Types

struct TransformAnimation {
    let type: AnimationType
    let duration: TimeInterval
    let easing: EasingFunction
    var targetPosition: simd_float3? = nil
    var targetRotation: simd_quatf? = nil
    var rotationAxis: simd_float3? = nil
    var culturalIntensity: Float = 1.0
    var strength: Float = 1.0
    
    enum AnimationType {
        case traditionalFlip
        case folkDance
        case sevenSpecial
        case victory
        case magneticAttraction
        case snapToPosition
        case professionalFlip
    }
}

enum EasingFunction {
    case linear
    case easeIn
    case easeOut
    case easeInOut
    case easeInBack
    case easeOutBack
    case easeInOutBack
    
    func apply(_ t: Float) -> Float {
        switch self {
        case .linear:
            return t
        case .easeIn:
            return t * t
        case .easeOut:
            return 1 - (1 - t) * (1 - t)
        case .easeInOut:
            return t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2
        case .easeInBack:
            let c1: Float = 1.70158
            let c3: Float = c1 + 1
            return c3 * t * t * t - c1 * t * t
        case .easeOutBack:
            let c1: Float = 1.70158
            let c3: Float = c1 + 1
            return 1 + c3 * pow(t - 1, 3) + c1 * pow(t - 1, 2)
        case .easeInOutBack:
            let c1: Float = 1.70158
            let c2: Float = c1 * 1.525
            return t < 0.5
                ? (pow(2 * t, 2) * ((c2 + 1) * 2 * t - c2)) / 2
                : (pow(2 * t - 2, 2) * ((c2 + 1) * (t * 2 - 2) + c2) + 2) / 2
        }
    }
}

// MARK: - Matrix Utilities

func matrix4x4_translation(_ translation: simd_float3) -> matrix_float4x4 {
    var matrix = matrix_identity_float4x4
    matrix.columns.3 = simd_float4(translation.x, translation.y, translation.z, 1.0)
    return matrix
}

func matrix4x4_rotation(from quaternion: simd_quatf) -> matrix_float4x4 {
    let matrix3x3 = matrix3x3_from_quaternion(quaternion)
    return matrix_float4x4(
        simd_float4(matrix3x3.columns.0, 0),
        simd_float4(matrix3x3.columns.1, 0),
        simd_float4(matrix3x3.columns.2, 0),
        simd_float4(0, 0, 0, 1)
    )
}

func matrix4x4_scale(_ scale: simd_float3) -> matrix_float4x4 {
    return matrix_float4x4(
        simd_float4(scale.x, 0, 0, 0),
        simd_float4(0, scale.y, 0, 0),
        simd_float4(0, 0, scale.z, 0),
        simd_float4(0, 0, 0, 1)
    )
}

func matrix3x3_from_quaternion(_ quaternion: simd_quatf) -> matrix_float3x3 {
    let x = quaternion.imag.x
    let y = quaternion.imag.y
    let z = quaternion.imag.z
    let w = quaternion.real
    
    let xx = x * x
    let yy = y * y
    let zz = z * z
    let xy = x * y
    let xz = x * z
    let yz = y * z
    let wx = w * x
    let wy = w * y
    let wz = w * z
    
    return matrix_float3x3(
        simd_float3(1 - 2 * (yy + zz), 2 * (xy + wz), 2 * (xz - wy)),
        simd_float3(2 * (xy - wz), 1 - 2 * (xx + zz), 2 * (yz + wx)),
        simd_float3(2 * (xz + wy), 2 * (yz - wx), 1 - 2 * (xx + yy))
    )
}

func matrix3x3_scale(_ scale: simd_float3) -> matrix_float3x3 {
    return matrix_float3x3(
        simd_float3(scale.x, 0, 0),
        simd_float3(0, scale.y, 0),
        simd_float3(0, 0, scale.z)
    )
}

// MARK: - Interpolation Protocol

protocol Interpolatable {
    func interpolate(to target: Self, progress: Float) -> Self
}

extension simd_float3: Interpolatable {
    func interpolate(to target: simd_float3, progress: Float) -> simd_float3 {
        return simd_mix(self, target, simd_float3(repeating: progress))
    }
}

extension simd_quatf: Interpolatable {
    func interpolate(to target: simd_quatf, progress: Float) -> simd_quatf {
        return simd_slerp(self, target, progress)
    }
}

extension Float: Interpolatable {
    func interpolate(to target: Float, progress: Float) -> Float {
        return self + (target - self) * progress
    }
}