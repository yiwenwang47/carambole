//
//  TopicMapView.swift
//  carambole
//
//  "Table des matières" — the grammar topic map. A numbered editorial table of
//  contents (NOT a gamified candy map): hairline rules between rows, serif
//  titles, a single saffron accent, staggered reveal on appear.
//  Built entirely from the "Le Cahier" design system.
//

import SwiftUI

/// Identifiable wrapper so a `GrammarTopic` can drive `.fullScreenCover(item:)`.
private struct DrillPresentation: Identifiable {
    let topic: GrammarTopic
    var id: String { topic.id }
}

struct TopicMapView: View {
    @StateObject private var viewModel = TopicMapViewModel()

    /// The topic currently presented as a drill session (nil = none).
    @State private var presentedDrill: DrillPresentation?
    /// Routes to the daily-review queue.
    @State private var showingReview = false
    /// Drives the staggered reveal once the view appears.
    @State private var revealed = false

    var body: some View {
        ZStack {
            AppColor.paper.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    header
                    reviewRow
                    divider
                    topicList
                }
                .padding(.horizontal, Spacing.screenH)
                .padding(.top, 72)
                .padding(.bottom, Spacing.xl)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .onAppear {
            viewModel.loadSeedingIfNeeded()
            viewModel.refreshDue()
            withAnimation(.easeOut(duration: 0.45)) {
                revealed = true
            }
        }
        .fullScreenCover(item: $presentedDrill) { presentation in
            DrillSessionView(topic: presentation.topic) {
                viewModel.markComplete(presentation.topic.id)
                presentedDrill = nil
            }
        }
        .fullScreenCover(isPresented: $showingReview, onDismiss: {
            viewModel.refreshDue()
        }) {
            ReviewQueueView(due: viewModel.dueExercises()) {
                showingReview = false
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionLabel("Grammaire")
            Text("Table des matières")
                .font(.appTitle)
                .foregroundColor(AppColor.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, Spacing.sm)
    }

    // MARK: - Révision row (quiet, not a loud button)

    private var reviewRow: some View {
        Button {
            showingReview = true
        } label: {
            HStack(alignment: .center, spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Révision")
                        .font(.system(size: 18, weight: .regular, design: .serif))
                        .foregroundColor(AppColor.ink)
                    Text("Daily review")
                        .uppercaseLabel()
                }
                Spacer()
                Text("\(viewModel.dueCount) due")
                    .font(.appLabel)
                    .foregroundColor(viewModel.dueCount > 0 ? AppColor.saffronDeep : AppColor.graphite)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColor.graphite)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Topic list

    private var topicList: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(viewModel.topics.enumerated()), id: \.element.id) { index, topic in
                let state = viewModel.state(for: topic)
                let unlocked = state != .locked

                Button {
                    guard unlocked else { return }
                    presentedDrill = DrillPresentation(topic: topic)
                } label: {
                    TopicRow(number: index + 1, title: topic.title, state: state)
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(!unlocked)
                .opacity(revealed ? 1 : 0)
                .offset(y: revealed ? 0 : 12)
                .animation(
                    .easeOut(duration: 0.4).delay(Double(index) * 0.06),
                    value: revealed
                )

                if index < viewModel.topics.count - 1 {
                    Rectangle()
                        .fill(AppColor.hairline)
                        .frame(height: 1)
                }
            }
        }
    }

    // MARK: - Divider

    private var divider: some View {
        Rectangle()
            .fill(AppColor.hairline)
            .frame(height: 1)
    }
}

// MARK: - Topic row

/// A single table-of-contents row: index number · serif title · state glyph.
private struct TopicRow: View {
    let number: Int
    let title: String
    let state: TopicState

    private var isLocked: Bool { state == .locked }

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            Text(String(format: "%02d", number))
                .font(.system(size: 15, weight: .regular, design: .monospaced))
                .foregroundColor(isLocked ? AppColor.hairline : AppColor.graphite)

            Text(title)
                .font(.appTitle)
                .foregroundColor(isLocked ? AppColor.graphite : AppColor.ink)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            glyph
        }
        .padding(.vertical, Spacing.md)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var glyph: some View {
        switch state {
        case .done:
            Image(systemName: "checkmark")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColor.saffron)
        case .current:
            Circle()
                .fill(AppColor.saffron)
                .frame(width: 10, height: 10)
        case .locked:
            Image(systemName: "lock")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(AppColor.graphite)
        }
    }
}

// MARK: - Preview

#Preview {
    TopicMapView()
}
