//
//  TokenBuilderView.swift
//  carambole
//
//  "Le Cahier" token-build input for `inputMode == .buildFromTokens`.
//  Tap chips from the bank to fill underlined worksheet blanks; tap a filled
//  slot to return the token to the bank. The parent owns the submitted tokens.
//

import SwiftUI

/// Renders a tappable token bank above a row of underlined answer blanks.
///
/// The current answer is exposed via the `answer` binding as an ordered
/// `[String]`. Each bank index can be used at most once; once placed, its chip
/// shows a faded "used" state and is disabled.
struct TokenBuilderView: View {
    let exercise: Exercise
    /// The ordered tokens the user has placed. Owned by the parent.
    @Binding var answer: [String]

    /// Whether the input is locked (after the answer has been checked).
    var isLocked: Bool = false

    /// Bank indices that have been consumed into the answer, in placement order.
    /// We track indices (not values) so duplicate tokens in the bank behave
    /// correctly and each chip maps to exactly one slot.
    @State private var placedIndices: [Int] = []

    /// Presentation order of the chips: a deterministic, stable-per-`id` shuffle so
    /// the bank never mirrors the answer order (see `Exercise.displayBank`). All
    /// rendering AND index→token mapping go through this one array, so `placedIndices`
    /// stay valid.
    private var bank: [String] { exercise.displayBank }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Answer area: underlined worksheet blanks.
            answerSlots

            // Token bank.
            tokenBank
        }
        .onChange(of: answer) { _, newValue in
            // If the parent clears the answer (e.g. advancing exercises), reset.
            if newValue.isEmpty && !placedIndices.isEmpty {
                placedIndices = []
            }
        }
    }

    // MARK: - Answer slots

    private var answerSlots: some View {
        FlowLayout(spacing: Spacing.sm, lineSpacing: Spacing.md) {
            if placedIndices.isEmpty {
                // A single empty blank as an invitation.
                emptyBlank
            } else {
                ForEach(Array(placedIndices.enumerated()), id: \.offset) { _, bankIndex in
                    filledSlot(bankIndex: bankIndex)
                }
                if !isLocked {
                    emptyBlank
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyBlank: some View {
        Text(" ")
            .font(.appToken)
            .foregroundColor(.clear)
            .frame(minWidth: 56)
            .padding(.horizontal, Spacing.sm)
            .padding(.bottom, 6)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(AppColor.saffron)
                    .frame(height: 2)
            }
    }

    private func filledSlot(bankIndex: Int) -> some View {
        Button {
            guard !isLocked else { return }
            returnToken(bankIndex: bankIndex)
        } label: {
            Text(bank[bankIndex])
                .font(.appToken)
                .foregroundColor(AppColor.ink)
                .padding(.horizontal, Spacing.sm)
                .padding(.bottom, 6)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(AppColor.ink)
                        .frame(height: 2)
                }
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(isLocked)
    }

    // MARK: - Token bank

    private var tokenBank: some View {
        FlowLayout(spacing: Spacing.sm, lineSpacing: Spacing.sm) {
            ForEach(Array(bank.enumerated()), id: \.offset) { index, token in
                bankChip(index: index, token: token)
            }
        }
    }

    private func bankChip(index: Int, token: String) -> some View {
        let used = placedIndices.contains(index)
        return Button {
            guard !isLocked, !used else { return }
            placeToken(bankIndex: index)
        } label: {
            Text(token)
                .font(.appToken)
                .foregroundColor(AppColor.ink)
                .padding(.vertical, Spacing.sm)
                .padding(.horizontal, Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(AppColor.paper)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(AppColor.ink, lineWidth: 1)
                )
                .opacity(used ? 0.28 : 1.0)
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(used || isLocked)
    }

    // MARK: - Mutation

    private func placeToken(bankIndex: Int) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            placedIndices.append(bankIndex)
            syncAnswer()
        }
    }

    private func returnToken(bankIndex: Int) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            placedIndices.removeAll { $0 == bankIndex }
            syncAnswer()
        }
    }

    private func syncAnswer() {
        answer = placedIndices.map { bank[$0] }
    }
}

// MARK: - FlowLayout

/// A simple wrapping flow layout: lays children left-to-right, wrapping to a new
/// line when the row would overflow the available width. Used for token chips
/// and answer slots so they read like text on a worksheet.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rows = computeRows(maxWidth: maxWidth, subviews: subviews)
        let height = rows.reduce(CGFloat.zero) { $0 + $1.height } +
            CGFloat(max(0, rows.count - 1)) * lineSpacing
        let width = rows.map(\.width).max() ?? 0
        rows.removeAll()
        return CGSize(width: min(width, maxWidth), height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let rows = computeRows(maxWidth: bounds.width, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            for item in row.items {
                let size = subviews[item.index].sizeThatFits(.unspecified)
                subviews[item.index].place(
                    at: CGPoint(x: x, y: y),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(size)
                )
                x += size.width + spacing
            }
            y += row.height + lineSpacing
        }
    }

    // MARK: - Row computation

    private struct RowItem { let index: Int }
    private struct Row { var items: [RowItem] = []; var width: CGFloat = 0; var height: CGFloat = 0 }

    private func computeRows(maxWidth: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let projected = current.items.isEmpty ? size.width : current.width + spacing + size.width
            if !current.items.isEmpty && projected > maxWidth {
                rows.append(current)
                current = Row()
                current.items = [RowItem(index: index)]
                current.width = size.width
                current.height = size.height
            } else {
                if !current.items.isEmpty { current.width += spacing }
                current.items.append(RowItem(index: index))
                current.width += size.width
                current.height = max(current.height, size.height)
            }
        }
        if !current.items.isEmpty { rows.append(current) }
        return rows
    }
}

// MARK: - Preview

#Preview {
    struct Harness: View {
        @State private var answer: [String] = []
        var body: some View {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                TokenBuilderView(exercise: .sample, answer: $answer)
                Text("answer: \(answer.joined(separator: " "))")
                    .uppercaseLabel()
            }
            .padding(Spacing.screenH)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(AppColor.paper)
        }
    }
    return Harness()
}
