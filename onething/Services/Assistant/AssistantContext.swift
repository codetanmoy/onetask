import Foundation

struct AssistantContext: Codable, Equatable {
    var today: TodaySummary
    var recent: [RecentSummary]
    var settings: SettingsSummary

    struct TodaySummary: Codable, Equatable {
        var taskText: String
        var isRunning: Bool
        var elapsedSeconds: Int
        var completed: Bool
    }

    struct RecentSummary: Codable, Equatable {
        var date: String
        var taskText: String
        var elapsedSeconds: Int
        var completed: Bool
    }

    struct SettingsSummary: Codable, Equatable {
        var dailyReset: Bool
        var retentionDays: Int
        var hapticsEnabled: Bool
    }
}

