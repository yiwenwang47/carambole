//
//  VocabSessionView.swift
//  carambole
//
//  *Mots* swipe session. Port of design/vocab/vocab-swipe.src.html v7
//  (`#drill`): ✕ only at the top, the big remaining count with « à apprendre »
//  / « à réviser » and the session stats, then four fixed slots on the pale
//  tint tray, 18 pt apart, centred in the space below the count. ANY card can
//  be swiped (user 2026-10-24); it flies off sideways on its own layer
//  (`FlyingCard`) and the next word fades into the same slot. Nothing ever
//  slides up: the other cards stay where they are, and a slot with no word
//  left stays empty. Every card is the same fixed size; a long headword
//  shrinks to fit (`VocabSwipeCard`).
//
//  Gestures on a card (spec: docs/plans/2026-10-23-vocab-swipe-plan.md):
//    - a partial left drag is a PEEK: the English slides in on the pale
//      underlay; release snaps back;
//    - left past 72 % of the card (or a fast flick) → `.again` (requeued,
//      dashed outline);
//    - right → « Connu » underlay; a learn word goes back to the waiting pile
//      until its third « connu » in a row, which grades `.good` (`VocabQueue`);
//    - after a peek, right rubber-bands back (no label; user 2026-10-23).
//  No swipe up: trop facile is marked on the Leçon page only (user
//  2026-10-24). Playing a clip never counts as a peek. Vertical drags do
//  nothing.
//
//  Learn mode opens on the Leçon page (`VocabLessonView`). Leçon 0
//  (« Comment glisser », user 2026-10-23) is the swipe lesson: no Leçon page;
//  the top card moves by itself through peek / far left / right with
//  captions in the count area; touching the tray ends it, then the learner
//  practises on leçon 1's first four words. It is UNGRADED (nothing reaches
//  `VocabStudy.commit`), opens before leçon 1 until finished once
//  (`VocabStudy.swipeLessonDone`), and replays from the Sommaire.
//
//  The placement start (« Où commencer ? », user 2026-10-23) follows leçon 0
//  the first time, before leçon 1: the same stack with 5 words per band
//  (`VocabPlacement`), right = known, left or a peek = not known, no
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
    /// What the tray draws: `queue` caught up at each swipe, inside the fade
    /// that brings the new card into its slot (`syncDisplay`).
    @Published private(set) var display: VocabQueue
    /// Learn: the done panel's offer (set when the stack empties).
    @Published private(set) var next: VocabPacing.Next = .none

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
        let q = VocabQueue.learn(entries: Array(first.entries.prefix(4)), armed: [], knownTarget: 1)
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
    func swipe(_ s: VocabQueue.Swipe, slot: Int) -> VocabQueue.Outcome {
        let outcome = queue.apply(s, slot: slot)
        if isPlacement {
            // Ungraded: right = known, left = not known (a peek locks the
            // card to left, so a peek always ends as not known).
            guard case .swiped(let grade) = outcome, var test = placement else { return outcome }
            test.record(entryID: grade.entryID, known: s == .right)
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
            if queue.isFinished, mode == .learn, let lecon {
                let hasNext = VocabStudy.lecon(after: lecon.index, in: vocab) != nil
                next = VocabPacing.afterLecon(wordsLearnedToday: VocabStudy.wordsLearnedToday(book: vocab),
                                              cap: newPerDay, hasNext: hasNext)
            }
        }
        return outcome
    }

    /// Catch the drawn tray up with the queue (as the swiped card flies out).
    func syncDisplay() { display = queue }

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

    // The dragged card (finger or swipe lesson): its slot and x offset, in points.
    @State private var dragSlot = 0
    @State private var dx: CGFloat = 0
    private enum DragAxis { case x, ignored }
    @State private var axis: DragAxis?
    @State private var dragging = false
    /// The touch began off every card or ended the swipe lesson: ignore it.
    @State private var swallowed = false
    /// Swiped cards flying off sideways above the tray, each on its own spring,
    /// so the next card can be dragged meanwhile.
    @State private var flights: [FlyingCard.Flight] = []
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    // Swipe lesson.
    @State private var coachOn = false
    @State private var coachStep = -1
    @State private var coachTask: Task<Void, Never>?
    @State private var cardWidth: CGFloat = 330

    // Mock geometry (`ROW_H`, `GAP`, `PAD`; tray 366 pt).
    private static let rowH: CGFloat = VocabSwipeCard.height
    private static let gap: CGFloat = 18
    private static let pad: CGFloat = 12
    private static let trayH: CGFloat = pad * 2 + 4 * rowH + 3 * gap
    private static func rowTop(_ i: Int) -> CGFloat { pad + CGFloat(i) * (rowH + gap) }
    /// Swipe-lesson caption box and the hero holding it.
    private static let captionH = ceil(AppFonts.uiFont(AppFonts.manrope, size: 24, wght: 300).lineHeight * 2)
    private static let coachHeroH: CGFloat = max(132, 14 + 14 + 10 + captionH + 10 + 3 + 10 + 14)

    /// The new card fades into the swiped card's slot, in place.
    private static let fadeIn = Animation.easeOut(duration: 0.45)
    private static let snapBack = Animation.spring(response: 0.36, dampingFraction: 0.68)
    private static let coachOut = Animation.timingCurve(0.3, 0.7, 0.2, 1, duration: 0.7)
    private static let coachBack = Animation.timingCurve(0.2, 0.9, 0.25, 1.1, duration: 0.45)

    /// Captions break where the mock's `text-wrap: balance` breaks them
    /// (SwiftUI has no balanced wrapping).
    private static let coachSteps: [(dx: CGFloat, say: String)] = [
        (-0.45, "Glisse un peu à gauche\npour voir le sens."),
        (-0.8, "Encore plus loin à\ngauche : tu dois le revoir."),
        (0.4, "À droite : tu le connais déjà."),
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
        let slots = model.display.slots
        let w = width - 24
        return ZStack(alignment: .topLeading) {
            if model.display.isFinished {
                donePanel
                    .transition(.opacity)
            } else {
                underlay(width: w)
                    .offset(x: Self.pad, y: Self.rowTop(dragSlot))
                ForEach(slots.indices, id: \.self) { i in
                    if let card = slots[i] {
                        VocabSwipeCard(card: card, theme: theme)
                            .frame(width: w)
                            .offset(x: Self.pad + (i == dragSlot ? dx : 0), y: Self.rowTop(i))
                            .zIndex(i == dragSlot ? 4 : 3)
                            .id(card.id)
                            .transition(.asymmetric(insertion: .opacity, removal: .identity))
                    }
                }
            }
            // A left swipe's English stays under the cards (as the underlay),
            // so the word fading into the slot covers it.
            ForEach(flights.filter { $0.swipe == .left }) { flight in
                FlyingCard(flight: flight, theme: theme, width: w, still: reduceMotion, meaning: true) {}
                    .offset(x: Self.pad, y: Self.rowTop(flight.slot))
                    .zIndex(2)
            }
            ForEach(flights) { flight in
                FlyingCard(flight: flight, theme: theme, width: w, still: reduceMotion) {
                    flights.removeAll { $0.id == flight.id }
                }
                .offset(x: Self.pad, y: Self.rowTop(flight.slot))
                .zIndex(5)
            }
        }
        .frame(width: width, height: Self.trayH, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color(hex: theme.tint)))
        .contentShape(Rectangle())
        .simultaneousGesture(dragGesture(cardWidth: w))
    }

    /// `.slot`: under the dragged card. The English panel rides 10 pt right of
    /// the card's right edge (so it slides in as the card goes left); « Connu »
    /// shows for right (nothing for a locked one). Their opacities follow the
    /// card without easing, as in the mock.
    private func underlay(width w: CGFloat) -> some View {
        let peeked = model.queue.isPeeked(slot: dragSlot)
        let okO: Double = dx > 0 && !peeked ? Double(min(1, dx / 60)) : 0
        let enO: Double = dx < 0 ? 1 : 0
        return ZStack(alignment: .leading) {
            Text("Connu").uppercaseLabel(AppColor.ink)
                .padding(.leading, 18)
                .frame(width: w, height: Self.rowH, alignment: .leading)
                .background(Color(hex: theme.tileOn))
                .opacity(okO)
            VocabMeaningPanel(text: model.display.card(at: dragSlot)?.entry.en ?? "", theme: theme, cardWidth: w)
                .opacity(enO)
                .animation(nil, value: enO)
                .offset(x: w + dx + 10)
        }
        .animation(nil, value: okO)
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

    /// The slot whose card is under `p`, if any.
    private func slot(at p: CGPoint, cardWidth w: CGFloat) -> Int? {
        model.display.slots.indices.first { i in
            model.display.slots[i] != nil
                && CGRect(x: Self.pad, y: Self.rowTop(i), width: w, height: Self.rowH).contains(p)
        }
    }

    private func dragGesture(cardWidth w: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { v in
                if !dragging && !swallowed {
                    if coachOn { stopCoach(); swallowed = true; return }
                    guard let i = slot(at: v.startLocation, cardWidth: w) else {
                        swallowed = true; return
                    }
                    // A new touch takes over: any card still easing back sits down.
                    var off = Transaction(animation: nil)
                    off.disablesAnimations = true
                    withTransaction(off) { dx = 0; dragSlot = i }
                    dragging = true
                    axis = nil
                }
                guard dragging else { return }
                drag(to: v.translation)
            }
            .onEnded { v in
                defer { dragging = false; swallowed = false; axis = nil }
                guard dragging else { return }
                release(velocity: v.velocity.width / 1000, cardWidth: w)
            }
    }

    /// Follow the finger (`pointermove`): the first 8 pt pick the axis
    /// (a vertical drag is ignored); left past 56 pt is a peek; after a peek
    /// right only gives a rubber band.
    private func drag(to t: CGSize) {
        var tx = t.width
        if axis == nil, hypot(t.width, t.height) > 8 {
            axis = abs(t.width) >= abs(t.height) ? .x : .ignored
        }
        guard axis == .x else { return }
        let peeked = model.queue.isPeeked(slot: dragSlot)
        if tx < -56, !peeked { model.swipe(.peek, slot: dragSlot) }
        if tx > 0, model.queue.isPeeked(slot: dragSlot) { tx = Self.rubber(tx) }
        dx = tx
    }

    /// `endDrag`: commit or snap back. Velocity in pt / ms.
    private func release(velocity v: CGFloat, cardWidth w: CGFloat) {
        let peeked = model.queue.isPeeked(slot: dragSlot)
        if axis == .x, dx < 0, -dx > w * 0.72 || (v < -0.9 && -dx > 80) {
            return commit(.left, cardWidth: w, velocity: v)
        }
        if axis == .x, dx > 0, !peeked, dx > w * 0.38 || v > 0.8 {
            return commit(.right, cardWidth: w, velocity: v)
        }
        withAnimation(Self.snapBack) { dx = 0 }
    }

    /// The card flies off sideways on its own layer (`FlyingCard`), carrying
    /// the finger's speed; in the same frame the next word fades into its
    /// slot. Velocity in pt / ms.
    private func commit(_ s: VocabQueue.Swipe, cardWidth w: CGFloat, velocity v: CGFloat) {
        let slot = dragSlot
        guard let card = model.display.card(at: slot) else { return }
        switch model.swipe(s, slot: slot) {
        case .swiped, .passed: break
        case .peeked, .rejected:
            withAnimation(Self.snapBack) { dx = 0 }
            return
        }
        let end: CGFloat = s == .left ? -1.2 * w : 1.2 * w
        let speed = (s == .left ? -v : v) * 1000   // pt / s along the way out
        let distance = max(1, abs(end - dx))
        flights.append(.init(card: card, swipe: s, slot: slot, startX: dx, endX: end,
                             velocity: min(12, max(FlyingCard.minLaunch, speed / distance))))
        var off = Transaction(animation: nil)
        off.disablesAnimations = true
        withTransaction(off) { dx = 0 }
        withAnimation(Self.fadeIn) { model.syncDisplay() }
    }

    // MARK: Swipe lesson

    /// The mock's `startCoach`, without its 0.5 s lead-in (leçon 0 has no
    /// Leçon page to fade from; motion starts at once): each step glides out
    /// in 0.7 s, holds until 1.9 s, glides back in 0.45 s and rests 0.8 s; the
    /// three steps loop. The top card moves.
    private func startCoach() {
        coachTask?.cancel()
        coachOn = true
        coachStep = -1
        dragSlot = 0
        coachTask = Task { @MainActor in
            var step = 0
            while !Task.isCancelled && coachOn {
                let s = Self.coachSteps[step]
                coachStep = step
                withAnimation(Self.coachOut) { dx = s.dx * cardWidth }
                try? await Task.sleep(nanoseconds: 1_900_000_000)
                guard !Task.isCancelled, coachOn else { return }
                withAnimation(Self.coachBack) { dx = 0 }
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
        withTransaction(off) { coachOn = false; coachStep = -1; dx = 0 }
    }

    // MARK: Simulator flags (DEBUG)

    #if DEBUG
    /// CB_VOC_ARM=n arms the first n rows; CB_VOC_START=<s> presses Commencer
    /// after s seconds; CB_VOC_SCRIPT=a,b,… then plays gestures one after
    /// another (touch, peek, left, right, lock, wait, play), through the same
    /// drag / release code as the finger. A step ending in a digit 0–3 acts on
    /// that slot (`right2`); else on the top slot.
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

    /// A scripted finger on `slot`: moves in 12 steps over ~0.4 s, holds, releases.
    private func fingerDrag(slot: Int, to target: CGFloat, hold: Double = 0.6) async {
        guard model.display.card(at: slot) != nil else { return }
        var off = Transaction(animation: nil)
        off.disablesAnimations = true
        withTransaction(off) { dx = 0; dragSlot = slot }
        dragging = true
        axis = nil
        for k in 1...12 {
            drag(to: CGSize(width: target * CGFloat(k) / 12, height: 0))
            await pause(0.033)
        }
        await pause(hold)
        release(velocity: 0, cardWidth: cardWidth)
        dragging = false
        axis = nil
    }

    private func play(_ raw: String) async {
        let w = cardWidth
        var step = raw
        var slot = 0
        if let last = step.last, let n = Int(String(last)), (0..<VocabQueue.visibleCount).contains(n) {
            slot = n
            step.removeLast()
        }
        switch step {
        case "touch": if coachOn { stopCoach() }
        case "peek": await fingerDrag(slot: slot, to: -0.45 * w, hold: 1.4)
        case "left": await fingerDrag(slot: slot, to: -0.8 * w, hold: 0.5)
        case "right": await fingerDrag(slot: slot, to: 0.45 * w, hold: 0.5)
        case "lock":
            // Peek, then try right: it rubber-bands back.
            await fingerDrag(slot: slot, to: -0.4 * w, hold: 0.9)
            await pause(0.6)
            await fingerDrag(slot: slot, to: 0.5 * w, hold: 1.2)
        case "wait": await pause(1.5)
        case "play":
            // Press that card's play disc (`VocabPlayDisc.debugPlay`).
            if let id = model.display.card(at: slot)?.entry.id {
                NotificationCenter.default.post(name: VocabPlayDisc.debugPlay, object: id)
            }
        default: break
        }
    }
    #endif
}

/// A swiped card flying off sideways above the tray. It takes its fill at
/// once (right: `tileOn`), and a critically damped spring carries it from
/// where the finger let go to off the card's edge, starting at the finger's
/// speed (at least `minLaunch`), so a flick flies faster than a slow drag.
/// A left swipe's English rides away with it, clipped to the slot, on its own
/// layer under the cards (`meaning`). Removes itself when done. `still` (Reduce Motion): a short ease.
struct FlyingCard: View {
    struct Flight: Identifiable {
        let card: VocabQueue.Card
        let swipe: VocabQueue.Swipe
        let slot: Int
        let startX: CGFloat
        let endX: CGFloat
        /// Initial speed in units of the whole trip per second.
        let velocity: CGFloat
        var id: Int { card.id }
    }

    /// Fly-out speed floor (trips / s): a slow release still leaves briskly
    /// instead of starting from rest.
    static let minLaunch: CGFloat = 3

    let flight: Flight
    let theme: AppTheme
    let width: CGFloat
    var still = false
    /// Draw the left swipe's English panel instead of the card (same spring,
    /// so the two move together).
    var meaning = false
    let onDone: () -> Void
    @State private var t: CGFloat = 0

    var body: some View {
        let x = flight.startX + (flight.endX - flight.startX) * t
        Group {
            if meaning {
                VocabMeaningPanel(text: flight.card.entry.en, theme: theme, cardWidth: width)
                    .offset(x: width + x + 10)
                    .frame(width: width, height: VocabSwipeCard.height, alignment: .leading)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .opacity(Double(max(0, 1 - 1.5 * t)))
            } else {
                VocabSwipeCard(card: flight.card, theme: theme,
                               leavingFill: flight.swipe == .right ? Color(hex: theme.tileOn) : nil)
                    .frame(width: width)
                    .offset(x: x)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            let spring = Animation.interpolatingSpring(mass: 1, stiffness: 190, damping: 27.6,
                                                       initialVelocity: flight.velocity)
            withAnimation(still ? .easeIn(duration: 0.2) : spring) { t = 1 } completion: { onDone() }
        }
    }
}

/// The English shown on a peek (`.slot .en`): pale `quietFill` block, 62 % of
/// the card wide.
private struct VocabMeaningPanel: View {
    let text: String
    let theme: AppTheme
    let cardWidth: CGFloat

    var body: some View {
        Text(text)
            .font(.display(size: 15, wght: 400))
            .foregroundColor(AppColor.ink)
            .lineSpacing(0)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 16)
            .frame(width: cardWidth * 0.62, height: VocabSwipeCard.height, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(hex: theme.quietFill)))
    }
}
