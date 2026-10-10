import SwiftUI
import Foundation

/// App root: the library shelf. Pick a book → its `BookView`.
struct RootView: View {
    var body: some View {
        #if DEBUG
        if let demo = DrillDemo.rootView() {
            demo
        } else {
            LibraryView()
        }
        #else
        LibraryView()
        #endif
    }
}

#Preview {
    RootView()
}
