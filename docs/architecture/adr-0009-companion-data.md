# ADR-0009: Companion Data — Registry + State Schema

## Status
Accepted

## Date
2026-04-09

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core (data architecture) |
| **Knowledge Risk** | LOW — Dictionary/Array operations, file loading. No post-cutoff APIs. |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (GameStore: stores mutable companion state), ADR-0005 (Localization: companion display names) |
| **Enables** | ADR-0010 (Romance: reads/writes companion state), ADR-0012 (Blessings: reads romance_stage + element), ADR-0007 (Combat: reads STR/INT for captain bonus) |
| **Blocks** | All companion-related epics |
| **Ordering Note** | Core layer. Most-depended-on system — 10 downstream systems consume this data. |

## Context

### Problem Statement

Every system in Dark Olympus references companion data. Poker Combat reads STR/INT for captain bonuses. Dialogue reads portraits and moods. Romance & Social reads/writes relationship state. Blessings reads romance_stage. The companion data layer must be clean enough to serve 10+ consumers without creating circular dependencies or ownership conflicts.

The key architectural question: should CompanionData be one module or two? Static profiles (immutable identity: name, stats, element) vs. mutable state (relationship_level, mood, met) have very different lifecycles — one is loaded once from data files, the other is read/written constantly and persisted.

### Requirements

- 4 companion profiles + 1 NPC (priestess)
- Static profile fields: id, display_name, role, element, STR, INT, AGI, card_value, starting_location, portrait_path_base
- Mutable state fields: relationship_level, trust, motivation, romance_stage, dates_completed, met, known_likes, known_dislikes, current_mood, mood_expiry_date
- romance_stage derived from relationship_level thresholds [0, 21, 51, 71, 91] — never decreases
- Portrait path: `res://assets/images/companions/{id}/{id}_{mood}.png` (6 moods)
- All mutable state persisted via GameStore (ADR-0001)

## Decision

**Two modules: CompanionRegistry (static, autoload) + CompanionState (logic, non-autoload).**

### CompanionRegistry (Autoload — static data, loaded once)

Holds immutable companion profiles loaded from `res://assets/data/companions.json` at boot. Read-only. No writes. No signals. Pure data lookup.

```gdscript
extends Node

var _profiles: Dictionary = {}  # id → profile dict

func _ready() -> void:
    _load_profiles("res://assets/data/companions.json")

func get_profile(id: String) -> Dictionary:
    return _profiles.get(id, {})

func get_all_ids() -> Array[String]:
    return _profiles.keys()

func get_portrait_path(id: String, mood: String) -> String:
    var base: String = _profiles[id].portrait_path_base
    return "%s/%s_%s.png" % [base, id, mood]

func get_element_for_suit(suit: String) -> String:
    # Hearts=Fire, Diamonds=Water, Clubs=Earth, Spades=Lightning
    return {"Hearts": "Fire", "Diamonds": "Water",
            "Clubs": "Earth", "Spades": "Lightning"}.get(suit, "")
```

### CompanionState (Non-autoload — logic layer over GameStore)

Provides typed access and derived values on top of GameStore's raw companion state. This is NOT an autoload — it's a class that systems instantiate or reference. All reads/writes go through GameStore.

```gdscript
class_name CompanionState
extends RefCounted

const STAGE_THRESHOLDS: Array[int] = [0, 21, 51, 71, 91]

static func get_romance_stage(companion_id: String) -> int:
    var rl := GameStore.get_relationship_level(companion_id)
    var stage := 0
    for i in range(STAGE_THRESHOLDS.size()):
        if rl >= STAGE_THRESHOLDS[i]:
            stage = i
    return stage

static func set_relationship_level(companion_id: String, value: int) -> void:
    var clamped := clampi(value, 0, 100)
    var old_stage := get_romance_stage(companion_id)
    GameStore.set_relationship_level(companion_id, clamped)
    var new_stage := get_romance_stage(companion_id)
    if new_stage > old_stage:
        EventBus.romance_stage_changed.emit(companion_id, old_stage, new_stage)

static func is_met(companion_id: String) -> bool:
    return GameStore.get_companion_state(companion_id).get("met", false)
```

**Why not an autoload?** CompanionState has no persistent state of its own — it's a logic layer over GameStore. Making it a `RefCounted` class with static methods keeps the autoload count minimal and makes the dependency explicit (callers import `CompanionState` by class name).

### Data Format (companions.json)

```json
{
  "artemisa": {
    "display_name_key": "COMP_ARTEMISA",
    "role": "Goddess of the Hunt",
    "element": "Earth",
    "str": 17, "int": 13, "agi": 20,
    "card_value": 13,
    "starting_location": "base_camp",
    "portrait_path_base": "res://assets/images/companions/artemisa"
  },
  "hipolita": { ... },
  "atenea": { ... },
  "nyx": { ... },
  "priestess": {
    "display_name_key": "COMP_PRIESTESS",
    "role": "Gaia Fragment (NPC)",
    "element": "None",
    "portrait_path_base": "res://assets/images/npcs/priestess"
  }
}
```

### Architecture Diagram

```
CompanionRegistry (autoload, read-only)
    │  ← loaded once from companions.json
    │  ← queried by: Dialogue, Combat, Deck, Camp, Story Flow
    │
CompanionState (RefCounted, static methods)
    │  ← reads/writes GameStore companion fields
    │  ← used by: RomanceSocial, Story Flow, Blessings, Camp
    │  ← emits: romance_stage_changed via EventBus
    │
GameStore (autoload, ADR-0001)
    │  ← owns all mutable companion data
    │  ← persisted by SaveManager
```

## Alternatives Considered

### Alternative 1: Single CompanionManager Autoload

- **Description**: One autoload holds both static profiles AND mutable state logic. Single entry point for all companion queries.
- **Pros**: One import for everything. Simpler mental model.
- **Cons**: Mixes immutable data with mutable state logic. The autoload grows large (profile lookup + state mutation + stage derivation + mood management). Harder to test — can't test profile lookup without GameStore.
- **Rejection Reason**: Separation of concerns. CompanionRegistry is pure data (testable with no dependencies). CompanionState is logic over GameStore (testable with a mock GameStore). Combining them couples data loading to state management.

### Alternative 2: CompanionState as Autoload

- **Description**: Make CompanionState an autoload instead of a RefCounted class.
- **Pros**: Globally accessible without import. Consistent with other systems.
- **Cons**: Adds autoload #9 to boot order. CompanionState has no state of its own — it's a pure logic layer over GameStore. Making it an autoload suggests it owns something.
- **Rejection Reason**: Autoloads should own persistent state or provide infrastructure. CompanionState is a helper class — `static` methods on a `RefCounted` keep it lightweight and explicit.

## Consequences

### Positive

- **Clear ownership split**: CompanionRegistry owns identity. GameStore owns state. CompanionState is the logic bridge.
- **10 consumers served cleanly**: Systems that only need profiles (Dialogue, Combat) import CompanionRegistry. Systems that need mutable state (Romance, Camp) import CompanionState. No system needs both unless it does both.
- **Testable**: CompanionRegistry is testable with just a JSON file. CompanionState is testable with a mock GameStore.

### Negative

- **Two imports instead of one**: A system that needs both profile and state must import both CompanionRegistry and CompanionState. Mitigation: most systems need only one or the other.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|---|---|---|
| companion-data.md | 4 companions + 1 NPC with static profiles (Registry) | CompanionRegistry loaded from companions.json |
| companion-data.md | Mutable state: RL, trust, mood, met, etc. (State Record) | GameStore fields accessed via CompanionState |
| companion-data.md | romance_stage derived, never decreasing (Rule 3) | CompanionState.get_romance_stage() + set_relationship_level() guards |
| companion-data.md | Portrait paths: {id}_{mood}.png (Portrait System) | CompanionRegistry.get_portrait_path() |
| companion-data.md | romance_stage_changed signal on stage advance | CompanionState.set_relationship_level() emits via EventBus |
| companion-data.md | Forward/backward save compatibility | GameStore.from_dict() creates defaults for missing companions |

## Performance Implications

- **CPU**: Dictionary lookup O(1). Stage derivation: 5 comparisons. Negligible.
- **Memory**: 5 profiles (~2KB). Static, loaded once.

## Migration Plan

Existing `CompanionData.gd` autoload combines profiles and state. Split into CompanionRegistry (autoload, profiles only) + CompanionState (RefCounted, state logic). Move state fields to GameStore.

## Validation Criteria

1. **Unit test**: `CompanionRegistry.get_profile("artemisa")` returns correct STR/INT/element.
2. **Unit test**: `CompanionState.get_romance_stage("artemisa")` at RL=55 returns 2.
3. **Unit test**: `CompanionState.set_relationship_level("artemisa", 25)` at RL=20 triggers `romance_stage_changed(0→1)`.
4. **Unit test**: RL set to 15 after stage 1 achieved → stage remains 1 (never decreases).
5. **Unit test**: `CompanionRegistry.get_portrait_path("hipolita", "angry")` returns correct path.

## Related Decisions

- ADR-0001: GameStore — owns companion mutable state
- ADR-0004: EventBus — romance_stage_changed signal
- ADR-0007: Poker Combat — reads STR/INT via CompanionRegistry
- ADR-0008: Dialogue — reads portraits/mood via CompanionRegistry
- `design/gdd/companion-data.md` — complete design spec
