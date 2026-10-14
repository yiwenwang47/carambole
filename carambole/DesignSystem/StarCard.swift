//
//  StarCard.swift
//  carambole
//
//  The 01 Objet star as a die-cut card (default since 2026-10-14; mock
//  design/star-and-marks, artifact KoG5B5dkqq2mWohL6q6AKZ): a card with a white
//  die-cut border, the palette's star colour printed on the face, and the quiet
//  colour printed a little off register over one lobe. `StarVideoRenderer`
//  renders it into the shipped loops (`star_<palette>.mov`).
//
//  Trial looks for comparison, rendered by `CB_RENDER_STAR=<look>` into
//  `star_<look>_<palette>.mov` and played by `CB_STAR_VARIANT=<look>`:
//    ink:   the same card with a black face (the language marks' recipe).
//    objet: the earlier extruded acrylic / pearl star (`CaramboleStarMesh`).
//

import CoreGraphics
import Foundation
import RealityKit
import UIKit

enum StarCard {
    enum Look: String { case card, ink, objet }

    /// White border round the star, card thickness (world units, star tips at 1).
    static let border: Float = 0.15
    static let depth: Float = 0.08
    /// Face texture covers x, y in ±span / 2.
    private static let span: Float = 2.7

    /// Loop file for a look: the default card ships as `star_<palette>.mov`.
    static func fileName(_ look: Look, _ palette: AppPalette) -> String {
        look == .card ? StarVideoGeometry.fileName(palette) : "star_\(look.rawValue)_\(palette.rawValue).mov"
    }

    // MARK: Geometry

    /// Star outline, CCW, one sample per step, each tip once.
    private static func outline(perLobe: Int = 64) -> [SIMD2<Float>] {
        let valley = Float(CaramboleStarMesh.objetValley)
        func at(_ a: Float, _ r: Float) -> SIMD2<Float> { [cos(a) * r, sin(a) * r] }
        var pts: [SIMD2<Float>] = []
        for k in 0..<5 {
            let a = at(.pi / 2 + Float(k) * 2 * .pi / 5, 1)
            let c = at(.pi / 2 + (Float(k) + 0.5) * 2 * .pi / 5, valley)
            let b = at(.pi / 2 + Float(k + 1) * 2 * .pi / 5, 1)
            for s in 0..<perLobe {
                let t = Float(s) / Float(perLobe), u = 1 - t
                pts.append(u * u * a + 2 * u * t * c + t * t * b)
            }
        }
        return pts
    }

    /// The outline grown by `border`, round at the tips (a die-cut edge).
    private static func cardOutline() -> [SIMD2<Float>] {
        let pts = outline(), n = pts.count
        func normal(_ p: SIMD2<Float>, _ q: SIMD2<Float>) -> SIMD2<Float> { simd_normalize(SIMD2(q.y - p.y, -(q.x - p.x))) }
        var out: [SIMD2<Float>] = []
        for i in 0..<n {
            let p = pts[i], n0 = normal(pts[(i + n - 1) % n], p), n1 = normal(p, pts[(i + 1) % n])
            let a0 = atan2(n0.y, n0.x)
            var d = atan2(n1.y, n1.x) - a0
            while d > .pi { d -= 2 * .pi }
            while d < -.pi { d += 2 * .pi }
            if d < -0.2 {
                let steps = Int((-d / 0.08).rounded(.up))
                for s in 0...steps {
                    let a = a0 + d * Float(s) / Float(steps)
                    out.append(p + SIMD2(cos(a), sin(a)) * border)
                }
            } else {
                out.append(p + simd_normalize(n0 + n1) * border)
            }
        }
        return out
    }

    /// Two meshes: the printed faces (front and back, UV from x, y) and the edge wall.
    static func meshes() throws -> (faces: MeshResource, edge: MeshResource) {
        let rim = cardOutline(), n = rim.count, z = depth / 2
        func uv(_ p: SIMD2<Float>, mirror: Bool) -> SIMD2<Float> {
            // Back face mirrored in x so the card looks the same after a half turn (seamless π loop).
            [(mirror ? -p.x : p.x) / span + 0.5, p.y / span + 0.5]
        }
        var pos: [SIMD3<Float>] = [], nrm: [SIMD3<Float>] = [], tex: [SIMD2<Float>] = [], idx: [UInt32] = []
        for (zz, sign) in [(z, Float(1)), (-z, Float(-1))] {
            let centre = UInt32(pos.count)
            pos.append([0, 0, zz]); nrm.append([0, 0, sign]); tex.append(uv(.zero, mirror: sign < 0))
            let first = UInt32(pos.count)
            for p in rim { pos.append([p.x, p.y, zz]); nrm.append([0, 0, sign]); tex.append(uv(p, mirror: sign < 0)) }
            for i in 0..<n {
                let a = first + UInt32(i), b = first + UInt32((i + 1) % n)
                idx += sign > 0 ? [centre, a, b] : [centre, b, a]
            }
        }
        var faces = MeshDescriptor(name: "starCardFaces")
        faces.positions = MeshBuffers.Positions(pos)
        faces.normals = MeshBuffers.Normals(nrm)
        faces.textureCoordinates = MeshBuffers.TextureCoordinates(tex)
        faces.primitives = .triangles(idx)

        var wp: [SIMD3<Float>] = [], wn: [SIMD3<Float>] = [], wi: [UInt32] = []
        for i in 0..<n {
            let p = rim[i], q = rim[(i + 1) % n]
            let nn = simd_normalize(SIMD2(q.y - p.y, -(q.x - p.x)))
            let base = UInt32(wp.count)
            wp += [[p.x, p.y, -z], [q.x, q.y, -z], [q.x, q.y, z], [p.x, p.y, z]]
            wn += Array(repeating: SIMD3(nn.x, nn.y, 0), count: 4)
            wi += [base, base + 1, base + 2, base, base + 2, base + 3]
        }
        var edge = MeshDescriptor(name: "starCardEdge")
        edge.positions = MeshBuffers.Positions(wp)
        edge.normals = MeshBuffers.Normals(wn)
        edge.primitives = .triangles(wi)
        return (try MeshResource.generate(from: [faces]), try MeshResource.generate(from: [edge]))
    }

    // MARK: Materials

    @MainActor
    static func materials(_ look: Look, _ palette: AppPalette) throws -> (face: PhysicallyBasedMaterial, edge: PhysicallyBasedMaterial) {
        let t = palette.theme
        let body = look == .ink ? UIColor(hex: "0F0F0F") : UIColor(hex: faceHex(palette))
        let image = try faceImage(body: body, quiet: UIColor(hex: t.tokenReview))
        let texture = try TextureResource(image: image, options: .init(semantic: .color))
        var face = PhysicallyBasedMaterial()
        face.baseColor = .init(texture: .init(texture))
        face.metallic = .init(floatLiteral: 0)
        face.roughness = .init(floatLiteral: 0.9)
        face.specular = .init(floatLiteral: 0.2)
        var edge = PhysicallyBasedMaterial()
        edge.baseColor = .init(tint: UIColor(hex: "F2F1EC"))
        edge.metallic = .init(floatLiteral: 0)
        edge.roughness = .init(floatLiteral: 0.95)
        return (face, edge)
    }

    /// The palette's star colour (Iris: lilac, its loud colour).
    private static func faceHex(_ p: AppPalette) -> String {
        switch p.theme.star {
        case .acrylic(let hex): return hex
        case .iris: return p.theme.tokenNew
        }
    }

    /// White card, smooth star in `body`, the quiet colour multiplied over the top-left lobe.
    private static func faceImage(body: UIColor, quiet: UIColor) throws -> CGImage {
        let size = 1024
        guard let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                  bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
        else { throw NSError(domain: "StarCard", code: 1) }
        // CG origin is bottom-left, like uv: (x / span + 0.5) · size.
        func pt(_ p: SIMD2<Float>) -> CGPoint {
            CGPoint(x: CGFloat((p.x / span + 0.5) * Float(size)), y: CGFloat((p.y / span + 0.5) * Float(size)))
        }
        func fill(_ pts: [SIMD2<Float>], _ color: UIColor) {
            ctx.beginPath()
            ctx.move(to: pt(pts[0]))
            for p in pts.dropFirst() { ctx.addLine(to: pt(p)) }
            ctx.closePath()
            ctx.setFillColor(color.cgColor)
            ctx.fillPath()
        }
        ctx.setFillColor(UIColor.white.cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))
        fill(outline(perLobe: 128), body)

        // Overprint: lobe 0 (tip 0 → tip 1, closed through the centre), nudged and turned a little.
        let valley = Float(CaramboleStarMesh.objetValley)
        let a = SIMD2<Float>(cos(.pi / 2), sin(.pi / 2))
        let c = SIMD2<Float>(cos(.pi / 2 + .pi / 5), sin(.pi / 2 + .pi / 5)) * valley
        let b = SIMD2<Float>(cos(.pi / 2 + 2 * .pi / 5), sin(.pi / 2 + 2 * .pi / 5))
        var lobe: [SIMD2<Float>] = (0...64).map { s in
            let t = Float(s) / 64, u = 1 - t
            return u * u * a + 2 * u * t * c + t * t * b
        }
        lobe.append(.zero)
        let rot: Float = 0.12, shift = SIMD2<Float>(0.07, 0.03)
        lobe = lobe.map { p in SIMD2(p.x * cos(rot) - p.y * sin(rot), p.x * sin(rot) + p.y * cos(rot)) + shift }
        ctx.setBlendMode(.multiply)
        ctx.setAlpha(0.9)
        fill(lobe, quiet)
        guard let image = ctx.makeImage() else { throw NSError(domain: "StarCard", code: 2) }
        return image
    }
}
