import Foundation

struct ReviewStatus: Codable {
    let wordID: String
    var learningState: LearningState
    var lastReviewDate: Date?
    var nextReviewDate: Date?
    
    init(wordID: String, learningState: LearningState = .new) {
        self.wordID = wordID
        self.learningState = learningState
        self.lastReviewDate = nil
        self.nextReviewDate = nil
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
