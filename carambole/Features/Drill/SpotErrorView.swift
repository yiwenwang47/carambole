//
//  SpotErrorView.swift
//  carambole
//
//  Input for `inputMode == .spotError`: a full sentence with ONE wrong word.
//  Tap the wrong word → it takes a dashed frame and its fixes appear below; tap
//  a fix → it springs into the slot. A tap on a right word shakes it and dims it
//  (one miss); after two misses the error is shown. The fixes stay hidden until
//  the error is found, because they would point at the slot.
//
//  The parent owns `answer` (the sentence with the chosen fix, empty until one
//  is picked) and `misses` (feeds the FSRS grade: a miss turns `.good` into `.hard`).
//

import SwiftUI
import UIKit

struct SpotErrorView: View {
    let exercise: Exercise
    @Binding var answer: [String]
    @Binding var misses: Int
    var isLocked: Bool = false
    /// nil until checked; then whether the answer was right.
    var result: Bool? = nil

    /// Misses before the error is shown for the learner.
    static let missesBeforeReveal = 2

    @State private var found = false
    @State private var dimmed: Set<Int> = []
    @State private var shakes: [Int: Int] = [:]
    @State private var pick: Int?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(AppPalette.storageKey) private var paletteID = AppPalette.fallback.rawValue
    @AppStorage(DrillStyle.storageKey) private var drillStyleID = DrillStyle.fallback.rawValue

    private var spot: SpotError? { exercise.spot }
    private var theme: AppTheme { AppPalette(stored: paletteID).theme }
    /// Fixes in a stable per-id order, so the right one has no fixed position.
    private var options: [String] {
        Exercise.deterministicShuffle(spot?.options ?? [], seed: Exercise.seed64(exercise.id))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let spot {
                FlowLayout(spacing: 4, lineSpacing: 10) {
                    ForEach(Array(spot.tokens.enumerated()), id: \.offset) { i, token in
                        word(i, token, isError: i == spot.wrongIndex)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(status)
                    .font(.appBody)
                    .foregroundColor(AppColor.graphite)
                    .padding(.top, 14)
                    .animation(.easeOut(duration: 0.2), value: status)
                // Glued like the audio text ("J'ai", not "J' ai").
                DrillFeedbackLine(result: result,
                                  answer: Exercise.spokenFrench(prompt: "",
                                      answer: Exercise.displayJoin(exercise.answerTokens),
                                      hasBlank: false))
                    .padding(.top, 4)

                // Wrong answer: the rule, French then English, under "Réponse".
                if result == false {
                    explanation
                        .padding(.top, 10)
                        .transition(.opacity)
                }

                if found {
                    optionTray
                        .padding(.top, 18)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        #if DEBUG
        .onAppear {
            guard let state = DrillDemo.spotState, let spot else { return }
            if state == "miss", let i = spot.tokens.indices.first(where: { $0 != spot.wrongIndex }) {
                tapWord(i, isError: false)
            } else if state == "found" || Int(state) != nil {
                found = true
                if let n = Int(state), options.indices.contains(n) { choose(n) }
            }
        }
        #endif
    }

    private var explanation: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(exercise.explanation)
                .font(.appBody)
                .foregroundColor(AppColor.ink)
            if let english = exercise.displayExplanationEN {
                Text(english)
                    .font(.appBody)
                    .foregroundColor(AppColor.g2)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var status: String {
        if result != nil { return "" }
        if found { return misses >= Self.missesBeforeReveal ? "Le mot faux est encadré. Corrige-le." : "Corrige-le." }
        return misses == 0 ? "Touche le mot faux." : "Pas ce mot. Encore un essai."
    }

    // MARK: - Sentence

    @ViewBuilder
    private func word(_ i: Int, _ token: String, isError: Bool) -> some View {
        let framed = isError && found
        let shown = framed ? (pick.map { options[$0] } ?? token) : token
        // A wrong fix goes back to the dashed frame, like a wrong build tile.
        let filled = framed && pick != nil && result != false
        Button { tapWord(i, isError: isError) } label: {
            Text(shown)
                .font(.display(size: 24, wght: 300))
                .tracking(-0.4)
                .foregroundColor(AppColor.ink)
                .padding(.horizontal, framed ? 13 : 3)
                .frame(height: MagnetBoard.tileHeight)
                .background(Capsule().fill(filled ? Color(hex: result == true ? theme.tint : theme.tileOn) : .clear))
                .overlay(
                    Capsule().strokeBorder(
                        framed && !filled ? Color(hex: theme.fragile) : .clear,
                        style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                )
                .opacity(dimmed.contains(i) ? 0.35 : 1)
                .contentShape(Rectangle())
                // An elided word ("J'", "qu'") sits against the next one, as in print.
                // Gap between words = 2 × 3 pt inset + 4 pt spacing.
                .padding(.trailing, !framed && Self.isElided(shown) ? -10 : 0)
                .padding(.leading, Self.hugsPrevious(shown) ? -10 : 0)
        }
        .buttonStyle(.plain)
        .allowsHitTesting(!isLocked && !found && !Self.hugsPrevious(shown))
        .phaseAnimator([0.0, -6, 6, -4, 4, 0], trigger: shakes[i] ?? 0) { content, x in
            content.offset(x: reduceMotion ? 0 : x)
        } animation: { _ in .linear(duration: 0.05) }
        .accessibilityLabel(shown)
        .accessibilityHint(found || isLocked ? "" : "Marquer comme faux")
    }

    /// A bare "." or "," sits against the word before it; French keeps a space
    /// before ? ! ; : so those stay apart.
    static func hugsPrevious(_ token: String) -> Bool {
        token == "." || token == "," || token == "…"
    }

    static func isElided(_ token: String) -> Bool {
        token.hasSuffix("'") || token.hasSuffix("\u{2019}")
    }

    // MARK: - Fixes

    @ViewBuilder
    private var optionTray: some View {
        let tiles = FlowLayout(spacing: 14, lineSpacing: 16) {
            ForEach(Array(options.enumerated()), id: \.offset) { i, option in
                Button { choose(i) } label: {
                    MagnetTile(text: option, style: pick == i ? .placed : .bank)
                }
                .buttonStyle(.plain)
                .allowsHitTesting(!isLocked)
                .opacity(result == false && pick == i ? 0.35 : 1)
                .accessibilityLabel(option)
            }
        }
        switch DrillStyle(stored: drillStyleID) {
        case .plateau:
            tiles
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Color(hex: theme.tint)))
                .padding(.horizontal, -8)
        case .cadres:
            tiles.frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Interaction

    private func tapWord(_ i: Int, isError: Bool) {
        guard !isLocked, !found else { return }
        if isError {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(duration: 0.35, bounce: 0.2)) { found = true }
            return
        }
        guard !dimmed.contains(i) else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        shakes[i, default: 0] += 1
        withAnimation(.easeOut(duration: 0.3)) { _ = dimmed.insert(i) }
        misses += 1
        if misses >= Self.missesBeforeReveal {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                withAnimation(.spring(duration: 0.35, bounce: 0.2)) { found = true }
            }
        }
    }

    private func choose(_ i: Int) {
        guard !isLocked, let spot else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(duration: 0.35, bounce: 0.3)) { pick = i }
        var tokens = spot.tokens
        tokens[spot.wrongIndex] = options[i]
        answer = tokens
    }
}
