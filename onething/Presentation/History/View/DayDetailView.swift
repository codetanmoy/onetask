import SwiftUI
import SwiftData

struct DayDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @AppStorage(UserPreferences.hapticsEnabledKey) private var hapticsEnabled: Bool = true
    @AppStorage(UserPreferences.dailyResetEnabledKey) private var dailyResetEnabled: Bool = true

    @State private var taskDraft: String = ""
    @State private var isEditingTask: Bool = false
    @State private var showDeleteConfirmation: Bool = false

    let entry: DayEntry

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Task Card
                OneThingCard {
                    VStack(alignment: .leading, spacing: 12) {
                        OneThingSectionHeader(title: "Task")
                        
                        if entry.isCompleted || !isEditingTask {
                            Text(entry.taskText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "No task" : entry.taskText)
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundStyle(entry.taskText.isEmpty ? .secondary : .primary)
                        } else {
                            TextField("Task", text: $taskDraft)
                                .font(.title3)
                                .textInputAutocapitalization(.sentences)
                                .submitLabel(.done)
                                .onSubmit(saveTask)
                        }

                        if !entry.isCompleted {
                            Button {
                                if isEditingTask {
                                    saveTask()
                                } else {
                                    taskDraft = entry.taskText
                                    isEditingTask = true
                                }
                            } label: {
                                Label(isEditingTask ? "Save" : "Edit", systemImage: isEditingTask ? "checkmark" : "pencil")
                                    .font(.subheadline.weight(.medium))
                            }
                            .buttonStyle(.bordered)
                            .buttonBorderShape(.capsule)
                            .tint(.primary)
                        }
                    }
                }

                // Time Card
                OneThingCard {
                    VStack(alignment: .leading, spacing: 12) {
                        OneThingSectionHeader(title: "Time")
                        
                        HStack(spacing: 16) {
                            // Timer icon - black/white
                            ZStack {
                                Circle()
                                    .fill(Color(.secondarySystemBackground))
                                    .frame(width: 48, height: 48)
                                
                                Image(systemName: "timer")
                                    .font(.title3)
                                    .foregroundStyle(.primary)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Total Duration")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(DurationFormatter.timer(entry.totalElapsedSeconds()))
                                    .font(.title2.weight(.semibold))
                                    .monospacedDigit()
                            }
                        }
                    }
                }

                // Status Card
                OneThingCard {
                    VStack(alignment: .leading, spacing: 12) {
                        OneThingSectionHeader(title: "Status")
                        
                        if let completedAt = entry.completedAt {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(Color.primary)
                                        .frame(width: 44, height: 44)
                                    
                                    Image(systemName: "checkmark")
                                        .font(.title3.weight(.bold))
                                        .foregroundStyle(colorScheme == .dark ? .black : .white)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Completed")
                                        .font(.headline)
                                    Text(completedAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        } else {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(Color(.secondarySystemBackground))
                                        .frame(width: 44, height: 44)
                                    
                                    Image(systemName: "circle")
                                        .font(.title3)
                                        .foregroundStyle(.tertiary)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("In Progress")
                                        .font(.headline)
                                        .foregroundStyle(.secondary)
                                    Text("Not completed yet")
                                        .font(.footnote)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                    }
                }

                // Actions Card
                OneThingCard(isElevated: false) {
                    VStack(spacing: 12) {
                        Button {
                            copyToToday()
                        } label: {
                            Label("Copy to Today", systemImage: "doc.on.doc")
                                .font(.subheadline.weight(.medium))
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.roundedRectangle(radius: 12))
                        .tint(.primary)

                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete Day", systemImage: "trash")
                                .font(.subheadline.weight(.medium))
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.roundedRectangle(radius: 12))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
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
