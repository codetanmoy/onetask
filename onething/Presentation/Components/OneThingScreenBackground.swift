import SwiftUI

struct OneThingScreenBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

extension View {
    func oneThingScreenBackground() -> some View {
        modifier(OneThingScreenBackground())
    }
}
