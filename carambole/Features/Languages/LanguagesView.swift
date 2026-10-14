//
//  LanguagesView.swift
//  carambole
//
//  The app's root: the languages, set as a type specimen (design/studio,
//  "Specimen"). Each language is one big name (Manrope 76 / 200) led by its
//  small mark (`LanguageMarkView`; the cut-paper mark carries the book count,
//  so the home page shows no separate count). A tap opens that
//  language's shelf (`LibraryView(language:)`). `Colors →` (top right) and
//  `Settings` (bottom right) open the colour page.
//
//  Positions are the user's drag layout (design/studio/prefs/layout-specimen.json,
//  360 pt wide design): x from the left edge, y from the top of the screen,
//  text placed by the CSS line-box top it had in the mock (converted to a
//  baseline), right-hand labels kept 24 pt from the right edge. The two
//  language rows keep their spacing but are centred vertically as a block.
//

import SwiftUI

struct LanguagesView: View {
    @State private var openLanguage: ShelfLanguage?
    @State private var openColors = false
    /// A book to open as soon as the French shelf appears (debug flags / remote).
    @State private var pendingBook: BookDescriptor?
    @AppStorage(AppPalette.storageKey) private var paletteID = AppPalette.fallback.rawValue
    @AppStorage(LanguageMarkStyle.storageKey) private var markID = LanguageMarkStyle.fallback.rawValue

    /// One language's row: mark origin, name box top, and the top of its tap band (mock points).
    private struct Row {
        let language: ShelfLanguage
        let markY: CGFloat
        let nameY: CGFloat
        let tapTop: CGFloat
    }

    private let rows = [
        Row(language: .english, markY: 150, nameY: 140, tapTop: 105),
        Row(language: .french, markY: 340, nameY: 327, tapTop: 287),
    ]

    private enum Layout {
        static let markX: CGFloat = 22
        static let markSize: CGFloat = 56
        static let nameX: CGFloat = 102
        static let nameSize: CGFloat = 76
        static let edge: CGFloat = 24
        static let headerY: CGFloat = 66
        /// `Settings` box top in the 760 pt tall mock, kept as a distance from the bottom.
        static let footY: CGFloat = 704
        static let mockHeight: CGFloat = 760
        /// Top of the English name box and bottom of the Français one (mock points):
        /// the two rows are centred on the screen as one block.
        static let rowsTop: CGFloat = 140
        static let rowsBottom: CGFloat = 327 + nameSize
    }

    /// Moves the language rows down so their block sits at the screen's vertical centre.
    private func rowsShift(height: CGFloat) -> CGFloat {
        height / 2 - (Layout.rowsTop + Layout.rowsBottom) / 2
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack(alignment: .topLeading) {
                    AppColor.paper
                    header(width: geo.size.width)
                    ForEach(rows, id: \.language) { row in
                        languageRow(row, width: geo.size.width, dy: rowsShift(height: geo.size.height))
                    }
                    footer(size: geo.size)
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            }
            .ignoresSafeArea()
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(item: $openLanguage) { language in
                LibraryView(language: language, initialBook: language == .french ? pendingBook : nil)
                    .onDisappear { pendingBook = nil }
            }
            .navigationDestination(isPresented: $openColors) { ColorSettingsView() }
            #if DEBUG
            .onAppear {
                let env = ProcessInfo.processInfo.environment
                if let raw = env["CB_OPEN_LANGUAGE"], let lang = ShelfLanguage(rawValue: raw) { openLanguage = lang }
                if env["CB_OPEN_COLORS"] == "1" { openColors = true }
                if pendingBook == nil, let id = env["CB_OPEN_BOOK"],
                   let book = BookCatalog.descriptor(id: id) {
                    pendingBook = book
                    openLanguage = .french
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: DemoRemote.Action.openBook.notification)) { _ in
                if openLanguage != .french { pendingBook = BookCatalog.fondations; openLanguage = .french }
            }
            .onReceive(NotificationCenter.default.publisher(for: DemoRemote.Action.openSituationBook.notification)) { _ in
                if openLanguage != .french { pendingBook = BookCatalog.enSituation; openLanguage = .french }
            }
            #endif
        }
    }

    // MARK: - Pieces

    private var theme: AppTheme { AppPalette(stored: paletteID).theme }
    private var markStyle: LanguageMarkStyle { LanguageMarkStyle(stored: markID) }

    private func header(width: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            Color.clear
            Text("Carambole")
                .uppercaseLabel(AppColor.ink)
                .placed(x: Layout.edge, baseline: Self.labelBaseline(Layout.headerY))
                .accessibilityAddTraits(.isHeader)
            Button { openColors = true } label: {
                Text("Colors →").uppercaseLabel(AppColor.ink)
                    .padding(10).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(-10)
            .placed(trailing: width - Layout.edge, baseline: Self.labelBaseline(Layout.headerY))
            .accessibilityLabel("Colors")
        }
        .frame(width: width, height: 120, alignment: .topLeading)
    }

    /// One tap band per language: from above its name to just below it.
    private func languageRow(_ row: Row, width: CGFloat, dy: CGFloat) -> some View {
        let lang = row.language
        let top = row.tapTop
        let height = row.nameY + Layout.nameSize + 8 - top
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            openLanguage = lang
        } label: {
            ZStack(alignment: .topLeading) {
                Color.clear
                LanguageMarkView(language: lang, style: markStyle, theme: theme)
                    .frame(width: Layout.markSize, height: Layout.markSize)
                    .placed(x: Layout.markX, y: row.markY - top)
                Text(lang.name)
                    .font(.display(size: Layout.nameSize, wght: 200))
                    .tracking(-0.055 * Layout.nameSize)
                    .foregroundColor(AppColor.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .frame(maxWidth: width - Layout.nameX - 8, alignment: .leading)
                    .placed(x: Layout.nameX, baseline: Self.nameBaseline(row.nameY) - top)
            }
            .frame(width: width, height: height, alignment: .topLeading)
            .contentShape(Rectangle())
        }
        .buttonStyle(LanguageRowButtonStyle())
        .placed(x: 0, y: top + dy)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(lang.name), \(lang.bookCountLine)")
        .accessibilityHint("Opens the shelf")
        .accessibilityAddTraits(.isButton)
    }

    private func footer(size: CGSize) -> some View {
        let fromBottom = Layout.mockHeight - Self.labelBaseline(Layout.footY)
        return Button { openColors = true } label: {
            Text("Settings").uppercaseLabel()
                .padding(10).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(-10)
        .placed(trailing: size.width - Layout.edge, baseline: size.height - fromBottom)
    }

    // MARK: - Mock line boxes → baselines

    /// The mock set text with `line-height: 1`, so a box top `y` puts the
    /// baseline at `y + (size − (ascender + descender)) / 2 + ascender`.
    private static func cssBaseline(_ y: CGFloat, font: UIFont) -> CGFloat {
        let a = font.ascender, d = -font.descender
        return y + (font.pointSize - (a + d)) / 2 + a
    }
    private static func labelBaseline(_ y: CGFloat) -> CGFloat {
        cssBaseline(y, font: AppFonts.uiFont(AppFonts.familjen, size: 11, wght: 400))
    }
    private static func nameBaseline(_ y: CGFloat) -> CGFloat {
        cssBaseline(y, font: AppFonts.uiFont(AppFonts.manrope, size: Layout.nameSize, wght: 200))
    }
}

/// Row press feedback: a light dim (as on the shelf).
private struct LanguageRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.55 : 1)
            .animation(.easeOut(duration: 0.18), value: configuration.isPressed)
    }
}

// MARK: - Absolute placement inside a top-leading ZStack

private extension View {
    /// Top-left corner at (x, y).
    func placed(x: CGFloat, y: CGFloat) -> some View {
        alignmentGuide(.leading) { _ in -x }.alignmentGuide(.top) { _ in -y }
    }
    /// Leading edge at x, first baseline at `baseline`.
    func placed(x: CGFloat, baseline: CGFloat) -> some View {
        alignmentGuide(.leading) { _ in -x }.alignmentGuide(.top) { d in d[.firstTextBaseline] - baseline }
    }
    /// Trailing edge at `trailing`, first baseline at `baseline`.
    func placed(trailing: CGFloat, baseline: CGFloat) -> some View {
        alignmentGuide(.leading) { d in d.width - trailing }.alignmentGuide(.top) { d in d[.firstTextBaseline] - baseline }
    }
}

#if DEBUG
#Preview {
    LanguagesView()
}
#endif
