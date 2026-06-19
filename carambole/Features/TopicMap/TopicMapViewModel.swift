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

    /// UserDefaults key holding the set of completed topic ids.
    private let completedKey = "completedTopicIDs"

    /// In-memory mirror of the persisted completed-topic set.
    private var completedIDs: Set<String>

    init() {
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
            }
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
