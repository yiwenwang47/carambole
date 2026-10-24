//
//  VocabSwipeCard.swift
//  carambole
//
//  One *Mots* card in the swipe stack, and the play disc shared with the Leçon
//  page. Port of design/vocab/vocab-swipe.src.html v7 (`.row`, `.play`): every
//  card looks the same (white face, 1.5 pt ink outline, 72 pt high), the word
//  with its article smaller after it, a dashed outline once the word was swiped
//  left. An armed word's card looks like any other (no tag, user 2026-10-24).
//  Every card is the same fixed size (user 2026-10-24: a new word fades into
//  the swiped card's slot); a long headword shrinks to fit one line, and
//  `_selfTest` checks every entry fits before the shrink runs out. The slots,
//  gestures and underlay live in `VocabSessionView`.
//

import SwiftUI

struct VocabSwipeCard: View {
    let card: VocabQueue.Card
    let theme: AppTheme
    /// The fill the card takes as it flies out (right: `tileOn`); nil = white
    /// face with its outline.
    var leavingFill: Color? = nil

    static let height: CGFloat = 72
    /// Headword size, and how far a long one may shrink.
    static let headSize: CGFloat = 23
    static let minScale: CGFloat = 0.7

    var body: some View {
        HStack(spacing: 10) {
            VocabHeadword(entry: card.entry, size: Self.headSize, minScale: Self.minScale)
                .frame(maxWidth: .infinity, alignment: .leading)
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
        .accessibilityLabel(card.entry.displayFR)
    }
}

/// « confiance » + a smaller grey « (la) », dictionary style (`.w small`: 0.66 em
/// at 23 pt, 15 pt at 21 pt, 5 pt apart). Cards: one line; a word too long for
/// the line shrinks to fit. Leçon rows (`wraps`): full size, wraps at spaces
/// (never « … »: dots are forbidden, user 2026-10-24).
struct VocabHeadword: View {
    let entry: VocabEntry
    let size: CGFloat
    var articleSize: CGFloat? = nil
    /// Wrap at spaces at full size (Leçon rows) instead of one shrinking line.
    var wraps: Bool = false
    /// One line: how far it may shrink.
    var minScale: CGFloat = 0.7

    var body: some View {
        if wraps { wrapped } else { oneLine }
    }

    /// The article is joined to the last word by a no-break space.
    private var wrapped: some View {
        var text = Text(entry.displayWord)
            .font(.display(size: size, wght: 400))
            .foregroundColor(AppColor.ink)
        if let article = entry.displayArticle {
            text = text + Text("\u{00A0}" + article)
                .font(.display(size: articleSize ?? (size * 0.66).rounded(), wght: 400))
                .foregroundColor(AppColor.g2)
        }
        return text.fixedSize(horizontal: false, vertical: true)
    }

    private var oneLine: some View {
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
        .minimumScaleFactor(minScale)
    }
}

#if DEBUG
extension VocabSwipeCard {
    /// Every headword of the book fits a card on a 375 pt wide phone (the
    /// narrowest) within `minScale`, so the one-line shrink never runs out
    /// into « … » (HARD RULE). Text room: card = 375 − 40 + 16 − 24; minus
    /// 18 + 14 padding, 10 spacing, 34 play disc.
    static func _selfTest() {
        let room: CGFloat = 375 - 40 + 16 - 24 - 18 - 14 - 10 - 34
        let word = AppFonts.uiFont(AppFonts.manrope, size: headSize, wght: 400)
        let article = AppFonts.uiFont(AppFonts.manrope, size: (headSize * 0.66).rounded(), wght: 400)
        func width(_ s: String, _ f: UIFont) -> CGFloat { (s as NSString).size(withAttributes: [.font: f]).width }
        var widest: (CGFloat, String) = (0, "")
        for entry in VocabBook.bundled.entries {
            var w = width(entry.displayWord, word)
            if let a = entry.displayArticle { w += 5 + width(a, article) }
            if w > widest.0 { widest = (w, entry.displayFR) }
            assert(w * minScale <= room, "« \(entry.displayFR) » does not fit a card even shrunk (\(Int(w)) pt)")
        }
        print("VocabSwipeCard._selfTest: ok, widest « \(widest.1) » \(Int(widest.0)) pt of \(Int(room)) pt")
    }
}
#endif

/// Book 2's replay disc (`.play`): a 34 pt pale `quietFill` disc, ink triangle,
/// no outline. Plays the bundled clip only (no synthesized fallback, as Book 2
/// word audio); a missing clip dims the disc. Never counts as a peek.
/// While its clip plays the disc holds the mock's `.play.ing` state
/// (`transform: scale(.92)`, 0.15 s `ease`, the same look as pressed); it goes
/// back when the clip ends, another clip replaces it, or the session stops
/// audio (`speak()` / `onended` in the mock).
struct VocabPlayDisc: View {
    let entry: VocabEntry
    let theme: AppTheme
    @State private var playing = false
    @State private var playToken = 0

    var body: some View {
        let hasAudio = Speaker.bundledAudioURL(key: entry.audio) != nil
        Button(action: play) {
            PlayTriangle()
                .fill(AppColor.ink)
                .frame(width: 11, height: 11)
                .offset(x: 1)
                .frame(width: 34, height: 34)
                .background(Circle().fill(Color(hex: theme.quietFill)))
                .contentShape(Circle())
        }
        .buttonStyle(PlayDiscStyle(playing: playing))
        .disabled(!hasAudio)
        .opacity(hasAudio ? 1 : 0.35)
        .accessibilityLabel("Écouter \(entry.displayWord)")
        #if DEBUG
        .onReceive(NotificationCenter.default.publisher(for: Self.debugPlay)) { note in
            if note.object as? String == entry.id { play() }
        }
        #endif
    }

    private func play() {
        playToken += 1
        let token = playToken
        // A replay of this disc ends the old clip first (its onEnd is ignored
        // by token), then this one plays.
        Speaker.shared.playBundled(key: entry.audio) {
            DispatchQueue.main.async { if playToken == token { playing = false } }
        }
        playing = true   // a clip that can't play calls onEnd, which reverts it
    }

    #if DEBUG
    /// `CB_VOC_SCRIPT` step `play`: object = the entry id whose disc to press.
    static let debugPlay = Notification.Name("cb.voc.play")
    #endif
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

/// `.play:active, .play.ing { transform: scale(.92) }` with the `.play`
/// transition `transform .15s` (CSS default timing `ease`).
private struct PlayDiscStyle: ButtonStyle {
    let playing: Bool

    func makeBody(configuration: Configuration) -> some View {
        let down = configuration.isPressed || playing
        configuration.label
            .scaleEffect(down ? 0.92 : 1)
            .animation(.timingCurve(0.25, 0.1, 0.25, 1, duration: 0.15), value: down)
    }
}
