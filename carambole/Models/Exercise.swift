import Foundation

enum ExerciseType: String, Codable {
    case conjugate
    case fillBlank
    case genderArticle
    case wordOrder
}

enum InputMode: String, Codable {
    case multipleChoice
    case buildFromTokens
}

struct Exercise: Identifiable, Codable, Equatable {
    let id: String
    let topicID: String
    let type: ExerciseType
    let prompt: String
    let cue: String?
    let answerTokens: [String]
    let tokenBank: [String]
    let inputMode: InputMode
    let explanation: String

    static let sample = Exercise(
        id: "exercise-sample",
        topicID: "topic-sample",
        type: .conjugate,
        prompt: "Il ___ (partir) hier.",
        cue: "partir",
        answerTokens: ["est", "parti"],
        tokenBank: ["a", "est", "parti", "partie", "partait"],
        inputMode: .buildFromTokens,
        explanation: "Partir uses être in the passé composé, and the past participle agrees with the subject."
    )
}
