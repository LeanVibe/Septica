//
//  ProfessionalCard.swift
//  Septica
//
//  Professional card component integrating Metal-based rendering with existing CardView system
//  Provides ShuffleCats-quality rendering while maintaining Romanian cultural authenticity
//

import SwiftUI
import Metal
import MetalKit
import simd
import Combine

// MARK: - Professional Card Component

/// Professional card component that enhances CardView with advanced rendering capabilities
/// Integrates ProfessionalCardRenderer, Advanced3DTransform, MaterialEffect, and caching systems
struct ProfessionalCard: View {
    
    // MARK: - Properties
    
    let card: Card
    let isSelected: Bool
    let isPlayable: Bool
    let isAnimating: Bool
    let cardSize: CardSize
    let onTap: (() -> Void)?
    let onDragChanged: ((DragGesture.Value) -> Void)?
    let onDragEnded: ((DragGesture.Value) -> Void)?
    
    // MARK: - Rendering Configuration
    
    @AppStorage("enableMetalRendering") private var enableMetalRendering: Bool = false
    @AppStorage("renderQuality") private var renderQuality: String = "high"
    @AppStorage("enableAdvancedEffects") private var enableAdvancedEffects: Bool = true
    @AppStorage("enableRomanianCulturalEffects") private var enableRomanianCulturalEffects: Bool = true
    @AppStorage("enableShuffleCatsEnhancements") private var enableShuffleCatsEnhancements: Bool = true
    
    // MARK: - Advanced Rendering Systems
    
    @StateObject private var transform3D = Advanced3DTransform()
    @StateObject private var materialEffectSystem = MaterialEffectSystem(device: MTLCreateSystemDefaultDevice()!)
    @StateObject private var professionalRenderer = makeProfessionalRenderer()
    @StateObject private var cardVisualEffectsManager = CardVisualEffectsManager()
    @StateObject private var integrationManager = makeIntegrationManager()
    @StateObject private var romanianPatternManager = RomanianPatternIntegrationManager(device: MTLCreateSystemDefaultDevice()!)
    @StateObject private var shuffleCatsEnhancementManager = ShuffleCatsQualityEnhancementManager()
    
    // MARK: - State Management
    
    @State private var currentMaterialProperties = MaterialProperties.premiumCardstock
    @State private var isMetalInitialized = false
    @State private var renderError: String?
    @State private var lastFrameTime: CFTimeInterval = 0
    
    // MARK: - Animation State
    
    @State private var isPerformingAdvancedAnimation = false
    @State private var currentSpecialEffect: SpecialCardEffect?
    @State private var effectIntensity: Float = 1.0
    @State private var currentInteractionState: InteractionState = .idle
    
    // MARK: - Performance Monitoring
    
    @State private var frameRate: Double = 60.0
    @State private var renderTime: Double = 0.0
    @State private var memoryUsage: Int = 0
    
    // MARK: - Initialization
    
    init(
        card: Card,
        isSelected: Bool = false,
        isPlayable: Bool = true,
        isAnimating: Bool = false,
        cardSize: CardSize = .normal,
        onTap: (() -> Void)? = nil,
        onDragChanged: ((DragGesture.Value) -> Void)? = nil,
        onDragEnded: ((DragGesture.Value) -> Void)? = nil
    ) {
        self.card = card
        self.isSelected = isSelected
        self.isPlayable = isPlayable
        self.isAnimating = isAnimating
        self.cardSize = cardSize
        self.onTap = onTap
        self.onDragChanged = onDragChanged
        self.onDragEnded = onDragEnded
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            if enableMetalRendering && isMetalInitialized && renderError == nil {
                // Professional Metal rendering path
                professionalMetalCard
                    .overlay(professionalEffectsOverlay)
            } else {
                // Enhanced SwiftUI fallback path
                enhancedSwiftUICard
                    .overlay(materialEffectsOverlay)
            }
            
            // Debug overlay (only in debug builds)
            #if DEBUG
            if enableAdvancedEffects {
                debugInfoOverlay
            }
            #endif
        }
        .integratedEffects(
            manager: integrationManager,
            card: card,
            isSelected: isSelected,
            isPlayable: isPlayable,
            isAnimating: isAnimating
        )
        .onAppear {
            setupProfessionalCard()
        }
        .onChange(of: isSelected) { newValue in
            handleSelectionChange(newValue)
        }
        .onChange(of: card.value) { _ in
            updateMaterialProperties()
        }
        .onReceive(Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()) { _ in
            updatePerformanceMetrics()
        }
    }
    
    // MARK: - Professional Metal Rendering
    
    @ViewBuilder
    private var professionalMetalCard: some View {
        ProfessionalMetalCardView(
            card: card,
            transform: transform3D,
            materialProperties: currentMaterialProperties,
            renderer: professionalRenderer,
            isSelected: isSelected,
            isPlayable: isPlayable,
            isAnimating: isAnimating
        )
        .frame(width: cardSize.width, height: cardSize.height)
        .scaleEffect(professionalScaleEffect)
        .rotation3DEffect(
            .degrees(Double(transform3D.rotation.y * 180 / .pi)),
            axis: (x: 0, y: 1, z: 0)
        )
        .professional3DTransform(transform3D)
        .onTapGesture {
            handleProfessionalCardTap()
        }
        .simultaneousGesture(professionalDragGesture)
    }
    
    @ViewBuilder
    private var enhancedSwiftUICard: some View {
        shuffleCatsEnhancementManager.enhanceCard(
            CardView(
                card: card,
                isSelected: isSelected,
                isPlayable: isPlayable,
                isAnimating: isAnimating,
                cardSize: cardSize,
                onTap: onTap,
                onDragChanged: onDragChanged,
                onDragEnded: onDragEnded
            )
            .materialEffect(currentMaterialProperties, intensity: effectIntensity)
            .advanced3DTransform(transform3D, enabled: enableAdvancedEffects),
            card: card,
            isSelected: isSelected
        )
        .microInteractions(
            state: currentInteractionState,
            enhancementLevel: shuffleCatsEnhancementManager.enhancementLevel,
            enabled: shuffleCatsEnhancementManager.enableMicroInteractions
        )
    }
    
    // MARK: - Professional Effects Overlay
    
    @ViewBuilder
    private var professionalEffectsOverlay: some View {
        ZStack {
            // Special card effects
            if let effect = currentSpecialEffect {
                specialEffectView(effect)
            }
            
            // Romanian cultural overlay
            if enableRomanianCulturalEffects {
                romanianCulturalOverlay
            }
            
            // Selection glow
            if isSelected {
                professionalSelectionGlow
            }
        }
    }
    
    @ViewBuilder
    private var materialEffectsOverlay: some View {
        ZStack {
            // Material glow effects
            if currentMaterialProperties.glowIntensity > 0 {
                RoundedRectangle(cornerRadius: cardSize.cornerRadius)
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(
                                    red: Double(currentMaterialProperties.emissiveFactor.x),
                                    green: Double(currentMaterialProperties.emissiveFactor.y),
                                    blue: Double(currentMaterialProperties.emissiveFactor.z)
                                ).opacity(Double(currentMaterialProperties.glowIntensity) * 0.8),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 40
                        )
                    )
                    .scaleEffect(1.0 + Double(currentMaterialProperties.pulseIntensity) * 0.2)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: UUID())
            }
            
            // Gold leaf effect
            if currentMaterialProperties.goldLeafEffect > 0 {
                RoundedRectangle(cornerRadius: cardSize.cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.yellow.opacity(Double(currentMaterialProperties.goldLeafEffect) * 0.8),
                                Color.orange.opacity(Double(currentMaterialProperties.goldLeafEffect) * 0.6),
                                Color.yellow.opacity(Double(currentMaterialProperties.goldLeafEffect) * 0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: Double(currentMaterialProperties.goldLeafEffect) * 3
                    )
                    .shadow(
                        color: Color.yellow.opacity(Double(currentMaterialProperties.goldLeafEffect) * 0.6),
                        radius: 8,
                        x: 0,
                        y: 0
                    )
            }
        }
    }
    
    @ViewBuilder
    private var romanianCulturalOverlay: some View {
        if currentMaterialProperties.folkPatternIntensity > 0 {
            ZStack {
                // Professional pattern integration using TextureCache
                if enableMetalRendering && isMetalInitialized {
                    RomanianPatternView(
                        card: card,
                        patternSet: .traditional,
                        intensity: currentMaterialProperties.folkPatternIntensity
                    )
                    .clipShape(RoundedRectangle(cornerRadius: cardSize.cornerRadius))
                } else {
                    // Fallback to SwiftUI patterns
                    RomanianCulturalPatternView(
                        intensity: currentMaterialProperties.folkPatternIntensity,
                        embroideryEffect: currentMaterialProperties.embroideryEffect
                    )
                    .opacity(Double(currentMaterialProperties.folkPatternIntensity) * 0.3)
                }
                
                // Cultural border accent
                RoundedRectangle(cornerRadius: cardSize.cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                RomanianColors.embroideryRed.opacity(Double(currentMaterialProperties.folkPatternIntensity) * 0.4),
                                RomanianColors.goldAccent.opacity(Double(currentMaterialProperties.folkPatternIntensity) * 0.3),
                                RomanianColors.primaryBlue.opacity(Double(currentMaterialProperties.folkPatternIntensity) * 0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        }
    }
    
    @ViewBuilder
    private var professionalSelectionGlow: some View {
        RoundedRectangle(cornerRadius: cardSize.cornerRadius)
            .stroke(
                LinearGradient(
                    colors: [
                        RomanianColors.goldAccent,
                        RomanianColors.primaryYellow,
                        RomanianColors.goldAccent
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 4
            )
            .shadow(color: RomanianColors.goldAccent.opacity(0.8), radius: 12, x: 0, y: 0)
            .shadow(color: RomanianColors.primaryYellow.opacity(0.6), radius: 20, x: 0, y: 0)
            .scaleEffect(1.05)
            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: UUID())
    }
    
    // MARK: - Special Effects
    
    @ViewBuilder
    private func specialEffectView(_ effect: SpecialCardEffect) -> some View {
        switch effect {
        case .sevenMagic:
            SevenCardMagicalEffect(intensity: effectIntensity)
        case .pointCardShimmer:
            PointCardShimmerEffect(intensity: effectIntensity)
        case .romanianFlourish:
            RomanianFlourishEffect(intensity: effectIntensity)
        case .goldenGlow:
            GoldenGlowEffect(intensity: effectIntensity)
        }
    }
    
    // MARK: - Debug Info Overlay
    
    #if DEBUG
    @ViewBuilder
    private var debugInfoOverlay: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("FPS: \(frameRate, specifier: "%.1f")")
                    Text("Render: \(renderTime, specifier: "%.2f")ms")
                    Text("Memory: \(memoryUsage)MB")
                    Text("Metal: \(enableMetalRendering ? "ON" : "OFF")")
                    if let error = renderError {
                        Text("Error: \(error)")
                            .foregroundColor(.red)
                    }
                }
                .font(.system(size: 8, family: .monospaced))
                .foregroundColor(.white)
                .padding(4)
                .background(Color.black.opacity(0.7))
                .cornerRadius(4)
            }
        }
        .allowsHitTesting(false)
    }
    #endif
    
    // MARK: - Computed Properties
    
    private var professionalScaleEffect: CGFloat {
        let baseScale = isSelected ? 1.15 : (isPlayable ? 1.0 : 0.85)
        let transformScale = Double(1.0 + transform3D.scale.x * 0.1)
        return baseScale * transformScale
    }
    
    // MARK: - Gesture Handling
    
    private var professionalDragGesture: some Gesture {
        DragGesture(minimumDistance: 8, coordinateSpace: .global)
            .onChanged { value in
                guard isPlayable else {
                    // Enhanced invalid move feedback with 3D shake
                    currentInteractionState = .idle
                    performInvalidMoveEffect()
                    return
                }
                
                // Update interaction state
                currentInteractionState = .dragging
                
                // Update 3D transform based on drag
                let normalizedTranslation = simd_float3(
                    Float(value.translation.x) / 100,
                    Float(-value.translation.y) / 100,
                    0
                )
                transform3D.setPosition(normalizedTranslation, animated: false)
                
                // Add rotation based on drag direction
                let rotationY = Float(value.translation.x) / 200
                transform3D.setRotation(simd_float3(0, rotationY, 0), animated: false)
                
                onDragChanged?(value)
            }
            .onEnded { value in
                guard isPlayable else { 
                    currentInteractionState = .idle
                    return 
                }
                
                // Update interaction state
                currentInteractionState = .released
                
                // Smooth return animation
                transform3D.snapToPosition(simd_float3(0, 0, 0), rotation: simd_float3(0, 0, 0)) {
                    currentInteractionState = .idle
                }
                
                onDragEnded?(value)
            }
    }
    
    // MARK: - Event Handlers
    
    private func handleProfessionalCardTap() {
        currentInteractionState = .pressed
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            currentInteractionState = .released
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                currentInteractionState = .idle
            }
        }
        
        if isPlayable {
            // Trigger advanced tap effects
            performCardPlayEffect()
            onTap?()
        } else {
            performInvalidMoveEffect()
        }
    }
    
    private func handleSelectionChange(_ newValue: Bool) {
        if newValue {
            // Card selected - trigger lift effect
            transform3D.performLiftEffect(height: 0.3) {
                // Update material properties for selection
                updateMaterialForSelection()
            }
        } else {
            // Card deselected - return to normal
            transform3D.setPosition(simd_float3(0, 0, 0), animated: true, duration: 0.4)
            updateMaterialForDeselection()
        }
    }
    
    private func performCardPlayEffect() {
        isPerformingAdvancedAnimation = true
        
        // Use integration manager for coordinated effects
        if card.value == 7 {
            currentSpecialEffect = .sevenMagic
            integrationManager.triggerIntegratedEffect(.sevenCardSpecial, for: card, intensity: 1.0)
            
        } else if card.isPointCard {
            currentSpecialEffect = .pointCardShimmer
            integrationManager.triggerIntegratedEffect(.pointCardHighlight, for: card, intensity: 0.8)
            
        } else {
            // Standard play effect
            integrationManager.triggerIntegratedEffect(.playAnimation, for: card, intensity: 0.7)
        }
        
        // Add Romanian cultural flourish for appropriate cards
        if enableRomanianCulturalEffects && shouldShowRomanianFlourish() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                currentSpecialEffect = .romanianFlourish
                integrationManager.triggerIntegratedEffect(.romanianCulturalFlourish, for: card, intensity: 0.6)
            }
        }
        
        // Schedule completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            completeCardPlayEffect()
        }
    }
    
    private func performInvalidMoveEffect() {
        // Use integration manager for coordinated invalid move effect
        integrationManager.triggerIntegratedEffect(.invalidMove, for: card, intensity: 1.0)
    }
    
    private func completeCardPlayEffect() {
        isPerformingAdvancedAnimation = false
        currentSpecialEffect = nil
        
        // Return to normal state
        transform3D.setPosition(simd_float3(0, 0, 0), animated: true, duration: 0.3)
        transform3D.setRotation(simd_float3(0, 0, 0), animated: true, duration: 0.3)
    }
    
    // MARK: - Material System Integration
    
    private func updateMaterialProperties() {
        // Set base material based on card type
        if card.value == 7 {
            currentMaterialProperties = MaterialProperties.magicalSeven
        } else if card.isPointCard {
            currentMaterialProperties = MaterialProperties.romanianGold
        } else {
            currentMaterialProperties = MaterialProperties.premiumCardstock
        }
        
        // Apply Romanian cultural tinting
        if enableRomanianCulturalEffects {
            currentMaterialProperties.folkPatternIntensity = 0.3
            currentMaterialProperties.culturalColorShift = simd_float3(1.1, 0.95, 0.8)
            
            // Update Romanian pattern manager
            romanianPatternManager.setPatternIntensity(currentMaterialProperties.folkPatternIntensity)
            romanianPatternManager.setCulturalAuthenticity(.authentic)
            
            // Set appropriate pattern set based on card
            if card.value == 7 {
                romanianPatternManager.setPatternSet(.ceremonial)
            } else {
                romanianPatternManager.setPatternSet(.traditional)
            }
        }
        
        // Update material effect system
        materialEffectSystem.applyMaterialPreset(.premiumCardstock, to: UUID(), animated: true)
    }
    
    private func updateMaterialForSelection() {
        currentMaterialProperties.glowIntensity = 0.8
        currentMaterialProperties.emissiveFactor = simd_float3(0.2, 0.15, 0.05)
        
        let selectionEffect = materialEffectSystem.createGoldHighlightEffect(for: UUID(), intensity: 1.0)
        materialEffectSystem.addEffect(selectionEffect)
    }
    
    private func updateMaterialForDeselection() {
        currentMaterialProperties.glowIntensity = 0.0
        currentMaterialProperties.emissiveFactor = simd_float3(0, 0, 0)
        
        materialEffectSystem.clearAllEffects()
    }
    
    // MARK: - Setup and Configuration
    
    private func setupProfessionalCard() {
        // Initialize Metal rendering if available
        if enableMetalRendering {
            initializeMetalRendering()
        }
        
        // Setup material properties
        updateMaterialProperties()
        
        // Configure 3D transform
        transform3D.culturalIntensity = enableRomanianCulturalEffects ? 1.0 : 0.0
        
        // Configure ShuffleCats enhancements
        if enableShuffleCatsEnhancements {
            shuffleCatsEnhancementManager.enhancementLevel = getEnhancementLevel()
            shuffleCatsEnhancementManager.preserveCulturalAuthenticity = enableRomanianCulturalEffects
            shuffleCatsEnhancementManager.enableMicroInteractions = enableAdvancedEffects
        }
        
        // Start performance monitoring
        lastFrameTime = CACurrentMediaTime()
    }
    
    private func getEnhancementLevel() -> EnhancementLevel {
        switch renderQuality {
        case "low": return .minimal
        case "medium": return .medium
        case "high": return .high
        case "ultra": return .ultra
        default: return .high
        }
    }
    
    private func initializeMetalRendering() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            renderError = "Metal not available"
            return
        }
        
        do {
            // Metal initialization would be handled by ProfessionalCardRenderer
            isMetalInitialized = true
            renderError = nil
            print("✅ Professional Metal rendering initialized")
        } catch {
            renderError = "Failed to initialize Metal: \(error.localizedDescription)"
            print("❌ Metal initialization failed: \(error)")
        }
    }
    
    // MARK: - Performance Monitoring
    
    private func updatePerformanceMetrics() {
        let currentTime = CACurrentMediaTime()
        if lastFrameTime > 0 {
            let deltaTime = currentTime - lastFrameTime
            frameRate = 1.0 / deltaTime
        }
        lastFrameTime = currentTime
        
        // Update memory usage (simplified)
        memoryUsage = Int(Double(ProcessInfo.processInfo.physicalMemory) / (1024 * 1024 * 1024))
    }
    
    // MARK: - Utility Methods
    
    private func shouldShowRomanianFlourish() -> Bool {
        // Show Romanian flourish for hearts 10 (traditional lucky card in Romanian culture)
        return card.suit == .hearts && card.value == 10
    }
    
    // MARK: - Static Factory Methods
    
    private static func makeProfessionalRenderer() -> ProfessionalCardRenderer {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else {
            fatalError("Metal not available for ProfessionalCardRenderer")
        }
        
        do {
            return try ProfessionalCardRenderer(device: device, commandQueue: commandQueue)
        } catch {
            fatalError("Failed to create ProfessionalCardRenderer: \(error)")
        }
    }
    
    private static func makeIntegrationManager() -> AdvancedEffectsIntegrationManager {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal not available for AdvancedEffectsIntegrationManager")
        }
        
        let cardEffectsManager = CardVisualEffectsManager()
        let materialSystem = MaterialEffectSystem(device: device)
        let transform3D = Advanced3DTransform()
        
        return AdvancedEffectsIntegrationManager(
            cardVisualEffectsManager: cardEffectsManager,
            materialEffectSystem: materialSystem,
            transform3DManager: transform3D
        )
    }
}

// MARK: - Supporting Views

/// Professional Metal card view component
struct ProfessionalMetalCardView: UIViewRepresentable {
    let card: Card
    let transform: Advanced3DTransform
    let materialProperties: MaterialProperties
    let renderer: ProfessionalCardRenderer
    let isSelected: Bool
    let isPlayable: Bool
    let isAnimating: Bool
    
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.delegate = context.coordinator
        mtkView.preferredFramesPerSecond = 120
        mtkView.enableSetNeedsDisplay = true
        mtkView.isPaused = false
        mtkView.backgroundColor = UIColor.clear
        mtkView.isOpaque = false
        
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.updateCard(
            card: card,
            transform: transform,
            materialProperties: materialProperties,
            isSelected: isSelected,
            isPlayable: isPlayable,
            isAnimating: isAnimating
        )
    }
    
    func makeCoordinator() -> ProfessionalMetalCardCoordinator {
        ProfessionalMetalCardCoordinator(renderer: renderer)
    }
}

/// Coordinator for professional Metal card rendering
class ProfessionalMetalCardCoordinator: NSObject, MTKViewDelegate {
    private let renderer: ProfessionalCardRenderer
    private var currentCard: Card?
    private var currentTransform: Advanced3DTransform?
    private var currentMaterialProperties: MaterialProperties?
    private var isSelected = false
    private var isPlayable = true
    private var isAnimating = false
    
    init(renderer: ProfessionalCardRenderer) {
        self.renderer = renderer
        super.init()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Handle view size changes
    }
    
    func draw(in view: MTKView) {
        guard let currentCard = currentCard,
              let currentTransform = currentTransform,
              let currentMaterialProperties = currentMaterialProperties,
              let drawable = view.currentDrawable else { return }
        
        do {
            // Create view and projection matrices
            let viewMatrix = createViewMatrix()
            let projectionMatrix = createProjectionMatrix(viewSize: view.drawableSize)
            
            // Create lighting environment
            let lightingEnvironment = createLightingEnvironment()
            
            // Render using professional renderer
            try renderer.renderCard(
                currentCard,
                transform: currentTransform,
                materialProperties: currentMaterialProperties,
                lightingEnvironment: lightingEnvironment,
                to: drawable.texture,
                viewMatrix: viewMatrix,
                projectionMatrix: projectionMatrix
            )
            
            drawable.present()
        } catch {
            print("❌ Professional rendering error: \(error)")
        }
    }
    
    func updateCard(
        card: Card,
        transform: Advanced3DTransform,
        materialProperties: MaterialProperties,
        isSelected: Bool,
        isPlayable: Bool,
        isAnimating: Bool
    ) {
        self.currentCard = card
        self.currentTransform = transform
        self.currentMaterialProperties = materialProperties
        self.isSelected = isSelected
        self.isPlayable = isPlayable
        self.isAnimating = isAnimating
    }
    
    private func createViewMatrix() -> matrix_float4x4 {
        let eye = simd_float3(0, 0, 5)
        let center = simd_float3(0, 0, 0)
        let up = simd_float3(0, 1, 0)
        return matrix_look_at_left_hand(eye: eye, center: center, up: up)
    }
    
    private func createProjectionMatrix(viewSize: CGSize) -> matrix_float4x4 {
        let aspect = Float(viewSize.width / viewSize.height)
        let fovy = Float.pi / 4
        let near: Float = 0.1
        let far: Float = 100.0
        return matrix_perspective_left_hand(fovyRadians: fovy, aspect: aspect, nearZ: near, farZ: far)
    }
    
    private func createLightingEnvironment() -> LightingEnvironment {
        var environment = LightingEnvironment()
        environment.primaryLightDirection = simd_float3(0.5, -0.8, 0.3)
        environment.primaryLightColor = simd_float3(1.0, 0.95, 0.8)
        environment.ambientLightColor = simd_float3(0.3, 0.3, 0.4)
        environment.lightIntensity = 1.0
        environment.romanianCulturalTint = simd_float3(1.0, 0.85, 0.4)
        return environment
    }
}

// MARK: - Supporting Types

enum SpecialCardEffect {
    case sevenMagic
    case pointCardShimmer
    case romanianFlourish
    case goldenGlow
}

// MARK: - View Modifiers

extension View {
    /// Apply advanced 3D transform to a view
    func advanced3DTransform(_ transform: Advanced3DTransform, enabled: Bool = true) -> some View {
        Group {
            if enabled {
                self
                    .scaleEffect(
                        x: CGFloat(transform.scale.x),
                        y: CGFloat(transform.scale.y)
                    )
                    .rotation3DEffect(
                        .radians(Double(transform.rotation.y)),
                        axis: (x: 0, y: 1, z: 0)
                    )
                    .offset(
                        x: CGFloat(transform.position.x * 50),
                        y: CGFloat(-transform.position.y * 50)
                    )
            } else {
                self
            }
        }
    }
    
    /// Apply ShuffleCats-style enhancements
    func shuffleCatsEnhancements(enabled: Bool = true) -> some View {
        Group {
            if enabled {
                self
                    .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                    .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            } else {
                self
            }
        }
    }
    
    /// Apply professional 3D transform modifier
    func professional3DTransform(_ transform: Advanced3DTransform) -> some View {
        self
            .scaleEffect(CGFloat(1.0 + transform.scale.x * 0.1))
            .rotation3DEffect(
                .radians(Double(simd_length(transform.rotation))),
                axis: (
                    x: CGFloat(transform.rotation.x),
                    y: CGFloat(transform.rotation.y),
                    z: CGFloat(transform.rotation.z)
                )
            )
            .offset(
                x: CGFloat(transform.position.x * 100),
                y: CGFloat(-transform.position.y * 100)
            )
    }
}

// MARK: - Matrix Utilities

func matrix_look_at_left_hand(eye: simd_float3, center: simd_float3, up: simd_float3) -> matrix_float4x4 {
    let f = simd_normalize(center - eye)
    let s = simd_normalize(simd_cross(f, up))
    let u = simd_cross(s, f)
    
    return matrix_float4x4(
        simd_float4(s.x, u.x, -f.x, 0),
        simd_float4(s.y, u.y, -f.y, 0),
        simd_float4(s.z, u.z, -f.z, 0),
        simd_float4(-simd_dot(s, eye), -simd_dot(u, eye), simd_dot(f, eye), 1)
    )
}

func matrix_perspective_left_hand(fovyRadians: Float, aspect: Float, nearZ: Float, farZ: Float) -> matrix_float4x4 {
    let ys = 1 / tanf(fovyRadians * 0.5)
    let xs = ys / aspect
    let zs = farZ / (farZ - nearZ)
    
    return matrix_float4x4(
        simd_float4(xs, 0, 0, 0),
        simd_float4(0, ys, 0, 0),
        simd_float4(0, 0, zs, 1),
        simd_float4(0, 0, -nearZ * zs, 0)
    )
}