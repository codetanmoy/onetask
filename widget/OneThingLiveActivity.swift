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
            // Lock Screen Banner
            LockScreenBannerView(context: context)
                .widgetURL(URL(string: "onething://home"))
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded: Leading - just icon
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "flame.fill")
                        .font(.title2)
                        .foregroundStyle(.orange)
                }
                
                // Expanded: Trailing - just timer
                DynamicIslandExpandedRegion(.trailing) {
                    LiveTimer(
                        baseSeconds: context.state.elapsedSeconds,
                        startedAt: context.state.startedAt
                    )
                    .font(.title2.weight(.bold).monospacedDigit())
                    .foregroundStyle(.white)
                    
                }
                
                // Expanded: Bottom - task name only
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.displayTask)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        
                }
            } compactLeading: {
                // Compact leading - small flame
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                    
            } compactTrailing: {
                // Compact trailing - timer
                LiveTimer(
                    baseSeconds: context.state.elapsedSeconds,
                    startedAt: context.state.startedAt
                )
                .font(.caption.weight(.semibold).monospacedDigit())
                .foregroundStyle(.white)
              
            } minimal: {
                // Minimal - just flame
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                    
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
        VStack(alignment:.leading, spacing: 14) {
            // Left - Flame icon with gradient background
            HStack{
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
                // Center - Task name and status
                Text(context.state.displayTask)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
           
            HStack(spacing: 10) {
                Circle()
                    .fill(.green)
                    .frame(width: 6, height: 6)
                Text("Focus Time")
                    .foregroundStyle(Color(.secondaryLabel))
                    .font(.subheadline)
                Spacer()
                // Right - Timer
                LiveTimer(
                    baseSeconds: context.state.elapsedSeconds,
                    startedAt: context.state.startedAt
                )
                .font(.title.weight(.bold).monospacedDigit())
                .foregroundStyle(.primary)
            }
            
            
            
        } .frame(minWidth: 300)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        
        
        .activityBackgroundTint(Color(.systemBackground))
    }
}

// MARK: - Live Timer Component

private struct LiveTimer: View {
    let baseSeconds: Int
    let startedAt: Date?
    
    var body: some View {
        VStack{
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
        }.frame(minWidth: 200)
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
