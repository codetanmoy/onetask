import Foundation
import SwiftData

/// Statistics calculation service for dopamine-driven progress visibility.
enum StatsService {
    
    struct Stats {
        // Today
        let todayTasksCompleted: Int
        let todayMinutesFocused: Int
        
        // This Week
        let weekActiveDays: Int
        let weekTasksCompleted: Int
        let weekMinutesFocused: Int
        
        // All Time
        let totalTasksCompleted: Int
        let totalMinutesFocused: Int
        let longestStreak: Int
        let memberSince: Date?
        
        // Current
        let currentStreak: Int
        
        static let empty = Stats(
            todayTasksCompleted: 0,
            todayMinutesFocused: 0,
            weekActiveDays: 0,
            weekTasksCompleted: 0,
            weekMinutesFocused: 0,
            totalTasksCompleted: 0,
            totalMinutesFocused: 0,
            longestStreak: 0,
            memberSince: nil,
            currentStreak: 0
        )
    }
    
    static func calculateStats(context: ModelContext) throws -> Stats {
        let calendar = Calendar.current
        let now = Date.now
        let today = calendar.startOfDay(for: now)
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today)!
        
        // Fetch all entries
        let descriptor = FetchDescriptor<DayEntry>(sortBy: [SortDescriptor(\.day, order: .forward)])
        let allEntries = try context.fetch(descriptor)
        
        // Today's stats
        let todayEntries = allEntries.filter { calendar.isDate($0.day, inSameDayAs: today) }
        let todayCompleted = todayEntries.filter { $0.isCompleted }.count
        let todaySeconds = todayEntries.reduce(0) { $0 + $1.totalElapsedSeconds(now: now) }
        
        // This week's stats
        let weekEntries = allEntries.filter { $0.day >= weekAgo }
        let weekCompleted = weekEntries.filter { $0.isCompleted }.count
        let weekSeconds = weekEntries.reduce(0) { $0 + $1.totalElapsedSeconds(now: now) }
        
        // Count active days this week
        var activeDaysSet = Set<Date>()
        for entry in weekEntries where entry.isCompleted {
            activeDaysSet.insert(calendar.startOfDay(for: entry.day))
        }
        
        // All time stats
        let allCompleted = allEntries.filter { $0.isCompleted }.count
        let allSeconds = allEntries.reduce(0) { $0 + $1.totalElapsedSeconds(now: now) }
        let memberSince = allEntries.first?.createdAt
        
        // Get streak info
        let streakInfo = try StreakService.calculateStreak(context: context)
        
        return Stats(
            todayTasksCompleted: todayCompleted,
            todayMinutesFocused: todaySeconds / 60,
            weekActiveDays: activeDaysSet.count,
            weekTasksCompleted: weekCompleted,
            weekMinutesFocused: weekSeconds / 60,
            totalTasksCompleted: allCompleted,
            totalMinutesFocused: allSeconds / 60,
            longestStreak: streakInfo.longestEver,
            memberSince: memberSince,
            currentStreak: streakInfo.currentDays
        )
    }
}
