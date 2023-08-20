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

    private var mesh: GlobusSphere!
    private var pipelineState: MTLRenderPipelineState!

    private let texture: MTLTexture?

    var timer: Float = 0

    private(set) var aspectRatio: Float = 1

    private var depthState: MTLDepthStencilState!

    init(mtkView: MTKView) {
        guard
            let device = MTLCreateSystemDefaultDevice()
        else {
            fatalError("Fatal error: cannot create Device")
        }

        self.device = device

        mesh = GlobusSphere(device: device,
                            radius: 0.5,
                            segmentsInfo: .init(uPartsNumber: 16, vPartsNumber: 16))

        texture = TextureController.texture(filename: "map_equirectangular.png", device: device)

        super.init()

        guard
            let depthState = createDepthState()
        else {
            fatalError("Fatal error: cannot create depth state")
        }
        self.depthState = depthState

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
        pipelineDescriptor.vertexDescriptor = GlobusSphere.layout
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            fatalError(error.localizedDescription)
        }

        mtkView.clearColor = MTLClearColor(red: 0.5,
                                             green: 0.5,
                                             blue: 0.5,
                                             alpha: 1.0)

        mtkView.depthStencilPixelFormat = .depth32Float

        mtkView.delegate = self
    }
}

extension RenderEngine {
    func createDepthState() -> MTLDepthStencilState? {
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.depthCompareFunction = .less
        descriptor.isDepthWriteEnabled = true
        return device.makeDepthStencilState(descriptor: descriptor)
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

        renderEncoder.setDepthStencilState(depthState)

        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(mesh.vBuffer,
                                      offset: 0,
                                      index: 0)

        if let texture {
            renderEncoder.setFragmentTexture(texture,
                                             index: MainTexture.index)
        }

        //renderEncoder.setTriangleFillMode(.lines)

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
