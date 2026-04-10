# Stories: GameStore + SettingsStore

> **Epic**: GameStore + SettingsStore
> **Layer**: Foundation
> **Governing ADRs**: ADR-0001, ADR-0006
> **Manifest Version**: 2026-04-09

---

### STORY-GS-001: GameStore State Schema + Default Initialization

- **Type**: Logic
- **TR-IDs**: N/A (ADR-driven infrastructure — no GDD TR-IDs)
- **ADR Guidance**: ADR-0001 — GameStore holds all companion, story, economy, romance, combat buff, and captain state as typed private properties; `_initialize_defaults()` populates defaults for all 4 companions and all scalar fields
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN a fresh GameStore (no save loaded), WHEN `_initialize_defaults()` is called, THEN all 4 companion IDs ("artemis", "hipolita", "atenea", "nyx") exist in the companion states dictionary with `relationship_level: 0`, `trust: 0`, `motivation: 50`, `met: false`
  - [ ] AC2: GIVEN a fresh GameStore, WHEN `_initialize_defaults()` is called, THEN scalar fields are initialized: `player_gold = 0`, `player_xp = 0`, `daily_tokens_remaining = 3`, `current_streak = 0`, `current_chapter = "ch01"`, `active_combat_buff = {}`
  - [ ] AC3: GIVEN the GameStore autoload, WHEN inspected, THEN all state properties are private (underscore-prefixed) with no public direct field access
  - [ ] AC4: GIVEN GameStore initialized with defaults, WHEN `get_combat_buff()` is called, THEN it returns an empty Dictionary
- **Test Evidence**: `tests/unit/game_store/game_store_init_test.gd`
- **Status**: Ready
- **Depends On**: None

---

### STORY-GS-002: GameStore Typed Getters and Setters

- **Type**: Logic
- **TR-IDs**: N/A (ADR-driven infrastructure)
- **ADR Guidance**: ADR-0001 — All public access through typed methods; `set_flag()` is idempotent; `spend_gold()` returns false if insufficient; `_set_relationship_level()` is underscore-prefixed and reserved for CompanionState only
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN `player_gold = 50`, WHEN `spend_gold(30)` is called, THEN returns `true` and gold is 20
  - [ ] AC2: GIVEN `player_gold = 10`, WHEN `spend_gold(30)` is called, THEN returns `false` and gold remains 10
  - [ ] AC3: GIVEN an empty story_flags array, WHEN `set_flag("ch01_met_artemis")` is called twice, THEN `story_flags` contains exactly one entry and `has_flag("ch01_met_artemis")` returns true
  - [ ] AC4: GIVEN a companion with trust = 5, WHEN `set_trust("artemis", 10)` is called, THEN `get_companion_state("artemis")["trust"]` equals 10
  - [ ] AC5: GIVEN any setter call, WHEN the setter executes, THEN `_dirty` is set to `true`
  - [ ] AC6: GIVEN `get_node_state("node_42")` called on a fresh store, WHEN the key does not exist, THEN it returns an empty String (not null or error)
- **Test Evidence**: `tests/unit/game_store/game_store_setters_test.gd`
- **Status**: Ready
- **Depends On**: STORY-GS-001

---

### STORY-GS-003: GameStore Dirty-Flag + Deferred Flush Mechanism

- **Type**: Logic
- **TR-IDs**: N/A (ADR-driven infrastructure)
- **ADR Guidance**: ADR-0001 — Every setter sets `_dirty = true` and calls `call_deferred("_flush_save")` only if `_save_pending = false`; multiple same-frame mutations produce exactly 1 `_flush_save()` call; `_flush_save()` clears both flags after calling SaveManager
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN 5 different setters called in the same frame, WHEN the frame ends and deferred calls run, THEN `SaveManager.save_game()` is called exactly once
  - [ ] AC2: GIVEN `_save_pending = false`, WHEN any setter is called, THEN `_save_pending` becomes `true` before the frame ends
  - [ ] AC3: GIVEN `_flush_save()` is called, WHEN it completes, THEN `_dirty = false` and `_save_pending = false`
  - [ ] AC4: GIVEN `_save_pending = true` already, WHEN another setter fires in the same frame, THEN `call_deferred("_flush_save")` is NOT called a second time
  - [ ] AC5: GIVEN `from_dict()` is called (load path), WHEN it completes, THEN `_dirty` remains `false` (loading does not trigger a save)
- **Test Evidence**: `tests/unit/game_store/game_store_dirty_flag_test.gd`
- **Status**: Ready
- **Depends On**: STORY-GS-002

---

### STORY-GS-004: GameStore to_dict / from_dict Serialization

- **Type**: Logic
- **TR-IDs**: N/A (ADR-driven infrastructure)
- **ADR Guidance**: ADR-0001 — `to_dict()` captures all state in one call; `from_dict()` uses `.get(key, default)` for every field to support forward/backward compatibility; missing companion IDs receive default companion state
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN a GameStore with known state, WHEN `to_dict()` is called, THEN the returned Dictionary contains keys: "companion_states", "story_flags", "node_states", "current_chapter", "player_gold", "player_xp", "daily_tokens_remaining", "current_streak", "last_interaction_date", "active_combat_buff", "last_captain_id"
  - [ ] AC2: GIVEN a Dictionary missing the "player_xp" key, WHEN `from_dict()` is called, THEN `get_xp()` returns 0 (default) with no error
  - [ ] AC3: GIVEN a Dictionary missing "nyx" from companion_states, WHEN `from_dict()` is called, THEN "nyx" is initialized with default companion state
  - [ ] AC4: GIVEN a state set via setters, WHEN `to_dict()` is called and then `from_dict()` is called on a new instance, THEN all getter values match the original
  - [ ] AC5: GIVEN `from_dict()` is called, WHEN it completes, THEN `_dirty` is `false` (round-trip does not trigger persistence)
- **Test Evidence**: `tests/unit/game_store/game_store_serialization_test.gd`
- **Status**: Ready
- **Depends On**: STORY-GS-002

---

### STORY-GS-005: SettingsStore Autoload

- **Type**: Logic
- **TR-IDs**: N/A (ADR-driven infrastructure)
- **ADR Guidance**: ADR-0001, ADR-0006 — SettingsStore is autoload #2; holds locale, volume levels, and text speed; uses same dirty-flag + call_deferred pattern as GameStore; implements `to_dict()` / `from_dict()`
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN a fresh SettingsStore, WHEN initialized, THEN `locale = "en"`, `master_volume = 1.0`, `sfx_volume = 1.0`, `music_volume = 1.0`, `text_speed = 1.0`
  - [ ] AC2: GIVEN `set_locale("es")` is called, WHEN it executes, THEN `locale` is "es" and `_dirty` is `true`
  - [ ] AC3: GIVEN a SettingsStore with `locale = "es"`, WHEN `to_dict()` is called, THEN the returned Dictionary contains `"locale": "es"` and all other settings fields
  - [ ] AC4: GIVEN a Dictionary with `"locale": "es"`, WHEN `from_dict()` is called, THEN `locale` equals "es"
  - [ ] AC5: GIVEN `set_locale("es")` called, WHEN the frame ends, THEN `SaveManager.save_game()` is called (dirty-flag mechanism triggers)
- **Test Evidence**: `tests/unit/game_store/settings_store_test.gd`
- **Status**: Ready
- **Depends On**: STORY-GS-001

---

### STORY-GS-006: GameStore + SettingsStore Boot Order Wiring

- **Type**: Integration
- **TR-IDs**: N/A (ADR-driven infrastructure)
- **ADR Guidance**: ADR-0006 — GameStore is autoload #1, SettingsStore is autoload #2; neither may reference any other autoload during `_ready()`; verified in project.godot
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN `project.godot`, WHEN the autoload section is inspected, THEN GameStore appears before SettingsStore and both appear before EventBus, Localization, SaveManager, and SceneManager
  - [ ] AC2: GIVEN the game launches fresh with no save file, WHEN Splash scene loads, THEN no "autoload not ready" errors appear in the output log
  - [ ] AC3: GIVEN GameStore's `_ready()` function, WHEN inspected via grep, THEN it references no other autoload by name
  - [ ] AC4: GIVEN SettingsStore's `_ready()` function, WHEN inspected via grep, THEN it references no other autoload by name
  - [ ] AC5: GIVEN `GameStore.state_changed` signal, WHEN any setter emits it, THEN listeners in other autoloads that loaded after GameStore can connect without error
- **Test Evidence**: `tests/integration/game_store/boot_order_test.gd`
- **Status**: Ready
- **Depends On**: STORY-GS-003, STORY-GS-004, STORY-GS-005
