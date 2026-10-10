//
//  LibraryView.swift
//  carambole
//
//  The shelf — the app's root. motion.html 08 "Ruban": one paper ribbon runs
//  down the right side of the shelf and each book is a stretch of it
//  (`LibraryRibbon.swift`). Books sit on the left of their stretch: kicker
//  label, light title, then `Ouvrir →` + % for open books or `Bientôt` for
//  books to come. Open books sort first. The ribbon lives inside the scroll
//  content, so it scrolls exactly with the titles. It is a still picture.
//
//  "Français — Fondations" is the first (and only live) book; the model
//  supports many, so future books appear here as they ship.
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
}

struct LibraryView: View {
    /// Authored order; open books are moved to the front for display.
    private let catalog: [ShelfBook] = [
        ShelfBook(id: "fr_fondations", title: "Fondations",
                  kicker: "Grammaire A1 → B1", available: true),
        ShelfBook(id: "fr_conversation", title: "Conversation",
                  kicker: "Oral", available: false),
    ]

    /// Fondations progress (%) — the only live book today.
    @StateObject private var bookViewModel = BookViewModel()
    /// Fondations per-day activity — feeds its ribbon stretch. Loaded before
    /// the first frame so the ribbon is drawn once, from real days.
    @StateObject private var historyViewModel = HistoryViewModel(loadImmediately: true)
    @State private var loaded = false
    /// Pushes Fondations' `BookView`.
    @State private var openBook = false
    /// Pushes the colour page.
    @State private var openColors = false
    @AppStorage(AppPalette.storageKey) private var paletteID = AppPalette.fallback.rawValue

    private var books: [ShelfBook] {
        catalog.filter(\.available) + catalog.filter { !$0.available }
    }

    var body: some View {
        NavigationStack {
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
            .navigationDestination(isPresented: $openBook) { BookView(showBack: true) }
            .navigationDestination(isPresented: $openColors) { ColorSettingsView() }
            .onAppear {
                StarLoopPlayers.shared.prewarm()
                // First appearance loads content; returning from a book refreshes.
                if loaded { bookViewModel.refresh() } else { bookViewModel.load(); loaded = true }
                historyViewModel.load()
            }
            #if DEBUG
            .onReceive(NotificationCenter.default.publisher(for: DemoRemote.Action.openBook.notification)) { _ in
                openBook = true
            }
            .onReceive(NotificationCenter.default.publisher(for: DemoRemote.Action.closeBook.notification)) { _ in
                openBook = false
            }
            #endif
        }
    }

    // MARK: - Shelf

    private func shelf(width: CGFloat) -> some View {
        let books = self.books
        let geometry = LibraryRibbonGeometry(stretches: books.map(stretch(for:)),
                                             viewWidth: Float(width))
        let height = CGFloat(geometry.contentHeight)

        return ZStack(alignment: .topLeading) {
            LibraryRibbonImage(geometry: geometry, palette: AppPalette(stored: paletteID))
            .frame(width: width, height: height)
            .allowsHitTesting(false)
            .accessibilityHidden(true)

            edgeLabels
                .padding(.horizontal, Spacing.screenH)
                .padding(.top, 66)

            heading(books)
                .padding(.leading, Spacing.screenH)
                .padding(.top, 100)

            ForEach(Array(books.enumerated()), id: \.element.id) { index, book in
                block(book, number: catalogNumber(book))
                    .frame(width: 220, alignment: .leading)
                    .padding(.leading, Spacing.screenH)
                    .padding(.top, CGFloat(LibraryRibbonGeometry.top(ofStretch: index)) + 34)
            }

            Text("Fin de la bibliothèque")
                .uppercaseLabel()
                .frame(width: width)
                .padding(.top, height - 60)
                .accessibilityHidden(true)
        }
        .frame(width: width, height: height, alignment: .topLeading)
    }

    /// The ribbon stretch for a book: an open book's last 30 days, or a
    /// faint strip for a book to come.
    private func stretch(for book: ShelfBook) -> LibraryRibbonGeometry.Stretch {
        guard book.available else { return .toCome }
        let window = HistoryViewModel.window(days: historyViewModel.days, today: Date(),
                                             count: 30, calendar: .current)
        return .started(window.map { $0.learned + $0.reviewed })
    }

    private func catalogNumber(_ book: ShelfBook) -> Int {
        (catalog.firstIndex { $0.id == book.id } ?? 0) + 1
    }

    // MARK: - Header

    /// motion.html `.lab` pair pinned to the top edges; the right one opens the
    /// colour page (a small strip of the current palette + `Couleurs →`).
    private var edgeLabels: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Carambole").uppercaseLabel(AppColor.ink)
            Spacer()
            Button {
                openColors = true
            } label: {
                HStack(spacing: 8) {
                    PaletteStrip(palette: AppPalette(stored: paletteID))
                        .frame(width: 26, height: 8)
                        .alignmentGuide(.firstTextBaseline) { d in d[.bottom] }
                    Text("Couleurs →").uppercaseLabel(AppColor.ink)
                }
                .padding(.vertical, 10)
                .padding(.leading, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.vertical, -10)
            .accessibilityLabel("Couleurs, \(AppPalette(stored: paletteID).name)")
        }
    }

    /// 08 `.big`: Manrope 40 / 250, −0.03em; `N livres` then grey `M ouverts`.
    private func heading(_ books: [ShelfBook]) -> some View {
        let open = books.filter(\.available).count
        // Manrope's natural line box is ~1.37em; 08 sets 1.05em → pull lines up.
        return VStack(alignment: .leading, spacing: -12) {
            Text("\(books.count) livres")
                .foregroundColor(AppColor.ink)
            Text(open == 1 ? "1 ouvert" : "\(open) ouverts")
                .foregroundColor(AppColor.g2)
        }
        .font(.display(size: 40, wght: 250))
        .tracking(-1.2)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    // MARK: - Book block

    private func open() {
        openBook = true
    }

    @ViewBuilder
    private func block(_ book: ShelfBook, number: Int) -> some View {
        if book.available {
            Button(action: open) {
                blockLabel(book, number: number)
            }
            .buttonStyle(ShelfRowButtonStyle())
            .accessibilityHint("Ouvrir le livre")
        } else {
            blockLabel(book, number: number)
                .accessibilityHint("Bientôt disponible")
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
                    Text("Ouvrir →")
                        .uppercaseLabel(AppColor.ink)
                        .padding(.bottom, 2)
                        .overlay(alignment: .bottom) {
                            Rectangle().fill(AppColor.ink).frame(height: 1)
                        }
                    Text("\(bookViewModel.estimate.percentComplete) %")
                        .uppercaseLabel(AppColor.ink)
                }
                .padding(.top, 4)
            } else {
                Text("Bientôt")
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
    LibraryView()
}
