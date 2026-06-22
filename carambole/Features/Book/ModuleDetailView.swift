//
//  ModuleDetailView.swift
//  carambole
//
//  A durable, per-module element list reached from a SECONDARY affordance on the
//  book's module row (an "ⓘ" detail button — the PRIMARY row tap still starts the
//  learn session, unchanged). Each element shows its memory-strength bucket
//  (maîtrisé · fragile · en cours · à venir). A GRADUATED element (maîtrisé or
//  fragile) carries a swipe action "remettre en cours" → `BookViewModel.demoteElement`,
//  the durable un-graduate surface (the undo toast after "Trop facile" is the
//  transient one). Built from "Le Cahier", styled like `HistoryView` — custom
//  header + paper background + hand-rolled swipe (no system List), so it matches the
//  rest of the app rather than the platform default.
//

import SwiftUI

struct ModuleDetailView: View {
    let module: CourseModule
    @ObservedObject var viewModel: BookViewModel

    @Environment(\.dismiss) private var dismiss

    private var elements: [GrammarElement] {
        module.elements.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        ZStack {
            AppColor.paper.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    header
                    elementList
                    footnote
                }
                .padding(.horizontal, Spacing.screenH)
                .padding(.top, 72)
                .padding(.bottom, Spacing.xl)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        // Re-read the live sets on appear (and after a demote elsewhere) so the
        // buckets are current.
        .onAppear { viewModel.refresh() }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .swipeToGoBack { dismiss() }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColor.graphite)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.trailing, Spacing.sm)
            .accessibilityLabel("Retour")

            VStack(alignment: .leading, spacing: Spacing.sm) {
                SectionLabel("Module")
                Text(module.title)
                    .font(.appTitle)
                    .foregroundColor(AppColor.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(.bottom, Spacing.sm)
    }

    // MARK: Element list

    private var elementList: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(elements.enumerated()), id: \.element.id) { index, element in
                ElementRow(
                    number: index + 1,
                    element: element,
                    bucket: viewModel.bucket(for: element),
                    onDemote: { viewModel.demoteElement(element.id) }
                )
                if index < elements.count - 1 {
                    Rectangle().fill(AppColor.hairline).frame(height: 1)
                }
            }
        }
    }

    // MARK: Footnote

    private var footnote: some View {
        Text("Glisse un élément maîtrisé vers la gauche pour le remettre en cours.")
            .uppercaseLabel()
            .foregroundColor(AppColor.graphite)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, Spacing.sm)
    }
}

// MARK: - Element row (with custom swipe-to-demote on graduated elements)

/// One element row: number · label · bucket badge. A graduated element (maîtrisé /
/// fragile) reveals a "remettre en cours" action on a leftward swipe — hand-rolled
/// (no system List) to keep the paper/serif look. En-cours / à-venir rows don't
/// swipe (nothing to un-graduate).
private struct ElementRow: View {
    let number: Int
    let element: GrammarElement
    let bucket: BookViewModel.ElementBucket
    let onDemote: () -> Void

    /// True only for graduated elements — the ones the swipe action applies to.
    private var canDemote: Bool {
        bucket == .mastered || bucket == .fragile
    }

    /// Width of the revealed action panel.
    private let actionWidth: CGFloat = 150
    /// Current horizontal offset of the row content (≤ 0; -actionWidth = fully open).
    @State private var offset: CGFloat = 0
    /// The row's rest offset captured at the START of the active drag, so a drag that
    /// begins from the OPEN position continues from there (and can close). `DragGesture`
    /// has no "began" callback, so `isDragging` marks the first change of each drag.
    @State private var dragStart: CGFloat = 0
    @State private var isDragging = false

    var body: some View {
        ZStack(alignment: .trailing) {
            // Revealed action sits BEHIND the row, exposed as the content slides left.
            if canDemote {
                demoteAction
            }
            rowContent
                .background(AppColor.paper)   // opaque so the action only peeks when open
                .offset(x: offset)
                .gesture(canDemote ? swipe : nil)
                // Tap an open row to close it — a dismiss path that doesn't fight the
                // screen's rightward `swipeToGoBack`. No-op when closed.
                .onTapGesture { if offset != 0 { close() } }
                .animation(.interactiveSpring(response: 0.32, dampingFraction: 0.86), value: offset)
        }
        .clipped()
    }

    // MARK: Row content

    private var rowContent: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            Text(String(format: "%02d", number))
                .font(.system(size: 15, weight: .regular, design: .monospaced))
                .foregroundColor(AppColor.graphite)

            Text(element.label)
                .font(.appExplain)
                .foregroundColor(AppColor.ink)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            bucketBadge
        }
        .padding(.vertical, Spacing.md)
        .contentShape(Rectangle())
    }

    // MARK: Bucket badge

    private var bucketBadge: some View {
        Text(badgeText)
            .font(.appLabel)
            .tracking(2)
            .textCase(.uppercase)
            .foregroundColor(badgeColor)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 4)
            .background(Capsule().fill(badgeColor.opacity(0.12)))
    }

    private var badgeText: String {
        switch bucket {
        case .mastered: return "maîtrisé"
        case .fragile:  return "fragile"
        case .enCours:  return "en cours"
        case .aVenir:   return "à venir"
        }
    }

    private var badgeColor: Color {
        switch bucket {
        case .mastered: return AppColor.saffronDeep
        case .fragile:  return AppColor.error
        case .enCours:  return AppColor.graphite
        case .aVenir:   return AppColor.hairline
        }
    }

    // MARK: Swipe action

    private var demoteAction: some View {
        HStack {
            Spacer()
            Button {
                onDemote()
                close()
            } label: {
                Text("Remettre en cours")
                    .font(.appLabel)
                    .fontWeight(.semibold)
                    .tracking(1)
                    .textCase(.uppercase)
                    .foregroundColor(AppColor.paper)
                    .multilineTextAlignment(.center)
                    .frame(width: actionWidth)
                    .frame(maxHeight: .infinity)
                    .background(AppColor.saffronDeep)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remettre \(element.label) en cours")
        }
    }

    private var swipe: some Gesture {
        DragGesture(minimumDistance: 14)
            .onChanged { value in
                // Horizontally-dominant drags only, so vertical scroll still works.
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                // Capture the rest offset once, at the first horizontal change of this
                // drag — so a drag begun from the OPEN position continues from -actionWidth.
                if !isDragging { isDragging = true; dragStart = offset }
                // Clamp between [-actionWidth, 0] with a little rightward rubber-band.
                let raw = dragStart + value.translation.width
                offset = min(0, max(-actionWidth - 24, raw))
            }
            .onEnded { _ in
                isDragging = false
                // Snap from the RESULTING offset: past the half-open mark → open,
                // otherwise close. Works from either start state (open row drags closed).
                if offset < -actionWidth * 0.5 { open() } else { close() }
            }
    }

    private func open() {
        offset = -actionWidth
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func close() {
        offset = 0
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ModuleDetailView(module: .sample, viewModel: BookViewModel())
    }
}
