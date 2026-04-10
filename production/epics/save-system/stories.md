# Stories: Save System

> **Epic**: Save System
> **Layer**: Foundation
> **Governing ADRs**: ADR-0002, ADR-0006
> **Manifest Version**: 2026-04-09

---

### STORY-SS-001: SaveManager Autoload Skeleton + Constants

- **Type**: Config
- **TR-IDs**: TR-save-system-001, TR-save-system-009
- **ADR Guidance**: ADR-0002 — SaveManager is a pure I/O service autoload; SAVE_VERSION and SAVE_PATH are configurable constants, never hardcoded inline; boot position #5 (after Localization)
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN `save_manager.gd`, WHEN inspected, THEN `const SAVE_VERSION: int = 1` and `const SAVE_PATH: String = "user://save.json"` and `const TEMP_PATH: String = "user://save.json.tmp"` are declared as top-level constants
  - [ ] AC2: GIVEN `project.godot` autoload section, WHEN inspected, THEN SaveManager appears as autoload #5, after Localization and before SceneManager
  - [ ] AC3: GIVEN `save_manager.gd`'s `_ready()`, WHEN inspected, THEN it references no autoload that loads after it (no SceneManager, no CompanionRegistry references)
  - [ ] AC4: GIVEN the class, WHEN its public interface is checked, THEN the four public methods exist: `save_game() -> bool`, `load_game() -> bool`, `has_save() -> bool`, `delete_save() -> void`
- **Test Evidence**: `production/qa/evidence/save-system-constants-check.md`
- **Status**: Ready
- **Depends On**: STORY-GS-004 (GameStore.to_dict / from_dict must exist)

---

### STORY-SS-002: Atomic Save Write

- **Type**: Logic
- **TR-IDs**: TR-save-system-001, TR-save-system-004, TR-save-system-008
- **ADR Guidance**: ADR-0002 — Write to `user://save.json.tmp` first, then `DirAccess.rename()` to `user://save.json`; `FileAccess.store_string()` returns `bool` since Godot 4.4 — check return value; save write must complete in <3ms
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN `save_game()` is called, WHEN it succeeds, THEN `user://save.json` exists and `user://save.json.tmp` does not remain on disk
  - [ ] AC2: GIVEN `save_game()` is called, WHEN the file is opened and read, THEN the content is valid JSON with keys: "version", "timestamp", "game", "settings"
  - [ ] AC3: GIVEN `FileAccess.open(TEMP_PATH, WRITE)` returns null (disk full simulation), WHEN `save_game()` runs, THEN it returns `false` and logs a warning via `push_warning()`
  - [ ] AC4: GIVEN `file.store_string()` returns false (write failure simulation), WHEN `save_game()` detects it, THEN it returns `false` without proceeding to rename
  - [ ] AC5: GIVEN `save_game()` succeeds, WHEN the saved JSON is parsed, THEN `data["version"]` equals `SAVE_VERSION` and `data["timestamp"]` is a positive integer
- **Test Evidence**: `tests/unit/save_system/save_game_atomic_test.gd`
- **Status**: Ready
- **Depends On**: STORY-SS-001

---

### STORY-SS-003: Save Load and Parse

- **Type**: Logic
- **TR-IDs**: TR-save-system-001, TR-save-system-002, TR-save-system-007
- **ADR Guidance**: ADR-0002 — `load_game()` reads, JSON-parses, migrates, then calls `GameStore.from_dict()` and `SettingsStore.from_dict()`; corrupted JSON returns `false` without deleting the file
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN a valid `user://save.json` written by `save_game()`, WHEN `load_game()` is called, THEN it returns `true` and `GameStore` and `SettingsStore` state reflects the saved values
  - [ ] AC2: GIVEN no save file exists, WHEN `load_game()` is called, THEN it returns `false` with no crash
  - [ ] AC3: GIVEN a `user://save.json` containing invalid JSON (e.g., `"not json"`), WHEN `load_game()` is called, THEN it returns `false`, logs an error via `push_error()`, and the file is NOT deleted
  - [ ] AC4: GIVEN `has_save()` called when no file exists, WHEN it runs, THEN returns `false`
  - [ ] AC5: GIVEN `has_save()` called after `save_game()` succeeds, WHEN it runs, THEN returns `true`
- **Test Evidence**: `tests/unit/save_system/load_game_test.gd`
- **Status**: Ready
- **Depends On**: STORY-SS-002

---

### STORY-SS-004: Save Version Migration Chain

- **Type**: Logic
- **TR-IDs**: TR-save-system-005
- **ADR Guidance**: ADR-0002 — `_migrate(data, from_version)` chains migration functions v0→v1→…→current; each step adds default fields for missing keys; old fields are never removed
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN a save Dictionary with `"version": 0` passed to `_migrate()`, WHEN it runs, THEN the returned Dictionary has `"version"` equal to `SAVE_VERSION` and any v0→v1 default fields are present
  - [ ] AC2: GIVEN a save Dictionary already at the current version, WHEN `_migrate()` is called, THEN no migration functions run and the data is returned unchanged (except version stamp refresh)
  - [ ] AC3: GIVEN a migration from v0 to v1 that adds field `"player_xp"`, WHEN `_migrate_v0_to_v1()` runs on data lacking `"player_xp"` in the game sub-dict, THEN the resulting game dict contains `"player_xp": 0`
  - [ ] AC4: GIVEN a future schema version (e.g. v2 stub), WHEN the migration chain is extended by adding a new `if from_version < 2` block, THEN v0 saves correctly chain through v1 then v2 without skipping
- **Test Evidence**: `tests/unit/save_system/save_migration_test.gd`
- **Status**: Ready
- **Depends On**: STORY-SS-003

---

### STORY-SS-005: Delete Save + New Game Confirmation Guard

- **Type**: Logic
- **TR-IDs**: TR-save-system-010
- **ADR Guidance**: ADR-0002 — `delete_save()` removes the file and resets GameStore + SettingsStore to defaults; New Game with existing save requires a confirmation dialog before overwriting (UI-level guard, not SaveManager responsibility)
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN a save file exists, WHEN `delete_save()` is called, THEN `has_save()` returns `false` after the call
  - [ ] AC2: GIVEN `delete_save()` is called, WHEN it completes, THEN GameStore and SettingsStore are reset to their default values (equivalent to calling `_initialize_defaults()`)
  - [ ] AC3: GIVEN no save file exists, WHEN `delete_save()` is called, THEN it completes without error (idempotent)
  - [ ] AC4: GIVEN the Splash screen UI (integration scope), WHEN the player taps "New Game" with an existing save, THEN a confirmation dialog appears before `delete_save()` is called
- **Test Evidence**: `tests/unit/save_system/delete_save_test.gd`
- **Status**: Ready
- **Depends On**: STORY-SS-001

---

### STORY-SS-006: Continuous Persistence Integration (Dirty-Flag Trigger)

- **Type**: Integration
- **TR-IDs**: TR-save-system-003, TR-save-system-006
- **ADR Guidance**: ADR-0001, ADR-0002 — GameStore dirty-flag calls `SaveManager.save_game()` via deferred flush; combat state is intentionally NOT persisted; multiple same-frame mutations produce exactly 1 disk write
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN GameStore and SaveManager both running, WHEN `GameStore.add_gold(50)` is called, THEN by the next frame `user://save.json` exists and reflects the new gold value
  - [ ] AC2: GIVEN 3 different GameStore setters called in the same frame, WHEN the frame ends, THEN exactly 1 `SaveManager.save_game()` call occurred (verified via call count spy)
  - [ ] AC3: GIVEN a CombatSystem scene instance holding hand state, WHEN `save_game()` is called during an active combat, THEN the saved JSON contains no "hand", "deck_order", or "score" keys in the game section
  - [ ] AC4: GIVEN `GameStore.from_dict()` called (load path), WHEN it runs, THEN `save_game()` is NOT triggered (loading does not produce a write)
- **Test Evidence**: `tests/integration/save_system/continuous_persistence_test.gd`
- **Status**: Ready
- **Depends On**: STORY-SS-002, STORY-SS-003, STORY-GS-003
