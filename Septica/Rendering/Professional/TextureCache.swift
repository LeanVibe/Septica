//
//  TextureCache.swift
//  Septica
//
//  High-performance texture caching system for ShuffleCats-quality card rendering
//  Provides efficient texture management, Romanian cultural pattern loading, and memory optimization
//

#if canImport(Metal)
import Metal
import MetalKit
#endif
import SwiftUI
import Combine
import CoreGraphics
import CoreText
import UIKit

// MARK: - Texture Cache System

/// High-performance texture caching system optimized for card rendering
@MainActor
class TextureCache: ObservableObject {
    
    // MARK: - Core Properties
    
    private let device: MTLDevice
    private let textureLoader: MTKTextureLoader
    private var cache: [String: CachedTexture] = [:]
    private var generatedTextures: [String: MTLTexture] = [:]
    
    // MARK: - Cache Configuration
    
    @Published var cacheSize: Int = 0
    @Published var maxCacheSize: Int = 256 * 1024 * 1024 // 256MB
    @Published var enableCompression: Bool = true
    @Published var enableMipmaps: Bool = true
    @Published var cacheHitRate: Double = 0.0
    
    // MARK: - Performance Metrics
    
    private var cacheHits: Int = 0
    private var cacheMisses: Int = 0
    private var lastCleanupTime: CFTimeInterval = 0
    
    // MARK: - Romanian Cultural Patterns
    
    private var culturalPatternCache: [String: MTLTexture] = [:]
    private var embroideryPatterns: [String: MTLTexture] = [:]
    private var folkMotifs: [String: MTLTexture] = [:]
    
    // MARK: - Initialization
    
    init(device: MTLDevice) {
        self.device = device
        self.textureLoader = MTKTextureLoader(device: device)
        
        // Setup cleanup timer
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.performCacheCleanup()
            }
        }
        
        // Preload essential textures
        preloadEssentialTextures()
        
        print("🎨 TextureCache initialized")
        print("   - Max Cache Size: \(maxCacheSize / (1024 * 1024))MB")
        print("   - Compression: \(enableCompression)")
        print("   - Mipmaps: \(enableMipmaps)")
    }
    
    // MARK: - Card Texture Loading
    
    /// Get texture for a specific card
    func getCardTexture(for card: Card) throws -> MTLTexture {
        let cacheKey = "card_\(card.suit.rawValue)_\(card.value)"
        
        if let cachedTexture = cache[cacheKey]?.texture {
            recordCacheHit()
            return cachedTexture
        }
        
        recordCacheMiss()
        
        // Generate card texture dynamically
        let texture = try generateCardTexture(for: card)
        cacheTexture(texture, key: cacheKey, type: .cardFace)
        
        return texture
    }
    
    /// Get normal map texture for a card
    func getNormalMapTexture(for card: Card) throws -> MTLTexture {
        let cacheKey = "normal_\(card.suit.rawValue)_\(card.value)"
        
        if let cachedTexture = cache[cacheKey]?.texture {
            recordCacheHit()
            return cachedTexture
        }
        
        recordCacheMiss()
        
        // Generate normal map for card depth effects
        let texture = try generateCardNormalMap(for: card)
        cacheTexture(texture, key: cacheKey, type: .normalMap)
        
        return texture
    }
    
    /// Get Romanian cultural pattern texture
    func getRomanianPatternTexture(for card: Card) throws -> MTLTexture {
        let patternType = determineCulturalPattern(for: card)
        let cacheKey = "romanian_pattern_\(patternType)"
        
        if let cachedTexture = culturalPatternCache[cacheKey] {
            recordCacheHit()
            return cachedTexture
        }
        
        recordCacheMiss()
        
        // Generate Romanian cultural pattern
        let texture = try generateRomanianPattern(type: patternType)
        culturalPatternCache[cacheKey] = texture
        
        return texture
    }
    
    /// Get embroidery effect texture
    func getEmbroideryTexture(intensity: Float = 1.0) throws -> MTLTexture {
        let cacheKey = "embroidery_\(Int(intensity * 100))"
        
        if let cachedTexture = embroideryPatterns[cacheKey] {
            recordCacheHit()
            return cachedTexture
        }
        
        recordCacheMiss()
        
        // Generate embroidery pattern texture
        let texture = try generateEmbroideryPattern(intensity: intensity)
        embroideryPatterns[cacheKey] = texture
        
        return texture
    }
    
    /// Get folk motif texture
    func getFolkMotifTexture(motif: RomanianMotif) throws -> MTLTexture {
        let cacheKey = "folk_motif_\(motif.rawValue)"
        
        if let cachedTexture = folkMotifs[cacheKey] {
            recordCacheHit()
            return cachedTexture
        }
        
        recordCacheMiss()
        
        // Generate folk motif texture
        let texture = try generateFolkMotifTexture(motif: motif)
        folkMotifs[cacheKey] = texture
        
        return texture
    }
    
    // MARK: - Texture Generation
    
    private func generateCardTexture(for card: Card) throws -> MTLTexture {
        let textureSize = 512 // High resolution for quality
        
        // Create render target
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm_srgb,
            width: textureSize,
            height: Int(Float(textureSize) * 1.4), // Card aspect ratio
            mipmapped: enableMipmaps
        )
        descriptor.usage = [.renderTarget, .shaderRead]
        
        guard let texture = device.makeTexture(descriptor: descriptor) else {
            throw TextureCacheError.textureCreationFailed
        }
        texture.label = "CardTexture_\(card.suit.rawValue)_\(card.value)"
        
        // Render card to texture using Core Graphics
        try renderCardToTexture(card: card, texture: texture)
        
        return texture
    }
    
    private func generateCardNormalMap(for card: Card) throws -> MTLTexture {
        let textureSize = 512
        
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: textureSize,
            height: Int(Float(textureSize) * 1.4),
            mipmapped: enableMipmaps
        )
        descriptor.usage = [.renderTarget, .shaderRead]
        
        guard let texture = device.makeTexture(descriptor: descriptor) else {
            throw TextureCacheError.textureCreationFailed
        }
        texture.label = "NormalMap_\(card.suit.rawValue)_\(card.value)"
        
        // Generate normal map for card embossing effect
        try generateCardNormalMapData(card: card, texture: texture)
        
        return texture
    }
    
    private func generateRomanianPattern(type: RomanianPatternType) throws -> MTLTexture {
        let textureSize = 256
        
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm_srgb,
            width: textureSize,
            height: textureSize,
            mipmapped: enableMipmaps
        )
        descriptor.usage = [.renderTarget, .shaderRead]
        
        guard let texture = device.makeTexture(descriptor: descriptor) else {
            throw TextureCacheError.textureCreationFailed
        }
        texture.label = "RomanianPattern_\(type.rawValue)"
        
        // Generate Romanian cultural pattern
        try renderRomanianPatternToTexture(type: type, texture: texture)
        
        return texture
    }
    
    private func generateEmbroideryPattern(intensity: Float) throws -> MTLTexture {
        let textureSize = 256
        
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm_srgb,
            width: textureSize,
            height: textureSize,
            mipmapped: enableMipmaps
        )
        descriptor.usage = [.renderTarget, .shaderRead]
        
        guard let texture = device.makeTexture(descriptor: descriptor) else {
            throw TextureCacheError.textureCreationFailed
        }
        texture.label = "EmbroideryPattern_\(Int(intensity * 100))"
        
        // Generate embroidery pattern
        try renderEmbroideryPatternToTexture(intensity: intensity, texture: texture)
        
        return texture
    }
    
    private func generateFolkMotifTexture(motif: RomanianMotif) throws -> MTLTexture {
        let textureSize = 128
        
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm_srgb,
            width: textureSize,
            height: textureSize,
            mipmapped: enableMipmaps
        )
        descriptor.usage = [.renderTarget, .shaderRead]
        
        guard let texture = device.makeTexture(descriptor: descriptor) else {
            throw TextureCacheError.textureCreationFailed
        }
        texture.label = "FolkMotif_\(motif.rawValue)"
        
        // Generate folk motif
        try renderFolkMotifToTexture(motif: motif, texture: texture)
        
        return texture
    }
    
    // MARK: - Core Graphics Rendering
    
    private func renderCardToTexture(card: Card, texture: MTLTexture) throws {
        let width = texture.width
        let height = texture.height
        let bytesPerRow = width * 4
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw TextureCacheError.contextCreationFailed
        }
        
        // Clear background
        context.setFillColor(red: 0.98, green: 0.96, blue: 0.94, alpha: 1.0)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        
        // Draw card border
        drawCardBorder(context: context, width: width, height: height)
        
        // Draw suit symbols and values
        drawCardContent(context: context, card: card, width: width, height: height)
        
        // Draw Romanian cultural elements
        drawRomanianElements(context: context, card: card, width: width, height: height)
        
        // Copy data to Metal texture
        guard let data = context.data else {
            throw TextureCacheError.dataExtractionFailed
        }
        
        let region = MTLRegionMake2D(0, 0, width, height)
        texture.replace(region: region, mipmapLevel: 0, withBytes: data, bytesPerRow: bytesPerRow)
        
        // Generate mipmaps if enabled
        if enableMipmaps {
            generateMipmaps(for: texture)
        }
    }
    
    private func drawCardBorder(context: CGContext, width: Int, height: Int) {
        let rect = CGRect(x: 4, y: 4, width: width - 8, height: height - 8)
        let cornerRadius: CGFloat = 16
        
        // Outer border
        context.setLineWidth(3.0)
        context.setStrokeColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        
        let path = CGPath(
            roundedRect: rect,
            cornerWidth: cornerRadius,
            cornerHeight: cornerRadius,
            transform: nil
        )
        context.addPath(path)
        context.strokePath()
        
        // Inner highlight
        context.setLineWidth(1.0)
        context.setStrokeColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.8)
        
        let innerRect = rect.insetBy(dx: 2, dy: 2)
        let innerPath = CGPath(
            roundedRect: innerRect,
            cornerWidth: cornerRadius - 2,
            cornerHeight: cornerRadius - 2,
            transform: nil
        )
        context.addPath(innerPath)
        context.strokePath()
    }
    
    private func drawCardContent(context: CGContext, card: Card, width: Int, height: Int) {
        // Draw value in top-left
        let fontName = "HelveticaNeue-Bold" as CFString
        guard let valueFont = CGFont(fontName) else { return }
        context.setFont(valueFont)
        context.setFontSize(48)
        
        // Set color based on suit
        let (red, green, blue) = getSuitColor(card.suit)
        context.setFillColor(red: red, green: green, blue: blue, alpha: 1.0)
        
        // Draw value using Core Text
        let valueString = card.displayValue
        let valuePoint = CGPoint(x: 20, y: height - 60)
        context.textPosition = valuePoint
        
        // Use showGlyphs instead of deprecated show method
        let attributedString = NSAttributedString(
            string: valueString,
            attributes: [
                .font: UIFont(name: "HelveticaNeue-Bold", size: 48) ?? UIFont.systemFont(ofSize: 48),
                .foregroundColor: UIColor(red: red, green: green, blue: blue, alpha: 1.0)
            ]
        )
        
        let line = CTLineCreateWithAttributedString(attributedString)
        context.textPosition = valuePoint
        CTLineDraw(line, context)
        
        // Draw suit symbol in center
        drawSuitSymbol(context: context, suit: card.suit, center: CGPoint(x: width / 2, y: height / 2), size: 120)
        
        // Draw rotated value and suit in bottom-right
        context.saveGState()
        context.translateBy(x: CGFloat(width - 20), y: 60)
        context.rotate(by: .pi)
        
        // Draw rotated value using Core Text
        let rotatedAttributedString = NSAttributedString(
            string: valueString,
            attributes: [
                .font: UIFont(name: "HelveticaNeue-Bold", size: 48) ?? UIFont.systemFont(ofSize: 48),
                .foregroundColor: UIColor(red: red, green: green, blue: blue, alpha: 1.0)
            ]
        )
        
        let rotatedLine = CTLineCreateWithAttributedString(rotatedAttributedString)
        context.textPosition = CGPoint.zero
        CTLineDraw(rotatedLine, context)
        
        drawSuitSymbol(context: context, suit: card.suit, center: CGPoint(x: 0, y: -30), size: 24)
        
        context.restoreGState()
    }
    
    private func drawSuitSymbol(context: CGContext, suit: Suit, center: CGPoint, size: CGFloat) {
        let (red, green, blue) = getSuitColor(suit)
        context.setFillColor(red: red, green: green, blue: blue, alpha: 1.0)
        
        let rect = CGRect(
            x: center.x - size/2,
            y: center.y - size/2,
            width: size,
            height: size
        )
        
        switch suit {
        case .hearts:
            drawHeart(context: context, in: rect)
        case .diamonds:
            drawDiamond(context: context, in: rect)
        case .clubs:
            drawClub(context: context, in: rect)
        case .spades:
            drawSpade(context: context, in: rect)
        }
    }
    
    private func drawRomanianElements(context: CGContext, card: Card, width: Int, height: Int) {
        // Add subtle Romanian pattern in corners
        context.setFillColor(red: 0.9, green: 0.7, blue: 0.2, alpha: 0.1)
        
        let patternSize: CGFloat = 16
        let spacing: CGFloat = 4
        
        // Top-left corner pattern
        for i in 0..<3 {
            for j in 0..<3 {
                let x = spacing + CGFloat(i) * (patternSize + spacing)
                let y = spacing + CGFloat(j) * (patternSize + spacing)
                drawRomanianMotif(context: context, at: CGPoint(x: x, y: y), size: patternSize)
            }
        }
        
        // Bottom-right corner pattern
        for i in 0..<3 {
            for j in 0..<3 {
                let x = CGFloat(width) - spacing - CGFloat(3-i) * (patternSize + spacing)
                let y = CGFloat(height) - spacing - CGFloat(3-j) * (patternSize + spacing)
                drawRomanianMotif(context: context, at: CGPoint(x: x, y: y), size: patternSize)
            }
        }
    }
    
    private func drawRomanianMotif(context: CGContext, at point: CGPoint, size: CGFloat) {
        let rect = CGRect(x: point.x, y: point.y, width: size, height: size)
        
        // Simple diamond pattern typical of Romanian folk art
        context.move(to: CGPoint(x: rect.midX, y: rect.minY))
        context.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        context.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        context.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        context.closePath()
        context.fillPath()
    }
    
    // MARK: - Suit Symbol Drawing
    
    private func drawHeart(context: CGContext, in rect: CGRect) {
        let path = CGMutablePath()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addCurve(
            to: CGPoint(x: rect.minX, y: rect.minY + height * 0.3),
            control1: CGPoint(x: rect.midX - width * 0.3, y: rect.maxY - height * 0.3),
            control2: CGPoint(x: rect.minX, y: rect.minY + height * 0.6)
        )
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.minY + height * 0.3),
            control1: CGPoint(x: rect.minX, y: rect.minY),
            control2: CGPoint(x: rect.midX - width * 0.25, y: rect.minY)
        )
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + height * 0.3),
            control1: CGPoint(x: rect.midX + width * 0.25, y: rect.minY),
            control2: CGPoint(x: rect.maxX, y: rect.minY)
        )
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY),
            control1: CGPoint(x: rect.maxX, y: rect.minY + height * 0.6),
            control2: CGPoint(x: rect.midX + width * 0.3, y: rect.maxY - height * 0.3)
        )
        
        context.addPath(path)
        context.fillPath()
    }
    
    private func drawDiamond(context: CGContext, in rect: CGRect) {
        context.move(to: CGPoint(x: rect.midX, y: rect.minY))
        context.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        context.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        context.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        context.closePath()
        context.fillPath()
    }
    
    private func drawClub(context: CGContext, in rect: CGRect) {
        let centerX = rect.midX
        let centerY = rect.midY
        let radius = rect.width * 0.15
        
        // Three circles
        context.addEllipse(in: CGRect(x: centerX - radius, y: centerY - radius * 1.5, width: radius * 2, height: radius * 2))
        context.addEllipse(in: CGRect(x: centerX - radius * 1.5, y: centerY - radius * 0.5, width: radius * 2, height: radius * 2))
        context.addEllipse(in: CGRect(x: centerX + radius * 0.5, y: centerY - radius * 0.5, width: radius * 2, height: radius * 2))
        context.fillPath()
        
        // Stem
        context.move(to: CGPoint(x: centerX, y: centerY + radius))
        context.addLine(to: CGPoint(x: centerX, y: rect.maxY - radius))
        context.setLineWidth(radius * 0.8)
        context.strokePath()
    }
    
    private func drawSpade(context: CGContext, in rect: CGRect) {
        let path = CGMutablePath()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addCurve(
            to: CGPoint(x: rect.minX, y: rect.midY),
            control1: CGPoint(x: rect.midX - width * 0.3, y: rect.minY + height * 0.2),
            control2: CGPoint(x: rect.minX, y: rect.midY - height * 0.1)
        )
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.midY + height * 0.2),
            control1: CGPoint(x: rect.minX, y: rect.midY + height * 0.1),
            control2: CGPoint(x: rect.midX - width * 0.2, y: rect.midY + height * 0.2)
        )
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY),
            control1: CGPoint(x: rect.midX + width * 0.2, y: rect.midY + height * 0.2),
            control2: CGPoint(x: rect.maxX, y: rect.midY + height * 0.1)
        )
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.minY),
            control1: CGPoint(x: rect.maxX, y: rect.midY - height * 0.1),
            control2: CGPoint(x: rect.midX + width * 0.3, y: rect.minY + height * 0.2)
        )
        
        context.addPath(path)
        context.fillPath()
        
        // Stem
        let stemRect = CGRect(x: rect.midX - width * 0.05, y: rect.midY + height * 0.1, width: width * 0.1, height: height * 0.3)
        context.fill(stemRect)
    }
    
    private func getSuitColor(_ suit: Suit) -> (CGFloat, CGFloat, CGFloat) {
        switch suit {
        case .hearts, .diamonds:
            return (0.8, 0.1, 0.1) // Romanian red
        case .clubs, .spades:
            return (0.0, 0.2, 0.6) // Romanian blue
        }
    }
    
    // MARK: - Specialized Texture Generation
    
    private func generateCardNormalMapData(card: Card, texture: MTLTexture) throws {
        // Generate normal map data for card embossing
        let width = texture.width
        let height = texture.height
        let bytesPerRow = width * 4
        
        var normalData = [UInt8](repeating: 0, count: width * height * 4)
        
        for y in 0..<height {
            for x in 0..<width {
                let index = (y * width + x) * 4
                
                // Create embossed effect around edges and suit symbols
                let normalX = calculateNormalX(x: x, y: y, width: width, height: height)
                let normalY = calculateNormalY(x: x, y: y, width: width, height: height)
                let normalZ = sqrt(max(0, 1 - normalX * normalX - normalY * normalY))
                
                normalData[index] = UInt8((normalX * 0.5 + 0.5) * 255)     // R
                normalData[index + 1] = UInt8((normalY * 0.5 + 0.5) * 255) // G
                normalData[index + 2] = UInt8(normalZ * 255)               // B
                normalData[index + 3] = 255                                // A
            }
        }
        
        let region = MTLRegionMake2D(0, 0, width, height)
        texture.replace(region: region, mipmapLevel: 0, withBytes: normalData, bytesPerRow: bytesPerRow)
    }
    
    private func calculateNormalX(x: Int, y: Int, width: Int, height: Int) -> Float {
        // Create embossing effect based on distance to edges
        let distToLeftRight = min(x, width - x)
        let edgeFactorX = Float(distToLeftRight) / Float(width / 8)
        return sin(edgeFactorX * .pi) * 0.3
    }
    
    private func calculateNormalY(x: Int, y: Int, width: Int, height: Int) -> Float {
        // Create embossing effect based on distance to top/bottom
        let distToTopBottom = min(y, height - y)
        let edgeFactorY = Float(distToTopBottom) / Float(height / 8)
        return sin(edgeFactorY * .pi) * 0.3
    }
    
    private func renderRomanianPatternToTexture(type: RomanianPatternType, texture: MTLTexture) throws {
        // Generate Romanian cultural patterns
        // Implementation would create authentic Romanian folk art patterns
        // For now, create a simple geometric pattern
        
        let width = texture.width
        let height = texture.height
        let bytesPerRow = width * 4
        
        var patternData = [UInt8](repeating: 0, count: width * height * 4)
        
        for y in 0..<height {
            for x in 0..<width {
                let index = (y * width + x) * 4
                
                let pattern = generateRomanianPatternPixel(
                    x: x, y: y,
                    width: width, height: height,
                    type: type
                )
                
                patternData[index] = pattern.r     // R
                patternData[index + 1] = pattern.g // G
                patternData[index + 2] = pattern.b // B
                patternData[index + 3] = pattern.a // A
            }
        }
        
        let region = MTLRegionMake2D(0, 0, width, height)
        texture.replace(region: region, mipmapLevel: 0, withBytes: patternData, bytesPerRow: bytesPerRow)
    }
    
    private func renderEmbroideryPatternToTexture(intensity: Float, texture: MTLTexture) throws {
        // Generate embroidery pattern texture
        // Creates a texture that simulates Romanian embroidery
        
        let width = texture.width
        let height = texture.height
        let bytesPerRow = width * 4
        
        var embroideryData = [UInt8](repeating: 0, count: width * height * 4)
        
        for y in 0..<height {
            for x in 0..<width {
                let index = (y * width + x) * 4
                
                let stitch = generateEmbroideryStitch(x: x, y: y, width: width, height: height, intensity: intensity)
                
                embroideryData[index] = stitch.r     // R
                embroideryData[index + 1] = stitch.g // G
                embroideryData[index + 2] = stitch.b // B
                embroideryData[index + 3] = stitch.a // A
            }
        }
        
        let region = MTLRegionMake2D(0, 0, width, height)
        texture.replace(region: region, mipmapLevel: 0, withBytes: embroideryData, bytesPerRow: bytesPerRow)
    }
    
    private func renderFolkMotifToTexture(motif: RomanianMotif, texture: MTLTexture) throws {
        // Generate specific Romanian folk motif
        let width = texture.width
        let height = texture.height
        let bytesPerRow = width * 4
        
        var motifData = [UInt8](repeating: 0, count: width * height * 4)
        
        for y in 0..<height {
            for x in 0..<width {
                let index = (y * width + x) * 4
                
                let motifPixel = generateFolkMotifPixel(
                    x: x, y: y,
                    width: width, height: height,
                    motif: motif
                )
                
                motifData[index] = motifPixel.r     // R
                motifData[index + 1] = motifPixel.g // G
                motifData[index + 2] = motifPixel.b // B
                motifData[index + 3] = motifPixel.a // A
            }
        }
        
        let region = MTLRegionMake2D(0, 0, width, height)
        texture.replace(region: region, mipmapLevel: 0, withBytes: motifData, bytesPerRow: bytesPerRow)
    }
    
    // MARK: - Pattern Generation Helpers
    
    private func generateRomanianPatternPixel(x: Int, y: Int, width: Int, height: Int, type: RomanianPatternType) -> (r: UInt8, g: UInt8, b: UInt8, a: UInt8) {
        let fx = Float(x) / Float(width)
        let fy = Float(y) / Float(height)
        
        switch type {
        case .traditionalBorder:
            let borderPattern = sin(fx * 16 * .pi) * sin(fy * 16 * .pi)
            let intensity = UInt8(max(0, min(255, (borderPattern * 0.5 + 0.5) * 255)))
            return (200, 150, 50, intensity)
            
        case .floralMotif:
            let floralPattern = sin(fx * 8 * .pi) * cos(fy * 8 * .pi) + sin(fx * 12 * .pi) * sin(fy * 6 * .pi)
            let intensity = UInt8(max(0, min(255, (floralPattern * 0.3 + 0.5) * 255)))
            return (180, 50, 50, intensity)
            
        case .geometricPattern:
            let geomPattern = (sin(fx * 12 * .pi) > 0 && sin(fy * 12 * .pi) > 0) ? 1.0 : 0.0
            let intensity = UInt8(geomPattern * 255)
            return (50, 100, 200, intensity)
        }
    }
    
    private func generateEmbroideryStitch(x: Int, y: Int, width: Int, height: Int, intensity: Float) -> (r: UInt8, g: UInt8, b: UInt8, a: UInt8) {
        let fx = Float(x) / Float(width)
        let fy = Float(y) / Float(height)
        
        // Create stitch pattern
        let stitchX = sin(fx * 32 * .pi + fy * 4 * .pi)
        let stitchY = sin(fy * 32 * .pi + fx * 4 * .pi)
        let stitch = (stitchX * stitchX + stitchY * stitchY) * intensity
        
        let red = UInt8(min(255, max(0, 220 * stitch)))
        let green = UInt8(min(255, max(0, 180 * stitch)))
        let blue = UInt8(min(255, max(0, 60 * stitch)))
        let alpha = UInt8(min(255, max(0, stitch * 255)))
        
        return (red, green, blue, alpha)
    }
    
    private func generateFolkMotifPixel(x: Int, y: Int, width: Int, height: Int, motif: RomanianMotif) -> (r: UInt8, g: UInt8, b: UInt8, a: UInt8) {
        let fx = Float(x) / Float(width) - 0.5
        let fy = Float(y) / Float(height) - 0.5
        let distance = sqrt(fx * fx + fy * fy)
        
        switch motif {
        case .rosette:
            let angle = atan2(fy, fx)
            let rosette = sin(angle * 8) * exp(-distance * 4)
            let intensity = UInt8(max(0, min(255, (rosette * 0.5 + 0.5) * 255)))
            return (200, 100, 150, intensity)
            
        case .cross:
            let crossPattern = (abs(fx) < 0.1 || abs(fy) < 0.1) && distance < 0.4 ? 1.0 : 0.0
            let intensity = UInt8(crossPattern * 255)
            return (150, 200, 100, intensity)
            
        case .diamond:
            let diamondPattern = (abs(fx) + abs(fy) < 0.3) ? 1.0 : 0.0
            let intensity = UInt8(diamondPattern * 255)
            return (100, 150, 200, intensity)
        }
    }
    
    // MARK: - Cache Management
    
    private func cacheTexture(_ texture: MTLTexture, key: String, type: TextureType) {
        let size = estimateTextureSize(texture)
        
        // Check if we need to free space
        if cacheSize + size > maxCacheSize {
            freeOldestTextures(requiredSpace: size)
        }
        
        let cachedTexture = CachedTexture(
            texture: texture,
            type: type,
            size: size,
            accessTime: CACurrentMediaTime()
        )
        
        cache[key] = cachedTexture
        cacheSize += size
        updateCacheMetrics()
    }
    
    private func freeOldestTextures(requiredSpace: Int) {
        // Sort by access time and remove oldest
        let sortedKeys = cache.keys.sorted { key1, key2 in
            cache[key1]!.accessTime < cache[key2]!.accessTime
        }
        
        var freedSpace = 0
        for key in sortedKeys {
            if freedSpace >= requiredSpace { break }
            
            if let cachedTexture = cache[key] {
                freedSpace += cachedTexture.size
                cacheSize -= cachedTexture.size
                cache.removeValue(forKey: key)
            }
        }
    }
    
    private func performCacheCleanup() {
        let currentTime = CACurrentMediaTime()
        let maxAge: CFTimeInterval = 300 // 5 minutes
        
        let expiredKeys = cache.compactMap { key, cachedTexture in
            currentTime - cachedTexture.accessTime > maxAge ? key : nil
        }
        
        for key in expiredKeys {
            if let cachedTexture = cache[key] {
                cacheSize -= cachedTexture.size
                cache.removeValue(forKey: key)
            }
        }
        
        updateCacheMetrics()
        
        print("🧹 TextureCache cleanup: removed \(expiredKeys.count) expired textures")
    }
    
    private func estimateTextureSize(_ texture: MTLTexture) -> Int {
        let bytesPerPixel = 4 // Assuming BGRA8
        let baseSize = texture.width * texture.height * bytesPerPixel
        
        // Account for mipmaps
        if texture.mipmapLevelCount > 1 {
            return Int(Float(baseSize) * 1.33) // Approximate mipmap overhead
        }
        
        return baseSize
    }
    
    private func generateMipmaps(for texture: MTLTexture) {
        guard let commandQueue = device.makeCommandQueue(),
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let blitEncoder = commandBuffer.makeBlitCommandEncoder() else { return }
        
        blitEncoder.generateMipmaps(for: texture)
        blitEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
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
    
    private func determineCulturalPattern(for card: Card) -> RomanianPatternType {
        if card.value == 7 {
            return .floralMotif // Special pattern for sevens
        } else if card.isPointCard {
            return .traditionalBorder
        } else {
            return .geometricPattern
        }
    }
    
    private func preloadEssentialTextures() {
        // Preload commonly used patterns
        Task {
            do {
                _ = try await generateRomanianPattern(type: .traditionalBorder)
                _ = try await generateRomanianPattern(type: .floralMotif)
                _ = try await generateRomanianPattern(type: .geometricPattern)
                
                print("✅ Essential textures preloaded")
            } catch {
                print("⚠️ Failed to preload essential textures: \(error)")
            }
        }
    }
}

// MARK: - Supporting Types

struct CachedTexture {
    let texture: MTLTexture
    let type: TextureType
    let size: Int
    var accessTime: CFTimeInterval
}

enum TextureType {
    case cardFace
    case normalMap
    case culturalPattern
    case embroidery
    case folkMotif
}

enum RomanianPatternType: String {
    case traditionalBorder = "traditional_border"
    case floralMotif = "floral_motif"
    case geometricPattern = "geometric_pattern"
}

enum RomanianMotif: String {
    case rosette = "rosette"
    case cross = "cross"
    case diamond = "diamond"
}

enum TextureCacheError: Error {
    case textureCreationFailed
    case contextCreationFailed
    case dataExtractionFailed
    case patternGenerationFailed
}

// MARK: - Extensions

extension MTLTexture {
    var memoryFootprint: Int {
        let bytesPerPixel = 4 // Assuming BGRA8
        let baseSize = width * height * bytesPerPixel
        
        if mipmapLevelCount > 1 {
            return Int(Float(baseSize) * 1.33)
        }
        
        return baseSize
    }
}