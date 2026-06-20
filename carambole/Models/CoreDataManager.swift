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
                     interval_days, first_seen_date, suspended, distinct_correct, mastered_example_ids)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(element_id) DO UPDATE SET
                    learning_state       = excluded.learning_state,
                    last_review_date     = excluded.last_review_date,
                    next_review_date     = excluded.next_review_date,
                    interval_days        = excluded.interval_days,
                    first_seen_date      = COALESCE(review_status.first_seen_date, excluded.first_seen_date),
                    suspended            = excluded.suspended,
                    distinct_correct     = excluded.distinct_correct,
                    mastered_example_ids = excluded.mastered_example_ids;
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
        }
    }

    /// Fetch the persisted state for one element, or nil if never reviewed.
    func fetchReviewStatus(elementID: String) -> ReviewStatus? {
        var result: ReviewStatus?
        dbQueue.sync {
            let query = """
                SELECT learning_state, last_review_date, next_review_date, interval_days,
                       suspended, distinct_correct, mastered_example_ids
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

    /// Not-yet-due review items (soonest-due first), excluding suspended, capped at
    /// `limit`. Tops up the review queue toward the soft target.
    func fetchOverflowElementIDs(asOf now: Date, limit: Int) -> [String] {
        guard limit > 0 else { return [] }
        var ids: [String] = []
        dbQueue.sync {
            let query = """
                SELECT element_id FROM review_status
                WHERE next_review_date IS NOT NULL AND next_review_date > ?
                  AND (suspended IS NULL OR suspended = 0)
                ORDER BY next_review_date ASC, interval_days ASC
                LIMIT ?;
                """
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_double(statement, 1, now.timeIntervalSince1970)
                sqlite3_bind_int(statement, 2, Int32(limit))
                while sqlite3_step(statement) == SQLITE_ROW {
                    if let c = sqlite3_column_text(statement, 0) { ids.append(String(cString: c)) }
                }
            }
            sqlite3_finalize(statement)
        }
        return ids
    }

    /// Element ids that satisfy the module-unlock gate: mastered
    /// (`distinct_correct >= threshold`) OR suspended ("too easy" counts as done).
    func fetchUnlockSatisfiedElementIDs(threshold: Int) -> Set<String> {
        var ids: Set<String> = []
        dbQueue.sync {
            let query = "SELECT element_id FROM review_status WHERE suspended = 1 OR distinct_correct >= ?;"
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_int(statement, 1, Int32(threshold))
                while sqlite3_step(statement) == SQLITE_ROW {
                    if let c = sqlite3_column_text(statement, 0) { ids.insert(String(cString: c)) }
                }
            }
            sqlite3_finalize(statement)
        }
        return ids
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

    /// Mark an element "too easy" — suspended from the new + review queues.
    func setSuspended(elementID: String) {
        execWithID("UPDATE review_status SET suspended = 1 WHERE element_id = ?;", id: elementID)
    }

    /// Delete an element's row — "clean records" (drops back to fresh/unseen).
    func clearReviewStatus(elementID: String) {
        execWithID("DELETE FROM review_status WHERE element_id = ?;", id: elementID)
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
