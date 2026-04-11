# Stories: Equipment Epic

> **Epic**: Equipment
> **Layer**: Feature (Alpha)
> **Governing ADRs**: ADR-0007
> **Control Manifest Version**: 2026-04-10
> **Story Count**: 8

---

### STORY-EQUIP-001: Item Data Schema and JSON Loading

- **Type**: Logic
- **TR-IDs**: TR-equip-004, TR-equip-012, TR-equip-015
- **ADR Guidance**: No ADR — implements GDD directly. All item definitions loaded from `assets/data/equipment.json`. No bonus values hardcoded in `.gd` files. Config knobs in `assets/data/equipment_config.json`.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN `equipment.json` is loaded at startup, WHEN `EquipmentData.get_item(item_id)` is called for a known item, THEN it returns a dict with keys: `item_id`, `slot_type` ("weapon" or "amulet"), `rarity` ("common"/"rare"/"legendary"), `chip_bonus` (int, weapons only), `mult_bonus` (float, amulets only), `display_name_key` (String), `flavor_text_key` (String).
  - [ ] AC2: GIVEN a Weapon item definition with `chip_bonus=25`, WHEN the item is retrieved, THEN `chip_bonus=25` and `mult_bonus` is absent or 0.0 (Weapons have no mult_bonus).
  - [ ] AC3: GIVEN an Amulet item definition with `mult_bonus=1.5`, WHEN the item is retrieved, THEN `mult_bonus=1.5` and `chip_bonus` is absent or 0 (Amulets have no chip_bonus).
  - [ ] AC4: GIVEN `equipment.json` fails to load (missing file or parse error), WHEN `get_item()` is called, THEN it returns null, an error is logged, and no crash occurs.
  - [ ] AC5: GIVEN `equipment_config.json` is loaded, WHEN config constants are accessed, THEN DROP_RATE_STANDARD=20, DROP_RATE_BOSS=100, RARITY_WEIGHT_COMMON=65, RARITY_WEIGHT_RARE=30, RARITY_WEIGHT_LEGENDARY=5 are all readable.
  - [ ] AC6: GIVEN all items in `equipment.json`, WHEN the full item list is validated, THEN every item has a non-empty `item_id`, a valid `slot_type`, a valid `rarity`, and the appropriate bonus field set.
- **Test Evidence**: `tests/unit/equipment/equipment_data_test.gd`
- **Status**: Ready
- **Depends On**: None

---

### STORY-EQUIP-002: Equipment Slot System

- **Type**: Logic
- **TR-IDs**: TR-equip-001, TR-equip-011
- **ADR Guidance**: ADR-0007 — weapon_chip_bonus and amulet_mult_bonus exposed as read-only values to CombatSystem. Empty slot returns 0 / 0.0. No crash on empty slots.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN both slots are empty, WHEN `EquipmentSystem.get_weapon_chip_bonus()` is called, THEN returns 0.
  - [ ] AC2: GIVEN both slots are empty, WHEN `EquipmentSystem.get_amulet_mult_bonus()` is called, THEN returns 0.0.
  - [ ] AC3: GIVEN a Weapon item with chip_bonus=35 is equipped, WHEN `get_weapon_chip_bonus()` is called, THEN returns 35.
  - [ ] AC4: GIVEN an Amulet item with mult_bonus=1.5 is equipped, WHEN `get_amulet_mult_bonus()` is called, THEN returns 1.5.
  - [ ] AC5: GIVEN a Weapon and an Amulet are both equipped, WHEN both getters are called, THEN each returns its respective item's bonus independently.
  - [ ] AC6: GIVEN slot_type is "amulet" for an item, WHEN `equip(item)` is called, THEN the item is placed in the Amulet slot (not the Weapon slot) regardless of call order.
- **Test Evidence**: `tests/unit/equipment/equipment_slots_test.gd`
- **Status**: Ready
- **Depends On**: STORY-EQUIP-001

---

### STORY-EQUIP-003: Equip and Unequip Logic with Persistence

- **Type**: Logic
- **TR-IDs**: TR-equip-005, TR-equip-006, TR-equip-007, TR-equip-014
- **ADR Guidance**: No ADR — implements GDD directly. Equipping writes `equipped_weapon` and `equipped_amulet` to SaveManager. pending_equipment list max 5 items. Warning shown at 4/5 items.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN a Weapon already equipped and a new Weapon is equipped, WHEN the equip action is confirmed, THEN the old Weapon is discarded (not in pending_equipment or any inventory), and the new Weapon occupies the slot.
  - [ ] AC2: GIVEN a new item is being equipped, WHEN the Equipment screen shows the confirmation prompt, THEN the current slot item stats and the new item stats are both displayed for comparison.
  - [ ] AC3: GIVEN the player equips a new item, WHEN SaveManager is queried, THEN `equipped_weapon` or `equipped_amulet` reflects the newly equipped item dict.
  - [ ] AC4: GIVEN pending_equipment has 4 items, WHEN a 5th item is acquired, THEN the item is added (size becomes 5) and a "1 slot remaining" warning is shown in the Equipment screen.
  - [ ] AC5: GIVEN pending_equipment has 5 items, WHEN a 6th item is acquired, THEN the 6th item is discarded with a notification: "Inventory full — [Item Name] lost." pending_equipment remains at 5.
  - [ ] AC6: GIVEN the app is closed after equipping an item, WHEN the app is reopened, THEN EquipmentSystem loads the equipped item from SaveManager and both getter methods return the persisted values.
  - [ ] AC7: GIVEN an item is equipped from pending_equipment, WHEN the equip action completes, THEN that item is removed from pending_equipment (it is now the active slot item, not in the queue).
- **Test Evidence**: `tests/unit/equipment/equip_logic_test.gd`
- **Status**: Ready
- **Depends On**: STORY-EQUIP-002

---

### STORY-EQUIP-004: Scoring Pipeline Injection

- **Type**: Integration
- **TR-IDs**: TR-equip-003, TR-equip-010, TR-equip-011
- **ADR Guidance**: ADR-0007 — weapon_chip_bonus injected at Step 4 (chips additive phase, after captain_chip_bonus, before blessing_chips). amulet_mult_bonus injected at Step D (mult additive phase, after captain_mult_bonus, before blessing_mult). Both read once at CombatSystem SETUP and locked.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN Weapon chip_bonus=25 and the standard pipeline runs, WHEN CombatSystem resolves a hand, THEN total_chips includes 25 at Step 4 (verified by injecting known values for all other pipeline steps).
  - [ ] AC2: GIVEN Amulet mult_bonus=1.5 and the standard pipeline runs, WHEN CombatSystem resolves a hand, THEN total_mult includes 1.5 at Step D.
  - [ ] AC3: GIVEN pipeline formula: total_chips=(base+enhancement+captain+weapon+blessing), WHEN weapon_chip_bonus=25 and all other sources are known constants, THEN final total_chips equals expected sum.
  - [ ] AC4: GIVEN both slots empty, WHEN pipeline runs, THEN weapon contributes 0 to chips and amulet contributes 0.0 to mult (no NullRef, no crash).
  - [ ] AC5: GIVEN equipment is changed between combat setup and mid-combat (test scenario), WHEN the pipeline runs, THEN it uses the values captured at SETUP (not the current slot values).
  - [ ] AC6: GIVEN Weapon chip_bonus=70 (Legendary) + captain_chip_bonus=10 + blessing_chips=30, WHEN chips are summed, THEN the order is respected: captain (Step 3) before weapon (Step 4) before blessing (Step 5).
- **Test Evidence**: `tests/integration/equipment/pipeline_injection_test.gd`
- **Status**: Ready
- **Depends On**: STORY-EQUIP-002

---

### STORY-EQUIP-005: Drop Generation

- **Type**: Logic
- **TR-IDs**: TR-equip-002, TR-equip-008, TR-equip-009
- **ADR Guidance**: No ADR — implements GDD directly. Standard drop: roll d100, success if < 20, then weighted rarity. Boss drop: always success, rarity floor Rare (Legendary possible, Common excluded). Drop table loaded from equipment_config.json.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN a standard combat victory and 1000 seeded rolls, WHEN drop rolls are tallied, THEN approximately 20% trigger an item drop (within ±3% statistical tolerance).
  - [ ] AC2: GIVEN a standard combat defeat, WHEN drop roll is executed, THEN no item is generated (drop only on victory).
  - [ ] AC3: GIVEN a boss combat victory, WHEN drop generation runs, THEN exactly one item is returned, with rarity == "rare" or rarity == "legendary" (never "common").
  - [ ] AC4: GIVEN 1000 seeded standard drops (all triggering), WHEN rarities are tallied, THEN distribution is approximately 65% common / 30% rare / 5% legendary (within ±5% tolerance for each tier).
  - [ ] AC5: GIVEN rarity weights loaded from `equipment_config.json`, WHEN drop generation runs, THEN no weight constants are hardcoded in `drop_generator.gd`.
  - [ ] AC6: GIVEN a drop is generated with rarity "rare", WHEN `EquipmentData.get_random_item_by_rarity("rare")` is called, THEN it returns an item with rarity=="rare" from the loaded item pool.
- **Test Evidence**: `tests/unit/equipment/drop_generation_test.gd`
- **Status**: Ready
- **Depends On**: STORY-EQUIP-001

---

### STORY-EQUIP-006: Pending Items Queue

- **Type**: Logic
- **TR-IDs**: TR-equip-007, TR-equip-014
- **ADR Guidance**: No ADR — implements GDD directly. Pending queue is a List capped at 5. Items exceeding the cap are discarded with notification. Warning fires at 4/5 capacity.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN pending_equipment has 0 items, WHEN `award_item(item)` is called, THEN item is added and pending_equipment.size()==1.
  - [ ] AC2: GIVEN pending_equipment has 5 items, WHEN `award_item(item)` is called, THEN item is discarded, pending_equipment.size() remains 5, and a notification is emitted: "Inventory full — [item.display_name_key] lost."
  - [ ] AC3: GIVEN pending_equipment has 4 items, WHEN the Equipment screen is opened, THEN a "1 slot remaining — manage your inventory" warning banner is displayed.
  - [ ] AC4: GIVEN pending_equipment has 5 items and a new item arrives from exploration, WHEN `award_item()` is called, THEN the exploration reward summary shows "[Item Name] — Lost (Inventory Full)."
  - [ ] AC5: GIVEN an item in pending_equipment, WHEN the player equips it to a slot, THEN the item is removed from pending_equipment and placed in the active slot (queue size decrements).
  - [ ] AC6: GIVEN pending_equipment state is persisted to SaveManager, WHEN the app is closed and reopened, THEN pending_equipment is restored with the same items in the same order.
- **Test Evidence**: `tests/unit/equipment/pending_queue_test.gd`
- **Status**: Ready
- **Depends On**: STORY-EQUIP-003

---

### STORY-EQUIP-007: Equipment UI Screen

- **Type**: UI
- **TR-IDs**: TR-equip-005, TR-equip-006, TR-equip-013
- **ADR Guidance**: No ADR — implements GDD directly. Equipment screen accessible from Camp and Abyss shop. NOT accessible during active combat. Shows both slots side by side. Shows pending_equipment list below.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN the Equipment screen is opened from Camp, WHEN rendered, THEN both the Weapon slot and Amulet slot are displayed side by side, each showing either the equipped item or an "Empty" placeholder.
  - [ ] AC2: GIVEN an equipped item, WHEN displayed in its slot, THEN the item shows: name (localized), slot icon (sword or ring), rarity color frame (grey/blue/gold), stat bonus value, and flavor text.
  - [ ] AC3: GIVEN a pending item is tapped, WHEN the player selects "Equip to [slot]", THEN a before/after comparison card is shown displaying old item stats and new item stats.
  - [ ] AC4: GIVEN the comparison card is shown for equipping a Common over a Legendary, WHEN displayed, THEN both rarities are shown with rarity color frames (making the downgrade visually obvious).
  - [ ] AC5: GIVEN the player confirms equip from the comparison card, WHEN the action completes, THEN the slot updates to the new item, and the comparison card dismisses without animation glitch.
  - [ ] AC6: GIVEN an active combat is in progress (CombatSystem in DRAW or SELECT state), WHEN the player attempts to navigate to Equipment screen, THEN navigation is blocked and a toast message explains it is unavailable during combat.
  - [ ] AC7: GIVEN all Equipment screen interactive elements, WHEN measured, THEN each meets the 44x44px minimum touch target requirement.
- **Test Evidence**: `production/qa/evidence/equipment-ui-layout.md`
- **Status**: Ready
- **Depends On**: STORY-EQUIP-003, STORY-EQUIP-006

---

### STORY-EQUIP-008: Integration with Combat Rewards

- **Type**: Integration
- **TR-IDs**: TR-equip-008, TR-equip-009, TR-equip-012
- **ADR Guidance**: ADR-0007 — combat_completed signal is the trigger for drop generation. Equipment award follows the standard award_item() path. Graceful degradation if equipment.json fails to load.
- **Acceptance Criteria**:
  - [ ] AC1: GIVEN EventBus emits combat_completed with victory=true and is_boss=false, WHEN the reward handler runs, THEN a d100 is rolled and an item is awarded if roll < 20.
  - [ ] AC2: GIVEN EventBus emits combat_completed with victory=true and is_boss=true, WHEN the reward handler runs, THEN `award_item()` is called unconditionally with a Rare-or-better item.
  - [ ] AC3: GIVEN EventBus emits combat_completed with victory=false, WHEN the reward handler runs, THEN no item is generated.
  - [ ] AC4: GIVEN a standard victory triggers a drop, WHEN `award_item(item)` is called, THEN the item appears in pending_equipment (if space available) and the player sees a reward notification.
  - [ ] AC5: GIVEN `equipment.json` fails to load at startup, WHEN combat_completed fires and a drop would be awarded, THEN no item is generated, an error is logged, and no crash occurs. Combat result (victory/score) is still processed normally.
  - [ ] AC6: GIVEN a boss fight victory with pending_equipment full (5 items), WHEN the guaranteed boss drop is awarded, THEN Equipment handles the overflow (discard + notification) and the combat reward flow does not crash.
- **Test Evidence**: `tests/integration/equipment/combat_reward_integration_test.gd`
- **Status**: Ready
- **Depends On**: STORY-EQUIP-005, STORY-EQUIP-006
