import SwiftUI
import Foundation

struct Book: Identifiable {
    let id = UUID()
    let name: String
    let wordLists: [WordList]
}

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
    @State private var isBackPressed = false
    @State private var devDrillTopic: GrammarTopic? = nil // TEMP-T5
    
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
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.black)
                .padding(.leading, 42)
                .padding(.top, 40)
                .scaleEffect(isBackPressed ? 0.95 : 1.0)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in isBackPressed = true }
                        .onEnded { _ in isBackPressed = false }
                )
                .buttonStyle(.plain)
            }
            
            // Animated content region
            Group {
                switch screen {
                case .home:
                    VStack(alignment: .leading, spacing: 0) {
                        Button("SEARCH") {
                            // Add search action here
                        }
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.black)
                        .padding(.leading, 42)
                        .padding(.top, 40)
                        .buttonStyle(.plain)

                        Button("Grammar (dev)") { openDevDrill() } // TEMP-T5
                            .font(.system(size: 16, weight: .regular)) // TEMP-T5
                            .foregroundColor(AppColor.saffronDeep) // TEMP-T5
                            .padding(.leading, 42) // TEMP-T5
                            .padding(.top, 8) // TEMP-T5
                            .buttonStyle(.plain) // TEMP-T5

                        HomeContent { title in
                            isNavigatingForward = true
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { 
                                screen = .book(title)
                            }
                        }
                    }
                    .transition(.asymmetric(
                        insertion: isNavigatingForward ? .move(edge: .trailing) : .move(edge: .leading),
                        removal: isNavigatingForward ? .move(edge: .leading) : .move(edge: .trailing)
                    ))
                    
                case .book(let title):
                    BookContent(book: books.first(where: { $0.name == title })!) { action in
                        isNavigatingForward = true
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
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
                    
                case .learn(let book):
                    BookDetailContent(book: book) { wordList in
                        isNavigatingForward = true
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            screen = .wordList(wordList)
                        }
                    }
                    .transition(.asymmetric(
                        insertion: isNavigatingForward ? .move(edge: .trailing) : .move(edge: .leading),
                        removal: isNavigatingForward ? .move(edge: .leading) : .move(edge: .trailing)
                    ))
                    
                case .review:
                    Text("Review Coming Soon")
                        .transition(.asymmetric(
                            insertion: isNavigatingForward ? .move(edge: .trailing) : .move(edge: .leading),
                            removal: isNavigatingForward ? .move(edge: .leading) : .move(edge: .trailing)
                        ))
                    
                case .wordList(let wordList):
                    FlashcardSessionView(words: wordList.words)
                        .transition(.asymmetric(
                            insertion: isNavigatingForward ? .move(edge: .trailing) : .move(edge: .leading),
                            removal: isNavigatingForward ? .move(edge: .leading) : .move(edge: .trailing)
                        ))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color.white)
        }
        .onAppear {
            loadData()
        }
        // TEMP-T5: temporary drill entry point; remove in T6 once real nav lands.
        .fullScreenCover(item: $devDrillTopic) { topic in // TEMP-T5
            DrillSessionView(topic: topic) { devDrillTopic = nil } // TEMP-T5
        } // TEMP-T5
    }

    // TEMP-T5: loads the first seeded topic and presents the drill session.
    private func openDevDrill() { // TEMP-T5
        DataManager.shared.fetchAllTopics { topics in // TEMP-T5
            DispatchQueue.main.async { // TEMP-T5
                if let first = topics.first { devDrillTopic = first } // TEMP-T5
                else { devDrillTopic = GrammarTopic.sample } // TEMP-T5
            } // TEMP-T5
        } // TEMP-T5
    } // TEMP-T5

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
            print("RootView: Seeding grammar topics into database...")
            TopicLoader.seedIfNeeded()
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

// This is to align all buttons
private let topPadding: CGFloat = 80

private struct HomeContent: View {
    let onBookSelected: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            Button("Book 1") {
                onBookSelected("Book 1")
            }
            .font(.system(size: 60))
            .foregroundColor(.black)
            .buttonStyle(ScaleButtonStyle())
            
            Button("Book 2") {
                onBookSelected("Book 2")
            }
            .font(.system(size: 60))
            .foregroundColor(.black)
            .buttonStyle(ScaleButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.leading, 40)
        .padding(.top, topPadding)
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
            Button {
                print("Learn button tapped")
                onAction(.learn(book))
            } label: {
                Text("Learn")
                    .font(.system(size: 60))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .buttonStyle(ScaleButtonStyle())
            
            Button {
                print("Review button tapped")
                onAction(.review)
            } label: {
                Text("Review")
                    .font(.system(size: 60))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.leading, 40)
        .padding(.top, topPadding)
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
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.leading, 40)
        .padding(.top, topPadding)
    }
} 