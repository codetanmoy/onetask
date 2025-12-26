import Foundation
import SwiftData

@Model
final class DayEntry {
var id: UUID = Foundation.UUID()
var day: Date = Foundation.Calendar.current.startOfDay(for: Foundation.Date())

    var taskText: String = ""

    var startedAt: Date?
    var elapsedSeconds: Int = 0

    var completedAt: Date?

    var createdAt: Date = Foundation.Date()
    var updatedAt: Date = Foundation.Date()

    init(
        id: UUID = .init(),
        day: Date = Foundation.Calendar.current.startOfDay(for: Foundation.Date()),
        taskText: String = "",
        startedAt: Date? = nil,
        elapsedSeconds: Int = 0,
        completedAt: Date? = nil,
        createdAt: Date = Foundation.Date(),
        updatedAt: Date = Foundation.Date()
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

    func totalElapsedSeconds(now: Date = Date()) -> Int {
        guard let startedAt else { return elapsedSeconds }
        let delta = Int(now.timeIntervalSince(startedAt))
        return max(0, elapsedSeconds + delta)
    }
}
