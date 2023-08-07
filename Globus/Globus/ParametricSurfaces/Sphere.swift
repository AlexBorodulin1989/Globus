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

class Sphere {
    var vBuffer: MTLBuffer!
    var iBuffer: MTLBuffer!

    private let radius: Float
    private let segmentsInfo: SegmentsInfo

    var vertices: [Vertex] {
        var result = [Vertex]()

        let uPart = 1 / Float(segmentsInfo.uPartsNumber)
        let vPart = 1 / Float(segmentsInfo.vPartsNumber)
        let uPartAngle = Float.pi * uPart
        let vPartAngle = 2 * Float.pi * vPart
        for u in 0...segmentsInfo.uPartsNumber {
            for v in 0...segmentsInfo.vPartsNumber {
                var vertex = Vertex()
                vertex.position = positionForParams(u: uPartAngle * Float(u), v: vPartAngle * Float(v))
                vertex.normal = vertex.position.normalized()
                vertex.uv = float2(x: vPart * Float(v), y: uPart * Float(u))
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
                result.append(index + UInt16(segmentsInfo.vPartsNumber + 1))
                result.append(index + 1)
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
         radius: Float,
         segmentsInfo: SegmentsInfo) {
        self.radius = radius
        self.segmentsInfo = segmentsInfo

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

    func positionForParams(u: Float, v: Float) -> float3 {
        let x = radius * sin(u) * cos(v)
        let y = radius * cos(u)
        let z = radius * sin(u) * sin(v)

        return [x, y, z]
    }
}
