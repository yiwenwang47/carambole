import Foundation

/// Pure queue-building logic for the daily study session. Holds no state and
/// touches no persistence or UI — the caller passes in the facts (topics, the set
/// of seen exercise IDs, due/overflow exercises, budgets) and gets back ordered
/// queues. See `DataManager` for the persistence that supplies these facts.
struct StudyScheduler {
    /// All exercises in deterministic course order: topics by `sortOrder`
    /// ascending, then exercises by `id` ascending within each topic, flattened.
    static func courseOrdered(_ topics: [GrammarTopic]) -> [Exercise] {
        topics
            .sorted { $0.sortOrder < $1.sortOrder }
            .flatMap { $0.exercises.sorted { $0.id < $1.id } }
    }

    /// The next new exercises to introduce: course order, minus anything already
    /// seen, capped at `remainingBudget` (the day's remaining `newPerDay` headroom).
    static func newQueue(topics: [GrammarTopic], seen: Set<String>, remainingBudget: Int) -> [Exercise] {
        let budget = max(0, remainingBudget)
        guard budget > 0 else { return [] }
        return courseOrdered(topics)
            .filter { !seen.contains($0.id) }
            .prefix(budget)
            .map { $0 }
    }

    /// The daily review queue. ALL `due` items are returned and are NEVER
    /// truncated, even when `due.count > target`. When the due stack is below
    /// `target`, the queue is topped up with the first `target - due.count`
    /// overflow items. `due` and `overflow` are disjoint by construction.
    static func reviewQueue(due: [Exercise], overflow: [Exercise], target: Int) -> [Exercise] {
        guard due.count < target else { return due }
        let topUp = overflow.prefix(target - due.count)
        return due + topUp
    }
}

#if DEBUG
extension StudyScheduler {
    static func _selfTest() {
        func ex(_ id: String, topic: String) -> Exercise {
            Exercise(id: id, topicID: topic, type: .conjugate, prompt: "", cue: nil,
                     answerTokens: [], tokenBank: [], inputMode: .multipleChoice, explanation: "")
        }

        // Course ordering: topic with the lower sortOrder comes first, ids sorted
        // ascending within each topic — regardless of input order.
        let topicB = GrammarTopic(id: "B", title: "B", sortOrder: 1, prerequisiteID: nil,
                                  ruleNote: "", exercises: [ex("b2", topic: "B"), ex("b1", topic: "B")])
        let topicA = GrammarTopic(id: "A", title: "A", sortOrder: 0, prerequisiteID: nil,
                                  ruleNote: "", exercises: [ex("a2", topic: "A"), ex("a1", topic: "A")])
        let ordered = courseOrdered([topicB, topicA])
        assert(ordered.map { $0.id } == ["a1", "a2", "b1", "b2"], "course order")

        // newQueue drops seen ids and honors budget.
        let seen: Set<String> = ["a1", "b1"]
        assert(newQueue(topics: [topicA, topicB], seen: seen, remainingBudget: 0).isEmpty, "budget 0 → empty")
        let big = newQueue(topics: [topicA, topicB], seen: seen, remainingBudget: 10)
        assert(big.map { $0.id } == ["a2", "b2"], "drops seen, budget > available returns all unseen")
        let one = newQueue(topics: [topicA, topicB], seen: seen, remainingBudget: 1)
        assert(one.map { $0.id } == ["a2"], "budget caps to first N unseen")

        // reviewQueue tops up to target with overflow.
        let due = [ex("d1", topic: "A"), ex("d2", topic: "A")]
        let overflow = [ex("o1", topic: "A"), ex("o2", topic: "A"), ex("o3", topic: "A")]
        let topped = reviewQueue(due: due, overflow: overflow, target: 4)
        assert(topped.map { $0.id } == ["d1", "d2", "o1", "o2"], "tops up to target")

        // reviewQueue never truncates when due.count >= target.
        let notTruncated = reviewQueue(due: due, overflow: overflow, target: 1)
        assert(notTruncated.map { $0.id } == ["d1", "d2"], "due never truncated below its own count")
        let exactlyTarget = reviewQueue(due: due, overflow: overflow, target: 2)
        assert(exactlyTarget.map { $0.id } == ["d1", "d2"], "no overflow added when due.count == target")
    }
}
#endif
