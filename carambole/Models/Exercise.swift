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

    /// Whether an answer is worth *typing* rather than picking. Excludes bare
    /// elisions and ultra-short particles (`n'`, `d'`, `de`, `ne`, `la`, `y`) and
    /// any answer carrying an elision token (`["n'", "est"]` → `"n' est"`, which a
    /// learner can't reproduce because answers are space-joined). Those are
    /// discrimination drills — typing defeats the contrast and the accent-strict
    /// grader would punish the very apostrophe being taught. Substantial words stay
    /// eligible for the typing shuffle.
    static func isTypeable(_ tokens: [String]) -> Bool {
        guard tokens.joined(separator: " ").count >= 3 else { return false }
        return !tokens.contains { $0.hasSuffix("'") || $0.hasSuffix("\u{2019}") }
    }

    /// Stable 50/50 bit derived from the exercise `id` (FNV-1a parity). Deterministic
    /// across launches and processes — unlike `String.hashValue`, which is seeded per
    /// run and would let a drill change input mode between sessions inconsistently.
    static func typeBit(_ id: String) -> Bool {
        var hash: UInt64 = 1469598103934665603        // FNV-1a 64-bit offset basis
        for byte in id.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 1099511628211              // FNV-1a 64-bit prime
        }
        return hash & 1 == 0
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
