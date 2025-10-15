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
    
    let device: MTLDevice  // Public access for ProfessionalCardView
    private let commandQueue: MTLCommandQueue
    private let library: MTLLibrary
    
    // MARK: - Enhanced Pipeline States

    private var cardPipelineState: MTLRenderPipelineState
    private var depthOnlyPipelineState: MTLRenderPipelineState
    private var shadowMapPipelineState: MTLRenderPipelineState
    private var materialEffectPipelineState: MTLRenderPipelineState
    private var culturalPatternPipelineState: MTLRenderPipelineState
    private var edgeHighlightingPipelineState: MTLRenderPipelineState
    
    // MARK: - Advanced Resources
    
    private var depthStencilState: MTLDepthStencilState
    private var shadowDepthStencilState: MTLDepthStencilState
    private var samplerState: MTLSamplerState
    private var shadowSamplerState: MTLSamplerState

    /// Reusable depth textures grouped by render target size, triple buffered to keep GPU busy without reallocating
    private var depthTexturePools: [DepthTextureKey: DepthTexturePool] = [:]
    
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
    
    // MARK: - Phase 2 Advanced Systems
    
    private var advancedLightingSystem: AdvancedLightingSystem?
    private var enhancedMaterialSystem: EnhancedMaterialSystem?
    private var advancedVisualEffectsIntegration: AdvancedVisualEffectsIntegration?
    
    // MARK: - Render Configuration
    
    @Published var renderQuality: RenderQuality = .high
    @Published var enableAdvancedLighting = true
    @Published var enableRomanianCulturalEffects = true
    @Published var enableMaterialPhysics = true
    @Published var performanceMode: PerformanceMode = .balanced
    
    // MARK: - Phase 2 Configuration
    
    @Published var enableEnhancedMaterials = true
    @Published var enableAdvancedVisualEffects = true
    @Published var phase2QualityLevel: Phase2QualityLevel = .high
    
    // MARK: - Threading and Performance
    
    private let renderQueue = DispatchQueue(label: "com.septica.professional-renderer", qos: .userInteractive)
    private var frameCounter: Int = 0
    private var lastFrameTime: CFTimeInterval = 0
    private var currentFrameData: FrameData = FrameData()
    
    // MARK: - Error Handling
    
    weak var errorDelegate: ProfessionalRendererErrorDelegate?
    private var cancellables = Set<AnyCancellable>()

    private struct DepthTextureKey: Hashable {
        let width: Int
        let height: Int
    }

    private struct DepthTexturePool {
        var textures: [MTLTexture]
        var cursor: Int = 0

        mutating func nextTexture() -> MTLTexture? {
            guard !textures.isEmpty else { return nil }
            let texture = textures[cursor % textures.count]
            cursor = (cursor + 1) % textures.count
            return texture
        }
    }
    
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
        self.edgeHighlightingPipelineState = try Self.createEdgeHighlightingPipelineState(device: device, library: library)
        
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
        
        // Initialize Phase 2 Advanced Systems
        try initializePhase2Systems()
        
        print("🎮 ProfessionalCardRenderer initialized successfully")
        print("   - Device: \(device.name)")
        print("   - Quality: \(renderQuality)")
        print("   - Advanced Lighting: \(enableAdvancedLighting)")
        print("   - Romanian Cultural Effects: \(enableRomanianCulturalEffects)")
        print("   - Material Physics: \(enableMaterialPhysics)")
        print("   - Phase 2 Advanced Systems: ✅")
        print("   - Phase 2 Quality Level: \(phase2QualityLevel)")
    }
    
    // MARK: - Phase 2 System Initialization
    
    private func initializePhase2Systems() throws {
        // Initialize Advanced Lighting System
        if enableAdvancedLighting {
            do {
                advancedLightingSystem = try AdvancedLightingSystem(device: device, commandQueue: commandQueue)
                print("✅ Advanced Lighting System initialized")
            } catch {
                print("⚠️ Failed to initialize Advanced Lighting System: \(error)")
                enableAdvancedLighting = false
            }
        }
        
        // Initialize Enhanced Material System
        if enableEnhancedMaterials {
            do {
                enhancedMaterialSystem = try EnhancedMaterialSystem(
                    device: device,
                    materialEffectSystem: materialEffectSystem,
                    advancedLightingSystem: advancedLightingSystem!
                )
                print("✅ Enhanced Material System initialized")
            } catch {
                print("⚠️ Failed to initialize Enhanced Material System: \(error)")
                enableEnhancedMaterials = false
            }
        }
        
        // Initialize Advanced Visual Effects Integration
        if enableAdvancedVisualEffects {
            do {
                advancedVisualEffectsIntegration = try AdvancedVisualEffectsIntegration(
                    device: device,
                    commandQueue: commandQueue
                )
                print("✅ Advanced Visual Effects Integration initialized")
            } catch {
                print("⚠️ Failed to initialize Advanced Visual Effects Integration: \(error)")
                enableAdvancedVisualEffects = false
            }
        }
        
        // Configure quality levels
        configurePhase2QualityLevels()
    }
    
    private func configurePhase2QualityLevels() {
        let visualEffectsQuality = phase2QualityLevel.visualEffectsQuality
        
        advancedLightingSystem?.setLightingQuality(visualEffectsQuality.lightingQuality)
        enhancedMaterialSystem?.setMaterialQuality(visualEffectsQuality.materialQuality)
        advancedVisualEffectsIntegration?.setVisualEffectsQuality(visualEffectsQuality)
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

        // Edge UV (float2) - for edge highlighting
        vertexDescriptor.attributes[5].format = .float2
        vertexDescriptor.attributes[5].offset = 52
        vertexDescriptor.attributes[5].bufferIndex = 0

        // Thickness (float) - for depth effects
        vertexDescriptor.attributes[6].format = .float
        vertexDescriptor.attributes[6].offset = 60
        vertexDescriptor.attributes[6].bufferIndex = 0

        vertexDescriptor.layouts[0].stride = 64
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

    private static func createEdgeHighlightingPipelineState(device: MTLDevice, library: MTLLibrary) throws -> MTLRenderPipelineState {
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.label = "EdgeHighlightingPipeline"
        descriptor.vertexFunction = library.makeFunction(name: "edgeHighlightingVertexShader")
        descriptor.fragmentFunction = library.makeFunction(name: "edgeHighlightingFragmentShader")

        // Enhanced vertex descriptor for edge highlighting
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

        // Cultural pattern UV (float2)
        vertexDescriptor.attributes[4].format = .float2
        vertexDescriptor.attributes[4].offset = 44
        vertexDescriptor.attributes[4].bufferIndex = 0

        // Edge UV (float2) - for edge highlighting
        vertexDescriptor.attributes[5].format = .float2
        vertexDescriptor.attributes[5].offset = 52
        vertexDescriptor.attributes[5].bufferIndex = 0

        // Thickness (float)
        vertexDescriptor.attributes[6].format = .float
        vertexDescriptor.attributes[6].offset = 60
        vertexDescriptor.attributes[6].bufferIndex = 0

        vertexDescriptor.layouts[0].stride = 64
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = .perVertex

        descriptor.vertexDescriptor = vertexDescriptor

        // Color attachment configuration with additive blending for glow
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm_srgb
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .one
        descriptor.colorAttachments[0].rgbBlendOperation = .add
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        descriptor.colorAttachments[0].alphaBlendOperation = .add

        // Depth attachment
        descriptor.depthAttachmentPixelFormat = .depth32Float
        descriptor.stencilAttachmentPixelFormat = .invalid

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
        descriptor.textureType = .type2DArray
        descriptor.pixelFormat = .depth32Float
        descriptor.width = 4096  // Ultra high resolution shadow map for premium quality
        descriptor.height = 4096
        descriptor.arrayLength = 4  // Cascaded shadow maps
        descriptor.usage = [.renderTarget, .shaderRead]
        descriptor.storageMode = .private

        guard let texture = device.makeTexture(descriptor: descriptor) else {
            throw ProfessionalRendererError.textureCreationFailed
        }
        texture.label = "EnhancedShadowMapTexture"
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
        attachCompletionHandler(to: commandBuffer)
        
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

        // Edge highlighting pass for premium visual quality
        try renderEdgeHighlightingPass(commandBuffer: commandBuffer, card: card, renderTarget: renderTarget)

        commandBuffer.commit()
    }
    
    /// Enhanced card rendering with Phase 2 advanced systems
    func renderCardWithAdvancedEffects(
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
        commandBuffer.label = "AdvancedCardRender"
        attachCompletionHandler(to: commandBuffer)
        
        // Update frame data
        updateFrameData(
            card: card,
            transform: transform,
            materialProperties: materialProperties,
            lightingEnvironment: lightingEnvironment,
            viewMatrix: viewMatrix,
            projectionMatrix: projectionMatrix
        )
        
        // Create scene rendering data for Phase 2 systems
        let sceneData = SceneRenderingData(
            colorTarget: renderTarget,
            depthTarget: try depthTexture(for: renderTarget.width, height: renderTarget.height),
            cardGeometries: [createCardGeometry(for: card)],
            viewMatrix: viewMatrix,
            projectionMatrix: projectionMatrix
        )
        
        // Phase 2: Use Advanced Visual Effects Integration if available
        if enableAdvancedVisualEffects, let advancedEffects = advancedVisualEffectsIntegration {
            try advancedEffects.renderAdvancedVisualEffects(
                commandBuffer: commandBuffer,
                sceneData: sceneData,
                cards: [card],
                lightingEnvironment: lightingEnvironment
            )
        } else {
            // Fallback to Phase 1 rendering
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
        }
        
        commandBuffer.commit()
    }
    
    private func createCardGeometry(for card: Card) -> CardGeometryData {
        let cachedGeometry = geometryCache.getCardGeometry(.romanian_traditional)
        
        return CardGeometryData(
            vertexBuffer: cachedGeometry.vertexBuffer,
            indexBuffer: cachedGeometry.indexBuffer,
            indexCount: cachedGeometry.indexCount,
            indexType: cachedGeometry.indexType
        )
    }
    
    // MARK: - Render Passes
    
    private func renderShadowMapPass(commandBuffer: MTLCommandBuffer) throws {
        guard let shadowMapTexture = shadowMapTexture else { return }

        // Enhanced cascaded shadow map rendering
        let shadowCascades = 4
        let shadowDistances: [Float] = [0.1, 2.0, 8.0, 25.0]

        for cascade in 0..<shadowCascades {
            let renderPassDescriptor = MTLRenderPassDescriptor()
            renderPassDescriptor.depthAttachment.texture = shadowMapTexture
            renderPassDescriptor.depthAttachment.slice = cascade
            renderPassDescriptor.depthAttachment.loadAction = cascade == 0 ? .clear : .load
            renderPassDescriptor.depthAttachment.storeAction = .store
            renderPassDescriptor.depthAttachment.clearDepth = 1.0

            guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
                throw ProfessionalRendererError.renderEncoderCreationFailed
            }
            renderEncoder.label = "ShadowMapPass_Cascade\(cascade)"

            renderEncoder.setRenderPipelineState(shadowMapPipelineState)
            renderEncoder.setDepthStencilState(shadowDepthStencilState)

            // Set enhanced shadow matrices for this cascade
            var shadowMatrix = calculateShadowMatrixForCascade(cascade, distance: shadowDistances[cascade])
            renderEncoder.setVertexBytes(&shadowMatrix, length: MemoryLayout<matrix_float4x4>.stride, index: 1)

            // Set geometry
            renderEncoder.setVertexBuffer(transformBuffer, offset: 0, index: 0)
            renderEncoder.setVertexBuffer(cacheGeometryBuffer, offset: 0, index: 1)

            // Render shadow-casting geometry with enhanced detail
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
    }

    private func calculateShadowMatrixForCascade(_ cascade: Int, distance: Float) -> matrix_float4x4 {
        // Calculate light view matrix
        let lightPosition = simd_float3(5, 10, 5)
        let lightTarget = simd_float3(0, 0, 0)
        let lightUp = simd_float3(0, 1, 0)
        let lightViewMatrix = lookAt(eye: lightPosition, center: lightTarget, up: lightUp)

        // Calculate orthographic projection for this cascade
        let cascadeSize = distance * 2.0
        let aspectRatio: Float = 1.0
        let left = -cascadeSize * aspectRatio / 2.0
        let right = cascadeSize * aspectRatio / 2.0
        let bottom = -cascadeSize / 2.0
        let top = cascadeSize / 2.0
        let near: Float = 0.1
        let far: Float = distance * 2.0

        let lightProjectionMatrix = orthographic(left: left, right: right, bottom: bottom, top: top, near: near, far: far)

        return simd_mul(lightProjectionMatrix, lightViewMatrix)
    }

    private func orthographic(left: Float, right: Float, bottom: Float, top: Float, near: Float, far: Float) -> matrix_float4x4 {
        let tx = -(left + right) / (right - left)
        let ty = -(top + bottom) / (top - bottom)
        let tz = near / (far - near)

        return matrix_float4x4(
            simd_float4(2.0 / (right - left), 0, 0, 0),
            simd_float4(0, 2.0 / (top - bottom), 0, 0),
            simd_float4(0, 0, 1.0 / (far - near), 0),
            simd_float4(tx, ty, tz, 1)
        )
    }
    
    private func renderMainCardPass(commandBuffer: MTLCommandBuffer, card: Card, renderTarget: MTLTexture) throws {
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = renderTarget
        renderPassDescriptor.colorAttachments[0].loadAction = .load
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        
        // Create depth texture if needed
        let depthTexture = try depthTexture(for: renderTarget.width, height: renderTarget.height)
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
        
        // Set enhanced textures for premium rendering
        let cardTexture = try textureCache.getCardTexture(for: card)
        renderEncoder.setFragmentTexture(cardTexture, index: 0)

        if let shadowMapTexture = shadowMapTexture {
            renderEncoder.setFragmentTexture(shadowMapTexture, index: 1)
        }

        let normalMapTexture = try textureCache.getNormalMapTexture(for: card)
        renderEncoder.setFragmentTexture(normalMapTexture, index: 2)

        // Add Romanian cultural pattern texture for enhanced depth
        let culturalTexture = try textureCache.getRomanianPatternTexture(for: card)
        renderEncoder.setFragmentTexture(culturalTexture, index: 3)

        // Set enhanced samplers with different filtering for shadow maps
        renderEncoder.setFragmentSamplerState(samplerState, index: 0)
        renderEncoder.setFragmentSamplerState(shadowSamplerState, index: 1)

        // Set shadow uniforms for cascaded shadow mapping
        var shadowUniforms = EnhancedShadowUniforms(
            shadowMatrices: [
                calculateShadowMatrixForCascade(0, distance: 0.1),
                calculateShadowMatrixForCascade(1, distance: 2.0),
                calculateShadowMatrixForCascade(2, distance: 8.0),
                calculateShadowMatrixForCascade(3, distance: 25.0)
            ],
            shadowCascadeDistances: simd_float4(0.1, 2.0, 8.0, 25.0),
            shadowBias: 0.002,
            contactShadowStrength: 0.8,
            shadowSoftness: 1.2
        )

        renderEncoder.setFragmentBytes(&shadowUniforms, length: MemoryLayout<EnhancedShadowUniforms>.stride, index: 2)
        
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

    private func renderEdgeHighlightingPass(commandBuffer: MTLCommandBuffer, card: Card, renderTarget: MTLTexture) throws {
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = renderTarget
        renderPassDescriptor.colorAttachments[0].loadAction = .load
        renderPassDescriptor.colorAttachments[0].storeAction = .store

        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            throw ProfessionalRendererError.renderEncoderCreationFailed
        }
        renderEncoder.label = "EdgeHighlightingPass"

        renderEncoder.setRenderPipelineState(edgeHighlightingPipelineState)

        // Set edge highlighting uniforms
        var edgeHighlightingUniforms = EdgeHighlightingUniforms(
            edgeColor: determineEdgeColor(for: card),
            edgeIntensity: determineEdgeIntensity(for: card),
            edgeWidth: 0.02,
            glowIntensity: card.isSpecialCard ? 1.2 : 0.8,
            pulseFrequency: card.value == 7 ? 3.0 : 0.0,
            time: Float(CACurrentMediaTime())
        )

        renderEncoder.setFragmentBytes(&edgeHighlightingUniforms, length: MemoryLayout<EdgeHighlightingUniforms>.stride, index: 0)

        // Set card geometry
        let cardGeometry = createCardGeometry(for: card)
        renderEncoder.setVertexBuffer(cardGeometry.vertexBuffer, offset: 0, index: 0)
        renderEncoder.drawIndexedPrimitives(
            type: .triangle,
            indexCount: cardGeometry.indexCount,
            indexType: cardGeometry.indexType,
            indexBuffer: cardGeometry.indexBuffer,
            indexBufferOffset: 0
        )

        renderEncoder.endEncoding()
    }

    private func determineEdgeColor(for card: Card) -> simd_float3 {
        if card.value == 7 {
            return simd_float3(0.9, 0.8, 1.0) // Mystical blue-white for sevens
        } else if card.isPointCard {
            return RomanianColors.goldAccent.toSIMD3() // Gold for point cards
        } else if card.suit == .hearts {
            return RomanianColors.embroideryRed.toSIMD3() // Red for hearts
        } else if card.suit == .diamonds {
            return RomanianColors.folkBlue.toSIMD3() // Blue for diamonds
        } else {
            return simd_float3(0.7, 0.7, 0.7) // Silver for regular cards
        }
    }

    private func determineEdgeIntensity(for card: Card) -> Float {
        if card.value == 7 {
            return 1.0 // Maximum intensity for special sevens
        } else if card.isPointCard {
            return 0.8 // High intensity for point cards
        } else {
            return 0.4 // Subtle intensity for regular cards
        }
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

    private func depthTexture(for width: Int, height: Int) throws -> MTLTexture {
        let key = DepthTextureKey(width: width, height: height)
        var pool = depthTexturePools[key] ?? DepthTexturePool(textures: [])

        if pool.textures.count < 3 {
            let texture = try createDepthTexture(width: width, height: height)
            pool.textures.append(texture)
        }

        guard let texture = pool.nextTexture() else {
            // Fallback: generate one more texture if pool was empty for some reason
            let texture = try createDepthTexture(width: width, height: height)
            pool.textures = [texture]
            depthTexturePools[key] = pool
            return texture
        }

        depthTexturePools[key] = pool
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
    
    private func attachCompletionHandler(to commandBuffer: MTLCommandBuffer) {
        commandBuffer.addCompletedHandler { [weak self] buffer in
            guard let self else { return }
            Task { @MainActor in
                if buffer.status == .error {
                    if let error = buffer.error {
                        print("⚠️ Professional renderer command buffer error: \(error.localizedDescription)")
                    }
                    self.errorDelegate?.rendererDidEncounterError(.commandBufferExecutionFailed)
                } else {
                    self.errorDelegate?.rendererDidRecoverFromError()
                }
                self.updatePerformanceMetrics()
            }
        }
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
    case commandBufferExecutionFailed
    
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
        case .commandBufferExecutionFailed:
            return "Command buffer execution failed"
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

// MARK: - Phase 2 Configuration Types

enum Phase2QualityLevel {
    case low
    case medium
    case high
    case ultra
    
    var visualEffectsQuality: VisualEffectsQuality {
        switch self {
        case .low: return .low
        case .medium: return .medium
        case .high: return .high
        case .ultra: return .ultra
        }
    }
    
    var description: String {
        switch self {
        case .low:
            return "Low - Basic visual effects, optimized for performance"
        case .medium:
            return "Medium - Balanced visual quality and performance"
        case .high:
            return "High - Advanced visual effects with good performance"
        case .ultra:
            return "Ultra - Maximum visual quality, premium devices only"
        }
    }
}

// MARK: - Phase 2 Configuration Extensions

extension ProfessionalCardRenderer {
    
    /// Configure Phase 2 quality level
    func setPhase2QualityLevel(_ level: Phase2QualityLevel) {
        phase2QualityLevel = level
        configurePhase2QualityLevels()
        objectWillChange.send()
    }
    
    /// Configure advanced lighting settings
    func configureAdvancedLighting(
        enableGlobalIllumination: Bool = true,
        enableLightBouncing: Bool = true,
        enableCascadedShadows: Bool = true,
        romanianWarmth: Float = 0.8,
        goldenHour: Float = 0.6
    ) {
        advancedLightingSystem?.enableGlobalIllumination = enableGlobalIllumination
        advancedLightingSystem?.enableLightBouncing = enableLightBouncing
        advancedLightingSystem?.enableCascadedShadows = enableCascadedShadows
        advancedLightingSystem?.configureRomanianLighting(warmth: romanianWarmth, goldenHour: goldenHour)
        
        objectWillChange.send()
    }
    
    /// Configure enhanced materials
    func configureEnhancedMaterials(
        enablePBR: Bool = true,
        enableSubsurfaceScattering: Bool = true,
        enableRomanianCultural: Bool = true,
        metallicFactor: Float = 1.0,
        roughnessFactor: Float = 1.0,
        culturalIntensity: Float = 1.0
    ) {
        enhancedMaterialSystem?.enablePBRMaterials = enablePBR
        enhancedMaterialSystem?.enableSubsurfaceScattering = enableSubsurfaceScattering
        enhancedMaterialSystem?.enableRomanianCulturalMaterials = enableRomanianCultural
        enhancedMaterialSystem?.configureGlobalMaterialFactors(
            metallic: metallicFactor,
            roughness: roughnessFactor,
            cultural: culturalIntensity
        )
        
        objectWillChange.send()
    }
    
    /// Configure advanced visual effects
    func configureAdvancedVisualEffects(
        enableReflections: Bool = true,
        enableRefractions: Bool = true,
        enableShimmer: Bool = true,
        enableCulturalGlow: Bool = true,
        enableParticles: Bool = true,
        globalIntensity: Float = 1.0
    ) {
        advancedVisualEffectsIntegration?.enableAdvancedReflections = enableReflections
        advancedVisualEffectsIntegration?.enableRefractions = enableRefractions
        advancedVisualEffectsIntegration?.enableShimmerEffects = enableShimmer
        advancedVisualEffectsIntegration?.enableCulturalGlow = enableCulturalGlow
        advancedVisualEffectsIntegration?.enableParticleEffects = enableParticles
        
        advancedVisualEffectsIntegration?.configureEffectIntensities(
            global: globalIntensity,
            reflection: 0.8,
            refraction: 0.6,
            shimmer: 0.7,
            cultural: 0.9,
            particle: 0.8
        )
        
        objectWillChange.send()
    }
    
    /// Get comprehensive Phase 2 performance metrics
    func getPhase2Metrics() -> Phase2Metrics? {
        guard let advancedEffects = advancedVisualEffectsIntegration else { return nil }
        
        let comprehensiveMetrics = advancedEffects.getComprehensiveMetrics()
        
        return Phase2Metrics(
            totalRenderTime: comprehensiveMetrics.totalRenderTime,
            lightingRenderTime: comprehensiveMetrics.lightingRenderTime,
            materialRenderTime: comprehensiveMetrics.materialRenderTime,
            effectsRenderTime: comprehensiveMetrics.effectsRenderTime,
            totalMemoryUsage: comprehensiveMetrics.memoryUsage + comprehensiveMetrics.lightingMemoryUsage + comprehensiveMetrics.materialMemoryUsage,
            activeEffectCount: comprehensiveMetrics.activeEffectCount,
            particleCount: comprehensiveMetrics.particleCount,
            qualityLevel: phase2QualityLevel,
            systemsEnabled: Phase2SystemStatus(
                advancedLighting: enableAdvancedLighting && advancedLightingSystem != nil,
                enhancedMaterials: enableEnhancedMaterials && enhancedMaterialSystem != nil,
                advancedVisualEffects: enableAdvancedVisualEffects && advancedVisualEffectsIntegration != nil
            )
        )
    }
}

struct Phase2Metrics {
    let totalRenderTime: Double
    let lightingRenderTime: Double
    let materialRenderTime: Double
    let effectsRenderTime: Double
    let totalMemoryUsage: Int
    let activeEffectCount: Int
    let particleCount: Int
    let qualityLevel: Phase2QualityLevel
    let systemsEnabled: Phase2SystemStatus
}

struct Phase2SystemStatus {
    let advancedLighting: Bool
    let enhancedMaterials: Bool
    let advancedVisualEffects: Bool

    var allSystemsEnabled: Bool {
        return advancedLighting && enhancedMaterials && advancedVisualEffects
    }

    var enabledSystemsCount: Int {
        return (advancedLighting ? 1 : 0) + (enhancedMaterials ? 1 : 0) + (advancedVisualEffects ? 1 : 0)
    }
}

struct EdgeHighlightingUniforms {
    let edgeColor: simd_float3
    let edgeIntensity: Float
    let edgeWidth: Float
    let glowIntensity: Float
    let pulseFrequency: Float
    let time: Float
}

struct EnhancedShadowUniforms {
    let shadowMatrices: [matrix_float4x4]
    let shadowCascadeDistances: simd_float4
    let shadowBias: Float
    let contactShadowStrength: Float
    let shadowSoftness: Float
}
