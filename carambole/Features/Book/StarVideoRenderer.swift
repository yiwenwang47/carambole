//
//  StarVideoRenderer.swift
//  carambole
//
//  DEBUG-only generator for the pre-rendered star loops (`star_<palette>.mov`).
//  Renders the 01 Objet star (the `StarCard` die-cut card; `CB_RENDER_STAR=ink`
//  or `objet` renders a trial look instead) offscreen with `RealityRenderer`, using the same
//  mesh, materials and lights as the live scene, and writes one HEVC-with-alpha
//  loop per palette to Documents. Copy them into `Resources/StarVideos/`.
//
//  Run: launch a Debug build with `CB_RENDER_STAR=1` in the environment, wait
//  for "STAR VIDEOS DONE" in the log, then copy Documents/star_*.mov off the
//  device (see tools/star_video/README.md).
//

#if DEBUG
import AVFoundation
import Metal
import os
import RealityKit
import UIKit
import VideoToolbox

@MainActor
enum StarVideoRenderer {
    private static let log = Logger(subsystem: "wen.carambole", category: "StarVideo")

    static func runIfRequested() {
        guard let flag = ProcessInfo.processInfo.environment["CB_RENDER_STAR"],
              let look = flag == "1" ? .card : StarCard.Look(rawValue: flag) else { return }
        Task { @MainActor in
            do {
                for palette in AppPalette.allCases {
                    let url = try await render(palette, look: look)
                    log.log("wrote \(url.lastPathComponent, privacy: .public)")
                }
                log.log("STAR VIDEOS DONE")
            } catch {
                log.error("STAR VIDEOS FAILED: \(String(describing: error), privacy: .public)")
            }
        }
    }

    private struct Failure: Error { let what: String }

    static func render(_ palette: AppPalette, look: StarCard.Look) async throws -> URL {
        let g = StarVideoGeometry.self
        let size = g.pixelSize
        let renderer = try RealityRenderer()
        renderer.cameraSettings.colorBackground = .color(CGColor(gray: 0, alpha: 0))
        renderer.cameraSettings.antialiasing = .multisample4X

        // Same rig as `ObjetStarController.makeScene`, minus the ring (drawn in
        // 2D by `StarLoopView`). The camera keeps the live position (z = 11.5)
        // but narrows its field to the square around the star, so the
        // perspective matches the live scene exactly.
        let camera = PerspectiveCamera()
        camera.camera.fieldOfViewInDegrees = g.renderFieldOfViewDegrees
        camera.position = [0, 0, g.cameraZ]
        let key = DirectionalLight()
        key.light.intensity = 2600
        key.look(at: .zero, from: [3, 4, 6], relativeTo: nil)
        let pivot = Entity()
        pivot.scale = SIMD3(repeating: 0.78)
        let light = StudioEnvironment.lightEntity(intensityExponent: 1.1)
        if look == .objet {
            let mesh = try CaramboleStarMesh.objetMesh()
            let star = CaramboleStarMesh.centred(mesh, materials: [StarMaterial.finish(palette.theme.star)])
            pivot.addChild(star.holder)
        } else {
            let meshes = try StarCard.meshes()
            let mats = try StarCard.materials(look, palette)
            pivot.addChild(ModelEntity(mesh: meshes.faces, materials: [mats.face]))
            pivot.addChild(ModelEntity(mesh: meshes.edge, materials: [mats.edge]))
        }
        if let light { StudioEnvironment.receive(pivot, from: light) }
        renderer.entities.append(contentsOf: [camera, key, pivot] + (light.map { [$0] } ?? []))
        renderer.activeCamera = camera

        guard let device = MTLCreateSystemDefaultDevice() else { throw Failure(what: "no Metal device") }
        let desc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm_srgb, width: size,
                                                            height: size, mipmapped: false)
        desc.usage = [.renderTarget, .shaderRead]
        desc.storageMode = .shared
        guard let texture = device.makeTexture(descriptor: desc) else { throw Failure(what: "texture") }
        let output = try RealityRenderer.CameraOutput(.singleProjection(colorTexture: texture))

        let url = URL.documentsDirectory.appending(path: StarCard.fileName(look, palette))
        try? FileManager.default.removeItem(at: url)
        let writer = try AVAssetWriter(outputURL: url, fileType: .mov)
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.hevcWithAlpha,
            AVVideoWidthKey: size,
            AVVideoHeightKey: size,
            AVVideoColorPropertiesKey: [
                AVVideoColorPrimariesKey: AVVideoColorPrimaries_ITU_R_709_2,
                AVVideoTransferFunctionKey: AVVideoTransferFunction_IEC_sRGB,
                AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_709_2,
            ],
            AVVideoCompressionPropertiesKey: [
                AVVideoQualityKey: 0.9,
                kVTCompressionPropertyKey_TargetQualityForAlpha as String: 0.9,
                kVTCompressionPropertyKey_AlphaChannelMode as String: kVTAlphaChannelMode_PremultipliedAlpha,
            ],
        ])
        input.expectsMediaDataInRealTime = false
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: size,
            kCVPixelBufferHeightKey as String: size,
        ])
        writer.add(input)
        guard writer.startWriting() else { throw writer.error ?? Failure(what: "startWriting") }
        writer.startSession(atSourceTime: .zero)

        for frame in 0..<g.frameCount {
            // Half a turn per loop: the star is mirror-symmetric about its
            // vertical axis and front/back symmetric, so a π turn is seamless.
            let rotY = Float.pi * Float(frame) / Float(g.frameCount)
            pivot.orientation = simd_quatf(angle: rotY, axis: [0, 1, 0])
            await withCheckedContinuation { (done: CheckedContinuation<Void, Never>) in
                do {
                    try renderer.updateAndRender(deltaTime: 1.0 / Double(g.fps), cameraOutput: output,
                                                 onComplete: { _ in done.resume() })
                } catch {
                    done.resume()
                }
            }
            while !input.isReadyForMoreMediaData { try await Task.sleep(for: .milliseconds(2)) }
            guard let pool = adaptor.pixelBufferPool else { throw Failure(what: "pool") }
            var buffer: CVPixelBuffer?
            CVPixelBufferPoolCreatePixelBuffer(nil, pool, &buffer)
            guard let buffer else { throw Failure(what: "pixel buffer") }
            CVPixelBufferLockBaseAddress(buffer, [])
            texture.getBytes(CVPixelBufferGetBaseAddress(buffer)!,
                             bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                             from: MTLRegionMake2D(0, 0, size, size), mipmapLevel: 0)
            SRGBPremultiply.fix(CVPixelBufferGetBaseAddress(buffer)!, width: size, height: size,
                                bytesPerRow: CVPixelBufferGetBytesPerRow(buffer))
            CVPixelBufferUnlockBaseAddress(buffer, [])
            adaptor.append(buffer, withPresentationTime: CMTime(value: CMTimeValue(frame),
                                                                timescale: CMTimeScale(g.fps)))
        }
        input.markAsFinished()
        await writer.finishWriting()
        if let error = writer.error { throw error }
        return url
    }
}
#endif
