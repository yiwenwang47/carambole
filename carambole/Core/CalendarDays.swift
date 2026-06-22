import Foundation

/// The single I/O-layer bridge from a pair of `Date`s to the `elapsedDays` that the
/// pure `FSRS` core consumes. `FSRS` is deliberately date-free (no `Date()` /
/// `Calendar.current` in its logic path), so every place that needs "how many days
/// since the last review" routes through here instead of hand-rolling the day math —
/// keeping one start-of-day rule and avoiding the drift that copy-pasted date code
/// invites.
///
/// Returns the NON-NEGATIVE whole-day gap counted start-of-day to start-of-day. A nil
/// `from` (never reviewed) or a same-day `to` → 0. `calendar` is injectable so callers
/// (and the self-test) stay deterministic.
enum CalendarDays {
    static func elapsed(from: Date?, to: Date, calendar: Calendar = .current) -> Double {
        guard let from else { return 0 }
        let days = calendar.dateComponents([.day],
                                           from: calendar.startOfDay(for: from),
                                           to: calendar.startOfDay(for: to)).day ?? 0
        return Double(max(0, days))
    }
}

#if DEBUG
extension CalendarDays {
    static func _selfTest() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let t0 = Date(timeIntervalSince1970: 1_700_000_000)
        func plus(_ n: Int) -> Date { cal.date(byAdding: .day, value: n, to: t0)! }

        assert(CalendarDays.elapsed(from: nil, to: t0, calendar: cal) == 0, "nil from → 0")
        assert(CalendarDays.elapsed(from: t0, to: t0, calendar: cal) == 0, "same instant → 0")
        // Same calendar day, hours apart → still 0 (start-of-day to start-of-day).
        assert(CalendarDays.elapsed(from: t0, to: t0.addingTimeInterval(3600), calendar: cal) == 0,
               "same day, +1h → 0")
        assert(CalendarDays.elapsed(from: t0, to: plus(1), calendar: cal) == 1, "+1 day → 1")
        assert(CalendarDays.elapsed(from: t0, to: plus(14), calendar: cal) == 14, "+14 days → 14")
        // Reversed (clock skew / future last-review) clamps to 0, never negative.
        assert(CalendarDays.elapsed(from: plus(3), to: t0, calendar: cal) == 0, "reversed → 0 (clamped)")
    }
}
#endif
