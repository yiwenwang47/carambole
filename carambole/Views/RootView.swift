import SwiftUI
import Foundation

/// App root: seeds grammar topics on launch and hosts the topic map.
struct RootView: View {
    var body: some View {
        TopicMapView()
            .onAppear {
                loadData()
            }
    }

    /// Seeds grammar topics into the database if needed. (Vocabulary loading was
    /// removed in the French-grammar pivot.)
    private func loadData() {
        print("RootView: Starting to load data...")
        DispatchQueue.global(qos: .userInitiated).async {
            print("RootView: Seeding grammar topics into database...")
            TopicLoader.seedIfNeeded()
        }
    }
}

#Preview {
    RootView()
}
