//
//  ChoiceView.swift
//  carambole
//
//  "Le Cahier" multiple-choice input for `inputMode == .multipleChoice`.
//  Each token-bank entry is a full-width serif choice row. One tap commits a
//  selection; the chosen row highlights with saffron. The selected value is a
//  single-element `[String]` bound to the parent.
//

import SwiftUI

/// Full-width choice rows for a multiple-choice exercise.
struct ChoiceView: View {
    let exercise: Exercise
    /// The committed selection as a single-element array (or empty). Parent-owned.
    @Binding var answer: [String]

    /// Whether the input is locked (after the answer has been checked).
    var isLocked: Bool = false

    private var selected: String? { answer.first }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(exercise.tokenBank.enumerated()), id: \.offset) { index, choice in
                choiceRow(choice: choice)

                if index < exercise.tokenBank.count - 1 {
                    Rectangle()
                        .fill(AppColor.hairline)
                        .frame(height: 1)
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppColor.hairline, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func choiceRow(choice: String) -> some View {
        let isSelected = selected == choice
        return Button {
            guard !isLocked else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                answer = [choice]
            }
        } label: {
            HStack(spacing: Spacing.md) {
                Text(choice)
                    .font(.appToken)
                    .foregroundColor(AppColor.ink)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                if isSelected {
                    Image(systemName: "circle.inset.filled")
                        .foregroundColor(AppColor.ink)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(AppColor.hairline)
                }
            }
            .padding(.vertical, Spacing.md)
            .padding(.horizontal, Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? AppColor.saffron.opacity(0.45) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(isLocked)
    }
}

// MARK: - Preview

#Preview {
    struct Harness: View {
        @State private var answer: [String] = []
        private let exercise = Exercise(
            id: "mc", topicID: "t", type: .conjugate,
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
