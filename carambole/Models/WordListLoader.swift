import Foundation

struct WordListData: Codable {
    let wordLists: [WordListDataItem]
}

struct WordListDataItem: Codable {
    let id: String
    let name: String
    let description: String
    let words: [WordData]
}

struct WordData: Codable {
    let id: String
    let text: String
    let definition: String
    let exampleSentence: String
}

class WordListLoader {
    static func loadWordLists() -> [WordList] {
        guard let url = Bundle.main.url(forResource: "test_words", withExtension: "json") else {
            print("Error: Could not find test_words.json")
            return []
        }
        
        do {
            print("Loading word lists from JSON file at: \(url.path)")
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let wordListData = try decoder.decode(WordListData.self, from: data)
            print("Successfully decoded \(wordListData.wordLists.count) word lists from JSON")
            return wordListData.wordLists.map { item in
                print("Processing word list: \(item.name) with \(item.words.count) words")
                return WordList(
                    id: item.id,
                    name: item.name,
                    description: item.description,
                    words: item.words.map { wordData in
                        print("Loading word from JSON - ID: \(wordData.id), Text: \(wordData.text)")
                        return Word(
                            id: wordData.id,
                            text: wordData.text,
                            definition: wordData.definition,
                            exampleSentence: wordData.exampleSentence
                        )
                    }
                )
            }
        } catch {
            print("Error loading word lists: \(error)")
            return []
        }
    }
    
    static func loadWordListsIntoDatabase() {
        print("Starting to load word lists into database...")
        DataManager.shared.fetchAllWordLists { existingLists in
            print("Found \(existingLists.count) existing word lists")
            if !existingLists.isEmpty {
                print("Database already has word lists, skipping initialization")
                return
            }
            
            print("No existing word lists found, loading from JSON...")
            let wordLists = loadWordLists()
            print("Loaded \(wordLists.count) word lists from JSON")
            
            let group = DispatchGroup()
            
            for wordList in wordLists {
                group.enter()
                print("Creating word list: \(wordList.name) with \(wordList.words.count) words")
                DataManager.shared.createWordList(id: wordList.id, name: wordList.name, description: wordList.description) { listID in
                    if !listID.isEmpty {
                        for word in wordList.words {
                            print("Adding word: \(word.text) to list: \(wordList.name)")
                            DataManager.shared.addWordToList(word: word, listID: listID)
                        }
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                print("Finished loading all word lists into database")
            }
        }
    }
} 