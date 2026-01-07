import SwiftUI

/// Displays streak count with animated gradient flame - enhanced visual prominence
struct StreakBadge: View {
    let streakDays: Int
    let isAtRisk: Bool
    
    @State private var animationPhase: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 12) {
            flameIcon
            textContent
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private var flameIcon: some View {
        ZStack {
            // Glow effect
            Image(systemName: iconName)
                .font(.title2)
                .foregroundStyle(flameGradient)
                .blur(radius: 8)
                .opacity(0.6)
            
            // Main flame
            Image(systemName: iconName)
                .font(.title2)
                .foregroundStyle(flameGradient)
                .symbolEffect(.pulse, options: .repeating.speed(0.5), isActive: !isAtRisk)
                .symbolEffect(.pulse, isActive: isAtRisk)
        }
        .scaleEffect(scaleAmount)
    }
    
    private var textContent: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(streakDays) day streak")
                .font(.headline.weight(.bold))
                .foregroundStyle(.primary)
            
            if isAtRisk {
                Text("Complete a task to keep it!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color(.secondarySystemBackground))
    }
    
    private var iconName: String {
        isAtRisk ? "exclamationmark.triangle.fill" : "flame.fill"
    }
    
    private var scaleAmount: CGFloat {
        1.0 + (isAtRisk ? 0 : animationPhase * 0.05)
    }
    
    
    
    private var shadowColor: Color {
        Color.primary.opacity(0.15)
    }
    
    private func startAnimation() {
        guard !isAtRisk else { return }
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            animationPhase = 1.0
        }
    }
    
    
    
    private var flameGradient: LinearGradient {
        if isAtRisk {
            // Gray gradient for at-risk state
            return LinearGradient(
                colors: [Color.secondary, Color.secondary.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            // Animated black to gray gradient for active streak
            let blackColor = Color.primary
            let darkGray = Color.primary.opacity(0.7)
            let lightGray = Color.primary.opacity(0.5)
            
            // Break down color interpolation to avoid compiler complexity
            let midColor1 = interpolateColor(from: blackColor, to: darkGray, amount: animationPhase)
            let midColor2 = interpolateColor(from: darkGray, to: lightGray, amount: animationPhase)
            
            return LinearGradient(
                colors: [blackColor, midColor1, midColor2],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private func interpolateColor(from: Color, to: Color, amount: CGFloat) -> Color {
        let clampedAmount = max(0, min(1, amount))
        let fromComponents = from.rgbaComponents
        let toComponents = to.rgbaComponents
        
        return Color(
            red: (1 - clampedAmount) * fromComponents.red + clampedAmount * toComponents.red,
            green: (1 - clampedAmount) * fromComponents.green + clampedAmount * toComponents.green,
            blue: (1 - clampedAmount) * fromComponents.blue + clampedAmount * toComponents.blue
        )
    }
}

// MARK: - Color Extension for Component Extraction
extension Color {
    var rgbaComponents: (red: Double, green: Double, blue: Double, alpha: Double) {
        #if canImport(UIKit)
        typealias NativeColor = UIColor
        #elseif canImport(AppKit)
        typealias NativeColor = NSColor
        #endif
        
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        guard NativeColor(self).getRed(&r, green: &g, blue: &b, alpha: &a) else {
            return (0, 0, 0, 1)
        }
        
        return (Double(r), Double(g), Double(b), Double(a))
    }
}


/// Large streak display for celebration moments - black/white theme
struct StreakCelebration: View {
    let oldStreak: Int
    let newStreak: Int
    
    @State private var showIncrement = false
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .font(.title2)
                .foregroundStyle(.primary)
                .symbolEffect(.bounce, value: showIncrement)
            
            HStack(spacing: 4) {
                Text("\(newStreak)")
                    .font(.title.weight(.bold))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                
                Text("day streak")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            
            if showIncrement {
                Text("+1")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(.primary))
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            guard newStreak > oldStreak else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.3)) {
                showIncrement = true
            }
        }
    }
}

#Preview("Badge - Normal") {
    StreakBadge(streakDays: 16, isAtRisk: false)
}

#Preview("Badge - At Risk") {
    StreakBadge(streakDays: 16, isAtRisk: true)
}

#Preview("Celebration") {
    StreakCelebration(oldStreak: 15, newStreak: 16)
}
