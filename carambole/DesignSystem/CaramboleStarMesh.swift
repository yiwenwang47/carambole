//
//  CaramboleStarMesh.swift
//  carambole
//
//  RealityKit building blocks for the 01 Objet star (rendered offline into
//  the star loops by `StarVideoRenderer`): the hand-extruded star mesh, the
//  palette materials and a procedural neutral "studio" environment for
//  image-based lighting (a stand-in for three.js' RoomEnvironment in
//  design/motion.html).
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
}

// MARK: - Materials

enum StarMaterial {
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
