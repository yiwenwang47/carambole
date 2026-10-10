//
//  StarVideoGeometry.swift
//  carambole
//
//  The numbers shared by the star-loop generator (`StarVideoRenderer`) and the
//  view that plays it (`StarLoopView`), so the pre-rendered star and the 2D
//  orbit ring drawn around it line up with the old live RealityKit scene
//  (`ObjetStarController`: camera at z 11.5, 30° vertical field, group at
//  y 0.1, ring radius 1.32 tilted 1.18 / 0.22 rad).
//

import Foundation
import simd

enum StarVideoGeometry {
    /// Live scene camera distance and vertical field of view.
    static let cameraZ: Float = 11.5
    static let liveFieldOfViewDegrees: Float = 30
    /// World units (at the star's depth) covered by the square video.
    static let worldExtent: Float = 2.0
    /// The narrowed field used to render just that square.
    static var renderFieldOfViewDegrees: Float {
        2 * atan(worldExtent / 2 / cameraZ) * 180 / .pi
    }
    /// 900 px covers the star at 3× on the tallest phone with room to spare.
    static let pixelSize = 900
    static let fps = 60
    /// One loop = half a turn at the live rest spin (0.006 rad per 60 Hz frame).
    static let frameCount = 524
    static var loopSeconds: Double { Double(frameCount) / Double(fps) }

    /// Group height and bob (world units, bob period 2π / 0.9 s).
    static let groupY: Float = 0.1
    static let bobAmplitude: Float = 0.06
    static let bobRate: Float = 0.9

    /// Ring: radius, tube radii, fixed tilt and spin rate (rad / s).
    static let ringRadius: Float = 1.32
    static let ringTilt = simd_quatf(angle: 1.18, axis: [1, 0, 0]) * simd_quatf(angle: 0.22, axis: [0, 1, 0])
    static let ringSpinRate: Float = 0.0025 * 60
    static let trackTube: Float = 0.012
    static let arcTube: Float = 0.045
    static let enCoursTube: Float = 0.024
    static let beadRadius: Float = 0.09

    static func fileName(_ palette: AppPalette) -> String { "star_\(palette.rawValue).mov" }

    /// Focal length in points for a view `height` points tall (the live scene
    /// filled the view, so its vertical field spans `height`). A point at depth
    /// d from the camera projects at `focal · x / d` from the view centre.
    static func focal(height: Double) -> Double {
        height / 2 / tan(Double(liveFieldOfViewDegrees) / 2 * .pi / 180)
    }
}
