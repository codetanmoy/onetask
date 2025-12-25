import Foundation
import SwiftData

enum DayEntryRepository {
    static func startOfDay(calendar: Calendar = .current, now: Date = .now) -> Date {
        calendar.startOfDay(for: now)
    }

    @MainActor
    static func fetchOrCreateToday(
        context: ModelContext,
        dailyResetEnabled: Bool,
        now: Date = .now
    ) throws -> DayEntry {
        let today = Calendar.current.startOfDay(for: now)

        let descriptor = FetchDescriptor<DayEntry>(
            predicate: #Predicate { $0.day == today },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let existing = try context.fetch(descriptor)
        if let active = existing.first(where: { $0.completedAt == nil }) {
            return active
        }
        // If all of today's entries are completed, create a fresh one so Home is ready for the next task.
        let newEntry: DayEntry
        if existing.isEmpty {
            if dailyResetEnabled {
                newEntry = DayEntry(day: today)
            } else {
                let carryText = try fetchMostRecentTaskText(context: context, before: today)
                newEntry = DayEntry(day: today, taskText: carryText ?? "")
            }
        } else {
            newEntry = DayEntry(day: today)
        }

        context.insert(newEntry)
        try context.save()
        return newEntry
    }

    @MainActor
    static func fetchRecentEntries(context: ModelContext, limit: Int, now: Date = .now) throws -> [DayEntry] {
        let today = Calendar.current.startOfDay(for: now)
        var descriptor = FetchDescriptor<DayEntry>(
            predicate: #Predicate { $0.day < today },
            sortBy: [SortDescriptor(\.day, order: .reverse)]
        )
        descriptor.fetchLimit = max(0, limit)
        return try context.fetch(descriptor)
    }

    @MainActor
    static func fetchMostRecentTaskText(context: ModelContext, before day: Date) throws -> String? {
        var descriptor = FetchDescriptor<DayEntry>(
            predicate: #Predicate { $0.day < day },
            sortBy: [SortDescriptor(\.day, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        guard let entry = try context.fetch(descriptor).first else { return nil }
        let trimmed = entry.taskText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    @MainActor
    static func purgeOldEntries(context: ModelContext, retentionDays: Int, now: Date = .now) throws {
        guard retentionDays > 0 else { return }
        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .day, value: -retentionDays, to: calendar.startOfDay(for: now)) ?? .distantPast

        let descriptor = FetchDescriptor<DayEntry>(
            predicate: #Predicate { $0.day < cutoff }
        )
        for entry in try context.fetch(descriptor) {
            context.delete(entry)
        }
        try context.save()
    }
}
