import SwiftUI

struct HomeRecentBlock: View {
    let entries: [DayEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            OneThingSectionHeader(title: "Recent days")

            VStack(spacing: 0) {
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    VStack(spacing: 0) {
                        recentRow(entry: entry)
                        
                        // Divider for all but last item
                        if index < entries.count - 1 {
                            Divider()
                                .padding(.leading, 44)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.tertiarySystemGroupedBackground).opacity(0.6))
            )
        }
    }
    
    private func recentRow(entry: DayEntry) -> some View {
        HStack(alignment: .center, spacing: 12) {
            // Status icon
            ZStack {
                Circle()
                    .fill(entry.isCompleted ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: entry.isCompleted ? "checkmark" : "clock")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(entry.isCompleted ? .green : .orange)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.taskText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty 
                     ? "No task" 
                     : entry.taskText)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                Text(entry.day, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer(minLength: 0)
            
            // Status badge
            Text(entry.isCompleted ? "Done" : "Open")
                .font(.caption2.weight(.medium))
                .foregroundStyle(entry.isCompleted ? .green : .orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(entry.isCompleted ? Color.green.opacity(0.12) : Color.orange.opacity(0.12))
                )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

