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

    private var mesh: MTKMesh!
    private var vertexBuffer: MTLBuffer!
    private var pipelineState: MTLRenderPipelineState!

    init(mtkView: MTKView) {
        guard
            let device = MTLCreateSystemDefaultDevice()
        else {
            fatalError("Fatal error: cannot create Device")
        }

        self.device = device

        super.init()

        guard
            let commandQueue = device.makeCommandQueue()
        else {
            fatalError("Fatal error: cannot create Queue")
        }
        self.commandQueue = commandQueue

        mtkView.device = device

        let allocator = MTKMeshBufferAllocator(device: device)
        let size: Float = 0.8
        let mdlMesh = MDLMesh(boxWithExtent: [size, size, size],
                              segments: [1, 1, 1],
                              inwardNormals: false,
                              geometryType: .triangles,
                              allocator: allocator)

        do {
            mesh = try MTKMesh(mesh: mdlMesh, device: device)
        } catch let error {
            fatalError(error.localizedDescription)
        }
        vertexBuffer = mesh.vertexBuffers[0].buffer
        self.library = device.makeDefaultLibrary()
        let vertexFunction = library?.makeFunction(name: "vertex_main")
        let fragmentFunction = library?.makeFunction(name: "fragment_main")

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        pipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(mdlMesh.vertexDescriptor)
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            fatalError(error.localizedDescription)
        }

        mtkView.clearColor = MTLClearColor(red: 1.0,
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
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        for submesh in mesh.submeshes {
            renderEncoder.drawIndexedPrimitives(type: .triangle,
                                                indexCount: submesh.indexCount,
                                                indexType: submesh.indexType,
                                                indexBuffer: submesh.indexBuffer.buffer,
                                                indexBufferOffset: submesh.indexBuffer.offset)
        }

        renderEncoder.endEncoding()

        guard let drawable = view.currentDrawable else {
            return
        }

        commandBuffer.present(drawable)

        commandBuffer.commit()
    }
}
