import SwiftUI

struct RootView: View {
    enum Screen: Equatable { 
        case home
        case book(String)
        case learn(Book)
        case review
        case wordList(WordList)
        
        static func == (lhs: Screen, rhs: Screen) -> Bool {
            switch (lhs, rhs) {
            case (.home, .home):
                return true
            case (.book(let lTitle), .book(let rTitle)):
                return lTitle == rTitle
            case (.learn(let lBook), .learn(let rBook)):
                return lBook.id == rBook.id
            case (.review, .review):
                return true
            case (.wordList(let lList), .wordList(let rList)):
                return lList.id == rList.id
            default:
                return false
            }
        }
    }
    
    @State private var screen: Screen = .home
    @State private var books: [Book] = []
    @State private var isLoading = true
    @State private var isNavigatingForward = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // BACK button stays static
            if case .home = screen {
                // Don't show back button on home screen
            } else {
                Button("BACK") { 
                    isNavigatingForward = false
                    withAnimation(.easeInOut) {
                        goBack()
                    }
                }
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(.black)
                .padding(.leading, 40)
            }
            
            // Animated content region
            ZStack {
                if case .home = screen {
                    HomeContent { title in
                        isNavigatingForward = true
                        withAnimation(.easeInOut) { 
                            screen = .book(title)
                        }
                    }
                    .transition(.asymmetric(
                        insertion: isNavigatingForward ? .move(edge: .trailing) : .move(edge: .leading),
                        removal: isNavigatingForward ? .move(edge: .leading) : .move(edge: .trailing)
                    ))
                }
                
                if case .book(let title) = screen {
                    BookContent(book: books.first(where: { $0.name == title })!) { action in
                        isNavigatingForward = true
                        withAnimation(.easeInOut) {
                            switch action {
                            case .learn(let book):
                                screen = .learn(book)
                            case .review:
                                screen = .review
                            }
                        }
                    }
                    .transition(.asymmetric(
                        insertion: isNavigatingForward ? .move(edge: .trailing) : .move(edge: .leading),
                        removal: isNavigatingForward ? .move(edge: .leading) : .move(edge: .trailing)
                    ))
                }
                
                if case .learn(let book) = screen {
                    BookDetailContent(book: book) { wordList in
                        isNavigatingForward = true
                        withAnimation(.easeInOut) {
                            screen = .wordList(wordList)
                        }
                    }
                    .transition(.asymmetric(
                        insertion: isNavigatingForward ? .move(edge: .trailing) : .move(edge: .leading),
                        removal: isNavigatingForward ? .move(edge: .leading) : .move(edge: .trailing)
                    ))
                }
                
                if case .review = screen {
                    Text("Review Coming Soon")
                        .transition(.asymmetric(
                            insertion: isNavigatingForward ? .move(edge: .trailing) : .move(edge: .leading),
                            removal: isNavigatingForward ? .move(edge: .leading) : .move(edge: .trailing)
                        ))
                }
                
                if case .wordList(let wordList) = screen {
                    FlashcardSessionView(words: wordList.words)
                        .transition(.asymmetric(
                            insertion: isNavigatingForward ? .move(edge: .trailing) : .move(edge: .leading),
                            removal: isNavigatingForward ? .move(edge: .leading) : .move(edge: .trailing)
                        ))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(Color.white)
        }
        .onAppear {
            loadData()
        }
    }
    
    private func goBack() {
        switch screen {
        case .home:
            break
        case .book(_):
            screen = .home
        case .learn(_):
            screen = .book("Book 1")
        case .review:
            screen = .book("Book 1")
        case .wordList(_):
            screen = .learn(books[0])
        }
    }
    
    private func loadData() {
        print("RootView: Starting to load data...")
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            print("RootView: Loading word lists into database...")
            WordListLoader.loadWordListsIntoDatabase()
            print("RootView: Fetching all word lists...")
            DataManager.shared.fetchAllWordLists { lists in
                print("RootView: Received \(lists.count) word lists")
                DispatchQueue.main.async {
                    // Organize word lists into books
                    let greAndBusinessLists = lists.filter { list in
                        list.name.contains("GRE") || list.name.contains("Business")
                    }
                    let otherLists = lists.filter { list in
                        !list.name.contains("GRE") && !list.name.contains("Business")
                    }
                    
                    self.books = [
                        Book(name: "Book 1", wordLists: greAndBusinessLists),
                        Book(name: "Book 2", wordLists: otherLists)
                    ]
                    self.isLoading = false
                    print("RootView: Updated UI with \(self.books.count) books")
                }
            }
        }
    }
}

// MARK: - Content Views
private struct HomeContent: View {
    let onBookSelected: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            Button("Book 1") {
                onBookSelected("Book 1")
            }
            .font(.system(size: 60))
            .foregroundColor(.black)
            
            Button("Book 2") {
                onBookSelected("Book 2")
            }
            .font(.system(size: 60))
            .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.leading, 40)
    }
}

private struct BookContent: View {
    let book: Book
    let onAction: (BookAction) -> Void
    
    enum BookAction {
        case learn(Book)
        case review
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            Button("Learn") {
                onAction(.learn(book))
            }
            .font(.system(size: 60))
            .foregroundColor(.black)
            
            Button("Review") {
                onAction(.review)
            }
            .font(.system(size: 60))
            .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.leading, 40)
    }
}

private struct BookDetailContent: View {
    let book: Book
    let onWordListSelected: (WordList) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(book.wordLists) { list in
                Button {
                    onWordListSelected(list)
                } label: {
                    Text(list.name)
                        .font(.system(size: 30))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.leading, 40)
    }
} 