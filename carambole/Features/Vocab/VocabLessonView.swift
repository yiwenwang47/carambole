//
//  VocabLessonView.swift
//  carambole
//
//  The *Mots* Leçon page: a pale slab with the leçon number, then the leçon as
//  classical dictionary rows (headword + article in parentheses, small part of
//  speech, the English on its own line, a play disc). Tapping a row arms trop
//  facile for that word (pale lime row); armed words come first in the swipe
//  stack (their cards carry no tag). The list scrolls; Commencer stays at the
//  bottom. No swiping here, no audio-source labels.
//  Port of design/vocab/vocab-swipe.src.html v7 (`#lesson`).
//

import SwiftUI

struct VocabLessonView: View {
    let lecon: VocabLecon
    /// Cards the session will serve (the leçon's pending entries).
    let startCount: Int
    let canStart: Bool
    @Binding var armed: Set<String>
    let onStart: () -> Void
    let onClose: () -> Void

    @AppStorage(AppPalette.storageKey) private var paletteID = AppPalette.fallback.rawValue
    private var theme: AppTheme { AppPalette(stored: paletteID).theme }

    /// « Leçon 63 · mots 601–700 ».
    private var slabLabel: String {
        let lo = (lecon.band - 1) * 100 + 1, hi = lecon.band * 100
        return "Leçon \(lecon.index) · mots \(lo)–\(hi)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VocabCloseButton(action: onClose)
            slab.padding(.top, 4)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Touche un mot trop facile pour le retirer")
                        .uppercaseLabel()
                        .padding(.top, 22)
                        .padding(.bottom, 10)
                    ForEach(Array(lecon.entries.enumerated()), id: \.element.id) { i, entry in
                        row(entry, index: i)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .padding(.horizontal, -20)
            Button(buttonTitle, action: onStart)
                .buttonStyle(DrillButtonStyle())
                .disabled(!canStart || startCount == 0)
                .opacity(canStart && startCount > 0 ? 1 : 0.4)
                .padding(.top, 14)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, Spacing.sm)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppColor.paper.ignoresSafeArea())
    }

    private var buttonTitle: String {
        if !canStart { return "Verrouillé" }
        return "Commencer · \(startCount) \(startCount == 1 ? "mot" : "mots")"
    }

    /// `.slab`: 92 pt, radius 24, quiet fill; label top-left, the leçon number
    /// 120 / 200 hanging off the bottom-right corner.
    private var slab: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Color(hex: theme.quietFill))
            .overlay(alignment: .bottomTrailing) {
                Text("\(lecon.index)")
                    .font(.display(size: 120, wght: 200))
                    .tracking(-7)
                    .foregroundColor(AppColor.ink.opacity(0.9))
                    .lineLimit(1)
                    .fixedSize()
                    .frame(height: 120)
                    .offset(x: 2, y: 34)
                    .accessibilityHidden(true)
            }
            .overlay(alignment: .topLeading) {
                Text(slabLabel)
                    .uppercaseLabel(AppColor.ink)
                    .padding(.leading, 16)
                    .padding(.top, 14)
            }
            .frame(height: 92)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .accessibilityElement(children: .combine)
    }

    /// `.entry`: hairline above (none next to an armed row), 18 pt above and
    /// below; the row's fill reaches 10 pt past the text on both sides.
    private func row(_ entry: VocabEntry, index: Int) -> some View {
        let on = armed.contains(entry.id)
        let prevOn = index > 0 && armed.contains(lecon.entries[index - 1].id)
        let last = index == lecon.entries.count - 1
        return HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    VocabHeadword(entry: entry, size: 21, articleSize: 15)
                        .layoutPriority(1)
                    Text(entry.posLabel)
                        .font(.label(size: 10))
                        .uppercaseLabel()
                        .lineLimit(1)
                        .fixedSize()
                    if on {
                        Text("Trop facile")
                            .font(.label(size: 10))
                            .uppercaseLabel(AppColor.ink)
                            .lineLimit(1)
                            .fixedSize()
                    }
                }
                Text(entry.en)
                    .font(.display(size: 15, wght: 400))
                    .lineSpacing(15 * 0.4 - 4)
                    .foregroundColor(AppColor.graphite)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            VocabPlayDisc(entry: entry, theme: theme)
        }
        .padding(.vertical, 18)
        .padding(.leading, 10)
        .padding(.trailing, 8)
        .background(RoundedRectangle(cornerRadius: on ? 14 : 0, style: .continuous)
            .fill(on ? Color(hex: theme.tileOn) : Color.clear))
        .overlay(alignment: .top) {
            Rectangle().fill(AppColor.hairline).frame(height: 1).opacity(on || prevOn ? 0 : 1)
        }
        .overlay(alignment: .bottom) {
            if last { Rectangle().fill(AppColor.hairline).frame(height: 1).opacity(on ? 0 : 1) }
        }
        .padding(.horizontal, -10)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeOut(duration: 0.2)) {
                if on { armed.remove(entry.id) } else { armed.insert(entry.id) }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(on ? [.isButton, .isSelected] : .isButton)
        .accessibilityHint("Marquer trop facile")
    }
}

/// The mock's `.x` (32 pt button, nudged 6 pt left). The mock sets « ✕ » at
/// 20 px, line-height 1, in ink; Chrome draws it as two straight bars with
/// square (butt) ends. Measured from the rendered mock: bar centre lines run
/// corner to corner of a 12.7 pt square centred at (16.0, 16.6) in the button
/// (14 × 14 pt ink box). The outline is 1.55 pt at 10×, but at the phone's 3×
/// Chrome's glyph rasterising darkens it to the coverage of a 1.8 pt path, so
/// the stroke is 1.8 to look the same on screen. A path, not a font glyph.
struct VocabCloseButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VocabCloseGlyph()
                .stroke(AppColor.ink, style: StrokeStyle(lineWidth: 1.8, lineCap: .butt))
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.leading, -6)
        .accessibilityLabel("Quitter")
    }
}

/// The two bars of the mock's ✕ in its 32 × 32 button (see `VocabCloseButton`).
struct VocabCloseGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height) / 32
        let cx = rect.midX, cy = rect.midY + 0.6 * s, h = 6.36 * s
        var p = Path()
        p.move(to: CGPoint(x: cx - h, y: cy - h)); p.addLine(to: CGPoint(x: cx + h, y: cy + h))
        p.move(to: CGPoint(x: cx + h, y: cy - h)); p.addLine(to: CGPoint(x: cx - h, y: cy + h))
        return p
    }
}
