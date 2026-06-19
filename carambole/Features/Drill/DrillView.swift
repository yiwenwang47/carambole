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
    /// The exercise to drill.
    let exercise: Exercise
    /// Session progress (0...1) for the corner progress ring.
    var progress: Double = 0
    /// Called once when the answer is checked, with the correctness result.
    var onResult: (Bool) -> Void = { _ in }
    /// Called when the user taps "Next" to advance to the following exercise.
    var onNext: () -> Void = {}

    @State private var answer: [String] = []
    @State private var checked = false
    @State private var isCorrect = false

    private var hasAnswer: Bool { !answer.isEmpty }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                header

                promptBlock

                inputBlock

                if checked {
                    resultBanner
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Spacer(minLength: Spacing.lg)

                actionButton
            }
            .padding(.horizontal, Spacing.screenH)
            .padding(.top, Spacing.xl)
            .padding(.bottom, Spacing.xl)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(AppColor.paper.ignoresSafeArea())
    }

    // MARK: - Header (label + progress ring)

    private var header: some View {
        HStack(alignment: .top) {
            SectionLabel("Exercice")
            Spacer()
            ProgressRing(progress: progress, size: 36, lineWidth: 4)
        }
    }

    // MARK: - Prompt, framed by corner brackets

    private var promptBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            CornerBracketFrame {
                Text(exercise.prompt)
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
        }
    }

    // MARK: - Input

    @ViewBuilder
    private var inputBlock: some View {
        switch exercise.inputMode {
        case .buildFromTokens:
            TokenBuilderView(exercise: exercise, answer: $answer, isLocked: checked)
        case .multipleChoice:
            ChoiceView(exercise: exercise, answer: $answer, isLocked: checked)
        }
    }

    // MARK: - Result banner

    private var resultBanner: some View {
        let tint = isCorrect ? AppColor.success : AppColor.error
        return VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(tint)
                Text(isCorrect ? "Correct" : "Pas tout à fait")
                    .font(.appTitle)
                    .foregroundColor(tint)
            }

            if !isCorrect {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Réponse")
                        .uppercaseLabel()
                    Text(exercise.answerTokens.joined(separator: " "))
                        .font(.appToken)
                        .foregroundColor(AppColor.ink)
                }
            }

            // Always show the rule explanation after checking.
            Text(exercise.explanation)
                .font(.appExplain)
                .foregroundColor(AppColor.ink)
                .fixedSize(horizontal: false, vertical: true)
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

    // MARK: - Action button (Check → Next)

    @ViewBuilder
    private var actionButton: some View {
        if checked {
            Button("Suivant") { onNext() }
                .buttonStyle(PrimaryButtonStyle())
        } else {
            Button("Vérifier") { check() }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!hasAnswer)
                .opacity(hasAnswer ? 1.0 : 0.5)
        }
    }

    // MARK: - Logic

    private func check() {
        let correct = DrillEngine.check(answer, exercise)
        UINotificationFeedbackGenerator().notificationOccurred(correct ? .success : .error)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            isCorrect = correct
            checked = true
        }
        onResult(correct)
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
    DrillView(exercise: .sample, progress: 0.4, onResult: { _ in }, onNext: {})
}
