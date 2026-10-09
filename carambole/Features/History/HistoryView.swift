//
//  HistoryView.swift
//  carambole
//
//  "Historique" — motion.html 05 "Ruban". Per calendar day, how many grammar
//  elements were learned vs genuinely reviewed, scoped to the current book.
//  The last 30 days are drawn as a twisted paper ribbon (`RibbonView.swift`);
//  scrolling down reaches the exact per-day list + the "approximatives"
//  footnote. Self-contained + previewable; navigation is wired elsewhere.
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

    /// Fetch the facts off-main, bucket them, then publish on main. Mirrors
    /// `BookViewModel.load()` / `refresh()`.
    func load() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let book = ContentLoader.loadBook()
            let bookIDs = Set(book.allElements.map(\.id))
            let firstSeen = DataManager.shared.fetchFirstSeenByElement()
            let reviewLog = DataManager.shared.fetchReviewLog()
            let result = HistoryViewModel.activities(
                bookIDs: bookIDs,
                firstSeen: firstSeen,
                reviewLog: reviewLog,
                calendar: .current
            )
            DispatchQueue.main.async {
                self?.days = result
            }
        }
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


// MARK: - Read-only helpers (ribbon window + streak)

extension HistoryViewModel {
    /// The last `count` calendar days ending `today`, OLDEST first, with
    /// zero-activity entries for rest days. Pure; feeds the ribbon.
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

/// Loads the history and shows it as the 05 "Ruban" page.
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

/// motion.html 05 "Ruban": a full-screen ribbon page (header numerals,
/// 3D ribbon, scrub readout, streak + legend), then — scrolling down — the
/// exact per-day list and the "approximatives" footnote. Data-in, so the
/// layout is previewable with fixed days.
struct HistoryContent: View {
    /// All active days, newest first (`HistoryViewModel.days`).
    let days: [HistoryViewModel.DayActivity]
    let today: Date
    let onBack: () -> Void

    @State private var selected: Int

    init(days: [HistoryViewModel.DayActivity], today: Date,
         initialSelection: Int = RibbonPage.windowDays - 1,
         onBack: @escaping () -> Void) {
        self.days = days
        self.today = today
        self.onBack = onBack
        _selected = State(initialValue: initialSelection)
    }

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 0) {
                    if days.isEmpty {
                        emptyPage(size: geo.size)
                    } else {
                        RibbonPage(days: days, today: today, size: geo.size,
                                   selected: $selected, onBack: onBack)
                        HistoryDayList(days: days, onBack: onBack)
                    }
                }
            }
            .scrollIndicators(.hidden)
            .scrollDisabled(days.isEmpty)
        }
        .ignoresSafeArea()
        .background(AppColor.paper.ignoresSafeArea())
        .onChange(of: days.first?.id) { selected = RibbonPage.windowDays - 1 }
    }

    // MARK: Empty state

    private func emptyPage(size: CGSize) -> some View {
        ZStack(alignment: .topLeading) {
            Color.clear
            HistoryHeader(learned: 0, reviewed: 0, onBack: onBack)
            Text("Pas encore d'activité.")
                .font(.display(size: 22, wght: 300))
                .tracking(-0.44)
                .foregroundColor(AppColor.graphite)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: size.width, height: size.height)
        .contentShape(Rectangle())
        .swipeToGoBack { onBack() }
    }
}

// MARK: - Day list

/// The exact per-day list below the ribbon (all history, newest first) and
/// the "approximatives" footnote.
struct HistoryDayList: View {
    let days: [HistoryViewModel.DayActivity]
    let onBack: () -> Void

    private var maxTotal: Int {
        days.map { $0.learned + $0.reviewed }.max() ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Jour par jour")
                .uppercaseLabel(AppColor.ink)
                .padding(.bottom, 10)
            Rectangle().fill(AppColor.ink).frame(height: 1)
            ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                DayRow(activity: day, maxTotal: maxTotal)
                if index < days.count - 1 {
                    Rectangle().fill(AppColor.hairline).frame(height: 1)
                }
            }
            Text("Les révisions d'avant cette mise à jour sont approximatives.")
                .uppercaseLabel()
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, Spacing.lg)
        }
        .padding(.horizontal, Spacing.screenH)
        .padding(.top, 48)
        .padding(.bottom, 64)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .swipeToGoBack { onBack() }
    }
}

// MARK: - Header

/// `‹ Historique` · `30 jours`, then the two big totals (motion.html 05).
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

            Text("30 jours")
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

// MARK: - Ribbon page

/// The first, full-screen part of the page: the ribbon and its overlays.
struct RibbonPage: View {
    static let windowDays = 30

    let days: [HistoryViewModel.DayActivity]
    let today: Date
    let size: CGSize
    @Binding var selected: Int
    let onBack: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var motion = RibbonMotion()
    @State private var lastDragX: CGFloat?
    @State private var haptic = UISelectionFeedbackGenerator()

    private var window: [HistoryViewModel.DayActivity] {
        HistoryViewModel.window(days: days, today: today, count: Self.windowDays, calendar: .current)
    }

    var body: some View {
        let win = window
        let geo = RibbonGeometry(totals: win.map { $0.learned + $0.reviewed })
        let h = size.height
        let sel = min(max(0, selected), win.count - 1)

        ZStack(alignment: .topLeading) {
            RibbonScene(geometry: geo, motion: motion, selected: sel)
                .id(geo.totals)
                .allowsHitTesting(false)
                .accessibilityHidden(true)

            // Margins: swipe-back + page scroll. The ribbon column on top owns
            // its touches, so turning the ribbon never pops the screen.
            Color.clear
                .contentShape(Rectangle())
                .swipeToGoBack { onBack() }

            scrubColumn(geo: geo, win: win)

            // .ribline: follows the selected day's projected height each frame.
            TimelineView(.animation) { _ in
                let y = RibbonGeometry.screenY(of: RibbonGeometry.spine(geo.s(ofDay: sel)),
                                               angle: motion.angle, height: h)
                Rectangle()
                    .fill(AppColor.ink)
                    .frame(width: 54, height: 1)
                    .offset(x: Spacing.screenH, y: y)
            }
            .allowsHitTesting(false)

            HistoryHeader(learned: win.reduce(0) { $0 + $1.learned },
                          reviewed: win.reduce(0) { $0 + $1.reviewed },
                          onBack: onBack)

            Text("\(Self.shortDate(win.first?.day ?? today)) ↓")
                .uppercaseLabel()
                .padding(.leading, Spacing.screenH)
                .padding(.top, 214)
                .allowsHitTesting(false)

            bottom(win: win, sel: sel)
        }
        .frame(width: size.width, height: h)
        .clipped()
        .coordinateSpace(name: "ribbonPage")
        .onAppear { motion.reduceMotion = reduceMotion }
        .onChange(of: reduceMotion) { motion.reduceMotion = reduceMotion }
    }

    // MARK: Scrub + turn

    /// Vertical position scrubs the day; horizontal drag turns the ribbon.
    private func scrubColumn(geo: RibbonGeometry, win: [HistoryViewModel.DayActivity]) -> some View {
        let w = size.width, h = size.height
        return Color.clear
            .contentShape(Rectangle())
            .frame(width: w * 0.7, height: h * 0.75)
            .offset(x: w * 0.15, y: h * 0.13)
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .named("ribbonPage"))
                    .onChanged { v in
                        if lastDragX == nil { haptic.prepare() }
                        let dx = v.location.x - (lastDragX ?? v.location.x)
                        lastDragX = v.location.x
                        motion.turnTarget = min(1.2, max(-1.2, motion.turnTarget + Float(dx) * 0.01))
                        let i = geo.day(nearestScreenY: v.location.y, angle: motion.angle, height: h)
                        if i != selected {
                            selected = i
                            haptic.selectionChanged()
                        }
                    }
                    .onEnded { _ in
                        lastDragX = nil
                        motion.turnTarget = 0
                    }
            )
            .accessibilityElement()
            .accessibilityLabel("Ruban des 30 derniers jours")
            .accessibilityValue(readoutA11y(win: win))
            .accessibilityAdjustableAction { dir in
                switch dir {
                case .increment: selected = min(win.count - 1, selected + 1)
                case .decrement: selected = max(0, selected - 1)
                @unknown default: break
                }
            }
    }

    // MARK: Readout + legend

    private func bottom(win: [HistoryViewModel.DayActivity], sel: Int) -> some View {
        let day = win[sel]
        let isToday = sel == win.count - 1
        let rest = day.learned + day.reviewed == 0
        return VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 0)
            VStack(alignment: .leading, spacing: 6) {
                Text(Self.longDate(day.day) + (isToday ? " · aujourd’hui" : ""))
                    .uppercaseLabel(AppColor.ink)
                Text(rest ? "Pause" : "\(day.learned) appris · \(day.reviewed) révisés")
                    .font(.display(size: 22, wght: 300))
                    .tracking(-0.44)
                    .foregroundColor(AppColor.ink)
            }
            .padding(.bottom, 66 - 30 - 13)   // readout bottom 66, legend bottom 30
            HStack {
                Text("Série \(HistoryViewModel.streak(days: days, today: today, calendar: .current)) j")
                    .uppercaseLabel(AppColor.ink)
                Spacer()
                Text("Largeur = travail · torsion = pause")
                    .uppercaseLabel()
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, Spacing.screenH)
        .padding(.bottom, 30)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .allowsHitTesting(false)
    }

    private func readoutA11y(win: [HistoryViewModel.DayActivity]) -> String {
        let d = win[min(max(0, selected), win.count - 1)]
        let counts = d.learned + d.reviewed == 0 ? "pause"
            : "\(d.learned) appris, \(d.reviewed) révisés"
        return "\(Self.longDate(d.day)), \(counts)"
    }

    // MARK: Dates

    private static let longFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "EEE d MMM"
        return f
    }()

    private static let shortFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "d MMM"
        return f
    }()

    /// `Jeu. 8 oct.`
    static func longDate(_ d: Date) -> String {
        let raw = longFormatter.string(from: d)
        return raw.prefix(1).capitalized + raw.dropFirst()
    }

    /// `10 sept.`
    static func shortDate(_ d: Date) -> String { shortFormatter.string(from: d) }
}

// MARK: - Day row

/// One exact line of the list below the ribbon: date, counts, and a hairline
/// bar (learned = ink, reviewed = g3) scaled to the busiest day.
struct DayRow: View {
    let activity: HistoryViewModel.DayActivity
    let maxTotal: Int

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "EEE d MMMM"
        return f
    }()

    private var dateLabel: String {
        let raw = DayRow.dateFormatter.string(from: activity.day)
        return raw.prefix(1).capitalized + raw.dropFirst()
    }

    private var countsLabel: String {
        "\(activity.learned) appris · \(activity.reviewed) révisés"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(dateLabel)
                    .font(.display(size: 17, wght: 300))
                    .tracking(-0.2)
                    .foregroundColor(AppColor.ink)
                Spacer()
                Text(countsLabel)
                    .uppercaseLabel()
            }
            bar
        }
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    /// Learned (ink) + reviewed (g3), the whole bar's width proportional to
    /// this day's total vs the busiest day.
    private var bar: some View {
        GeometryReader { geo in
            let total = activity.learned + activity.reviewed
            let fraction = maxTotal > 0 ? CGFloat(total) / CGFloat(maxTotal) : 0
            let fullWidth = geo.size.width * fraction
            let learnedWidth = total > 0 ? fullWidth * CGFloat(activity.learned) / CGFloat(total) : 0
            let reviewedWidth = max(0, fullWidth - learnedWidth)

            HStack(spacing: 0) {
                Rectangle().fill(AppColor.ink).frame(width: learnedWidth)
                Rectangle().fill(AppColor.g3).frame(width: reviewedWidth)
                Spacer(minLength: 0)
            }
        }
        .frame(height: 2)
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
    }
}
#endif

// MARK: - Preview

#Preview {
    HistoryView()
}
