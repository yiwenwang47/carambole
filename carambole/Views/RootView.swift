import SwiftUI
import Foundation

/// App root: the library shelf. Pick a book → its `BookView`.
struct RootView: View {
    var body: some View {
        LibraryView()
    }
}

#Preview {
    RootView()
}
