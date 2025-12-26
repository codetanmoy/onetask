import Foundation
import SwiftData

enum AssistantActionService {
    @MainActor
    static func applyTaskText(
        _ text: String,
        context: ModelContext,
        dailyResetEnabled: Bool,
        now: Date = .now
    ) throws -> DayEntry {
        let task = String(text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(Constants.maxTaskLength))
        guard task.isEmpty == false else { throw NSError(domain: "AssistantActionService", code: 1) }

        let entry = try DayEntryRepository.fetchOrCreateToday(
            context: context,
            dailyResetEnabled: dailyResetEnabled,
            now: now
        )
        if entry.isCompleted {
            let today = Calendar.current.startOfDay(for: now)
            let newEntry = DayEntry(day: today, taskText: task)
            context.insert(newEntry)
            try context.save()
            return newEntry
        }

        entry.taskText = task
        entry.updatedAt = now
        try context.save()
        return entry
    }

    @MainActor
    static func startTimerIfPossible(context: ModelContext, dailyResetEnabled: Bool, now: Date = .now) throws {
        let entry = try DayEntryRepository.fetchOrCreateToday(
            context: context,
            dailyResetEnabled: dailyResetEnabled,
            now: now
        )
        let hasTask = entry.taskText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        guard hasTask, entry.isCompleted == false, entry.isRunning == false else { return }
        TimerService.start(entry: entry, now: now)
        try context.save()
    }

    @MainActor
    static func stopTimerIfRunning(context: ModelContext, dailyResetEnabled: Bool, now: Date = .now) throws {
        let entry = try DayEntryRepository.fetchOrCreateToday(
            context: context,
            dailyResetEnabled: dailyResetEnabled,
            now: now
        )
        guard entry.isRunning else { return }
        TimerService.stop(entry: entry, now: now)
        try context.save()
    }

    @MainActor
    static func pauseTimer(context: ModelContext, dailyResetEnabled: Bool, now: Date = .now) throws {
        try stopTimerIfRunning(context: context, dailyResetEnabled: dailyResetEnabled, now: now)
    }

    @MainActor
    static func completeTask(context: ModelContext, dailyResetEnabled: Bool, now: Date = .now) throws {
        let entry = try DayEntryRepository.fetchOrCreateToday(
            context: context,
            dailyResetEnabled: dailyResetEnabled,
            now: now
        )
        guard entry.isCompleted == false else { return }
        if entry.isRunning {
            TimerService.stop(entry: entry, now: now)
        }
        entry.completedAt = now
        entry.updatedAt = now
        try context.save()
    }
}
