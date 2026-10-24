import Foundation

//  BookCatalog.swift
//  carambole
//
//  The books on the shelf and how each one loads. Every book has its own
//  content, element IDs, review state, schedule, history and settings; the
//  books share only application code and the palette.
//
//  Element IDs never collide across books (Book 2 IDs start with `sit_`, *Mots* `voc_`), so
//  the shared SQLite tables stay correct as long as every reader filters by
//  the selected book's IDs. See docs/archive/plans/2026-10-11-book-2-action-plan.md
//  (Task 2).

/// How a book's content is shaped and drilled.
enum BookKind: Equatable {
    /// *Fondations*: grammar elements drilled with example sentences
    /// (`DrillSessionView`).
    case grammar
    /// *En situation*: conversational moves drilled with short dialogues
    /// (`SituationSessionView`).
    case situation
    /// *Mots*: single words and short expressions drilled by swiping
    /// (`VocabQueue`, `Models/Vocab.swift`, `VocabSessionView`).
    case vocab
}

/// One shelf entry: identity, labels, content kind and settings scope.
struct BookDescriptor: Identifiable, Hashable {
    /// Stable book ID (`Book.id`, `CourseModule.bookID`).
    let id: String
    /// Full title, e.g. "Français — Fondations".
    let title: String
    /// Shelf title, e.g. "Fondations".
    let shelfTitle: String
    /// Small label above the shelf title.
    let kicker: String
    let kind: BookKind
    /// UserDefaults key scope. `nil` keeps the original `settings.*` keys
    /// (Book 1, unchanged); otherwise keys read `settings.<scope>.*`.
    let settingsScope: String?

    static func == (lhs: BookDescriptor, rhs: BookDescriptor) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

enum BookCatalog {
    static let fondations = BookDescriptor(
        id: "book_fr_fondations", title: "Français — Fondations", shelfTitle: "Fondations",
        kicker: "Grammaire A1 → B1", kind: .grammar, settingsScope: nil)

    static let enSituation = BookDescriptor(
        id: "book_fr_en_situation", title: "Français — En situation", shelfTitle: "En situation",
        kicker: "Dialogues", kind: .situation, settingsScope: "book_fr_en_situation")

    /// *Mots* id (also the `mots.json` `book` field).
    static let motsID = "book_fr_mots"

    /// Vocab swipe book (working title *Mots*, plan 2026-10-23).
    static let mots = BookDescriptor(
        id: motsID, title: "Français — Mots", shelfTitle: "Mots",
        kicker: "Vocabulaire", kind: .vocab, settingsScope: "book_fr_mots")

    /// Shelf order.
    static let all: [BookDescriptor] = [fondations, enSituation, mots]

    static func descriptor(id: String) -> BookDescriptor? {
        all.first { $0.id == id }
    }
}
