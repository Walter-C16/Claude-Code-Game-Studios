# Stories: Romance & Social

> **Epic**: romance-social
> **Layer**: Feature
> **ADR**: ADR-0010
> **Manifest Version**: 2026-04-09
> **Total Stories**: 10

---

### STORY-RS-001: Token Pool — Daily Allocation and Spending

- **Type**: Logic
- **TR-IDs**: TR-romance-social-001, TR-romance-social-007, TR-romance-social-008
- **ADR Guidance**: RomanceSocial autoload owns token state; all token mutations go through GameStore typed setters. Midnight UTC crossing detection must use `Time.get_datetime_dict_from_system()`; negative date gaps treated as 0 to protect against clock rollback.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN tokens = 3, WHEN `spend_token()` is called, THEN tokens decreases to 2 and GameStore `_dirty` is set.
  - [ ] AC2: GIVEN tokens = 0, WHEN `spend_token()` is called, THEN it returns false and tokens remains 0.
  - [ ] AC3: GIVEN a midnight UTC crossing occurs while the app is open, WHEN `_check_midnight_reset()` fires, THEN tokens reset to 3 and a new day's streak evaluation is triggered.
  - [ ] AC4: GIVEN the device clock jumps backward (negative gap), WHEN the gap is computed, THEN it is treated as 0 (no reset, no streak change).
  - [ ] AC5: GIVEN the token count is read immediately after reset, THEN `get_token_count()` returns 3.
- **Test Evidence**: `tests/unit/romance_social/token_pool_test.gd`
- **Status**: Ready
- **Depends On**: None

---

### STORY-RS-002: Streak System — Consecutive-Day Tracking and Multiplier Lookup

- **Type**: Logic
- **TR-IDs**: TR-romance-social-002, TR-romance-social-023, TR-romance-social-026
- **ADR Guidance**: Streak multiplier uses a 5-tier lookup table [1.0, 1.1, 1.25, 1.4, 1.5] loaded from config (not hardcoded). Streak increments on gap=1 day, resets on gap >= 2 days, first session = streak 1. Camp gains only.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN `last_interaction_date` is yesterday (gap=1), WHEN a camp interaction completes, THEN streak increments by 1.
  - [ ] AC2: GIVEN gap >= 2 days since last interaction, WHEN a camp interaction completes, THEN streak resets to 1.
  - [ ] AC3: GIVEN no prior interaction (first session ever), WHEN first camp interaction occurs, THEN streak = 1.
  - [ ] AC4: GIVEN streak = 5 (or more), WHEN `get_streak_multiplier()` is called, THEN it returns 1.5 (capped at tier 5).
  - [ ] AC5: GIVEN streak = 3, WHEN `get_streak_multiplier()` is called, THEN it returns 1.25.
  - [ ] AC6: GIVEN streak values and multipliers, THEN all 5 tier values are loaded from the config data file, not literals in code.
- **Test Evidence**: `tests/unit/romance_social/streak_system_test.gd`
- **Status**: Ready
- **Depends On**: None

---

### STORY-RS-003: Relationship Gain Formula and RL Write Pipeline

- **Type**: Logic
- **TR-IDs**: TR-romance-social-014, TR-romance-social-017, TR-romance-social-018, TR-romance-social-026, TR-romance-social-027
- **ADR Guidance**: `floor(base_RL * streak_multiplier)`; min 1 except base-0 stays 0. All RL writes clamp to [0, 100]. Stage re-evaluated after every write. Stage re-evaluation also occurs on save load to catch desync.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN base_RL=3, streak=5 (1.40x), WHEN formula is applied, THEN RL gain = floor(3 * 1.40) = 4.
  - [ ] AC2: GIVEN base_RL=4 (Happy Talk), streak=5 (1.40x), WHEN formula is applied, THEN RL gain = floor(4 * 1.40) = 5.
  - [ ] AC3: GIVEN current RL=98 and gain=5, WHEN written, THEN clamped RL = 100 (not 103).
  - [ ] AC4: GIVEN base_RL=0 (disliked gift), WHEN formula is applied, THEN gain = 0 (not bumped to 1).
  - [ ] AC5: GIVEN RL crosses a stage threshold (e.g. RL reaches 30), WHEN `_evaluate_stage()` is called, THEN `romance_stage_changed` signal is queued or emitted.
  - [ ] AC6: GIVEN save data is loaded with a desync between RL and romance_stage, WHEN the game boots, THEN stage is re-evaluated and corrected.
- **Test Evidence**: `tests/unit/romance_social/rl_formula_test.gd`
- **Status**: Ready
- **Depends On**: None

---

### STORY-RS-004: Mood State Machine — Transitions, Priority, and Expiry

- **Type**: Logic
- **TR-IDs**: TR-romance-social-003, TR-romance-social-006, TR-romance-social-019
- **ADR Guidance**: 5 moods: Content/Happy/Lonely/Annoyed/Excited. `current_mood` and `mood_expiry_date` stored in GameStore via CompanionState. Decay to Content on expiry. Priority on simultaneous triggers: Excited > Happy > Annoyed > Lonely > Content.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN companion is Content and a Talk succeeds, WHEN mood is updated, THEN mood transitions to Happy.
  - [ ] AC2: GIVEN `mood_expiry_date` is in the past, WHEN mood is evaluated, THEN mood decays to Content.
  - [ ] AC3: GIVEN two mood triggers fire simultaneously (e.g. Happy and Annoyed), WHEN priority is resolved, THEN Excited > Happy > Annoyed > Lonely > Content wins.
  - [ ] AC4: GIVEN mood durations are read, THEN all values come from the config data file (not hardcoded).
  - [ ] AC5: GIVEN a mood is set, WHEN `get_mood(companion_id)` is called, THEN it returns the current mood enum value.
- **Test Evidence**: `tests/unit/romance_social/mood_state_machine_test.gd`
- **Status**: Ready
- **Depends On**: None

---

### STORY-RS-005: Talk and Gift Interactions — Camp Action Logic

- **Type**: Logic
- **TR-IDs**: TR-romance-social-010, TR-romance-social-017, TR-romance-social-021, TR-romance-social-025
- **ADR Guidance**: `do_talk()` and `do_gift()` validate tokens > 0 and met==true before proceeding. Gift preference discovery is through dates only, not gifts (TR-021). Dialogue deltas applied flat with no streak multiplier (TR-010). Processing within 16ms.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN tokens > 0 and companion is met, WHEN `do_talk(id)` is called, THEN RL is gained, token is spent, mood is updated, and result dict is returned.
  - [ ] AC2: GIVEN companion mood is Happy, WHEN `do_talk(id)` is called, THEN base_RL = 4 (not 3).
  - [ ] AC3: GIVEN a liked gift item (matching known_likes category), WHEN `do_gift(id, item_id)` is called, THEN RL gain = 2.
  - [ ] AC4: GIVEN a neutral gift, WHEN `do_gift(id, item_id)` is called, THEN RL gain = 1.
  - [ ] AC5: GIVEN a disliked gift (matching known_dislikes), WHEN `do_gift(id, item_id)` is called, THEN RL gain = 0.
  - [ ] AC6: GIVEN tokens = 0, WHEN `do_talk(id)` or `do_gift(id, item_id)` is called, THEN it returns an error dict and no state changes.
  - [ ] AC7: GIVEN a dialogue delta of -5 RL arrives via EventBus, WHEN `_on_relationship_changed()` handles it, THEN exactly -5 is applied with no streak multiplier.
- **Test Evidence**: `tests/unit/romance_social/camp_interactions_test.gd`
- **Status**: Ready
- **Depends On**: STORY-RS-001, STORY-RS-002, STORY-RS-003, STORY-RS-004

---

### STORY-RS-006: Date Sub-System — 4-Round Activity Scoring

- **Type**: Logic
- **TR-IDs**: TR-romance-social-004, TR-romance-social-015, TR-romance-social-022
- **ADR Guidance**: 4 rounds, 3 activity options per round drawn from 6 categories with replacement. Romance stage snapshot taken at `start_date()` entry; live stage changes during date are ignored. Preference weights are static hidden values per companion.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN a date starts, WHEN the date is initialized, THEN romance_stage is snapshotted and locked for the duration.
  - [ ] AC2: GIVEN a date has 4 rounds, WHEN each round presents options, THEN exactly 3 activity options are shown, drawn from 6 categories with replacement.
  - [ ] AC3: GIVEN a player selects an activity matching a companion's high-preference category, WHEN the round scores, THEN the RL contribution reflects the hidden preference weight.
  - [ ] AC4: GIVEN romance_stage changes mid-date (edge case), WHEN the date resolves, THEN the original snapshotted stage is used for scoring (not the updated one).
  - [ ] AC5: GIVEN all 4 rounds are completed, WHEN the date ends, THEN total RL gained is applied in a single write, token is consumed, and the date scene closes.
- **Test Evidence**: `tests/unit/romance_social/date_subsystem_test.gd`
- **Status**: Ready
- **Depends On**: STORY-RS-003

---

### STORY-RS-007: Combat Buffs — Generation, Replacement, and Persistence

- **Type**: Logic
- **TR-IDs**: TR-romance-social-005, TR-romance-social-012, TR-romance-social-020, TR-romance-social-011
- **ADR Guidance**: Per-stage lookup for `social_buff_chips`, `social_buff_mult`, `combats_remaining`. Replacement rule: replace only if (new_chips + new_mult) > (old_chips + old_mult). Buff persisted to save data. Captain +1 RL on combat victory.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN a Gift interaction succeeds at romance_stage 2, WHEN buff is generated, THEN chips/mult/combats values match the stage-2 row in config.
  - [ ] AC2: GIVEN an active buff with sum=5 and a new buff with sum=4, WHEN replacement is evaluated, THEN the old buff is retained.
  - [ ] AC3: GIVEN an active buff with sum=5 and a new buff with sum=6, WHEN replacement is evaluated, THEN the new buff replaces the old.
  - [ ] AC4: GIVEN `combats_remaining` > 0, WHEN `combat_completed` fires, THEN `combats_remaining` decrements by 1 and the buff is re-persisted.
  - [ ] AC5: GIVEN `combats_remaining` reaches 0, WHEN evaluated, THEN the active_combat_buff is cleared.
  - [ ] AC6: GIVEN the companion is captain and combat is won, WHEN `_on_combat_completed()` fires, THEN captain companion gains exactly +1 RL (no streak multiplier).
  - [ ] AC7: GIVEN a save/load cycle, WHEN active_combat_buff is read back, THEN it matches the pre-save value.
- **Test Evidence**: `tests/unit/romance_social/combat_buffs_test.gd`
- **Status**: Ready
- **Depends On**: STORY-RS-003

---

### STORY-RS-008: romance_stage_changed Signal and Dialogue Delta Events

- **Type**: Integration
- **TR-IDs**: TR-romance-social-009, TR-romance-social-013, TR-romance-social-024, TR-romance-social-028
- **ADR Guidance**: `romance_stage_changed(companion_id, old, new)` emitted via EventBus; autosave triggered. Signal queued during active dialogue and applied after `dialogue_ended`. `companion_met(companion_id)` emitted for reactive UI. Additional state fields persisted: `current_mood`, `mood_expiry_date`, `current_streak`, `last_interaction_date`, `daily_tokens_remaining`, `active_combat_buff`.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN RL crosses a stage threshold outside of dialogue, WHEN stage evaluates, THEN `EventBus.romance_stage_changed` emits with (companion_id, old_stage, new_stage) and SaveManager autosaves.
  - [ ] AC2: GIVEN RL crosses a stage threshold during active dialogue, WHEN dialogue is ongoing, THEN `romance_stage_changed` is queued (not emitted) and fires only after `dialogue_ended`.
  - [ ] AC3: GIVEN a companion's `met` flag changes to true, WHEN the change is applied, THEN `EventBus.companion_met(companion_id)` is emitted.
  - [ ] AC4: GIVEN a save is written and loaded, THEN all 6 additional CompanionState fields (`current_mood`, `mood_expiry_date`, `current_streak`, `last_interaction_date`, `daily_tokens_remaining`, `active_combat_buff`) round-trip correctly.
  - [ ] AC5: GIVEN `romance_stage_changed` fires, THEN BlessingSystem's slot availability is derivable from the new stage (verified by blessing slot unlock test in divine-blessings epic).
- **Test Evidence**: `tests/integration/romance_social/stage_changed_integration_test.gd`
- **Status**: Ready
- **Depends On**: STORY-RS-003, STORY-RS-004, STORY-RS-005

---

### STORY-RS-009: Visual/Audio Feedback — Stage Advance Ceremony and Portraits

- **Type**: UI
- **TR-IDs**: TR-romance-social-016
- **ADR Guidance**: Presentation layer only. All Control nodes must inherit shared Theme .tres. Touch targets >= 44x44px. No game state logic in this scene.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN a romance_stage_changed event fires, WHEN the ceremony plays, THEN companion portrait crossfades to the new stage portrait within 1 second.
  - [ ] AC2: GIVEN stage advance ceremony, WHEN it plays, THEN particle effects fire and audio sting plays (asset stubs acceptable for milestone).
  - [ ] AC3: GIVEN the ceremony completes, WHEN player taps anywhere, THEN ceremony dismisses and returns to the triggering screen.
  - [ ] AC4: GIVEN all UI elements in the ceremony, THEN no hardcoded color values exist; all reference theme tokens.
- **Test Evidence**: `production/qa/evidence/romance-social/stage-ceremony-screenshot.png`
- **Status**: Ready
- **Depends On**: STORY-RS-008

---

### STORY-RS-010: RomanceSocial Autoload — Boot, GameStore Integration, EventBus Wiring

- **Type**: Integration
- **TR-IDs**: TR-romance-social-025, TR-romance-social-026, TR-romance-social-027, TR-romance-social-028
- **ADR Guidance**: RomanceSocial is an autoload (9th in boot order per ADR-0006). Must not reference autoloads later than itself in `_ready()`. All config values (streak thresholds, buff values, mood durations, RL bases) loaded from data files. Stage re-evaluation on load.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN the game boots, WHEN RomanceSocial's `_ready()` runs, THEN it connects to EventBus signals (`relationship_changed`, `trust_changed`, `combat_completed`, `dialogue_ended`) without referencing later autoloads.
  - [ ] AC2: GIVEN the game boots, WHEN config is loaded, THEN all tuning values (streak tiers, buff table, mood durations, RL base values) come from data files — no hardcoded literals in GDScript.
  - [ ] AC3: GIVEN save data is loaded, WHEN RomanceSocial initializes companion state, THEN `_evaluate_stage()` runs for all companions to catch any desync.
  - [ ] AC4: GIVEN a camp interaction (`do_talk`, `do_gift`, `start_date`) completes end-to-end, WHEN measured, THEN total processing time is under 16ms (one frame at 60fps).
  - [ ] AC5: GIVEN RomanceSocial runs as the sole writer of relationship state, THEN no other autoload or scene script calls `CompanionState.set_relationship_level()` directly.
- **Test Evidence**: `tests/integration/romance_social/autoload_boot_test.gd`
- **Status**: Ready
- **Depends On**: STORY-RS-005, STORY-RS-006, STORY-RS-007, STORY-RS-008
