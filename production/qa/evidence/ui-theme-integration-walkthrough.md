# UI Theme Integration Walkthrough — STORY-UT-007

**Story**: STORY-UT-007 — UI Theme Integration Verification
**Type**: Integration
**Date**: 2026-04-10
**Tester**: (pending — assign before marking Done)
**Status**: PARTIAL — automated ACs covered; manual ACs require device run

---

## AC1 — No Runtime Theme Mutation (AUTOMATED)

**Method**: `UIThemeIntegrationTest` in `tests/integration/ui_theme/ui_theme_integration_test.gd`

Tests:
- `test_no_theme_new_calls_in_src_scripts` — greps src/ for `Theme.new()`
- `test_no_inline_theme_property_assignments_in_src_scripts` — greps for `.theme = `

**Result**: Run `godot --headless --script tests/gdunit4_runner.gd` and confirm both pass.
Record pass/fail here when CI run completes.

| Check | Result |
|---|---|
| `Theme.new()` matches in src/ | _pending_ |
| `.theme = ` matches in src/ | _pending_ |

---

## AC2 — Theme Loads Without Warnings (AUTOMATED + ADVISORY)

**Method**: `UIThemeIntegrationTest`

Tests:
- `test_dark_olympus_theme_tres_exists_at_canonical_path`
- `test_dark_olympus_theme_tres_loads_as_theme_resource`

Canonical path: `assets/themes/dark_olympus_theme.tres`

**Headless limitation**: The headless runner cannot launch a full scene; "Theme: property not
found" warnings only appear during a real engine boot with a scene loaded. To verify AC2
fully, boot the game to the Splash screen in the editor and confirm the Output panel shows
no theme warnings.

| Check | Result |
|---|---|
| Resource exists at canonical path | _pending_ |
| Resource loads as Theme (not null) | _pending_ |
| Editor boot — no "Theme: property not found" warnings | _pending — manual_ |

---

## AC3 — Visual Walkthrough: No Default Godot Styling Visible (MANUAL)

**Gate level**: ADVISORY

Steps:
1. Boot game in Godot editor (Play Scene or Play Project).
2. Navigate to Hub screen.
3. Visit all four tabs (Companions, Chapter Map, Deck, Equipment or as implemented).
4. Confirm: all buttons, panels, and labels show the dark-brown / gold mythological palette.
5. Confirm: zero default Godot grey buttons, blue highlights, or white panels are visible.

| Screen | Palette Correct? | Notes |
|---|---|---|
| Hub — Tab 1 | _pending_ | |
| Hub — Tab 2 | _pending_ | |
| Hub — Tab 3 | _pending_ | |
| Hub — Tab 4 | _pending_ | |
| Splash | _pending_ | |

**Sign-off**: _______________________ Date: ___________

---

## AC4 — 60-Second Android Run: No Theme Errors (MANUAL)

**Gate level**: ADVISORY

Steps:
1. Export to Android debug APK.
2. Install and launch on target device.
3. Navigate Hub → Chapter Map → Dialogue for 60 seconds.
4. Pull logcat: `adb logcat | grep -i theme`
5. Confirm: zero theme-related error or warning lines.

| Check | Result |
|---|---|
| Logcat theme errors | _pending_ |
| Logcat theme warnings | _pending_ |

**Device tested**: _______________________ OS: ___________
**Sign-off**: _______________________ Date: ___________

---

## AC5 — Fade Duration Conflict: 200ms vs 300ms (OPEN — BLOCKING)

**Status**: OPEN — must resolve before ship.

**Conflict**:
- `SceneManager.FADE_DURATION = 0.3` seconds = **300ms** per half (fade-out + fade-in).
- ADR-0013 (UI Theme, TR-ui-theme-007) specifies the scene transition fade overlay
  as **200ms** out + **200ms** in.

**Impact**:
- If ADR-0013 governs: update `SceneManager.FADE_DURATION` to `0.2` and re-verify
  SN-002 AC5 timing (total ~0.45s instead of ~0.65s).
- If SceneManager governs: update ADR-0013 to document 300ms and close the conflict.

**Decision required from**: Technical Director / Gameplay Programmer

**Resolution** (fill in when decided):

> Decision: _________________________
> Date: ___________
> Implemented in: ___________________

The automated test `test_fade_duration_conflict_is_flagged_as_open` in
`UIThemeIntegrationTest` emits a `push_warning` until this is resolved, keeping it
visible in every CI run.

---

## Class Existence Checks (AUTOMATED)

Tests verify that the four GDScript token classes all compile and are instantiable:

| Class | File | Result |
|---|---|---|
| `UIConstants` | `src/systems/ui_constants.gd` | _pending_ |
| `UITypography` | `src/systems/ui_typography.gd` | _pending_ |
| `UIStyles` | `src/systems/ui_styles.gd` | _pending_ |
| `UILayout` | `src/systems/ui_layout.gd` | _pending_ |

---

## Test File

`tests/integration/ui_theme/ui_theme_integration_test.gd`

Run command:
```
godot --headless --script tests/gdunit4_runner.gd
```
