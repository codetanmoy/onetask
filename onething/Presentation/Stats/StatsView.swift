import SwiftUI
import SwiftData

struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @State private var stats: StatsService.Stats = .empty
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Hero: Current Streak
                if stats.currentStreak > 0 {
                    streakHero
                }
                
                // Summary Grid
                summarySection
                
                // Activity Breakdown
                activitySection
                
                // Member info
                if let memberSince = stats.memberSince {
                    memberSinceView(memberSince)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color(.systemBackground))
        .navigationTitle("Statistics")
        .task {
            refreshStats()
        }
        .refreshable {
            refreshStats()
        }
    }
    
    // MARK: - Hero Streak
    
    private var streakHero: some View {
        VStack(spacing: 8) {
            Text("\(stats.currentStreak)")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            
            Text("day streak")
                .font(.title3.weight(.medium))
                .foregroundStyle(.secondary)
            
            if stats.longestStreak > stats.currentStreak {
                Text("Best: \(stats.longestStreak) days")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
    
    // MARK: - Summary Section
    
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Summary")
                .font(.headline)
                .foregroundStyle(.primary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                SummaryCell(
                    value: "\(stats.totalTasksCompleted)",
                    label: "Tasks Completed",
                    isHighlighted: true
                )
                
                SummaryCell(
                    value: formatHours(stats.totalMinutesFocused),
                    label: "Total Focused"
                )
                
                SummaryCell(
                    value: "\(stats.weekTasksCompleted)",
                    label: "This Week"
                )
                
                SummaryCell(
                    value: "\(stats.weekActiveDays)/7",
                    label: "Active Days"
                )
            }
        }
    }
    
    // MARK: - Activity Section
    
    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today")
                .font(.headline)
                .foregroundStyle(.primary)
            
            HStack(spacing: 16) {
                ActivityRow(
                    value: "\(stats.todayTasksCompleted)",
                    label: "completed",
                    isHighlighted: stats.todayTasksCompleted > 0
                )
                
                Divider()
                    .frame(height: 40)
                
                ActivityRow(
                    value: "\(stats.todayMinutesFocused)",
                    label: "min focused",
                    isHighlighted: false
                )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }
    
    // MARK: - Member Since
    
    private func memberSinceView(_ date: Date) -> some View {
        HStack {
            Text("Member since \(date, format: .dateTime.month(.wide).year())")
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
    
    // MARK: - Helpers
    
    private func refreshStats() {
        do {
            stats = try StatsService.calculateStats(context: modelContext)
        } catch {
            // Keep empty stats
        }
    }
    
    private func formatHours(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)m"
        }
        let hours = Double(minutes) / 60.0
        return String(format: "%.1fh", hours)
    }
}

// MARK: - Summary Cell

private struct SummaryCell: View {
    let value: String
    let label: String
    var isHighlighted: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(isHighlighted ? .primary : .primary)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Activity Row

private struct ActivityRow: View {
    let value: String
    let label: String
    var isHighlighted: Bool = false
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(isHighlighted ? .primary : .primary)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        StatsView()
    }
    .modelContainer(for: DayEntry.self, inMemory: true)
}
