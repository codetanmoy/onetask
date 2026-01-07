import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(UserPreferences.retentionDaysKey) private var retentionDays: Int = Constants.defaultRetentionDays
    @AppStorage(UserPreferences.dailyResetEnabledKey) private var dailyResetEnabled: Bool = true
    @State private var refreshToken: UUID = UUID()
    @State private var selectedDate: Date = .now

    @Query(sort: [SortDescriptor(\DayEntry.day, order: .forward), SortDescriptor(\DayEntry.createdAt, order: .forward)]) private var allEntries: [DayEntry]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Date Picker Card
                OneThingCard {
                    VStack(alignment: .leading, spacing: 12) {
                        OneThingSectionHeader(title: "Select Date")
                        
                        DatePicker(
                            "Select a day",
                            selection: $selectedDate,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.graphical)
                        .tint(.primary)
                    }
                }
                
                // Entries Card
                OneThingCard {
                    VStack(alignment: .leading, spacing: 16) {
                        OneThingSectionHeader(title: selectedDayTitle)
                        
                        if selectedDayEntries.isEmpty {
                            VStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color(.secondarySystemBackground))
                                        .frame(width: 64, height: 64)
                                    
                                    Image(systemName: "calendar.badge.clock")
                                        .font(.title)
                                        .foregroundStyle(.secondary)
                                }
                                
                                VStack(spacing: 4) {
                                    Text("No entries")
                                        .font(.headline)
                                    Text("Pick another date to view history.")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 16)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(selectedDayEntries) { entry in
                                    NavigationLink {
                                        DayDetailView(entry: entry)
                                    } label: {
                                        HistoryEntryRow(entry: entry)
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button("Copy to Today") {
                                            copyToToday(entry)
                                        }
                                        Button("Delete", role: .destructive) {
                                            delete(entry)
                                        }
                                    }
                                    
                                    if entry.id != selectedDayEntries.last?.id {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
        .id(refreshToken)
        .navigationTitle("History")
        .refreshable {
            refreshToken = UUID()
        }
        .onAppear {
            if let newestDay = filteredEntries.last?.day {
                selectedDate = newestDay
            } else {
                selectedDate = .now
            }
        }
    }

    private var filteredEntries: [DayEntry] {
        guard retentionDays > 0 else { return allEntries }
        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .day, value: -retentionDays, to: calendar.startOfDay(for: .now)) ?? .distantPast
        return allEntries.filter { $0.day >= cutoff }
    }

    private var selectedDay: Date {
        Calendar.current.startOfDay(for: selectedDate)
    }

    private var selectedDayEntries: [DayEntry] {
        filteredEntries
            .filter { $0.day == selectedDay }
            .filter { entry in
                // Only show entries that have meaningful content
                // Filter out auto-created placeholder entries that were never used
                let hasTaskText = !entry.taskText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                let wasStarted = entry.startedAt != nil || entry.elapsedSeconds > 0
                let wasCompleted = entry.completedAt != nil
                
                return hasTaskText || wasStarted || wasCompleted
            }
    }

    private var selectedDayTitle: String {
        selectedDay.formatted(date: .complete, time: .omitted)
    }

    @MainActor
    private func copyToToday(_ fromEntry: DayEntry) {
        do {
            let todayEntry = try DayEntryRepository.fetchOrCreateToday(
                context: modelContext,
                dailyResetEnabled: dailyResetEnabled
            )
            todayEntry.taskText = fromEntry.taskText
            todayEntry.updatedAt = .now
            try modelContext.save()
        } catch {
            LoggingService.log("Copy to today failed: \(error)")
        }
    }


    private func delete(_ entry: DayEntry) {
        modelContext.delete(entry)
        try? modelContext.save()
    }
}

// MARK: - History Entry Row
struct HistoryEntryRow: View {
    let entry: DayEntry
    
    var body: some View {
        HStack(spacing: 14) {
            // Leading status icon
            ZStack {
                Circle()
                    .fill(entry.isCompleted ? Color.primary.opacity(0.1) : Color(.secondarySystemBackground))
                    .frame(width: 40, height: 40)
                
                Image(systemName: entry.isCompleted ? "checkmark" : "circle")
                    .font(.body)
                    .foregroundStyle(entry.isCompleted ? .primary : .tertiary)
            }
            
            // Middle: title + date
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.taskText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "No task" : entry.taskText)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
                Text(entry.day, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Trailing: time & duration
            VStack(alignment: .trailing, spacing: 4) {
                Text(entry.createdAt, format: .dateTime.hour().minute())
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .monospacedDigit()
                
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                        .font(.caption2)
                    Text(DurationFormatter.compact(entry.totalElapsedSeconds()))
                        .font(.caption)
                        .monospacedDigit()
                }
                .foregroundStyle(.tertiary)
            }
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
    }
}

#Preview {
    NavigationStack {
        HistoryView()
    }
    .modelContainer(for: DayEntry.self, inMemory: true)
}
