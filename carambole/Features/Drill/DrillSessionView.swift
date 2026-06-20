//
//  DrillSessionView.swift
//  carambole
//
//  Drives a study session over GRAMMAR ELEMENTS (not a flat exercise list). The
//  SRS unit is the element; each element is drilled via its example sentences,
//  shuffled so the learner masters the rule, not a memorized token order.
//
//  Two modes:
//  - .learn  — walk each element, drilling shuffled examples until the element is
//              mastered (`masteryThreshold` distinct examples answered correctly),
//              then advance. Used by "Apprendre" and by tapping a module.
//  - .review — one fresh example per due element, SRS-regraded. Used by "Réviser".
//
//  See docs/plans/2026-06-19-book-modules-elements-design.md.
//

import SwiftUI

struct DrillSessionView: View {
    enum Mode { case learn, review }

    let title: String
    /// English module intro shown once on the "Leçon" card. Empty → no card.
    let ruleNote: String
    let elements: [GrammarElement]
    let mode: Mode
    let masteryThreshold: Int
    var onFinish: () -> Void = {}

    init(title: String, ruleNote: String, elements: [GrammarElement], mode: Mode,
         masteryThreshold: Int = StudySettings.masteryThreshold,
         onFinish: @escaping () -> Void = {}) {
        self.title = title
        self.ruleNote = ruleNote
        self.elements = elements
        self.mode = mode
        self.masteryThreshold = masteryThreshold
        self.onFinish = onFinish
    }

    private enum NextAction { case nextExample, nextElement }

    @State private var elementIndex = 0
    /// Pending examples for the current element (learn mode queue).
    @State private var pending: [Exercise] = []
    @State private var lastExampleID: String?
    @State private var nextAction: NextAction = .nextElement

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
    /// Direction of the last cursor move, so the slide matches the intent:
    /// forward = new drill enters from the right; back = it enters from the left.
    @State private var navBack = false

    @State private var finished = false
    @State private var showingIntro = true

    private var answeredCount: Int { resultByIndex.count }
    private var correctCount: Int { resultByIndex.values.filter { $0 }.count }
    /// The cursor sits behind the frontier → showing an answered drill read-only.
    private var isReviewing: Bool { cursor < history.count - 1 }

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
                        DrillView(
                            exercise: history[cursor],
                            progress: progress,
                            onResult: { correct, tokens in handleResult(correct: correct, answer: tokens) },
                            onTooEasy: { correct, tokens in handleTooEasy(correct: correct, answer: tokens) },
                            onNext: advance,
                            canGoBack: cursor > 0,
                            onBack: goBack,
                            canGoForward: isReviewing,
                            onForward: goForward,
                            reviewData: isReviewing
                                ? DrillView.ReviewData(answer: submittedAnswers[cursor] ?? [],
                                                       correct: resultByIndex[cursor] ?? false)
                                : nil
                        )
                        .id(cursor)
                        // Continuous directional push: the incoming and outgoing drills
                        // slide together in the same direction (next = leftward, back =
                        // rightward). No opacity fade — the white paper background hides
                        // the brief seam, so it reads as one clean slide, not a cross-over.
                        .transition(.asymmetric(
                            insertion: .move(edge: navBack ? .leading : .trailing),
                            removal: .move(edge: navBack ? .trailing : .leading)
                        ))
                    }
                }
            }
        }
        .onAppear {
            if history.isEmpty && !elements.isEmpty { startElement(0) }
        }
        .animation(.easeInOut(duration: 0.3), value: cursor)
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: finished)
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: showingIntro)
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

    // MARK: - Element / example driver

    private func startElement(_ index: Int) {
        elementIndex = index
        pending = buildQueue()
        presentNextExample()
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

    private func presentNextExample() {
        if pending.isEmpty { pending = buildQueue() }
        guard !pending.isEmpty else { goToNextElement(); return }
        let next = pending.removeFirst()
        lastExampleID = next.id
        history.append(next)
        navBack = false
        cursor = history.count - 1
    }

    private func goToNextElement() {
        let next = elementIndex + 1
        if next < elements.count {
            startElement(next)
        } else {
            elementIndex = elements.count
            navBack = false
            finished = true
        }
    }

    private func advance() {
        switch nextAction {
        case .nextExample: presentNextExample()
        case .nextElement: goToNextElement()
        }
    }

    /// Step back to the previous presented drill, shown read-only.
    private func goBack() { if cursor > 0 { navBack = true; cursor -= 1 } }

    /// Step forward out of review toward the live drill. Never passes the frontier.
    private func goForward() { if cursor < history.count - 1 { navBack = false; cursor += 1 } }

    // MARK: - Grading (element-level)

    // This only fires from a LIVE drill (DrillView shows Vérifier solely when
    // `reviewData == nil`, i.e. cursor == frontier), so `currentElement`
    // (driven by `elementIndex`) is guaranteed to be the element that produced
    // `history[cursor]`. Keep that gating intact or grading targets the wrong element.
    private func handleResult(correct: Bool, answer: [String]) {
        submittedAnswers[cursor] = answer
        resultByIndex[cursor] = correct
        guard let element = currentElement, history.indices.contains(cursor) else { return }
        gradeElement(element, exampleID: history[cursor].id, correct: correct)

        if mode == .review {
            nextAction = .nextElement
        } else {
            nextAction = isMastered(element) ? .nextElement : .nextExample
        }
    }

    /// "Trop facile" gate resolved per element: correct → master this example, then
    /// suspend the element (gone for good); wrong → clean the element's records
    /// (back to fresh/unseen). Either way move to the next element.
    private func handleTooEasy(correct: Bool, answer: [String]) {
        submittedAnswers[cursor] = answer
        resultByIndex[cursor] = correct
        guard let element = currentElement, history.indices.contains(cursor) else { return }
        if correct {
            gradeElement(element, exampleID: history[cursor].id, correct: true)
            DataManager.shared.setSuspended(elementID: element.id)
        } else {
            DataManager.shared.clearReviewStatus(elementID: element.id)
        }
        nextAction = .nextElement
    }

    /// Fetch-or-fresh → record the correct example → SRS grade → upsert. Reads/writes
    /// run on the database's serial queue, so the follow-up `isMastered` read sees
    /// this write.
    private func gradeElement(_ element: GrammarElement, exampleID: String, correct: Bool) {
        var status = DataManager.shared.fetchReviewStatus(elementID: element.id)
            ?? SRSScheduler.fresh(element.id)
        if correct { status.recordCorrect(exampleID: exampleID) }
        status = SRSScheduler.grade(status, pass: correct, now: Date())
        DataManager.shared.upsertReviewStatus(status)
    }

    private func isMastered(_ element: GrammarElement) -> Bool {
        (DataManager.shared.fetchReviewStatus(elementID: element.id)?.distinctCorrect ?? 0) >= masteryThreshold
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
