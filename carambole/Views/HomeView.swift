import SwiftUI

struct HomeView: View {
    @State private var path: [String] = []
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack(alignment: .leading, spacing: 25) {
                ForEach(["Book 1", "Book 2"], id: \.self) { book in
                    Button(book) {
                        print("Button tapped: \(book)")
                        path.append(book)
                    }
                    .font(.system(size: 60))
                    .foregroundColor(.black)
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(.leading, 40)
            .background(Color.white)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: String.self) { book in
                ContentView(selectedBook: book)
            }
        }
    }
}

#Preview {
    HomeView()
}
