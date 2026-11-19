//
//  TextureQuad.metal
//  Examples
//
//  Created by Gabriele de Simone on 11/18/26.
//

#include <metal_stdlib>
using namespace metal;
#include "TexturedQuad.h"

vertex
TexturedQuadFragmentInput
TexturedQuadVertexFunction(TexturedQuadVertexInput                      input               [[ stage_in ]],
                           constant TexturedQuadVertexUniforms &        uniforms            [[ buffer(kTexturedQuadVertexUniformsBufferIndex) ]],
                           uint                                         vertexID            [[ vertex_id ]]) {
    return (TexturedQuadFragmentInput) {
        .position = uniforms.modelViewProjectionMatrix * float4(input.position * uniforms.scale, 0.0, 1.0),
        .texcoord = input.texcoord
    };
}

fragment
float4
TexturedQuadFragmentFunction(TexturedQuadFragmentInput                  input               [[ stage_in ]],
                             texture2d<float>                           texture             [[ texture(kTexturedQuadFragmentTextureIndex) ]],
                             sampler                                    sampler             [[ sampler(kTexturedQuadFragmentSamplerIndex) ]],
                             constant TexturedQuadFragmentUniforms &    uniforms            [[ buffer(kTexturedQuadFragmentUniformsBufferIndex) ]]) {
    return texture.sample(sampler, input.texcoord) * uniforms.blendColor;
}
