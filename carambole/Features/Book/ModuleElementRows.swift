//
//  ModuleElementRows.swift
//  carambole
//
//  The element list with its memory-strength bucket (maîtrisé · fragile ·
//  en cours · à venir). A GRADUATED element (maîtrisé or fragile) carries a swipe
//  action "Remettre en cours" → `BookViewModel.demoteElement`, the durable
//  un-graduate surface (the undo toast after "Trop facile" is the transient one).
//  Shown in the Book 1 session's module sheet (`DrillSessionView`).
//

import SwiftUI

// MARK: - Element row (with custom swipe-to-demote on graduated elements)

/// One element row (02 `.els`): label · right-aligned bucket label, g4 hairline below.
/// À-venir rows read g3. A graduated element (maîtrisé / fragile) reveals a
/// "Remettre en cours" action on a leftward swipe — hand-rolled (no system List).
/// En-cours / à-venir rows don't swipe (nothing to un-graduate).
struct ModuleElementRows: View {
    let module: CourseModule
    @ObservedObject var viewModel: BookViewModel
    var onDemote: ((GrammarElement) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(module.elements.sorted { $0.sortOrder < $1.sortOrder }) { element in
                ElementRow(element: element, bucket: viewModel.bucket(for: element),
                           onDemote: {
                    if let onDemote { onDemote(element) }
                    else { viewModel.demoteElement(element.id) }
                })
            }
        }
    }
}

struct ElementRow: View {
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
        .overlay(alignment: .bottom) { Rectangle().fill(AppColor.hairline).frame(height: 1) }
        .accessibilityElement(children: .combine)
        .accessibilityActions {
            if canDemote {
                Button("Remettre en cours") { onDemote() }
            }
        }
    }

    // MARK: Row content

    private var rowContent: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(element.label)
                    .font(.display(size: 15, wght: 400))
                    .foregroundColor(bucket == .aVenir ? AppColor.g3 : AppColor.ink)
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)

            bucketLabel
        }
        .padding(.vertical, 9)
        .contentShape(Rectangle())
    }

    // MARK: Bucket label (state by form: ink / dashed underline / g2)

    @ViewBuilder
    private var bucketLabel: some View {
        switch bucket {
        case .mastered:
            Text("Maîtrisé").uppercaseLabel(AppColor.ink)
        case .fragile:
            Text("Fragile")
                .uppercaseLabel(AppColor.ink)
                .padding(.bottom, 2)
                .overlay(alignment: .bottom) {
                    Line()
                        .stroke(AppColor.ink, style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                        .frame(height: 1)
                }
        case .enCours:
            Text("En cours").uppercaseLabel()
        case .aVenir:
            Text("À venir").uppercaseLabel()
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
                    .uppercaseLabel(AppColor.paper)
                    .multilineTextAlignment(.center)
                    .frame(width: actionWidth)
                    .frame(maxHeight: .infinity)
                    .background(AppColor.buttonDark)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remettre \(element.label) en cours")
        }
    }

    private var swipe: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                // Horizontally-dominant drags only, so vertical scroll still works.
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                // Engage ONLY on a leftward pull (demote direction) or when the row is
                // already open (so it can be dragged closed). A rightward drag on a
                // closed row is left alone — it must pass through to the screen's
                // swipe-to-go-back and to the ScrollView, never get eaten here.
                if !isDragging {
                    guard value.translation.width < 0 || offset != 0 else { return }
                    isDragging = true
                    dragStart = offset
                }
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
