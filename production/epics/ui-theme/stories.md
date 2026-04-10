# Stories: UI Theme

> **Epic**: UI Theme
> **Layer**: Foundation
> **Governing ADRs**: ADR-0013
> **Manifest Version**: 2026-04-09

---

### STORY-UT-001: Theme .tres Skeleton + Font Resources

- **Type**: Config
- **TR-IDs**: TR-ui-theme-001, TR-ui-theme-003, TR-ui-theme-010
- **ADR Guidance**: ADR-0013 — Single Godot Theme .tres resource defines all visual tokens; loaded once at startup, never modified at runtime; Cinzel for display text (20-40px), Nunito Sans for body text (11-18px), both bundled as .tres FontFile resources
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN the project, WHEN `assets/` is inspected, THEN a single `dark_olympus_theme.tres` Theme resource exists at a documented canonical path
  - [ ] AC2: GIVEN `dark_olympus_theme.tres`, WHEN opened in Godot, THEN Cinzel font is present as a FontFile resource for display use (titles, headings)
  - [ ] AC3: GIVEN `dark_olympus_theme.tres`, WHEN opened in Godot, THEN Nunito Sans font is present as a FontFile resource for body use (labels, descriptions)
  - [ ] AC4: GIVEN a profiler measuring theme load at startup, WHEN the game launches, THEN the theme is fully loaded within 16.6ms (one frame at 60fps)
  - [ ] AC5: GIVEN any scene in `src/scenes/`, WHEN its root Control node is inspected, THEN it references `dark_olympus_theme.tres` (no scene defines its own theme override)
- **Test Evidence**: `production/qa/evidence/ui-theme-font-check.md`
- **Status**: Ready
- **Depends On**: None

---

### STORY-UT-002: Semantic Color Token Palette (20+ Tokens)

- **Type**: Config
- **TR-IDs**: TR-ui-theme-002, TR-ui-theme-011, TR-ui-theme-013
- **ADR Guidance**: ADR-0013 — 20+ named color tokens in "DarkOlympus" theme type; BG_PRIMARY, TEXT_PRIMARY, ACCENT_GOLD, element colors, and status colors; WCAG AA minimum 4.5:1 contrast for TEXT_PRIMARY on BG_PRIMARY; element colors provide pre-baked foreground/background variants
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN `dark_olympus_theme.tres`, WHEN the "DarkOlympus" custom type colors are listed, THEN at minimum these tokens exist: BG_PRIMARY, BG_SECONDARY, TEXT_PRIMARY, TEXT_SECONDARY, TEXT_DISABLED, ACCENT_GOLD, ACCENT_GOLD_DARK, STATUS_SUCCESS, STATUS_DANGER, STATUS_WARNING
  - [ ] AC2: GIVEN TEXT_PRIMARY and BG_PRIMARY color values, WHEN a WCAG contrast ratio is calculated, THEN the ratio is at least 4.5:1 (AA compliance)
  - [ ] AC3: GIVEN element colors (fire, water, earth, air, lightning), WHEN inspected, THEN each element has both a foreground (`ELEM_[NAME]_FG`) and background (`ELEM_[NAME]_BG`) variant token
  - [ ] AC4: GIVEN code in `src/` calling `get_theme_color()`, WHEN inspected, THEN it uses the `&"DarkOlympus"` type string (not a raw hex color)
  - [ ] AC5: GIVEN 20+ color tokens are defined, WHEN any scene script hardcodes a `Color(...)` literal for a UI element, THEN it is flagged as a standards violation in code review
- **Test Evidence**: `production/qa/evidence/ui-theme-contrast-check.md`
- **Status**: Ready
- **Depends On**: STORY-UT-001

---

### STORY-UT-003: Typography Scale (12 Font/Size Combinations)

- **Type**: Config
- **TR-IDs**: TR-ui-theme-003
- **ADR Guidance**: ADR-0013 — 12 font/size combinations; Cinzel for display at 20/24/32/40px; Nunito Sans for body at 11/13/15/18px and a set of intermediate sizes for labels and captions
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN `dark_olympus_theme.tres`, WHEN the font overrides for Label, Button, and RichTextLabel are listed, THEN Cinzel fonts are assigned at minimum 4 sizes (20px, 24px, 32px, 40px)
  - [ ] AC2: GIVEN `dark_olympus_theme.tres`, WHEN body font overrides are listed, THEN Nunito Sans fonts are assigned at minimum 4 sizes (11px, 13px, 15px, 18px)
  - [ ] AC3: GIVEN any scene script setting a Label font size directly (e.g., `label.add_theme_font_size_override()`), WHEN inspected, THEN it uses one of the 12 documented scale values (not an arbitrary size)
  - [ ] AC4: GIVEN `dark_olympus_theme.tres`, WHEN loaded, THEN all 12 font size combinations resolve without "missing font" errors in the output log
- **Test Evidence**: `production/qa/evidence/ui-theme-typography-check.md`
- **Status**: Ready
- **Depends On**: STORY-UT-001

---

### STORY-UT-004: Panel and Button StyleBoxes

- **Type**: Config
- **TR-IDs**: TR-ui-theme-001, TR-ui-theme-008, TR-ui-theme-012
- **ADR Guidance**: ADR-0013 — Standard panel: 1px gold border, 8px radius; Elevated panel: 2px gold border, 12px radius, shadow; Primary button: gold fill; Secondary button: gold border; Danger button: red border; Disabled button; button feedback: scale 0.97 + color shift within 1 frame; NO ripple effect
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN `dark_olympus_theme.tres`, WHEN StyleBox overrides for PanelContainer are listed, THEN a "standard" style exists with 1px gold border and 8px corner radius
  - [ ] AC2: GIVEN `dark_olympus_theme.tres`, WHEN StyleBox overrides for PanelContainer are listed, THEN an "elevated" style exists with 2px gold border and 12px corner radius
  - [ ] AC3: GIVEN `dark_olympus_theme.tres`, WHEN Button StyleBox overrides are listed, THEN distinct styles exist for: normal (gold fill), hover (same as normal — touch device, no hover state needed), pressed (scale 0.97 + darkened color), disabled
  - [ ] AC4: GIVEN a Button press event in a test scene, WHEN it fires, THEN the visual feedback (scale 0.97 + color shift) occurs within 1 frame (16ms) of the press
  - [ ] AC5: GIVEN any Button implementation in the project, WHEN inspected for ripple effect nodes or ripple animation code, THEN zero matches are found (ripple is forbidden per ADR-0013)
- **Test Evidence**: `production/qa/evidence/ui-theme-styleboxes-check.md`
- **Status**: Ready
- **Depends On**: STORY-UT-002

---

### STORY-UT-005: Touch Target Enforcement + Thumb Zone Layout

- **Type**: UI
- **TR-IDs**: TR-ui-theme-004, TR-ui-theme-005, TR-ui-theme-006
- **ADR Guidance**: ADR-0013 — Minimum 44x44px hitbox for all interactive elements; primary buttons 52px minimum height; list rows 64px minimum height; primary actions in bottom 560px of 430x932 viewport; safe area via `DisplayServer.get_display_safe_area()`
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN any interactive Control node (Button, TextureButton, LinkButton) in any scene, WHEN its minimum size is inspected, THEN height and width are both at least 44px
  - [ ] AC2: GIVEN primary action buttons (New Game, Continue, primary CTA buttons), WHEN their minimum height is inspected, THEN it is at least 52px
  - [ ] AC3: GIVEN list row containers (companion list items, deck list rows), WHEN their minimum height is inspected, THEN it is at least 64px
  - [ ] AC4: GIVEN `DisplayServer.get_display_safe_area()` is available, WHEN any scene with a top or bottom bar is checked, THEN it applies the safe area insets to avoid the notch and home indicator
  - [ ] AC5: GIVEN the 430x932 viewport layout, WHEN the primary action buttons' vertical position is measured from the bottom, THEN all primary CTAs are positioned within the bottom 560px (thumb zone)
- **Test Evidence**: `production/qa/evidence/ui-theme-touch-targets-walkthrough.md`
- **Status**: Ready
- **Depends On**: STORY-UT-004

---

### STORY-UT-006: Haptic Feedback System

- **Type**: Logic
- **TR-IDs**: TR-ui-theme-009
- **ADR Guidance**: ADR-0013 — Three haptic levels: light 15ms, medium 30ms, heavy 50ms; graceful degradation on platforms that do not support haptics (no crash, no error)
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN a HapticManager utility (static class or autoload), WHEN `HapticManager.light()` is called, THEN a 15ms haptic vibration is triggered on supported platforms
  - [ ] AC2: GIVEN `HapticManager.medium()` is called, WHEN it runs, THEN a 30ms haptic vibration is triggered on supported platforms
  - [ ] AC3: GIVEN `HapticManager.heavy()` is called, WHEN it runs, THEN a 50ms haptic vibration is triggered on supported platforms
  - [ ] AC4: GIVEN the game runs on a Web (HTML5) export where haptics are unsupported, WHEN any haptic method is called, THEN no error or crash occurs (graceful degradation)
  - [ ] AC5: GIVEN any primary button press in the game, WHEN it registers a tap, THEN `HapticManager.light()` is called (consistent haptic feedback on all primary interactions)
- **Test Evidence**: `tests/unit/ui_theme/haptic_manager_test.gd`
- **Status**: Ready
- **Depends On**: None

---

### STORY-UT-007: UI Theme Integration Verification

- **Type**: Integration
- **TR-IDs**: TR-ui-theme-001, TR-ui-theme-002, TR-ui-theme-003, TR-ui-theme-004, TR-ui-theme-005, TR-ui-theme-006, TR-ui-theme-007, TR-ui-theme-008, TR-ui-theme-009, TR-ui-theme-010, TR-ui-theme-011, TR-ui-theme-012, TR-ui-theme-013
- **ADR Guidance**: ADR-0013 — Theme is loaded once at startup; all Control nodes inherit from the shared theme; no runtime modifications to the theme resource
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN a grep of `src/` for `theme = new Theme()` or inline theme property assignments, WHEN run, THEN zero matches are found in scene scripts (no runtime theme mutation)
  - [ ] AC2: GIVEN the Splash screen runs in a headless test, WHEN it loads, THEN no "Theme: property not found" warnings appear in the output log
  - [ ] AC3: GIVEN a visual walkthrough of the Hub screen (manual), WHEN all four tabs are visited, THEN all buttons, panels, and labels visually match the dark-brown mythological palette (no default Godot grey/blue controls visible)
  - [ ] AC4: GIVEN the game launched on Android, WHEN the display runs for 60 seconds across Hub, Chapter Map, and Dialogue scenes, THEN no theme-related error logs appear
  - [ ] AC5: GIVEN a scene transition fade (TR-ui-theme-007), WHEN timed, THEN the fade overlay is 200ms out and 200ms in (matching the ADR-0013 value, separate from SceneManager's 300ms — note: confirm which value governs and resolve any conflict before implementation)
- **Test Evidence**: `production/qa/evidence/ui-theme-integration-walkthrough.md`
- **Status**: Ready
- **Depends On**: STORY-UT-002, STORY-UT-003, STORY-UT-004, STORY-UT-005, STORY-UT-006
