# Exploration

> **Status**: Designed
> **Author**: game-designer
> **Last Updated**: 2026-04-10
> **Implements Pillar**: Pillar 4 — Roguelike Abyss for Replayability (secondary); Pillar 3 — Companion Romance as Mechanical Investment

## Summary

Exploration is a timed real-time dispatch system. The player sends a companion on a mission lasting 1-4 real-time hours. On return, the mission yields gold, XP, equipment items, or gift items. Only one mission runs at a time. Companion AGI shortens dispatch duration; companion INT increases the chance of rare item finds. Companion must be `met == true` to send on a dispatch.

> **Quick reference** — Layer: `Feature` · Priority: `Alpha` · Key deps: `Companion Data, Save System`

---

## Overview

Exploration adds an asynchronous progression layer to Dark Olympus that rewards players who return to the game between sessions. From the Camp hub, the player selects a companion and a mission type, then commits them for a real-time duration (1, 2, or 4 hours). The mission runs in the background — the companion is "away" and unavailable for camp interactions (Talk/Gift/Date) while dispatched. On return, the player collects rewards: a base payout of gold and XP, with a chance to find equipment or gift items scaled to companion stats. Only one companion may be dispatched at a time, and the dispatched companion cannot serve as combat captain while away. The system uses real clock time stored in UTC, not in-game time — a 2-hour mission takes 2 real-world hours. Exploration is lightweight by design: it rewards consistent login habits without demanding active play, making it the primary engagement mechanic for sub-5-minute sessions.

---

## Player Fantasy

**"Send Her Into the World"**

The companions are powerful. Sending Artemis into the wilds to hunt rare artifacts, or dispatching Hipolita to raid a bandit camp for supplies, feels right — these aren't fragile NPCs waiting at camp for the player's attention. They are capable, autonomous, and bring back things that matter. When Artemis returns from a 4-hour hunt with a Legendary bow, the player should feel that she did something real while they were away.

This system also deepens the texture of the world. Missions have brief text descriptions that paint a small scene — Hipolita breaking down a fortress gate alone, Nyx moving through the dream-dark wilds. These flashes of companion agency make the goddesses feel larger than the player's direct interactions suggest.

The waiting is part of it. Knowing Artemis is out there right now, while you're doing other things, creates a gentle connective thread to the game between sessions. Coming back to collect what she found is a ritual pleasure — like checking a fishing line.

*Pillar 3: "Each companion must feel distinct." Exploration dispatch stats (AGI for speed, INT for rare finds) give each companion a different dispatch value profile.*

---

## Detailed Rules

### Rule 1 — Dispatch Setup

From Camp, the player selects:
1. **Companion** — any companion with `met == true` and not currently dispatched
2. **Mission Type** — determines base reward category (see Mission Type table)
3. **Duration** — 1 hour, 2 hours, or 4 hours (player's choice)

Confirming dispatch:
- Stores `dispatch_start_utc` (current UTC timestamp) in save data
- Stores `dispatch_duration_hours` (1, 2, or 4)
- Stores `dispatch_companion_id`
- Stores `dispatch_mission_type`
- Marks companion as `dispatched = true`

Only one dispatch may be active at a time. If a dispatch is active, the Dispatch button is replaced with a timer showing time remaining.

### Rule 2 — Mission Types

| Mission Type | Base Gold | Base XP | Primary Item Category | Flavor Tag |
|-------------|-----------|---------|----------------------|-----------|
| Hunt | 30–60 | 20–40 | Equipment (Weapon) | Artemis-flavored text |
| Raid | 50–80 | 10–20 | Equipment (Weapon or Amulet) | Hipolita-flavored text |
| Expedition | 20–40 | 40–60 | Equipment (Amulet) or Gift | Atenea-flavored text |
| Night Watch | 10–30 | 30–50 | Gift items | Nyx-flavored text |

Any companion can be sent on any mission type — the flavor text adapts to the dispatched companion. Mission type affects reward category, not which companion is allowed.

### Rule 3 — Duration Scaling

Longer missions yield better base rewards and higher item find chance:

| Duration | Gold Multiplier | XP Multiplier | Item Find Chance |
|----------|----------------|--------------|-----------------|
| 1 hour | 1.0x | 1.0x | 15% |
| 2 hours | 1.6x | 1.6x | 25% |
| 4 hours | 2.8x | 2.8x | 40% |

Base gold and XP are rolled within the mission type range, then multiplied by duration. Item find chance is a single d100 roll at return time.

### Rule 4 — Companion Stat Influence

Two companion stats modify dispatch outcomes:

**AGI (Agility) — affects effective duration:**
AGI reduces the effective mission time. The reduced time is cosmetic (display only) — the real-time clock still ticks at wall-clock speed. AGI does not make missions return faster in real time; it reduces the in-game narrative duration for flavor, and may unlock a future "Express Return" feature if implemented.

For now: AGI contributes to `agi_bonus_pct` which adds to Item Find Chance.

**INT (Intelligence) — affects rare item rarity:**
If an item find roll succeeds, INT shifts the rarity table toward higher tiers.

```
agi_bonus_pct = floor(companion.agi / 5)          -- +1% item find per 5 AGI points
int_rarity_shift = floor(companion.int / 10)       -- +1 rarity tier point per 10 INT points
```

Rarity tier point shifts the weighted table:
- 0 points: standard table (65/30/5)
- 1 point: (55/35/10)
- 2 points: (45/35/20)
- 3+ points: (35/35/30) — capped

Example: Atenea (INT 19) has `int_rarity_shift = 1`, giving her (55/35/10) rarity weights on item finds.

### Rule 5 — Return and Collection

The player returns to Camp and sees:
- Timer shows "0:00 — Ready to Collect!" if duration has elapsed
- Tapping "Collect" triggers the reward sequence:
  1. Companion portrait briefly displayed ("I'm back.")
  2. Reward summary card shows: gold earned, XP earned, item found (if any)
  3. Gold added to `player.gold`, XP added to `companion.xp`
  4. Item (if found) added to `pending_equipment` or `gift_inventory`
  5. Companion `dispatched = false`, available for camp interactions again

Dispatch data is cleared from save after collection. There is no auto-collect — the player must actively collect to clear the slot.

### Rule 6 — Companion Unavailability While Dispatched

A dispatched companion:
- Cannot be selected for Talk, Gift, or Date interactions at Camp
- Cannot be set as combat captain
- Appears in Camp with a "On Mission" visual indicator and a timer

Story combat can still proceed while a companion is dispatched — the player must use a non-dispatched companion as captain, or fight with no captain (allowed, but no captain bonus applies).

### Rule 7 — XP and Leveling

Dispatch XP is awarded to the dispatched companion's `xp` pool. Companion leveling is managed by the Companion Data system. XP from exploration follows the same accumulation path as XP from combat captain duty. No special dispatch XP behavior.

---

## Formulas

### Gold Reward

```
base_gold = random_int(mission_gold_min, mission_gold_max)
gold_reward = round(base_gold * duration_gold_multiplier)
```

### XP Reward

```
base_xp = random_int(mission_xp_min, mission_xp_max)
xp_reward = round(base_xp * duration_xp_multiplier)
```

### Item Find Chance

```
item_find_chance = base_find_chance + agi_bonus_pct
item_find_chance = min(item_find_chance, MAX_FIND_CHANCE)

agi_bonus_pct = floor(companion.agi / 5)
```

| Constant | Value |
|----------|-------|
| `MAX_FIND_CHANCE` | 60% (cap; prevents AGI from guaranteeing items) |

**Example — 4-hour Hunt with Artemis (AGI 20, INT 13):**

```
base_find_chance (4hr) = 40%
agi_bonus_pct = floor(20 / 5) = 4%
item_find_chance = 40 + 4 = 44%

int_rarity_shift = floor(13 / 10) = 1
rarity table: (55/35/10)

base_gold range: 30-60, multiplied 2.8x → 84-168 gold
base_xp range: 20-40, multiplied 2.8x → 56-112 XP
```

### Time Remaining Display

```
time_elapsed_sec = current_utc - dispatch_start_utc
time_remaining_sec = (dispatch_duration_hours * 3600) - time_elapsed_sec
time_remaining_sec = max(0, time_remaining_sec)
```

Displayed as `HH:MM` format. When `time_remaining_sec == 0`, shows "Ready!" and enables the Collect button.

---

## Edge Cases

**EC-1: App closed mid-dispatch.**
`dispatch_start_utc` is written to save at dispatch time. On next app open, the system recalculates `time_remaining_sec` from the stored UTC. Dispatch state persists correctly across app close/open. If the dispatch has completed while the app was closed, the "Ready!" state is shown immediately on Camp load.

**EC-2: Device clock manipulation.**
The system uses UTC timestamp stored at dispatch time and compares to current UTC at collection time. If the device clock is set backward (attempted exploit), `time_elapsed_sec` becomes negative. Guard: `time_elapsed_sec = max(0, current_utc - dispatch_start_utc)`. Dispatch cannot be collected early by any client-side clock manipulation because the minimum remaining is 0, not negative.

**EC-3: Only one companion met.**
The player can still dispatch. They lose access to all camp interactions and combat captain for the dispatch duration. This is a valid (if suboptimal) player choice. No system lock required.

**EC-4: Companion dispatched, story node triggers combat requiring a captain.**
Story combat does not enforce captain selection if no non-dispatched captain is available. The player fights without a captain (captain_chip_bonus = 0, captain_mult_bonus = 0). This is an edge case for early-game when only one companion is met. No crash — the combat system handles absent captain gracefully.

**EC-5: Item found but `pending_equipment` is full.**
Item is discarded. Reward summary still shows the item name with "(Lost — Inventory Full)" appended. Player is not penalized on gold or XP — only the item is lost. The Collect button shows a warning if the inventory is at capacity before confirming.

**EC-6: dispatch_duration_hours contains an invalid value.**
Valid values are 1, 2, 4. If save data is corrupt and contains another value, duration multipliers default to 1.0x and a warning is logged. Dispatch proceeds with 1-hour rates.

**EC-7: Both mission type data and companion data fail to load.**
Gold = 0, XP = 0, no item. Companion `dispatched` flag is cleared. A single error toast is shown: "Mission data missing — no rewards." The system does not crash.

---

## Dependencies

### Systems this depends on

| System | Usage | Doc |
|--------|-------|-----|
| **Companion Data** | Reads `companion.agi`, `companion.int`, `companion.met`, `companion.dispatched`; reads companion portrait asset for return screen | design/gdd/companion-data.md |
| **Save System** | Reads/writes dispatch state (`dispatch_start_utc`, `dispatch_companion_id`, `dispatch_duration_hours`, `dispatch_mission_type`) and clears on collection | design/gdd/save-system.md |

### Systems that depend on this

| System | How |
|--------|-----|
| **Equipment** | Receives equipment item drops via standard acquisition path on mission return |
| **Romance & Social** | Receives XP award routed through companion XP on collection; dispatched companion is unavailable for Camp interactions |
| **Camp** | Displays dispatch UI, timer, and collect button; reads `dispatched` flag per companion to show/hide interaction options |

### Integration Contract

**Provides to Camp**: `get_dispatch_state() -> dict` containing `{ active: bool, companion_id: String, time_remaining_sec: int, ready: bool }`

**Provides to Equipment**: standard `award_item(item_dict)` call on collection if item roll succeeds.

**Requires from Companion Data**: read-only access to `agi`, `int`, `met` per companion.

---

## Tuning Knobs

| Knob | Category | Default | Range | Notes |
|------|----------|---------|-------|-------|
| `DURATION_OPTIONS` | Gate | [1, 2, 4] hours | — | Fixed options. Adding a 8hr option would shift daily retention loop. |
| `GOLD_MULT_1HR` | Curve | 1.0 | 0.8–1.2 | Gold multiplier for 1-hour missions. |
| `GOLD_MULT_2HR` | Curve | 1.6 | 1.3–2.0 | Gold multiplier for 2-hour missions. |
| `GOLD_MULT_4HR` | Curve | 2.8 | 2.0–3.5 | Gold multiplier for 4-hour missions. |
| `XP_MULT_1HR` | Curve | 1.0 | 0.8–1.2 | XP multiplier for 1-hour missions. |
| `XP_MULT_2HR` | Curve | 1.6 | 1.3–2.0 | XP multiplier for 2-hour missions. |
| `XP_MULT_4HR` | Curve | 2.8 | 2.0–3.5 | XP multiplier for 4-hour missions. |
| `BASE_FIND_1HR` | Curve | 15% | 10–25% | Item find chance for 1-hour missions. |
| `BASE_FIND_2HR` | Curve | 25% | 15–35% | Item find chance for 2-hour missions. |
| `BASE_FIND_4HR` | Curve | 40% | 25–55% | Item find chance for 4-hour missions. |
| `MAX_FIND_CHANCE` | Gate | 60% | 50–75% | Caps AGI contribution to item find. Prevents trivial item farming. |
| `AGI_BONUS_DIVISOR` | Curve | 5 | 3–8 | Divides AGI to produce `agi_bonus_pct`. Higher = less AGI influence. |
| `INT_SHIFT_DIVISOR` | Curve | 10 | 8–15 | Divides INT to produce `int_rarity_shift`. Higher = less INT influence. |

All knobs live in `assets/data/exploration_config.json`.

---

## Acceptance Criteria

### Functional Criteria

- [ ] **AC-1**: Dispatching a companion stores `dispatch_start_utc` (UTC), `dispatch_companion_id`, `dispatch_duration_hours`, and `dispatch_mission_type` in save data. These values persist across app close/open.
- [ ] **AC-2**: Time remaining is calculated as `(dispatch_duration_hours * 3600) - (current_utc - dispatch_start_utc)`, clamped to minimum 0. "Ready!" state is shown when remaining == 0.
- [ ] **AC-3**: A dispatched companion is unavailable for Camp interactions (Talk/Gift/Date) and cannot be set as combat captain. The Camp UI shows "On Mission" for that companion.
- [ ] **AC-4**: On collection, gold and XP are calculated using the correct mission type ranges and duration multipliers. Values match the formula output within ±1 (rounding tolerance).
- [ ] **AC-5**: Item find chance correctly incorporates `agi_bonus_pct` and is capped at `MAX_FIND_CHANCE`. If an item drops, rarity weighting applies `int_rarity_shift` correctly (verified by seeded random tests).
- [ ] **AC-6**: Only one dispatch may be active at a time. Attempting to dispatch a second companion while one is active is rejected with a UI message; no state change occurs.
- [ ] **AC-7**: If a device clock rollback produces a negative `time_elapsed_sec`, the value is clamped to 0 and the dispatch is not prematurely collectible.
- [ ] **AC-8**: Collecting with a full `pending_equipment` inventory discards the item, shows a "(Lost — Inventory Full)" notification, and correctly awards gold and XP.

### Experiential Criteria

- [ ] **EX-1** (Playtest): Players understand the dispatch system without a tutorial — the UI communicates "send her, wait, collect" within 30 seconds of first encounter.
- [ ] **EX-2** (Playtest): Players who dispatched a companion overnight (8+ hours, auto-collected after timer expires) report finding the reward on their next session as a positive "opening the game to a surprise" experience.
- [ ] **EX-3** (Playtest): The 4-hour dispatch option is chosen by players who know they won't return for a while — confirming the duration choice is meaningful rather than arbitrary.
