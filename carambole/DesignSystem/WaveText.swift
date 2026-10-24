//
//  WaveText.swift
//  carambole
//
//  The motion.html weight wave: a sin² pulse on Manrope's `wght` axis that
//  runs letter by letter (02 title, 07 weld). Pure timing lives in
//  `WaveText.weight(...)` so callers can share one clock across several words.
//

import SwiftUI

struct WaveText: View {
    let text: String
    var size: CGFloat
    /// Resting weight.
    var base: CGFloat = 300
    /// Peak weight at the crest of the wave.
    var peak: CGFloat = 720
    var tracking: CGFloat = 0
    /// Wave start. nil → static at `base` (also the reduce-motion path).
    var start: Date?
    /// This word's first letter index within the whole sentence, so a wave can
    /// travel across several `WaveText`s.
    var letterOffset: Int = 0
    /// Letter count of the whole sentence (stagger is spread over it).
    var totalLetters: Int? = nil
    /// Whole-sentence wave duration (seconds).
    var duration: Double = 0.75

    /// Set once this wave has run its course, so the TimelineView stops ticking.
    @State private var finishedStart: Date?

    private var letters: [Character] { Array(text) }

    var body: some View {
        Group {
            if let start, finishedStart != start {
                TimelineView(.animation) { ctx in
                    row(t: ctx.date.timeIntervalSince(start))
                }
            } else {
                row(t: -1)
            }
        }
        .task(id: start) {
            guard let start else { return }
            let remaining = start.timeIntervalSinceNow + duration + 0.05
            if remaining > 0 { try? await Task.sleep(for: .seconds(remaining)) }
            if !Task.isCancelled { finishedStart = start }
        }
    }

    /// Words wrap at spaces when the proposed width is too narrow (a long weld
    /// sentence goes onto more lines instead of squeezing its letters). Each
    /// word takes its size at the resting weight, so the bolder crest never
    /// moves a line break mid-wave, and a word never breaks inside itself.
    private func row(t: Double) -> some View {
        let total = totalLetters ?? letters.count
        return FlowLayout(spacing: spaceWidth, lineSpacing: 0) {
            ForEach(words, id: \.start) { word in
                letterRow(word, weight: { _ in base })
                    .hidden()
                    .overlay(alignment: .leading) {
                        letterRow(word, weight: { i in
                            Self.weight(t: t, index: letterOffset + i, total: total,
                                        duration: duration, base: base, peak: peak)
                        })
                    }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
    }

    private func letterRow(_ word: (start: Int, end: Int), weight: @escaping (Int) -> CGFloat) -> some View {
        HStack(spacing: 0) {
            ForEach(word.start..<word.end, id: \.self) { i in
                Text(String(letters[i]))
                    .font(.display(size: size, wght: weight(i)))
                    .tracking(tracking)
            }
        }
        .fixedSize()
    }

    /// Letter ranges of the words; spaces keep their index so the wave timing
    /// matches the unsplit text.
    private var words: [(start: Int, end: Int)] {
        var result: [(start: Int, end: Int)] = []
        var start: Int?
        for (i, ch) in letters.enumerated() {
            if ch == " " {
                if let s = start { result.append((s, i)); start = nil }
            } else if start == nil {
                start = i
            }
        }
        if let s = start { result.append((s, letters.count)) }
        return result
    }

    private var spaceWidth: CGFloat {
        let font = AppFonts.uiFont(AppFonts.manrope, size: size, wght: base)
        return (" " as NSString).size(withAttributes: [.font: font]).width + tracking
    }

    /// Weight of letter `index` at time `t` (seconds since start). Each letter
    /// pulses for `pulse` seconds; starts are staggered so the last letter ends
    /// at `duration`.
    static func weight(t: Double, index: Int, total: Int, duration: Double,
                       base: CGFloat, peak: CGFloat) -> CGFloat {
        guard t >= 0 else { return base }
        let pulse = min(0.35, duration)
        let stagger = total > 1 ? min(0.06, (duration - pulse) / Double(total - 1)) : 0
        let local = (t - Double(index) * stagger) / pulse
        guard local > 0, local < 1 else { return base }
        let s = sin(local * .pi)
        return base + (peak - base) * CGFloat(s * s)
    }

    #if DEBUG
    static func _selfTest() {
        assert(weight(t: -1, index: 0, total: 5, duration: 0.75, base: 300, peak: 720) == 300)
        let crest = weight(t: 0.175, index: 0, total: 5, duration: 0.75, base: 300, peak: 720)
        assert(abs(crest - 720) < 1, "first letter should crest mid-pulse")
        // Everything is back at rest once the wave has finished.
        for i in 0..<40 {
            assert(weight(t: 0.76, index: i, total: 40, duration: 0.75, base: 300, peak: 720) == 300,
                   "letter \(i) still waving after duration")
        }
    }
    #endif
}
