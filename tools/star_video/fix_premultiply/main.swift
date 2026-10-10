import AVFoundation
import VideoToolbox
// One-off fix for loops rendered before 2026-10-10 (see ../README.md).
// Build + run from the repo root:
//   swiftc -O tools/star_video/fix_premultiply/main.swift carambole/DesignSystem/SRGBPremultiply.swift -o /tmp/fixmov
//   /tmp/fixmov in.mov out.mov
let src = URL(fileURLWithPath: CommandLine.arguments[1]), dst = URL(fileURLWithPath: CommandLine.arguments[2])
try? FileManager.default.removeItem(at: dst)
let asset = AVURLAsset(url: src)
let track = try await asset.loadTracks(withMediaType: .video)[0]
let size = try await track.load(.naturalSize)
let reader = try AVAssetReader(asset: asset)
let out = AVAssetReaderTrackOutput(track: track, outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA])
out.alwaysCopiesSampleData = true
reader.add(out); reader.startReading()
let w = Int(size.width), h = Int(size.height)
let writer = try AVAssetWriter(outputURL: dst, fileType: .mov)
let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
    AVVideoCodecKey: AVVideoCodecType.hevcWithAlpha, AVVideoWidthKey: w, AVVideoHeightKey: h,
    AVVideoColorPropertiesKey: [AVVideoColorPrimariesKey: AVVideoColorPrimaries_ITU_R_709_2,
                                AVVideoTransferFunctionKey: AVVideoTransferFunction_IEC_sRGB,
                                AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_709_2],
    AVVideoCompressionPropertiesKey: [AVVideoQualityKey: 0.9,
                                      kVTCompressionPropertyKey_TargetQualityForAlpha as String: 0.9,
                                      kVTCompressionPropertyKey_AlphaChannelMode as String: kVTAlphaChannelMode_PremultipliedAlpha]])
input.expectsMediaDataInRealTime = false
let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: nil)
writer.add(input); writer.startWriting(); writer.startSession(atSourceTime: .zero)
var n = 0
while let sb = out.copyNextSampleBuffer() {
    guard let pb = CMSampleBufferGetImageBuffer(sb) else { continue }
    CVPixelBufferLockBaseAddress(pb, [])
    SRGBPremultiply.fix(CVPixelBufferGetBaseAddress(pb)!, width: w, height: h, bytesPerRow: CVPixelBufferGetBytesPerRow(pb))
    CVPixelBufferUnlockBaseAddress(pb, [])
    while !input.isReadyForMoreMediaData { try await Task.sleep(for: .milliseconds(2)) }
    adaptor.append(pb, withPresentationTime: CMSampleBufferGetPresentationTimeStamp(sb))
    n += 1
}
input.markAsFinished(); await writer.finishWriting()
print("frames \(n) status \(writer.status.rawValue) \(writer.error.map { "\($0)" } ?? "")")
