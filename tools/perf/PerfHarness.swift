//
//  PerfHarness.swift
//  carambole
//
//  TEMPORARY stutter-measurement harness. Compiled only with the
//  PERF_HARNESS condition; launched with CB_PERF=1 it drives a fixed tour
//  (library scroll → book → modules → module page → back → colours), meters
//  frame pacing per segment, and writes Documents/perf.json. CB_PERF_* env
//  switches turn individual suspects off for A/B runs.
//

import Foundation
import os
import QuartzCore
import UIKit

enum PerfFlags {
    #if PERF_HARNESS
    private static let env = ProcessInfo.processInfo.environment
    static let staticWave = env["CB_PERF_STATIC_WAVE"] == "1"
    static let pauseStar = env["CB_PERF_PAUSE_STAR"] == "1"
    static let noColorStar = env["CB_PERF_NO_COLOR_STAR"] == "1"
    #else
    static let staticWave = false
    static let pauseStar = false
    static let noColorStar = false
    #endif
}

#if PERF_HARNESS

@MainActor
final class PerfHarness: NSObject {
    static let shared = PerfHarness()
    private static let log = Logger(subsystem: "wen.carambole.perf", category: "perf")
    private let signposter = OSSignposter(subsystem: "wen.carambole.perf", category: .pointsOfInterest)

    private var started = false
    private var link: CADisplayLink?
    private var last: CFTimeInterval?

    // Current segment stats.
    private var frames = 0
    private var hitches = 0
    private var hitchTime: Double = 0
    private var worst: Double = 0
    private var busy: Double = 0
    private var results: [[String: Any]] = []
    private var note = ""

    // Scroll driver.
    private var scrollView: UIScrollView?
    private var scrollDir: CGFloat = 1
    private var scrollSpeed: CGFloat = 1400

    static func startIfRequested() {
        guard ProcessInfo.processInfo.environment["CB_PERF"] == "1" else { return }
        shared.start()
    }

    private func start() {
        guard !started else { return }
        started = true
        UIApplication.shared.isIdleTimerDisabled = true
        let l = CADisplayLink(target: self, selector: #selector(frame(_:)))
        l.add(to: .main, forMode: .common)
        link = l
        Task { await tour() }
    }

    // MARK: Frame meter

    @objc private func frame(_ l: CADisplayLink) {
        let expected = l.targetTimestamp - l.timestamp
        if let last {
            let dt = l.timestamp - last
            frames += 1
            if dt > expected * 1.5 {
                hitches += 1
                hitchTime += dt - expected
            }
            worst = max(worst, dt)
            busy += expected
        }
        last = l.timestamp
        if let sv = scrollView { stepScroll(sv, dt: expected) }
    }

    private func resetStats() {
        frames = 0; hitches = 0; hitchTime = 0; worst = 0; busy = 0; last = nil
    }

    private func segment(_ name: String, seconds: Double, _ action: () -> Void = {}) async {
        resetStats()
        note = ""
        let state = signposter.beginInterval("segment", id: signposter.makeSignpostID(), "\(name)")
        let t0 = CACurrentMediaTime()
        let m0 = mach_absolute_time()
        action()
        try? await Task.sleep(for: .seconds(seconds))
        signposter.endInterval("segment", state)
        let wall = CACurrentMediaTime() - t0
        let ratio = wall > 0 ? hitchTime * 1000 / wall : 0
        let row: [String: Any] = [
            "segment": name, "seconds": wall, "frames": frames, "hitches": hitches,
            "hitchMs": hitchTime * 1000, "hitchRatioMsPerS": ratio, "worstFrameMs": worst * 1000,
            "startMach": m0, "endMach": mach_absolute_time(),
            "depth": topNav()?.viewControllers.count ?? -1, "note": note,
        ]
        results.append(row)
        Self.log.log("PERF \(name, privacy: .public) frames=\(self.frames) hitches=\(self.hitches) hitchMs=\(self.hitchTime * 1000, format: .fixed(precision: 1)) ratio=\(ratio, format: .fixed(precision: 1)) worst=\(self.worst * 1000, format: .fixed(precision: 1))")
    }

    // MARK: Tour

    private func tour() async {
        try? await Task.sleep(for: .seconds(4))   // launch + first load settle
        microbenchmarks()

        await segment("library_idle", seconds: 4)
        await scrollSegment("library_scroll", seconds: 6)

        await segment("push_book", seconds: 2) { post("openBook") }
        await segment("book_idle", seconds: 4)

        await segment("push_modules", seconds: 2) { post("openModules") }
        await scrollSegment("modules_scroll", seconds: 5)
        await segment("modules_settle", seconds: 1)

        await segment("push_module", seconds: 2) {
            post("openModule")
        }
        await segment("module_idle", seconds: 5)
        await scrollSegment("module_scroll", seconds: 5)

        await segment("pop_module", seconds: 2) { pop() }
        await segment("pop_modules", seconds: 2) { pop() }
        await segment("pop_book", seconds: 2) { pop() }
        await segment("library_return", seconds: 2)

        await segment("push_colors", seconds: 2) { post("openColors") }
        await scrollSegment("colors_scroll", seconds: 5)
        await segment("pop_colors", seconds: 2) { pop() }

        // Second round: warm (shaders compiled) vs cold first push above.
        await segment("push_book2", seconds: 2) { post("openBook") }
        await segment("book_idle2", seconds: 2)
        await segment("pop_book2", seconds: 2) { pop() }
        await segment("push_colors2", seconds: 2) { post("openColors") }
        await segment("pop_colors2", seconds: 2) { pop() }

        write()
        link?.invalidate()
        Self.log.log("PERF DONE")
    }

    private func scrollSegment(_ name: String, seconds: Double) async {
        let sv = findScrollView()
        let info = sv.map { "scroll h=\(Int($0.contentSize.height)) vis=\(Int($0.bounds.height))" } ?? "scroll:NONE"
        scrollDir = 1
        scrollView = sv
        await segment(name, seconds: seconds)
        if var last = results.popLast() { last["note"] = info; results.append(last) }
        scrollView = nil
        if let sv { sv.setContentOffset(CGPoint(x: 0, y: -sv.adjustedContentInset.top), animated: false) }
    }

    private func stepScroll(_ sv: UIScrollView, dt: Double) {
        let minY = -sv.adjustedContentInset.top
        let maxY = max(minY, sv.contentSize.height - sv.bounds.height + sv.adjustedContentInset.bottom)
        var y = sv.contentOffset.y + scrollDir * scrollSpeed * CGFloat(dt)
        if y >= maxY { y = maxY; scrollDir = -1 }
        if y <= minY { y = minY; scrollDir = 1 }
        sv.contentOffset.y = y
    }

    // MARK: Microbenchmarks (main-thread costs measured directly)

    private func microbenchmarks() {
        var mesh: [Double] = []
        for _ in 0..<3 {
            let t = CACurrentMediaTime()
            _ = try? CaramboleStarMesh.objetMesh()
            mesh.append((CACurrentMediaTime() - t) * 1000)
        }
        // Uncached variable-font creation (size 55 is never used by the app).
        let t1 = CACurrentMediaTime()
        for w in 200...719 { _ = AppFonts.uiFont(AppFonts.manrope, size: 55, wght: CGFloat(w)) }
        let fontCold = (CACurrentMediaTime() - t1) * 1000
        let t2 = CACurrentMediaTime()
        for w in 200...719 { _ = AppFonts.uiFont(AppFonts.manrope, size: 55, wght: CGFloat(w)) }
        let fontWarm = (CACurrentMediaTime() - t2) * 1000
        let row: [String: Any] = [
            "segment": "micro", "starMeshMs": mesh, "font520ColdMs": fontCold, "font520WarmMs": fontWarm,
            "fontColdPerWeightMs": fontCold / 520,
        ]
        results.append(row)
        Self.log.log("PERF micro mesh=\(mesh.description, privacy: .public) fontCold=\(fontCold, format: .fixed(precision: 1)) fontWarm=\(fontWarm, format: .fixed(precision: 1))")
    }

    // MARK: Output

    private func write() {
        let env = ProcessInfo.processInfo.environment.filter { $0.key.hasPrefix("CB_PERF") }
        let doc: [String: Any] = ["env": env, "results": results,
                                  "maxFPS": UIScreen.main.maximumFramesPerSecond]
        guard let data = try? JSONSerialization.data(withJSONObject: doc, options: [.prettyPrinted, .sortedKeys]),
              let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        try? data.write(to: dir.appendingPathComponent("perf.json"))
    }

    // MARK: UI driving (accessibility tree, so no view changes)

    private var windows: [UIWindow] {
        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.flatMap(\.windows)
    }

    private func activate(_ match: (NSObject) -> Bool) -> Bool {
        var queue: [NSObject] = windows
        var seen = 0
        while !queue.isEmpty, seen < 20000 {
            let node = queue.removeFirst()
            seen += 1
            if !(node is UIWindow), match(node) {
                let ok = node.accessibilityActivate()
                note += "activate[\(node.accessibilityLabel ?? "?")]=\(ok) "
                return ok
            }
            if let v = node as? UIView {
                if v.isHidden || v.window == nil { continue }
                queue.append(contentsOf: v.subviews)
            }
            if let els = node.accessibilityElements as? [NSObject] { queue.append(contentsOf: els) }
        }
        note += "activate:NO-MATCH "
        return false
    }

    private func post(_ command: String) {
        NotificationCenter.default.post(name: .perfCommand, object: command)
    }

    private func topNav() -> UINavigationController? {
        func find(_ vc: UIViewController?) -> UINavigationController? {
            guard let vc else { return nil }
            if let p = vc.presentedViewController, let n = find(p) { return n }
            if let n = vc as? UINavigationController { return n }
            for c in vc.children { if let n = find(c) { return n } }
            return nil
        }
        return windows.lazy.compactMap { find($0.rootViewController) }.first
    }

    private func pop() {
        let nav = topNav()
        Self.log.log("PERF pop depth=\(nav?.viewControllers.count ?? -1)")
        nav?.popViewController(animated: true)
    }

    private func findScrollView() -> UIScrollView? {
        let root: UIView? = topNav()?.topViewController?.view ?? windows.first?.rootViewController?.view
        var best: UIScrollView?
        var queue: [UIView] = root.map { [$0] } ?? []
        while !queue.isEmpty {
            let v = queue.removeFirst()
            if let sv = v as? UIScrollView, sv.contentSize.height > sv.bounds.height + 1, v.window != nil {
                if best == nil || sv.bounds.height * sv.bounds.width > best!.bounds.height * best!.bounds.width {
                    best = sv
                }
            }
            queue.append(contentsOf: v.subviews)
        }
        return best
    }
}

#endif

// MARK: - Command hooks (no-ops unless PERF_HARNESS)

import SwiftUI

extension Notification.Name {
    static let perfCommand = Notification.Name("wen.carambole.perfCommand")
}

extension View {
    /// Runs `action` when the harness posts `command`.
    @ViewBuilder
    func perfCommand(_ command: String, perform action: @escaping () -> Void) -> some View {
        #if PERF_HARNESS
        onReceive(NotificationCenter.default.publisher(for: .perfCommand)) { note in
            if note.object as? String == command { action() }
        }
        #else
        self
        #endif
    }
}
