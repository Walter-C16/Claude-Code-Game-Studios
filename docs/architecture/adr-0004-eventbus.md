# ADR-0004: EventBus — Cross-System Signal Architecture

## Status
Accepted

## Date
2026-04-09

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core (signal architecture) |
| **Knowledge Risk** | LOW — Signal API unchanged since 4.0. Callable-based `connect()` is the standard. |
| **References Consulted** | `docs/engine-reference/godot/deprecated-apis.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None — signals are stable and well-understood. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None (pure infrastructure, no state dependency) |
| **Enables** | All Core/Feature ADRs (ADR-0007 through ADR-0012) — every cross-system communication goes through EventBus |
| **Blocks** | Any system that emits or listens for cross-system events |
| **Ordering Note** | Foundation layer. EventBus is autoload #3 in boot order (after GameStore, SettingsStore). |

## Context

### Problem Statement

Dark Olympus has 13 systems across 4 layers (Foundation, Core, Feature, Presentation). Many events need to cross layer boundaries: combat completion triggers story advancement AND relationship gains AND buff consumption. Without a decoupling layer, Feature systems would import each other directly, creating circular dependencies and violating layer isolation (ADR-0001 principle #3).

### Constraints

- **Layer isolation**: Feature layer must not import Core or Foundation. Core must not import Feature. (Architecture principle #3)
- **Single-threaded GDScript**: No concurrency concerns. Signals are synchronous in the same frame.
- **~15 cross-system signals**: The game has a bounded, known set of events that cross system boundaries.
- **Testability**: Systems must be testable in isolation. Direct signal connections between autoloads create hidden dependencies.

### Requirements

- Cross-system events route through a single, known relay point
- Emitters and listeners do not import each other
- All cross-system signals are defined in one place (auditable catalog)
- Adding a new signal requires only: (1) add signal to EventBus, (2) connect in emitter/listener
- Signal parameters are typed for compiler validation

## Decision

**EventBus is a lightweight autoload that declares all cross-system signals.** It owns no state and no logic — it is a pure relay. Emitting systems call `EventBus.signal_name.emit(args)`. Listening systems call `EventBus.signal_name.connect(callable)`. Neither system imports the other.

### Signal Catalog

```gdscript
extends Node

# ── Romance & Social ──
signal romance_stage_changed(companion_id: String, old_stage: int, new_stage: int)
signal tokens_reset  # midnight UTC

# ── Combat ──
signal combat_completed(result: Dictionary)
# result: {victory: bool, score: int, hands_used: int, captain_id: String}

# ── Dialogue ──
signal dialogue_ended(sequence_id: String)
signal dialogue_blocked(sequence_id: String, reason: String)
signal relationship_changed(companion_id: String, delta: int)
signal trust_changed(companion_id: String, delta: int)

# ── Story ──
signal companion_met(companion_id: String)
signal chapter_completed(chapter_id: String)
signal node_completed(node_id: String)

# ── Deck/Combat Setup ──
# combat_configured is a LOCAL signal on DeckManager (scene-local, same scene as CombatSystem).
# It does NOT route through EventBus. See ADR-0014.
```

### Emission Pattern

Systems emit to EventBus, not directly:

```gdscript
# In DialogueRunner (Core layer):
func _resolve_effect(effect: Dictionary) -> void:
    if effect.type == "relationship":
        EventBus.relationship_changed.emit(effect.companion, effect.delta)

# In RomanceSocial (Feature layer) — listener:
func _ready() -> void:
    EventBus.relationship_changed.connect(_on_relationship_changed)

func _on_relationship_changed(companion_id: String, delta: int) -> void:
    var current := GameStore.get_relationship_level(companion_id)
    GameStore.set_relationship_level(companion_id, current + delta)
```

DialogueRunner (Core) does not import RomanceSocial (Feature). RomanceSocial does not import DialogueRunner. Both import only EventBus (Foundation).

### Connection Rules

1. **Emitters call `EventBus.[signal].emit()`** — never emit on their own local signals for cross-system events.
2. **Listeners call `EventBus.[signal].connect()` in `_ready()`** — disconnect is automatic when the listener is freed.
3. **Local signals are still allowed** for intra-module communication (e.g., CombatSystem's internal `hand_scored` signal is local, not on EventBus).
4. **EventBus has no `_process()`**, no state, no logic. It is ~30 lines of signal declarations.

### Architecture Diagram

```
Feature Layer:
  RomanceSocial ──listen──> EventBus.relationship_changed
  StoryFlow     ──listen──> EventBus.combat_completed
  StoryFlow     ──listen──> EventBus.dialogue_ended
  BlessingSystem ──listen──> EventBus.romance_stage_changed

Core Layer:
  DialogueRunner ──emit──> EventBus.relationship_changed
  DialogueRunner ──emit──> EventBus.trust_changed
  DialogueRunner ──emit──> EventBus.dialogue_ended
  CombatSystem   ──emit──> EventBus.combat_completed

Foundation Layer:
  EventBus (autoload) — declares all signals, relays only
```

No arrows go upward (Core → Feature). All cross-layer communication goes through EventBus.

## Alternatives Considered

### Alternative 1: Direct Signal Connections Between Systems

- **Description**: RomanceSocial directly connects to DialogueRunner's `relationship_changed` signal. No intermediary.
- **Pros**: Fewer files. No bus abstraction. Godot-idiomatic for small projects.
- **Cons**: RomanceSocial must import DialogueRunner to call `.connect()`. Creates a Feature → Core import, violating layer isolation. Adding a new listener requires modifying the emitter's code. Harder to audit all cross-system connections.
- **Rejection Reason**: Violates layer isolation (Architecture Principle #3). Also makes unit testing harder — testing RomanceSocial would require a DialogueRunner instance.

### Alternative 2: Observer Pattern with Callable Registration

- **Description**: A central registry where systems register interest in event types by name. Emitters push events to the registry, which dispatches to registered callables.
- **Pros**: Fully dynamic — systems can register at runtime. Type-agnostic.
- **Cons**: Loses Godot's built-in signal type checking. String-based event names are error-prone. No compiler validation of parameters. Reinvents what Godot signals already provide.
- **Rejection Reason**: Godot's typed signal system already provides compile-time validation, automatic disconnect on free, and the familiar `.connect()` / `.emit()` API. Wrapping this in a custom observer pattern adds complexity without benefit.

## Consequences

### Positive

- **Layer isolation enforced**: No cross-layer imports. Systems communicate through EventBus only.
- **Auditable**: All cross-system events are declared in one ~30-line file.
- **Testable**: Testing a system in isolation only requires a mock EventBus (or direct signal emission in test).
- **Extensible**: Adding a new cross-system event = add one signal line to EventBus.

### Negative

- **Indirection**: Debugging "who listens to this signal?" requires checking EventBus connections rather than following direct imports. Mitigation: EventBus is small and well-documented. `Grep "EventBus.signal_name"` finds all emitters and listeners instantly.
- **No compile-time verification of connections**: A listener can connect to a signal that no emitter ever fires, or an emitter can fire a signal with no listeners. Both are silent. Mitigation: integration tests verify end-to-end signal chains.

### Risks

- **Signal parameter mismatch**: An emitter sends 3 args, a listener expects 2. Godot will crash or silently ignore the extra. Mitigation: typed signal declarations enforce parameter counts at the `emit()` call site.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|---|---|---|
| dialogue.md | `relationship_changed` and `trust_changed` signals (Rule 5) | Declared on EventBus, emitted by DialogueRunner |
| dialogue.md | `dialogue_ended` and `dialogue_blocked` signals (Rule 2h/7b) | Declared on EventBus |
| romance-social.md | `romance_stage_changed` signal (Rule 9) | Declared on EventBus, emitted by RomanceSocial |
| poker-combat.md | `combat_completed` signal (Rule 10) | Declared on EventBus, emitted by CombatSystem |
| story-flow.md | Listens for `dialogue_ended` and `combat_completed` | Connects via EventBus |
| companion-data.md | Stage transition emits signal for other systems | `romance_stage_changed` on EventBus |
| divine-blessings.md | Listens for `romance_stage_changed` to unlock slots | Connects via EventBus |
| deck-management.md | `combat_configured` signal to CombatSystem | Local signal on DeckManager (NOT EventBus — scene-local per ADR-0014) |
| camp.md | Responds to `tokens_reset` for midnight refresh | Connects via EventBus |

## Performance Implications

- **CPU**: Signal emit + dispatch: <0.01ms per signal. Negligible.
- **Memory**: ~30 signal declarations: <1KB.
- **Load Time**: None — EventBus loads in `_ready()` with no I/O.

## Migration Plan

No existing EventBus. Create from scratch. Current prototype code uses direct signal connections — refactor emitters to use `EventBus.[signal].emit()` and listeners to `EventBus.[signal].connect()`.

## Validation Criteria

1. **Integration test**: DialogueRunner emits `relationship_changed` → RomanceSocial receives it and updates GameStore.
2. **Integration test**: CombatSystem emits `combat_completed` → StoryFlow receives it and advances node.
3. **Grep audit**: `grep -r "change_scene_to_file\|\.connect.*DialogueRunner\|\.connect.*CombatSystem" src/` — must return 0 results outside EventBus connections (no direct cross-system imports).
4. **Unit test**: EventBus can be instantiated in a test scene with no errors and all signals are accessible.

## Related Decisions

- ADR-0001: GameStore — state mutations triggered by EventBus signals are written through GameStore
- ADR-0003: Scene Management — `scene_changed` signal is on SceneManager directly (local, not EventBus), since it's Foundation-to-Foundation
- `docs/architecture/architecture.md` — Architecture Principle #3: Layer Isolation
