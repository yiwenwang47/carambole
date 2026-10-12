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
    /// *En situation* only: wrong attempts by day, newest first (`loadMistakes`).
    @Published var mistakes: [MistakeDay] = []

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
    /// The book whose days this model counts (history is per book).
    let descriptor: BookDescriptor
    /// Element IDs of `descriptor`, loaded once.
    private var bookIDs: Set<String>?

    init(book: BookDescriptor = BookCatalog.fondations, loadImmediately: Bool = false) {
        self.descriptor = book
        if loadImmediately {
            let ids = Self.elementIDs(book)
            bookIDs = ids
            days = Self.fetch(bookIDs: ids)
        }
    }

    /// Fetch the facts off-main, bucket them, then publish on main. Mirrors
    /// `BookViewModel.load()` / `refresh()`.
    func load() {
        let descriptor = self.descriptor
        let known = bookIDs
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let ids = known ?? HistoryViewModel.elementIDs(descriptor)
            let result = HistoryViewModel.fetch(bookIDs: ids)
            DispatchQueue.main.async {
                self?.bookIDs = ids
                self?.days = result
            }
        }
    }

    private static func elementIDs(_ book: BookDescriptor) -> Set<String> {
        Set(ContentLoader.loadBook(book).allElements.map(\.id))
    }

    private static func fetch(bookIDs: Set<String>) -> [DayActivity] {
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


// MARK: - Mistake log (*En situation*)

extension HistoryViewModel {
    /// One wrong attempt from `situation_attempt_log`, labelled for display.
    struct MistakeEntry: Identifiable, Equatable {
        let id: Int
        let date: Date
        /// Drill name as the session showed it ("Corriger", or a standalone label).
        let title: String
        /// The move (element) it belongs to.
        let move: String
        let given: String
        let expected: String
        let why: String?
    }

    /// One calendar day of mistakes, newest attempt first.
    struct MistakeDay: Identifiable, Equatable {
        let day: Date
        let entries: [MistakeEntry]
        var id: TimeInterval { day.timeIntervalSince1970 }
    }

    /// Whether this book keeps a mistake log (only *En situation* does).
    var hasMistakeLog: Bool { descriptor.kind == .situation }

    /// Loads the book's attempt log off-main. Called by the History page only,
    /// so the shelf's ribbon models never pay for it.
    func loadMistakes() {
        guard hasMistakeLog else { return }
        let descriptor = self.descriptor
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let book = ContentLoader.loadBook(descriptor)
            var moves: [String: String] = [:]
            var standalone: [String: String] = [:]
            for element in book.allElements {
                moves[element.id] = element.label
                for item in element.items { standalone[item.id] = item.standalone }
            }
            let result = HistoryViewModel.mistakeDays(
                attempts: DataManager.shared.fetchSituationAttempts(bookID: descriptor.id),
                moves: moves, standalone: standalone, calendar: .current)
            DispatchQueue.main.async { self?.mistakes = result }
        }
    }

    /// Buckets attempts (any order) into calendar days, newest day first and
    /// newest attempt first within a day. The title matches the session's:
    /// a standalone item's label, else the drill type's French name. Pure.
    static func mistakeDays(attempts: [DataManager.SituationAttempt], moves: [String: String],
                            standalone: [String: String], calendar: Calendar) -> [MistakeDay] {
        let entries = attempts.enumerated().map { i, a in
            MistakeEntry(
                id: i, date: a.createdAt,
                title: standalone[a.dialogueID] ?? SituationDrill.Kind(rawValue: a.drillType)?.title ?? a.drillType,
                move: moves[a.elementID] ?? "",
                given: a.given, expected: a.expected, why: a.reason)
        }
        let byDay = Dictionary(grouping: entries) { calendar.startOfDay(for: $0.date) }
        return byDay
            .map { day, list in
                MistakeDay(day: day, entries: list.sorted { ($0.date, $1.id) > ($1.date, $0.id) })
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
    @StateObject private var viewModel: HistoryViewModel
    @Environment(\.dismiss) private var dismiss

    init(book: BookDescriptor = BookCatalog.fondations) {
        _viewModel = StateObject(wrappedValue: HistoryViewModel(book: book))
    }

    var body: some View {
        HistoryContent(days: viewModel.days, today: Date(),
                       mistakes: viewModel.hasMistakeLog ? viewModel.mistakes : nil) { dismiss() }
            .onAppear {
                viewModel.load()
                viewModel.loadMistakes()
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationBarBackButtonHidden(true)
    }
}

/// motion.html 09: `‹ Historique` · `Depuis le début`, the two totals, `Série N j`,
/// an ink rule, then all recorded days newest first and the footnote pinned to
/// the bottom. Data-in, so the layout is previewable with fixed days.
/// *En situation* adds its mistake log: a `Jours · Erreurs` switch on the
/// Série line swaps the day list for the wrong attempts, by day.
struct HistoryContent: View {
    /// All active days, newest first (`HistoryViewModel.days`).
    let days: [HistoryViewModel.DayActivity]
    let today: Date
    /// Wrong attempts by day, newest first; nil when the book keeps no log.
    var mistakes: [HistoryViewModel.MistakeDay]? = nil
    let onBack: () -> Void

    @State private var showMistakes = false

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
                HStack(alignment: .firstTextBaseline) {
                    Text("Série \(HistoryViewModel.streak(days: days, today: today, calendar: .current)) j")
                        .uppercaseLabel(AppColor.ink)
                        .accessibilityLabel("Série de \(HistoryViewModel.streak(days: days, today: today, calendar: .current)) jours")
                    Spacer()
                    if let mistakes {
                        listSwitch(mistakeCount: mistakes.reduce(0) { $0 + $1.entries.count })
                    }
                }
                .padding(.horizontal, Spacing.screenH)
                .padding(.top, 214)

                Group {
                    if let mistakes, showMistakes {
                        mistakeList(mistakes)
                    } else {
                        dayList(rows)
                    }
                }
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
        #if DEBUG
        // Simulator checks: CB_HISTORY_TAB=erreurs opens the mistake log.
        .onAppear {
            if mistakes != nil, ProcessInfo.processInfo.environment["CB_HISTORY_TAB"] == "erreurs" {
                showMistakes = true
            }
        }
        #endif
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

    /// `Jours · Erreurs N`: two quiet labels; the shown list is ink.
    private func listSwitch(mistakeCount: Int) -> some View {
        HStack(spacing: 14) {
            switchLabel("Jours", selected: !showMistakes) { showMistakes = false }
            switchLabel("Erreurs · \(mistakeCount)", selected: showMistakes) { showMistakes = true }
                .accessibilityLabel("Erreurs, \(mistakeCount)")
        }
    }

    private func switchLabel(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .uppercaseLabel(selected ? AppColor.ink : AppColor.g2)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, -8)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    /// The mistake log: same ink rule and hairline rows as the day list. Each
    /// day reads `Ven. 9 oct.` · `N erreurs`, then its attempts, newest first,
    /// each under its move's name.
    private func mistakeList(_ mistakeDays: [HistoryViewModel.MistakeDay]) -> some View {
        VStack(spacing: 0) {
            Rectangle().fill(AppColor.ink).frame(height: 1)
            if mistakeDays.isEmpty {
                Text("Aucune erreur.")
                    .font(.display(size: 15, wght: 400))
                    .foregroundColor(AppColor.graphite)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 11)
            }
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(mistakeDays) { day in
                        HStack(alignment: .firstTextBaseline) {
                            Text(DayRow.longDate(day.day))
                                .font(.display(size: 15, wght: 400))
                                .foregroundColor(AppColor.ink)
                            Spacer(minLength: 12)
                            Text(day.entries.count == 1 ? "1 erreur" : "\(day.entries.count) erreurs")
                                .uppercaseLabel(AppColor.ink)
                        }
                        .lineLimit(1)
                        .padding(.top, 14)
                        .padding(.bottom, 4)
                        .accessibilityElement(children: .combine)
                        .accessibilityAddTraits(.isHeader)
                        ForEach(day.entries) { entry in
                            VStack(alignment: .leading, spacing: 4) {
                                if !entry.move.isEmpty {
                                    Text(entry.move)
                                        .font(.display(size: 13, wght: 500))
                                        .foregroundColor(AppColor.ink)
                                }
                                SituationMistakeRow(title: entry.title, given: entry.given,
                                                    expected: entry.expected, why: entry.why)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 10)
                            .overlay(alignment: .bottom) {
                                Rectangle().fill(AppColor.hairline).frame(height: 1)
                            }
                            .accessibilityElement(children: .combine)
                        }
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

        _selfTestMistakes(cal)
    }

    /// Mistake log bucketing: days newest first, attempts newest first within
    /// a day, standalone label over the drill name, unknown type kept raw.
    private static func _selfTestMistakes(_ cal: Calendar) {
        func attempt(_ t: TimeInterval, _ element: String, _ item: String, _ type: String) -> DataManager.SituationAttempt {
            .init(bookID: "b", elementID: element, dialogueID: item, drillType: type,
                  given: "g\(Int(t))", expected: "e", reason: nil, createdAt: Date(timeIntervalSince1970: t))
        }
        let attempts = [
            attempt(100, "sit_m", "d01", "fix"),                 // day 0, earlier
            attempt(86_400 + 50, "sit_m", "s01", "reply"),       // day 1 (standalone)
            attempt(200, "sit_m", "d02", "pick"),                // day 0, later
            attempt(300, "sit_x", "d03", "mystery"),             // day 0, unknown move + type
        ]
        let days = mistakeDays(attempts: attempts, moves: ["sit_m": "Commander"],
                               standalone: ["s01": "Construire"], calendar: cal)
        assert(days.count == 2, "two mistake days")
        assert(days.first?.day == cal.startOfDay(for: Date(timeIntervalSince1970: 86_400)), "newest day first")
        assert(days[0].entries.map(\.title) == ["Construire"], "standalone label wins")
        assert(days[1].entries.map(\.given) == ["g300", "g200", "g100"], "newest attempt first in a day")
        assert(days[1].entries.map(\.title) == ["mystery", "Choisir", "Corriger"], "drill names")
        assert(days[1].entries[0].move.isEmpty && days[1].entries[1].move == "Commander", "move labels")
        assert(mistakeDays(attempts: [], moves: [:], standalone: [:], calendar: cal).isEmpty, "no attempts → no days")
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
