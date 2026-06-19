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
    /// The live frontier — the furthest exercise reached. Indices below this are
    /// answered and shown read-only when revisited.
    @State private var maxIndex = 0
    /// Latest correctness per answered exercise index. Keyed so revisiting a
    /// drill (via the back chevron) overwrites rather than double-counts.
    @State private var results: [Int: Bool] = [:]
    /// The tokens the user submitted per exercise index, for read-only revisits.
    @State private var submittedAnswers: [Int: [String]] = [:]
    @State private var finished = false

    private var correctCount: Int { results.values.filter { $0 }.count }

    /// Review payload for the current index when it sits behind the frontier.
    private var currentReview: DrillView.ReviewData? {
        guard currentIndex < maxIndex else { return nil }
        return DrillView.ReviewData(
            answer: submittedAnswers[currentIndex] ?? [],
            correct: results[currentIndex] ?? false
        )
    }
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
        // Track the frontier so the ring holds steady while reviewing earlier drills.
        return Double(maxIndex) / Double(exercises.count)
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
                    onResult: { correct, tokens in
                        results[currentIndex] = correct
                        submittedAnswers[currentIndex] = tokens
                        grade(exercises[currentIndex], wasCorrect: correct)
                    },
                    onNext: advance,
                    canGoBack: currentIndex > 0,
                    onBack: goBack,
                    canGoForward: currentIndex < maxIndex,
                    onForward: goForward,
                    reviewData: currentReview
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

    // MARK: - Spaced-repetition grading

    /// Persist the SRS outcome for one answered exercise: fetch-or-fresh → grade → upsert.
    private func grade(_ exercise: Exercise, wasCorrect: Bool) {
        let prev = DataManager.shared.fetchReviewStatus(exerciseID: exercise.id)
            ?? SRSScheduler.fresh(exercise.id)
        let next = SRSScheduler.grade(prev, pass: wasCorrect, now: Date())
        DataManager.shared.upsertReviewStatus(next)
    }

    // MARK: - Advance

    private func advance() {
        // Push the frontier forward when leaving the live drill.
        if currentIndex == maxIndex { maxIndex = currentIndex + 1 }
        if currentIndex + 1 < exercises.count {
            currentIndex += 1
        } else {
            finished = true
        }
    }

    /// Return to the previous drill to review it read-only.
    private func goBack() {
        if currentIndex > 0 {
            currentIndex -= 1
        }
    }

    /// Move forward out of review. Stops at the live frontier; if the frontier is
    /// past the last drill, the session is complete.
    private func goForward() {
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
