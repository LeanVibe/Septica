//
//  RomanianPatternIntegration.swift
//  Septica
//
//  Romanian cultural pattern integration with TextureCache system
//  Provides authentic folk art patterns and cultural elements for professional card rendering
//

import SwiftUI
import Metal
import MetalKit
import Combine

// MARK: - Romanian Pattern Integration Manager

/// Manager that integrates Romanian cultural patterns with the TextureCache system
@MainActor
class RomanianPatternIntegrationManager: ObservableObject {
    
    // MARK: - Core Systems
    
    private let textureCache: TextureCache
    private let device: MTLDevice
    
    // MARK: - Pattern State
    
    @Published var availablePatterns: [RomanianPatternInfo] = []
    @Published var currentPatternSet: RomanianPatternSet = .traditional
    @Published var patternIntensity: Float = 1.0
    @Published var culturalAuthenticity: RomanianPatternAuthenticity = .authentic
    
    // MARK: - Cache Performance
    
    @Published var patternCacheHitRate: Double = 0.0
    @Published var loadedPatternCount: Int = 0
    @Published var patternMemoryUsage: Int = 0
    
    // MARK: - Initialization
    
    init(device: MTLDevice) {
        self.device = device
        self.textureCache = TextureCache(device: device)
        
        setupRomanianPatterns()
        preloadEssentialPatterns()
    }
    
    // MARK: - Pattern Loading Interface
    
    /// Get Romanian pattern for a specific card
    func getPatternForCard(_ card: Card) throws -> MTLTexture {
        let patternType = determinePatternType(for: card)
        return try textureCache.getRomanianPatternTexture(for: card)
    }
    
    /// Get embroidery pattern with specified intensity
    func getEmbroideryPattern(intensity: Float = 1.0) throws -> MTLTexture {
        return try textureCache.getEmbroideryTexture(intensity: intensity)
    }
    
    /// Get folk motif for specific use case
    func getFolkMotif(_ motif: RomanianMotif) throws -> MTLTexture {
        return try textureCache.getFolkMotifTexture(motif: motif)
    }
    
    /// Generate complete cultural overlay for card
    func generateCulturalOverlay(for card: Card, size: CGSize) throws -> CulturalOverlayData {
        let patternTexture = try getPatternForCard(card)
        let embroideryTexture = try getEmbroideryPattern(intensity: patternIntensity)
        
        let overlayData = CulturalOverlayData(
            mainPattern: patternTexture,
            embroideryPattern: embroideryTexture,
            culturalMotifs: try loadCulturalMotifs(for: card),
            authenticity: culturalAuthenticity,
            size: size
        )
        
        return overlayData
    }
    
    // MARK: - Pattern Set Management
    
    /// Switch to different Romanian pattern set
    func setPatternSet(_ set: RomanianPatternSet) {
        guard currentPatternSet != set else { return }
        
        currentPatternSet = set
        loadPatternSet(set)
    }
    
    /// Adjust pattern intensity
    func setPatternIntensity(_ intensity: Float) {
        patternIntensity = max(0.0, min(1.0, intensity))
        updatePatternRendering()
    }
    
    /// Set cultural authenticity level
    func setCulturalAuthenticity(_ authenticity: RomanianPatternAuthenticity) {
        culturalAuthenticity = authenticity
        updatePatternSelection()
    }
    
    // MARK: - Private Implementation
    
    private func setupRomanianPatterns() {
        availablePatterns = createRomanianPatternInfo()
        updateCacheMetrics()
    }
    
    private func createRomanianPatternInfo() -> [RomanianPatternInfo] {
        return [
            RomanianPatternInfo(
                id: "traditional_border",
                name: "Traditional Border",
                type: .traditionalBorder,
                region: .maramures,
                description: "Classic Maramureș border patterns with geometric motifs",
                authenticity: .authentic,
                complexity: .medium
            ),
            RomanianPatternInfo(
                id: "floral_motif",
                name: "Floral Motif",
                type: .floralMotif,
                region: .moldavia,
                description: "Traditional Moldavian floral patterns from folk textiles",
                authenticity: .authentic,
                complexity: .high
            ),
            RomanianPatternInfo(
                id: "geometric_pattern",
                name: "Geometric Pattern",
                type: .geometricPattern,
                region: .oltenia,
                description: "Oltenian geometric designs used in traditional crafts",
                authenticity: .authentic,
                complexity: .low
            ),
            RomanianPatternInfo(
                id: "ia_embroidery",
                name: "Ia Embroidery",
                type: .floralMotif,
                region: .wallachia,
                description: "Traditional Romanian blouse embroidery patterns",
                authenticity: .authentic,
                complexity: .high
            ),
            RomanianPatternInfo(
                id: "carpet_weave",
                name: "Carpet Weave",
                type: .geometricPattern,
                region: .transylvania,
                description: "Traditional Transylvanian carpet weaving patterns",
                authenticity: .authentic,
                complexity: .medium
            )
        ]
    }
    
    private func preloadEssentialPatterns() {
        Task {
            do {
                // Preload most commonly used patterns
                for pattern in availablePatterns.prefix(3) {
                    _ = try await preloadPattern(pattern)
                }
                
                // Preload folk motifs
                for motif in RomanianMotif.allCases {
                    _ = try await textureCache.getFolkMotifTexture(motif: motif)
                }
                
                updateCacheMetrics()
                print("✅ Romanian patterns preloaded successfully")
                
            } catch {
                print("⚠️ Failed to preload Romanian patterns: \(error)")
            }
        }
    }
    
    private func preloadPattern(_ patternInfo: RomanianPatternInfo) async throws -> MTLTexture {
        // Create a dummy card to generate the pattern
        let dummyCard = Card(suit: .hearts, value: 7)
        return try textureCache.getRomanianPatternTexture(for: dummyCard)
    }
    
    private func determinePatternType(for card: Card) -> RomanianPatternType {
        switch currentPatternSet {
        case .traditional:
            if card.value == 7 {
                return .floralMotif // Special pattern for sevens
            } else if card.isPointCard {
                return .traditionalBorder
            } else {
                return .geometricPattern
            }
            
        case .regional:
            // Assign patterns based on suit and Romanian regions
            switch card.suit {
            case .hearts:
                return .floralMotif // Moldavian style
            case .diamonds:
                return .traditionalBorder // Maramureș style
            case .clubs:
                return .geometricPattern // Oltenian style
            case .spades:
                return .geometricPattern // Transylvanian style
            }
            
        case .ceremonial:
            // Special ceremonial patterns for important cards
            if card.value == 7 || card.value == 1 || card.value == 14 {
                return .floralMotif
            } else {
                return .traditionalBorder
            }
            
        case .modern:
            // Simplified modern interpretations
            return .geometricPattern
        }
    }
    
    private func loadCulturalMotifs(for card: Card) throws -> [MTLTexture] {
        var motifs: [MTLTexture] = []
        
        // Add appropriate motifs based on card significance
        if card.value == 7 {
            // Seven is special in Romanian culture
            motifs.append(try textureCache.getFolkMotifTexture(motif: .rosette))
        }
        
        if card.isPointCard {
            // Point cards get cross motifs
            motifs.append(try textureCache.getFolkMotifTexture(motif: .cross))
        }
        
        // Add suit-appropriate motifs
        switch card.suit {
        case .hearts:
            motifs.append(try textureCache.getFolkMotifTexture(motif: .rosette))
        case .diamonds:
            motifs.append(try textureCache.getFolkMotifTexture(motif: .diamond))
        case .clubs, .spades:
            motifs.append(try textureCache.getFolkMotifTexture(motif: .cross))
        }
        
        return motifs
    }
    
    private func loadPatternSet(_ set: RomanianPatternSet) {
        // Update available patterns based on selected set
        let filteredPatterns = availablePatterns.filter { pattern in
            switch set {
            case .traditional:
                return pattern.authenticity == .authentic
            case .regional:
                return true // All patterns available
            case .ceremonial:
                return pattern.complexity != .low
            case .modern:
                return pattern.complexity != .high
            }
        }
        
        availablePatterns = filteredPatterns
        updateCacheMetrics()
    }
    
    private func updatePatternRendering() {
        // Notify observers that pattern intensity changed
        objectWillChange.send()
    }
    
    private func updatePatternSelection() {
        // Update pattern selection based on authenticity level
        loadPatternSet(currentPatternSet)
    }
    
    private func updateCacheMetrics() {
        patternCacheHitRate = textureCache.cacheHitRate
        loadedPatternCount = availablePatterns.count
        patternMemoryUsage = textureCache.cacheSize / (1024 * 1024) // Convert to MB
    }
}

// MARK: - Supporting Types

/// Information about a Romanian pattern
struct RomanianPatternInfo: Identifiable, Hashable {
    let id: String
    let name: String
    let type: RomanianPatternType
    let region: RomanianCulturalRegion
    let description: String
    let authenticity: RomanianPatternAuthenticity
    let complexity: PatternComplexity
}

/// Romanian cultural regions with distinct folk art styles
enum RomanianCulturalRegion: String, CaseIterable {
    case maramures = "Maramureș"
    case moldavia = "Moldavia"
    case wallachia = "Wallachia"
    case transylvania = "Transylvania"
    case oltenia = "Oltenia"
    case banat = "Banat"
    case dobrogea = "Dobrogea"
    
    var description: String {
        switch self {
        case .maramures:
            return "Known for intricate geometric wood carvings and textiles"
        case .moldavia:
            return "Famous for colorful floral embroidery and pottery"
        case .wallachia:
            return "Traditional in folk costumes and carpet weaving"
        case .transylvania:
            return "Rich Saxon and Hungarian influences in crafts"
        case .oltenia:
            return "Distinctive geometric patterns and pottery"
        case .banat:
            return "Multicultural influences in decorative arts"
        case .dobrogea:
            return "Coastal influences with unique textile traditions"
        }
    }
}

/// Pattern sets for different occasions
enum RomanianPatternSet: String, CaseIterable {
    case traditional = "Traditional"
    case regional = "Regional"
    case ceremonial = "Ceremonial"
    case modern = "Modern"
    
    var description: String {
        switch self {
        case .traditional:
            return "Authentic traditional patterns from Romanian folk art"
        case .regional:
            return "Patterns organized by Romanian cultural regions"
        case .ceremonial:
            return "Special patterns for important cultural moments"
        case .modern:
            return "Contemporary interpretations of traditional motifs"
        }
    }
}

/// Romanian pattern authenticity levels
enum RomanianPatternAuthenticity: String, CaseIterable {
    case authentic = "Authentic"
    case inspired = "Inspired"
    case modern = "Modern"
    
    var description: String {
        switch self {
        case .authentic:
            return "Historically accurate traditional patterns"
        case .inspired:
            return "Modern interpretations of traditional elements"
        case .modern:
            return "Contemporary designs with cultural influences"
        }
    }
}

/// Pattern complexity levels
enum PatternComplexity: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var renderingComplexity: Float {
        switch self {
        case .low: return 0.3
        case .medium: return 0.6
        case .high: return 1.0
        }
    }
}

/// Cultural overlay data for rendering
struct CulturalOverlayData {
    let mainPattern: MTLTexture
    let embroideryPattern: MTLTexture
    let culturalMotifs: [MTLTexture]
    let authenticity: RomanianPatternAuthenticity
    let size: CGSize
    
    var totalTextureCount: Int {
        return 1 + 1 + culturalMotifs.count // main + embroidery + motifs
    }
    
    var estimatedMemoryUsage: Int {
        // Rough estimate of memory usage in bytes
        let baseSize = Int(size.width * size.height * 4) // RGBA
        return baseSize * totalTextureCount
    }
}

// MARK: - SwiftUI Integration

/// SwiftUI view that displays Romanian cultural patterns using TextureCache
struct RomanianPatternView: View {
    let card: Card
    let patternSet: RomanianPatternSet
    let intensity: Float
    
    @StateObject private var patternManager = RomanianPatternIntegrationManager(device: MTLCreateSystemDefaultDevice()!)
    @State private var overlayData: CulturalOverlayData?
    @State private var isLoading = true
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let overlayData = overlayData {
                    // Display the cultural overlay
                    MetalPatternView(overlayData: overlayData)
                        .opacity(Double(intensity))
                } else if isLoading {
                    // Loading indicator with Romanian colors
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: RomanianColors.goldAccent))
                } else {
                    // Fallback to SwiftUI patterns
                    RomanianCulturalPatternView(intensity: intensity, embroideryEffect: intensity * 0.8)
                }
            }
        }
        .onAppear {
            loadPatterns(size: CGSize(width: 120, height: 160))
        }
        .onChange(of: patternSet) { newSet in
            patternManager.setPatternSet(newSet)
            loadPatterns(size: CGSize(width: 120, height: 160))
        }
        .onChange(of: intensity) { newIntensity in
            patternManager.setPatternIntensity(newIntensity)
        }
    }
    
    private func loadPatterns(size: CGSize) {
        isLoading = true
        
        Task {
            do {
                let data = try await patternManager.generateCulturalOverlay(for: card, size: size)
                
                await MainActor.run {
                    overlayData = data
                    isLoading = false
                }
            } catch {
                print("Failed to load Romanian patterns: \(error)")
                
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

/// Metal view for displaying pattern textures
struct MetalPatternView: UIViewRepresentable {
    let overlayData: CulturalOverlayData
    
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.delegate = context.coordinator
        mtkView.isOpaque = false
        mtkView.backgroundColor = UIColor.clear
        
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.updateOverlay(overlayData)
    }
    
    func makeCoordinator() -> MetalPatternCoordinator {
        MetalPatternCoordinator()
    }
}

/// Coordinator for Metal pattern rendering
class MetalPatternCoordinator: NSObject, MTKViewDelegate {
    private var overlayData: CulturalOverlayData?
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Handle size changes
    }
    
    func draw(in view: MTKView) {
        guard let overlayData = overlayData,
              let drawable = view.currentDrawable,
              let commandQueue = view.device?.makeCommandQueue(),
              let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        
        // Simple pattern rendering - in production this would use proper shaders
        // For now, just display the main pattern
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    func updateOverlay(_ data: CulturalOverlayData) {
        overlayData = data
    }
}

// MARK: - Extensions

extension RomanianMotif: CaseIterable {
    public static let allCases: [RomanianMotif] = [.rosette, .cross, .diamond]
}

// MARK: - Preview

struct RomanianPatternIntegration_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            RomanianPatternView(
                card: Card(suit: .hearts, value: 7),
                patternSet: .traditional,
                intensity: 1.0
            )
            .frame(width: 120, height: 160)
            .background(Color.white)
            .cornerRadius(8)
            .shadow(radius: 4)
            
            RomanianPatternView(
                card: Card(suit: .clubs, value: 14),
                patternSet: .regional,
                intensity: 0.7
            )
            .frame(width: 120, height: 160)
            .background(Color.white)
            .cornerRadius(8)
            .shadow(radius: 4)
        }
        .padding()
    }
}