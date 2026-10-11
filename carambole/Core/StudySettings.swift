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

/// Observable store backing `StudySettings` in `UserDefaults`, scoped to ONE
/// book. *Fondations* keeps the original `settings.*` keys; another book reads
/// and writes `settings.<scope>.*` (e.g. `settings.book_fr_en_situation.newPerDay`),
/// so changing one book's pacing or audio never changes the other's. The
/// `UserDefaults` instance is injected so tests (and the self-test) can run
/// against an isolated suite. Writes are clamped via `StudySettings.init`, so
/// persisted values are always in range.
final class StudySettingsStore: ObservableObject {
    /// Setting names; `key(_:)` adds the book scope.
    private enum Name {
        static let newPerDay = "newPerDay"
        static let reviewTarget = "reviewTarget"
        static let reviewRoundSize = "reviewRoundSize"
        static let autoSpeak = "autoSpeak"
    }

    private let defaults: UserDefaults
    /// nil → `settings.<name>` (Book 1); else `settings.<scope>.<name>`.
    let scope: String?

    /// The full UserDefaults key for a setting in this book's scope.
    func key(_ name: String) -> String {
        Self.key(name, scope: scope)
    }

    private static func key(_ name: String, scope: String?) -> String {
        if let scope { return "settings.\(scope).\(name)" }
        return "settings.\(name)"
    }

    @Published var settings: StudySettings {
        didSet {
            defaults.set(settings.newPerDay, forKey: key(Name.newPerDay))
            defaults.set(settings.reviewTarget, forKey: key(Name.reviewTarget))
            defaults.set(settings.reviewRoundSize, forKey: key(Name.reviewRoundSize))
        }
    }

    /// Read aloud automatically on a correct answer (Book 1: the model sentence;
    /// Book 2: the server's follow-up line). Default OFF — the learner opts in;
    /// the manual play buttons are always there. Drill views receive this value
    /// from the selected book's store; nothing reads the key directly.
    @Published var autoSpeak: Bool {
        didSet { defaults.set(autoSpeak, forKey: key(Name.autoSpeak)) }
    }

    convenience init(book: BookDescriptor, defaults: UserDefaults = .standard) {
        self.init(defaults: defaults, scope: book.settingsScope)
    }

    init(defaults: UserDefaults = .standard, scope: String? = nil) {
        self.defaults = defaults
        self.scope = scope
        let newPerDay = defaults.object(forKey: Self.key(Name.newPerDay, scope: scope)) as? Int
            ?? StudySettings.default.newPerDay
        let reviewTarget = defaults.object(forKey: Self.key(Name.reviewTarget, scope: scope)) as? Int
            ?? StudySettings.default.reviewTarget
        let reviewRoundSize = defaults.object(forKey: Self.key(Name.reviewRoundSize, scope: scope)) as? Int
            ?? StudySettings.default.reviewRoundSize
        // Absent key → OFF by default; opt-in only.
        self.autoSpeak = defaults.object(forKey: Self.key(Name.autoSpeak, scope: scope)) as? Bool ?? false
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

        // Book scope: Book 1 keeps the legacy `settings.*` keys; Book 2 writes
        // `settings.book_fr_en_situation.*` and never touches Book 1's values.
        suite.removePersistentDomain(forName: suiteName)
        let book1 = StudySettingsStore(book: BookCatalog.fondations, defaults: suite)
        let book2 = StudySettingsStore(book: BookCatalog.enSituation, defaults: suite)
        assert(book1.key("newPerDay") == "settings.newPerDay", "Book 1 keys unchanged")
        assert(book2.key("autoSpeak") == "settings.book_fr_en_situation.autoSpeak", "Book 2 scoped key")
        book1.settings = StudySettings(newPerDay: 12, reviewTarget: 100, reviewRoundSize: 20)
        book2.settings = StudySettings(newPerDay: 5, reviewTarget: 300, reviewRoundSize: 10)
        book2.autoSpeak = true
        let book1Again = StudySettingsStore(book: BookCatalog.fondations, defaults: suite)
        let book2Again = StudySettingsStore(book: BookCatalog.enSituation, defaults: suite)
        assert(book1Again.settings == StudySettings(newPerDay: 12, reviewTarget: 100, reviewRoundSize: 20),
               "Book 2 writes leave Book 1 settings alone")
        assert(book1Again.autoSpeak == false, "Book 2 auto-speak leaves Book 1 off")
        assert(book2Again.settings == StudySettings(newPerDay: 5, reviewTarget: 300, reviewRoundSize: 10),
               "Book 2 settings round-trip")
        assert(book2Again.autoSpeak == true, "Book 2 auto-speak round-trips")
        assert(suite.object(forKey: "settings.book_fr_en_situation.reviewRoundSize") as? Int == 10,
               "Book 2 uses the documented key")
        assert(suite.object(forKey: "settings.autoSpeak") == nil, "Book 2 never writes Book 1's key")

        suite.removePersistentDomain(forName: suiteName)
    }
}
#endif
