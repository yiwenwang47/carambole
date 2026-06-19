//
//  TopicMapViewModel.swift
//  carambole
//
//  Drives the "Table des matières" topic map: loads grammar topics, tracks
//  completion (UserDefaults for now — real SRS lands in a later task), and
//  derives the unlock / row-state for each topic.
//

import Foundation
import Combine

/// Row state used to pick the trailing glyph in the topic map.
enum TopicState {
    case done
    case current
    case locked
}

final class TopicMapViewModel: ObservableObject {
    @Published var topics: [GrammarTopic] = []

    /// Number of exercises currently due for spaced-repetition review. Drives
    /// the "Y due" count on the home. Semantics = ACTUAL due (never the target).
    @Published var dueCount: Int = 0

    /// How many NEW cards remain available to introduce today: the day's
    /// remaining `newPerDay` budget, further capped by the count of unseen
    /// exercises left in the course. Drives the "X new" count on the home.
    @Published var newAvailableToday: Int = 0

    /// The SHARED study-settings store — single source of truth for pacing.
    /// The view passes this same instance into `SettingsView`, so an edit there
    /// is observed here (and by `remainingNewBudget` / `reviewSessionExercises`).
    let settingsStore: StudySettingsStore

    /// UserDefaults key holding the set of completed topic ids.
    private let completedKey = "completedTopicIDs"

    /// In-memory mirror of the persisted completed-topic set.
    private var completedIDs: Set<String>

    init(settingsStore: StudySettingsStore = StudySettingsStore()) {
        self.settingsStore = settingsStore
        let stored = UserDefaults.standard.array(forKey: completedKey) as? [String] ?? []
        self.completedIDs = Set(stored)
    }

    // MARK: - Loading

    /// The single seed-then-load entry point: seeds topics if the database is
    /// empty, then fetches them. Both run off the main thread on the database's
    /// serial queue, in order, so this fetch observes the rows seeded just above.
    func loadSeedingIfNeeded() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            TopicLoader.seedIfNeeded()
            self?.load()
        }
    }

    /// Loads all grammar topics from the database and publishes on the main thread.
    func load() {
        DataManager.shared.fetchAllTopics { [weak self] topics in
            DispatchQueue.main.async {
                self?.topics = topics.sorted { $0.sortOrder < $1.sortOrder }
                self?.refresh()
            }
        }
    }

    // MARK: - Daily session (new + review)

    /// All exercises across every loaded topic whose SRS schedule is due as of now.
    /// Semantics = ACTUAL due — drives the home's "Y due" count.
    func dueExercises() -> [Exercise] {
        let due = Set(DataManager.shared.fetchDueExerciseIDs(asOf: Date()))
        return topics.flatMap(\.exercises).filter { due.contains($0.id) }
    }

    /// The day's remaining `newPerDay` headroom: the hard cap minus the number of
    /// new cards already introduced today. Never negative.
    private var remainingNewBudget: Int {
        max(0, settingsStore.settings.newPerDay - DataManager.shared.countNewIntroduced(on: Date()))
    }

    /// The new exercises to introduce in today's "Apprendre" session: course
    /// order, minus anything already seen, capped at today's remaining budget.
    /// Read a fresh value at present-time (do NOT cache).
    func todaysNewExercises() -> [Exercise] {
        StudyScheduler.newQueue(
            topics: topics,
            seen: DataManager.shared.fetchSeenExerciseIDs(),
            remainingBudget: remainingNewBudget
        )
    }

    /// Not-yet-due overflow exercises (soonest-due / lowest-familiarity first),
    /// mapped back to loaded `Exercise`s while PRESERVING the SQL order — built
    /// via an id→Exercise dictionary so a Set lookup can't drop ordering. Capped
    /// so the review queue grows toward (never truncates below) the target.
    private func overflowExercises() -> [Exercise] {
        let target = settingsStore.settings.reviewTarget
        let limit = max(0, target - dueExercises().count)
        let ids = DataManager.shared.fetchOverflowExerciseIDs(asOf: Date(), limit: limit)
        let byID = Dictionary(
            topics.flatMap(\.exercises).map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        return ids.compactMap { byID[$0] }
    }

    /// The exercises for today's "Réviser" session: every due item (never
    /// truncated) topped up with overflow toward the soft target.
    /// Read a fresh value at present-time (do NOT cache).
    func reviewSessionExercises() -> [Exercise] {
        StudyScheduler.reviewQueue(
            due: dueExercises(),
            overflow: overflowExercises(),
            target: settingsStore.settings.reviewTarget
        )
    }

    /// Recomputes BOTH the due count and the available-new count from the SRS
    /// schedule + settings, publishing on the main thread. Safe to call from the
    /// view on appear / after a session or settings sheet dismisses.
    func refresh() {
        let work = { [weak self] in
            guard let self else { return }
            let due = self.dueExercises().count
            // `todaysNewExercises().count` already applies BOTH the budget cap
            // and the unseen filter, so it is exactly `newAvailableToday`.
            let new = self.todaysNewExercises().count
            DispatchQueue.main.async {
                self.dueCount = due
                self.newAvailableToday = new
            }
        }
        // DB reads use `dbQueue.sync` internally; keep them off the main thread.
        if Thread.isMainThread {
            DispatchQueue.global(qos: .userInitiated).async(execute: work)
        } else {
            work()
        }
    }

    // MARK: - Completion tracking

    func isComplete(_ id: String) -> Bool {
        completedIDs.contains(id)
    }

    func markComplete(_ id: String) {
        guard !completedIDs.contains(id) else { return }
        completedIDs.insert(id)
        UserDefaults.standard.set(Array(completedIDs), forKey: completedKey)
        // Re-publish so dependent unlock states refresh.
        objectWillChange.send()
    }

    // MARK: - Unlocking

    /// A topic is unlocked when it has no prerequisite, when its prerequisite is
    /// complete, or when its prerequisite isn't present among the loaded topics
    /// (an orphan / not-yet-authored prereq counts as satisfied, so the first
    /// available topic is always playable).
    func isUnlocked(_ topic: GrammarTopic) -> Bool {
        guard let prerequisiteID = topic.prerequisiteID else { return true }
        if isComplete(prerequisiteID) { return true }
        let prereqIsAuthored = topics.contains { $0.id == prerequisiteID }
        return !prereqIsAuthored
    }

    // MARK: - Row state

    func state(for topic: GrammarTopic) -> TopicState {
        if isComplete(topic.id) { return .done }
        if isUnlocked(topic) { return .current }
        return .locked
    }
}
