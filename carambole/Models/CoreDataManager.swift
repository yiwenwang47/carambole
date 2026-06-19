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

    private init() {
        setupDatabase()
    }

    // MARK: - Setup & migration

    private func setupDatabase() {
        let fileURL = try! FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("carambole.sqlite")
        print("Database path: \(fileURL.path)")

        guard sqlite3_open(fileURL.path, &db) == SQLITE_OK else {
            print("Error opening database: \(String(cString: sqlite3_errmsg(db)))")
            return
        }

        // Content tables from the pre-Book schema are obsolete (content is now
        // in-memory). Drop them if an old install left them behind.
        sqlite3_exec(db, "DROP TABLE IF EXISTS topics;", nil, nil, nil)
        sqlite3_exec(db, "DROP TABLE IF EXISTS exercises;", nil, nil, nil)

        // review_status was keyed by exercise_id before the element rekey. That
        // old shape is incompatible (and its per-exercise progress is meaningless
        // under element-level SRS), so drop it and start clean. No production users
        // yet; dev keeps its reseed-on-uninstall habit. (This is the place the
        // CLAUDE.md tech-debt note asks for — a real `user_version` scheme can
        // layer on later.)
        if tableExists("review_status") && !columnExists(table: "review_status", column: "element_id") {
            print("Migrating: dropping old exercise-keyed review_status")
            sqlite3_exec(db, "DROP TABLE IF EXISTS review_status;", nil, nil, nil)
        }

        let create = """
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
            """
        sqlite3_exec(db, create, nil, nil, nil)

        // Idempotent column adds for an element-keyed table predating these
        // columns. ALTER fails with "duplicate column name" when present; ignored.
        for alter in [
            "ALTER TABLE review_status ADD COLUMN suspended INTEGER DEFAULT 0;",
            "ALTER TABLE review_status ADD COLUMN distinct_correct INTEGER DEFAULT 0;",
            "ALTER TABLE review_status ADD COLUMN mastered_example_ids TEXT DEFAULT '[]';",
        ] {
            sqlite3_exec(db, alter, nil, nil, nil)
        }
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
