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
    /// Which book this model drives. Every count, queue and setting below is
    /// scoped to this book's element IDs and settings store.
    let descriptor: BookDescriptor
    @Published var book: Book

    /// Elements due for review right now — drives "Y due".
    @Published var dueCount: Int = 0
    /// Unintroduced elements in the newest unlocked module — drives "X new".
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
    /// Element ids ever introduced (en-cours-or-better) — drives the four-bucket
    /// classification in the module detail list (`seen ∖ graduated = en cours`).
    @Published private(set) var seenIDs: Set<String> = []
    /// Correctly introduced elements. Book 2 uses this for unit completion;
    /// merely attempting a card (the seen set) does not finish its unit.
    @Published private(set) var introducedIDs: Set<String> = []
    /// Graduated element ids whose memory has decayed below the fragile floor
    /// (`R(now) < 0.80`). A subset of `satisfiedIDs`; drives the "fragile" badge.
    @Published private(set) var fragileIDs: Set<String> = []
    /// Book-completion bar segments + % + time-to-finish estimate. Mastered/segments/%
    /// come from the LIVE `satisfied` gate (a cleared element drops out); the
    /// `mastery_log` day stamps feed ONLY the pace. The fragile annotation (graduated
    /// AND `R(now) < 0.80`) rides on the same value. See `ProgressEstimate`.
    @Published var estimate: ProgressEstimate = ProgressEstimate(
        total: 0, mastered: 0, seen: 0, masteryDays: [], firstActivity: nil, today: Date())

    let settingsStore: StudySettingsStore

    init(book descriptor: BookDescriptor = BookCatalog.fondations,
         settingsStore: StudySettingsStore? = nil) {
        self.descriptor = descriptor
        self.book = Book(id: descriptor.id, title: descriptor.title, sortOrder: 0, modules: [],
                         kind: descriptor.kind)
        self.settingsStore = settingsStore ?? StudySettingsStore(book: descriptor)
    }

    // MARK: - Loading

    /// Load content from the bundle (off-main) then publish + refresh on main.
    func load() {
        let descriptor = self.descriptor
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let book = ContentLoader.loadBook(descriptor)
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

            // Graduation takes spaced reviews, so the course unlocks after
            // introductions. Book 2 requires a correct answer; a wrong attempt
            // counts as seen but must keep that unit open.
            let seen = DataManager.shared.fetchSeenElementIDs()
            let introduced = DataManager.shared.fetchIntroducedElementIDs()
            let unlocked = StudyScheduler.unlockedModuleIDs(
                book, satisfied: descriptor.kind == .situation ? introduced : seen)

            // The bar/module-"done" maîtrisé set is the live STICKY GRADUATION flag
            // (`graduated_date IS NOT NULL`) — exact + monotonic, never the old count.
            let satisfied = DataManager.shared.fetchGraduatedElementIDs()

            // Apprendre drills the newest unlocked (frontier) module; "X new" is how
            // many of its elements are still un-introduced — what one tap
            // will teach. No daily cap on new material.
            let frontier = book.modules
                .filter { unlocked.contains($0.id) }
                .max(by: { $0.sortOrder < $1.sortOrder })
            let newCount = frontier?.elements.filter {
                !(self.descriptor.kind == .situation ? introduced : seen).contains($0.id)
            }.count ?? 0

            // Today's done-work, scoped to this book. "reviewed" excludes elements
            // first-seen today (a first sighting is not a re-grade) — matches the
            // history page's rule.
            let bookIDs = Set(book.allElements.map(\.id))
            let firstSeenToday = DataManager.shared.fetchElementIDsFirstSeen(on: Date())
            let reviewedToday = DataManager.shared.fetchElementIDsReviewedLogged(on: Date())
            let learnedCount = firstSeenToday.intersection(bookIDs).count
            let reviewedCount = reviewedToday.subtracting(firstSeenToday).intersection(bookIDs).count

            // Book-completion bar + finish estimate. maîtrisé/segments/% come from the
            // LIVE graduation flag (`satisfied`, so a cleared element correctly drops
            // out); the `mastery_log` day stamps feed ONLY the pace.
            let total = book.allElements.count
            let masteredInBook = satisfied.intersection(bookIDs).count
            let seenInBook = seen.intersection(bookIDs).count
            let masteryDays = DataManager.shared.fetchMasteryLog()
                .filter { bookIDs.contains($0.elementID) }
                .map(\.dayStart)
            let firstActivity = DataManager.shared.fetchFirstSeenByElement()
                .filter { bookIDs.contains($0.key) }
                .values.min()

            // FRAGILE = graduated ∧ ¬suspended ∧ R(now) < 0.80, ∩ book. A subset of
            // maîtrisé (annotation only — never changes the bar segments above). R is
            // predicted recall over the calendar-day gap since the element's last
            // review (`CalendarDays.elapsed`, the same bridge grading uses). Keep the
            // id SET (not just the count) so the module detail list can badge each
            // fragile element; the bar still uses `.count`.
            let now = Date()
            let fragileIDs = Set(DataManager.shared.fetchGraduatedStates()
                .filter { bookIDs.contains($0.elementID) }
                .filter { row in
                    let elapsed = CalendarDays.elapsed(from: row.lastReviewDate, to: now)
                    return FSRS.retrievability(stability: row.stability, elapsedDays: elapsed) < FSRS.fragileRecall
                }
                .map(\.elementID))
            let fragileInBook = fragileIDs.count

            let estimate = ProgressEstimate(total: total, mastered: masteredInBook,
                                            seen: seenInBook, masteryDays: masteryDays,
                                            firstActivity: firstActivity, today: now,
                                            fragile: fragileInBook)

            DispatchQueue.main.async {
                self.dueCount = due
                self.newAvailableToday = newCount
                self.learnedToday = learnedCount
                self.reviewedToday = reviewedCount
                self.satisfiedIDs = satisfied
                self.seenIDs = seen
                self.introducedIDs = introduced
                self.fragileIDs = fragileIDs
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

    /// Due elements only, ordered by ascending predicted recall `R(now)` so
    /// the most-decayed elements enter the round first. The selected round size
    /// is a maximum, not a target to fill with early reviews.
    func reviewSessionElements() -> [GrammarElement] {
        let now = Date()
        let dueIDs = Set(DataManager.shared.fetchDueElementIDs(asOf: now))
        let due = book.allElements.filter { dueIDs.contains($0.id) }

        // Lowest predicted recall first. R per element from its (stability,
        // lastReviewDate); an element with no FSRS state yet sorts last. The
        // original index keeps course order stable for equal recall.
        // TODO(perf): N+1 — `currentRecall` does one `fetchReviewStatus` per due
        // element. Batch into a single
        // `fetchReviewStatuses(forIDs:)` reader if review rounds start to feel slow.
        struct Ranked { let index: Int; let element: GrammarElement; let recall: Double }
        var ranked: [Ranked] = []
        ranked.reserveCapacity(due.count)
        for (offset, element) in due.enumerated() {
            let recall = Self.currentRecall(elementID: element.id, asOf: now)
            ranked.append(Ranked(index: offset, element: element, recall: recall))
        }
        ranked.sort { lhs, rhs in
            lhs.recall != rhs.recall ? lhs.recall < rhs.recall : lhs.index < rhs.index
        }
        let ordered = ranked.map(\.element)

        // One Réviser tap = up to `reviewRoundSize` due elements. Any remaining
        // due elements wait for the next round.
        return StudyScheduler.reviewQueue(due: ordered, limit: settingsStore.settings.reviewRoundSize)
    }

    // MARK: - FSRS recall helpers (I/O layer — date math lives here, not in pure FSRS)

    /// Predicted recall `R(now)` for an element from its persisted `(stability,
    /// lastReviewDate)`. No FSRS state yet → `1.0` (treat as freshest, sorts last).
    private static func currentRecall(elementID: String, asOf now: Date) -> Double {
        guard let status = DataManager.shared.fetchReviewStatus(elementID: elementID),
              let stability = status.stability else { return 1.0 }
        let elapsed = CalendarDays.elapsed(from: status.lastReviewDate, to: now)
        return FSRS.retrievability(stability: stability, elapsedDays: elapsed)
    }

    /// Resume Apprendre at elements not yet answered correctly. A wrong answer
    /// creates review state but does not complete that element's introduction.
    /// Once all elements have a correct answer, a new tap practises the full module.
    func moduleLearnElements(_ module: CourseModule) -> [GrammarElement] {
        let completed = Set(module.elements.compactMap { element -> String? in
            guard let status = DataManager.shared.fetchReviewStatus(elementID: element.id),
                  status.distinctCorrect > 0 || status.graduatedDate != nil || status.suspended
            else { return nil }
            return element.id
        })
        let pending = Set(LearnLoop.pendingElementIDs(module.elements.map(\.id), completedIDs: completed))
        return module.elements.filter { pending.contains($0.id) }
    }

    // MARK: - Module row state

    func masteredCount(in module: CourseModule) -> Int {
        module.elements.filter { satisfiedIDs.contains($0.id) }.count
    }

    func isUnlocked(_ module: CourseModule) -> Bool {
        unlockedIDs.contains(module.id)
    }

    func state(for module: CourseModule) -> ModuleState {
        let completeIDs = descriptor.kind == .situation ? introducedIDs : satisfiedIDs
        if StudyScheduler.isModuleComplete(module, satisfied: completeIDs) { return .done }
        if unlockedIDs.contains(module.id) { return .current }
        return .locked
    }

    func completedCount(in module: CourseModule) -> Int {
        let completeIDs = descriptor.kind == .situation ? introducedIDs : satisfiedIDs
        return module.elements.filter { completeIDs.contains($0.id) }.count
    }

    // MARK: - Element-level bucket classification (module detail list)

    /// The four memory-strength buckets an element can be in, derived from the live
    /// sets refreshed above. `fragile` is a graduated element whose recall has decayed
    /// below the floor — still maîtrisé on the bar, but flagged at-risk.
    enum ElementBucket {
        case mastered   // graduated, recall still healthy
        case fragile    // graduated AND R(now) < 0.80
        case enCours    // seen but not graduated
        case aVenir     // unseen
    }

    /// Classify one element into its memory-strength bucket. Order matters: fragile is
    /// a graduated element (checked within the graduated branch), and a graduated
    /// element is by definition seen, so the graduated test precedes the seen test.
    func bucket(for element: GrammarElement) -> ElementBucket {
        if satisfiedIDs.contains(element.id) {
            return fragileIDs.contains(element.id) ? .fragile : .mastered
        }
        if seenIDs.contains(element.id) { return .enCours }
        return .aVenir
    }

    /// Un-graduate ("remettre en cours") an element from a module's list, then
    /// refresh so the bar + buckets re-rate. Only meaningful on a graduated element;
    /// `demote` is harmless on others. `demote` and every reader in `refresh()` run on
    /// the same serial `dbQueue`, so the write is guaranteed to land before the refresh
    /// re-reads it — no settle delay needed.
    func demoteElement(_ elementID: String) {
        DataManager.shared.demote(elementID: elementID)
        refresh()
    }
}
