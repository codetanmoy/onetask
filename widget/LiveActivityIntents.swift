import AppIntents
import ActivityKit
import WidgetKit

// MARK: - Pause Timer Intent
struct PauseTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Pause Timer"
    static var description = IntentDescription("Pauses the current focus timer")
    
    func perform() async throws -> some IntentResult {
        // Store action in UserDefaults for app to pick up
        let userDefaults = UserDefaults(suiteName: "group.com.qps.onething")
        userDefaults?.set("pause", forKey: "pendingWidgetAction")
        
        // Get current elapsed time and update snapshot
        if let snapshot = loadSnapshot() {
            let elapsed = snapshot.totalElapsedSeconds(now: Date())
            
            // Save paused snapshot
            saveSnapshot(snapshot: snapshot, totalElapsed: elapsed, isPaused: true)
            
            // Update ALL activities directly with paused state
            let activities = Activity<OneThingActivityAttributes>.activities
            for activity in activities {
                let state = OneThingActivityAttributes.ContentState(
                    taskText: snapshot.taskText,
                    elapsedSeconds: elapsed,
                    startedAt: nil  // nil = paused
                )
                await activity.update(ActivityContent(state: state, staleDate: nil))
            }
        }
        
        userDefaults?.synchronize()
        WidgetCenter.shared.reloadAllTimelines()
        
        return .result()
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
        
        // Get current elapsed time and end activity
        if let snapshot = loadSnapshot() {
            let elapsed = snapshot.totalElapsedSeconds(now: Date())
            
            // Save completed snapshot
            saveCompletedSnapshot(snapshot: snapshot, totalElapsed: elapsed)
            
            // End ALL activities
            let activities = Activity<OneThingActivityAttributes>.activities
            for activity in activities {
                let state = OneThingActivityAttributes.ContentState(
                    taskText: snapshot.taskText,
                    elapsedSeconds: elapsed,
                    startedAt: nil
                )
                await activity.end(ActivityContent(state: state, staleDate: nil), dismissalPolicy: .default)
            }
        }
        
        userDefaults?.synchronize()
        WidgetCenter.shared.reloadAllTimelines()
        
        return .result()
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
        
        // Resume the timer
        if let snapshot = loadSnapshot() {
            let elapsed = snapshot.elapsedSeconds
            
            // Save running snapshot
            saveSnapshot(snapshot: snapshot, totalElapsed: elapsed, isPaused: false)
            
            // Update ALL activities with running state
            let activities = Activity<OneThingActivityAttributes>.activities
            for activity in activities {
                let state = OneThingActivityAttributes.ContentState(
                    taskText: snapshot.taskText,
                    elapsedSeconds: elapsed,
                    startedAt: Date()  // now = running
                )
                await activity.update(ActivityContent(state: state, staleDate: nil))
            }
        }
        
        userDefaults?.synchronize()
        WidgetCenter.shared.reloadAllTimelines()
        
        return .result()
    }
}

// MARK: - Live Activity Helpers

private func pauseLiveActivity(totalElapsed: Int) async {
    let activities = Activity<OneThingActivityAttributes>.activities
    print("[LiveActivityIntents] Pause - Found \(activities.count) activities")
    
    for activity in activities {
        let state = OneThingActivityAttributes.ContentState(
            taskText: activity.content.state.taskText,
            elapsedSeconds: totalElapsed,
            startedAt: nil  // Set to nil to stop the timer
        )
        let content = ActivityContent(state: state, staleDate: nil)
        await activity.update(content)
        print("[LiveActivityIntents] Updated activity to paused state with \(totalElapsed) seconds")
    }
}

private func resumeLiveActivity(taskText: String, accumulatedBeforeResume: Int) async {
    let activities = Activity<OneThingActivityAttributes>.activities
    print("[LiveActivityIntents] Resume - Found \(activities.count) activities")
    
    for activity in activities {
        let state = OneThingActivityAttributes.ContentState(
            taskText: taskText,
            elapsedSeconds: accumulatedBeforeResume,
            startedAt: Date()  // Set to now to resume counting
        )
        let content = ActivityContent(state: state, staleDate: nil)
        await activity.update(content)
        print("[LiveActivityIntents] Updated activity to running state")
    }
}

private func endLiveActivity(finalElapsed: Int) async {
    let activities = Activity<OneThingActivityAttributes>.activities
    print("[LiveActivityIntents] End - Found \(activities.count) activities")
    
    for activity in activities {
        let state = OneThingActivityAttributes.ContentState(
            taskText: activity.content.state.taskText,
            elapsedSeconds: finalElapsed,
            startedAt: nil
        )
        let content = ActivityContent(state: state, staleDate: nil)
        await activity.end(content, dismissalPolicy: .default)
        print("[LiveActivityIntents] Ended activity")
    }
}

// MARK: - Widget Snapshot Helpers

private func loadSnapshot() -> WidgetSnapshotData? {
    guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.qps.onething") else {
        return nil
    }
    let url = container.appendingPathComponent("widget-snapshot.json")
    guard let data = try? Data(contentsOf: url) else { return nil }
    return try? JSONDecoder().decode(WidgetSnapshotData.self, from: data)
}

private func saveSnapshot(snapshot: WidgetSnapshotData, totalElapsed: Int, isPaused: Bool) {
    guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.qps.onething") else {
        return
    }
    
    let updatedSnapshot = WidgetSnapshotData(
        taskText: snapshot.taskText,
        elapsedSeconds: totalElapsed,
        startedAt: isPaused ? nil : Date(),
        completedAt: nil,
        updatedAt: Date()
    )
    
    let url = container.appendingPathComponent("widget-snapshot.json")
    if let data = try? JSONEncoder().encode(updatedSnapshot) {
        try? data.write(to: url)
    }
}

private func saveCompletedSnapshot(snapshot: WidgetSnapshotData, totalElapsed: Int) {
    guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.qps.onething") else {
        return
    }
    
    let updatedSnapshot = WidgetSnapshotData(
        taskText: snapshot.taskText,
        elapsedSeconds: totalElapsed,
        startedAt: nil,
        completedAt: Date(),
        updatedAt: Date()
    )
    
    let url = container.appendingPathComponent("widget-snapshot.json")
    if let data = try? JSONEncoder().encode(updatedSnapshot) {
        try? data.write(to: url)
    }
}
