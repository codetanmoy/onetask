import Foundation
import SwiftData

/// Streak calculation service providing loss aversion retention mechanics.
/// Calculates current streak from consecutive days with completed tasks.
enum StreakService {
    
    /// Streak data for display in UI
    struct StreakInfo {
        let currentDays: Int
        let longestEver: Int
        let isAtRisk: Bool
        let lastCompletedDate: Date?
        
        static let zero = StreakInfo(currentDays: 0, longestEver: 0, isAtRisk: false, lastCompletedDate: nil)
    }
    
    /// Calculate streak from completed entries
    /// - Parameters:
    ///   - context: SwiftData model context
    ///   - now: Current date (for testing)
    /// - Returns: StreakInfo with current and longest streak
    static func calculateStreak(context: ModelContext, now: Date = .now) throws -> StreakInfo {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        
        // Fetch all completed entries, sorted by day descending
        let descriptor = FetchDescriptor<DayEntry>(
            predicate: #Predicate { $0.completedAt != nil },
            sortBy: [SortDescriptor(\.day, order: .reverse)]
        )
        
        let completedEntries = try context.fetch(descriptor)
        
        guard !completedEntries.isEmpty else {
            return .zero
        }
        
        // Get unique completed days (one completion per day counts)
        var completedDays = Set<Date>()
        for entry in completedEntries {
            let day = calendar.startOfDay(for: entry.day)
            completedDays.insert(day)
        }
        
        let sortedDays = completedDays.sorted(by: >)
        
        // Calculate current streak
        var currentStreak = 0
        var expectedDay = today
        
        // Check if today is completed - if not, start from yesterday
        if !completedDays.contains(today) {
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: today) {
                expectedDay = yesterday
            }
        }
        
        for day in sortedDays {
            if day == expectedDay {
                currentStreak += 1
                expectedDay = calendar.date(byAdding: .day, value: -1, to: expectedDay) ?? expectedDay
            } else if day < expectedDay {
                // Gap found, streak broken
                break
            }
        }
        
        // Calculate longest streak ever
        let longestStreak = calculateLongestStreak(sortedDays: sortedDays.sorted(), calendar: calendar)
        
        // Determine if streak is at risk
        // At risk if: user had a streak yesterday but hasn't completed today yet
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let isAtRisk = currentStreak > 0 && !completedDays.contains(today) && completedDays.contains(yesterday)
        
        let lastCompleted = sortedDays.first
        
        return StreakInfo(
            currentDays: currentStreak,
            longestEver: max(longestStreak, currentStreak),
            isAtRisk: isAtRisk,
            lastCompletedDate: lastCompleted
        )
    }
    
    /// Calculate the longest consecutive streak from sorted days
    private static func calculateLongestStreak(sortedDays: [Date], calendar: Calendar) -> Int {
        guard !sortedDays.isEmpty else { return 0 }
        
        var longest = 1
        var current = 1
        
        for i in 1..<sortedDays.count {
            let prevDay = sortedDays[i - 1]
            let currDay = sortedDays[i]
            
            if let nextExpected = calendar.date(byAdding: .day, value: 1, to: prevDay),
               currDay == nextExpected {
                current += 1
                longest = max(longest, current)
            } else {
                current = 1
            }
        }
        
        return longest
    }
}
