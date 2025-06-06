import SwiftUI

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct ScaleButton<Label: View>: View {
    let action: () -> Void
    let label: Label
    @State private var isPressed = false
    
    init(action: @escaping () -> Void, @ViewBuilder label: () -> Label) {
        print("ScaleButton initialized")
        self.action = action
        self.label = label()
    }
    
    var body: some View {
        print("ScaleButton body called")
        return Button {
            print("ScaleButton action triggered")
            action()
        } label: {
            label
                .scaleEffect(isPressed ? 0.95 : 1)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isPressed)
        }
        .buttonStyle(ScaleButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    print("ScaleButton drag gesture began")
                    isPressed = true
                }
                .onEnded { _ in
                    print("ScaleButton drag gesture ended")
                    isPressed = false
                }
        )
    }
}

// Add a modifier to disable default button appearance
extension View {
    func disableButtonStyle() -> some View {
        self.buttonStyle(.plain)
    }
} 