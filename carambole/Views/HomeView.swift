import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 25) {
                NavigationLink(destination: ContentView(selectedBook: "Book 1")) {
                    Text("Book 1")
                        .font(.system(size: 60))
                        .foregroundColor(.black)
                }
                
                NavigationLink(destination: ContentView(selectedBook: "Book 2")) {
                    Text("Book 2")
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
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

#Preview {
    HomeView()
}
