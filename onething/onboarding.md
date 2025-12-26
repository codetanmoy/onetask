# OneThing — Onboarding Design  
**Apple-Style Microcopy · Motion · SF Symbols**

This onboarding follows Apple’s design philosophy:
**clarity → restraint → continuity**.

SF Symbols are used to reinforce meaning **without adding visual noise**.

---

## 1) Onboarding Goals

- Communicate the rule instantly
- Reduce hesitation
- Let the user begin immediately
- Feel system-native, not promotional

---

## 2) Core Principles (Apple-aligned)

- Maximum **2 screens**
- No account, no permissions
- Skip always visible
- SF Symbols > custom illustrations
- Motion supports understanding, not delight

---

## 3) Entry Conditions

- Shown on first launch only
- Never auto-repeated

---

## 4) Screen 1 — The Rule

### Copy (Apple-style)

**Title**
> One task. One timer.

**Body**
> Finish one thing today.

Short. Declarative. Calm.

---

### SF Symbol (Primary Visual)

**Symbol**
- `checkmark.circle`

**Why**
- Universally understood
- Neutral, non-judgmental
- Signals completion without pressure

**Style**
- Weight: `.regular`
- Size: Large (hero scale)
- Color: `.secondary` (system color)
- No background shape

---

### Motion

**Symbol**
- Fade in (opacity 0 → 1)
- Slight scale (0.96 → 1.0)
- Duration: **200ms**
- Ease: `.easeOut`

**Text**
- Fade + vertical offset (y +12 → 0)
- Duration: **220ms**

---

### Actions

**Primary**
> Continue

**Secondary**
> Skip

---

### Transition to Screen 2

- Horizontal slide
- Content moves as a single plane
- Duration: **260ms**
- Ease: `.easeInOut`

---

## 5) Screen 2 — How It Works

### Copy (Apple-style)

**Title**
> That’s it.

**Steps**
> Pick one task  
> Start the timer  
> Mark it done

**Supporting line**
> No lists. No planning.

---

### SF Symbols (Per Step)

1. **Pick one task**
   - Symbol: `square.and.pencil`
   - Meaning: simple input, no structure

2. **Start the timer**
   - Symbol: `timer`
   - Meaning: time awareness, not pressure

3. **Mark it done**
   - Symbol: `checkmark`
   - Meaning: completion, closure

**Style**
- Weight: `.regular`
- Size: Medium
- Color: `.secondary`

---

### Motion (Step Reveal)

- Each step fades in sequentially
- Stagger: **80ms**
- Opacity + slight vertical movement
- No bounce

---

### Actions

**Primary**
> Start

**Secondary**
> Skip

---

### Transition to Home (Critical)

**Animation**
- Crossfade from onboarding to Home
- SF Symbols fade out as real UI fades in
- Duration: **300ms**
- Perfect visual alignment between preview and real UI

User perception:
> “I’m already using it.”

---

## 6) Landing on Home Screen

### Behavior

- Task input focused
- Keyboard visible
- No animation other than cursor blink
- No banners, no tooltips

Silence = confidence.

---

## 7) Global Motion Rules

- Max animation duration: **300ms**
- Opacity + position only
- Respect Reduce Motion
- No springs
- No decorative motion

---

## 8) SF Symbols Usage Rules (Very Important)

- Only use **system SF Symbols**
- No filled variants unless meaning requires it
- Avoid stacking symbols
- One symbol = one idea
- If text explains it well, remove the symbol

---

## 9) Accessibility

- SF Symbols scale with Dynamic Type
- VoiceOver reads text, not symbol names
- Tap targets ≥ 44pt
- Motion disabled when Reduce Motion is on

---

## 10) Definition of Done

Onboarding is complete when:
- User understands the rule instantly
- User reaches Home in under 15 seconds
- User starts typing without guidance
- Symbols feel obvious, not decorative

---

## Final Rule

> If a symbol needs explanation, it doesn’t belong.

