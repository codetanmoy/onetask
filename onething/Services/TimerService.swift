import Foundation

enum TimerService {
    static func start(entry: DayEntry, now: Date = .now) {
        guard entry.startedAt == nil else { return }
        entry.startedAt = now
        entry.updatedAt = now
    }

    static func stop(entry: DayEntry, now: Date = .now) {
        guard let startedAt = entry.startedAt else { return }
        let delta = Int(now.timeIntervalSince(startedAt))
        entry.elapsedSeconds = max(0, entry.elapsedSeconds + delta)
        entry.startedAt = nil
        entry.updatedAt = now
    }

    static func reset(entry: DayEntry, now: Date = .now) {
        entry.elapsedSeconds = 0
        entry.startedAt = nil
        entry.updatedAt = now
    }
}

