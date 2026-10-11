#if DEBUG
import Foundation

/// Test book content contract for the Book 2 dialogue pilot (design rework,
/// 2026-10-11). Short café dialogues, 1–2 drills each, six drill types. Not
/// loaded by the production book loader and never writes review status.
struct PilotContent: Decodable {
    /// Normalised French word or set phrase → English. Tap-to-show only.
    let glossary: [String: String]
    let dialogues: [PilotDialogue]

    /// Content mistakes that would make a dialogue unfair or unplayable.
    var validationErrors: [String] {
        var errors: [String] = []
        if Set(dialogues.map(\.id)).count != dialogues.count { errors.append("duplicate dialogue id") }
        for dialogue in dialogues {
            errors += dialogue.validationErrors.map { "\(dialogue.id): \($0)" }
            for word in dialogue.newWords where glossary[word] == nil {
                errors.append("\(dialogue.id): new word '\(word)' has no gloss")
            }
        }
        return errors
    }
}

struct PilotDialogue: Decodable, Identifiable {
    struct Turn: Decodable {
        struct ErrorMark: Decodable {
            let word: String
            let fix: String
            let choices: [String]
            /// English reason shown after a wrong fix.
            let why: String?
        }
        /// "server" or "learner". Any non-learner voice counts as "server".
        let speaker: String
        /// Cast name shown above a server bubble ("Karim", "Léa"). Nil → "Serveur".
        let name: String?
        /// Transformer: the learner's earlier line, shown grey, to rewrite.
        let source: Bool?
        /// One line may hold a `___` gap (Compléter, Mot en retour).
        let text: String
        /// Learner line with one wrong word (Corriger).
        let error: ErrorMark?

        var isLearner: Bool { speaker == "learner" }
        var isSource: Bool { source == true }
    }

    let id: String
    let element: String
    let cue: String
    let turns: [Turn]
    let drills: [PilotDrill]
    /// Server's closing line. Standalone drills have none.
    let followUp: String?
    /// Who says the follow-up; defaults to the first named server turn.
    let followUpBy: String?
    /// Label above the cue: place or channel ("Au café", "Texto · Léa").
    let place: String?
    /// Standalone sentence drill label ("Transformer", "Mot en retour"…).
    /// Nil for a dialogue.
    let standalone: String?
    let newWords: [String]

    var isStandalone: Bool { standalone != nil }
    var followUpSpeaker: String? { followUpBy ?? turns.first { !$0.isLearner && $0.name != nil }?.name }

    var gapTurnIndex: Int? { turns.firstIndex { $0.text.contains("___") } }
    var errorTurnIndex: Int? { turns.firstIndex { $0.error != nil } }

    var validationErrors: [String] {
        var errors: [String] = []
        if id.isEmpty || element.isEmpty || cue.isEmpty { errors.append("missing required text") }
        if isStandalone {
            if followUp != nil { errors.append("standalone drill has no follow-up") }
            if turns.count > 2 || drills.count != 1 { errors.append("standalone needs 0–2 lines and one drill") }
        } else {
            if (followUp ?? "").isEmpty { errors.append("dialogue needs a follow-up") }
            if turns.isEmpty || turns.count > 3 { errors.append("dialogue needs 1–3 lines") }
        }
        if turns.contains(where: { !["server", "learner"].contains($0.speaker) || $0.text.isEmpty }) {
            errors.append("bad turn")
        }
        if turns.contains(where: { PilotText.wordCount($0.text) > 10 }) { errors.append("line over 10 words") }
        if drills.isEmpty || drills.count > 2 { errors.append("dialogue needs 1–2 drills") }
        let types = drills.map(\.type)
        if Set(types).count != types.count { errors.append("repeated drill type") }
        if types.contains(.reply) && types.contains(.pick) { errors.append("reply and pick both fill the reply bubble") }
        if types.contains(.complete) != (gapTurnIndex != nil) { errors.append("complete drill needs exactly one gap line") }
        if types.contains(.fix) != (errorTurnIndex != nil) { errors.append("fix drill needs exactly one error line") }
        if let i = errorTurnIndex, let mark = turns[i].error {
            if !turns[i].isLearner { errors.append("error must sit in a learner line") }
            if !PilotText.tokens(turns[i].text).map(PilotText.norm).contains(PilotText.norm(mark.word)) {
                errors.append("error word not in its line")
            }
            if !mark.choices.contains(mark.fix) { errors.append("fix missing from its choices") }
        }
        for drill in drills { errors += drill.validationErrors }
        return errors
    }
}

struct PilotDrill: Decodable {
    enum Kind: String, Decodable {
        case comprehend, reply, pick, complete, fix, word

        /// Learner-facing French name.
        var title: String {
            switch self {
            case .comprehend: return "Comprendre"
            case .reply: return "Répondre"
            case .pick: return "Choisir"
            case .complete: return "Compléter"
            case .fix: return "Corriger"
            case .word: return "Mot"
            }
        }
    }

    let type: Kind
    /// English question or goal.
    let prompt: String
    let choices: [String]?
    let correct: Int?
    /// English why-line per wrong choice ("" for the right one).
    let why: [String]?
    /// English note after a first miss.
    let miss: String?
    let bank: [String]?
    let accepted: [[String]]?
    let model: String?
    /// Mot: the normalised glossary key to highlight.
    let target: String?

    func accepts(_ tiles: [String]) -> Bool {
        accepted?.contains(tiles) ?? false
    }

    /// Longest start of `tiles` that also starts some accepted reply. A wrong
    /// reply keeps this part placed for the second try (Book 1 pattern).
    func correctPrefixCount(_ tiles: [String]) -> Int {
        (accepted ?? []).map { reply in
            zip(tiles, reply).prefix { $0 == $1 }.count
        }.max() ?? 0
    }

    var validationErrors: [String] {
        var errors: [String] = []
        if prompt.isEmpty { errors.append("\(type.rawValue): missing prompt") }
        switch type {
        case .comprehend, .word, .pick, .complete:
            let need = type == .comprehend ? 2 : 3
            guard let choices, choices.count == need, Set(choices).count == need else {
                errors.append("\(type.rawValue): needs \(need) distinct choices"); break
            }
            if !(correct.map(choices.indices.contains) ?? false) { errors.append("\(type.rawValue): correct out of range") }
            if type == .pick || type == .complete {
                if why?.count != need { errors.append("\(type.rawValue): needs a why-line per choice") }
            }
            if type == .word && (target ?? "").isEmpty { errors.append("word: missing target") }
        case .reply:
            guard let bank, let accepted, !accepted.isEmpty, let model, !model.isEmpty else {
                errors.append("reply: missing bank, accepted, or model"); break
            }
            if accepted.contains(where: { $0.isEmpty || !Self.isSubset($0, of: bank) }) {
                errors.append("reply: accepted reply cannot be built from bank")
            }
            if !accepted.map({ $0.joined(separator: " ") }).contains(model) {
                errors.append("reply: model is not an accepted reply")
            }
        case .fix:
            break
        }
        return errors
    }

    static func isSubset(_ answer: [String], of bank: [String]) -> Bool {
        var remaining = bank
        for chunk in answer {
            guard let index = remaining.firstIndex(of: chunk) else { return false }
            remaining.remove(at: index)
        }
        return true
    }
}

/// Splits a line into tappable words and set phrases.
enum PilotText {
    struct Segment: Equatable {
        enum Kind: Equatable { case word, gap }
        let index: Int
        /// Text as shown (without trailing punctuation for glossed words).
        let display: String
        /// Trailing punctuation shown after the word.
        let trailing: String
        /// Glossary key, if any.
        let key: String?
        let kind: Kind
    }

    static func tokens(_ text: String) -> [String] {
        text.split(separator: " ").map(String.init)
    }

    static func wordCount(_ text: String) -> Int {
        tokens(text).filter { !norm($0).isEmpty }.count
    }

    /// Lowercased, typographic apostrophe → straight, punctuation stripped.
    static func norm(_ word: String) -> String {
        word.lowercased()
            .replacingOccurrences(of: "’", with: "'")
            .trimmingCharacters(in: CharacterSet(charactersIn: ".,!?;:«»… "))
    }

    /// Longest glossary phrase first, so « un quart d'heure » wins over « un ».
    /// `keepApart` is a Corriger error word that no multi-word phrase may swallow.
    static func segments(_ text: String, glossary: [String: String], keepApart: String? = nil) -> [Segment] {
        let toks = tokens(text)
        let apart = keepApart.map(norm)
        let phrases = glossary.keys
            .map { $0.split(separator: " ").map(String.init) }
            .filter { p in p.count == 1 || apart == nil || !p.contains(apart!) }
            .sorted { $0.count > $1.count }
        var out: [Segment] = []
        var i = 0
        while i < toks.count {
            if toks[i].hasPrefix("___") {
                out.append(Segment(index: out.count, display: "", trailing: String(toks[i].dropFirst(3)),
                                   key: nil, kind: .gap))
                i += 1
                continue
            }
            // French spaced punctuation (« ? », « ! ») rides on the word before
            // with a no-break space, so it never wraps onto a line of its own.
            if norm(toks[i]).isEmpty, let last = out.popLast() {
                out.append(Segment(index: last.index, display: last.display,
                                   trailing: last.trailing + "\u{00A0}" + toks[i], key: last.key, kind: last.kind))
                i += 1
                continue
            }
            let hit = phrases.first { p in
                i + p.count <= toks.count && p.enumerated().allSatisfy { norm(toks[i + $0.offset]) == $0.element }
            }
            let len = hit?.count ?? 1
            let raw = toks[i..<(i + len)].joined(separator: " ")
            let (body, trail) = splitTrailing(raw)
            let key = hit?.joined(separator: " ")
            out.append(Segment(index: out.count, display: key == nil ? raw : body,
                               trailing: key == nil ? "" : trail, key: key, kind: .word))
            i += len
        }
        return out
    }

    private static func splitTrailing(_ raw: String) -> (String, String) {
        var body = raw
        var trail = ""
        while let last = body.last, ".,!?;:".contains(last) {
            trail = String(last) + trail
            body.removeLast()
        }
        return (body, trail)
    }
}
#endif
