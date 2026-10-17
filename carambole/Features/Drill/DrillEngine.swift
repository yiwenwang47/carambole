import Foundation

struct DrillEngine {
    /// Grades a submitted answer. Token modes (multiple-choice / build-from-tokens)
    /// require an exact, order-sensitive match. Free-text typing normalizes case,
    /// apostrophe shape, and surrounding/inner whitespace, but PRESERVES accents
    /// (`é` ≠ `e`) — accent correctness is graded.
    static func check(_ submitted: [String], _ exercise: Exercise) -> Bool {
        switch exercise.resolvedInputMode {
        case .freeText:
            return normalize(submitted.joined(separator: " "))
                == normalize(exercise.answerTokens.joined(separator: " "))
        case .multipleChoice:
            return submitted == exercise.answerTokens
        case .spotError:
            // The submitted tokens are the shown sentence with the learner's one
            // replacement applied; right only when that restores the sentence.
            return submitted == exercise.answerTokens
        case .buildFromTokens:
            // The learner builds words only — bare-punctuation chips are never
            // offered, so grade against the punctuation-stripped answer. Compare
            // by SURFACE string, not chip array: a multi-word chip the bank offers
            // ("à la") must grade the same as its separate parts ("à","la") — both
            // produce the identical, correctly-ordered sentence. Word ORDER is still
            // graded (a reorder changes the surface); only the pedagogically
            // irrelevant chip partition is allowed to differ.
            return buildSurface(submitted)
                == buildSurface(exercise.producibleAnswerTokens)
        }
    }

    /// Second try on a build: how many leading placed tiles are right. The largest
    /// `k` whose first `k` chips spell, by surface, the first words of the answer —
    /// so a multi-word chip ("à la") or a split elision ("N'" + "es-tu") counts the
    /// same as it grades. These tiles stay on the line, locked; the rest go home.
    static func correctPrefixCount(_ submitted: [String], _ exercise: Exercise) -> Int {
        let target = buildSurface(exercise.producibleAnswerTokens).split(separator: " ")
        var best = 0
        for k in 0...submitted.count {
            let words = buildSurface(Array(submitted.prefix(k))).split(separator: " ")
            if words.count <= target.count && Array(target.prefix(words.count)) == words {
                best = k
            }
        }
        return best
    }

    /// True when a wrong build already spells the whole answer and only has tiles
    /// after it. Nothing is left to fix by building, so it gets no second try.
    static func isAnswerPlusExtra(_ submitted: [String], _ exercise: Exercise) -> Bool {
        let k = correctPrefixCount(submitted, exercise)
        return k < submitted.count
            && buildSurface(Array(submitted.prefix(k))) == buildSurface(exercise.producibleAnswerTokens)
    }

    /// Surface form for build-mode grading: unify apostrophe shape, split every chip
    /// on whitespace (so a multi-word chip and its separate parts collapse equal),
    /// then rejoin with single spaces — EXCEPT glue (no space) after a token ending
    /// in an apostrophe, so a French elision (`N'` + `es-tu`) reads `N'es-tu`,
    /// identical to the combined `N'es-tu` chip. Case + accents are PRESERVED (chips
    /// are pre-cased / pre-accented, so any difference is a real error).
    static func buildSurface(_ tokens: [String]) -> String {
        let words = tokens
            .map {
                $0.replacingOccurrences(of: "\u{2019}", with: "'")   // ’ → '
                  .replacingOccurrences(of: "\u{02BC}", with: "'")   // ʼ → '
            }
            .flatMap { $0.split(whereSeparator: { $0.isWhitespace }).map(String.init) }
        var out = ""
        for word in words {
            if out.isEmpty {
                out = word
            } else if out.hasSuffix("'") {
                out += word            // elision: glue to the previous token, no space
            } else {
                out += " " + word
            }
        }
        return out
    }

    /// Lowercases, trims, collapses internal whitespace, and unifies curly/straight
    /// apostrophes. Does NOT strip diacritics — accent spelling must be correct.
    static func normalize(_ s: String) -> String {
        let unified = s
            .replacingOccurrences(of: "\u{2019}", with: "'")   // ’ → '
            .replacingOccurrences(of: "\u{02BC}", with: "'")   // ʼ → '
        return unified
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
            .lowercased()
    }
}

#if DEBUG
extension DrillEngine {
    static func _selfTest() {
        let ex = Exercise.sample            // answerTokens == ["est","parti"]
        assert(check(ex.answerTokens, ex), "exact match must pass")
        assert(!check(Array(ex.answerTokens.reversed()), ex), "wrong order must fail")
        assert(!check(ex.answerTokens + ["x"], ex), "extra token must fail")
        assert(!check(Array(ex.answerTokens.dropLast()), ex), "missing token must fail")
        assert(ex.resolvedInputMode != .buildFromTokens
               || isAnswerPlusExtra(ex.answerTokens + ["x"], ex), "answer + extra gets no retry")
        assert(!check([], ex), "empty must fail")
        // single-token (multiple-choice style) exact match
        let mc = Exercise(id: "t", elementID: "t", type: .conjugate, prompt: "p",
                          cue: nil, answerTokens: ["sont allés"],
                          tokenBank: ["sont allés","ont allés"],
                          inputMode: .multipleChoice, explanation: "e")
        assert(check(["sont allés"], mc), "mc correct must pass")
        assert(!check(["ont allés"], mc), "mc wrong must fail")

        // build mode: the learner never produces bare punctuation, so grading
        // ignores it — the punctuation-free word sequence is the correct answer.
        let punc = Exercise(id: "punc", elementID: "t", type: .wordOrder, prompt: "p",
                            cue: nil,
                            answerTokens: ["Non", ",", "je", "ne", "mange", "pas"],
                            tokenBank: ["Non", ",", "je", "ne", "mange", "pas", "tu"],
                            inputMode: .buildFromTokens, explanation: "e")
        assert(check(["Non", "je", "ne", "mange", "pas"], punc),
               "build grades the punctuation-free production as correct")
        assert(!check(["Non", ",", "je", "ne", "mange", "pas"], punc),
               "a literal punctuation token is never required")

        // build mode: a multi-word chip grades identically to its separate parts —
        // both produce the same ordered surface sentence (real bug: the "à la"
        // distractor chip was marked wrong though the sentence was correct).
        let combo = Exercise(id: "combo", elementID: "t", type: .wordOrder, prompt: "p",
                             cue: nil,
                             answerTokens: ["Elle", "n'", "est", "pas", "à", "la", "maison"],
                             tokenBank: ["Elle", "n'", "est", "pas", "à", "la", "maison", "à la"],
                             inputMode: .buildFromTokens, explanation: "e")
        assert(check(["Elle", "n'", "est", "pas", "à la", "maison"], combo),
               "a combined 'à la' chip must grade the same as 'à'+'la'")
        assert(check(["Elle", "n'", "est", "pas", "à", "la", "maison"], combo),
               "the separate-parts build still passes")
        assert(!check(["Elle", "est", "n'", "pas", "à", "la", "maison"], combo),
               "wrong word order still fails on surface")

        // build mode: an elision token ("N'") glues to the next word with no space,
        // so the combined "N'es-tu" distractor chip grades the same as the split
        // "N'"+"es-tu" answer (real bug: "N'es-tu pas content" built from the
        // combined chip was marked wrong because the surface kept a stray space).
        let elision = Exercise(id: "elision", elementID: "t", type: .wordOrder, prompt: "p",
                               cue: nil,
                               answerTokens: ["N'", "es-tu", "pas", "content"],
                               tokenBank: ["N'", "es-tu", "pas", "content", "N'es-tu", "contente"],
                               inputMode: .buildFromTokens, explanation: "e")
        assert(check(["N'es-tu", "pas", "content"], elision),
               "a combined elision chip grades the same as split 'N'' + 'es-tu'")
        assert(check(["N'", "es-tu", "pas", "content"], elision),
               "the separate-parts elision build still passes")
        assert(!check(["es-tu", "N'", "pas", "content"], elision),
               "wrong elision order still fails on surface")

        // second try: the leading run of right tiles, by surface.
        let pre = Exercise(id: "pre", elementID: "t", type: .wordOrder, prompt: "p",
                           cue: nil,
                           answerTokens: ["Elle", "n'", "est", "pas", "à", "la", "maison", "."],
                           tokenBank: ["Elle", "n'", "est", "pas", "à", "la", "maison", "à la", "."],
                           inputMode: .buildFromTokens, explanation: "e")
        assert(correctPrefixCount(["Elle", "est", "n'", "pas"], pre) == 1, "stops at first wrong tile")
        assert(correctPrefixCount(["Elle", "n'", "est", "pas", "à la", "chez"], pre) == 5,
               "a multi-word chip counts as its parts")
        assert(correctPrefixCount(["est", "Elle"], pre) == 0, "wrong first tile keeps nothing")
        assert(correctPrefixCount([], pre) == 0, "empty keeps nothing")
        assert(correctPrefixCount(["N'", "es-tu"], elision) == 2, "split elision counts once glued")

        // spot the error: right only when the replacement restores the sentence.
        let spot = Exercise(id: "spot", elementID: "t", type: .fillBlank, prompt: "p",
                            cue: nil, answerTokens: ["Je", "la", "vois"], tokenBank: [],
                            inputMode: .spotError, explanation: "e",
                            spot: SpotError(tokens: ["Je", "lui", "vois"], wrongIndex: 1,
                                            options: ["la", "leur", "les"]))
        assert(spot.resolvedInputMode == .spotError, "spot drills never shuffle into typing")
        assert(check(["Je", "la", "vois"], spot), "right fix passes")
        assert(!check(["Je", "les", "vois"], spot), "wrong fix fails")

        // free-text: accent-strict, but case / whitespace / apostrophe lenient.
        let ft = Exercise(id: "ft", elementID: "t", type: .fillBlank, prompt: "p",
                          cue: nil, answerTokens: ["café"], tokenBank: [],
                          inputMode: .freeText, explanation: "e")
        assert(check(["café"], ft), "exact typed must pass")
        assert(check(["  Café "], ft), "case + surrounding space must pass")
        assert(!check(["cafe"], ft), "missing accent must fail (accent-strict)")
        assert(!check([], ft), "empty typed must fail")
        let ap = Exercise(id: "ap", elementID: "t", type: .fillBlank, prompt: "p",
                          cue: nil, answerTokens: ["l'eau"], tokenBank: [],
                          inputMode: .freeText, explanation: "e")
        assert(check(["l\u{2019}eau"], ap), "curly apostrophe must match straight")
        assert(check(["l'eau"], ap), "straight apostrophe must pass")

        // typeBit: deterministic, and not all-one-value across distinct ids.
        assert(Exercise.typeBit("ft") == Exercise.typeBit("ft"), "typeBit stable")
        let ids = (0..<200).map { "id-\($0)" }
        let trues = ids.filter { Exercise.typeBit($0) }.count
        assert(trues > 40 && trues < 160, "typeBit should split, got \(trues)/200")

        // typeability guard: substantial words type; elisions / particles stay picked.
        assert(Exercise.isTypeable(["café"]), "real word is typeable")
        assert(Exercise.isTypeable(["est"]), "3-letter word is typeable")
        assert(Exercise.isTypeable(["l'eau"]), "mid-word apostrophe is typeable")
        assert(!Exercise.isTypeable(["n'"]), "bare elision must stay picked")
        assert(!Exercise.isTypeable(["de"]), "2-char particle must stay picked")
        assert(!Exercise.isTypeable(["n'", "est"]), "elision token must stay picked")

        // HARD RULE: never make a learner type punctuation — answers carrying
        // . , ? ! etc. are barred from the typing shuffle (stay picked).
        assert(!Exercise.isTypeable(["Tu aimes le café?"]), "trailing ? must stay picked")
        assert(!Exercise.isTypeable(["Oui, je la vois"]), "inner comma must stay picked")
        assert(!Exercise.isTypeable(["À midi."]), "trailing period must stay picked")
        assert(Exercise.isTypeable(["va-t-il"]), "intra-word hyphen still typeable")
    }
}
#endif
