//
//  BookViewModel.swift
//  carambole
//
//  Drives the book home: loads the in-memory Book from bundle JSON, derives the
//  daily new/due counts (in ELEMENTS), and computes per-module unlock + mastery
//  state from the SRS `review_status`. Content is not persisted; only progress is.
//

import Foundation
import Combine

/// Row state for a module in the book.
enum ModuleState {
    case done
    case current
    case locked
}

final class BookViewModel: ObservableObject {
    @Published var book: Book = .sample

    /// Elements due for review right now — drives "Y due".
    @Published var dueCount: Int = 0
    /// Unmastered elements in the newest unlocked module — drives "X new".
    @Published var newAvailableToday: Int = 0
    /// Elements first introduced today, in this book — drives "N appris".
    @Published var learnedToday: Int = 0
    /// Elements genuinely re-graded today (reviewed minus first-seen-today), in this
    /// book — drives "M révisés".
    @Published var reviewedToday: Int = 0
    /// Module ids currently unlocked (strict chain).
    @Published private(set) var unlockedIDs: Set<String> = []
    /// Element ids that satisfy the unlock gate (mastered or suspended).
    @Published private(set) var satisfiedIDs: Set<String> = []
    /// Book-completion bar segments + % + time-to-finish estimate. Mastered/segments/%
    /// come from the LIVE `satisfied` gate (a cleared element drops out); the
    /// `mastery_log` day stamps feed ONLY the pace. See `ProgressEstimate`.
    @Published var estimate: ProgressEstimate = ProgressEstimate(
        total: 0, mastered: 0, seen: 0, masteryDays: [], firstActivity: nil, today: Date())

    let settingsStore: StudySettingsStore
    private var masteryThreshold: Int { StudySettings.masteryThreshold }

    init(settingsStore: StudySettingsStore = StudySettingsStore()) {
        self.settingsStore = settingsStore
    }

    // MARK: - Loading

    /// Load content from the bundle (off-main) then publish + refresh on main.
    func load() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let book = ContentLoader.loadBook()
            DispatchQueue.main.async {
                self?.book = book
                self?.refresh()
            }
        }
    }

    /// Recompute due / new counts and unlock state from the SRS schedule. Snapshot
    /// the main-owned `book` / settings before going off-main. Call from the MAIN
    /// thread (on appear, after a session or settings sheet dismisses).
    func refresh() {
        let book = self.book
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            let dueIDs = Set(DataManager.shared.fetchDueElementIDs(asOf: Date()))
            let due = book.allElements.filter { dueIDs.contains($0.id) }.count
            let satisfied = DataManager.shared.fetchUnlockSatisfiedElementIDs(threshold: self.masteryThreshold)
            let unlocked = StudyScheduler.unlockedModuleIDs(book, satisfied: satisfied)

            // Apprendre drills the newest unlocked (frontier) module; "X new" is how
            // many of its elements are still unmastered — what one tap will teach.
            // No daily cap on new material.
            let frontier = book.modules
                .filter { unlocked.contains($0.id) }
                .max(by: { $0.sortOrder < $1.sortOrder })
            let newCount = frontier?.elements.filter { !satisfied.contains($0.id) }.count ?? 0

            // Today's done-work, scoped to this book. "reviewed" excludes elements
            // first-seen today (a first sighting is not a re-grade) — matches the
            // history page's rule.
            let bookIDs = Set(book.allElements.map(\.id))
            let firstSeenToday = DataManager.shared.fetchElementIDsFirstSeen(on: Date())
            let reviewedToday = DataManager.shared.fetchElementIDsReviewedLogged(on: Date())
            let learnedCount = firstSeenToday.intersection(bookIDs).count
            let reviewedCount = reviewedToday.subtracting(firstSeenToday).intersection(bookIDs).count

            // Book-completion bar + finish estimate. Segments/% come from the LIVE
            // `satisfied` gate (so a cleared element correctly drops out); the
            // `mastery_log` day stamps feed ONLY the pace.
            let total = book.allElements.count
            let masteredInBook = satisfied.intersection(bookIDs).count
            let seenInBook = DataManager.shared.fetchSeenElementIDs().intersection(bookIDs).count
            let masteryDays = DataManager.shared.fetchMasteryLog()
                .filter { bookIDs.contains($0.elementID) }
                .map(\.dayStart)
            let firstActivity = DataManager.shared.fetchFirstSeenByElement()
                .filter { bookIDs.contains($0.key) }
                .values.min()
            let estimate = ProgressEstimate(total: total, mastered: masteredInBook,
                                            seen: seenInBook, masteryDays: masteryDays,
                                            firstActivity: firstActivity, today: Date())

            DispatchQueue.main.async {
                self.dueCount = due
                self.newAvailableToday = newCount
                self.learnedToday = learnedCount
                self.reviewedToday = reviewedCount
                self.satisfiedIDs = satisfied
                self.unlockedIDs = unlocked
                self.estimate = estimate
            }
        }
    }

    // MARK: - Session builders (call at tap-time on the MAIN thread)

    /// The newest unlocked (frontier) module — the one Apprendre drills. Highest
    /// `sortOrder` among unlocked modules (complete ones + the current frontier).
    func newestUnlockedModule() -> CourseModule? {
        book.modules
            .filter { unlockedIDs.contains($0.id) }
            .max(by: { $0.sortOrder < $1.sortOrder })
    }

    /// Due elements (never truncated) topped up with overflow toward the soft target.
    func reviewSessionElements() -> [GrammarElement] {
        let byID = Dictionary(book.allElements.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let dueIDs = Set(DataManager.shared.fetchDueElementIDs(asOf: Date()))
        let due = book.allElements.filter { dueIDs.contains($0.id) }
        let target = settingsStore.settings.reviewTarget
        let overflowIDs = DataManager.shared.fetchOverflowElementIDs(asOf: Date(), limit: max(0, target - due.count))
        let overflow = overflowIDs.compactMap { byID[$0] }
        let queue = StudyScheduler.reviewQueue(due: due, overflow: overflow, target: target)
        // One Réviser tap = one round of at most `reviewRoundSize` problems; tap
        // again for the next round. The day's pool (`reviewTarget`) still bounds the
        // overflow top-up above.
        return Array(queue.prefix(settingsStore.settings.reviewRoundSize))
    }

    /// Elements to drill when a module is tapped: its not-yet-mastered elements
    /// (so the learner can finish the module); the full set if already complete.
    func moduleLearnElements(_ module: CourseModule) -> [GrammarElement] {
        let remaining = module.elements.filter { !satisfiedIDs.contains($0.id) }
        return remaining.isEmpty ? module.elements : remaining
    }

    // MARK: - Module row state

    func masteredCount(in module: CourseModule) -> Int {
        module.elements.filter { satisfiedIDs.contains($0.id) }.count
    }

    func isUnlocked(_ module: CourseModule) -> Bool {
        unlockedIDs.contains(module.id)
    }

    func state(for module: CourseModule) -> ModuleState {
        if StudyScheduler.isModuleComplete(module, satisfied: satisfiedIDs) { return .done }
        if unlockedIDs.contains(module.id) { return .current }
        return .locked
    }
}
