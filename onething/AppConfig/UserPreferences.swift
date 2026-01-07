import Foundation

enum UserPreferences {
    static let retentionDaysKey = "retentionDays"
    static let dailyResetEnabledKey = "dailyResetEnabled"
    static let hapticsEnabledKey = "hapticsEnabled"
    static let onboardingCompleteKey = "onboardingComplete"
    
    // Notification preferences
    static let morningReminderEnabledKey = "morningReminderEnabled"
    static let eveningReminderEnabledKey = "eveningReminderEnabled"
    static let dailyReengagementEnabledKey = "dailyReengagementEnabled"
    static let hourlyProgressNotificationsEnabledKey = "hourlyProgressNotificationsEnabled"
    static let streakProtectionEnabledKey = "streakProtectionEnabled"
}
