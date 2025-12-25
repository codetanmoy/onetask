# OneThing — Data Models + Cloud Sync (SwiftData + CloudKit)

This doc defines the **actual models** and a clean approach for **CloudKit sync** using SwiftData.

> Goal: local-first, fast; CloudKit only as a syncing layer (no custom backend).

---

## 1) SwiftData Models

### 1.1 DayEntry (MVP)
```swift
import Foundation
import SwiftData

@Model
final class DayEntry {
    // Identity
    @Attribute(.unique) var id: UUID

    // Day key (normalized to start-of-day in the user’s local calendar)
    @Attribute(.indexed) var day: Date

    // Content
    var taskText: String

    // Timer
    var startedAt: Date?          // nil when not running
    var elapsedSeconds: Int       // accumulated seconds (stopped time)

    // Completion
    var completedAt: Date?

    // Audit
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        day: Date,
        taskText: String = "",
        startedAt: Date? = nil,
        elapsedSeconds: Int = 0,
        completedAt: Date? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.day = day
        self.taskText = taskText
        self.startedAt = startedAt
        self.elapsedSeconds = elapsedSeconds
        self.completedAt = completedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
```

### 1.2 Derived properties (computed, not stored)
```swift
extension DayEntry {
    var isRunning: Bool { startedAt != nil }
    var isCompleted: Bool { completedAt != nil }

    func totalElapsedSeconds(now: Date = .now) -> Int {
        guard let startedAt else { return elapsedSeconds }
        let delta = Int(now.timeIntervalSince(startedAt))
        return max(0, elapsedSeconds + delta)
    }
}
```

---

## 2) Constraints & Indices

### Uniqueness
- `id` is unique
- Also recommended: one entry per day **per user/device**
  - Achieve by enforcing logic: fetch-or-create by `day`

### Indexed
- `day` should be indexed for fast “today” queries

---

## 3) Cloud Sync (SwiftData + CloudKit)

### 3.1 Setup (Xcode)
1. Turn on **iCloud → CloudKit** capability
2. Pick container: `iCloud.<your.bundle.id>`
3. Ensure CloudKit schema is set up (Development first)

### 3.2 ModelContainer configuration
```swift
import SwiftData

enum PersistenceController {
    static func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            DayEntry.self
        ])

        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.com.yourcompany.onething") // change this
        )

        return try ModelContainer(for: schema, configurations: [config])
    }
}
```

> Use **private database** for personal tasks/timers.

---

## 4) Fetch-or-create “Today” entry

### Normalize to start-of-day
```swift
import Foundation

func startOfToday(calendar: Calendar = .current, now: Date = .now) -> Date {
    calendar.startOfDay(for: now)
}
```

### Fetch-or-create
```swift
import SwiftData

@MainActor
func fetchOrCreateToday(context: ModelContext) throws -> DayEntry {
    let today = Calendar.current.startOfDay(for: .now)

    let descriptor = FetchDescriptor<DayEntry>(
        predicate: #Predicate { $0.day == today },
        sortBy: []
    )

    if let existing = try context.fetch(descriptor).first {
        return existing
    }

    let entry = DayEntry(day: today)
    context.insert(entry)
    try context.save()
    return entry
}
```

---

## 5) Migrations (only if model changes later)

SwiftData migrations can be handled by:
- lightweight migrations (add optional fields)
- custom migration plan (if needed)

### Example migration plan placeholder (future)
```swift
// Define a MigrationPlan when you introduce non-trivial changes.
// Keep MVP simple; do this only when required.
```

---

## 6) Seeding (Optional, MVP-friendly)
Seed nothing by default.  
If you want a demo seed in Debug builds:
- create 3–5 DayEntry items for the past few days.

---

## 7) Notes
- Keep timer correctness local (based on `startedAt` + delta)
- CloudKit sync will merge changes across devices; avoid conflicting edits by:
  - updating `updatedAt`
  - keeping the UI single-entry-per-day
