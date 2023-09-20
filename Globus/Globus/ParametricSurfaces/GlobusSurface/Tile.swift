//
//  Tile.swift
//  Globus
//
//  Created by Aleksandr Borodulin on 07.09.2023.
//

import Foundation
import MetalKit

class Tile {
    private let bottomRightVert: AccurateVertex
    private let bottomLeftVert: AccurateVertex
    private let topRightVert: AccurateVertex
    private let topLeftVert: AccurateVertex

    private let radius: Double
    private let zoom: Int
    private let x: Int
    private let y: Int

    var vBuffer: MTLBuffer!
    var iBuffer: MTLBuffer!

    private let tileTexture: MTLTexture?

    lazy var indices: [UInt16] = {
        return [0, 1, 2, 2, 1, 3]
    }()

    init(device: MTLDevice,
         bottomRightVert: AccurateVertex,
         bottomLeftVert: AccurateVertex,
         topRightVert: AccurateVertex,
         topLeftVert: AccurateVertex,
         radius: Double,
         zoom: Int,
         x: Int,
         y: Int,
         matrix: double4x4) {
        self.bottomRightVert = bottomRightVert
        self.bottomLeftVert = bottomLeftVert
        self.topRightVert = topRightVert
        self.topLeftVert = topLeftVert
        self.radius = radius
        self.zoom = zoom
        self.x = x
        self.y = y

        tileTexture = TextureController.texture(filename: "\(zoom)-\(x)-\(y)_rect.png", device: device)

        var verts = vertices(matrix: matrix)

        guard let vertexBuffer = device.makeBuffer(bytes: &verts,
                                                   length: MemoryLayout<Vertex>.stride * verts.count,
                                                   options: [])
        else {
            fatalError("Unable to create quad vertex buffer")
        }
        self.vBuffer = vertexBuffer

        guard let indexBuffer = device.makeBuffer(bytes: &indices,
                                                  length: MemoryLayout<UInt16>.stride * indices.count)
        else {
            fatalError("Unable to create quad index buffer")
        }

        self.iBuffer = indexBuffer
    }

    func vertices(matrix: double4x4) -> [Vertex] {
        var result = [Vertex]()

        let texCoordinates = [float2(0.0, 1.0),
                              float2(1.0, 1.0),
                              float2(0.0, 0.0),
                              float2(1.0, 0.0)]

        var texIndex = -1

        [bottomRightVert,
         bottomLeftVert,
         topRightVert,
         topLeftVert].forEach { vert in
            texIndex += 1
            let position = positionForParams(u: vert.u, v: vert.v)
            let transformedPosition = matrix * position
            let floatPosition: float3 = [Float(transformedPosition.x),
                                           Float(transformedPosition.y),
                                           Float(transformedPosition.z)]
            let vertex = Vertex(position: floatPosition,
                                normal: floatPosition.normalized(),
                                uv: texCoordinates[texIndex])
            result.append(vertex)
        }

        return result
    }

    func positionForParams(u: Double, v: Double) -> double3 {
        let x = radius * sin(u) * cos(v)
        let y = radius * cos(u)
        let z = radius * sin(u) * sin(v)

        return [x, y, z]
    }
}

extension Tile {
    func draw(engine: RenderEngine,
              encoder: MTLRenderCommandEncoder) {
        if let tileTexture {
            encoder.setFragmentTexture(tileTexture,
                                       index: MainTexture.index)
        }

        encoder.setVertexBuffer(vBuffer,
                                offset: 0,
                                index: 0)

        encoder.drawIndexedPrimitives(type: .triangle,
                                      indexCount: indices.count,
                                      indexType: .uint16,
                                      indexBuffer: iBuffer,
                                      indexBufferOffset: 0)
    }
}
