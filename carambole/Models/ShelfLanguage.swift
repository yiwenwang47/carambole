import Foundation

//  ShelfLanguage.swift
//  carambole
//
//  The languages on the home page (`LanguagesView`). Each language has its own
//  shelf (`LibraryView(language:)`): the books it ships, plus greyed placeholder
//  books that are not out yet. App-level text (home, colours) is English; each
//  shelf speaks its own language (`shelf`), so the French shelf stays French.

/// A book announced on a shelf but not out yet (drawn greyed, `Coming soon`).
struct PlaceholderBook: Hashable {
    let id: String
    let title: String
    let kicker: String
}

enum ShelfLanguage: String, CaseIterable, Identifiable, Hashable {
    case english, french

    var id: String { rawValue }

    /// Home-page order, as designed (design/studio/prefs/layout-specimen.json).
    static let homeOrder: [ShelfLanguage] = [.english, .french]

    /// The language's name in that language.
    var name: String {
        switch self {
        case .english: return "English"
        case .french: return "Français"
        }
    }

    /// The books that open.
    var books: [BookDescriptor] {
        switch self {
        case .english: return []
        case .french: return BookCatalog.all
        }
    }

    /// Books announced but not out yet.
    var placeholders: [PlaceholderBook] {
        switch self {
        case .english:
            return [PlaceholderBook(id: "book_en_foundations", title: "Foundations", kicker: "Grammar A1 → B1")]
        case .french:
            return []
        }
    }

    /// The shelf's own words, in the shelf's language.
    var shelf: ShelfText {
        switch self {
        case .english:
            return ShelfText(back: "‹ Languages", backA11y: "Back to languages",
                             count: { total, _ in total == 1 ? "1 book" : "\(total) books" },
                             sub: { total, open in open == 0 ? "\(total - open) coming" : "\(open) open" },
                             open: "Open →", soon: "Coming soon", end: "End of the shelf",
                             openHint: "Opens the book", soonHint: "Coming soon")
        case .french:
            // The shelf as it shipped (2026-10-09), plus a way back.
            return ShelfText(back: "‹ Langues", backA11y: "Retour aux langues",
                             count: { total, _ in "\(total) livres" },
                             sub: { _, open in open == 1 ? "1 ouvert" : "\(open) ouverts" },
                             open: "Ouvrir →", soon: "Bientôt", end: "Fin de la bibliothèque",
                             openHint: "Ouvrir le livre", soonHint: "Bientôt disponible")
        }
    }

    /// `2 books`, `No books yet`.
    var bookCountLine: String {
        switch books.count {
        case 0: return "No books yet"
        case 1: return "1 book"
        default: return "\(books.count) books"
        }
    }
}

/// Every word a shelf shows, so each shelf speaks its own language.
struct ShelfText {
    let back: String
    let backA11y: String
    /// Big line, from (all books, open books).
    let count: (Int, Int) -> String
    /// Grey line under it, from (all books, open books).
    let sub: (Int, Int) -> String
    let open: String
    let soon: String
    let end: String
    let openHint: String
    let soonHint: String
}
