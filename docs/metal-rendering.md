# Septica Metal Rendering Engine Documentation

## 🚀 Rendering Architecture Overview

The Septica Metal rendering engine is designed for 60 FPS card game performance with advanced visual effects, realistic lighting, and smooth animations. Built on Apple's Metal 3 framework, it leverages GPU compute shaders for physics simulation and particle effects.

## ⚡ Core Metal Pipeline

### Rendering System Architecture
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Scene Graph   │───▶│  Render Queue   │───▶│  Metal Engine   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ Game Objects    │    │  Draw Commands  │    │   GPU Buffers   │
│ - Cards         │    │  - Geometry     │    │  - Vertices     │
│ - Table         │    │  - Materials    │    │  - Textures     │
│ - Effects       │    │  - Transforms   │    │  - Uniforms     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Metal Framework Integration
```swift
class SepticaRenderer: NSObject, MTKViewDelegate {
    // Core Metal objects
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let library: MTLLibrary
    
    // Rendering pipelines
    private var cardRenderPipeline: MTLRenderPipelineState
    private var tableRenderPipeline: MTLRenderPipelineState
    private var particleComputePipeline: MTLComputePipelineState
    private var shadowMapPipeline: MTLRenderPipelineState
    
    // Resource management
    private let resourceManager: MetalResourceManager
    private let bufferAllocator: BufferAllocator
    private let textureCache: TextureCache
    
    // Frame synchronization
    private let inFlightSemaphore = DispatchSemaphore(value: 3)
    private var currentFrameIndex = 0
    
    init(metalKitView: MTKView) throws {
        self.device = metalKitView.device!
        self.commandQueue = device.makeCommandQueue()!
        self.library = device.makeDefaultLibrary()!
        
        // Initialize rendering pipelines
        self.cardRenderPipeline = try Self.createCardPipeline(device: device, library: library)
        self.tableRenderPipeline = try Self.createTablePipeline(device: device, library: library)
        self.particleComputePipeline = try Self.createParticlePipeline(device: device, library: library)
        self.shadowMapPipeline = try Self.createShadowPipeline(device: device, library: library)
        
        // Initialize resource management
        self.resourceManager = MetalResourceManager(device: device)
        self.bufferAllocator = BufferAllocator(device: device)
        self.textureCache = TextureCache(device: device)
        
        super.init()
        
        metalKitView.delegate = self
        metalKitView.depthStencilPixelFormat = .depth32Float
        metalKitView.colorPixelFormat = .bgra8Unorm_srgb
        metalKitView.sampleCount = 4 // MSAA 4x
    }
}
```

## 🃏 Card Rendering System

### Card Geometry Generation
```swift
struct CardVertex {
    let position: simd_float3
    let normal: simd_float3
    let texCoord: simd_float2
    let tangent: simd_float3
}

class CardMeshGenerator {
    static func generateCardMesh(width: Float, height: Float, thickness: Float = 0.002) -> [CardVertex] {
        let halfWidth = width * 0.5
        let halfHeight = height * 0.5
        let halfThickness = thickness * 0.5
        
        var vertices: [CardVertex] = []
        
        // Front face
        vertices.append(contentsOf: [
            CardVertex(position: simd_float3(-halfWidth, -halfHeight, halfThickness),
                      normal: simd_float3(0, 0, 1),
                      texCoord: simd_float2(0, 1),
                      tangent: simd_float3(1, 0, 0)),
            
            CardVertex(position: simd_float3(halfWidth, -halfHeight, halfThickness),
                      normal: simd_float3(0, 0, 1),
                      texCoord: simd_float2(1, 1),
                      tangent: simd_float3(1, 0, 0)),
            
            CardVertex(position: simd_float3(halfWidth, halfHeight, halfThickness),
                      normal: simd_float3(0, 0, 1),
                      texCoord: simd_float2(1, 0),
                      tangent: simd_float3(1, 0, 0)),
            
            CardVertex(position: simd_float3(-halfWidth, halfHeight, halfThickness),
                      normal: simd_float3(0, 0, 1),
                      texCoord: simd_float2(0, 0),
                      tangent: simd_float3(1, 0, 0))
        ])
        
        // Back face and edges...
        // (Additional vertices for complete 3D card)
        
        return vertices
    }
}
```

### Card Shader Implementation
```metal
// Card vertex shader
vertex VertexOut cardVertexShader(VertexIn in [[stage_in]],
                                  constant Uniforms& uniforms [[buffer(0)]],
                                  constant CardInstanceData& instanceData [[buffer(1)]],
                                  uint instanceId [[instance_id]]) {
    VertexOut out;
    
    // Transform vertex position
    float4 worldPosition = instanceData.modelMatrix * float4(in.position, 1.0);
    out.position = uniforms.projectionMatrix * uniforms.viewMatrix * worldPosition;
    out.worldPosition = worldPosition.xyz;
    
    // Transform normal for lighting
    float3 worldNormal = normalize((instanceData.normalMatrix * float4(in.normal, 0.0)).xyz);
    out.normal = worldNormal;
    
    // Pass through texture coordinates
    out.texCoord = in.texCoord;
    
    // Calculate tangent space for normal mapping
    float3 worldTangent = normalize((instanceData.modelMatrix * float4(in.tangent, 0.0)).xyz);
    out.tangent = worldTangent;
    out.bitangent = cross(worldNormal, worldTangent);
    
    // Shadow mapping
    out.shadowCoord = uniforms.shadowMatrix * worldPosition;
    
    return out;
}

// Card fragment shader
fragment float4 cardFragmentShader(VertexOut in [[stage_in]],
                                   texture2d<float> diffuseTexture [[texture(0)]],
                                   texture2d<float> normalMap [[texture(1)]],
                                   texture2d<float> roughnessMap [[texture(2)]],
                                   texture2d<float> shadowMap [[texture(3)]],
                                   constant Material& material [[buffer(0)]],
                                   constant LightingUniforms& lighting [[buffer(1)]],
                                   sampler textureSampler [[sampler(0)]]) {
    
    // Sample textures
    float4 baseColor = diffuseTexture.sample(textureSampler, in.texCoord);
    float3 normalSample = normalMap.sample(textureSampler, in.texCoord).xyz * 2.0 - 1.0;
    float roughness = roughnessMap.sample(textureSampler, in.texCoord).r;
    
    // Calculate world normal from normal map
    float3x3 TBN = float3x3(in.tangent, in.bitangent, in.normal);
    float3 normal = normalize(TBN * normalSample);
    
    // Lighting calculations
    float3 viewDir = normalize(lighting.cameraPosition - in.worldPosition);
    float3 lightDir = normalize(lighting.directionalLight.direction);
    
    // Shadow mapping
    float shadowFactor = calculateShadow(shadowMap, in.shadowCoord, textureSampler);
    
    // PBR lighting
    float3 color = calculatePBR(baseColor.rgb, normal, viewDir, lightDir, roughness, material.metallic);
    color *= shadowFactor;
    
    // Add ambient lighting
    color += lighting.ambientColor.rgb * baseColor.rgb * lighting.ambientStrength;
    
    return float4(color, baseColor.a * material.opacity);
}
```

### Instanced Card Rendering
```swift
class CardRenderer {
    private var instanceBuffer: MTLBuffer
    private var cardInstances: [CardInstance] = []
    
    struct CardInstance {
        var modelMatrix: simd_float4x4
        var normalMatrix: simd_float3x3
        var textureIndex: UInt32
        var materialIndex: UInt32
        var opacity: Float
        var highlighted: Bool
    }
    
    func renderCards(_ cards: [GameCard], encoder: MTLRenderCommandEncoder) {
        // Update instance buffer
        updateCardInstances(cards)
        
        // Set render pipeline
        encoder.setRenderPipelineState(cardRenderPipeline)
        
        // Bind mesh data
        encoder.setVertexBuffer(cardMeshBuffer, offset: 0, index: 0)
        encoder.setVertexBuffer(instanceBuffer, offset: 0, index: 1)
        
        // Bind textures
        encoder.setFragmentTexture(cardAtlasTexture, index: 0)
        encoder.setFragmentTexture(normalMapTexture, index: 1)
        encoder.setFragmentTexture(roughnessTexture, index: 2)
        encoder.setFragmentTexture(shadowMapTexture, index: 3)
        
        // Draw all cards in single call
        encoder.drawIndexedPrimitives(
            type: .triangle,
            indexCount: cardMesh.indexCount,
            indexType: .uint16,
            indexBuffer: cardMesh.indexBuffer,
            indexBufferOffset: 0,
            instanceCount: cards.count
        )
    }
    
    private func updateCardInstances(_ cards: [GameCard]) {
        cardInstances.removeAll(keepingCapacity: true)
        
        for (index, card) in cards.enumerated() {
            let transform = card.worldTransform
            let normalMatrix = simd_float3x3(transform.upperLeft3x3.inverse.transpose)
            
            let instance = CardInstance(
                modelMatrix: transform,
                normalMatrix: normalMatrix,
                textureIndex: UInt32(card.textureIndex),
                materialIndex: UInt32(card.materialIndex),
                opacity: card.opacity,
                highlighted: card.isHighlighted
            )
            
            cardInstances.append(instance)
        }
        
        // Upload to GPU
        let bufferPointer = instanceBuffer.contents().bindMemory(to: CardInstance.self, capacity: cards.count)
        for (index, instance) in cardInstances.enumerated() {
            bufferPointer[index] = instance
        }
    }
}
```

## 🌟 Advanced Visual Effects

### Particle System
```swift
class MetalParticleSystem {
    private let device: MTLDevice
    private let computePipeline: MTLComputePipelineState
    private let renderPipeline: MTLRenderPipelineState
    
    private var particleBuffer: MTLBuffer
    private var particleCount: Int = 0
    private let maxParticles: Int = 10000
    
    struct Particle {
        var position: simd_float3
        var velocity: simd_float3
        var color: simd_float4
        var size: Float
        var life: Float
        var maxLife: Float
    }
    
    func update(deltaTime: Float, encoder: MTLComputeCommandEncoder) {
        encoder.setComputePipelineState(computePipeline)
        encoder.setBuffer(particleBuffer, offset: 0, index: 0)
        encoder.setBytes(&deltaTime, length: MemoryLayout<Float>.size, index: 1)
        
        let threadsPerGroup = MTLSize(width: 64, height: 1, depth: 1)
        let numThreadgroups = MTLSize(
            width: (particleCount + threadsPerGroup.width - 1) / threadsPerGroup.width,
            height: 1,
            depth: 1
        )
        
        encoder.dispatchThreadgroups(numThreadgroups, threadsPerThreadgroup: threadsPerGroup)
    }
}
```

### Particle Compute Shader
```metal
kernel void updateParticles(device Particle* particles [[buffer(0)]],
                           constant float& deltaTime [[buffer(1)]],
                           uint index [[thread_position_in_grid]]) {
    
    Particle particle = particles[index];
    
    // Update particle life
    particle.life -= deltaTime;
    
    if (particle.life <= 0.0) {
        // Respawn particle
        particle.position = float3(0.0);
        particle.velocity = generateRandomVelocity();
        particle.life = particle.maxLife;
        particle.color.a = 1.0;
    } else {
        // Update physics
        particle.velocity.y -= 9.8 * deltaTime; // Gravity
        particle.position += particle.velocity * deltaTime;
        
        // Fade out over time
        particle.color.a = particle.life / particle.maxLife;
    }
    
    particles[index] = particle;
}
```

### Shadow Mapping
```swift
class ShadowRenderer {
    private let shadowMapSize: Int = 2048
    private let shadowDepthTexture: MTLTexture
    private let shadowRenderPassDescriptor: MTLRenderPassDescriptor
    
    func renderShadowMap(cards: [GameCard], light: DirectionalLight, encoder: MTLRenderCommandEncoder) {
        // Calculate light space matrix
        let lightView = createLookAtMatrix(eye: light.position, center: simd_float3(0), up: simd_float3(0, 1, 0))
        let lightProjection = createOrthographicMatrix(left: -10, right: 10, bottom: -10, top: 10, near: 0.1, far: 100)
        let lightSpaceMatrix = lightProjection * lightView
        
        // Render to shadow map
        encoder.setRenderPipelineState(shadowMapPipeline)
        
        for card in cards {
            var mvpMatrix = lightSpaceMatrix * card.worldTransform
            encoder.setVertexBytes(&mvpMatrix, length: MemoryLayout<simd_float4x4>.size, index: 0)
            encoder.setVertexBuffer(cardMeshBuffer, offset: 0, index: 1)
            
            encoder.drawIndexedPrimitives(
                type: .triangle,
                indexCount: cardMesh.indexCount,
                indexType: .uint16,
                indexBuffer: cardMesh.indexBuffer,
                indexBufferOffset: 0
            )
        }
    }
}
```

## 🎨 Material System

### Physical-Based Rendering Materials
```swift
struct PBRMaterial {
    var baseColor: simd_float4
    var metallic: Float
    var roughness: Float
    var normalStrength: Float
    var emissiveColor: simd_float3
    var opacity: Float
    
    static let cardFront = PBRMaterial(
        baseColor: simd_float4(1.0, 1.0, 1.0, 1.0),
        metallic: 0.0,
        roughness: 0.1,
        normalStrength: 1.0,
        emissiveColor: simd_float3(0.0),
        opacity: 1.0
    )
    
    static let cardBack = PBRMaterial(
        baseColor: simd_float4(0.2, 0.3, 0.6, 1.0),
        metallic: 0.1,
        roughness: 0.3,
        normalStrength: 0.5,
        emissiveColor: simd_float3(0.0),
        opacity: 1.0
    )
    
    static let tableWood = PBRMaterial(
        baseColor: simd_float4(0.4, 0.2, 0.1, 1.0),
        metallic: 0.0,
        roughness: 0.8,
        normalStrength: 1.0,
        emissiveColor: simd_float3(0.0),
        opacity: 1.0
    )
}
```

### Texture Atlas Management
```swift
class TextureAtlasManager {
    private let device: MTLDevice
    private let textureLoader: MTKTextureLoader
    private var atlasTexture: MTLTexture?
    private var atlasDescriptors: [String: AtlasRegion] = [:]
    
    struct AtlasRegion {
        let minU: Float
        let maxU: Float  
        let minV: Float
        let maxV: Float
    }
    
    func loadCardAtlas() throws {
        // Load card texture atlas
        let textureOptions: [MTKTextureLoader.Option: Any] = [
            .textureUsage: MTLTextureUsage.shaderRead.rawValue,
            .textureStorageMode: MTLStorageMode.private.rawValue,
            .generateMipmaps: true
        ]
        
        atlasTexture = try textureLoader.newTexture(
            name: "card_atlas_4k",
            scaleFactor: 1.0,
            bundle: Bundle.main,
            options: textureOptions
        )
        
        // Define card regions in atlas
        setupCardRegions()
    }
    
    private func setupCardRegions() {
        let cardWidth: Float = 1.0 / 13.0  // 13 values per row
        let cardHeight: Float = 1.0 / 4.0  // 4 suits per column
        
        for suit in 0..<4 {
            for value in 0..<13 {
                let cardKey = "\(suit)_\(value)"
                let region = AtlasRegion(
                    minU: Float(value) * cardWidth,
                    maxU: Float(value + 1) * cardWidth,
                    minV: Float(suit) * cardHeight,
                    maxV: Float(suit + 1) * cardHeight
                )
                atlasDescriptors[cardKey] = region
            }
        }
    }
}
```

## 🎬 Animation System

### Transform Animation
```swift
class CardAnimator {
    private var activeAnimations: [UUID: CardAnimation] = [:]
    
    struct CardAnimation {
        let cardId: UUID
        let startTransform: simd_float4x4
        let endTransform: simd_float4x4
        let duration: TimeInterval
        let startTime: TimeInterval
        let curve: AnimationCurve
    }
    
    enum AnimationCurve {
        case linear
        case easeIn
        case easeOut
        case easeInOut
        case spring(damping: Float, stiffness: Float)
    }
    
    func animateCard(id: UUID, to transform: simd_float4x4, duration: TimeInterval, curve: AnimationCurve = .easeOut) {
        let animation = CardAnimation(
            cardId: id,
            startTransform: currentTransform(for: id),
            endTransform: transform,
            duration: duration,
            startTime: CACurrentMediaTime(),
            curve: curve
        )
        
        activeAnimations[id] = animation
    }
    
    func update(currentTime: TimeInterval) {
        var completedAnimations: [UUID] = []
        
        for (id, animation) in activeAnimations {
            let elapsed = currentTime - animation.startTime
            let progress = min(elapsed / animation.duration, 1.0)
            
            if progress >= 1.0 {
                // Animation complete
                setTransform(id: id, transform: animation.endTransform)
                completedAnimations.append(id)
            } else {
                // Interpolate transform
                let easedProgress = applyAnimationCurve(progress, curve: animation.curve)
                let interpolatedTransform = interpolateTransform(
                    from: animation.startTransform,
                    to: animation.endTransform,
                    t: Float(easedProgress)
                )
                setTransform(id: id, transform: interpolatedTransform)
            }
        }
        
        // Remove completed animations
        for id in completedAnimations {
            activeAnimations.removeValue(forKey: id)
        }
    }
}
```

### Physics Integration
```metal
// Simple physics simulation for card motion
kernel void simulateCardPhysics(device CardPhysics* cards [[buffer(0)]],
                               constant PhysicsParams& params [[buffer(1)]],
                               uint index [[thread_position_in_grid]]) {
    
    CardPhysics card = cards[index];
    
    // Apply gravity
    card.velocity.y -= params.gravity * params.deltaTime;
    
    // Apply air resistance
    card.velocity *= (1.0 - params.drag * params.deltaTime);
    
    // Update position
    card.position += card.velocity * params.deltaTime;
    
    // Table collision
    if (card.position.y <= params.tableHeight && card.velocity.y < 0.0) {
        card.position.y = params.tableHeight;
        card.velocity.y *= -params.restitution;
        
        // Add some friction
        card.velocity.xz *= (1.0 - params.friction);
    }
    
    cards[index] = card;
}
```

## 🔧 Performance Optimization

### Memory Management
```swift
class BufferAllocator {
    private let device: MTLDevice
    private var bufferPool: [MTLBuffer] = []
    private var freeBuffers: [MTLBuffer] = []
    
    func allocateBuffer(size: Int) -> MTLBuffer {
        if let buffer = freeBuffers.popLast() {
            return buffer
        }
        
        let buffer = device.makeBuffer(length: size, options: .storageModeShared)!
        bufferPool.append(buffer)
        return buffer
    }
    
    func releaseBuffer(_ buffer: MTLBuffer) {
        freeBuffers.append(buffer)
    }
}
```

### GPU Profiling Integration
```swift
extension SepticaRenderer {
    func setupGPUProfiling() {
        #if DEBUG
        // Enable GPU capture programmatically
        let captureManager = MTLCaptureManager.shared()
        let captureDescriptor = MTLCaptureDescriptor()
        captureDescriptor.captureObject = device
        captureDescriptor.destination = .gpuTraceDocument
        captureDescriptor.outputURL = getDocumentsDirectory().appendingPathComponent("septica_trace.gputrace")
        
        do {
            try captureManager.startCapture(with: captureDescriptor)
        } catch {
            print("Failed to start GPU capture: \(error)")
        }
        #endif
    }
}
```

### Culling System
```swift
class RenderCuller {
    func cullCards(_ cards: [GameCard], camera: Camera) -> [GameCard] {
        let frustum = camera.frustum
        
        return cards.filter { card in
            let bounds = card.boundingBox
            return frustum.intersects(bounds)
        }
    }
    
    func sortByDepth(_ cards: [GameCard], camera: Camera) -> [GameCard] {
        let cameraPosition = camera.position
        
        return cards.sorted { card1, card2 in
            let distance1 = simd_distance(card1.position, cameraPosition)
            let distance2 = simd_distance(card2.position, cameraPosition)
            return distance1 > distance2 // Back to front for alpha blending
        }
    }
}
```

## 📊 Performance Targets

### Frame Rate Optimization
- **Target FPS:** 60 (iPhone 11+), 120 (ProMotion devices)
- **Frame Time Budget:** 16.67ms (60 FPS), 8.33ms (120 FPS)
- **GPU Time:** <12ms per frame
- **CPU Time:** <4ms per frame

### Memory Usage
- **VRAM:** <100MB for textures and buffers
- **RAM:** <50MB for geometry and CPU data structures
- **Dynamic Allocation:** <1MB per frame

### Thermal Management
- **GPU Utilization:** <80% sustained
- **Thermal Throttling:** Graceful degradation of effects quality
- **Power Efficiency:** Adaptive quality based on battery level

This Metal rendering engine provides the foundation for premium 60 FPS card game visuals with advanced lighting, realistic materials, and smooth animations while maintaining excellent performance across all iOS devices.