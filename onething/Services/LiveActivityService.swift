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

        // If the entry is not running, ensure activity is ended
        guard entry.isRunning else {
            await end()
            return
        }

        // If we already have a matching activity in the system, prefer that
        if currentActivity == nil {
            currentActivity = activity(matching: entry)
        }

        let attributes = OneThingActivityAttributes(taskIdentifier: entry.id.uuidString)
        let content = OneThingActivityAttributes.ContentState(
            taskText: entry.taskText,
            elapsedSeconds: entry.elapsedSeconds,
            startedAt: entry.startedAt
        )
        let stale = Date.now.addingTimeInterval(1)

        if let activity = currentActivity {
            await activity.update(.init(state: content, staleDate: stale))
            return
        }

        // Avoid duplicate requests: if the system already has one (race with restore), use it.
        if let existing = activity(matching: entry) {
            currentActivity = existing
            await existing.update(.init(state: content, staleDate: stale))
            return
        }

        do {
            currentActivity = try Activity<OneThingActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: content, staleDate: stale),
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
}

