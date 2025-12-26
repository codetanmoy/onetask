import SwiftUI

struct SettingsView: View {
    @AppStorage(UserPreferences.dailyResetEnabledKey) private var dailyResetEnabled: Bool = true
    @AppStorage(UserPreferences.retentionDaysKey) private var retentionDays: Int = Constants.defaultRetentionDays
    @AppStorage(UserPreferences.hapticsEnabledKey) private var hapticsEnabled: Bool = true

    var body: some View {
        Form {
            Section("Behavior") {
                Toggle("Daily reset", isOn: $dailyResetEnabled)
                Toggle("Haptics", isOn: $hapticsEnabled)
            }

            Section("History") {
                Picker("Retention", selection: $retentionDays) {
                    Text("7 days").tag(7)
                    Text("14 days").tag(14)
                    Text("30 days").tag(30)
                }
            }

            Section("Assistant") {
                NavigationLink("OneThing Assistant") {
                    AssistantView()
                }
            }

            Section("About") {
                Text("Pick one thing. Do it. Done.")
                Text("Local-first. No shame.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
    }
}
