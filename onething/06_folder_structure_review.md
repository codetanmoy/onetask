# Folder Structure Review (Based on Attached Screenshot)

## Screenshot: What’s currently present
Top-level folders:
- `AppConfig`
- `Data`
- `Manager`
- `Media`
- `Presentation`
  - `Components`
  - `Home`
    - `Event`
    - `State`
    - `View`
    - `ViewModel`
- `OnBoarding`
- `RootView`
- `Settings`
- `ShowLog`

This is already close to a clean **feature-first presentation layer** with separated app infrastructure.

---

## What’s good
- `Presentation/Home` is properly split into **Event / State / View / ViewModel**
- `Components` is separated (good for reusable UI)
- `RootView` exists (good place for app shell + routing)
- `Settings` is separated (good for future growth)

---

## Suggested improvements (minimal changes)
### 1) Rename “Manager” → “Services” or “Core”
“Manager” becomes a junk drawer over time. Prefer clearer intent:
- `Services` (timers, notifications, haptics, cloud sync)
- or `Core` (helpers, app services, environment)

### 2) Move “ShowLog” under a debug-only area
If it’s only for dev:
- `Debug/ShowLog`
If it’s user-facing:
- keep under `Presentation/ShowLog`

### 3) Put “OnBoarding” into Presentation
Right now it sits top-level. If it’s UI:
- `Presentation/OnBoarding`

### 4) Clarify “Data”
Recommend structuring like:
- `Data/Models`
- `Data/Persistence` (SwiftData / CloudKit config)
- `Data/Repositories` (optional)
- `Data/Migrations` (future)

### 5) “Media”
If it’s app assets, keep it.
If it’s code for media handling, consider:
- `Services/Media`

---

## Recommended folder structure (clean + scalable)

```
App
├── AppConfig
│   ├── AppEnvironment.swift
│   ├── Constants.swift
│   └── FeatureFlags.swift
│
├── Data
│   ├── Models
│   │   └── DayEntry.swift
│   ├── Persistence
│   │   ├── ModelContainerFactory.swift
│   │   └── CloudKitConfig.swift
│   └── Repositories (optional)
│       └── DayEntryRepository.swift
│
├── Services   (rename from Manager)
│   ├── TimerService.swift
│   ├── HapticsService.swift
│   ├── NotificationService.swift
│   └── LoggingService.swift
│
├── Presentation
│   ├── Components
│   ├── RootView
│   ├── Home
│   │   ├── Event
│   │   ├── State
│   │   ├── View
│   │   └── ViewModel
│   ├── OnBoarding
│   ├── Settings
│   └── Debug (optional)
│       └── ShowLog
│
└── Media
    └── (assets / local resources)
```

---

## Mapping this to OneThing (MVP)
- `Data/Models/DayEntry.swift` → the only model
- `Data/Persistence/ModelContainerFactory.swift` → SwiftData + CloudKit config
- `Services/TimerService.swift` → timer calculations + lifecycle hooks
- `Presentation/Home/*` → Home UI + state machine
- `Presentation/History/*` (add feature folder later) → history UI
- `Presentation/Settings/*` → toggles + retention options

---

## Quick final note
Your current structure is good.  
The only high-impact fix is: **rename Manager** + **move OnBoarding under Presentation** + isolate debug tools.
