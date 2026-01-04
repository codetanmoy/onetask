import SwiftUI

struct HistoryTimelineRow: View {
    let entry: DayEntry
    
    private var taskDisplayText: String {
        let trimmed = entry.taskText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "No task" : trimmed
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // Status icon with colored background
            ZStack {
                Circle()
                    .fill(entry.isCompleted ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: entry.isCompleted ? "checkmark" : "clock")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(entry.isCompleted ? .green : .orange)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(taskDisplayText)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    // Time created
                    Label {
                        Text(entry.createdAt, format: .dateTime.hour().minute())
                            .monospacedDigit()
                    } icon: {
                        Image(systemName: "clock")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    
                    // Duration
                    Text("•")
                        .foregroundStyle(.quaternary)
                    
                    Text(DurationFormatter.compact(entry.totalElapsedSeconds()))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }

            Spacer(minLength: 0)
            
            // Status badge
            Text(entry.isCompleted ? "Done" : "Open")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(entry.isCompleted ? .green : .orange)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(entry.isCompleted ? Color.green.opacity(0.12) : Color.orange.opacity(0.12))
                        .overlay(
                            Capsule()
                                .strokeBorder(entry.isCompleted ? Color.green.opacity(0.2) : Color.orange.opacity(0.2), lineWidth: 1)
                        )
                )
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    List {
        HistoryTimelineRow(entry: DayEntry(day: Calendar.current.startOfDay(for: .now), taskText: "Deep work session", elapsedSeconds: 1250, completedAt: .now))
        HistoryTimelineRow(entry: DayEntry(day: Calendar.current.startOfDay(for: .now), taskText: "", elapsedSeconds: 0, completedAt: nil))
    }
}

