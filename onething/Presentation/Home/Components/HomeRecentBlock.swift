import SwiftUI

struct HomeRecentBlock: View {
    let entries: [DayEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            OneThingSectionHeader(title: "Recent days")

            ForEach(entries) { entry in
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(entry.day, format: .dateTime.month(.abbreviated).day())
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(width: 64, alignment: .leading)

                    Text(entry.taskText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "—" : entry.taskText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    Text(entry.isCompleted ? "Done" : "Open")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

