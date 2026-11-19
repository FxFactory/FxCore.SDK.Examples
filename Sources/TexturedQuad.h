//
//  TexturedQuad.h
//  Examples
//
//  Created by Gabriele de Simone on 11/18/26.
//

#ifndef TexturedQuad_h
#define TexturedQuad_h
#include "MetalBridging.h"
    
enum {
    kTexturedQuadVertexGeometryBufferIndex = 0,
    kTexturedQuadVertexPositionAttribute = 0,
    kTexturedQuadVertexTexcoordAttribute = 1,
    kTexturedQuadVertexUniformsBufferIndex = 1,
    kTexturedQuadFragmentUniformsBufferIndex = 0,
    kTexturedQuadFragmentTextureIndex = 0,
    kTexturedQuadFragmentSamplerIndex = 0,
};

typedef struct {
    float4x4     modelViewProjectionMatrix;
    float4x4     modelViewMatrix;
    float2       scale;
} TexturedQuadVertexUniforms;

typedef struct {
    float4       blendColor;
} TexturedQuadFragmentUniforms;

typedef struct {
    float2       position        METAL_ATTRIBUTE(kTexturedQuadVertexPositionAttribute);
    float2       texcoord        METAL_ATTRIBUTE(kTexturedQuadVertexTexcoordAttribute);
} TexturedQuadVertexInput;

typedef struct {
    float4       position        METAL_POSITION;
    float2       texcoord;
} TexturedQuadFragmentInput;

#endif /* TexturedQuad_h */
