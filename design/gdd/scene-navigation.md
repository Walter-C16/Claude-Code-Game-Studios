# Scene Navigation

> **Status**: Designed
> **Author**: game-designer + systems-designer
> **Last Updated**: 2026-04-08
> **Implements Pillar**: All pillars (enables flow between all game screens)

## Summary

Scene Navigation is the SceneManager autoload that handles all screen-to-screen transitions in Dark Olympus. It provides a single `change_scene()` entry point with animated transitions (fade-to-black), guards against double-transitions, and emits a `scene_changed` signal so other systems can react to navigation events. All 18 game screens route through this system -- no screen changes itself directly via `SceneTree`.

> **Quick reference** -- Layer: `Foundation` · Priority: `MVP` · Key deps: `None`

## Overview

Scene Navigation is the centralized routing layer for all 18 screens in Dark Olympus. It wraps Godot's `SceneTree.change_scene_to_file()` behind a managed interface that enforces transition animations, prevents input during transitions, and emits lifecycle signals. The player never interacts with this system directly -- they tap a story node, a camp companion, or a tab bar button, and the owning system calls `SceneManager.change_scene()` with the target screen path. The system exists because unmanaged scene changes produce jarring cuts, allow double-tap race conditions, and scatter transition logic across every screen. A single autoload centralizes these concerns so every screen transition is consistent, safe, and auditable.

## Player Fantasy

Scene Navigation has no direct player fantasy -- its success is invisibility. The player's relationship with Dark Olympus is built on trust: trust that the story is continuous, that the goddess they were speaking with still exists when they return to camp, that the world did not reassemble itself while they looked away. This system is the silent keeper of that trust. It promises that every tap leads somewhere, that the world does not stutter or contradict itself. The player feels this not as a feature but as the baseline confidence that lets them fall into a story about fallen gods and fragile intimacy. When it works, they never think about it. When it breaks, they stop believing in the world.

## Detailed Design

### Core Rules

1. **Screen Registry.** Every screen has a canonical `SceneId` enum value. No caller passes raw `.tscn` path strings to SceneManager. The registry maps each `SceneId` to its `res://` path in a single const dictionary. If a scene file moves, only the registry entry changes.

   Registry entries (17 full scenes):
   `SPLASH, DIALOGUE, COMBAT, HUB, CHAPTER_MAP, CAMP, COMPANION_ROOM, DATE, INTIMACY, DECK, DECK_VIEWER, EQUIPMENT, EXPLORATION, ABYSS, GALLERY, ACHIEVEMENTS, SETTINGS`

   Note: Settings is registered but loaded as an overlay, not via `change_scene_to_file()`. Hub sub-tab content (Team, Arena, Story, Camp panels) are NOT registered -- they are in-scene sub-scenes managed by Hub internally.

2. **Hub tab bar is in-scene, not scene changes.** The Hub has 5 bottom tabs (Team, Arena, Story, Camp, Settings). Tabs 1-4 swap a `ContentContainer` child inside `hub.tscn` using keep-alive hide/show -- no SceneManager call, no transition animation, instant swap. Tab 5 (Settings) calls `SceneManager.open_settings_overlay()`. Arena tab shows a sub-screen with challenger name, HP, and an Enter button before launching combat.

3. **Settings is an overlay, not a scene change.** `open_settings_overlay()` instantiates `settings.tscn` on a `CanvasLayer` at layer 50, above the current scene but below the transition overlay (layer 100). The underlying scene is not freed -- it continues to exist beneath. Closing Settings removes the overlay and resumes the underlying scene. Settings emits a `close_requested` signal; SceneManager removes the overlay on receipt.

4. **One-level previous scene, not a back-stack.** SceneManager tracks `_previous_scene_id: SceneId` -- the last scene before the current one. There is no deep stack. Navigation is always explicit: the caller knows the destination. The `_previous_scene_id` exists so that scenes that need a "return" path (e.g., Companion Room returning to Hub) can reference it, but the standard pattern is to pass the return destination in the context payload.

5. **Scene state is destroyed on full scene changes.** When SceneManager triggers a full scene change, the outgoing scene tree is freed. Persistent state lives in autoload stores (GameStore, SettingsStore, DialogueStore, CombatStore). Scenes rebuild from autoloads in `_ready()`. SceneManager does not save or restore any scene-local state.

6. **Context payload.** `change_scene()` accepts an optional `context: Dictionary`. SceneManager stores it and exposes it via `get_arrival_context() -> Dictionary`. The incoming scene reads this in `_ready()` to configure itself. Examples:
   - Combat: `{ "source": SceneId.HUB, "mode": "arena" }` vs. `{ "source": SceneId.DIALOGUE, "story_node_id": "ch01_n04", "mode": "story" }`
   - Hub: `{ "restore_tab": 3 }` (Camp tab index)
   - Companion Room: `{ "companion_id": "artemisa" }`

   Context is read-once -- cleared after `get_arrival_context()` is called.

7. **Transition types.** Three types, selected by enum:

   | Type | Behavior | When Used |
   |------|----------|-----------|
   | `FADE` | 0.3s fade-out, scene swap, 0.3s fade-in | Default for all full scene changes |
   | `INSTANT` | No animation, immediate swap | Splash -> first scene only |
   | `NONE` | No transition, direct swap (1 frame) | Debug/testing only |

   Default is `FADE` if omitted.

8. **Transition guard.** While a transition is in progress, all `change_scene()` and `open_settings_overlay()` calls are silently dropped. No queuing. Callers that need to chain transitions must await the `scene_changed` signal before calling again.

9. **Input blocking during transitions.** The transition overlay switches to `MOUSE_FILTER_STOP` at the start of fade-out (blocking all touch input) and restores `MOUSE_FILTER_IGNORE` after fade-in completes. This prevents touch events reaching scenes in mid-teardown or mid-initialization.

10. **Signal contract.**

    | Signal | Emitted When | Payload |
    |--------|-------------|---------|
    | `scene_changed(scene_id: SceneId)` | After fade-in completes (full transition done) | The new scene's ID |
    | `transition_started(scene_id: SceneId)` | At the start of fade-out | The target scene's ID |

    Settings overlay open/close does NOT emit `scene_changed`.

11. **Android back button.** `NOTIFICATION_WM_GO_BACK_REQUEST` is handled per-scene, not by SceneManager. On Splash: show quit confirmation. On Hub: consume the event (do nothing -- prevents accidental minimize). On other screens: navigate to Hub. During transitions (`SceneManager.is_transitioning` is true), all back-button handlers must early-return.

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| `IDLE` | Initial state; after fade-in completes; after overlay closed | `change_scene()` or `open_settings_overlay()` called | Normal gameplay, input passthrough |
| `FADING_OUT` | `change_scene()` called with FADE | Fade-out tween completes | Overlay alpha 0->1, input blocked |
| `LOADING` | Fade-out complete | `process_frame` completes after `change_scene_to_file()` | Scene tree swap occurs, overlay fully opaque |
| `FADING_IN` | Loading complete | Fade-in tween completes | Overlay alpha 1->0, input still blocked |
| `OVERLAY_OPEN` | `open_settings_overlay()` called | Settings emits `close_requested` | Settings visible at layer 50, underlying scene paused |

Invalid transitions (silently dropped):
- Any `change_scene()` when state != IDLE
- `open_settings_overlay()` when state != IDLE

For INSTANT type: IDLE -> LOADING -> IDLE (no FADING states).

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| **Story Flow** | Calls SceneManager | `change_scene(DIALOGUE/COMBAT/INTIMACY, FADE, { story_node_id, mode })`. StoryFlow owns sequencing -- SceneManager is a transport layer. |
| **Dialogue** | Emits signal consumed by StoryFlow | Dialogue emits `dialogue_completed`. StoryFlow listens, advances story node, calls SceneManager for next scene. Dialogue never calls SceneManager directly in story mode. |
| **Combat** | Emits signal consumed by StoryFlow/ArenaManager | Combat emits `combat_completed(result)`. In story mode: StoryFlow handles. In arena mode: ArenaManager calls `change_scene(HUB, FADE, { restore_tab: 1 })`. |
| **Hub** | Contains tab bar (in-scene) | Tabs 1-4: internal content swap, no SceneManager. Tab 5: `open_settings_overlay()`. Arena Enter button and Story node taps call `change_scene()`. |
| **Camp** | Calls SceneManager for companion drill-down | `change_scene(COMPANION_ROOM, FADE, { companion_id })`. Return: `change_scene(HUB, FADE, { restore_tab: 3 })`. |
| **Save System** | Indirect | SceneManager does not call Save System. Autoloads save state independently. SceneManager only ensures autoloads survive scene changes (guaranteed by Godot autoload lifecycle). |
| **Localization** | Indirect | SceneManager does not handle locale changes. Scenes rebuild localized strings in `_ready()` from `tr()` calls. |
| **Settings Overlay** | Managed by SceneManager | `open_settings_overlay()` / overlay `close_requested` signal. Settings reads/writes SettingsStore directly. |

## Formulas

### Transition Duration

The transition_duration formula is defined as:

`transition_duration = fade_out_duration + load_time + fade_in_duration`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| fade_out_duration | T_out | float | 0.0--1.0s | Duration of the fade-to-black tween |
| load_time | T_load | float | 0.016--2.0s | Time for SceneTree to instantiate the new scene (1 frame min, asset-dependent) |
| fade_in_duration | T_in | float | 0.0--1.0s | Duration of the fade-from-black tween |

**Output Range:** 0.032s (INSTANT type, load only) to ~2.6s (max fade + slow device load). Typical: 0.65s (0.3 + 0.05 + 0.3).

**Example:** T_out = 0.3s, T_load = 0.05s (fast device, small scene), T_in = 0.3s -> transition_duration = 0.65s. Player perceives: 0.3s darkening, brief black, 0.3s brightening.

**Constraint:** T_load is always hidden under the opaque overlay. The implementation awaits scene load before starting fade-in, so T_load cannot exceed the overlay window. If T_load > 1.0s on a device, the player sees extended black -- acceptable but signals the scene's `_ready()` is too heavy.

**Note:** This is the only formula in Scene Navigation. The system performs no scoring, scaling, or balance calculations. All transition timing values are tuning knobs (see Tuning Knobs section).

## Edge Cases

- **If `change_scene()` is called twice in the same frame** (double-tap before state flips): `_is_transitioning` must be set as the very first line of `change_scene()`, before any tween or await, so the guard trips even on same-frame calls.

- **If `change_scene_to_file()` receives a missing or corrupted `.tscn` path**: Godot returns an error code but does not crash; the scene tree may be empty. SceneManager must check the return value, fade back in on the previous scene (re-instantiate from `_previous_scene_id`), emit `navigation_error(scene_id)`, and log the error. Never leave the player on a black screen.

- **If a scene's `_ready()` takes longer than expected during LOADING state**: the overlay stays opaque. Acceptable up to ~1.0s. If scenes consistently exceed this, their `_ready()` must defer heavy work to `call_deferred()`. No timeout watchdog in v1 -- monitor via profiling.

- **If `get_arrival_context()` is called more than once**: the second call returns an empty Dictionary (context is read-once). Scenes must cache the result locally on first call. This is a documented contract, not a bug.

- **If `get_arrival_context()` is never called**: stale context could leak to the next navigation. SceneManager clears `_arrival_context` at the start of every `change_scene()` call, not only on read.

- **If a full scene change is triggered while the Settings overlay is open**: state is `OVERLAY_OPEN`, so `change_scene()` is silently dropped. Correct for player-initiated use. If a forced-navigation use case arises (e.g., session timeout), a `force_change_scene()` variant that closes the overlay first will be needed -- flag as open question until confirmed.

- **If the Hub tab bar is tapped rapidly**: Hub tracks a `_tab_locked: bool` during any content-swap animation. Incoming tab taps during lock are dropped, not queued.

- **If the Android back button fires while the Settings overlay is open**: SceneManager must intercept `NOTIFICATION_WM_GO_BACK_REQUEST` when state is `OVERLAY_OPEN`, close the overlay, and consume the event. Per-scene handlers only run if SceneManager does not consume it.

- **If the Android back button fires on Splash before `_ready()` completes**: the quit confirmation dialog may not exist yet. Splash's back handler must guard with `is_inside_tree()` or instantiate the dialog lazily on first press.

- **If the fade-out tween's `finished` signal fires after the outgoing scene is freed**: safe as long as the transition overlay `CanvasLayer` is parented to the SceneManager autoload node (which persists), never to the outgoing scene. This is an implementation constraint.

## Dependencies

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| **Camp** | Camp depends on this | Camp calls `change_scene(COMPANION_ROOM)` for companion drill-down and passes `companion_id` in context. Camp expects `change_scene(HUB, { restore_tab: 3 })` on return. |
| **Story Flow** | Story Flow depends on this | Story Flow calls `change_scene()` to sequence dialogue -> combat -> reward -> next node. Story Flow owns the sequencing logic; SceneManager is the transport layer. |
| **Dialogue** | Dialogue depends on this (indirect) | Dialogue does not call SceneManager directly in story mode -- it emits `dialogue_completed` to Story Flow, which calls SceneManager. In standalone/debug mode, Dialogue may call SceneManager directly. |
| **Combat** | Combat depends on this (indirect) | Combat emits `combat_completed(result)` consumed by Story Flow or ArenaManager. Arena mode: Combat itself calls `change_scene(HUB, { restore_tab: 1 })`. |
| **Hub** | Hub depends on this | Hub tab 5 (Settings) calls `open_settings_overlay()`. Arena Enter button and Story node taps call `change_scene()`. Hub reads `restore_tab` from arrival context. |
| **Settings** | Settings depends on this (overlay) | Settings is loaded as an overlay by SceneManager. Settings emits `close_requested` to close. Settings reads/writes SettingsStore directly. |
| **Deck Management** | Deck Management depends on this | Deck Management calls `change_scene(COMBAT, context)` on combat handoff. Cancel returns to previous screen via SceneManager. |
| **Save System** | Independent | SceneManager does not call Save System. Autoload stores handle their own persistence. No dependency in either direction. |
| **Localization** | Independent | No dependency. Scenes rebuild localized strings via `tr()` in their own `_ready()`. |

**Hard dependencies** (system cannot function without):
- None. Scene Navigation has zero upstream dependencies. It is a Foundation layer system.

**Soft dependencies** (enhanced by but works without):
- UI Theme: transition overlay uses plain black -- could eventually use themed visuals, but works without.

## Tuning Knobs

| Parameter | Current Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|
| `FADE_DURATION` | 0.3s | 0.1--0.8s | Transitions feel more cinematic/deliberate; >0.8s feels sluggish | Transitions feel snappier; <0.1s feels jarring, nearly instant |
| `OVERLAY_LAYER` | 100 | 90--127 | No visible effect unless another system uses a higher layer | Risk of UI elements rendering above the overlay during transitions |
| `SETTINGS_OVERLAY_LAYER` | 50 | 40--90 | Settings renders above more UI layers | Risk of game UI rendering above Settings |
| `MAX_LOAD_WAIT` | 5.0s (monitoring only, no timeout in v1) | 2.0--10.0s | More tolerance for slow devices | Faster detection of stuck loads (future use) |

**Knob interactions:**
- `FADE_DURATION` directly affects perceived responsiveness. For Abyss mode (fast-paced roguelike), consider allowing a shorter fade (0.15s) via context payload if the default 0.3s feels too slow between rapid ante transitions.
- `OVERLAY_LAYER` must always be > `SETTINGS_OVERLAY_LAYER` so the transition overlay covers Settings during scene changes.

## Acceptance Criteria

- [ ] **AC-01**: GIVEN any system navigates to a new screen, WHEN it calls `change_scene()`, THEN the argument is a `SceneId` enum value, never a raw `.tscn` path string. Grep for `change_scene_to_file` outside `scene_manager.gd` must return zero results.
- [ ] **AC-02**: GIVEN a FADE transition is triggered, WHEN the transition completes, THEN the screen fades to black over 0.3s, the scene swaps while the overlay is opaque, and the new scene fades in over 0.3s. Total transition time is 0.6--0.9s on target hardware.
- [ ] **AC-03**: GIVEN the Splash scene exits, WHEN `change_scene(HUB, INSTANT)` is called, THEN the scene changes in one frame with no fade animation and no black overlay visible.
- [ ] **AC-04**: GIVEN a transition is in progress, WHEN a second `change_scene()` call arrives, THEN it is silently dropped. `scene_changed` emits exactly once. Final scene is the first call's target.
- [ ] **AC-05**: GIVEN `change_scene()` is called with a context payload, WHEN the arriving scene calls `get_arrival_context()`, THEN the returned Dictionary matches the payload.
- [ ] **AC-06**: GIVEN `get_arrival_context()` has been called once, WHEN it is called again, THEN it returns an empty Dictionary.
- [ ] **AC-07**: GIVEN Scene A navigated to Scene B with context and Scene B never read it, WHEN Scene B navigates to Scene C with no context, THEN `get_arrival_context()` from Scene C returns `{}`.
- [ ] **AC-08**: GIVEN the player taps Settings tab, WHEN `open_settings_overlay()` is called, THEN Settings appears at CanvasLayer 50; Hub remains instantiated beneath; `scene_changed` is NOT emitted; state transitions to `OVERLAY_OPEN`.
- [ ] **AC-09**: GIVEN Settings overlay is open, WHEN `change_scene()` is called, THEN the call is silently dropped. Settings remains visible.
- [ ] **AC-10**: GIVEN a FADE transition is in progress, WHEN the player touches the screen, THEN the touch event does not reach any scene node. After transition completes, input is restored.
- [ ] **AC-11**: GIVEN the player is on Hub, WHEN they tap between tabs 1-4, THEN content swaps instantly via hide/show with no SceneManager call. `transition_started` is never emitted.
- [ ] **AC-12**: GIVEN Settings overlay is open, WHEN Android back button fires, THEN SceneManager closes the overlay and consumes the event. Per-scene handlers do not fire.
- [ ] **AC-13**: GIVEN a transition targets a missing/corrupted `.tscn`, WHEN load fails, THEN SceneManager fades back in on the previous scene, emits `navigation_error(scene_id)`, and returns to IDLE. Player never sees a permanent black screen.
- [ ] **AC-14**: GIVEN a FADE transition from Hub to Dialogue, WHEN the transition completes, THEN `transition_started` is emitted before fade-out begins and `scene_changed` is emitted after fade-in completes. Never in reverse order.
- [ ] **AC-15**: GIVEN a FADE transition on the minimum-spec target device, WHEN Hub transitions to any scene, THEN `transition_duration` does not exceed 1.5s. No frame drops below 30fps during fade tweens.

## Cross-References

| This Document References | Target GDD | Specific Element Referenced | Nature |
|--------------------------|-----------|----------------------------|--------|
| Settings overlay uses SettingsStore for reads/writes | `design/gdd/save-system.md` | `to_dict()` / `from_dict()` serialization contract | Data dependency |
| Arrival context carries `companion_id` for Companion Room | `design/gdd/companion-data.md` | Companion ID enum values (`artemisa`, `hipolita`, etc.) | Data dependency |
| Story Flow sequences dialogue -> combat -> reward via `change_scene()` | `design/gdd/story-flow.md` (not yet designed) | Story node type resolution and sequencing | Rule dependency |
| Camp calls `change_scene(COMPANION_ROOM)` with context | `design/gdd/camp.md` (not yet designed) | Camp-to-companion drill-down flow | State trigger |
| Hub tab restore uses `restore_tab` in context payload | `design/gdd/ui-theme.md` | Tab bar layout and indexing | Rule dependency |

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Screen count: Overview says "18 screens" but SceneId registry has 17 entries. Is the 18th screen missing or was one merged? | game-designer | Before implementation | Audit screen list against GDD Screens Needed |
| Should `force_change_scene()` exist for forced navigation (e.g., session timeout) that bypasses the OVERLAY_OPEN guard? | game-designer | Before Abyss Mode GDD | No use case confirmed yet -- revisit when a forced-nav scenario arises |
| Should Abyss mode use a shorter FADE_DURATION (0.15s) for faster between-ante pacing? | game-designer | During Abyss Mode GDD | Defer to Abyss Mode design |
