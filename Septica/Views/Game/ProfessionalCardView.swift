//
//  ProfessionalCardView.swift
//  Septica
//
//  Professional card view with ShuffleCats-quality Metal rendering
//  Integrates advanced lighting, materials, and Romanian cultural authenticity
//

import SwiftUI
import MetalKit
import simd
import Combine

/// Professional card view with Metal-based rendering for ShuffleCats quality
struct ProfessionalCardView: View {
    let card: Card
    let isSelected: Bool
    let isPlayable: Bool
    let isAnimating: Bool
    let cardSize: CardSize
    let professionalRenderer: ProfessionalCardRenderer?
    let transform: SimpleTransform
    let materialProperties: MaterialProperties
    let lightingEnvironment: LightingEnvironment
    let onTap: (() -> Void)?
    let onDragChanged: ((DragGesture.Value) -> Void)?
    let onDragEnded: ((DragGesture.Value) -> Void)?
    
    @State private var renderTexture: MTLTexture?
    @State private var isPressed = false
    @State private var dragOffset = CGSize.zero
    @State private var selectionGlowIntensity: Float = 0.0
    @State private var selectionPulsePhase: Float = 0.0
    
    var body: some View {
        ZStack {
            if professionalRenderer != nil, let texture = renderTexture {
                // Metal-rendered card
                MetalCardDisplayView(texture: texture)
                    .frame(width: cardSize.width, height: cardSize.height)
                    .scaleEffect(scaleEffect)
                    .offset(dragOffset)
                    .overlay(
                        // Enhanced selection glow effect
                        selectionGlowOverlay
                    )
                    .onTapGesture {
                        handleTap()
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                dragOffset = value.translation
                                onDragChanged?(value)
                            }
                            .onEnded { value in
                                withAnimation(.spring()) {
                                    dragOffset = .zero
                                }
                                onDragEnded?(value)
                            }
                    )
                    .accessibilityElement()
                    .accessibilityLabel(accessibilityLabel)
                    .accessibilityAddTraits(isPlayable ? .isButton : [])
            } else {
                // Fallback SwiftUI card
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
            }
        }
        .onAppear {
            renderProfessionalCard()
        }
        .onChange(of: isSelected) { _, _ in
            renderProfessionalCard()
            updateSelectionAnimation()
        }
        .onChange(of: transform) { _, _ in
            renderProfessionalCard()
        }
        .onAppear {
            startSelectionAnimation()
        }
    }
    
    private var scaleEffect: CGFloat {
        if isPressed {
            return 0.95
        } else if isSelected {
            return 1.05
        } else {
            return 1.0
        }
    }
    
    private var accessibilityLabel: String {
        return "\(card.suit.rawValue) \(card.value)"
    }
    
    private var selectionGlowOverlay: some View {
        ZStack {
            if isSelected {
                // Multi-layered glow effect for selected cards
                RoundedRectangle(cornerRadius: cardSize.width * 0.08)
                    .fill(
                        RadialGradient(
                            colors: [
                                selectionGlowColor.opacity(Double(selectionGlowIntensity * 0.8)),
                                selectionGlowColor.opacity(Double(selectionGlowIntensity * 0.4)),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: cardSize.width * 0.6
                        )
                    )
                    .scaleEffect(1.0 + Double(selectionPulsePhase) * 0.05)
                    .blur(radius: 8)

                // Inner glow for enhanced depth
                RoundedRectangle(cornerRadius: cardSize.width * 0.08)
                    .stroke(
                        LinearGradient(
                            colors: [
                                selectionGlowColor.opacity(Double(selectionGlowIntensity)),
                                selectionGlowColor.opacity(Double(selectionGlowIntensity * 0.6))
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .scaleEffect(1.0 + Double(selectionPulsePhase) * 0.02)

                // Outer rim highlight
                RoundedRectangle(cornerRadius: cardSize.width * 0.08)
                    .stroke(
                        selectionGlowColor.opacity(Double(selectionGlowIntensity * 0.3)),
                        lineWidth: 1
                    )
                    .scaleEffect(1.0 + Double(selectionPulsePhase) * 0.08)
            }
        }
    }

    private var selectionGlowColor: Color {
        if card.value == 7 {
            return Color.blue // Mystical blue for sevens
        } else if card.isPointCard {
            return Color.yellow // Gold for point cards
        } else if card.suit == .hearts {
            return Color.red // Red for hearts
        } else if card.suit == .diamonds {
            return Color.orange // Orange for diamonds
        } else {
            return Color.white // White for regular cards
        }
    }

    private func handleTap() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isPressed = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = false
            }
        }

        onTap?()
    }

    private func startSelectionAnimation() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            selectionPulsePhase = 1.0
        }

        updateSelectionAnimation()
    }

    private func updateSelectionAnimation() {
        withAnimation(.easeInOut(duration: 0.4)) {
            selectionGlowIntensity = isSelected ? 1.0 : 0.0
        }
    }
    
    private func renderProfessionalCard() {
        guard let renderer = professionalRenderer else { return }
        
        Task(priority: .userInitiated) { @MainActor in
            do {
                // Create render target texture
                let texture = try createRenderTexture()
                
                // Calculate matrices for Metal rendering
                let viewMatrix = createViewMatrix()
                let projectionMatrix = createProjectionMatrix()
                let advancedTransform = makeAdvancedTransform(from: transform)
                
                // Render card with professional effects
                try renderer.renderCardWithAdvancedEffects(
                    card,
                    transform: advancedTransform,
                    materialProperties: materialProperties,
                    lightingEnvironment: lightingEnvironment,
                    to: texture,
                    viewMatrix: viewMatrix,
                    projectionMatrix: projectionMatrix
                )
                
                renderTexture = texture
            } catch {
                print("⚠️ Failed to render professional card: \(error)")
            }
        }
    }
    
    private func createRenderTexture() throws -> MTLTexture {
        guard let device = professionalRenderer?.device else {
            throw ProfessionalCardViewError.deviceNotAvailable
        }
        
        let descriptor = MTLTextureDescriptor()
        descriptor.textureType = .type2D
        descriptor.pixelFormat = .bgra8Unorm_srgb
        descriptor.width = Int(cardSize.width * 3) // 3x for high DPI
        descriptor.height = Int(cardSize.height * 3)
        descriptor.usage = [.renderTarget, .shaderRead]
        descriptor.storageMode = .private
        
        guard let texture = device.makeTexture(descriptor: descriptor) else {
            throw ProfessionalCardViewError.textureCreationFailed
        }
        
        texture.label = "ProfessionalCardTexture"
        return texture
    }
    
    private func createViewMatrix() -> matrix_float4x4 {
        // Create view matrix for card rendering
        let eye = simd_float3(0, 0, 5)
        let center = simd_float3(0, 0, 0)
        let up = simd_float3(0, 1, 0)
        
        return lookAt(eye: eye, center: center, up: up)
    }
    
    private func createProjectionMatrix() -> matrix_float4x4 {
        let aspect = Float(cardSize.width / cardSize.height)
        let fovy: Float = 45.0 * .pi / 180.0
        let near: Float = 0.1
        let far: Float = 100.0
        
        return perspective(fovy: fovy, aspect: aspect, near: near, far: far)
    }

    private func makeAdvancedTransform(from simple: SimpleTransform) -> Advanced3DTransform {
        let advanced = Advanced3DTransform()
        advanced.position = simple.translation

        let radians = simd_float3(
            Float(simple.rotationX * .pi / 180),
            Float(simple.rotationY * .pi / 180),
            Float(simple.rotationZ * .pi / 180)
        )

        // Compose quaternion from Euler rotations (Z * Y * X)
        let qx = simd_quatf(angle: radians.x, axis: simd_float3(1, 0, 0))
        let qy = simd_quatf(angle: radians.y, axis: simd_float3(0, 1, 0))
        let qz = simd_quatf(angle: radians.z, axis: simd_float3(0, 0, 1))
        advanced.quaternionRotation = simd_mul(simd_mul(qz, qy), qx)
        advanced.rotation = radians

        return advanced
    }
}

// MARK: - Metal Display View

struct MetalCardDisplayView: UIViewRepresentable {
    let texture: MTLTexture
    
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = texture.device
        mtkView.delegate = context.coordinator
        mtkView.isPaused = true
        mtkView.enableSetNeedsDisplay = false
        mtkView.framebufferOnly = false
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.texture = texture
        uiView.setNeedsDisplay()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MTKViewDelegate {
        var texture: MTLTexture?
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
        
        func draw(in view: MTKView) {
            guard let texture = texture,
                  let drawable = view.currentDrawable,
                  let commandQueue = view.device?.makeCommandQueue(),
                  let commandBuffer = commandQueue.makeCommandBuffer() else { return }
            
            // Simple blit to display the professionally rendered texture
            let blitEncoder = commandBuffer.makeBlitCommandEncoder()
            
            blitEncoder?.copy(
                from: texture,
                sourceSlice: 0,
                sourceLevel: 0,
                sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
                sourceSize: MTLSize(width: texture.width, height: texture.height, depth: 1),
                to: drawable.texture,
                destinationSlice: 0,
                destinationLevel: 0,
                destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0)
            )
            
            blitEncoder?.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}

// MARK: - Support Manager Classes

@MainActor
class Advanced3DTransformManager: ObservableObject {
    @Published private var transforms: [String: SimpleTransform] = [:]
    
    func getTransform(for card: Card) -> SimpleTransform {
        let key = card.id.uuidString
        
        if let existing = transforms[key] {
            return existing
        }
        
        // Create default transform for card
        let transform = SimpleTransform(
            perspective: 0.6,
            rotationX: 0,
            rotationY: 0,
            rotationZ: 0,
            translation: simd_float3(0, 0, 0),
            lightingVector: simd_float3(0, 1, 0.5)
        )
        
        transforms[key] = transform
        return transform
    }
    
    func updateTransform(for card: Card, transform: SimpleTransform) {
        transforms[card.id.uuidString] = transform
    }
}

@MainActor
class MaterialEffectCoordinator: ObservableObject {
    @Published private var materials: [String: MaterialProperties] = [:]
    
    func getMaterialProperties(for card: Card) -> MaterialProperties {
        let key = card.id.uuidString
        
        if let existing = materials[key] {
            return existing
        }
        
        // Create material based on card properties
        var properties = MaterialProperties()
        properties.albedo = Color.white.toSIMD3()
        properties.metallicFactor = card.isSpecialCard ? 0.2 : 0.1
        properties.roughnessFactor = 0.6
        properties.folkPatternIntensity = 0.8
        properties.goldLeafEffect = card.suit == .hearts ? 1.0 : 0.5
        
        materials[key] = properties
        return properties
    }
}

@MainActor
class LightingEnvironmentManager: ObservableObject {
    @Published var currentEnvironment: LightingEnvironment
    @Published var tableEnvironment: LightingEnvironment
    @Published var playerEnvironment: LightingEnvironment
    
    init() {
        // Default environment with Romanian cultural warmth
        let defaultEnv = LightingEnvironment(
            primaryLightDirection: simd_float3(0, 1, 0.8),
            primaryLightColor: Color.white.toSIMD3(),
            ambientLightColor: RomanianColors.goldAccent.toSIMD3() * 0.3,
            lightIntensity: 1.0,
            shadowBias: 0.001,
            romanianCulturalTint: RomanianColors.primaryYellow.toSIMD3() * 0.2
        )
        
        self.currentEnvironment = defaultEnv
        self.tableEnvironment = defaultEnv
        self.playerEnvironment = defaultEnv
    }
    
    func configureLighting(
        ambientColor: simd_float3,
        primaryLightColor: simd_float3,
        lightIntensity: Float,
        culturalTint: simd_float3
    ) {
        let newEnv = LightingEnvironment(
            primaryLightDirection: simd_float3(0, 1, 0.8),
            primaryLightColor: primaryLightColor,
            ambientLightColor: ambientColor,
            lightIntensity: lightIntensity,
            shadowBias: 0.001,
            romanianCulturalTint: culturalTint
        )
        
        currentEnvironment = newEnv
        tableEnvironment = newEnv
        playerEnvironment = newEnv
    }
    
    func enhanceForSelectedCard(_ card: Card) {
        let enhanced = LightingEnvironment(
            primaryLightDirection: simd_float3(0, 1, 0.6),
            primaryLightColor: RomanianColors.goldAccent.toSIMD3(),
            ambientLightColor: currentEnvironment.ambientLightColor * 1.2,
            lightIntensity: 1.3,
            shadowBias: 0.0005,
            romanianCulturalTint: RomanianColors.primaryBlue.toSIMD3() * 0.3
        )
        
        currentEnvironment = enhanced
    }
    
    func resetToNormalLighting() {
        configureLighting(
            ambientColor: RomanianColors.goldAccent.toSIMD3() * 0.3,
            primaryLightColor: Color.white.toSIMD3(),
            lightIntensity: 1.0,
            culturalTint: RomanianColors.primaryYellow.toSIMD3() * 0.2
        )
    }
}

// MARK: - Matrix Utilities

func lookAt(eye: simd_float3, center: simd_float3, up: simd_float3) -> matrix_float4x4 {
    let f = normalize(center - eye)
    let s = normalize(cross(f, up))
    let u = cross(s, f)
    
    var result = matrix_identity_float4x4
    result.columns.0 = simd_float4(s.x, u.x, -f.x, 0)
    result.columns.1 = simd_float4(s.y, u.y, -f.y, 0)
    result.columns.2 = simd_float4(s.z, u.z, -f.z, 0)
    result.columns.3 = simd_float4(-dot(s, eye), -dot(u, eye), dot(f, eye), 1)
    
    return result
}

func perspective(fovy: Float, aspect: Float, near: Float, far: Float) -> matrix_float4x4 {
    let yScale = 1 / tan(fovy * 0.5)
    let xScale = yScale / aspect
    let zRange = far - near
    let zScale = -(far + near) / zRange
    let wzScale = -2 * far * near / zRange
    
    var result = matrix_float4x4()
    result.columns.0 = simd_float4(xScale, 0, 0, 0)
    result.columns.1 = simd_float4(0, yScale, 0, 0)
    result.columns.2 = simd_float4(0, 0, zScale, -1)
    result.columns.3 = simd_float4(0, 0, wzScale, 0)
    
    return result
}

// MARK: - Color Extensions

extension Color {
    func toSIMD3() -> simd_float3 {
        let cgColor = self.cgColor ?? UIColor.white.cgColor
        let components = cgColor.components ?? [1, 1, 1, 1]
        return simd_float3(
            Float(components[0]),
            Float(components[1]),
            Float(components[2])
        )
    }
    
    func toSIMD4() -> simd_float4 {
        let cgColor = self.cgColor ?? UIColor.white.cgColor
        let components = cgColor.components ?? [1, 1, 1, 1]
        return simd_float4(
            Float(components[0]),
            Float(components[1]),
            Float(components[2]),
            Float(components[3])
        )
    }
}

// MARK: - Error Types

enum ProfessionalCardViewError: Error {
    case deviceNotAvailable
    case textureCreationFailed
    case renderingFailed
}
