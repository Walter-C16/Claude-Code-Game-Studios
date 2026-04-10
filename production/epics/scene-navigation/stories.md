# Stories: Scene Navigation

> **Epic**: Scene Navigation
> **Layer**: Foundation
> **Governing ADRs**: ADR-0003, ADR-0006
> **Manifest Version**: 2026-04-09

---

### STORY-SN-001: SceneId Enum + Scene Path Registry

- **Type**: Config
- **TR-IDs**: TR-scene-nav-001, TR-scene-nav-009
- **ADR Guidance**: ADR-0003 — SceneId enum maps all 16+ screens to res:// paths in a SCENE_PATHS Dictionary; adding a new screen requires only a new enum value + path entry; raw .tscn path strings are forbidden outside scene_manager.gd
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN `scene_manager.gd`, WHEN inspected, THEN an `enum SceneId` exists containing at minimum: SPLASH, DIALOGUE, COMBAT, HUB, CHAPTER_MAP, COMPANION_ROOM, DATE, INTIMACY, DECK, DECK_VIEWER, EQUIPMENT, EXPLORATION, ABYSS, GALLERY, ACHIEVEMENTS, SETTINGS
  - [ ] AC2: GIVEN `scene_manager.gd`, WHEN inspected, THEN a `const SCENE_PATHS: Dictionary` maps each non-SETTINGS SceneId to a `res://src/scenes/...` path string
  - [ ] AC3: GIVEN a grep of `src/` excluding `scene_manager.gd`, WHEN run for `change_scene_to_file`, THEN the result is zero matches
  - [ ] AC4: GIVEN a grep of `src/` excluding `scene_manager.gd`, WHEN run for raw `.tscn` path strings in scene-switch contexts, THEN the result is zero matches in any autoload or scene script
- **Test Evidence**: `production/qa/evidence/scene-nav-enum-check.md`
- **Status**: Ready
- **Depends On**: None

---

### STORY-SN-002: Fade Transition Implementation

- **Type**: Logic
- **TR-IDs**: TR-scene-nav-010, TR-scene-nav-012, TR-scene-nav-007
- **ADR Guidance**: ADR-0003 — Fade transition uses a ColorRect on CanvasLayer 100 parented to SceneManager; 0.3s fade-out then scene swap then 0.3s fade-in; `transition_started` signal emits before fade-out; `scene_changed` signal emits after fade-in; TransitionType.INSTANT and TransitionType.NONE are also supported
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN SceneManager's `_ready()`, WHEN it runs, THEN a CanvasLayer at layer 100 is created as a child with a ColorRect covering the full viewport
  - [ ] AC2: GIVEN `change_scene(SceneId.HUB, TransitionType.FADE)` is called, WHEN the transition runs, THEN `transition_started` signal emits before the fade-out tween begins
  - [ ] AC3: GIVEN the FADE transition, WHEN the full transition completes (both tweens), THEN `scene_changed(scene_id)` signal emits with the correct SceneId
  - [ ] AC4: GIVEN `TransitionType.INSTANT`, WHEN `change_scene()` is called, THEN the scene swaps in 1 frame with no tween animation
  - [ ] AC5: GIVEN a FADE transition completing, WHEN timed on a test device, THEN total elapsed time is approximately 0.65s (0.3s out + scene load + 0.3s in) and stays above 30fps
- **Test Evidence**: `tests/unit/scene_navigation/fade_transition_test.gd`
- **Status**: Ready
- **Depends On**: STORY-SN-001

---

### STORY-SN-003: Transition State Machine + Double-Tap Guard

- **Type**: Logic
- **TR-IDs**: TR-scene-nav-004, TR-scene-nav-007
- **ADR Guidance**: ADR-0003 — State machine: IDLE → FADING_OUT → LOADING → FADING_IN → IDLE; `change_scene()` calls while NOT in IDLE are silently dropped; `is_transitioning()` returns true in any non-IDLE state
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN SceneManager is in IDLE state, WHEN `change_scene()` is called, THEN state transitions to FADING_OUT immediately
  - [ ] AC2: GIVEN SceneManager is in FADING_OUT state, WHEN a second `change_scene()` call arrives, THEN it is silently dropped (no error, no double transition)
  - [ ] AC3: GIVEN two `change_scene()` calls in the same frame, WHEN the frame processes, THEN only the first transition executes
  - [ ] AC4: GIVEN SceneManager is in FADING_IN state, WHEN `is_transitioning()` is called, THEN it returns `true`
  - [ ] AC5: GIVEN the transition completes fully, WHEN `is_transitioning()` is called after `scene_changed` emits, THEN it returns `false`
- **Test Evidence**: `tests/unit/scene_navigation/transition_guard_test.gd`
- **Status**: Ready
- **Depends On**: STORY-SN-002

---

### STORY-SN-004: Input Blocking During Transitions

- **Type**: Logic
- **TR-IDs**: TR-scene-nav-005
- **ADR Guidance**: ADR-0003 — Transition overlay ColorRect sets `mouse_filter = MOUSE_FILTER_STOP` during FADING_OUT/LOADING/FADING_IN; restored to `MOUSE_FILTER_IGNORE` after FADING_IN completes; verify under Godot 4.6 dual-focus system
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN a FADE transition is active (state is FADING_OUT), WHEN the overlay ColorRect's `mouse_filter` property is read, THEN it equals `Control.MOUSE_FILTER_STOP`
  - [ ] AC2: GIVEN a FADE transition completes (state returns to IDLE), WHEN the overlay ColorRect's `mouse_filter` property is read, THEN it equals `Control.MOUSE_FILTER_IGNORE`
  - [ ] AC3: GIVEN an active transition, WHEN a simulated touch input event is dispatched to the scene below the overlay, THEN the underlying scene's `_input()` handler does not fire
  - [ ] AC4: GIVEN `TransitionType.INSTANT` (no tween), WHEN the swap completes, THEN overlay `mouse_filter` is restored to `MOUSE_FILTER_IGNORE` within the same frame
- **Test Evidence**: `tests/unit/scene_navigation/input_blocking_test.gd`
- **Status**: Ready
- **Depends On**: STORY-SN-003

---

### STORY-SN-005: Arrival Context Payload (Read-Once)

- **Type**: Logic
- **TR-IDs**: TR-scene-nav-006
- **ADR Guidance**: ADR-0003 — `change_scene(id, transition, context)` stores context in `_arrival_context`; `get_arrival_context()` returns the dict and clears it (read-once); context is also cleared at the start of every `change_scene()` call to prevent stale data
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN `change_scene(SceneId.COMBAT, FADE, {"enemy_id": "mountain_beast"})` is called, WHEN the arriving scene calls `SceneManager.get_arrival_context()`, THEN it receives `{"enemy_id": "mountain_beast"}`
  - [ ] AC2: GIVEN `get_arrival_context()` has already been called once, WHEN called a second time, THEN it returns an empty Dictionary `{}`
  - [ ] AC3: GIVEN `change_scene()` is called with a new context while a previous context was never read, WHEN `get_arrival_context()` is called after the transition, THEN it returns only the new context (old context is cleared)
  - [ ] AC4: GIVEN `change_scene()` is called with no context argument, WHEN `get_arrival_context()` is called in the arriving scene, THEN it returns an empty Dictionary with no error
- **Test Evidence**: `tests/unit/scene_navigation/arrival_context_test.gd`
- **Status**: Ready
- **Depends On**: STORY-SN-003

---

### STORY-SN-006: Settings Overlay (CanvasLayer 50)

- **Type**: Integration
- **TR-IDs**: TR-scene-nav-003
- **ADR Guidance**: ADR-0003 — Settings is NOT a scene change; `open_settings_overlay()` instantiates `settings.tscn` on CanvasLayer at layer 50; the underlying scene is NOT freed; `open_settings_overlay()` is dropped if not in IDLE state
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN `open_settings_overlay()` is called while in IDLE state, WHEN it executes, THEN a CanvasLayer at layer 50 is added to the scene tree with `settings.tscn` as its child
  - [ ] AC2: GIVEN the Settings overlay is open, WHEN the underlying Hub scene's root node is checked, THEN it is still present in the scene tree (not freed)
  - [ ] AC3: GIVEN the Settings overlay is open (OVERLAY_OPEN state), WHEN `change_scene()` or `open_settings_overlay()` is called again, THEN the call is silently dropped
  - [ ] AC4: GIVEN the Settings overlay emits its `close_requested` signal, WHEN it fires, THEN the CanvasLayer is removed from the scene tree and SceneManager returns to IDLE state
  - [ ] AC5: GIVEN `scene_changed` signal listeners, WHEN Settings overlay opens or closes, THEN `scene_changed` is NOT emitted
- **Test Evidence**: `tests/integration/scene_navigation/settings_overlay_test.gd`
- **Status**: Ready
- **Depends On**: STORY-SN-003

---

### STORY-SN-007: Hub Tab Keep-Alive + Android Back Button

- **Type**: Integration
- **TR-IDs**: TR-scene-nav-002, TR-scene-nav-008
- **ADR Guidance**: ADR-0003 — Hub tabs 1-4 use hide/show on a ContentContainer, never calling SceneManager; Tab 5 (Settings) calls `open_settings_overlay()`; Android back button is intercepted by SceneManager during OVERLAY_OPEN state
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN the Hub scene, WHEN a tab button is pressed to switch from tab 1 to tab 2, THEN no `SceneManager.change_scene()` call occurs (verified by monitoring SceneManager's transition state)
  - [ ] AC2: GIVEN the Hub scene, WHEN switching tabs, THEN the previously active tab's root node is hidden (not freed) and the new tab's root node becomes visible
  - [ ] AC3: GIVEN the Hub's Tab 5 (Settings) button is tapped, WHEN it activates, THEN `SceneManager.open_settings_overlay()` is called
  - [ ] AC4: GIVEN SceneManager is in OVERLAY_OPEN state and the Android back button is pressed, WHEN `_input()` processes it, THEN the overlay closes and SceneManager returns to IDLE (back does not navigate away from Hub)
  - [ ] AC5: GIVEN `TR-scene-nav-011` error recovery: a `change_scene()` call with a SceneId whose .tscn path fails to load, WHEN it fails, THEN the transition fades back to the previous scene and `navigation_error` signal is emitted
- **Test Evidence**: `tests/integration/scene_navigation/hub_tab_test.gd`
- **Status**: Ready
- **Depends On**: STORY-SN-004, STORY-SN-006
