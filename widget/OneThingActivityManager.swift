import Foundation
import ActivityKit

final class OneThingActivityManager {
    static let shared = OneThingActivityManager()

    private var activity: Activity<OneThingActivityAttributes>? = nil
    private init() {}

    // Start a new live activity for a running timer.
    // - Parameters:
    //   - taskText: The task label to display
    //   - accumulatedBeforeStart: Total elapsed seconds accumulated before this run segment
    func start(taskText: String, accumulatedBeforeStart: Int, taskIdentifier: String) async {
        // If there is an existing activity, end it before starting a new one
        if let existing = activity {
            await end(finalElapsed: accumulatedBeforeStart, dismiss: false)
            existing.dismiss(reason: .userInitiated)
        }
        let attributes = OneThingActivityAttributes(taskIdentifier: taskIdentifier)
        let state = OneThingActivityAttributes.ContentState(
            taskText: taskText,
            elapsedSeconds: accumulatedBeforeStart,
            startedAt: Date()
        )
        do {
            let newActivity = try Activity.request(attributes: attributes, contentState: state, pushType: nil)
            self.activity = newActivity
        } catch {
            print("[OneThingActivityManager] Failed to start activity: \(error)")
        }
    }

    // Pause the timer: set startedAt to nil and update accumulated total.
    func pause(totalElapsed: Int) async {
        guard let activity else { return }
        let state = OneThingActivityAttributes.ContentState(
            taskText: activity.content.state.taskText,
            elapsedSeconds: totalElapsed,
            startedAt: nil
        )
        do {
            try await activity.update(using: state)
        } catch {
            print("[OneThingActivityManager] Failed to pause activity: \(error)")
        }
    }

    // Resume the timer: set startedAt to now and keep accumulated base.
    func resume(taskText: String? = nil, accumulatedBeforeResume: Int) async {
        guard let activity else { return }
        let current = activity.content.state
        let state = OneThingActivityAttributes.ContentState(
            taskText: taskText ?? current.taskText,
            elapsedSeconds: accumulatedBeforeResume,
            startedAt: Date()
        )
        do {
            try await activity.update(using: state)
        } catch {
            print("[OneThingActivityManager] Failed to resume activity: \(error)")
        }
    }

    // Stop/end the activity and optionally dismiss it from the system UI.
    func end(finalElapsed: Int, dismiss: Bool = true) async {
        guard let activity else { return }
        let state = OneThingActivityAttributes.ContentState(
            taskText: activity.content.state.taskText,
            elapsedSeconds: finalElapsed,
            startedAt: nil
        )
        do {
            try await activity.end(using: state, dismissalPolicy: dismiss ? .immediate : .default)
            self.activity = nil
        } catch {
            print("[OneThingActivityManager] Failed to end activity: \(error)")
        }
    }
}
