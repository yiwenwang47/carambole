//
//  TokenBuilderView.swift
//  carambole
//
//  Token-build input for `inputMode == .buildFromTokens`, drawn as 07 magnets
//  (`MagnetBoard`). Tap a tile to spring it onto the answer line; tap a placed
//  tile to send it home. The parent owns the submitted tokens.
//

import SwiftUI

/// The current answer is exposed via the `answer` binding as an ordered
/// `[String]`. Each bank index can be used at most once.
struct TokenBuilderView: View {
    let exercise: Exercise
    /// The ordered tokens the user has placed. Owned by the parent.
    @Binding var answer: [String]

    /// Whether the input is locked (after the answer has been checked).
    var isLocked: Bool = false
    /// nil until checked; then whether the answer was right.
    var result: Bool? = nil
    /// Second try (see `MagnetBoard`): locked leading tiles, flash trigger, note.
    var lockedCount: Int = 0
    var retryTrigger: Int = 0
    var retryNote: String? = nil
    var explainOnMiss = false

    /// Bank indices consumed into the answer, in placement order. Indices (not
    /// values) so duplicate tokens in the bank map to exactly one tile each.
    @State private var placedIndices: [Int] = []

    /// Presentation order: a deterministic, stable-per-`id` shuffle so the bank
    /// never mirrors the answer order (see `Exercise.displayBank`). Rendering AND
    /// index→token mapping go through this one array, so `placedIndices` stay valid.
    private var bank: [String] { exercise.displayBank }

    var body: some View {
        MagnetBoard(bank: bank, placed: $placedIndices, isLocked: isLocked,
                    result: result, answerTokens: exercise.answerTokens,
                    lockedCount: lockedCount, retryTrigger: retryTrigger, retryNote: retryNote,
                    explainOnMiss: explainOnMiss ? exercise : nil)
            .onChange(of: placedIndices) { _, new in
                answer = new.map { bank[$0] }
            }
            .onChange(of: answer) { _, newValue in
                // If the parent clears the answer (e.g. advancing exercises), reset.
                if newValue.isEmpty && !placedIndices.isEmpty {
                    placedIndices = []
                }
            }
            #if DEBUG
            .onAppear {
                // Simulator harness (DrillDemo): pre-place the first n answer tokens.
                let n = DrillDemo.placeCount
                guard n > 0, placedIndices.isEmpty else { return }
                var used = Set<Int>()
                for token in exercise.answerTokens.prefix(n) {
                    if let i = bank.indices.first(where: { bank[$0] == token && !used.contains($0) }) {
                        used.insert(i); placedIndices.append(i)
                    }
                }
                // Second-try harness: one wrong tile after the right start.
                if DrillDemo.autoRetry,
                   let i = bank.indices.first(where: { !used.contains($0)
                       && !exercise.answerTokens.contains(bank[$0]) }) {
                    placedIndices.append(i)
                }
            }
            #endif
    }
}

// MARK: - Preview

#Preview {
    struct Harness: View {
        @State private var answer: [String] = []
        var body: some View {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                TokenBuilderView(exercise: .sample, answer: $answer)
                Text("answer: \(answer.joined(separator: " "))")
                    .uppercaseLabel()
            }
            .padding(Spacing.screenH)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(AppColor.paper)
        }
    }
    return Harness()
}
