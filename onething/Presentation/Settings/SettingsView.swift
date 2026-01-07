import SwiftUI
import UserNotifications

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @AppStorage(UserPreferences.dailyResetEnabledKey) private var dailyResetEnabled: Bool = true
    @AppStorage(UserPreferences.retentionDaysKey) private var retentionDays: Int = Constants.defaultRetentionDays
    @AppStorage(UserPreferences.hapticsEnabledKey) private var hapticsEnabled: Bool = true
    @AppStorage(UserPreferences.morningReminderEnabledKey) private var morningReminderEnabled: Bool = false
    @AppStorage(UserPreferences.eveningReminderEnabledKey) private var eveningReminderEnabled: Bool = false
    
    @State private var notificationPermissionGranted = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Behavior Card
                OneThingCard {
                    VStack(alignment: .leading, spacing: 16) {
                        OneThingSectionHeader(title: "Behavior")
                        
                        SettingsToggleRow(
                            icon: "arrow.clockwise",
                            title: "Daily Reset",
                            subtitle: "Start fresh each day",
                            isOn: $dailyResetEnabled
                        )
                        
                        Divider()
                        
                        SettingsToggleRow(
                            icon: "waveform",
                            title: "Haptics",
                            subtitle: "Tactile feedback",
                            isOn: $hapticsEnabled
                        )
                    }
                }
                
                // Notifications Card
                OneThingCard {
                    VStack(alignment: .leading, spacing: 16) {
                        OneThingSectionHeader(title: "Reminders")
                        
                        SettingsToggleRow(
                            icon: "sun.max",
                            title: "Morning Reminder",
                            subtitle: "\"What's your ONE task?\" at 8am",
                            isOn: Binding(
                                get: { morningReminderEnabled },
                                set: { newValue in
                                    Task {
                                        if newValue {
                                            let granted = await NotificationService.requestAuthorizationIfNeeded()
                                            if granted {
                                                morningReminderEnabled = true
                                                NotificationService.scheduleMorningReminder()
                                            }
                                        } else {
                                            morningReminderEnabled = false
                                            UNUserNotificationCenter.current().removePendingNotificationRequests(
                                                withIdentifiers: [NotificationService.morningReminderId]
                                            )
                                        }
                                    }
                                }
                            )
                        )
                        
                        Divider()
                        
                        SettingsToggleRow(
                            icon: "moon",
                            title: "Evening Reminder",
                            subtitle: "\"Complete your task\" at 7pm",
                            isOn: Binding(
                                get: { eveningReminderEnabled },
                                set: { newValue in
                                    Task {
                                        if newValue {
                                            let granted = await NotificationService.requestAuthorizationIfNeeded()
                                            if granted {
                                                eveningReminderEnabled = true
                                                NotificationService.scheduleEveningReminder()
                                            }
                                        } else {
                                            eveningReminderEnabled = false
                                            NotificationService.cancelEveningReminder()
                                        }
                                    }
                                }
                            )
                        )
                    }
                }
                
                // History Card
                OneThingCard {
                    VStack(alignment: .leading, spacing: 16) {
                        OneThingSectionHeader(title: "History")
                        
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Color(.secondarySystemBackground))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.body)
                                    .foregroundStyle(.primary)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Retention Period")
                                    .font(.subheadline.weight(.medium))
                                Text("How long to keep history")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Picker("", selection: $retentionDays) {
                                Text("7 days").tag(7)
                                Text("14 days").tag(14)
                                Text("30 days").tag(30)
                            }
                            .pickerStyle(.menu)
                            .tint(.primary)
                        }
                    }
                }
                
                // Progress Card
                OneThingCard {
                    VStack(alignment: .leading, spacing: 12) {
                        OneThingSectionHeader(title: "Progress")
                        
                        NavigationLink {
                            StatsView()
                        } label: {
                            SettingsNavigationRow(
                                icon: "chart.bar",
                                title: "Statistics",
                                subtitle: "View your progress & streaks"
                            )
                        }
                        .buttonStyle(.plain)
                        
                        Divider()
                        
                        NavigationLink {
                            AchievementsView()
                        } label: {
                            SettingsNavigationRow(
                                icon: "trophy",
                                title: "Achievements",
                                subtitle: "Badges & milestones"
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // Assistant Card
                OneThingCard {
                    VStack(alignment: .leading, spacing: 12) {
                        OneThingSectionHeader(title: "Assistant")
                        
                        NavigationLink {
                            AssistantView()
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(Color.primary)
                                        .frame(width: 40, height: 40)
                                    
                                    Image(systemName: "sparkles")
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(colorScheme == .dark ? .black : .white)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("OneThing Assistant")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.primary)
                                    Text("AI-powered task suggestions")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // About Card
                OneThingCard(isElevated: false) {
                    VStack(alignment: .center, spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color(.secondarySystemBackground))
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: "1.circle.fill")
                                .font(.title)
                                .foregroundStyle(.primary)
                        }
                        
                        VStack(spacing: 4) {
                            Text("Pick one thing. Do it. Done.")
                                .font(.subheadline.weight(.medium))
                                .multilineTextAlignment(.center)
                            
                            Text("Local-first. No shame.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
        .navigationTitle("Settings")
    }
}

// MARK: - Settings Toggle Row (Black/White)
struct SettingsToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(.secondarySystemBackground))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(.primary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
    }
}

// MARK: - Settings Navigation Row (Black/White)
struct SettingsNavigationRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(.secondarySystemBackground))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(.primary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
