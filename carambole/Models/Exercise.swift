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
    /// English translation of the whole prompt sentence (always-on, subtle).
    let translation: String?
    /// Short English grammar nudge, revealed on tap.
    let hint: String?

    /// Memberwise initializer with `translation`/`hint` defaulted last so existing
    /// call sites keep compiling. Codable's synthesized `init(from:)` is unaffected
    /// (absent JSON keys decode the optionals to `nil`).
    init(
        id: String,
        topicID: String,
        type: ExerciseType,
        prompt: String,
        cue: String?,
        answerTokens: [String],
        tokenBank: [String],
        inputMode: InputMode,
        explanation: String,
        translation: String? = nil,
        hint: String? = nil
    ) {
        self.id = id
        self.topicID = topicID
        self.type = type
        self.prompt = prompt
        self.cue = cue
        self.answerTokens = answerTokens
        self.tokenBank = tokenBank
        self.inputMode = inputMode
        self.explanation = explanation
        self.translation = translation
        self.hint = hint
    }

    static let sample = Exercise(
        id: "exercise-sample",
        topicID: "topic-sample",
        type: .conjugate,
        prompt: "Il ___ (partir) hier.",
        cue: "partir",
        answerTokens: ["est", "parti"],
        tokenBank: ["a", "est", "parti", "partie", "partait"],
        inputMode: .buildFromTokens,
        explanation: "Partir uses être in the passé composé, and the past participle agrees with the subject.",
        translation: "He left yesterday.",
        hint: "'partir' takes être; match the participle to the subject."
    )
}
