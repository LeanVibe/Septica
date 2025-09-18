//
//  MaterialEffect.swift
//  Septica
//
//  Professional material properties system for ShuffleCats-quality card rendering
//  Provides realistic material physics, surface properties, and Romanian cultural materials
//

#if canImport(Metal)
import Metal
import MetalKit
#endif
import SwiftUI
import simd
import Combine

// MARK: - Material Properties

/// Comprehensive material properties for professional card rendering
struct MaterialProperties {
    
    // MARK: - Basic Properties
    
    var albedo: simd_float3 = simd_float3(1.0, 1.0, 1.0)           // Base color
    var metallicFactor: Float = 0.0                                 // Metallic vs dielectric
    var roughnessFactor: Float = 0.5                               // Surface roughness
    var normalScale: Float = 1.0                                   // Normal map intensity
    var occlusionStrength: Float = 1.0                            // Ambient occlusion
    var emissiveFactor: simd_float3 = simd_float3(0.0, 0.0, 0.0) // Emission color
    
    // MARK: - Advanced Properties
    
    var subsurfaceScattering: Float = 0.0                         // SSS intensity
    var transmission: Float = 0.0                                  // Transparency
    var refractionIndex: Float = 1.0                              // IOR for refraction
    var clearcoat: Float = 0.0                                    // Clearcoat layer
    var clearcoatRoughness: Float = 0.0                           // Clearcoat roughness
    var sheen: Float = 0.0                                        // Fabric-like sheen
    var sheenTint: simd_float3 = simd_float3(1.0, 1.0, 1.0)     // Sheen tint
    
    // MARK: - Romanian Cultural Properties
    
    var folkPatternIntensity: Float = 0.0                         // Traditional pattern overlay
    var embroideryEffect: Float = 0.0                             // Embroidery simulation
    var goldLeafEffect: Float = 0.0                               // Gold leaf accents
    var weatheringFactor: Float = 0.0                             // Age/wear simulation
    var culturalColorShift: simd_float3 = simd_float3(1.0, 1.0, 1.0) // Cultural color tinting
    
    // MARK: - Animation Properties
    
    var animationTime: Float = 0.0                                // For animated effects
    var pulseIntensity: Float = 0.0                               // Pulsing effects
    var glowIntensity: Float = 0.0                                // Glow effects
    var magicEffectStrength: Float = 0.0                          // Special card effects
    
    // MARK: - Preset Materials
    
    static let traditionalPaper = MaterialProperties(
        albedo: simd_float3(0.95, 0.92, 0.88),
        metallicFactor: 0.0,
        roughnessFactor: 0.8,
        subsurfaceScattering: 0.3,
        folkPatternIntensity: 0.2,
        weatheringFactor: 0.1
    )
    
    static let premiumCardstock = MaterialProperties(
        albedo: simd_float3(0.98, 0.96, 0.94),
        metallicFactor: 0.0,
        roughnessFactor: 0.3,
        subsurfaceScattering: 0.1,
        clearcoat: 0.5,
        clearcoatRoughness: 0.1
    )
    
    static let romanianGold = MaterialProperties(
        albedo: simd_float3(1.0, 0.85, 0.4),
        metallicFactor: 1.0,
        roughnessFactor: 0.1,
        emissiveFactor: simd_float3(0.2, 0.15, 0.05),
        goldLeafEffect: 1.0,
        culturalColorShift: simd_float3(1.1, 0.9, 0.6)
    )
    
    static let magicalSeven = MaterialProperties(
        albedo: simd_float3(0.9, 0.9, 1.0),
        metallicFactor: 0.3,
        roughnessFactor: 0.2,
        emissiveFactor: simd_float3(0.1, 0.1, 0.3),
        pulseIntensity: 0.5,
        glowIntensity: 0.8,
        magicEffectStrength: 1.0
    )
    
    static let vintageCardboard = MaterialProperties(
        albedo: simd_float3(0.85, 0.8, 0.7),
        metallicFactor: 0.0,
        roughnessFactor: 0.9,
        folkPatternIntensity: 0.4,
        weatheringFactor: 0.6,
        culturalColorShift: simd_float3(1.0, 0.95, 0.85)
    )
}

// MARK: - Material Effect System

/// Advanced material effect system for professional card rendering
@MainActor
class MaterialEffectSystem: ObservableObject {
    
    // MARK: - Core Resources
    
    private let device: MTLDevice
    private var computePipelineState: MTLComputePipelineState?
    private var materialBuffer: MTLBuffer
    private var effectParametersBuffer: MTLBuffer
    
    // MARK: - Effect Management
    
    @Published var activeEffects: [MaterialEffect] = []
    @Published var globalEffectIntensity: Float = 1.0
    @Published var enableRomanianEffects: Bool = true
    @Published var enableAdvancedMaterials: Bool = true
    
    // MARK: - Performance Settings
    
    @Published var effectQuality: MaterialQuality = .high
    @Published var enableRealTimeReflections: Bool = true
    @Published var enableSubsurfaceScattering: Bool = true
    @Published var enableParallaxMapping: Bool = true
    
    // MARK: - Animation System
    
    private var effectTimer: Timer?
    private var lastUpdateTime: CFTimeInterval = 0
    
    // MARK: - Initialization
    
    init(device: MTLDevice) {
        self.device = device
        
        // Allocate buffers
        let materialBufferSize = MemoryLayout<MaterialProperties>.stride * 256
        guard let materialBuf = device.makeBuffer(length: materialBufferSize, options: [.storageModeShared]) else {
            fatalError("Failed to allocate material buffer")
        }
        self.materialBuffer = materialBuf
        materialBuffer.label = "MaterialBuffer"
        
        let effectBufferSize = MemoryLayout<MaterialEffectParameters>.stride * 128
        guard let effectBuf = device.makeBuffer(length: effectBufferSize, options: [.storageModeShared]) else {
            fatalError("Failed to allocate effect parameters buffer")
        }
        self.effectParametersBuffer = effectBuf
        effectParametersBuffer.label = "EffectParametersBuffer"
        
        // Setup compute pipeline
        setupComputePipeline()
        
        // Start effect update loop
        startEffectUpdates()
    }
    
    // MARK: - Setup
    
    private func setupComputePipeline() {
        guard let library = device.makeDefaultLibrary(),
              let function = library.makeFunction(name: "materialEffectComputeShader") else {
            print("⚠️ Material effect compute shader not found - using fallback")
            return
        }
        
        do {
            computePipelineState = try device.makeComputePipelineState(function: function)
        } catch {
            print("⚠️ Failed to create material effect compute pipeline: \(error)")
        }
    }
    
    private func startEffectUpdates() {
        lastUpdateTime = CACurrentMediaTime()
        effectTimer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateEffects()
            }
        }
    }
    
    // MARK: - Effect Management
    
    /// Add a material effect
    func addEffect(_ effect: MaterialEffect) {
        activeEffects.append(effect)
    }
    
    /// Remove a material effect
    func removeEffect(withId id: UUID) {
        activeEffects.removeAll { $0.id == id }
    }
    
    /// Clear all material effects
    func clearAllEffects() {
        activeEffects.removeAll()
    }
    
    /// Apply material preset to card
    func applyMaterialPreset(_ preset: MaterialPreset, to cardId: UUID, animated: Bool = true) {
        let properties = preset.properties
        let effect = MaterialEffect(
            id: UUID(),
            type: .materialTransition,
            cardId: cardId,
            targetProperties: properties,
            duration: animated ? 1.0 : 0.0,
            startTime: CACurrentMediaTime()
        )
        addEffect(effect)
    }
    
    /// Create Romanian cultural material effect
    func createRomanianCulturalEffect(for cardId: UUID, intensity: Float = 1.0) -> MaterialEffect {
        var properties = MaterialProperties.traditionalPaper
        properties.folkPatternIntensity = intensity * 0.8
        properties.embroideryEffect = intensity * 0.6
        properties.culturalColorShift = simd_float3(1.0 + intensity * 0.2, 1.0, 1.0 - intensity * 0.1)
        properties.animationTime = 0.0
        
        return MaterialEffect(
            id: UUID(),
            type: .romanianCultural,
            cardId: cardId,
            targetProperties: properties,
            duration: 2.0,
            startTime: CACurrentMediaTime(),
            intensity: intensity
        )
    }
    
    /// Create seven card special effect
    func createSevenCardEffect(for cardId: UUID) -> MaterialEffect {
        var properties = MaterialProperties.magicalSeven
        properties.magicEffectStrength = 1.0
        properties.glowIntensity = 1.0
        properties.pulseIntensity = 0.8
        properties.emissiveFactor = simd_float3(0.2, 0.2, 0.4)
        
        return MaterialEffect(
            id: UUID(),
            type: .sevenSpecial,
            cardId: cardId,
            targetProperties: properties,
            duration: 1.5,
            startTime: CACurrentMediaTime(),
            intensity: 1.0
        )
    }
    
    /// Create gold highlight effect
    func createGoldHighlightEffect(for cardId: UUID, intensity: Float = 1.0) -> MaterialEffect {
        var properties = MaterialProperties.romanianGold
        properties.goldLeafEffect = intensity
        properties.emissiveFactor = simd_float3(0.3, 0.25, 0.1) * intensity
        properties.glowIntensity = intensity * 0.7
        
        return MaterialEffect(
            id: UUID(),
            type: .goldHighlight,
            cardId: cardId,
            targetProperties: properties,
            duration: 1.0,
            startTime: CACurrentMediaTime(),
            intensity: intensity
        )
    }
    
    /// Create weathering effect
    func createWeatheringEffect(for cardId: UUID, age: Float = 0.5) -> MaterialEffect {
        var properties = MaterialProperties.vintageCardboard
        properties.weatheringFactor = age
        properties.roughnessFactor = 0.5 + age * 0.4
        properties.albedo = simd_float3(0.9 - age * 0.2, 0.85 - age * 0.15, 0.75 - age * 0.1)
        
        return MaterialEffect(
            id: UUID(),
            type: .weathering,
            cardId: cardId,
            targetProperties: properties,
            duration: 0.5,
            startTime: CACurrentMediaTime(),
            intensity: age
        )
    }
    
    // MARK: - Effect Updates
    
    private func updateEffects() {
        let currentTime = CACurrentMediaTime()
        let deltaTime = Float(currentTime - lastUpdateTime)
        lastUpdateTime = currentTime
        
        // Update active effects
        for i in 0..<activeEffects.count {
            activeEffects[i].update(deltaTime: deltaTime, currentTime: currentTime)
        }
        
        // Remove completed effects
        activeEffects.removeAll { !$0.isActive }
    }
    
    // MARK: - Rendering Integration
    
    /// Render material effects using Metal compute shaders
    func renderEffects(renderEncoder: MTLRenderCommandEncoder, currentFrameData: FrameData) {
        guard enableAdvancedMaterials,
              let _ = computePipelineState else { return }
        
        // Update material buffers
        updateMaterialBuffers()
        
        // Set up compute pass for material effects
        // This would typically be done in a separate compute command encoder
        // For now, we'll update the material properties directly
        
        updateMaterialPropertiesForCurrentFrame(currentFrameData)
    }
    
    private func updateMaterialBuffers() {
        let materialPtr = materialBuffer.contents().bindMemory(to: MaterialProperties.self, capacity: 256)
        
        // Update material properties for each active effect
        for (index, effect) in activeEffects.enumerated() {
            guard index < 256 else { break }
            materialPtr.advanced(by: index).pointee = effect.currentProperties
        }
    }
    
    private func updateMaterialPropertiesForCurrentFrame(_ frameData: FrameData) {
        // Apply global time-based animations to materials
        let time = Float(frameData.timestamp)
        
        for i in 0..<activeEffects.count {
            var effect = activeEffects[i]
            
            // Apply time-based animations
            switch effect.type {
            case .sevenSpecial:
                effect.currentProperties.pulseIntensity = 0.5 + 0.3 * sin(time * 4.0)
                effect.currentProperties.glowIntensity = 0.8 + 0.2 * sin(time * 2.0)
                effect.currentProperties.animationTime = time
                
            case .romanianCultural:
                effect.currentProperties.folkPatternIntensity *= (1.0 + 0.1 * sin(time * 1.5))
                effect.currentProperties.embroideryEffect *= (1.0 + 0.05 * sin(time * 3.0))
                
            case .goldHighlight:
                effect.currentProperties.emissiveFactor *= (1.0 + 0.2 * sin(time * 6.0))
                effect.currentProperties.metallicFactor = min(1.0, effect.currentProperties.metallicFactor * (1.0 + 0.1 * sin(time * 2.0)))
                
            case .materialTransition, .weathering:
                // Static effects - no animation needed
                break
            }
            
            activeEffects[i] = effect
        }
    }
    
    // MARK: - SwiftUI Integration
    
    /// Get material properties for a specific card
    func getMaterialProperties(for cardId: UUID) -> MaterialProperties {
        let effects = activeEffects.filter { $0.cardId == cardId }
        
        if effects.isEmpty {
            return .premiumCardstock
        }
        
        // Blend multiple effects
        var finalProperties = effects.first!.currentProperties
        
        for effect in effects.dropFirst() {
            finalProperties = blendMaterialProperties(finalProperties, effect.currentProperties, blendFactor: effect.intensity)
        }
        
        return finalProperties
    }
    
    private func blendMaterialProperties(_ a: MaterialProperties, _ b: MaterialProperties, blendFactor: Float) -> MaterialProperties {
        var result = a
        
        result.albedo = simd_mix(a.albedo, b.albedo, simd_float3(repeating: blendFactor))
        result.metallicFactor = a.metallicFactor + (b.metallicFactor - a.metallicFactor) * blendFactor
        result.roughnessFactor = a.roughnessFactor + (b.roughnessFactor - a.roughnessFactor) * blendFactor
        result.emissiveFactor = simd_mix(a.emissiveFactor, b.emissiveFactor, simd_float3(repeating: blendFactor))
        result.glowIntensity = a.glowIntensity + (b.glowIntensity - a.glowIntensity) * blendFactor
        result.pulseIntensity = a.pulseIntensity + (b.pulseIntensity - a.pulseIntensity) * blendFactor
        result.folkPatternIntensity = a.folkPatternIntensity + (b.folkPatternIntensity - a.folkPatternIntensity) * blendFactor
        result.embroideryEffect = a.embroideryEffect + (b.embroideryEffect - a.embroideryEffect) * blendFactor
        result.goldLeafEffect = a.goldLeafEffect + (b.goldLeafEffect - a.goldLeafEffect) * blendFactor
        result.weatheringFactor = a.weatheringFactor + (b.weatheringFactor - a.weatheringFactor) * blendFactor
        result.culturalColorShift = simd_mix(a.culturalColorShift, b.culturalColorShift, simd_float3(repeating: blendFactor))
        
        return result
    }
}

// MARK: - Material Effect

/// Individual material effect that can be applied to cards
struct MaterialEffect {
    let id: UUID
    let type: MaterialEffectType
    let cardId: UUID
    var targetProperties: MaterialProperties
    var currentProperties: MaterialProperties
    let duration: TimeInterval
    let startTime: CFTimeInterval
    var intensity: Float
    
    private var startProperties: MaterialProperties
    
    init(id: UUID, type: MaterialEffectType, cardId: UUID, targetProperties: MaterialProperties, duration: TimeInterval, startTime: CFTimeInterval, intensity: Float = 1.0) {
        self.id = id
        self.type = type
        self.cardId = cardId
        self.targetProperties = targetProperties
        self.currentProperties = .premiumCardstock
        self.duration = duration
        self.startTime = startTime
        self.intensity = intensity
        self.startProperties = .premiumCardstock
    }
    
    var progress: Float {
        guard duration > 0 else { return 1.0 }
        let elapsed = CACurrentMediaTime() - startTime
        return min(Float(elapsed / duration), 1.0)
    }
    
    var isActive: Bool {
        return progress < 1.0
    }
    
    mutating func update(deltaTime: Float, currentTime: CFTimeInterval) {
        let easedProgress = easeInOut(progress)
        currentProperties = interpolateMaterialProperties(startProperties, targetProperties, progress: easedProgress)
    }
    
    private func easeInOut(_ t: Float) -> Float {
        return t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2
    }
    
    private func interpolateMaterialProperties(_ start: MaterialProperties, _ target: MaterialProperties, progress: Float) -> MaterialProperties {
        var result = start
        
        result.albedo = simd_mix(start.albedo, target.albedo, simd_float3(repeating: progress))
        result.metallicFactor = start.metallicFactor + (target.metallicFactor - start.metallicFactor) * progress
        result.roughnessFactor = start.roughnessFactor + (target.roughnessFactor - start.roughnessFactor) * progress
        result.emissiveFactor = simd_mix(start.emissiveFactor, target.emissiveFactor, simd_float3(repeating: progress))
        result.glowIntensity = start.glowIntensity + (target.glowIntensity - start.glowIntensity) * progress
        result.pulseIntensity = start.pulseIntensity + (target.pulseIntensity - start.pulseIntensity) * progress
        result.folkPatternIntensity = start.folkPatternIntensity + (target.folkPatternIntensity - start.folkPatternIntensity) * progress
        result.embroideryEffect = start.embroideryEffect + (target.embroideryEffect - start.embroideryEffect) * progress
        result.goldLeafEffect = start.goldLeafEffect + (target.goldLeafEffect - start.goldLeafEffect) * progress
        result.weatheringFactor = start.weatheringFactor + (target.weatheringFactor - start.weatheringFactor) * progress
        result.culturalColorShift = simd_mix(start.culturalColorShift, target.culturalColorShift, simd_float3(repeating: progress))
        
        return result
    }
}

// MARK: - Supporting Types

enum MaterialEffectType {
    case materialTransition
    case romanianCultural
    case sevenSpecial
    case goldHighlight
    case weathering
}

enum MaterialPreset {
    case traditionalPaper
    case premiumCardstock
    case romanianGold
    case magicalSeven
    case vintageCardboard
    
    var properties: MaterialProperties {
        switch self {
        case .traditionalPaper:
            return .traditionalPaper
        case .premiumCardstock:
            return .premiumCardstock
        case .romanianGold:
            return .romanianGold
        case .magicalSeven:
            return .magicalSeven
        case .vintageCardboard:
            return .vintageCardboard
        }
    }
}

enum MaterialQuality {
    case low
    case medium
    case high
    case ultra
    
    var computeThreadsPerGroup: Int {
        switch self {
        case .low: return 8
        case .medium: return 16
        case .high: return 32
        case .ultra: return 64
        }
    }
}

struct MaterialEffectParameters {
    var time: Float = 0.0
    var deltaTime: Float = 0.0
    var effectIntensity: Float = 1.0
    var romanianEffectsEnabled: Float = 1.0
    var advancedMaterialsEnabled: Float = 1.0
    var qualityLevel: Float = 1.0
    var screenSize: simd_float2 = simd_float2(1, 1)
    var cameraPosition: simd_float3 = simd_float3(0, 0, 5)
}

// MARK: - SwiftUI Modifiers

/// Material effect modifier for SwiftUI views
struct MaterialEffectModifier: ViewModifier {
    let materialProperties: MaterialProperties
    let effectIntensity: Float
    
    func body(content: Content) -> some View {
        content
            .overlay(
                // Glow effect
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(
                                    red: Double(materialProperties.emissiveFactor.x),
                                    green: Double(materialProperties.emissiveFactor.y),
                                    blue: Double(materialProperties.emissiveFactor.z)
                                ).opacity(Double(materialProperties.glowIntensity) * 0.8),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 30
                        )
                    )
                    .scaleEffect(1.0 + Double(materialProperties.pulseIntensity) * 0.1)
                    .opacity(Double(effectIntensity))
            )
            .overlay(
                // Gold leaf effect
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.yellow.opacity(Double(materialProperties.goldLeafEffect) * 0.6),
                                Color.orange.opacity(Double(materialProperties.goldLeafEffect) * 0.4),
                                Color.yellow.opacity(Double(materialProperties.goldLeafEffect) * 0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: Double(materialProperties.goldLeafEffect) * 2
                    )
                    .opacity(Double(effectIntensity))
            )
            .background(
                // Cultural pattern overlay
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        Color.red.opacity(Double(materialProperties.folkPatternIntensity) * 0.1)
                    )
                    .opacity(Double(effectIntensity))
            )
    }
}

extension View {
    /// Apply material effects to a view
    func materialEffect(_ properties: MaterialProperties, intensity: Float = 1.0) -> some View {
        modifier(MaterialEffectModifier(materialProperties: properties, effectIntensity: intensity))
    }
    
    /// Apply Romanian cultural material effect
    func romanianMaterialEffect(intensity: Float = 1.0) -> some View {
        let properties = MaterialProperties.traditionalPaper
        return materialEffect(properties, intensity: intensity)
    }
    
    /// Apply gold highlight material effect
    func goldMaterialEffect(intensity: Float = 1.0) -> some View {
        let properties = MaterialProperties.romanianGold
        return materialEffect(properties, intensity: intensity)
    }
    
    /// Apply seven card special material effect
    func sevenCardMaterialEffect(intensity: Float = 1.0) -> some View {
        let properties = MaterialProperties.magicalSeven
        return materialEffect(properties, intensity: intensity)
    }
}