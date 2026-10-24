import Foundation

/// Pure card logic for one *Mots* swipe session. A value type with no UI,
/// persistence or clock: the view drives it with `apply(_:slot:)` and gets
/// back what to grade (`VocabQueue.Grade`), which `VocabStudy.commit` writes
/// through the shared `ElementGrader` / `TooEasyGate`. Spec:
/// docs/plans/2026-10-23-vocab-swipe-plan.md (Drill, Trop facile, Pacing).
///
/// ## Slots (user 2026-10-24)
/// Four cards are on screen, one per fixed slot, and ANY of them can be
/// swiped. A swiped card's slot is refilled in place by the next waiting card;
/// the other cards never move. When nothing is waiting, the slot stays empty.
///
/// ## Rules
/// - **Learn** (one leçon): armed (trop-facile-marked) words first, then the
///   rest, both in leçon order. A left swipe sends the card back to the
///   waiting pile so 2 waiting cards come out before it (the end if fewer
///   wait), as often as it takes, and zeroes its « connu » count. A word
///   leaves only after 3 right swipes in a row (user 2026-10-24: one
///   « connu » was too few); the first two send it back so 5 waiting cards
///   come out before it.
/// - **Review**: all due, most overdue (lowest predicted recall) first, capped.
///   A left swipe sends the card to the end ONCE; a second left drops it.
/// - **Peek** (a partial left drag shows the English): from then on that card
///   can only go left; right is rejected (the view rubber-bands). Playing
///   audio is not a peek.
/// - **Grades**: the right swipe that removes the card → `.good` (a learn
///   card's first two « connu » grade nothing); left → `.again`.
/// - **Trop facile** is marked on the Leçon page only (no swipe up, user
///   2026-10-24). An armed card: clean right → trop facile removed; left (with
///   or without a peek) → trop facile NOT removed (records cleaned), and the
///   card carries on as a normal word (no extra `.again`, as in Books 1 and 2).
struct VocabQueue: Equatable {
    /// One card. `id` is unique per presentation (a requeued card gets a new
    /// one) so SwiftUI can tell the new card in a slot from the old one.
    struct Card: Identifiable, Equatable {
        let id: Int
        let entry: VocabEntry
        /// Marked trop facile on the Leçon page and not yet resolved (the card
        /// itself shows no tag, user 2026-10-24).
        var armed: Bool
        /// Swiped left at least once this session (dashed outline).
        var again: Bool
        /// Right swipes since its last left swipe (learn: leaves at `learnKnownTarget`).
        var known = 0
    }

    /// One gesture from the view.
    enum Swipe: Equatable {
        /// Left drag past the peek point (English shown). Send once per drag.
        case peek
        /// Left past the threshold: "I still need the meaning".
        case left
        /// Right: "I know it".
        case right
    }

    /// What one swipe asks the caller to persist. `entryID` is the element id.
    enum Grade: Equatable {
        /// Plain FSRS grade (`.good` / `.again`) via `ElementGrader.grade`.
        case rate(entryID: String, rating: FSRS.Rating)
        /// Shared trop facile gate: `TooEasyGate.resolve(removed:)`. `removed`
        /// → show the `.tooEasyUndo` pill for `entryID`.
        case tooEasy(entryID: String, removed: Bool)

        var entryID: String {
            switch self {
            case .rate(let id, _), .tooEasy(let id, _): return id
            }
        }
    }

    /// Result of `apply(_:slot:)`.
    enum Outcome: Equatable {
        /// Not allowed now (right after a peek, or an empty slot): snap back.
        case rejected
        /// The peek was recorded; nothing to grade.
        case peeked
        /// The card left its slot (or went back to the waiting pile); persist `grade`.
        case swiped(Grade)
        /// A learn « connu » short of `learnKnownTarget`: the card went back to
        /// the waiting pile; nothing to grade.
        case passed
    }

    /// Session counts for the header (« 12 connus · 3 à revoir · 1 trop facile »).
    struct Stats: Equatable {
        /// Words that left known (a learn word counts once, on its last « connu »).
        var known = 0
        /// Left swipes, counted every time (as in the mock).
        var again = 0
        var tooEasy = 0
    }

    /// Slots on screen.
    static let visibleCount = 4
    /// Learn: waiting cards that come out before a left-swiped card returns
    /// (the 3 other cards on screen are seen meanwhile too).
    static let learnRequeueGap = 2
    /// Learn: right swipes in a row before a word leaves.
    static let learnKnownTarget = 3
    /// Learn: waiting cards that come out before a word sent back by a « connu ».
    static let learnKnownGap = 5

    let mode: SessionMode
    /// The cards on screen by slot, top first; nil = an empty slot. Never
    /// reordered: a swiped slot is refilled in place.
    private(set) var slots: [Card?]
    /// Waiting cards, next first.
    private(set) var pool: [Card]
    /// Cards peeked (English shown): only a left swipe for them.
    private(set) var peekedIDs: Set<Int> = []
    private(set) var stats = Stats()
    /// Review: entry ids already sent to the end once.
    private var requeuedIDs: Set<String> = []
    /// False for the placement test: every card is seen once.
    private var requeues = true
    /// Learn: right swipes a word needs to leave (1 for leçon 0's practice).
    private var knownTarget = 1
    private var nextCardID: Int

    private init(mode: SessionMode, entries: [(VocabEntry, armed: Bool)]) {
        self.mode = mode
        let cards = entries.enumerated().map { Card(id: $0.offset, entry: $0.element.0, armed: $0.element.armed, again: false) }
        let shown = Array(cards.prefix(Self.visibleCount))
        self.slots = shown.map { Optional($0) } + Array(repeating: nil, count: Self.visibleCount - shown.count)
        self.pool = Array(cards.dropFirst(Self.visibleCount))
        self.nextCardID = entries.count
    }

    // MARK: Building

    /// Learn stack for `entries` (a leçon, in leçon order): ids in `armed` come
    /// first, tagged armed; the rest follow. Order within each group is kept.
    /// `knownTarget`: right swipes in a row a word needs to leave.
    static func learn(entries: [VocabEntry], armed: Set<String>,
                      knownTarget: Int = learnKnownTarget) -> VocabQueue {
        let first = entries.filter { armed.contains($0.id) }.map { ($0, armed: true) }
        let rest = entries.filter { !armed.contains($0.id) }.map { ($0, armed: false) }
        var q = VocabQueue(mode: .learn, entries: first + rest)
        q.knownTarget = max(1, knownTarget)
        return q
    }

    /// A due entry with its predicted recall now (`FSRS.retrievability`); lower
    /// = more overdue.
    struct Due: Equatable {
        let entry: VocabEntry
        let recall: Double
    }

    /// Review stack: lowest recall first (ties keep the given order), at most
    /// `cap` cards. The rest roll to the next session / day.
    static func review(due: [Due], cap: Int) -> VocabQueue {
        let ordered = due.enumerated()
            .sorted { $0.element.recall != $1.element.recall ? $0.element.recall < $1.element.recall : $0.offset < $1.offset }
            .prefix(max(0, cap))
            .map { ($0.element.entry, armed: false) }
        return VocabQueue(mode: .review, entries: Array(ordered))
    }

    /// Placement stack (`VocabPlacement`): the probes in order; a left swipe
    /// does not requeue. Its grades are ignored (the test is ungraded).
    static func placement(entries: [VocabEntry]) -> VocabQueue {
        var q = VocabQueue(mode: .learn, entries: entries.map { ($0, armed: false) })
        q.requeues = false
        return q
    }

    // MARK: Reading

    /// The card in `slot`, if any.
    func card(at slot: Int) -> Card? {
        slots.indices.contains(slot) ? slots[slot] : nil
    }
    /// The big count (« 12 à apprendre »): cards on screen and waiting.
    var remaining: Int { slots.compactMap { $0 }.count + pool.count }
    var isFinished: Bool { remaining == 0 }
    func isPeeked(slot: Int) -> Bool {
        card(at: slot).map { peekedIDs.contains($0.id) } ?? false
    }

    // MARK: Driving

    /// Apply one gesture to the card in `slot`.
    mutating func apply(_ swipe: Swipe, slot: Int) -> Outcome {
        guard var card = card(at: slot) else { return .rejected }
        switch swipe {
        case .peek:
            peekedIDs.insert(card.id)
            return .peeked

        case .right:
            guard !peekedIDs.contains(card.id) else { return .rejected }
            if card.armed {
                stats.tooEasy += 1
                refill(slot)
                return .swiped(.tooEasy(entryID: card.entry.id, removed: true))
            }
            card.known += 1
            if requeues, mode == .learn, card.known < knownTarget {
                requeue(card, gap: Self.learnKnownGap)
                refill(slot)
                return .passed
            }
            stats.known += 1
            refill(slot)
            return .swiped(.rate(entryID: card.entry.id, rating: .good))

        case .left:
            peekedIDs.remove(card.id)
            stats.again += 1
            let grade: Grade = card.armed
                ? .tooEasy(entryID: card.entry.id, removed: false)
                : .rate(entryID: card.entry.id, rating: .again)
            card.armed = false
            card.again = true
            card.known = 0
            if requeues {
                switch mode {
                case .learn:
                    requeue(card, gap: Self.learnRequeueGap)
                case .review:
                    if requeuedIDs.insert(card.entry.id).inserted { requeue(card, gap: pool.count) }
                }
            }
            refill(slot)
            return .swiped(grade)
        }
    }

    /// The undo pill demoted a trop facile word: count it as known instead
    /// (as in the mock). It does not come back this session.
    mutating func undoTooEasy() {
        guard stats.tooEasy > 0 else { return }
        stats.tooEasy -= 1
        stats.known += 1
    }

    /// Empty the stack (the placement test stopped early).
    mutating func clear() {
        slots = Array(repeating: nil, count: Self.visibleCount)
        pool.removeAll()
        peekedIDs.removeAll()
    }

    /// The next waiting card takes `slot` (nil when none waits).
    private mutating func refill(_ slot: Int) {
        if let old = slots[slot] { peekedIDs.remove(old.id) }
        slots[slot] = pool.isEmpty ? nil : pool.removeFirst()
    }

    /// Back to the waiting pile, `gap` waiting cards before it, under a new
    /// presentation id.
    private mutating func requeue(_ card: Card, gap: Int) {
        defer { nextCardID += 1 }
        let again = Card(id: nextCardID, entry: card.entry, armed: card.armed, again: card.again, known: card.known)
        pool.insert(again, at: min(max(0, gap), pool.count))
    }
}

#if DEBUG
extension VocabQueue {
    static func _selfTest() {
        func entry(_ id: String) -> VocabEntry {
            VocabEntry(id: id, fr: id, pos: "n.m.", en: id, rank: 1, fem: nil, register: nil, audio: id)
        }
        let ids = (1...8).map { "voc_\($0)" }
        let entries = ids.map(entry)
        func shown(_ q: VocabQueue) -> [String?] { q.slots.map { $0?.entry.id } }
        func waiting(_ q: VocabQueue) -> [String] { q.pool.map(\.entry.id) }

        // Learn: armed first (leçon order kept), then the rest; 4 on screen.
        var q = learn(entries: entries, armed: ["voc_6", "voc_3"], knownTarget: 1)
        assert(shown(q) == ["voc_3", "voc_6", "voc_1", "voc_2"], "armed first, four slots")
        assert(waiting(q) == ["voc_4", "voc_5", "voc_7", "voc_8"], "the rest wait")
        assert(q.card(at: 0)?.armed == true && q.card(at: 2)?.armed == false, "armed tag")
        assert(Set((q.slots.compactMap { $0 } + q.pool).map(\.id)).count == 8, "unique card ids")

        // Any slot can be swiped; it is refilled in place, the others stay.
        assert(q.apply(.right, slot: 2) == .swiped(.rate(entryID: "voc_1", rating: .good)), "right on slot 2")
        assert(shown(q) == ["voc_3", "voc_6", "voc_4", "voc_2"], "slot 2 refilled in place")
        // Armed + clean right → trop facile removed.
        assert(q.apply(.right, slot: 1) == .swiped(.tooEasy(entryID: "voc_6", removed: true)), "armed clean right")
        assert(shown(q) == ["voc_3", "voc_5", "voc_4", "voc_2"], "slot 1 refilled")
        assert(q.stats == Stats(known: 1, again: 0, tooEasy: 1), "stats")
        q.undoTooEasy()
        assert(q.stats == Stats(known: 2, again: 0, tooEasy: 0), "undo counts it known")
        // Left → .again, back to the pile with 2 waiting cards before it.
        assert(waiting(q) == ["voc_7", "voc_8"], "two waiting")
        assert(q.apply(.left, slot: 3) == .swiped(.rate(entryID: "voc_2", rating: .again)), "left = again")
        assert(shown(q) == ["voc_3", "voc_5", "voc_4", "voc_7"] && waiting(q) == ["voc_8", "voc_2"],
               "requeued after 2 waiting, slot refilled from the pile")
        assert(q.pool.last!.again, "requeued: dashed")
        // Armed + left → cleaned, then a normal word.
        assert(q.apply(.left, slot: 0) == .swiped(.tooEasy(entryID: "voc_3", removed: false)), "armed left cleans")
        assert(q.pool.contains { $0.entry.id == "voc_3" && !$0.armed }, "requeued as a normal word")
        // Empty slots stay empty when nothing waits.
        var small = learn(entries: Array(entries.prefix(2)), armed: [], knownTarget: 1)
        assert(shown(small) == ["voc_1", "voc_2", nil, nil], "two cards, two empty slots")
        _ = small.apply(.right, slot: 0)
        assert(shown(small) == [nil, "voc_2", nil, nil] && small.remaining == 1, "slot left empty")
        assert(small.apply(.right, slot: 0) == .rejected, "empty slot rejects")
        _ = small.apply(.right, slot: 1)
        assert(small.isFinished, "finished")

        // Peek lock is per card.
        var p = learn(entries: Array(entries.prefix(3)), armed: [], knownTarget: 1)
        assert(p.apply(.peek, slot: 1) == .peeked && p.isPeeked(slot: 1) && !p.isPeeked(slot: 0), "peek on slot 1")
        let before = p
        assert(p.apply(.right, slot: 1) == .rejected && p == before, "peeked: right rejected, nothing changes")
        assert(p.apply(.right, slot: 0) == .swiped(.rate(entryID: "voc_1", rating: .good)), "other card unlocked")
        assert(p.apply(.left, slot: 1) == .swiped(.rate(entryID: "voc_2", rating: .again)), "left allowed")
        assert(!p.isPeeked(slot: 1), "lock gone with the card")

        // Three « connu » in a row (the default): the first two send the card
        // back 5 waiting cards later and grade nothing; the third grades .good.
        var k = learn(entries: entries, armed: [])
        assert(k.apply(.right, slot: 0) == .passed, "first connu: back to the pile")
        assert(shown(k) == ["voc_5", "voc_2", "voc_3", "voc_4"] && waiting(k) == ["voc_6", "voc_7", "voc_8", "voc_1"],
               "refilled in place, back at the end (fewer than 5 wait)")
        assert(k.pool.last!.known == 1 && k.stats == Stats(), "counted, not graded")
        var three = learn(entries: [entry("voc_k")], armed: [])
        assert(three.apply(.right, slot: 0) == .passed && three.apply(.right, slot: 0) == .passed, "two connus pass")
        assert(three.apply(.right, slot: 0) == .swiped(.rate(entryID: "voc_k", rating: .good)), "third grades good")
        assert(three.isFinished && three.stats == Stats(known: 1, again: 0, tooEasy: 0), "leaves on the third")
        // A left swipe zeroes the count.
        var reset = learn(entries: [entry("voc_r")], armed: [])
        _ = reset.apply(.right, slot: 0); _ = reset.apply(.right, slot: 0)
        assert(reset.apply(.left, slot: 0) == .swiped(.rate(entryID: "voc_r", rating: .again)), "left after two connus")
        assert(reset.card(at: 0)?.known == 0, "count zeroed")
        assert(reset.apply(.right, slot: 0) == .passed && reset.apply(.right, slot: 0) == .passed, "needs three again")
        assert(reset.apply(.right, slot: 0) == .swiped(.rate(entryID: "voc_r", rating: .good)), "then leaves")

        // Review: lowest recall first, ties in given order, capped.
        let due = [Due(entry: entry("voc_a"), recall: 0.8), Due(entry: entry("voc_b"), recall: 0.3),
                   Due(entry: entry("voc_c"), recall: 0.8), Due(entry: entry("voc_d"), recall: 0.5),
                   Due(entry: entry("voc_e"), recall: 0.9)]
        assert(shown(review(due: due, cap: 250)) == ["voc_b", "voc_d", "voc_a", "voc_c"], "most overdue first")
        assert(shown(review(due: due, cap: 2)) == ["voc_b", "voc_d", nil, nil], "cap")
        assert(review(due: due, cap: 0).isFinished && review(due: [], cap: 250).isFinished, "empty")
        // A left swipe goes to the end once (one right review); a second left drops it.
        var r = review(due: due, cap: 250)
        assert(r.apply(.left, slot: 0) == .swiped(.rate(entryID: "voc_b", rating: .again)), "review left = again")
        assert(shown(r) == ["voc_e", "voc_d", "voc_a", "voc_c"] && waiting(r) == ["voc_b"], "back once at the end")
        _ = r.apply(.right, slot: 0)
        assert(r.card(at: 0)?.entry.id == "voc_b" && r.card(at: 0)!.again, "the requeued card comes back")
        assert(r.apply(.right, slot: 0) == .swiped(.rate(entryID: "voc_b", rating: .good)), "review: one right leaves")
        var r2 = review(due: Array(due.prefix(1)), cap: 250)
        _ = r2.apply(.left, slot: 0)
        assert(r2.apply(.left, slot: 0) == .swiped(.rate(entryID: "voc_a", rating: .again)), "second left still grades")
        assert(r2.isFinished && r2.stats == Stats(known: 0, again: 2, tooEasy: 0), "second left drops it")
        assert(r.mode == .review, "mode")

        // Placement: each card once, no requeue; clear() ends it.
        var pl = placement(entries: Array(entries.prefix(5)))
        _ = pl.apply(.peek, slot: 0)
        assert(pl.apply(.right, slot: 0) == .rejected, "placement keeps the peek lock")
        _ = pl.apply(.left, slot: 0)
        assert(shown(pl) == ["voc_5", "voc_2", "voc_3", "voc_4"] && pl.pool.isEmpty, "placement left: no requeue")
        pl.clear()
        assert(pl.isFinished && pl.peekedIDs.isEmpty, "cleared")
    }
}
#endif
