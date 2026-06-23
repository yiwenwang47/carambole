import Foundation

/// Pure queue-building + unlock logic for the daily study session. Holds no state
/// and touches no persistence or UI — the caller passes in the facts (the book,
/// the set of seen / due / mastered element ids, budgets) and gets back ordered
/// element queues. The SRS unit is the `GrammarElement`, not the example sentence.
struct StudyScheduler {
    /// All elements in deterministic course order: modules by `sortOrder`, then
    /// elements by `sortOrder` within each module, flattened.
    static func courseOrdered(_ book: Book) -> [GrammarElement] {
        book.modules
            .sorted { $0.sortOrder < $1.sortOrder }
            .flatMap { $0.elements.sorted { $0.sortOrder < $1.sortOrder } }
    }

    /// The next new elements to introduce: course order, minus anything already
    /// seen, capped at `remainingBudget` (the day's remaining `newPerDay` headroom).
    static func newQueue(book: Book, seen: Set<String>, remainingBudget: Int) -> [GrammarElement] {
        let budget = max(0, remainingBudget)
        guard budget > 0 else { return [] }
        return courseOrdered(book)
            .filter { !seen.contains($0.id) }
            .prefix(budget)
            .map { $0 }
    }

    /// The daily review queue. ALL `due` elements are returned and NEVER truncated;
    /// when below `target`, topped up with the first `target - due.count` overflow.
    static func reviewQueue(due: [GrammarElement], overflow: [GrammarElement], target: Int) -> [GrammarElement] {
        guard due.count < target else { return due }
        return due + overflow.prefix(target - due.count)
    }

    /// A module is complete when every one of its elements is in the `satisfied` set
    /// the caller passes (under FSRS that's the graduated set, `fetchGraduatedElementIDs`).
    static func isModuleComplete(_ module: CourseModule, satisfied: Set<String>) -> Bool {
        !module.elements.isEmpty && module.elements.allSatisfy { satisfied.contains($0.id) }
    }

    /// The set of unlocked module ids: a chain that opens forward but never re-locks
    /// work already started. A module is unlocked when it is the first, OR its
    /// immediate predecessor is complete (every element seen), OR it has itself been
    /// started (≥1 element in the `satisfied` set). The last clause is self-healing:
    /// if an EARLIER module later gains a fresh, never-seen element (a content update),
    /// the strict "predecessor complete" test would re-lock every module after it —
    /// including ones the learner already finished. Keeping a started module unlocked
    /// prevents that regression, while a fresh module with no progress still only
    /// opens once its predecessor is complete (so the frontier advances one at a time).
    static func unlockedModuleIDs(_ book: Book, satisfied: Set<String>) -> Set<String> {
        let ordered = book.modules.sorted { $0.sortOrder < $1.sortOrder }
        var unlocked: Set<String> = []
        for (i, module) in ordered.enumerated() {
            let predecessorComplete = i == 0 || isModuleComplete(ordered[i - 1], satisfied: satisfied)
            let started = module.elements.contains { satisfied.contains($0.id) }
            if i == 0 || predecessorComplete || started {
                unlocked.insert(module.id)
            }
        }
        return unlocked
    }
}

#if DEBUG
extension StudyScheduler {
    static func _selfTest() {
        func el(_ id: String, module: String, order: Int) -> GrammarElement {
            GrammarElement(id: id, moduleID: module, sortOrder: order, label: id, ruleNote: "", examples: [])
        }
        func mod(_ id: String, order: Int, elementIDs: [String]) -> CourseModule {
            CourseModule(id: id, bookID: "b", sortOrder: order, title: id, ruleNote: "",
                         elements: elementIDs.enumerated().map { el($1, module: id, order: $0) })
        }

        let m1 = mod("m1", order: 0, elementIDs: ["a", "b"])
        let m2 = mod("m2", order: 1, elementIDs: ["c", "d"])
        let book = Book(id: "b", title: "B", sortOrder: 0, modules: [m2, m1]) // out of order on purpose

        // Course order respects module then element sortOrder.
        assert(courseOrdered(book).map(\.id) == ["a", "b", "c", "d"], "course order")

        // newQueue drops seen, honors budget.
        assert(newQueue(book: book, seen: ["a"], remainingBudget: 0).isEmpty, "budget 0 → empty")
        assert(newQueue(book: book, seen: ["a"], remainingBudget: 10).map(\.id) == ["b", "c", "d"], "drops seen")
        assert(newQueue(book: book, seen: [], remainingBudget: 2).map(\.id) == ["a", "b"], "budget caps")

        // reviewQueue tops up to target; never truncates due.
        let due = [el("d1", module: "m1", order: 0), el("d2", module: "m1", order: 1)]
        let over = [el("o1", module: "m1", order: 0), el("o2", module: "m1", order: 1)]
        assert(reviewQueue(due: due, overflow: over, target: 3).map(\.id) == ["d1", "d2", "o1"], "tops up")
        assert(reviewQueue(due: due, overflow: over, target: 1).map(\.id) == ["d1", "d2"], "no truncate")

        // Module completeness + unlock chain.
        assert(!isModuleComplete(m1, satisfied: ["a"]), "partial → incomplete")
        assert(isModuleComplete(m1, satisfied: ["a", "b"]), "all satisfied → complete")
        assert(unlockedModuleIDs(book, satisfied: []) == ["m1"], "only first unlocked initially")
        assert(unlockedModuleIDs(book, satisfied: ["a", "b"]) == ["m1", "m2"], "m2 unlocks when m1 complete")
        // Self-heal: a started later module stays unlocked even if an earlier module is
        // incomplete (e.g. it gained a fresh, never-seen element). m1 is missing "b" but
        // m2 has progress ("c") → m2 must NOT re-lock.
        assert(unlockedModuleIDs(book, satisfied: ["a", "c"]).contains("m2"),
               "a started module stays unlocked despite an incomplete predecessor")
        // A fresh module with no progress still waits for its predecessor to complete.
        assert(!unlockedModuleIDs(book, satisfied: ["a"]).contains("m2"),
               "an untouched module stays locked until its predecessor is complete")
    }
}
#endif
