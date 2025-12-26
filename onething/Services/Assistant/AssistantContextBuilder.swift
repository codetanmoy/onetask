import Foundation
import SwiftData

enum AssistantContextBuilder {
    @MainActor
    static func make(
        context: ModelContext,
        dailyResetEnabled: Bool,
        retentionDays: Int,
        hapticsEnabled: Bool,
        now: Date = .now
    ) -> AssistantContext? {
        do {
            let today = Calendar.current.startOfDay(for: now)
            let todayEntries = try DayEntryRepository.fetchEntries(forDay: today, context: context)
            let activeToday = todayEntries.first(where: { $0.completedAt == nil })
            let representative = activeToday ?? todayEntries.first

            let recentEntries = try DayEntryRepository.fetchRecentEntries(
                context: context,
                limit: min(7, max(0, retentionDays)),
                now: now
            )

            let todaySummary = AssistantContext.TodaySummary(
                taskText: representative?.taskText ?? "",
                isRunning: representative?.isRunning ?? false,
                elapsedSeconds: representative?.totalElapsedSeconds(now: now) ?? 0,
                previousElapsedSeconds: representative?.elapsedSeconds ?? 0,
                startedAt: representative?.startedAt,
                completed: representative?.isCompleted ?? false
            )

            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate]
            let recent: [AssistantContext.RecentSummary] = recentEntries.map { entry in
                AssistantContext.RecentSummary(
                    date: formatter.string(from: entry.day),
                    taskText: entry.taskText,
                    elapsedSeconds: entry.totalElapsedSeconds(now: now),
                    completed: entry.isCompleted
                )
            }

            let settings = AssistantContext.SettingsSummary(
                dailyReset: dailyResetEnabled,
                retentionDays: retentionDays,
                hapticsEnabled: hapticsEnabled
            )

            return AssistantContext(today: todaySummary, recent: recent, settings: settings)
        } catch {
            LoggingService.log("AssistantContextBuilder failed: \(error)")
            return nil
        }
    }
}
