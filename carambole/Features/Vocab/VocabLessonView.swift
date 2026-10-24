//
//  VocabLessonView.swift
//  carambole
//
//  The *Mots* Leçon page: a pale slab with the leçon number, then the leçon as
//  classical dictionary rows (headword + article in parentheses, small part of
//  speech in a left margin, the English on its own line, a play disc). Swiping
//  a row left arms trop facile for that word (pale lime row, no label); a
//  second swipe disarms it. Armed words come first in the swipe stack (their
//  cards carry no tag). The list scrolls; Commencer stays at the bottom. No
//  audio-source labels.
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
    /// Row being swiped and how far (≤ 0).
    @State private var dragging: String?
    @State private var dragOffset: CGFloat = 0

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
                    Text("Glisse à gauche un mot trop facile")
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
        #if DEBUG
        .onAppear {
            // Simulator harness (DrillDemo): hold one row mid-swipe.
            if let id = ProcessInfo.processInfo.environment["CB_VOCAB_DRAG"] {
                dragging = id; dragOffset = -150
            }
        }
        #endif
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
    /// below; the row's fill reaches 10 pt past the text on both sides. The
    /// part of speech sits in a 52 pt margin on the headword's first baseline,
    /// a register under it; the headword wraps (design/vocab/lecon-pos-options.html, B).
    private func row(_ entry: VocabEntry, index: Int) -> some View {
        let on = armed.contains(entry.id)
        let prevOn = index > 0 && armed.contains(lecon.entries[index - 1].id)
        let last = index == lecon.entries.count - 1
        let dragX = dragging == entry.id ? dragOffset : 0
        return HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    marginLabel(entry)
                    VocabHeadword(entry: entry, size: 21, articleSize: 15, wraps: true)
                }
                Text(entry.en)
                    .font(.display(size: 15, wght: 400))
                    .lineSpacing(15 * 0.4 - 4)
                    .foregroundColor(AppColor.graphite)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, Self.marginWidth)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            VocabPlayDisc(entry: entry, theme: theme)
        }
        .padding(.vertical, 18)
        .padding(.leading, 10)
        .padding(.trailing, 8)
        .background(RoundedRectangle(cornerRadius: on || dragX != 0 ? 14 : 0, style: .continuous)
            .fill(on ? Color(hex: theme.tileOn) : AppColor.paper))
        .offset(x: dragX)
        .background(alignment: .trailing) {
            // What the swipe uncovers: the state the row will switch to.
            if dragX != 0 {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(on ? AppColor.paper : Color(hex: theme.tileOn))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(on ? AppColor.hairline : .clear, lineWidth: 1))
                    .overlay(alignment: .trailing) {
                        Text(on ? "Remettre" : "Trop facile")
                            .uppercaseLabel(AppColor.ink)
                            .padding(.trailing, 18)
                    }
            }
        }
        .overlay(alignment: .top) {
            Rectangle().fill(AppColor.hairline).frame(height: 1).opacity(on || prevOn ? 0 : 1)
        }
        .overlay(alignment: .bottom) {
            if last { Rectangle().fill(AppColor.hairline).frame(height: 1).opacity(on ? 0 : 1) }
        }
        .padding(.horizontal, -10)
        .contentShape(Rectangle())
        .gesture(swipe(entry))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(on ? .isSelected : [])
        .accessibilityAction(named: on ? "Remettre" : "Trop facile") { toggle(entry) }
    }

    private static let marginWidth: CGFloat = 52

    /// Part of speech in the margin; a register hangs under it without taking
    /// height from the row (the English stays right under the headword).
    private func marginLabel(_ entry: VocabEntry) -> some View {
        Text(entry.pos)
            .font(.label(size: 10))
            .uppercaseLabel()
            .fixedSize()
            .overlay(alignment: .topLeading) {
                if let register = entry.register, !register.isEmpty {
                    Text(register)
                        .font(.label(size: 10))
                        .uppercaseLabel()
                        .fixedSize()
                        .offset(y: AppFonts.uiFont(AppFonts.familjen, size: 10, wght: 400).lineHeight + 5)
                }
            }
            .frame(width: Self.marginWidth, alignment: .leading)
    }

    /// Left swipe past half the row toggles trop facile, then the row springs
    /// home. A UIKit pan that only begins on a leftward horizontal drag, so
    /// vertical drags stay with the list's scroll (a SwiftUI DragGesture on
    /// the rows took every touch and the list stopped scrolling).
    private func swipe(_ entry: VocabEntry) -> LeftSwipeGesture {
        LeftSwipeGesture(
            onChange: { dx in
                dragging = entry.id
                dragOffset = min(0, dx)
            },
            onEnd: { dx in
                if dx < -rowWidth / 2 {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    toggle(entry)
                }
                withAnimation(.spring(duration: 0.4, bounce: 0.15)) { dragOffset = 0 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    if dragOffset == 0 { dragging = nil }
                }
            })
    }

    private var rowWidth: CGFloat { UIScreen.main.bounds.width - 20 }

    private func toggle(_ entry: VocabEntry) {
        withAnimation(.easeOut(duration: 0.2)) {
            if armed.contains(entry.id) { armed.remove(entry.id) } else { armed.insert(entry.id) }
        }
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

/// Pan that begins only when the finger first moves left more than it moves
/// up or down; reports the horizontal translation.
struct LeftSwipeGesture: UIGestureRecognizerRepresentable {
    let onChange: (CGFloat) -> Void
    let onEnd: (CGFloat) -> Void

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let pan = UIPanGestureRecognizer()
        pan.delegate = context.coordinator
        return pan
    }

    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
        let dx = recognizer.translation(in: recognizer.view).x
        switch recognizer.state {
        case .began, .changed: onChange(dx)
        case .ended: onEnd(dx)
        case .cancelled, .failed: onEnd(0)
        default: break
        }
    }

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return false }
            let v = pan.velocity(in: pan.view)
            return v.x < 0 && abs(v.x) > abs(v.y)
        }
    }
}
