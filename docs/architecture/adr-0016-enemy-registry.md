# ADR-0016: EnemyRegistry — Static Enemy Data Autoload

## Status
Accepted

## Date
2026-04-09

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core / Data |
| **Knowledge Risk** | LOW — pure GDScript Dictionary/JSON; no post-cutoff APIs |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/breaking-changes.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (GameStore — element enum definition), ADR-0005 (Localization — name_key resolution) |
| **Enables** | None |
| **Blocks** | Poker Combat epic (combat cannot configure encounters without enemy profiles), Story Flow epic (chapter nodes reference enemy IDs) |
| **Ordering Note** | Must be implemented after Localization (autoload #4) and before any combat or story implementation |

## Context

### Problem Statement
EnemyRegistry is listed as autoload #8 in ADR-0006 and is consumed by both Poker Combat (ADR-0007) and Story Flow (ADR-0011), but no ADR defines its data schema, public interface, file format, or validation rules. The architecture review identified 4 uncovered technical requirements (TR-enemy-data-001 through -005) and 3 partial requirements. Without this ADR, implementers must reverse-engineer the contract from the GDD, risking inconsistent interpretation.

### Constraints
- Must be read-only — enemy profiles are static data, not mutable game state
- Must load before any combat or story system initializes
- Enemy display names must resolve through Localization, not be stored as raw strings
- Element enum values must match the shared enum from CompanionData (ADR-0009)
- Data-driven: no hardcoded enemy stats in combat or story logic

### Requirements
- Provide typed lookup by enemy ID within 1ms (TR-enemy-data-007)
- Support chapter-based filtering for story progression
- Validate data integrity at load time (TR-enemy-data-005)
- Derive attack values from HP using configurable ratio (TR-enemy-data-004)
- All enemy values externalized in JSON config (TR-enemy-data-006)

## Decision

EnemyRegistry is a **GDScript autoload** (boot position #8) that loads enemy profiles from a single JSON file at startup and exposes them through typed getter methods. It owns no mutable state and serves as a pure read-only data layer.

### Data File

Enemy profiles live at `res://assets/data/enemies.json`:

```json
{
  "enemies": [
    {
      "id": "forest_monster",
      "name_key": "ENEMY_FOREST_MONSTER",
      "hp": 40,
      "score_threshold": 40,
      "element": null,
      "chapter": "chapter_1",
      "context": "Prologue tutorial",
      "type": "Normal",
      "portrait_key": "forest_monster"
    }
  ],
  "config": {
    "ATTACK_RATIO": 0.1
  }
}
```

### Architecture Diagram

```
                    ┌─────────────────────────┐
                    │   enemies.json           │
                    │   (res://assets/data/)   │
                    └──────────┬──────────────┘
                               │ load at _ready()
                    ┌──────────▼──────────────┐
                    │     EnemyRegistry        │
                    │     (Autoload #8)        │
                    │                          │
                    │  _enemies: Dictionary     │
                    │  {id -> enemy_profile}    │
                    │                          │
                    │  ATTACK_RATIO: float      │
                    └──┬───────────┬───────────┘
                       │           │
          get_enemy()  │           │  get_enemies_by_chapter()
                       │           │
            ┌──────────▼──┐  ┌────▼──────────┐
            │ Poker Combat│  │  Story Flow   │
            │  (ADR-0007) │  │  (ADR-0011)   │
            └─────────────┘  └───────────────┘
```

### Key Interfaces

```gdscript
# enemy_registry.gd — Autoload #8
extends Node

## Typed enemy profile dictionary keys:
## id: String, name_key: String, hp: int, score_threshold: int,
## element: Variant (String or null), chapter: String, context: String,
## type: String, attack: int, portrait_key: String

var _enemies: Dictionary = {}  # {String id -> Dictionary profile}
var _attack_ratio: float = 0.1

func _ready() -> void:
    _load_enemies()

## Returns enemy profile by ID, or empty Dictionary if not found.
func get_enemy(id: String) -> Dictionary:
    return _enemies.get(id, {})

## Returns true if enemy ID exists in registry.
func has_enemy(id: String) -> bool:
    return _enemies.has(id)

## Returns all enemy profiles as Array[Dictionary].
func get_all_enemies() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for profile in _enemies.values():
        result.append(profile)
    return result

## Returns enemy profiles for a specific chapter.
func get_enemies_by_chapter(chapter: String) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for profile in _enemies.values():
        if profile.get("chapter", "") == chapter:
            result.append(profile)
    return result

## Returns enemy display name via Localization.
func get_enemy_name(id: String) -> String:
    var profile := get_enemy(id)
    if profile.is_empty():
        return id  # fallback to raw ID
    return Localization.get_text(profile["name_key"])
```

### EnemyType Constants

```gdscript
# Constants for type checking (not a formal enum — matches GDD string values)
const TYPE_NORMAL := "Normal"
const TYPE_BOSS := "Boss"
const TYPE_DUEL := "Duel"
const TYPE_ABYSS := "Abyss"
```

### Data Validation (at load time)

```gdscript
func _validate_enemy(profile: Dictionary) -> Dictionary:
    # Clamp score_threshold to hp (TR-enemy-data-005)
    if profile["score_threshold"] > profile["hp"]:
        push_warning("EnemyRegistry: %s score_threshold (%d) > hp (%d), clamping" %
            [profile["id"], profile["score_threshold"], profile["hp"]])
        profile["score_threshold"] = profile["hp"]

    # Warn on invalid HP
    if profile["hp"] <= 0:
        push_error("EnemyRegistry: %s has hp <= 0, will be instant victory" % profile["id"])

    # Validate element
    var valid_elements := ["Fire", "Water", "Earth", "Lightning"]
    if profile.get("element") != null and profile["element"] not in valid_elements:
        push_warning("EnemyRegistry: %s invalid element '%s', defaulting to null" %
            [profile["id"], profile["element"]])
        profile["element"] = null

    # Validate type
    var valid_types := ["Normal", "Boss", "Duel", "Abyss"]
    if profile.get("type", "") not in valid_types:
        push_warning("EnemyRegistry: %s invalid type '%s', defaulting to Normal" %
            [profile["id"], profile["type"]])
        profile["type"] = "Normal"

    # Derive attack (TR-enemy-data-004)
    profile["attack"] = int(floor(profile["hp"] * _attack_ratio))

    return profile
```

## Alternatives Considered

### Alternative 1: Godot Resource (.tres) Files Per Enemy
- **Description**: Each enemy as a custom Resource subclass (`EnemyProfile.gd extends Resource`) saved as `.tres` files, loaded via `preload()` or `ResourceLoader`
- **Pros**: Type-safe properties via `@export`; inspector-editable; Godot-native
- **Cons**: 20+ individual files vs one JSON; harder to diff in git; Resource serialization adds overhead for what is flat data; breaks the JSON-based data pipeline established by ADR-0008 (dialogue) and ADR-0011 (story flow)
- **Rejection Reason**: Inconsistent with the project's JSON data convention. The overhead of Resource subclasses is not justified for a flat, read-only table of ~20 entries.

### Alternative 2: Inline Dictionaries in GDScript
- **Description**: Enemy profiles hardcoded as `const ENEMIES := {...}` in the autoload script
- **Pros**: Zero load time; no file I/O; simplest implementation
- **Cons**: Violates "all values data-driven" coding standard; makes balance tweaking require code changes; inconsistent with the data-driven approach used by every other system
- **Rejection Reason**: Directly violates TR-enemy-data-006 and project coding standards.

## Consequences

### Positive
- Closes 4 architecture gaps and 3 partial coverage items from the architecture review
- Consistent with CompanionRegistry pattern (ADR-0009) — same autoload + Dictionary + JSON approach
- Unblocks Poker Combat and Story Flow implementation
- Single source of truth for enemy data — no more implicit contracts

### Negative
- One more JSON file to maintain (minor — only ~20 entries for full game)
- Attack field is derived and currently unused (forward-compatible, low cost)

### Risks
- **Risk**: Enemy JSON file missing or malformed at startup
  - **Mitigation**: `_ready()` logs error and initializes empty registry; combat falls back to inline `enemy_config` from story nodes (existing pattern per GDD edge case)
- **Risk**: Element string values drift from CompanionData enum
  - **Mitigation**: Validation uses the same string constants; future refactor could extract shared Element enum to a common constants file

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| enemy-data.md | TR-enemy-data-001: Enemy registry schema | Defines full JSON schema and Dictionary structure with all 10 fields |
| enemy-data.md | TR-enemy-data-002: Names via Localization keys | `get_enemy_name()` delegates to `Localization.get_text()`; raw key fallback |
| enemy-data.md | TR-enemy-data-003: Enemy type enum | TYPE_NORMAL/BOSS/DUEL/ABYSS constants with load-time validation |
| enemy-data.md | TR-enemy-data-004: Attack derivation formula | `floor(hp * ATTACK_RATIO)` computed at load time; ATTACK_RATIO from JSON config |
| enemy-data.md | TR-enemy-data-005: Data validation (clamp, hp<=0) | `_validate_enemy()` runs per-profile at load with warnings/errors |
| enemy-data.md | TR-enemy-data-006: All values data-driven | External `enemies.json` — no hardcoded stats in code |
| enemy-data.md | TR-enemy-data-007: Lookup within 1ms | Dictionary.get() is O(1); well under 1ms for ~20 entries |

## Performance Implications
- **CPU**: Negligible — one-time JSON parse at boot (~1ms for 20 entries); O(1) lookups thereafter
- **Memory**: ~5-10 KB for 20 enemy profiles in Dictionary form
- **Load Time**: <5ms total (JSON parse + validation + attack derivation)
- **Network**: N/A

## Migration Plan
No existing code to migrate. This is a new autoload. Implementation order:
1. Create `res://assets/data/enemies.json` with Chapter 1 enemy data
2. Create `src/autoloads/enemy_registry.gd`
3. Register as autoload #8 in `project.godot` (after Localization, before any consumer)
4. Update ADR-0006 boot order to include EnemyRegistry formally

## Validation Criteria
- Unit tests verify all 4 Chapter 1 enemies load with correct values
- Unit test: score_threshold > hp gets clamped
- Unit test: hp <= 0 returns valid profile (instant victory)
- Unit test: invalid element defaults to null
- Unit test: `get_enemies_by_chapter("chapter_1")` returns exactly 4 entries
- Unit test: `get_enemy("nonexistent")` returns empty Dictionary
- Performance: registry load completes within 5ms in headless test

## Related Decisions
- ADR-0001: GameStore — element enum definition
- ADR-0005: Localization — name_key resolution
- ADR-0006: Boot Order — EnemyRegistry is autoload #8
- ADR-0007: Poker Combat — primary consumer of enemy profiles
- ADR-0009: CompanionData — architectural pattern this ADR mirrors
- ADR-0011: Story Flow — references enemy IDs in chapter nodes
