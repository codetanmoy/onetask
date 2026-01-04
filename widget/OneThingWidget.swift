import WidgetKit
import SwiftUI

struct OneThingEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshotData

    var elapsedSeconds: Int {
        snapshot.totalElapsedSeconds(now: date)
    }
}

struct OneThingProvider: TimelineProvider {
    func placeholder(in context: Context) -> OneThingEntry {
        .init(date: .now, snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (OneThingEntry) -> Void) {
        let data = WidgetSnapshotStore.shared.loadSnapshot() ?? .placeholder
        completion(.init(date: .now, snapshot: data))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<OneThingEntry>) -> Void) {
        let data = WidgetSnapshotStore.shared.loadSnapshot() ?? .placeholder
        let now = Date()
        let refreshInterval: TimeInterval = data.status == .running ? 60 : 1800
        let nextUpdate = now.addingTimeInterval(refreshInterval)
        let entry = OneThingEntry(date: now, snapshot: data)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

struct OneThingWidgetEntryView: View {
    let entry: OneThingEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        content
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        case .accessoryCircular:
            accessoryCircular
        case .accessoryRectangular:
            accessoryRectangular
        default:
            mediumView
        }
    }

    // MARK: - Small Widget
    private var smallView: some View {
        ZStack {
            // Premium gradient background
            ContainerRelativeShape()
                .fill(
                    LinearGradient(
                        colors: backgroundGradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 8) {
                // Status icon with glow
                ZStack {
                    Circle()
                        .fill(entry.snapshot.status.color.opacity(0.2))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: entry.snapshot.status.icon)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(entry.snapshot.status.color)
                }
                
                Text(entry.snapshot.displayTask)
                    .font(.subheadline.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .foregroundStyle(.primary)
                
                // Timer with pill background - LIVE when running
                Group {
                    if entry.snapshot.status == .running, let startedAt = entry.snapshot.startedAt {
                        let adjustedStart = startedAt.addingTimeInterval(TimeInterval(-entry.snapshot.elapsedSeconds))
                        Text(timerInterval: adjustedStart...Date.distantFuture, countsDown: false)
                            .font(.caption.weight(.semibold).monospacedDigit())
                    } else {
                        Text(timerString(entry.elapsedSeconds))
                            .font(.caption.weight(.semibold).monospacedDigit())
                    }
                }
                .foregroundStyle(entry.snapshot.status == .running ? .white : .secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(entry.snapshot.status == .running 
                              ? entry.snapshot.status.color 
                              : Color(.systemGray5))
                )
            }
            .padding()
        }
    }

    // MARK: - Medium Widget
    private var mediumView: some View {
        ZStack {
            // Premium gradient background
            ContainerRelativeShape()
                .fill(
                    LinearGradient(
                        colors: backgroundGradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            HStack(spacing: 16) {
                // Left: Progress circle with timer
                ZStack(alignment: .center) {
                    // Background circle
                    Circle()
                        .stroke(Color(.systemGray4), lineWidth: 6)
                        .frame(width: 80, height: 80)
                    
                    // Progress arc
                    Circle()
                        .trim(from: 0, to: progressValue)
                        .stroke(
                            entry.snapshot.status.gradient,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                    
                    // Timer text - LIVE when running (centered in circle)
                    VStack(spacing: 2) {
                        if entry.snapshot.status == .running, let startedAt = entry.snapshot.startedAt {
                            let adjustedStart = startedAt.addingTimeInterval(TimeInterval(-entry.snapshot.elapsedSeconds))
                            Text(timerInterval: adjustedStart...Date.distantFuture, countsDown: false)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .minimumScaleFactor(0.8)
                                .multilineTextAlignment(.center)
                        } else {
                            Text(timerString(entry.elapsedSeconds))
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .multilineTextAlignment(.center)
                        }
                        
                        if entry.snapshot.status == .running {
                            Circle()
                                .fill(.green)
                                .frame(width: 6, height: 6)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(width: 80, height: 80)
                
                // Right: Task and status
                VStack(alignment: .leading, spacing: 8) {
                    Text(entry.snapshot.displayTask)
                        .font(.headline.weight(.semibold))
                        .lineLimit(2)
                        .foregroundStyle(.primary)
                    
                    // Status badge
                    HStack(spacing: 6) {
                        Image(systemName: entry.snapshot.status.icon)
                            .font(.caption)
                        Text(entry.snapshot.status.label)
                            .font(.caption.weight(.medium))
                    }
                    .foregroundStyle(entry.snapshot.status.color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(entry.snapshot.status.color.opacity(0.15))
                    )
                }
                
                Spacer(minLength: 0)
            }
            .padding()
        }
    }
    
    // MARK: - Accessory Circular
    private var accessoryCircular: some View {
        ZStack {
            // Progress ring
            Circle()
                .stroke(Color.secondary.opacity(0.3), lineWidth: 4)
            
            Circle()
                .trim(from: 0, to: progressValue)
                .stroke(Color.primary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            VStack(spacing: 0) {
                if entry.snapshot.status == .running, let startedAt = entry.snapshot.startedAt {
                    Text(timerInterval: startedAt...Date.distantFuture, countsDown: false)
                        .font(.system(size: 12, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                } else {
                    Text(timerString(entry.elapsedSeconds))
                        .font(.system(size: 12, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                }
            }
        }
    }

    // MARK: - Accessory Rectangular
    private var accessoryRectangular: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: entry.snapshot.status.icon)
                    .font(.caption2)
                Text(entry.snapshot.displayTask)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
            }
            
            HStack(spacing: 4) {
                Text(entry.snapshot.status.label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                if entry.snapshot.status == .running, let startedAt = entry.snapshot.startedAt {
                    Text(timerInterval: startedAt...Date.distantFuture, countsDown: false)
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                } else {
                    Text(timerString(entry.elapsedSeconds))
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private var progressValue: Double {
        // 1 hour = full circle
        min(Double(entry.elapsedSeconds) / 3600.0, 1.0)
    }
    
    private var backgroundGradient: [Color] {
        switch entry.snapshot.status {
        case .running:
            return [Color(.systemBackground), Color.green.opacity(0.05)]
        case .done:
            return [Color(.systemBackground), Color.green.opacity(0.1)]
        case .stopped:
            return [Color(.systemBackground), Color.orange.opacity(0.05)]
        case .noTask:
            return [Color(.systemBackground), Color(.systemGray6)]
        }
    }

    private func timerString(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%d:%02d", minutes, secs)
    }
}

struct OneThingWidget: Widget {
    let kind: String = "OneThingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: OneThingProvider()) { entry in
            OneThingWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("One thing status")
        .description("See your current task and timer at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}

struct WidgetSnapshotData: Codable {
    let taskText: String
    let elapsedSeconds: Int
    let startedAt: Date?
    let completedAt: Date?
    let updatedAt: Date

    static let placeholder = WidgetSnapshotData(
        taskText: "Ship the calm UI",
        elapsedSeconds: 420,
        startedAt: Date().addingTimeInterval(-420),
        completedAt: nil,
        updatedAt: .now
    )

    var status: WidgetStatus {
        if completedAt != nil {
            return .done
        }
        if startedAt != nil {
            return .running
        }
        if taskText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .noTask
        }
        return .stopped
    }

    var displayTask: String {
        let trimmed = taskText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return "Set your one thing" }
        if trimmed.count > 40 {
            let prefix = trimmed.prefix(40)
            return "\(prefix)…"
        }
        return trimmed
    }

    func totalElapsedSeconds(now: Date = .now) -> Int {
        guard let startedAt else { return elapsedSeconds }
        let delta = Int(now.timeIntervalSince(startedAt))
        return max(0, elapsedSeconds + delta)
    }
}

enum WidgetStatus: String, Codable {
    case running
    case stopped
    case done
    case noTask

    var label: String {
        switch self {
        case .running: return "Running"
        case .stopped: return "Stopped"
        case .done: return "Done"
        case .noTask: return "Set your one thing"
        }
    }

    var shortLabel: String {
        switch self {
        case .running: return "Running"
        case .stopped: return "Stopped"
        case .done: return "Done"
        case .noTask: return "Set task"
        }
    }

    var color: Color {
        switch self {
        case .running: return .green
        case .stopped: return .orange
        case .done: return .green
        case .noTask: return .secondary
        }
    }
    
    var icon: String {
        switch self {
        case .running: return "flame.fill"
        case .stopped: return "pause.circle.fill"
        case .done: return "checkmark.circle.fill"
        case .noTask: return "plus.circle"
        }
    }
    
    var gradient: LinearGradient {
        switch self {
        case .running:
            return LinearGradient(
                colors: [.green, .mint],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .stopped:
            return LinearGradient(
                colors: [.orange, .yellow],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .done:
            return LinearGradient(
                colors: [.green, .mint],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .noTask:
            return LinearGradient(
                colors: [.secondary, .secondary.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

struct WidgetSnapshotStore {
    static let shared = WidgetSnapshotStore()
    private let fileName = "widget-snapshot.json"
    private let appGroupIdentifiers: [String] = [
        "group.com.qps.onething"
    ]

    private var snapshotURL: URL? {
        guard let container = appGroupContainerURL else { return nil }
        return container.appendingPathComponent(fileName)
    }

    private var appGroupContainerURL: URL? {
        for identifier in appGroupIdentifiers {
            if let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier) {
                return container
            }
        }
        return nil
    }

    func loadSnapshot() -> WidgetSnapshotData? {
        guard let url = snapshotURL else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshotData.self, from: data)
    }
}

@main
struct OneThingWidgetsBundle: WidgetBundle {
    var body: some Widget {
        OneThingWidget()
        OneThingLiveActivity()
    }
}
