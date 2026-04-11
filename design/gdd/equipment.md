# Equipment

> **Status**: Designed
> **Author**: game-designer
> **Last Updated**: 2026-04-10
> **Implements Pillar**: Pillar 1 — Balatro-Inspired Poker Combat

## Summary

Equipment is a passive stat-bonus system built around two artifact slots (Weapon and Amulet). Weapons affect `chips`; Amulets affect `mult`. Items have three rarities (Common, Rare, Legendary) and are obtained from combat rewards and exploration dispatches. Equipment bonuses are applied passively in the poker combat scoring pipeline after the captain bonus and before blessings.

> **Quick reference** — Layer: `Feature` · Priority: `Alpha` · Key deps: `Companion Data, Save System`

---

## Overview

Equipment gives players a persistent power layer that complements the blessing system without replacing it. The player has 2 equipment slots: a Weapon slot (modifies `chips`) and an Amulet slot (modifies `mult`). Each slot holds exactly one item at a time. Equipping a new item immediately replaces the old one — there is no item storage beyond what is currently equipped. Items are found as combat drop rewards and exploration dispatch returns. Rarity (Common, Rare, Legendary) determines stat bonus magnitude and visual presentation. In combat, the equipped Weapon's `chip_bonus` and the equipped Amulet's `mult_bonus` are added into the scoring pipeline at a fixed position: after the captain's stat bonus and before any divine blessing calculations. This placement means equipment establishes a baseline that blessings then amplify, preserving the romance-to-power hierarchy from Pillar 3.

---

## Player Fantasy

**"The Arsenal of a Champion"**

The companions give you divine power. Equipment is what you earn — artifacts pulled from defeated enemies and remote ruins by your own effort. A Weapon isn't just a stat bump; it's a trophy. When the player equips the Iron Bow of the Hunt (dropped by the Mountain Harpy), it should feel like Artemis approves. When the Amulet of Olympian Flame appears after a brutal fight, you wear it because you survived something that should have killed you.

Equipment creates player expression within combat identity. Two players who both romance Artemis will play differently if one wields a high-chip Weapon and the other a high-mult Amulet. The slot constraints — one of each — prevent equipment from collapsing into a single optimal loadout. There is always a choice.

The rarity system makes item discovery exciting. Common items are useful workhorses. Legendary items are found rarely enough that they reshape how a player thinks about their build.

*Pillar 1: "Every card play is a strategic decision." Equipment is the layer that shapes what strategic options are viable.*

---

## Detailed Rules

### Rule 1 — Slot Definitions

| Slot | Stat Modified | Count |
|------|--------------|-------|
| Weapon | `chips` (additive) | 1 |
| Amulet | `mult` (additive) | 1 |

The player always has both slots. Slots begin empty (no bonus). An empty slot contributes 0 to its stat.

### Rule 2 — Rarity Tiers

| Rarity | Chip Bonus Range (Weapon) | Mult Bonus Range (Amulet) | Drop Weight |
|--------|--------------------------|--------------------------|-------------|
| Common | +5 to +15 chips | +0.3 to +0.8 mult | 65% |
| Rare | +20 to +40 chips | +1.0 to +2.0 mult | 30% |
| Legendary | +50 to +80 chips | +2.5 to +4.0 mult | 5% |

Bonus values within each rarity tier are fixed per item definition — items are not procedurally generated. Each item in `assets/data/equipment.json` has a defined `chip_bonus` or `mult_bonus`, a `rarity`, and a `display_name_key`.

### Rule 3 — Scoring Pipeline Position

Equipment bonuses are injected at Step 4 of the poker scoring pipeline (see poker-combat.md for full pipeline):

```
Step 1: base_chips (hand rank + card pips)
Step 2: enhancement_chips (Foil cards)
Step 3: captain_chip_bonus (companion stat contribution)
Step 4: weapon_chip_bonus  ← Weapon slot inserted here
Step 5: blessing_chips (divine blessings)
---------
Total chips = sum of steps 1-5

Step A: base_mult (hand rank mult)
Step B: enhancement_mult (Holographic, Polychrome cards)
Step C: captain_mult_bonus
Step D: amulet_mult_bonus  ← Amulet slot inserted here
Step E: blessing_mult (divine blessings)
---------
Total mult = sum of steps A-E

Final score = Total chips * Total mult
```

Equipment always falls before blessings in the pipeline. This is load-bearing for Pillar 3: blessings amplify an already-enhanced base, making romantic investment feel multiplicatively powerful over raw gear.

### Rule 4 — Equipping Items

- Items are obtained as rewards (Rule 5) and placed into the player's `pending_equipment` inventory (maximum 5 items).
- The player opens the Equipment screen (accessible from Camp hub or between Abyss antes) to manage slots.
- Selecting an item prompts "Equip to Weapon slot" or "Equip to Amulet slot" depending on item type.
- Equipping replaces the current item in that slot. The replaced item is discarded — it does not return to inventory.
- Items in `pending_equipment` that exceed the 5-item cap are discarded at acquisition time (player is warned). The player is shown a comparison before equipping to prevent accidental replacement.
- Items cannot be moved between slots (a Weapon is always a Weapon; an Amulet is always an Amulet).

### Rule 5 — Item Acquisition Sources

| Source | Drop Type | Drop Rate | Notes |
|--------|-----------|-----------|-------|
| Story combat (standard) | Weapon or Amulet | 20% per fight | Rarity weighted per table above |
| Story combat (boss) | Weapon or Amulet | 100% (guaranteed) | Rarity floor: Rare |
| Exploration dispatch | Weapon, Amulet, or Gift | See exploration.md | Companion AGI and INT influence rarity |
| Abyss shop | Direct purchase | Cost in gold | Fixed stock per ante, no random rarity — items are presented at known stats |

Boss fights always drop exactly one item. Standard fights roll a single d100 against the 20% drop rate; on success, rarity is then determined by the weighted table.

### Rule 6 — Item Display

Each item displays:
- Name (localized from `display_name_key`)
- Slot type icon (sword icon for Weapon, ring icon for Amulet)
- Rarity color frame (grey = Common, blue = Rare, gold = Legendary)
- Stat bonus value ("+25 chips" or "+1.5 mult")
- Flavor text line (1 sentence, lore-flavor, localized)

The Equipment screen shows both slots side by side with currently equipped items and the pending_equipment list below.

---

## Formulas

### Score Pipeline Contribution

```
final_score = (base_chips + enhancement_chips + captain_chip_bonus + weapon_chip_bonus + blessing_chips)
            * (base_mult + enhancement_mult + captain_mult_bonus + amulet_mult_bonus + blessing_mult)
```

Variable definitions:
| Variable | Source | Type |
|----------|--------|------|
| `weapon_chip_bonus` | Equipped Weapon item's `chip_bonus` field | int, 0 if slot empty |
| `amulet_mult_bonus` | Equipped Amulet item's `mult_bonus` field | float, 0.0 if slot empty |

**Example — Common loadout (mid-game):**

- Hand: Pair of Fives → base_chips = 20, base_mult = 2
- Enhancement chips: Foil Five = +20 chips → enhancement_chips = 20
- Captain bonus (Artemis, stage 3): +10 chips, +0.5 mult
- Weapon: Hunting Spear (Common) = +10 chips
- Amulet: Silver Ring (Common) = +0.5 mult
- No blessings active

```
total_chips = 20 + 20 + 10 + 10 + 0 = 60
total_mult  = 2 + 0 + 0.5 + 0.5 + 0 = 3.0
score = 60 * 3.0 = 180
```

**Example — Legendary loadout (late-game):**

- Hand: Full House → base_chips = 40, base_mult = 4
- Captain bonus: +20 chips, +1.0 mult
- Weapon: Olympian Spear (Legendary) = +70 chips
- Amulet: Amulet of Flame (Legendary) = +3.5 mult
- Blessings: +30 chips, +2.0 mult

```
total_chips = 40 + 0 + 20 + 70 + 30 = 160
total_mult  = 4 + 0 + 1.0 + 3.5 + 2.0 = 10.5
score = 160 * 10.5 = 1680
```

### Drop Rate Calculation

```
item_drops = (combat_result == WIN) AND (roll(0..99) < DROP_RATE_STANDARD)
rarity = weighted_random(RARITY_WEIGHTS)
```

| Constant | Value |
|----------|-------|
| `DROP_RATE_STANDARD` | 20 (20%) |
| `DROP_RATE_BOSS` | 100 (guaranteed) |
| `RARITY_WEIGHT_COMMON` | 65 |
| `RARITY_WEIGHT_RARE` | 30 |
| `RARITY_WEIGHT_LEGENDARY` | 5 |

---

## Edge Cases

**EC-1: Both slots empty.**
`weapon_chip_bonus = 0`, `amulet_mult_bonus = 0.0`. Scoring pipeline proceeds normally with no equipment contribution. Valid starting state.

**EC-2: Player receives an item but pending_equipment is full (5 items).**
New item is discarded silently with a notification: "Inventory full — [Item Name] lost." Player is not blocked from combat. To prevent frustration, the Equipment screen shows a "Manage Equipment" prompt before combat starts if `pending_equipment.size() >= 4`.

**EC-3: Player equips an item mid-Abyss run.**
Equipment changes are allowed at the Abyss shop screen between antes. A change mid-ante (outside the shop) is not possible — the Equipment screen is not accessible during active combat. This prevents stat swapping during a hand sequence.

**EC-4: Item with `chip_bonus = 0` or `mult_bonus = 0.0`.**
Valid state — some items may have zero bonus on one axis if the design calls for a utility-only item in a future expansion. Current item set has no zero-bonus items. Pipeline handles zero values cleanly (additive with no effect).

**EC-5: Item data file missing or malformed.**
If `assets/data/equipment.json` fails to load, all equipment bonuses default to 0. Combat proceeds without error. A warning is logged. Empty slots are displayed in the Equipment screen. This prevents a data error from blocking gameplay.

**EC-6: Replacing a Legendary item with a Common.**
The player sees a comparison screen before confirming. The replaced item is permanently discarded. No confirmation bypass exists — the comparison is always shown. If the player confirms, the Legendary is lost. This is a deliberate design choice: storage management is itself a decision.

**EC-7: Exploration dispatch returns an equipment item while the player's inventory is full.**
Same as EC-2. The item from exploration is discarded with a notification logged. The player sees the result summary on the exploration return screen, which shows "[Item Name] — Lost (Inventory Full)."

---

## Dependencies

### Systems this depends on

| System | Usage | Doc |
|--------|-------|-----|
| **Companion Data** | Reads companion ID and `element` for future element-affinity item expansion; reads captain identity to determine pipeline position | design/gdd/companion-data.md |
| **Save System** | Reads/writes `equipped_weapon`, `equipped_amulet`, and `pending_equipment[]` on every equip action and session load | design/gdd/save-system.md |
| **Poker Combat** | Injects `weapon_chip_bonus` and `amulet_mult_bonus` into the scoring pipeline at Step 4/D | design/gdd/poker-combat.md |

### Systems that depend on this

| System | How |
|--------|-----|
| **Exploration** | Returns equipment items as dispatch rewards; Equipment system receives items via the standard acquisition path |
| **Abyss Mode** | Reads equipped item stats before each ante; provides shop access to purchase items between antes |
| **Poker Combat** | Reads `weapon_chip_bonus` and `amulet_mult_bonus` at combat setup; equipment stats are locked for the duration of a fight |

### Integration Contract

**Provides to Poker Combat**: Two read-only floats resolved at combat start:
- `get_weapon_chip_bonus() -> int` (0 if slot empty)
- `get_amulet_mult_bonus() -> float` (0.0 if slot empty)

**Requires from Save System**: Persistent dict at key `equipment_state` containing `equipped_weapon: {item_id, chip_bonus}`, `equipped_amulet: {item_id, mult_bonus}`, `pending_equipment: [{item_id, slot_type, rarity, chip_bonus, mult_bonus}]`.

---

## Tuning Knobs

| Knob | Category | Default | Range | Notes |
|------|----------|---------|-------|-------|
| `DROP_RATE_STANDARD` | Feel | 20% | 10–35% | Combat drop rate per won fight. Above 35% floods inventory. Below 10% feels stingy. |
| `DROP_RATE_BOSS` | Gate | 100% | 100% | Boss drops are always guaranteed. Not intended to be lowered. |
| `RARITY_WEIGHT_COMMON` | Curve | 65 | 50–75 | Common drop share. Shifting toward Rare/Legendary accelerates power curve. |
| `RARITY_WEIGHT_RARE` | Curve | 30 | 20–40 | Rare drop share. |
| `RARITY_WEIGHT_LEGENDARY` | Curve | 5 | 2–10 | Legendary drop share. Above 10% dilutes the significance of Legendaries. |
| `COMMON_CHIP_MIN` | Curve | 5 | 3–10 | Minimum chip bonus for Common Weapons. |
| `COMMON_CHIP_MAX` | Curve | 15 | 10–25 | Maximum chip bonus for Common Weapons. |
| `RARE_CHIP_MIN` | Curve | 20 | 15–30 | Minimum chip bonus for Rare Weapons. |
| `RARE_CHIP_MAX` | Curve | 40 | 30–60 | Maximum chip bonus for Rare Weapons. |
| `LEGENDARY_CHIP_MIN` | Curve | 50 | 40–70 | Minimum chip bonus for Legendary Weapons. |
| `LEGENDARY_CHIP_MAX` | Curve | 80 | 60–100 | Maximum chip bonus for Legendary Weapons. |
| `COMMON_MULT_MIN` | Curve | 0.3 | 0.2–0.5 | Minimum mult bonus for Common Amulets. |
| `COMMON_MULT_MAX` | Curve | 0.8 | 0.5–1.2 | Maximum mult bonus for Common Amulets. |
| `RARE_MULT_MIN` | Curve | 1.0 | 0.8–1.5 | Minimum mult bonus for Rare Amulets. |
| `RARE_MULT_MAX` | Curve | 2.0 | 1.5–3.0 | Maximum mult bonus for Rare Amulets. |
| `LEGENDARY_MULT_MIN` | Curve | 2.5 | 2.0–3.5 | Minimum mult bonus for Legendary Amulets. |
| `LEGENDARY_MULT_MAX` | Curve | 4.0 | 3.0–5.0 | Maximum mult bonus for Legendary Amulets. |
| `PENDING_INVENTORY_CAP` | Gate | 5 | 3–10 | Max items held before forced discard. Increasing reduces management pressure. |

All knobs live in `assets/data/equipment_config.json`.

---

## Acceptance Criteria

### Functional Criteria

- [ ] **AC-1**: Weapon slot applies `chip_bonus` additively at scoring pipeline Step 4 (after captain bonus, before blessings). Amulet slot applies `mult_bonus` additively at Step D. An empty slot contributes exactly 0 / 0.0.
- [ ] **AC-2**: Equipping a new item replaces the existing item in that slot. The replaced item is not added to inventory. The Equipment screen shows a before/after comparison before the player confirms.
- [ ] **AC-3**: Standard combat victory rolls a d100; if result < 20, an item drops with rarity determined by weighted table (65/30/5). Boss victories always drop one item at Rare or better.
- [ ] **AC-4**: `pending_equipment` never exceeds 5 items. Items acquired when the cap is reached are discarded with a notification shown to the player.
- [ ] **AC-5**: Equipment stats are read once at combat setup and locked for the duration of the encounter. Changing equipment mid-Abyss is only possible at the shop screen between antes.
- [ ] **AC-6**: If `assets/data/equipment.json` fails to load, both bonuses default to 0, combat proceeds, and an error is logged without crashing.
- [ ] **AC-7**: The Equipment screen is accessible from Camp and from the Abyss between-ante shop. It is not accessible during active combat.

### Experiential Criteria

- [ ] **EX-1** (Playtest): Players can explain the difference between Weapon and Amulet slots without being told — the chip/mult split is legible from the UI alone.
- [ ] **EX-2** (Playtest): Finding a Legendary item feels like a meaningful event. Players mention it unprompted in playtest debrief sessions.
- [ ] **EX-3** (Playtest): The inventory-full discard warning appears early enough (at 4/5 items) that players manage inventory proactively rather than being surprised by loss.
