//
//  LibraryRibbon.swift
//  carambole
//
//  motion.html 08 "Ruban": one twisted paper ribbon running down the whole
//  shelf, one stretch per book. A started book's stretch is its last
//  30 days over ≈ 560 pt (width = learned + reviewed on a scale SHARED across books, eased
//  between days; a rest day = one full 2π twist that flashes the grey back).
//  A book to come is a narrow, faint strip of tracing paper. A full twist also
//  marks every boundary between books.
//
//  The RealityView is laid out INSIDE the scroll content, as tall as the list,
//  so the system scroll moves it with the titles (no offset syncing). It uses
//  an orthographic camera at k = 0.0076 world units per point, so content
//  points map 1:1 onto the mesh. Only the gentle sway animates.
//
//  Geometry mirrors the prototype's `<!-- 08 · library ribbon -->` script:
//  same spine, width and twist functions. The two-sided paper + edge-tube mesh
//  construction comes from the earlier 05 history ribbon.
//

import RealityKit
import SwiftUI
import UIKit

// MARK: - Geometry (pure)

/// The library ribbon's shape as pure functions of content-space y (points
/// from the top of the scroll content).
struct LibraryRibbonGeometry: Hashable {
    /// One book's stretch of ribbon.
    enum Stretch: Hashable {
        /// learned + reviewed per day, oldest first (the last 30 days).
        case started([Int])
        /// A book that isn't open yet: narrow, faint, no days.
        case toCome

        var isLive: Bool { if case .started = self { return true } else { return false } }
    }

    let stretches: [Stretch]
    /// Width of the view in points (the phone width).
    let viewWidth: Float
    /// Busiest single day across all started books (≥ 1): the shared width scale.
    let busiestDay: Int

    init(stretches: [Stretch], viewWidth: Float) {
        self.stretches = stretches
        self.viewWidth = viewWidth
        self.busiestDay = max(1, stretches.compactMap { s -> Int? in
            if case let .started(days) = s { return days.max() } else { return nil }
        }.max() ?? 1)
    }

    /// First stretch top, stretch length, tail below the last one (points).
    static let start: Float = 236
    /// Stretch length (points): a started book gets the old 05 history
    /// ribbon's proportions (30 days over ≈ 560 pt, ≈ 18 pt a day) so its
    /// edges stay soft; a book to come is a short 200 pt strip.
    static let startedStep: Float = 560
    static let toComeStep: Float = 200
    static let tail: Float = 110
    /// World units per point (orthographic).
    static let k: Float = 0.0076
    /// Started-book minimum width and book-to-come width (world units).
    static let toComeWidth: Float = 0.12
    /// Mesh samples per point of spine.
    static let samplesPerPoint: Float = 1 / 1.2

    /// Content height the ribbon (and the shelf) occupy.
    var contentHeight: Float { top(ofStretch: stretches.count) + Self.tail }
    /// Ribbon axis x: 268 of the prototype's 360, kept as a right margin.
    var axisX: Float { viewWidth - 92 }

    /// Top y of stretch `i` (points).
    /// Length of stretch `i` (points).
    func length(ofStretch i: Int) -> Float {
        stretches[i].isLive ? Self.startedStep : Self.toComeStep
    }

    /// Top y of stretch `i` (points); `i == count` is the end of the ribbon.
    func top(ofStretch i: Int) -> Float {
        Self.start + (0..<min(i, stretches.count)).reduce(0) { $0 + length(ofStretch: $1) }
    }

    // MARK: Point → world

    func wx(_ px: Float) -> Float { (px - viewWidth / 2) * Self.k }
    func wy(_ py: Float) -> Float { (contentHeight / 2 - py) * Self.k }

    // MARK: Shape

    /// A calm weave down the right side of the shelf (prototype `spine`).
    func spine(_ py: Float) -> SIMD3<Float> {
        let d = py - Self.start
        return SIMD3(wx(axisX + sin(d / 230) * 22), wy(py), sin(d / 170) * 0.3)
    }

    private func stretchIndex(at py: Float) -> Int {
        var end = Self.start
        for i in stretches.indices {
            end += length(ofStretch: i)
            if py < end { return i }
        }
        return max(0, stretches.count - 1)
    }

    private static func ease(_ x: Float) -> Float {
        let x = min(1, max(0, x))
        return x * x * (3 - 2 * x)
    }

    /// Ribbon width (world units): 0.04 + 0.5 · v / busiestDay — the old 05
    /// history ribbon's formula, one scale shared by all started books.
    func width(at py: Float) -> Float {
        guard !stretches.isEmpty else { return Self.toComeWidth }
        let b = stretchIndex(at: py)
        guard case let .started(days) = stretches[b], !days.isEmpty else { return Self.toComeWidth }
        let n = days.count
        let d = (py - top(ofStretch: b)) / length(ofStretch: b) * Float(n - 1)
        let i = max(0, min(n - 1, Int(d.rounded(.down))))
        let j = min(n - 1, i + 1)
        let e = Self.ease(d - Float(i))
        let v = Float(days[i]) * (1 - e) + Float(days[j]) * e
        return 0.04 + 0.5 * v / Float(busiestDay)
    }

    /// Accumulated twist: a full 2π at every book boundary, and one per PAUSE
    /// inside a started book (centres clamped so an end pause's twist
    /// completes). A pause = a run of consecutive rest days (`restRuns`), so
    /// sparse activity never coils the strip into dozens of tight twists.
    func twist(at py: Float) -> Float {
        var th: Float = 0
        for (bi, stretch) in stretches.enumerated() {
            let s0 = top(ofStretch: bi)
            let len = length(ofStretch: bi)
            if bi > 0 { th += 2 * .pi * Self.ease((py - s0 + 22) / 44) }
            guard case let .started(days) = stretch else { continue }
            let span = Float(max(1, days.count - 1))
            for centre in Self.restRuns(days) {
                let c = s0 + min(span - 0.5, max(0.5, centre)) / span * len
                th += 2 * .pi * Self.ease((py - c) / (len / span) + 0.5)
            }
        }
        return th
    }

    /// Centre day index of each pause: a run of consecutive rest days after
    /// the book's first active day in the window (days before it aren't
    /// pauses — the book wasn't started yet). Pure.
    static func restRuns(_ days: [Int]) -> [Float] {
        guard let first = days.firstIndex(where: { $0 > 0 }) else { return [] }
        var centres: [Float] = []
        var runStart: Int?
        for i in first..<days.count {
            if days[i] == 0 {
                if runStart == nil { runStart = i }
            } else if let r = runStart {
                centres.append(Float(r + i - 1) / 2)
                runStart = nil
            }
        }
        if let r = runStart { centres.append(Float(r + days.count - 1) / 2) }
        return centres
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
        return Sample(p: p, w: w, n: n, half: width(at: py) / 2)
    }

    /// Samples for stretch `i` (overlapping the next stretch by 1 pt so the
    /// seam never opens).
    func samples(forStretch i: Int) -> [Sample] {
        let a = top(ofStretch: i)
        let b = a + length(ofStretch: i) + (i < stretches.count - 1 ? 1 : 0)
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
        let rest = [5, 0, 7] + Array(repeating: 6, count: 27)
        let g = LibraryRibbonGeometry(stretches: [.started(rest), .started(Array(repeating: 0, count: 30)), .toCome],
                                      viewWidth: 360)
        assert(g.top(ofStretch: 1) == 236 + 560 && g.top(ofStretch: 2) == 236 + 1120, "started stretches are 560 pt")
        assert(g.contentHeight == 236 + 560 * 2 + 200 + 110, "content height = start + lengths + tail")
        assert(abs(g.wx(g.axisX) - (268 - 180) * k) < 1e-5, "axis at 268 of 360")
        // Width: 05 formula relative to the busiest day across started books (7 here).
        assert(g.busiestDay == 7, "busiest day = 7")
        assert(abs(g.width(at: g.top(ofStretch: 0)) - (0.04 + 0.5 * 5 / 7)) < 1e-4, "first day width")
        assert(abs(g.width(at: g.top(ofStretch: 1) + 100) - 0.04) < 1e-5, "idle started book = 0.04")
        assert(abs(g.width(at: g.top(ofStretch: 2) + 100) - toComeWidth) < 1e-5, "book to come")
        // Twist: one rest day (2π) inside book 0, plus 2π per boundary, none for the idle book.
        let end = g.twist(at: g.contentHeight)
        assert(abs(end - 3 * 2 * .pi) < 1e-3, "1 rest + 2 boundaries = 6π, got \(end)")
        assert(abs(g.twist(at: g.top(ofStretch: 0))) < 1e-3, "no twist at the start")
        // Pauses: leading rest days aren't pauses; a run of rest days is one pause.
        assert(restRuns([0, 0, 3, 0, 0, 0, 4, 0, 5]) == [4, 7], "runs centred at 4 and 7")
        assert(restRuns([2, 0, 0]) == [1.5], "trailing run counts")
        assert(restRuns([0, 0, 0]).isEmpty, "never-started book has no pauses")
    }
}
#endif
