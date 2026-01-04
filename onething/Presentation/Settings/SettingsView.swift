import SwiftUI

struct SettingsView: View {
    @AppStorage(UserPreferences.dailyResetEnabledKey) private var dailyResetEnabled: Bool = true
    @AppStorage(UserPreferences.retentionDaysKey) private var retentionDays: Int = Constants.defaultRetentionDays
    @AppStorage(UserPreferences.hapticsEnabledKey) private var hapticsEnabled: Bool = true

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Behavior Card
                OneThingCard {
                    VStack(alignment: .leading, spacing: 16) {
                        OneThingSectionHeader(title: "Behavior")
                        
                        SettingsToggleRow(
                            icon: "arrow.clockwise",
                            iconColor: .blue,
                            title: "Daily Reset",
                            subtitle: "Start fresh each day",
                            isOn: $dailyResetEnabled
                        )
                        
                        Divider()
                        
                        SettingsToggleRow(
                            icon: "waveform",
                            iconColor: .purple,
                            title: "Haptics",
                            subtitle: "Tactile feedback",
                            isOn: $hapticsEnabled
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
                                    .fill(Color.orange.opacity(0.15))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.body)
                                    .foregroundStyle(.orange)
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
                            .tint(.accentColor)
                        }
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
                                        .fill(
                                            LinearGradient(
                                                colors: [.accentColor, .accentColor.opacity(0.7)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 40, height: 40)
                                    
                                    Image(systemName: "sparkles")
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(.white)
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
                                .fill(
                                    LinearGradient(
                                        colors: [.accentColor.opacity(0.2), .accentColor.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: "1.circle.fill")
                                .font(.title)
                                .foregroundStyle(Color.accentColor)
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
        .oneThingScreenBackground()
        .navigationTitle("Settings")
    }
}

// MARK: - Settings Toggle Row
struct SettingsToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(iconColor)
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

#Preview {
    NavigationStack {
        SettingsView()
    }
}
