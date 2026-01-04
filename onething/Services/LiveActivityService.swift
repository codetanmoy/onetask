import ActivityKit
import UIKit
import Foundation

// Conditional availability check helper for Live Activities (iOS 16.2+)

@MainActor
enum LiveActivityService {
    private static var currentActivity: Activity<OneThingActivityAttributes>?

    private static func activity(matching entry: DayEntry) -> Activity<OneThingActivityAttributes>? {
        Activity<OneThingActivityAttributes>.activities.first { $0.attributes.taskIdentifier == entry.id.uuidString }
    }

    static func restoreIfNeeded(for entry: DayEntry) {
        // Attempt to restore an existing activity after app relaunch
        currentActivity = activity(matching: entry)
    }

    static func sync(entry: DayEntry) async {
        // Ensure Live Activities are allowed
        let authInfo = ActivityAuthorizationInfo()
        guard authInfo.areActivitiesEnabled else {
            LoggingService.log("Live Activities are disabled on this device")
            await end()
            return
        }

        // Restore reference if needed
        if currentActivity == nil {
            restoreIfNeeded(for: entry)
        }

        // If completed, end the activity
        if entry.isCompleted {
            await end()
            return
        }
        
        // Check if task has content
        let hasTask = !entry.taskText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        guard hasTask else {
            await end()
            return
        }

        // If we already have a matching activity in the system, prefer that
        if currentActivity == nil {
            currentActivity = activity(matching: entry)
        }

        let attributes = OneThingActivityAttributes(taskIdentifier: entry.id.uuidString)
        
        // Create content state - works for both running and paused
        let contentState = OneThingActivityAttributes.ContentState(
            taskText: entry.taskText,
            elapsedSeconds: entry.elapsedSeconds,
            startedAt: entry.startedAt  // nil when paused, Date when running
        )

        if let activity = currentActivity {
            await activity.update(.init(state: contentState, staleDate: nil))
            return
        }

        // Avoid duplicate requests: if the system already has one (race with restore), use it.
        if let existing = activity(matching: entry) {
            currentActivity = existing
            await existing.update(.init(state: contentState, staleDate: nil))
            return
        }

        // Only start a new activity if there's actual timer activity (running or previously run)
        guard entry.isRunning || entry.elapsedSeconds > 0 else {
            return
        }

        do {
            currentActivity = try Activity<OneThingActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil),
                pushType: nil
            )
        } catch {
          
            LoggingService.log("Live Activity request failed: \(error)")
        }
    }

    static func end() async {
        if let activity = currentActivity {
            let finalContent = OneThingActivityAttributes.ContentState(
                taskText: "",
                elapsedSeconds: 0,
                startedAt: nil
            )
            let content = ActivityContent(state: finalContent, staleDate: .now)
            await activity.end(content, dismissalPolicy: .immediate)
            LoggingService.log("Live Activity ended")
        }
        currentActivity = nil
    }
    
    /// Force update the Live Activity with specific state (used by widget action callbacks)
    static func forceUpdate(taskText: String, elapsedSeconds: Int, isRunning: Bool) async {
        guard let activity = currentActivity ?? Activity<OneThingActivityAttributes>.activities.first else {
            return
        }
        
        let contentState = OneThingActivityAttributes.ContentState(
            taskText: taskText,
            elapsedSeconds: elapsedSeconds,
            startedAt: isRunning ? Date() : nil
        )
        
        await activity.update(.init(state: contentState, staleDate: nil))
        currentActivity = activity
    }
}

