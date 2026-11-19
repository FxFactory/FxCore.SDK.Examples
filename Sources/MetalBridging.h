//
//  MetalBridging.h
//  Examples
//
//  Created by Gabriele de Simone on 11/18/26.
//

#ifndef MetalBridging_h
#define MetalBridging_h

#ifdef __METAL_VERSION__

#define METAL_ATTRIBUTE(x)                  [[ attribute(x) ]]
#define METAL_POSITION                      [[ position ]]
#define METAL_COLOR_ATTACHMENT(x)           [[ color(x) ]]
#define METAL_USER(x)                       [[ user(x) ]]
#define METAL_FLAT                          [[ flat ]]

using namespace metal;

#else

#define METAL_ATTRIBUTE(x)
#define METAL_POSITION
#define METAL_FLAT
#define METAL_COLOR_ATTACHMENT(x)
#define METAL_USER(x)

#import <simd/simd.h>
#import <CoreFoundation/CoreFoundation.h>

typedef simd_uint2                          uint2;
typedef simd_uint3                          uint3;
typedef simd_uint4                          uint4;
typedef simd_float2                         float2;
typedef simd_float3                         float3;
typedef simd_float4                         float4;
typedef simd_float2x2                       float2x2;
typedef simd_float3x3                       float3x3;
typedef simd_float4x4                       float4x4;
typedef simd_char2                          char2;
typedef simd_char3                          char3;
typedef simd_char4                          char4;
typedef simd_uchar2                         uchar2;
typedef simd_uchar3                         uchar3;
typedef simd_uchar4                         uchar4;

#endif

#endif /* MetalBridging_h */
