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

    /// 01 star: three.js `ExtrudeGeometry` (depth .34, bevelThickness .14,
    /// bevelSize .1, bevelSegments 10) built by hand. RealityKit's own chamfer
    /// left sawtooth artefacts where the bevel met each tip and blunted the
    /// tips; here every ring of the bevel is the unit outline offset outward by
    /// `size · cos φ` (mitred at the tips, so they stay sharp) at height
    /// `depth/2 + thickness · sin φ`, with analytic normals, so the curves and
    /// the bevel shade smoothly.
    static func objetMesh(perLobe: Int = 96, bevelSegments: Int = 12) throws -> MeshResource {
        let depth: Float = 0.34, thickness: Float = 0.14, size: Float = 0.1
        let rim = rimPoints(valley: objetValley, perLobe: perLobe)
        let n = rim.count

        // Profile, back cap edge → back bevel → wall → front bevel → front cap
        // edge: (outward offset, z, outward weight, z weight) per ring.
        var profile: [(off: Float, z: Float, nOut: Float, nZ: Float)] = []
        for j in 0...bevelSegments {   // back bevel, φ from π/2 down to 0
            let phi = Float.pi / 2 * (1 - Float(j) / Float(bevelSegments))
            profile.append((size * cos(phi), -(depth / 2 + thickness * sin(phi)), thickness * cos(phi), -size * sin(phi)))
        }
        for j in 0...bevelSegments {   // front bevel, φ from 0 up to π/2
            let phi = Float.pi / 2 * Float(j) / Float(bevelSegments)
            profile.append((size * cos(phi), depth / 2 + thickness * sin(phi), thickness * cos(phi), size * sin(phi)))
        }

        var pos: [SIMD3<Float>] = [], nrm: [SIMD3<Float>] = [], idx: [UInt32] = []
        for ring in profile {
            for r in rim {
                let xy = r.p + r.miter * ring.off
                pos.append([xy.x, xy.y, ring.z])
                nrm.append(simd_normalize(SIMD3(r.n.x * ring.nOut, r.n.y * ring.nOut, ring.nZ)))
            }
        }
        // Sides: rim runs CCW seen from +z, rings run back → front, so
        // (i, j) → (i+1, j) → (i+1, j+1) faces outward.
        for j in 0..<(profile.count - 1) {
            for i in 0..<n {
                let i2 = (i + 1) % n
                let a = UInt32(j * n + i), b = UInt32(j * n + i2)
                let c = UInt32((j + 1) * n + i2), d = UInt32((j + 1) * n + i)
                idx += [a, b, c, a, c, d]
            }
        }
        // Caps: fans from the centre (the star is star-shaped about it).
        for (z, sign) in [(depth / 2 + thickness, Float(1)), (-(depth / 2 + thickness), Float(-1))] {
            let centre = UInt32(pos.count)
            pos.append([0, 0, z]); nrm.append([0, 0, sign])
            let first = UInt32(pos.count)
            for r in rim { pos.append([r.p.x, r.p.y, z]); nrm.append([0, 0, sign]) }
            for i in 0..<n {
                let a = first + UInt32(i), b = first + UInt32((i + 1) % n)
                idx += sign > 0 ? [centre, a, b] : [centre, b, a]
            }
        }

        var desc = MeshDescriptor(name: "objetStar")
        desc.positions = MeshBuffers.Positions(pos)
        desc.normals = MeshBuffers.Normals(nrm)
        desc.primitives = .triangles(idx)
        return try MeshResource.generate(from: [desc])
    }

    /// One rim sample: point on the unit outline, its outward normal, and the
    /// direction to offset it along (the normal, or the miter at a tip).
    struct RimPoint {
        let p: SIMD2<Float>
        let n: SIMD2<Float>
        let miter: SIMD2<Float>
    }

    /// The outline, CCW, `perLobe + 1` samples per quadratic lobe. Each tip
    /// appears twice (end of one lobe, start of the next) with its own lobe's
    /// normal, so the tip stays a crisp ridge, and both copies share the miter
    /// so the offset rings never open a gap.
    static func rimPoints(valley: CGFloat, perLobe: Int) -> [RimPoint] {
        func f2(_ p: CGPoint) -> SIMD2<Float> { [Float(p.x), Float(p.y)] }
        func outward(_ t: SIMD2<Float>) -> SIMD2<Float> { simd_normalize(SIMD2(t.y, -t.x)) }
        // Normals at the start (t = 0) and end (t = 1) of lobe k.
        func lobe(_ k: Int) -> (a: SIMD2<Float>, c: SIMD2<Float>, b: SIMD2<Float>) {
            (f2(tip(k, 1)), f2(valleyPoint(k, valley)), f2(tip(k + 1, 1)))
        }
        func miter(_ n1: SIMD2<Float>, _ n2: SIMD2<Float>) -> SIMD2<Float> {
            let m = simd_normalize(n1 + n2)
            return m / max(0.2, simd_dot(m, n1))
        }
        var pts: [RimPoint] = []
        for k in 0..<5 {
            let (a, c, b) = lobe(k)
            let prev = lobe(k + 4)
            let next = lobe(k + 1)
            let startMiter = miter(outward(prev.b - prev.c), outward(c - a))
            let endMiter = miter(outward(b - c), outward(next.c - next.a))
            for s in 0...perLobe {
                let t = Float(s) / Float(perLobe), u = 1 - t
                let p = u * u * a + 2 * u * t * c + t * t * b
                let n = outward(2 * u * (c - a) + 2 * t * (b - c))
                let m = s == 0 ? startMiter : s == perLobe ? endMiter : n
                pts.append(RimPoint(p: p, n: n, miter: m))
            }
        }
        return pts
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

    /// The palette's star body (`AppTheme.StarFinish`).
    static func finish(_ f: AppTheme.StarFinish) -> RealityKit.Material {
        switch f {
        case .acrylic(let hex):
            return acrylic(UIColor(hex: hex))
        case .iris:
            return iris()
        }
    }

    /// Tinted acrylic: glossy clearcoat over the colour, plus a little emissive
    /// so it reads lit from inside. Opaque on purpose (RealityKit's transparent
    /// blending flattens the lighting).
    static func acrylic(_ color: UIColor) -> PhysicallyBasedMaterial {
        var m = PhysicallyBasedMaterial()
        m.baseColor = .init(tint: color)
        m.metallic = .init(floatLiteral: 0)
        m.roughness = .init(floatLiteral: 0.14)
        m.specular = .init(floatLiteral: 0.9)
        m.clearcoat = .init(floatLiteral: 1)
        m.clearcoatRoughness = .init(floatLiteral: 0.04)
        m.emissiveColor = .init(color: color)
        m.emissiveIntensity = 0.3
        return m
    }

    /// Iris: light pearly metal with a faint lilac glow. (PhysicallyBasedMaterial
    /// has no iridescence and its `sheen` tinted the star olive; a custom
    /// shader would need the Metal toolchain.)
    private static func iris() -> PhysicallyBasedMaterial {
        var m = PhysicallyBasedMaterial()
        m.baseColor = .init(tint: UIColor(hex: "F3F1F8"))
        m.metallic = .init(floatLiteral: 0.35)
        m.roughness = .init(floatLiteral: 0.2)
        m.specular = .init(floatLiteral: 0.8)
        m.clearcoat = .init(floatLiteral: 1)
        m.clearcoatRoughness = .init(floatLiteral: 0.05)
        m.emissiveColor = .init(color: UIColor(hex: "F1EDFF"))
        m.emissiveIntensity = 0.18
        return m
    }

    /// Glossy coloured lacquer for the orbit arc / bead.
    static func lacquer(_ hex: String) -> PhysicallyBasedMaterial {
        var m = PhysicallyBasedMaterial()
        m.baseColor = .init(tint: UIColor(hex: hex))
        m.metallic = .init(floatLiteral: 0.2)
        m.roughness = .init(floatLiteral: 0.22)
        m.clearcoat = .init(floatLiteral: 1)
        m.clearcoatRoughness = .init(floatLiteral: 0.1)
        return m
    }

    /// Unlit flat palette colour.
    static func flat(hex: String) -> UnlitMaterial {
        UnlitMaterial(color: UIColor(hex: hex))
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
