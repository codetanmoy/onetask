import Foundation
import UserNotifications
import SwiftData

/// Smart notification service for the dopamine loop CUE system.
/// Handles permission requests and scheduling of contextual reminders.
enum NotificationService {
    
    // MARK: - Notification Identifiers
    
    static let morningReminderId = "com.onetask.morning"
    static let eveningReminderId = "com.onetask.evening"
    
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
}
