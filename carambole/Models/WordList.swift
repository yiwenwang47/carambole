import Foundation

struct WordList: Identifiable, Codable {
    let id: String
    let name: String
    let description: String?
    let createdAt: Date
    var words: [Word]
    
    init(id: String = UUID().uuidString, name: String, description: String? = nil, createdAt: Date = Date(), words: [Word] = []) {
        self.id = id
        self.name = name
        self.description = description
        self.createdAt = createdAt
        self.words = words
    }
}
