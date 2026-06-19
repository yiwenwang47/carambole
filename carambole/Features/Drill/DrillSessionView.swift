//
//  DrillSessionView.swift
//  carambole
//
//  "Le Cahier" drill session — drives a whole topic's exercises, tracks
//  correctness, and shows a self-contained editorial completion summary.
//  Built entirely from the design system; no FlashcardView symbols referenced.
//

import SwiftUI

struct DrillSessionView: View {
    let title: String
    let exercises: [Exercise]
    /// English topic rule note shown on the one-time intro card. Empty when the
    /// session was built from a raw exercise list (no intro card in that case).
    let ruleNote: String
    /// Called when the user finishes the session ("Done").
    var onFinish: () -> Void = {}

    @State private var currentIndex = 0
    @State private var correctCount = 0
    @State private var finished = false
    /// Whether the one-time English intro card is showing.
    @State private var showingIntro = true

    /// Convenience: drive a session straight from a `GrammarTopic`.
    init(topic: GrammarTopic, onFinish: @escaping () -> Void = {}) {
        self.title = topic.title
        self.exercises = topic.exercises
        self.ruleNote = topic.ruleNote
        self.onFinish = onFinish
    }

    /// Drive a session from a raw exercise list plus a display title.
    /// No `ruleNote` here → the intro card is gated off.
    init(title: String, exercises: [Exercise], onFinish: @escaping () -> Void = {}) {
        self.title = title
        self.exercises = exercises
        self.ruleNote = ""
        self.onFinish = onFinish
    }

    /// Whether the intro card should be presented (only when a rule note exists).
    private var shouldShowIntro: Bool {
        showingIntro && !ruleNote.isEmpty && !exercises.isEmpty
    }

    private var progress: Double {
        guard !exercises.isEmpty else { return 0 }
        return Double(currentIndex) / Double(exercises.count)
    }

    var body: some View {
        ZStack {
            AppColor.paper.ignoresSafeArea()

            if shouldShowIntro {
                introCard
                    .transition(.opacity)
            } else if finished || exercises.isEmpty {
                completionSummary
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                DrillView(
                    exercise: exercises[currentIndex],
                    progress: progress,
                    onResult: { correct in
                        if correct { correctCount += 1 }
                    },
                    onNext: advance
                )
                .id(currentIndex) // fresh DrillView state per exercise
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: currentIndex)
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: finished)
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: showingIntro)
    }

    // MARK: - Topic intro card (one-time English ease-in)

    private var introCard: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Spacer(minLength: Spacing.xl)

            SectionLabel("Leçon")

            Text(title)
                .font(.appTitle)
                .foregroundColor(AppColor.ink)
                .fixedSize(horizontal: false, vertical: true)

            Rectangle()
                .fill(AppColor.hairline)
                .frame(height: 1)
                .padding(.vertical, Spacing.sm)

            Text(ruleNote)
                .font(.appExplain)
                .foregroundColor(AppColor.graphite)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            Button("Commencer") {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                    showingIntro = false
                }
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(.horizontal, Spacing.screenH)
        .padding(.bottom, Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - Advance

    private func advance() {
        if currentIndex + 1 < exercises.count {
            currentIndex += 1
        } else {
            finished = true
        }
    }

    // MARK: - Completion summary (self-contained)

    private var completionSummary: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Spacer(minLength: Spacing.xl)

            SectionLabel(title)

            Text("Terminé")
                .font(.appDisplay)
                .foregroundColor(AppColor.ink)

            HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                Text("\(correctCount)")
                    .font(.appPrompt)
                    .foregroundColor(AppColor.ink)
                Text("/ \(exercises.count) correct")
                    .font(.appTitle)
                    .foregroundColor(AppColor.graphite)
            }

            Rectangle()
                .fill(AppColor.hairline)
                .frame(height: 1)
                .padding(.vertical, Spacing.sm)

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
    DrillSessionView(topic: .sample, onFinish: {})
}
