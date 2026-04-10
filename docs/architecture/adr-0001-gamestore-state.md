# ADR-0001: GameStore — Centralized State Architecture

## Status
Accepted

## Date
2026-04-09

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core (state management) |
| **Knowledge Risk** | LOW — Dictionary/Array APIs stable since 4.0 |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/breaking-changes.md`, `docs/engine-reference/godot/deprecated-apis.md` |
| **Post-Cutoff APIs Used** | `FileAccess.store_string()` returns `bool` since 4.4 (was void). Must check return value. |
| **Verification Required** | Verify `DirAccess.rename()` is atomic on Android, iOS, and Web (HTML5 IndexedDB). Test save corruption resilience on each target platform. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None (first ADR, Foundation layer) |
| **Enables** | ADR-0002 (Save System: Continuous Persistence), ADR-0004 (EventBus), all Core/Feature ADRs |
| **Blocks** | All epics — no implementation can begin without the state architecture |
| **Ordering Note** | Must be Accepted before any other ADR, as every system reads/writes through GameStore |

## Context

### Problem Statement

Dark Olympus has 13 designed systems that collectively produce, read, and modify ~40 distinct pieces of mutable game state (companion relationships, story flags, gold, combat buffs, moods, streaks, etc.). Without a centralized authority for this state, each system would own its own data, creating: (1) save/load complexity (serialize N separate sources), (2) state desync (two systems disagree on a value), (3) circular import dependencies (System A imports System B to read its state, and vice versa).

The game requires continuous persistence — every state mutation must survive an app crash within 1 frame. This demands a single serialization point that knows about all mutable state.

### Constraints

- **Single-threaded GDScript**: No concurrent access concerns within a frame, but deferred calls may interleave between frames.
- **Mobile targets**: File I/O is slow. Minimize write frequency while guaranteeing no data loss.
- **Save migration**: Content updates (Chapter 2+) will add new state fields. The state schema must support forward/backward compatibility.
- **13 consumer systems**: The API must be simple enough that every system uses it consistently, not just the ones the author remembers to wire up.

### Requirements

- All mutable game state accessible via a single autoload
- Any mutation triggers persistence within 1 frame (continuous save)
- Serialization to/from Dictionary for JSON save format
- Forward/backward compatibility for save schema changes
- No system may maintain parallel mutable state — GameStore is the sole writer/owner

## Decision

**GameStore is a single autoload (`Node`) that holds all mutable game state as typed properties organized into logical groups.** Every gameplay system reads and writes state exclusively through GameStore's public API. No system maintains its own persistent state.

### Architecture

```
+----------------------------------------------------------+
|  GameStore (Autoload — Node)                              |
|                                                          |
|  Companion State (per-companion Dictionary):             |
|    relationship_level, trust, motivation,                 |
|    dates_completed, met, known_likes, known_dislikes,    |
|    current_mood, mood_expiry_date                        |
|                                                          |
|  Story State:                                            |
|    story_flags: Array[String]                            |
|    node_states: Dictionary  {node_id: state_string}      |
|    current_chapter: String                               |
|                                                          |
|  Economy:                                                |
|    player_gold: int                                      |
|    player_xp: int                                        |
|                                                          |
|  Romance State:                                          |
|    daily_tokens_remaining: int                           |
|    current_streak: int                                   |
|    last_interaction_date: String (UTC date)              |
|                                                          |
|  Combat Buff:                                            |
|    active_combat_buff: Dictionary                        |
|      {chips: int, mult: float, combats_remaining: int}   |
|                                                          |
|  Captain:                                                |
|    last_captain_id: String                               |
|                                                          |
|  Internal:                                               |
|    _dirty: bool = false                                  |
|    _save_pending: bool = false                           |
+----------------------------------------------------------+
         |                    |
    [set_*() marks          [to_dict() / from_dict()
     _dirty = true,          called by SaveManager
     schedules flush]        for persistence]
```

### Persistence Mechanism (Dirty-Flag with Deferred Flush)

Every setter method:
1. Validates and applies the value
2. Sets `_dirty = true`
3. If `!_save_pending`: calls `call_deferred("_flush_save")` and sets `_save_pending = true`

`_flush_save()` runs at the end of the current frame:
1. Calls `SaveManager.save_game()` (which reads `to_dict()`)
2. Sets `_dirty = false`, `_save_pending = false`

This naturally batches all mutations in a single frame into one write. If 5 setters fire in the same frame, only 1 disk write occurs.

### Atomic Write Protocol

SaveManager writes via temp file + rename (NOT direct overwrite):

```gdscript
func save_game() -> bool:
    var data := {
        "version": SAVE_VERSION,
        "timestamp": int(Time.get_unix_time_from_system()),
        "game": GameStore.to_dict(),
        "settings": SettingsStore.to_dict()
    }
    var json_string := JSON.stringify(data)
    var temp_path := SAVE_PATH + ".tmp"

    var file := FileAccess.open(temp_path, FileAccess.WRITE)
    if not file:
        return false
    var success := file.store_string(json_string)  # returns bool since 4.4
    file.close()
    if not success:
        return false

    var dir := DirAccess.open("user://")
    if dir:
        dir.rename(temp_path, SAVE_PATH)
    return true
```

This ensures: either the old save or the new save exists on disk, never a half-written file.

### Key Interfaces

```gdscript
extends Node

# ── Signals ──
signal state_changed(key: String)

# ── Companion State ──
func get_companion_state(id: String) -> Dictionary
func get_relationship_level(id: String) -> int
func set_trust(id: String, value: int) -> void
func set_met(id: String, value: bool) -> void

# INTERNAL — only CompanionState (ADR-0009) may call these:
func _set_relationship_level(id: String, value: int) -> void
# CompanionState.set_relationship_level() wraps this with clamping,
# stage derivation, and romance_stage_changed signal emission.
# Direct callers would bypass signal emission — DO NOT make public.
# romance_stage is derived by CompanionState, NOT GameStore.

# ── Story State ──
func get_story_flags() -> Array[String]
func has_flag(flag: String) -> bool
func set_flag(flag: String) -> void  # write-once, idempotent
func get_node_state(node_id: String) -> String
func set_node_state(node_id: String, state: String) -> void

# ── Economy ──
func get_gold() -> int
func add_gold(amount: int) -> void
func spend_gold(amount: int) -> bool  # false if insufficient

# ── Combat Buff ──
func get_combat_buff() -> Dictionary
func set_combat_buff(buff: Dictionary) -> void
func clear_combat_buff() -> void

# ── Romance ──
func get_daily_tokens() -> int
func spend_token() -> void
func reset_tokens() -> void
func get_streak() -> int
func set_streak(days: int) -> void

# ── Mood ──
func get_mood(id: String) -> int
func set_mood(id: String, mood: int, expiry: String) -> void

# ── Captain ──
func get_last_captain_id() -> String
func set_last_captain_id(id: String) -> void

# ── Serialization ──
func to_dict() -> Dictionary
func from_dict(data: Dictionary) -> void  # does NOT set _dirty

# ── Internal ──
func _flush_save() -> void  # called via call_deferred, not directly
```

### Initialization

On fresh save (no save file exists):
```gdscript
func _initialize_defaults() -> void:
    for id in ["artemisa", "hipolita", "atenea", "nyx"]:
        _companion_states[id] = {
            "relationship_level": 0, "trust": 0, "motivation": 50,
            # romance_stage: DERIVED by CompanionState.get_romance_stage() — not stored here
            "dates_completed": 0, "met": false,
            "known_likes": [], "known_dislikes": [],
            "current_mood": 0, "mood_expiry_date": ""
        }
    _story_flags = []
    _node_states = {}
    _current_chapter = "ch01"
    _player_gold = 0
    _player_xp = 0
    _daily_tokens_remaining = 3
    _current_streak = 0
    _last_interaction_date = ""
    _active_combat_buff = {}
    _last_captain_id = ""
```

### Save Migration

`from_dict()` handles missing keys with defaults:
```gdscript
func from_dict(data: Dictionary) -> void:
    _player_gold = data.get("player_gold", 0)
    # New fields added in future versions get their default if absent:
    _player_xp = data.get("player_xp", 0)
    # New companions get default state if absent:
    for id in ["artemisa", "hipolita", "atenea", "nyx"]:
        if id not in data.get("companion_states", {}):
            _companion_states[id] = _default_companion_state()
```

## Alternatives Considered

### Alternative 1: Resource Subclasses per Domain

- **Description**: Define `CompanionState extends Resource`, `StoryState extends Resource`, etc. GameStore holds typed Resource properties instead of raw Dictionaries. Use `duplicate_deep()` (4.5+) for safe copies.
- **Pros**: Static typing, editor inspection, cleaner code, compiler validation, more idiomatic Godot.
- **Cons**: More complex JSON round-tripping (Resource serialization requires custom `_get_property_list()` or manual `to_dict()` per Resource). More files. `duplicate_deep()` is post-cutoff (4.5) — needs verification.
- **Rejection Reason**: The game's save format is flat JSON. Resource subclasses add a translation layer between typed properties and JSON without reducing the amount of serialization code. For a solo developer, Dictionary-based state with typed getter/setter wrappers provides the same safety with less ceremony. **Revisit if the team grows or the state schema exceeds ~100 fields.**

### Alternative 2: Distributed Autoloads per Domain

- **Description**: `CompanionStore`, `StoryStore`, `EconomyStore` — each autoload owns its own state slice and implements `to_dict()`/`from_dict()` independently.
- **Pros**: Separation of concerns. Each store is small and focused. Autoloads are already Godot's singleton pattern.
- **Cons**: Save/load must coordinate N autoloads (SaveManager calls `to_dict()` on each, merges, writes). State desync risk: if CompanionStore writes a stage change but StoryStore hasn't flushed, the save is inconsistent. Boot order becomes critical. More autoloads = more Project Settings entries.
- **Rejection Reason**: Continuous persistence (save every frame if dirty) requires a single dirty flag and a single serialization point. Distributing state means distributing the dirty flag, which means either N save calls per frame or a coordinator that polls each store — both add complexity for no gain. Centralized state with a single `to_dict()` is simpler and produces atomic, consistent saves.

### Alternative 3: SQLite Database

- **Description**: Use SQLite (via GDExtension) for structured state storage with transactions.
- **Pros**: ACID transactions guarantee consistency. SQL queries for complex state lookups. Standard tooling.
- **Cons**: Requires a GDExtension addon (not built into Godot). Overkill for ~40 state fields. Adds binary dependency for all 3 target platforms. SQL queries are slower than Dictionary lookups for small datasets.
- **Rejection Reason**: The state schema is small (< 100 fields, < 1KB serialized). A JSON file with atomic writes provides the same data safety without the dependency and complexity overhead.

## Consequences

### Positive

- **Single serialization point**: `to_dict()` captures all game state in one call. Save is always consistent.
- **No state desync**: Every system reads/writes the same source. No "two truths" problem.
- **Simple save migration**: `from_dict()` uses `.get(key, default)` — missing keys get defaults automatically. New fields are added without migration scripts.
- **Testable**: GameStore can be initialized with test data via `from_dict()` without loading a save file.
- **Continuous persistence**: Dirty-flag + `call_deferred` ensures every mutation persists within 1 frame with at most 1 disk write per frame.

### Negative

- **Single point of failure**: If GameStore has a bug, all state is affected. Mitigation: comprehensive unit tests on all getters/setters.
- **Large autoload**: As the game grows, GameStore will have many methods. Mitigation: logical grouping with comments/regions. Consider extracting to Resource subclasses (Alt 1) if it exceeds ~150 methods.
- **No concurrent access**: Single-threaded GDScript makes this safe, but if the project ever moves to multithreaded loading, GameStore would need mutex protection. Mitigation: not needed for MVP; flag if Godot threading is adopted.
- **Internal setters require discipline**: `_set_relationship_level()` is prefixed with underscore but GDScript does not enforce access control. Any system could still call it. Mitigation: code review + grep audit for direct `_set_relationship_level` calls outside CompanionState.

### Risks

- **Mobile I/O performance**: Writing JSON every frame during rapid interactions (e.g., 3 camp interactions in quick succession) could cause micro-stutters on low-end devices. Mitigation: `call_deferred` batches same-frame mutations; worst case is 1 write per frame, and JSON stringify of <1KB data takes <1ms. Monitor with profiling on target hardware.
- **Web (HTML5) persistence**: IndexedDB on web may not support `DirAccess.rename()` atomically. Mitigation: test on web export early; fallback to direct write if rename is not supported (accept the corruption risk on web, which is lower since browser tabs rarely crash).

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|---|---|---|
| companion-data.md | Companion state persists across sessions (Rule 1-2) | All companion fields stored in GameStore, serialized via to_dict() |
| companion-data.md | romance_stage never decreases (Rule 3) | Delegated to CompanionState (ADR-0009) which wraps _set_relationship_level() with stage derivation + max() guard |
| companion-data.md | Forward/backward save compatibility for new companions | from_dict() creates default state for missing companion IDs |
| save-system.md | Continuous persistence — every mutation persists within 1 frame (Rule 5) | Dirty-flag + call_deferred pattern |
| save-system.md | Atomic write (Rule 5) | Temp file + DirAccess.rename() |
| save-system.md | Version-stamped saves with migration (Rule 2) | version field in save dict; from_dict() uses .get(key, default) |
| romance-social.md | Token pool, streak, mood, combat buff persistence | All R&S mutable state stored in GameStore |
| story-flow.md | Story flags are write-once strings (Rule 4) | set_flag() is idempotent — checks existence before adding |
| story-flow.md | Node states persist across sessions (Rule 3) | node_states Dictionary in GameStore |
| poker-combat.md | Combat state is NOT saved mid-fight | Combat state lives in CombatSystem (scene-local), not GameStore |
| deck-management.md | Last-used captain persisted | last_captain_id field in GameStore |

## Performance Implications

- **CPU**: Negligible. Dictionary get/set is O(1). `to_dict()` is O(N) where N = total fields (~40). Under 0.1ms.
- **Memory**: < 10KB for all game state. Insignificant against 512MB mobile budget.
- **Load Time**: JSON parse of <1KB save file: <1ms.
- **Disk I/O**: 1 write per frame when dirty (~60 writes/sec worst case during active play, but `call_deferred` batches to 1 per frame). Each write is <1KB JSON. Well within mobile I/O budget.

## Migration Plan

No existing code to migrate. This is the first ADR — GameStore will be implemented from scratch.

Existing prototype autoloads (`GameStore.gd`, `SettingsStore.gd`) in `src/autoloads/` should be refactored to match this specification. The existing `to_dict()`/`from_dict()` contract is already in place and compatible.

## Validation Criteria

1. **Unit test**: Initialize GameStore with `from_dict()`, verify all getters return expected values.
2. **Unit test**: Call multiple setters in the same frame, verify exactly 1 `save_game()` call occurs.
3. **Unit test**: Set `relationship_level` above a stage threshold, verify `romance_stage` increases. Set RL below threshold, verify stage does NOT decrease.
4. **Unit test**: Call `set_flag("test")` twice, verify `story_flags` contains exactly one "test" entry.
5. **Integration test**: Write save → kill process → reload → verify all state restored.
6. **Platform test**: Verify `DirAccess.rename()` atomicity on Android, iOS, and Web.
7. **Performance test**: Profile `to_dict()` + `JSON.stringify()` on minimum-spec mobile device. Must complete in <2ms.

## Related Decisions

- `docs/architecture/architecture.md` — Master architecture document (defines GameStore's layer and ownership)
- ADR-0002 (planned): Save System: Continuous Persistence — will formalize SaveManager's contract with GameStore
- ADR-0004 (planned): EventBus — will define how state changes are communicated across systems
- `design/gdd/save-system.md` — Save System GDD (defines persistence rules)
- `design/gdd/companion-data.md` — Companion Data GDD (defines state schema)
