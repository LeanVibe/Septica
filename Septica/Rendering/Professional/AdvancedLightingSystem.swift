//
//  AdvancedLightingSystem.swift
//  Septica
//
//  Advanced lighting system for ShuffleCats-quality card rendering
//  Global illumination, dynamic shadows, and Romanian cultural lighting
//

#if canImport(Metal)
import Metal
import MetalKit
import MetalPerformanceShaders
#endif
import SwiftUI
import simd
import Combine

// MARK: - Advanced Lighting System

/// Advanced lighting system providing global illumination and dynamic shadows for professional card rendering
@MainActor
class AdvancedLightingSystem: ObservableObject {
    
    // MARK: - Core Resources
    
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private var library: MTLLibrary
    
    // MARK: - Lighting Pipeline States
    
    private var globalIlluminationPipelineState: MTLComputePipelineState?
    private var lightBounceComputeState: MTLComputePipelineState?
    private var cascadedShadowPipelineState: MTLRenderPipelineState?
    private var romanianLightingPipelineState: MTLRenderPipelineState?
    
    // MARK: - Lighting Resources
    
    private var lightBuffer: MTLBuffer
    private var globalIlluminationBuffer: MTLBuffer
    private var shadowMapCascades: [MTLTexture] = []
    private var lightProbeTexture: MTLTexture?
    private var irradianceMapTexture: MTLTexture?
    
    // MARK: - Romanian Cultural Lighting
    
    private var romanianLightingParameters: MTLBuffer
    private var culturalLightProbes: [MTLTexture] = []
    
    // MARK: - Published Properties
    
    @Published var lightingQuality: LightingQuality = .high
    @Published var enableGlobalIllumination: Bool = true
    @Published var enableLightBouncing: Bool = true
    @Published var enableCascadedShadows: Bool = true
    @Published var enableRomanianCulturalLighting: Bool = true
    
    @Published var primaryLightIntensity: Float = 1.0
    @Published var ambientLightIntensity: Float = 0.3
    @Published var romanianWarmthFactor: Float = 0.8
    @Published var goldenHourTinting: Float = 0.6
    
    // MARK: - Performance Metrics
    
    @Published var lightingRenderTime: Double = 0.0
    @Published var shadowMapUpdateFrequency: Int = 60
    @Published var globalIlluminationSamples: Int = 32
    
    // MARK: - Light Configuration
    
    private var lightConfiguration = RomanianLightingConfiguration()
    private var lightProbeManager: LightProbeManager
    private var shadowMapManager: CascadedShadowMapManager
    
    // MARK: - Initialization
    
    init(device: MTLDevice, commandQueue: MTLCommandQueue) throws {
        self.device = device
        self.commandQueue = commandQueue
        
        guard let library = device.makeDefaultLibrary() else {
            throw AdvancedLightingError.libraryCreationFailed
        }
        self.library = library
        
        // Initialize managers
        self.lightProbeManager = try LightProbeManager(device: device)
        self.shadowMapManager = try CascadedShadowMapManager(device: device)
        
        // Allocate buffers
        let lightBufferSize = MemoryLayout<AdvancedLightingUniforms>.stride * 16
        guard let lightBuf = device.makeBuffer(length: lightBufferSize, options: [.storageModeShared]) else {
            throw AdvancedLightingError.bufferAllocationFailed
        }
        self.lightBuffer = lightBuf
        lightBuffer.label = "AdvancedLightingBuffer"
        
        let giBufferSize = MemoryLayout<GlobalIlluminationParameters>.stride * 8
        guard let giBuf = device.makeBuffer(length: giBufferSize, options: [.storageModeShared]) else {
            throw AdvancedLightingError.bufferAllocationFailed
        }
        self.globalIlluminationBuffer = giBuf
        globalIlluminationBuffer.label = "GlobalIlluminationBuffer"
        
        let romanianBufferSize = MemoryLayout<RomanianLightingParameters>.stride * 4
        guard let romanianBuf = device.makeBuffer(length: romanianBufferSize, options: [.storageModeShared]) else {
            throw AdvancedLightingError.bufferAllocationFailed
        }
        self.romanianLightingParameters = romanianBuf
        romanianLightingParameters.label = "RomanianLightingParameters"
        
        // Setup pipeline states
        try setupLightingPipelines()
        
        // Initialize lighting resources
        try setupLightingResources()
        
        // Setup Romanian cultural lighting
        try setupRomanianCulturalLighting()
        
        print("🌟 AdvancedLightingSystem initialized successfully")
        print("   - Global Illumination: \(enableGlobalIllumination)")
        print("   - Light Bouncing: \(enableLightBouncing)")
        print("   - Cascaded Shadows: \(enableCascadedShadows)")
        print("   - Romanian Cultural Lighting: \(enableRomanianCulturalLighting)")
    }
    
    // MARK: - Pipeline Setup
    
    private func setupLightingPipelines() throws {
        // Global Illumination Compute Pipeline
        if let giFunction = library.makeFunction(name: "globalIlluminationComputeShader") {
            globalIlluminationPipelineState = try device.makeComputePipelineState(function: giFunction)
        } else {
            print("⚠️ Global illumination shader not found - using fallback")
        }
        
        // Light Bounce Compute Pipeline
        if let bounceFunction = library.makeFunction(name: "lightBounceComputeShader") {
            lightBounceComputeState = try device.makeComputePipelineState(function: bounceFunction)
        } else {
            print("⚠️ Light bounce shader not found - using fallback")
        }
        
        // Cascaded Shadow Pipeline
        let shadowDescriptor = MTLRenderPipelineDescriptor()
        shadowDescriptor.label = "CascadedShadowPipeline"
        shadowDescriptor.vertexFunction = library.makeFunction(name: "cascadedShadowVertexShader")
        shadowDescriptor.fragmentFunction = library.makeFunction(name: "cascadedShadowFragmentShader")
        shadowDescriptor.depthAttachmentPixelFormat = .depth32Float
        shadowDescriptor.colorAttachments[0].pixelFormat = .invalid
        
        if shadowDescriptor.vertexFunction != nil && shadowDescriptor.fragmentFunction != nil {
            cascadedShadowPipelineState = try device.makeRenderPipelineState(descriptor: shadowDescriptor)
        } else {
            print("⚠️ Cascaded shadow shaders not found - using fallback")
        }
        
        // Romanian Cultural Lighting Pipeline
        let romanianDescriptor = MTLRenderPipelineDescriptor()
        romanianDescriptor.label = "RomanianLightingPipeline"
        romanianDescriptor.vertexFunction = library.makeFunction(name: "romanianLightingVertexShader")
        romanianDescriptor.fragmentFunction = library.makeFunction(name: "romanianLightingFragmentShader")
        romanianDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm_srgb
        romanianDescriptor.depthAttachmentPixelFormat = .depth32Float
        
        if romanianDescriptor.vertexFunction != nil && romanianDescriptor.fragmentFunction != nil {
            romanianLightingPipelineState = try device.makeRenderPipelineState(descriptor: romanianDescriptor)
        } else {
            print("⚠️ Romanian lighting shaders not found - using fallback")
        }
    }
    
    private func setupLightingResources() throws {
        // Create shadow map cascades
        shadowMapCascades = try shadowMapManager.createCascades(count: 4, resolution: 2048)
        
        // Create light probe texture
        lightProbeTexture = try lightProbeManager.createLightProbeTexture(size: 128)
        
        // Create irradiance map for global illumination
        irradianceMapTexture = try createIrradianceMap(size: 64)
        
        print("✅ Lighting resources initialized")
    }
    
    private func setupRomanianCulturalLighting() throws {
        // Create cultural light probes for authentic Romanian lighting
        culturalLightProbes = try createRomanianCulturalLightProbes()
        
        // Initialize Romanian lighting parameters
        updateRomanianLightingParameters()
        
        print("🏛️ Romanian cultural lighting setup complete")
    }
    
    // MARK: - Lighting Rendering API
    
    /// Render advanced lighting for the scene
    func renderAdvancedLighting(
        commandBuffer: MTLCommandBuffer,
        sceneData: SceneRenderingData,
        lightingEnvironment: LightingEnvironment
    ) throws {
        
        let startTime = CACurrentMediaTime()
        
        // Update lighting uniforms
        updateLightingUniforms(lightingEnvironment: lightingEnvironment, sceneData: sceneData)
        
        // 1. Cascaded shadow map pass
        if enableCascadedShadows {
            try renderCascadedShadowMaps(commandBuffer: commandBuffer, sceneData: sceneData)
        }
        
        // 2. Global illumination pass
        if enableGlobalIllumination {
            try renderGlobalIllumination(commandBuffer: commandBuffer, sceneData: sceneData)
        }
        
        // 3. Light bouncing pass
        if enableLightBouncing {
            try renderLightBouncing(commandBuffer: commandBuffer, sceneData: sceneData)
        }
        
        // 4. Romanian cultural lighting pass
        if enableRomanianCulturalLighting {
            try renderRomanianCulturalLighting(commandBuffer: commandBuffer, sceneData: sceneData)
        }
        
        // Update performance metrics
        lightingRenderTime = CACurrentMediaTime() - startTime
    }
    
    // MARK: - Rendering Passes
    
    private func renderCascadedShadowMaps(commandBuffer: MTLCommandBuffer, sceneData: SceneRenderingData) throws {
        guard let pipelineState = cascadedShadowPipelineState else { return }
        
        for (index, shadowMap) in shadowMapCascades.enumerated() {
            let renderPassDescriptor = MTLRenderPassDescriptor()
            renderPassDescriptor.depthAttachment.texture = shadowMap
            renderPassDescriptor.depthAttachment.loadAction = .clear
            renderPassDescriptor.depthAttachment.storeAction = .store
            renderPassDescriptor.depthAttachment.clearDepth = 1.0
            
            guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
                throw AdvancedLightingError.renderEncoderCreationFailed
            }
            
            renderEncoder.label = "CascadedShadowMap_\(index)"
            renderEncoder.setRenderPipelineState(pipelineState)
            
            // Set cascade-specific uniforms
            var cascadeData = shadowMapManager.getCascadeData(index: index, sceneData: sceneData)
            renderEncoder.setVertexBytes(&cascadeData, length: MemoryLayout<CascadeData>.stride, index: 0)
            
            // Render shadow-casting geometry for this cascade
            renderShadowCastingGeometry(renderEncoder: renderEncoder, cascadeIndex: index, sceneData: sceneData)
            
            renderEncoder.endEncoding()
        }
    }
    
    private func renderGlobalIllumination(commandBuffer: MTLCommandBuffer, sceneData: SceneRenderingData) throws {
        guard let computeState = globalIlluminationPipelineState,
              let lightProbeTexture = lightProbeTexture,
              let irradianceMapTexture = irradianceMapTexture else { return }
        
        guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            throw AdvancedLightingError.computeEncoderCreationFailed
        }
        
        computeEncoder.label = "GlobalIllumination"
        computeEncoder.setComputePipelineState(computeState)
        
        // Set compute resources
        computeEncoder.setBuffer(globalIlluminationBuffer, offset: 0, index: 0)
        computeEncoder.setTexture(lightProbeTexture, index: 0)
        computeEncoder.setTexture(irradianceMapTexture, index: 1)
        
        // Dispatch global illumination computation
        let threadsPerGroup = MTLSize(width: 16, height: 16, depth: 1)
        let threadgroupCount = MTLSize(
            width: (lightProbeTexture.width + threadsPerGroup.width - 1) / threadsPerGroup.width,
            height: (lightProbeTexture.height + threadsPerGroup.height - 1) / threadsPerGroup.height,
            depth: 1
        )
        
        computeEncoder.dispatchThreadgroups(threadgroupCount, threadsPerThreadgroup: threadsPerGroup)
        computeEncoder.endEncoding()
    }
    
    private func renderLightBouncing(commandBuffer: MTLCommandBuffer, sceneData: SceneRenderingData) throws {
        guard let computeState = lightBounceComputeState else { return }
        
        guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            throw AdvancedLightingError.computeEncoderCreationFailed
        }
        
        computeEncoder.label = "LightBouncing"
        computeEncoder.setComputePipelineState(computeState)
        
        // Set light bouncing parameters
        var bounceParams = LightBounceParameters(
            bounceCount: lightingQuality.maxBounces,
            bounceIntensity: 0.7,
            materialReflectance: 0.8,
            energyConservation: 0.95
        )
        
        computeEncoder.setBytes(&bounceParams, length: MemoryLayout<LightBounceParameters>.stride, index: 0)
        computeEncoder.setBuffer(lightBuffer, offset: 0, index: 1)
        
        if let lightProbeTexture = lightProbeTexture {
            computeEncoder.setTexture(lightProbeTexture, index: 0)
        }
        
        // Dispatch light bouncing computation
        let threadsPerGroup = MTLSize(width: 32, height: 1, depth: 1)
        let threadgroupCount = MTLSize(width: globalIlluminationSamples / 32 + 1, height: 1, depth: 1)
        
        computeEncoder.dispatchThreadgroups(threadgroupCount, threadsPerThreadgroup: threadsPerGroup)
        computeEncoder.endEncoding()
    }
    
    private func renderRomanianCulturalLighting(commandBuffer: MTLCommandBuffer, sceneData: SceneRenderingData) throws {
        guard let pipelineState = romanianLightingPipelineState else { return }
        
        // Create a render pass for cultural lighting overlay
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = sceneData.colorTarget
        renderPassDescriptor.colorAttachments[0].loadAction = .load
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            throw AdvancedLightingError.renderEncoderCreationFailed
        }
        
        renderEncoder.label = "RomanianCulturalLighting"
        renderEncoder.setRenderPipelineState(pipelineState)
        
        // Set Romanian lighting parameters
        renderEncoder.setFragmentBuffer(romanianLightingParameters, offset: 0, index: 0)
        
        // Set cultural light probe textures
        for (index, lightProbe) in culturalLightProbes.enumerated() {
            renderEncoder.setFragmentTexture(lightProbe, index: index + 10) // Use higher indices
        }
        
        // Render full-screen quad for cultural lighting overlay
        renderFullScreenQuad(renderEncoder: renderEncoder)
        
        renderEncoder.endEncoding()
    }
    
    // MARK: - Helper Methods
    
    private func createIrradianceMap(size: Int) throws -> MTLTexture {
        let descriptor = MTLTextureDescriptor()
        descriptor.textureType = .typeCube
        descriptor.pixelFormat = .rgba16Float
        descriptor.width = size
        descriptor.height = size
        descriptor.depth = 1
        descriptor.mipmapLevelCount = 1
        descriptor.usage = [.shaderRead, .shaderWrite]
        descriptor.storageMode = .private
        
        guard let texture = device.makeTexture(descriptor: descriptor) else {
            throw AdvancedLightingError.textureCreationFailed
        }
        
        texture.label = "IrradianceMap"
        return texture
    }
    
    private func createRomanianCulturalLightProbes() throws -> [MTLTexture] {
        var probes: [MTLTexture] = []
        
        // Create different cultural lighting scenarios
        let culturalLightingScenarios: [RomanianLightingScenario] = [
            .goldenHour,    // Warm golden lighting reminiscent of Romanian sunsets
            .candlelight,   // Traditional church lighting
            .fireplace,     // Cozy indoor Romanian home lighting
            .harvest        // Autumn harvest lighting
        ]
        
        for scenario in culturalLightingScenarios {
            let probe = try lightProbeManager.createCulturalLightProbe(scenario: scenario)
            probes.append(probe)
        }
        
        return probes
    }
    
    private func updateLightingUniforms(lightingEnvironment: LightingEnvironment, sceneData: SceneRenderingData) {
        let lightingPtr = lightBuffer.contents().bindMemory(to: AdvancedLightingUniforms.self, capacity: 1)
        
        lightingPtr.pointee = AdvancedLightingUniforms(
            primaryLightDirection: lightingEnvironment.primaryLightDirection,
            primaryLightColor: lightingEnvironment.primaryLightColor * primaryLightIntensity,
            ambientLightColor: lightingEnvironment.ambientLightColor * ambientLightIntensity,
            globalIlluminationIntensity: enableGlobalIllumination ? 1.0 : 0.0,
            lightBounceIntensity: enableLightBouncing ? 0.8 : 0.0,
            shadowMapCount: Float(shadowMapCascades.count),
            romanianCulturalTint: lightingEnvironment.romanianCulturalTint * romanianWarmthFactor,
            goldenHourIntensity: goldenHourTinting,
            time: Float(CACurrentMediaTime())
        )
        
        // Update global illumination parameters
        let giPtr = globalIlluminationBuffer.contents().bindMemory(to: GlobalIlluminationParameters.self, capacity: 1)
        
        giPtr.pointee = GlobalIlluminationParameters(
            sampleCount: globalIlluminationSamples,
            maxBounces: lightingQuality.maxBounces,
            energyThreshold: 0.01,
            indirectIntensity: enableGlobalIllumination ? 0.6 : 0.0
        )
    }
    
    private func updateRomanianLightingParameters() {
        let romanianPtr = romanianLightingParameters.contents().bindMemory(to: RomanianLightingParameters.self, capacity: 1)
        
        romanianPtr.pointee = RomanianLightingParameters(
            warmthFactor: romanianWarmthFactor,
            goldenHourTinting: goldenHourTinting,
            culturalAmbientColor: simd_float3(1.0, 0.9, 0.7), // Warm Romanian interior colors
            traditionAdjustment: enableRomanianCulturalLighting ? 1.0 : 0.0,
            candlelightIntensity: 0.3,
            fireplaceGlow: 0.4,
            churchLightingFactor: 0.2
        )
    }
    
    private func renderShadowCastingGeometry(renderEncoder: MTLRenderCommandEncoder, cascadeIndex: Int, sceneData: SceneRenderingData) {
        // Render geometry that casts shadows
        // In a real implementation, this would iterate through all shadow-casting objects
        
        // For now, render card geometry
        for cardGeometry in sceneData.cardGeometries {
            renderEncoder.setVertexBuffer(cardGeometry.vertexBuffer, offset: 0, index: 0)
            renderEncoder.drawIndexedPrimitives(
                type: .triangle,
                indexCount: cardGeometry.indexCount,
                indexType: cardGeometry.indexType,
                indexBuffer: cardGeometry.indexBuffer,
                indexBufferOffset: 0
            )
        }
    }
    
    private func renderFullScreenQuad(renderEncoder: MTLRenderCommandEncoder) {
        // Render a full-screen quad for post-processing effects
        // This would typically use a pre-generated quad geometry
        
        // For now, we'll assume the quad geometry is available
        // In production, this would be a cached full-screen quad
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
    }
    
    // MARK: - Configuration API
    
    /// Set lighting quality level
    func setLightingQuality(_ quality: LightingQuality) {
        lightingQuality = quality
        
        // Update dependent parameters
        globalIlluminationSamples = quality.globalIlluminationSamples
        shadowMapUpdateFrequency = quality.shadowMapUpdateFrequency
        
        objectWillChange.send()
    }
    
    /// Configure Romanian cultural lighting
    func configureRomanianLighting(warmth: Float, goldenHour: Float) {
        romanianWarmthFactor = max(0.0, min(1.0, warmth))
        goldenHourTinting = max(0.0, min(1.0, goldenHour))
        
        updateRomanianLightingParameters()
        objectWillChange.send()
    }
    
    /// Get current lighting metrics for performance monitoring
    func getCurrentLightingMetrics() -> LightingMetrics {
        return LightingMetrics(
            renderTime: lightingRenderTime,
            shadowMapCount: shadowMapCascades.count,
            globalIlluminationSamples: globalIlluminationSamples,
            lightProbeCount: culturalLightProbes.count,
            memoryUsage: calculateLightingMemoryUsage()
        )
    }
    
    private func calculateLightingMemoryUsage() -> Int {
        var usage = 0
        
        // Shadow maps
        for shadowMap in shadowMapCascades {
            usage += shadowMap.width * shadowMap.height * 4 // 32-bit depth
        }
        
        // Light probes
        if let lightProbe = lightProbeTexture {
            usage += lightProbe.width * lightProbe.height * 6 * 8 // Cube map, RGBA16F
        }
        
        // Cultural light probes
        for probe in culturalLightProbes {
            usage += probe.width * probe.height * 6 * 8 // Cube map, RGBA16F
        }
        
        return usage
    }
}

// MARK: - Supporting Types

struct AdvancedLightingUniforms {
    let primaryLightDirection: simd_float3
    let primaryLightColor: simd_float3
    let ambientLightColor: simd_float3
    let globalIlluminationIntensity: Float
    let lightBounceIntensity: Float
    let shadowMapCount: Float
    let romanianCulturalTint: simd_float3
    let goldenHourIntensity: Float
    let time: Float
}

struct GlobalIlluminationParameters {
    let sampleCount: Int
    let maxBounces: Int
    let energyThreshold: Float
    let indirectIntensity: Float
}

struct RomanianLightingParameters {
    let warmthFactor: Float
    let goldenHourTinting: Float
    let culturalAmbientColor: simd_float3
    let traditionAdjustment: Float
    let candlelightIntensity: Float
    let fireplaceGlow: Float
    let churchLightingFactor: Float
}

struct LightBounceParameters {
    let bounceCount: Int
    let bounceIntensity: Float
    let materialReflectance: Float
    let energyConservation: Float
}

struct CascadeData {
    let lightSpaceMatrix: matrix_float4x4
    let cascadeIndex: Int
    let splitDistance: Float
    let bias: Float
}


struct LightingMetrics {
    let renderTime: Double
    let shadowMapCount: Int
    let globalIlluminationSamples: Int
    let lightProbeCount: Int
    let memoryUsage: Int
}

enum LightingQuality {
    case low
    case medium
    case high
    case ultra
    
    var maxBounces: Int {
        switch self {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        case .ultra: return 4
        }
    }
    
    var globalIlluminationSamples: Int {
        switch self {
        case .low: return 16
        case .medium: return 32
        case .high: return 64
        case .ultra: return 128
        }
    }
    
    var shadowMapUpdateFrequency: Int {
        switch self {
        case .low: return 30
        case .medium: return 60
        case .high: return 60
        case .ultra: return 120
        }
    }
}

enum RomanianLightingScenario {
    case goldenHour
    case candlelight
    case fireplace
    case harvest
    
    var description: String {
        switch self {
        case .goldenHour:
            return "Warm golden sunset lighting typical of Romanian countryside"
        case .candlelight:
            return "Traditional church and monastery lighting"
        case .fireplace:
            return "Cozy home lighting from traditional Romanian hearths"
        case .harvest:
            return "Autumn harvest lighting with warm, earthy tones"
        }
    }
}

struct RomanianLightingConfiguration {
    var enableWarmTinting: Bool = true
    var enableGoldenHourEffects: Bool = true
    var enableCandlelightSimulation: Bool = true
    var enableFireplaceGlow: Bool = true
    var culturalLightingIntensity: Float = 0.8
}

// MARK: - Helper Classes

class LightProbeManager {
    private let device: MTLDevice
    
    init(device: MTLDevice) throws {
        self.device = device
    }
    
    func createLightProbeTexture(size: Int) throws -> MTLTexture {
        let descriptor = MTLTextureDescriptor()
        descriptor.textureType = .typeCube
        descriptor.pixelFormat = .rgba16Float
        descriptor.width = size
        descriptor.height = size
        descriptor.usage = [.shaderRead, .shaderWrite]
        descriptor.storageMode = .private
        
        guard let texture = device.makeTexture(descriptor: descriptor) else {
            throw AdvancedLightingError.textureCreationFailed
        }
        
        texture.label = "LightProbe"
        return texture
    }
    
    func createCulturalLightProbe(scenario: RomanianLightingScenario) throws -> MTLTexture {
        let probe = try createLightProbeTexture(size: 64)
        probe.label = "CulturalLightProbe_\(scenario)"
        
        // In production, this would generate appropriate lighting based on scenario
        return probe
    }
}

class CascadedShadowMapManager {
    private let device: MTLDevice
    
    init(device: MTLDevice) throws {
        self.device = device
    }
    
    func createCascades(count: Int, resolution: Int) throws -> [MTLTexture] {
        var cascades: [MTLTexture] = []
        
        for i in 0..<count {
            let descriptor = MTLTextureDescriptor()
            descriptor.textureType = .type2D
            descriptor.pixelFormat = .depth32Float
            descriptor.width = resolution
            descriptor.height = resolution
            descriptor.usage = [.renderTarget, .shaderRead]
            descriptor.storageMode = .private
            
            guard let texture = device.makeTexture(descriptor: descriptor) else {
                throw AdvancedLightingError.textureCreationFailed
            }
            
            texture.label = "ShadowMapCascade_\(i)"
            cascades.append(texture)
        }
        
        return cascades
    }
    
    func getCascadeData(index: Int, sceneData: SceneRenderingData) -> CascadeData {
        // Calculate cascade-specific data
        let splitDistances: [Float] = [5.0, 15.0, 50.0, 150.0]
        let biases: [Float] = [0.001, 0.002, 0.005, 0.01]
        
        return CascadeData(
            lightSpaceMatrix: calculateLightSpaceMatrix(cascadeIndex: index, sceneData: sceneData),
            cascadeIndex: index,
            splitDistance: splitDistances[min(index, splitDistances.count - 1)],
            bias: biases[min(index, biases.count - 1)]
        )
    }
    
    private func calculateLightSpaceMatrix(cascadeIndex: Int, sceneData: SceneRenderingData) -> matrix_float4x4 {
        // In production, this would calculate the light space matrix for the specific cascade
        // For now, return identity matrix
        return matrix_identity_float4x4
    }
}

// MARK: - Error Types

enum AdvancedLightingError: Error, LocalizedError {
    case libraryCreationFailed
    case bufferAllocationFailed
    case textureCreationFailed
    case pipelineStateCreationFailed
    case renderEncoderCreationFailed
    case computeEncoderCreationFailed
    
    var errorDescription: String? {
        switch self {
        case .libraryCreationFailed:
            return "Failed to create Metal library for advanced lighting"
        case .bufferAllocationFailed:
            return "Failed to allocate lighting buffers"
        case .textureCreationFailed:
            return "Failed to create lighting textures"
        case .pipelineStateCreationFailed:
            return "Failed to create lighting pipeline states"
        case .renderEncoderCreationFailed:
            return "Failed to create render encoder for lighting"
        case .computeEncoderCreationFailed:
            return "Failed to create compute encoder for lighting"
        }
    }
}