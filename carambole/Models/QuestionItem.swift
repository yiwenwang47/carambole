import Foundation

struct QuestionItem: Identifiable {
    let id: String
    let prompt: String?
    let options: [String]?
    let correctAnswer: String?
    
    init(id: String = UUID().uuidString, prompt: String?, options: [String]?, correctAnswer: String?) {
        self.id = id
        self.prompt = prompt
        self.options = options
        self.correctAnswer = correctAnswer
    }
}
