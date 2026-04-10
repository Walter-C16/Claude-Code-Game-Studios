# Stories: Companion Data Epic

> **Epic**: Companion Data
> **Layer**: Core
> **Governing ADRs**: ADR-0009, ADR-0006
> **Control Manifest Version**: 2026-04-09
> **Story Count**: 5

---

### STORY-COMPANION-001: CompanionRegistry Autoload — Static Profile Loading

- **Type**: Logic
- **TR-IDs**: TR-companion-data-001, TR-companion-data-008, TR-companion-data-009
- **ADR Guidance**: ADR-0009 — CompanionRegistry is autoload #7, reads from `res://assets/data/companions.json` at `_ready()`, exposes `get_profile()`, `get_all_ids()`, and `get_portrait_path()` as the sole public API. Read-only, no writes.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN `companions.json` exists at `res://assets/data/companions.json`, WHEN CompanionRegistry `_ready()` runs, THEN all 4 companion profiles and the priestess NPC are loaded into `_profiles` dictionary.
  - [ ] AC2: GIVEN companion ID `"artemis"`, WHEN `get_profile("artemis")` is called, THEN returns a Dictionary with keys: `id`, `display_name`, `role`, `element`, `STR`, `INT`, `AGI`, `card_value`, `starting_location`, `portrait_path_base`.
  - [ ] AC3: GIVEN an unknown companion ID `"zeus"`, WHEN `get_profile("zeus")` is called, THEN returns an empty Dictionary `{}` (no crash, no error push).
  - [ ] AC4: GIVEN CompanionRegistry is loaded, WHEN `get_all_ids()` is called, THEN returns an `Array[String]` of exactly 5 IDs (4 companions + priestess).
  - [ ] AC5: GIVEN any companion ID and a valid mood string, WHEN `get_portrait_path(id, mood)` is called, THEN returns a String matching pattern `res://assets/images/companions/{id}/{id}_{mood}.png`.
  - [ ] AC6: GIVEN CompanionRegistry is loaded, WHEN a profile dictionary field (e.g. `STR`) is retrieved and modified externally, THEN the internal `_profiles` dictionary is NOT mutated (defensive copy or immutable read).
  - [ ] AC7: GIVEN 5 profiles in the dictionary, WHEN `get_profile()` is called with a known ID, THEN execution completes within 1ms (dictionary lookup, not iteration).
- **Test Evidence**: `tests/unit/companion_data/companion_registry_test.gd`
- **Status**: Ready
- **Depends On**: None

---

### STORY-COMPANION-002: Element Enum and Suit Mapping

- **Type**: Logic
- **TR-IDs**: TR-companion-data-005
- **ADR Guidance**: ADR-0009 — Element enum (Fire, Water, Earth, Lightning) shared across Combat and Companion systems; suit mapping Hearts=Fire, Diamonds=Water, Clubs=Earth, Spades=Lightning defined in CompanionRegistry as `get_element_for_suit()`.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN a `CompanionElement` enum is defined (as a GDScript enum or constants dict), WHEN any system references `CompanionElement.FIRE`, THEN the value is accessible without importing a scene node.
  - [ ] AC2: GIVEN suit string `"Hearts"`, WHEN `CompanionRegistry.get_element_for_suit("Hearts")` is called, THEN returns `"Fire"`.
  - [ ] AC3: GIVEN suit string `"Diamonds"`, WHEN `get_element_for_suit("Diamonds")` is called, THEN returns `"Water"`.
  - [ ] AC4: GIVEN suit string `"Clubs"`, WHEN `get_element_for_suit("Clubs")` is called, THEN returns `"Earth"`.
  - [ ] AC5: GIVEN suit string `"Spades"`, WHEN `get_element_for_suit("Spades")` is called, THEN returns `"Lightning"`.
  - [ ] AC6: GIVEN an unknown suit string `"Joker"`, WHEN `get_element_for_suit("Joker")` is called, THEN returns empty string `""` (no crash).
  - [ ] AC7: GIVEN the element enum, WHEN companion profiles are loaded, THEN each of the 4 companions has a unique element (no two companions share an element).
- **Test Evidence**: `tests/unit/companion_data/element_suit_mapping_test.gd`
- **Status**: Ready
- **Depends On**: STORY-COMPANION-001

---

### STORY-COMPANION-003: CompanionState — Mutable State Access and Romance Stage Derivation

- **Type**: Logic
- **TR-IDs**: TR-companion-data-002, TR-companion-data-003, TR-companion-data-006, TR-companion-data-010
- **ADR Guidance**: ADR-0009 — CompanionState is a non-autoload RefCounted class with static methods over GameStore. `get_state(id)` returns mutable state dict. `get_romance_stage(id)` derives stage from threshold array. `romance_stage_changed` emitted via EventBus on stage transition. `relationship_level` clamped to [0, 100] on any write.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN GameStore contains companion state for `"artemis"` with `relationship_level=55`, WHEN `CompanionState.get_state("artemis")` is called, THEN returns a Dictionary with all mutable state fields: `relationship_level`, `trust`, `motivation`, `romance_stage`, `dates_completed`, `met`, `known_likes`, `known_dislikes`.
  - [ ] AC2: GIVEN `relationship_level=55` (thresholds [0, 21, 51, 71, 91]), WHEN `CompanionState.get_romance_stage("artemis")` is called, THEN returns `2`.
  - [ ] AC3: GIVEN `relationship_level=0`, WHEN `get_romance_stage()` is called, THEN returns `0`.
  - [ ] AC4: GIVEN `relationship_level=91`, WHEN `get_romance_stage()` is called, THEN returns `4`.
  - [ ] AC5: GIVEN companion at romance_stage=3 with `relationship_level=75`, WHEN `relationship_level` is updated to `65` (below stage-3 threshold of 71), THEN `get_romance_stage()` still returns `3` (stage never decreases).
  - [ ] AC6: GIVEN `relationship_level` write of `105`, WHEN `CompanionState.set_relationship_level("artemis", 105)` is called, THEN GameStore stores `100` (clamped to max).
  - [ ] AC7: GIVEN companion crosses from stage 1 to stage 2, WHEN the transition is detected, THEN `EventBus.romance_stage_changed.emit(companion_id, old_stage, new_stage)` is called.
  - [ ] AC8: GIVEN a stage-already-at-4 companion with `relationship_level` written to 100, WHEN `set_relationship_level()` is called, THEN no `romance_stage_changed` signal is emitted (no spurious events).
- **Test Evidence**: `tests/unit/companion_data/companion_state_test.gd`
- **Status**: Ready
- **Depends On**: STORY-COMPANION-001

---

### STORY-COMPANION-004: Portrait Fallback System

- **Type**: Logic
- **TR-IDs**: TR-companion-data-004
- **ADR Guidance**: ADR-0009 — Portrait path convention `res://assets/images/companions/{id}/{id}_{mood}.png`. Fallback order: requested mood → neutral → placeholder silhouette. CompanionRegistry `get_portrait_path()` returns the path; callers (Dialogue system) handle the FileAccess check.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN companion `"hipolita"` and mood `"angry"`, WHEN `get_portrait_path("hipolita", "angry")` is called, THEN returns `"res://assets/images/companions/hipolita/hipolita_angry.png"`.
  - [ ] AC2: GIVEN a missing portrait file for mood `"surprised"`, WHEN the Dialogue system requests a portrait path and the file does not exist, THEN the system receives the `neutral` portrait path as fallback (`hipolita_neutral.png`).
  - [ ] AC3: GIVEN both the requested mood file and the `neutral` file are missing, WHEN fallback is applied, THEN a placeholder silhouette path (e.g. `res://assets/images/companions/placeholder.png`) is returned.
  - [ ] AC4: GIVEN 6 mood values (neutral, happy, sad, angry, surprised, seductive), WHEN `get_portrait_path()` is called for each, THEN each returns a unique, correctly-formatted path string.
  - [ ] AC5: GIVEN an invalid mood string `"bored"`, WHEN `get_portrait_path()` is called, THEN it falls back to `neutral` path (does not crash).
- **Test Evidence**: `tests/unit/companion_data/portrait_fallback_test.gd`
- **Status**: Ready
- **Depends On**: STORY-COMPANION-001

---

### STORY-COMPANION-005: Save Migration — Missing and Unknown Companions

- **Type**: Integration
- **TR-IDs**: TR-companion-data-007
- **ADR Guidance**: ADR-0009 — On save load, create default state for any companion in CompanionRegistry that is absent from save data; ignore (drop) any companion ID in save data that is not in CompanionRegistry. ADR-0002 governs save file format.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN a save file containing state for only `"artemis"` and `"hipolita"` (missing atenea and nyx), WHEN the save is loaded, THEN GameStore contains valid default-value state records for `"atenea"` and `"nyx"` (relationship_level=0, trust=0, motivation=50, met=false).
  - [ ] AC2: GIVEN a save file containing a companion ID `"future_companion"` not in CompanionRegistry, WHEN the save is loaded, THEN `"future_companion"` data is silently discarded and all known companions load correctly.
  - [ ] AC3: GIVEN a save file with all 4 companions plus an unknown ID, WHEN loaded, THEN exactly 4 companion state records exist in GameStore (the unknown is stripped).
  - [ ] AC4: GIVEN a brand-new game (no save file), WHEN the game initializes, THEN all 4 companions have state records with exactly the GDD-defined initial values: relationship_level=0, trust=0, motivation=50, romance_stage=0, dates_completed=0, met=false, known_likes=[], known_dislikes=[].
  - [ ] AC5: GIVEN migration creates a new default companion record, WHEN the game is subsequently saved, THEN the new record is included in the save file (migration is persistent).
- **Test Evidence**: `tests/integration/companion_data/save_migration_test.gd`
- **Status**: Ready
- **Depends On**: STORY-COMPANION-001, STORY-COMPANION-003
