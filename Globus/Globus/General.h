//
//  General.h
//  Globus
//
//  Created by Aleksandr Borodulin on 04.08.2023.
//

#ifndef General_h
#define General_h

#import <simd/simd.h>

typedef struct {
    matrix_float4x4 model;
    matrix_float4x4 proj;
} Camera;

typedef struct {
    vector_float3 position;
    vector_float3 normal;
} Vertex;

#endif /* General_h */
