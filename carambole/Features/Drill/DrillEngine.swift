import Foundation

struct DrillEngine {
    /// Exact, order-sensitive token match.
    static func check(_ submitted: [String], _ exercise: Exercise) -> Bool {
        submitted == exercise.answerTokens
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
        assert(!check([], ex), "empty must fail")
        // single-token (multiple-choice style) exact match
        let mc = Exercise(id: "t", elementID: "t", type: .conjugate, prompt: "p",
                          cue: nil, answerTokens: ["sont allés"],
                          tokenBank: ["sont allés","ont allés"],
                          inputMode: .multipleChoice, explanation: "e")
        assert(check(["sont allés"], mc), "mc correct must pass")
        assert(!check(["ont allés"], mc), "mc wrong must fail")
    }
}
#endif
