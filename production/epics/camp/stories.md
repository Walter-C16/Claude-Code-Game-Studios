# Stories: Camp + Gift Items

> **Epic**: camp
> **Layer**: Feature
> **ADR**: ADR-0015
> **Manifest Version**: 2026-04-09
> **Total Stories**: 7

---

### STORY-CAMP-001: GiftItems Utility — JSON Loading and Gold Validation

- **Type**: Logic
- **TR-IDs**: TR-camp-014 (gift_items.json source), ADR-0015 TR-IDs: gift-items-001 (6 items), gift-items-003 (gold deduction), gift-items-004 (unlimited stock)
- **ADR Guidance**: `GiftItems` is a stateless `RefCounted` with static methods. Loads 6 items from `res://assets/data/gift_items.json`. `can_afford()` validates gold without side effects. No inventory. Data-driven: no item IDs, costs, or categories hardcoded in `.gd` files.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN `GiftItems.get_items()` is called, THEN it returns exactly 6 item dicts each with fields: `id`, `name_key`, `category`, `gold_cost`.
  - [ ] AC2: GIVEN `GiftItems.get_item("wildflowers")` is called, THEN it returns the dict with `gold_cost: 10` and `category: "romantic"`.
  - [ ] AC3: GIVEN `GiftItems.can_afford("ancient_scroll", 20)`, THEN it returns true (20 >= 20).
  - [ ] AC4: GIVEN `GiftItems.can_afford("ancient_scroll", 19)`, THEN it returns false (19 < 20).
  - [ ] AC5: GIVEN `GiftItems.get_cost("training_sword")`, THEN it returns 15.
  - [ ] AC6: GIVEN GiftItems code is inspected, THEN no item IDs, name keys, gold costs, or category strings appear as literals — all sourced from `gift_items.json`.
- **Test Evidence**: `tests/unit/camp/gift_items_test.gd`
- **Status**: Ready
- **Depends On**: None

---

### STORY-CAMP-002: Gift Purchase Flow — Gold Spend and RomanceSocial Integration

- **Type**: Integration
- **TR-IDs**: TR-camp-014, ADR-0015 purchase flow
- **ADR Guidance**: Purchase flow: `GiftItems.can_afford()` → `GameStore.spend_gold(cost)` → `RomanceSocial.do_gift(companion_id, item_id)`. Immediate gift — no inventory. One token consumed per purchase (handled by `do_gift`). Gold deducted atomically on confirmation.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN player has 25 gold and selects `wildflowers` (10 gold), WHEN purchase is confirmed, THEN `GameStore.spend_gold(10)` is called and gold decreases by 10.
  - [ ] AC2: GIVEN purchase is confirmed, WHEN the flow completes, THEN `RomanceSocial.do_gift(companion_id, "wildflowers")` is called after `spend_gold()` succeeds.
  - [ ] AC3: GIVEN player has 0 gold, WHEN `can_afford()` returns false, THEN `spend_gold()` is never called and no state changes.
  - [ ] AC4: GIVEN `do_gift()` is called with `item_id="wildflowers"` (category="romantic") and the companion likes "romantic", WHEN processed by RomanceSocial, THEN RL gain = 2, token decrements by 1.
  - [ ] AC5: GIVEN `wildflowers` category is "romantic" and the companion `known_dislikes` contains "romantic", WHEN `do_gift()` resolves, THEN RL gain = 0.
  - [ ] AC6: GIVEN purchase completes, WHEN SaveManager is checked, THEN autosave was triggered (gold change sets GameStore dirty).
- **Test Evidence**: `tests/integration/camp/gift_purchase_flow_test.gd`
- **Status**: Ready
- **Depends On**: STORY-CAMP-001

---

### STORY-CAMP-003: Companion Grid — Display, Gating, and Reactive Updates

- **Type**: UI
- **TR-IDs**: TR-camp-002, TR-camp-003, TR-camp-010, TR-camp-012
- **ADR Guidance**: Camp is pure presentation layer — reads RomanceSocial API, owns no game logic. Grid is 2-column scrollable, met companions only. Reactive on `companion_met` EventBus signal. No companions met state shows story-flavored prompt with no grid and no buttons. Grid cards >= 88x88px touch targets.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN no companions are met, WHEN Camp renders, THEN no companion grid is shown and a story-flavored "no companions yet" prompt is displayed instead of interaction buttons.
  - [ ] AC2: GIVEN 2 companions are met, WHEN Camp renders, THEN exactly 2 cards appear in the 2-column grid (unmet companions are not shown).
  - [ ] AC3: GIVEN `EventBus.companion_met(companion_id)` fires while Camp is visible, WHEN the signal is handled, THEN the new companion's card is added to the grid without a full scene reload.
  - [ ] AC4: GIVEN all companion grid cards, THEN each card has a minimum 88x88px touch target hitbox.
  - [ ] AC5: GIVEN Camp code is inspected, THEN no game state is written from Camp — all writes go through RomanceSocial's API or EventBus signals.
- **Test Evidence**: `production/qa/evidence/camp/companion-grid-screenshot.png`
- **Status**: Ready
- **Depends On**: None

---

### STORY-CAMP-004: Token Counter, Streak Display, and Midnight Reset Reactive Update

- **Type**: UI
- **TR-IDs**: TR-camp-006, TR-camp-008, TR-camp-011
- **ADR Guidance**: 3 gold pips represent tokens; update immediately on spend. Midnight reset triggers token refill via EventBus signal. Tokens exhausted: buttons disabled, "Come back tomorrow" label replaces interaction area. Interaction buttons individually gated (greyed + non-tappable, not hidden). All Control nodes inherit shared Theme .tres.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN `RomanceSocial.get_token_count()` returns 2, WHEN Camp renders the token pips, THEN 2 pips are gold and 1 pip is empty/greyed.
  - [ ] AC2: GIVEN a Talk action is completed (token spent), WHEN the UI updates, THEN the pip count decrements immediately without a scene reload.
  - [ ] AC3: GIVEN tokens = 0, WHEN Camp renders the interaction area, THEN Talk, Gift, and Date buttons are greyed and non-tappable, and a "Come back tomorrow" label is visible.
  - [ ] AC4: GIVEN the midnight reset event fires via EventBus, WHEN Camp handles it, THEN token pips update to 3 and interaction buttons become active.
  - [ ] AC5: GIVEN interaction buttons are gated (e.g. not enough tokens), THEN buttons are greyed and non-tappable — they must NOT be hidden (visibility must remain true).
  - [ ] AC6: GIVEN the streak count display, WHEN rendered, THEN it reads from `RomanceSocial.get_streak()` and shows the current consecutive-day count.
- **Test Evidence**: `production/qa/evidence/camp/token-display-screenshot.png`
- **Status**: Ready
- **Depends On**: None

---

### STORY-CAMP-005: Gift Picker Modal — Item Display, Affordability Gating, and Preference Hints

- **Type**: UI
- **TR-IDs**: TR-camp-004, TR-camp-007, TR-camp-012, TR-camp-013, TR-camp-014
- **ADR Guidance**: Gift picker as in-Camp modal bottom sheet at 60% screen height. Affordability: items player cannot afford are greyed and non-tappable. Preference hint icons shown only when `romance_stage >= 2` for items matching `known_likes` categories. Gift button disabled if `gift_items.json` fails to load. 60fps open/close. All touch targets >= 44x44px.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN the Gift button is tapped, WHEN the modal opens, THEN it animates from the bottom edge to occupy 60% of the 430x932 screen height at 60fps.
  - [ ] AC2: GIVEN player has 12 gold, WHEN the gift picker renders, THEN `wildflowers` (10g) and `woven_blanket` (10g) are tappable; `training_sword` (15g), `ancient_scroll` (20g), `explorers_map` (15g), and `painted_stone` (20g) are greyed and non-tappable.
  - [ ] AC3: GIVEN romance_stage >= 2 and the companion's `known_likes` contains "romantic", WHEN `wildflowers` (romantic) renders in the picker, THEN a preference hint icon is shown on that item.
  - [ ] AC4: GIVEN romance_stage < 2, WHEN the gift picker renders, THEN no preference hint icons are shown for any item.
  - [ ] AC5: GIVEN `gift_items.json` fails to load, WHEN Camp initializes, THEN the Gift button is disabled and no crash occurs.
  - [ ] AC6: GIVEN all gift item rows in the picker, THEN each has a minimum 44x44px touch target.
  - [ ] AC7: GIVEN the gift picker is open and the player taps outside or taps Close, WHEN handled, THEN the modal closes with a downward slide animation and no state changes.
- **Test Evidence**: `production/qa/evidence/camp/gift-picker-screenshot.png`
- **Status**: Ready
- **Depends On**: STORY-CAMP-001

---

### STORY-CAMP-006: Interaction Result Feedback — RL Gain Animation and Mood Change Display

- **Type**: UI
- **TR-IDs**: TR-camp-002 (pure presentation), TR-romance-social-016 (visual feedback)
- **ADR Guidance**: Presentation layer only. Reads the result dict returned by `RomanceSocial.do_talk()` / `do_gift()`. Displays RL gain and mood change without owning any logic. No game state written from Camp UI.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN `do_talk()` returns `{rl_gain: 4, new_mood: "Happy", stage_changed: false}`, WHEN the result is displayed, THEN a "+4 RL" floating label animates above the companion portrait.
  - [ ] AC2: GIVEN `new_mood` changes to "Happy", WHEN the result is displayed, THEN the companion portrait updates to the Happy mood variant.
  - [ ] AC3: GIVEN `stage_changed: true` in the result, WHEN the result is handled, THEN the stage advance ceremony scene is triggered (UI hands off to the ceremony; Camp does not play the ceremony itself).
  - [ ] AC4: GIVEN the feedback animation plays, THEN it completes within 1 second and does not block subsequent interaction button taps.
  - [ ] AC5: GIVEN Camp code for this feature, THEN no RL values, mood strings, or stage thresholds are written or computed here — all come from the result dict.
- **Test Evidence**: `production/qa/evidence/camp/interaction-feedback-screenshot.png`
- **Status**: Ready
- **Depends On**: STORY-CAMP-003, STORY-CAMP-004

---

### STORY-CAMP-007: Camp Scene Integration — Keep-Alive Tab, Date Launch, and Hub Wiring

- **Type**: Integration
- **TR-IDs**: TR-camp-001, TR-camp-005, TR-camp-008, TR-camp-009
- **ADR Guidance**: Camp is a Hub sub-tab using keep-alive hide/show (not scene change). Tab switch must be < 1 frame. Date launches full scene transition via `SceneManager.change_scene()`; return restores Camp tab via context payload. R&S API calls: `get_token_count()`, `get_streak()`, `get_companion_state(id)`, `do_talk(id)`, `do_gift(id, item)`, `start_date(id)`. No direct SceneManager calls for tab switching.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN the Hub tab bar switches away from and back to Camp, WHEN the transition occurs, THEN Camp uses hide/show (not `SceneManager.change_scene()`) and completes in < 1 frame (< 16.6ms).
  - [ ] AC2: GIVEN the Date button is tapped, WHEN handled, THEN `RomanceSocial.start_date(companion_id)` is called and `SceneManager.change_scene(SceneId.DATE, context)` transitions to the Date scene.
  - [ ] AC3: GIVEN the Date scene completes and returns, WHEN Camp is restored, THEN the correct companion remains selected and token pips reflect any tokens spent during the date.
  - [ ] AC4: GIVEN Camp needs to read state, THEN it exclusively uses the R&S API: `get_token_count()`, `get_streak()`, `get_companion_state(id)` — no direct GameStore reads from Camp.
  - [ ] AC5: GIVEN all 6 R&S API methods called by Camp, THEN each call matches the exact signatures defined in ADR-0010 Key Interfaces (no typos, no extra arguments).
- **Test Evidence**: `tests/integration/camp/hub_wiring_test.gd`
- **Status**: Ready
- **Depends On**: STORY-CAMP-002, STORY-CAMP-003, STORY-CAMP-004, STORY-CAMP-005, STORY-CAMP-006
