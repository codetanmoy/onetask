# OneThing — Product Logic (MVP)

## 1) Daily entry logic
- The app maintains exactly **one DayEntry per day**.
- On launch (and when app becomes active):
  - normalize `today = startOfDay(now)`
  - fetch entry for `today`
  - if missing: create it

## 2) Task setting
- Task can be set anytime before completion.
- Editing task:
  - allowed even when timer running (MVP ok)
  - does not reset timer

## 3) Timer logic
### Start
- If `startedAt == nil`:
  - set `startedAt = now`
  - save

### Stop
- If `startedAt != nil`:
  - compute delta = now - startedAt
  - set `elapsedSeconds += delta`
  - set `startedAt = nil`
  - save

### Reset
- Always requires confirmation OR long-press.
- On reset:
  - `elapsedSeconds = 0`
  - `startedAt = nil`
  - save

### Display elapsed
- `totalElapsed = elapsedSeconds + (startedAt != nil ? now - startedAt : 0)`

## 4) Completion
### Mark done
- If timer running: stop first (auto-stop)
- Set `completedAt = now`
- Lock edits by default

### Undo
- Allow undo for a short window (e.g., 5–10 seconds)
- Undo clears `completedAt`

## 5) History retention
- Keep last N days (7/14/30).
- On app launch / daily rollover:
  - delete entries older than retention window

## 6) Daily reset
Two modes:
- **Enabled**: new day means a fresh blank task + timer
- **Disabled**: user can keep task until they change it (still one entry per day)

Recommended MVP:
- Enabled by default (simple mental model)

## 7) Edge cases
- App killed while running:
  - restore from `startedAt`
- Day changes while timer running:
  - stop timer and attribute to the day it started (recommended)
- Timezone change:
  - keep existing `day` stored as start-of-day at time of creation
  - do not re-key old entries automatically (prevents weird shifts)

## 8) Optional (post-MVP)
- Live Activity for running timer
- Widget showing today task + time
