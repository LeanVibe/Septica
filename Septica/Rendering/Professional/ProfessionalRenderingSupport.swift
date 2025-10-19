//
//  ProfessionalRenderingSupport.swift
//  Septica
//
//  Support utilities and extensions for professional Metal rendering
//  Provides helper functions and extensions for ShuffleCats-quality rendering
//

import Foundation
import SwiftUI
import MetalKit
import simd

// MARK: - Animation Support

struct AnimationSequence {
    let cardTransforms: [Advanced3DTransform]
    let lightingChanges: LightingEnvironment
    let materialEffects: MaterialProperties
    let duration: TimeInterval
}

// MARK: - Performance Types

enum RenderQuality {
    case low, medium, high, ultra
    
    var textureResolution: Int {
        switch self {
        case .low: return 512
        case .medium: return 1024
        case .high: return 2048
        case .ultra: return 4096
        }
    }
    
    var shadowMapResolution: Int {
        switch self {
        case .low: return 512
        case .medium: return 1024
        case .high: return 2048
        case .ultra: return 4096
        }
    }
}


// MARK: - Phase 2 Types

struct VisualEffectsQualityLevel {
    let lightingQuality: LightingQualityLevel
    let materialQuality: MaterialQualityLevel
    let effectsQuality: EffectsQualityLevel
}

enum LightingQualityLevel {
    case basic, standard, advanced, ultra
}

enum MaterialQualityLevel {
    case basic, standard, pbr, ultra
}

enum EffectsQualityLevel {
    case minimal, standard, advanced, ultra
}

// MARK: - Rendering Data

struct SceneRenderingData {
    let colorTarget: MTLTexture
    let depthTarget: MTLTexture
    let cardGeometries: [CardGeometryData]
    let viewMatrix: matrix_float4x4
    let projectionMatrix: matrix_float4x4
}

struct CardGeometryData {
    let vertexBuffer: MTLBuffer
    let indexBuffer: MTLBuffer
    let indexCount: Int
    let indexType: MTLIndexType
}

// MARK: - Matrix Utilities

func translationMatrix(_ translation: simd_float3) -> matrix_float4x4 {
    var matrix = matrix_identity_float4x4
    matrix.columns.3 = simd_float4(translation.x, translation.y, translation.z, 1.0)
    return matrix
}

func rotationMatrix(_ angle: Float, axis: simd_float3) -> matrix_float4x4 {
    let normalizedAxis = normalize(axis)

    let cos = cosf(angle)
    let sin = sinf(angle)
    let oneMinusCos = 1.0 - cos

    let x = normalizedAxis.x
    let y = normalizedAxis.y
    let z = normalizedAxis.z

    var matrix = matrix_identity_float4x4

    matrix.columns.0 = simd_float4(
        cos + x * x * oneMinusCos,
        y * x * oneMinusCos + z * sin,
        z * x * oneMinusCos - y * sin,
        0
    )

    matrix.columns.1 = simd_float4(
        x * y * oneMinusCos - z * sin,
        cos + y * y * oneMinusCos,
        z * y * oneMinusCos + x * sin,
        0
    )

    matrix.columns.2 = simd_float4(
        x * z * oneMinusCos + y * sin,
        y * z * oneMinusCos - x * sin,
        cos + z * z * oneMinusCos,
        0
    )

    matrix.columns.3 = simd_float4(0, 0, 0, 1)

    return matrix
}

// MARK: - Card Extensions

extension Card {
    var isSpecialCard: Bool {
        value == 7 || isPointCard
    }
}

// MARK: - Romanian Colors Support
// Note: toSIMD3() and toSIMD4() are already defined as Color extensions in RomanianColors.swift


// MARK: - Device Capability Detection

extension MTLDevice {
    var supportsProfessionalRendering: Bool {
        return supportsFamily(.apple7) || supportsFamily(.mac2)
    }
    
    var recommendedRenderQuality: RenderQuality {
        if supportsFamily(.apple8) {
            return .ultra
        } else if supportsFamily(.apple7) {
            return .high
        } else if supportsFamily(.apple6) {
            return .medium
        } else {
            return .low
        }
    }
}

// MARK: - Simple Transform Data Structure for non-class usage

struct SimpleTransform: Equatable {
    let perspective: Double
    let rotationX: Double  // degrees
    let rotationY: Double  // degrees
    let rotationZ: Double  // degrees
    let translation: simd_float3
    let lightingVector: simd_float3
    
    init(
        perspective: Double = 0.6,
        rotationX: Double = 0,
        rotationY: Double = 0,
        rotationZ: Double = 0,
        translation: simd_float3 = simd_float3(0, 0, 0),
        lightingVector: simd_float3 = simd_float3(0, 1, 0.5)
    ) {
        self.perspective = perspective
        self.rotationX = rotationX
        self.rotationY = rotationY
        self.rotationZ = rotationZ
        self.translation = translation
        self.lightingVector = lightingVector
    }
    
    var modelMatrix: matrix_float4x4 {
        var transform = matrix_identity_float4x4
        
        // Apply translation
        transform = simd_mul(transform, translationMatrix(translation))
        
        // Apply rotations (convert degrees to radians)
        transform = simd_mul(transform, rotationMatrix(Float(rotationX * .pi / 180), axis: simd_float3(1, 0, 0)))
        transform = simd_mul(transform, rotationMatrix(Float(rotationY * .pi / 180), axis: simd_float3(0, 1, 0)))
        transform = simd_mul(transform, rotationMatrix(Float(rotationZ * .pi / 180), axis: simd_float3(0, 0, 1)))
        
        return transform
    }
}