//
//  ProfessionalCardRenderer.swift
//  Septica
//
//  Enhanced Metal-based rendering system for ShuffleCats-quality card rendering
//  Provides professional depth, lighting, and material physics with Romanian cultural authenticity
//

#if canImport(Metal)
import Metal
import MetalKit
import MetalPerformanceShaders
#endif
import SwiftUI
import simd
import Combine

// MARK: - Professional Card Renderer

/// Advanced Metal-based card renderer providing ShuffleCats-quality visual effects
/// with Romanian cultural authenticity and premium material physics
@MainActor
class ProfessionalCardRenderer: ObservableObject {
    
    // MARK: - Core Metal Resources
    
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let library: MTLLibrary
    
    // MARK: - Enhanced Pipeline States
    
    private var cardPipelineState: MTLRenderPipelineState
    private var depthOnlyPipelineState: MTLRenderPipelineState
    private var shadowMapPipelineState: MTLRenderPipelineState
    private var materialEffectPipelineState: MTLRenderPipelineState
    private var culturalPatternPipelineState: MTLRenderPipelineState
    
    // MARK: - Advanced Resources
    
    private var depthStencilState: MTLDepthStencilState
    private var shadowDepthStencilState: MTLDepthStencilState
    private var samplerState: MTLSamplerState
    private var shadowSamplerState: MTLSamplerState
    
    // MARK: - Textures and Buffers
    
    private var shadowMapTexture: MTLTexture?
    private var materialPropertiesBuffer: MTLBuffer
    private var lightingBuffer: MTLBuffer
    private var transformBuffer: MTLBuffer
    private var cacheGeometryBuffer: MTLBuffer
    
    // MARK: - Performance Optimizations
    
    private let textureCache: TextureCache
    private let geometryCache: GeometryCache
    private let materialEffectSystem: MaterialEffectSystem
    
    // MARK: - Render Configuration
    
    @Published var renderQuality: RenderQuality = .high
    @Published var enableAdvancedLighting = true
    @Published var enableRomanianCulturalEffects = true
    @Published var enableMaterialPhysics = true
    @Published var performanceMode: PerformanceMode = .balanced
    
    // MARK: - Threading and Performance
    
    private let renderQueue = DispatchQueue(label: "com.septica.professional-renderer", qos: .userInteractive)
    private var frameCounter: Int = 0
    private var lastFrameTime: CFTimeInterval = 0
    private var currentFrameData: FrameData = FrameData()
    
    // MARK: - Error Handling
    
    weak var errorDelegate: ProfessionalRendererErrorDelegate?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(device: MTLDevice, commandQueue: MTLCommandQueue) throws {
        self.device = device
        self.commandQueue = commandQueue
        
        // Initialize library
        guard let library = device.makeDefaultLibrary() else {
            throw ProfessionalRendererError.libraryCreationFailed
        }
        self.library = library
        
        // Initialize caching systems
        self.textureCache = TextureCache(device: device)
        self.geometryCache = GeometryCache(device: device)
        self.materialEffectSystem = MaterialEffectSystem(device: device)
        
        // Create enhanced pipeline states
        self.cardPipelineState = try Self.createCardPipelineState(device: device, library: library)
        self.depthOnlyPipelineState = try Self.createDepthOnlyPipelineState(device: device, library: library)
        self.shadowMapPipelineState = try Self.createShadowMapPipelineState(device: device, library: library)
        self.materialEffectPipelineState = try Self.createMaterialEffectPipelineState(device: device, library: library)
        self.culturalPatternPipelineState = try Self.createCulturalPatternPipelineState(device: device, library: library)
        
        // Create depth stencil states
        self.depthStencilState = try Self.createDepthStencilState(device: device)
        self.shadowDepthStencilState = try Self.createShadowDepthStencilState(device: device)
        
        // Create sampler states
        self.samplerState = try Self.createSamplerState(device: device)
        self.shadowSamplerState = try Self.createShadowSamplerState(device: device)
        
        // Allocate buffers
        let bufferSize = MemoryLayout<MaterialProperties>.stride * 1024
        guard let materialBuffer = device.makeBuffer(length: bufferSize, options: [.storageModeShared]) else {
            throw ProfessionalRendererError.bufferAllocationFailed
        }
        self.materialPropertiesBuffer = materialBuffer
        materialBuffer.label = "MaterialPropertiesBuffer"
        
        let lightingBufferSize = MemoryLayout<LightingUniforms>.stride * 256
        guard let lightBuffer = device.makeBuffer(length: lightingBufferSize, options: [.storageModeShared]) else {
            throw ProfessionalRendererError.bufferAllocationFailed
        }
        self.lightingBuffer = lightBuffer
        lightBuffer.label = "LightingBuffer"
        
        let transformBufferSize = MemoryLayout<TransformUniforms>.stride * 2048
        guard let transformBuf = device.makeBuffer(length: transformBufferSize, options: [.storageModeShared]) else {
            throw ProfessionalRendererError.bufferAllocationFailed
        }
        self.transformBuffer = transformBuf
        transformBuf.label = "TransformBuffer"
        
        let cacheBufferSize = MemoryLayout<CachedGeometry>.stride * 512
        guard let cacheBuf = device.makeBuffer(length: cacheBufferSize, options: [.storageModeShared]) else {
            throw ProfessionalRendererError.bufferAllocationFailed
        }
        self.cacheGeometryBuffer = cacheBuf
        cacheBuf.label = "CacheGeometryBuffer"
        
        // Initialize shadow map texture
        self.shadowMapTexture = try Self.createShadowMapTexture(device: device)
        
        print("🎮 ProfessionalCardRenderer initialized successfully")
        print("   - Device: \(device.name)")
        print("   - Quality: \(renderQuality)")
        print("   - Advanced Lighting: \(enableAdvancedLighting)")
        print("   - Romanian Cultural Effects: \(enableRomanianCulturalEffects)")
        print("   - Material Physics: \(enableMaterialPhysics)")
    }
    
    // MARK: - Pipeline State Creation
    
    private static func createCardPipelineState(device: MTLDevice, library: MTLLibrary) throws -> MTLRenderPipelineState {
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.label = "ProfessionalCardPipeline"
        
        // Enhanced vertex and fragment shaders
        descriptor.vertexFunction = library.makeFunction(name: "professionalCardVertexShader")
        descriptor.fragmentFunction = library.makeFunction(name: "professionalCardFragmentShader")
        
        // Advanced vertex descriptor
        let vertexDescriptor = MTLVertexDescriptor()
        
        // Position (float3)
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        
        // Normal (float3)
        vertexDescriptor.attributes[1].format = .float3
        vertexDescriptor.attributes[1].offset = 12
        vertexDescriptor.attributes[1].bufferIndex = 0
        
        // Texture coordinates (float2)
        vertexDescriptor.attributes[2].format = .float2
        vertexDescriptor.attributes[2].offset = 24
        vertexDescriptor.attributes[2].bufferIndex = 0
        
        // Tangent (float3)
        vertexDescriptor.attributes[3].format = .float3
        vertexDescriptor.attributes[3].offset = 32
        vertexDescriptor.attributes[3].bufferIndex = 0
        
        // Cultural pattern UV (float2) - for Romanian motifs
        vertexDescriptor.attributes[4].format = .float2
        vertexDescriptor.attributes[4].offset = 44
        vertexDescriptor.attributes[4].bufferIndex = 0
        
        vertexDescriptor.layouts[0].stride = 52
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        
        descriptor.vertexDescriptor = vertexDescriptor
        
        // Color attachment configuration
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm_srgb
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        descriptor.colorAttachments[0].rgbBlendOperation = .add
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        descriptor.colorAttachments[0].alphaBlendOperation = .add
        
        // Depth attachment
        descriptor.depthAttachmentPixelFormat = .depth32Float
        descriptor.stencilAttachmentPixelFormat = .invalid
        
        return try device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    private static func createDepthOnlyPipelineState(device: MTLDevice, library: MTLLibrary) throws -> MTLRenderPipelineState {
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.label = "DepthOnlyPipeline"
        descriptor.vertexFunction = library.makeFunction(name: "depthOnlyVertexShader")
        descriptor.fragmentFunction = nil // Depth-only pass
        descriptor.depthAttachmentPixelFormat = .depth32Float
        descriptor.colorAttachments[0].pixelFormat = .invalid
        
        return try device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    private static func createShadowMapPipelineState(device: MTLDevice, library: MTLLibrary) throws -> MTLRenderPipelineState {
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.label = "ShadowMapPipeline"
        descriptor.vertexFunction = library.makeFunction(name: "shadowMapVertexShader")
        descriptor.fragmentFunction = library.makeFunction(name: "shadowMapFragmentShader")
        descriptor.depthAttachmentPixelFormat = .depth32Float
        descriptor.colorAttachments[0].pixelFormat = .invalid
        
        return try device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    private static func createMaterialEffectPipelineState(device: MTLDevice, library: MTLLibrary) throws -> MTLRenderPipelineState {
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.label = "MaterialEffectPipeline"
        descriptor.vertexFunction = library.makeFunction(name: "materialEffectVertexShader")
        descriptor.fragmentFunction = library.makeFunction(name: "materialEffectFragmentShader")
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm_srgb
        descriptor.depthAttachmentPixelFormat = .depth32Float
        
        return try device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    private static func createCulturalPatternPipelineState(device: MTLDevice, library: MTLLibrary) throws -> MTLRenderPipelineState {
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.label = "CulturalPatternPipeline"
        descriptor.vertexFunction = library.makeFunction(name: "culturalPatternVertexShader")
        descriptor.fragmentFunction = library.makeFunction(name: "culturalPatternFragmentShader")
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm_srgb
        descriptor.depthAttachmentPixelFormat = .depth32Float
        
        return try device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    // MARK: - State Creation Helpers
    
    private static func createDepthStencilState(device: MTLDevice) throws -> MTLDepthStencilState {
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.depthCompareFunction = .less
        descriptor.isDepthWriteEnabled = true
        descriptor.label = "MainDepthStencilState"
        
        guard let state = device.makeDepthStencilState(descriptor: descriptor) else {
            throw ProfessionalRendererError.depthStencilStateCreationFailed
        }
        return state
    }
    
    private static func createShadowDepthStencilState(device: MTLDevice) throws -> MTLDepthStencilState {
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.depthCompareFunction = .less
        descriptor.isDepthWriteEnabled = true
        descriptor.label = "ShadowDepthStencilState"
        
        guard let state = device.makeDepthStencilState(descriptor: descriptor) else {
            throw ProfessionalRendererError.depthStencilStateCreationFailed
        }
        return state
    }
    
    private static func createSamplerState(device: MTLDevice) throws -> MTLSamplerState {
        let descriptor = MTLSamplerDescriptor()
        descriptor.minFilter = .linear
        descriptor.magFilter = .linear
        descriptor.mipFilter = .linear
        descriptor.sAddressMode = .clampToEdge
        descriptor.tAddressMode = .clampToEdge
        descriptor.rAddressMode = .clampToEdge
        descriptor.maxAnisotropy = 8
        descriptor.label = "MainSamplerState"
        
        guard let state = device.makeSamplerState(descriptor: descriptor) else {
            throw ProfessionalRendererError.samplerStateCreationFailed
        }
        return state
    }
    
    private static func createShadowSamplerState(device: MTLDevice) throws -> MTLSamplerState {
        let descriptor = MTLSamplerDescriptor()
        descriptor.minFilter = .linear
        descriptor.magFilter = .linear
        descriptor.mipFilter = .notMipmapped
        descriptor.sAddressMode = .clampToZero
        descriptor.tAddressMode = .clampToZero
        descriptor.rAddressMode = .clampToZero
        descriptor.compareFunction = .less
        descriptor.label = "ShadowSamplerState"
        
        guard let state = device.makeSamplerState(descriptor: descriptor) else {
            throw ProfessionalRendererError.samplerStateCreationFailed
        }
        return state
    }
    
    private static func createShadowMapTexture(device: MTLDevice) throws -> MTLTexture {
        let descriptor = MTLTextureDescriptor()
        descriptor.textureType = .type2D
        descriptor.pixelFormat = .depth32Float
        descriptor.width = 2048  // High resolution shadow map
        descriptor.height = 2048
        descriptor.usage = [.renderTarget, .shaderRead]
        descriptor.storageMode = .private
        
        guard let texture = device.makeTexture(descriptor: descriptor) else {
            throw ProfessionalRendererError.textureCreationFailed
        }
        texture.label = "ShadowMapTexture"
        return texture
    }
    
    // MARK: - Rendering API
    
    /// Render a card with professional quality effects
    func renderCard(
        _ card: Card,
        transform: Advanced3DTransform,
        materialProperties: MaterialProperties,
        lightingEnvironment: LightingEnvironment,
        to renderTarget: MTLTexture,
        viewMatrix: matrix_float4x4,
        projectionMatrix: matrix_float4x4
    ) throws {
        
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            throw ProfessionalRendererError.commandBufferCreationFailed
        }
        commandBuffer.label = "ProfessionalCardRender"
        
        // Update frame data
        updateFrameData(
            card: card,
            transform: transform,
            materialProperties: materialProperties,
            lightingEnvironment: lightingEnvironment,
            viewMatrix: viewMatrix,
            projectionMatrix: projectionMatrix
        )
        
        // Shadow map pass (if advanced lighting is enabled)
        if enableAdvancedLighting {
            try renderShadowMapPass(commandBuffer: commandBuffer)
        }
        
        // Main card rendering pass
        try renderMainCardPass(
            commandBuffer: commandBuffer,
            card: card,
            renderTarget: renderTarget
        )
        
        // Material effects pass
        if enableMaterialPhysics {
            try renderMaterialEffectsPass(commandBuffer: commandBuffer, renderTarget: renderTarget)
        }
        
        // Romanian cultural pattern overlay
        if enableRomanianCulturalEffects {
            try renderCulturalPatternPass(commandBuffer: commandBuffer, card: card, renderTarget: renderTarget)
        }
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        // Update performance metrics
        updatePerformanceMetrics()
    }
    
    // MARK: - Render Passes
    
    private func renderShadowMapPass(commandBuffer: MTLCommandBuffer) throws {
        guard let shadowMapTexture = shadowMapTexture else { return }
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.depthAttachment.texture = shadowMapTexture
        renderPassDescriptor.depthAttachment.loadAction = .clear
        renderPassDescriptor.depthAttachment.storeAction = .store
        renderPassDescriptor.depthAttachment.clearDepth = 1.0
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            throw ProfessionalRendererError.renderEncoderCreationFailed
        }
        renderEncoder.label = "ShadowMapPass"
        
        renderEncoder.setRenderPipelineState(shadowMapPipelineState)
        renderEncoder.setDepthStencilState(shadowDepthStencilState)
        
        // Set shadow matrices and geometry
        renderEncoder.setVertexBuffer(transformBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(cacheGeometryBuffer, offset: 0, index: 1)
        
        // Render shadow-casting geometry
        let cachedGeometry = geometryCache.getCardGeometry(.romanian_traditional)
        renderEncoder.drawIndexedPrimitives(
            type: .triangle,
            indexCount: cachedGeometry.indexCount,
            indexType: cachedGeometry.indexType,
            indexBuffer: cachedGeometry.indexBuffer,
            indexBufferOffset: 0
        )
        
        renderEncoder.endEncoding()
    }
    
    private func renderMainCardPass(commandBuffer: MTLCommandBuffer, card: Card, renderTarget: MTLTexture) throws {
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = renderTarget
        renderPassDescriptor.colorAttachments[0].loadAction = .load
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        
        // Create depth texture if needed
        let depthTexture = try createDepthTexture(width: renderTarget.width, height: renderTarget.height)
        renderPassDescriptor.depthAttachment.texture = depthTexture
        renderPassDescriptor.depthAttachment.loadAction = .clear
        renderPassDescriptor.depthAttachment.storeAction = .dontCare
        renderPassDescriptor.depthAttachment.clearDepth = 1.0
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            throw ProfessionalRendererError.renderEncoderCreationFailed
        }
        renderEncoder.label = "MainCardPass"
        
        renderEncoder.setRenderPipelineState(cardPipelineState)
        renderEncoder.setDepthStencilState(depthStencilState)
        
        // Set buffers
        renderEncoder.setVertexBuffer(transformBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(materialPropertiesBuffer, offset: 0, index: 1)
        renderEncoder.setVertexBuffer(lightingBuffer, offset: 0, index: 2)
        
        renderEncoder.setFragmentBuffer(materialPropertiesBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentBuffer(lightingBuffer, offset: 0, index: 1)
        
        // Set textures
        let cardTexture = try textureCache.getCardTexture(for: card)
        renderEncoder.setFragmentTexture(cardTexture, index: 0)
        
        if let shadowMapTexture = shadowMapTexture {
            renderEncoder.setFragmentTexture(shadowMapTexture, index: 1)
        }
        
        let normalMapTexture = try textureCache.getNormalMapTexture(for: card)
        renderEncoder.setFragmentTexture(normalMapTexture, index: 2)
        
        // Set samplers
        renderEncoder.setFragmentSamplerState(samplerState, index: 0)
        renderEncoder.setFragmentSamplerState(shadowSamplerState, index: 1)
        
        // Render card geometry
        let cachedGeometry = geometryCache.getCardGeometry(.romanian_traditional)
        renderEncoder.drawIndexedPrimitives(
            type: .triangle,
            indexCount: cachedGeometry.indexCount,
            indexType: cachedGeometry.indexType,
            indexBuffer: cachedGeometry.indexBuffer,
            indexBufferOffset: 0
        )
        
        renderEncoder.endEncoding()
    }
    
    private func renderMaterialEffectsPass(commandBuffer: MTLCommandBuffer, renderTarget: MTLTexture) throws {
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = renderTarget
        renderPassDescriptor.colorAttachments[0].loadAction = .load
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            throw ProfessionalRendererError.renderEncoderCreationFailed
        }
        renderEncoder.label = "MaterialEffectsPass"
        
        renderEncoder.setRenderPipelineState(materialEffectPipelineState)
        
        // Render material effects (reflections, refractions, etc.)
        materialEffectSystem.renderEffects(renderEncoder: renderEncoder, currentFrameData: currentFrameData)
        
        renderEncoder.endEncoding()
    }
    
    private func renderCulturalPatternPass(commandBuffer: MTLCommandBuffer, card: Card, renderTarget: MTLTexture) throws {
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = renderTarget
        renderPassDescriptor.colorAttachments[0].loadAction = .load
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            throw ProfessionalRendererError.renderEncoderCreationFailed
        }
        renderEncoder.label = "CulturalPatternPass"
        
        renderEncoder.setRenderPipelineState(culturalPatternPipelineState)
        
        // Render Romanian cultural patterns based on card type
        let culturalTexture = try textureCache.getRomanianPatternTexture(for: card)
        renderEncoder.setFragmentTexture(culturalTexture, index: 0)
        renderEncoder.setFragmentSamplerState(samplerState, index: 0)
        
        // Render pattern overlay geometry
        let patternGeometry = geometryCache.getCulturalPatternGeometry(for: card)
        renderEncoder.drawIndexedPrimitives(
            type: .triangle,
            indexCount: patternGeometry.indexCount,
            indexType: patternGeometry.indexType,
            indexBuffer: patternGeometry.indexBuffer,
            indexBufferOffset: 0
        )
        
        renderEncoder.endEncoding()
    }
    
    // MARK: - Helper Methods
    
    private func createDepthTexture(width: Int, height: Int) throws -> MTLTexture {
        let descriptor = MTLTextureDescriptor()
        descriptor.textureType = .type2D
        descriptor.pixelFormat = .depth32Float
        descriptor.width = width
        descriptor.height = height
        descriptor.usage = .renderTarget
        descriptor.storageMode = .private
        
        guard let texture = device.makeTexture(descriptor: descriptor) else {
            throw ProfessionalRendererError.textureCreationFailed
        }
        texture.label = "DepthTexture"
        return texture
    }
    
    private func updateFrameData(
        card: Card,
        transform: Advanced3DTransform,
        materialProperties: MaterialProperties,
        lightingEnvironment: LightingEnvironment,
        viewMatrix: matrix_float4x4,
        projectionMatrix: matrix_float4x4
    ) {
        currentFrameData.card = card
        currentFrameData.transform = transform
        currentFrameData.materialProperties = materialProperties
        currentFrameData.lightingEnvironment = lightingEnvironment
        currentFrameData.viewMatrix = viewMatrix
        currentFrameData.projectionMatrix = projectionMatrix
        currentFrameData.timestamp = CACurrentMediaTime()
        
        // Update GPU buffers
        updateTransformBuffer()
        updateMaterialBuffer()
        updateLightingBuffer()
    }
    
    private func updateTransformBuffer() {
        let transformPtr = transformBuffer.contents().bindMemory(to: TransformUniforms.self, capacity: 1)
        
        let modelMatrix = currentFrameData.transform.modelMatrix
        let viewMatrix = currentFrameData.viewMatrix
        let projectionMatrix = currentFrameData.projectionMatrix
        
        transformPtr.pointee = TransformUniforms(
            modelMatrix: modelMatrix,
            viewMatrix: viewMatrix,
            projectionMatrix: projectionMatrix,
            modelViewMatrix: simd_mul(viewMatrix, modelMatrix),
            modelViewProjectionMatrix: simd_mul(projectionMatrix, simd_mul(viewMatrix, modelMatrix)),
            normalMatrix: matrix3x3_from_matrix4x4(modelMatrix).matrixTranspose.matrixInverse
        )
    }
    
    private func updateMaterialBuffer() {
        let materialPtr = materialPropertiesBuffer.contents().bindMemory(to: MaterialProperties.self, capacity: 1)
        materialPtr.pointee = currentFrameData.materialProperties
    }
    
    private func updateLightingBuffer() {
        let lightingPtr = lightingBuffer.contents().bindMemory(to: LightingUniforms.self, capacity: 1)
        
        let environment = currentFrameData.lightingEnvironment
        lightingPtr.pointee = LightingUniforms(
            lightDirection: environment.primaryLightDirection,
            lightColor: environment.primaryLightColor,
            ambientColor: environment.ambientLightColor,
            lightIntensity: environment.lightIntensity,
            shadowBias: environment.shadowBias,
            romanianCulturalTint: environment.romanianCulturalTint
        )
    }
    
    private func updatePerformanceMetrics() {
        frameCounter += 1
        let currentTime = CACurrentMediaTime()
        
        if lastFrameTime > 0 {
            _ = currentTime - lastFrameTime
            // Update performance metrics for battery optimization
        }
        
        lastFrameTime = currentTime
    }
}

// MARK: - Supporting Types

struct FrameData {
    var card: Card?
    var transform: Advanced3DTransform = Advanced3DTransform()
    var materialProperties: MaterialProperties = MaterialProperties()
    var lightingEnvironment: LightingEnvironment = LightingEnvironment()
    var viewMatrix: matrix_float4x4 = matrix_identity_float4x4
    var projectionMatrix: matrix_float4x4 = matrix_identity_float4x4
    var timestamp: CFTimeInterval = 0
}

struct TransformUniforms {
    let modelMatrix: matrix_float4x4
    let viewMatrix: matrix_float4x4
    let projectionMatrix: matrix_float4x4
    let modelViewMatrix: matrix_float4x4
    let modelViewProjectionMatrix: matrix_float4x4
    let normalMatrix: matrix_float3x3
}

struct LightingUniforms {
    let lightDirection: simd_float3
    let lightColor: simd_float3
    let ambientColor: simd_float3
    let lightIntensity: Float
    let shadowBias: Float
    let romanianCulturalTint: simd_float3
}

struct LightingEnvironment {
    var primaryLightDirection: simd_float3 = simd_float3(0.5, -0.8, 0.3)
    var primaryLightColor: simd_float3 = simd_float3(1.0, 0.95, 0.8)
    var ambientLightColor: simd_float3 = simd_float3(0.3, 0.3, 0.4)
    var lightIntensity: Float = 1.0
    var shadowBias: Float = 0.001
    var romanianCulturalTint: simd_float3 = simd_float3(1.0, 0.85, 0.4) // Warm cultural lighting
}

// Note: PerformanceMode is defined in AdvancedEffectsIntegration.swift

// MARK: - Error Types

enum ProfessionalRendererError: Error, LocalizedError {
    case libraryCreationFailed
    case pipelineStateCreationFailed
    case depthStencilStateCreationFailed
    case samplerStateCreationFailed
    case textureCreationFailed
    case bufferAllocationFailed
    case commandBufferCreationFailed
    case renderEncoderCreationFailed
    
    var errorDescription: String? {
        switch self {
        case .libraryCreationFailed:
            return "Failed to create Metal library"
        case .pipelineStateCreationFailed:
            return "Failed to create render pipeline state"
        case .depthStencilStateCreationFailed:
            return "Failed to create depth stencil state"
        case .samplerStateCreationFailed:
            return "Failed to create sampler state"
        case .textureCreationFailed:
            return "Failed to create texture"
        case .bufferAllocationFailed:
            return "Failed to allocate Metal buffer"
        case .commandBufferCreationFailed:
            return "Failed to create command buffer"
        case .renderEncoderCreationFailed:
            return "Failed to create render encoder"
        }
    }
}

protocol ProfessionalRendererErrorDelegate: AnyObject {
    func rendererDidEncounterError(_ error: ProfessionalRendererError)
    func rendererDidRecoverFromError()
}

// MARK: - Matrix Utilities

func matrix3x3_from_matrix4x4(_ matrix: matrix_float4x4) -> matrix_float3x3 {
    let m = matrix.columns
    return matrix_float3x3(
        simd_float3(m.0.x, m.0.y, m.0.z),
        simd_float3(m.1.x, m.1.y, m.1.z),
        simd_float3(m.2.x, m.2.y, m.2.z)
    )
}

extension matrix_float3x3 {
    var matrixTranspose: matrix_float3x3 {
        return simd_transpose(self)
    }
    
    var matrixInverse: matrix_float3x3 {
        return simd_inverse(self)
    }
}