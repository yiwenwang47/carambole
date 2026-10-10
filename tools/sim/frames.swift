// Extract frames from a video: frames <video> <outdir> <start s> <end s> <step s>
// [y0 y1] crops rows (ring band). Writes f_<ms>.jpg (exact time, zero tolerance).
import AVFoundation
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let a = CommandLine.arguments
let asset = AVURLAsset(url: URL(fileURLWithPath: a[1]))
let out = URL(fileURLWithPath: a[2])
try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
let start = Double(a[3])!, step = Double(a[5])!
let sem = DispatchSemaphore(value: 0)
Task {
    let dur = try await asset.load(.duration).seconds
    print("duration \(dur)")
    let end = min(Double(a[4])!, dur - 0.001)
    let gen = AVAssetImageGenerator(asset: asset)
    gen.requestedTimeToleranceBefore = .zero
    gen.requestedTimeToleranceAfter = .zero
    var t = start
    var n = 0
    while t <= end {
        if var img = try? await gen.image(at: CMTime(seconds: t, preferredTimescale: 6000)).image {
            if a.count > 7, let y0 = Int(a[6]), let y1 = Int(a[7]),
               let c = img.cropping(to: CGRect(x: 0, y: y0, width: img.width, height: y1 - y0)) { img = c }
            let url = out.appendingPathComponent(String(format: "f_%07d.jpg", Int((t * 1000).rounded())))
            if let dst = CGImageDestinationCreateWithURL(url as CFURL, UTType.jpeg.identifier as CFString, 1, nil) {
                CGImageDestinationAddImage(dst, img, [kCGImageDestinationLossyCompressionQuality: 0.9] as CFDictionary)
                CGImageDestinationFinalize(dst)
                n += 1
            }
        }
        t += step
    }
    print("wrote \(n)")
    sem.signal()
}
sem.wait()
