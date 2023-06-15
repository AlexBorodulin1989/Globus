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

    init(mtkView: MTKView) {
        guard
            let device = MTLCreateSystemDefaultDevice()
        else {
            fatalError("Fatal error: cannot create Device")
        }

        self.device = device

        mesh = Sphere(device: device,
                      radius: 1,
                      segmentsInfo: .init(uPartsNumber: 100, vPartsNumber: 100))

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
    ) {}

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

        renderEncoder.drawIndexedPrimitives(type: .point,
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
