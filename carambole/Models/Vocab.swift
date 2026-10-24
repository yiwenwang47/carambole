import Foundation

//  Vocab.swift
//  carambole
//
//  *Mots* (`book_fr_mots`): the vocab swipe book. One element = one word or
//  short expression (`voc_…`), French → English recognition. Content is one
//  bundled file, `Resources/Vocab/mots.json`, written by `tools/vocab/`:
//
//      {"book": "book_fr_mots", "version": 1, "seed": <int>,
//       "bands": [{"band": 1, "lecons": [{"index": 1, "entries": [
//           {"id": "voc_prix", "fr": "le prix", "pos": "n.m.", "en": "price; prize",
//            "rank": 709, "audio": "voc_prix", "fem": …, "register": …}]}]}]}
//
//  Band = 100 frequency ranks (band 7 = ranks 601–700), shuffled within the band
//  with the fixed `seed`. Leçon = 10 words + 2 expressions (`pos` "loc.", `rank`
//  null); its `index` is global (band 7 = leçons 61–70). Spec:
//  docs/plans/2026-10-23-vocab-swipe-plan.md. Pure value types, no UI.

/// One word or expression. The SRS element; `id` is the element id.
struct VocabEntry: Codable, Identifiable, Hashable {
    /// Element id, `voc_…` (accents folded: réussir → `voc_reussir`).
    let id: String
    /// Headword as authored, article / reflexive pronoun included:
    /// « la confiance », « l'odeur », « se tromper », « doux », « tout de suite ».
    let fr: String
    /// Part of speech: n.m., n.f., v., adj., adv., prép., conj., loc.
    let pos: String
    /// English gloss, main senses split by `;`.
    let en: String
    /// Lexique 3 lemma frequency rank. Nil for expressions (curated, no rank).
    let rank: Int?
    /// Irregular feminine (doux → douce). Nil when regular or not an adjective.
    let fem: String?
    /// Register label, e.g. `fam.`, `vulg.`. Nil for neutral words.
    let register: String?
    /// Bundled clip key (MP3 basename). The clip voices the bare word only.
    let audio: String

    /// True for a set expression (`loc.`).
    var isExpression: Bool { pos == "loc." }

    /// Article or reflexive pronoun split off the front, dictionary style:
    /// « la confiance » → ("confiance", "la"), « l'odeur » → ("odeur", "l'"),
    /// « se tromper » → ("tromper", "se"). Same rule as the approved mock
    /// (`head()` in design/vocab/vocab-swipe.src.html): le / la / les / se + space,
    /// or l' / s' (straight or curly apostrophe). Anything else → (fr, nil).
    var headParts: (word: String, article: String?) {
        let lower = fr.lowercased()
        for prefix in ["les ", "le ", "la ", "se "] where lower.hasPrefix(prefix) && fr.count > prefix.count {
            return (String(fr.dropFirst(prefix.count)), String(fr.prefix(prefix.count - 1)))
        }
        for prefix in ["l'", "s'", "l’", "s’"] where lower.hasPrefix(prefix) && fr.count > prefix.count {
            return (String(fr.dropFirst(prefix.count)), String(fr.prefix(prefix.count)))
        }
        return (fr, nil)
    }

    /// The headword without its article, plus an irregular feminine:
    /// « confiance », « doux, douce ». The view sets `(la)` after it in a smaller
    /// style (`displayArticle`).
    var displayWord: String {
        let word = headParts.word
        guard let fem, !fem.isEmpty else { return word }
        return "\(word), \(fem)"
    }

    /// `(la)`, `(l')`, `(se)`; nil when there is none.
    var displayArticle: String? {
        headParts.article.map { "(\($0))" }
    }

    /// One-line headword: « confiance (la) », « odeur (l') », « tromper (se) »,
    /// « doux, douce », « tout de suite ».
    var displayFR: String {
        guard let article = displayArticle else { return displayWord }
        return "\(displayWord) \(article)"
    }

    /// Part of speech with the register after it: `n.m.`, `n.m. · fam.`.
    var posLabel: String {
        guard let register, !register.isEmpty else { return pos }
        return "\(pos) · \(register)"
    }
}

/// One leçon: 10 words + 2 expressions, in authored (seeded-shuffle) order.
struct VocabLecon: Identifiable, Equatable {
    /// Global leçon number, 1-based (band 7 = leçons 61–70).
    let index: Int
    /// The band this leçon belongs to.
    let band: Int
    let entries: [VocabEntry]

    var id: Int { index }
}

/// One frequency band of 100 ranks = one module (band 7 = ranks 601–700).
struct VocabBand: Identifiable, Equatable {
    let band: Int
    let lecons: [VocabLecon]

    var id: Int { band }
    /// Frequency ranks this band covers: band 7 → 601...700.
    var rankRange: ClosedRange<Int> { ((band - 1) * 100 + 1)...(band * 100) }
    var entries: [VocabEntry] { lecons.flatMap(\.entries) }
}

/// The whole *Mots* book in memory: bands → leçons → entries.
struct VocabBook: Equatable {
    /// Book id from the file; must be `book_fr_mots`.
    let bookID: String
    let version: Int
    /// The seed the band shuffle used (informational; order is already applied).
    let seed: Int
    let bands: [VocabBand]

    static let empty = VocabBook(bookID: BookCatalog.motsID, version: 0, seed: 0, bands: [])

    var lecons: [VocabLecon] { bands.flatMap(\.lecons) }
    var entries: [VocabEntry] { lecons.flatMap(\.entries) }

    func lecon(index: Int) -> VocabLecon? {
        lecons.first { $0.index == index }
    }

    func entry(id: String) -> VocabEntry? {
        entries.first { $0.id == id }
    }

    /// The first leçon (book order) that still has an entry not in `done`
    /// (e.g. the ids with a correct answer / suspended). Nil when all are done.
    func nextLecon(done: Set<String>) -> VocabLecon? {
        lecons.first { lecon in lecon.entries.contains { !done.contains($0.id) } }
    }

    // MARK: Decoding

    private struct FileDTO: Decodable {
        let book: String
        let version: Int
        let seed: Int
        let bands: [BandDTO]
    }

    private struct BandDTO: Decodable {
        let band: Int
        let lecons: [LeconDTO]
    }

    private struct LeconDTO: Decodable {
        let index: Int
        let entries: [VocabEntry]
    }

    /// Decode the bundled JSON shape. Bands and leçons are sorted by number; an
    /// entry with a non-`voc_` id, an empty `fr` / `en` / `audio`, or an id seen
    /// earlier in the book is dropped with a log line, and a leçon or band left
    /// empty is dropped, so the views never meet an unplayable card. Throws only
    /// when the file itself does not decode.
    static func decode(_ data: Data) throws -> VocabBook {
        let file = try JSONDecoder().decode(FileDTO.self, from: data)
        var seen: Set<String> = []
        let bands: [VocabBand] = file.bands.sorted { $0.band < $1.band }.compactMap { band in
            let lecons: [VocabLecon] = band.lecons.sorted { $0.index < $1.index }.compactMap { lecon in
                let entries = lecon.entries.filter { entry in
                    guard entry.id.hasPrefix("voc_"), !entry.fr.isEmpty, !entry.en.isEmpty,
                          !entry.audio.isEmpty, seen.insert(entry.id).inserted else {
                        print("Vocab: skipped entry \(entry.id) (bad field or duplicate id)")
                        return false
                    }
                    return true
                }
                return entries.isEmpty ? nil : VocabLecon(index: lecon.index, band: band.band, entries: entries)
            }
            return lecons.isEmpty ? nil : VocabBand(band: band.band, lecons: lecons)
        }
        if file.book != BookCatalog.motsID {
            print("Vocab: file book id \(file.book) is not \(BookCatalog.motsID)")
        }
        return VocabBook(bookID: file.book, version: file.version, seed: file.seed, bands: bands)
    }

    /// The bundled book, decoded once (lazy, thread-safe) and shared by the
    /// book model, `ContentLoader` and the swipe session.
    static let bundled = loadBundled()

    /// `mots.json` from the bundle (`Vocab/` subdirectory, else the flattened
    /// root). Fails soft: a missing or broken file logs and returns `.empty`.
    static func loadBundled(_ bundle: Bundle = .main) -> VocabBook {
        guard let url = bundle.url(forResource: "mots", withExtension: "json", subdirectory: "Vocab")
                ?? bundle.url(forResource: "mots", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("Vocab: no mots.json in the bundle")
            return .empty
        }
        do {
            return try decode(data)
        } catch {
            print("Vocab: failed to decode mots.json: \(error)")
            return .empty
        }
    }
}

#if DEBUG
extension VocabBook {
    /// Inline fixture in the file contract shape (until the content agent ships
    /// `mots.json`). Leçon 61 sits in band 7, as in the real book.
    static let fixtureJSON = """
    {"book":"book_fr_mots","version":1,"seed":42,"bands":[
     {"band":7,"lecons":[
      {"index":62,"entries":[
       {"id":"voc_flic","fr":"le flic","pos":"n.m.","register":"fam.","en":"cop","rank":734,"audio":"voc_flic"},
       {"id":"voc_avoir_faim","fr":"avoir faim","pos":"loc.","en":"to be hungry","rank":null,"audio":"voc_avoir_faim"}]},
      {"index":61,"entries":[
       {"id":"voc_prix","fr":"le prix","pos":"n.m.","en":"price; prize","rank":709,"audio":"voc_prix"},
       {"id":"voc_cuisine","fr":"la cuisine","pos":"n.f.","en":"kitchen; cooking","rank":741,"audio":"voc_cuisine"},
       {"id":"voc_avis","fr":"l'avis","pos":"n.m.","en":"opinion; à mon avis = in my opinion","rank":791,"audio":"voc_avis"},
       {"id":"voc_naitre","fr":"naître","pos":"v.","en":"to be born","rank":705,"audio":"voc_naitre"},
       {"id":"voc_calmer","fr":"se calmer","pos":"v.","en":"to calm down","rank":773,"audio":"voc_calmer"},
       {"id":"voc_doux","fr":"doux","fem":"douce","pos":"adj.","en":"soft; gentle; mild","rank":708,"audio":"voc_doux"},
       {"id":"voc_tout_de_suite","fr":"tout de suite","pos":"loc.","en":"right away, at once","rank":null,"audio":"voc_tout_de_suite"},
       {"id":"voc_prix","fr":"le prix","pos":"n.m.","en":"duplicate","rank":709,"audio":"voc_prix"},
       {"id":"bad_id","fr":"x","pos":"n.m.","en":"x","rank":1,"audio":"x"}]}]},
     {"band":1,"lecons":[
      {"index":1,"entries":[
       {"id":"voc_odeur","fr":"l’odeur","pos":"n.f.","en":"smell","rank":90,"audio":"voc_odeur"},
       {"id":"voc_asseoir","fr":"s'asseoir","pos":"v.","en":"to sit down","rank":95,"audio":"voc_asseoir"}]},
      {"index":2,"entries":[
       {"id":"bad_only","fr":"x","pos":"n.m.","en":"x","rank":1,"audio":"x"}]}]}]}
    """

    static func _selfTest() {
        guard let book = try? decode(Data(fixtureJSON.utf8)) else {
            assertionFailure("vocab fixture decodes"); return
        }
        // Shape: bands and leçons sorted, bad + duplicate entries and empty leçons dropped.
        assert(book.bookID == "book_fr_mots" && book.version == 1 && book.seed == 42, "header fields")
        assert(book.bands.map(\.band) == [1, 7], "bands sorted")
        assert(book.lecons.map(\.index) == [1, 61, 62], "leçons sorted; an all-bad leçon is dropped")
        assert(book.lecon(index: 61)?.entries.count == 7, "duplicate id + non-voc_ id dropped")
        assert(book.lecon(index: 61)?.band == 7, "leçon knows its band")
        assert(book.bands.last?.rankRange == 601...700, "band 7 = ranks 601–700")
        assert(Set(book.entries.map(\.id)).count == book.entries.count, "ids unique")

        // Optional fields.
        let doux = book.entry(id: "voc_doux")!
        let flic = book.entry(id: "voc_flic")!
        let faim = book.entry(id: "voc_avoir_faim")!
        assert(doux.fem == "douce" && doux.register == nil && doux.rank == 708, "fem decodes")
        assert(faim.rank == nil && faim.isExpression && !doux.isExpression, "expression: no rank, loc.")
        assert(flic.audio == "voc_flic", "audio key")

        // Display, dictionary style (spec + mock).
        assert(book.entry(id: "voc_cuisine")!.displayFR == "cuisine (la)", "« cuisine (la) »")
        assert(book.entry(id: "voc_prix")!.displayFR == "prix (le)", "« prix (le) »")
        assert(book.entry(id: "voc_avis")!.displayFR == "avis (l')", "« avis (l') »")
        assert(book.entry(id: "voc_odeur")!.displayFR == "odeur (l’)", "curly apostrophe kept as authored")
        assert(book.entry(id: "voc_calmer")!.displayFR == "calmer (se)", "« calmer (se) »")
        assert(book.entry(id: "voc_asseoir")!.displayFR == "asseoir (s')", "« asseoir (s') »")
        assert(doux.displayFR == "doux, douce" && doux.displayArticle == nil, "« doux, douce »")
        assert(book.entry(id: "voc_naitre")!.displayFR == "naître", "bare verb unchanged")
        assert(book.entry(id: "voc_tout_de_suite")!.displayFR == "tout de suite", "expression unchanged")
        assert(book.entry(id: "voc_cuisine")!.displayWord == "cuisine", "word without article")
        assert(book.entry(id: "voc_cuisine")!.displayArticle == "(la)", "article in parentheses")
        assert(flic.posLabel == "n.m. · fam.", "register after the part of speech")
        assert(doux.posLabel == "adj.", "no register → pos only")
        // "la" alone (no word after) is not split.
        let la = VocabEntry(id: "voc_la", fr: "là", pos: "adv.", en: "there", rank: 1, fem: nil, register: nil, audio: "voc_la")
        assert(la.displayFR == "là", "« là » is a word, not an article")

        // Next leçon to learn.
        assert(book.nextLecon(done: [])?.index == 1, "start at the first leçon")
        assert(book.nextLecon(done: ["voc_odeur", "voc_asseoir"])?.index == 61, "skip a finished leçon")
        assert(book.nextLecon(done: Set(book.entries.map(\.id))) == nil, "all done → nil")

        // Fail soft.
        assert((try? decode(Data("{}".utf8))) == nil, "a broken file throws from decode")
        if let bare = Bundle(path: FileManager.default.temporaryDirectory.path) {
            assert(loadBundled(bare) == .empty, "missing file → .empty, no crash")
        }
    }
}
#endif
