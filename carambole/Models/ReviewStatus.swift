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

    init(elementID: String, learningState: LearningState = .new, intervalDays: Int = 0) {
        self.elementID = elementID
        self.learningState = learningState
        self.lastReviewDate = nil
        self.nextReviewDate = nil
        self.intervalDays = intervalDays
        self.distinctCorrect = 0
        self.masteredExampleIDs = []
        self.suspended = false
    }

    /// Record a correct answer for `exampleID`, bumping distinct-correct if new.
    mutating func recordCorrect(exampleID: String) {
        masteredExampleIDs.insert(exampleID)
        distinctCorrect = masteredExampleIDs.count
    }
}

// Scheduling lives in `SRSScheduler.grade(_:pass:now:)` — the single source of
// truth for intervals + state transitions. Do not add ad-hoc date logic here.
