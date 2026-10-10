//
//  ChoiceView.swift
//  carambole
//
//  Multiple-choice input for `inputMode == .multipleChoice`, drawn as 07
//  magnets: the choices are level tiles and the picked one springs onto the
//  answer line (a new pick replaces it). The selected value is a single-element
//  `[String]` bound to the parent.
//

import SwiftUI

struct ChoiceView: View {
    let exercise: Exercise
    /// The committed selection as a single-element array (or empty). Parent-owned.
    @Binding var answer: [String]

    /// Whether the input is locked (after the answer has been checked).
    var isLocked: Bool = false
    /// nil until checked; then whether the answer was right.
    var result: Bool? = nil
    var explainOnMiss = false

    @State private var placedIndices: [Int] = []

    /// Choices in presentation order: a deterministic, stable-per-`id` shuffle so the
    /// correct answer is not pinned to the first tile (see `Exercise.displayBank`).
    private var choices: [String] { exercise.displayBank }

    var body: some View {
        MagnetBoard(bank: choices, placed: $placedIndices, maxPlaced: 1,
                    isLocked: isLocked, result: result,
                    answerTokens: exercise.answerTokens,
                    explainOnMiss: explainOnMiss ? exercise : nil)
            .onChange(of: placedIndices) { _, new in
                answer = new.map { choices[$0] }
            }
            .onChange(of: answer) { _, newValue in
                if newValue.isEmpty && !placedIndices.isEmpty {
                    placedIndices = []
                }
            }
            #if DEBUG
            .onAppear {
                // Simulator harness: pre-pick choice n (CB_DRILL_PICK=n).
                if let n = Int(ProcessInfo.processInfo.environment["CB_DRILL_PICK"] ?? ""),
                   choices.indices.contains(n), placedIndices.isEmpty {
                    placedIndices = [n]
                }
            }
            #endif
    }
}

// MARK: - Preview

#Preview {
    struct Harness: View {
        @State private var answer: [String] = []
        private let exercise = Exercise(
            id: "mc", elementID: "t", type: .conjugate,
            prompt: "Elles ___ (aller) au marché.",
            cue: "aller",
            answerTokens: ["sont allées"],
            tokenBank: ["sont allées", "ont allé", "est allée", "sont allé"],
            inputMode: .multipleChoice,
            explanation: "Aller forms the passé composé with être; the participle agrees with the feminine plural subject."
        )
        var body: some View {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                ChoiceView(exercise: exercise, answer: $answer)
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
