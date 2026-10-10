//
//  LibraryRibbon.swift
//  carambole
//
//  motion.html 08 "Ruban": one twisted paper ribbon running down the whole
//  shelf, ONE LINK PER BOOK. Each book is a single soft blob of paper, 200 pt
//  tall, pinched and given a full 2π twist where it meets the next book (the
//  old 05 history ribbon's chain-of-links look), so three books fit on a
//  screen. A link opens from its pinch with round shoulders, then runs at a
//  near-constant belly whose two edges wobble independently (seeded per book),
//  like hand-cut paper. A started book's belly grows with its 30-day total
//  (scale SHARED across books) and its last 30 days tint the outline gently
//  (±12 %, never jagged); a book to come is a slimmer, paler link with grey edges.
//
//  The ribbon is rendered once to a still image (`LibraryRibbonImage`) laid
//  out INSIDE the scroll content, as tall as the list, so the system scroll
//  moves it with the titles (no offset syncing). The render uses an
//  orthographic camera at k = 0.0076 world units per point, so content points
//  map 1:1 onto the mesh. Nothing animates (the old sway is gone).
//
//  Spine and boundary twist follow the prototype's `<!-- 08 · library ribbon -->`
//  script; the two-sided paper + edge-tube mesh comes from the 05 ribbon.
//

import Metal
import RealityKit
import SwiftUI
import UIKit

// MARK: - Geometry (pure)

/// The library ribbon's shape as pure functions of content-space y (points
/// from the top of the scroll content).
struct LibraryRibbonGeometry: Hashable {
    /// One book's link of ribbon.
    enum Stretch: Hashable {
        /// learned + reviewed per day, oldest first (the last 30 days).
        case started([Int])
        /// A book that isn't open yet: small, faint, no days.
        case toCome

        var isLive: Bool { if case .started = self { return true } else { return false } }
    }

    let stretches: [Stretch]
    /// Width of the view in points (the phone width).
    let viewWidth: Float
    /// Per stretch: the smoothed 30-day profile, 0…1 against the book's own
    /// busiest smoothed day (empty for a book to come).
    let profiles: [[Float]]
    /// Per stretch: belly width (world units). Started books grow with their
    /// 30-day total on a scale shared across books.
    let bellies: [Float]

    init(stretches: [Stretch], viewWidth: Float) {
        self.stretches = stretches
        self.viewWidth = viewWidth
        let totals = stretches.map { s -> Int in
            if case let .started(days) = s { return days.reduce(0, +) } else { return 0 }
        }
        let peakTotal = Float(max(1, totals.max() ?? 0))
        self.profiles = stretches.map { s -> [Float] in
            guard case let .started(days) = s else { return [] }
            let sm = Self.smooth(days)
            let peak = max(1e-6, sm.max() ?? 0)
            return sm.map { $0 / peak }
        }
        self.bellies = zip(stretches, totals).map { s, total in
            s.isLive ? Self.startedBase + Self.startedGain * sqrt(Float(total) / peakTotal) : Self.toComeBelly
        }
    }

    /// First link top, link length, tail below the last one (points).
    static let start: Float = 236
    static let step: Float = 200
    static let tail: Float = 110
    /// World units per point (orthographic).
    static let k: Float = 0.0076
    /// Mesh samples per point of spine.
    static let samplesPerPoint: Float = 1 / 1.2
    /// Link widths (world units): pinch at the ends, started belly 0.62…0.78
    /// (≈ 82…103 pt), book-to-come belly 0.52 (≈ 68 pt).
    static let pinch: Float = 0.03
    static let startedBase: Float = 0.62
    static let startedGain: Float = 0.16
    static let toComeBelly: Float = 0.52
    /// Fraction of a link spent opening from the pinch to the belly, and the
    /// flat neck (points) either side of a boundary where the paper twists.
    static let shoulder: Float = 0.2
    static let neck: Float = 9
    /// Half-length (points) of the 2π twist at a boundary: long enough that
    /// the paper starts turning on the shoulders and catches grey light there.
    static let twistHalf: Float = 28
    /// Roll (radians) inside a link, so links tilt toward or away from the key.
    static let roll: Float = 0.7
    /// Cross-width curl: the paper bows by `curl · half` mid-width, so light
    /// grades from edge to edge instead of shading one flat colour.
    static let curl: Float = 0.6
    /// Mesh columns across the width (curl needs more than the 2 edges).
    static let columns = 10

    /// Content height the ribbon (and the shelf) occupy.
    var contentHeight: Float { Self.top(ofStretch: stretches.count) + Self.tail }
    /// Ribbon axis x: 84 pt in from the right edge (the prototype had 92 of
    /// 360; nudged right so the wider links clear the titles).
    var axisX: Float { viewWidth - 84 }

    /// Top y of link `i` (points); `i == count` is the end of the ribbon.
    static func top(ofStretch i: Int) -> Float { start + Float(i) * step }

    // MARK: Point → world

    func wx(_ px: Float) -> Float { (px - viewWidth / 2) * Self.k }
    func wy(_ py: Float) -> Float { (contentHeight / 2 - py) * Self.k }

    // MARK: Shape

    /// A calm weave down the right side of the shelf (prototype `spine`) plus
    /// a shorter drift so each link leans a little, like 05's links.
    func spine(_ py: Float) -> SIMD3<Float> {
        let d = py - Self.start
        return SIMD3(wx(axisX + sin(d / 230) * 24 + sin(d / 64) * 9), wy(py), sin(d / 170) * 0.3)
    }

    private func stretchIndex(at py: Float) -> Int {
        let i = Int(((py - Self.start) / Self.step).rounded(.down))
        return min(stretches.count - 1, max(0, i))
    }

    private static func ease(_ x: Float) -> Float {
        let x = min(1, max(0, x))
        return x * x * (3 - 2 * x)
    }

    /// Gaussian smoothing (σ = 3.5 days) so a link's outline stays soft.
    static func smooth(_ days: [Int]) -> [Float] {
        let sigma: Float = 3.5
        return days.indices.map { i in
            var sum: Float = 0, weight: Float = 0
            for (j, v) in days.enumerated() {
                let w = exp(-Float((i - j) * (i - j)) / (2 * sigma * sigma))
                sum += w * Float(v)
                weight += w
            }
            return sum / weight
        }
    }

    /// Link envelope: 0 through the flat neck at both ends of a book, round
    /// shoulders (sin^0.8) over `shoulder` of the link, 1 across the belly.
    static func envelope(_ t: Float) -> Float {
        let g = neck / step
        func rise(_ x: Float) -> Float {
            pow(sin(.pi / 2 * min(1, max(0, (x - g) / (shoulder - g)))), 0.8)
        }
        return rise(t) * rise(1 - t)
    }

    /// Smooth deterministic noise in about ±Σamps: a few sines whose phases
    /// are seeded by `seed` (stable per book, never per frame).
    static func wobble(seed: Int, _ t: Float, amps: [Float], freqs: [Float]) -> Float {
        var r: Float = 0
        for (k, (a, f)) in zip(amps, freqs).enumerated() {
            let h = sin(Float(seed) * 12.9898 + Float(k) * 78.233) * 43758.5453
            let phase = (h - h.rounded(.down)) * 2 * .pi
            r += a * sin(2 * .pi * f * t + phase)
        }
        return r
    }

    private func linkT(_ py: Float) -> (b: Int, t: Float) {
        let b = stretchIndex(at: py)
        return (b, (py - Self.top(ofStretch: b)) / Self.step)
    }

    /// Ribbon width (world units): pinch + envelope · belly · tint · wobble.
    /// A started book's smoothed days tint the belly by 0.82…1.04.
    func width(at py: Float) -> Float {
        guard !stretches.isEmpty else { return Self.pinch }
        let (b, t) = linkT(py)
        var tint: Float = 1
        let profile = profiles[b]
        if !profile.isEmpty {
            let d = min(1, max(0, t)) * Float(profile.count - 1)
            let i = min(profile.count - 1, Int(d.rounded(.down)))
            let j = min(profile.count - 1, i + 1)
            let e = Self.ease(d - Float(i))
            tint = 0.82 + 0.22 * (profile[i] * (1 - e) + profile[j] * e)
        }
        let wob = 1 + Self.wobble(seed: b + 1, t, amps: [0.10, 0.06, 0.035], freqs: [1.3, 2.4, 3.7])
        return Self.pinch + Self.envelope(t) * bellies[b] * tint * wob
    }

    /// Sideways shift of the link's centre along its width direction (world
    /// units), so the two edges wobble independently. 0 at the pinches.
    func offset(at py: Float) -> Float {
        guard !stretches.isEmpty else { return 0 }
        let (b, t) = linkT(py)
        return Self.envelope(t) * bellies[b] * Self.wobble(seed: b + 7, t, amps: [0.07, 0.04], freqs: [1.1, 2.2])
    }

    /// Accumulated twist: one full 2π at every boundary between books, centred
    /// on the pinch, plus a ±`roll` rad roll so the paper catches the light
    /// unevenly inside a link.
    func twist(at py: Float) -> Float {
        var th = Self.roll * sin((py - Self.start) / 110 + 0.7)
        for bi in 1..<max(1, stretches.count) {
            th += 2 * .pi * Self.ease((py - Self.top(ofStretch: bi) + Self.twistHalf) / (2 * Self.twistHalf))
        }
        return th
    }

    /// One sample along the ribbon: centre, unit width direction, unit
    /// normal (white side), half width.
    struct Sample {
        let p: SIMD3<Float>
        let w: SIMD3<Float>
        let n: SIMD3<Float>
        let half: Float
    }

    /// Width direction = world Z projected perpendicular to the tangent, then
    /// turned by the twist about the tangent (Frenet frames flip on this spine).
    func sample(_ py: Float) -> Sample {
        let p = spine(py)
        let tg = simd_normalize(spine(py + 0.5) - spine(py - 0.5))
        let z = SIMD3<Float>(0, 0, 1)
        let w0 = simd_normalize(z - tg * simd_dot(tg, z))
        let xw = simd_cross(tg, w0)
        let th = twist(at: py)
        let w = simd_normalize(xw * cos(th) + w0 * sin(th))
        let n = simd_normalize(simd_cross(w, tg))
        return Sample(p: p + w * offset(at: py), w: w, n: n, half: width(at: py) / 2)
    }

    /// Samples for link `i` (overlapping the next link by 1 pt so the seam
    /// never opens).
    func samples(forStretch i: Int) -> [Sample] {
        let a = Self.top(ofStretch: i)
        let b = a + Self.step + (i < stretches.count - 1 ? 1 : 0)
        let count = max(2, Int(((b - a) * Self.samplesPerPoint).rounded()))
        return (0...count).map { sample(a + (b - a) * Float($0) / Float(count)) }
    }

    // MARK: Meshes

    /// The paper strip, one side, `columns` wide and bowed by `curl` across
    /// its width (normals follow the bow). `front` = white side (normals +n,
    /// CCW seen from +n); the back is the same strip with flipped winding +
    /// normals.
    static func paperMesh(_ samples: [Sample], front: Bool) throws -> MeshResource {
        let cols = columns
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        positions.reserveCapacity(samples.count * (cols + 1))
        normals.reserveCapacity(samples.count * (cols + 1))
        for sm in samples {
            for c in 0...cols {
                let s = 1 - 2 * Float(c) / Float(cols)  // +1 … -1 across the width
                positions.append(sm.p + sm.w * (s * sm.half) + sm.n * (curl * sm.half * (1 - s * s)))
                let n = simd_normalize(sm.n + sm.w * (2 * curl * s))
                normals.append(front ? n : -n)
            }
        }
        let stride = UInt32(cols + 1)
        var indices: [UInt32] = []
        indices.reserveCapacity((samples.count - 1) * cols * 6)
        for i in 0..<UInt32(samples.count - 1) {
            for c in 0..<UInt32(cols) {
                let a0 = i * stride + c, b0 = a0 + 1, a1 = a0 + stride, b1 = a1 + 1
                indices += front ? [a0, a1, b0, b0, a1, b1] : [a0, b0, a1, b0, b1, a1]
            }
        }
        var desc = MeshDescriptor(name: front ? "shelfRibbonFront" : "shelfRibbonBack")
        desc.positions = MeshBuffers.Positions(positions)
        desc.normals = MeshBuffers.Normals(normals)
        desc.primitives = .triangles(indices)
        return try MeshResource.generate(from: [desc])
    }

    /// The two edge lines (prototype `THREE.Line`s) as thin square tubes.
    static func edgeMesh(_ samples: [Sample], radius r: Float = 0.0025) throws -> MeshResource {
        var positions: [SIMD3<Float>] = []
        var indices: [UInt32] = []
        for side: Float in [1, -1] {
            let base = UInt32(positions.count)
            for sm in samples {
                let e = sm.p + sm.w * (sm.half * side)
                positions += [e + sm.n * r, e + sm.w * r, e - sm.n * r, e - sm.w * r]
            }
            for i in 0..<(samples.count - 1) {
                let r0 = base + UInt32(i * 4), r1 = r0 + 4
                for k in 0..<UInt32(4) {
                    let k2 = (k + 1) % 4
                    indices += [r0 + k, r1 + k, r0 + k2, r0 + k2, r1 + k, r1 + k2]
                }
            }
        }
        var desc = MeshDescriptor(name: "shelfRibbonEdges")
        desc.positions = MeshBuffers.Positions(positions)
        desc.primitives = .triangles(indices)
        return try MeshResource.generate(from: [desc])
    }
}

// MARK: - Still image

/// The shelf ribbon as a still picture, sized to `geometry.viewWidth ×
/// contentHeight` points. It used to be a live RealityView that swayed; a
/// RealityView costs ~100 ms on the main thread every time it is created, and
/// the library re-created it on every return from a book. Now the scene is
/// rendered once per (geometry, palette, screen scale) with `RealityRenderer`
/// and shown as an image, so going back to the shelf is free.
struct LibraryRibbonImage: View {
    let geometry: LibraryRibbonGeometry
    var palette: AppPalette = .current

    @Environment(\.displayScale) private var displayScale
    @State private var image: CGImage?

    var body: some View {
        let key = LibraryRibbonRenderer.Key(geometry: geometry, palette: palette, scale: displayScale)
        Group {
            if let image = LibraryRibbonRenderer.cached(key) ?? image {
                Image(decorative: image, scale: displayScale)
                    .resizable()
            } else {
                Color.clear
            }
        }
        .task(id: key) {
            if LibraryRibbonRenderer.cached(key) != nil { return }
            // A new picture replaces one already on screen: wait for the
            // push / pop to settle first, so the render never lands mid-slide.
            if image != nil { try? await Task.sleep(for: .milliseconds(450)) }
            if Task.isCancelled { return }
            if let rendered = await LibraryRibbonRenderer.render(key) { image = rendered }
        }
    }
}

/// Renders the ribbon scene offscreen and keeps the latest picture.
@MainActor
enum LibraryRibbonRenderer {
    struct Key: Hashable {
        let geometry: LibraryRibbonGeometry
        let palette: AppPalette
        let scale: CGFloat
    }

    private static var last: (key: Key, image: CGImage)?
    private static var renderer: RealityRenderer?

    static func cached(_ key: Key) -> CGImage? {
        last?.key == key ? last?.image : nil
    }

    static func render(_ key: Key) async -> CGImage? {
        if let hit = cached(key) { return hit }
        let g = key.geometry
        let width = Int((CGFloat(g.viewWidth) * key.scale).rounded())
        let height = Int((CGFloat(g.contentHeight) * key.scale).rounded())
        guard width > 0, height > 0, let device = MTLCreateSystemDefaultDevice() else { return nil }
        do {
            if renderer == nil {
                let r = try RealityRenderer()
                r.cameraSettings.colorBackground = .color(CGColor(gray: 0, alpha: 0))
                r.cameraSettings.antialiasing = .multisample4X
                // RealityView adds soft environment light on top of the two
                // lights; the offscreen renderer has none, so give it the
                // studio room at the strength that matched the live view's
                // brightness (sim screenshots, 2026-10-09).
                r.lighting.resource = StudioEnvironment.resource()
                r.lighting.intensityExponent = 1.4
                renderer = r
            }
            guard let renderer else { return nil }
            let desc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm_srgb, width: width,
                                                                height: height, mipmapped: false)
            desc.usage = [.renderTarget, .shaderRead]
            desc.storageMode = .shared
            guard let texture = device.makeTexture(descriptor: desc) else { return nil }
            let output = try RealityRenderer.CameraOutput(.singleProjection(colorTexture: texture))

            let (camera, roots) = scene(g, palette: key.palette)
            renderer.entities.removeAll()
            renderer.entities.append(contentsOf: [camera] + roots)
            renderer.activeCamera = camera
            await withCheckedContinuation { (done: CheckedContinuation<Void, Never>) in
                do {
                    try renderer.updateAndRender(deltaTime: 0, cameraOutput: output, onComplete: { _ in done.resume() })
                } catch {
                    done.resume()
                }
            }
            renderer.entities.removeAll()

            let bytesPerRow = width * 4
            var pixels = Data(count: bytesPerRow * height)
            pixels.withUnsafeMutableBytes { buf in
                texture.getBytes(buf.baseAddress!, bytesPerRow: bytesPerRow,
                                 from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0)
            }
            guard let provider = CGDataProvider(data: pixels as CFData),
                  let image = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32,
                                      bytesPerRow: bytesPerRow, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                      bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue
                                                               | CGBitmapInfo.byteOrder32Little.rawValue),
                                      provider: provider, decode: nil, shouldInterpolate: true,
                                      intent: .defaultIntent)
            else { return nil }
            last = (key, image)
            return image
        } catch {
            return nil
        }
    }

    /// The old RealityView scene at rest: orthographic camera mapping content
    /// points 1:1 onto the mesh, key + fill lights, one paper link per book.
    private static func scene(_ geometry: LibraryRibbonGeometry, palette: AppPalette) -> (Entity, [Entity]) {
        // `scale` is the HALF extent along `scaleDirection`.
        let camera = Entity()
        var ortho = OrthographicCameraComponent()
        ortho.scaleDirection = .horizontal
        ortho.scale = geometry.viewWidth * LibraryRibbonGeometry.k / 2
        ortho.near = 0.1
        ortho.far = 50
        camera.components.set(ortho)
        camera.position = [0, 0, 10]

        // Key light (prototype DirectionalLight at (-2, 4, 5)): paper facing
        // the camera stays near white, paper turned away greys strongly.
        let key = DirectionalLight()
        key.light.intensity = 1000
        key.look(at: .zero, from: [-2, 4, 5], relativeTo: nil)

        // Soft fill from below-front (stands in for the prototype's
        // hemisphere ground colour) so turned paper greys, never blacks.
        let fill = DirectionalLight()
        fill.light.intensity = 120
        fill.look(at: .zero, from: [1, -3, 4], relativeTo: nil)

        let group = Entity()
        let theme = palette.theme
        for (i, stretch) in geometry.stretches.enumerated() {
            let samples = geometry.samples(forStretch: i)
            let live = stretch.isLive
            if let front = try? LibraryRibbonGeometry.paperMesh(samples, front: true),
               let back = try? LibraryRibbonGeometry.paperMesh(samples, front: false),
               let edges = try? LibraryRibbonGeometry.edgeMesh(samples) {
                let frontHex = live ? theme.ribbonFront : theme.soonFront
                let backHex = live ? theme.ribbonBack : theme.soonBack
                group.addChild(ModelEntity(mesh: front, materials: [paper(UIColor(hex: frontHex), live: live)]))
                group.addChild(ModelEntity(mesh: back, materials: [paper(UIColor(hex: backHex), live: live)]))
                var line = UnlitMaterial(color: UIColor(live ? AppColor.ink : AppColor.g2))
                line.faceCulling = .none
                group.addChild(ModelEntity(mesh: edges, materials: [line]))
            }
        }
        return (camera, [key, fill, group])
    }

    /// Two-sided paper in the palette's colours (front = the loud colour, back =
    /// the quiet one, seen where the paper twists), lit by a soft key + fill so
    /// it shades like the 05 ribbon (no self-light on a started book, so the
    /// folds read strongly). Books to come use paler colours and a little
    /// self-light.
    private static func paper(_ base: UIColor, live: Bool) -> PhysicallyBasedMaterial {
        var m = PhysicallyBasedMaterial()
        m.baseColor = .init(tint: base)
        m.roughness = .init(floatLiteral: 0.62)
        m.metallic = .init(floatLiteral: 0)
        m.specular = .init(floatLiteral: 0.1)
        m.emissiveColor = .init(color: base)
        // Books to come: same paper, lit more by itself, so their shading
        // (and grey back) is fainter. Opaque on purpose: RealityKit's
        // transparent blending flattened the lighting to plain white.
        m.emissiveIntensity = live ? 0 : 0.1
        return m
    }
}

// MARK: - Self-test

#if DEBUG
extension LibraryRibbonGeometry {
    static func _selfTest() {
        let busy = [5, 0, 7] + Array(repeating: 6, count: 27)
        let g = LibraryRibbonGeometry(stretches: [.started(busy), .started(Array(repeating: 0, count: 30)), .toCome],
                                      viewWidth: 360)
        assert(g.contentHeight == 236 + 3 * 200 + 110, "one 200 pt link per book")
        assert(abs(g.wx(g.axisX) - (276 - 180) * k) < 1e-5, "axis 84 pt from the right")
        // Links pinch at every book boundary and bulge mid-book.
        for i in 0...3 {
            let y = top(ofStretch: i) + (i == 3 ? -1e-3 : 0)
            assert(abs(g.width(at: y) - pinch) < 1e-3, "pinch at boundary \(i)")
            assert(abs(g.offset(at: y)) < 1e-4, "centred at boundary \(i)")
        }
        for i in 0...2 {
            for dy in stride(from: Float(50), through: 150, by: 10) {
                let w = g.width(at: top(ofStretch: i) + dy)
                assert(w > pinch + 0.6 * g.bellies[i] && w < pinch + 1.25 * g.bellies[i], "soft belly \(i) \(dy)")
            }
        }
        // Shared scale: busier total = wider belly; idle started > book to come.
        assert(g.bellies[0] > g.bellies[1] && g.bellies[1] > g.bellies[2], "belly order")
        assert(abs(g.bellies[0] - (startedBase + startedGain)) < 1e-5, "busiest book = full belly")
        // Twists: exactly one per boundary (the roll is tiny, never a turn).
        let end = g.twist(at: g.contentHeight) - roll * sin((g.contentHeight - start) / 110 + 0.7)
        assert(abs(end - 2 * 2 * .pi) < 1e-3, "2 boundaries = 4π")
        assert(abs(g.twist(at: top(ofStretch: 1) - twistHalf - 1)) <= roll + 1e-4, "no turn inside the first link")
    }
}
#endif
