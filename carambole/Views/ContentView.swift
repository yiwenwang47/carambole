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
            } else if books.isEmpty {
                Text("No books available")
                    .font(.headline)
            } else {
                VStack(alignment: .leading, spacing: 25) {
                    Button {
                        print("Learn button tapped")
                    } label: {
                        Text("Learn")
                            .font(.system(size: 60))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    Button {
                        print("Review button tapped")
                    } label: {
                        Text("Review")
                            .font(.system(size: 60))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(.leading, 40)
                .background(Color.white)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text("BACK")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.black)
                }
                .buttonStyle(ScaleButtonStyle())
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
                Button {
                    print("Word list tapped: \(list.name)")
                } label: {
                    Text(list.name)
                        .font(.system(size: 30))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.leading, 40)
        .background(Color.white)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text("BACK")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.black)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }
} 