# OneThing — Theme UI/UX Spec (iOS-native)

## Visual direction
**Quiet, calm, system-native.**  
Avoid “gamer productivity” aesthetics.

### Style keywords
- Minimal
- Warm neutral
- Big type for the task + timer
- Subtle separators and spacing

## Typography
- Task text: `title2` / `title3` (Dynamic Type enabled)
- Timer: `largeTitle` (monospaced digits)
- Secondary labels: `footnote` / `caption`

**Checklist**
- [ ] Supports Dynamic Type up to XXL
- [ ] Uses monospaced digits for the timer
- [ ] Avoids fixed font sizes

## Color
- Use system colors (`.primary`, `.secondary`, `.tertiary`)
- Background: system grouped background
- One accent color only (optional)

**Checklist**
- [ ] High contrast in Light/Dark
- [ ] No hard-coded hex colors for text
- [ ] Reduced Transparency / Increased Contrast friendly

## Motion
- Micro animations only:
  - state transitions (start/stop/done)
  - subtle number change smoothing
- Respect Reduce Motion

**Checklist**
- [ ] No bouncy/flashy animations
- [ ] Animations <= 200–250ms

## Interaction & feedback
- Start/Stop: haptic (light)
- Done: haptic (success)
- Reset: destructive confirmation or long-press

**Checklist**
- [ ] Buttons are large, thumb-friendly
- [ ] Primary action is always obvious
- [ ] “Running” state is visible at a glance

## Layout rules (Home)
- Top: Today + date
- Middle: Task (hero)
- Timer (hero)
- Bottom: Done button + small history

**Spacing**
- Generous vertical padding
- Avoid dense UI

## Accessibility
- VoiceOver: timer reads “Task name, elapsed time”
- Buttons have clear labels (no icon-only actions in MVP)
- Tap targets >= 44pt

## Optional iOS-native enhancements (post-MVP)
- Live Activity for running timer
- Lock Screen widget
- Home Screen widget
