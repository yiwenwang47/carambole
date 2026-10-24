//
//  TodayView.swift
//  carambole
//
//  "Aujourd'hui" — motion.html 03 Gravité. Today's work as a pile of physical
//  tokens (palette fills for new / review, dashed = fragile) falling into a
//  SpriteKit pile; drag and throw them, `Secouer` tosses them. Opened from the
//  book home's `fait :` line; links on to History. The bottom pills start the
//  same Apprendre / Réviser sessions as the home (the parent presents them).
//  On return, finished tokens fall out of the pile instead of rebuilding it.
//

import Combine
import SpriteKit
import SwiftUI

// MARK: - Snapshot

/// What the screen shows: the tokens plus the three counts.
struct TodaySnapshot: Equatable {
    var tokens: [TokenSpec]
    var learnCount: Int
    var reviewCount: Int
    var fragileCount: Int

    static let empty = TodaySnapshot(tokens: [], learnCount: 0, reviewCount: 0, fragileCount: 0)

    var total: Int { learnCount + reviewCount }
}

// MARK: - View

/// Holds the scene so it is created once per screen (a `@State` initial value
/// is re-evaluated on every parent render, building throwaway scenes).
private final class PileHolder: ObservableObject {
    let scene = TokenPileScene()
}

struct TodayView: View {
    @ObservedObject private var viewModel: BookViewModel
    private let startLearn: () -> Void
    private let startReview: () -> Void
    /// Preview / harness only: a fixed snapshot instead of the live queues.
    private let override: TodaySnapshot?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @StateObject private var holder = PileHolder()
    @State private var snapshot: TodaySnapshot = .empty
    /// False until the push has settled: the first drop waits for it, so the
    /// tokens fall on a still screen with its final size.
    @State private var settled = false
    #if DEBUG
    /// `DemoRemote.openHistory`: pushes History without a tap (simulator checks).
    @State private var remoteHistory = false
    /// `CB_TODAY_CYCLE`: true while the first long tokens are out of the pile.
    @State private var cycleOut = false
    #endif
    @AppStorage(AppPalette.storageKey) private var paletteID = AppPalette.fallback.rawValue

    private var scene: TokenPileScene { holder.scene }

    init(viewModel: BookViewModel, startLearn: @escaping () -> Void, startReview: @escaping () -> Void) {
        self.init(viewModel: viewModel, snapshot: nil, startLearn: startLearn, startReview: startReview)
    }

    /// Fixed-snapshot init for previews and the screenshot harness.
    init(viewModel: BookViewModel, snapshot: TodaySnapshot?,
         startLearn: @escaping () -> Void = {}, startReview: @escaping () -> Void = {}) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
        self.startLearn = startLearn
        self.startReview = startReview
        self.override = snapshot
    }

    // MARK: Layout (motion.html 03, 360×760 phone; status bar = 50 px)

    /// Bottom pills: 54 tall, 30 above the screen edge; the pile floor sits 10 above.
    private static let buttonBottom: CGFloat = 30
    private static let buttonHeight: CGFloat = 54
    private static let floorGap: CGFloat = 10

    var body: some View {
        // The reader respects the safe area (so the top inset is real); the
        // stack inside it ignores it and spans the whole screen.
        GeometryReader { geo in
            // Prototype y (from the phone top) → app y below the status bar.
            let top = geo.safeAreaInsets.top
            ZStack(alignment: .topLeading) {
                AppColor.paper

                SpriteView(scene: scene)
                    .accessibilityHidden(true)

                header
                    .padding(.top, top + 22)            // .hd top: 72
                bigLine
                    .padding(.top, top + 54)            // .big top: 104
                actionRow
                    .padding(.top, top + 160)           // .shake top: 210

                VStack {
                    Spacer()
                    startButtons
                }
                .padding(.horizontal, Spacing.screenH)
                .padding(.bottom, Self.buttonBottom)
            }
            .ignoresSafeArea()
        }
        .onAppear {
            scene.reduceMotion = reduceMotion
            scene.floorInset = Self.buttonBottom + Self.buttonHeight + Self.floorGap
            if settled {
                rebuild()
            } else {
                snapshot = override ?? Self.liveSnapshot(viewModel)
                // Navigation push ≈ 0.35 s; drop once it has landed.
                DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0 : 0.4)) {
                    settled = true
                    rebuild()
                }
            }
        }
        .onChange(of: refreshKey) { if settled { rebuild() } }
        .onChange(of: override) { if settled { rebuild() } }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .swipeToGoBack {
            // A rightward token throw is not a back-swipe.
            if !scene.isHandlingTouch { dismiss() }
        }
        #if DEBUG
        .navigationDestination(isPresented: $remoteHistory) { HistoryView(book: viewModel.descriptor) }
        .onReceive(NotificationCenter.default.publisher(for: DemoRemote.Action.openHistory.notification)) { _ in
            remoteHistory = true
        }
        .onReceive(NotificationCenter.default.publisher(for: DemoRemote.Action.closeHistory.notification)) { _ in
            remoteHistory = false
        }
        .onReceive(Self.cycleTimer) { _ in
            guard settled else { return }
            cycleOut.toggle()
            rebuild()
        }
        #endif
    }

    // MARK: Header

    /// `‹ Aujourd'hui` (back) left; the date and `Historique →` right.
    private var header: some View {
        HStack(alignment: .top) {
            Button { dismiss() } label: {
                Text("‹ Aujourd’hui")
                    .uppercaseLabel(AppColor.ink)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.vertical, -8)
            .accessibilityLabel("Retour")

            Spacer()

            VStack(alignment: .trailing, spacing: 10) {
                Text(Self.dateText(Date()))
                    .uppercaseLabel()
                NavigationLink {
                    HistoryView(book: viewModel.descriptor)
                } label: {
                    Text("Historique →")
                        .uppercaseLabel(AppColor.ink)
                        .padding(.vertical, 6)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.vertical, -6)
            }
        }
        .padding(.horizontal, Spacing.screenH)
    }

    /// "Ven. 9 oct." — French abbreviated weekday + day + month, capitalised.
    static func dateText(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.setLocalizedDateFormatFromTemplate("EEEdMMM")
        let s = f.string(from: date)
        return s.prefix(1).uppercased() + s.dropFirst()
    }

    // MARK: Big line

    /// `22 éléments` / grey `t'attendent.` — Manrope 250 40pt, −0.03em, lh 1.05.
    private var bigLine: some View {
        let n = snapshot.total
        return VStack(alignment: .leading, spacing: -12) {
            if n == 0 {
                Text("Tout est fait")
                    .foregroundColor(AppColor.ink)
                Text("pour aujourd’hui.")
                    .foregroundColor(AppColor.g2)
            } else {
                Text("\(n) \(n == 1 ? "élément" : "éléments")")
                    .foregroundColor(AppColor.ink)
                Text(n == 1 ? "t’attend." : "t’attendent.")
                    .foregroundColor(AppColor.g2)
            }
        }
        .font(.display(size: 40, wght: 250))
        .tracking(-1.2)
        .padding(.horizontal, Spacing.screenH)
        .allowsHitTesting(false)
        .accessibilityElement(children: .combine)
    }

    // MARK: Fragile chip + Secouer

    /// Left: the fragile chip (dashed underline, starts Réviser) when any.
    /// Right: `Secouer` (solid underline) tosses the pile — hidden on reduce motion.
    private var actionRow: some View {
        HStack(alignment: .firstTextBaseline) {
            if snapshot.fragileCount > 0 {
                let n = snapshot.fragileCount
                Button(action: startReview) {
                    Text("\(n) \(n == 1 ? "fragile" : "fragiles") · à réviser")
                        .uppercaseLabel(AppColor.ink)
                        .padding(.bottom, 2)
                        .overlay(alignment: .bottom) { DashedRule() }
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.vertical, -8)
                .accessibilityLabel("\(n) \(n == 1 ? "élément fragile" : "éléments fragiles"), réviser")
            }
            Spacer()
            if !reduceMotion && !snapshot.tokens.isEmpty {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    scene.shake()
                } label: {
                    Text("Secouer")
                        .uppercaseLabel(AppColor.ink)
                        .padding(.bottom, 2)
                        .overlay(alignment: .bottom) {
                            Rectangle().fill(AppColor.ink).frame(height: 1)
                        }
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.vertical, -8)
            }
        }
        .padding(.horizontal, Spacing.screenH)
    }

    // MARK: Start pills

    /// `Apprendre 8` / `Réviser 14`: black 54pt pills side by side, count
    /// right-aligned in the small label face. A pill with nothing to do hides.
    private var startButtons: some View {
        HStack(spacing: 10) {
            if snapshot.learnCount > 0 {
                startPill("Apprendre", count: snapshot.learnCount, action: startLearn)
            }
            if snapshot.reviewCount > 0 {
                startPill("Réviser", count: snapshot.reviewCount, action: startReview)
            }
        }
    }

    private func startPill(_ title: String, count: Int, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                Spacer(minLength: 8)
                Text("\(count)")
                    .font(.appLabel)
                    .tracking(labelTracking)
                    .foregroundColor(Color(hex: AppPalette(stored: paletteID).theme.buttonCount))
            }
        }
        .buttonStyle(PrimaryButtonStyle(height: Self.buttonHeight))
        .accessibilityLabel("\(title), \(count)")
    }

    // MARK: Data

    /// Changes whenever `BookViewModel.refresh()` lands (e.g. back from a session).
    private struct RefreshKey: Equatable {
        let seen: Set<String>
        let unlocked: Set<String>
        let fragile: Set<String>
        let due: Int
        let learned: Int
        let reviewed: Int
        let newAvailable: Int
    }

    private var refreshKey: RefreshKey {
        RefreshKey(seen: viewModel.seenIDs, unlocked: viewModel.unlockedIDs,
                   fragile: viewModel.fragileIDs, due: viewModel.dueCount,
                   learned: viewModel.learnedToday, reviewed: viewModel.reviewedToday,
                   newAvailable: viewModel.newAvailableToday)
    }

    private func rebuild() {
        #if DEBUG
        let next = Self.debugLongTokens(override ?? Self.liveSnapshot(viewModel), viewModel, out: cycleOut)
        #else
        let next = override ?? Self.liveSnapshot(viewModel)
        #endif
        snapshot = next
        scene.sync(next.tokens)
    }

    /// Same sources as the book home: new = the frontier module's not-yet-seen
    /// elements (what Apprendre teaches; its count is `newAvailableToday`),
    /// review = this round's `reviewSessionElements()`, fragile = membership in
    /// `fragileIDs`. New and review interleave so the pile mixes as it falls.
    private static func liveSnapshot(_ vm: BookViewModel) -> TodaySnapshot {
        let newEls = vm.newestUnlockedModule().map { module in
            vm.moduleLearnElements(module).filter { !vm.seenIDs.contains($0.id) }
        } ?? []
        let reviewEls = vm.reviewSessionElements()
        let newTokens = newEls.map { TokenSpec(id: $0.id, label: $0.label, kind: .new) }
        let reviewTokens = reviewEls.map {
            TokenSpec(id: $0.id, label: $0.label,
                      kind: vm.fragileIDs.contains($0.id) ? .fragile : .review)
        }
        var tokens: [TokenSpec] = []
        var seen = Set<String>()
        for i in 0..<max(newTokens.count, reviewTokens.count) {
            for t in [i < reviewTokens.count ? reviewTokens[i] : nil,
                      i < newTokens.count ? newTokens[i] : nil].compactMap({ $0 })
            where seen.insert(t.id).inserted {
                tokens.append(t)
            }
        }
        return TodaySnapshot(tokens: tokens, learnCount: vm.newAvailableToday,
                             reviewCount: reviewEls.count,
                             fragileCount: vm.estimate.fragileCount)
    }
}

#if DEBUG
// MARK: - Simulator checks

extension TodayView {
    /// `CB_TODAY_LONG=<n>`: the book's n widest element labels (real elements;
    /// new / review / fragile in turn) go first in the pile, so 2-line pills
    /// are on screen. `CB_TODAY_CYCLE=<secs>`: every <secs> the first 4 of them
    /// leave the pile, and join again the next tick (join / leave recordings).
    fileprivate static func debugLongTokens(_ s: TodaySnapshot, _ vm: BookViewModel, out: Bool) -> TodaySnapshot {
        guard let n = Int(ProcessInfo.processInfo.environment["CB_TODAY_LONG"] ?? ""), n > 0 else { return s }
        let font = TokenPileScene.PillLayout.font
        let widest = vm.book.allElements
            .map { ($0, (TokenPileScene.shortLabel($0.label) as NSString).size(withAttributes: [.font: font]).width) }
            .sorted { $0.1 > $1.1 }
            .prefix(n)
        let kinds: [TokenSpec.Kind] = [.review, .new, .fragile]
        var long = widest.enumerated().map { i, pair in
            TokenSpec(id: pair.0.id, label: pair.0.label, kind: kinds[i % kinds.count])
        }
        if out { long.removeFirst(min(4, long.count)) }
        let ids = Set(widest.map(\.0.id))
        var copy = s
        copy.tokens = long + s.tokens.filter { !ids.contains($0.id) }
        return copy
    }

    fileprivate static let cycleTimer: AnyPublisher<Date, Never> = {
        guard let secs = Double(ProcessInfo.processInfo.environment["CB_TODAY_CYCLE"] ?? ""), secs > 0 else {
            return Empty().eraseToAnyPublisher()
        }
        return Timer.publish(every: secs, on: .main, in: .common).autoconnect().eraseToAnyPublisher()
    }()
}
#endif

// MARK: - Dashed rule

/// A 1pt dashed underline (fragile = dashed, by form).
private struct DashedRule: View {
    var body: some View {
        GeometryReader { geo in
            Path { p in
                p.move(to: CGPoint(x: 0, y: 0.5))
                p.addLine(to: CGPoint(x: geo.size.width, y: 0.5))
            }
            .stroke(AppColor.ink, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
        }
        .frame(height: 1)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        TodayView(viewModel: BookViewModel(), snapshot: TodaySnapshot(
            tokens: [
                TokenSpec(id: "a", label: "aller + inf.", kind: .new),
                TokenSpec(id: "b", label: "ne… pas", kind: .review),
                TokenSpec(id: "c", label: "il y a", kind: .fragile),
            ],
            learnCount: 1, reviewCount: 2, fragileCount: 1))
    }
}
#endif
