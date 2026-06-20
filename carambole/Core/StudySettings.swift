import Foundation

/// User-tunable study pacing. `newPerDay` is a HARD cap on how many brand-new
/// exercises are introduced per calendar day; `reviewTarget` is a SOFT target for
/// the daily review queue (it may be exceeded by a large due stack). Both are
/// clamped on init — out-of-range values are an invariant violation and are never
/// stored.
struct StudySettings: Equatable {
    /// HARD cap on new ELEMENTS (grammar points) introduced per calendar day.
    var newPerDay: Int
    var reviewTarget: Int
    /// How many problems one Réviser tap presents. A discrete choice — snapped to
    /// the NEAREST allowed option on init, layered on top of `reviewTarget`.
    var reviewRoundSize: Int

    static let newPerDayRange = 3...20
    static let reviewTargetRange = 40...600
    static let reviewTargetStep = 20
    static let reviewRoundSizeOptions = [10, 20, 50]

    /// Distinct example sentences a learner must answer correctly for an element to
    /// count as mastered (the module-unlock gate). Not user-tunable in v1.
    static let masteryThreshold = 3

    static let `default` = StudySettings(newPerDay: 10, reviewTarget: 200, reviewRoundSize: 20)

    init(newPerDay: Int, reviewTarget: Int, reviewRoundSize: Int) {
        self.newPerDay = newPerDay.clamped(to: StudySettings.newPerDayRange)
        self.reviewTarget = reviewTarget.clamped(to: StudySettings.reviewTargetRange)
        self.reviewRoundSize = reviewRoundSize.snapped(to: StudySettings.reviewRoundSizeOptions)
    }
}

private extension Int {
    func clamped(to range: ClosedRange<Int>) -> Int {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }

    /// Snap to the option with the smallest absolute distance; ties pick the
    /// smaller option. `options` is assumed non-empty.
    func snapped(to options: [Int]) -> Int {
        options.min { lhs, rhs in
            let dl = abs(lhs - self), dr = abs(rhs - self)
            return dl != dr ? dl < dr : lhs < rhs
        } ?? self
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
        static let reviewRoundSize = "settings.reviewRoundSize"
        /// Also read by `DrillView` via `@AppStorage` under this exact literal — keep
        /// the two in sync if it ever changes.
        static let autoSpeak = "settings.autoSpeak"
    }

    private let defaults: UserDefaults

    @Published var settings: StudySettings {
        didSet {
            defaults.set(settings.newPerDay, forKey: Key.newPerDay)
            defaults.set(settings.reviewTarget, forKey: Key.reviewTarget)
            defaults.set(settings.reviewRoundSize, forKey: Key.reviewRoundSize)
        }
    }

    /// Read aloud the model French sentence automatically on a correct answer.
    /// Default OFF — the learner opts in. The drill always offers a manual 🔊
    /// regardless. Persisted under `Key.autoSpeak` (shared with `DrillView`).
    @Published var autoSpeak: Bool {
        didSet { defaults.set(autoSpeak, forKey: Key.autoSpeak) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let newPerDay = defaults.object(forKey: Key.newPerDay) as? Int
            ?? StudySettings.default.newPerDay
        let reviewTarget = defaults.object(forKey: Key.reviewTarget) as? Int
            ?? StudySettings.default.reviewTarget
        let reviewRoundSize = defaults.object(forKey: Key.reviewRoundSize) as? Int
            ?? StudySettings.default.reviewRoundSize
        // Absent key → OFF by default; opt-in only.
        self.autoSpeak = defaults.object(forKey: Key.autoSpeak) as? Bool ?? false
        // Clamps via init; persists clamped values back through didSet.
        self.settings = StudySettings(newPerDay: newPerDay, reviewTarget: reviewTarget, reviewRoundSize: reviewRoundSize)
    }
}

#if DEBUG
extension StudySettingsStore {
    static func _selfTest() {
        // Clamping invariant.
        assert(StudySettings(newPerDay: 1, reviewTarget: 200, reviewRoundSize: 20).newPerDay == 3, "newPerDay clamps up to 3")
        assert(StudySettings(newPerDay: 99, reviewTarget: 200, reviewRoundSize: 20).newPerDay == 20, "newPerDay clamps down to 20")
        assert(StudySettings(newPerDay: 20, reviewTarget: 0, reviewRoundSize: 20).reviewTarget == 40, "reviewTarget clamps up to 40")
        assert(StudySettings(newPerDay: 20, reviewTarget: 9999, reviewRoundSize: 20).reviewTarget == 600, "reviewTarget clamps down to 600")

        // reviewRoundSize snaps to the nearest allowed option ({10, 20, 50}).
        assert(StudySettings(newPerDay: 10, reviewTarget: 200, reviewRoundSize: 7).reviewRoundSize == 10, "7 snaps to 10")
        assert(StudySettings(newPerDay: 10, reviewTarget: 200, reviewRoundSize: 33).reviewRoundSize == 20, "33 snaps to 20")
        assert(StudySettings(newPerDay: 10, reviewTarget: 200, reviewRoundSize: 40).reviewRoundSize == 50, "40 snaps to 50")
        assert(StudySettings(newPerDay: 10, reviewTarget: 200, reviewRoundSize: 99).reviewRoundSize == 50, "99 snaps to 50")
        // Exact options pass through unchanged.
        assert(StudySettings(newPerDay: 10, reviewTarget: 200, reviewRoundSize: 10).reviewRoundSize == 10, "10 stays 10")
        assert(StudySettings(newPerDay: 10, reviewTarget: 200, reviewRoundSize: 50).reviewRoundSize == 50, "50 stays 50")

        // Round-trip persistence through an isolated suite.
        let suiteName = "carambole.selftest.settings"
        let suite = UserDefaults(suiteName: suiteName)!
        suite.removePersistentDomain(forName: suiteName)

        let store = StudySettingsStore(defaults: suite)
        assert(store.settings == .default, "absent keys fall back to default")
        assert(store.autoSpeak == false, "autoSpeak defaults OFF (opt-in)")

        // autoSpeak round-trips through the suite.
        store.autoSpeak = true
        assert(StudySettingsStore(defaults: suite).autoSpeak == true, "autoSpeak round-trips on")
        store.autoSpeak = false
        assert(StudySettingsStore(defaults: suite).autoSpeak == false, "autoSpeak round-trips off")

        store.settings = StudySettings(newPerDay: 15, reviewTarget: 150, reviewRoundSize: 50)
        let reloaded = StudySettingsStore(defaults: suite)
        assert(reloaded.settings == StudySettings(newPerDay: 15, reviewTarget: 150, reviewRoundSize: 50), "values round-trip")
        assert(reloaded.settings.reviewRoundSize == 50, "reviewRoundSize round-trips")

        // Out-of-range write is stored clamped/snapped.
        store.settings = StudySettings(newPerDay: 99, reviewTarget: 0, reviewRoundSize: 7)
        let reloadedClamped = StudySettingsStore(defaults: suite)
        assert(reloadedClamped.settings == StudySettings(newPerDay: 20, reviewTarget: 40, reviewRoundSize: 10), "persisted values stay clamped/snapped")

        suite.removePersistentDomain(forName: suiteName)
    }
}
#endif
