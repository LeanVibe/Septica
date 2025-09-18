//
//  GeometryCache.swift
//  Septica
//
//  High-performance geometry caching system for ShuffleCats-quality card rendering
//  Provides efficient mesh management, Romanian cultural geometry, and optimized rendering
//

#if canImport(Metal)
import Metal
import MetalKit
import ModelIO
#endif
import SwiftUI
import simd
import Combine

// MARK: - Geometry Cache System

/// High-performance geometry caching system optimized for card rendering
@MainActor
class GeometryCache: ObservableObject {
    
    // MARK: - Core Properties
    
    private let device: MTLDevice
    private var geometryCache: [String: CachedGeometry] = [:]
    private var meshCache: [String: MTKMesh] = [:]
    
    // MARK: - Cache Configuration
    
    @Published var cacheSize: Int = 0
    @Published var maxCacheSize: Int = 64 * 1024 * 1024 // 64MB
    @Published var enableLOD: Bool = true
    @Published var geometryQuality: GeometryQuality = .high
    @Published var cacheHitRate: Double = 0.0
    
    // MARK: - Performance Metrics
    
    private var cacheHits: Int = 0
    private var cacheMisses: Int = 0
    private var lastCleanupTime: CFTimeInterval = 0
    
    // MARK: - Romanian Cultural Geometry
    
    private var culturalGeometryCache: [String: CachedGeometry] = [:]
    private var embossPatterns: [String: CachedGeometry] = [:]
    
    // MARK: - Initialization
    
    init(device: MTLDevice) {
        self.device = device
        
        // Setup cleanup timer
        Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.performCacheCleanup()
        }
        
        // Preload essential geometries
        preloadEssentialGeometries()
        
        print("📐 GeometryCache initialized")
        print("   - Max Cache Size: \(maxCacheSize / (1024 * 1024))MB")
        print("   - Quality: \(geometryQuality)")
        print("   - LOD Enabled: \(enableLOD)")
    }
    
    // MARK: - Card Geometry Loading
    
    /// Get geometry for a specific card type
    func getCardGeometry(_ type: CardGeometryType) -> CachedGeometry {
        let cacheKey = "card_\(type.rawValue)_\(geometryQuality.rawValue)"
        
        if let cachedGeometry = geometryCache[cacheKey] {
            recordCacheHit()
            cachedGeometry.accessTime = CACurrentMediaTime()
            return cachedGeometry
        }
        
        recordCacheMiss()
        
        // Generate card geometry
        let geometry = generateCardGeometry(type: type, quality: geometryQuality)
        cacheGeometry(geometry, key: cacheKey, type: .cardMesh)
        
        return geometry
    }
    
    /// Get Romanian cultural pattern geometry
    func getCulturalPatternGeometry(for card: Card) -> CachedGeometry {
        let patternType = determineCulturalPattern(for: card)
        let cacheKey = "cultural_\(patternType.rawValue)_\(geometryQuality.rawValue)"
        
        if let cachedGeometry = culturalGeometryCache[cacheKey] {
            recordCacheHit()
            cachedGeometry.accessTime = CACurrentMediaTime()
            return cachedGeometry
        }
        
        recordCacheMiss()
        
        // Generate cultural pattern geometry
        let geometry = generateCulturalPatternGeometry(type: patternType, quality: geometryQuality)
        culturalGeometryCache[cacheKey] = geometry
        
        return geometry
    }
    
    /// Get emboss pattern geometry for depth effects
    func getEmbossPatternGeometry(intensity: Float) -> CachedGeometry {
        let cacheKey = "emboss_\(Int(intensity * 100))_\(geometryQuality.rawValue)"
        
        if let cachedGeometry = embossPatterns[cacheKey] {
            recordCacheHit()
            cachedGeometry.accessTime = CACurrentMediaTime()
            return cachedGeometry
        }
        
        recordCacheMiss()
        
        // Generate emboss pattern geometry
        let geometry = generateEmbossPatternGeometry(intensity: intensity, quality: geometryQuality)
        embossPatterns[cacheKey] = geometry
        
        return geometry
    }
    
    /// Get Level of Detail geometry for performance optimization
    func getLODGeometry(for card: Card, distance: Float) -> CachedGeometry {
        let lodLevel = calculateLODLevel(distance: distance)
        let cacheKey = "card_lod_\(lodLevel)_\(card.suit.rawValue)"
        
        if let cachedGeometry = geometryCache[cacheKey] {
            recordCacheHit()
            cachedGeometry.accessTime = CACurrentMediaTime()
            return cachedGeometry
        }
        
        recordCacheMiss()
        
        // Generate LOD geometry
        let geometry = generateLODGeometry(lodLevel: lodLevel, card: card)
        cacheGeometry(geometry, key: cacheKey, type: .lodMesh)
        
        return geometry
    }
    
    // MARK: - Geometry Generation
    
    private func generateCardGeometry(type: CardGeometryType, quality: GeometryQuality) -> CachedGeometry {
        let metalAllocator = MTKMeshBufferAllocator(device: device)
        
        switch type {
        case .romanian_traditional:
            return generateRomanianTraditionalCard(allocator: metalAllocator, quality: quality)
        case .premium_flat:
            return generatePremiumFlatCard(allocator: metalAllocator, quality: quality)
        case .embossed_luxury:
            return generateEmbossedLuxuryCard(allocator: metalAllocator, quality: quality)
        case .seven_special:
            return generateSevenSpecialCard(allocator: metalAllocator, quality: quality)
        }
    }
    
    private func generateRomanianTraditionalCard(allocator: MTKMeshBufferAllocator, quality: GeometryQuality) -> CachedGeometry {
        let subdivisions = quality.subdivisions
        let cornerRadius: Float = 0.1
        
        // Create traditional Romanian card with slightly curved edges
        let vertices = generateRoundedCardVertices(
            width: 2.5, height: 3.5, thickness: 0.05,
            cornerRadius: cornerRadius,
            subdivisions: subdivisions
        )
        
        let indices = generateCardIndices(subdivisions: subdivisions)
        
        return createCachedGeometry(
            vertices: vertices,
            indices: indices,
            allocator: allocator,
            label: "RomanianTraditionalCard"
        )
    }
    
    private func generatePremiumFlatCard(allocator: MTKMeshBufferAllocator, quality: GeometryQuality) -> CachedGeometry {
        let subdivisions = quality.subdivisions
        
        // Create premium flat card with subtle edge highlighting
        let vertices = generateFlatCardVertices(
            width: 2.5, height: 3.5,
            subdivisions: subdivisions
        )
        
        let indices = generateCardIndices(subdivisions: subdivisions)
        
        return createCachedGeometry(
            vertices: vertices,
            indices: indices,
            allocator: allocator,
            label: "PremiumFlatCard"
        )
    }
    
    private func generateEmbossedLuxuryCard(allocator: MTKMeshBufferAllocator, quality: GeometryQuality) -> CachedGeometry {
        let subdivisions = quality.subdivisions
        
        // Create luxury card with embossed details
        let vertices = generateEmbossedCardVertices(
            width: 2.5, height: 3.5, thickness: 0.08,
            subdivisions: subdivisions
        )
        
        let indices = generateCardIndices(subdivisions: subdivisions)
        
        return createCachedGeometry(
            vertices: vertices,
            indices: indices,
            allocator: allocator,
            label: "EmbossedLuxuryCard"
        )
    }
    
    private func generateSevenSpecialCard(allocator: MTKMeshBufferAllocator, quality: GeometryQuality) -> CachedGeometry {
        let subdivisions = quality.subdivisions
        
        // Create special seven card with magical geometry
        let vertices = generateMagicalCardVertices(
            width: 2.5, height: 3.5, thickness: 0.06,
            subdivisions: subdivisions
        )
        
        let indices = generateCardIndices(subdivisions: subdivisions)
        
        return createCachedGeometry(
            vertices: vertices,
            indices: indices,
            allocator: allocator,
            label: "SevenSpecialCard"
        )
    }
    
    // MARK: - Vertex Generation Functions
    
    private func generateRoundedCardVertices(width: Float, height: Float, thickness: Float, cornerRadius: Float, subdivisions: Int) -> [ProfessionalCardVertex] {
        var vertices: [ProfessionalCardVertex] = []
        
        let _ = width / Float(subdivisions)
        let _ = height / Float(subdivisions)
        
        for y in 0...subdivisions {
            for x in 0...subdivisions {
                let u = Float(x) / Float(subdivisions)
                let v = Float(y) / Float(subdivisions)
                
                // Calculate position with rounded corners
                let worldX = (u - 0.5) * width
                let worldY = (v - 0.5) * height
                let worldZ = calculateCardDepth(u: u, v: v, thickness: thickness, cornerRadius: cornerRadius)
                
                // Calculate normal
                let normal = calculateCardNormal(u: u, v: v, cornerRadius: cornerRadius)
                
                // Calculate tangent for normal mapping
                let tangent = calculateCardTangent(u: u, v: v)
                
                // Cultural pattern UV coordinates
                let culturalU = u * 3.0 // Repeat pattern 3 times
                let culturalV = v * 3.0
                
                let vertex = ProfessionalCardVertex(
                    position: simd_float3(worldX, worldY, worldZ),
                    normal: normal,
                    texCoord: simd_float2(u, v),
                    tangent: tangent,
                    culturalUV: simd_float2(culturalU, culturalV)
                )
                
                vertices.append(vertex)
            }
        }
        
        return vertices
    }
    
    private func generateFlatCardVertices(width: Float, height: Float, subdivisions: Int) -> [ProfessionalCardVertex] {
        var vertices: [ProfessionalCardVertex] = []
        
        for y in 0...subdivisions {
            for x in 0...subdivisions {
                let u = Float(x) / Float(subdivisions)
                let v = Float(y) / Float(subdivisions)
                
                let worldX = (u - 0.5) * width
                let worldY = (v - 0.5) * height
                let worldZ: Float = 0.0 // Flat card
                
                let normal = simd_float3(0, 0, 1) // Always pointing up
                let tangent = simd_float3(1, 0, 0) // Always pointing right
                
                let vertex = ProfessionalCardVertex(
                    position: simd_float3(worldX, worldY, worldZ),
                    normal: normal,
                    texCoord: simd_float2(u, v),
                    tangent: tangent,
                    culturalUV: simd_float2(u * 2.0, v * 2.0)
                )
                
                vertices.append(vertex)
            }
        }
        
        return vertices
    }
    
    private func generateEmbossedCardVertices(width: Float, height: Float, thickness: Float, subdivisions: Int) -> [ProfessionalCardVertex] {
        var vertices: [ProfessionalCardVertex] = []
        
        for y in 0...subdivisions {
            for x in 0...subdivisions {
                let u = Float(x) / Float(subdivisions)
                let v = Float(y) / Float(subdivisions)
                
                let worldX = (u - 0.5) * width
                let worldY = (v - 0.5) * height
                
                // Create embossed pattern
                let embossHeight = calculateEmbossHeight(u: u, v: v, thickness: thickness)
                let worldZ = embossHeight
                
                let normal = calculateEmbossNormal(u: u, v: v, thickness: thickness)
                let tangent = calculateEmbossTangent(u: u, v: v)
                
                let vertex = ProfessionalCardVertex(
                    position: simd_float3(worldX, worldY, worldZ),
                    normal: normal,
                    texCoord: simd_float2(u, v),
                    tangent: tangent,
                    culturalUV: simd_float2(u * 4.0, v * 4.0)
                )
                
                vertices.append(vertex)
            }
        }
        
        return vertices
    }
    
    private func generateMagicalCardVertices(width: Float, height: Float, thickness: Float, subdivisions: Int) -> [ProfessionalCardVertex] {
        var vertices: [ProfessionalCardVertex] = []
        
        for y in 0...subdivisions {
            for x in 0...subdivisions {
                let u = Float(x) / Float(subdivisions)
                let v = Float(y) / Float(subdivisions)
                
                let worldX = (u - 0.5) * width
                let worldY = (v - 0.5) * height
                
                // Create magical ripple effect
                let magicalHeight = calculateMagicalHeight(u: u, v: v, thickness: thickness)
                let worldZ = magicalHeight
                
                let normal = calculateMagicalNormal(u: u, v: v, thickness: thickness)
                let tangent = calculateMagicalTangent(u: u, v: v)
                
                let vertex = ProfessionalCardVertex(
                    position: simd_float3(worldX, worldY, worldZ),
                    normal: normal,
                    texCoord: simd_float2(u, v),
                    tangent: tangent,
                    culturalUV: simd_float2(u * 6.0, v * 6.0) // More detailed pattern for magical cards
                )
                
                vertices.append(vertex)
            }
        }
        
        return vertices
    }
    
    // MARK: - Geometry Calculation Helpers
    
    private func calculateCardDepth(u: Float, v: Float, thickness: Float, cornerRadius: Float) -> Float {
        // Create subtle depth variation for Romanian cards
        let centerX = u - 0.5
        let centerY = v - 0.5
        let distanceFromCenter = sqrt(centerX * centerX + centerY * centerY)
        
        // Subtle curvature
        let curvature = (1.0 - distanceFromCenter * 2.0) * thickness * 0.3
        return max(0, curvature)
    }
    
    private func calculateCardNormal(u: Float, v: Float, cornerRadius: Float) -> simd_float3 {
        let centerX = u - 0.5
        let centerY = v - 0.5
        
        // Calculate normal based on subtle curvature
        let normalX = centerX * -0.2
        let normalY = centerY * -0.2
        let normalZ: Float = 1.0
        
        return simd_normalize(simd_float3(normalX, normalY, normalZ))
    }
    
    private func calculateCardTangent(u: Float, v: Float) -> simd_float3 {
        // Simple tangent calculation for texture mapping
        return simd_normalize(simd_float3(1.0, 0.0, 0.1))
    }
    
    private func calculateEmbossHeight(u: Float, v: Float, thickness: Float) -> Float {
        // Create embossed pattern based on UV coordinates
        let patternX = sin(u * 8.0 * .pi)
        let patternY = sin(v * 6.0 * .pi)
        let pattern = (patternX * patternY) * 0.5 + 0.5
        
        // Add border embossing
        let borderDistanceX = min(u, 1.0 - u)
        let borderDistanceY = min(v, 1.0 - v)
        let borderEmboss = min(borderDistanceX, borderDistanceY) * 4.0
        let borderHeight = min(1.0, borderEmboss) * thickness * 0.5
        
        return pattern * thickness * 0.3 + borderHeight
    }
    
    private func calculateEmbossNormal(u: Float, v: Float, thickness: Float) -> simd_float3 {
        let h = calculateEmbossHeight(u: u, v: v, thickness: thickness)
        let hU = calculateEmbossHeight(u: u + 0.01, v: v, thickness: thickness)
        let hV = calculateEmbossHeight(u: u, v: v + 0.01, thickness: thickness)
        
        let normalX = (h - hU) / 0.01
        let normalY = (h - hV) / 0.01
        let normalZ: Float = 1.0
        
        return simd_normalize(simd_float3(normalX, normalY, normalZ))
    }
    
    private func calculateEmbossTangent(u: Float, v: Float) -> simd_float3 {
        return simd_normalize(simd_float3(1.0, 0.0, 0.2))
    }
    
    private func calculateMagicalHeight(u: Float, v: Float, thickness: Float) -> Float {
        let centerX = u - 0.5
        let centerY = v - 0.5
        let distance = sqrt(centerX * centerX + centerY * centerY)
        
        // Create magical ripple effect
        let ripple = sin(distance * 16.0 * .pi) * exp(-distance * 4.0)
        return ripple * thickness * 0.4
    }
    
    private func calculateMagicalNormal(u: Float, v: Float, thickness: Float) -> simd_float3 {
        let h = calculateMagicalHeight(u: u, v: v, thickness: thickness)
        let hU = calculateMagicalHeight(u: u + 0.01, v: v, thickness: thickness)
        let hV = calculateMagicalHeight(u: u, v: v + 0.01, thickness: thickness)
        
        let normalX = (h - hU) / 0.01
        let normalY = (h - hV) / 0.01
        let normalZ: Float = 1.0
        
        return simd_normalize(simd_float3(normalX, normalY, normalZ))
    }
    
    private func calculateMagicalTangent(u: Float, v: Float) -> simd_float3 {
        let centerX = u - 0.5
        let centerY = v - 0.5
        let angle = atan2(centerY, centerX)
        
        return simd_normalize(simd_float3(cos(angle), sin(angle), 0.1))
    }
    
    // MARK: - Index Generation
    
    private func generateCardIndices(subdivisions: Int) -> [UInt16] {
        var indices: [UInt16] = []
        
        for y in 0..<subdivisions {
            for x in 0..<subdivisions {
                let topLeft = UInt16(y * (subdivisions + 1) + x)
                let topRight = UInt16(y * (subdivisions + 1) + x + 1)
                let bottomLeft = UInt16((y + 1) * (subdivisions + 1) + x)
                let bottomRight = UInt16((y + 1) * (subdivisions + 1) + x + 1)
                
                // First triangle
                indices.append(topLeft)
                indices.append(bottomLeft)
                indices.append(topRight)
                
                // Second triangle
                indices.append(topRight)
                indices.append(bottomLeft)
                indices.append(bottomRight)
            }
        }
        
        return indices
    }
    
    // MARK: - Cultural Pattern Geometry
    
    private func generateCulturalPatternGeometry(type: CulturalPatternType, quality: GeometryQuality) -> CachedGeometry {
        let metalAllocator = MTKMeshBufferAllocator(device: device)
        
        switch type {
        case .traditionalBorder:
            return generateTraditionalBorderGeometry(allocator: metalAllocator, quality: quality)
        case .floralMotif:
            return generateFloralMotifGeometry(allocator: metalAllocator, quality: quality)
        case .geometricPattern:
            return generateGeometricPatternGeometry(allocator: metalAllocator, quality: quality)
        case .embroideryStitch:
            return generateEmbroideryStitchGeometry(allocator: metalAllocator, quality: quality)
        }
    }
    
    private func generateTraditionalBorderGeometry(allocator: MTKMeshBufferAllocator, quality: GeometryQuality) -> CachedGeometry {
        // Generate traditional Romanian border pattern
        let subdivisions = quality.subdivisions / 2 // Simpler geometry for overlay
        
        let vertices = generateBorderVertices(subdivisions: subdivisions)
        let indices = generateBorderIndices(subdivisions: subdivisions)
        
        return createCachedGeometry(
            vertices: vertices,
            indices: indices,
            allocator: allocator,
            label: "TraditionalBorder"
        )
    }
    
    private func generateFloralMotifGeometry(allocator: MTKMeshBufferAllocator, quality: GeometryQuality) -> CachedGeometry {
        // Generate floral motif pattern
        let subdivisions = quality.subdivisions / 3
        
        let vertices = generateFloralVertices(subdivisions: subdivisions)
        let indices = generateFloralIndices(subdivisions: subdivisions)
        
        return createCachedGeometry(
            vertices: vertices,
            indices: indices,
            allocator: allocator,
            label: "FloralMotif"
        )
    }
    
    private func generateGeometricPatternGeometry(allocator: MTKMeshBufferAllocator, quality: GeometryQuality) -> CachedGeometry {
        // Generate geometric pattern
        let subdivisions = quality.subdivisions / 4
        
        let vertices = generateGeometricVertices(subdivisions: subdivisions)
        let indices = generateGeometricIndices(subdivisions: subdivisions)
        
        return createCachedGeometry(
            vertices: vertices,
            indices: indices,
            allocator: allocator,
            label: "GeometricPattern"
        )
    }
    
    private func generateEmbroideryStitchGeometry(allocator: MTKMeshBufferAllocator, quality: GeometryQuality) -> CachedGeometry {
        // Generate embroidery stitch pattern
        let subdivisions = quality.subdivisions / 2
        
        let vertices = generateStitchVertices(subdivisions: subdivisions)
        let indices = generateStitchIndices(subdivisions: subdivisions)
        
        return createCachedGeometry(
            vertices: vertices,
            indices: indices,
            allocator: allocator,
            label: "EmbroideryStitch"
        )
    }
    
    // MARK: - Pattern Vertex Generation
    
    private func generateBorderVertices(subdivisions: Int) -> [ProfessionalCardVertex] {
        var vertices: [ProfessionalCardVertex] = []
        
        // Generate border pattern vertices
        for i in 0...subdivisions {
            let t = Float(i) / Float(subdivisions)
            let angle = t * 2.0 * .pi
            
            let x = cos(angle) * 0.8
            let y = sin(angle) * 0.8
            let z = sin(angle * 8.0) * 0.02 // Wavy border
            
            let vertex = ProfessionalCardVertex(
                position: simd_float3(x, y, z),
                normal: simd_float3(0, 0, 1),
                texCoord: simd_float2(t, 0),
                tangent: simd_float3(1, 0, 0),
                culturalUV: simd_float2(t * 4.0, 0)
            )
            
            vertices.append(vertex)
        }
        
        return vertices
    }
    
    private func generateFloralVertices(subdivisions: Int) -> [ProfessionalCardVertex] {
        var vertices: [ProfessionalCardVertex] = []
        
        // Generate floral motif vertices in a spiral pattern
        for i in 0...subdivisions {
            let t = Float(i) / Float(subdivisions)
            let angle = t * 6.0 * .pi // Multiple spirals
            let radius = t * 0.5
            
            let x = cos(angle) * radius
            let y = sin(angle) * radius
            let z = sin(angle * 3.0) * 0.01
            
            let vertex = ProfessionalCardVertex(
                position: simd_float3(x, y, z),
                normal: simd_float3(0, 0, 1),
                texCoord: simd_float2(t, 0),
                tangent: simd_float3(1, 0, 0),
                culturalUV: simd_float2(t * 8.0, t * 8.0)
            )
            
            vertices.append(vertex)
        }
        
        return vertices
    }
    
    private func generateGeometricVertices(subdivisions: Int) -> [ProfessionalCardVertex] {
        var vertices: [ProfessionalCardVertex] = []
        
        // Generate geometric pattern vertices
        let steps = subdivisions / 4
        for y in 0...steps {
            for x in 0...steps {
                let u = Float(x) / Float(steps)
                let v = Float(y) / Float(steps)
                
                let worldX = (u - 0.5) * 2.0
                let worldY = (v - 0.5) * 2.0
                let worldZ: Float = ((Int(x + y) % 2) == 0) ? 0.01 : 0.0 // Checkerboard height
                
                let vertex = ProfessionalCardVertex(
                    position: simd_float3(worldX, worldY, worldZ),
                    normal: simd_float3(0, 0, 1),
                    texCoord: simd_float2(u, v),
                    tangent: simd_float3(1, 0, 0),
                    culturalUV: simd_float2(u * 4.0, v * 4.0)
                )
                
                vertices.append(vertex)
            }
        }
        
        return vertices
    }
    
    private func generateStitchVertices(subdivisions: Int) -> [ProfessionalCardVertex] {
        var vertices: [ProfessionalCardVertex] = []
        
        // Generate embroidery stitch pattern
        for i in 0...subdivisions {
            let t = Float(i) / Float(subdivisions)
            let x = (t - 0.5) * 2.0
            let y = sin(t * 12.0 * .pi) * 0.1 // Zigzag pattern
            let z: Float = 0.005
            
            let vertex = ProfessionalCardVertex(
                position: simd_float3(x, y, z),
                normal: simd_float3(0, 0, 1),
                texCoord: simd_float2(t, 0.5),
                tangent: simd_float3(1, 0, 0),
                culturalUV: simd_float2(t * 16.0, 0.5)
            )
            
            vertices.append(vertex)
        }
        
        return vertices
    }
    
    // MARK: - Pattern Index Generation
    
    private func generateBorderIndices(subdivisions: Int) -> [UInt16] {
        var indices: [UInt16] = []
        
        for i in 0..<subdivisions {
            indices.append(UInt16(i))
            indices.append(UInt16(i + 1))
        }
        
        return indices
    }
    
    private func generateFloralIndices(subdivisions: Int) -> [UInt16] {
        var indices: [UInt16] = []
        
        for i in 0..<subdivisions {
            indices.append(UInt16(i))
            indices.append(UInt16(i + 1))
        }
        
        return indices
    }
    
    private func generateGeometricIndices(subdivisions: Int) -> [UInt16] {
        var indices: [UInt16] = []
        let steps = subdivisions / 4
        
        for y in 0..<steps {
            for x in 0..<steps {
                let topLeft = UInt16(y * (steps + 1) + x)
                let topRight = UInt16(y * (steps + 1) + x + 1)
                let bottomLeft = UInt16((y + 1) * (steps + 1) + x)
                let bottomRight = UInt16((y + 1) * (steps + 1) + x + 1)
                
                indices.append(topLeft)
                indices.append(bottomLeft)
                indices.append(topRight)
                
                indices.append(topRight)
                indices.append(bottomLeft)
                indices.append(bottomRight)
            }
        }
        
        return indices
    }
    
    private func generateStitchIndices(subdivisions: Int) -> [UInt16] {
        var indices: [UInt16] = []
        
        for i in 0..<subdivisions {
            indices.append(UInt16(i))
            indices.append(UInt16(i + 1))
        }
        
        return indices
    }
    
    // MARK: - LOD System
    
    private func calculateLODLevel(distance: Float) -> Int {
        if distance < 5.0 {
            return 0 // Highest detail
        } else if distance < 15.0 {
            return 1 // Medium detail
        } else {
            return 2 // Lowest detail
        }
    }
    
    private func generateLODGeometry(lodLevel: Int, card: Card) -> CachedGeometry {
        let _ = MTKMeshBufferAllocator(device: device)
        
        let quality: GeometryQuality
        switch lodLevel {
        case 0: quality = .high
        case 1: quality = .medium
        default: quality = .low
        }
        
        // Generate simplified geometry for distant cards
        return generateCardGeometry(type: .premium_flat, quality: quality)
    }
    
    private func generateEmbossPatternGeometry(intensity: Float, quality: GeometryQuality) -> CachedGeometry {
        let metalAllocator = MTKMeshBufferAllocator(device: device)
        let subdivisions = quality.subdivisions
        
        var vertices: [ProfessionalCardVertex] = []
        
        for y in 0...subdivisions {
            for x in 0...subdivisions {
                let u = Float(x) / Float(subdivisions)
                let v = Float(y) / Float(subdivisions)
                
                let worldX = (u - 0.5) * 2.0
                let worldY = (v - 0.5) * 2.0
                let embossHeight = calculateEmbossHeight(u: u, v: v, thickness: intensity * 0.1)
                
                let vertex = ProfessionalCardVertex(
                    position: simd_float3(worldX, worldY, embossHeight),
                    normal: calculateEmbossNormal(u: u, v: v, thickness: intensity * 0.1),
                    texCoord: simd_float2(u, v),
                    tangent: simd_float3(1, 0, 0),
                    culturalUV: simd_float2(u * 2.0, v * 2.0)
                )
                
                vertices.append(vertex)
            }
        }
        
        let indices = generateCardIndices(subdivisions: subdivisions)
        
        return createCachedGeometry(
            vertices: vertices,
            indices: indices,
            allocator: metalAllocator,
            label: "EmbossPattern_\(Int(intensity * 100))"
        )
    }
    
    // MARK: - Geometry Creation Helper
    
    private func createCachedGeometry(vertices: [ProfessionalCardVertex], indices: [UInt16], allocator: MTKMeshBufferAllocator, label: String) -> CachedGeometry {
        // Create vertex buffer
        let vertexBufferSize = vertices.count * MemoryLayout<ProfessionalCardVertex>.stride
        guard let vertexBuffer = device.makeBuffer(bytes: vertices, length: vertexBufferSize, options: []) else {
            fatalError("Failed to create vertex buffer")
        }
        vertexBuffer.label = "\(label)_Vertices"
        
        // Create index buffer
        let indexBufferSize = indices.count * MemoryLayout<UInt16>.stride
        guard let indexBuffer = device.makeBuffer(bytes: indices, length: indexBufferSize, options: []) else {
            fatalError("Failed to create index buffer")
        }
        indexBuffer.label = "\(label)_Indices"
        
        let size = vertexBufferSize + indexBufferSize
        
        return CachedGeometry(
            vertexBuffer: vertexBuffer,
            indexBuffer: indexBuffer,
            vertexCount: vertices.count,
            indexCount: indices.count,
            indexType: .uint16,
            size: size,
            accessTime: CACurrentMediaTime()
        )
    }
    
    // MARK: - Cache Management
    
    private func cacheGeometry(_ geometry: CachedGeometry, key: String, type: GeometryType) {
        let size = geometry.size
        
        // Check if we need to free space
        if cacheSize + size > maxCacheSize {
            freeOldestGeometries(requiredSpace: size)
        }
        
        geometryCache[key] = geometry
        cacheSize += size
        updateCacheMetrics()
    }
    
    private func freeOldestGeometries(requiredSpace: Int) {
        // Sort by access time and remove oldest
        let sortedKeys = geometryCache.keys.sorted { key1, key2 in
            geometryCache[key1]!.accessTime < geometryCache[key2]!.accessTime
        }
        
        var freedSpace = 0
        for key in sortedKeys {
            if freedSpace >= requiredSpace { break }
            
            if let cachedGeometry = geometryCache[key] {
                freedSpace += cachedGeometry.size
                cacheSize -= cachedGeometry.size
                geometryCache.removeValue(forKey: key)
            }
        }
    }
    
    private func performCacheCleanup() {
        let currentTime = CACurrentMediaTime()
        let maxAge: CFTimeInterval = 600 // 10 minutes
        
        let expiredKeys = geometryCache.compactMap { key, cachedGeometry in
            currentTime - cachedGeometry.accessTime > maxAge ? key : nil
        }
        
        for key in expiredKeys {
            if let cachedGeometry = geometryCache[key] {
                cacheSize -= cachedGeometry.size
                geometryCache.removeValue(forKey: key)
            }
        }
        
        updateCacheMetrics()
        
        print("🧹 GeometryCache cleanup: removed \(expiredKeys.count) expired geometries")
    }
    
    // MARK: - Metrics
    
    private func recordCacheHit() {
        cacheHits += 1
        updateCacheMetrics()
    }
    
    private func recordCacheMiss() {
        cacheMisses += 1
        updateCacheMetrics()
    }
    
    private func updateCacheMetrics() {
        let total = cacheHits + cacheMisses
        cacheHitRate = total > 0 ? Double(cacheHits) / Double(total) : 0.0
    }
    
    // MARK: - Utility Methods
    
    private func determineCulturalPattern(for card: Card) -> CulturalPatternType {
        if card.value == 7 {
            return .floralMotif // Special pattern for sevens
        } else if card.isPointCard {
            return .embroideryStitch
        } else if card.suit == .hearts || card.suit == .diamonds {
            return .traditionalBorder
        } else {
            return .geometricPattern
        }
    }
    
    private func preloadEssentialGeometries() {
        // Preload commonly used geometries
        Task {
            _ = getCardGeometry(.romanian_traditional)
            _ = getCardGeometry(.premium_flat)
            
            print("✅ Essential geometries preloaded")
        }
    }
}

// MARK: - Supporting Types

class CachedGeometry {
    let vertexBuffer: MTLBuffer
    let indexBuffer: MTLBuffer
    let vertexCount: Int
    let indexCount: Int
    let indexType: MTLIndexType
    let size: Int
    var accessTime: CFTimeInterval
    
    init(vertexBuffer: MTLBuffer, indexBuffer: MTLBuffer, vertexCount: Int, indexCount: Int, indexType: MTLIndexType, size: Int, accessTime: CFTimeInterval) {
        self.vertexBuffer = vertexBuffer
        self.indexBuffer = indexBuffer
        self.vertexCount = vertexCount
        self.indexCount = indexCount
        self.indexType = indexType
        self.size = size
        self.accessTime = accessTime
    }
}

struct ProfessionalCardVertex {
    let position: simd_float3
    let normal: simd_float3
    let texCoord: simd_float2
    let tangent: simd_float3
    let culturalUV: simd_float2
}

enum CardGeometryType: String {
    case romanian_traditional = "romanian_traditional"
    case premium_flat = "premium_flat"
    case embossed_luxury = "embossed_luxury"
    case seven_special = "seven_special"
}

enum CulturalPatternType: String {
    case traditionalBorder = "traditional_border"
    case floralMotif = "floral_motif"
    case geometricPattern = "geometric_pattern"
    case embroideryStitch = "embroidery_stitch"
}

enum GeometryType {
    case cardMesh
    case culturalPattern
    case embossPattern
    case lodMesh
}

enum GeometryQuality: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case ultra = "ultra"
    
    var subdivisions: Int {
        switch self {
        case .low: return 8
        case .medium: return 16
        case .high: return 32
        case .ultra: return 64
        }
    }
}