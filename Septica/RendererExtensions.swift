//
//  RendererExtensions.swift
//  Septica
//
//  Extensions for Enhanced Metal Renderer
//  Provides pipeline state builders and helper methods
//

import Metal
import MetalKit
import simd

// MARK: - Particle System

struct ParticleEmitter {
    var position: simd_float3
    var emissionRate: Float
    var particleLifetime: Float
    var particleSize: Float
    var color: simd_float4
    var velocity: simd_float3
    var isActive: Bool
}

// MARK: - Renderer Extensions

extension Renderer {
    
    // MARK: - Enhanced Vertex Descriptor
    
    static func buildEnhancedVertexDescriptor() -> MTLVertexDescriptor {
        let mtlVertexDescriptor = MTLVertexDescriptor()
        
        // Position attribute
        mtlVertexDescriptor.attributes[VertexAttribute.position.rawValue].format = MTLVertexFormat.float3
        mtlVertexDescriptor.attributes[VertexAttribute.position.rawValue].offset = 0
        mtlVertexDescriptor.attributes[VertexAttribute.position.rawValue].bufferIndex = BufferIndex.meshPositions.rawValue
        
        // Texture coordinate attribute
        mtlVertexDescriptor.attributes[VertexAttribute.texcoord.rawValue].format = MTLVertexFormat.float2
        mtlVertexDescriptor.attributes[VertexAttribute.texcoord.rawValue].offset = 0
        mtlVertexDescriptor.attributes[VertexAttribute.texcoord.rawValue].bufferIndex = BufferIndex.meshGenerics.rawValue
        
        // Position buffer layout
        mtlVertexDescriptor.layouts[BufferIndex.meshPositions.rawValue].stride = 12
        mtlVertexDescriptor.layouts[BufferIndex.meshPositions.rawValue].stepRate = 1
        mtlVertexDescriptor.layouts[BufferIndex.meshPositions.rawValue].stepFunction = MTLVertexStepFunction.perVertex
        
        // Generic buffer layout
        mtlVertexDescriptor.layouts[BufferIndex.meshGenerics.rawValue].stride = 8
        mtlVertexDescriptor.layouts[BufferIndex.meshGenerics.rawValue].stepRate = 1
        mtlVertexDescriptor.layouts[BufferIndex.meshGenerics.rawValue].stepFunction = MTLVertexStepFunction.perVertex
        
        return mtlVertexDescriptor
    }
    
    // MARK: - Pipeline State Builders
    
    static func buildBasicPipelineState(device: MTLDevice,
                                       metalKitView: MTKView,
                                       mtlVertexDescriptor: MTLVertexDescriptor) throws -> MTLRenderPipelineState {
        
        guard let library = device.makeDefaultLibrary() else {
            throw RendererError.shaderCompilationFailed("Cannot create default library")
        }
        
        guard let vertexFunction = library.makeFunction(name: "basicVertexShader") else {
            throw RendererError.shaderCompilationFailed("Cannot find basicVertexShader function")
        }
        
        guard let fragmentFunction = library.makeFunction(name: "basicFragmentShader") else {
            throw RendererError.shaderCompilationFailed("Cannot find basicFragmentShader function")
        }
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "BasicRenderPipeline"
        pipelineDescriptor.rasterSampleCount = metalKitView.sampleCount
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = mtlVertexDescriptor
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalKitView.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = metalKitView.depthStencilPixelFormat
        pipelineDescriptor.stencilAttachmentPixelFormat = metalKitView.depthStencilPixelFormat
        
        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    static func buildCardPipelineState(device: MTLDevice,
                                      metalKitView: MTKView,
                                      mtlVertexDescriptor: MTLVertexDescriptor) throws -> MTLRenderPipelineState {
        
        guard let library = device.makeDefaultLibrary() else {
            throw RendererError.shaderCompilationFailed("Cannot create default library")
        }
        
        guard let vertexFunction = library.makeFunction(name: "cardVertexShader") else {
            throw RendererError.shaderCompilationFailed("Cannot find cardVertexShader function")
        }
        
        guard let fragmentFunction = library.makeFunction(name: "cardFragmentShader") else {
            throw RendererError.shaderCompilationFailed("Cannot find cardFragmentShader function")
        }
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "CardRenderPipeline"
        pipelineDescriptor.rasterSampleCount = metalKitView.sampleCount
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = mtlVertexDescriptor
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalKitView.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = metalKitView.depthStencilPixelFormat
        pipelineDescriptor.stencilAttachmentPixelFormat = metalKitView.depthStencilPixelFormat
        
        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    static func buildCardHighlightPipelineState(device: MTLDevice,
                                               metalKitView: MTKView,
                                               mtlVertexDescriptor: MTLVertexDescriptor) throws -> MTLRenderPipelineState {
        
        guard let library = device.makeDefaultLibrary() else {
            throw RendererError.shaderCompilationFailed("Cannot create default library")
        }
        
        guard let vertexFunction = library.makeFunction(name: "cardVertexShader") else {
            throw RendererError.shaderCompilationFailed("Cannot find cardVertexShader function")
        }
        
        guard let fragmentFunction = library.makeFunction(name: "cardHighlightShader") else {
            throw RendererError.shaderCompilationFailed("Cannot find cardHighlightShader function")
        }
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "CardHighlightPipeline"
        pipelineDescriptor.rasterSampleCount = metalKitView.sampleCount
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = mtlVertexDescriptor
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalKitView.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = metalKitView.depthStencilPixelFormat
        pipelineDescriptor.stencilAttachmentPixelFormat = metalKitView.depthStencilPixelFormat
        
        // Enable alpha blending for highlights
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperation.add
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperation.add
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactor.sourceAlpha
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactor.sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactor.oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactor.oneMinusSourceAlpha
        
        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    static func buildCardFlipPipelineState(device: MTLDevice,
                                          metalKitView: MTKView,
                                          mtlVertexDescriptor: MTLVertexDescriptor) throws -> MTLRenderPipelineState {
        
        guard let library = device.makeDefaultLibrary() else {
            throw RendererError.shaderCompilationFailed("Cannot create default library")
        }
        
        guard let vertexFunction = library.makeFunction(name: "cardFlipVertexShader") else {
            throw RendererError.shaderCompilationFailed("Cannot find cardFlipVertexShader function")
        }
        
        guard let fragmentFunction = library.makeFunction(name: "cardFragmentShader") else {
            throw RendererError.shaderCompilationFailed("Cannot find cardFragmentShader function")
        }
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "CardFlipPipeline"
        pipelineDescriptor.rasterSampleCount = metalKitView.sampleCount
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = mtlVertexDescriptor
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalKitView.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = metalKitView.depthStencilPixelFormat
        pipelineDescriptor.stencilAttachmentPixelFormat = metalKitView.depthStencilPixelFormat
        
        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    static func buildParticlePipelineState(device: MTLDevice,
                                          metalKitView: MTKView,
                                          mtlVertexDescriptor: MTLVertexDescriptor) throws -> MTLRenderPipelineState {
        
        guard let library = device.makeDefaultLibrary() else {
            throw RendererError.shaderCompilationFailed("Cannot create default library")
        }
        
        guard let vertexFunction = library.makeFunction(name: "particleVertexShader") else {
            throw RendererError.shaderCompilationFailed("Cannot find particleVertexShader function")
        }
        
        guard let fragmentFunction = library.makeFunction(name: "particleFragmentShader") else {
            throw RendererError.shaderCompilationFailed("Cannot find particleFragmentShader function")
        }
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "ParticlePipeline"
        pipelineDescriptor.rasterSampleCount = metalKitView.sampleCount
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = mtlVertexDescriptor
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalKitView.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = metalKitView.depthStencilPixelFormat
        pipelineDescriptor.stencilAttachmentPixelFormat = metalKitView.depthStencilPixelFormat
        
        // Enable alpha blending for particles
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperation.add
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperation.add
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactor.sourceAlpha
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactor.sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactor.one
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactor.oneMinusSourceAlpha
        
        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    static func buildRomanianPatternPipelineState(device: MTLDevice,
                                                 metalKitView: MTKView,
                                                 mtlVertexDescriptor: MTLVertexDescriptor) throws -> MTLRenderPipelineState {
        
        guard let library = device.makeDefaultLibrary() else {
            throw RendererError.shaderCompilationFailed("Cannot create default library")
        }
        
        guard let vertexFunction = library.makeFunction(name: "cardVertexShader") else {
            throw RendererError.shaderCompilationFailed("Cannot find cardVertexShader function")
        }
        
        guard let fragmentFunction = library.makeFunction(name: "romanianPatternShader") else {
            throw RendererError.shaderCompilationFailed("Cannot find romanianPatternShader function")
        }
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "RomanianPatternPipeline"
        pipelineDescriptor.rasterSampleCount = metalKitView.sampleCount
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = mtlVertexDescriptor
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalKitView.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = metalKitView.depthStencilPixelFormat
        pipelineDescriptor.stencilAttachmentPixelFormat = metalKitView.depthStencilPixelFormat
        
        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    // MARK: - Mesh Builders
    
    static func buildCardMesh(device: MTLDevice, 
                             mtlVertexDescriptor: MTLVertexDescriptor) throws -> MTKMesh {
        let metalAllocator = MTKMeshBufferAllocator(device: device)
        
        // Create a plane mesh for cards with proper proportions
        let mdlMesh = MDLMesh.newPlane(withDimensions: SIMD2<Float>(2.5, 3.5), // Standard card proportions
                                       segments: SIMD2<UInt32>(1, 1),
                                       geometryType: MDLGeometryType.triangles,
                                       allocator: metalAllocator)
        
        let mdlVertexDescriptor = MTKModelIOVertexDescriptorFromMetal(mtlVertexDescriptor)
        
        guard let attributes = mdlVertexDescriptor.attributes as? [MDLVertexAttribute] else {
            throw RendererError.badVertexDescriptor
        }
        
        attributes[VertexAttribute.position.rawValue].name = MDLVertexAttributePosition
        attributes[VertexAttribute.texcoord.rawValue].name = MDLVertexAttributeTextureCoordinate
        
        mdlMesh.vertexDescriptor = mdlVertexDescriptor
        
        return try MTKMesh(mesh: mdlMesh, device: device)
    }
    
    // MARK: - Texture Utilities
    
    static func createFallbackTexture(device: MTLDevice) -> MTLTexture {
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm,
                                                                         width: 64,
                                                                         height: 64,
                                                                         mipmapped: false)
        textureDescriptor.usage = [.shaderRead]
        
        guard let texture = device.makeTexture(descriptor: textureDescriptor) else {
            fatalError("Failed to create fallback texture")
        }
        
        // Create a simple gradient pattern
        let bytesPerPixel = 4
        let bytesPerRow = 64 * bytesPerPixel
        let imageData = UnsafeMutableRawPointer.allocate(byteCount: 64 * 64 * bytesPerPixel, alignment: 1)
        defer { imageData.deallocate() }
        
        let pixelData = imageData.assumingMemoryBound(to: UInt8.self)
        
        for y in 0..<64 {
            for x in 0..<64 {
                let index = (y * 64 + x) * 4
                let normalizedX = Float(x) / 64.0
                let normalizedY = Float(y) / 64.0
                
                // Romanian flag colors gradient
                pixelData[index] = UInt8(255 * (1.0 - normalizedX + normalizedY) * 0.5) // Red
                pixelData[index + 1] = UInt8(255 * normalizedY * 0.8) // Green
                pixelData[index + 2] = UInt8(255 * normalizedX * 0.6) // Blue
                pixelData[index + 3] = 255 // Alpha
            }
        }
        
        let region = MTLRegionMake2D(0, 0, 64, 64)
        texture.replace(region: region, mipmapLevel: 0, withBytes: imageData, bytesPerRow: bytesPerRow)
        
        return texture
    }
    
    // MARK: - Legacy Compatibility
    
    static func buildLegacyMetalVertexDescriptor() -> MTLVertexDescriptor {
        return buildEnhancedVertexDescriptor()
    }
    
    static func buildLegacyRenderPipelineWithDevice(device: MTLDevice,
                                                   metalKitView: MTKView,
                                                   mtlVertexDescriptor: MTLVertexDescriptor) throws -> MTLRenderPipelineState {
        return try buildBasicPipelineState(device: device, metalKitView: metalKitView, mtlVertexDescriptor: mtlVertexDescriptor)
    }
}

// MARK: - Performance Monitoring Integration

extension Renderer {
    
    func updatePerformanceMetrics() {
        let currentTime = CACurrentMediaTime()
        if lastFrameTime > 0 {
            let deltaTime = currentTime - lastFrameTime
            frameRate = 1.0 / deltaTime
            
            // Report performance warnings if frame rate drops significantly
            if frameRate < 50.0 {
                errorManager?.reportError(.performanceWarning(metric: "Frame Rate", value: frameRate), 
                                        context: "Metal Renderer")
            }
            
            performanceMonitor?.recordMetric(name: "FrameRate", value: frameRate, unit: "fps")
            performanceMonitor?.recordMetric(name: "RenderTime", value: deltaTime * 1000, unit: "ms")
        }
        lastFrameTime = currentTime
    }
    
    func checkMemoryUsage() {
        var memoryInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &memoryInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let memoryUsage = Double(memoryInfo.resident_size) / 1024.0 / 1024.0 // MB
            
            if memoryUsage > 500.0 {
                errorManager?.reportError(.insufficientMemory(currentUsage: memoryUsage), 
                                        context: "Metal Renderer Memory Check")
            }
            
            performanceMonitor?.recordMetric(name: "MemoryUsage", value: memoryUsage, unit: "MB")
        }
    }
}

// MARK: - Romanian Cultural Animation Support

extension Renderer {
    
    func setCardAnimation(_ cardId: UUID, state: CardAnimationState) {
        currentCardAnimations[cardId] = state
    }
    
    func removeCardAnimation(_ cardId: UUID) {
        currentCardAnimations.removeValue(forKey: cardId)
    }
    
    func addParticleEmitter(at position: simd_float3, 
                           color: simd_float4 = simd_float4(ROMANIAN_GOLD_R, ROMANIAN_GOLD_G, ROMANIAN_GOLD_B, 1.0)) {
        let emitter = ParticleEmitter(
            position: position,
            emissionRate: 50.0,
            particleLifetime: 2.0,
            particleSize: 0.05,
            color: color,
            velocity: simd_float3(0, 1, 0),
            isActive: true
        )
        particleEmitters.append(emitter)
    }
    
    func clearAllParticles() {
        particleEmitters.removeAll()
    }
    
    func setRomanianEffectsEnabledExtended(_ enabled: Bool) {
        isUsingRomanianEffects = enabled
        culturalIntensity = enabled ? 1.0 : 0.0
    }
}