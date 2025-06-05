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
    
    func createWordList(name: String, description: String? = nil) -> String {
        let listID = UUID().uuidString
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
                } else {
                    print("Error creating word list: \(String(cString: sqlite3_errmsg(self.db)))")
                }
            }
            sqlite3_finalize(statement)
        }
        return listID
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
                
                print("Found word: \(text) (ID: \(id))")
                
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
    
    deinit {
        if let db = self.db {
            sqlite3_close(db)
        }
    }
}