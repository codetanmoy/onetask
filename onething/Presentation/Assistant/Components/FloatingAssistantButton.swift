import SwiftUI

struct FloatingAssistantButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "message.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(
                    LinearGradient(
                        colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.18), radius: 14, x: 0, y: 8)
                .overlay {
                    Circle().strokeBorder(.white.opacity(0.18), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open assistant")
    }
}

#Preview {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        FloatingAssistantButton {}
            .padding()
    }
}

