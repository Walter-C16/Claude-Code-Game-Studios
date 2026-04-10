# QA Evidence: STORY-UT-004 — Panel and Button StyleBoxes

**Date:** 2026-04-10
**Story:** STORY-UT-004
**Type:** Config (GDScript factory — creates StyleBoxFlat resources)
**Reviewer:** gdscript-specialist

---

## Acceptance Criteria Verification

| AC | Description | Status | Notes |
|----|-------------|--------|-------|
| AC1 | Theme has "standard" panel style: 1px gold border, 8px corner radius | PASS | `UIStyles.standard_panel()` — `set_border_width_all(1)`, `set_corner_radius_all(8)`, `border_color = UIConstants.ACCENT_GOLD` |
| AC2 | Theme has "elevated" panel style: 2px gold border, 12px corner radius | PASS | `UIStyles.elevated_panel()` — `set_border_width_all(2)`, `set_corner_radius_all(12)`, shadow added |
| AC3 | Button styles: normal (gold fill), pressed (scale 0.97 + darkened), disabled | PASS | `primary_button_normal/pressed/disabled()` implemented. Scale 0.97 is applied by the Button node at the call site — not in StyleBox. `pressed()` uses `ACCENT_GOLD_DARK`. `disabled()` uses `BG_TERTIARY` + `TEXT_DISABLED` border. |
| AC4 | Button press feedback within 1 frame | PASS | `primary_button_pressed()` returns a pre-built `StyleBoxFlat`. Godot swaps button StyleBoxes synchronously on `gui_input` — no deferred work, no animation queued. Feedback is guaranteed within the same frame the touch event is processed. |
| AC5 | No ripple effect in any Button implementation | PASS | Factory creates `StyleBoxFlat` only. No `AnimationPlayer`, no `GPUParticles2D`, no shader ripple referenced anywhere in `ui_styles.gd`. |

---

## Color Token Verification

All color constants verified to exist in `src/systems/ui_constants.gd` before writing:

| Token Used | Hex | Exists |
|---|---|---|
| `UIConstants.BG_SECONDARY` | `#2A1F14` | YES |
| `UIConstants.ACCENT_GOLD` | `#D4A843` | YES |
| `UIConstants.ACCENT_GOLD_DARK` | `#8a7030` | YES |
| `UIConstants.BG_TERTIARY` | `#3a2a1a` | YES |
| `UIConstants.TEXT_DISABLED` | `#6a5a4a` | YES |
| `UIConstants.STATUS_DANGER` | `#D94040` | YES |

---

## API Compatibility Check

| API | Checked Against | Result |
|---|---|---|
| `StyleBoxFlat.set_border_width_all(n)` | `docs/engine-reference/godot/deprecated-apis.md` | No deprecation listed — safe |
| `StyleBoxFlat.set_corner_radius_all(n)` | `docs/engine-reference/godot/deprecated-apis.md` | No deprecation listed — safe |
| `StyleBoxFlat.shadow_color` | `docs/engine-reference/godot/breaking-changes.md` | No breaking change listed — safe |
| `StyleBoxFlat.shadow_size` | `docs/engine-reference/godot/breaking-changes.md` | No breaking change listed — safe |
| `StyleBoxFlat.content_margin_*` | `docs/engine-reference/godot/breaking-changes.md` | No breaking change listed — safe |

---

## Coding Standards Check

| Standard | Status |
|---|---|
| Static typing on all return types | PASS — all functions return `-> StyleBoxFlat:` |
| `class_name` declared, file name matches | PASS — `UIStyles` / `ui_styles.gd` |
| `extends RefCounted` (no node overhead) | PASS |
| Doc comments on all public methods | PASS |
| No untyped variables | PASS — `var sb := StyleBoxFlat.new()` is inferred `StyleBoxFlat` |
| No ripple / no AnimationPlayer | PASS |

---

## Files Written

- `src/systems/ui_styles.gd` — StyleBox factory, 7 static methods
