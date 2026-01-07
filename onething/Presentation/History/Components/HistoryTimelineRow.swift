import SwiftUI

struct HistoryTimelineRow: View {
    let entry: DayEntry
    
    private var taskDisplayText: String {
        let trimmed = entry.taskText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "No task" : trimmed
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // Status icon - pure black/white
            ZStack {
                Circle()
                    .fill(entry.isCompleted ? Color.primary.opacity(0.1) : Color(.tertiarySystemFill))
                    .frame(width: 40, height: 40)
                
                Image(systemName: entry.isCompleted ? "checkmark" : "circle")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(entry.isCompleted ? .primary : .tertiary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(taskDisplayText)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(entry.isCompleted ? .primary : .secondary)
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
                    .foregroundStyle(.tertiary)
                    
                    // Duration
                    Text("•")
                        .foregroundStyle(.quaternary)
                    
                    Text(DurationFormatter.compact(entry.totalElapsedSeconds()))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .monospacedDigit()
                }
            }

            Spacer(minLength: 0)
            
            // Minimal status indicator
            if entry.isCompleted {
                Image(systemName: "checkmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.primary)
            }
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
