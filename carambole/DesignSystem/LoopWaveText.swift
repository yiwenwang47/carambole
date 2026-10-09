//
//  LoopWaveText.swift
//  carambole
//
//  The motion.html 02 title: a CONTINUOUS, looping weight wave that rolls
//  through the letters forever (unlike `WaveText`, the one-shot 07 weld wave).
//  Per letter: s = max(0, sin(t·1.1 − i·0.32)), wght = 200 + 520·s⁴.
//
//  Letters sit inline and words never break. Lines are wrapped ONCE from a
//  reference weight (not per frame), so the wave never makes the title reflow;
//  the font steps down from `maxSize` until the title fits in `maxLines`.
//

import SwiftUI
import UIKit

struct LoopWaveText: View {
    let text: String
    var maxSize: CGFloat = 54
    var minSize: CGFloat = 28
    var maxLines: Int = 3
    /// CSS line-height in em (02 `.title`: .98).
    var lineHeight: CGFloat = 0.98
    /// CSS letter-spacing in em (02 `.title`: -0.035em).
    var trackingEm: CGFloat = -0.035
    /// Static weight when the wave is off (reduce motion).
    var restWeight: CGFloat = 300

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var width: CGFloat = 0

    var body: some View {
        let fit = Self.fit(text: text, width: width > 0 ? width : 320, maxSize: maxSize,
                           minSize: minSize, maxLines: maxLines, trackingEm: trackingEm)
        Group {
            if reduceMotion {
                lines(fit, t: nil)
            } else {
                TimelineView(.animation) { ctx in
                    lines(fit, t: ctx.date.timeIntervalSinceReferenceDate)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
        .accessibilityAddTraits(.isHeader)
    }

    // MARK: Rendering

    private func lines(_ fit: Fit, t: Double?) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(fit.lines.enumerated()), id: \.offset) { _, line in
                HStack(spacing: 0) {
                    ForEach(Array(line.enumerated()), id: \.offset) { w, word in
                        if w > 0 {
                            Text(" ").font(.display(size: fit.size, wght: 200))
                        }
                        ForEach(Array(word.letters.enumerated()), id: \.offset) { k, ch in
                            Text(String(ch))
                                .font(.display(size: fit.size, wght: weight(t: t, index: word.start + k)))
                                .tracking(fit.size * trackingEm)
                        }
                    }
                }
                .fixedSize()
                .frame(height: fit.size * lineHeight)
            }
        }
    }

    private func weight(t: Double?, index: Int) -> CGFloat {
        guard let t else { return restWeight }
        return Self.weight(t: t, index: index)
    }

    /// Weight of letter `index` (spaces not counted) at time `t` (seconds).
    static func weight(t: Double, index: Int) -> CGFloat {
        let s = max(0, sin(t * 1.1 - Double(index) * 0.32))
        return 200 + 520 * CGFloat(pow(s, 4))
    }

    // MARK: Fit (wrap once, step the size down until it fits)

    struct Word {
        let letters: [Character]
        /// Index of this word's first letter in the whole title (spaces excluded).
        let start: Int
    }

    struct Fit {
        let size: CGFloat
        let lines: [[Word]]
    }

    static func fit(text: String, width: CGFloat, maxSize: CGFloat, minSize: CGFloat,
                    maxLines: Int, trackingEm: CGFloat) -> Fit {
        var words: [Word] = []
        var index = 0
        for part in text.split(separator: " ") {
            words.append(Word(letters: Array(part), start: index))
            index += part.count
        }

        var size = maxSize
        while true {
            // Measure at a mid weight so letters swelling under the wave still fit.
            let font = AppFonts.uiFont(AppFonts.manrope, size: size, wght: 340)
            let attrs: [NSAttributedString.Key: Any] = [.font: font, .kern: size * trackingEm]
            let space = (" " as NSString).size(withAttributes: [.font: font]).width
            let widths = words.map { (String($0.letters) as NSString).size(withAttributes: attrs).width }

            var lines: [[Word]] = []
            var current: [Word] = []
            var lineWidth: CGFloat = 0
            for (word, w) in zip(words, widths) {
                if current.isEmpty {
                    current = [word]; lineWidth = w
                } else if lineWidth + space + w <= width {
                    current.append(word); lineWidth += space + w
                } else {
                    lines.append(current)
                    current = [word]; lineWidth = w
                }
            }
            if !current.isEmpty { lines.append(current) }

            let fits = lines.count <= maxLines && (widths.max() ?? 0) <= width
            if fits || size <= minSize { return Fit(size: size, lines: lines) }
            size -= 2
        }
    }

    #if DEBUG
    static func _selfTest() {
        // Crest at 720, trough at 200, and letters further along lag behind.
        assert(abs(weight(t: (.pi / 2) / 1.1, index: 0) - 720) < 0.5)
        assert(weight(t: 0, index: 3) == 200)
        let fit = fit(text: "Le futur proche", width: 320, maxSize: 54, minSize: 28,
                      maxLines: 3, trackingEm: -0.035)
        assert(fit.lines.flatMap { $0 }.count == 3, "words must never split")
        assert(fit.lines.last?.last?.start == 7, "letter indices skip spaces")
    }
    #endif
}

#Preview {
    LoopWaveText(text: "Le futur proche")
        .padding(20)
        .background(AppColor.paper)
}
