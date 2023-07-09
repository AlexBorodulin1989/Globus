//
//  GeneralShader.metal
//  Globus
//
//  Created by Aleksandr Borodulin on 11.06.2023.
//

#include <metal_stdlib>
using namespace metal;

struct Camera {
    float4x4 model;
    float4x4 proj;
};

struct VertexIn {
    float4 position [[attribute(0)]];
};

struct VertexOut {
    float4 pos [[position]];
};

vertex VertexOut vertex_main(const VertexIn vertexIn [[stage_in]],
                             constant Camera &camera [[buffer(16)]]) {
    VertexOut result;
    result.pos = camera.proj * camera.model * vertexIn.position;
    return result;
}

fragment float4 fragment_main() {
    return float4(1, 0, 0, 1);
}
