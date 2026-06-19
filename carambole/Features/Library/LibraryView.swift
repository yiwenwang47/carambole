//
//  LibraryView.swift
//  carambole
//
//  The shelf — the app's root. Lists the available books; tap one to enter its
//  BookView. "Français — Fondations" is the first (and only live) book; the model
//  supports many, so future books appear here as they ship. Built from "Le Cahier".
//

import SwiftUI

/// One entry on the shelf. `available` books open into `BookView`; others are
/// locked placeholders that signal what's coming.
private struct ShelfBook: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let available: Bool
}

struct LibraryView: View {
    private let books: [ShelfBook] = [
        ShelfBook(id: "fr_fondations", title: "Français — Fondations",
                  subtitle: "Grammaire · A1 → B1", available: true),
        ShelfBook(id: "fr_conversation", title: "Français — Conversation",
                  subtitle: "Bientôt", available: false),
        ShelfBook(id: "fr_intermediaire", title: "Français — Intermédiaire",
                  subtitle: "Bientôt", available: false),
    ]

    @State private var revealed = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.paper.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        header
                        divider
                        shelf
                    }
                    .padding(.horizontal, Spacing.screenH)
                    .padding(.top, 72)
                    .padding(.bottom, Spacing.xl)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.45)) { revealed = true }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionLabel("Bibliothèque")
            Text("Mes livres")
                .font(.appTitle)
                .foregroundColor(AppColor.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, Spacing.sm)
    }

    // MARK: - Shelf

    private var shelf: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(books.enumerated()), id: \.element.id) { index, book in
                row(book, index: index)
                if index < books.count - 1 {
                    Rectangle().fill(AppColor.hairline).frame(height: 1)
                }
            }
        }
    }

    @ViewBuilder
    private func row(_ book: ShelfBook, index: Int) -> some View {
        if book.available {
            NavigationLink {
                BookView(showBack: true)
            } label: {
                card(book)
            }
            .buttonStyle(ScaleButtonStyle())
            .opacity(revealed ? 1 : 0)
            .offset(y: revealed ? 0 : 12)
            .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.06), value: revealed)
        } else {
            card(book)
                .opacity(revealed ? 0.45 : 0)
                .offset(y: revealed ? 0 : 12)
                .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.06), value: revealed)
        }
    }

    private func card(_ book: ShelfBook) -> some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.appTitle)
                    .foregroundColor(book.available ? AppColor.ink : AppColor.graphite)
                    .fixedSize(horizontal: false, vertical: true)
                Text(book.subtitle).uppercaseLabel()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if book.available {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColor.saffron)
            } else {
                Image(systemName: "lock")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(AppColor.graphite)
            }
        }
        .padding(.vertical, Spacing.lg)
        .contentShape(Rectangle())
    }

    private var divider: some View {
        Rectangle().fill(AppColor.hairline).frame(height: 1)
    }
}

// MARK: - Preview

#Preview {
    LibraryView()
}
