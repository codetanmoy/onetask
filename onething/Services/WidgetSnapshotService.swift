import Foundation
import SwiftData
import WidgetKit
@MainActor
enum WidgetSnapshotService {
    private static let snapshotFileName = "widget-snapshot.json"

    static func updateSnapshot(context: ModelContext, dailyResetEnabled: Bool) throws {
        guard let url = snapshotFileURL else { return }
        let entry = try DayEntryRepository.fetchOrCreateToday(
            context: context,
            dailyResetEnabled: dailyResetEnabled
        )
        let snapshot = WidgetSnapshot(entry: entry)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(snapshot)
        try data.write(to: url, options: .atomic)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private static var snapshotFileURL: URL? {
        guard let container = appGroupContainerURL else { return nil }
        return container.appendingPathComponent(snapshotFileName)
    }

    private static var appGroupContainerURL: URL? {
        for identifier in appGroupIdentifiers {
            if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier) {
                return url
            }
        }
        return nil
    }

    private static let appGroupIdentifiers: [String] = [
        "group.com.qps.onething.widget",
        "group.com.qps.onething",
        "group.com.qps.com-shipapps-onething"
    ]
}

struct WidgetSnapshot: Codable {
    let taskText: String
    let elapsedSeconds: Int
    let startedAt: Date?
    let completedAt: Date?
    let updatedAt: Date

    init(entry: DayEntry) {
        self.taskText = entry.taskText
        self.elapsedSeconds = entry.elapsedSeconds
        self.startedAt = entry.startedAt
        self.completedAt = entry.completedAt
        self.updatedAt = entry.updatedAt
    }

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
}
