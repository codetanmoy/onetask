import SwiftUI
import SwiftData

struct DayDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @AppStorage(UserPreferences.hapticsEnabledKey) private var hapticsEnabled: Bool = true
    @AppStorage(UserPreferences.dailyResetEnabledKey) private var dailyResetEnabled: Bool = true

    @State private var taskDraft: String = ""
    @State private var isEditingTask: Bool = false
    @State private var showDeleteConfirmation: Bool = false

    let entry: DayEntry

    var body: some View {
        Form {
            Section("Task") {
                if entry.isCompleted || !isEditingTask {
                    Text(entry.taskText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "—" : entry.taskText)
                } else {
                    TextField("Task", text: $taskDraft)
                        .textInputAutocapitalization(.sentences)
                        .submitLabel(.done)
                        .onSubmit(saveTask)
                }

                if !entry.isCompleted {
                    Button(isEditingTask ? "Save" : "Edit") {
                        if isEditingTask {
                            saveTask()
                        } else {
                            taskDraft = entry.taskText
                            isEditingTask = true
                        }
                    }
                }
            }

            Section("Time") {
                LabeledContent("Total") {
                    Text(DurationFormatter.timer(entry.totalElapsedSeconds()))
                        .monospacedDigit()
                }
            }

            Section("Status") {
                if let completedAt = entry.completedAt {
                    LabeledContent("Completed") {
                        Text(completedAt.formatted(date: .abbreviated, time: .shortened))
                    }
                } else {
                    Text("Not done")
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button("Copy to Today") {
                    copyToToday()
                }

                Button("Delete Day", role: .destructive) {
                    showDeleteConfirmation = true
                }
            }
        }
        .navigationTitle(entry.day.formatted(date: .abbreviated, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            taskDraft = entry.taskText
        }
        .confirmationDialog("Delete this day?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                modelContext.delete(entry)
                try? modelContext.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone.")
        }
    }

    private func saveTask() {
        let trimmed = taskDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.taskText = String(trimmed.prefix(Constants.maxTaskLength))
        entry.updatedAt = .now
        try? modelContext.save()
        isEditingTask = false
        HapticsService.lightImpact(enabled: hapticsEnabled)
    }

    @MainActor
    private func copyToToday() {
        do {
            let todayEntry = try DayEntryRepository.fetchOrCreateToday(
                context: modelContext,
                dailyResetEnabled: dailyResetEnabled
            )
            todayEntry.taskText = entry.taskText
            todayEntry.updatedAt = .now
            try modelContext.save()
            HapticsService.lightImpact(enabled: hapticsEnabled)
        } catch {
            LoggingService.log("Copy to today failed: \(error)")
        }
    }

}

#Preview {
    NavigationStack {
        let entry = DayEntry(day: Calendar.current.startOfDay(for: .now), taskText: "Write Day Detail view", elapsedSeconds: 125, completedAt: nil)
        DayDetailView(entry: entry)
    }
    .modelContainer(for: DayEntry.self, inMemory: true)
}
