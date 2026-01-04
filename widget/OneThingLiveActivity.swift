import ActivityKit
import WidgetKit
import SwiftUI
import AppIntents

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
                // Expanded view - task focused
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "flame.fill")
                        .font(.title2)
                        .foregroundStyle(.orange)
                        .symbolEffect(.pulse.wholeSymbol, options: .repeating)
                        .frame(width: 44, height: 44)
                }
                
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.displayTask)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        if let startedAt = context.state.startedAt {
                            let adjustedStart = startedAt.addingTimeInterval(TimeInterval(-context.state.elapsedSeconds))
                            Text(timerInterval: adjustedStart...Date.distantFuture, countsDown: false)
                                .font(.title3.weight(.bold).monospacedDigit())
                                .foregroundStyle(.white)
                        } else {
                            Text(formatCompactTime(context.state.elapsedSeconds))
                                .font(.title3.weight(.bold).monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(context.state.startedAt != nil ? .green : .orange)
                                .frame(width: 6, height: 6)
                            Text(context.state.startedAt != nil ? "Focus" : "Paused")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
            } compactLeading: {
                // Compact leading - flame icon
                Image(systemName: "flame.fill")
                    .font(.body)
                    .foregroundStyle(.orange)
                
            } compactTrailing: {
                // Compact trailing - timer
                HStack{
                    if let startedAt = context.state.startedAt {
                        let adjustedStart = startedAt.addingTimeInterval(TimeInterval(-context.state.elapsedSeconds))
                        Text(timerInterval: adjustedStart...Date.distantFuture, countsDown: false)
                            .font(.body.weight(.medium).monospacedDigit())
                            .foregroundStyle(.white)
                    } else {
                        Text(formatCompactTime(context.state.elapsedSeconds))
                            .font(.body.weight(.medium).monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    
                    Text("Focus")
                        .font(.caption2)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .foregroundStyle(Color.secondary)
                }
           
            } minimal: {
                // Minimal - just flame icon
                Image(systemName: "flame.fill")
                    .font(.body)
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
    @State private var isPulsing = false
    
    // Use context state directly - this is what Activity.update() modifies
    private var isRunning: Bool {
        context.state.startedAt != nil
    }
    
    private var displayTask: String {
        context.state.displayTask
    }
    
    private var elapsedSeconds: Int {
        context.state.elapsedSeconds
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Left: Timer ring with icon
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 4)
                        .frame(width: 56, height: 56)
                    
                    Circle()
                        .trim(from: 0, to: progressValue)
                        .stroke(
                            LinearGradient(
                                colors: isRunning ? [.orange, .red] : [.gray, .gray.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 56, height: 56)
                        .rotationEffect(.degrees(-90))
                    
                    Image(systemName: isRunning ? "flame.fill" : "pause.fill")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: isRunning ? [.orange, .red] : [.gray, .gray],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .scaleEffect(isRunning && isPulsing ? 1.1 : 1.0)
                        .shadow(color: isRunning ? .orange.opacity(0.5) : .clear, radius: isPulsing ? 8 : 4)
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                        isPulsing = true
                    }
                }
                
                // Center: Task and timer
                VStack(alignment: .leading, spacing: 6) {
                    Text(displayTask)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(isRunning ? .green : .orange)
                                .frame(width: 6, height: 6)
                            Text(isRunning ? "Focus" : "Paused")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        // Timer - LIVE when running, STATIC when paused
                        if isRunning, let startedAt = context.state.startedAt {
                            // Live counting timer
                            let adjustedStart = startedAt.addingTimeInterval(TimeInterval(-elapsedSeconds))
                            Text(timerInterval: adjustedStart...Date.distantFuture, countsDown: false)
                                .font(.title3.weight(.bold).monospacedDigit())
                                .foregroundStyle(.primary)
                        } else {
                            // Static paused timer
                            Text(formatTime(elapsedSeconds))
                                .font(.title3.weight(.bold).monospacedDigit())
                                .foregroundStyle(.primary)
                        }
                    }
                }
                
                Spacer(minLength: 8)
                
                // Right: Action buttons
                VStack(spacing: 8) {
                    if isRunning {
                        Button(intent: PauseTimerIntent()) {
                            Image(systemName: "pause.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(.orange))
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button(intent: ResumeTimerIntent()) {
                            Image(systemName: "play.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(.blue))
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Button(intent: CompleteTaskIntent()) {
                        Image(systemName: "checkmark")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(.green))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .activityBackgroundTint(Color(.systemBackground).opacity(0.95))
    }
    
    private var progressValue: Double {
        let total: Int
        if isRunning, let startedAt = context.state.startedAt {
            total = elapsedSeconds + Int(Date().timeIntervalSince(startedAt))
        } else {
            total = elapsedSeconds
        }
        return min(Double(total) / 3600.0, 1.0)
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
    
    var shortTask: String {
        let trimmed = taskText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Focus" }
        if trimmed.count > 12 {
            let prefix = trimmed.prefix(12)
            return "\(prefix)…"
        }
        return trimmed
    }
}

private func formatCompactTime(_ seconds: Int) -> String {
    let hrs = seconds / 3600
    let mins = (seconds % 3600) / 60
    let secs = seconds % 60
    if hrs > 0 {
        return String(format: "%d:%02d:%02d", hrs, mins, secs)
    }
    return String(format: "%d:%02d", mins, secs)
}

// MARK: - Legacy View (for backwards compatibility if needed)

struct OneThingLiveActivityView: View {
    let context: ActivityViewContext<OneThingActivityAttributes>
    
    var body: some View {
        LockScreenBannerView(context: context)
    }
}
