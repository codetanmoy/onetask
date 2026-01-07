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
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }
    
    private func recentRow(entry: DayEntry) -> some View {
        HStack(alignment: .center, spacing: 12) {
            // Status icon - pure black/white
            ZStack {
                Circle()
                    .fill(entry.isCompleted ? Color.primary.opacity(0.1) : Color(.tertiarySystemFill))
                    .frame(width: 32, height: 32)
                
                Image(systemName: entry.isCompleted ? "checkmark" : "circle")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(entry.isCompleted ? .primary : .tertiary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.taskText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty 
                     ? "No task" 
                     : entry.taskText)
                    .font(.subheadline)
                    .foregroundStyle(entry.isCompleted ? .primary : .secondary)
                    .lineLimit(1)
                
                Text(entry.day, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer(minLength: 0)
            
            // Status badge - minimal
            if entry.isCompleted {
                Image(systemName: "checkmark")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}
