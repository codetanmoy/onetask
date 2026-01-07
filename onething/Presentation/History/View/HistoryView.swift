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
        List {
            Section {
                DatePicker(
                    "Select a day",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .tint(.primary)
            }

            Section {
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
                    .padding(.vertical, 32)
                } else {
                    ForEach(selectedDayEntries) { entry in
                        NavigationLink {
                            DayDetailView(entry: entry)
                        } label: {
                            HistoryTimelineRow(entry: entry)
                        }
                        .contextMenu {
                            Button("Copy to Today") {
                                copyToToday(entry)
                            }
                            Button("Delete", role: .destructive) {
                                delete(entry)
                            }
                        }
                    }
                    .onDelete(perform: deleteOffsetsForSelectedDay)
                }
            } header: {
                Text(selectedDayTitle)
            }
        }
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
        filteredEntries.filter { $0.day == selectedDay }
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

    private func deleteOffsetsForSelectedDay(_ offsets: IndexSet) {
        for index in offsets {
            delete(selectedDayEntries[index])
        }
    }

    private func delete(_ entry: DayEntry) {
        modelContext.delete(entry)
        try? modelContext.save()
    }
}

#Preview {
    NavigationStack {
        HistoryView()
    }
    .modelContainer(for: DayEntry.self, inMemory: true)
}
