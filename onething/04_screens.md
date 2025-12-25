# OneThing — Screens (MVP)

## 1) Home (Today)
**Purpose:** daily use. Must be enough on its own.

### Components
- Header: “Today” + date
- Task block:
  - Empty: input + Set
  - Filled: large text + tap to edit
- Timer block:
  - Big elapsed time
  - Start/Stop primary button
  - Reset (confirm / long-press)
  - Running indicator
- Completion:
  - Mark Done button
  - Completion timestamp after done
  - Undo toast (short-lived)
- Recent days preview (3–5 rows)

### Key states
- No task
- Task set, timer stopped
- Timer running
- Completed

---

## 2) History
**Purpose:** sanity check. Not analytics.

### UI
- List grouped by date
- Row: date + task + time + status
- Tap → Day Detail

Optional:
- Swipe to delete
- Copy task to today

---

## 3) Day Detail
**Purpose:** read-only record.

### UI
- Task
- Total time
- Completed at (or not done)
- Actions:
  - Copy to today
  - Delete
  - Edit (if not completed)

---

## 4) Settings
**Purpose:** tiny controls.

### Toggles
- Daily reset
- Retention (7/14/30)
- Haptics
Optional:
- Reminder notification
- Export today summary as text

---

## Post-MVP screens (later)
- Onboarding (single card)
- Live Activity / widgets configuration
