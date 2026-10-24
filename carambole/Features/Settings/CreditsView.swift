//
//  CreditsView.swift
//  carambole
//
//  "Credits": the third-party material the app ships. Pushed from Settings
//  (`ColorSettingsView`, `Credits →`). Same page style as Settings: `‹ Back`
//  edge label, one big light heading, tracked section labels over an ink rule,
//  hairline-ruled rows, `→` on rows that open something.
//
//  Sections: « Monnaie courante » (Lexique 3; Lingua Libre with its speakers
//  and the `All recordings` page, which lists every clip with its Commons
//  link; the synthesized rest), the Google TTS audio of Fondations and
//  En situation, and the two bundled OFL fonts. Book data comes from
//  `Resources/Vocab/mots_credits.json` (`BookCredits`), decoded off the main thread.
//

import SwiftUI

struct CreditsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var credits: BookCredits?
    @State private var openRecordings = false
    #if DEBUG
    @State private var appliedDebugFlags = false
    #endif

    var body: some View {
        ZStack(alignment: .top) {
            AppColor.paper.ignoresSafeArea()
            ScrollViewReader { scroller in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        CreditsHeader(back: "Settings") { dismiss() }
                        CreditsTitle("Credits")

                        SectionLabel("Monnaie courante").padding(.top, 34).padding(.bottom, 10)
                        Rectangle().fill(AppColor.ink).frame(height: 1)
                        if let credits {
                            motsSection(credits)
                        } else {
                            ProgressView()
                                .tint(AppColor.g2)
                                .padding(.vertical, 24)
                        }

                        SectionLabel("Fondations · En situation").padding(.top, 34).padding(.bottom, 10)
                        Rectangle().fill(AppColor.ink).frame(height: 1)
                        CreditRow(
                            name: "Synthesized voices",
                            lines: ["Sentence and dialogue audio: Google Cloud Text-to-Speech, French voices."]
                        )

                        SectionLabel("Fonts").padding(.top, 34).padding(.bottom, 10)
                        Rectangle().fill(AppColor.ink).frame(height: 1)
                        CreditRow(
                            name: "Manrope",
                            lines: ["Copyright 2018 The Manrope Project Authors",
                                    "SIL Open Font License 1.1"],
                            link: ("github.com/googlefonts/manrope", "https://github.com/googlefonts/manrope")
                        )
                        CreditRow(
                            name: "Familjen Grotesk",
                            lines: ["Copyright 2021 The Familjen Grotesk Project Authors",
                                    "SIL Open Font License 1.1"],
                            link: ("github.com/Familjen-Sthlm/Familjen-Grotesk",
                                   "https://github.com/Familjen-Sthlm/Familjen-Grotesk")
                        )
                        .id("end")
                    }
                    .padding(.horizontal, Spacing.screenH)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
                #if DEBUG
                .onChange(of: credits != nil) { _, loaded in
                    // CB_OPEN_CREDITS=bottom: scroll to the fonts once the book section is in.
                    if loaded, ProcessInfo.processInfo.environment["CB_OPEN_CREDITS"] == "bottom" {
                        DispatchQueue.main.async { scroller.scrollTo("end", anchor: .bottom) }
                    }
                }
                #endif
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .swipeToGoBack { dismiss() }
        .navigationDestination(isPresented: $openRecordings) {
            AllRecordingsView(clips: credits?.clips ?? [])
        }
        .task {
            if credits == nil { credits = await BookCredits.loadMots() }
            #if DEBUG
            if !appliedDebugFlags {
                appliedDebugFlags = true
                if ProcessInfo.processInfo.environment["CB_OPEN_CREDITS"] == "all" { openRecordings = true }
            }
            #endif
        }
    }

    // MARK: - Monnaie courante

    @ViewBuilder
    private func motsSection(_ credits: BookCredits) -> some View {
        ForEach(credits.sources.filter { $0.name != "Lingua Libre" }, id: \.self) { source in
            CreditRow(
                name: source.name,
                lines: [source.authors, "\(source.use.capitalizedFirst) · \(source.license)"],
                link: (source.url.displayHost, source.url)
            )
        }

        if let libre = credits.sources.first(where: { $0.name == "Lingua Libre" }) {
            CreditRow(
                name: libre.name,
                lines: [libre.authors,
                        "\(credits.clips.count.formatted()) word recordings on Wikimedia Commons",
                        credits.licenseCounts.map { "\($0.license): \($0.clips.formatted())" }
                            .joined(separator: " · ")],
                link: (libre.url.displayHost, libre.url)
            )

            SectionLabel("Speakers").padding(.top, 22).padding(.bottom, 10)
            Rectangle().fill(AppColor.ink).frame(height: 1)
            ForEach(credits.speakers, id: \.self) { speaker in
                speakerRow(speaker)
            }

            Button { openRecordings = true } label: {
                HStack(alignment: .firstTextBaseline) {
                    Text("All recordings")
                        .font(.display(size: 17, wght: 400))
                        .tracking(-0.2)
                        .foregroundColor(AppColor.ink)
                    Spacer()
                    Text("→")
                        .font(.display(size: 20, wght: 300))
                        .foregroundColor(AppColor.ink)
                        .accessibilityHidden(true)
                }
                .padding(.vertical, 18)
                .contentShape(Rectangle())
                .overlay(alignment: .bottom) {
                    Rectangle().fill(AppColor.hairline).frame(height: 1)
                }
            }
            .buttonStyle(.plain)
            .accessibilityHint("Every recording with its speaker, licence and Commons page")
        }

        if let tts = credits.tts, tts.count > 0 {
            CreditRow(
                name: "Synthesized voice",
                lines: ["The other \(tts.count.formatted()) words have no Lingua Libre recording yet; "
                        + "they use \(tts.service)."]
            )
        }
    }

    private func speakerRow(_ speaker: BookCredits.SpeakerCount) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(speaker.name)
                .font(.display(size: 17, wght: 400))
                .tracking(-0.2)
                .foregroundColor(AppColor.ink)
            Spacer()
            Text(speaker.clips == 1 ? "1 clip" : "\(speaker.clips.formatted()) clips")
                .font(.label(size: 13, wght: 400))
                .foregroundColor(AppColor.graphite)
                .monospacedDigit()
        }
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            Rectangle().fill(AppColor.hairline).frame(height: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - All recordings

/// Every Lingua Libre clip of « Monnaie courante »: word, speaker, licence;
/// a tap opens the clip's Wikimedia Commons file page (CC BY / BY-SA attribution).
struct AllRecordingsView: View {
    let clips: [BookCredits.Clip]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .top) {
            AppColor.paper.ignoresSafeArea()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    CreditsHeader(back: "Credits") { dismiss() }
                    CreditsTitle("All recordings")
                    Text("\(clips.count.formatted()) Lingua Libre recordings, Wikimedia Commons. "
                         + "Tap a word to open its file page.")
                        .font(.label(size: 13, wght: 400))
                        .foregroundColor(AppColor.graphite)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 14)

                    SectionLabel("Word · speaker · licence").padding(.top, 34).padding(.bottom, 10)
                    Rectangle().fill(AppColor.ink).frame(height: 1)
                    ForEach(clips) { clip in
                        recordingRow(clip)
                    }
                }
                .padding(.horizontal, Spacing.screenH)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .swipeToGoBack { dismiss() }
    }

    @ViewBuilder
    private func recordingRow(_ clip: BookCredits.Clip) -> some View {
        let content = VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(clip.word)
                    .font(.display(size: 17, wght: 400))
                    .tracking(-0.2)
                    .foregroundColor(AppColor.ink)
                Spacer()
                Text("→")
                    .font(.display(size: 17, wght: 300))
                    .foregroundColor(AppColor.ink)
                    .accessibilityHidden(true)
            }
            Text("\(clip.speaker) · \(clip.license)")
                .font(.label(size: 13, wght: 400))
                .foregroundColor(AppColor.graphite)
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .overlay(alignment: .bottom) {
            Rectangle().fill(AppColor.hairline).frame(height: 1)
        }

        if let url = URL(string: clip.url) {
            Link(destination: url) { content }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
                .accessibilityHint("Opens the file page on Wikimedia Commons")
        } else {
            content
        }
    }
}

// MARK: - Pieces

/// `‹ Back` (ink) on the left, the screen's parent as a grey label on the right,
/// as on the Settings page.
private struct CreditsHeader: View {
    let back: String
    let action: () -> Void

    var body: some View {
        HStack {
            Button(action: action) {
                Text("‹ Back")
                    .uppercaseLabel(AppColor.ink)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.vertical, -8)
            .accessibilityLabel("Back to \(back)")
            Spacer()
            Text(back).uppercaseLabel()
        }
    }
}

/// The page's one big light heading (Manrope 40 / 250), as on Settings.
private struct CreditsTitle: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.display(size: 40, wght: 250))
            .tracking(-1.2)
            .foregroundColor(AppColor.ink)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 30)
            .accessibilityAddTraits(.isHeader)
    }
}

/// Name (Manrope 26 / 250, as a Settings row), grey lines under it, and an
/// optional link line with `→`. Hairline below.
private struct CreditRow: View {
    let name: String
    let lines: [String]
    var link: (label: String, url: String)?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(name)
                .font(.display(size: 26, wght: 250))
                .tracking(-0.6)
                .foregroundColor(AppColor.ink)
                .accessibilityAddTraits(.isHeader)
            ForEach(lines, id: \.self) { line in
                Text(line)
                    .font(.label(size: 13, wght: 400))
                    .foregroundColor(AppColor.graphite)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let link, let url = URL(string: link.url) {
                Link(destination: url) {
                    Text("\(link.label) →")
                        .font(.label(size: 13, wght: 400))
                        .foregroundColor(AppColor.ink)
                        .padding(.vertical, 6)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.vertical, -6)
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 16)
        .overlay(alignment: .bottom) {
            Rectangle().fill(AppColor.hairline).frame(height: 1)
        }
    }
}

private extension String {
    /// "word frequency ranks" → "Word frequency ranks".
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }

    /// "https://lingualibre.org" → "lingualibre.org"; "http://www.lexique.org" → "lexique.org".
    var displayHost: String {
        guard let host = URL(string: self)?.host() else { return self }
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }
}

#if DEBUG
#Preview {
    NavigationStack { CreditsView() }
}
#endif
