import Foundation

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
    
    mutating func updateReviewDates() {
        lastReviewDate = Date()
        
        // Set next review date based on learning state
        switch learningState {
        case .new:
            nextReviewDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        case .learning:
            nextReviewDate = Calendar.current.date(byAdding: .day, value: 3, to: Date())
        case .learned:
            nextReviewDate = nil // No more reviews needed
        }
    }
}
