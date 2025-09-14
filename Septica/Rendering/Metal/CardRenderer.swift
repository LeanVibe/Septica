//
//  CardRenderer.swift
//  Septica
//
//  Dedicated card rendering system for Romanian Septica game
//  Provides premium visual effects for authentic card game experience
//

#if canImport(Metal)
import Metal
import MetalKit
#endif
import simd
import SwiftUI
import Combine

// MARK: - Card Animation States

enum CardAnimationState: String, CaseIterable {
    case idle = "idle"
    case selected = "selected"
    case hovering = "hovering"
    case flipping = "flipping"
    case playing = "playing"
    case winning = "winning"
    
    var duration: TimeInterval {
        switch self {
        case .idle: return 0.0
        case .selected: return 0.3
        case .hovering: return 0.2
        case .flipping: return 0.8
        case .playing: return 0.5
        case .winning: return 1.2
        }
    }
}

// MARK: - Card Visual Properties

struct CardVisualProperties {
    var position: simd_float3
    var rotation: simd_float3
    var scale: simd_float3
    var highlightIntensity: Float
    var glowColor: simd_float4
    var flipAngle: Float
    var animationProgress: Float
    
    static let defaultProperties = CardVisualProperties(
        position: simd_float3(0, 0, 0),
        rotation: simd_float3(0, 0, 0),
        scale: simd_float3(1, 1, 1),
        highlightIntensity: 0.0,
        glowColor: simd_float4(0.8, 0.6, 0.2, 1.0), // Romanian gold
        flipAngle: 0.0,
        animationProgress: 0.0
    )
}

// MARK: - Romanian Cultural Constants

struct RomanianCardConstants {
    // Traditional Romanian colors
    static let traditionalRed = simd_float4(0.8, 0.1, 0.1, 1.0)
    static let traditionalBlue = simd_float4(0.0, 0.3, 0.6, 1.0)
    static let traditionalYellow = simd_float4(1.0, 0.8, 0.0, 1.0)
    static let folkGold = simd_float4(0.9, 0.7, 0.2, 1.0)
    
    // Card dimensions (Romanian playing card proportions)
    static let cardWidth: Float = 2.5
    static let cardHeight: Float = 3.5
    static let cardThickness: Float = 0.1
    static let cornerRadius: Float = 0.2
    
    // Cultural animation timings
    static let tradicionalFlipDuration: TimeInterval = 0.8
    static let victoryCelebrationDuration: TimeInterval = 2.0
    static let sevenSpecialEffectDuration: TimeInterval = 1.5
}

// MARK: - Card Renderer Protocol

protocol CardRendererDelegate: AnyObject {
    func cardRenderer(_ renderer: CardRenderer, didCompleteAnimation cardId: UUID, animationType: CardAnimationState)
    func cardRenderer(_ renderer: CardRenderer, didDetectTouch touch: CGPoint) -> Card?
    func cardRenderer(_ renderer: CardRenderer, willBeginAnimation cardId: UUID, animationType: CardAnimationState)
}

// MARK: - Card Renderer Implementation

@MainActor
class CardRenderer: ObservableObject {
    
    // MARK: - Core Properties
    
    weak var delegate: CardRendererDelegate?
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    
    // MARK: - Rendering Resources
    
    private var cardVertexBuffer: MTLBuffer?
    private var cardIndexBuffer: MTLBuffer?
    private var cardUniformBuffer: MTLBuffer?
    
    // MARK: - Pipeline States (Fallback for Metal Toolchain Issue)
    
    private var isMetalAvailable: Bool = false
    private var fallbackToSwiftUI: Bool = true
    
    // MARK: - Card State Management
    
    @Published var activeCards: [UUID: CardVisualProperties] = [:]
    @Published var cardAnimations: [UUID: CardAnimationState] = [:]
    @Published var isRomanianEffectsEnabled: Bool = true
    
    // MARK: - Performance Monitoring
    
    @Published var renderingPerformance: RenderingPerformanceMetrics = RenderingPerformanceMetrics()
    
    // MARK: - Initialization
    
    init(device: MTLDevice, commandQueue: MTLCommandQueue) {
        self.device = device
        self.commandQueue = commandQueue
        
        // Test Metal availability
        setupMetalResources()
        
        print("🎮 CardRenderer initialized:")
        print("   - Metal Available: \(isMetalAvailable)")
        print("   - Fallback Mode: \(fallbackToSwiftUI)")
        print("   - Romanian Effects: \(isRomanianEffectsEnabled)")
    }
    
    // MARK: - Metal Resource Setup
    
    private func setupMetalResources() {
        do {
            try createCardGeometry()
            try allocateBuffers()
            isMetalAvailable = true
            fallbackToSwiftUI = false
            print("✅ Metal resources initialized successfully")
        } catch {
            print("⚠️ Metal setup failed: \(error)")
            print("   Falling back to SwiftUI rendering mode")
            isMetalAvailable = false
            fallbackToSwiftUI = true
        }
    }
    
    private func createCardGeometry() throws {
        // Create card quad vertices (Romanian card proportions)
        let vertices: [CardVertex] = [
            // Front face
            CardVertex(position: simd_float3(-RomanianCardConstants.cardWidth/2, -RomanianCardConstants.cardHeight/2, 0),
                      texCoord: simd_float2(0, 1),
                      normal: simd_float3(0, 0, 1)),
            CardVertex(position: simd_float3(RomanianCardConstants.cardWidth/2, -RomanianCardConstants.cardHeight/2, 0),
                      texCoord: simd_float2(1, 1),
                      normal: simd_float3(0, 0, 1)),
            CardVertex(position: simd_float3(RomanianCardConstants.cardWidth/2, RomanianCardConstants.cardHeight/2, 0),
                      texCoord: simd_float2(1, 0),
                      normal: simd_float3(0, 0, 1)),
            CardVertex(position: simd_float3(-RomanianCardConstants.cardWidth/2, RomanianCardConstants.cardHeight/2, 0),
                      texCoord: simd_float2(0, 0),
                      normal: simd_float3(0, 0, 1))
        ]
        
        let indices: [UInt16] = [0, 1, 2, 0, 2, 3]
        
        // Create vertex buffer
        let vertexBufferSize = vertices.count * MemoryLayout<CardVertex>.stride
        guard let vertexBuffer = device.makeBuffer(bytes: vertices, length: vertexBufferSize, options: []) else {
            throw RendererError.bufferAllocationFailed
        }
        vertexBuffer.label = "CardVertexBuffer"
        self.cardVertexBuffer = vertexBuffer
        
        // Create index buffer
        let indexBufferSize = indices.count * MemoryLayout<UInt16>.stride
        guard let indexBuffer = device.makeBuffer(bytes: indices, length: indexBufferSize, options: []) else {
            throw RendererError.bufferAllocationFailed
        }
        indexBuffer.label = "CardIndexBuffer"
        self.cardIndexBuffer = indexBuffer
    }
    
    private func allocateBuffers() throws {
        // Allocate uniform buffer for card transformations
        let uniformBufferSize = MemoryLayout<CardUniforms>.stride * 256 // Support up to 256 cards
        guard let uniformBuffer = device.makeBuffer(length: uniformBufferSize, options: [.storageModeShared]) else {
            throw RendererError.bufferAllocationFailed
        }
        uniformBuffer.label = "CardUniformBuffer"
        self.cardUniformBuffer = uniformBuffer
    }
    
    // MARK: - Public Card Management API
    
    /// Add a card to the rendering system
    func addCard(_ card: Card, at position: simd_float3, animated: Bool = true) {
        let properties = CardVisualProperties(
            position: position,
            rotation: simd_float3(0, 0, 0),
            scale: simd_float3(1, 1, 1),
            highlightIntensity: 0.0,
            glowColor: isRomanianEffectsEnabled ? RomanianCardConstants.folkGold : simd_float4(0.5, 0.5, 0.5, 1.0),
            flipAngle: 0.0,
            animationProgress: 0.0
        )
        
        activeCards[card.id] = properties
        
        if animated {
            animateCardEntry(card.id)
        }
    }
    
    /// Remove a card from the rendering system
    func removeCard(_ cardId: UUID, animated: Bool = true) {
        if animated {
            animateCardExit(cardId) { [weak self] in
                self?.activeCards.removeValue(forKey: cardId)
                self?.cardAnimations.removeValue(forKey: cardId)
            }
        } else {
            activeCards.removeValue(forKey: cardId)
            cardAnimations.removeValue(forKey: cardId)
        }
    }
    
    /// Update card position
    func updateCardPosition(_ cardId: UUID, to position: simd_float3, animated: Bool = true) {
        guard var properties = activeCards[cardId] else { return }
        
        if animated {
            animateCardMovement(cardId, from: properties.position, to: position)
        } else {
            properties.position = position
            activeCards[cardId] = properties
        }
    }
    
    /// Set card selection state
    func setCardSelected(_ cardId: UUID, selected: Bool) {
        if selected {
            setCardAnimation(cardId, state: .selected)
            updateCardHighlight(cardId, intensity: 1.0)
        } else {
            setCardAnimation(cardId, state: .idle)
            updateCardHighlight(cardId, intensity: 0.0)
        }
    }
    
    /// Animate card flip (for revealing cards)
    func flipCard(_ cardId: UUID, completion: @escaping () -> Void = {}) {
        setCardAnimation(cardId, state: .flipping)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + RomanianCardConstants.tradicionalFlipDuration) {
            self.setCardAnimation(cardId, state: .idle)
            completion()
        }
    }
    
    /// Play special effect for 7 (wild card) in Romanian Septica
    func playSevenSpecialEffect(_ cardId: UUID) {
        guard isRomanianEffectsEnabled else { return }
        
        // Special golden glow effect for the traditional wild card
        updateCardGlow(cardId, color: RomanianCardConstants.folkGold, intensity: 1.5)
        setCardAnimation(cardId, state: .winning)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + RomanianCardConstants.sevenSpecialEffectDuration) {
            self.setCardAnimation(cardId, state: .idle)
            self.updateCardGlow(cardId, color: RomanianCardConstants.folkGold, intensity: 0.0)
        }
    }
    
    /// Victory celebration effect
    func playVictoryCelebration(for cardIds: [UUID]) {
        guard isRomanianEffectsEnabled else { return }
        
        for cardId in cardIds {
            setCardAnimation(cardId, state: .winning)
            updateCardGlow(cardId, color: RomanianCardConstants.traditionalYellow, intensity: 2.0)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + RomanianCardConstants.victoryCelebrationDuration) {
            for cardId in cardIds {
                self.setCardAnimation(cardId, state: .idle)
                self.updateCardGlow(cardId, color: RomanianCardConstants.folkGold, intensity: 0.0)
            }
        }
    }
    
    // MARK: - Private Animation Methods
    
    private func setCardAnimation(_ cardId: UUID, state: CardAnimationState) {
        cardAnimations[cardId] = state
        delegate?.cardRenderer(self, willBeginAnimation: cardId, animationType: state)
        
        // Auto-complete animation after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + state.duration) {
            if self.cardAnimations[cardId] == state {
                self.cardAnimations[cardId] = .idle
                self.delegate?.cardRenderer(self, didCompleteAnimation: cardId, animationType: state)
            }
        }
    }
    
    private func animateCardEntry(_ cardId: UUID) {
        guard var properties = activeCards[cardId] else { return }
        
        // Start with scale 0 and animate to normal size
        properties.scale = simd_float3(0, 0, 0)
        activeCards[cardId] = properties
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
            properties.scale = simd_float3(1, 1, 1)
            self.activeCards[cardId] = properties
        }
    }
    
    private func animateCardExit(_ cardId: UUID, completion: @escaping () -> Void) {
        guard var properties = activeCards[cardId] else {
            completion()
            return
        }
        
        UIView.animate(withDuration: 0.3) {
            properties.scale = simd_float3(0, 0, 0)
            properties.highlightIntensity = 0.0
            self.activeCards[cardId] = properties
        } completion: { _ in
            completion()
        }
    }
    
    private func animateCardMovement(_ cardId: UUID, from startPosition: simd_float3, to endPosition: simd_float3) {
        let startTime = CACurrentMediaTime()
        let duration: TimeInterval = 0.5
        
        Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { timer in
            let elapsed = CACurrentMediaTime() - startTime
            let progress = min(elapsed / duration, 1.0)
            
            // Smooth easing function
            let easedProgress = Float(1 - cos(progress * .pi) / 2)
            
            guard var properties = self.activeCards[cardId] else {
                timer.invalidate()
                return
            }
            
            properties.position = simd_mix(startPosition, endPosition, simd_float3(repeating: easedProgress))
            self.activeCards[cardId] = properties
            
            if progress >= 1.0 {
                timer.invalidate()
            }
        }
    }
    
    private func updateCardHighlight(_ cardId: UUID, intensity: Float) {
        guard var properties = activeCards[cardId] else { return }
        properties.highlightIntensity = intensity
        activeCards[cardId] = properties
    }
    
    private func updateCardGlow(_ cardId: UUID, color: simd_float4, intensity: Float) {
        guard var properties = activeCards[cardId] else { return }
        properties.glowColor = color
        properties.highlightIntensity = intensity
        activeCards[cardId] = properties
    }
    
    // MARK: - Touch Handling
    
    func handleTouch(at point: CGPoint, in view: MTKView) -> Card? {
        // Convert touch point to world coordinates and find intersecting card
        return delegate?.cardRenderer(self, didDetectTouch: point)
    }
    
    // MARK: - Romanian Cultural Settings
    
    func setRomanianEffectsEnabled(_ enabled: Bool) {
        isRomanianEffectsEnabled = enabled
        
        // Update all card colors to match cultural setting
        for (cardId, var properties) in activeCards {
            if enabled {
                properties.glowColor = RomanianCardConstants.folkGold
            } else {
                properties.glowColor = simd_float4(0.5, 0.5, 0.5, 1.0)
            }
            activeCards[cardId] = properties
        }
    }
    
    // MARK: - Fallback SwiftUI Integration
    
    /// Creates SwiftUI view representation when Metal is unavailable
    func createSwiftUIFallback() -> some View {
        VStack {
            Text("🎮 Septica Card Renderer")
                .font(.title2)
                .foregroundColor(Color(.systemBlue))
            
            Text("Running in SwiftUI fallback mode")
                .font(.caption)
                .foregroundColor(Color(.systemGray))
            
            Text("Metal Toolchain: \(isMetalAvailable ? "Available" : "Unavailable")")
                .font(.caption)
                .foregroundColor(isMetalAvailable ? .green : .orange)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    // MARK: - Performance Monitoring
    
    func updatePerformanceMetrics() {
        renderingPerformance.activeCardCount = activeCards.count
        renderingPerformance.activeAnimationCount = cardAnimations.values.filter { $0 != .idle }.count
        renderingPerformance.isUsingMetalRendering = isMetalAvailable
        renderingPerformance.lastUpdateTime = CACurrentMediaTime()
    }
}

// MARK: - Supporting Types

struct CardVertex {
    let position: simd_float3
    let texCoord: simd_float2
    let normal: simd_float3
}

struct CardUniforms {
    var modelMatrix: matrix_float4x4
    var highlightColor: simd_float4
    var glowIntensity: Float
    var flipAngle: Float
    var animationProgress: Float
    var _padding: Float = 0 // Ensure 16-byte alignment
}

struct RenderingPerformanceMetrics {
    var activeCardCount: Int = 0
    var activeAnimationCount: Int = 0
    var isUsingMetalRendering: Bool = false
    var lastUpdateTime: CFTimeInterval = 0
    var averageFrameTime: Double = 16.67 // 60 FPS target
}

// MARK: - Extensions for Integration

extension CardRenderer {
    /// Integration point for GameState
    func syncWithGameState(_ gameState: GameState) {
        // Remove cards no longer in play
        let gameCardIds = Set(gameState.tableCards.map { $0.id })
        let rendererCardIds = Set(activeCards.keys)
        
        for cardId in rendererCardIds.subtracting(gameCardIds) {
            removeCard(cardId, animated: true)
        }
        
        // Add new cards
        for card in gameState.tableCards {
            if !activeCards.keys.contains(card.id) {
                let position = calculateCardPosition(for: card, in: gameState)
                addCard(card, at: position, animated: true)
            }
        }
    }
    
    private func calculateCardPosition(for card: Card, in gameState: GameState) -> simd_float3 {
        // Calculate appropriate position based on game table layout
        let index = gameState.tableCards.firstIndex { $0.id == card.id } ?? 0
        let spacing: Float = 3.0
        let x = Float(index - gameState.tableCards.count / 2) * spacing
        return simd_float3(x, 0, 0)
    }
    
    // MARK: - Single Card Rendering
    
    /// Render a single card to a drawable (for MetalCardView integration)
    /// TODO: Fix compilation issues when Metal toolchain is available
    func renderCard(card: Card, isSelected: Bool, isPlayable: Bool, isAnimating: Bool, to drawable: CAMetalDrawable, view: MTKView) {
        // Temporarily disabled due to compilation issues with Metal toolchain
        print("Metal rendering requested but disabled - using SwiftUI fallback")
        return
        
        // Uncomment when Metal toolchain works:
        /*
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        
        // Set clear color and configure render pass
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
        
        // Set up single card properties
        var cardProperties = CardVisualProperties(
            position: simd_float3(0, 0, 0), // Centered
            rotation: simd_float3(0, 0, 0),
            scale: simd_float3(
                isSelected ? 1.05 : (isPlayable ? 1.0 : 0.95),
                isSelected ? 1.05 : (isPlayable ? 1.0 : 0.95),
                1.0
            ),
            highlightIntensity: isSelected ? 1.0 : 0.0,
            glowColor: isSelected ? simd_float4(0.2, 0.6, 1.0, 1.0) : simd_float4(0.8, 0.6, 0.2, 1.0),
            flipAngle: 0.0,
            animationProgress: isAnimating ? 1.0 : 0.0
        )
        
        // Apply animation rotation if animating
        if isAnimating {
            cardProperties.rotation.z = Float(Date().timeIntervalSince1970.truncatingRemainder(dividingBy: 2.0)) * Float.pi
        }
        
        // Render the single card
        renderEncoder.setRenderPipelineState(cardRenderPipeline)
        renderEncoder.setVertexBuffer(cardVertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBytes(&cardProperties, length: MemoryLayout<CardVisualProperties>.size, index: 1)
        
        // Set viewport
        let viewport = MTLViewport(
            originX: 0, originY: 0,
            width: Double(view.drawableSize.width),
            height: Double(view.drawableSize.height),
            znear: 0.0, zfar: 1.0
        )
        renderEncoder.setViewport(viewport)
        
        // Draw the card
        renderEncoder.drawIndexedPrimitives(
            type: .triangle,
            indexCount: 6,
            indexType: .uint16,
            indexBuffer: cardIndexBuffer,
            indexBufferOffset: 0
        )
        
        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
        */
    }
}

// CardRenderer.swift created with Metal fallback support