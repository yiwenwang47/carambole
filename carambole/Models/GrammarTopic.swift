import Foundation

struct GrammarTopic: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let sortOrder: Int
    let prerequisiteID: String?
    let ruleNote: String
    var exercises: [Exercise]

    static let sample = GrammarTopic(
        id: "topic-sample",
        title: "Passé composé with être",
        sortOrder: 0,
        prerequisiteID: nil,
        ruleNote: "A set of verbs of motion and state form the passé composé with être, and their past participle agrees with the subject.",
        exercises: [Exercise.sample]
    )
}
