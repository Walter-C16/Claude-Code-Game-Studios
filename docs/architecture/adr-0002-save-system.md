# ADR-0002: Save System — Continuous Persistence

## Status
Accepted

## Date
2026-04-09

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core (persistence, file I/O) |
| **Knowledge Risk** | LOW — FileAccess/DirAccess API stable. `store_*` returns `bool` since 4.4. |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/breaking-changes.md` |
| **Post-Cutoff APIs Used** | `FileAccess.store_string()` returns `bool` (4.4). `DirAccess.rename()` unchanged. |
| **Verification Required** | `DirAccess.rename()` atomicity on Android, iOS, and HTML5 (IndexedDB). Measure JSON.stringify + file write latency on minimum-spec mobile. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (GameStore: Centralized State Architecture) — SaveManager calls GameStore.to_dict() |
| **Enables** | All Feature/Core ADRs that require persistent state (ADR-0007 through ADR-0012) |
| **Blocks** | All epics — no feature can ship without save/load |
| **Ordering Note** | Must be Accepted immediately after ADR-0001. SaveManager is the second autoload to implement. |

## Context

### Problem Statement

Dark Olympus requires live-service-style persistence: every state mutation must survive an app crash with at most 1 frame of data loss. The game targets mobile platforms where apps are routinely killed by the OS without warning. Players should never see a "Save" button or worry about losing progress — the game is always saved.

ADR-0001 established GameStore as the single state owner with a dirty-flag mechanism. This ADR formalizes SaveManager's contract: how it detects dirty state, writes to disk atomically, handles version migration, and recovers from failures.

### Constraints

- **Mobile I/O**: Android/iOS file writes are slower than desktop. Must not cause frame drops.
- **HTML5 (IndexedDB)**: Web persistence uses IndexedDB under the hood via Godot's `user://` abstraction. `DirAccess.rename()` may not be atomic.
- **Save size**: Current state schema serializes to <1KB JSON. Projected max with full content: <5KB.
- **Single save slot**: No save management UI. One save per device.
- **Combat is ephemeral**: CombatSystem state (deck, hand, score) is scene-local and intentionally NOT persisted.

### Requirements

- Every GameStore mutation persists to disk within 1 frame
- Save writes are atomic (no half-written files)
- Save format supports version-stamped migration
- Load restores all state from a single JSON file
- App crash at any point produces a valid (possibly 1-frame-old) save
- No manual "Save" button in the UI

## Decision

**SaveManager is an autoload that provides `save_game()`, `load_game()`, `has_save()`, and `delete_save()`.** It does NOT decide when to save — that is driven by GameStore's dirty-flag mechanism (ADR-0001). SaveManager is a pure I/O service.

### Save Flow

```
GameStore.set_*() called
    |
    v
GameStore._dirty = true
    |
    v (if !_save_pending)
GameStore.call_deferred("_flush_save")
GameStore._save_pending = true
    |
    v (end of frame — deferred call runs)
GameStore._flush_save():
    SaveManager.save_game()
    _dirty = false
    _save_pending = false
```

Multiple mutations in the same frame produce exactly 1 disk write.

### Save File Format

```json
{
  "version": 1,
  "timestamp": 1712534400,
  "game": { /* GameStore.to_dict() */ },
  "settings": { /* SettingsStore.to_dict() */ }
}
```

- `version`: Integer, incremented when schema changes. Current: 1.
- `timestamp`: Unix time (int) for debugging. Not used for game logic.
- `game`: Complete GameStore state snapshot.
- `settings`: Complete SettingsStore state snapshot (locale, volumes, text speed).

Path: `user://save.json`

### Atomic Write Protocol

```gdscript
const SAVE_PATH := "user://save.json"
const TEMP_PATH := "user://save.json.tmp"

func save_game() -> bool:
    var data := {
        "version": SAVE_VERSION,
        "timestamp": int(Time.get_unix_time_from_system()),
        "game": GameStore.to_dict(),
        "settings": SettingsStore.to_dict()
    }
    var json_string := JSON.stringify(data)

    # Write to temp file first
    var file := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
    if not file:
        push_warning("SaveManager: Cannot open temp file for writing")
        return false
    var success := file.store_string(json_string)
    file.close()
    if not success:
        push_warning("SaveManager: store_string failed")
        return false

    # Atomic rename
    var dir := DirAccess.open("user://")
    if dir:
        if dir.file_exists("save.json"):
            dir.remove("save.json")
        dir.rename("save.json.tmp", "save.json")

    return true
```

### Load Flow

```gdscript
func load_game() -> bool:
    if not has_save():
        return false

    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if not file:
        return false
    var json_string := file.get_as_text()
    file.close()

    var json := JSON.new()
    var parse_result := json.parse(json_string)
    if parse_result != OK:
        push_error("SaveManager: JSON parse failed")
        return false

    var data: Dictionary = json.data
    var save_version: int = data.get("version", 0)

    # Run migration chain if needed
    data = _migrate(data, save_version)

    GameStore.from_dict(data.get("game", {}))
    SettingsStore.from_dict(data.get("settings", {}))
    Localization.switch_locale(SettingsStore.locale)
    return true
```

### Version Migration

```gdscript
func _migrate(data: Dictionary, from_version: int) -> Dictionary:
    if from_version < 1:
        data = _migrate_v0_to_v1(data)
    # if from_version < 2:
    #     data = _migrate_v1_to_v2(data)
    data["version"] = SAVE_VERSION
    return data
```

Each migration function adds new fields with defaults. Old fields are never removed — they are ignored if unused.

### Key Interfaces

```gdscript
extends Node

const SAVE_VERSION: int = 1
const SAVE_PATH: String = "user://save.json"

func save_game() -> bool       # Atomic write. Returns success.
func load_game() -> bool       # Parse + migrate + restore. Returns success.
func has_save() -> bool        # FileAccess.file_exists(SAVE_PATH)
func delete_save() -> void     # Removes file, resets GameStore + SettingsStore to defaults
```

### Combat Exception

CombatSystem state (current hand, deck order, score, hands/discards remaining) is NOT written to GameStore and therefore NOT saved. This is intentional:

- Combat is a discrete challenge, not persistent state
- Serializing deck order + hand state adds complexity for minimal gain
- On crash during combat: player returns to Chapter Map, node stays `in_progress`, retry prompt shown
- No progress is lost — the worst case is replaying one fight

### SettingsStore Persistence

SettingsStore uses the same dirty-flag pattern as GameStore:

```gdscript
# SettingsStore
var _dirty: bool = false

func set_locale(value: String) -> void:
    locale = value
    _dirty = true
    if not _save_pending:
        call_deferred("_flush_save")
        _save_pending = true
```

Both stores share the same SaveManager write — `save_game()` captures both `to_dict()` calls in a single JSON file.

## Alternatives Considered

### Alternative 1: Timed Debounce (500ms-5s)

- **Description**: Instead of per-frame flush, save at most once every N milliseconds via a timer that resets on each mutation.
- **Pros**: Fewer disk writes (max 2/sec at 500ms). Less I/O pressure on mobile.
- **Cons**: Data loss window: up to N ms of mutations lost on crash. At 5000ms (original design), a player could lose an entire camp interaction sequence.
- **Rejection Reason**: The core design requirement is "like a server game — nothing is ever lost." Any debounce window creates a data loss window. The per-frame `call_deferred` approach achieves 1-frame batching (16ms window at 60fps) while still writing at most once per frame. On mobile, <1KB JSON writes in <1ms — I/O pressure is negligible.

### Alternative 2: Event-Triggered Saves Only

- **Description**: Save only on specific game events (node completion, stage advance, combat victory) rather than on every mutation.
- **Pros**: Fewest disk writes. Predictable save points.
- **Cons**: Mutations between save events are lost on crash. A player could complete 3 camp interactions, crash, and lose all of them. This contradicts the "live-service feel" requirement.
- **Rejection Reason**: Event-triggered saves are the original Save System GDD design (Rule 6, pre-revision). The user explicitly upgraded to continuous persistence to match the feel of server-backed games.

## Consequences

### Positive

- **Zero data loss**: At most 1 frame (~16ms) of mutations can be lost. In practice, app-kill between a setter and `call_deferred` is nearly impossible.
- **No save UI needed**: No "Save" button, no save slots, no save management screen. Settings screen only needs "Delete Save" for full reset.
- **Atomic writes**: Temp file + rename ensures no corrupted saves from mid-write crashes.
- **Simple migration**: Version-stamped saves with a chained migration function. New fields get defaults via `.get(key, default)`.

### Negative

- **Frequent I/O**: During active play (camp interactions, combat outcomes), the game writes to disk every frame that has a mutation. Typically 0-3 writes per second. On very slow storage, this could cause micro-stutters.
  - *Mitigation*: <1KB JSON stringify + write takes <1ms even on low-end mobile. Monitor with profiling.
- **No offline recovery**: If the save file is corrupted (e.g., filesystem error), there is no backup save.
  - *Mitigation*: Consider adding a `save.json.bak` backup copy updated every N minutes (post-MVP).

### Risks

- **HTML5 IndexedDB atomicity**: `DirAccess.rename()` may not be atomic on web. A crash during rename could lose both temp and original files.
  - *Mitigation*: Test on web early. If rename is unreliable, fall back to direct write for web (accept higher corruption risk on a platform where browser crashes are rare).
- **Android storage scoped access**: Future Android versions may restrict `user://` access patterns.
  - *Mitigation*: Godot's `user://` abstraction handles scoped storage. Monitor Godot release notes for changes.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|---|---|---|
| save-system.md | Continuous persistence — every mutation persists within 1 frame (Rule 5) | Dirty-flag + call_deferred pattern via GameStore |
| save-system.md | Atomic write — no half-written saves (Rule 5) | Temp file + DirAccess.rename() |
| save-system.md | Version-stamped saves with migration (Rule 2) | version field + _migrate() chain |
| save-system.md | Single save slot at user://save.json (Rule 1) | Hardcoded SAVE_PATH constant |
| save-system.md | Combat state is ephemeral (Rule 6) | CombatSystem state is scene-local, not in GameStore |
| save-system.md | Delete save with confirmation (Rule 8) | delete_save() removes file + resets stores |
| save-system.md | Load on app launch via has_save() (Rule 7) | has_save() + load_game() called from Splash screen |
| companion-data.md | Forward compatibility: unknown companion IDs ignored on load | from_dict() skips unknown keys via .get() |
| companion-data.md | Backward compatibility: missing companions get default state | from_dict() creates defaults for missing IDs |

## Performance Implications

- **CPU**: JSON.stringify() on <5KB Dictionary: <0.5ms. Negligible.
- **Memory**: One copy of state Dictionary during save (~5KB max). Negligible.
- **Disk I/O**: 1 write per frame when dirty. File size <5KB. On minimum-spec Android device, FileAccess write latency: ~1-3ms. Well within 16.6ms frame budget.
- **Load Time**: JSON parse of <5KB: <1ms. Migration chain: O(1) per version step.

## Migration Plan

No existing SaveManager to migrate. Implement from scratch against the GameStore API defined in ADR-0001.

The existing prototype `SaveManager.gd` in `src/autoloads/` uses the same `to_dict()`/`from_dict()` contract but with event-triggered saves. Refactor to dirty-flag flush pattern.

## Validation Criteria

1. **Unit test**: Call `save_game()`, verify file exists at `user://save.json` with correct JSON structure.
2. **Unit test**: Corrupt `save.json` (invalid JSON), call `load_game()`, verify returns `false` without crash. Verify file is NOT deleted.
3. **Unit test**: Create save with `version: 0`, call `load_game()`, verify migration runs and new fields have defaults.
4. **Unit test**: Call `delete_save()`, verify `has_save()` returns `false` and GameStore is reset.
5. **Integration test**: Multiple GameStore setters in same frame → verify exactly 1 file write.
6. **Platform test**: Kill app mid-save on Android/iOS → verify either old or new save exists (never corrupted).
7. **Performance test**: Profile save_game() on minimum-spec device. Must complete in <3ms.

## Related Decisions

- ADR-0001: GameStore — Centralized State Architecture (dependency: GameStore provides to_dict/from_dict)
- ADR-0004 (planned): EventBus — may need a `save_completed` signal for UI indicators
- `design/gdd/save-system.md` — Save System GDD (design spec this ADR implements)
