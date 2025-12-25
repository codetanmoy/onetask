import SwiftUI

struct HistoryRow: View {
    let entry: DayEntry

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.day, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                    .font(.headline)

                if entry.taskText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("—")
                        .foregroundStyle(.secondary)
                } else {
                    Text(entry.taskText)
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 4) {
                Text(DurationFormatter.compact(entry.totalElapsedSeconds()))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)

                Text(entry.isCompleted ? "Done" : "Open")
                    .font(.caption)
                    .foregroundStyle(entry.isCompleted ? .secondary : .primary)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    List {
        HistoryRow(entry: DayEntry(day: Calendar.current.startOfDay(for: .now), taskText: "Ship history UI", elapsedSeconds: 3661, completedAt: .now))
        HistoryRow(entry: DayEntry(day: Calendar.current.date(byAdding: .day, value: -1, to: .now)!, taskText: "", elapsedSeconds: 120, completedAt: nil))
    }
}

