import Foundation

//  Situation.swift
//  carambole
//
//  *En situation* (Book 2) content and the pure rules that drive it: decoding,
//  tappable-word segmentation, render-time choice shuffling, grading, the
//  dialogue rating, Réviser item selection and the mastery gate.
//
//  Foundation only, so `tools/situations/SituationModelTests.swift` can compile
//  this file on its own with swiftc. The JSON shape is documented in
//  `tools/situations/README.md`; the Test book pilot (`Debug/PilotScenario.swift`)
//  decodes the same dialogue fields.

// MARK: - Content

/// One `words.json` entry. `firstSeen == nil` marks a *Fondations* (base) word.
struct SituationWord: Decodable, Equatable {
    let fr: String
    let en: String
    let spoken: Bool
    let audio: String?
    let firstSeen: String?

    /// Tooltip English. Spoken forms carry a `* ` prefix (« je sais pas »
    /// → `* I don't know`).
    var tipText: String {
        guard spoken, !en.hasPrefix("* ") else { return en }
        return "* " + en
    }
}

/// One dialogue or standalone drill of a conversational move.
struct SituationItem: Decodable, Equatable, Identifiable {
    struct Turn: Decodable, Equatable {
        struct ErrorMark: Decodable, Equatable {
            let word: String
            let fix: String
            let choices: [String]
            /// English reason shown after a wrong fix.
            let why: String?
        }
        /// "server" or "learner".
        let speaker: String
        /// Cast name above a server bubble ("Karim"). Nil → "Serveur".
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
    let place: String?
    let cue: String
    let turns: [Turn]
    let drills: [SituationDrill]
    /// Server's closing line. Standalone drills have none.
    let followUp: String?
    let followUpBy: String?
    /// Standalone drill label ("Construire", "Corriger"…). Nil for a dialogue.
    let standalone: String?
    let newWords: [String]

    var isStandalone: Bool { standalone != nil }
    var followUpSpeaker: String? {
        followUpBy ?? turns.first { !$0.isLearner && $0.name != nil }?.name
    }
    var gapTurnIndex: Int? { turns.firstIndex { $0.text.contains("___") } }
    var errorTurnIndex: Int? { turns.firstIndex { $0.error != nil } }
    var errorMark: Turn.ErrorMark? { errorTurnIndex.flatMap { turns[$0].error } }
    var drillKinds: Set<SituationDrill.Kind> { Set(drills.map(\.type)) }

    /// Production audio keys (`tools/situations/README.md`): the whole item ID
    /// once, then `_t<turn>` or `_f`.
    func turnAudioKey(_ index: Int) -> String { "\(id)_t\(index)" }
    var followUpAudioKey: String { "\(id)_f" }

    /// Contract errors that would make the item unplayable. The Python linter
    /// is the full gate; this guards the view against a bad bundle.
    var validationErrors: [String] {
        var errors: [String] = []
        if id.isEmpty || cue.isEmpty { errors.append("missing id or cue") }
        if turns.contains(where: { !["server", "learner"].contains($0.speaker) || $0.text.isEmpty }) {
            errors.append("bad turn")
        }
        if drills.isEmpty || drills.count > 2 { errors.append("needs 1–2 drills") }
        let kinds = drills.map(\.type)
        if Set(kinds).count != kinds.count { errors.append("repeated drill type") }
        if kinds.contains(.reply) && kinds.contains(.pick) { errors.append("reply and pick together") }
        if kinds.contains(.complete) != (gapTurnIndex != nil) { errors.append("complete needs one gap") }
        if kinds.contains(.fix) {
            guard let mark = errorMark, mark.choices.contains(mark.fix) else {
                errors.append("fix needs an error mark with its fix among the choices")
                return errors
            }
        }
        for drill in drills { errors += drill.validationErrors }
        return errors.map { "\(id): \($0)" }
    }
}

struct SituationDrill: Decodable, Equatable {
    enum Kind: String, Decodable, CaseIterable {
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
    /// English why-line per choice ("" for the right one), in authored order.
    let why: [String]?
    /// English note after a first miss (Comprendre).
    let miss: String?
    let bank: [String]?
    let accepted: [[String]]?
    let model: String?
    /// Mot: the word-list key to highlight.
    let target: String?

    /// The right choice text (authored index → string).
    var correctChoice: String? {
        guard let choices, let correct, choices.indices.contains(correct) else { return nil }
        return choices[correct]
    }

    /// Grading by identity: the picked choice TEXT must be the right one, so
    /// the shuffled display order can never change the grade.
    func isCorrect(choice: String) -> Bool {
        correctChoice == choice
    }

    /// Every listed reply grades correct; nothing else does.
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

    /// Why-line for an authored choice index.
    func why(for authoredIndex: Int) -> String? {
        guard let why, why.indices.contains(authoredIndex), !why[authoredIndex].isEmpty else { return nil }
        return why[authoredIndex]
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
            if correctChoice == nil { errors.append("\(type.rawValue): correct out of range") }
        case .reply:
            guard let bank, let accepted, !accepted.isEmpty, let model, !model.isEmpty else {
                errors.append("reply: missing bank, accepted or model"); break
            }
            if accepted.contains(where: { $0.isEmpty || !Self.isSubset($0, of: bank) }) {
                errors.append("reply: accepted reply cannot be built from the bank")
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

// MARK: - Module files (manifest → module → element → item)

/// `situations_manifest.json`. Lists every authored module; the loader reads
/// all of them, so new modules need no Swift change.
struct SituationManifest: Decodable {
    let book: String
    let moduleFiles: [String]
}

struct SituationModuleFile: Decodable {
    struct Element: Decodable {
        let id: String
        let title: String
        let note: String
        let items: [SituationItem]
    }
    let id: String
    let title: String
    let arc: String?
    let goal: String
    let elements: [Element]

    /// `sit_06` → 6. Unparseable IDs sort last.
    var number: Int {
        Int(id.split(separator: "_").last.map(String.init) ?? "") ?? 999
    }
}

struct SituationWordFile: Decodable {
    let words: [SituationWord]

    /// Normalised key → word. Later duplicates never replace the first entry.
    var glossary: [String: SituationWord] {
        var out: [String: SituationWord] = [:]
        for word in words where out[SituationText.norm(word.fr)] == nil {
            out[SituationText.norm(word.fr)] = word
        }
        return out
    }
}

// MARK: - Tappable words

/// Splits a line into tappable words and set phrases.
enum SituationText {
    struct Segment: Equatable {
        enum Kind: Equatable { case word, gap }
        let index: Int
        /// Text as shown (without trailing punctuation for glossed words).
        let display: String
        /// Trailing punctuation shown after the word.
        let trailing: String
        /// Word-list key, if any.
        let key: String?
        let kind: Kind
    }

    static func tokens(_ text: String) -> [String] {
        text.split(separator: " ").map(String.init)
    }

    /// Lowercased, typographic apostrophe → straight, punctuation stripped.
    static func norm(_ word: String) -> String {
        word.lowercased()
            .replacingOccurrences(of: "’", with: "'")
            .trimmingCharacters(in: CharacterSet(charactersIn: ".,!?;:«»… "))
    }

    /// Longest word-list phrase first, so « comme d'habitude » wins over
    /// « comme ». French spaced punctuation rides on the word before it.
    /// `keepApart` is a Corriger error word: no multi-word phrase may swallow
    /// it, so the learner can tap it on its own (« moi aussi » → « moi » « aussi »).
    static func segments(_ text: String, keys: Set<String>, keepApart: String? = nil) -> [Segment] {
        let toks = tokens(text)
        let apart = keepApart.map(norm)
        let phrases = keys
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

// MARK: - Render-time shuffling

/// Display order for choices and reply banks. The JSON order never reaches
/// the screen, so an author's habit (answer in slot 0) can't leak. Seeded per
/// item + drill + presentation salt: stable while the card is on screen,
/// different the next time the item comes back.
enum SituationShuffle {
    static func seed(_ text: String) -> UInt64 {
        var hash: UInt64 = 1469598103934665603          // FNV-1a 64-bit
        for byte in text.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 1099511628211
        }
        return hash
    }

    private static func splitmix64(_ state: inout UInt64) -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    /// A uniform permutation of `0..<count` (authored indices in display order).
    static func order(count: Int, seed: UInt64) -> [Int] {
        var arr = Array(0..<count)
        var state = seed
        var i = arr.count - 1
        while i > 0 {
            let j = Int(splitmix64(&state) % UInt64(i + 1))
            arr.swapAt(i, j)
            i -= 1
        }
        return arr
    }

    /// Reply bank order: a permutation whose first tiles never spell an
    /// accepted reply left to right.
    static func bankOrder(bank: [String], accepted: [[String]], seed: UInt64) -> [Int] {
        var s = seed
        for _ in 0..<16 {
            let order = self.order(count: bank.count, seed: s)
            let shown = order.map { bank[$0] }
            let spells = accepted.contains { reply in
                reply.count > 1 && Array(shown.prefix(reply.count)) == reply
            }
            if !spells { return order }
            s = s &+ 0x9E3779B97F4A7C15
        }
        return Array(0..<bank.count).reversed()
    }
}

// MARK: - Rating

/// A dialogue's result. Every drill right first time → good; any miss or
/// retry → hard; any drill not solved after two tries → again. The dialogue
/// takes its worst drill. Reading, replaying audio and tapping words for
/// English never lower it.
enum SituationOutcome: Int, Comparable {
    case again = 1, hard = 2, good = 3

    static func < (lhs: SituationOutcome, rhs: SituationOutcome) -> Bool { lhs.rawValue < rhs.rawValue }

    /// One drill: solved with `misses` wrong attempts, or not solved.
    static func drill(misses: Int, solved: Bool) -> SituationOutcome {
        !solved ? .again : (misses > 0 ? .hard : .good)
    }

    /// The dialogue: its worst drill (no drills → good).
    static func dialogue(_ drills: [SituationOutcome]) -> SituationOutcome {
        drills.min() ?? .good
    }
}

// MARK: - Réviser selection and mastery

/// What the app remembers about one item (`situation_item_log`).
struct SituationItemHistory: Equatable {
    let lastDone: Date
    let times: Int
    let lastOutcome: SituationOutcome
}

enum SituationSelector {
    /// The item for one Réviser turn of an element:
    /// 1. an item whose last try was not solved (bring the miss back first);
    /// 2. else an unseen item, in authored order (new words are taught in order);
    /// 3. else the item done longest ago.
    /// Within 2 and 3, prefer an item whose drill types differ from the
    /// element's last review (`lastKinds`), looking at most one step ahead in
    /// authored order for unseen items so taught-word order holds.
    static func reviewItem(_ items: [SituationItem], history: [String: SituationItemHistory],
                           lastKinds: Set<SituationDrill.Kind>) -> SituationItem? {
        guard !items.isEmpty else { return nil }
        let missed = items
            .filter { history[$0.id]?.lastOutcome == .again }
            .sorted { (history[$0.id]?.lastDone ?? .distantPast) < (history[$1.id]?.lastDone ?? .distantPast) }
        if let first = missed.first { return first }

        func differs(_ item: SituationItem) -> Bool { item.drillKinds.isDisjoint(with: lastKinds) }

        let unseen = items.filter { history[$0.id] == nil }
        if !unseen.isEmpty {
            return unseen.prefix(2).first(where: differs) ?? unseen.first
        }
        let oldest = items.sorted {
            (history[$0.id]?.lastDone ?? .distantPast) < (history[$1.id]?.lastDone ?? .distantPast)
        }
        return oldest.prefix(3).first(where: differs) ?? oldest.first
    }

    /// Apprendre for one element: the next `size` items in authored order that
    /// were never done (authored as d d s, so a chunk mixes two dialogues and a
    /// standalone). When every item is done, the ones done longest ago.
    static func learnItems(_ items: [SituationItem], history: [String: SituationItemHistory],
                           size: Int = 3) -> [SituationItem] {
        let unseen = items.filter { history[$0.id] == nil }
        if !unseen.isEmpty { return Array(unseen.prefix(size)) }
        let oldest = items.sorted {
            (history[$0.id]?.lastDone ?? .distantPast) < (history[$1.id]?.lastDone ?? .distantPast)
        }
        return Array(oldest.prefix(size))
    }
}

enum SituationMastery {
    static let distinctItems = 3
    static let distinctKinds = 2

    /// The Book 2 mastery gate: correct (good or hard) answers on at least 3
    /// distinct items of the element, covering at least 2 drill types. Graduation
    /// also still needs FSRS stability past the 21-day bar, as in Book 1.
    static func gateMet(correctItemIDs: Set<String>, items: [SituationItem]) -> Bool {
        let done = items.filter { correctItemIDs.contains($0.id) }
        guard done.count >= distinctItems else { return false }
        let kinds = done.reduce(into: Set<SituationDrill.Kind>()) { $0.formUnion($1.drillKinds) }
        return kinds.count >= distinctKinds
    }
}

// MARK: - Retry gate

/// Vérifier after a wrong Répondre. A miss keeps the reply's correct start
/// placed (Book 1's second-try pattern), so the learner's answer is still on
/// screen. Checking that same answer again must not spend the second try:
/// Vérifier stays off until the learner changes the answer.
enum SituationRetry {
    /// Answers to refuse after `tiles` was graded wrong: the wrong reply itself
    /// and the `keep` tiles left in place for the retry.
    static func rejected(after tiles: [String], keep: Int) -> [[String]] {
        [tiles, Array(tiles.prefix(max(0, keep)))]
    }

    /// Vérifier is on when something is placed and it differs from every
    /// answer already refused for this drill.
    static func canCheck(_ tiles: [String], rejected: [[String]]) -> Bool {
        !tiles.isEmpty && !rejected.contains(tiles)
    }
}
