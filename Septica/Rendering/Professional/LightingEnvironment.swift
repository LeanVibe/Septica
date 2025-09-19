//
//  LightingEnvironment.swift
//  Septica
//
//  Shared rendering data structures used across professional rendering systems.
//

#if canImport(Metal)
import Metal
#endif
import Foundation
import simd

/// Describes the lighting conditions used by the professional rendering pipeline.
/// Shared between the advanced lighting system and card renderer to ensure consistent visuals.
struct LightingEnvironment {
    var primaryLightDirection: simd_float3 = simd_float3(0.5, -0.8, 0.3)
    var primaryLightColor: simd_float3 = simd_float3(1.0, 0.95, 0.8)
    var ambientLightColor: simd_float3 = simd_float3(0.3, 0.3, 0.4)
    var lightIntensity: Float = 1.0
    var shadowBias: Float = 0.001
    var romanianCulturalTint: simd_float3 = simd_float3(1.0, 0.85, 0.4)
}

/// Captures the state needed for a single rendering frame. Kept separate so effects systems
/// (material, lighting, visual) can read or mutate without depending on renderer internals.
struct FrameData {
    var card: Card?
    var transform: Advanced3DTransform = Advanced3DTransform()
    var materialProperties: MaterialProperties = MaterialProperties()
    var lightingEnvironment: LightingEnvironment = LightingEnvironment()
    var viewMatrix: matrix_float4x4 = matrix_identity_float4x4
    var projectionMatrix: matrix_float4x4 = matrix_identity_float4x4
    var timestamp: CFTimeInterval = 0
}
