# OneThing — Widget Implementation Plan 

This document defines exactly what we will implement for widgets in OneThing.

---

## 1) Goals
- Give users a **fast glance** at their OneThing without opening the app.
- Keep the widget **minimal** so it doesn’t add noise or extra workflows.
- Ensure widget info stays **correct** even when the app is not running.

---

## 2) Widget Types to Build (MVP)

### 2.1 Home Screen Widget
**Sizes**
- Small
- Medium

**Displays**
- Today’s task (1–2 lines)
- Status: **Running / Stopped / Done**
- Elapsed time (computed from stored timer state)

**Interaction**
- Tap opens the app → Home screen
- No buttons/actions in MVP (keep stable & simple)

---

### 2.2 Lock Screen Widget (Accessory)
**Types**
- Accessory Circular (timer/status)
- Accessory Rectangular (task + status)

**Displays**
- Circular: elapsed time + running indicator
- Rectangular: task (short) + status + elapsed

**Interaction**
- Tap opens the app → Home screen

---

## 3) Data Sharing Strategy (Required)
Widgets cannot depend on live app memory. We need a simple shared data source.

### Chosen approach (recommended)
✅ **App Group + Snapshot File**
- Main app writes a small “Widget Snapshot” whenever state changes.
- Widget reads snapshot to render UI.
- Works offline and after device restart.
- Independent of Cloud sync timing.

**Snapshot contains only what widget needs**
- taskText
- elapsedSeconds
- startedAt
- completedAt
- updatedAt

**Important**
- Widget computes live elapsed time if startedAt exists.
- Widget does not access SwiftData directly in MVP.

---

## 4) When the App Updates the Widget Snapshot
We must write snapshot + reload widget timeline after these events:

### Task events
- Task set
- Task edited
- Task cleared (if allowed)

### Timer events
- Start timer
- Stop timer
- Reset timer

### Completion events
- Mark done (auto-stop timer first)
- Undo completion (if implemented)

### App lifecycle events
- App becomes active (refresh snapshot once)
- Day rollover handling (new day entry created)

---

## 5) Widget Refresh Policy (Performance Rules)
Widgets should refresh often enough to feel live, but not waste resources.

### If timer is running
- Refresh approx every **1 minute**

### If timer is not running
- Refresh approx every **30 minutes**
- Also refresh immediately on state changes (via app trigger)

---

## 6) Widget UI Rules (Must Follow OneThing Ideology)

### What widgets must NOT do
- No task lists
- No multiple tasks
- No motivational quotes
- No scoring or streaks
- No complex UI

### Widget should feel like
- A calm “status card” for your single task

---

## 7) Empty / Edge State Handling

### No task set
Widget shows:
- “Set your one thing”

### Timer running but task empty (should not happen)
Widget shows:
- “Timer running” + elapsed
- App should prevent this state if possible

### Completed
Widget shows:
- Status “Done”
- Elapsed time stays visible (optional)

### Snapshot missing/corrupt
Widget shows:
- Safe placeholder state (not blank)
- Does not crash

---

## 8) QA Checklist (MVP Acceptance)
Widget work is complete when:

- [ ] Small widget shows task, status, elapsed correctly
- [ ] Medium widget shows same with better readability
- [ ] Lock screen widgets render properly (circular + rectangular)
- [ ] Widget updates after Start/Stop/Done/Reset
- [ ] Widget works after reboot without opening the app (snapshot persists)
- [ ] Running timer stays accurate (computed from startedAt)
- [ ] No excessive timeline updates (battery safe)
- [ ] Tapping widget opens Home screen

---

## 9) Must Needed
- Live Activity (Dynamic Island / Lock Screen timer controls)
- Widget buttons/actions
- CloudKit-driven widget state (too complex for MVP)
- Siri/Shortcuts automation

---

## 10) Must Upgrade Upgrade Path 
If users love widgets, next add:
- Live Activity for running timer on Lock Screen/Dynamic Island
- Optional widget deep links (tap status -> timer section)
- Optional “Start timer” intent (only if we want interactive wid

