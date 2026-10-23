//
//  MagnetBoard.swift
//  carambole
//
//  07 · Aimants — the drill's word magnets. Level tiles sit in a wrapping bank;
//  a tap springs one onto the answer line (palette fill, one overshoot), a tap on
//  a placed tile flies it back to its fixed home slot (homes never reflow).
//  Correct → the placed tiles weld into plain text, leftovers drop away, and a
//  `wght` wave runs through the sentence. Wrong → the line shakes, mismatched
//  tiles turn dashed, and "Réponse : …" appears under the baseline.
//
//  Tiles are keyed by BANK INDEX (not string) so duplicate tokens stay correct.
//  Serves both build-from-tokens (`maxPlaced == nil`) and multiple choice
//  (`maxPlaced == 1`, a new pick replaces the old one).
//

import SwiftUI
import UIKit

struct MagnetBoard: View {
    /// Tiles in presentation order (`Exercise.displayBank`).
    let bank: [String]
    /// Placed bank indices, in line order. Parent-owned.
    @Binding var placed: [Int]
    /// nil = unlimited (build); 1 = multiple choice (replace on tap).
    var maxPlaced: Int? = nil
    var isLocked: Bool = false
    /// nil until checked; then whether the answer was right.
    var result: Bool? = nil
    let answerTokens: [String]
    /// Second try: the leading tiles that were right stay on the line and can't
    /// be sent home. 0 outside a retry.
    var lockedCount: Int = 0
    /// Bumped by the parent on a first wrong check that earns a second try: the
    /// line shakes, tiles past `lockedCount` flash dashed, then fly home.
    var retryTrigger: Int = 0
    /// Shown under the baseline while the second try is open.
    var retryNote: String? = nil
    /// When set, a wrong answer also shows this drill's rule under "Réponse".
    var explainOnMiss: Exercise? = nil

    @Namespace private var ns
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Bank index currently doing its post-snap scale pop.
    @State private var popping: Int?
    @State private var shakeTrigger = 0
    @State private var welded = false
    @State private var weldStart: Date?
    @State private var waveDone = false
    /// Height of the placed tiles' flow (rows only, no reserved space).
    @State private var lineContentHeight: CGFloat = 0
    /// Plateau: set on the weld so the welded text keeps the tiles' first row
    /// in place (it only loses its colour and closes up) instead of dropping
    /// to the baseline when it needs fewer rows. nil = bottom-aligned.
    @State private var weldTopInset: CGFloat?
    /// During the retry flash: tiles from this line position on show dashed.
    @State private var flashFrom: Int?
    @AppStorage(AppPalette.storageKey) private var paletteID = AppPalette.fallback.rawValue
    @AppStorage(DrillStyle.storageKey) private var drillStyleID = DrillStyle.fallback.rawValue

    static let tileHeight: CGFloat = 40
    private static let snap = Animation.spring(duration: 0.35, bounce: 0.3)
    private static let waveDuration = 0.75

    var body: some View {
        let theme = AppPalette(stored: paletteID).theme
        let style = DrillStyle(stored: drillStyleID)
        VStack(alignment: .leading, spacing: 0) {
            switch style {
            case .plateau:
                answerLine
                Rectangle()
                    .fill(AppColor.ink)
                    .frame(height: 1)
                    .padding(.top, 10)
            case .cadres:
                // The answer line becomes a framed well in the palette's deep line
                // colour; it fills pale and the outline firms up once right.
                answerLine
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(welded ? Color(hex: theme.tint) : .clear))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color(hex: theme.fragile).opacity(welded ? 1 : 0.55), lineWidth: 1.5))
                    .animation(.easeOut(duration: 0.35), value: welded)
            }
            DrillFeedbackLine(result: result, answer: Exercise.displayJoin(answerTokens),
                              note: retryNote)
                .padding(.top, 12)
            if result == false, let explainOnMiss {
                DrillMissExplanation(exercise: explainOnMiss)
                    .padding(.top, 8)
                    .transition(.opacity)
            }
            switch style {
            case .plateau:
                // The bank sits on a pale tray, like a magnet board (its colour
                // never changes; "Juste" in the footer confirms an answer).
                bankTray(inset: 16, shape: RoundedRectangle(cornerRadius: 28, style: .continuous),
                         fill: Color(hex: theme.tint))
                    .padding(.horizontal, -8)
                    .padding(.top, 16)
            case .cadres:
                bankTray(inset: 0, shape: Rectangle(), fill: .clear)
                    .padding(.top, 22)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onChange(of: result) { _, new in
            guard let new else { return }
            if new { weld() } else { shakeTrigger += 1 }
        }
        .onChange(of: retryTrigger) { _, _ in startRetry() }
        .onAppear {
            // Revisited live card that is already welded (e.g. sliding back in).
            if result == true && !welded { welded = true; waveDone = true }
        }
    }

    // MARK: - Answer line

    private var answerLine: some View {
        FlowLayout(spacing: welded ? 6 : 8, lineSpacing: 10) {
            ForEach(Array(placed.enumerated()), id: \.element) { position, index in
                lineTile(position: position, index: index)
            }
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { lineContentHeight = $0 }
        .padding(.top, weldTopInset ?? 0)
        .frame(maxWidth: .infinity, minHeight: reservedLineHeight,
               alignment: DrillStyle(stored: drillStyleID) == .cadres || weldTopInset != nil
                   ? .topLeading : .bottomLeading)
        .phaseAnimator([0.0, -10, 10, -7, 7, -3, 0], trigger: shakeTrigger) { content, x in
            content.offset(x: reduceMotion ? 0 : x)
        } animation: { _ in .linear(duration: 0.06) }
    }

    @ViewBuilder
    private func lineTile(position: Int, index: Int) -> some View {
        let token = bank[index]
        if welded {
            WaveText(text: token, size: 26, base: 300, tracking: -0.5,
                     start: (reduceMotion || waveDone) ? nil : weldStart,
                     letterOffset: letterOffset(before: position), totalLetters: totalPlacedLetters,
                     duration: Self.waveDuration)
                .frame(height: Self.tileHeight)
                .matchedGeometryEffect(id: index, in: ns)
        } else {
            let wrong = (result == false && !matchesAnswer(position: position, index: index))
                || (flashFrom.map { position >= $0 } ?? false)
            Button { tapPlaced(index) } label: {
                MagnetTile(text: token, style: wrong ? .wrong : .placed)
            }
            .buttonStyle(.plain)
            .allowsHitTesting(!isLocked && position >= lockedCount && flashFrom == nil)
            .scaleEffect(popping == index ? 1.1 : 1)
            .matchedGeometryEffect(id: index, in: ns)
            .accessibilityLabel(token)
            .accessibilityHint(isLocked ? "" : "Retirer de la phrase")
        }
    }

    // MARK: - Bank

    /// The bank on its tray. The tray hugs the tiles when they fit; when the
    /// space left above the footer is too small (an expanded hint, a long
    /// answer, a small screen) the tray takes exactly that space and the tiles
    /// scroll INSIDE it, clipped to the tray's own shape — so the visible tray
    /// edge is the boundary and nothing above it (answer line, hint) ever moves
    /// or gets covered. On a correct weld the clip lifts so leftovers can fall
    /// away off-screen.
    private func bankTray<S: Shape>(inset: CGFloat, shape: S, fill: Color) -> some View {
        ViewThatFits(in: .vertical) {
            bankArea
                .padding(inset)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(shape.fill(fill))
            ScrollView {
                bankArea
                    .padding(inset)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
            .background(shape.fill(fill))
            .clipShape(welded ? AnyShape(Rectangle().inset(by: -2000)) : AnyShape(shape))
        }
    }

    private var bankArea: some View {
        FlowLayout(spacing: 14, lineSpacing: 16) {
            ForEach(Array(bank.enumerated()), id: \.offset) { index, token in
                if placed.contains(index) {
                    // Keep the home slot so the bank never reflows.
                    MagnetTile(text: token, style: .bank).hidden()
                } else {
                    Button { tapBank(index) } label: {
                        MagnetTile(text: token, style: .bank)
                    }
                    .buttonStyle(.plain)
                    .allowsHitTesting(!isLocked)
                    .matchedGeometryEffect(id: index, in: ns)
                    .opacity(result == false ? 0.35 : 1)
                    // Correct → leftovers drop off-screen.
                    .offset(y: welded && !reduceMotion ? 900 : 0)
                    .opacity(welded ? 0 : 1)
                    .animation(
                        welded ? .easeIn(duration: 0.55).delay(Double(index % 6) * 0.04) : nil,
                        value: welded
                    )
                    .accessibilityLabel(token)
                }
            }
        }
    }

    // MARK: - Interaction

    private func tapBank(_ index: Int) {
        guard !isLocked else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(reduceMotion ? nil : Self.snap) {
            if maxPlaced == 1 {
                placed = [index]
            } else if let cap = maxPlaced, placed.count >= cap {
                return
            } else {
                placed.append(index)
            }
        }
        guard !reduceMotion else { return }
        popping = index
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.spring(duration: 0.3, bounce: 0.5)) {
                if popping == index { popping = nil }
            }
        }
    }

    private func tapPlaced(_ index: Int) {
        guard !isLocked else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(reduceMotion ? nil : Self.snap) {
            placed.removeAll { $0 == index }
        }
    }

    private func startRetry() {
        flashFrom = lockedCount
        shakeTrigger += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(reduceMotion ? nil : Self.snap) {
                placed = Array(placed.prefix(lockedCount))
                flashFrom = nil
            }
        }
    }

    private func weld() {
        weldStart = Date()
        // Same spot as bottom alignment right now; pins the first row from here on.
        weldTopInset = max(0, reservedLineHeight - lineContentHeight)
        withAnimation(reduceMotion ? nil : .spring(duration: 0.4, bounce: 0.15)) {
            welded = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.waveDuration + 0.05) {
            waveDone = true
        }
    }

    // MARK: - Helpers

    private func matchesAnswer(position: Int, index: Int) -> Bool {
        answerTokens.indices.contains(position) && answerTokens[position] == bank[index]
    }

    private var totalPlacedLetters: Int {
        placed.reduce(0) { $0 + bank[$1].count }
    }

    private func letterOffset(before position: Int) -> Int {
        placed.prefix(position).reduce(0) { $0 + bank[$1].count }
    }

    /// Reserve enough rows for the full answer up front so the baseline and the
    /// bank below don't jump as the line wraps.
    private var reservedLineHeight: CGFloat {
        let available = UIScreen.main.bounds.width - 2 * Spacing.screenH
        var rows = 1
        var x: CGFloat = 0
        for token in answerTokens {
            let w = MagnetTile.estimatedWidth(token)
            if x > 0 && x + 8 + w > available { rows += 1; x = w } else { x += (x > 0 ? 8 : 0) + w }
        }
        return CGFloat(rows) * Self.tileHeight + CGFloat(rows - 1) * 10
    }
}

// MARK: - Tile

/// One level word tile (07 `.tile`): 40pt capsule, 1pt ink border.
struct MagnetTile: View {
    enum Style { case bank, placed, wrong }
    let text: String
    var style: Style = .bank
    @AppStorage(AppPalette.storageKey) private var paletteID = AppPalette.fallback.rawValue

    private var theme: AppTheme { AppPalette(stored: paletteID).theme }

    /// Placed = palette fill, no outline; bank = white + ink outline; wrong =
    /// white + dashed outline in the palette's fragile colour. Text is ink.
    private var stroke: Color {
        switch style {
        case .bank: return AppColor.ink
        case .placed: return .clear
        case .wrong: return Color(hex: theme.fragile)
        }
    }

    var body: some View {
        Text(text)
            .font(.appToken)
            .tracking(-0.2)
            .lineLimit(1)
            .foregroundColor(AppColor.ink)
            .padding(.horizontal, 15)
            .frame(height: MagnetBoard.tileHeight)
            .background(Capsule().fill(style == .placed ? Color(hex: theme.tileOn) : AppColor.white))
            .overlay(
                Capsule().strokeBorder(
                    stroke,
                    style: StrokeStyle(lineWidth: style == .wrong ? 1.5 : 1, dash: style == .wrong ? [4, 3] : [])
                )
            )
            .contentShape(Capsule())
    }

    /// Rough width for layout reservation (19pt Manrope ≈ 10.5pt/char + padding).
    static func estimatedWidth(_ text: String) -> CGFloat {
        30 + CGFloat(text.count) * 10.5
    }
}

// MARK: - Feedback line (under the baseline)

/// "Réponse : …" under the answer baseline on a wrong live answer. Empty
/// otherwise (a correct answer is shown by the weld itself).
struct DrillFeedbackLine: View {
    let result: Bool?
    let answer: String
    /// Shown before the final result (e.g. the second-try line); nil = nothing.
    var note: String? = nil

    @State private var shown = false

    var body: some View {
        Group {
            if result == false {
                (Text("Réponse : ").foregroundColor(AppColor.graphite)
                    + Text(answer).foregroundColor(AppColor.ink))
                    .font(.appBody)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(shown ? 1 : 0)
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.4).delay(0.35)) { shown = true }
                    }
            } else if result == nil, let note {
                Text(note)
                    .font(.appBody)
                    .foregroundColor(AppColor.graphite)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Explanation on a miss

/// The drill's rule after a wrong answer: French, then the English beneath it.
struct DrillMissExplanation: View {
    let exercise: Exercise

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(exercise.explanation)
                .font(.appBody)
                .foregroundColor(AppColor.ink)
            if let english = exercise.displayExplanationEN {
                Text(english)
                    .font(.appBody)
                    .foregroundColor(AppColor.g2)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - FlowLayout

/// A simple wrapping flow layout: lays children left-to-right, wrapping to a new
/// line when the row would overflow the available width. Used for the magnet
/// bank and answer line so they read like text.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = computeRows(maxWidth: maxWidth, subviews: subviews)
        let height = rows.reduce(CGFloat.zero) { $0 + $1.height } +
            CGFloat(max(0, rows.count - 1)) * lineSpacing
        // Not clamped to the proposal: a child that can't shrink (one word)
        // makes the row wider, so a hugging parent (a chat bubble) grows
        // instead of squeezing that child into a truncated "…".
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let rows = computeRows(maxWidth: bounds.width, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            for item in row.items {
                let size = itemSize(item.index, maxWidth: bounds.width, subviews: subviews)
                subviews[item.index].place(
                    at: CGPoint(x: x, y: y + (row.height - size.height)),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(size)
                )
                x += size.width + spacing
            }
            y += row.height + lineSpacing
        }
    }

    // MARK: Row computation

    private struct RowItem { let index: Int }
    private struct Row { var items: [RowItem] = []; var width: CGFloat = 0; var height: CGFloat = 0 }

    private func itemSize(_ index: Int, maxWidth: CGFloat, subviews: Subviews) -> CGSize {
        let ideal = subviews[index].sizeThatFits(.unspecified)
        guard maxWidth.isFinite, ideal.width > maxWidth else { return ideal }
        return subviews[index].sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
    }

    private func computeRows(maxWidth: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        for index in subviews.indices {
            let size = itemSize(index, maxWidth: maxWidth, subviews: subviews)
            let projected = current.items.isEmpty ? size.width : current.width + spacing + size.width
            if !current.items.isEmpty && projected > maxWidth {
                rows.append(current)
                current = Row(items: [RowItem(index: index)], width: size.width, height: size.height)
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
