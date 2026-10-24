import Foundation

/// Pure card-stack logic for one *Mots* swipe session. A value type with no UI,
/// persistence or clock: the view drives it with `apply(_:)` and gets back what
/// to grade (`VocabQueue.Grade`), which `VocabStudy.commit` writes through the
/// shared `ElementGrader` / `TooEasyGate`. Spec:
/// docs/plans/2026-10-23-vocab-swipe-plan.md (Drill, Trop facile, Pacing).
///
/// ## Rules
/// - **Learn** (one leçon): armed (trop-facile-marked) words first, then the
///   rest, both in leçon order. A left swipe sends the card back so 5 other
///   cards come before it (the end if fewer remain), as often as it takes; it
///   leaves the stack only on a right / up swipe.
/// - **Review**: all due, most overdue (lowest predicted recall) first, capped.
///   A left swipe sends the card to the end ONCE; a second left drops it.
/// - **Peek** (a partial left drag shows the English): from then on the top
///   card can only go left; right / up are rejected (the view rubber-bands).
///   Playing audio is not a peek.
/// - **Grades**: right → `.good`; left → `.again`; up → trop facile removed.
///   An armed card: clean right or up → trop facile removed; left (with or
///   without a peek) → trop facile NOT removed (records cleaned), and the card
///   carries on as a normal word (no extra `.again`, as in Books 1 and 2).
struct VocabQueue: Equatable {
    /// One card in the stack. `id` is unique per presentation (a requeued card
    /// gets a new one) so SwiftUI can animate the old card out and the new one in.
    struct Card: Identifiable, Equatable {
        let id: Int
        let entry: VocabEntry
        /// Marked trop facile on the Leçon page and not yet resolved; tag it
        /// « Trop facile ? ».
        var armed: Bool
        /// Swiped left at least once this session (dashed outline).
        var again: Bool
    }

    /// One gesture from the view.
    enum Swipe: Equatable {
        /// Left drag past the peek point (English shown). Send once per drag.
        case peek
        /// Left past the threshold: "I still need the meaning".
        case left
        /// Right: "I know it".
        case right
        /// Up: trop facile.
        case up
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

    /// Result of `apply(_:)`.
    enum Outcome: Equatable {
        /// Not allowed now (right / up after a peek, or an empty stack): snap back.
        case rejected
        /// The peek was recorded; nothing to grade.
        case peeked
        /// The top card left the stack (or went back in it); persist `grade`.
        case swiped(Grade)
    }

    /// Session counts for the header (« 12 connus · 3 à revoir · 1 trop facile »).
    struct Stats: Equatable {
        var known = 0
        /// Left swipes, counted every time (as in the mock).
        var again = 0
        var tooEasy = 0
    }

    /// Cards drawn at once (top card + three behind it).
    static let visibleCount = 4
    /// Learn: cards that come before a left-swiped card returns.
    static let learnRequeueGap = 5

    let mode: SessionMode
    private(set) var cards: [Card]
    /// The top card has been peeked; only a left swipe is allowed.
    private(set) var peeked = false
    private(set) var stats = Stats()
    /// Review: entry ids already sent to the end once.
    private var requeuedIDs: Set<String> = []
    /// False for the placement test: every card is seen once.
    private var requeues = true
    private var nextCardID: Int

    private init(mode: SessionMode, entries: [(VocabEntry, armed: Bool)]) {
        self.mode = mode
        self.cards = entries.enumerated().map { Card(id: $0.offset, entry: $0.element.0, armed: $0.element.armed, again: false) }
        self.nextCardID = entries.count
    }

    // MARK: Building

    /// Learn stack for `entries` (a leçon, in leçon order): ids in `armed` come
    /// first, tagged armed; the rest follow. Order within each group is kept.
    static func learn(entries: [VocabEntry], armed: Set<String>) -> VocabQueue {
        let first = entries.filter { armed.contains($0.id) }.map { ($0, armed: true) }
        let rest = entries.filter { !armed.contains($0.id) }.map { ($0, armed: false) }
        return VocabQueue(mode: .learn, entries: first + rest)
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

    /// The swiped card.
    var current: Card? { cards.first }
    /// Top card first, at most `visibleCount`.
    var visible: [Card] { Array(cards.prefix(Self.visibleCount)) }
    /// The big count (« 12 à apprendre »): cards still in the stack.
    var remaining: Int { cards.count }
    var isFinished: Bool { cards.isEmpty }
    var canSwipeRight: Bool { current != nil && !peeked }
    var canSwipeUp: Bool { current != nil && !peeked }

    // MARK: Driving

    /// Apply one gesture to the top card.
    mutating func apply(_ swipe: Swipe) -> Outcome {
        guard var card = cards.first else { return .rejected }
        switch swipe {
        case .peek:
            peeked = true
            return .peeked

        case .right, .up:
            guard !peeked else { return .rejected }
            cards.removeFirst()
            peeked = false
            if swipe == .up || card.armed {
                stats.tooEasy += 1
                return .swiped(.tooEasy(entryID: card.entry.id, removed: true))
            }
            stats.known += 1
            return .swiped(.rate(entryID: card.entry.id, rating: .good))

        case .left:
            cards.removeFirst()
            peeked = false
            stats.again += 1
            let grade: Grade = card.armed
                ? .tooEasy(entryID: card.entry.id, removed: false)
                : .rate(entryID: card.entry.id, rating: .again)
            card.armed = false
            card.again = true
            guard requeues else { return .swiped(grade) }
            switch mode {
            case .learn:
                cards.insert(fresh(card), at: min(Self.learnRequeueGap, cards.count))
            case .review:
                if requeuedIDs.insert(card.entry.id).inserted { cards.append(fresh(card)) }
            }
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
        cards.removeAll()
        peeked = false
    }

    /// The same card under a new presentation id.
    private mutating func fresh(_ card: Card) -> Card {
        defer { nextCardID += 1 }
        return Card(id: nextCardID, entry: card.entry, armed: card.armed, again: card.again)
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
        func order(_ q: VocabQueue) -> [String] { q.cards.map(\.entry.id) }

        // Learn: armed first (leçon order kept), then the rest.
        var q = learn(entries: entries, armed: ["voc_6", "voc_3"])
        assert(order(q) == ["voc_3", "voc_6", "voc_1", "voc_2", "voc_4", "voc_5", "voc_7", "voc_8"], "armed first")
        assert(q.visible.count == 4 && q.visible.first?.entry.id == "voc_3", "top four, top card first")
        assert(q.current?.armed == true && q.visible[2].armed == false, "armed tag")
        assert(Set(q.cards.map(\.id)).count == 8, "unique card ids")

        // Armed + clean right → trop facile removed; leaves the stack.
        assert(q.apply(.right) == .swiped(.tooEasy(entryID: "voc_3", removed: true)), "armed clean right")
        // Armed + up → trop facile removed.
        assert(q.apply(.up) == .swiped(.tooEasy(entryID: "voc_6", removed: true)), "armed up")
        assert(q.stats == Stats(known: 0, again: 0, tooEasy: 2), "two trop facile")
        q.undoTooEasy()
        assert(q.stats == Stats(known: 1, again: 0, tooEasy: 1), "undo counts it known")

        // Plain right → .good.
        assert(q.apply(.right) == .swiped(.rate(entryID: "voc_1", rating: .good)), "right = good")
        // Left → .again, back so 5 cards come first.
        assert(order(q) == ["voc_2", "voc_4", "voc_5", "voc_7", "voc_8"], "after three swipes")
        let topID = q.current!.id
        assert(q.apply(.left) == .swiped(.rate(entryID: "voc_2", rating: .again)), "left = again")
        assert(order(q) == ["voc_4", "voc_5", "voc_7", "voc_8", "voc_2"], "fewer than 5 left → end")
        assert(q.cards.last!.again && q.cards.last!.id != topID, "requeued: dashed, new id")

        // Requeue gap of 5 when enough cards remain.
        var long = learn(entries: entries, armed: [])
        _ = long.apply(.left)
        assert(order(long) == ["voc_2", "voc_3", "voc_4", "voc_5", "voc_6", "voc_1", "voc_7", "voc_8"],
               "back 5 cards later")
        // It keeps coming back until swiped right.
        for _ in 0..<5 { _ = long.apply(.right) }
        assert(long.current?.entry.id == "voc_1", "returns after 5")
        _ = long.apply(.left)
        assert(order(long) == ["voc_7", "voc_8", "voc_1"], "learn requeues again (no limit)")
        _ = long.apply(.right); _ = long.apply(.right)
        assert(long.apply(.right) == .swiped(.rate(entryID: "voc_1", rating: .good)), "finally right")
        assert(long.isFinished && long.remaining == 0, "stack empty")
        assert(long.apply(.right) == .rejected && long.apply(.peek) == .rejected, "empty stack rejects")
        assert(long.stats == Stats(known: 8, again: 2, tooEasy: 0), "stats")

        // Peek lock: after a peek only left; right / up are rejected and change nothing.
        var p = learn(entries: Array(entries.prefix(3)), armed: [])
        assert(p.canSwipeRight && p.canSwipeUp, "unlocked before a peek")
        assert(p.apply(.peek) == .peeked && p.peeked, "peek recorded")
        assert(!p.canSwipeRight && !p.canSwipeUp, "locked after a peek")
        let before = p
        assert(p.apply(.right) == .rejected && p.apply(.up) == .rejected, "right / up rejected")
        assert(p == before, "a rejected swipe changes nothing")
        assert(p.apply(.left) == .swiped(.rate(entryID: "voc_1", rating: .again)), "left allowed")
        assert(!p.peeked, "lock is per card")
        assert(p.apply(.right) == .swiped(.rate(entryID: "voc_2", rating: .good)), "next card unlocked")

        // Armed + peek → left only → trop facile NOT removed; then a normal word.
        var a = learn(entries: Array(entries.prefix(2)), armed: ["voc_2"])
        _ = a.apply(.peek)
        assert(a.apply(.right) == .rejected, "armed peeked: right locked")
        assert(a.apply(.left) == .swiped(.tooEasy(entryID: "voc_2", removed: false)), "armed left cleans")
        assert(order(a) == ["voc_1", "voc_2"] && a.cards.last!.armed == false, "requeued as a normal word")
        _ = a.apply(.right)
        assert(a.apply(.right) == .swiped(.rate(entryID: "voc_2", rating: .good)), "then grades normally")
        // Armed + left without a peek: also cleans.
        var a2 = learn(entries: [entry("voc_x")], armed: ["voc_x"])
        assert(a2.apply(.left) == .swiped(.tooEasy(entryID: "voc_x", removed: false)), "armed left, no peek")
        // Up on an unarmed card is trop facile too.
        var u = learn(entries: [entry("voc_y")], armed: [])
        assert(u.apply(.up) == .swiped(.tooEasy(entryID: "voc_y", removed: true)), "up = trop facile")

        // Review: lowest recall first, ties in given order, capped.
        let due = [Due(entry: entry("voc_a"), recall: 0.8), Due(entry: entry("voc_b"), recall: 0.3),
                   Due(entry: entry("voc_c"), recall: 0.8), Due(entry: entry("voc_d"), recall: 0.5)]
        assert(order(review(due: due, cap: 250)) == ["voc_b", "voc_d", "voc_a", "voc_c"], "most overdue first")
        assert(order(review(due: due, cap: 2)) == ["voc_b", "voc_d"], "cap")
        assert(review(due: due, cap: 0).isFinished && review(due: [], cap: 250).isFinished, "empty")
        // A left swipe goes to the end once; a second left drops it.
        var r = review(due: due, cap: 250)
        assert(r.apply(.left) == .swiped(.rate(entryID: "voc_b", rating: .again)), "review left = again")
        assert(order(r) == ["voc_d", "voc_a", "voc_c", "voc_b"], "back once at the end")
        _ = r.apply(.right); _ = r.apply(.right); _ = r.apply(.up)
        assert(r.current?.entry.id == "voc_b" && r.current!.again, "the requeued card comes back")
        assert(r.apply(.left) == .swiped(.rate(entryID: "voc_b", rating: .again)), "second left still grades")
        assert(r.isFinished, "second left drops it")
        assert(r.stats == Stats(known: 2, again: 2, tooEasy: 1), "review stats")
        assert(r.mode == .review, "mode")

        // Placement: each card once, no requeue; clear() ends it.
        var pl = placement(entries: Array(entries.prefix(3)))
        _ = pl.apply(.peek)
        assert(pl.apply(.right) == .rejected, "placement keeps the peek lock")
        _ = pl.apply(.left)
        assert(order(pl) == ["voc_2", "voc_3"], "placement left: no requeue")
        pl.clear()
        assert(pl.isFinished && !pl.peeked, "cleared")
    }
}
#endif
