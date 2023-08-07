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
    float2 uv [[attribute(2)]];
};

vertex VertexOut vertex_main(constant Vertex *vertices [[buffer(0)]],
                             constant Camera &camera [[buffer(16)]],
                             uint id [[vertex_id]]) {
    auto vert = vertices[id];
    VertexOut result {
        .pos = camera.proj * camera.model * float4(vert.position, 1),
        .normal = vert.normal,
        .uv = vert.uv
    };
    return result;
}

fragment float4 fragment_main(VertexOut in [[stage_in]],
                              texture2d<float> baseColorTexture [[texture(MainTexture)]]) {
    constexpr sampler textureSampler;
    float3 baseColor = baseColorTexture.sample(textureSampler, in.uv).rgb;
    return float4(baseColor, 1);
}
