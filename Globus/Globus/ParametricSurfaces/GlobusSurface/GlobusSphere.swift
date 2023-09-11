//
//  Sphere.swift
//  Globus
//
//  Created by Aleksandr Borodulin on 15.06.2023.
//

import Foundation
import MetalKit

struct SegmentsInfo {
    let uPartsNumber: Int
    let vPartsNumber: Int
}

struct AccurateVertex {
    let u: Double
    let v: Double
}

class GlobusSphere {

    private let segmentsInfo: SegmentsInfo

    private let limitAngle: Double = 1.48442223321

    var rootTiles = [Tile]()

    private var timer: Float = 0

    var vertices: [AccurateVertex] {
        var result = [AccurateVertex]()

        let uPart: Double = 1.0 / Double(segmentsInfo.uPartsNumber)
        let vPart: Double = 1.0 / Double(segmentsInfo.vPartsNumber)
        let uPartAngle: Double = limitAngle * 2.0 * uPart
        let vPartAngle: Double = 2.0 * Double.pi * vPart
        let startUAngle: Double = (Double.pi - limitAngle * 2) * 0.5

        for u in 0...segmentsInfo.uPartsNumber {
            for v in 0...segmentsInfo.vPartsNumber {
                var vertex = AccurateVertex(u: uPartAngle * Double(u) + startUAngle,
                                            v: vPartAngle * Double(v))
                //vertex.normal = vertex.position.normalized()
                result.append(vertex)
            }
        }

        return result
    }

    var indices: [UInt16] {
        var result = [UInt16]()
        var index: UInt16 = 0
        for _ in 0..<segmentsInfo.uPartsNumber {
            for _ in 0..<segmentsInfo.vPartsNumber {
                result.append(index)
                result.append(index + 1)
                result.append(index + UInt16(segmentsInfo.vPartsNumber + 1))
                result.append(index + UInt16(segmentsInfo.vPartsNumber + 1) + 1)
                index += 1
            }
            index += 1
        }

        return result
    }

    static var layout: MTLVertexDescriptor {
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        var stride = MemoryLayout<float3>.stride

        vertexDescriptor.attributes[1].format = .float3
        vertexDescriptor.attributes[1].offset = stride
        vertexDescriptor.attributes[1].bufferIndex = 0
        stride += MemoryLayout<float3>.stride

        vertexDescriptor.attributes[2].format = .float2
        vertexDescriptor.attributes[2].offset = stride
        vertexDescriptor.attributes[2].bufferIndex = 0
        stride += MemoryLayout<float2>.stride

        vertexDescriptor.layouts[0].stride = stride
        return vertexDescriptor
    }

    init(device: MTLDevice,
         radius: Double,
         segmentsInfo: SegmentsInfo) {
        self.segmentsInfo = segmentsInfo

        let vertices = self.vertices
        let indices = self.indices

        let tilesCount = indices.count / 4

        for tileIndex in 0..<tilesCount {
            let startIndex = tileIndex * 4
            let x = tileIndex % segmentsInfo.uPartsNumber
            let y = tileIndex / segmentsInfo.vPartsNumber

            let tile = Tile(device: device,
                            bottomRightVert: vertices[Int(indices[startIndex])],
                            bottomLeftVert: vertices[Int(indices[startIndex + 1])],
                            topRightVert: vertices[Int(indices[startIndex + 2])],
                            topLeftVert: vertices[Int(indices[startIndex + 3])],
                            radius: radius,
                            zoom: 3,
                            x: x,
                            y: y)

            rootTiles.append(tile)
        }
    }
}

extension GlobusSphere {
    func draw(engine: RenderEngine,
              encoder: MTLRenderCommandEncoder,
              aspectRatio: Float) {
        timer += 1
        
        let far: Float = 2
        let near: Float = 1

        let interval = far - near
        let invInterval = 1 / interval

        let a = far * invInterval
        let b = -far * near * invInterval

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

        encoder.setVertexBytes(&cam,
                               length: MemoryLayout<Camera>.stride,
                               index: 16)
        
        rootTiles.forEach { tile in
            tile.draw(engine: engine,
                      encoder: encoder,
                      aspectRatio: aspectRatio)
        }
    }
}
