# OneTask: Psychology-First Implementation Guide

## Table of Contents
1. [Core Philosophy](#core-philosophy)
2. [The Dopamine Loop Architecture](#the-dopamine-loop-architecture)
3. [Psychological Hooks & Implementation](#psychological-hooks--implementation)
4. [Feature Roadmap](#feature-roadmap)
5. [Technical Implementation Details](#technical-implementation-details)
6. [Retention Mechanics](#retention-mechanics)
7. [Onboarding Flow](#onboarding-flow)
8. [Notification Strategy](#notification-strategy)
9. [Monetization Psychology](#monetization-psychology)
10. [Success Metrics](#success-metrics)

---

## Core Philosophy

### The One Principle
**"One task, one timer, one focus. Nothing else."**

### Target Audience
- **Primary:** ADHD brains (16M+ adults in US)
- **Secondary:** Anyone overwhelmed by traditional to-do apps
- **Tertiary:** Deep work practitioners, students, developers

### The Problem We're Solving
```
Traditional to-do apps:
47 tasks → Analysis paralysis → Nothing gets done

OneTask:
1 task → Clear focus → Task completed → Dopamine hit → Repeat
```

### Core Psychology Principles
1. **Simplicity reduces cognitive load** (fewer decisions = less paralysis)
2. **Constraints create clarity** (one task = obvious next step)
3. **Progress visibility drives motivation** (streaks, stats)
4. **Loss aversion > gain seeking** (don't break streak)
5. **Immediate rewards form habits** (dopamine on completion)

---

## The Dopamine Loop Architecture

### The Complete Loop

```
CUE (What triggers opening the app)
    ↓
CRAVING (What they want)
    ↓
RESPONSE (What they do)
    ↓
REWARD (What they get)
    ↓
[Loop repeats]
```

### OneTask's Implementation

#### 1. CUE (Triggers to Open)
```swift
// Multiple cues working together

// Widget on Home Screen
Widget shows:
- Current task (if active)
- "0/1 tasks today" (creates tension)
- Streak count (reminds them of investment)

// Live Activity (iOS 16+)
Shows timer running on Dynamic Island
Visual reminder that task is in progress

// Smart Notifications
- Morning: "What's your ONE task today?" (8-9am)
- Midday: "How's your focus going?" (if task active for 2+ hours)
- Evening: "Mark today's task complete?" (if task incomplete at 7pm)

// Lock Screen Widget
Shows:
- Today's task
- Current streak
- Timer if running
```

**Implementation Priority:**
```
Phase 1 (Launch):
✅ Home screen widget (basic)
✅ One daily notification

Phase 2 (Week 2):
✅ Live Activity
✅ Smart notification timing

Phase 3 (Month 1):
✅ Lock screen widget
✅ Advanced notification logic
```

#### 2. CRAVING (What They Want)

**Psychological Needs:**
- **Clarity:** "I know exactly what to do right now"
- **Progress:** "I want to see my streak grow"
- **Relief:** "I want to feel accomplished"
- **Identity:** "I want to be a focused person"

**UI Implementation:**
```swift
// The craving is built into the visual design

Main Screen (when task incomplete):
- Empty checkbox (creates tension)
- "0 min focused today" (gap to fill)
- Streak at risk: "Don't break 14 days" (loss aversion)

Main Screen (during focus):
- Timer running (satisfying to watch)
- Progress visible (time accumulating)
- Pause option (control)

Main Screen (task complete):
- Checked box (closure)
- "23 min focused" (achievement)
- Streak incremented "+1" (growth)
```

#### 3. RESPONSE (What They Do)

**The Actions:**
1. Open app (cue triggers this)
2. See today's task OR set new task
3. Tap "Start Focus"
4. Work on task (app in background via Live Activity)
5. Return to app
6. Tap "Complete"

**Critical: Minimize Friction**
```swift
// Every unnecessary tap = 20% drop-off

BAD FLOW (7 taps):
Open app → Tap "New Task" → Type task → Tap "Save" → 
Tap "Start Timer" → Tap "Set Duration" → Choose time → Start

GOOD FLOW (2 taps):
Open app → Type task → Tap "Start" (timer auto-starts)

BEST FLOW (1 tap):
Open app (yesterday's task still there) → Tap "Start"
```

**Implementation:**
```swift
// Intelligent task persistence

If last task was completed:
- Show "What's next?" with empty input
- Keyboard auto-focuses

If last task incomplete:
- Show yesterday's task pre-filled
- User can edit or just tap "Start"
- No need to retype if continuing same work

If user has active streak:
- Suggest similar tasks (AI/pattern based)
- "Yesterday: Write blog post"
- "Today: Write blog post?" [Start] [Change]
```

#### 4. REWARD (What They Get)

**Immediate Rewards (0-3 seconds):**
```swift
// On task completion

Visual:
- Checkmark animation (satisfying)
- Confetti (subtle, not annoying)
- Task fades out (closure)

Haptic:
- Success haptic (iOS standard)
- Feels tactile and real

Audio (optional):
- Subtle "ding" (user preference)
- Not intrusive

Data:
- Streak increments: "15 → 16 days" 
- Time adds up: "+23 min focused today"
- Stats update: "67 tasks this month"
```

**Delayed Rewards (shown immediately after):**
```swift
// Celebration Screen (2 seconds, then auto-dismiss)

Today:
✅ 1 task completed
⏱️ 23 minutes focused

Streak: 16 days 🔥

[Continue to tomorrow's task →]

// No buttons except continue
// No friction
// Just reinforcement
```

**Long-term Rewards (weekly/monthly):**
```swift
// Insights Screen (accessible, not forced)

This Week:
- 6/7 days active
- 5 tasks completed  
- 2.3 hours focused
- Best day: Tuesday (47 min)

This Month:
- 23 days active
- 67 tasks completed
- 18.4 hours focused
- Longest streak: 16 days

Patterns:
"You focus best at 9-11am"
"Tuesday is your most productive day"
"Tasks with clear verbs get done 2x faster"
```

---

## Psychological Hooks & Implementation

### Hook 1: Streak Tracking (Loss Aversion)

**Psychology:**
- Losing a streak hurts 2x more than gaining one feels good
- Creates daily commitment
- Investment grows over time

**Implementation:**
```swift
// Core Streak Logic

struct Streak {
    var currentDays: Int
    var longestEver: Int
    var lastCompletedDate: Date
    var isAtRisk: Bool {
        // If didn't complete yesterday, streak at risk
        Calendar.current.isDateInYesterday(lastCompletedDate) == false
    }
}

// Visual Display

Main Screen (prominent):
🔥 16 day streak

If at risk:
⚠️ 16 day streak at risk
"Don't break it today"

If maintained:
✅ 17 day streak  
"New record!"

// Streak Recovery (Premium Feature)

If user breaks streak:
"Your 16-day streak ended 😔

But your progress isn't lost:
- 67 tasks completed
- 18 hours focused  
- You did this once, you can do it again

[Start new streak]
[Unlock Streak Freeze] ← Premium
```

**Streak Freeze (Premium):**
```swift
// User can "freeze" streak 1 day/month

Use cases:
- Sick day
- Travel
- Life happens

Psychology:
- Reduces anxiety (safety net)
- Prevents full loss aversion backfire
- Keeps user engaged long-term

Cost: 1 freeze per month (Premium only)
```

### Hook 2: Progress Dashboard (Achievement)

**Psychology:**
- Humans love seeing progress
- Numbers going up = dopamine
- "Sunk cost" keeps them engaged

**Implementation:**
```swift
// Stats Screen (accessible but not intrusive)

Today:
• 1 task completed ✅
• 23 min focused ⏱️

This Week:
• 6/7 active days 📊
• 18 tasks done ✅
• 4.2 hours focused ⏱️
• Current streak: 16 🔥

All Time:
• 234 tasks completed
• 87 hours total focus
• Longest streak: 23 days
• Member since: [date]

You're in the top 12% of users 🏆

// Gamification (subtle)

Achievements (unlocked naturally):
🥉 First Task - Complete 1 task
🥈 Momentum - 7 day streak
🥇 Focused - 10 hours total
💎 Dedicated - 30 day streak
🚀 Unstoppable - 100 tasks
```

### Hook 3: Daily Check-in (Habit Formation)

**Psychology:**
- Creates ritual
- Bookends the day
- Builds routine

**Implementation:**
```swift
// Morning Prompt (8-9am notification)

Notification:
"Good morning! What's your ONE task today?"

Opens to:
[Text input ready]
"Today's focus:"
_________________

Suggestions based on history:
- "Write" (you do this often)
- "Code" (Tuesday pattern)
- "Review" (common task)

[Start when ready]

// Evening Check-in (7-8pm if task incomplete)

Notification:
"Did you complete your task today?"

Opens to:
Your task: "Write blog post"
Timer: 47 min elapsed

[Mark Complete] [Continue Tomorrow]

If complete:
"Great work! Tomorrow's task?"

If incomplete:
"No problem. Try again tomorrow?"
[Keep for tomorrow] [New task]
```

### Hook 4: Smart Defaults (Reduce Friction)

**Psychology:**
- Default option = most chosen (90%+ take default)
- Removing decisions = removing fatigue
- Automatic behavior = habit formation

**Implementation:**
```swift
// Intelligent Defaults

Timer Duration:
- Default: No duration (open-ended)
- User can set if desired
- Most ADHD users prefer "until done" over arbitrary time

Task Input:
- Auto-capitalizes first letter
- Suggests verbs: "Write," "Code," "Read," "Review"
- Character limit: 50 (forces clarity)

Task Persistence:
- If incomplete, auto-carries to tomorrow
- User can edit or keep as-is
- No "failed task" shaming

Notifications:
- Default: Morning check-in only
- User can enable more
- Never more than 3/day max

Theme:
- Default: System (light/dark auto)
- ADHD-friendly: High contrast, clear typography
- No distracting colors
```

### Hook 5: Micro-Celebrations (Positive Reinforcement)

**Psychology:**
- Small wins = dopamine spikes
- Positive reinforcement > punishment
- Celebration = motivation to continue

**Implementation:**
```swift
// Milestone Celebrations (appear organically)

First task completed:
"🎉 You did it! Your first task."

7-day streak:
"🔥 7 days! You're building momentum."

10 tasks completed:
"⭐ 10 tasks done! You're on fire."

50 tasks completed:
"🚀 50 tasks! This is becoming a habit."

30-day streak:
"💎 30 days! You're in the top 5% of users."

// Format:
- Full screen (can't miss)
- 2 seconds
- Auto-dismisses
- No action required
- Just celebration
```

### Hook 6: Social Proof (Belonging)

**Psychology:**
- Humans are tribal
- "Others like me do this" = motivation
- Comparison drives behavior

**Implementation (Subtle, Optional):**
```swift
// Stats Screen (bottom section)

Community:
• 47,234 tasks completed today by OneTask users
• You're in the top 12% for consistency
• 2,341 people on 30+ day streaks

// Premium Feature: Focus Sessions (Opt-in)

"Join Focus Session"
- 23 people focusing right now
- Average session: 31 minutes
- Join quietly (anonymous)
- Leave when done

Psychology:
- Accountability (others are working too)
- Not alone (community feeling)
- No pressure (anonymous)

// Privacy-first:
- No usernames visible
- No forced social features
- Opt-in only
```

---

## Feature Roadmap

### Phase 1: MVP (Launch - Week 0)

**Must-Have (Core Loop):**
```
✅ Task Input (one text field)
✅ Start Focus Button
✅ Timer (counts up, no duration required)
✅ Complete Task Button
✅ Streak Counter (basic)
✅ Today's Stats (tasks done, time focused)
✅ Basic Widget (shows current task)
✅ One Notification (morning check-in)
✅ History (last 7 days)
```

**Design Principles:**
- 3 screens max: Main, Stats, Settings
- No tutorial (app is self-explanatory)
- Launch in 2-3 weeks

### Phase 2: Retention Hooks (Week 1-4)

**Add:**
```
✅ Live Activity (Dynamic Island)
✅ Advanced Streak Tracking
✅ Weekly/Monthly Stats
✅ Achievement Badges (subtle)
✅ Smart Notifications (time-based)
✅ Task Suggestions (based on history)
✅ Streak Freeze (premium)
✅ Themes (light/dark/high contrast)
```

### Phase 3: Premium Features (Month 2-3)

**OneTask Pro ($2.99/month or $19.99/year):**
```
✅ Unlimited History (free = 7 days)
✅ Advanced Insights
  - Best focus times
  - Productivity patterns
  - Task completion rates
✅ Streak Freeze (1/month)
✅ Focus Session (anonymous co-working)
✅ Custom Themes
✅ Export Data (CSV)
✅ Multiple Devices Sync (iCloud)
✅ Priority Support
```