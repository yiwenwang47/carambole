#if DEBUG
import Foundation

/// Small, disposable content shape for reviewing Book 3 cards in Test book.
/// Production Book 3 content and its review unit are deliberately undecided.
struct Book3PilotCard: Decodable, Identifiable {
    enum Format: String, Decodable, CaseIterable {
        case dialogue, microtext, rewrite, word

        var title: String {
            switch self {
            case .dialogue: return "Dialogue"
            case .microtext: return "Microtexte"
            case .rewrite: return "Réécrire"
            case .word: return "Mot en contexte"
            }
        }
    }

    struct SourceLine: Decodable {
        let speaker: String?
        let text: String
    }

    struct Response: Decodable {
        enum Kind: String, Decodable { case choices, typed }
        let kind: Kind
        let choices: [String]?
        let answer: String
        let accepted: [String]?
    }

    let id: String
    let format: Format
    let source: [SourceLine]
    let task: String
    let response: Response
    let feedback: String

    var validationErrors: [String] {
        var errors: [String] = []
        if id.isEmpty || source.isEmpty || source.contains(where: { $0.text.isEmpty }) ||
            task.isEmpty || feedback.isEmpty { errors.append("missing visible content") }
        if format == .dialogue && source.contains(where: { ($0.speaker ?? "").isEmpty }) {
            errors.append("dialogue line has no speaker")
        }
        if format != .dialogue && source.contains(where: { $0.speaker != nil }) {
            errors.append("non-dialogue line has speaker")
        }
        switch response.kind {
        case .choices:
            let choices = response.choices ?? []
            if choices.count != 3 || Set(choices).count != choices.count || !choices.contains(response.answer) {
                errors.append("choices need three distinct options including answer")
            }
            if response.accepted != nil { errors.append("choices have typed variants") }
        case .typed:
            if response.choices != nil { errors.append("typed response has choices") }
            let accepted = response.accepted ?? []
            if accepted.isEmpty || !accepted.contains(response.answer) {
                errors.append("typed answer missing from accepted forms")
            }
        }
        return errors
    }

    func accepts(_ candidate: String) -> Bool {
        let key = Self.normalized(candidate)
        switch response.kind {
        case .choices: return key == Self.normalized(response.answer)
        case .typed: return (response.accepted ?? []).contains { Self.normalized($0) == key }
        }
    }

    static func normalized(_ answer: String) -> String {
        var value = answer.precomposedStringWithCanonicalMapping
            .replacingOccurrences(of: "’", with: "'")
            .lowercased(with: Locale(identifier: "fr_FR"))
        value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        while let last = value.last, ".?!…".contains(last) { value.removeLast() }
        return value.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }
}
#endif
