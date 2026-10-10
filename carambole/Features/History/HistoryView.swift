//
//  HistoryView.swift
//  carambole
//
//  "Historique" — motion.html 09 "Liste". Per calendar day, how many grammar
//  elements were learned vs genuinely reviewed, scoped to the current book.
//  No object: two all-time totals, the streak, then one quiet line per day
//  (newest first, rest days kept and greyed) and the "approximatives"
//  footnote. Nothing moves. Self-contained + previewable; navigation is wired
//  elsewhere. (The 3D ribbon moved to the library — `LibraryRibbon.swift`.)
//
import SwiftUI
import Combine

// MARK: - View model

final class HistoryViewModel: ObservableObject {
    /// One row per active day, newest first.
    @Published var days: [DayActivity] = []

    /// One calendar day's activity. Value type so the bucketing is pure + testable.
    struct DayActivity: Identifiable {
        let day: Date
        let learned: Int
        let reviewed: Int
        var id: TimeInterval { day.timeIntervalSince1970 }
    }

    // MARK: Loading

    /// `loadImmediately` fetches on the calling thread so the first frame has
    /// real days. The library needs this: its ribbon is a still drawn from
    /// these days, and starting from `[]` drew a second, different picture
    /// once the async load landed (a visible twist on launch).
    init(loadImmediately: Bool = false) {
        if loadImmediately { days = Self.fetch() }
    }

    /// Fetch the facts off-main, bucket them, then publish on main. Mirrors
    /// `BookViewModel.load()` / `refresh()`.
    func load() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let result = HistoryViewModel.fetch()
            DispatchQueue.main.async {
                self?.days = result
            }
        }
    }

    private static func fetch() -> [DayActivity] {
        let book = ContentLoader.loadBook()
        let bookIDs = Set(book.allElements.map(\.id))
        return activities(
            bookIDs: bookIDs,
            firstSeen: DataManager.shared.fetchFirstSeenByElement(),
            reviewLog: DataManager.shared.fetchReviewLog(),
            calendar: .current
        )
    }

    // MARK: Pure bucketing

    /// Bucket first-seen + review events into per-day activity, scoped to `bookIDs`.
    ///
    /// - `learned` for a day = distinct in-book elements first-seen that day.
    /// - `reviewed` for a day = distinct in-book elements reviewed that day MINUS
    ///   those first-seen that same day (a first sighting is not a re-grade).
    /// Days where both counts are 0 are dropped. Sorted newest-first.
    static func activities(
        bookIDs: Set<String>,
        firstSeen: [String: Date],
        reviewLog: [(elementID: String, dayStart: Date)],
        calendar: Calendar
    ) -> [DayActivity] {
        var learnedByDay: [Date: Set<String>] = [:]
        for (id, date) in firstSeen where bookIDs.contains(id) {
            let day = calendar.startOfDay(for: date)
            learnedByDay[day, default: []].insert(id)
        }

        var reviewedByDay: [Date: Set<String>] = [:]
        for event in reviewLog where bookIDs.contains(event.elementID) {
            // `dayStart` is already a startOfDay value from the data layer.
            reviewedByDay[event.dayStart, default: []].insert(event.elementID)
        }

        let allDays = Set(learnedByDay.keys).union(reviewedByDay.keys)
        return allDays.compactMap { day -> DayActivity? in
            let learned = (learnedByDay[day] ?? []).count
            let reviewed = (reviewedByDay[day] ?? [])
                .subtracting(learnedByDay[day] ?? [])
                .count
            guard learned > 0 || reviewed > 0 else { return nil }
            return DayActivity(day: day, learned: learned, reviewed: reviewed)
        }
        .sorted { $0.day > $1.day }
    }
}


// MARK: - Read-only helpers (history, ribbon window + streak)

extension HistoryViewModel {
    /// Every calendar day from the first recorded activity through today,
    /// oldest first, including rest days. The library ribbon keeps its own
    /// fixed 30-day window below.
    static func allHistory(days: [DayActivity], today: Date,
                           calendar: Calendar) -> [DayActivity] {
        let todayStart = calendar.startOfDay(for: today)
        guard let first = days.map({ calendar.startOfDay(for: $0.day) }).min(),
              first <= todayStart,
              let elapsed = calendar.dateComponents([.day], from: first, to: todayStart).day else {
            return []
        }
        return window(days: days, today: today, count: elapsed + 1, calendar: calendar)
    }

    /// The last `count` calendar days ending `today`, OLDEST first, with
    /// zero-activity entries for rest days. Pure; used by full history and
    /// the library's fixed 30-day ribbon.
    static func window(days: [DayActivity], today: Date, count: Int = 30,
                       calendar: Calendar) -> [DayActivity] {
        let todayStart = calendar.startOfDay(for: today)
        var byDay: [Date: DayActivity] = [:]
        for d in days { byDay[calendar.startOfDay(for: d.day)] = d }
        return (0..<count).reversed().compactMap { back -> DayActivity? in
            guard let day = calendar.date(byAdding: .day, value: -back, to: todayStart) else { return nil }
            return byDay[day] ?? DayActivity(day: day, learned: 0, reviewed: 0)
        }
    }

    /// Current streak: consecutive active days ending today. A not-yet-active
    /// today doesn't break it (the streak then ends yesterday). Pure.
    static func streak(days: [DayActivity], today: Date, calendar: Calendar) -> Int {
        let active = Set(days.filter { $0.learned + $0.reviewed > 0 }
            .map { calendar.startOfDay(for: $0.day) })
        var cursor = calendar.startOfDay(for: today)
        if !active.contains(cursor) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor) else { return 0 }
            cursor = yesterday
        }
        var n = 0
        while active.contains(cursor) {
            n += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return n
    }
}

// MARK: - View

/// Loads the history and shows it as the 09 "Liste" page.
struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HistoryContent(days: viewModel.days, today: Date()) { dismiss() }
            .onAppear { viewModel.load() }
            .toolbar(.hidden, for: .navigationBar)
            .navigationBarBackButtonHidden(true)
    }
}

/// motion.html 09: `‹ Historique` · `Depuis le début`, the two totals, `Série N j`,
/// an ink rule, then all recorded days newest first and the footnote pinned to
/// the bottom. Data-in, so the layout is previewable with fixed days.
struct HistoryContent: View {
    /// All active days, newest first (`HistoryViewModel.days`).
    let days: [HistoryViewModel.DayActivity]
    let today: Date
    let onBack: () -> Void

    /// Full recorded span, NEWEST first, rest days included.
    private var history: [HistoryViewModel.DayActivity] {
        HistoryViewModel.allHistory(days: days, today: today,
                                    calendar: .current).reversed()
    }

    var body: some View {
        let rows = history
        ZStack(alignment: .topLeading) {
            AppColor.paper

            HistoryHeader(learned: rows.reduce(0) { $0 + $1.learned },
                          reviewed: rows.reduce(0) { $0 + $1.reviewed },
                          onBack: onBack)

            if days.isEmpty {
                Text("Pas encore d'activité.")
                    .font(.display(size: 22, wght: 300))
                    .tracking(-0.44)
                    .foregroundColor(AppColor.graphite)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .allowsHitTesting(false)
            } else {
                Text("Série \(HistoryViewModel.streak(days: days, today: today, calendar: .current)) j")
                    .uppercaseLabel(AppColor.ink)
                    .padding(.leading, Spacing.screenH)
                    .padding(.top, 214)
                    .accessibilityLabel("Série de \(HistoryViewModel.streak(days: days, today: today, calendar: .current)) jours")

                dayList(rows)
                    .padding(.top, 252)
                    .padding(.bottom, 84)   // clears the two-line footnote
            }

            Text("Les révisions d'avant cette mise à jour sont approximatives.")
                .uppercaseLabel()
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Spacing.screenH)
                .padding(.bottom, 30)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .allowsHitTesting(false)
                .opacity(days.isEmpty ? 0 : 1)
        }
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .swipeToGoBack { onBack() }
    }

    /// `.days`: ink top rule, then one hairline-separated row per day.
    private func dayList(_ rows: [HistoryViewModel.DayActivity]) -> some View {
        VStack(spacing: 0) {
            Rectangle().fill(AppColor.ink).frame(height: 1)
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(rows.enumerated()), id: \.element.id) { index, day in
                        DayRow(activity: day, isToday: index == 0)
                    }
                }
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
        }
        .padding(.horizontal, Spacing.screenH)
    }
}

// MARK: - Header

/// `‹ Historique` · `Depuis le début`, then the two big totals (motion.html 09).
private struct HistoryHeader: View {
    let learned: Int
    let reviewed: Int
    let onBack: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            Button(action: onBack) {
                Text("‹ Historique")
                    .uppercaseLabel(AppColor.ink)
                    .padding(.vertical, 10)
                    .padding(.trailing, 16)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Retour")
            .padding(.leading, Spacing.screenH)
            .padding(.top, 56)

            Text("Depuis le début")
                .uppercaseLabel()
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, Spacing.screenH)
                .padding(.top, 66)

            HStack(alignment: .top) {
                total(learned, "appris", alignment: .leading)
                Spacer()
                total(reviewed, "révisés", alignment: .trailing)
            }
            .padding(.horizontal, Spacing.screenH)
            .padding(.top, 100)
            .allowsHitTesting(false)
        }
    }

    private func total(_ n: Int, _ label: String, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 8) {
            Text("\(n)")
                .font(.display(size: 64, wght: 200))
                .tracking(-3.2)
                .foregroundColor(AppColor.ink)
                .frame(height: 58)   // CSS line-height .9
            Text(label).uppercaseLabel()
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Day row

/// One line of the list: `Ven. 9 oct. · aujourd’hui` left (Manrope 15 / 400),
/// `6 appris · 14 révisés` label right. A rest day reads `Pause`, all in g3.
struct DayRow: View {
    let activity: HistoryViewModel.DayActivity
    var isToday = false

    private var rest: Bool { activity.learned + activity.reviewed == 0 }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(Self.longDate(activity.day) + (isToday ? " · aujourd’hui" : ""))
                .font(.display(size: 15, wght: 400))
                .foregroundColor(rest ? AppColor.g3 : AppColor.ink)
            Spacer(minLength: 12)
            Text(rest ? "Pause" : "\(activity.learned) appris · \(activity.reviewed) révisés")
                .uppercaseLabel(rest ? AppColor.g3 : AppColor.ink)
        }
        .lineLimit(1)
        .padding(.vertical, 11)
        .overlay(alignment: .bottom) {
            Rectangle().fill(AppColor.hairline).frame(height: 1)
        }
        .accessibilityElement(children: .combine)
    }

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "EEE d MMM"
        return f
    }()

    /// `Ven. 9 oct.`
    static func longDate(_ d: Date) -> String {
        let raw = formatter.string(from: d)
        return raw.prefix(1).capitalized + raw.dropFirst()
    }
}

// MARK: - Self-test

#if DEBUG
extension HistoryViewModel {
    static func _selfTest() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!

        // Fixed, explicit UTC instants (deterministic).
        let day0 = Date(timeIntervalSince1970: 0)              // 1970-01-01 00:00 UTC
        let day0Noon = Date(timeIntervalSince1970: 12 * 3600)  // same day, midday
        let day1 = Date(timeIntervalSince1970: 86_400)         // 1970-01-02 00:00 UTC
        let day2 = Date(timeIntervalSince1970: 2 * 86_400)     // 1970-01-03 00:00 UTC

        let bookIDs: Set<String> = ["a", "b", "c"]

        let firstSeen: [String: Date] = [
            "a": day0,        // learned day0, reviewed same day → reviewed should NOT count
            "b": day0Noon,    // learned day0 too
            "c": day1,        // learned day1
            "x": day0,        // NOT in book → excluded
        ]

        let reviewLog: [(elementID: String, dayStart: Date)] = [
            ("a", cal.startOfDay(for: day0)),   // same day as first-seen → excluded from reviewed
            ("a", cal.startOfDay(for: day2)),   // genuine re-grade on day2
            ("b", cal.startOfDay(for: day2)),   // genuine re-grade on day2
            ("c", cal.startOfDay(for: day1)),   // same day as first-seen → excluded
            ("x", cal.startOfDay(for: day2)),   // NOT in book → excluded
        ]

        let result = activities(bookIDs: bookIDs, firstSeen: firstSeen,
                                reviewLog: reviewLog, calendar: cal)

        // Three active days: day0, day1, day2.
        assert(result.count == 3, "expected 3 active days, got \(result.count)")

        // (d) Newest-first ordering.
        let day0Start = cal.startOfDay(for: day0)
        let day1Start = cal.startOfDay(for: day1)
        let day2Start = cal.startOfDay(for: day2)
        assert(result.map(\.day) == [day2Start, day1Start, day0Start], "newest-first ordering")

        func row(_ day: Date) -> DayActivity { result.first { $0.day == day }! }

        // (a) Learned AND reviewed same day → learned counted, reviewed 0.
        let d0 = row(day0Start)
        assert(d0.learned == 2, "day0 learned=2 (a,b), got \(d0.learned)")
        assert(d0.reviewed == 0, "day0 reviewed=0 (same-day excluded), got \(d0.reviewed)")

        // (c) day1: c learned, its same-day review excluded → reviewed 0.
        let d1 = row(day1Start)
        assert(d1.learned == 1, "day1 learned=1 (c), got \(d1.learned)")
        assert(d1.reviewed == 0, "day1 reviewed=0, got \(d1.reviewed)")

        // (b) day2: genuine re-grades of a,b on a later day; x excluded.
        let d2 = row(day2Start)
        assert(d2.learned == 0, "day2 learned=0, got \(d2.learned)")
        assert(d2.reviewed == 2, "day2 reviewed=2 (a,b), got \(d2.reviewed)")
    }
}
#endif

#if DEBUG
extension HistoryViewModel {
    /// Ribbon window + streak helpers (pure, deterministic UTC calendar).
    static func _selfTestRibbon() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let today = Date(timeIntervalSince1970: 100 * 86_400 + 15 * 3600) // day 100, 15:00
        func day(_ n: Int, _ l: Int, _ r: Int) -> DayActivity {
            DayActivity(day: Date(timeIntervalSince1970: TimeInterval(n) * 86_400), learned: l, reviewed: r)
        }

        // Active 100, 99, 98, rest 97, active 96 → streak 3.
        let days = [day(100, 2, 3), day(99, 1, 0), day(98, 0, 4), day(96, 5, 5)]
        assert(streak(days: days, today: today, calendar: cal) == 3, "streak through today = 3")
        // Today not active yet → the streak still counts up to yesterday.
        assert(streak(days: Array(days.dropFirst()), today: today, calendar: cal) == 2,
               "inactive today keeps yesterday's streak = 2")
        // Yesterday AND today inactive → 0.
        assert(streak(days: [day(96, 1, 1)], today: today, calendar: cal) == 0, "broken streak = 0")
        assert(streak(days: [], today: today, calendar: cal) == 0, "empty = 0")

        // Window: 30 entries, oldest first, today last, gaps filled with zeros.
        let win = window(days: days, today: today, count: 30, calendar: cal)
        assert(win.count == 30, "window has 30 days")
        assert(win.last?.day == cal.startOfDay(for: today), "window ends today")
        assert(win.first?.day == Date(timeIntervalSince1970: 71 * 86_400), "window starts 29 days back")
        assert(win[26].learned + win[26].reviewed == 0, "day 97 is a rest day")
        assert(win[29].learned == 2 && win[29].reviewed == 3, "today's counts carried")
        assert(win.filter { $0.learned + $0.reviewed > 0 }.count == 4, "4 active days in window")

        // Historique reaches activity older than the ribbon's 30-day window.
        let full = allHistory(days: days + [day(50, 7, 8)], today: today, calendar: cal)
        assert(full.count == 51, "history spans first activity through today")
        assert(full.first?.learned == 7 && full.first?.reviewed == 8, "oldest activity retained")
        assert(full[1].learned + full[1].reviewed == 0, "rest days retained")
        assert(full.last?.day == cal.startOfDay(for: today), "history ends today")
        assert(allHistory(days: [], today: today, calendar: cal).isEmpty, "empty history has no rows")
    }
}
#endif

// MARK: - Preview

#Preview {
    HistoryView()
}
