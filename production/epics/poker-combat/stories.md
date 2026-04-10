# Stories: Poker Combat Epic

> **Epic**: Poker Combat
> **Layer**: Core
> **Governing ADRs**: ADR-0007, ADR-0006
> **Control Manifest Version**: 2026-04-09
> **Story Count**: 12

---

### STORY-COMBAT-001: Deck Creation and Shuffle

- **Type**: Logic
- **TR-IDs**: TR-poker-combat-001, TR-poker-combat-027
- **ADR Guidance**: ADR-0007 — Standard 52-card deck (4 suits x 13 values, Ace=14). Suit-to-element mapping locked: Hearts=Fire, Diamonds=Water, Clubs=Earth, Spades=Lightning. Signature cards tagged with `companion_id` at deck build time but play identically to normal cards. Deck loaded from config, not hardcoded.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN a fresh combat encounter, WHEN `CombatSystem._build_deck()` is called, THEN a deck of exactly 52 Card dictionaries is produced with no duplicates.
  - [ ] AC2: GIVEN the 52-card deck, WHEN inspected, THEN each of the 4 suits has exactly 13 cards with values 2 through 14 (Ace=14).
  - [ ] AC3: GIVEN a built deck, WHEN `shuffle()` is called, THEN the deck order changes from the ordered baseline (Fisher-Yates or equivalent; verify multiple shuffles differ).
  - [ ] AC4: GIVEN companion `"artemisa"` is the active captain, WHEN the deck is built, THEN the card matching Artemisa's suit (Clubs/Earth) and card_value (13/King) has `companion_id = "artemisa"` on its dictionary.
  - [ ] AC5: GIVEN a tagged signature card, WHEN played in a hand, THEN it contributes chips and element interactions identically to any other King of Clubs.
  - [ ] AC6: GIVEN no active captain, WHEN the deck is built, THEN no cards carry a `companion_id` tag.
  - [ ] AC7: GIVEN deck config is loaded from `res://assets/data/hand_ranks.json` (or equivalent config file), WHEN CombatSystem initializes, THEN no card values or suit names are hardcoded in `combat_system.gd`.
- **Test Evidence**: `tests/unit/poker_combat/deck_creation_test.gd`
- **Status**: Ready
- **Depends On**: None

---

### STORY-COMBAT-002: Hand Evaluation — All 10 Poker Ranks

- **Type**: Logic
- **TR-IDs**: TR-poker-combat-002, TR-poker-combat-022, TR-poker-combat-023
- **ADR Guidance**: ADR-0007 — 10 hand ranks from High Card to Royal Flush with defined base chips and mult (loaded from config). Flush and Straight require exactly 5 cards; fewer-card plays max at Four of a Kind. A-2-3-4-5 wheel straight recognized as valid. Hand rank values must be loaded from config files, not hardcoded.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN cards [7H, 7D, 9C, 5S, 3H] (Pair of 7s), WHEN `evaluate_hand([...])` is called, THEN returns rank `"Pair"`, base_chips=10, base_mult=2.
  - [ ] AC2: GIVEN cards [7H, 7D, 7C, 5S, 3H] (Three of a Kind), WHEN evaluated, THEN returns rank `"Three of a Kind"`, base_chips=30, base_mult=3.
  - [ ] AC3: GIVEN cards [AH, KH, QH, JH, 10H] (Royal Flush), WHEN evaluated, THEN returns rank `"Royal Flush"`, base_chips=100, base_mult=8.
  - [ ] AC4: GIVEN cards [AH, 2H, 3H, 4H, 5H] (Wheel Straight Flush), WHEN evaluated, THEN returns a Straight Flush (not a Straight), base_chips=100, base_mult=8.
  - [ ] AC5: GIVEN cards [AH, 2D, 3C, 4S, 5H] (A-2-3-4-5 Wheel Straight), WHEN evaluated, THEN returns rank `"Straight"`, base_chips=30, base_mult=4.
  - [ ] AC6: GIVEN only 4 cards selected [7H, 7D, 7C, 5S] (Three of a Kind, 4 cards), WHEN evaluated, THEN returns `"Three of a Kind"` (not a Flush or Straight — 5-card hands not possible).
  - [ ] AC7: GIVEN 4 cards of same suit [7H, 9H, KH, 2H], WHEN evaluated, THEN does NOT return Flush (requires exactly 5 cards).
  - [ ] AC8: GIVEN all 10 hand ranks, WHEN each is evaluated with a canonical example hand, THEN all 10 return the correct rank, base_chips, and base_mult matching values from config.
  - [ ] AC9: GIVEN hand rank data loaded from config file, WHEN `evaluate_hand()` is called, THEN no rank base values are hardcoded in `hand_evaluator.gd`.
- **Test Evidence**: `tests/unit/poker_combat/hand_evaluation_test.gd`
- **Status**: Ready
- **Depends On**: STORY-COMBAT-001

---

### STORY-COMBAT-003: Scoring Pipeline — Chips Calculation

- **Type**: Logic
- **TR-IDs**: TR-poker-combat-003, TR-poker-combat-006, TR-poker-combat-010, TR-poker-combat-019, TR-poker-combat-021
- **ADR Guidance**: ADR-0007 — Additive chips pipeline (strict order): base_hand_chips + per_card_chips + foil_chips + blessing_chips + element_chips + captain_chip_bonus + social_buff_chips. Clamp total_chips to min 1 after all additions. Per-card: 2-10=face value, J/Q/K=10, Ace=11. Foil=+50 chips per card. Pipeline order must not be modified.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN a Pair of 7s (base_chips=10), cards 7+7+9+5+3 (per-card=31), no enhancements, no captain, no buffs, WHEN chips are computed, THEN total_chips=41.
  - [ ] AC2: GIVEN a Flush (base_chips=35), 5 cards, one of which has Foil enhancement, WHEN chips computed, THEN foil contributes exactly +50 chips.
  - [ ] AC3: GIVEN Ace card value=14, WHEN `card_chips(14)` is called, THEN returns 11.
  - [ ] AC4: GIVEN Jack (11), Queen (12), King (13), WHEN `card_chips()` is called on each, THEN each returns 10.
  - [ ] AC5: GIVEN all chip sources sum to -5 (chips go negative due to element resistance), WHEN pipeline clamp is applied, THEN total_chips is set to 1 (never below 1).
  - [ ] AC6: GIVEN `social_buff_chips=20` in GameStore, WHEN chips are computed, THEN social_buff_chips is added at the end of the additive phase (before clamp).
  - [ ] AC7: GIVEN `blessing_chips=30` returned from BlessingSystem mock, WHEN chips are computed, THEN blessing_chips is included in the sum at the correct pipeline position.
  - [ ] AC8: GIVEN captain Hipolita (STR=20), WHEN `captain_chip_bonus` is computed, THEN result is `floor(20 * 0.5) = 10`.
- **Test Evidence**: `tests/unit/poker_combat/chips_pipeline_test.gd`
- **Status**: Ready
- **Depends On**: STORY-COMBAT-002

---

### STORY-COMBAT-004: Scoring Pipeline — Mult Calculation and Final Score

- **Type**: Logic
- **TR-IDs**: TR-poker-combat-003, TR-poker-combat-006, TR-poker-combat-010, TR-poker-combat-021
- **ADR Guidance**: ADR-0007 — Additive mult phase: base_hand_mult + holo_mult + blessing_mult + element_mult + social_buff_mult. Clamp additive_mult to min 1.0. Multiplicative phase: product(1.5 per Polychrome card) x captain_mult_modifier. Final score = floor(total_chips x final_mult). Score uses 64-bit int to avoid overflow.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN Pair (base_mult=2.0), no enhancements, no captain, no buffs, WHEN mult computed, THEN additive_mult=2.0, final_mult=2.0.
  - [ ] AC2: GIVEN one Holographic card, WHEN mult computed, THEN holo_mult contributes exactly +10 to additive phase.
  - [ ] AC3: GIVEN two Polychrome cards, WHEN mult computed, THEN final_mult includes factor of 1.5 x 1.5 = 2.25 from Polychrome (applied sequentially after additive phase).
  - [ ] AC4: GIVEN captain Atenea (INT=19), WHEN `captain_mult_modifier` computed, THEN equals `1.0 + (19 * 0.025) = 1.475`.
  - [ ] AC5: GIVEN all additive mult sources sum to 0.5 (below minimum), WHEN clamp applied, THEN additive_mult is set to 1.0 (never below 1.0).
  - [ ] AC6: GIVEN total_chips=258, final_mult=7.9625, WHEN final score computed, THEN result is `floor(258 * 7.9625) = 2054`.
  - [ ] AC7: GIVEN a very large score (e.g., chips=10000, mult=1000.0), WHEN score is computed and stored, THEN no integer overflow occurs (stored as 64-bit int or float with sufficient precision).
  - [ ] AC8: GIVEN total_chips=41 and final_mult=2.0 (early-game Pair), WHEN score computed, THEN result is 82.
- **Test Evidence**: `tests/unit/poker_combat/mult_pipeline_test.gd`
- **Status**: Ready
- **Depends On**: STORY-COMBAT-003

---

### STORY-COMBAT-005: Element Weakness and Resistance System

- **Type**: Logic
- **TR-IDs**: TR-poker-combat-004, TR-poker-combat-020
- **ADR Guidance**: ADR-0007 — Element cycle Fire > Earth > Lightning > Water > Fire. Per-card: weak element = +25 chips +0.5 mult (additive); enemy's own element = -15 chips (no mult penalty); neutral = 0. Enemy element None disables all interactions. Element interactions are per-card, independent.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN enemy element `"Earth"` (weak to Fire), WHEN a Heart card (Fire) is played, THEN that card contributes +25 element_chips and +0.5 element_mult.
  - [ ] AC2: GIVEN enemy element `"Earth"`, WHEN a Club card (Earth) is played, THEN that card contributes -15 element_chips and 0 element_mult.
  - [ ] AC3: GIVEN enemy element `"Earth"`, WHEN a Diamond card (Water) is played, THEN element_chips=0 and element_mult=0 (neutral).
  - [ ] AC4: GIVEN enemy element `"None"`, WHEN any card is played, THEN element_chips=0 and element_mult=0 for all cards.
  - [ ] AC5: GIVEN 5 Heart cards (Fire) vs Earth enemy, WHEN element bonuses computed, THEN total element_chips=+125 and total element_mult=+2.5.
  - [ ] AC6: GIVEN 5 Club cards (Earth) vs Earth enemy, WHEN element bonuses computed, THEN total element_chips=-75 and total element_mult=0.
  - [ ] AC7: GIVEN the element cycle Fire > Earth > Lightning > Water > Fire, WHEN each enemy element is tested, THEN: Fire is weak to Water, Water is weak to Lightning, Lightning is weak to Earth, Earth is weak to Fire.
  - [ ] AC8: GIVEN element data loaded from config (not hardcoded), WHEN `element_chips()` is evaluated, THEN the +25, -15, +0.5 values come from the loaded config object.
- **Test Evidence**: `tests/unit/poker_combat/element_system_test.gd`
- **Status**: Ready
- **Depends On**: STORY-COMBAT-003

---

### STORY-COMBAT-006: Card Enhancement Effects — Foil, Holo, Polychrome

- **Type**: Logic
- **TR-IDs**: TR-poker-combat-006
- **ADR Guidance**: ADR-0007 — Foil=+50 chips (additive chips phase), Holographic=+10 mult (additive mult phase), Polychrome=x1.5 mult (multiplicative phase, applied per card sequentially). One enhancement per card maximum. Enhancements are card-level attributes, not global buffs.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN a card with `enhancement = "Foil"`, WHEN chips pipeline runs, THEN that card contributes exactly +50 additional chips.
  - [ ] AC2: GIVEN a card with `enhancement = "Holographic"`, WHEN mult pipeline runs, THEN that card contributes exactly +10 additive mult.
  - [ ] AC3: GIVEN a card with `enhancement = "Polychrome"`, WHEN mult pipeline runs, THEN final_mult is multiplied by 1.5 for that card (after additive mult clamp).
  - [ ] AC4: GIVEN 3 Polychrome cards in a hand, WHEN mult pipeline runs, THEN the Polychrome factor is `1.5 ^ 3 = 3.375` applied to additive_mult.
  - [ ] AC5: GIVEN a card with no enhancement (`enhancement = null` or `"None"`), WHEN pipeline runs, THEN no enhancement bonus is applied.
  - [ ] AC6: GIVEN a card data schema, WHEN a card carries `enhancement = "Foil"`, THEN it cannot simultaneously carry `"Holographic"` (one enhancement per card, enforced at card creation).
  - [ ] AC7: GIVEN a Foil card, a Holo card, and a Polychrome card in the same hand, WHEN the full pipeline runs, THEN each applies at the correct phase independently (Foil to chips, Holo to additive mult, Poly to multiplicative mult).
- **Test Evidence**: `tests/unit/poker_combat/card_enhancements_test.gd`
- **Status**: Ready
- **Depends On**: STORY-COMBAT-003, STORY-COMBAT-004

---

### STORY-COMBAT-007: Captain Stat Bonus Integration

- **Type**: Logic
- **TR-IDs**: TR-poker-combat-005
- **ADR Guidance**: ADR-0007 — captain_chip_bonus = floor(STR * 0.5) added to chips phase. captain_mult_modifier = (1.0 + INT * 0.025) applied as multiplicative factor after Polychrome. Captain is locked at combat SETUP from CompanionRegistry/GameStore. No captain = bonuses are 0 and 1.0 respectively. Reads Companion Data (ADR-0009) — Core-to-Core dependency allowed.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN captain Artemisa (STR=17, INT=13) set at SETUP, WHEN a hand is scored, THEN captain_chip_bonus=8 (floor(17*0.5)) and captain_mult_modifier=1.325 (1.0+13*0.025).
  - [ ] AC2: GIVEN captain Hipolita (STR=20, INT=9), WHEN scored, THEN captain_chip_bonus=10 and captain_mult_modifier=1.225.
  - [ ] AC3: GIVEN captain Nyx (STR=18, INT=19), WHEN scored, THEN captain_chip_bonus=9 and captain_mult_modifier=1.475.
  - [ ] AC4: GIVEN no captain selected (captain_id = null or ""), WHEN scored, THEN captain_chip_bonus=0 and captain_mult_modifier=1.0.
  - [ ] AC5: GIVEN captain is locked at SETUP, WHEN romance_stage changes during combat (hypothetical), THEN captain stats do NOT change mid-combat (captain locked for duration).
  - [ ] AC6: GIVEN captain stats, WHEN captain_mult_modifier is applied in the pipeline, THEN it is applied AFTER Polychrome multiplication (strict pipeline order).
  - [ ] AC7: GIVEN CombatSystem reads captain stats at SETUP, WHEN `CompanionRegistry.get_profile(captain_id)` is called, THEN STR and INT are retrieved from the static profile (not from mutable CompanionState).
- **Test Evidence**: `tests/unit/poker_combat/captain_bonus_test.gd`
- **Status**: Ready
- **Depends On**: STORY-COMBAT-003, STORY-COMBAT-004

---

### STORY-COMBAT-008: Combat State Machine

- **Type**: Logic
- **TR-IDs**: TR-poker-combat-007, TR-poker-combat-008, TR-poker-combat-011, TR-poker-combat-017, TR-poker-combat-018, TR-poker-combat-024, TR-poker-combat-026
- **ADR Guidance**: ADR-0007 — State machine: SETUP → DRAW → SELECT → RESOLVE/DISCARD_DRAW → VICTORY/DEFEAT. Victory check before defeat check in RESOLVE. Deck exhaustion at DRAW (0 cards) = auto-defeat; < 5 cards = reduced hand. Combat state NOT persisted. Enemy config validates hands_allowed >= 1, discards_allowed >= 1 at SETUP. Discard 1-5 cards valid; 0 is invalid.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN a valid enemy config with score_threshold=40, WHEN `CombatSystem.start_combat(config)` is called, THEN state transitions SETUP → DRAW automatically, deck is built, current_score=0, hands_remaining=4, discards_remaining=4.
  - [ ] AC2: GIVEN state is DRAW and deck has 5+ cards, WHEN draw executes, THEN exactly 5 cards are dealt and state transitions to SELECT.
  - [ ] AC3: GIVEN state is DRAW and deck has 3 cards remaining, WHEN draw executes, THEN exactly 3 cards are dealt (not 5) and state transitions to SELECT.
  - [ ] AC4: GIVEN state is DRAW and deck has 0 cards, WHEN draw executes, THEN state transitions directly to DEFEAT (auto-defeat on empty deck).
  - [ ] AC5: GIVEN state is SELECT and player selects 3 cards and presses PLAY, WHEN action is submitted, THEN state transitions to RESOLVE.
  - [ ] AC6: GIVEN state is RESOLVE and current_score >= score_threshold after scoring, WHEN victory check runs, THEN state transitions to VICTORY (victory checked before defeat).
  - [ ] AC7: GIVEN state is RESOLVE and hands_remaining == 0 and current_score < score_threshold, WHEN checks run, THEN state transitions to DEFEAT.
  - [ ] AC8: GIVEN state is SELECT and player selects 0 cards and presses DISCARD, WHEN action is submitted, THEN the action is rejected (0 cards invalid discard).
  - [ ] AC9: GIVEN discards_remaining == 0, WHEN player attempts a DISCARD action, THEN action is rejected and state remains SELECT.
  - [ ] AC10: GIVEN enemy config with `hands_allowed=0`, WHEN `start_combat()` is called, THEN combat refuses to start and logs a data error (hands_allowed must be >= 1).
  - [ ] AC11: GIVEN combat ends (VICTORY or DEFEAT), WHEN CombatSystem is freed, THEN no combat state persists in GameStore (only outcomes written via signals).
- **Test Evidence**: `tests/unit/poker_combat/combat_state_machine_test.gd`
- **Status**: Ready
- **Depends On**: STORY-COMBAT-001, STORY-COMBAT-002

---

### STORY-COMBAT-009: Victory, Defeat, and Social Buff Lifecycle

- **Type**: Logic
- **TR-IDs**: TR-poker-combat-008, TR-poker-combat-009, TR-poker-combat-012, TR-poker-combat-025
- **ADR Guidance**: ADR-0007 — combat_completed signal emitted via EventBus with payload {victory, score, hands_used}. Social buff: social_buff_chips + social_buff_mult read from GameStore at SETUP. Consumed on VICTORY (combats_remaining - 1). Retained on DEFEAT (buff persists for retry). Victory short-circuits — remaining hands forfeited.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN current_score reaches score_threshold during RESOLVE, WHEN VICTORY state is entered, THEN `EventBus.combat_completed.emit({victory: true, score: current_score, hands_used: N})` is called.
  - [ ] AC2: GIVEN DEFEAT state is entered (hands exhausted), WHEN combat ends, THEN `EventBus.combat_completed.emit({victory: false, score: current_score, hands_used: N})` is called.
  - [ ] AC3: GIVEN VICTORY on hand 2 of 4, WHEN combat_completed is emitted, THEN `hands_used = 2` (not 4 — forfeited hands not counted).
  - [ ] AC4: GIVEN GameStore has active social combat buff (buff_chips=20, buff_mult=1.5, combats_remaining=3), WHEN combat SETUP runs, THEN social_buff_chips=20 and social_buff_mult=1.5 are captured and used in scoring.
  - [ ] AC5: GIVEN active social buff with combats_remaining=3 and player wins, WHEN VICTORY is resolved, THEN GameStore social buff combats_remaining is decremented to 2.
  - [ ] AC6: GIVEN active social buff with combats_remaining=3 and player loses, WHEN DEFEAT is resolved, THEN GameStore social buff combats_remaining remains 3 (buff retained on defeat).
  - [ ] AC7: GIVEN combats_remaining reaches 0, WHEN the buff is decremented, THEN the buff is marked inactive in GameStore (not negative).
  - [ ] AC8: GIVEN no active social buff (buff is null or inactive), WHEN SETUP runs, THEN social_buff_chips=0 and social_buff_mult=0.0 (no crash).
- **Test Evidence**: `tests/unit/poker_combat/victory_defeat_test.gd`
- **Status**: Ready
- **Depends On**: STORY-COMBAT-008

---

### STORY-COMBAT-010: BlessingSystem Black-Box Integration

- **Type**: Integration
- **TR-IDs**: TR-poker-combat-013
- **ADR Guidance**: ADR-0007 — CombatSystem calls `BlessingSystem.compute(hand_context)` as a black box at RESOLVE. Receives Dictionary `{blessing_chips: int, blessing_mult: float}`. CombatSystem does NOT inspect blessing internals. hand_context contains: played_cards, hand_rank, captain_id, romance_stages. Control Manifest: BlessingSystem is stateless RefCounted (ADR-0012), blessing set frozen at SETUP.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN a hand played in RESOLVE state, WHEN `BlessingSystem.compute(hand_context)` is called, THEN `hand_context` Dictionary contains at minimum: `played_cards` (Array), `hand_rank` (String), `captain_id` (String), and `romance_stages` (Dictionary keyed by companion_id).
  - [ ] AC2: GIVEN BlessingSystem returns `{blessing_chips: 50, blessing_mult: 2.0}`, WHEN chips pipeline runs, THEN blessing_chips=50 is added at the correct position (after foil, before element).
  - [ ] AC3: GIVEN BlessingSystem returns `{blessing_chips: 0, blessing_mult: 0.0}` (no active blessings), WHEN pipeline runs, THEN the zero values contribute nothing and score is correct.
  - [ ] AC4: GIVEN BlessingSystem is a stateless class (not autoload), WHEN CombatSystem calls `compute()`, THEN it calls via a local reference (not via autoload path).
  - [ ] AC5: GIVEN romance_stage changes during combat (hypothetical), WHEN `compute()` is called on hand 2, THEN the romance_stages snapshot from SETUP is used (frozen at combat start), not the current GameStore value.
  - [ ] AC6: GIVEN any hand context passed to BlessingSystem, WHEN `compute()` returns, THEN CombatSystem does not access any BlessingSystem internal fields (black-box contract enforced by interface).
- **Test Evidence**: `tests/integration/poker_combat/blessing_integration_test.gd`
- **Status**: Ready
- **Depends On**: STORY-COMBAT-008

---

### STORY-COMBAT-011: Combat UI Scene

- **Type**: UI
- **TR-IDs**: TR-poker-combat-014, TR-poker-combat-015, TR-poker-combat-016, TR-poker-combat-028, TR-poker-combat-029, TR-poker-combat-030, TR-poker-combat-031, TR-poker-combat-032, TR-poker-combat-033
- **ADR Guidance**: ADR-0007 — Combat screen layout: Enemy Info (0-120px), Scoring Tray (120-420px), Hand Area (420-800px), Action Bar (800-932px). Card minimum 64x90px tap target. PLAY/DISCARD buttons 190x56px. HP bar: full-width, 8px height, red fill + gold score overlay with 600ms ease-out. Max 4 active GPU particle emitters, max 2 animated shaders, no bloom/glow (Mobile renderer). Score animation cascade < 2s total, per-card 100ms.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN the CombatScreen scene is loaded, WHEN inspected in the scene tree, THEN layout zones are present: EnemyInfoPanel (y=0-120px), ScoringTray (y=120-420px), HandArea (y=420-800px), ActionBar (y=800-932px).
  - [ ] AC2: GIVEN a card is displayed in HandArea, WHEN measured, THEN its minimum touch target is 64x90px.
  - [ ] AC3: GIVEN PLAY and DISCARD buttons in ActionBar, WHEN measured, THEN each is at minimum 190x56px.
  - [ ] AC4: GIVEN a hand is scored, WHEN the scoring animation plays, THEN total cascade animation does not exceed 2 seconds.
  - [ ] AC5: GIVEN the HP bar, WHEN enemy HP is reduced, THEN the bar animates with a 600ms ease-out tween and score text overlays the HP bar.
  - [ ] AC6: GIVEN the combat scene, WHEN rendering on mobile, THEN no more than 4 GPU particle emitters are active simultaneously and no bloom/glow post-processing is used.
  - [ ] AC7: GIVEN the card sort toggle, WHEN player taps it, THEN cards reorder by Value or by Suit (Hearts → Diamonds → Clubs → Spades, then by value) without any gameplay state change.
  - [ ] AC8: GIVEN score numbers animating during cascade, WHEN rendered with a monospace/tabular font, THEN digits do not cause layout shifts as values increase.
  - [ ] AC9: GIVEN element icons displayed on cards or enemy panel, WHEN the element is indicated, THEN both color AND shape are used (flame, drop, leaf, bolt) — color is never the sole differentiator.
- **Test Evidence**: `production/qa/evidence/combat-ui-layout.md`
- **Status**: Ready
- **Depends On**: STORY-COMBAT-008, STORY-COMBAT-009

---

### STORY-COMBAT-012: Full Combat Integration — SceneManager, EventBus, and GameStore Rewards

- **Type**: Integration
- **TR-IDs**: TR-poker-combat-009, TR-poker-combat-018
- **ADR Guidance**: ADR-0007 — CombatSystem emits `combat_completed` via EventBus (not a local signal). Story Flow listens and advances narrative. Scene transitions via SceneManager.change_scene(SceneId) — never raw tscn paths. Combat state NOT persisted in GameStore. Only outcomes (gold, XP, story progress) written via autoload stores.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN CombatSystem loaded via SceneManager with valid enemy config, WHEN combat starts, THEN CombatSystem does NOT call `SceneTree.change_scene_to_file()` or reference a raw `.tscn` path.
  - [ ] AC2: GIVEN combat reaches VICTORY, WHEN `combat_completed` fires, THEN the signal is emitted on EventBus (`EventBus.combat_completed.emit(...)`) not as a local Node signal.
  - [ ] AC3: GIVEN `combat_completed` emitted with `victory=true`, WHEN Story Flow receives it, THEN Story Flow advances to the next story node (verified with a mock Story Flow listener).
  - [ ] AC4: GIVEN combat reaches DEFEAT and player chooses Retry, WHEN retry is triggered, THEN CombatSystem restarts (SETUP state) with a fresh deck (no stale state from prior run).
  - [ ] AC5: GIVEN the combat scene is freed after completion, WHEN GameStore is inspected, THEN no in-progress combat state (hands_remaining, current_score, deck) exists in GameStore.
  - [ ] AC6: GIVEN a VICTORY result with known score, WHEN downstream systems receive the combat_completed payload, THEN the payload Dictionary contains at minimum: `victory: bool`, `score: int`, `hands_used: int`.
  - [ ] AC7: GIVEN Scene transition back to Hub after combat, WHEN `SceneManager.change_scene()` is called, THEN a valid `SceneId` enum value is used (not a raw string path).
- **Test Evidence**: `tests/integration/poker_combat/combat_integration_test.gd`
- **Status**: Ready
- **Depends On**: STORY-COMBAT-009, STORY-COMBAT-010, STORY-COMBAT-011
