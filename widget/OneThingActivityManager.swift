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
        if activity != nil {
            await end(finalElapsed: accumulatedBeforeStart, dismiss: false)
            self.activity = nil
        }
        let attributes = OneThingActivityAttributes(taskIdentifier: taskIdentifier)
        let state = OneThingActivityAttributes.ContentState(
            taskText: taskText,
            elapsedSeconds: accumulatedBeforeStart,
            startedAt: Date()
        )
        do {
            let content = ActivityContent(state: state, staleDate: nil)
            let newActivity = try Activity.request(attributes: attributes, content: content, pushType: nil)
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
        let content = ActivityContent(
            state: state,
            staleDate: nil,        // or a future Date if you want staleness
            relevanceScore: 0      // optional; 0 is fine for most cases
        )
        await activity.update(content)
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
        let content = ActivityContent(
            state: state,
            staleDate: nil,        // or a future Date if you want staleness
            relevanceScore: 0      // optional; 0 is fine for most cases
        )
        await activity.update(content)
    }

    // Stop/end the activity and optionally dismiss it from the system UI.
    func end(finalElapsed: Int, dismiss: Bool = true) async {
        guard let activity else { return }
        let state = OneThingActivityAttributes.ContentState(
            taskText: activity.content.state.taskText,
            elapsedSeconds: finalElapsed,
            startedAt: nil
        )
        await activity.end(ActivityContent(state: state, staleDate: nil), dismissalPolicy: dismiss ? .immediate : .default)
        self.activity = nil
    }
}
