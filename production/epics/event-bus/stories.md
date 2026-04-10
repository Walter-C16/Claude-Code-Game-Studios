# Stories: EventBus

> **Epic**: EventBus
> **Layer**: Foundation
> **Governing ADRs**: ADR-0004, ADR-0006
> **Manifest Version**: 2026-04-09

---

### STORY-EB-001: EventBus Signal Catalog Declaration

- **Type**: Logic
- **TR-IDs**: N/A (ADR-driven infrastructure — no GDD TR-IDs)
- **ADR Guidance**: ADR-0004 — EventBus is a pure relay with no state and no logic; all cross-system signals are declared here; typed signal parameters enforce compiler validation; ~15 signals covering romance, combat, dialogue, story, and deck domains
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN the `event_bus.gd` file, WHEN inspected, THEN it declares exactly these signals (no more, no fewer): `romance_stage_changed(companion_id: String, old_stage: int, new_stage: int)`, `tokens_reset`, `combat_completed(result: Dictionary)`, `dialogue_ended(sequence_id: String)`, `dialogue_blocked(sequence_id: String, reason: String)`, `relationship_changed(companion_id: String, delta: int)`, `trust_changed(companion_id: String, delta: int)`, `companion_met(companion_id: String)`, `chapter_completed(chapter_id: String)`, `node_completed(node_id: String)`
  - [ ] AC2: GIVEN `event_bus.gd`, WHEN inspected, THEN it has no `_process()`, no `_physics_process()`, no instance variables (no state), and no logic methods beyond signal declarations
  - [ ] AC3: GIVEN `event_bus.gd`, WHEN inspected, THEN `extends Node` is the base class (not Resource, not RefCounted)
  - [ ] AC4: GIVEN the file, WHEN a doc comment is checked, THEN each signal group (Romance, Combat, Dialogue, Story) has a section comment explaining its purpose and which system emits it
  - [ ] AC5: GIVEN `combat_completed` signal, WHEN its parameter type is checked, THEN it uses `Dictionary` (not a raw variant) with the documented structure `{victory: bool, score: int, hands_used: int, captain_id: String}`
- **Test Evidence**: `tests/unit/event_bus/event_bus_declarations_test.gd`
- **Status**: Ready
- **Depends On**: None

---

### STORY-EB-002: EventBus Type Safety and Emission Validation

- **Type**: Logic
- **TR-IDs**: N/A (ADR-driven infrastructure)
- **ADR Guidance**: ADR-0004 — Typed signal declarations enforce parameter counts at emit() call site; signal parameter mismatch causes crash or silent ignore; integration tests verify end-to-end signal chains
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN a test emitter calling `EventBus.relationship_changed.emit("artemisa", 5)`, WHEN a connected listener runs, THEN it receives `companion_id = "artemisa"` and `delta = 5` with correct types
  - [ ] AC2: GIVEN a test listener connected to `EventBus.combat_completed`, WHEN `EventBus.combat_completed.emit({victory: true, score: 1200, hands_used: 3, captain_id: "artemisa"})` fires, THEN the listener receives the full Dictionary unchanged
  - [ ] AC3: GIVEN a listener connected to `EventBus.romance_stage_changed`, WHEN it receives emission, THEN `old_stage` and `new_stage` are both typed int (not String or float)
  - [ ] AC4: GIVEN `EventBus.tokens_reset`, WHEN emitted with no arguments, THEN connected listeners are called with no arguments and no error occurs
  - [ ] AC5: GIVEN `EventBus` is instantiated in a test scene, WHEN all signals are accessed, THEN no errors appear and all signals are callable
- **Test Evidence**: `tests/unit/event_bus/event_bus_type_safety_test.gd`
- **Status**: Ready
- **Depends On**: STORY-EB-001

---

### STORY-EB-003: EventBus Boot Order Wiring + Layer Isolation Verification

- **Type**: Integration
- **TR-IDs**: N/A (ADR-driven infrastructure)
- **ADR Guidance**: ADR-0006 — EventBus is autoload #3, after GameStore and SettingsStore; ADR-0004 — emitters call `EventBus.[signal].emit()`, listeners call `EventBus.[signal].connect()`; no direct cross-layer imports
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN `project.godot`, WHEN the autoload section is inspected, THEN EventBus is listed after GameStore and SettingsStore and before Localization, SaveManager, and SceneManager
  - [ ] AC2: GIVEN `event_bus.gd`'s `_ready()`, WHEN inspected, THEN it references no other autoload (EventBus has no dependencies)
  - [ ] AC3: GIVEN a grep of `src/` for `SceneTree.change_scene_to_file`, WHEN run, THEN the result is zero matches outside of `scene_manager.gd`
  - [ ] AC4: GIVEN a grep of Core-layer scripts for direct imports of Feature-layer scripts, WHEN run, THEN the result is zero matches (no upward imports across layers)
  - [ ] AC5: GIVEN a simulated DialogueRunner emitting `EventBus.relationship_changed`, WHEN a simulated RomanceSocial listener is connected, THEN the listener fires and receives the correct values without DialogueRunner and RomanceSocial importing each other
- **Test Evidence**: `tests/integration/event_bus/event_bus_wiring_test.gd`
- **Status**: Ready
- **Depends On**: STORY-EB-001, STORY-EB-002
