//
//  LibraryView.swift
//  carambole
//
//  One language's shelf, pushed from `LanguagesView`. Books keep the old
//  motion.html 08 spacing (one 200 pt slot each): kicker label, light title,
//  then `Ouvrir →` + % for open books or `Bientôt` for books to come. Open
//  books sort first. The 08 paper ribbon was dropped on 2026-10-14; its code is
//  archived in `docs/archive/code/LibraryRibbon.swift`. Each book has its die-cut
//  mark on the right (`BookMarkView`, same recipe as the language marks).
//
//  The French shelf holds the two French books; the English shelf holds one
//  greyed placeholder (`ShelfLanguage.placeholders`). Each shelf speaks its own
//  language (`ShelfLanguage.shelf`): the French shelf stays in French.
//

import SwiftUI

/// One entry on the shelf. `available` books open into `BookView`; others are
/// placeholders that signal what's coming.
private struct ShelfBook: Identifiable {
    let id: String
    let title: String
    /// `.lab` kicker after the number, e.g. `Grammaire A1 → B1`.
    let kicker: String
    let available: Bool
    /// The book to open (nil for a placeholder).
    let descriptor: BookDescriptor?
}

struct LibraryView: View {
    let language: ShelfLanguage
    /// Opened once on first appearance (debug launch flags / remote).
    var initialBook: BookDescriptor? = nil

    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppPalette.storageKey) private var paletteID = AppPalette.fallback.rawValue
    @AppStorage(LanguageMarkStyle.storageKey) private var markID = LanguageMarkStyle.fallback.rawValue

    /// Authored order: the language's books, then its placeholders.
    private var catalog: [ShelfBook] {
        language.books.map {
            ShelfBook(id: $0.id, title: $0.shelfTitle, kicker: $0.kicker, available: true, descriptor: $0)
        } + language.placeholders.map {
            ShelfBook(id: $0.id, title: $0.title, kicker: $0.kicker, available: false, descriptor: nil)
        }
    }

    /// Each book's progress (%), from its own element IDs.
    @StateObject private var fondationsModel = BookViewModel(book: BookCatalog.fondations)
    @StateObject private var situationModel = BookViewModel(book: BookCatalog.enSituation)
    @State private var loaded = false
    /// The book pushed from the shelf (`BookView`).
    @State private var openedBook: BookDescriptor?

    private var books: [ShelfBook] {
        catalog.filter(\.available) + catalog.filter { !$0.available }
    }

    var body: some View {
        Group {
            GeometryReader { geo in
                ScrollView {
                    shelf(width: geo.size.width)
                }
                .scrollIndicators(.hidden)
                .ignoresSafeArea(edges: .top)
            }
            .background(AppColor.paper.ignoresSafeArea())
            // Status-bar band: paper, so titles scroll under it cleanly.
            .overlay(alignment: .top) {
                Color.clear.frame(height: 0)
                    .background(AppColor.paper.ignoresSafeArea(edges: .top))
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(item: $openedBook) { book in
                BookView(book: book, showBack: true)
            }
            .navigationBarBackButtonHidden(true)
            .swipeToGoBack { dismiss() }
            .onAppear {
                guard language == .french else { return }
                StarLoopPlayers.shared.prewarm()
                // First appearance loads content; returning from a book refreshes.
                if loaded {
                    fondationsModel.refresh()
                    situationModel.refresh()
                } else {
                    fondationsModel.load()
                    situationModel.load()
                    loaded = true
                    if let initialBook { openedBook = initialBook }
                    #if DEBUG
                    if let id = ProcessInfo.processInfo.environment["CB_OPEN_BOOK"] {
                        openedBook = BookCatalog.descriptor(id: id)
                    }
                    #endif
                }
            }
            #if DEBUG
            .onReceive(NotificationCenter.default.publisher(for: DemoRemote.Action.openBook.notification)) { _ in
                openedBook = BookCatalog.fondations
            }
            .onReceive(NotificationCenter.default.publisher(for: DemoRemote.Action.openSituationBook.notification)) { _ in
                openedBook = BookCatalog.enSituation
            }
            .onReceive(NotificationCenter.default.publisher(for: DemoRemote.Action.closeBook.notification)) { _ in
                openedBook = nil
            }
            #endif
        }
    }

    // MARK: - Shelf

    /// Shelf rhythm (the old 08 ribbon's): first slot top, slot height, space after the last.
    private enum Slot {
        static let start: CGFloat = 236
        static let step: CGFloat = 200
        static let tail: CGFloat = 110
        static func top(_ i: Int) -> CGFloat { start + CGFloat(i) * step }
    }

    private func shelf(width: CGFloat) -> some View {
        let books = self.books
        let height = Slot.top(books.count) + Slot.tail

        return ZStack(alignment: .topLeading) {
            edgeLabels
                .padding(.horizontal, Spacing.screenH)
                .padding(.top, 66)

            heading(books)
                .padding(.leading, Spacing.screenH)
                .padding(.top, 100)

            ForEach(Array(books.enumerated()), id: \.element.id) { index, book in
                bookMark(book, number: catalogNumber(book))
                    .padding(.leading, Mark.x)
                    .padding(.top, Slot.top(index) + 34 + Mark.dy)
                block(book, number: catalogNumber(book))
                    .frame(width: 220, alignment: .leading)
                    .padding(.leading, Spacing.screenH)
                    .padding(.top, Slot.top(index) + 34)
            }

            Text(language.shelf.end)
                .uppercaseLabel()
                .frame(width: width)
                .padding(.top, height - 60)
                .accessibilityHidden(true)
        }
        .frame(width: width, height: height, alignment: .topLeading)
    }

    /// Book mark beside each block (design/studio/books.html): 124 pt, from x 248,
    /// its box 30 pt above the block's kicker.
    private enum Mark {
        static let x: CGFloat = 248
        static let dy: CGFloat = -30
        static let size: CGFloat = 124
    }

    private func bookMark(_ book: ShelfBook, number: Int) -> some View {
        BookMarkView(shape: BookMarkShape(bookID: book.id), number: String(format: "%02d", number),
                     available: book.available, style: LanguageMarkStyle(stored: markID),
                     palette: AppPalette(stored: paletteID))
            .frame(width: Mark.size, height: Mark.size)
            .allowsHitTesting(false)
    }

    private func percent(_ book: ShelfBook) -> Int {
        let model = book.id == BookCatalog.enSituation.id ? situationModel : fondationsModel
        return model.estimate.percentComplete
    }

    private func catalogNumber(_ book: ShelfBook) -> Int {
        (catalog.firstIndex { $0.id == book.id } ?? 0) + 1
    }

    // MARK: - Header

    /// motion.html `.lab` pair pinned to the top edges: `‹ Languages` (back)
    /// and the language's name.
    private var edgeLabels: some View {
        HStack(alignment: .firstTextBaseline) {
            Button { dismiss() } label: {
                Text(language.shelf.back)
                    .uppercaseLabel(AppColor.ink)
                    .padding(.vertical, 10)
                    .padding(.trailing, 12)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.vertical, -10)
            .accessibilityLabel(language.shelf.backA11y)
            Spacer()
            Text(language.name).uppercaseLabel(AppColor.ink)
        }
    }

    /// 08 `.big`: Manrope 40 / 250, −0.03em; `N livres` then grey `M ouverts`
    /// (English shelf: `N books`, `M coming`).
    private func heading(_ books: [ShelfBook]) -> some View {
        let open = books.filter(\.available).count
        let text = language.shelf
        // Manrope's natural line box is ~1.37em; 08 sets 1.05em → pull lines up.
        return VStack(alignment: .leading, spacing: -12) {
            Text(text.count(language == .english ? open : books.count, open))
                .foregroundColor(AppColor.ink)
            Text(text.sub(books.count, open))
                .foregroundColor(AppColor.g2)
        }
        .font(.display(size: 40, wght: 250))
        .tracking(-1.2)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    // MARK: - Book block

    @ViewBuilder
    private func block(_ book: ShelfBook, number: Int) -> some View {
        if book.available, let descriptor = book.descriptor {
            Button { openedBook = descriptor } label: {
                blockLabel(book, number: number)
            }
            .buttonStyle(ShelfRowButtonStyle())
            .accessibilityHint(language.shelf.openHint)
        } else {
            blockLabel(book, number: number)
                .accessibilityHint(language.shelf.soonHint)
        }
    }

    /// Kicker `.lab`, title 32 / 250, then `Ouvrir →` (underlined) + % or `Bientôt`.
    private func blockLabel(_ book: ShelfBook, number: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(String(format: "%02d · ", number) + book.kicker)
                .uppercaseLabel()
            Text(book.title)
                .font(.display(size: 32, wght: 250))
                .tracking(-0.96)
                .foregroundColor(book.available ? AppColor.ink : AppColor.g3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)
            if book.available {
                HStack(spacing: 10) {
                    Text(language.shelf.open)
                        .uppercaseLabel(AppColor.ink)
                        .padding(.bottom, 2)
                        .overlay(alignment: .bottom) {
                            Rectangle().fill(AppColor.ink).frame(height: 1)
                        }
                    Text("\(percent(book)) %")
                        .uppercaseLabel(AppColor.ink)
                }
                .padding(.top, 4)
            } else {
                Text(language.shelf.soon)
                    .uppercaseLabel()
                    .padding(.top, 4)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// Block press feedback: a light dim + tiny scale (no colour, no bounce chrome).
private struct ShelfRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.55 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1, anchor: .leading)
            .animation(.easeOut(duration: 0.18), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack { LibraryView(language: .french) }
}
