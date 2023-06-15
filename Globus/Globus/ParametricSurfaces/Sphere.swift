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

    var vertices: [Float] {
        var result = [Float]()

        let uPart = Float.pi / Float(segmentsInfo.uPartsNumber)
        let vPart = 2 * Float.pi / Float(segmentsInfo.vPartsNumber)
        for u in 0..<segmentsInfo.uPartsNumber {
            for v in 0..<segmentsInfo.vPartsNumber {
                result.append(contentsOf: positionForParams(u: uPart * Float(u), v: vPart * Float(v)))
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
                index += 1
            }
        }

        return result
    }

    static var layout: MTLVertexDescriptor {
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0

        let stride = MemoryLayout<Float>.stride * 3
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
                                                   length: MemoryLayout<Float>.stride * vertices.count,
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

    func positionForParams(u: Float, v: Float) -> [Float] {
        let x = radius * sin(u) * cos(v)
        let y = radius * cos(u)
        let z = radius * sin(u) * sin(v)

        if z < 0 {
            print([x, y, z])
        }


        return [x, y, z + 1]
    }
}
