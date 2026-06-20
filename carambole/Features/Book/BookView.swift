//
//  BookView.swift
//  carambole
//
//  The book home — the app's root screen. A numbered editorial table of contents
//  of the book's modules, with the daily "Aujourd'hui · X new · Y due" panel and
//  the Apprendre / Réviser actions living INSIDE the book. Built from "Le Cahier".
//

import SwiftUI

/// A daily / module study session, captured fresh at present-time so the cover
/// renders a current element list. A new `id` each time forces a rebuild.
private struct ElementSession: Identifiable {
    let id = UUID()
    let title: String
    let ruleNote: String
    let elements: [GrammarElement]
    let mode: DrillSessionView.Mode
}

struct BookView: View {
    /// Shown with a back affordance when pushed from the library shelf.
    var showBack: Bool = false

    @StateObject private var viewModel = BookViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var session: ElementSession?
    @State private var showingSettings = false
    @State private var revealed = false

    private var modules: [CourseModule] {
        viewModel.book.modules.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        ZStack {
            AppColor.paper.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    header
                    todayPanel
                    divider
                    moduleList
                }
                .padding(.horizontal, Spacing.screenH)
                .padding(.top, 72)
                .padding(.bottom, Spacing.xl)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .onAppear {
            viewModel.load()
            withAnimation(.easeOut(duration: 0.45)) { revealed = true }
        }
        .fullScreenCover(item: $session, onDismiss: { viewModel.refresh() }) { s in
            DrillSessionView(title: s.title, ruleNote: s.ruleNote, elements: s.elements, mode: s.mode) {
                session = nil
            }
        }
        .sheet(isPresented: $showingSettings, onDismiss: { viewModel.refresh() }) {
            SettingsView(store: viewModel.settingsStore)
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Header (book title)

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            if showBack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColor.graphite)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.trailing, Spacing.sm)
                .accessibilityLabel("Bibliothèque")
            }
            VStack(alignment: .leading, spacing: Spacing.sm) {
                SectionLabel("Grammaire")
                Text(viewModel.book.title)
                    .font(.appTitle)
                    .foregroundColor(AppColor.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Button { showingSettings = true } label: {
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

    // MARK: - "Aujourd'hui" panel (lives inside the book)

    private var todayPanel: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionLabel("Aujourd'hui")

            HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                count(viewModel.newAvailableToday, label: "new")
                Text("·").font(.appPrompt).foregroundColor(AppColor.hairline)
                count(viewModel.dueCount, label: "due")
                Spacer()
            }

            progressLine

            HStack(spacing: Spacing.md) {
                Button("Apprendre") {
                    guard let m = viewModel.newestUnlockedModule() else { return }
                    session = ElementSession(title: m.title, ruleNote: m.ruleNote,
                                             elements: viewModel.moduleLearnElements(m), mode: .learn)
                }
                .buttonStyle(PrimaryButtonStyle())

                Button("Réviser") {
                    session = ElementSession(title: "Réviser", ruleNote: "",
                                             elements: viewModel.reviewSessionElements(), mode: .review)
                }
                .buttonStyle(PrimaryButtonStyle())
            }

            RoundSizeSelector(store: viewModel.settingsStore)
        }
    }

    /// Today's done-work, scoped to this book; taps through to the full history.
    private var progressLine: some View {
        NavigationLink {
            HistoryView()
        } label: {
            HStack(spacing: Spacing.sm) {
                Text("\(viewModel.learnedToday) appris · \(viewModel.reviewedToday) révisés")
                    .uppercaseLabel()
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(AppColor.graphite)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("Historique de progression")
    }

    private func count(_ value: Int, label: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text("\(value)")
                .font(.appPrompt)
                .foregroundColor(value > 0 ? AppColor.saffronDeep : AppColor.graphite)
            Text(label).uppercaseLabel()
        }
    }

    // MARK: - Module list

    private var moduleList: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(modules.enumerated()), id: \.element.id) { index, module in
                let state = viewModel.state(for: module)
                let unlocked = state != .locked

                Button {
                    guard unlocked else { return }
                    session = ElementSession(title: module.title, ruleNote: module.ruleNote,
                                             elements: viewModel.moduleLearnElements(module), mode: .learn)
                } label: {
                    ModuleRow(number: index + 1,
                              title: module.title,
                              mastered: viewModel.masteredCount(in: module),
                              total: module.elements.count,
                              state: state)
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(!unlocked)
                .opacity(revealed ? 1 : 0)
                .offset(y: revealed ? 0 : 12)
                .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.06), value: revealed)

                if index < modules.count - 1 {
                    Rectangle().fill(AppColor.hairline).frame(height: 1)
                }
            }
        }
    }

    private var divider: some View {
        Rectangle().fill(AppColor.hairline).frame(height: 1)
    }
}

// MARK: - Réviser round-size selector

/// Inline segmented control for how many problems one Réviser tap presents
/// (`StudySettings.reviewRoundSizeOptions`). Writes straight to the settings store.
private struct RoundSizeSelector: View {
    @ObservedObject var store: StudySettingsStore

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Text("Révision par tour").uppercaseLabel()
            Spacer()
            HStack(spacing: 0) {
                ForEach(StudySettings.reviewRoundSizeOptions, id: \.self) { n in
                    let selected = store.settings.reviewRoundSize == n
                    Button { select(n) } label: {
                        Text("\(n)")
                            .font(.appLabel)
                            .tracking(1)
                            .foregroundColor(selected ? AppColor.paper : AppColor.graphite)
                            .frame(minWidth: 38)
                            .padding(.vertical, Spacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .fill(selected ? AppColor.ink : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(n) révisions par tour")
                    .accessibilityAddTraits(selected ? [.isSelected] : [])
                }
            }
            .padding(3)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppColor.hairline.opacity(0.5))
            )
        }
    }

    private func select(_ n: Int) {
        let s = store.settings
        store.settings = StudySettings(newPerDay: s.newPerDay,
                                       reviewTarget: s.reviewTarget,
                                       reviewRoundSize: n)
    }
}

// MARK: - Module row

private struct ModuleRow: View {
    let number: Int
    let title: String
    let mastered: Int
    let total: Int
    let state: ModuleState

    private var isLocked: Bool { state == .locked }

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            Text(String(format: "%02d", number))
                .font(.system(size: 15, weight: .regular, design: .monospaced))
                .foregroundColor(isLocked ? AppColor.hairline : AppColor.graphite)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.appTitle)
                    .foregroundColor(isLocked ? AppColor.graphite : AppColor.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if !isLocked {
                    Text("\(mastered)/\(total) maîtrisés")
                        .uppercaseLabel()
                }
            }

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
            Circle().fill(AppColor.saffron).frame(width: 10, height: 10)
        case .locked:
            Image(systemName: "lock")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(AppColor.graphite)
        }
    }
}

// MARK: - Preview

#Preview {
    BookView()
}
