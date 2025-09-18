//
//  AdvancedEffectsIntegration.swift
//  Septica
//
//  Integration layer between existing CardVisualEffectsManager and new MaterialEffect system
//  Provides seamless interaction between SwiftUI and Metal-based effects
//

import SwiftUI
import Metal
import Combine

// MARK: - Advanced Effects Integration Manager

/// Integration manager that coordinates between CardVisualEffectsManager and MaterialEffectSystem
@MainActor
class AdvancedEffectsIntegrationManager: ObservableObject {
    
    // MARK: - Core Systems
    
    private let cardVisualEffectsManager: CardVisualEffectsManager
    private let materialEffectSystem: MaterialEffectSystem
    private let transform3DManager: Advanced3DTransform
    
    // MARK: - State Management
    
    @Published var isMetalRenderingEnabled: Bool = false
    @Published var currentRenderMode: RenderMode = .swiftUI
    @Published var performanceMetrics: PerformanceMetrics = PerformanceMetrics()
    
    // MARK: - Effect Coordination
    
    @Published var activeIntegratedEffects: [IntegratedEffect] = []
    @Published var effectSyncEnabled: Bool = true
    @Published var crossSystemEffectsEnabled: Bool = true
    
    // MARK: - Performance Monitoring
    
    private var frameCounter: Int = 0
    private var lastMetricsUpdate: CFTimeInterval = 0
    private var cancellables = Set<AnyCancellable>()
    private var effectIntensity: Float = 1.0
    
    // MARK: - Initialization
    
    init(
        cardVisualEffectsManager: CardVisualEffectsManager,
        materialEffectSystem: MaterialEffectSystem,
        transform3DManager: Advanced3DTransform
    ) {
        self.cardVisualEffectsManager = cardVisualEffectsManager
        self.materialEffectSystem = materialEffectSystem
        self.transform3DManager = transform3DManager
        
        setupIntegration()
        setupPerformanceMonitoring()
    }
    
    // MARK: - Public Interface
    
    /// Trigger an integrated effect that uses both systems
    func triggerIntegratedEffect(
        _ effectType: IntegratedEffectType,
        for card: Card,
        at position: CGPoint = .zero,
        intensity: Float = 1.0
    ) {
        let integratedEffect = IntegratedEffect(
            id: UUID(),
            type: effectType,
            card: card,
            position: position,
            intensity: intensity,
            startTime: CACurrentMediaTime()
        )
        
        activeIntegratedEffects.append(integratedEffect)
        
        // Trigger effects in both systems
        if isMetalRenderingEnabled {
            triggerMetalEffects(for: integratedEffect)
        }
        
        triggerSwiftUIEffects(for: integratedEffect)
        triggerTransformEffects(for: integratedEffect)
        
        // Schedule cleanup
        DispatchQueue.main.asyncAfter(deadline: .now() + effectType.duration) {
            self.removeIntegratedEffect(integratedEffect.id)
        }
    }
    
    /// Switch between rendering modes
    func setRenderMode(_ mode: RenderMode) {
        guard currentRenderMode != mode else { return }
        
        withAnimation(.easeInOut(duration: 0.5)) {
            currentRenderMode = mode
            isMetalRenderingEnabled = (mode == .metal || mode == .hybrid)
        }
        
        // Sync active effects to new mode
        syncEffectsToNewMode()
    }
    
    /// Update integration based on card state changes
    func updateForCardState(
        card: Card,
        isSelected: Bool,
        isPlayable: Bool,
        isAnimating: Bool
    ) {
        // Update material properties based on card state
        if isSelected {
            applySelectionEffects(for: card)
        }
        
        if !isPlayable {
            applyDisabledEffects(for: card)
        }
        
        if isAnimating {
            applyAnimationEffects(for: card)
        }
    }
    
    // MARK: - Private Integration Methods
    
    private func setupIntegration() {
        // Monitor user preferences
        UserDefaults.standard.publisher(for: \.enableMetalRendering)
            .sink { [weak self] enabled in
                self?.isMetalRenderingEnabled = enabled
                self?.updateRenderMode()
            }
            .store(in: &cancellables)
        
        // Monitor performance and adjust accordingly
        // Note: MaterialEffectSystem performance monitoring would be implemented here
    }
    
    private func updateRenderMode() {
        if isMetalRenderingEnabled {
            setRenderMode(.hybrid) // Start with hybrid for best compatibility
        } else {
            setRenderMode(.swiftUI)
        }
    }
    
    private func triggerMetalEffects(for effect: IntegratedEffect) {
        switch effect.type {
        case .sevenCardSpecial:
            let materialEffect = materialEffectSystem.createSevenCardEffect(for: effect.card.id ?? UUID())
            materialEffectSystem.addEffect(materialEffect)
            
        case .pointCardHighlight:
            let goldEffect = materialEffectSystem.createGoldHighlightEffect(
                for: effect.card.id ?? UUID(),
                intensity: effect.intensity
            )
            materialEffectSystem.addEffect(goldEffect)
            
        case .romanianCulturalFlourish:
            let culturalEffect = materialEffectSystem.createRomanianCulturalEffect(
                for: effect.card.id ?? UUID(),
                intensity: effect.intensity
            )
            materialEffectSystem.addEffect(culturalEffect)
            
        case .selectionGlow:
            let glowEffect = materialEffectSystem.createGoldHighlightEffect(
                for: effect.card.id ?? UUID(),
                intensity: effect.intensity * 0.8
            )
            materialEffectSystem.addEffect(glowEffect)
            
        case .playAnimation:
            // Standard play effects handled by both systems
            break
            
        case .invalidMove:
            // Error effects are primarily visual (SwiftUI)
            break
        }
    }
    
    private func triggerSwiftUIEffects(for effect: IntegratedEffect) {
        let cardEffectType = mapToCardEffectType(effect.type)
        cardVisualEffectsManager.triggerEffect(cardEffectType, for: effect.card, at: effect.position)
    }
    
    private func triggerTransformEffects(for effect: IntegratedEffect) {
        switch effect.type {
        case .sevenCardSpecial:
            transform3DManager.performSevenCardEffect {
                // Effect completion
            }
            
        case .pointCardHighlight:
            transform3DManager.performLiftEffect(height: 0.2) {
                // Lift complete
            }
            
        case .romanianCulturalFlourish:
            transform3DManager.performFolkDanceMotion(intensity: effect.intensity) {
                // Cultural animation complete
            }
            
        case .selectionGlow:
            transform3DManager.performLiftEffect(height: 0.3) {
                // Selection lift complete
            }
            
        case .playAnimation:
            transform3DManager.performProfessionalFlip {
                // Play animation complete
            }
            
        case .invalidMove:
            // Apply shake effect with transform
            let originalPosition = transform3DManager.position
            for i in 0..<3 {
                let delay = Double(i) * 0.1
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    let shakeOffset = simd_float3(
                        Float.random(in: -0.1...0.1),
                        0,
                        Float.random(in: -0.05...0.05)
                    )
                    self.transform3DManager.setPosition(originalPosition + shakeOffset, animated: false)
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.transform3DManager.setPosition(originalPosition, animated: true, duration: 0.2)
            }
        }
    }
    
    private func mapToCardEffectType(_ integratedType: IntegratedEffectType) -> CardEffectType {
        switch integratedType {
        case .sevenCardSpecial:
            return .goldenGlow
        case .pointCardHighlight:
            return .pointCardShimmer
        case .romanianCulturalFlourish:
            return .romanianFlourish
        case .selectionGlow:
            return .sparklePlay
        case .playAnimation:
            return .sparklePlay
        case .invalidMove:
            return .invalidCardShake
        }
    }
    
    private func syncEffectsToNewMode() {
        // When switching modes, ensure effects are properly transitioned
        for effect in activeIntegratedEffects {
            if currentRenderMode == .metal || currentRenderMode == .hybrid {
                triggerMetalEffects(for: effect)
            }
        }
    }
    
    private func applySelectionEffects(for card: Card) {
        triggerIntegratedEffect(.selectionGlow, for: card, intensity: 1.0)
    }
    
    private func applyDisabledEffects(for card: Card) {
        // Apply subtle material effects for disabled cards
        let weatheringEffect = materialEffectSystem.createWeatheringEffect(
            for: card.id ?? UUID(),
            age: 0.3
        )
        materialEffectSystem.addEffect(weatheringEffect)
    }
    
    private func applyAnimationEffects(for card: Card) {
        if card.value == 7 {
            triggerIntegratedEffect(.sevenCardSpecial, for: card, intensity: 1.0)
        } else if card.isPointCard {
            triggerIntegratedEffect(.pointCardHighlight, for: card, intensity: 0.8)
        } else {
            triggerIntegratedEffect(.playAnimation, for: card, intensity: 0.7)
        }
    }
    
    private func removeIntegratedEffect(_ id: UUID) {
        activeIntegratedEffects.removeAll { $0.id == id }
    }
    
    // MARK: - Performance Management
    
    private func setupPerformanceMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updatePerformanceMetrics()
        }
    }
    
    private func updatePerformanceMetrics() {
        let currentTime = CACurrentMediaTime()
        
        if lastMetricsUpdate > 0 {
            let deltaTime = currentTime - lastMetricsUpdate
            performanceMetrics.frameRate = 1.0 / deltaTime
        }
        
        lastMetricsUpdate = currentTime
        frameCounter += 1
        
        // Update memory usage
        performanceMetrics.memoryUsage = getCurrentMemoryUsage()
        
        // Update effect counts
        performanceMetrics.activeSwiftUIEffects = cardVisualEffectsManager.activeEffects.count
        performanceMetrics.activeMetalEffects = materialEffectSystem.activeEffects.count
        performanceMetrics.active3DTransforms = transform3DManager.isAnimating ? 1 : 0
        
        // Auto-adjust quality based on performance
        autoAdjustQualityForPerformance()
    }
    
    private func getCurrentMemoryUsage() -> Int {
        // Simplified memory usage calculation
        let info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &count) {
            task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), UnsafeMutablePointer<integer_t>(OpaquePointer($0)), &count)
        }
        
        if kerr == KERN_SUCCESS {
            return Int(info.resident_size / (1024 * 1024)) // MB
        }
        
        return 0
    }
    
    private func adjustEffectIntensityForPerformance(_ mode: PerformanceMode) {
        let intensityMultiplier: Float
        
        switch mode {
        case .batteryOptimized:
            intensityMultiplier = 0.6
        case .balanced:
            intensityMultiplier = 1.0
        case .maximumQuality:
            intensityMultiplier = 1.4
        }
        
        // Apply intensity adjustment to all active effects
        for i in 0..<activeIntegratedEffects.count {
            activeIntegratedEffects[i].intensity *= intensityMultiplier
        }
    }
    
    private func autoAdjustQualityForPerformance() {
        // If frame rate drops below threshold, reduce effect intensity
        if performanceMetrics.frameRate < 30 {
            // Reduce effect load
            if activeIntegratedEffects.count > 3 {
                // Remove oldest effects
                activeIntegratedEffects.removeFirst()
            }
            
            // Switch to battery mode if performance is critical
            if performanceMetrics.frameRate < 20 {
                // Reduce effect intensity for performance
                effectIntensity = 0.5
            }
        }
    }
}

// MARK: - Supporting Types

/// Integrated effect that uses multiple rendering systems
struct IntegratedEffect: Identifiable {
    let id: UUID
    let type: IntegratedEffectType
    let card: Card
    let position: CGPoint
    var intensity: Float
    let startTime: CFTimeInterval
    
    var progress: Float {
        let elapsed = Float(CACurrentMediaTime() - startTime)
        return min(elapsed / Float(type.duration), 1.0)
    }
    
    var isActive: Bool {
        return progress < 1.0
    }
}

/// Types of integrated effects
enum IntegratedEffectType {
    case sevenCardSpecial
    case pointCardHighlight
    case romanianCulturalFlourish
    case selectionGlow
    case playAnimation
    case invalidMove
    
    var duration: TimeInterval {
        switch self {
        case .sevenCardSpecial: return 2.0
        case .pointCardHighlight: return 1.5
        case .romanianCulturalFlourish: return 3.0
        case .selectionGlow: return 1.0
        case .playAnimation: return 1.2
        case .invalidMove: return 0.6
        }
    }
}

/// Rendering mode options
enum RenderMode: CaseIterable {
    case swiftUI    // Pure SwiftUI rendering
    case metal      // Pure Metal rendering
    case hybrid     // Combination of both (recommended)
    
    var description: String {
        switch self {
        case .swiftUI: return "SwiftUI Only"
        case .metal: return "Metal Only"
        case .hybrid: return "Hybrid (Recommended)"
        }
    }
}

/// Performance mode options
enum PerformanceMode: CaseIterable {
    case batteryOptimized
    case balanced
    case maximumQuality
    
    var description: String {
        switch self {
        case .batteryOptimized: return "Battery Optimized"
        case .balanced: return "Balanced"
        case .maximumQuality: return "Maximum Quality"
        }
    }
}

/// Performance metrics for monitoring
struct PerformanceMetrics {
    var frameRate: Double = 60.0
    var memoryUsage: Int = 0
    var activeSwiftUIEffects: Int = 0
    var activeMetalEffects: Int = 0
    var active3DTransforms: Int = 0
    var renderMode: RenderMode = .swiftUI
    var lastUpdateTime: CFTimeInterval = 0
}

// MARK: - Extension for Card ID

extension Card {
    var id: UUID? {
        // Generate consistent UUID based on card properties
        let string = "\(suit.rawValue)_\(value)"
        return UUID(uuidString: string.md5) ?? UUID()
    }
}

// MARK: - String MD5 Extension

extension String {
    var md5: String {
        // Simple hash for UUID generation
        let hash = self.hash
        return String(format: "%08x-%04x-%04x-%04x-%012x",
                     hash & 0xFFFFFFFF,
                     (hash >> 32) & 0xFFFF,
                     (hash >> 48) & 0xFFFF,
                     (hash >> 64) & 0xFFFF,
                     hash & 0xFFFFFFFFFFFF)
    }
}

// MARK: - View Modifier for Integration

extension View {
    /// Apply integrated effects to a view
    func integratedEffects(
        manager: AdvancedEffectsIntegrationManager,
        card: Card,
        isSelected: Bool = false,
        isPlayable: Bool = true,
        isAnimating: Bool = false
    ) -> some View {
        self
            .onAppear {
                manager.updateForCardState(
                    card: card,
                    isSelected: isSelected,
                    isPlayable: isPlayable,
                    isAnimating: isAnimating
                )
            }
            .onChange(of: isSelected) {
                manager.updateForCardState(
                    card: card,
                    isSelected: isSelected,
                    isPlayable: isPlayable,
                    isAnimating: isAnimating
                )
            }
            .onChange(of: isAnimating) {
                manager.updateForCardState(
                    card: card,
                    isSelected: isSelected,
                    isPlayable: isPlayable,
                    isAnimating: isAnimating
                )
            }
    }
}