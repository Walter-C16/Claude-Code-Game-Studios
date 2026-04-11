# Stories: Abyss Mode Epic

> **Epic**: Abyss Mode
> **Layer**: Feature (Alpha)
> **Governing ADRs**: ADR-0007
> **Control Manifest Version**: 2026-04-10
> **Story Count**: 12

---

### STORY-ABYSS-001: Ante Threshold Progression Data

- **Type**: Logic
- **TR-IDs**: TR-abyss-001, TR-abyss-018
- **ADR Guidance**: No ADR — implements GDD directly. Thresholds are hand-tuned values loaded from `assets/data/abyss_config.json`. No values hardcoded in `.gd` files.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN `abyss_config.json` is loaded, WHEN `AbyssConfig.get_threshold(ante)` is called for antes 1–8, THEN returns [300, 500, 800, 1200, 1800, 2700, 4000, 6000] respectively.
  - [ ] AC2: GIVEN ante index out of bounds (0 or 9), WHEN `get_threshold(ante)` is called, THEN returns -1 and logs a warning (does not crash).
  - [ ] AC3: GIVEN `abyss_config.json` contains all tuning knobs (HANDS_PER_ANTE, DISCARDS_PER_ANTE, BASE_HAND_GOLD, ANTE_COMPLETION_BONUS, SHOP_SLOTS, item costs), WHEN the config is loaded, THEN all constants are readable with correct default values.
  - [ ] AC4: GIVEN `abyss_config.json` fails to load or is malformed, WHEN config is accessed, THEN safe defaults are returned and an error is logged (does not prevent the game from running).
  - [ ] AC5: GIVEN no hardcoded constants in `abyss_config.gd` or `abyss_runner.gd`, WHEN the config file is inspected, THEN all threshold and cost values originate from the JSON file.
- **Test Evidence**: `tests/unit/abyss_mode/abyss_config_test.gd`
- **Status**: Ready
- **Depends On**: None

---

### STORY-ABYSS-002: Run State Machine

- **Type**: Logic
- **TR-IDs**: TR-abyss-003, TR-abyss-011
- **ADR Guidance**: No ADR — implements GDD directly. State machine states: LOBBY, ANTE, SHOP, COMPLETE, DEFEAT. Transitions are driven by ante results and shop completion. State NOT persisted mid-ante (same as CombatSystem per ADR-0007).
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN AbyssRunner is initialized, WHEN `start_run()` is called, THEN state transitions LOBBY → ANTE and ante_current is set to 1.
  - [ ] AC2: GIVEN state is ANTE and combat_completed fires with victory=true, WHEN AbyssRunner handles the signal, THEN state transitions ANTE → SHOP (unless ante_current == 8, in which case ANTE → COMPLETE).
  - [ ] AC3: GIVEN state is ANTE and combat_completed fires with victory=false, WHEN AbyssRunner handles the signal, THEN state transitions ANTE → DEFEAT.
  - [ ] AC4: GIVEN state is SHOP and player taps "Continue", WHEN shop is dismissed, THEN state transitions SHOP → ANTE and ante_current increments by 1.
  - [ ] AC5: GIVEN state is COMPLETE (all 8 antes done), WHEN AbyssRunner emits run_completed, THEN the payload includes: antes_completed=8, gold_earned, final_score, is_new_highscore.
  - [ ] AC6: GIVEN state is DEFEAT, WHEN AbyssRunner emits run_ended, THEN the payload includes: antes_completed (last completed ante), final_score, is_new_highscore.
  - [ ] AC7: GIVEN any terminal state (COMPLETE or DEFEAT), WHEN `start_run()` is called again, THEN AbyssRunner resets to LOBBY with fresh run state (gold=0, buffs cleared, ante_current=0).
- **Test Evidence**: `tests/unit/abyss_mode/run_state_machine_test.gd`
- **Status**: Ready
- **Depends On**: STORY-ABYSS-001

---

### STORY-ABYSS-003: Between-Ante Shop System

- **Type**: Logic
- **TR-IDs**: TR-abyss-004, TR-abyss-005, TR-abyss-007, TR-abyss-016
- **ADR Guidance**: No ADR — implements GDD directly. Shop generates 3 slots each visit. Each slot is one of: card removal, enhancement (Foil/Holographic/Polychrome applied to a deck card), or temporary run buff. Stock generated fresh per visit; no re-roll mechanic. Gold cannot go below 0.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN the shop is opened after a successful ante, WHEN `ShopSystem.generate_stock()` is called, THEN exactly 3 ShopSlot objects are returned.
  - [ ] AC2: GIVEN a shop slot of type CARD_REMOVAL with cost 20, WHEN `purchase(slot)` is called with run_gold=25, THEN run_gold decrements to 5 and a card removal is staged.
  - [ ] AC3: GIVEN a shop slot of type ENHANCEMENT_FOIL with cost 15, WHEN `purchase(slot)` is called with run_gold=10, THEN purchase is rejected (insufficient gold), run_gold unchanged.
  - [ ] AC4: GIVEN run_gold=0, WHEN any purchase is attempted, THEN the purchase is rejected and gold remains 0 (never goes negative).
  - [ ] AC5: GIVEN shop stock with 3 slots and all 3 are purchased, WHEN the shop UI queries slot availability, THEN all slots show "Purchased" state and no further purchases are possible.
  - [ ] AC6: GIVEN a card enhancement slot (Holographic, cost 20), WHEN purchased, THEN the enhancement is applied to a card in the player's current run deck (not the persistent deck).
  - [ ] AC7: GIVEN a card that already has Foil enhancement, WHEN a Holographic enhancement is purchased targeting the same card, THEN the card becomes Foil+Holographic (stacking allowed per GDD EC-8).
- **Test Evidence**: `tests/unit/abyss_mode/shop_system_test.gd`
- **Status**: Ready
- **Depends On**: STORY-ABYSS-001, STORY-ABYSS-002

---

### STORY-ABYSS-004: Run-Scoped Gold Economy

- **Type**: Logic
- **TR-IDs**: TR-abyss-005, TR-abyss-006, TR-abyss-008
- **ADR Guidance**: No ADR — implements GDD directly. Gold is run-scoped: earned per hand and per ante, spent in shop, cleared on run end. Main-game gold is never touched. Golden Hand buff modifies per-hand gold earned.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN 4 hands played in an ante with no buffs, WHEN gold is calculated, THEN gold_earned = (4 * 2) + 15 = 23.
  - [ ] AC2: GIVEN Golden Hand buff is active (adds +5/hand), WHEN 4 hands are played, THEN gold_earned = (4 * (2+5)) + 15 = 43.
  - [ ] AC3: GIVEN run_gold=50 at run start after ante 1, WHEN a shop item costing 20 is purchased, THEN run_gold=30.
  - [ ] AC4: GIVEN run ends (COMPLETE or DEFEAT), WHEN GameStore is inspected, THEN main game gold is unchanged (run gold is not carried over).
  - [ ] AC5: GIVEN a new run starts, WHEN AbyssRunner initializes, THEN run_gold=0 (no gold carries from a previous run).
  - [ ] AC6: GIVEN the hand gold award is triggered, WHEN the combat_completed payload includes hands_used, THEN AbyssRunner awards BASE_HAND_GOLD per hand played from the payload (not a fixed 4).
- **Test Evidence**: `tests/unit/abyss_mode/run_gold_test.gd`
- **Status**: Ready
- **Depends On**: STORY-ABYSS-002

---

### STORY-ABYSS-005: Deck Modifications During Run

- **Type**: Logic
- **TR-IDs**: TR-abyss-004, TR-abyss-016, TR-abyss-017
- **ADR Guidance**: No ADR — implements GDD directly. Card removals and enhancements are applied to a run-scoped deck copy, not the player's persistent deck. On next run, deck resets to clean 52 cards.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN a run starts, WHEN AbyssRunner initializes the run deck, THEN it creates a copy of the player's standard 52-card deck (persistent deck is not mutated).
  - [ ] AC2: GIVEN a card removal is purchased targeting card "King of Spades", WHEN the removal is applied, THEN that card is absent from the run deck for all subsequent antes.
  - [ ] AC3: GIVEN a card removal applied during a run, WHEN the run ends and a new run starts, THEN the deck resets to all 52 cards (removal is not permanent).
  - [ ] AC4: GIVEN an enhancement (Foil) applied to "Ace of Hearts" during a run, WHEN that card is drawn in a subsequent ante, THEN it carries the Foil enhancement in scoring.
  - [ ] AC5: GIVEN an enhancement applied during a run, WHEN the run ends and a new run starts, THEN the card has no enhancement (enhancement is not persistent).
  - [ ] AC6: GIVEN the run deck has had 5 cards removed, WHEN CombatSystem receives the deck for the next ante, THEN it receives a 47-card deck (removals accumulate across antes within a run).
- **Test Evidence**: `tests/unit/abyss_mode/deck_modifications_test.gd`
- **Status**: Ready
- **Depends On**: STORY-ABYSS-003

---

### STORY-ABYSS-006: Temporary Run Buffs

- **Type**: Logic
- **TR-IDs**: TR-abyss-008, TR-abyss-009
- **ADR Guidance**: No ADR — implements GDD directly. 6 buff types with defined effects. Buffs stack additively. Persist until run end. Hunter's Focus and Divine Favor inject into the scoring pipeline at the abyss_buff layer (after equipment, before blessings in the abyss pipeline context). Golden Hand modifies per-hand gold award.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN Hunter's Focus buff is purchased (cost 10), WHEN a hand is scored in any subsequent ante, THEN chip_bonus receives a flat +10 contribution from the buff.
  - [ ] AC2: GIVEN Divine Favor buff is purchased (cost 15), WHEN a hand is scored, THEN mult_bonus receives a flat +0.5 contribution from the buff.
  - [ ] AC3: GIVEN Last Gambit buff is purchased (cost 25), WHEN the next ante begins, THEN hands_allowed for that ante and all subsequent antes is 4+1=5.
  - [ ] AC4: GIVEN Clear Mind buff is purchased (cost 20), WHEN the next ante begins, THEN discards_allowed is 4+1=5.
  - [ ] AC5: GIVEN Fortune's Eye buff is purchased (cost 10), WHEN the post-run reward roll triggers, THEN item find chance for the completion reward is increased by 20%.
  - [ ] AC6: GIVEN two Hunter's Focus buffs purchased (stacking), WHEN a hand is scored, THEN chip_bonus receives +20 (stacks additively per GDD Rule 4).
  - [ ] AC7: GIVEN any buff is active, WHEN the run ends (COMPLETE or DEFEAT), THEN the buff is cleared from run state (buffs do not persist to next run).
- **Test Evidence**: `tests/unit/abyss_mode/run_buffs_test.gd`
- **Status**: Ready
- **Depends On**: STORY-ABYSS-003, STORY-ABYSS-004

---

### STORY-ABYSS-007: Run Summary and Reward Distribution

- **Type**: Logic
- **TR-IDs**: TR-abyss-013, TR-abyss-014
- **ADR Guidance**: No ADR — implements GDD directly. Post-run summary covers antes completed, gold earned (lost), score highscore update. Full-run completion (8 antes) triggers a Legendary-floor equipment drop via Equipment's standard award path.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN a run ends (win or loss), WHEN `AbyssRunner.build_run_summary()` is called, THEN the summary dict contains: antes_completed (int), total_gold_earned (int), best_score (int), is_new_highscore (bool).
  - [ ] AC2: GIVEN the current run's best score exceeds `abyss_highscore` in SaveManager, WHEN the summary is built, THEN `abyss_highscore` is updated and `is_new_highscore = true`.
  - [ ] AC3: GIVEN a run ends at ante 3 (defeat), WHEN the summary is built, THEN antes_completed=3 and no equipment reward is awarded.
  - [ ] AC4: GIVEN all 8 antes are completed (COMPLETE state), WHEN `award_completion_reward()` is called, THEN `Equipment.award_item(item)` is called with an item at Legendary rarity floor.
  - [ ] AC5: GIVEN Fortune's Eye buff is active at run completion, WHEN the Legendary drop is rolled, THEN the item find chance modifier (+20%) is applied to the roll.
  - [ ] AC6: GIVEN the player's `pending_equipment` is full when the completion reward is awarded, WHEN `award_item()` is called, THEN the Equipment system handles the overflow (discard + notification) without AbyssRunner crashing.
- **Test Evidence**: `tests/unit/abyss_mode/run_summary_test.gd`
- **Status**: Ready
- **Depends On**: STORY-ABYSS-002, STORY-ABYSS-006

---

### STORY-ABYSS-008: Abyss Entry from Hub

- **Type**: Integration
- **TR-IDs**: TR-abyss-003, TR-abyss-012
- **ADR Guidance**: ADR-0007 — Scene transition uses SceneManager.change_scene(SceneId); no raw .tscn paths. Weekly modifier read from AbyssModifiers at run start and stored in run save.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN the player is in the Hub scene, WHEN the Abyss entry button is tapped, THEN SceneManager transitions to the Abyss scene using a valid SceneId (not a raw string path).
  - [ ] AC2: GIVEN the Abyss entry screen loads, WHEN the active weekly modifier is displayed, THEN the modifier name and effect text match the current modifier from AbyssModifiers.
  - [ ] AC3: GIVEN the player starts a run, WHEN AbyssRunner initializes, THEN the active modifier_id is read and stored in run save state.
  - [ ] AC4: GIVEN a run is in progress (active=true in save) when the Abyss scene is loaded, WHEN AbyssRunner initializes, THEN it restores the run from save state (ante_current, gold, buffs, removals, enhancements, modifier_id) rather than starting fresh.
  - [ ] AC5: GIVEN the Monday UTC rotation fires while a run is active, WHEN AbyssRunner reads its stored modifier_id, THEN the run continues with the original modifier (not the new weekly modifier).
- **Test Evidence**: `tests/integration/abyss_mode/abyss_entry_test.gd`
- **Status**: Ready
- **Depends On**: STORY-ABYSS-002, STORY-ABYSS-010

---

### STORY-ABYSS-009: Integration with CombatSystem

- **Type**: Integration
- **TR-IDs**: TR-abyss-001, TR-abyss-002, TR-abyss-009, TR-abyss-015
- **ADR Guidance**: ADR-0007 — AbyssRunner constructs an enemy_config dict per ante and calls CombatSystem via the standard interface. Persistent blessings and equipment bonuses apply identically in Abyss combat as in story combat. Score overflow soft cap handled in display layer.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN ante_current=3 (threshold=800), WHEN AbyssRunner constructs the enemy_config, THEN the config contains score_threshold=800, hands_allowed=4, discards_allowed=4 (plus any buff adjustments).
  - [ ] AC2: GIVEN active divine blessings and equipped items in the main game, WHEN Abyss ante combat resolves a hand, THEN blessing_chips, blessing_mult, weapon_chip_bonus, and amulet_mult_bonus are all applied (verified by comparing score to expected formula output).
  - [ ] AC3: GIVEN the same hand composition played in story combat and Abyss combat with identical blessings/equipment, WHEN scores are compared, THEN they are equal (pipeline reuse verified).
  - [ ] AC4: GIVEN run buff Hunter's Focus (+10 chips) is active, WHEN a hand is scored in an Abyss ante, THEN chip_bonus includes the +10 on top of the standard pipeline contributions.
  - [ ] AC5: GIVEN a score that would exceed 9,999,999, WHEN the score is displayed, THEN it shows "9,999,999+" but combat continues to resolve correctly against the threshold.
  - [ ] AC6: GIVEN ante combat ends with victory=true, WHEN AbyssRunner receives combat_completed, THEN hands_used from the payload is used to calculate gold earned (not a fixed 4).
- **Test Evidence**: `tests/integration/abyss_mode/combat_integration_test.gd`
- **Status**: Ready
- **Depends On**: STORY-ABYSS-006, STORY-ABYSS-007

---

### STORY-ABYSS-010: Weekly Modifier Slot

- **Type**: Logic
- **TR-IDs**: TR-abyss-012
- **ADR Guidance**: No ADR — implements GDD directly. AbyssModifiers provides the active modifier at run start. The modifier_id is stored in run save. Rotation occurs Monday 00:00 UTC and is a read from the modifier data source (abyss-modifiers.md defines the data, not this epic).
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN AbyssModifiers provides a modifier with id="glass_cannon" and effect rules, WHEN AbyssRunner reads the modifier at run start, THEN modifier_id="glass_cannon" is stored in run save.
  - [ ] AC2: GIVEN modifier_id is stored in run save, WHEN the run is resumed after app close, THEN AbyssRunner reloads the modifier by id and applies the same effect rules.
  - [ ] AC3: GIVEN a modifier with effect mult_bonus_flat=+2.0 (example "glass_cannon" effect), WHEN a hand is scored in any ante, THEN the modifier's effect is applied in addition to standard pipeline contributions.
  - [ ] AC4: GIVEN modifier_id = "" (no modifier active), WHEN the pipeline runs, THEN no modifier contribution is applied and no crash occurs.
  - [ ] AC5: GIVEN a modifier's `rotation_day` has passed (simulated), WHEN a new run starts, THEN AbyssModifiers returns the new modifier (not the expired one), and the run's modifier_id is updated.
- **Test Evidence**: `tests/unit/abyss_mode/weekly_modifier_test.gd`
- **Status**: Ready
- **Depends On**: STORY-ABYSS-001

---

### STORY-ABYSS-011: Abyss UI — Ante Display and Run Progress

- **Type**: UI
- **TR-IDs**: TR-abyss-001, TR-abyss-003, TR-abyss-004, TR-abyss-005
- **ADR Guidance**: No ADR — implements GDD directly. UI uses standard UITheme conventions. Abyss entry screen shows active modifier. Between-ante shop UI presents stock, costs, current gold, and purchase confirmation. Run progress shows ante number and threshold.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN the Abyss entry screen, WHEN rendered, THEN the active weekly modifier name and effect summary are displayed before the run starts.
  - [ ] AC2: GIVEN ante_current=4 (threshold=1200), WHEN the combat HUD is shown, THEN the ante number ("Ante 4") and score threshold ("1,200") are visible and correct.
  - [ ] AC3: GIVEN the between-ante shop screen, WHEN rendered, THEN exactly 3 shop slots are displayed, each showing item type, stat effect, and cost in gold.
  - [ ] AC4: GIVEN the player's run_gold=18 and a slot costs 20, WHEN the slot is displayed, THEN its purchase button is visually disabled (insufficient gold state).
  - [ ] AC5: GIVEN all 3 shop slots have been purchased, WHEN the shop is displayed, THEN all slots show a "Purchased" state and the "Continue" button is enabled.
  - [ ] AC6: GIVEN the post-run summary screen (win or loss), WHEN displayed, THEN it shows: antes completed, total gold earned, score achieved, and a "New Highscore!" indicator if applicable.
  - [ ] AC7: GIVEN all UI tap targets in the Abyss screens, WHEN measured, THEN each interactive element meets the minimum 44x44px touch target requirement.
- **Test Evidence**: `production/qa/evidence/abyss-ui-layout.md`
- **Status**: Ready
- **Depends On**: STORY-ABYSS-003, STORY-ABYSS-007

---

### STORY-ABYSS-012: Full Abyss Run Integration Test

- **Type**: Integration
- **TR-IDs**: TR-abyss-001 through TR-abyss-017
- **ADR Guidance**: ADR-0007 — Full run exercises the entire chain: entry → 8 antes via CombatSystem → shop between each ante → COMPLETE → Legendary drop. Run save is verified after each ante. Persistent data (blessings, equipment, main gold) is verified unchanged at run end.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN a player with known blessings and equipment, WHEN a full simulated Abyss run is executed (8 antes, each with a mocked combat_completed victory signal), THEN the run reaches COMPLETE state without error.
  - [ ] AC2: GIVEN the full run completes, WHEN save state is inspected after each ante transition, THEN ante_current, run_gold, and modifier_id were persisted correctly at each step.
  - [ ] AC3: GIVEN the run completes with 8 antes, WHEN the post-run reward is distributed, THEN Equipment.award_item() is called exactly once with Legendary rarity.
  - [ ] AC4: GIVEN the run ends (win or loss), WHEN main GameStore is inspected, THEN player.gold, companion romance_stages, and equipped items are unchanged from their pre-run values.
  - [ ] AC5: GIVEN a run that was interrupted mid-run (ante_current=5, gold=60, two buffs active), WHEN the Abyss scene is loaded fresh, THEN AbyssRunner restores exactly that run state and resumes from the shop before ante 6.
  - [ ] AC6: GIVEN a defeat at ante 3, WHEN post-run summary is shown, THEN no equipment reward is awarded and highscore is updated only if the score from antes 1–2 exceeded the prior highscore.
- **Test Evidence**: `tests/integration/abyss_mode/full_run_integration_test.gd`
- **Status**: Ready
- **Depends On**: STORY-ABYSS-008, STORY-ABYSS-009, STORY-ABYSS-010, STORY-ABYSS-011
