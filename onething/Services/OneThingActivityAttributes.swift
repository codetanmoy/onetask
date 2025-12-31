import ActivityKit
import Foundation

struct OneThingActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        let taskText: String
        let elapsedSeconds: Int
        let startedAt: Date?
    }

    var taskIdentifier: String
}
