import Foundation

/// Pure-value "how far through the book / how much time left" estimate. Holds no
/// state and touches no persistence, UI, or singletons — the caller passes in the
/// book-scoped counts plus the mastery/first-seen day stamps and an injected
/// `today`, and gets back the bar segments, completion percent, and a (suppressible)
/// time-to-finish projection. Deterministic: ALL date math goes through the injected
/// `calendar`; there are no hidden `Date()` / `Calendar.current` calls in the logic
/// path, so the same inputs always yield the same estimate. T3 renders this.
struct ProgressEstimate: Equatable {
    // --- Inputs (book-scoped counts) ---
    let total: Int        // total elements in the book
    let mastered: Int     // elements CURRENTLY satisfied (live review_status gate) ∩ book
    let seen: Int         // elements ever introduced ∩ book

    // --- Bar segments (always sum to `total` for normal inputs) ---
    let masteredCount: Int    // = mastered                  (maîtrisé)
    let inProgressCount: Int   // = max(0, seen - mastered)   (en cours)
    let toComeCount: Int       // = max(0, total - seen)      (à venir)

    // --- Completion ---
    let fractionComplete: Double  // mastered/total, 0 when total == 0
    let percentComplete: Int      // see rounding rules in init
    let isComplete: Bool          // total > 0 && mastered >= total

    // --- Pace + time-to-finish (nil when not enough data / already done) ---
    let pacePerDay: Double?     // mastery events per calendar day over the window
    let daysRemaining: Int?     // ceil((total - mastered) / pace)
    let projectedFinish: Date?  // startOfDay(today) + daysRemaining days
    var hasEstimate: Bool { daysRemaining != nil }

    /// - Parameters:
    ///   - masteryDays:    `day_start` stamps from `mastery_log`, already book-scoped.
    ///   - firstActivity:  earliest `first_seen_date` in the book, `nil` if none yet.
    ///   - today:          injected "now" (no internal `Date()` — keeps it testable).
    ///   - window:         pace-averaging window in calendar days (inclusive of today).
    init(total: Int,
         mastered: Int,
         seen: Int,
         masteryDays: [Date],
         firstActivity: Date?,
         today: Date,
         calendar: Calendar = .current,
         window: Int = 14) {
        self.total = total
        self.mastered = mastered
        self.seen = seen

        // --- Segments (clamp negatives; sum to total for mastered ≤ seen ≤ total) ---
        self.masteredCount = mastered
        self.inProgressCount = max(0, seen - mastered)
        self.toComeCount = max(0, total - seen)

        // --- Completion ---
        let fraction = total > 0 ? Double(mastered) / Double(total) : 0
        self.fractionComplete = fraction
        let complete = total > 0 && mastered >= total
        self.isComplete = complete

        if total == 0 {
            self.percentComplete = 0
        } else if complete {
            self.percentComplete = 100
        } else {
            // Avoid two lies: never 100 unless truly done (cap at 99), and never 0
            // while some mastery exists (floor at 1 once mastered > 0).
            let floorPct = mastered > 0 ? 1 : 0
            let rounded = Int((fraction * 100).rounded())
            self.percentComplete = min(99, max(floorPct, rounded))
        }

        // --- Pace window: [windowStart … today], `window` calendar days inclusive ---
        let todayStart = calendar.startOfDay(for: today)
        let windowStart = calendar.date(byAdding: .day, value: -(window - 1), to: todayStart) ?? todayStart

        // Count mastery stamps falling within [windowStart … todayStart] (normalize
        // each to startOfDay defensively — the stamps are already startOfDay).
        let masteredInWindow = masteryDays.reduce(into: 0) { acc, d in
            let day = calendar.startOfDay(for: d)
            if day >= windowStart && day <= todayStart { acc += 1 }
        }

        // Inclusive elapsed day-span from firstActivity to today, capped at `window`
        // so the denominator matches the windowed event count above (a user active
        // for 100 days still divides by ≤ window). nil firstActivity → no data.
        let elapsed: Int?
        if let first = firstActivity {
            let firstStart = calendar.startOfDay(for: first)
            let span = calendar.dateComponents([.day], from: firstStart, to: todayStart).day ?? 0
            elapsed = min(window, span + 1)
        } else {
            elapsed = nil
        }

        // EARLY-STATE GATE — produce an estimate ONLY with enough data: not already
        // complete, ≥3 days of history (`elapsed`), and ≥3 mastery events in the
        // window. Binding `elapsed` here makes its non-nil-ness lexical (no `!`), and
        // a nil firstActivity falls through to the `else` as "no data". Suppressing
        // otherwise stops a wild "≈900 j" on day one and any divide-by-tiny.
        if !complete, let days = elapsed, days >= 3, masteredInWindow >= 3 {
            let pace = Double(masteredInWindow) / Double(days)
            let remaining = total - mastered
            let daysLeft = Int((Double(remaining) / pace).rounded(.up))
            self.pacePerDay = pace
            self.daysRemaining = daysLeft
            self.projectedFinish = calendar.date(byAdding: .day, value: daysLeft, to: todayStart)
        } else {
            self.pacePerDay = nil
            self.daysRemaining = nil
            self.projectedFinish = nil
        }
    }
}

// MARK: - Self-test

#if DEBUG
extension ProgressEstimate {
    static func _selfTest() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!

        // Fixed reference "today" (deterministic UTC instant).
        let today = Date(timeIntervalSince1970: 1_700_000_000) // a midday instant
        func ago(_ n: Int) -> Date { cal.date(byAdding: .day, value: -n, to: today)! }
        let todayStart = cal.startOfDay(for: today)

        // 1. Fresh / empty.
        let fresh = ProgressEstimate(total: 500, mastered: 0, seen: 0,
                                     masteryDays: [], firstActivity: nil,
                                     today: today, calendar: cal)
        assert(fresh.masteredCount == 0 && fresh.inProgressCount == 0 && fresh.toComeCount == 500,
               "fresh segments (0,0,500)")
        assert(fresh.masteredCount + fresh.inProgressCount + fresh.toComeCount == fresh.total,
               "fresh segments sum to total")
        assert(fresh.percentComplete == 0, "fresh percent 0")
        assert(fresh.hasEstimate == false, "fresh no estimate")
        assert(fresh.pacePerDay == nil && fresh.daysRemaining == nil && fresh.projectedFinish == nil,
               "fresh pace fields nil")

        // 2. Early (<3 days) — firstActivity yesterday → suppressed; percent floors at 1.
        let early = ProgressEstimate(total: 500, mastered: 2, seen: 5,
                                     masteryDays: [ago(1), today],
                                     firstActivity: ago(1),
                                     today: today, calendar: cal)
        assert(early.hasEstimate == false, "early <3 days suppressed")
        // 2/500 = 0.4% → rounds to 0, but floor is 1 because mastered > 0.
        assert(early.percentComplete == 1, "early percent floors at 1, got \(early.percentComplete)")
        assert(early.inProgressCount == 3 && early.toComeCount == 495, "early segments (2,3,495)")

        // 3. Steady pace: 7 distinct days today−6…today, firstActivity today−6d.
        let steadyDays = (0...6).map { ago($0) } // today, today−1 … today−6
        let steady = ProgressEstimate(total: 20, mastered: 10, seen: 14,
                                      masteryDays: steadyDays,
                                      firstActivity: ago(6),
                                      today: today, calendar: cal)
        assert(steady.pacePerDay == 1.0, "steady pace 1.0, got \(String(describing: steady.pacePerDay))")
        assert(steady.daysRemaining == 10, "steady daysRemaining 10, got \(String(describing: steady.daysRemaining))")
        let expectedFinish = cal.date(byAdding: .day, value: 10, to: todayStart)!
        assert(steady.projectedFinish == expectedFinish, "steady projectedFinish = todayStart+10d")
        assert(steady.masteredCount == 10 && steady.inProgressCount == 4 && steady.toComeCount == 6,
               "steady segments (10,4,6)")
        assert(steady.masteredCount + steady.inProgressCount + steady.toComeCount == steady.total,
               "steady segments sum")
        assert(steady.percentComplete == 50, "steady percent 50")

        // 4. Skipped days → elapsed 14 with the SAME 7 mastery days → pace 0.5, longer.
        let skipped = ProgressEstimate(total: 20, mastered: 10, seen: 14,
                                       masteryDays: steadyDays,
                                       firstActivity: ago(13),
                                       today: today, calendar: cal)
        assert(skipped.pacePerDay == 0.5, "skipped pace 0.5, got \(String(describing: skipped.pacePerDay))")
        assert(skipped.daysRemaining == 20, "skipped daysRemaining 20, got \(String(describing: skipped.daysRemaining))")
        assert(skipped.daysRemaining! > steady.daysRemaining!, "skipping lengthens the estimate")

        // 5. Out-of-window stamps (today−30, today−20) must NOT be counted.
        let withOutliers = ProgressEstimate(total: 20, mastered: 10, seen: 14,
                                            masteryDays: steadyDays + [ago(30), ago(20)],
                                            firstActivity: ago(6),
                                            today: today, calendar: cal)
        assert(withOutliers.pacePerDay == steady.pacePerDay,
               "out-of-window stamps excluded → pace unchanged")
        assert(withOutliers.daysRemaining == steady.daysRemaining, "out-of-window daysRemaining unchanged")

        // 6. Near-done: pace 1, remaining 1 → daysRemaining 1.
        let nearDone = ProgressEstimate(total: 20, mastered: 19, seen: 20,
                                        masteryDays: steadyDays,
                                        firstActivity: ago(6),
                                        today: today, calendar: cal)
        assert(nearDone.daysRemaining == 1, "near-done daysRemaining 1, got \(String(describing: nearDone.daysRemaining))")
        assert(nearDone.percentComplete == 95, "near-done percent 95 (19/20)")

        // 7. Done.
        let done = ProgressEstimate(total: 20, mastered: 20, seen: 20,
                                    masteryDays: steadyDays,
                                    firstActivity: ago(6),
                                    today: today, calendar: cal)
        assert(done.isComplete == true, "done isComplete")
        assert(done.percentComplete == 100, "done percent 100")
        assert(done.masteredCount == 20 && done.inProgressCount == 0 && done.toComeCount == 0,
               "done segments (20,0,0)")
        assert(done.hasEstimate == false, "done suppresses estimate")

        // 8. No false 100: 999/1000 not complete → exactly 99.
        let almost = ProgressEstimate(total: 1000, mastered: 999, seen: 1000,
                                      masteryDays: steadyDays,
                                      firstActivity: ago(6),
                                      today: today, calendar: cal)
        assert(almost.isComplete == false, "almost not complete")
        assert(almost.percentComplete == 99, "almost capped at 99, got \(almost.percentComplete)")
    }
}
#endif
