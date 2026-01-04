import SwiftUI

/// A premium pulsing dot indicator for active/running states.
struct PulsingIndicator: View {
    let color: Color
    let size: CGFloat
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPulsing = false
    
    init(color: Color = .green, size: CGFloat = 8) {
        self.color = color
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Outer pulsing ring
            if !reduceMotion {
                Circle()
                    .fill(color.opacity(0.3))
                    .frame(width: size * 2.5, height: size * 2.5)
                    .scaleEffect(isPulsing ? 1.3 : 1.0)
                    .opacity(isPulsing ? 0 : 0.6)
            }
            
            // Inner solid dot
            Circle()
                .fill(color)
                .frame(width: size, height: size)
                .shadow(color: color.opacity(0.5), radius: 4, x: 0, y: 0)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: false)) {
                isPulsing = true
            }
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        PulsingIndicator(color: .green)
        PulsingIndicator(color: .blue, size: 12)
        PulsingIndicator(color: .orange, size: 6)
    }
    .padding()
    .background(Color(.systemBackground))
}
