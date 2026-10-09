//
//  DrillView.swift
//  carambole
//
//  Single-exercise drill card (07 · Aimants). Renders the prompt, the input
//  (word magnets for build / multiple choice, or the typed baseline), the
//  "Trop facile" gate, and the fixed Vérifier → Suivant pill. The session's top
//  bar (✕, label, chevrons, ring) lives in `DrillSessionView` so it stays put
//  while cards slide.
//

import SwiftUI
import UIKit

struct DrillView: View {
    /// A previously-answered drill being revisited: the tokens the user
    /// submitted and whether they were correct. Renders read-only.
    struct ReviewData: Equatable {
        let answer: [String]
        let correct: Bool
    }

    /// The exercise to drill.
    let exercise: Exercise
    /// Called once when the answer is checked, with the result + submitted tokens.
    var onResult: (Bool, [String]) -> Void = { _, _ in }
    /// Called instead of `onResult` when the user marked this drill "too easy"
    /// before answering (the answer-once gate). The parent suspends the exercise
    /// on a correct answer, or cleans its records on a wrong one. Same payload as
    /// `onResult`: (correct, submitted tokens).
    var onTooEasy: (Bool, [String]) -> Void = { _, _ in }
    /// Called when the user taps "Next" to advance to the following exercise.
    var onNext: () -> Void = {}
    /// Called to move forward (out of review, back toward the live drill).
    var onForward: () -> Void = {}
    /// Non-nil when revisiting an already-answered drill: show it read-only.
    var reviewData: ReviewData? = nil

    /// How long the weld + `wght` wave shows before auto-advancing.
    private let correctAdvanceDelay: TimeInterval = 1.0

    /// Opt-in: read the model sentence aloud automatically on a correct answer.
    /// OFF by default. Same UserDefaults key the `StudySettingsStore` toggle writes
    /// ("settings.autoSpeak") — they stay in sync via UserDefaults.standard.
    @AppStorage("settings.autoSpeak") private var autoSpeak = false

    @State private var answer: [String] = []
    @State private var checked = false
    @State private var isCorrect = false
    /// Whether the tap-to-reveal English hint is shown. Reset per-exercise
    /// automatically because DrillSessionView re-creates DrillView via `.id`.
    @State private var showHint = false
    /// Set when the user taps "Trop facile": the drill enters the answer-once gate.
    /// They must still answer correctly to remove it; a miss keeps it in the stack.
    @State private var pendingTooEasy = false
    /// True once a too-easy gate is passed, so the green footer reads "Retiré".
    @State private var didRemove = false

    private var hasAnswer: Bool { !answer.isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            // Vertical is LOCKED — no ScrollView. The card content is sized to the
            // available height by `GeometryReader`: when space is tight (typing, with
            // the keyboard up, shrinks this region — see DrillSessionView.keyboardInset)
            // it collapses to a `compact` layout that drops the secondary chrome
            // (translation, cue, Indice/Écouter) so the prompt + input + footer always
            // fit without scrolling. Text additionally shrinks via minimumScaleFactor.
            GeometryReader { geo in
                let compact = geo.size.height < 540
                contentStack(spacing: compact ? Spacing.md : Spacing.lg, compact: compact)
                    .frame(maxWidth: .infinity, minHeight: geo.size.height,
                           alignment: .top)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

            // Pinned footer: the primary action stays reachable. On a wrong LIVE
            // answer the correct answer sits compactly directly above "Suivant".
            VStack(spacing: Spacing.sm) {
                // "Too easy" affordance — only before checking, never in review.
                if !checked && reviewData == nil {
                    tooEasyControl
                }
                // (A wrong LIVE answer shows "Réponse : …" under the input's
                // baseline — see DrillFeedbackLine — not here.)
                actionButton
            }
            .padding(.horizontal, Spacing.screenH)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.sm)
            .background(AppColor.paper)
        }
        .background(AppColor.paper.ignoresSafeArea())
    }

    /// The card body, laid out top-down. `compact` drops the secondary chrome to
    /// fit a constrained height (e.g. keyboard up); `spacing` tightens the gaps.
    @ViewBuilder
    private func contentStack(spacing: CGFloat, compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: spacing) {
            promptBlock(compact: compact)

            if let review = reviewData {
                // Read-only revisit: show what was submitted, the result, the
                // correct answer (if wrong), and the full bilingual explanation.
                submittedAnswerBlock(review.answer)
                reviewResultBlock(correct: review.correct)
            } else {
                inputBlock
            }
        }
        .padding(.horizontal, Spacing.screenH)
        .padding(.top, compact ? Spacing.sm : Spacing.md)
        .padding(.bottom, Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Prompt

    /// `compact` (tight height, e.g. keyboard up) hides the secondary chrome —
    /// cue, the always-on translation, and the Indice/Écouter assist row — so the
    /// prompt + input + footer fit without scrolling. The prompt itself always
    /// shows, shrinking via `minimumScaleFactor` before it would clip.
    private func promptBlock(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Cue: small label above the prompt (07 "Construis la phrase").
            if !compact, let cue = exercise.cue, !cue.isEmpty {
                Text(cue)
                    .uppercaseLabel()
            }

            Text(Self.blankedPrompt(exercise.prompt))
                .font(.appPrompt)
                .tracking(-0.7)
                .lineSpacing(2)
                .foregroundColor(AppColor.ink)
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Always-on, subtle English translation — one quiet line (hidden when compact).
            if !compact, let translation = exercise.translation, !translation.isEmpty {
                Text("“\(translation)”")
                    .font(.appBody)
                    .foregroundColor(AppColor.g2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Opt-in assists on one line: English "Indice" (left, when present) and
            // "Écouter" (right, always) — the learner chooses to reveal/hear.
            // Hidden when compact to reclaim vertical space.
            if !compact {
                assistRow
                    .padding(.top, 4)
            }
        }
    }

    /// Width of a blank slot: 4 figure spaces (`\u{2007}`) — reads clearly as a gap
    /// yet never leaks the answer's length.
    private static let blankSlot = String(repeating: "\u{2007}", count: 4)
    /// Zero-width, non-breaking, NON-whitespace anchor (U+2060 WORD JOINER). Bracketing
    /// the whitespace slot with it keeps the slot off the start/end of any (possibly
    /// wrapped) line, where SwiftUI trims trailing/leading whitespace and the underline
    /// would silently vanish.
    private static let wordJoiner = "\u{2060}"

    /// Renders the prompt with each underscore "blank" (`___`) drawn as ONE
    /// continuous underline instead of literal underscore glyphs, which render with
    /// visible gaps in the prompt face.
    ///
    /// Each slot is wrapped in WORD JOINERs so a blank that lands at the very start or
    /// end of the prompt (e.g. "des ___" / "___ tu as faim") still shows its underline:
    /// the slot is pure whitespace, which SwiftUI trims at line edges, so without the
    /// anchors the underline disappears for exactly those prompts.
    static func blankedPrompt(_ prompt: String) -> AttributedString {
        var result = AttributedString()
        var run = ""
        func flush() {
            if !run.isEmpty { result.append(AttributedString(run)); run = "" }
        }
        let chars = Array(prompt)
        var i = 0
        while i < chars.count {
            if chars[i] == "_" {
                while i < chars.count && chars[i] == "_" { i += 1 }   // consume run
                flush()
                result.append(AttributedString(wordJoiner))            // leading anchor
                var slot = AttributedString(blankSlot)
                slot.underlineStyle = .single                          // one solid line
                result.append(slot)
                result.append(AttributedString(wordJoiner))            // trailing anchor
            } else {
                run.append(chars[i]); i += 1
            }
        }
        flush()
        return result
    }

    #if DEBUG
    static func _selfTest() {
        // Trailing blank: the slot must be anchored by a non-whitespace WORD JOINER so
        // SwiftUI doesn't trim the underline off the end of the line.
        let trailing = blankedPrompt("des ___")
        assert(trailing.characters.last == "\u{2060}", "trailing blank not anchored")
        // Leading blank: anchored at the front too.
        let leading = blankedPrompt("___ tu as faim")
        assert(leading.characters.first == "\u{2060}", "leading blank not anchored")
        // The figure-space slot is present, underlined, and no raw underscores leak.
        assert(String(trailing.characters).contains("\u{2007}"), "blank slot missing")
        assert(trailing.runs.contains { $0.underlineStyle == .single }, "slot not underlined")
        assert(!String(blankedPrompt("a ___ b").characters).contains("_"), "underscores leaked")
        // A prompt with no blank is passed through unchanged.
        assert(String(blankedPrompt("Bonjour").characters) == "Bonjour", "plain prompt altered")
    }
    #endif

    // MARK: - Learner assists (Indice + Écouter), one line

    /// One line of opt-in assists: tap-to-reveal English "Indice" (left, only when
    /// the exercise has a hint) and "Écouter" (right, always). Both are deliberate
    /// taps — nothing is shown or played automatically. The revealed hint text drops
    /// in below the row.
    private var assistRow: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .center) {
                if let hint = exercise.hint, !hint.isEmpty {
                    indiceButton
                }
                Spacer(minLength: Spacing.sm)
                listenButton
            }
            if showHint, let hint = exercise.hint, !hint.isEmpty {
                Text(hint)
                    .font(.appBody)
                    .foregroundColor(AppColor.graphite)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    /// Tap-to-reveal English grammar hint toggle.
    private var indiceButton: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                showHint.toggle()
            }
        } label: {
            HStack(spacing: 6) {
                Text("Indice").uppercaseLabel(AppColor.ink)
                Text("↓")
                    .font(.appLabel)
                    .foregroundColor(AppColor.ink)
                    .rotationEffect(.degrees(showHint ? 180 : 0))
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// Opt-in "hear the sentence" hint, available while solving. Plays the bundled
    /// model audio (or on-device synth) of `spokenFrench`. The learner decides
    /// whether hearing the model sentence helps — this reads the full sentence, so
    /// it's a chosen hint, not a passive aid (auto-play stays an off-by-default
    /// Settings toggle).
    private var listenButton: some View {
        Button { Speaker.shared.speak(exercise.spokenFrench, key: exercise.audioKey) } label: {
            HStack(spacing: 6) {
                Image(systemName: "speaker.wave.2")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(AppColor.ink)
                Text("Écouter").uppercaseLabel(AppColor.ink)
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Écouter la phrase")
    }

    // MARK: - Input

    /// nil until checked; then the live result (drives weld / shake / feedback).
    private var liveResult: Bool? { checked ? isCorrect : nil }

    @ViewBuilder
    private var inputBlock: some View {
        switch exercise.resolvedInputMode {
        case .buildFromTokens:
            // Slots GROW as chips are placed (a placed chip stays faded in the bank
            // AND shows in the slots), so a long answer can outgrow the locked card.
            // Give just the slots+bank their own bounded scroll — `.basedOnSize` means
            // normal drills never scroll (locked feel holds), but a fully-built 10-slot
            // construis can always reach every chip. Prompt + footer stay fixed.
            ScrollView {
                TokenBuilderView(exercise: exercise, answer: $answer, isLocked: checked,
                                 result: liveResult)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollBounceBehavior(.basedOnSize)
            // Leftover tiles drop off-screen on a correct weld — don't clip them.
            .scrollClipDisabled()
        case .multipleChoice:
            ChoiceView(exercise: exercise, answer: $answer, isLocked: checked,
                       result: liveResult)
        case .freeText:
            TypeAnswerView(exercise: exercise, answer: $answer, isLocked: checked,
                           result: liveResult)
        }
    }

    // MARK: - Submitted answer (review mode)

    /// The tokens the user submitted, shown read-only when revisiting a drill.
    private func submittedAnswerBlock(_ tokens: [String]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Votre réponse")
                .uppercaseLabel()
            Text(tokens.isEmpty ? "—" : Exercise.displayJoin(tokens))
                .font(.display(size: 22, wght: 300))
                .tracking(-0.4)
                .foregroundColor(AppColor.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Review result (read-only revisit only)

    /// Result block shown ONLY when revisiting an already-answered drill
    /// (`reviewData != nil`). Shows correctness, the correct answer if it was a
    /// miss, and the FULL bilingual rule explanation (French, then the subtler
    /// English line). Live drills never render this — a wrong live answer shows
    /// only "Réponse : …" under the input baseline (`DrillFeedbackLine`).
    private func reviewResultBlock(correct: Bool) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // State by form, not hue: solid rule = right, dashed rule = wrong.
            Line()
                .stroke(AppColor.ink, style: StrokeStyle(lineWidth: 1, dash: correct ? [] : [4, 3]))
                .frame(height: 1)

            Text(correct ? "Juste" : "Pas tout à fait")
                .font(.display(size: 22, wght: 300))
                .tracking(-0.4)
                .foregroundColor(AppColor.ink)
            // (Audio is on the prompt's "Écouter" assist row above, shown in both
            // solving and review — no separate speaker needed here.)

            if !correct {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Réponse")
                        .uppercaseLabel()
                    Text(Exercise.displayJoin(exercise.answerTokens))
                        .font(.display(size: 22, wght: 300))
                        .tracking(-0.4)
                        .foregroundColor(AppColor.ink)
                }
            }

            // Full rule explanation — French, then a subtler English rendering
            // beneath it (bilingual explanation). English shows when populated.
            // The card itself is locked (no scroll); a long explanation gets its
            // OWN bounded scroll so it never pushes the card past the screen.
            // `.basedOnSize` keeps short explanations static (no scroll at all),
            // so the locked feel holds for the common case.
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    Text(exercise.explanation)
                        .font(.appBody)
                        .foregroundColor(AppColor.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    if let english = exercise.displayExplanationEN {
                        Text(english)
                            .font(.appBody)
                            .foregroundColor(AppColor.g2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollBounceBehavior(.basedOnSize)
            .frame(maxHeight: 220)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - "Too easy" gate control

    /// Sits just above the footer button before checking. Tapping "Trop facile"
    /// arms the answer-once gate; while armed it shows a reminder + an Annuler
    /// escape. The actual remove/clean happens in `check()` on the next answer.
    @ViewBuilder
    private var tooEasyControl: some View {
        if pendingTooEasy {
            HStack(spacing: Spacing.sm) {
                Text("Réponds correctement pour le retirer")
                    .uppercaseLabel(AppColor.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: Spacing.sm)
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        pendingTooEasy = false
                    }
                } label: {
                    Text("Annuler").uppercaseLabel(AppColor.ink).underline()
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .transition(.opacity)
        } else {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                    pendingTooEasy = true
                }
            } label: {
                Text("Trop facile — retirer")
                    .uppercaseLabel()
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Action button (Check → Next)

    @ViewBuilder
    private var actionButton: some View {
        if reviewData != nil {
            // Read-only revisit: the only action is to move forward again.
            Button("Suivant") { onForward() }
                .buttonStyle(PrimaryButtonStyle())
        } else if checked {
            if isCorrect {
                // Non-interactive green confirmation; auto-advances after a beat.
                correctConfirmation
            } else {
                Button("Suivant") { onNext() }
                    .buttonStyle(PrimaryButtonStyle())
            }
        } else {
            Button("Vérifier") { check() }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!hasAnswer)
                .opacity(hasAnswer ? 1.0 : 0.25)
                .animation(.easeOut(duration: 0.25), value: hasAnswer)
        }
    }

    /// Mirrors PrimaryButtonStyle's footprint so the footer doesn't jump when it
    /// swaps from "Vérifier" to this (non-interactive) confirmation.
    private var correctConfirmation: some View {
        Text(didRemove ? "Retiré" : "Juste")
            .font(.display(size: 16, wght: 400))
            .foregroundColor(AppColor.ink)
            .frame(maxWidth: .infinity, minHeight: 54, maxHeight: 54)
            .overlay(Capsule().strokeBorder(AppColor.ink, lineWidth: 1))
    }

    // MARK: - Logic

    private func check() {
        let correct = DrillEngine.check(answer, exercise)
        UINotificationFeedbackGenerator().notificationOccurred(correct ? .success : .error)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            isCorrect = correct
            checked = true
        }
        if pendingTooEasy {
            // Gate: correct removes the drill for good; wrong cleans its records
            // and leaves it in the stack (re-markable next time). Either way the
            // parent owns the persistence — see DrillSessionView.onTooEasy.
            didRemove = correct
            onTooEasy(correct, answer)
        } else {
            onResult(correct, answer)
        }

        // Correct → linger on the green confirmation briefly, then auto-advance.
        // Wrong → stay put; the learner reads the answer and taps Suivant.
        if correct {
            // No banner is shown on a correct answer (it auto-advances), so — when the
            // learner has opted into auto-play — read the sentence aloud here. A wrong
            // answer keeps its banner with a tappable speaker either way. Speech
            // continues across the advance (Speaker is shared).
            if autoSpeak {
                Speaker.shared.speak(exercise.spokenFrench, key: exercise.audioKey)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + correctAdvanceDelay) {
                onNext()
            }
        }
    }
}

// MARK: - Line

/// A horizontal line across the full width (for solid or dashed rules).
struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return p
    }
}

// MARK: - Preview

#Preview {
    DrillView(exercise: .sample, onResult: { _, _ in }, onNext: {})
}
