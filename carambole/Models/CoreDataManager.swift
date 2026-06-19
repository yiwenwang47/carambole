import Foundation
import SQLite3

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
                let checkQuery = "SELECT COUNT(*) FROM word_lists;"
                var statement: OpaquePointer?
                if sqlite3_prepare_v2(self.db, checkQuery, -1, &statement, nil) == SQLITE_OK {
                    if sqlite3_step(statement) == SQLITE_ROW {
                        let count = sqlite3_column_int(statement, 0)
                        if count > 0 {
                            print("Database already initialized with \(count) word lists")
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
            CREATE TABLE IF NOT EXISTS word_lists (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                description TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
            """,
            """
            CREATE TABLE IF NOT EXISTS words (
                id TEXT PRIMARY KEY,
                text TEXT NOT NULL,
                definition TEXT,
                example_sentence TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
            """,
            """
            CREATE TABLE IF NOT EXISTS word_list_words (
                word_list_id TEXT,
                word_id TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                PRIMARY KEY (word_list_id, word_id),
                FOREIGN KEY (word_list_id) REFERENCES word_lists(id),
                FOREIGN KEY (word_id) REFERENCES words(id)
            );
            """,
            """
            CREATE TABLE IF NOT EXISTS questions (
                id TEXT PRIMARY KEY,
                word_id TEXT NOT NULL,
                type TEXT NOT NULL,
                prompt TEXT,
                options TEXT,
                correct_answer TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (word_id) REFERENCES words(id)
            );
            """,
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
                explanation TEXT
            );
            """,
            """
            CREATE TABLE IF NOT EXISTS review_status (
                exercise_id TEXT PRIMARY KEY,
                learning_state TEXT,
                last_review_date REAL,
                next_review_date REAL,
                interval_days INTEGER
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
    
    func createWordList(id: String? = nil, name: String, description: String? = nil, completion: @escaping (String) -> Void) {
        let listID = id ?? UUID().uuidString
        dbQueue.async {
            print("Creating word list: \(name)")
            let insertQuery = "INSERT INTO word_lists (id, name, description) VALUES (?, ?, ?);"
            var statement: OpaquePointer?
            
            if sqlite3_prepare_v2(self.db, insertQuery, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (listID as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 2, (name as NSString).utf8String, -1, nil)
                if let description = description {
                    sqlite3_bind_text(statement, 3, (description as NSString).utf8String, -1, nil)
                } else {
                    sqlite3_bind_null(statement, 3)
                }
                
                if sqlite3_step(statement) == SQLITE_DONE {
                    print("Successfully created word list with ID: \(listID)")
                    completion(listID)
                } else {
                    print("Error creating word list: \(String(cString: sqlite3_errmsg(self.db)))")
                    completion("")
                }
            }
            sqlite3_finalize(statement)
        }
    }
    
    func addWordToList(word: Word, listID: String) {
        dbQueue.async {
            print("Adding word '\(word.text)' to list ID: \(listID)")
            let wordID = UUID().uuidString
            
            // Start transaction
            if sqlite3_exec(self.db, "BEGIN TRANSACTION;", nil, nil, nil) != SQLITE_OK {
                print("Error starting transaction")
                return
            }
            
            // Insert word
            let insertWordQuery = "INSERT INTO words (id, text, definition, example_sentence) VALUES (?, ?, ?, ?);"
            var statement: OpaquePointer?
            
            if sqlite3_prepare_v2(self.db, insertWordQuery, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (wordID as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 2, (word.text as NSString).utf8String, -1, nil)
                if let definition = word.definition {
                    sqlite3_bind_text(statement, 3, (definition as NSString).utf8String, -1, nil)
                } else {
                    sqlite3_bind_null(statement, 3)
                }
                if let example = word.exampleSentence {
                    sqlite3_bind_text(statement, 4, (example as NSString).utf8String, -1, nil)
                } else {
                    sqlite3_bind_null(statement, 4)
                }
                
                if sqlite3_step(statement) == SQLITE_DONE {
                    print("Successfully inserted word with ID: \(wordID)")
                } else {
                    print("Error inserting word: \(String(cString: sqlite3_errmsg(self.db)))")
                    sqlite3_exec(self.db, "ROLLBACK;", nil, nil, nil)
                    sqlite3_finalize(statement)
                    return
                }
            }
            sqlite3_finalize(statement)
            
            // Create association
            let insertAssociationQuery = "INSERT INTO word_list_words (word_list_id, word_id) VALUES (?, ?);"
            if sqlite3_prepare_v2(self.db, insertAssociationQuery, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (listID as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 2, (wordID as NSString).utf8String, -1, nil)
                
                if sqlite3_step(statement) == SQLITE_DONE {
                    print("Successfully created word-list association")
                } else {
                    print("Error creating word-list association: \(String(cString: sqlite3_errmsg(self.db)))")
                    sqlite3_exec(self.db, "ROLLBACK;", nil, nil, nil)
                    sqlite3_finalize(statement)
                    return
                }
            }
            sqlite3_finalize(statement)
            
            // Commit transaction
            if sqlite3_exec(self.db, "COMMIT;", nil, nil, nil) != SQLITE_OK {
                print("Error committing transaction")
                sqlite3_exec(self.db, "ROLLBACK;", nil, nil, nil)
            }
        }
    }
    
    func fetchAllWordLists(completion: @escaping ([WordList]) -> Void) {
        print("Fetching all word lists...")
        dbQueue.async {
            var wordLists: [WordList] = []
            let query = "SELECT id, name, description FROM word_lists;"
            var statement: OpaquePointer?
            
            if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
                while sqlite3_step(statement) == SQLITE_ROW {
                    let id = String(cString: sqlite3_column_text(statement, 0))
                    let name = String(cString: sqlite3_column_text(statement, 1))
                    let description = sqlite3_column_text(statement, 2) != nil ?
                        String(cString: sqlite3_column_text(statement, 2)) : nil
                    
                    print("Found word list: \(name) (ID: \(id))")
                    
                    // Fetch words for this list
                    let words = self.fetchWords(forListID: id)
                    print("Found \(words.count) words for list \(name)")
                    
                    let wordList = WordList(
                        id: id,
                        name: name,
                        description: description,
                        words: words
                    )
                    wordLists.append(wordList)
                }
            } else {
                print("Error preparing fetch statement: \(String(cString: sqlite3_errmsg(self.db)))")
            }
            sqlite3_finalize(statement)
            completion(wordLists)
        }
    }
    
    private func fetchWords(forListID listID: String) -> [Word] {
        var words: [Word] = []
        let query = """
            SELECT w.id, w.text, w.definition, w.example_sentence
            FROM words w
            JOIN word_list_words wlw ON w.id = wlw.word_id
            WHERE wlw.word_list_id = ?;
        """
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (listID as NSString).utf8String, -1, nil)
            
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = String(cString: sqlite3_column_text(statement, 0))
                let text = String(cString: sqlite3_column_text(statement, 1))
                let definition = sqlite3_column_text(statement, 2) != nil ?
                    String(cString: sqlite3_column_text(statement, 2)) : nil
                let exampleSentence = sqlite3_column_text(statement, 3) != nil ?
                    String(cString: sqlite3_column_text(statement, 3)) : nil
                
                print("Fetched word from database - ID: \(id), Text: \(text)")
                
                let word = Word(
                    id: id,
                    text: text,
                    definition: definition,
                    exampleSentence: exampleSentence
                )
                words.append(word)
            }
        }
        sqlite3_finalize(statement)
        return words
    }
    
    func fetchQuestions(for wordIDs: [String]) -> [QuestionItem] {
        print("Fetching questions for \(wordIDs.count) words")
        var questions: [QuestionItem] = []
        let query = """
            SELECT id, prompt, options, correct_answer
            FROM questions
            WHERE word_id IN (\(wordIDs.map { "'\($0)'" }.joined(separator: ",")));
        """
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = String(cString: sqlite3_column_text(statement, 0))
                let prompt = sqlite3_column_text(statement, 1) != nil ?
                    String(cString: sqlite3_column_text(statement, 1)) : nil
                let optionsJSON = sqlite3_column_text(statement, 2) != nil ?
                    String(cString: sqlite3_column_text(statement, 2)) : nil
                let correctAnswer = sqlite3_column_text(statement, 3) != nil ?
                    String(cString: sqlite3_column_text(statement, 3)) : nil
                
                // Parse options from JSON
                var options: [String]? = nil
                if let optionsJSON = optionsJSON,
                   let data = optionsJSON.data(using: .utf8),
                   let parsedOptions = try? JSONDecoder().decode([String].self, from: data) {
                    options = parsedOptions
                }
                
                let question = QuestionItem(
                    id: id,
                    prompt: prompt,
                    options: options,
                    correctAnswer: correctAnswer
                )
                questions.append(question)
            }
        }
        sqlite3_finalize(statement)
        return questions
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
                sqlite3_bind_text(statement, 1, (topic.id as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 2, (topic.title as NSString).utf8String, -1, nil)
                sqlite3_bind_int(statement, 3, Int32(topic.sortOrder))
                if let prerequisiteID = topic.prerequisiteID {
                    sqlite3_bind_text(statement, 4, (prerequisiteID as NSString).utf8String, -1, nil)
                } else {
                    sqlite3_bind_null(statement, 4)
                }
                sqlite3_bind_text(statement, 5, (topic.ruleNote as NSString).utf8String, -1, nil)

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
                INSERT OR REPLACE INTO exercises (id, topic_id, type, prompt, cue, answer_tokens, token_bank, input_mode, explanation)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
            """
            for exercise in topic.exercises {
                var exerciseStatement: OpaquePointer?
                if sqlite3_prepare_v2(self.db, upsertExerciseQuery, -1, &exerciseStatement, nil) == SQLITE_OK {
                    let answerTokensJSON = (try? JSONEncoder().encode(exercise.answerTokens))
                        .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
                    let tokenBankJSON = (try? JSONEncoder().encode(exercise.tokenBank))
                        .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"

                    sqlite3_bind_text(exerciseStatement, 1, (exercise.id as NSString).utf8String, -1, nil)
                    sqlite3_bind_text(exerciseStatement, 2, (exercise.topicID as NSString).utf8String, -1, nil)
                    sqlite3_bind_text(exerciseStatement, 3, (exercise.type.rawValue as NSString).utf8String, -1, nil)
                    sqlite3_bind_text(exerciseStatement, 4, (exercise.prompt as NSString).utf8String, -1, nil)
                    if let cue = exercise.cue {
                        sqlite3_bind_text(exerciseStatement, 5, (cue as NSString).utf8String, -1, nil)
                    } else {
                        sqlite3_bind_null(exerciseStatement, 5)
                    }
                    sqlite3_bind_text(exerciseStatement, 6, (answerTokensJSON as NSString).utf8String, -1, nil)
                    sqlite3_bind_text(exerciseStatement, 7, (tokenBankJSON as NSString).utf8String, -1, nil)
                    sqlite3_bind_text(exerciseStatement, 8, (exercise.inputMode.rawValue as NSString).utf8String, -1, nil)
                    sqlite3_bind_text(exerciseStatement, 9, (exercise.explanation as NSString).utf8String, -1, nil)

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

    private func fetchExercises(forTopicID topicID: String) -> [Exercise] {
        var exercises: [Exercise] = []
        let query = """
            SELECT id, topic_id, type, prompt, cue, answer_tokens, token_bank, input_mode, explanation
            FROM exercises
            WHERE topic_id = ?;
        """
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (topicID as NSString).utf8String, -1, nil)

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
                    explanation: explanation
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