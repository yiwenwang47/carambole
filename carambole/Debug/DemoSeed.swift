//
//  DemoSeed.swift
//  carambole
//
//  DEBUG only. Launch with `CB_SEED_DEMO=1` in the environment (simulator:
//  `SIMCTL_CHILD_CB_SEED_DEMO=1 xcrun simctl launch <sim> wen.carambole`) to
//  fill an EMPTY store with a realistic mid-course learner, so visual checks
//  never run on blank progress:
//
//  - all 500 elements seen over ~9 weeks, the first 381 graduated (76 %, 19
//    modules done), the rest en cours;
//  - 20 elements first seen today and 50 genuine reviews today;
//  - a handful of reviews due now, graduations inside the 14-day pace window.
//
//  A store that already has rows is left untouched.
//

#if DEBUG
import Foundation

enum DemoSeed {
    static let masteredCount = 381
    static let learnedToday = 20
    static let reviewedToday = 50
    static let dueNow = 12

    static func runIfRequested() {
        guard ProcessInfo.processInfo.environment["CB_SEED_DEMO"] == "1" else { return }
        let data = DataManager.shared
        guard data.fetchSeenElementIDs().isEmpty else {
            print("DemoSeed: store not empty — skipped")
            return
        }
        let elements = ContentLoader.loadBook().allElements
        guard elements.count > masteredCount + learnedToday else {
            print("DemoSeed: book too small (\(elements.count) elements) — skipped")
            return
        }
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        func day(_ offset: Int, hour: Int = 19) -> Date {
            let start = calendar.date(byAdding: .day, value: offset, to: today) ?? today
            return calendar.date(byAdding: .hour, value: hour, to: start) ?? start
        }
        /// A moment earlier today (fraction 0…1 of the time since midnight), so
        /// "today" rows stay today even just after midnight.
        func earlierToday(_ fraction: Double) -> Date {
            today.addingTimeInterval(now.timeIntervalSince(today) * min(max(fraction, 0.05), 0.95))
        }

        let olderSeen = elements.count - learnedToday
        for (index, element) in elements.enumerated() {
            let examples = element.examples.map(\.id)
            // First sighting: graduated elements −62…−22 days, the rest −21…−1,
            // the last `learnedToday` today (stamps first_seen_date + review_log).
            let firstSeen: Date
            if index >= olderSeen {
                firstSeen = earlierToday(Double(index - olderSeen) / Double(learnedToday) * 0.5)
            } else if index < masteredCount {
                firstSeen = day(-62 + index * 41 / masteredCount)
            } else {
                firstSeen = day(-21 + (index - masteredCount) * 21 / (olderSeen - masteredCount))
            }
            var status = ReviewStatus(elementID: element.id, learningState: .learning, intervalDays: 1)
            status.lastReviewDate = firstSeen
            status.nextReviewDate = calendar.date(byAdding: .day, value: 1, to: firstSeen)
            status.recordCorrect(exampleID: examples.first ?? element.id)
            status.stability = 1.5
            status.difficulty = 5.5
            data.upsertReviewStatus(status)
            if index >= olderSeen { continue }

            // Latest review. The 50 reviewed today come from the newest older
            // elements; `dueNow` of the graduated ones are overdue.
            let reviewedTodayRange = (olderSeen - reviewedToday)..<olderSeen
            let lastReview: Date
            if reviewedTodayRange.contains(index) {
                lastReview = earlierToday(0.5 + Double(index % reviewedToday) / Double(reviewedToday) * 0.45)
            } else {
                let mid = calendar.dateComponents([.day], from: firstSeen, to: today).day ?? 1
                lastReview = day(-max(1, mid / 3))
            }
            let graduated = index < masteredCount
            status.lastReviewDate = lastReview
            status.learningState = graduated ? .learned : .learning
            for id in examples.prefix(graduated ? 4 : 2) { status.recordCorrect(exampleID: id) }
            status.stability = graduated ? 24 + Double(index % 30) : 4 + Double(index % 6)
            status.difficulty = 4 + Double(index % 4) * 0.5
            let interval = graduated ? 21 + index % 20 : 2 + index % 5
            status.intervalDays = interval
            let overdue = graduated && index % (masteredCount / dueNow) == 0
            status.nextReviewDate = overdue
                ? calendar.date(byAdding: .hour, value: -3, to: now)
                : calendar.date(byAdding: .day, value: interval, to: max(lastReview, today))
            data.upsertReviewStatus(status)
            if graduated {
                data.markGraduated(elementID: element.id,
                                   on: min(day(-1), calendar.date(byAdding: .day, value: 21, to: firstSeen) ?? now))
            }
        }
        // Drain the serial write queue before the UI reads.
        _ = data.fetchSeenElementIDs()
        print("DemoSeed: seeded \(elements.count) elements, \(masteredCount) graduated")
    }
}
#endif
