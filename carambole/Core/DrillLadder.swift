import Foundation

/// Which form of a drill to serve: the authored one, or the easier spot-the-error
/// form of the same sentence (when the example carries `spot` data).
///
/// Second-language practice works best when the effort matches how well a rule is
/// held: notice and fix while it is shaky, produce once it holds. So:
/// - a retry after a miss in this session → spot (a step down, same rule);
/// - a just-lapsed element (FSRS stability < 1 day) → spot;
/// - a young element (stability < 3 days) → spot one time in three, for variety;
/// - first meeting (no FSRS state yet) and anything stable → the authored drill.
/// See docs/plans/2026-10-10-drill-types-design.md.
enum DrillLadder {
    static let lapsedStability = 1.0
    static let youngStability = 3.0

    static func present(_ exercise: Exercise, stability: Double?, missedInSession: Bool,
                        roll: Double = Double.random(in: 0..<1)) -> Exercise {
        guard let spot = exercise.spotVariant else { return exercise }
        if missedInSession { return spot }
        guard let s = stability else { return exercise }
        if s < lapsedStability { return spot }
        if s < youngStability && roll < 1.0 / 3.0 { return spot }
        return exercise
    }
}

#if DEBUG
extension DrillLadder {
    static func _selfTest() {
        let plain = Exercise.sample
        let spotted = Exercise(id: "lad", elementID: "e", type: .wordOrder, prompt: "Construis : « I see her. »",
                               cue: nil, answerTokens: ["Je", "la", "vois"],
                               tokenBank: ["Je", "la", "vois", "lui", "le"], inputMode: .buildFromTokens,
                               explanation: "e",
                               spot: SpotError(tokens: ["Je", "lui", "vois"], wrongIndex: 1,
                                               options: ["la", "leur", "leurs"]))
        func mode(_ ex: Exercise) -> InputMode { ex.resolvedInputMode }
        assert(present(plain, stability: 0.1, missedInSession: true).id == plain.id,
               "no spot data → always the authored drill")
        assert(mode(present(spotted, stability: nil, missedInSession: false)) == .buildFromTokens,
               "first meeting produces")
        assert(mode(present(spotted, stability: nil, missedInSession: true)) == .spotError,
               "retry after a miss steps down")
        assert(mode(present(spotted, stability: 0.5, missedInSession: false)) == .spotError,
               "lapsed → spot")
        assert(mode(present(spotted, stability: 2, missedInSession: false, roll: 0.1)) == .spotError,
               "young, low roll → spot")
        assert(mode(present(spotted, stability: 2, missedInSession: false, roll: 0.9)) == .buildFromTokens,
               "young, high roll → authored")
        assert(mode(present(spotted, stability: 30, missedInSession: false, roll: 0)) == .buildFromTokens,
               "stable → authored")
        let v = spotted.spotVariant!
        assert(v.id == "lad~spot" && v.answerTokens == ["Je", "la", "vois"] && v.elementID == "e",
               "variant restores the sentence and keeps the element")
        let noted = Exercise(id: "n", elementID: "e", type: .conjugate,
                             prompt: "Complète (une femme parle) : « Je suis ___ . » (aller)",
                             cue: nil, answerTokens: ["allée"], tokenBank: ["allée", "allé"],
                             inputMode: .multipleChoice, explanation: "e",
                             spot: SpotError(tokens: ["Je", "suis", "allées", "."], wrongIndex: 2,
                                             options: ["allée", "allés"]))
        assert(noted.spotVariant?.cue == "une femme parle · aller",
               "spot keeps the prompt's bracketed notes")
    }
}
#endif
