# Combat UI Layout Evidence — STORY-COMBAT-011

**Story**: STORY-COMBAT-011 — Combat UI Scene
**Type**: UI (Advisory gate)
**Date**: 2026-04-10
**Tester**: (assign before marking Done)
**Status**: PENDING — all ACs require manual verification in-editor / on-device

---

## Overview

This document is the test evidence for STORY-COMBAT-011. Because this is a UI
story, no automated tests are required. All acceptance criteria must be verified
manually by running the game in the Godot editor or on an Android/iOS device at
430×932 resolution and ticking each row below.

Scene under test: `src/scenes/combat/combat.tscn`
Controller script: `src/scenes/combat/combat.gd`

---

## AC1 — Layout Zones Present

**Method**: Open `combat.tscn` in the Godot editor. Select each panel node and
confirm its Rect position and size.

| Zone | Expected y-range | Node name | Result |
|---|---|---|---|
| EnemyInfoPanel | 0 – 120 px | `%EnemyInfoPanel` (or equivalent) | _pending_ |
| ScoringTray | 120 – 420 px | `%ScoringTray` | _pending_ |
| HandArea | 420 – 800 px | `%HandContainer` parent | _pending_ |
| ActionBar | 800 – 932 px | contains `%PlayBtn`, `%DiscardBtn` | _pending_ |

---

## AC2 — Card Minimum Touch Target

**Method**: Select any card Button node in the scene tree. In the Inspector
check `custom_minimum_size`.

| Check | Expected | Result |
|---|---|---|
| Card `custom_minimum_size.x` | >= 64 px | _pending_ |
| Card `custom_minimum_size.y` | >= 90 px | _pending_ |

The script sets `custom_minimum_size = Vector2(64, 90)` in `_create_card_button()`.
Confirm the scene does not override this to a smaller value.

---

## AC3 — PLAY / DISCARD Button Size

**Method**: Select `%PlayBtn` and `%DiscardBtn` in the scene tree and check their
minimum sizes (Inspector → Layout → Custom Minimum Size).

| Button | Expected min width | Expected min height | Result |
|---|---|---|---|
| `%PlayBtn` | >= 190 px | >= 56 px | _pending_ |
| `%DiscardBtn` | >= 190 px | >= 56 px | _pending_ |

---

## AC4 — Score Cascade Animation ≤ 2 Seconds

**Method**: Run the game. Play any hand. Start a stopwatch when the first chip
number appears in `%ChipsLabel` / `%MultLabel` and stop it when `%ScoreLabel`
and `%HpBar` settle. Total must be < 2 s.

The script caps each per-card step at `min(0.1, 2.0 / card_count)` seconds,
ensuring the cascade never exceeds 2 s regardless of hand size.

| Hand size | Observed cascade duration | Pass (< 2 s)? | Result |
|---|---|---|---|
| 1 card | _pending_ | _pending_ | _pending_ |
| 3 cards | _pending_ | _pending_ | _pending_ |
| 5 cards | _pending_ | _pending_ | _pending_ |

---

## AC5 — HP Bar 600ms Ease-Out Animation

**Method**: Run the game. Play a hand that reduces the enemy HP bar. Observe the
bar animation. It should ease from its current value to the new value over
approximately 0.6 seconds with a smooth deceleration (ease-out cubic).

The tween in `_tween_hp_bar()` uses:
- `Tween.EASE_OUT`
- `Tween.TRANS_CUBIC`
- Duration: `0.6` seconds

| Check | Expected | Result |
|---|---|---|
| Bar animates (not instant snap) | Yes | _pending_ |
| Duration approximately 0.6 s | Yes | _pending_ |
| Easing curve decelerates | Ease-out visible | _pending_ |
| Score text visible over HP bar | Yes | _pending_ |

---

## AC6 — Mobile Renderer / Particle Budget

**Method**: Run the game on Android or with Mobile renderer active in the editor.
Open the Godot Monitors panel and check GPU particle emitter counts during combat.

| Check | Limit | Result |
|---|---|---|
| Active GPU particle emitters | <= 4 simultaneously | _pending_ |
| Bloom/glow post-processing | None (disabled) | _pending_ |
| Animated shaders active | <= 2 simultaneously | _pending_ |

Note: The Mobile renderer does not support bloom natively. Confirm no
`WorldEnvironment` with glow enabled is attached to the combat scene.

---

## AC7 — Card Sort Toggle

**Method**: Run the game. Tap the sort button. Verify cards reorder without
losing any selection state or triggering a hand play/discard.

| Check | Expected | Result |
|---|---|---|
| Tap sort → cards reorder by Value (ascending) | Yes | _pending_ |
| Tap sort again → cards reorder by Suit (Hearts→Diamonds→Clubs→Spades, then Value) | Yes | _pending_ |
| Selected cards remain selected after sort | Yes | _pending_ |
| `hands_remaining` unchanged after sort | Yes | _pending_ |

---

## AC8 — Score Digits No Layout Shift

**Method**: Run the game. Play multiple hands until the score reaches 4+ digits.
Observe the `%ScoreLabel` and chip/mult labels during cascade animation. Digits
must not cause the label to resize and push other UI elements.

| Check | Expected | Result |
|---|---|---|
| Score label uses monospace or tabular font | Yes | _pending_ |
| No layout shift when score changes from 3→4 digits | No shift | _pending_ |
| No layout shift when score changes from 4→5 digits | No shift | _pending_ |

---

## AC9 — Element Icons Use Shape + Color

**Method**: Run the game. Inspect card buttons in HandArea and the enemy element
indicator in EnemyInfoPanel. Each element must be distinguishable by **both** a
shape/label and a color — color alone must not be the sole indicator.

The script encodes element icons as:
- Fire → `[F]` (red tint)
- Water → `[W]` (blue tint)
- Earth → `[E]` (green tint)
- Lightning → `[L]` (yellow tint)

| Element | Shape/label present | Color present | Result |
|---|---|---|---|
| Fire | `[F]` | Red (#F24D26 tint) | _pending_ |
| Water | `[W]` | Blue (#338CF2 tint) | _pending_ |
| Earth | `[E]` | Green (#73BF40 tint) | _pending_ |
| Lightning | `[L]` | Yellow (#CCaa33 tint) | _pending_ |

---

## Sign-off

| Role | Name | Date | Signature |
|---|---|---|---|
| Implementer | | | |
| Lead / Reviewer | | | |

Mark story Done only after all Advisory ACs above are ticked and sign-off is
recorded.
