//
//  StarLoopView.swift
//  carambole
//
//  The 01 Objet star without a live 3D scene: the star turning is a
//  pre-rendered HEVC-with-alpha loop (`star_<palette>.mov`, made by
//  `StarVideoRenderer` from the same mesh, materials and lights), and the
//  orbit ring, which shows the learner's live progress, is drawn in 2D around
//  it: the back half under the video, the front half over it. The whole group
//  bobs as one.
//
//  Why: every new RealityView costs ~100 ms on the main thread when it is
//  created (measured on device), and the book home and the colour page each
//  create one on push, so every push froze. A video layer from an
//  already-loaded player shows at once and costs almost nothing.
//
//  Reduce Motion: the video stays on its first frame, no bob, no ring spin.
//

import AVFoundation
import simd
import SwiftUI
import UIKit

struct StarLoopView: View {
    /// Fraction of the book maîtrisé (0…1) — the dark arc.
    let mastered: Double
    /// Fraction en cours (0…1) — the lighter arc after it.
    let inProgress: Double
    var palette: AppPalette = .current
    /// False while a page covers the star: the video pauses and the ring
    /// stops redrawing, but the view stays mounted, so coming back is instant.
    var active = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var visiblePalette: AppPalette?

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            TimelineView(.animation(paused: !active || reduceMotion)) { context in
                let t = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
                let ring = OrbitRing(mastered: mastered, inProgress: inProgress, theme: palette.theme,
                                     size: size, time: t)
                ZStack(alignment: .topLeading) {
                    Canvas { ctx, _ in ring.draw(in: &ctx, front: false) }
                    StarVideoLayer(palette: palette, playing: active && !reduceMotion) {
                        visiblePalette = palette
                    }
                        .frame(width: ring.videoSide, height: ring.videoSide)
                        .position(ring.starCentre)
                    Canvas { ctx, _ in ring.draw(in: &ctx, front: true) }
                }
                // Keep the orbit and video together while the first image loads.
                // Flattened first: an opacity on the bare ZStack fades each
                // layer on its own, so mid-fade the star was see-through and
                // the back of the orbit showed through it.
                .compositingGroup()
                .opacity(visiblePalette == palette ? 1 : 0)
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Ring (2D projection of the old 3D ring)

/// The orbit ring of `ObjetStarController` projected with the live scene's
/// camera: a faint full track and a bead leading the maîtrisé arc, with the
/// en-cours arc behind that. Tube widths follow perspective.
private struct OrbitRing {
    let mastered: Double
    let inProgress: Double
    let theme: AppTheme
    let size: CGSize
    let time: Double

    private typealias G = StarVideoGeometry

    private var focal: Double { G.focal(height: size.height) }
    /// `time` is seconds since 2001 (~8 × 10⁸). A Float holds that only to the
    /// nearest 64 s, so each phase is reduced to one period in Double before it
    /// becomes a Float. `Float(time)` here froze the bob for 64 s and then
    /// jumped the star and ring together by up to 17 pt.
    private var bob: Float {
        let period = 2 * Double.pi / Double(G.bobRate)
        return sin(Float(time.truncatingRemainder(dividingBy: period)) * G.bobRate) * G.bobAmplitude
    }
    private var spin: Float {
        let period = 2 * Double.pi / Double(G.ringSpinRate)
        return Float(time.truncatingRemainder(dividingBy: period)) * G.ringSpinRate
    }
    private var orientation: simd_quatf { G.ringTilt * simd_quatf(angle: spin, axis: [0, 0, 1]) }

    /// Screen side of the square star video.
    var videoSide: CGFloat { CGFloat(Double(G.worldExtent) * focal / Double(G.cameraZ)) }
    /// Screen position of the star's centre (group origin).
    var starCentre: CGPoint { project([0, G.groupY + bob, 0]).point }

    private func project(_ p: SIMD3<Float>) -> (point: CGPoint, scale: Double) {
        let d = Double(G.cameraZ - p.z)
        let s = focal / d
        return (CGPoint(x: size.width / 2 + Double(p.x) * s, y: size.height / 2 - Double(p.y) * s), s)
    }

    /// One sample of a tube on screen, with the ring's direction there.
    private struct TubePoint {
        let point: CGPoint
        let width: Double
        let z: Float
        let dir: CGVector
    }

    /// The two ring angles where the ring passes through z = 0 (the star's
    /// plane), i.e. where it goes behind or in front of the star.
    private var crossings: [Float] {
        let a = orientation.act([1, 0, 0]).z, b = orientation.act([0, 1, 0]).z
        let u0 = atan2(-a, b)
        return [u0, u0 + .pi]
    }

    /// World position of ring angle `u` (radians, local to the ring).
    private func ringPoint(_ u: Float) -> SIMD3<Float> {
        let local = SIMD3<Float>(G.ringRadius * cos(u), G.ringRadius * sin(u), 0)
        return orientation.act(local) + SIMD3(0, G.groupY + bob, 0)
    }

    func draw(in ctx: inout GraphicsContext, front: Bool) {
        var tubeContext = ctx
        if front && !beadIsFront {
            // A rear bead stays behind the star, but the front tube cannot
            // paint over its projected sphere.
            tubeContext.clip(to: Path(ellipseIn: beadRect), options: .inverse)
        }
        let m = min(max(mastered, 0), 1), p = min(max(inProgress, 0), 1 - m)
        let top = Float.pi / 2
        let sweep = 2 * Float.pi * Float(m)
        // The track's front overlap at a crossing is shorter than the arcs',
        // so its seam edge sits inside the arc above, not on the arc's own
        // seam edge (two stacked antialiased edges let the pale track leak
        // through as a hairline).
        tube(&tubeContext, from: 0, sweep: 2 * .pi, radius: G.trackTube, color: Color(hex: theme.starTrack),
             gloss: false, front: front, seamPad: 0.01)
        // Bead first, then the maîtrisé arc right behind it, then en cours
        // (the ring spins toward larger angles, so both arcs trail the bead).
        // En cours runs on under the maîtrisé arc to the bead: one tube under
        // the other, with no seam where they meet.
        if p > 0.002 {
            tube(&tubeContext, from: top, sweep: 2 * .pi * Float(p) + sweep, radius: G.enCoursTube,
                 color: Color(hex: theme.starArcSoft), gloss: false, front: front)
        }
        if m > 0.002 {
            tube(&tubeContext, from: top + 2 * .pi * Float(p), sweep: sweep, radius: G.arcTube,
                 color: Color(hex: theme.starArc), gloss: true, front: front)
        }
        if beadIsFront == front { bead(&ctx) }
    }

    /// The bead leads both arcs, at the end of maîtrisé + en cours.
    private var beadPosition: SIMD3<Float> {
        let m = min(max(mastered, 0), 1), p = min(max(inProgress, 0), 1 - m)
        return ringPoint(Float.pi / 2 + 2 * Float.pi * Float(m + p))
    }

    private var beadIsFront: Bool { beadPosition.z >= 0 }

    private var beadRect: CGRect {
        let pr = project(beadPosition)
        let r = Double(G.beadRadius) * pr.scale
        return CGRect(x: pr.point.x - r, y: pr.point.y - r, width: 2 * r, height: 2 * r)
    }

    /// One arc of tube, only the parts on the requested side of the star (a
    /// piece whose middle has z ≥ 0 is in front). Each run on one side is a
    /// single filled band whose width follows perspective, so it reads as one
    /// smooth tube; the arc's true ends get round caps.
    private func tube(_ ctx: inout GraphicsContext, from start: Float, sweep: Float, radius: Float,
                      color: Color, gloss: Bool, front: Bool, seamPad: Float = 0.02) {
        let grid = max(8, Int(180 * sweep / (2 * .pi)))
        // Samples: an even grid plus the exact angles where the ring crosses
        // z = 0, so every tube (track, en cours, maîtrisé) splits front from
        // back on the same line. Cut at their own nearest grid step, a lower
        // tube's front piece started early and showed through the one above.
        // Each crossing also gets samples exactly `seamPad` either side (grid
        // samples in between dropped): the one-step front overlap below.
        let cuts = crossings.flatMap { c in (-2...2).map { c + Float($0) * 2 * .pi } }
        var angles = (0...grid).map { start + sweep * Float($0) / Float(grid) }
            .filter { u in cuts.allSatisfy { abs(u - $0) >= seamPad } || u == start || u == start + sweep }
        for c in cuts {
            for u in [c - seamPad, c, c + seamPad] where u > start + 1e-4 && u < start + sweep - 1e-4 {
                angles.append(u)
            }
        }
        angles.sort()
        let steps = angles.count - 1
        let points = angles.map { u -> TubePoint in
            let w = ringPoint(u)
            let pr = project(w)
            let a = project(ringPoint(u - 1e-3)).point, b = project(ringPoint(u + 1e-3)).point
            let len = max(hypot(b.x - a.x, b.y - a.y), 1e-9)
            return TubePoint(point: pr.point, width: Double(radius) * 2 * pr.scale, z: w.z,
                             dir: CGVector(dx: (b.x - a.x) / len, dy: (b.y - a.y) / len))
        }
        let closed = sweep >= 2 * .pi - 1e-4
        /// Point index `j`, wrapped round a closed ring, clamped on an arc.
        func at(_ j: Int) -> Int { closed ? (j % steps + steps) % steps : min(steps, max(0, j)) }
        /// Points `lo…hi`, padded by one step past each end (clamped on an
        /// arc), wrapped round a closed ring.
        func padded(_ lo: Int, _ hi: Int) -> [Int] {
            (closed ? Array(lo - 1...hi + 1) : Array(max(0, lo - 1)...min(steps, hi + 1))).map(at)
        }
        /// Draws the points `lo…hi` this side owns. At a crossing the front
        /// piece, body and gloss, runs one step over the back piece (the
        /// ring's sides are clear of the star), so the halves meet as an edge
        /// over matching paint: no gap, and the gloss is never doubled.
        func flush(_ lo: Int, _ hi: Int) {
            let run = front ? padded(lo, hi) : Array(lo...hi).map(at)
            ctx.fill(band(run, points, offset: 0, scale: 1), with: .color(color))
            if gloss {
                // Lacquer: a soft lighter streak along the upper edge.
                ctx.fill(band(run, points, offset: -0.16, scale: 0.45), with: .color(.white.opacity(0.09)))
            }
        }
        var lo: Int?
        for i in 0..<steps {
            if ((points[i].z + points[i + 1].z) / 2 >= 0) == front {
                if lo == nil { lo = i }
            } else if let l = lo {
                flush(l, i)
                lo = nil
            }
        }
        if let l = lo { flush(l, steps) }
        if !closed {
            for end in [points[0], points[steps]] where (end.z >= 0) == front {
                let r = end.width / 2
                ctx.fill(Path(ellipseIn: CGRect(x: end.point.x - r, y: end.point.y - r, width: 2 * r, height: 2 * r)),
                         with: .color(color))
            }
        }
    }

    /// A filled band through the point indices `run`: half-width
    /// `scale · width / 2` either side of the centre line, shifted toward
    /// screen up by up to `offset · width` (see below). Each point carries the
    /// ring's exact tangent, so two bands that share an end point cut it
    /// along the same line and meet edge to edge.
    private func band(_ run: [Int], _ points: [TubePoint], offset: Double, scale: Double) -> Path {
        var left: [CGPoint] = [], right: [CGPoint] = []
        for j in run {
            let p = points[j]
            let dx = p.dir.dx, dy = p.dir.dy
            let h = p.width * scale / 2
            // Shift across the tube by the part of `offset · width` (screen y)
            // that lies across it: full on a flat stretch, none where the tube
            // runs vertical. A plain y shift slid along a vertical tube and
            // folded the streak over itself at the ring's sides.
            let across = offset * p.width * dx
            let c = CGPoint(x: p.point.x - dy * across, y: p.point.y + dx * across)
            left.append(CGPoint(x: c.x - dy * h, y: c.y + dx * h))
            right.append(CGPoint(x: c.x + dy * h, y: c.y - dx * h))
        }
        var path = Path()
        path.addLines(left + right.reversed())
        path.closeSubpath()
        return path
    }

    private func bead(_ ctx: inout GraphicsContext) {
        let rect = beadRect
        let r = rect.width / 2
        ctx.fill(Path(ellipseIn: rect), with: .color(Color(hex: theme.starBead)))
        // Glossy highlight, upper left of centre.
        let hl = CGPoint(x: rect.midX - r * 0.25, y: rect.midY - r * 0.4)
        ctx.fill(Path(ellipseIn: rect), with: .radialGradient(
            Gradient(colors: [.white.opacity(0.55), .white.opacity(0)]),
            center: hl, startRadius: 0, endRadius: r * 0.55))
    }
}

// MARK: - Video layer

/// A single player item whose final frame remains visible during the seek
/// back to frame zero. A first-frame cover sits above the video only until
/// the player layer can display its own first frame.
private struct StarVideoLayer: UIViewRepresentable {
    let palette: AppPalette
    let playing: Bool
    let onVisibleFrame: () -> Void

    final class LayerView: UIView {
        let playerLayer = AVPlayerLayer()
        let firstFrame = CALayer()
        var readyObservation: NSKeyValueObservation?
        var palette: AppPalette?
        var holdsPlay = false
        var onVisibleFrame: (() -> Void)?
        var reportedVisibleFrame = false

        func reportVisibleFrame() {
            guard !reportedVisibleFrame else { return }
            reportedVisibleFrame = true
            let notify = onVisibleFrame
            DispatchQueue.main.async { notify?() }
        }

        override init(frame: CGRect) {
            super.init(frame: frame)
            isOpaque = false
            backgroundColor = .clear
            isUserInteractionEnabled = false
            playerLayer.videoGravity = .resizeAspect
            firstFrame.contentsGravity = .resizeAspect
            layer.addSublayer(playerLayer)
            layer.addSublayer(firstFrame)
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

        override func layoutSubviews() {
            super.layoutSubviews()
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            playerLayer.frame = bounds
            firstFrame.frame = bounds
            CATransaction.commit()
        }
    }

    func makeUIView(context: Context) -> LayerView { LayerView() }

    func updateUIView(_ v: LayerView, context: Context) {
        let players = StarLoopPlayers.shared
        v.onVisibleFrame = onVisibleFrame
        if v.palette != palette {
            if v.holdsPlay, let old = v.palette { players.release(old) }
            v.holdsPlay = false
            v.palette = palette
            v.readyObservation?.invalidate()
            v.firstFrame.contents = nil
            v.firstFrame.isHidden = false
            v.reportedVisibleFrame = false
            v.playerLayer.player = players.player(palette, fromStart: true)
            v.readyObservation = v.playerLayer.observe(\.isReadyForDisplay, options: [.initial, .new]) {
                [weak v] layer, _ in
                Task { @MainActor [weak v] in
                    guard v?.palette == palette else { return }
                    v?.firstFrame.isHidden = layer.isReadyForDisplay
                    if layer.isReadyForDisplay { v?.reportVisibleFrame() }
                }
            }
            players.poster(palette) { [weak v] image in
                guard v?.palette == palette else { return }
                v?.firstFrame.contents = image
                v?.reportVisibleFrame()
            }
        }
        if playing != v.holdsPlay {
            if playing { players.acquire(palette) } else { players.release(palette) }
            v.holdsPlay = playing
        }
    }

    static func dismantleUIView(_ v: LayerView, coordinator: ()) {
        if v.holdsPlay, let p = v.palette { StarLoopPlayers.shared.release(p) }
        v.holdsPlay = false
        v.readyObservation?.invalidate()
        v.playerLayer.player = nil
    }
}

// MARK: - Shared players

/// One persistent player item per palette. Rewind the item itself rather than
/// replacing queue items at each wrap.
@MainActor
final class StarLoopPlayers {
    static let shared = StarLoopPlayers()

    private struct Entry {
        let player: AVPlayer
        let observer: NSObjectProtocol
        var holders = 0
    }
    private var entries: [AppPalette: Entry] = [:]
    private var posters: [AppPalette: CGImage] = [:]
    private var decoding: Set<AppPalette> = []
    private var waiting: [AppPalette: [@MainActor (CGImage) -> Void]] = [:]

    func prewarm(_ palette: AppPalette = .current) {
        _ = player(palette, fromStart: false)
        for p in AppPalette.allCases { loadPoster(p) }
    }

    func poster(_ palette: AppPalette, _ apply: @escaping @MainActor (CGImage) -> Void) {
        if let image = posters[palette] { apply(image); return }
        loadPoster(palette, then: apply)
    }

    func player(_ palette: AppPalette, fromStart: Bool) -> AVPlayer? {
        if let e = entries[palette] {
            if fromStart, e.holders == 0 { e.player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero) }
            return e.player
        }
        guard let url = Self.url(palette) else { return nil }
        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        player.isMuted = true
        player.preventsDisplaySleepDuringVideoPlayback = false
        player.allowsExternalPlayback = false
        let observer = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                                               object: item, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let entry = self.entries[palette] else { return }
                entry.player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] finished in
                    Task { @MainActor [weak self] in
                        if finished, let entry = self?.entries[palette], entry.holders > 0 {
                            entry.player.play()
                        }
                    }
                }
            }
        }
        entries[palette] = Entry(player: player, observer: observer)
        return player
    }

    func acquire(_ palette: AppPalette) {
        guard player(palette, fromStart: false) != nil else { return }
        entries[palette]!.holders += 1
        entries[palette]!.player.play()
        AudioDiag.log("star play")
    }

    func release(_ palette: AppPalette) {
        guard var e = entries[palette] else { return }
        e.holders = max(0, e.holders - 1)
        if e.holders == 0 {
            e.player.pause()
            AudioDiag.log("star pause")
            // Keep the decoder primed while a page covers the star, so `play()`
            // on the way back shows motion at once instead of holding a frame.
            if e.player.status == .readyToPlay { e.player.preroll(atRate: 1) }
        }
        entries[palette] = e
    }

    private static func url(_ palette: AppPalette) -> URL? {
        #if DEBUG
        // `CB_STAR_VARIANT=ink|objet`: play a trial loop rendered into Documents.
        if let v = ProcessInfo.processInfo.environment["CB_STAR_VARIANT"].flatMap(StarCard.Look.init(rawValue:)), v != .card {
            let trial = URL.documentsDirectory.appending(path: StarCard.fileName(v, palette))
            if FileManager.default.fileExists(atPath: trial.path) { return trial }
        }
        #endif
        let name = (StarVideoGeometry.fileName(palette) as NSString).deletingPathExtension
        return Bundle.main.url(forResource: name, withExtension: "mov")
    }

    private func loadPoster(_ palette: AppPalette, then apply: (@MainActor (CGImage) -> Void)? = nil) {
        if let apply { waiting[palette, default: []].append(apply) }
        guard posters[palette] == nil, !decoding.contains(palette), let url = Self.url(palette) else { return }
        decoding.insert(palette)
        let generator = AVAssetImageGenerator(asset: AVURLAsset(url: url))
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        Task {
            let image = try? await generator.image(at: .zero).image
            decoding.remove(palette)
            guard let image else { return }
            posters[palette] = image
            for apply in waiting.removeValue(forKey: palette) ?? [] { apply(image) }
        }
    }
}
