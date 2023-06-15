//
//  GeneralShader.metal
//  Globus
//
//  Created by Aleksandr Borodulin on 11.06.2023.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float4 position [[attribute(0)]];
};

struct VertexOut {
    float4 pos [[position]];
    float pointsize[[point_size]];
};

vertex VertexOut vertex_main(const VertexIn vertexIn [[stage_in]]) {
    VertexOut result;
    result.pos = vertexIn.position;
    result.pointsize = 4;
    return result;
}

fragment float4 fragment_main() {
    return float4(1, 0, 0, 1);
}
