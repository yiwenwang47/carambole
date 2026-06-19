//
//  ReviewQueueView.swift
//  carambole
//
//  "Révision" — the Daily Review queue. Drives every exercise that is currently
//  due for spaced-repetition review through the existing `DrillSessionView`
//  (which re-grades each answer via SRS, rescheduling items automatically). When
//  nothing is due it shows a calm editorial empty state.
//  Built entirely from the "Le Cahier" design system.
//

import SwiftUI

struct ReviewQueueView: View {
    /// The exercises due for review right now. Empty → editorial empty state.
    let due: [Exercise]
    /// Called when the queue finishes or the user dismisses the empty state.
    var onFinish: () -> Void = {}

    init(due: [Exercise], onFinish: @escaping () -> Void = {}) {
        self.due = due
        self.onFinish = onFinish
    }

    var body: some View {
        if due.isEmpty {
            emptyState
        } else {
            DrillSessionView(title: "Révision", exercises: due, onFinish: onFinish)
        }
    }

    // MARK: - Empty state (nothing due)

    private var emptyState: some View {
        ZStack {
            AppColor.paper.ignoresSafeArea()

            VStack(alignment: .leading, spacing: Spacing.lg) {
                Spacer(minLength: Spacing.xl)

                SectionLabel("Révision")

                Text("Rien à réviser")
                    .font(.appDisplay)
                    .foregroundColor(AppColor.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Nothing due right now — come back later.")
                    .font(.appExplain)
                    .foregroundColor(AppColor.graphite)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                Button("Fermer") { onFinish() }
                    .buttonStyle(PrimaryButtonStyle())
            }
            .padding(.horizontal, Spacing.screenH)
            .padding(.bottom, Spacing.xl)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

// MARK: - Preview

#Preview("Populated") {
    ReviewQueueView(due: GrammarTopic.sample.exercises)
}

#Preview("Empty") {
    ReviewQueueView(due: [])
}
