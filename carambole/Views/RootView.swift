import SwiftUI
import Foundation

/// App root: the languages (`LanguagesView`). Pick a language → its shelf → a book.
struct RootView: View {
    var body: some View {
        #if DEBUG
        if let demo = DrillDemo.rootView() {
            demo
        } else {
            LanguagesView()
        }
        #else
        LanguagesView()
        #endif
    }
}

#Preview {
    RootView()
}
