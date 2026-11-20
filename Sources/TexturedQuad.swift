//
//  TexturedQuad.swift
//  Examples
//
//  Created by Gabriele de Simone on 11/18/26.
//

import FxCore
import Metal

/// Draws a textured quad in the output.
///
/// - Note: Plug-Ins are guaranteed by the FxCore runtime that the Metal device
///   won't ever change during their lifetime. If the user happens to have more than
///   one GPU and switches rendering from one to another, FxCore creates a new instance
///   of all plug-ins.
///   This is what allows the plug-in to create an cache data structures linked to
///   the Metal device accessible at execution.
///
class TexturedQuadPlugIn : BasePlugIn {
    
    /// This plug-in is designed to render something to the current 3D environment, as
    /// such it must be declared a consumer.
    
    override class var features: FxCorePlugInFeature { [.consumer] }
    
    /// Remember that every plug-in must have its own unique identifier. There are two
    /// strategies... use reverse-domain syntax, e.g. "com.mycompany.myproduct.myplugin"
    /// or `uuidgen` a new UUID in the Terminal.
    
    override class var identifier: String { "1D4AF729-6CEA-4033-BB7A-C3ADCD4E38FB" }
    override class var symbols: [String] { ["photo.artframe"] }
    override class var tag: FxCoreUITag { .consumer }
    
    /// Until the better Swift APIs are part of the SDK, working with ports involves
    /// dictionaries and lots of key-value pairs to specify port options.
    /// Note below that it is OK to leave Swift enums as such... FxCore will unbox
    /// these `RawRepresentable` enums behind the scenes and interpret them as
    /// equivalent numeric values wrapped in `NSNumber`.
    
    @NSManaged var inputImage: FxCoreImage?
    @NSManaged var inputBlendColor: FxCoreColor?
    @NSManaged var inputScaleX: Double
    @NSManaged var inputScaleY: Double
    @NSManaged var inputMipmapped: Bool
    @NSManaged var inputAnisotropy: UInt
    @NSManaged var inputDepthTest: Bool
    @NSManaged var inputDepthFunction: MTLCompareFunction
    
    override init() {
        super.init()
        add([[.key: #keyPath(inputImage), .type: FxCorePortType.image],
             [.key: #keyPath(inputBlendColor), .type: FxCorePortType.color, .default: FxCoreColor.white],
             [.key: #keyPath(inputScaleX), .type: FxCorePortType.double, .default: 1.0, .min: 0.0, .sliderMin: 0.0, .sliderMax: 2.0],
             [.key: #keyPath(inputScaleY), .type: FxCorePortType.double, .default: 1.0, .min: 0.0, .sliderMin: 0.0, .sliderMax: 2.0],
             [.key: #keyPath(inputMipmapped), .type: FxCorePortType.boolean],
             [.key: #keyPath(inputAnisotropy), .type: FxCorePortType.unsignedInteger, .default: 1,
              .menu: ["1 sample", "2 samples", "4 samples", "8 samples", "16 samples"],
              .alternates: [1: "1", 2: "2", 4: "4", 8: "8", 16: "16"],
              .values: [1, 2, 4, 8, 16]],
             [.key: #keyPath(inputDepthTest), .type: FxCorePortType.boolean, .default: true],
             [.key: #keyPath(inputDepthFunction), .type: FxCorePortType.unsignedInteger, .default: MTLCompareFunction.lessEqual,
              .menu: ["Less than", "Less than or equal", "Greater than", "Greater than or equal", "Equal", "Not equal"],
              .values: [MTLCompareFunction.less,
                        MTLCompareFunction.lessEqual,
                        MTLCompareFunction.greater,
                        MTLCompareFunction.greaterEqual,
                        MTLCompareFunction.equal,
                        MTLCompareFunction.notEqual],
              .alternates: [MTLCompareFunction.less: "<",
                            MTLCompareFunction.lessEqual: "≤",
                            MTLCompareFunction.greater: ">",
                            MTLCompareFunction.greaterEqual: "≥",
                            MTLCompareFunction.equal: "=",
                            MTLCompareFunction.notEqual: "≠"]
             ]])
    }
    
    private lazy var vertexDescriptor: MTLVertexDescriptor = {
        let vertexDescriptor = MTLVertexDescriptor()
        
        vertexDescriptor.attributes[kTexturedQuadVertexPositionAttribute].format = .float2
        vertexDescriptor.attributes[kTexturedQuadVertexPositionAttribute].offset = 0
        vertexDescriptor.attributes[kTexturedQuadVertexPositionAttribute].bufferIndex = kTexturedQuadVertexGeometryBufferIndex
        
        vertexDescriptor.attributes[kTexturedQuadVertexTexcoordAttribute].format = .float2
        vertexDescriptor.attributes[kTexturedQuadVertexTexcoordAttribute].offset = MemoryLayout<simd_float2>.stride
        vertexDescriptor.attributes[kTexturedQuadVertexTexcoordAttribute].bufferIndex = kTexturedQuadVertexGeometryBufferIndex
        
        vertexDescriptor.layouts[kTexturedQuadVertexGeometryBufferIndex].stride = MemoryLayout<TexturedQuadVertexInput>.stride
        vertexDescriptor.layouts[kTexturedQuadVertexGeometryBufferIndex].stepRate = 1
        vertexDescriptor.layouts[kTexturedQuadVertexGeometryBufferIndex].stepFunction = .perVertex
        
        return vertexDescriptor
    }()

    /// Lazily allocate the vertex geometry buffer, 6 vertices to define 2 triangles to
    /// draw our quad.
    ///
    /// - Warning: The same number of vertices (6) must then be passed as an argumen to
    ///   `drawPrimitives(type:vertexStart:vertexCount:instanceCount:)`.
    ///
    /// - Note: We create the geometry buffer once on the current device... so what if the
    ///   plug-in is asked to execute on a different `MTLDevice`? Trick question... that
    ///   cannot happen. Plug-Ins are guaranteed by the FxCore runtime that the Metal device
    ///   won't ever change during their lifetime. If the user happens to have more than
    ///   one GPU and switches rendering from one to another, FxCore creates a new instance
    ///   of all plug-ins.
    ///
    private lazy var vertexGeometryBuffer = device.makeBuffer(bytes: [TexturedQuadVertexInput(position: float2(-1.0, -1.0), texcoord: float2(0.0, 1.0)),
                                                                      TexturedQuadVertexInput(position: float2( 1.0,  1.0), texcoord: float2(1.0, 0.0)),
                                                                      TexturedQuadVertexInput(position: float2( 1.0, -1.0), texcoord: float2(1.0, 1.0)),
                                                                      TexturedQuadVertexInput(position: float2(-1.0, -1.0), texcoord: float2(0.0, 1.0)),
                                                                      TexturedQuadVertexInput(position: float2(-1.0,  1.0), texcoord: float2(0.0, 0.0)),
                                                                      TexturedQuadVertexInput(position: float2( 1.0,  1.0), texcoord: float2(1.0, 0.0))],
                                                              length: MemoryLayout<TexturedQuadVertexInput>.stride * 6,
                                                              options: .cpuCacheModeWriteCombined)!
    
    /// Let FxCore know this plug-in can only execute inside a 3D environment.
    ///
    override func canExecute(_ scene: any FxCoreScene) -> Bool {
        scene is FxCore3DScene
    }
    
    override func execute() throws {
        
        /// If no input image has been specified, there is nothing for this plug-in to render.
        /// Similarly, if either scale factor is zero, there is nothing to render.
        
        guard let image = inputImage,
              case let scaleX = inputScaleX, scaleX > 0,
              case let scaleY = inputScaleY, scaleY > 0 else { return }
        
        /// Only images with finite, representable dimensions can be represented as a texture
        /// and rendered. If the user passes in an empty or infinite image, throwing `.emptyOrInfiniteImage`
        /// will flag this as an error in the graph and print a message to the debugging Console.
        
        guard image.isRepresentable else { throw error(.emptyOrInfiniteImage) }
        
        /// Our `canExecute(scene:)` override ensures that the only scene we are ever going to execute
        /// in, is `FxCore3DScene`
        
        let scene = scene as! FxCore3DScene
        
        /// Should the image be too large to be represented by a Metal texture, throwing `.unexecutable`
        /// will flag this node as having failed execution, setting it to red and printing a message
        /// to the debugging Console.
        ///
        /// The default library should be present in the plug-in bundle as a side effect of compiling
        /// all .metal files in the target.
        
        guard let texture = image.texture(commandBuffer: commandBuffer,
                                          context: ciContext,
                                          colorSpace: scene.colorSpace,
                                          depth: .native,
                                          count: .native,
                                          mipmapped: inputMipmapped),
              let library = defaultLibrary,
              let pipelineState = renderPipelineState(library: library,
                                                      vertexDescriptor: vertexDescriptor,
                                                      vertexFunction: "TexturedQuadVertexFunction",
                                                      fragmentFunction: "TexturedQuadFragmentFunction",
                                                      sampleCount: scene.sampleCount,
                                                      colorPixelFormats: scene.colorPixelFormats,
                                                      depthPixelFormat: scene.depthPixelFormat,
                                                      stencilPixelFormat: scene.stencilPixelFormat,
                                                      blending: true,
                                                      rgbSource: .one,
                                                      rgbDestination: .oneMinusSourceAlpha,
                                                      rgbOperation: .add,
                                                      alphaSource: .one,
                                                      alphaDestination: .oneMinusSourceAlpha,
                                                      alphaOperation: .add,
                                                      writeMask: .all),
              let depthStencilState = depthStencilState(depthTest: true, function: inputDepthFunction),
              let samplerState = samplerState(normalizedCoordinates: true,
                                              minFilter: .linear,
                                              magFilter: .linear,
                                              mipFilter: .notMipmapped,
                                              maxAnisotropy: inputAnisotropy,
                                              sAddressMode: .clampToEdge,
                                              tAddressMode: .clampToEdge,
                                              rAddressMode: .clampToEdge),
              let blendColor = inputBlendColor?.convertingToColorSpace(scene.colorSpace, intent: .defaultIntent),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: scene.renderPassDescriptor) else { throw error(.unexecutable) }
        
        let modelViewMatrix = scene.viewMatrix * scene.modelMatrix
        let modelViewProjectionMatrix = scene.projectionMatrix * modelViewMatrix
        var vertexUniforms = TexturedQuadVertexUniforms(modelViewProjectionMatrix: modelViewProjectionMatrix,
                                                        modelViewMatrix: modelViewMatrix,
                                                        scale: float2(Float(scaleX) * (Float(texture.width) / Float(scene.pixelsWide)),
                                                                      Float(scaleY) * (Float(texture.height) / Float(scene.pixelsWide))))
        
        var fragmentUniforms = TexturedQuadFragmentUniforms(blendColor: float4(Float(blendColor.red * blendColor.alpha),
                                                                               Float(blendColor.green * blendColor.alpha),
                                                                               Float(blendColor.blue * blendColor.alpha),
                                                                               Float(blendColor.alpha)))
        
        let vertexUniformsBuffer = device.makeBuffer(bytes: &vertexUniforms, length: MemoryLayout<TexturedQuadVertexUniforms>.size, options: .storageModeShared)
        let fragmentUniformsBuffer = device.makeBuffer(bytes: &fragmentUniforms, length: MemoryLayout<TexturedQuadFragmentUniforms>.size, options: .storageModeShared)
        
        encoder.setRenderPipelineState(pipelineState)
        encoder.setBlendColor(red: 1, green: 1, blue: 1, alpha: 1)
        encoder.setViewport(viewport)
        encoder.setDepthStencilState(depthStencilState)
        encoder.setFrontFacing(.clockwise)
        encoder.setCullMode(.none)
        encoder.setDepthClipMode(.clip)
        encoder.setTriangleFillMode(.fill)
        encoder.setVertexBuffer(vertexGeometryBuffer, offset: 0, index: kTexturedQuadVertexGeometryBufferIndex)
        encoder.setVertexBuffer(vertexUniformsBuffer, offset: 0, index: kTexturedQuadVertexUniformsBufferIndex)
        encoder.setFragmentBuffer(fragmentUniformsBuffer, offset: 0, index: kTexturedQuadFragmentUniformsBufferIndex)
        encoder.setFragmentTexture(texture, index: kTexturedQuadFragmentTextureIndex)
        encoder.setFragmentSamplerState(samplerState, index: kTexturedQuadFragmentSamplerIndex)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6, instanceCount: 1)
        encoder.endEncoding()
        
    }
}
