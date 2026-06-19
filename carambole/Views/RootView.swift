import SwiftUI
import Foundation

/// App root: a thin host for the topic map. Seeding is owned solely by
/// `TopicMapViewModel` (see its `loadSeedingIfNeeded()`).
struct RootView: View {
    var body: some View {
        TopicMapView()
    }
}

#Preview {
    RootView()
}
