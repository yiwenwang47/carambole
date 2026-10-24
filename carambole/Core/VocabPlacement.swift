import Foundation

/// *Monnaie courante* placement start (user, 2026-10-23): a short swipe test
/// after leçon 0 that picks the leçon a new learner starts at. Pure: no UI,
/// persistence or grading (it is UNGRADED; nothing reaches `VocabStudy.commit`).
///
/// - Probes: `perBand` words from every band, bands in book order. Words only
///   (no expressions), picked with a fixed seed so the test is the same on
///   every install.
/// - Right / up = known; left (with or without a peek) = not known. Each card
///   is seen once.
/// - The test stops at the first band with `missLimit` words not known; the
///   start is that band's first leçon. If every band passes, the start is the
///   last band's first leçon.
struct VocabPlacement: Equatable {
    static let perBand = 5
    static let missLimit = 2
    static let seed: UInt64 = 0x4D_4F_4E_4E

    /// All probe words, band after band.
    let probes: [VocabEntry]
    private let bandOf: [String: Int]
    private let bands: [Int]
    private(set) var missed: [Int: Int] = [:]
    private(set) var answered = 0
    /// The band the learner starts in, once decided.
    private(set) var startBand: Int?

    init(book: VocabBook) {
        var probes: [VocabEntry] = []
        var bandOf: [String: Int] = [:]
        for band in book.bands {
            var rng = SplitMix64(seed: Self.seed ^ UInt64(band.band))
            let words = band.entries.filter { !$0.isExpression }.shuffled(using: &rng).prefix(Self.perBand)
            probes += words
            for w in words { bandOf[w.id] = band.band }
        }
        self.probes = probes
        self.bandOf = bandOf
        self.bands = book.bands.map(\.band)
        if probes.isEmpty { startBand = bands.last }
    }

    var isDecided: Bool { startBand != nil }

    /// Record one answer. Ignored once the start is decided.
    mutating func record(entryID: String, known: Bool) {
        guard startBand == nil, let band = bandOf[entryID] else { return }
        answered += 1
        if !known {
            missed[band, default: 0] += 1
            if missed[band, default: 0] >= Self.missLimit { startBand = band; return }
        }
        if answered >= probes.count { startBand = bands.last }
    }

    /// The start leçon for the decided band: its first leçon.
    func startLecon(in book: VocabBook) -> VocabLecon? {
        guard let startBand else { return nil }
        return book.bands.first { $0.band == startBand }?.lecons.first
    }
}

/// Small seeded generator (SplitMix64) so the probe sample is stable.
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

#if DEBUG
extension VocabPlacement {
    static func _selfTest() {
        func entry(_ id: String, expr: Bool = false) -> VocabEntry {
            VocabEntry(id: id, fr: id, pos: expr ? "loc." : "n.m.", en: id, rank: expr ? nil : 1,
                       fem: nil, register: nil, audio: id)
        }
        func band(_ n: Int) -> VocabBand {
            let lecons = (0..<2).map { l in
                VocabLecon(index: (n - 1) * 10 + l + 1, band: n,
                           entries: (0..<10).map { entry("voc_\(n)_\(l)_\($0)") }
                               + [entry("voc_\(n)_\(l)_x", expr: true), entry("voc_\(n)_\(l)_y", expr: true)])
            }
            return VocabBand(band: n, lecons: lecons)
        }
        let book = VocabBook(bookID: "book_fr_mots", version: 1, seed: 1, bands: [band(1), band(2), band(3)])

        let p = VocabPlacement(book: book)
        assert(p.probes.count == 15, "5 per band")
        assert(p.probes.allSatisfy { !$0.isExpression }, "words only")
        assert(p.probes.prefix(5).allSatisfy { $0.id.hasPrefix("voc_1_") }
               && p.probes.suffix(5).allSatisfy { $0.id.hasPrefix("voc_3_") }, "bands in order")
        assert(VocabPlacement(book: book).probes == p.probes, "fixed seed: same sample")

        // Band 1 passes (one miss), band 2 fails on its second miss.
        var t = p
        for (i, e) in p.probes.prefix(5).enumerated() { t.record(entryID: e.id, known: i != 2) }
        assert(!t.isDecided, "one miss passes")
        let b2 = Array(p.probes[5..<10])
        t.record(entryID: b2[0].id, known: false)
        assert(!t.isDecided, "one miss so far")
        t.record(entryID: b2[1].id, known: false)
        assert(t.startBand == 2 && t.startLecon(in: book)?.index == 11, "stops at band 2 → leçon 11")
        t.record(entryID: p.probes[12].id, known: false)
        assert(t.startBand == 2, "ignored once decided")

        // All known → last band's first leçon.
        var all = p
        for e in p.probes { all.record(entryID: e.id, known: true) }
        assert(all.startBand == 3 && all.startLecon(in: book)?.index == 21, "all pass → last band")

        // Fails band 1 at once.
        var low = p
        low.record(entryID: p.probes[0].id, known: false)
        low.record(entryID: p.probes[1].id, known: false)
        assert(low.startLecon(in: book)?.index == 1, "band 1 → leçon 1")

        assert(VocabPlacement(book: .empty).probes.isEmpty, "empty book")
    }
}
#endif
