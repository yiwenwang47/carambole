import Foundation
import SQLite3

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

class DataManager {
    static let shared = DataManager()
    private var db: OpaquePointer?
    private let dbQueue = DispatchQueue(label: "com.carambole.database", qos: .userInitiated)
    
    private init() {
        setupDatabase()
    }
    
    private func setupDatabase() {
        print("Setting up database...")
        let fileURL = try! FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("carambole.sqlite")
        
        print("Database path: \(fileURL.path)")
        
        // Only delete database if it's empty or corrupted
        if FileManager.default.fileExists(atPath: fileURL.path) {
            print("Database file exists, checking if it needs initialization...")
            if sqlite3_open(fileURL.path, &self.db) == SQLITE_OK {
                // Check if tables exist and have data
                let checkQuery = "SELECT COUNT(*) FROM topics;"
                var statement: OpaquePointer?
                if sqlite3_prepare_v2(self.db, checkQuery, -1, &statement, nil) == SQLITE_OK {
                    if sqlite3_step(statement) == SQLITE_ROW {
                        let count = sqlite3_column_int(statement, 0)
                        if count > 0 {
                            print("Database already initialized with \(count) topics")
                            sqlite3_finalize(statement)
                            return
                        }
                    }
                }
                sqlite3_finalize(statement)
                sqlite3_close(self.db)
                print("Database exists but is empty, will reinitialize")
            }
            // Delete existing database to start fresh
            try? FileManager.default.removeItem(at: fileURL)
            print("Deleted existing database file")
        }
        
        if sqlite3_open(fileURL.path, &self.db) != SQLITE_OK {
            print("Error opening database: \(String(cString: sqlite3_errmsg(self.db)))")
            return
        }
        
        print("Successfully opened database connection")
        
        // Enable foreign keys
        if sqlite3_exec(self.db, "PRAGMA foreign_keys = ON;", nil, nil, nil) != SQLITE_OK {
            print("Error enabling foreign keys")
        }
        
        // Create tables
        let createTables = [
            """
            CREATE TABLE IF NOT EXISTS topics (
                id TEXT PRIMARY KEY,
                title TEXT NOT NULL,
                sort_order INTEGER,
                prerequisite_id TEXT,
                rule_note TEXT
            );
            """,
            """
            CREATE TABLE IF NOT EXISTS exercises (
                id TEXT PRIMARY KEY,
                topic_id TEXT NOT NULL,
                type TEXT,
                prompt TEXT,
                cue TEXT,
                answer_tokens TEXT,
                token_bank TEXT,
                input_mode TEXT,
                explanation TEXT,
                translation TEXT,
                hint TEXT
            );
            """,
            """
            CREATE TABLE IF NOT EXISTS review_status (
                exercise_id TEXT PRIMARY KEY,
                learning_state TEXT,
                last_review_date REAL,
                next_review_date REAL,
                interval_days INTEGER,
                first_seen_date REAL
            );
            """
        ]
        
        for createTable in createTables {
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, createTable, -1, &statement, nil) == SQLITE_OK {
                if sqlite3_step(statement) == SQLITE_DONE {
                    print("Successfully created table")
                } else {
                    print("Error creating table: \(String(cString: sqlite3_errmsg(self.db)))")
                }
            }
            sqlite3_finalize(statement)
        }
    }

    // MARK: - Grammar Topics & Exercises

    func upsertTopic(_ topic: GrammarTopic) {
        dbQueue.async {
            print("Upserting topic: \(topic.title) (ID: \(topic.id))")

            // Start transaction
            if sqlite3_exec(self.db, "BEGIN TRANSACTION;", nil, nil, nil) != SQLITE_OK {
                print("Error starting transaction")
                return
            }

            // Upsert topic row
            let upsertTopicQuery = """
                INSERT OR REPLACE INTO topics (id, title, sort_order, prerequisite_id, rule_note)
                VALUES (?, ?, ?, ?, ?);
            """
            var statement: OpaquePointer?

            if sqlite3_prepare_v2(self.db, upsertTopicQuery, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (topic.id as NSString).utf8String, -1, SQLITE_TRANSIENT)
                sqlite3_bind_text(statement, 2, (topic.title as NSString).utf8String, -1, SQLITE_TRANSIENT)
                sqlite3_bind_int(statement, 3, Int32(topic.sortOrder))
                if let prerequisiteID = topic.prerequisiteID {
                    sqlite3_bind_text(statement, 4, (prerequisiteID as NSString).utf8String, -1, SQLITE_TRANSIENT)
                } else {
                    sqlite3_bind_null(statement, 4)
                }
                sqlite3_bind_text(statement, 5, (topic.ruleNote as NSString).utf8String, -1, SQLITE_TRANSIENT)

                if sqlite3_step(statement) == SQLITE_DONE {
                    print("Successfully upserted topic with ID: \(topic.id)")
                } else {
                    print("Error upserting topic: \(String(cString: sqlite3_errmsg(self.db)))")
                    sqlite3_exec(self.db, "ROLLBACK;", nil, nil, nil)
                    sqlite3_finalize(statement)
                    return
                }
            } else {
                print("Error preparing topic upsert: \(String(cString: sqlite3_errmsg(self.db)))")
                sqlite3_exec(self.db, "ROLLBACK;", nil, nil, nil)
                sqlite3_finalize(statement)
                return
            }
            sqlite3_finalize(statement)

            // Upsert each exercise row
            let upsertExerciseQuery = """
                INSERT OR REPLACE INTO exercises (id, topic_id, type, prompt, cue, answer_tokens, token_bank, input_mode, explanation, translation, hint)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
            """
            for exercise in topic.exercises {
                var exerciseStatement: OpaquePointer?
                if sqlite3_prepare_v2(self.db, upsertExerciseQuery, -1, &exerciseStatement, nil) == SQLITE_OK {
                    let answerTokensJSON = (try? JSONEncoder().encode(exercise.answerTokens))
                        .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
                    let tokenBankJSON = (try? JSONEncoder().encode(exercise.tokenBank))
                        .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"

                    sqlite3_bind_text(exerciseStatement, 1, (exercise.id as NSString).utf8String, -1, SQLITE_TRANSIENT)
                    sqlite3_bind_text(exerciseStatement, 2, (exercise.topicID as NSString).utf8String, -1, SQLITE_TRANSIENT)
                    sqlite3_bind_text(exerciseStatement, 3, (exercise.type.rawValue as NSString).utf8String, -1, SQLITE_TRANSIENT)
                    sqlite3_bind_text(exerciseStatement, 4, (exercise.prompt as NSString).utf8String, -1, SQLITE_TRANSIENT)
                    if let cue = exercise.cue {
                        sqlite3_bind_text(exerciseStatement, 5, (cue as NSString).utf8String, -1, SQLITE_TRANSIENT)
                    } else {
                        sqlite3_bind_null(exerciseStatement, 5)
                    }
                    sqlite3_bind_text(exerciseStatement, 6, (answerTokensJSON as NSString).utf8String, -1, SQLITE_TRANSIENT)
                    sqlite3_bind_text(exerciseStatement, 7, (tokenBankJSON as NSString).utf8String, -1, SQLITE_TRANSIENT)
                    sqlite3_bind_text(exerciseStatement, 8, (exercise.inputMode.rawValue as NSString).utf8String, -1, SQLITE_TRANSIENT)
                    sqlite3_bind_text(exerciseStatement, 9, (exercise.explanation as NSString).utf8String, -1, SQLITE_TRANSIENT)
                    if let translation = exercise.translation {
                        sqlite3_bind_text(exerciseStatement, 10, (translation as NSString).utf8String, -1, SQLITE_TRANSIENT)
                    } else {
                        sqlite3_bind_null(exerciseStatement, 10)
                    }
                    if let hint = exercise.hint {
                        sqlite3_bind_text(exerciseStatement, 11, (hint as NSString).utf8String, -1, SQLITE_TRANSIENT)
                    } else {
                        sqlite3_bind_null(exerciseStatement, 11)
                    }

                    if sqlite3_step(exerciseStatement) == SQLITE_DONE {
                        print("Successfully upserted exercise with ID: \(exercise.id)")
                    } else {
                        print("Error upserting exercise: \(String(cString: sqlite3_errmsg(self.db)))")
                        sqlite3_exec(self.db, "ROLLBACK;", nil, nil, nil)
                        sqlite3_finalize(exerciseStatement)
                        return
                    }
                } else {
                    print("Error preparing exercise upsert: \(String(cString: sqlite3_errmsg(self.db)))")
                    sqlite3_exec(self.db, "ROLLBACK;", nil, nil, nil)
                    sqlite3_finalize(exerciseStatement)
                    return
                }
                sqlite3_finalize(exerciseStatement)
            }

            // Commit transaction
            if sqlite3_exec(self.db, "COMMIT;", nil, nil, nil) != SQLITE_OK {
                print("Error committing transaction")
                sqlite3_exec(self.db, "ROLLBACK;", nil, nil, nil)
            }
        }
    }

    func fetchAllTopics(completion: @escaping ([GrammarTopic]) -> Void) {
        print("Fetching all topics...")
        dbQueue.async {
            var topics: [GrammarTopic] = []
            let query = "SELECT id, title, sort_order, prerequisite_id, rule_note FROM topics ORDER BY sort_order;"
            var statement: OpaquePointer?

            if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
                while sqlite3_step(statement) == SQLITE_ROW {
                    let id = String(cString: sqlite3_column_text(statement, 0))
                    let title = String(cString: sqlite3_column_text(statement, 1))
                    let sortOrder = Int(sqlite3_column_int(statement, 2))
                    let prerequisiteID = sqlite3_column_text(statement, 3) != nil ?
                        String(cString: sqlite3_column_text(statement, 3)) : nil
                    let ruleNote = sqlite3_column_text(statement, 4) != nil ?
                        String(cString: sqlite3_column_text(statement, 4)) : ""

                    print("Found topic: \(title) (ID: \(id))")

                    let exercises = self.fetchExercises(forTopicID: id)
                    print("Found \(exercises.count) exercises for topic \(title)")

                    let topic = GrammarTopic(
                        id: id,
                        title: title,
                        sortOrder: sortOrder,
                        prerequisiteID: prerequisiteID,
                        ruleNote: ruleNote,
                        exercises: exercises
                    )
                    topics.append(topic)
                }
            } else {
                print("Error preparing fetch statement: \(String(cString: sqlite3_errmsg(self.db)))")
            }
            sqlite3_finalize(statement)
            completion(topics)
        }
    }

    func topicCount() -> Int {
        var count = 0
        dbQueue.sync {
            let query = "SELECT COUNT(*) FROM topics;"
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
                if sqlite3_step(statement) == SQLITE_ROW {
                    count = Int(sqlite3_column_int(statement, 0))
                }
            } else {
                print("Error preparing topic count statement: \(String(cString: sqlite3_errmsg(self.db)))")
            }
            sqlite3_finalize(statement)
        }
        return count
    }

    // MARK: - Review Status (spaced repetition)

    /// Upsert the persisted SRS state for one exercise. Dates are stored as REAL
    /// (`timeIntervalSince1970`); nil dates bind NULL. `first_seen_date` is stamped
    /// once on first write (the introduction time) and PRESERVED on later writes
    /// via COALESCE — a true UPSERT, not INSERT OR REPLACE (which would delete the
    /// row and lose the original `first_seen_date`).
    func upsertReviewStatus(_ status: ReviewStatus) {
        dbQueue.async {
            let query = """
                INSERT INTO review_status
                    (exercise_id, learning_state, last_review_date, next_review_date, interval_days, first_seen_date)
                VALUES (?, ?, ?, ?, ?, ?)
                ON CONFLICT(exercise_id) DO UPDATE SET
                    learning_state   = excluded.learning_state,
                    last_review_date = excluded.last_review_date,
                    next_review_date = excluded.next_review_date,
                    interval_days    = excluded.interval_days,
                    first_seen_date  = COALESCE(review_status.first_seen_date, excluded.first_seen_date);
            """
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (status.exerciseID as NSString).utf8String, -1, SQLITE_TRANSIENT)
                sqlite3_bind_text(statement, 2, (status.learningState.rawValue as NSString).utf8String, -1, SQLITE_TRANSIENT)
                if let last = status.lastReviewDate {
                    sqlite3_bind_double(statement, 3, last.timeIntervalSince1970)
                } else {
                    sqlite3_bind_null(statement, 3)
                }
                if let next = status.nextReviewDate {
                    sqlite3_bind_double(statement, 4, next.timeIntervalSince1970)
                } else {
                    sqlite3_bind_null(statement, 4)
                }
                sqlite3_bind_int(statement, 5, Int32(status.intervalDays))
                // First grade stamps the introduction time; COALESCE keeps it stable later.
                let firstSeen = status.lastReviewDate?.timeIntervalSince1970 ?? Date().timeIntervalSince1970
                sqlite3_bind_double(statement, 6, firstSeen)

                if sqlite3_step(statement) != SQLITE_DONE {
                    print("Error upserting review status: \(String(cString: sqlite3_errmsg(self.db)))")
                }
            } else {
                print("Error preparing review status upsert: \(String(cString: sqlite3_errmsg(self.db)))")
            }
            sqlite3_finalize(statement)
        }
    }

    /// Fetch the persisted SRS state for one exercise, or nil if never reviewed.
    func fetchReviewStatus(exerciseID: String) -> ReviewStatus? {
        var result: ReviewStatus?
        dbQueue.sync {
            let query = """
                SELECT learning_state, last_review_date, next_review_date, interval_days
                FROM review_status
                WHERE exercise_id = ?;
            """
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (exerciseID as NSString).utf8String, -1, SQLITE_TRANSIENT)
                if sqlite3_step(statement) == SQLITE_ROW {
                    let stateRaw = sqlite3_column_text(statement, 0) != nil ?
                        String(cString: sqlite3_column_text(statement, 0)) : ""
                    let learningState = LearningState(rawValue: stateRaw) ?? .new
                    let lastReviewDate = sqlite3_column_type(statement, 1) != SQLITE_NULL ?
                        Date(timeIntervalSince1970: sqlite3_column_double(statement, 1)) : nil
                    let nextReviewDate = sqlite3_column_type(statement, 2) != SQLITE_NULL ?
                        Date(timeIntervalSince1970: sqlite3_column_double(statement, 2)) : nil
                    let intervalDays = Int(sqlite3_column_int(statement, 3))

                    var status = ReviewStatus(exerciseID: exerciseID,
                                              learningState: learningState,
                                              intervalDays: intervalDays)
                    status.lastReviewDate = lastReviewDate
                    status.nextReviewDate = nextReviewDate
                    result = status
                }
            } else {
                print("Error preparing review status fetch: \(String(cString: sqlite3_errmsg(self.db)))")
            }
            sqlite3_finalize(statement)
        }
        return result
    }

    /// Exercise IDs whose next review is due on or before `date`. Used by the
    /// Daily Review queue.
    func fetchDueExerciseIDs(asOf date: Date) -> [String] {
        var ids: [String] = []
        dbQueue.sync {
            let query = """
                SELECT exercise_id FROM review_status
                WHERE next_review_date IS NOT NULL AND next_review_date <= ?;
            """
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_double(statement, 1, date.timeIntervalSince1970)
                while sqlite3_step(statement) == SQLITE_ROW {
                    if sqlite3_column_text(statement, 0) != nil {
                        ids.append(String(cString: sqlite3_column_text(statement, 0)))
                    }
                }
            } else {
                print("Error preparing due exercises fetch: \(String(cString: sqlite3_errmsg(self.db)))")
            }
            sqlite3_finalize(statement)
        }
        return ids
    }

    /// All exercise IDs that have ever been graded (i.e. have a `review_status`
    /// row). Used to distinguish seen exercises from brand-new ones.
    func fetchSeenExerciseIDs() -> Set<String> {
        var ids: Set<String> = []
        dbQueue.sync {
            let query = "SELECT exercise_id FROM review_status;"
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
                while sqlite3_step(statement) == SQLITE_ROW {
                    if sqlite3_column_text(statement, 0) != nil {
                        ids.insert(String(cString: sqlite3_column_text(statement, 0)))
                    }
                }
            } else {
                print("Error preparing seen exercises fetch: \(String(cString: sqlite3_errmsg(self.db)))")
            }
            sqlite3_finalize(statement)
        }
        return ids
    }

    /// Number of exercises first introduced on the calendar day containing `day`,
    /// over the half-open interval `[startOfDay, startOfNextDay)`. Drives the
    /// `newPerDay` hard cap.
    func countNewIntroduced(on day: Date) -> Int {
        var count = 0
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: day)
        let startOfNextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        dbQueue.sync {
            let query = """
                SELECT COUNT(*) FROM review_status
                WHERE first_seen_date >= ? AND first_seen_date < ?;
            """
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_double(statement, 1, startOfDay.timeIntervalSince1970)
                sqlite3_bind_double(statement, 2, startOfNextDay.timeIntervalSince1970)
                if sqlite3_step(statement) == SQLITE_ROW {
                    count = Int(sqlite3_column_int(statement, 0))
                }
            } else {
                print("Error preparing new-introduced count: \(String(cString: sqlite3_errmsg(self.db)))")
            }
            sqlite3_finalize(statement)
        }
        return count
    }

    /// Not-yet-due review items, soonest-due first (then lowest interval), capped
    /// at `limit`. Used to top up the daily review queue toward the soft target.
    /// Returns an empty array immediately when `limit <= 0`.
    func fetchOverflowExerciseIDs(asOf now: Date, limit: Int) -> [String] {
        guard limit > 0 else { return [] }
        var ids: [String] = []
        dbQueue.sync {
            let query = """
                SELECT exercise_id FROM review_status
                WHERE next_review_date IS NOT NULL AND next_review_date > ?
                ORDER BY next_review_date ASC, interval_days ASC
                LIMIT ?;
            """
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_double(statement, 1, now.timeIntervalSince1970)
                sqlite3_bind_int(statement, 2, Int32(limit))
                while sqlite3_step(statement) == SQLITE_ROW {
                    if sqlite3_column_text(statement, 0) != nil {
                        ids.append(String(cString: sqlite3_column_text(statement, 0)))
                    }
                }
            } else {
                print("Error preparing overflow exercises fetch: \(String(cString: sqlite3_errmsg(self.db)))")
            }
            sqlite3_finalize(statement)
        }
        return ids
    }

    private func fetchExercises(forTopicID topicID: String) -> [Exercise] {
        var exercises: [Exercise] = []
        let query = """
            SELECT id, topic_id, type, prompt, cue, answer_tokens, token_bank, input_mode, explanation, translation, hint
            FROM exercises
            WHERE topic_id = ?;
        """
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (topicID as NSString).utf8String, -1, SQLITE_TRANSIENT)

            while sqlite3_step(statement) == SQLITE_ROW {
                let id = String(cString: sqlite3_column_text(statement, 0))
                let exerciseTopicID = String(cString: sqlite3_column_text(statement, 1))
                let typeRaw = sqlite3_column_text(statement, 2) != nil ?
                    String(cString: sqlite3_column_text(statement, 2)) : ""
                let prompt = sqlite3_column_text(statement, 3) != nil ?
                    String(cString: sqlite3_column_text(statement, 3)) : ""
                let cue = sqlite3_column_text(statement, 4) != nil ?
                    String(cString: sqlite3_column_text(statement, 4)) : nil
                let answerTokensJSON = sqlite3_column_text(statement, 5) != nil ?
                    String(cString: sqlite3_column_text(statement, 5)) : "[]"
                let tokenBankJSON = sqlite3_column_text(statement, 6) != nil ?
                    String(cString: sqlite3_column_text(statement, 6)) : "[]"
                let inputModeRaw = sqlite3_column_text(statement, 7) != nil ?
                    String(cString: sqlite3_column_text(statement, 7)) : ""
                let explanation = sqlite3_column_text(statement, 8) != nil ?
                    String(cString: sqlite3_column_text(statement, 8)) : ""
                let translation = sqlite3_column_text(statement, 9) != nil ?
                    String(cString: sqlite3_column_text(statement, 9)) : nil
                let hint = sqlite3_column_text(statement, 10) != nil ?
                    String(cString: sqlite3_column_text(statement, 10)) : nil

                // Decode JSON arrays
                var answerTokens: [String] = []
                if let data = answerTokensJSON.data(using: .utf8),
                   let parsed = try? JSONDecoder().decode([String].self, from: data) {
                    answerTokens = parsed
                }
                var tokenBank: [String] = []
                if let data = tokenBankJSON.data(using: .utf8),
                   let parsed = try? JSONDecoder().decode([String].self, from: data) {
                    tokenBank = parsed
                }

                // Decode enums from rawValue, skipping unrecognized rows
                guard let type = ExerciseType(rawValue: typeRaw),
                      let inputMode = InputMode(rawValue: inputModeRaw) else {
                    print("Skipping exercise \(id) with unknown type/inputMode")
                    continue
                }

                let exercise = Exercise(
                    id: id,
                    topicID: exerciseTopicID,
                    type: type,
                    prompt: prompt,
                    cue: cue,
                    answerTokens: answerTokens,
                    tokenBank: tokenBank,
                    inputMode: inputMode,
                    explanation: explanation,
                    translation: translation,
                    hint: hint
                )
                exercises.append(exercise)
            }
        }
        sqlite3_finalize(statement)
        return exercises
    }

    deinit {
        if let db = self.db {
            sqlite3_close(db)
        }
    }
}