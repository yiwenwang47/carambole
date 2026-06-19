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
    @StateObject private var viewModel = BookViewModel()

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
    }

    // MARK: - Header (book title)

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
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

            HStack(spacing: Spacing.md) {
                Button("Apprendre") {
                    session = ElementSession(title: "Apprendre", ruleNote: "",
                                             elements: viewModel.todaysNewElements(), mode: .learn)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(viewModel.newAvailableToday == 0)
                .opacity(viewModel.newAvailableToday == 0 ? 0.4 : 1)

                Button("Réviser") {
                    session = ElementSession(title: "Réviser", ruleNote: "",
                                             elements: viewModel.reviewSessionElements(), mode: .review)
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
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
