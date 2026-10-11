import Foundation

/// Grades one answer on its ELEMENT with FSRS and persists it. Shared by both
/// drill loops: *Fondations* (`DrillSessionView`, one example sentence) and
/// *En situation* (`SituationSessionView`, one dialogue or standalone item).
enum ElementGrader {
    /// Fetch-or-fresh the element's `ReviewStatus`, advance `(S, D)` via `FSRS.next`
    /// (or seed via `FSRS.initialState` on the first-ever review), write back
    /// stability/difficulty + the FSRS-computed next-review date, then persist (the
    /// upsert also logs a `review_log` row, keeping the History page working). On a
    /// SUCCESSFUL grade that pushes `S` past the graduation bar, stamp the sticky
    /// `graduated_date` via `markGraduated` (idempotent) — but only if
    /// `graduationGate` (when given) also holds for the updated status. Book 2 uses
    /// the gate for its 3-item / 2-drill-type rule. Reads/writes run on the
    /// database's serial queue, so a follow-up read sees this.
    static func grade(elementID: String, exampleID: String, rating: FSRS.Rating, now: Date = Date(),
                      graduationGate: ((ReviewStatus) -> Bool)? = nil) {
        var status = DataManager.shared.fetchReviewStatus(elementID: elementID)
            ?? ReviewStatus(elementID: elementID)
        let correct = rating != .again

        // Distinct-correct bookkeeping (Book 1: non-gating, History/back-compat;
        // Book 2: the distinct items behind the mastery gate).
        if correct { status.recordCorrect(exampleID: exampleID) }

        // FSRS state: first-ever review (no S yet) → seed; otherwise advance over the
        // calendar-day gap since the last review (0 if never reviewed / same day).
        let newState: FSRS.State
        if let s = status.stability, let d = status.difficulty {
            let elapsed = CalendarDays.elapsed(from: status.lastReviewDate, to: now)
            newState = FSRS.next(FSRS.State(stability: s, difficulty: d),
                                 elapsedDays: elapsed, rating: rating)
        } else {
            newState = FSRS.initialState(rating: rating)
        }
        status.stability = newState.stability
        status.difficulty = newState.difficulty
        status.lastReviewDate = now
        // NOTE: `learning_state` is intentionally NOT maintained under FSRS — it's
        // non-gating now (S/D + graduated_date drive everything); it stays at its
        // fetched/seed value and is read only by the one-time v4 backfill.
        // Next review when predicted recall decays to desiredRetention; round to whole
        // days (≥1) so the due-queue's date math stays day-granular, mirroring the old
        // integer-interval scheduling. interval_days is kept in sync for overflow order.
        let intervalDays = max(1, Int(FSRS.intervalDays(stability: newState.stability).rounded()))
        status.intervalDays = intervalDays
        status.nextReviewDate = Calendar.current.date(byAdding: .day, value: intervalDays, to: now) ?? now

        DataManager.shared.upsertReviewStatus(status)

        // Graduation hook: only on success, only once S crosses the 21-day bar, and
        // only when the book's own gate holds. Idempotent.
        if correct && newState.stability >= FSRS.graduationStability
            && (graduationGate?(status) ?? true) {
            DataManager.shared.markGraduated(elementID: elementID, on: now)
        }
    }
}
