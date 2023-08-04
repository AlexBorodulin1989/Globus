//
//  RenderEngine.swift
//  Globus
//
//  Created by Aleksandr Borodulin on 11.06.2023.
//

import MetalKit

class RenderEngine: NSObject {
    private var device: MTLDevice
    private var commandQueue: MTLCommandQueue!

    private var library: MTLLibrary!

    private var mesh: Sphere!
    private var pipelineState: MTLRenderPipelineState!

    var timer: Float = 0

    private(set) var aspectRatio: Float = 1

    init(mtkView: MTKView) {
        guard
            let device = MTLCreateSystemDefaultDevice()
        else {
            fatalError("Fatal error: cannot create Device")
        }

        self.device = device

        mesh = Sphere(device: device,
                      radius: 0.5,
                      segmentsInfo: .init(uPartsNumber: 8, vPartsNumber: 8))

        super.init()

        guard
            let commandQueue = device.makeCommandQueue()
        else {
            fatalError("Fatal error: cannot create Queue")
        }
        self.commandQueue = commandQueue

        mtkView.device = device

        self.library = device.makeDefaultLibrary()
        let vertexFunction = library?.makeFunction(name: "vertex_main")
        let fragmentFunction = library?.makeFunction(name: "fragment_main")

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        pipelineDescriptor.vertexDescriptor = Sphere.layout
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            fatalError(error.localizedDescription)
        }

        mtkView.clearColor = MTLClearColor(red: 0.5,
                                             green: 0.5,
                                             blue: 0.5,
                                             alpha: 1.0)

        mtkView.delegate = self
    }
}

extension RenderEngine: MTKViewDelegate {
    func mtkView(_ view: MTKView,
                 drawableSizeWillChange size: CGSize
    ) {
        let width = size.width > 1 ? size.width : 1
        aspectRatio = Float(size.height / width)
    }

    func draw(in view: MTKView) {
        guard
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let descriptor = view.currentRenderPassDescriptor,
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }

        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(mesh.vBuffer,
                                      offset: 0,
                                      index: 0)

        renderEncoder.setTriangleFillMode(.lines)

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

        let translation = float4x4(translation: [0, 0, -1])
        let rotation = float4x4(rotation: [0, timer.degreesToRadians, 0])
        let model = translation.inverse * translation.inverse * rotation * translation
        var cam = Camera(model: model, proj: projMatrix)

        renderEncoder.setVertexBytes(&cam,
                                     length: MemoryLayout<Camera>.stride,
                                     index: 16)

        renderEncoder.drawIndexedPrimitives(type: .triangle,
                                            indexCount: mesh.indices.count,
                                            indexType: .uint16,
                                            indexBuffer: mesh.iBuffer,
                                            indexBufferOffset: 0)

        renderEncoder.endEncoding()

        guard let drawable = view.currentDrawable else {
            return
        }

        commandBuffer.present(drawable)

        commandBuffer.commit()
    }
}
