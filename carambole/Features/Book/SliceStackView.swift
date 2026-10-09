//
//  SliceStackView.swift
//  carambole
//
//  The book's table of contents — design/motion.html "06 · Tranches". Cut a
//  carambole and every slice is a star: the 25 modules are 25 thin star slices
//  on an ink skewer, module 01 at the bottom. Form carries state:
//    chrome            = maîtrisé (module complete)
//    white paper       = en cours (some elements introduced)
//    faint glass + grey outline = à venir / verrouillé
//  The selected slice gets an ink outline.
//
//  Use: slide a finger up/down the stack to choose a module (selection haptic per
//  slice) — the finger maps onto the CLOSED stack's screen extent, so fanning open
//  never makes the pick jitter. The stack fans open above the selection; the
//  selected slice lifts half, slides out and slowly spins. Drag sideways to turn
//  the stack. Tap (no drag) or `Ouvrir →` opens the 02 module page: the slice
//  lifts toward the camera and tilts to face it, then the page is pushed.
//  Reduce Motion: no sway / spin, positions snap.
//

import RealityKit
import SwiftUI

/// Per-module slice form.
enum SliceKind: Equatable {
    case mastered
    case inProgress(Double)   // fraction maîtrisé within the module
    case toCome               // unlocked, nothing introduced yet
    case locked

    var isLocked: Bool { self == .locked }
}

struct SliceStackView: View {
    @ObservedObject var viewModel: BookViewModel
    /// Module index to select first; nil = the newest unlocked module.
    var initialSelection: Int? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var controller = SliceStackController()
    @State private var selected: Int?
    @State private var opening = false
    @State private var openedModule: CourseModule?
    @State private var showModule = false

    // Drag bookkeeping.
    @State private var dragStart: CGPoint?
    @State private var lastX: CGFloat = 0
    @State private var moved: CGFloat = 0

    private var modules: [CourseModule] {
        viewModel.book.modules.sorted { $0.sortOrder < $1.sortOrder }
    }

    private var kinds: [SliceKind] {
        modules.map { m in
            switch viewModel.state(for: m) {
            case .done: return .mastered
            case .locked: return .locked
            case .current:
                guard viewModel.seenCount(in: m) > 0 else { return .toCome }
                return .inProgress(Double(viewModel.masteredCount(in: m)) / Double(max(1, m.elements.count)))
            }
        }
    }

    /// Default = the newest unlocked module (the one Apprendre drills).
    private var defaultIndex: Int {
        if let m = viewModel.newestUnlockedModule(), let i = modules.firstIndex(where: { $0.id == m.id }) {
            return i
        }
        return 0
    }

    private var sel: Int { min(selected ?? defaultIndex, max(0, modules.count - 1)) }

    private var shortTitle: String {
        let t = viewModel.book.title
        if let r = t.range(of: "— ") { return String(t[r.upperBound...]) }
        return t
    }

    var body: some View {
        ZStack {
            AppColor.paper.ignoresSafeArea()

            SliceStackScene(kinds: kinds, selected: sel, controller: controller)
                .ignoresSafeArea()

            GeometryReader { geo in
                let h = geo.size.height
                Rectangle()
                    .fill(AppColor.ink)
                    .frame(width: 54, height: 1)
                    .position(x: Spacing.screenH + 27, y: SliceStackController.tickY(index: sel, count: modules.count, height: h))
                    .animation(reduceMotion ? nil : .spring(duration: 0.45, bounce: 0), value: sel)
                    .opacity(opening ? 0 : 1)
                    .allowsHitTesting(false)
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(stackGesture(height: h))
                    .accessibilityHidden(true)
            }
            .ignoresSafeArea()

            chrome
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.3), value: opening)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $showModule) {
            if let m = openedModule {
                ModuleDetailView(module: m, viewModel: viewModel)
            }
        }
        .onChange(of: showModule) { _, shown in
            if !shown {
                opening = false
                controller.setOpening(false)
            }
        }
        .onAppear {
            controller.reduceMotion = reduceMotion
            if selected == nil, let i = initialSelection { selected = i }
        }
    }

    // MARK: - Edge type + readout

    private var chrome: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Button { dismiss() } label: {
                    Text("‹ \(shortTitle)").uppercaseLabel(AppColor.ink)
                        .padding(.vertical, 8).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.vertical, -8)
                .accessibilityLabel("Retour au livre")
                Spacer()
                Text("\(modules.count) modules").uppercaseLabel()
            }
            Text("\(modules.count) ↑").uppercaseLabel()
                .padding(.top, 21)
                .accessibilityHidden(true)

            Spacer(minLength: 0)

            readout
                .opacity(opening ? 0 : 1)
                .allowsHitTesting(false)
                .padding(.bottom, 64 - 30 - 13)

            HStack(alignment: .firstTextBaseline) {
                Button(action: open) {
                    Text("Ouvrir →")
                        .uppercaseLabel(isLocked ? AppColor.g3 : AppColor.ink)
                        .padding(.vertical, 8).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.vertical, -8)
                .disabled(isLocked || modules.isEmpty)
                .accessibilityLabel(modules.isEmpty ? "Ouvrir" : "Ouvrir le module \(sel + 1)")
                Spacer()
                Text("Glisser ↕\u{FE0E} · toucher pour ouvrir").uppercaseLabel()
                    .accessibilityHidden(true)
            }
            .opacity(opening ? 0 : 1)
        }
        .padding(.horizontal, Spacing.screenH)
        .padding(.top, 16)
        .padding(.bottom, 30)
        .ignoresSafeArea(edges: .bottom)
    }

    private var isLocked: Bool { kinds.indices.contains(sel) && kinds[sel].isLocked }

    @ViewBuilder
    private var readout: some View {
        if modules.indices.contains(sel) {
            let m = modules[sel]
            VStack(alignment: .leading, spacing: 0) {
                Text(String(format: "%02d", sel + 1))
                    .font(.display(size: 64, wght: 200))
                    .tracking(-3.2)
                    .foregroundColor(AppColor.ink)
                    .frame(height: 58)
                    .fixedSize()
                Text(m.title)
                    .font(.display(size: 22, wght: 300))
                    .tracking(-0.44)
                    .foregroundColor(AppColor.ink)
                    .lineLimit(2)
                    .padding(.top, 10)
                status(kinds[sel])
                    .frame(height: 18)
                    .padding(.top, 8)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.updatesFrequently)
        }
    }

    @ViewBuilder
    private func status(_ kind: SliceKind) -> some View {
        switch kind {
        case .mastered:
            Text("Maîtrisé").uppercaseLabel(AppColor.ink)
        case .inProgress(let p):
            HStack(spacing: 8) {
                ProgressRing(progress: p, size: 18, lineWidth: 2.5)
                Text("En cours · \(Int((p * 100).rounded())) %").uppercaseLabel(AppColor.ink)
            }
        case .toCome:
            Text("À venir").uppercaseLabel()
        case .locked:
            Text("Verrouillé").uppercaseLabel()
        }
    }

    // MARK: - Interaction

    private func stackGesture(height: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { v in
                guard !opening else { return }
                if dragStart == nil {
                    dragStart = v.startLocation
                    lastX = v.startLocation.x
                    moved = 0
                    if v.startLocation.x >= 24 { pick(y: v.startLocation.y, height: height) }
                }
                guard let s = dragStart, s.x >= 24 else { return }   // edge = swipe-back
                moved = max(moved, abs(v.location.y - s.y), abs(v.location.x - s.x))
                pick(y: v.location.y, height: height)
                controller.turn(by: v.location.x - lastX)
                lastX = v.location.x
            }
            .onEnded { v in
                defer { dragStart = nil }
                guard let s = dragStart, !opening else { return }
                if s.x < 24 {
                    if v.translation.width > 60, abs(v.translation.width) > abs(v.translation.height) { dismiss() }
                    return
                }
                if moved < 6 { open() }
            }
    }

    private func pick(y: CGFloat, height: CGFloat) {
        guard !modules.isEmpty else { return }
        let i = SliceStackController.index(atScreenY: y, count: modules.count, height: height)
        if i != sel {
            selected = i
            UISelectionFeedbackGenerator().selectionChanged()
        }
    }

    private func open() {
        guard !opening, modules.indices.contains(sel), !isLocked else { return }
        openedModule = modules[sel]
        opening = true
        controller.setOpening(true)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.05 : 0.7)) {
            showModule = true
        }
    }
}

// MARK: - RealityView wrapper

private struct SliceStackScene: View {
    let kinds: [SliceKind]
    let selected: Int
    let controller: SliceStackController

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        RealityView { content in
            controller.build(into: &content, count: kinds.count)
            controller.configure(kinds: kinds, selected: selected)
        } update: { _ in
            controller.reduceMotion = reduceMotion
            controller.configure(kinds: kinds, selected: selected)
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Scene controller

/// Scene graph + fan / spin / open state for the 06 stack. Not observable: the
/// per-frame RealityKit update drives motion; SwiftUI only pushes selection,
/// slice kinds, turn deltas and the opening flag.
@MainActor
final class SliceStackController {
    var reduceMotion = false

    // motion.html 06 constants.
    static let gap: Float = 0.17
    static let openLift: Float = 0.36
    private static let sliceScale: Float = 0.55
    private static let projection = StarCameraProjection(eye: [0, 2.2, 13.4], target: [0, -0.3, 0], fovDegrees: 30)

    private struct SliceState {
        var y: Float
        var x: Float = 0
        var z: Float = 0
        var tilt: Float = 0
        var spin: Float = 0
    }

    private let stack = Entity()
    private let rod = ModelEntity()
    private var slices: [Entity] = []
    private var bodies: [ModelEntity] = []
    private var edges: [ModelEntity] = []
    private var states: [SliceState] = []
    private var kinds: [SliceKind] = []
    private var selected = 0
    private var count = 0
    private var built = false
    private var subscription: EventSubscription?

    private var opening = false
    private var openingElapsed: Float = 0
    private var rotTarget: Float = 0
    private var rot: Float = 0
    private var time: Float = 0

    // Materials.
    private let chrome = StarMaterial.chrome(roughness: 0.2)
    private let paper = StarMaterial.paper()
    private let glass = StarMaterial.flat(1, opacity: 0.3)
    private let lineInk = StarMaterial.flat(0.08)
    private let lineGrey = StarMaterial.flat(0.74)

    private var y0: Float { Self.baseY(count) }

    // MARK: Build

    func build(into content: inout RealityViewCameraContent, count: Int) {
        guard !built else { return }
        built = true
        self.count = count

        let camera = PerspectiveCamera()
        camera.camera.fieldOfViewInDegrees = Self.projection.fovDegrees
        camera.position = Self.projection.eye
        camera.orientation = Self.projection.orientation
        content.add(camera)

        let light = StudioEnvironment.lightEntity(intensityExponent: 1.0)
        if let light { content.add(light) }
        let key = DirectionalLight()
        key.light.intensity = 2200
        key.look(at: .zero, from: [3, 6, 5], relativeTo: nil)
        content.add(key)

        // Skewer.
        rod.model = ModelComponent(mesh: .generateCylinder(height: Self.gap * Float(count) + 1.3, radius: 0.014),
                                   materials: [StarMaterial.ink(metallic: 0, roughness: 0.4)])
        rod.position.y = y0 + Self.gap * Float(count - 1) / 2 + 0.25
        stack.addChild(rod)

        // Slices: one shared mesh, lying flat (three.js rotateX(-π/2), scale .55 in x/z).
        let mesh = try? CaramboleStarMesh.sliceMesh()
        // Outline of the top face only — built in the extrusion's own path space and
        // parented to the same holder, so it sits exactly on the body whatever the
        // extruder's axis conventions.
        let topZ = (mesh?.bounds.max.z ?? 0.055) + 0.002
        let outline = CaramboleStarMesh.outlinePoints(valley: CaramboleStarMesh.sliceValley, perLobe: 8)
            .map { SIMD3<Float>(Float($0.x), Float($0.y), topZ) }
        let edgeMesh = try? CaramboleStarMesh.tubeLoop(outline, radius: 0.0035 / Self.sliceScale,
                                                       sides: 5, up: [0, 0, 1])

        for i in 0..<count {
            let g = Entity()
            let body: ModelEntity
            let edge = ModelEntity()
            if let edgeMesh { edge.model = ModelComponent(mesh: edgeMesh, materials: [lineGrey]) }
            if let mesh {
                let c = CaramboleStarMesh.centred(mesh, materials: [glass])
                c.holder.orientation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
                c.holder.scale = [Self.sliceScale, Self.sliceScale, 1]
                edge.position = c.model.position
                c.holder.addChild(edge)
                g.addChild(c.holder)
                body = c.model
            } else {
                body = ModelEntity()
            }
            let y = y0 + Float(i) * Self.gap
            g.position.y = y
            stack.addChild(g)
            slices.append(g)
            bodies.append(body)
            edges.append(edge)
            states.append(SliceState(y: y))
        }
        content.add(stack)
        if let light { StudioEnvironment.receive(stack, from: light) }

        subscription = content.subscribe(to: SceneEvents.Update.self) { [weak self] event in
            MainActor.assumeIsolated { self?.tick(Float(event.deltaTime)) }
        }
    }

    /// Applies slice forms + the selection outline. Cheap when nothing changed.
    func configure(kinds newKinds: [SliceKind], selected newSelected: Int) {
        guard built, newKinds.count == count else { return }
        if newKinds != kinds {
            kinds = newKinds
            for i in 0..<count {
                switch kinds[i] {
                case .mastered: bodies[i].model?.materials = [chrome]
                case .inProgress: bodies[i].model?.materials = [paper]
                case .toCome, .locked: bodies[i].model?.materials = [glass]
                }
            }
        }
        selected = newSelected
        for i in 0..<count {
            let isSel = i == selected
            edges[i].model?.materials = [isSel || isInProgress(i) ? lineInk : lineGrey]
            edges[i].isEnabled = isSel || kinds[i] != .mastered
        }
    }

    private func isInProgress(_ i: Int) -> Bool {
        if case .inProgress = kinds[i] { return true }
        return false
    }

    // MARK: Input

    /// Horizontal drag turns the stack (motion.html: ×.012, clamped ±1.4).
    func turn(by dx: CGFloat) {
        rotTarget = min(1.4, max(-1.4, rotTarget + Float(dx) * 0.012))
    }

    func setOpening(_ on: Bool) {
        opening = on
        openingElapsed = 0
    }

    /// Finger y → module index over the CLOSED stack's screen extent.
    static func index(atScreenY y: CGFloat, count: Int, height: CGFloat) -> Int {
        guard count > 1 else { return 0 }
        let top = screenY(baseY(count) + Float(count - 1) * gap + openLift, height: height)
        let bottom = screenY(baseY(count), height: height)
        let t = (bottom - y) / max(1, bottom - top)
        return max(0, min(count - 1, Int((t * CGFloat(count - 1)).rounded())))
    }

    /// Screen y of the selected slice's resting (fanned) height — the 54pt tick.
    static func tickY(index: Int, count: Int, height: CGFloat) -> CGFloat {
        screenY(baseY(count) + Float(index) * gap + openLift / 2, height: height)
    }

    /// Module 01's resting height (three.js `Y0`).
    static func baseY(_ count: Int) -> Float { -gap * Float(max(count, 1) - 1) / 2 - 0.2 }

    private static func screenY(_ worldY: Float, height: CGFloat) -> CGFloat {
        projection.screenY([0, worldY, 0], height: height)
    }

    // MARK: Frame

    private func tick(_ dt: Float) {
        guard count > 0 else { return }
        let f = min(dt * 60, 3)
        time += dt
        if opening { openingElapsed += dt }
        let k: Float = reduceMotion ? 1 : 1 - pow(1 - 0.14, f)

        for i in 0..<count {
            var u = states[i]
            let lift = opening && i == selected
            let ty: Float = lift ? 0.6
                : y0 + Float(i) * Self.gap + (i > selected ? Self.openLift : i == selected ? Self.openLift / 2 : 0)
            let tx: Float = lift ? 0 : (i == selected ? 0.4 : 0)
            u.y += (ty - u.y) * k
            u.x += (tx - u.x) * k
            u.z += ((lift ? 3.2 : 0) - u.z) * k
            u.tilt += ((lift ? 1.05 : 0) - u.tilt) * k
            if i == selected && !reduceMotion { u.spin += 0.012 * f } else { u.spin *= pow(0.9, f) }
            states[i] = u

            let s = slices[i]
            s.position = [u.x, u.y, u.z]
            s.orientation = simd_quatf(angle: u.tilt, axis: [1, 0, 0])
                * simd_quatf(angle: Float(i) * 0.045 + u.spin, axis: [0, 1, 0])
            s.isEnabled = !opening || i == selected || openingElapsed < 0.25
        }
        rod.isEnabled = !opening
        rot += (rotTarget - rot) * (reduceMotion ? 1 : 1 - pow(1 - 0.06, f))
        let sway: Float = reduceMotion ? 0 : sin(time * 0.4) * 0.18
        stack.orientation = simd_quatf(angle: rot + sway, axis: [0, 1, 0])
    }
}
