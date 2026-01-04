import AppIntents
import ActivityKit

// MARK: - Pause Timer Intent
struct PauseTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Pause Timer"
    static var description = IntentDescription("Pauses the current focus timer")
    
    func perform() async throws -> some IntentResult {
        // Store action in UserDefaults for app to pick up
        let userDefaults = UserDefaults(suiteName: "group.com.qps.onething")
        userDefaults?.set("pause", forKey: "pendingWidgetAction")
        userDefaults?.synchronize()
        
        // Update all activities to paused state on MainActor
        await updateActivitiesToPaused()
        
        return .result()
    }
    
    @MainActor
    private func updateActivitiesToPaused() async {
        for activity in Activity<OneThingActivityAttributes>.activities {
            let currentState = activity.content.state
            let elapsed = currentState.elapsedSeconds + Int(Date().timeIntervalSince(currentState.startedAt ?? Date()))
            let newState = OneThingActivityAttributes.ContentState(
                taskText: currentState.taskText,
                elapsedSeconds: elapsed,
                startedAt: nil  // nil = paused
            )
            await activity.update(ActivityContent(state: newState, staleDate: nil))
        }
    }
}

// MARK: - Complete Task Intent
struct CompleteTaskIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Complete Task"
    static var description = IntentDescription("Marks the current task as complete")
    
    func perform() async throws -> some IntentResult {
        // Store action in UserDefaults for app to pick up
        let userDefaults = UserDefaults(suiteName: "group.com.qps.onething")
        userDefaults?.set("complete", forKey: "pendingWidgetAction")
        userDefaults?.synchronize()
        
        // End all activities on MainActor
        await endAllActivities()
        
        return .result()
    }
    
    @MainActor
    private func endAllActivities() async {
        for activity in Activity<OneThingActivityAttributes>.activities {
            let currentState = activity.content.state
            let elapsed = currentState.elapsedSeconds + Int(Date().timeIntervalSince(currentState.startedAt ?? Date()))
            let newState = OneThingActivityAttributes.ContentState(
                taskText: currentState.taskText,
                elapsedSeconds: elapsed,
                startedAt: nil
            )
            await activity.end(ActivityContent(state: newState, staleDate: nil), dismissalPolicy: .immediate)
        }
    }
}

// MARK: - Resume Timer Intent
struct ResumeTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Resume Timer"
    static var description = IntentDescription("Resumes the paused timer")
    
    func perform() async throws -> some IntentResult {
        // Store action in UserDefaults for app to pick up
        let userDefaults = UserDefaults(suiteName: "group.com.qps.onething")
        userDefaults?.set("resume", forKey: "pendingWidgetAction")
        userDefaults?.synchronize()
        
        // Update all activities to running state on MainActor
        await updateActivitiesToRunning()
        
        return .result()
    }
    
    @MainActor
    private func updateActivitiesToRunning() async {
        for activity in Activity<OneThingActivityAttributes>.activities {
            let currentState = activity.content.state
            let newState = OneThingActivityAttributes.ContentState(
                taskText: currentState.taskText,
                elapsedSeconds: currentState.elapsedSeconds,
                startedAt: Date()  // now = running
            )
            await activity.update(ActivityContent(state: newState, staleDate: nil))
        }
    }
}
