import SwiftUI

struct HistoryRow: View {
    let entry: DayEntry
    
    private var taskDisplayText: String {
        let trimmed = entry.taskText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "No task" : trimmed
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // Status icon
            ZStack {
                Circle()
                    .fill(entry.isCompleted ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: entry.isCompleted ? "checkmark.circle.fill" : "clock.fill")
                    .font(.title3)
                    .foregroundStyle(entry.isCompleted ? .green : .orange)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.day, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(taskDisplayText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 4) {
                // Duration with icon
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                        .font(.caption2)
                    Text(DurationFormatter.compact(entry.totalElapsedSeconds()))
                        .monospacedDigit()
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                // Status badge
                Text(entry.isCompleted ? "Done" : "Open")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(entry.isCompleted ? .green : .orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(entry.isCompleted ? Color.green.opacity(0.12) : Color.orange.opacity(0.12))
                    )
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    List {
        HistoryRow(entry: DayEntry(day: Calendar.current.startOfDay(for: .now), taskText: "Ship history UI", elapsedSeconds: 3661, completedAt: .now))
        HistoryRow(entry: DayEntry(day: Calendar.current.date(byAdding: .day, value: -1, to: .now)!, taskText: "", elapsedSeconds: 120, completedAt: nil))
    }
}

