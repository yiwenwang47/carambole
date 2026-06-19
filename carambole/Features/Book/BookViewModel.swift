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
    /// New elements still introducible today (budget ∧ unseen) — drives "X new".
    @Published var newAvailableToday: Int = 0
    /// Module ids currently unlocked (strict chain).
    @Published private(set) var unlockedIDs: Set<String> = []
    /// Element ids that satisfy the unlock gate (mastered or suspended).
    @Published private(set) var satisfiedIDs: Set<String> = []

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
        let settings = settingsStore.settings
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            let dueIDs = Set(DataManager.shared.fetchDueElementIDs(asOf: Date()))
            let due = book.allElements.filter { dueIDs.contains($0.id) }.count
            let seen = DataManager.shared.fetchSeenElementIDs()
            let remaining = max(0, settings.newPerDay - DataManager.shared.countNewIntroduced(on: Date()))
            let newCount = StudyScheduler.newQueue(book: book, seen: seen, remainingBudget: remaining).count
            let satisfied = DataManager.shared.fetchUnlockSatisfiedElementIDs(threshold: self.masteryThreshold)
            let unlocked = StudyScheduler.unlockedModuleIDs(book, satisfied: satisfied)
            DispatchQueue.main.async {
                self.dueCount = due
                self.newAvailableToday = newCount
                self.satisfiedIDs = satisfied
                self.unlockedIDs = unlocked
            }
        }
    }

    // MARK: - Session builders (call at tap-time on the MAIN thread)

    /// New elements to introduce today: course order, minus seen, capped at budget.
    func todaysNewElements() -> [GrammarElement] {
        let seen = DataManager.shared.fetchSeenElementIDs()
        let remaining = max(0, settingsStore.settings.newPerDay - DataManager.shared.countNewIntroduced(on: Date()))
        return StudyScheduler.newQueue(book: book, seen: seen, remainingBudget: remaining)
    }

    /// Due elements (never truncated) topped up with overflow toward the soft target.
    func reviewSessionElements() -> [GrammarElement] {
        let byID = Dictionary(book.allElements.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let dueIDs = Set(DataManager.shared.fetchDueElementIDs(asOf: Date()))
        let due = book.allElements.filter { dueIDs.contains($0.id) }
        let target = settingsStore.settings.reviewTarget
        let overflowIDs = DataManager.shared.fetchOverflowElementIDs(asOf: Date(), limit: max(0, target - due.count))
        let overflow = overflowIDs.compactMap { byID[$0] }
        return StudyScheduler.reviewQueue(due: due, overflow: overflow, target: target)
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
