import Foundation

/// *Mots* new-word pacing. **PROVISIONAL (2026-10-23, Claude default pending
/// the user)**: all of the choice lives here so it is one edit to change.
///
/// - One leçon (10 words + 2 expressions) is the unit of a new-word session;
///   a leçon is never cut at the daily cap.
/// - Only words count against the cap (`newPerDay`, 10–20); expressions are
///   free.
/// - When a leçon ends under the cap, the done panel offers « Leçon suivante »;
///   at or over the cap it offers « Terminer » plus « Encore une leçon » (the
///   "one more leçon" button). Apprendre on the book home is never blocked.
enum VocabPacing {
    /// What the learn done panel offers.
    enum Next: Equatable {
        /// Under today's cap: go straight on to the next leçon.
        case nextLecon
        /// Cap reached: finish, or take one more leçon.
        case oneMore
        /// Nothing left to learn in the book.
        case none
    }

    /// Does `entry` count against the daily new-word cap?
    static func countsAgainstCap(_ entry: VocabEntry) -> Bool { !entry.isExpression }

    /// The done panel's offer after a leçon.
    static func afterLecon(wordsLearnedToday: Int, cap: Int, hasNext: Bool) -> Next {
        guard hasNext else { return .none }
        return wordsLearnedToday < cap ? .nextLecon : .oneMore
    }
}

#if DEBUG
extension VocabPacing {
    static func _selfTest() {
        let word = VocabEntry(id: "voc_a", fr: "a", pos: "v.", en: "a", rank: 1, fem: nil, register: nil, audio: "voc_a")
        let expr = VocabEntry(id: "voc_b", fr: "b c", pos: "loc.", en: "b", rank: nil, fem: nil, register: nil, audio: "voc_b")
        assert(countsAgainstCap(word) && !countsAgainstCap(expr), "expressions are free")
        assert(afterLecon(wordsLearnedToday: 10, cap: 20, hasNext: true) == .nextLecon, "under the cap")
        assert(afterLecon(wordsLearnedToday: 10, cap: 10, hasNext: true) == .oneMore, "cap reached")
        assert(afterLecon(wordsLearnedToday: 14, cap: 10, hasNext: true) == .oneMore, "over the cap")
        assert(afterLecon(wordsLearnedToday: 0, cap: 10, hasNext: false) == .none, "book done")
    }
}
#endif
