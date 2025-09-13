//
//  Renderer.swift
//  Septica
//
//  Created by Bogdan Veliscu on 12.09.2025.
//

// Our platform independent renderer class

import Metal
import MetalKit
import simd
import SwiftUI
import Combine

// The 256 byte aligned size of our uniform structure
let alignedUniformsSize = (MemoryLayout<Uniforms>.size + 0xFF) & -0x100
let alignedCardUniformsSize = (MemoryLayout<CardUniforms>.size + 0xFF) & -0x100

let maxBuffersInFlight = 3

// MARK: - Renderer Errors

enum RendererError: Error {
    case badVertexDescriptor
    case shaderCompilationFailed(String)
    case metalDeviceUnavailable
    case commandQueueCreationFailed
    case bufferAllocationFailed
    case textureCreationFailed
    case pipelineStateCreationFailed
    
    var localizedDescription: String {
        switch self {
        case .badVertexDescriptor:
            return "Failed to create valid vertex descriptor"
        case .shaderCompilationFailed(let details):
            return "Shader compilation failed: \(details)"
        case .metalDeviceUnavailable:
            return "Metal device is not available on this device"
        case .commandQueueCreationFailed:
            return "Failed to create Metal command queue"
        case .bufferAllocationFailed:
            return "Failed to allocate Metal buffer"
        case .textureCreationFailed:
            return "Failed to create Metal texture"
        case .pipelineStateCreationFailed:
            return "Failed to create render pipeline state"
        }
    }
}

// MARK: - Render Quality Management

enum RenderQualityManager {
    static func determineOptimalQuality(device: MTLDevice) -> RenderQuality {
        // Determine optimal rendering quality based on device capabilities
        if device.supportsFamily(.apple5) || device.supportsFamily(.apple6) || device.supportsFamily(.apple7) {
            return .high
        } else if device.supportsFamily(.apple4) {
            return .medium
        } else {
            return .low
        }
    }
    
    static func shouldUseParticles(quality: RenderQuality) -> Bool {
        return quality == .high || quality == .ultra
    }
    
    static func getMaxParticleCount(quality: RenderQuality) -> Int {
        switch quality {
        case .low: return 0
        case .medium: return 100
        case .high: return 500
        case .ultra: return Int(MAX_PARTICLES)
        @unknown default: return 100
        }
    }
}

// MARK: - Enhanced Renderer Class

@MainActor
class Renderer: NSObject, MTKViewDelegate, ObservableObject {
    
    // MARK: - Core Metal Resources
    
    public let device: MTLDevice
    let commandQueue: MTLCommandQueue
    
    // MARK: - Buffers
    
    var dynamicUniformBuffer: MTLBuffer
    var cardUniformBuffer: MTLBuffer
    var particleBuffer: MTLBuffer?
    
    // MARK: - Pipeline States
    
    var basicPipelineState: MTLRenderPipelineState
    var cardPipelineState: MTLRenderPipelineState
    var cardHighlightPipelineState: MTLRenderPipelineState
    var cardFlipPipelineState: MTLRenderPipelineState
    var particlePipelineState: MTLRenderPipelineState?
    var romanianPatternPipelineState: MTLRenderPipelineState
    
    // MARK: - Render State
    
    var depthState: MTLDepthStencilState
    var colorMap: MTLTexture
    
    // MARK: - Threading and Performance
    
    let inFlightSemaphore = DispatchSemaphore(value: maxBuffersInFlight)
    var uniformBufferOffset = 0
    var uniformBufferIndex = 0
    var cardUniformBufferOffset = 0
    
    // MARK: - Uniform Pointers
    
    var uniforms: UnsafeMutablePointer<Uniforms>
    var cardUniforms: UnsafeMutablePointer<CardUniforms>
    
    // MARK: - Rendering State
    
    var projectionMatrix: matrix_float4x4 = matrix_float4x4()
    var rotation: Float = 0
    var time: Float = 0
    
    // MARK: - Mesh Resources
    
    var mesh: MTKMesh
    var cardMesh: MTKMesh?
    
    // MARK: - Quality and Performance
    
    @Published var renderQuality: RenderQuality
    @Published var isMetalAvailable = true
    @Published var frameRate: Double = 60.0
    @Published var lastFrameTime: CFTimeInterval = 0
    
    // MARK: - Manager Integration
    
    weak var errorManager: ErrorManager?
    weak var performanceMonitor: PerformanceMonitor?
    
    // MARK: - Animation State
    
    var currentCardAnimations: [UUID: CardAnimationState] = [:]
    var particleEmitters: [ParticleEmitter] = []
    
    // MARK: - Romanian Cultural Effects
    
    var isUsingRomanianEffects = true
    var culturalIntensity: Float = 1.0
    
    @MainActor
    init?(metalKitView: MTKView, 
          errorManager: ErrorManager? = nil, 
          performanceMonitor: PerformanceMonitor? = nil) {
        
        // Initialize device and basic properties
        guard let device = metalKitView.device else {
            return nil
        }
        self.device = device
        self.errorManager = errorManager
        self.performanceMonitor = performanceMonitor
        
        // Determine optimal render quality for device
        let initialRenderQuality = RenderQualityManager.determineOptimalQuality(device: device)
        self.renderQuality = initialRenderQuality
        
        // Create command queue
        guard let queue = device.makeCommandQueue() else {
            errorManager?.reportError(.criticalSystemError(error: "Failed to create Metal command queue"), 
                                    context: "Renderer initialization")
            return nil
        }
        self.commandQueue = queue
        
        // Allocate uniform buffers
        let uniformBufferSize = alignedUniformsSize * maxBuffersInFlight
        let cardUniformBufferSize = alignedCardUniformsSize * maxBuffersInFlight
        
        guard let uniformBuffer = device.makeBuffer(length: uniformBufferSize, 
                                                   options: [.storageModeShared]) else {
            errorManager?.reportError(.criticalSystemError(error: "Failed to allocate uniform buffer"), 
                                    context: "Buffer allocation")
            return nil
        }
        dynamicUniformBuffer = uniformBuffer
        dynamicUniformBuffer.label = "UniformBuffer"
        
        guard let cardBuffer = device.makeBuffer(length: cardUniformBufferSize, 
                                                options: [.storageModeShared]) else {
            errorManager?.reportError(.criticalSystemError(error: "Failed to allocate card uniform buffer"), 
                                    context: "Buffer allocation")
            return nil
        }
        cardUniformBuffer = cardBuffer
        cardUniformBuffer.label = "CardUniformBuffer"
        
        // Set up uniform pointers
        uniforms = UnsafeMutableRawPointer(dynamicUniformBuffer.contents()).bindMemory(to: Uniforms.self, capacity: 1)
        cardUniforms = UnsafeMutableRawPointer(cardUniformBuffer.contents()).bindMemory(to: CardUniforms.self, capacity: 1)
        
        // Configure MetalKit view
        metalKitView.depthStencilPixelFormat = MTLPixelFormat.depth32Float_stencil8
        metalKitView.colorPixelFormat = MTLPixelFormat.bgra8Unorm_srgb
        metalKitView.sampleCount = 1
        metalKitView.preferredFramesPerSecond = 60
        
        // Build vertex descriptor
        let mtlVertexDescriptor = Renderer.buildEnhancedVertexDescriptor()
        
        // Initialize pipeline states
        do {
            basicPipelineState = try Renderer.buildBasicPipelineState(device: device,
                                                                     metalKitView: metalKitView,
                                                                     mtlVertexDescriptor: mtlVertexDescriptor)
            
            cardPipelineState = try Renderer.buildCardPipelineState(device: device,
                                                                   metalKitView: metalKitView,
                                                                   mtlVertexDescriptor: mtlVertexDescriptor)
            
            cardHighlightPipelineState = try Renderer.buildCardHighlightPipelineState(device: device,
                                                                                     metalKitView: metalKitView,
                                                                                     mtlVertexDescriptor: mtlVertexDescriptor)
            
            cardFlipPipelineState = try Renderer.buildCardFlipPipelineState(device: device,
                                                                           metalKitView: metalKitView,
                                                                           mtlVertexDescriptor: mtlVertexDescriptor)
            
            romanianPatternPipelineState = try Renderer.buildRomanianPatternPipelineState(device: device,
                                                                                         metalKitView: metalKitView,
                                                                                         mtlVertexDescriptor: mtlVertexDescriptor)
            
            // Particle pipeline state (if quality supports it)
            if RenderQualityManager.shouldUseParticles(quality: initialRenderQuality) {
                particlePipelineState = try Renderer.buildParticlePipelineState(device: device,
                                                                               metalKitView: metalKitView,
                                                                               mtlVertexDescriptor: mtlVertexDescriptor)
                
                // Allocate particle buffer
                let particleCount = RenderQualityManager.getMaxParticleCount(quality: initialRenderQuality)
                let particleBufferSize = MemoryLayout<ParticleData>.stride * particleCount
                particleBuffer = device.makeBuffer(length: particleBufferSize, options: [.storageModeShared])
                particleBuffer?.label = "ParticleBuffer"
            }
            
        } catch {
            errorManager?.reportError(.criticalSystemError(error: "Pipeline state compilation failed: \(error)"), 
                                    context: "Shader compilation")
            return nil
        }
        
        // Create depth state
        let depthStateDescriptor = MTLDepthStencilDescriptor()
        depthStateDescriptor.depthCompareFunction = MTLCompareFunction.less
        depthStateDescriptor.isDepthWriteEnabled = true
        guard let state = device.makeDepthStencilState(descriptor: depthStateDescriptor) else {
            errorManager?.reportError(.criticalSystemError(error: "Failed to create depth stencil state"), 
                                    context: "Depth state creation")
            return nil
        }
        depthState = state
        
        // Build meshes
        do {
            mesh = try Renderer.buildMesh(device: device, mtlVertexDescriptor: mtlVertexDescriptor)
            cardMesh = try Renderer.buildCardMesh(device: device, mtlVertexDescriptor: mtlVertexDescriptor)
        } catch {
            errorManager?.reportError(.criticalSystemError(error: "Failed to build mesh: \(error)"), 
                                    context: "Mesh creation")
            return nil
        }
        
        // Load textures
        do {
            colorMap = try Renderer.loadTexture(device: device, textureName: "ColorMap")
        } catch {
            // Create fallback texture if ColorMap not found
            colorMap = Renderer.createFallbackTexture(device: device)
        }
        
        super.init()
        
        // Initialize performance monitoring
        performanceMonitor?.startMonitoring(component: "MetalRenderer")
        
        print("✅ Enhanced Metal Renderer initialized successfully")
        print("   - Render Quality: \(renderQuality)")
        print("   - Device: \(device.name)")
        print("   - Particles Enabled: \(RenderQualityManager.shouldUseParticles(quality: renderQuality))")
    }
    
    class func buildMetalVertexDescriptor() -> MTLVertexDescriptor {
        // Create a Metal vertex descriptor specifying how vertices will by laid out for input into our render
        //   pipeline and how we'll layout our Model IO vertices
        
        let mtlVertexDescriptor = MTLVertexDescriptor()
        
        mtlVertexDescriptor.attributes[VertexAttribute.position.rawValue].format = MTLVertexFormat.float3
        mtlVertexDescriptor.attributes[VertexAttribute.position.rawValue].offset = 0
        mtlVertexDescriptor.attributes[VertexAttribute.position.rawValue].bufferIndex = BufferIndex.meshPositions.rawValue
        
        mtlVertexDescriptor.attributes[VertexAttribute.texcoord.rawValue].format = MTLVertexFormat.float2
        mtlVertexDescriptor.attributes[VertexAttribute.texcoord.rawValue].offset = 0
        mtlVertexDescriptor.attributes[VertexAttribute.texcoord.rawValue].bufferIndex = BufferIndex.meshGenerics.rawValue
        
        mtlVertexDescriptor.layouts[BufferIndex.meshPositions.rawValue].stride = 12
        mtlVertexDescriptor.layouts[BufferIndex.meshPositions.rawValue].stepRate = 1
        mtlVertexDescriptor.layouts[BufferIndex.meshPositions.rawValue].stepFunction = MTLVertexStepFunction.perVertex
        
        mtlVertexDescriptor.layouts[BufferIndex.meshGenerics.rawValue].stride = 8
        mtlVertexDescriptor.layouts[BufferIndex.meshGenerics.rawValue].stepRate = 1
        mtlVertexDescriptor.layouts[BufferIndex.meshGenerics.rawValue].stepFunction = MTLVertexStepFunction.perVertex
        
        return mtlVertexDescriptor
    }
    
    @MainActor
    class func buildRenderPipelineWithDevice(device: MTLDevice,
                                             metalKitView: MTKView,
                                             mtlVertexDescriptor: MTLVertexDescriptor) throws -> MTLRenderPipelineState {
        /// Build a render state pipeline object
        
        let library = device.makeDefaultLibrary()
        
        let vertexFunction = library?.makeFunction(name: "vertexShader")
        let fragmentFunction = library?.makeFunction(name: "fragmentShader")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "RenderPipeline"
        pipelineDescriptor.rasterSampleCount = metalKitView.sampleCount
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = mtlVertexDescriptor
        
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalKitView.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = metalKitView.depthStencilPixelFormat
        pipelineDescriptor.stencilAttachmentPixelFormat = metalKitView.depthStencilPixelFormat
        
        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    class func buildMesh(device: MTLDevice,
                         mtlVertexDescriptor: MTLVertexDescriptor) throws -> MTKMesh {
        /// Create and condition mesh data to feed into a pipeline using the given vertex descriptor
        
        let metalAllocator = MTKMeshBufferAllocator(device: device)
        
        let mdlMesh = MDLMesh.newBox(withDimensions: SIMD3<Float>(4, 4, 4),
                                     segments: SIMD3<UInt32>(2, 2, 2),
                                     geometryType: MDLGeometryType.triangles,
                                     inwardNormals:false,
                                     allocator: metalAllocator)
        
        let mdlVertexDescriptor = MTKModelIOVertexDescriptorFromMetal(mtlVertexDescriptor)
        
        guard let attributes = mdlVertexDescriptor.attributes as? [MDLVertexAttribute] else {
            throw RendererError.badVertexDescriptor
        }
        attributes[VertexAttribute.position.rawValue].name = MDLVertexAttributePosition
        attributes[VertexAttribute.texcoord.rawValue].name = MDLVertexAttributeTextureCoordinate
        
        mdlMesh.vertexDescriptor = mdlVertexDescriptor
        
        return try MTKMesh(mesh:mdlMesh, device:device)
    }
    
    class func loadTexture(device: MTLDevice,
                           textureName: String) throws -> MTLTexture {
        /// Load texture data with optimal parameters for sampling
        
        let textureLoader = MTKTextureLoader(device: device)
        
        let textureLoaderOptions = [
            MTKTextureLoader.Option.textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
            MTKTextureLoader.Option.textureStorageMode: NSNumber(value: MTLStorageMode.`private`.rawValue)
        ]
        
        return try textureLoader.newTexture(name: textureName,
                                            scaleFactor: 1.0,
                                            bundle: nil,
                                            options: textureLoaderOptions)
        
    }
    
    // MARK: - Buffer State Management
    
    private func updateDynamicBufferState() {
        uniformBufferIndex = (uniformBufferIndex + 1) % maxBuffersInFlight
        uniformBufferOffset = alignedUniformsSize * uniformBufferIndex
        cardUniformBufferOffset = alignedCardUniformsSize * uniformBufferIndex
        
        uniforms = UnsafeMutableRawPointer(dynamicUniformBuffer.contents() + uniformBufferOffset).bindMemory(to: Uniforms.self, capacity: 1)
        cardUniforms = UnsafeMutableRawPointer(cardUniformBuffer.contents() + cardUniformBufferOffset).bindMemory(to: CardUniforms.self, capacity: 1)
    }
    
    private func updateGameState() {
        let currentTime = Float(CACurrentMediaTime())
        let deltaTime = time > 0 ? currentTime - time : 0.016 // 60 FPS fallback
        time = currentTime
        
        // Update main uniforms
        uniforms[0].projectionMatrix = projectionMatrix
        uniforms[0].time = time
        uniforms[0].deltaTime = deltaTime
        uniforms[0].screenSize = simd_float2(Float(UIScreen.main.bounds.width), Float(UIScreen.main.bounds.height))
        uniforms[0].animationProgress = 0.0 // Will be set per object
        
        // Basic rotation for demo purposes
        let rotationAxis = SIMD3<Float>(0, 1, 0)
        let modelMatrix = matrix4x4_rotation(radians: rotation, axis: rotationAxis)
        let viewMatrix = matrix4x4_translation(0.0, 0.0, -5.0)
        uniforms[0].modelViewMatrix = simd_mul(viewMatrix, modelMatrix)
        rotation += 0.01
        
        // Update card uniforms with Romanian cultural colors
        cardUniforms[0].highlightColor = simd_float4(ROMANIAN_GOLD_R, ROMANIAN_GOLD_G, ROMANIAN_GOLD_B, 1.0)
        cardUniforms[0].flipAngle = 0.0
        cardUniforms[0].glowIntensity = DEFAULT_GLOW_INTENSITY * culturalIntensity
        cardUniforms[0].animationProgress = 0.0
    }
    
    // MARK: - Rendering Methods
    
    private func renderBasicMesh(_ renderEncoder: MTLRenderCommandEncoder) {
        renderEncoder.setRenderPipelineState(basicPipelineState)
        
        renderEncoder.setVertexBuffer(dynamicUniformBuffer, offset: uniformBufferOffset, index: BufferIndex.uniforms.rawValue)
        renderEncoder.setFragmentBuffer(dynamicUniformBuffer, offset: uniformBufferOffset, index: BufferIndex.uniforms.rawValue)
        
        for (index, element) in mesh.vertexDescriptor.layouts.enumerated() {
            guard let layout = element as? MDLVertexBufferLayout else { continue }
            
            if layout.stride != 0 {
                let buffer = mesh.vertexBuffers[index]
                renderEncoder.setVertexBuffer(buffer.buffer, offset: buffer.offset, index: index)
            }
        }
        
        renderEncoder.setFragmentTexture(colorMap, index: TextureIndex.color.rawValue)
        
        for submesh in mesh.submeshes {
            renderEncoder.drawIndexedPrimitives(type: submesh.primitiveType,
                                               indexCount: submesh.indexCount,
                                               indexType: submesh.indexType,
                                               indexBuffer: submesh.indexBuffer.buffer,
                                               indexBufferOffset: submesh.indexBuffer.offset)
        }
    }
    
    private func renderCards(_ renderEncoder: MTLRenderCommandEncoder) {
        guard let cardMesh = cardMesh else { return }
        
        // Use appropriate pipeline based on animation state
        let pipelineState = isUsingRomanianEffects ? romanianPatternPipelineState : cardPipelineState
        renderEncoder.setRenderPipelineState(pipelineState)
        
        // Set uniforms
        renderEncoder.setVertexBuffer(dynamicUniformBuffer, offset: uniformBufferOffset, index: BufferIndex.uniforms.rawValue)
        renderEncoder.setFragmentBuffer(dynamicUniformBuffer, offset: uniformBufferOffset, index: BufferIndex.uniforms.rawValue)
        renderEncoder.setFragmentBuffer(cardUniformBuffer, offset: cardUniformBufferOffset, index: BufferIndex.cardUniforms.rawValue)
        
        // Set mesh
        for (index, element) in cardMesh.vertexDescriptor.layouts.enumerated() {
            guard let layout = element as? MDLVertexBufferLayout else { continue }
            
            if layout.stride != 0 {
                let buffer = cardMesh.vertexBuffers[index]
                renderEncoder.setVertexBuffer(buffer.buffer, offset: buffer.offset, index: index)
            }
        }
        
        renderEncoder.setFragmentTexture(colorMap, index: TextureIndex.color.rawValue)
        
        // Render card mesh
        for submesh in cardMesh.submeshes {
            renderEncoder.drawIndexedPrimitives(type: submesh.primitiveType,
                                               indexCount: submesh.indexCount,
                                               indexType: submesh.indexType,
                                               indexBuffer: submesh.indexBuffer.buffer,
                                               indexBufferOffset: submesh.indexBuffer.offset)
        }
    }
    
    private func renderParticles(_ renderEncoder: MTLRenderCommandEncoder) {
        guard let particlePipelineState = particlePipelineState,
              let particleBuffer = particleBuffer,
              !particleEmitters.isEmpty else { return }
        
        renderEncoder.setRenderPipelineState(particlePipelineState)
        
        renderEncoder.setVertexBuffer(dynamicUniformBuffer, offset: uniformBufferOffset, index: BufferIndex.uniforms.rawValue)
        renderEncoder.setVertexBuffer(particleBuffer, offset: 0, index: BufferIndex.particleData.rawValue)
        
        // Update and render active particles
        // This would be expanded with actual particle simulation
        let particleCount = min(particleEmitters.count * 10, RenderQualityManager.getMaxParticleCount(quality: renderQuality))
        
        if particleCount > 0 {
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: particleCount * 6)
        }
    }
    
    func draw(in view: MTKView) {
        // Performance monitoring
        updatePerformanceMetrics()
        
        // Memory check (periodic)
        if Int(time) % 60 == 0 { // Check every ~60 frames
            checkMemoryUsage()
        }
        
        _ = inFlightSemaphore.wait(timeout: DispatchTime.distantFuture)
        
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            inFlightSemaphore.signal()
            errorManager?.reportError(.criticalSystemError(error: "Failed to create command buffer"), 
                                    context: "Metal rendering")
            return
        }
        
        commandBuffer.label = "SepticaRenderCommand"
        
        let semaphore = inFlightSemaphore
        commandBuffer.addCompletedHandler { _ in
            semaphore.signal()
        }
        
        // Update rendering state
        updateDynamicBufferState()
        updateGameState()
        
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else {
            commandBuffer.commit()
            return
        }
        
        // Configure render pass
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.1, green: 0.2, blue: 0.15, alpha: 1.0) // Dark green Romanian theme
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            commandBuffer.commit()
            errorManager?.reportError(.criticalSystemError(error: "Failed to create render encoder"), 
                                    context: "Metal rendering")
            return
        }
        
        renderEncoder.label = "SepticaRenderEncoder"
        renderEncoder.pushDebugGroup("SepticaCardGame")
        
        // Set common render state
        renderEncoder.setCullMode(.back)
        renderEncoder.setFrontFacing(.counterClockwise)
        renderEncoder.setDepthStencilState(depthState)
        
        // Render based on quality level
        switch renderQuality {
        case .low:
            renderEncoder.pushDebugGroup("BasicRendering")
            renderBasicMesh(renderEncoder)
            renderEncoder.popDebugGroup()
            
        case .medium:
            renderEncoder.pushDebugGroup("StandardRendering")
            renderCards(renderEncoder)
            renderEncoder.popDebugGroup()
            
        case .high, .ultra:
            renderEncoder.pushDebugGroup("HighQualityRendering")
            renderCards(renderEncoder)
            
            if RenderQualityManager.shouldUseParticles(quality: renderQuality) {
                renderEncoder.pushDebugGroup("ParticleEffects")
                renderParticles(renderEncoder)
                renderEncoder.popDebugGroup()
            }
            renderEncoder.popDebugGroup()
            
        @unknown default:
            renderEncoder.pushDebugGroup("FallbackRendering")
            renderBasicMesh(renderEncoder)
            renderEncoder.popDebugGroup()
        }
        
        renderEncoder.popDebugGroup()
        renderEncoder.endEncoding()
        
        if let drawable = view.currentDrawable {
            commandBuffer.present(drawable)
        }
        
        commandBuffer.commit()
        
        // Update performance monitor
        performanceMonitor?.recordMetric(name: "DrawCalls", value: 1, unit: "calls")
    }
    
    // MARK: - Public API for Integration
    
    /// Enable/disable Romanian cultural effects
    func setRomanianEffectsEnabled(_ enabled: Bool) {
        isUsingRomanianEffects = enabled
        culturalIntensity = enabled ? 1.0 : 0.0
    }
    
    /// Set render quality level
    func setRenderQuality(_ quality: RenderQuality) {
        renderQuality = quality
        
        // Update particle system based on quality
        if !RenderQualityManager.shouldUseParticles(quality: quality) {
            clearAllParticles()
        }
    }
    
    /// Add victory celebration effect
    func triggerVictoryCelebration(at position: simd_float3) {
        if RenderQualityManager.shouldUseParticles(quality: renderQuality) {
            addParticleEmitter(at: position, 
                             color: simd_float4(ROMANIAN_GOLD_R, ROMANIAN_GOLD_G, ROMANIAN_GOLD_B, 1.0))
        }
    }
    
    /// Add card selection effect
    func setCardHighlighted(_ cardId: UUID, highlighted: Bool) {
        if highlighted {
            // Animation state management moved to CardRenderer
        } else {
            removeCardAnimation(cardId)
        }
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        /// Respond to drawable size or orientation changes here
        
        let aspect = Float(size.width) / Float(size.height)
        projectionMatrix = matrix_perspective_right_hand(fovyRadians: radians_from_degrees(65), aspectRatio:aspect, nearZ: 0.1, farZ: 100.0)
    }
}

// Generic matrix math utility functions
func matrix4x4_rotation(radians: Float, axis: SIMD3<Float>) -> matrix_float4x4 {
    let unitAxis = normalize(axis)
    let ct = cosf(radians)
    let st = sinf(radians)
    let ci = 1 - ct
    let x = unitAxis.x, y = unitAxis.y, z = unitAxis.z
    return matrix_float4x4.init(columns:(vector_float4(    ct + x * x * ci, y * x * ci + z * st, z * x * ci - y * st, 0),
                                         vector_float4(x * y * ci - z * st,     ct + y * y * ci, z * y * ci + x * st, 0),
                                         vector_float4(x * z * ci + y * st, y * z * ci - x * st,     ct + z * z * ci, 0),
                                         vector_float4(                  0,                   0,                   0, 1)))
}

func matrix4x4_translation(_ translationX: Float, _ translationY: Float, _ translationZ: Float) -> matrix_float4x4 {
    return matrix_float4x4.init(columns:(vector_float4(1, 0, 0, 0),
                                         vector_float4(0, 1, 0, 0),
                                         vector_float4(0, 0, 1, 0),
                                         vector_float4(translationX, translationY, translationZ, 1)))
}

func matrix_perspective_right_hand(fovyRadians fovy: Float, aspectRatio: Float, nearZ: Float, farZ: Float) -> matrix_float4x4 {
    let ys = 1 / tanf(fovy * 0.5)
    let xs = ys / aspectRatio
    let zs = farZ / (nearZ - farZ)
    return matrix_float4x4.init(columns:(vector_float4(xs,  0, 0,   0),
                                         vector_float4( 0, ys, 0,   0),
                                         vector_float4( 0,  0, zs, -1),
                                         vector_float4( 0,  0, zs * nearZ, 0)))
}

func radians_from_degrees(_ degrees: Float) -> Float {
    return (degrees / 180) * .pi
}
