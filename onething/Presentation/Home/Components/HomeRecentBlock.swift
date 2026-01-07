import SwiftUI

struct HomeRecentBlock: View {
    let entries: [DayEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            OneThingSectionHeader(title: "Recent tasks")
            VStack(spacing: 2) {
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                   recentRow(entry: entry)
                }
            }
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.clear))
            )
        }
    }
    
    private func recentRow(entry: DayEntry) -> some View {
        HStack(alignment: .center, spacing: 12) {
            // Leading status glyph in circular container
            ZStack {
                Circle()
                    .fill(entry.isCompleted ? Color.primary.opacity(0.1) : Color(.tertiarySystemFill))
                    .frame(width: 36, height: 36)
                Image(systemName: entry.isCompleted ? "checkmark" : "circle")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(entry.isCompleted ? .primary : .tertiary)
            }

            // Middle: title + subtitle (single line title)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.taskText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                     ? "No task"
                     : entry.taskText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(entry.day, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            // Trailing: metadata stack (time + minimalist sparkline placeholder)
            VStack(alignment: .trailing, spacing: 6) {
                // Time (createdAt if available else day time)
                Text(entry.createdAt, format: .dateTime.hour().minute())
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .monospacedDigit()

                // Minimalist sparkline placeholder bars (monochrome)
                HStack(alignment: .bottom, spacing: 2) {
                    Capsule().fill(Color(.secondaryLabel)).frame(width: 3, height: 6)
                    Capsule().fill(Color(.tertiaryLabel)).frame(width: 3, height: 10)
                    Capsule().fill(Color(.tertiaryLabel)).frame(width: 3, height: 7)
                    Capsule().fill(Color(.tertiaryLabel)).frame(width: 3, height: 12)
                    Capsule().fill(Color(.tertiaryLabel)).frame(width: 3, height: 8)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
        )
    }
}
