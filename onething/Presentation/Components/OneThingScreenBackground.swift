import SwiftUI

struct OneThingScreenBackground: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Base background
                    Color(.systemGroupedBackground)
                    
                    // Subtle gradient overlay for depth
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .opacity(0.5)
                    
                    // Radial accent glow at top
                    RadialGradient(
                        colors: [
                            Color.accentColor.opacity(colorScheme == .dark ? 0.08 : 0.05),
                            Color.clear
                        ],
                        center: .topTrailing,
                        startRadius: 50,
                        endRadius: 400
                    )
                }
                .ignoresSafeArea()
            )
    }
    
    private var gradientColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(.systemGroupedBackground),
                Color(.systemGroupedBackground).opacity(0.95)
            ]
        } else {
            return [
                Color.white.opacity(0.3),
                Color(.systemGroupedBackground)
            ]
        }
    }
}

extension View {
    func oneThingScreenBackground() -> some View {
        modifier(OneThingScreenBackground())
    }
}
