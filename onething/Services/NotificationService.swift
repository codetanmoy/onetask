import Foundation
import UserNotifications
import SwiftData

/// Smart notification service for the dopamine loop CUE system.
/// Handles permission requests and scheduling of contextual reminders.
enum NotificationService {
    
    // MARK: - Notification Identifiers
    
    
    static let morningReminderId = "com.onetask.morning"
    static let eveningReminderId = "com.onetask.evening"
    static let dailyReengagementId = "com.onetask.reengagement.daily"
    static let hourlyProgressIdPrefix = "com.onetask.progress.hourly"
    static let streakProtectionId = "com.onetask.streak.protection"
    
    // MARK: - Permission Handling
    
    /// Request notification authorization if not already determined
    static func requestAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        
        switch settings.authorizationStatus {
        case .notDetermined:
            do {
                return try await center.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                return false
            }
        case .authorized, .provisional:
            return true
        case .denied, .ephemeral:
            return false
        @unknown default:
            return false
        }
    }
    
    /// Check current authorization status
    static func isAuthorized() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
    }
    
    // MARK: - Morning Notification
    
    /// Schedule the morning "What's your ONE task today?" notification
    /// - Parameters:
    ///   - hour: Hour to send (default 8am)
    ///   - minute: Minute to send (default 0)
    static func scheduleMorningReminder(hour: Int = 8, minute: Int = 0) {
        let center = UNUserNotificationCenter.current()
        
        // Remove existing morning notification
        center.removePendingNotificationRequests(withIdentifiers: [morningReminderId])
        
        // Create content
        let content = UNMutableNotificationContent()
        content.title = "Good morning! 🌅"
        content.body = "What's your ONE task today?"
        content.sound = .default
        content.categoryIdentifier = "MORNING_REMINDER"
        
        // Schedule daily at specified time
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: morningReminderId, content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error {
                print("Failed to schedule morning reminder: \(error)")
            }
        }
    }
    
    // MARK: - Evening Notification
    
    /// Schedule the evening "Did you complete your task?" notification
    /// Only fires if task is incomplete
    /// - Parameters:
    ///   - hour: Hour to send (default 7pm/19:00)
    ///   - minute: Minute to send (default 0)
    static func scheduleEveningReminder(hour: Int = 19, minute: Int = 0) {
        let center = UNUserNotificationCenter.current()
        
        // Remove existing evening notification
        center.removePendingNotificationRequests(withIdentifiers: [eveningReminderId])
        
        // Create content
        let content = UNMutableNotificationContent()
        content.title = "Don't forget your task! ⏰"
        content.body = "Mark your task complete before the day ends."
        content.sound = .default
        content.categoryIdentifier = "EVENING_REMINDER"
        
        // Schedule daily at specified time
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: eveningReminderId, content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error {
                print("Failed to schedule evening reminder: \(error)")
            }
        }
    }
    
    // MARK: - Cancel Notifications
    
    /// Cancel the evening reminder when task is completed
    static func cancelEveningReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [eveningReminderId])
    }
    
    /// Cancel all scheduled reminders
    static func cancelAllReminders() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            morningReminderId,
            eveningReminderId
        ])
    }
    
    // MARK: - Schedule All (Based on Settings)
    
    /// Update notification schedule based on current settings
    /// - Parameters:
    ///   - morningEnabled: Whether morning notification is enabled
    ///   - eveningEnabled: Whether evening notification is enabled
    static func updateSchedule(morningEnabled: Bool, eveningEnabled: Bool) async {
        guard await isAuthorized() else { return }
        
        if morningEnabled {
            scheduleMorningReminder()
        } else {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [morningReminderId])
        }
        
        if eveningEnabled {
            scheduleEveningReminder()
        } else {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [eveningReminderId])
        }
    }
    
    // MARK: - Daily Re-engagement Notification
    
    /// Schedule daily re-engagement notification (24 hours from now)
    static func scheduleDailyReengagement() {
        let center = UNUserNotificationCenter.current()
        
        // Remove existing
        center.removePendingNotificationRequests(withIdentifiers: [dailyReengagementId])
        
        // Create content
        let content = UNMutableNotificationContent()
        content.title = "You haven't set your ONE task today"
        content.body = "What will you focus on? 🎯"
        content.sound = .default
        content.categoryIdentifier = "DAILY_REENGAGEMENT"
        
        // Schedule 24 hours from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 24 * 60 * 60, repeats: false)
        let request = UNNotificationRequest(identifier: dailyReengagementId, content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error {
                print("Failed to schedule daily re-engagement: \(error)")
            }
        }
    }
    
    /// Cancel daily re-engagement notification
    static func cancelDailyReengagement() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [dailyReengagementId])
    }
    
    // MARK: - Hourly Progress Notifications
    
    /// Schedule hourly progress notification
    /// - Parameters:
    ///   - hoursCompleted: Number of hours that will be completed
    ///   - delay: Seconds until notification should fire
    static func scheduleHourlyProgressNotification(hoursCompleted: Int, delay: TimeInterval) {
        let center = UNUserNotificationCenter.current()
        let identifier = "\(hourlyProgressIdPrefix).\(hoursCompleted)"
        
        // Create content based on hours completed
        let content = UNMutableNotificationContent()
        content.sound = .default
        content.categoryIdentifier = "HOURLY_PROGRESS"
        
        switch hoursCompleted {
        case 1:
            content.title = "1 hour of focus time!"
            content.body = "Keep going 💪"
        case 2:
            content.title = "2 hours of deep work!"
            content.body = "You're on fire 🔥"
        case 3:
            content.title = "3 hours completed!"
            content.body = "Amazing dedication ⭐"
        case 4:
            content.title = "4 hours of focused work!"
            content.body = "Incredible! 🎯"
        default:
            content.title = "\(hoursCompleted) hours!"
            content.body = "You're unstoppable! 🚀"
        }
        
        // Schedule with delay
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error {
                print("Failed to schedule hourly progress notification: \(error)")
            }
        }
    }
    
    /// Cancel all hourly progress notifications
    static func cancelHourlyProgressNotifications() {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let progressIds = requests
                .map { $0.identifier }
                .filter { $0.hasPrefix(hourlyProgressIdPrefix) }
            center.removePendingNotificationRequests(withIdentifiers: progressIds)
        }
    }
    
    // MARK: - Streak Protection Notification
    
    /// Schedule streak protection notification (at 6 PM today if not already passed)
    /// - Parameter streakDays: Current streak count
    static func scheduleStreakProtection(streakDays: Int) {
        let center = UNUserNotificationCenter.current()
        
        // Remove existing
        center.removePendingNotificationRequests(withIdentifiers: [streakProtectionId])
        
        // Create content
        let content = UNMutableNotificationContent()
        content.title = "Don't lose your \(streakDays)-day streak!"
        content.body = "Set today's task now 🔥"
        content.sound = .default
        content.categoryIdentifier = "STREAK_PROTECTION"
        
        // Schedule for 6 PM today
        var dateComponents = DateComponents()
        dateComponents.hour = 18
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: streakProtectionId, content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error {
                print("Failed to schedule streak protection: \(error)")
            }
        }
    }
    
    /// Cancel streak protection notification
    static func cancelStreakProtection() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [streakProtectionId])
    }
}
