//
//  LibraryView.swift
//  carambole
//
//  The shelf — the app's root. Lists the available books; tap one to enter its
//  BookView. "Français — Fondations" is the first (and only live) book; the model
//  supports many, so future books appear here as they ship.
//
//  Edge-type layout from design/motion.html (01 / 03 / 05 headers): small
//  tracked labels pinned to the top edges, one big light heading, hairline
//  rules, 22pt edges and a lot of empty paper. Grayscale; state by form
//  (live = ink + `→`, locked = g3 + `Bientôt`).
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

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealed = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.paper.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        edgeLabels
                        heading
                            .padding(.top, 22)
                        shelf
                            .padding(.top, 64)
                    }
                    .padding(.horizontal, Spacing.screenH)
                    .padding(.top, 16)
                    .padding(.bottom, Spacing.xl)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .safeAreaInset(edge: .bottom) { footer }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                if reduceMotion {
                    revealed = true
                } else {
                    withAnimation(.easeOut(duration: 0.45)) { revealed = true }
                }
            }
        }
    }

    // MARK: - Header (edge labels + big heading)

    /// motion.html `.lab` pair pinned to the top edges.
    private var edgeLabels: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Carambole").uppercaseLabel(AppColor.ink)
            Spacer()
            Text("Bibliothèque").uppercaseLabel()
        }
    }

    /// 03 `.big`: Manrope 40 / 250, −0.03em, second line in g2.
    private var heading: some View {
        let open = books.filter(\.available).count
        let soon = books.count - open
        // Manrope's natural line box is ~1.37em; 03 sets 1.05em → pull lines up.
        return VStack(alignment: .leading, spacing: -12) {
            Text("\(books.count) livres")
                .foregroundColor(AppColor.ink)
            Text("\(open) ouvert, \(soon) à venir.")
                .foregroundColor(AppColor.g2)
        }
        .font(.display(size: 40, wght: 250))
        .tracking(-1.2)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    // MARK: - Shelf

    private var shelf: some View {
        VStack(alignment: .leading, spacing: 0) {
            rule(AppColor.ink)
            ForEach(Array(books.enumerated()), id: \.element.id) { index, book in
                row(book, index: index)
                rule(AppColor.hairline)
            }
        }
    }

    @ViewBuilder
    private func row(_ book: ShelfBook, index: Int) -> some View {
        let anim: Animation? = reduceMotion
            ? nil
            : .easeOut(duration: 0.4).delay(Double(index) * 0.06)
        if book.available {
            NavigationLink {
                BookView(showBack: true)
            } label: {
                card(book, index: index)
            }
            .buttonStyle(ShelfRowButtonStyle())
            .opacity(revealed ? 1 : 0)
            .offset(y: revealed || reduceMotion ? 0 : 12)
            .animation(anim, value: revealed)
        } else {
            card(book, index: index)
                .opacity(revealed ? 1 : 0)
                .offset(y: revealed || reduceMotion ? 0 : 12)
                .animation(anim, value: revealed)
                .accessibilityHint("Bientôt disponible")
        }
    }

    /// One shelf row: index label, title (Manrope 24 / 300), subtitle label,
    /// and an edge marker on the right (`→` live, `Bientôt` locked).
    private func card(_ book: ShelfBook, index: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Text(String(format: "%02d", index + 1))
                .uppercaseLabel(book.available ? AppColor.ink : AppColor.g3)
                .frame(width: 22, alignment: .leading)

            VStack(alignment: .leading, spacing: 8) {
                Text(shortTitle(book.title))
                    .font(.display(size: 24, wght: 300))
                    .tracking(-0.5)
                    .foregroundColor(book.available ? AppColor.ink : AppColor.g3)
                    .fixedSize(horizontal: false, vertical: true)
                Text(book.available ? "Français · \(book.subtitle)" : "Français")
                    .uppercaseLabel(book.available ? AppColor.g2 : AppColor.g3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if book.available {
                Text("→")
                    .font(.display(size: 22, wght: 300))
                    .foregroundColor(AppColor.ink)
                    .accessibilityHidden(true)
            } else {
                Text("Bientôt").uppercaseLabel(AppColor.g2)
            }
        }
        .padding(.vertical, 22)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    /// "Français — Fondations" → "Fondations" (the language moves to the label).
    private func shortTitle(_ title: String) -> String {
        title.components(separatedBy: " — ").last ?? title
    }

    private func rule(_ color: Color) -> some View {
        Rectangle().fill(color).frame(height: 1)
    }

    // MARK: - Footer

    /// 01 bottom label: centred, quiet.
    private var footer: some View {
        Text("Toucher un livre pour l’ouvrir")
            .uppercaseLabel()
            .frame(maxWidth: .infinity)
            .padding(.bottom, 14)
            .accessibilityHidden(true)
    }
}

/// Row press feedback: a light dim + tiny scale (no colour, no bounce chrome).
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
