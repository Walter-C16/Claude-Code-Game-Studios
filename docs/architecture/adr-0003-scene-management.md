# ADR-0003: Scene Management — SceneId Registry + Transitions

## Status
Accepted

## Date
2026-04-09

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | UI / Core (scene lifecycle, transitions) |
| **Knowledge Risk** | MEDIUM — Dual-focus system (4.6) separates mouse/touch from keyboard/gamepad focus. |
| **References Consulted** | `docs/engine-reference/godot/modules/ui.md`, `docs/engine-reference/godot/modules/input.md`, `docs/engine-reference/godot/breaking-changes.md` |
| **Post-Cutoff APIs Used** | Dual-focus affects `MOUSE_FILTER` behavior during transitions. `SceneTree.change_scene_to_file()` API unchanged. |
| **Verification Required** | Verify `MOUSE_FILTER_STOP` on transition overlay blocks touch input correctly under 4.6 dual-focus. Test overlay CanvasLayer stacking on all 3 platforms. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (GameStore persists across scene changes via autoload lifecycle) |
| **Enables** | ADR-0008 (Dialogue), ADR-0011 (Story Flow), ADR-0014 (Deck Management) — all systems that trigger scene transitions |
| **Blocks** | All gameplay epics — cannot navigate between screens without SceneManager |
| **Ordering Note** | Foundation layer. Implement after GameStore/SaveManager, before any scene-based system. |

## Context

### Problem Statement

Dark Olympus has 17 registered screens. Without a centralized routing layer, each screen would call `SceneTree.change_scene_to_file()` directly, producing: (1) jarring instant cuts instead of smooth transitions, (2) double-tap race conditions where rapid taps load two scenes simultaneously, (3) scattered transition logic duplicated across every screen, (4) no consistent way to pass data between scenes.

### Constraints

- **Touch-only input**: No keyboard/gamepad navigation. All touch, all the time.
- **Portrait viewport (430x932)**: UI layout is fixed portrait. No landscape support.
- **Mobile performance**: Transition tweens must not drop below 30fps on minimum-spec devices.
- **Hub is special**: Hub has 5 tabs that swap content internally — NOT scene changes.
- **Settings is an overlay**: Settings renders above the current scene, not replacing it.

### Requirements

- All scene transitions route through a single autoload
- Callers use enum IDs, never raw `.tscn` paths
- Animated transitions (fade-to-black) between scenes
- Input blocked during transitions
- Context payloads pass data to arriving scenes
- Guard against concurrent/double transitions
- Settings as overlay, not scene change
- Hub tabs as keep-alive internal swaps

## Decision

**SceneManager is an autoload that centralizes all scene transitions.** It provides `change_scene(SceneId, TransitionType, context)` as the sole entry point. Raw `SceneTree.change_scene_to_file()` calls outside `scene_manager.gd` are forbidden.

### SceneId Registry

```gdscript
enum SceneId {
    SPLASH,
    DIALOGUE,
    COMBAT,
    HUB,
    CHAPTER_MAP,
    COMPANION_ROOM,
    DATE,
    INTIMACY,
    DECK,
    DECK_VIEWER,
    EQUIPMENT,
    EXPLORATION,
    ABYSS,
    GALLERY,
    ACHIEVEMENTS,
    SETTINGS,  # overlay, not full scene change
}

const SCENE_PATHS: Dictionary = {
    SceneId.SPLASH: "res://src/scenes/splash/splash.tscn",
    SceneId.DIALOGUE: "res://src/scenes/dialogue/dialogue.tscn",
    SceneId.COMBAT: "res://src/scenes/combat/combat.tscn",
    SceneId.HUB: "res://src/scenes/hub/hub.tscn",
    SceneId.CHAPTER_MAP: "res://src/scenes/story/chapter_map.tscn",
    # ... etc
}
```

Adding a new screen: add enum value + path entry. No other code changes.

### Transition Types

```gdscript
enum TransitionType { FADE, INSTANT, NONE }
```

| Type | Behavior | Duration | Use |
|---|---|---|---|
| FADE | Overlay fades to black (0.3s), scene swaps, fades back (0.3s) | ~0.65s total | Default for all full scene changes |
| INSTANT | No animation, immediate swap | 1 frame | Splash → Hub only |
| NONE | Direct swap, no overlay | 1 frame | Debug/testing only |

### State Machine

```
IDLE → FADING_OUT → LOADING → FADING_IN → IDLE
IDLE → OVERLAY_OPEN → IDLE (Settings only)
```

- All `change_scene()` calls while NOT in IDLE are silently dropped (transition guard).
- `open_settings_overlay()` is also dropped if not IDLE.

### Input Blocking

During FADING_OUT/LOADING/FADING_IN, the transition overlay (ColorRect on CanvasLayer 100) sets `mouse_filter = MOUSE_FILTER_STOP`, blocking all touch events from reaching scenes below. Restored to `MOUSE_FILTER_IGNORE` after FADING_IN completes.

### Context Payload

```gdscript
var _arrival_context: Dictionary = {}

func change_scene(id: SceneId, transition: TransitionType = TransitionType.FADE,
        context: Dictionary = {}) -> void:
    _arrival_context = context
    # ... transition logic

func get_arrival_context() -> Dictionary:
    var ctx := _arrival_context
    _arrival_context = {}  # read-once, cleared after read
    return ctx
```

Examples:
- Combat: `{ "enemy_id": "mountain_beast", "mode": "story", "node_id": "ch01_n04" }`
- Hub: `{ "restore_tab": 3 }` (Camp tab index)
- Companion Room: `{ "companion_id": "artemisa" }`

Context is cleared at the start of every `change_scene()` call AND after `get_arrival_context()` to prevent stale context leaking.

### Settings Overlay

Settings is NOT a scene change. `open_settings_overlay()` instantiates `settings.tscn` on a CanvasLayer at layer 50 (below transition overlay at 100, above game scenes). The underlying scene is NOT freed. Closing Settings removes the overlay via `close_requested` signal.

### Hub Tab Architecture

Hub has 5 bottom tabs. Tabs 1-4 (Team, Arena, Story, Camp) swap a `ContentContainer` child using keep-alive hide/show — no SceneManager call, instant swap, no transition animation. Tab 5 (Settings) calls `open_settings_overlay()`.

### Signals

```gdscript
signal scene_changed(scene_id: SceneId)        # after fade-in completes
signal transition_started(scene_id: SceneId)    # at start of fade-out
```

Settings overlay open/close does NOT emit `scene_changed`.

### Key Interfaces

```gdscript
extends Node

enum SceneId { ... }  # 16 entries
enum TransitionType { FADE, INSTANT, NONE }

func change_scene(id: SceneId, transition: TransitionType = TransitionType.FADE,
    context: Dictionary = {}) -> void
func open_settings_overlay() -> void
func get_arrival_context() -> Dictionary  # read-once
func is_transitioning() -> bool

signal scene_changed(scene_id: SceneId)
signal transition_started(scene_id: SceneId)
```

## Alternatives Considered

### Alternative 1: Direct SceneTree Calls Per Screen

- **Description**: Each screen calls `get_tree().change_scene_to_file()` directly with its own transition logic.
- **Pros**: No abstraction overhead. Each screen controls its own transitions.
- **Cons**: Duplicated transition code across 17 screens. No double-tap guard. No context passing. Inconsistent transition timing. No central signal for "scene changed."
- **Rejection Reason**: Violates DRY. Double-tap race conditions are a known mobile UX bug. Context payload would require a global variable anyway, which is what SceneManager provides.

### Alternative 2: Navigation Stack (Push/Pop)

- **Description**: Maintain a stack of scenes. `push_scene()` adds on top, `pop_scene()` returns to previous. Like mobile app navigation.
- **Pros**: Back navigation is automatic. Deep stacking possible.
- **Cons**: Dark Olympus navigation is mostly flat (Hub is the center, screens branch from it and return). A stack suggests deep nesting that doesn't match the game's navigation model. Hub tabs break the stack metaphor. Combat → Hub return doesn't "pop" — it's a fresh Hub load.
- **Rejection Reason**: The game's navigation is hub-and-spoke, not stack-based. A one-level `_previous_scene_id` covers the rare cases where a "back" concept is needed. Full stack adds complexity for a pattern the game doesn't use.

## Consequences

### Positive

- **Consistent transitions**: Every screen change looks and feels the same (0.3s fade).
- **Race condition proof**: Double-tap guard prevents loading two scenes simultaneously.
- **Centralized routing**: One place to audit all possible scene transitions.
- **Context passing**: Clean data handoff between scenes without global state hacks.
- **Input safety**: Touch input is blocked during transitions — no accidental taps on half-loaded scenes.

### Negative

- **All transitions go through one bottleneck**: If SceneManager has a bug, no screen can navigate. Mitigation: SceneManager is small (~150 lines) and highly testable.
- **No deep back-stack**: Can't do "back, back, back" navigation. Mitigation: Hub-and-spoke model doesn't need this.

### Risks

- **`MOUSE_FILTER_STOP` under 4.6 dual-focus**: The dual-focus system separates mouse/touch from keyboard/gamepad focus. Since this game is touch-only, `MOUSE_FILTER_STOP` on the overlay should block touch correctly. But verify this on 4.6 — the dual-focus change could affect how `STOP` is processed. Mitigation: test early on target hardware.
- **Scene load time**: If a scene's `_ready()` takes >1s, the player sees extended black during LOADING state. Mitigation: profile `_ready()` for all scenes. Defer heavy setup to `call_deferred()`.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|---|---|---|
| scene-navigation.md | Single change_scene() entry point (Rule 1) | SceneManager autoload with SceneId enum |
| scene-navigation.md | SceneId enum, no raw paths (Rule 1) | SCENE_PATHS dictionary maps enum to .tscn |
| scene-navigation.md | FADE transition 0.3s out + 0.3s in (Rule 7) | TransitionType.FADE with configurable duration |
| scene-navigation.md | Double-transition guard (Rule 8) | State machine: only IDLE accepts change_scene() |
| scene-navigation.md | Input blocking during transitions (Rule 9) | MOUSE_FILTER_STOP on CanvasLayer 100 overlay |
| scene-navigation.md | Context payload, read-once (Rule 6) | _arrival_context Dictionary, cleared after read |
| scene-navigation.md | Settings as overlay, not scene change (Rule 3) | open_settings_overlay() on CanvasLayer 50 |
| scene-navigation.md | Hub tabs are keep-alive, not scene changes (Rule 2) | Hub manages ContentContainer internally |
| scene-navigation.md | scene_changed / transition_started signals (Rule 10) | Two typed signals on SceneManager |
| camp.md | Camp tab activates via keep-alive (AC-CAMP-01) | Hub tab architecture supports this |
| story-flow.md | Story Flow sequences scenes via SceneManager | change_scene(DIALOGUE/COMBAT, context) |

## Performance Implications

- **CPU**: Tween for fade overlay: negligible (~0.01ms/frame during transition).
- **Memory**: One ColorRect overlay + one CanvasLayer: <1KB.
- **Load Time**: Scene load time is scene-dependent, not SceneManager-dependent. SceneManager adds 0ms overhead.

## Migration Plan

Existing `scene_manager.gd` in `src/autoloads/` already implements a subset of this design. Refactor to add: SceneId enum (currently uses raw paths), context payload system, Settings overlay pattern, formal state machine, transition_started signal.

## Validation Criteria

1. **Unit test**: `change_scene()` with valid SceneId transitions to correct scene.
2. **Unit test**: Two `change_scene()` calls in same frame — only first executes, second is dropped.
3. **Unit test**: `get_arrival_context()` returns payload on first call, empty Dictionary on second.
4. **Unit test**: `is_transitioning()` returns true during FADING_OUT/LOADING/FADING_IN.
5. **Integration test**: Settings overlay opens above Hub, Hub remains instantiated beneath.
6. **Platform test**: Touch input during FADING_OUT does not reach scenes below overlay.
7. **Performance test**: FADE transition maintains 30fps on minimum-spec device.

## Related Decisions

- ADR-0001: GameStore — autoloads persist across scene changes (Godot guarantees this)
- ADR-0002: Save System — SaveManager survives scene changes, continues saving
- ADR-0004 (planned): EventBus — scene_changed signal may relay through EventBus
- `design/gdd/scene-navigation.md` — full design spec
