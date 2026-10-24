import Foundation

/// The I/O edge of a *Mots* session: builds `VocabQueue`s from the stored
/// review state and persists the grades the queue hands back. Everything goes
/// through the shared graders — `ElementGrader.grade` for `.good` / `.again`,
/// `TooEasyGate.resolve` for trop facile (HARD RULE: one logic, never forked) —
/// into `review_status` / `review_log`; no vocab-specific tables. The pure rules
/// live in `VocabQueue`. Reads hit the database's serial queue; call off-main
/// for a large review stack, like `BookViewModel.reviewSessionElements`.
enum VocabStudy {
    /// Persist one swipe's grade. A word has no example sentences, so the entry
    /// id doubles as the `exampleID` (its one distinct "item").
    static func commit(_ grade: VocabQueue.Grade, now: Date = Date()) {
        switch grade {
        case .rate(let id, let rating):
            ElementGrader.grade(elementID: id, exampleID: id, rating: rating, now: now)
        case .tooEasy(let id, let removed):
            TooEasyGate.resolve(elementID: id, exampleID: id, removed: removed, now: now)
        }
    }

    /// Learn stack for one leçon: entries not yet answered right (or graduated /
    /// suspended) — all of them once the leçon is complete, so it can be
    /// practised again (`LearnLoop.pendingElementIDs`, as Book 1) — with the
    /// `armed` ids (rows tapped on the Leçon page) first.
    static func learnQueue(lecon: VocabLecon, armed: Set<String>) -> VocabQueue {
        let pending = pendingIDs(lecon: lecon)
        return VocabQueue.learn(entries: lecon.entries.filter { pending.contains($0.id) }, armed: armed)
    }

    /// Entries of `lecon` a learn session would serve: those not yet answered
    /// right (or graduated / suspended); all of them once the leçon is complete.
    static func pendingIDs(lecon: VocabLecon) -> Set<String> {
        let completed = completedIDs(lecon.entries)
        return Set(LearnLoop.pendingElementIDs(lecon.entries.map(\.id), completedIDs: completed))
    }

    /// Entries with a correct answer, a graduation or a suspension.
    static func completedIDs(_ entries: [VocabEntry]) -> Set<String> {
        Set(entries.compactMap { entry -> String? in
            guard let status = DataManager.shared.fetchReviewStatus(elementID: entry.id),
                  status.distinctCorrect > 0 || status.graduatedDate != nil || status.suspended
            else { return nil }
            return entry.id
        })
    }

    /// The leçon Apprendre opens among `lecons` (one band, or the rest of the
    /// book): the first one with an entry not yet completed; when all are
    /// complete, the first one (practised again). Nil only for an empty list.
    static func nextLecon(in lecons: [VocabLecon]) -> VocabLecon? {
        lecons.first { !completedIDs($0.entries).isSuperset(of: $0.entries.map(\.id)) } ?? lecons.first
    }

    /// The first leçon after `index` (book order) that still has an entry not
    /// completed. Nil when every later leçon is done.
    static func lecon(after index: Int, in book: VocabBook) -> VocabLecon? {
        book.lecons.first { $0.index > index && !completedIDs($0.entries).isSuperset(of: $0.entries.map(\.id)) }
    }

    /// New WORDS first seen today in `book`: expressions do not count against
    /// the daily cap (`VocabPacing.countsAgainstCap`).
    static func wordsLearnedToday(book: VocabBook, now: Date = Date()) -> Int {
        let firstSeen = DataManager.shared.fetchElementIDsFirstSeen(on: now)
        return book.entries.filter { VocabPacing.countsAgainstCap($0) && firstSeen.contains($0.id) }.count
    }

    /// Review stack: every due, unsuspended entry of `book`, lowest predicted
    /// recall first, at most `cap` (the book's `reviewRoundSize`, 200–300).
    static func reviewQueue(book: VocabBook, cap: Int, now: Date = Date()) -> VocabQueue {
        let dueIDs = Set(DataManager.shared.fetchDueElementIDs(asOf: now))
        // TODO(perf): one `fetchReviewStatus` per due entry (as Book 1's review
        // round); batch it if a 250-card stack opens slowly.
        let due = book.entries.filter { dueIDs.contains($0.id) }.map { entry in
            VocabQueue.Due(entry: entry, recall: recall(elementID: entry.id, asOf: now))
        }
        return VocabQueue.review(due: due, cap: cap)
    }

    /// Due entries in `book` right now (the shelf / book-home count).
    static func dueCount(book: VocabBook, now: Date = Date()) -> Int {
        let dueIDs = Set(DataManager.shared.fetchDueElementIDs(asOf: now))
        return book.entries.filter { dueIDs.contains($0.id) }.count
    }

    /// Predicted recall `R(now)`; no FSRS state yet → 1.0 (sorts last), same as
    /// `BookViewModel.currentRecall`.
    private static func recall(elementID: String, asOf now: Date) -> Double {
        guard let status = DataManager.shared.fetchReviewStatus(elementID: elementID),
              let stability = status.stability else { return 1.0 }
        let elapsed = CalendarDays.elapsed(from: status.lastReviewDate, to: now)
        return FSRS.retrievability(stability: stability, elapsedDays: elapsed)
    }
}
