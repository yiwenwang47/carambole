#if DEBUG
import Foundation

/// A deliberately small Test book content contract. It is not loaded by the
/// production book loader and does not write review status.
struct PilotScenario: Decodable, Identifiable {
    struct Turn: Decodable {
        let speaker: String
        let text: String
    }

    let id: String
    let context: String
    let turns: [Turn]
    let question: String
    let choices: [String]
    let correctChoice: Int
    let responsePrompt: String
    let replyTokens: [String]
    let tokenBank: [String]
    let acceptedReplies: [[String]]
    let modelReply: String
    let followUp: String
    let explanationEN: String

    func accepts(_ chunks: [String]) -> Bool {
        acceptedReplies.contains(chunks)
    }

    func replyText(_ chunks: [String]) -> String {
        chunks.joined(separator: " ")
    }

    /// Check content mistakes before a pilot reaches a device. In particular,
    /// every accepted reply must be buildable from the offered chip multiset.
    var validationErrors: [String] {
        var errors: [String] = []
        if id.isEmpty || context.isEmpty || question.isEmpty || responsePrompt.isEmpty
            || modelReply.isEmpty || followUp.isEmpty || explanationEN.isEmpty {
            errors.append("missing required text")
        }
        if turns.count < 2 || turns.contains(where: { $0.speaker.isEmpty || $0.text.isEmpty }) {
            errors.append("dialogue needs at least two complete turns")
        }
        if Set(turns.map(\.speaker)).count < 2 {
            errors.append("dialogue needs two speakers")
        }
        if choices.count != 3 || choices.contains(where: \.isEmpty) {
            errors.append("listening question needs three choices")
        }
        if !choices.indices.contains(correctChoice) {
            errors.append("correctChoice out of range")
        }
        if replyTokens.isEmpty || acceptedReplies.isEmpty || !acceptedReplies.contains(replyTokens) {
            errors.append("canonical reply missing from acceptedReplies")
        }
        if acceptedReplies.contains(where: { $0.isEmpty || !Self.isSubset($0, of: tokenBank) }) {
            errors.append("accepted reply cannot be built from tokenBank")
        }
        return errors
    }

    private static func isSubset(_ answer: [String], of bank: [String]) -> Bool {
        var remaining = bank
        for chunk in answer {
            guard let index = remaining.firstIndex(of: chunk) else { return false }
            remaining.remove(at: index)
        }
        return true
    }
}
#endif
