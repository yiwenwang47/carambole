//
//  DrillSessionView.swift
//  carambole
//
//  Drives a study session over GRAMMAR ELEMENTS (not a flat exercise list). The
//  SRS unit is the element; each element is drilled via its example sentences,
//  shuffled so the learner masters the rule, not a memorized token order.
//
//  Two modes:
//  - .learn  — walk each element, drilling shuffled examples to INTRODUCE it:
//              advance to the next element after the FIRST correct answer (the
//              element now carries FSRS state = "seen"/en-cours); a wrong answer
//              stays on the element and presents another example (retry). Graduation
//              to maîtrisé happens LATER, across spaced review days — never in this
//              intro session. Used by "Apprendre" and by tapping a module.
//  - .review — one fresh example per due element, FSRS-regraded. Used by "Réviser".
//
//  See docs/plans/2026-06-19-book-modules-elements-design.md.
//

import SwiftUI
import UIKit

struct DrillSessionView: View {
    typealias Mode = SessionMode

    let title: String
    /// English module intro shown once on the "Leçon" card. Empty → no card.
    let ruleNote: String
    let elements: [GrammarElement]
    let mode: Mode
    var onFinish: () -> Void = {}

    init(title: String, ruleNote: String, elements: [GrammarElement], mode: Mode,
         onFinish: @escaping () -> Void = {}) {
        self.title = title
        self.ruleNote = ruleNote
        self.elements = elements
        self.mode = mode
        self.onFinish = onFinish
    }

    @State private var elementIndex = 0
    /// Pending examples for the current element (learn mode queue).
    @State private var pending: [Exercise] = []
    @State private var lastExampleID: String?
    /// What `advance()` does next — set by grading via `LearnLoop.nextAction`.
    @State private var nextAction: LearnLoop.NextAction = .nextElement

    /// Append-only log of every example presented this session, in order. The
    /// drill on screen is `history[cursor]`; this is what makes the back chevron
    /// possible across element boundaries — the live stream has no flat index to
    /// step through, so we keep our own.
    @State private var history: [Exercise] = []
    /// Tokens the user submitted, keyed by history index, for read-only revisits.
    @State private var submittedAnswers: [Int: [String]] = [:]
    /// Correctness keyed by history index. Doubles as the answered-set so the
    /// summary counts distinct presentations even if a drill is re-answered.
    @State private var resultByIndex: [Int: Bool] = [:]
    /// Index into `history` of the drill on screen. Equals the frontier
    /// (`history.count - 1`) when live; below it when reviewing read-only.
    @State private var cursor = 0
    /// Live horizontal drag of the card stack, in points. 0 at rest; tracks the
    /// finger during a swipe and springs back to 0 (or commits to the next/prev
    /// card) on release. Each card is offset by `(i - cursor) * width + dragOffset`.
    @State private var dragOffset: CGFloat = 0
    /// Index of the card we just ADVANCED past (forward). It is still on screen,
    /// sliding out left, but must NOT flip into the explanation/review chrome —
    /// "just slide to the next drill." It keeps its live answered look (the card is
    /// still alive, so its internal state shows). Cleared the moment the learner
    /// drags BACK, so a deliberate slide-back reveals the explanation as intended.
    @State private var hideExplanationAt: Int? = nil
    /// Manual keyboard inset (keyboard + accent bar height, above the home
    /// indicator). The carousel's fixed-height cards defeat SwiftUI's automatic
    /// keyboard avoidance, so for typing drills we lift the card content by this
    /// much to keep "Vérifier" above the keyboard. 0 whenever the keyboard is down.
    @State private var keyboardInset: CGFloat = 0

    @State private var finished = false
    @State private var showingIntro = true

    /// Element id just marked "Trop facile" (correct → instant graduate). Set so the
    /// undo toast's "Annuler" can `demote` exactly that element even though the session
    /// has already auto-advanced past it. Cleared when the toast is dismissed/undone.
    @State private var tooEasyUndoElementID: String?
    /// Bumped each time a too-easy graduation happens; the auto-dismiss task keys off
    /// this so a NEW too-easy (toast re-shown) cancels the previous dismissal timer.
    @State private var tooEasyUndoToken = 0

    private var answeredCount: Int { resultByIndex.count }
    private var correctCount: Int { resultByIndex.values.filter { $0 }.count }
    /// Index of the live (gradable) card — always the last one presented.
    private var frontier: Int { history.count - 1 }
    /// True once the live card has been answered, so a forward swipe may advance.
    private var liveCardFinished: Bool { resultByIndex[frontier] != nil }
    /// While typing a free-text answer the embedded UITextField owns horizontal
    /// drags (caret/selection); pause the carousel swipe so it can't hijack them.
    private var isTypingLiveCard: Bool {
        cursor == frontier
            && history.indices.contains(frontier)
            && history[frontier].resolvedInputMode == .freeText
            && resultByIndex[frontier] == nil
    }

    private var currentElement: GrammarElement? {
        elements.indices.contains(elementIndex) ? elements[elementIndex] : nil
    }

    private var shouldShowIntro: Bool {
        showingIntro && !ruleNote.isEmpty && !elements.isEmpty
    }

    private var progress: Double {
        guard !elements.isEmpty else { return 0 }
        return Double(elementIndex) / Double(elements.count)
    }

    var body: some View {
        ZStack {
            AppColor.paper.ignoresSafeArea()

            VStack(spacing: 0) {
                // Exit affordance during a live session (intro + drilling). The
                // completion/empty states have their own "Terminer" button, so the
                // bar is hidden there. Progress is already durable — every answer
                // upserts review_status as it happens — so leaving simply dismisses.
                if !finished && !elements.isEmpty {
                    exitBar
                }

                ZStack {
                    if shouldShowIntro {
                        introCard.transition(.opacity)
                    } else if finished || elements.isEmpty {
                        completionSummary
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    } else if history.indices.contains(cursor) {
                        carousel
                    }
                }
                // The carousel's fixed-height cards swallow SwiftUI's automatic
                // keyboard avoidance, so own it manually: opt out of the auto inset
                // and lift the content by the keyboard (+ accent bar) height. 0 when
                // the keyboard is down, so token/MC drills are unaffected.
                .padding(.bottom, keyboardInset)
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .animation(.easeOut(duration: 0.25), value: keyboardInset)
            }

            // Passive undo affordance after a "Trop facile" graduation — floats at the
            // TOP, just under the exit-bar ✕, so it never collides with the card's
            // pinned Vérifier/Suivant footer. The surrounding VStack/Spacer is
            // hit-transparent (only the pill itself takes touches) so the live card
            // underneath stays fully interactive.
            if tooEasyUndoElementID != nil {
                VStack {
                    tooEasyUndoToast
                        .padding(.horizontal, Spacing.screenH)
                        .padding(.top, 48)   // clear the exit-bar (✕) row above
                    Spacer().allowsHitTesting(false)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: tooEasyUndoElementID)
        // Auto-dismiss the undo toast ~4.5s after each too-easy graduation. Keyed on
        // the token so a fresh too-easy restarts the timer (and cancels the prior one);
        // cancellation (token bumps / view teardown) silently aborts the sleep.
        .task(id: tooEasyUndoToken) {
            guard tooEasyUndoElementID != nil else { return }
            try? await Task.sleep(nanoseconds: 4_500_000_000)
            if !Task.isCancelled { dismissTooEasyUndo() }
        }
        .onAppear {
            if history.isEmpty && !elements.isEmpty { startElement(0, animated: false) }
        }
        .onReceive(NotificationCenter.default.publisher(
            for: UIResponder.keyboardWillShowNotification)) { updateKeyboardInset($0) }
        .onReceive(NotificationCenter.default.publisher(
            for: UIResponder.keyboardWillChangeFrameNotification)) { updateKeyboardInset($0) }
        .onReceive(NotificationCenter.default.publisher(
            for: UIResponder.keyboardWillHideNotification)) { _ in keyboardInset = 0 }
        // The drill stack (carousel) animates itself via `dragOffset`/`cursor` inside
        // explicit withAnimation transactions; only the intro/completion swaps animate
        // here.
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: finished)
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: showingIntro)
    }

    // MARK: - Swipeable card stack (finger-tracked paging)

    /// Render only the on-screen card and its immediate neighbors — a long session
    /// builds a big `history`, so we never instantiate every DrillView.
    private var visibleIndices: [Int] {
        guard !history.isEmpty else { return [] }
        let lo = max(0, cursor - 1)
        let hi = min(history.count - 1, cursor + 1)
        return Array(lo...hi)
    }

    private var carousel: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack {
                ForEach(visibleIndices, id: \.self) { i in
                    cardView(at: i)
                        .frame(width: w, height: geo.size.height)
                        .offset(x: CGFloat(i - cursor) * w + dragOffset)
                        // Only the centered card takes touches; neighbors are parked
                        // off-screen and must not steal taps.
                        .allowsHitTesting(i == cursor)
                }
            }
            .frame(width: w, height: geo.size.height)
            .contentShape(Rectangle())
            .simultaneousGesture(dragGesture(width: w),
                                 including: isTypingLiveCard ? .subviews : .all)
        }
    }

    @ViewBuilder
    private func cardView(at i: Int) -> some View {
        DrillView(
            exercise: history[i],
            progress: progress,
            onResult: { correct, tokens in handleResult(correct: correct, answer: tokens) },
            onTooEasy: { correct, tokens in handleTooEasy(correct: correct, answer: tokens) },
            onNext: advance,
            canGoBack: i > 0,
            onBack: goBack,
            canGoForward: i < frontier,
            onForward: goForward,
            // An answered card behind the frontier is a read-only review — EXCEPT
            // the one we just advanced past (`hideExplanationAt`), which keeps its
            // live answered look while sliding out so the explanation never flashes.
            reviewData: (i < frontier && i != hideExplanationAt)
                ? DrillView.ReviewData(answer: submittedAnswers[i] ?? [],
                                       correct: resultByIndex[i] ?? false)
                : nil
        )
        .id(i)
    }

    private func dragGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                // A swipe over a lingering keyboard (e.g. an answered typing card)
                // would scramble the neighbour as it slides under the inset — drop it
                // the moment the drag starts. (This gesture is disabled while ACTIVELY
                // typing a live card, so this never yanks the keyboard mid-entry.)
                if keyboardInset > 0 { dismissKeyboard() }
                // Dragging back toward the previous card → reveal its explanation
                // as it slides in (clear the advance-suppression).
                if value.translation.width > 0, hideExplanationAt != nil {
                    hideExplanationAt = nil
                }
                dragOffset = resistedOffset(value.translation.width, width: width)
            }
            .onEnded { value in
                endDrag(translation: value.translation.width,
                        predicted: value.predictedEndTranslation.width,
                        width: width)
            }
    }

    /// Track the finger 1:1 toward an existing neighbor; rubber-band (damp + cap)
    /// toward an edge or a not-yet-finished frontier so the stack resists where it
    /// can't go but still gives a little.
    private func resistedOffset(_ raw: CGFloat, width: CGFloat) -> CGFloat {
        let towardPrevious = raw > 0
        let canTrack = towardPrevious ? cursor > 0 : cursor < frontier
        if canTrack { return raw }
        let cap = width * 0.22
        return max(-cap, min(cap, raw * 0.32))
    }

    /// Commit to the next/prev card if the finger moved far enough OR flicked fast
    /// (velocity via `predictedEndTranslation`); otherwise spring back to rest.
    private func endDrag(translation: CGFloat, predicted: CGFloat, width: CGFloat) {
        let commit = abs(translation) > width * 0.28 || abs(predicted) > width * 0.55
        let towardPrevious = translation > 0
        if commit {
            if towardPrevious {
                if cursor > 0 { navHaptic(); goBack(); return }
            } else if cursor < frontier {
                navHaptic(); goForward(); return
            } else if cursor == frontier && liveCardFinished {
                navHaptic(); advance(); return
            }
        }
        withAnimation(.interactiveSpring(response: 0.32, dampingFraction: 0.86)) {
            dragOffset = 0
        }
    }

    private func navHaptic() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// Compute the on-screen keyboard inset from a keyboard frame notification:
    /// how far the keyboard (with its accent-bar accessory) rises ABOVE the home
    /// indicator's safe area, which is what `padding(.bottom,)` must add to clear it.
    private func updateKeyboardInset(_ note: Notification) {
        guard let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey]
                as? CGRect else { return }
        let window = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }.first
        let screenH = window?.bounds.height ?? UIScreen.main.bounds.height
        let safeBottom = window?.safeAreaInsets.bottom ?? 0
        keyboardInset = max(0, screenH - frame.origin.y - safeBottom)
    }

    /// Animate the stack so card `index` becomes centered (and clear any drag).
    private func animateCursor(to index: Int) {
        // Leaving the current card: drop any keyboard so a typing drill never drags a
        // stale keyboard — and its layout inset — onto the neighbouring card.
        dismissKeyboard()
        withAnimation(.interactiveSpring(response: 0.32, dampingFraction: 0.86)) {
            dragOffset = 0
            cursor = index
        }
    }

    /// Force-dismiss the keyboard (resign whatever is first responder). Idempotent;
    /// safe to call when nothing is focused.
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    /// Thin top bar with a leading close button. Tapping leaves the session; the
    /// learner's progress is already saved (per-answer upsert), so nothing extra
    /// to flush.
    private var exitBar: some View {
        HStack {
            Button(action: onFinish) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColor.graphite)
                    .frame(width: 40, height: 40, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Quitter")
            Spacer()
        }
        .padding(.horizontal, Spacing.screenH)
        .padding(.top, Spacing.sm)
    }

    // MARK: - "Trop facile" undo toast

    /// Subtle ink pill: "Marqué trop facile" + an "Annuler" action that demotes the
    /// just-graduated element back to en-cours. Styled with design tokens (not a
    /// system alert); passive — it never blocks the drill or the auto-advance.
    private var tooEasyUndoToast: some View {
        HStack(spacing: Spacing.md) {
            Text("Marqué trop facile")
                .font(.appLabel)
                .foregroundColor(AppColor.paper)
                .lineLimit(1)

            Rectangle()
                .fill(AppColor.paper.opacity(0.25))
                .frame(width: 1, height: 16)

            Button(action: undoTooEasy) {
                Text("Annuler")
                    .font(.appLabel)
                    .fontWeight(.semibold)
                    .tracking(1)
                    .textCase(.uppercase)
                    .foregroundColor(AppColor.saffron)
                    .contentShape(Rectangle())
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityLabel("Annuler · remettre en cours")
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(
            Capsule().fill(AppColor.ink)
                .shadow(color: AppColor.ink.opacity(0.18), radius: 14, y: 6)
        )
    }

    /// Surface the undo toast for `elementID` (called on the too-easy-correct path).
    /// Bumping the token (re)starts the auto-dismiss timer.
    private func presentTooEasyUndo(elementID: String) {
        tooEasyUndoElementID = elementID
        tooEasyUndoToken += 1
    }

    /// "Annuler" → demote the just-graduated element back to en-cours, then hide the
    /// toast. The session has already advanced past it; the demote is a pure data op,
    /// reflected on the book bar at the next `refresh()` (cover dismiss).
    private func undoTooEasy() {
        if let id = tooEasyUndoElementID {
            DataManager.shared.demote(elementID: id)
        }
        dismissTooEasyUndo()
    }

    private func dismissTooEasyUndo() {
        tooEasyUndoElementID = nil
    }

    // MARK: - Element / example driver

    /// `animated` is false only for the very first card (it just appears); element
    /// advances during a session slide the new card in.
    private func startElement(_ index: Int, animated: Bool) {
        elementIndex = index
        pending = buildQueue()
        presentNextExample(animated: animated)
    }

    /// The examples to drill for the current element. Learn: the examples not yet
    /// mastered (from the DB), shuffled; if all are mastered, the full pool. Review:
    /// a single example.
    private func buildQueue() -> [Exercise] {
        guard let element = currentElement else { return [] }
        if mode == .review {
            return [reviewExample(for: element)].compactMap { $0 }
        }
        let mastered = DataManager.shared.fetchReviewStatus(elementID: element.id)?.masteredExampleIDs ?? []
        var remaining = element.examples.filter { !mastered.contains($0.id) }
        if remaining.isEmpty { remaining = element.examples }
        remaining.shuffle()
        // Avoid showing the same sentence twice in a row when there's a choice.
        if remaining.count > 1, remaining.first?.id == lastExampleID { remaining.swapAt(0, 1) }
        return remaining
    }

    private func reviewExample(for element: GrammarElement) -> Exercise? {
        let pool = element.examples.count > 1
            ? element.examples.filter { $0.id != lastExampleID }
            : element.examples
        return pool.randomElement() ?? element.examples.first
    }

    /// Append the next example to the stack. The new card lands at `frontier`
    /// (history.count - 1); the caller decides whether to slide the cursor to it.
    private func presentNextExample(animated: Bool) {
        if pending.isEmpty { pending = buildQueue() }
        guard !pending.isEmpty else { goToNextElement(animated: animated); return }
        let next = pending.removeFirst()
        lastExampleID = next.id
        history.append(next)
        if animated {
            // New card was appended at frontier (cursor + 1), parked off-screen right;
            // sliding the cursor to it brings it in from the right while the old
            // frontier slides out left.
            animateCursor(to: history.count - 1)
        } else {
            cursor = history.count - 1
        }
    }

    private func goToNextElement(animated: Bool) {
        let next = elementIndex + 1
        if next < elements.count {
            startElement(next, animated: animated)
        } else {
            elementIndex = elements.count
            finished = true
        }
    }

    /// Commit forward from the live card to a freshly-generated next card.
    private func advance() {
        // The card we're leaving stays on screen sliding out — suppress its review
        // chrome so it slides away cleanly instead of flashing the explanation.
        hideExplanationAt = cursor
        switch nextAction {
        case .nextExample: presentNextExample(animated: true)
        case .nextElement: goToNextElement(animated: true)
        }
    }

    /// Slide back to the previous (answered, read-only) card. A deliberate
    /// slide-back is exactly when the explanation SHOULD appear, so lift any
    /// suppression first.
    private func goBack() {
        hideExplanationAt = nil
        guard cursor > 0 else { return }
        animateCursor(to: cursor - 1)
    }

    /// Slide forward through already-seen cards toward the live drill. Never passes
    /// the frontier (advancing to a NEW card goes through `advance()`).
    private func goForward() {
        guard cursor < frontier else { return }
        animateCursor(to: cursor + 1)
    }

    // MARK: - Grading (element-level)

    // This only fires from a LIVE drill (DrillView shows Vérifier solely when
    // `reviewData == nil`, i.e. cursor == frontier), so `currentElement`
    // (driven by `elementIndex`) is guaranteed to be the element that produced
    // `history[cursor]`. Keep that gating intact or grading targets the wrong element.
    private func handleResult(correct: Bool, answer: [String]) {
        submittedAnswers[cursor] = answer
        resultByIndex[cursor] = correct
        guard let element = currentElement, history.indices.contains(cursor) else { return }
        // FSRS rating: correct → .good (S grows), wrong → .again (S collapses).
        gradeElement(element, exampleID: history[cursor].id, rating: correct ? .good : .again)
        nextAction = LearnLoop.nextAction(mode: mode, correct: correct)
    }

    /// "Trop facile" gate resolved per element: correct → grade .easy (S/D update),
    /// then suspend (which stamps the sticky graduation) → instant maîtrisé + gone for
    /// good; wrong → clean the element's records (back to fresh/unseen). Either way
    /// move to the next element.
    private func handleTooEasy(correct: Bool, answer: [String]) {
        submittedAnswers[cursor] = answer
        resultByIndex[cursor] = correct
        guard let element = currentElement, history.indices.contains(cursor) else { return }
        if correct {
            // Grade .easy so S/D advance, THEN suspend — `setSuspended` itself calls
            // `markGraduated`, so this is the self-attested-skip graduation path.
            gradeElement(element, exampleID: history[cursor].id, rating: .easy)
            DataManager.shared.setSuspended(elementID: element.id)
            // Surface a passive undo toast — capture THIS element's id now, before the
            // session auto-advances past it, so "Annuler" can demote the right one.
            // Only the too-easy-CORRECT (instant-graduate) path gets the toast.
            presentTooEasyUndo(elementID: element.id)
        } else {
            DataManager.shared.clearReviewStatus(elementID: element.id)
        }
        nextAction = .nextElement
    }

    /// Grade one answer with FSRS. Fetch-or-fresh the element's `ReviewStatus`, advance
    /// `(S, D)` via `FSRS.next` (or seed via `FSRS.initialState` on the first-ever
    /// review), write back stability/difficulty + the FSRS-computed next-review date,
    /// then persist (the upsert also logs a `review_log` row, keeping the History page
    /// working). On a SUCCESSFUL grade that pushes `S` past the graduation bar, stamp
    /// the sticky `graduated_date` via `markGraduated` (idempotent — safe every time).
    /// Reads/writes run on the database's serial queue, so a follow-up read sees this.
    private func gradeElement(_ element: GrammarElement, exampleID: String, rating: FSRS.Rating) {
        let now = Date()
        var status = DataManager.shared.fetchReviewStatus(elementID: element.id)
            ?? ReviewStatus(elementID: element.id)
        let correct = rating != .again

        // Keep the (now non-gating) distinct-correct bookkeeping for History/back-compat.
        if correct { status.recordCorrect(exampleID: exampleID) }

        // FSRS state: first-ever review (no S yet) → seed; otherwise advance over the
        // calendar-day gap since the last review (0 if never reviewed / same day).
        let newState: FSRS.State
        if let s = status.stability, let d = status.difficulty {
            let elapsed = CalendarDays.elapsed(from: status.lastReviewDate, to: now)
            newState = FSRS.next(FSRS.State(stability: s, difficulty: d),
                                 elapsedDays: elapsed, rating: rating)
        } else {
            newState = FSRS.initialState(rating: rating)
        }
        status.stability = newState.stability
        status.difficulty = newState.difficulty
        status.lastReviewDate = now
        // NOTE: `learning_state` is intentionally NOT maintained under FSRS — it's
        // non-gating now (S/D + graduated_date drive everything); it stays at its
        // fetched/seed value and is read only by the one-time v4 backfill.
        // Next review when predicted recall decays to desiredRetention; round to whole
        // days (≥1) so the due-queue's date math stays day-granular, mirroring the old
        // integer-interval scheduling. interval_days is kept in sync for overflow order.
        let intervalDays = max(1, Int(FSRS.intervalDays(stability: newState.stability).rounded()))
        status.intervalDays = intervalDays
        status.nextReviewDate = Calendar.current.date(byAdding: .day, value: intervalDays, to: now) ?? now

        DataManager.shared.upsertReviewStatus(status)

        // Graduation hook: only on success, only once S crosses the 21-day bar. Idempotent.
        if correct && newState.stability >= FSRS.graduationStability {
            DataManager.shared.markGraduated(elementID: element.id, on: now)
        }
    }

    // MARK: - Intro card (one-time English ease-in)

    private var introCard: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Spacer(minLength: Spacing.xl)
            SectionLabel("Leçon")
            Text(title)
                .font(.appTitle)
                .foregroundColor(AppColor.ink)
                .fixedSize(horizontal: false, vertical: true)
            Rectangle().fill(AppColor.hairline).frame(height: 1).padding(.vertical, Spacing.sm)
            Text(ruleNote)
                .font(.appExplain)
                .foregroundColor(AppColor.graphite)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Button("Commencer") {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { showingIntro = false }
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(.horizontal, Spacing.screenH)
        .padding(.bottom, Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - Completion / empty state

    private var completionSummary: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Spacer(minLength: Spacing.xl)
            SectionLabel(title)

            if elements.isEmpty {
                Text(mode == .review ? "Rien à réviser" : "Rien à apprendre")
                    .font(.appDisplay)
                    .foregroundColor(AppColor.ink)
                Text(mode == .review
                     ? "Aucun élément à réviser pour le moment. Reviens plus tard."
                     : "Tu as parcouru tout le contenu disponible.")
                    .font(.appExplain)
                    .foregroundColor(AppColor.graphite)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Terminé")
                    .font(.appDisplay)
                    .foregroundColor(AppColor.ink)
                HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                    Text("\(correctCount)")
                        .font(.appPrompt)
                        .foregroundColor(AppColor.ink)
                    Text("/ \(answeredCount) correct")
                        .font(.appTitle)
                        .foregroundColor(AppColor.graphite)
                }
            }

            Rectangle().fill(AppColor.hairline).frame(height: 1).padding(.vertical, Spacing.sm)
            Spacer()
            Button("Terminer") { onFinish() }
                .buttonStyle(PrimaryButtonStyle())
        }
        .padding(.horizontal, Spacing.screenH)
        .padding(.bottom, Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Preview

#Preview {
    DrillSessionView(title: "Test", ruleNote: "An English lesson intro.",
                     elements: [GrammarElement.sample], mode: .learn, onFinish: {})
}
