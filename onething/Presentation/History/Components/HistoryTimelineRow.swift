import SwiftUI

struct HistoryTimelineRow: View {
    let entry: DayEntry

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(entry.createdAt, format: .dateTime.hour().minute())
                .font(.footnote)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .frame(width: 54, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.taskText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "—" : entry.taskText)
                    .font(.body)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(DurationFormatter.compact(entry.totalElapsedSeconds()))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()

                    Text(entry.isCompleted ? "Done" : "Open")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(entry.isCompleted ? .secondary : .primary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    List {
        HistoryTimelineRow(entry: DayEntry(day: Calendar.current.startOfDay(for: .now), taskText: "Deep work", elapsedSeconds: 1250, completedAt: .now))
        HistoryTimelineRow(entry: DayEntry(day: Calendar.current.startOfDay(for: .now), taskText: "", elapsedSeconds: 0, completedAt: nil))
    }
}

