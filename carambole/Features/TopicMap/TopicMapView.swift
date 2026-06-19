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

/// Identifiable snapshot of a daily session's exercises, captured at present-time
/// so the cover renders a FRESH list (not a stale published value). A new `id`
/// each time forces SwiftUI to rebuild the cover even for back-to-back sessions.
private struct ExerciseSession: Identifiable {
    let id = UUID()
    let exercises: [Exercise]
}

struct TopicMapView: View {
    @StateObject private var viewModel = TopicMapViewModel()

    /// The topic currently presented as a drill session (nil = none).
    @State private var presentedDrill: DrillPresentation?
    /// Today's NEW session ("Apprendre") — exercises captured fresh at present-time.
    @State private var newSession: ExerciseSession?
    /// Today's review session ("Réviser") — exercises captured fresh at present-time.
    @State private var reviewSession: ExerciseSession?
    /// Routes to the "Réglages" settings sheet.
    @State private var showingSettings = false
    /// Drives the staggered reveal once the view appears.
    @State private var revealed = false

    var body: some View {
        ZStack {
            AppColor.paper.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    header
                    todayPanel
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
            // `loadSeedingIfNeeded()` ends in a `refresh()` once topics load; no
            // need to refresh again here against still-empty `topics`.
            viewModel.loadSeedingIfNeeded()
            withAnimation(.easeOut(duration: 0.45)) {
                revealed = true
            }
        }
        .fullScreenCover(item: $presentedDrill, onDismiss: {
            // Recompute the daily new/due counts after a topic session — grading
            // during the drill changes what's seen/due. (The new/review covers
            // and the settings sheet already do this; the topic cover must too.)
            viewModel.refresh()
        }) { presentation in
            DrillSessionView(topic: presentation.topic) {
                viewModel.markComplete(presentation.topic.id)
                presentedDrill = nil
            }
        }
        .fullScreenCover(item: $newSession, onDismiss: {
            viewModel.refresh()
        }) { session in
            DrillSessionView(title: "Nouveau", exercises: session.exercises) {
                newSession = nil
            }
        }
        .fullScreenCover(item: $reviewSession, onDismiss: {
            viewModel.refresh()
        }) { session in
            ReviewQueueView(due: session.exercises) {
                reviewSession = nil
            }
        }
        .sheet(isPresented: $showingSettings, onDismiss: {
            viewModel.refresh()
        }) {
            SettingsView(store: viewModel.settingsStore)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                SectionLabel("Grammaire")
                Text("Table des matières")
                    .font(.appTitle)
                    .foregroundColor(AppColor.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(AppColor.graphite)
                    .contentShape(Rectangle())
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityLabel("Réglages")
        }
        .padding(.bottom, Spacing.sm)
    }

    // MARK: - "Aujourd'hui" panel (the daily-driven home)

    /// Surfaces "X new · Y due" and folds the review action in alongside a
    /// "learn new" action. KEPT above the topic table of contents.
    private var todayPanel: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionLabel("Aujourd'hui")

            // X new · Y due — the two counts, prominent and editorial.
            HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                count(viewModel.newAvailableToday, label: "new")
                Text("·")
                    .font(.appPrompt)
                    .foregroundColor(AppColor.hairline)
                count(viewModel.dueCount, label: "due")
                Spacer()
            }

            HStack(spacing: Spacing.md) {
                Button("Apprendre") {
                    newSession = ExerciseSession(exercises: viewModel.todaysNewExercises())
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(viewModel.newAvailableToday == 0)
                .opacity(viewModel.newAvailableToday == 0 ? 0.4 : 1)

                Button("Réviser") {
                    reviewSession = ExerciseSession(exercises: viewModel.reviewSessionExercises())
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
    }

    /// One count column: big serif number + small uppercase English label.
    private func count(_ value: Int, label: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text("\(value)")
                .font(.appPrompt)
                .foregroundColor(value > 0 ? AppColor.saffronDeep : AppColor.graphite)
            Text(label)
                .uppercaseLabel()
        }
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
