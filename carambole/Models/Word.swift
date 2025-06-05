import Foundation

enum LearningState: String, Codable {
    case new
    case learning
    case learned
}

struct Word: Identifiable, Codable, Equatable {
    let id: String
    let text: String
    let definition: String?
    let exampleSentence: String?
    var learningState: LearningState
    
    init(id: String = UUID().uuidString,
         text: String,
         definition: String? = nil,
         exampleSentence: String? = nil,
         learningState: LearningState = .new) {
        self.id = id
        self.text = text
        self.definition = definition
        self.exampleSentence = exampleSentence
        self.learningState = learningState
    }
    
    static func == (lhs: Word, rhs: Word) -> Bool {
        lhs.id == rhs.id
    }
}
