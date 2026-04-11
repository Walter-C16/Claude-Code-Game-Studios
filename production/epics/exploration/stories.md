# Stories: Exploration Epic

> **Epic**: Exploration
> **Layer**: Feature (Alpha)
> **Governing ADRs**: No ADR — implements GDD directly
> **Control Manifest Version**: 2026-04-10
> **Story Count**: 7

---

### STORY-EXPLORE-001: Mission Data and Dispatch State

- **Type**: Logic
- **TR-IDs**: TR-explore-001, TR-explore-002, TR-explore-003, TR-explore-015
- **ADR Guidance**: No ADR — implements GDD directly. Mission type definitions loaded from `assets/data/exploration_config.json`. Dispatch state written to SaveManager at dispatch time with UTC timestamp.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN `exploration_config.json` is loaded, WHEN `MissionData.get_mission(type)` is called for each of the 4 mission types (hunt, raid, expedition, night_watch), THEN it returns a dict with: `gold_min`, `gold_max`, `xp_min`, `xp_max`, and `primary_item_category`.
  - [ ] AC2: GIVEN a companion with `met == true`, WHEN `dispatch(companion_id, mission_type, duration_hours)` is called, THEN SaveManager is written with: `dispatch_start_utc` (current UTC int), `dispatch_companion_id`, `dispatch_duration_hours`, `dispatch_mission_type`.
  - [ ] AC3: GIVEN a companion with `met == false`, WHEN `dispatch()` is called for that companion, THEN the dispatch is rejected, no save state is written, and an error result is returned.
  - [ ] AC4: GIVEN `exploration_config.json` fails to load, WHEN `dispatch()` is called, THEN gold=0, XP=0, no item, dispatched flag cleared, and an error toast is shown — no crash.
  - [ ] AC5: GIVEN `duration_hours` contains an invalid value (not 1, 2, or 4), WHEN dispatch runs, THEN multipliers default to 1.0x (1-hour rates), a warning is logged, and dispatch proceeds without crash.
  - [ ] AC6: GIVEN all tuning knobs (GOLD_MULT_1HR, GOLD_MULT_2HR, GOLD_MULT_4HR, BASE_FIND_1HR, etc.), WHEN accessed, THEN all originate from `exploration_config.json` (no hardcoded values in `.gd` files).
- **Test Evidence**: `tests/unit/exploration/mission_data_test.gd`
- **Status**: Ready
- **Depends On**: None

---

### STORY-EXPLORE-002: Real-Time Clock and UTC Persistence

- **Type**: Logic
- **TR-IDs**: TR-explore-004, TR-explore-005
- **ADR Guidance**: No ADR — implements GDD directly. Time remaining = (duration_hours * 3600) - (current_utc - dispatch_start_utc), clamped to min 0. Clock rollback guard prevents negative elapsed time.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN dispatch_start_utc=1000000 and duration_hours=2 (7200 seconds), WHEN current_utc=1003600 (1 hour elapsed), THEN `get_time_remaining_sec()` returns 3600.
  - [ ] AC2: GIVEN dispatch_start_utc=1000000 and duration_hours=1 (3600 seconds), WHEN current_utc=1003700 (elapsed > duration), THEN `get_time_remaining_sec()` returns 0 (clamped, not negative).
  - [ ] AC3: GIVEN dispatch_start_utc=1000000 and current_utc=999999 (clock rollback — current is before start), WHEN `get_time_remaining_sec()` is called, THEN elapsed is clamped to 0, time_remaining = full duration (dispatch not prematurely collectible).
  - [ ] AC4: GIVEN time_remaining_sec == 0, WHEN `is_ready_to_collect()` is called, THEN returns true.
  - [ ] AC5: GIVEN time_remaining_sec > 0, WHEN `is_ready_to_collect()` is called, THEN returns false.
  - [ ] AC6: GIVEN dispatch state is stored in SaveManager and the app is closed then reopened, WHEN `get_time_remaining_sec()` is called on next app open, THEN it correctly reflects the real time elapsed during the closure (UTC persists across sessions).
  - [ ] AC7: GIVEN time_remaining_sec=3723, WHEN `format_time_remaining()` is called, THEN it returns "01:02" (HH:MM format, rounded down to minutes).
- **Test Evidence**: `tests/unit/exploration/utc_clock_test.gd`
- **Status**: Ready
- **Depends On**: STORY-EXPLORE-001

---

### STORY-EXPLORE-003: Reward Calculation

- **Type**: Logic
- **TR-IDs**: TR-explore-006, TR-explore-007, TR-explore-008, TR-explore-009
- **ADR Guidance**: No ADR — implements GDD directly. Gold = round(random_int(min,max) * duration_mult). XP = round(random_int(min,max) * duration_mult). Item find chance = base_find_chance + floor(agi/5), capped at 60%. INT rarity shift: 0=65/30/5, 1=55/35/10, 2=45/35/20, 3+=35/35/30.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN a Hunt mission with duration=4hr (gold range 30-60, mult=2.8), WHEN `calculate_gold()` is called with a seeded RNG, THEN the result is within the range [84, 168] and equals `round(base * 2.8)`.
  - [ ] AC2: GIVEN an Expedition mission with duration=2hr (xp range 40-60, mult=1.6), WHEN `calculate_xp()` is called, THEN result is within [64, 96] and equals `round(base * 1.6)`.
  - [ ] AC3: GIVEN Artemis (AGI=20) on a 4-hour mission (base_find_chance=40%), WHEN item_find_chance is calculated, THEN result = 40 + floor(20/5) = 44%.
  - [ ] AC4: GIVEN a companion with AGI=100 (extreme value), WHEN item_find_chance is calculated, THEN result is capped at 60% (MAX_FIND_CHANCE).
  - [ ] AC5: GIVEN Atenea (INT=19) finds an item, WHEN rarity weights are applied, THEN the table used is (55/35/10) (int_rarity_shift = floor(19/10) = 1).
  - [ ] AC6: GIVEN a companion with INT=25 (int_rarity_shift=2), WHEN rarity weights are applied, THEN the table is (45/35/20).
  - [ ] AC7: GIVEN a companion with INT=40 (int_rarity_shift=4, above cap), WHEN rarity weights are applied, THEN the table is capped at (35/35/30) (3+ points cap).
  - [ ] AC8: GIVEN 1000 seeded item find rolls with item_find_chance=44%, WHEN tallied, THEN approximately 44% result in an item find (within ±4% tolerance).
- **Test Evidence**: `tests/unit/exploration/reward_calculation_test.gd`
- **Status**: Ready
- **Depends On**: STORY-EXPLORE-001

---

### STORY-EXPLORE-004: Companion Availability Lock

- **Type**: Logic
- **TR-IDs**: TR-explore-003, TR-explore-010, TR-explore-011
- **ADR Guidance**: No ADR — implements GDD directly. A dispatched companion has `dispatched = true` in CompanionState. This flag is read by Camp and CombatSystem to block interactions. Only one dispatch active at a time.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN companion "artemis" is dispatched, WHEN `CompanionState.is_dispatched("artemis")` is called, THEN returns true.
  - [ ] AC2: GIVEN a dispatch is already active for "artemis", WHEN `dispatch("nyx", ...)` is called, THEN the dispatch is rejected with a UI message "A companion is already on a mission" and no save state is written.
  - [ ] AC3: GIVEN "artemis" is dispatched, WHEN the Camp UI renders companion interaction options, THEN Talk, Gift, and Date buttons for "artemis" are disabled or hidden.
  - [ ] AC4: GIVEN "artemis" is dispatched and is the current combat captain, WHEN the player attempts to start combat, THEN CombatSystem receives no captain (captain_chip_bonus=0, captain_mult_modifier=1.0) and combat proceeds without crash.
  - [ ] AC5: GIVEN the player has only one met companion and that companion is dispatched, WHEN camp interactions are attempted, THEN all interaction buttons for that companion are disabled; the game does not crash or lock.
  - [ ] AC6: GIVEN a dispatch is collected and `dispatched = false` is set, WHEN the Camp UI renders, THEN the companion's interaction options are restored (Talk/Gift/Date enabled again).
- **Test Evidence**: `tests/unit/exploration/companion_lock_test.gd`
- **Status**: Ready
- **Depends On**: STORY-EXPLORE-001, STORY-EXPLORE-002

---

### STORY-EXPLORE-005: Mission Complete Collection

- **Type**: Logic
- **TR-IDs**: TR-explore-006, TR-explore-007, TR-explore-008, TR-explore-012, TR-explore-013
- **ADR Guidance**: No ADR — implements GDD directly. Collection: calculate gold/XP/item, write gold to player.gold, write XP to companion.xp, call Equipment.award_item() if item rolled, clear dispatch save state, set dispatched=false.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN a completed dispatch (time_remaining==0), WHEN `collect()` is called, THEN `player.gold` increases by the calculated gold reward and `companion.xp` increases by the calculated XP reward.
  - [ ] AC2: GIVEN a completed dispatch with item_find_chance=44% and the item roll succeeds, WHEN `collect()` is called, THEN `Equipment.award_item(item)` is called once with a valid item dict.
  - [ ] AC3: GIVEN a completed dispatch where the item roll fails, WHEN `collect()` is called, THEN `Equipment.award_item()` is NOT called.
  - [ ] AC4: GIVEN `collect()` completes, WHEN SaveManager is inspected, THEN dispatch state fields (dispatch_start_utc, dispatch_companion_id, dispatch_duration_hours, dispatch_mission_type) are all cleared.
  - [ ] AC5: GIVEN `collect()` completes, WHEN `CompanionState.is_dispatched(companion_id)` is called, THEN returns false.
  - [ ] AC6: GIVEN pending_equipment is full and the dispatch item roll succeeds, WHEN `collect()` is called, THEN the reward summary shows "[Item Name] — Lost (Inventory Full)" and gold/XP are still awarded correctly.
  - [ ] AC7: GIVEN `collect()` is called when time_remaining > 0 (dispatch not complete), WHEN the collect action is attempted, THEN it is rejected — no rewards distributed and no state change occurs.
- **Test Evidence**: `tests/unit/exploration/collection_test.gd`
- **Status**: Ready
- **Depends On**: STORY-EXPLORE-003, STORY-EXPLORE-004

---

### STORY-EXPLORE-006: Exploration UI — Dispatch and Collect

- **Type**: UI
- **TR-IDs**: TR-explore-001, TR-explore-004, TR-explore-010
- **ADR Guidance**: No ADR — implements GDD directly. UI reads `get_dispatch_state()` from ExplorationSystem to render timer and availability. Camp displays "On Mission" indicator for dispatched companions.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN no active dispatch, WHEN the Exploration panel in Camp is displayed, THEN a list of available met companions is shown with "Dispatch" buttons, and mission type + duration selectors are present.
  - [ ] AC2: GIVEN an active dispatch with time_remaining=5400 (1h30m remaining), WHEN the Exploration panel is displayed, THEN the timer shows "01:30" and the "Dispatch" button is replaced with a "Waiting..." state.
  - [ ] AC3: GIVEN time_remaining reaches 0 (dispatch complete), WHEN the Exploration panel is displayed, THEN the timer shows "Ready!" and a "Collect" button appears enabled.
  - [ ] AC4: GIVEN the dispatched companion is shown in the companion roster, WHEN rendered, THEN that companion shows an "On Mission" visual indicator and all interaction buttons (Talk/Gift/Date) are visually disabled.
  - [ ] AC5: GIVEN the player taps "Collect" and the reward sequence plays, WHEN the reward summary card is shown, THEN it displays: companion portrait, gold earned, XP earned, and item name (or "No item found"). If inventory was full, it shows "[Item Name] — Lost (Inventory Full)".
  - [ ] AC6: GIVEN a player attempts to dispatch a second companion while one is active, WHEN the Dispatch button is tapped, THEN a toast message appears: "A companion is already on a mission" and no dispatch occurs.
  - [ ] AC7: GIVEN all Exploration UI interactive elements, WHEN measured, THEN each meets the 44x44px minimum touch target requirement.
- **Test Evidence**: `production/qa/evidence/exploration-ui-layout.md`
- **Status**: Ready
- **Depends On**: STORY-EXPLORE-004, STORY-EXPLORE-005

---

### STORY-EXPLORE-007: Integration with GameStore and Hub

- **Type**: Integration
- **TR-IDs**: TR-explore-001, TR-explore-011, TR-explore-012, TR-explore-013
- **ADR Guidance**: No ADR — implements GDD directly. ExplorationSystem reads from CompanionState (via GameStore), writes to SaveManager, and routes XP through the same companion XP path as combat. Equipment award uses Equipment.award_item() (same path as combat drops).
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN a 4-hour Hunt dispatch is started in-session, WHEN the app is closed and reopened, THEN the Camp Hub renders the timer correctly (time_remaining reflects real elapsed time, not session time).
  - [ ] AC2: GIVEN a dispatch completes and XP is awarded, WHEN `CompanionState.get_xp(companion_id)` is called, THEN the value has increased by the calculated XP reward (same accumulation path as combat XP).
  - [ ] AC3: GIVEN a dispatch completes with an item find, WHEN `EquipmentSystem.get_pending_equipment()` is called, THEN the new item appears in the pending_equipment list (if space was available).
  - [ ] AC4: GIVEN a companion is dispatched during a session and combat is started without selecting a captain, WHEN CombatSystem initializes, THEN captain_chip_bonus=0 and captain_mult_modifier=1.0 (dispatched companion cannot be captain).
  - [ ] AC5: GIVEN the ExplorationSystem emits `dispatch_completed` and the Camp Hub listens, WHEN the signal fires, THEN the Hub UI updates to show "Ready!" without requiring an app restart.
  - [ ] AC6: GIVEN a dispatch state saved by a previous app version (dispatch_duration_hours=3 — invalid), WHEN the app loads the corrupt save, THEN ExplorationSystem defaults to 1-hour multipliers, logs a warning, and clears the dispatch on collection without crash.
- **Test Evidence**: `tests/integration/exploration/gamestore_integration_test.gd`
- **Status**: Ready
- **Depends On**: STORY-EXPLORE-005, STORY-EXPLORE-006
