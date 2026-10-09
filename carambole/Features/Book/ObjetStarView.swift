//
//  ObjetStarView.swift
//  carambole
//
//  The 01 Objet scene (design/motion.html, "01 · chrome carambole + orbit ring"):
//  a chrome extruded carambole star turning slowly in the middle of the book
//  home, with the book's progress as a 3D ring orbiting it — a faint full track,
//  a dark arc for maîtrisé, a lighter arc for en cours and one bead at the end of
//  the maîtrisé arc. Drag turns the star (with inertia); it bobs gently.
//  Reduce Motion: no spin, no bob, no orbit, no inertia.
//
//  Motion constants are the prototype's per-frame values (60 fps) converted to
//  per-second with `dt * 60`.
//

import RealityKit
import SwiftUI

// MARK: - View

struct ObjetStarView: View {
    /// Fraction of the book maîtrisé (0…1) — the dark arc.
    let mastered: Double
    /// Fraction en cours (0…1) — the lighter arc after it.
    let inProgress: Double
    /// Owned by the parent so its drag gesture can steer the star.
    let controller: ObjetStarController
    /// Colour palette for the star body, ring and bead.
    var palette: AppPalette = .current

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        RealityView { content in
            controller.build(into: &content)
            controller.setPalette(palette)
            controller.setProgress(mastered: mastered, inProgress: inProgress)
        } update: { _ in
            controller.reduceMotion = reduceMotion
            controller.setPalette(palette)
            controller.setProgress(mastered: mastered, inProgress: inProgress)
        }
        .onAppear { controller.reduceMotion = reduceMotion }
        .accessibilityHidden(true)
    }
}

// MARK: - Scene controller

/// Holds the scene graph and the turn / inertia state. Not observable: SwiftUI
/// never re-renders from it — RealityKit's per-frame update drives the motion.
@MainActor
final class ObjetStarController {
    var reduceMotion = false

    // three.js scene constants (motion.html 01).
    private static let ringRadius: Float = 1.32
    private static let restSpin: Float = 0.006        // rad / frame at rest
    private static let dragGain: Float = 0.004        // rad per point dragged

    private let group = Entity()
    private let starPivot = Entity()
    private let ring = Entity()
    private let arc = ModelEntity()
    private let enCours = ModelEntity()
    private let bead = ModelEntity()
    private let track = ModelEntity()
    private var starModel: ModelEntity?
    /// Camera, lights and `group`: re-added when a new RealityView takes the
    /// scene over (the book removes the view while Today is pushed).
    private var roots: [Entity] = []
    private var subscription: EventSubscription?
    private var built = false
    private var shownPalette: AppPalette?

    // Turn state (per-frame units, as in the prototype).
    private var rotX: Float = 0.35
    private var rotY: Float = 0
    private var vx: Float = 0
    private var vy: Float = restSpin
    private var ringSpin: Float = 0
    private var time: Float = 0
    private var dragging = false
    private var pending = CGSize.zero
    private var shownProgress: (Double, Double) = (-1, -1)

    // MARK: Build

    func build(into content: inout RealityViewCameraContent) {
        if !built { makeScene() }
        for e in roots { content.add(e) }
        subscription = content.subscribe(to: SceneEvents.Update.self) { [weak self] event in
            MainActor.assumeIsolated { self?.tick(Float(event.deltaTime)) }
        }
    }

    private func makeScene() {
        built = true

        let camera = PerspectiveCamera()
        camera.camera.fieldOfViewInDegrees = 30
        camera.position = [0, 0, 11.5]
        roots.append(camera)

        let light = StudioEnvironment.lightEntity(intensityExponent: 1.1)
        if let light { roots.append(light) }

        let key = DirectionalLight()
        key.light.intensity = 2600
        key.look(at: .zero, from: [3, 4, 6], relativeTo: nil)
        roots.append(key)

        // Star: centred extrusion, scale .78, tilted by `rotX`.
        if let mesh = try? CaramboleStarMesh.objetMesh() {
            let star = CaramboleStarMesh.centred(mesh, materials: [StarMaterial.chrome()])
            starPivot.addChild(star.holder)
            starModel = star.model
        }
        starPivot.scale = SIMD3(repeating: 0.78)
        group.addChild(starPivot)

        // Orbit ring: faint full track + arcs + bead.
        if let trackMesh = try? CaramboleStarMesh.torusArc(radius: Self.ringRadius, tube: 0.012,
                                                           start: 0, sweep: 2 * .pi, radialSegments: 8) {
            track.model = ModelComponent(mesh: trackMesh, materials: [StarMaterial.flat(0.60, opacity: 0.55)])
        }
        ring.addChild(track)
        arc.model = ModelComponent(mesh: .generateBox(size: 0.001), materials: [StarMaterial.ink()])
        enCours.model = ModelComponent(mesh: .generateBox(size: 0.001), materials: [StarMaterial.flat(0.74)])
        bead.model = ModelComponent(mesh: .generateSphere(radius: 0.09), materials: [StarMaterial.ink()])
        ring.addChild(enCours)
        ring.addChild(arc)
        ring.addChild(bead)
        group.addChild(ring)
        group.position.y = 0.1
        roots.append(group)

        if let light { StudioEnvironment.receive(group, from: light) }

        applyTransforms()
    }

    /// Swaps the star body, ring and bead materials to `palette`'s.
    func setPalette(_ palette: AppPalette) {
        guard built, shownPalette != palette else { return }
        shownPalette = palette
        let t = palette.theme
        starModel?.model?.materials = [StarMaterial.finish(t.star)]
        track.model?.materials = [StarMaterial.flat(hex: t.starTrack)]
        arc.model?.materials = [StarMaterial.lacquer(t.starArc)]
        enCours.model?.materials = [StarMaterial.flat(hex: t.starArcSoft)]
        bead.model?.materials = [StarMaterial.lacquer(t.starBead)]
    }

    /// Rebuilds the arc meshes when the bucket fractions change.
    func setProgress(mastered: Double, inProgress: Double) {
        let m = min(max(mastered, 0), 1), p = min(max(inProgress, 0), 1 - m)
        guard built, shownProgress != (m, p) else { return }
        shownProgress = (m, p)

        let top = Float.pi / 2
        let sweep = 2 * Float.pi * Float(m)
        if m > 0.002, let mesh = try? CaramboleStarMesh.torusArc(radius: Self.ringRadius, tube: 0.045,
                                                                 start: top, sweep: sweep, radialSegments: 16) {
            arc.model?.mesh = mesh
            arc.isEnabled = true
        } else {
            arc.isEnabled = false
        }
        if p > 0.002, let mesh = try? CaramboleStarMesh.torusArc(radius: Self.ringRadius, tube: 0.024,
                                                                 start: top + sweep,
                                                                 sweep: 2 * .pi * Float(p), radialSegments: 10) {
            enCours.model?.mesh = mesh
            enCours.isEnabled = true
        } else {
            enCours.isEnabled = false
        }
        let a = top + sweep
        bead.position = [cos(a) * Self.ringRadius, sin(a) * Self.ringRadius, 0]
    }

    // MARK: Drag (driven by the parent's DragGesture)

    func dragChanged(by delta: CGSize) {
        dragging = true
        pending.width += delta.width
        pending.height += delta.height
    }

    func dragEnded() {
        dragging = false
        if reduceMotion { vx = 0; vy = 0 }
    }

    // MARK: Frame

    private func tick(_ dt: Float) {
        let f = min(dt * 60, 3)   // prototype frames elapsed
        time += dt
        if dragging {
            let dx = Float(pending.width) * Self.dragGain
            let dy = Float(pending.height) * Self.dragGain
            pending = .zero
            rotY += dx; rotX += dy
            if f > 0 { vy = dx / f; vx = dy / f }
        } else if reduceMotion {
            vx = 0; vy = 0
        } else {
            rotY += vy * f; rotX += vx * f
            vy += (Self.restSpin - vy) * (1 - pow(1 - 0.02, f))
            vx *= pow(0.95, f)
            rotX *= pow(0.985, f)
            ringSpin += 0.0025 * f
        }
        applyTransforms()
    }

    private func applyTransforms() {
        starPivot.orientation = simd_quatf(angle: rotX, axis: [1, 0, 0]) * simd_quatf(angle: rotY, axis: [0, 1, 0])
        ring.orientation = simd_quatf(angle: 1.18, axis: [1, 0, 0])
            * simd_quatf(angle: 0.22, axis: [0, 1, 0])
            * simd_quatf(angle: ringSpin, axis: [0, 0, 1])
        group.position.y = reduceMotion ? 0.1 : 0.1 + sin(time * 0.9) * 0.06
    }
}
