import Foundation

/// The kind of study session. A Core-owned enum so the pure `LearnLoop` decision
/// never reaches up into the SwiftUI layer; `DrillSessionView.Mode` is a typealias
/// to this.
enum SessionMode { case learn, review }

/// Pure decision for the drill session's "what comes next" step. Extracted from
/// `DrillSessionView` so the introduce-style learn loop is unit-testable in isolation
/// (the SwiftUI view is not).
///
/// ## Why this exists (the loop reshape)
/// Under FSRS an element can NOT graduate inside one session — graduation needs spaced
/// successes across days (see `Core/FSRS.swift`). The old rule
/// `isMastered ? .nextElement : .nextExample` (mastery = `distinctCorrect >= 3`) would
/// therefore loop a single element FOREVER in `.learn`, since the in-session distinct
/// count is irrelevant to FSRS graduation. The new rule treats Apprendre as an
/// INTRODUCTION: meet the element once (a correct answer = "seen", it now has FSRS
/// state and counts en-cours), then move on. Depth/graduation is Réviser's job.
enum LearnLoop {
    /// What the session should do after grading the current live drill.
    /// - `.nextExample` — stay on the current element, present another example.
    /// - `.nextElement` — advance to the next element (or finish).
    enum NextAction { case nextExample, nextElement }

    /// Decide the next step.
    /// - In `.review`: always advance — one fresh example per due element.
    /// - In `.learn`:
    ///   - **correct** → advance to the next element. The element is now introduced
    ///     (it carries FSRS state = en-cours); breadth over in-session depth. This is
    ///     what guarantees the loop terminates: any single correct answer advances.
    ///   - **wrong** → stay and retry with another example. Bounded by the learner
    ///     eventually answering one correctly; `DrillSessionView.buildQueue`/
    ///     `presentNextExample` refill/cycle the example pool, so a never-correct
    ///     element can't run out of examples and soft-lock.
    static func nextAction(mode: SessionMode, correct: Bool) -> NextAction {
        switch mode {
        case .review:
            return .nextElement
        case .learn:
            return correct ? .nextElement : .nextExample
        }
    }
}

#if DEBUG
extension LearnLoop {
    static func _selfTest() {
        // Review: always advance, regardless of correctness.
        assert(nextAction(mode: .review, correct: true)  == .nextElement, "review correct → next element")
        assert(nextAction(mode: .review, correct: false) == .nextElement, "review wrong → next element")

        // Learn: first correct introduces the element → advance (no infinite loop on
        // an element that can't graduate in-session).
        assert(nextAction(mode: .learn, correct: true)   == .nextElement, "learn correct → next element (introduced)")

        // Learn: wrong → stay on the element and retry another example.
        assert(nextAction(mode: .learn, correct: false)  == .nextExample, "learn wrong → next example (retry)")

        // Termination property: in learn mode, ANY correct answer advances, so a
        // session over N elements can present at most (retries + 1) cards per element
        // and always progresses on the first success. The only non-advancing branch is
        // (learn, wrong), which is the deliberate retry — never (learn, correct).
        assert(nextAction(mode: .learn, correct: true) != .nextExample,
               "learn correct must never repeat the same element")
    }
}
#endif
