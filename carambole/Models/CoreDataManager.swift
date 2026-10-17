import Foundation
import SQLite3

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

/// Persistence for USER data only. Course content (Book → Module → Element →
/// Example) is static and loaded from bundle JSON by `ContentLoader`, so the only
/// table here is `review_status` — one row per `GrammarElement`, holding both the
/// SRS schedule and the mastery counters. See
/// docs/plans/2026-06-19-book-modules-elements-design.md.
class DataManager {
    static let shared = DataManager()
    private var db: OpaquePointer?
    private let dbQueue = DispatchQueue(label: "com.carambole.database", qos: .userInitiated)

    /// On-disk location of the SQLite store (Documents/carambole.sqlite). Exposed
    /// so Settings can export a backup of accumulated learning progress.
    let databaseFileURL: URL = try! FileManager.default
        .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        .appendingPathComponent("carambole.sqlite")

    private init() {
        setupDatabase()
    }

    // MARK: - Setup & migration

    private func setupDatabase() {
        print("Database path: \(databaseFileURL.path)")

        guard sqlite3_open(databaseFileURL.path, &db) == SQLITE_OK else {
            print("Error opening database: \(String(cString: sqlite3_errmsg(db)))")
            return
        }

        migrate()
    }

    /// Versioned schema migration. `PRAGMA user_version` records which schema the
    /// open DB is at; each `if version < N` block upgrades ONE step and bumps the
    /// version. A fresh DB starts at 0 and runs every block in order; an existing
    /// install runs only the blocks newer than it.
    ///
    /// `review_status` is accumulated USER data and is NEVER reseeded. So every
    /// future schema change MUST be an additive step added here as a new block —
    /// never edit an earlier block, and never DROP this table. Adding a column
    /// only to the `CREATE TABLE` below does nothing on installs that already have
    /// the table; it must be an `ALTER TABLE … ADD COLUMN` inside its own block.
    private func migrate() {
        let version = userVersion()

        // v1 — element-keyed review_status (the current baseline). Every statement
        // is idempotent, so this also upgrades a pre-versioning dev DB (which sits
        // at user_version 0) in place without touching its accumulated rows.
        if version < 1 {
            // Pre-Book content tables are obsolete (content is now in-memory).
            sqlite3_exec(db, "DROP TABLE IF EXISTS topics;", nil, nil, nil)
            sqlite3_exec(db, "DROP TABLE IF EXISTS exercises;", nil, nil, nil)

            // review_status was exercise-keyed before the element rekey; that shape
            // is incompatible and its per-exercise progress is meaningless under
            // element-level SRS. Drop ONLY the old shape (no element_id column) —
            // never the current element-keyed table.
            if tableExists("review_status") && !columnExists(table: "review_status", column: "element_id") {
                print("Migrating: dropping old exercise-keyed review_status")
                sqlite3_exec(db, "DROP TABLE IF EXISTS review_status;", nil, nil, nil)
            }

            sqlite3_exec(db, """
                CREATE TABLE IF NOT EXISTS review_status (
                    element_id TEXT PRIMARY KEY,
                    learning_state TEXT,
                    last_review_date REAL,
                    next_review_date REAL,
                    interval_days INTEGER,
                    first_seen_date REAL,
                    suspended INTEGER DEFAULT 0,
                    distinct_correct INTEGER DEFAULT 0,
                    mastered_example_ids TEXT DEFAULT '[]'
                );
                """, nil, nil, nil)

            // Additive column adds for an element-keyed table predating them
            // (duplicate-column ALTER errors when present are ignored).
            for alter in [
                "ALTER TABLE review_status ADD COLUMN suspended INTEGER DEFAULT 0;",
                "ALTER TABLE review_status ADD COLUMN distinct_correct INTEGER DEFAULT 0;",
                "ALTER TABLE review_status ADD COLUMN mastered_example_ids TEXT DEFAULT '[]';",
            ] {
                sqlite3_exec(db, alter, nil, nil, nil)
            }

            setUserVersion(1)
        }

        // v2 — append-only `review_log` (one row per element per calendar day it was
        // reviewed). `review_status.last_review_date` keeps only the LATEST review, so
        // it can't reconstruct reviews-per-day; this event log can. Backfilled once
        // from existing rows so installed users aren't all-zeros.
        if version < 2 {
            sqlite3_exec(db, """
                CREATE TABLE IF NOT EXISTS review_log (
                    element_id TEXT NOT NULL,
                    day_start REAL NOT NULL,
                    PRIMARY KEY (element_id, day_start)
                );
                """, nil, nil, nil)

            // Backfill: stamp one (element_id, startOfDay(last_review_date)) per
            // already-reviewed element. day_start is computed in Swift via Calendar
            // (no date math in SQL), consistent with countNewIntroduced.
            backfillReviewLog()

            setUserVersion(2)
        }

        // v3 — append-only `mastery_log` (one row per element, the day it FIRST
        // became mastered/satisfied). `review_status` keeps only the latest counters,
        // so it can't reconstruct masteries-per-day; this event log can — driving an
        // honest "time to finish the book" pace estimate. PK is element_id alone
        // because mastery happens once per element. Backfilled once so installed
        // users with already-satisfied elements aren't all-zeros.
        //
        // This is a HISTORICAL EVENT log, not a live "is-currently-mastered" set:
        // `clearReviewStatus` ("Trop facile → wrong → clean records") deliberately does
        // NOT retract a logged mastery (same as `review_log`). So consumers must use it
        // ONLY for the per-day pace count — current mastery/% comes from the live
        // `graduated_date` gate (`fetchGraduatedElementIDs`), never from this log.
        if version < 3 {
            sqlite3_exec(db, """
                CREATE TABLE IF NOT EXISTS mastery_log (
                    element_id TEXT PRIMARY KEY,
                    day_start REAL NOT NULL
                );
                """, nil, nil, nil)

            // Backfill: stamp one (element_id, startOfDay(last_review_date)) per
            // currently-satisfied element. day_start is computed in Swift via Calendar
            // (no date math in SQL), consistent with backfillReviewLog.
            backfillMasteryLog()

            setUserVersion(3)
        }

        // v4 — FSRS memory-strength state. Adds the `(S, D)` pair + a sticky
        // graduated flag to `review_status`, replacing the count gate as the
        // authority for the maîtrisé bar (the legacy `distinct_correct` /
        // `learning_state` / `interval_days` columns stay but no longer gate).
        // All three ALTERs are additive (duplicate-column errors on a re-run are
        // ignored), then a ONE-TIME backfill re-derives FSRS state + graduation
        // from the spacing data already in each row — so the existing install
        // (real data on a physical iPhone) is honestly re-rated, not wiped or
        // grandfathered. `mastery_log` is LEFT UNTOUCHED here: pre-migration pace
        // stays approximate (and ages out of the 14-day pace window on its own);
        // the bar's maîtrisé COUNT is exact from the live `graduated_date` flag,
        // never the log.
        if version < 4 {
            for alter in [
                "ALTER TABLE review_status ADD COLUMN stability REAL;",
                "ALTER TABLE review_status ADD COLUMN difficulty REAL;",
                "ALTER TABLE review_status ADD COLUMN graduated_date REAL;",
            ] {
                sqlite3_exec(db, alter, nil, nil, nil)
            }

            backfillFSRSState()

            setUserVersion(4)
        }

        // v5 — *En situation* (Book 2). Two NEW tables; nothing existing changes.
        // Book 2 element IDs start with `sit_`, so they share `review_status` /
        // `review_log` / `mastery_log` with Book 1 without colliding; every reader
        // filters by the selected book's IDs.
        //   - `situation_item_log`: one row per dialogue/standalone item — when it
        //     was last done, how often, and its last rating (1 again, 2 hard,
        //     3 good). Drives Réviser selection (unseen first, then oldest; a
        //     missed item comes back first).
        //   - `situation_attempt_log`: every wrong attempt, append-only, with the
        //     book ID so each book's log stays separate.
        if version < 5 {
            sqlite3_exec(db, """
                CREATE TABLE IF NOT EXISTS situation_item_log (
                    item_id TEXT PRIMARY KEY,
                    element_id TEXT NOT NULL,
                    last_done REAL NOT NULL,
                    times INTEGER NOT NULL DEFAULT 0,
                    last_rating INTEGER NOT NULL
                );
                """, nil, nil, nil)
            sqlite3_exec(db, """
                CREATE TABLE IF NOT EXISTS situation_attempt_log (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    book_id TEXT NOT NULL,
                    element_id TEXT NOT NULL,
                    dialogue_id TEXT NOT NULL,
                    drill_type TEXT NOT NULL,
                    given TEXT NOT NULL,
                    expected TEXT NOT NULL,
                    reason TEXT,
                    created_at REAL NOT NULL
                );
                """, nil, nil, nil)
            sqlite3_exec(db, """
                CREATE INDEX IF NOT EXISTS situation_attempt_log_element
                ON situation_attempt_log (book_id, element_id);
                """, nil, nil, nil)
            setUserVersion(5)
        }

        // v6 — *Nuances* (Book 3) card history. Existing review and situation
        // records remain untouched; each card stores its latest grade and count.
        if version < 6 {
            sqlite3_exec(db, """
                CREATE TABLE IF NOT EXISTS nuance_card_log (
                    card_id TEXT PRIMARY KEY,
                    element_id TEXT NOT NULL,
                    last_done REAL NOT NULL,
                    times INTEGER NOT NULL DEFAULT 0,
                    last_rating INTEGER NOT NULL
                );
                """, nil, nil, nil)
            setUserVersion(6)
        }
    }

    /// One-time v2 backfill: seed `review_log` from each `review_status` row that
    /// already has a `last_review_date`, computing `day_start` in Swift. Wrapped in a
    /// transaction for speed; `INSERT OR IGNORE` makes it idempotent.
    ///
    /// Caveat: `day_start` is recomputed at migration time with the device's CURRENT
    /// timezone, which may differ from the zone in effect when the review happened, so
    /// a backfilled day can drift by a day vs a live-logged one. Inherent to
    /// reconstructing from a single timestamp — reviewed-history is documented lossy.
    private func backfillReviewLog() {
        let calendar = Calendar.current
        var rows: [(id: String, dayStart: Double)] = []

        var read: OpaquePointer?
        if sqlite3_prepare_v2(db,
            "SELECT element_id, last_review_date FROM review_status WHERE last_review_date IS NOT NULL;",
            -1, &read, nil) == SQLITE_OK {
            while sqlite3_step(read) == SQLITE_ROW {
                guard let c = sqlite3_column_text(read, 0) else { continue }
                let id = String(cString: c)
                let last = Date(timeIntervalSince1970: sqlite3_column_double(read, 1))
                rows.append((id, calendar.startOfDay(for: last).timeIntervalSince1970))
            }
        } else {
            print("Error preparing review_log backfill read: \(String(cString: sqlite3_errmsg(db)))")
        }
        sqlite3_finalize(read)

        guard !rows.isEmpty else { return }

        sqlite3_exec(db, "BEGIN;", nil, nil, nil)
        var insert: OpaquePointer?
        if sqlite3_prepare_v2(db,
            "INSERT OR IGNORE INTO review_log (element_id, day_start) VALUES (?, ?);",
            -1, &insert, nil) == SQLITE_OK {
            for row in rows {
                sqlite3_reset(insert)
                sqlite3_bind_text(insert, 1, (row.id as NSString).utf8String, -1, SQLITE_TRANSIENT)
                sqlite3_bind_double(insert, 2, row.dayStart)
                if sqlite3_step(insert) != SQLITE_DONE {
                    print("Error backfilling review_log: \(String(cString: sqlite3_errmsg(db)))")
                }
            }
        } else {
            print("Error preparing review_log backfill insert: \(String(cString: sqlite3_errmsg(db)))")
        }
        sqlite3_finalize(insert)
        sqlite3_exec(db, "COMMIT;", nil, nil, nil)
    }

    /// One-time v3 backfill: seed `mastery_log` from each `review_status` row that
    /// is currently satisfied — suspended ("too easy") OR mastered
    /// (`distinct_correct >= StudySettings.masteryThreshold`) — computing `day_start`
    /// in Swift from `last_review_date`. Wrapped in a transaction for speed;
    /// `INSERT OR IGNORE` makes it idempotent. Rows with a NULL `last_review_date`
    /// (no crossing timestamp to stamp) are defensively skipped — a satisfied
    /// element will normally have one.
    ///
    /// Caveat (same as `backfillReviewLog`): `day_start` is recomputed at migration
    /// time with the device's CURRENT timezone, which may differ from the zone in
    /// effect when mastery happened, so a backfilled day can drift by a day vs a
    /// live-logged one. Inherent to reconstructing from a single timestamp —
    /// mastery-history before this migration is forward-only / approximate.
    private func backfillMasteryLog() {
        let calendar = Calendar.current
        var rows: [(id: String, dayStart: Double)] = []

        var read: OpaquePointer?
        if sqlite3_prepare_v2(db,
            """
            SELECT element_id, last_review_date FROM review_status
            WHERE last_review_date IS NOT NULL
              AND (suspended = 1 OR distinct_correct >= ?);
            """,
            -1, &read, nil) == SQLITE_OK {
            sqlite3_bind_int(read, 1, Int32(StudySettings.masteryThreshold))
            while sqlite3_step(read) == SQLITE_ROW {
                guard let c = sqlite3_column_text(read, 0) else { continue }
                let id = String(cString: c)
                let last = Date(timeIntervalSince1970: sqlite3_column_double(read, 1))
                rows.append((id, calendar.startOfDay(for: last).timeIntervalSince1970))
            }
        } else {
            print("Error preparing mastery_log backfill read: \(String(cString: sqlite3_errmsg(db)))")
        }
        sqlite3_finalize(read)

        guard !rows.isEmpty else { return }

        sqlite3_exec(db, "BEGIN;", nil, nil, nil)
        var insert: OpaquePointer?
        if sqlite3_prepare_v2(db,
            "INSERT OR IGNORE INTO mastery_log (element_id, day_start) VALUES (?, ?);",
            -1, &insert, nil) == SQLITE_OK {
            for row in rows {
                sqlite3_reset(insert)
                sqlite3_bind_text(insert, 1, (row.id as NSString).utf8String, -1, SQLITE_TRANSIENT)
                sqlite3_bind_double(insert, 2, row.dayStart)
                if sqlite3_step(insert) != SQLITE_DONE {
                    print("Error backfilling mastery_log: \(String(cString: sqlite3_errmsg(db)))")
                }
            }
        } else {
            print("Error preparing mastery_log backfill insert: \(String(cString: sqlite3_errmsg(db)))")
        }
        sqlite3_finalize(insert)
        sqlite3_exec(db, "COMMIT;", nil, nil, nil)
    }

    /// One-time v4 backfill: seed each `review_status` row's FSRS `(S, D)` from the
    /// spacing data it already carries, and re-derive the sticky `graduated_date`.
    /// Wrapped in a transaction for speed; only writes rows whose `stability` is still
    /// NULL, so running migrate() twice never re-seeds (a row graded by the live FSRS
    /// engine has a non-NULL `stability` and is skipped). Forward-only / approximate
    /// (we're reconstructing from a single interval + the last review day).
    ///
    /// Backfill rule (see `fsrsBackfill(intervalDays:learningState:suspended:lastReviewDate:)`
    /// for the exact, unit-tested computation):
    ///   - `stability  ← max(interval_days, ε)` — the old SRS interval is a stability
    ///     proxy: the day-gap the element had already survived (ε = FSRS.stabilityMin).
    ///   - `difficulty ← default nudged by learning_state` (.learned 4 / .learning 5 /
    ///     .new|unknown 6, all in [1,10]; easier the further along the element was).
    ///   - `graduated_date ← last_review_date` IFF seeded `stability >= 21`
    ///     (FSRS.graduationStability) OR `suspended = 1` (suspended elements were
    ///     "done" under the old gate → stay graduated). Else NULL — those fall into
    ///     en-cours under the new gate (the honest re-rating of the old lenient 150).
    private func backfillFSRSState() {
        struct Row {
            let id: String
            let stability: Double
            let difficulty: Double
            let graduatedDate: Double?
            /// FSRS-derived next-review instant (`lastReview + intervalDays(S)`), so the
            /// Réviser due queue agrees with the freshly-seeded `S`/fragile flag from
            /// launch. `nil` when there's no `last_review_date` → keep the existing date.
            let nextReviewDate: Double?
        }
        var rows: [Row] = []

        var read: OpaquePointer?
        if sqlite3_prepare_v2(db,
            """
            SELECT element_id, interval_days, learning_state, suspended, last_review_date
            FROM review_status
            WHERE stability IS NULL;
            """,
            -1, &read, nil) == SQLITE_OK {
            while sqlite3_step(read) == SQLITE_ROW {
                guard let c = sqlite3_column_text(read, 0) else { continue }
                let id = String(cString: c)
                let interval = Int(sqlite3_column_int(read, 1))
                let stateRaw = sqlite3_column_text(read, 2).map { String(cString: $0) } ?? ""
                let learningState = LearningState(rawValue: stateRaw)
                let suspended = sqlite3_column_int(read, 3) != 0
                let lastReview: Date? = sqlite3_column_type(read, 4) != SQLITE_NULL
                    ? Date(timeIntervalSince1970: sqlite3_column_double(read, 4)) : nil

                let seed = DataManager.fsrsBackfill(
                    intervalDays: interval,
                    learningState: learningState,
                    suspended: suspended,
                    lastReviewDate: lastReview)
                // Re-schedule onto the FSRS curve: next due = last review + the interval
                // at which R decays to desiredRetention for the seeded S. Keeps the due
                // queue consistent with the fragile (R<0.80) flag post-migration.
                let nextReview = lastReview.map {
                    $0.addingTimeInterval(FSRS.intervalDays(stability: seed.stability) * 86_400)
                }
                rows.append(Row(id: id,
                                stability: seed.stability,
                                difficulty: seed.difficulty,
                                graduatedDate: seed.graduatedDate?.timeIntervalSince1970,
                                nextReviewDate: nextReview?.timeIntervalSince1970))
            }
        } else {
            print("Error preparing FSRS backfill read: \(String(cString: sqlite3_errmsg(db)))")
        }
        sqlite3_finalize(read)

        guard !rows.isEmpty else { return }

        sqlite3_exec(db, "BEGIN;", nil, nil, nil)
        var update: OpaquePointer?
        if sqlite3_prepare_v2(db,
            """
            UPDATE review_status
            SET stability = ?, difficulty = ?, graduated_date = ?,
                next_review_date = COALESCE(?, next_review_date)
            WHERE element_id = ?;
            """,
            -1, &update, nil) == SQLITE_OK {
            for row in rows {
                sqlite3_reset(update)
                sqlite3_bind_double(update, 1, row.stability)
                sqlite3_bind_double(update, 2, row.difficulty)
                if let g = row.graduatedDate {
                    sqlite3_bind_double(update, 3, g)
                } else {
                    sqlite3_bind_null(update, 3)
                }
                if let n = row.nextReviewDate {
                    sqlite3_bind_double(update, 4, n)
                } else {
                    sqlite3_bind_null(update, 4)   // keep existing next_review_date
                }
                sqlite3_bind_text(update, 5, (row.id as NSString).utf8String, -1, SQLITE_TRANSIENT)
                if sqlite3_step(update) != SQLITE_DONE {
                    print("Error backfilling FSRS state: \(String(cString: sqlite3_errmsg(db)))")
                }
            }
        } else {
            print("Error preparing FSRS backfill update: \(String(cString: sqlite3_errmsg(db)))")
        }
        sqlite3_finalize(update)
        sqlite3_exec(db, "COMMIT;", nil, nil, nil)
    }

    /// Pure, deterministic v4-backfill rule — derives seed FSRS `(S, D)` + the sticky
    /// `graduated_date` from a row's pre-FSRS spacing data. Extracted from
    /// `backfillFSRSState` so it is unit-testable without live SQLite (see
    /// `_selfTest()`). No `Date()` / `Calendar` — `lastReviewDate` enters as a param.
    static func fsrsBackfill(intervalDays: Int,
                             learningState: LearningState?,
                             suspended: Bool,
                             lastReviewDate: Date?) -> (stability: Double, difficulty: Double, graduatedDate: Date?) {
        // S ← the old interval (days survived), floored at FSRS.stabilityMin so it's
        // never 0 (a 0-interval massed element seeds at ε → far below the 21-day bar).
        let stability = max(Double(intervalDays), FSRS.stabilityMin)

        // D ← a sensible default nudged by how far the element had progressed: the
        // further along (.learned), the easier we assume it is. Values within [1,10],
        // centred near the FSRS mid-range so later real grades can drift either way.
        let difficulty: Double
        switch learningState {
        case .learned:  difficulty = 4.0   // easiest — repeatedly recalled
        case .learning: difficulty = 5.0   // mid
        case .new, .none: difficulty = 6.0 // hardest assumption — barely seen / unknown
        }

        // Sticky graduation: an element is re-rated maîtrisé iff its seeded stability
        // already clears the durable bar (deep-ladder element) OR it was suspended
        // ("too easy" → done under the old gate). Stamp the crossing day = the last
        // review; if that's missing, no honest crossing day → not graduated.
        let graduated = stability >= FSRS.graduationStability || suspended
        let graduatedDate = graduated ? lastReviewDate : nil

        return (stability, difficulty, graduatedDate)
    }

    /// Current `PRAGMA user_version` (0 on a DB that predates versioning).
    private func userVersion() -> Int32 {
        var v: Int32 = 0
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, "PRAGMA user_version;", -1, &statement, nil) == SQLITE_OK,
           sqlite3_step(statement) == SQLITE_ROW {
            v = sqlite3_column_int(statement, 0)
        }
        sqlite3_finalize(statement)
        return v
    }

    /// Stamp the schema version. `user_version` takes no bound parameters, so the
    /// Int32 is interpolated directly (no injection surface).
    private func setUserVersion(_ v: Int32) {
        sqlite3_exec(db, "PRAGMA user_version = \(v);", nil, nil, nil)
    }

    /// Copy the live DB to a temp file for backup/share. Checkpoints first so a
    /// WAL (if ever enabled) is folded into the main file, giving a consistent
    /// snapshot. Returns nil on failure.
    func exportSnapshot() -> URL? {
        var snapshot: URL?
        dbQueue.sync {
            sqlite3_exec(db, "PRAGMA wal_checkpoint(FULL);", nil, nil, nil)
            let dest = FileManager.default.temporaryDirectory
                .appendingPathComponent("carambole-progress.sqlite")
            try? FileManager.default.removeItem(at: dest)
            do {
                try FileManager.default.copyItem(at: databaseFileURL, to: dest)
                snapshot = dest
            } catch {
                print("Export snapshot failed: \(error)")
            }
        }
        return snapshot
    }

    private func tableExists(_ name: String) -> Bool {
        var exists = false
        let query = "SELECT name FROM sqlite_master WHERE type='table' AND name=?;"
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (name as NSString).utf8String, -1, SQLITE_TRANSIENT)
            if sqlite3_step(statement) == SQLITE_ROW { exists = true }
        }
        sqlite3_finalize(statement)
        return exists
    }

    private func columnExists(table: String, column: String) -> Bool {
        var found = false
        let query = "PRAGMA table_info(\(table));"
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                if let c = sqlite3_column_text(statement, 1),
                   String(cString: c) == column { found = true }
            }
        }
        sqlite3_finalize(statement)
        return found
    }

    // MARK: - Review status (one row per element)

    /// UPSERT one element's review status. `first_seen_date` is stamped once (the
    /// element's introduction) and preserved on later writes via COALESCE.
    func upsertReviewStatus(_ status: ReviewStatus) {
        dbQueue.async {
            let query = """
                INSERT INTO review_status
                    (element_id, learning_state, last_review_date, next_review_date,
                     interval_days, first_seen_date, suspended, distinct_correct, mastered_example_ids,
                     stability, difficulty, graduated_date)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(element_id) DO UPDATE SET
                    learning_state       = excluded.learning_state,
                    last_review_date     = excluded.last_review_date,
                    next_review_date     = excluded.next_review_date,
                    interval_days        = excluded.interval_days,
                    first_seen_date      = COALESCE(review_status.first_seen_date, excluded.first_seen_date),
                    suspended            = excluded.suspended,
                    distinct_correct     = excluded.distinct_correct,
                    mastered_example_ids = excluded.mastered_example_ids,
                    stability            = excluded.stability,
                    difficulty           = excluded.difficulty,
                    graduated_date       = excluded.graduated_date;
                """
            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK else {
                print("Error preparing review status upsert: \(String(cString: sqlite3_errmsg(self.db)))")
                return
            }
            sqlite3_bind_text(statement, 1, (status.elementID as NSString).utf8String, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 2, (status.learningState.rawValue as NSString).utf8String, -1, SQLITE_TRANSIENT)
            if let last = status.lastReviewDate {
                sqlite3_bind_double(statement, 3, last.timeIntervalSince1970)
            } else { sqlite3_bind_null(statement, 3) }
            if let next = status.nextReviewDate {
                sqlite3_bind_double(statement, 4, next.timeIntervalSince1970)
            } else { sqlite3_bind_null(statement, 4) }
            sqlite3_bind_int(statement, 5, Int32(status.intervalDays))
            let firstSeen = status.lastReviewDate?.timeIntervalSince1970 ?? Date().timeIntervalSince1970
            sqlite3_bind_double(statement, 6, firstSeen)
            sqlite3_bind_int(statement, 7, status.suspended ? 1 : 0)
            sqlite3_bind_int(statement, 8, Int32(status.distinctCorrect))
            let masteredJSON = (try? JSONEncoder().encode(Array(status.masteredExampleIDs)))
                .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
            sqlite3_bind_text(statement, 9, (masteredJSON as NSString).utf8String, -1, SQLITE_TRANSIENT)
            // FSRS state (v4): nil until the element's first FSRS grade.
            if let s = status.stability {
                sqlite3_bind_double(statement, 10, s)
            } else { sqlite3_bind_null(statement, 10) }
            if let d = status.difficulty {
                sqlite3_bind_double(statement, 11, d)
            } else { sqlite3_bind_null(statement, 11) }
            if let g = status.graduatedDate {
                sqlite3_bind_double(statement, 12, g.timeIntervalSince1970)
            } else { sqlite3_bind_null(statement, 12) }

            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error upserting review status: \(String(cString: sqlite3_errmsg(self.db)))")
            }
            sqlite3_finalize(statement)

            // Append-only review event: one (element_id, startOfDay) row per day the
            // element was reviewed. INSERT OR IGNORE collapses repeats within a day.
            if let last = status.lastReviewDate {
                let dayStart = Calendar.current.startOfDay(for: last).timeIntervalSince1970
                var logStmt: OpaquePointer?
                if sqlite3_prepare_v2(self.db,
                    "INSERT OR IGNORE INTO review_log (element_id, day_start) VALUES (?, ?);",
                    -1, &logStmt, nil) == SQLITE_OK {
                    sqlite3_bind_text(logStmt, 1, (status.elementID as NSString).utf8String, -1, SQLITE_TRANSIENT)
                    sqlite3_bind_double(logStmt, 2, dayStart)
                    if sqlite3_step(logStmt) != SQLITE_DONE {
                        print("Error logging review event: \(String(cString: sqlite3_errmsg(self.db)))")
                    }
                } else {
                    print("Error preparing review log insert: \(String(cString: sqlite3_errmsg(self.db)))")
                }
                sqlite3_finalize(logStmt)
            }

            // NOTE (v4): the old count-based mastery_log trigger
            // (`distinct_correct >= masteryThreshold || suspended`) is GONE. Under FSRS
            // a mastery_log row = a GRADUATION event, which is no longer derivable from
            // the count — it happens when `S` crosses the 21-day bar (a spaced success)
            // or via a too-easy skip. The grading layer (T3) records it explicitly by
            // calling `markGraduated`, and `setSuspended` calls it for the skip path.
            // A plain graded write here must NOT stamp a graduation.
        }
    }

    /// Stamp an element's GRADUATION (FSRS S crossed the 21-day bar, or a too-easy
    /// skip). Idempotent: sets the sticky `graduated_date` only if it's currently NULL
    /// (first crossing wins — later calls no-op), and `INSERT OR IGNORE`s the
    /// `mastery_log` row keyed on element_id (PK ⇒ only the first day sticks). Reuses
    /// the same `startOfDay(day)` bucketing the v3 mastery_log hook used. Calling this
    /// on an already-graduated element changes nothing.
    func markGraduated(elementID: String, on day: Date) {
        dbQueue.async {
            // Sticky flag — only stamp if not already graduated (COALESCE-style guard
            // via the WHERE clause so a re-graduate keeps the original crossing date).
            let dayTS = day.timeIntervalSince1970
            var flag: OpaquePointer?
            if sqlite3_prepare_v2(self.db,
                "UPDATE review_status SET graduated_date = ? WHERE element_id = ? AND graduated_date IS NULL;",
                -1, &flag, nil) == SQLITE_OK {
                sqlite3_bind_double(flag, 1, dayTS)
                sqlite3_bind_text(flag, 2, (elementID as NSString).utf8String, -1, SQLITE_TRANSIENT)
                if sqlite3_step(flag) != SQLITE_DONE {
                    print("Error stamping graduated_date: \(String(cString: sqlite3_errmsg(self.db)))")
                }
            } else {
                print("Error preparing graduated_date update: \(String(cString: sqlite3_errmsg(self.db)))")
            }
            sqlite3_finalize(flag)

            // Append-only mastery event: one row per element, the day it first
            // graduated. Same day bucket as the v3 hook (startOfDay).
            let dayStart = Calendar.current.startOfDay(for: day).timeIntervalSince1970
            var masteryStmt: OpaquePointer?
            if sqlite3_prepare_v2(self.db,
                "INSERT OR IGNORE INTO mastery_log (element_id, day_start) VALUES (?, ?);",
                -1, &masteryStmt, nil) == SQLITE_OK {
                sqlite3_bind_text(masteryStmt, 1, (elementID as NSString).utf8String, -1, SQLITE_TRANSIENT)
                sqlite3_bind_double(masteryStmt, 2, dayStart)
                if sqlite3_step(masteryStmt) != SQLITE_DONE {
                    print("Error logging mastery event: \(String(cString: sqlite3_errmsg(self.db)))")
                }
            } else {
                print("Error preparing mastery log insert: \(String(cString: sqlite3_errmsg(self.db)))")
            }
            sqlite3_finalize(masteryStmt)
        }
    }

    /// Fetch the persisted state for one element, or nil if never reviewed.
    func fetchReviewStatus(elementID: String) -> ReviewStatus? {
        var result: ReviewStatus?
        dbQueue.sync {
            let query = """
                SELECT learning_state, last_review_date, next_review_date, interval_days,
                       suspended, distinct_correct, mastered_example_ids,
                       stability, difficulty, graduated_date
                FROM review_status WHERE element_id = ?;
                """
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (elementID as NSString).utf8String, -1, SQLITE_TRANSIENT)
                if sqlite3_step(statement) == SQLITE_ROW {
                    let stateRaw = sqlite3_column_text(statement, 0).map { String(cString: $0) } ?? ""
                    var status = ReviewStatus(elementID: elementID,
                                              learningState: LearningState(rawValue: stateRaw) ?? .new,
                                              intervalDays: Int(sqlite3_column_int(statement, 3)))
                    status.lastReviewDate = sqlite3_column_type(statement, 1) != SQLITE_NULL ?
                        Date(timeIntervalSince1970: sqlite3_column_double(statement, 1)) : nil
                    status.nextReviewDate = sqlite3_column_type(statement, 2) != SQLITE_NULL ?
                        Date(timeIntervalSince1970: sqlite3_column_double(statement, 2)) : nil
                    status.suspended = sqlite3_column_int(statement, 4) != 0
                    status.distinctCorrect = Int(sqlite3_column_int(statement, 5))
                    if let json = sqlite3_column_text(statement, 6) {
                        let data = Data(String(cString: json).utf8)
                        status.masteredExampleIDs = (try? JSONDecoder().decode([String].self, from: data))
                            .map(Set.init) ?? []
                    }
                    // FSRS state (v4) — NULL until the first FSRS grade.
                    status.stability = sqlite3_column_type(statement, 7) != SQLITE_NULL ?
                        sqlite3_column_double(statement, 7) : nil
                    status.difficulty = sqlite3_column_type(statement, 8) != SQLITE_NULL ?
                        sqlite3_column_double(statement, 8) : nil
                    status.graduatedDate = sqlite3_column_type(statement, 9) != SQLITE_NULL ?
                        Date(timeIntervalSince1970: sqlite3_column_double(statement, 9)) : nil
                    result = status
                }
            } else {
                print("Error preparing review status fetch: \(String(cString: sqlite3_errmsg(self.db)))")
            }
            sqlite3_finalize(statement)
        }
        return result
    }

    /// Element ids whose next review is due on or before `date`, excluding
    /// suspended ("too easy") elements. Drives the Réviser queue.
    func fetchDueElementIDs(asOf date: Date) -> [String] {
        queryIDs("""
            SELECT element_id FROM review_status
            WHERE next_review_date IS NOT NULL AND next_review_date <= ?
              AND (suspended IS NULL OR suspended = 0);
            """, bindDouble: date.timeIntervalSince1970)
    }

    /// Every element id with a row (ever introduced). Suspended elements are
    /// included so they are NOT re-introduced as new.
    func fetchSeenElementIDs() -> Set<String> {
        Set(queryIDs("SELECT element_id FROM review_status;", bindDouble: nil))
    }

    /// Count of elements first introduced on the calendar day of `day`. Drives the
    /// `newPerDay` hard cap (now counted in elements).
    func countNewIntroduced(on day: Date) -> Int {
        var count = 0
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: day)
        let next = calendar.date(byAdding: .day, value: 1, to: start) ?? start
        dbQueue.sync {
            let query = "SELECT COUNT(*) FROM review_status WHERE first_seen_date >= ? AND first_seen_date < ?;"
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_double(statement, 1, start.timeIntervalSince1970)
                sqlite3_bind_double(statement, 2, next.timeIntervalSince1970)
                if sqlite3_step(statement) == SQLITE_ROW { count = Int(sqlite3_column_int(statement, 0)) }
            }
            sqlite3_finalize(statement)
        }
        return count
    }

    /// Not-yet-due review items of ONE book (soonest-due first), excluding
    /// suspended, capped at `limit`. Tops up the review queue toward the soft target.
    ///
    /// The book filter runs BEFORE the cap (`StudyScheduler.scopedOverflow`): the
    /// table holds every book's rows, and a SQL `LIMIT` ahead of the filter let
    /// another book's soonest-due IDs use up the whole limit, starving this one.
    func fetchOverflowElementIDs(asOf now: Date, limit: Int, within bookIDs: Set<String>) -> [String] {
        guard limit > 0 else { return [] }
        var ids: [String] = []
        dbQueue.sync {
            let query = """
                SELECT element_id FROM review_status
                WHERE next_review_date IS NOT NULL AND next_review_date > ?
                  AND (suspended IS NULL OR suspended = 0)
                ORDER BY next_review_date ASC, interval_days ASC;
                """
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_double(statement, 1, now.timeIntervalSince1970)
                while sqlite3_step(statement) == SQLITE_ROW {
                    if let c = sqlite3_column_text(statement, 0) { ids.append(String(cString: c)) }
                }
            }
            sqlite3_finalize(statement)
        }
        return StudyScheduler.scopedOverflow(ids, bookIDs: bookIDs, limit: limit)
    }

    // MARK: - En situation (Book 2) item + attempt logs (v5)

    /// Record one finished item: stamp `last_done`, bump `times`, keep its rating.
    func logSituationItem(itemID: String, elementID: String, rating: SituationOutcome, at date: Date) {
        dbQueue.async {
            let query = """
                INSERT INTO situation_item_log (item_id, element_id, last_done, times, last_rating)
                VALUES (?, ?, ?, 1, ?)
                ON CONFLICT(item_id) DO UPDATE SET
                    last_done = excluded.last_done,
                    times = situation_item_log.times + 1,
                    last_rating = excluded.last_rating;
                """
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (itemID as NSString).utf8String, -1, SQLITE_TRANSIENT)
                sqlite3_bind_text(statement, 2, (elementID as NSString).utf8String, -1, SQLITE_TRANSIENT)
                sqlite3_bind_double(statement, 3, date.timeIntervalSince1970)
                sqlite3_bind_int(statement, 4, Int32(rating.rawValue))
                if sqlite3_step(statement) != SQLITE_DONE {
                    print("Error logging situation item: \(String(cString: sqlite3_errmsg(self.db)))")
                }
            } else {
                print("Error preparing situation item log: \(String(cString: sqlite3_errmsg(self.db)))")
            }
            sqlite3_finalize(statement)
        }
    }

    /// Item history for one element's items, keyed by item ID.
    func fetchSituationItemHistory(elementID: String) -> [String: SituationItemHistory] {
        var result: [String: SituationItemHistory] = [:]
        dbQueue.sync {
            let query = "SELECT item_id, last_done, times, last_rating FROM situation_item_log WHERE element_id = ?;"
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (elementID as NSString).utf8String, -1, SQLITE_TRANSIENT)
                while sqlite3_step(statement) == SQLITE_ROW {
                    guard let c = sqlite3_column_text(statement, 0) else { continue }
                    result[String(cString: c)] = SituationItemHistory(
                        lastDone: Date(timeIntervalSince1970: sqlite3_column_double(statement, 1)),
                        times: Int(sqlite3_column_int(statement, 2)),
                        lastOutcome: SituationOutcome(rawValue: Int(sqlite3_column_int(statement, 3))) ?? .good)
                }
            }
            sqlite3_finalize(statement)
        }
        return result
    }

    // MARK: - Nuances (Book 3) card history (v6)

    /// Record one finished card, preserving its cumulative attempt count.
    func logNuanceCard(cardID: String, elementID: String, rating: Int, at date: Date) {
        guard (1...3).contains(rating) else { return }
        dbQueue.async {
            let query = """
                INSERT INTO nuance_card_log (card_id, element_id, last_done, times, last_rating)
                VALUES (?, ?, ?, 1, ?)
                ON CONFLICT(card_id) DO UPDATE SET
                    last_done = excluded.last_done,
                    times = nuance_card_log.times + 1,
                    last_rating = excluded.last_rating;
                """
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (cardID as NSString).utf8String, -1, SQLITE_TRANSIENT)
                sqlite3_bind_text(statement, 2, (elementID as NSString).utf8String, -1, SQLITE_TRANSIENT)
                sqlite3_bind_double(statement, 3, date.timeIntervalSince1970)
                sqlite3_bind_int(statement, 4, Int32(rating))
                if sqlite3_step(statement) != SQLITE_DONE {
                    print("Error logging nuance card: \(String(cString: sqlite3_errmsg(self.db)))")
                }
            } else {
                print("Error preparing nuance card log: \(String(cString: sqlite3_errmsg(self.db)))")
            }
            sqlite3_finalize(statement)
        }
    }

    /// Card history for one Nuances element, keyed by card ID.
    func fetchNuanceCardHistory(elementID: String) -> [String: NuanceCardHistory] {
        var result: [String: NuanceCardHistory] = [:]
        dbQueue.sync {
            let query = "SELECT card_id, last_done, times, last_rating FROM nuance_card_log WHERE element_id = ?;"
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (elementID as NSString).utf8String, -1, SQLITE_TRANSIENT)
                while sqlite3_step(statement) == SQLITE_ROW {
                    guard let c = sqlite3_column_text(statement, 0) else { continue }
                    result[String(cString: c)] = NuanceCardHistory(
                        lastDone: Date(timeIntervalSince1970: sqlite3_column_double(statement, 1)),
                        times: Int(sqlite3_column_int(statement, 2)),
                        lastRating: Int(sqlite3_column_int(statement, 3)))
                }
            }
            sqlite3_finalize(statement)
        }
        return result
    }

    /// Make a Nuances group fresh again after an armed Too Easy answer fails.
    func clearNuanceCardHistory(elementID: String) {
        dbQueue.async {
            let query = "DELETE FROM nuance_card_log WHERE element_id = ?;"
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (elementID as NSString).utf8String, -1, SQLITE_TRANSIENT)
                if sqlite3_step(statement) != SQLITE_DONE {
                    print("Error clearing nuance card history: \(String(cString: sqlite3_errmsg(self.db)))")
                }
            } else {
                print("Error preparing nuance card history clear: \(String(cString: sqlite3_errmsg(self.db)))")
            }
            sqlite3_finalize(statement)
        }
    }

    /// One wrong attempt, kept so the learner's own mistakes can be shown back.
    struct SituationAttempt: Equatable {
        let bookID: String
        let elementID: String
        let dialogueID: String
        let drillType: String
        let given: String
        let expected: String
        let reason: String?
        let createdAt: Date
    }

    func logSituationAttempt(_ attempt: SituationAttempt) {
        dbQueue.async {
            let query = """
                INSERT INTO situation_attempt_log
                    (book_id, element_id, dialogue_id, drill_type, given, expected, reason, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?);
                """
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
                let texts = [attempt.bookID, attempt.elementID, attempt.dialogueID, attempt.drillType,
                             attempt.given, attempt.expected]
                for (i, text) in texts.enumerated() {
                    sqlite3_bind_text(statement, Int32(i + 1), (text as NSString).utf8String, -1, SQLITE_TRANSIENT)
                }
                if let reason = attempt.reason {
                    sqlite3_bind_text(statement, 7, (reason as NSString).utf8String, -1, SQLITE_TRANSIENT)
                } else {
                    sqlite3_bind_null(statement, 7)
                }
                sqlite3_bind_double(statement, 8, attempt.createdAt.timeIntervalSince1970)
                if sqlite3_step(statement) != SQLITE_DONE {
                    print("Error logging situation attempt: \(String(cString: sqlite3_errmsg(self.db)))")
                }
            } else {
                print("Error preparing situation attempt log: \(String(cString: sqlite3_errmsg(self.db)))")
            }
            sqlite3_finalize(statement)
        }
    }

    /// Wrong attempts for one book, newest first.
    func fetchSituationAttempts(bookID: String, limit: Int = 500) -> [SituationAttempt] {
        var rows: [SituationAttempt] = []
        dbQueue.sync {
            let query = """
                SELECT book_id, element_id, dialogue_id, drill_type, given, expected, reason, created_at
                FROM situation_attempt_log WHERE book_id = ?
                ORDER BY created_at DESC, id DESC LIMIT ?;
                """
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (bookID as NSString).utf8String, -1, SQLITE_TRANSIENT)
                sqlite3_bind_int(statement, 2, Int32(limit))
                while sqlite3_step(statement) == SQLITE_ROW {
                    func text(_ i: Int32) -> String {
                        sqlite3_column_text(statement, i).map { String(cString: $0) } ?? ""
                    }
                    rows.append(SituationAttempt(
                        bookID: text(0), elementID: text(1), dialogueID: text(2), drillType: text(3),
                        given: text(4), expected: text(5),
                        reason: sqlite3_column_type(statement, 6) == SQLITE_NULL ? nil : text(6),
                        createdAt: Date(timeIntervalSince1970: sqlite3_column_double(statement, 7))))
                }
            }
            sqlite3_finalize(statement)
        }
        return rows
    }

    /// Element ids that have GRADUATED — the sticky `graduated_date` flag is set. This
    /// is the bar's maîtrisé set under FSRS: exact + monotonic, read from the live flag
    /// (NOT the historical `mastery_log`). Set once `S` crosses 21d via a spaced success
    /// or a too-easy skip; never un-set by decay (T4 surfaces forgetting as "fragile").
    func fetchGraduatedElementIDs() -> Set<String> {
        Set(queryIDs("SELECT element_id FROM review_status WHERE graduated_date IS NOT NULL;",
                     bindDouble: nil))
    }

    /// Elements whose introduction has succeeded. A wrong first answer creates a
    /// review row but does not count as learned; a clean "Trop facile" does.
    func fetchIntroducedElementIDs() -> Set<String> {
        Set(queryIDs("""
            SELECT element_id FROM review_status
            WHERE distinct_correct > 0 OR graduated_date IS NOT NULL OR suspended = 1;
            """, bindDouble: nil))
    }

    /// FSRS state for every graduated, non-suspended element that has a stability —
    /// the rows whose predicted recall `R(now)` can still decay into "fragile". A
    /// suspended element never decays (the too-easy-skip graduation path), so it is
    /// excluded here; a graduated row without a stability (shouldn't happen post-v4)
    /// is excluded too. ONE query (no N+1). The caller computes `R` per row via
    /// `FSRS.retrievability` over the calendar-day gap since `lastReviewDate`.
    func fetchGraduatedStates() -> [(elementID: String, stability: Double, lastReviewDate: Date?)] {
        var rows: [(elementID: String, stability: Double, lastReviewDate: Date?)] = []
        dbQueue.sync {
            let query = """
                SELECT element_id, stability, last_review_date FROM review_status
                WHERE graduated_date IS NOT NULL
                  AND (suspended IS NULL OR suspended = 0)
                  AND stability IS NOT NULL;
                """
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
                while sqlite3_step(statement) == SQLITE_ROW {
                    guard let c = sqlite3_column_text(statement, 0) else { continue }
                    let id = String(cString: c)
                    let stability = sqlite3_column_double(statement, 1)
                    let last: Date? = sqlite3_column_type(statement, 2) != SQLITE_NULL
                        ? Date(timeIntervalSince1970: sqlite3_column_double(statement, 2))
                        : nil
                    rows.append((id, stability, last))
                }
            }
            sqlite3_finalize(statement)
        }
        return rows
    }

    // MARK: - Per-day history (learned & reviewed)

    /// Element ids first introduced on the calendar day of `day`. Window computed
    /// in Swift via Calendar, mirroring `countNewIntroduced`.
    func fetchElementIDsFirstSeen(on day: Date) -> Set<String> {
        var ids: Set<String> = []
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: day)
        let next = calendar.date(byAdding: .day, value: 1, to: start) ?? start
        dbQueue.sync {
            let query = "SELECT element_id FROM review_status WHERE first_seen_date >= ? AND first_seen_date < ?;"
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_double(statement, 1, start.timeIntervalSince1970)
                sqlite3_bind_double(statement, 2, next.timeIntervalSince1970)
                while sqlite3_step(statement) == SQLITE_ROW {
                    if let c = sqlite3_column_text(statement, 0) { ids.insert(String(cString: c)) }
                }
            }
            sqlite3_finalize(statement)
        }
        return ids
    }

    /// Element ids logged as reviewed on the calendar day of `day`. `day_start` is
    /// already a startOfDay stamp, so this is an exact match.
    func fetchElementIDsReviewedLogged(on day: Date) -> Set<String> {
        var ids: Set<String> = []
        let start = Calendar.current.startOfDay(for: day).timeIntervalSince1970
        dbQueue.sync {
            let query = "SELECT element_id FROM review_log WHERE day_start = ?;"
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_double(statement, 1, start)
                while sqlite3_step(statement) == SQLITE_ROW {
                    if let c = sqlite3_column_text(statement, 0) { ids.insert(String(cString: c)) }
                }
            }
            sqlite3_finalize(statement)
        }
        return ids
    }

    /// Every element's `first_seen_date` (the introduction stamp), as
    /// element_id → Date. Drives the historical "learned per day" reconstruction.
    func fetchFirstSeenByElement() -> [String: Date] {
        var result: [String: Date] = [:]
        dbQueue.sync {
            let query = "SELECT element_id, first_seen_date FROM review_status WHERE first_seen_date IS NOT NULL;"
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
                while sqlite3_step(statement) == SQLITE_ROW {
                    if let c = sqlite3_column_text(statement, 0) {
                        result[String(cString: c)] = Date(timeIntervalSince1970: sqlite3_column_double(statement, 1))
                    }
                }
            }
            sqlite3_finalize(statement)
        }
        return result
    }

    /// Every `review_log` event as (elementID, dayStart). Drives the historical
    /// "reviewed per day" reconstruction.
    func fetchReviewLog() -> [(elementID: String, dayStart: Date)] {
        var rows: [(elementID: String, dayStart: Date)] = []
        dbQueue.sync {
            let query = "SELECT element_id, day_start FROM review_log;"
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
                while sqlite3_step(statement) == SQLITE_ROW {
                    if let c = sqlite3_column_text(statement, 0) {
                        rows.append((String(cString: c),
                                     Date(timeIntervalSince1970: sqlite3_column_double(statement, 1))))
                    }
                }
            }
            sqlite3_finalize(statement)
        }
        return rows
    }

    /// Every `mastery_log` event as (elementID, dayStart) — one row per element, the
    /// day it first became satisfied. Drives the masteries-per-day finish-pace.
    func fetchMasteryLog() -> [(elementID: String, dayStart: Date)] {
        var rows: [(elementID: String, dayStart: Date)] = []
        dbQueue.sync {
            let query = "SELECT element_id, day_start FROM mastery_log;"
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
                while sqlite3_step(statement) == SQLITE_ROW {
                    if let c = sqlite3_column_text(statement, 0) {
                        rows.append((String(cString: c),
                                     Date(timeIntervalSince1970: sqlite3_column_double(statement, 1))))
                    }
                }
            }
            sqlite3_finalize(statement)
        }
        return rows
    }

    /// Mark an element "too easy" — suspended from the new + review queues. Under FSRS
    /// this is the self-attested-skip graduation path (design decision #5): suspended ⇒
    /// graduated, matching the old "satisfied" behaviour. So besides flipping
    /// `suspended`, it stamps the sticky `graduated_date` + logs the mastery event via
    /// `markGraduated`. Both run on the serial `dbQueue`, so the suspend write here
    /// lands before the graduation stamp. The crossing day is today (a live user action).
    func setSuspended(elementID: String) {
        dbQueue.async {
            var statement: OpaquePointer?
            let update = "UPDATE review_status SET suspended = 1 WHERE element_id = ?;"
            if sqlite3_prepare_v2(self.db, update, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (elementID as NSString).utf8String, -1, SQLITE_TRANSIENT)
                if sqlite3_step(statement) != SQLITE_DONE {
                    print("Error executing \(update): \(String(cString: sqlite3_errmsg(self.db)))")
                }
            }
            sqlite3_finalize(statement)
        }
        // Stamps graduated_date (if not already) + the mastery_log row. Also a
        // dbQueue.async, enqueued after the suspend write above → ordered.
        markGraduated(elementID: elementID, on: Date())
    }

    /// Delete an element's row — "clean records" (drops back to fresh/unseen). Note:
    /// intentionally does NOT delete any `mastery_log` row — that log is historical
    /// (see the v3 migration comment); a past mastery stays recorded for the pace.
    func clearReviewStatus(elementID: String) {
        execWithID("DELETE FROM review_status WHERE element_id = ?;", id: elementID)
    }

    /// Un-graduate ("remettre en cours") — move a graduated element back to en-cours,
    /// for an accidental graduation (massed-by-mistake, or a "Trop facile" the learner
    /// regrets). The inverse of `markGraduated` at the row level, in ONE statement on
    /// the serial `dbQueue`:
    ///   - `graduated_date → NULL` — drops it from the live maîtrisé set
    ///     (`fetchGraduatedElementIDs`), so the bar's green segment shrinks on the next
    ///     `refresh()`. This sticky flag is the ONLY thing the bar reads, so clearing
    ///     it is what actually demotes the element.
    ///   - `suspended → 0` — re-enters the new/review queues (a "too easy" skip had
    ///     suspended it; an earned graduate was never suspended, so this is a harmless
    ///     no-op there).
    ///   - `stability → min(current, relearnStability)`, floored at `stabilityMin` —
    ///     knocks `S` below the 21-day graduation bar so the element genuinely lands in
    ///     en-cours (`S < 21d`) and must RE-EARN graduation through spaced success. We
    ///     never raise `S` (a freshly-massed graduate may already be under 7d). A row
    ///     with no FSRS state yet (`stability IS NULL`, shouldn't happen for a graduate)
    ///     is seeded to `relearnStability` via COALESCE so it still re-enters as en-cours.
    ///   - `difficulty` is KEPT (the element's learned hardness survives the demote).
    ///   - `next_review_date ≈ now`, `last_review_date = now` — re-enters the Réviser
    ///     queue right away (`fetchDueElementIDs` keys off `next_review_date <= now`).
    /// The `mastery_log` row is intentionally LEFT (historical event log, matching the
    /// `clearReviewStatus` convention — only the live `graduated_date` flag drives the
    /// bar, so the demote takes effect immediately without retracting past pace data).
    ///
    /// Idempotent-ish: calling it on a non-graduated element just re-asserts an
    /// en-cours state (clears an already-NULL flag, caps an already-low `S`) — harmless.
    /// A row that doesn't exist at all is untouched (the `WHERE element_id = ?` matches
    /// nothing).
    func demote(elementID: String) {
        dbQueue.async {
            let now = Date().timeIntervalSince1970
            let relearn = FSRS.relearnStability
            let floor = FSRS.stabilityMin
            let query = """
                UPDATE review_status SET
                    graduated_date   = NULL,
                    suspended        = 0,
                    stability        = MAX(?, MIN(COALESCE(stability, ?), ?)),
                    last_review_date = ?,
                    next_review_date = ?
                WHERE element_id = ?;
                """
            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK else {
                print("Error preparing demote: \(String(cString: sqlite3_errmsg(self.db)))")
                return
            }
            // stability ← max(floor, min(coalesce(stability, relearn), relearn))
            sqlite3_bind_double(statement, 1, floor)
            sqlite3_bind_double(statement, 2, relearn)
            sqlite3_bind_double(statement, 3, relearn)
            sqlite3_bind_double(statement, 4, now)   // last_review_date = now
            sqlite3_bind_double(statement, 5, now)   // next_review_date ≈ now (due immediately)
            sqlite3_bind_text(statement, 6, (elementID as NSString).utf8String, -1, SQLITE_TRANSIENT)
            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error demoting element: \(String(cString: sqlite3_errmsg(self.db)))")
            }
            sqlite3_finalize(statement)
        }
    }

    // MARK: - Small query helpers

    private func queryIDs(_ query: String, bindDouble value: Double?) -> [String] {
        var ids: [String] = []
        dbQueue.sync {
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
                if let value { sqlite3_bind_double(statement, 1, value) }
                while sqlite3_step(statement) == SQLITE_ROW {
                    if let c = sqlite3_column_text(statement, 0) { ids.append(String(cString: c)) }
                }
            } else {
                print("Error preparing query: \(String(cString: sqlite3_errmsg(self.db)))")
            }
            sqlite3_finalize(statement)
        }
        return ids
    }

    private func execWithID(_ query: String, id: String) {
        dbQueue.async {
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (id as NSString).utf8String, -1, SQLITE_TRANSIENT)
                if sqlite3_step(statement) != SQLITE_DONE {
                    print("Error executing \(query): \(String(cString: sqlite3_errmsg(self.db)))")
                }
            }
            sqlite3_finalize(statement)
        }
    }
}

// MARK: - Self-test (pure v4-backfill rule, no live SQLite)
//
// Exercises `fsrsBackfill` — the deterministic core of the v4 migration — over the
// cases that matter for "the existing 150 re-rated honestly": deep-ladder graduates,
// massed interval-1 demotes to en-cours, suspended stays graduated, and the D nudge
// per learning_state. No DB is touched (the migration's SQLite plumbing is judged by
// the build + the additive/idempotent reasoning in the review).

#if DEBUG
extension DataManager {
    static func _selfTest() {
        let day = Date(timeIntervalSince1970: 1_700_000_000)

        // Deep-ladder element (interval 35 ≥ 21) → graduated, stamped at last review.
        let deep = fsrsBackfill(intervalDays: 35, learningState: .learned, suspended: false, lastReviewDate: day)
        assert(deep.stability == 35.0, "S ← interval (35)")
        assert(deep.difficulty == 4.0, ".learned → D 4")
        assert(deep.graduatedDate == day, "interval ≥ 21 graduates at last review")

        // Exactly at the 21-day bar → graduates (>= is inclusive).
        let atBar = fsrsBackfill(intervalDays: 21, learningState: .learned, suspended: false, lastReviewDate: day)
        assert(atBar.graduatedDate == day, "interval == 21 graduates (inclusive bar)")

        // Just below the bar (interval 16, the old ladder rung under 21) → en cours.
        let shallow = fsrsBackfill(intervalDays: 16, learningState: .learning, suspended: false, lastReviewDate: day)
        assert(shallow.stability == 16.0, "S ← interval (16)")
        assert(shallow.difficulty == 5.0, ".learning → D 5")
        assert(shallow.graduatedDate == nil, "interval < 21 → not graduated (en cours)")

        // Massed interval-0 element (3-in-a-session under the old gate) → S floored at
        // ε, NOT graduated. This is the lenient-massing case the design demotes.
        let massed = fsrsBackfill(intervalDays: 0, learningState: .new, suspended: false, lastReviewDate: day)
        assert(massed.stability == FSRS.stabilityMin, "interval 0 → S floored at ε")
        assert(massed.difficulty == 6.0, ".new → D 6")
        assert(massed.graduatedDate == nil, "massed interval-0 → demoted to en cours")

        // Suspended ("too easy") stays graduated regardless of interval.
        let easy = fsrsBackfill(intervalDays: 1, learningState: .learning, suspended: true, lastReviewDate: day)
        assert(easy.graduatedDate == day, "suspended stays graduated even at interval 1")

        // Graduated but no last-review timestamp → no honest crossing day → nil.
        let noStamp = fsrsBackfill(intervalDays: 35, learningState: .learned, suspended: false, lastReviewDate: nil)
        assert(noStamp.graduatedDate == nil, "graduated w/o last_review_date → no stamp")

        // Unknown learning_state (nil) defaults to the hardest D, like .new.
        let unknown = fsrsBackfill(intervalDays: 5, learningState: nil, suspended: false, lastReviewDate: day)
        assert(unknown.difficulty == 6.0, "unknown state → D 6")

        // All seeded difficulties live in FSRS's [1, 10] range.
        for d in [deep.difficulty, shallow.difficulty, massed.difficulty] {
            assert(d >= 1.0 && d <= 10.0, "seeded D in [1,10]")
        }
    }
}
#endif
