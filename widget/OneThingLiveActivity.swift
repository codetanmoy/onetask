import ActivityKit
import WidgetKit
import SwiftUI

struct OneThingActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        let taskText: String
        let elapsedSeconds: Int
        let startedAt: Date?
    }
    
    var taskIdentifier: String
}

// MARK: - Live Activity Widget Configuration

struct OneThingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: OneThingActivityAttributes.self) { context in
            // Lock Screen Banner - also used for StandBy full screen
            LockScreenBannerView(context: context)
                .widgetURL(URL(string: "onething://home"))
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded: Center region with horizontal layout
                DynamicIslandExpandedRegion(.center) {
                    HStack(alignment: .center,spacing: 20){
                        ZStack{
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.orange.opacity(0.25), .red.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 36, height: 36)
                            Image(systemName: "flame.fill")
                                .font(.title3)
                                .foregroundStyle(.orange)
                        }
                        
                        Text(context.state.displayTask)
                            .font(.title3.weight(.semibold))
                            .multilineTextAlignment(.leading)
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                        
                        Spacer()
                        
                        LiveTimer(
                            baseSeconds: context.state.elapsedSeconds,
                            startedAt: context.state.startedAt
                        )
                        .font(.title2.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.secondary)
                    }
                    
                }
            } compactLeading: {
                // Compact leading - flame icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.orange.opacity(0.25), .red.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 24, height: 24)
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                            .padding(10)
                    }
                
            } compactTrailing: {
                // Compact trailing - timer
                HStack{
                    
                    LiveTimer(
                        baseSeconds: context.state.elapsedSeconds,
                        startedAt: context.state.startedAt
                    )
                    .font(.title2.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.secondary)
                    
                    Text(context.state.displayTask)
                        .font(.custom("", fixedSize: 6))
                        .foregroundStyle(.primary)
                }
            } minimal: {
                // Minimal - visible orange circle with flame
                ZStack {
                    Circle()
                        .fill(.orange)
                        .frame(width: 24, height: 24)
                    Image(systemName: "flame.fill")
                        
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .symbolEffect(.pulse.wholeSymbol, options: .repeating)
                }
            }
            .widgetURL(URL(string: "onething://home"))
        }
    }
}

// MARK: - Dynamic Island Expanded Views

private struct ExpandedLeadingView: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .font(.title2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .symbolEffect(.pulse.wholeSymbol, options: .repeating)
            
            Text("Focus")
                .font(.callout.weight(.semibold))
                .foregroundStyle(.primary)
        }
    }
}

private struct ExpandedTrailingView: View {
    let elapsedSeconds: Int
    let startedAt: Date?
    
    var body: some View {
        LiveTimer(baseSeconds: elapsedSeconds, startedAt: startedAt)
            .font(.title2.weight(.bold).monospacedDigit())
            .foregroundStyle(.primary)
            .contentTransition(.numericText())
    }
}

private struct ExpandedBottomView: View {
    let taskText: String
    
    var body: some View {
        VStack(spacing: 10) {
            // Task text
            Text(taskText)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Animated progress bar
            AnimatedProgressBar()
        }
        .padding(.top, 4)
    }
}

// MARK: - Dynamic Island Compact Views

private struct CompactLeadingView: View {
    var body: some View {
        Image(systemName: "flame.fill")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(
                LinearGradient(
                    colors: [.orange, .red],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }
}

private struct CompactTrailingView: View {
    let elapsedSeconds: Int
    let startedAt: Date?
    
    var body: some View {
        LiveTimer(baseSeconds: elapsedSeconds, startedAt: startedAt)
            .font(.system(size: 14, weight: .semibold).monospacedDigit())
            .foregroundStyle(.primary)
            .contentTransition(.numericText())
    }
}

// MARK: - Dynamic Island Minimal View

private struct MinimalView: View {
    var body: some View {
        Image(systemName: "flame.fill")
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(
                LinearGradient(
                    colors: [.orange, .red],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }
}

// MARK: - Lock Screen Banner View

struct LockScreenBannerView: View {
    let context: ActivityViewContext<OneThingActivityAttributes>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Top row - Flame icon and task name
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.orange.opacity(0.25), .red.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "flame.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                
                Text(context.state.displayTask)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            
            // Bottom row - Status and timer
            HStack(spacing: 10) {
                Circle()
                    .fill(.clear)
                .frame(width: 44, height: 44)
                Circle()
                    .fill(.green)
                    .frame(width: 6, height: 6)
                Text("Focus Time")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                Spacer()
                
                LiveTimer(
                    baseSeconds: context.state.elapsedSeconds,
                    startedAt: context.state.startedAt
                )
                .font(.title.weight(.bold).monospacedDigit())
                .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .activityBackgroundTint(Color(.systemBackground))
    }
}

// MARK: - Live Timer Component

private struct LiveTimer: View {
    let baseSeconds: Int
    let startedAt: Date?
    
    var body: some View {
        if let startedAt {
            // Use native timer interval for live updates
            let adjustedStart = startedAt.addingTimeInterval(TimeInterval(-baseSeconds))
            Text(timerInterval: adjustedStart...Date.distantFuture, countsDown: false)
                .monospacedDigit()
        } else {
            // Static display when not running
            Text(formatTime(baseSeconds))
                .monospacedDigit()
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let hrs = seconds / 3600
        let mins = (seconds % 3600) / 60
        let secs = seconds % 60
        
        if hrs > 0 {
            return String(format: "%d:%02d:%02d", hrs, mins, secs)
        }
        return String(format: "%02d:%02d", mins, secs)
    }
}

// MARK: - Animated Progress Bar

private struct AnimatedProgressBar: View {
    @State private var offset: CGFloat = -1
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            
            ZStack(alignment: .leading) {
                // Background track
                Capsule()
                    .fill(Color.white.opacity(0.15))
                
                // Animated shimmer
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(0.4),
                                .white.opacity(0.6),
                                .white.opacity(0.4),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: width * 0.4)
                    .offset(x: offset * width)
            }
            .onAppear {
                withAnimation(
                    .linear(duration: 2.0)
                    .repeatForever(autoreverses: false)
                ) {
                    offset = 1.4
                }
            }
        }
        .frame(height: 4)
        .clipShape(Capsule())
    }
}

// MARK: - Helper Extensions

private extension OneThingActivityAttributes.ContentState {
    var displayTask: String {
        let trimmed = taskText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "OneThing running" }
        if trimmed.count > 50 {
            let prefix = trimmed.prefix(50)
            return "\(prefix)…"
        }
        return trimmed
    }
}

// MARK: - Legacy View (for backwards compatibility if needed)

struct OneThingLiveActivityView: View {
    let context: ActivityViewContext<OneThingActivityAttributes>
    
    var body: some View {
        LockScreenBannerView(context: context)
    }
}
