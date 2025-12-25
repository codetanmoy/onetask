import Foundation
import SwiftData

@Model
final class DayEntry {
    @Attribute(.unique) var id: UUID
    var day: Date

    var taskText: String

    var startedAt: Date?
    var elapsedSeconds: Int

    var completedAt: Date?

    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        day: Date,
        taskText: String = "",
        startedAt: Date? = nil,
        elapsedSeconds: Int = 0,
        completedAt: Date? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.day = day
        self.taskText = taskText
        self.startedAt = startedAt
        self.elapsedSeconds = elapsedSeconds
        self.completedAt = completedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension DayEntry {
    var isRunning: Bool { startedAt != nil }
    var isCompleted: Bool { completedAt != nil }

    func totalElapsedSeconds(now: Date = .now) -> Int {
        guard let startedAt else { return elapsedSeconds }
        let delta = Int(now.timeIntervalSince(startedAt))
        return max(0, elapsedSeconds + delta)
    }
}
