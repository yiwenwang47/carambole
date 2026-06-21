//
//  DrillView.swift
//  carambole
//
//  "Le Cahier" single-exercise drill card. Renders the prompt framed by the
//  corner-bracket brand motif, the appropriate input (token-build or
//  multiple-choice), a Check button, and a result banner with the rule
//  explanation. Built entirely from the design system — no FlashcardView symbols.
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
    /// Session progress (0...1) for the corner progress ring.
    var progress: Double = 0
    /// Called once when the answer is checked, with the result + submitted tokens.
    var onResult: (Bool, [String]) -> Void = { _, _ in }
    /// Called instead of `onResult` when the user marked this drill "too easy"
    /// before answering (the answer-once gate). The parent suspends the exercise
    /// on a correct answer, or cleans its records on a wrong one. Same payload as
    /// `onResult`: (correct, submitted tokens).
    var onTooEasy: (Bool, [String]) -> Void = { _, _ in }
    /// Called when the user taps "Next" to advance to the following exercise.
    var onNext: () -> Void = {}
    /// Whether a previous exercise exists to return to.
    var canGoBack: Bool = false
    /// Called when the user taps the back chevron to revisit the previous drill.
    var onBack: () -> Void = {}
    /// Whether a later exercise exists to move forward to.
    var canGoForward: Bool = false
    /// Called to move forward (out of review, back toward the live drill).
    var onForward: () -> Void = {}
    /// Non-nil when revisiting an already-answered drill: show it read-only.
    var reviewData: ReviewData? = nil

    /// How long the green "Correct" confirmation shows before auto-advancing.
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
            // Content scrolls ONLY when it overflows (long prompt, many tokens, an
            // expanded Indice, or the full review block) — `.basedOnSize` keeps short
            // drills static (no bounce, looks like a fixed card). The footer below is
            // pinned OUTSIDE the scroll, so "Suivant" is always reachable.
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    header

                    promptBlock

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
                .padding(.top, Spacing.xl)
                .padding(.bottom, Spacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollBounceBehavior(.basedOnSize)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

            // Pinned footer: the primary action stays reachable. On a wrong LIVE
            // answer the correct answer sits compactly directly above "Suivant".
            VStack(spacing: Spacing.sm) {
                // "Too easy" affordance — only before checking, never in review.
                if !checked && reviewData == nil {
                    tooEasyControl
                }
                // Wrong LIVE answer: show ONLY the correct answer, just above the
                // button. No banner, no explanation (that lives in review mode).
                if checked && !isCorrect && reviewData == nil {
                    correctAnswerHint
                }
                actionButton
            }
            .padding(.horizontal, Spacing.screenH)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.md)
            .background(AppColor.paper)
        }
        .background(AppColor.paper.ignoresSafeArea())
    }

    // Navigation between drills is driven by the finger-tracked card stack in
    // DrillSessionView (the carousel), which owns the horizontal drag gesture. The
    // header chevrons (onBack/onForward) remain as an explicit fallback.

    // MARK: - Header (label + progress ring)

    private var header: some View {
        HStack(alignment: .center) {
            if canGoBack {
                navChevron("chevron.left", label: "Exercice précédent", action: onBack)
                    .padding(.trailing, Spacing.sm)
            }
            SectionLabel(reviewData != nil ? "Révision" : "Exercice")
            Spacer()
            if canGoForward {
                navChevron("chevron.right", label: "Exercice suivant", action: onForward)
                    .padding(.trailing, Spacing.sm)
            }
            ProgressRing(progress: progress, size: 36, lineWidth: 4)
        }
    }

    /// Small "écouter" control that reads a French string aloud via `Speaker`.
    private func speakButton(_ text: String) -> some View {
        Button { Speaker.shared.speak(text) } label: {
            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColor.saffronDeep)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Écouter la phrase")
    }

    private func navChevron(_ systemName: String, label: String,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppColor.graphite)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    // MARK: - Prompt, framed by corner brackets

    private var promptBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            CornerBracketFrame {
                Text(Self.blankedPrompt(exercise.prompt))
                    .font(.appPrompt)
                    .foregroundColor(AppColor.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let cue = exercise.cue, !cue.isEmpty {
                Text(cue)
                    .uppercaseLabel()
                    .padding(.leading, Spacing.sm)
            }

            // Always-on, subtle English translation — one quiet line.
            if let translation = exercise.translation, !translation.isEmpty {
                Text("“\(translation)”")
                    .font(.appExplain)
                    .foregroundColor(AppColor.graphite)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, Spacing.sm)
            }

            // Tap-to-reveal English grammar hint, only when one exists.
            if let hint = exercise.hint, !hint.isEmpty {
                hintControl(hint)
                    .padding(.leading, Spacing.sm)
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
    /// visible gaps in the serif prompt face.
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

    // MARK: - Hint (tap-to-reveal)

    @ViewBuilder
    private func hintControl(_ hint: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    showHint.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Indice")
                        .font(.appLabel)
                        .textCase(.uppercase)
                        .tracking(2)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .rotationEffect(.degrees(showHint ? 180 : 0))
                }
                .foregroundColor(showHint ? AppColor.saffronDeep : AppColor.graphite)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showHint {
                Text(hint)
                    .font(.appExplain)
                    .foregroundColor(AppColor.graphite)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Input

    @ViewBuilder
    private var inputBlock: some View {
        switch exercise.resolvedInputMode {
        case .buildFromTokens:
            TokenBuilderView(exercise: exercise, answer: $answer, isLocked: checked)
        case .multipleChoice:
            ChoiceView(exercise: exercise, answer: $answer, isLocked: checked)
        case .freeText:
            TypeAnswerView(exercise: exercise, answer: $answer, isLocked: checked)
        }
    }

    // MARK: - Submitted answer (review mode)

    /// The tokens the user submitted, shown read-only when revisiting a drill.
    private func submittedAnswerBlock(_ tokens: [String]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Votre réponse")
                .uppercaseLabel()
            Text(tokens.isEmpty ? "—" : Exercise.displayJoin(tokens))
                .font(.appToken)
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
    /// only the compact `correctAnswerHint` in the footer instead.
    private func reviewResultBlock(correct: Bool) -> some View {
        let tint = correct ? AppColor.success : AppColor.error
        return VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(tint)
                Text(correct ? "Correct" : "Pas tout à fait")
                    .font(.appTitle)
                    .foregroundColor(tint)
                Spacer()
                // Hear the correct French sentence read aloud. Only ever shown after
                // checking (here in review), so it can't leak the answer.
                speakButton(exercise.spokenFrench)
            }

            if !correct {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Réponse")
                        .uppercaseLabel()
                    Text(Exercise.displayJoin(exercise.answerTokens))
                        .font(.appToken)
                        .foregroundColor(AppColor.ink)
                }
            }

            // Full rule explanation — French, then a subtler English rendering
            // beneath it (bilingual explanation). English shows when populated.
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.explanation)
                    .font(.appExplain)
                    .foregroundColor(AppColor.ink)
                    .fixedSize(horizontal: false, vertical: true)

                if let english = exercise.explanationEN, !english.isEmpty {
                    Text(english)
                        .font(.appExplain)
                        .foregroundColor(AppColor.graphite)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(tint.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(tint.opacity(0.4), lineWidth: 1)
        )
    }

    // MARK: - Wrong live answer (compact, footer)

    /// Shown directly above "Suivant" on a WRONG live answer: just the correct
    /// answer, compactly. No banner, no explanation — that's reserved for review.
    private var correctAnswerHint: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Réponse")
                .uppercaseLabel()
            Text(Exercise.displayJoin(exercise.answerTokens))
                .font(.appToken)
                .foregroundColor(AppColor.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .transition(.opacity)
    }

    // MARK: - "Too easy" gate control

    /// Sits just above the footer button before checking. Tapping "Trop facile"
    /// arms the answer-once gate; while armed it shows a reminder + an Annuler
    /// escape. The actual remove/clean happens in `check()` on the next answer.
    @ViewBuilder
    private var tooEasyControl: some View {
        if pendingTooEasy {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "checkmark.seal")
                    .font(.system(size: 13, weight: .semibold))
                Text("Réponds correctement pour le retirer")
                    .font(.appLabel)
                Spacer()
                Button("Annuler") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        pendingTooEasy = false
                    }
                }
                .font(.appLabel)
                .buttonStyle(.plain)
            }
            .foregroundColor(AppColor.saffronDeep)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(AppColor.saffron.opacity(0.16))
            )
            .transition(.opacity)
        } else {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                    pendingTooEasy = true
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Trop facile — retirer")
                        .font(.appLabel)
                        .textCase(.uppercase)
                        .tracking(1.5)
                }
                .foregroundColor(AppColor.graphite)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
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
                .opacity(hasAnswer ? 1.0 : 0.5)
        }
    }

    /// Mirrors PrimaryButtonStyle's footprint so the footer doesn't jump when it
    /// swaps from "Vérifier" to this confirmation.
    private var correctConfirmation: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: didRemove ? "checkmark.seal.fill" : "checkmark.circle.fill")
            Text(didRemove ? "Retiré" : "Correct")
                .font(.appLabel)
                .fontWeight(.semibold)
                .tracking(1)
                .textCase(.uppercase)
        }
        .foregroundColor(AppColor.success)
        .padding(.vertical, Spacing.md)
        .padding(.horizontal, Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppColor.success.opacity(0.14))
        )
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
                Speaker.shared.speak(exercise.spokenFrench)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + correctAdvanceDelay) {
                onNext()
            }
        }
    }
}

// MARK: - Corner bracket motif

/// Frames content with the brand's corner-bracket motif (recreated locally for
/// T5 — does NOT depend on the soon-to-be-deleted FlashcardView `BracketView`).
/// Draws an `ink` left top-bracket and right bottom-bracket around its content.
struct CornerBracketFrame<Content: View>: View {
    var armLength: CGFloat = 16
    var lineWidth: CGFloat = 2.5
    var color: Color = AppColor.ink
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(Spacing.md)
            .overlay(alignment: .topLeading) {
                CornerBracket(corner: .topLeading, armLength: armLength, lineWidth: lineWidth)
                    .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                    .frame(width: armLength, height: armLength)
            }
            .overlay(alignment: .bottomTrailing) {
                CornerBracket(corner: .bottomTrailing, armLength: armLength, lineWidth: lineWidth)
                    .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                    .frame(width: armLength, height: armLength)
            }
    }
}

/// A single right-angle corner bracket (two arms meeting at one corner).
private struct CornerBracket: Shape {
    enum Corner { case topLeading, bottomTrailing }
    let corner: Corner
    var armLength: CGFloat
    var lineWidth: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        switch corner {
        case .topLeading:
            // ┌ — vertical arm down, horizontal arm right, meeting at top-left.
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        case .bottomTrailing:
            // ┘ — horizontal arm left, vertical arm up, meeting at bottom-right.
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        }
        return path
    }
}

// MARK: - Preview

#Preview {
    DrillView(exercise: .sample, progress: 0.4, onResult: { _, _ in }, onNext: {})
}
