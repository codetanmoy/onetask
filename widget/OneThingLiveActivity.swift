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

struct OneThingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: OneThingActivityAttributes.self) { context in
            OneThingLiveActivityView(context: context)
                .widgetURL(URL(string: "onething://home"))
                .activityBackgroundTint(Color(.systemBackground))
                .activitySystemActionForegroundColor(Color.accentColor)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "timer")
                        .symbolEffect(.bounce, options: .repeating)
                        .font(.title3)
                        .widgetURL(URL(string: "onething://home"))
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 6) {
                        Text(context.state.displayTask)
                            .font(.headline.weight(.semibold))
                            .lineLimit(1)
                        ShimmerBar()
                        Text("Running")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .widgetURL(URL(string: "onething://home"))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    LiveUpdatingElapsed(baseSeconds: context.state.elapsedSeconds, startedAt: context.state.startedAt)
                        .font(.title3)
                        .widgetURL(URL(string: "onething://home"))
                }
            } compactLeading: {
                Image(systemName: "timer")
                    .symbolEffect(.pulse, options: .repeating)
                    .font(.title3)
                    .widgetURL(URL(string: "onething://home"))
            } compactTrailing: {
                LiveUpdatingElapsed(baseSeconds: context.state.elapsedSeconds, startedAt: context.state.startedAt)
                    .font(.caption)
                    .widgetURL(URL(string: "onething://home"))
            } minimal: {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 8, height: 8)
                    .widgetURL(URL(string: "onething://home"))
            }
        }
    }
}

private struct LiveUpdatingText: View {
    let builder: () -> String
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { _ in
            Text(builder())
                .monospacedDigit()
        }
    }
}

private struct LiveUpdatingElapsed: View {
    let baseSeconds: Int
    let startedAt: Date?

    @State private var viewStart = Date()

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { _ in
            Text(formatted())
                .monospacedDigit()
        }
        .onAppear { viewStart = Date() }
    }

    private func formatted() -> String {
        let delta: Int
        if let startedAt {
            delta = max(0, Int(Date().timeIntervalSince(startedAt)))
        } else {
            delta = max(0, Int(Date().timeIntervalSince(viewStart)))
        }
        let seconds = baseSeconds + delta
        let hrs = seconds / 3600
        let mins = (seconds % 3600) / 60
        let secs = seconds % 60
        if hrs > 0 {
            return String(format: "%d:%02d:%02d", hrs, mins, secs)
        }
        return String(format: "%02d:%02d", mins, secs)
    }
}

private struct ShimmerBar: View {
    @State private var phase: CGFloat = -1
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            ZStack {
                RoundedRectangle(cornerRadius: height/2, style: .continuous)
                    .fill(Color.secondary.opacity(0.2))
                RoundedRectangle(cornerRadius: height/2, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.accentColor.opacity(0.2),
                                Color.accentColor.opacity(0.6),
                                Color.accentColor.opacity(0.2)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .mask(
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(stops: [
                                        .init(color: .clear, location: 0),
                                        .init(color: .white, location: 0.2),
                                        .init(color: .white, location: 0.5),
                                        .init(color: .clear, location: 0.8)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .offset(x: phase * width)
                    )
            }
            .onAppear {
                withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: false)) {
                    phase = 2
                }
            }
        }
        .frame(height: 8)
    }
}

private struct OneThingLiveActivityView: View {
    let context: ActivityViewContext<OneThingActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "timer.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.accent)
                    .font(.title2)
                    .scaleEffect(1.0)
                    .symbolEffect(.pulse, options: .repeating)
                Text(context.state.displayTask)
                    .font(.title2.weight(.semibold))
                    .lineLimit(1)
            }
            LiveUpdatingElapsed(baseSeconds: context.state.elapsedSeconds, startedAt: context.state.startedAt)
                .font(.title)
            ShimmerBar()
            Text("Running")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private extension OneThingActivityAttributes.ContentState {
    var displayTask: String {
        let trimmed = taskText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "OneThing running" }
        if trimmed.count > 28 {
            let prefix = trimmed.prefix(28)
            return "\(prefix)…"
        }
        return trimmed
    }

    func formattedElapsed() -> String {
        let base = elapsedSeconds
        guard let started = startedAt else {
            return Self.timerString(seconds: base)
        }
        let delta = Int(Date().timeIntervalSince(started))
        return Self.timerString(seconds: base + max(0, delta))
    }

    private static func timerString(seconds: Int) -> String {
        let hrs = seconds / 3600
        let mins = (seconds % 3600) / 60
        let secs = seconds % 60
        if hrs > 0 {
            return String(format: "%d:%02d:%02d", hrs, mins, secs)
        }
        return String(format: "%02d:%02d", mins, secs)
    }
}
