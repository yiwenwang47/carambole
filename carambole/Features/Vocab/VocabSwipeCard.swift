//
//  VocabSwipeCard.swift
//  carambole
//
//  One *Mots* card in the swipe stack, and the play disc shared with the Leçon
//  page. Port of design/vocab/vocab-swipe.src.html v7 (`.row`, `.play`): every
//  card looks the same (white face, 1.5 pt ink outline, 72 pt high), the word
//  with its article smaller after it, a « Trop facile ? » tag on an armed word,
//  a dashed outline once the word was swiped left. The stack, gestures and
//  underlay live in `VocabSessionView`.
//

import SwiftUI

struct VocabSwipeCard: View {
    let card: VocabQueue.Card
    let theme: AppTheme
    /// The fill the card takes as it flies out (right: `tileOn`, up:
    /// `buttonFill`); nil = white face with its outline.
    var leavingFill: Color? = nil

    static let height: CGFloat = 72

    var body: some View {
        HStack(spacing: 10) {
            VocabHeadword(entry: card.entry, size: 23)
                .frame(maxWidth: .infinity, alignment: .leading)
            if card.armed {
                Text("Trop facile ?")
                    .font(.label(size: 10))
                    .tracking(labelTracking)
                    .textCase(.uppercase)
                    .foregroundColor(Color(hex: theme.fragile))
                    .lineLimit(1)
                    .fixedSize()
            }
            VocabPlayDisc(entry: card.entry, theme: theme)
        }
        .padding(.leading, 18)
        .padding(.trailing, 14)
        .frame(height: Self.height)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(leavingFill ?? AppColor.paper))
        .overlay {
            if leavingFill == nil {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(card.again ? Color(hex: theme.fragile) : AppColor.ink,
                                  style: StrokeStyle(lineWidth: 1.5, dash: card.again ? [3, 2.5] : []))
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(card.entry.displayFR + (card.armed ? ", trop facile ?" : ""))
    }
}

/// « confiance » + a smaller grey « (la) », dictionary style (`.w small`: 0.66 em
/// at 23 pt, 15 pt at 21 pt, 5 pt apart).
struct VocabHeadword: View {
    let entry: VocabEntry
    let size: CGFloat
    var articleSize: CGFloat? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Text(entry.displayWord)
                .font(.display(size: size, wght: 400))
                .foregroundColor(AppColor.ink)
            if let article = entry.displayArticle {
                Text(article)
                    .font(.display(size: articleSize ?? (size * 0.66).rounded(), wght: 400))
                    .foregroundColor(AppColor.g2)
            }
        }
        .lineLimit(1)
        // The mock ellipsises a long headword; a vocab card must show the whole
        // word, so it shrinks a little first (as Book 1's drill text does).
        .minimumScaleFactor(0.7)
    }
}

/// Book 2's replay disc (`.play`): a 34 pt pale `quietFill` disc, ink triangle,
/// no outline. Plays the bundled clip only (no synthesized fallback, as Book 2
/// word audio); a missing clip dims the disc. Never counts as a peek.
struct VocabPlayDisc: View {
    let entry: VocabEntry
    let theme: AppTheme

    var body: some View {
        let hasAudio = Speaker.bundledAudioURL(key: entry.audio) != nil
        Button {
            Speaker.shared.playBundled(key: entry.audio)
        } label: {
            PlayTriangle()
                .fill(AppColor.ink)
                .frame(width: 11, height: 11)
                .offset(x: 1)
                .frame(width: 34, height: 34)
                .background(Circle().fill(Color(hex: theme.quietFill)))
                .contentShape(Circle())
        }
        .buttonStyle(PlayDiscStyle())
        .disabled(!hasAudio)
        .opacity(hasAudio ? 1 : 0.35)
        .accessibilityLabel("Écouter \(entry.displayWord)")
    }
}

/// The mock's `M1 .8v10.4L10.4 6z` in a 11 × 12 view box, fitted (meet) into
/// the frame.
private struct PlayTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        let s = min(rect.width / 11, rect.height / 12)
        let ox = rect.minX + (rect.width - 11 * s) / 2, oy = rect.minY + (rect.height - 12 * s) / 2
        var p = Path()
        p.move(to: CGPoint(x: ox + 1 * s, y: oy + 0.8 * s))
        p.addLine(to: CGPoint(x: ox + 1 * s, y: oy + 11.2 * s))
        p.addLine(to: CGPoint(x: ox + 10.4 * s, y: oy + 6 * s))
        p.closeSubpath()
        return p
    }
}

/// `.play:active { transform: scale(.92) }`, 0.15 s.
private struct PlayDiscStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
