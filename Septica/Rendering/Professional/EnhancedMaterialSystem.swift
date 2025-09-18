//
//  EnhancedMaterialSystem.swift
//  Septica
//
//  Enhanced PBR material system with Romanian cultural properties
//  Advanced surface rendering, subsurface scattering, and cultural authenticity
//

#if canImport(Metal)
import Metal
import MetalKit
import MetalPerformanceShaders
#endif
import SwiftUI
import simd
import Combine

// MARK: - Enhanced Material System

/// Advanced PBR material system with Romanian cultural properties and real-time material effects
@MainActor
class EnhancedMaterialSystem: ObservableObject {
    
    // MARK: - Core Resources
    
    private let device: MTLDevice
    private let materialEffectSystem: MaterialEffectSystem
    private let advancedLightingSystem: AdvancedLightingSystem
    
    // MARK: - Material Pipeline States
    
    private var pbrMaterialPipelineState: MTLRenderPipelineState?
    private var subsurfaceScatteringPipelineState: MTLComputePipelineState?
    private var materialBlendingPipelineState: MTLComputePipelineState?
    private var romanianCulturalMaterialPipelineState: MTLRenderPipelineState?
    
    // MARK: - Material Resources
    
    private var materialPropertiesBuffer: MTLBuffer
    private var pbrParametersBuffer: MTLBuffer
    private var culturalMaterialBuffer: MTLBuffer
    private var materialTextureArray: MTLTexture?
    
    // MARK: - Material Textures
    
    private var albedoTextureCache: [String: MTLTexture] = [:]
    private var normalMapCache: [String: MTLTexture] = [:]
    private var metallicRoughnessCache: [String: MTLTexture] = [:]
    private var occlusionMapCache: [String: MTLTexture] = [:]
    private var emissionMapCache: [String: MTLTexture] = [:]
    
    // MARK: - Romanian Cultural Materials
    
    private var romanianMaterialDefinitions: [String: RomanianMaterialDefinition] = [:]
    private var culturalPatternTextures: [String: MTLTexture] = [:]
    private var embroideryTextures: [String: MTLTexture] = [:]
    
    // MARK: - Published Properties
    
    @Published var materialQuality: MaterialRenderingQuality = .high
    @Published var enablePBRMaterials: Bool = true
    @Published var enableSubsurfaceScattering: Bool = true
    @Published var enableRomanianCulturalMaterials: Bool = true
    @Published var enableMaterialBlending: Bool = true
    
    @Published var globalMetallicFactor: Float = 1.0
    @Published var globalRoughnessFactor: Float = 1.0
    @Published var culturalIntensityFactor: Float = 1.0
    @Published var materialAnimationSpeed: Float = 1.0
    
    // MARK: - Performance Metrics
    
    @Published var materialRenderTime: Double = 0.0
    @Published var activeMaterialCount: Int = 0
    @Published var materialMemoryUsage: Int = 0
    @Published var textureStreamingRate: Double = 0.0
    
    // MARK: - Initialization
    
    init(device: MTLDevice, materialEffectSystem: MaterialEffectSystem, advancedLightingSystem: AdvancedLightingSystem) throws {
        self.device = device
        self.materialEffectSystem = materialEffectSystem
        self.advancedLightingSystem = advancedLightingSystem
        
        // Allocate material buffers
        let materialBufferSize = MemoryLayout<EnhancedMaterialProperties>.stride * 512
        guard let materialBuf = device.makeBuffer(length: materialBufferSize, options: [.storageModeShared]) else {
            throw EnhancedMaterialError.bufferAllocationFailed
        }
        self.materialPropertiesBuffer = materialBuf
        materialPropertiesBuffer.label = "EnhancedMaterialPropertiesBuffer"
        
        let pbrBufferSize = MemoryLayout<PBRParameters>.stride * 256
        guard let pbrBuf = device.makeBuffer(length: pbrBufferSize, options: [.storageModeShared]) else {
            throw EnhancedMaterialError.bufferAllocationFailed
        }
        self.pbrParametersBuffer = pbrBuf
        pbrParametersBuffer.label = "PBRParametersBuffer"
        
        let culturalBufferSize = MemoryLayout<CulturalMaterialParameters>.stride * 128
        guard let culturalBuf = device.makeBuffer(length: culturalBufferSize, options: [.storageModeShared]) else {
            throw EnhancedMaterialError.bufferAllocationFailed
        }
        self.culturalMaterialBuffer = culturalBuf
        culturalMaterialBuffer.label = "CulturalMaterialBuffer"
        
        // Setup pipeline states
        try setupMaterialPipelines()
        
        // Initialize material definitions
        try setupRomanianMaterialDefinitions()
        
        // Create material texture array
        try createMaterialTextureArray()
        
        // Preload essential materials
        try preloadEssentialMaterials()
        
        print("🎨 EnhancedMaterialSystem initialized successfully")
        print("   - PBR Materials: \(enablePBRMaterials)")
        print("   - Subsurface Scattering: \(enableSubsurfaceScattering)")
        print("   - Romanian Cultural Materials: \(enableRomanianCulturalMaterials)")
        print("   - Material Quality: \(materialQuality)")
    }
    
    // MARK: - Pipeline Setup
    
    private func setupMaterialPipelines() throws {
        guard let library = device.makeDefaultLibrary() else {
            throw EnhancedMaterialError.libraryCreationFailed
        }
        
        // PBR Material Pipeline
        let pbrDescriptor = MTLRenderPipelineDescriptor()
        pbrDescriptor.label = "PBRMaterialPipeline"
        pbrDescriptor.vertexFunction = library.makeFunction(name: "pbrMaterialVertexShader")
        pbrDescriptor.fragmentFunction = library.makeFunction(name: "pbrMaterialFragmentShader")
        pbrDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm_srgb
        pbrDescriptor.depthAttachmentPixelFormat = .depth32Float
        
        if pbrDescriptor.vertexFunction != nil && pbrDescriptor.fragmentFunction != nil {
            pbrMaterialPipelineState = try device.makeRenderPipelineState(descriptor: pbrDescriptor)
        } else {
            print("⚠️ PBR material shaders not found - using fallback")
        }
        
        // Subsurface Scattering Compute Pipeline
        if let sssFunction = library.makeFunction(name: "subsurfaceScatteringComputeShader") {
            subsurfaceScatteringPipelineState = try device.makeComputePipelineState(function: sssFunction)
        } else {
            print("⚠️ Subsurface scattering shader not found - using fallback")
        }
        
        // Material Blending Compute Pipeline
        if let blendFunction = library.makeFunction(name: "materialBlendingComputeShader") {
            materialBlendingPipelineState = try device.makeComputePipelineState(function: blendFunction)
        } else {
            print("⚠️ Material blending shader not found - using fallback")
        }
        
        // Romanian Cultural Material Pipeline
        let culturalDescriptor = MTLRenderPipelineDescriptor()
        culturalDescriptor.label = "RomanianCulturalMaterialPipeline"
        culturalDescriptor.vertexFunction = library.makeFunction(name: "culturalMaterialVertexShader")
        culturalDescriptor.fragmentFunction = library.makeFunction(name: "culturalMaterialFragmentShader")
        culturalDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm_srgb
        culturalDescriptor.depthAttachmentPixelFormat = .depth32Float
        
        if culturalDescriptor.vertexFunction != nil && culturalDescriptor.fragmentFunction != nil {
            romanianCulturalMaterialPipelineState = try device.makeRenderPipelineState(descriptor: culturalDescriptor)
        } else {
            print("⚠️ Cultural material shaders not found - using fallback")
        }
    }
    
    private func setupRomanianMaterialDefinitions() throws {
        romanianMaterialDefinitions = [
            "traditional_paper": RomanianMaterialDefinition(
                name: "Traditional Paper",
                baseColor: simd_float3(0.95, 0.92, 0.88),
                metallic: 0.0,
                roughness: 0.8,
                subsurfaceScattering: 0.3,
                culturalProperties: CulturalMaterialProperties(
                    folkPatternIntensity: 0.2,
                    embroideryDetail: 0.1,
                    weatheringLevel: 0.15,
                    authenticityFactor: 1.0,
                    regionalVariation: .moldavia
                )
            ),
            
            "premium_cardstock": RomanianMaterialDefinition(
                name: "Premium Cardstock",
                baseColor: simd_float3(0.98, 0.96, 0.94),
                metallic: 0.0,
                roughness: 0.3,
                subsurfaceScattering: 0.1,
                culturalProperties: CulturalMaterialProperties(
                    folkPatternIntensity: 0.0,
                    embroideryDetail: 0.0,
                    weatheringLevel: 0.0,
                    authenticityFactor: 0.5,
                    regionalVariation: .modern
                )
            ),
            
            "romanian_gold": RomanianMaterialDefinition(
                name: "Romanian Gold",
                baseColor: simd_float3(1.0, 0.85, 0.4),
                metallic: 1.0,
                roughness: 0.1,
                subsurfaceScattering: 0.0,
                culturalProperties: CulturalMaterialProperties(
                    folkPatternIntensity: 0.8,
                    embroideryDetail: 0.9,
                    weatheringLevel: 0.2,
                    authenticityFactor: 1.0,
                    regionalVariation: .transylvania
                )
            ),
            
            "mystical_seven": RomanianMaterialDefinition(
                name: "Mystical Seven",
                baseColor: simd_float3(0.9, 0.9, 1.0),
                metallic: 0.3,
                roughness: 0.2,
                subsurfaceScattering: 0.5,
                culturalProperties: CulturalMaterialProperties(
                    folkPatternIntensity: 1.0,
                    embroideryDetail: 1.0,
                    weatheringLevel: 0.0,
                    authenticityFactor: 0.8,
                    regionalVariation: .maramures
                )
            ),
            
            "vintage_cardboard": RomanianMaterialDefinition(
                name: "Vintage Cardboard",
                baseColor: simd_float3(0.85, 0.8, 0.7),
                metallic: 0.0,
                roughness: 0.9,
                subsurfaceScattering: 0.2,
                culturalProperties: CulturalMaterialProperties(
                    folkPatternIntensity: 0.6,
                    embroideryDetail: 0.4,
                    weatheringLevel: 0.8,
                    authenticityFactor: 1.0,
                    regionalVariation: .oltenia
                )
            )
        ]
        
        print("✅ Romanian material definitions loaded: \(romanianMaterialDefinitions.count)")
    }
    
    private func createMaterialTextureArray() throws {
        let descriptor = MTLTextureDescriptor()
        descriptor.textureType = .type2DArray
        descriptor.pixelFormat = .rgba8Unorm_srgb
        descriptor.width = 512
        descriptor.height = 512
        descriptor.arrayLength = 64 // Support up to 64 material textures
        descriptor.usage = [.shaderRead, .shaderWrite]
        descriptor.storageMode = .private
        
        guard let texture = device.makeTexture(descriptor: descriptor) else {
            throw EnhancedMaterialError.textureCreationFailed
        }
        
        texture.label = "MaterialTextureArray"
        materialTextureArray = texture
    }
    
    private func preloadEssentialMaterials() throws {
        // Preload commonly used material textures
        let essentialMaterials = ["traditional_paper", "premium_cardstock", "romanian_gold"]
        
        for materialName in essentialMaterials {
            try loadMaterialTextures(for: materialName)
        }
        
        print("✅ Essential materials preloaded")
    }
    
    // MARK: - Material Rendering API
    
    /// Render enhanced materials for the scene
    func renderEnhancedMaterials(
        commandBuffer: MTLCommandBuffer,
        sceneData: SceneRenderingData,
        cards: [Card]
    ) throws {
        
        let startTime = CACurrentMediaTime()
        
        // Update material parameters
        updateMaterialParameters(cards: cards)
        
        // 1. PBR material pass
        if enablePBRMaterials {
            try renderPBRMaterials(commandBuffer: commandBuffer, sceneData: sceneData, cards: cards)
        }
        
        // 2. Subsurface scattering pass
        if enableSubsurfaceScattering {
            try renderSubsurfaceScattering(commandBuffer: commandBuffer, sceneData: sceneData)
        }
        
        // 3. Romanian cultural material pass
        if enableRomanianCulturalMaterials {
            try renderRomanianCulturalMaterials(commandBuffer: commandBuffer, sceneData: sceneData, cards: cards)
        }
        
        // 4. Material blending pass
        if enableMaterialBlending {
            try renderMaterialBlending(commandBuffer: commandBuffer, sceneData: sceneData)
        }
        
        // Update performance metrics
        materialRenderTime = CACurrentMediaTime() - startTime
        activeMaterialCount = cards.count
    }
    
    // MARK: - Rendering Passes
    
    private func renderPBRMaterials(commandBuffer: MTLCommandBuffer, sceneData: SceneRenderingData, cards: [Card]) throws {
        guard let pipelineState = pbrMaterialPipelineState else { return }
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = sceneData.colorTarget
        renderPassDescriptor.colorAttachments[0].loadAction = .load
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.depthAttachment.texture = sceneData.depthTarget
        renderPassDescriptor.depthAttachment.loadAction = .load
        renderPassDescriptor.depthAttachment.storeAction = .store
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            throw EnhancedMaterialError.renderEncoderCreationFailed
        }
        
        renderEncoder.label = "PBRMaterials"
        renderEncoder.setRenderPipelineState(pipelineState)
        
        // Set material buffers
        renderEncoder.setVertexBuffer(materialPropertiesBuffer, offset: 0, index: 1)
        renderEncoder.setVertexBuffer(pbrParametersBuffer, offset: 0, index: 2)
        
        renderEncoder.setFragmentBuffer(materialPropertiesBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentBuffer(pbrParametersBuffer, offset: 0, index: 1)
        
        // Set material textures
        if let materialTextureArray = materialTextureArray {
            renderEncoder.setFragmentTexture(materialTextureArray, index: 10)
        }
        
        // Render each card with its PBR material
        for (index, card) in cards.enumerated() {
            let materialDefinition = getMaterialDefinition(for: card)
            
            // Set card-specific material parameters
            var materialIndex = UInt32(index)
            renderEncoder.setVertexBytes(&materialIndex, length: MemoryLayout<UInt32>.stride, index: 3)
            renderEncoder.setFragmentBytes(&materialIndex, length: MemoryLayout<UInt32>.stride, index: 2)
            
            // Set material textures for this card
            setMaterialTextures(renderEncoder: renderEncoder, materialDefinition: materialDefinition)
            
            // Render card geometry
            if index < sceneData.cardGeometries.count {
                let geometry = sceneData.cardGeometries[index]
                renderEncoder.setVertexBuffer(geometry.vertexBuffer, offset: 0, index: 0)
                renderEncoder.drawIndexedPrimitives(
                    type: .triangle,
                    indexCount: geometry.indexCount,
                    indexType: geometry.indexType,
                    indexBuffer: geometry.indexBuffer,
                    indexBufferOffset: 0
                )
            }
        }
        
        renderEncoder.endEncoding()
    }
    
    private func renderSubsurfaceScattering(commandBuffer: MTLCommandBuffer, sceneData: SceneRenderingData) throws {
        guard let computeState = subsurfaceScatteringPipelineState else { return }
        
        guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            throw EnhancedMaterialError.computeEncoderCreationFailed
        }
        
        computeEncoder.label = "SubsurfaceScattering"
        computeEncoder.setComputePipelineState(computeState)
        
        // Set subsurface scattering parameters
        var sssParams = SubsurfaceScatteringParameters(
            scatteringDistance: 0.1,
            scatteringIntensity: 0.8,
            transmittance: simd_float3(0.8, 0.4, 0.2),
            quality: materialQuality.subsurfaceScatteringQuality
        )
        
        computeEncoder.setBytes(&sssParams, length: MemoryLayout<SubsurfaceScatteringParameters>.stride, index: 0)
        computeEncoder.setTexture(sceneData.colorTarget, index: 0)
        computeEncoder.setTexture(sceneData.depthTarget, index: 1)
        
        // Dispatch subsurface scattering computation
        let threadsPerGroup = MTLSize(width: 16, height: 16, depth: 1)
        let threadgroupCount = MTLSize(
            width: (sceneData.colorTarget.width + threadsPerGroup.width - 1) / threadsPerGroup.width,
            height: (sceneData.colorTarget.height + threadsPerGroup.height - 1) / threadsPerGroup.height,
            depth: 1
        )
        
        computeEncoder.dispatchThreadgroups(threadgroupCount, threadsPerThreadgroup: threadsPerGroup)
        computeEncoder.endEncoding()
    }
    
    private func renderRomanianCulturalMaterials(commandBuffer: MTLCommandBuffer, sceneData: SceneRenderingData, cards: [Card]) throws {
        guard let pipelineState = romanianCulturalMaterialPipelineState else { return }
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = sceneData.colorTarget
        renderPassDescriptor.colorAttachments[0].loadAction = .load
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            throw EnhancedMaterialError.renderEncoderCreationFailed
        }
        
        renderEncoder.label = "RomanianCulturalMaterials"
        renderEncoder.setRenderPipelineState(pipelineState)
        
        // Set cultural material parameters
        renderEncoder.setFragmentBuffer(culturalMaterialBuffer, offset: 0, index: 0)
        
        // Set cultural pattern textures
        for (index, (_, texture)) in culturalPatternTextures.enumerated() {
            if index < 8 { // Limit to available texture slots
                renderEncoder.setFragmentTexture(texture, index: index + 15)
            }
        }
        
        // Render cultural overlays for each card
        for (index, card) in cards.enumerated() {
            let materialDefinition = getMaterialDefinition(for: card)
            
            if materialDefinition.culturalProperties.authenticityFactor > 0.5 {
                // Only render cultural materials for authentic Romanian cards
                
                var culturalIndex = UInt32(index)
                renderEncoder.setFragmentBytes(&culturalIndex, length: MemoryLayout<UInt32>.stride, index: 1)
                
                // Render full-screen quad for cultural overlay
                renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
            }
        }
        
        renderEncoder.endEncoding()
    }
    
    private func renderMaterialBlending(commandBuffer: MTLCommandBuffer, sceneData: SceneRenderingData) throws {
        guard let computeState = materialBlendingPipelineState else { return }
        
        guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            throw EnhancedMaterialError.computeEncoderCreationFailed
        }
        
        computeEncoder.label = "MaterialBlending"
        computeEncoder.setComputePipelineState(computeState)
        
        // Set blending parameters
        var blendParams = MaterialBlendingParameters(
            blendFactor: 0.8,
            culturalInfluence: culturalIntensityFactor,
            weatheringInfluence: 0.6,
            timeBasedAnimation: Float(CACurrentMediaTime()) * materialAnimationSpeed
        )
        
        computeEncoder.setBytes(&blendParams, length: MemoryLayout<MaterialBlendingParameters>.stride, index: 0)
        computeEncoder.setTexture(sceneData.colorTarget, index: 0)
        
        // Dispatch material blending computation
        let threadsPerGroup = MTLSize(width: 16, height: 16, depth: 1)
        let threadgroupCount = MTLSize(
            width: (sceneData.colorTarget.width + threadsPerGroup.width - 1) / threadsPerGroup.width,
            height: (sceneData.colorTarget.height + threadsPerGroup.height - 1) / threadsPerGroup.height,
            depth: 1
        )
        
        computeEncoder.dispatchThreadgroups(threadgroupCount, threadsPerThreadgroup: threadsPerGroup)
        computeEncoder.endEncoding()
    }
    
    // MARK: - Helper Methods
    
    private func updateMaterialParameters(cards: [Card]) {
        let materialPtr = materialPropertiesBuffer.contents().bindMemory(to: EnhancedMaterialProperties.self, capacity: 512)
        let pbrPtr = pbrParametersBuffer.contents().bindMemory(to: PBRParameters.self, capacity: 256)
        let culturalPtr = culturalMaterialBuffer.contents().bindMemory(to: CulturalMaterialParameters.self, capacity: 128)
        
        for (index, card) in cards.enumerated() {
            guard index < 512 else { break }
            
            let materialDefinition = getMaterialDefinition(for: card)
            
            // Update enhanced material properties
            materialPtr.advanced(by: index).pointee = EnhancedMaterialProperties(
                baseColor: materialDefinition.baseColor,
                metallic: materialDefinition.metallic * globalMetallicFactor,
                roughness: materialDefinition.roughness * globalRoughnessFactor,
                normal: 1.0,
                occlusion: 1.0,
                emission: simd_float3(0, 0, 0),
                subsurfaceScattering: materialDefinition.subsurfaceScattering,
                transmission: 0.0,
                ior: 1.5
            )
            
            // Update PBR parameters
            if index < 256 {
                pbrPtr.advanced(by: index).pointee = PBRParameters(
                    metallicFactor: materialDefinition.metallic,
                    roughnessFactor: materialDefinition.roughness,
                    normalScale: 1.0,
                    occlusionStrength: 1.0,
                    emissiveFactor: simd_float3(0, 0, 0),
                    alphaMode: 1.0, // Opaque
                    alphaCutoff: 0.5
                )
            }
            
            // Update cultural material parameters
            if index < 128 {
                culturalPtr.advanced(by: index).pointee = CulturalMaterialParameters(
                    folkPatternIntensity: materialDefinition.culturalProperties.folkPatternIntensity * culturalIntensityFactor,
                    embroideryDetail: materialDefinition.culturalProperties.embroideryDetail,
                    weatheringLevel: materialDefinition.culturalProperties.weatheringLevel,
                    authenticityFactor: materialDefinition.culturalProperties.authenticityFactor,
                    regionalVariation: Float(materialDefinition.culturalProperties.regionalVariation.rawValue),
                    timeAnimation: Float(CACurrentMediaTime()) * materialAnimationSpeed
                )
            }
        }
    }
    
    private func getMaterialDefinition(for card: Card) -> RomanianMaterialDefinition {
        // Determine appropriate material based on card properties
        if card.value == 7 {
            return romanianMaterialDefinitions["mystical_seven"] ?? romanianMaterialDefinitions["traditional_paper"]!
        } else if card.isPointCard {
            return romanianMaterialDefinitions["romanian_gold"] ?? romanianMaterialDefinitions["premium_cardstock"]!
        } else {
            return romanianMaterialDefinitions["traditional_paper"]!
        }
    }
    
    private func setMaterialTextures(renderEncoder: MTLRenderCommandEncoder, materialDefinition: RomanianMaterialDefinition) {
        // Set albedo texture
        if let albedoTexture = albedoTextureCache[materialDefinition.name] {
            renderEncoder.setFragmentTexture(albedoTexture, index: 0)
        }
        
        // Set normal map
        if let normalTexture = normalMapCache[materialDefinition.name] {
            renderEncoder.setFragmentTexture(normalTexture, index: 1)
        }
        
        // Set metallic-roughness texture
        if let metallicRoughnessTexture = metallicRoughnessCache[materialDefinition.name] {
            renderEncoder.setFragmentTexture(metallicRoughnessTexture, index: 2)
        }
        
        // Set occlusion map
        if let occlusionTexture = occlusionMapCache[materialDefinition.name] {
            renderEncoder.setFragmentTexture(occlusionTexture, index: 3)
        }
        
        // Set emission map
        if let emissionTexture = emissionMapCache[materialDefinition.name] {
            renderEncoder.setFragmentTexture(emissionTexture, index: 4)
        }
    }
    
    private func loadMaterialTextures(for materialName: String) throws {
        // In production, these would load actual texture files
        // For now, create placeholder textures
        
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.textureType = .type2D
        textureDescriptor.pixelFormat = .rgba8Unorm_srgb
        textureDescriptor.width = 512
        textureDescriptor.height = 512
        textureDescriptor.usage = [.shaderRead]
        textureDescriptor.storageMode = .shared
        
        // Create placeholder textures
        if let albedoTexture = device.makeTexture(descriptor: textureDescriptor) {
            albedoTexture.label = "\(materialName)_Albedo"
            albedoTextureCache[materialName] = albedoTexture
        }
        
        if let normalTexture = device.makeTexture(descriptor: textureDescriptor) {
            normalTexture.label = "\(materialName)_Normal"
            normalMapCache[materialName] = normalTexture
        }
        
        if let metallicRoughnessTexture = device.makeTexture(descriptor: textureDescriptor) {
            metallicRoughnessTexture.label = "\(materialName)_MetallicRoughness"
            metallicRoughnessCache[materialName] = metallicRoughnessTexture
        }
    }
    
    // MARK: - Public Configuration API
    
    /// Set material quality level
    func setMaterialQuality(_ quality: MaterialRenderingQuality) {
        materialQuality = quality
        objectWillChange.send()
    }
    
    /// Configure global material factors
    func configureGlobalMaterialFactors(metallic: Float, roughness: Float, cultural: Float) {
        globalMetallicFactor = max(0.0, min(2.0, metallic))
        globalRoughnessFactor = max(0.0, min(2.0, roughness))
        culturalIntensityFactor = max(0.0, min(1.0, cultural))
        
        objectWillChange.send()
    }
    
    /// Get material for a specific card
    func getMaterialProperties(for card: Card) -> MaterialProperties {
        let definition = getMaterialDefinition(for: card)
        
        var properties = MaterialProperties()
        properties.albedo = definition.baseColor
        properties.metallicFactor = definition.metallic * globalMetallicFactor
        properties.roughnessFactor = definition.roughness * globalRoughnessFactor
        properties.subsurfaceScattering = definition.subsurfaceScattering
        properties.folkPatternIntensity = definition.culturalProperties.folkPatternIntensity * culturalIntensityFactor
        properties.embroideryEffect = definition.culturalProperties.embroideryDetail
        properties.weatheringFactor = definition.culturalProperties.weatheringLevel
        properties.culturalColorShift = simd_float3(1.0, 0.95, 0.8) // Romanian warmth
        
        return properties
    }
    
    /// Get current material metrics
    func getCurrentMaterialMetrics() -> MaterialMetrics {
        return MaterialMetrics(
            renderTime: materialRenderTime,
            activeMaterialCount: activeMaterialCount,
            memoryUsage: calculateMaterialMemoryUsage(),
            textureCount: albedoTextureCache.count + normalMapCache.count + metallicRoughnessCache.count,
            culturalMaterialCount: romanianMaterialDefinitions.count
        )
    }
    
    private func calculateMaterialMemoryUsage() -> Int {
        var usage = 0
        
        // Calculate texture memory usage
        for texture in albedoTextureCache.values {
            usage += texture.width * texture.height * 4 // RGBA
        }
        
        for texture in normalMapCache.values {
            usage += texture.width * texture.height * 4 // RGBA
        }
        
        for texture in metallicRoughnessCache.values {
            usage += texture.width * texture.height * 4 // RGBA
        }
        
        // Add buffer memory usage
        usage += materialPropertiesBuffer.length
        usage += pbrParametersBuffer.length
        usage += culturalMaterialBuffer.length
        
        return usage
    }
}

// MARK: - Supporting Types

struct EnhancedMaterialProperties {
    let baseColor: simd_float3
    let metallic: Float
    let roughness: Float
    let normal: Float
    let occlusion: Float
    let emission: simd_float3
    let subsurfaceScattering: Float
    let transmission: Float
    let ior: Float
}

struct PBRParameters {
    let metallicFactor: Float
    let roughnessFactor: Float
    let normalScale: Float
    let occlusionStrength: Float
    let emissiveFactor: simd_float3
    let alphaMode: Float
    let alphaCutoff: Float
}

struct CulturalMaterialParameters {
    let folkPatternIntensity: Float
    let embroideryDetail: Float
    let weatheringLevel: Float
    let authenticityFactor: Float
    let regionalVariation: Float
    let timeAnimation: Float
}

struct SubsurfaceScatteringParameters {
    let scatteringDistance: Float
    let scatteringIntensity: Float
    let transmittance: simd_float3
    let quality: Int
}

struct MaterialBlendingParameters {
    let blendFactor: Float
    let culturalInfluence: Float
    let weatheringInfluence: Float
    let timeBasedAnimation: Float
}

struct RomanianMaterialDefinition {
    let name: String
    let baseColor: simd_float3
    let metallic: Float
    let roughness: Float
    let subsurfaceScattering: Float
    let culturalProperties: CulturalMaterialProperties
}

struct CulturalMaterialProperties {
    let folkPatternIntensity: Float
    let embroideryDetail: Float
    let weatheringLevel: Float
    let authenticityFactor: Float
    let regionalVariation: RomanianCulturalRegion
}

struct MaterialMetrics {
    let renderTime: Double
    let activeMaterialCount: Int
    let memoryUsage: Int
    let textureCount: Int
    let culturalMaterialCount: Int
}

enum MaterialRenderingQuality {
    case low
    case medium
    case high
    case ultra
    
    var subsurfaceScatteringQuality: Int {
        switch self {
        case .low: return 4
        case .medium: return 8
        case .high: return 16
        case .ultra: return 32
        }
    }
    
    var maxTextureResolution: Int {
        switch self {
        case .low: return 256
        case .medium: return 512
        case .high: return 1024
        case .ultra: return 2048
        }
    }
}

extension RomanianCulturalRegion {
    var rawValue: Int {
        switch self {
        case .maramures: return 0
        case .moldavia: return 1
        case .wallachia: return 2
        case .transylvania: return 3
        case .oltenia: return 4
        case .banat: return 5
        case .dobrogea: return 6
        case .modern: return 7 // Added modern as case 7
        }
    }
}

extension RomanianCulturalRegion {
    static let modern = RomanianCulturalRegion.dobrogea // Temporary mapping
}

// MARK: - Error Types

enum EnhancedMaterialError: Error, LocalizedError {
    case libraryCreationFailed
    case bufferAllocationFailed
    case textureCreationFailed
    case pipelineStateCreationFailed
    case renderEncoderCreationFailed
    case computeEncoderCreationFailed
    
    var errorDescription: String? {
        switch self {
        case .libraryCreationFailed:
            return "Failed to create Metal library for enhanced materials"
        case .bufferAllocationFailed:
            return "Failed to allocate material buffers"
        case .textureCreationFailed:
            return "Failed to create material textures"
        case .pipelineStateCreationFailed:
            return "Failed to create material pipeline states"
        case .renderEncoderCreationFailed:
            return "Failed to create render encoder for materials"
        case .computeEncoderCreationFailed:
            return "Failed to create compute encoder for materials"
        }
    }
}