import SwiftUI

struct Book: Identifiable {
    let id = UUID()
    let name: String
    let wordLists: [WordList]
}

struct ContentView: View {
    let selectedBook: String
    @State private var books: [Book] = []
    @State private var isLoading = true
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading books...")
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
            } else if books.isEmpty {
                Text("No books available")
                    .font(.headline)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
            } else {
                if selectedBook == "Book 1" {
                    VStack(alignment: .leading, spacing: 25) {
                        NavigationLink(destination: BookDetailView(book: books[0])) {
                            Text("Learn")
                                .font(.system(size: 60))
                                .foregroundColor(.black)
                        }
                        
                        NavigationLink(destination: Text("Review Coming Soon")) {
                            Text("Review")
                                .font(.system(size: 60))
                                .foregroundColor(.black)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .padding(.leading, 40)
                    .background(Color.white)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
                } else {
                    BookDetailView(book: books[1])
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("BACK")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.black)
                }
            }
        }
        .onAppear {
            loadData()
        }
    }
    
    private func loadData() {
        print("ContentView: Starting to load data...")
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            print("ContentView: Loading word lists into database...")
            WordListLoader.loadWordListsIntoDatabase()
            print("ContentView: Fetching all word lists...")
            DataManager.shared.fetchAllWordLists { lists in
                print("ContentView: Received \(lists.count) word lists")
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
                    print("ContentView: Updated UI with \(self.books.count) books")
                }
            }
        }
    }
}

struct BookDetailView: View {
    let book: Book
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(book.wordLists) { list in
                NavigationLink {
                    FlashcardSessionView(words: list.words)
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
        .background(Color.white)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing),
            removal: .move(edge: .leading)
        ))
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("BACK")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.black)
                }
            }
        }
    }
} 