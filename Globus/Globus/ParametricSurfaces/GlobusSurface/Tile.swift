//
//  Tile.swift
//  Globus
//
//  Created by Aleksandr Borodulin on 07.09.2023.
//

import Foundation
import MetalKit

class Tile {
    let bottomRightVert: AccurateVertex
    let bottomLeftVert: AccurateVertex
    let topRightVert: AccurateVertex
    let topLeftVert: AccurateVertex

    private let radius: Double

    private var timer: Float = 0

    var vBuffer: MTLBuffer!
    var iBuffer: MTLBuffer!

    var vertices: [Vertex] {
        var result = [Vertex]()

        [bottomRightVert,
         bottomLeftVert,
         topRightVert,
         topLeftVert].forEach { vert in
            let position = positionForParams(u: vert.u, v: vert.v)
            let vertex = Vertex(position: positionForParams(u: vert.u, v: vert.v),
                                normal: position.normalized(),
                                uv: float2(Float(vert.texCoord.x),
                                           Float(vert.texCoord.y)))
            result.append(vertex)
        }

        return result
    }

    var indices: [UInt16] {
        return [0, 1, 2, 2, 1, 3]
    }

    init(device: MTLDevice,
         bottomRightVert: AccurateVertex,
         bottomLeftVert: AccurateVertex,
         topRightVert: AccurateVertex,
         topLeftVert: AccurateVertex,
         radius: Double) {
        self.bottomRightVert = bottomRightVert
        self.bottomLeftVert = bottomLeftVert
        self.topRightVert = topRightVert
        self.topLeftVert = topLeftVert
        self.radius = radius

        var vertices = self.vertices
        guard let vertexBuffer = device.makeBuffer(bytes: &vertices,
                                                   length: MemoryLayout<Vertex>.stride * vertices.count,
                                                   options: [])
        else {
            fatalError("Unable to create quad vertex buffer")
        }
        self.vBuffer = vertexBuffer

        var indices = self.indices
        guard let indexBuffer = device.makeBuffer(bytes: &indices,
                                                  length: MemoryLayout<UInt16>.stride * indices.count)
        else {
            fatalError("Unable to create quad index buffer")
        }

        self.iBuffer = indexBuffer
    }

    func positionForParams(u: Double, v: Double) -> float3 {
        let x = radius * sin(u) * cos(v)
        let y = radius * cos(u)
        let z = radius * sin(u) * sin(v)

        return [Float(x), Float(y), Float(z)]
    }
}

extension Tile {
    func draw(engine: RenderEngine,
              encoder: MTLRenderCommandEncoder,
              aspectRatio: Float) {
        timer += 1
        
        let far: Float = 2
        let near: Float = 1

        let interval = far - near

        let a = far / interval
        let b = -far * near / interval

        let projMatrix: matrix_float4x4

        if aspectRatio > 1 { // width > height
            projMatrix = matrix_float4x4([
                SIMD4<Float>(2,             0, 0, 0),
                SIMD4<Float>(0, 2/aspectRatio, 0, 0),
                SIMD4<Float>(0,             0, a, 1),
                SIMD4<Float>(0,             0, b, 0)
            ])
        } else {
            projMatrix = matrix_float4x4([
                SIMD4<Float>(2 * aspectRatio, 0, 0, 0),
                SIMD4<Float>(              0, 2, 0, 0),
                SIMD4<Float>(              0, 0, a, 1),
                SIMD4<Float>(              0, 0, b, 0)
            ])
        }

        let translation = float4x4(translation: [0, 0, -2])
        let rotation = float4x4(rotation: [timer.degreesToRadians, timer.degreesToRadians, 0])
        let model = translation.inverse * rotation
        var cam = Camera(model: model, proj: projMatrix)

        encoder.setVertexBuffer(vBuffer,
                                offset: 0,
                                index: 0)

        encoder.setVertexBytes(&cam,
                               length: MemoryLayout<Camera>.stride,
                               index: 16)

        encoder.drawIndexedPrimitives(type: .triangle,
                                      indexCount: indices.count,
                                      indexType: .uint16,
                                      indexBuffer: iBuffer,
                                      indexBufferOffset: 0)
    }
}
