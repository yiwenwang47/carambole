import Foundation

/// Spaced-repetition learning state for a review item.
enum LearningState: String, Codable {
    case new
    case learning
    case learned
}

/// Persisted progress for ONE `GrammarElement` (not per example sentence). Carries
/// both the SRS schedule (for the Réviser queue) and the mastery counters (for the
/// module-unlock gate). One row per element in `review_status`.
struct ReviewStatus: Codable {
    let elementID: String
    var learningState: LearningState
    var lastReviewDate: Date?
    var nextReviewDate: Date?
    var intervalDays: Int

    /// Distinct example sentences answered correctly for this element. Drives the
    /// mastery gate (`distinctCorrect >= masteryThreshold` ⇒ element mastered).
    /// Always equals `masteredExampleIDs.count`.
    var distinctCorrect: Int
    /// The set of example ids answered correctly, so distinctness survives restarts.
    var masteredExampleIDs: Set<String>
    /// "Too easy" — suspended from the new + review queues (see DrillSessionView).
    var suspended: Bool

    // MARK: FSRS memory-strength state (added in the v4 schema migration)

    /// FSRS stability `S` (days) — the memory-strength half of the `(S, D)` pair that
    /// replaces the count gate. `nil` until the element's first FSRS grade (T3). Once
    /// set, scheduling + the maîtrisé bar derive from it (see `Core/FSRS.swift`).
    var stability: Double?
    /// FSRS difficulty `D` (1–10) — how hard the element is to retain. `nil` until the
    /// first FSRS grade, then drifts per rating.
    var difficulty: Double?
    /// Sticky "maîtrisé" flag: the day the element FIRST graduated (`S` crossed the
    /// 21-day bar via a spaced success, or a "too easy" skip). Non-nil ⇒ graduated;
    /// monotonic — decay never un-sets it (forgetting surfaces as "fragile" instead).
    var graduatedDate: Date?

    init(elementID: String, learningState: LearningState = .new, intervalDays: Int = 0) {
        self.elementID = elementID
        self.learningState = learningState
        self.lastReviewDate = nil
        self.nextReviewDate = nil
        self.intervalDays = intervalDays
        self.distinctCorrect = 0
        self.masteredExampleIDs = []
        self.suspended = false
        self.stability = nil
        self.difficulty = nil
        self.graduatedDate = nil
    }

    /// Record a correct answer for `exampleID`, bumping distinct-correct if new.
    mutating func recordCorrect(exampleID: String) {
        masteredExampleIDs.insert(exampleID)
        distinctCorrect = masteredExampleIDs.count
    }
}

// Scheduling now lives in the FSRS path: `DrillSessionView.gradeElement` advances the
// `(stability, difficulty)` pair via `Core/FSRS.swift` and writes `nextReviewDate` from
// `FSRS.intervalDays`. The legacy `SRSScheduler.grade`/`.fresh` ladder is no longer on
// the grading path (kept only for its `_selfTest`; dead code, slated for cleanup). Do
// not add ad-hoc date logic here.
