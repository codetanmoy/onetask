import Foundation
import SwiftData

/// Milestone tracking for micro-celebrations (dopamine REWARD enhancement).
enum MilestoneService {
    
    /// Types of milestones that trigger celebrations
    enum Milestone: String, CaseIterable {
        case firstTask = "first_task"
        case streak7 = "streak_7"
        case streak30 = "streak_30"
        case tasks10 = "tasks_10"
        case tasks50 = "tasks_50"
        case tasks100 = "tasks_100"
        case hours10 = "hours_10"
        
        var title: String {
            switch self {
            case .firstTask: return "🎉 First Task!"
            case .streak7: return "🔥 7 Days!"
            case .streak30: return "💎 30 Days!"
            case .tasks10: return "⭐ 10 Tasks!"
            case .tasks50: return "🚀 50 Tasks!"
            case .tasks100: return "🏆 100 Tasks!"
            case .hours10: return "⏱️ 10 Hours!"
            }
        }
        
        var message: String {
            switch self {
            case .firstTask: return "You completed your first task. This is just the beginning!"
            case .streak7: return "7 days in a row! You're building real momentum."
            case .streak30: return "30 days! You're in the top 5% of focused people."
            case .tasks10: return "10 tasks complete. You're on fire!"
            case .tasks50: return "50 tasks! This is becoming a serious habit."
            case .tasks100: return "100 tasks! You're unstoppable!"
            case .hours10: return "10 hours of focused work. Amazing dedication!"
            }
        }
    }
    
    /// Check for newly achieved milestones
    /// - Returns: First unshown milestone that was just achieved, or nil
    static func checkForNewMilestone(context: ModelContext) throws -> Milestone? {
        let stats = try StatsService.calculateStats(context: context)
        let shownMilestones = getShownMilestones()
        
        // Check in order of priority (rare milestones first)
        if stats.currentStreak >= 30 && !shownMilestones.contains(.streak30) {
            return .streak30
        }
        if stats.totalTasksCompleted >= 100 && !shownMilestones.contains(.tasks100) {
            return .tasks100
        }
        if stats.totalTasksCompleted >= 50 && !shownMilestones.contains(.tasks50) {
            return .tasks50
        }
        if stats.totalMinutesFocused >= 600 && !shownMilestones.contains(.hours10) { // 10 hours
            return .hours10
        }
        if stats.currentStreak >= 7 && !shownMilestones.contains(.streak7) {
            return .streak7
        }
        if stats.totalTasksCompleted >= 10 && !shownMilestones.contains(.tasks10) {
            return .tasks10
        }
        if stats.totalTasksCompleted >= 1 && !shownMilestones.contains(.firstTask) {
            return .firstTask
        }
        
        return nil
    }
    
    /// Mark a milestone as shown so it doesn't repeat
    static func markMilestoneShown(_ milestone: Milestone) {
        var shown = getShownMilestones()
        shown.insert(milestone)
        let rawValues = shown.map { $0.rawValue }
        UserDefaults.standard.set(rawValues, forKey: "shownMilestones")
    }
    
    /// Get all previously shown milestones
    private static func getShownMilestones() -> Set<Milestone> {
        guard let rawValues = UserDefaults.standard.array(forKey: "shownMilestones") as? [String] else {
            return []
        }
        return Set(rawValues.compactMap { Milestone(rawValue: $0) })
    }
}
