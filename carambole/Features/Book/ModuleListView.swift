//
//  ModuleListView.swift
//  carambole
//
//  The book's table of contents: the 25 modules as quiet numbered rows in the
//  motion.html edge-type language. Tapping a row opens that module's Leçon
//  page (`DrillSessionView`). Reached from the book home's bottom
//  line (`25 modules →`). (Replaces the dropped 06 Tranches stack.)
//

import SwiftUI

struct ModuleListView: View {
    @ObservedObject var viewModel: BookViewModel
    @State private var selectedModule: CourseModule?
    @State private var swipeGuard = SwipeBackGuard()

    @Environment(\.dismiss) private var dismiss

    private var modules: [CourseModule] {
        viewModel.book.modules.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        ZStack {
            AppColor.paper.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    Text(modules.count == 1 ? "1 module" : "\(modules.count) modules")
                        .font(.display(size: 40, wght: 250))
                        .tracking(-1.2)
                        .foregroundColor(AppColor.ink)
                        .padding(.top, 30)
                    Rectangle().fill(AppColor.ink).frame(height: 1).padding(.top, 22)
                    ForEach(Array(modules.enumerated()), id: \.element.id) { index, module in
                        Button {
                            guard !swipeGuard.dragging else { return }
                            selectedModule = module
                        } label: {
                            row(number: index + 1, module: module)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Spacing.screenH)
                .padding(.top, 16)
                .padding(.bottom, Spacing.xl)
            }
        }
        .fullScreenCover(item: $selectedModule, onDismiss: { viewModel.refresh() }) { module in
            StudySessionView(viewModel: viewModel, title: module.title, ruleNote: module.ruleNote,
                             elements: viewModel.moduleLearnElements(module), mode: .learn,
                             moduleNumber: module.sortOrder, module: module,
                             canStart: viewModel.isUnlocked(module)) {
                selectedModule = nil
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .swipeToGoBack(guard: swipeGuard) { dismiss() }
    }

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Text("‹ \(shortTitle)")
                    .uppercaseLabel(AppColor.ink)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Retour au livre")
            Spacer()
            Text("Sommaire").uppercaseLabel()
        }
    }

    /// "Français — Fondations" → "Fondations".
    private var shortTitle: String {
        viewModel.book.title.components(separatedBy: "— ").last ?? viewModel.book.title
    }

    private func row(number: Int, module: CourseModule) -> some View {
        let state = viewModel.state(for: module)
        let locked = state == .locked
        return HStack(alignment: .firstTextBaseline, spacing: 14) {
            Text(String(format: "%02d", number))
                .uppercaseLabel(locked ? AppColor.g3 : AppColor.g2)
                .monospacedDigit()
                .frame(width: 22, alignment: .leading)
            Text(module.title)
                .font(.display(size: 18, wght: state == .current ? 400 : 300))
                .tracking(-0.3)
                .foregroundColor(locked ? AppColor.g3 : AppColor.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            Text(statusText(module, state: state))
                .uppercaseLabel(state == .current ? AppColor.ink : (locked ? AppColor.g3 : AppColor.g2))
                .monospacedDigit()
        }
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) {
            Rectangle().fill(AppColor.hairline).frame(height: 1)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private func statusText(_ module: CourseModule, state: ModuleState) -> String {
        switch state {
        case .done: return "Maîtrisé"
        case .current: return "\(viewModel.masteredCount(in: module)) / \(module.elements.count)"
        case .locked: return "Verrouillé"
        }
    }
}
