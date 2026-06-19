import Foundation

/// User-tunable study pacing. `newPerDay` is a HARD cap on how many brand-new
/// exercises are introduced per calendar day; `reviewTarget` is a SOFT target for
/// the daily review queue (it may be exceeded by a large due stack). Both are
/// clamped on init — out-of-range values are an invariant violation and are never
/// stored.
struct StudySettings: Equatable {
    var newPerDay: Int
    var reviewTarget: Int

    static let newPerDayRange = 5...40
    static let reviewTargetRange = 40...600
    static let reviewTargetStep = 20

    static let `default` = StudySettings(newPerDay: 20, reviewTarget: 200)

    init(newPerDay: Int, reviewTarget: Int) {
        self.newPerDay = newPerDay.clamped(to: StudySettings.newPerDayRange)
        self.reviewTarget = reviewTarget.clamped(to: StudySettings.reviewTargetRange)
    }
}

private extension Int {
    func clamped(to range: ClosedRange<Int>) -> Int {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

/// Observable store backing `StudySettings` in `UserDefaults`. The `UserDefaults`
/// instance is injected so tests (and the self-test) can run against an isolated
/// suite. Writes are clamped via `StudySettings.init`, so persisted values are
/// always in range.
final class StudySettingsStore: ObservableObject {
    private enum Key {
        static let newPerDay = "settings.newPerDay"
        static let reviewTarget = "settings.reviewTarget"
    }

    private let defaults: UserDefaults

    @Published var settings: StudySettings {
        didSet {
            defaults.set(settings.newPerDay, forKey: Key.newPerDay)
            defaults.set(settings.reviewTarget, forKey: Key.reviewTarget)
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let newPerDay = defaults.object(forKey: Key.newPerDay) as? Int
            ?? StudySettings.default.newPerDay
        let reviewTarget = defaults.object(forKey: Key.reviewTarget) as? Int
            ?? StudySettings.default.reviewTarget
        // Clamps via init; persists clamped values back through didSet.
        self.settings = StudySettings(newPerDay: newPerDay, reviewTarget: reviewTarget)
    }
}

#if DEBUG
extension StudySettingsStore {
    static func _selfTest() {
        // Clamping invariant.
        assert(StudySettings(newPerDay: 1, reviewTarget: 200).newPerDay == 5, "newPerDay clamps up to 5")
        assert(StudySettings(newPerDay: 99, reviewTarget: 200).newPerDay == 40, "newPerDay clamps down to 40")
        assert(StudySettings(newPerDay: 20, reviewTarget: 0).reviewTarget == 40, "reviewTarget clamps up to 40")
        assert(StudySettings(newPerDay: 20, reviewTarget: 9999).reviewTarget == 600, "reviewTarget clamps down to 600")

        // Round-trip persistence through an isolated suite.
        let suiteName = "carambole.selftest.settings"
        let suite = UserDefaults(suiteName: suiteName)!
        suite.removePersistentDomain(forName: suiteName)

        let store = StudySettingsStore(defaults: suite)
        assert(store.settings == .default, "absent keys fall back to default")

        store.settings = StudySettings(newPerDay: 30, reviewTarget: 150)
        let reloaded = StudySettingsStore(defaults: suite)
        assert(reloaded.settings == StudySettings(newPerDay: 30, reviewTarget: 150), "values round-trip")

        // Out-of-range write is stored clamped.
        store.settings = StudySettings(newPerDay: 99, reviewTarget: 0)
        let reloadedClamped = StudySettingsStore(defaults: suite)
        assert(reloadedClamped.settings == StudySettings(newPerDay: 40, reviewTarget: 40), "persisted values stay clamped")

        suite.removePersistentDomain(forName: suiteName)
    }
}
#endif
