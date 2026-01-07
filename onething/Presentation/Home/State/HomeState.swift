import Foundation

struct HomeState: Equatable {
    var taskDraft: String = ""
    var isEditingTask: Bool = false
    var showResetConfirmation: Bool = false
    var showUndoToast: Bool = false
    var lastCompletedAt: Date? = nil
    
    // Streak tracking for loss aversion
    var streakDays: Int = 0
    var streakAtRisk: Bool = false
    var previousStreakDays: Int = 0  // For celebration animation
    
    // Milestone celebration
    var pendingMilestone: MilestoneService.Milestone? = nil
    
    // Task suggestions
    var suggestions: [TaskSuggestionService.Suggestion] = []
}
