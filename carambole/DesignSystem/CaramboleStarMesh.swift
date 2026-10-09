//
//  CaramboleStarMesh.swift
//  carambole
//
//  RealityKit building blocks for the 01 Objet book home (one chunky chrome
//  star): the logo
//  geometry as an extrusion path, the extruded meshes, hand-built torus-arc and
//  tube meshes, the chrome / paper / glass materials and a procedural neutral
//  "studio" environment for image-based lighting (a stand-in for three.js'
//  RoomEnvironment in design/motion.html).
//
//  Logo geometry (design/logo/README.md): 5 rib tips, 5 concave valleys, one
//  quadratic curve per lobe, point-up. Tips sit at radius 1 here; the caller
//  scales the entity.
//

import CoreGraphics
import RealityKit
import SwiftUI
import UIKit

// MARK: - Geometry

enum CaramboleStarMesh {
    /// 01 valley radius: r/R = 17/42, opened by 1.25 as in motion.html's 01 script.
    static let objetValley: CGFloat = 17.0 / 42.0 * 1.25

    /// Unit-tip star outline, y-up, centred on the origin, tip 0 straight up.
    static func path(valley: CGFloat, scale: CGFloat = 1) -> Path {
        var p = Path()
        p.move(to: tip(0, scale))
        for k in 0..<5 {
            p.addQuadCurve(to: tip(k + 1, scale), control: valleyPoint(k, valley * scale))
        }
        p.closeSubpath()
        return p
    }

    /// Points along the outline (`perLobe` samples per quadratic), y-up.
    static func outlinePoints(valley: CGFloat, perLobe: Int = 16) -> [CGPoint] {
        var pts: [CGPoint] = []
        for k in 0..<5 {
            let a = tip(k, 1), c = valleyPoint(k, valley), b = tip(k + 1, 1)
            for s in 0..<perLobe {
                let t = CGFloat(s) / CGFloat(perLobe)
                let u = 1 - t
                pts.append(CGPoint(x: u * u * a.x + 2 * u * t * c.x + t * t * b.x,
                                   y: u * u * a.y + 2 * u * t * c.y + t * t * b.y))
            }
        }
        return pts
    }

    private static func tip(_ k: Int, _ r: CGFloat) -> CGPoint {
        let a = Double.pi / 2 + Double(k) * 2 * .pi / 5
        return CGPoint(x: CGFloat(cos(a)) * r, y: CGFloat(sin(a)) * r)
    }

    private static func valleyPoint(_ k: Int, _ r: CGFloat) -> CGPoint {
        let a = Double.pi / 2 + (Double(k) + 0.5) * 2 * .pi / 5
        return CGPoint(x: CGFloat(cos(a)) * r, y: CGFloat(sin(a)) * r)
    }

    // MARK: Meshes

    /// 01 star: three.js `ExtrudeGeometry` depth .34 + bevel .14 each side, bevel
    /// size .1 → .62 deep overall. RealityKit's chamfer ADDS to the linear depth
    /// (measured: depth .62 + radius .13 → .88), so the core is .36 + 2 × .13.
    @MainActor
    static func objetMesh() throws -> MeshResource {
        var o = MeshResource.ShapeExtrusionOptions()
        o.extrusionMethod = .linear(depth: 0.36)
        o.chamferRadius = 0.13
        o.chamferMode = .both
        o.boundaryResolution = .uniformSegmentsPerSpan(segmentCount: 48)
        o.chamferResolution = .uniformSegmentsPerSpan(segmentCount: 10)
        return try MeshResource(extruding: path(valley: objetValley, scale: 1.08), extrusionOptions: o)
    }

    /// Wraps `mesh` so its bounding box is centred on the returned entity's origin
    /// (three.js `geo.center()`).
    @MainActor
    static func centred(_ mesh: MeshResource, materials: [RealityKit.Material]) -> (holder: Entity, model: ModelEntity) {
        let model = ModelEntity(mesh: mesh, materials: materials)
        model.position = -mesh.bounds.center
        let holder = Entity()
        holder.addChild(model)
        return (holder, model)
    }

    /// A torus segment in the XY plane (axis Z), like three.js `TorusGeometry`,
    /// from angle `start` sweeping `sweep` radians counter-clockwise.
    static func torusArc(radius: Float, tube: Float, start: Float, sweep: Float,
                         radialSegments: Int = 12, tubularSegments: Int = 220) throws -> MeshResource {
        let segs = max(2, Int(Float(tubularSegments) * abs(sweep) / (2 * .pi)))
        var pos: [SIMD3<Float>] = [], nrm: [SIMD3<Float>] = [], idx: [UInt32] = []
        for j in 0...radialSegments {
            for i in 0...segs {
                let u = start + Float(i) / Float(segs) * sweep
                let v = Float(j) / Float(radialSegments) * 2 * .pi
                let centre = SIMD3<Float>(radius * cos(u), radius * sin(u), 0)
                let p = SIMD3<Float>((radius + tube * cos(v)) * cos(u),
                                     (radius + tube * cos(v)) * sin(u),
                                     tube * sin(v))
                pos.append(p)
                nrm.append(simd_normalize(p - centre))
            }
        }
        let row = UInt32(segs + 1)
        for j in 1...radialSegments {
            for i in 1...segs {
                let a = row * UInt32(j) + UInt32(i - 1)
                let b = row * UInt32(j - 1) + UInt32(i - 1)
                let c = row * UInt32(j - 1) + UInt32(i)
                let d = row * UInt32(j) + UInt32(i)
                idx += [a, b, d, b, c, d]
            }
        }
        var desc = MeshDescriptor(name: "torusArc")
        desc.positions = MeshBuffers.Positions(pos)
        desc.normals = MeshBuffers.Normals(nrm)
        desc.primitives = .triangles(idx)
        return try MeshResource.generate(from: [desc])
    }

    /// A thin closed tube through `points` — the stand-in for three.js' 1px
    /// `LineLoop` outline (RealityKit has no line primitive).
    /// `up` = the loop's plane normal.
    static func tubeLoop(_ points: [SIMD3<Float>], radius: Float, sides: Int = 6,
                         up: SIMD3<Float> = [0, 1, 0]) throws -> MeshResource {
        let n = points.count
        var pos: [SIMD3<Float>] = [], nrm: [SIMD3<Float>] = [], idx: [UInt32] = []
        for i in 0..<n {
            let t = simd_normalize(points[(i + 1) % n] - points[(i + n - 1) % n])
            var side = simd_cross(t, up)
            if simd_length(side) < 1e-4 { side = SIMD3<Float>(1, 0, 0) }
            side = simd_normalize(side)
            let normalUp = simd_normalize(simd_cross(side, t))
            for s in 0..<sides {
                let a = Float(s) / Float(sides) * 2 * .pi
                let d = side * cos(a) + normalUp * sin(a)
                pos.append(points[i] + d * radius)
                nrm.append(d)
            }
        }
        for i in 0..<n {
            let i2 = (i + 1) % n
            for s in 0..<sides {
                let s2 = (s + 1) % sides
                let a = UInt32(i * sides + s), b = UInt32(i2 * sides + s)
                let c = UInt32(i2 * sides + s2), d = UInt32(i * sides + s2)
                idx += [a, b, c, a, c, d]
            }
        }
        var desc = MeshDescriptor(name: "tubeLoop")
        desc.positions = MeshBuffers.Positions(pos)
        desc.normals = MeshBuffers.Normals(nrm)
        desc.primitives = .triangles(idx)
        return try MeshResource.generate(from: [desc])
    }
}

// MARK: - Materials

enum StarMaterial {
    /// three.js `MeshPhysicalMaterial` chrome: metalness .85, roughness ~.22,
    /// clearcoat 1 / .08.
    static func chrome(roughness: Float = 0.22) -> PhysicallyBasedMaterial {
        var m = PhysicallyBasedMaterial()
        m.baseColor = .init(tint: UIColor(white: 0.95, alpha: 1))
        m.metallic = .init(floatLiteral: 0.85)
        m.roughness = .init(floatLiteral: roughness)
        m.clearcoat = .init(floatLiteral: 1)
        m.clearcoatRoughness = .init(floatLiteral: 0.08)
        return m
    }

    /// Dark lacquered metal for the orbit arc / bead / skewer.
    static func ink(metallic: Float = 0.6, roughness: Float = 0.25) -> PhysicallyBasedMaterial {
        var m = PhysicallyBasedMaterial()
        m.baseColor = .init(tint: UIColor(white: 0.08, alpha: 1))
        m.metallic = .init(floatLiteral: metallic)
        m.roughness = .init(floatLiteral: roughness)
        return m
    }

    /// White paper (06 in-progress slice).
    static func paper() -> PhysicallyBasedMaterial {
        var m = PhysicallyBasedMaterial()
        m.baseColor = .init(tint: .white)
        m.metallic = .init(floatLiteral: 0)
        m.roughness = .init(floatLiteral: 0.65)
        return m
    }

    /// Unlit flat colour, optionally translucent (track, glass, outlines).
    static func flat(_ white: CGFloat, opacity: Float = 1) -> UnlitMaterial {
        var m = UnlitMaterial(color: UIColor(white: white, alpha: 1))
        if opacity < 1 { m.blending = .transparent(opacity: .init(floatLiteral: opacity)) }
        return m
    }
}

// MARK: - Studio environment (image-based lighting)

/// A neutral grey "room" with soft rectangular light panels, rendered once as an
/// equirectangular image and turned into an `EnvironmentResource`. Gives the
/// chrome something to reflect (bright panels + mid-grey walls + dark floor),
/// like three.js' `RoomEnvironment`. Rectangles only — no dot patterns.
@MainActor
enum StudioEnvironment {
    private static var cached: EnvironmentResource?

    static func resource() -> EnvironmentResource? {
        if let cached { return cached }
        guard let image = makeImage(),
              let env = try? EnvironmentResource(equirectangular: image, withName: "carambole-studio")
        else { return nil }
        cached = env
        return env
    }

    /// An entity carrying the IBL plus a helper to make others receive it.
    static func lightEntity(intensityExponent: Float = 0.6) -> Entity? {
        guard let env = resource() else { return nil }
        let e = Entity()
        e.components.set(ImageBasedLightComponent(source: .single(env), intensityExponent: intensityExponent))
        return e
    }

    /// Recursively lets `root` and its descendants receive `light`.
    static func receive(_ root: Entity, from light: Entity) {
        root.components.set(ImageBasedLightReceiverComponent(imageBasedLight: light))
        for c in root.children { receive(c, from: light) }
    }

    private static func makeImage() -> CGImage? {
        let w = 1024, h = 512
        guard let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { return nil }
        // CG's origin is bottom-left: y = h is the zenith row.
        let colors = [UIColor(white: 0.78, alpha: 1).cgColor,  // ceiling
                      UIColor(white: 0.68, alpha: 1).cgColor,  // walls at the horizon
                      UIColor(white: 0.30, alpha: 1).cgColor,  // floor
                      UIColor(white: 0.18, alpha: 1).cgColor] as CFArray
        let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors,
                              locations: [0, 0.48, 0.56, 1])!
        ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: h), end: CGPoint(x: 0, y: 0), options: [])

        // Soft light panels: (azimuth 0…1, elevation centre 0…1 from bottom, w, h, brightness).
        let panels: [(CGFloat, CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (0.50, 0.93, 1.00, 0.14, 1.00),  // big overhead panel
            (0.12, 0.66, 0.10, 0.20, 1.00),  // key panels around the horizon
            (0.40, 0.70, 0.07, 0.16, 0.95),
            (0.64, 0.62, 0.12, 0.10, 1.00),
            (0.86, 0.68, 0.08, 0.22, 0.90),
            (0.30, 0.56, 0.20, 0.03, 0.85),  // a long low strip
        ]
        for (u, v, pw, ph, b) in panels {
            let rect = CGRect(x: (u - pw / 2) * CGFloat(w), y: (v - ph / 2) * CGFloat(h),
                              width: pw * CGFloat(w), height: ph * CGFloat(h))
            ctx.setFillColor(UIColor(white: b, alpha: 1).cgColor)
            ctx.fill(rect)
        }
        return ctx.makeImage()
    }
}

// MARK: - Camera projection helper

/// Pin-hole projection matching a `PerspectiveCamera` with a vertical FOV, used
/// to map world points to SwiftUI points (06 tick + pointer mapping) without
/// round-tripping through the renderer.
struct StarCameraProjection {
    let eye: SIMD3<Float>
    let target: SIMD3<Float>
    let fovDegrees: Float

    /// Screen y (points from the top) of a world point, in a view `height` tall.
    func screenY(_ p: SIMD3<Float>, height: CGFloat) -> CGFloat {
        let f = simd_normalize(target - eye)
        let r = simd_normalize(simd_cross(f, SIMD3<Float>(0, 1, 0)))
        let u = simd_cross(r, f)
        let d = p - eye
        let ndc = (simd_dot(d, u) / simd_dot(d, f)) / tan(fovDegrees * .pi / 360)
        return (1 - CGFloat(ndc)) / 2 * height
    }

    /// Orientation that makes a camera at `eye` look at `target`.
    var orientation: simd_quatf {
        let f = simd_normalize(target - eye)
        let r = simd_normalize(simd_cross(f, SIMD3<Float>(0, 1, 0)))
        let u = simd_cross(r, f)
        return simd_quatf(simd_float3x3(columns: (r, u, -f)))
    }
}
