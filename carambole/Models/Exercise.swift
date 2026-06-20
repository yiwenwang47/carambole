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
    /// Learner types the answer on the keyboard (graded accent-strict). Authors may
    /// set this explicitly; short answers are also shuffled into it at runtime — see
    /// `Exercise.resolvedInputMode`.
    case freeText
}

/// One drillable example sentence — the leaf of Book → Module → Element → Example.
/// Several examples (≥5) belong to one `GrammarElement`; they are interchangeable
/// test instances of the same rule, shuffled to prevent memorizing a fixed answer.
struct Exercise: Identifiable, Codable, Equatable {
    let id: String
    /// The `GrammarElement` this example drills. Injected by the loader.
    let elementID: String
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
        elementID: String,
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
        self.elementID = elementID
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

    /// The input actually presented to the learner. Long answers (≥3 tokens) keep
    /// their authored mode; short answers (≤2 tokens) are shuffled ~50/50 between
    /// typing and their authored mode for variety. An explicit `.freeText` author
    /// choice always types. Deterministic per `id`, so revisiting a drill via review
    /// navigation never flips its mode mid-session.
    var resolvedInputMode: InputMode {
        if inputMode == .freeText { return .freeText }
        guard answerTokens.count <= 2, Exercise.isTypeable(answerTokens) else {
            return inputMode
        }
        return Exercise.typeBit(id) ? .freeText : inputMode
    }

    /// Punctuation a learner would have to type out — terminal marks and
    /// separators. HARD RULE: a typing drill must never ask the learner to type
    /// these, so any answer carrying one is barred from the typing shuffle (it
    /// stays in its authored picked mode). Apostrophes and hyphens are intra-word
    /// (`l'eau`, `va-t-il`) and stay allowed.
    static let untypeablePunctuation: Set<Character> =
        [".", ",", "?", "!", ";", ":", "«", "»", "…", "\"", "(", ")"]

    /// Whether an answer is worth *typing* rather than picking. Excludes bare
    /// elisions and ultra-short particles (`n'`, `d'`, `de`, `ne`, `la`, `y`) and
    /// any answer carrying an elision token (`["n'", "est"]` → `"n' est"`, which a
    /// learner can't reproduce because answers are space-joined). Those are
    /// discrimination drills — typing defeats the contrast and the accent-strict
    /// grader would punish the very apostrophe being taught. Also excludes any
    /// answer containing `untypeablePunctuation` — we never make a learner type a
    /// `.`, `,`, `?`, `!` etc. Substantial words stay eligible for the typing shuffle.
    static func isTypeable(_ tokens: [String]) -> Bool {
        guard tokens.joined(separator: " ").count >= 3 else { return false }
        if tokens.contains(where: { $0.contains(where: untypeablePunctuation.contains) }) {
            return false        // never ask the learner to type punctuation
        }
        return !tokens.contains { $0.hasSuffix("'") || $0.hasSuffix("\u{2019}") }
    }

    /// Stable 50/50 bit derived from the exercise `id` (FNV-1a parity). Deterministic
    /// across launches and processes — unlike `String.hashValue`, which is seeded per
    /// run and would let a drill change input mode between sessions inconsistently.
    static func typeBit(_ id: String) -> Bool {
        return Exercise.seed64(id) & 1 == 0
    }

    /// 64-bit FNV-1a hash of an id — the deterministic seed shared by `typeBit` and
    /// `displayBank`. Stable across launches and processes (unlike `String.hashValue`,
    /// which is per-run seeded).
    static func seed64(_ id: String) -> UInt64 {
        var hash: UInt64 = 1469598103934665603        // FNV-1a 64-bit offset basis
        for byte in id.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 1099511628211              // FNV-1a 64-bit prime
        }
        return hash
    }

    /// The token bank in *presentation* order: a deterministic shuffle of `tokenBank`,
    /// seeded from `id`. Authoring tools may emit the bank with the answer tokens first
    /// in answer order (trivially solvable left-to-right); this guarantees the chips
    /// the learner actually sees are scrambled. The order is STABLE per `id` so it never
    /// reshuffles on a SwiftUI re-render mid-interaction, nor when a drill is revisited
    /// read-only via review navigation.
    ///
    /// Guards (the bank is reshuffled with a perturbed seed until they hold, then a
    /// rotation as a last resort): the result never reproduces the authored order, and
    /// for multi-token answers (`buildFromTokens`) the first `answerTokens.count` chips
    /// are never the answer in order. Single-token answers (multiple choice) only need
    /// to differ from the authored order — a uniform shuffle, so the answer lands at any
    /// row with no learnable position bias.
    var displayBank: [String] {
        guard tokenBank.count > 1 else { return tokenBank }
        var seed = Exercise.seed64(id)
        for _ in 0..<16 {
            let order = Exercise.deterministicShuffle(tokenBank, seed: seed)
            if passesShuffleGuards(order) { return order }
            seed = seed &+ 0x9E3779B97F4A7C15        // perturb and retry
        }
        // Last resort: a single rotation always differs from the authored order
        // (for distinct-element banks of count > 1).
        return Array(tokenBank.dropFirst()) + [tokenBank[0]]
    }

    /// A shuffled bank is acceptable when it changes the authored order and is not
    /// solvable by tapping chips left-to-right (multi-token answers only).
    private func passesShuffleGuards(_ order: [String]) -> Bool {
        if order == tokenBank { return false }
        if answerTokens.count > 1,
           Array(order.prefix(answerTokens.count)) == answerTokens {
            return false
        }
        return true
    }

    /// Deterministic Fisher–Yates shuffle driven by a splitmix64 stream off `seed`.
    /// Pure (no global RNG), so the same `(items, seed)` always yields the same order.
    static func deterministicShuffle(_ items: [String], seed: UInt64) -> [String] {
        var arr = items
        var state = seed
        var i = arr.count - 1
        while i > 0 {
            let j = Int(Exercise.splitmix64(&state) % UInt64(i + 1))
            arr.swapAt(i, j)
            i -= 1
        }
        return arr
    }

    /// One step of the splitmix64 PRNG.
    private static func splitmix64(_ state: inout UInt64) -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    static let sample = Exercise(
        id: "exercise-sample",
        elementID: "el-sample",
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

#if DEBUG
extension Exercise {
    static func _selfTest() {
        // displayBank is a permutation of tokenBank (same multiset).
        let build = Exercise(
            id: "shuf-build", elementID: "t", type: .wordOrder, prompt: "p", cue: nil,
            answerTokens: ["je", "suis", "à", "la", "maison"],
            tokenBank: ["je", "suis", "à", "la", "maison", "tu"],
            inputMode: .buildFromTokens, explanation: "e")
        assert(build.displayBank.sorted() == build.tokenBank.sorted(),
               "displayBank must be a permutation of tokenBank")

        // Deterministic + stable across calls.
        assert(build.displayBank == build.displayBank, "displayBank stable per id")

        // Guard: not the authored order, and not answer-in-order left-to-right.
        assert(build.displayBank != build.tokenBank, "must differ from authored order")
        assert(Array(build.displayBank.prefix(build.answerTokens.count)) != build.answerTokens,
               "first chips must not spell the answer in order")

        // Distinct ids generally yield distinct orders (not all identical).
        let orders = (0..<50).map { i -> [String] in
            Exercise(id: "b-\(i)", elementID: "t", type: .wordOrder, prompt: "p", cue: nil,
                     answerTokens: build.answerTokens, tokenBank: build.tokenBank,
                     inputMode: .buildFromTokens, explanation: "e").displayBank
        }
        assert(Set(orders.map { $0.joined(separator: "|") }).count > 1,
               "different ids must not all share one order")

        // Multiple choice: single answer token, bank still shuffled away from authored.
        let mc = Exercise(
            id: "shuf-mc", elementID: "t", type: .conjugate, prompt: "p", cue: nil,
            answerTokens: ["suis"], tokenBank: ["suis", "es", "est", "sommes"],
            inputMode: .multipleChoice, explanation: "e")
        assert(mc.displayBank.sorted() == mc.tokenBank.sorted(), "mc permutation")
        assert(mc.displayBank != mc.tokenBank, "mc must differ from authored order")

        // Duplicate tokens in the bank survive the shuffle (count preserved).
        let dup = Exercise(
            id: "shuf-dup", elementID: "t", type: .wordOrder, prompt: "p", cue: nil,
            answerTokens: ["la", "la"], tokenBank: ["la", "la", "le", "les"],
            inputMode: .buildFromTokens, explanation: "e")
        assert(dup.displayBank.filter { $0 == "la" }.count == 2, "duplicate tokens preserved")

        // Tiny banks (<= 1) are returned untouched (no distinct order exists).
        let one = Exercise(
            id: "shuf-one", elementID: "t", type: .fillBlank, prompt: "p", cue: nil,
            answerTokens: ["oui"], tokenBank: ["oui"],
            inputMode: .multipleChoice, explanation: "e")
        assert(one.displayBank == ["oui"], "single-chip bank returned as-is")
    }
}
#endif
