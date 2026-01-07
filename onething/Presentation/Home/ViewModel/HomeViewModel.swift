import ActivityKit
import Foundation
import SwiftData
import Combine

struct HomeOptions: Equatable {
    var retentionDays: Int
    var dailyResetEnabled: Bool
    var hapticsEnabled: Bool
}

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var entry: DayEntry?
    @Published private(set) var recentEntries: [DayEntry] = []
    @Published var state: HomeState = .init()

    private var undoHideTask: Task<Void, Never>?

    func handle(_ event: HomeEvent, context: ModelContext, options: HomeOptions) {
        switch event {
        case .onAppear:
            do {
                try stopAnyOvernightRunningTimers(context: context, now: .now)
                try DayEntryRepository.purgeOldEntries(context: context, retentionDays: options.retentionDays)
                entry = try DayEntryRepository.fetchOrCreateToday(
                    context: context,
                    dailyResetEnabled: options.dailyResetEnabled
                )
                state.taskDraft = entry?.taskText ?? ""
                recentEntries = try DayEntryRepository.fetchRecentEntries(context: context, limit: 5)
                refreshStreak(context: context)
                refreshSuggestions(context: context)
                try? WidgetSnapshotService.updateSnapshot(context: context, dailyResetEnabled: options.dailyResetEnabled)
                Task {
                    if let entry = entry {
                        await LiveActivityService.sync(entry: entry)
                    }
                }
            } catch {
                LoggingService.log("Failed to load today entry: \(error)")
            }

        case let .setTask(text):
            guard let entry else { return }
            guard entry.isCompleted == false else { return }
            let capped = String(text.prefix(Constants.maxTaskLength))
            let trimmed = capped.trimmingCharacters(in: .whitespacesAndNewlines)
            entry.taskText = trimmed
            entry.updatedAt = .now
            state.taskDraft = capped
            try? context.save()
            try? WidgetSnapshotService.updateSnapshot(context: context, dailyResetEnabled: options.dailyResetEnabled)
            Task {
                await LiveActivityService.sync(entry: entry)
            }

        case .startStopTapped:
            guard let entry, entry.isCompleted == false else { return }
            guard entry.taskText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else { return }
            if entry.isRunning {
                TimerService.stop(entry: entry)
            } else {
                TimerService.start(entry: entry)
            }
            HapticsService.lightImpact(enabled: options.hapticsEnabled)
            try? context.save()
            try? WidgetSnapshotService.updateSnapshot(context: context, dailyResetEnabled: options.dailyResetEnabled)
            Task {
                await LiveActivityService.sync(entry: entry)
            }
            objectWillChange.send()

        case .resetConfirmed:
            guard let entry, entry.isCompleted == false else { return }
            TimerService.reset(entry: entry)
            HapticsService.lightImpact(enabled: options.hapticsEnabled)
            try? context.save()
            try? WidgetSnapshotService.updateSnapshot(context: context, dailyResetEnabled: options.dailyResetEnabled)
            Task {
                await LiveActivityService.sync(entry: entry)
            }
            objectWillChange.send()

        case .markDoneTapped:
            guard let entry, entry.isCompleted == false else { return }
            if entry.isRunning {
                TimerService.stop(entry: entry)
            }
            // Save previous streak for celebration animation
            state.previousStreakDays = state.streakDays
            entry.completedAt = .now
            entry.updatedAt = .now
            HapticsService.success(enabled: options.hapticsEnabled)
            try? context.save()
            // Refresh recent entries to show newly completed task
            recentEntries = (try? DayEntryRepository.fetchRecentEntries(context: context, limit: 5)) ?? []
            refreshStreak(context: context)
            // Check for milestone achievements
            checkForMilestone(context: context)
            // Cancel evening reminder since task is complete
            NotificationService.cancelEveningReminder()
            try? WidgetSnapshotService.updateSnapshot(context: context, dailyResetEnabled: options.dailyResetEnabled)
            Task {
                await LiveActivityService.sync(entry: entry)
            }
            showUndoWindow(for: entry)
            objectWillChange.send()

        case .undoDone:
            guard let entry else { return }
            undoHideTask?.cancel()
            entry.completedAt = nil
            entry.updatedAt = .now
            HapticsService.lightImpact(enabled: options.hapticsEnabled)
            try? context.save()
            refreshStreak(context: context)
            try? WidgetSnapshotService.updateSnapshot(context: context, dailyResetEnabled: options.dailyResetEnabled)
            Task {
                await LiveActivityService.sync(entry: entry)
            }
            state.showUndoToast = false
            state.lastCompletedAt = nil
            objectWillChange.send()

        case .startAnotherTask:
            state.showUndoToast = false
            state.lastCompletedAt = nil
            undoHideTask?.cancel()

            let today = Calendar.current.startOfDay(for: .now)
            let newEntry = DayEntry(day: today)
            context.insert(newEntry)
            try? context.save()

            entry = newEntry
            state.taskDraft = ""
            HapticsService.lightImpact(enabled: options.hapticsEnabled)
            try? WidgetSnapshotService.updateSnapshot(context: context, dailyResetEnabled: options.dailyResetEnabled)
            objectWillChange.send()
        }
    }

    private func refreshStreak(context: ModelContext) {
        do {
            let streakInfo = try StreakService.calculateStreak(context: context)
            state.streakDays = streakInfo.currentDays
            state.streakAtRisk = streakInfo.isAtRisk
        } catch {
            LoggingService.log("Failed to calculate streak: \(error)")
        }
    }

    private func checkForMilestone(context: ModelContext) {
        do {
            if let milestone = try MilestoneService.checkForNewMilestone(context: context) {
                state.pendingMilestone = milestone
            }
        } catch {
            LoggingService.log("Failed to check milestones: \(error)")
        }
    }

    private func refreshSuggestions(context: ModelContext) {
        do {
            state.suggestions = try TaskSuggestionService.generateSuggestions(context: context)
        } catch {
            LoggingService.log("Failed to load suggestions: \(error)")
        }
    }

    private func showUndoWindow(for entry: DayEntry) {
        state.lastCompletedAt = entry.completedAt
        state.showUndoToast = true

        undoHideTask?.cancel()
        let completionToken = entry.completedAt
        undoHideTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 8_000_000_000)
            await MainActor.run {
                guard let self else { return }
                guard self.state.lastCompletedAt == completionToken else { return }
                self.state.showUndoToast = false
            }
        }
    }

    private func stopAnyOvernightRunningTimers(context: ModelContext, now: Date) throws {
        let today = Calendar.current.startOfDay(for: now)
        let descriptor = FetchDescriptor<DayEntry>(
            predicate: #Predicate { $0.day < today }
        )
        let candidates = try context.fetch(descriptor)
        let running = candidates.filter { $0.startedAt != nil }
        guard running.isEmpty == false else { return }
        for entry in running {
            TimerService.stop(entry: entry, now: now)
        }
        try context.save()
    }
}
