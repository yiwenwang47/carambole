//
//  RibbonView.swift
//  carambole
//
//  motion.html 05 "Ruban": the history timeline as a twisted paper ribbon.
//  Oldest day at the top, today at the bottom. Width = that day's work
//  (learned + reviewed, eased between days); a rest day = one full 2π twist
//  that flashes the grey back of the paper. RealityKit procedural mesh
//  (`MeshDescriptor`), no assets.
//
//  Geometry mirrors the prototype's `<script>` (05 · ribbon history) 1:1:
//  same spine, width and twist functions, camera (fov 34° vertical, z 9.5),
//  sway (sin(t·0.5)·0.25) and turn constants.
//

import RealityKit
import SwiftUI
import UIKit

// MARK: - Geometry (pure)

/// The ribbon's shape as pure functions of the per-day totals (oldest first).
struct RibbonGeometry {
    /// learned + reviewed per day, oldest first.
    let totals: [Int]

    /// Spine top / bottom (world y).
    static let y0: Float = 2.0
    static let y1: Float = -2.1
    /// Camera distance + vertical field of view (prototype `PerspectiveCamera(34)` at z 9.5).
    static let cameraZ: Float = 9.5
    static let fovDegrees: Float = 34
    /// Mesh resolution along the spine.
    static let segments = 900

    var count: Int { totals.count }
    private var maxTotal: Float { Float(max(1, totals.max() ?? 1)) }

    /// A calm S from top (oldest, s = 0) to bottom (today, s = 1).
    static func spine(_ t: Float) -> SIMD3<Float> {
        SIMD3(sin(t * .pi * 1.1) * 0.55,
              y0 + (y1 - y0) * t,
              sin(t * .pi * 2) * 0.35)
    }

    /// Spine parameter of day `i`.
    func s(ofDay i: Int) -> Float {
        count > 1 ? Float(i) / Float(count - 1) : 0
    }

    /// Ribbon width: the day's total, smoothstep-eased between neighbouring days.
    func width(at s: Float) -> Float {
        guard count > 0 else { return 0.04 }
        let d = s * Float(max(0, count - 1))
        let i = min(count - 1, Int(d.rounded(.down)))
        let j = min(count - 1, i + 1)
        let f = d - Float(i)
        let e = f * f * (3 - 2 * f)
        let v = Float(totals[i]) * (1 - e) + Float(totals[j]) * e
        return 0.04 + 0.5 * (v / maxTotal)
    }

    /// Accumulated twist: each rest day adds a full 2π, eased across one day.
    /// Centres are clamped inside the window so the first / last day's twist
    /// completes (a half twist would leave the grey back showing at an end).
    func twist(at s: Float) -> Float {
        guard count > 1 else { return 0 }
        let d = s * Float(count - 1)
        var th: Float = 0
        for (i, v) in totals.enumerated() where v == 0 {
            let c = min(max(Float(i), 0.5), Float(count) - 1.5)
            let x = min(1, max(0, d - c + 0.5))
            th += 2 * .pi * x * x * (3 - 2 * x)
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
    /// turned by the twist about the tangent. (Frenet frames flip and crumple
    /// on this spine; the Z projection stays calm.)
    func sample(_ s: Float) -> Sample {
        let dt: Float = 1e-3
        let p = Self.spine(s)
        let tg = simd_normalize(Self.spine(min(1, s + dt)) - Self.spine(max(0, s - dt)))
        let z = SIMD3<Float>(0, 0, 1)
        let w0 = simd_normalize(z - tg * simd_dot(tg, z))
        let xw = simd_cross(tg, w0)                 // in-screen width direction
        let th = twist(at: s)
        let w = simd_normalize(xw * cos(th) + w0 * sin(th))
        let n = simd_normalize(simd_cross(w, tg))   // faces +Z where untwisted
        return Sample(p: p, w: w, n: n, half: width(at: s) / 2)
    }

    // MARK: Meshes

    /// The paper strip, one side. `front` = white side (normals +n, CCW seen
    /// from +n); the back is the same strip with flipped winding + normals.
    func paperMesh(front: Bool) throws -> MeshResource {
        let samples = (0...Self.segments).map { sample(Float($0) / Float(Self.segments)) }
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        positions.reserveCapacity(samples.count * 2)
        normals.reserveCapacity(samples.count * 2)
        for sm in samples {
            let n = front ? sm.n : -sm.n
            positions.append(sm.p + sm.w * sm.half)   // a (left)
            positions.append(sm.p - sm.w * sm.half)   // b (right)
            normals.append(n); normals.append(n)
        }
        var indices: [UInt32] = []
        indices.reserveCapacity(Self.segments * 6)
        for i in 0..<Self.segments {
            let a0 = UInt32(i * 2), b0 = a0 + 1, a1 = a0 + 2, b1 = a0 + 3
            if front {
                indices += [a0, a1, b0, b0, a1, b1]
            } else {
                indices += [a0, b0, a1, b0, b1, a1]
            }
        }
        var desc = MeshDescriptor(name: front ? "ribbonFront" : "ribbonBack")
        desc.positions = MeshBuffers.Positions(positions)
        desc.normals = MeshBuffers.Normals(normals)
        desc.primitives = .triangles(indices)
        return try MeshResource.generate(from: [desc])
    }

    /// The two ink edge lines (prototype `THREE.Line`s) as thin square tubes.
    func edgeMesh(radius r: Float = 0.006) throws -> MeshResource {
        let samples = (0...Self.segments).map { sample(Float($0) / Float(Self.segments)) }
        var positions: [SIMD3<Float>] = []
        var indices: [UInt32] = []
        for side: Float in [1, -1] {
            let base = UInt32(positions.count)
            for sm in samples {
                let e = sm.p + sm.w * (sm.half * side)
                positions += [e + sm.n * r, e + sm.w * r, e - sm.n * r, e - sm.w * r]
            }
            for i in 0..<Self.segments {
                let r0 = base + UInt32(i * 4), r1 = r0 + 4
                for k in 0..<UInt32(4) {
                    let k2 = (k + 1) % 4
                    indices += [r0 + k, r1 + k, r0 + k2, r0 + k2, r1 + k, r1 + k2]
                }
            }
        }
        var desc = MeshDescriptor(name: "ribbonEdges")
        desc.positions = MeshBuffers.Positions(positions)
        desc.primitives = .triangles(indices)
        return try MeshResource.generate(from: [desc])
    }

    // MARK: Projection

    /// Screen y (pt, from the view's top) of a ribbon-local point when the
    /// ribbon is turned `angle` radians about Y, for a view `height` tall.
    static func screenY(of p: SIMD3<Float>, angle: Float, height: CGFloat) -> CGFloat {
        let zr = -p.x * sin(angle) + p.z * cos(angle)
        let ndc = p.y / ((cameraZ - zr) * tan(fovDegrees / 2 * .pi / 180))
        return CGFloat(1 - ndc) / 2 * height
    }

    /// The day whose spine point projects closest to screen `y`.
    func day(nearestScreenY y: CGFloat, angle: Float, height: CGFloat) -> Int {
        guard count > 0 else { return 0 }
        var best = 0
        var bestD = CGFloat.greatestFiniteMagnitude
        for i in 0..<count {
            let d = abs(Self.screenY(of: Self.spine(s(ofDay: i)), angle: angle, height: height) - y)
            if d < bestD { bestD = d; best = i }
        }
        return best
    }
}

// MARK: - Motion controller

/// Per-frame state shared by the RealityKit update loop and the SwiftUI
/// overlay (ribline). A plain reference type: frames don't go through SwiftUI.
final class RibbonMotion {
    /// Turn requested by horizontal drag (clamped ±1.2, back to 0 on release).
    var turnTarget: Float = 0
    /// Eased turn.
    private(set) var turn: Float = 0
    private var time: Float = 0
    var reduceMotion = false

    weak var root: Entity?
    weak var marker: Entity?
    var subscription: EventSubscription?

    /// Total Y rotation this frame: turn + gentle sway (no spin).
    var angle: Float { turn + (reduceMotion ? 0 : sin(time * 0.5) * 0.25) }

    func tick(_ dt: Float) {
        time += dt
        if reduceMotion {
            turn = turnTarget
        } else {
            // Prototype: rot += (target - rot) * 0.06 per 60 Hz frame.
            let k = 1 - pow(1 - 0.06, dt * 60)
            turn += (turnTarget - turn) * k
        }
        root?.orientation = simd_quatf(angle: angle, axis: [0, 1, 0])
    }

    /// Moves the marker bar across the ribbon to day `i`.
    func select(_ i: Int, in geo: RibbonGeometry) {
        let s = geo.s(ofDay: i)
        marker?.position = RibbonGeometry.spine(s)
        marker?.scale = [max(0.5, geo.width(at: s) + 0.5), 1, 1]
    }
}

// MARK: - RealityView

/// The 3D ribbon. Rebuild by changing `.id` when the data changes.
struct RibbonScene: View {
    let geometry: RibbonGeometry
    let motion: RibbonMotion
    let selected: Int

    var body: some View {
        RealityView { content in
            content.camera = .virtual

            let camera = PerspectiveCamera()
            camera.camera.fieldOfViewInDegrees = RibbonGeometry.fovDegrees
            camera.camera.fieldOfViewOrientation = .vertical
            camera.position = [0, 0, RibbonGeometry.cameraZ]
            content.add(camera)

            // Key light (prototype DirectionalLight at (-2, 4, 5)).
            let key = DirectionalLight()
            key.light.intensity = 2600
            key.look(at: .zero, from: [-2, 4, 5], relativeTo: nil)
            content.add(key)

            let root = Entity()
            if let front = try? geometry.paperMesh(front: true),
               let back = try? geometry.paperMesh(front: false),
               let edges = try? geometry.edgeMesh() {
                root.addChild(ModelEntity(mesh: front, materials: [Self.paper(white: true)]))
                root.addChild(ModelEntity(mesh: back, materials: [Self.paper(white: false)]))
                var ink = UnlitMaterial(color: UIColor(AppColor.ink))
                ink.faceCulling = .none
                root.addChild(ModelEntity(mesh: edges, materials: [ink]))
            }
            // Selection marker: a thin bar across the ribbon at the chosen day.
            let marker = ModelEntity(mesh: .generateBox(size: [1, 0.012, 0.012]),
                                     materials: [UnlitMaterial(color: UIColor(AppColor.ink))])
            root.addChild(marker)
            content.add(root)

            motion.root = root
            motion.marker = marker
            motion.select(selected, in: geometry)
            motion.tick(0)
            motion.subscription = content.subscribe(to: SceneEvents.Update.self) { event in
                motion.tick(Float(event.deltaTime))
            }
        } update: { _ in
            motion.select(selected, in: geometry)
        }
    }

    /// Two-sided paper: white front, grey (g2) back. Faint self-light stands
    /// in for the prototype's hemisphere fill so shadowed folds stay paper,
    /// not black.
    private static func paper(white: Bool) -> PhysicallyBasedMaterial {
        var m = PhysicallyBasedMaterial()
        let base = white ? UIColor.white : UIColor(AppColor.g2)
        m.baseColor = .init(tint: base)
        m.roughness = .init(floatLiteral: white ? 0.6 : 0.7)
        m.metallic = .init(floatLiteral: 0)
        m.emissiveColor = .init(color: base)
        m.emissiveIntensity = white ? 0.45 : 0.35
        return m
    }
}
