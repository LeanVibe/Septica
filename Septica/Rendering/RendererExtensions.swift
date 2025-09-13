//
//  RendererExtensions.swift
//  Septica
//
//  Additional renderer methods and extensions to support Metal pipeline
//  Provides missing implementations for complete compilation
//

import Metal
import MetalKit
import simd

// MARK: - Missing Renderer Methods (Sprint 1 Implementation)

extension Renderer {
    
    // MARK: - Enhanced Vertex Descriptor
    
    class func buildEnhancedVertexDescriptor() -> MTLVertexDescriptor {
        let mtlVertexDescriptor = MTLVertexDescriptor()
        
        // Position attribute (same as before)
        mtlVertexDescriptor.attributes[VertexAttribute.position.rawValue].format = MTLVertexFormat.float3
        mtlVertexDescriptor.attributes[VertexAttribute.position.rawValue].offset = 0
        mtlVertexDescriptor.attributes[VertexAttribute.position.rawValue].bufferIndex = BufferIndex.meshPositions.rawValue
        
        // Texture coordinate attribute
        mtlVertexDescriptor.attributes[VertexAttribute.texcoord.rawValue].format = MTLVertexFormat.float2
        mtlVertexDescriptor.attributes[VertexAttribute.texcoord.rawValue].offset = 0
        mtlVertexDescriptor.attributes[VertexAttribute.texcoord.rawValue].bufferIndex = BufferIndex.meshGenerics.rawValue
        
        // Normal attribute (for lighting)
        mtlVertexDescriptor.attributes[VertexAttribute.normal.rawValue].format = MTLVertexFormat.float3
        mtlVertexDescriptor.attributes[VertexAttribute.normal.rawValue].offset = 8
        mtlVertexDescriptor.attributes[VertexAttribute.normal.rawValue].bufferIndex = BufferIndex.meshGenerics.rawValue
        
        // Layout for positions
        mtlVertexDescriptor.layouts[BufferIndex.meshPositions.rawValue].stride = 12
        mtlVertexDescriptor.layouts[BufferIndex.meshPositions.rawValue].stepRate = 1
        mtlVertexDescriptor.layouts[BufferIndex.meshPositions.rawValue].stepFunction = MTLVertexStepFunction.perVertex
        
        // Layout for texture coordinates and normals
        mtlVertexDescriptor.layouts[BufferIndex.meshGenerics.rawValue].stride = 20 // 2 floats (8 bytes) + 3 floats (12 bytes)
        mtlVertexDescriptor.layouts[BufferIndex.meshGenerics.rawValue].stepRate = 1
        mtlVertexDescriptor.layouts[BufferIndex.meshGenerics.rawValue].stepFunction = MTLVertexStepFunction.perVertex
        
        return mtlVertexDescriptor
    }
    
    // MARK: - Pipeline State Builders
    
    class func buildBasicPipelineState(device: MTLDevice,
                                      metalKitView: MTKView,
                                      mtlVertexDescriptor: MTLVertexDescriptor) throws -> MTLRenderPipelineState {
        
        let library = device.makeDefaultLibrary()
        
        // For now, use placeholder shaders (would be actual Metal functions)
        let vertexFunction = library?.makeFunction(name: "vertexShader") // Will be implemented in Metal
        let fragmentFunction = library?.makeFunction(name: "fragmentShader") // Will be implemented in Metal
        
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
    
    class func buildCardPipelineState(device: MTLDevice,
                                     metalKitView: MTKView,
                                     mtlVertexDescriptor: MTLVertexDescriptor) throws -> MTLRenderPipelineState {
        
        let library = device.makeDefaultLibrary()
        
        let vertexFunction = library?.makeFunction(name: "cardVertexShader")
        let fragmentFunction = library?.makeFunction(name: "cardFragmentShader")
        
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
    
    class func buildCardHighlightPipelineState(device: MTLDevice,
                                              metalKitView: MTKView,
                                              mtlVertexDescriptor: MTLVertexDescriptor) throws -> MTLRenderPipelineState {
        
        let library = device.makeDefaultLibrary()
        
        let vertexFunction = library?.makeFunction(name: "cardVertexShader")
        let fragmentFunction = library?.makeFunction(name: "cardHighlightFragmentShader")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "CardHighlightPipeline"
        pipelineDescriptor.rasterSampleCount = metalKitView.sampleCount
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = mtlVertexDescriptor
        
        // Enable blending for highlight effects
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalKitView.colorPixelFormat
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        
        pipelineDescriptor.depthAttachmentPixelFormat = metalKitView.depthStencilPixelFormat
        pipelineDescriptor.stencilAttachmentPixelFormat = metalKitView.depthStencilPixelFormat
        
        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    class func buildCardFlipPipelineState(device: MTLDevice,
                                         metalKitView: MTKView,
                                         mtlVertexDescriptor: MTLVertexDescriptor) throws -> MTLRenderPipelineState {
        
        let library = device.makeDefaultLibrary()
        
        let vertexFunction = library?.makeFunction(name: "cardFlipVertexShader")
        let fragmentFunction = library?.makeFunction(name: "cardFragmentShader")
        
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
    
    class func buildRomanianPatternPipelineState(device: MTLDevice,
                                                metalKitView: MTKView,
                                                mtlVertexDescriptor: MTLVertexDescriptor) throws -> MTLRenderPipelineState {
        
        let library = device.makeDefaultLibrary()
        
        let vertexFunction = library?.makeFunction(name: "cardVertexShader")
        let fragmentFunction = library?.makeFunction(name: "romanianPatternFragmentShader")
        
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
    
    class func buildParticlePipelineState(device: MTLDevice,
                                         metalKitView: MTKView,
                                         mtlVertexDescriptor: MTLVertexDescriptor) throws -> MTLRenderPipelineState {
        
        let library = device.makeDefaultLibrary()
        
        let vertexFunction = library?.makeFunction(name: "particleVertexShader")
        let fragmentFunction = library?.makeFunction(name: "particleFragmentShader")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "ParticlePipeline"
        pipelineDescriptor.rasterSampleCount = metalKitView.sampleCount
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = mtlVertexDescriptor
        
        // Enable blending for particles
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalKitView.colorPixelFormat
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .one
        
        pipelineDescriptor.depthAttachmentPixelFormat = metalKitView.depthStencilPixelFormat
        pipelineDescriptor.stencilAttachmentPixelFormat = metalKitView.depthStencilPixelFormat
        
        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    // MARK: - Enhanced Mesh Creation
    
    class func buildCardMesh(device: MTLDevice,
                            mtlVertexDescriptor: MTLVertexDescriptor) throws -> MTKMesh {
        
        let metalAllocator = MTKMeshBufferAllocator(device: device)
        
        // Create a quad mesh for cards (Romanian playing card proportions)
        let mdlMesh = MDLMesh.newBox(withDimensions: SIMD3<Float>(2.5, 3.5, 0.1), // Romanian card proportions
                                     segments: SIMD3<UInt32>(1, 1, 1),
                                     geometryType: MDLGeometryType.triangles,
                                     inwardNormals: false,
                                     allocator: metalAllocator)
        
        let mdlVertexDescriptor = MTKModelIOVertexDescriptorFromMetal(mtlVertexDescriptor)
        
        guard let attributes = mdlVertexDescriptor.attributes as? [MDLVertexAttribute] else {
            throw RendererError.badVertexDescriptor
        }
        
        attributes[VertexAttribute.position.rawValue].name = MDLVertexAttributePosition
        attributes[VertexAttribute.texcoord.rawValue].name = MDLVertexAttributeTextureCoordinate
        attributes[VertexAttribute.normal.rawValue].name = MDLVertexAttributeNormal
        
        mdlMesh.vertexDescriptor = mdlVertexDescriptor
        
        return try MTKMesh(mesh: mdlMesh, device: device)
    }
    
    // MARK: - Fallback Texture Creation
    
    class func createFallbackTexture(device: MTLDevice) -> MTLTexture {
        let textureDescriptor = MTLTextureDescriptor.texture2D(pixelFormat: .bgra8Unorm,
                                                              width: 256,
                                                              height: 256,
                                                              mipmapped: false)
        textureDescriptor.usage = [.shaderRead]
        
        guard let texture = device.makeTexture(descriptor: textureDescriptor) else {
            fatalError("Could not create fallback texture")
        }
        
        // Fill with a simple Romanian-themed pattern (red-yellow-blue)
        let region = MTLRegion(origin: MTLOrigin(x: 0, y: 0, z: 0),
                              size: MTLSize(width: 256, height: 256, depth: 1))
        
        var pixelData = [UInt32](repeating: 0, count: 256 * 256)
        for y in 0..<256 {
            for x in 0..<256 {
                let idx = y * 256 + x
                if y < 85 {
                    pixelData[idx] = 0xFF0000FF  // Blue
                } else if y < 170 {
                    pixelData[idx] = 0xFFFFFF00  // Yellow
                } else {
                    pixelData[idx] = 0xFF0000FF  // Red
                }
            }
        }
        
        texture.replace(region: region,
                       mipmapLevel: 0,
                       withBytes: &pixelData,
                       bytesPerRow: 256 * 4)
        
        return texture
    }
    
    // MARK: - Animation State Management
    
    func setCardAnimation(_ cardId: UUID, state: CardAnimationState) {
        currentCardAnimations[cardId] = CardAnimationState()
    }
    
    func removeCardAnimation(_ cardId: UUID) {
        currentCardAnimations.removeValue(forKey: cardId)
    }
    
    func clearAllParticles() {
        particleEmitters.removeAll()
    }
    
    func addParticleEmitter(at position: simd_float3, color: simd_float4) {
        let emitter = ParticleEmitter(position: position, color: color)
        particleEmitters.append(emitter)
    }
    
    // MARK: - Performance Monitoring
    
    private func updatePerformanceMetrics() {
        let currentTime = CACurrentMediaTime()
        let deltaTime = currentTime - lastFrameTime
        lastFrameTime = currentTime
        
        if deltaTime > 0 {
            frameRate = 1.0 / deltaTime
        }
        
        performanceMonitor?.recordMetric(name: "FPS", value: frameRate, unit: "fps")
        performanceMonitor?.recordMetric(name: "FrameTime", value: deltaTime * 1000, unit: "ms")
    }
    
    private func checkMemoryUsage() {
        // Basic memory usage check
        let info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &count) {
            $0.withMemoryRebound(to: mach_msg_type_number_t.self, capacity: 1) { countPtr in
                withUnsafeMutablePointer(to: &info) {
                    $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { infoPtr in
                        task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), infoPtr, countPtr)
                    }
                }
            }
        }
        
        if kerr == KERN_SUCCESS {
            let memoryUsageMB = Double(info.resident_size) / 1024.0 / 1024.0
            performanceMonitor?.recordMetric(name: "Memory", value: memoryUsageMB, unit: "MB")
            
            // Report memory warning if usage is high
            if memoryUsageMB > 250 { // 250MB threshold
                errorManager?.reportError(.insufficientMemory(currentUsage: memoryUsageMB),
                                        context: "Memory monitoring")
            }
        }
    }
}

// MARK: - Supporting Types

struct CardAnimationState {
    var progress: Float = 0.0
    var startTime: CFTimeInterval = 0.0
    var duration: TimeInterval = 0.5
    var animationType: String = "idle"
}

struct ParticleEmitter {
    let position: simd_float3
    let color: simd_float4
    var particleCount: Int = 50
    var lifespan: TimeInterval = 2.0
    var startTime: CFTimeInterval = CACurrentMediaTime()
}

// MARK: - C Interop for Memory Info

import Darwin

private struct mach_task_basic_info {
    var virtual_size: mach_vm_size_t = 0
    var resident_size: mach_vm_size_t = 0
    var resident_size_max: mach_vm_size_t = 0
    var user_time: time_value_t = time_value_t()
    var system_time: time_value_t = time_value_t()
    var policy: policy_t = 0
    var suspend_count: integer_t = 0
}