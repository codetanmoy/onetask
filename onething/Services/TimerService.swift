import Foundation

enum TimerService {
    static func start(entry: DayEntry, now: Date = .now, progressNotificationsEnabled: Bool = false) {
        guard entry.startedAt == nil else { return }
        entry.startedAt = now
        entry.updatedAt = now
        
        // Schedule hourly progress notifications if enabled
        if progressNotificationsEnabled {
            scheduleProgressNotifications(for: entry)
        }
    }

    static func stop(entry: DayEntry, now: Date = .now) {
        guard let startedAt = entry.startedAt else { return }
        let delta = Int(now.timeIntervalSince(startedAt))
        entry.elapsedSeconds = max(0, entry.elapsedSeconds + delta)
        entry.startedAt = nil
        entry.updatedAt = now
        
        // Cancel progress notifications when timer stops
        NotificationService.cancelHourlyProgressNotifications()
    }

    static func reset(entry: DayEntry, now: Date = .now) {
        entry.elapsedSeconds = 0
        entry.startedAt = nil
        entry.updatedAt = now
        
        // Cancel progress notifications when timer resets
        NotificationService.cancelHourlyProgressNotifications()
    }
    
    // MARK: - Progress Notifications
    
    /// Schedule hourly progress notifications based on current elapsed time
    private static func scheduleProgressNotifications(for entry: DayEntry) {
        // Calculate when the next hour milestone will be reached
        let currentElapsed = entry.elapsedSeconds
        let nextHourMark = ((currentElapsed / 3600) + 1) * 3600
        let secondsUntilNextHour = nextHourMark - currentElapsed
        
        // Only schedule if there's meaningful time left (at least 1 minute)
        guard secondsUntilNextHour >= 60 else { return }
        
        // Schedule notification for next hour mark
        NotificationService.scheduleHourlyProgressNotification(
            hoursCompleted: (nextHourMark / 3600),
            delay: TimeInterval(secondsUntilNextHour)
        )
    }
}


