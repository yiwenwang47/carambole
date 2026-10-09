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
//  (±12 %, never jagged); a book to come is a slimmer link of tracing paper.
//
//  The RealityView is laid out INSIDE the scroll content, as tall as the list,
//  so the system scroll moves it with the titles (no offset syncing). It uses
//  an orthographic camera at k = 0.0076 world units per point, so content
//  points map 1:1 onto the mesh. Only the gentle sway animates.
//
//  Spine and boundary twist follow the prototype's `<!-- 08 · library ribbon -->`
//  script; the two-sided paper + edge-tube mesh comes from the 05 ribbon.
//

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
    /// Link widths (world units): pinch at the ends, started belly 0.48…0.62
    /// (≈ 63…82 pt), book-to-come belly 0.40 (≈ 53 pt).
    static let pinch: Float = 0.03
    static let startedBase: Float = 0.48
    static let startedGain: Float = 0.14
    static let toComeBelly: Float = 0.40
    /// Fraction of a link spent opening from the pinch to the belly, and the
    /// flat neck (points) either side of a boundary where the paper twists.
    static let shoulder: Float = 0.2
    static let neck: Float = 9
    /// Half-length (points) of the 2π twist at a boundary.
    static let twistHalf: Float = 18

    /// Content height the ribbon (and the shelf) occupy.
    var contentHeight: Float { Self.top(ofStretch: stretches.count) + Self.tail }
    /// Ribbon axis x: 268 of the prototype's 360, kept as a right margin.
    var axisX: Float { viewWidth - 92 }

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
    /// on the pinch, plus a gentle ±0.35 rad roll so the paper catches the
    /// light unevenly inside a link.
    func twist(at py: Float) -> Float {
        var th = 0.35 * sin((py - Self.start) / 95)
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

    /// The paper strip, one side. `front` = white side (normals +n, CCW seen
    /// from +n); the back is the same strip with flipped winding + normals.
    static func paperMesh(_ samples: [Sample], front: Bool) throws -> MeshResource {
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        positions.reserveCapacity(samples.count * 2)
        normals.reserveCapacity(samples.count * 2)
        for sm in samples {
            let n = front ? sm.n : -sm.n
            positions.append(sm.p + sm.w * sm.half)
            positions.append(sm.p - sm.w * sm.half)
            normals.append(n); normals.append(n)
        }
        var indices: [UInt32] = []
        indices.reserveCapacity((samples.count - 1) * 6)
        for i in 0..<(samples.count - 1) {
            let a0 = UInt32(i * 2), b0 = a0 + 1, a1 = a0 + 2, b1 = a0 + 3
            indices += front ? [a0, a1, b0, b0, a1, b1] : [a0, b0, a1, b0, b1, a1]
        }
        var desc = MeshDescriptor(name: front ? "shelfRibbonFront" : "shelfRibbonBack")
        desc.positions = MeshBuffers.Positions(positions)
        desc.normals = MeshBuffers.Normals(normals)
        desc.primitives = .triangles(indices)
        return try MeshResource.generate(from: [desc])
    }

    /// The two edge lines (prototype `THREE.Line`s) as thin square tubes.
    static func edgeMesh(_ samples: [Sample], radius r: Float = 0.004) throws -> MeshResource {
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

// MARK: - Motion

/// Per-frame sway state for the RealityKit update loop (not SwiftUI state).
final class LibraryRibbonMotion {
    var reduceMotion = false
    private var time: Float = 0
    weak var pivot: Entity?
    var subscription: EventSubscription?

    /// Prototype: `pivot.rotation.y = sin(t · .5) · .2`, none with Reduce Motion.
    func tick(_ dt: Float) {
        time += dt
        let angle = reduceMotion ? 0 : sin(time * 0.5) * 0.2
        pivot?.orientation = simd_quatf(angle: angle, axis: [0, 1, 0])
    }
}

// MARK: - RealityView

/// The shelf ribbon, sized to `geometry.viewWidth × contentHeight`. Rebuild by
/// changing `.id` when the geometry changes.
struct LibraryRibbonScene: View {
    let geometry: LibraryRibbonGeometry
    let motion: LibraryRibbonMotion

    var body: some View {
        RealityView { content in
            content.camera = .virtual

            // Orthographic: the view's full width spans viewWidth · k world units, so
            // content points map 1:1 onto the mesh.
            let camera = Entity()
            var ortho = OrthographicCameraComponent()
            // `scale` is the HALF extent along `scaleDirection`.
            ortho.scaleDirection = .horizontal
            ortho.scale = geometry.viewWidth * LibraryRibbonGeometry.k / 2
            ortho.near = 0.1
            ortho.far = 50
            camera.components.set(ortho)
            camera.position = [0, 0, 10]
            content.add(camera)

            // Key light (prototype DirectionalLight at (-2, 4, 5)).
            let key = DirectionalLight()
            key.light.intensity = 2600
            key.look(at: .zero, from: [-2, 4, 5], relativeTo: nil)
            content.add(key)

            // Sway about the ribbon's own axis: pivot at the axis, group offset back.
            let pivot = Entity()
            pivot.position.x = geometry.wx(geometry.axisX)
            let group = Entity()
            group.position.x = -geometry.wx(geometry.axisX)
            pivot.addChild(group)

            for (i, stretch) in geometry.stretches.enumerated() {
                let samples = geometry.samples(forStretch: i)
                let live = stretch.isLive
                if let front = try? LibraryRibbonGeometry.paperMesh(samples, front: true),
                   let back = try? LibraryRibbonGeometry.paperMesh(samples, front: false),
                   let edges = try? LibraryRibbonGeometry.edgeMesh(samples) {
                    group.addChild(ModelEntity(mesh: front, materials: [Self.paper(white: true, live: live)]))
                    group.addChild(ModelEntity(mesh: back, materials: [Self.paper(white: false, live: live)]))
                    var line = UnlitMaterial(color: UIColor(live ? AppColor.ink : AppColor.g2))
                    line.faceCulling = .none
                    group.addChild(ModelEntity(mesh: edges, materials: [line]))
                }
            }
            content.add(pivot)

            motion.pivot = pivot
            motion.tick(0)
            motion.subscription = content.subscribe(to: SceneEvents.Update.self) { event in
                motion.tick(Float(event.deltaTime))
            }
        }
    }

    /// Two-sided paper: white front, grey (g2) back. Books to come are tracing
    /// paper (front 0.6, back 0.35 opacity). Faint self-light stands in for the
    /// prototype's hemisphere fill so shadowed folds stay paper, not black.
    private static func paper(white: Bool, live: Bool) -> PhysicallyBasedMaterial {
        var m = PhysicallyBasedMaterial()
        let base = white ? UIColor.white : UIColor(AppColor.g2)
        m.baseColor = .init(tint: base)
        m.roughness = .init(floatLiteral: white ? 0.6 : 0.7)
        m.metallic = .init(floatLiteral: 0)
        m.emissiveColor = .init(color: base)
        m.emissiveIntensity = white ? 0.45 : 0.35
        if !live {
            m.blending = .transparent(opacity: .init(floatLiteral: white ? 0.6 : 0.35))
        }
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
        assert(abs(g.wx(g.axisX) - (268 - 180) * k) < 1e-5, "axis at 268 of 360")
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
        let end = g.twist(at: g.contentHeight) - 0.35 * sin((g.contentHeight - start) / 95)
        assert(abs(end - 2 * 2 * .pi) < 1e-3, "2 boundaries = 4π")
        assert(abs(g.twist(at: top(ofStretch: 1) - 30)) < 0.36, "no turn inside the first link")
    }
}
#endif
