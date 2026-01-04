import SwiftUI

struct OneThingCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    
    private let content: Content
    private let isElevated: Bool

    init(isElevated: Bool = true, @ViewBuilder content: () -> Content) {
        self.isElevated = isElevated
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBackground)
            .overlay(cardBorder)
            .shadow(
                color: shadowColor,
                radius: isElevated ? 12 : 6,
                x: 0,
                y: isElevated ? 4 : 2
            )
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(.ultraThinMaterial)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground).opacity(0.85))
            )
    }
    
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Color.white.opacity(colorScheme == .dark ? 0.15 : 0.6),
                        Color.white.opacity(colorScheme == .dark ? 0.05 : 0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }
    
    private var shadowColor: Color {
        colorScheme == .dark
            ? Color.black.opacity(0.4)
            : Color.black.opacity(0.08)
    }
}

#Preview {
    VStack(spacing: 16) {
        OneThingCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("One thing").font(.caption).foregroundStyle(.secondary)
                Text("Ship a calm iOS-native UI").font(.title3).fontWeight(.semibold)
            }
        }
        
        OneThingCard(isElevated: false) {
            Text("Lower elevation card")
        }
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

