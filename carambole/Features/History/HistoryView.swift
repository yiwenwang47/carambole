//
//  HistoryView.swift
//  carambole
//
//  A separate "Progrès · Historique" page: per calendar day (newest first) how
//  many grammar elements were learned vs genuinely reviewed that day, scoped to
//  the current book. Self-contained + previewable; navigation is wired elsewhere.
//  Built from "Le Cahier".
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

// MARK: - View

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @Environment(\.dismiss) private var dismiss

    /// Largest combined (learned + reviewed) total — the bar-width denominator.
    private var maxTotal: Int {
        viewModel.days.map { $0.learned + $0.reviewed }.max() ?? 0
    }

    var body: some View {
        ZStack {
            AppColor.paper.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    header

                    if viewModel.days.isEmpty {
                        emptyState
                    } else {
                        dayList
                        footnote
                    }
                }
                .padding(.horizontal, Spacing.screenH)
                .padding(.top, 72)
                .padding(.bottom, Spacing.xl)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .onAppear { viewModel.load() }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColor.graphite)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.trailing, Spacing.sm)
            .accessibilityLabel("Retour")

            VStack(alignment: .leading, spacing: Spacing.sm) {
                SectionLabel("Progrès")
                Text("Historique")
                    .font(.appTitle)
                    .foregroundColor(AppColor.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(.bottom, Spacing.sm)
    }

    // MARK: Day list

    private var dayList: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(viewModel.days.enumerated()), id: \.element.id) { index, day in
                DayRow(activity: day, maxTotal: maxTotal)
                if index < viewModel.days.count - 1 {
                    Rectangle().fill(AppColor.hairline).frame(height: 1)
                }
            }
        }
    }

    // MARK: Footnote

    private var footnote: some View {
        Text("Les révisions d'avant cette mise à jour sont approximatives.")
            .uppercaseLabel()
            .foregroundColor(AppColor.graphite)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, Spacing.sm)
    }

    // MARK: Empty state

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Text("Pas encore d'activité.")
                .font(.appExplain)
                .foregroundColor(AppColor.graphite)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Spacing.xl)
    }
}

// MARK: - Day row

private struct DayRow: View {
    let activity: HistoryViewModel.DayActivity
    let maxTotal: Int

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "d MMMM"
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
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                Text(dateLabel)
                    .font(.appTitle)
                    .foregroundColor(AppColor.ink)
                Spacer()
                Text(countsLabel)
                    .uppercaseLabel()
            }
            bar
        }
        .padding(.vertical, Spacing.md)
        .contentShape(Rectangle())
    }

    /// A subtle proportional bar: learned (saffron) + reviewed (hairline), the
    /// whole bar's width proportional to this day's total vs the busiest day.
    private var bar: some View {
        GeometryReader { geo in
            let total = activity.learned + activity.reviewed
            let fraction = maxTotal > 0 ? CGFloat(total) / CGFloat(maxTotal) : 0
            let fullWidth = geo.size.width * fraction
            let learnedWidth = total > 0 ? fullWidth * CGFloat(activity.learned) / CGFloat(total) : 0
            let reviewedWidth = max(0, fullWidth - learnedWidth)

            HStack(spacing: 0) {
                Rectangle()
                    .fill(AppColor.saffron)
                    .frame(width: learnedWidth)
                Rectangle()
                    .fill(AppColor.hairline)
                    .frame(width: reviewedWidth)
                Spacer(minLength: 0)
            }
            .clipShape(Capsule())
        }
        .frame(height: 5)
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

// MARK: - Preview

#Preview {
    HistoryView()
}
