import SwiftUI
import SwiftData

/// Achievements view displaying earned and locked badges
struct AchievementsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var earnedMilestones: Set<MilestoneService.Milestone> = []
    @State private var stats: StatsService.Stats = .empty
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Progress Hero
                progressHero
                
                // Badges List
                badgesSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color(.systemBackground))
        .navigationTitle("Achievements")
        .task {
            loadData()
        }
    }
    
    // MARK: - Progress Hero
    
    private var progressHero: some View {
        VStack(spacing: 8) {
            Text("\(earnedMilestones.count)/\(allBadges.count)")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            
            Text("achievements unlocked")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
    
    // MARK: - Badges Section
    
    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("All Achievements")
                .font(.headline)
                .foregroundStyle(.primary)
            
            VStack(spacing: 0) {
                ForEach(Array(allBadges.enumerated()), id: \.element.id) { index, badge in
                    BadgeRow(
                        badge: badge,
                        isEarned: earnedMilestones.contains(badge.milestone),
                        progress: progressFor(badge.milestone)
                    )
                    
                    if index < allBadges.count - 1 {
                        Divider()
                            .padding(.leading, 56)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }
    
    // MARK: - Data Loading
    
    private func loadData() {
        if let rawValues = UserDefaults.standard.array(forKey: "shownMilestones") as? [String] {
            earnedMilestones = Set(rawValues.compactMap { MilestoneService.Milestone(rawValue: $0) })
        }
        
        do {
            stats = try StatsService.calculateStats(context: modelContext)
        } catch {}
    }
    
    private func progressFor(_ milestone: MilestoneService.Milestone) -> Double {
        switch milestone {
        case .firstTask:
            return stats.totalTasksCompleted >= 1 ? 1.0 : 0.0
        case .streak7:
            return min(Double(stats.currentStreak) / 7.0, 1.0)
        case .streak30:
            return min(Double(stats.currentStreak) / 30.0, 1.0)
        case .tasks10:
            return min(Double(stats.totalTasksCompleted) / 10.0, 1.0)
        case .tasks50:
            return min(Double(stats.totalTasksCompleted) / 50.0, 1.0)
        case .tasks100:
            return min(Double(stats.totalTasksCompleted) / 100.0, 1.0)
        case .hours10:
            return min(Double(stats.totalMinutesFocused) / 600.0, 1.0)
        }
    }
    
    private var allBadges: [Badge] {
        MilestoneService.Milestone.allCases.map { Badge(milestone: $0) }
    }
}

// MARK: - Badge Model

private struct Badge: Identifiable {
    let id = UUID()
    let milestone: MilestoneService.Milestone
    
    var sfSymbol: String {
        switch milestone {
        case .firstTask: return "star"
        case .streak7: return "flame"
        case .streak30: return "flame.fill"
        case .tasks10: return "list.bullet"
        case .tasks50: return "list.bullet.rectangle"
        case .tasks100: return "trophy"
        case .hours10: return "clock"
        }
    }
    
    var name: String {
        String(milestone.title.dropFirst(2)).trimmingCharacters(in: .whitespaces)
    }
    
    var requirement: String {
        switch milestone {
        case .firstTask: return "Complete your first task"
        case .streak7: return "Maintain a 7 day streak"
        case .streak30: return "Maintain a 30 day streak"
        case .tasks10: return "Complete 10 tasks"
        case .tasks50: return "Complete 50 tasks"
        case .tasks100: return "Complete 100 tasks"
        case .hours10: return "Focus for 10 hours total"
        }
    }
}

// MARK: - Badge Row

private struct BadgeRow: View {
    let badge: Badge
    let isEarned: Bool
    let progress: Double
    
    var body: some View {
        HStack(spacing: 16) {
            // Badge icon with SF Symbol
            ZStack {
                Circle()
                    .fill(isEarned ? Color.primary.opacity(0.08) : Color(.tertiarySystemFill))
                    .frame(width: 44, height: 44)
                
                if !isEarned && progress > 0 {
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.primary.opacity(0.2), lineWidth: 2)
                        .frame(width: 44, height: 44)
                        .rotationEffect(.degrees(-90))
                }
                
                Image(systemName: isEarned ? badge.sfSymbol + ".fill" : badge.sfSymbol)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(isEarned ? .primary : .tertiary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(badge.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(isEarned ? .primary : .secondary)
                
                Text(badge.requirement)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
            
            if isEarned {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.primary)
            } else if progress > 0 {
                Text("\(Int(progress * 100))%")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.tertiary)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    NavigationStack {
        AchievementsView()
    }
    .modelContainer(for: DayEntry.self, inMemory: true)
}
