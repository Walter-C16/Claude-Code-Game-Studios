# Interaction Pattern Library: Dark Olympus

> **Status**: Initialized
> **Last Updated**: 2026-04-10
> **Platform**: Portrait mobile (430x932), touch-only
> **Source**: UI Theme GDD (design/gdd/ui-theme.md) + ADR-0013

---

## Core Interaction Patterns

### 1. Tap (Primary Action)

- **Use for**: Buttons, cards, companions, menu items, dialogue advance
- **Feedback**: Scale 0.97 + color shift within 1 frame (16ms)
- **Touch target**: Minimum 44x44px; primary buttons 52px height
- **Haptic**: Light 15ms on tap

### 2. Long Press (Inspect / Tooltip)

- **Use for**: Card details, blessing tooltips, companion info
- **Trigger**: 500ms hold threshold
- **Feedback**: Tooltip overlay appears; game pauses during combat tooltips
- **Cancel**: Lift finger to dismiss

### 3. Swipe Down (Dismiss Modal)

- **Use for**: Bottom sheet dismissal (gift picker, settings panels)
- **Threshold**: 40% of sheet height dragged down
- **Animation**: Spring-back if below threshold; slide-to-dismiss if above
- **Duration**: 250ms ease-out

### 4. Tab Bar Switch (Hub Navigation)

- **Use for**: Hub sub-tabs (Story, Combat, Camp, Profile)
- **Pattern**: Keep-alive hide/show; no scene transition
- **Feedback**: Active tab highlighted; content swap < 1 frame
- **Constraint**: No swipe-between-tabs (prevents accidental navigation)

### 5. Card Selection (Combat Hand)

- **Use for**: Selecting cards to play or discard in poker combat
- **Pattern**: Tap to select (card raises); tap again to deselect
- **Multi-select**: Up to 5 cards simultaneously
- **Feedback**: Selected cards visually elevated + border glow

### 6. Screen Transition (Navigation)

- **Use for**: All full-scene changes via SceneManager
- **Pattern**: Fade through black (0.3s out + 0.3s in)
- **Input blocking**: MOUSE_FILTER_STOP on overlay during transition
- **Guard**: Duplicate change_scene() calls silently dropped

---

## Thumb Zone Layout

```
+------------------+
|   Status Bar     |  0-60px    (system, avoid)
|   Display Zone   |  60-372px  (read-only info)
|   Neutral Zone   |  372-560px (secondary actions)
|   Primary Zone   |  560-872px (main interactions)
|   Safe Area      |  872-932px (gesture bar, avoid)
+------------------+
```

All primary actions (PLAY, DISCARD, Talk, Gift, Date, Confirm) in bottom 372px.

---

## Anti-Patterns (Forbidden)

- No hover interactions (touch-only)
- No swipe-to-navigate between major screens (accidental trigger risk)
- No double-tap requirements (accessibility barrier)
- No drag-and-drop for gameplay actions (imprecise on mobile)
- No pinch-to-zoom (single viewport, no map)
- No landscape orientation support

---

## Pattern Usage by Screen

| Screen | Primary Patterns | Notes |
|--------|-----------------|-------|
| Poker Combat | Tap (cards), Long Press (inspect), Tab Bar (n/a) | Card selection is multi-tap |
| Dialogue | Tap (advance/choose) | Choice panel slide-in 0.25s |
| Camp | Tap (companion/action), Swipe Down (gift picker) | Gift picker is bottom sheet |
| Chapter Map | Tap (node select) | Completed nodes non-tappable |
| Hub | Tab Bar (sub-tabs) | Keep-alive, no transitions |
| Deck Viewer | Tap (captain select/confirm) | Read-only card grid |
| Settings | Tap (controls), Swipe Down (dismiss overlay) | CanvasLayer overlay |
| Splash | Tap (Continue/New Game) | Conditional on has_save() |
