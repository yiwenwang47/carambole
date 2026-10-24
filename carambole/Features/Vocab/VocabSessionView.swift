//
//  VocabSessionView.swift
//  carambole
//
//  *Mots* swipe session. Port of design/vocab/vocab-swipe.src.html v7
//  (`#drill`): ✕ only at the top, the big remaining count with « à apprendre »
//  / « à réviser » and the session stats, then at most four equal cards on the
//  pale tint tray, 18 pt apart, centred in the space below the count. The top
//  card is the one swiped; after a swipe it flies out, then the others slide up
//  and a new card enters at the bottom.
//
//  Gestures on the top card (spec: docs/plans/2026-10-23-vocab-swipe-plan.md):
//    - a partial left drag is a PEEK: the English slides in on the pale
//      underlay; release snaps back;
//    - left past 72 % of the card (or a fast flick) → `.again` (requeued,
//      dashed outline);
//    - right → `.good` (« Connu » underlay);
//    - up → trop facile (`TooEasyGate` via `VocabStudy.commit`, undo pill);
//    - after a peek, right and up rubber-band back (no label; user
//      2026-10-23).
//  Playing a clip never counts as a peek. The card stack is vertically locked.
//
//  Learn mode opens on the Leçon page (`VocabLessonView`). Leçon 0
//  (« Comment glisser », user 2026-10-23) is the swipe lesson: no Leçon page;
//  the top card moves by itself through peek / far left / right / up with
//  captions in the count area; touching the tray ends it, then the learner
//  practises on leçon 1's first four words. It is UNGRADED (nothing reaches
//  `VocabStudy.commit`), opens before leçon 1 until finished once
//  (`VocabStudy.swipeLessonDone`), and replays from the Sommaire.
//
//  The placement start (« Où commencer ? », user 2026-10-23) follows leçon 0
//  the first time, before leçon 1: the same stack with 5 words per band
//  (`VocabPlacement`), right / up = known, left or a peek = not known, no
//  requeue. It stops at the first band with 2 misses; the done panel offers
//  that band's first leçon (`VocabStudy.placementStartLecon`). UNGRADED, like
//  leçon 0; it can be retaken from the Sommaire.
//
//  Grading goes through `VocabQueue` (pure) → `VocabStudy.commit` (shared
//  `ElementGrader` / `TooEasyGate`, HARD RULE: never forked).
//

import SwiftUI

// MARK: - Session model

/// Session data that must survive the parent re-creating this view: the
/// leçon, the armed words and the queue. Built once (`@StateObject`).
@MainActor
final class VocabSessionModel: ObservableObject {
    enum Phase: Equatable { case lesson, stack, empty }

    let vocab: VocabBook
    let mode: SessionMode
    let newPerDay: Int

    @Published var phase: Phase
    @Published var lecon: VocabLecon?
    /// Leçon 0, the ungraded swipe lesson (`lecon` is then leçon 1, whose
    /// first four words are the practice cards).
    @Published private(set) var isSwipeLesson = false
    /// The placement start (ungraded). `placement` holds its tally.
    @Published private(set) var isPlacement = false
    @Published private(set) var placement: VocabPlacement?
    /// The leçon the placement start chose (its done panel).
    @Published private(set) var placementResult: VocabLecon?
    /// Rows tapped on the Leçon page.
    @Published var armed: Set<String> = []
    /// The live queue: every swipe is applied here at once and graded.
    @Published private(set) var queue: VocabQueue
    /// What the stack draws. It lags `queue` by the fly-out (0.26 s) so the
    /// other cards slide up after the swiped one has left, as in the mock.
    @Published private(set) var display: VocabQueue
    /// Learn: the done panel's offer (set when the stack empties).
    @Published private(set) var next: VocabPacing.Next = .none
    /// The undo pill (`.tooEasyUndo`).
    @Published var undoElementID: String?
    @Published private(set) var undoToken = 0

    init(vocab: VocabBook, mode: SessionMode, elements: [GrammarElement], newPerDay: Int, reviewCap: Int,
         swipeLesson: Bool = false, placement: Bool = false) {
        self.vocab = vocab
        self.mode = mode
        self.newPerDay = newPerDay
        switch mode {
        case .learn:
            // The leçon holding the elements the book model chose; else the
            // book's next unfinished leçon.
            let first = elements.first?.id
            let lecon = vocab.lecons.first { l in l.entries.contains { $0.id == first } }
                ?? VocabStudy.nextLecon(in: vocab.lecons)
            self.lecon = lecon
            let q = VocabQueue.learn(entries: [], armed: [])
            queue = q
            display = q
            phase = lecon == nil ? .empty : .lesson
            // Leçon 0 when asked for, or before leçon 1 until done once.
            if let first = vocab.lecons.first,
               swipeLesson || (!VocabStudy.swipeLessonDone && lecon?.index == first.index) {
                startSwipeLesson(practice: first)
            } else if placement || (VocabStudy.placementStartLecon == nil && lecon?.index == vocab.lecons.first?.index) {
                // Then the placement start, once, before leçon 1.
                startPlacement()
            }
        case .review:
            var q = VocabStudy.reviewQueue(book: vocab, cap: reviewCap)
            #if DEBUG
            // CB_VOC_REVIEW_ALL=1: every entry of the first band as if due
            // (simulator check of the review stack without real progress).
            if ProcessInfo.processInfo.environment["CB_VOC_REVIEW_ALL"] == "1", let band = vocab.bands.first {
                q = VocabQueue.review(due: band.entries.map { VocabQueue.Due(entry: $0, recall: 1) }, cap: reviewCap)
            }
            #endif
            queue = q
            display = q
            phase = q.isFinished ? .empty : .stack
        }
    }

    /// Leçon 0: straight to the stack, four practice cards, nothing graded.
    private func startSwipeLesson(practice first: VocabLecon) {
        isSwipeLesson = true
        lecon = first
        let q = VocabQueue.learn(entries: Array(first.entries.prefix(4)), armed: [])
        queue = q
        display = q
        phase = .stack
    }

    /// The placement start: straight to the stack, nothing graded.
    func startPlacement() {
        let test = VocabPlacement(book: vocab)
        isSwipeLesson = false
        isPlacement = true
        placement = test
        placementResult = nil
        let q = VocabQueue.placement(entries: test.probes)
        queue = q
        display = q
        next = .none
        phase = q.isFinished ? .empty : .stack
    }

    /// Cards Commencer will serve.
    var pendingCount: Int {
        guard let lecon else { return 0 }
        return VocabStudy.pendingIDs(lecon: lecon).count
    }

    /// Commencer: build the learn stack (armed words first).
    func start() {
        guard let lecon else { return }
        let q = VocabStudy.learnQueue(lecon: lecon, armed: armed)
        queue = q
        display = q
        phase = .stack
    }

    /// Apply one gesture; persist the grade it hands back.
    @discardableResult
    func swipe(_ s: VocabQueue.Swipe) -> VocabQueue.Outcome {
        let outcome = queue.apply(s)
        if isPlacement {
            // Ungraded: right / up = known, left = not known (a peek locks the
            // card to left, so a peek always ends as not known).
            guard case .swiped(let grade) = outcome, var test = placement else { return outcome }
            test.record(entryID: grade.entryID, known: s != .left)
            if test.isDecided || queue.isFinished {
                queue.clear()
                placementResult = test.startLecon(in: vocab)
                if let result = placementResult { VocabStudy.placementStartLecon = result.index }
            }
            placement = test
            return outcome
        }
        if isSwipeLesson {
            // Ungraded: no commit, no undo pill, no pacing.
            if queue.isFinished { VocabStudy.swipeLessonDone = true }
            return outcome
        }
        if case .swiped(let grade) = outcome {
            VocabStudy.commit(grade)
            if case .tooEasy(let id, true) = grade {
                undoElementID = id
                undoToken += 1
            }
            if queue.isFinished, mode == .learn, let lecon {
                let hasNext = VocabStudy.lecon(after: lecon.index, in: vocab) != nil
                next = VocabPacing.afterLecon(wordsLearnedToday: VocabStudy.wordsLearnedToday(book: vocab),
                                              cap: newPerDay, hasNext: hasNext)
            }
        }
        return outcome
    }

    /// Catch the drawn stack up with the queue (after the fly-out).
    func syncDisplay() { display = queue }

    /// « Annuler » on the undo pill (the pill itself demoted the word).
    func undoTooEasy() {
        queue.undoTooEasy()
        display.undoTooEasy()
    }

    /// Leçon 0's « Leçon 1 »: leçon 1's page, now a normal graded leçon.
    func openFirstLecon() {
        guard let first = vocab.lecons.first else { return }
        openLecon(first)
    }

    /// The placement start's result: that leçon's page, a normal graded leçon.
    func openLecon(_ target: VocabLecon) {
        isSwipeLesson = false
        isPlacement = false
        placement = nil
        lecon = target
        armed = []
        let q = VocabQueue.learn(entries: [], armed: [])
        queue = q
        display = q
        next = .none
        phase = .lesson
    }

    /// « Leçon suivante » / « Encore une leçon »: the next unfinished leçon's page.
    func openNextLecon() {
        guard let current = lecon, let nextLecon = VocabStudy.lecon(after: current.index, in: vocab) else { return }
        lecon = nextLecon
        armed = []
        let q = VocabQueue.learn(entries: [], armed: [])
        queue = q
        display = q
        next = .none
        phase = .lesson
    }
}

// MARK: - View

struct VocabSessionView: View {
    let canStart: Bool
    let onFinish: () -> Void
    @StateObject private var model: VocabSessionModel

    init(elements: [GrammarElement], mode: SessionMode, canStart: Bool,
         settings: StudySettings, swipeLesson: Bool = false, placement: Bool = false,
         onFinish: @escaping () -> Void) {
        self.canStart = canStart
        self.onFinish = onFinish
        _model = StateObject(wrappedValue: VocabSessionModel(
            vocab: .bundled, mode: mode, elements: elements,
            newPerDay: settings.newPerDay, reviewCap: settings.reviewRoundSize,
            swipeLesson: swipeLesson, placement: placement))
    }

    @AppStorage(AppPalette.storageKey) private var paletteID = AppPalette.fallback.rawValue
    private var theme: AppTheme { AppPalette(stored: paletteID).theme }

    // Top-card motion (finger, swipe lesson, fly-out), in points.
    @State private var dx: CGFloat = 0
    @State private var dy: CGFloat = 0
    private enum DragAxis { case x, y }
    @State private var axis: DragAxis?
    @State private var dragging = false
    /// The touch began off the top card or ended the swipe lesson: ignore it.
    @State private var swallowed = false
    /// The swiped card while it flies out (fill + no underlay).
    @State private var leaving: VocabQueue.Swipe?
    @State private var flown = false
    // Swipe lesson.
    @State private var coachOn = false
    @State private var coachStep = -1
    @State private var coachTask: Task<Void, Never>?
    @State private var cardWidth: CGFloat = 330

    // Mock geometry (`ROW_H`, `GAP`, `PAD`; tray 366 pt).
    private static let rowH: CGFloat = 72
    private static let gap: CGFloat = 18
    private static let pad: CGFloat = 12
    private static let trayH: CGFloat = pad * 2 + 4 * rowH + 3 * gap
    private static func rowTop(_ i: Int) -> CGFloat { pad + CGFloat(i) * (rowH + gap) }
    /// Swipe-lesson caption box and the hero holding it.
    private static let captionH = ceil(AppFonts.uiFont(AppFonts.manrope, size: 24, wght: 300).lineHeight * 2)
    private static let coachHeroH: CGFloat = max(132, 14 + 14 + 10 + captionH + 10 + 3 + 10 + 14)

    // Mock curves.
    private static let slideUp = Animation.timingCurve(0.2, 0.9, 0.25, 1.12, duration: 0.42)
    private static let snapBack = Animation.timingCurve(0.2, 0.9, 0.25, 1.15, duration: 0.35)
    private static let coachOut = Animation.timingCurve(0.3, 0.7, 0.2, 1, duration: 0.7)
    private static let coachBack = Animation.timingCurve(0.2, 0.9, 0.25, 1.1, duration: 0.45)

    /// Captions break where the mock's `text-wrap: balance` breaks them
    /// (SwiftUI has no balanced wrapping).
    private static let coachSteps: [(dx: CGFloat, dy: CGFloat, say: String)] = [
        (-0.45, 0, "Glisse un peu à gauche\npour voir le sens."),
        (-0.8, 0, "Encore plus loin à\ngauche : tu dois le revoir."),
        (0.4, 0, "À droite : tu le connais déjà."),
        (0, -64, "Vers le haut : trop facile,\nil ne reviendra plus."),
    ]

    var body: some View {
        Group {
            switch model.phase {
            case .lesson:
                if let lecon = model.lecon {
                    VocabLessonView(lecon: lecon, startCount: model.pendingCount, canStart: canStart,
                                    armed: $model.armed, onStart: start, onClose: exit)
                        .transition(.opacity)
                        .id(lecon.index)
                }
            case .stack:
                stack.transition(.opacity)
            case .empty:
                emptyState
            }
        }
        .background(AppColor.paper.ignoresSafeArea())
        // On the ✕ row, right of the ✕ (user 2026-10-23): the shared top
        // position covered the big count. The row is 36 pt, the pill 48 pt.
        .tooEasyUndo(elementID: $model.undoElementID, token: model.undoToken,
                     insets: EdgeInsets(top: -6, leading: 58, bottom: 0, trailing: 20),
                     onUndo: model.undoTooEasy)
        .onDisappear {
            coachTask?.cancel()
            Speaker.shared.stop()
        }
        #if DEBUG
        .task { await runLaunchFlags() }
        #endif
    }

    private func exit() {
        coachTask?.cancel()
        Speaker.shared.stop()
        onFinish()
    }

    private func start() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { model.start() }
    }

    // MARK: Stack screen

    private var stack: some View {
        GeometryReader { geo in
            // Phone padding 20; the tray reaches 8 pt past it on each side.
            let trayW = geo.size.width - 40 + 16
            VStack(alignment: .leading, spacing: 0) {
                HStack { VocabCloseButton(action: exit); Spacer() }
                    .frame(height: 36)
                hero
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    tray(width: trayW)
                        .padding(.horizontal, -8)
                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 22)
            .onAppear {
                cardWidth = trayW - 24
                if model.isSwipeLesson, model.display.stats == .init(), coachTask == nil { startCoach() }
            }
            .onChange(of: geo.size.width) { _, w in cardWidth = w - 40 + 16 - 24 }
        }
    }

    // MARK: Hero (count, or the swipe lesson's captions)

    private var hero: some View {
        VStack(alignment: .leading, spacing: 6) {
            if coachOn { coach } else { count }
        }
        .padding(.top, 14)
        .padding(.horizontal, 2)
        // Leçon 0 keeps the captions' height after the demo, so the tray never
        // moves when the count replaces them.
        // The placement start keeps it too: it follows leçon 0 on the same stack.
        .frame(maxWidth: .infinity, minHeight: model.isSwipeLesson || model.isPlacement ? Self.coachHeroH : 132,
               alignment: .topLeading)
    }

    private var count: some View {
        let d = model.display
        return VStack(alignment: .leading, spacing: 0) {
            Text("\(d.remaining)")
                .font(.display(size: 96, wght: 200))
                .tracking(-5)
                .monospacedDigit()
                .foregroundColor(AppColor.ink)
                .lineLimit(1)
                .fixedSize()
                .frame(height: 96 * 0.9)
            Text(model.isPlacement ? "à tester" : model.mode == .learn ? "à apprendre" : "à réviser")
                .uppercaseLabel(AppColor.ink)
            Text(statsLine(d.stats))
                .uppercaseLabel()
        }
        .accessibilityElement(children: .combine)
    }

    private func statsLine(_ s: VocabQueue.Stats) -> String {
        if model.isPlacement { return "\(s.known + s.tooEasy) connus · \(s.again) inconnus" }
        return "\(s.known) connus · \(s.again) à revoir" + (s.tooEasy > 0 ? " · \(s.tooEasy) trop facile" : "")
    }

    private var coach: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Comment glisser").uppercaseLabel(AppColor.ink)
            Text(coachStep >= 0 ? Self.coachSteps[coachStep].say : "")
                .font(.display(size: 24, wght: 300))
                .tracking(-0.5)
                .foregroundColor(AppColor.ink)
                .fixedSize(horizontal: false, vertical: true)
                // The mock's `min-height: 2.4em` (two lines): a fixed box so one-
                // and two-line captions never move the tray. Two of Manrope's
                // natural lines, which are taller than the mock's 1.2.
                .frame(height: Self.captionH, alignment: .topLeading)
            HStack(spacing: 6) {
                ForEach(0..<Self.coachSteps.count, id: \.self) { k in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(k == coachStep ? AppColor.ink : AppColor.g3)
                        .frame(width: 18, height: 3)
                        .animation(.easeOut(duration: 0.2), value: coachStep)
                }
            }
            Text("Touche une carte pour commencer").uppercaseLabel()
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Tray

    private func tray(width: CGFloat) -> some View {
        let cards = model.display.visible
        let w = width - 24
        return ZStack(alignment: .topLeading) {
            if model.display.isFinished {
                donePanel
            } else {
                underlay(width: w)
                    .offset(x: Self.pad, y: Self.rowTop(0))
                ForEach(Array(cards.enumerated()), id: \.element.id) { i, card in
                    let top = i == 0
                    VocabSwipeCard(card: card, theme: theme, leavingFill: top ? leavingFill : nil)
                        .frame(width: w)
                        .offset(x: Self.pad + (top && dy == 0 ? dx : 0), y: Self.rowTop(i) + (top ? dy : 0))
                        .opacity(top && leaving == .up && flown ? 0 : 1)
                        .zIndex(top ? 4 : 3)
                        .transition(.asymmetric(insertion: .modifier(active: EnterModifier(on: true),
                                                                     identity: EnterModifier(on: false)),
                                                removal: .identity))
                }
            }
        }
        .frame(width: width, height: Self.trayH, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color(hex: theme.tint)))
        .contentShape(Rectangle())
        .simultaneousGesture(dragGesture(cardWidth: w))
    }

    private var leavingFill: Color? {
        switch leaving {
        case .right: return Color(hex: theme.tileOn)
        case .up: return Color(hex: theme.buttonFill)
        default: return nil
        }
    }

    /// `.slot`: under the top card. The English panel rides 10 pt right of the
    /// card's right edge (so it slides in as the card goes left); « Connu » and
    /// « ↑ Trop facile » show for right and up (nothing for a locked one).
    /// Their opacities follow the card without easing, as in the mock.
    private func underlay(width w: CGFloat) -> some View {
        let peeked = model.queue.peeked
        let on = leaving == nil
        let okO: Double = on && dx > 0 && !peeked ? Double(min(1, dx / 60)) : 0
        let upO: Double = on && dy < 0 && !peeked ? Double(min(1, -dy / 40)) : 0
        let enO: Double = on && dx < 0 ? 1 : 0
        return ZStack(alignment: .leading) {
            Text("Connu").uppercaseLabel(AppColor.ink)
                .padding(.leading, 18)
                .frame(width: w, height: Self.rowH, alignment: .leading)
                .background(Color(hex: theme.tileOn))
                .opacity(okO)
            Text("↑ Trop facile").uppercaseLabel(AppColor.ink)
                .padding(.bottom, 10)
                .frame(width: w, height: Self.rowH, alignment: .bottom)
                .background(Color(hex: theme.buttonFill))
                .opacity(upO)
            Text(model.display.current?.entry.en ?? "")
                .font(.display(size: 15, wght: 400))
                .foregroundColor(AppColor.ink)
                .lineSpacing(0)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 16)
                .frame(width: w * 0.62, height: Self.rowH, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(hex: theme.quietFill)))
                .opacity(enO)
                .animation(nil, value: enO)
                .offset(x: w + (dy == 0 ? dx : 0) + 10)
        }
        .animation(nil, value: okO)
        .animation(nil, value: upO)
        .frame(width: w, height: Self.rowH, alignment: .leading)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityHidden(true)
    }

    /// `.done`: inside the tray, bottom-aligned.
    @ViewBuilder
    private var donePanel: some View {
        if model.isPlacement { placementDone } else { lessonDone }
    }

    /// The placement start's result: « Leçon 31 », its ranks, the tally, and
    /// a button to that leçon's page.
    private var placementDone: some View {
        let s = model.display.stats
        let result = model.placementResult
        return VStack(alignment: .leading, spacing: 10) {
            Spacer(minLength: 0)
            Text("Où commencer ?").uppercaseLabel(AppColor.ink)
            Text(result.map { "Leçon \($0.index)" } ?? "Terminé")
                .font(.display(size: 40, wght: 250))
                .tracking(-1.2)
                .foregroundColor(AppColor.ink)
            if let result, let band = model.vocab.bands.first(where: { $0.band == result.band }) {
                Text("Mots \(band.rankRange.lowerBound)–\(band.rankRange.upperBound)")
                    .font(.display(size: 24, wght: 300))
                    .tracking(-0.5)
                    .foregroundColor(AppColor.ink)
            }
            Text("\(s.known + s.tooEasy) connus · \(s.again) inconnus").uppercaseLabel(AppColor.ink)
            Group {
                if let result {
                    Button("Leçon \(result.index)") { withAnimation(.smooth(duration: 0.4)) { model.openLecon(result) } }
                } else {
                    Button("Terminer", action: exit)
                }
            }
            .buttonStyle(DrillButtonStyle())
            .padding(.top, 12)
        }
        .padding(22)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }

    private var lessonDone: some View {
        let s = model.display.stats
        return VStack(alignment: .leading, spacing: 10) {
            Spacer(minLength: 0)
            Text(model.isSwipeLesson ? "Leçon 0 · Comment glisser" : model.mode == .learn ? "Leçon" : "Réviser")
                .uppercaseLabel(AppColor.ink)
            Text("Terminé")
                .font(.display(size: 40, wght: 250))
                .tracking(-1.2)
                .foregroundColor(AppColor.ink)
            Text("\(s.known)")
                .font(.display(size: 64, wght: 200))
                .tracking(-2.5)
                .monospacedDigit()
                .foregroundColor(AppColor.ink)
                .frame(height: 64)
            Text("connus · \(s.again) à revoir · \(s.tooEasy) trop facile").uppercaseLabel(AppColor.ink)
            doneButtons.padding(.top, 12)
        }
        .padding(22)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }

    /// Provisional pacing (`VocabPacing`): under the cap « Leçon suivante »;
    /// at the cap « Terminer » + « Encore une leçon ».
    @ViewBuilder
    private var doneButtons: some View {
        if model.isSwipeLesson, VocabStudy.placementStartLecon == nil {
            // First time: the placement start comes next, before leçon 1.
            Button("Où commencer ?") { withAnimation(.smooth(duration: 0.4)) { model.startPlacement() } }
                .buttonStyle(DrillButtonStyle())
        } else if model.isSwipeLesson {
            Button("Leçon 1") { withAnimation(.smooth(duration: 0.4)) { model.openFirstLecon() } }
                .buttonStyle(DrillButtonStyle())
        } else {
            pacingButtons
        }
    }

    @ViewBuilder
    private var pacingButtons: some View {
        switch model.mode == .learn ? model.next : .none {
        case .nextLecon:
            Button("Leçon suivante") { withAnimation(.smooth(duration: 0.4)) { model.openNextLecon() } }
                .buttonStyle(DrillButtonStyle())
        case .oneMore:
            VStack(spacing: 4) {
                Button("Terminer", action: exit).buttonStyle(DrillButtonStyle())
                Button { withAnimation(.smooth(duration: 0.4)) { model.openNextLecon() } } label: {
                    Text("Encore une leçon").uppercaseLabel(AppColor.ink).underline()
                        .padding(.vertical, 10).frame(maxWidth: .infinity).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        case .none:
            Button("Terminer", action: exit).buttonStyle(DrillButtonStyle())
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack { VocabCloseButton(action: exit); Spacer() }.frame(height: 36)
            Spacer(minLength: Spacing.xl)
            SectionLabel(model.mode == .review ? "Réviser" : "Apprendre")
            Text(model.mode == .review ? "Rien à réviser" : "Rien à apprendre")
                .font(.display(size: 40, wght: 250))
                .tracking(-1.2)
                .foregroundColor(AppColor.ink)
            Text(model.mode == .review
                 ? "Aucun mot à réviser pour le moment. Reviens plus tard."
                 : "Tu as parcouru tous les mots disponibles.")
                .font(.appBody)
                .foregroundColor(AppColor.graphite)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Button("Terminer", action: exit).buttonStyle(DrillButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.bottom, Spacing.sm)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: Gesture

    /// `rubber()`: a locked direction gives at most 16 pt.
    private static func rubber(_ d: CGFloat) -> CGFloat {
        (d < 0 ? -1 : 1) * 16 * (1 - exp(-abs(d) / 50))
    }

    private func dragGesture(cardWidth w: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { v in
                if !dragging && !swallowed {
                    if coachOn { stopCoach(); swallowed = true; return }
                    let topCard = CGRect(x: Self.pad, y: Self.rowTop(0), width: w, height: Self.rowH)
                    guard leaving == nil, model.display.current != nil, topCard.contains(v.startLocation) else {
                        swallowed = true; return
                    }
                    dragging = true
                    axis = nil
                }
                guard dragging else { return }
                drag(to: v.translation)
            }
            .onEnded { v in
                defer { dragging = false; swallowed = false; axis = nil }
                guard dragging else { return }
                release(velocity: CGSize(width: v.velocity.width / 1000, height: v.velocity.height / 1000),
                        cardWidth: w)
            }
    }

    /// Follow the finger (`pointermove`): the first 8 pt pick the axis; left
    /// past 56 pt is a peek; after a peek right and up only give a rubber band.
    private func drag(to t: CGSize) {
        var tx = t.width, ty = t.height
        if axis == nil, hypot(tx, ty) > 8 {
            axis = abs(tx) >= abs(ty) ? .x : (ty < 0 ? .y : nil)
        }
        guard let axis else { return }
        switch axis {
        case .x:
            if tx < -56, !model.queue.peeked { model.swipe(.peek) }
            if tx > 0, model.queue.peeked { tx = Self.rubber(tx) }
            dy = 0; dx = tx
        case .y:
            ty = min(0, ty)
            if model.queue.peeked { ty = Self.rubber(ty) }
            dx = 0; dy = ty
        }
    }

    /// `endDrag`: commit or snap back. Velocities in pt / ms.
    private func release(velocity v: CGSize, cardWidth w: CGFloat) {
        let peeked = model.queue.peeked
        if axis == .x, dx < 0, -dx > w * 0.72 || (v.width < -0.9 && -dx > 80) { return commit(.left, cardWidth: w) }
        if axis == .x, dx > 0, !peeked, dx > w * 0.38 || v.width > 0.8 { return commit(.right, cardWidth: w) }
        if axis == .y, !peeked, dy < -70 || (v.height < -0.8 && dy < -30) { return commit(.up, cardWidth: w) }
        withAnimation(Self.snapBack) { dx = 0; dy = 0 }
    }

    /// The card flies out (0.28 s ease-in), then the stack slides up and a new
    /// card enters at the bottom (`commit` + `render` after 260 ms).
    private func commit(_ s: VocabQueue.Swipe, cardWidth w: CGFloat) {
        guard case .swiped = model.swipe(s) else {
            withAnimation(Self.snapBack) { dx = 0; dy = 0 }
            return
        }
        leaving = s
        flown = false
        withAnimation(.easeIn(duration: 0.28)) {
            flown = true
            switch s {
            case .left: dy = 0; dx = -1.3 * w
            case .right: dy = 0; dx = 1.3 * w
            default: dx = 0; dy = -120
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.26) {
            var off = Transaction(animation: nil)
            off.disablesAnimations = true
            withTransaction(off) { leaving = nil; flown = false; dx = 0; dy = 0 }
            withAnimation(Self.slideUp) { model.syncDisplay() }
        }
    }

    // MARK: Swipe lesson

    /// The mock's `startCoach`, without its 0.5 s lead-in (leçon 0 has no
    /// Leçon page to fade from; motion starts at once): each step glides out
    /// in 0.7 s, holds until 1.9 s, glides back in 0.45 s and rests 0.8 s; the
    /// four steps loop.
    private func startCoach() {
        coachTask?.cancel()
        coachOn = true
        coachStep = -1
        coachTask = Task { @MainActor in
            var step = 0
            while !Task.isCancelled && coachOn {
                let s = Self.coachSteps[step]
                coachStep = step
                withAnimation(Self.coachOut) { dx = s.dx * cardWidth; dy = s.dy }
                try? await Task.sleep(nanoseconds: 1_900_000_000)
                guard !Task.isCancelled, coachOn else { return }
                withAnimation(Self.coachBack) { dx = 0; dy = 0 }
                try? await Task.sleep(nanoseconds: 800_000_000)
                step = (step + 1) % Self.coachSteps.count
            }
        }
    }

    private func stopCoach() {
        coachTask?.cancel()
        coachTask = nil
        var off = Transaction(animation: nil)
        off.disablesAnimations = true
        withTransaction(off) { coachOn = false; coachStep = -1; dx = 0; dy = 0 }
    }

    // MARK: Simulator flags (DEBUG)

    #if DEBUG
    /// CB_VOC_ARM=n arms the first n rows; CB_VOC_START=<s> presses Commencer
    /// after s seconds; CB_VOC_SCRIPT=a,b,… then plays gestures on the top card
    /// (touch, peek, left, right, up, lock, wait) one after another, through
    /// the same drag / release code as the finger.
    private func runLaunchFlags() async {
        let env = ProcessInfo.processInfo.environment
        if let n = env["CB_VOC_ARM"].flatMap(Int.init), let lecon = model.lecon {
            model.armed = Set(lecon.entries.prefix(n).map(\.id))
        }
        if model.phase == .lesson, let t = env["CB_VOC_START"].flatMap(Double.init) {
            await pause(t)
            start()
        }
        guard let script = env["CB_VOC_SCRIPT"] else { return }
        await pause(Double(env["CB_VOC_SCRIPT_DELAY"] ?? "") ?? 1.5)
        for step in script.split(separator: ",").map(String.init) {
            await play(step)
            await pause(1.0)
        }
    }

    private func pause(_ s: Double) async {
        try? await Task.sleep(nanoseconds: UInt64(s * 1_000_000_000))
    }

    /// A scripted finger: moves in 12 steps over ~0.4 s, holds, releases.
    private func fingerDrag(to target: CGSize, hold: Double = 0.6, flick: CGSize = .zero) async {
        guard model.display.current != nil else { return }
        dragging = true
        axis = nil
        for k in 1...12 {
            let f = CGFloat(k) / 12
            drag(to: CGSize(width: target.width * f, height: target.height * f))
            await pause(0.033)
        }
        await pause(hold)
        release(velocity: flick, cardWidth: cardWidth)
        dragging = false
        axis = nil
    }

    private func play(_ step: String) async {
        let w = cardWidth
        switch step {
        case "touch": if coachOn { stopCoach() }
        case "peek": await fingerDrag(to: CGSize(width: -0.45 * w, height: 0), hold: 1.4)
        case "left": await fingerDrag(to: CGSize(width: -0.8 * w, height: 0), hold: 0.5)
        case "right": await fingerDrag(to: CGSize(width: 0.45 * w, height: 0), hold: 0.5)
        case "up": await fingerDrag(to: CGSize(width: 0, height: -90), hold: 0.5)
        case "lock":
            // Peek, then try right and up: both rubber-band back.
            await fingerDrag(to: CGSize(width: -0.4 * w, height: 0), hold: 0.9)
            await pause(0.6)
            await fingerDrag(to: CGSize(width: 0.5 * w, height: 0), hold: 1.2)
            await pause(0.6)
            await fingerDrag(to: CGSize(width: 0, height: -120), hold: 1.2)
        case "wait": await pause(1.5)
        default: break
        }
    }
    #endif
}

/// A new card enters one slot lower, transparent (`.row.enter`).
private struct EnterModifier: ViewModifier {
    let on: Bool
    func body(content: Content) -> some View {
        content.offset(y: on ? 72 + 18 : 0).opacity(on ? 0 : 1)
    }
}
