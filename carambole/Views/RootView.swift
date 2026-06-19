import SwiftUI
import Foundation

/// App root: a thin host for the book home. Content loading is owned by
/// `BookViewModel` (see its `load()`).
struct RootView: View {
    var body: some View {
        BookView()
    }
}

#Preview {
    RootView()
}
