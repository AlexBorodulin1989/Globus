//
//  GeneralShader.metal
//  Globus
//
//  Created by Aleksandr Borodulin on 11.06.2023.
//

#include <metal_stdlib>
#import "../General.h"
using namespace metal;

struct VertexOut {
    float4 pos [[position]];
    float3 normal [[attribute(1)]];
};

vertex VertexOut vertex_main(constant Vertex *vertices [[buffer(0)]],
                             constant Camera &camera [[buffer(16)]],
                             uint id [[vertex_id]]) {
    auto vert = vertices[id];
    VertexOut result;
    result.pos = camera.proj * camera.model * float4(vert.position, 1);
    result.normal = vert.normal;
    return result;
}

fragment float4 fragment_main(VertexOut in [[stage_in]]) {
    return float4(in.normal, 1);
}
