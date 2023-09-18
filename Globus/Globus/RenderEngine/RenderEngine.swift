//
//  RenderEngine.swift
//  Globus
//
//  Created by Aleksandr Borodulin on 11.06.2023.
//

import MetalKit

enum RenderInfo {
    static var fps: Int = 0
}

class RenderEngine: NSObject {
    private var device: MTLDevice
    private var commandQueue: MTLCommandQueue!

    private var library: MTLLibrary!

    private var mesh: GlobusSphere!
    private var pipelineState: MTLRenderPipelineState!

    private(set) var aspectRatio: Float = 1

    private var depthState: MTLDepthStencilState!

    private var fps = 0

    private var lastTimeInterval = CFAbsoluteTimeGetCurrent()

    private var timeElapsed: Double = 0

    init(mtkView: MTKView) {
        guard
            let device = MTLCreateSystemDefaultDevice()
        else {
            fatalError("Fatal error: cannot create Device")
        }

        self.device = device

        mesh = GlobusSphere(device: device,
                            segmentsInfo: .init(uPartsNumber: 8, vPartsNumber: 8))

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

        fpsCalculator()

        renderEncoder.setDepthStencilState(depthState)

        renderEncoder.setRenderPipelineState(pipelineState)

        mesh.draw(engine: self,
                  encoder: renderEncoder,
                  aspectRatio: aspectRatio)

        renderEncoder.endEncoding()

        guard let drawable = view.currentDrawable else {
            return
        }

        commandBuffer.present(drawable)

        commandBuffer.commit()
    }

    func fpsCalculator() {
        let timeInterval = CFAbsoluteTimeGetCurrent()

        let timeDif = timeInterval - lastTimeInterval

        timeElapsed += timeDif

        if timeElapsed > 1 {
            timeElapsed = timeElapsed - 1
            RenderInfo.fps = fps
            fps = 0
        } else {
            fps += 1
        }

        lastTimeInterval = timeInterval
    }
}
