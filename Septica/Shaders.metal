//
//  Shaders.metal
//  Septica
//
//  Enhanced Metal shaders for Romanian Septica card game
//  Provides premium visual effects for card rendering and animations
//

// File for Metal kernel and shader functions

#include <metal_stdlib>
#include <simd/simd.h>

// Including header shared between this Metal shader code and Swift/C code executing Metal API commands
#import "ShaderTypes.h"

using namespace metal;

// MARK: - Vertex Input/Output Structures

typedef struct
{
    float3 position [[attribute(VertexAttributePosition)]];
    float2 texCoord [[attribute(VertexAttributeTexcoord)]];
} Vertex;

typedef struct
{
    float4 position [[position]];
    float2 texCoord;
    float3 worldPos;
} ColorInOut;

typedef struct
{
    float4 position [[position]];
    float2 texCoord;
    float4 color;
    float alpha;
} ParticleOut;

// MARK: - Card Rendering Shaders

vertex ColorInOut cardVertexShader(Vertex in [[stage_in]],
                                   constant Uniforms & uniforms [[ buffer(BufferIndexUniforms) ]])
{
    ColorInOut out;

    float4 position = float4(in.position, 1.0);
    out.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * position;
    out.texCoord = in.texCoord;
    out.worldPos = (uniforms.modelViewMatrix * position).xyz;

    return out;
}

fragment float4 cardFragmentShader(ColorInOut in [[stage_in]],
                                   constant Uniforms & uniforms [[ buffer(BufferIndexUniforms) ]],
                                   texture2d<half> cardTexture [[ texture(TextureIndexColor) ]])
{
    constexpr sampler cardSampler(mip_filter::linear,
                                  mag_filter::linear,
                                  min_filter::linear);

    half4 cardColor = cardTexture.sample(cardSampler, in.texCoord.xy);
    
    // Add subtle card edge glow for Romanian elegance
    float2 center = float2(0.5, 0.5);
    float distance = length(in.texCoord - center);
    float edgeGlow = smoothstep(0.4, 0.5, distance) * 0.1;
    
    // Romanian traditional colors enhancement
    float3 romanianGold = float3(1.0, 0.84, 0.0);
    float3 romanianRed = float3(0.8, 0.2, 0.2);
    
    // Enhance card colors based on suit
    float3 enhancedColor = float3(cardColor.rgb);
    
    // Add warm lighting for traditional feel
    float3 warmLight = float3(1.05, 1.02, 0.98);
    enhancedColor *= warmLight;
    
    return float4(enhancedColor + edgeGlow, float(cardColor.a));
}

// MARK: - Professional Card Rendering Structures

typedef struct
{
    float3 position [[attribute(0)]];
    float3 normal [[attribute(1)]];
    float2 texCoord [[attribute(2)]];
    float3 tangent [[attribute(3)]];
    float2 culturalUV [[attribute(4)]];
} ProfessionalVertex;

typedef struct
{
    float4 position [[position]];
    float2 texCoord;
    float3 worldPos;
    float3 worldNormal;
    float3 worldTangent;
    float2 culturalUV;
    float4 shadowCoord;
} ProfessionalColorInOut;

// MARK: - Professional Card Shaders

vertex ProfessionalColorInOut professionalCardVertexShader(ProfessionalVertex in [[stage_in]],
                                                          constant TransformUniforms & transforms [[ buffer(0) ]],
                                                          constant LightingUniforms & lighting [[ buffer(1) ]])
{
    ProfessionalColorInOut out;
    
    float4 worldPos = transforms.modelMatrix * float4(in.position, 1.0);
    out.position = transforms.projectionMatrix * transforms.viewMatrix * worldPos;
    out.worldPos = worldPos.xyz;
    
    // Transform normal and tangent to world space
    float3x3 normalMatrix = float3x3(transforms.normalMatrix);
    out.worldNormal = normalize(normalMatrix * in.normal);
    out.worldTangent = normalize(normalMatrix * in.tangent);
    
    out.texCoord = in.texCoord;
    out.culturalUV = in.culturalUV;
    
    // Shadow coordinate calculation
    float4x4 shadowMatrix = transforms.projectionMatrix * transforms.viewMatrix;
    out.shadowCoord = shadowMatrix * worldPos;
    
    return out;
}

fragment float4 professionalCardFragmentShader(ProfessionalColorInOut in [[stage_in]],
                                              constant MaterialProperties & material [[ buffer(0) ]],
                                              constant LightingUniforms & lighting [[ buffer(1) ]],
                                              texture2d<half> cardTexture [[ texture(0) ]],
                                              texture2d<float> shadowMap [[ texture(1) ]],
                                              texture2d<half> normalMap [[ texture(2) ]],
                                              sampler cardSampler [[ sampler(0) ]],
                                              sampler shadowSampler [[ sampler(1) ]])
{
    // Sample base color
    half4 baseColor = cardTexture.sample(cardSampler, in.texCoord);
    
    // Sample normal map
    half3 normalTexture = normalMap.sample(cardSampler, in.texCoord).rgb * 2.0 - 1.0;
    
    // Calculate tangent-space to world-space transformation
    float3 N = normalize(in.worldNormal);
    float3 T = normalize(in.worldTangent);
    float3 B = cross(N, T);
    float3x3 TBN = float3x3(T, B, N);
    float3 worldNormal = normalize(TBN * float3(normalTexture));
    
    // Lighting calculations
    float3 lightDir = normalize(-lighting.lightDirection);
    float3 viewDir = normalize(-in.worldPos);
    
    // Diffuse lighting
    float NdotL = max(dot(worldNormal, lightDir), 0.0);
    float3 diffuse = lighting.lightColor * NdotL;
    
    // Specular lighting (Blinn-Phong)
    float3 halfwayDir = normalize(lightDir + viewDir);
    float NdotH = max(dot(worldNormal, halfwayDir), 0.0);
    float specularPower = mix(16.0, 64.0, 1.0 - material.roughness);
    float specular = pow(NdotH, specularPower) * material.specular;
    
    // Shadow calculation
    float shadow = 1.0;
    if (in.shadowCoord.w > 0.0) {
        float3 shadowCoord = in.shadowCoord.xyz / in.shadowCoord.w;
        shadowCoord = shadowCoord * 0.5 + 0.5;
        
        if (shadowCoord.x >= 0.0 && shadowCoord.x <= 1.0 &&
            shadowCoord.y >= 0.0 && shadowCoord.y <= 1.0) {
            float shadowDepth = shadowMap.sample(shadowSampler, shadowCoord.xy).x;
            shadow = (shadowCoord.z - lighting.shadowBias) <= shadowDepth ? 1.0 : 0.3;
        }
    }
    
    // Romanian cultural enhancement
    float3 culturalTint = lighting.romanianCulturalTint * material.culturalIntensity;
    
    // Combine lighting
    float3 ambient = lighting.ambientColor * 0.3;
    float3 finalColor = float3(baseColor.rgb) * (ambient + (diffuse + specular) * shadow);
    finalColor = mix(finalColor, finalColor * culturalTint, 0.2);
    
    return float4(finalColor, baseColor.a);
}

// MARK: - Depth Only Shaders

vertex float4 depthOnlyVertexShader(ProfessionalVertex in [[stage_in]],
                                   constant TransformUniforms & transforms [[ buffer(0) ]])
{
    float4 worldPos = transforms.modelMatrix * float4(in.position, 1.0);
    return transforms.projectionMatrix * transforms.viewMatrix * worldPos;
}

// MARK: - Shadow Map Shaders

vertex float4 shadowMapVertexShader(ProfessionalVertex in [[stage_in]],
                                   constant TransformUniforms & transforms [[ buffer(0) ]])
{
    float4 worldPos = transforms.modelMatrix * float4(in.position, 1.0);
    return transforms.projectionMatrix * transforms.viewMatrix * worldPos;
}

fragment float shadowMapFragmentShader(float4 position [[position]])
{
    return position.z;
}

// MARK: - Material Effect Shaders

vertex ProfessionalColorInOut materialEffectVertexShader(ProfessionalVertex in [[stage_in]],
                                                        constant TransformUniforms & transforms [[ buffer(0) ]])
{
    ProfessionalColorInOut out;
    
    float4 worldPos = transforms.modelMatrix * float4(in.position, 1.0);
    out.position = transforms.projectionMatrix * transforms.viewMatrix * worldPos;
    out.worldPos = worldPos.xyz;
    out.texCoord = in.texCoord;
    
    return out;
}

fragment float4 materialEffectFragmentShader(ProfessionalColorInOut in [[stage_in]],
                                            constant MaterialProperties & material [[ buffer(0) ]])
{
    // Reflection and refraction effects
    float3 viewDir = normalize(-in.worldPos);
    float fresnel = pow(1.0 - max(dot(in.worldNormal, viewDir), 0.0), 2.0);
    
    // Metallic reflection
    float3 reflection = mix(float3(0.1), float3(0.9), material.metallic);
    
    // Romanian gold accent for metallic surfaces
    float3 romanianGold = float3(1.0, 0.84, 0.0);
    reflection = mix(reflection, romanianGold, material.culturalIntensity * 0.3);
    
    return float4(reflection * fresnel, 1.0);
}

// MARK: - Cultural Pattern Shaders

vertex ProfessionalColorInOut culturalPatternVertexShader(ProfessionalVertex in [[stage_in]],
                                                         constant TransformUniforms & transforms [[ buffer(0) ]])
{
    ProfessionalColorInOut out;
    
    float4 worldPos = transforms.modelMatrix * float4(in.position, 1.0);
    out.position = transforms.projectionMatrix * transforms.viewMatrix * worldPos;
    out.culturalUV = in.culturalUV;
    
    return out;
}

fragment float4 culturalPatternFragmentShader(ProfessionalColorInOut in [[stage_in]],
                                             texture2d<half> culturalTexture [[ texture(0) ]],
                                             sampler culturalSampler [[ sampler(0) ]])
{
    half4 pattern = culturalTexture.sample(culturalSampler, in.culturalUV);
    
    // Romanian traditional pattern enhancement
    float3 romanianBlue = float3(0.0, 0.27, 0.68);
    float3 romanianYellow = float3(1.0, 0.84, 0.0);
    float3 romanianRed = float3(0.8, 0.2, 0.2);
    
    // Blend traditional colors
    float3 culturalColor = mix(romanianBlue, romanianYellow, pattern.r);
    culturalColor = mix(culturalColor, romanianRed, pattern.g);
    
    return float4(culturalColor, pattern.a * 0.3);
}

// MARK: - Card Selection Highlight Shader

fragment float4 cardHighlightShader(ColorInOut in [[stage_in]],
                                     constant Uniforms & uniforms [[ buffer(BufferIndexUniforms) ]],
                                     texture2d<half> cardTexture [[ texture(TextureIndexColor) ]])
{
    constexpr sampler cardSampler(mip_filter::linear,
                                  mag_filter::linear,
                                  min_filter::linear);

    half4 cardColor = cardTexture.sample(cardSampler, in.texCoord.xy);
    
    // Golden selection highlight for Romanian elegance
    float2 center = float2(0.5, 0.5);
    float distance = length(in.texCoord - center);
    
    // Pulsing golden border
    float time = uniforms.modelViewMatrix[3][3]; // Use matrix component as time
    float pulse = sin(time * 6.0) * 0.5 + 0.5;
    float border = smoothstep(0.45, 0.5, distance) * pulse;
    
    float3 goldHighlight = float3(1.0, 0.84, 0.2) * border * 0.6;
    
    float3 highlightedColor = float3(cardColor.rgb) + goldHighlight;
    return float4(highlightedColor, float(cardColor.a));
}

// MARK: - Card Animation Shaders

vertex ColorInOut cardFlipVertexShader(Vertex in [[stage_in]],
                                        constant Uniforms & uniforms [[ buffer(BufferIndexUniforms) ]])
{
    ColorInOut out;
    
    float4 position = float4(in.position, 1.0);
    
    // Apply flip rotation around Y-axis
    float flipAngle = uniforms.modelViewMatrix[0][3]; // Use matrix component as flip angle
    float cosAngle = cos(flipAngle);
    float sinAngle = sin(flipAngle);
    
    // Flip transformation
    position.x *= cosAngle;
    position.z = position.x * sinAngle;
    
    out.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * position;
    out.texCoord = in.texCoord;
    out.worldPos = (uniforms.modelViewMatrix * position).xyz;
    
    return out;
}

// MARK: - Particle System for Romanian Cultural Effects

vertex ParticleOut particleVertexShader(Vertex in [[stage_in]],
                                         constant Uniforms & uniforms [[ buffer(BufferIndexUniforms) ]])
{
    ParticleOut out;
    
    float4 position = float4(in.position, 1.0);
    out.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * position;
    out.texCoord = in.texCoord;
    
    // Traditional Romanian colors for celebrations
    float3 romanianColors[4] = {
        float3(0.8, 0.2, 0.2),  // Deep red
        float3(1.0, 0.84, 0.0), // Gold
        float3(0.2, 0.4, 0.8),  // Royal blue
        float3(0.9, 0.9, 0.9)   // Silver
    };
    
    int colorIndex = int(in.position.z) % 4;
    out.color = float4(romanianColors[colorIndex], 1.0);
    
    // Fade based on age/distance
    float distance = length(in.position.xy);
    out.alpha = 1.0 - smoothstep(0.0, 2.0, distance);
    
    return out;
}

fragment float4 particleFragmentShader(ParticleOut in [[stage_in]])
{
    // Create circular particles
    float2 center = float2(0.5, 0.5);
    float distance = length(in.texCoord - center);
    
    if (distance > 0.5) {
        discard_fragment();
    }
    
    // Soft circular particle with alpha falloff
    float alpha = (1.0 - distance * 2.0) * in.alpha;
    
    return float4(in.color.rgb, alpha);
}

// MARK: - Romanian Pattern Overlay Shader

fragment float4 romanianPatternShader(ColorInOut in [[stage_in]],
                                       constant Uniforms & uniforms [[ buffer(BufferIndexUniforms) ]],
                                       texture2d<half> cardTexture [[ texture(TextureIndexColor) ]])
{
    constexpr sampler cardSampler(mip_filter::linear,
                                  mag_filter::linear,
                                  min_filter::linear);

    half4 cardColor = cardTexture.sample(cardSampler, in.texCoord.xy);
    
    // Traditional Romanian geometric patterns
    float2 scaledCoord = in.texCoord * 8.0;
    float pattern1 = sin(scaledCoord.x) * sin(scaledCoord.y);
    float pattern2 = cos(scaledCoord.x + scaledCoord.y) * 0.5;
    
    // Subtle pattern overlay
    float patternStrength = (pattern1 + pattern2) * 0.02;
    
    // Romanian traditional color tints
    float3 patternColor = float3(0.9, 0.85, 0.7); // Warm beige
    
    float3 finalColor = float3(cardColor.rgb) + (patternColor * patternStrength);
    
    return float4(finalColor, float(cardColor.a));
}

// MARK: - Performance Optimized Basic Shaders

inline ColorInOut basicVertexShaderCore(Vertex in,
                                        constant Uniforms & uniforms)
{
    ColorInOut out;

    float4 position = float4(in.position, 1.0);
    out.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * position;
    out.texCoord = in.texCoord;
    out.worldPos = (uniforms.modelViewMatrix * position).xyz;

    return out;
}

vertex ColorInOut basicVertexShader(Vertex in [[stage_in]],
                                     constant Uniforms & uniforms [[ buffer(BufferIndexUniforms) ]])
{
    return basicVertexShaderCore(in, uniforms);
}

inline float4 basicFragmentShaderCore(ColorInOut in,
                                      texture2d<half> colorMap)
{
    constexpr sampler colorSampler(mip_filter::linear,
                                   mag_filter::linear,
                                   min_filter::linear);

    half4 colorSample = colorMap.sample(colorSampler, in.texCoord.xy);

    return float4(colorSample);
}

fragment float4 basicFragmentShader(ColorInOut in [[stage_in]],
                                     constant Uniforms & uniforms [[ buffer(BufferIndexUniforms) ]],
                                     texture2d<half> colorMap [[ texture(TextureIndexColor) ]])
{
    return basicFragmentShaderCore(in, colorMap);
}

// MARK: - Legacy Compatibility Shaders

vertex ColorInOut vertexShader(Vertex in [[stage_in]],
                               constant Uniforms & uniforms [[ buffer(BufferIndexUniforms) ]])
{
    return basicVertexShaderCore(in, uniforms);
}

fragment float4 fragmentShader(ColorInOut in [[stage_in]],
                               constant Uniforms & uniforms [[ buffer(BufferIndexUniforms) ]],
                               texture2d<half> colorMap [[ texture(TextureIndexColor) ]])
{
    return basicFragmentShaderCore(in, colorMap);
}

