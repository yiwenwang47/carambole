import Foundation

/// Pure spaced-repetition scheduling logic. Grades a review answer and computes
/// the next interval / learning state up a fixed spacing ladder. No persistence,
/// no UI — see `DataManager` for storage and `DrillSessionView` for the call site.
struct SRSScheduler {
    /// Spacing ladder in days.
    static let intervals = [1, 3, 7, 16, 35]

    /// Grade a review. `pass` = answered correctly.
    /// pass → advance to the next interval up the ladder (cap at the top = .learned);
    /// fail → reset to 1 day and .learning.
    static func grade(_ status: ReviewStatus, pass: Bool, now: Date) -> ReviewStatus {
        let newInterval: Int
        let newState: LearningState
        if pass {
            newInterval = intervals.first(where: { $0 > status.intervalDays }) ?? intervals.last!
            newState = (newInterval == intervals.last!) ? .learned : .learning
        } else {
            newInterval = intervals.first!      // 1
            newState = .learning
        }
        let next = Calendar.current.date(byAdding: .day, value: newInterval, to: now) ?? now

        // Mutate a COPY so mastery counters (`distinctCorrect` /
        // `masteredExampleIDs`) and `suspended` carry through — only the SRS
        // schedule fields change here.
        var result = status
        result.learningState = newState
        result.intervalDays = newInterval
        result.lastReviewDate = now
        result.nextReviewDate = next
        return result
    }

    /// A fresh status for an element never reviewed.
    static func fresh(_ elementID: String) -> ReviewStatus {
        ReviewStatus(elementID: elementID, learningState: .new, intervalDays: 0)
    }
}

#if DEBUG
extension SRSScheduler {
    static func _selfTest() {
        let now = Date()
        var s = fresh("x")
        s = grade(s, pass: true, now: now);  assert(s.intervalDays == 1 && s.learningState == .learning)
        s = grade(s, pass: true, now: now);  assert(s.intervalDays == 3)
        s = grade(s, pass: true, now: now);  assert(s.intervalDays == 7)
        s = grade(s, pass: true, now: now);  assert(s.intervalDays == 16)
        s = grade(s, pass: true, now: now);  assert(s.intervalDays == 35 && s.learningState == .learned)
        s = grade(s, pass: true, now: now);  assert(s.intervalDays == 35, "stays capped")
        s = grade(s, pass: false, now: now); assert(s.intervalDays == 1 && s.learningState == .learning, "fail resets")
        assert(s.nextReviewDate != nil)
    }
}
#endif
