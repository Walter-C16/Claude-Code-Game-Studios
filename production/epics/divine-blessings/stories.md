# Stories: Divine Blessings

> **Epic**: divine-blessings
> **Layer**: Feature
> **ADR**: ADR-0012
> **Manifest Version**: 2026-04-09
> **Total Stories**: 6

---

### STORY-DB-001: Blessing Data — JSON Loading and Validation

- **Type**: Logic
- **TR-IDs**: TR-divine-blessings-001, TR-divine-blessings-006, TR-divine-blessings-008, TR-divine-blessings-011, TR-divine-blessings-012
- **ADR Guidance**: All 20 blessings data-driven from `res://assets/data/blessings.json`. No hardcoded values. BlessingSystem is a stateless `RefCounted` — data is loaded once and cached (or re-read per call; no persistent state). hand_context dict must support all 12 required fields.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN `blessings.json` is parsed, WHEN `get_blessing_info(captain_id)` is called for each of the 4 companions, THEN exactly 5 blessings per companion are returned (20 total).
  - [ ] AC2: GIVEN a blessing dict from the file, WHEN validated, THEN it contains `slot`, `stage`, `name_key`, `trigger_type`, and at least one value field (`chips_per_card`, `mult_per_card`, `chips_flat`, `mult_flat`).
  - [ ] AC3: GIVEN per-card variable blessings are loaded, THEN Artemisa slot 1 has `suit: "Clubs"` and `chips_per_card: 8`; Hipolita has `suit: "Hearts"` and `chips_per_card: 10`; Atenea has `suit: "Spades"` and `mult_per_card: 0.8`; Nyx has `suit: "Diamonds"` and `chips_per_card: 7`.
  - [ ] AC4: GIVEN BlessingSystem code is inspected, THEN no numeric blessing values (chip amounts, multiplier amounts, stage thresholds) appear as literals — all sourced from the JSON file.
  - [ ] AC5: GIVEN a hand_context dict, WHEN validated against the required schema, THEN all 12 required fields are present: `cards_played`, `hand_rank`, `hand_rank_value`, `suit_counts`, `current_score`, `hands_played`, `discards_used`, `discards_remaining`, `discards_allowed`, `signature_card_played`, `raw_hand_chips`, `hands_scoring_above`.
- **Test Evidence**: `tests/unit/divine_blessings/blessing_data_test.gd`
- **Status**: Ready
- **Depends On**: None

---

### STORY-DB-002: Slot Availability — Stage Gating and Captain Lock

- **Type**: Logic
- **TR-IDs**: TR-divine-blessings-002, TR-divine-blessings-003, TR-divine-blessings-013, TR-divine-blessings-014
- **ADR Guidance**: Slot availability gated by romance_stage: 0/1/2/4/5 slots per stage 0/1/2/3/4. Captain lock: only active captain's blessings contribute; frozen at combat start. Blessing states: LOCKED, UNLOCKED, ACTIVE, INACTIVE_TRIGGER. Unlock state derived from romance_stage (no additional save data).
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN `_max_slot_for_stage(0)` is called, THEN it returns 0 (no blessings at stage 0).
  - [ ] AC2: GIVEN `_max_slot_for_stage(2)` is called, THEN it returns 2.
  - [ ] AC3: GIVEN `_max_slot_for_stage(3)` is called, THEN it returns 4 (stage 3 unlocks slot 4, not slot 3).
  - [ ] AC4: GIVEN `_max_slot_for_stage(4)` is called, THEN it returns 5.
  - [ ] AC5: GIVEN captain_id="artemisa" and romance_stage=2, WHEN `compute()` is called for captain_id="hipolita", THEN only Hipolita's blessings are evaluated (not Artemisa's).
  - [ ] AC6: GIVEN romance_stage changes mid-combat, WHEN `compute()` is called with the cached stage value from combat start, THEN the changed stage is ignored and the frozen value is used.
- **Test Evidence**: `tests/unit/divine_blessings/slot_availability_test.gd`
- **Status**: Ready
- **Depends On**: STORY-DB-001

---

### STORY-DB-003: Trigger Evaluation — All 13 Trigger Types

- **Type**: Logic
- **TR-IDs**: TR-divine-blessings-004, TR-divine-blessings-005, TR-divine-blessings-006, TR-divine-blessings-007
- **ADR Guidance**: Sequential slot evaluation 1-5. `_evaluate_trigger()` handles 13 trigger types. `accumulated_chips` is passed to support Nyx Slot 4 (`accumulated_chips_min`). CombatSystem must track `discards_used` and `hands_played` as combat state fields per TR-007.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN trigger_type="always", WHEN evaluated, THEN returns true unconditionally.
  - [ ] AC2: GIVEN trigger_type="suit_count", suit="Clubs", min_count=3, and suit_counts={"Clubs": 3}, WHEN evaluated, THEN returns true.
  - [ ] AC3: GIVEN trigger_type="suit_count", suit="Clubs", min_count=3, and suit_counts={"Clubs": 2}, WHEN evaluated, THEN returns false.
  - [ ] AC4: GIVEN trigger_type="accumulated_chips_min", min_chips=30, and accumulated_chips=25 (from prior slots), WHEN evaluated, THEN returns false.
  - [ ] AC5: GIVEN trigger_type="accumulated_chips_min", min_chips=30, and accumulated_chips=35, WHEN evaluated, THEN returns true.
  - [ ] AC6: GIVEN trigger_type="discards_remaining_eq" and discards_remaining == discards_allowed, WHEN evaluated, THEN returns true (patient hunt: no discard used).
  - [ ] AC7: GIVEN all 13 trigger type branches in `_evaluate_trigger()`, WHEN each is exercised with boundary-value inputs, THEN each returns the correct bool — no unhandled match returns false by default.
- **Test Evidence**: `tests/unit/divine_blessings/trigger_evaluation_test.gd`
- **Status**: Ready
- **Depends On**: STORY-DB-002

---

### STORY-DB-004: compute() Function — End-to-End Output and Performance

- **Type**: Logic
- **TR-IDs**: TR-divine-blessings-004, TR-divine-blessings-005, TR-divine-blessings-009, TR-divine-blessings-017
- **ADR Guidance**: `compute(captain_id, romance_stage, hand_context)` returns `{blessing_chips: int, blessing_mult: float}`. Sequential 1-5 evaluation. `accumulated_chips` accumulates across the loop and is passed to each trigger evaluation. Must complete in <1ms. Recomputed fresh each PLAY — not cached across turns.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN Artemisa at romance_stage=1 and 3 Clubs played, WHEN `compute()` is called, THEN `blessing_chips` = 24 and `blessing_mult` = 0.0.
  - [ ] AC2: GIVEN romance_stage=0 for any captain, WHEN `compute()` is called, THEN it returns `{blessing_chips: 0, blessing_mult: 0.0}`.
  - [ ] AC3: GIVEN Nyx at romance_stage=4 with all triggers met, WHEN `compute()` is called, THEN `blessing_chips` = 66 and `blessing_mult` = 9.5 (ADR-0012 Validation Criterion 3).
  - [ ] AC4: GIVEN a Hipolita stage 4 worked example from the GDD, WHEN `compute()` is called with the specified hand_context, THEN the final score contribution matches the GDD value of 869.
  - [ ] AC5: GIVEN `compute()` is called 1000 times in a loop with valid inputs, WHEN measured via `Time.get_ticks_usec()`, THEN average call time is under 1ms (1000 microseconds).
  - [ ] AC6: GIVEN `compute()` is called twice for the same inputs on successive PLAYs, THEN it returns identical results (stateless, deterministic).
- **Test Evidence**: `tests/unit/divine_blessings/compute_function_test.gd`
- **Status**: Ready
- **Depends On**: STORY-DB-003

---

### STORY-DB-005: Combat HUD — Blessing Icon Strip (1-5 Icons)

- **Type**: UI
- **TR-IDs**: TR-divine-blessings-010, TR-divine-blessings-013, TR-divine-blessings-015, TR-divine-blessings-016
- **ADR Guidance**: Presentation layer only. 1-5 icons (32x32px) stacked vertically on left edge. Opacity 100% when triggered, 40% when not triggered. 0.2s icon pulse VFX per triggered hand (no full-screen interruption). Long-press on icon pauses game and shows tooltip. All Control nodes inherit shared Theme .tres. Touch targets >= 44x44px.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN captain has 3 unlocked blessing slots (romance_stage=2), WHEN the HUD renders, THEN exactly 3 icons are visible on the left edge, each 32x32px.
  - [ ] AC2: GIVEN a blessing triggered on the last PLAY action, WHEN the HUD updates, THEN the corresponding icon is at 100% opacity; non-triggered slots are at 40% opacity.
  - [ ] AC3: GIVEN a blessing triggers, WHEN the icon animates, THEN a 0.2s pulse plays on the icon without covering the combat play area.
  - [ ] AC4: GIVEN the player long-presses a blessing icon, WHEN the press holds, THEN the game pauses and a tooltip card appears with the blessing name and effect description.
  - [ ] AC5: GIVEN the tooltip is visible, WHEN the player releases or taps elsewhere, THEN the tooltip dismisses and the game unpauses.
  - [ ] AC6: GIVEN all blessing icon hitboxes, THEN each is at minimum 44x44px regardless of the 32x32 visual size.
- **Test Evidence**: `production/qa/evidence/divine-blessings/blessing-hud-screenshot.png`
- **Status**: Ready
- **Depends On**: STORY-DB-004

---

### STORY-DB-006: BlessingSystem Integration — CombatSystem Scoring Pipeline Hook

- **Type**: Integration
- **TR-IDs**: TR-divine-blessings-003, TR-divine-blessings-004, TR-divine-blessings-007, TR-divine-blessings-009
- **ADR Guidance**: CombatSystem calls `BlessingSystem.compute()` as a black box during RESOLVE. `blessing_chips` and `blessing_mult` injected into the scoring pipeline at the correct positions (after raw chips, before final mult). CombatSystem caches romance_stage at combat start (from `EventBus.combat_configured` payload). CombatSystem must track `discards_used` and `hands_played` and include them in hand_context.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN a PLAY action triggers RESOLVE, WHEN the scoring pipeline runs, THEN `BlessingSystem.compute(captain_id, cached_romance_stage, hand_context)` is called exactly once.
  - [ ] AC2: GIVEN `compute()` returns `{blessing_chips: 24, blessing_mult: 0.0}`, WHEN scoring continues, THEN 24 is added to the additive chips total at the correct pipeline position.
  - [ ] AC3: GIVEN CombatSystem builds hand_context, WHEN inspected, THEN all 12 required fields are present including `discards_used` and `hands_played`.
  - [ ] AC4: GIVEN romance_stage changes via `romance_stage_changed` during combat, WHEN `compute()` is called on the next PLAY, THEN the cached stage value (from combat start) is used, not the updated live value.
  - [ ] AC5: GIVEN CombatSystem code is inspected, THEN it does not import or inspect blessing internals — it only calls `BlessingSystem.compute()` and reads the two returned values.
- **Test Evidence**: `tests/integration/divine_blessings/combat_pipeline_integration_test.gd`
- **Status**: Ready
- **Depends On**: STORY-DB-004
