import Foundation

/// Spaced-repetition learning state for a review item.
enum LearningState: String, Codable {
    case new
    case learning
    case learned
}

struct ReviewStatus: Codable {
    let exerciseID: String
    var learningState: LearningState
    var lastReviewDate: Date?
    var nextReviewDate: Date?
    var intervalDays: Int

    init(exerciseID: String, learningState: LearningState = .new, intervalDays: Int = 0) {
        self.exerciseID = exerciseID
        self.learningState = learningState
        self.lastReviewDate = nil
        self.nextReviewDate = nil
        self.intervalDays = intervalDays
    }
}

// Scheduling lives in `SRSScheduler.grade(_:pass:now:)` — the single source of
// truth for intervals + state transitions. Do not add ad-hoc date logic here.
