import Foundation

//  BookContent.swift
//  carambole
//
//  The course content hierarchy: Book → Module → Element → Example.
//
//  - A `Book` holds an ordered list of `CourseModule`s (the unlock units).
//  - A `CourseModule` holds the book's review elements.
//  - A *Fondations* `GrammarElement` holds ≥5 interchangeable `Exercise`s,
//    shuffled so the learner masters the rule, not a memorized token order.
//
//  These are pure in-memory value types loaded from bundle JSON by `ContentLoader`
//  (content is static, so it is NOT persisted in SQLite — only user `review_status`
//  is). See docs/plans/2026-06-19-book-modules-elements-design.md.

/// One grammar point plus its pool of example sentences. The SRS unit.
struct GrammarElement: Identifiable, Equatable {
    let id: String
    let moduleID: String
    let sortOrder: Int
    /// Short human label, e.g. "Article indéfini : un / une".
    let label: String
    /// One-to-two sentence English rule note shown when learning this element.
    let ruleNote: String
    /// ≥5 interchangeable example sentences (*Fondations*). Empty for a
    /// situation element.
    var examples: [Exercise]
    /// *En situation*: the move's short dialogues and standalone drills, in
    /// authored order (`d01 d02 s01 …`). Empty for a grammar element.
    var items: [SituationItem] = []
    /// *Nuances*: visible-source reading and expression cards, in authored order.
    var nuanceCards: [NuanceCard] = []
}

/// The unlock unit. Module N+1 unlocks when module N is complete
/// (every element mastered). ≈ the former `GrammarTopic`, much larger.
struct CourseModule: Identifiable, Equatable {
    let id: String
    let bookID: String
    let sortOrder: Int
    let title: String
    /// English intro shown on the module's one-time "Leçon" card.
    let ruleNote: String
    var elements: [GrammarElement]

    /// Every example across all of this module's elements, in element order.
    var allExamples: [Exercise] { elements.flatMap(\.examples) }
}

/// The top-level container. One book in v1; the model supports many.
struct Book: Identifiable, Equatable {
    let id: String
    let title: String
    let sortOrder: Int
    var modules: [CourseModule]
    /// Which drill loop serves this book.
    var kind: BookKind = .grammar
    /// *En situation* word list: normalised French word or set phrase → gloss.
    /// Empty for *Fondations*.
    var words: [String: SituationWord] = [:]
    /// *En situation*: who the learner plays throughout the book. Nil elsewhere.
    var persona: String?

    /// All elements across every module, in module → element order.
    var allElements: [GrammarElement] { modules.flatMap(\.elements) }
}

// MARK: - Samples (previews / self-tests)

extension GrammarElement {
    static let sample = GrammarElement(
        id: "el-sample",
        moduleID: "mod-sample",
        sortOrder: 1,
        label: "Passé composé avec être",
        ruleNote: "Verbs of motion form the passé composé with être; the participle agrees with the subject.",
        examples: [Exercise.sample]
    )
}

extension CourseModule {
    static let sample = CourseModule(
        id: "mod-sample",
        bookID: "book-sample",
        sortOrder: 1,
        title: "Composer des phrases",
        ruleNote: "French sentences share English's Subject–Verb–Object backbone.",
        elements: [GrammarElement.sample]
    )
}

extension Book {
    static let sample = Book(
        id: "book-sample",
        title: "Français — Fondations",
        sortOrder: 1,
        modules: [CourseModule.sample]
    )
}
