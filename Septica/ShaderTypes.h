//
//  ShaderTypes.h
//  Septica
//
//  Enhanced shader types for Romanian Septica card game Metal rendering
//  Supports advanced card effects, animations, and cultural visual elements
//

//
//  Header containing types and enum constants shared between Metal shaders and Swift/ObjC source
//
#ifndef ShaderTypes_h
#define ShaderTypes_h

#ifdef __METAL_VERSION__
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
typedef metal::int32_t EnumBackingType;
#else
#import <Foundation/Foundation.h>
typedef NSInteger EnumBackingType;
#endif

#include <simd/simd.h>

// MARK: - Buffer Indices

typedef NS_ENUM(EnumBackingType, BufferIndex)
{
    BufferIndexMeshPositions = 0,
    BufferIndexMeshGenerics  = 1,
    BufferIndexUniforms      = 2,
    BufferIndexCardUniforms  = 3,
    BufferIndexParticleData  = 4
};

// MARK: - Vertex Attributes

typedef NS_ENUM(EnumBackingType, VertexAttribute)
{
    VertexAttributePosition  = 0,
    VertexAttributeTexcoord  = 1,
    VertexAttributeNormal    = 2,
    VertexAttributeColor     = 3
};

// MARK: - Texture Indices

typedef NS_ENUM(EnumBackingType, TextureIndex)
{
    TextureIndexColor        = 0,
    TextureIndexCardFace     = 1,
    TextureIndexCardBack     = 2,
    TextureIndexNormal       = 3,
    TextureIndexParticle     = 4
};

// MARK: - Shader Types

typedef NS_ENUM(EnumBackingType, ShaderType)
{
    ShaderTypeBasic          = 0,
    ShaderTypeCard           = 1,
    ShaderTypeCardHighlight  = 2,
    ShaderTypeCardFlip       = 3,
    ShaderTypeParticle       = 4,
    ShaderTypeRomanianPattern = 5
};

// MARK: - Animation States

typedef NS_ENUM(EnumBackingType, CardAnimationState)
{
    CardAnimationStateIdle      = 0,
    CardAnimationStateSelected  = 1,
    CardAnimationStateFlipping  = 2,
    CardAnimationStateFloating  = 3,
    CardAnimationStateCelebrating = 4
};

// MARK: - Uniform Structures

typedef struct
{
    matrix_float4x4 projectionMatrix;
    matrix_float4x4 modelViewMatrix;
    float time;
    float deltaTime;
    simd_float2 screenSize;
    float animationProgress;
} Uniforms;

typedef struct
{
    simd_float4 highlightColor;
    simd_float4 edgeGlowColor;
    float selectionIntensity;
    float flipAngle;
    float glowIntensity;
    CardAnimationState animationState;
    simd_float2 cardSize;
    float cornerRadius;
} CardUniforms;

typedef struct
{
    simd_float3 position;
    simd_float3 velocity;
    simd_float4 color;
    float life;
    float size;
    float rotation;
    float rotationSpeed;
} ParticleData;

// MARK: - Romanian Cultural Constants

#define ROMANIAN_GOLD_R 1.0f
#define ROMANIAN_GOLD_G 0.84f
#define ROMANIAN_GOLD_B 0.0f

#define ROMANIAN_RED_R 0.8f
#define ROMANIAN_RED_G 0.2f
#define ROMANIAN_RED_B 0.2f

#define ROMANIAN_BLUE_R 0.2f
#define ROMANIAN_BLUE_G 0.4f
#define ROMANIAN_BLUE_B 0.8f

// MARK: - Performance Constants

#define MAX_PARTICLES 1000
#define CARD_CORNER_RADIUS 0.1f
#define DEFAULT_GLOW_INTENSITY 0.3f
#define ANIMATION_SPEED_MULTIPLIER 1.0f

// MARK: - Quality Settings

typedef NS_ENUM(EnumBackingType, RenderQuality)
{
    RenderQualityLow    = 0,  // Basic shaders, minimal effects
    RenderQualityMedium = 1,  // Standard card effects
    RenderQualityHigh   = 2,  // Full effects with particles
    RenderQualityUltra  = 3   // Maximum visual quality
};

#endif /* ShaderTypes_h */

