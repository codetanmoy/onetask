import SwiftUI

/// Displays streak count with "at risk" warning state - pure black/white theme
struct StreakBadge: View {
    let streakDays: Int
    let isAtRisk: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isAtRisk ? "exclamationmark.triangle.fill" : "flame.fill")
                .foregroundStyle(isAtRisk ? .secondary : .primary)
                .symbolEffect(.pulse, isActive: isAtRisk)
            
            VStack(alignment: .leading, spacing: 0) {
                Text("\(streakDays) day streak")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                
                if isAtRisk {
                    Text("Complete a task to keep it!")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.secondarySystemBackground))
        }
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
