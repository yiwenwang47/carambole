//
//  SRGBPremultiply.swift
//  carambole
//
//  RealityKit renders into a `.bgra8Unorm_srgb` texture with alpha
//  premultiplied in LINEAR light, then sRGB-encodes the colour. Everything
//  that composites the bytes afterwards (Core Animation, AVFoundation's
//  HEVC-with-alpha) expects the colour premultiplied in sRGB space. Read the
//  other way, a soft edge pixel comes out far too light (an edge at 50 %
//  alpha read as (218, 238, 160) instead of ≈ (150, 163, 111)), which showed
//  as a thin glow round the star. `fix` rewrites the bytes in place.
//

import Foundation

enum SRGBPremultiply {
    /// table[a · 256 + c]: a byte `c` premultiplied by alpha `a` in linear
    /// light, as the same colour premultiplied in sRGB space.
    private static let table: [UInt8] = {
        func decode(_ v: Double) -> Double { v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) }
        func encode(_ v: Double) -> Double { v <= 0.0031308 ? v * 12.92 : 1.055 * pow(v, 1 / 2.4) - 0.055 }
        var t = [UInt8](repeating: 0, count: 256 * 256)
        for a in 1..<256 {
            let alpha = Double(a) / 255
            for c in 0..<256 {
                let straight = min(1, decode(Double(c) / 255) / alpha)
                t[a * 256 + c] = UInt8((encode(straight) * alpha * 255).rounded())
            }
        }
        return t
    }()

    /// Fixes 4-byte pixels with alpha in the last byte (BGRA or RGBA).
    static func fix(_ base: UnsafeMutableRawPointer, width: Int, height: Int, bytesPerRow: Int) {
        table.withUnsafeBufferPointer { t in
            for y in 0..<height {
                let row = base.advanced(by: y * bytesPerRow).assumingMemoryBound(to: UInt8.self)
                for x in 0..<width {
                    let px = row + x * 4
                    let a = Int(px[3])
                    if a == 0 || a == 255 { continue }
                    px[0] = t[a * 256 + Int(px[0])]
                    px[1] = t[a * 256 + Int(px[1])]
                    px[2] = t[a * 256 + Int(px[2])]
                }
            }
        }
    }
}
