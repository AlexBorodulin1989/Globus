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
};

vertex VertexOut vertex_main(constant Vertex *vertices [[buffer(0)]],
                             constant Camera &camera [[buffer(16)]],
                             uint id [[vertex_id]]) {
    VertexOut result;
    result.pos = camera.proj * camera.model * vertices[id].position;
    return result;
}

fragment float4 fragment_main() {
    return float4(1, 0, 0, 1);
}
