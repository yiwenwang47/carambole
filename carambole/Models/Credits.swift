import Foundation

//  Credits.swift
//  carambole
//
//  Third-party credits for one book, read by the Credits screen
//  (`Features/Settings/CreditsView.swift`). « Monnaie courante »
//  (`book_fr_mots`) ships `Resources/Vocab/mots_credits.json`, written by
//  `tools/vocab/build_lists.py assemble` and checked by `tools/vocab/lint.py`:
//
//      {"book": "book_fr_mots",
//       "sources": [{"name": "Lexique 3.83", "authors": …, "use": …,
//                    "license": "CC BY-SA 4.0", "url": "http://www.lexique.org"}, …],
//       "speakers": ["Lepticed7", …],
//       "clips": [{"audio": "voc_a", "word": "à", "source": "Lingua Libre",
//                  "speaker": "Lepticed7", "title": "File:LL-Q150 (fra)-Lepticed7-à.wav",
//                  "license": "CC BY-SA 4.0", "url": "https://commons.wikimedia.org/wiki/File:…"}],
//       "tts": {"count": 65, "service": "Google Cloud Text-to-Speech", "voices": ["fr-FR-Neural2-F"]}}
//
//  The file name is book-specific because Xcode flattens bundle resources.
//  Pure value types, no UI.

struct BookCredits: Equatable {
    /// A dataset or recording project the book draws on.
    struct Source: Codable, Equatable, Hashable {
        let name: String
        let authors: String
        let use: String
        let license: String
        let url: String
    }

    /// One bundled recording and its Commons attribution.
    struct Clip: Codable, Equatable, Identifiable {
        /// Clip key (MP3 basename); unique in the book.
        let audio: String
        /// The word as spoken.
        let word: String
        let source: String
        let speaker: String
        /// Commons file title, `File:LL-Q150 (fra)-<speaker>-<word>.wav`.
        let title: String
        let license: String
        /// Commons file page.
        let url: String

        var id: String { audio }
    }

    /// Clips with no recording, synthesized instead.
    struct TTS: Codable, Equatable {
        let count: Int
        let service: String
        let voices: [String]
    }

    /// One speaker and how many of the book's clips they recorded.
    struct SpeakerCount: Equatable, Hashable {
        let name: String
        let clips: Int
    }

    let bookID: String
    let sources: [Source]
    /// Sorted by word (French collation), as the "All recordings" page lists them.
    let clips: [Clip]
    let tts: TTS?

    static let empty = BookCredits(bookID: "", sources: [], clips: [], tts: nil)

    var isEmpty: Bool { sources.isEmpty && clips.isEmpty }

    /// Speakers, most clips first (ties by name).
    var speakers: [SpeakerCount] {
        Dictionary(grouping: clips, by: \.speaker)
            .map { SpeakerCount(name: $0.key, clips: $0.value.count) }
            .sorted { $0.clips != $1.clips ? $0.clips > $1.clips : $0.name < $1.name }
    }

    /// Clip count per licence, most first.
    var licenseCounts: [(license: String, clips: Int)] {
        Dictionary(grouping: clips, by: \.license)
            .map { (license: $0.key, clips: $0.value.count) }
            .sorted { $0.clips != $1.clips ? $0.clips > $1.clips : $0.license < $1.license }
    }

    // MARK: Decoding

    private struct FileDTO: Decodable {
        let book: String
        let sources: [Source]
        let clips: [Clip]
        let tts: TTS?
    }

    /// Decode the bundled JSON shape. A clip with an empty speaker, word,
    /// licence or URL, or a key seen earlier, is dropped with a log line, so
    /// the screen never shows an unattributed recording. Throws only when the
    /// file itself does not decode.
    static func decode(_ data: Data) throws -> BookCredits {
        let file = try JSONDecoder().decode(FileDTO.self, from: data)
        var seen: Set<String> = []
        let clips = file.clips.filter { clip in
            guard !clip.speaker.isEmpty, !clip.word.isEmpty, !clip.license.isEmpty,
                  URL(string: clip.url) != nil, seen.insert(clip.audio).inserted else {
                print("Credits: skipped clip \(clip.audio) (bad field or duplicate key)")
                return false
            }
            return true
        }
        let french = Locale(identifier: "fr_FR")
        let sorted = clips.sorted {
            let order = $0.word.compare($1.word, options: [.caseInsensitive, .diacriticInsensitive], locale: french)
            return order == .orderedSame ? $0.audio < $1.audio : order == .orderedAscending
        }
        return BookCredits(bookID: file.book, sources: file.sources, clips: sorted, tts: file.tts)
    }

    /// « Monnaie courante »'s credits, decoded once (lazy, thread-safe). The
    /// file is ~300 KB; read it off the main thread with `loadMots()`.
    static let mots = loadBundled(resource: "mots_credits")

    /// `mots` decoded on a background task, so the screen's first frame is not held up.
    static func loadMots() async -> BookCredits {
        await Task.detached(priority: .userInitiated) { mots }.value
    }

    /// `<resource>.json` from the bundle (`Vocab/` subdirectory, else the
    /// flattened root). Fails soft: a missing or broken file logs and returns `.empty`.
    static func loadBundled(resource: String, _ bundle: Bundle = .main) -> BookCredits {
        guard let url = bundle.url(forResource: resource, withExtension: "json", subdirectory: "Vocab")
                ?? bundle.url(forResource: resource, withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("Credits: no \(resource).json in the bundle")
            return .empty
        }
        do {
            return try decode(data)
        } catch {
            print("Credits: failed to decode \(resource).json: \(error)")
            return .empty
        }
    }
}

#if DEBUG
extension BookCredits {
    static let fixtureJSON = """
    {"book":"book_fr_mots",
     "sources":[{"name":"Lexique 3.83","authors":"Boris New, Christophe Pallier et al.","use":"word frequency ranks","license":"CC BY-SA 4.0","url":"http://www.lexique.org"}],
     "speakers":["Lepticed7","Yug"],
     "clips":[
      {"audio":"voc_etre","word":"être","source":"Lingua Libre","speaker":"Yug","title":"File:LL-Q150 (fra)-Yug-être.wav","license":"CC0","url":"https://commons.wikimedia.org/wiki/File:LL-Q150_(fra)-Yug-être.wav"},
      {"audio":"voc_a","word":"à","source":"Lingua Libre","speaker":"Lepticed7","title":"File:LL-Q150 (fra)-Lepticed7-à.wav","license":"CC BY-SA 4.0","url":"https://commons.wikimedia.org/wiki/File:LL-Q150_(fra)-Lepticed7-à.wav"},
      {"audio":"voc_ecole","word":"école","source":"Lingua Libre","speaker":"Lepticed7","title":"File:LL-Q150 (fra)-Lepticed7-école.wav","license":"CC BY 4.0","url":"https://commons.wikimedia.org/wiki/File:LL-Q150_(fra)-Lepticed7-école.wav"},
      {"audio":"voc_a","word":"à","source":"Lingua Libre","speaker":"Lepticed7","title":"dup","license":"CC0","url":"https://commons.wikimedia.org/wiki/File:x"},
      {"audio":"voc_nobody","word":"x","source":"Lingua Libre","speaker":"","title":"x","license":"CC0","url":"https://commons.wikimedia.org/wiki/File:x"}],
     "tts":{"count":65,"service":"Google Cloud Text-to-Speech","voices":["fr-FR-Neural2-F"]}}
    """

    static func _selfTest() {
        guard let credits = try? decode(Data(fixtureJSON.utf8)) else {
            assertionFailure("credits fixture decodes"); return
        }
        assert(credits.bookID == "book_fr_mots" && credits.sources.count == 1, "header fields")
        assert(credits.clips.map(\.audio) == ["voc_a", "voc_ecole", "voc_etre"],
               "duplicate + speakerless clips dropped; sorted by word, accents folded")
        assert(credits.speakers == [SpeakerCount(name: "Lepticed7", clips: 2), SpeakerCount(name: "Yug", clips: 1)],
               "speakers by clip count")
        assert(credits.licenseCounts.map(\.license) == ["CC BY 4.0", "CC BY-SA 4.0", "CC0"], "licence ties by name")
        assert(credits.tts?.count == 65, "tts count")

        // Fail soft.
        assert((try? decode(Data("{}".utf8))) == nil, "a broken file throws from decode")
        if let bare = Bundle(path: FileManager.default.temporaryDirectory.path) {
            assert(loadBundled(resource: "mots_credits", bare) == .empty, "missing file → .empty, no crash")
        }
        // The bundled file is present (its content is checked by tools/vocab/lint.py;
        // not decoded here, so launch stays quick).
        assert(Bundle.main.url(forResource: "mots_credits", withExtension: "json", subdirectory: "Vocab")
               ?? Bundle.main.url(forResource: "mots_credits", withExtension: "json") != nil,
               "mots_credits.json is bundled")
    }
}
#endif
