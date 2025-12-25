import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(UserPreferences.retentionDaysKey) private var retentionDays: Int = Constants.defaultRetentionDays
    @AppStorage(UserPreferences.dailyResetEnabledKey) private var dailyResetEnabled: Bool = true
    @State private var refreshToken: UUID = UUID()

    @Query(sort: [SortDescriptor(\DayEntry.day, order: .forward), SortDescriptor(\DayEntry.createdAt, order: .reverse)]) private var allEntries: [DayEntry]

    var body: some View {
        List {
            ForEach(filteredEntries) { entry in
                NavigationLink {
                    DayDetailView(entry: entry)
                } label: {
                    HistoryRow(entry: entry)
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
            .onDelete(perform: deleteOffsets)
        }
        .id(refreshToken)
        .navigationTitle("History")
        .refreshable {
            // SwiftData/@Query usually updates automatically; this forces a re-evaluation and is a good UX affordance.
            refreshToken = UUID()
        }
    }

    private var filteredEntries: [DayEntry] {
        guard retentionDays > 0 else { return allEntries }
        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .day, value: -retentionDays, to: calendar.startOfDay(for: .now)) ?? .distantPast
        return allEntries.filter { $0.day >= cutoff }
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

    private func deleteOffsets(_ offsets: IndexSet) {
        for index in offsets {
            delete(filteredEntries[index])
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
