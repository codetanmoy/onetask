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
        ZStack {
            Color("WidgetBackground")
            content
                .padding()
        }
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

    private var smallView: some View {
        VStack(spacing: 6) {
            Text(entry.snapshot.status.label)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text(entry.snapshot.displayTask)
                .font(.headline)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            Text(timerString(entry.elapsedSeconds))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var mediumView: some View {
        VStack(spacing: 12) {
            Text(entry.snapshot.displayTask)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
                .lineLimit(2)

            statusRow

            Text(timerString(entry.elapsedSeconds))
                .font(.title2.monospacedDigit())
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var statusRow: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(entry.snapshot.status.color)
                .frame(width: 8, height: 8)
            Text(entry.snapshot.status.label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var accessoryCircular: some View {
        VStack {
            if entry.snapshot.status == .running, let startedAt = entry.snapshot.startedAt {
                Text(timerInterval: startedAt...Date.distantFuture, countsDown: false)
                    .monospacedDigit()
                    .foregroundStyle(.primary)
            } else {
                Text(timerString(entry.elapsedSeconds))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
            }
            Text(entry.snapshot.status.shortLabel)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var accessoryRectangular: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.snapshot.displayTask)
                .font(.caption.weight(.semibold))
                .lineLimit(2)
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
        case .running: return .accentColor
        case .stopped: return .gray
        case .done: return .green
        case .noTask: return .secondary
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
