//
//  AdvancedVisualEffectsIntegration.swift
//  Septica
//
//  Advanced visual effects integration combining lighting, materials, and Romanian cultural elements
//  Provides ShuffleCats-quality visual effects with performance optimization
//

#if canImport(Metal)
import Metal
import MetalKit
import MetalPerformanceShaders
#endif
import SwiftUI
import simd
import Combine

// MARK: - Advanced Visual Effects Integration

/// Master visual effects system that integrates lighting, materials, and cultural elements
@MainActor
class AdvancedVisualEffectsIntegration: ObservableObject {
    
    // MARK: - Core Systems
    
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let advancedLightingSystem: AdvancedLightingSystem
    private let enhancedMaterialSystem: EnhancedMaterialSystem
    private let cardVisualEffectsManager: CardVisualEffectsManager
    private let materialEffectSystem: MaterialEffectSystem
    
    // MARK: - Advanced Effect Pipeline States
    
    private var reflectionPipelineState: MTLComputePipelineState?
    private var refractionPipelineState: MTLComputePipelineState?
    private var shimmerEffectPipelineState: MTLRenderPipelineState?
    private var culturalGlowPipelineState: MTLRenderPipelineState?
    private var particleSystemPipelineState: MTLRenderPipelineState?
    
    // MARK: - Visual Effect Resources
    
    private var reflectionTexture: MTLTexture?
    private var refractionTexture: MTLTexture?
    private var shimmerTexture: MTLTexture?
    private var particleBuffer: MTLBuffer?
    private var effectParametersBuffer: MTLBuffer
    
    // MARK: - Romanian Cultural Effects
    
    private var romanianEffectTextures: [String: MTLTexture] = [:]
    private var culturalParticleTextures: [MTLTexture] = []
    private var goldLeafEffectTexture: MTLTexture?
    private var embroideryPatternTexture: MTLTexture?
    
    // MARK: - Published Properties
    
    @Published var visualEffectsQuality: VisualEffectsQuality = .high
    @Published var enableAdvancedReflections: Bool = true
    @Published var enableRefractions: Bool = true
    @Published var enableShimmerEffects: Bool = true
    @Published var enableCulturalGlow: Bool = true
    @Published var enableParticleEffects: Bool = true
    @Published var enableRomanianCulturalEffects: Bool = true
    
    @Published var globalEffectIntensity: Float = 1.0
    @Published var reflectionIntensity: Float = 0.8
    @Published var refractionIntensity: Float = 0.6
    @Published var shimmerIntensity: Float = 0.7
    @Published var culturalEffectIntensity: Float = 0.9
    @Published var particleIntensity: Float = 0.8
    
    // MARK: - Performance Metrics
    
    @Published var totalRenderTime: Double = 0.0
    @Published var effectsRenderTime: Double = 0.0
    @Published var particleCount: Int = 0
    @Published var activeEffectCount: Int = 0
    @Published var memoryUsage: Int = 0
    
    // MARK: - Initialization
    
    init(device: MTLDevice, commandQueue: MTLCommandQueue) throws {
        self.device = device
        self.commandQueue = commandQueue
        
        // Initialize subsystems
        self.advancedLightingSystem = try AdvancedLightingSystem(device: device, commandQueue: commandQueue)
        
        // Create material effect system first
        self.materialEffectSystem = MaterialEffectSystem(device: device)
        
        // Then create enhanced material system with the material effect system
        self.enhancedMaterialSystem = try EnhancedMaterialSystem(
            device: device,
            materialEffectSystem: materialEffectSystem,
            advancedLightingSystem: advancedLightingSystem
        )
        
        self.cardVisualEffectsManager = CardVisualEffectsManager()
        
        // Allocate effect parameters buffer
        let effectBufferSize = MemoryLayout<AdvancedEffectParameters>.stride * 16
        guard let effectBuf = device.makeBuffer(length: effectBufferSize, options: [.storageModeShared]) else {
            throw AdvancedVisualEffectsError.bufferAllocationFailed
        }
        self.effectParametersBuffer = effectBuf
        effectParametersBuffer.label = "AdvancedEffectParametersBuffer"
        
        // Setup pipeline states
        try setupAdvancedEffectPipelines()
        
        // Initialize effect resources
        try setupEffectResources()
        
        // Setup Romanian cultural effects
        try setupRomanianCulturalEffects()
        
        print("✨ AdvancedVisualEffectsIntegration initialized successfully")
        print("   - Advanced Reflections: \(enableAdvancedReflections)")
        print("   - Refractions: \(enableRefractions)")
        print("   - Shimmer Effects: \(enableShimmerEffects)")
        print("   - Cultural Glow: \(enableCulturalGlow)")
        print("   - Particle Effects: \(enableParticleEffects)")
        print("   - Romanian Cultural Effects: \(enableRomanianCulturalEffects)")
    }
    
    // MARK: - Pipeline Setup
    
    private func setupAdvancedEffectPipelines() throws {
        guard let library = device.makeDefaultLibrary() else {
            throw AdvancedVisualEffectsError.libraryCreationFailed
        }
        
        // Reflection Compute Pipeline
        if let reflectionFunction = library.makeFunction(name: "advancedReflectionComputeShader") {
            reflectionPipelineState = try device.makeComputePipelineState(function: reflectionFunction)
        } else {
            print("⚠️ Advanced reflection shader not found - using fallback")
        }
        
        // Refraction Compute Pipeline
        if let refractionFunction = library.makeFunction(name: "refractionComputeShader") {
            refractionPipelineState = try device.makeComputePipelineState(function: refractionFunction)
        } else {
            print("⚠️ Refraction shader not found - using fallback")
        }
        
        // Shimmer Effect Pipeline
        let shimmerDescriptor = MTLRenderPipelineDescriptor()
        shimmerDescriptor.label = "ShimmerEffectPipeline"
        shimmerDescriptor.vertexFunction = library.makeFunction(name: "shimmerEffectVertexShader")
        shimmerDescriptor.fragmentFunction = library.makeFunction(name: "shimmerEffectFragmentShader")
        shimmerDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm_srgb
        shimmerDescriptor.depthAttachmentPixelFormat = .depth32Float
        
        if shimmerDescriptor.vertexFunction != nil && shimmerDescriptor.fragmentFunction != nil {
            shimmerEffectPipelineState = try device.makeRenderPipelineState(descriptor: shimmerDescriptor)
        } else {
            print("⚠️ Shimmer effect shaders not found - using fallback")
        }
        
        // Cultural Glow Pipeline
        let glowDescriptor = MTLRenderPipelineDescriptor()
        glowDescriptor.label = "CulturalGlowPipeline"
        glowDescriptor.vertexFunction = library.makeFunction(name: "culturalGlowVertexShader")
        glowDescriptor.fragmentFunction = library.makeFunction(name: "culturalGlowFragmentShader")
        glowDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm_srgb
        glowDescriptor.colorAttachments[0].isBlendingEnabled = true
        glowDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        glowDescriptor.colorAttachments[0].destinationRGBBlendFactor = .one
        
        if glowDescriptor.vertexFunction != nil && glowDescriptor.fragmentFunction != nil {
            culturalGlowPipelineState = try device.makeRenderPipelineState(descriptor: glowDescriptor)
        } else {
            print("⚠️ Cultural glow shaders not found - using fallback")
        }
        
        // Particle System Pipeline
        let particleDescriptor = MTLRenderPipelineDescriptor()
        particleDescriptor.label = "ParticleSystemPipeline"
        particleDescriptor.vertexFunction = library.makeFunction(name: "particleVertexShader")
        particleDescriptor.fragmentFunction = library.makeFunction(name: "particleFragmentShader")
        particleDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm_srgb
        particleDescriptor.colorAttachments[0].isBlendingEnabled = true
        particleDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        particleDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        
        if particleDescriptor.vertexFunction != nil && particleDescriptor.fragmentFunction != nil {
            particleSystemPipelineState = try device.makeRenderPipelineState(descriptor: particleDescriptor)
        } else {
            print("⚠️ Particle system shaders not found - using fallback")
        }
    }
    
    private func setupEffectResources() throws {
        // Create reflection texture
        reflectionTexture = try createEffectTexture(width: 1024, height: 1024, label: "ReflectionTexture")
        
        // Create refraction texture
        refractionTexture = try createEffectTexture(width: 512, height: 512, label: "RefractionTexture")
        
        // Create shimmer texture
        shimmerTexture = try createEffectTexture(width: 256, height: 256, label: "ShimmerTexture")
        
        // Create particle buffer
        let particleBufferSize = MemoryLayout<ParticleData>.stride * 10000 // Support 10k particles
        guard let particleBuf = device.makeBuffer(length: particleBufferSize, options: [.storageModeShared]) else {
            throw AdvancedVisualEffectsError.bufferAllocationFailed
        }
        self.particleBuffer = particleBuf
        particleBuffer?.label = "ParticleBuffer"
        
        print("✅ Advanced effect resources initialized")
    }
    
    private func setupRomanianCulturalEffects() throws {
        // Create Romanian-specific effect textures
        goldLeafEffectTexture = try createCulturalEffectTexture(name: "GoldLeafEffect")
        embroideryPatternTexture = try createCulturalEffectTexture(name: "EmbroideryPattern")
        
        // Create cultural particle textures
        let culturalParticleNames = ["RomanianStar", "TraditionalRosette", "FolkPattern", "GoldenSparkle"]
        
        for name in culturalParticleNames {
            let texture = try createParticleTexture(name: name)
            culturalParticleTextures.append(texture)
        }
        
        // Store Romanian effect textures
        romanianEffectTextures["goldLeaf"] = goldLeafEffectTexture
        romanianEffectTextures["embroidery"] = embroideryPatternTexture
        
        print("🏛️ Romanian cultural effects setup complete")
    }
    
    // MARK: - Master Rendering API
    
    /// Render complete advanced visual effects pipeline
    func renderAdvancedVisualEffects(
        commandBuffer: MTLCommandBuffer,
        sceneData: SceneRenderingData,
        cards: [Card],
        lightingEnvironment: LightingEnvironment
    ) throws {
        
        let startTime = CACurrentMediaTime()
        
        // Update effect parameters
        updateEffectParameters(cards: cards, lightingEnvironment: lightingEnvironment)
        
        // 1. Advanced Lighting Pass
        try advancedLightingSystem.renderAdvancedLighting(
            commandBuffer: commandBuffer,
            sceneData: sceneData,
            lightingEnvironment: lightingEnvironment
        )
        
        // 2. Enhanced Materials Pass
        try enhancedMaterialSystem.renderEnhancedMaterials(
            commandBuffer: commandBuffer,
            sceneData: sceneData,
            cards: cards
        )
        
        // 3. Advanced Reflections Pass
        if enableAdvancedReflections {
            try renderAdvancedReflections(commandBuffer: commandBuffer, sceneData: sceneData)
        }
        
        // 4. Refraction Effects Pass
        if enableRefractions {
            try renderRefractionEffects(commandBuffer: commandBuffer, sceneData: sceneData)
        }
        
        // 5. Shimmer Effects Pass
        if enableShimmerEffects {
            try renderShimmerEffects(commandBuffer: commandBuffer, sceneData: sceneData, cards: cards)
        }
        
        // 6. Romanian Cultural Glow Pass
        if enableCulturalGlow && enableRomanianCulturalEffects {
            try renderCulturalGlowEffects(commandBuffer: commandBuffer, sceneData: sceneData, cards: cards)
        }
        
        // 7. Particle Effects Pass
        if enableParticleEffects {
            try renderParticleEffects(commandBuffer: commandBuffer, sceneData: sceneData)
        }
        
        // Update performance metrics
        totalRenderTime = CACurrentMediaTime() - startTime
        effectsRenderTime = totalRenderTime - advancedLightingSystem.lightingRenderTime - enhancedMaterialSystem.materialRenderTime
        activeEffectCount = cardVisualEffectsManager.activeEffects.count
    }
    
    // MARK: - Effect Rendering Passes
    
    private func renderAdvancedReflections(commandBuffer: MTLCommandBuffer, sceneData: SceneRenderingData) throws {
        guard let computeState = reflectionPipelineState,
              let reflectionTexture = reflectionTexture else { return }
        
        guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            throw AdvancedVisualEffectsError.computeEncoderCreationFailed
        }
        
        computeEncoder.label = "AdvancedReflections"
        computeEncoder.setComputePipelineState(computeState)
        
        // Set reflection parameters
        var reflectionParams = ReflectionParameters(
            intensity: reflectionIntensity * globalEffectIntensity,
            roughness: 0.1,
            fresnel: 0.04,
            quality: visualEffectsQuality.reflectionQuality
        )
        
        computeEncoder.setBytes(&reflectionParams, length: MemoryLayout<ReflectionParameters>.stride, index: 0)
        computeEncoder.setTexture(sceneData.colorTarget, index: 0)
        computeEncoder.setTexture(reflectionTexture, index: 1)
        
        // Dispatch reflection computation
        let threadsPerGroup = MTLSize(width: 16, height: 16, depth: 1)
        let threadgroupCount = MTLSize(
            width: (reflectionTexture.width + threadsPerGroup.width - 1) / threadsPerGroup.width,
            height: (reflectionTexture.height + threadsPerGroup.height - 1) / threadsPerGroup.height,
            depth: 1
        )
        
        computeEncoder.dispatchThreadgroups(threadgroupCount, threadsPerThreadgroup: threadsPerGroup)
        computeEncoder.endEncoding()
    }
    
    private func renderRefractionEffects(commandBuffer: MTLCommandBuffer, sceneData: SceneRenderingData) throws {
        guard let computeState = refractionPipelineState,
              let refractionTexture = refractionTexture else { return }
        
        guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            throw AdvancedVisualEffectsError.computeEncoderCreationFailed
        }
        
        computeEncoder.label = "RefractionEffects"
        computeEncoder.setComputePipelineState(computeState)
        
        // Set refraction parameters
        var refractionParams = RefractionParameters(
            intensity: refractionIntensity * globalEffectIntensity,
            ior: 1.5,
            thickness: 0.1,
            distortion: 0.05
        )
        
        computeEncoder.setBytes(&refractionParams, length: MemoryLayout<RefractionParameters>.stride, index: 0)
        computeEncoder.setTexture(sceneData.colorTarget, index: 0)
        computeEncoder.setTexture(refractionTexture, index: 1)
        
        // Dispatch refraction computation
        let threadsPerGroup = MTLSize(width: 16, height: 16, depth: 1)
        let threadgroupCount = MTLSize(
            width: (refractionTexture.width + threadsPerGroup.width - 1) / threadsPerGroup.width,
            height: (refractionTexture.height + threadsPerGroup.height - 1) / threadsPerGroup.height,
            depth: 1
        )
        
        computeEncoder.dispatchThreadgroups(threadgroupCount, threadsPerThreadgroup: threadsPerGroup)
        computeEncoder.endEncoding()
    }
    
    private func renderShimmerEffects(commandBuffer: MTLCommandBuffer, sceneData: SceneRenderingData, cards: [Card]) throws {
        guard let pipelineState = shimmerEffectPipelineState,
              let shimmerTexture = shimmerTexture else { return }
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = sceneData.colorTarget
        renderPassDescriptor.colorAttachments[0].loadAction = .load
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            throw AdvancedVisualEffectsError.renderEncoderCreationFailed
        }
        
        renderEncoder.label = "ShimmerEffects"
        renderEncoder.setRenderPipelineState(pipelineState)
        
        // Set shimmer parameters
        var shimmerParams = ShimmerParameters(
            intensity: shimmerIntensity * globalEffectIntensity,
            speed: 2.0,
            scale: 1.0,
            time: Float(CACurrentMediaTime())
        )
        
        renderEncoder.setFragmentBytes(&shimmerParams, length: MemoryLayout<ShimmerParameters>.stride, index: 0)
        renderEncoder.setFragmentTexture(shimmerTexture, index: 0)
        
        // Render shimmer for special cards (like sevens)
        for card in cards {
            if card.value == 7 || card.isPointCard {
                // Render shimmer overlay
                renderFullScreenQuad(renderEncoder: renderEncoder)
            }
        }
        
        renderEncoder.endEncoding()
    }
    
    private func renderCulturalGlowEffects(commandBuffer: MTLCommandBuffer, sceneData: SceneRenderingData, cards: [Card]) throws {
        guard let pipelineState = culturalGlowPipelineState else { return }
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = sceneData.colorTarget
        renderPassDescriptor.colorAttachments[0].loadAction = .load
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            throw AdvancedVisualEffectsError.renderEncoderCreationFailed
        }
        
        renderEncoder.label = "CulturalGlowEffects"
        renderEncoder.setRenderPipelineState(pipelineState)
        
        // Set cultural glow parameters
        var glowParams = CulturalGlowParameters(
            intensity: culturalEffectIntensity * globalEffectIntensity,
            warmth: 0.8,
            goldenRatio: 0.618,
            time: Float(CACurrentMediaTime())
        )
        
        renderEncoder.setFragmentBytes(&glowParams, length: MemoryLayout<CulturalGlowParameters>.stride, index: 0)
        
        // Set Romanian effect textures
        if let goldLeafTexture = goldLeafEffectTexture {
            renderEncoder.setFragmentTexture(goldLeafTexture, index: 0)
        }
        
        if let embroideryTexture = embroideryPatternTexture {
            renderEncoder.setFragmentTexture(embroideryTexture, index: 1)
        }
        
        // Render cultural glow for Romanian cards
        for card in cards {
            if shouldApplyCulturalEffects(to: card) {
                renderFullScreenQuad(renderEncoder: renderEncoder)
            }
        }
        
        renderEncoder.endEncoding()
    }
    
    private func renderParticleEffects(commandBuffer: MTLCommandBuffer, sceneData: SceneRenderingData) throws {
        guard let pipelineState = particleSystemPipelineState,
              let particleBuffer = particleBuffer else { return }
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = sceneData.colorTarget
        renderPassDescriptor.colorAttachments[0].loadAction = .load
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            throw AdvancedVisualEffectsError.renderEncoderCreationFailed
        }
        
        renderEncoder.label = "ParticleEffects"
        renderEncoder.setRenderPipelineState(pipelineState)
        
        // Set particle parameters
        var particleParams = ParticleParameters(
            intensity: particleIntensity * globalEffectIntensity,
            count: visualEffectsQuality.maxParticleCount,
            lifetime: 2.0,
            size: 4.0
        )
        
        renderEncoder.setVertexBytes(&particleParams, length: MemoryLayout<ParticleParameters>.stride, index: 1)
        renderEncoder.setVertexBuffer(particleBuffer, offset: 0, index: 0)
        
        // Set cultural particle textures
        for (index, texture) in culturalParticleTextures.enumerated() {
            if index < 4 { // Limit to available texture slots
                renderEncoder.setFragmentTexture(texture, index: index)
            }
        }
        
        // Render particles
        renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: particleParams.count)
        
        renderEncoder.endEncoding()
    }
    
    // MARK: - Helper Methods
    
    private func createEffectTexture(width: Int, height: Int, label: String) throws -> MTLTexture {
        let descriptor = MTLTextureDescriptor()
        descriptor.textureType = .type2D
        descriptor.pixelFormat = .rgba16Float
        descriptor.width = width
        descriptor.height = height
        descriptor.usage = [.shaderRead, .shaderWrite]
        descriptor.storageMode = .private
        
        guard let texture = device.makeTexture(descriptor: descriptor) else {
            throw AdvancedVisualEffectsError.textureCreationFailed
        }
        
        texture.label = label
        return texture
    }
    
    private func createCulturalEffectTexture(name: String) throws -> MTLTexture {
        let texture = try createEffectTexture(width: 512, height: 512, label: name)
        // In production, this would load actual cultural effect patterns
        return texture
    }
    
    private func createParticleTexture(name: String) throws -> MTLTexture {
        let texture = try createEffectTexture(width: 64, height: 64, label: "\(name)_Particle")
        // In production, this would load actual particle textures
        return texture
    }
    
    private func updateEffectParameters(cards: [Card], lightingEnvironment: LightingEnvironment) {
        let effectPtr = effectParametersBuffer.contents().bindMemory(to: AdvancedEffectParameters.self, capacity: 1)
        
        effectPtr.pointee = AdvancedEffectParameters(
            globalIntensity: globalEffectIntensity,
            reflectionIntensity: reflectionIntensity,
            refractionIntensity: refractionIntensity,
            shimmerIntensity: shimmerIntensity,
            culturalIntensity: culturalEffectIntensity,
            particleIntensity: particleIntensity,
            time: Float(CACurrentMediaTime()),
            lightDirection: lightingEnvironment.primaryLightDirection,
            romanianWarmth: lightingEnvironment.romanianCulturalTint
        )
    }
    
    private func shouldApplyCulturalEffects(to card: Card) -> Bool {
        // Apply cultural effects to special cards or based on cultural setting
        return card.value == 7 || card.isPointCard || enableRomanianCulturalEffects
    }
    
    private func renderFullScreenQuad(renderEncoder: MTLRenderCommandEncoder) {
        // Render a full-screen quad
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
    }
    
    // MARK: - Configuration API
    
    /// Set visual effects quality
    func setVisualEffectsQuality(_ quality: VisualEffectsQuality) {
        visualEffectsQuality = quality
        
        // Update subsystem qualities
        advancedLightingSystem.setLightingQuality(quality.lightingQuality)
        enhancedMaterialSystem.setMaterialQuality(quality.materialQuality)
        
        objectWillChange.send()
    }
    
    /// Configure effect intensities
    func configureEffectIntensities(
        global: Float,
        reflection: Float,
        refraction: Float,
        shimmer: Float,
        cultural: Float,
        particle: Float
    ) {
        globalEffectIntensity = max(0.0, min(2.0, global))
        reflectionIntensity = max(0.0, min(1.0, reflection))
        refractionIntensity = max(0.0, min(1.0, refraction))
        shimmerIntensity = max(0.0, min(1.0, shimmer))
        culturalEffectIntensity = max(0.0, min(1.0, cultural))
        particleIntensity = max(0.0, min(1.0, particle))
        
        objectWillChange.send()
    }
    
    /// Get comprehensive performance metrics
    func getComprehensiveMetrics() -> ComprehensiveEffectsMetrics {
        let lightingMetrics = advancedLightingSystem.getCurrentLightingMetrics()
        let materialMetrics = enhancedMaterialSystem.getCurrentMaterialMetrics()
        
        return ComprehensiveEffectsMetrics(
            totalRenderTime: totalRenderTime,
            lightingRenderTime: lightingMetrics.renderTime,
            materialRenderTime: materialMetrics.renderTime,
            effectsRenderTime: effectsRenderTime,
            memoryUsage: calculateTotalMemoryUsage(),
            activeEffectCount: activeEffectCount,
            particleCount: particleCount,
            lightingMemoryUsage: lightingMetrics.memoryUsage,
            materialMemoryUsage: materialMetrics.memoryUsage
        )
    }
    
    private func calculateTotalMemoryUsage() -> Int {
        var usage = 0
        
        // Effect textures
        if let reflectionTexture = reflectionTexture {
            usage += reflectionTexture.width * reflectionTexture.height * 8 // RGBA16F
        }
        
        if let refractionTexture = refractionTexture {
            usage += refractionTexture.width * refractionTexture.height * 8 // RGBA16F
        }
        
        if let shimmerTexture = shimmerTexture {
            usage += shimmerTexture.width * shimmerTexture.height * 8 // RGBA16F
        }
        
        // Cultural effect textures
        for texture in romanianEffectTextures.values {
            usage += texture.width * texture.height * 8 // RGBA16F
        }
        
        // Particle textures
        for texture in culturalParticleTextures {
            usage += texture.width * texture.height * 8 // RGBA16F
        }
        
        // Buffers
        usage += effectParametersBuffer.length
        if let particleBuffer = particleBuffer {
            usage += particleBuffer.length
        }
        
        return usage
    }
}

// MARK: - Supporting Types

struct AdvancedEffectParameters {
    let globalIntensity: Float
    let reflectionIntensity: Float
    let refractionIntensity: Float
    let shimmerIntensity: Float
    let culturalIntensity: Float
    let particleIntensity: Float
    let time: Float
    let lightDirection: simd_float3
    let romanianWarmth: simd_float3
}

struct ReflectionParameters {
    let intensity: Float
    let roughness: Float
    let fresnel: Float
    let quality: Int
}

struct RefractionParameters {
    let intensity: Float
    let ior: Float
    let thickness: Float
    let distortion: Float
}

struct ShimmerParameters {
    let intensity: Float
    let speed: Float
    let scale: Float
    let time: Float
}

struct CulturalGlowParameters {
    let intensity: Float
    let warmth: Float
    let goldenRatio: Float
    let time: Float
}

struct ParticleParameters {
    let intensity: Float
    let count: Int
    let lifetime: Float
    let size: Float
}

struct ParticleData {
    let position: simd_float3
    let velocity: simd_float3
    let color: simd_float4
    let life: Float
    let size: Float
}

struct ComprehensiveEffectsMetrics {
    let totalRenderTime: Double
    let lightingRenderTime: Double
    let materialRenderTime: Double
    let effectsRenderTime: Double
    let memoryUsage: Int
    let activeEffectCount: Int
    let particleCount: Int
    let lightingMemoryUsage: Int
    let materialMemoryUsage: Int
}

enum VisualEffectsQuality {
    case low
    case medium
    case high
    case ultra
    
    var lightingQuality: LightingQuality {
        switch self {
        case .low: return .low
        case .medium: return .medium
        case .high: return .high
        case .ultra: return .ultra
        }
    }
    
    var materialQuality: MaterialRenderingQuality {
        switch self {
        case .low: return .low
        case .medium: return .medium
        case .high: return .high
        case .ultra: return .ultra
        }
    }
    
    var reflectionQuality: Int {
        switch self {
        case .low: return 2
        case .medium: return 4
        case .high: return 8
        case .ultra: return 16
        }
    }
    
    var maxParticleCount: Int {
        switch self {
        case .low: return 500
        case .medium: return 2000
        case .high: return 5000
        case .ultra: return 10000
        }
    }
}

// MARK: - Error Types

enum AdvancedVisualEffectsError: Error, LocalizedError {
    case libraryCreationFailed
    case bufferAllocationFailed
    case textureCreationFailed
    case pipelineStateCreationFailed
    case renderEncoderCreationFailed
    case computeEncoderCreationFailed
    
    var errorDescription: String? {
        switch self {
        case .libraryCreationFailed:
            return "Failed to create Metal library for advanced visual effects"
        case .bufferAllocationFailed:
            return "Failed to allocate visual effects buffers"
        case .textureCreationFailed:
            return "Failed to create visual effects textures"
        case .pipelineStateCreationFailed:
            return "Failed to create visual effects pipeline states"
        case .renderEncoderCreationFailed:
            return "Failed to create render encoder for visual effects"
        case .computeEncoderCreationFailed:
            return "Failed to create compute encoder for visual effects"
        }
    }
}