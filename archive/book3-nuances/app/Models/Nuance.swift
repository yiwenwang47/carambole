import Foundation

struct NuanceModuleFile: Decodable, Identifiable, Equatable {
    let id: String
    let number: Int
    let title: String
    let goal: String
    let elements: [NuanceElement]
}

struct NuanceElement: Decodable, Identifiable, Equatable {
    let id: String
    let title: String
    let note: String
    let cards: [NuanceCard]
}

struct NuanceCard: Decodable, Identifiable, Equatable {
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

    struct SourceLine: Decodable, Equatable {
        let speaker: String?
        let text: String
    }

    struct Response: Decodable, Equatable {
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

    func accepts(_ candidate: String) -> Bool {
        let key = Self.normalized(candidate)
        switch response.kind {
        case .choices:
            return key == Self.normalized(response.answer)
        case .typed:
            return (response.accepted ?? []).contains { Self.normalized($0) == key }
        }
    }

    static func normalized(_ answer: String) -> String {
        var value = answer.precomposedStringWithCanonicalMapping
            .replacingOccurrences(of: "’", with: "'")
            .lowercased(with: Locale(identifier: "fr_FR"))
        value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        while let last = value.last, ".?!…".contains(last) {
            value.removeLast()
        }
        return value.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }
}

struct NuanceCardHistory: Equatable {
    let lastDone: Date
    let times: Int
    let lastRating: Int // 1 = again, 2 = hard, 3 = good
}

enum NuanceCardSelector {
    enum Mode { case learn, review }

    static func select(
        from cards: [NuanceCard],
        history: [String: NuanceCardHistory],
        limit: Int,
        mode: Mode
    ) -> [NuanceCard] {
        guard limit > 0 else { return [] }

        let missed = cards.filter { history[$0.id]?.lastRating == 1 }
        let unseen = cards.filter { history[$0.id] == nil }
        let eligibleUnseen = mode == .learn ? Array(unseen.prefix(3)) : unseen
        let oldest = cards.enumerated()
            .filter { history[$0.element.id] != nil && history[$0.element.id]?.lastRating != 1 }
            .sorted { left, right in
                let leftDate = history[left.element.id]!.lastDone
                let rightDate = history[right.element.id]!.lastDone
                return leftDate == rightDate ? left.offset < right.offset : leftDate < rightDate
            }
            .map(\.element)
        return Array((missed + eligibleUnseen + oldest).prefix(limit))
    }
}

enum NuanceMastery {
    static func gateMet(correctCardIDs: Set<String>, cards: [NuanceCard]) -> Bool {
        let correctCards = cards.filter { correctCardIDs.contains($0.id) }
        return Set(correctCards.map(\.id)).count >= 3 &&
            Set(correctCards.map(\.format)).count >= 2
    }
}
